#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>

#define ENG_NULLENT			-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define sfmg_WEAPONKEY 		814
#define MAX_PLAYERS  		32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)

#define DMG_SFMG 1.4
#define DMG_MODE_SFMG 1.5
#define RECOIL_SFMG 1.05
#define RECOIL_MODE_SFMG 1.7
#define SPD_SFMG 0.98
#define SPD_MODE_SFMG 0.76

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4

#define WEAP_LINUX_XTRA_OFF		4
#define m_pPlayer                			41
#define m_fKnown					44
#define m_flNextPrimaryAttack 		46
#define m_flNextSecondaryAttack 		47
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF	5
#define m_flNextAttack				83

#define sfmg_DRAW_TIME     		1.0
#define sfmg_RELOAD_TIME			4.8
#define sfmg_TIME_MODE			2.2

#define sfmg_IDLE				0
#define sfmg_RELOAD			1
#define sfmg_DRAW			2
#define sfmg_SHOOT1			3
#define sfmg_SHOOT2			4
#define sfmg_FIRST_ANIM		6
#define sfmg_IDLE_MODE		7
#define sfmg_RELOAD_MODE	8
#define sfmg_DRAW_MODE		9
#define sfmg_SHOOT1_MODE	10
#define sfmg_SHOOT2_MODE	11
#define sfmg_SECOND_ANIM		13

#define UP_SCALE				-7.0    //����� (6)
#define FORWARD_SCALE		14.0     //������ (8)
#define RIGHT_SCALE			6.5       //������ (5.5)
#define TE_BOUNCE_SHELL		1

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_Sounds_sfmg[][] = { "weapons/sfmg-1.wav" }

new sfmg_V_MODEL[64] = "models/v_sfmg.mdl"
new sfmg_P_MODEL[64] = "models/p_sfmg.mdl"
new sfmg_W_MODEL[64] = "models/w_sfmg.mdl"

#define sfmg_Body		0

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new const sfmg_name[] = "weapon_m249"

new const g_iMuzzleFlash1[ ]  = "sprites/muzzleflash16.spr" ; 
new const g_iMuzzleFlash2[ ]  = "sprites/muzzleflash17.spr" ; 

new g_itemid_sfmg
new g_MaxPlayers, g_orig_event_sfmg, g_IsInPrimaryAttack
new Float:cl_pushangle[MAX_PLAYERS + 1][3]
new g_has_sfmg[33], g_clip_ammo[33], g_sfmg_TmpClip[33], oldweap[33], g_curweapon[33]
new g_mode[33]
new g_hamczbots, cvar_botquota
new gmsgWeaponList
new g_iShellModel
new Float:g_flNextUseTime[33], Float:g_flSaveMode[33][2]

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_init()
{
	register_plugin("[ZP] Extra: SF-1 MG Avalanche", "1.0", "LARS-BLOODLIKER")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m249", "fw_sfmg_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
	if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_sfmg_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_sfmg_PrimaryAttack_Post", 1)
     	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_m249", "fw_sfmg_WeaponIdle")
	RegisterHam(Ham_Item_PostFrame, "weapon_m249", "sfmg_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_m249", "sfmg_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_m249", "sfmg_Reload_Post", 1)
	RegisterHam(Ham_Item_Holster, "weapon_m249", "sfmg_Holster_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)

	g_MaxPlayers = get_maxplayers()
	cvar_botquota = get_cvar_pointer("bot_quota")
	gmsgWeaponList = get_user_msgid("WeaponList")
	register_clcmd(sfmg_name, "command_sfmg")
	register_clcmd(sfmg_name, "command_sfmg")
}

public plugin_precache()
{
	precache_model(sfmg_V_MODEL)
	precache_model(sfmg_P_MODEL)
	precache_model(sfmg_W_MODEL)

	for(new i = 0; i < sizeof Fire_Sounds_sfmg; i++)
	precache_sound(Fire_Sounds_sfmg[i])	

	g_iShellModel = precache_model("models/rshell.mdl")

	new sFile[64]
	formatex(sFile, charsmax(sFile), "sprites/%s.txt", sfmg_name)
	precache_generic(sFile)

	precache_model( g_iMuzzleFlash1 ) 
	precache_model( g_iMuzzleFlash2 ) 

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_M249) return
	
	if(!g_has_sfmg[iAttacker]) return

	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
	if(iEnt)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		write_short(iEnt)
		message_end()
	}
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		message_end()
	}
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	write_coord_f(flEnd[0])
	write_coord_f(flEnd[1])
	write_coord_f(flEnd[2])
	write_short(iAttacker)
	write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
	message_end()
}

