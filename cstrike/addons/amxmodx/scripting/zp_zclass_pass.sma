/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <zombieplague>
#include <fakemeta>
#include <hamsandwich> 
#include <cstrike> 
#include <toan> 
#include <engine> 

#define PLUGIN "[CSO LIKE] Blotter zombie"
#define VERSION "0.1"
#define AUTHOR "Barney"

enum (+= 100)
{
	TASK_WAIT = 2000,
	TASK_ATTACK,
	TASK_BOT_USE_SKILL,
	TASK_USE_SKILL
}

native is_max_KnockbackNade (id)

// IDs inside tasks
#define ID_WAIT (taskid - TASK_WAIT)
#define ID_ATTACK (taskid - TASK_ATTACK)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)
#define ID_USE_SKILL (taskid - TASK_USE_SKILL)

#define OFFSET_AMMO_SG_32BIT 389
#define OFFSET_AMMO_SG_64BIT 438
#define OFFSET_AMMO_LINUXDIFF 5

new const NADE_WEAPON_NAME[] = "weapon_smokegrenade" // nade weapon name

new vzombi
new cvar_debug

new const models[] = {"pass_zombi_origin"};

new g_sound[][] = 
{
	"zombie_plague/passzombie_death1.wav" ,
	"zombie_plague/passzombie_death2.wav" ,
	"zombie_plague/passzombie_hurt1.wav" ,
	"zombie_plague/passzombie_hurt2.wav"
};
new g_iCurrentWeapon[33], g_MaxPlayers
new const zclass1_bombmodel[] = { "models/zombie_plague/v_zombibomb_pass.mdl" }
new const g_WorldModel[] = "models/zombie_plague/w_zombibomb.mdl"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	register_event("DeathMsg", "Death", "a");
	register_event("CurWeapon", "EV_CurWeapon", "be", "1=1")
	register_forward(FM_PlayerPreThink, "fm_pthink")

	register_think("real_jump_nade", "fw_ThinkGrenade")
	register_touch("real_jump_nade", "*", "fw_TouchGrenade")

	register_logevent("roundStart", 2, "1=Round_Start")
	register_clcmd("drop", "cmd_drop");
	cvar_debug = register_cvar("zp_bot_skill_debug", "0")
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache() {
	for(new i = 0; i < sizeof g_sound; i++)
		precache_sound(g_sound[i]);

	precache_model(zclass1_bombmodel)
	precache_model(g_WorldModel)
	vzombi = zp_register_zombie_class("Blotter", "", models, "v_knife_zombipass.mdl", 3100, 290, 0.8, 1.45);
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
	reset_value_player(id)

	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id)==vzombi && !zp_get_user_nemesis(id) && !zp_get_user_assassin(id))
	{
		engfunc( EngFunc_EmitSound, id, CHAN_ITEM, g_sound[random_num(0,1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}
public EV_CurWeapon(id)
{
	if(!is_user_alive(id) || !zp_get_user_zombie(id))
		return PLUGIN_CONTINUE
		
	g_iCurrentWeapon[id] = read_data(2)
	if(g_iCurrentWeapon[id] == CSW_SMOKEGRENADE && zp_get_user_zombie_class(id) == vzombi)
	{
		set_pev(id, pev_viewmodel2, zclass1_bombmodel)
	}
	return PLUGIN_CONTINUE
}
public fw_TakeDamage(id, iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamage)
{
	if (zp_get_user_zombie_class(id)==vzombi && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && !zp_get_user_assassin(id))
	{
		emit_sound(id, CHAN_WEAPON, g_sound[random_num(2,3)], 1.0, ATTN_NORM, 0, PITCH_LOW)
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
public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_bot(id)) return;

	engclient_cmd(id, NADE_WEAPON_NAME)
	client_cmd(id, NADE_WEAPON_NAME)
	cmd_drop(id)
	if (task_exists(taskid)) remove_task(taskid)
	set_task(float(random_num(5,10)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}
public fm_pthink(id){
	if(!is_user_alive(id))
		return 
	if(entity_get_int(id, EV_INT_button) & IN_USE){
		static Float:fLastUse[33]
		if(zp_get_user_zombie(id)&&!zp_get_user_nemesis(id)&&!zp_get_user_assassin(id)&& zp_get_user_zombie_class(id) == vzombi
		&& fLastUse[id] + 3.0 < get_gametime() && pev(id, pev_health) >= 1000.0) 
		{
			if (is_user_bot(id)&&get_pcvar_num(cvar_debug))
				return;

			set_pev(id, pev_health, pev(id, pev_health) - 1000.0)
			KnockbackNade(id)

			engclient_cmd(id, NADE_WEAPON_NAME)
			client_cmd(id, NADE_WEAPON_NAME)

			set_pdata_float(id , 83, 2.0 , 5) 

			Set_WeaponAnim(id, 5)
			fLastUse[id] = get_gametime();
		}
	}
}
static Float:fLastUseDrop[33]
public cmd_drop(id) {
	if(is_user_alive(id) && zp_get_user_zombie(id)&&!zp_get_user_nemesis(id)&&!zp_get_user_assassin(id)&& zp_get_user_zombie_class(id) == vzombi && fLastUseDrop[id] + 3.0 < get_gametime()) 
	{
		if(get_user_weapon(id) != CSW_SMOKEGRENADE)
			return

		if (is_user_bot(id)&&get_pcvar_num(cvar_debug))
			return;

		if(is_user_bot(id))
			KnockbackNade(id)

		engclient_cmd(id, NADE_WEAPON_NAME)
		client_cmd(id, NADE_WEAPON_NAME)

		set_pdata_float(id , 83, 1.5 , 5) 
		Set_WeaponAnim(id, 4)

		set_task(1.4, "drop_nade", id)
		fLastUseDrop[id] = get_gametime();
	}
}
public drop_nade(id){
	if(!zp_get_user_zombie(id)||zp_get_user_nemesis(id)||zp_get_user_assassin(id)||!is_user_alive(id)) 
		return;

	new nade = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite")) // create nade entity
	if (!nade) { // if nade entity not created
		return 
	}

	new iBpAmmo = cs_get_user_bpammo(id, CSW_SMOKEGRENADE)
	if(!iBpAmmo)
		return

	cs_set_user_bpammo(id, CSW_SMOKEGRENADE, --iBpAmmo)

	engclient_cmd(id, NADE_WEAPON_NAME) // switch to nade
	engclient_cmd(id, "lastinv") // switch to previous weapon

	set_pev(nade, pev_movetype, MOVETYPE_TOSS)
	set_pev(nade, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(nade, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(nade, pev_gravity, 1.0)
	set_pev(nade, pev_owner, id)
	set_pev(nade, pev_solid, SOLID_TRIGGER)
	set_pev(nade, pev_classname, "real_jump_nade") // set nade unique classname
	set_pev(nade, pev_fuser1, get_gametime() + 2.0) // set nade unique classname

	// setup nade start origin
	new Float:origin[3]
	pev(id, pev_origin, origin)
	engfunc(EngFunc_SetOrigin, nade, origin)

	entity_set_model(nade, g_WorldModel)

	// setup nade angles
	new Float:angles[3]
	pev(id, pev_angles, angles)
	angles[0] = 0.0 // we don't need specific vertical angle
	angles[1] += 0
	set_pev(nade, pev_angles, angles)

	// setup nade velocity
	new Float:anglevec[3], Float:velocity[3]
	pev(id, pev_v_angle, anglevec)
	engfunc(EngFunc_MakeVectors, anglevec)
	global_get(glb_v_forward, anglevec)
	velocity[0] = anglevec[0] * 350
	velocity[1] = anglevec[1] * 350
	velocity[2] = anglevec[2] * 350
	set_pev(nade, pev_velocity, velocity)
	set_pev(nade, pev_nextthink, get_gametime() + 0.1)

	//dllfunc(DLLFunc_Spawn, nade) // spawn nade
}
public fw_ThinkGrenade(ent){
	if(!pev_valid(ent))
		return

	static i, Float:Origin[3], Float:Speed
	pev(ent, pev_origin, Origin)
	for(i=0;i<g_MaxPlayers;i++)
	{
		if(is_user_alive(i)
		 && i!=pev(ent, pev_owner)
		 && entity_range(ent, i) <= 100.0
		 && zp_core_is_zombie(i)
		 && is_user_bot(i)
		 )
		{
			Speed = (400.0 / entity_range(ent, i)) * 75.0
			
			hook_ent2(i, Origin, Speed)	
		}
	}		
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}
public fw_TouchGrenade(ent, toucher){
	if(!pev_valid(ent) || !is_user_connected(toucher) || !is_user_alive(toucher) || !zp_core_is_zombie(toucher))
		return

	if(pev(ent, pev_fuser1) > get_gametime())
		return

	if(is_max_KnockbackNade(toucher))
		return;

	KnockbackNade(toucher)
	set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
}

public asd(id)
{
	if ((zp_get_user_zombie_class(id) == vzombi) && zp_get_user_zombie(id))
	{
		client_print(id, print_center,"Cool down finish! [G]")
	}
}

stock Set_WeaponAnim(id, Anim)
{
	set_pev(id, pev_weaponanim, Anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(Anim)
	write_byte(pev(id, pev_body))
	message_end()
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