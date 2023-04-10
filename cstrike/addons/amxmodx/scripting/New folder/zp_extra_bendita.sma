#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <engine>
#include <zombieplague>

#define PLUGIN "[CSO] Weapon: Vandita"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define V_MODEL "models/v_bendita.mdl"
#define P_MODEL "models/p_bendita.mdl"
#define W_MODEL "models/w_bendita.mdl"

#define CSW_BASEDON CSW_G3SG1
#define weapon_basedon "weapon_g3sg1"

#define DAMAGE 825
#define CLIP 7
#define BPAMMO 200
#define SPEED 3.0
#define RECOIL 7.0
#define RELOAD_TIME 3.0

#define SHOOT_ANIM random_num(1, 2)
#define DRAW_ANIM 4
#define RELOAD_ANIM 3

#define BODY_NUM 0

#define WEAPON_SECRETCODE 545442
#define WEAPON_EVENT "events/g3sg1.sc"
#define OLD_W_MODEL "models/w_g3sg1.mdl"

#define FIRE_SOUND "weapons/bendita-1.wav"

#define HOLYBOMB_BURNDAMAGE 40
#define HOLYBOMB_BURNDELAY 0.5
#define HOLYBOMB_BURNTIME 5.0

#define HOLYFIREBURN_CLASSNAME "holyfire"

native navtive_bullet_effect(id, ent, ptr)

new const WeaponResources[][] = 
{
	"sprites/flame_burn01.spr"
}

new g_Had_Weapon, g_Old_Weapon[33], Float:g_Recoil[33][3], g_Clip[33]
new g_weapon_event, g_ShellId,bendita
new g_HamBot

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	register_forward(FM_SetModel, "fw_SetModel")	
	register_forward(FM_Think, "fw_Think")	
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_PlayerPost", 1)	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_basedon, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_basedon, "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon_basedon, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Weapon_Reload, weapon_basedon, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_basedon, "fw_Weapon_Reload_Post", 1)
	RegisterHam(Ham_Item_Deploy, weapon_basedon, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_PostFrame, weapon_basedon, "fw_Item_PostFrame")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
			
	bendita = zp_register_extra_item("Bendita", 3000, ZP_TEAM_HUMAN)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	engfunc(EngFunc_PrecacheSound, FIRE_SOUND)
	
	g_ShellId = engfunc(EngFunc_PrecacheModel, "models/rshell_big.mdl")	
	
	for(new i = 0; i < sizeof(WeaponResources); i++)
	{
		if(i == 1) engfunc(EngFunc_PrecacheGeneric, WeaponResources[i])
		else engfunc(EngFunc_PrecacheModel, WeaponResources[i])
	}	
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}
public zp_extra_item_selected(id, ItemID)
{
	if(ItemID == bendita)
	{
		drop_weapons(id, 1)
		Set_BitVar(g_Had_Weapon, id)
		new iWep2 = give_item(id,weapon_basedon)
		if( iWep2 > 0 )
		{
			cs_set_weapon_ammo( iWep2, CLIP )
			cs_set_user_bpammo (id, CSW_BASEDON, 200)
			set_weapon_anim(id, DRAW_ANIM)
		}
	}
}
public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(WEAPON_EVENT, name))
		g_weapon_event = get_orig_retval()		
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
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage_PlayerPost", 1)
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
}

public Get_Weapon(id)
{		
	drop_weapons(id, 1)
	Set_BitVar(g_Had_Weapon, id)
	new iWep2 = give_item(id,weapon_basedon)
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo( iWep2, CLIP )
		cs_set_user_bpammo (id, CSW_BASEDON, 200)
		set_weapon_anim(id, DRAW_ANIM)
	}
}
public zp_user_humanized_post(id)
{
	Remove_Weapon(id)
}
public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		Remove_Weapon(id)
	}
}
public Remove_Weapon(id)
{
	UnSet_BitVar(g_Had_Weapon, id)
}

public Player_Spawn(id)
{
	UnSet_BitVar(g_Had_Weapon, id)
}
public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
	
	static CSWID; CSWID = read_data(2)
	
	if((CSWID == CSW_BASEDON && g_Old_Weapon[id] != CSW_BASEDON) && Get_BitVar(g_Had_Weapon, id))
	{
		set_pev(id, pev_viewmodel2, V_MODEL)
		set_pev(id, pev_weaponmodel2, P_MODEL)
		
		set_weapon_anim(id, DRAW_ANIM)
		//Draw_NewWeapon(id, CSWID)
	} else if((CSWID == CSW_BASEDON && g_Old_Weapon[id] == CSW_BASEDON) && Get_BitVar(g_Had_Weapon, id)) {
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_BASEDON)
		if(!pev_valid(Ent))
		{
			g_Old_Weapon[id] = get_user_weapon(id)
			return
		}
		
		if(cs_get_user_zoom(id) == 1)
		{
			set_pev(id, pev_viewmodel2, V_MODEL)
		} else if(cs_get_user_zoom(id) == 2 || cs_get_user_zoom(id) == 3) {
			set_pev(id, pev_viewmodel2, "")
		}
		
		set_pdata_float(Ent, 46, get_pdata_float(Ent, 46, 4) * SPEED, 4)
	} else if(CSWID != CSW_BASEDON && g_Old_Weapon[id] == CSW_BASEDON) Draw_NewWeapon(id, CSWID)
	
	g_Old_Weapon[id] = get_user_weapon(id)
}

