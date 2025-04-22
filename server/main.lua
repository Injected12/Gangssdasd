-- SouthVale RP - QBCore Gang System
-- Server Main File

local QBCore = exports['qb-core']:GetCoreObject()

-- Variables
local GangInvites = {} -- Format: {playerId = {gangName = gang, invitedBy = inviterName}}

-- Event Handlers
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        TriggerClientEvent('sv-gangs:client:SendUIConfig', src)
    end
end)

-- Admin gang management
QBCore.Functions.CreateCallback('sv-gangs:server:CheckAdminPermission', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        if IsPlayerAdmin(Player) then
            cb(true)
        else
            cb(false)
        end
    else
        cb(false)
    end
end)

-- Check if player is admin
function IsPlayerAdmin(Player)
    local hasPermission = false
    
    -- Check permission
    if Player.PlayerData.permission and type(Player.PlayerData.permission) == 'string' then
        if QBCore.Functions.HasPermission(Player.PlayerData.source, Config.AdminPermission) then
            hasPermission = true
        end
    end
    
    -- Check admin groups
    if not hasPermission and Player.PlayerData.permission then
        for _, group in pairs(Config.AdminGroups) do
            if QBCore.Functions.HasPermission(Player.PlayerData.source, group) then
                hasPermission = true
                break
            end
        end
    end
    
    return hasPermission
end

-- Create new gang
RegisterNetEvent('sv-gangs:server:CreateGang', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and IsPlayerAdmin(Player) then
        if data.name and data.label then
            -- Format gang name (remove spaces, lowercase)
            local gangName = string.lower(data.name:gsub("%s+", ""))
            
            -- Check if gang already exists
            if QBCore.Shared.Gangs[gangName] then
                TriggerClientEvent('QBCore:Notify', src, 'A gang with this name already exists.', 'error')
                return
            end
            
            -- Create gang in QBCore shared
            QBCore.Shared.Gangs[gangName] = {
                label = data.label,
                grades = {}
            }
            
            -- Set up default ranks
            local ranks = data.ranks or Config.DefaultGangRanks
            for i, rank in ipairs(ranks) do
                QBCore.Shared.Gangs[gangName].grades[tostring(i-1)] = {
                    name = rank.name,
                    level = rank.level
                }
            end
            
            -- Save gang to database
            SaveGangToDatabase(gangName, data.label, data.color or Config.DefaultGangColor, ranks)
            
            TriggerClientEvent('QBCore:Notify', src, 'Gang created successfully: ' .. data.label, 'success')
            
            -- Update all clients
            TriggerClientEvent('QBCore:Client:UpdateGangs', -1, QBCore.Shared.Gangs)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Invalid gang data provided.', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to create gangs.', 'error')
    end
end)

-- Delete gang
RegisterNetEvent('sv-gangs:server:DeleteGang', function(gangName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and IsPlayerAdmin(Player) then
        if gangName and QBCore.Shared.Gangs[gangName] then
            -- Remove gang from QBCore shared
            QBCore.Shared.Gangs[gangName] = nil
            
            -- Remove gang from database
            DeleteGangFromDatabase(gangName)
            
            -- Update all members to "none" gang
            MySQL.Async.execute('UPDATE players SET gang = ? WHERE gang = ?', {'none', gangName})
            
            -- Update online players
            local Players = QBCore.Functions.GetQBPlayers()
            for _, xPlayer in pairs(Players) do
                if xPlayer.PlayerData.gang.name == gangName then
                    xPlayer.Functions.SetGang('none')
                end
            end
            
            TriggerClientEvent('QBCore:Notify', src, 'Gang deleted successfully.', 'success')
            
            -- Update all clients
            TriggerClientEvent('QBCore:Client:UpdateGangs', -1, QBCore.Shared.Gangs)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Invalid gang name provided.', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to delete gangs.', 'error')
    end
end)

