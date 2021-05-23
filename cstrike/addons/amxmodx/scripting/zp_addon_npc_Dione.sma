#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN "[CSO] Fallen Titan"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define DIONE_MODEL "models/zombie_plague/boss/dione.mdl"

#define DIONE_CLASSNAME "NPC_DIONE"
#define DIONE_EF_POISONEXP1 "sprites/poisonexp.spr"

new const skill_posion[2][] = {
	"models/zombie_plague/boss/ef_poison01.mdl", // Start
	"models/zombie_plague/boss/ef_poison02.mdl" // End
}
new const skill_swing[] = "models/zombie_plague/boss/ef_swing.mdl"
new const skill_tentacle[][] = {
	"models/zombie_plague/boss/ef_tentacle_sign.mdl",
	"models/zombie_plague/boss/tentacle.mdl",
	"models/zombie_plague/boss/ef_tentacle.mdl"
}
new const DioneSound[][] = {	
	"zombie_plague/boss/boss_footstep_1.wav",
	"zombie_plague/boss/boss_footstep_2.wav",		//1
	"zombie_plague/boss/dione/appear3.wav",			//2
	"zombie_plague/boss/dione/zbs_attack_bite.wav",		//3
	"zombie_plague/boss/dione/zbs_attack_poison1.wav",	//4
	"zombie_plague/boss/dione/zbs_poison_spit.wav",		//5
	"zombie_plague/boss/dione/zbs_attack_swing.wav",	//6	
	"zombie_plague/boss/dione/zbs_rolling1.wav",		//7
	"zombie_plague/boss/dione/zbs_rolling2.wav",		//8
	"zombie_plague/boss/dione/zbs_rolling3.wav",		//9	
	"zombie_plague/boss/dione/zbs_attack_tentacle1.wav",	//10
	"zombie_plague/boss/dione/zbs_attack_tentacle2.wav",	//11
	"zombie_plague/boss/dione/zbs_tentacle_pierce.wav",	//12
	"zombie_plague/boss/dione/exit1.wav"			//13
}


#define DIONE_SPEED 250.0
#define HEALTH_OFFSET 50000.0
#define DIONE_ATTACK_RANGE 250.0

#define BITE_RADIUS 100.0
#define BITE_DAMAGE random_float(350.0, 450.0)
#define SWING_RADIUS 320.0
#define SWING_DAMAGE random_float(450.0, 550.0)
#define POISON_DAMAGE random_float(100.0, 150.0)
#define ROLLING_DAMAGE random_float(450.0, 550.0)
#define TENTACLE_DAMAGE random_float(250.0, 300.0)

enum
{
	DIONE_ANIM_DUMMY = 0,
	DIONE_ANIM_APPEAR1,
	DIONE_ANIM_APPEAR2,
	DIONE_ANIM_APPEAR3,
	DIONE_ANIM_IDLE,
	DIONE_ANIM_WALK,
	DIONE_ANIM_RUN,
	DIONE_ANIM_ATTACK_SWING,
	DIONE_ANIM_ATTACK_BITE,
	DIONE_ANIM_ATTACK_TENTACLE_1,
	DIONE_ANIM_ATTACK_TENTACLE_2,
	DIONE_ANIM_ATTACK_POISON_1,
	DIONE_ANIM_ATTACK_POISON_2,
	DIONE_ANIM_ATTACK_ROLL_START,
	DIONE_ANIM_ATTACK_ROLL_LOOP,
	DIONE_ANIM_ATTACK_ROLL_END,
	DIONE_ANIM_EXIT_1,
	DIONE_ANIM_EXIT_2
}

enum
{
	DIONE_STATE_IDLE = 0,
	DIONE_STATE_APPEARING,
	DIONE_STATE_SEARCHING_ENEMY,
	DIONE_STATE_CHASE_ENEMY,	
	DIONE_STATE_ATTACK_SWING,
	DIONE_STATE_ATTACK_BITE,
	DIONE_STATE_ATTACK_TENTACLE_1,
	DIONE_STATE_ATTACK_TENTACLE_2,
	DIONE_STATE_ATTACK_POISON_1,
	DIONE_STATE_ATTACK_POISON_2,
	DIONE_STATE_ATTACK_ROLL,
	DIONE_STATE_EXIT
}

#define TASK_GAME_START 27015
#define TASK_ATTACK 27016

const pev_state = pev_iuser1
const pev_laststate = pev_iuser2
const pev_time = pev_fuser1
const pev_time2 = pev_fuser2
const pev_time3 = pev_fuser3

