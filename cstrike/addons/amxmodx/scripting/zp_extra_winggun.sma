#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <engine>
#include <toan>
#include <fun>
#include <beams>
#include <zombieplague>

#define PLUGIN "[CSO] Skull-11"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define CSW_WINGGUN CSW_M3
#define weapon_winggun "weapon_m3"
#define WEAPON_ANIMEXT "m249"
#define DEFAULT_W_MODEL "models/w_m3.mdl"
#define WEAPON_SECRET_CODE 1942
#define old_event "events/m3.sc"
#define BEAM_CLASSNAME "szBeamBoss21"

#define DAMAGE 122
#define DAMAGE_B random_float(35.0, 45.0)
#define DAMAGE_SPEC random_float(2000.0,3000.0)
#define SPEED 0.35
#define RECOIL 0.75
#define RELOAD_TIME 100/30.0
#define DEFAULT_CLIP 28
#define DEFAULT_BPAMMO 180
#define SECOND_MODE_RADIUS 250.0
#define WEAPON_MAX_ENERGY 100
#define ZP_WEAPON_ENERGY_NEW 0.2

new const WeaponModel[3][] =
{
	"models/v_winggun.mdl", // V
	"models/p_winggun.mdl", // P
	"models/w_winggun.mdl" // W
}

new const WEAPON_MODELS[][] =
{
	"sprites/ef_winggun_explosion.spr", //0
	"sprites/ef_winggun_laserbeam.spr", //1
	"sprites/ef_winggun_particle.spr", //2
	"sprites/ef_winggun_ring.spr", //3
	"sprites/ef_winggun_star.spr" //4
}
new const WeaponSound[6][] =
{
	"weapons/winggun_shoot1.wav",
	"weapons/winggun_shoot2.wav",
	"weapons/winggun_wingstart.wav",
	"weapons/winggun_wingend.wav",
	"weapons/winggun_loop.wav",
	"weapons/winggun_special_on.wav"
}

#define WEAPON_ANIM_IDLE 0
#define WEAPON_ANIM_SHOOT random_num(1, 2)
#define WEAPON_ANIM_RELOAD 3
#define WEAPON_ANIM_IDLE_B 4
#define WEAPON_ANIM_DRAW 5
#define WEAPON_ANIM_START_B 6
#define WEAPON_ANIM_LOOP_B 7
#define WEAPON_ANIM_SHOOT_B random_num(8, 9)
#define WEAPON_ANIM_RELOAD_B 10
#define WEAPON_ANIM_END_B 11
#define WEAPON_ANIM_SHOT_SPEC 12

const PDATA_SAFE = 2
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_LINUX_PLAYER = 5
const OFFSET_WEAPONOWNER = 41
const m_iClip = 51
const m_fInReload = 54
const m_flNextAttack = 83
const m_szAnimExtention = 492
const m_flTimeWeaponIdle = 48

new g_Winggun, g_iszModelIndexStars, g_DivineMode[33], gl_hitID, g_ChargeBullets[33], g_SpecShot_Exp, g_SpecShot[33]
new g_had_winggun[33], Float:g_punchangles[33][3], g_winggun_event, g_smokepuff_id, m_iBlood[2], g_ham_bot


// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))


public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")		
	
	RegisterHam(Ham_Item_Deploy, weapon_winggun, "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_Reload, weapon_winggun, "fw_Weapon_Reload_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_winggun, "fw_Weapon_Idle_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_winggun, "fw_Item_PostFrame")
	RegisterHam(Ham_Item_AddToPlayer, weapon_winggun, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_winggun, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_winggun, "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Think, "beam", "CWeapon__Think_Beam", true);

	g_Winggun = zp_register_extra_item("Divine Blaster", 35000, ZP_TEAM_HUMAN) 
}

public plugin_precache()
{
	new i
	
	for(i = 0; i < sizeof(WeaponModel); i++)
		engfunc(EngFunc_PrecacheModel, WeaponModel[i])
	for(i = 0; i < sizeof(WeaponSound); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSound[i])

	engfunc(EngFunc_PrecacheModel, WEAPON_MODELS[1]);
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	m_iBlood[0] = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr")
	m_iBlood[1] = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr")		
	
	g_iszModelIndexStars = engfunc(EngFunc_PrecacheModel, WEAPON_MODELS[4])
	gl_hitID = engfunc(EngFunc_PrecacheModel, WEAPON_MODELS[2]);
	g_SpecShot_Exp = engfunc(EngFunc_PrecacheModel, WEAPON_MODELS[0]);

	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)	
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(old_event, name))
		g_winggun_event = get_orig_retval()
}

