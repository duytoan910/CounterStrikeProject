#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN "[CSO] Fallen Titan"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define FT_MODEL "models/zombie_plague/boss/fallentitan.mdl"
#define FT_MINE "models/zombie_plague/boss/titan_m14.mdl"
#define FT_CLASSNAME "NPC_FALLENTITAN"
#define MINE_CLASSNAME "ft_landmine"

#define CANNON_MODEL "models/grenade.mdl"

//#define FT_HEALTH 250000.0
#define FT_SPEED 350.0

#define HEALTH_OFFSET 50000.0

#define FT_ATTACK_RANGE 150.0
#define ATTACK1_RADIUS 200.0
#define ATTACK2_RADIUS 200.0
#define ATTACK_DAMAGE random_float(460.0, 700.0)
#define FT_ATTACK_CANNON_DAMAGE random_float(150.0, 250.0)

new const FT_Sounds[18][] = 
{
	"zombie_plague/boss/fallentitan/death.wav",	
	"zombie_plague/boss/boss_footstep_1.wav",
	"zombie_plague/boss/boss_footstep_2.wav",		//2
	"zombie_plague/boss/fallentitan/landmine_drop1.wav",	//3
	"zombie_plague/boss/fallentitan/landmine_drop2.wav",	//4
	"zombie_plague/boss/fallentitan/landmine_drop3.wav",	//5
	"zombie_plague/boss/fallentitan/landmine_drop4.wav",	//6
	"zombie_plague/boss/fallentitan/landmine_exp.wav",	//7
	"zombie_plague/boss/fallentitan/landmine_jut.wav",	//8
	"zombie_plague/boss/fallentitan/scene_appear1.wav",	//9
	"zombie_plague/boss/fallentitan/scene_appear3.wav",	//10
	"zombie_plague/boss/fallentitan/scene_howling.wav",	//11
	"zombie_plague/boss/fallentitan/zbs_attack1.wav",	//12
	"zombie_plague/boss/fallentitan/zbs_attack2.wav",	//13
	"zombie_plague/boss/fallentitan/zbs_cannon_ready.wav",	//14
	"zombie_plague/boss/fallentitan/zbs_cannon1.wav",	//15
	"zombie_plague/boss/fallentitan/zbs_idle1.wav",		//16
	"zombie_plague/boss/fallentitan/zbs_landmine1.wav"	//17
}

enum
{
	FT_ANIM_DUMMY = 0,
	FT_ANIM_SCENE_APPEAR1,
	FT_ANIM_SCENE_APPEAR2,
	FT_ANIM_SCENE_APPEAR3,
	FT_ANIM_HOWLING,
	FT_ANIM_IDLE,
	FT_ANIM_WALK,
	FT_ANIM_RUN,
	FT_ANIM_DASH_BEGIN,
	FT_ANIM_DASH_ING,
	FT_ANIM_DASH_END,
	FT_ANIM_ATTACK1,
	FT_ANIM_ATTACK2,
	FT_ANIM_CANNON_BEGIN,
	FT_ANIM_CANNON_ING,
	FT_ANIM_CANNON_END,
	FT_ANIM_CANNON_SPECIAL,
	FT_ANIM_LANDMINE1,
	FT_ANIM_LANDMINE2,
	FT_ANIM_DEATH
}

enum
{
	FT_STATE_IDLE = 0,
	FT_STATE_APPEARING1,
	FT_STATE_APPEARING2,
	FT_STATE_APPEARING3,
	FT_STATE_APPEARING4,
	FT_STATE_SEARCHING_ENEMY,
	FT_STATE_CHASE_ENEMY,
	FT_STATE_ATTACK_NORMAL,
	FT_STATE_ATTACK_DASH,
	FT_STATE_ATTACK_CANNON,
	FT_STATE_ATTACK_CANNON_2,
	FT_STATE_ATTACK_MINE,
	FT_STATE_ATTACK_MINE_2,
	FT_STATE_DEATH
}
#define TASK_GAME_START 27015
#define TASK_ATTACK 27016

enum EntityData
{
	EntID,
	Float:EntityOrigin[3]
}

const pev_state = pev_iuser1
const pev_laststate = pev_iuser2
const pev_time = pev_fuser1
const pev_time2 = pev_fuser2
const pev_time3 = pev_fuser3

