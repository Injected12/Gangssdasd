-- SouthVale RP - QBCore Gang System
-- Client Commands

local QBCore = exports['qb-core']:GetCoreObject()

-- Register admin command
RegisterCommand(Config.Commands.Admin, function()
    if not LocalPlayer.state.isLoggedIn then return end
    
    QBCore.Functions.TriggerCallback('sv-gangs:server:IsPlayerAdmin', function(isAdmin)
        if isAdmin then
            OpenGangAdminPanel()
        else
            QBCore.Functions.Notify('You do not have permission to use this command', 'error')
        end
    end)
end, false)

-- Register gang panel command
RegisterCommand(Config.Commands.Panel, function()
    if not LocalPlayer.state.isLoggedIn then return end
    
    local Player = QBCore.Functions.GetPlayerData()
    if Player.gang.name ~= 'none' then
        QBCore.Functions.TriggerCallback('sv-gangs:server:GetGangRankLevel', function(rankLevel)
            if rankLevel and rankLevel >= 70 then -- Lieutenant or higher
                OpenGangPanel()
            else
                QBCore.Functions.Notify('Only high-ranking gang members can access the gang panel', 'error')
            end
        end)
    else
        QBCore.Functions.Notify('You are not in a gang', 'error')
    end
end, false)

-- Register leaderboard command
RegisterCommand(Config.Commands.Leaderboard, function()
    if not LocalPlayer.state.isLoggedIn then return end
    OpenLeaderboardPanel()
end, false)

-- Register key bindings if enabled
if Config.EnableKeybinds then
    if Config.Keybinds.GangPanel then
        RegisterKeyMapping(Config.Commands.Panel, 'Open Gang Panel', 'keyboard', Config.Keybinds.GangPanel)
    end
    
    if Config.Keybinds.Leaderboard then
        RegisterKeyMapping(Config.Commands.Leaderboard, 'Open Gang Leaderboard', 'keyboard', Config.Keybinds.Leaderboard)
    end
end

-- Command suggestions
Citizen.CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.Admin, 'Open the gang admin panel', {})
    TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.Panel, 'Open your gang management panel', {})
    TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.Leaderboard, 'View the gang leaderboard', {})
end)