new g_CurrentBoss_Ent, g_Reg_Ham, Float:DIONE_HEALTH
new g_Msg_ScreenShake, g_MaxPlayers, g_FootStep
new g_Exp_SprID

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_think(DIONE_CLASSNAME, "fw_DIONE_Think")
	register_touch("dione_poison", "*", "fw_PoisonTouch")
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	g_Msg_ScreenShake = get_user_msgid("ScreenShake")
	g_MaxPlayers = get_maxplayers()	
}
public plugin_natives()
{
	register_native("Create_Dione","Create_Boss",1)
}
public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, DIONE_MODEL)
	engfunc(EngFunc_PrecacheModel, skill_swing)
	
	for(new i = 0; i < sizeof(skill_posion); i++)
		engfunc(EngFunc_PrecacheModel, skill_posion[i])
	for(new i = 0; i < sizeof(skill_tentacle); i++)
		engfunc(EngFunc_PrecacheModel, skill_tentacle[i])
		
	for(new i = 0; i < sizeof(DioneSound); i++)
		precache_sound(DioneSound[i])
		
	g_Exp_SprID = precache_model(DIONE_EF_POISONEXP1)
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
	
	static DIONE; DIONE = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(DIONE)) return -1
	
	g_CurrentBoss_Ent = DIONE
	DIONE_HEALTH = HP
	
	static Float:StartOrigin[3]	
	pev(id, pev_origin, StartOrigin)
	set_pev(DIONE, pev_origin, StartOrigin)
	
	static Float:Angles[3]	
	pev(id, pev_angles, Angles)
	set_pev(DIONE, pev_angles, Angles)
	set_pev(DIONE, pev_v_angle, Angles)
	
	// Set Config
	entity_set_string(DIONE, EV_SZ_classname,DIONE_CLASSNAME)
	entity_set_model(DIONE, DIONE_MODEL)		
	set_pev(DIONE, pev_skin, random_num(0,1))
	
	set_pev(DIONE, pev_gamestate, 1)
	entity_set_int(DIONE, EV_INT_solid, SOLID_BBOX)
	entity_set_int(DIONE, EV_INT_movetype, MOVETYPE_PUSHSTEP)

	// Set Size
	new Float:maxs[3] = {110.0, 110.0, 110.0}
	new Float:mins[3] = {-110.0, -110.0,-30.0}
	entity_set_size(DIONE, mins, maxs)
	
	// Set Life
	set_pev(DIONE, pev_takedamage, DAMAGE_YES)
	set_pev(DIONE, pev_health, HEALTH_OFFSET + DIONE_HEALTH)
	
	// Set Config 2
	set_pev(DIONE, pev_owner, id)
	set_entity_anim(DIONE, DIONE_ANIM_IDLE, 1.0)
	set_pev(DIONE, pev_laststate, -1)
	set_pev(DIONE, pev_state, DIONE_STATE_APPEARING)

	set_pev(DIONE, pev_nextthink, get_gametime() + 0.1)
	engfunc(EngFunc_DropToFloor, DIONE)
	
	set_pev(DIONE, pev_time2, get_gametime() + 1.0)
	
	if(!g_Reg_Ham)
	{
		g_Reg_Ham = 1
		RegisterHamFromEntity(Ham_TraceAttack, DIONE, "fw_DIONE_TraceAttack", 1)
	}
	return DIONE;
}