public register_ham_czbots(Player)
{
	if (g_hamczbots || !is_user_connected(Player) || !get_pcvar_num(cvar_botquota)) return
	
	RegisterHamFromEntity(Ham_TakeDamage, Player, "fw_TakeDamage")
	
	g_hamczbots = true
}

public client_putinserver(Player)
{
	if(is_user_bot(Player) && !g_hamczbots && cvar_botquota) set_task(0.1, "register_ham_czbots", Player)
}

public command_sfmg(Player)
{
	engclient_cmd(Player, "weapon_m249")
	return PLUGIN_HANDLED
}

public plugin_natives ()
{
    register_native("sfmg", "native_give_weapon_add", 1)
}
public native_give_weapon_add(id)
{
	give_sfmg(id)
}
public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/m249.sc", name))
	{
		g_orig_event_sfmg = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_sfmg[id] = false
	g_mode[id] = 0
}

public client_disconnect(id)
{
	g_has_sfmg[id] = false
	g_mode[id] = 0
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_sfmg[id] = false
		g_mode[id] = 0
	}
}

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
	
		if(g_has_sfmg[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, sfmg_WEAPONKEY)
			set_pev(iStoredAugID, pev_iuser4, g_mode[iOwner]) 
			g_has_sfmg[iOwner] = false
			g_mode[iOwner] = 0 
			entity_set_model(entity, sfmg_W_MODEL)

			set_pev(entity, pev_body, sfmg_Body)
						
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_sfmg(id)
{
	drop_weapons(id, 1)
	new iWep2 = give_item(id,"weapon_m249")
	if( iWep2 > 0 )
	{
		g_mode[id] = 1
		cs_set_weapon_ammo(iWep2, 200)
		cs_set_user_bpammo (id, CSW_M249, 200)	
		if (g_mode[id] == 1)
		{
			UTIL_PlayWeaponAnimation (id, sfmg_DRAW)
		}
		else if (g_mode[id] == 2)
		{
			UTIL_PlayWeaponAnimation (id, sfmg_DRAW_MODE)
		}
		set_pdata_float(id, m_flNextAttack, sfmg_DRAW_TIME, OFFSET_LINUX)

		message_begin(MSG_ONE, gmsgWeaponList, _, id)
		write_string(sfmg_name)
		write_byte(3)
		write_byte(200)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(4)
		write_byte(CSW_M249)
		message_end()
	}
	g_has_sfmg[id] = true
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid != g_itemid_sfmg)
		return

	give_sfmg(id)
}

