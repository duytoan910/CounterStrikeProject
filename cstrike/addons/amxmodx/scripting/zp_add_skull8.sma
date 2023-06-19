#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>
#include <toan>

#define ENG_NULLENT		-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define skull8_WEAPONKEY 	806398
#define MAX_PLAYERS  		32
#define IsValidUser(%1) 	(1 <= %1 <= g_MaxPlayers)

#define SKULL8_DAMAGE 1.3
#define SKULL8_RECOIL 1.03
#define SKULL8_CLIP 100
#define SKULL8_FIRE_SPD 1.02
#define SKULL8_AMMO 200
#define SKULL8_SLASH_RADIUS 220
#define SKULL8_SLASH_DAMAGE 600

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4

#define WEAP_LINUX_XTRA_OFF		4
#define m_fKnown			44
#define m_flNextPrimaryAttack 		46
#define m_flTimeWeaponIdle		48
#define m_iClip				51
#define m_fInReload			54
#define PLAYER_LINUX_XTRA_OFF		5
#define m_flNextAttack			83

/*Anim Settings	*/
#define skull8_SHOOT1		1
#define skull8_SHOOT2		2
#define skull8_RELOAD		3
#define skull8_DRAW		4

/*Time Settings */
#define skull8_RELOAD_TIME	4.6
#define skull8_SLASH_TIME	1.3	//�������� �� ���������� �����
#define skull8_SLASH_COMING	0.8	//����� ����� �������� ������ �� �����


#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_Sounds[][] = { "weapons/skull8-1.wav" }

new skull8_V_MODEL[64] = "models/v_skull8.mdl"
new skull8_P_MODEL[64] = "models/p_skull8.mdl"
new skull8_W_MODEL[64] = "models/w_skull8.mdl"

new skull8_anim[33]
new skull8_delay[33]
new g_SmokePuff_SprId
new g_ShellId
new slash_attack[33]

new g_itemid_skull8
new g_MaxPlayers, g_orig_event_skull8, g_IsInPrimaryAttack, g_ham_bot
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_has_skull8[33], g_clip_ammo[33], g_skull8_TmpClip[33], oldweap[33]

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_init()
{
	register_plugin("[WPN] Skull-8", "1.0", "Chrescoe1")	
	//������� �� ������� "[ZP] Extra: HK23" by "Crock / =) (Poprogun4ik) / LARS-DAY[BR]EAKER", ��� �� � ���� ���������� ���������
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m249", "fw_skull8_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	
	for (new i = 1; i < sizeof WEAPONENTNAMES ;i++)
	if (WEAPONENTNAMES[i][0]) 
		RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_skull8_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_skull8_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_m249", "skull8_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_m249", "skull8_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_m249", "skull8_Reload_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_CmdStart,  "fw_CmdStart", 1)
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)

	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(skull8_V_MODEL)
	precache_model(skull8_P_MODEL)
	precache_model(skull8_W_MODEL)
	
	for(new i = 0 ;i < sizeof Fire_Sounds ;i++)
	precache_sound(Fire_Sounds[i])	
	
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	
	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	g_ShellId = engfunc(EngFunc_PrecacheModel, "models/pshell.mdl")
	
	register_clcmd("weapon_skull8", "weapon_hook")	

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public client_putinserver(id)
{
	if(!g_ham_bot && is_user_bot(id))
	{
		g_ham_bot = 1
		set_task(0.1, "Do_Register_HamBot", id)
	}
}

