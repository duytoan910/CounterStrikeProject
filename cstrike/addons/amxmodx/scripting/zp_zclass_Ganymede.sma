#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <fun>
#include <toan> 

#define PLUGIN "[CSO:Hunter Zombie]"
#define VERSION "1.2"
#define AUTHOR "HoRRoR/tERoR edit"

const OFFSET_LINUX = 5
const OFFSET_PAINSHOCK = 108

enum (+= 100)
{
	TASK_WAIT = 2000,
	TASK_ATTACK,
	TASK_BOT_USE_SKILL,
	TASK_USE_SKILL,
	TASK_USE_ANIM
}
// IDs inside tasks
#define ID_WAIT (taskid - TASK_WAIT)
#define ID_ATTACK (taskid - TASK_ATTACK)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)
#define ID_USE_SKILL (taskid - TASK_USE_SKILL)
#define ID_USE_ANIM (taskid - TASK_USE_ANIM)

// Zombie Attributes
new const zclass_name[] = "Ganymede"
new const zclass_info[] = ""
new const zclass_model[] = {"deimos2_zombi_host","deimos2_zombi_origin"} // model
new const zclass_clawmodel[] = "v_knife_deimos2_zombi.mdl" // claw model
const zclass_health = 3400 // health
const zclass_speed = 280 // speed
const Float:zclass_gravity = 0.8 // gravity
const Float:zclass_knockback =  1.45 // knockback
new g_iCurrentWeapon[33]
new const zclass1_bombmodel[] = { "models/zombie_plague/v_zombibomb_deimos2_zombi.mdl" }


new Float:g_fastspeed = 250.0 // sprint speed 340
new Float:g_normspeed = 280.0 // norm speed. must be as zclass_speed
new Float:g_skill_wait = 5.0 // cooldown time
new Float:g_skill_length = 5.0 // time of sprint
new const sound_china_sprint[] = "zombie_plague/china_spd.wav" //sprint sound
new g_sound[][] = 
{
	"zombie_plague/zombi_death_1.wav" ,
	"zombie_plague/zombi_death_2.wav" ,
	"zombie_plague/zombi_hurt_01.wav" ,
	"zombie_plague/zombi_hurt_02.wav"
};
// ----------------------------------- //
new g_zclass_china
new g_skill_used[33] = 0
new g_maxplayers, cvar_debug
new g_wait[33]
public plugin_precache()
{
	g_zclass_china = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)	
	precache_sound(sound_china_sprint)
	for(new i = 0; i < sizeof g_sound; i++)
		precache_sound(g_sound[i]);
	precache_model(zclass1_bombmodel)
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("drop", "useabilityone")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post",1);
	register_event("DeathMsg", "Death", "a");
	register_event("CurWeapon", "EV_CurWeapon", "be", "1=1")

	register_forward( FM_PlayerPreThink, "client_prethink" )
	register_forward( FM_PlayerPostThink, "fw_PlayerPostThink" )
	register_logevent("roundStart", 2, "1=Round_Start")
	register_forward(FM_EmitSound, "fw_EmitSound")
	g_maxplayers = get_maxplayers()
	cvar_debug = register_cvar("zp_bot_skill_debug", "0")
}

