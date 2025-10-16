fx_version "adamant"
game "gta5" 

author '´PINGUIN DEV'
version '2.0.0'
description 'BusWork - Sistema de Emprego de Motorista de Ônibus com UI Moderna'

-- UI Files
ui_page 'ui/index.html'

files {
   'ui/index.html',
   'ui/style.css',
   'ui/script.js'
}

-- Server Scripts
server_scripts {
   "@vrp/lib/utils.lua",
   "Config.lua",
   "src/Server-Side.lua"
}

-- Client Scripts
client_scripts {
   "@vrp/lib/utils.lua",
   "Config.lua",
   "src/Client-Side-New.lua"
}

