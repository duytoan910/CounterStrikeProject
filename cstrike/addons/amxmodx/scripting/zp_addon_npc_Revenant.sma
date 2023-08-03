#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN "[CSO] Fallen Titan"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define REVENANT_MODEL "models/zombie_plague/boss/revenant.mdl"
#define REVENANT_FIREBALL "models/zombie_plague/boss/fireball.mdl"

#define REVENANT_CLASSNAME "NPC_REVENANT"
#define REVENANT_FIREBALL_CLASSNAME "REVENANT_BALL"
#define REVENANT_FIRE_CLASSNAME "REVENANT_FIRE"

new const Revenant_Sound[][] = {
	"zombie_plague/boss/revenant/firemonster_zbs_death.wav",		//0
	"zombie_plague/boss/revenant/firemonster_zbs_idle1.wav",		//1
	"zombie_plague/boss/revenant/firemonster_zbs_attack1.wav",		//2	
	"zombie_plague/boss/revenant/firemonster_zbs_attack4.wav",		//3
	"zombie_plague/boss/revenant/firemonster_zbs_attack5.wav",		//4
	"zombie_plague/boss/revenant/firemonster_zbs_fireball1.wav",		//5
	"zombie_plague/boss/revenant/firemonster_zbs_fireball2.wav",		//6
	"zombie_plague/boss/revenant/firemonster_scene_appear.wav",		//7
	"zombie_plague/boss/revenant/firemonster_zbs_dash_ready.wav",		//8
	"zombie_plague/boss/revenant/firemonster_zbs_burning2.wav",		//9
	"zombie_plague/boss/revenant/firemonster_fireball_explode.wav"		//10
}
new const footstep[][] = {
	"zombie_plague/boss/boss_footstep_1.wav",
	"zombie_plague/boss/boss_footstep_2.wav"	
}

#define REVENANT_SPEED 280.0
#define HEALTH_OFFSET 50000.0
#define REVENANT_ATTACK_RANGE 200.0

#define NORMAL_RADIUS 150.0
#define NORMAL_DAMAGE random_float(600.0, 700.0)
#define FIREBALL_DAMAGE random_float(300.0, 350.0)
#define FIRESTORM_DAMAGE random_float(45.0, 50.0)
#define INFERNO_DAMAGE random_float(200.0, 300.0)
#define DASH_DAMAGE random_float(250.0, 350.0)

enum
{
	REVENANT_ANIM_DUMMY = 0,
	REVENANT_ANIM_APPEAR,
	REVENANT_ANIM_IDLE,
	REVENANT_ANIM_WALK,
	REVENANT_ANIM_RUN,
	REVENANT_ANIM_ATTACK_DASH_START,
	REVENANT_ANIM_ATTACK_DASH_LOOP,
	REVENANT_ANIM_ATTACK_DASH_END,
	REVENANT_ANIM_ATTACK_NORMAL,
	REVENANT_ANIM_ATTACK_FIREBALL_1,
	REVENANT_ANIM_ATTACK_FIREBALL_2,
	REVENANT_ANIM_ATTACK_FIRESTORM,
	REVENANT_ANIM_ATTACK_INFERNO,
	REVENANT_ANIM_ATTACK_BURN_1,
	REVENANT_ANIM_ATTACK_BURN_2,
	REVENANT_ANIM_GROGGY,
	REVENANT_ANIM_DEATH
}

enum
{
	REVENANT_STATE_IDLE = 0,
	REVENANT_STATE_SEARCHING_ENEMY,
	REVENANT_STATE_CHASE_ENEMY,	
	REVENANT_AIM_ENEMY,	
	REVENANT_STATE_APPEAR,	
	REVENANT_STATE_EVO,	
	REVENANT_STATE_ATTACK_DASH,
	REVENANT_STATE_ATTACK_NORMAL,
	REVENANT_STATE_ATTACK_FIREBALL,
	REVENANT_STATE_ATTACK_FIRESTORM,
	REVENANT_STATE_ATTACK_INFERNO,
	REVENANT_STATE_ATTACK_CHANGE,
	REVENANT_STATE_DEATH
}

