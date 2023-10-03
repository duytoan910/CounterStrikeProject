#define PLUGIN "BTE Heavy Zombie"
#define VERSION "1.0"
#define AUTHOR "BTE TEAM"

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <fun>
#include <toan> 

#define	m_pActiveItem	373
#define	m_iId			43

#define CANNOT			0
#define CANUSE			1

// Zombie Attributes
new const zclass1_name[] = "Heavy"
new const zclass1_info[] = ""
new const zclass1_model[] = {"heavy_zombi_host","heavy_zombi_origin"} // model
new const zclass1_clawmodel[] = "v_knife_heavy_zombi.mdl" // claw model
const zclass1_health = 3700 // health
const zclass1_speed = 280 // speed
const Float:zclass1_gravity = 0.8 // gravity
const Float:zclass1_knockback =  1.12 // knockback

new g_iCurrentWeapon[33]
new const zclass1_bombmodel[] = { "models/zombie_plague/v_zombibomb_heavy_zombi.mdl" }

new g_sound[][] = 
{
	"zombie_plague/zombi_death_heavy_1.wav" ,
	"zombie_plague/zombi_death_heavy_2.wav" ,
	"zombie_plague/zombi_hurt_heavy_1.wav" ,
	"zombie_plague/zombi_hurt_heavy_2.wav"
};
static const szTrapModel[] = "models/zombie_plague/zombitrap.mdl"
new const szSoundTrap[] = "zombie_plague/zombi_trapped.wav"
new const szSoundTrapSet[] = "zombie_plague/zombi_trapsetup.wav"
const Float:fCoolDownTime = 15.0 // time of wait
new Float:fTrapTime = 5.0
new Float:fTrapDeath = 30.0
new maxplayers

new g_msgScreenShake;
new bool:cooldown_started[33]
new iClass;
new Float:fMins[3], Float:fMaxs[3];
new iSkillStat[33], Float:fNextCanUse[33], iTrapTotal[33];
new isTraped[33],cvar_debug
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_event("HLTV","Event_HLTV","a","1=0","2=0")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");
	register_forward(FM_ClientCommand, "fw_ClientCommand");
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink", 1)
	register_event("ResetHUD","NewRound","be")	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	register_event("DeathMsg", "Death", "a");
	
	RegisterHam(Ham_Touch, "info_target", "HamF_Touch");
	RegisterHam(Ham_Think, "info_target", "HamF_Think");

	g_msgScreenShake = get_user_msgid("ScreenShake");
	maxplayers = get_maxplayers()
	cvar_debug = register_cvar("zp_bot_skill_debug", "0")
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
public plugin_precache()
{	
	iClass = zp_register_zombie_class(zclass1_name, zclass1_info, zclass1_model, zclass1_clawmodel, zclass1_health, zclass1_speed, zclass1_gravity, zclass1_knockback)
	precache_model(szTrapModel)
	engfunc(EngFunc_PrecacheSound, szSoundTrap);
	engfunc(EngFunc_PrecacheSound, szSoundTrapSet)	
	for(new i = 0; i < sizeof g_sound; i++)
		precache_sound(g_sound[i]);
		
	precache_model(zclass1_bombmodel)
}

public fw_PlayerPostThink(id)
{
	if(pev(id, pev_deadflag) != DEAD_NO)
		return FMRES_IGNORED;
	
	if(isTraped[id] && zp_get_user_zombie(id) != 1)
	{
		client_print(id, print_center, "Trapped!");
		set_pev(id, pev_maxspeed, 1.0);
		set_pev(id, pev_velocity, {0.0, 0.0, -200.0});
	}
	
	// BOT USE SKILL
	if(zp_get_user_zombie(id) != 1)
		return FMRES_IGNORED;
	if (cooldown_started[id])
		return PLUGIN_CONTINUE
		
	if(zp_get_user_zombie_class(id) != iClass)
		return FMRES_IGNORED;
		
	new Float:fCurTime;
	global_get(glb_time, fCurTime);
	
	if(!is_user_bot(id))
		return FMRES_IGNORED;

	if(fNextCanUse[id] <= fCurTime && iSkillStat[id] == CANUSE)
		UseSkill(id);
	
	
	return FMRES_IGNORED;
}


public fw_ClientCommand(id)
{
	static szCommand[24];
	read_argv(0, szCommand, charsmax(szCommand));

	if(pev(id, pev_deadflag) != DEAD_NO)
		return FMRES_IGNORED;

	if(iClass != zp_get_user_zombie_class(id) || zp_get_user_nemesis(id) || zp_get_user_assassin(id) || zp_get_user_zombie(id) != 1)
		return FMRES_IGNORED;
	
	if(!strcmp(szCommand, "drop"))
	{
		new Float:fCurTime;
		global_get(glb_time, fCurTime);

		if (cooldown_started[id])
			return PLUGIN_CONTINUE
		UseSkill(id);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id) || !zp_get_user_zombie(id))
		return PLUGIN_CONTINUE
		
	g_iCurrentWeapon[id] = read_data(2)
	if(g_iCurrentWeapon[id] == CSW_SMOKEGRENADE && zp_get_user_zombie_class(id) == iClass)
	{
		set_pev(id, pev_viewmodel2, zclass1_bombmodel)
	}

	if(get_user_weapon(id) == CSW_KNIFE) iSkillStat[id] = CANUSE;
	else iSkillStat[id] = CANNOT;
	return PLUGIN_CONTINUE
}