public client_putinserver(id)
{
	if(is_user_bot(id) && !g_ham_bot)
	{
		g_ham_bot = 1
		set_task(0.1, "Do_Register_Ham", id)
	}
}

public Do_Register_Ham(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")	
}

public zp_extra_item_selected(id, itemid) 
{ 
	if(itemid == g_Winggun) get_winggun(id) 
} 
public zp_user_infected_post(id) 
{ 
	remove_winggun(id) 
} 
public get_winggun(id)
{
	g_had_winggun[id] = 1
	g_DivineMode[id] = 0
	drop_weapons(id, 1)
	give_item(id, weapon_winggun)
	
	// Set Clip
	static ent; ent = fm_get_user_weapon_entity(id, CSW_WINGGUN)
	if(pev_valid(ent)) cs_set_weapon_ammo(ent, DEFAULT_CLIP)
	
	// Set BpAmmo
	cs_set_user_bpammo(id, CSW_WINGGUN, DEFAULT_BPAMMO)
	
	// Update Ammo
	g_ChargeBullets[id] = 20
	SetExtraAmmo(id, 0);
	update_ammo(id, CSW_WINGGUN, DEFAULT_CLIP, DEFAULT_BPAMMO)
}

public remove_winggun(id)
{
	g_had_winggun[id] = 0
	g_DivineMode[id] = 0
	
	g_ChargeBullets[id] = 0
	g_SpecShot[id] = 0
	UTIL_StatusIcon(id, 0)
}

