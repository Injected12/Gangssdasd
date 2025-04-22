-- SouthVale RP - QBCore Gang System
-- Server Gang Management

local QBCore = exports['qb-core']:GetCoreObject()

-- Check if player is in gang
function IsPlayerInGang(src, gangName)
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.gang.name == gangName then
        return true
    end
    
    return false
end

-- Check if player has required gang rank level
function HasGangRankLevel(src, requiredLevel)
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.gang.name == 'none' then
        return false
    end
    
    local playerRankLevel = Player.PlayerData.gang.grade and Player.PlayerData.gang.grade.level or 0
    
    return playerRankLevel >= requiredLevel
end

-- Notify all gang members
function NotifyGangMembers(gangName, message, excludeSrc)
    local Players = QBCore.Functions.GetQBPlayers()
    
    for _, Player in pairs(Players) do
        if Player.PlayerData.gang.name == gangName and (not excludeSrc or Player.PlayerData.source ~= excludeSrc) then
            TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, message, 'primary')
        end
    end
end

-- Get all gang members (online and offline)
function GetAllGangMembers(gangName, cb)
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
        
        -- Sort members by rank level (descending)
        table.sort(members, function(a, b)
            return a.gradeLevel > b.gradeLevel
        end)
    end
    
    if cb then
        cb(members)
    end
    
    return members
end

-- Get online gang members
function GetOnlineGangMembers(gangName)
    local onlineMembers = {}
    local Players = QBCore.Functions.GetQBPlayers()
    
    for _, Player in pairs(Players) do
        if Player.PlayerData.gang.name == gangName then
            table.insert(onlineMembers, {
                src = Player.PlayerData.source,
                citizenid = Player.PlayerData.citizenid,
                name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                grade = Player.PlayerData.gang.grade,
                rank = Player.PlayerData.gang.grade and Player.PlayerData.gang.grade.name or 'Unknown'
            })
        end
    end
    
    return onlineMembers
end

-- Get gang rank by level
function GetGangRankByLevel(gangName, level)
    if not QBCore.Shared.Gangs[gangName] then return nil end
    
    for grade, info in pairs(QBCore.Shared.Gangs[gangName].grades) do
        if info.level == level then
            return {grade = grade, name = info.name, level = info.level}
        end
    end
    
    return nil
end

-- Find next rank in gang hierarchy (up or down)
function FindNextGangRank(gangName, currentLevel, direction)
    if not QBCore.Shared.Gangs[gangName] then return nil end
    
    local ranks = {}
    for grade, info in pairs(QBCore.Shared.Gangs[gangName].grades) do
        table.insert(ranks, {grade = grade, name = info.name, level = info.level})
    end
    
    -- Sort ranks by level
    table.sort(ranks, function(a, b)
        return a.level < b.level
    end)
    
    local currentIndex = nil
    for i, rank in ipairs(ranks) do
        if rank.level == currentLevel then
            currentIndex = i
            break
        end
    end
    
    if not currentIndex then return nil end
    
    if direction == 'up' and currentIndex < #ranks then
        return ranks[currentIndex + 1]
    elseif direction == 'down' and currentIndex > 1 then
        return ranks[currentIndex - 1]
    end
    
    return nil
end

-- Gang events
RegisterNetEvent('sv-gangs:server:UpdateGangInfo', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.gang.name ~= 'none' then
        local gangName = Player.PlayerData.gang.name
        
        -- Check if player has permission
        if HasGangRankLevel(src, 90) then
            if data.label then
                -- Update gang label
                QBCore.Shared.Gangs[gangName].label = data.label
                MySQL.Async.execute('UPDATE gangs SET label = ? WHERE gang = ?', {data.label, gangName})
                
                NotifyGangMembers(gangName, 'Gang name updated to: ' .. data.label, src)
                TriggerClientEvent('QBCore:Notify', src, 'Gang name updated successfully.', 'success')
            end
            
            if data.color then
                -- Update gang color
                MySQL.Async.execute('UPDATE gangs SET color = ? WHERE gang = ?', {data.color, gangName})
                
                NotifyGangMembers(gangName, 'Gang colors have been updated.', src)
                TriggerClientEvent('QBCore:Notify', src, 'Gang color updated successfully.', 'success')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'Only gang bosses can update gang information.', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You are not in a gang.', 'error')
    end
end)

