"GameMenu" { "1" { "label" "Start server" "command" "engine maxplayers 32;map zm_toan;bot_difficulty 3; bot_quota 15" } "2" { "label" "" "command" "" } "3" { "label" "#GameUI_GameMenu_ResumeGame" "command" "ResumeGame" "OnlyInGame" "1" } "4" { "label" "#GameUI_GameMenu_Disconnect" "command" "Disconnect" "OnlyInGame" "1" "notsingle" "1" } "5" { "label" "#GameUI_GameMenu_PlayerList" "command" "OpenPlayerListDialog" "OnlyInGame" "1" "notsingle" "1" } "9" { "label" "" "command" "" "OnlyInGame" "1" } "10" { "label" "#GameUI_GameMenu_NewGame" "command" "OpenCreateMultiplayerGameDialog" } "11" { "label" "#GameUI_GameMenu_FindServers" "command" "OpenServerBrowser" } "12" { "label" "#GameUI_GameMenu_Options" "command" "OpenOptionsDialog" } "13" { "label" "#GameUI_GameMenu_Quit" "command" "Quit" } }