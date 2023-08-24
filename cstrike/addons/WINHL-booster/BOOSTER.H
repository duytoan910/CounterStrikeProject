#ifndef BOOSTER_H
#define BOOSTER_H

#pragma warning(disable:4127)

#include <extdll.h>
#include <sdk_util.h>
#include <dllapi.h>
#include <meta_api.h>

#include <pdh.h>
#include <winsock.h>
#include <mmsystem.h>

#include "vers_plugin.h"


#define TIMERMAX 10


typedef struct timecaps_s {
	unsigned long min;
	unsigned long max;
} timecaps_t;

typedef struct tagPDHPROFSTRUCT {
    HQUERY hQuery;
    HCOUNTER hCounter;
    DWORD dwValue;
} PDHPROFSTRUCT, *PPDHPROFSTRUCT;

extern cvar_t *         cvar_sys_ticrate;
extern cvar_t *         booster_autofps;
extern cvar_t *         booster_cpu_enabled;
extern cvar_t *         booster_cpu_spikemax;
extern cvar_t *         booster_cpu_spikelevel;
extern cvar_t *         booster_cpu_mminc;
extern cvar_t *         booster_force_systicrate;
extern cvar_t *         booster_minsleepms;
extern cvar_t *         booster_show_connmsg;
extern cvar_t *         booster_version;
extern cvar_t *         server_fps;

extern timecaps_t       timecaps;
extern PDHPROFSTRUCT    pdhStruct;   // performance data

extern unsigned long    connected_players[33];

extern long             sys_ticrate;
extern unsigned long    current_fps;
extern float            next_time;
extern unsigned long    frame_num;
extern unsigned long    cpu_spike_count;


extern BOOL __fastcall CreatePDHItem(LPTSTR lpszCounterName, PPDHPROFSTRUCT pStruct);
extern BOOL __fastcall ClosePDHItem(PPDHPROFSTRUCT pStruct);
extern BOOL __fastcall PDHUpdate(PPDHPROFSTRUCT pStruct);
extern bool InitializePerfmon(void);

extern long GetPlayerCount(void);
extern void ForceTimerAccurency(void);
extern void BoosterCPU(void);
extern void ForceServerInfoVersion(void);
extern void DoAutoFPS(void);
extern void UpdateServerFPS(void);

extern void plugin_init(void);

extern int Get_Entity_API2(DLL_FUNCTIONS *pFunctionTable, int *interfaceVersion);


inline void CVAR_DIRSET_STRING(const cvar_t *cvar, const char *str) 
{
	g_engfuncs.pfnCvar_DirectSet((cvar_t*)cvar,(char*)str);
}


#endif // BOOSTER_H
