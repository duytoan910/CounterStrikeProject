#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <xs>
#include <zombieplague>

#define PLUGIN "[ZP] Extra Item: Dragon Sword"
#define VERSION "2.0"
#define AUTHOR "Dias Leon"

#define V_MODEL "models/v_zbs64knife.mdl"
#define P_MODEL "models/p_zbs64knife.mdl"

#define DAMAGE_A 394 // 200 for Zombie
#define DAMAGE_B 1284 // 400 for Zombie
#define RADIUS_A 100.0
#define RADIUS_B 120.0

#define CSW_ZBS64KNIFE CSW_KNIFE
#define weapon_zbs64knife "weapon_knife"
#define WEAPON_ANIMEXT "knife" //"skullaxe"

#define TASK_SLASHING 2033+20
#define TASK_STABING 2033+10

// OFFSET
const PDATA_SAFE = 2
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_WEAPONOWNER = 41
const m_flNextAttack = 83
const m_szAnimExtention = 492

new const WeaponSounds[][] =
{
	"weapons/zbs64knife_draw.wav",
	"weapons/zbs64knife_midslash1.wav",
	"weapons/zbs64knife_midslash2.wav",
	"weapons/zbs64knife_midslash3.wav",
	"weapons/zbs64knife_stab.wav",
	"weapons/zbs64knife_stab_miss.wav",
	"weapons/zbs64knife_hit1.wav",
	"weapons/zbs64knife_hit2.wav",
	"weapons/zbs64knife_hit3.wav",
	"weapons/mastercombat_wall.wav"
}
enum
{
	ANIM_IDLE = 0,
	ANIM_SLASH1,
	ANIM_SLASH2,
	ANIM_DRAW,
	ANIM_STAB,
	ANIM_STAB_MISS,
	ANIM_MSLASH1,
	ANIM_MSLASH2,
	ANIM_MSLASH3
}
enum
{
	ATTACK_SLASH= 1,
	ATTACK_STAB
}

enum
{
	HIT_NOTHING = 0,
	HIT_ENEMY,
	HIT_WALL
}

new g_Had_Zbs64Knife[33], g_Attack_Mode[33], g_Checking_Mode[33], g_Hit_Ing[33]
new g_Old_Weapon[33], g_Ham_Bot,m_iBlood[2]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	//register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_TraceLine, "fw_TraceLine",1)
	register_forward(FM_TraceHull, "fw_TraceHull")
	
	RegisterHam(Ham_TraceAttack, "player", "fw_PlayerTraceAttack")
	RegisterHam(Ham_Item_Deploy, weapon_zbs64knife, "fw_Item_Deploy_Post", 1)
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
}

public plugin_natives()
{
	register_native("jaydagger", "get_jaydagger", 1)
}
public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	
	for(new i = 0; i < sizeof(WeaponSounds); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
	m_iBlood[0] = precache_model("sprites/blood.spr");
	m_iBlood[1] = precache_model("sprites/bloodspray.spr");	
}

public zp_user_infected_post(id) remove_jaydagger(id)
public get_jaydagger(id)
{
	remove_task(id+TASK_SLASHING)
	remove_task(id+TASK_STABING)
		
	g_Had_Zbs64Knife[id] = 1
	g_Attack_Mode[id] = 0
	g_Checking_Mode[id] = 0
	g_Hit_Ing[id] = 0
	fm_give_item(id, "weapon_knife")
}

public remove_jaydagger(id)
{
	remove_task(id+TASK_SLASHING)
	remove_task(id+TASK_STABING)
		
	g_Had_Zbs64Knife[id] = 0
	g_Attack_Mode[id] = 0
	g_Checking_Mode[id] = 0
	g_Hit_Ing[id] = 0
}

