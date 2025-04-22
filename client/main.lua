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

-- Commands and key bindings are now managed in commands.lua

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
