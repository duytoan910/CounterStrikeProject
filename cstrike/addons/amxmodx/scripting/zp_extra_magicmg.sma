#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>
#include <metadrawer>
#include <toan>

#define PLUGIN "Balrog-XI"
#define VERSION "2.0"
#define AUTHOR "Dias"
#define SUPPORT FOR ZP "Conspiracy"

#define V_MODEL "models/v_magicmg.mdl"
#define P_MODEL "models/p_magicmg.mdl"
#define W_MODEL "models/w_magicmg.mdl"

new const WEAPON_SOUND_FIRE[][] = 
{
	"weapons/magicmg-1.wav",
	"weapons/magicmg-2.wav"
};

new const ENTITY_MISSILE_SPRITE[][] =
{
	"sprites/ef_magicmgmissile1.spr",
	"sprites/ef_magicmgmissile2.spr"
};
new const ENTITY_MISSILE_EXP_SPRITE[][] =
{
	"sprites/ef_magicmgexplo.spr",
	"sprites/ef_magicmgexplo2.spr"
};
new const ENTITY_SPRITE[][] =
{
	"sprites/ef_magicmgdraw.spr",
	"sprites/ef_magicmgidle.spr",
	"sprites/ef_magicmgreloadstart.spr",
	"sprites/ef_magicmgreloadcharge.spr",
	"sprites/ef_magicmgshoot2.spr"
};
new const WEAPON_SOUND_READY[] = 	"weapons/magicmg_alarm.wav";
new const ENTITY_MISSILE_EXP_SOUND[][] =
{
	"weapons/magicmg_1exp.wav",
	"weapons/magicmg_2exp.wav"
};

#define CSW_MAGICMG CSW_M249
#define weapon_magicmg "weapon_m249"
#define OLD_W_MODEL "models/w_m249.mdl"
#define OLD_EVENT "events/m249.sc"

#define WEAPON_SECRETCODE 1569

#define	magicmg_NAME "Shining Heart Rod"
#define	magicmg_COST	3000

#define magicmg_CLIP 100
#define magicmg_AMMO 200
#define magicmg_SPEED 0.2
#define magicmg_RECOIL 0.3
#define MAGICMG_RELOAD 4.0
#define magicmg_DAMAGE 1.3

const WEAPON_HIT_COUNT = 30;
const Float: ENTITY_MISSILE_RADIUS_EX = 125.0;
const Float: ENTITY_MISSILE_RADIUS = 75.0;

#define ENTITY_MISSILE_DAMAGE		random_float(100.0, 150.0)
#define ENTITY_MISSILE_DAMAGE_EX	random_float(1500.0, 2000.0)
#define ATTACHMENT_CLASSNAME "magicmg_missile"

#define TASK_IDLE  4194
#define TASK_RELOAD  4195

// OFFSET
const PDATA_SAFE = 2
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_WEAPONOWNER = 41

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

enum
{
	ANIM_IDLE = 0,
	ANIM_SHOOT,
	ANIM_SHOOT2,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT_2,
	ANIM_IDLE2
}

