#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>

/*================================================================================
 [Plugin Customization]
=================================================================================*/

#define SMOKE_TIME 10.0
#define SMOKE_TIMEWAIT 8.0
#define SMOKE_SIZE 8

// Classic Zombie Attributes
new zclass_name[32] = "Psycho"
new zclass_desc[32] = ""
new const zclass_hostmodel[] = "pc_zombi_host"
new const zclass_clawsmodelhost[] = "v_knife_pc_zombi.mdl"
new const zclass_health = 3200
new const zclass_speed = 280
new const Float:zclass_gravity = 0.8
new const Float:zclass_knockback = 1.25
new const DeathSound[2][] =
{
	"zombie_plague/zombi_death_1.wav",
	"zombie_plague/zombi_death_2.wav"
}
new const HurtSound[2][] = 
{
	"zombie_plague/zombi_hurt_01.wav",
	"zombie_plague/zombi_hurt_02.wav"	
}
new const sound_smoke[] = "zombie_plague/zombi_smoke.wav"
new const sprites_smoke[] = "sprites/zb_smoke.spr"

// Task offsets
enum (+= 100)
{
	TASK_SMOKE = 2000,
	TASK_SMOKE_EXP,
	TASK_WAIT_SMOKE,
	TASK_BOT_USE_SKILL
}

// IDs inside tasks
#define ID_SMOKE (taskid - TASK_SMOKE)
#define ID_SMOKE_EXP (taskid - TASK_SMOKE_EXP)
#define ID_WAIT_SMOKE (taskid - TASK_WAIT_SMOKE)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)

/*============================================================================*/

// Class IDs
new g_zclass,id_smoke1, cvar_debug

// Main Vars
new g_smoke[33], g_smoke_wait[33], Float:g_smoke_origin[33][3]

public plugin_init()
{
	register_plugin("[ZP] Default Zombie Classes", "4.3", "MeRcyLeZZ")

	// Events
	register_logevent("logevent_round_start",2, "1=Round_Start")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");

	cvar_debug = register_cvar("zp_bot_skill_debug", "0")
	
	// Client Cmd
	register_clcmd("drop", "cmd_smoke")
}