public fw_DIONE_TraceAttack(Ent, Attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	if(!is_valid_ent(Ent)) 
		return
     
	static Classname[32]
	pev(Ent, pev_classname, Classname, charsmax(Classname)) 
	     
	if(!equal(Classname, DIONE_CLASSNAME)) 
		return
		
	new owner;owner=pev(Ent,pev_owner)
	if(pev(owner, pev_health)>200.0)
	{
		set_pev(owner, pev_health, pev(Ent, pev_health) - HEALTH_OFFSET)
	}
	else set_pev(owner, pev_health, 1.0)
	
}
public fw_DIONE_Think(ent)
{
	if(!pev_valid(ent))
		return
	if(pev(ent, pev_state) == DIONE_STATE_EXIT)
		return
	if((pev(ent, pev_health) - HEALTH_OFFSET) <= 0.0)
	{
		set_pev(ent, pev_takedamage, DAMAGE_NO)
		DIONE_Death(ent)
		return
	}
	
	switch(pev(ent, pev_state))
	{
		case DIONE_STATE_IDLE:
		{
			if(get_gametime() - 3.3 > pev(ent, pev_time))
			{
				set_entity_anim(ent, DIONE_ANIM_IDLE, 1.0)
				
				set_pev(ent, pev_time, get_gametime())
			}
			if(get_gametime() - 1.0 > pev(ent, pev_time2))
			{
				set_pev(ent, pev_state, DIONE_STATE_SEARCHING_ENEMY)
				set_pev(ent, pev_time2, get_gametime())
			}	
			
			// Set Next Think
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case DIONE_STATE_APPEARING:
		{
			set_entity_anim(ent, DIONE_ANIM_APPEAR3, 1.0)
			
			PlaySound(0, DioneSound[2])
			set_task(3.9, "Make_PlayerShake", 0)
			
			set_pev(ent, pev_state, DIONE_STATE_IDLE)
			set_pev(ent, pev_nextthink, get_gametime() + 8.6)
		}
		case DIONE_STATE_SEARCHING_ENEMY:
		{
			static Victim;
			Victim = FindClosetEnemy(ent, 0)
			
			if(is_user_alive(Victim))
			{
				set_pev(ent, pev_enemy, Victim)
				Random_AttackMethod(ent)
			} else {
				set_pev(ent, pev_enemy, 0)
				set_pev(ent, pev_state, DIONE_STATE_IDLE)
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case DIONE_STATE_CHASE_ENEMY:
		{
			static Enemy; Enemy = pev(ent, pev_enemy)
			static Float:EnemyOrigin[3]
			pev(Enemy, pev_origin, EnemyOrigin)
			
			if(is_user_alive(Enemy))
			{
				if(entity_range(Enemy, ent) <= floatround(DIONE_ATTACK_RANGE))
				{
					MM_Aim_To(ent, EnemyOrigin) 
					
					Dione_Attack_Bite(ent+TASK_ATTACK)
				} else {
					if(pev(ent, pev_movetype) == MOVETYPE_PUSHSTEP)
					{
						static Float:OriginAhead[3]
						get_position(ent, 300.0, 0.0, 0.0, OriginAhead)
						
						MM_Aim_To(ent, EnemyOrigin) 
						hook_ent2(ent, OriginAhead, DIONE_SPEED + 30.0)
						
						set_entity_anim2(ent, DIONE_ANIM_WALK, 1.0)
						
						if(get_gametime() - 1.0 > pev(ent, pev_time3))
						{
							if(g_FootStep != 1) g_FootStep = 1
							else g_FootStep = 2
						
							PlaySound(0, DioneSound[g_FootStep == 1 ? 0 : 1])
							
							set_pev(ent, pev_time3, get_gametime())
						}
						
						if(get_gametime() - 4.0 > pev(ent, pev_time2))
						{
							new rand = random_num(0, 5)
							if(rand == 0)
								Dione_Start_Attack_Roll(ent+TASK_ATTACK)
							else if(rand == 1) Dione_Attack_Tentacle(ent+TASK_ATTACK)
							else if(rand == 2||rand == 3) Dione_Attack_Poison(ent+TASK_ATTACK)
							
							set_pev(ent, pev_time2, get_gametime())
						}
					} else {
						set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
					}
				}
			} else {
				set_pev(ent, pev_state, DIONE_STATE_SEARCHING_ENEMY)
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.1)
		}
		case DIONE_STATE_ATTACK_POISON_1 + 1000:
		{				
			static Float:EnemyOrigin[3]
			pev(pev(ent, pev_enemy), pev_origin, EnemyOrigin)
			MM_Aim_To(ent, EnemyOrigin) 
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
		set_pev(ent, pev_state, DIONE_STATE_CHASE_ENEMY)
	}
	else if(RandomNum >= 51 && RandomNum <= 70)
		Dione_Start_Attack_Roll(ent)
	else if(RandomNum >= 71 && RandomNum <= 80)
		Dione_Attack_Poison(ent)
	else if(RandomNum >= 81 && RandomNum < 110)
		Dione_Attack_Tentacle(ent)
	else
		Random_AttackMethod(ent)
}
public Dione_Attack_Bite(ent)
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
		set_pev(ent, pev_state, DIONE_STATE_ATTACK_BITE)
		set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
		set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	
	
		set_task(0.1, "Dione_Attack_Bite_2", ent+TASK_ATTACK)			
	}else{
		Dione_Attack_Swing(ent+TASK_ATTACK)
	}
}

public Dione_Attack_Bite_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_entity_anim(ent, DIONE_ANIM_ATTACK_BITE, 1.0)
	
	PlaySound(0, DioneSound[3])
	set_task(0.7, "Dione_Check_Attack_Bite", ent+TASK_ATTACK)
	set_task(1.3, "Dione_Check_Attack_Bite_2", ent+TASK_ATTACK)
	set_task(3.2, "Dione_End_Attack_Bite", ent+TASK_ATTACK)	
}

public Dione_Check_Attack_Bite(ent)
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
public Dione_Check_Attack_Bite_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	static Float:CheckPosition[3], Float:VicOrigin[3]
	get_position(ent, 270.0, -60.0, 0.0, CheckPosition)
		
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

public Dione_End_Attack_Bite(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, DIONE_STATE_CHASE_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public Dione_Attack_Swing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	
	set_pev(ent, pev_state, DIONE_STATE_ATTACK_SWING)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	

	set_entity_anim(ent, DIONE_ANIM_ATTACK_SWING, 1.0)
	
	set_task(0.6, "Dione_Check_Attack_Swing", ent+TASK_ATTACK)
	set_task(3.5, "Dione_End_Attack_Swing", ent+TASK_ATTACK)
}
public Dione_Check_Attack_Swing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	static wpn, wpnname[32]
	static Float:CheckPosition[3], Float:VicOrigin[3]
	get_position(ent, 0.0, 0.0, 0.0, CheckPosition)
	
	PlaySound(0, DioneSound[6])
	
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
	set_task(0.5, "Dione_Remove_Ef_Swing", ent_ef)
}
public Dione_Remove_Ef_Swing(ent)
{
	remove_entity(ent)		
}
public Dione_End_Attack_Swing(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, DIONE_STATE_CHASE_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public Dione_Start_Attack_Roll(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	

	set_pev(ent, pev_state, DIONE_STATE_ATTACK_ROLL)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	
	set_pev(ent, pev_enemy, FindFarestEnemy(ent,0))	
	new Float:EnemyOrigin[3],Enemy;Enemy = pev(ent, pev_enemy)
	pev(Enemy, pev_origin, EnemyOrigin)
	MM_Aim_To(ent, EnemyOrigin)
	
	set_entity_anim(ent, DIONE_ANIM_ATTACK_ROLL_START, 1.0)
	PlaySound(0, DioneSound[7])
	
	set_task(0.7, "Dione_Start_Rolling", ent+TASK_ATTACK)
	set_task(2.0, "Dione_Stop_Rolling", ent+TASK_ATTACK)
}

public Dione_Start_Rolling(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
			
	set_entity_anim(ent, DIONE_ANIM_ATTACK_ROLL_LOOP, 1.0)
	set_task(0.01, "Task_Rolling", ent+TASK_ATTACK, _, _, "b")
}

public Task_Rolling(ent)
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
	PlaySound(0, DioneSound[8])
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	hook_ent2(ent, Target, 2000.0)
}