new g_magicmg, g_clip[33], Float:cl_pushangle[33][3]
new g_had_magicmg[33], HitCount[33], m_iBlood[2]
new g_old_weapon[33], g_event_magicmg, g_ham_bot
new g_exp_spr[sizeof(ENTITY_MISSILE_SPRITE)]
new g_spr[sizeof(ENTITY_MISSILE_EXP_SPRITE)]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_magicmg, "fw_Item_AddToPlayer_Post", 1)
	
	RegisterHam(Ham_Item_Deploy, weapon_magicmg, "fw_Item_Deploy")
	RegisterHam(Ham_Item_Deploy, weapon_magicmg, "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_Reload, weapon_magicmg, "Reload7")
	RegisterHam(Ham_Weapon_Reload, weapon_magicmg, "Reload_Post7", 1)
	
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_magicmg, "fw_WeaponIdle", false);
	RegisterHam(Ham_Item_PostFrame, weapon_magicmg, "fw_Item_PostFrame")	
	RegisterHam(Ham_Item_Holster, weapon_magicmg, "HolsterPost", 1)
	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_magicmg, "HAM_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_magicmg, "HAM_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	
	register_think(ATTACHMENT_CLASSNAME, "CSprite__Think_Post")
	register_touch(ATTACHMENT_CLASSNAME, "*", "CSprite__Touch_Post")
	
	g_magicmg = zp_register_extra_item(magicmg_NAME, magicmg_COST, ZP_TEAM_HUMAN)
	
	static i;
	for(i=0;i<sizeof(ENTITY_SPRITE);i++)
		md_loadsprite(ENTITY_SPRITE[i])
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	precache_sound(WEAPON_SOUND_READY)
	static i;
	for(i=0;i<sizeof(ENTITY_MISSILE_EXP_SPRITE);i++)
		g_exp_spr[i] = engfunc(EngFunc_PrecacheModel, ENTITY_MISSILE_EXP_SPRITE[i])
	for(i=0;i<sizeof(ENTITY_MISSILE_SPRITE);i++)
		g_spr[i] = engfunc(EngFunc_PrecacheModel, ENTITY_MISSILE_SPRITE[i])	
	for(i=0;i<sizeof(WEAPON_SOUND_FIRE);i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_FIRE[i])
	for(i=0;i<sizeof(ENTITY_MISSILE_EXP_SOUND);i++)
		engfunc(EngFunc_PrecacheSound, ENTITY_MISSILE_EXP_SOUND[i])
		
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	
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
	RegisterHamFromEntity(Ham_Spawn, id, "Player_Spawn")
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(OLD_EVENT, name))
		g_event_magicmg = get_orig_retval()
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_magicmg) Get_magicmg(id)
}

public Get_magicmg(id)
{
	drop_weapons(id, 1)
	g_had_magicmg[id] = 1
	g_old_weapon[id] = 0
	HitCount[id] = 0
	
	fm_give_item(id, weapon_magicmg)
	cs_set_user_bpammo(id, CSW_MAGICMG, magicmg_AMMO)
}

