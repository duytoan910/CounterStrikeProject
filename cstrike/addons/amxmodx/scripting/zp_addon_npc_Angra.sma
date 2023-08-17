#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <cstrike>

#define PLUGIN "[Dias's Boss] ANGRA"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define ANGRA_MODEL "models/zombie_plague/boss/zbs_bossl_big06.mdl"

#define TENTACLE_MODEL "models/zombie_plague/boss/tentacle3.mdl"
#define EARTHHOLE_MODEL_BEGIN "models/zombie_plague/boss/ef_tentacle_sign.mdl"
#define EARTHHOLE_MODEL_END "models/zombie_plague/boss/ef_tentacle.mdl"

#define POISON_SPR "sprites/ef_smoke_poison.spr"

#define ANGRA_CLASSNAME "cso_angra"
#define TENTACLE_CLASSNAME "tentacle"
#define EARTHHOLE_CLASSNAME "earthhole"
#define POISON_CLASSNAME "poison"
#define TENTACLE_MAX1 30
#define TENTACLE_MAX2 60
#define ANGRA_ATTACK_RANGE 150.0
#define HEALTH_OFFSET 50000.0
#define ANGRA_SPEED 250.0

#define QUAKE_DAMAGE random_float(200.0, 400.0)
#define QUAKE_DAMAGE_RADIUS 400.0
#define BITE_DAMAGE random_float(350.0, 450.0)
#define SWING_DAMAGE random_float(350.0, 450.0)
#define TENTACLE_DAMAGE random_float(150.0, 200.0)
#define POISON_DAMAGE random_float(50.0, 100.0)

enum
{
	ANGRA_ANIM_DUMMY = 0,
	ANGRA_ANIM_APPEAR1,
	ANGRA_ANIM_APPEAR2,
	ANGRA_ANIM_APPEAR3,
	ANGRA_ANIM_IDLE,
	ANGRA_ANIM_WALK,
	ANGRA_ANIM_RUN,
	ANGRA_ANIM_ATTACK_QUAKE,
	ANGRA_ANIM_ATTACK_BITE,
	ANGRA_ANIM_ATTACK_WIND,
	ANGRA_ANIM_ATTACK_SWING,
	ANGRA_ANIM_ATTACK_TENTACLE1,
	ANGRA_ANIM_ATTACK_TENTACLE2,
	ANGRA_ANIM_ATTACK_POISON1,
	ANGRA_ANIM_ATTACK_POISON2,
	ANGRA_ANIM_ATTACK_FLY1_POISON1,
	ANGRA_ANIM_ATTACK_FLY1_POISON2,
	ANGRA_ANIM_ATTACK_FLY2_POISON1,
	ANGRA_ANIM_FLY1,
	ANGRA_ANIM_FLY2,
	ANGRA_ANIM_LAND1,
	ANGRA_ANIM_LAND2,
	ANGRA_ANIM_LAND3,
	ANGRA_ANIM_FLY2_2,
	ANGRA_ANIM_FLY_CHANGE1,
	ANGRA_ANIM_FLY_CHANGE2,
	ANGRA_ANIM_DEATH,
	ANGRA_ANIM_STUN1,
	ANGRA_ANIM_STUN2,
	ANGRA_ANIM_STUN3
}

enum
{
	ANGRA_STATE_IDLE = 0,
	ANGRA_STATE_SEARCHING_ENEMY,
	ANGRA_STATE_CHASE_ENEMY,
	ANGRA_STATE_WALK,
	ANGRA_STATE_APPEAR,
	ANGRA_STATE_ATTACK_QUAKE,
	ANGRA_STATE_ATTACK_BITE,
	ANGRA_STATE_ATTACK_SWING,
	ANGRA_STATE_ATTACK_TENTACLE1,
	ANGRA_STATE_ATTACK_TENTACLE2,
	ANGRA_STATE_FLYING_UP,
	ANGRA_STATE_IDLE_FLYING,
	ANGRA_STATE_LANDING_DOWN,
	ANGRA_STATE_ATTACK_LAND_POISON1,
	ANGRA_STATE_ATTACK_LAND_POISON2,
	ANGRA_STATE_ATTACK_FLY_POISON1,
	ANGRA_STATE_ATTACK_FLY_POISON2
}

new const footstep[][] = {	
	"zombie_plague/boss/boss_footstep_1.wav",
	"zombie_plague/boss/boss_footstep_2.wav"
}
#define SOUND_APPEAR1 "zombie_plague/boss/angra/angra_appear1.wav"
#define SOUND_APPEAR3 "zombie_plague/boss/angra/angra_appear3.wav"
#define SOUND_DO_POISON "zombie_plague/boss/angra/angra_zbs_poison1.wav"
#define SOUND_ATTACK_QUAKE "zombie_plague/boss/angra/angra_zbs_attack_quake.wav"
#define SOUND_ATTACK_BITE "zombie_plague/boss/angra/angra_zbs_attack_bite.wav"
#define SOUND_ATTACK_SWING "zombie_plague/boss/angra/zbs_attack_swing.wav"
#define SOUND_ATTACK_TENTACLE1 "zombie_plague/boss/angra/angra_zbs_attack_tentacle1.wav"
#define SOUND_ATTACK_TENTACLE2 "zombie_plague/boss/angra/angra_zbs_attack_tentacle2.wav"
#define SOUND_FLYING_UP "zombie_plague/boss/angra/angra_zbs_fly1.wav"
#define SOUND_FLYING "zombie_plague/boss/angra/angra_zbs_fly2.wav"
#define SOUND_LANDED "zombie_plague/boss/angra/angra_zbs_land3.wav"

#define APPEAR1_TIME 8.0
#define APPEAR2_ANIM_LOOP_TIME 0.5

#define TASK_APPEAR 28000+10
#define TASK_DO_QUAKE 28000+50
#define TASK_DO_BITE 28000+60
#define TASK_DO_SWING 28000+70
#define TASK_DO_TENTACLE 28000+80
#define TASK_DO_TENTACLE_SOUND 28000+90
#define TASK_DO_CREATING_TENTACLE 28000+100
#define TASK_TENTACLE_GROW 28000+110
#define TASK_DO_FLYING_UP 28000+120
#define TASK_DO_POISON 28000+140
#define TASK_DO_THROWING_POISON 28000+150
#define TASK_DO_LANDING_DOWN 28000+130

const WPN_NOT_DROP = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))

new g_Angra_Ent, m_iBlood[2]
new g_Msg_ScreenShake, g_MaxPlayers, Float:ANGRA_HEALTH, g_FootStep

