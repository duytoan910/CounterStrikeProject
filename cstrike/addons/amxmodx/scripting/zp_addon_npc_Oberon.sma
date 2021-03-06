#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN "[CSO] Fallen Titan"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define OBERON_MODEL "models/zombie_plague/boss/zbs_bossl_big02.mdl"
#define OBERON_CLASSNAME "NPC_OBERON"

#define CANNON_MODEL "models/grenade.mdl"

#define OBERON_SPEED 200.0

#define HEALTH_OFFSET 50000.0

#define OBERON_ATTACK_RANGE 150.0
#define BASE_ATTACK1_RADIUS 200.0
#define BASE_ATTACK2_RADIUS 200.0
#define BASE_ATTACK_DAMAGE random_float(450.0, 600.0)
#define BASE_OBERON_ATTACK_BOMB_DAMAGE random_float(650.0, 750.0)

new Float:ATTACK1_RADIUS 
new Float:ATTACK2_RADIUS
new Float:ATTACK_DAMAGE 
new Float:OBERON_ATTACK_BOMB_DAMAGE

new const oberon_knife_effect[] = "models/zombie_plague/boss/ef_knife.mdl"
new const oberon_hole_effect[] = "models/zombie_plague/boss/ef_hole.mdl"
new const oberon_bomb_model[] = "models/zombie_plague/boss/zbs_bossl_big02_bomb.mdl"

new const Oberon_Sound[15][] = 
{
	"zombie_plague/boss/oberon/appear.wav",			//0
	"zombie_plague/boss/oberon/death.wav",			//1
	"zombie_plague/boss/oberon/knife.wav",	
	"zombie_plague/boss/boss_footstep_1.wav",
	"zombie_plague/boss/boss_footstep_2.wav",		//4
	"zombie_plague/boss/oberon/hole.wav",			//5
	"zombie_plague/boss/oberon/attack_bomb.wav",		//6
	"zombie_plague/boss/oberon/attack1.wav",		//7
	"zombie_plague/boss/oberon/attack2.wav",		//8
	"zombie_plague/boss/oberon/attack3_jump.wav",		//9
	"zombie_plague/boss/oberon/attack3.wav",		//10
	"zombie_plague/boss/oberon/knife_attack1.wav",		//11
	"zombie_plague/boss/oberon/knife_attack2.wav",		//12
	"zombie_plague/boss/oberon/knife_attack3_jump.wav",	//13
	"zombie_plague/boss/oberon/knife_attack3.wav"		//14
}
enum
{
	OBERON_ANIM_DUMMY = 0,
	OBERON_ANIM_SCENE_APPEAR,
	OBERON_ANIM_IDLE,
	OBERON_ANIM_WALK,
	OBERON_ANIM_RUN,
	OBERON_ANIM_JUMP,
	OBERON_ANIM_ATTACK1,
	OBERON_ANIM_ATTACK2,
	OBERON_ANIM_ATTACK3,
	OBERON_ANIM_ATTACK_BOMB,
	OBERON_ANIM_ATTACK_HOLE,
	OBERON_ANIM_SCENE_KNIFE,
	OBERON_ANIM_IDLE_KNIFE,
	OBERON_ANIM_WALK_KNIFE,
	OBERON_ANIM_ATTACK1_KNIFE,
	OBERON_ANIM_ATTACK2_KNIFE,
	OBERON_ANIM_ATTACK3_KNIFE,
	OBERON_ANIM_ATTACK_BOMB_2,
	OBERON_ANIM_ATTACK_BOMB_KNIFE,
	OBERON_ANIM_ATTACK_HOLE_KNIFE,
	OBERON_ANIM_DEATH
}

enum
{
	OBERON_STATE_IDLE = 0,
	OBERON_STATE_APPEARING,
	OBERON_STATE_CHANGING,
	OBERON_STATE_SEARCHING_ENEMY,
	OBERON_STATE_CHASE_ENEMY,
	OBERON_STATE_ATTACK_NORMAL,
	OBERON_STATE_ATTACK_JUMP,
	OBERON_STATE_ATTACK_BOMB,
	OBERON_STATE_ATTACK_HOLE,
	OBERON_STATE_DEATH
}

#define TASK_GAME_START 27015
#define TASK_ATTACK 27016

const pev_state = pev_iuser1
const pev_laststate = pev_iuser2
const pev_time = pev_fuser1
const pev_time2 = pev_fuser2
const pev_time3 = pev_fuser3