public Remove_magicmg(id)
{
	if(g_had_magicmg[id])
	{
		g_had_magicmg[id] = 0
		g_old_weapon[id] = 0
		UTIL_StatusIcon(id, 0);
		md_removedrawing(id, 2, 4)
		remove_task(id+TASK_IDLE)
		remove_task(id+TASK_RELOAD)
	}
}
public zp_user_infected_post(id) 
{
	Remove_magicmg(id)
}
public Player_Spawn(id)
{
	Remove_magicmg(id)
}
public Event_CurWeapon(id)
{
	if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
		return;
	
	if(read_data(2) != CSW_MAGICMG || !g_had_magicmg[id])
		return	
		
	if(!g_had_magicmg[id])
		return;
	
	static weapon[32],Ent
	get_weaponname(read_data(2),weapon,31)
	Ent = find_ent_by_owner(-1,weapon,id)
	if(Ent)
	{
		static Float:Delay
		Delay = get_pdata_float( Ent, 46, 4)
		
		if (Delay > 0.0)
		{
			set_pdata_float(Ent, 46, magicmg_SPEED, 4)
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
		weapon = fm_get_user_weapon_entity(entity, CSW_MAGICMG)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_magicmg[id])
		{
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			set_pev(weapon, pev_iuser4,HitCount[id])
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			Remove_magicmg(id)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_Item_AddToPlayer_Post(ent, id)
{
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		g_had_magicmg[id] = 1
		HitCount[id] = pev(ent, pev_iuser4)
		set_pev(ent, pev_impulse, 0)
	}		
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_MAGICMG)
		{
			if(g_had_magicmg[attacker])
			{
				SetHamParamFloat(4, damage * magicmg_DAMAGE)
			}
		}
	}
}
public fw_TraceAttack(Ent, Attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	if(!is_user_alive(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_MAGICMG || !g_had_magicmg[Attacker])
		return HAM_IGNORED
		
	return HAM_SUPERCEDE
}

public HAM_PrimaryAttack(weapon)
{
	new Player = get_pdata_cbase(weapon, 41, 4)
	if (!g_had_magicmg[Player])
		return;
}
public HAM_PrimaryAttack_Post(wpn) 
{
	new id = pev(wpn, pev_owner), clip, bpammo
	get_user_weapon(id, clip, bpammo)
	if(g_had_magicmg[id]) 
	{
		if(clip > 0) 
		{			
			new Float:push[3];
			pev(id,pev_punchangle,push);
			xs_vec_sub(push,cl_pushangle[id],push);
			xs_vec_mul_scalar(push,magicmg_RECOIL,push);
			xs_vec_add(push,cl_pushangle[id],push);
			set_pev(id,pev_punchangle,push);
			
			set_pdata_int(wpn, 51, clip-1, 4)
			CreateMissile(id, 0)
			if(is_user_bot(id))
			{
				if(HitCount[id] >= WEAPON_HIT_COUNT)
				{
					remove_task(id+TASK_IDLE)
					remove_task(id+TASK_RELOAD)
					set_weapon_anim(id, ANIM_SHOOT_2)
					set_task(1.0,"Missile2",id)
					
					set_pdata_float(id, 83, 2.0)	
					
					UTIL_StatusIcon(id, 0)
					HitCount[id]=0
				}				
			}
		}			
	}
}
public CreateMissile(id, iMissileType)
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Ent)) return

	new Float: AttachO[3];	
	if(!iMissileType)
		get_position(id, 10.0, 2.0, -8.0, AttachO)
	else get_position(id, 10.0, 0.0, 0.0, AttachO)
	
	// Set info for ent
	set_pev(Ent, pev_movetype, MOVETYPE_FLY)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 200.0)
	set_pev(Ent, pev_owner, id)
	set_pev(Ent, pev_scale, iMissileType ? 0.5 : random_float(0.1, 0.2));
	
	entity_set_string(Ent, EV_SZ_classname, ATTACHMENT_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, ENTITY_MISSILE_SPRITE[iMissileType])
	set_pev(Ent, pev_mins, Float:{-1.5, -1.5, -1.5})
	set_pev(Ent, pev_maxs, Float:{1.5, 1.5, 1.5})
	set_pev(Ent, pev_origin, AttachO)
	set_pev(Ent, pev_gravity, 0.01)
	set_pev(Ent, pev_solid, SOLID_BBOX)
	set_pev(Ent, pev_frame, 0.0)
	
	set_pev(Ent, pev_iuser4, random_num(0, 1));
	set_pev(Ent, pev_iuser3, iMissileType);
	
	set_pev(Ent, pev_nextthink, halflife_time() + 0.2)
	
	static Float:Velocity[3]
	velocity_by_aim(id, 1000 , Velocity)
	set_pev(Ent, pev_velocity, Velocity)	
}
public CSprite__Think_Post(iEntity)
{
	if(!pev_valid(iEntity)) return HAM_IGNORED;
	
	if(pev(iEntity, pev_iuser3) == 1) return HAM_IGNORED;

	new Float: flGameTime = get_gametime();
	new iRotate = pev(iEntity, pev_iuser4);
	new Float: vecAngles[3]; pev(iEntity, pev_angles, vecAngles);

	vecAngles[1] += iRotate ? 15.0 : -15.0;
	vecAngles[2] += iRotate ? 15.0 : -15.0;

	set_pev(iEntity, pev_angles, vecAngles);
	set_pev(iEntity, pev_nextthink, flGameTime + 0.05);
	
	return HAM_IGNORED;
}

