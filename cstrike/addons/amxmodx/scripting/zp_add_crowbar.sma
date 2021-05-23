#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <zombieplague>

#define PLUGIN "[Mileage] Melee: Maverick Crowbar"
#define VERSION "1.0"
#define AUTHOR "Joseph Rias de Dias"

#define DISTANCE 130.0
#define DAMAGE_MULTI 80.0 // 12.0 for zombie

#define MODEL_V "models/v_crowbarcraft.mdl"
#define MODEL_P "models/p_crowbarcraft.mdl"
const m_flNextAttack = 83
new const WeaponSounds[7][] = 
{
	"weapons/crowbarcraft_draw.wav",
	"weapons/crowbarcraft_slash1.wav",
	"weapons/crowbarcraft_slash2.wav",
	"weapons/crowbarcraft_stab.wav",
	"weapons/crowbarcraft_stab_miss.wav",
	"weapons/janus9_stone1.wav",
	"weapons/katanad_stab.wav"
}
new g_Had_Crowbar[33], g_Stab[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")	
	
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage")
}

public plugin_precache()
{
	precache_model(MODEL_V)
	precache_model(MODEL_P)
	
	for(new i = 0; i < sizeof(WeaponSounds); i++)
		precache_sound(WeaponSounds[i])
}
public client_putinserver(id)
{	
	new g_Ham_Bot

	if(!g_Ham_Bot && is_user_bot(id))
	{
		g_Ham_Bot = 1
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
}
public Do_RegisterHam_Bot(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_PlayerTakeDamage")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack", 1)
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
}
public plugin_natives()
{
    register_native("crowbar", "crowbar", 1)
}

public crowbar(id)
{
        Get_Crowbar(id)
}
public zp_user_infected_post(id) Remove_Crowbar(id)

public Get_Crowbar(id)
{
	g_Had_Crowbar[id] = 1
	g_Stab[id] = 0
	
	if(get_user_weapon(id) == CSW_KNIFE)
	{
		set_pev(id, pev_viewmodel2, MODEL_V)
		set_pev(id, pev_weaponmodel2, MODEL_P)
		
		Set_WeaponAnim(id, 3)
		set_pdata_float(id, 83, 0.75, 5)
	} /*else {
		engclient_cmd(id, "weapon_knife")
	}*/
}