-- Update gang information
RegisterNetEvent('sv-gangs:server:UpdateGang', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and IsPlayerAdmin(Player) then
        if data.name and QBCore.Shared.Gangs[data.name] then
            -- Update QBCore shared
            if data.label then
                QBCore.Shared.Gangs[data.name].label = data.label
            end
            
            if data.ranks then
                for i, rank in ipairs(data.ranks) do
                    QBCore.Shared.Gangs[data.name].grades[tostring(i-1)] = {
                        name = rank.name,
                        level = rank.level
                    }
                end
            end
            
            -- Update database
            UpdateGangInDatabase(data.name, data.label, data.color, data.ranks)
            
            TriggerClientEvent('QBCore:Notify', src, 'Gang updated successfully.', 'success')
            
            -- Update all clients
            TriggerClientEvent('QBCore:Client:UpdateGangs', -1, QBCore.Shared.Gangs)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Invalid gang data provided.', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to update gangs.', 'error')
    end
end)

-- Add member to gang
RegisterNetEvent('sv-gangs:server:AddMemberToGang', function(gangName, citizenid, rankLevel)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and IsPlayerAdmin(Player) then
        if gangName and QBCore.Shared.Gangs[gangName] and citizenid then
            -- Find the appropriate grade number based on level
            local gradeNumber = "0" -- Default to lowest
            
            if rankLevel then
                for grade, info in pairs(QBCore.Shared.Gangs[gangName].grades) do
                    if info.level == tonumber(rankLevel) then
                        gradeNumber = grade
                        break
                    end
                end
            end
            
            -- Update player in database
            MySQL.Async.execute('UPDATE players SET gang = ?, gang_grade = ? WHERE citizenid = ?', 
                {gangName, gradeNumber, citizenid})
            
            -- If player is online, update them
            local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
            if targetPlayer then
                targetPlayer.Functions.SetGang(gangName, tonumber(gradeNumber))
                TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'You have been added to ' .. QBCore.Shared.Gangs[gangName].label, 'success')
            end
            
            TriggerClientEvent('QBCore:Notify', src, 'Player added to gang successfully.', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Invalid data provided.', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to add members to gangs.', 'error')
    end
end)