new g_CurrentBoss_Ent, g_Reg_Ham, Float:last_bomb, Float:last_mine, Float:FT_HEALTH
new g_Msg_ScreenShake, g_MaxPlayers, g_FootStep, spr_trail, g_expspr_id

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_think(MINE_CLASSNAME, "fw_Mine_Think")
	register_touch(MINE_CLASSNAME, "*", "fw_Mine_Touch")	
	
	register_think(FT_CLASSNAME, "fw_FT_Think")
	register_touch("grenade2", "*", "fw_Grenade_Touch")
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	g_Msg_ScreenShake = get_user_msgid("ScreenShake")
	g_MaxPlayers = get_maxplayers()
}
public plugin_natives()
{
	register_native("Create_FallenTitan","Create_Boss",1)
}
public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, FT_MODEL)
	engfunc(EngFunc_PrecacheModel, FT_MINE)
	engfunc(EngFunc_PrecacheModel, CANNON_MODEL)
	
	for(new i = 0; i < sizeof(FT_Sounds); i++)
		engfunc(EngFunc_PrecacheSound, FT_Sounds[i])	
	
	spr_trail = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr") 
	g_expspr_id = engfunc(EngFunc_PrecacheModel, "sprites/flame_puff01.spr")	
}
public Event_NewRound()
{
	remove_task(TASK_GAME_START)
	remove_entity_name(MINE_CLASSNAME)
}
public logevent_round_end()
{
	remove_task(g_CurrentBoss_Ent+TASK_ATTACK)	
}
public Create_Boss(id, Float:HP)
{
	if(pev_valid(g_CurrentBoss_Ent))
		engfunc(EngFunc_RemoveEntity, g_CurrentBoss_Ent)
	
	static FT; FT = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(FT)) return -1
	
	g_CurrentBoss_Ent = FT
	FT_HEALTH = HP
	
	static Float:StartOrigin[3]	
	pev(id, pev_origin, StartOrigin)
	set_pev(FT, pev_origin, StartOrigin)
	
	static Float:Angles[3]	
	pev(id, pev_angles, Angles)
	set_pev(FT, pev_angles, Angles)
	set_pev(FT, pev_v_angle, Angles)
	
	// Set Config
	entity_set_string(FT, EV_SZ_classname,FT_CLASSNAME)
	entity_set_model(FT, FT_MODEL)
	set_pev(FT, pev_skin, random_num(0,1))
		
	set_pev(FT, pev_gamestate, 1)
	entity_set_int(FT, EV_INT_solid, SOLID_BBOX)
	entity_set_int(FT, EV_INT_movetype, MOVETYPE_PUSHSTEP)

	// Set Size
	new Float:maxs[3] = {67.0, 67.0, 150.0}
	new Float:mins[3] = {-67.0, -67.0, -35.0}	
	engfunc(EngFunc_SetSize, FT, mins, maxs)
	
	// Set Life
	set_pev(FT, pev_takedamage, DAMAGE_YES)
	set_pev(FT, pev_health, HEALTH_OFFSET + FT_HEALTH)
	
	// Set Config 2
	set_pev(FT, pev_owner, id)
	set_entity_anim(FT, FT_ANIM_IDLE, 1.0)
	set_pev(FT, pev_state, FT_STATE_APPEARING3)
	set_pev(FT, pev_laststate, -1)

	set_pev(FT, pev_nextthink, get_gametime() + 1.0)
	engfunc(EngFunc_DropToFloor, FT)
	
	set_pev(FT, pev_time2, get_gametime() + 1.0)
	
	if(!g_Reg_Ham)
	{
		g_Reg_Ham = 1
		RegisterHamFromEntity(Ham_TraceAttack, FT, "fw_FT_TraceAttack", 1)
		//RegisterHamFromEntity(Ham_TakeDamage, FT, "fw_FT_TakeAttack")
	}
	return FT;
}