public Do_Register_HamBot(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
}
public weapon_hook(id)
{
    	engclient_cmd(id, "weapon_m249")
    	return PLUGIN_HANDLED
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_M249) return
	
	if(!g_has_skull8[iAttacker]) return

	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
	Make_BulletHole(iAttacker, flEnd,flDamage)
}
public Make_BulletSmoke(id, TrResult)
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
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0)
	write_short(g_SmokePuff_SprId)
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()
}
stock Make_BulletHole(id, Float:Origin[3], Float:Damage)
{
	// Find target
	static Decal 
	Decal = random_num(41, 45)
	static LoopTime 
	
	if(Damage > 100.0) LoopTime = 2
	else LoopTime = 1
	
	for(new i = 0 ;i < LoopTime;i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(Decal)
		message_end()
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(id)
		write_byte(Decal)
		message_end()
	}
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
stock Eject_Shell(id, Shell_ModelIndex, Float:Time) // By Dias
{
	static Ent 
	Ent = get_pdata_cbase(id, 373, 5)
	if(!pev_valid(Ent))
		return

	set_pdata_int(Ent, 57, Shell_ModelIndex, 4)
	set_pdata_float(id, 111, get_gametime() + Time)
}
public plugin_natives ()
	register_native("skull8", "native_give_weapon_add", 1)
public native_give_weapon_add(id)
	give_skull8(id)

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/m249.sc", name))
	{
		g_orig_event_skull8 = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
	g_has_skull8[id] = false

public zp_user_infected_post(id)
	if (zp_get_user_zombie(id))
		g_has_skull8[id] = false

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, "models/w_m249.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_m249", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_has_skull8[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, skull8_WEAPONKEY)
			
			g_has_skull8[iOwner] = false
			
			entity_set_model(entity, skull8_W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_skull8(id)
{
	drop_weapons(id, 1)
	new iWep2 = give_item(id,"weapon_m249")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, SKULL8_CLIP)
		cs_set_user_bpammo (id, CSW_M249, SKULL8_AMMO)	
		UTIL_PlayWeaponAnimation(id, skull8_DRAW)
		set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
	}
	g_has_skull8[id] = true
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid != g_itemid_skull8)
		return

	give_skull8(id)
}

public fw_skull8_AddToPlayer(skull8, id)
{
	if(!is_valid_ent(skull8) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(skull8, EV_INT_WEAPONKEY) == skull8_WEAPONKEY)
	{
		g_has_skull8[id] = true
		
		entity_set_int(skull8, EV_INT_WEAPONKEY, 0)
		return HAM_HANDLED
	}
	return HAM_IGNORED
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
	if (use_type == USE_STOPPED && is_user_connected(caller))
		replace_weapon_models(caller, get_user_weapon(caller))

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
	
	if(read_data(2) != CSW_M249 || !g_has_skull8[id])
		return
	
	static Float:iSpeed
	if(g_has_skull8[id])
		iSpeed = SKULL8_FIRE_SPD
	
	static weapon[32],Ent
	get_weaponname(read_data(2),weapon,31)
	Ent = find_ent_by_owner(-1,weapon,id)
	if(Ent)
	{
		static Float:Delay
		Delay = get_pdata_float( Ent, 46, 4) * iSpeed
		if (Delay > 0.0)
			set_pdata_float(Ent, 46, Delay, 4)
	}
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_M249:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return
			
			if(g_has_skull8[id])
			{
				set_pev(id, pev_viewmodel2, skull8_V_MODEL)
				set_pev(id, pev_weaponmodel2, skull8_P_MODEL)
				if(oldweap[id] != CSW_M249) 
				{
					UTIL_PlayWeaponAnimation(id, skull8_DRAW)
					set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_M249 || !g_has_skull8[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_skull8_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_skull8[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_skull8) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
		return FMRES_IGNORED
	Eject_Shell(invoker, g_ShellId, 0.0)
	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_skull8_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return

	if(g_has_skull8[Player])
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push, SKULL8_RECOIL,push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, random_num(skull8_SHOOT1, skull8_SHOOT2))
	}
}

public do_secAttack(id){
	set_pdata_float(id, m_flNextAttack, skull8_SLASH_TIME, PLAYER_LINUX_XTRA_OFF)
	if(skull8_anim[id]==5)
		skull8_anim[id]=6
	else
	if(skull8_anim[id]==6)
		skull8_anim[id]=5
	else
		skull8_anim[id]=5
	UTIL_PlayWeaponAnimation(id,skull8_anim[id])
	skull8_delay[id]=1
	slash_attack[id]=1
	set_task(skull8_SLASH_TIME,"skull8_delay_end",id)
	set_task(skull8_SLASH_COMING,"skull8_slash",id)
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
	if (victim != attacker && is_user_connected(attacker))
		if(get_user_weapon(attacker) == CSW_M249)
			if(g_has_skull8[attacker])
				if(slash_attack[attacker]!=1)
					SetHamParamFloat(4, damage * SKULL8_DAMAGE)

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, "m249") && get_user_weapon(iAttacker) == CSW_M249)
	{
		if(g_has_skull8[iAttacker])
			if(slash_attack[iAttacker]==1)
				set_msg_arg_string(4, "skull8")
			else
				set_msg_arg_string(4, "skull8")
	}
	return PLUGIN_CONTINUE
}

