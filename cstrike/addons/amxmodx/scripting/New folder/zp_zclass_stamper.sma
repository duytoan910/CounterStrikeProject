#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich> 
#include <zombieplague> 
#include <xs> 

#define PLUGIN "Undertaker"
#define VERSION "1.0"
#define AUTHOR "DSHGFHDS"

#define SKILLMODEL "models/zombiepile.mdl"
#define SKILLNAME "zombiecoffin"
#define SKILL_COFFIN 15214
#define TASK_COOLDAWN 1234
#define TASK_SKILLUSEING 2345
#define TASK_SKILLOVER 3456
#define TASK_ENTTHINK 4567
#define TASK_SPEEDTIME 5678
#define DMG_EXPLOSION (1<<24)


new const WEAPON_CLASSNAME[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
	"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
	"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
	"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
"weapon_ak47", "weapon_knife", "weapon_p90" }

new const zclass_name[] = { "Undertaker" }
new const zclass_info[] = { " " }
new const zclass_model[] = { "stamper_zombi_host", "stamper_zombi_origin" }
new const zclass_clawmodel[] = { "v_knife_undertaker.mdl" }
new const zclass_health = 3200
new const zclass_speed = 280
new const Float:zclass_gravity = 0.75
new const Float:zclass_knockback = 1.5
new const setcoffinsound[] = "zombie_plague/zombi_stamper_iron_maiden_stamping.wav"
new const coffinexsound[] = "zombie_plague/zombi_stamper_iron_maiden_explosion.wav"
new g_sound[][] = 
{
"zombie_plague/zombi_death_stamper_1.wav" ,
"zombie_plague/zombi_death_stamper_2.wav" ,
"zombie_plague/zombi_hurt_stamper_1.wav" ,
"zombie_plague/zombi_hurt_stamper_2.wav"
};
new g_zclass_undertaker, g_shokewaveSpr, humanspr, zm_zombiebomb, g_Wood_SprId, cvar_debug
new skillcooldawn[33], skilluseing[33], setmaxspeed[33], sprremove[33], knifehit[33], removesdamage[33], removeknock[33]
//new cvar_skillcooldawntime, cvar_skillhealth, cvar_coffintime, cvar_exrange, cvar_exknock, cvar_speedtime, cvar_maxspeed, cvar_bot_use_skill, cvar_exdamage, cvar_exhit
enum 
{
anim_idle,
anim_slash1,
anim_skill,
anim_daw,
anim_stab,
anim_stab_miss,
anim_midslash1,
anim_midslash2,
}

const DMG_HEGRENADE = (1<<24)
public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("drop","makecoffin")
	//register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	RegisterHam(Ham_Killed, "player", "player_death",1)
	for (new i = 0; i < sizeof WEAPON_CLASSNAME; i++)
	{
		if (strlen(WEAPON_CLASSNAME[i]) <= 0)
			continue; 
		RegisterHam(Ham_Item_Deploy, WEAPON_CLASSNAME[i], "fwItemDeploy_Post", 1)
	}
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_Weapon_SecondaryAttack")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_Weapon_SecondaryAttack_Post", 1)
	RegisterHam(Ham_TakeDamage, "info_target", "fw_TakeDamage")	
	register_event("DeathMsg", "Death", "a");
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamageplayer")
	RegisterHam(Ham_TraceAttack, "info_target", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttackplayer")
	register_forward(FM_CmdStart, "forward_CmdStart", 1)
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink" , 1)
	register_forward(FM_UpdateClientData, "UpdateClientData_Post", 1) 
	
	cvar_debug = register_cvar("zp_bot_skill_debug", "0")
}

public plugin_precache()
{
	g_zclass_undertaker = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
	engfunc(EngFunc_PrecacheModel,SKILLMODEL)
	g_shokewaveSpr = engfunc(EngFunc_PrecacheModel,"sprites/shockwave.spr")
	humanspr = engfunc(EngFunc_PrecacheModel,"sprites/un_trap.spr")
	zm_zombiebomb = engfunc(EngFunc_PrecacheModel, "sprites/zombiebomb_exp.spr")
	g_Wood_SprId = engfunc(EngFunc_PrecacheModel, "models/woodgibs.mdl")
	engfunc(EngFunc_PrecacheSound,setcoffinsound)
	engfunc(EngFunc_PrecacheSound,coffinexsound)
	for(new i = 0; i < sizeof g_sound; i++)
		precache_sound(g_sound[i]);
}

