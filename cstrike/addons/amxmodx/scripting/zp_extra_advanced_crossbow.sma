#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>

#define ENG_NULLENT		-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define crossbow_WEAPONKEY 35481
#define MAX_PLAYERS  			  32

#define DAMAGE 1.6
#define BOLT_SPEED 2000
#define BOLT_LIVETIME 10.0
#define BOLT_CLASSNAME "dias_der_gott"

const pev_user = pev_iuser1
const pev_time = pev_fuser1

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
#define crossbow_RELOAD_TIME 3.5

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const Sound_Fire[][] = { "weapons/crossbow_shoot1.wav" }

new crossbow_V_MODEL[64] = "models/v_crossbowex.mdl"
new crossbow_P_MODEL[64] = "models/p_crossbowex.mdl"
new crossbow_W_MODEL[64] = "models/w_crossbowex.mdl"
new crossbow_S_MODEL[64] = "models/s_crossbowex.mdl"

new g_itemid_crossbow,g_SprId_LaserBeam
new g_has_crossbow[33], g_MaxPlayers, Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2], 
g_orig_event_crossbow, g_IsInPrimaryAttack, g_clip_ammo[33], g_crossbow_TmpClip[33], oldweap[33]
new g_HamBot

public plugin_init()
{
	register_plugin("CSO CROSSBOW, toectb ap6alet", "1.0", "Crock")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_sg550", "fw_Aug_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	
	RegisterHam(Ham_Item_Deploy, "weapon_sg550", "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_sg550", "fw_Aug_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_sg550", "fw_Aug_PrimaryAttack_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_sg550", "crossbow__ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_sg550", "crossbow__Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_sg550", "crossbow__Reload_Post", 1);
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")

	register_touch(BOLT_CLASSNAME, "*", "fw_SpearTouch")
	register_think(BOLT_CLASSNAME, "fw_SpearThink")
	g_itemid_crossbow = zp_register_extra_item("Advanced Crossbow", 3000, ZP_TEAM_HUMAN)
	g_MaxPlayers = get_maxplayers()
}
public plugin_precache()
{
	precache_model(crossbow_V_MODEL)
	precache_model(crossbow_P_MODEL)
	precache_model(crossbow_W_MODEL)
	precache_model(crossbow_S_MODEL)
	for(new i = 0; i < sizeof Sound_Fire; i++)
		precache_sound(Sound_Fire[i])
	precache_sound("weapons/crossbow_foley1.wav")
	precache_sound("weapons/crossbow_foley2.wav")
	precache_sound("weapons/crossbow_foley3.wav")
	precache_sound("weapons/crossbow_foley4.wav")
	precache_sound("weapons/crossbow_draw.wav")	
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	
	g_SprId_LaserBeam = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr")

	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}
public client_putinserver(id)
{
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Do_Register_HamBot", id)
	}
}
public Do_Register_HamBot(id) 
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_Spawn, id, "Player_Spawn")
	//RegisterHamFromEntity(Ham_TraceAttack, id, "TraceAttack")	
}

public zp_user_humanized_post(id)
{
	g_has_crossbow[id] = false
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/sg550.sc", name))
	{
		g_orig_event_crossbow = get_orig_retval()
		return FMRES_HANDLED
	}

	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_crossbow[id] = false
}

public client_disconnect(id)
{
	g_has_crossbow[id] = false
}

public Player_Spawn(id)
{
	g_has_crossbow[id] = false
}
public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_crossbow[id] = false
	}
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
	
	if(equal(model, "models/w_sg550.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_sg550", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED;
	
		if(g_has_crossbow[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, crossbow_WEAPONKEY)
			
			g_has_crossbow[iOwner] = false
			
			entity_set_model(entity, crossbow_W_MODEL)
			
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_itemid_crossbow)
	{
		drop_weapons(id, 1);
		g_has_crossbow[id] = true;
		new iWep2 = give_item(id,"weapon_sg550")
		if( iWep2 > 0 )
		{
			cs_set_weapon_ammo( iWep2, 50 )
			cs_set_user_bpammo (id, CSW_SG550, 200)
			UTIL_PlayWeaponAnimation(id, 4)
		}
	}
}

public fw_Aug_AddToPlayer(Aug, id)
{
	if(!is_valid_ent(Aug) || !is_user_connected(id))
		return HAM_IGNORED;
	
	if(entity_get_int(Aug, EV_INT_WEAPONKEY) == crossbow_WEAPONKEY)
	{
		g_has_crossbow[id] = true
		
		entity_set_int(Aug, EV_INT_WEAPONKEY, 0)
		
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}
public fw_AddToPlayer( iEnt, Player )
{
    if( pev_valid( iEnt ) && is_user_connected( Player ) )
    {

    }
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

     if(read_data(2) != CSW_SG550 || !g_has_crossbow[id])
          return
     
     static Float:iSpeed
     if(g_has_crossbow[id])
          iSpeed = 0.5
     
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
		case CSW_SG550:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return;
			
			if(g_has_crossbow[id])
			{
				set_pev(id, pev_viewmodel2, crossbow_V_MODEL)
				set_pev(id, pev_weaponmodel2, crossbow_P_MODEL)
				if(oldweap[id] != CSW_SG550) 
				{
					set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
					UTIL_PlayWeaponAnimation(id, 4)
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_SG550 || !g_has_crossbow[Player]))

		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_Aug_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_crossbow[Player])
		return;
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_crossbow) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_Aug_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(g_has_crossbow[Player])
	{
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,1.0,push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		if (!g_clip_ammo[Player])
			return
		
		emit_sound(Player, CHAN_WEAPON, Sound_Fire[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, random_num(1, 2))
		
		Create_Dart(Player)
	}
}
public Create_Dart(id)
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return
	
	static Float:Origin[3], Float:Angles[3], Float:Velocity[3], Float:Target[3]
	
	//Get_Position(id, 12.0, 6.0, -3.0, Origin)
	Get_Position(id, 0.0, 0.0, 0.0, Origin)
	
	pev(id, pev_v_angle, Angles); 
	
	Get_Position(id, 1024.0, 0.0, 0.0, Target)
	
	Angles[0] += 180.0
	Angles[1] += 180.0
	
	// Set info for ent
	set_pev(Ent, pev_movetype, MOVETYPE_FLY)	
	set_pev(Ent, pev_classname, BOLT_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, crossbow_S_MODEL)	
	set_pev(Ent, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(Ent, pev_maxs, Float:{1.0, 1.0, 1.0})	
	set_pev(Ent, pev_origin, Origin)
	set_pev(Ent, pev_angles, Angles)
	set_pev(Ent, pev_gravity, 0.01)	
	set_pev(Ent, pev_solid, SOLID_TRIGGER)	
	set_pev(Ent, pev_user, id)
	set_pev(Ent, pev_time, get_gametime() + BOLT_LIVETIME)	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.05)	
	
	get_speed_vector(Origin, Target, float(BOLT_SPEED), Velocity)
	set_pev(Ent, pev_velocity, Velocity)
	
	// Create Beam
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(Ent)
	write_short(g_SprId_LaserBeam)
	write_byte(5)
	write_byte(1)
	write_byte(0)
	write_byte(127)
	write_byte(255)
	write_byte(150)
	message_end()
}

