#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <zombieplague>

#define PLUGIN "[CSO] Thanatos-7"
#define VERSION "1.0"
#define AUTHOR "Dias no Pendragon"

#define DAMAGE_A 66 // 66 for zombie
#define DAMAGE_B 18.0 // 250 for zombie

#define CLIP 120

#define V_MODEL "models/v_thanatos7.mdl"
#define P_MODEL "models/p_thanatos7.mdl"
#define W_MODEL "models/w_thanatos7.mdl"
#define S_MODEL "models/thanatos7_scythe.mdl"

new const WeaponSounds[][] =
{
	"weapons/thanatos7-1.wav",
	"weapons/thanatos7_scytheshoot.wav"
}

enum
{
	ANIM_IDLE_A = 0,
	ANIM_IDLE_B,
	ANIM_IDLE_B2,
	ANIM_SHOOT_A1,
	ANIM_SHOOT_B1,
	ANIM_SHOOT_A2,
	ANIM_SHOOT_B2,
	ANIM_RELOAD_A,
	ANIM_RELOAD_B,
	ANIM_SPECIAL_SHOOT,
	ANIM_SPECIAL_RELOAD,
	ANIM_DRAW_A,
	ANIM_DRAW_B
}

#define TASK_RELOAD 12115
#define SCYTHE_CLASSNAME "scythe"

#define CSW_THANATOS7 CSW_M249
#define weapon_thanatos7 "weapon_m249"

// Fire Start
#define THANATOS7_OLDMODEL "models/w_m249.mdl"

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_Had_Thanatos7, g_Thanatos7_Clip[33], g_Had_Scythe
new g_MsgStatusIcon
new g_Event_Thanatos7, g_HamBot
new g_thanatos7

native navtive_bullet_effect(id, ent, ptr)

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	
	register_forward(FM_UpdateClientData,"fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	register_forward(FM_SetModel, "fw_SetModel")		
	register_forward(FM_CmdStart, "fw_CmdStart")	
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	
	register_touch(SCYTHE_CLASSNAME, "*", "fw_Scythe_Touch")
	
	RegisterHam(Ham_Item_Deploy, weapon_thanatos7, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_AddToPlayer, weapon_thanatos7, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_thanatos7, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_thanatos7, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_thanatos7, "fw_Weapon_Reload_Post", 1)	
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_thanatos7, "fw_Weapon_WeaponIdle_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_thanatos7, "fw_Weapon_PrimaryAttack", 1)
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)	
	RegisterHam(Ham_Item_Holster, weapon_thanatos7, "HolsterPost", 1)
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")	
	
	g_MsgStatusIcon = get_user_msgid("StatusIcon")
	
	g_thanatos7 = zp_register_extra_item("Thanatos-VII", 3000, ZP_TEAM_HUMAN) 
}

public plugin_precache()
{
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_model(W_MODEL)
	precache_model(S_MODEL)
	
	for(new i = 0; i < sizeof(WeaponSounds); i++)
		precache_sound(WeaponSounds[i])

	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal("events/m249.sc", name)) g_Event_Thanatos7 = get_orig_retval()		
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
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Player")
	RegisterHamFromEntity(Ham_Spawn, id, "Player_Spawn")
}

public Event_NewRound() remove_entity_name(SCYTHE_CLASSNAME)

public zp_extra_item_selected(id, itemid) 
{ 
	if(itemid == g_thanatos7) Get_Thanatos7(id)
} 
public Get_Thanatos7(id)
{
	drop_weapons(id, 1)
	
	Set_BitVar(g_Had_Thanatos7, id)
	UnSet_BitVar(g_Had_Scythe, id)
	give_item(id, weapon_thanatos7)
	
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_THANATOS7)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, CLIP)
	Update_SpecialAmmo(id, 1, 0)
	
	cs_set_user_bpammo(id, CSW_THANATOS7, 200)
}

