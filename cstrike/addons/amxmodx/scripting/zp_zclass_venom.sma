#include <amxmodx> 
#include <amxmisc> 
#include <engine> 
#include <fakemeta> 
#include <fakemeta_util> 
#include <hamsandwich> 
#include <cstrike> 
#include <xs> 
#include <zombieplague> 

enum (+= 100)
{
TASK_WAIT = 2000,
TASK_ATTACK,
TASK_BOT_USE_SKILL,
TASK_USE_SKILL
}
// IDs inside tasksg
#define ID_WAIT (taskid - TASK_WAIT)
#define ID_ATTACK (taskid - TASK_ATTACK)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)
#define ID_USE_SKILL (taskid - TASK_USE_SKILL)


// Zombie Attributes 
new const zclass_name[] = "Venom Guard" // name 
new const zclass_info[] = " " // description 
new const zclass_model[] = "boomer_zombi_origin" // model 
new const zclass_clawmodel[] = "v_knife_boomer_zombi.mdl" // claw model 
const zclass_health = 3500 // health 
const zclass_speed = 280 // speed 
const Float:zclass_gravity = 0.8 // gravity 
const Float:zclass_knockback = 1.25 // knockback 

new idclass 

// ==== Heal 
new Float:heal_time_wait = 10.0, heal_amount = 2000 
new const heal_sprite[] = "sprites/zb_restore_health.spr" 
new heal_sprite_id 
new g_can_heal[33] 
new const zombie_sound_heal[] = "zombie_plague/zombi_heal.wav" 
#define TASK_WAIT_HEAL 53498 


// ==== Harden 
new Float:harden_time = 10.0 
new Float:harden_time_wait = 10.0 
new Float:harden_damage_def = 0.5,  
Float:harden_painshock_def = 0.5 
new const harden_sound[] = "zombie_plague/boomer_skill.wav" 
new g_can_harden[33], g_hardening[33] 

const m_flTimeWeaponIdle = 48 
const m_flNextAttack = 83 

#define TASK_H_TIME_REMOVE 8345843 
#define TASK_H_TIME_WAIT 53495734 

// ==== Dead Explode Effect 
new const death_exp_effect_model[] = "models/zombie_plague/ef_boomer.mdl" 
new const death_exp_effect_model2[] = "models/zombie_plague/ef_poison03.mdl" 
new const death_exp_effect_sprite[] = "sprites/ef_boomer_ex.spr" 
new const death_exp_effect_sprite2[] = "sprites/spr_boomer.spr" 
new const death_exp_effect_sound[] = "zombie_plague/boomer_death.wav" 
new Float:death_exp_radius = 200.0 
new Float:death_exp_knockspeed = 700.0 
new g_sound[][] = 
{
"zombie_plague/boomer_hurt1.wav" ,
"zombie_plague/boomer_hurt2.wav"
};

#define	m_iTeam			114
#define GIB_CLASSNAME "venomguard_gib" 
new g_hide_corpse[33] , cvar_debug
new g_register, g_explode_effect_idspr, g_explode_effect_idspr2

new g_current_time[33], g_hud_skill, g_hud_skill2, g_current_time2[33] 

public plugin_init() 
{ 
register_plugin("[Zombie: Z-VIRUS] Zombie Class: Venom Guard Zombie", "1.0", "Dias") 

register_message(get_user_msgid("ClCorpse"), "msg_clcorpse")      
register_think(GIB_CLASSNAME, "fw_Think_Gib")

RegisterHam(Ham_Killed, "player", "fw_Killed_Post", 1) 
RegisterHam(Ham_Spawn, "player", "fw_Spawn_Post", 1) 
RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage") 
register_event("DeathMsg", "Death", "a")
register_logevent("roundStart", 2, "1=Round_Start")
RegisterHam(Ham_Think, "info_target", "HamF_Think");
g_hud_skill = CreateHudSyncObj(11) 
g_hud_skill2 = CreateHudSyncObj(12) 
set_task(1.0, "change_time", _, _, _, "b") 

register_clcmd("drop", "cmd_drop") 
register_clcmd("lastinv", "cmd_lastinv") 

cvar_debug = register_cvar("zp_bot_skill_debug", "0")
} 

