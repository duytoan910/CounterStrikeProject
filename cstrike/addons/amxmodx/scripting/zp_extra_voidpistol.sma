#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <xs>
#include <zombieplague>
#include <toan>

#define PLUGIN "Void Avenger"
#define VERSION "1.2"
#define AUTHOR "Mellowzy"

#define SHOOT_MAX 120
#define DAMAGE_A 58.0
#define DAMAGE_B 58.0
#define DAMAGE_C 58.0
#define DAMAGE_HOLE 45.0

#define DEFAULT_CLIP 50
#define DEFAULT_BPAMMO 200
#define RELOAD_TIME 3.3
#define FIRE_SPEED 0.2

#define MAXDIST 600.0
#define RANGE_BLACKHOLE 500.0
#define SPEED_BLACKHOLE 900.0
#define BLACKHOLE_TIME 5.0

#define WP_BASEON CSW_TMP
#define wp_baseon_classname "weapon_tmp"
#define weapon_event "events/tmp.sc"
#define old_w_model "models/w_tmp.mdl"
#define WP_KEY 221132

#define muzzleflash "sprites/muzzleflash140.spr"
#define muzzleflash2 "sprites/muzzleflash141.spr"
#define MF_W "sprites/ef_blackhole04.spr"

// Safety
new g_HamBot
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33]

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new const wp_model[][] = {
	"models/v_voidpistol.mdl",
	"models/p_voidpistol.mdl",
	"models/w_voidpistol.mdl",
	"sprites/ef_blackhole_projectile.spr", //3
	"models/ef_blackhole.mdl" //4
}

new const wp_sound[][] = {
	"weapons/voidpistol-1.wav",//5 0
	"weapons/voidpistol-2.wav",//6 1
	"weapons/voidpistol_beep.wav",//8 2
	"weapons/voidpistol_blackhole_start.wav",//15 3
	"weapons/voidpistol_blackhole_idle.wav",//16 4 
	"weapons/voidpistol_blackhole_exp.wav",//17 5
	"weapons/voidpistol_blackhole_c_idle.wav"//18 6
}

new const spr_ef[][] = {
	"sprites/ef_blackhole_start.spr",//0
	"sprites/ef_blackhole_loop.spr",//1
	"sprites/ef_blackhole_end.spr",//2
	"sprites/ef_blackhole04.spr"//3
}

enum
{
	ANIM_IDLEA = 0,
	ANIM_IDLEB,
	ANIM_IDLEC,
	ANIM_SHOOTA,
	ANIM_SHOOTB,
	ANIM_SHOOTC,
	ANIM_SHOOT_BLACKHOLEA,
	ANIM_SHOOT_BLACKHOLEB,
	ANIM_RELOADA,
	ANIM_RELOADB,
	ANIM_RELOADC,
	ANIM_SCANNING_ON,
	ANIM_SCANNING_OFF,
	ANIM_CHANGE_AC,
	ANIM_CHANGE_BC,
	ANIM_DRAWA,
	ANIM_DRAWB,
	ANIM_DRAWC	
}

// HardCode
new g_had_wp[33], m_iBlood[2], Float:g_recoil[33], g_clip[33], g_itemid
new g_Event_FS,ef_star[2],g_OldWeapon[33]
new g_ShootCount[33]
new g_cachde_mf[2], Float:g_cache_frame_mf[2]
new bool:IsDetect,bool:isAttached,anim

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_MAC10)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_CheckVisibility, "fw_CheckVisibility")

	RegisterHam(Ham_Item_AddToPlayer, wp_baseon_classname, "ham_add_wp", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "ham_traceattack", 1)
	RegisterHam(Ham_TraceAttack, "player", "ham_traceattack", 1)
	
	RegisterHam(Ham_Think, "info_target", "HamF_InfoTarget_Think")
	RegisterHam(Ham_Touch, "info_target", "HamF_InfoTarget_Touch")
	RegisterHam(Ham_Think, "env_sprite",  "HamHook_Spr_Think");
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	RegisterHam(Ham_Weapon_WeaponIdle, wp_baseon_classname, "fw_Weapon_WeaponIdle_Post", 1)
	RegisterHam(Ham_Item_Deploy, wp_baseon_classname, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_PostFrame, wp_baseon_classname, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, wp_baseon_classname, "fw_Weapon_Reload")	
	RegisterHam(Ham_Weapon_Reload, wp_baseon_classname, "fw_Weapon_Reload_Post", 1)		
	RegisterHam(Ham_Weapon_PrimaryAttack, wp_baseon_classname, "fw_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, wp_baseon_classname, "fw_PrimaryAttack_Post", 1)
	
	register_concmd("wc_refill", "refill_ammo")
	
	g_itemid = zp_register_extra_item("Void Avenger", 15000, ZP_TEAM_HUMAN, 1)
}

public plugin_precache()
{
	for(new i = 0; i < sizeof(wp_model); i++)
		engfunc(EngFunc_PrecacheModel, wp_model[i])
	for(new i = 0; i < sizeof(wp_sound); i++)
		engfunc(EngFunc_PrecacheSound, wp_sound[i])
	for(new i = 0; i < sizeof(spr_ef); i++)
		engfunc(EngFunc_PrecacheModel, spr_ef[i])

	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	ef_star[0] = precache_model("sprites/ef_blackhole_star.spr")
	g_cachde_mf[0] = precache_model(MF_W)
	g_cache_frame_mf[0] = float(engfunc(EngFunc_ModelFrames, g_cachde_mf[0]))
	
	precache_model(muzzleflash)
	precache_model(muzzleflash2)
	precache_model("sprites/ef_blackhole04.spr")
	precache_model("sprites/voidpistol_aim.spr")
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}
public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64]
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	
	if (strcmp(szWeapon, "tmp"))
		return PLUGIN_CONTINUE
	
	new id = get_msg_arg_int(1)
	new iEntity = get_pdata_cbase(id, 373)
	
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != WP_BASEON || !g_had_wp[id])
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, "voidpistol")
	return PLUGIN_CONTINUE
}
public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(weapon_event, name)) g_Event_FS = get_orig_retval()		
}

public client_connect(id) 
{
	g_had_wp[id] = false
}

public client_disconnect(id) 
{
	g_had_wp[id] = false
}

public zp_user_humanized_post(id) 
{
	g_had_wp[id] = false
}

public zp_user_infected_post(id) 
{
	g_had_wp[id] = false
}

public zp_extra_item_selected(id, itemid) 
{
	if(itemid == g_itemid)
	{
		get_weapon(id)
	}
}

public get_weapon(id)
{
	g_had_wp[id] = 1
	Stock_Drop_Slot(id,1)
	g_ShootCount[id] = 0;

	give_item(id, wp_baseon_classname)
	IsDetect = false;
	isAttached=false;
	anim=0;
	
	// Clip & Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, WP_BASEON)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, DEFAULT_CLIP)
	cs_set_user_bpammo(id, WP_BASEON, DEFAULT_BPAMMO)
	
	ExecuteHamB(Ham_Item_Deploy, Ent)
	set_pdata_float(Ent, 38, get_gametime() + 0.5, 4)
	Set_PlayerNextAttack(id, 1.0)
	set_pev(Ent, pev_iuser4, 0)
}

public weapon_call(id) {
	engclient_cmd(id, wp_baseon_classname)
	return PLUGIN_HANDLED;
}

public refill_ammo(id) cs_set_user_bpammo(id, WP_BASEON, DEFAULT_BPAMMO)

public remove_weapon(id)
{
	g_had_wp[id] = 0
	g_ShootCount[id] = 0;
	IsDetect = false;
	isAttached=false;
	anim=0;
}

