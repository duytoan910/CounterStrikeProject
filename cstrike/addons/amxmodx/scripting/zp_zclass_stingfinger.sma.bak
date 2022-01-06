#include <amxmodx>
#include <zombieplague>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>
#include <fun>

new const PLUGIN[] = "[CSO] Class Sting Finger"
new const VERSION[] = "2.0"
new const AUTHOR[] =  "m4m3ts"

new const zclass_name[] = "Sting Finger" // name 
new const zclass_info[] = " " // description 
new const zclass_model[] = "resident_zombi_host" // model 
new const zclass_clawmodel[] = "v_knife_resident_zombi.mdl" // claw model 
const zclass_health = 3200 // health 
const zclass_speed = 280 // speed 
const Float:zclass_gravity = 0.8 // gravity 
const Float:zclass_knockback = 1.25 // knockback 

const Float:finger_heal  = 2000.0
const Float:armtime = 12.0
const Float:healtime = 8.0

const dmg_long = 80 //Дамаг вытягивания рук;
const Distance = 130 //Дистанция для вытягивание рук;
const MAX_CLIENTS = 32 ;

const FINGER_MAX_STRING = 128;

enum _:FINGER_ANIMATIONS
{
	LongDamageAnim   = 8,
	GravAnim      = 9,
	EndGrav        = 10,
	skill1        = 91,
	skill2       = 98
};

enum _:FINGER_SOUNDS
{
	SKILL1 = 0,
	SKILL2,
	DEATH,
	PAIN1,
	PAIN2
};
enum (+= 100)
{
	TASK_WAIT = 2000,
	TASK_ATTACK,
	TASK_BOT_USE_SKILL,
	TASK_USE_SKILL
}
// IDs inside tasks
#define ID_WAIT (taskid - TASK_WAIT)
#define ID_ATTACK (taskid - TASK_ATTACK)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)
#define ID_USE_SKILL (taskid - TASK_USE_SKILL)
new g_stinger_sound[FINGER_SOUNDS][FINGER_MAX_STRING] = 
{
	"zombie_plague/resident_skill1.wav",
	"zombie_plague/resident_skill2.wav",
	"zombie_plague/resident_death.wav" ,
	"zombie_plague/resident_hurt1.wav" ,
	"zombie_plague/resident_hurt2.wav"
};

new class_sting,g_coldown[33],g_coldownheal[33]
new g_bot,cvar_debug

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR) ;

	register_event("DeathMsg", "Death", "a");
	register_logevent("logevent_round_end", 2, "1=Round_End");
	register_logevent("roundStart", 2, "1=Round_Start")	
	RegisterHam(Ham_TakeDamage, "player", "String_TakeDamage");
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink" , 1)
	
	register_clcmd("drop","cmd_arm")
	register_clcmd("lastinv","cmd_heal")
	cvar_debug = register_cvar("zp_bot_skill_debug", "0")
}