-- Remove member from gang
RegisterNetEvent('sv-gangs:server:RemoveMemberFromGang', function(gangName, citizenid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        local hasPermission = IsPlayerAdmin(Player)
        
        -- Gang leaders can also remove members
        if not hasPermission and Player.PlayerData.gang.name == gangName then
            QBCore.Functions.TriggerCallback('sv-gangs:server:GetGangRankLevel', function(rankLevel)
                if rankLevel >= 90 then -- Only Boss/Underboss can remove
                    RemovePlayerFromGang(src, gangName, citizenid)
                else
                    TriggerClientEvent('QBCore:Notify', src, 'Only gang bosses can remove members.', 'error')
                end
            end, src)
        elseif hasPermission then
            RemovePlayerFromGang(src, gangName, citizenid)
        else
            TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to remove members from gangs.', 'error')
        end
    end
end)

-- Helper function to remove player from gang
function RemovePlayerFromGang(src, gangName, citizenid)
    if gangName and citizenid then
        -- Update player in database
        MySQL.Async.execute('UPDATE players SET gang = ?, gang_grade = ? WHERE citizenid = ?', 
            {'none', '0', citizenid})
        
        -- If player is online, update them
        local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
        if targetPlayer then
            targetPlayer.Functions.SetGang('none', 0)
            TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'You have been removed from your gang.', 'error')
        end
        
        TriggerClientEvent('QBCore:Notify', src, 'Player removed from gang successfully.', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Invalid data provided.', 'error')
    end
end

-- Gang invite system
RegisterNetEvent('sv-gangs:server:InviteToGang', function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(targetId)
    
    if Player and Target then
        local gangName = Player.PlayerData.gang.name
        
        if gangName ~= 'none' then
            -- Check if player has permission to invite
            QBCore.Functions.TriggerCallback('sv-gangs:server:GetGangRankLevel', function(rankLevel)
                if rankLevel >= 50 then -- Soldiers and above can invite
                    -- Store the invite
                    GangInvites[targetId] = {
                        gangName = gangName,
                        invitedBy = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                        inviterId = src
                    }
                    
                    -- Send invite to target
                    TriggerClientEvent('sv-gangs:client:GangInvite', targetId, 
                        QBCore.Shared.Gangs[gangName].label, 
                        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname)
                    
                    TriggerClientEvent('QBCore:Notify', src, 'Invitation sent.', 'success')
                else
                    TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to invite players.', 'error')
                end
            end, src)
        else
            TriggerClientEvent('QBCore:Notify', src, 'You are not in a gang.', 'error')
        end
    end
end)

-- Handle gang invite response
RegisterNetEvent('sv-gangs:server:RespondToGangInvite', function(accept)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and GangInvites[src] then
        local gangName = GangInvites[src].gangName
        local invitedBy = GangInvites[src].invitedBy
        local inviterId = GangInvites[src].inviterId
        
        if accept and QBCore.Shared.Gangs[gangName] then
            -- Add player to gang with lowest rank
            Player.Functions.SetGang(gangName, 0)
            
            -- Notify everyone
            TriggerClientEvent('QBCore:Notify', src, 'You joined ' .. QBCore.Shared.Gangs[gangName].label, 'success')
            
            local inviter = QBCore.Functions.GetPlayer(inviterId)
            if inviter then
                TriggerClientEvent('QBCore:Notify', inviterId, 
                    Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' joined your gang.', 'success')
            end
            
            -- Notify all gang members
            local Players = QBCore.Functions.GetQBPlayers()
            for _, xPlayer in pairs(Players) do
                if xPlayer.PlayerData.gang.name == gangName and xPlayer.PlayerData.source ~= src and xPlayer.PlayerData.source ~= inviterId then
                    TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, 
                        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' joined your gang.', 'primary')
                end
            end
        else
            -- Notify inviter of rejection
            local inviter = QBCore.Functions.GetPlayer(inviterId)
            if inviter then
                TriggerClientEvent('QBCore:Notify', inviterId, 
                    Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' declined your invitation.', 'error')
            end
            
            TriggerClientEvent('QBCore:Notify', src, 'You declined the gang invitation.', 'error')
        end
        
        -- Remove invite
        GangInvites[src] = nil
    end
end)

-- Promote gang member
RegisterNetEvent('sv-gangs:server:PromoteGangMember', function(citizenid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.gang.name ~= 'none' then
        local gangName = Player.PlayerData.gang.name
        
        -- Check if player has permission to promote
        QBCore.Functions.TriggerCallback('sv-gangs:server:GetGangRankLevel', function(rankLevel)
            if rankLevel >= 90 then -- Only Boss/Underboss can promote
                -- Get target player data
                local targetGrade = nil
                local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
                
                if targetPlayer and targetPlayer.PlayerData.gang.name == gangName then
                    targetGrade = targetPlayer.PlayerData.gang.grade
                else
                    -- Get from database if offline
                    local result = MySQL.Sync.fetchAll('SELECT gang_grade FROM players WHERE citizenid = ? AND gang = ?', 
                        {citizenid, gangName})
                    
                    if result and result[1] then
                        targetGrade = {level = tonumber(result[1].gang_grade)}
                    end
                end
                
                if targetGrade then
                    -- Find next highest rank
                    local currentLevel = targetGrade.level
                    local newGradeKey = nil
                    local highestLevel = -1
                    
                    for grade, info in pairs(QBCore.Shared.Gangs[gangName].grades) do
                        if info.level > currentLevel and (info.level < highestLevel or highestLevel == -1) then
                            highestLevel = info.level
                            newGradeKey = grade
                        end
                    end
                    
                    if newGradeKey then
                        -- Update player
                        if targetPlayer then
                            targetPlayer.Functions.SetGang(gangName, tonumber(newGradeKey))
                            TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 
                                'You have been promoted to ' .. QBCore.Shared.Gangs[gangName].grades[newGradeKey].name, 'success')
                        else
                            MySQL.Async.execute('UPDATE players SET gang_grade = ? WHERE citizenid = ?', 
                                {newGradeKey, citizenid})
                        end
                        
                        TriggerClientEvent('QBCore:Notify', src, 'Member promoted successfully.', 'success')
                    else
                        TriggerClientEvent('QBCore:Notify', src, 'This member is already at the highest rank.', 'error')
                    end
                else
                    TriggerClientEvent('QBCore:Notify', src, 'Unable to find gang member.', 'error')
                end
            else
                TriggerClientEvent('QBCore:Notify', src, 'Only gang bosses can promote members.', 'error')
            end
        end, src)
    else
        TriggerClientEvent('QBCore:Notify', src, 'You are not in a gang.', 'error')
    end
end)

