/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>
#include <xs>
#include <zombieplague>

#define PLUGIN  "[Luna's Weapon] Bouncer"
#define VERSION "Beta 1.0"
#define AUTHOR  "Celena Luna"

#define P_MODEL "models/p_bouncer.mdl"
#define V_MODEL "models/v_bouncer.mdl"
#define W_MODEL "models/w_bouncer.mdl"
#define BALL_MODEL "models/s_bouncer.mdl"

#define CSW_BOUNCER CSW_M3 
#define weapon_bouncer "weapon_m3"

#define OLD_SHELL "models/shell_bcs.mdl"	

#define WEAPON_SECRETCODE 46731
#define OLD_W_MODEL "models/w_m3.mdl"
#define OLD_EVENT "events/m3.sc"

#define CLIP 25
#define BPAMMO 200
#define BOUNCETIME 5
#define SPEED 1200
#define DAMAGE 70

#define RELOAD_TIME 0.2
#define RELOAD_ANIMATION_TIME RELOAD_TIME+0.2

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord, %1)

enum
{
	ANIM_IDLE_A = 0,
	ANIM_SHOOT1_A,
	ANIM_SHOOT2_A,
	ANIM_INSERT_A,
	ANIM_AFTER_A,
	ANIM_START_A,
	ANIM_DRAW_A, 
}

// ==========================================================
enum _:ShotGuns {
	m3,
	xm1014
}

const NOCLIP_WPN_BS	= ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))
const SHOTGUNS_BS	= ((1<<CSW_M3)|(1<<CSW_XM1014))

// weapons offsets
#define XTRA_OFS_WEAPON			4
#define m_pPlayer				41
#define m_iId					43
#define m_fKnown				44
#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack	47
#define m_flTimeWeaponIdle		48
#define m_iPrimaryAmmoType		49
#define m_iClip				51
#define m_fInReload				54
#define m_fInSpecialReload		55
#define m_fSilent				74
#define m_flNextReload			75

// players offsets
#define XTRA_OFS_PLAYER		5
#define m_flNextAttack		83
#define m_rgAmmo_player_Slot0	376

stock const g_iDftMaxClip[CSW_P90+1] = {
	-1,  13, -1, 10,  1,  7,	1, 30, 30,  1,  30, 
		20, 25, 30, 35, 25,   12, 20, 10, 30, 100, 
		8 , 30, 30, 20,  2,	7, 30, 30, -1,  50}

stock const Float:g_fDelay[CSW_P90+1] = {
	0.00, 2.70, 0.00, 2.00, 0.00, 0.55,   0.00, 3.15, 3.30, 0.00, 4.50, 
		 2.70, 3.50, 3.35, 2.45, 3.30,   2.70, 2.20, 2.50, 2.63, 4.70, 
		 0.55, 3.05, 2.12, 3.50, 0.00,   2.20, 3.00, 2.45, 0.00, 3.40
}

stock const g_iReloadAnims[CSW_P90+1] = {
	-1,  5, -1, 3, -1,  6,   -1, 1, 1, -1, 14, 
		4,  2, 3,  1,  1,   13, 7, 4,  1,  3, 
		6, 11, 1,  3, -1,	4, 1, 1, -1,  1}

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_Had_Bouncer, g_Event_Bouncer, m_iBlood[2]
new g_MsgCurWeapon, g_HamBot
new m_spriteTexture, g_Muzzle[33]
new g_OldWeapon[33], item_janus

// Safety
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33]

new const WeaponSounds[3][] = 
{
	"sound/weapons/bouncer_draw.wav",
	"sound/weapons/bouncer_reload_after.wav",
	"sound/weapons/bouncer_reload_insert.wav"
}

#define WeaponShoots "weapons/bouncer-1.wav"