public hook_change(id)
{
	engclient_cmd(id, wp_baseon_classname)
	return PLUGIN_HANDLED
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
}
public event_checkweapon(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
	if(zp_get_user_zombie(id) || zp_get_user_survivor(id))
		return PLUGIN_HANDLED
	if(get_user_weapon(id) != WP_BASEON || !g_had_wp[id])
		return PLUGIN_HANDLED
		
	set_pev(id, pev_viewmodel2, wp_model[0])
	set_pev(id, pev_weaponmodel2, wp_model[1])

	return PLUGIN_HANDLED
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED
	if(zp_get_user_zombie(id) || zp_get_user_survivor(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != WP_BASEON || !g_had_wp[id])
		return FMRES_IGNORED
	
	set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_SetModel(ent, const model[])
{
	if(!is_valid_ent(ent))
		return FMRES_IGNORED
	
	static szClassName[33]
	entity_get_string(ent, EV_SZ_classname, szClassName, charsmax(szClassName))
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = entity_get_edict(ent, EV_ENT_owner)
	
	if(equal(model, old_w_model))
	{
		static at4cs
		at4cs = find_ent_by_owner(-1, wp_baseon_classname, ent)
		
		if(!is_valid_ent(at4cs))
			return FMRES_IGNORED;
		
		if(g_had_wp[iOwner])
		{
			entity_set_int(at4cs, EV_INT_impulse, WP_KEY)
			g_had_wp[iOwner] = 0
			entity_set_model(ent, wp_model[2])
			
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}


public Event_CurWeapon(id)
{
	static CSWID; CSWID = read_data(2)
	
	if((CSWID == WP_BASEON && g_OldWeapon[id] != WP_BASEON) && g_had_wp[id])
	{
		 Draw_NewWeapon(id, CSWID)
	} else if((CSWID == WP_BASEON && g_OldWeapon[id] == WP_BASEON) && g_had_wp[id]) {
		static Ent; Ent = fm_get_user_weapon_entity(id, WP_BASEON)
		if(!pev_valid(Ent))
		{
			g_OldWeapon[id] = get_user_weapon(id)
			return
		}
		
		if(!get_pdata_int(Ent, 55, 4))
		{
			set_pdata_float(Ent, 46, FIRE_SPEED, 4)
			set_pdata_float(Ent, 47, FIRE_SPEED, 4)
		}
	} else if(CSWID != WP_BASEON && g_OldWeapon[id] == WP_BASEON) {
		Draw_NewWeapon(id, CSWID)
	}
	
	g_OldWeapon[id] = get_user_weapon(id)
}
public Draw_NewWeapon(id, CSW_ID)
{
	if(CSW_ID == WP_BASEON)
	{
		static ent
		ent = fm_get_user_weapon_entity(id, WP_BASEON)
		
		if(pev_valid(ent) && g_had_wp[id])
			set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW) 
	} else {
		static ent, iFlame[2]
		ent = fm_get_user_weapon_entity(id, WP_BASEON)
		iFlame[0] = find_ent_by_class(id, "ef_bhole")
		iFlame[1] = find_ent_by_class(id, "voidpistol_aim")
		
		if(pev_valid(ent)) set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW) 
		if(pev_valid(iFlame[0])) set_pev(iFlame[0], pev_effects, pev(iFlame[0], pev_effects) | EF_NODRAW)
		if(pev_valid(iFlame[1])) set_pev(iFlame[1], pev_effects, pev(iFlame[1], pev_effects) | EF_NODRAW)
	}
	
}
public fw_CheckVisibility(iEnt, pSet)
{
	static classname[64]; pev(iEnt, pev_classname, classname, sizeof(classname))
	if(equal(classname, "wpn_muzzleflash"))
	{
		forward_return(FMV_CELL, 1)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public fw_Weapon_WeaponIdle_Post(Ent)
{
	new iState = pev(Ent, pev_iuser1)
	if(pev_valid(Ent) != 2)
		return HAM_IGNORED	
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return HAM_IGNORED	
	if(!g_had_wp[Id])
		return HAM_IGNORED	
		
	if(get_pdata_float(Ent, 48, 4) <= 0.1)
	{
		new EventCheck = pev(Ent, pev_iuser4)
		if(!EventCheck){
			set_weapon_anim(Id, !iState?ANIM_IDLEA : ANIM_IDLEB)
			
			static iFlame
			iFlame = find_ent_by_class(Id, "ef_bhole")
			if(pev_valid(iFlame)) set_pev(iFlame, pev_flags, FL_KILLME)
		}else{ set_weapon_anim(Id, ANIM_IDLEC); }
		
		set_pdata_float(Ent, 48, 20.0, 4)
	}
	
	return HAM_IGNORED	
}

public fw_Item_Deploy_Post(Ent)
{
	new iState = pev(Ent, pev_iuser1)
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!g_had_wp[Id])
		return
	
	set_pev(Id, pev_viewmodel2, wp_model[0])
	set_pev(Id, pev_weaponmodel2, wp_model[1])
	
	new EventCheck = pev(Ent, pev_iuser4)
	if(!EventCheck){
		set_weapon_anim(Id, !iState?ANIM_DRAWA:ANIM_DRAWB)
		set_pdata_float(Ent, 38, get_gametime() + 3.5, 4)
	}else{
		set_weapon_anim(Id, ANIM_DRAWC)
	}
	set_pdata_float(Ent, 38, get_gametime() + 0.5)
	set_pdata_float(Ent, 48, 1.5, 4)
	Additional_Deploy(Ent, Id)
}
public Additional_Deploy(ent, id)// Asdi, i borrow it ok :3
{
	set_pdata_int(ent, 55, 0, 4)
	
	static iFlame[3]
	iFlame[0] = find_ent_by_class(id, "ef_bhole")
	iFlame[1] = find_ent_by_class(id, "wpn_muzzleflash")
	iFlame[2] = find_ent_by_class(id, "voidpistol_aim")
	
	if(pev_valid(iFlame[0])) set_pev(iFlame[0], pev_effects, pev(iFlame[0], pev_effects) &~ EF_NODRAW)
	if(pev_valid(iFlame[1])) set_pev(iFlame[1], pev_effects, pev(iFlame[1], pev_effects) &~ EF_NODRAW)
	if(pev_valid(iFlame[2])) set_pev(iFlame[2], pev_effects, pev(iFlame[2], pev_effects) &~ EF_NODRAW)
}// but nothing work -_-

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != WP_BASEON || !g_had_wp[invoker])
		return FMRES_IGNORED
	if(eventid != g_Event_FS)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	return FMRES_IGNORED
}

public ham_add_wp(ent, id)
{
	if(entity_get_int(ent, EV_INT_impulse) == WP_KEY)
	{
		g_had_wp[id] = 1
	}

}

public ham_traceattack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker) || !is_user_connected(attacker))
		return HAM_IGNORED
	if(zp_get_user_zombie(attacker) || zp_get_user_survivor(attacker))
		return HAM_IGNORED
	if(get_user_weapon(attacker) != WP_BASEON || !g_had_wp[attacker])
		return HAM_IGNORED
	
	static Float:flEnd[3], Float:vecPlane[3]
	
	get_tr2(ptr, TR_vecEndPos, flEnd)
	get_tr2(ptr, TR_vecPlaneNormal, vecPlane)	
	new wpn = fm_get_user_weapon_entity(attacker, WP_BASEON)
		
	if(!is_user_alive(ent))
	{
		new EventCheck = pev(wpn, pev_iuser4)
		if(!EventCheck){
			make_bullet(attacker, flEnd)
			
			static Float:flEnd2[12][3]
			get_tr2(ptr, TR_vecEndPos, flEnd2)
		}
	} else {
		Weapon_ShootCound(attacker)
	}
		
	SetHamParamFloat(3, is_deadlyshot(attacker)?random_float(DAMAGE_A-5,DAMAGE_A+5)*1.5:random_float(DAMAGE_A-5,DAMAGE_A+5))	
	
	return HAM_HANDLED
}
public fw_PrimaryAttack(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!g_had_wp[id])
		return HAM_IGNORED
	
	set_pdata_int( ent, 64, -1)
	pev(id, pev_punchangle, g_recoil[id])
	
	return HAM_IGNORED	
}

