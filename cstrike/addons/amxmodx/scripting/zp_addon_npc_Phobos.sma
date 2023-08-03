#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN "[CSO] Fallen Titan"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define PHOBOS_MODEL "models/zombie_plague/boss/zbs_bossl_big00.mdl"
#define PHOBOS_MODEL2 "models/zombie_plague/boss/zbs_bossl_big01.mdl"

#define PHOBOS_CLASSNAME "NPC_PHOBOS"

new const Phobos_Sound[][] = 
{
	"zombie_plague/boss/boss_footstep_1.wav",
	"zombie_plague/boss/boss_footstep_2.wav",	//1
	"zombie_plague/boss/phobos/boss_death.wav",		//2
	"zombie_plague/boss/phobos/boss_dash.wav",		//3		
	"zombie_plague/boss/phobos/boss_swing.wav",		//4
	"zombie_plague/boss/phobos/boss_shokwave.wav",	//5
	"zombie_plague/boss/phobos/boss_voice_1.wav"		//6
}

#define PHOBOS_SPEED 250.0
#define HEALTH_OFFSET 50000.0
#define PHOBOS_ATTACK_RANGE 180.0

#define SWING_RADIUS 200.0
#define SWING_DAMAGE random_float(650.0, 750.0)
#define SHOCKWAVE_RADIUS 320.0
#define SHOCKWAVE_DAMAGE random_float(500.0, 650.0)
#define DASH_DAMAGE random_float(250.0, 350.0)

enum
{
	PHOBOS_ANIM_DUMMY = 0,
	PHOBOS_ANIM_DEATH,
	PHOBOS_ANIM_IDLE,
	PHOBOS_ANIM_WALK,
	PHOBOS_ANIM_RUN,
	PHOBOS_ANIM_ATTACK_SHOCKWAVE,
	PHOBOS_ANIM_ATTACK_SWING,
	PHOBOS_ANIM_ATTACK_DASH
}

enum
{
	PHOBOS_STATE_IDLE = 0,
	PHOBOS_STATE_SEARCHING_ENEMY,
	PHOBOS_STATE_CHASE_ENEMY,		
	PHOBOS_STATE_ATTACK_SWING,
	PHOBOS_STATE_ATTACK_SHOCKWAVE,
	PHOBOS_STATE_ATTACK_DASH,
	PHOBOS_STATE_DEATH
}

#define TASK_GAME_START 27015
#define TASK_ATTACK 27016
#define TASK_DASH 21016

const pev_state = pev_iuser1
const pev_time = pev_fuser1
const pev_time2 = pev_fuser2
const pev_time3 = pev_fuser3

