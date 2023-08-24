#include "booster.h"


static cvar_t booster_cvars[] = {
	{"server_fps",              "100", 		FCVAR_EXTDLL | FCVAR_SERVER | FCVAR_UNLOGGED , 100, NULL},
	{"booster_autofps",         "100",		FCVAR_EXTDLL , 100, NULL},
	{"booster_minsleepms",      "3",		FCVAR_EXTDLL , 3, NULL},
	
	{"booster_show_connmsg",    "1",		FCVAR_EXTDLL , 1, NULL},
	{"booster_force_systicrate","10000",	FCVAR_EXTDLL , 10000, NULL},
	
	{"booster_cpu_enabled",     "0",		FCVAR_EXTDLL , 0, NULL},
	{"booster_cpu_spikemax",    "3",		FCVAR_EXTDLL , 3, NULL},
	{"booster_cpu_spikelevel",  "75",		FCVAR_EXTDLL , 75, NULL},
	{"booster_cpu_mminc",       "2",		FCVAR_EXTDLL , 2, NULL},
	
	{"booster_version",         VVERSION,	FCVAR_EXTDLL | FCVAR_SERVER , 0, NULL},
	
	{NULL,NULL,0,0,NULL},
};


// Plugin startup.  Register commands and cvars.
void plugin_init(void) 
{
	LOG_MESSAGE(PLID, REALNAME ", " VDATE);		// "Booster vX.XX, X.XX.XXXX (dd.mm.yy)
	LOG_MESSAGE(PLID, "by "VAUTHOR);		// "by Jussi Kivilinna <me@email.to.me>
	LOG_MESSAGE(PLID, "   "VURL);			// "   http://home.page.dot/
	LOG_MESSAGE(PLID, "compiled: " __DATE__ ", " __TIME__ " EET");
	
	
	for(int i = 0; booster_cvars[i].name; i++) CVAR_REGISTER( &booster_cvars[i] );
	
	
	server_fps              = CVAR_GET_POINTER( "server_fps" );
	booster_autofps         = CVAR_GET_POINTER( "booster_autofps" );
	booster_minsleepms      = CVAR_GET_POINTER( "booster_minsleepms" );
	booster_show_connmsg    = CVAR_GET_POINTER( "booster_show_connmsg" );
	booster_force_systicrate= CVAR_GET_POINTER( "booster_force_systicrate" );
	booster_version         = CVAR_GET_POINTER( "booster_version" );
	cvar_sys_ticrate        = CVAR_GET_POINTER( "sys_ticrate" );

	booster_cpu_enabled     = CVAR_GET_POINTER( "booster_cpu_enabled" );
	booster_cpu_spikemax    = CVAR_GET_POINTER( "booster_cpu_spikemax" );
	booster_cpu_spikelevel  = CVAR_GET_POINTER( "booster_cpu_spikelevel" );
	booster_cpu_mminc       = CVAR_GET_POINTER( "booster_cpu_mminc" );	

	SERVER_PRINT("=============-----------------------------\n");
	SERVER_PRINT(" " REALNAME " " VBY "\n");
	SERVER_PRINT("=============-----------------------------\n");
	
	
	//We dont want to fill logs
	cvar_sys_ticrate->flags |= FCVAR_UNLOGGED | FCVAR_SERVER ;
	
	//We set this 10000 .. 
	CVAR_DIRSET_STRING(cvar_sys_ticrate, "10000.0");
	
	sys_ticrate = 10000;
	
	//
	memset(connected_players, 0, sizeof(connected_players));
}



