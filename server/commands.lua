local QBCore = exports['qb-core']:GetCoreObject()

-- Register Commands
QBCore.Commands.Add('gangadmin', 'Open gang admin panel (Admin Only)', {}, false, function(source, _)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if Player and (QBCore.Functions.HasPermission(source, Config.AdminPermission) or Config.AdminGroups[Player.PlayerData.group]) then
        TriggerClientEvent('sv-gangsystem:client:OpenAdminPanel', source)
    else
        TriggerClientEvent('QBCore:Notify', source, 'You do not have permission to use this command', 'error')
    end
end)

QBCore.Commands.Add('gangpanel', 'Open gang panel (Gang Leaders Only)', {}, false, function(source, _)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    exports['sv-gangsystem']:GetPlayerGang(Player.PlayerData.citizenid, function(gangData)
        if gangData and gangData.rank >= Config.LeaderRankLevel then
            TriggerClientEvent('sv-gangsystem:client:OpenGangPanel', source)
        else
            TriggerClientEvent('QBCore:Notify', source, 'You need to be a gang leader to use this command', 'error')
        end
    end)
end)

QBCore.Commands.Add('leaderboard', 'View gang leaderboard', {}, false, function(source, _)
    TriggerClientEvent('sv-gangsystem:client:OpenLeaderboard', source)
end)