public hook_weapon(id)
{
	client_cmd(id, weapon_winggun)
	return PLUGIN_HANDLED
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, "m3") && get_user_weapon(iAttacker) == CSW_WINGGUN)
	{
		if(g_had_winggun[iAttacker])
			set_msg_arg_string(4, "winggun")
	}
	return PLUGIN_CONTINUE
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_WINGGUN || !g_had_winggun[id])
		return
		
	// Speed
	static ent; ent = fm_get_user_weapon_entity(id, CSW_WINGGUN)
	if(!pev_valid(ent)) 
		return
		
	set_pdata_float(ent, 46, get_pdata_float(ent, 46, OFFSET_LINUX_WEAPONS) * SPEED, OFFSET_LINUX_WEAPONS)
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_WINGGUN || !g_had_winggun[id])
		return 

	static ent; ent = fm_get_user_weapon_entity(id, CSW_WINGGUN)
	if(!pev_valid(ent)) 
		return

	static CurButton; CurButton = get_uc(uc_handle, UC_Buttons)
	
	static Float:changeTime
	pev(ent, pev_fuser3, changeTime)
	if(CurButton & IN_ATTACK2  && get_gametime() >= changeTime + 0.5){
		set_pev(ent, pev_fuser3, get_gametime() + 31/30.0)
		if(!g_DivineMode[id]){
			set_weapon_anim(id, WEAPON_ANIM_START_B)
			set_weapons_timeidle(id, CSW_WINGGUN, 31/30.0)
			
			set_task(31/30.0,"setDivineMode",id)
		}else{
			if(g_SpecShot[id]>=20){
				create_beam_shoot(ent, id);
			}
			set_weapon_anim(id, WEAPON_ANIM_END_B)
			set_weapons_timeidle(id, CSW_WINGGUN, 31/30.0)

			static Float:push[3]
			pev(id, pev_punchangle, push)
			xs_vec_sub(push, g_punchangles[id], push)
			
			xs_vec_mul_scalar(push, 5.0, push)
			xs_vec_add(push, g_punchangles[id], push)
			set_pev(id, pev_punchangle, push)	

			g_DivineMode[id] = false
			set_task(31/30.0,"unsetDivineMode",id)
		}
		
		//create_beam_shoot(ent, id);
	}
	if(CurButton & IN_RELOAD)
	{
		CurButton &= ~IN_RELOAD
		set_uc(uc_handle, UC_Buttons, CurButton)
		
		static ent; ent = fm_get_user_weapon_entity(id, CSW_WINGGUN)
		if(!pev_valid(ent)) return
		
		static fInReload; fInReload = get_pdata_int(ent, m_fInReload, OFFSET_LINUX_WEAPONS)
		static Float:flNextAttack; flNextAttack = get_pdata_float(id, m_flNextAttack, OFFSET_LINUX_PLAYER)
		
		if (flNextAttack > 0.0)
			return
			
		if (fInReload)
		{
			set_weapon_anim(id, g_DivineMode[id]?WEAPON_ANIM_LOOP_B:WEAPON_ANIM_IDLE)
			return
		}
		
		if(cs_get_weapon_ammo(ent) >= DEFAULT_CLIP)
		{
			set_weapon_anim(id, g_DivineMode[id]?WEAPON_ANIM_LOOP_B:WEAPON_ANIM_IDLE)
			return
		}
			
		fw_Weapon_Reload_Post(ent)
	}
}
public setDivineMode(id){
	if(!is_user_alive(id) || zp_get_user_zombie(id))
		return

	g_DivineMode[id] = true
}
public unsetDivineMode(id){
	if(!is_user_alive(id) || zp_get_user_zombie(id))
		return

	UTIL_StatusIcon(id, 0)
	g_SpecShot[id] = 0
}
public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	pev(entity, pev_classname, szClassName, charsmax(szClassName))
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(entity, pev_owner)
	
	if(equal(model, DEFAULT_W_MODEL))
	{
		static weapon
		weapon = fm_find_ent_by_owner(-1, weapon_winggun, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_winggun[id])
		{
			set_pev(weapon, pev_impulse, WEAPON_SECRET_CODE)
			engfunc(EngFunc_SetModel, entity, WeaponModel[2])
			
			remove_winggun(id)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}

public fw_TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker))
		return HAM_IGNORED	
	if(get_user_weapon(attacker) != CSW_WINGGUN || !g_had_winggun[attacker])
		return HAM_IGNORED
		
	if(!is_user_alive(ent))
	{
		static Float:flEnd[3], Float:vecPlane[3]
	
		get_tr2(ptr, TR_vecEndPos, flEnd)
		get_tr2(ptr, TR_vecPlaneNormal, vecPlane)	

		make_bullet(attacker, flEnd)
		UTIL_BulletBalls(attacker, ptr)
	}
		
	SetHamParamFloat(3, float(DAMAGE) / 6.0)	

	return HAM_HANDLED
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_WINGGUN || !g_had_winggun[id])
		return FMRES_IGNORED
		
	set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if(!is_user_connected(invoker))
		return FMRES_IGNORED	
		
	if(get_user_weapon(invoker) == CSW_WINGGUN && g_had_winggun[invoker] && eventid == g_winggun_event)
	{
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
		Event_Winggun_Shoot(invoker)	

		return FMRES_SUPERCEDE
	}
	
	return FMRES_HANDLED
}

public fw_Item_Deploy_Post(ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(ent)
	if (!pev_valid(id))
		return

	static weaponid
	weaponid = cs_get_weapon_id(ent)

	if(weaponid != CSW_WINGGUN)
		return
	if(!g_had_winggun[id])
		return
		
	set_pev(id, pev_viewmodel2, WeaponModel[0])
	set_pev(id, pev_weaponmodel2, WeaponModel[1])

	SetExtraAmmo(id, g_ChargeBullets[id]);

	set_weapon_anim(id, WEAPON_ANIM_DRAW)
	set_pdata_float(ent, 48, 31.0/30,OFFSET_LINUX_WEAPONS)
	set_pdata_string(id, m_szAnimExtention * 4, WEAPON_ANIMEXT, -1 , 20)
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)

	if(g_had_winggun[id])
	{
		static CurBpAmmo; CurBpAmmo = cs_get_user_bpammo(id, CSW_WINGGUN)
		
		if(CurBpAmmo  <= 0)
			return HAM_IGNORED

		set_pdata_int(ent, 55, 0, OFFSET_LINUX_WEAPONS)
		set_pdata_float(id, 83, RELOAD_TIME, OFFSET_LINUX_PLAYER)
		set_pdata_float(ent, 48, RELOAD_TIME + 0.5, OFFSET_LINUX_WEAPONS)
		set_pdata_float(ent, 46, RELOAD_TIME + 0.25, OFFSET_LINUX_WEAPONS)
		set_pdata_float(ent, 47, RELOAD_TIME + 0.25, OFFSET_LINUX_WEAPONS)
		set_pdata_int(ent, m_fInReload, 1, OFFSET_LINUX_WEAPONS)
		
		set_weapon_anim(id, g_DivineMode[id]?WEAPON_ANIM_RELOAD_B:WEAPON_ANIM_RELOAD)			
		
		return HAM_HANDLED
	}
	
	return HAM_IGNORED	
}

