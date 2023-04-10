#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define PLUGIN "Magnum Drill 3in1"
#define VERSION "1.0"
#define AUTHOR "Asdian"

// Data Config
enum _:ModelType
{
	MODEL_P = 0,
	MODEL_P2 = 2,
	MODEL_V = 4,
	MODEL_W = 6
}

new const WeaponModels[][] =
{
	"models/p_sgdrill.mdl",
	"models/p_sgdrillgold.mdl",
	
	"models/p_sgdrill_slash.mdl",
	"models/p_sgdrillgold_slash.mdl",
	
	"models/v_sgdrill.mdl",
	"models/v_sgdrillgold.mdl",
	
	"models/w_sgdrill.mdl"
}

#define MODEL_W_OLD "models/w_xm1014.mdl"

new const ShootSounds[][] =
{
	"weapons/sgdrill-1.wav",
	"weapons/sgdrill_slash.wav",
	"weapons/sgdrill_pslash.wav"
}

#define CSW_SGDRILL CSW_XM1014
#define weapon_sgdrill "weapon_xm1014"

#define WEAPON_CODE 7272018
#define WEAPON_EVENT "events/xm1014.sc"

enum _:NewAnim
{
	SGDRILL_IDLE = 0,
	SGDRILL_SHOOT,
	SGDRILL_SLASH,
	SGDRILL_RELOAD,
	SGDRILL_DRAW
}

// Weapon Config
#define DAMAGE 1.4
#define ACCURACY 23 // 0 - 100 ; -1 Default
#define CLIP 40
#define BPAMMO 200
#define SPEED 0.25
#define RECOIL 0.5
#define RELOAD_TIME 2.9

#define SLASH_ANGLE 45.0
#define SLASH_RANGE 150.0
#define SLASH_DAMAGE 1562.0
#define SLASH_KNOCKBACK 500.0

new g_Had_Base[33], g_iType[33], g_Clip[33], g_OldWeapon[33], Float:g_Recoil[33][3]
new g_Sgd //g_Event_Base, 
	
// Safety
new g_HamBot, iBlood[2]
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33]

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

//Hit
#define	RESULT_HIT_NONE 			0
#define	RESULT_HIT_PLAYER			1
#define	RESULT_HIT_WORLD			2

native navtive_bullet_effect(id, ent, ptr)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Safety
	Register_SafetyFunc()
	
	// Event
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	// Forward
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	//register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_SetModel, "fw_SetModel")
	
	// Ham
	RegisterHam(Ham_Item_Deploy, weapon_sgdrill, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_AddToPlayer, weapon_sgdrill, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_sgdrill, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_sgdrill, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_sgdrill, "fw_Weapon_Reload_Post", 1)	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_sgdrill, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_sgdrill, "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	// Cache
	register_clcmd("weapon_sgdrill", "hook_weapon")
	register_clcmd("weapon_sgdrillgold", "hook_weapon")
	
	g_Sgd = zp_register_extra_item("Magnum Drill", 3000, ZP_TEAM_HUMAN)
	//g_Sgd[1] = zp_register_extra_item("\r(+6) Magnum Drill Chimera", 10, ZP_TEAM_HUMAN)
	//g_Sgd[2] = zp_register_extra_item("Transcendence Magnum Drill Gold", 10, ZP_TEAM_HUMAN)
}

public hook_weapon(id) engclient_cmd(id, weapon_sgdrill)

public plugin_precache()
{
	new i
	for(i = 0; i < sizeof(WeaponModels); i++) precache_model(WeaponModels[i])
	for(i = 0; i < sizeof(ShootSounds); i++) precache_sound(ShootSounds[i])
	iBlood[0] = precache_model("sprites/bloodspray.spr");
	iBlood[1] = precache_model("sprites/blood.spr");
	
	//register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64]
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	
	if (strcmp(szWeapon, "xm1014"))
		return PLUGIN_CONTINUE
	
	new id = get_msg_arg_int(1)
	new iEntity = get_pdata_cbase(id, 373)
	
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != CSW_SGDRILL || !g_Had_Base[id])
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, "sgdrill")
	return PLUGIN_CONTINUE
}
public client_putinserver(id)
{
        Safety_Connected(id)
	
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Register_HamBot", id)
	}
}
 
public Register_HamBot(id)
{
	Register_SafetyFuncBot(id)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Player")	
}
public client_disconnect(id)
{
        Safety_Disconnected(id)
}

