taskkill /F /IM hl.exe
taskkill /F /IM cstrike.exe
echo Wait!
start cstrike.exe -console -maxplayers 20 +map zm_toan -gl
del *.mdmp