public Draw_NewWeapon(id, CSW_ID)
{
	if(CSW_ID == CSW_BASEDON)
	{
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_BASEDON)
		
		if(pev_valid(ent) && Get_BitVar(g_Had_Weapon, id))
		{
			set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW) 
			engfunc(EngFunc_SetModel, ent, P_MODEL)	
			set_pev(ent, pev_body, BODY_NUM)
		}
	} else {
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_BASEDON)
		
		if(pev_valid(ent)) set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW) 			
	}
	
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_BASEDON && Get_BitVar(g_Had_Weapon, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_BASEDON || !Get_BitVar(g_Had_Weapon, invoker))
		return FMRES_IGNORED
	if(eventid != g_weapon_event)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	set_weapon_anim(invoker, SHOOT_ANIM)
	emit_sound(invoker, CHAN_WEAPON, FIRE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	if(cs_get_user_zoom(invoker) == 1) Eject_Shell(invoker, g_ShellId, 0.0)
		
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
	
	if(equal(model, OLD_W_MODEL))
	{
		static weapon; weapon = fm_find_ent_by_owner(-1, weapon_basedon, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_Had_Weapon, iOwner))
		{
			Remove_Weapon(iOwner)
			
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			//set_pev(entity, pev_body, BODY_NUM)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Classname[32]; pev(ent, pev_classname, Classname, sizeof(Classname))
	if(!equal(Classname, HOLYFIREBURN_CLASSNAME))
		return
	
	static Float:fFrame
	pev(ent, pev_frame, fFrame)

	fFrame += 1.0
	if(fFrame > 15.0) fFrame = 0.0

	set_pev(ent, pev_frame, fFrame)
	
	static id; id = pev(ent, pev_owner)
	static NewHealth
	
	if(get_gametime() - HOLYBOMB_BURNDELAY > pev(ent, pev_fuser2))
	{
		NewHealth = get_user_health(id) - HOLYBOMB_BURNDAMAGE
		
		if(NewHealth > 1)
			set_user_health(id, NewHealth)
		else
		{
			engfunc(EngFunc_RemoveEntity, ent)
			return
		}
			
		set_pev(ent, pev_fuser2, get_gametime())
	}
	
	static Float:fTimeRemove
	pev(ent, pev_fuser1, fTimeRemove)
	if (get_gametime() >= fTimeRemove)
	{
		engfunc(EngFunc_RemoveEntity, ent)
		return;
	}	
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_BASEDON || !Get_BitVar(g_Had_Weapon, Attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]
	
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)		

	navtive_bullet_effect(Attacker, Victim, Ptr)
	
	SetHamParamFloat(3, float(DAMAGE))
	
	return HAM_IGNORED
}

public fw_TraceAttack_Player(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_BASEDON || !Get_BitVar(g_Had_Weapon, Attacker))
		return HAM_IGNORED
		
	SetHamParamFloat(3, float(DAMAGE))
	
	return HAM_IGNORED
}

public fw_TakeDamage_PlayerPost(Victim, Inflictor, Attacker, Float:Damage, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_BASEDON || !Get_BitVar(g_Had_Weapon, Attacker))
		return HAM_IGNORED
		
	if(is_user_alive(Victim) && cs_get_user_team(Victim) != cs_get_user_team(Attacker)) Make_HolyFire(Victim)
	
	return HAM_IGNORED
}

public fw_Weapon_PrimaryAttack(Ent)
{
	static id; id = pev(Ent, pev_owner)
	pev(id, pev_punchangle, g_Recoil[id])
	
	return HAM_IGNORED
}

public fw_Weapon_PrimaryAttack_Post(Ent)
{
	static id; id = pev(Ent, pev_owner)
	
	if(Get_BitVar(g_Had_Weapon, id))
	{
		static Float:Push[3]
		pev(id, pev_punchangle, Push)
		xs_vec_sub(Push, g_Recoil[id], Push)
		
		xs_vec_mul_scalar(Push, RECOIL, Push)
		xs_vec_add(Push, g_Recoil[id], Push)
		
		Push[1] *= 0.5
		
		set_pev(id, pev_punchangle, Push)
	}
}

