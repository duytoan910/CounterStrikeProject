#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define PLUGIN "Balrog-XI"
#define VERSION "2.0"
#define AUTHOR "Dias"
#define SUPPORT FOR ZP "Conspiracy"

#define V_MODEL "models/v_balrog11.mdl"
#define P_MODEL "models/p_balrog11.mdl"
#define W_MODEL "models/w_balrog11.mdl"
#define V_MODELB "models/v_balrog11b.mdl"

#define CSW_BALROG11 CSW_XM1014
#define weapon_balrog11 "weapon_xm1014"

#define OLD_W_MODEL "models/w_xm1014.mdl"
#define OLD_EVENT "events/xm1014.sc"
#define WEAPON_SECRETCODE 1982

#define DRAW_TIME 0.75
#define DAMAGE 45
#define FIRE_DAMAGE 400
#define BPAMMO 200

#define CHARGE_COND_AMMO 2
#define MAX_SPECIAL_AMMO 7
#define SPECIALSHOOT_DELAY 0.35
#define FIRE_SPEED 1
#define RADIUS 350
#define FIRE_CLASSNAME "balrog11_fire"
#define SYSTEM_CLASSNAME "balrog11_firesystem"

// Fire Start
#define WEAPON_ATTACH_F 30.0
#define WEAPON_ATTACH_R 10.0
#define WEAPON_ATTACH_U -5.0

native navtive_bullet_effect(id, ent, ptr)

// OFFSET
const PDATA_SAFE = 2
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_WEAPONOWNER = 41
const m_flNextAttack = 83
const m_flNextPrimaryAttack	= 46
const m_flNextSecondaryAttack	= 47

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
		
new const WeaponSounds[5][] = 
{
	"weapons/balrog11-1.wav",
	"weapons/balrog11-2.wav",
	"weapons/balrog11_draw.wav",
	"weapons/balrog11_insert.wav",
	"weapons/balrog11_charge.wav"
}

new const WeaponResources[][] =
{
	"sprites/flame_puff01.spr",
	"sprites/flame_puff01_blue.spr"
}

enum
{
	B11_ANIM_IDLE = 0,
	B11_ANIM_SHOOT,
	B11_ANIM_SHOOT_SPECIAL,
	B11_ANIM_INSERT,
	B11_ANIM_AFTER_RELOAD,
	B11_ANIM_START_RELOAD,
	B11_ANIM_DRAW
}

new g_balrog11, shot[33], g_skin[33], Float:cl_pushangle[32 + 1][3]
new g_had_balrog11[33], g_holding_attack[33], g_Shoot_Count[33], g_SpecialAmmo[33]
new g_old_weapon[33], g_event_balrog11, g_Msg_StatusIcon, g_ham_bot, g_MaxPlayers

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_think(FIRE_CLASSNAME, "fw_Think")
	register_touch(FIRE_CLASSNAME, "*", "fw_Touch")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")	
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_balrog11, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_balrog11, "fw_Item_PostFrame")
	RegisterHam(Ham_Item_Deploy, weapon_balrog11, "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_balrog11, "fw_balrog11_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_balrog11, "fw_balrog11_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	
	g_Msg_StatusIcon = get_user_msgid("StatusIcon")
	g_MaxPlayers = get_maxplayers()
	
	//register_clcmd("admin_get_balrog11", "Get_Balrog11", ADMIN_RCON)
	
	g_balrog11 = zp_register_extra_item("Balrog-XI", 3000, ZP_TEAM_HUMAN)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	engfunc(EngFunc_PrecacheModel, V_MODELB)
	
	new i
	for(i = 0; i < sizeof(WeaponSounds); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
	for(i = 0; i < sizeof(WeaponResources); i++)
		engfunc(EngFunc_PrecacheModel, WeaponResources[i])
	
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
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(OLD_EVENT, name))
		g_event_balrog11 = get_orig_retval()
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_balrog11) Get_Balrog11(id)
}

public Get_Balrog11(id)
{
	drop_weapons(id, 1)
	g_had_balrog11[id] = 1
	g_old_weapon[id] = 0
	g_holding_attack[id] = 0
	g_Shoot_Count[id] = 0
	g_SpecialAmmo[id] = 7
	g_skin[id] = random_num(0,1)
	
	fm_give_item(id, weapon_balrog11)
	cs_set_user_bpammo(id, CSW_BALROG11, BPAMMO)
	
	
	update_ammo(id)
	update_specialammo(id, g_SpecialAmmo[id], g_SpecialAmmo[id] > 0 ? 1 : 0)
}