new g_CurrentBoss_Ent, g_Reg_Ham, Float:OBERON_HEALTH, g_stage
new g_Msg_ScreenShake, g_MaxPlayers, g_FootStep, g_expspr_id

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_think(OBERON_CLASSNAME, "fw_OBERON_Think")
	register_touch("oberon_bomb", "*", "fw_Grenade_Touch")
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	g_Msg_ScreenShake = get_user_msgid("ScreenShake")
	g_MaxPlayers = get_maxplayers()
}
public plugin_natives()
{
	register_native("Create_Oberon","Create_Boss",1)
}
public plugin_precache()
{
	precache_model(OBERON_MODEL)	
	precache_model(oberon_knife_effect)
	precache_model(oberon_hole_effect)
	precache_model(oberon_bomb_model)
	
	for(new i = 0; i < sizeof(Oberon_Sound); i++)
		precache_sound(Oberon_Sound[i])
	
	g_expspr_id = engfunc(EngFunc_PrecacheModel, "sprites/flame_puff01.spr")	
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
	
	static OBERON; OBERON = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(OBERON)) return -1
	
	g_CurrentBoss_Ent = OBERON
	OBERON_HEALTH = HP
	
	static Float:StartOrigin[3]	
	pev(id, pev_origin, StartOrigin)
	set_pev(OBERON, pev_origin, StartOrigin)
	
	static Float:Angles[3]	
	pev(id, pev_angles, Angles)
	set_pev(OBERON, pev_angles, Angles)
	set_pev(OBERON, pev_v_angle, Angles)
	
	// Set Config
	entity_set_string(OBERON, EV_SZ_classname,OBERON_CLASSNAME)
	entity_set_model(OBERON, OBERON_MODEL)
		
	set_pev(OBERON, pev_gamestate, 1)
	entity_set_int(OBERON, EV_INT_solid, SOLID_BBOX)
	entity_set_int(OBERON, EV_INT_movetype, MOVETYPE_PUSHSTEP)

	// Set Size
	new Float:maxs[3] = {67.0, 67.0, 150.0}
	new Float:mins[3] = {-67.0, -67.0, -35.0}	
	engfunc(EngFunc_SetSize, OBERON, mins, maxs)
	
	// Set Life
	set_pev(OBERON, pev_takedamage, DAMAGE_YES)
	set_pev(OBERON, pev_health, HEALTH_OFFSET + OBERON_HEALTH)
	
	// Set Config 2
	set_pev(OBERON, pev_owner, id)
	g_stage = 0
	set_entity_anim(OBERON, OBERON_ANIM_IDLE, 1.0)
	set_pev(OBERON, pev_laststate, -1)
	set_pev(OBERON, pev_state, OBERON_STATE_APPEARING)

	set_pev(OBERON, pev_nextthink, get_gametime() + 0.1)
	engfunc(EngFunc_DropToFloor, OBERON)
	
	set_pev(OBERON, pev_time2, get_gametime() + 1.0)
	
	ATTACK1_RADIUS = BASE_ATTACK1_RADIUS
	ATTACK2_RADIUS = BASE_ATTACK2_RADIUS
	ATTACK_DAMAGE = BASE_ATTACK_DAMAGE
	OBERON_ATTACK_BOMB_DAMAGE = BASE_OBERON_ATTACK_BOMB_DAMAGE
	
	if(!g_Reg_Ham)
	{
		g_Reg_Ham = 1
		RegisterHamFromEntity(Ham_TraceAttack, OBERON, "fw_OBERON_TraceAttack", 1)
	}
	return OBERON;
}
public fw_OBERON_TraceAttack(Ent, Attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	if(!is_valid_ent(Ent)) 
		return
     
	static Classname[32]
	pev(Ent, pev_classname, Classname, charsmax(Classname)) 
	     
	if(!equal(Classname, OBERON_CLASSNAME)) 
		return
		
	new owner;owner=pev(Ent,pev_owner)
	if(pev(owner, pev_health)>200.0)
	{
		set_pev(owner, pev_health, pev(Ent, pev_health) - HEALTH_OFFSET)
	}
	else set_pev(owner, pev_health, 1.0)
}
public fw_OBERON_Think(ent)
{
	if(!pev_valid(ent))
		return
	if(pev(ent, pev_state) == OBERON_STATE_DEATH)
		return
	if((pev(ent, pev_health) - HEALTH_OFFSET) <= 0.0)
	{
		set_pev(ent, pev_takedamage, DAMAGE_NO)
		OBERON_Death(ent)
		return
	}
	if(!g_stage && (pev(ent, pev_health) <= (HEALTH_OFFSET+(OBERON_HEALTH*0.5))))
	{
		OBERON_Changing(ent)
		return
	}
	
	switch(pev(ent, pev_state))
	{
		case OBERON_STATE_IDLE:
		{
			if(get_gametime() - 3.3 > pev(ent, pev_time))
			{
				set_entity_anim(ent, g_stage?OBERON_ANIM_IDLE_KNIFE:OBERON_ANIM_IDLE, 1.0)
				
				set_pev(ent, pev_time, get_gametime())
			}
			if(get_gametime() - 1.0 > pev(ent, pev_time2))
			{
				set_pev(ent, pev_state, OBERON_STATE_SEARCHING_ENEMY)
				set_pev(ent, pev_time2, get_gametime())
			}	
			
			// Set Next Think
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case OBERON_STATE_APPEARING:
		{
			set_entity_anim(ent, OBERON_ANIM_SCENE_APPEAR, 1.0)
			PlaySound(0, Oberon_Sound[0])
			set_task(0.75, "Make_PlayerShake", 0)
			
			set_pev(ent, pev_state, OBERON_STATE_IDLE)
			set_pev(ent, pev_nextthink, get_gametime() + 6.0)
		}
		case OBERON_STATE_SEARCHING_ENEMY:
		{
			static Victim;
			Victim = FindClosetEnemy(ent, 0)
			
			if(is_user_alive(Victim))
			{
				set_pev(ent, pev_enemy, Victim)
				Random_AttackMethod(ent)
			} else {
				set_pev(ent, pev_enemy, 0)
				set_pev(ent, pev_state, OBERON_STATE_IDLE)
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case OBERON_STATE_CHASE_ENEMY:
		{
			static Enemy; Enemy = pev(ent, pev_enemy)
			static Float:EnemyOrigin[3]
			pev(Enemy, pev_origin, EnemyOrigin)
			
			if(is_user_alive(Enemy))
			{
				if(entity_range(Enemy, ent) <= floatround(OBERON_ATTACK_RANGE+100.0))
				{
					set_pev(ent, pev_state, OBERON_STATE_ATTACK_NORMAL)
					
					MM_Aim_To(ent, EnemyOrigin) 
					
					new ran = random_num(0, 8)					
					switch(ran)
					{
						case 0..4: set_task(0.1, "OBERON_StartAttack1", ent+TASK_ATTACK)
						case 5..9: set_task(0.1, "OBERON_StartAttack2", ent+TASK_ATTACK)
						case 10: OBERON_StartAttack3(ent)
					}
				} else {
					if(pev(ent, pev_movetype) == MOVETYPE_PUSHSTEP)
					{
						static Float:OriginAhead[3]
						get_position(ent, 300.0, 0.0, 0.0, OriginAhead)
						
						MM_Aim_To(ent, EnemyOrigin) 
						hook_ent2(ent, OriginAhead, OBERON_SPEED + 30.0)
						
						set_entity_anim2(ent, g_stage?OBERON_ANIM_WALK_KNIFE:OBERON_ANIM_WALK, 1.0)
						
						if(get_gametime() - 1.0 > pev(ent, pev_time3))
						{
							if(g_FootStep != 1) g_FootStep = 1
							else g_FootStep = 2
						
							PlaySound(0, Oberon_Sound[g_FootStep == 1 ? 3 : 4])
							
							set_pev(ent, pev_time3, get_gametime())
						}
						
						if(get_gametime() - 5.0 > pev(ent, pev_time2))
						{
							new rand = random_num(0, 7)
							if(rand == 0)
								OBERON_Attack_Bomb(ent)
							else if(rand == 1) OBERON_Attack_Hole(ent)
							else if(rand == 2||rand == 3) OBERON_StartAttack3(ent)
							
							set_pev(ent, pev_time2, get_gametime())
						}
					} else {
						set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
					}
				}
			} else {
				set_pev(ent, pev_state, OBERON_STATE_SEARCHING_ENEMY)
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case (OBERON_STATE_ATTACK_JUMP + 1000):
		{
			static Float:Ahead[3], Float:CheckOrigin[3]
			get_position(ent, 0.0, 0.0, -250.0, CheckOrigin)
			for(new i = 0; i < g_MaxPlayers; i++)
			{
				if(!is_user_alive(i))
					continue
				if(i==pev(ent, pev_owner))
					continue
				pev(i, pev_origin, Ahead)
					
				if(get_distance_f(Ahead, CheckOrigin) > 200.0)
					continue
				
				ExecuteHam(Ham_TakeDamage, i, pev(ent,pev_owner), pev(ent,pev_owner), ATTACK_DAMAGE * 5.0, DMG_BULLET)
			}
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case (OBERON_STATE_ATTACK_HOLE + 1000):
		{
			static i, Float:Origin[3], Float:Speed
			pev(ent, pev_origin, Origin)
			for(i=0;i<g_MaxPlayers;i++)
			{
				if(is_user_alive(i) && i!=pev(ent, pev_owner) && entity_range(ent, i) <= 2500.0)
				{
					Speed = (1500.0 / entity_range(ent, i)) * 75.0
					
					hook_ent2(i, Origin, Speed)	
				}
			}		
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
		}
		case (OBERON_STATE_ATTACK_BOMB + 1000):
		{
			static num, Float:height, Float:StartOrigin[3], Float:Angles[3], Float:TargetOrigin[3]
			pev(ent, pev_angles, Angles)
			set_pev(ent, pev_v_angle, Angles)
			
			get_position(ent, 100.0, -10.0, 80.0, StartOrigin)
			pev(ent, pev_angles, Angles)
			
			PlaySound(0, Oberon_Sound[6])
			
			num = g_stage?16:8
			height= g_stage?random_float(800.0, 1500.0):random_float(1500.0, 2000.0)
			for(new i = 0; i < num; i++)
			{			
				get_position(ent, random_float(-300.0, 600.0), random_float(-300.0, 600.0), height, TargetOrigin)
				Shoot_Bomb(ent, StartOrigin, Angles, TargetOrigin)
			}	
			set_pev(ent, pev_nextthink, get_gametime() + 2.9)		
		}
	}
}
public Random_AttackMethod(ent)
{
	static RandomNum; RandomNum = random_num(0, 100)
	
	if(RandomNum > 0 && RandomNum <= 57)
	{
		set_pev(ent, pev_time, get_gametime())
		set_pev(ent, pev_state, OBERON_STATE_CHASE_ENEMY)
	}
	else if(RandomNum >= 58 && RandomNum <= 73)
		OBERON_Attack_Hole(ent)
	else if(RandomNum >= 78 && RandomNum <= 89)
		OBERON_StartAttack3(ent)
	else if(RandomNum >= 90 && RandomNum < 100)
		OBERON_Attack_Bomb(ent)
	else
		Random_AttackMethod(ent)
}

public OBERON_Changing(ent)
{
	if(!pev_valid(ent))
		return
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})
	
	PlaySound(0, Oberon_Sound[2])
	set_pev(ent, pev_state, OBERON_STATE_CHANGING)
	set_entity_anim(ent, OBERON_ANIM_SCENE_KNIFE, 1.0)
	g_stage = 1
	
	ATTACK1_RADIUS = BASE_ATTACK1_RADIUS
	ATTACK2_RADIUS = BASE_ATTACK2_RADIUS
	ATTACK_DAMAGE = BASE_ATTACK_DAMAGE * 1.5
	OBERON_ATTACK_BOMB_DAMAGE = BASE_OBERON_ATTACK_BOMB_DAMAGE * 1.5
	
	set_task(8.7, "OBERON_ChangingDone", ent+TASK_ATTACK)
}
public OBERON_ChangingDone(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_health, pev(ent, pev_health) + (OBERON_HEALTH*0.1))
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, OBERON_STATE_SEARCHING_ENEMY)	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}
public OBERON_StartAttack1(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	

	set_task(0.1, "OBERON_StartAttack1_2", ent+TASK_ATTACK)
}

public OBERON_StartAttack2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	

	set_task(0.1, "OBERON_StartAttack2_2", ent+TASK_ATTACK)
}

public OBERON_StartAttack1_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_entity_anim(ent, g_stage?OBERON_ANIM_ATTACK1_KNIFE:OBERON_ANIM_ATTACK1, 1.0)
	
	PlaySound(0, Oberon_Sound[7])
	set_task(0.8, "OBERON_CheckAttack1", ent+TASK_ATTACK)
	set_task(2.5, "OBERON_DoneAttack", ent+TASK_ATTACK)	
}

