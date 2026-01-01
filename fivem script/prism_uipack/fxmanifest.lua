fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
game 'gta5'
lua54 'yes'
author 'Prism Scripts - Zykem'
version '1.2.8'

dependency 'ox_lib'

file 'init.lua'
file 'config_init.lua'

client_scripts {
    'modules/*.lua',
    'main.lua'
}

ui_page 'web/build/index.html'
files {
    'web/build/**',
    'locales/*.lua'
}

escrow_ignore {
    'config_init.lua',
    'locales/*.lua'
}
dependency '/assetpacks'