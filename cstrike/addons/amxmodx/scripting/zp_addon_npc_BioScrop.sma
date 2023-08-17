#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN "[CSO] Fallen Titan"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define SCORPION_MODEL "models/zombie_plague/boss/zbs_bossl_big08.mdl"

#define SCORPION_CLASSNAME "NPC_SCORPION"

new const skill_swing[] = "models/zombie_plague/boss/ef_swing.mdl"
new const skill_tentacle[][] = {
	"models/zombie_plague/boss/ef_tentacle_sign.mdl",
	"models/zombie_plague/boss/tentacle4.mdl",
	"models/zombie_plague/boss/ef_tentacle.mdl"
}
new const ScorpionSound[][] = {	
	"zombie_plague/boss/boss_footstep_1.wav",
	"zombie_plague/boss/boss_footstep_2.wav",		//1
	"zombie_plague/boss/scorpion/appear3.wav",			//2
	"zombie_plague/boss/scorpion/zbs_attack_bite.wav",		//3
	"zombie_plague/boss/scorpion/zbs_attack_poison1.wav",	//4
	"zombie_plague/boss/scorpion/zbs_poison_spit.wav",		//5
	"zombie_plague/boss/scorpion/zbs_attack_swing.wav",	//6	
	"zombie_plague/boss/scorpion/zbs_rolling1.wav",		//7
	"zombie_plague/boss/scorpion/zbs_rolling2.wav",		//8
	"zombie_plague/boss/scorpion/zbs_rolling3.wav",		//9	
	"zombie_plague/boss/scorpion/zbs_attack_tentacle1.wav",	//10
	"zombie_plague/boss/scorpion/zbs_attack_tentacle2.wav",	//11
	"zombie_plague/boss/scorpion/zbs_tentacle_pierce.wav",	//12
	"zombie_plague/boss/scorpion/exit1.wav"			//13
}


#define SCORPION_SPEED 250.0
#define HEALTH_OFFSET 50000.0
#define SCORPION_ATTACK_RANGE 250.0

#define BITE_RADIUS 100.0
#define BITE_DAMAGE random_float(350.0, 450.0)
#define SWING_RADIUS 320.0
#define SWING_DAMAGE random_float(450.0, 550.0)
#define POISON_DAMAGE random_float(100.0, 150.0)
#define ROLLING_DAMAGE random_float(450.0, 550.0)
#define TENTACLE_DAMAGE random_float(150.0, 200.0)

enum
{
	SCORPION_ANIM_DUMMY = 0,
	SCORPION_ANIM_APPEAR1,
	SCORPION_ANIM_IDLE,
	SCORPION_ANIM_WALK,
	SCORPION_ANIM_RUN,
	SCORPION_ANIM_ATTACK_1,
	SCORPION_ANIM_ATTACK_2,
	SCORPION_ANIM_ATTACK_3,
	SCORPION_ANIM_TENTACLE_1,
	SCORPION_ANIM_TENTACLE_2,
	SCORPION_ANIM_STORM_1,
	SCORPION_ANIM_STORM_2,
	SCORPION_ANIM_STORM_END,
	SCORPION_ANIM_GUARD_START,
	SCORPION_ANIM_GUARD_LOOP,
	SCORPION_ANIM_GUARD_END,
	SCORPION_ANIM_GUARD_BROKEN,
	SCORPION_ANIM_DASH_START,
	SCORPION_ANIM_DASH_LOOP,
	SCORPION_ANIM_DASH_END,
	SCORPION_ANIM_DEATH
}

enum
{
	SCORPION_STATE_IDLE = 0,
	SCORPION_STATE_APPEARING,
	SCORPION_STATE_SEARCHING_ENEMY,
	SCORPION_STATE_CHASE_ENEMY,	
	SCORPION_STATE_ATTACK_1,
	SCORPION_STATE_ATTACK_2,
	SCORPION_STATE_ATTACK_3,
	SCORPION_STATE_TENTACLE_1,
	SCORPION_STATE_TENTACLE_2,
	SCORPION_STATE_STORM,
	SCORPION_STATE_GUARD,
	SCORPION_STATE_DASH,
	SCORPION_STATE_DEATH
}

#define TASK_GAME_START 27015
#define TASK_ATTACK 27016

const pev_state = pev_iuser1
const pev_laststate = pev_iuser2
const pev_time = pev_fuser1
const pev_time2 = pev_fuser2
const pev_time3 = pev_fuser3

