#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <toan> 

/*================================================================================
 [Plugin Customization]
=================================================================================*/

#define DAMAGE_BURN 1.0
#define DAMAGE_RADIUS 30.0
#define SPIT_TIMEWAIT 17.0

// Classic Zombie Attributes
new const zclass_name[] = { "Spitter" } 
new const zclass_info[] = { "" } 
new const zclass_model[] = { "SpitterL4D2" } 
new const zclass_clawmodel[] = { "v_Spitter_hands.mdl" } 
const zclass_health = 2200
const zclass_speed = 280
const Float:zclass_gravity = 0.8 
const Float:zclass_knockback = 0.8  

new const WeaponResources[][] = 
{
	"sprites/spr_boomer.spr"
}

new const death_exp_effect_model2[] = "models/zombie_plague/ef_poison03.mdl" 
new const spit_model[] = "models/spit.mdl" // HAlF-Life model
new const Spitter_spitlaunch[] = "zombie_plague/spitter_spit.wav"
new const Spitter_spithit[] = "bullchicken/bc_attack2.wav" // HAlF-Life model
new const Spitter_dieacid_start[] = "bullchicken/bc_acid2.wav"

new const DeathSound[2][] =
{
	"zombie_plague/zombi_death_1.wav",
	"zombie_plague/zombi_death_2.wav"
}
new const HurtSound[2][] = 
{
	"zombie_plague/resident_hurt1.wav" ,
	"zombie_plague/resident_hurt2.wav"	
}

// Task offsets
enum (+= 100)
{
	TASK_SPIT = 21235,
	TASK_SPIT_EXP,
	TASK_WAIT_SPIT,
	TASK_BOT_USE_SKILL
}

// IDs inside tasks
#define ID_SPIT (taskid - TASK_SPIT)
#define ID_SPIT_EXP (taskid - TASK_SPIT_EXP)
#define ID_WAIT_SPIT (taskid - TASK_WAIT_SPIT)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)
#define MOLOTOV_CLASSNAME "spitpoison"
#define FLAME_FAKE_CLASSNAME "spitpoison_fake"
#define FIRE2_CLASSNAME "smallpoison"

/*============================================================================*/

// Class IDs
new g_zclass, cvar_debug, spr_trail,g_ExpSprId, cvar_optimize

// Main Vars
new g_SPIT_wait[33]

public plugin_init()
{
	register_plugin("[ZP] Default Zombie Classes", "4.3", "MeRcyLeZZ")

	// Events
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");

	RegisterHam(Ham_Think, "info_target", "HamF_Think");
	register_think(FIRE2_CLASSNAME, "fw_Fire2Think")
	register_think(FLAME_FAKE_CLASSNAME, "FlameFakeThink")
	register_touch(MOLOTOV_CLASSNAME, "*", "fw_Touch_Molotov")
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink" , 1)
	
	cvar_debug = register_cvar("zp_bot_skill_debug", "0")
	cvar_optimize = register_cvar("zp_optimize", "0")
	
	// Client Cmd
	register_clcmd("drop", "cmd_SPIT")
}