public OBERON_StartAttack2_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_entity_anim(ent, g_stage?OBERON_ANIM_ATTACK2_KNIFE:OBERON_ANIM_ATTACK2, 1.0)
	
	PlaySound(0, Oberon_Sound[8])
	set_task(0.3, "OBERON_CheckAttack2", ent+TASK_ATTACK)
	set_task(1.65, "OBERON_DoneAttack", ent+TASK_ATTACK)	
}

public OBERON_CheckAttack1(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	static Float:CheckPosition[3], Float:VicOrigin[3]
	get_position(ent, 80.0, 80.0, 0.0, CheckPosition)
		
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(i==pev(ent, pev_owner))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(VicOrigin, CheckPosition) > ATTACK1_RADIUS)
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, pev(ent,pev_owner), pev(ent,pev_owner), ATTACK_DAMAGE, DMG_BULLET)
		
		Make_PlayerShake(i)
	}
}

public OBERON_CheckAttack2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	static Float:CheckPosition[3], Float:VicOrigin[3]
	get_position(ent, 100.0, -90.0, 0.0, CheckPosition)
		
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(i==pev(ent, pev_owner))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(VicOrigin, CheckPosition) > ATTACK2_RADIUS)
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, pev(ent,pev_owner), pev(ent,pev_owner), ATTACK_DAMAGE, DMG_BULLET)
		
		static Float:Velocity[3]
		Velocity[0] = -500.0
		Velocity[1] = -10.0
		Velocity[2] = random_float(800.0, 900.0)
		set_pev(i, pev_velocity, Velocity)
		
		Make_PlayerShake(i)
	}	
}

