fx_version 'cerulean'
game 'gta5'

name 'gang_npc_manager'
description 'Sistema Completo de Gerenciamento de NPCs para FiveM'
author 'Gang NPC Manager Team'
version '2.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'ox_lib',
    'ox_target',
    'oxmysql'
}

exports {
    'GetPlayerNPCs',
    'GetPlayerGroups',
    'SendNPCCommand',
    'GetNearbyNPCs',
    'CreateNPCGroup'
}
