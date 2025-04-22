-- SouthVale RP - QBCore Gang System
-- Client Gang HUD

local QBCore = exports['qb-core']:GetCoreObject()

-- Variables
local hudVisible = true
local gangData = nil

-- Function to update the Gang HUD
function UpdateGangHUD()
    if not Config.EnableGangHUD then return end
    
    local Player = QBCore.Functions.GetPlayerData()
    
    if Player.gang and Player.gang.name ~= 'none' then
        -- Get gang color from config or default
        local gangColor = Config.DefaultGangColor
        local gangName = Player.gang.label or Player.gang.name
        local gangRank = Player.gang.grade and Player.gang.grade.name or 'Member'
        
        -- Check if we have a custom color for this gang
        if Config.GangColors[Player.gang.name] then
            gangColor = Config.GangColors[Player.gang.name]
        end
        
        -- Send to NUI
        SendNUIMessage({
            action = 'updateGangHUD',
            show = hudVisible,
            gang = {
                label = gangName,
                rank = gangRank,
                color = gangColor
            }
        })
    else
        -- Hide HUD if not in gang
        SendNUIMessage({
            action = 'updateGangHUD',
            show = false
        })
    end
end

-- Toggle HUD visibility
RegisterCommand('toggleganghud', function()
    hudVisible = not hudVisible
    UpdateGangHUD()
    QBCore.Functions.Notify(hudVisible and 'Gang HUD Enabled' or 'Gang HUD Disabled', 'success')
end, false)

TriggerEvent('chat:addSuggestion', '/toggleganghud', 'Toggle the visibility of the gang HUD')

-- Initialize HUD on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    -- Wait for player to be loaded
    Wait(1000)
    if LocalPlayer.state.isLoggedIn then
        UpdateGangHUD()
    end
end)

-- Key binding for toggling HUD if enabled
if Config.EnableKeybinds and Config.Keybinds.ToggleHUD then
    RegisterKeyMapping('toggleganghud', 'Toggle Gang HUD', 'keyboard', Config.Keybinds.ToggleHUD)
end

-- Set HUD position based on config (top-right, top-left, etc.)
Citizen.CreateThread(function()
    Wait(1000) -- Wait for NUI to load
    
    local position = Config.HUDPosition or 'top-right'
    local offsetX = Config.HUDOffsetX or 0
    local offsetY = Config.HUDOffsetY or 0
    
    SendNUIMessage({
        action = 'setHUDPosition',
        position = position,
        offsetX = offsetX,
        offsetY = offsetY
    })
    
    -- Initial HUD update
    UpdateGangHUD()
end)