public client_putinserver(id)
{
	if(!g_Ham_Bot && is_user_bot(id))
	{
		g_Ham_Bot = 1
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
}

public Do_RegisterHam_Bot(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_PlayerTraceAttack")
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return

	// Problem Here ?. SHUT THE FUCK UP
	if((read_data(2) == CSW_ZBS64KNIFE && g_Old_Weapon[id] != CSW_ZBS64KNIFE) && g_Had_Zbs64Knife[id])
	{
		set_pev(id, pev_viewmodel2, V_MODEL)
		set_pev(id, pev_weaponmodel2, P_MODEL)
	
		set_weapon_anim(id, ANIM_DRAW)
		set_weapons_timeidle(id, CSW_ZBS64KNIFE, 0.5)
		set_player_nextattack(id, 0.5)
		
		set_pdata_string(id, m_szAnimExtention * 4, WEAPON_ANIMEXT, -1 , 20)
	}
		
	g_Old_Weapon[id] = read_data(2)
}

public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!g_Had_Zbs64Knife[Id])
		return
	if(zp_get_user_zombie(Id))
		return
	
	set_pev(Id, pev_viewmodel2, V_MODEL)
	set_pev(Id, pev_weaponmodel2, P_MODEL)

	set_weapon_anim(Id, ANIM_DRAW)
	set_weapons_timeidle(Id, CSW_ZBS64KNIFE, 0.5)
	set_player_nextattack(Id, 0.5)
	
	set_pdata_string(Id, m_szAnimExtention * 4, WEAPON_ANIMEXT, -1 , 20)
	emit_sound(Id, CHAN_ITEM, WeaponSounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED
	if(/*get_user_weapon(id) != CSW_ZBS64KNIFE || */!g_Had_Zbs64Knife[id])
		return FMRES_IGNORED
		
	if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
			return FMRES_SUPERCEDE
		if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
		{
			if (sample[17] == 'w') // wall
			{
				g_Hit_Ing[id] = HIT_WALL
				return FMRES_SUPERCEDE
			} else {
				g_Hit_Ing[id] = HIT_ENEMY
				return FMRES_SUPERCEDE
			}
		}
		if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
			return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id)) 
		return
	if(get_user_weapon(id) != CSW_ZBS64KNIFE || !g_Had_Zbs64Knife[id])
		return
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_ZBS64KNIFE)
	
	if(!pev_valid(ent))
		return
	if(get_pdata_float(ent, 46, OFFSET_LINUX_WEAPONS) > 0.0 || get_pdata_float(ent, 47, OFFSET_LINUX_WEAPONS) > 0.0) 
		return
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if (CurButton & IN_ATTACK)
	{
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK)

		g_Attack_Mode[id] = ATTACK_SLASH
		g_Checking_Mode[id] = 1
		ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
		g_Checking_Mode[id] = 0

		Primary_Attack(id, random_num(0,10))
	} else if (CurButton & IN_ATTACK2) {
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK2)
		
		g_Attack_Mode[id] = ATTACK_STAB
		g_Checking_Mode[id] = 1
		ExecuteHamB(Ham_Weapon_SecondaryAttack, ent)
		g_Checking_Mode[id] = 0
		
		set_pev(id, pev_framerate, 1.5)
		set_weapons_timeidle(id, CSW_ZBS64KNIFE, 1.0)
		set_player_nextattack(id, 1.0)
		
		set_weapon_anim(id, ANIM_SLASH2)
		
		remove_task(id+TASK_STABING)
		set_task(0.42, "Do_StabNow", id+TASK_STABING)
	}
}
public Primary_Attack(id, NoDelayAttack)
{
	if(!NoDelayAttack)
	{
		set_weapons_timeidle(id, CSW_ZBS64KNIFE, 1.0)
		set_player_nextattack(id, 1.0)			
		set_weapon_anim(id, ANIM_MSLASH3)
		set_task(0.1, "Do_Slashing", id+TASK_SLASHING)
	}else{		
		set_weapons_timeidle(id, CSW_ZBS64KNIFE, 0.4)
		set_player_nextattack(id, 0.4)			
		set_weapon_anim(id, random_num(ANIM_MSLASH1,ANIM_MSLASH2))
		set_task(0.1, "Do_Slashing", id+TASK_SLASHING)
	}	
}
public Do_Slashing(id)
{
	id -= TASK_SLASHING
	
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_ZBS64KNIFE || !g_Had_Zbs64Knife[id])
		return
		
	if(Check_Attack(id, ATTACK_SLASH))
	{
		emit_sound(id, CHAN_ITEM, WeaponSounds[random_num(6, 8)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	} else {
		if(g_Hit_Ing[id] == HIT_WALL)
		{
			emit_sound(id, CHAN_ITEM, WeaponSounds[9], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)	
		}
		else if(g_Hit_Ing[id] == HIT_NOTHING) emit_sound(id, CHAN_WEAPON, WeaponSounds[random_num(1,3)], ATTN_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
	
	g_Attack_Mode[id] = 0
	g_Hit_Ing[id] = 0
}

public Do_StabNow(id)
{
	id -= TASK_STABING
	
	if (!is_user_alive(id)) 
		return
	if(get_user_weapon(id) != CSW_ZBS64KNIFE || !g_Had_Zbs64Knife[id])
		return

	if(Check_Attack(id, ATTACK_STAB))
	{
		emit_sound(id, CHAN_ITEM, WeaponSounds[random_num(6, 8)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	} else {
		if(g_Hit_Ing[id] == HIT_WALL) emit_sound(id, CHAN_ITEM, WeaponSounds[9], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)	
		else if(g_Hit_Ing[id] == HIT_NOTHING) emit_sound(id, CHAN_WEAPON, WeaponSounds[random_num(1,3)], ATTN_NORM, ATTN_NORM, 0, PITCH_NORM)
	}

	g_Attack_Mode[id] = 0
	g_Hit_Ing[id] = 0
}


public Check_Attack(id, Mode)
{
	static Float:Max_Distance, Float:Point[4][3], Float:TB_Distance, Float:Point_Dis
	
	if(Mode == ATTACK_SLASH)
	{
		Point_Dis = RADIUS_A/2
		Max_Distance = RADIUS_A
		TB_Distance = Max_Distance / 4.0
	} else if(Mode == ATTACK_STAB) {
		Point_Dis = RADIUS_B/2
		Max_Distance = RADIUS_B
		TB_Distance = Max_Distance / 4.0
	}
	
	static Float:VicOrigin[3], Float:MyOrigin[3]
	pev(id, pev_origin, MyOrigin)
	
	for(new i = 0; i < 4; i++)
		get_position(id, TB_Distance * (i + 1), 0.0, 0.0, Point[i])
		
	static Have_Victim; Have_Victim = 0
	static ent
	ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
		
	if(!pev_valid(ent))
		return 0
		
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(id == i)
			continue
		if(entity_range(id, i) > Max_Distance)
			continue
	
		pev(i, pev_origin, VicOrigin)
		if(is_wall_between_points(MyOrigin, VicOrigin, id))
			continue
			
		if(get_distance_f(VicOrigin, Point[0]) <= Point_Dis
		|| get_distance_f(VicOrigin, Point[1]) <= Point_Dis
		|| get_distance_f(VicOrigin, Point[2]) <= Point_Dis
		|| get_distance_f(VicOrigin, Point[3]) <= Point_Dis)
		{
			if(!Have_Victim) Have_Victim = 1
			if(!zp_get_user_zombie(i))
				continue
			static Float:vecViewAngle[3]; pev(id, pev_v_angle, vecViewAngle);
			static Float:vecForward[3]; angle_vector(vecViewAngle, ANGLEVECTOR_FORWARD, vecForward);
			if(Mode == ATTACK_SLASH)		
				do_attack(id, i, ent, float(random_num(DAMAGE_A-10,DAMAGE_A+10)))
			else if(Mode == ATTACK_STAB)
			{
				FakeKnockBack(i, vecForward, 0.5);
				do_attack(id, i, ent, float(random_num(DAMAGE_B-10,DAMAGE_B+10)))
			}
			make_blood(VicOrigin)				
		}	
	}	
	
	if(Have_Victim)
		return 1
	else
		return 0
	
	return 0
}	

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED	
	if (get_user_weapon(id) != CSW_ZBS64KNIFE || !g_Had_Zbs64Knife[id])
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)

	if(g_Attack_Mode[id] == ATTACK_SLASH) xs_vec_mul_scalar(v_forward, RADIUS_A, v_forward)
	else if(g_Attack_Mode[id] == ATTACK_STAB) xs_vec_mul_scalar(v_forward, RADIUS_B, v_forward)
	else xs_vec_mul_scalar(v_forward, 0.0, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, ignored_monster, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED	
	if (get_user_weapon(id) != CSW_ZBS64KNIFE || !g_Had_Zbs64Knife[id])
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)
	
	if(g_Attack_Mode[id] == ATTACK_SLASH) xs_vec_mul_scalar(v_forward, RADIUS_A, v_forward)
	else if(g_Attack_Mode[id] == ATTACK_STAB) xs_vec_mul_scalar(v_forward, RADIUS_B, v_forward)
	else xs_vec_mul_scalar(v_forward, 0.0, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceHull, vecStart, vecEnd, ignored_monster, hull, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_PlayerTraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], TraceResult, DamageBits) 
{
	if(!is_user_alive(Attacker))	
		return HAM_IGNORED
	if(!g_Had_Zbs64Knife[Attacker] || !g_Checking_Mode[Attacker])
		return HAM_IGNORED
		
	return HAM_SUPERCEDE
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
		case HIT_CHEST: fMultifDamage  = 1.5
		case HIT_STOMACH: fMultifDamage  = 1.4
		case HIT_LEFTLEG: fMultifDamage  = 0.85
		case HIT_RIGHTLEG: fMultifDamage  = 0.85
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

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
		
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
	message_end()	
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entwpn, 47, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, OFFSET_LINUX_WEAPONS)
}

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
}

stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
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

stock FakeKnockBack(iPlayer, Float: vecDirection[3], Float:flKnockBack)
{
	static Float:vecVelocity[3]; pev(iPlayer, pev_velocity, vecVelocity);
	
	if (pev(iPlayer, pev_flags) & FL_DUCKING)
	{
		flKnockBack *= 0.7;
	}
	
	vecVelocity[0] = vecDirection[0] * 500.0 * flKnockBack;
	vecVelocity[1] = vecDirection[1] * 500.0 * flKnockBack;
	vecVelocity[2] = 400.0;
	
	set_pev(iPlayer, pev_velocity, vecVelocity);
}
stock make_blood(Float:origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]+random_num(15,25)))
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(248)
	write_byte(random_num(8,15))
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]+random_num(15,25)))
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(248)
	write_byte(random_num(8,15))
	message_end()
}

public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(get_user_weapon(iAttacker) == CSW_ZBS64KNIFE)
	{
		if(g_Had_Zbs64Knife[iAttacker])
			set_msg_arg_string(4, "zbs64knife")
	}
                
	return PLUGIN_CONTINUE
}