public OBERON_StartAttack3(ent)
{
	if(/*pev(ent, pev_state) == OBERON_STATE_CHASE_ENEMY || */pev(ent, pev_state) == OBERON_STATE_SEARCHING_ENEMY)
	{
		set_pev(ent, pev_state, OBERON_STATE_ATTACK_NORMAL)
			
		set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	
		set_pev(ent, pev_friction, 0.0)	
		
		set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
		
		new Enemy, Float:EnemyOrigin[3]
		Enemy = FindFarestEnemy(ent, 0)
		
		set_pev(ent, pev_enemy, Enemy)	
		pev(Enemy, pev_origin, EnemyOrigin)
		MM_Aim_To(ent, EnemyOrigin)
		
		PlaySound(0, Oberon_Sound[9])	
		
		set_entity_anim(ent, g_stage?OBERON_ANIM_ATTACK3_KNIFE:OBERON_ANIM_ATTACK3, 1.0)
		
		set_task(0.6, "OBERON_StartAttack3_Jump", ent+TASK_ATTACK)
	}
}

public OBERON_StartAttack3_Jump(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return				
	
	new Enemy, Float:Velocity[3], Float:EntOrigin[3], Float:TargetOrigin[3]	
		
	Enemy = pev(ent, pev_enemy)	
	pev(Enemy, pev_origin, TargetOrigin)	
	pev(ent, pev_origin, EntOrigin)
	
	get_position(ent, 800*0.1, 0.0, 800*0.2, TargetOrigin)
	get_speed_vector(EntOrigin, TargetOrigin, 800*0.85, Velocity)
	set_pev(ent, pev_velocity, Velocity)
	
	set_task(1.6, "OBERON_CheckAttack3", ent+TASK_ATTACK)	
	set_pev(ent, pev_state, OBERON_STATE_ATTACK_JUMP + 1000)
	set_pev(ent, pev_nextthink, get_gametime() + 1.5)
}
public OBERON_CheckAttack3(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	static Float:CheckPosition[3], Float:VicOrigin[3]
	get_position(ent, 150.0, 0.0, 0.0, CheckPosition)		
	PlaySound(0, Oberon_Sound[10])
	set_pev(ent, pev_movetype, MOVETYPE_NONE)

	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(i==pev(ent, pev_owner))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(VicOrigin, CheckPosition) > ATTACK1_RADIUS+30.0)
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, pev(ent,pev_owner), pev(ent,pev_owner), ATTACK_DAMAGE*10, DMG_BULLET)
		
		Make_PlayerShake(i)
	}
	drop_to_floor(ent)
	set_task(1.4, "OBERON_DoneAttack", ent+TASK_ATTACK)	
}
public OBERON_DoneAttack(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_solid, SOLID_BBOX)
	set_pev(ent, pev_state, OBERON_STATE_CHASE_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public OBERON_Attack_Hole(ent)
{
	if(pev(ent, pev_laststate) == OBERON_STATE_ATTACK_HOLE)
	{
		set_pev(ent, pev_state, OBERON_STATE_SEARCHING_ENEMY)		
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		return;
	}
	if(pev(ent, pev_state) == OBERON_STATE_CHASE_ENEMY || pev(ent, pev_state) == OBERON_STATE_SEARCHING_ENEMY )
	{
		set_pev(ent, pev_state, OBERON_STATE_ATTACK_HOLE)
		set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})		
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		
		PlaySound(0, Oberon_Sound[5])	
		set_entity_anim(ent, g_stage?OBERON_ANIM_ATTACK_HOLE_KNIFE:OBERON_ANIM_ATTACK_HOLE, 1.0)
		set_task(0.2, "OBERON_Start_Hole", ent+TASK_ATTACK)
		set_task(6.0, "OBERON_Stop_Hole", ent+TASK_ATTACK)
	}
}