public plugin_precache()
{	
	static i ;
	
	for(i = 0; i < sizeof g_stinger_sound; i++)
	{
		precache_sound(g_stinger_sound[i]);
	}
	class_sting = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)      
}
public client_putinserver(id)
{
	if(is_user_bot(id) && !g_bot)
	{
		g_bot = 1
		set_task(0.1, "Do_RegisterHamBot", id)
	}
}
public Do_RegisterHamBot(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "String_TakeDamage")
}
public roundStart(id)
{
	for (new id=1; id<33; id++)
	{
		if (!is_user_connected(id)) continue;
		if (is_user_bot(id))
		{
			if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
			set_task(float(20), "bot_use_skill", id+TASK_BOT_USE_SKILL)
		}
	}
}
public logevent_round_end(id)
{
	reset_value_player(id)
}
public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_bot(id)) return;

	cmd_heal(id)
	
	if (task_exists(taskid)) remove_task(taskid)
	set_task(float(random_num(10,15)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}
public fw_PlayerPostThink(id)
{
	if(!is_user_alive(id) || !is_user_bot(id))
		return PLUGIN_HANDLED
	
	new enemy, body
	get_user_aiming(id, enemy, body)
	if ((1 <= enemy <= 32) && !zp_get_user_zombie(enemy))
	{
		new origin1[3] ,origin2[3],range
		get_user_origin(id,origin1)
		get_user_origin(enemy,origin2)
		range = get_distance(origin1, origin2)
		if(range <= Distance) cmd_arm(id)
	}
	return PLUGIN_CONTINUE
}
public Death(id)
{
	new id = read_data(2)

	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id)==class_sting && !zp_get_user_nemesis(id))
	{
		engfunc( EngFunc_EmitSound, id, CHAN_ITEM, g_stinger_sound[DEATH], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}
public String_TakeDamage(id, iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamage)
{
	if (zp_get_user_zombie_class(id)==class_sting && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
		switch(random_num(1,2))
  		{
			case 1: emit_sound(id, CHAN_WEAPON, g_stinger_sound[PAIN1], 0.7, ATTN_NORM, 0, PITCH_LOW)
			case 2: emit_sound(id, CHAN_WEAPON, g_stinger_sound[PAIN2], 0.7, ATTN_NORM, 0, PITCH_LOW)
		}
	}
} 
public cmd_heal(id)
{
	if (!is_user_alive(id))
		return
	if(!zp_get_user_zombie(id))
		return
		
	if(zp_get_user_zombie_class(id)==class_sting && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{	
		if (is_user_bot(id)&&get_pcvar_num(cvar_debug))
			return
		if(g_coldownheal[id] == 0)
		{
			g_coldownheal[id]=1
			UTIL_PlayAnim(id , GravAnim) 
			set_pdata_float(id , 83, 2.5 , 5) 
			Player_SetAnimation(id, "skill2")
			set_task(1.5, "UTIL_Heal", id)
			set_task(healtime,"reset_heal",id)
		}
	}	
}
public UTIL_Heal(id)
{
	if (!is_user_alive(id))
	{
		return FMRES_IGNORED
	}
	
	if(zp_get_user_zombie_class(id)==class_sting && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
		
		UTIL_PlayAnim( id , EndGrav ) 
		
		emit_sound(id, CHAN_WEAPON, g_stinger_sound[SKILL2], 1.0, ATTN_NORM, 0, PITCH_LOW)
		
		set_pev(id, pev_health, float(pev(id,pev_health)+2000));
		md_zb_skill(id, 1)
	}
	return FMRES_IGNORED 
}

public cmd_arm(id)
{	
	if(is_user_alive(id)&&zp_get_user_zombie_class(id)==class_sting && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{			
		if (is_user_bot(id)&&get_pcvar_num(cvar_debug))
			return

		if(g_coldown[id] == 0)
		{
			g_coldown[id]=1
			//set_uc(UC_Handle, UC_Buttons, IN_ATTACK2)
			Player_SetAnimation(id, "skill1")
			md_zb_skill(id, 0)
			UTIL_PlayAnim( id , LongDamageAnim ) 
			set_task(0.2, "UTIL_LongDamage", id)
			set_task(armtime,"reset_arm",id)
		}
	}	
}
public UTIL_LongDamage(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED
	
	if(zp_get_user_zombie_class(id)==class_sting && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{		
		emit_sound(id, CHAN_WEAPON, g_stinger_sound[SKILL1], 1.0, ATTN_NORM, 0, PITCH_LOW)
					
		set_pdata_float(id , 83, 1.0 , 5) 
		
		Skill(id) 
	}
	
	return FMRES_IGNORED 
}

stock Skill(id)
{
	if (!is_user_alive(id))
	{
		return FMRES_IGNORED;
	}
	
	static gBody , gTarget  
	get_user_aiming(id , gTarget , gBody , Distance) 
	
	if(gTarget)
	{
		if(is_user_alive(gTarget))
		{
			ExecuteHamB(Ham_TakeDamage, gTarget, id, id, float(dmg_long), DMG_BULLET)
		}
	}
	return FMRES_IGNORED 
}

public reset_arm(id)
{
	client_print(id, print_center,"Long Arm cool down finish! [G]")
	g_coldown[id] = false 
}
public reset_heal(id)
{
	client_print(id, print_center,"Heal cool down finish! [Q]")
	g_coldownheal[id] = false
}
reset_value_player(id)
{
	if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
}
stock UTIL_PlayAnim(id , seq)
{
	set_pev(id, pev_weaponanim, seq)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = id)
	write_byte(seq)
	write_byte(pev(id, pev_body))
	message_end()
}	

stock Player_SetAnimation(const iPlayer, const szAnim[])
{
	if(!is_user_alive(iPlayer))
		return;
		
	#define ACT_RANGE_ATTACK1   28
	   
	// Linux extra offsets
	#define extra_offset_animating   4
	   
	// CBaseAnimating
	#define m_flFrameRate      36
	#define m_flGroundSpeed      37
	#define m_flLastEventCheck   38
	#define m_fSequenceFinished   39
	#define m_fSequenceLoops   40
	   
	// CBaseMonster
	#define m_Activity      73
	#define m_IdealActivity      74
	   
	// CBasePlayer
	#define m_flLastAttackTime   220
	   
	new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
	      
	if ((iAnimDesired = lookup_sequence(iPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed)) == -1)
	{
		iAnimDesired = 0;
	}
	   
	new Float: flGametime = get_gametime();
	
	set_pev(iPlayer, pev_frame, 0.0);
	set_pev(iPlayer, pev_framerate, 1.0);
	set_pev(iPlayer, pev_animtime, flGametime );
	set_pev(iPlayer, pev_sequence, iAnimDesired);
	   
	set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, extra_offset_animating);
	set_pdata_int(iPlayer, m_fSequenceFinished, 0, extra_offset_animating);
	   
	set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, extra_offset_animating);
	set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, extra_offset_animating);
	set_pdata_float(iPlayer, m_flLastEventCheck, flGametime , extra_offset_animating);
	   
	set_pdata_int(iPlayer, m_Activity, ACT_RANGE_ATTACK1, 5);
	set_pdata_int(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, 5);   
	set_pdata_float(iPlayer, m_flLastAttackTime, flGametime , 5);
}