public fw_PrimaryAttack_Post(ent)
{
	static id; id = pev(ent,pev_owner)
	new iState = pev(ent, pev_iuser1)
	new iClip = get_pdata_int(ent, 51, 4)
	
	new EventCheck = pev(ent, pev_iuser4)
	
	if(g_had_wp[id] && get_user_weapon(id) == WP_BASEON)
	{
		if(!iClip)
			return HAM_SUPERCEDE;
		
		static muz;muz = fm_find_ent_by_class(id, "wpn_muzzleflash")
		if(pev_valid(muz)) set_pev(muz, pev_effects, pev(muz, pev_effects) &~ EF_NODRAW)
		
		if(!EventCheck && anim != 2){
			if(iState)
			{
				set_weapon_anim(id, ANIM_SHOOTB)
				MakeMuzzleFlash(id, 1, 0.05, "wpn_muzzleflash", muzzleflash)
			}else{
				set_weapon_anim(id, ANIM_SHOOTA)
				MakeMuzzleFlash(id, 1, 0.05, "wpn_muzzleflash", muzzleflash)
			}
		}else{
			set_weapon_anim(id, ANIM_SHOOTC)
			MakeMuzzleFlash(id, 1, 0.05, "wpn_muzzleflash", muzzleflash2)
			
			emit_sound(id, CHAN_WEAPON, wp_sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			new Float:PlayerOrigin[3]; pev(id, pev_origin, PlayerOrigin)
			new i = -1;
			while((i = engfunc(EngFunc_FindEntityInSphere, i, PlayerOrigin, MAXDIST)) != 0)
			{
				if(!is_user_alive(i))continue
				if(!is_valid_ent(i))continue
				if(id==i)continue
				if(pev(i, pev_takedamage)==DAMAGE_NO)continue
				if(!can_damage(id, i))continue
				if(!zp_get_user_zombie(i))
					continue;
					
				ExecuteHamB(Ham_TakeDamage, i, fm_get_user_weapon_entity(id, WP_BASEON), id, is_deadlyshot(id)?random_float(DAMAGE_C-5,DAMAGE_C+5)*1.5:random_float(DAMAGE_C-5,DAMAGE_C+5), DMG_BULLET)
				
				static Float:vOrigin[3]; pev(i, pev_origin, vOrigin)
				create_blood(vOrigin)
			}
		}
		
		if(IsDetect)
		{
			emit_sound(id, CHAN_WEAPON, wp_sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
			emit_sound(id, CHAN_STATIC, wp_sound[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			
			new Float:PlayerOrigin[3]; pev(id, pev_origin, PlayerOrigin)
			new i = -1;
			while((i = engfunc(EngFunc_FindEntityInSphere, i, PlayerOrigin, MAXDIST)) != 0)
			{
				if(!is_user_alive(i))continue
				if(!pev_valid(i))continue
				if(id==i)continue
				if(!can_damage(id,i))continue
				if(pev(i, pev_takedamage)==DAMAGE_NO)continue
				if(!zp_get_user_zombie(i))
					continue;
				
				ExecuteHamB(Ham_TakeDamage, i, fm_get_user_weapon_entity(id, WP_BASEON), id, is_deadlyshot(id)?random_float(DAMAGE_B-5,DAMAGE_B+5)*1.5:random_float(DAMAGE_B-5,DAMAGE_B+5), DMG_BULLET)
				
				static Float:vOrigin[3]; pev(i, pev_origin, vOrigin)
				create_blood(vOrigin)
				Weapon_ShootCound(id)
			}
		}else{
			emit_sound(id, CHAN_WEAPON, wp_sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}
	
	set_pdata_float(ent, 48, 1.0, 4)
	
	return HAM_IGNORED
}
public fw_TakeDamage(Victim, Inflictor, Attacker, Float:fDamage, iDamageType)
{	
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != WP_BASEON || !g_had_wp[Attacker])
		return HAM_IGNORED
			
	if(is_user_alive(Victim) && Victim != Attacker && g_ShootCount[Attacker] < SHOOT_MAX)
	{
		static Wpn; Wpn = get_pdata_cbase(Attacker, 373)
		new EventCheck = pev(Wpn, pev_iuser4)
		Weapon_ShootCound(Attacker)
		
		if(EventCheck)return HAM_IGNORED
	}
	return HAM_IGNORED
}
public Weapon_ShootCound(id)
{
	static Wpn;Wpn = fm_get_user_weapon_entity(id, WP_BASEON)
	new EventCheck = pev(Wpn, pev_iuser4)
	
	if(EventCheck) return
	
	if(g_ShootCount[id] < SHOOT_MAX)
	{
		g_ShootCount[id] ++
		
		if(g_ShootCount[id] >= SHOOT_MAX) 
		{
			set_pev(Wpn, pev_iuser4, 1)
		}
	}
}
public MakeMuzzleFlash2(id, iBody)
{
	if(is_user_bot(id)) return;
	static iMuz
	iMuz = Stock_CreateEntityBase(id, "env_sprite", MOVETYPE_FOLLOW, MF_W, "ef_bhole", SOLID_NOT,0.01)
	set_pev(iMuz, pev_body, iBody)
	set_pev(iMuz, pev_rendermode, kRenderTransAdd)
	set_pev(iMuz, pev_renderamt, 255.0)
	set_pev(iMuz, pev_aiment, id)
	set_pev(iMuz, pev_scale, 0.05)
	set_pev(iMuz, pev_frame, 0.0)
	set_pev(iMuz, pev_animtime, get_gametime())
	set_pev(iMuz, pev_framerate, 1.0)
	dllfunc(DLLFunc_Spawn, iMuz)
}

public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	
	if(is_user_alive(id) && is_user_connected(id) && g_had_wp[id])
	{	
		static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
		static bpammo; bpammo = cs_get_user_bpammo(id, WP_BASEON)
	
		static iClip; iClip = get_pdata_int(ent, 51, 4)
		static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
		if(fInReload && flNextAttack <= 0.0)
		{
			static temp1
			temp1 = min(DEFAULT_CLIP - iClip, bpammo)

			set_pdata_int(ent, 51, iClip + temp1, 4)
			cs_set_user_bpammo(id, WP_BASEON, bpammo - temp1)		
		
			set_pdata_int(ent, 54, 0, 4)
		
			fInReload = 0
		}
		
		static Float:flLastEventCheck; flLastEventCheck = get_pdata_float(ent, 38, 4)
		
		static Float:Origin[3]; pev(id, pev_origin, Origin)
		new iState = pev(ent, pev_iuser1)
		new EventCheck = pev(ent, pev_iuser4)
		new Float:fSound; pev(ent, pev_fuser2, fSound)
		new Float:fTime; pev(ent, pev_fuser3, fTime)
		
		if(EventCheck && anim==1)
		{
			if(fTime < get_gametime()){
				MakeMuzzleFlash2(id,2)
				set_pev(ent, pev_fuser3, get_gametime() + 240.0)
			}
			
			if(fSound < get_gametime())
			{
				emit_sound(id, CHAN_VOICE, wp_sound[6], VOL_NORM,ATTN_NORM,0,PITCH_NORM)
				set_pev(ent, pev_fuser2, get_gametime() + 0.85)
			}
		}else{
			set_pev(ent, pev_fuser2, 0.0)
			set_pev(ent, pev_fuser3, 0.0)
		}
		
		if(flLastEventCheck < get_gametime()){
		
			flLastEventCheck = get_gametime() + 0.40
			set_pdata_float(ent, 38, flLastEventCheck, 4)
			void_buff(id, ent, iState)
			//voidpistol_aim_conf(id, iState) disable bcz bug issue again lol
			
			if(EventCheck)
			{
				switch(anim)
				{
					case 0:anim = 1;
					case 1:return HAM_IGNORED;
				}
				
				set_weapon_anim(id, iState?ANIM_CHANGE_BC:ANIM_CHANGE_AC)
				set_pdata_float(ent, 46, 0.7, 4)
				set_pdata_float(ent, 48, 1.0, 4)
			}
		}
	}
	WE_voidPistol(id, ent, pev(id, pev_button))
	
	return HAM_IGNORED
}
public voidpistol_aim_spr(id,Float:Origin[3],iState)
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!iState) { return; }
	engfunc(EngFunc_SetModel, ent, "sprites/voidpistol_aim.spr")
	Origin[2] += 12.0
	set_pev(ent, pev_origin, Origin)
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_classname, "voidpistol_aim")
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 255.0)
	set_pev(ent, pev_rendercolor, {255.0,0.0,0.0})
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_scale, 0.3)
	set_pev(ent, pev_nextthink, get_gametime() + 0.01)
}
/////////////////////////////////////// BAD CODE :( ////////////////////////////////
///////////////////////////////////// BUT IT WORKS :) //////////////////////////////
public void_buff(id, Entity, iState)
{
	if(!is_user_alive(id))
		return;
		
	static Float:fOrigin[3],Float:vOrigin[3],Float:dist;
	new EventCheck = pev(Entity, pev_iuser4)
	pev(id, pev_origin, fOrigin)
	
	dist = get_distance_f(fOrigin,vOrigin)
	new i = FM_NULLENT
	
	// Get distance between victim and epicenter
	while((i = engfunc(EngFunc_FindEntityInSphere, i, fOrigin, MAXDIST ))!= 0)
	{
		if(!is_user_alive(i) || id == i || !pev_valid(i))
			continue;
		
		if(!zp_get_user_zombie(i))
			continue;
		
		if(!can_see_fm(id, i))
			continue;
			
		pev(i, pev_origin, vOrigin)
		if(dist <= MAXDIST && !iState)
		{
			if(!iState){ 
				if(!EventCheck){
					set_weapon_anim(id, ANIM_SCANNING_ON)
					set_pdata_float(Entity, 48, 0.7, 4)
					set_pev(Entity, pev_iuser1, 1); 
					IsDetect = true;
					
				}else{
					set_pev(Entity, pev_iuser1, 1); 
					IsDetect = true;
				}
			}
			
			if(iState == 1 && !EventCheck)
			{
				set_weapon_anim(id, ANIM_SCANNING_OFF)
				set_pdata_float(Entity, 48, 0.7, 4)
				set_pev(Entity, pev_iuser1, 0); 
				IsDetect = false;
			}
		}
		
		else if(dist > MAXDIST && iState){
			if(iState) {
				if(!EventCheck){
					set_weapon_anim(id, ANIM_SCANNING_OFF)
					set_pdata_float(Entity, 48, 0.7, 4)
					set_pev(Entity, pev_iuser1, 0); 
					IsDetect = false;
				}else{
					set_pev(Entity, pev_iuser1, 0); 
					IsDetect = false;
				}
			}
			
			if(iState == 1 && !EventCheck)
			{
				set_weapon_anim(id, ANIM_SCANNING_OFF)
				set_pdata_float(Entity, 48, 0.7, 4)
				set_pev(Entity, pev_iuser1, 0); 
				IsDetect = false;
			}
		}
	}
}
public voidpistol_aim_conf(id, iState)
{
	if(!iState) { return; }
	
	new i = -1;
	static ent;ent = fm_find_ent_by_class(-1, "voidpistol_aim")
	
	new Float:fOrigin[3];pev(ent, pev_origin, fOrigin)
	new Float:idOrigin[3]; pev(id, pev_origin, idOrigin)
	while((i = engfunc(EngFunc_FindEntityInSphere, i, idOrigin, MAXDIST)) != 0)
	{
		if(!is_user_alive(i))continue
		if(id==i)continue
		if(!pev_valid(i))continue
		
		if(!is_user_alive(i))
		{
			if(pev_valid(ent))set_pev(ent, pev_flags, FL_KILLME)
		}
						
		new Float:vOrigin[3], Float:dist2;
		pev(i, pev_origin, vOrigin)
		dist2 = get_distance_f(idOrigin,vOrigin)
		if(dist2 <= MAXDIST)
		{
			voidpistol_aim_spr(id,vOrigin,iState)
			isAttached = true;
		}
		if(dist2 > MAXDIST){
			isAttached = false;
		}
	}
}
public WE_voidPistol(id, ent, iButton)
{
	new EventCheck = pev(ent, pev_iuser4)
	new iState = pev(ent, pev_iuser1)
	
	if(iButton & IN_ATTACK2)
	{
		if(!EventCheck) return HAM_IGNORED;
		g_ShootCount[id] = 0;
			
		set_weapon_anim(id, iState?ANIM_SHOOT_BLACKHOLEB:ANIM_SHOOT_BLACKHOLEA)
		emit_sound(id, CHAN_WEAPON, wp_sound[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		MakeMuzzleFlash(id, 1, 0.08, "wpn_muzzleflash", muzzleflash2)
			
		set_pev(ent, pev_iuser4, 0)
		set_pdata_float(ent, 48, 1.5, 4)
		set_pdata_float(ent, 38, get_gametime() + 0.1)
		anim=0;
			
		static iFlame
		iFlame = find_ent_by_class(id, "ef_bhole")
		if(pev_valid(iFlame)) set_pev(iFlame, pev_flags, FL_KILLME)
			
		new Float:vOrigin[3], Float:vAngles[3], Float:vVec[3],Float:vAngle[3]
		pev(id, pev_origin, vOrigin)
		pev(id, pev_v_angle, vAngle)
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, vAngle)
		xs_vec_mul_scalar(vAngle, 2076.0, vVec)
		
		static iBall
		iBall = Stock_CreateEntityBase(id, "info_target", MOVETYPE_FLY, wp_model[3], "galaxy_projectile", SOLID_BBOX, 0.05)
		engfunc(EngFunc_SetSize, iBall, Float:{-1.0, -1.0, 1.0}, Float:{1.0, 1.0, 1.0})
		
		set_pev(iBall, pev_origin, vOrigin)
		set_pev(iBall, pev_gravity, 0.01)
		set_pev(iBall, pev_animtime, get_gametime())
		set_pev(iBall, pev_frame, 0.0)
		set_pev(iBall, pev_framerate, 1.0)
		set_pev(iBall, pev_sequence, 0)
		set_pev(iBall, pev_rendermode, kRenderTransAdd)
		set_pev(iBall, pev_renderamt, 255.0)
		set_pev(iBall, pev_velocity, vVec)
		set_pev(iBall, pev_iuser3, 0)
		set_pev(iBall, pev_scale, 0.2)
		set_pev(iBall, pev_nextthink, get_gametime())
		
		static Float:vVelocity[3]
		pev(iBall, pev_velocity, vVelocity)
		vector_to_angle(vVelocity, vAngles)
		if(vAngles[0] > 90.0) vAngles[0] = -(360.0 - vAngles[0])
		set_pev(iBall, pev_angles, vAngles)
	}else if(iButton & IN_ATTACK && is_user_bot(id)){
		if(!EventCheck) return HAM_IGNORED;
		g_ShootCount[id] = 0;
			
		set_weapon_anim(id, iState?ANIM_SHOOT_BLACKHOLEB:ANIM_SHOOT_BLACKHOLEA)
		emit_sound(id, CHAN_WEAPON, wp_sound[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		MakeMuzzleFlash(id, 1, 0.08, "wpn_muzzleflash", muzzleflash2)
			
		set_pev(ent, pev_iuser4, 0)
		set_pdata_float(ent, 48, 1.5, 4)
		set_pdata_float(ent, 38, get_gametime() + 0.1)
		anim=0;
			
		static iFlame
		iFlame = find_ent_by_class(id, "ef_bhole")
		if(pev_valid(iFlame)) set_pev(iFlame, pev_flags, FL_KILLME)
			
		new Float:vOrigin[3], Float:vAngles[3], Float:vVec[3],Float:vAngle[3]
		pev(id, pev_origin, vOrigin)
		pev(id, pev_v_angle, vAngle)
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, vAngle)
		xs_vec_mul_scalar(vAngle, 2076.0, vVec)
		
		static iBall
		iBall = Stock_CreateEntityBase(id, "info_target", MOVETYPE_FLY, wp_model[3], "galaxy_projectile", SOLID_BBOX, 0.05)
		engfunc(EngFunc_SetSize, iBall, Float:{-1.0, -1.0, 1.0}, Float:{1.0, 1.0, 1.0})
		
		set_pev(iBall, pev_origin, vOrigin)
		set_pev(iBall, pev_gravity, 0.01)
		set_pev(iBall, pev_animtime, get_gametime())
		set_pev(iBall, pev_frame, 0.0)
		set_pev(iBall, pev_framerate, 1.0)
		set_pev(iBall, pev_sequence, 0)
		set_pev(iBall, pev_rendermode, kRenderTransAdd)
		set_pev(iBall, pev_renderamt, 255.0)
		set_pev(iBall, pev_velocity, vVec)
		set_pev(iBall, pev_iuser3, 0)
		set_pev(iBall, pev_scale, 0.2)
		set_pev(iBall, pev_nextthink, get_gametime())
		
		static Float:vVelocity[3]
		pev(iBall, pev_velocity, vVelocity)
		vector_to_angle(vVelocity, vAngles)
		if(vAngles[0] > 90.0) vAngles[0] = -(360.0 - vAngles[0])
		set_pev(iBall, pev_angles, vAngles)	
	}
	
	iButton &= ~IN_ATTACK2;
	set_pev(id, pev_button, iButton);
	
	return HAM_IGNORED
}
	
public HamHook_Spr_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Classname[32]
	pev(ent, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, "ef_bhole"))
	{
		static Float:fFrame, Float:fFrameMax
		
		pev(ent, pev_frame, fFrame)
		fFrameMax = 34.0;
		
		fFrame += 1.5
		if(fFrame >= fFrameMax) fFrame = 0.0
		
		set_pev(ent, pev_frame, fFrame)
		set_pev(ent, pev_nextthink, get_gametime() + 0.01)
		return
	}
	
	if(equal(Classname, "wpn_muzzleflash"))
	{
		static Float:fFrame, Float:fFrameMax
		pev(ent, pev_frame, fFrame)
		
		fFrameMax = 11.0
		
		if(fFrame >= 1.0)
		{
			fFrame += 0.6
		}else{
			fFrame += 0.1
		}
		
		if(fFrame >= fFrameMax) 
		{
			fFrame = 0.0;
			set_pev(ent, pev_flags, FL_KILLME)
		}
		set_pev(ent, pev_frame, fFrame)
		
		set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW) 
		
		set_pev(ent, pev_nextthink, get_gametime() + 0.01)
	}
	
	if(equal(Classname, "ef_star")){
		static Float:fTimeRemove;
		pev(ent, pev_ltime, fTimeRemove)
		
		set_pev(ent, pev_nextthink, get_gametime() + 0.01)
		
		if(get_gametime() >= fTimeRemove) 
		{
			set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
			return
		}
	}
}
public Sprites_Test(id, Float:Origin[3], classname[], spr_model[], Float:ltime)
{
	new spr = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	engfunc(EngFunc_SetModel, spr, spr_model)
	set_pev(spr, pev_origin, Origin)
	set_pev(spr, pev_classname, classname)
	set_pev(spr, pev_movetype, MOVETYPE_TOSS)
	set_pev(spr, pev_solid, SOLID_TRIGGER)
	set_pev(spr, pev_rendermode, kRenderTransAdd)
	set_pev(spr, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(spr, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(spr, pev_gravity, 1.0)
	set_pev(spr, pev_renderamt, 255.0)
	set_pev(spr, pev_scale, 0.03)
	set_pev(spr, pev_owner, id)
	set_pev(spr, pev_ltime, get_gametime() + ltime)
	set_pev(spr, pev_nextthink, get_gametime() + 0.01)
}
public HamF_InfoTarget_Think(iEnt)
{
	if(!pev_valid(iEnt))
		return
	
	static Classname[32]
	pev(iEnt, pev_classname, Classname, sizeof(Classname))
	static iOwner;iOwner = pev(iEnt, pev_owner)
	static id;id = pev(iEnt, pev_owner);
	
	if(equal(Classname, "voidpistol_aim"))
	{
		if(!isAttached)
		{
			set_pev(iEnt, pev_flags, FL_KILLME)
			return;
		}
		
		set_pev(iEnt, pev_effects, pev(iEnt, pev_effects) &~ EF_NODRAW) 
		
		static Float:fOrigin[3],Float:vOrigin[3],Float:velocity[3]
		pev(iEnt, pev_origin, fOrigin)
		new pEntity = -1;
		while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, fOrigin, 50.0)) != 0)
		{
			if(!is_user_alive(pEntity))continue
			if(iOwner == pEntity)continue
			if(!pev_valid(pEntity))continue
			if(!can_damage(pEntity,iOwner)) continue
			if(pev(pEntity, pev_takedamage) == DAMAGE_NO)continue
			
			pev(pEntity, pev_origin, vOrigin)
			
			get_speed_vector(fOrigin,vOrigin,999.0,velocity)
			set_pev(iEnt, pev_velocity, velocity)	
			vOrigin[2] += 12.0;
			engfunc(EngFunc_SetOrigin, iEnt, vOrigin)
			set_pev(iEnt, pev_movetype, MOVETYPE_FOLLOW)
			
			if(!is_user_alive(pEntity) && isAttached == true)
			{
				isAttached = false;
			}
		}
		
		new Float:fRenderMount; 
		pev(iEnt, pev_renderamt, fRenderMount)
		
		if(fRenderMount == 255.0)
		{
			fRenderMount -= 6.0
			set_pev(iEnt, pev_renderamt, fRenderMount)
		}
		if(fRenderMount <= 0.0)
		{
			fRenderMount += 10.0
			set_pev(iEnt, pev_renderamt, fRenderMount)
		}
		
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
		
	}
	
	if(equal(Classname, "blackhole2")){
		static Float:Origin[3], Float:vOrigin[3]
		pev(iEnt, pev_origin, Origin)

		static Float:Time; pev(iEnt, pev_fuser4, Time)
		if(get_gametime() - 0.3 > Time){
			
			new pEntity = -1;
			while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, Origin, RANGE_BLACKHOLE)) != 0)
			{
				if(!is_user_alive(pEntity))continue
				if(iOwner == pEntity)continue
				if(!pev_valid(pEntity))continue
				if(!can_damage(pEntity,iOwner)) continue
				if(pev(pEntity, pev_takedamage) == DAMAGE_NO)continue
				if(!zp_get_user_zombie(pEntity))
					continue;
					
				static Float:pOrigin[3];pev(pEntity, pev_origin, pOrigin)
				static Float:velocity[3];
				
				new Float:flDistance = get_distance_f ( Origin, pOrigin )   
				
				if(flDistance >=10.0){
					get_speed_vector(pOrigin,Origin,SPEED_BLACKHOLE*2,velocity)
				}else{
					get_speed_vector(pOrigin,Origin,0.0,velocity)
				}
				
				set_pev(pEntity, pev_velocity, velocity)
				
				pev(pEntity, pev_origin, vOrigin)
				create_blood(vOrigin)
				
				new Float:dmg = is_deadlyshot(id)?random_float(DAMAGE_HOLE-1,DAMAGE_HOLE+1)*1.5:random_float(DAMAGE_HOLE-1,DAMAGE_HOLE+1)
				ExecuteHamB(Ham_TakeDamage, pEntity, fm_get_user_weapon_entity(iOwner, WP_BASEON), iOwner, dmg, DMG_BULLET)
			}
			set_pev(iEnt, pev_fuser4, get_gametime())
		}
		
		new Float:flAnimTime;
		pev(iEnt, pev_fuser1, flAnimTime)
		if(flAnimTime < get_gametime())
		{
			set_pev(iEnt, pev_animtime, get_gametime())
			set_pev(iEnt, pev_sequence, 1)
			
			set_pev(iEnt, pev_fuser1, get_gametime() + 1.0)
		}

		static Float:fTimeRemove
		pev(iEnt, pev_ltime, fTimeRemove)
		
		if(get_gametime() >= fTimeRemove) 
		{
			set_pev(iEnt, pev_animtime, get_gametime())
			set_pev(iEnt, pev_sequence, 2)
			set_task(1.3, "remove_ent", id)
			return
		}
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.001)
	}
	
	if(equal(Classname, "galaxy_projectile")){
		static Float:fFrame,Float:fFrameMax
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
		
		fFrame += 1.0
		fFrameMax = 29.0
		
		if(fFrame >= fFrameMax)
		{
			fFrame = 0.0
		}
		
		set_pev(iEnt, pev_frame, fFrame)
	}
	if(equal(Classname, "blackhole_start")){
	
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)

		static Float:fFrame,Float:fFrameMax,Float:vecOrigin[3],iOwner
		iOwner = pev(iEnt, pev_owner)
		pev(iEnt, pev_frame, fFrame)
		pev(iEnt, pev_origin, vecOrigin)
				
		fFrame += 1.5
		fFrameMax = 44.0
		
		set_pev(iEnt, pev_frame, fFrame)
		if(fFrame >= fFrameMax)
		{
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
			BlackHole_Loop(iOwner,vecOrigin)
			return
		}
	}
	if(equal(Classname, "blackhole_loop")){
	
		if(!pev(iEnt, pev_iuser3))
		{	
			set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
		
			static Float:fTimeRemove, Float:fRenderMount; 
			pev(iEnt, pev_ltime, fTimeRemove)
			pev(iEnt, pev_renderamt, fRenderMount)
		
			static Float:fFrame,Float:fFrameMax
			pev(iEnt, pev_frame, fFrame)
			
			fFrame += 1.0
			fFrameMax = 34.0
		
			if(fFrame >= fFrameMax) fFrame = 0.0
		
			static Float:Origin[3],Float:fSound
			pev(iEnt, pev_fuser2, fSound)
			pev(iEnt, pev_origin, Origin)
		
			if(fSound < get_gametime()){
				fSound = get_gametime() + 1.0
				emit_sound(iEnt, CHAN_STATIC, wp_sound[4], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				set_pev(iEnt, pev_fuser2, fSound)
			}
		
			set_pev(iEnt, pev_frame, fFrame)
			
			if(get_gametime() >= fTimeRemove) 
			{
				static Float:flOrigin[3];
				pev(iEnt, pev_origin, flOrigin)
				BlackHole_End(iOwner,flOrigin)
				emit_sound(iEnt, CHAN_STATIC, wp_sound[5], 1.0, ATTN_NORM, 0, PITCH_NORM)
				
				new i = -1;
				while((i = engfunc(EngFunc_FindEntityInSphere, i, flOrigin, 150.0)) != 0)
				{
					if(!is_user_alive(i))continue
					if(!is_user_bot(i))continue
					if(id == i)continue
					if(!can_damage(id, i))continue
					if(!zp_get_user_zombie(i))
						continue;
					
					ExecuteHamB(Ham_TakeDamage, i, fm_get_user_weapon_entity(id, WP_BASEON), id, 170.0, DMG_BLAST)
				}
			
				set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
				return
			}
		} else {
			set_pev(iEnt, pev_nextthink, get_gametime() + 0.5)
		
			static Float:fTimeRemove
			pev(iEnt, pev_ltime, fTimeRemove)
		
			if(get_gametime() >= fTimeRemove) 
			{
				set_pev(iEnt, pev_enemy, 0)
				set_pev(iEnt, pev_aiment, 0)
				set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
				return
			}
		}
	}
	
	if(equal(Classname, "blackhole_end")){
	
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.03)

		static Float:fFrame,Float:fFrameMax,Float:vecOrigin[3],iOwner
		iOwner = pev(iEnt, pev_owner)
		pev(iEnt, pev_frame, fFrame)
		pev(iEnt, pev_origin, vecOrigin)
				
		fFrame += 1.0
		fFrameMax = 45.0
		
		new Float:fTimer; pev(iEnt, pev_fuser3, fTimer)
		if(fTimer < get_gametime()){
			new pEntity = -1;
			while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, 250.0)) != 0)
			{
				if(!pev_valid(pEntity))continue
				if(pEntity == iOwner) continue
				if(!is_user_alive(pEntity))continue
				if(!can_damage(iOwner,pEntity))continue
				if(pev(pEntity, pev_takedamage) == DAMAGE_NO)continue
				if(!zp_get_user_zombie(pEntity))
					continue;
			
				ExecuteHam(Ham_TakeDamage, pEntity, fm_get_user_weapon_entity(iOwner, WP_BASEON), iOwner, DAMAGE_HOLE, DMG_BLAST)
				Stock_Fake_KnockBack(iOwner, pEntity, random_float(5.0,7.0))
			}
			set_pev(iEnt, pev_fuser3, get_gametime() + 1.08)
		}
		
		set_pev(iEnt, pev_frame, fFrame)
		if(fFrame >= fFrameMax)
		{
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
			return
		}
	}
}
public remove_ent(id)
{
	new ent = fm_find_ent_by_owner(-1, "blackhole2", id)
	if(pev_valid(ent))
	{
		set_pev(ent, pev_flags, FL_KILLME)
		return
	}
}
public HamF_InfoTarget_Touch(iEnt, iPtd)
{
	if(!pev_valid(iEnt))
		return HAM_IGNORED
	
	static Classname[32]
	pev(iEnt, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "galaxy_projectile"))
		return HAM_IGNORED
		
	new iOwner, Float:vecOri[3]
	iOwner = pev(iEnt, pev_owner)
	pev(iEnt, pev_origin, vecOri)
	
	if(iPtd == iOwner)
		return HAM_IGNORED
	
	BlackHole_Start(iOwner,vecOri)
	
	engfunc(EngFunc_RemoveEntity, iEnt)
	return HAM_IGNORED
}
public BlackHole_Start(iOwner,Float:vecOri[3])
{	
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(ent, pev_classname, "blackhole_start")
	engfunc(EngFunc_SetModel, ent, spr_ef[0])
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_origin, vecOri)
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 255.0)
	set_pev(ent, pev_owner, iOwner)
	set_pev(ent, pev_scale, 0.5)
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_framerate, 1.0)
	set_pev(ent, pev_nextthink, get_gametime())
	engfunc(EngFunc_SetSize, ent, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	
	BlackHole(iOwner, vecOri)
}
public BlackHole_Loop(iOwner,Float:vecOri[3])
{
	new iEfx = Stock_CreateEntityBase(iOwner, "info_target", MOVETYPE_NONE, spr_ef[1], "blackhole_loop", SOLID_NOT, 0.0)
	set_pev(iEfx, pev_origin, vecOri)
	set_pev(iEfx, pev_iuser3, 0)
	set_pev(iEfx, pev_rendermode, kRenderTransAdd)
	set_pev(iEfx, pev_renderamt, 255.0)
	set_pev(iEfx, pev_light_level, 180)
	set_pev(iEfx, pev_animtime, get_gametime())
	set_pev(iEfx, pev_sequence, 0)
	set_pev(iEfx, pev_frame, 0.0)
	set_pev(iEfx, pev_owner, iOwner)
	set_pev(iEfx, pev_scale, 0.5)
	set_pev(iEfx, pev_framerate, 1.0)
	set_pev(iEfx, pev_ltime, get_gametime() + BLACKHOLE_TIME)
	set_pev(iEfx, pev_nextthink, get_gametime())
	engfunc(EngFunc_SetSize, iEfx, Float:{-1.1, -1.1, -1.1}, Float:{1.1, 1.1, 1.1})
	emit_sound(iEfx, CHAN_STATIC, wp_sound[4], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}
public BlackHole_End(iOwner,Float:vecOri[3])
{
	new iEfx = Stock_CreateEntityBase(iOwner, "info_target", MOVETYPE_NONE, spr_ef[2], "blackhole_end", SOLID_NOT, 0.0)
	set_pev(iEfx, pev_origin, vecOri)
	set_pev(iEfx, pev_iuser3, 0)
	set_pev(iEfx, pev_rendermode, kRenderTransAdd)
	set_pev(iEfx, pev_renderamt, 255.0)
	set_pev(iEfx, pev_light_level, 180)
	set_pev(iEfx, pev_animtime, get_gametime())
	set_pev(iEfx, pev_sequence, 0)
	set_pev(iEfx, pev_frame, 0.0)
	set_pev(iEfx, pev_owner, iOwner)
	set_pev(iEfx, pev_scale, 0.5)
	set_pev(iEfx, pev_framerate, 1.0)
	set_pev(iEfx, pev_ltime, get_gametime() + 1.3)
	set_pev(iEfx, pev_nextthink, get_gametime())
	engfunc(EngFunc_SetSize, iEfx, Float:{-1.1, -1.1, -1.1}, Float:{1.1, 1.1, 1.1})
	emit_sound(iEfx, CHAN_STATIC, wp_sound[4], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}
public BlackHole(id, Float:Origin[3])
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(ent, pev_classname, "blackhole2")
	set_pev(ent, pev_origin, Origin)
	engfunc(EngFunc_SetModel, ent, wp_model[4])
	set_pev(ent, pev_sequence, 0)
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_solid, SOLID_BBOX)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_framerate, 1.0)
	set_pev(ent, pev_animtime, get_gametime())
	set_pev(ent, pev_scale, 50.0)
	engfunc(EngFunc_SetSize, ent, Float:{-1.1, -1.1, -1.1}, Float:{1.1, 1.1, 1.1})
	set_pev(ent, pev_ltime, get_gametime() + BLACKHOLE_TIME + 1.3)
	set_pev(ent, pev_nextthink, get_gametime() + 1.0)
	
	emit_sound(ent, CHAN_STATIC, wp_sound[3], 1.0, ATTN_NORM, 0, PITCH_NORM)
}
stock log_kill(killer,victim,weapon[],headshot)
{
	user_silentkill(victim);
	
	message_begin(MSG_ALL, get_user_msgid("DeathMsg"), {0,0,0},0);
	write_byte(killer)
	write_byte(victim)
	write_byte(headshot)
	write_string(weapon)
	message_end()
	
	new kfrags = get_user_frags(killer)
	set_user_frags(killer,kfrags+1)
	new vfrags = get_user_frags(victim)
	set_user_frags(victim,vfrags-1)
	
	return PLUGIN_CONTINUE
}
public fw_Weapon_Reload(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_had_wp[id])
		return HAM_IGNORED	
		
	g_clip[id] = -1
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, WP_BASEON)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
		
	if(BPAmmo <= 0 || iClip >= DEFAULT_CLIP)
		return HAM_SUPERCEDE
			
	g_clip[id] = iClip
	return HAM_IGNORED
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	new iState = pev(ent, pev_iuser1)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_had_wp[id])
		return HAM_IGNORED	
	if(g_clip[id] == -1)
		return HAM_IGNORED
	
	set_pdata_int(ent, 51, g_clip[id], 4)
	set_pdata_int(ent, 54, 1, 4)
	
	new EventCheck = pev(ent, pev_iuser4)
	
	if(!EventCheck){
		set_weapon_anim(id, iState?ANIM_RELOADB:ANIM_RELOADA)
		set_pev(ent, pev_iuser1, 0)
	}else{
		set_weapon_anim(id, ANIM_RELOADC)
	}
	
	set_pdata_float(ent, 38, get_gametime() + 0.5, 4)
	
	set_pdata_float(ent, 48, RELOAD_TIME + 0.3, 4)
	Set_PlayerNextAttack(id, RELOAD_TIME)
	
	return HAM_IGNORED
}
stock Stock_Hook_Ent(ent, Float:TargetOrigin[3], Float:Speed, mode=0)
{
	static Float:fl_Velocity[3],Float:EntOrigin[3],Float:distance_f,Float:fl_Time
	pev(ent, pev_origin, EntOrigin)
	
	if(!mode)
	{
		distance_f = get_distance_f(EntOrigin, TargetOrigin)
		fl_Time = distance_f / Speed
			
		pev(ent, pev_velocity, fl_Velocity)
			
		fl_Velocity[0] = (TargetOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (TargetOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = (TargetOrigin[2] - EntOrigin[2]) / fl_Time

		if(vector_length(fl_Velocity) > 1.0) set_pev(ent, pev_velocity, fl_Velocity)
		else set_pev(ent, pev_velocity, Float:{0.01, 0.01, 0.01})
	} else {
		static Float:fl_EntVelocity[3], Float:fl_Acc[3]
		Stock_Directed_Vector(TargetOrigin, EntOrigin, fl_Velocity)
		xs_vec_mul_scalar(fl_Velocity, Speed, fl_Velocity)
		
		for(new i =0; i<3; i++)
		{
			if(fl_Velocity[i] > fl_EntVelocity[i]) 
			{
				fl_Acc[i] = fl_Velocity[i]-fl_EntVelocity[i]
				fl_Acc[i] = floatmin(70.0, fl_Acc[i])
				fl_EntVelocity[i] += fl_Acc[i]
			}
			else if(fl_Velocity[i] < fl_EntVelocity[i])
			{
				fl_Acc[i] = fl_EntVelocity[i]-fl_Velocity[i]
				fl_Acc[i] = floatmin(70.0, fl_Acc[i])
				fl_EntVelocity[i] -= fl_Acc[i]
			}
		}
		set_pev(ent, pev_velocity, fl_EntVelocity)
	}
}
stock Stock_Directed_Vector(Float:start[3],Float:end[3],Float:reOri[3])
{	
	new Float:v3[3]
	v3[0]=start[0]-end[0]
	v3[1]=start[1]-end[1]
	v3[2]=start[2]-end[2]
	new Float:vl = vector_length(v3)
	reOri[0] = v3[0] / vl
	reOri[1] = v3[1] / vl
	reOri[2] = v3[2] / vl
}
stock set_weapon_anim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(pev(id,pev_body))
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
/*
stock Stock_Drop_Slot(id,iSlot)
{
	new weapons[32], num
	get_user_weapons(id, weapons, num)
	for (new i = 0; i < num; i++)
	{
		const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
		
		if (iSlot == 2 && SECONDARY_WEAPONS_BIT_SUM & (1<<weapons[i]))
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}
*/
stock Stock_Drop_Slot(id, dropwhat)
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
stock Stock_CreateEntityBase(id, classtype[], mvtyp, mdl[], class[], solid, Float:fNext)
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classtype))
	set_pev(pEntity, pev_movetype, mvtyp);
	set_pev(pEntity, pev_owner, id);
	engfunc(EngFunc_SetModel, pEntity, mdl);
	set_pev(pEntity, pev_classname, class);
	set_pev(pEntity, pev_solid, solid);
	set_pev(pEntity, pev_nextthink, get_gametime() + fNext)
	return pEntity
}
stock Set_WeaponIdleTime(id, WeaponId ,Float:TimeIdle)
{
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, TimeIdle, 4)
}

