fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Codex'
description 'QB-Core torture interaction system powered by ox_lib and ox_target.'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'qb-core',
    'ox_lib',
    'ox_target'
}
