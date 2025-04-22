-- SouthVale RP - QBCore Gang System
-- Client Turf Capture Logic

local QBCore = exports['qb-core']:GetCoreObject()
local activeTurfs = {}
local playerInTurf = false
local currentTurf = nil
local turfBlip = nil
local turfArea = nil
local turfTimer = 0
local playerVehicleBeforeTurf = nil

-- Draw 3D markers for turf locations
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        if isLoggedIn and PlayerGang.name ~= 'none' then
            for _, turf in pairs(Config.TurfLocations) do
                local distance = #(playerCoords - vector3(turf.x, turf.y, turf.z))
                
                if distance < 50.0 then
                    sleep = 0
                    
                    -- Check if turf is active
                    local isTurfActive = false
                    for _, activeTurf in pairs(activeTurfs) do
                        if activeTurf.location.x == turf.x and activeTurf.location.y == turf.y then
                            isTurfActive = true
                            break
                        end
                    end
                    
                    if not isTurfActive then
                        -- Draw marker when player is close
                        if distance < 20.0 then
                            DrawMarker(1, turf.x, turf.y, turf.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 1.0, 0, 120, 255, 100, false, true, 2, false, nil, nil, false)
                            
                            -- Show help text when player is very close
                            if distance < 2.0 then
                                QBCore.Functions.DrawText3D(turf.x, turf.y, turf.z, "Press ~g~E~w~ to start capturing turf: " .. turf.name)
                                
                                if IsControlJustReleased(0, 38) then -- E key
                                    TriggerServerEvent('sv-gangs:server:StartTurfCapture', turf)
                                end
                            end
                        end
                    else
                        -- Draw active turf area
                        DrawMarker(1, turf.x, turf.y, turf.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                            Config.TurfCaptureRadius * 2.0, Config.TurfCaptureRadius * 2.0, 3.0, 
                            Config.TurfMarkerColor.r, Config.TurfMarkerColor.g, Config.TurfMarkerColor.b, Config.TurfMarkerColor.a, 
                            false, true, 2, false, nil, nil, false)
                    end
                end
            end
        end
        
        Citizen.Wait(sleep)
    end
end)

-- Handle active turf and player interaction
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        
        if isLoggedIn and PlayerGang.name ~= 'none' and #activeTurfs > 0 then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            for _, turf in pairs(activeTurfs) do
                local turfCoords = vector3(turf.location.x, turf.location.y, turf.location.z)
                local distance = #(playerCoords - turfCoords)
                
                if distance < Config.TurfCaptureRadius then
                    sleep = 0
                    
                    if not playerInTurf then
                        EnterTurf(turf)
                    end
                    
                    -- Display remaining time
                    local timeLeft = math.ceil(turf.endTime - GetGameTimer() / 1000)
                    if timeLeft > 0 then
                        QBCore.Functions.DrawText3D(turfCoords.x, turfCoords.y, turfCoords.z + 1.5, "Turf War: ~r~" .. timeLeft .. "s~w~ remaining")
                    end
                else
                    if playerInTurf and currentTurf and 
                       currentTurf.location.x == turf.location.x and 
                       currentTurf.location.y == turf.location.y then
                        ExitTurf()
                    end
                end
            end
        end
        
        Citizen.Wait(sleep)
    end
end)

-- Enter turf battle area
function EnterTurf(turf)
    playerInTurf = true
    currentTurf = turf
    
    -- Store vehicle and remove player from it
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        playerVehicleBeforeTurf = GetVehiclePedIsIn(playerPed, false)
        TaskLeaveVehicle(playerPed, playerVehicleBeforeTurf, 0)
        Citizen.Wait(1500) -- Wait for player to exit vehicle
        SetEntityCoords(playerVehicleBeforeTurf, 0, 0, 0) -- Temporarily hide the vehicle
    end
    
    -- Notify the server that player entered turf
    TriggerServerEvent('sv-gangs:server:PlayerEnteredTurf', currentTurf.id)
    
    -- Notify the player
    QBCore.Functions.Notify('You entered a turf war! Defend your position until the timer ends.', 'primary')
end

-- Exit turf battle area
function ExitTurf()
    playerInTurf = false
    
    -- Notify the server that player exited turf
    if currentTurf then
        TriggerServerEvent('sv-gangs:server:PlayerExitedTurf', currentTurf.id)
    end
    
    currentTurf = nil
    
    QBCore.Functions.Notify('You left the turf war!', 'error')
end