public Remove_Balrog11(id)
{
	update_specialammo(id, g_SpecialAmmo[id], 0)
		
	g_had_balrog11[id] = 0
	g_old_weapon[id] = 0
	g_holding_attack[id] = 0
	g_Shoot_Count[id] = 0
	g_SpecialAmmo[id] = 0	
}
public Player_Spawn(id)
{
	Remove_Balrog11(id)
}
public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return	
	
	if(g_had_balrog11[id] && (get_user_weapon(id) == CSW_BALROG11 && g_old_weapon[id] != CSW_BALROG11))
	{ // Balrog Draw
		set_weapon_anim(id, B11_ANIM_DRAW)
		set_player_nextattack(id, DRAW_TIME)
		
		update_specialammo(id, g_SpecialAmmo[id], g_SpecialAmmo[id] > 0 ? 1 : 0)
	} else if(get_user_weapon(id) != CSW_BALROG11 && g_old_weapon[id] == CSW_BALROG11) {
		update_specialammo(id, g_SpecialAmmo[id], 0)
	}
	
	g_old_weapon[id] = get_user_weapon(id)
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_BALROG11 || !g_had_balrog11[id])
		return
		
	static NewButton; NewButton = get_uc(uc_handle, UC_Buttons)
	static OldButton; OldButton = pev(id, pev_oldbuttons)
	
	if(NewButton & IN_ATTACK)
	{
		if(!g_holding_attack[id]) g_holding_attack[id] = 1
	} else if(NewButton & IN_ATTACK2) {
		SpecialShoot_Handle(id)
	} else {
		if(OldButton & IN_ATTACK)
		{
			if(g_holding_attack[id]) 
			{
				g_holding_attack[id] = 0
				g_Shoot_Count[id] = 0
			}
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
		weapon = fm_get_user_weapon_entity(entity, CSW_BALROG11)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_balrog11[id])
		{
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			set_pev(weapon, pev_iuser4, g_SpecialAmmo[id])			
			set_pev(weapon, pev_iuser3, g_skin[id])
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			Remove_Balrog11(id)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_BALROG11 && g_had_balrog11[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED		
	if(get_user_weapon(invoker) == CSW_BALROG11 && g_had_balrog11[invoker] && eventid == g_event_balrog11)
	{
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)	

		if(g_holding_attack[invoker]) g_Shoot_Count[invoker]++
		else g_Shoot_Count[invoker] = 0
		
		shot[invoker]++
		//client_print(invoker, print_chat,"%i shot",shot[invoker])
		if(is_user_bot(invoker)&&shot[invoker]==15)
		{
			shot1(invoker)	
			set_task(SPECIALSHOOT_DELAY,"shot1",invoker)
			set_task(SPECIALSHOOT_DELAY*2,"shot1",invoker)
			set_task(SPECIALSHOOT_DELAY*3,"shot1",invoker)
			shot[invoker]=0
		}
		
		if(g_Shoot_Count[invoker] >= CHARGE_COND_AMMO)
		{
			g_Shoot_Count[invoker] = 0
			
			if(g_SpecialAmmo[invoker] < MAX_SPECIAL_AMMO) 
			{
				update_specialammo(invoker, g_SpecialAmmo[invoker], 0)
				g_SpecialAmmo[invoker]++
				update_specialammo(invoker, g_SpecialAmmo[invoker], 1)
				
				emit_sound(invoker, CHAN_WEAPON, WeaponSounds[4], 1.0, ATTN_NORM, 0, PITCH_NORM)				
			}
		}
		set_weapon_anim(invoker, B11_ANIM_SHOOT)
		emit_sound(invoker, CHAN_WEAPON, WeaponSounds[0], 1.0, ATTN_NORM, 0, PITCH_LOW)	

		return FMRES_SUPERCEDE
	}
	
	return FMRES_HANDLED
}
public shot1(invoker)
{
	emit_sound(invoker, CHAN_WEAPON, WeaponSounds[1], 1.0, ATTN_NORM, 0, PITCH_LOW)
	Create_FireSystem(invoker, 1)
	set_task(0.25, "Check_RadiusDamage", invoker)
	//set_task(SPECIALSHOOT_DELAY,"shot2", invoker)
}

public fw_balrog11_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_had_balrog11[Player])
		return HAM_IGNORED
		
	pev(Player,pev_punchangle,cl_pushangle[Player])
	return HAM_IGNORED
}
public fw_balrog11_PrimaryAttack_Post(Weapon)
{	
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(!is_user_alive(Player))
		return

	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)

	if(g_had_balrog11[Player])
	{
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		xs_vec_mul_scalar(push,0.5,push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
	}
}
public fw_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
	
	static Float:fFrame, Float:fNextThink, Float:fScale
	pev(iEnt, pev_frame, fFrame)
	pev(iEnt, pev_scale, fScale)
	
	// effect exp
	static iMoveType; iMoveType = pev(iEnt, pev_movetype)
	if (iMoveType == MOVETYPE_NONE)
	{
		fNextThink = 0.0015
		fFrame += random_float(0.25, 0.75)
		fScale += 0.01
		
		if(fFrame > 21.0)
		{
			engfunc(EngFunc_RemoveEntity, iEnt)
			return
		}
	} else {
		fNextThink = 0.045
		
		fFrame += random_float(0.5, 1.0)
		fScale += 0.001
		
		fFrame = floatmin(21.0, fFrame)
		fScale = floatmin(1.5, fFrame)
	}
	
	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_scale, fScale)
	set_pev(iEnt, pev_nextthink, halflife_time() + fNextThink)
	
	// time remove
	static Float:fTimeRemove
	pev(iEnt, pev_fuser1, fTimeRemove)
	if(get_gametime() >= fTimeRemove)
	{
		static Float:Amount; pev(iEnt, pev_renderamt, Amount)
		if(Amount <= 5.0)
		{
			engfunc(EngFunc_RemoveEntity, iEnt)
			return
		} else {
			Amount -= 5.0
			set_pev(iEnt, pev_renderamt, Amount)
		}
	}
}