stock fm_cs_get_current_weapon_ent(id)
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX)
stock fm_cs_get_weapon_ent_owner(ent)
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

public skull8_ItemPostFrame(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED
	
	if (!g_has_skull8[id])
		return HAM_IGNORED
	
	static iClipExtra
	
	iClipExtra = SKULL8_CLIP
	
	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)
	new iBpAmmo = cs_get_user_bpammo(id, CSW_M249)
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)	
	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 
	
	if( fInReload && flNextAttack <= 0.0 )
	{ 
		new j = min(iClipExtra - iClip, iBpAmmo)
		
		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, CSW_M249, iBpAmmo-j)
			
		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		fInReload = 0
	}

	if(!zp_get_user_zombie(id) && is_user_bot(id)){
		new enemy, body
		get_user_aiming(id, enemy, body)
		if ((1 <= enemy <= 32) && zp_get_user_zombie(enemy))
		{
			new origin1[3] ,origin2[3],range
			get_user_origin(id,origin1)
			get_user_origin(enemy,origin2)
			range = get_distance(origin1, origin2)
			if(range <= SKULL8_SLASH_RADIUS+20.0){
				do_secAttack(id)
				return HAM_IGNORED
			}
		}
	}

	return HAM_IGNORED
}

public skull8_Reload(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED
	
	if (!g_has_skull8[id])
		return HAM_IGNORED
	
	static iClipExtra
	
	if(g_has_skull8[id])
		iClipExtra = SKULL8_CLIP
	g_skull8_TmpClip[id] = -1
	
	new iBpAmmo = cs_get_user_bpammo(id, CSW_M249)
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)
	
	if (iBpAmmo <= 0||iClip >= iClipExtra)
		return HAM_SUPERCEDE
	
	g_skull8_TmpClip[id] = iClip
	
	return HAM_IGNORED
}

