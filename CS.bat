taskkill /F /IM hl.exe
taskkill /F /IM cstrike.exe
echo Wait!
start hl.exe -game cstrike -steam -d3d -console -maxplayers 20 +map zm_toan
del *.mdmp