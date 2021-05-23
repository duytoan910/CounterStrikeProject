#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <xs>
#include <engine>

#define CustomItem(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)

#define PDATA_SAFE 2

#define WEAPON_ANIM_IDLE 0
#define WEAPON_ANIM_SHOOT random_num(1,2)
#define WEAPON_ANIM_INSERT 3
#define WEAPON_ANIM_DRAW 6
#define WEAPON_ANIM_AFTER 4
#define WEAPON_ANIM_BEFORE 5

// From model: Frames/FPS
#define WEAPON_ANIM_IDLE_TIME 2/16.0
#define WEAPON_ANIM_SHOOT_TIME 2.0/20.0
#define WEAPON_ANIM_DRAW_TIME 1.0

#define WEAPON_SPECIAL_CODE 79483166
#define WEAPON_REFERENCE "weapon_m3"
#define WEAPON_ITEM_NAME "M32 MGL Venom"
#define WEAPON_ITEM_COST 3000

#define WEAPON_MODEL_VIEW "models/v_m32venom.mdl"
#define WEAPON_MODEL_PLAYER "models/p_m32venom.mdl"
#define WEAPON_MODEL_WORLD "models/w_m32venom.mdl"

#define WEAPON_BODY 0

//Настройки
#define RADIUS_DMG 120.0	//Максимальный радиус для взрыва
#define DMG_EXP 400.0		//Максимальный дамаг (при таком значении в среднем будет 280)

#define M32_DAMAGE_POISON 7.0
#define M32_RANGE 120.0

#define DISTANCE 1200		//Расстояние выстрела без прицела
#define DISTANCE_ZOOM 1400	//Расстояние выстрела с прицелом
#define WEAPON_MAX_CLIP 6	//Ля, ребят не эксперементировал, лучше не трогать.(патроны)
#define WEAPON_DEFAULT_AMMO 18	//Ля, ребят эксперементировал, можете трогать.(боезапас)
#define SPEED 1.0		//Скорость выстрела без зума
#define SPEED_ZOOM 0.7		//Скорость выстрела с зумом

// Linux extra offsets
#define linux_diff_weapon 4
#define linux_diff_player 5

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox 34

// CBaseAnimating
#define m_flLastEventCheck 38

// CBasePlayerItem
#define m_pPlayer 41
#define m_pNext 42
#define m_iId 43

// CBasePlayerWeapon
#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47
#define m_flTimeWeaponIdle 48
#define m_iPrimaryAmmoType 49
#define m_iClip 51
#define m_fInReload 54
#define	m_fInSpecialReload 55			
#define m_iWeaponState 74

// CBaseMonster
#define m_flNextAttack 83

// CBasePlayer
#define m_iFOV 363		
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376
#define OFFSET_AMMO_M3 381
new const GRENADE_MODEL[] = "models/grenade.mdl"
new const GRENADE_TRAIL[] = "sprites/laserbeam.spr"
new const GRENADE_EXPLOSION[] = "sprites/ef_m32_poison.spr"

new const Sounds[][]=
{
	"weapons/m32-1.wav",
	"weapons/m32venom_exp.wav",
	"weapons/explode3.wav",
	"weapons/explode4.wav",
	"weapons/explode5.wav"
}

const pev_livetime = pev_fuser1

new g_iszAllocString_Entity,
	g_iszAllocString_ModelView, 
	g_iszAllocString_ModelPlayer, 
	g_iItemID,
	sTrail,
	sExplo,
	g_poision_id

