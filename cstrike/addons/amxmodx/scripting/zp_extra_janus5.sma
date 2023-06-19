#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>

#define ENG_NULLENT			-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define janus5_WEAPONKEY 	513342
#define MAX_PLAYERS  		32
#define WEAPON_ANIMEXT "carbine"

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4
const m_szAnimExtention = 492

#if cellbits == 32
const OFFSET_CLIPAMMO = 51
#else
const OFFSET_CLIPAMMO = 65
#endif

#define WEAP_LINUX_XTRA_OFF		4
#define m_fKnown					44
#define m_flNextPrimaryAttack 		46
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF	5
#define m_flNextAttack				83
#define janus5_READY 50
#define janus5_RELOAD_TIME	3.0

#define DAMAGE1 1.4
#define DAMAGE2 2.8

native navtive_bullet_effect(id, ent, ptr)

enum
{
	ANIM_IDLE = 0,
	ANIM_RELOAD_NORMAL,
	ANIM_DRAW_NORMAL,
	ANIM_SHOOT_NORMAL,
	ANIM_SHOOT_SIGNAL,
	ANIM_CHANGE_1,
	ANIM_IDLE_B,
	ANIM_DRAW_B,
	ANIM_SHOOT_B,
	ANIM_SHOOT_B2,
	ANIM_SHOOT_B3,
	ANIM_CHANGE_2,
	ANIM_SIGNAL,
	ANIM_RELOAD_SIGNAL,
	ANIM_DRAW_SIGNAL
}

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)
#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_Sounds[][] = { "weapons/janusmk5-12.wav" }
new const Fire_Sounds2[][] = { "weapons/janusmk5-2.wav" }

new janus5_V_MODEL[64] = "models/v_janus5.mdl"
new janus5_P_MODEL[64] = "models/p_janus5.mdl"
new janus5_W_MODEL[64] = "models/w_janus5.mdl"

new g_MaxPlayers, g_orig_event_janus5, g_IsInPrimaryAttack
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_has_janus5[33], g_clip_ammo[33], g_janus5_TmpClip[33], oldweap[33], janus5_mode[33], janus5_signal[33], siap_janus5[33]
new g_Ham_Bot, item_janus

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
public plugin_init()
{
	register_plugin("Janus-3", "1.0", "m4m3ts")
	
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	RegisterHam(Ham_Item_AddToPlayer, "weapon_galil", "fw_janus5_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Item_Deploy, "weapon_galil", "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_janus5_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_janus5_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_galil", "janus5_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_galil", "janus5_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_galil", "janus5_Reload_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_galil", "fw_janus5idleanim", 1)
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)
	
	item_janus = zp_register_extra_item("Janus-V", 4000, ZP_TEAM_HUMAN)
	register_clcmd("setmode","set_mode")
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(janus5_V_MODEL)
	precache_model(janus5_P_MODEL)
	precache_model(janus5_W_MODEL)
	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])
	for(new i = 0; i < sizeof Fire_Sounds2; i++)
	precache_sound(Fire_Sounds2[i])
	precache_sound("weapons/change1_ready.wav")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
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
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_Spawn, id, "Player_Spawn")
}
public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_GALIL) return
	
	if(!g_has_janus5[iAttacker]) return

	navtive_bullet_effect(iAttacker, iEnt, ptr)
}

public Player_Spawn(id)
{
	g_has_janus5[id] = false
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/galil.sc", name))
	{
		g_orig_event_janus5 = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_janus5[id] = false
}

public client_disconnect(id)
{
	g_has_janus5[id] = false
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_janus5[id] = false
	}
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid == item_janus) give_janus5(id)
}

public give_janus5(id)
{
	drop_weapons(id, 1)
	new iWep2 = give_item(id,"weapon_galil")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, 50)
		cs_set_user_bpammo (id, CSW_GALIL, 200)	
		UTIL_PlayWeaponAnimation(id, ANIM_DRAW_NORMAL)
		set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
	}
	g_has_janus5[id] = true
	siap_janus5[id] = 1
	janus5_mode[id] = 1
	janus5_signal[id] = 0
	update_ammo(id)
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED;
		
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[64]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(entity, pev_owner)
	
	if(equal(model, "models/w_galil.mdl"))
	{
		static weapon
		weapon = fm_get_user_weapon_entity(entity, CSW_GALIL)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_has_janus5[id])
		{
			set_pev(weapon, pev_impulse, janus5_WEAPONKEY)
			
			g_has_janus5[id] = false
			
			entity_set_model(entity, janus5_W_MODEL)
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED;	
}

