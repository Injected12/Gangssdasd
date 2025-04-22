-- SouthVale RP - QBCore Gang System
-- Client NUI Handling

local QBCore = exports['qb-core']:GetCoreObject()

-- NUI Callback events
RegisterNUICallback('closePanel', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('createGang', function(data, cb)
    TriggerServerEvent('sv-gangs:server:CreateGang', data)
    cb('ok')
end)

RegisterNUICallback('updateGang', function(data, cb)
    TriggerServerEvent('sv-gangs:server:UpdateGang', data)
    cb('ok')
end)

RegisterNUICallback('deleteGang', function(data, cb)
    TriggerServerEvent('sv-gangs:server:DeleteGang', data.gangName)
    cb('ok')
end)

RegisterNUICallback('addMember', function(data, cb)
    TriggerServerEvent('sv-gangs:server:AddGangMember', data.gangName, data.playerId, data.rankLevel)
    cb('ok')
end)

RegisterNUICallback('removeMember', function(data, cb)
    TriggerServerEvent('sv-gangs:server:RemoveGangMember', data.gangName, data.citizenid)
    cb('ok')
end)

RegisterNUICallback('promoteMember', function(data, cb)
    TriggerServerEvent('sv-gangs:server:PromoteGangMember', data.gangName, data.citizenid)
    cb('ok')
end)

RegisterNUICallback('demoteMember', function(data, cb)
    TriggerServerEvent('sv-gangs:server:DemoteGangMember', data.gangName, data.citizenid)
    cb('ok')
end)

RegisterNUICallback('invitePlayer', function(data, cb)
    TriggerServerEvent('sv-gangs:server:InviteToGang', data.playerId)
    cb('ok')
end)

RegisterNUICallback('leaveGang', function(data, cb)
    TriggerServerEvent('sv-gangs:server:LeaveGang')
    cb('ok')
end)

RegisterNUICallback('saveGangSettings', function(data, cb)
    TriggerServerEvent('sv-gangs:server:UpdateGangSettings', data)
    cb('ok')
end)

RegisterNUICallback('searchPlayers', function(data, cb)
    QBCore.Functions.TriggerCallback('sv-gangs:server:SearchPlayers', function(result)
        cb(result)
    end, data.query)
end)

-- Moving these function definitions to main.lua to avoid duplicates

-- Commands are now in client/commands.lua to avoid duplicates