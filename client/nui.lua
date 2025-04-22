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

-- Opens NUI panel with data
function OpenGangAdminPanel()
    SendNUIMessage({
        action = 'openPanel',
        panel = 'gangadmin'
    })
    SetNuiFocus(true, true)
    
    -- Load gangs data for admin panel
    QBCore.Functions.TriggerCallback('sv-gangs:server:GetAllGangs', function(gangsData)
        SendNUIMessage({
            action = 'setGangsData',
            gangs = gangsData
        })
    end)
end

function OpenGangPanel()
    SendNUIMessage({
        action = 'openPanel',
        panel = 'gangpanel'
    })
    SetNuiFocus(true, true)
    
    -- Load gang data for gang panel
    QBCore.Functions.TriggerCallback('sv-gangs:server:GetPlayerGangData', function(gangData)
        SendNUIMessage({
            action = 'setGangPanelData',
            gangData = gangData
        })
    end)
    
    -- Load gang turfs
    QBCore.Functions.TriggerCallback('sv-gangs:server:GetGangTurfs', function(turfsData)
        SendNUIMessage({
            action = 'setGangTurfs',
            turfs = turfsData
        })
    end)
end

function OpenLeaderboardPanel()
    SendNUIMessage({
        action = 'openPanel',
        panel = 'leaderboard'
    })
    SetNuiFocus(true, true)
    
    -- Load leaderboard data
    QBCore.Functions.TriggerCallback('sv-gangs:server:GetLeaderboard', function(leaderboardData)
        SendNUIMessage({
            action = 'setLeaderboardData',
            leaderboard = leaderboardData
        })
    end)
end

-- Register command to open admin panel
RegisterCommand(Config.Commands.Admin, function()
    QBCore.Functions.TriggerCallback('sv-gangs:server:IsPlayerAdmin', function(isAdmin)
        if isAdmin then
            OpenGangAdminPanel()
        else
            QBCore.Functions.Notify('You do not have permission to use this command', 'error')
        end
    end)
end, false)

-- Register command to open gang panel
RegisterCommand(Config.Commands.Panel, function()
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

-- Register command to open leaderboard
RegisterCommand(Config.Commands.Leaderboard, function()
    OpenLeaderboardPanel()
end, false)

-- Command suggestions
TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.Admin, 'Open the gang admin panel', {})
TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.Panel, 'Open your gang management panel', {})
TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.Leaderboard, 'View the gang leaderboard', {})