public fw_SpearThink(Ent)
{
	if(!pev_valid(Ent))
		return
	if(pev(Ent, pev_flags) == FL_KILLME)
		return

	if(pev(Ent, pev_time) <= get_gametime())
		set_pev(Ent, pev_flags, FL_KILLME)
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.05)
}

public fw_SpearTouch(Ent, Touched)
{
	if(!pev_valid(Ent))
		return
	
	static id; id = pev(Ent, pev_user)
	if(!is_user_connected(id))
	{
		set_pev(Ent, pev_flags, FL_KILLME)
		set_pev(Ent, pev_nextthink, get_gametime() + 0.05)
		
		return
	}
	if(pev(Ent, pev_movetype) == MOVETYPE_NONE)
		return
	
	if(is_user_alive(Touched))
	{
		if(id == Touched)
			return

		if(cs_get_user_team(id) == cs_get_user_team(Touched))
			return

		//ExecuteHamB(Ham_TakeDamage, Touched, id, id, DAMAGE, DMG_BULLET)
		
		set_pev(Ent, pev_movetype, MOVETYPE_NONE)
		set_pev(Ent, pev_time, get_gametime())
		set_pev(Ent, pev_nextthink, get_gametime() + 0.05)
	} else {
		set_pev(Ent, pev_movetype, MOVETYPE_NONE)
		set_pev(Ent, pev_time, get_gametime() + BOLT_LIVETIME/2)
	}
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_SG550)
		{
			if(g_has_crossbow[attacker])
				SetHamParamFloat(4, damage * DAMAGE)
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
	
	if(get_user_weapon(iAttacker) == CSW_SG550)
	{
		if(g_has_crossbow[iAttacker])
			set_msg_arg_string(4, "crossbowex")
	}
	
	return PLUGIN_CONTINUE
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

public crossbow__ItemPostFrame(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED;

     if (!g_has_crossbow[id])
          return HAM_IGNORED;
     
     static iClipExtra

     if(g_has_crossbow[id])
          iClipExtra = 50

     new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     new iBpAmmo = cs_get_user_bpammo(id, CSW_SG550);
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

     if( fInReload && flNextAttack <= 0.0 )
     {
          new j = min(iClipExtra - iClip, iBpAmmo)
     
          set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
          cs_set_user_bpammo(id, CSW_SG550, iBpAmmo-j);
          
          set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
          fInReload = 0
     }

     return HAM_IGNORED;
}

public crossbow__Reload(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED;

     if (!g_has_crossbow[id])
          return HAM_IGNORED;

     static iClipExtra

     if(g_has_crossbow[id])
          iClipExtra = 50

     g_crossbow_TmpClip[id] = -1;

     new iBpAmmo = cs_get_user_bpammo(id, CSW_SG550);
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE;

     if (iClip >= iClipExtra)
          return HAM_SUPERCEDE;


     g_crossbow_TmpClip[id] = iClip;

     return HAM_IGNORED;
}

public crossbow__Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_crossbow[id])
		return HAM_IGNORED;

	if (g_crossbow_TmpClip[id] == -1)
		return HAM_IGNORED;

	static Float:iReloadTime
	if(g_has_crossbow[id])
		iReloadTime = crossbow_RELOAD_TIME

	set_pdata_int(weapon_entity, m_iClip, g_crossbow_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, iReloadTime, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, iReloadTime, PLAYER_LINUX_XTRA_OFF)

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

stock Get_Position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}