new Debug
public client_putinserver(id)
{
	if(Debug == 1)return
	new classname[32]
	pev(id,pev_classname,classname,31)
	if(!equal(classname,"player"))
	{
		Debug=1
		set_task(1.0,"_Debug",id)
	}
}
public fw_Weapon_SecondaryAttack(iEntity)
{
	new owner = pev(iEntity, pev_owner)
	knifehit[owner] = true
}

public fw_Weapon_SecondaryAttack_Post(iEntity)
{
	new owner = pev(iEntity, pev_owner)
	knifehit[owner] = false
}
public Death(id)
{
	new id = read_data(2)

	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id)==g_zclass_undertaker && !zp_get_user_nemesis(id))
	{
		engfunc( EngFunc_EmitSound, id, CHAN_ITEM, g_sound[random_num(0,1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED;
	
	if(damage_type & DMG_HEGRENADE)
		return HAM_IGNORED
	
	if(pev(victim, pev_iuser4) == SKILL_COFFIN)
	{
		if(get_user_weapon(attacker) == CSW_KNIFE && knifehit[attacker])
		{
			set_pev(victim, pev_iuser3, pev(victim, pev_iuser3)-1)
			return HAM_SUPERCEDE
		}
		removesdamage[attacker] = true
	}
	
	return HAM_IGNORED
}

public fw_TakeDamageplayer(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED;
	
	if(damage_type & DMG_HEGRENADE)
		return HAM_IGNORED
	
	if(removesdamage[attacker])
	{
		removesdamage[attacker] = false
		return HAM_SUPERCEDE
	}
	if (zp_get_user_zombie_class(victim)==g_zclass_undertaker && zp_get_user_zombie(victim) && !zp_get_user_nemesis(victim))
	{
		emit_sound(victim, CHAN_WEAPON, g_sound[random_num(2,3)], 0.7, ATTN_NORM, 0, PITCH_LOW)
	}	
	return HAM_IGNORED
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:dir[3], ptr, damagetype)
{
	if(!is_user_alive(attacker) || !is_user_connected(attacker))
		return HAM_IGNORED
	
	new iVictim = get_tr2(ptr, TR_pHit)
	
	if(pev(iVictim, pev_iuser4) == SKILL_COFFIN && get_user_weapon(attacker) != CSW_KNIFE)
	{
		removeknock[attacker] = true
		new Float:fHitOrigin[3]
		get_tr2(ptr, TR_vecEndPos, fHitOrigin)
		
		engfunc(EngFunc_MessageBegin,MSG_PVS, SVC_TEMPENTITY, fHitOrigin, 0)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord,fHitOrigin[0])
		engfunc(EngFunc_WriteCoord,fHitOrigin[1])
		engfunc(EngFunc_WriteCoord,fHitOrigin[2])
		write_short(0)
		write_byte(45)
		message_end()
		
		engfunc(EngFunc_MessageBegin,MSG_PVS, SVC_TEMPENTITY, fHitOrigin, 0)
		write_byte(TE_SPARKS)
		engfunc(EngFunc_WriteCoord,fHitOrigin[0])
		engfunc(EngFunc_WriteCoord,fHitOrigin[1])
		engfunc(EngFunc_WriteCoord,fHitOrigin[2])
		message_end()
	}
	
	return HAM_IGNORED
}

public fw_TraceAttackplayer(victim, attacker, Float:damage, Float:dir[3], ptr, damagetype)
{
	if(!is_user_alive(attacker) || !is_user_connected(attacker))
		return HAM_IGNORED
	
	if(removeknock[attacker])
	{
		removeknock[attacker] = false
		return HAM_SUPERCEDE
	}
	
	return HAM_IGNORED
}

public fw_PlayerPreThink(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
	
	if(setmaxspeed[id]) set_speed_to_velocity(id, 0.2)
	//set_pev(id, pev_maxspeed, (pev(id, pev_maxspeed)*get_pcvar_float(cvar_maxspeed)))
	
	return PLUGIN_CONTINUE
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
		if(range <= 150) skilluse(id)
	}
	return PLUGIN_CONTINUE
}

public UpdateClientData_Post(id, sendweapons, cd_handle) 
{ 
	if(!is_user_alive(id)) 
		return PLUGIN_HANDLED
	
	if(skilluseing[id] || sprremove[id])
	{
		set_cd(cd_handle, CD_ID, 0)
		sprremove[id] = false
	}
	
	return PLUGIN_CONTINUE
}

public forward_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
	static button
	button = get_uc(uc_handle, UC_Buttons)
	
	if(skilluseing[id] && (button & IN_ATTACK))
	{
		button &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, button)
	}
	
	return PLUGIN_CONTINUE
}

