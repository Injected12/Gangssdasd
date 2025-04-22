fx_version 'cerulean'
game 'gta5'

description 'SouthVale RP - QBCore Gang System'
version '1.0.0'
author 'SouthVale RP'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/nui.lua',
    'client/turf.lua',
    'client/turf_system.lua',
    'client/gang_hud.lua',
    'client/commands.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/database.lua',
    'server/gangs.lua',
    'server/turfs.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/gangadmin.html',
    'html/gangadmin.css',
    'html/gangadmin.js',
    'html/gangpanel.html',
    'html/gangpanel.css',
    'html/gangpanel.js',
    'html/leaderboard.html',
    'html/leaderboard.css',
    'html/leaderboard.js'
}

lua54 'yes'