new g_CurrentBoss_Ent, Float:SCORPION_HEALTH
new g_Msg_ScreenShake, g_MaxPlayers, g_FootStep

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_think(SCORPION_CLASSNAME, "fw_SCORPION_Think")
	register_touch("scorpion_poison", "*", "fw_PoisonTouch")
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	g_Msg_ScreenShake = get_user_msgid("ScreenShake")
	g_MaxPlayers = get_maxplayers()	
}
public plugin_natives()
{
	register_native("Create_BioScropion","Create_Boss",1)
}
public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, SCORPION_MODEL)
	engfunc(EngFunc_PrecacheModel, skill_swing)
	
	for(new i = 0; i < sizeof(skill_tentacle); i++)
		engfunc(EngFunc_PrecacheModel, skill_tentacle[i])
		
	for(new i = 0; i < sizeof(ScorpionSound); i++)
		precache_sound(ScorpionSound[i])
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
	
	static SCORPION; SCORPION = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(SCORPION)) return -1
	
	g_CurrentBoss_Ent = SCORPION
	SCORPION_HEALTH = HP
	
	static Float:StartOrigin[3]	
	pev(id, pev_origin, StartOrigin)
	set_pev(SCORPION, pev_origin, StartOrigin)
	
	static Float:Angles[3]	
	pev(id, pev_angles, Angles)
	set_pev(SCORPION, pev_angles, Angles)
	set_pev(SCORPION, pev_v_angle, Angles)
	
	// Set Config
	entity_set_string(SCORPION, EV_SZ_classname,SCORPION_CLASSNAME)
	entity_set_model(SCORPION, SCORPION_MODEL)		
	set_pev(SCORPION, pev_skin, random_num(0,1))
	
	set_pev(SCORPION, pev_gamestate, 1)
	entity_set_int(SCORPION, EV_INT_solid, SOLID_BBOX)
	entity_set_int(SCORPION, EV_INT_movetype, MOVETYPE_PUSHSTEP)

	// Set Size
	new Float:maxs[3] = {110.0, 110.0, 110.0}
	new Float:mins[3] = {-110.0, -110.0,-30.0}
	entity_set_size(SCORPION, mins, maxs)
	
	// Set Life
	set_pev(SCORPION, pev_takedamage, DAMAGE_YES)
	set_pev(SCORPION, pev_health, HEALTH_OFFSET + SCORPION_HEALTH)
	
	// Set Config 2
	set_pev(SCORPION, pev_owner, id)
	set_entity_anim(SCORPION, SCORPION_ANIM_IDLE, 1.0)
	set_pev(SCORPION, pev_laststate, -1)
	set_pev(SCORPION, pev_state, SCORPION_STATE_APPEARING)

	set_pev(SCORPION, pev_nextthink, get_gametime() + 0.1)
	engfunc(EngFunc_DropToFloor, SCORPION)
	
	set_pev(SCORPION, pev_time2, get_gametime() + 1.0)
	
	return SCORPION;
}
public fw_SCORPION_Think(ent)
{
	if(!pev_valid(ent))
		return
	if(pev(ent, pev_state) == SCORPION_STATE_DEATH)
		return
		
	new owner; owner = pev(ent, pev_owner)
	if(pev(owner, pev_health) < HEALTH_OFFSET)
	{
		set_pev(owner, pev_takedamage, DAMAGE_NO)
		set_pev(ent, pev_takedamage, DAMAGE_NO)
		SCORPION_Death(ent)
		return
	}
	if(get_cvar_num("bot_stop")){
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		return;
	}
	switch(pev(ent, pev_state))
	{
		case SCORPION_STATE_IDLE:
		{
			if(get_gametime() - 3.3 > pev(ent, pev_time))
			{
				set_entity_anim(ent, SCORPION_ANIM_IDLE, 1.0)
				
				set_pev(ent, pev_time, get_gametime())
			}
			if(get_gametime() - 1.0 > pev(ent, pev_time2))
			{
				set_pev(ent, pev_state, SCORPION_STATE_SEARCHING_ENEMY)
				set_pev(ent, pev_time2, get_gametime())
			}	
			
			// Set Next Think
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case SCORPION_STATE_APPEARING:
		{
			set_entity_anim(ent, SCORPION_ANIM_APPEAR1, 1.0)
			
			PlaySound(0, ScorpionSound[2])
			set_task(3.9, "Make_PlayerShake", 0)
			
			set_pev(ent, pev_state, SCORPION_STATE_IDLE)
			set_pev(ent, pev_nextthink, get_gametime() + 8.6)
		}
		case SCORPION_STATE_SEARCHING_ENEMY:
		{
			static Victim;
			Victim = FindClosetEnemy(ent, 0)
			
			if(is_user_alive(Victim))
			{
				set_pev(ent, pev_enemy, Victim)
				Random_AttackMethod(ent)
			} else {
				set_pev(ent, pev_enemy, 0)
				set_pev(ent, pev_state, SCORPION_STATE_IDLE)
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case SCORPION_STATE_CHASE_ENEMY:
		{
			static Enemy; Enemy = pev(ent, pev_enemy)
			static Float:EnemyOrigin[3]
			pev(Enemy, pev_origin, EnemyOrigin)
			
			if(is_user_alive(Enemy))
			{
				if(entity_range(Enemy, ent) <= floatround(SCORPION_ATTACK_RANGE))
				{
					MM_Aim_To(ent, EnemyOrigin) 
					
					Scorpion_Attack_Attack1(ent+TASK_ATTACK)
				} else {
					if(pev(ent, pev_movetype) == MOVETYPE_PUSHSTEP)
					{
						static Float:OriginAhead[3]
						get_position(ent, 300.0, 0.0, 0.0, OriginAhead)
						
						MM_Aim_To(ent, EnemyOrigin) 
						hook_ent2(ent, OriginAhead, SCORPION_SPEED + 30.0)
						
						set_entity_anim2(ent, SCORPION_ANIM_WALK, 1.0)
						
						if(get_gametime() - 1.0 > pev(ent, pev_time3))
						{
							if(g_FootStep != 1) g_FootStep = 1
							else g_FootStep = 2
						
							PlaySound(0, ScorpionSound[g_FootStep == 1 ? 0 : 1])
							
							set_pev(ent, pev_time3, get_gametime())
						}
						
						if(get_gametime() - 4.0 > pev(ent, pev_time2))
						{
							new rand = random_num(0, 5)
							if(rand == 0)
								Scorpion_Start_Attack_Dash(ent+TASK_ATTACK)
							else if(rand == 1) Scorpion_Attack_Tentacle(ent+TASK_ATTACK)
							
							set_pev(ent, pev_time2, get_gametime())
						}
					} else {
						set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
					}
				}
			} else {
				set_pev(ent, pev_state, SCORPION_STATE_SEARCHING_ENEMY)
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
	}
}
public Random_AttackMethod(ent)
{
	static RandomNum; RandomNum = random_num(0, 100)
	
	if(RandomNum > 0 && RandomNum <= 50)
	{
		set_pev(ent, pev_time, get_gametime())
		set_pev(ent, pev_state, SCORPION_STATE_CHASE_ENEMY)
	}
	else if(RandomNum >= 51 && RandomNum <= 70)
		Scorpion_Start_Attack_Dash(ent)
	// else if(RandomNum >= 71 && RandomNum <= 80)
	// 	Scorpion_Attack_Poison(ent)
	else if(RandomNum >= 71 && RandomNum < 110)
		Scorpion_Attack_Tentacle(ent)
	else
		Random_AttackMethod(ent)
}
public Scorpion_Attack_Attack1(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
	
	static Enemy, Float:CheckPosition[3], Float:VicOrigin[3]
	Enemy = pev(ent, pev_enemy)	
	pev(Enemy, pev_origin, VicOrigin)
	get_position(ent, 270.0, 0.0, 0.0, CheckPosition)	
	if(get_distance_f(VicOrigin, CheckPosition) < BITE_RADIUS-20.0)
	{

		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		set_pev(ent, pev_state, SCORPION_STATE_ATTACK_1)
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
		set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	
	
		set_task(0.1, "Scorpion_Attack_Attack1_2", ent+TASK_ATTACK)			
	}else{
		Scorpion_Attack_Swing(ent+TASK_ATTACK)
	}
}

public Scorpion_Attack_Attack1_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
	
	PlaySound(0, ScorpionSound[3])
	new attackChance = random_num(0,1)
	if(attackChance){
		set_entity_anim(ent, SCORPION_ANIM_ATTACK_1, 1.0)
		set_task(float(25/30), "Scorpion_Check_Attack_Attack1", ent+TASK_ATTACK)
		set_task(2.03, "Scorpion_End_Attack_Attack1", ent+TASK_ATTACK)	
	}else{
		set_entity_anim(ent, SCORPION_ANIM_ATTACK_2, 1.0)
		set_task(float(40/30), "Scorpion_Check_Attack_Attack1", ent+TASK_ATTACK)
		set_task(2.7, "Scorpion_End_Attack_Attack1", ent+TASK_ATTACK)	
	}
}

public Scorpion_Check_Attack_Attack1(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	static Float:CheckPosition[3], Float:VicOrigin[3]
	get_position(ent, 270.0, 60.0, 0.0, CheckPosition)
		
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(i==pev(ent, pev_owner))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(VicOrigin, CheckPosition) > BITE_RADIUS)
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, pev(ent,pev_owner), pev(ent,pev_owner), BITE_DAMAGE, DMG_BULLET)
		
		Make_PlayerShake(i)
	}
}
public Scorpion_End_Attack_Attack1(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, SCORPION_STATE_CHASE_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public Scorpion_Attack_Swing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	
	set_pev(ent, pev_state, SCORPION_STATE_ATTACK_3)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	

	set_entity_anim(ent, SCORPION_ANIM_ATTACK_3, 1.0)
	
	set_task(0.6, "Scorpion_Check_Attack_Swing", ent+TASK_ATTACK)
	set_task(3.5, "Scorpion_End_Attack_Swing", ent+TASK_ATTACK)
}
public Scorpion_Check_Attack_Swing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	static wpn, wpnname[32]
	static Float:CheckPosition[3], Float:VicOrigin[3]
	get_position(ent, 0.0, 0.0, 0.0, CheckPosition)
	
	PlaySound(0, ScorpionSound[6])
	new ent_ef = create_entity("info_target")
	
	CheckPosition[2] -= 30.0
	entity_set_origin(ent_ef, CheckPosition)	
	entity_set_string(ent_ef,EV_SZ_classname, "ef_swing")
	entity_set_model(ent_ef, skill_swing)
	entity_set_int(ent_ef, EV_INT_solid, SOLID_SLIDEBOX)
	entity_set_int(ent_ef, EV_INT_movetype, MOVETYPE_NONE)
	
	new Float:maxs[3] = {16.0,16.0,36.0}
	new Float:mins[3] = {-16.0,-16.0,-36.0}
	entity_set_size(ent_ef, mins, maxs)
	
	set_pev(ent_ef, pev_rendermode, kRenderTransAdd)
	set_pev(ent_ef, pev_renderamt, 255.0)	
	
	entity_set_float(ent_ef, EV_FL_animtime, get_gametime())
	entity_set_float(ent_ef, EV_FL_framerate, 1.0)	
	entity_set_int(ent_ef, EV_INT_sequence, 0)
		
	get_position(ent, 0.0, 0.0, 0.0, CheckPosition)
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
		
		wpn = get_user_weapon(i)
		if(get_weaponname(wpn, wpnname, charsmax(wpnname)))
			engclient_cmd(i, "drop", wpnname)
		Make_PlayerShake(i)
	}
	set_task(0.5, "Scorpion_Remove_Ef_Swing", ent_ef)
}

