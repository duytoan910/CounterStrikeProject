#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>
#include <toan> 

#define PLUGIN "[CSO] PlasmaGun"
#define VERSION "1.0"
#define AUTHOR "Dias Leon"

// ================= Config =================
// ZP Config
#define COST 6000

// Level 1 Config
#define V_MODEL "models/v_plasmagun.mdl"
#define P_MODEL "models/p_plasmagun.mdl"
#define W_MODEL "models/w_plasmagun.mdl"

#define V_MODEL_6 "models/v_plasmagun_6.mdl"

new const WeaponSounds[2][] =
{
	"weapons/plasmagun-1.wav",
	"weapons/plasmagun_exp.wav"
}

new const plasma_ball[] = "sprites/plasmaball.spr"
new const plasma_bomb[] = "sprites/plasmabomb.spr"
new const plasma_ball_6[] = "sprites/plasmaball_6.spr"
new const plasma_bomb_6[] = "sprites/plasmabomb_6.spr"

// Level 2 Config
#define DAMAGE 125
#define CLIP 45
#define BPAMMO 200
#define SPEED 1.5
#define RECOIL 0.8

#define PLASMA_SPEED 1500.0
#define PLASMA_RADIUS 100.0

// Level 3 Config
#define CSW_PLASMA CSW_AK47
#define weapon_plasma "weapon_ak47"

#define WEAPON_EVENT "events/ak47.sc"
#define WEAPON_ANIMEXT "carbine"
#define WEAPON_OLD_WMODEL "models/w_ak47.mdl"
#define WEAPON_SECRETCODE 1946

#define WEAPONANIM_SHOOT random_num(3, 5)
#define WEAPONANIM_RELOAD 1

#define WEAPONTIME_DRAW 0.75
#define WEAPONTIME_RELOAD 3.5

// Level 4 Config
#define PLASMABALL_CLASSNAME "plasmaball"
// ============== End of Config ==============

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

enum
{
	TEAM_T = 1,
	TEAM_CT
}

// Vars
new g_PlasmaGun
new g_Had_Plasma, g_WeaponClip[33], Float:g_WeaponRecoil[33][3]
new g_skin[33]
new g_PlasmaExp_SprId, g_PlasmaExp_SprId_6, g_weapon_event, g_HamBot 

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	register_forward(FM_SetModel, "fw_SetModel")		
	
	register_think(PLASMABALL_CLASSNAME, "fw_Think_Plasma")
	register_touch(PLASMABALL_CLASSNAME, "*", "fw_Touch_Plasma")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_plasma, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_plasma, "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_Deploy, weapon_plasma, "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_plasma, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_plasma, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_plasma, "fw_Weapon_Reload_Post", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon_plasma, "fw_Item_AddToPlayer_Post", 1)	
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	
	g_PlasmaGun = zp_register_extra_item("PlasmaGun", COST, ZP_TEAM_HUMAN)
}
 public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(get_user_weapon(iAttacker) == CSW_PLASMA)
	{
		if(Get_BitVar(g_Had_Plasma, iAttacker))
			set_msg_arg_string(4, "plasmagun")
	}
                
	return PLUGIN_CONTINUE
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	engfunc(EngFunc_PrecacheModel, V_MODEL_6)
	
	new i
	for(i = 0; i < sizeof(WeaponSounds); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
	
	engfunc(EngFunc_PrecacheModel, plasma_ball)
	g_PlasmaExp_SprId = engfunc(EngFunc_PrecacheModel, plasma_bomb)
	engfunc(EngFunc_PrecacheModel, plasma_ball_6)
	g_PlasmaExp_SprId_6 = engfunc(EngFunc_PrecacheModel, plasma_bomb_6)
		
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(WEAPON_EVENT, name)) g_weapon_event = get_orig_retval()		
}

public client_putinserver(id)
{
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Do_RegisterHam", id)
	}
}

public Do_RegisterHam(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Player")	
	RegisterHamFromEntity(Ham_Spawn, id, "Player_Spawn")
}

public zp_extra_item_selected(id, ItemID)
{
	if(ItemID == g_PlasmaGun) Get_Plasma(id)
}

public zp_user_infected_post(id) Remove_Plasma(id)
public zp_user_humanized_post(id) Remove_Plasma(id)