public Dione_Stop_Rolling(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	remove_task(ent+TASK_ATTACK)
	set_entity_anim(ent, DIONE_ANIM_ATTACK_ROLL_END, 1.0)
	PlaySound(0, DioneSound[9])
	set_pev(ent, pev_velocity, {0.0,0.0,0.0})
	set_pev(ent, pev_state,DIONE_STATE_ATTACK_ROLL)
	
	set_task(1.5, "Dione_End_Rolling", ent+TASK_ATTACK)
}

public Dione_End_Rolling(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
	
	set_pev(ent, pev_laststate, DIONE_STATE_ATTACK_ROLL)
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, DIONE_STATE_SEARCHING_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public Dione_Attack_Poison(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_state, DIONE_STATE_ATTACK_POISON_1)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})	

	set_task(0.1, "Dione_Attack_Poison_2", ent+TASK_ATTACK)
}

public Dione_Attack_Poison_2(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
		
	set_entity_anim(ent, DIONE_ANIM_ATTACK_POISON_1, 1.0)	
	
	set_task(0.5, "Spit_Sound")
	set_task(0.5, "Spit_State", ent+TASK_ATTACK)
	set_task(4.1, "Dione_Spit_Poison", ent+TASK_ATTACK)
	set_task(6.2, "Dione_End_Attack_Poison", ent+TASK_ATTACK)	
}
public Spit_Sound() PlaySound(0, DioneSound[4])
public Spit_State(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return
	set_pev(ent, pev_state, DIONE_STATE_ATTACK_POISON_1 + 1000)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
}
public Dione_Spit_Poison(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return		

	static Float:StartPoint[3], Float:Target[5][3]
	static Enemy; Enemy = pev(ent, pev_enemy)

	get_position(ent, 240.0, 0.0, 100.0, StartPoint)
	get_position(Enemy, random_float(-50.0, 50.0), random_float(-100.0, -50.0), random_float(-10.0, 10.0), Target[0])
	get_position(Enemy, random_float(-50.0, 50.0), random_float(-50.0, -0.0), random_float(-10.0, 10.0), Target[1])
	get_position(Enemy, random_float(-50.0, 50.0), 0.0			, random_float(-10.0, 10.0), Target[2])
	get_position(Enemy, random_float(-50.0, 50.0), random_float(0.0, 50.0), random_float(-10.0, 10.0), Target[3])
	get_position(Enemy, random_float(-50.0, 50.0), random_float(50.0, 100.0), random_float(-10.0, 10.0), Target[4])
	
	
	for(new i = 0; i < 5; i++) Create_PoisonBall(ent, StartPoint, Target[i])
	set_pev(ent, pev_state, DIONE_STATE_ATTACK_POISON_1)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
}
public Dione_End_Attack_Poison(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, DIONE_STATE_SEARCHING_ENEMY)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}
public Create_PoisonBall(ent, Float:Origin[3], Float:Target[3])
{
	static Poison; Poison = create_entity("info_target")

	engfunc(EngFunc_SetOrigin, Poison, Origin)
	Target[2]-=30.0
	MM_Aim_To(Poison, Target)
	
	set_pev(Poison, pev_classname, "dione_poison")
	engfunc(EngFunc_SetModel, Poison, skill_posion[0])
	set_pev(Poison, pev_solid, SOLID_TRIGGER)
	set_pev(Poison, pev_movetype, MOVETYPE_FLY)
	set_pev(Poison, pev_owner, pev(ent, pev_owner))
	set_pev(Poison, pev_rendermode, kRenderTransAdd)
	set_pev(Poison, pev_renderamt, 255.0)	
	
	new Float:maxs[3] = {1.0,1.0,1.0}
	new Float:mins[3] = {-1.0,-1.0,-1.0}
	entity_set_size(Poison, mins, maxs)
	
	hook_ent2(Poison, Target, 2000.0)
}
public Remove_Poison(ent)
{
	remove_entity(ent)
}
public fw_PoisonTouch(Ent, Id)
{
	if(!pev_valid(Ent))
		return
		
	new Classname[32]
	if(pev_valid(Id)) pev(Id, pev_classname, Classname, sizeof(Classname))	
	if(equal(Classname, "dione_poison") || equal(Classname, DIONE_CLASSNAME))
		return
		
	static id; id = pev(Ent, pev_owner)
	static Float:Origin[3]; pev(Ent, pev_origin, Origin)
	static Float:Angles[3]; pev(Ent, pev_angles, Angles)
	set_pev(Ent, pev_flags, FL_KILLME)
	
	emit_sound(Ent, CHAN_BODY, DioneSound[5], 1.0, ATTN_NORM, 0, PITCH_NORM)
	Create_PoisonZone(id, Origin, Angles)
	Create_PoisonEffect(Origin)
	Check_PoisonDamge(id, Origin)
}