public fw_FT_Think(ent)
{
	if(!pev_valid(ent))
		return
	if(pev(ent, pev_state) == FT_STATE_DEATH)
		return
	if((pev(ent, pev_health) - HEALTH_OFFSET) <= 0.0)
	{
		set_pev(ent, pev_takedamage, DAMAGE_NO)
		FT_Death(ent)
		return
	}
	switch(pev(ent, pev_state))
	{
		case FT_STATE_IDLE:
		{
			if(get_gametime() - 3.3 > pev(ent, pev_time))
			{
				set_entity_anim(ent, FT_ANIM_IDLE, 1.0)
				//PlaySound(0, FT_Sounds[16])
				
				set_pev(ent, pev_time, get_gametime())
			}
			if(get_gametime() - 1.0 > pev(ent, pev_time2))
			{
				set_pev(ent, pev_state, FT_STATE_SEARCHING_ENEMY)
				set_pev(ent, pev_time2, get_gametime())
			}	
			
			// Set Next Think
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case FT_STATE_APPEARING1:
		{
			static Float:Ahead[3]
			get_position(ent, 1000.0, 0.0, 0.0, Ahead)

			MM_Aim_To(ent, Ahead)
			hook_ent2(ent, Ahead, FT_SPEED - 200.0)
			
			if(get_gametime() - 4.76 > pev(ent, pev_time))
			{
				set_entity_anim(ent, FT_ANIM_WALK, 1.0)
				set_pev(ent, pev_time, get_gametime())
			}	
			if(get_gametime() - 1.0 > pev(ent, pev_time3))
			{
				if(g_FootStep != 1) g_FootStep = 1
				else g_FootStep = 2
				PlaySound(0, FT_Sounds[g_FootStep == 1 ? 1 : 2])
				
				set_pev(ent, pev_time3, get_gametime())
			}
			if(get_gametime() - 5.0 > pev(ent, pev_time2))
			{
				set_pev(ent, pev_state, FT_STATE_APPEARING2)
				set_pev(ent, pev_time, get_gametime())
			}
			for(new i = 0; i < g_MaxPlayers; i++)
			{
				if(!is_user_alive(i))
					continue
				if(entity_range(ent, i) > 90)
					continue
					
				static Float:Velocity[3]
				Velocity[0] = random_float(-500.0, 500.0)
				Velocity[1] = random_float(-500.0, 500.0)
				Velocity[2] = random_float(500.0, 600.0)
				set_pev(i, pev_velocity, Velocity)
			}
			// Set Next Think
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case FT_STATE_APPEARING2:
		{
			set_entity_anim(ent, FT_ANIM_IDLE, 1.0)

			set_pev(ent, pev_state, FT_STATE_APPEARING3)
			set_pev(ent, pev_nextthink, get_gametime() + 0.5)
		}
		case FT_STATE_APPEARING3:
		{
			set_pev(ent, pev_movetype, MOVETYPE_NONE)
			set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})
			
			set_pev(ent, pev_state, FT_STATE_APPEARING4)
			set_pev(ent, pev_nextthink, get_gametime() + 0.01)
		}
		case FT_STATE_APPEARING4:
		{
			set_entity_anim(ent, FT_ANIM_HOWLING, 1.0)
			PlaySound(0, FT_Sounds[11])
			set_task(0.75, "Make_PlayerShake", 0)
			
			set_pev(ent, pev_state, FT_STATE_IDLE)
			set_pev(ent, pev_nextthink, get_gametime() + 4.6)
		}
		case FT_STATE_SEARCHING_ENEMY:
		{
			static Victim;
			Victim = FindClosetEnemy(ent, 0)
			
			if(is_user_alive(Victim))
			{
				set_pev(ent, pev_enemy, Victim)
				Random_AttackMethod(ent)
			} else {
				set_pev(ent, pev_enemy, 0)
				set_pev(ent, pev_state, FT_STATE_IDLE)
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case FT_STATE_CHASE_ENEMY:
		{
			static Enemy; Enemy = pev(ent, pev_enemy)
			static Float:EnemyOrigin[3]
			pev(Enemy, pev_origin, EnemyOrigin)	
			if(is_user_alive(Enemy))
			{
				if(entity_range(Enemy, ent) <= floatround(FT_ATTACK_RANGE))
				{
					set_pev(ent, pev_state, FT_STATE_ATTACK_NORMAL)
					
					MM_Aim_To(ent, EnemyOrigin) 
					
					new ran = random_num(0, 10)					
					switch(ran)
					{
						case 0..4: set_task(0.1, "FT_StartAttack1", ent+TASK_ATTACK)
						case 5..9: set_task(0.1, "FT_StartAttack2", ent+TASK_ATTACK)
						case 10: FT_Attack_Cannon2(ent)
					}
				} else {
					if(pev(ent, pev_movetype) == MOVETYPE_PUSHSTEP)
					{
						static Float:OriginAhead[3]
						get_position(ent, 300.0, 0.0, 0.0, OriginAhead)
						
						MM_Aim_To(ent, EnemyOrigin) 
						hook_ent2(ent, OriginAhead, FT_SPEED + 30.0)
						
						set_entity_anim2(ent, FT_ANIM_RUN, 1.0)
						
						if(get_gametime() - 1.0 > pev(ent, pev_time3))
						{
							if(g_FootStep != 1) g_FootStep = 1
							else g_FootStep = 2
						
							PlaySound(0, FT_Sounds[g_FootStep == 1 ? 1 : 2])
							
							set_pev(ent, pev_time3, get_gametime())
						}
						
						if(get_gametime() - 4.0 > pev(ent, pev_time2))
						{
							new rand = random_num(0, 6)
							if(rand == 1)
								FT_Attack_Dash(ent)
							else if(rand == 2) FT_Attack_Cannon(ent)	
							//else if(rand == 3) FT_Attack_Cannon2(ent)	
							else if(rand == 3) FT_Attack_Mine_2(ent)	
							else if(rand == 4) FT_Attack_Mine(ent)
							
							set_pev(ent, pev_time2, get_gametime())
						}
					} else {
						set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
					}
				}
			} else {
				set_pev(ent, pev_state, FT_STATE_SEARCHING_ENEMY)
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}	
		case (FT_STATE_ATTACK_DASH + 1000):
		{
			static Float:Ahead[3], Float:CheckOrigin[3]
			get_position(ent, 1000.0, 0.0, 0.0, Ahead)

			MM_Aim_To(ent, Ahead)
			hook_ent2(ent, Ahead, FT_SPEED * 5.0)	
			
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
					
				ExecuteHam(Ham_TakeDamage, i, pev(ent,pev_owner), pev(ent,pev_owner), ATTACK_DAMAGE, DMG_BULLET)
				
				static Float:Velocity[3]
				Velocity[0] = random_float(-900.0, 900.0)
				Velocity[1] = random_float(-900.0, 900.0)
				Velocity[2] = random_float(800.0, 900.0)
				set_pev(i, pev_velocity, Velocity)
			}
			
			if(get_gametime() - 1.0 > pev(ent, pev_time3))
			{
				if(g_FootStep != 1) g_FootStep = 1
				else g_FootStep = 2
			
				PlaySound(0, FT_Sounds[g_FootStep == 1 ? 1 : 2])
				
				set_pev(ent, pev_time3, get_gametime())
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
	}
}
public fw_FT_TraceAttack(Ent, Attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	if(!is_valid_ent(Ent)) 
		return
     
	static Classname[32]
	pev(Ent, pev_classname, Classname, charsmax(Classname)) 
	     
	if(!equal(Classname, FT_CLASSNAME)) 
		return
		
	new owner;owner=pev(Ent,pev_owner)
	if(pev(owner, pev_health)>200.0)
	{
		set_pev(owner, pev_health, pev(Ent, pev_health) - HEALTH_OFFSET)
	}
	else set_pev(owner, pev_health, 1.0)
}

public Random_AttackMethod(ent)
{
	static RandomNum; RandomNum = random_num(0, 120)
	
	if(RandomNum > 0 && RandomNum <= 60)
	{
		set_pev(ent, pev_time, get_gametime())
		set_pev(ent, pev_state, FT_STATE_CHASE_ENEMY)
	}
	else if(RandomNum >= 61 && RandomNum <= 80)
		FT_Attack_Dash(ent)
	else if(RandomNum >= 81 && RandomNum <= 100)
		FT_Attack_Cannon(ent)
	else if(RandomNum >= 101 && RandomNum <= 110)
		FT_Attack_Mine(ent)
	else if(RandomNum >= 111 && RandomNum < 130)
		FT_Attack_Mine_2(ent)
	else
		Random_AttackMethod(ent)
}

public FT_StartAttack1(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	

	set_task(0.1, "FT_StartAttack1_2", ent+TASK_ATTACK)
}

public FT_StartAttack2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	

	set_task(0.1, "FT_StartAttack2_2", ent+TASK_ATTACK)	
}

public FT_StartAttack1_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_entity_anim(ent, FT_ANIM_ATTACK1, 1.0)
	PlaySound(0, FT_Sounds[12])
	
	set_task(1.5, "FT_CheckAttack1", ent+TASK_ATTACK)
	set_task(3.2, "FT_DoneAttack", ent+TASK_ATTACK)	
}

public FT_StartAttack2_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_entity_anim(ent, FT_ANIM_ATTACK2, 1.0)
	PlaySound(0, FT_Sounds[13])
	
	set_task(1.0, "FT_CheckAttack2", ent+TASK_ATTACK)
	set_task(3.2, "FT_DoneAttack", ent+TASK_ATTACK)	
}

public FT_CheckAttack1(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	static Float:CheckPosition[3], Float:VicOrigin[3]
	get_position(ent, 80.0, 10.0, 0.0, CheckPosition)
		
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
		
		static Float:Velocity[3]
		Velocity[0] = random_float(200.0, 200.0)
		Velocity[1] = random_float(200.0, 200.0)
		Velocity[2] = random_float(800.0, 900.0)
		set_pev(i, pev_velocity, Velocity)
		
		Make_PlayerShake(i)
	}
}