// Zombie Classes MUST be registered on plugin_precache
public plugin_precache()
{
	id_smoke1 = precache_model(sprites_smoke)
	engfunc(EngFunc_PrecacheSound, sound_smoke)
	for(new i = 0; i < sizeof DeathSound; i++)
		precache_sound(DeathSound[i]);
	for(new i = 0; i < sizeof HurtSound; i++)
		precache_sound(HurtSound[i]);
			
	// Register all classes
	g_zclass = zp_register_zombie_class(zclass_name, zclass_desc, zclass_hostmodel, zclass_clawsmodelhost, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
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
public event_round_start()
{
	for (new id=1; id<33; id++)
	{
		if (!is_user_connected(id)) continue;
		
		reset_value_player(id)
		if (task_exists(id+TASK_SMOKE)) remove_task(id+TASK_SMOKE)
		if (task_exists(id+TASK_WAIT_SMOKE)) remove_task(id+TASK_WAIT_SMOKE)
		if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
		g_smoke[id] = 0
	}
}
public logevent_round_start()
{
	for (new id=0; id<32; id++)
	{
		if (!is_user_connected(id)) continue;
		if (!is_user_alive(id)) continue;
		if (is_user_bot(id))
		{
			if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
			set_task(5.0, "bot_use_skill", id+TASK_BOT_USE_SKILL)
		}
	}
}
public Death()
{
	new victim = read_data(2) 

	reset_value_player(victim)
	if(zp_get_user_zombie(victim) && zp_get_user_zombie_class(victim)==g_zclass && !zp_get_user_nemesis(victim))
	{
		engfunc( EngFunc_EmitSound, victim, CHAN_ITEM, DeathSound[random_num(0,1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}
public fw_TakeDamage(id, iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamage)
{
	if (zp_get_user_zombie_class(id)==g_zclass && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
		emit_sound(id, CHAN_WEAPON, HurtSound[random_num(0,1)], 0.7, ATTN_NORM, 0, PITCH_LOW)
	}
}
public client_connect(id)
{
	reset_value_player(id)
	if (task_exists(id+TASK_SMOKE)) remove_task(id+TASK_SMOKE)
	if (task_exists(id+TASK_WAIT_SMOKE)) remove_task(id+TASK_WAIT_SMOKE)
	if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
}
public client_disconnect(id)
{
	reset_value_player(id)
	if (task_exists(id+TASK_SMOKE)) remove_task(id+TASK_SMOKE)
	if (task_exists(id+TASK_WAIT_SMOKE)) remove_task(id+TASK_WAIT_SMOKE)
	if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)	
}
reset_value_player(id)
{
	if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
	
	//g_smoke[id] = 0
	g_smoke_wait[id] = 0
}

// bot use skill
public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_bot(id)) return;

	cmd_smoke(id)
	if (task_exists(taskid)) remove_task(taskid)
	set_task(5.0, "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

// #################### MAIN PUBLIC ####################
// cmd smoke
public cmd_smoke(id)
{
	if (!is_user_alive(id)) return;
	if (is_user_alive(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass && !zp_get_user_nemesis(id) && !g_smoke[id] && !g_smoke_wait[id])
	{
		if (is_user_bot(id)&&get_pcvar_num(cvar_debug))
			return
			
		// set smoke
		g_smoke[id] = 1		
		g_smoke_wait[id] = 1
		
		md_zb_skill(id, 0)
		
		// task smoke exp
		pev(id,pev_origin,g_smoke_origin[id])
		if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
		set_task(0.1, "SmokeExplode", id+TASK_SMOKE_EXP)
		
		if (task_exists(id+TASK_SMOKE)) remove_task(id+TASK_SMOKE)
		set_task(SMOKE_TIME, "RemoveSmoke", id+TASK_SMOKE)
		
		// play sound
		PlaySound(id, sound_smoke)
		
		//client_print(id, print_center, "Fart!")
	}
}
public SmokeExplode(taskid)
{
	new id = ID_SMOKE_EXP
	
	// remove smoke
	if (!g_smoke[id])
	{
		if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
		return;
	}
	
	new Float:origin[3]
	origin[0] = g_smoke_origin[id][0]// + random_num(-75,75)
	origin[1] = g_smoke_origin[id][1]// + random_num(-75,75)
	origin[2] = g_smoke_origin[id][2]// + random_num(0,65)
	
	new flags = pev(id, pev_flags)
	if (!((flags & FL_DUCKING) && (flags & FL_ONGROUND)))
		origin[2] -= 36.0
	
	Create_Smoke_Group(id,origin)
	
	// task smoke exp
	if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
	set_task(1.0, "SmokeExplode", id+TASK_SMOKE_EXP)
	
	return;
}
public RemoveSmoke(taskid)
{
	new id = ID_SMOKE
	
	// remove smoke
	g_smoke[id] = 0
	if (task_exists(taskid)) remove_task(taskid)

	// set time wait
	g_smoke_wait[id] = 1
	if (task_exists(id+TASK_WAIT_SMOKE)) remove_task(id+TASK_WAIT_SMOKE)
	set_task(SMOKE_TIMEWAIT, "RemoveWaitSmoke", id+TASK_WAIT_SMOKE)
}
public RemoveWaitSmoke(taskid)
{
	new id = ID_WAIT_SMOKE
	g_smoke_wait[id] = 0
	client_print(id, print_center,"Cool down finish! [G]")
	if (task_exists(taskid)) remove_task(taskid)
}
PlaySound(id, const sound[])
{
	client_cmd(id, "spk ^"%s^"", sound)
}
Create_Smoke_Group(id,Float:position[3])
{
	new Float:origin[12][3]
	get_spherical_coord(position, 40.0, 0.0, 0.0, origin[0])
	get_spherical_coord(position, 40.0, 90.0, 0.0, origin[1])
	get_spherical_coord(position, 40.0, 180.0, 0.0, origin[2])
	get_spherical_coord(position, 40.0, 270.0, 0.0, origin[3])
	/*
	get_spherical_coord(position, 40.0, 0.0, 0.0, origin[0])
	get_spherical_coord(position, 40.0, 90.0, 0.0, origin[1])
	get_spherical_coord(position, 40.0, 180.0, 0.0, origin[2])
	get_spherical_coord(position, 40.0, 270.0, 0.0, origin[3])
	get_spherical_coord(position, 100.0, 0.0, 0.0, origin[4])
	get_spherical_coord(position, 100.0, 45.0, 0.0, origin[5])
	get_spherical_coord(position, 100.0, 90.0, 0.0, origin[6])
	get_spherical_coord(position, 100.0, 135.0, 0.0, origin[7])
	get_spherical_coord(position, 100.0, 180.0, 0.0, origin[8])
	get_spherical_coord(position, 100.0, 225.0, 0.0, origin[9])
	get_spherical_coord(position, 100.0, 270.0, 0.0, origin[10])
	get_spherical_coord(position, 100.0, 315.0, 0.0, origin[11])
	*/
	for (new i = 0; i < 4; i++)
	{
		create_Smoke(id,origin[i], id_smoke1, 100, 0)
	}
}
create_Smoke(id,const Float:position[3], sprite_index, life, framerate)
{	
	// Alphablend sprite, move vertically 30 pps
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SMOKE) // TE_SMOKE (5)
	engfunc(EngFunc_WriteCoord, position[0]) // position.x
	engfunc(EngFunc_WriteCoord, position[1]) // position.y
	engfunc(EngFunc_WriteCoord, position[2]) // position.z
	write_short(sprite_index) // sprite index
	write_byte(life) // scale in 0.1's
	write_byte(framerate) // framerate
	message_end()
	
	new a = FM_NULLENT
	while((a = find_ent_in_sphere(a, position, 180.0)) != 0)
	{
		//if (id == a)continue 
		if (!is_user_alive(a))continue 
		if (!zp_get_user_zombie(a))
		{
			if(pev(a, pev_takedamage) != DAMAGE_NO)
			{
				ExecuteHam(Ham_TakeDamage, a, id, id, random_float(8.0,10.0), (1<<7));
			}			
		}else{
			set_pev(a, pev_health, pev(a,pev_health) + 50.0)
		}
		
	}	
}
get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	new Float:length
	length  = redius * floatcos(vertical_angle, degrees)
	origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees)
	origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees)
	origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees)
}
