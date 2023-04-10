#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define PLUGIN "Balrog-XI"
#define VERSION "2.0"
#define AUTHOR "Dias"
#define SUPPORT FOR ZP "Conspiracy"

#define V_MODEL "models/v_Basilisk.mdl"
#define P_MODEL "models/p_Basilisk.mdl"
#define W_MODEL "models/w_Basilisk.mdl"

new const FireSound[][] = {
	"weapons/basilisk-1.wav",
	"weapons/basilisk-2.wav"
}

#define CSW_BASILISK CSW_M3
#define weapon_BASILISK "weapon_m3"
#define OLD_W_MODEL "models/w_m3.mdl"
#define OLD_EVENT "events/m3.sc"

#define WEAPON_SECRETCODE 19821

#define	BASILISK_NAME "Basilisk Shotgun"
#define	BASILISK_COST	3000
#define BASILISK_CLIP 10
#define BASILISK_AMMO 200
#define BASILISK_SPEED 0.8
#define BASILISK_RECOIL 1.3
#define BASILISK_RELOAD 4.0
#define BASILISK_DAMAGE 1.4

// OFFSET
const PDATA_SAFE = 2
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_WEAPONOWNER = 41

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

enum
{
	ANIM_IDLE = 0,
	ANIM_SHOOT,
	ANIM_SHOOT2,
	ANIM_INSERT,
	ANIM_AFTER_RELOAD,
	ANIM_START_RELOAD,
	ANIM_DRAW
}

new g_Basilisk, g_iszModelIndexStars
new sTrail
new g_had_Basilisk[33]
new g_old_weapon[33], g_event_Basilisk, g_ham_bot

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_BASILISK, "fw_Item_AddToPlayer_Post", 1)
	
	RegisterHam(Ham_Item_Deploy, weapon_BASILISK, "fw_Item_Deploy_Post", 1)
	//RegisterHam(Ham_Weapon_Reload, weapon_BASILISK, "Reload_Post7", 1)
	
	RegisterHam(Ham_Item_PostFrame, weapon_BASILISK, "fw_Item_PostFrame")	
	RegisterHam(Ham_Item_Holster, weapon_BASILISK, "HolsterPost", 1)
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	
	g_Basilisk = zp_register_extra_item(BASILISK_NAME, BASILISK_COST, ZP_TEAM_HUMAN)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)	
	
	for(new i; i<=charsmax(FireSound); i++)
	{
		precache_sound(FireSound[i]);
	}	
	g_iszModelIndexStars = engfunc(EngFunc_PrecacheModel,  "sprites/xspark1.spr")
	
	sTrail = precache_model("sprites/lgtning.spr")
}

public client_putinserver(id)
{
	if(!g_ham_bot && is_user_bot(id))
	{
		g_ham_bot = 1
		set_task(0.1, "do_register", id)
	}
}

public do_register(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(OLD_EVENT, name))
		g_event_Basilisk = get_orig_retval()
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_Basilisk) Get_Basilisk(id)
}

public Get_Basilisk(id)
{
	drop_weapons(id, 1)
	g_had_Basilisk[id] = 1
	g_old_weapon[id] = 0
	
	fm_give_item(id, weapon_BASILISK)
	cs_set_user_bpammo(id, CSW_BASILISK, BASILISK_AMMO)
}