enum EntityData
{
	EntID,
	TargetID,
	Float:EntitySpeed,
	Float:EntityOrigin[3]
}

#define TASK_GAME_START 27015
#define TASK_ATTACK 27016
#define TASK_DASH 21016
#define TASK_RAIN 5416

const pev_state = pev_iuser1
const pev_laststate = pev_iuser2
const pev_time = pev_fuser1
const pev_time2 = pev_fuser2
const pev_time3 = pev_fuser3

new g_CurrentBoss_Ent, Float:REVENANT_HEALTH
new g_Msg_ScreenShake, g_MaxPlayers, g_FootStep
new g_Exp_SprID, Float:Plus, bool:g_evolution

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_think(REVENANT_CLASSNAME, "fw_REVENANT_Think")
	register_think(REVENANT_FIRE_CLASSNAME, "fw_FireballThink")
	register_touch(REVENANT_FIREBALL_CLASSNAME, "*", "fw_FireballTouch")
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	g_Msg_ScreenShake = get_user_msgid("ScreenShake")
	g_MaxPlayers = get_maxplayers()
}
public plugin_natives()
{
	register_native("Create_Revenant","Create_Boss",1)
}
public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, REVENANT_MODEL)
	precache_model(REVENANT_FIREBALL)
	
	for(new i = 0; i < sizeof(Revenant_Sound); i++)
		precache_sound(Revenant_Sound[i])
	for(new i = 0; i < sizeof(footstep); i++)
		precache_sound(footstep[i])
		
	g_Exp_SprID = engfunc(EngFunc_PrecacheModel, "sprites/flame_puff01.spr")
	precache_model("sprites/flame.spr")
}
public Event_NewRound()
{
	remove_task(TASK_GAME_START)
	remove_entity_name(REVENANT_FIREBALL_CLASSNAME)
}
public logevent_round_end()
{
	remove_task(g_CurrentBoss_Ent+TASK_ATTACK)	
}
public Create_Boss(id, Float:HP)
{
	if(pev_valid(g_CurrentBoss_Ent))
		engfunc(EngFunc_RemoveEntity, g_CurrentBoss_Ent)
	
	static REVENANT; REVENANT = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(REVENANT)) return -1
	
	g_CurrentBoss_Ent = REVENANT
	REVENANT_HEALTH = HP
	
	static Float:StartOrigin[3]	
	pev(id, pev_origin, StartOrigin)
	set_pev(REVENANT, pev_origin, StartOrigin)
	
	static Float:Angles[3]	
	pev(id, pev_angles, Angles)
	set_pev(REVENANT, pev_angles, Angles)
	set_pev(REVENANT, pev_v_angle, Angles)
	
	// Set Config
	entity_set_string(REVENANT, EV_SZ_classname,REVENANT_CLASSNAME)
	entity_set_model(REVENANT, REVENANT_MODEL)
		
	set_pev(REVENANT, pev_gamestate, 1)
	entity_set_int(REVENANT, EV_INT_solid, SOLID_BBOX)
	entity_set_int(REVENANT, EV_INT_movetype, MOVETYPE_PUSHSTEP)

	// Set Size
	new Float:maxs[3] = {25.0, 50.0, 200.0}
	new Float:mins[3] = {-25.0, -50.0, -35.0}
	entity_set_size(REVENANT, mins, maxs)
	
	// Set Life
	set_pev(REVENANT, pev_takedamage, DAMAGE_YES)
	set_pev(REVENANT, pev_health, HEALTH_OFFSET + REVENANT_HEALTH)
	
	// Set Config 2
	set_pev(REVENANT, pev_owner, id)
	set_entity_anim(REVENANT, REVENANT_ANIM_IDLE, 1.0)
	set_pev(REVENANT, pev_state, REVENANT_STATE_APPEAR)
	set_pev(REVENANT, pev_laststate, -1)
	g_evolution = false

	set_pev(REVENANT, pev_nextthink, get_gametime() + 0.1)
	engfunc(EngFunc_DropToFloor, REVENANT)
	
	set_pev(REVENANT, pev_time2, get_gametime() + 1.0)
	
	return REVENANT;
}
public fw_REVENANT_Think(ent)
{
	if(!pev_valid(ent))
		return
	if(pev(ent, pev_state) == REVENANT_STATE_DEATH)
		return
	new owner; owner = pev(ent, pev_owner)
	if(pev(owner, pev_health) < HEALTH_OFFSET)
	{
		set_pev(owner, pev_takedamage, DAMAGE_NO)
		set_pev(ent, pev_takedamage, DAMAGE_NO)
		Revenant_Death(ent)
		return
	}
	if(get_cvar_num("bot_stop")){
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		return;
	}
	if(!g_evolution && (pev(ent, pev_health) <= (HEALTH_OFFSET+(REVENANT_HEALTH*0.5))))
	{
		Revenant_Evolution(ent)
		return
	}
	
	switch(pev(ent, pev_state))
	{
		case REVENANT_STATE_IDLE:
		{
			if(get_gametime() - 3.3 > pev(ent, pev_time))
			{
				set_entity_anim(ent, REVENANT_ANIM_IDLE, 1.0)
				
				set_pev(ent, pev_time, get_gametime())
			}
			if(get_gametime() - 1.0 > pev(ent, pev_time2))
			{
				set_pev(ent, pev_state, REVENANT_STATE_SEARCHING_ENEMY)
				set_pev(ent, pev_time2, get_gametime())
			}	
			
			// Set Next Think
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case REVENANT_STATE_APPEAR:
		{
			set_entity_anim(ent, REVENANT_ANIM_APPEAR, 1.0)
			PlaySound(0, Revenant_Sound[7])
			
			set_pev(ent, pev_state, REVENANT_STATE_IDLE)
			set_pev(ent, pev_nextthink, get_gametime() + 14.0)
		}
		case REVENANT_STATE_SEARCHING_ENEMY:
		{
			static Victim;
			Victim = FindClosetEnemy(ent, 0)
			
			if(is_user_alive(Victim))
			{
				set_pev(ent, pev_enemy, Victim)
				Random_AttackMethod(ent)
			} else {
				set_pev(ent, pev_enemy, 0)
				set_pev(ent, pev_state, REVENANT_STATE_IDLE)
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case REVENANT_STATE_CHASE_ENEMY:
		{
			static Enemy; Enemy = pev(ent, pev_enemy)
			static Float:EnemyOrigin[3]
			pev(Enemy, pev_origin, EnemyOrigin)
			if(is_user_alive(Enemy))
			{
				if(entity_range(Enemy, ent) <= floatround(REVENANT_ATTACK_RANGE))
				{
					MM_Aim_To(ent, EnemyOrigin) 
					switch(random_num(0, 3))
					{
						case 0..1:Revenant_Attack_Normal(ent+TASK_ATTACK)
						case 2..3:Revenant_Attack_Firestorm(ent+TASK_ATTACK)
					}					
				} else {
					if(pev(ent, pev_movetype) == MOVETYPE_PUSHSTEP)
					{
						static Float:OriginAhead[3]
						get_position(ent, 300.0, 0.0, 0.0, OriginAhead)
						
						MM_Aim_To(ent, EnemyOrigin) 
						hook_ent2(ent, OriginAhead, REVENANT_SPEED)
						
						set_entity_anim2(ent, REVENANT_ANIM_RUN, 1.0)
						
						if(get_gametime() - 0.65 > pev(ent, pev_time3))
						{
							if(g_FootStep != 1) g_FootStep = 1
							else g_FootStep = 2
						
							PlaySound(0, footstep[g_FootStep == 1 ? 0 : 1])
							
							set_pev(ent, pev_time3, get_gametime())
						}
						
						if(get_gametime() - 4.0 > pev(ent, pev_time2))
						{
							switch(random_num(0, 6))
							{
								case 0:Revenant_Start_Attack_Dash(ent+TASK_ATTACK)
								case 1..2:Revenant_Attack_Fireball(ent+TASK_ATTACK)
								case 3:Revenant_Attack_Firestorm(ent+TASK_ATTACK)
								case 4:Revenant_Attack_RainFire(ent+TASK_ATTACK)
							}
							
							set_pev(ent, pev_time2, get_gametime())
						}
					} else {
						set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
					}
				}
			} else {
				set_pev(ent, pev_state, REVENANT_STATE_SEARCHING_ENEMY)
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case (REVENANT_STATE_ATTACK_DASH + 1000):
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
				Make_PlayerShake(i)
				
				static Float:Velocity[3]
				Velocity[0] = random_float(-900.0, 900.0)
				Velocity[1] = random_float(-900.0, 900.0)
				Velocity[2] = random_float(800.0, 900.0)
				set_pev(i, pev_velocity, Velocity)
			}			
			if(get_gametime() - 0.2 > pev(ent, pev_time3))
			{
				if(g_FootStep != 1) g_FootStep = 1
				else g_FootStep = 2
			
				PlaySound(0, footstep[g_FootStep == 1 ? 0 : 1])
				
				set_pev(ent, pev_time3, get_gametime())
			}
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case (REVENANT_AIM_ENEMY):
		{			
			static Float:EnemyOrigin[3]; 
			pev(pev(ent, pev_enemy), pev_origin, EnemyOrigin)
			MM_Aim_To(ent, EnemyOrigin) 
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
	}
}
public Random_AttackMethod(ent)
{
	static RandomNum; RandomNum = random_num(0, 120)
	
	if(RandomNum > 0 && RandomNum <= 50)
	{
		set_pev(ent, pev_time, get_gametime())
		set_pev(ent, pev_state, REVENANT_STATE_CHASE_ENEMY)
	}
	else if(RandomNum >= 51 && RandomNum <= 80)
		Revenant_Start_Attack_Dash(ent)
	else if(RandomNum >= 81 && RandomNum <= 100)
		Revenant_Attack_Fireball(ent)
	else if(RandomNum >= 101 && RandomNum <= 110)
		Revenant_Attack_Firestorm(ent)
	else if(RandomNum >= 111 && RandomNum < 120)
		Revenant_Attack_RainFire(ent)
	else
		Random_AttackMethod(ent)
}
public Revenant_Evolution(ent)
{
	if(!pev_valid(ent))
		return
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})
	
	set_pev(ent, pev_state, REVENANT_STATE_EVO)
	
	set_entity_anim(ent, REVENANT_ANIM_ATTACK_BURN_2, 1.0)
	set_task(0.6, "Evolution_Sound", 9)
	g_evolution = true
		
	set_task(4.5, "Revenant_Evolution_Flame", ent)
	set_task(9.8, "Revenant_Evolution_Done", ent+TASK_ATTACK)
}
public Evolution_Sound(soundindex) PlaySound(0, Revenant_Sound[soundindex])
public Revenant_Evolution_Flame(ent)
{
	static Float:Origin[3]
	
	emit_sound(ent, CHAN_ITEM, Revenant_Sound[10], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	for(new i = 0; i < 15; i++)
	{
		get_position(ent, random_float(-60.0,60.0), random_float(-60.0,60.0), random_float(-80.0,100.0), Origin)
		Revenant_Explosion(pev(ent,pev_owner), Origin, 0.0)
	}
	set_pev(ent , pev_skin, 1)
}
public Revenant_Evolution_Done(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_health, pev(ent, pev_health) + (REVENANT_HEALTH*0.1))
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, REVENANT_STATE_SEARCHING_ENEMY)	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}
public Revenant_Attack_Normal(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	static Enemy, Float:CheckPosition[3], Float:VicOrigin[3]
	Enemy = pev(ent, pev_enemy)	
	pev(Enemy, pev_origin, VicOrigin)
	get_position(ent, 150.0, 0.0, 0.0, CheckPosition)	
	if(get_distance_f(VicOrigin, CheckPosition) < NORMAL_RADIUS)
	{
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})
		
		set_pev(ent, pev_state, REVENANT_STATE_ATTACK_NORMAL)
	
		set_task(0.1, "Revenant_Attack_Normal_2", ent+TASK_ATTACK)		
	}else{
		Revenant_Attack_Firestorm(ent+TASK_ATTACK)
	}	
}

