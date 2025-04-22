Config = {}

-- General settings
Config.Debug = false -- Set to true to enable debug messages
Config.ServerName = "SouthVale RP" -- Your server name
Config.Logo = "https://yourserver.com/logo.png" -- URL to your server logo

-- Permissions
Config.AdminGroups = {'admin', 'god'} -- Groups that can access gang admin panel
Config.AdminPermission = "admin.gangadmin" -- Permission to access gang admin panel

-- Gang settings
Config.DefaultGangColor = "#3498db" -- Default color for new gangs
Config.MaxGangMembers = 20 -- Maximum number of members per gang
Config.MaxGangRanks = 10 -- Maximum number of ranks per gang
Config.DefaultGangRanks = { -- Default ranks for new gangs
    { name = "Boss", level = 100 },
    { name = "Underboss", level = 90 },
    { name = "Capo", level = 80 },
    { name = "Lieutenant", level = 70 },
    { name = "Soldier", level = 50 },
    { name = "Associate", level = 10 },
    { name = "Recruit", level = 0 }
}

-- Gang-specific colors (will override default color for these gangs)
Config.GangColors = {
    ["ballas"] = "#9b59b6", -- Purple for Ballas
    ["vagos"] = "#f1c40f",  -- Yellow for Vagos
    ["families"] = "#2ecc71", -- Green for Families
    ["triads"] = "#e74c3c"  -- Red for Triads
}

-- UI settings
Config.UIThemeColor = "#3498db" -- Primary theme color
Config.UIBackgroundOpacity = 0.85 -- Background opacity for UI (0.0 - 1.0)

-- HUD settings
Config.EnableGangHUD = true -- Enable or disable the gang HUD
Config.HUDPosition = "top-right" -- Position of the gang HUD (top-left, top-right, bottom-left, bottom-right)
Config.HUDOffsetX = -10 -- X offset for the gang HUD
Config.HUDOffsetY = 10 -- Y offset for the gang HUD

-- Keybind settings
Config.EnableKeybinds = true -- Enable or disable keybinds
Config.Keybinds = {
    GangPanel = "F6", -- Keybind to open gang panel (only for members with appropriate rank)
    Leaderboard = "F7", -- Keybind to open gang leaderboard (available to everyone)
    ToggleHUD = "F9" -- Keybind to toggle the gang HUD
}

-- Turf settings
Config.TurfCaptureDuration = 200 -- Duration of turf capture in seconds
Config.TurfCaptureRadius = 50.0 -- Radius of the turf capture area
Config.TurfCooldown = 120 -- Cooldown between turf captures in seconds
Config.TurfRewardPoints = 10 -- Points rewarded for capturing a turf
Config.EnableTurfNotifications = true -- Enable or disable turf notifications
Config.TurfMarkerColor = {r = 0, g = 0, b = 0, a = 128} -- Color of the turf marker (RGBA)

-- Turf locations (x, y, z, heading)
Config.TurfLocations = {
    {x = 91.4858, y = -809.1631, z = 31.4138, h = 221.5335, name = "Downtown Vinewood"},
    {x = 298.8464, y = -584.5562, z = 43.2840, h = 78.5644, name = "Pillbox Hospital"},
    {x = -1037.9630, y = -2741.7646, z = 13.9592, h = 329.2644, name = "Airport"},
    {x = -209.2212, y = -1321.9865, z = 30.8904, h = 90.1141, name = "South Los Santos"},
    {x = 1322.9636, y = -1652.3450, z = 52.2750, h = 12.5508, name = "Mirror Park"}
}

-- Commands
Config.Commands = {
    Admin = "gangadmin", -- Command to open the gang admin panel
    Panel = "gangpanel", -- Command to open the gang panel
    Leaderboard = "gangleaderboard" -- Command to open the gang leaderboard
}