new g_CurrentBoss_Ent, Float:PHOBOS_HEALTH, g_sprid
new g_Msg_ScreenShake, g_MaxPlayers, g_FootStep

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_think(PHOBOS_CLASSNAME, "fw_PHOBOS_Think")
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	g_Msg_ScreenShake = get_user_msgid("ScreenShake")
	g_MaxPlayers = get_maxplayers()
}
public plugin_natives()
{
	register_native("Create_Phobos","Create_Boss",1)
}
public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, PHOBOS_MODEL)
	engfunc(EngFunc_PrecacheModel, PHOBOS_MODEL2)
	
	for(new i = 0; i < sizeof(Phobos_Sound); i++)
		precache_sound(Phobos_Sound[i])
		
	g_sprid = precache_model("sprites/shockwave.spr")	
}
public Event_NewRound()
{
	remove_task(TASK_GAME_START)
}
public logevent_round_end()
{
	remove_task(g_CurrentBoss_Ent+TASK_ATTACK)	
}
public Create_Boss(id, Float:HP)
{
	if(pev_valid(g_CurrentBoss_Ent))
		engfunc(EngFunc_RemoveEntity, g_CurrentBoss_Ent)
	
	static PHOBOS; PHOBOS = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(PHOBOS)) return -1
	
	g_CurrentBoss_Ent = PHOBOS
	PHOBOS_HEALTH = HP
	
	static Float:StartOrigin[3]	
	pev(id, pev_origin, StartOrigin)
	set_pev(PHOBOS, pev_origin, StartOrigin)
	
	static Float:Angles[3]	
	pev(id, pev_angles, Angles)
	set_pev(PHOBOS, pev_angles, Angles)
	set_pev(PHOBOS, pev_v_angle, Angles)
	
	// Set Config
	entity_set_string(PHOBOS, EV_SZ_classname,PHOBOS_CLASSNAME)
	entity_set_model(PHOBOS, random_num(0,1)?PHOBOS_MODEL2:PHOBOS_MODEL)

	set_pev(PHOBOS, pev_gamestate, 1)
	entity_set_int(PHOBOS, EV_INT_solid, SOLID_BBOX)
	entity_set_int(PHOBOS, EV_INT_movetype, MOVETYPE_PUSHSTEP)

	// Set Size
	new Float:maxs[3] = {40.0, 40.0, 200.0}
	new Float:mins[3] = {-40.0, -40.0, -35.0}
	entity_set_size(PHOBOS, mins, maxs)
	
	// Set Life
	set_pev(PHOBOS, pev_takedamage, DAMAGE_YES)
	set_pev(PHOBOS, pev_health, HEALTH_OFFSET + PHOBOS_HEALTH)
	
	// Set Config 2
	set_pev(PHOBOS, pev_owner, id)
	set_entity_anim(PHOBOS, PHOBOS_ANIM_IDLE, 1.0)
	set_pev(PHOBOS, pev_state, PHOBOS_STATE_IDLE)

	set_pev(PHOBOS, pev_nextthink, get_gametime() + 0.1)
	engfunc(EngFunc_DropToFloor, PHOBOS)
	
	set_pev(PHOBOS, pev_time2, get_gametime() + 1.0)
	
	return PHOBOS;
}
public fw_PHOBOS_Think(ent)
{
	if(!pev_valid(ent))
		return
	if(pev(ent, pev_state) == PHOBOS_STATE_DEATH)
		return
	new owner; owner = pev(ent, pev_owner)
	if(pev(owner, pev_health) < HEALTH_OFFSET)
	{
		set_pev(owner, pev_takedamage, DAMAGE_NO)
		set_pev(ent, pev_takedamage, DAMAGE_NO)
		PHOBOS_Death(ent)
		return
	}
	if(get_cvar_num("bot_stop")){
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		return;
	}

	switch(pev(ent, pev_state))
	{
		case PHOBOS_STATE_IDLE:
		{
			if(get_gametime() - 3.3 > pev(ent, pev_time))
			{
				set_entity_anim(ent, PHOBOS_ANIM_IDLE, 1.0)
				
				set_pev(ent, pev_time, get_gametime())
			}
			if(get_gametime() - 1.0 > pev(ent, pev_time2))
			{
				set_pev(ent, pev_state, PHOBOS_STATE_SEARCHING_ENEMY)
				set_pev(ent, pev_time2, get_gametime())
			}	
			
			// Set Next Think
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case PHOBOS_STATE_SEARCHING_ENEMY:
		{
			static Victim;
			Victim = FindClosetEnemy(ent, 0)
			
			if(is_user_alive(Victim))
			{
				set_pev(ent, pev_enemy, Victim)
				Random_AttackMethod(ent)
			} else {
				set_pev(ent, pev_enemy, 0)
				set_pev(ent, pev_state, PHOBOS_STATE_IDLE)
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case PHOBOS_STATE_CHASE_ENEMY:
		{
			static Enemy; Enemy = pev(ent, pev_enemy)
			static Float:EnemyOrigin[3]
			pev(Enemy, pev_origin, EnemyOrigin)
			
			if(is_user_alive(Enemy))
			{
				if(entity_range(Enemy, ent) <= floatround(PHOBOS_ATTACK_RANGE))
				{
					MM_Aim_To(ent, EnemyOrigin) 
					
					new rand = random_num(0, 3)
					if(rand == 0||rand == 1||rand == 2)
						Phobos_Attack_Swing(ent+TASK_ATTACK)
					else if(rand == 3) Phobos_Attack_Shockwave(ent+TASK_ATTACK)
				} else {
					if(pev(ent, pev_movetype) == MOVETYPE_PUSHSTEP)
					{
						static Float:OriginAhead[3]
						get_position(ent, 300.0, 0.0, 0.0, OriginAhead)
						
						MM_Aim_To(ent, EnemyOrigin) 
						hook_ent2(ent, OriginAhead, PHOBOS_SPEED + 30.0)
						
						set_entity_anim2(ent, PHOBOS_ANIM_RUN, 1.0)
						
						if(get_gametime() - 1.0 > pev(ent, pev_time3))
						{
							if(g_FootStep != 1) g_FootStep = 1
							else g_FootStep = 2
						
							PlaySound(0, Phobos_Sound[g_FootStep == 1 ? 0 : 1])
							
							set_pev(ent, pev_time3, get_gametime())
						}
						
						if(get_gametime() - 3.0 > pev(ent, pev_time2))
						{
							new rand = random_num(0, 3)
							if(rand == 0)
								Phobos_Start_Attack_Dash(ent+TASK_ATTACK)
							else if(rand == 1) Phobos_Attack_Shockwave(ent+TASK_ATTACK)
							
							set_pev(ent, pev_time2, get_gametime())
						}
					} else {
						set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
					}
				}
			} else {
				set_pev(ent, pev_state, PHOBOS_STATE_SEARCHING_ENEMY)
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case (PHOBOS_STATE_ATTACK_DASH + 1000):
		{
			static Float:Ahead[3], Float:CheckOrigin[3]
			get_position(ent, 512.0, 0.0, 0.0, Ahead)

			MM_Aim_To(ent, Ahead)
			hook_ent2(ent, Ahead, 2000.0)	
			
			get_position(ent, 150.0, 0.0, 0.0, CheckOrigin)
			for(new i = 0; i < g_MaxPlayers; i++)
			{
				if(!is_user_alive(i))
					continue
				if(i==pev(ent, pev_owner))
					continue
				pev(i, pev_origin, Ahead)
					
				if(get_distance_f(Ahead, CheckOrigin) > 200.0)
					continue
					
				ExecuteHam(Ham_TakeDamage, i, pev(ent,pev_owner), pev(ent,pev_owner), DASH_DAMAGE, DMG_BULLET)
				
				static Float:Velocity[3]
				Velocity[0] = random_float(-900.0, 900.0)
				Velocity[1] = random_float(-900.0, 900.0)
				Velocity[2] = random_float(800.0, 900.0)
				set_pev(i, pev_velocity, Velocity)
			}			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
	}
}
public Random_AttackMethod(ent)
{
	static RandomNum; RandomNum = random_num(0, 90)
	
	if(RandomNum > 0 && RandomNum <= 50)
	{
		set_pev(ent, pev_time, get_gametime())
		set_pev(ent, pev_state, PHOBOS_STATE_CHASE_ENEMY)
	}
	else if(RandomNum >= 51 && RandomNum <= 80)
		Phobos_Start_Attack_Dash(ent)
	else if(RandomNum >= 81 && RandomNum < 100)
		Phobos_Attack_Shockwave(ent)
	else
		Random_AttackMethod(ent)
}
public Phobos_Attack_Swing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	
	
	set_pev(ent, pev_state, PHOBOS_STATE_ATTACK_SWING)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	

	set_task(0.1, "Phobos_Attack_Swing_2", ent+TASK_ATTACK)			
}

public Phobos_Attack_Swing_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_entity_anim(ent, PHOBOS_ANIM_ATTACK_SWING, 1.0)
	
	PlaySound(0, Phobos_Sound[4])
	set_task(0.5, "Phobos_Check_Attack_Swing", ent+TASK_ATTACK)
	set_task(1.9, "Phobos_End_Attack_Swing", ent+TASK_ATTACK)	
}

public Phobos_Check_Attack_Swing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	static Float:CheckPosition[3], Float:VicOrigin[3]
	get_position(ent, 30.0, 00.0, 0.0, CheckPosition)
		
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(i==pev(ent, pev_owner))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(VicOrigin, CheckPosition) > SWING_RADIUS)
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, pev(ent,pev_owner), pev(ent,pev_owner), SWING_DAMAGE, DMG_BULLET)
		
		Make_PlayerShake(i)
	}
}