public Revenant_Attack_Normal_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_entity_anim(ent, REVENANT_ANIM_ATTACK_NORMAL, 1.0)
	
	set_task(0.85, "Revenant_Check_Attack_Normal", ent+TASK_ATTACK)
	set_task(2.26, "Revenant_End_Attack_Normal", ent+TASK_ATTACK)	
}

public Revenant_Check_Attack_Normal(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	static Float:CheckPosition[3], Float:VicOrigin[3]
	get_position(ent, 150.0, 00.0, 0.0, CheckPosition)
		
	PlaySound(0, Revenant_Sound[2])
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(i==pev(ent, pev_owner))
			continue
			
		pev(i, pev_origin, VicOrigin)
		if(get_distance_f(VicOrigin, CheckPosition) > NORMAL_RADIUS)
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, pev(ent,pev_owner), pev(ent,pev_owner), NORMAL_DAMAGE, DMG_BULLET)		
		Make_PlayerShake(i)
	}
}

public Revenant_End_Attack_Normal(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_laststate, REVENANT_STATE_ATTACK_NORMAL)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, REVENANT_STATE_CHASE_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public Revenant_Start_Attack_Dash(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	

	set_pev(ent, pev_state, REVENANT_STATE_ATTACK_DASH)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	
	new Float:EnemyOrigin[3]
	pev(pev(ent, pev_enemy), pev_origin, EnemyOrigin)
	MM_Aim_To(ent, EnemyOrigin)
	
	set_entity_anim(ent, REVENANT_ANIM_ATTACK_DASH_START, 1.0)
	PlaySound(0, Revenant_Sound[8])
	
	set_task(1.4, "Revenant_Start_Dashing", ent+TASK_ATTACK)
	set_task(2.5, "Revenant_Stop_Dashing", ent+TASK_ATTACK)
}