public fw_Weapon_Idle_Post(Weapon){
	static id; id = pev(Weapon, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_had_winggun[id])
		return HAM_IGNORED
				
	if(get_pdata_float(Weapon, 48, 4) <= 0.1 && g_DivineMode[id]) 
	{
		set_weapon_anim(id, WEAPON_ANIM_LOOP_B)
		set_pdata_float(Weapon, 48, 121.0/30,OFFSET_LINUX_WEAPONS)
	}
	
	return HAM_IGNORED
}
public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!g_had_winggun[id]) return

	static iBpAmmo ; iBpAmmo = get_pdata_int(id, 381, OFFSET_LINUX_PLAYER)
	static iClip ; iClip = get_pdata_int(ent, m_iClip, OFFSET_LINUX_WEAPONS)
	static iMaxClip ; iMaxClip = DEFAULT_CLIP

	if(get_pdata_int(ent, m_fInReload, OFFSET_LINUX_WEAPONS) && get_pdata_float(id, m_flNextAttack, OFFSET_LINUX_PLAYER) <= 0.0)
	{
		static j; j = min(iMaxClip - iClip, iBpAmmo)
		set_pdata_int(ent, m_iClip, iClip + j, OFFSET_LINUX_WEAPONS)
		set_pdata_int(id, 381, iBpAmmo-j, OFFSET_LINUX_PLAYER)
		
		set_pdata_int(ent, m_fInReload, 0, OFFSET_LINUX_WEAPONS)
		cs_set_weapon_ammo(ent, DEFAULT_CLIP)
	
		update_ammo(id, CSW_WINGGUN, cs_get_weapon_ammo(ent), cs_get_user_bpammo(id, CSW_WINGGUN))
	}

	static Float:fTimeNewEn
	pev(ent, pev_fuser1, fTimeNewEn)
	if(get_gametime() >= fTimeNewEn)
	{	
		if(g_ChargeBullets[id] < WEAPON_MAX_ENERGY)
		{
			if(!g_DivineMode[id])
			{
				g_ChargeBullets[id] ++;
				SetExtraAmmo(id, g_ChargeBullets[id]);
				if(g_ChargeBullets[id] == WEAPON_MAX_ENERGY&&get_pdata_int(ent, m_fInReload, OFFSET_LINUX_WEAPONS) == 0)
				{
					set_pdata_float(ent, m_flTimeWeaponIdle, 0.0, OFFSET_LINUX_WEAPONS);
				}
				set_pev(ent, pev_fuser1, get_gametime()+ZP_WEAPON_ENERGY_NEW);		
			}
		}
		
		if(g_DivineMode[id])
		{
			if(g_ChargeBullets[id])
			{
				g_ChargeBullets[id] --;
				g_SpecShot[id]++;
				if(g_SpecShot[id]>=30)
					UTIL_StatusIcon(id, 1)
				SetExtraAmmo(id, g_ChargeBullets[id]);
				set_pev(ent, pev_fuser1, get_gametime()+ZP_WEAPON_ENERGY_NEW);
			}
		}

	}

	//client_print(id, print_chat , "Power: %d, Spec: %d", g_ChargeBullets[id], g_SpecShot[id])

	static Float:fTimeHitEffect
	pev(ent, pev_fuser4, fTimeHitEffect)
	if(g_DivineMode[id] && get_gametime() >= fTimeHitEffect){
		set_pev(ent, pev_fuser4, get_gametime()+0.3)

		new a = FM_NULLENT, Float:Org[3];pev(id, pev_origin, Org)
		while((a = find_ent_in_sphere(a, Org, SECOND_MODE_RADIUS)) != 0)
		{
			if (id == a)
					continue 
			if (!pev_valid(a))
					continue;
			if (!is_user_alive(a))
					continue;
			if (!zp_get_user_zombie(a))
					continue;
			if(!can_see_fm(id, a))
					continue;

			new Float:Target[3];
			pev(a, pev_origin, Target)

			new TargetO[3];
			get_user_origin(a, TargetO, 0)

			if(pev(a, pev_takedamage) != DAMAGE_NO)
			{
					new Float:TargetO_[3]
					TargetO_[0] = float(TargetO[0])
					TargetO_[1] = float(TargetO[1])
					TargetO_[2] = float(TargetO[2])

					message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
					write_byte(TE_EXPLOSION)
					engfunc(EngFunc_WriteCoord, TargetO_[0])
					engfunc(EngFunc_WriteCoord, TargetO_[1])
					engfunc(EngFunc_WriteCoord, TargetO_[2])
					write_short(gl_hitID)
					write_byte(4)
					write_byte(60)
					write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
					message_end()

					create_blood(TargetO_)
					ExecuteHamB(Ham_TakeDamage, a, id, id, is_deadlyshot(id)?DAMAGE_B*1.5:DAMAGE_B, DMG_BULLET)
			}
		}

		if(g_ChargeBullets[id] <= 0){
			if(g_SpecShot[id]>=20){
				//client_print(id, print_chat , "Power: %d, Spec: %d", g_ChargeBullets[id], g_SpecShot[id])
				create_beam_shoot(ent, id);
			}

			set_weapon_anim(id, WEAPON_ANIM_END_B)
			set_weapons_timeidle(id, CSW_WINGGUN, 31/30.0)

			static Float:push[3]
			pev(id, pev_punchangle, push)
			xs_vec_sub(push, g_punchangles[id], push)
			
			xs_vec_mul_scalar(push, 5.0, push)
			xs_vec_add(push, g_punchangles[id], push)
			set_pev(id, pev_punchangle, push)	

			g_DivineMode[id] = false
			set_task(31/30.0,"unsetDivineMode",id)
		}
	}
}