public Get_Plasma(id)
{
	if(!is_user_alive(id))
		return

	drop_weapons(id, 1)
	g_skin[id] = random_num(0,1)
	new iWep2 = fm_give_item(id,weapon_plasma)
	if( iWep2 > 0 )
	{
		set_pev(id, pev_viewmodel2, g_skin[id]?V_MODEL_6:V_MODEL)
		set_pev(id, pev_weaponmodel2, P_MODEL)
		
		set_pdata_string(id, (492) * 4, WEAPON_ANIMEXT, -1 , 20)
		
		cs_set_weapon_ammo( iWep2, CLIP )
		cs_set_user_bpammo (id, CSW_PLASMA, 200)
		Set_BitVar(g_Had_Plasma, id)
	}
}

public Remove_Plasma(id)
{
	UnSet_BitVar(g_Had_Plasma, id)
}
public Player_Spawn(id)
{
	UnSet_BitVar(g_Had_Plasma, id)
}
public Event_NewRound() remove_entity_name(PLASMABALL_CLASSNAME)

public fw_Think_Plasma(Ent)
{
	if(!pev_valid(Ent))
		return
		
	static Float:RenderAmt; pev(Ent, pev_renderamt, RenderAmt)
	
	RenderAmt += 50.0
	RenderAmt = float(clamp(floatround(RenderAmt), 0, 255))
	
	set_pev(Ent, pev_renderamt, RenderAmt)
	set_pev(Ent, pev_nextthink, halflife_time() + 0.1)
}

public fw_Touch_Plasma(Ent, id)
{
	if(!pev_valid(Ent))
		return
	if(pev(Ent, pev_movetype) == MOVETYPE_NONE)
		return
		
	// Exp Sprite
	static Float:Origin[3], TE_FLAG
	pev(Ent, pev_origin, Origin)
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	new iOwner = pev(Ent, pev_iuser1)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_skin[iOwner]?g_PlasmaExp_SprId_6:g_PlasmaExp_SprId)
	write_byte(7)
	write_byte(30)
	write_byte(TE_FLAG)
	message_end()	
	
	// Exp Sound
	emit_sound(Ent, CHAN_BODY, WeaponSounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	Damage_Plasma(Ent, id)
	
	// Remove Ent
	set_pev(Ent, pev_flags, pev(Ent, pev_flags) | FL_KILLME);
}

public Damage_Plasma(Ent, id)
{
	static Owner; Owner = pev(Ent, pev_iuser1)
	static Attacker; 
	static Org[3];
	pev(Ent, pev_origin, Org)
	
	if(!is_user_alive(Owner)) 
	{
		Attacker = 0
		return
	} else Attacker = Owner	
	
	new a = FM_NULLENT
	
	while((a = find_ent_in_sphere(a, Float:Org, PLASMA_RADIUS)) != 0)
	{
		if(!is_user_alive(a))
			continue 
		if (Attacker == a)
			continue 
		if(!is_user_alive(a))
			continue
		if(!zp_get_user_zombie(a))
			continue	
			
		if(pev(a, pev_takedamage) != DAMAGE_NO)
		{
			ExecuteHamB(Ham_TakeDamage, a, Attacker, Attacker, is_deadlyshot(Attacker)?random_float(DAMAGE-15.0,DAMAGE+15.0)*1.5:random_float(DAMAGE-15.0,DAMAGE+15.0), DMG_BULLET)
		}
	}
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_PLASMA && Get_BitVar(g_Had_Plasma, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_PLASMA || !Get_BitVar(g_Had_Plasma, invoker))
		return FMRES_IGNORED
	if(eventid != g_weapon_event)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	return FMRES_SUPERCEDE
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
	
	if(equal(model, WEAPON_OLD_WMODEL))
	{
		static weapon; weapon = fm_find_ent_by_owner(-1, weapon_plasma, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_Had_Plasma, iOwner))
		{
			Remove_Plasma(iOwner)
			
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			set_pev(weapon, pev_iuser4, g_skin[iOwner])
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_PLASMA || !Get_BitVar(g_Had_Plasma, Attacker))
		return HAM_IGNORED
	
	return HAM_SUPERCEDE
}

public fw_TraceAttack_Player(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_PLASMA || !Get_BitVar(g_Had_Plasma, Attacker))
		return HAM_IGNORED
		
	return HAM_SUPERCEDE
}