public zp_user_infected_post(id)
{
	alloff(id)
	setmaxspeed[id] = false
	remove_task(id)
	remove_task(id+TASK_SPEEDTIME)
}

public zp_user_humanized_post(id)
{
	alloff(id)
	setmaxspeed[id] = false
	remove_task(id)
	remove_task(id+TASK_SPEEDTIME)
}

public makecoffin(id)
{
	if(is_user_alive(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_undertaker && !zp_get_user_nemesis(id))
	{
		skilluse(id)
	}
}

public skilluse(id)
{
	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_undertaker && !zp_get_user_nemesis(id) && !skillcooldawn[id] && !skilluseing[id] && get_user_weapon(id) == CSW_KNIFE)
	{
		if(pev(id, pev_flags) & FL_ONGROUND)
		{
			if (is_user_bot(id)&&get_pcvar_num(cvar_debug))
				return	
			
			Player_SetAnimation(id,"skill")
			md_zb_skill(id, 0)
			
			native_playanim(id,anim_skill)
			set_task(0.4, "settheent", id+TASK_SKILLUSEING)
			set_task(1.1, "skillover", id+TASK_SKILLOVER)
			skilluseing[id] = true
		}
		else client_print(id,print_center,"Stand On Ground!")
	}
}

public skillover(taskid)
{
	new id = taskid - TASK_SKILLOVER
	native_playanim(id,anim_idle)
	skilluseing[id] = false
	remove_task(id+TASK_SKILLOVER)
}

public skillcooldawnover(taskid)
{
	new id = taskid - TASK_COOLDAWN
	skillcooldawn[id] = false
	client_print(id, print_center,"Cool down finish! [G]")
	remove_task(id+TASK_COOLDAWN)
}

public settheent(taskid)
{
	new id = taskid - TASK_SKILLUSEING
	remove_task(id+TASK_SKILLUSEING)
	
	if(!zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_undertaker || zp_get_user_nemesis(id))
		return
	
	skillcooldawn[id] = true
	set_task(10.0, "skillcooldawnover", id+TASK_COOLDAWN)
	new Float:origin[3], Float:fAngle[3], Float:fAngle2[3], Float:vec[3]
	pev(id,pev_origin,origin)
	get_origin_distance(id, vec, 40.0) 
	vec[2] += 25.0
	pev(id,pev_angles,fAngle)
	new ent = fm_create_entity("info_target")
	if(!pev_valid(ent)) 
		return
	pev(ent,pev_angles,fAngle2)
	fAngle[0] = fAngle2[0]
	set_pev(ent, pev_classname, SKILLNAME)
	set_pev(ent, pev_iuser4, SKILL_COFFIN)
	set_pev(ent, pev_iuser3, 5)
	engfunc(EngFunc_SetModel,ent,SKILLMODEL)
	engfunc(EngFunc_SetSize, ent, {-14.0, -10.0, -36.0}, {14.0, 10.0, 36.0})
	set_pev(ent, pev_mins, {-14.0, -10.0, -36.0});
	set_pev(ent, pev_maxs, {14.0, 10.0, 36.0});
	set_pev(ent, pev_absmin, {-14.0, -10.0, -36.0})
	set_pev(ent, pev_absmax, {-14.0, -10.0, -36.0})
	set_pev(ent, pev_health, 1000.0)
	set_pev(ent, pev_gravity, 2.0)
	set_pev(ent, pev_solid,SOLID_BBOX)
	set_pev(ent, pev_movetype,MOVETYPE_TOSS)
	set_pev(ent, pev_takedamage, DAMAGE_YES)
	set_pev(ent,pev_angles,fAngle)
	engfunc(EngFunc_SetOrigin,ent, vec)
	engfunc(EngFunc_DropToFloor, ent) 
	engfunc(EngFunc_EmitSound, ent, CHAN_AUTO, setcoffinsound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_task(10.0, "removecoffin", ent, _, _, "b")
	set_task(0.1, "coffinthink", ent+TASK_ENTTHINK, _, _, "b")
	new Float:iorigin[3], Float:entorigin[3]
	pev(ent, pev_origin, entorigin)
	for(new i=1;i<33;i++)
	{
		pev(i, pev_origin, iorigin)
		new Float:range = get_distance_f(entorigin, iorigin)
		if(range <= 150 && is_user_alive(i) && !zp_get_user_zombie(i) && !setmaxspeed[id])
		{
			setmaxspeed[i] = true
			makespr(i)
			set_task(5.0, "overspeedtime", i+TASK_SPEEDTIME)
		}
	}
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, entorigin, 0)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, entorigin[0])
	engfunc(EngFunc_WriteCoord, entorigin[1])
	engfunc(EngFunc_WriteCoord, entorigin[2]-10)
	engfunc(EngFunc_WriteCoord, entorigin[0]-150)
	engfunc(EngFunc_WriteCoord, entorigin[1])
	engfunc(EngFunc_WriteCoord, entorigin[2]+300)
	write_short(g_shokewaveSpr)
	write_byte(0)
	write_byte(0)
	write_byte(2)
	write_byte(20)
	write_byte(0)
	write_byte(255)
	write_byte(255)
	write_byte(255)
	write_byte(100)
	write_byte(2)
	message_end()
	gettheent(ent)
}