stock Set_PlayerNextAttack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
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
	write_byte(15)
	message_end()
}

stock CheckAngle(iAttacker, iVictim, Float:fAngle)  return(Stock_CheckAngle(iAttacker, iVictim) > floatcos(fAngle,degrees))
stock Float:Stock_CheckAngle(id,iTarget)
{
	new Float:vOricross[2],Float:fRad,Float:vId_ori[3],Float:vTar_ori[3],Float:vId_ang[3],Float:fLength,Float:vForward[3]
	pev(id, pev_origin, vId_ori)
	pev(iTarget, pev_origin, vTar_ori)
	
	pev(id,pev_angles,vId_ang)
	for(new i=0;i<2;i++) vOricross[i] = vTar_ori[i] - vId_ori[i]
	
	fLength = floatsqroot(vOricross[0]*vOricross[0] + vOricross[1]*vOricross[1])
	
	if (fLength<=0.0)
	{
		vOricross[0]=0.0
		vOricross[1]=0.0
	} else {
		vOricross[0]=vOricross[0]*(1.0/fLength)
		vOricross[1]=vOricross[1]*(1.0/fLength)
	}
	
	engfunc(EngFunc_MakeVectors,vId_ang)
	global_get(glb_v_forward,vForward)
	
	fRad = vOricross[0]*vForward[0]+vOricross[1]*vForward[1]
	return fRad   //->   RAD 90' = 0.5rad
}

