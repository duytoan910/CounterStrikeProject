#include "booster.h"


/*
 *	ClientConnect .. Show booster message.
 */
static BOOL ClientConnect(edict_t *pEntity, const char *pszName, const char * pszAddress, char szRejectReason[128])
{
	if (!gpGlobals->deathmatch)
	{
		SET_META_RESULT(MRES_IGNORED);
		return(TRUE);
	}
	
	static char OutPut[512];
	int conn = (int)booster_show_connmsg->value;
	
	if (conn<=0)
	{
		SET_META_RESULT(MRES_IGNORED);
		return(TRUE);
	}
	
	if (conn>1)
	{
		long count = GetPlayerCount();

		snprintf(OutPut,512,
		
			"============---------------------\n"
			"  Server is currently running at %lu fps with %li clients present.\n"
			"  Current map: %s\n"
			"============---------------------\n"
		
			,current_fps
			,count
			,STRING(gpGlobals->mapname) );
	}
	else if(conn>0)
	{
		snprintf(OutPut,512,"===-- Server is running at %lu fps with " SHORTNAME ".\n",current_fps);
	}
	
	CLIENT_PRINTF(pEntity,print_console,OutPut);

	SET_META_RESULT(MRES_HANDLED);
	return(TRUE);
}


static void StartFrame(void)
{	
	if (!gpGlobals->deathmatch) 
	{
		SET_META_RESULT(MRES_IGNORED);
		return;
	}

	/*
	 *	Updates server_fps cvar
	 *	and tweaks sys_ticrate
	 */	
	if (next_time <= gpGlobals->time)
	{
		UpdateServerFPS();
		
		float force = booster_force_systicrate->value;
		if (force > (50.0f - 0.01f))
		{
			char tmp[64];

			//Force systicrate
			sys_ticrate = (long)force;
			snprintf(tmp, 64, "%li", sys_ticrate);
			
			CVAR_DIRSET_STRING(cvar_sys_ticrate, tmp);
		}
		else
		{
			DoAutoFPS();
		}
		
		BoosterCPU();
			
		ForceTimerAccurency();
		
		ForceServerInfoVersion();

		next_time = gpGlobals->time + 4.0f;
	}
	else
	{
		//Add frame
		frame_num++;
	}

	SET_META_RESULT(MRES_IGNORED);
}


static void PlayerPreThink( edict_t *pEdict )
{
	//Only connected players think!
	connected_players[ENTINDEX(pEdict)] = 1;
	
	SET_META_RESULT(MRES_IGNORED);
}


static void ClientPutInServer( edict_t *pEdict )
{
	//Set connected
	connected_players[ENTINDEX(pEdict)] = 1;
	
	SET_META_RESULT(MRES_IGNORED);
}


static void ClientDisconnect( edict_t *pEdict )
{
	//Set disconnected
	connected_players[ENTINDEX(pEdict)] = 0;
	
	SET_META_RESULT(MRES_IGNORED);
}


static void ServerActivate( edict_t *pEdictList, int edictCount, int clientMax )
{
	frame_num = 0;
	CVAR_DIRSET_STRING( server_fps , "1.0" );
	
	next_time = gpGlobals->time + 4.0f;

	if (!CreatePDHItem("\\Processor(_Total)\\% Processor Time", &pdhStruct))
		LOG_MESSAGE(PLID, "ERROR - unable to create performance monitor");

	cpu_spike_count = 0;

	memset(connected_players, 0, sizeof(connected_players));

	SET_META_RESULT(MRES_IGNORED);
}

static void ServerDeactivate( void ) 
{
	if (!ClosePDHItem(&pdhStruct))
		LOG_MESSAGE(PLID, "ERROR - unable to close performance monitor");

	SET_META_RESULT(MRES_IGNORED);
}


int Get_Entity_API2( DLL_FUNCTIONS *pFunctionTable, int *interfaceVersion )
{
	if( !pFunctionTable )
	{
		return( FALSE );
	}
	else if( *interfaceVersion != INTERFACE_VERSION )
	{
		*interfaceVersion = INTERFACE_VERSION;
		return( FALSE );
	}
	
	memset(pFunctionTable,0,sizeof(DLL_FUNCTIONS));
	
	pFunctionTable->pfnStartFrame		= StartFrame;
	pFunctionTable->pfnPlayerPreThink	= PlayerPreThink;
	pFunctionTable->pfnServerActivate	= ServerActivate;
	pFunctionTable->pfnServerDeactivate	= ServerDeactivate;
	pFunctionTable->pfnClientPutInServer= ClientPutInServer;
	pFunctionTable->pfnClientDisconnect	= ClientDisconnect;
	pFunctionTable->pfnClientConnect	= ClientConnect;
	
	return( TRUE );
}