const pev_state = pev_iuser1
const pev_time = pev_fuser1
const pev_time2 = pev_fuser2
const pev_time3 = pev_fuser3

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_think(ANGRA_CLASSNAME, "fw_Angra_Think")
	register_think(POISON_CLASSNAME, "fw_Poison_Think")
	
	g_Msg_ScreenShake = get_user_msgid("ScreenShake")
	g_MaxPlayers = get_maxplayers()
	
	register_clcmd("quake", "Angra_Do_Quake")
	register_clcmd("bite", "Angra_Do_Bite")
	register_clcmd("swing", "Angra_Do_Swing")
	register_clcmd("tentacle", "Angra_Do_Tentacle")
	register_clcmd("flying", "Angra_Do_FlyingUp")
	register_clcmd("land", "Angra_Do_LandingDown")
	register_clcmd("poison", "Angra_Do_Poison")
	register_clcmd("flypoison", "Angra_Do_FlyPoison")
	
	register_clcmd("set_health", "CMD_Health")
}

public CMD_Health(id)
{
	set_pev(id, pev_health, 150.0)
}

public plugin_natives()
{
	register_native("Create_Angra","Create_Boss",1)
}
public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, ANGRA_MODEL)
	
	engfunc(EngFunc_PrecacheSound, SOUND_APPEAR1)
	engfunc(EngFunc_PrecacheSound, SOUND_APPEAR3)	
	engfunc(EngFunc_PrecacheSound, SOUND_ATTACK_QUAKE)
	engfunc(EngFunc_PrecacheSound, SOUND_ATTACK_BITE)
	engfunc(EngFunc_PrecacheSound, SOUND_ATTACK_SWING)
	engfunc(EngFunc_PrecacheSound, SOUND_ATTACK_TENTACLE1)
	engfunc(EngFunc_PrecacheSound, SOUND_ATTACK_TENTACLE2)
	
	engfunc(EngFunc_PrecacheModel, TENTACLE_MODEL)
	engfunc(EngFunc_PrecacheModel, EARTHHOLE_MODEL_BEGIN)
	engfunc(EngFunc_PrecacheModel, EARTHHOLE_MODEL_END)
	
	engfunc(EngFunc_PrecacheSound, SOUND_FLYING_UP)
	engfunc(EngFunc_PrecacheSound, SOUND_FLYING)
	engfunc(EngFunc_PrecacheSound, SOUND_LANDED)
	
	engfunc(EngFunc_PrecacheSound, SOUND_DO_POISON)
	engfunc(EngFunc_PrecacheModel, POISON_SPR)
	for(new i = 0; i < sizeof(footstep); i++)
		precache_sound(footstep[i])
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")	
}

public Create_Boss(id, Float:HP)
{
	if(pev_valid(g_Angra_Ent))
		engfunc(EngFunc_RemoveEntity, g_Angra_Ent)
	
	static ent; ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(ent)) return -1
	
	g_Angra_Ent = ent
	ANGRA_HEALTH = HP
	
	static Float:StartOrigin[3]	
	pev(id, pev_origin, StartOrigin)
	set_pev(ent, pev_origin, StartOrigin)
	
	static Float:Angles[3]	
	pev(id, pev_angles, Angles)
	set_pev(ent, pev_angles, Angles)
	set_pev(ent, pev_v_angle, Angles)
	
	// Set Config
	entity_set_string(ent, EV_SZ_classname, ANGRA_CLASSNAME)
	entity_set_model(ent, ANGRA_MODEL)
		
	set_pev(ent, pev_gamestate, 1)
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_PUSHSTEP)

	// Set Size
	new Float:maxs[3] = {142.0, 102.0, 194.0}
	new Float:mins[3] = {-142.0, -102.0, -30.0}
	entity_set_size(ent, mins, maxs)
	
	// Set Life
	set_pev(ent, pev_takedamage, DAMAGE_YES)
	set_pev(ent, pev_health, HEALTH_OFFSET + ANGRA_HEALTH)
	
	// Set Config 2
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_state, ANGRA_STATE_APPEAR)	
	set_entity_anim(ent, ANGRA_ANIM_IDLE, 1)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	
	engfunc(EngFunc_DropToFloor, ent)
	return ent;
}