public gettheent(ent)
{
	if(!pev_valid(ent)) 
		return
	
	if(!is_player_stuck(ent) || pev(ent, pev_movetype) == MOVETYPE_NOCLIP || pev(ent,pev_solid) == SOLID_NOT)
		return
	
	removecoffin(ent)
}

public makespr(id)
{
	if(zp_get_user_zombie(id) || !is_user_alive(id))
		return
	
	new Float:hm_origin[3]
	pev(id, pev_origin, hm_origin)
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, hm_origin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord,hm_origin[0])
	engfunc(EngFunc_WriteCoord,hm_origin[1])
	engfunc(EngFunc_WriteCoord,hm_origin[2]+10.0)
	write_short(humanspr)
	write_byte(8)
	write_byte(255)
	message_end()
	
	set_task(0.1,"makespr",id)
}

public overspeedtime(taskid)
{
	new id = taskid - TASK_SPEEDTIME
	setmaxspeed[id] = false
	remove_task(id)
	remove_task(id+TASK_SPEEDTIME)
}

public coffinthink(taskent)
{
	new ent = taskent - TASK_ENTTHINK
	if(!pev_valid(ent)) 
		return
	
	if(pev(ent, pev_health) <= 10 || pev(ent, pev_iuser3) <= 0)removecoffin(ent)
}
public removecoffin(ent)
{
	new Float:iorigin[3], Float:entorigin[3]
	pev(ent, pev_origin, entorigin)
	static Owner; Owner = pev(ent, pev_iuser1)
	
	for(new i=1;i<33;i++)
	{
		pev(i, pev_origin, iorigin)
		new Float:range = get_distance_f(entorigin, iorigin)
		if(range <= 300.0 && is_user_alive(i))
		{	
			ExecuteHam(Ham_TakeDamage, i, 0, Owner, 80.0, DMG_EXPLOSION);
			set_velocity_from_origin(i, entorigin, float(100+700))
			if(!setmaxspeed[i] && !zp_get_user_zombie(i))
			{
				setmaxspeed[i] = true
				makespr(i)
				set_task(5.0, "overspeedtime", i+TASK_SPEEDTIME)
			}
		}
	}	
	
	engfunc(EngFunc_EmitSound, ent, CHAN_AUTO, coffinexsound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, entorigin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, entorigin[0])
	engfunc(EngFunc_WriteCoord, entorigin[1])
	engfunc(EngFunc_WriteCoord, entorigin[2]+38.0)
	write_short(zm_zombiebomb)
	write_byte(20)
	write_byte(255)
	message_end()
	
	// Break Model
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, entorigin, 0)
	write_byte(TE_BREAKMODEL)
	engfunc(EngFunc_WriteCoord, entorigin[0])
	engfunc(EngFunc_WriteCoord, entorigin[1])
	engfunc(EngFunc_WriteCoord, entorigin[2] - 36.0)
	engfunc(EngFunc_WriteCoord, 36)
	engfunc(EngFunc_WriteCoord, 36)
	engfunc(EngFunc_WriteCoord, 36)
	engfunc(EngFunc_WriteCoord, random_num(-25, 25))
	engfunc(EngFunc_WriteCoord, random_num(-25, 25))
	engfunc(EngFunc_WriteCoord, 25)
	write_byte(20)
	write_short(g_Wood_SprId)
	write_byte(10)
	write_byte(25)
	write_byte(0x08)
	message_end()
	
	remove_task(ent)
	remove_task(ent+TASK_ENTTHINK)
	engfunc(EngFunc_RemoveEntity, ent)
}
public alloff(id)
{
	skillcooldawn[id] = false
	skilluseing[id] = false
	remove_task(id+TASK_SKILLUSEING)
	remove_task(id+TASK_COOLDAWN)
	remove_task(id+TASK_SKILLOVER)
}