public EV_CurWeapon(id)
{
	if(!is_user_alive(id) || !zp_get_user_zombie(id))
		return PLUGIN_CONTINUE
		
	g_iCurrentWeapon[id] = read_data(2)
	if(g_iCurrentWeapon[id] == CSW_SMOKEGRENADE && zp_get_user_zombie_class(id) == g_zclass_china)
	{
		set_pev(id, pev_viewmodel2, zclass1_bombmodel)
	}
	return PLUGIN_CONTINUE
}
public client_prethink(id)
{
	if (zp_get_user_zombie_class(id) == g_zclass_china)
	{
		if(is_user_alive(id) && zp_get_user_zombie(id) && (zp_get_user_zombie_class(id) == g_zclass_china) && !zp_get_user_nemesis(id))
		Action(id);
	}
}
new g_setAnim[33]
public fw_PlayerPostThink(id)
{
	if (zp_get_user_zombie_class(id) == g_zclass_china)
	{
		if(is_user_alive(id) && zp_get_user_zombie(id) && (zp_get_user_zombie_class(id) == g_zclass_china) && !zp_get_user_nemesis(id)){
			new button = pev(id, pev_button)
			if(IsCurrentSpeedHigherThan(id, 200.0)){
				if (!(button & IN_DUCK || button & IN_JUMP || button & IN_BACK) && !g_setAnim[id])
				{
					g_setAnim[id] = true
					Player_SetAnimation(id, "ref_aim_knife_run")
					set_task(1.9, "unlockAnim", id+TASK_USE_ANIM)
				}else if((button & IN_DUCK || button & IN_JUMP || button & IN_BACK)){
					Player_SetAnimation(id, "ref_aim_knife_walk")
					if (task_exists(id+TASK_USE_ANIM)){
						g_setAnim[id] = false
						remove_task(id+TASK_USE_ANIM)
					}
				}
			}else{
				if((button & IN_FORWARD || button & IN_LEFT || button & IN_RIGHT || button & IN_BACK)){
					Player_SetAnimation(id, "ref_aim_knife_walk")
					if (task_exists(id+TASK_USE_ANIM)){
						g_setAnim[id] = false
						remove_task(id+TASK_USE_ANIM)
					}
				}
			}
		}
	}
	return FMRES_HANDLED
}
public unlockAnim(taskid){
	new id = ID_USE_ANIM;
	g_setAnim[id] = false
}
new g_bot
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
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage_Post" ,1)
}
public Death(id)
{
	new id = read_data(2)

	set_task(0.1, "set_normal_speed",id)	
	g_wait[id] = 0
	
	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id)==g_zclass_china && !zp_get_user_nemesis(id))
	{
		engfunc( EngFunc_EmitSound, id, CHAN_ITEM, g_sound[random_num(0,1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}
public fw_TakeDamage_Post(id, iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamage)
{
	if (zp_get_user_zombie_class(id)==g_zclass_china && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
		emit_sound(id, CHAN_WEAPON, g_sound[random_num(2,3)], 0.7, ATTN_NORM, 0, PITCH_LOW)
	}

	if (zp_get_user_zombie_class(id)==g_zclass_china && zp_get_user_zombie(id))
	{
        if(g_skill_used[id] == 1){
		    set_pdata_float(id, OFFSET_PAINSHOCK, 1.0, OFFSET_LINUX)
        }
	}
}
public client_connect(id)
{
	reset_value_player(id)
}
public client_disconnect(id)
{
	reset_value_player(id)
}
reset_value_player(id)
{
	if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
	
	for (new i = 1; i <= g_maxplayers; i++)
	{
		g_skill_used[i] = 0
		g_wait[i] = 0
		remove_task(i)
		client_cmd(id,"cl_forwardspeed 400")
		client_cmd(id,"cl_backspeed 400")
		client_cmd(id, "cl_sidespeed 400");
	}
}
public Action(id)
{
	if (g_skill_used[id] == 1)
	{
		set_user_maxspeed(id , g_fastspeed); 
	}
	else
	{
		set_user_maxspeed(id , g_normspeed); 
	}
	return PLUGIN_HANDLED;
} 

stock IsCurrentSpeedHigherThan(id, Float:fValue)
{
    new Float:fVecVelocity[3]
    entity_get_vector(id, EV_VEC_velocity, fVecVelocity)
    
    if(vector_length(fVecVelocity) > fValue)
        return true
    
    return false
} 
public roundStart(id)
{
	for (new id=1; id<33; id++)
	{
		if (!is_user_connected(id)) continue;
		if (is_user_bot(id))
		{
			if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
			set_task(float(5), "bot_use_skill", id+TASK_BOT_USE_SKILL)
		}
	}
}
public bot_use_skill(taskid)
{	
	new id = ID_BOT_USE_SKILL
	if (!is_user_bot(id)) return;

	useabilityone(id)
	if (task_exists(taskid)) remove_task(taskid)
	set_task(float(random_num(5,10)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

public useabilityone(id)
{
	if (is_user_alive(id) && (zp_get_user_zombie_class(id) == g_zclass_china) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && !g_wait[id] && g_skill_used[id] != 1)
	{
		if (is_user_bot(id)&&get_pcvar_num(cvar_debug))
			return	
			
		//SetRendering(id, kRenderFxGlowShell, 255, 3, 0, kRenderNormal, 0);
		
		md_zb_skill(id, 0)
		g_skill_used[id] = 1

		emit_sound(id, CHAN_WEAPON, sound_china_sprint, 1.0, ATTN_NORM, 0, PITCH_NORM)
		client_cmd(id,"cl_forwardspeed 600")
		client_cmd(id,"cl_backspeed 600")
		client_cmd(id, "cl_sidespeed 600");
		set_task(g_skill_length, "set_normal_speed", id)
	}
}

public set_normal_speed(id)
{
	if ((zp_get_user_zombie_class(id) == g_zclass_china) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
		g_skill_used[id] = 0	
		
		client_cmd(id,"cl_forwardspeed 400")
		client_cmd(id,"cl_backspeed 400")
		client_cmd(id, "cl_sidespeed 400");
		set_task(g_skill_wait, "remove_count_down",id)	
		//fm_set_rendering(id)
	}
}
public remove_count_down(id)
{
	if ((zp_get_user_zombie_class(id) == g_zclass_china) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
		g_wait[id] = 0
		client_print(id, print_center,"Cool down finish! [G]")
	}	
}
public zp_user_infected_post(id, infector)
{
	if ((zp_get_user_zombie_class(id) == g_zclass_china) && !zp_get_user_nemesis(id))
	{		
		remove_task(id)
		g_wait[id] = 0
		g_skill_used[id] = 0
	}
}

public zp_user_humanized_post(id)
{
	remove_task(id)
	client_cmd(id,"cl_forwardspeed 400")
	client_cmd(id,"cl_backspeed 400")
	client_cmd(id, "cl_sidespeed 400");
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id))
		return FMRES_HANDLED;	

	if (sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e')
		return FMRES_SUPERCEDE;


	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_china && !zp_get_user_nemesis(id))
	{
		if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
		{

		}
	}
	return FMRES_IGNORED;
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