// ================= IDLE SCENE ===================
public fw_Angra_Think(ent)
{
	if(!pev_valid(ent)) return
	new owner; owner = pev(ent, pev_owner)
	if(pev(owner, pev_health) < HEALTH_OFFSET)
	{
		set_pev(owner, pev_takedamage, DAMAGE_NO)
		set_pev(ent, pev_takedamage, DAMAGE_NO)
		Angra_Die(ent)
		return
	}
	if(get_cvar_num("bot_stop")){
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		return;
	}	
	switch(pev(ent, pev_state))
	{
		case ANGRA_STATE_IDLE:
		{
			if(get_gametime() - 3.3 > pev(ent, pev_time))
			{
				set_entity_anim(ent, ANGRA_ANIM_IDLE, 0)
				
				set_pev(ent, pev_time, get_gametime())
			}
			if(get_gametime() - 1.0 > pev(ent, pev_time2))
			{
				set_pev(ent, pev_state, ANGRA_STATE_SEARCHING_ENEMY)
				set_pev(ent, pev_time2, get_gametime())
			}	
			
			// Set Next Think
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)			
		}
		case ANGRA_STATE_APPEAR:
		{
			set_entity_anim(ent, 0, 1)
			PlaySound(0, SOUND_APPEAR3)
			
			Make_PlayerShake(0)
			set_pev(ent, pev_state, ANGRA_STATE_IDLE)
			set_pev(ent, pev_nextthink, get_gametime() + 1.8)	
		}

		case ANGRA_STATE_SEARCHING_ENEMY:
		{
			static Victim;
			Victim = FindClosetEnemy(ent, 1)
			
			if(is_user_alive(Victim))
			{
				set_pev(ent, pev_enemy, Victim)
				set_pev(ent, pev_time, get_gametime())
				set_pev(ent, pev_state, ANGRA_STATE_CHASE_ENEMY)
			} else {
				set_pev(ent, pev_enemy, 0)
				set_pev(ent, pev_state, ANGRA_STATE_IDLE)
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case ANGRA_STATE_CHASE_ENEMY:
		{
			static Enemy; Enemy = pev(ent, pev_enemy)
			static Float:EnemyOrigin[3]
			pev(Enemy, pev_origin, EnemyOrigin)
			
			if(is_user_alive(Enemy))
			{
				if(entity_range(Enemy, ent) <= floatround(ANGRA_ATTACK_RANGE))
				{
					MM_Aim_To(ent, EnemyOrigin) 
					
					new ran = random_num(0, 12)					
					switch(ran)
					{
						case 0..4: Angra_Do_Bite(ent)
						case 5..9: Angra_Do_Swing(ent)
						case 10..11: Angra_Do_Quake(ent)
						case 12: Angra_Do_Tentacle(ent)
					}
				} else {
					if(pev(ent, pev_movetype) == MOVETYPE_PUSHSTEP)
					{
						static Float:OriginAhead[3]
						get_position(ent, 300.0, 0.0, 0.0, OriginAhead)
						
						MM_Aim_To(ent, EnemyOrigin) 
						hook_ent2(ent, OriginAhead, ANGRA_SPEED + 30.0)
						
						set_entity_anim2(ent, ANGRA_ANIM_WALK, 1.0)
						
						if(get_gametime() - 1.3 > pev(ent, pev_time3))
						{
							if(g_FootStep != 1) g_FootStep = 1
							else g_FootStep = 2
						
							PlaySound(0, footstep[g_FootStep == 1 ? 0 : 1])
							
							set_pev(ent, pev_time3, get_gametime())
						}
						
						if(get_gametime() - 4.0 > pev(ent, pev_time2))
						{
							new rand = random_num(0, 5)
							if(rand == 1) Angra_Do_Poison(ent)
							else if(rand == 3) Angra_Do_FlyingUp(ent)
							
							set_pev(ent, pev_time2, get_gametime())
						}
					} else {
						set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
					}
				}
			} else {
				set_pev(ent, pev_state, ANGRA_STATE_SEARCHING_ENEMY)
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
	}
}
// ================= QUAKE SCENE ===================
public Angra_Do_Quake(ent)
{
	if(!pev_valid(ent)) return
	if(pev(ent, pev_state)==ANGRA_STATE_SEARCHING_ENEMY || pev(ent, pev_state)==ANGRA_STATE_CHASE_ENEMY)
	{		
		set_pev(ent, pev_state, ANGRA_STATE_ATTACK_QUAKE)
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		
		set_task(0.1, "Do_Quake_Now", ent+TASK_DO_QUAKE)
	}
}

public Do_Quake_Now(ent)
{
	ent -= TASK_DO_QUAKE
	if(!pev_valid(ent)) return
	
	set_entity_anim(ent, ANGRA_ANIM_ATTACK_QUAKE, 1)
	PlaySound(0, SOUND_ATTACK_QUAKE)
	
	set_task(1.3, "Check_Target_Quake", ent+TASK_DO_QUAKE)
	set_task(4.5, "Angra_Done_Quake", ent+TASK_DO_QUAKE)
}

public Check_Target_Quake(ent)
{
	ent -= TASK_DO_QUAKE
	if(!pev_valid(ent)) return
	
	Make_PlayerShake(0)
	
	static Float:TargetOrigin[3], Float:VicOrigin[3]
	pev(ent, pev_origin, TargetOrigin)
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(TargetOrigin, VicOrigin) > QUAKE_DAMAGE_RADIUS)
			continue
		
		//Drop_PlayerWeapon(i)
		ExecuteHamB(Ham_TakeDamage, i, pev(g_Angra_Ent, pev_owner), pev(g_Angra_Ent, pev_owner), QUAKE_DAMAGE, DMG_BULLET)
		static Float:Vel[3]
		Vel[0] += random_float(-300.0, 300.0)
		Vel[1] += random_float(-300.0, 300.0)
		Vel[2] += random_float(300.0, 600.0)
		set_pev(i, pev_velocity, Vel)
	}	
}

public Drop_PlayerWeapon(id)
{
	static wpn, wpnname[32]
	
	if(!id)
	{
		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(!is_user_alive(i)) continue
			
			wpn = get_user_weapon(i)
			if(!(WPN_NOT_DROP & (1<<wpn)) && get_weaponname(wpn, wpnname, charsmax(wpnname)))
				engclient_cmd(i, "drop", wpnname)
		}
	} else {
		if(!is_user_alive(id)) return
		
		wpn = get_user_weapon(id)
		if(!(WPN_NOT_DROP & (1<<wpn)) && get_weaponname(wpn, wpnname, charsmax(wpnname)))
			engclient_cmd(id, "drop", wpnname)
	}
}

public Angra_Done_Quake(ent)
{
	ent -= TASK_DO_QUAKE
	if(!pev_valid(ent)) return
	
	remove_task(ent+TASK_DO_QUAKE)
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_state, ANGRA_STATE_SEARCHING_ENEMY)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

// ================= BITE SCENE ===================
public Angra_Do_Bite(ent)
{
	if(!pev_valid(ent)) return
	if(pev(ent, pev_state)==ANGRA_STATE_SEARCHING_ENEMY || pev(ent, pev_state)==ANGRA_STATE_CHASE_ENEMY)
	{		
		set_pev(ent, pev_state, ANGRA_STATE_ATTACK_BITE)
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		
		set_task(0.1, "Do_Bite_Now", ent+TASK_DO_BITE)
	}
}

public Do_Bite_Now(ent)
{
	ent -= TASK_DO_BITE
	if(!pev_valid(ent)) return
	
	set_entity_anim(ent, ANGRA_ANIM_ATTACK_BITE, 1)
	PlaySound(0, SOUND_ATTACK_BITE)
	
	set_task(0.4, "Check_Target_BiteLeft", ent+TASK_DO_BITE)
	set_task(0.9, "Check_Target_BiteRight", ent+TASK_DO_BITE)
	
	set_task(2.6, "Angra_Done_Bite", ent+TASK_DO_BITE)
}

public Check_Target_BiteLeft(ent)
{
	ent -= TASK_DO_BITE
	if(!pev_valid(ent)) return
	
	static Float:TargetOrigin[3], Float:VicOrigin[3]
	get_position(ent, 125.0, -40.0, 0.0, TargetOrigin)
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(TargetOrigin, VicOrigin) > 200.0)
			continue
		
		ExecuteHamB(Ham_TakeDamage, i, pev(g_Angra_Ent, pev_owner), pev(g_Angra_Ent, pev_owner), BITE_DAMAGE, DMG_BULLET)
		static Float:Vel[3]
		Vel[0] += random_float(-300.0, 300.0)
		Vel[1] += random_float(-300.0, 300.0)
		Vel[2] += random_float(300.0, 600.0)
		set_pev(i, pev_velocity, Vel)
		Make_PlayerShake(i)
	}
}

public Check_Target_BiteRight(ent)
{
	ent -= TASK_DO_BITE
	if(!pev_valid(ent)) return
	
	static Float:TargetOrigin[3], Float:VicOrigin[3]
	get_position(ent, 200.0, 40.0, 0.0, TargetOrigin)	
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(TargetOrigin, VicOrigin) > 200.0)
			continue
		
		ExecuteHamB(Ham_TakeDamage, i, pev(g_Angra_Ent, pev_owner), pev(g_Angra_Ent, pev_owner), BITE_DAMAGE, DMG_BULLET)
		static Float:Vel[3]
		Vel[0] += random_float(-300.0, 300.0)
		Vel[1] += random_float(-300.0, 300.0)
		Vel[2] += random_float(300.0, 600.0)
		set_pev(i, pev_velocity, Vel)
		Make_PlayerShake(i)
	}	
}