public zp_extra_item_selected(i, d) 
{
	if(d == g_Sgd) Get_Base(i, random_num(0,1))
}

public zp_user_infected_post(i) Remove_Base(i)
public zp_user_humanized_post(i) Remove_Base(i)

public Get_Base(id, type)
{
	drop_weapons(id, 1)
	
	if(g_Had_Base[id]) Remove_Base(id)
	g_Had_Base[id] = 1
	g_iType[id] = type
	
	fm_give_item(id, weapon_sgdrill)
	
	// Clip & Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_SGDRILL)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, CLIP)
	cs_set_user_bpammo(id, CSW_SGDRILL, BPAMMO)
}

public Remove_Base(id)
{
	g_Had_Base[id] = 0
}

public Event_CurWeapon(id)
{
	static CSWID; CSWID = read_data(2)
	
	if((CSWID == CSW_SGDRILL && g_OldWeapon[id] != CSW_SGDRILL) && g_Had_Base[id])
	{
		 Draw_NewWeapon(id, CSWID)
	} else if((CSWID == CSW_SGDRILL && g_OldWeapon[id] == CSW_SGDRILL) && g_Had_Base[id]) {
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_SGDRILL)
		if(!pev_valid(Ent))
		{
			g_OldWeapon[id] = get_user_weapon(id)
			return
		}
		
		set_pdata_float(Ent, 46, SPEED, 4)
		set_pdata_float(Ent, 47, SPEED, 4)
	} else if(CSWID != CSW_SGDRILL && g_OldWeapon[id] == CSW_SGDRILL) {
		Draw_NewWeapon(id, CSWID)
	}
	
	g_OldWeapon[id] = get_user_weapon(id)
}

public Draw_NewWeapon(id, CSW_ID)
{
	if(CSW_ID == CSW_SGDRILL)
	{
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_SGDRILL)
		
		if(pev_valid(ent) && g_Had_Base[id])
		{
			//set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW)
			engfunc(EngFunc_SetModel, ent, WeaponModels[MODEL_P + g_iType[id]])
		}
	}	
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_SGDRILL && g_Had_Base[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

#if 0
public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_connected(invoker))
		return FMRES_IGNORED	
	if(get_player_weapon(invoker) != CSW_SGDRILL || !g_Had_Base[invoker])
		return FMRES_IGNORED
	if(eventid != g_Event_Base)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	Set_WeaponAnim(invoker, SGDRILL_SHOOT)
	
	emit_sound(invoker, CHAN_WEAPON, ShootSounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	return FMRES_SUPERCEDE
}
#endif

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
	
	if(equal(model, MODEL_W_OLD))
	{
		static weapon; weapon = find_ent_by_owner(-1, weapon_sgdrill, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(g_Had_Base[iOwner])
		{
			set_pev(weapon, pev_iuser2, cs_get_user_bpammo(iOwner, CSW_SGDRILL))
			set_pev(weapon, pev_iuser3, get_pdata_int(weapon, 51, 4))
			set_pev(weapon, pev_iuser4, g_iType[iOwner])
			
			set_pev(weapon, pev_impulse, WEAPON_CODE)
			engfunc(EngFunc_SetModel, entity, WeaponModels[MODEL_W])
			
			set_pev(entity, pev_body, g_iType[iOwner])
			Remove_Base(iOwner)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
		
	static Id
	Id = get_pdata_cbase(Ent, 41, 4)
	
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!g_Had_Base[Id])
		return
	
	set_pev(Id, pev_viewmodel2, WeaponModels[MODEL_V + g_iType[Id]])
	set_pev(Id, pev_weaponmodel2, WeaponModels[MODEL_P + g_iType[Id]])
	Set_WeaponAnim(Id, SGDRILL_DRAW)

	set_pev(Ent, pev_iuser1, 0)
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == WEAPON_CODE)
	{
		g_Had_Base[id] = 1
		g_iType[id] = pev(Ent, pev_iuser4)
		
		static iMaxClip; iMaxClip = pev(Ent, pev_iuser3)
		static iBpAmmo; iBpAmmo = pev(Ent, pev_iuser2)
		set_pdata_int(Ent, 51, iMaxClip, 4)
		cs_set_user_bpammo(id, CSW_SGDRILL, iBpAmmo)
		
		set_pev(Ent, pev_impulse, 0)
	}
	
	return HAM_IGNORED	
}

