#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>

#define DAMAGE 2.0

#define ENG_NULLENT		-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define WEAPONKEY 33
#define MAX_PLAYERS					32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)
#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)
const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4
#define WEAP_LINUX_XTRA_OFF			4
#define m_fKnown				44
#define m_flNextPrimaryAttack 			46
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF			5
#define m_flNextAttack				83
#define RELOAD_TIME 5.0
#define wId CSW_M249
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const Fire_snd[] = {"weapons/m134ex-1.wav"}
new const went[] ={"weapon_m249"}

new m134ex_V_MODEL[64] = "models/v_m134ex.mdl"
new m134ex_P_MODEL[64] = "models/p_m134ex.mdl"
new m134ex_W_MODEL[64] = "models/w_m134ex.mdl"
new g_itemid_m134ex
new g_has_m134ex[33]
new g_MaxPlayers, g_orig_event_m134ex, g_clip_ammo[33]
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_m134ex_TmpClip[33]
new g_bot,g_can[33]

native navtive_bullet_effect(id, ent, ptr)

public plugin_init()
{
	register_plugin("[ZP]Weapon Generator", "1.0", "Crock / =)")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, went, "fw_m134ex_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Item_Deploy, went, "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, went, "fw_m134ex_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, went, "fw_m134ex_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, went, "m134ex__ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, went, "m134ex__Reload");
	RegisterHam(Ham_Weapon_Reload, went, "m134ex__Reload_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "worldspawn", "TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart")	
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	
	g_itemid_m134ex = zp_register_extra_item("M134 Predator", 3000, ZP_TEAM_HUMAN)
	g_MaxPlayers = get_maxplayers()
}
public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
				
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
				
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
				
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
				
	if(get_user_weapon(iAttacker) == wId)
	{
		if(g_has_m134ex[iAttacker])
			set_msg_arg_string(4, "m134ex")
	}
								
	return PLUGIN_CONTINUE
}

public plugin_precache()
{
	precache_model(m134ex_V_MODEL)
	precache_model(m134ex_P_MODEL)
	precache_model(m134ex_W_MODEL)
	precache_sound(Fire_snd)
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
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
	RegisterHamFromEntity(Ham_Spawn, id, "Player_Spawn")
}
public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/m249.sc", name))
	{
		g_orig_event_m134ex = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_m134ex[id] = false
}
public client_disconnect(id)
{
	g_has_m134ex[id] = false
}public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_m134ex[id] = false
	}
}
public Player_Spawn(id)
{
	g_has_m134ex[id] = false
}
public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED;
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED;
	static iOwner
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	if(equal(model, "models/w_m249.mdl"))
	{
		static iStoredSVDID
		iStoredSVDID = find_ent_by_owner(ENG_NULLENT, went, entity)
		if(!is_valid_ent(iStoredSVDID))
			return FMRES_IGNORED;
		if(g_has_m134ex[iOwner])
		{
			entity_set_int(iStoredSVDID, EV_INT_WEAPONKEY, WEAPONKEY)
			g_has_m134ex[iOwner] = false
			entity_set_model(entity, m134ex_W_MODEL)
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}
public give_m134ex(id)
{
	drop_weapons(id, 1);
	new iWep2 = give_item(id,went)
	if( iWep2 > 0 )
	{
	cs_set_weapon_ammo(iWep2, 200)
	cs_set_user_bpammo (id, wId, 200)
	}
	g_has_m134ex[id] = true;
}
public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_itemid_m134ex)
	{
	give_m134ex(id)
	}
}
public fw_m134ex_AddToPlayer(m134ex, id)
{
	if(!is_valid_ent(m134ex) || !is_user_connected(id))
		return HAM_IGNORED;
	if(entity_get_int(m134ex, EV_INT_WEAPONKEY) == WEAPONKEY)
	{
		g_has_m134ex[id] = true
		entity_set_int(m134ex, EV_INT_WEAPONKEY, 0)
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
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
	if(!is_user_alive(owner) || (get_user_weapon(owner) != wId) || !g_has_m134ex[owner])
		return
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	replace_weapon_models(owner, weaponid)
	UTIL_PlayWeaponAnimation(owner, 4)
	set_pdata_float(owner, m_flNextAttack, 1.5, PLAYER_LINUX_XTRA_OFF)
	g_can[owner] = 0
}
public CurrentWeapon(id)
{
	static Float:iSpeed
	if(g_has_m134ex[id])
	{
		iSpeed = 0.6
		
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
	replace_weapon_models(id, read_data(2))
}
replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case wId:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return;
			if(g_has_m134ex[id])
			{
				set_pev(id, pev_viewmodel2, m134ex_V_MODEL)
				set_pev(id, pev_weaponmodel2, m134ex_P_MODEL)		
			}
		}
	}
}
public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != wId) || !g_has_m134ex[Player])
	return FMRES_IGNORED
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public user_can(id) 
{
	g_can[id] = 2
}

