#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <zombieplague>

new const ZP_CSO_PLUGIN_NAME[] = "[ZP] CSO Countdown"
new const ZP_CSO_PLUGIN_VERSION[] = "5.0"
new const ZP_CSO_PLUGIN_AUTHOR[] = "jc980"

new zp_cso_round, zp_cso_sec, zp_center_textmsg
new zp_cso_humanswins, zp_cso_zombieswins,zp_cso_hud_sync3
new zp_cso_countchant[10][] = 
{ 
	"zombie_plague/1.wav",
	"zombie_plague/2.wav",
	"zombie_plague/3.wav",
	"zombie_plague/4.wav",
	"zombie_plague/5.wav",
	"zombie_plague/6.wav",
	"zombie_plague/7.wav",
	"zombie_plague/8.wav",
	"zombie_plague/9.wav",
	"zombie_plague/10.wav" 
}

public plugin_init() 
{
	register_plugin(ZP_CSO_PLUGIN_NAME, ZP_CSO_PLUGIN_VERSION, ZP_CSO_PLUGIN_AUTHOR)
	register_event("HLTV", "zp_cso_round_start", "a", "1=0", "2=0")
	register_logevent("Event_RoundStart", 2, "1=Round_Start")
	register_logevent("Event_RoundEnd", 2, "1=Round_End")
	zp_center_textmsg = get_user_msgid("TextMsg")
	zp_cso_hud_sync3 = CreateHudSyncObj()
}

public plugin_precache()
{	
	new i

	for(i = 0; i < sizeof zp_cso_countchant; i++) 
		engfunc(EngFunc_PrecacheSound, zp_cso_countchant[i])
	precache_sound("zombie_plague/zombi_ambience.mp3")
}
public client_putinserver(id) 
{
	//set_task(1.0,"zp_cso_hud_score", id, _, _, "b")
}
public zp_cso_round_start()
{
	zp_cso_sec = 11
	zp_cso_round += 1
	zp_cso_countdown()
}
public Event_RoundStart()
{
	StopSound(0)
	remove_task(0)
	set_task(23.0, "play_ambience_sound")
}
public play_ambience_sound()
{
	PlaySound(0, "zombie_plague/zombi_ambience.mp3")	
}
public Event_RoundEnd()
{
	remove_task(0)
	StopSound(0)
}
public zp_cso_countdown()
{   	
	new iText[64]
	
	format(iText, charsmax(iText), "Zombie Sẽ Xuất Hiện Trong %i Giây Nữa!", zp_cso_sec)
	zp_clientcenter_text(0, iText)
	
	zp_cso_sec -= 1
	
	if(zp_cso_sec < 10)
	{
		zp_cso_chantdown()
	}
	if(zp_cso_sec >= 1)
	{
		set_task(1.0, "zp_cso_countdown")
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

stock zp_clientcenter_text(id, zp_message[])
{
	new dest
	if (id) dest = MSG_ONE
	else dest = MSG_ALL
	
	message_begin(dest, zp_center_textmsg, {0,0,0}, id)
	write_byte(4)
	write_string(zp_message)
	message_end()
}
stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}
stock StopSound(id)
{
	if(!is_user_connected(id))
		return
		
	client_cmd(id, "mp3 stop; stopsound")
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
	format(iMsg, charsmax(iMsg), "[ Humans ] %02i [ Round %02i ] %02i [ Zombies ]^n [ %02i ] [ VS ] [ %02i ] ", zp_cso_humanswins, zp_roundnum, zp_cso_zombieswins, zp_hmnum, zp_zbnum)
	ShowSyncHudMsg(id, zp_cso_hud_sync3, iMsg)
	
	return PLUGIN_CONTINUE
}