public Check_PoisonDamge(id, Float:Origin[3])
{
	static Float:POrigin[3]
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		pev(i, pev_origin, POrigin)
		if(get_distance_f(Origin, POrigin) > 200.0)
			continue
		if(i==pev(id, pev_owner))
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, id, id, POISON_DAMAGE, DMG_BULLET)
		Make_PlayerShake(i)
	}
}

public Create_PoisonZone(id, Float:Origin[3], Float:Angles[3])
{
	// Create Ground
	static Effect; Effect = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Effect)) return
		
	set_pev(Effect, pev_origin, Origin)
	Angles[0] = 0.0
	set_pev(Effect, pev_angles, Angles)
	
	// Set Config
	set_pev(Effect, pev_classname, "dione_effect")
	engfunc(EngFunc_SetModel, Effect, skill_posion[1])
	set_pev(Effect, pev_solid, SOLID_TRIGGER)
	set_pev(Effect, pev_movetype, MOVETYPE_TOSS)
	
	fm_set_rendering(Effect, kRenderFxNone, 100, 100, 100, kRenderTransAdd, 255)
	
	// Set Size
	new Float:maxs[3] = {1.0, 1.0, 1.0}
	new Float:mins[3] = {-1.0, -1.0, -1.0}
	engfunc(EngFunc_SetSize, Effect, mins, maxs)
	
	engfunc(EngFunc_DropToFloor, Effect)
	
	set_entity_anim(Effect, 0, 1.0)
	set_task(5.0, "Remove_Poison", Effect)
}