public user_can2(id) 
{
	g_can[id] = 0
}
public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id) || get_user_weapon(id) != CSW_M249 || !g_has_m134ex[id]) 
		return PLUGIN_HANDLED

	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	if(flNextAttack > 0.0)
		return PLUGIN_HANDLED

	new szClip, szAmmo
	get_user_weapon(id, szClip, szAmmo)
	new Float:shoottime = 1.1
	
	if(is_user_bot(id))
		shoottime = 0.0

	if(szClip <= 0)
		return PLUGIN_HANDLED

	if(!(pev(id, pev_oldbuttons) & IN_ATTACK))
	{
		remove_task(id)
		set_pdata_float(id, m_flNextAttack, 0.0, PLAYER_LINUX_XTRA_OFF)
		g_can[id] = 0
	}
	if((pev(id, pev_oldbuttons) & IN_ATTACK) && !(get_uc(uc_handle, UC_Buttons) & IN_ATTACK))
	{
		remove_task(id)
		set_task(shoottime,"user_can2",id)
		g_can[id] = 3
		set_pdata_float(id, m_flNextAttack, shoottime, PLAYER_LINUX_XTRA_OFF)
		UTIL_PlayWeaponAnimation(id,6)
		g_can[id] = 0
	}
	return PLUGIN_HANDLED
}

public fw_m134ex_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_m134ex[Player])
		return HAM_IGNORED

	new Float:flNextAttack = get_pdata_float(Player, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	if(flNextAttack > 0.0)
		return HAM_IGNORED

	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)

	new Float:shoottime = 1.1
	
	if(is_user_bot(Player))
		shoottime = 0.0
		
	if(!g_can[Player] || g_can[Player] == 3)
	{
		if(szClip <= 0)
		{
			UTIL_PlayWeaponAnimation(Player,6)
			set_pdata_float(Player, m_flNextAttack, shoottime, PLAYER_LINUX_XTRA_OFF)
			return HAM_SUPERCEDE
		}
		set_task(shoottime,"user_can",Player)
		g_can[Player] = 1
		set_pdata_float(Player, m_flNextAttack, shoottime, PLAYER_LINUX_XTRA_OFF)
		UTIL_PlayWeaponAnimation(Player,5)
		
		return HAM_SUPERCEDE
	}
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)

	return HAM_IGNORED
}
public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_m134ex))
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
		return FMRES_IGNORED
	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}
public fw_m134ex_PrimaryAttack_Post(Weapon)
{	
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(!is_user_alive(Player))
		return

	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)

	if(g_has_m134ex[Player])
	{
		if(g_can[Player] != 2)
			return

		if(szClip <= 0)
		{
			UTIL_PlayWeaponAnimation(Player,5)
			set_pdata_float(Player, m_flNextAttack, 1.1, PLAYER_LINUX_XTRA_OFF)
		}

		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		xs_vec_mul_scalar(push,0.5,push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		emit_sound(Player, CHAN_WEAPON, Fire_snd[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, random_num(1,2))
		//ScreenShake(Player)
	}
}

public TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker))
		return
		
	new g_currentweapon = get_user_weapon(attacker)

	if((g_currentweapon != wId) 
	|| (g_currentweapon == wId && !g_has_m134ex[attacker])) return;
	
	navtive_bullet_effect(attacker, ent, ptr)
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == wId)
		{
			if(g_has_m134ex[attacker])
				SetHamParamFloat(4, damage * DAMAGE)
		}
	}
}
public fw_PlayerPreThink(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_has_m134ex[id] || get_user_weapon(id) != CSW_M249)
		return

	new szClip
	get_user_weapon(id, szClip)

	if(g_can[id]) set_pev(id, pev_maxspeed, 150.0)
	if(!g_can[id] || szClip <= 0) set_pev(id, pev_maxspeed, 200.0)
}
stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);
}
stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}
stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}
public m134ex__ItemPostFrame(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;
	if (!g_has_m134ex[id])
		return HAM_IGNORED;
	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)
	new iBpAmmo = cs_get_user_bpammo(id, wId);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)
	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF)
	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(200 - iClip, iBpAmmo)
		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, wId, iBpAmmo-j);
		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		fInReload = 0
	}
	return HAM_IGNORED;
}
public m134ex__Reload(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;
	if (!g_has_m134ex[id])
		return HAM_IGNORED;
	g_m134ex_TmpClip[id] = -1;
	new iBpAmmo = cs_get_user_bpammo(id, wId);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)
	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE;
	if (iClip >= 200)
		return HAM_SUPERCEDE;
	g_m134ex_TmpClip[id] = iClip;
	return HAM_IGNORED;
}
public m134ex__Reload_Post(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;
	if (!g_has_m134ex[id])
		return HAM_IGNORED;
	if (g_m134ex_TmpClip[id] == -1)
		return HAM_IGNORED;
	set_pdata_int(weapon_entity, m_iClip, g_m134ex_TmpClip[id], WEAP_LINUX_XTRA_OFF)
	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, RELOAD_TIME, WEAP_LINUX_XTRA_OFF)
	set_pdata_float(id, m_flNextAttack, RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)
	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)
	UTIL_PlayWeaponAnimation(id, 3)
	return HAM_IGNORED;
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
//stock ScreenShake(id, amplitude = 18, duration = 5, frequency = 28)
stock ScreenShake(id, amplitude = 1000, duration = 1, frequency = 28)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, id)
	write_short((1<<12)*amplitude) 
	write_short((1<<12)*duration) 
	write_short((1<<12)*frequency) 
	message_end()
}

