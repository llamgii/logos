fx_version 'cerulean'
game 'gta5'

name 'qbx_ped_interact'
author 'OpenAI'
description 'QBox ped interaction using ox_lib, ox_target, and ox_inventory'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependency 'ox_lib'
dependency 'ox_target'
dependency 'ox_inventory'