public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_Had_Base[id])
		return HAM_IGNORED	
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_SGDRILL)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	static iMaxClip; iMaxClip = CLIP
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(iMaxClip - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		
		cs_set_user_bpammo(id, CSW_SGDRILL, bpammo - temp1)	
		
		set_pdata_int(ent, 54, 0, 4)
		fInReload = 0
	}	
	
	WE_SGDrill(id, ent, iClip,bpammo,pev(id, pev_button))
	if(is_user_bot(id))
	{
		new enemy, body
		get_user_aiming(id, enemy, body)
		if ((1 <= enemy <= 32) && zp_get_user_zombie(enemy))
		{
			new origin1[3] ,origin2[3],range
			get_user_origin(id,origin1)
			get_user_origin(enemy,origin2)
			range = get_distance(origin1, origin2)
			if(range <= SLASH_RANGE+20.0) WE_SGDrill(id, ent, iClip,bpammo,IN_ATTACK2)
		}		
	}
	return HAM_IGNORED
}

public WE_SGDrill(id,iEnt,iClip, bpammo,iButton)
{
	if (get_pdata_float(iEnt, 46, 4) <= 0.0)
	{
		if (iButton & IN_ATTACK2 && iButton & ~IN_ATTACK)
		{
			set_pdata_float(id, 83, 0.6, 5)
			set_pdata_float(iEnt, 46, 1.5, 4)
			set_pdata_float(iEnt, 47, 1.5, 4)
			set_pdata_float(iEnt, 48, 1.8, 4)

			set_pev(iEnt, pev_iuser1, 1)
			set_pev(iEnt, pev_fuser4, get_pdata_float(id, 83) + get_gametime())

			set_pev(id, pev_weaponmodel2, WeaponModels[MODEL_P2 + g_iType[id]])
			Set_WeaponAnim(id, SGDRILL_SLASH)
			emit_sound(id, CHAN_WEAPON, ShootSounds[random_num(1,2)], 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		iButton &= ~IN_ATTACK2;
		set_pev(id, pev_button, iButton);
	}

	if (get_pdata_float(id, 83, 5) <= 0.0 && pev(iEnt, pev_iuser1) == 1)
	{
		new Float:flOrigin[3]
		pev(id, pev_origin, flOrigin)
		
		for(new i=1;i<get_maxplayers();i++)
		{
			if(!is_user_alive(i))
				continue
			if(i==id)
				continue
			if(!zp_get_user_zombie(i))
				continue
			if(!can_see_fm(id,i))
				continue
				
			new Float:flVictimOrigin[3]
			pev(i,pev_origin,flVictimOrigin)
			
			if(!is_in_viewcone(id, flVictimOrigin))
				continue
				
			new Float:flDistance=get_distance_f(flOrigin,flVictimOrigin)
			
			if(flDistance<=SLASH_RANGE)
			{
				ExecuteHamB(Ham_TakeDamage, i ,id ,id,  is_deadlyshot(id)?random_float(SLASH_DAMAGE-100,SLASH_DAMAGE+100)*1.5:random_float(SLASH_DAMAGE-100,SLASH_DAMAGE+100), DMG_BULLET)
				
				flOrigin[2] -=100.0				
				static Float:flVelocity[3]
				Create_Blood(flVictimOrigin, iBlood[0], iBlood[1], 248, random_num(8,15));
				get_speed_vector(flOrigin,flVictimOrigin,SLASH_KNOCKBACK,flVelocity)				
				set_pev(i,pev_velocity,flVelocity)
			}
		}
		set_pev(id, pev_weaponmodel2, WeaponModels[MODEL_P + g_iType[id]])
		set_pev(iEnt, pev_iuser1, 0)	
	}
}
public fw_Weapon_Reload(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_Had_Base[id])
		return HAM_IGNORED	

	g_Clip[id] = -1
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_SGDRILL)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static iMaxClip; iMaxClip = CLIP
	
	if(BPAmmo <= 0 || iClip >= iMaxClip)
		return HAM_SUPERCEDE
			
	g_Clip[id] = iClip
	return HAM_IGNORED
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_Had_Base[id])
		return HAM_IGNORED	
	if(g_Clip[id] == -1)
		return HAM_IGNORED
		
	set_pdata_int(ent, 51, g_Clip[id], 4)
	set_pdata_int(ent, 54, 1, 4)
	
	Set_WeaponAnim(id, SGDRILL_RELOAD)
	Set_PlayerNextAttack(id, RELOAD_TIME)
	return HAM_IGNORED
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_SGDRILL)
		{
			if(g_Had_Base[attacker])
			{
				SetHamParamFloat(4, damage * DAMAGE)
			}
		}
	}
}
public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_SGDRILL || !g_Had_Base[Attacker])
		return HAM_IGNORED
		
	navtive_bullet_effect(Attacker, Victim, Ptr)
	
	return HAM_HANDLED
}