// Zombie Classes MUST be registered on plugin_precache
public plugin_precache()
{
	for(new i = 0; i < sizeof DeathSound; i++)
		precache_sound(DeathSound[i]);
	for(new i = 0; i < sizeof HurtSound; i++)
		precache_sound(HurtSound[i]);
				
	for(new i = 0; i < sizeof(WeaponResources); i++)
	{
		precache_model(WeaponResources[i])
	}
	
	spr_trail = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr")
	precache_model(spit_model)
	precache_sound(Spitter_spitlaunch)
	precache_sound(Spitter_spithit)
	precache_sound(Spitter_dieacid_start)
	g_ExpSprId = precache_model(WeaponResources[0])
	engfunc(EngFunc_PrecacheModel, death_exp_effect_model2) 
	
	// Register all classes
	g_zclass = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback) 
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
		if (task_exists(id+TASK_WAIT_SPIT)) remove_task(id+TASK_WAIT_SPIT)
	}
}
public Death()
{
	new victim = read_data(2) 

	reset_value_player(victim)
	if(zp_get_user_zombie(victim) && zp_get_user_zombie_class(victim)==g_zclass && !zp_get_user_nemesis(victim))
	{
		Create_Molotov(victim, true)
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
	if (task_exists(id+TASK_WAIT_SPIT)) remove_task(id+TASK_WAIT_SPIT)
}
public client_disconnect(id)
{
	reset_value_player(id)
	if (task_exists(id+TASK_WAIT_SPIT)) remove_task(id+TASK_WAIT_SPIT)
}
reset_value_player(id)
{
	g_SPIT_wait[id] = 0
}

public fw_PlayerPostThink(id)
{
	if(!is_user_alive(id) || !is_user_bot(id))
		return PLUGIN_HANDLED
	
	new enemy, body
	get_user_aiming(id, enemy, body)
	if ((1 <= enemy <= 32) && !zp_get_user_zombie(enemy))
	{
		cmd_SPIT(id)
	}
	return PLUGIN_CONTINUE
}

// #################### MAIN PUBLIC ####################
// cmd SPIT
public cmd_SPIT(id)
{
	if (!is_user_alive(id)) return;
	if (is_user_alive(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass && !zp_get_user_nemesis(id) && !g_SPIT_wait[id])
	{
		if (is_user_bot(id)&&get_pcvar_num(cvar_debug))
			return
			
		// set SPIT	
		g_SPIT_wait[id] = 1
		
		md_zb_skill(id, 0)
		set_task(0.5, "Create_Molotov",id)
		emit_sound(id, CHAN_STREAM, Spitter_spitlaunch, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		
		if (task_exists(id+TASK_WAIT_SPIT)) remove_task(id+TASK_WAIT_SPIT)
		set_task(SPIT_TIMEWAIT, "RemoveWaitSPIT", id+TASK_WAIT_SPIT)
		
		//client_print(id, print_center, "Fart!")
	}
}
public Create_Molotov(id, isDead)
{
	static Float:StartOrigin[3], Float:EndOrigin[3], Float:Angles[3]
	
	if(!isDead){
		get_position(id, 48.0, 0.0, 0.0, StartOrigin)
		get_position(id, 1024.0, 0.0, 0.0, EndOrigin)	
	}else{
		pev(id, pev_origin, StartOrigin)
		new Float:tmpOrg[3];tmpOrg = StartOrigin;
		tmpOrg[2] -= 10.0;
		EndOrigin = tmpOrg
	}
	
	pev(id, pev_v_angle, Angles)
	
	Angles[0] *= -1
	
	static Molotov; Molotov = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Molotov)) return
	
	set_pev(Molotov, pev_movetype, MOVETYPE_FLY)
	set_pev(Molotov, pev_iuser1, id) // Better than pev_owner
	set_pev(Molotov, pev_iuser3, 0)
	set_pev(Molotov, pev_iuser4, 0)
	
	entity_set_string(Molotov, EV_SZ_classname, MOLOTOV_CLASSNAME)
	engfunc(EngFunc_SetModel, Molotov, spit_model)
	set_pev(Molotov, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(Molotov, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(Molotov, pev_origin, StartOrigin)
	set_pev(Molotov, pev_angles, Angles)
	set_pev(Molotov, pev_gravity, 1.0)
	set_pev(Molotov, pev_solid, SOLID_BBOX)
	
	set_pev(Molotov, pev_nextthink, get_gametime() + 0.1)
	
	static Float:Velocity[3]
	get_speed_vector(StartOrigin, EndOrigin, 1000.0, Velocity)
	set_pev(Molotov, pev_velocity, Velocity)
	
	// Make a Beam
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(Molotov) // entity
	write_short(spr_trail) // sprite
	write_byte(20)  // life
	write_byte(4)  // width
	write_byte(0) // r
	write_byte(255);  // g
	write_byte(0);  // b
	write_byte(200); // brightness
	message_end();
}
public fw_Touch_Molotov(Ent, Id)
{
	if(!pev_valid(Ent))
		return
	if(pev(Ent, pev_movetype) == MOVETYPE_NONE)
		return
		
	static Float:Origin[3], Attacker; Attacker = pev(Ent, pev_iuser1)
	pev(Ent, pev_origin, Origin)

	static a = FM_NULLENT
	while((a = find_ent_in_sphere(a, Origin, DAMAGE_RADIUS+50.0)) != 0)
	{
		if (Attacker == a)
			continue 
		if(!is_user_alive(a))
			continue	
		if(!zp_get_user_zombie(a))
			continue	
		if(pev(a, pev_takedamage) != DAMAGE_NO)
		{
			//ExecuteHamB(Ham_TakeDamage, a, Attacker, Attacker, is_deadlyshot(Attacker)?random_float(DAMAGE_EXPLOSION-10.0,DAMAGE_EXPLOSION+10.0)*1.5:random_float(DAMAGE_EXPLOSION-10.0,DAMAGE_EXPLOSION+10.0), DMG_BULLET);
		}
	}
	
	// Remove Ent
	set_pev(Ent, pev_movetype, MOVETYPE_NONE)
	set_pev(Ent, pev_solid, SOLID_NOT)
	engfunc(EngFunc_SetModel, Ent, "")
	
	emit_sound(Ent, CHAN_WEAPON, Spitter_spitlaunch, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	Create_GroundFire(Ent)
	set_task(1.5, "Remove_Entity", Ent)
}
public fw_Fire2Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
	
	static Float:fFrame; pev(iEnt, pev_frame, fFrame)
	
	fFrame += 1.0
	if(fFrame >= 16.0) 
		fFrame = 0.0

	new Float:time_1; 
	pev(iEnt, pev_fuser2, time_1)
	
	static Float:Alpha
	pev(iEnt, pev_renderamt, Alpha)
	if(time_1 + random_float(0.2, 0.4) <= get_gametime()) 
	{
		if(Alpha>40){
			if(!get_pcvar_num(cvar_optimize))
				Create_Fake_Flame(iEnt)
		}else{
			set_pev(iEnt, pev_fuser2, get_gametime())
		}
	}else{
		time_1 += 0.03
		set_pev(iEnt, pev_fuser2, time_1)
	}
	set_pev(iEnt, pev_frame, fFrame)
	
	if(get_gametime() >= pev(iEnt, pev_fuser1))
	{
		Alpha-=15.0
		if(Alpha<=0)
		{	
			remove_entity(iEnt)
			return;
		}
		set_pev(iEnt, pev_renderamt, Alpha)
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)
		return;
	}	
	
	static Attacker; Attacker = pev(iEnt, pev_iuser1)
	static Float:Origin[3]
	pev(iEnt, pev_origin, Origin)
	
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)
	
	if(zp_get_user_zombie(Attacker))
	{
		Stock_DamageRadius(Attacker, Origin, DAMAGE_RADIUS, DAMAGE_BURN, DMG_BULLET)
	}
	else remove_entity(iEnt)
}

public Create_Fake_Flame(ent)
{
	new Float:Origin[3];
	pev(ent, pev_origin, Origin)
	
	static Scale,Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Ent)) return
	
	pev(ent, pev_scale, Scale)
	
	// Set info for ent
	set_pev(Ent, pev_movetype, MOVETYPE_NOCLIP)
	set_pev(Ent, pev_solid, SOLID_NOT)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 130.0)
	
	set_pev(Ent, pev_scale, random_float(0.6,0.7))
	set_pev(Ent, pev_owner, ent)
	
	set_pev(Ent, pev_classname, FLAME_FAKE_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, WeaponResources[0])
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
	
	Origin[2] +=1.0
	set_pev(Ent, pev_maxs, Float:{16.0, 16.0, 1.0})
	set_pev(Ent, pev_mins, Float:{-16.0, -16.0, -1.0})
	set_pev(Ent, pev_origin, Origin)
	
	new Vel[3]
	Vel[0] += random_float(-35.0, 35.0)
	Vel[1] += random_float(-35.0, 35.0)
	Vel[2] += random_float(20.0, 25.0)
	set_pev(Ent, pev_velocity, Vel)
}
public FlameFakeThink(iEnt)
{
	if(!pev_valid(iEnt)) 
		return;
	
	if(pev(iEnt, pev_flags) & FL_KILLME) 
		return;
		
	new Owner = pev(iEnt, pev_owner);
	
	static Float:fFrame, Float:Alpha, Float:Scale; 
	pev(iEnt, pev_frame, fFrame)	
	pev(iEnt, pev_scale, Scale)	
	pev(iEnt, pev_renderamt, Alpha)
	
	fFrame += 1.0
	Scale -= 0.03
	
	if(fFrame >= 16.0 || Alpha<=0.0 || Scale <= 0.0) 
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
		
	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_scale, Scale)
	if(pev_valid(Owner))
	{		
		if(pev(Owner, pev_renderamt)<=25.0)
			Alpha -= 10.0
		else Alpha -= 0.5
		set_pev(iEnt, pev_renderamt, Alpha)
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)
	}
	else set_pev(iEnt, pev_nextthink, get_gametime() + 0.07)
}
public Create_GroundFire(Ent)
{
	static Float:Origin[3]; pev(Ent, pev_origin, Origin)
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_ExpSprId)	// sprite index
	write_byte(10)	// scale in 0.1's
	write_byte(10)	// framerate
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOPARTICLES)	// flags
	message_end()
	
	static Float:Ori[3],Float:FireOrigin[9][3]
	pev(Ent, pev_origin, Ori)
	get_spherical_coord(Ori, random_float(60.0, 80.0), 0.0, -10.0, FireOrigin[0])
	get_spherical_coord(Ori, random_float(60.0, 80.0), 90.0, -10.0, FireOrigin[1])
	get_spherical_coord(Ori, random_float(60.0, 80.0), 180.0, -10.0, FireOrigin[2])
	get_spherical_coord(Ori, random_float(60.0, 80.0), 270.0, -10.0, FireOrigin[3])
	
	get_spherical_coord(Ori, random_float(60.0, 80.0), 315.0, -10.0, FireOrigin[4])
	get_spherical_coord(Ori, random_float(60.0, 80.0), 45.0, -10.0, FireOrigin[5])
	get_spherical_coord(Ori, random_float(60.0, 80.0), 135.0, -10.0, FireOrigin[6])
	get_spherical_coord(Ori, random_float(60.0, 80.0), 225.0, -10.0, FireOrigin[7])
	get_spherical_coord(Ori, 0.0, 0.0, 0.0, FireOrigin[8])
	new iEnt;
	for(new i = 0; i < 9; i++)
	{	
		FireOrigin[i][2] += 20.0	
		Create_SmallFire(FireOrigin[i], Ent)
		
		new Float:fCurTime;
		global_get(glb_time, fCurTime);
		
		iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));	
		set_pev(iEnt, pev_classname, "spit_exp");
		set_pev(iEnt, pev_solid, SOLID_NOT);
		set_pev(iEnt, pev_movetype, MOVETYPE_TOSS);
		set_pev(iEnt, pev_sequence, 0);	
		set_pev(iEnt, pev_framerate, 0.1);
		set_pev(iEnt, pev_body,1);
		engfunc(EngFunc_SetModel, iEnt,death_exp_effect_model2);
		FireOrigin[i][2] += 10.0
		set_pev(iEnt, pev_origin, FireOrigin[i]);
		engfunc(EngFunc_DropToFloor, iEnt);
		set_pev(iEnt, pev_nextthink, fCurTime + 5.0);
	}
	make_sound(iEnt)
}
public make_sound(ent){
	if (!pev_valid(ent)) return;
	emit_sound(ent, CHAN_WEAPON, Spitter_dieacid_start, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)	
	set_task(0.2, "make_sound", ent)
}
public HamF_Think(iEnt)
{
	if (!pev_valid(iEnt)) return HAM_IGNORED;
	
	new classname[32];
	pev(iEnt, pev_classname, classname, charsmax(classname));
	if(!equal(classname, "spit_exp")) return HAM_IGNORED;
	
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)
	
	set_pev(iEnt, pev_effects, EF_NODRAW);
	set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
	return HAM_IGNORED;
}
public Create_SmallFire(Float:Origin[3], Master)
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Ent)) return

	// Set info for ent
	set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 180.0)
	set_pev(Ent, pev_scale, random_float(0.6,0.7))
	set_pev(Ent, pev_nextthink, get_gametime() + 0.05)
	
	set_pev(Ent, pev_classname, FIRE2_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, WeaponResources[0])
	set_pev(Ent, pev_fuser2, get_gametime())
	
	set_pev(Ent, pev_maxs, Float:{16.0, 16.0, 115.0})
	set_pev(Ent, pev_mins, Float:{-16.0, -16.0, -25.0})
	
	set_pev(Ent, pev_origin, Origin)
	
	set_pev(Ent, pev_gravity, 1.0)
	set_pev(Ent, pev_solid, SOLID_NOT)
	set_pev(Ent, pev_frame, 0.0)
	set_pev(Ent, pev_iuser1, pev(Master, pev_iuser1))
	set_pev(Ent, pev_fuser1, get_gametime() + 4.0)
}
public RemoveWaitSPIT(taskid)
{
	new id = ID_WAIT_SPIT
	g_SPIT_wait[id] = 0
	client_print(id, print_center,"Cool down finish! [G]")
	if (task_exists(taskid)) remove_task(taskid)
}
public Remove_Entity(Ent)
{
	if(pev_valid(Ent)) remove_entity(Ent)
}
stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	static Float:num; num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}