-- Kick member from gang
RegisterNetEvent('sv-gangs:server:KickFromGang', function(citizenid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.gang.name ~= 'none' then
        local gangName = Player.PlayerData.gang.name
        
        -- Check if player has permission
        if HasGangRankLevel(src, 90) then
            -- Make sure player is not trying to kick themselves
            if Player.PlayerData.citizenid == citizenid then
                TriggerClientEvent('QBCore:Notify', src, 'You cannot kick yourself from the gang.', 'error')
                return
            end
            
            -- Get target player info
            local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
            local targetName = "Unknown"
            
            -- Get target name if offline
            if not targetPlayer then
                local result = MySQL.Sync.fetchAll('SELECT charinfo FROM players WHERE citizenid = ?', {citizenid})
                if result and result[1] then
                    local charInfo = json.decode(result[1].charinfo)
                    targetName = charInfo.firstname .. ' ' .. charInfo.lastname
                end
            else
                targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
                
                -- Check if target outranks kicker
                if targetPlayer.PlayerData.gang.grade and targetPlayer.PlayerData.gang.grade.level > Player.PlayerData.gang.grade.level then
                    TriggerClientEvent('QBCore:Notify', src, 'You cannot kick someone with a higher rank.', 'error')
                    return
                end
            end
            
            -- Update database
            MySQL.Async.execute('UPDATE players SET gang = ?, gang_grade = ? WHERE citizenid = ?', 
                {'none', 0, citizenid})
            
            -- Update online player
            if targetPlayer then
                targetPlayer.Functions.SetGang('none', 0)
                TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 
                    'You have been kicked from ' .. QBCore.Shared.Gangs[gangName].label, 'error')
            end
            
            -- Notify gang
            NotifyGangMembers(gangName, targetName .. ' has been kicked from the gang.', src)
            TriggerClientEvent('QBCore:Notify', src, 'Player has been kicked from the gang.', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Only gang bosses can kick members.', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You are not in a gang.', 'error')
    end
end)

-- Leave gang
RegisterNetEvent('sv-gangs:server:LeaveGang', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and Player.PlayerData.gang.name ~= 'none' then
        local gangName = Player.PlayerData.gang.name
        local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        
        -- Check if player is the highest ranking member (gang boss)
        if HasGangRankLevel(src, 100) then
            -- See if there are other members with boss rank
            local otherBosses = false
            local gangMembers = GetAllGangMembers(gangName)
            
            for _, member in ipairs(gangMembers) do
                if member.gradeLevel == 100 and member.citizenid ~= Player.PlayerData.citizenid then
                    otherBosses = true
                    break
                end
            end
            
            if not otherBosses then
                -- Check if there are other members at all
                if #gangMembers > 1 then
                    -- Promote next highest member to boss
                    local highestMember = nil
                    local highestRank = -1
                    
                    for _, member in ipairs(gangMembers) do
                        if member.citizenid ~= Player.PlayerData.citizenid and member.gradeLevel > highestRank then
                            highestMember = member
                            highestRank = member.gradeLevel
                        end
                    end
                    
                    if highestMember then
                        -- Get boss rank
                        local bossRank = GetGangRankByLevel(gangName, 100)
                        
                        if bossRank then
                            -- Update database
                            MySQL.Async.execute('UPDATE players SET gang_grade = ? WHERE citizenid = ?', 
                                {bossRank.grade, highestMember.citizenid})
                            
                            -- Update online player
                            local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(highestMember.citizenid)
                            if targetPlayer then
                                targetPlayer.Functions.SetGang(gangName, tonumber(bossRank.grade))
                                TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 
                                    'You have been promoted to ' .. bossRank.name .. '!', 'success')
                            end
                            
                            NotifyGangMembers(gangName, highestMember.name .. ' has been promoted to ' .. bossRank.name .. '!', src)
                        end
                    end
                end
            end
        end
        
        -- Remove player from gang
        Player.Functions.SetGang('none', 0)
        
        -- Notify gang
        NotifyGangMembers(gangName, playerName .. ' has left the gang.', src)
        TriggerClientEvent('QBCore:Notify', src, 'You have left the gang.', 'primary')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You are not in a gang.', 'error')
    end
end)
