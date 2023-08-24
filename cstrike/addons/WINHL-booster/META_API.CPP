#include "booster.h"


// Description of plugin.
// (V* info from vers_plugin.h)
plugin_info_t Plugin_info = {
	META_INTERFACE_VERSION, // ifvers
	VNAME,			// name
	VVERSION,		// version
	VDATE,			// date
	VAUTHOR,		// author
	VURL,			// url
	VLOGTAG,		// logtag
	PT_CHANGELEVEL,		// loadable
	PT_ANYPAUSE,		// unloadable
};

// Global variables from metamod.  These variable names are referenced by
// various macros.
meta_globals_t *gpMetaGlobals;		// metamod globals
gamedll_funcs_t *gpGamedllFuncs;	// gameDLL function tables
mutil_funcs_t *gpMetaUtilFuncs;		// metamod utility functions


// Metamod requesting info about this plugin
C_DLLEXPORT int Meta_Query(char *ifvers, plugin_info_t **pPlugInfo, mutil_funcs_t *pMetaUtilFuncs) 
{
	// Check for valid pMetaUtilFuncs before we continue.
	if(!pMetaUtilFuncs) { return(FALSE); }
	
	gpMetaUtilFuncs=pMetaUtilFuncs;

	// Give metamod our plugin_info struct.
	*pPlugInfo=&Plugin_info;

	// Check for interface version compatibility.
	if(!FStrEq(ifvers, Plugin_info.ifvers)) 
	{
		//Lazy method
	 	Plugin_info.ifvers=strdup(ifvers);
	}
	
	return(TRUE);
}


// Metamod attaching plugin to the server.
C_DLLEXPORT int Meta_Attach(PLUG_LOADTIME now, META_FUNCTIONS *pFunctionTable, meta_globals_t *pMGlobals, gamedll_funcs_t *pGamedllFuncs)
{
	if(now > Plugin_info.loadable) 
	{
		return(FALSE);
	}
	
	if(!pMGlobals) 
	{
		return(FALSE);
	}
	
	gpMetaGlobals=pMGlobals;
	
	if(!pFunctionTable) 
	{
		return(FALSE);
	}
	
	
	memset(pFunctionTable,0,sizeof(META_FUNCTIONS));
	pFunctionTable->pfnGetEntityAPI2 = Get_Entity_API2;
	
	
	gpGamedllFuncs=pGamedllFuncs;

	
	//mm timer tweak 
	timeGetDevCaps((TIMECAPS*)&timecaps,sizeof(timecaps));
	
	unsigned long minimum_ms = 3;
			
	if( minimum_ms < timecaps.min )
	{
		//minimum_ms = timecaps.min;
	}
	else if ( minimum_ms > TIMERMAX )
	{
		timecaps.min = TIMERMAX;
	}
	else
	{
		timecaps.min = minimum_ms;
	}
			
	timeBeginPeriod(timecaps.min);


	// Let's go.	
	plugin_init();
	
	return(TRUE);
}


// Metamod detaching plugin from the server.
C_DLLEXPORT int Meta_Detach(PLUG_LOADTIME now, PL_UNLOAD_REASON reason) 
{
	if(now > Plugin_info.unloadable && reason != PNL_CMD_FORCED) 
	{
		return(FALSE);
	}


	//mm timer tweak off
	timeEndPeriod(timecaps.min);


	return(TRUE);
}


//! Holds engine functionality callbacks
enginefuncs_t g_engfuncs;
globalvars_t  *gpGlobals;


// Receive engine function table from engine.
C_DLLEXPORT void WINAPI GiveFnptrsToDll( enginefuncs_t* pengfuncsFromEngine, globalvars_t *pGlobals )
{
	memcpy(&g_engfuncs, pengfuncsFromEngine, sizeof(enginefuncs_t));
	gpGlobals = pGlobals;
}


BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) 
{
	return(TRUE);
}