stock Stock_RadiusDamage(Float:vecSrc[3], pevInflictor, pevAttacker, Float:flDamage, Float:flRadius, bitsDamageType, bool:bSkipAttacker=true, bool:bCheckTeam=false)
{
	new pEntity = -1, tr = create_tr2(), Float:flAdjustedDamage, Float:falloff

	falloff = flDamage / flRadius
	new bInWater = (engfunc(EngFunc_PointContents, vecSrc) == CONTENTS_WATER)
	vecSrc[2] += 1.0
	if(!pevAttacker) pevAttacker = pevInflictor
	
	while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecSrc, flRadius)) != 0)
	{
		if(pev(pEntity, pev_takedamage) == DAMAGE_NO)
			continue
		if(bInWater && !pev(pEntity, pev_waterlevel))
			continue
		if(!bInWater && pev(pEntity, pev_waterlevel) == 3)
			continue
		if(bCheckTeam && is_user_connected(pEntity) && pEntity != pevAttacker)
			if(!can_damage(pEntity, pevAttacker))
				continue
		if(bSkipAttacker && pEntity == pevAttacker)
			continue
		
		new Float:vecEnd[3]
		pev(pEntity, pev_origin, vecEnd)

		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, 0, tr)

		new Float:flFraction
		get_tr2(tr, TR_flFraction, flFraction)

		if(flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, 0, tr)
		
		if(pev_valid(pEntity))
		{
			pev(pEntity, pev_origin, vecEnd)
			xs_vec_sub(vecEnd, vecSrc, vecEnd)

			new Float:fDistance = xs_vec_len(vecEnd)
			if(fDistance < 1.0) fDistance = 0.0

			flAdjustedDamage = fDistance * falloff
			
			if(get_tr2(tr, TR_pHit) != pEntity) flAdjustedDamage *= 0.3

			if(flAdjustedDamage <= 0)
				continue

			ExecuteHamB(Ham_TraceAttack, pEntity, pevAttacker, 1.0, vecEnd, tr, bitsDamageType)
			ExecuteHamB(Ham_TakeDamage, pEntity, pevAttacker, pevAttacker, flAdjustedDamage, bitsDamageType);
		}
	}
	free_tr2(tr)
}
public MakeMuzzleFlash(id, iBody, Float:iSize, szclassname[], cache_muf[])//Thx Asdian DX
{
	if(is_user_bot(id)) return;
	static iMuz
	iMuz = Stock_CreateEntityBase(id, "env_sprite", MOVETYPE_FOLLOW, cache_muf, szclassname, SOLID_NOT,0.01)
	set_pev(iMuz, pev_body, iBody)
	set_pev(iMuz, pev_owner, id)
	set_pev(iMuz, pev_rendermode, kRenderTransAdd)
	set_pev(iMuz, pev_renderamt, 255.0)
	set_pev(iMuz, pev_aiment, id)
	set_pev(iMuz, pev_scale, iSize)
	set_pev(iMuz, pev_frame, 0.0)
	dllfunc(DLLFunc_Spawn, iMuz)
}
public Stock_Fake_KnockBack(id, iVic, Float:iKb)
{
	if(iVic > 32) return
	
	new Float:vAttacker[3], Float:vVictim[3], Float:vVelocity[3], flags
	pev(id, pev_origin, vAttacker)
	pev(iVic, pev_origin, vVictim)
	vAttacker[2] = vVictim[2] = 0.0
	flags = pev(id, pev_flags)
	
	xs_vec_sub(vVictim, vAttacker, vVictim)
	new Float:fDistance
	fDistance = xs_vec_len(vVictim)
	xs_vec_mul_scalar(vVictim, 1 / fDistance, vVictim)
	
	pev(iVic, pev_velocity, vVelocity)
	xs_vec_mul_scalar(vVictim, iKb, vVictim)
	xs_vec_mul_scalar(vVictim, 50.0, vVictim)
	vVictim[2] = xs_vec_len(vVictim) * 0.15
	
	if(flags &~ FL_ONGROUND)
	{
		xs_vec_mul_scalar(vVictim, 1.2, vVictim)
		vVictim[2] *= 0.4
	}
	if(xs_vec_len(vVictim) > xs_vec_len(vVelocity)) set_pev(iVic, pev_velocity, vVictim)
}	