public fw_Item_AddToPlayer_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	if(pev(ent, pev_impulse) == WEAPON_SECRET_CODE)
	{
		remove_winggun(id)
		g_had_winggun[id] = 1
		
		update_ammo(id, CSW_WINGGUN, cs_get_weapon_ammo(ent), cs_get_user_bpammo(id, CSW_WINGGUN))
	}
	
	return HAM_IGNORED
}

public fw_Weapon_PrimaryAttack(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!g_had_winggun[id])
		return
		
	pev(id, pev_punchangle, g_punchangles[id])
}

public fw_Weapon_PrimaryAttack_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!g_had_winggun[id])
		return
		
	static Float:push[3]
	pev(id, pev_punchangle, push)
	xs_vec_sub(push, g_punchangles[id], push)
	
	xs_vec_mul_scalar(push, RECOIL, push)
	xs_vec_add(push, g_punchangles[id], push)
	set_pev(id, pev_punchangle, push)	
}

public CWeapon__Think_Beam(iSprite)
{
    if (!pev_valid(iSprite))
    {
        return HAM_IGNORED;
    }
    static Float:amt; pev(iSprite, pev_renderamt, amt)
    amt -= 5.0
    set_pev(iSprite, pev_renderamt, amt)
    set_pev(iSprite, pev_nextthink, get_gametime() + 0.005);
    if(amt <= 0.0) 
    {
        set_pev(iSprite, pev_flags, pev(iSprite,pev_flags) | FL_KILLME)
    }
    return HAM_SUPERCEDE;
}

public update_ammo(id, csw_id, clip, bpammo)
{
	if(!is_user_alive(id))
		return
		
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), _, id)
	write_byte(1)
	write_byte(csw_id)
	write_byte(clip)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(3)
	write_byte(bpammo)
	message_end()
}

public Event_Winggun_Shoot(id)
{
	set_weapon_anim(id, g_DivineMode[id]?WEAPON_ANIM_SHOOT_B:WEAPON_ANIM_SHOOT)

	static ent; ent = fm_get_user_weapon_entity(id, CSW_WINGGUN)
	set_pdata_float(ent, 48, 31.0/30,OFFSET_LINUX_WEAPONS)

	emit_sound(id, CHAN_WEAPON, WeaponSound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	if (pev_valid(ent) != PDATA_SAFE)
		return -1
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
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

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	
	const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		
		if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
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

public fake_smoke(id, trace_result)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
	
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(trace_result, TR_vecEndPos, vecSrc)
	get_tr2(trace_result, TR_vecPlaneNormal, vecEnd)
	
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0)
	write_short(g_smokepuff_id)
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()
}

stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	new Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	new Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	new Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	new Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}