public fw_Weapon_PrimaryAttack(Ent)
{
	if(!pev_valid(Ent))
		return
		
	static id; id = pev(Ent, pev_owner)
	if(!Get_BitVar(g_Had_Plasma, id))
		return
	static Ammo; Ammo = cs_get_weapon_ammo(Ent)
	if(Ammo <= 0) return

	// Weapon Shoot
	Set_Weapon_Anim(id, WEAPONANIM_SHOOT)
	emit_sound(id, CHAN_WEAPON, WeaponSounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	// Create Plasma Effect
	Create_PlasmaBall(id)
	
	// Speed & Recoil
	pev(Ent, pev_punchangle, g_WeaponRecoil[id])
}

public fw_Weapon_PrimaryAttack_Post(Ent)
{
	if(!pev_valid(Ent))
		return
		
	static id; id = pev(Ent, pev_owner)
	if(!Get_BitVar(g_Had_Plasma, id))
		return
	static Ammo; Ammo = cs_get_weapon_ammo(Ent)
	if(Ammo <= 0) return
	
	// Speed & Recoil
	set_pdata_float(Ent, 46, get_pdata_float(Ent, 46, 4) * SPEED, 4)
	
	static Float:Push[3]; pev(id, pev_punchangle, Push)
	
	xs_vec_sub(Push, g_WeaponRecoil[id], Push)
	xs_vec_mul_scalar(Push, RECOIL, Push)
	xs_vec_add(Push,  g_WeaponRecoil[id], Push)

	set_pev(id, pev_punchangle, Push)
}

public fw_Item_Deploy_Post(Ent)
{
	if(!pev_valid(Ent))
		return
		
	static id; id = pev(Ent, pev_owner)
	if(!Get_BitVar(g_Had_Plasma, id))
		return
		
	set_pev(id, pev_viewmodel2, g_skin[id]?V_MODEL_6:V_MODEL)
	set_pev(id, pev_weaponmodel2, P_MODEL)
	
	set_pdata_string(id, (492) * 4, WEAPON_ANIMEXT, -1 , 20)
	
	// Set Draw
	set_pdata_float(id, 83, 0.8, 5)
	Set_Weapon_TimeIdle(id, CSW_PLASMA, 0.8)
	Set_Weapon_Anim(id ,2)		
}

public fw_Item_PostFrame(Ent)
{
	if(!pev_valid(Ent))
		return
		
	static id; id = pev(Ent, pev_owner)
	if(!Get_BitVar(g_Had_Plasma, id))
		return
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_PLASMA)
	static iClip; iClip = get_pdata_int(Ent, 51, 4)

	if(get_pdata_int(Ent, 54, 4) && flNextAttack <= 0.0)
	{
		static temp1; temp1 = min(CLIP - iClip, bpammo)

		set_pdata_int(Ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_PLASMA, bpammo - temp1)		
		
		set_pdata_int(Ent, 54, 0, 4)
	}		
}

public fw_Weapon_Reload(Ent)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	static id; id = pev(Ent, pev_owner)
	if(!Get_BitVar(g_Had_Plasma, id))
		return HAM_IGNORED
		
	g_WeaponClip[id] = -1
	
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_PLASMA)
	static iClip; iClip = get_pdata_int(Ent, 51, 4)
	
	if(bpammo <= 0) return HAM_SUPERCEDE
	if(iClip >= CLIP) return HAM_SUPERCEDE
		
	g_WeaponClip[id] = iClip
	return HAM_IGNORED
}