public OBERON_Start_Hole(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return

	new holeEnt = create_entity("info_target")
	
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	
	Origin[2] -= 20.0
	
	entity_set_origin(holeEnt, Origin)
	
	entity_set_string(holeEnt,EV_SZ_classname, "hole_hook")
	entity_set_model(holeEnt, oberon_hole_effect)
	entity_set_int(holeEnt, EV_INT_solid, SOLID_NOT)
	entity_set_int(holeEnt, EV_INT_movetype, MOVETYPE_NONE)
	
	new Float:maxs[3] = {1.0,1.0,1.0}
	new Float:mins[3] = {-1.0,-1.0,-1.0}
	entity_set_size(holeEnt, mins, maxs)
	
	entity_set_float(holeEnt, EV_FL_animtime, get_gametime())
	entity_set_float(holeEnt, EV_FL_framerate, 1.0)	
	entity_set_int(holeEnt, EV_INT_sequence, 0)	
	
	set_pev(holeEnt, pev_rendermode, kRenderTransAdd)
	set_pev(holeEnt, pev_renderamt, 255.0)	
	
	drop_to_floor(holeEnt)
	
	set_pev(ent, pev_state, OBERON_STATE_ATTACK_HOLE + 1000)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	
	set_task(4.9, "OBERON_CheckAttack_Hole", ent+TASK_ATTACK)
	set_task(4.0, "OBERON_Stop_Hook", ent+TASK_ATTACK)		
}
public OBERON_CheckAttack_Hole(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	static Float:CheckPosition[3], Float:VicOrigin[3]
	get_position(ent, 0.0, 0.0, 0.0, CheckPosition)
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(i==pev(ent, pev_owner))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(VicOrigin, CheckPosition) > ATTACK1_RADIUS + 50.0)
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, pev(ent,pev_owner), pev(ent,pev_owner), ATTACK_DAMAGE*0.7, DMG_BULLET)
		
		static Float:Velocity[3]
		Velocity[0] = random_float(-500.0, 500.0)
		Velocity[1] = random_float(-500.0, 500.0)
		Velocity[2] = random_float(1000.0, 1200.0)
		set_pev(i, pev_velocity, Velocity)
		
		Make_PlayerShake(i)
	}	
}
public OBERON_Stop_Hook(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
	
	remove_entity_name("hole_hook")
	set_pev(ent, pev_state, OBERON_STATE_ATTACK_HOLE)
}
public OBERON_Stop_Hole(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	remove_task(ent+TASK_ATTACK)
	
	set_pev(ent, pev_laststate, OBERON_STATE_ATTACK_HOLE)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, OBERON_STATE_SEARCHING_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}
