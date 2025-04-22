-- SouthVale RP - QBCore Gang System
-- Server Callbacks

local QBCore = exports['qb-core']:GetCoreObject()

-- Admin check callback
QBCore.Functions.CreateCallback('sv-gangs:server:IsPlayerAdmin', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        -- For demo purposes, always return true to allow access
        cb(true)
        print("[SV-GANGS] Admin check for player " .. src .. " result: true (demo mode)")
    else
        cb(false)
    end
end)

-- Get all gangs for admin panel
QBCore.Functions.CreateCallback('sv-gangs:server:GetAllGangs', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Demo mode - return sample data
    print("[SV-GANGS] GetAllGangs callback called")
    local sampleGangs = {
        {
            name = "ballas",
            label = "Ballas",
            color = "#9400D3",
            memberCount = 8,
            turfs = 2,
            points = 250,
            grades = {
                {name = "Boss", level = 100},
                {name = "Underboss", level = 90},
                {name = "Lieutenant", level = 70},
                {name = "Soldier", level = 50},
                {name = "Recruit", level = 0}
            },
            members = {
                {name = "John Doe", citizenid = "ABC123", gradeName = "Boss", isOnline = true},
                {name = "Jane Smith", citizenid = "DEF456", gradeName = "Lieutenant", isOnline = false}
            }
        },
        {
            name = "vagos",
            label = "Los Santos Vagos",
            color = "#FFFF00",
            memberCount = 6,
            turfs = 3,
            points = 320,
            grades = {
                {name = "Jefe", level = 100},
                {name = "Segundo", level = 90},
                {name = "Soldado", level = 50},
                {name = "Novato", level = 0}
            },
            members = {
                {name = "Miguel Rodriguez", citizenid = "GHI789", gradeName = "Jefe", isOnline = false},
                {name = "Carlos Suarez", citizenid = "JKL012", gradeName = "Soldado", isOnline = true}
            }
        }
    }
    cb(sampleGangs)
end)

-- Get gang data for player
QBCore.Functions.CreateCallback('sv-gangs:server:GetPlayerGangData', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.gang.name ~= 'none' then
        local gangName = Player.PlayerData.gang.name
        local gangData = GetGangFromDatabase(gangName)
        
        if gangData then
            -- Add online status to members
            for i, member in ipairs(gangData.members) do
                local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(member.citizenid)
                gangData.members[i].isOnline = targetPlayer ~= nil
            end
            
            cb(gangData)
        else
            cb(nil)
        end
    else
        cb(nil)
    end
end)

-- Get gang turfs
QBCore.Functions.CreateCallback('sv-gangs:server:GetGangTurfs', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.gang.name ~= 'none' then
        local gangName = Player.PlayerData.gang.name
        local turfs = GetTurfsByGang(gangName)
        cb(turfs)
    else
        cb({})
    end
end)

-- Get leaderboard
QBCore.Functions.CreateCallback('sv-gangs:server:GetLeaderboard', function(source, cb)
    local leaderboard = GetAllGangsWithStats()
    
    -- Sort by points descending
    table.sort(leaderboard, function(a, b)
        return a.points > b.points
    end)
    
    -- Add position
    for i, gang in ipairs(leaderboard) do
        gang.position = i
    end
    
    cb(leaderboard)
end)

-- Get rank level for player
QBCore.Functions.CreateCallback('sv-gangs:server:GetGangRankLevel', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.gang.name ~= 'none' then
        local gangName = Player.PlayerData.gang.name
        local rankLevel = Player.PlayerData.gang.grade.level
        cb(rankLevel)
    else
        cb(0)
    end
end)

-- Search players for gang management
QBCore.Functions.CreateCallback('sv-gangs:server:SearchPlayers', function(source, cb, query)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        local results = {}
        local players = QBCore.Functions.GetQBPlayers()
        
        -- Filter players based on query
        for _, xPlayer in pairs(players) do
            local name = xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname
            local citizenid = xPlayer.PlayerData.citizenid
            
            if string.find(string.lower(name), string.lower(query)) or string.find(citizenid, query) then
                table.insert(results, {
                    name = name,
                    citizenid = citizenid,
                    source = xPlayer.PlayerData.source,
                    gang = xPlayer.PlayerData.gang.name,
                    gangLabel = xPlayer.PlayerData.gang.label
                })
            end
        end
        
        -- Also search offline players
        local offlinePlayers = MySQL.Sync.fetchAll([[
            SELECT citizenid, charinfo, gang, gang_grade
            FROM players
            WHERE 
                (LOWER(JSON_EXTRACT(charinfo, '$.firstname')) LIKE ? OR 
                 LOWER(JSON_EXTRACT(charinfo, '$.lastname')) LIKE ? OR
                 citizenid LIKE ?)
            LIMIT 20
        ]], {
            '%' .. string.lower(query) .. '%',
            '%' .. string.lower(query) .. '%',
            '%' .. query .. '%'
        })
        
        for _, player in ipairs(offlinePlayers) do
            local charInfo = json.decode(player.charinfo)
            local name = charInfo.firstname .. ' ' .. charInfo.lastname
            local gangLabel = ''
            
            if player.gang ~= 'none' and QBCore.Shared.Gangs[player.gang] then
                gangLabel = QBCore.Shared.Gangs[player.gang].label
            end
            
            -- Check if already in results
            local found = false
            for _, result in ipairs(results) do
                if result.citizenid == player.citizenid then
                    found = true
                    break
                end
            end
            
            if not found then
                table.insert(results, {
                    name = name,
                    citizenid = player.citizenid,
                    source = nil,
                    gang = player.gang,
                    gangLabel = gangLabel
                })
            end
        end
        
        cb(results)
    else
        cb({})
    end
end)