new Float:Damage[33]
stock Stock_DamageRadius(iPlayer, Float:vOrigin[3], Float:fRadius, Float:fDamage, iDamageType = DMG_BULLET)
{
	new iVictim = FM_NULLENT
	while((iVictim = find_ent_in_sphere(iVictim, vOrigin, fRadius)) != 0) 
	{
		if(iVictim == iPlayer) continue
		if(pev(iVictim, pev_takedamage) == DAMAGE_NO) continue
		if(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY) continue
		if(!is_user_alive(iVictim))continue
		if(zp_get_user_zombie(iVictim)){
			set_pev(iVictim, pev_health, pev(iVictim, pev_health) + 10.0)
			continue
		} 
		
		//ExecuteHamB(Ham_TakeDamage, iVictim, iEnt, iPlayer, fDamage, iDamageType)
		
		new Float:multi
		if(is_user_bot(iPlayer))
			multi=get_cvar_float("zp_human_damage_reward")*2
		else multi = get_cvar_float("zp_human_damage_reward")
		
		static health
		health = pev(iVictim, pev_health)
		
		if (health - floatround(fDamage, floatround_ceil) > 0)
		{	
			fm_set_user_health(iVictim, health - floatround(fDamage, floatround_ceil))
			ExecuteHam(Ham_TakeDamage, iVictim, iPlayer, iPlayer, 0.0, iDamageType)
			Damage[iPlayer]+=fDamage
			
		}
		else ExecuteHam(Ham_TakeDamage, iVictim, iPlayer, iPlayer, 10.0, iDamageType)
		
		if(Damage[iPlayer]>= 20.0)
		{
			zp_set_user_ammo_packs(iPlayer, zp_get_user_ammo_packs(iPlayer) + floatround(Damage[iPlayer] * multi))
			Damage[iPlayer]=0.0
		}
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Money"), _, iPlayer);
		write_long(zp_get_user_ammo_packs(iPlayer));
		write_byte(1);
		message_end();
	}
}
stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	new Float:length
	length  = redius * floatcos(vertical_angle, degrees)
	origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees)
	origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees)
	origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees)
}