public plugin_init()
{
	register_plugin("[ZP] Weapon: M32", "1.0", "PbI)I(Uu' / Batcon: Code base");

	g_iItemID = zp_register_extra_item(WEAPON_ITEM_NAME, WEAPON_ITEM_COST, ZP_TEAM_HUMAN);
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_SetModel, "FM_Hook_SetModel_Pre", false);
	RegisterHam(Ham_Killed, "player", "M32_Killed", 1)
	RegisterHam(Ham_Spawn, "player", "CPlayer__Spawn_Post", true);
	RegisterHam(Ham_Item_Holster, WEAPON_REFERENCE, "CWeapon__Holster_Post", true);
	RegisterHam(Ham_Item_Deploy, WEAPON_REFERENCE, "CWeapon__Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame, WEAPON_REFERENCE, "CWeapon__PostFrame_Pre", false);
	RegisterHam(Ham_Weapon_Reload, WEAPON_REFERENCE, "M32_ReloadP", true)
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERENCE,	"CWeapon__PrimaryAttack_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_REFERENCE, "M32_Attackp", true);
	RegisterHam(Ham_Item_AddToPlayer, WEAPON_REFERENCE, "CWeapon__AddToPlayer_Post", true);
	register_think("venom_poison", "PoisonThink")
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
}
public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);
	
	sTrail = precache_model(GRENADE_TRAIL)
	sExplo = precache_model(GRENADE_EXPLOSION)
	
	g_poision_id = engfunc(EngFunc_PrecacheModel, "sprites/ef_smoke_poison.spr")
	for(new i; i<=charsmax(Sounds); i++)
	{
		precache_sound(Sounds[i]);
	}
	
	// Other
	g_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	g_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	g_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);
}

// [ Amxx ]
#if AMXX_VERSION_NUM < 183
	public client_disconnect(iPlayer)
#else
	public client_disconnected(iPlayer)
#endif
{
	UTIL_SetRendering(iPlayer);
	set_pev(iPlayer, pev_iuser2, 0);
}

public weapon_list_m32(id) client_cmd(id,WEAPON_REFERENCE)
public zp_extra_item_selected(iPlayer, iItem)
{
	if(iItem == g_iItemID)
		Command_GiveWeapon(iPlayer);
}