public Scorpion_Remove_Ef_Swing(ent)
{
	remove_entity(ent)		
}
public Scorpion_End_Attack_Swing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, SCORPION_STATE_CHASE_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public Scorpion_Start_Attack_Dash(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	

	set_pev(ent, pev_state, SCORPION_STATE_DASH)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	
	set_pev(ent, pev_enemy, FindFarestEnemy(ent,0))	
	new Float:EnemyOrigin[3],Enemy;Enemy = pev(ent, pev_enemy)
	pev(Enemy, pev_origin, EnemyOrigin)
	MM_Aim_To(ent, EnemyOrigin)
	
	set_entity_anim(ent, SCORPION_ANIM_DASH_START, 1.0)
	PlaySound(0, ScorpionSound[7])
	
	set_task(1.7, "Scorpion_Start_Dashing", ent+TASK_ATTACK)
	set_task(3.0, "Scorpion_Stop_Dashing", ent+TASK_ATTACK)
}

public Scorpion_Start_Dashing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
			
	set_entity_anim(ent, SCORPION_ANIM_DASH_LOOP, 1.0)
	set_task(0.01, "Task_Dashing", ent+TASK_ATTACK, _, _, "b")
}

public Task_Dashing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	static Float:Target[3];
	get_position(ent, 512.0, 0.0, 0.0, Target)
	
	static Float:Origin[3]; pev(ent, pev_origin, Origin)
	static Float:POrigin[3]
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		pev(i, pev_origin, POrigin)
		if(get_distance_f(Origin, POrigin) > 170.0)
			continue
		if(i==pev(ent, pev_owner))
			continue
			
		static Float:Velocity[3]
		Velocity[0] = random_float(-900.0, 900.0)
		Velocity[1] = random_float(-900.0, 900.0)
		Velocity[2] = random_float(800.0, 900.0)
		set_pev(i, pev_velocity, Velocity)
		ExecuteHamB(Ham_TakeDamage, i, pev(ent, pev_owner), pev(ent, pev_owner), ROLLING_DAMAGE, DMG_CRUSH)
		Make_PlayerShake(i)
	}
	PlaySound(0, ScorpionSound[8])
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	hook_ent2(ent, Target, 2000.0)
}