public fw_sfmg_AddToPlayer(sfmg, id)
{
	if(!is_valid_ent(sfmg) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(sfmg, EV_INT_WEAPONKEY) == sfmg_WEAPONKEY)
	{
		g_has_sfmg[id] = true
		g_mode[id] = pev(sfmg, pev_iuser4 ) 
		set_pev(sfmg, pev_iuser4, 0 )            
		entity_set_int(sfmg, EV_INT_WEAPONKEY, 0)

		message_begin(MSG_ONE, gmsgWeaponList, _, id)
		write_string(sfmg_name)
		write_byte(3)
		write_byte(200)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(4)
		write_byte(CSW_M249)
		message_end()

		return HAM_HANDLED
	}
	else
	{
		message_begin(MSG_ONE, gmsgWeaponList, _, id)
		write_string("weapon_m249")
		write_byte(3)
		write_byte(200)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(4)
		write_byte(CSW_M249)
		message_end()
	}
	return HAM_IGNORED
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

	g_curweapon[id] = read_data(2)

	if(read_data(2) != CSW_M249 || !g_has_sfmg[id])
		return
     
	static Float:iSpeed, Ent
	Ent = find_ent_by_owner(-1,"weapon_m249",id)

	if (g_mode[id] == 1)
		iSpeed = SPD_SFMG
	else if (g_mode[id] == 2)
		iSpeed = SPD_MODE_SFMG

	if(Ent)
	{
		static Float:Delay, Float:M_Delay
		Delay = get_pdata_float( Ent, 46, 4) * iSpeed
		M_Delay = get_pdata_float( Ent, 47, 4) * iSpeed
		if(Delay > 0.0)
		{
		set_pdata_float(Ent, 46, Delay, 4)
			set_pdata_float(Ent, 47, M_Delay, 4)
		}
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
			
			if(g_has_sfmg[id])
			{
				set_pev(id, pev_viewmodel2, sfmg_V_MODEL)
				set_pev(id, pev_weaponmodel2, sfmg_P_MODEL)
				if(oldweap[id] != CSW_M249) 
				{
					if (g_mode[id] == 1)
					{
						UTIL_PlayWeaponAnimation (id, sfmg_DRAW)
					}
					else if (g_mode[id] == 2)
					{
						UTIL_PlayWeaponAnimation (id, sfmg_DRAW_MODE)
					}
					set_pdata_float(id, m_flNextAttack, sfmg_DRAW_TIME, OFFSET_LINUX)

					message_begin(MSG_ONE, gmsgWeaponList, _, id)
					write_string(sfmg_name)
					write_byte(3)
					write_byte(200)
					write_byte(-1)
					write_byte(-1)
					write_byte(0)
					write_byte(4)
					write_byte(CSW_M249)
					message_end()
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_M249 || !g_has_sfmg[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_sfmg_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_sfmg[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_sfmg) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_CmdStart(id, uc_handle, seed)
{
	if ((!is_user_alive(id) || (!g_has_sfmg[id] || g_curweapon[id] != CSW_M249)))
		return FMRES_IGNORED
		
	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, OFFSET_LINUX)

	if (g_curweapon[id] == CSW_M249)
	{
		if ((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
		{
			if (g_mode[id] == 1 && flNextAttack <= 0.0)
			{
				UTIL_PlayWeaponAnimation(id, sfmg_FIRST_ANIM)
				g_mode[id] = 2
				set_pdata_float(id, m_flNextAttack, sfmg_TIME_MODE, OFFSET_LINUX)
				g_flSaveMode[id][0] = get_gametime() + sfmg_TIME_MODE
			}
			else if (g_mode[id] == 2 && flNextAttack <= 0.0)
			{
				UTIL_PlayWeaponAnimation(id, sfmg_SECOND_ANIM)
				g_mode[id] = 1
				set_pdata_float(id, m_flNextAttack, sfmg_TIME_MODE, OFFSET_LINUX)
				g_flSaveMode[id][1] = get_gametime() + sfmg_TIME_MODE
			}
		}
	}
	return FMRES_IGNORED
}

public fw_sfmg_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return

	if(g_has_sfmg[Player])
	{
		if (!g_clip_ammo[Player])
			return

		new Float:push[3]

		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)

		if (g_curweapon [Player] == CSW_M249)
		{	
			if (g_has_sfmg[Player])
			{
				if (g_mode[Player] == 1)
					xs_vec_mul_scalar(push , RECOIL_SFMG, push)
				else if(g_mode[Player] == 2)
					xs_vec_mul_scalar(push, RECOIL_MODE_SFMG, push)
			}
		}
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)

		if(g_mode[Player] == 1)
		{
			UTIL_PlayWeaponAnimation(Player,random_num(sfmg_SHOOT1, sfmg_SHOOT2))
		}
		else if (g_mode[Player] == 2)
		{
			UTIL_PlayWeaponAnimation(Player,random_num(sfmg_SHOOT1_MODE, sfmg_SHOOT2_MODE))
		}
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds_sfmg[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		static Float:vVel[3], Float:vAngle[3], Float:vOrigin[3], Float:vViewOfs[3], 
		i, Float:vShellOrigin[3], Float:vShellVelocity[3], Float:vRight[3], 
		Float:vUp[3], Float:vForward[3]
		pev(Player, pev_velocity, vVel)
		pev(Player, pev_view_ofs, vViewOfs)
		pev(Player, pev_angles, vAngle)
		pev(Player, pev_origin, vOrigin)
		global_get(glb_v_right, vRight)
		global_get(glb_v_up, vUp)
		global_get(glb_v_forward, vForward)
		for(i = 0; i<3; i++)
		{
			vShellOrigin[i] = vOrigin[i] + vViewOfs[i] + vUp[i] * UP_SCALE + vForward[i] * FORWARD_SCALE + vRight[i] * RIGHT_SCALE
			vShellVelocity[i] = vVel[i] + vRight[i] * random_float(50.0, 70.0) + vUp[i] * random_float(100.0, 150.0) + vForward[i] * 25.0
		}
		CBaseWeapon__EjectBrass(vShellOrigin, vShellVelocity, -vAngle[1], g_iShellModel, TE_BOUNCE_SHELL)

		UTIL_MakeMuzzle( Player ) 
	}
}

stock UTIL_MakeMuzzle( Player   ) 
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite")) 
	
	new Float:vecOrigin[ 3 ]
	pev( Player, pev_origin, vecOrigin )

	entity_set_origin( pEntity, vecOrigin )
	
	if(g_mode[Player] == 1) { entity_set_model( pEntity, g_iMuzzleFlash2 ); } 
	else if(g_mode[Player] == 2) { entity_set_model( pEntity, g_iMuzzleFlash1 ); }

	entity_set_int( pEntity, EV_INT_solid, SOLID_NOT )
	entity_set_int( pEntity, EV_INT_movetype, MOVETYPE_NOCLIP )
	
	entity_set_string( pEntity, EV_SZ_classname, "muzzle_et" )
	
	entity_set_float( pEntity, EV_FL_animtime, get_gametime() )
	entity_set_float( pEntity, EV_FL_framerate, 8.0 )       

	if(g_mode[Player] == 1) { set_pev( pEntity, pev_scale, 0.17 ); }
	else if(g_mode[Player] == 2) { set_pev( pEntity, pev_scale, 0.13 ); }

	set_pev( pEntity, pev_spawnflags, SF_SPRITE_ONCE)

	set_pev(pEntity, pev_rendermode,  kRenderTransAdd)
	
	set_pev(pEntity, pev_renderamt,   255.0)

	set_pev(pEntity, pev_skin, Player )
	set_pev(pEntity, pev_body, 1)
	set_pev(pEntity, pev_aiment, Player)

	entity_set_float(pEntity, EV_FL_nextthink, get_gametime() + 1.0 ); //3.0
	
	DispatchSpawn( pEntity );
	
	set_task( 1.0 , "rem_ent" , pEntity ) 
}		

public rem_ent( iEnt ) 
{
	remove_entity( iEnt ) 
}	

public fw_sfmg_WeaponIdle(Weapon)
{
	if(!pev_valid(Weapon))
		return HAM_IGNORED

	new Player = get_pdata_cbase(Weapon, m_pPlayer, 4)

	if(!g_has_sfmg[Player])
		return HAM_IGNORED

	if(g_has_sfmg[Player])
	{
		if(get_pdata_float(Weapon, m_flTimeWeaponIdle ) > 0.0)
			return HAM_SUPERCEDE

		if(g_mode[Player] == 1) { UTIL_PlayWeaponAnimation(Player, sfmg_IDLE)
		} else if (g_mode[Player] == 2) { UTIL_PlayWeaponAnimation(Player, sfmg_IDLE_MODE)
		}

		set_pdata_float(Weapon, m_flTimeWeaponIdle, random_float(5.0, 10.0), 4);
		
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_M249)
		{
			if(g_has_sfmg[attacker])
			{
				if (g_mode[attacker] == 1)
					SetHamParamFloat(4, damage * DMG_SFMG)
				else if (g_mode[attacker] == 2)
					SetHamParamFloat(4, damage * DMG_MODE_SFMG)
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
	
	if(equal(szTruncatedWeapon, "m249") && get_user_weapon(iAttacker) == CSW_M249)
	{
		if(g_has_sfmg[iAttacker])
			set_msg_arg_string(4, "sfmg")
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

public sfmg_ItemPostFrame(weapon_entity) 
{
     	new id = pev(weapon_entity, pev_owner)
     	if (!is_user_connected(id))
          	return HAM_IGNORED

     	if (!g_has_sfmg[id])
          	return HAM_IGNORED

     	static iClipExtra
     
     	iClipExtra = 200
     	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     	new iBpAmmo = cs_get_user_bpammo(id, CSW_M249)
     	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

     	if(fInReload && flNextAttack <= 0.0)
     	{
	     	new j = min(iClipExtra - iClip, iBpAmmo)
	
	     	set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
	     	cs_set_user_bpammo(id, CSW_M249, iBpAmmo-j)
		
	     	set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
	     	fInReload = 0
     	}
     	return HAM_IGNORED
}

public sfmg_Reload(weapon_entity) 
{
     	new id = pev(weapon_entity, pev_owner)
     	if (!is_user_connected(id))
          	return HAM_IGNORED

     	if (!g_has_sfmg[id])
          	return HAM_IGNORED

     	static iClipExtra

     	if(g_has_sfmg[id])
          	iClipExtra = 200

     	g_sfmg_TmpClip[id] = -1

     	new iBpAmmo = cs_get_user_bpammo(id, CSW_M249)
     	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     	if (iBpAmmo <= 0)
          	return HAM_SUPERCEDE

     	if (iClip >= iClipExtra)
          	return HAM_SUPERCEDE

     	g_sfmg_TmpClip[id] = iClip

     	return HAM_IGNORED
}

public sfmg_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_sfmg[id])
		return HAM_IGNORED

	if (g_sfmg_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_sfmg_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, sfmg_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, sfmg_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	if(g_mode[id] == 1)
	{
		UTIL_PlayWeaponAnimation (id, sfmg_RELOAD)
	}
	else if (g_mode[id] == 2)
	{
		UTIL_PlayWeaponAnimation (id, sfmg_RELOAD_MODE)
	}
	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	return HAM_IGNORED
}

public sfmg_Holster_Post(weapon_entity)
{
	static Player
	Player = get_pdata_cbase(weapon_entity, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
	
	g_flNextUseTime[Player] = 0.0

	if(g_has_sfmg[Player])
	{
		if(g_flSaveMode[Player][0] > get_gametime())
		{
			g_mode[Player] = 1
		}
		if(g_flSaveMode[Player][1] > get_gametime())
		{
			g_mode[Player] = 2
		}
	}
}

CBaseWeapon__EjectBrass(Float:vecOrigin[3], Float:vecVelocity[3], Float:rotation, model, soundtype)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0)
	write_byte(TE_MODEL)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	engfunc(EngFunc_WriteCoord, vecVelocity[0])
	engfunc(EngFunc_WriteCoord, vecVelocity[1])
	engfunc(EngFunc_WriteCoord, vecVelocity[2])
	engfunc(EngFunc_WriteAngle, rotation)
	write_short(model)
	write_byte(soundtype)
	write_byte(25) // 2.5 seconds
	message_end()
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