public Event_HLTV()
{
	for(new i=1; i<33 ;i++)
	{
		iTrapTotal[i] = 0;
		isTraped[i] = 0;
	}

	new ent = -1
	while((ent = engfunc( EngFunc_FindEntityByString, ent, "classname", "zombie_trap"))) engfunc( EngFunc_RemoveEntity, ent );
}
public UseSkill(id)
{	
	if (is_user_bot(id)&&get_pcvar_num(cvar_debug))
		return
		
	md_zb_skill(id, 0)
		
	new Float:fCurTime;
	global_get(glb_time, fCurTime);
	
	fNextCanUse[id] = fCoolDownTime + fCurTime;
	
	new Float:vOrigin[3];
	pev(id, pev_origin, vOrigin);

	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (!iEnt) return;

	set_pev(iEnt, pev_classname, "zombie_trap");
	set_pev(iEnt, pev_solid, SOLID_TRIGGER);
	set_pev(iEnt, pev_movetype, MOVETYPE_TOSS);
	set_pev(iEnt, pev_owner, id);
	set_pev(iEnt, pev_sequence, 0);
	set_pev(iEnt, pev_framerate, 1.0);
	set_pev(iEnt, pev_iuser2, 998);
	set_pev(iEnt, pev_iuser3, 0);
	set_pev(iEnt, pev_iuser4, 0);

	set_pev(iEnt, pev_nextthink, fCurTime + fTrapDeath);

	engfunc(EngFunc_SetSize, iEnt, fMins, fMaxs);
	engfunc(EngFunc_SetModel, iEnt, szTrapModel);
	set_pev(iEnt, pev_origin, vOrigin);

	engfunc(EngFunc_EmitSound, id, CHAN_AUTO, szSoundTrapSet, 1.0, ATTN_NORM, 0, PITCH_NORM);
	cooldown_started[id] = true
	set_task(fCoolDownTime, "cooldown_finish", id)
}

public cooldown_finish(id)
{
	if (cooldown_started[id]) 
	client_print(id, print_center,"Trap cool down finish! [G]")
	cooldown_started[id] = false
}
public HamF_Touch(iPtr,iPtd)
{
	if (!pev_valid(iPtr) || !pev_valid(iPtd)) return HAM_IGNORED;

	new classname[32];
	pev(iPtr, pev_classname, classname, charsmax(classname));
	if(!equal(classname, "zombie_trap")) return HAM_IGNORED;
	if(iPtd > 32 || iPtd < 1) return HAM_IGNORED;
	if(zp_get_user_zombie(iPtd) == 1) return HAM_IGNORED;
	if(pev(iPtr, pev_iuser4)) return HAM_IGNORED;

	new Float:fCurTime;
	global_get(glb_time, fCurTime);
	set_pev(iPtr, pev_nextthink, fCurTime + fTrapTime);
	if(pev(iPtr, pev_sequence) != 1)
	{
		set_pev(iPtr, pev_animtime, fCurTime);
		set_pev(iPtr, pev_sequence, 1);
	}
	set_pev(iPtr, pev_iuser3, iPtd);
	set_pev(iPtr, pev_iuser4, 1);
	isTraped[iPtd] = 1;
	ScreenShake(iPtd);
	
	new Float:vVel[3];
	pev(iPtd, pev_velocity, vVel);
	vVel[0] = vVel[1] = 0.0;
	set_pev(iPtd, pev_velocity, vVel);
	engfunc(EngFunc_EmitSound, iPtd, CHAN_AUTO, szSoundTrap, 1.0, ATTN_NORM, 0, PITCH_NORM);

	return HAM_IGNORED;
}

public HamF_Think(iEnt)
{
	if (!pev_valid(iEnt)) return HAM_IGNORED;

	new classname[32];
	pev(iEnt, pev_classname, classname, charsmax(classname));
	if(!equal(classname, "zombie_trap")) return HAM_IGNORED;
	
	new id = pev(iEnt, pev_iuser3);
	isTraped[id] = 0;

	set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
	return HAM_IGNORED;
}

public zp_user_infected_post(id,inf)
{
	isTraped[id] = 0;
	if(iClass==zp_get_user_zombie_class(id))
	{
		fNextCanUse[id] = 0.0;
	}
	
}
public NewRound(id)
{
	cooldown_started[id] = false
}

public Death()
{
	new player = read_data(2)
	if ((player <= 0) || (player > maxplayers))
		return;
	
	cooldown_started[player] = false
	
	if(zp_get_user_zombie(player) && zp_get_user_zombie_class(player)==iClass && !zp_get_user_nemesis(player) && !zp_get_user_assassin(player))
	{
		engfunc( EngFunc_EmitSound, player, CHAN_ITEM, g_sound[random_num(0,1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

public fw_TakeDamage(id, iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamage)
{
	if (zp_get_user_zombie_class(id)==iClass && zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && !zp_get_user_assassin(id))
	{
		emit_sound(id, CHAN_WEAPON, g_sound[random_num(2,3)], 1.0, ATTN_NORM, 0, PITCH_LOW)
	}
} 
ScreenShake(id, amplitude = 8, duration = 6, frequency = 18)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short((1<<12)*amplitude) 
	write_short((1<<12)*duration) 
	write_short((1<<12)*frequency) 
	message_end()
}