public Angra_Done_Bite(ent)
{
	ent -= TASK_DO_BITE
	if(!pev_valid(ent)) return
	
	remove_task(ent+TASK_DO_BITE)
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_state, ANGRA_STATE_SEARCHING_ENEMY)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

// ================= SWING SCENE ===================
public Angra_Do_Swing(ent)
{
	if(!pev_valid(ent)) return
	if(pev(ent, pev_state)==ANGRA_STATE_SEARCHING_ENEMY || pev(ent, pev_state)==ANGRA_STATE_CHASE_ENEMY)
	{		
		set_pev(ent, pev_state, ANGRA_STATE_ATTACK_SWING)
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		
		set_task(0.1, "Do_Swing_Now", ent+TASK_DO_SWING)
	}
}

public Do_Swing_Now(ent)
{
	ent -= TASK_DO_SWING
	if(!pev_valid(ent)) return
	
	set_entity_anim(ent, ANGRA_ANIM_ATTACK_SWING, 1)
	
	set_task(0.75, "Set_Swing_Sound", ent+TASK_DO_SWING)
	set_task(1.0, "Check_Target_Swing", ent+TASK_DO_SWING)
	set_task(2.3, "Angra_Done_Swing", ent+TASK_DO_SWING)
}

public Set_Swing_Sound(ent)
{
	ent -= TASK_DO_SWING
	if(!pev_valid(ent)) return
	
	PlaySound(0, SOUND_ATTACK_SWING)
}

public Check_Target_Swing(ent)
{
	ent -= TASK_DO_SWING
	if(!pev_valid(ent)) return
	
	static Float:TargetOrigin[3], Float:VicOrigin[3]
	get_position(ent, 200.0, 20.0, 0.0, TargetOrigin)
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(TargetOrigin, VicOrigin) > 300.0)
			continue
		
		ExecuteHamB(Ham_TakeDamage, i, pev(g_Angra_Ent, pev_owner), pev(g_Angra_Ent, pev_owner), SWING_DAMAGE, DMG_BULLET)
		static Float:Vel[3]
		Vel[0] += random_float(-300.0, 300.0)
		Vel[1] += random_float(-300.0, 300.0)
		Vel[2] += random_float(300.0, 600.0)
		set_pev(i, pev_velocity, Vel)
		Make_PlayerShake(i)
	}
}

public Angra_Done_Swing(ent)
{
	ent -= TASK_DO_SWING
	if(!pev_valid(ent)) return
	
	remove_task(ent+TASK_DO_SWING)
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_state, ANGRA_STATE_SEARCHING_ENEMY)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

// ================= TENTACLE SCENE ===================
public Angra_Do_Tentacle(ent)
{
	if(!pev_valid(ent)) return
	if(pev(ent, pev_state)==ANGRA_STATE_SEARCHING_ENEMY || pev(ent, pev_state)==ANGRA_STATE_CHASE_ENEMY)
	{		
		set_pev(ent, pev_movetype, MOVETYPE_NONE)	
		set_task(0.1, "Do_Tentacle_Now", ent+TASK_DO_TENTACLE)
	}
}

public Do_Tentacle_Now(ent)
{
	ent -= TASK_DO_TENTACLE
	if(!pev_valid(ent)) return
	
	if(random_num(0,1) == 1) // Tentacle 1
	{
		set_pev(ent, pev_state, ANGRA_STATE_ATTACK_TENTACLE1)
		set_entity_anim(ent, ANGRA_ANIM_ATTACK_TENTACLE1, 1)
		
		set_task(1.0, "Do_Tentacle_Sound", ent+TASK_DO_TENTACLE_SOUND)
		set_task(1.8, "Angra_Tentacle", ent+TASK_DO_TENTACLE)
		set_task(4.6, "Angra_Tentacle", ent+TASK_DO_TENTACLE)
		set_task(7.2, "Angra_Done_Tentacle", ent+TASK_DO_TENTACLE)
	} else { // Tentacle 2
		set_pev(ent, pev_state, ANGRA_STATE_ATTACK_TENTACLE2)
		set_entity_anim(ent, ANGRA_ANIM_ATTACK_TENTACLE2, 1)
		
		set_task(1.0, "Do_Tentacle_Sound", ent+TASK_DO_TENTACLE_SOUND)
		set_task(1.7, "Angra_Tentacle", ent+TASK_DO_TENTACLE)
		set_task(2.8, "Angra_Tentacle", ent+TASK_DO_TENTACLE)
		set_task(3.8, "Angra_Tentacle", ent+TASK_DO_TENTACLE)
		set_task(4.5, "Angra_Tentacle", ent+TASK_DO_TENTACLE)
		set_task(10.0, "Angra_Done_Tentacle", ent+TASK_DO_TENTACLE)
	}
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public Do_Tentacle_Sound(ent)
{
	ent -= TASK_DO_TENTACLE_SOUND
	if(!pev_valid(ent)) return	
	
	PlaySound(0, pev(ent, pev_state) == ANGRA_STATE_ATTACK_TENTACLE1 ? SOUND_ATTACK_TENTACLE1 : SOUND_ATTACK_TENTACLE2)
}

public Angra_Tentacle(ent)
{
	ent -= TASK_DO_TENTACLE
	if(!pev_valid(ent))
		return
		
	static Float:Origin[3], Float:StartOrigin[3], Float:Angles[3]
	
	entity_get_vector(ent, EV_VEC_origin, Origin)
	entity_get_vector(ent, EV_VEC_v_angle, Angles)
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(i==pev(ent, pev_owner))
			continue
			
		pev(i, pev_origin, StartOrigin)		
		StartOrigin[2] = Origin[2]		
		Create_Tentacle(ent, StartOrigin, Angles)
	}	
}
public Create_Tentacle(ent, Float:Origin[3], Float:Angles[3])
{
	new Float:num, ent = create_entity("info_target")

	Origin[2] += 5.0
	
	entity_set_origin(ent, Origin)
	entity_set_vector(ent, EV_VEC_v_angle, Angles)
	
	entity_set_string(ent,EV_SZ_classname, "tentacle")
	entity_set_model(ent, EARTHHOLE_MODEL_BEGIN)
	entity_set_int(ent, EV_INT_solid, SOLID_NOT)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_owner, pev(ent, pev_owner))
	
	new Float:maxs[3] = {1.0,1.0,1.0}
	new Float:mins[3] = {-1.0,-1.0,-1.0}
	entity_set_size(ent, mins, maxs)
	
	set_entity_anim(ent, 0, 1)	
	
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 150.0)		
	
	num = random_float(0.4,1.0)
	set_task(num, "Tentacle_Change", ent)
	set_task(num+0.1, "Tentacle_Check", ent)
}

