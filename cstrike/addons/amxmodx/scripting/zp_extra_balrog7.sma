#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <toan>
#include <zombieplague>

#define PLUGIN "Balrog-XI"
#define VERSION "2.0"
#define AUTHOR "Dias"
#define SUPPORT FOR ZP "Conspiracy"

#define V_MODEL "models/v_balrog7.mdl"
#define P_MODEL "models/p_balrog7.mdl"
#define W_MODEL "models/w_balrog7.mdl"

#define V_MODELB "models/v_balrog7b.mdl"

#define Fire_Sound "weapons/balrog7-1.wav"

#define CSW_BALROG7 CSW_M249
#define weapon_balrog7 "weapon_m249"
#define OLD_W_MODEL "models/w_m249.mdl"
#define OLD_EVENT "events/m249.sc"

#define WEAPON_SECRETCODE 1921

#define	BALROG7_NAME "Balrog-VII"
#define	BALROG7_COST	3000
#define BALROG7_CLIP 150
#define BALROG7_AMMO 200
#define BALROG7_SPEED 1.0
#define BALROG7_RECOIL 1.0
#define BALROG7_RELOAD 4.0
#define BALROG7_DAMAGE 1.4
#define CHARGE_EXPRADIUS 50.0
#define BALROG7_CLASSNAME "bl7_crit"
new const EXP_SOUND[3][] = {
	"weapons/explode3.wav",
	"weapons/explode4.wav",
	"weapons/explode5.wav"
}

// OFFSET
const PDATA_SAFE = 2
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_WEAPONOWNER = 41

enum
{
	ANIM_IDLE = 0,
	ANIM_SHOOT,
	ANIM_SHOOT2,
	ANIM_AFTER_RELOAD,
	ANIM_DRAW
}

new const exp_spr[] = "sprites/balrogcritical.spr"
new const exp_spr2[] = "sprites/flame_puff01.spr"

new const exp_sprb[] = "sprites/balrogcritical_blue.spr"
new const exp_sprb2[] = "sprites/flame_puff01_blue.spr"

new g_balrog7, g_skin[33], g_exp_sprid2, g_exp_spridb2
//new g_exp_sprid, g_exp_spridb
new g_has_balrog7[33], g_shot[33], g_clip[33], g_balrog7_zoom[33]
new g_event_balrog7, g_ham_bot

native navtive_bullet_effect(id, ent, ptr)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_forward(FM_CmdStart, "CmdStart")	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_balrog7, "fw_Item_AddToPlayer_Post", 1)
	
	RegisterHam(Ham_Weapon_Reload, weapon_balrog7, "Reload7")
	RegisterHam(Ham_Weapon_Reload, weapon_balrog7, "Reload_Post7", 1)
	
	RegisterHam(Ham_Item_PostFrame, weapon_balrog7, "fw_Item_PostFrame")	
	RegisterHam(Ham_Item_Holster, weapon_balrog7, "HolsterPost", 1)
	
	RegisterHam(Ham_Item_Deploy, weapon_balrog7, "fw_Item_Deploy_Post", 1)
	
	register_think(BALROG7_CLASSNAME, "fw_Think_B7Crit")
	
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	
	g_balrog7 = zp_register_extra_item(BALROG7_NAME, BALROG7_COST, ZP_TEAM_HUMAN)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	engfunc(EngFunc_PrecacheModel, V_MODELB)
	
	engfunc(EngFunc_PrecacheSound, Fire_Sound)
	
	for(new i = 0; i < sizeof(EXP_SOUND); i++) 
		engfunc(EngFunc_PrecacheSound, EXP_SOUND[i])	
	//g_exp_sprid = 
	engfunc(EngFunc_PrecacheModel, exp_spr)
	g_exp_sprid2 = engfunc(EngFunc_PrecacheModel, exp_spr2)
	//g_exp_spridb = 
	engfunc(EngFunc_PrecacheModel, exp_sprb)
	g_exp_spridb2 = engfunc(EngFunc_PrecacheModel, exp_sprb2)
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)	
}

public client_putinserver(id)
{
	if(!g_ham_bot && is_user_bot(id))
	{
		g_ham_bot = 1
		set_task(0.1, "do_register", id)
	}
}

public do_register(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(OLD_EVENT, name))
		g_event_balrog7 = get_orig_retval()
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_balrog7) Get_balrog7(id)
}

public Get_balrog7(id)
{
	drop_weapons(id, 1)
	g_has_balrog7[id] = 1
	g_balrog7_zoom[id] = 0
	g_skin[id] = random_num(0,1)
	
	new iWep2 = give_item(id, weapon_balrog7)
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, BALROG7_CLIP)
		cs_set_user_bpammo(id, CSW_BALROG7, BALROG7_AMMO)
		set_pdata_float(id, 83, 1.0, 5)
	}
}