public FT_CheckAttack2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return

	static Float:CheckPosition[3], Float:VicOrigin[3]
	get_position(ent, 10.0, 10.0, 0.0, CheckPosition)
		
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
		Velocity[0] = random_float(10.0, 50.0)
		Velocity[1] = random_float(10.0, 50.0)
		Velocity[2] = random_float(800.0, 900.0)
		set_pev(i, pev_velocity, Velocity)
		Make_PlayerShake(i)
	}	
}

public FT_DoneAttack(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, FT_STATE_CHASE_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public FT_Attack_Dash(ent)
{
	if(!pev_valid(ent))
		return	
	if(pev(ent, pev_laststate) == FT_STATE_ATTACK_DASH)	
	{
		set_pev(ent, pev_state, FT_STATE_SEARCHING_ENEMY)		
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		return
	}
	if(pev(ent, pev_state) == FT_STATE_CHASE_ENEMY || pev(ent, pev_state) == FT_STATE_IDLE)
	{
		set_pev(ent, pev_state, FT_STATE_ATTACK_DASH)
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		set_pev(ent, pev_enemy, FindFarestEnemy(ent,0))
		set_task(0.1, "FT_Start_Attack_Dash", ent+TASK_ATTACK)	
	}
}

public FT_Start_Attack_Dash(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	

	set_pev(ent, pev_enemy, FindFarestEnemy(ent,0))
	
	new Float:EnemyOrigin[3],Enemy;Enemy = pev(ent, pev_enemy)
	pev(Enemy, pev_origin, EnemyOrigin)
	MM_Aim_To(ent, EnemyOrigin)	
	
	set_entity_anim(ent, FT_ANIM_DASH_BEGIN, 1.0)
	set_task(1.3, "FT_Start_Dashing", ent+TASK_ATTACK)
}

public Reset_MoveType(ent)
{
	if(!pev_valid(ent))
		return		
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
}

public FT_Start_Dashing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	new Float:EnemyOrigin[3],Enemy;Enemy = pev(ent, pev_enemy)
	pev(Enemy, pev_origin, EnemyOrigin)
	MM_Aim_To(ent, EnemyOrigin)	
	
	set_entity_anim(ent, FT_ANIM_DASH_ING, 1.0)
	set_pev(ent, pev_state, FT_STATE_ATTACK_DASH + 1000)
	
	set_task(0.1, "Reset_MoveType", ent)
	set_task(1.0, "FT_Stop_Dashing", ent+TASK_ATTACK)
	set_pev(ent, pev_nextthink, get_gametime() + 0.2)
}

public FT_Stop_Dashing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_entity_anim(ent, FT_ANIM_DASH_END, 1.0)
	set_pev(ent, pev_state, FT_STATE_ATTACK_DASH)
	
	set_task(1.2, "FT_End_Dashing", ent+TASK_ATTACK)
}

