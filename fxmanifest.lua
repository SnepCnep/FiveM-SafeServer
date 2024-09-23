fx_version 'cerulean'
game 'gta5'

author 'SnepCnep'
description 'safeServer Created By SnepCnep'
version '1.0.0'
lua54 'yes'

client_scripts {
    'src/client/main.lua',
}

server_scripts {
    'config.lua',
    'src/server/main.lua',
    'src/server/banhandler.lua',
}

files {
    'init.lua'
}