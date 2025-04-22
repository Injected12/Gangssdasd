-- SouthVale RP - QBCore Gang System
-- Client Main File

local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local PlayerGang = {}
local isLoggedIn = false

-- Player load handling
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    PlayerGang = PlayerData.gang
    isLoggedIn = true
    TriggerServerEvent('sv-gangs:server:CheckPlayerGang')
    
    if Config.EnableGangHUD then
        UpdateGangHUD()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    PlayerGang = {}
    isLoggedIn = false
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    PlayerGang = gang
    if Config.EnableGangHUD then
        UpdateGangHUD()
    end
end)

-- Panel events
RegisterNetEvent('sv-gangs:client:OpenAdminPanel', function()
    OpenGangAdminPanel()
end)

RegisterNetEvent('sv-gangs:client:OpenGangPanel', function()
    OpenGangPanel()
end)

RegisterNetEvent('sv-gangs:client:OpenLeaderboard', function()
    OpenLeaderboardPanel()
end)

-- Gang commands
RegisterCommand(Config.Commands.Admin, function()
    if not isLoggedIn then return end
    
    QBCore.Functions.TriggerCallback('sv-gangs:server:CheckAdminPermission', function(hasPermission)
        if hasPermission then
            OpenGangAdminPanel()
        else
            QBCore.Functions.Notify('You do not have permission to use this command.', 'error')
        end
    end)
end)

RegisterCommand(Config.Commands.Panel, function()
    if not isLoggedIn then return end
    
    if PlayerGang.name ~= 'none' then
        QBCore.Functions.TriggerCallback('sv-gangs:server:GetGangRankLevel', function(rankLevel)
            if rankLevel >= 80 then -- Only high ranking members (Boss, Underboss, Capo)
                OpenGangPanel()
            else
                QBCore.Functions.Notify('Only high-ranking gang members can access the gang panel.', 'error')
            end
        end)
    else
        QBCore.Functions.Notify('You are not in a gang.', 'error')
    end
end)

RegisterCommand(Config.Commands.Leaderboard, function()
    if not isLoggedIn then return end
    OpenGangLeaderboard()
end)

-- Register key bindings if enabled
if Config.EnableKeybinds then
    if Config.Keybinds.GangPanel then
        RegisterKeyMapping(Config.Commands.Panel, 'Open Gang Panel', 'keyboard', Config.Keybinds.GangPanel)
    end
    
    if Config.Keybinds.Leaderboard then
        RegisterKeyMapping(Config.Commands.Leaderboard, 'Open Gang Leaderboard', 'keyboard', Config.Keybinds.Leaderboard)
    end
end

-- Event handlers
RegisterNetEvent('sv-gangs:client:UpdateGangInfo', function(gangData)
    PlayerGang = gangData
    if Config.EnableGangHUD then
        UpdateGangHUD()
    end
end)

RegisterNetEvent('sv-gangs:client:NotifyGangMembers', function(message)
    QBCore.Functions.Notify(message, 'primary', 10000)
end)

-- Functions
function OpenGangAdminPanel()
    SendNUIMessage({
        action = 'openGangAdmin'
    })
    SetNuiFocus(true, true)
    
    QBCore.Functions.TriggerCallback('sv-gangs:server:GetAllGangs', function(gangs)
        SendNUIMessage({
            action = 'setGangs',
            gangs = gangs
        })
    end)
end

function OpenGangPanel()
    SendNUIMessage({
        action = 'openGangPanel'
    })
    SetNuiFocus(true, true)
    
    QBCore.Functions.TriggerCallback('sv-gangs:server:GetGangData', function(gangData)
        SendNUIMessage({
            action = 'setGangData',
            gangData = gangData
        })
    end)
    
    QBCore.Functions.TriggerCallback('sv-gangs:server:GetGangTurfs', function(turfs)
        SendNUIMessage({
            action = 'setGangTurfs',
            turfs = turfs
        })
    end)
end

function OpenGangLeaderboard()
    SendNUIMessage({
        action = 'openLeaderboard'
    })
    SetNuiFocus(true, true)
    
    QBCore.Functions.TriggerCallback('sv-gangs:server:GetGangLeaderboard', function(leaderboard)
        SendNUIMessage({
            action = 'setLeaderboardData',
            leaderboard = leaderboard
        })
    end)
end

-- Debug function
function Debug(msg)
    if Config.Debug then
        print("[SV-GANGS] " .. msg)
    end
end

-- Export functions for other resources
exports('GetPlayerGang', function()
    return PlayerGang
end)

exports('IsPlayerInGang', function(gangName)
    if not gangName then
        return PlayerGang.name ~= 'none'
    end
    return PlayerGang.name == gangName
end)

exports('GetPlayerGangRank', function()
    return PlayerGang.grade and PlayerGang.grade.level or 0
end)