public Revenant_Start_Dashing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
			
	new Float:EnemyOrigin[3]
	pev(pev(ent, pev_enemy), pev_origin, EnemyOrigin)
	MM_Aim_To(ent, EnemyOrigin)
	
	set_entity_anim(ent, REVENANT_ANIM_ATTACK_DASH_LOOP, 1.0)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, REVENANT_STATE_ATTACK_DASH + 1000)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
}

public Revenant_Stop_Dashing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	remove_task(ent+TASK_ATTACK)
	set_pev(ent, pev_state,REVENANT_STATE_ATTACK_DASH)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
	
	set_entity_anim(ent, REVENANT_ANIM_ATTACK_DASH_END, 1.0)
	set_task(0.5, "Revenant_End_Dashing", ent+TASK_ATTACK)
}

public Revenant_End_Dashing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
	
	set_pev(ent, pev_laststate, REVENANT_STATE_ATTACK_DASH)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, REVENANT_STATE_SEARCHING_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}
public Revenant_Attack_Fireball(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})
	
	set_pev(ent, pev_state, REVENANT_STATE_ATTACK_FIREBALL)

	set_task(0.1, "Revenant_Attack_Fireball_2", ent+TASK_ATTACK)
}

public Revenant_Attack_Fireball_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_entity_anim(ent, REVENANT_ANIM_ATTACK_FIREBALL_1, 1.0)
	
	set_pev(ent, pev_state, REVENANT_AIM_ENEMY)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	
	set_task(0.7, "Revenant_Attack_Fireball_3", ent+TASK_ATTACK)
	set_task(4.3, "Revenant_End_Attack_Fireball", ent+TASK_ATTACK)	
}