public Command_GiveWeapon(iPlayer)
{
	static iEntity; iEntity = engfunc(EngFunc_CreateNamedEntity, g_iszAllocString_Entity);
	if(iEntity <= 0) return 0;

	set_pev(iEntity, pev_impulse, WEAPON_SPECIAL_CODE);
	ExecuteHam(Ham_Spawn, iEntity);
	UTIL_DropWeapon(iPlayer, 1);

	if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iEntity))
	{
		set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
		return 0;
	}
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	ExecuteHamB(Ham_Item_AttachToPlayer, iEntity, iPlayer);
	set_pdata_int(iEntity, m_iClip, WEAPON_MAX_CLIP, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iEntity, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, m_rgAmmo, linux_diff_player) < WEAPON_DEFAULT_AMMO)
		set_pdata_int(iPlayer, iAmmoType, WEAPON_DEFAULT_AMMO, linux_diff_player);
		
	emit_sound(iPlayer, CHAN_WEAPON, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	return 1;
}
// [ Fakemeta ]
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
	if(!is_user_alive(iPlayer)) return;

	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(pev_valid(iItem) != PDATA_SAFE || !CustomItem(iItem)) return;

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(iEntity)
{
	static i, szClassName[32], iItem;
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

	for(i = 0; i < 6; i++)
	{
		iItem = get_pdata_cbase(iEntity, m_rgpPlayerItems_CWeaponBox + i, linux_diff_weapon);

		if(iItem > 0 && CustomItem(iItem))
		{
			engfunc(EngFunc_SetModel, iEntity, WEAPON_MODEL_WORLD);
			set_pev(iEntity, pev_body, WEAPON_BODY);
			
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

// [ HamSandwich ]
public CPlayer__Spawn_Post(iPlayer)
{
	if(!is_user_connected(iPlayer)) return;

	UTIL_SetRendering(iPlayer);
	set_pev(iPlayer, pev_iuser2, 0);
}

public CWeapon__Holster_Post(iItem)
{
	if(!CustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
	
	set_pdata_int(iPlayer, m_iFOV, 90, linux_diff_player)
	set_pdata_int(iItem, m_fInSpecialReload, 0, linux_diff_weapon)
}

public CWeapon__Deploy_Post(iItem)
{
	if(!CustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	set_pev_string(iPlayer, pev_viewmodel2, g_iszAllocString_ModelView);
	set_pev_string(iPlayer, pev_weaponmodel2, g_iszAllocString_ModelPlayer);
	
	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static id; id = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon)
	static fInReload; fInReload = get_pdata_int(iItem, m_fInReload, linux_diff_weapon) 
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, m_flNextAttack, linux_diff_player)
	if(fInReload && flNextAttack <= 0.0)
	{
		set_pdata_int(iItem, m_fInSpecialReload, 0, linux_diff_weapon)
		fInReload = 0
	}
	static iButton;iButton = pev(id, pev_button)
		
	if(iButton & IN_ATTACK && get_pdata_float(iItem, m_flNextPrimaryAttack, linux_diff_weapon) <= 0.0)
	{
		return HAM_IGNORED
	}
	
	if(iButton & IN_RELOAD && !fInReload)
	{
		if(iClip >= WEAPON_MAX_CLIP)
		{
			set_pev(id, pev_button, iButton & ~IN_RELOAD)
		}
		else if(iClip == WEAPON_MAX_CLIP)
		{
			if(!get_pdata_int(id,OFFSET_AMMO_M3,linux_diff_player))
				return HAM_IGNORED		
		}
	}

	if(get_pdata_float(iItem, m_flNextSecondaryAttack, linux_diff_weapon) <= 0.0) 
	{
		if(iButton & IN_ATTACK2) 
		{
			emit_sound( id, CHAN_WEAPON, "weapons/zoom.wav", 0.20, 2.40, 0, 100 )
			set_pdata_int(id, m_iFOV, get_pdata_int(id, m_iFOV, linux_diff_player) == 90 ? 65 : 90);
			set_pdata_float(iItem, m_flNextSecondaryAttack, 0.3, linux_diff_weapon);
		}
	}
	return HAM_IGNORED;
}
public M32_ReloadP(ent)
{
	static id; id = get_pdata_cbase(ent, m_pPlayer, linux_diff_weapon);
	if(!CustomItem(ent)) return 
	if(!get_pdata_int(id,OFFSET_AMMO_M3,linux_diff_player)) return
	if(get_pdata_int(id, m_iFOV, linux_diff_player) != 90)
	{
		set_pdata_int(id, m_iFOV, 90, linux_diff_player);
	}
	set_pdata_float(id, m_flNextAttack, 0.7, linux_diff_player)
	set_pdata_float(ent, m_flTimeWeaponIdle, 0.7, linux_diff_weapon)
	set_pdata_float(id, m_flNextPrimaryAttack, 0.7, linux_diff_player)
	set_pdata_int(ent, m_fInSpecialReload, 1, linux_diff_weapon)
	UTIL_SendWeaponAnim(id, WEAPON_ANIM_BEFORE);
	static clip; clip = get_pdata_int(ent,m_iClip,linux_diff_player)
	static bpammo; bpammo = get_pdata_int(id,OFFSET_AMMO_M3,linux_diff_player)
	if(get_pdata_float(ent, m_flNextPrimaryAttack,linux_diff_weapon) > 0.0) return 
	if(get_pdata_int(ent, m_fInSpecialReload, linux_diff_weapon))
	{

		if(get_pdata_int(id,OFFSET_AMMO_M3,linux_diff_player) <= 0 || WEAPON_MAX_CLIP-1 == clip)
		set_pdata_float(id, m_flNextAttack, 0.7, linux_diff_player)
		set_pdata_float(ent, m_flTimeWeaponIdle, 0.7, linux_diff_weapon)
		set_pdata_float(ent, m_flNextPrimaryAttack, 0.7, linux_diff_weapon)
		UTIL_SendWeaponAnim(id, WEAPON_ANIM_INSERT);
		set_pdata_int(ent, m_fInSpecialReload, 1, linux_diff_weapon)
		if(get_pdata_float(ent, m_flNextPrimaryAttack, linux_diff_weapon) > 0.0)
		{
			if(clip<WEAPON_MAX_CLIP)
			{
				set_pdata_int(id, OFFSET_AMMO_M3, bpammo-1, linux_diff_player)
				set_pdata_int(ent, m_iClip, clip+1)
			}	
		}
			
		if(clip==WEAPON_MAX_CLIP)
		{
			set_pdata_float(id, m_flNextAttack, 0.7, linux_diff_player)
			set_pdata_float(ent, m_flTimeWeaponIdle, 0.7, linux_diff_weapon)
			set_pdata_float(id, m_flNextPrimaryAttack, 0.7, linux_diff_player)
			set_pdata_int(ent, m_fInSpecialReload, 0, linux_diff_weapon)
			UTIL_SendWeaponAnim(id, WEAPON_ANIM_AFTER);
			return 
		}	
		return 
	}
	return 
}
public CWeapon__PrimaryAttack_Pre( iItem ) 
{
	if(CustomItem(iItem)) return HAM_SUPERCEDE
	return HAM_IGNORED
}

public M32_Attackp( ent )
{
	static id; id = pev( ent, pev_owner )
	if(CustomItem(ent))
	{
		if(get_pdata_int(ent, m_fInSpecialReload, linux_diff_player))
		{
			set_pdata_float(id, m_flNextAttack, 0.9, linux_diff_player)
			set_pdata_float(ent, m_flTimeWeaponIdle, 0.9, linux_diff_weapon)
			set_pdata_float(ent, m_flNextPrimaryAttack, 0.9, linux_diff_weapon)
			UTIL_SendWeaponAnim(id, WEAPON_ANIM_AFTER); 
			set_pdata_int(ent, m_fInSpecialReload, 0, linux_diff_weapon)
			return HAM_SUPERCEDE
		}
		if(get_pdata_int(ent,m_iClip,linux_diff_player)!=0)
		{
			UTIL_SendWeaponAnim(id, WEAPON_ANIM_SHOOT); 
			emit_sound( id, CHAN_WEAPON, Sounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM )
			FireGrenade( id )
			//Отдача
			static Float:punchAngle[3]; 
			punchAngle[0] = -4.0;
			punchAngle[1] = float(random_num(-600, 600)) / 100.0;
			punchAngle[2] = 0.0;
			set_pev(id, pev_punchangle, punchAngle);
			//
			static item; item = get_pdata_cbase(id, m_pActiveItem)
			static clip; clip = get_pdata_int(item,m_iClip,linux_diff_player)
			set_pdata_int(item, m_iClip, clip-1)
			if(get_pdata_int(id, m_iFOV, linux_diff_player) != 90)
			{
				set_pdata_float(id, m_flNextAttack, SPEED_ZOOM, linux_diff_player)
				set_pdata_float(ent, m_flTimeWeaponIdle, SPEED_ZOOM, linux_diff_weapon)
				set_pdata_float(ent, m_flNextPrimaryAttack, SPEED_ZOOM, linux_diff_weapon)
			}
			else
			{
				set_pdata_float(id, m_flNextAttack, SPEED, linux_diff_player)
				set_pdata_float(ent, m_flTimeWeaponIdle, SPEED, linux_diff_weapon)
				set_pdata_float(ent, m_flNextPrimaryAttack, SPEED, linux_diff_weapon)
			}	
		}
		else
		{
			set_pdata_float(ent, m_flNextPrimaryAttack, 0.5, linux_diff_weapon)
			ExecuteHam(Ham_Weapon_PlayEmptySound, ent)	
			return HAM_SUPERCEDE
		}
	}
	return HAM_IGNORED
}

public FireGrenade(id)
{

	static Float:origin[3],Float:velocity[3],Float:angles[3]
	pev(id,pev_angles,angles)
	static ent; ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if(!is_user_bot(id))
		get_weapon_position(id, origin, 10.0, get_cvar_num("cl_righthand")?8.0: -8.0, -5.0)
	else get_weapon_position(id, origin, 10.0, 0.0, -5.0)
	
	set_pev( ent, pev_classname, "m32venom" )
	set_pev( ent, pev_solid, SOLID_BBOX )
	set_pev( ent, pev_movetype, is_user_bot(id)?MOVETYPE_FLY:MOVETYPE_TOSS )
	engfunc ( EngFunc_SetSize  , ent, Float:{ -0.1, -0.1, -0.1 }, Float:{ 0.1, 0.1, 0.1 } );
	engfunc ( EngFunc_SetModel , ent, GRENADE_MODEL );
	engfunc ( EngFunc_SetOrigin, ent, origin );
	set_pev( ent, pev_angles, angles )
	set_pev( ent, pev_owner, id )
	set_pev( ent, pev_nextthink, get_gametime( ))
	set_pev(ent, pev_speed, velocity) 
	if(get_pdata_int(id, m_iFOV, linux_diff_player) == 90)
	{
		velocity_by_aim( id,DISTANCE,velocity )
	}
	else
	{
		velocity_by_aim( id,DISTANCE_ZOOM, velocity )	
	}
	set_pev( ent, pev_velocity, velocity )
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // Temporary entity ID
	write_short(ent) // Entity
	write_short(sTrail) // Sprite index
	write_byte(3) // Life
	write_byte(3) // Line width
	write_byte(255) // Red
	write_byte(255) // Green
	write_byte(255) // Blue
	write_byte(100) // Alpha
	message_end() 
	return 
}	
public CWeapon__AddToPlayer_Post(iItem, iPlayer)
{

}
public pfn_touch(ptr, ptd)
{
	// If ent is valid
	if (pev_valid(ptr))
	{	
		// Get classnames
		static classname[32]
		pev(ptr, pev_classname, classname, 31)
		// Our ent
		if(equal(classname, "m32venom"))
		{
			new TE_FLAG
			TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
			TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
			TE_FLAG |= TE_EXPLFLAG_NOSOUND
			// Get it's origin
			new Float:originF[3]
			static Float:flSpeed,Float:flVictimOrigin [ 3 ], Float:flVelocity [ 3 ]
			pev(ptr, pev_origin, originF)
			// Draw explosion
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION) // Temporary entity ID
			engfunc(EngFunc_WriteCoord, originF[0]) // engfunc because float
			engfunc(EngFunc_WriteCoord, originF[1])
			engfunc(EngFunc_WriteCoord, originF[2]+10.0)
			write_short(sExplo) // Sprite index
			write_byte(20) // Scale
			write_byte(30) // Framerate
			write_byte(TE_FLAG) // Flags
			message_end()
			Create_Poison(ptr)
			emit_sound(ptr, CHAN_WEAPON, Sounds[random_num(1,3)], 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			static pOwner; pOwner = pev(ptr,pev_owner);
			static pevVictim        
			pevVictim  = FM_NULLENT;
			
			while((pevVictim = engfunc(EngFunc_FindEntityInSphere, pevVictim, originF, RADIUS_DMG)) != 0)
			{
				if(!is_user_alive(pevVictim)) continue
				if(zp_get_user_zombie(pevVictim))
					flSpeed = 150.0
				else flSpeed = 800.0		
					
				pev(pevVictim, pev_origin, flVictimOrigin)
				static Float:flNewSpeed
				new Float:flDistance = get_distance_f ( originF, flVictimOrigin )   
				flNewSpeed = flSpeed * ( 1.0 - ( flDistance / RADIUS_DMG ) )
				if(zp_get_user_zombie(pevVictim))
				{
					ExecuteHamB(Ham_TakeDamage, pevVictim, pOwner, pOwner, is_deadlyshot(pOwner)?random_float(DMG_EXP-10.0,DMG_EXP+10.0)*1.5:random_float(DMG_EXP-10.0,DMG_EXP+10.0), DMG_BULLET);
					flVictimOrigin[2]+=50.0
					get_speed_vector ( originF, flVictimOrigin, flNewSpeed, flVelocity )
					set_pev ( pevVictim, pev_velocity,flVelocity )
				}else if(pevVictim==pOwner)
				{
					get_speed_vector ( originF, flVictimOrigin, flNewSpeed, flVelocity )
					set_pev ( pevVictim, pev_velocity,flVelocity )	
				}				
			}
			engfunc( EngFunc_RemoveEntity, ptr );
		}
	}
}

public Create_Poison(iEnt)
{
	if(!pev_valid(iEnt))return
	static Float:Origin[3]; pev(iEnt, pev_origin, Origin)
	
	Origin[2]+=40.0
	Create_Poison_Onground(Origin, iEnt)
}

public Create_Poison_Onground(Float:Origin[3], iEnt)
{
	static id; id = pev(iEnt, pev_owner)
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Ent)) return
	
	// Set info for ent
	set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 100.0)
	set_pev(Ent, pev_scale, 2.1)
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
	set_pev(Ent, pev_owner, id)
	
	set_pev(Ent, pev_classname, "venom_poison")
	engfunc(EngFunc_SetModel, Ent, "sprites/ef_smoke_poison.spr")
	
	set_pev(Ent, pev_mins, Float:{-12.0, -12.0, -12.0})
	set_pev(Ent, pev_maxs, Float:{12.0, 12.0, 12.0})
	
	//Origin[2]+=80.0
	set_pev(Ent, pev_origin, Origin)
	set_pev(Ent, pev_iuser2, pev(iEnt, pev_iuser2))
	
	Create_Poison_Group(Origin)
	
	set_pev(Ent, pev_gravity, 1.0)
	set_pev(Ent, pev_solid, SOLID_TRIGGER)
	set_pev(Ent, pev_frame, 1.5)
	//client_print(1, print_chat, "Poision Making!")
	
	emit_sound(Ent, CHAN_WEAPON, Sounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
}
Create_Poison_Group(Float:position[3])
{
	new Float:origin[12][3]
	get_spherical_coord(position, 40.0, 0.0, 0.0, origin[0])
	get_spherical_coord(position, 40.0, 90.0, 0.0, origin[1])
	get_spherical_coord(position, 40.0, 180.0, 0.0, origin[2])
	get_spherical_coord(position, 40.0, 270.0, 0.0, origin[3])
	for (new i = 0; i < 4; i++)
	{
		// Draw explosion
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION) // Temporary entity ID
		engfunc(EngFunc_WriteCoord, origin[i][0]) // engfunc because float
		engfunc(EngFunc_WriteCoord, origin[i][1])
		engfunc(EngFunc_WriteCoord, origin[i][2]-=50.0)
		write_short(g_poision_id) // Sprite index
		write_byte(10) // Scale
		write_byte(15) // Framerate
		write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOPARTICLES|TE_EXPLFLAG_NOSOUND) // Flags
		message_end()		
	}
}
public PoisonThink(iEnt)
{
	static Float:fFrame; pev(iEnt, pev_frame, fFrame)
	new pevAttacker = pev(iEnt, pev_owner);
	if(!is_user_connected(pevAttacker) || !is_user_alive(pevAttacker))
	{
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
		return
	}
	if(!pev_valid(iEnt)) return;
	if(pev(iEnt, pev_flags) & FL_KILLME) return;
	
	fFrame += 0.5
	if(fFrame >= 38.0) 
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
		
	//client_print(1, print_chat, "Poision Thinking!")
	
	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_nextthink, halflife_time() + 0.1)
	
	if(get_gametime() >= pev(iEnt, pev_livetime))
	{
		static Float:Origin[3]
		pev(iEnt, pev_origin, Origin)
		Stock_DamageRadius(pevAttacker, Origin, M32_RANGE, is_deadlyshot(pevAttacker)?M32_DAMAGE_POISON*1.5:M32_DAMAGE_POISON, DMG_BULLET)
		set_pev(iEnt, pev_livetime, get_gametime())
		set_pev(iEnt, pev_owner, pevAttacker)
	}
}
public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)	
		
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	
	if(get_user_weapon(iAttacker) == CSW_M3)
	{
		if(CustomItem(iItem))
			set_msg_arg_string(4, "m32venom")
	}
	
	return PLUGIN_CONTINUE
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
public M32_Killed(iVictim, iAttacker, shouldgib)
{
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(CustomItem(iAttacker))
	{
		if(user_has_weapon(iAttacker,21,-1))
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_CONTINUE;
}
public Event_NewRound() remove_entity_name("m32venom")
// [ Stocks ]
stock UTIL_SendWeaponAnim(iPlayer, iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}
stock UTIL_DropWeapon(iPlayer, iSlot)
{
	static iEntity, iNext, szWeaponName[32];
	iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);

	if(iEntity > 0)
	{       
		do 
		{
			iNext = get_pdata_cbase(iEntity, m_pNext, linux_diff_weapon);

			if(get_weaponname(get_pdata_int(iEntity, m_iId, linux_diff_weapon), szWeaponName, charsmax(szWeaponName)))
				engclient_cmd(iPlayer, "drop", szWeaponName);
		} 
		
		while((iEntity = iNext) > 0);
	}
}

