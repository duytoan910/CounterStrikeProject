#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <zombieplague>
#include <xs>
#include <toan> 

#define PLUGIN "DJB Zombie Class Banchee"
#define VERSION "1.0.3"
#define AUTHOR "Csoldjb&wbyokomo"

// Zombie Attributes 
new const zclass_name[] = "Banshee" // name 
new const zclass_info[] = " " // description 
new const zclass_model[] ={ "witch_zombi_host", "witch_zombi_origin"} // model 
new const zclass_clawmodel[] = "v_knife_witch_zombi.mdl" // claw model 
const zclass_health = 3200 // health 
const zclass_speed = 285 // speed 
const Float:zclass_gravity = 0.69 // gravity 
const Float:zclass_knockback = 1.25 // knockback 
new g_iCurrentWeapon[33]
new const zclass1_bombmodel[] = { "models/zombie_plague/v_zombibomb_witch_zombi.mdl" }
new const SOUND_BAT_HIT[] = "zombie_plague/zombi_banshee_laugh.wav"
new const SOUND_BAT_MISS[] = "zombie_plague/zombi_banshee_pulling_fail.wav"

new const MODEL_BAT[] = "models/zombie_plague/bat_witch.mdl"
new const BAT_CLASSNAME[] = "banchee_bat"

new g_sound[2][] = 
{
	"zombie_plague/zombi_death_banshee_1.wav",
	"zombie_plague/zombi_hurt_banshee_1.wav"
};

new spr_skull

const Float:banchee_skull_bat_speed = 1500.0
const Float:banchee_skull_bat_flytime = 5.0
const Float:banchee_skull_bat_catch_time = 5.0
const Float:banchee_skull_bat_catch_speed = 1000.0
const Float:bat_timewait = 12.0

new g_bat_time[33]
new g_bat_stat[33]
new g_bat_enemy[33]
new batting[33]
new kelelawar[33]

new classbanchee
new g_maxplayers
new g_msgScreenFade
new g_bot, cvar_debug
enum (+= 100)
{
	TASK_REMOVE_STAT,
	TASK_CONFUSION,
	TASK_SOUND
}

#define ID_TASK_REMOVE_STAT (taskid - TASK_REMOVE_STAT)
#define ID_CONFUSION (taskid - TASK_CONFUSION)
#define ID_SOUND (taskid - TASK_SOUND)

const UNIT_SECOND = (1<<12)
const FFADE_IN = 0x0000