public Player_Spawn(id)
{
	Remove_balrog7(id)
}
public Remove_balrog7(id)
{
	g_balrog7_zoom[id] = 0
	g_has_balrog7[id] = 0
}
public Event_CurWeapon(id)
{
	if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
		return;
	
	if(read_data(2) != CSW_BALROG7 || !g_has_balrog7[id])
		return	
	static Float:iSpeed
	if(g_has_balrog7[id])
	iSpeed = BALROG7_SPEED
	
	static weapon[32],Ent
	get_weaponname(read_data(2),weapon,31)
	Ent = find_ent_by_owner(-1,weapon,id)
	if(Ent)
	{
		static Float:Delay
		Delay = get_pdata_float( Ent, 46, 4) * iSpeed
		
		if (Delay > 0.0)
		{
			if(!g_balrog7_zoom[id])
				set_pdata_float(Ent, 46, Delay, 4)
			else 
				set_pdata_float(Ent, 46, Delay/0.7, 4)
		}
	}
}
public fw_Item_AddToPlayer_Post(ent, id)
{
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		g_has_balrog7[id] = 1
		
		set_pev(ent, pev_impulse, 0)
		g_skin[id] = pev(ent, pev_iuser4)
		g_shot[id] = 0
	}		
}
public CmdStart(id, uc_handle, seed)
{
	if(!g_has_balrog7[id])
		return

	if(!is_user_alive(id))
		return
		
	new iButtons = get_uc(uc_handle, UC_Buttons)

	if((iButtons & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
	{
		new szClip, szAmmo
		new szWeapID = get_user_weapon(id, szClip, szAmmo)
		
		if(szWeapID == CSW_BALROG7 && g_has_balrog7[id] && !g_balrog7_zoom[id] == true)
		{
			g_balrog7_zoom[id] = 1
			cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 1)
			emit_sound(id, CHAN_WEAPON, "weapons/zoom.wav", 0.20, 2.40, 0, 100)
		}
		else if(szWeapID == CSW_BALROG7 && g_has_balrog7[id] && g_balrog7_zoom[id])
		{
				g_balrog7_zoom[id] = false
				cs_set_user_zoom(id, CS_RESET_ZOOM, 0)	
		}
	}
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_BALROG7 && g_has_balrog7[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED		
	if(get_user_weapon(invoker) == CSW_BALROG7 && g_has_balrog7[invoker] && eventid == g_event_balrog7)
	{
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)	

		set_weapon_anim(invoker, ANIM_SHOOT)
		emit_sound(invoker, CHAN_WEAPON, Fire_Sound, 1.0, ATTN_NORM, 0, PITCH_LOW)	

		g_shot[invoker]++
		return FMRES_SUPERCEDE
	}
	
	return FMRES_HANDLED
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_BALROG7)
		{
			if(g_has_balrog7[attacker])
			{
				SetHamParamFloat(4, damage * BALROG7_DAMAGE)
			}
		}
	}
}
public fw_TraceAttack(Ent, Attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	if(!is_user_alive(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_BALROG7 || !g_has_balrog7[Attacker])
		return HAM_IGNORED
		
	new Float:flEnd[3]	
	get_tr2(ptr, TR_vecEndPos, flEnd)
	if(!is_user_alive(Ent))
	{
		navtive_bullet_effect(Attacker, Ent, ptr)
	}
	
	if(g_shot[Attacker] >= 10 && get_user_weapon(Attacker) == CSW_BALROG7)
	{
		explode(Attacker, flEnd)
	}
	return HAM_HANDLED	
}

public fw_Think_B7Crit(Ent)
{
	if(!pev_valid(Ent))
		return
		
	static Float:Scale; pev(Ent, pev_scale, Scale)
	
	if(Scale>=0.312)	
	{
		set_pev(Ent, pev_flags, FL_KILLME)	
	}else if(Scale>=0.27)
	{
		Scale += 0.0025
	}else Scale += 0.05	
		
	
	set_pev(Ent, pev_scale, Scale)
	set_pev(Ent, pev_nextthink, halflife_time() + 0.045)
}
public explode(id, Float:End1[3])
{
	if(g_has_balrog7[id])
	{
		if(is_user_alive(id))
		{
			new TE_FLAG
			
			TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
			TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
			
			// Exp
			/*
			message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION)
			engfunc(EngFunc_WriteCoord, End1[0])
			engfunc(EngFunc_WriteCoord, End1[1])
			engfunc(EngFunc_WriteCoord, End1[2])
			write_short(g_skin[id]?g_exp_spridb:g_exp_sprid)	// sprite index
			write_byte(3)	// scale in 0.1's
			write_byte(1)	// framerate
			write_byte(TE_FLAG)	// flags
			message_end()*/
			
			message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION)
			engfunc(EngFunc_WriteCoord, End1[0])
			engfunc(EngFunc_WriteCoord, End1[1])
			engfunc(EngFunc_WriteCoord, End1[2]-10.0)
			write_short(g_skin[id]?g_exp_spridb2:g_exp_sprid2)	// sprite index
			write_byte(12)	// scale in 0.1's
			write_byte(25)	// framerate
			write_byte(TE_FLAG)	// flags
			message_end()
			
			End1[2]+=10.0
			
			new ent = create_entity("info_target")
			set_pev(ent, pev_origin, End1)
			set_pev(ent, pev_rendermode, kRenderTransAdd)
			set_pev(ent, pev_renderamt, 255.0)
			set_pev(ent, pev_nextthink, halflife_time() + 0.1)
			entity_set_string(ent, EV_SZ_classname, BALROG7_CLASSNAME)
			engfunc(EngFunc_SetModel, ent, g_skin[id]?exp_sprb:exp_spr)
			set_pev(ent, pev_solid, SOLID_NOT)
			set_pev(ent, pev_frame, 0.0)
			set_pev(ent, pev_scale, 0.08)
			
			emit_sound(ent, CHAN_WEAPON, EXP_SOUND[random_num(0,2)], 1.0, ATTN_NORM, 0, PITCH_NORM)				
			
			// Alive...
			new a = FM_NULLENT
			// Get distance between victim and epicenter
			while((a = find_ent_in_sphere(a, End1, CHARGE_EXPRADIUS)) != 0)
			{
				if (id == a)
					continue 
				if(pev(a, pev_takedamage) != DAMAGE_NO)
				{
					ExecuteHamB(Ham_TakeDamage, a, id, id, is_deadlyshot(id)?random_float(250.0-10,250.0+10)*1.5:random_float(250.0-10,250.0+10), DMG_BULLET)
				}
			}
			g_shot[id]=0
		}
	}
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
		weapon = fm_get_user_weapon_entity(entity, CSW_BALROG7)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_has_balrog7[id])
		{
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			set_pev(weapon, pev_iuser4, g_skin[id])
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			Remove_balrog7(id)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_Item_Deploy_Post(ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(ent)
	if (!pev_valid(id))
		return

	if(!g_has_balrog7[id])
		return
	
	set_pev(id, pev_viewmodel2, g_skin[id]?V_MODELB:V_MODEL)
	set_pev(id, pev_weaponmodel2, P_MODEL)
	
	set_weapon_anim(id, 4)
}

public fw_Item_PostFrame(Ent)
{
	if(!pev_valid(Ent))
		return
		
	static Id; Id = pev(Ent, pev_owner)
	if(!g_has_balrog7[Id])
		return
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(Id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(Id, CSW_BALROG7)
	static iClip; iClip = get_pdata_int(Ent, 51, 4)

	if(get_pdata_int(Ent, 54, 4) && flNextAttack <= 0.0)
	{
		static temp1; temp1 = min(BALROG7_CLIP - iClip, bpammo)

		set_pdata_int(Ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(Id, CSW_BALROG7, bpammo - temp1)		
		
		set_pdata_int(Ent, 54, 0, 4)
	}		
}
public Reload7(wpn) 
{
	new id = pev(wpn, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_balrog7[id])
		return HAM_IGNORED

	static iClipExtra

	iClipExtra = BALROG7_CLIP

	g_clip[id] = -1
	
	new iClip = get_pdata_int(wpn, 51, 4)
	new iBpAmmo = cs_get_user_bpammo(id, CSW_BALROG7)
		
	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE

	if (iClip >= iClipExtra)
		return HAM_SUPERCEDE

	g_clip[id] = iClip

	return HAM_IGNORED
}
public Reload_Post7(wpn) 
{
	new id = pev(wpn, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_balrog7[id])
		return HAM_IGNORED

	if (g_clip[id] == -1)
		return HAM_IGNORED

	//g_balrog7_zoom[id] = 0
	cs_set_user_zoom(id, CS_RESET_ZOOM, 0)
	
	set_pdata_float(wpn, 48, BALROG7_RELOAD, 4)
	set_pdata_float(id, 83, BALROG7_RELOAD, 5)

	set_pdata_int(wpn, 51, g_clip[id], 4)
	set_pdata_int(wpn, 54, 1, 4)
	
	g_shot[id]=0

	return HAM_IGNORED
}
public HolsterPost(wpn)
{
	static id
	id = get_pdata_cbase(wpn, 41, 4)
	if(!g_has_balrog7[id])
		return;

	if(g_has_balrog7[id])
	{
		g_balrog7_zoom[id] = 0
		cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
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
stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
		
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
	message_end()	
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	if (pev_valid(ent) != PDATA_SAFE)
		return -1
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, 83, nexttime, 5)
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entBALROG7; entBALROG7 = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entBALROG7)) 
		return
		
	set_pdata_float(entBALROG7, 46, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entBALROG7, 47, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entBALROG7, 48, TimeIdle + 0.5, OFFSET_LINUX_WEAPONS)
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
public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(get_user_weapon(iAttacker) == CSW_BALROG7)
	{
		if(g_has_balrog7[iAttacker])
			set_msg_arg_string(4, "balrog7")
	}
                
	return PLUGIN_CONTINUE
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
