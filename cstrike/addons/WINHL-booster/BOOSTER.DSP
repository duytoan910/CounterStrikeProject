# Microsoft Developer Studio Project File - Name="booster" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Dynamic-Link Library" 0x0102

CFG=booster - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "booster.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "booster.mak" CFG="booster - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "booster - Win32 Release" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE "booster - Win32 Debug" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "booster - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MT /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "BOOSTER_EXPORTS" /YX /FD /c
# ADD CPP /nologo /G6 /MT /W4 /GX /O2 /I "common" /I "dlls" /I "engine" /I "metamod" /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "BOOSTER_EXPORTS" /FD /c
# SUBTRACT CPP /YX
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x40b /d "NDEBUG"
# ADD RSC /l 0x40b /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /dll /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib winmm.lib wsock32.lib pdh.lib /nologo /dll /machine:I386 /out:"booster_mm.dll"

!ELSEIF  "$(CFG)" == "booster - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MTd /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "BOOSTER_EXPORTS" /YX /FD /GZ /c
# ADD CPP /nologo /G6 /MDd /W3 /Gm /GX /ZI /Od /I "common" /I "dlls" /I "engine" /I "metamod" /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "BOOSTER_EXPORTS" /YX /FD /GZ /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x40b /d "_DEBUG"
# ADD RSC /l 0x40b /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /dll /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib winmm.lib wsock32.lib pdh.lib /nologo /dll /debug /machine:I386 /out:"booster_mm.dll" /pdbtype:sept
# Begin Special Build Tool
SOURCE="$(InputPath)"
PostBuild_Cmds=copy booster_mm.dll d:\pelit\half-life\valve\dlls
# End Special Build Tool

!ENDIF 

# Begin Target

# Name "booster - Win32 Release"
# Name "booster - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\booster.cpp
# End Source File
# Begin Source File

SOURCE=.\booster_mm.def
# End Source File
# Begin Source File

SOURCE=.\dllapi.cpp
# End Source File
# Begin Source File

SOURCE=.\meta_api.cpp
# End Source File
# Begin Source File

SOURCE=.\perfmon.cpp
# End Source File
# Begin Source File

SOURCE=.\plugin.cpp
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Group "HLHeaders"

# PROP Default_Filter ""
# Begin Source File

SOURCE=.\dlls\activity.h
# End Source File
# Begin Source File

SOURCE=.\dlls\cdll_dll.h
# End Source File
# Begin Source File

SOURCE=.\common\const.h
# End Source File
# Begin Source File

SOURCE=.\common\crc.h
# End Source File
# Begin Source File

SOURCE=.\engine\custom.h
# End Source File
# Begin Source File

SOURCE=.\common\cvardef.h
# End Source File
# Begin Source File

SOURCE=.\metamod\dllapi.h
# End Source File
# Begin Source File

SOURCE=.\engine\edict.h
# End Source File
# Begin Source File

SOURCE=.\engine\eiface.h
# End Source File
# Begin Source File

SOURCE=.\metamod\engine_api.h
# End Source File
# Begin Source File

SOURCE=.\dlls\enginecallback.h
# End Source File
# Begin Source File

SOURCE=.\common\event_flags.h
# End Source File
# Begin Source File

SOURCE=.\dlls\extdll.h
# End Source File
# Begin Source File

SOURCE=.\common\in_buttons.h
# End Source File
# Begin Source File

SOURCE=.\metamod\meta_api.h
# End Source File
# Begin Source File

SOURCE=.\metamod\mutil.h
# End Source File
# Begin Source File

SOURCE=.\metamod\osdep.h
# End Source File
# Begin Source File

SOURCE=.\metamod\plinfo.h
# End Source File
# Begin Source File

SOURCE=.\engine\progdefs.h
# End Source File
# Begin Source File

SOURCE=.\metamod\sdk_util.h
# End Source File
# Begin Source File

SOURCE=.\metamod\support_meta.h
# End Source File
# Begin Source File

SOURCE=.\dlls\vector.h
# End Source File
# End Group
# Begin Source File

SOURCE=.\booster.h
# End Source File
# Begin Source File

SOURCE=.\vers_plugin.h
# End Source File
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# Begin Source File

SOURCE=.\version.rc
# End Source File
# End Group
# End Target
# End Project