public plugin_precache()
{
	precache_sound(SOUND_BAT_HIT)
	precache_sound(SOUND_BAT_MISS)
	precache_model(MODEL_BAT)
	precache_model(zclass1_bombmodel)
	for(new i = 0; i < sizeof g_sound; i++)
	{
		precache_sound(g_sound[i]);
	}	
	classbanchee = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)      
	
	spr_skull = precache_model("sprites/ef_bat.spr")
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "EventHLTV", "a", "1=0", "2=0")
	register_event("DeathMsg", "EventDeath", "a")
	register_event("CurWeapon", "EV_CurWeapon", "be", "1=1")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	
	register_clcmd("drop", "cmd_bat")
	register_forward(FM_PlayerPreThink,"fw_PlayerPreThink")

	RegisterHam(Ham_Touch,"info_target","EntityTouchPost")
 
	g_maxplayers = get_maxplayers()
	g_msgScreenFade = get_user_msgid("ScreenFade")
	cvar_debug = register_cvar("zp_bot_skill_debug", "0")
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
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
}
public EV_CurWeapon(id)
{
	if(!is_user_alive(id) || !zp_get_user_zombie(id))
		return PLUGIN_CONTINUE
		
	g_iCurrentWeapon[id] = read_data(2)
	if(g_iCurrentWeapon[id] == CSW_SMOKEGRENADE && zp_get_user_zombie_class(id) == classbanchee)
	{
		set_pev(id, pev_viewmodel2, zclass1_bombmodel)
	}
	return PLUGIN_CONTINUE
}
public EventHLTV()
{
	for(new id = 1; id <= g_maxplayers; id++)
	{
		if (!is_user_connected(id)) continue;
		
		banchee_reset_value_player(id)
	}
}
public EventDeath()
{
	new id = read_data(2)
	
	banchee_reset_value_player(id)
	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id)==classbanchee && !zp_get_user_nemesis(id) && !zp_get_user_assassin(id))
	{
		engfunc( EngFunc_EmitSound, id, CHAN_ITEM, g_sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}
public zp_user_humanized_post(id)
{
	banchee_reset_value_player(id)
}

public bat_anim_start(id)
{
	set_pev(id, pev_framerate, 0.5)
	PlayWeaponAnimation(id, 2)
}
public fw_TakeDamage(id, iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamage)
{
	if (zp_get_user_zombie_class(id)==classbanchee && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && !zp_get_user_assassin(id))
	{
		emit_sound(id, CHAN_WEAPON, g_sound[1], 1.0, ATTN_NORM, 0, PITCH_LOW)
	}
}
public cmd_bat(id)
{
	if(is_user_alive(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id)  && !zp_get_user_assassin(id) && zp_get_user_zombie_class(id)==classbanchee && !g_bat_time[id] && get_user_weapon(id) == CSW_KNIFE)
	{
		if (is_user_bot(id)&&get_pcvar_num(cvar_debug))
			return	
		
		g_bat_time[id] = 1
		batting[id] = 1
		kelelawar[id] = 1
		bat_anim_start(id)
		set_task(bat_timewait,"clear_stat",id+TASK_REMOVE_STAT)		
		
		new ent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
		
		Player_SetAnimation(id, "skill1_loop")
		md_zb_skill(id, 0)
		
		if(!pev_valid(ent)) return;
		
		new Float:vecAngle[3],Float:vecOrigin[3],Float:vecVelocity[3],Float:vecForward[3]
		//fm_get_user_startpos(id,0.0,0.0,0.0,vecOrigin)
		fm_get_user_startpos(id,50.0,0.0,0.0,vecOrigin)
		pev(id,pev_angles,vecAngle)
		
		engfunc(EngFunc_MakeVectors,vecAngle)
		global_get(glb_v_forward,vecForward)
		
		velocity_by_aim(id,floatround(banchee_skull_bat_speed),vecVelocity)
		
		set_pev(ent,pev_origin,vecOrigin)
		set_pev(ent,pev_angles,vecAngle)
		set_pev(ent,pev_classname,BAT_CLASSNAME)
		set_pev(ent,pev_movetype,MOVETYPE_FLY)
		set_pev(ent,pev_solid,SOLID_BBOX)
		engfunc(EngFunc_SetSize,ent,{-40.0,-25.0,-8.0},{40.0,25.0,8.0})
		
		set_pev(ent, pev_gravity, 0.01)
		
		engfunc(EngFunc_SetModel,ent,MODEL_BAT)
		set_pev(ent,pev_animtime,get_gametime())
		set_pev(ent,pev_framerate,1.0)
		set_pev(ent,pev_owner,id)
		set_pev(ent,pev_velocity,vecVelocity)
		//set_pev(ent,pev_nextthink,get_gametime()+banchee_skull_bat_flytime)
		set_pev(ent,pev_nextthink,get_gametime()+0.1)
	}
}

public fw_PlayerPreThink(id)
{
	if(!is_user_alive(id)) return FMRES_IGNORED
	
	if(g_bat_stat[id]&&!zp_get_user_zombie(id))
	{
		new owner = g_bat_enemy[id], Float:ownerorigin[3]
		pev(owner,pev_origin,ownerorigin)
		
		static Float:vec[3]
		
		aim_at_origin(id,ownerorigin,vec)
		engfunc(EngFunc_MakeVectors, vec)
		global_get(glb_v_forward, vec)
		vec[0] *= banchee_skull_bat_catch_speed
		vec[1] *= banchee_skull_bat_catch_speed
		vec[2] *= banchee_skull_bat_catch_speed
		set_pev(id,pev_velocity,vec)
	}
	
	if(is_user_bot(id))
	{	
		new enemy, body
		get_user_aiming(id, enemy, body)
		if (pev_valid(enemy) && is_user_alive(enemy) && !zp_get_user_zombie(enemy))
		{
			set_task(0.5 , "cmd_bat", id)
		}
	}
	return FMRES_IGNORED
}
	
public EntityTouchPost(ent,ptd)
{
	if(!pev_valid(ent)) return HAM_IGNORED
	
	new classname[32]
	pev(ent,pev_classname,classname,31)
	
	if(equal(classname,BAT_CLASSNAME))
	{
		if(!pev_valid(ptd))
		{
			static Float:origin[3];
			pev(ent,pev_origin,origin);
			
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION)
			write_coord(floatround(origin[0]))
			write_coord(floatround(origin[1]))
			write_coord(floatround(origin[2]))
			write_short(spr_skull)
			write_byte(40)
			write_byte(30)
			write_byte(14)
			message_end()
			
			emit_sound(ent, CHAN_WEAPON, SOUND_BAT_MISS, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			engfunc(EngFunc_RemoveEntity,ent)
			
			return HAM_IGNORED
		}
		new owner = pev(ent,pev_owner)
		
		if(0 < ptd && ptd <= g_maxplayers && is_user_alive(ptd)&& ptd != owner && kelelawar[owner])
		{
			g_bat_enemy[ptd] = owner
			
			message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, ptd)
			write_short(UNIT_SECOND)
			write_short(0)
			write_short(FFADE_IN)
			write_byte(150)
			write_byte(150)
			write_byte(150)
			write_byte(150)
			message_end()
			
			emit_sound(owner, CHAN_WEAPON, SOUND_BAT_HIT, 1.0, ATTN_NORM, 0, PITCH_NORM)
			//emit_sound(ent, CHAN_WEAPON, SOUND_BAT_MISS, 1.0, ATTN_NORM, 0, PITCH_NORM)
			set_pev(ent,pev_nextthink,get_gametime()+ 0.3)
			set_task(banchee_skull_bat_catch_time,"clear_stat2",ptd+TASK_REMOVE_STAT)
			set_task(banchee_skull_bat_catch_time,"rmv_bat",ent)
			set_pev(ent,pev_movetype,MOVETYPE_FOLLOW)
			set_pev(ent,pev_aiment,ptd)
			g_bat_stat[ptd] = 1
		}
		else
		{
			static Float:origin[3];
			pev(ent,pev_origin,origin);
			
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION)
			write_coord(floatround(origin[0]))
			write_coord(floatround(origin[1]))
			write_coord(floatround(origin[2]))
			write_short(spr_skull)
			write_byte(40)
			write_byte(30)
			write_byte(14)
			message_end()
			
			emit_sound(ent, CHAN_WEAPON, SOUND_BAT_MISS, 1.0, ATTN_NORM, 0, PITCH_NORM)
			engfunc(EngFunc_RemoveEntity,ent)
			
			return HAM_IGNORED
		}
	}
	return HAM_IGNORED
}
public rmv_bat(ent)
{
	if(!pev_valid(ent)) return 
	new owner = pev(ent,pev_owner)
	Player_SetAnimation(owner, "idle1")
	engfunc(EngFunc_RemoveEntity,ent)
}
public clear_stat(taskid)
{
	new id = ID_TASK_REMOVE_STAT

	g_bat_time[id] = 0
	
	client_print(id, print_center,"Spawn bat cool down finish! [G]")
}
public clear_stat2(idx)
{
	new id = idx-TASK_REMOVE_STAT
	
	kelelawar[id] = 0
	g_bat_enemy[id] = 0
	g_bat_stat[id] = 0
}

fm_get_user_startpos(id,Float:forw,Float:right,Float:up,Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	engfunc(EngFunc_MakeVectors, vAngle)
	
	global_get(glb_v_forward, vForward)
	global_get(glb_v_right, vRight)
	global_get(glb_v_up, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

aim_at_origin(id, Float:target[3], Float:angles[3])
{
	static Float:vec[3]
	pev(id,pev_origin,vec)
	vec[0] = target[0] - vec[0]
	vec[1] = target[1] - vec[1]
	vec[2] = target[2] - vec[2]
	engfunc(EngFunc_VecToAngles,vec,angles)
	angles[0] *= -1.0
	angles[2] = 0.0
}

PlayWeaponAnimation(id, animation)
{
	set_pev(id, pev_weaponanim, animation)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(animation)
	write_byte(pev(id, pev_body))
	message_end()
}


banchee_reset_value_player(id)
{
	g_bat_time[id] = 0
	g_bat_stat[id] = 0
	g_bat_enemy[id] = 0
	kelelawar[id] = 0

	remove_task(id)
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
