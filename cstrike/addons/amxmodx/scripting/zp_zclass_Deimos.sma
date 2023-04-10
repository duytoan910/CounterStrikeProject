#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <xs>
#include <engine>
#include <toan> 

#define PLUGIN "BTE Deimos Zombie"
#define VERSION "1.0"
#define AUTHOR "BTE TEAM"

const m_iTeam = 114
const m_rgpPlayerItems = 367
const m_pNext = 42

new idclass
/*
new zombie_name[64], zombie_model[64], zombie_sex, zombie_modelindex, Float:zombie_gravity, Float:zombie_speed, Float:zombie_knockback, zombie_sound_evolution[64], Float:zombie_xdamage[3] ,
zombie_sound_death1[64], zombie_sound_death2[64], zombie_sound_hurt1[64], zombie_sound_hurt2[64], zombie_sound_heal[64],
v_model_host[64], v_zombibomb_host[64]
*/
new g_wait[33], g_useskill[33]

new Float:skill_use_time_next[33]
const Float:skill_time_wait = 12.0

new g_msgScreenShake,gtrail,gexp
new const light_classname[] = "zp_skill"

const WPN_NOT_DROP = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))
enum (+= 100)
{
	TASK_WAIT = 2000,
	TASK_ATTACK,
	TASK_USE_SKILL,
	TASK_USE_ANIM
}
// IDs inside tasks
#define ID_WAIT (taskid - TASK_WAIT)
#define ID_ATTACK (taskid - TASK_ATTACK)
#define ID_USE_SKILL (taskid - TASK_USE_SKILL)
#define ID_USE_ANIM (taskid - TASK_USE_ANIM)

const m_flTimeWeaponIdle = 48
const m_flNextAttack = 83
//new Float:cl_pushangle[33][3]

new cvar_debug
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	
	register_clcmd("drop", "use_skill")
	RegisterHam(Ham_Touch, "info_target", "HamF_InfoTarget_Touch")
	
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink" , 1)
	
	g_msgScreenShake = get_user_msgid("ScreenShake");
	cvar_debug = register_cvar("zp_bot_skill_debug", "0")
}

public HamF_InfoTarget_Touch(ptr,ptd)
{
	if(!pev_valid(ptr)) return
	static iflag
	iflag = pev(ptr,pev_iuser1)
	if(iflag != 123) return
	light_exp(ptr, ptd)
	set_pev(ptr, pev_flags, pev(ptr, pev_flags) | FL_KILLME);
	
}

new const zclass1_name[] = { "Deimos" }
new const zclass1_info[] = { "" }
new const zclass1_model[] = { "deimos_zombi_host", "deimos_zombi_origin" }
new const zclass1_clawmodel[] = { "v_knife_deimos_zombi_host.mdl" }
const zclass1_health = 3200
const zclass1_speed = 290
const Float:zclass1_gravity = 0.8
const Float:zclass1_knockback = 1.45

new const sound_skill_start[] = "zombie_plague/deimos_skill_start.wav" 
new const sound_skill_hit[] = "zombie_plague/deimos_skill_hit.wav" 
new g_sound[][] = 
{
	"zombie_plague/zombi_death_1.wav" ,
	"zombie_plague/zombi_death_2.wav" ,
	"zombie_plague/zombi_hurt_01.wav" ,
	"zombie_plague/zombi_hurt_02.wav"
};