public plugin_precache() 
{ 
engfunc(EngFunc_PrecacheModel, death_exp_effect_model) 
engfunc(EngFunc_PrecacheModel, death_exp_effect_model2) 
engfunc(EngFunc_PrecacheSound, death_exp_effect_sound) 
g_explode_effect_idspr = engfunc(EngFunc_PrecacheModel, death_exp_effect_sprite) 
g_explode_effect_idspr2 = engfunc(EngFunc_PrecacheModel, death_exp_effect_sprite2)      
heal_sprite_id = engfunc(EngFunc_PrecacheModel, heal_sprite) 
engfunc(EngFunc_PrecacheSound, harden_sound) 
for(new i = 0; i < sizeof g_sound; i++)
precache_sound(g_sound[i]);

idclass = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)      
} 
public Death()
{
new victim = read_data(2) 
reset_value_player(victim)
}
public client_connect(id)
{
reset_value_player(id)
}
public client_disconnect(id)
{
reset_value_player(id)
}
reset_value_player(id)
{
if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
}
public roundStart(id)
{
for (new id=1; id<33; id++)
{
if (!is_user_connected(id)) continue;
if (is_user_bot(id))
{
	if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
	set_task(float(20), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}
}
}
public bot_use_skill(taskid)
{
new id = ID_BOT_USE_SKILL
if (!is_user_bot(id)) return;

cmd_lastinv(id) 
cmd_drop(id)
if (task_exists(taskid)) remove_task(taskid)
set_task(float(random_num(5,15)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}
public client_putinserver(id) 
{ 
	if(is_user_bot(id) && !g_register) 
	{ 
	g_register = 1 
	set_task(0.1, "do_register_ham_now", id) 
	} 
	
	//if(!is_user_bot(id)) 
	//set_task(1.0, "show_skill_hud", id, _, _, "b") 
} 

public show_skill_hud(id) 
{ 
if(is_user_alive(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == idclass) 
{ 
	show_hud_heal(id) 
	show_hud_harden(id) 
} 
} 

public show_hud_heal(id) 
{ 
static Float:percent, percent2 
static Float:time_remove 

time_remove = heal_time_wait 

percent = (float(g_current_time[id]) / time_remove) * 100.0 
percent2 = clamp(floatround(percent), 1, 100) 

if(percent2 > 0 && percent2 < 50) 
{ 
	set_hudmessage(255, 0, 0, -1.0, 0.10, 0, 1.5, 1.5) 
	ShowSyncHudMsg(id, g_hud_skill, "[G] - Heal (%i%%)", percent2) 
	} else if(percent2 >= 50 && percent < 100) { 
	set_hudmessage(255, 255, 0, -1.0, 0.10, 0, 1.5, 1.5) 
	ShowSyncHudMsg(id, g_hud_skill, "[G] - Heal (%i%%)", percent2) 
	} else if(percent2 >= 100) { 
	set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 1.5, 1.5) 
	ShowSyncHudMsg(id, g_hud_skill, "[G] - Heal (Ready)") 
} 
} 

public show_hud_harden(id) 
{ 
static Float:percent, percent2 
static Float:time_remove, Float:time_wait 

time_wait = harden_time 
time_remove = harden_time_wait 

percent = (float(g_current_time2[id]) / (time_remove + time_wait)) * 100.0 
percent2 = clamp(floatround(percent), 1, 100) 

if(percent2 > 0 && percent2 < 50) 
{ 
	set_hudmessage(255, 0, 0, -1.0, 0.125, 0, 1.5, 1.5) 
	ShowSyncHudMsg(id, g_hud_skill2, "[Q] - Hard Defense (%i%%)", percent2) 
	} else if(percent2 >= 50 && percent < 100) { 
	set_hudmessage(255, 255, 0, -1.0, 0.125, 0, 1.5, 1.5) 
	ShowSyncHudMsg(id, g_hud_skill2, "[Q] - Hard Defense (%i%%)", percent2) 
	} else if(percent2 >= 100) { 
	set_hudmessage(255, 255, 255, -1.0, 0.125, 0, 1.5, 1.5) 
	ShowSyncHudMsg(id, g_hud_skill2, "[Q] - Hard Defense (Ready)") 
}      
} 

public change_time() 
{ 
for(new i = 0; i < get_maxplayers(); i++) 
{ 
	g_current_time[i]++ 
	g_current_time2[i]++ 
} 
} 

public do_register_ham_now(id) 
{ 
RegisterHamFromEntity(Ham_Spawn, id, "fw_Spawn_Post", 1) 
RegisterHamFromEntity(Ham_Killed, id, "fw_Killed_Post", 1) 
RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage") 
} 

public zp_user_infected_post(id) 
{ 
if(zp_get_user_zombie_class(id) == idclass) 
{ 
	g_current_time[id] = 100 
	g_current_time2[id] = 100      
	
	g_can_heal[id] = 1 
	g_can_harden[id] = 1 
	g_hardening[id] = 0      
} 
} 

public zp_user_humanized_post(id) 
{ 
fw_Spawn_Post(id) 
} 
// ================================== Skill: Heal =================================== 
public cmd_drop(id) 
{ 
	if (is_user_bot(id)&&get_pcvar_num(cvar_debug))
		return
	if(is_user_alive(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == idclass) 
	{
		if (is_user_bot(id)&&get_pcvar_num(cvar_debug))
			return
		skill_heal_handle(id)
	} 
} 

public skill_heal_handle(id) 
{ 
	if(g_can_heal[id]) 
	{ 
		// set health 
		new health
		
		health = get_user_health(id)
		
		fm_set_user_health(id, health + heal_amount) 
		g_current_time[id] = 0 
		md_zb_skill(id, 1)		      
		
		// effect 
		PlaySound(id, zombie_sound_heal) 
		
		static Float:Origin[3] 
		pev(id, pev_origin, Origin) 
		
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);  
		write_byte(TE_EXPLOSION) 
		engfunc(EngFunc_WriteCoord, Origin[0]) 
		engfunc(EngFunc_WriteCoord, Origin[1]) 
		engfunc(EngFunc_WriteCoord, Origin[2]) 
		write_short(heal_sprite_id) 
		write_byte(15) 
		write_byte(12) 
		write_byte(14) 
		message_end() 
		
		// set time wait 
		g_can_heal[id] = 0 
		if (task_exists(id+TASK_WAIT_HEAL)) remove_task(id+TASK_WAIT_HEAL) 
		set_task(heal_time_wait, "reset_skill_heal", id+TASK_WAIT_HEAL) 
	}      
	
	return PLUGIN_HANDLED 
} 

public reset_skill_heal(id) 
{ 
	id -= TASK_WAIT_HEAL 
	
	if(is_user_alive(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == idclass) 
	{ 
		g_can_heal[id] = 1 
		g_current_time[id] = 100 
		client_print(id, print_center,"Heal cool down finish! [G]")
	} 
} 
// ================================== Skill: Harden ================================ 
public cmd_lastinv(id)
{ 
	if (is_user_bot(id)&&get_pcvar_num(cvar_debug))
		return
	if(is_user_alive(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == idclass) 
	{	
		skill_harden_handle(id) 
	}
} 

public skill_harden_handle(id) 
{ 
	if(g_can_harden[id] && !g_hardening[id]) 
	{ 
		play_weapon_anim(id, 2) 
		set_weapons_timeidle(id, 1.75) 
		set_player_nextattack(id, 1.75) 
		
		emit_sound(id, CHAN_ITEM, harden_sound, 1.0, ATTN_NORM, 0, PITCH_NORM) 
		//fm_set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 16) 
		
		md_zb_skill(id, 0)
		g_current_time2[id] = 0 
		
		set_task(harden_time, "stop_harden", id+TASK_H_TIME_REMOVE) 
	} 
} 

public stop_harden(id) 
{ 
	id -= TASK_H_TIME_REMOVE 
	
	if(is_user_alive(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == idclass) 
	{ 
		//fm_set_user_rendering(id) 
		
		g_can_harden[id] = 0 
		g_hardening[id] = 0 
		
		set_task(harden_time_wait, "reset_harden", id+TASK_H_TIME_WAIT) 
	} 
} 

public reset_harden(id) 
{ 
	id -= TASK_H_TIME_WAIT 
	
	if(is_user_alive(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == idclass) 
	{ 
		//fm_set_user_rendering(id) 
		
		g_can_harden[id] = 1 
		g_hardening[id] = 0 
		
		g_current_time2[id] = 100 
		client_print(id, print_center,"Harden cool down finish! [Q]")
	}      
} 

// ================================== MAIN MESSAGE ==================================== 
public msg_clcorpse() 
{ 
	static id 
	id = get_msg_arg_int(12) 
	
	if(!zp_get_user_zombie(id)) 
		return PLUGIN_CONTINUE 
	if(zp_get_user_zombie_class(id) != idclass) 
		return PLUGIN_CONTINUE 
	
	if(g_hide_corpse[id]) 
		return PLUGIN_HANDLED 
	
	return PLUGIN_CONTINUE 
}   

// ================================== FORWARD =============================== 
public fw_Spawn_Post(id) 
{ 
	if(!is_user_connected(id)) 
		return HAM_IGNORED 
	
	g_hide_corpse[id] = 0 
	//fm_set_user_rendering(id) 
	
	return HAM_HANDLED 
} 

public fw_Killed_Post(id) 
{ 
	if(!is_user_connected(id)) 
		return HAM_IGNORED 
	if(!zp_get_user_zombie(id)) 
		return HAM_IGNORED 
	if(zp_get_user_zombie_class(id) != idclass) 
		return HAM_IGNORED 
	
	g_hide_corpse[id] = 1 
	fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0) 
	death_effect(id) 
	
	return HAM_HANDLED 
} 
public fw_Think_Gib(ent) 
{ 
	if(!pev_valid(ent)) 
		return 
	
	engfunc(EngFunc_RemoveEntity, ent) 
} 

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits) 
{ 
	if(!is_user_connected(victim) || !is_user_connected(attacker)) 
		return HAM_IGNORED 
	if(!zp_get_user_zombie(victim) || zp_get_user_zombie(attacker)) 
		return HAM_IGNORED 
	if(zp_get_user_zombie_class(victim) != idclass) 
		return HAM_IGNORED 
	
	emit_sound(victim, CHAN_BODY, g_sound[random_num(0,1)], 0.7, ATTN_NORM, 0, PITCH_LOW)
	
	if(!g_hardening[victim]) 
		return HAM_IGNORED 
	
	SetHamParamFloat(4, damage * harden_damage_def) 
	set_pdata_float(victim, 108, harden_painshock_def, 5) 
	
	return HAM_HANDLED 
} 

// ================================= MAIN PUBLIC ========================================= 
#define DMG_EXPLOSION (1<<24)
public death_effect(id) 
{ 
	static Float:Origin[3] 
	pev(id, pev_origin, Origin) 
	
	create_explode_effect(Origin) 
	emit_sound(id, CHAN_STATIC, death_exp_effect_sound, 1.0, ATTN_NORM, 0, PITCH_NORM) 
	
	new iVictim = -1;
	while ((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, Origin, death_exp_radius)) != 0)
	{
		if(!is_user_alive(iVictim)) continue;
		if(iVictim == id) continue;
		if(get_pdata_int(iVictim, m_iTeam) == get_pdata_int(id, m_iTeam)) continue;
		if(!IsDirect(id, iVictim)) continue;		
		check_and_knockback(id, iVictim, Origin, death_exp_radius) 
	}
} 
public create_explode_effect(Float:Origin[3]) 
{ 
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, Origin[0]) 
	engfunc(EngFunc_WriteCoord, Origin[1]) 
	engfunc(EngFunc_WriteCoord, Origin[2]+70) 
	write_short(g_explode_effect_idspr);
	write_byte(10);
	write_byte(255);
	message_end();
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, Origin[0]) 
	engfunc(EngFunc_WriteCoord, Origin[1]) 
	engfunc(EngFunc_WriteCoord, Origin[2]+70) 
	write_short(g_explode_effect_idspr2);
	write_byte(10);
	write_byte(255);
	message_end();
	/*
	new iEnt;
	new Float:fCurTime;
	global_get(glb_time, fCurTime);
	iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	
	set_pev(iEnt, pev_classname, "boomer_exp");
	set_pev(iEnt, pev_solid, SOLID_NOT);
	set_pev(iEnt, pev_movetype, MOVETYPE_TOSS);
	set_pev(iEnt, pev_sequence, 0);	
	set_pev(iEnt, pev_framerate, 1.0);
	engfunc(EngFunc_SetModel, iEnt, death_exp_effect_model);
	set_pev(iEnt, pev_origin, Origin);
	engfunc(EngFunc_DropToFloor, iEnt);
	set_pev(iEnt, pev_nextthink, fCurTime + 2.0);
	
	iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));	
	set_pev(iEnt, pev_classname, "boomer_exp");
	set_pev(iEnt, pev_solid, SOLID_NOT);
	set_pev(iEnt, pev_movetype, MOVETYPE_TOSS);
	set_pev(iEnt, pev_sequence, 0);	
	set_pev(iEnt, pev_framerate, 1.0);
	set_pev(iEnt, pev_body,1);
	engfunc(EngFunc_SetModel, iEnt,death_exp_effect_model2);
	set_pev(iEnt, pev_origin, Origin);
	engfunc(EngFunc_DropToFloor, iEnt);
	set_pev(iEnt, pev_nextthink, fCurTime + 3.0);*/
} 
public HamF_Think(iEnt)
{
	if (!pev_valid(iEnt)) return HAM_IGNORED;
	
	new classname[32];
	pev(iEnt, pev_classname, classname, charsmax(classname));
	if(!equal(classname, "boomer_exp")) return HAM_IGNORED;
	
	set_pev(iEnt, pev_effects, EF_NODRAW);
	set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
	return HAM_IGNORED;
}
stock IsDirect(id,id2)
{
	new Float:v1[3], Float:v2[3];
	pev(id, pev_origin, v1);
	pev(id2, pev_origin, v2);
	
	new Float:hit_origin[3];
	new tr;
	
	engfunc(EngFunc_TraceLine, v1, v2, 1, -1, tr);
	get_tr2(tr, TR_vecEndPos, hit_origin);
	
	if (!vector_distance(hit_origin, v2)) return 1;
	return 0;
}

public check_and_knockback(id, iVictim, Float:Origin[3], Float:radius) 
{ 
	static const hit_sound[3][] = 
	{ 
		"player/bhit_flesh-1.wav", 
		"player/bhit_flesh-2.wav", 
		"player/bhit_flesh-3.wav" 
	} 

	if(is_user_alive(iVictim) && can_see_fm(iVictim, id) && cs_get_user_team(id) != cs_get_user_team(iVictim)) 
	{ 
		shake_screen(iVictim) 
		
		new Float:flVictimOrigin [ 3 ],Float:flVelocity[3]
		pev ( iVictim, pev_origin, flVictimOrigin )
		flVictimOrigin[2]+=200.0
		get_speed_vector ( Origin, flVictimOrigin, death_exp_knockspeed, flVelocity )
		set_pev ( iVictim, pev_velocity,flVelocity )
		
		ExecuteHam(Ham_TakeDamage, iVictim, id, id, 80.0, (1<<7));
		emit_sound(iVictim, CHAN_BODY, hit_sound[random(sizeof(hit_sound))], 1.0, ATTN_NORM, 0, PITCH_NORM) 
	} 
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}

// ================================ MAIN STOCK ===================================== 
set_weapons_timeidle(id, Float:timeidle) 
{ 
new entwpn = fm_get_user_weapon_entity(id, get_user_weapon(id)) 
if (pev_valid(entwpn)) set_pdata_float(entwpn, m_flTimeWeaponIdle, timeidle + 3.0, 4) 
} 

set_player_nextattack(id, Float:nexttime) 
{ 
set_pdata_float(id, m_flNextAttack, nexttime, 4) 
} 

stock play_weapon_anim(player, anim) 
{ 
set_pev(player, pev_weaponanim, anim) 

message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player) 
write_byte(anim) 
write_byte(pev(player, pev_body)) 
message_end() 
} 

stock PlaySound(id, const sound[]) 
{ 
client_cmd(id, "spk ^"%s^"", sound) 
} 

stock set_entity_anim(ent, anim) 
{ 
if(!pev_valid(ent)) 
return 

entity_set_float(ent, EV_FL_animtime, get_gametime()) 
entity_set_float(ent, EV_FL_framerate, 1.0) 
entity_set_float(ent, EV_FL_frame, 0.0) 

entity_set_int(ent, EV_INT_sequence, anim)      
} 

stock shake_screen(id) 
{ 
message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"),{0,0,0}, id) 
write_short(1<<14) 
write_short(1<<13) 
write_short(1<<13) 
message_end() 
} 
stock bool:can_see_fm(entindex1, entindex2) 
{ 
	if (!entindex1 || !entindex2) 
	return false 
	
	if (pev_valid(entindex1) && pev_valid(entindex1)) 
	{ 
		new flags = pev(entindex1, pev_flags) 
		if (flags & EF_NODRAW || flags & FL_NOTARGET) 
		{ 
			return false 
		} 
		
		new Float:lookerOrig[3] 
		new Float:targetBaseOrig[3] 
		new Float:targetOrig[3] 
		new Float:temp[3] 
		
		pev(entindex1, pev_origin, lookerOrig) 
		pev(entindex1, pev_view_ofs, temp) 
		lookerOrig[0] += temp[0] 
		lookerOrig[1] += temp[1] 
		lookerOrig[2] += temp[2] 
		
		pev(entindex2, pev_origin, targetBaseOrig) 
		pev(entindex2, pev_view_ofs, temp) 
		targetOrig[0] = targetBaseOrig [0] + temp[0] 
		targetOrig[1] = targetBaseOrig [1] + temp[1] 
		targetOrig[2] = targetBaseOrig [2] + temp[2] 
		
		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the had of seen player 
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater)) 
		{ 
			return false 
		}  
		else  
		{ 
			new Float:flFraction 
			get_tr2(0, TraceResult:TR_flFraction, flFraction) 
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2)) 
			{ 
				return true 
			} 
			else 
			{ 
				targetOrig[0] = targetBaseOrig [0] 
				targetOrig[1] = targetBaseOrig [1] 
				targetOrig[2] = targetBaseOrig [2] 
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player 
				get_tr2(0, TraceResult:TR_flFraction, flFraction) 
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2)) 
				{ 
					return true 
				} 
				else 
				{ 
					targetOrig[0] = targetBaseOrig [0] 
					targetOrig[1] = targetBaseOrig [1] 
					targetOrig[2] = targetBaseOrig [2] - 17.0 
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player 
					get_tr2(0, TraceResult:TR_flFraction, flFraction) 
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2)) 
					{ 
						return true 
					} 
				} 
			} 
		} 
	} 
	return false 
} 
