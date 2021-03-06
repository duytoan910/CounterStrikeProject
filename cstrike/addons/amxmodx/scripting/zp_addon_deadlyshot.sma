#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <fakemeta_util>

#define TASK_REMOVE_DEADLYSHOT 839483
#define TASK_DEADLYSHOT_ICON 534534

#define DS_TIME 15.0
#define SOUND_SKILL_START "zombie_plague/speedup.wav"

new using_item[33]
new waiting[33]
new tasked[33]

new sync_hud1,g_iBarTime
new g_Ham_Bot

new g_deadlyshot_icon_id
new const g_deadlyshot_icon[] = "sprites/z4_skull.spr"

public plugin_init()
{
	register_plugin("[ZP] Extra Item: Deadly Shot (Human)", "1.0", "Dias")
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_traceattack")
	register_message(get_user_msgid("DeathMsg"), "Death")  

	sync_hud1 = CreateHudSyncObj(random_num(1, 10))
	g_iBarTime = get_user_msgid("BarTime") 
}
public plugin_precache()
{
	g_deadlyshot_icon_id = precache_model(g_deadlyshot_icon)
	precache_sound(SOUND_SKILL_START);
}
public plugin_natives()
{
	register_native("is_deadlyshot", "is_DL", 1)
}
public client_putinserver(id)
{
	if(!g_Ham_Bot && is_user_bot(id))
	{
		g_Ham_Bot = 1
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
}
public zp_round_started(id)
{
	enable_hs_mode(id)
}
public Do_RegisterHam_Bot(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_traceattack")
	RegisterHamFromEntity(Ham_Spawn, id, "fw_PlayerSpawn_Post")
}
public is_DL(id)
{
	return using_item[id]
}
public fw_PlayerSpawn_Post(id)
{
	using_item[id] = 0
	waiting[id] = 1
	remove_headshot_mode(id)
}
public zp_user_humanized_post(id)
{
	using_item[id] = 0
	waiting[id] = 0
}
public zp_user_infected_post(id)
{
	using_item[id] = 0
	waiting[id] = 0
	remove_headshot_mode(id)
	
	message_begin(MSG_ONE_UNRELIABLE, g_iBarTime, .player=id)
	write_short(0)
	message_end() 
}
public Death()
{
	new ikiller = read_data(1)
	new ivictim = read_data(2)
	
	if (!is_user_alive(ikiller))
		return
	if (ikiller == ivictim)
		return
	if (zp_get_user_zombie(ikiller))
		return	
	if(!using_item[ikiller])
		return
	set_msg_arg_int(3, ARG_BYTE, 1)
} 

public client_PostThink(id)
{
	if(zp_get_user_zombie(id))
		return
			
	static Button
	Button = get_user_button(id)
	
	if(Button & IN_USE)
	{
		if(!using_item[id] && !waiting[id])
		{				
			using_item[id] = 1
			set_task(DS_TIME, "remove_headshot_mode",id)
			set_hudmessage(0, 255, 0, -1.0, 0.3, 0, 15.0, 2.0)	
			ShowSyncHudMsg(id, sync_hud1, "Deadly Shot - Actived")
			emit_sound(id, CHAN_ITEM, SOUND_SKILL_START, 1.0, ATTN_NORM, 0, PITCH_NORM);

			message_begin(MSG_ONE_UNRELIABLE, g_iBarTime, .player=id)
			write_short(floatround(DS_TIME))
			message_end() 

			make_deadlyshoot_icon(id)
		}
	}
	if(!is_user_bot(id))
		return
		
	if(tasked[id]) return
	new enemy, body
	get_user_aiming(id, enemy, body)
	if ((1 <= enemy <= 32) && zp_get_user_zombie(enemy))
	{
		if(!using_item[id] && !waiting[id])
		{			
			tasked[id] = true	
			set_task(random_float(1.0,10.0), "DO_DS", id)
		}
	}
}
public DO_DS(id)
{
	if(!is_user_bot(id))
		return
		
	using_item[id] = 1
	set_task(DS_TIME, "remove_headshot_mode",id)
	set_hudmessage(0, 255, 0, -1.0, 0.3, 0, 15.0, 2.0)	
	ShowSyncHudMsg(id, sync_hud1, "Deadly Shot - Actived")

	message_begin(MSG_ONE_UNRELIABLE, g_iBarTime, .player=id)
	write_short(floatround(DS_TIME))
	message_end() 

	make_deadlyshoot_icon(id)		
}
public fw_traceattack(victim, attacker, Float:damage, direction[3], traceresult, dmgbits)
{
	if(using_item[attacker])
	{
		set_tr2(traceresult, TR_iHitgroup, HIT_HEAD)
	}
}
public remove_headshot_mode(id)
{
	if(zp_get_user_zombie(id))
		return
		
	using_item[id] = 0
	waiting[id] = 1
	
	set_hudmessage(0, 255, 0, -1.0, 0.3, 0, 15.0, 2.0)
	ShowSyncHudMsg(id, sync_hud1, "Deadly Shot - Disable")
	
	set_task(1.5*(is_user_bot(id)?DS_TIME + random(10):DS_TIME), "enable_hs_mode",id)	
	message_begin(MSG_ONE_UNRELIABLE, g_iBarTime, .player=id)
	write_short(0)
	message_end() 
}
public enable_hs_mode(id)
{
	if(zp_get_user_zombie(id))
		return
		
	waiting[id] = 0
	tasked[id] = false
	set_hudmessage(0, 255, 0, -1.0, 0.3, 0, 15.0, 2.0)	
	ShowSyncHudMsg(id, sync_hud1, "[E] -> Active Deadly Shot")
}
public make_deadlyshoot_icon(id)
{
	if(!is_user_connected(id))
		return
	if(zp_get_user_zombie(id))
		return
				
	remove_deadlyshot_icon(id)
	set_task(0.1, "make_ds_spr", id+TASK_DEADLYSHOT_ICON)
}

public make_ds_spr(id)
{
	id -= TASK_DEADLYSHOT_ICON
	
	if(!is_user_connected(id))
		return
	if(!is_user_alive(id))
		return
	if(zp_get_user_zombie(id))
		return
				
	if(!using_item[id])
		return
		
	static Float:Origin[3], Float:Add_Point
	pev(id, pev_origin, Origin)
	
	if(!(pev(id, pev_flags) & FL_DUCKING))
		Add_Point = 25.0
	else
		Add_Point = 17.0
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 20 + Add_Point)
	write_short(g_deadlyshot_icon_id)
	write_byte(1) 
	write_byte(255)
	message_end()
	
	md_zb_skill(id,2)
	
	set_task(0.1, "make_ds_spr", id+TASK_DEADLYSHOT_ICON)
}
public remove_deadlyshot_icon(id)
{
	if(!is_user_connected(id))
		return
		
	remove_task(id+TASK_DEADLYSHOT_ICON)
}