public Player_Spawn(id)
{
	Remove_Thanatos7(id) 
}

public zp_user_infected_post(id) 
{ 
	Remove_Thanatos7(id) 
} 
public Remove_Thanatos7(id)
{
	if(is_user_connected(id)) 
		Update_SpecialAmmo(id, 1, 0)
	
	UnSet_BitVar(g_Had_Thanatos7, id)
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_THANATOS7 && Get_BitVar(g_Had_Thanatos7, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_THANATOS7 || !Get_BitVar(g_Had_Thanatos7, invoker))
		return FMRES_IGNORED
	if(eventid != g_Event_Thanatos7)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	if(Get_BitVar(g_Had_Scythe, invoker)) Set_WeaponAnim(invoker, ANIM_SHOOT_B1)
	else Set_WeaponAnim(invoker, ANIM_SHOOT_A1)
	emit_sound(invoker, CHAN_WEAPON, WeaponSounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)

	return FMRES_IGNORED
}

public Update_SpecialAmmo(id, Ammo, On)
{
	static AmmoSprites[33]
	format(AmmoSprites, sizeof(AmmoSprites), "number_%d", Ammo)

	message_begin(MSG_ONE_UNRELIABLE, g_MsgStatusIcon, {0,0,0}, id)
	write_byte(On)
	write_string(AmmoSprites)
	write_byte(42) // red 
	write_byte(212) // green 
	write_byte(255) // blue 
	message_end()
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[32]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, THANATOS7_OLDMODEL))
	{
		static weapon; weapon = find_ent_by_owner(-1, weapon_thanatos7, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_Had_Thanatos7, iOwner))
		{
			set_pev(weapon, pev_impulse, 1212015)
			set_pev(weapon, pev_iuser4, Get_BitVar(g_Had_Scythe, iOwner) ? 1 : 0)
			
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			Remove_Thanatos7(iOwner)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_THANATOS7 || !Get_BitVar(g_Had_Thanatos7, id))
		return FMRES_IGNORED
		
	static PressedButton
	PressedButton = get_uc(uc_handle, UC_Buttons)
	
	if(PressedButton & IN_ATTACK2)
	{
		if(get_pdata_float(id, 83, 5) > 0.0)
			return FMRES_IGNORED
		

		if(!Get_BitVar(g_Had_Scythe, id))
		{
			Set_WeaponAnim(id, ANIM_SPECIAL_RELOAD)
			set_pdata_float(id, 83, 3.0, 5)
			
			remove_task(id+TASK_RELOAD)
			set_task(2.9, "Complete_Reload", id+TASK_RELOAD)
			set_task(3.0, "Complete_Reload2", id+TASK_RELOAD)
		} else {
			Shoot_Scythe(id)
		}
	}
		
	return FMRES_HANDLED
}

public Shoot_Scythe(id)
{
	emit_sound(id, CHAN_WEAPON, WeaponSounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	Set_WeaponAnim(id, ANIM_SPECIAL_SHOOT)
	
	Update_SpecialAmmo(id, 1, 0)
	set_pdata_float(id, 83, 4.0, 5)
	
	UnSet_BitVar(g_Had_Scythe, id)
	
	// Fake Punch
	static Float:Origin[3]
	Origin[0] = random_float(-2.5, -5.0)
	
	set_pev(id, pev_punchangle, Origin)
	
	// Scythe
	Create_Scythe(id)
}

public Complete_Reload(id)
{
	id -= TASK_RELOAD
	
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_THANATOS7 || !Get_BitVar(g_Had_Thanatos7, id))
		return
	if(Get_BitVar(g_Had_Scythe, id))
		return
		
	Set_BitVar(g_Had_Scythe, id)	
	Update_SpecialAmmo(id, 1, 1)
}
public Complete_Reload2(id)
{
	id -= TASK_RELOAD
	
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_THANATOS7 || !Get_BitVar(g_Had_Thanatos7, id))
		return
	if(Get_BitVar(g_Had_Scythe, id))
		return
		
	Set_WeaponAnim(id, ANIM_IDLE_B2)
}
public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_Had_Thanatos7, Id))
		return
	
	set_pev(Id, pev_viewmodel2, V_MODEL)
	set_pev(Id, pev_weaponmodel2, P_MODEL)
	
	if(Get_BitVar(g_Had_Scythe, Id))
	{
		Set_WeaponAnim(Id, ANIM_DRAW_B)
		Update_SpecialAmmo(Id, 1, 1)
	}else{
		Set_WeaponAnim(Id, ANIM_DRAW_A)
		Update_SpecialAmmo(Id, 1, 0)
	}
	set_pdata_float(Id, 83, 2.0, 5)
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 1212015)
	{
		Set_BitVar(g_Had_Thanatos7, id)
		set_pev(Ent, pev_impulse, 0)
		
		if(pev(Ent, pev_iuser4)) Update_SpecialAmmo(id, 1, 1)
	}

	return HAM_HANDLED	
}

