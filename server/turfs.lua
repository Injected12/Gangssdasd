-- SouthVale RP - QBCore Gang System
-- Server Turf Management

local QBCore = exports['qb-core']:GetCoreObject()
local activeTurfs = {}
local turfCooldowns = {}

-- Start turf capture
RegisterNetEvent('sv-gangs:server:StartTurfCapture', function(turf)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.gang.name == 'none' then
        TriggerClientEvent('QBCore:Notify', src, 'You need to be in a gang to capture turfs.', 'error')
        return
    end
    
    local gangName = Player.PlayerData.gang.name
    local gangLabel = QBCore.Shared.Gangs[gangName].label
    
    -- Check if turf is on cooldown
    local turfKey = string.format("%.1f_%.1f", turf.x, turf.y)
    if turfCooldowns[turfKey] and (os.time() < turfCooldowns[turfKey]) then
        local remainingTime = math.ceil((turfCooldowns[turfKey] - os.time()) / 60)
        TriggerClientEvent('QBCore:Notify', src, 'This turf is on cooldown. Try again in ' .. remainingTime .. ' minutes.', 'error')
        return
    end
    
    -- Check if this location is already an active turf
    for _, activeTurf in pairs(activeTurfs) do
        if #(vector3(activeTurf.location.x, activeTurf.location.y, activeTurf.location.z) - vector3(turf.x, turf.y, turf.z)) < 50.0 then
            TriggerClientEvent('QBCore:Notify', src, 'This turf is already being captured.', 'error')
            return
        end
    end
    
    -- Check if turf already owned by this gang
    local existingTurf = GetTurfByCoordinates(turf.x, turf.y, 50.0)
    if existingTurf and existingTurf.gang == gangName then
        TriggerClientEvent('QBCore:Notify', src, 'Your gang already controls this turf.', 'error')
        return
    end
    
    -- Create new active turf
    local turfId = #activeTurfs + 1
    activeTurfs[turfId] = {
        id = turfId,
        location = turf,
        startedBy = {
            src = src,
            citizenid = Player.PlayerData.citizenid,
            gang = gangName
        },
        participants = {},
        gangsInvolved = {},
        startTime = os.time(),
        endTime = os.time() + Config.TurfCaptureDuration,
        status = 'active',
        existingTurfId = existingTurf and existingTurf.id or nil
    }
    
    -- Add starter to participants
    activeTurfs[turfId].participants[src] = {
        citizenid = Player.PlayerData.citizenid,
        gang = gangName,
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        kills = 0,
        deaths = 0
    }
    
    -- Track gang participation
    activeTurfs[turfId].gangsInvolved[gangName] = {
        members = 1,
        kills = 0,
        deaths = 0
    }
    
    -- Set the turf cooldown for this location
    turfCooldowns[turfKey] = os.time() + Config.TurfCooldown
    
    -- Notify all players
    if Config.EnableTurfNotifications then
        TriggerClientEvent('QBCore:Notify', -1, gangLabel .. ' is attempting to capture turf in ' .. turf.name .. '!', 'primary', 10000)
    else
        -- Only notify gang members
        local gangMembers = GetOnlineGangMembers(gangName)
        for _, member in ipairs(gangMembers) do
            TriggerClientEvent('QBCore:Notify', member.src, 'Your gang is attempting to capture turf in ' .. turf.name .. '!', 'primary', 10000)
        end
    end
    
    -- Sync active turfs to all clients
    SyncActiveTurfs()
    
    -- Start turf timer
    StartTurfTimer(turfId)
end)