-- Demote gang member
RegisterNetEvent('sv-gangs:server:DemoteGangMember', function(citizenid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.gang.name ~= 'none' then
        local gangName = Player.PlayerData.gang.name
        
        -- Check if player has permission to demote
        QBCore.Functions.TriggerCallback('sv-gangs:server:GetGangRankLevel', function(rankLevel)
            if rankLevel >= 90 then -- Only Boss/Underboss can demote
                -- Get target player data
                local targetGrade = nil
                local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
                
                if targetPlayer and targetPlayer.PlayerData.gang.name == gangName then
                    targetGrade = targetPlayer.PlayerData.gang.grade
                else
                    -- Get from database if offline
                    local result = MySQL.Sync.fetchAll('SELECT gang_grade FROM players WHERE citizenid = ? AND gang = ?', 
                        {citizenid, gangName})
                    
                    if result and result[1] then
                        targetGrade = {level = tonumber(result[1].gang_grade)}
                    end
                end
                
                if targetGrade then
                    -- Find next lowest rank
                    local currentLevel = targetGrade.level
                    local newGradeKey = nil
                    local lowestLevel = 999
                    
                    for grade, info in pairs(QBCore.Shared.Gangs[gangName].grades) do
                        if info.level < currentLevel and info.level > lowestLevel then
                            lowestLevel = info.level
                            newGradeKey = grade
                        end
                    end
                    
                    if newGradeKey then
                        -- Update player
                        if targetPlayer then
                            targetPlayer.Functions.SetGang(gangName, tonumber(newGradeKey))
                            TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 
                                'You have been demoted to ' .. QBCore.Shared.Gangs[gangName].grades[newGradeKey].name, 'error')
                        else
                            MySQL.Async.execute('UPDATE players SET gang_grade = ? WHERE citizenid = ?', 
                                {newGradeKey, citizenid})
                        end
                        
                        TriggerClientEvent('QBCore:Notify', src, 'Member demoted successfully.', 'success')
                    else
                        TriggerClientEvent('QBCore:Notify', src, 'This member is already at the lowest rank.', 'error')
                    end
                else
                    TriggerClientEvent('QBCore:Notify', src, 'Unable to find gang member.', 'error')
                end
            else
                TriggerClientEvent('QBCore:Notify', src, 'Only gang bosses can demote members.', 'error')
            end
        end, src)
    else
        TriggerClientEvent('QBCore:Notify', src, 'You are not in a gang.', 'error')
    end
end)

