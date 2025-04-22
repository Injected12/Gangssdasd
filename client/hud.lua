-- SouthVale RP - QBCore Gang System
-- Client HUD Display

local QBCore = exports['qb-core']:GetCoreObject()
local gangHUD = nil
local hudPosition = nil

-- Create the gang HUD display
function CreateGangHUD()
    if not Config.EnableGangHUD then return end
    
    -- Destroy existing HUD if it exists
    if gangHUD then
        DestroyGangHUD()
    end
    
    -- Set HUD position based on config
    local screenW, screenH = GetActiveScreenResolution()
    local offsetX = Config.GangHUDOffsetX
    local offsetY = Config.GangHUDOffsetY
    
    if Config.GangHUDPosition == "top-right" then
        hudPosition = {x = screenW - 170 + offsetX, y = 20 + offsetY}
    elseif Config.GangHUDPosition == "top-left" then
        hudPosition = {x = 20 + offsetX, y = 20 + offsetY}
    elseif Config.GangHUDPosition == "bottom-right" then
        hudPosition = {x = screenW - 170 + offsetX, y = screenH - 60 + offsetY}
    elseif Config.GangHUDPosition == "bottom-left" then
        hudPosition = {x = 20 + offsetX, y = screenH - 60 + offsetY}
    else
        hudPosition = {x = screenW - 170 + offsetX, y = 20 + offsetY} -- Default to top-right
    end
    
    gangHUD = true
end

-- Remove the gang HUD
function DestroyGangHUD()
    gangHUD = nil
    hudPosition = nil
end

-- Update the gang HUD with current player gang info
function UpdateGangHUD()
    if not Config.EnableGangHUD or not isLoggedIn then return end
    
    if not gangHUD then
        CreateGangHUD()
    end
    
    -- Send info to NUI
    SendNUIMessage({
        action = 'updateGangHUD',
        show = true,
        gang = {
            name = PlayerGang.name ~= 'none' and PlayerGang.name or 'No Gang',
            label = PlayerGang.label or 'No Gang',
            rank = PlayerGang.grade and PlayerGang.grade.name or 'None',
            color = PlayerGang.color or Config.DefaultGangColor
        }
    })
}

-- Hide the gang HUD
function HideGangHUD()
    if not gangHUD then return end
    
    SendNUIMessage({
        action = 'updateGangHUD',
        show = false
    })
}

-- Render HUD on screen
Citizen.CreateThread(function()
    while true do
        if isLoggedIn and gangHUD and hudPosition and PlayerGang.name ~= 'none' then
            local gangName = PlayerGang.label or PlayerGang.name
            local gangRank = PlayerGang.grade and PlayerGang.grade.name or 'Member'
            local gangColor = PlayerGang.color or Config.DefaultGangColor
            
            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            
            -- Draw gang name with custom color
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(gangName)
            EndTextCommandDisplayText(hudPosition.x, hudPosition.y)
            
            -- Draw rank below
            SetTextFont(4)
            SetTextScale(0.4, 0.4)
            SetTextColour(200, 200, 200, 255)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(gangRank)
            EndTextCommandDisplayText(hudPosition.x, hudPosition.y + 0.025)
        end
        
        Citizen.Wait(0)
    end
end)

-- Handle screen resolution changes
Citizen.CreateThread(function()
    local lastScreenW, lastScreenH = GetActiveScreenResolution()
    
    while true do
        local screenW, screenH = GetActiveScreenResolution()
        
        if screenW ~= lastScreenW or screenH ~= lastScreenH then
            lastScreenW, lastScreenH = screenW, screenH
            
            -- Recreate HUD with new screen dimensions
            if gangHUD then
                CreateGangHUD()
            end
        end
        
        Citizen.Wait(1000)
    end
end)

-- Initialize HUD on resource start
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        Citizen.Wait(1000)
        if isLoggedIn then
            CreateGangHUD()
            UpdateGangHUD()
        end
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        HideGangHUD()
    end
end)