public FT_End_Dashing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
	
	set_pev(ent, pev_laststate, FT_STATE_ATTACK_DASH)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)		
	set_pev(ent, pev_state, FT_STATE_SEARCHING_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public FT_Attack_Cannon(ent)
{
	if(!pev_valid(ent))
		return	
	if(pev(ent, pev_laststate) == FT_STATE_ATTACK_CANNON)	
	{
		set_pev(ent, pev_state, FT_STATE_SEARCHING_ENEMY)		
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		return
	}
	if(pev(ent, pev_state) == FT_STATE_CHASE_ENEMY || pev(ent, pev_state) == FT_STATE_IDLE)
	{
		set_pev(ent, pev_state, FT_STATE_ATTACK_CANNON)
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		
		set_task(0.1, "FT_Start_Attack_Cannon", ent+TASK_ATTACK)	
	}
}

public FT_Start_Attack_Cannon(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return		
		
	set_entity_anim(ent, FT_ANIM_CANNON_BEGIN, 1.0)
	set_task(0.6, "Cannon_StartSound")
	set_task(1.43, "FT_Attacking_Cannon", ent+TASK_ATTACK)
}

public Cannon_StartSound() PlaySound(0, FT_Sounds[14])

public FT_Attacking_Cannon(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_entity_anim(ent, FT_ANIM_CANNON_ING, 1.0)
	set_pev(ent, pev_state, FT_STATE_ATTACK_CANNON + 1000)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	
	set_task(0.15, "FT_Shoot_Cannon", ent+TASK_ATTACK, _, _, "b")
	set_task(3.0, "FT_Stop_Cannon", ent+TASK_ATTACK)
}

public FT_Shoot_Cannon(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_entity_anim(ent, FT_ANIM_CANNON_ING, 1.0)
	
	static Float:StartOrigin[3], Float:TargetOrigin[3][3], Float:Angles[3]
	pev(ent, pev_angles, Angles)
	set_pev(ent, pev_v_angle, Angles)
	
	get_position(ent, 50.0, -50.0, 80.0, StartOrigin)
	
	static Enemy; Enemy = pev(ent, pev_enemy)
	get_position(Enemy, random_float(-50.0, 50.0), random_float(-50.0, 50.0), random_float(-5.0, 40.0), TargetOrigin[0])
	get_position(Enemy, random_float(-50.0, 50.0), random_float(-50.0, 50.0), random_float(-5.0, 40.0), TargetOrigin[1])
	get_position(Enemy, random_float(-50.0, 50.0), random_float(-50.0, 50.0), random_float(-5.0, 40.0), TargetOrigin[2])
	
	pev(ent, pev_angles, Angles)
	
	static Float:EnemyOrigin[3]
	for(new i = 0; i < 1; i++)
	{			
		pev(Enemy, pev_origin, EnemyOrigin)
		MM_Aim_To(ent, EnemyOrigin)
		Shoot_Cannon(ent, StartOrigin, Angles, TargetOrigin[i], 0)		
	}
}

public Shoot_Cannon(FT, Float:StartOrigin[3], Float:Angles[3], Float:TargetOrigin[3], special)
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return
	
	set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(Ent, pev_solid, SOLID_TRIGGER)
	
	set_pev(Ent, pev_classname, "grenade2")
	engfunc(EngFunc_SetModel, Ent, CANNON_MODEL)
	set_pev(Ent, pev_origin, StartOrigin)
	set_pev(Ent, pev_angles, Angles)
	set_pev(Ent, pev_v_angle, Angles)
	set_pev(Ent, pev_owner, pev(FT,pev_owner))
	
	// Set Size
	new Float:maxs[3] = {1.0, 1.0, 1.0}
	new Float:mins[3] = {-1.0, -1.0, -1.0}
	engfunc(EngFunc_SetSize, Ent, mins, maxs)	
	
	// Create Velocity
	static Float:Velocity[3]
	if(special)
		get_speed_vector(StartOrigin, TargetOrigin, random_float(400.0, 600.0), Velocity)
	else get_speed_vector(StartOrigin, TargetOrigin, random_float(1700.0,2000.0), Velocity)
	//VelocityByAim(Ent, random_num(500, 2500), Velocity)
	
	set_pev(Ent, pev_velocity, Velocity)
	
	// Make a Beam
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(Ent) // entity
	write_short(spr_trail) // sprite
	write_byte(10)  // life
	write_byte(5)  // width
	write_byte(200) // r
	write_byte(200);  // g
	write_byte(200);  // b
	write_byte(200); // brightness
	message_end();	
}

public fw_Grenade_Touch(ent, id)
{
	if(!pev_valid(ent))
		return
		
	new Classname[32]
	if(pev_valid(id)) pev(id, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, "grenade2") || equal(Classname, FT_CLASSNAME))
		return
		
	Make_Explosion(ent, pev(ent,pev_owner))
}