public Scorpion_Stop_Dashing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	remove_task(ent+TASK_ATTACK)
	set_entity_anim(ent, SCORPION_ANIM_DASH_END, 1.0)
	PlaySound(0, ScorpionSound[9])
	set_pev(ent, pev_velocity, {0.0,0.0,0.0})
	set_pev(ent, pev_state, SCORPION_STATE_DASH)
	
	set_task(1.7, "Scorpion_End_Dashing", ent+TASK_ATTACK)
}

public Scorpion_End_Dashing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
	
	set_pev(ent, pev_laststate, SCORPION_STATE_DASH)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, SCORPION_STATE_SEARCHING_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public Scorpion_Attack_Tentacle(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return

	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_state, SCORPION_STATE_TENTACLE_1)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
	
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})

	if(random_num(0,1) == 1) // Tentacle 1
	{
		set_entity_anim(ent, SCORPION_ANIM_TENTACLE_1, 1.0)	
		
		set_task(2.5, "Scorpion_Tentacle_Sound", 10)
		set_task(float(100/15), "Scorpion_Tentacle", ent+TASK_ATTACK)
		set_task(float(125/15), "Scorpion_Tentacle", ent+TASK_ATTACK)
		set_task(7.3, "Scorpion_End_Attack_Tentacle", ent+TASK_ATTACK)
		
	} else { // Tentacle 2
		set_entity_anim(ent, SCORPION_ANIM_TENTACLE_2, 1.0)
		
		set_task(2.4, "Scorpion_Tentacle_Sound", 11)
		set_task(float(95/15), "Scorpion_Tentacle", ent+TASK_ATTACK)
		set_task(float(113/15), "Scorpion_Tentacle", ent+TASK_ATTACK)
		set_task(float(132/15), "Scorpion_Tentacle", ent+TASK_ATTACK)
		set_task(10.73, "Scorpion_End_Attack_Tentacle", ent+TASK_ATTACK)
	}	
}
public Scorpion_Tentacle_Sound(index) PlaySound(0,ScorpionSound[index])
public Scorpion_Tentacle(ent)
{
	ent -= TASK_ATTACK
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
public Scorpion_End_Attack_Tentacle(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, SCORPION_STATE_SEARCHING_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}
public Create_Tentacle(Scorpion, Float:Origin[3], Float:Angles[3])
{
	new Float:num, ent = create_entity("info_target")

	Origin[2] += 5.0
	
	entity_set_origin(ent, Origin)
	entity_set_vector(ent, EV_VEC_v_angle, Angles)
	
	entity_set_string(ent,EV_SZ_classname, "tentacle")
	entity_set_model(ent, skill_tentacle[0])
	entity_set_int(ent, EV_INT_solid, SOLID_NOT)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_owner, pev(Scorpion, pev_owner))
	
	new Float:maxs[3] = {1.0,1.0,1.0}
	new Float:mins[3] = {-1.0,-1.0,-1.0}
	entity_set_size(ent, mins, maxs)
	
	set_entity_anim(ent, 0, 1.0)	
	
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
		
	emit_sound(ent, CHAN_BODY, ScorpionSound[12], 1.0, ATTN_NORM, 0, PITCH_NORM)
	entity_set_model(ent, skill_tentacle[1])	
	entity_set_string(ent,EV_SZ_classname, "tentacle2")	
	new Float:maxs[3] = {26.0,26.0,36.0}
	new Float:mins[3] = {-26.0,-26.0,-36.0}
	entity_set_size(ent, mins, maxs)		
	set_entity_anim(ent, 0, 1.0)	
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
		Velocity[0] = random_float(-20.0, 20.0)
		Velocity[1] = random_float(-20.0, 20.0)
		Velocity[2] = random_float(400.0, 600.0)
		set_pev(i, pev_velocity, Velocity)
		ExecuteHamB(Ham_TakeDamage, i, pev(ent, pev_owner), pev(ent, pev_owner), TENTACLE_DAMAGE, DMG_BULLET)
		Make_PlayerShake(i)
	}
}
public SCORPION_Death(ent)
{
	if(!pev_valid(ent))
		return
	
	remove_task(ent+TASK_ATTACK)
	remove_task(ent+TASK_GAME_START)
	
	set_entity_anim(ent, SCORPION_ANIM_DEATH, 1.0)	
	set_pev(ent, pev_state, SCORPION_STATE_DEATH)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
	
	PlaySound(0, ScorpionSound[13])
	set_task(10.0, "SCORPION_Death2", ent)
}

public SCORPION_Death2(ent)
{		
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)

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