public Remove_Crowbar(id) g_Had_Crowbar[id] = g_Stab[id] = 0

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return

	// Problem Here ?. SHUT THE FUCK UP
	if(get_user_weapon(id) == CSW_KNIFE && g_Had_Crowbar[id])
	{
		set_pev(id, pev_viewmodel2, MODEL_V)
		set_pev(id, pev_weaponmodel2, MODEL_P)
	}
}
public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return
	
	static Button; Button = get_uc(uc_handle, UC_Buttons)
	if(Button & IN_ATTACK) g_Stab[id] = 0
	if(Button & IN_ATTACK2)	g_Stab[id] = 1
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED
	if(!g_Had_Crowbar[id])
		return FMRES_IGNORED
		
	if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
		{
			emit_sound(id, channel, WeaponSounds[random_num(1, 2)], volume, attn, flags, pitch)
			set_pdata_float(id, 83, 0.5, 5)
			
			return FMRES_SUPERCEDE
		}
		if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
		{
			if (sample[17] == 'w') // wall
			{
				if(g_Stab[id]) emit_sound(id, channel, WeaponSounds[3], volume, attn, flags, pitch)
				else {
					emit_sound(id, channel, WeaponSounds[5], volume, attn, flags, pitch)
					set_pdata_float(id, 83, 0.5, 5)
				}
				
				return FMRES_SUPERCEDE
			} else {
				emit_sound(id, channel, WeaponSounds[6], volume, attn, flags, pitch)
				set_pdata_float(id, 83, 0.5, 5)
				
				return FMRES_SUPERCEDE
			}
		}
		if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
		{
			emit_sound(id, channel, WeaponSounds[3], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED
}

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED	
	if (get_user_weapon(id) != CSW_KNIFE || !g_Had_Crowbar[id])
		return FMRES_IGNORED

	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)

	xs_vec_mul_scalar(v_forward, DISTANCE, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, ignored_monster, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED	
	if (get_user_weapon(id) != CSW_KNIFE || !g_Had_Crowbar[id])
		return FMRES_IGNORED

	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)
	
	xs_vec_mul_scalar(v_forward, DISTANCE, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceHull, vecStart, vecEnd, ignored_monster, hull, id, handle)
	
	return FMRES_SUPERCEDE
}
public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if (!is_user_alive(iAttacker))
		return FMRES_IGNORED	
	if (get_user_weapon(iAttacker) != CSW_KNIFE || !g_Had_Crowbar[iAttacker])
		return FMRES_IGNORED
		
	
	static Float:VicOrigin[3], Float:MyOrigin[3]
	pev(iAttacker, pev_origin, MyOrigin)
	static ent
	ent = fm_get_user_weapon_entity(iAttacker, get_user_weapon(iAttacker))
	// Alive...
	new a = FM_NULLENT
	// Get distance between victim and epicenter
	while((a = find_ent_in_sphere(a, MyOrigin, DISTANCE)) != 0)
	{
		if (iAttacker == a)
			continue 
		pev(a, pev_origin, VicOrigin)
		if(!is_in_viewcone(iAttacker, VicOrigin, 1))
			continue
		if(is_wall_between_points(MyOrigin, VicOrigin, iAttacker))
			continue	
			
		if(pev(a, pev_takedamage) != DAMAGE_NO)
		{
			
			do_attack(iAttacker, a, ent, 10.0)
		
			MyOrigin[2]-=25.0
			if(g_Stab[iAttacker])
			{
				CreateBombKnockBack(a,MyOrigin,500.0,1500.0)
			}else  CreateBombKnockBack(a,MyOrigin,500.0,700.0)
		}
	}
	
	
	/*static Float:VicOrigin[3], Float:MyOrigin[3]
	pev(iAttacker, pev_origin, MyOrigin)
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(iAttacker == i)
			continue
		if(entity_range(iAttacker, i) > DISTANCE)
			continue
		pev(i, pev_origin, VicOrigin)
		
		if(!is_in_viewcone(iAttacker, VicOrigin, 1))
			continue
		if(is_wall_between_points(MyOrigin, VicOrigin, iAttacker))
			continue
			
		ExecuteHamB(Ham_TakeDamage, i ,iAttacker ,iAttacker,  DAMAGE_MULTI, DMG_SLASH)
		
		MyOrigin[2]-=25.0
		if(g_Stab[iAttacker])
		{
			CreateBombKnockBack(i,MyOrigin,1000.0,1500.0)
		}else  CreateBombKnockBack(i,MyOrigin,1000.0,700.0)
	}*/	
}

public fw_PlayerTakeDamage(Victim, Inflictor, Attacker, Float:Damage, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED
	if(get_user_weapon(Attacker) != CSW_KNIFE || !g_Had_Crowbar[Attacker])
		return HAM_IGNORED
	
	//SetHamParamFloat(4, Damage * DAMAGE_MULTI)

	static Float:originF[3]
	pev(Attacker, pev_origin, originF)
	originF[2]-=20.0
	/*
	if(g_Stab[Attacker])
	{
		CreateBombKnockBack(Victim,originF,1000.0,1500.0)
	}else  CreateBombKnockBack(Victim,originF,1000.0,700.0)*/
	return HAM_IGNORED
}

stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}
stock CreateBombKnockBack(iVictim,Float:vAttacker[3],Float:fMulti,Float:fRadius)
{
	new Float:vVictim[3];
	pev(iVictim, pev_origin, vVictim);
	static ducking
	ducking = pev(iVictim, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)
	if(ducking)
	{
		xs_vec_sub(vVictim, vAttacker, vVictim);
		xs_vec_mul_scalar(vVictim, fMulti * 0.7 * 3.0 , vVictim);
		xs_vec_mul_scalar(vVictim, fRadius / xs_vec_len(vVictim), vVictim);
		set_pev(iVictim, pev_velocity, vVictim);
	}else{

		xs_vec_sub(vVictim, vAttacker, vVictim);
		xs_vec_mul_scalar(vVictim, fMulti * 0.7, vVictim);
		xs_vec_mul_scalar(vVictim, fRadius / xs_vec_len(vVictim), vVictim);
		set_pev(iVictim, pev_velocity, vVictim);
	}
}
stock is_wall_between_points(Float:start[3], Float:end[3], ignore_ent)
{
	static ptr
	ptr = create_tr2()

	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	free_tr2(ptr)
	return floatround(get_distance_f(end, EndPos))
} 

do_attack(Attacker, Victim, Inflictor, Float:fDamage)
{
	fake_player_trace_attack(Attacker, Victim, fDamage)
	fake_take_damage(Attacker, Victim, fDamage, Inflictor)
}

fake_player_trace_attack(iAttacker, iVictim, &Float:fDamage)
{
	// get fDirection
	new Float:fAngles[3], Float:fDirection[3]
	pev(iAttacker, pev_angles, fAngles)
	angle_vector(fAngles, ANGLEVECTOR_FORWARD, fDirection)
	
	// get fStart
	new Float:fStart[3], Float:fViewOfs[3]
	pev(iAttacker, pev_origin, fStart)
	pev(iAttacker, pev_view_ofs, fViewOfs)
	xs_vec_add(fViewOfs, fStart, fStart)
	
	// get aimOrigin
	new iAimOrigin[3], Float:fAimOrigin[3]
	get_user_origin(iAttacker, iAimOrigin, 3)
	IVecFVec(iAimOrigin, fAimOrigin)
	
	// TraceLine from fStart to AimOrigin
	new ptr = create_tr2() 
	engfunc(EngFunc_TraceLine, fStart, fAimOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr)
	new pHit = get_tr2(ptr, TR_pHit)
	new iHitgroup = get_tr2(ptr, TR_iHitgroup)
	new Float:fEndPos[3]
	get_tr2(ptr, TR_vecEndPos, fEndPos)

	// get target & body at aiming
	new iTarget, iBody
	get_user_aiming(iAttacker, iTarget, iBody)
	
	// if aiming find target is iVictim then update iHitgroup
	if (iTarget == iVictim)
	{
		iHitgroup = iBody
	}
	
	// if ptr find target not is iVictim
	else if (pHit != iVictim)
	{
		// get AimOrigin in iVictim
		new Float:fVicOrigin[3], Float:fVicViewOfs[3], Float:fAimInVictim[3]
		pev(iVictim, pev_origin, fVicOrigin)
		pev(iVictim, pev_view_ofs, fVicViewOfs) 
		xs_vec_add(fVicViewOfs, fVicOrigin, fAimInVictim)
		fAimInVictim[2] = fStart[2]
		fAimInVictim[2] += get_distance_f(fStart, fAimInVictim) * floattan( fAngles[0] * 2.0, degrees )
		
		// check aim in size of iVictim
		new iAngleToVictim = get_angle_to_target(iAttacker, fVicOrigin)
		iAngleToVictim = abs(iAngleToVictim)
		new Float:fDis = 2.0 * get_distance_f(fStart, fAimInVictim) * floatsin( float(iAngleToVictim) * 0.5, degrees )
		new Float:fVicSize[3]
		pev(iVictim, pev_size , fVicSize)
		if ( fDis <= fVicSize[0] * 0.5 )
		{
			// TraceLine from fStart to aimOrigin in iVictim
			new ptr2 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fAimInVictim, DONT_IGNORE_MONSTERS, iAttacker, ptr2)
			new pHit2 = get_tr2(ptr2, TR_pHit)
			new iHitgroup2 = get_tr2(ptr2, TR_iHitgroup)
			
			// if ptr2 find target is iVictim
			if ( pHit2 == iVictim && (iHitgroup2 != HIT_HEAD || fDis <= fVicSize[0] * 0.25) )
			{
				pHit = iVictim
				iHitgroup = iHitgroup2
				get_tr2(ptr2, TR_vecEndPos, fEndPos)
			}
			
			free_tr2(ptr2)
		}
		
		// if pHit still not is iVictim then set default HitGroup
		if (pHit != iVictim)
		{
			// set default iHitgroup
			iHitgroup = HIT_GENERIC
			
			new ptr3 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fVicOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr3)
			get_tr2(ptr3, TR_vecEndPos, fEndPos)
			
			// free ptr3
			free_tr2(ptr3)
		}
	}
	
	// set new Hit & Hitgroup & EndPos
	set_tr2(ptr, TR_pHit, iVictim)
	set_tr2(ptr, TR_iHitgroup, iHitgroup)
	set_tr2(ptr, TR_vecEndPos, fEndPos)
	
	// hitgroup multi fDamage
	new Float:fMultifDamage 
	switch(iHitgroup)
	{
		case HIT_HEAD: fMultifDamage  = 2.0
		case HIT_STOMACH: fMultifDamage  = 1.25
		case HIT_LEFTLEG: fMultifDamage  = 0.75
		case HIT_RIGHTLEG: fMultifDamage  = 0.75
		default: fMultifDamage  = 1.0
	}
	
	fDamage *= fMultifDamage
	
	// ExecuteHam
	fake_trake_attack(iAttacker, iVictim, fDamage, fDirection, ptr)
	
	// free ptr
	free_tr2(ptr)
}