public Create_PoisonEffect(Float:Origin[3])
{
	// Make Explosion
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord(floatround(Origin[0]))	// start position
	write_coord(floatround(Origin[1]))
	write_coord(floatround(Origin[2] + 50.0))
	write_short(g_Exp_SprID)	// sprite index
	write_byte(random_num(15, 20))	// scale in 0.1's
	write_byte(random_num(5, 15))	// framerate
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOPARTICLES)	// flags
	message_end()
	/*
	// Make Explosion 2
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord(floatround(Origin[0]))	// start position
	write_coord(floatround(Origin[1]))
	write_coord(floatround(Origin[2] + 40.0))
	write_short(g_Exp2_SprID)	// sprite index
	write_byte(random_num(30, 40))	// scale in 0.1's
	write_byte(random_num(7, 20))	// framerate
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOPARTICLES)	// flags
	message_end()*/
}

public Dione_Attack_Tentacle(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return

	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_state, DIONE_STATE_ATTACK_TENTACLE_1)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
	
	set_pev(ent, pev_velocity, {0.0, 0.0, 0.0})

	if(random_num(0,1) == 1) // Tentacle 1
	{
		set_entity_anim(ent, DIONE_ANIM_ATTACK_TENTACLE_1, 1.0)	
		
		set_task(2.5, "Dione_Tentacle_Sound", 10)
		set_task(3.1, "Dione_Tentacle", ent+TASK_ATTACK)
		set_task(5.4, "Dione_Tentacle", ent+TASK_ATTACK)
		set_task(7.3, "Dione_End_Attack_Tentacle", ent+TASK_ATTACK)
		
	} else { // Tentacle 2
		set_entity_anim(ent, DIONE_ANIM_ATTACK_TENTACLE_2, 1.0)
		
		set_task(2.4, "Dione_Tentacle_Sound", 11)
		set_task(2.8, "Dione_Tentacle", ent+TASK_ATTACK)
		set_task(3.8, "Dione_Tentacle", ent+TASK_ATTACK)
		set_task(5.0, "Dione_Tentacle", ent+TASK_ATTACK)
		set_task(6.0, "Dione_Tentacle", ent+TASK_ATTACK)
		set_task(7.6, "Dione_Tentacle", ent+TASK_ATTACK)
		set_task(10.7, "Dione_End_Attack_Tentacle", ent+TASK_ATTACK)
	}	
}
public Dione_Tentacle_Sound(index) PlaySound(0,DioneSound[index])
public Dione_Tentacle(ent)
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
public Dione_End_Attack_Tentacle(ent)
{
	ent -= TASK_ATTACK
	if(!pev_valid(ent))
		return	
		
	set_pev(ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ent, pev_state, DIONE_STATE_SEARCHING_ENEMY)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}
public Create_Tentacle(Dione, Float:Origin[3], Float:Angles[3])
{
	new Float:num, ent = create_entity("info_target")

	Origin[2] += 5.0
	
	entity_set_origin(ent, Origin)
	entity_set_vector(ent, EV_VEC_v_angle, Angles)
	
	entity_set_string(ent,EV_SZ_classname, "tentacle")
	entity_set_model(ent, skill_tentacle[0])
	entity_set_int(ent, EV_INT_solid, SOLID_NOT)
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_owner, pev(Dione, pev_owner))
	
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
		
	emit_sound(ent, CHAN_BODY, DioneSound[12], 1.0, ATTN_NORM, 0, PITCH_NORM)
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
public DIONE_Death(ent)
{
	if(!pev_valid(ent))
		return
	
	remove_task(ent+TASK_ATTACK)
	remove_task(ent+TASK_GAME_START)
	
	set_entity_anim(ent, DIONE_ANIM_EXIT_1, 1.0)	
	set_pev(ent, pev_state, DIONE_STATE_EXIT)
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
	
	PlaySound(0, DioneSound[13])
	set_task(10.0, "DIONE_Death2", ent)
}

public DIONE_Death2(ent)
{		
	set_entity_anim(ent, DIONE_ANIM_EXIT_2, 1.0)
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_task(10.0, "DIONE_Death3", ent)
}

public DIONE_Death3(ent)
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