public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")

		// Safety
	Register_SafetyFunc()

	register_touch("bouncer_ball", "*", "fw_touch")	
	register_think("bouncer_ball", "fw_think")

	register_event("HLTV", "event_newround", "a", "1=0", "2=0")

	register_think("bouncer_muzzleflash", "fw_Muzzle_Think")

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)		
	
	RegisterHam(Ham_Item_Deploy, weapon_bouncer, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_AddToPlayer, weapon_bouncer, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_bouncer, "fw_Weapon_WeaponIdle")	
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_bouncer, "fw_Weapon_WeaponIdle_Post", 1)
	RegisterHam(Ham_Weapon_Reload, weapon_bouncer, "fw_Weapon_Reload", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_bouncer, "fw_Weapon_PrimaryAttack_Post", 1)

	// Cache
	g_MsgCurWeapon = get_user_msgid("CurWeapon")
	item_janus = zp_register_extra_item("Bouncer", 3000, ZP_TEAM_HUMAN)
}
public plugin_precache()
{
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_model(W_MODEL)
	precache_model(BALL_MODEL)
	precache_sound(WeaponShoots)
	
	for(new i = 0; i < sizeof(WeaponSounds); i++)
		precache_generic(WeaponSounds[i])

	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)	
	
	m_spriteTexture = precache_model("sprites/laserbeam.spr")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
}
public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(OLD_EVENT, name))
		g_Event_Bouncer = get_orig_retval()
}

public client_putinserver(id)
{
	Safety_Connected(id)
	
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Do_Register_HamBot", id)
	}
}

public Do_Register_HamBot(id) 
{
	Register_SafetyFuncBot(id)
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
}

public client_disconnect(id)
{
	Safety_Disconnected(id)
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		Remove_Bouncer(id)
	}
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid == item_janus) Get_Bouncer(id)
}

public Get_Bouncer(id)
{
	drop_weapons(id, 1)
	Remove_Bouncer(id)
	
	Set_BitVar(g_Had_Bouncer, id)
	
	give_item(id, weapon_bouncer)
	static bpammo; bpammo = BPAMMO
	cs_set_user_bpammo(id, CSW_BOUNCER, bpammo)
	
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_BOUNCER)
	static Clip; Clip = CLIP
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, Clip)

	message_begin(MSG_ONE_UNRELIABLE, g_MsgCurWeapon, _, id)
	write_byte(1)
	write_byte(CSW_BOUNCER)
	write_byte(Clip)
	message_end()
}

public Remove_Bouncer(id)
{
	UnSet_BitVar(g_Had_Bouncer, id)

	if(pev_valid(g_Muzzle[id])) remove_entity(g_Muzzle[id])
	g_Muzzle[id] = 0
}
public Player_Spawn(id)
{
	Remove_Bouncer(id)
}

public Event_CurWeapon(id)
{
	if(!is_player(id, 1))
		return
	
	static CSWID; CSWID = read_data(2)
	
	g_OldWeapon[id] = CSWID
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
		weapon = fm_get_user_weapon_entity(entity, CSW_BOUNCER)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(Get_BitVar(g_Had_Bouncer, id))
		{
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			Remove_Bouncer(id)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_player(id, 1))
		return
	if(get_player_weapon(id) != CSW_BOUNCER|| !Get_BitVar(g_Had_Bouncer, id))
		return
		
	static NewButton; NewButton = get_uc(uc_handle, UC_Buttons)
	
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_BOUNCER)
	static Clip; Clip = CLIP
	if(!pev_valid(Ent)) return
	
	/*if(NewButton & IN_RELOAD) 
	{
		NewButton &= ~IN_RELOAD
		set_uc(uc_handle, UC_Buttons, NewButton)
		
		if(flNextAttack > 0.0) return
		
		static fInReload; fInReload = get_pdata_int(Ent, 54, 4)
		if(fInReload || cs_get_weapon_ammo(Ent) >= CLIP)
			return
		
		fw_Weapon_Reload(Ent)
	}*/

	if(NewButton & IN_RELOAD)
	{	
		if(pev_valid(Ent)) set_pdata_int(Ent, 54, 0, 4)
		
		NewButton &= ~IN_RELOAD
		set_uc(uc_handle, UC_Buttons, NewButton)
		if(cs_get_weapon_ammo(Ent) < Clip)
			ExecuteHamB(Ham_Weapon_Reload, Ent)

		return
	}
}

public event_newround()
{
	new nextitem  = find_ent_by_class(-1, "bouncer_ball")
	while(nextitem)
	{
		remove_entity(nextitem)
		nextitem = find_ent_by_class(-1, "bouncer_ball")
	}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_player(id, 1))
		return FMRES_IGNORED	
	if(get_player_weapon(id) == CSW_BOUNCER && Get_BitVar(g_Had_Bouncer, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_player(invoker, 0))
		return FMRES_IGNORED		
	if(get_player_weapon(invoker) == CSW_BOUNCER && Get_BitVar(g_Had_Bouncer, invoker) && eventid == g_Event_Bouncer)
	{
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)	

		Set_WeaponAnim(invoker, ANIM_SHOOT1_A)
		emit_sound(invoker, CHAN_WEAPON, WeaponShoots, 1.0, ATTN_NORM, 0, PITCH_LOW)	
	
		return FMRES_SUPERCEDE
	}
	
	return FMRES_HANDLED
}

