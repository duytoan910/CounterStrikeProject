#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <zombieplague>

new const ZP_CSO_PLUGIN_NAME[] = "[ZP] CSO Countdown"
new const ZP_CSO_PLUGIN_VERSION[] = "5.0"
new const ZP_CSO_PLUGIN_AUTHOR[] = "jc980"

new zp_cso_sec, zp_cso_round, current_mode
new g_msgsync, g_roundstarted
new zp_cso_humanswins, zp_cso_zombieswins,zp_cso_hud_sync3

new GAMEMODE_NAME[][] = 
{
	"Zombie is coming!!",
	"Infection",
	"Nemesis",
	"Survivor",
	"Swarm",
	"Multi Infection",
	"Plague",
	"Boss"
}


new zp_cso_countchant[][] = 
{ 
	"fvox/one.wav", 
	"fvox/two.wav", 
	"fvox/three.wav", 
	"fvox/four.wav", 
	"fvox/five.wav", 
	"fvox/six.wav", 
	"fvox/seven.wav", 
	"fvox/eight.wav", 
	"fvox/nine.wav",
	"fvox/ten.wav",
	"fvox/biohazard_detected.wav"
}
public plugin_init() 
{
	register_plugin(ZP_CSO_PLUGIN_NAME, ZP_CSO_PLUGIN_VERSION, ZP_CSO_PLUGIN_AUTHOR)
	register_event("HLTV", "zp_cso_round_start", "a", "1=0", "2=0")
	register_logevent("Event_RoundStart", 2, "1=Round_Start")
	register_logevent("Event_RoundEnd", 2, "1=Round_End")
	g_msgsync = CreateHudSyncObj()
	zp_cso_hud_sync3 = CreateHudSyncObj()
}

public plugin_precache()
{	
	new i

	for(i = 0; i < sizeof zp_cso_countchant; i++) 
		engfunc(EngFunc_PrecacheSound, zp_cso_countchant[i])
}
public Event_RoundStart()
{
	current_mode = 0

}
public zp_cso_round_start()
{
	if(zp_cso_round>=15){
		server_cmd("map zm_toan")
		zp_cso_round = 0
		return;
	}
	zp_cso_sec = get_cvar_num("zp_gamemode_delay") + 1 
	zp_cso_round += 1
	zp_cso_countdown()
	return;
}
public client_putinserver(id){
	set_task(0.1,"zp_cso_hud_score", id, _, _, "b")
}
public Event_RoundEnd()
{
	g_roundstarted = false
}
public zp_round_started(gamemode)
{
	g_roundstarted = true
	current_mode = gamemode
}
public zp_cso_countdown()
{   	
	if(g_roundstarted)
	{
		client_cmd(0,"speak ^"%s^"", zp_cso_countchant[10])
		return;	
	}
	
	set_hudmessage(179, 0, 0, -1.0, 0.28, 2, 0.02, 1.0, 0.01, 0.1, 10);	
	ShowSyncHudMsg(0, g_msgsync, "Infection on %i", zp_cso_sec)
	zp_cso_sec -= 1
	
	if(zp_cso_sec < 10)
	{
		zp_cso_chantdown()
	}
	if(zp_cso_sec >= 1)
	{
		set_task(1.0, "zp_cso_countdown")
	}
	if(zp_cso_sec == 0)
	{
		client_cmd(0,"speak ^"%s^"", zp_cso_countchant[10])
	}
} 
public zp_cso_chantdown()
{
	new iChant[64], iSound
	
	iSound = zp_cso_sec
	
	if(iSound == -1)
		return PLUGIN_CONTINUE
		
	copy(iChant, charsmax(iChant), zp_cso_countchant[iSound])
	client_cmd(0,"speak ^"%s^"", iChant)
        return PLUGIN_CONTINUE
}
stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}

public zp_round_ended()
{
	if(zp_get_human_count() == 0)
	{
		zp_cso_zombieswins += 1
	}
	else
	{
		zp_cso_humanswins += 1
	}
}
public zp_cso_hud_score(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	
	new iMsg[600], zp_hmnum, zp_zbnum, zp_roundnum
	
	zp_hmnum = zp_get_human_count()
	zp_zbnum = zp_get_zombie_count()
	zp_roundnum = zp_cso_round
	
	set_hudmessage( 0, 250, 0, -1.0, 0.0, 0, 6.0, 1.1, 0.0, 0.0, -1)
	format(iMsg, charsmax(iMsg), "[ Humans ] %02i [ Round %02i ] %02i [ Zombies ]^n [ %02i ] [ VS ] [ %02i ]^n[ %s ]", zp_cso_humanswins, zp_roundnum, zp_cso_zombieswins, zp_hmnum, zp_zbnum, GAMEMODE_NAME[current_mode])
	ShowSyncHudMsg(id, zp_cso_hud_sync3, iMsg)
	
	return PLUGIN_CONTINUE
}
