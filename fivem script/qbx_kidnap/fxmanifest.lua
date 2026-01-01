fx_version 'cerulean'
game 'gta5'

lua54 'yes'

description 'QB-Core kidnapping and interrogation mission'
author 'Codex'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/mission.lua',
    'client/interactions.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'qb-core',
    'ox_lib',
    'ox_target'
}