public Tentacle_Change(ent)
{
	if(!pev_valid(ent))
		return	
		
	entity_set_model(ent, TENTACLE_MODEL)	
	entity_set_string(ent,EV_SZ_classname, "tentacle2")	
	new Float:maxs[3] = {26.0,26.0,36.0}
	new Float:mins[3] = {-26.0,-26.0,-36.0}
	entity_set_size(ent, mins, maxs)		
	set_entity_anim(ent, 0, 1)	
	set_pev(ent, pev_rendermode, kRenderNormal)
	set_pev(ent, pev_renderamt, 255.0)		
	
	set_task(1.0, "Remove_Tentacle", ent)
}
public Remove_Tentacle(ent)
{
	if(!pev_valid(ent))
		return	
	remove_entity(ent)
}
public Tentacle_Check(ent)
{
	if(!pev_valid(ent))
		return	
		
	static Float:Origin[3],Float:POrigin[3];
	get_position(ent, 0.0, 0.0, 20.0, Origin)
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		pev(i, pev_origin, POrigin)
		if(get_distance_f(Origin, POrigin) > 50.0)
			continue
		if(i==pev(ent, pev_owner))
			continue
			
		static Float:Velocity[3]
		Velocity[0] = random_float(-200.0, 200.0)
		Velocity[1] = random_float(-200.0, 200.0)
		Velocity[2] = random_float(400.0, 600.0)
		set_pev(i, pev_velocity, Velocity)
		ExecuteHamB(Ham_TakeDamage, i, pev(g_Angra_Ent, pev_owner), pev(g_Angra_Ent, pev_owner), TENTACLE_DAMAGE, DMG_BULLET)
		Make_PlayerShake(i)
	}
}

public Angra_Done_Tentacle(ent)
{
	ent -= TASK_DO_TENTACLE
	if(!pev_valid(ent)) return
	
	remove_task(ent+TASK_DO_TENTACLE)
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_state, ANGRA_STATE_SEARCHING_ENEMY)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

// ================= POISON SCENE ===================
public Angra_Do_Poison(ent)
{
	if(!pev_valid(ent)) return
	if(pev(ent, pev_state)==ANGRA_STATE_SEARCHING_ENEMY || pev(ent, pev_state)==ANGRA_STATE_CHASE_ENEMY)
	{		
		set_pev(ent, pev_movetype, MOVETYPE_NONE)	
		set_task(0.05, "Checking_Poison", ent+TASK_DO_POISON)
	}
}

public Checking_Poison(ent)
{
	ent -= TASK_DO_POISON
	if(!pev_valid(ent)) return
	
	static Float:EnemyOrigin[3]
	pev(pev(ent, pev_enemy), pev_origin, EnemyOrigin)
	MM_Aim_To(ent, EnemyOrigin) 
	
	if(random_num(0,1) == 1) // Poison 1
	{
		set_pev(ent, pev_state, ANGRA_STATE_ATTACK_LAND_POISON1)
		set_entity_anim(ent, ANGRA_ANIM_ATTACK_POISON1, 1)
		
		set_task(0.1, "Set_Poison_Sound", ent+(TASK_DO_POISON+2))
		set_task(2.7, "Angra_Create_Poison", ent+TASK_DO_POISON)
		set_task(4.25, "Angra_Stop_Poison", ent+(TASK_DO_POISON+3))
		set_task(4.7, "Angra_Done_Poison", ent+(TASK_DO_POISON+1))
	} else { // Poison 2
		set_pev(ent, pev_state, ANGRA_STATE_ATTACK_LAND_POISON2)
		set_entity_anim(ent, ANGRA_ANIM_ATTACK_POISON1, 1)
		set_task(0.1, "Set_Poison_Sound", ent+(TASK_DO_POISON+2))
		set_task(3.0, "Angra_Create_Poison", ent+TASK_DO_POISON)
		set_task(4.25, "Angra_Stop_Poison", ent+(TASK_DO_POISON+3))
		set_task(5.1, "Angra_Done_Poison", ent+(TASK_DO_POISON+1))
	}	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}
public Set_Poison_Sound(ent)
{
	ent -= (TASK_DO_POISON+2)
	
	if(!pev_valid(ent)) return
	PlaySound(0, SOUND_DO_POISON)
}

public Angra_Create_Poison(ent)
{
	ent -= TASK_DO_POISON
	if(!pev_valid(ent)) return
	
	set_task(0.1, "Create_Poison", ent+TASK_DO_THROWING_POISON, _, _, "b")
}

public Create_Poison(ent)
{
	ent -= TASK_DO_THROWING_POISON
	if(!pev_valid(ent)) return
	
	static Float:EnemyOrigin[3]
	pev(pev(ent, pev_enemy), pev_origin, EnemyOrigin)
	MM_Aim_To(ent, EnemyOrigin) 
	
	static Float:Origin[3], Float:Angles[3], Float:Target[3]
	
	get_position(ent, 150.0, 0.0, 100.0, Origin)
	get_position(ent, 1000.0, 0.0, 0.0, Target)
	pev(ent, pev_angles, Angles)
	
	static ent; ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))

	set_pev(ent, pev_origin, Origin)
	set_pev(ent, pev_angles, Angles)	
	
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 250.0)
	set_pev(ent, pev_scale, 0.5)
	set_pev(ent, pev_nextthink, halflife_time() + 0.05)
	
	set_pev(ent, pev_classname, POISON_CLASSNAME)
	set_pev(ent, pev_owner, pev(ent, pev_owner))
	
	engfunc(EngFunc_SetModel, ent, POISON_SPR)
	set_pev(ent, pev_mins, Float:{-5.0, -5.0, -10.0})
	set_pev(ent, pev_maxs, Float:{5.0, 5.0, 10.0})
	set_pev(ent, pev_fuser1, get_gametime() + 1.5)
	set_pev(ent, pev_gravity, 0.1)
	
	hook_ent2(ent, Target, 650.0)
	
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_framerate, 1.0)
	
	set_pev(ent, pev_solid, SOLID_TRIGGER)	
}
public fw_Poison_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
	
	new Float:fFrame, Float:fNextThink, Float:fScale
	pev(iEnt, pev_frame, fFrame)
	pev(iEnt, pev_scale, fScale)
	
	// effect exp
	new iMoveType = pev(iEnt, pev_movetype)
	if (iMoveType == MOVETYPE_NONE)
	{
		fNextThink = 0.01
		fFrame += 0.5
		
		if (fFrame > 39.0)
		{
			//engfunc(EngFunc_RemoveEntity, iEnt)
			//return
		}
	}
	// effect normal
	else
	{
		fNextThink = 0.05
		
		fFrame += 0.5
		fScale += 0.25
		
		fFrame = floatmin(39.0, fFrame)
		fScale = floatmin(4.0, fScale)
		
		if (fFrame > 39.0)
		{
			engfunc(EngFunc_RemoveEntity, iEnt)
			return
		}
	}
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue

		if(entity_range(i, iEnt) < 100.0)
			ExecuteHamB(Ham_TakeDamage, i, pev(g_Angra_Ent, pev_owner), pev(g_Angra_Ent, pev_owner), POISON_DAMAGE, DMG_BULLET)
	}
	
	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_scale, fScale)
	set_pev(iEnt, pev_nextthink, halflife_time() + fNextThink)
	
	// time remove
	new Float:fTimeRemove
	pev(iEnt, pev_fuser1, fTimeRemove)
	if (get_gametime() >= fTimeRemove)
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return;
	}	
}
public Angra_Stop_Poison(ent)
{
	ent -= (TASK_DO_POISON+3)
	if(!pev_valid(ent)) return
	
	remove_task(ent+TASK_DO_THROWING_POISON)
}

