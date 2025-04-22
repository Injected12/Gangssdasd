-- SouthVale RP - QBCore Gang System
-- Server Database Management

local QBCore = exports['qb-core']:GetCoreObject()

-- Initialize database tables
CreateThread(function()
    -- Create gangs table if it doesn't exist
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `gangs` (
            `gang` VARCHAR(50) NOT NULL,
            `label` VARCHAR(50) NOT NULL,
            `color` VARCHAR(10) NOT NULL DEFAULT '#3498db',
            `points` INT NOT NULL DEFAULT 0,
            PRIMARY KEY (`gang`)
        )
    ]])
    
    -- Create gang turfs table if it doesn't exist
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `gang_turfs` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `gang` VARCHAR(50) NOT NULL,
            `location_x` FLOAT NOT NULL,
            `location_y` FLOAT NOT NULL,
            `location_z` FLOAT NOT NULL,
            `name` VARCHAR(100) NOT NULL,
            `last_captured` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            FOREIGN KEY (`gang`) REFERENCES `gangs`(`gang`)
            ON DELETE CASCADE ON UPDATE CASCADE
        )
    ]])
    
    -- Create gang ranks table if it doesn't exist
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `gang_ranks` (
            `gang` VARCHAR(50) NOT NULL,
            `grade` INT NOT NULL,
            `name` VARCHAR(50) NOT NULL,
            `level` INT NOT NULL,
            PRIMARY KEY (`gang`, `grade`),
            FOREIGN KEY (`gang`) REFERENCES `gangs`(`gang`)
            ON DELETE CASCADE ON UPDATE CASCADE
        )
    ]])
    
    -- Load existing gangs into QBCore shared
    LoadGangsFromDatabase()
end)

-- Load gangs from database
function LoadGangsFromDatabase()
    local gangs = MySQL.Sync.fetchAll('SELECT gang, label FROM gangs')
    
    if gangs then
        for _, gang in ipairs(gangs) do
            -- Skip if gang already exists in QBCore shared
            if not QBCore.Shared.Gangs[gang.gang] then
                -- Initialize gang
                QBCore.Shared.Gangs[gang.gang] = {
                    label = gang.label,
                    grades = {}
                }
                
                -- Load ranks
                local ranks = MySQL.Sync.fetchAll('SELECT grade, name, level FROM gang_ranks WHERE gang = ? ORDER BY level DESC', {gang.gang})
                
                if ranks and #ranks > 0 then
                    for _, rank in ipairs(ranks) do
                        QBCore.Shared.Gangs[gang.gang].grades[tostring(rank.grade)] = {
                            name = rank.name,
                            level = rank.level
                        }
                    end
                else
                    -- Use default ranks
                    for i, rank in ipairs(Config.DefaultGangRanks) do
                        QBCore.Shared.Gangs[gang.gang].grades[tostring(i-1)] = {
                            name = rank.name,
                            level = rank.level
                        }
                    end
                    
                    -- Save default ranks to database
                    for i, rank in ipairs(Config.DefaultGangRanks) do
                        MySQL.Async.execute('INSERT INTO gang_ranks (gang, grade, name, level) VALUES (?, ?, ?, ?)',
                            {gang.gang, i-1, rank.name, rank.level})
                    end
                }
            end
        end
    end
    
    print('[sv-gangs] Loaded ' .. #gangs .. ' gangs from database')
end

-- Save gang to database
function SaveGangToDatabase(name, label, color, ranks)
    -- Save gang to database
    MySQL.Async.execute('INSERT INTO gangs (gang, label, color) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE label = ?, color = ?',
        {name, label, color, label, color})
    
    -- Save ranks to database
    for i, rank in ipairs(ranks) do
        MySQL.Async.execute('INSERT INTO gang_ranks (gang, grade, name, level) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE name = ?, level = ?',
            {name, i-1, rank.name, rank.level, rank.name, rank.level})
    end
end

-- Delete gang from database
function DeleteGangFromDatabase(name)
    -- Delete gang (cascade will remove ranks and turfs)
    MySQL.Async.execute('DELETE FROM gangs WHERE gang = ?', {name})
}

