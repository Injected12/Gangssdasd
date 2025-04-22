local QBCore = exports['qb-core']:GetCoreObject()

-- Register commands for keybindings and chat suggestions
Citizen.CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/gangadmin', 'Open the Gang Admin Panel (Admin Only)')
    TriggerEvent('chat:addSuggestion', '/gangpanel', 'Open the Gang Management Panel (Gang Leaders Only)')
    TriggerEvent('chat:addSuggestion', '/leaderboard', 'Open the Gang Leaderboard')
end)
