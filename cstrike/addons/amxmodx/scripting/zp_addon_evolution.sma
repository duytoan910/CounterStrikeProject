#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <fun>

#define PLUGIN "[ZP] Addon: Evolution"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define TASK_SHOWHUD 321321

#define HUD_DELAY_TIME 1.0

new g_ham_bot, g_sync_hud1, g_sync_hud2
new g_level, g_exploSpr
const MAX_LEVEL_HUMAN = 10
static zombie_kill
static zombie_damage[33]
static temp

// Human Evolution Vars + Config
new const levelup_sound[] = "zombie_plague/levelup.wav"

new Float:XDAMAGE[11] = {
	1.0,
	1.1,
	1.2,
	1.3,
	1.4,
	1.5,
	1.6,
	1.7,
	1.8,
	1.9,
	2.0
}
new const zp_cso_hmlvl_r[11] =
{
	0,
	0,
	0,
	0,
	255,
	255,
	255,
	255,
	255,
	255,
	255
}
new const zp_cso_hmlvl_g[11] =
{
	255,
	255,
	255,
	255,
	255,
	255,
	255,
	155,
	155,
	155,
	0
}
new const zp_cso_hmlvl_b[11] =
{
	0,
	0,
	0,
	0,
	55,
	55,
	55,
	55,
	55,
	55,
	0
}
public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("DeathMsg", "event_death", "a")
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	
	//RegisterHam(Ham_Spawn, "player", "fw_spawn_post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage")
	
	g_sync_hud1 = CreateHudSyncObj(18)
	g_sync_hud2 = CreateHudSyncObj(19)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheSound, levelup_sound)
	g_exploSpr = precache_model("sprites/shockwave.spr");
	
	// Precache Sprites
}
public client_putinserver(id)
{
	if(!g_ham_bot && is_user_bot(id))
	{
		g_ham_bot = 1
		set_task(0.1, "do_register", id)
	}
}
public do_register(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_takedamage")
}
public zp_user_humanized_post(id)
{
	set_task(HUD_DELAY_TIME, "show_hud", id+TASK_SHOWHUD, _, _, "b")
}

public zp_user_infected_post(id)
{
	set_hudmessage(0, 0, 0, -1.0, 0.83, 0, 2.0, 1.0)
	ShowSyncHudMsg(id, g_sync_hud1, "")

	remove_task(id+TASK_SHOWHUD)
}

public event_newround()
{
	static id
	for (id = 1; id <= get_maxplayers(); id++)
	{
		zombie_damage[id] = 0
		g_level = 0
		zombie_kill = 0
		temp = 0
	}	
}

public event_death()
{
	new attacker = read_data(1)
	new victim = read_data(2) 	
	
	zombie_kill++
	
	// Zombie Die
	if (victim != attacker && is_user_connected(attacker) && zp_get_user_zombie(victim) && !zp_get_user_zombie(attacker))
	{
		temp++
		if(temp==20)
		{
			UpdateLevelTeamHuman()
			temp=0
		}
	}
}
public zp_round_started(gamemode)
{
	static id
	if(gamemode == MODE_INFECTION || gamemode == MODE_MULTI)
	{
		for(id=0;id<get_maxplayers();id++)
		{
			if (is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id)  && !zp_get_user_assassin(id) && !zp_get_user_survivor(id) && !zp_get_user_sniper(id))
			{
				if(is_user_bot(id))
					continue
				set_task(HUD_DELAY_TIME, "show_hud", id+TASK_SHOWHUD, _, _, "b")
			}	
		}		
	}		
}

public fw_takedamage(victim, inflictor, attacker, Float:damage, damagetype)
{
	if(damagetype & DMG_GENERIC || victim == attacker || !is_user_alive(victim) || !is_user_connected(attacker))
		return HAM_IGNORED

	if((damagetype & (1<<24)) && zp_get_user_zombie(attacker))
		return HAM_IGNORED	
	
	if(victim != attacker && is_user_connected(attacker) && !zp_get_user_zombie(attacker) && !zp_get_user_nemesis(attacker) && !zp_get_user_survivor(attacker) && !zp_get_user_assassin(attacker) && !zp_get_user_sniper(attacker))
	{
		if (g_level)
		{
			new Float: xdmg = XDAMAGE[g_level]
			damage *= xdmg
		}

		SetHamParamFloat(4, damage)
		zombie_damage[attacker] += floatround(damage)
	}
	
	return HAM_HANDLED
}

public show_hud(taskid)
{
	new id = taskid - TASK_SHOWHUD
	
	if (is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && !zp_get_user_survivor(id)  && !zp_get_user_assassin(id) && !zp_get_user_sniper(id) && !is_user_bot(id))
	{
		show_hud_text(id)
	} else {
		remove_task(taskid)
	}
}

