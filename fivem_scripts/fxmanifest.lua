fx_version 'cerulean'
game 'gta5'

name 'gang_npc_manager'
description 'Sistema Avançado de Gerenciamento de NPCs para FiveM v2.0'
author 'Gang NPC Manager Team'
version '2.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/menu.lua',
    'client/npc_control.lua',
    'client/target.lua'
}

server_scripts {
    'server/main.lua',
    'server/commands.lua',
    'server/npc_handler.lua',
    'server/group_handler.lua'
}

dependencies {
    'ox_lib',
    'ox_target'
}

exports {
    'GetPlayerNPCs',
    'GetPlayerGroups',
    'SendNPCCommand',
    'GetNearbyNPCs'
}