public fw_Touch(ent, id)
{
	if(!pev_valid(ent))
		return
		
	if(pev_valid(id))
	{
		static Classname[32]
		pev(id, pev_classname, Classname, sizeof(Classname))
		
		if(equal(Classname, FIRE_CLASSNAME)) return
	}
		
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_solid, SOLID_NOT)
}

public fw_TraceAttack(Ent, Attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	if(!is_user_alive(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_BALROG11 || !g_had_balrog11[Attacker])
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]
	
	get_tr2(ptr, TR_vecEndPos, flEnd)
	get_tr2(ptr, TR_vecPlaneNormal, vecPlane)		
		
	if(!is_user_alive(Ent))
	{
		navtive_bullet_effect(Attacker, Ent, ptr)
	}
		
	SetHamParamFloat(3, float(DAMAGE))	

	return HAM_HANDLED	
}

public fw_Item_AddToPlayer_Post(ent, id)
{
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		g_had_balrog11[id] = 1
		
		set_pev(ent, pev_impulse, 0)
		g_SpecialAmmo[id] = pev(ent, pev_iuser4)
		g_skin[id] = pev(ent, pev_iuser3)
	}		
}

public fw_Item_PostFrame(ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(ent)
	if (!pev_valid(id))
		return

	if(!g_had_balrog11[id])
		return
		
	if(get_pdata_int(ent, 55, OFFSET_LINUX_WEAPONS) == 1) set_weapon_anim(id, B11_ANIM_INSERT)
}

public fw_Item_Deploy_Post(ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(ent)
	if (!pev_valid(id))
		return

	if(!g_had_balrog11[id])
		return
		
	set_pev(id, pev_viewmodel2, g_skin[id]?V_MODELB:V_MODEL)
	set_pev(id, pev_weaponmodel2, P_MODEL)
}

public update_ammo(id)
{
	if(!is_user_alive(id))
		return
	
	static weapon_ent; weapon_ent = fm_get_user_weapon_entity(id, CSW_BALROG11)
	if(!pev_valid(weapon_ent)) return
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_BALROG11)
	write_byte(cs_get_weapon_ammo(weapon_ent))
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(1)
	write_byte(cs_get_user_bpammo(id, CSW_BALROG11))
	message_end()
}

public update_specialammo(id, Ammo, On)
{
	static AmmoSprites[33]
	format(AmmoSprites, sizeof(AmmoSprites), "number_%d", Ammo)
  	
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_StatusIcon, {0,0,0}, id)
	write_byte(On)
	write_string(AmmoSprites)
	write_byte(42) // red
	write_byte(212) // green
	write_byte(255) // blue
	message_end()
}

public SpecialShoot_Handle(id)
{
	if(get_pdata_float(id, 83, 5) > 0.0)
		return
	if(g_SpecialAmmo[id] <= 0)
		return		

	create_fake_attack(id)	
	
	// Shoot Handle
	set_player_nextattack(id, SPECIALSHOOT_DELAY)
	set_weapons_timeidle(id, CSW_BALROG11, SPECIALSHOOT_DELAY)
	
	update_specialammo(id, g_SpecialAmmo[id], 0)
	g_SpecialAmmo[id]--
	update_specialammo(id, g_SpecialAmmo[id], g_SpecialAmmo[id] > 0 ? 1 : 0)
	
	set_weapon_anim(id, B11_ANIM_SHOOT_SPECIAL)
	emit_sound(id, CHAN_WEAPON, WeaponSounds[1], 1.0, ATTN_NORM, 0, PITCH_LOW)
	
	Create_FireSystem(id, 1)
	set_task(0.25, "Check_RadiusDamage", id)
}