public plugin_precache()
{
	precache_sound(sound_skill_start)
	precache_sound(sound_skill_hit)
	
	for(new i = 0; i < sizeof g_sound; i++)
		precache_sound(g_sound[i]);

	gexp = engfunc(EngFunc_PrecacheModel,"sprites/deimosexp.spr")
	gtrail = engfunc(EngFunc_PrecacheModel,"sprites/deimos_trail.spr")
	
	idclass = zp_register_zombie_class(zclass1_name, zclass1_info, zclass1_model, zclass1_clawmodel, zclass1_health, zclass1_speed, zclass1_gravity, zclass1_knockback)

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
	}
}
public Death()
{
	new id = read_data(2)
	reset_value_player(id)

	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id)==idclass && !zp_get_user_nemesis(id))
	{
		engfunc( EngFunc_EmitSound, id, CHAN_ITEM, g_sound[random_num(0,1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}
public fw_TakeDamage(id, iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamage)
{
	if (zp_get_user_zombie_class(id)==idclass && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
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
	if (task_exists(id+TASK_WAIT)) remove_task(id+TASK_WAIT)
	if (task_exists(id+TASK_WAIT)) remove_task(id+TASK_WAIT)
	if (task_exists(id+TASK_ATTACK)) remove_task(id+TASK_ATTACK)
	if (task_exists(id+TASK_USE_SKILL)) remove_task(id+TASK_USE_SKILL)
	
	g_wait[id] = 0
	g_useskill[id] = 0
}
new g_setAnim[33]
public fw_PlayerPostThink(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
	
	if (zp_get_user_zombie_class(id) == idclass)
	{
		if(is_user_alive(id) && zp_get_user_zombie(id) && (zp_get_user_zombie_class(id) == idclass)){
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

	
	if(is_user_bot(id)){
		new enemy, body
		get_user_aiming(id, enemy, body)
		if ((1 <= enemy <= 32) && !zp_get_user_zombie(enemy))
		{
			use_skill(id)
		}
	}
	return PLUGIN_CONTINUE
}
public unlockAnim(taskid){
	new id = ID_USE_ANIM;
	g_setAnim[id] = false
}
// #################### USE SKILL PUBLIC ####################
public use_skill(id)
{
	if (!is_user_alive(id)) return PLUGIN_CONTINUE
	
		
	if (idclass==zp_get_user_zombie_class(id) && zp_get_user_zombie(id)==1 && (!g_wait[id]) && !zp_get_user_nemesis(id) && get_user_weapon(id)==CSW_KNIFE)
	{
		if (is_user_bot(id)&&get_pcvar_num(cvar_debug))
			return PLUGIN_CONTINUE
			
		g_useskill[id] = 1	
		
		// set time wait
		new Float:timewait = skill_time_wait
		skill_use_time_next[id] = get_gametime() + timewait
		g_wait[id] = 1
		if (task_exists(id+TASK_WAIT)) remove_task(id+TASK_WAIT)
		set_task(timewait, "RemoveWait", id+TASK_WAIT)
		Use_Skill(id)
		
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}
public Use_Skill(id)
{
	play_weapon_anim(id, 2)
	set_weapons_timeidle(id, skill_time_wait)
	set_player_nextattack(id, 0.5)
	PlayEmitSound(id, sound_skill_start)
	Player_SetAnimation(id, "skill")
	md_zb_skill(id, 0)
		
	if (task_exists(id+TASK_ATTACK)) remove_task(id+TASK_ATTACK)
	set_task(0.5, "launch_light", id+TASK_ATTACK)
}
public launch_light(taskid)
{
	new id = ID_ATTACK
	if (task_exists(id+TASK_ATTACK)) remove_task(id+TASK_ATTACK)
	
	if (!is_user_alive(id)) return;
	
	
	// check
	new Float: fOrigin[3], Float:fAngle[3],Float: fVelocity[3]
	Stock_Get_Postion(id,5.0,0.0,0.0,fOrigin)
	//pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, fAngle)
	fm_velocity_by_aim(id, 1.5, fVelocity, fAngle)
	fAngle[0] *= -1.0
	
	// create ent
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(ent, pev_classname, light_classname)
	engfunc(EngFunc_SetModel, ent, "models/w_hegrenade.mdl")
	set_pev(ent, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(ent, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(ent, pev_origin, fOrigin)
	fOrigin[0] += fVelocity[0]
	fOrigin[1] += fVelocity[1]
	fOrigin[2] += fVelocity[2]
	set_pev(ent, pev_movetype, MOVETYPE_BOUNCE)
	set_pev(ent, pev_gravity, 0.01)
	fVelocity[0] *= 1000
	fVelocity[1] *= 1000
	fVelocity[2] *= 1000
	set_pev(ent, pev_velocity, fVelocity)
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_angles, fAngle)
	set_pev(ent, pev_solid, SOLID_BBOX)
	set_pev(ent, pev_iuser1, 123)
	
	// show trail	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_BEAMFOLLOW)
	write_short(ent)				//entity
	write_short(gtrail)		//model
	write_byte(5)		//10)//life
	write_byte(3)		//5)//width
	write_byte(209)					//r, hegrenade
	write_byte(120)					//g, gas-grenade
	write_byte(9)					//b
	write_byte(200)		//brightness
	message_end()					//move PHS/PVS data sending into here (SEND_ALL, SEND_PVS, SEND_PHS)
	
	//client_print(0, print_center, "phong")
	return;
}
light_exp(ent, victim)
{	
	new attacker = pev(ent, pev_owner)
	
	new Float:origin[3];
	pev(ent, pev_origin, origin);	

	if (is_user_alive(victim) && zp_get_user_zombie(victim)!=2 && !zp_get_user_survivor(victim))
	{
		Drop_PlayerWeapon(victim)
		ScreenShake(victim)
		
		/*
		push(a)
		new Float:push[3]
		pev(a,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[a],push)
		
		xs_vec_mul_scalar(push,30.0,push)
		xs_vec_add(push,cl_pushangle[a],push)
		set_pev(a,pev_punchangle,push)
		*/
		
		ExecuteHam(Ham_TakeDamage, victim, attacker, attacker, 80.0, (1<<7));
	}

	// create effect
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION); // TE_EXPLOSION
	write_coord(floatround(origin[0])); // origin x
	write_coord(floatround(origin[1])); // origin y
	write_coord(floatround(origin[2])); // origin z
	write_short(gexp); // sprites
	write_byte(40); // scale in 0.1's
	write_byte(30); // framerate
	write_byte(14); // flags 
	message_end(); // message end
	
	// play sound exp
	PlayEmitSound(ent, sound_skill_hit)
}
public RemoveWait(taskid)
{
	new id = ID_WAIT
	g_wait[id] = 0
	client_print(id, print_center,"Cool down finish! [G]")
	if (task_exists(taskid)) remove_task(taskid)
}
PlayEmitSound(id, const sound[])
{
	emit_sound(id, CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
play_weapon_anim(player, anim)
{
	set_pev(player, pev_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(pev(player, pev_body))
	message_end()
}
fm_velocity_by_aim(iIndex, Float:fDistance, Float:fVelocity[3], Float:fViewAngle[3])
{
	//new Float:fViewAngle[3]
	pev(iIndex, pev_v_angle, fViewAngle)
	fVelocity[0] = floatcos(fViewAngle[1], degrees) * fDistance
	fVelocity[1] = floatsin(fViewAngle[1], degrees) * fDistance
	fVelocity[2] = floatcos(fViewAngle[0]+90.0, degrees) * fDistance
	return 1
}
get_weapon_ent(id, weaponid)
{
	static wname[32], weapon_ent
	get_weaponname(weaponid, wname, charsmax(wname))
	weapon_ent = fm_find_ent_by_owner(-1, wname, id)
	return weapon_ent
}
set_weapons_timeidle(id, Float:timeidle)
{
	new entwpn = get_weapon_ent(id, get_user_weapon(id))
	if (pev_valid(entwpn)) set_pdata_float(entwpn, m_flTimeWeaponIdle, timeidle+3.0, 4)
}
set_player_nextattack(id, Float:nexttime)
{
	set_pdata_float(id, m_flNextAttack, nexttime, 4)
}


// ################### STOCK ###################
// Set player's health (from fakemeta_util)
stock fm_set_user_health(id, health)
{
	(health > 0) ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id);
}
// Set entity's rendering type (from fakemeta_util)
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}
// Find entity by its owner (from fakemeta_util)
stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) { /* keep looping */ }
	return entity;
}
stock Stock_Get_Postion(id,Float:forw,Float:right,Float:up,Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp)
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward)
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

const WPN_NOT_DROP = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))
public Drop_PlayerWeapon(id)
{
	static wpn, wpnname[32]
	
	if(!id)
	{
		for(new i = 0; i < get_maxplayers(); i++)
		{
			if(!is_user_alive(i)) continue
			
			wpn = get_user_weapon(i)
			if(!(WPN_NOT_DROP & (1<<wpn)) && get_weaponname(wpn, wpnname, charsmax(wpnname)))
				engclient_cmd(i, "drop", wpnname)
		}
	} else {
		if(!is_user_alive(id)) return
		
		wpn = get_user_weapon(id)
		if(!(WPN_NOT_DROP & (1<<wpn)) && get_weaponname(wpn, wpnname, charsmax(wpnname)))
			engclient_cmd(id, "drop", wpnname)
	}
}
stock ScreenShake(id, amplitude = 18, duration = 5, frequency = 28)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short((1<<12)*amplitude) 
	write_short((1<<12)*duration) 
	write_short((1<<12)*frequency) 
	message_end()
}
public push(id)
{
	static Float:vektor[3]
	vektor[0] = random_float(-3.0,3.0)
	vektor[1] = random_float(-3.0,3.0)
	vektor[2] = random_float(-3.0,3.0) 
	
	set_pev(id, pev_punchangle, vektor)        
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

stock IsCurrentSpeedHigherThan(id, Float:fValue)
{
    new Float:fVecVelocity[3]
    entity_get_vector(id, EV_VEC_velocity, fVecVelocity)
    
    if(vector_length(fVecVelocity) > fValue)
        return true
    
    return false
} 