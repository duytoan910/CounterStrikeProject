/*================================================================================
	
	----------------------------------
	-*- [ZP] Class: Human: Raptor -*-
	----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <zp50_class_human>
#include <zp50_gamemodes>
#include <zp50_class_survivor>
#include <zp50_class_sniper>

// Raptor Human Attributes
new const humanclass2_name[] = "Medict Woman"
new const humanclass2_info[] = ""
new const humanclass2_models[][] = { "soi" }
const humanclass2_health = 1000
const Float:humanclass2_speed = 1.0
const Float:humanclass2_gravity = 0.8

#define MEDBOX_HEALTH 100.0
#define DAMAGE_NEED 10000.0

#define MEDBOX_CLASSNAME "MEDBOX_MODEL"
new const medic_box_model[] = {"models/bg_medibox_open.mdl"}
new const medic_box_sound[] = {"zombie_plague/get_box.wav"}
new const spriteheal[] = "sprites/zb_restore_health.spr";

new g_HumanClassID, g_MaxPlayers, g_hamczbots, Float:g_DamageCount[33], Float:g_DropDelay[33], spriteid

public plugin_init(){
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_think(MEDBOX_CLASSNAME, "func_Medbox_Think")
	register_touch(MEDBOX_CLASSNAME, "*", "func_Medbox_Touch")
	g_MaxPlayers = get_maxplayers()
}
public plugin_precache()
{
	register_plugin("[ZP] Class: Human: Raptor", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_HumanClassID = zp_class_human_register(humanclass2_name, humanclass2_info, humanclass2_health, humanclass2_speed, humanclass2_gravity)
	new index
	for (index = 0; index < sizeof humanclass2_models; index++)
		zp_class_human_register_model(g_HumanClassID, humanclass2_models[index])

	precache_model(medic_box_model)
	precache_sound(medic_box_sound)
	spriteid = precache_model(spriteheal);
}

public client_putinserver(Player)
{
	if(is_user_bot(Player) && !g_hamczbots && get_cvar_pointer("bot_quota")) set_task(0.1, "register_ham_czbots", Player)
}
public register_ham_czbots(Player)
{
	if (g_hamczbots || !is_user_connected(Player) || !get_cvar_pointer("bot_quota")) return
	
	RegisterHamFromEntity(Ham_TakeDamage, Player, "fw_TakeDamage")
	
	g_hamczbots = true
}
public zp_round_started(gamemode, id){
	for(new i = 0; i<g_MaxPlayers; i++){
		g_DamageCount[i] = 0.0
	}
}

public zp_fw_core_cure_post(id, attacker){
	if(!is_user_connected(attacker) || !is_user_alive(attacker))
		return;

	g_DamageCount[id] = 0.0

	if(zp_class_human_get_current(attacker) != g_HumanClassID)
		return;

	g_DropDelay[id] = get_gametime()
}

public zp_fw_core_infect_post(id, attacker){
	g_DamageCount[id] = 0.0
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(is_user_alive(attacker)
		 && !zp_get_user_zombie(attacker)
		  && zp_class_human_get_current(attacker) == g_HumanClassID
		  && !zp_class_survivor_get(attacker)
		  && !zp_class_sniper_get(attacker)) 
		{
			g_DamageCount[attacker] += damage
			if(g_DamageCount[attacker] >= DAMAGE_NEED && g_DropDelay[attacker] < get_gametime()){
				g_DropDelay[attacker] = get_gametime() + 3.0
				g_DamageCount[attacker] = 0.0

				//Make Box
				Create_MedBox(attacker)
			}
		}
	}
}
public Create_MedBox(id){
	static ent; ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(ent)) return

	new Float:EntOrigin[3];pev(id, pev_origin, EntOrigin)

	// Set info for ent
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_rendermode, kRenderNormal)
	set_pev(ent, pev_renderamt, 255.0)
	set_pev(ent, pev_owner, id)	

	set_pev(ent, pev_classname, MEDBOX_CLASSNAME)
	engfunc(EngFunc_SetModel, ent, medic_box_model)
	
	set_pev(ent, pev_maxs, Float:{5.0, 5.0, 1.0})
	set_pev(ent, pev_mins, Float:{-5.0, -5.0, -25.0})

	EntOrigin[2] += 25.0
	set_pev(ent, pev_origin, EntOrigin)

	set_pev(ent, pev_gravity, 1.0)
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_frame, 0.0)
	
	set_pev(ent, pev_fuser1, get_gametime() + 3.0)
	set_pev(ent, pev_fuser2, get_gametime() + 15.0)

	new Float:anglevec[3], Float:velocity[3]
	pev(id, pev_v_angle, anglevec)
	engfunc(EngFunc_MakeVectors, anglevec)
	global_get(glb_v_forward, anglevec)
	velocity[0] = anglevec[0] * 350
	velocity[1] = anglevec[1] * 350
	velocity[2] = anglevec[2] * 350
	set_pev(ent, pev_velocity, velocity)

	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}
public func_Medbox_Think(ent){
	if(!pev_valid(ent))
		return

	if(pev(ent, pev_fuser2) < get_gametime()){
		set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
		return
	}

	static Float:EntOrigin[3];pev(ent, pev_origin, EntOrigin)
	static Float:Angles[3];pev(ent, pev_angles, Angles)
	Angles[1] += 3.0
	if(Angles[1]>= 360.0){
		Angles[1] = 0.0
	}

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, EntOrigin, 0)
	write_byte(TE_DLIGHT) // TE id
	engfunc(EngFunc_WriteCoord, EntOrigin[0]) // x
	engfunc(EngFunc_WriteCoord, EntOrigin[1]) // y
	engfunc(EngFunc_WriteCoord, EntOrigin[2]) // z
	write_byte(4) // radius
	write_byte(255) // r
	write_byte(225) // g
	write_byte(225) // b
	write_byte(5) // life
	write_byte(5) // decay rate
	message_end()

	set_pev(ent, pev_nextthink, get_gametime() + 0.01)
}
public func_Medbox_Touch(ent, toucher){
	if(!pev_valid(ent) || !is_user_connected(toucher) || !is_user_alive(toucher) || zp_core_is_zombie(toucher))
		return

	new Float:ToucherHP;pev(toucher, pev_health, ToucherHP)
	new Float:nextHP,Float:ToucherMaxHP;
	ToucherMaxHP = float(zp_class_human_get_max_health(toucher, zp_class_human_get_current(toucher)))
	static owner;owner=pev(ent, pev_owner)

	if(pev(ent, pev_fuser1) > get_gametime())
		return

	if(owner == toucher)
		nextHP = ToucherHP + floatround(MEDBOX_HEALTH/2)
	else nextHP = ToucherHP + MEDBOX_HEALTH
		
	if(nextHP > ToucherMaxHP){
		set_pev(toucher, pev_health, ToucherMaxHP)
	}else{
		set_pev(toucher, pev_health, nextHP)
	}

	Medbox_get_effect(ent, toucher)
	set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
}
public Medbox_get_effect(ent, id){
	new Float: fOrigin[3];
	pev( id, pev_origin, fOrigin );
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_short(spriteid);
	write_byte(10);
	write_byte(255);
	message_end();
	
	emit_sound(ent, CHAN_BODY, medic_box_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}