public Make_Explosion(ent,killer)
{
	static i, Float:Origin[3], Float:Origin2[3]	
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
	
	for(i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		if(i==pev(ent, pev_owner))
			continue		
			
		pev(i, pev_origin, Origin2)
		if(get_distance_f(Origin, Origin2) > 200.0)
			continue

		ExecuteHamB(Ham_TakeDamage, i, killer, killer, FT_ATTACK_CANNON_DAMAGE, DMG_BULLET)
		Make_PlayerShake(i)
	}
	set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
}


public FT_Stop_Cannon(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return		
	
	remove_task(ent+TASK_ATTACK)

	set_pev(ent, pev_state, FT_STATE_ATTACK_CANNON)
	set_entity_anim(ent, FT_ANIM_CANNON_END, 1.0)
	
	set_task(0.9, "FT_End_Cannon", ent+TASK_ATTACK)
}

public FT_End_Cannon(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_laststate, FT_STATE_ATTACK_CANNON)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, FT_STATE_SEARCHING_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
}

public FT_Attack_Cannon2(ent)
{
	if(!pev_valid(ent))
		return	
	if(pev(ent, pev_laststate) == FT_STATE_ATTACK_CANNON_2)	
	{
		set_pev(ent, pev_state, FT_STATE_CHASE_ENEMY)		
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		return
	}
	set_pev(ent, pev_state, FT_STATE_ATTACK_CANNON_2)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	
	set_task(0.1, "FT_Start_Attack_Cannon2", ent+TASK_ATTACK)	
}
public FT_Start_Attack_Cannon2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return		
		
	last_bomb=330.0
	set_entity_anim(ent, FT_ANIM_CANNON_SPECIAL, 1.0)
	set_task(0.2, "Cannon2_StartSound")
	set_task(0.6, "FT_Attacking_Cannon2", ent+TASK_ATTACK)
	set_task(3.5, "FT_Attacking_Cannon2_2", ent+TASK_ATTACK)
	set_task(4.5, "FT_Stop_Cannon2", ent+TASK_ATTACK)
}

public Cannon2_StartSound() PlaySound(0, FT_Sounds[11])

public FT_Attacking_Cannon2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	

	set_pev(ent, pev_state, FT_STATE_ATTACK_CANNON_2 + 1000)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	
	set_task(0.2, "FT_Shoot_Cannon2", ent+TASK_ATTACK, _, _, "b")
}
public FT_Attacking_Cannon2_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	

	set_pev(ent, pev_state, FT_STATE_ATTACK_CANNON_2 + 1000)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	
	set_task(0.25, "FT_Shoot_Cannon2_2", ent+TASK_ATTACK, _, _, "b")
}
public FT_Shoot_Cannon2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	new Float:StartOrigin[3], Float:TargetOrigin[3], Float:Angles[3]		
	//engfunc(EngFunc_GetAttachment, ent, 0, StartOrigin,Angles)
	
	get_position(ent, 50.0, -10.0, 100.0, StartOrigin)
	
	last_bomb-=40.0	
	StartOrigin[2] += 50.0
	get_position(ent, 200.0, last_bomb, 450.0, TargetOrigin)
	
	pev(ent, pev_angles, Angles)
	Shoot_Cannon(ent, StartOrigin, Angles, TargetOrigin, 1)
}

public FT_Shoot_Cannon2_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	new Float:StartOrigin[3], Float:TargetOrigin[3], Float:Angles[3]	
	//engfunc(EngFunc_GetAttachment, ent, 0, StartOrigin,Angles)	
	
	get_position(ent, 40.0, -15.0, 120.0, StartOrigin)
	
	get_position(ent, 200.0, last_bomb, 550.0, TargetOrigin)
	pev(ent, pev_angles, Angles)
	Shoot_Cannon(ent, StartOrigin, Angles, TargetOrigin, 1)
}
public FT_Stop_Cannon2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return		
	
	remove_task(ent+TASK_ATTACK)	
	set_pev(ent, pev_state, FT_STATE_ATTACK_CANNON_2)
	set_task(0.5, "FT_End_Cannon2", ent+TASK_ATTACK)
}

public FT_End_Cannon2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	

	set_pev(ent, pev_laststate, FT_STATE_ATTACK_CANNON_2)	
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, FT_STATE_CHASE_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
}

public FT_Attack_Mine(ent)
{
	if(!pev_valid(ent))
		return	
	if(pev(ent, pev_laststate) == FT_STATE_ATTACK_MINE)
	{
		set_pev(ent, pev_state, FT_STATE_SEARCHING_ENEMY)		
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		return
	}
	if(pev(ent, pev_state) == FT_STATE_SEARCHING_ENEMY || pev(ent, pev_state) == FT_STATE_IDLE)
	{
		set_pev(ent, pev_state, FT_STATE_ATTACK_MINE)
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		
		set_task(0.1, "FT_Start_Attack_Mine", ent+TASK_ATTACK)	
	}
}

public FT_Start_Attack_Mine(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return		
		
	set_entity_anim(ent, FT_ANIM_LANDMINE1, 1.0)
	
	//set_pev(ent, pev_state, FT_STATE_ATTACK_MINE + 1000)
	//set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	
	set_task(1.2, "FT_Mine_Sound")
	set_task(1.0, "FT_Attacking_Mine", ent+TASK_ATTACK)
	set_task(4.95, "FT_End_Mine", ent+TASK_ATTACK)
}
public FT_Mine_Sound() PlaySound(0, FT_Sounds[17])
public FT_Attacking_Mine(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
	
	last_mine=-50.0
	set_task(0.1, "FT_Shoot_Mine", ent+TASK_ATTACK)
}