public fw_TraceAttack(Ent, Attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	if(!is_player(Attacker, 0))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_BOUNCER || !Get_BitVar(g_Had_Bouncer, Attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]
	
	get_tr2(ptr, TR_vecEndPos, flEnd)
	get_tr2(ptr, TR_vecPlaneNormal, vecPlane)	

	CreateBouncerBall(Attacker, flEnd)
	
	//And Block it. Won't let it shot.
	return HAM_SUPERCEDE
}

public fw_Weapon_PrimaryAttack_Post( ent )
{
	static id ; id = get_pdata_cbase(ent, m_pPlayer, XTRA_OFS_WEAPON)	
	
	if(!is_user_alive(id) || !is_user_connected(id))
		return HAM_IGNORED
		
	if(get_user_weapon(id) != CSW_BOUNCER|| !Get_BitVar(g_Had_Bouncer, id))
		return HAM_IGNORED

	/*static total_shoot; total_shoot = random_num(5, 8)

	for(new i; i < total_shoot; i++)
		CreateBouncerBall(id)*/

	return HAM_IGNORED
}

public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_Had_Bouncer, Id))
		return

	set_pev(Id, pev_viewmodel2, V_MODEL)
	set_pev(Id, pev_weaponmodel2, P_MODEL)
	
	Set_WeaponAnim(Id, ANIM_DRAW_A)
}

public fw_Item_AddToPlayer_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED

	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		Set_BitVar(g_Had_Bouncer, id)
		set_pev(ent, pev_impulse, 0)
	}
	return HAM_HANDLED	
}

public fw_Weapon_WeaponIdle( iEnt )
{
	if(pev_valid(iEnt) != 2)
		return 
	static id; id = get_pdata_cbase(iEnt, m_pPlayer, XTRA_OFS_WEAPON)
	if(get_pdata_cbase(id, 373) != iEnt)
		return
	if(!Get_BitVar(g_Had_Bouncer, id))
		return
	
	if( get_pdata_float(iEnt, m_flTimeWeaponIdle, XTRA_OFS_WEAPON) > 0.0 )
	{
		return
	}
	
	static iId ; iId = get_pdata_int(iEnt, m_iId, XTRA_OFS_WEAPON)
	static iMaxClip ; iMaxClip = CLIP

	static iClip ; iClip = get_pdata_int(iEnt, m_iClip, XTRA_OFS_WEAPON)
	static fInSpecialReload ; fInSpecialReload = get_pdata_int(iEnt, m_fInSpecialReload, XTRA_OFS_WEAPON)

	if( !iClip && !fInSpecialReload )
	{
		return
	}

	if( fInSpecialReload )
	{
		static iBpAmmo ; iBpAmmo = get_pdata_int(id, 381, XTRA_OFS_PLAYER)
		static iDftMaxClip ; iDftMaxClip = g_iDftMaxClip[iId]

		if( iClip < iMaxClip && iClip == iDftMaxClip && iBpAmmo )
		{
			Shotgun_Reload(iEnt, iMaxClip, iClip, iBpAmmo, id)
			return
		}
		else if( iClip == iMaxClip && iClip != iDftMaxClip )
		{
			Set_WeaponAnim(id, ANIM_AFTER_A)
			
			set_pdata_int(iEnt, m_fInSpecialReload, 0, XTRA_OFS_WEAPON)
			set_pdata_float(iEnt, m_flTimeWeaponIdle, 1.5, XTRA_OFS_WEAPON)
		}
	}
	
	return
}

public fw_Weapon_WeaponIdle_Post( iEnt )
{
	if(pev_valid(iEnt) != 2)
		return 
	static id; id = get_pdata_cbase(iEnt, m_pPlayer, XTRA_OFS_WEAPON)
	if(get_pdata_cbase(id, 373) != iEnt)
		return
	if(!Get_BitVar(g_Had_Bouncer, id))
		return
		
	static SpecialReload; SpecialReload = get_pdata_int(iEnt, 55, 4)
	if(!SpecialReload && get_pdata_float(iEnt, 48, 4) <= 0.25)
	{
		Set_WeaponAnim(id, ANIM_IDLE_A)
		set_pdata_float(iEnt, 48, 20.0, 4)
	}	
}

