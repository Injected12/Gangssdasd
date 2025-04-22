-- SouthVale RP - QBCore Gang System
-- Client NUI Handling

local QBCore = exports['qb-core']:GetCoreObject()

-- NUI Callbacks
RegisterNUICallback('closePanel', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Gang Admin Callbacks
RegisterNUICallback('createGang', function(data, cb)
    TriggerServerEvent('sv-gangs:server:CreateGang', data)
    cb('ok')
end)

RegisterNUICallback('deleteGang', function(data, cb)
    TriggerServerEvent('sv-gangs:server:DeleteGang', data.name)
    cb('ok')
end)

RegisterNUICallback('updateGang', function(data, cb)
    TriggerServerEvent('sv-gangs:server:UpdateGang', data)
    cb('ok')
end)

RegisterNUICallback('addMemberToGang', function(data, cb)
    TriggerServerEvent('sv-gangs:server:AddMemberToGang', data.gangName, data.citizenid, data.rankLevel)
    cb('ok')
end)

RegisterNUICallback('removeMemberFromGang', function(data, cb)
    TriggerServerEvent('sv-gangs:server:RemoveMemberFromGang', data.gangName, data.citizenid)
    cb('ok')
end)

RegisterNUICallback('updateGangRanks', function(data, cb)
    TriggerServerEvent('sv-gangs:server:UpdateGangRanks', data.gangName, data.ranks)
    cb('ok')
end)

RegisterNUICallback('getPlayerByCitizenId', function(data, cb)
    QBCore.Functions.TriggerCallback('sv-gangs:server:GetPlayerByCitizenId', function(player)
        cb(player)
    end, data.citizenid)
end)

RegisterNUICallback('searchPlayers', function(data, cb)
    QBCore.Functions.TriggerCallback('sv-gangs:server:SearchPlayers', function(players)
        cb(players)
    end, data.query)
end)

-- Gang Panel Callbacks
RegisterNUICallback('inviteToGang', function(data, cb)
    TriggerServerEvent('sv-gangs:server:InviteToGang', data.playerId)
    cb('ok')
end)

RegisterNUICallback('kickFromGang', function(data, cb)
    TriggerServerEvent('sv-gangs:server:KickFromGang', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('promoteGangMember', function(data, cb)
    TriggerServerEvent('sv-gangs:server:PromoteGangMember', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('demoteGangMember', function(data, cb)
    TriggerServerEvent('sv-gangs:server:DemoteGangMember', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('setGangMemberRank', function(data, cb)
    TriggerServerEvent('sv-gangs:server:SetGangMemberRank', data.citizenid, data.rankLevel)
    cb('ok')
end)

RegisterNUICallback('updateGangInfo', function(data, cb)
    TriggerServerEvent('sv-gangs:server:UpdateGangInfo', data)
    cb('ok')
end)

RegisterNUICallback('refreshGangData', function(_, cb)
    QBCore.Functions.TriggerCallback('sv-gangs:server:GetGangData', function(gangData)
        cb(gangData)
    end)
end)

RegisterNUICallback('getOnlinePlayers', function(_, cb)
    QBCore.Functions.TriggerCallback('sv-gangs:server:GetOnlinePlayers', function(players)
        cb(players)
    end)
end)

RegisterNUICallback('getGangMembers', function(_, cb)
    QBCore.Functions.TriggerCallback('sv-gangs:server:GetGangMembers', function(members)
        cb(members)
    end)
end)

-- Leaderboard Callbacks
RegisterNUICallback('refreshLeaderboard', function(_, cb)
    QBCore.Functions.TriggerCallback('sv-gangs:server:GetGangLeaderboard', function(leaderboard)
        cb(leaderboard)
    end)
end)

-- Events from server
RegisterNetEvent('sv-gangs:client:GangInvite', function(gangName, inviterName)
    SendNUIMessage({
        action = 'gangInvite',
        gangName = gangName,
        inviterName = inviterName
    })
    
    -- Also show notification
    QBCore.Functions.Notify('You have been invited to join ' .. gangName .. ' by ' .. inviterName, 'primary', 10000)
end)

-- Callback for accepting/declining gang invite
RegisterNUICallback('respondToGangInvite', function(data, cb)
    TriggerServerEvent('sv-gangs:server:RespondToGangInvite', data.accept)
    cb('ok')
end)

-- Send UI configuration
RegisterNetEvent('sv-gangs:client:SendUIConfig', function()
    SendNUIMessage({
        action = 'setConfig',
        config = {
            serverName = Config.ServerName,
            logo = Config.Logo,
            themeColor = Config.UIThemeColor,
            backgroundOpacity = Config.UIBackgroundOpacity
        }
    })
end)
