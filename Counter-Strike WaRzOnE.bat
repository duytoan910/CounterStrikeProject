taskkill /F /IM hl.exe
taskkill /F /IM cstrike.exe
echo Wait!
start cstrike.exe -gl -console -w 1024 -h 768 -windowed
del *.mdmp