public fw_Weapon_Reload(iEnt) 
{ 
	static id ; id = get_pdata_cbase(iEnt, m_pPlayer, XTRA_OFS_WEAPON)	 

	if(get_player_weapon(id) != CSW_BOUNCER|| !Get_BitVar(g_Had_Bouncer, id))
		return HAM_SUPERCEDE 
		
	static iBpAmmo ; iBpAmmo = get_pdata_int(id, 381, XTRA_OFS_PLAYER) 
	static iClip ; iClip = get_pdata_int(iEnt, m_iClip, XTRA_OFS_WEAPON) 
	static iMaxClip ; iMaxClip = CLIP

	Shotgun_Reload(iEnt, iMaxClip, iClip, iBpAmmo, id) 
	return HAM_SUPERCEDE 
}

public CreateBouncerBall(id, Float:End[3])
{
	if(!Get_BitVar(g_Had_Bouncer, id))
		return
		
	new Float:Origin[3], Float:Angles[3], Float:Velocity[3]
	static Float:StartOrigin[3]
	get_position(id, 0.0, 0.0, 0.0, StartOrigin)

	new Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	engfunc(EngFunc_GetAttachment, id, 0, Origin, Angles)

	pev(id, pev_v_angle, Angles)//; Angles[0] *= -1.0

	entity_set_string(Ent, EV_SZ_classname, "bouncer_ball")
	set_pev(Ent, pev_origin, StartOrigin)
	set_pev(Ent, pev_angles, Angles)
	//set_pev(Ent, pev_solid, SOLID_BBOX)
	set_pev(Ent, pev_solid, SOLID_TRIGGER)
	set_pev(Ent, pev_gravity, 0.01)
	set_pev(Ent, pev_movetype, MOVETYPE_BOUNCE)
	set_pev(Ent, pev_classname, "bouncer_ball")
	set_pev(Ent, pev_angles, Angles)
	set_pev(Ent, pev_owner, id)
	set_pev(Ent, pev_frame, 0.0)
	//set_pev(Ent, pev_fuser4, get_gametime()+5.0)
	engfunc(EngFunc_SetModel, Ent,  BALL_MODEL)
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
	
	set_pev(Ent, pev_mins, {-2.0, -2.0, -2.0})
	set_pev(Ent, pev_maxs, {2.0, 2.0, 2.0})
	//randomize_origin_increase(TargetOrigin, Angles, -15.0, 15.0, TargetOrigin)

	get_speed_vector(StartOrigin, End, float(SPEED), Velocity)
	set_pev(Ent, pev_velocity, Velocity)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // Temporary entity ID
	write_short(Ent) // Entity
	write_short(m_spriteTexture) // Sprite index
	write_byte(3) // Life
	write_byte(1) // Line width
	write_byte(10)
	write_byte(229)
	write_byte(255)
	write_byte(100) // Alpha
	message_end() 
	set_pev(Ent, pev_iuser4, 0)
}
/*
public CreateBouncerBall(id)
{
	new Float:Origin[3], Float:Angles[3], Float:Velocity[3]
	static Float:StartOrigin[3], Float:TargetOrigin[3]
	get_position(id, 2.0, 0.0, 0.0, StartOrigin)

	new Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	engfunc(EngFunc_GetAttachment, id, 0, Origin, Angles)

	pev(id, pev_v_angle, Angles); Angles[0] *= -1.0

	set_pev(Ent, pev_origin, StartOrigin)
	set_pev(Ent, pev_solid, SOLID_BBOX)
	set_pev(Ent, pev_angles, Angles)
	set_pev(Ent, pev_gravity, 0.01)
	set_pev(Ent, pev_movetype, MOVETYPE_BOUNCE)
	set_pev(Ent, pev_classname, "bouncer_ball")
	set_pev(Ent, pev_owner, id)
	set_pev(Ent, pev_frame, 0.0)
	set_pev(Ent, pev_model, BALL_MODEL)

	set_pev(Ent, pev_mins, {-1.0, -1.0, -1.0})
	set_pev(Ent, pev_maxs, {1.0, 1.0, 1.0})

	fm_get_aim_origin(id, TargetOrigin)
	get_speed_vector(StartOrigin, TargetOrigin, 2000.0, Velocity)
	set_pev(Ent, pev_velocity, Velocity)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // Temporary entity ID
	write_short(Ent) // Entity
	write_short(m_spriteTexture) // Sprite index
	write_byte(7) // Life
	write_byte(1) // Line width
	write_byte(10)
	write_byte(229)
	write_byte(255)
	write_byte(100) // Alpha
	message_end() 
	set_pev(Ent, pev_iuser4, 0)
}*/

