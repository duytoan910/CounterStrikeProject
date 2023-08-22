/*================================================================================
	
	-------------------------------
	-*- [ZP] Game Mode: NPC -*-
	-------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amx_settings_api>
#include <cs_teams_api>
#include <fun>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <zp50_gamemodes>
#include <zp50_deathmatch>
#include <zp50_class_nemesis>

#define BOSS_HP 250000.0
#define HEALTH_OFFSET 50000.0
#define BLOODCOLOR 248
#define FIGHT_MUSIC "zombie_plague/boss/background/Scenario_Start.mp3"

native Create_FallenTitan(id, Float:HP)
native Create_Oberon(id, Float:HP)
native Create_Dione(id, Float:HP)
native Create_Phobos(id, Float:HP)
native Create_Revenant(id, Float:HP)
native Create_Angra(id, Float:HP)
native Create_BioScropion(id, Float:HP)

native set_hb_maxhp(Float:value, Boss_Ent)

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_npc[][] = { "zombie_plague/npc1.wav" , "zombie_plague/npc2.wav" }

#define SOUND_MAX_LENGTH 64

new Array:g_sound_npc

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 255
#define HUD_EVENT_G 20
#define HUD_EVENT_B 20

new g_MaxPlayers, g_npcround, g_Boss_Ent
new g_HudSync
new g_TargetPlayer
new m_iBlood[2]

new cvar_npc_chance, cvar_npc_min_players
new cvar_npc_show_hud, cvar_npc_sounds
new cvar_npc_allow_respawn
new g_HamBot;

public plugin_init() {
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")	
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")
}

public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: NPC", ZP_VERSION_STRING, "ZP Dev Team")
	zp_gamemodes_register("Titan boss")
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_npc_chance = register_cvar("zp_npc_chance", "1")
	cvar_npc_min_players = register_cvar("zp_npc_min_players", "0")
	cvar_npc_show_hud = register_cvar("zp_npc_show_hud", "1")
	cvar_npc_sounds = register_cvar("zp_npc_sounds", "1")
	cvar_npc_allow_respawn = register_cvar("zp_npc_allow_respawn", "1")
	
	precache_sound(FIGHT_MUSIC)
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")

	// Initialize arrays
	g_sound_npc = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND NPC", g_sound_npc)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_npc) == 0)
	{
		for (index = 0; index < sizeof sound_npc; index++)
			ArrayPushString(g_sound_npc, sound_npc[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND NPC", g_sound_npc)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_npc); index++)
	{
		ArrayGetString(g_sound_npc, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
}

public client_putinserver(id)
{
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Do_Register_HamBot", id)
	}
}

public Do_Register_HamBot(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Player")
}

public do_tele_player(id)
{	
	if(!g_npcround)
		return
	static Origin[3];		
	get_user_origin(id, Origin)
	Origin[2] = -2300;
	set_user_origin(id, Origin)
}
public Event_NewRound()
{
	PlaySoundToClients("")
	remove_entity(g_Boss_Ent)
}
public logevent_round_end()
{
	g_npcround = false
	remove_entity(g_Boss_Ent)
}

public MakeHB(id)
{
	if(!is_user_alive(id))
		return
	
	set_pev(id, pev_health, BOSS_HP)
	// set_pev(id, pev_movetype, MOVETYPE_FOLLOW)
	// set_pev(id, pev_solid, SOLID_NOT);
	// set_pev(id, pev_aiment, g_Boss_Ent)
	// set_pev(id, pev_body, 1)
	//fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)

}
// new Float:fDamage[33]
public fw_TraceAttack(Ent, Attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	if(!is_valid_ent(Ent)) 
		return
	 
	static Classname[32], BossClassame[32]
	pev(g_Boss_Ent, pev_classname, BossClassame, charsmax(BossClassame))
	pev(Ent, pev_classname, Classname, charsmax(Classname)) 
		 
	if(!equal(Classname, BossClassame))
		return
		
	static Float:EndPos[3] 
	get_tr2(ptr, TR_vecEndPos, EndPos)
	create_blood(EndPos)
	
	// fDamage[Attacker]+=Damage
	// if(fDamage[Attacker]>=100.0)
	// {
	// 	zp_set_user_ammo_packs(Attacker, zp_get_user_ammo_packs(Attacker)+3)
	// 	fDamage[Attacker] = 0.0
	// }	
	new owner;owner=pev(Ent,pev_owner)
	if(Damage){
		ExecuteHamB(Ham_TakeDamage, owner ,Attacker ,Attacker, Damage, DamageType)
		set_pev(Ent, pev_health, BOSS_HP)

		client_print(Attacker, print_center, "HP: [%d]", pev(owner, pev_health))
	}

}
public fw_TraceAttack_Player(victim, Attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	// if(!is_user_connected(Attacker))
	// 	return HAM_IGNORED	
	// if(!g_npcround)
	// 	return HAM_IGNORED
		
	// return HAM_SUPERCEDE
}
// Deathmatch module's player respawn forward
public zp_fw_deathmatch_respawn_pre(id)
{
	// Respawning allowed?
	if (!get_pcvar_num(cvar_npc_allow_respawn))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public zp_fw_core_cure_post(id)
{
	// Respawning allowed?
	if (!get_pcvar_num(cvar_npc_allow_respawn))
		return PLUGIN_HANDLED;

	if (!g_npcround)
		return PLUGIN_HANDLED;
	
	if (!is_user_alive(id) || zp_core_is_zombie(id) || zp_get_user_survivor(id))
		return PLUGIN_HANDLED;
		
	set_task(0.1, "do_tele_player", id)
	return PLUGIN_CONTINUE;
}

public zp_fw_core_spawn_post(id)
{
	if(!g_npcround)
		return

	// Always respawn as human on npc rounds
	zp_core_respawn_as_zombie(id, false)
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_npc_chance)) != 1)
			return PLUGIN_HANDLED;
		
		// Min players
		if (GetAliveCount() < get_pcvar_num(cvar_npc_min_players))
			return PLUGIN_HANDLED;
	}
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_post(game_mode_id, target_player)
{
	// Pick player randomly?
	g_TargetPlayer = (target_player == RANDOM_TARGET_PLAYER) ? getRandomBot() : target_player
}

public zp_fw_gamemodes_start()
{
	g_npcround = true

	// Turn player into npc
	zp_class_nemesis_set(g_TargetPlayer)
	
	// Remaining players should be humans (CTs)
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Not alive
		if (!is_user_alive(id))
			continue;
		
		// This is our NPC
		if (zp_class_nemesis_get(id))
			continue;
		
		// Switch to CT
		cs_set_player_team(id, CS_TEAM_CT)
	}
	
	// Play NPC sound
	if (get_pcvar_num(cvar_npc_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_npc, random_num(0, ArraySize(g_sound_npc) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
	
	if (get_pcvar_num(cvar_npc_show_hud))
	{
		// Show NPC HUD notice
		new name[32]
		get_user_name(g_TargetPlayer, name, charsmax(name))
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "NOTICE_NPC", name)
	}
	static Origin[3];
	for(new i=0; i < get_maxplayers();i++)
	{
		if(!is_user_alive(i)) continue
		get_user_origin(i, Origin)
		Origin[2] = -2300;
		set_user_origin(i, Origin)
	}
	
	if(pev_valid(g_Boss_Ent))
		remove_entity(g_Boss_Ent)

	//switch(random_num(0,4))
	switch(6)
	{
		case 0:g_Boss_Ent = Create_FallenTitan(g_TargetPlayer, BOSS_HP)
		case 1:g_Boss_Ent = Create_Oberon(g_TargetPlayer, BOSS_HP)
		case 2:g_Boss_Ent = Create_Dione(g_TargetPlayer, BOSS_HP)
		case 3:g_Boss_Ent = Create_Phobos(g_TargetPlayer, BOSS_HP)
		case 4:g_Boss_Ent = Create_Revenant(g_TargetPlayer, BOSS_HP)
		case 5:g_Boss_Ent = Create_Angra(g_TargetPlayer, BOSS_HP)
		case 6:g_Boss_Ent = Create_BioScropion(g_TargetPlayer, BOSS_HP)
	}	
	
	RegisterHamFromEntity(Ham_TraceAttack, g_Boss_Ent, "fw_TraceAttack", 1)
	
	set_task(0.5, "MakeHB", g_TargetPlayer)
}

public client_PreThink(id)
{
	if(!g_npcround)
		return
	if(!is_user_alive(id))
		return
	if(!pev_valid(g_Boss_Ent))
		return
	
	entity_set_int(id, EV_INT_watertype, -3);
	
	//client_print(id, print_center, "HP: [%.0f]", pev(g_Boss_Ent, pev_health))
	
	if(!zp_class_nemesis_get(id))
		return;
		
	static Float:EntOrigin[3]
	pev(g_Boss_Ent, pev_origin, EntOrigin)

	new Classname[32]
	pev(id, pev_classname, Classname, sizeof(Classname))

	if(equal(Classname, "NPC_DIONE"))
		EntOrigin[2]+=20.0
	else EntOrigin[2]+=80.0

	set_pev(id, pev_origin, EntOrigin)	
	pev(g_Boss_Ent, pev_v_angle, EntOrigin)
	set_pev(id, pev_v_angle, EntOrigin)	
	set_pev(id, pev_velocity, {0,0,0})
	set_pev(id, pev_maxspeed, 0.0)
	
}
stock entity_set_aim(ent,const Float:origin2[3],bone=0)
{
	if(!pev_valid(ent))
		return 0;

	static Float:origin[3]
	origin[0] = origin2[0]
	origin[1] = origin2[1]
	origin[2] = origin2[2]

	static Float:ent_origin[3], Float:angles[3]

	if(bone)
		engfunc(EngFunc_GetBonePosition,ent,bone,ent_origin,angles)
	else
		pev(ent,pev_origin,ent_origin)

	origin[0] -= ent_origin[0]
	origin[1] -= ent_origin[1]
	origin[2] -= ent_origin[2]

	static Float:v_length
	v_length = vector_length(origin)

	static Float:aim_vector[3]
	aim_vector[0] = origin[0] / v_length
	aim_vector[1] = origin[1] / v_length
	aim_vector[2] = origin[2] / v_length

	static Float:new_angles[3]
	vector_to_angle(aim_vector,new_angles)

	new_angles[0] *= -1

	if(new_angles[1]>180.0) new_angles[1] -= 360
	if(new_angles[1]<-180.0) new_angles[1] += 360
	if(new_angles[1]==180.0 || new_angles[1]==-180.0) new_angles[1]=-179.999999

	set_pev(ent,pev_angles,new_angles)
	set_pev(ent,pev_fixangle,1)

	return 1;
}
// Plays a sound on clients
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}

// Get Alive Count -returns alive players number-
GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}

// Get Random Alive -returns index of alive player number target_index -
GetRandomAlive(target_index)
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
		
		if (iAlive == target_index)
			return id;
	}
	
	return -1;
}

stock create_blood(const Float:origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(BLOODCOLOR)
	write_byte(random_num(5,10))
	message_end()
}
public getRandomBot(){
	new id = GetRandomAlive(random_num(1, GetAliveCount()))
	if(!is_user_bot(id) || !is_user_alive(id)){
		return getRandomBot()
	}
	return id
}