public Remove_Basilisk(id)
{
	g_had_Basilisk[id] = 0
	g_old_weapon[id] = 0
}
public Event_CurWeapon(id)
{
	if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
		return;
	
	if(read_data(2) != CSW_BASILISK || !g_had_Basilisk[id])
		return	
	static Float:iSpeed
	if(g_had_Basilisk[id])
	iSpeed = BASILISK_SPEED
	
	static weapon[32],Ent
	get_weaponname(read_data(2),weapon,31)
	Ent = find_ent_by_owner(-1,weapon,id)
	if(Ent)
	{
		static Float:Delay
		Delay = get_pdata_float( Ent, 46, 4) * iSpeed
		
		if (Delay > 0.0)
		{
			set_pdata_float(Ent, 46, Delay, 4)
		}
	}
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[64]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(entity, pev_owner)
	
	if(equal(model, OLD_W_MODEL))
	{
		static weapon
		weapon = fm_get_user_weapon_entity(entity, CSW_BASILISK)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_Basilisk[id])
		{
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			Remove_Basilisk(id)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_Item_AddToPlayer_Post(ent, id)
{
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		g_had_Basilisk[id] = 1
		
		set_pev(ent, pev_impulse, 0)
	}		
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_BASILISK)
		{
			if(g_had_Basilisk[attacker])
			{
				SetHamParamFloat(4, damage * BASILISK_DAMAGE)
			}
		}
	}
}
public fw_TraceAttack(Ent, Attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	if(!is_user_alive(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_BASILISK || !g_had_Basilisk[Attacker])
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3], Float:StartOrigin2[3];
	
	get_tr2(ptr, TR_vecEndPos, flEnd)
	get_tr2(ptr, TR_vecPlaneNormal, vecPlane)		
		
	if(!is_user_alive(Ent))
	{
		make_bullet(Attacker, flEnd)
	}
	
	get_position(Attacker, 25.0, 3.0, 8.0, StartOrigin2)
			
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, StartOrigin2[0])
	engfunc(EngFunc_WriteCoord, StartOrigin2[1])
	engfunc(EngFunc_WriteCoord, StartOrigin2[2] - 10.0)
	engfunc(EngFunc_WriteCoord, flEnd[0])
	engfunc(EngFunc_WriteCoord, flEnd[1])
	engfunc(EngFunc_WriteCoord, flEnd[2])
	write_short(sTrail)
	write_byte(0) // start frame
	write_byte(0) // framerate
	write_byte(5) // life
	write_byte(5) // line width
	write_byte(0) // amplitude
	write_byte(0)
	write_byte(155)
	write_byte(0) // blue
	write_byte(155) // brightness
	write_byte(0) // speed
	message_end()

	UTIL_BulletBalls(Attacker, ptr)

	SetHamParamFloat(3, 80.0)	

	return HAM_HANDLED	
}

public fw_Item_Deploy_Post(ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(ent)
	if (!pev_valid(id))
		return

	if(!g_had_Basilisk[id])
		return
		
	set_pev(id, pev_viewmodel2, V_MODEL)
	set_pev(id, pev_weaponmodel2, P_MODEL)
}