public fw_think(ent)
{
	if(!pev_valid(ent))
		return

	if(pev(ent, pev_solid) != SOLID_TRIGGER)
		set_pev(ent, pev_solid, SOLID_TRIGGER)

	set_pev(ent, pev_nextthink, get_gametime() + 0.001)
}

public fw_touch(Ent, Id)
{
	// If ent is valid
	if(!pev_valid(Ent))
		return

	static classnameptd[32],Float:org[3]
	pev(Id, pev_classname, classnameptd, 31)
	if(equal(classnameptd, "bouncer_ball"))
		return
	
	static Owner; Owner = pev(Ent, pev_owner)
	if(Id == Owner)
		return

	static Touched_Time; Touched_Time = pev(Ent, pev_iuser4)+1
	if(Touched_Time > BOUNCETIME)
	{
		engfunc(EngFunc_SetModel, Ent, "")
		remove_entity(Ent)
		return
	}

	if(is_user_alive(Id))
	{ 
		if(Id == Owner)
			return 
		if(!zp_get_user_zombie(Id))
			return 
		pev(Id, pev_origin, org)
		make_blood(org)
		ExecuteHamB(Ham_TakeDamage, Id, Owner, Owner, is_deadlyshot(Id)?random_float(DAMAGE-10.0,DAMAGE+10.0)+1.5:random_float(DAMAGE-10.0,DAMAGE+10.0), DMG_BULLET)
	}	
	set_pev(Ent, pev_iuser4, Touched_Time)
}

Shotgun_Reload(iEnt, iMaxClip, iClip, iBpAmmo, id) 
{ 
	if(iBpAmmo <= 0 || iClip == iMaxClip) 
		return 

	if(get_pdata_int(iEnt, m_flNextPrimaryAttack, XTRA_OFS_WEAPON) > 0.0) 
		return 

	switch( get_pdata_int(iEnt, m_fInSpecialReload, XTRA_OFS_WEAPON) ) 
	{ 
		case 0: 
		{ 
			Set_WeaponAnim(id, ANIM_START_A) 
		 
			set_pdata_int(iEnt, m_fInSpecialReload, 1) 
			set_pdata_float(id, m_flNextAttack, RELOAD_TIME) 
			set_pdata_float(iEnt, m_flTimeWeaponIdle, RELOAD_TIME) 
			set_pdata_float(iEnt, m_flNextPrimaryAttack, RELOAD_TIME) 
			set_pdata_float(iEnt, m_flNextSecondaryAttack, RELOAD_TIME) 
			return 
		} 
		case 1: 
		{	
			if( get_pdata_float(iEnt, m_flTimeWeaponIdle) > 0.0 ) 
				return 	

			set_pdata_int(iEnt, m_fInSpecialReload, 2) 
			 
			//emit_sound(id, CHAN_ITEM, random_num(0,1) ? "weapons/reload1.wav" : "weapons/reload3.wav", 1.0, ATTN_NORM, 0, 85 + random_num(0,0x1f)) 
			Set_WeaponAnim(id, ANIM_INSERT_A) 

			//set_pdata_float(iEnt, m_flTimeWeaponIdle, iId == CSW_XM1014 ? 0.30 : 0.45, XTRA_OFS_WEAPON) 
			set_pdata_float(iEnt, m_flNextReload, RELOAD_TIME);
			set_pdata_float(iEnt, m_flTimeWeaponIdle, RELOAD_ANIMATION_TIME) 
		} 
		default: 
		{ 
			set_pdata_int(iEnt, m_iClip, iClip + 1) 
			set_pdata_int(id, 381, iBpAmmo-1) 
			set_pdata_int(iEnt, m_fInSpecialReload, 1) 
		} 
	} 
}  

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	static Float:num; num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}

stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock Set_Weapon_Idle(id, WeaponId ,Float:TimeIdle)
{
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, 4)
}

stock Set_Player_NextAttack(id, Float:NextTime) set_pdata_float(id, 83, NextTime, 5)

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