public UpdateLevelTeamHuman()
{
	g_level++
	if (g_level > MAX_LEVEL_HUMAN)
	{
		g_level = MAX_LEVEL_HUMAN
	}else{
		static id
		for (id = 1; id <= get_maxplayers(); id++)
		{
			if (is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && !zp_get_user_survivor(id)  && !zp_get_user_assassin(id) && !zp_get_user_sniper(id) && !is_user_bot(id))
			{
				// Play Sound
				PlaySound2(id, levelup_sound)
				
				// Effect
				EffectLevelUp(id)
				set_hudmessage(zp_cso_hmlvl_r[g_level], zp_cso_hmlvl_g[g_level], zp_cso_hmlvl_b[g_level], -1.0, 0.40, 1, 5.0, 5.0)
				ShowSyncHudMsg(id, g_sync_hud2, "Level Up to %i !!!", g_level)	
			}
		}	
	}
	
}
public EffectLevelUp(id)
{
	if (!is_user_alive(id)) return;
	
	// get origin
	static Float:originF[3]
	pev(id, pev_origin, originF)
	
	// set color
	new color[3]
	color[0] = zp_cso_hmlvl_r[g_level]
	color[1] = zp_cso_hmlvl_g[g_level]
	color[2] = zp_cso_hmlvl_b[g_level]
	
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+60.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(30) // width
	write_byte(0) // noise
	write_byte(color[0]) // red
	write_byte(color[1]) // green
	write_byte(color[2]) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}

public show_hud_text(id)
{
	static level_color[3]
	
	level_color[0] = zp_cso_hmlvl_r[g_level]
	level_color[1] = zp_cso_hmlvl_g[g_level]
	level_color[2] = zp_cso_hmlvl_b[g_level]
	
	set_hudmessage(level_color[0], level_color[1], level_color[2], -1.0, 0.70, 0, 0.0, 2.0)
	
	if(g_level == 0)
	{
		ShowSyncHudMsg(id, g_sync_hud1, "Zombie Damage: %i - Zombie Kill: %i^nAttack Power: 100%%^n[--------------------]",zombie_damage[id],zombie_kill)
	} else if(g_level == 1) {
		ShowSyncHudMsg(id, g_sync_hud1, "Zombie Damage: %i - Zombie Kill: %i^nAttack Power: 110%%^n[++------------------]",zombie_damage[id],zombie_kill)			
	} else if(g_level == 2) {
		ShowSyncHudMsg(id, g_sync_hud1, "Zombie Damage: %i - Zombie Kill: %i^nAttack Power: 120%%^n[++++----------------]",zombie_damage[id],zombie_kill)			
	} else if(g_level == 3) {
		ShowSyncHudMsg(id, g_sync_hud1, "Zombie Damage: %i - Zombie Kill: %i^nAttack Power: 130%%^n[++++++--------------]",zombie_damage[id],zombie_kill)			
	} else if(g_level == 4) {
		ShowSyncHudMsg(id, g_sync_hud1, "Zombie Damage: %i - Zombie Kill: %i^nAttack Power: 140%%^n[++++++++------------]",zombie_damage[id],zombie_kill)			
	} else if(g_level == 5) {
		ShowSyncHudMsg(id, g_sync_hud1, "Zombie Damage: %i - Zombie Kill: %i^nAttack Power: 150%%^n[++++++++++----------]",zombie_damage[id],zombie_kill)			
	} else if(g_level == 6) {
		ShowSyncHudMsg(id, g_sync_hud1, "Zombie Damage: %i - Zombie Kill: %i^nAttack Power: 160%%^n[++++++++++++--------]",zombie_damage[id],zombie_kill)			
	} else if(g_level == 7) {
		ShowSyncHudMsg(id, g_sync_hud1, "Zombie Damage: %i - Zombie Kill: %i^nAttack Power: 170%%^n[++++++++++++++------]",zombie_damage[id],zombie_kill)			
	} else if(g_level == 8) {
		ShowSyncHudMsg(id, g_sync_hud1, "Zombie Damage: %i - Zombie Kill: %i^nAttack Power: 180%%^n[++++++++++++++++----]",zombie_damage[id],zombie_kill)			
	} else if(g_level == 9) {
		ShowSyncHudMsg(id, g_sync_hud1, "Zombie Damage: %i - Zombie Kill: %i^nAttack Power: 190%%^n[++++++++++++++++++--]",zombie_damage[id],zombie_kill)			
	} else if(g_level == 10) {
		ShowSyncHudMsg(id, g_sync_hud1, "Zombie Damage: %i - Zombie Kill: %i^nAttack Power: 200%%^n[++++++++++++++++++++]",zombie_damage[id],zombie_kill)		
	}
}
stock PlaySound2(id, const sound[])
{
	client_cmd(id, "spk ^"%s^"", sound)
}