stock UTIL_PrecacheSoundsFromModel(const szModelPath[])
{
	static iFile;
	
	if((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for(new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);
			
			for(k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if(iEvent != 5004)
					continue;
				
				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if(strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					engfunc(EngFunc_PrecacheSound, szSoundPath);
				}
			}
		}
	}
	
	fclose(iFile);
}
stock get_weapon_position(id, Float:fOrigin[], Float:add_forward = 0.0, Float:add_right = 0.0, Float:add_up = 0.0)
{
	static Float:Angles[3],Float:ViewOfs[3], Float:vAngles[3]
	static Float:Forward[3], Float:Right[3], Float:Up[3]
	
	pev(id, pev_v_angle, vAngles)
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, ViewOfs)
	xs_vec_add(fOrigin, ViewOfs, fOrigin)
	
	pev(id, pev_angles, Angles)
	
	Angles[0] = vAngles[0]
	
	engfunc(EngFunc_MakeVectors, Angles)
	
	global_get(glb_v_forward, Forward)
	global_get(glb_v_right, Right)
	global_get(glb_v_up, Up)
	
	xs_vec_mul_scalar(Forward, add_forward, Forward)
	xs_vec_mul_scalar(Right, add_right, Right)
	xs_vec_mul_scalar(Up, add_up, Up)
	
	fOrigin[0] = fOrigin[0] + Forward[0] + Right[0] + Up[0]
	fOrigin[1] = fOrigin[1] + Forward[1] + Right[1] + Up[1]
	fOrigin[2] = fOrigin[2] + Forward[2] + Right[2] + Up[2]
}
stock UTIL_SetRendering(iPlayer, iFx = 0, iRed = 255, iGreen = 255, iBlue = 255, iRender = 0, Float: flAmount = 16.0)
{
	static Float: flColor[3];
	
	flColor[0] = float(iRed);
	flColor[1] = float(iGreen);
	flColor[2] = float(iBlue);
	
	set_pev(iPlayer, pev_renderfx, iFx);
	set_pev(iPlayer, pev_rendercolor, flColor);
	set_pev(iPlayer, pev_rendermode, iRender);
	set_pev(iPlayer, pev_renderamt, flAmount);
}

get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	new Float:length
	length  = redius * floatcos(vertical_angle, degrees)
	origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees)
	origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees)
	origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees)
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