public Revenant_Attack_Fireball_3(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
	
	new ball1, ball2;
	static Float:ballOrigin[2][3],Float:TargetOrigin[3];
	new edData[EntityData];
	get_position(ent, 45.0, -10.0, 120.0, ballOrigin[0])
	get_position(ent, 45.0, 45.0, 120.0, ballOrigin[1])
	ball1 = Create_Fireball(ent, ballOrigin[0])
	ball2 = Create_Fireball(ent, ballOrigin[1])
	
	edData[EntID] = ball1;
	get_position(ent, 15.0, -50.0, 155.0, TargetOrigin[0])
	edData[EntitySpeed] = 0;
	edData[EntityOrigin] = {0,0,0}
	edData[EntitySpeed] += 120.0;
	edData[EntityOrigin][0] += TargetOrigin[0]
	edData[EntityOrigin][1] += TargetOrigin[1]
	edData[EntityOrigin][2] += TargetOrigin[2]
	set_task(0.7, "Fireball_Move", 12345, edData[EntID], sizeof(edData))
		
	edData[EntID] = ball2;
	get_position(ent, 45.0, 50.0, 155.0, TargetOrigin)
	edData[EntitySpeed] = 0;
	edData[EntityOrigin] = {0,0,0}
	edData[EntitySpeed] += 110.0;
	edData[EntityOrigin][0] += TargetOrigin[0]
	edData[EntityOrigin][1] += TargetOrigin[1]
	edData[EntityOrigin][2] += TargetOrigin[2]
	set_task(0.8, "Fireball_Move", 12345, edData[EntID], sizeof(edData))	
	
	set_task(1.1, "Fireball_Move2", ball1)	
	set_task(1.4, "Fireball_Move2", ball2)	
}