public fw_Weapon_Reload_Post(Ent)
{
	if(!pev_valid(Ent))
		return
		
	static id; id = pev(Ent, pev_owner)
	if(!Get_BitVar(g_Had_Plasma, id))
		return
	if(g_WeaponClip[id] == -1)
		return
	
	set_pdata_int(Ent, 51, g_WeaponClip[id], 4)
	set_pdata_int(Ent, 54, 1, 4)
	
	Set_Weapon_Anim(id, WEAPONANIM_RELOAD)
	set_pdata_float(id, 83, WEAPONTIME_RELOAD, 5)
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return
		
	if(pev(Ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		Set_BitVar(g_Had_Plasma, id)
		set_pev(Ent, pev_impulse, 0)
		g_skin[id] = pev(Ent, pev_iuser4)
		
		set_task(0.01, "AddToPlayer_Delay", id)
	}
	return
}

public AddToPlayer_Delay(id)
{
	set_pev(id, pev_viewmodel2, g_skin[id]?V_MODEL_6:V_MODEL)
	set_pev(id, pev_weaponmodel2, P_MODEL)
	
	//set_pdata_float(id, 83, 0.1, 5)
	Set_Weapon_Anim(id ,2)
	set_pdata_string(id, (492) * 4, WEAPON_ANIMEXT, -1 , 20)	
}
		
public Create_PlasmaBall(id)
{
	static Float:StartOrigin[3], Float:TargetOrigin[3], Float:MyVelocity[3], Float:VecLength
	
	get_position(id, 48.0, 10.0, -5.0, StartOrigin)
	//get_position(id, 0.0, 0.0, 0.0, StartOrigin)
	get_position(id, 1024.0, 0.0, 0.0, TargetOrigin)
	
	pev(id, pev_velocity, MyVelocity)
	VecLength = vector_length(MyVelocity)
	
	if(VecLength) 
	{
		TargetOrigin[0] += random_float(-16.0, 16.0); TargetOrigin[1] += random_float(-16.0, 16.0); TargetOrigin[2] += random_float(-16.0, 16.0)
	} else {
		TargetOrigin[0] += random_float(-8.0, 8.0); TargetOrigin[1] += random_float(-8.0, 8.0); TargetOrigin[2] += random_float(-8.0, 8.0)
	}
	
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Ent)) return
	
	// Set info for ent
	set_pev(Ent, pev_movetype, MOVETYPE_FLY)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 100.0)
	set_pev(Ent, pev_iuser1, id) // Better than pev_owner
	set_pev(Ent, pev_iuser2, Get_SpecialTeam(id, cs_get_user_team(id)))
	set_pev(Ent, pev_fuser1, get_gametime() + 3.0)
	set_pev(Ent, pev_scale, random_float(0.1, 0.25))
	set_pev(Ent, pev_nextthink, halflife_time() + 0.1)
	
	entity_set_string(Ent, EV_SZ_classname, PLASMABALL_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, g_skin[id]?plasma_ball_6:plasma_ball)
	set_pev(Ent, pev_mins, Float:{-1.5, -1.5, -1.5})
	set_pev(Ent, pev_maxs, Float:{1.5, 1.5, 1.5})
	set_pev(Ent, pev_origin, StartOrigin)
	set_pev(Ent, pev_gravity, 0.01)
	set_pev(Ent, pev_solid, SOLID_BBOX)
	set_pev(Ent, pev_frame, 0.0)
	
	static Float:Velocity[3]
	if(is_user_bot(id))
	{
		get_speed_vector(StartOrigin, TargetOrigin, 3500.0, Velocity)
	}else	get_speed_vector(StartOrigin, TargetOrigin, PLASMA_SPEED, Velocity)
	set_pev(Ent, pev_velocity, Velocity)
}
public Get_SpecialTeam(Ent, CsTeams:Team)
{
	if(Team == CS_TEAM_T) return TEAM_T
	else if(Team == CS_TEAM_CT) return TEAM_CT
	
	return 0
}

public CsTeams:Get_PlasmaTeam(Ent)
{
	if(pev(Ent, pev_iuser2) == TEAM_T) return CS_TEAM_T
	else if(pev(Ent, pev_iuser2) == TEAM_CT) return CS_TEAM_CT
	
	return CS_TEAM_UNASSIGNED
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

stock Set_Weapon_TimeIdle(id, WeaponId, Float:TimeIdle)
{
	static Ent; Ent = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(Ent)) return
		
	set_pdata_float(Ent, 46, TimeIdle, 4)
	set_pdata_float(Ent, 47, TimeIdle, 4)
	set_pdata_float(Ent, 48, TimeIdle + 0.5, 4)
}

stock Set_Player_NextAttack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
}

stock Set_Weapon_Anim(id, WeaponAnim)
{
	set_pev(id, pev_weaponanim, WeaponAnim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(WeaponAnim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
stock drop_weapons(id, dropwhat)
{
     static weapons[32], num, i, weaponid
     num = 0
     get_user_weapons(id, weapons, num)
     
     for (i = 0; i < num; i++)
     {
          weaponid = weapons[i]
          
          if (dropwhat == 1 && ((1<<weaponid) & ((1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90))))
          {
               static wname[32]
               get_weaponname(weaponid, wname, sizeof wname - 1)
               engclient_cmd(id, "drop", wname)
          }
     }
}
