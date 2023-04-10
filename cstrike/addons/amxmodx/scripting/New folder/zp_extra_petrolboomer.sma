#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <zombieplague>

#define PLUGIN "[CSO] Weapon: Petrol Boomer"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define CSW_PETROLBOOMER CSW_M249
#define weapon_petrolboomer "weapon_m249"

#define MAGAZINE 200
#define MOLOTOV_SPEED 750.0

#define WEAPON_ANIMEXT "rifle"
#define WEAPON_OLDWMODEL "models/w_m249.mdl"
#define WEAPON_SECRETCODE 1972014

#define DAMAGE_EXPLOSION 650.0 // 500 for Zombie
#define DAMAGE_BURN 5.0 // 100 for Zombie
#define DAMAGE_RADIUS 70.0

#define TIME_DRAW 0.75
#define TIME_RELOAD 4.2

#define FIRE2_CLASSNAME "smallfire"
#define FLAME_FAKE_CLASSNAME "ToanFakeFlame"
#define MOLOTOV_CLASSNAME "molotov"

#define MODEL_V "models/v_petrolboomer.mdl"
#define MODEL_P "models/p_petrolboomer.mdl"
#define MODEL_W "models/w_petrolboomer.mdl"
#define MODEL_S "models/s_petrolboomer.mdl"

new const WeaponSounds[6][] = 
{
	"weapons/petrolboomer_shoot.wav",
	"weapons/petrolboomer_explosion.wav",
	"weapons/petrolboomer_idle.wav",
	"weapons/petrolboomer_reload.wav",
	"weapons/petrolboomer_draw.wav",
	"weapons/petrolboomer_draw_empty.wav"
}

new const WeaponResources[][] = 
{
	"sprites/flame2.spr"
}

enum
{
	ANIM_IDLE = 0,
	ANIM_SHOOT,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_DRAW_EMPTY,
	ANIM_IDLE_EMPTY
}

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_Had_PB, g_id, cvar_optimize
new g_ExpSprId, spr_trail
new g_Reloading[33]
new g_wpnID[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_CmdStart, "fw_CmdStart")			
	
	register_think(FIRE2_CLASSNAME, "fw_Fire2Think")
	register_think(FLAME_FAKE_CLASSNAME, "FlameFakeThink")
	register_touch(MOLOTOV_CLASSNAME, "*", "fw_Touch_Molotov")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_petrolboomer, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_Deploy, weapon_petrolboomer, "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_Reload, weapon_petrolboomer, "fw_Item_Reload");
	
	cvar_optimize = register_cvar("zp_optimize", "0")
	
	g_id = zp_register_extra_item("Petrol Boomer", 3000, ZP_TEAM_HUMAN)
}

public plugin_precache()
{
	precache_model(MODEL_V)
	precache_model(MODEL_P)
	precache_model(MODEL_W)
	precache_model(MODEL_S)
	
	for(new i = 0; i < sizeof(WeaponSounds); i++)
		precache_sound(WeaponSounds[i])
	for(new i = 0; i < sizeof(WeaponResources); i++)
	{
		precache_model(WeaponResources[i])
	}
	
	g_ExpSprId = precache_model("sprites/zerogxplode.spr")
	spr_trail = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr")
}

public zp_extra_item_selected(id, ItemID)
{
	if(ItemID == g_id)
	{
		drop_weapons(id, 1)
		Get_PB(id)
	}
}
public Get_PB(id)
{
	Set_BitVar(g_Had_PB, id)
	
	new iWep2 = give_item(id, weapon_petrolboomer)
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, 1)
		cs_set_user_bpammo (id, CSW_PETROLBOOMER, MAGAZINE)
		set_pdata_float(id, 83, 1.0, 5)
	}	
}