public fwItemDeploy_Post(ent)
{
	new id = get_pdata_cbase(ent, 41, 4)
	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_undertaker && !zp_get_user_nemesis(id))
	{
		remove_task(id+TASK_SKILLUSEING)
		remove_task(id+TASK_SKILLOVER)
		skilluseing[id] = false
	}
}

public player_death(id) 
{
	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_undertaker && !zp_get_user_nemesis(id))
	{
		alloff(id)
		setmaxspeed[id] = false
		remove_task(id)
		remove_task(id+TASK_SPEEDTIME)
	}
}

public _Debug(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamageplayer")
	RegisterHamFromEntity(Ham_Killed,id,"player_death", 1)
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttackplayer")
}

stock native_playanim(player,anim)
{
	set_pev(player, pev_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(pev(player, pev_body))
	message_end()
}

stock get_origin_distance( index, Float:origin[3], Float:dist ) 
{
	new Float:start[ 3 ];
	new Float:view_ofs[ 3 ];
	
	pev( index, pev_origin, start );
	pev( index, pev_view_ofs, view_ofs );
	xs_vec_add( start, view_ofs, start );
	
	new Float:dest[3];
	pev(index, pev_angles, dest );
	
	engfunc( EngFunc_MakeVectors, dest );
	global_get( glb_v_forward, dest );
	
	xs_vec_mul_scalar( dest, dist, dest );
	xs_vec_add( start, dest, dest );
	
	engfunc( EngFunc_TraceLine, start, dest, 0, index, 0 );
	get_tr2( 0, TR_vecEndPos, origin );
	
	return 1;
} 

stock set_velocity_from_origin( ent, Float:fOrigin[3], Float:fSpeed )
{
	new Float:fVelocity[3]
	
	get_velocity_from_origin( ent, fOrigin, fSpeed, fVelocity )
	set_pev( ent, pev_velocity, fVelocity )
	
	return 1
} 

stock get_velocity_from_origin( ent, Float:fOrigin[3], Float:fSpeed, Float:fVelocity[3] )
{
	new Float:fEntOrigin[3];
	pev( ent, pev_origin, fEntOrigin );
	
	new Float:fDistance[3];
	fDistance[0] = fEntOrigin[0] - fOrigin[0]
	fDistance[1] = fEntOrigin[1] - fOrigin[1]
	fDistance[2] = fEntOrigin[2] - fOrigin[2]
	
	new Float:fTime = ( vector_distance( fEntOrigin,fOrigin ) / fSpeed )
	
	fVelocity[0] = fDistance[0] / fTime
	fVelocity[1] = fDistance[1] / fTime
	fVelocity[2] = fDistance[2] / fTime
	
	return ( fVelocity[0] && fVelocity[1] && fVelocity[2] )
}

stock is_player_stuck(id)
{
	static Float:originF[3]
	pev(id, pev_origin, originF)
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true
	
	return false
}

stock set_speed_to_velocity(id, Float:scalar = 1.0)
{
	new Float:velocity[3]
	pev(id, pev_velocity, velocity)
	xs_vec_mul_scalar(velocity, scalar, velocity)
	velocity[2] = velocity[2]/scalar
	set_pev(id, pev_velocity, velocity)
	
	return 1
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