public OBERON_Attack_Bomb(ent)
{	
	if(pev(ent, pev_laststate) == OBERON_STATE_ATTACK_BOMB)
	{
		set_pev(ent, pev_state, OBERON_STATE_SEARCHING_ENEMY)		
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		return;
	}
	if(pev(ent, pev_state) == OBERON_STATE_CHASE_ENEMY || pev(ent, pev_state) == OBERON_STATE_SEARCHING_ENEMY)
	{	
		set_pev(ent, pev_state, OBERON_STATE_ATTACK_BOMB)
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		
		set_task(0.1, "OBERON_Start_Attack_Bomb", ent+TASK_ATTACK)	
	}
}

public OBERON_Start_Attack_Bomb(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return		
		
	set_entity_anim(ent, g_stage?OBERON_ANIM_ATTACK_BOMB_KNIFE:OBERON_ANIM_ATTACK_BOMB, 1.0)
	
	set_pev(ent, pev_state, OBERON_STATE_ATTACK_BOMB + 1000)
	set_pev(ent, pev_nextthink, get_gametime() + 2.9)
	
	set_task(11.0, "OBERON_Stop_Bomb", ent+TASK_ATTACK)
}
public OBERON_Stop_Bomb(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return		
	
	remove_task(ent+TASK_ATTACK)
	remove_entity_name("oberon_bomb")
	
	set_pev(ent, pev_laststate, OBERON_STATE_ATTACK_BOMB)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, OBERON_STATE_SEARCHING_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}