public Revenant_End_Attack_Fireball(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_laststate, REVENANT_STATE_ATTACK_FIREBALL)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, REVENANT_STATE_SEARCHING_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}
public Fireball_Move(EntData[EntityData])
{
	new ent = EntData[EntID];
	new Float:spd,Float:Origin[3];
	spd += EntData[EntitySpeed]
	Origin[0] += EntData[EntityOrigin][0];
	Origin[1] += EntData[EntityOrigin][1];
	Origin[2] += EntData[EntityOrigin][2];
	
	if(!pev_valid(ent))
		return
		
	hook_ent2(ent, Origin, spd)
}
public Fireball_Move2(ent)
{
	if(!pev_valid(ent))
		return
		
	new Float:Target[3];
	get_position(pev(pev(ent, pev_owner), pev_enemy), random_float(-20.0, 20.0), random_float(-20.0, 20.0), random_float(-5.0, 30.0), Target)
	hook_ent2(ent, Target, 1500.0)
	set_pev(ent, pev_state, REVENANT_STATE_ATTACK_FIREBALL)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}
public Revenant_Attack_Firestorm(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	if(pev(ent, pev_laststate)==REVENANT_STATE_ATTACK_FIRESTORM)
	{
		set_pev(ent, pev_state, REVENANT_STATE_CHASE_ENEMY)		
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
		return;
	}else{
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})
		
		set_pev(ent, pev_state, REVENANT_STATE_ATTACK_FIRESTORM)
	
		set_task(0.1, "Revenant_Attack_Firestorm_2", ent+TASK_ATTACK)
	}
}