-- Set gang member rank directly
RegisterNetEvent('sv-gangs:server:SetGangMemberRank', function(citizenid, rankLevel)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        local hasPermission = IsPlayerAdmin(Player)
        
        -- Gang leaders can also set ranks
        if not hasPermission and Player.PlayerData.gang.name ~= 'none' then
            QBCore.Functions.TriggerCallback('sv-gangs:server:GetGangRankLevel', function(playerRankLevel)
                if playerRankLevel >= 90 then -- Only Boss/Underboss can set ranks
                    SetMemberRank(src, Player.PlayerData.gang.name, citizenid, rankLevel)
                else
                    TriggerClientEvent('QBCore:Notify', src, 'Only gang bosses can set member ranks.', 'error')
                end
            end, src)
        elseif hasPermission then
            -- Get gang name from target
            local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
            if targetPlayer then
                SetMemberRank(src, targetPlayer.PlayerData.gang.name, citizenid, rankLevel)
            else
                -- Get from database
                local result = MySQL.Sync.fetchAll('SELECT gang FROM players WHERE citizenid = ?', {citizenid})
                if result and result[1] and result[1].gang ~= 'none' then
                    SetMemberRank(src, result[1].gang, citizenid, rankLevel)
                else
                    TriggerClientEvent('QBCore:Notify', src, 'Player is not in a gang.', 'error')
                end
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to set ranks.', 'error')
        end
    end
end)

-- Helper function to set member rank
function SetMemberRank(src, gangName, citizenid, rankLevel)
    if gangName and citizenid and rankLevel and QBCore.Shared.Gangs[gangName] then
        -- Find the grade key with the specified level
        local newGradeKey = nil
        for grade, info in pairs(QBCore.Shared.Gangs[gangName].grades) do
            if info.level == tonumber(rankLevel) then
                newGradeKey = grade
                break
            end
        end
        
        if newGradeKey then
            -- Update player
            local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
            if targetPlayer then
                targetPlayer.Functions.SetGang(gangName, tonumber(newGradeKey))
                TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 
                    'Your rank has been set to ' .. QBCore.Shared.Gangs[gangName].grades[newGradeKey].name, 'primary')
            else
                MySQL.Async.execute('UPDATE players SET gang_grade = ? WHERE citizenid = ?', 
                    {newGradeKey, citizenid})
            end
            
            TriggerClientEvent('QBCore:Notify', src, 'Member rank updated successfully.', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Invalid rank level provided.', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Invalid data provided.', 'error')
    end
end

-- Check player gang on connection
RegisterNetEvent('sv-gangs:server:CheckPlayerGang', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        local gangName = Player.PlayerData.gang.name
        
        if gangName ~= 'none' then
            -- Check if gang still exists
            if not QBCore.Shared.Gangs[gangName] then
                Player.Functions.SetGang('none', 0)
                TriggerClientEvent('QBCore:Notify', src, 'Your gang no longer exists.', 'error')
            end
        end
    end
end)

-- Callbacks
QBCore.Functions.CreateCallback('sv-gangs:server:GetAllGangs', function(source, cb)
    local gangs = {}
    
    -- Convert QBCore.Shared.Gangs to array with additional info
    for name, gang in pairs(QBCore.Shared.Gangs) do
        if name ~= 'none' then
            local gangData = {
                name = name,
                label = gang.label,
                grades = {},
                memberCount = 0,
                turfs = 0,
                color = GetGangColor(name)
            }
            
            -- Convert grades to array
            for gradeNum, grade in pairs(gang.grades) do
                table.insert(gangData.grades, {
                    level = grade.level,
                    name = grade.name,
                    grade = tonumber(gradeNum)
                })
            end
            
            -- Sort grades by level
            table.sort(gangData.grades, function(a, b)
                return a.level > b.level
            end)
            
            -- Get member count
            local result = MySQL.Sync.fetchAll('SELECT COUNT(*) as count FROM players WHERE gang = ?', {name})
            if result and result[1] then
                gangData.memberCount = result[1].count
            end
            
            -- Get turf count
            local turfResult = MySQL.Sync.fetchAll('SELECT COUNT(*) as count FROM gang_turfs WHERE gang = ?', {name})
            if turfResult and turfResult[1] then
                gangData.turfs = turfResult[1].count
            end
            
            table.insert(gangs, gangData)
        end
    end
    
    cb(gangs)
end)