public fw_Item_PostFrame(Ent)
{
	if(!pev_valid(Ent))
		return
		
	static Id; Id = pev(Ent, pev_owner)
	if(!g_had_Basilisk[Id])
		return
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(Id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(Id, CSW_BASILISK)
	static iClip; iClip = get_pdata_int(Ent, 51, 4)

	if(get_pdata_int(Ent, 54, 4) && flNextAttack <= 0.0)
	{
		static temp1; temp1 = min(BASILISK_CLIP - iClip, bpammo)

		set_pdata_int(Ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(Id, CSW_BASILISK, bpammo - temp1)		
		
		set_pdata_int(Ent, 54, 0, 4)
	}		
}
#define CustomItem(%0) (pev(%0, pev_impulse) == WEAPON_SECRETCODE)
public Reload_Post7(ent)
{
	static id; id = get_pdata_cbase(ent, 41, 4);
	if(!CustomItem(ent)) return 
	if(!get_pdata_int(id,381,4)) return
	if(get_pdata_int(id, 363, 5) != 90)
	{
		set_pdata_int(id, 363, 90, 5);
	}
	set_pdata_float(id, 83, 0.7, 5)
	set_pdata_float(ent, 48, 0.7, 4)
	set_pdata_float(id, 46, 0.7, 5)
	set_pdata_int(ent, 55, 1, 4)
	set_weapon_anim(id, ANIM_START_RELOAD);
	static clip; clip = get_pdata_int(ent,51,5)
	static bpammo; bpammo = get_pdata_int(id,381,5)
	if(get_pdata_float(ent, 46,4) > 0.0) return 
	if(get_pdata_int(ent, 55, 4))
	{

		if(get_pdata_int(id,381,5) <= 0 || BASILISK_CLIP-1 == clip)
		set_pdata_float(id, 83, 0.7, 5)
		set_pdata_float(ent, 48, 0.7, 4)
		set_pdata_float(ent, 46, 0.7, 4)
		set_weapon_anim(id, ANIM_INSERT);
		set_pdata_int(ent, 55, 1, 4)
		if(get_pdata_float(ent, 46, 4) > 0.0)
		{
			if(clip<BASILISK_CLIP)
			{
				set_pdata_int(id, 381, bpammo-1, 5)
				set_pdata_int(ent, 51, clip+1)
			}	
		}
			
		if(clip==BASILISK_CLIP)
		{
			set_pdata_float(id, 83, 0.7, 5)
			set_pdata_float(ent, 48, 0.7, 4)
			set_pdata_float(id, 46, 0.7, 5)
			set_pdata_int(ent, 55, 0, 4)
			set_weapon_anim(id, ANIM_AFTER_RELOAD);
			return 
		}	
		return 
	}
	return 
}
public HolsterPost(wpn)
{
	static id
	id = get_pdata_cbase(wpn, 41, 4)
	if(!g_had_Basilisk[id])
		return;
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_BASILISK && g_had_Basilisk[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED		
	if(get_user_weapon(invoker) == CSW_BASILISK && g_had_Basilisk[invoker] && eventid == g_event_Basilisk)
	{
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)	

		set_weapon_anim(invoker, ANIM_SHOOT)
		emit_sound(invoker, CHAN_WEAPON, FireSound[random_num(0,1)], 1.0, ATTN_NORM, 0, PITCH_LOW)	

		return FMRES_SUPERCEDE
	}
	
	return FMRES_HANDLED
}
stock make_bullet(id, Float:Origin[3])
{
	// Find target
	new decal = random_num(41, 45)
	const loop_time = 2
	
	static Body, Target
	get_user_aiming(id, Target, Body, 999999)
	
	if(is_user_connected(Target))
		return
	
	for(new i = 0; i < loop_time; i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(decal)
		message_end()
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(id)
		write_byte(decal)
		message_end()
	}
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

stock fm_cs_get_weapon_ent_owner(ent)
{
	if (pev_valid(ent) != PDATA_SAFE)
		return -1
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, 83, nexttime, 5)
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entBASILISK_; entBASILISK_ = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entBASILISK_)) 
		return
		
	set_pdata_float(entBASILISK_, 46, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entBASILISK_, 47, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entBASILISK_, 48, TimeIdle + 0.5, OFFSET_LINUX_WEAPONS)
}

// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get weapon entity
			static wname[32]
			get_weaponname(weaponid, wname, charsmax(wname))

			// Player drops the weapon and looses his bpammo
			engclient_cmd(id, "drop", wname)
			cs_set_user_bpammo(id, weaponid, 0)
		}
	}
}
public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(get_user_weapon(iAttacker) == CSW_BASILISK)
	{
		if(g_had_Basilisk[iAttacker])
			set_msg_arg_string(4, "Basilisk")
	}
                
	return PLUGIN_CONTINUE
}
stock UTIL_BulletBalls(id, TrResult)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(TrResult, TR_vecEndPos, vecSrc)
	get_tr2(TrResult, TR_vecPlaneNormal, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
    
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_SPRITETRAIL);
	engfunc(EngFunc_WriteCoord, vecEnd[0]);
	engfunc(EngFunc_WriteCoord, vecEnd[1]);
	engfunc(EngFunc_WriteCoord, vecEnd[2]); // 20
	engfunc(EngFunc_WriteCoord, vecEnd[0]);
	engfunc(EngFunc_WriteCoord, vecEnd[1]);
	engfunc(EngFunc_WriteCoord, vecEnd[2]); // 20
	write_short(g_iszModelIndexStars);
	write_byte(1);
	write_byte(0);
	write_byte(1);
	write_byte(10);
	write_byte(10);
	message_end();
}

stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	static Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	static Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	static Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	static Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
