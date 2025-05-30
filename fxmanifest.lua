fx_version 'cerulean'
game 'gta5'

author 'Gang NPC Manager Team'
description 'Comprehensive NPC management system for gang operations'
version '2.0.0'

-- Dependencies
dependencies {
    'qb-core',
    'ox_lib'
}

-- Optional dependencies
optional_dependencies {
    'ox_target',
    'oxmysql'
}

-- Shared scripts
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua'
}

-- Server scripts
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/npc_manager.lua',
    'server/commands.lua',
    'server/admin_menu.lua'
}

-- Client scripts
client_scripts {
    'client/main.lua',
    'client/admin_menu.lua'
}

-- UI files (disabled - using ox_lib menus instead)
-- ui_page 'html/index.html'
-- files {
--     'html/index.html',
--     'html/style.css',
--     'html/script.js'
-- }

-- Exports
exports {
    'GetPlayerNPCs',
    'GetPlayerGroups',
    'SendNPCCommand'
}

lua54 'yes'