public CSprite__Touch_Post(iEntity, iTouch)
{
	if(!pev_valid(iEntity)) return HAM_IGNORED;

	new iOwner = pev(iEntity, pev_owner);
	if(iTouch == iOwner) return HAM_SUPERCEDE;

	new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
	if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
	{
		set_pev(iEntity, pev_flags, FL_KILLME);
		return HAM_IGNORED;
	}

	new iMissileType = pev(iEntity, pev_iuser3);

	emit_sound(iEntity, CHAN_WEAPON, ENTITY_MISSILE_EXP_SOUND[iMissileType], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_EXPLOSION); // TE
	engfunc(EngFunc_WriteCoord, vecOrigin[0]); // Position X
	engfunc(EngFunc_WriteCoord, vecOrigin[1]); // Position Y
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 20.0); // Position Z
	write_short(g_exp_spr[iMissileType]); // Model Index
	write_byte(iMissileType ? 16 : 8); // Scale
	write_byte(32); // Framerate
	write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES); // Flags
	message_end();

	new iVictim = FM_NULLENT;
	new Float: flRadius = iMissileType ? ENTITY_MISSILE_RADIUS_EX : ENTITY_MISSILE_RADIUS;
	new Float: flDamage = iMissileType ? ENTITY_MISSILE_DAMAGE_EX : ENTITY_MISSILE_DAMAGE;
	
	is_deadlyshot(iOwner)?flDamage*1.5:flDamage	
	
	if(is_user_alive(iTouch) && zp_get_user_zombie(iTouch))
		UTIL_BloodDrips(vecOrigin, iTouch, floatround(flDamage));
		
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, flRadius)) > 0)
	{
		if(pev(iVictim, pev_takedamage) == DAMAGE_NO) continue;
		if(is_user_alive(iVictim))
		{
			if(iVictim == iOwner || !zp_get_user_zombie(iVictim) || !is_wall_between_points(iOwner, iVictim))
				continue;
		}
		else if(pev(iVictim, pev_solid) == SOLID_BSP)
		{
			if(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
				continue;
		}

		if(is_user_alive(iVictim))
		{
			set_pdata_int(iVictim, 75, HIT_GENERIC, 5);

			if(!iMissileType) CWeapon__CheckHitCount(iOwner);
		}

		ExecuteHamB(Ham_TakeDamage, iVictim, iOwner, iOwner, flDamage, DMG_BULLET|DMG_NEVERGIB);
	}

	set_pev(iEntity, pev_flags, FL_KILLME);
	return HAM_IGNORED;
}
CWeapon__CheckHitCount(id)
{
	static iItem; iItem = get_pdata_cbase(id, 373, 4);

	if(!iItem || pev_valid(iItem) != PDATA_SAFE) return;
	
	if(!g_had_magicmg[id]) return;
	
	if(HitCount[id] > WEAPON_HIT_COUNT) return;

	if(HitCount[id] == WEAPON_HIT_COUNT)
	{
		UTIL_StatusIcon(id, 1);
		UTIL_ScreenFade(id, (1<<10) * 1, (1<<10) * 1, 0x0000, 219, 48, 130, 70);

		emit_sound(id, CHAN_WEAPON, WEAPON_SOUND_READY, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}

	HitCount[id]++
}
public fw_CmdStart(id, uc_handle, seed) 
{
	new ammo, clip, weapon = get_user_weapon(id, clip, ammo)
	if (!g_had_magicmg[id] || weapon != CSW_MAGICMG || !is_user_alive(id))
		return
	
	if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)) 
	{
		if(HitCount[id] >= WEAPON_HIT_COUNT)
		{
			set_weapon_anim(id, ANIM_SHOOT_2)
			
			remove_task(id+TASK_IDLE)
			remove_task(id+TASK_RELOAD)
			md_playsprite(id, 4, ENTITY_SPRITE[4], 0.0, 0.0, 0, 0, 255, 255, 255, 255 , SPR_ADDITIVE, 25, 0, ALIGN_NORMAL, md_getscreenwidth(), md_getscreenheight()+220)
			
			set_task(1.0,"Missile2",id)
			
			set_pdata_float(id, 83, 2.0)				
			
			UTIL_StatusIcon(id, 0)
			HitCount[id]=0
		}	
	}
}
public Missile2(id)
{		
	CreateMissile(id, 1);
}
public fw_Item_Deploy(ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(ent)
	if (!pev_valid(id))
		return

	if(!g_had_magicmg[id])
		return
		
	remove_task(id+TASK_IDLE)
	remove_task(id+TASK_RELOAD)
	md_playsprite(id, 4, ENTITY_SPRITE[0], 0.0, 0.0, 0, 0, 255, 255, 255, 255, SPR_ADDITIVE, 35, 0, ALIGN_NORMAL, md_getscreenwidth(), md_getscreenheight()+220)
}
public fw_Item_Deploy_Post(ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(ent)
	if (!pev_valid(id))
		return

	if(!g_had_magicmg[id])
		return
		
	set_pev(id, pev_viewmodel2, V_MODEL)
	set_pev(id, pev_weaponmodel2, P_MODEL)
	
	set_weapon_anim(id, 4)	
	
	UTIL_StatusIcon(id, HitCount[id] >= WEAPON_HIT_COUNT ? 1 : 0);
}
public fw_Item_PostFrame(Ent)
{
	if(!pev_valid(Ent))
		return
		
	static Id; Id = pev(Ent, pev_owner)
	if(!g_had_magicmg[Id])
		return
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(Id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(Id, CSW_MAGICMG)
	static iClip; iClip = get_pdata_int(Ent, 51, 4)

	if(get_pdata_int(Ent, 54, 4) && flNextAttack <= 0.0)
	{
		static temp1; temp1 = min(magicmg_CLIP - iClip, bpammo)

		set_pdata_int(Ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(Id, CSW_MAGICMG, bpammo - temp1)		
		
		set_pdata_int(Ent, 54, 0, 4)
	}		
}
public Reload7(wpn) 
{
	new id = pev(wpn, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_had_magicmg[id])
		return HAM_IGNORED

	static iClipExtra

	iClipExtra = magicmg_CLIP

	g_clip[id] = -1
	
	new iClip = get_pdata_int(wpn, 51, 4)
	new iBpAmmo = cs_get_user_bpammo(id, CSW_MAGICMG)
		
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

	if (!g_had_magicmg[id])
		return HAM_IGNORED

	if (g_clip[id] == -1)
		return HAM_IGNORED
		
	remove_task(id+TASK_IDLE)
	remove_task(id+TASK_RELOAD)
	set_weapon_anim(id, ANIM_RELOAD)
	
	set_pdata_float(wpn, 48, MAGICMG_RELOAD, 4)
	set_pdata_float(id, 83, MAGICMG_RELOAD, 5)
	
	set_pdata_int(wpn, 51, g_clip[id], 4)
	set_pdata_int(wpn, 54, 1, 4)
	
	set_task(0.5, "Play_SPR_Reload1", id+TASK_RELOAD)
	
	return HAM_IGNORED
}
public Play_SPR_Reload1(id)
{
	id -= TASK_RELOAD
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_had_magicmg[id] || get_user_weapon(id) != CSW_MAGICMG)
		return
		
	remove_task(id+TASK_IDLE)
	md_playsprite(id, 4, ENTITY_SPRITE[2], 0.0, 0.0, 0, 0, 255, 255, 255, 255 , SPR_ADDITIVE, 0, 0, ALIGN_NORMAL, md_getscreenwidth(), md_getscreenheight()+220)
	
	set_task(2.0, "Play_SPR_Reload2", id+TASK_RELOAD)
}
public Play_SPR_Reload2(id)
{
	id -= TASK_RELOAD
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_had_magicmg[id] || get_user_weapon(id) != CSW_MAGICMG)
		return
		
	md_playsprite(id, 4, ENTITY_SPRITE[3], 0.0, 0.0, 0, 0, 255, 255, 255, 255 , SPR_ADDITIVE, 0, 0, ALIGN_NORMAL, md_getscreenwidth(), md_getscreenheight()+220)
	
}
public fw_WeaponIdle(iItem)
{
	new id = get_pdata_cbase(iItem, 41, 4)

	if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_had_magicmg[id] || get_user_weapon(id) != CSW_MAGICMG)
		return HAM_IGNORED;

	static iIdleAnim;
	
	if(random_num(0, 10) <= 2) // Chance for second idle anim 10%
		iIdleAnim = 1;
	else iIdleAnim = 0;
	
	if(get_pdata_float(iItem, 48, 4) <= 0.25)
	{
		if(iIdleAnim)
		{	
			set_weapon_anim(id, ANIM_IDLE2);
			set_task(0.7, "Play_SPR_Idle2", id+TASK_IDLE)
		}
		else set_weapon_anim(id, ANIM_IDLE);
		set_pdata_float(iItem, 48, iIdleAnim?3.0:60.0, 4)
		
		return HAM_SUPERCEDE;
	}	
	return HAM_SUPERCEDE;
}
public Play_SPR_Idle2(id)
{
	id-=TASK_IDLE
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_had_magicmg[id] || get_user_weapon(id) != CSW_MAGICMG)
		return
		
	remove_task(id+TASK_RELOAD)
	md_playsprite(id, 4, ENTITY_SPRITE[1], 0.5, 0.5, 1, 1, 255, 255, 255, 255 , SPR_ADDITIVE, 0, 0, ALIGN_NORMAL, md_getscreenwidth(), md_getscreenheight()+440)
}
public HolsterPost(wpn)
{
	static id
	id = get_pdata_cbase(wpn, 41, 4)
	if(!g_had_magicmg[id])
		return;
		
	UTIL_StatusIcon(id, 0);	
	md_removedrawing(id, 2, 4)
	remove_task(id+TASK_IDLE)
	remove_task(id+TASK_RELOAD)
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_MAGICMG && g_had_magicmg[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED		
	if(get_user_weapon(invoker) == CSW_MAGICMG && g_had_magicmg[invoker] && eventid == g_event_magicmg)
	{
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)	

		remove_task(invoker+TASK_IDLE)
		remove_task(invoker+TASK_RELOAD)
		set_weapon_anim(invoker, random_num(ANIM_SHOOT,ANIM_SHOOT2))
		emit_sound(invoker, CHAN_WEAPON, WEAPON_SOUND_FIRE[0], 1.0, ATTN_NORM, 0, PITCH_LOW)	

		return FMRES_SUPERCEDE
	}
	
	return FMRES_HANDLED
}