public fw_TraceAttack_Player(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_SGDRILL || !g_Had_Base[Attacker])
		return HAM_IGNORED

	return HAM_HANDLED
}

public fw_Weapon_PrimaryAttack(Ent)
{
	static id; id = pev(Ent, pev_owner)
	if(!is_alive(id))
		return HAM_IGNORED
	if(!g_Had_Base[id])
		return HAM_IGNORED

	pev(id, pev_punchangle, g_Recoil[id])
	return HAM_IGNORED
}

public fw_Weapon_PrimaryAttack_Post(Ent)
{
	static id; id = pev(Ent, pev_owner)
	if(!is_alive(id))
		return
	if(!g_Had_Base[id])
		return

	static Float:Push[3]
	pev(id, pev_punchangle, Push)
	xs_vec_sub(Push, g_Recoil[id], Push)
	
	xs_vec_mul_scalar(Push, RECOIL, Push)
	xs_vec_add(Push, g_Recoil[id], Push)
	
	set_pev(id, pev_punchangle, Push)
	
	// Acc
	static Accena; Accena = ACCURACY
	if(Accena != -1)
	{
		static Float:Accuracy
		Accuracy = (float(100 - ACCURACY) * 1.5) / 100.0

		set_pdata_float(Ent, 62, Accuracy, 4);
	}
	
	Set_WeaponAnim(id, SGDRILL_SHOOT)
	emit_sound(id, CHAN_WEAPON, ShootSounds[0], VOL_NORM, ATTN_NORM, 0, random_num(95,120))
	
	set_pdata_float(id, 111, get_gametime())
}
stock Create_Blood(const Float:vStartTMP[3], const iModel, const iModel2, const iColor, const iScale)
{
	static vStart[3];
	vStart[0] = floatround(vStartTMP[0])
	vStart[1] = floatround(vStartTMP[1])
	vStart[2] = floatround(vStartTMP[2])
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vStart, 0);
	write_byte(TE_BLOODSPRITE);
	write_coord(vStart[0])
	write_coord(vStart[1])
	write_coord(vStart[2])
	write_short(iModel);
	write_short(iModel2);
	write_byte(iColor);
	write_byte(iScale);
	message_end();
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
	if(!is_alive(id))
		return
		
	static CSW; CSW = read_data(2)
	if(g_PlayerWeapon[id] != CSW) g_PlayerWeapon[id] = CSW
}

public fw_Safety_Spawn_Post(id)
{
	if(!is_user_alive(id))
		return
		
	Set_BitVar(g_IsAlive, id)
	Remove_Base(id)
}

public fw_Safety_Killed_Post(id)
{
	UnSet_BitVar(g_IsAlive, id)
}

public is_connected(id)
{
	if(!(1 <= id <= 32))
		return 0
	if(!Get_BitVar(g_IsConnected, id))
		return 0

	return 1
}

public is_alive(id)
{
	if(!is_connected(id))
		return 0
	if(!Get_BitVar(g_IsAlive, id))
		return 0
		
	return 1
}

public get_player_weapon(id)
{
	if(!is_alive(id))
		return 0
	
	return g_PlayerWeapon[id]
}

/* ===============================
--------- END OF SAFETY  ---------
=================================*/

stock Set_WeaponAnim(id, anim, iCheck=0)
{
	if(iCheck && pev(id, pev_weaponanim) == anim)
		return;

	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock Make_BulletHole(id, Float:Origin[3])
{
	// Find target
	static Decal; Decal = random_num(41, 45)

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
stock Set_PlayerNextAttack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
}
////////////
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
		
		if (dropwhat == 1 && ((1<<weaponid) & ((1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)
		|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)
		|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90))))
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
/////////

/* ===============================
------------- DAMAGES ------------
=================================*/
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