stock create_blood(const Float:origin[3])
{
	// Show some blood :)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(75)
	write_byte(5)
	message_end()
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
	write_byte(2);
	write_byte(0);
	write_byte(1);
	write_byte(20);
	write_byte(10);
	message_end();
}
public bool:can_see_fm(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false;

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags);
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false;
		}

		new Float:lookerOrig[3];
		new Float:targetBaseOrig[3];
		new Float:targetOrig[3];
		new Float:temp[3];

		pev(entindex1, pev_origin, lookerOrig);
		pev(entindex1, pev_view_ofs, temp);
		lookerOrig[0] += temp[0];
		lookerOrig[1] += temp[1];
		lookerOrig[2] += temp[2];

		pev(entindex2, pev_origin, targetBaseOrig);
		pev(entindex2, pev_view_ofs, temp);
		targetOrig[0] = targetBaseOrig [0] + temp[0];
		targetOrig[1] = targetBaseOrig [1] + temp[1];
		targetOrig[2] = targetBaseOrig [2] + temp[2];

		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0);//  checks the had of seen player
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		{
			return false;
		} 
		else 
		{
			new Float:flFraction;
			get_tr2(0, TraceResult:TR_flFraction, flFraction);
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
					return true;
			}
			else
			{
					targetOrig[0] = targetBaseOrig [0];
					targetOrig[1] = targetBaseOrig [1];
					targetOrig[2] = targetBaseOrig [2];
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0); //  checks the body of seen player		skype:paska2000701(Planeshift)
					get_tr2(0, TraceResult:TR_flFraction, flFraction);
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					{
						return true;
					}
					else
					{
						targetOrig[0] = targetBaseOrig [0];
						targetOrig[1] = targetBaseOrig [1];
						targetOrig[2] = targetBaseOrig [2] - 17.0;
						engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0); //  checks the legs of seen player
						get_tr2(0, TraceResult:TR_flFraction, flFraction);
						if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
						{
							return true;
						}
					}
			}
		}
	}
	return false;
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

stock SetExtraAmmo(id, iClip)
{
	message_begin(MSG_ONE, get_user_msgid("AmmoX"), { 0, 0, 0 }, id);
	write_byte(1);
	write_byte(iClip);
	message_end();
}

public create_beam_shoot(iItem,iPlayer)
{
	static Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);		
	get_weapon_position(iPlayer, vecOrigin, 18.0, 0.0, -5.0)
	
	static Float:vecLook[3];
	
	fm_get_aim_origin(iPlayer, vecLook)
	Weapon_DrawBeam2(iPlayer, vecLook)
	
	set_weapon_anim(iPlayer, WEAPON_ANIM_SHOT_SPEC)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION); // TE
	engfunc(EngFunc_WriteCoord, vecLook[0]); // Position X
	engfunc(EngFunc_WriteCoord, vecLook[1]); // Position Y
	engfunc(EngFunc_WriteCoord, vecLook[2]-10.0); // Position Z
	write_short(g_SpecShot_Exp); // Model Index
	write_byte(10); // Scale
	write_byte(25); // Framerate
	write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES); // Flags
	message_end();
	static iVictim;iVictim = FM_NULLENT;			
	
	// Some shot code here now
	while((iVictim = find_ent_in_sphere(iVictim, vecLook, 100.0)) > 0)
	{
		if(pev(iVictim, pev_takedamage) == DAMAGE_NO) continue;
		static classnameptd[32]; pev(iVictim, pev_classname, classnameptd, 31);
		if (equali(classnameptd, "func_breakable")) 
		{
			ExecuteHamB(Ham_TakeDamage, iVictim, 0, 0, 250.0, DMG_GENERIC);
		}
		if(is_user_connected(iVictim) && is_user_alive(iVictim))
		{
			if(iVictim == iPlayer ) continue;
			static Float:OrigVictim[3];
			pev(iVictim, pev_origin, OrigVictim)
			create_blood(OrigVictim);
			ExecuteHamB(Ham_TakeDamage, iVictim, iPlayer, iPlayer, is_deadlyshot(iPlayer)?DAMAGE_SPEC*1.5:DAMAGE_SPEC, DMG_GENERIC);
		}
	}

	emit_sound(iPlayer, CHAN_WEAPON, WeaponSound[1], 1.0, ATTN_NORM, 0, PITCH_NORM)

}