-- Player entered turf area
RegisterNetEvent('sv-gangs:server:PlayerEnteredTurf', function(turfId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or not activeTurfs[turfId] then return end
    
    local gangName = Player.PlayerData.gang.name
    
    if gangName == 'none' then
        TriggerClientEvent('QBCore:Notify', src, 'You need to be in a gang to participate in turf wars!', 'error')
        return
    end
    
    -- Add player to participants if not already there
    if not activeTurfs[turfId].participants[src] then
        activeTurfs[turfId].participants[src] = {
            citizenid = Player.PlayerData.citizenid,
            gang = gangName,
            name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            kills = 0,
            deaths = 0
        }
        
        -- Update gang involvement
        if not activeTurfs[turfId].gangsInvolved[gangName] then
            activeTurfs[turfId].gangsInvolved[gangName] = {
                members = 1,
                kills = 0,
                deaths = 0
            }
        else
            activeTurfs[turfId].gangsInvolved[gangName].members = activeTurfs[turfId].gangsInvolved[gangName].members + 1
        end
        
        -- Notify gang members
        local gangLabel = QBCore.Shared.Gangs[gangName].label
        local memberName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        
        local gangMembers = GetOnlineGangMembers(gangName)
        for _, member in ipairs(gangMembers) do
            if member.src ~= src then
                TriggerClientEvent('QBCore:Notify', member.src, memberName .. ' has joined the turf war!', 'primary')
            end
        end
    end
    
    -- Sync active turfs
    SyncActiveTurfs()
end)

-- Player exited turf area
RegisterNetEvent('sv-gangs:server:PlayerExitedTurf', function(turfId)
    local src = source
    
    if not activeTurfs[turfId] or not activeTurfs[turfId].participants[src] then return end
    
    local participantData = activeTurfs[turfId].participants[src]
    local gangName = participantData.gang
    
    -- Remove player from participants
    activeTurfs[turfId].participants[src] = nil
    
    -- Update gang involvement
    if activeTurfs[turfId].gangsInvolved[gangName] then
        activeTurfs[turfId].gangsInvolved[gangName].members = math.max(0, activeTurfs[turfId].gangsInvolved[gangName].members - 1)
    end
    
    -- Check if any players remain in turf
    local anyPlayersLeft = false
    for _ in pairs(activeTurfs[turfId].participants) do
        anyPlayersLeft = true
        break
    end
    
    if not anyPlayersLeft and activeTurfs[turfId].status == 'active' then
        -- End turf capture early if everyone left
        activeTurfs[turfId].status = 'abandoned'
        
        -- Announce the turf has been abandoned
        if Config.EnableTurfNotifications then
            TriggerClientEvent('QBCore:Notify', -1, 'The turf war at ' .. activeTurfs[turfId].location.name .. ' has been abandoned!', 'error', 10000)
        end
        
        -- Mark for cleanup
        activeTurfs[turfId].endTime = os.time()
    end
    
    -- Sync active turfs
    SyncActiveTurfs()
end)

-- Player died in turf
RegisterNetEvent('sv-gangs:server:PlayerDiedInTurf', function(turfId)
    local src = source
    
    if not activeTurfs[turfId] or not activeTurfs[turfId].participants[src] then return end
    
    local gangName = activeTurfs[turfId].participants[src].gang
    
    -- Increment death counter
    activeTurfs[turfId].participants[src].deaths = activeTurfs[turfId].participants[src].deaths + 1
    
    -- Update gang stats
    if activeTurfs[turfId].gangsInvolved[gangName] then
        activeTurfs[turfId].gangsInvolved[gangName].deaths = activeTurfs[turfId].gangsInvolved[gangName].deaths + 1
    end
    
    -- Sync active turfs
    SyncActiveTurfs()
end)

-- Register kill in turf war
RegisterNetEvent('sv-gangs:server:TurfKill', function(turfId, victimId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Victim = QBCore.Functions.GetPlayer(victimId)
    
    if not Player or not Victim or not activeTurfs[turfId] then return end
    
    if activeTurfs[turfId].participants[src] and activeTurfs[turfId].participants[victimId] then
        local killerGang = activeTurfs[turfId].participants[src].gang
        
        -- Increment kill counter
        activeTurfs[turfId].participants[src].kills = activeTurfs[turfId].participants[src].kills + 1
        
        -- Update gang stats
        if activeTurfs[turfId].gangsInvolved[killerGang] then
            activeTurfs[turfId].gangsInvolved[killerGang].kills = activeTurfs[turfId].gangsInvolved[killerGang].kills + 1
        end
        
        -- Sync active turfs
        SyncActiveTurfs()
    end
end)

-- Start turf timer
function StartTurfTimer(turfId)
    if not activeTurfs[turfId] then return end
    
    -- Set a timeout for when turf capture should end
    SetTimeout(Config.TurfCaptureDuration * 1000, function()
        if activeTurfs[turfId] and activeTurfs[turfId].status == 'active' then
            EndTurfCapture(turfId)
        end
    end)
    
    -- Also set a 10 second check interval to detect abandoned turfs
    local function CheckTurf()
        if not activeTurfs[turfId] or activeTurfs[turfId].status ~= 'active' then return end
        
        -- Check if timed out
        if os.time() >= activeTurfs[turfId].endTime then
            EndTurfCapture(turfId)
            return
        end
        
        -- Schedule next check
        SetTimeout(10000, CheckTurf)
    end
    
    CheckTurf()
end

-- End turf capture
function EndTurfCapture(turfId)
    if not activeTurfs[turfId] then return end
    
    local turf = activeTurfs[turfId]
    local winningGang = nil
    local winningScore = -1
    
    -- Determine the winning gang
    for gang, stats in pairs(turf.gangsInvolved) do
        -- Only consider gangs with active members
        if stats.members > 0 then
            local score = (stats.kills * 10) - (stats.deaths * 5) + (stats.members * 20)
            
            if score > winningScore then
                winningGang = gang
                winningScore = score
            end
        end
    end
    
    -- If no winning gang (everyone left), the turf remains with current owner
    if not winningGang then
        -- Get current owner if the turf exists
        if turf.existingTurfId then
            local existingTurf = MySQL.Sync.fetchSingle('SELECT gang FROM gang_turfs WHERE id = ?', {turf.existingTurfId})
            if existingTurf then
                winningGang = existingTurf.gang
            end
        end
        
        -- If still no winner, default to the gang that started the capture
        if not winningGang then
            winningGang = turf.startedBy.gang
        end
    end
    
    -- Update database
    if winningGang then
        if turf.existingTurfId then
            -- Transfer existing turf
            TransferTurf(turf.existingTurfId, winningGang)
        else
            -- Create new turf record
            AddTurfToGang(winningGang, turf.location.x, turf.location.y, turf.location.z, turf.location.name)
        }
        
        -- Add points to winning gang
        AddGangPoints(winningGang, Config.TurfRewardPoints)
        
        -- Notify everyone
        local winningGangLabel = QBCore.Shared.Gangs[winningGang].label
        
        if Config.EnableTurfNotifications then
            TriggerClientEvent('QBCore:Notify', -1, winningGangLabel .. ' has captured the turf at ' .. turf.location.name .. '!', 'primary', 10000)
        end
        
        -- Notify all gang members in the winning gang
        local gangMembers = GetOnlineGangMembers(winningGang)
        for _, member in ipairs(gangMembers) do
            TriggerClientEvent('QBCore:Notify', member.src, 'Your gang has captured the turf at ' .. turf.location.name .. '!', 'success', 10000)
        end
    }
    
    -- Notify clients that turf war ended
    for src, _ in pairs(turf.participants) do
        TriggerClientEvent('sv-gangs:client:TurfCaptureEnded', src, turfId, winningGang)
    end
    
    -- Mark as completed
    activeTurfs[turfId].status = 'completed'
    activeTurfs[turfId].winningGang = winningGang
    
    -- Cleanup turf after 60 seconds
    SetTimeout(60000, function()
        activeTurfs[turfId] = nil
        SyncActiveTurfs()
    end)
    
    -- Sync active turfs
    SyncActiveTurfs()
}

-- Sync active turfs to all clients
function SyncActiveTurfs()
    local turfsToSync = {}
    
    for id, turf in pairs(activeTurfs) do
        turfsToSync[id] = {
            id = turf.id,
            location = turf.location,
            startTime = turf.startTime,
            endTime = turf.endTime,
            status = turf.status,
            gangsInvolved = turf.gangsInvolved
        }
    end
    
    TriggerClientEvent('sv-gangs:client:SyncActiveTurfs', -1, turfsToSync)
end

-- Cleanup turfs when resource stops
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    -- End all active turf captures
    for id, _ in pairs(activeTurfs) do
        EndTurfCapture(id)
    end
end)
