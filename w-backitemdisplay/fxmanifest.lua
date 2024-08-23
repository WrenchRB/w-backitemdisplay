fx_version "cerulean"
game "gta5"
lua54 'yes'
name "w-backitemdisplay"
author "Wrench"
version "1.0.1"
description "w-backitemdisplay visually displays unequipped weapons and items on a player's back for a more immersive role-playing experience."

shared_scripts { 'editable.lua', 'config.lua' }
client_scripts { 'client.lua' }
server_scripts { 'server.lua' }

escrow_ignore { 'config.lua', 'editable.lua'}
dependency '/assetpacks' 