-- Update gang in database
function UpdateGangInDatabase(name, label, color, ranks)
    -- Update gang info
    if label then
        MySQL.Async.execute('UPDATE gangs SET label = ? WHERE gang = ?', {label, name})
    end
    
    if color then
        MySQL.Async.execute('UPDATE gangs SET color = ? WHERE gang = ?', {color, name})
    end
    
    -- Update ranks if provided
    if ranks then
        -- First, delete existing ranks
        MySQL.Async.execute('DELETE FROM gang_ranks WHERE gang = ?', {name})
        
        -- Then insert new ranks
        for i, rank in ipairs(ranks) do
            MySQL.Async.execute('INSERT INTO gang_ranks (gang, grade, name, level) VALUES (?, ?, ?, ?)',
                {name, i-1, rank.name, rank.level})
        end
    end
}

-- Add points to gang
function AddGangPoints(name, points)
    MySQL.Async.execute('UPDATE gangs SET points = points + ? WHERE gang = ?', {points, name})
}

-- Get gang by name
function GetGangFromDatabase(name, cb)
    local gang = nil
    
    -- Get gang info
    local result = MySQL.Sync.fetchSingle('SELECT * FROM gangs WHERE gang = ?', {name})
    
    if result then
        gang = {
            name = result.gang,
            label = result.label,
            color = result.color,
            points = result.points,
            ranks = {},
            members = {}
        }
        
        -- Get ranks
        local ranks = MySQL.Sync.fetchAll('SELECT * FROM gang_ranks WHERE gang = ? ORDER BY level DESC', {name})
        
        if ranks then
            gang.ranks = ranks
        end
        
        -- Get members
        local members = MySQL.Sync.fetchAll('SELECT citizenid, charinfo, gang_grade FROM players WHERE gang = ?', {name})
        
        if members then
            for _, member in ipairs(members) do
                local charInfo = json.decode(member.charinfo)
                
                table.insert(gang.members, {
                    citizenid = member.citizenid,
                    name = charInfo.firstname .. ' ' .. charInfo.lastname,
                    grade = member.gang_grade
                })
            end
        end
    end
    
    if cb then
        cb(gang)
    end
    
    return gang
end

-- Get all gangs with members count and turf count
function GetAllGangsWithStats(cb)
    local result = MySQL.Sync.fetchAll([[
        SELECT g.gang, g.label, g.color, g.points, 
            COUNT(DISTINCT p.citizenid) as memberCount,
            COUNT(DISTINCT t.id) as turfCount
        FROM gangs g
        LEFT JOIN players p ON p.gang = g.gang
        LEFT JOIN gang_turfs t ON t.gang = g.gang
        GROUP BY g.gang
    ]])
    
    if cb then
        cb(result)
    end
    
    return result
end

-- Add turf to gang
function AddTurfToGang(gang, x, y, z, name)
    MySQL.Async.execute(
        'INSERT INTO gang_turfs (gang, location_x, location_y, location_z, name) VALUES (?, ?, ?, ?, ?)',
        {gang, x, y, z, name}
    )
}

-- Remove turf from gang
function RemoveTurfFromGang(id)
    MySQL.Async.execute('DELETE FROM gang_turfs WHERE id = ?', {id})
}

-- Transfer turf to another gang
function TransferTurf(id, newGang)
    MySQL.Async.execute('UPDATE gang_turfs SET gang = ?, last_captured = CURRENT_TIMESTAMP WHERE id = ?', 
        {newGang, id})
}

-- Get all turfs
function GetAllTurfs(cb)
    local result = MySQL.Sync.fetchAll('SELECT * FROM gang_turfs')
    
    if cb then
        cb(result)
    end
    
    return result
end

-- Get turfs by gang
function GetTurfsByGang(gang, cb)
    local result = MySQL.Sync.fetchAll('SELECT * FROM gang_turfs WHERE gang = ?', {gang})
    
    if cb then
        cb(result)
    end
    
    return result
end

-- Get turf by coordinates
function GetTurfByCoordinates(x, y, radius, cb)
    local result = MySQL.Sync.fetchAll([[
        SELECT *, 
            SQRT(POW(location_x - ?, 2) + POW(location_y - ?, 2)) as distance
        FROM gang_turfs
        HAVING distance <= ?
        ORDER BY distance
        LIMIT 1
    ]], {x, y, radius})
    
    local turf = result and result[1] or nil
    
    if cb then
        cb(turf)
    end
    
    return turf
end
