#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <fun>

#define PLUGIN "[CSO:Hunter Zombie]"
#define VERSION "1.2"
#define AUTHOR "HoRRoR/tERoR edit"

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

// Zombie Attributes
new const zclass_name[] = "Berserker"
new const zclass_info[] = ""
new const zclass_model[] = "tank_zombi_host" // model
new const zclass_clawmodel[] = "v_knife_tank_zombi.mdl" // claw model
const zclass_health = 3100 // health
const zclass_speed = 290 // speed
const Float:zclass_gravity = 0.8 // gravity
const Float:zclass_knockback =  1.45 // knockback

new Float:g_fastspeed = 400.0 // sprint speed 340
new Float:g_normspeed = 290.0 // norm speed. must be as zclass_speed
new Float:g_skill_wait = 5.0 // cooldown time
new Float:g_skill_length = 10.0 // time of sprint
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
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("drop", "useabilityone")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	register_event("DeathMsg", "Death", "a");

	register_event("CurWeapon", "Event_CurrentWeapon", "be", "1=1")
	register_forward( FM_PlayerPreThink, "client_prethink" )
	register_logevent("roundStart", 2, "1=Round_Start")
	register_forward(FM_EmitSound, "fw_EmitSound")
	g_maxplayers = get_maxplayers()
	cvar_debug = register_cvar("zp_bot_skill_debug", "0")
}


public client_prethink(id)
{
	if (zp_get_user_zombie_class(id) == g_zclass_china)
	{
		if(is_user_alive(id) && zp_get_user_zombie(id) && (zp_get_user_zombie_class(id) == g_zclass_china) && !zp_get_user_nemesis(id))
		Action(id);
	}
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
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
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
public fw_TakeDamage(id, iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamage)
{
	if (zp_get_user_zombie_class(id)==g_zclass_china && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
		emit_sound(id, CHAN_WEAPON, g_sound[random_num(2,3)], 0.7, ATTN_NORM, 0, PITCH_LOW)
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


public Event_CurrentWeapon(id)
{

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