public Revenant_Attack_Firestorm_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_entity_anim(ent, REVENANT_ANIM_ATTACK_FIRESTORM, 1.0)
	Plus = 0.5
	set_task(0.5, "Revenant_Attack_Firestorm_3", ent+TASK_ATTACK)
	set_task(0.75, "Revenant_Attack_Firestorm_3", ent+TASK_ATTACK)
	set_task(1.0, "Revenant_Attack_Firestorm_3", ent+TASK_ATTACK)
	set_task(1.25, "Revenant_Attack_Firestorm_3", ent+TASK_ATTACK)
	
	set_task(1.0, "Revenant_End_Attack_Firestorm", ent+TASK_ATTACK)	
}
public Revenant_Attack_Firestorm_Sound() PlaySound(0, Revenant_Sound[3])
public Revenant_Attack_Firestorm_3(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
			
	Plus+=0.5
	Revenant_Attack_Firestorm_4(ent, Plus)
}
public Revenant_Attack_Firestorm_4(ent, Float:Plus)
{
	static Float:Origin[8][3]
	
	get_position(ent, 100.0 * Plus, 0.0, -50.0, Origin[0])
	get_position(ent, 75.0 * Plus, 75.0 * Plus, -50.0, Origin[1])
	get_position(ent, 75.0 * Plus, -75.0 * Plus, -50.0, Origin[2])	
	get_position(ent, 0.0, 100.0 * Plus, -50.0, Origin[3])
	get_position(ent, 0.0, -100.0 * Plus, -50.0, Origin[4])	
	get_position(ent, -75.0 * Plus, 75.0 * Plus, -50.0, Origin[5])
	get_position(ent, -75.0 * Plus, -75.0 * Plus, -50.0, Origin[6])	
	get_position(ent, -100.0 * Plus, 0.0, -50.0, Origin[7])
	
	emit_sound(ent, CHAN_ITEM, Revenant_Sound[10], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	for(new i = 0; i < 8; i++)
		Revenant_Explosion(pev(ent,pev_owner), Origin[i], FIRESTORM_DAMAGE)
}
public Revenant_End_Attack_Firestorm(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
	set_pev(ent, pev_laststate, REVENANT_STATE_ATTACK_FIRESTORM)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, REVENANT_STATE_SEARCHING_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public Revenant_Attack_RainFire(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
	
	if(pev(ent, pev_laststate)==REVENANT_STATE_ATTACK_INFERNO || !g_evolution)
	{
		set_pev(ent, pev_state, REVENANT_STATE_CHASE_ENEMY)		
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
		return;
	}else{
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})
		
		set_pev(ent, pev_state, REVENANT_STATE_ATTACK_INFERNO)
	
		set_task(0.1, "Revenant_Attack_RainFire_2", ent+TASK_ATTACK)
	}
}