QBCore.Functions.CreateCallback('sv-gangs:server:GetGangData', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.gang.name ~= 'none' then
        local gangName = Player.PlayerData.gang.name
        
        local gangData = {
            name = gangName,
            label = QBCore.Shared.Gangs[gangName].label,
            color = GetGangColor(gangName),
            grades = {},
            members = {},
            turfs = {}
        }
        
        -- Get grades
        for gradeNum, grade in pairs(QBCore.Shared.Gangs[gangName].grades) do
            table.insert(gangData.grades, {
                level = grade.level,
                name = grade.name,
                grade = tonumber(gradeNum)
            })
        end
        
        -- Sort grades by level
        table.sort(gangData.grades, function(a, b)
            return a.level > b.level
        end)
        
        -- Get members
        local result = MySQL.Sync.fetchAll('SELECT citizenid, charinfo, gang_grade, last_updated FROM players WHERE gang = ?', {gangName})
        if result then
            for _, player in ipairs(result) do
                local charInfo = json.decode(player.charinfo)
                local gradeInfo = QBCore.Shared.Gangs[gangName].grades[tostring(player.gang_grade)]
                
                -- Check if player is online
                local isOnline = false
                local onlinePlayer = QBCore.Functions.GetPlayerByCitizenId(player.citizenid)
                if onlinePlayer then
                    isOnline = true
                end
                
                table.insert(gangData.members, {
                    citizenid = player.citizenid,
                    name = charInfo.firstname .. ' ' .. charInfo.lastname,
                    grade = player.gang_grade,
                    gradeName = gradeInfo and gradeInfo.name or "Unknown",
                    gradeLevel = gradeInfo and gradeInfo.level or 0,
                    lastUpdated = player.last_updated,
                    isOnline = isOnline
                })
            end
            
            -- Sort members by grade level (descending)
            table.sort(gangData.members, function(a, b)
                return a.gradeLevel > b.gradeLevel
            end)
        end
        
        -- Get turfs
        local turfResult = MySQL.Sync.fetchAll('SELECT * FROM gang_turfs WHERE gang = ?', {gangName})
        if turfResult then
            gangData.turfs = turfResult
        end
        
        cb(gangData)
    else
        cb(nil)
    end
end)

QBCore.Functions.CreateCallback('sv-gangs:server:GetGangRankLevel', function(source, cb, playerId)
    local src = playerId or source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.gang.name ~= 'none' then
        local gangName = Player.PlayerData.gang.name
        local gradeLevel = 0
        
        if Player.PlayerData.gang.grade and Player.PlayerData.gang.grade.level then
            gradeLevel = Player.PlayerData.gang.grade.level
        end
        
        cb(gradeLevel)
    else
        cb(0)
    end
end)

QBCore.Functions.CreateCallback('sv-gangs:server:GetPlayerByCitizenId', function(source, cb, citizenid)
    local result = MySQL.Sync.fetchAll('SELECT citizenid, charinfo FROM players WHERE citizenid = ?', {citizenid})
    
    if result and result[1] then
        local charInfo = json.decode(result[1].charinfo)
        
        cb({
            citizenid = result[1].citizenid,
            name = charInfo.firstname .. ' ' .. charInfo.lastname
        })
    else
        cb(nil)
    end
end)

QBCore.Functions.CreateCallback('sv-gangs:server:SearchPlayers', function(source, cb, query)
    if not query or query == '' then
        cb({})
        return
    end
    
    local searchTerm = '%' .. query .. '%'
    local results = {}
    
    -- Search by name in charinfo JSON
    local players = MySQL.Sync.fetchAll([[
        SELECT citizenid, charinfo 
        FROM players 
        WHERE 
            JSON_EXTRACT(charinfo, '$.firstname') LIKE ? OR 
            JSON_EXTRACT(charinfo, '$.lastname') LIKE ? OR
            citizenid LIKE ?
        LIMIT 20
    ]], {searchTerm, searchTerm, searchTerm})
    
    if players then
        for _, player in ipairs(players) do
            local charInfo = json.decode(player.charinfo)
            
            table.insert(results, {
                citizenid = player.citizenid,
                name = charInfo.firstname .. ' ' .. charInfo.lastname
            })
        end
    end
    
    cb(results)
end)