public fw_Weapon_WeaponIdle_Post( iEnt )
{
	if(pev_valid(iEnt) != 2)
		return
	static Id; Id = get_pdata_cbase(iEnt, 41, 4)
	if(get_pdata_cbase(Id, 373) != iEnt)
		return
	if(!Get_BitVar(g_Had_Thanatos7, Id))
		return
		
	if(get_pdata_float(iEnt, 48, 4) <= 0.25)
	{
		if(Get_BitVar(g_Had_Scythe, Id)) Set_WeaponAnim(Id, ANIM_IDLE_B)
		else Set_WeaponAnim(Id, ANIM_IDLE_A)
		
		set_pdata_float(iEnt, 48, 20.0, 4)
	}	
}

public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_THANATOS7 || !Get_BitVar(g_Had_Thanatos7, Attacker))
		return HAM_IGNORED
		
	navtive_bullet_effect(Attacker, Victim, Ptr)		

	SetHamParamFloat(3, float(DAMAGE_A))
	
	return HAM_IGNORED
}

public fw_TraceAttack_Player(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_THANATOS7 || !Get_BitVar(g_Had_Thanatos7, Attacker))
		return HAM_IGNORED
		
	SetHamParamFloat(3, float(DAMAGE_A))
	
	return HAM_IGNORED
}

public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Thanatos7, id))
		return HAM_IGNORED	
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_THANATOS7)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(CLIP - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_THANATOS7, bpammo - temp1)		
		
		set_pdata_int(ent, 54, 0, 4)
		
		fInReload = 0
	}		
	
	return HAM_IGNORED
}
static g_shot[33]
public fw_Weapon_PrimaryAttack(wpn) 
{
	static id; id = pev(wpn, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Thanatos7, id))
		return HAM_IGNORED		
	if(!is_user_bot(id))
		return HAM_IGNORED
		
	g_shot[id]++
	if(g_shot[id]>=100)
	{
		Shoot_Scythe(id)
		g_shot[id] = 0
	}
	return HAM_IGNORED	
}
public fw_Weapon_Reload(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Thanatos7, id))
		return HAM_IGNORED	

	g_Thanatos7_Clip[id] = -1
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_THANATOS7)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
		
	if(BPAmmo <= 0)
		return HAM_SUPERCEDE
	if(iClip >= CLIP)
		return HAM_SUPERCEDE		
			
	g_Thanatos7_Clip[id] = iClip	
	
	return HAM_HANDLED
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Thanatos7, id))
		return HAM_IGNORED	
		
	if((get_pdata_int(ent, 54, 4) == 1))
	{ // Reload
		if(g_Thanatos7_Clip[id] == -1)
			return HAM_IGNORED
		
		set_pdata_int(ent, 51, g_Thanatos7_Clip[id], 4)
		set_pdata_float(id, 83, 3.2, 5)
		
		if(Get_BitVar(g_Had_Scythe, id)) Set_WeaponAnim(id, ANIM_RELOAD_B)
		else Set_WeaponAnim(id, ANIM_RELOAD_A)
	}
	
	return HAM_HANDLED
}