public FT_Shoot_Mine(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
	
	static Float:StartOrigin[3], Float:Angles[3], Float:TargetOrigin[3]
	pev(ent, pev_angles, Angles)
	
	get_position(ent, 0.0, 0.0, 100.0, StartOrigin)	
	pev(ent, pev_angles, Angles)
	for(new i = 0; i < 15; i++)
	{			
		get_position(ent, random_float(-600.0, 600.0), random_float(last_mine-350, last_mine+350), random_float(400.0,450.0), TargetOrigin)
			
		Shoot_Mine(ent, StartOrigin, Angles, TargetOrigin)
		last_mine+=90
	}	
}
public FT_End_Mine(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	

	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, FT_STATE_SEARCHING_ENEMY)
	set_pev(ent, pev_laststate , FT_STATE_ATTACK_MINE)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
}

public Shoot_Mine(FT, Float:StartOrigin[3], Float:Angles[3], Float:TargetOrigin[3])
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return
	
	set_pev(Ent, pev_movetype, MOVETYPE_TOSS)
	set_pev(Ent, pev_solid, SOLID_TRIGGER)
	
	set_pev(Ent, pev_classname, MINE_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, FT_MINE)
	set_pev(Ent, pev_origin, StartOrigin)
	set_pev(Ent, pev_angles, Angles)
	set_pev(Ent, pev_v_angle, Angles)
	set_pev(Ent, pev_owner, pev(FT,pev_owner))
	set_pev(Ent, pev_fuser4, -1.0)
	set_pev(Ent, pev_iuser4, 1)
	
	// Set Size
	new Float:maxs[3] = {1.0, 1.0, 1.0}
	new Float:mins[3] = {-1.0, -1.0, -1.0}
	engfunc(EngFunc_SetSize, Ent, mins, maxs)	
	
	// Create Velocity
	static Float:Velocity[3]
	get_speed_vector(StartOrigin, TargetOrigin, random_float(500.0, 700.0), Velocity)
	
	set_pev(Ent, pev_velocity, Velocity)
	set_pev(Ent, pev_nextthink, get_gametime() + 0.01)
}
public FT_Attack_Mine_2(ent)
{
	if(!pev_valid(ent))
		return	
	if(pev(ent, pev_laststate) == FT_STATE_ATTACK_MINE_2)	
	{
		set_pev(ent, pev_state, FT_STATE_SEARCHING_ENEMY)		
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		return
	}
	if(pev(ent, pev_state) == FT_STATE_SEARCHING_ENEMY || pev(ent, pev_state) == FT_STATE_IDLE)
	{
		new Float:EnemyOrigin[3],Enemy;Enemy = FindFarestEnemy(ent, 0)
		pev(Enemy, pev_origin, EnemyOrigin)
		MM_Aim_To(ent, EnemyOrigin)
		
		set_pev(ent, pev_state, FT_STATE_ATTACK_MINE_2)
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		
		set_entity_anim(ent, FT_ANIM_LANDMINE2, 1.0)
		set_task(1.2, "FT_Shoot_Mine_2", ent+TASK_ATTACK)
		set_task(5.0, "FT_End_Mine_2", ent+TASK_ATTACK)
	}
}

public FT_Shoot_Mine_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	static Float:StartOrigin[3][3]	
	new edData[EntityData];
	
	PlaySound(0, FT_Sounds[8])
	
	for(new i = 0; i < 11; i++)
	{		
		if(i<0) continue
		
		get_position(ent, i*90.0+100.0, 35.0, -35.0, StartOrigin[0])
		get_position(ent, i*90.0+100.0, (i*-15.0)+35.0, -35.0, StartOrigin[1])
		get_position(ent, i*90.0+100.0, (i*15.0)+35.0, -35.0, StartOrigin[2])		
		
		for(new j=0;j<3;j++)
		{
			edData[EntID] = ent;
			edData[EntityOrigin][0] = 0
			edData[EntityOrigin][1] = 0
			edData[EntityOrigin][2] = 0
			edData[EntityOrigin][0] += StartOrigin[j][0]
			edData[EntityOrigin][1] += StartOrigin[j][1]
			edData[EntityOrigin][2] += StartOrigin[j][2]
		
			set_task(0.1 * i , "Shoot_Mine_2", 12345, edData[EntID], sizeof(edData))
		}
	}		
}

