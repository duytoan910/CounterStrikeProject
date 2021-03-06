#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <zombieplague>

new const ZP_CSO_PLUGIN_NAME[] = "[ZP] CSO Countdown"
new const ZP_CSO_PLUGIN_VERSION[] = "5.0"
new const ZP_CSO_PLUGIN_AUTHOR[] = "jc980"

new zp_cso_sec
new g_msgsync, g_roundstarted

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
	register_logevent("Event_RoundEnd", 2, "1=Round_End")
	g_msgsync = CreateHudSyncObj()
}

public plugin_precache()
{	
	new i

	for(i = 0; i < sizeof zp_cso_countchant; i++) 
		engfunc(EngFunc_PrecacheSound, zp_cso_countchant[i])
}
public zp_cso_round_start()
{
	zp_cso_sec = get_cvar_num("zp_delay") + 1 
	zp_cso_countdown()
}
public Event_RoundEnd()
{
	g_roundstarted = false
}
public zp_round_started()
{
	g_roundstarted = true
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
