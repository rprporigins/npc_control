fx_version 'cerulean'
games {'gta5'}

author 'PixelForge <brunovds.cs@gmail.com>'
description 'RPRP Ribeirinhos - Store System'
version '1.0.0'

lua54 'yes'

ui_page 'web/build/index.html'

client_scripts {
    'client/**/*'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/**/*',
}

shared_scripts {
    '@ox_lib/init.lua',
}

files {
    'web/build/index.html',
    'web/build/**/*'
}

dependencies {
    'oxmysql',
    'ox_lib'
}