public Angra_Done_Poison(ent)
{
	ent -= (TASK_DO_POISON+1)
	if(!pev_valid(ent)) return

	remove_task(ent+TASK_DO_POISON)
	remove_task(ent+TASK_DO_THROWING_POISON)
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_state, ANGRA_STATE_SEARCHING_ENEMY)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

// ================= FLY SCENE ===================
public Angra_Do_FlyingUp(ent)
{
	if(!pev_valid(ent)) return
	if(pev(ent, pev_state)==ANGRA_STATE_SEARCHING_ENEMY || pev(ent, pev_state)==ANGRA_STATE_CHASE_ENEMY)
	{		
		//set_pev(ent, pev_movetype, MOVETYPE_NONE)
		set_pev(ent, pev_state, ANGRA_STATE_FLYING_UP)
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
		
		set_pev(ent, pev_enemy, FindFarestEnemy(ent,0))
		set_task(0.1, "Walk_To", ent+(TASK_DO_FLYING_UP+1), _, _, "b")
		set_task(0.5, "CheckAround", ent+(TASK_DO_FLYING_UP+1), _, _, "b")
		set_task(2.0, "Start_FlyingUp", ent+TASK_DO_FLYING_UP)
	}
}
public Walk_To(ent)
{
	ent -= (TASK_DO_FLYING_UP+1)
	if(!pev_valid(ent)) return
	
	new Float:EnemyOrigin[3]
	pev(pev(ent, pev_enemy), pev_origin, EnemyOrigin)
	MM_Aim_To(ent, EnemyOrigin)
	
	static Float:OriginAhead[3]
	get_position(ent, 500.0, 0.0, 0.0, OriginAhead)
	hook_ent2(ent, OriginAhead, ANGRA_SPEED + 30.0)
	
	set_entity_anim2(ent, ANGRA_ANIM_WALK, 1.0)
	if(get_gametime() - 1.3 > pev(ent, pev_time3))
	{
		if(g_FootStep != 1) g_FootStep = 1
		else g_FootStep = 2
	
		PlaySound(0, footstep[g_FootStep == 1 ? 0 : 1])
		
		set_pev(ent, pev_time3, get_gametime())
	}
}
public Start_FlyingUp(ent)
{
	ent -= TASK_DO_FLYING_UP
	if(!pev_valid(ent)) return
	
	remove_task(ent+(TASK_DO_FLYING_UP+1))
	
	set_entity_anim(ent, ANGRA_ANIM_FLY1, 1)
	PlaySound(0, SOUND_FLYING_UP)
	
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	//set_pev(ent, pev_solid, SOLID_TRIGGER)
	
	set_task(1.7, "Set_FlyUp", ent+(TASK_DO_FLYING_UP+1))
	set_task(2.5, "Set_FlyState", ent+TASK_DO_FLYING_UP)
}

public CheckAround(ent)
{
	ent -= (TASK_DO_FLYING_UP+1)
	if(!pev_valid(ent)) return
	
	new Float:Origin[3],Float:VicOrigin[3];
	get_position(ent, 0.0,0.0, 0.0, Origin)
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(i==pev(ent,pev_owner))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(Origin, VicOrigin) > 200.0)
			continue
		
		ExecuteHamB(Ham_TakeDamage, i, pev(g_Angra_Ent, pev_owner), pev(g_Angra_Ent, pev_owner), 800.0, DMG_BULLET)
	}
}

public Set_FlyUp(ent)
{
	ent -= (TASK_DO_FLYING_UP+1)
	if(!pev_valid(ent)) return
	
	static Float:Vec[3]
	Vec[2] = 700.0
	set_pev(ent, pev_velocity, Vec)
}

public Set_FlyState(ent)
{
	ent -= TASK_DO_FLYING_UP
	if(!pev_valid(ent)) return
	
	remove_task(ent+(TASK_DO_FLYING_UP+1))
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	
	new Float:maxs[3] = {162.0, 122.0, 750.0}
	new Float:mins[3] = {-162.0, -122.0, -35.0}
	entity_set_size(ent, mins, maxs)
	
	static Float:EnemyOrigin[3]
	pev(pev(ent, pev_enemy), pev_origin, EnemyOrigin)
	MM_Aim_To(ent, EnemyOrigin) 
	
	switch(random_num(0,1))
	{
		case 0:Angra_Do_FlyPoison(ent)
		case 1:Angra_Do_FlyingPoison(ent)
	}
}

// ================= LANDING DOWN SCENE ===================
public Angra_Do_LandingDown(ent)
{
	if(!pev_valid(ent)) return
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)	
	set_pev(ent, pev_state, ANGRA_STATE_LANDING_DOWN)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	
	set_task(0.1, "Start_LandingDown", ent+TASK_DO_LANDING_DOWN)	
}

public Start_LandingDown(ent)
{
	ent -= TASK_DO_LANDING_DOWN
	if(!pev_valid(ent)) return
	
	set_entity_anim(ent, ANGRA_ANIM_LAND1, 1)
	set_pev(ent, pev_solid, SOLID_BBOX)
	
	// Set Size
	new Float:maxs[3] = {162.0, 122.0, 194.0}
	new Float:mins[3] = {-162.0, -122.0, -30.0}
	entity_set_size(ent, mins, maxs)		
	
	set_task(0.7, "Set_Landing_Down", ent+TASK_DO_LANDING_DOWN)
	set_task(0.1, "CheckBelow", ent+TASK_DO_LANDING_DOWN, _, _, "b")
}

public CheckBelow(ent)
{
	ent -= TASK_DO_LANDING_DOWN
	if(!pev_valid(ent)) return
	
	new Float:Origin[3],Float:VicOrigin[3];
	get_position(ent, 0.0,0.0, -200.0, Origin)
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(i==pev(ent,pev_owner))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(Origin, VicOrigin) > 200.0)
			continue
		
		ExecuteHamB(Ham_TakeDamage, i, pev(g_Angra_Ent, pev_owner), pev(g_Angra_Ent, pev_owner), 2000.0, DMG_BULLET)
	}
}