stock get_weapon_position(id, Float:fOrigin[], Float:add_forward = 0.0, Float:add_right = 0.0, Float:add_up = 0.0)
{
	static Float:Angles[3],Float:ViewOfs[3], Float:vAngles[3]
	static Float:Forward[3], Float:Right[3], Float:Up[3]
	
	pev(id, pev_v_angle, vAngles)
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, ViewOfs)
	xs_vec_add(fOrigin, ViewOfs, fOrigin)
	
	pev(id, pev_angles, Angles)
	
	Angles[0] = vAngles[0]
	
	engfunc(EngFunc_MakeVectors, Angles)
	
	global_get(glb_v_forward, Forward)
	global_get(glb_v_right, Right)
	global_get(glb_v_up, Up)
	
	xs_vec_mul_scalar(Forward, add_forward, Forward)
	xs_vec_mul_scalar(Right, add_right, Right)
	xs_vec_mul_scalar(Up, add_up, Up)
	
	fOrigin[0] = fOrigin[0] + Forward[0] + Right[0] + Up[0]
	fOrigin[1] = fOrigin[1] + Forward[1] + Right[1] + Up[1]
	fOrigin[2] = fOrigin[2] + Forward[2] + Right[2] + Up[2]
}

stock Weapon_DrawBeam2(iPlayer, Float: vecEnd[3])
{
	static iBeamEntity, iszAllocStringCached; 
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "beam"))) 
	{ 
		iBeamEntity = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached); 
	} 
	if(!pev_valid(iBeamEntity)) return FM_NULLENT;
	set_pev(iBeamEntity, pev_flags, pev(iBeamEntity, pev_flags) | FL_CUSTOMENTITY); 
	set_pev(iBeamEntity, pev_rendercolor, Float: {255.0, 255.0, 255.0}) 
	set_pev(iBeamEntity, pev_renderamt, 255.0) 
	set_pev(iBeamEntity, pev_body, 0) 
	set_pev(iBeamEntity, pev_frame, 0.0) 
	set_pev(iBeamEntity, pev_animtime, 0.0) 
	set_pev(iBeamEntity, pev_scale, 120.0) 
		
	engfunc(EngFunc_SetModel, iBeamEntity, WEAPON_MODELS[1]); 
		
	set_pev(iBeamEntity, pev_skin, 0); 
	set_pev(iBeamEntity, pev_sequence, 0); 
	set_pev(iBeamEntity, pev_rendermode, 0);	

	static Float:Origp[3];
	get_weapon_position(iPlayer, Origp, 17.0, 0.0, -5.0)

	set_pev(iBeamEntity, pev_rendermode, (pev(iBeamEntity, pev_rendermode) & 0xF0) | BEAM_POINTS & 0x0F) 
	set_pev(iBeamEntity, pev_origin, vecEnd)  
	set_pev(iBeamEntity, pev_angles, Origp) 
	set_pev(iBeamEntity, pev_sequence, (pev(iBeamEntity, pev_sequence) & 0x0FFF) | ((0 & 0xF) << 12)) 
	set_pev(iBeamEntity, pev_skin, (pev(iBeamEntity, pev_skin) & 0x0FFF) | ((0 & 0xF) << 12)) 
	Beam_RelinkBeam(iBeamEntity);
	
	set_pev(iBeamEntity, pev_skin, (pev(iBeamEntity, pev_skin) & 0x0FFF) | ((0 & 0xF) << 12)) 
	set_pev(iBeamEntity, pev_sequence, (pev(iBeamEntity, pev_sequence) & 0x0FFF) | ((0 & 0xF) << 12))
	set_pev(iBeamEntity, pev_renderamt, 255.0) 
	set_pev(iBeamEntity, pev_animtime, 40.0) 
	set_pev(iBeamEntity, pev_rendercolor, {200.0, 200.0, 200.0}) 
	set_pev(iBeamEntity, pev_body, 0) 
	
	set_pev(iBeamEntity, pev_nextthink, get_gametime() + 0.3);
	set_pev(iBeamEntity, pev_classname, BEAM_CLASSNAME);
	set_pev(iBeamEntity, pev_owner, iPlayer);
	return iBeamEntity;
}

stock UTIL_StatusIcon(id, iUpdateMode)
{
	message_begin(MSG_ONE, get_user_msgid("StatusIcon"), { 0, 0, 0 }, id);
	write_byte(iUpdateMode ? 1 : 0);
	write_string("number_1"); 
	write_byte(255);
	write_byte(0); 
	write_byte(255);
	message_end();
}
