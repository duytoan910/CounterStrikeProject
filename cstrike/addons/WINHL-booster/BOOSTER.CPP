#include "booster.h"

/******************************************************
*******************************************************
*
* Globals
*
*******************************************************
******************************************************/
cvar_t *         cvar_sys_ticrate;
cvar_t *         booster_autofps;
cvar_t *         booster_cpu_enabled;
cvar_t *         booster_cpu_spikemax;
cvar_t *         booster_cpu_spikelevel;
cvar_t *         booster_cpu_mminc;
cvar_t *         booster_force_systicrate;
cvar_t *         booster_minsleepms;
cvar_t *         booster_show_connmsg;
cvar_t *         booster_version;
cvar_t *         server_fps;

timecaps_t       timecaps;

PDHPROFSTRUCT    pdhStruct;   // performance data

unsigned long    connected_players[33];

long             sys_ticrate     = 500;
unsigned long    current_fps     = 0;
float            next_time       = 0.0f;
unsigned long    frame_num       = 0;
unsigned long    cpu_spike_count = 0;
unsigned long	 cpu_quiet_rounds = 0;


/******************************************************
*******************************************************
*
* Functions
*
*******************************************************
******************************************************/
long GetPlayerCount(void) 
{
	return(connected_players[29]+ connected_players[30]+ connected_players[31]+ connected_players[32]+
		   connected_players[1] + connected_players[2] + connected_players[3] + connected_players[4] +
	       connected_players[5] + connected_players[6] + connected_players[7] + connected_players[8] +
	       connected_players[9] + connected_players[10]+ connected_players[11]+ connected_players[12]+
	       connected_players[13]+ connected_players[14]+ connected_players[15]+ connected_players[16]+
	       connected_players[17]+ connected_players[18]+ connected_players[19]+ connected_players[20]+
	       connected_players[21]+ connected_players[22]+ connected_players[23]+ connected_players[24]+
	       connected_players[25]+ connected_players[26]+ connected_players[27]+ connected_players[28]);
}


void ForceTimerAccurency(void)
{
	//Force timers
	timeEndPeriod(timecaps.min);
	timeGetDevCaps((TIMECAPS*)&timecaps,sizeof(timecaps));
	
	unsigned long minimum_ms = (unsigned long)booster_minsleepms->value;
	
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
}


// begin cpu monitor... by Buzz_Kill <buzzkill@100acrebloodbath.com>
void BoosterCPU(void)
{
	char tmp[64];

	if (booster_cpu_enabled->value) {

		if (!PDHUpdate(&pdhStruct))
			LOG_MESSAGE(PLID, "ERROR - unable to query performance monitor");
		
		else {

			if (pdhStruct.dwValue > booster_cpu_spikelevel->value) {
				cpu_quiet_rounds = 0;

				if (++cpu_spike_count >= booster_cpu_spikemax->value) {

					if (booster_minsleepms->value < TIMERMAX) {
						snprintf(tmp,64,"%.1f",booster_minsleepms->value + booster_cpu_mminc->value  );
						CVAR_DIRSET_STRING( booster_minsleepms ,tmp );
						LOG_MESSAGE(PLID, "spike limit exceeded. cpu at %lu. increasing timer to %s", pdhStruct.dwValue, tmp);
						cpu_spike_count = 0;
					}
				}

			} else {
				// have we been quiet long enough to drop timer?
				cpu_quiet_rounds++;

				if (cpu_quiet_rounds > 75) { // 5 minutes of no spikes
					cpu_quiet_rounds = 0;

					if (booster_minsleepms->value > 3) {
						snprintf(tmp,64,"%.1f",--booster_minsleepms->value );
						CVAR_DIRSET_STRING( booster_minsleepms ,tmp );
						LOG_MESSAGE(PLID, "cpu usage has decreased. decreasing timer to %s", tmp);
					}
				}
			}
		}
	}
}








void ForceServerInfoVersion(void)
{
	// Small trick to block some ppl from changing version numbers 
	// (I want to see how many servers are running different versions:)
	char tempver[8];
	snprintf(tempver, 8, "%.2f", FVERSION);
	CVAR_DIRSET_STRING( booster_version, tempver );
}


void DoAutoFPS(void)
{
	//AUTO-FPS
	unsigned long targetfps = (unsigned long)booster_autofps->value;
	char tmp[64];
			
	if(targetfps>49)
	{
		bool too_small = (current_fps <= targetfps);
		unsigned long difference = abs(targetfps - current_fps);
		long change = 0;
			
		if(difference>100)
			change = 75;
		else if(difference>50)
			change = 38;
		else if(difference>20)
			change = 15;
		else if(difference>10)
			change = 8;
		else if(difference>5)
			change = 3;
		else if(difference>0)
			change = 1;
							
		change = too_small ? change : -change;
				
		sys_ticrate += change;
			
		if(sys_ticrate>1000) sys_ticrate = 1000;
		if(sys_ticrate<100) sys_ticrate = 100;
				
		snprintf(tmp, 64, "%li", sys_ticrate);
			
		CVAR_DIRSET_STRING(cvar_sys_ticrate, tmp);
	}
}


void UpdateServerFPS(void)
{
	char tmp[64];
		
	current_fps = (++frame_num) >> 2;

	snprintf(tmp, 64, "%lu", current_fps);
	CVAR_DIRSET_STRING(server_fps, tmp);

	frame_num = 0;
}