stock get_weapon_attachment2(id, Float:output[3], Float:fDis = 40.0)
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
stock Get_Position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
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
public Create_Exp(iEntity, Float:Origin[3], const iSprite)
{
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, Origin, 0);
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0]);
	engfunc(EngFunc_WriteCoord, Origin[1]);
	engfunc(EngFunc_WriteCoord, Origin[2]);
	write_short(iSprite)
	write_byte(6)
	write_byte(25)
	write_byte(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES)			
	message_end();	
}
stock Stock_StarEffect(Float:vecOri[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOri)
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord,vecOri[0])
	engfunc(EngFunc_WriteCoord,vecOri[1])
	engfunc(EngFunc_WriteCoord,vecOri[2])
	write_short(ef_star[0])
	write_short(ef_star[0])
	write_byte(178)
	write_byte(3)
	message_end()
}
public can_damage(id1, id2)
{
	if(!pev_valid(id1) || !pev_valid(id2))
		return 0
		
	if(!is_user_alive(id1) || !is_user_alive(id2))
		return 0
		
	if(!can_see_fm(id1, id2))
		return 0
		
	// Check team
	if(zp_get_user_zombie(id1))
	{
		if(zp_get_user_zombie(id2))
			return 0;
		else if(!zp_get_user_zombie(id2))
			return 1;
	}else if(zp_get_user_zombie(id2))
	{
		if(zp_get_user_zombie(id1))
			return 0;
		else if(!zp_get_user_zombie(id1))
			return 1;
	}
	
	return 0;
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

/* ===============================
--------- END OF SAFETY  ---------
=================================*/