public Revenant_Attack_RainFire_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_entity_anim(ent, REVENANT_ANIM_ATTACK_INFERNO, 1.0)
	
	set_task(0.5, "RainFire_Sound")	
	set_task(3.0, "Revenant_Do_RainFire", ent+TASK_ATTACK)
	set_task(9.4, "Revenant_End_Attack_RainFire", ent+TASK_ATTACK)	
}
public RainFire_Sound() PlaySound(0, Revenant_Sound[4])
public Revenant_Do_RainFire(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_task(0.5, "Make_Fire",ent+TASK_ATTACK, _, _, "b")
}
public Make_Fire(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	static fireball, Float:StartOrigin[3], Float:EndOrigin[3]
	for(new i = 0; i < 15; i++)
	{			
		get_position(ent, random_float(-1000.0, 1000.0), random_float(-1000.0, 1000.0), random_float(500.0, 700.0), StartOrigin)
		EndOrigin[0] = StartOrigin[0] + 200.0
		EndOrigin[1] = StartOrigin[1]
		EndOrigin[2] = StartOrigin[2] - 500.0
		
		fireball = Create_Fireball(ent, StartOrigin)
		hook_ent2(fireball, EndOrigin, random_float(250.0, 550.0))
	}		
}
public Revenant_End_Attack_RainFire(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	remove_task(ent+TASK_ATTACK)
	set_pev(ent, pev_laststate, REVENANT_STATE_ATTACK_INFERNO)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, REVENANT_STATE_SEARCHING_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public Create_Fireball(ent, Float:StartOrigin[3])
{
	static Fireball;Fireball = create_entity("info_target")

	engfunc(EngFunc_SetOrigin, Fireball, StartOrigin)

	set_pev(Fireball, pev_classname, REVENANT_FIREBALL_CLASSNAME)
	engfunc(EngFunc_SetModel, Fireball, REVENANT_FIREBALL)
	set_pev(Fireball, pev_solid, SOLID_TRIGGER)
	set_pev(Fireball, pev_movetype, MOVETYPE_FLY)
	set_pev(Fireball, pev_owner, ent)

	fm_set_rendering(Fireball, kRenderNormal, 255, 255, 255, kRenderTransAdd, 255)
	
	new Float:maxs[3] = {5.0,5.0,5.0}
	new Float:mins[3] = {-5.0,-5.0,-5.0}
	entity_set_size(Fireball, mins, maxs)
	set_entity_anim(Fireball, 0, 1.0)
	
	Create_FireEffect(Fireball, 0.5)
	return Fireball;
}
public Create_FireEffect(ball, Float:size)
{
	static ent
	ent = create_entity("env_sprite")
	set_pev(ent, pev_takedamage, 0.0)
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_classname, REVENANT_FIRE_CLASSNAME)
	engfunc(EngFunc_SetModel, ent, "sprites/flame.spr")
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	//set_pev(ent, pev_renderamt, 255.0)
	//set_pev(ent, pev_light_level, 255.0)
	set_pev(ent, pev_scale, size)
	set_pev(ent, pev_owner, ball)	
	set_pev(ent, pev_animtime, get_gametime())
	set_pev(ent, pev_framerate, 8.0)
	set_pev(ent, pev_frame, 0.1)
	set_pev(ent, pev_spawnflags, SF_SPRITE_STARTON)
	dllfunc(DLLFunc_Spawn, ent)
	fw_FireballThink(ent)
	fm_set_rendering(ent, kRenderNormal, 255, 255, 255, kRenderTransAdd, 255)
	set_pev(ent, pev_nextthink, get_gametime() + 0.01)
}
public fw_FireballThink(ent)
{
	if(!pev_valid(ent))
		return
	if(!pev_valid(pev(ent, pev_owner)))
	{
		remove_entity(ent)
		return
	}
	static owner
	owner = pev(ent, pev_owner)
	static Float:Origin[3]
	pev(owner, pev_origin, Origin)
	Origin[2] += 50.0
	entity_set_origin(ent, Origin)
	set_pev(ent, pev_nextthink, get_gametime() + 0.001)
}
public fw_FireballTouch(ent, id)
{
	if(!pev_valid(ent))
		return
	if(!pev_valid(pev(ent,pev_owner)))
		return
	
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	emit_sound(ent, CHAN_ITEM, Revenant_Sound[10], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	Revenant_Explosion(pev(pev(ent,pev_owner),pev_owner), Origin, FIREBALL_DAMAGE)
	set_pev(ent, pev_flags, FL_KILLME)
}
public Revenant_Explosion(Attacker, Float:Origin[3], Float:Damage)
{
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 50.0)
	write_short(g_Exp_SprID)	// sprite index
	write_byte(20)	// scale in 0.1's
	write_byte(25)	// framerate
	write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOPARTICLES|TE_EXPLFLAG_NOSOUND)	// flags
	message_end()	
	
	static Float:POrigin[3];
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		pev(i, pev_origin, POrigin)
		if(get_distance_f(Origin, POrigin) > 180.0)
			continue
		if(i==Attacker)
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, Attacker, Attacker, Damage, DMG_BURN)		
		Make_PlayerShake(i)
	}
}

public Revenant_Death(ent)
{
	if(!pev_valid(ent))
		return
	
	remove_task(ent+TASK_ATTACK)
	remove_task(ent+TASK_GAME_START)
	
	set_entity_anim(ent, REVENANT_ANIM_DEATH, 1.0)	
	set_pev(ent, pev_state, REVENANT_STATE_DEATH)
	
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	
	PlaySound(0, Revenant_Sound[0])
	set_task(10.0, "Revenant_Death2", ent)
}

public Revenant_Death2(ent)
{	
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