public Phobos_End_Attack_Swing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, PHOBOS_STATE_CHASE_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public Phobos_Attack_Shockwave(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	
	
	set_pev(ent, pev_state, PHOBOS_STATE_ATTACK_SHOCKWAVE)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	

	set_task(0.1, "Phobos_Attack_Shockwave_2", ent+TASK_ATTACK)
	set_task(3.0, "Phobos_End_Attack_Shockwave", ent+TASK_ATTACK)				
}

public Phobos_Attack_Shockwave_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_entity_anim(ent, PHOBOS_ANIM_ATTACK_SHOCKWAVE, 1.0)
	
	PlaySound(0, Phobos_Sound[6])
	set_task(2.1, "Phobos_Check_Attack_Shockwave", ent+TASK_ATTACK)
}

public Phobos_Check_Attack_Shockwave(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	static wpn, wpnname[32]
	static Float:CheckPosition[3], Float:VicOrigin[3]
	get_position(ent, 100.0, 00.0, 0.0, CheckPosition)
		
	ShockWave(CheckPosition, 9, 100, SHOCKWAVE_RADIUS, {144, 238, 238})
	ShockWave(CheckPosition, 9, 100, SHOCKWAVE_RADIUS-50.0, {144, 144, 238})
	
	PlaySound(0, Phobos_Sound[5])
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(i==pev(ent, pev_owner))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(VicOrigin, CheckPosition) > SHOCKWAVE_RADIUS)
			continue
			
		wpn = get_user_weapon(i)
		if(get_weaponname(wpn, wpnname, charsmax(wpnname)))
			engclient_cmd(i, "drop", wpnname)
			
		ExecuteHamB(Ham_TakeDamage, i, pev(ent,pev_owner), pev(ent,pev_owner), SHOCKWAVE_DAMAGE, DMG_BULLET)
		
		Make_PlayerShake(i)
	}
}