public Event_NewRound() remove_entity_name(FIRE2_CLASSNAME)
public Player_Spawn(id)
{
	UnSet_BitVar(g_Had_PB, id)
}
public Remove_PB(id)
{
	UnSet_BitVar(g_Had_PB, id)
}
public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	pev(entity, pev_classname, szClassName, charsmax(szClassName))
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static id; id = pev(entity, pev_owner)
	
	if(equal(model, WEAPON_OLDWMODEL))
	{
		static weapon
		weapon = fm_find_ent_by_owner(-1, weapon_petrolboomer, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(Get_BitVar(g_Had_PB, id))
		{
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			set_pev(weapon, pev_iuser1, MAGAZINE)
			
			engfunc(EngFunc_SetModel, entity, MODEL_W)
			Remove_PB(id)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(get_user_weapon(id) != CSW_PETROLBOOMER || !Get_BitVar(g_Had_PB, id))
		return FMRES_IGNORED
	
	set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(get_user_weapon(id) != CSW_PETROLBOOMER || !Get_BitVar(g_Had_PB, id))
		return
	
	static CurButton; CurButton = get_uc(uc_handle, UC_Buttons)
	if(CurButton & IN_ATTACK)
	{
		CurButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, CurButton)
		if(!g_Reloading[id])
			PetrolBoomer_AttackHandle(id)
	}
	return 
}

public PetrolBoomer_AttackHandle(id)
{
	if(get_pdata_float(id, 83, 5) > 0.0)
		return

	Set_Weapon_Anim(id, ANIM_SHOOT)
	set_task(1.0, "ReloadAnim", id)
		
	emit_sound(id, CHAN_WEAPON, WeaponSounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	Create_Molotov(id)
	Make_Push(id)
	
	g_Reloading[id] = true;
	
	Set_Player_NextAttack(id, TIME_RELOAD)
	Set_Weapon_TimeIdle(id, CSW_PETROLBOOMER, TIME_RELOAD)
	set_pdata_int(g_wpnID[id], 51, 0, 4)
	set_task(TIME_RELOAD, "DoneReload", id)
	
}
public DoneReload(id)
{
	g_Reloading[id] = false;
	set_pdata_int(g_wpnID[id], 51, 1, 4)
}
public ReloadAnim(id)
{
	if(get_user_weapon(id) != CSW_PETROLBOOMER || !Get_BitVar(g_Had_PB, id))
		return
	Set_Weapon_Anim(id, ANIM_RELOAD)
}
public Make_Push(id)
{
	static Float:VirtualVec[3]
	VirtualVec[0] = random_float(-4.0, -7.0)
	VirtualVec[1] = random_float(1.0, -1.0)
	VirtualVec[2] = 0.0	
	
	set_pev(id, pev_punchangle, VirtualVec)		
}

public Create_Molotov(id)
{
	static Float:StartOrigin[3], Float:EndOrigin[3], Float:Angles[3]
	
	if(!is_user_bot(id))
		get_position(id, 48.0, 8.0, 5.0, StartOrigin)
	else get_position(id, 48.0, 0.0, 5.0, StartOrigin)
	
	get_position(id, 1024.0, 0.0, 0.0, EndOrigin)
	pev(id, pev_v_angle, Angles)
	
	Angles[0] *= -1
	
	static Molotov; Molotov = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Molotov)) return
	
	set_pev(Molotov, pev_movetype, is_user_bot(id)?MOVETYPE_FLY:MOVETYPE_TOSS)
	set_pev(Molotov, pev_iuser1, id) // Better than pev_owner
	set_pev(Molotov, pev_iuser3, 0)
	set_pev(Molotov, pev_iuser4, 0)
	
	entity_set_string(Molotov, EV_SZ_classname, MOLOTOV_CLASSNAME)
	engfunc(EngFunc_SetModel, Molotov, MODEL_S)
	set_pev(Molotov, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(Molotov, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(Molotov, pev_origin, StartOrigin)
	set_pev(Molotov, pev_angles, Angles)
	set_pev(Molotov, pev_gravity, 1.0)
	set_pev(Molotov, pev_solid, SOLID_BBOX)
	
	set_pev(Molotov, pev_nextthink, get_gametime() + 0.1)
	
	static Float:Velocity[3]
	get_speed_vector(StartOrigin, EndOrigin, MOLOTOV_SPEED, Velocity)
	set_pev(Molotov, pev_velocity, Velocity)
	
	// Make a Beam
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(Molotov) // entity
	write_short(spr_trail) // sprite
	write_byte(20)  // life
	write_byte(4)  // width
	write_byte(200) // r
	write_byte(200);  // g
	write_byte(200);  // b
	write_byte(200); // brightness
	message_end();
}

public fw_Touch_Molotov(Ent, Id)
{
	if(!pev_valid(Ent))
		return
	if(pev(Ent, pev_movetype) == MOVETYPE_NONE)
		return
		
	static Float:Origin[3], Attacker; Attacker = pev(Ent, pev_iuser1)
	pev(Ent, pev_origin, Origin)

	static a = FM_NULLENT
	while((a = find_ent_in_sphere(a, Origin, DAMAGE_RADIUS+50.0)) != 0)
	{
		if (Attacker == a)
			continue 
		if(!is_user_alive(a))
			continue	
		if(!zp_get_user_zombie(a))
			continue	
		if(pev(a, pev_takedamage) != DAMAGE_NO)
		{
			ExecuteHamB(Ham_TakeDamage, a, Attacker, Attacker, is_deadlyshot(Attacker)?random_float(DAMAGE_EXPLOSION-10.0,DAMAGE_EXPLOSION+10.0)*1.5:random_float(DAMAGE_EXPLOSION-10.0,DAMAGE_EXPLOSION+10.0), DMG_BULLET);
		}
	}
	
	// Remove Ent
	set_pev(Ent, pev_movetype, MOVETYPE_NONE)
	set_pev(Ent, pev_solid, SOLID_NOT)
	engfunc(EngFunc_SetModel, Ent, "")
	
	emit_sound(Ent, CHAN_WEAPON, WeaponSounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	Create_GroundFire(Ent)
	set_task(1.5, "Remove_Entity", Ent)
}

public Create_GroundFire(Ent)
{
	static Float:Origin[3]; pev(Ent, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_ExpSprId)	// sprite index
	write_byte(30)	// scale in 0.1's
	write_byte(30)	// framerate
	write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOPARTICLES)	// flags
	message_end()
	
	static Float:Ori[3],Float:FireOrigin[9][3]
	pev(Ent, pev_origin, Ori)
	get_spherical_coord(Ori, random_float(40.0, 60.0), 0.0, 0.0, FireOrigin[0])
	get_spherical_coord(Ori, random_float(40.0, 60.0), 90.0, 0.0, FireOrigin[1])
	get_spherical_coord(Ori, random_float(40.0, 60.0), 180.0, 0.0, FireOrigin[2])
	get_spherical_coord(Ori, random_float(40.0, 60.0), 270.0, 0.0, FireOrigin[3])
	
	get_spherical_coord(Ori, random_float(40.0, 60.0), 315.0, 0.0, FireOrigin[4])
	get_spherical_coord(Ori, random_float(40.0, 60.0), 45.0, 0.0, FireOrigin[5])
	get_spherical_coord(Ori, random_float(40.0, 60.0), 135.0, 0.0, FireOrigin[6])
	get_spherical_coord(Ori, random_float(40.0, 60.0), 225.0, 0.0, FireOrigin[7])
	get_spherical_coord(Ori, 0.0, 0.0, 0.0, FireOrigin[8])
	for(new i = 0; i < 9; i++)
	{	
		FireOrigin[i][2] += 20.0	
		Create_SmallFire(FireOrigin[i], Ent)
	}
}

public Remove_Entity(Ent)
{
	if(pev_valid(Ent)) remove_entity(Ent)
}
public fw_Fire2Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
	
	static Float:fFrame; pev(iEnt, pev_frame, fFrame)
	
	fFrame += 1.0
	if(fFrame >= 16.0) 
		fFrame = 0.0

	new Float:time_1; 
	pev(iEnt, pev_fuser2, time_1)
	
	static Float:Alpha
	pev(iEnt, pev_renderamt, Alpha)
	if(time_1 + random_float(0.2, 0.4) <= get_gametime()) 
	{
		if(Alpha>40){
			if(!get_pcvar_num(cvar_optimize))
				Create_Fake_Flame(iEnt)
		}else{
			set_pev(iEnt, pev_fuser2, get_gametime())
		}
	}else{
		time_1 += 0.03
		set_pev(iEnt, pev_fuser2, time_1)
	}
	set_pev(iEnt, pev_frame, fFrame)
	
	if(get_gametime() >= pev(iEnt, pev_fuser1))
	{
		Alpha-=15.0
		if(Alpha<=0)
		{	
			remove_entity(iEnt)
			return;
		}
		set_pev(iEnt, pev_renderamt, Alpha)
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)
		return;
	}	
	
	static Attacker; Attacker = pev(iEnt, pev_iuser1)
	static Float:Origin[3]
	pev(iEnt, pev_origin, Origin)
	
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)
	
	if(!zp_get_user_zombie(Attacker))
		Stock_DamageRadius(Attacker, Origin, DAMAGE_RADIUS, is_deadlyshot(Attacker)?DAMAGE_BURN*1.5:DAMAGE_BURN, DMG_BULLET)
	else remove_entity(iEnt)
}
public Create_SmallFire(Float:Origin[3], Master)
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Ent)) return

	// Set info for ent
	set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 180.0)
	set_pev(Ent, pev_scale, random_float(0.6,0.7))
	set_pev(Ent, pev_nextthink, get_gametime() + 0.05)
	
	set_pev(Ent, pev_classname, FIRE2_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, WeaponResources[0])
	set_pev(Ent, pev_fuser2, get_gametime())
	
	set_pev(Ent, pev_maxs, Float:{16.0, 16.0, 115.0})
	set_pev(Ent, pev_mins, Float:{-16.0, -16.0, -25.0})
	
	set_pev(Ent, pev_origin, Origin)
	
	set_pev(Ent, pev_gravity, 1.0)
	set_pev(Ent, pev_solid, SOLID_NOT)
	set_pev(Ent, pev_frame, 0.0)
	set_pev(Ent, pev_iuser1, pev(Master, pev_iuser1))
	set_pev(Ent, pev_fuser1, get_gametime() + 7.0)
}
public Create_Fake_Flame(ent)
{
	new Float:Origin[3];
	pev(ent, pev_origin, Origin)
	
	static Scale,Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Ent)) return
	
	pev(ent, pev_scale, Scale)
	
	// Set info for ent
	set_pev(Ent, pev_movetype, MOVETYPE_NOCLIP)
	set_pev(Ent, pev_solid, SOLID_NOT)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 100.0)
	
	set_pev(Ent, pev_scale, random_float(0.6,0.7))
	set_pev(Ent, pev_owner, ent)
	
	set_pev(Ent, pev_classname, FLAME_FAKE_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, WeaponResources[0])
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
	
	Origin[2] +=1.0
	set_pev(Ent, pev_maxs, Float:{16.0, 16.0, 1.0})
	set_pev(Ent, pev_mins, Float:{-16.0, -16.0, -1.0})
	set_pev(Ent, pev_origin, Origin)
	
	new Vel[3]
	Vel[0] += random_float(-35.0, 35.0)
	Vel[1] += random_float(-35.0, 35.0)
	Vel[2] += random_float(25.0, 30.0)
	set_pev(Ent, pev_velocity, Vel)
}
public FlameFakeThink(iEnt)
{
	if(!pev_valid(iEnt)) 
		return;
	
	if(pev(iEnt, pev_flags) & FL_KILLME) 
		return;
		
	new Owner = pev(iEnt, pev_owner);
	
	static Float:fFrame, Float:Alpha, Float:Scale; 
	pev(iEnt, pev_frame, fFrame)	
	pev(iEnt, pev_scale, Scale)	
	pev(iEnt, pev_renderamt, Alpha)
	
	fFrame += 1.0
	Scale -= 0.02
	
	if(fFrame >= 16.0 || Alpha<=0.0 || Scale <= 0.0) 
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
		
	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_scale, Scale)
	if(pev_valid(Owner))
	{		
		if(pev(Owner, pev_renderamt)<=25.0)
			Alpha -= 10.0
		else Alpha -= 0.5
		set_pev(iEnt, pev_renderamt, Alpha)
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)
	}
	else set_pev(iEnt, pev_nextthink, get_gametime() + 0.07)
}
public fw_Item_AddToPlayer_Post(Ent, Id)
{
	if(pev(Ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		Set_BitVar(g_Had_PB, Id)
		cs_set_user_bpammo(Id, CSW_PETROLBOOMER, MAGAZINE)
		set_pev(Ent, pev_impulse, 0)
	}			
}	

public fw_Item_Deploy_Post(Ent)
{
	if(!pev_valid(Ent))
		return
		
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(!Get_BitVar(g_Had_PB, Id))
		return
	g_wpnID[Id] = Ent	
	set_pev(Id, pev_viewmodel2, MODEL_V)
	set_pev(Id, pev_weaponmodel2, MODEL_P)
	
	//set_pdata_string(Id, (492) * 4, WEAPON_ANIMEXT, -1 , 20)
	
	Set_Weapon_TimeIdle(Id, CSW_PETROLBOOMER, TIME_DRAW + 0.5)
	Set_Player_NextAttack(Id, TIME_DRAW)
	Set_Weapon_Anim(Id, ANIM_DRAW)
}
public fw_Item_Reload(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;
		
	if(!Get_BitVar(g_Had_PB, id))
		return HAM_IGNORED
	
	return HAM_SUPERCEDE
}
new Float:Damage[33]
stock Stock_DamageRadius(iPlayer, Float:vOrigin[3], Float:fRadius, Float:fDamage, iDamageType = DMG_BULLET)
{
	new iVictim = FM_NULLENT
	while((iVictim = find_ent_in_sphere(iVictim, vOrigin, fRadius)) != 0) 
	{
		if(iVictim == iPlayer) continue
		if(pev(iVictim, pev_takedamage) == DAMAGE_NO) continue
		if(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY) continue
		if(!is_user_alive(iVictim))continue
		if(!zp_get_user_zombie(iVictim)) continue
		
		//ExecuteHamB(Ham_TakeDamage, iVictim, iEnt, iPlayer, fDamage, iDamageType)
		
		new Float:multi
		if(is_user_bot(iPlayer))
			multi=get_cvar_float("zp_human_damage_reward")*2
		else multi = get_cvar_float("zp_human_damage_reward")
		
		static health
		health = pev(iVictim, pev_health)
		
		if (health - floatround(fDamage, floatround_ceil) > 0)
		{	
			fm_set_user_health(iVictim, health - floatround(fDamage, floatround_ceil))
			Damage[iPlayer]+=fDamage
			
		}
		else ExecuteHam(Ham_TakeDamage, iVictim, iPlayer, iPlayer, 10.0, iDamageType)
		
		if(Damage[iPlayer]>= 20.0)
		{
			zp_set_user_ammo_packs(iPlayer, zp_get_user_ammo_packs(iPlayer) + floatround(Damage[iPlayer] * multi))
			Damage[iPlayer]=0.0
		}
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Money"), _, iPlayer);
		write_long(zp_get_user_ammo_packs(iPlayer));
		write_byte(1);
		message_end();
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

stock Set_Weapon_Anim(id, WeaponAnim)
{
	set_pev(id, pev_weaponanim, WeaponAnim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(WeaponAnim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock Set_Weapon_TimeIdle(id, WeaponId ,Float:TimeIdle)
{
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, 4)
}

stock Set_Player_NextAttack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
}


stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
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

get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	new Float:length
	length  = redius * floatcos(vertical_angle, degrees)
	origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees)
	origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees)
	origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees)
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

public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(get_user_weapon(iAttacker) == CSW_PETROLBOOMER)
	{
		if(Get_BitVar(g_Had_PB, iAttacker))
			set_msg_arg_string(4, "petrolboomer")
	}
                
	return PLUGIN_CONTINUE
}
