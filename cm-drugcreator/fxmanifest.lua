fx_version 'cerulean'
lua54 'yes'
game 'gta5'

author 'camrxn'
description 'Complete ESX Drug Creator with Admin Menu, Harvest Zones, and Webhook support'
version '3.0.0'

shared_script '@es_extended/imports.lua'
shared_script '@ox_lib/init.lua'
shared_script 'config.lua'

client_scripts {
    'client.lua',
    'harvest.lua'
}

server_script 'server.lua'

dependencies {
    'es_extended',
    'ox_lib'
}