stock randomize_origin_increase(Float:Origin[3], Float:Angles[3], Float:MinDif, Float: MaxDif, Float:Out[])
{
	static Float:vForward[3], Float:vRight[3], Float:vUp[3], Float:right, Float:up
	angle_vector(Angles,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(Angles,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(Angles,ANGLEVECTOR_UP,vUp)

	right = random_float(MinDif, MaxDif)
	up = random_float(MinDif, MaxDif)

	Out[0] = Origin[0] + vForward[0] + vRight[0] * right + vUp[0] * up
	Out[1] = Origin[1] + vForward[1] + vRight[1] * right + vUp[1] * up
	Out[2] = Origin[2] + vForward[2] + vRight[2] * right + vUp[2] * up
}

stock get_angle_to_target(id, const Float:fTarget[3], Float:TargetSize = 0.0)
{
	static Float:fOrigin[3], iAimOrigin[3], Float:fAimOrigin[3], Float:fV1[3]
	pev(id, pev_origin, fOrigin)
	get_user_origin(id, iAimOrigin, 3) // end position from eyes
	IVecFVec(iAimOrigin, fAimOrigin)
	xs_vec_sub(fAimOrigin, fOrigin, fV1)
	
	static Float:fV2[3]
	xs_vec_sub(fTarget, fOrigin, fV2)
	
	static iResult; iResult = get_angle_between_vectors(fV1, fV2)
	
	if (TargetSize > 0.0)
	{
		static Float:fTan; fTan = TargetSize / get_distance_f(fOrigin, fTarget)
		static fAngleToTargetSize; fAngleToTargetSize = floatround( floatatan(fTan, degrees) )
		iResult -= (iResult > 0) ? fAngleToTargetSize : -fAngleToTargetSize
	}
	
	return iResult
}

stock get_angle_between_vectors(const Float:fV1[3], const Float:fV2[3])
{
	static Float:fA1[3], Float:fA2[3]
	engfunc(EngFunc_VecToAngles, fV1, fA1)
	engfunc(EngFunc_VecToAngles, fV2, fA2)
	
	static iResult; iResult = floatround(fA1[1] - fA2[1])
	iResult = iResult % 360
	iResult = (iResult > 180) ? (iResult - 360) : iResult
	
	return iResult
}
/* ===============================
------------- SAFETY -------------
=================================*/
public Register_SafetyFunc()
{
	register_event("CurWeapon", "Safety_CurWeapon", "be", "1=1")
	
	RegisterHam(Ham_Spawn, "player", "fw_Safety_Spawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_Safety_Killed_Post", 1)
}

public Register_SafetyFuncBot(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Safety_Spawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fw_Safety_Killed_Post", 1)
}

public Safety_Connected(id)
{
	Set_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	
	g_PlayerWeapon[id] = 0
}

public Safety_Disconnected(id)
{
	UnSet_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	
	g_PlayerWeapon[id] = 0
}

public Safety_CurWeapon(id)
{
	if(!is_player(id, 1))
		return
		
	static CSW; CSW = read_data(2)
	if(g_PlayerWeapon[id] != CSW) g_PlayerWeapon[id] = CSW
}

public fw_Safety_Spawn_Post(id)
{
	if(!is_user_alive(id))
		return
		
	Set_BitVar(g_IsAlive, id)
	Remove_Bouncer(id)
}

public fw_Safety_Killed_Post(id)
{
	UnSet_BitVar(g_IsAlive, id)
}

public is_player(id, IsAliveCheck)
{
	if(!(1 <= id <= 32))
		return 0
	if(!Get_BitVar(g_IsConnected, id))
		return 0
	if(IsAliveCheck)
	{
		if(Get_BitVar(g_IsAlive, id)) return 1
		else return 0
	}
	
	return 1
}

public get_player_weapon(id)
{
	if(!is_player(id, 1))
		return 0
	
	return g_PlayerWeapon[id]
}
const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

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

/* ===============================
--------- End of SAFETY ----------
=================================*/

public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(get_user_weapon(iAttacker) == CSW_BOUNCER)
	{
		if(Get_BitVar(g_Had_Bouncer, iAttacker))
			set_msg_arg_string(4, "bouncer")
	}
                
	return PLUGIN_CONTINUE
}

stock make_blood(Float:origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]+15))
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(248)
	write_byte(8)
	message_end()
}