stock UTIL_StatusIcon(id, iUpdateMode)
{
	// message_begin(MSG_ONE, get_user_msgid("StatusIcon"), { 0, 0, 0 }, id);
	// write_byte(iUpdateMode ? 1 : 0);
	// write_string("number_1"); 
	// write_byte(219);
	// write_byte(48); 
	// write_byte(130);
	// message_end();

	nav_set_special_ammo(id, iUpdateMode ? 1 : 0)
}

stock UTIL_ScreenFade(id, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0)
{
	if(!id)
		message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, get_user_msgid("ScreenFade"));
	else message_begin(iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id);

	write_short(iDuration);
	write_short(iHoldTime);
	write_short(iFlags);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
}
public UTIL_BloodDrips(Float: vecOrigin[3], iVictim, iAmount)
{
	if(iAmount > 255) iAmount = 255;
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(m_iBlood[1]);
	write_short(m_iBlood[0]);
	write_byte(248);
	write_byte(min(max(3, iAmount / 10), 16));
	message_end();
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
			static wname[32]
			get_weaponname(weaponid, wname, charsmax(wname))

			// Player drops the weapon and looses his bpammo
			engclient_cmd(id, "drop", wname)
			cs_set_user_bpammo(id, weaponid, 0)
		}
	}
}
stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	if(!pev_valid(ent))
		return
		
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_angles, vAngle) // if normal entity ,use pev_angles
	
	vAngle[0] = 0.0
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(get_user_weapon(iAttacker) == CSW_MAGICMG)
	{
		if(g_had_magicmg[iAttacker])
			set_msg_arg_string(4, "magicmg")
	}
                
	return PLUGIN_CONTINUE
}

stock is_wall_between_points(id, iEntity)
{
	if(!is_user_alive(iEntity))
		return 0;

	new iTrace = create_tr2();
	new Float: flStart[3], Float: flEnd[3], Float: flEndPos[3];

	pev(id, pev_origin, flStart);
	pev(iEntity, pev_origin, flEnd);

	engfunc(EngFunc_TraceLine, flStart, flEnd, IGNORE_MONSTERS, id, iTrace);
	get_tr2(iTrace, TR_vecEndPos, flEndPos);

	free_tr2(iTrace);

	return xs_vec_equal(flEnd, flEndPos);
}