public fw_Item_AddToPlayer_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		Set_BitVar(g_Had_Weapon, id)
		set_pev(ent, pev_impulse, 0)
	}
	return HAM_HANDLED
}

public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return	
	if(!Get_BitVar(g_Had_Weapon, Id))
		return
	if(zp_get_user_zombie(Id))
		return
		
	set_weapon_anim(Id, DRAW_ANIM)	
	//Set_Weapon_Idle(Id, CSW_BASEDON, 0.7)
	//Set_Player_NextAttack(Id, 0.7)	
	//Set_WeaponAnim(Id, ANIM_DRAW)
}
public fw_Item_PostFrame(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(is_user_alive(id) && Get_BitVar(g_Had_Weapon, id))
	{	
		static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
		static bpammo; bpammo = cs_get_user_bpammo(id, CSW_BASEDON)
		static iClip; iClip = get_pdata_int(ent, 51, 4)
		static fInReload; fInReload = get_pdata_int(ent, 54, 4)
		
		if(fInReload && flNextAttack <= 0.0)
		{
			static temp1; temp1 = min(CLIP - iClip, bpammo)

			set_pdata_int(ent, 51, iClip + temp1, 4)
			cs_set_user_bpammo(id, CSW_BASEDON, bpammo - temp1)		
			
			set_pdata_int(ent, 54, 0, 4)
			
			fInReload = 0
		}		
	}
	
	return HAM_IGNORED	
}

public fw_Weapon_Reload(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Weapon, id))
		return HAM_IGNORED
	
	g_Clip[id] = -1
	
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_BASEDON)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	
	if(bpammo <= 0) return HAM_SUPERCEDE
	
	if(iClip >= CLIP) return HAM_SUPERCEDE		
		
	g_Clip[id] = iClip

	return HAM_HANDLED
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Weapon, id))
		return HAM_IGNORED

	if (g_Clip[id] == -1)
		return HAM_IGNORED
	
	set_pdata_int(ent, 51, g_Clip[id], 4)
	set_pdata_int(ent, 54, 1, 4)
	
	set_weapon_anim(id, RELOAD_ANIM)
	set_pdata_float(id, 83, RELOAD_TIME, 5)

	return HAM_HANDLED
}

public Make_HolyFire(id)
{
	static Ent; Ent = fm_find_ent_by_owner(-1, HOLYFIREBURN_CLASSNAME, id)
	if(!pev_valid(Ent))
	{
		static iEnt; iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
		static Float:MyOrigin[3]
		
		pev(id, pev_origin, MyOrigin)
		
		// set info for ent
		set_pev(iEnt, pev_movetype, MOVETYPE_FOLLOW)
		set_pev(iEnt, pev_rendermode, kRenderTransAdd)
		set_pev(iEnt, pev_renderamt, 250.0)
		set_pev(iEnt, pev_fuser1, get_gametime() + HOLYBOMB_BURNTIME)
		set_pev(iEnt, pev_scale, 1.0)
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.5)
		
		set_pev(iEnt, pev_classname, HOLYFIREBURN_CLASSNAME)
		engfunc(EngFunc_SetModel, iEnt, WeaponResources[0])
		set_pev(iEnt, pev_owner, id)
		set_pev(iEnt, pev_aiment, id)
	}	
}

stock Make_BulletHole(id, Float:Origin[3], Float:Damage)
{
	// Find target
	static Decal; Decal = random_num(41, 45)
	static LoopTime; 
	
	if(Damage > 100.0) LoopTime = 2
	else LoopTime = 1
	
	for(new i = 0; i < LoopTime; i++)
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

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed, Float:multi, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	static Float:EntVelocity[3]
	
	pev(ent, pev_velocity, EntVelocity)
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	static Float:fl_Time; fl_Time = distance_f / speed
	static Float:fl_Time2; fl_Time2 = distance_f / (speed * multi)
	
	if(type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time2) * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time2) * 1.5
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time		
	} else if(type == 2) {
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time2) * 1.5
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time2) * 1.5
		fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time
	}

	xs_vec_add(EntVelocity, fl_Velocity, fl_Velocity)
	set_pev(ent, pev_velocity, fl_Velocity)
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

stock Eject_Shell(id, Shell_ModelIndex, Float:Time) // By Dias
{
	static Ent; Ent = get_pdata_cbase(id, 373, 5)
	if(!pev_valid(Ent))
		return

        set_pdata_int(Ent, 57, Shell_ModelIndex, 4)
        set_pdata_float(id, 111, get_gametime() + Time)
}

stock set_weapon_anim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}
public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(get_user_weapon(iAttacker) == CSW_BASEDON)
	{
		if(Set_BitVar(g_Had_Weapon,iAttacker))
			set_msg_arg_string(4, "bendita")
	}
                
	return PLUGIN_CONTINUE
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