QBCore.Functions.CreateCallback('sv-gangs:server:GetGangMembers', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.gang.name ~= 'none' then
        local gangName = Player.PlayerData.gang.name
        
        local result = MySQL.Sync.fetchAll('SELECT citizenid, charinfo, gang_grade FROM players WHERE gang = ?', {gangName})
        local members = {}
        
        if result then
            for _, player in ipairs(result) do
                local charInfo = json.decode(player.charinfo)
                local gradeInfo = QBCore.Shared.Gangs[gangName].grades[tostring(player.gang_grade)]
                
                -- Check if player is online
                local isOnline = false
                local onlinePlayer = QBCore.Functions.GetPlayerByCitizenId(player.citizenid)
                if onlinePlayer then
                    isOnline = true
                end
                
                table.insert(members, {
                    citizenid = player.citizenid,
                    name = charInfo.firstname .. ' ' .. charInfo.lastname,
                    grade = player.gang_grade,
                    gradeName = gradeInfo and gradeInfo.name or "Unknown",
                    gradeLevel = gradeInfo and gradeInfo.level or 0,
                    isOnline = isOnline
                })
            end
        end
        
        cb(members)
    else
        cb({})
    end
end)

QBCore.Functions.CreateCallback('sv-gangs:server:GetOnlinePlayers', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local players = {}
    
    if Player then
        for _, xPlayer in pairs(QBCore.Functions.GetQBPlayers()) do
            if xPlayer.PlayerData.source ~= src and xPlayer.PlayerData.gang.name == 'none' then
                table.insert(players, {
                    id = xPlayer.PlayerData.source,
                    citizenid = xPlayer.PlayerData.citizenid,
                    name = xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname
                })
            end
        end
    end
    
    cb(players)
end)

QBCore.Functions.CreateCallback('sv-gangs:server:GetGangTurfs', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.gang.name ~= 'none' then
        local gangName = Player.PlayerData.gang.name
        
        local result = MySQL.Sync.fetchAll('SELECT * FROM gang_turfs WHERE gang = ?', {gangName})
        if result then
            cb(result)
        else
            cb({})
        end
    else
        cb({})
    end
end)

QBCore.Functions.CreateCallback('sv-gangs:server:GetGangLeaderboard', function(source, cb)
    -- Get gangs ordered by turf count and member count
    local result = MySQL.Sync.fetchAll([[
        SELECT g.gang, g.points, COUNT(p.citizenid) as members, COUNT(t.id) as turfs
        FROM gangs g
        LEFT JOIN players p ON p.gang = g.gang
        LEFT JOIN gang_turfs t ON t.gang = g.gang
        GROUP BY g.gang
        ORDER BY g.points DESC, turfs DESC, members DESC
    ]])
    
    local leaderboard = {}
    
    if result then
        for i, gang in ipairs(result) do
            if QBCore.Shared.Gangs[gang.gang] then
                table.insert(leaderboard, {
                    position = i,
                    name = gang.gang,
                    label = QBCore.Shared.Gangs[gang.gang].label,
                    color = GetGangColor(gang.gang),
                    points = gang.points,
                    members = gang.members,
                    turfs = gang.turfs
                })
            end
        end
    end
    
    cb(leaderboard)
end)

-- Helper function to get gang color
function GetGangColor(gangName)
    local result = MySQL.Sync.fetchSingle('SELECT color FROM gangs WHERE gang = ?', {gangName})
    
    if result and result.color then
        return result.color
    end
    
    return Config.DefaultGangColor
end