public Check_RadiusDamage(id)
{
	if(!is_user_alive(id))
		return
	static Float:Origin[3], Float:MyOrigin[3], Float:DamageMulti, Float:DmgMulti
	pev(id, pev_origin, MyOrigin)
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(id == i)
			continue
		pev(i, pev_origin, Origin)
		if(!is_in_viewcone(id, Origin, 1))
			continue
		if(entity_range(id, i) > float(RADIUS))
			continue
			
		DmgMulti = 1.1;
		DamageMulti = entity_range(id, i) / float(RADIUS)
		DmgMulti -= DamageMulti
		
		ExecuteHamB(Ham_TakeDamage, i, id, id, is_deadlyshot(id)?random_float(FIRE_DAMAGE-15.0,FIRE_DAMAGE+15.0)*1.5:random_float(FIRE_DAMAGE-15.0,FIRE_DAMAGE+15.0), DMG_BULLET)
	}
}

public create_fake_attack(id)
{
	static weapon
	weapon = fm_find_ent_by_owner(-1, "weapon_knife", id)
	
	if(pev_valid(weapon)) ExecuteHamB(Ham_Weapon_PrimaryAttack, weapon)
}

public Create_FireSystem(id, OffSet)
{
	const MAX_FIRE = 8
	static Float:StartOrigin[3], Float:TargetOrigin[MAX_FIRE][3], Float:Speed[MAX_FIRE]

	// Get Target
	
	// -- Left
	get_position(id, 100.0,	random_float(-10.0, -30.0), WEAPON_ATTACH_U, TargetOrigin[0]); Speed[0] = 140.0 * float(FIRE_SPEED)
	get_position(id, 100.0, random_float(-10.0, -20.0), WEAPON_ATTACH_U, TargetOrigin[1]); Speed[1] = 160.0 * float(FIRE_SPEED)
	get_position(id, 100.0, random_float(-10.0, -10.0), WEAPON_ATTACH_U, TargetOrigin[2]); Speed[2] = 180.0 * float(FIRE_SPEED)

	// -- Center
	get_position(id, 100.0, 0.0, WEAPON_ATTACH_U, TargetOrigin[3]); Speed[3] = 200.0 * float(FIRE_SPEED)
	get_position(id, 100.0, 0.0, WEAPON_ATTACH_U, TargetOrigin[4]); Speed[4] = 200.0 * float(FIRE_SPEED)
	
	// -- Right
	get_position(id, 100.0, random_float(10.0, 10.0), WEAPON_ATTACH_U, TargetOrigin[5]); Speed[5] = 180.0 * float(FIRE_SPEED)
	get_position(id, 100.0, random_float(10.0, 20.0) , WEAPON_ATTACH_U, TargetOrigin[6]); Speed[6] = 160.0 * float(FIRE_SPEED)
	get_position(id, 100.0,	random_float(10.0, 30.0), WEAPON_ATTACH_U, TargetOrigin[7]); Speed[7] = 140.0 * float(FIRE_SPEED)
	for(new i = 0; i < MAX_FIRE; i++)
	{
		// Get Start
		get_position(id, random_float(30.0, 40.0), 0.0, WEAPON_ATTACH_U, StartOrigin)
		Create_Fire(id, StartOrigin, TargetOrigin[i], Speed[i], OffSet)
	}
}

public Create_Fire(id, Float:Origin[3], Float:TargetOrigin[3], Float:Speed, Offset)
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Ent)) return
	
	static Float:Velocity[3]

	// Set info for ent
	set_pev(Ent, pev_movetype, MOVETYPE_FLY)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 100.0)
	set_pev(Ent, pev_fuser1, get_gametime() + 0.01)	// time remove
	set_pev(Ent, pev_scale, random_float(0.25, 0.75))
	set_pev(Ent, pev_nextthink, halflife_time() + 0.05)
	
	entity_set_string(Ent, EV_SZ_classname, FIRE_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, WeaponResources[g_skin[id]?1:0])
	set_pev(Ent, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(Ent, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(Ent, pev_origin, Origin)
	set_pev(Ent, pev_gravity, 0.01)
	set_pev(Ent, pev_solid, SOLID_TRIGGER)
	set_pev(Ent, pev_frame, 0.0)
	set_pev(Ent, pev_owner, id)
	set_pev(Ent, pev_iuser4, Offset)
	
	get_speed_vector(Origin, TargetOrigin, Speed * 3.0, Velocity)
	set_pev(Ent, pev_velocity, Velocity)
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
		
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entwpn, 47, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, OFFSET_LINUX_WEAPONS)
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP, vUp)
	
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
public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(get_user_weapon(iAttacker) == CSW_BALROG11)
	{
		if(g_had_balrog11[iAttacker])
			set_msg_arg_string(4, "balrog11b")
	}
                
	return PLUGIN_CONTINUE
}