-- Handle player death in turf
AddEventHandler('baseevents:onPlayerDied', function()
    if playerInTurf and currentTurf then
        TriggerServerEvent('sv-gangs:server:PlayerDiedInTurf', currentTurf.id)
        
        -- Respawn player outside turf area
        Citizen.Wait(2000) -- Wait for death animation
        local playerPed = PlayerPedId()
        local respawnCoords = GetRespawnCoordinatesOutsideTurf(currentTurf.location)
        
        SetEntityCoords(playerPed, respawnCoords.x, respawnCoords.y, respawnCoords.z)
        SetEntityHeading(playerPed, respawnCoords.h)
        
        -- Heal player
        SetEntityHealth(playerPed, 200)
    end
end)

-- Calculate respawn point outside turf
function GetRespawnCoordinatesOutsideTurf(turfLoc)
    local respawnDistance = Config.TurfCaptureRadius + 10.0
    local respawnHeading = math.random(0, 359)
    
    local respawnX = turfLoc.x + respawnDistance * math.cos(math.rad(respawnHeading))
    local respawnY = turfLoc.y + respawnDistance * math.sin(math.rad(respawnHeading))
    local z = 0.0
    local ground = 0
    
    -- Find ground Z coordinate
    for i = 1, 10 do
        local foundGround, groundZ = GetGroundZFor_3dCoord(respawnX, respawnY, 100.0 + i * 10, 0)
        if foundGround then
            z = groundZ + 1.0
            ground = 1
            break
        end
    end
    
    if ground == 0 then
        z = turfLoc.z -- Fallback to turf Z if ground not found
    end
    
    return {x = respawnX, y = respawnY, z = z, h = respawnHeading}
end

-- Create blip for active turf
function CreateTurfBlip(turf)
    if turfBlip then
        RemoveBlip(turfBlip)
    end
    
    turfBlip = AddBlipForRadius(turf.location.x, turf.location.y, turf.location.z, Config.TurfCaptureRadius)
    SetBlipColour(turfBlip, 1) -- Red
    SetBlipAlpha(turfBlip, 128)
    
    local blip = AddBlipForCoord(turf.location.x, turf.location.y, turf.location.z)
    SetBlipSprite(blip, 310) -- Combat sprite
    SetBlipColour(blip, 1) -- Red
    SetBlipScale(blip, 1.2)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Turf War: " .. turf.location.name)
    EndTextCommandSetBlipName(blip)
    
    -- Store blip in turf data
    turf.blip = blip
    
    return blip
end

-- Remove turf blip
function RemoveTurfBlip()
    if turfBlip then
        RemoveBlip(turfBlip)
        turfBlip = nil
    end
    
    for _, turf in pairs(activeTurfs) do
        if turf.blip then
            RemoveBlip(turf.blip)
            turf.blip = nil
        end
    end
end

-- Event handlers
RegisterNetEvent('sv-gangs:client:SyncActiveTurfs', function(turfs)
    activeTurfs = turfs
    
    -- Update blips
    RemoveTurfBlip()
    
    for _, turf in pairs(activeTurfs) do
        CreateTurfBlip(turf)
    end
    
    -- If player was in a turf that's no longer active, exit turf state
    if playerInTurf then
        local stillInActiveTurf = false
        
        for _, turf in pairs(activeTurfs) do
            if currentTurf and currentTurf.id == turf.id then
                stillInActiveTurf = true
                break
            end
        end
        
        if not stillInActiveTurf then
            ExitTurf()
            
            -- Restore player vehicle
            if playerVehicleBeforeTurf then
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                
                SetEntityCoords(playerVehicleBeforeTurf, playerCoords.x + 5.0, playerCoords.y, playerCoords.z)
                playerVehicleBeforeTurf = nil
            end
        end
    end
end)

RegisterNetEvent('sv-gangs:client:TurfCaptureEnded', function(turfId, winningGang)
    -- Check if player was in this turf
    if playerInTurf and currentTurf and currentTurf.id == turfId then
        ExitTurf()
        
        -- Restore player vehicle if it was stored
        if playerVehicleBeforeTurf then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            SetEntityCoords(playerVehicleBeforeTurf, playerCoords.x + 5.0, playerCoords.y, playerCoords.z)
            playerVehicleBeforeTurf = nil
        end
    end
    
    -- Notify player about who won
    local message = winningGang == PlayerGang.name 
        and "Your gang successfully captured the turf!" 
        or "The turf was captured by " .. winningGang .. "!"
    
    QBCore.Functions.Notify(message, 'primary', 10000)
end)

-- When player accidentally disconnects during turf war
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and playerVehicleBeforeTurf then
        -- Attempt to restore vehicle if player was in turf
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        SetEntityCoords(playerVehicleBeforeTurf, playerCoords.x + 5.0, playerCoords.y, playerCoords.z)
        playerVehicleBeforeTurf = nil
    end
end)
