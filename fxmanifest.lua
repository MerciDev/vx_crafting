fx_version 'cerulean'
game 'gta5'

author 'MiritoKaba (Vortex)'
description 'Immersive crafting and order system for QB-Core.'
version '1.0.0'

dependencies {
    'qb-core',
    'ox_lib',
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qb-core/shared/locale.lua',
    'config.lua',
}

client_scripts {
    'client/cl_crafting.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_crafting.lua',
}

ui_page 'craftingui/index.html'

files {
    'craftingui/index.html',
    'craftingui/style.css',
    'craftingui/script.js',
    'shared/crafting_recipes.json',
    'shared/imgs/*.png',
}

lua54 'yes'