public Set_Landing_Down(ent)
{
	ent -= TASK_DO_LANDING_DOWN
	if(!pev_valid(ent)) return
	
	set_entity_anim(ent, ANGRA_ANIM_LAND2, 1)
	
	/*new Float:Vel[3]
	Vel[2]-=500.0
	set_pev(ent, pev_velocity, Vel)*/
	engfunc(EngFunc_DropToFloor, ent)
	set_task(0.1, "Falling_Check", ent+TASK_DO_LANDING_DOWN, _, _, "b")
}
public Falling_Check(ent)
{
	ent -= TASK_DO_LANDING_DOWN
	if(!pev_valid(ent)) return
	
	if(pev(ent, pev_flags) & FL_ONGROUND)
	{		
		remove_task(ent+TASK_DO_LANDING_DOWN)
		
		PlaySound(0, SOUND_LANDED)
		
		Make_PlayerShake(0)
		//Drop_PlayerWeapon(0)
		Angra_Tentacle(ent+TASK_DO_TENTACLE)
		
		engfunc(EngFunc_DropToFloor, ent)
		
		set_entity_anim(ent, ANGRA_ANIM_LAND3, 1)	
		set_task(5.4, "Angra_Done_Land", ent+TASK_DO_LANDING_DOWN)			
	}else engfunc(EngFunc_DropToFloor, ent)
}
public Angra_Done_Land(ent)
{
	ent -= TASK_DO_LANDING_DOWN
	if(!pev_valid(ent)) return
	
	remove_task(ent+TASK_DO_LANDING_DOWN)
	//engfunc(EngFunc_DropToFloor, ent)
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_state, ANGRA_STATE_SEARCHING_ENEMY)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

// ================= FLYING POISON SCENE ===================

public Angra_Do_FlyingPoison(ent)
{
	if(!pev_valid(ent)) return
		
	//set_pev(ent, pev_movetype, MOVETYPE_NONE)	
	set_task(0.05, "Checking_FlyingPoison", ent+TASK_DO_POISON)	
}
public Checking_FlyingPoison(ent)
{
	ent -= TASK_DO_POISON
	if(!pev_valid(ent)) return
	
	set_entity_anim(ent, ANGRA_ANIM_FLY2_2, 1)
	
	set_pev(ent, pev_state, ANGRA_STATE_ATTACK_FLY_POISON1)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	
	switch(random_num(0,1))
	{
		case 0:
		{
			set_task(0.5, "Angra_Create_FlyingPoison", ent+TASK_DO_POISON)
			set_task(3.0, "Angra_Stop_FlyingPoison", ent+(TASK_DO_POISON+3))	
			set_task(3.1, "Angra_Done_FlyingPoison", ent+(TASK_DO_POISON+1))			
		}
		case 1:
		{			
			set_task(0.5, "Angra_Create_FlyingPoison", ent+TASK_DO_POISON)			
			set_task(3.0, "Angra_Stop_FlyingPoison", ent+(TASK_DO_POISON+3))
			
			set_task(3.1, "Angra_Create_FlyingPoison2", ent+TASK_DO_POISON)			
			set_task(5.4, "Angra_Stop_FlyingPoison", ent+(TASK_DO_POISON+3))
			
			set_task(5.5, "Angra_Done_FlyingPoison", ent+(TASK_DO_POISON+1))
		}
	}
}

public Angra_Stop_FlyingPoison(ent)
{
	ent -= (TASK_DO_POISON+3)
	if(!pev_valid(ent)) return
	
	remove_task(ent+TASK_DO_THROWING_POISON)
}
public Angra_Create_FlyingPoison(ent)
{
	ent -= TASK_DO_POISON
	if(!pev_valid(ent)) return
	
	set_task(0.1, "Create_FlyingPoison", ent+TASK_DO_THROWING_POISON, _, _, "b")
}
public Angra_Create_FlyingPoison2(ent)
{
	ent -= TASK_DO_POISON
	if(!pev_valid(ent)) return
	
	set_pev(ent, pev_enemy, FindFarestEnemy(ent,0))
	new Float:EnemyOrigin[3]
	pev(pev(ent, pev_enemy), pev_origin, EnemyOrigin)
	MM_Aim_To(ent, EnemyOrigin)
	
	set_task(0.1, "Create_FlyingPoison", ent+TASK_DO_THROWING_POISON, _, _, "b")
}
public Create_FlyingPoison(ent)
{
	ent -= TASK_DO_THROWING_POISON
	if(!pev_valid(ent)) return
	
	PlaySound(0, SOUND_FLYING)
	
	static Float:Target[3]
	get_position(ent, 1000.0, 0.0, 0.0, Target)	
	hook_ent2(ent, Target, 500.0)	
	
	static Float:Origin[3], Float:Angles[3]
	
	get_position(ent, 150.0, 0.0, 280.0, Origin)
	get_position(ent, 150.0, 0.0, 0.0, Target)
	pev(ent, pev_angles, Angles)	
	
	static ent; ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	
	set_pev(ent, pev_origin, Origin)
	set_pev(ent, pev_angles, Angles)	
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 250.0)
	set_pev(ent, pev_scale, 0.5)
	set_pev(ent, pev_nextthink, halflife_time() + 0.05)
	
	set_pev(ent, pev_classname, POISON_CLASSNAME)
	set_pev(ent, pev_owner, pev(ent, pev_owner))
	engfunc(EngFunc_SetModel, ent, POISON_SPR)
	set_pev(ent, pev_mins, Float:{-5.0, -5.0, -10.0})
	set_pev(ent, pev_maxs, Float:{5.0, 5.0, 10.0})
	set_pev(ent, pev_fuser1, get_gametime() + 2.5)
	set_pev(ent, pev_gravity, 0.1)
	
	hook_ent2(ent, Target, 800.0)
	
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_framerate, 1.0)
	
	set_pev(ent, pev_solid, SOLID_TRIGGER)
}
public Angra_Done_FlyingPoison(ent)
{
	ent -= (TASK_DO_POISON+1)
	if(!pev_valid(ent)) return

	remove_task(ent+TASK_DO_POISON)
	remove_task(ent+TASK_DO_THROWING_POISON)
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	
	Angra_Do_LandingDown(ent)
}
// ================= FLYPOISON SCENE ===================
public Angra_Do_FlyPoison(ent)
{
	if(!pev_valid(ent)) return
		
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_task(0.05, "Checking_Poison2", ent+TASK_DO_POISON)	
}

public Checking_Poison2(ent)
{
	ent -= TASK_DO_POISON
	if(!pev_valid(ent)) return
	
	set_pev(ent, pev_state, ANGRA_STATE_ATTACK_FLY_POISON1)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	set_entity_anim(ent, ANGRA_ANIM_ATTACK_FLY1_POISON1, 1)
	
	set_task(1.0, "Angra_Create_Poison1_2", ent+TASK_DO_POISON)
	set_task(2.3, "Angra_Stop_Poison_2", ent+(TASK_DO_POISON+3))
	set_task(2.4, "Angra_Done_Poison2", ent+(TASK_DO_POISON+1))
}

