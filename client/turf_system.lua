local QBCore = exports['qb-core']:GetCoreObject()

-- Variables
local activeTurfCaptures = {}
local inTurf = false
local currentTurf = nil
local turfBlips = {}
local captureZones = {}
local captureMarkers = {}

-- Initialize turf system
Citizen.CreateThread(function()
    -- Create blips for all turfs
    for _, turf in pairs(Config.TurfLocations) do
        local blip = AddBlipForRadius(turf.coords.x, turf.coords.y, turf.coords.z, turf.radius)
        SetBlipHighDetail(blip, true)
        SetBlipColour(blip, 1) -- Red
        SetBlipAlpha(blip, 128)
        
        turfBlips[turf.name] = blip
        
        -- Create trigger zones
        captureZones[turf.name] = CircleZone:Create(
            vector3(turf.coords.x, turf.coords.y, turf.coords.z), 
            2.0, 
            {
                name = "capture_" .. turf.name,
                debugPoly = false
            }
        )
        
        captureZones[turf.name]:onPlayerInOut(function(isPointInside)
            if isPointInside and not activeTurfCaptures[turf.name] then
                -- Show help text when player is near capture point
                exports['qb-core']:DrawText('[E] Start Turf Capture', 'left')
            else
                exports['qb-core']:HideText()
            end
        end)
    end
end)

-- Main thread for turf interaction
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        for turfName, zone in pairs(captureZones) do
            if zone:isPointInside(playerCoords) and not activeTurfCaptures[turfName] then
                sleep = 0
                
                -- Capture turf on E press
                if IsControlJustPressed(0, 38) then -- E key
                    TriggerServerEvent('sv-gangsystem:server:StartTurfCapture', turfName)
                end
            end
        end
        
        -- Check if player is in any active turf
        local isInAnyTurf = false
        for turfName, turfData in pairs(activeTurfCaptures) do
            local turf = nil
            for _, t in pairs(Config.TurfLocations) do
                if t.name == turfName then
                    turf = t
                    break
                end
            end
            
            if turf then
                local distance = #(playerCoords - vector3(turf.coords.x, turf.coords.y, turf.coords.z))
                if distance <= turf.radius then
                    isInAnyTurf = true
                    
                    if not inTurf or currentTurf ~= turfName then
                        -- Player just entered the turf
                        inTurf = true
                        currentTurf = turfName
                        TriggerServerEvent('sv-gangsystem:server:JoinTurfCapture', turfName)
                    end
                    
                    break
                end
            end
        end
        
        if inTurf and not isInAnyTurf then
            -- Player left the turf
            TriggerServerEvent('sv-gangsystem:server:LeaveTurfCapture', currentTurf)
            inTurf = false
            currentTurf = nil
            
            -- Restore player's vehicle
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if vehicle ~= 0 then
                SetEntityVisible(vehicle, true, false)
                SetEntityCollision(vehicle, true, true)
            end
        end
        
        Wait(sleep)
    end
end)