stock fake_trake_attack(iAttacker, iVictim, Float:fDamage, Float:fDirection[3], iTraceHandle, iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
	ExecuteHamB(Ham_TraceAttack, iVictim, iAttacker, fDamage, fDirection, iTraceHandle, iDamageBit)
}

stock fake_take_damage(iAttacker, iVictim, Float:fDamage, iInflictor = 0, iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
	iInflictor = (!iInflictor) ? iAttacker : iInflictor
	ExecuteHamB(Ham_TakeDamage, iVictim, iInflictor, iAttacker, fDamage, iDamageBit)
}

stock get_angle_to_target(id, const Float:fTarget[3], Float:TargetSize = 0.0)
{
	new Float:fOrigin[3], iAimOrigin[3], Float:fAimOrigin[3], Float:fV1[3]
	pev(id, pev_origin, fOrigin)
	get_user_origin(id, iAimOrigin, 3) // end position from eyes
	IVecFVec(iAimOrigin, fAimOrigin)
	xs_vec_sub(fAimOrigin, fOrigin, fV1)
	
	new Float:fV2[3]
	xs_vec_sub(fTarget, fOrigin, fV2)
	
	new iResult = get_angle_between_vectors(fV1, fV2)
	
	if (TargetSize > 0.0)
	{
		new Float:fTan = TargetSize / get_distance_f(fOrigin, fTarget)
		new fAngleToTargetSize = floatround( floatatan(fTan, degrees) )
		iResult -= (iResult > 0) ? fAngleToTargetSize : -fAngleToTargetSize
	}
	
	return iResult
}

stock get_angle_between_vectors(const Float:fV1[3], const Float:fV2[3])
{
	new Float:fA1[3], Float:fA2[3]
	engfunc(EngFunc_VecToAngles, fV1, fA1)
	engfunc(EngFunc_VecToAngles, fV2, fA2)
	
	new iResult = floatround(fA1[1] - fA2[1])
	iResult = iResult % 360
	iResult = (iResult > 180) ? (iResult - 360) : iResult
	
	return iResult
}