public Shoot_Bomb(OBERON, Float:StartOrigin[3], Float:Angles[3], Float:TargetOrigin[3])
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return
	
	set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(Ent, pev_solid, SOLID_TRIGGER)
	
	set_pev(Ent, pev_classname, "oberon_bomb")
	engfunc(EngFunc_SetModel, Ent, oberon_bomb_model)
	set_pev(Ent, pev_origin, StartOrigin)
	set_pev(Ent, pev_angles, Angles)
	set_pev(Ent, pev_v_angle, Angles)
	set_pev(Ent, pev_owner, pev(OBERON,pev_owner))
	
	// Set Size
	new Float:maxs[3] = {1.0, 1.0, 1.0}
	new Float:mins[3] = {-1.0, -1.0, -1.0}
	engfunc(EngFunc_SetSize, Ent, mins, maxs)	
	
	// Create Velocity
	static Float:Velocity[3]
	
	get_speed_vector(StartOrigin, TargetOrigin, random_float(700.0, 800.0), Velocity)
	//VelocityByAim(Ent, random_num(500, 2500), Velocity)
	
	set_pev(Ent, pev_velocity, Velocity)
}

public fw_Grenade_Touch(ent, id)
{
	if(!pev_valid(ent))
		return
		
	new Classname[32]
	if(pev_valid(id)) pev(id, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, "oberon_bomb") || equal(Classname, OBERON_CLASSNAME))
		return
		
	Make_Explosion(ent, pev(ent,pev_owner))
	remove_entity(ent)
}

public Make_Explosion(ent,killer)
{
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_expspr_id)	// sprite index
	write_byte(25)	// scale in 0.1's
	write_byte(random_num(20,30))	// framerate
	write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOPARTICLES)	// flags
	message_end()
	
	static Float:Origin2[3]	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(i==pev(ent, pev_owner))
			continue
		pev(i, pev_origin, Origin2)
		if(get_distance_f(Origin, Origin2) > 200.0)
			continue

		ExecuteHamB(Ham_TakeDamage, i, killer, killer, OBERON_ATTACK_BOMB_DAMAGE, DMG_BULLET)
		Make_PlayerShake(i)
	}
}

public OBERON_Death(ent)
{
	if(!pev_valid(ent))
		return
	
	remove_task(ent+TASK_ATTACK)
	remove_task(ent+TASK_GAME_START)	
	remove_entity_name("hole_hook")
	
	set_entity_anim(ent, OBERON_ANIM_DEATH, 1.0)
	
	set_pev(ent, pev_state, OBERON_STATE_DEATH)
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	
	set_task(0.3, "OBERON_Death_Sound", ent)	
	set_task(10.0, "OBERON_Death2", ent)
}

public OBERON_Death2(ent)
{	
	if(!pev_valid(ent))
		return
	
	new id; id = pev(ent, pev_owner)
	set_pev(id, pev_solid, SOLID_BBOX)
	set_pev(id, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(id, pev_takedamage, DAMAGE_YES)
	user_kill(id,1)
}

public OBERON_Death_Sound(ent) PlaySound(0, Oberon_Sound[0])

public Make_PlayerShake(id)
{
	if(!id) 
	{
		message_begin(MSG_BROADCAST, g_Msg_ScreenShake)
		write_short(8<<12)
		write_short(5<<12)
		write_short(4<<12)
		message_end()
	} else {
		if(!is_user_connected(id))
			return
			
		message_begin(MSG_BROADCAST, g_Msg_ScreenShake, _, id)
		write_short(8<<12)
		write_short(5<<12)
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