public Angra_Create_Poison1_2(ent)
{
	ent -= TASK_DO_POISON
	if(!pev_valid(ent)) return
	
	set_task(0.1, "Create_Poison1_2", ent+TASK_DO_THROWING_POISON, _, _, "b")
}

public Angra_Stop_Poison_2(ent)
{
	ent -= (TASK_DO_POISON+3)
	if(!pev_valid(ent)) return
	
	remove_task(ent+TASK_DO_THROWING_POISON)
}

public Create_Poison1_2(ent)
{
	ent -= TASK_DO_THROWING_POISON
	if(!pev_valid(ent)) return
	
	PlaySound(0, SOUND_FLYING)
	
	static Float:EnemyOrigin[3]
	pev(pev(ent, pev_enemy), pev_origin, EnemyOrigin)
	MM_Aim_To(ent, EnemyOrigin) 
	
	static Float:Origin[3], Float:Angles[3], Float:Target[3]
	
	get_position(ent, 150.0, 0.0, 250.0, Origin)
	get_position(ent, 1000.0, 0.0, -500.0, Target)
	
	pev(ent, pev_angles, Angles)
	
	static ent; ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))

	set_pev(ent, pev_origin, Origin)
	set_pev(ent, pev_angles, Angles)	
	
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 250.0)
	set_pev(ent, pev_scale, 0.5)
	set_pev(ent, pev_nextthink, halflife_time() + 0.05)
	
	set_pev(ent, pev_classname, POISON_CLASSNAME)
	set_pev(ent, pev_owner, pev(ent, pev_owner))
	engfunc(EngFunc_SetModel, ent, POISON_SPR)
	set_pev(ent, pev_mins, Float:{-5.0, -5.0, -10.0})
	set_pev(ent, pev_maxs, Float:{5.0, 5.0, 10.0})
	set_pev(ent, pev_fuser1, get_gametime() + 2.5)
	set_pev(ent, pev_gravity, 0.1)
	
	hook_ent2(ent, Target, 800.0)
	
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_framerate, 1.0)
	
	set_pev(ent, pev_solid, SOLID_TRIGGER)		
}

public Angra_Done_Poison2(ent)
{
	ent -= (TASK_DO_POISON+1)
	if(!pev_valid(ent)) return

	remove_task(ent+TASK_DO_POISON)
	remove_task(ent+TASK_DO_THROWING_POISON)
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	
	Angra_Do_LandingDown(ent)
}

// ================= DIE SCENE ===================
public Angra_Die(ent)
{

}

// ================= STOCK ===================
public Make_PlayerShake(id)
{
	if(!id) 
	{
		message_begin(MSG_BROADCAST, g_Msg_ScreenShake)
		write_short(8<<12)
		write_short(1<<12)
		write_short(4<<12)
		message_end()
	} else {
		if(!is_user_connected(id))
			return
			
		message_begin(MSG_BROADCAST, g_Msg_ScreenShake, _, id)
		write_short(8<<12)
		write_short(1<<12)
		write_short(4<<12)
		message_end()
	}
}
stock set_entity_anim(ent, anim, reset_frame)
{
	if(!pev_valid(ent)) return
	
	set_pev(ent, pev_animtime, get_gametime())
	set_pev(ent, pev_framerate, 1.0)
	if(reset_frame) set_pev(ent, pev_frame, 0.0)
	
	set_pev(ent, pev_sequence, anim)	
}

stock set_entity_anim2(ent, anim, Float:framerate)
{
	if(!pev_valid(ent))
		return

	set_pev(ent, pev_framerate, framerate)
	set_pev(ent, pev_sequence, anim)
}
public MM_Aim_To(ent, Float:Origin[3]) 
{
	if(!pev_valid(ent))	
		return
		
	static Float:Vec[3], Float:Angles[3]
	pev(ent, pev_origin, Vec)
	
	Vec[0] = Origin[0] - Vec[0]
	Vec[1] = Origin[1] - Vec[1]
	Vec[2] = Origin[2] - Vec[2]
	engfunc(EngFunc_VecToAngles, Vec, Angles)
	Angles[0] = Angles[2] = 0.0 
	
	set_pev(ent, pev_angles, Angles)
	set_pev(ent, pev_v_angle, Angles)
}
public FindClosetEnemy(ent, can_see)
{
	new Float:maxdistance = 4980.0
	new indexid = 0	
	new Float:current_dis = maxdistance
	
	static owner,Float:EntOrigin[3]
	pev(ent, pev_origin, EntOrigin)
	owner = pev(ent, pev_owner)
	
	for(new i = 1 ;i <= g_MaxPlayers; i++)
	{
		if(i==owner) continue
		if(can_see)
		{
			if(is_user_alive(i) && can_see_fm(ent, i) && entity_range(ent, i) < current_dis)
			{
				current_dis = entity_range(ent, i)
				indexid = i
			}
		} else {
			if(is_user_alive(i) && entity_range(ent, i) < current_dis)
			{
				current_dis = entity_range(ent, i)
				indexid = i
			}			
		}
	}	
	
	return indexid
}

public FindFarestEnemy(ent, can_see)
{
	new indexid = 0	
	new Float:current_dis = 0.0
	
	static owner,Float:EntOrigin[3]
	pev(ent, pev_origin, EntOrigin)
	owner = pev(ent, pev_owner)
	
	for(new i = 1 ;i <= g_MaxPlayers; i++)
	{
		if(i==owner) continue
		if(can_see)
		{
			if(is_user_alive(i) && can_see_fm(ent, i) && entity_range(ent, i) > current_dis)
			{
				current_dis = entity_range(ent, i)
				indexid = i
			}
		} else {
			if(is_user_alive(i) && entity_range(ent, i) > current_dis)
			{
				current_dis = entity_range(ent, i)
				indexid = i
			}			
		}
	}	
	
	return indexid
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed)
{
	if(!pev_valid(ent))
		return
	
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(ent, pev_origin, EntOrigin)
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / speed
		
	if(get_distance_f(VicOrigin, EntOrigin) > 65.0)
	{
		fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time
	} else {
		fl_Velocity[0] = fl_Velocity[1] = fl_Velocity[2] = 0.0
	}
	
	set_pev(ent, pev_velocity, fl_Velocity)
}
public bool:can_see_fm(entindex1, entindex2)
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
stock create_blood(const Float:origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(248)
	write_byte(random_num(5,10))
	message_end()
}
stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}

stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	if(!pev_valid(ent)) return
	
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	//pev(ent, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_angles, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