public HolsterPost(wpn)
{
	static id
	id = get_pdata_cbase(wpn, 41, 4)
	if(!Get_BitVar(g_Had_Thanatos7, id))
		return HAM_IGNORED	
		
	Update_SpecialAmmo(id, 1, 0)	
	return HAM_IGNORED	
}
public Create_Scythe(id)
{
	new iEnt = create_entity("info_target")
	
	static Float:Origin[3], Float:Angles[3], Float:TargetOrigin[3], Float:Velocity[3]
	
	get_weapon_attachment(id, Origin, 40.0)
	get_position(id, 1024.0, 0.0, 0.0, TargetOrigin)
	
	pev(id, pev_v_angle, Angles)
	Angles[0] *= -1.0

	// set info for ent
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
	entity_set_string(iEnt, EV_SZ_classname, SCYTHE_CLASSNAME)
	engfunc(EngFunc_SetModel, iEnt, S_MODEL)
	
	set_pev(iEnt, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(iEnt, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(iEnt, pev_origin, Origin)
	set_pev(iEnt, pev_gravity, 0.01)
	set_pev(iEnt, pev_angles, Angles)
	set_pev(iEnt, pev_solid, SOLID_BBOX) 
	set_pev(iEnt, pev_owner, id)	
	get_speed_vector(Origin, TargetOrigin, 750.0, Velocity)
	set_pev(iEnt, pev_velocity, Velocity)	
	
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)
	
	// Animation
	set_pev(iEnt, pev_animtime, get_gametime())
	set_pev(iEnt, pev_framerate, 2.0)
	set_pev(iEnt, pev_sequence, 0)
}

public fw_Scythe_Touch(Ent, id)
{
	// If ent is valid 
	if(!pev_valid(Ent)) 
		return 
	if(pev(Ent, pev_movetype) == MOVETYPE_NONE) 
		return 
		 
	set_pev(Ent, pev_movetype, MOVETYPE_NONE) 
	set_pev(Ent, pev_solid, SOLID_NOT) 
	entity_set_float(Ent, EV_FL_nextthink, halflife_time() + 0.1) 
	 
	set_task(0.0, "action_scythe", Ent) 
	set_task(10.0, "remove", Ent) 
}
public remove(Ent) 
{ 
	if(!pev_valid(Ent)) 
		return 
		 
	remove_entity(Ent) 
} 

public action_scythe(Ent) 
{ 
	if(!pev_valid(Ent)) 
		return 
		 
	Damage_scythe(Ent) 
} 

public Damage_scythe(Ent) 
{ 
	if(!pev_valid(Ent)) 
		return 
	 
	static id; id = pev(Ent, pev_owner) 
	new Float:origin[3] 
	pev(Ent, pev_origin, origin) 
	 
	// Alive... 
	new a = FM_NULLENT 
	// Get distance between victim and epicenter 
	while((a = find_ent_in_sphere(a, origin, 70.0)) != 0) 
	{ 
		if (id == a) 
			continue 
	 
		ExecuteHamB(Ham_TakeDamage, a, id, id, ((is_deadlyshot(id)?1.5:1.0)*random_float(DAMAGE_B-10.0, DAMAGE_B+10.0)), DMG_BULLET)
	} 
	set_task(0.1, "action_scythe", Ent) 
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
			static wname[32]; get_weaponname(weaponid, wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
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

public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
		
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
		
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
		
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
		
	if(get_user_weapon(iAttacker) == CSW_THANATOS7)
	{
		if(Get_BitVar(g_Had_Thanatos7, iAttacker))
			set_msg_arg_string(4, "thanatos7")
	}
				
	return PLUGIN_CONTINUE
}