public fw_janus5_AddToPlayer(janus5, id)
{
	if(pev(janus5, pev_impulse) == janus5_WEAPONKEY)
	{
		g_has_janus5[id] = true

		siap_janus5[id] = 1
		update_ammo(id)		
		set_pev(janus5, pev_impulse, 0)
	}	
}

public update_ammo(id)
{
	if(!is_user_alive(id))
		return
	
	static weapon_ent; weapon_ent = fm_get_user_weapon_entity(id, CSW_GALIL)
	if(!pev_valid(weapon_ent)) return
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_GALIL)
	write_byte(cs_get_weapon_ammo(weapon_ent))
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(1)
	write_byte(cs_get_user_bpammo(id, CSW_GALIL))
	message_end()
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if (use_type == USE_STOPPED && is_user_connected(caller))
		replace_weapon_models(caller, get_user_weapon(caller))
}

public fw_Item_Deploy_Post(weapon_ent)
{
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	
	replace_weapon_models(owner, weaponid)
}

public CurrentWeapon(id)
{
	replace_weapon_models(id, read_data(2))

	if(read_data(2) != CSW_GALIL || !g_has_janus5[id])
		return
	
	static Float:iSpeed
	if(g_has_janus5[id])
		iSpeed = 1.0
	
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

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_GALIL:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return
			
			if(g_has_janus5[id])
			{
				set_pev(id, pev_viewmodel2, janus5_V_MODEL)
				set_pev(id, pev_weaponmodel2, janus5_P_MODEL)
				if(oldweap[id] != CSW_GALIL) 
				{
					if(janus5_mode[id] == 1) UTIL_PlayWeaponAnimation(id, ANIM_DRAW_NORMAL)
					if(janus5_mode[id] == 2) UTIL_PlayWeaponAnimation(id, ANIM_DRAW_SIGNAL)
					if(janus5_mode[id] == 3) UTIL_PlayWeaponAnimation(id, ANIM_DRAW_B)
					set_pdata_string(id, m_szAnimExtention * 4, WEAPON_ANIMEXT, -1 , 20)
					set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_GALIL || !g_has_janus5[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_janus5_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_janus5[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_janus5) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_janus5_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return
	if(!g_has_janus5[Player])
		return

	if(janus5_mode[Player] != 3)
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,1.0,push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		janus5_signal[Player] ++
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		if(janus5_signal[Player] >= janus5_READY && siap_janus5[Player])
		{
			janus5_mode[Player] = 2
			emit_sound(Player, CHAN_WEAPON, "weapons/change1_ready.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			siap_janus5[Player] = 0
			if(is_user_bot(Player))
			{
				set_task(3.0,"set_mode",Player)
			}
		}
		
		if(janus5_mode[Player] == 2) UTIL_PlayWeaponAnimation(Player, ANIM_SHOOT_SIGNAL)
		else UTIL_PlayWeaponAnimation(Player, ANIM_SHOOT_NORMAL)
	}
	else
	{
		if (!g_clip_ammo[Player]) szClip = 2
		
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,0.1,push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds2[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		fm_set_weapon_ammo(Weapon, szClip++)
		
		UTIL_PlayWeaponAnimation(Player, random_num(ANIM_SHOOT_B,ANIM_SHOOT_B3))
	}
}
public set_mode(Player)
{
	if(!g_has_janus5[Player])
		return

	remove_task(Player)
	UTIL_PlayWeaponAnimation(Player, ANIM_CHANGE_1)
	//janus5_mode[id] = 3
	janus5_mode[Player] = 3
	set_weapons_timeidle(Player, CSW_GALIL, 1.7)
	set_player_nextattackx(Player, 1.7)
	set_task(20.0, "back_normal", Player)
	set_task(20.0, "back_normal2", Player)
}
public fw_janus5idleanim(Weapon)
{
	new id = get_pdata_cbase(Weapon, 41, 4)

	if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_has_janus5[id] || get_user_weapon(id) != CSW_GALIL)
		return HAM_IGNORED;

	if(janus5_mode[id] == 1) 
		return HAM_SUPERCEDE;
	
	if(janus5_mode[id] == 3 && get_pdata_float(Weapon, 48, 4) <= 0.25)
	{
		UTIL_PlayWeaponAnimation(id, ANIM_IDLE_B)
		set_pdata_float(Weapon, 48, 20.0, 4)
		return HAM_SUPERCEDE;
	}
	
	if(janus5_mode[id] == 2 && get_pdata_float(Weapon, 48, 4) <= 0.25) 
	{
		UTIL_PlayWeaponAnimation(id, ANIM_SIGNAL)
		set_pdata_float(Weapon, 48, 20.0, 4)
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	if(get_user_weapon(id) != CSW_GALIL || !g_has_janus5[id])
		return
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_GALIL)
	if(!pev_valid(ent))
		return
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)

	if(CurButton & IN_ATTACK2)
	{
		if(janus5_mode[id] == 2 && get_pdata_float(id, 83, 5) <= 0.0)
		{
			remove_task(id)
			UTIL_PlayWeaponAnimation(id, ANIM_CHANGE_1)
			janus5_mode[id] = 3
			set_weapons_timeidle(id, CSW_GALIL, 1.7)
			set_player_nextattackx(id, 1.7)
			set_task(20.0, "back_normal", id)
			set_task(20.0, "back_normal2", id)
		}
	}
}

public back_normal(id)
{
	if(get_user_weapon(id) != CSW_GALIL || !g_has_janus5[id])
		return
		
	UTIL_PlayWeaponAnimation(id, ANIM_CHANGE_2)
	set_weapons_timeidle(id, CSW_GALIL, 1.8)
	set_player_nextattackx(id, 1.8)
}

public back_normal2(id)
{
	janus5_mode[id] = 1
	janus5_signal[id] = 0
	siap_janus5[id] = 1
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_GALIL)
		{
			if(g_has_janus5[attacker])
			{
				if(janus5_mode[attacker] != 3)
				{
					SetHamParamFloat(4, damage * DAMAGE1)
				}
				else SetHamParamFloat(4, damage * DAMAGE2)
			}
		}
	}
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, "galil") && get_user_weapon(iAttacker) == CSW_GALIL)
	{
		if(g_has_janus5[iAttacker])
			set_msg_arg_string(4, "janusmk5")
	}
	return PLUGIN_CONTINUE
}

stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX)
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

public janus5_ItemPostFrame(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_janus5[id])
		return HAM_IGNORED

	static iClipExtra
	
	iClipExtra = 50
	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_GALIL)
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(iClipExtra - iClip, iBpAmmo)
	
		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, CSW_GALIL, iBpAmmo-j)
		
		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		fInReload = 0
	}
	return HAM_IGNORED
}

public janus5_Reload(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_janus5[id])
		return HAM_IGNORED

	static iClipExtra

	if(g_has_janus5[id])
		iClipExtra = 50

	g_janus5_TmpClip[id] = -1

	new iBpAmmo = cs_get_user_bpammo(id, CSW_GALIL)
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE

	if (iClip >= iClipExtra)
		return HAM_SUPERCEDE
		  
	if(janus5_mode[id] == 3)
		 return HAM_SUPERCEDE

	g_janus5_TmpClip[id] = iClip

	return HAM_IGNORED
}

public janus5_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_janus5[id])
		return HAM_IGNORED

	if (g_janus5_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_janus5_TmpClip[id], WEAP_LINUX_XTRA_OFF)
	
	set_weapons_timeidle(id, CSW_GALIL, janus5_RELOAD_TIME)
	set_player_nextattackx(id, janus5_RELOAD_TIME)
	
	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)
	
	if(janus5_mode[id] == 2) UTIL_PlayWeaponAnimation(id, ANIM_RELOAD_SIGNAL)
	else UTIL_PlayWeaponAnimation(id, ANIM_RELOAD_NORMAL)

	return HAM_IGNORED
}

stock set_player_nextattackx(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, WEAP_LINUX_XTRA_OFF)
	set_pdata_float(entwpn, 47, TimeIdle, WEAP_LINUX_XTRA_OFF)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, WEAP_LINUX_XTRA_OFF)
}

stock fm_set_weapon_ammo(entity, amount)
{
	set_pdata_int(entity, OFFSET_CLIPAMMO, amount, OFFSET_LINUX_WEAPONS);
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	
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