public skull8_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_skull8[id])
		return HAM_IGNORED

	if (g_skull8_TmpClip[id] == -1)
		return HAM_IGNORED
		
	set_pdata_int(weapon_entity, m_iClip, g_skull8_TmpClip[id], WEAP_LINUX_XTRA_OFF)
	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, skull8_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)
	set_pdata_float(id, m_flNextAttack, skull8_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)
	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)
	
	UTIL_PlayWeaponAnimation(id, skull8_RELOAD)
	return HAM_IGNORED
}
public fw_CmdStart(id,uc_handle)
{
	if(!is_user_alive(id)||!g_has_skull8[id])//||get_user_weapon(id)!=CSW_M249)
		return
		
	if(get_user_weapon(id)!=CSW_M249)
		return		
	
	if((get_uc(uc_handle, UC_Buttons)&IN_ATTACK2)&&skull8_delay[id]==0)
	{
		set_pdata_float(id, m_flNextAttack, skull8_SLASH_TIME, PLAYER_LINUX_XTRA_OFF)
		if(skull8_anim[id]==5)
			skull8_anim[id]=6
		else
		if(skull8_anim[id]==6)
			skull8_anim[id]=5
		else
			skull8_anim[id]=5
		UTIL_PlayWeaponAnimation(id,skull8_anim[id])
		skull8_delay[id]=1
		slash_attack[id]=1
		set_task(skull8_SLASH_TIME,"skull8_delay_end",id)
		set_task(skull8_SLASH_COMING,"skull8_slash",id)
	}
}
public skull8_delay_end(id)
{
	skull8_delay[id]=0
	slash_attack[id]=0
}
public skull8_slash(id,weapon_ent)
{
	new temp[2], weapon = get_user_weapon(id, temp[0], temp[1])
	
	if (weapon != CSW_M249 || slash_attack[id]!=1)
		return
		
	static Float:origin[3], Float:vSrc[3], Float:angles[3], Float:v_forward[3], Float:v_right[3], Float:v_up[3], Float:gun_position[3], Float:player_origin[3], Float:player_view_offset[3]
	pev(id, pev_v_angle, angles)
	engfunc(EngFunc_MakeVectors, angles)
	global_get(glb_v_forward, v_forward)
	global_get(glb_v_right, v_right)
	global_get(glb_v_up, v_up)

	//m_pPlayer->GetGunPosition( ) = pev->origin + pev->view_ofs
	pev(id, pev_origin, player_origin)
	pev(id, pev_view_ofs, player_view_offset)
	xs_vec_add(player_origin, player_view_offset, gun_position)
	
	xs_vec_mul_scalar(v_right, 0.0, v_right)

	if ((pev(id, pev_flags) & FL_DUCKING) == FL_DUCKING)
		xs_vec_mul_scalar(v_up, 6.0, v_up)
	else
		xs_vec_mul_scalar(v_up, -2.0, v_up)

	xs_vec_add(gun_position, v_forward, origin)
	xs_vec_add(origin, v_right, origin)
	xs_vec_add(origin, v_up, origin)
		
	vSrc[0] = origin[0]
	vSrc[1] = origin[1]
	vSrc[2] = origin[2]
	{
		static Float:flOrigin[3] , Float:flDistance , Float:originplayer[3]
		for(new iVictim=1;iVictim <= 33;iVictim++)
		{
			if(is_user_alive(iVictim) && zp_get_user_zombie(iVictim))
			{
				pev(iVictim, pev_origin, flOrigin)
				pev(id,pev_origin,originplayer)
	
				if(!get_can_see(flOrigin,originplayer))
					continue
			
				flDistance = get_distance_f ( vSrc , flOrigin )   
					
				if(flDistance <= float(SKULL8_SLASH_RADIUS / 2))
				{	
					new Float:dmg = random_float(SKULL8_SLASH_DAMAGE-10.0,SKULL8_SLASH_DAMAGE+10.0)
					
					ExecuteHamB(Ham_TakeDamage, iVictim , id , id, is_deadlyshot(id)?dmg*1.5:dmg, DMG_BULLET)		
					make_blood(iVictim,dmg)
				}
			}
		}
	}
	
}
stock get_can_see(Float:ent_origin[3], Float:target_origin[3])
{
	new Float:hit_origin[3]
	trace_line(-1, ent_origin, target_origin, hit_origin)						

	if (!vector_distance(hit_origin, target_origin))
		return 1

	return 0
}
stock make_blood(id , Float:Damage)
{
	new bloodColor = ExecuteHam(Ham_BloodColor, id)
	new Float:origin[3]
	pev(id,pev_origin,origin)

	if (bloodColor == -1)
		return

	new amount = floatround(Damage)

	amount *= 2

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(bloodColor)
	write_byte(min(max(3, amount/10), 16))
	message_end()
}
stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	
	for (i = 0 ;i < num; i++)
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
