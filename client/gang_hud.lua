local QBCore = exports['qb-core']:GetCoreObject()

-- Variables
local hudVisible = true
local PlayerGang = nil

-- Events
RegisterNetEvent('sv-gangsystem:client:SetPlayerGang', function(gangData)
    PlayerGang = gangData
    TriggerEvent('sv-gangsystem:client:UpdateGangHUD')
end)

RegisterNetEvent('sv-gangsystem:client:UpdateGangHUD', function()
    if not Config.EnableGangHUD then return end
    SendNUIMessage({
        action = 'updateGangHUD',
        show = hudVisible,
        data = PlayerGang
    })
end)

-- Toggle HUD visibility
RegisterCommand('toggleganghud', function()
    hudVisible = not hudVisible
    TriggerEvent('sv-gangsystem:client:UpdateGangHUD')
    QBCore.Functions.Notify(hudVisible and 'Gang HUD Enabled' or 'Gang HUD Disabled', 'success')
end, false)

TriggerEvent('chat:addSuggestion', '/toggleganghud', 'Toggle the visibility of the gang HUD')

-- Initialize HUD on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    -- Wait for player to be loaded
    Wait(1000)
    if LocalPlayer.state.isLoggedIn then
        TriggerServerEvent('sv-gangsystem:server:RequestGangData')
    end
end)

-- Set initial HUD position
Citizen.CreateThread(function()
    Wait(1000) -- Wait for NUI to load
    SendNUIMessage({
        action = 'setHUDPosition',
        position = Config.HUDPosition,
        offsetX = Config.HUDOffsetX,
        offsetY = Config.HUDOffsetY
    })
end)