-- Thread for drawing turf markers
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for turfName, active in pairs(activeTurfCaptures) do
            for _, turf in pairs(Config.TurfLocations) do
                if turf.name == turfName then
                    local distance = #(playerCoords - vector3(turf.coords.x, turf.coords.y, turf.coords.z))
                    
                    if distance <= turf.radius + 50.0 then
                        sleep = 0
                        
                        -- Draw capture circle on the ground
                        DrawMarker(
                            1, -- type
                            turf.coords.x, turf.coords.y, turf.coords.z - 1.0,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            turf.radius * 2.0, turf.radius * 2.0, 2.0,
                            Config.TurfMarkerColor.r, Config.TurfMarkerColor.g, Config.TurfMarkerColor.b, Config.TurfMarkerColor.a,
                            false, false, 2, false, nil, nil, false
                        )
                        
                        -- Draw center point
                        DrawMarker(
                            1, -- type
                            turf.coords.x, turf.coords.y, turf.coords.z - 0.97,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            2.0, 2.0, 1.0,
                            255, 0, 0, 200,
                            false, false, 2, false, nil, nil, false
                        )
                    end
                    
                    break
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Events
RegisterNetEvent('sv-gangsystem:client:TurfCaptureStarted', function(turfName, turfData, gangData)
    local PlayerGang = exports['sv-gangsystem']:GetPlayerGang()
    
    -- Set turf as active
    activeTurfCaptures[turfName] = true
    
    -- Update turf blip color
    if turfBlips[turfName] then
        SetBlipColour(turfBlips[turfName], 1) -- Red for active capture
        SetBlipAlpha(turfBlips[turfName], 200)
    end
    
    -- Notify player
    if Config.TurfCaptureNotification then
        QBCore.Functions.Notify(gangData.name .. ' is capturing ' .. turfName, 'inform', 5000)
    end
    
    -- Play sound for all players
    PlaySoundFrontend(-1, "MP_WAVE_COMPLETE", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
end)

RegisterNetEvent('sv-gangsystem:client:JoinTurfCapture', function(turfName, turfData, captureData)
    -- Hide player's vehicle if they're in one
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 then
        SetEntityVisible(vehicle, false, false)
        SetEntityCollision(vehicle, false, false)
    end
    
    -- Show turf capture timer
    local timeLeft = captureData.timeLeft
    QBCore.Functions.Notify('Turf capture in progress: ' .. timeLeft .. ' seconds remaining', 'primary', 10000)
    
    -- Start timer display
    Citizen.CreateThread(function()
        while inTurf and currentTurf == turfName and timeLeft > 0 do
            Wait(1000)
            timeLeft = timeLeft - 1
            
            -- Draw time remaining on screen
            DrawTurfTimer(timeLeft)
            
            if timeLeft <= 0 then
                break
            end
        end
    end)
end)

RegisterNetEvent('sv-gangsystem:client:TurfCaptureEnded', function(turfName, winningGangId)
    -- Remove turf from active list
    activeTurfCaptures[turfName] = nil
    
    -- Update turf blip color
    if turfBlips[turfName] then
        SetBlipColour(turfBlips[turfName], 3) -- Blue for inactive
        SetBlipAlpha(turfBlips[turfName], 128)
    end
    
    -- Reset current turf if player is in this one
    if currentTurf == turfName then
        inTurf = false
        currentTurf = nil
        
        -- Restore player's vehicle
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle ~= 0 then
            SetEntityVisible(vehicle, true, false)
            SetEntityCollision(vehicle, true, true)
        end
    end
    
    -- Play sound for all players
    PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 1)
end)

RegisterNetEvent('sv-gangsystem:client:RespawnOutsideTurf', function(turfData)
    -- Force respawn outside the turf
    local playerPed = PlayerPedId()
    local turf = turfData.coords
    local heading = turf.w
    
    -- Calculate position outside the turf
    local outsidePos = vector3(
        turf.x + math.cos(math.rad(heading)) * (turfData.radius + Config.TurfRespawnDistance),
        turf.y + math.sin(math.rad(heading)) * (turfData.radius + Config.TurfRespawnDistance),
        turf.z
    )
    
    -- Teleport player
    SetEntityCoords(playerPed, outsidePos.x, outsidePos.y, outsidePos.z, false, false, false, false)
    SetEntityHeading(playerPed, (heading + 180.0) % 360)
    
    -- Restore player's health
    SetEntityHealth(playerPed, 200)
    
    QBCore.Functions.Notify('You died and respawned outside the turf', 'inform')
end)

-- Functions
function DrawTurfTimer(seconds)
    SetTextFont(4)
    SetTextScale(0.5, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName('Turf Capture: ' .. seconds .. 's')
    EndTextCommandDisplayText(0.5, 0.1)
end

-- Check if player died during turf capture
Citizen.CreateThread(function()
    while true do
        Wait(500)
        
        if inTurf and currentTurf then
            local playerPed = PlayerPedId()
            
            if IsEntityDead(playerPed) then
                TriggerServerEvent('sv-gangsystem:server:PlayerDiedInTurf', currentTurf)
                Wait(2000) -- Wait for death animation
            end
        end
        
        Wait(500)
    end
end)
