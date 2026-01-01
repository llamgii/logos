fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Codex'
description 'Kidnapping helper for QB-Core vans'

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