public Phobos_End_Attack_Shockwave(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, PHOBOS_STATE_CHASE_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}
public Phobos_Start_Attack_Dash(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_state, PHOBOS_STATE_ATTACK_DASH)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_enemy, FindFarestEnemy(ent,0))	
	
	new Float:EnemyOrigin[3],Enemy;Enemy = pev(ent, pev_enemy)
	pev(Enemy, pev_origin, EnemyOrigin)
	MM_Aim_To(ent, EnemyOrigin)	
	
	set_entity_anim(ent, PHOBOS_ANIM_ATTACK_DASH, 1.0)
	set_task(0.7, "Phobos_Start_Dashing", ent+TASK_ATTACK)		
}

public Phobos_Start_Dashing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	new Float:EnemyOrigin[3],Enemy;Enemy = pev(ent, pev_enemy)
	pev(Enemy, pev_origin, EnemyOrigin)	
	
	set_pev(ent, pev_state, PHOBOS_STATE_ATTACK_DASH + 1000)	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	
	set_task(0.6, "Phobos_Stop_Dashing", ent+TASK_ATTACK)
}

public Phobos_Stop_Dashing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
	
	remove_task(ent+TASK_DASH)
	//set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})
	set_pev(ent, pev_state, PHOBOS_STATE_ATTACK_DASH)
	
	set_task(0.4, "Phobos_End_Dashing", ent+TASK_ATTACK)
}
public Phobos_End_Dashing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
	
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, PHOBOS_STATE_SEARCHING_ENEMY)	
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public PHOBOS_Death(ent)
{
	if(!pev_valid(ent))
		return
	
	remove_task(ent+TASK_ATTACK)
	remove_task(ent+TASK_GAME_START)
	
	set_entity_anim(ent, PHOBOS_ANIM_DEATH, 1.0)	
	set_pev(ent, pev_state, PHOBOS_STATE_DEATH)
	
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	
	PlaySound(0, Phobos_Sound[2])
	set_task(10.0, "PHOBOS_Death2", ent)
}

public PHOBOS_Death2(ent)
{	
	if(!pev_valid(ent))
		return
	new id; id = pev(ent, pev_owner)
	set_pev(id, pev_solid, SOLID_BBOX)
	set_pev(id, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(id, pev_takedamage, DAMAGE_YES)
	user_kill(id,1)
}

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

stock ShockWave(Float:Orig[3], Life, Width, Float:Radius, Color[3]) 
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Orig, 0)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, Orig[0])
	engfunc(EngFunc_WriteCoord, Orig[1])
	engfunc(EngFunc_WriteCoord, Orig[2]-35.0)
	engfunc(EngFunc_WriteCoord, Orig[0])
	engfunc(EngFunc_WriteCoord, Orig[1]) 
	engfunc(EngFunc_WriteCoord, Orig[2]+Radius)
	write_short(g_sprid) 
	write_byte(0) 
	write_byte(0) 
	write_byte(Life) 
	write_byte(Width) 
	write_byte(0) 
	write_byte(Color[0]) 
	write_byte(Color[1]) 
	write_byte(Color[2]) 
	write_byte(255) 
	write_byte(1) 
	message_end()
}
stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	if(!pev_valid(ent))
		return
		
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_angles, vAngle) // if normal entity ,use pev_angles
	
	vAngle[0] = 0.0
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}


stock hook_ent2(ent, Float:VicOrigin[3], Float:speed)
{
	if(!pev_valid(ent))
		return
	
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(ent, pev_origin, EntOrigin)
	
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / speed
		
	fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
	fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
	fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time

	set_pev(ent, pev_velocity, fl_Velocity)
}
stock set_entity_anim(ent, anim, Float:framerate)
{
	if(!pev_valid(ent))
		return
	
	set_pev(ent, pev_animtime, get_gametime())
	set_pev(ent, pev_framerate, framerate)
	set_pev(ent, pev_sequence, anim)
}

stock set_entity_anim2(ent, anim, Float:framerate)
{
	if(!pev_valid(ent))
		return

	set_pev(ent, pev_framerate, framerate)
	set_pev(ent, pev_sequence, anim)
}

stock PlaySound(id, const sound[])
{
	if(equal(sound, ""))
		client_cmd(id, "mp3 stop")
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
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