public Shoot_Mine_2(EntData[EntityData])
{	
	new Float:fStartOrigin[3]	
	new FT = EntData[EntID]
	
	fStartOrigin[0] = EntData[EntityOrigin][0];
	fStartOrigin[1] = EntData[EntityOrigin][1];
	fStartOrigin[2] = EntData[EntityOrigin][2];
	
	fStartOrigin[0] += random_float(-30.0,30.0)
	fStartOrigin[1] += random_float(-30.0,30.0)
	
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return
	
	set_pev(Ent, pev_movetype, MOVETYPE_TOSS)
	set_pev(Ent, pev_solid, SOLID_TRIGGER)
	
	set_pev(Ent, pev_classname, MINE_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, FT_MINE)
	set_pev(Ent, pev_origin, fStartOrigin)
	set_pev(Ent, pev_owner, pev(FT,pev_owner))
	set_pev(Ent, pev_fuser4, -1.0)
	set_pev(Ent, pev_iuser4, 0)
	
	// Set Size
	new Float:maxs[3] = {1.0, 1.0, 1.0}
	new Float:mins[3] = {-1.0, -1.0, -1.0}
	engfunc(EngFunc_SetSize, Ent, mins, maxs)	
	
	// Create Velocity
	static Float:Velocity[3]
	Velocity[0] = 0.0
	Velocity[1] = 0.0
	Velocity[2] = 150.0
	set_pev(Ent, pev_velocity, Velocity)
}
public FT_End_Mine_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	remove_task(ent+TASK_ATTACK)
	set_pev(ent, pev_laststate, FT_STATE_ATTACK_MINE_2)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, FT_STATE_SEARCHING_ENEMY)

	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
}
public fw_Mine_Touch(ent, id)
{
	if(!pev_valid(ent))
		return
		
	new owner = pev(ent, pev_owner), Classname[32];
	if(pev_valid(id)) pev(id, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, MINE_CLASSNAME) || equal(Classname, FT_CLASSNAME))
		return
	
	if(is_user_alive(id))
		Mine_Explosion(ent, owner)
	else{
		set_pev(ent, pev_iuser4, 0)
		
		new Float:Angles[3]
		Angles[1] = random_float(0.0,360.0)
		set_pev(ent, pev_angles, Angles)
		
		engfunc(EngFunc_DropToFloor, ent)	
		
		emit_sound(ent, CHAN_WEAPON, FT_Sounds[random_num(3,6)], 1.0, ATTN_NORM, 0, PITCH_NORM)	
		set_pev(ent, pev_fuser4, get_gametime())		
		set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	}
}

public fw_Mine_Think(ent)
{
	if(!pev_valid(ent)) 
		return

	if(pev(ent , pev_iuser4)==1)
	{
		new Float:Angles[3]
		pev(ent, pev_angles, Angles)
		Angles[0] += random_float(90.0,360.0)
		Angles[1] += random_float(90.0,360.0)
		Angles[2] += random_float(90.0,360.0)
		set_pev(ent, pev_angles, Angles)
	}
	
	if(pev(ent, pev_fuser4)<1.0)
		return;
		
	new owner = pev(ent, pev_owner), Classname[32];
	
	if(pev(ent, pev_fuser4)+10.0 < get_gametime())
	{
		Mine_Explosion(ent, owner)
	}
	
	if(pev(ent, pev_fuser4)+1.0 < get_gametime())
	{	
		static a, Float:Origin[3];
		pev(ent, pev_origin, Origin)
		while((a = find_ent_in_sphere(a, Origin, 20.0)) != 0)
		{
			pev(a, pev_classname, Classname, sizeof(Classname))			
			if(equal(Classname, MINE_CLASSNAME))
				continue
				
			if(equal(Classname, FT_CLASSNAME))
				Mine_Explosion(ent, owner)
				
			if(!is_user_alive(a))
				continue
				
			Mine_Explosion(ent, owner)
		}
	}
	set_pev(ent, pev_nextthink, get_gametime() + 0.01)
}
public Mine_Explosion(ent,killer)
{
	static i, Float:Origin[3], Float:Origin2[3], Float:Velocity[3]	
	pev(ent, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2]+50.0)
	write_short(g_expspr_id)	// sprite index
	write_byte(random_num(25,30))	// scale in 0.1's
	write_byte(random_num(20,30))	// framerate
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOPARTICLES)	// flags
	message_end()	
	
	emit_sound(ent, CHAN_WEAPON, FT_Sounds[7], 1.0, ATTN_NORM, 0, PITCH_NORM)	
	for(i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(i==pev(ent, pev_owner))
			continue
		pev(i, pev_origin, Origin2)
		if(get_distance_f(Origin, Origin2) > 200.0)
			continue

		Velocity[0] = random_float(-120.0, 120.0)
		Velocity[1] = random_float(-120.0, 120.0)
		Velocity[2] = random_float(500.0, 600.0)
		set_pev(i, pev_velocity, Velocity)
		
		ExecuteHamB(Ham_TakeDamage, i, killer, killer, FT_ATTACK_CANNON_DAMAGE*1.5, DMG_BULLET)
		Make_PlayerShake(i)				
	}	
	set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
}
public FT_Death(ent)
{
	if(!pev_valid(ent))
		return
	
	remove_task(ent+TASK_ATTACK)
	remove_task(ent+TASK_GAME_START)
	remove_entity_name(MINE_CLASSNAME)
	
	set_entity_anim(ent, FT_ANIM_DEATH, 1.0)
	
	set_pev(ent, pev_state, FT_STATE_DEATH)
	
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)	
	set_task(0.3, "FT_Death_Sound", ent)
	
	set_task(10.0, "FT_Death2", ent)	
}

public FT_Death2(ent)
{	
	new id; id = pev(ent, pev_owner)
	set_pev(id, pev_solid, SOLID_BBOX)
	set_pev(id, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(id, pev_takedamage, DAMAGE_YES)
	user_kill(id,1)
}

public FT_Death_Sound(ent) PlaySound(0, FT_Sounds[0])

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
