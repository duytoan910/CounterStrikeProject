#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <zombieplague>
#include <toan>

#define PLUGIN 					"[ZP] Extra: CSO Weapon M3 Big Dragon"
#define VERSION 				"1.0"
#define AUTHOR 					"TemplateAuthor:KORD_12.7:WeaponAuthor:PaXaN-ZOMBIE"

#pragma ctrlchar 				'\'
#pragma compress 				1

// Main
#define WEAPON_KEY				279214
#define WEAPON_NAME 				"weapon_m3dragon"

#define WEAPON_REFERANCE			"weapon_xm1014"
#define WEAPON_MAX_CLIP				10
#define WEAPON_DEFAULT_AMMO			200
#define WEAPON_HIT_TO_ACTIVE			8 //32 hit on player for active B mode (Dragon)

#define WEAPON_TIME_NEXT_IDLE 			15.0
#define WEAPON_TIME_NEXT_ATTACK 		1.0
#define WEAPON_TIME_DELAY_DEPLOY 		1.0

#define WEAPON_MULTIPLIER_DAMAGE  	  	2.0

//MissileAttack
#define WEAPON_RADIUS_EXP			150.0
#define WEAPON_DAMAGE_EXP			500.0

//DragonAttack
#define WEAPON_RADIUS_EXP2			100.0
#define WEAPON_DAMAGE_EXP2			140.0

#define ZP_ITEM_NAME				"M3 Black Dragon" 
#define ZP_ITEM_COST				8000

// Models
#define MODEL_WORLD				"models/w_m3dragon.mdl"
#define MODEL_VIEW				"models/v_m3dragon.mdl"
#define MODEL_PLAYER				"models/p_m3dragon.mdl"

#define SHARKMODEL				"models/m3dragon_effect.mdl"
#define MISSILEMODEL				"models/ef_fireball2.mdl"

#define WATERMODEL				"models/ef_m3dragonm_sign.mdl"

// Sounds
#define SOUND_FIRE				"weapons/m3dragon-1_1.wav"
#define SOUND_FIRE2				"weapons/m3dragon-2.wav"
#define SOUND_FIRE3				"weapons/m3dragon-2.wav"
#define SOUND_EXPLODE				"weapons/explode3.wav"
#define SOUND_DRAGONFX				"weapons/m3dragon_dragon_fx.wav"
#define SOUND_FLAME_LOOP			"weapons/m3dragon_fire_loop.wav"

// Sprites
#define WEAPON_SPR_FLAME			"sprites/m3dragon_flame.spr"
#define WEAPON_SPR_FLAME2			"sprites/m3dragon_flame2.spr"

// Animation
#define ANIM_EXTENSION				"shotgun"

// Animation sequences
enum
{	
	ANIM_IDLE,
	ANIM_SHOOT,
	ANIM_SHOOT2,
	ANIM_INSERT,
	ANIM_AFTER_RELOAD,
	ANIM_BEFOR_RELOAD,
	ANIM_DRAW,

	ANIM_IDLE_B,
	ANIM_SHOOT_B,
	ANIM_INSERT_B,
	ANIM_AFTER_RELOAD_B,
	ANIM_BEFOR_RELOAD_B,
	ANIM_DRAW_B
};

#define Sprite_SetScale(%0,%1) 			set_pev(%0, pev_scale, %1)
#define Sprite_SetFramerate(%0,%1) 		set_pev(%0, pev_framerate, %1)

#define POINTCONTENTS(%0) 			engfunc(EngFunc_PointContents, %0)

#define GET_STATE(%0)				get_pdata_int(%0, m_fWeaponState, extra_offset_weapon)
#define SET_STATE(%0,%1)			set_pdata_int(%0, m_fWeaponState, %1, extra_offset_weapon)

#define GET_SHOOTS(%0)				get_pdata_int(%0, m_fInCheckShoots, extra_offset_weapon)
#define SET_SHOOTS(%0,%1)			set_pdata_int(%0, m_fInCheckShoots, %1, extra_offset_weapon)

#define MDLL_Spawn(%0)				dllfunc(DLLFunc_Spawn, %0)
#define MDLL_Touch(%0,%1)			dllfunc(DLLFunc_Touch, %0, %1)
#define MDLL_USE(%0,%1)				dllfunc(DLLFunc_Use, %0, %1)

#define SET_MODEL(%0,%1)			engfunc(EngFunc_SetModel, %0, %1)
#define SET_ORIGIN(%0,%1)			engfunc(EngFunc_SetOrigin, %0, %1)
#define SET_SIZE(%0,%1,%2)			engfunc(EngFunc_SetSize, %0, %1, %2)

#define PRECACHE_MODEL(%0)			engfunc(EngFunc_PrecacheModel, %0)
#define PRECACHE_SOUND(%0)			engfunc(EngFunc_PrecacheSound, %0)
#define PRECACHE_GENERIC(%0)			engfunc(EngFunc_PrecacheGeneric, %0)

#define MESSAGE_BEGIN(%0,%1,%2,%3)		engfunc(EngFunc_MessageBegin, %0, %1, %2, %3)
#define MESSAGE_END()				message_end()

#define WRITE_ANGLE(%0)				engfunc(EngFunc_WriteAngle, %0)
#define WRITE_BYTE(%0)				write_byte(%0)
#define WRITE_COORD(%0)				engfunc(EngFunc_WriteCoord, %0)
#define WRITE_STRING(%0)			write_string(%0)
#define WRITE_SHORT(%0)				write_short(%0)

#define BitSet(%0,%1) 				(%0 |= (1 << (%1 - 1)))
#define BitClear(%0,%1) 			(%0 &= ~(1 << (%1 - 1)))
#define BitCheck(%0,%1) 			(%0 & (1 << (%1 - 1)))

// Linux extra offsets
#define extra_offset_weapon			4
#define extra_offset_player			5

new g_bitIsConnected;

#define m_rgpPlayerItems_CWeaponBox		34
#define m_fInCheckShoots			39

// CBasePlayerItem
#define m_pPlayer				41
#define m_pNext					42
#define m_iId                        		43

// CBasePlayerWeapon
#define m_flNextPrimaryAttack			46
#define m_flNextSecondaryAttack			47
#define m_flTimeWeaponIdle			48
#define m_iPrimaryAmmoType			49
#define m_iClip					51
#define m_fInSpecialReload  			55
#define m_fWeaponState				74
#define m_flNextAttack				83
#define m_iLastZoom 				109

// CBasePlayer
#define m_flVelocityModifier 			108 
#define m_fResumeZoom       			110
#define m_iFOV					363
#define m_rgpPlayerItems_CBasePlayer		367
#define m_pActiveItem				373
#define m_rgAmmo_CBasePlayer			376
#define m_szAnimExtention			492

#define IsValidPev(%0) 				(pev_valid(%0) == 2)

//EnitityClassName
#define MUZZLE_CLASSNAME_LEFT			"SmokeDragonleft"
#define MUZZLE_CLASSNAME_RIGHT			"SmokeDragonright"
#define DRAGON_CLASSNAME			"DragonClass"
#define MISSILE_CLASSNAME			"DragonMissileClass"
#define MUZZLE_CLASSNAME2			"MuzzleBigDragon"
#define WATER_CLASSNAME				"WateClassDragon"

new iBlood[2];
new g_Fire_SprId;

Weapon_OnPrecache()
{
	//PRECACHE_SOUND_FROM_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_PLAYER);
	PRECACHE_MODEL(WATERMODEL);
	
	PRECACHE_MODEL(SHARKMODEL);
	PRECACHE_MODEL(MISSILEMODEL);
	
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_FIRE2);
	PRECACHE_SOUND(SOUND_FIRE3);
	PRECACHE_SOUND(SOUND_EXPLODE);
	PRECACHE_SOUND(SOUND_DRAGONFX);
	PRECACHE_SOUND(SOUND_FLAME_LOOP);
	
	PRECACHE_MODEL(WEAPON_SPR_FLAME);
	PRECACHE_MODEL(WEAPON_SPR_FLAME2);

	iBlood[0] = PRECACHE_MODEL("sprites/bloodspray.spr");
	iBlood[1] = PRECACHE_MODEL("sprites/blood.spr");
	g_Fire_SprId = engfunc(EngFunc_PrecacheModel, "sprites/zerogxplode.spr")
}

Weapon_OnSpawn(const iItem)
{
	// Setting world model.
	SET_MODEL(iItem, MODEL_WORLD);
}

Weapon_OnDeploy(const iItem, const iPlayer, const iClip, const iAmmoPrimary, const iReloadMode, const iState)
{
	#pragma unused iClip, iAmmoPrimary, iReloadMode
	static iszViewModel;
	if (iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, MODEL_VIEW)))
	{
		set_pev_string(iPlayer, pev_viewmodel2, iszViewModel);
	}
	static iszPlayerModel;
	if (iszPlayerModel || (iszPlayerModel = engfunc(EngFunc_AllocString, MODEL_PLAYER)))
	{
		set_pev_string(iPlayer, pev_weaponmodel2, iszPlayerModel);
	}

	set_pdata_int(iItem, m_fInSpecialReload, false, extra_offset_weapon);

	set_pdata_string(iPlayer, m_szAnimExtention * 4, ANIM_EXTENSION, -1, extra_offset_player * 4);
	
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_DELAY_DEPLOY, extra_offset_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_TIME_DELAY_DEPLOY, extra_offset_player);

	Weapon_DefaultDeploy(iPlayer, MODEL_VIEW, MODEL_PLAYER, iState ? ANIM_DRAW_B:ANIM_DRAW, ANIM_EXTENSION);
	
	switch (iState)
	{
		case 1:
		{
			MuzzleFlash(iPlayer, WEAPON_SPR_FLAME2, MUZZLE_CLASSNAME_LEFT, 0.08, 1.0, 4, 29.0, 255.0);
			MuzzleFlash(iPlayer, WEAPON_SPR_FLAME, MUZZLE_CLASSNAME_RIGHT, 0.08, 1.0, 3, 29.0, 255.0);
			nav_set_special_ammo(iPlayer, 1)
		}
	}
}

Weapon_OnHolster(const iItem, const iPlayer, const iClip, const iAmmoPrimary, const iReloadMode, const iState)
{
	#pragma unused iPlayer, iClip, iAmmoPrimary, iReloadMode, iState
	
	set_pdata_int(iItem, m_fInSpecialReload, false, extra_offset_weapon);
	
	set_pev(iItem, pev_fuser1, 0.0);
}

Weapon_OnReload(const iItem, const iPlayer, const iClip, const iAmmoPrimary, const iReloadMode, const iState)
{
	#pragma unused iState
	
	if(iAmmoPrimary <= 0)
	{
		return HAM_IGNORED;
	}
	
	if (iClip >=WEAPON_MAX_CLIP)
	{
		return HAM_IGNORED;
	}

	switch(iReloadMode)
	{
		case 0:
		{
			Weapon_SendAnim(iPlayer, ANIM_BEFOR_RELOAD);
			
			set_pdata_float(iItem, m_flNextPrimaryAttack, 0.5, extra_offset_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, 0.5, extra_offset_weapon);
			
			set_pdata_int(iItem, m_fInSpecialReload, 1, extra_offset_weapon);
			
			return HAM_IGNORED;
		}
		case 1:
		{		
			if (get_pdata_int(iItem, m_flTimeWeaponIdle, extra_offset_weapon) > 0.0)
			{
				return HAM_IGNORED;
			}
				
			Weapon_SendAnim(iPlayer, ANIM_INSERT);
					
			set_pdata_int(iItem, m_fInSpecialReload, 2, extra_offset_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, 0.3, extra_offset_weapon);
				
			static szAnimation[64];

			formatex(szAnimation, charsmax(szAnimation), "ref_reload_shotgun");
			Player_SetAnimation(iPlayer, szAnimation);
				
		}
		case 2:
		{
			set_pdata_int(iItem, m_iClip, iClip + 1, extra_offset_weapon);
			set_pdata_int(iPlayer, 381, iAmmoPrimary-1, extra_offset_player);
			set_pdata_int(iItem, m_fInSpecialReload, 1, extra_offset_weapon);
		}
	}
	
	switch(iReloadMode)
	{
		case 0:
		{
			Weapon_SendAnim(iPlayer, ANIM_BEFOR_RELOAD);
			
			set_pdata_float(iItem, m_flNextPrimaryAttack, 0.5, extra_offset_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, 0.5, extra_offset_weapon);
			
			set_pdata_int(iItem, m_fInSpecialReload, 1, extra_offset_weapon);
			
			return HAM_IGNORED;
		}
	}
	return HAM_IGNORED;
}


Weapon_OnIdle(const iItem, const iPlayer, const iClip, const iAmmoPrimary, const iReloadMode, const iState)
{
	#pragma unused iClip, iAmmoPrimary
	
	ExecuteHamB(Ham_Weapon_ResetEmptySound, iItem);
	
	static Float:iFuser;pev(iItem, pev_fuser1, iFuser);
		
	if (GET_STATE(iItem) && iFuser <= get_gametime())
	{
		engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, SOUND_FLAME_LOOP, 1.0, ATTN_NORM, 0, PITCH_HIGH);
			
		set_pev(iItem, pev_fuser1, get_gametime() + 0.6);
	}

	if(iClip == WEAPON_MAX_CLIP)
	{
		if(iReloadMode == 2)
		{
			Weapon_ReloadEnd(iItem, iPlayer, iState);
			return;
		}
	}
	
	if(iAmmoPrimary <= 0)
	{
		if(iReloadMode == 2)
		{
			Weapon_ReloadEnd(iItem, iPlayer, iState);
			return;
		}
	}

	switch(iReloadMode)
	{
		case 1:
		{		
			if (get_pdata_int(iItem, m_flTimeWeaponIdle, extra_offset_weapon) > 0.0)
			{
				return;
			}
			
			Weapon_SendAnim(iPlayer, ANIM_INSERT);
				
			set_pdata_int(iItem, m_fInSpecialReload, 2, extra_offset_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, 0.5, extra_offset_weapon);
			
			static szAnimation[64];

			formatex(szAnimation, charsmax(szAnimation), "ref_reload_shotgun");
			Player_SetAnimation(iPlayer, szAnimation);
			
		}
		case 2:
		{
			set_pdata_int(iItem, m_iClip, iClip + 1, extra_offset_weapon);
			set_pdata_int(iPlayer, 381, iAmmoPrimary-1, extra_offset_player);
			set_pdata_int(iItem, m_fInSpecialReload, 1, extra_offset_weapon);
		}
	}
	
	if(!iReloadMode)
	{
		if (get_pdata_int(iItem, m_flTimeWeaponIdle, extra_offset_weapon) > 0.0)
		{
			return;
		}
	
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_IDLE, extra_offset_weapon);
		Weapon_SendAnim(iPlayer, iState ? ANIM_IDLE_B:ANIM_IDLE);
	}
}	

Weapon_OnPrimaryAttack(const iItem, const iPlayer, const iClip, const iAmmoPrimary, const iReloadMode, const iState)
{
	#pragma unused iAmmoPrimary
	
	static iFlags, iAnimDesired; 
	static szAnimation[64];iFlags = pev(iPlayer, pev_flags);

	if(iReloadMode > 0 && iClip > 0)
	{
		Weapon_ReloadEnd(iItem, iPlayer, iState);
		return;
	}
	
	CallOrigFireBullets3(iItem, iPlayer)

	if (iClip <= 0 || pev(iPlayer, pev_waterlevel) == 3)
	{
		return;
	}

	Punchangle(iPlayer, .iVecx = -2.5, .iVecy = 0.0, .iVecz = 0.0);

	Weapon_SendAnim(iPlayer, iState  ? ANIM_SHOOT_B:ANIM_SHOOT);
	
	switch (iState)
	{
		case 0:engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
		case 1:engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE3, 0.9, ATTN_NORM, 0, PITCH_NORM);
	}
	
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_TIME_NEXT_ATTACK, extra_offset_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_ATTACK+1.0, extra_offset_weapon);
		
	formatex(szAnimation, charsmax(szAnimation), iFlags & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", ANIM_EXTENSION);
								
	if ((iAnimDesired = lookup_sequence(iPlayer, szAnimation)) == -1)
	{
		iAnimDesired = 0;
	}
					
	set_pev(iPlayer, pev_sequence, iAnimDesired);
	
	SET_SHOOTS(iItem, GET_SHOOTS(iItem)+1);
	if (!GET_STATE(iItem) && GET_SHOOTS(iItem) >= WEAPON_HIT_TO_ACTIVE)
	{
		if(is_user_bot(iPlayer))
		{
			static iFlags, iAnimDesired; 
			static szAnimation[64];iFlags = pev(iPlayer, pev_flags);
			
			formatex(szAnimation, charsmax(szAnimation), iFlags & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", ANIM_EXTENSION);
										
			if ((iAnimDesired = lookup_sequence(iPlayer, szAnimation)) == -1)
			{
				iAnimDesired = 0;
			}
							
			set_pev(iPlayer, pev_sequence, iAnimDesired);
			
			Weapon_SendAnim(iPlayer, ANIM_SHOOT_B);
			
			set_pdata_float(iItem, m_flTimeWeaponIdle, 1.5, extra_offset_weapon);
			set_pdata_float(iItem, m_flNextPrimaryAttack, 0.5, extra_offset_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, 0.5, extra_offset_weapon);
			
			Punchangle(iPlayer, .iVecx = -3.5, .iVecy = 0.0, .iVecz = 0.0);
			new Float:vecEnd[3];GetWeaponPosition(iPlayer, 4096.0, 0.0, 0.0, vecEnd);
			new Float:vecSrc[3];GetWeaponPosition(iPlayer, 50.0, 0.0, 0.0, vecSrc);
			
			Spawn2(iPlayer, vecSrc, vecEnd);
			
			SET_SHOOTS(iItem, 0);
			
			nav_set_special_ammo(iPlayer, 0)
			engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE2, 0.9, ATTN_NORM, 0, PITCH_NORM);		
		}else{
			MuzzleFlash(iPlayer, WEAPON_SPR_FLAME2, MUZZLE_CLASSNAME_LEFT, 0.08, 1.0, 4, 29.0, 255.0);
			MuzzleFlash(iPlayer, WEAPON_SPR_FLAME, MUZZLE_CLASSNAME_RIGHT, 0.08, 1.0, 3, 29.0, 255.0);
			
			Weapon_SendAnim(iPlayer, ANIM_SHOOT2);
			
			SET_STATE(iItem, 1);
			SET_SHOOTS(iItem, 0);
			nav_set_special_ammo(iPlayer, 1)
		}
	}
}

Weapon_OnSecondaryAttack(const iItem, const iPlayer, const iClip, const iAmmoPrimary, const iReloadMode, const iState)
{
	#pragma unused iAmmoPrimary, iClip, iReloadMode, iState

	if (!GET_STATE(iItem))
	{
		return;
	}
	
	static iFlags, iAnimDesired; 
	static szAnimation[64];iFlags = pev(iPlayer, pev_flags);
	
	formatex(szAnimation, charsmax(szAnimation), iFlags & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", ANIM_EXTENSION);
								
	if ((iAnimDesired = lookup_sequence(iPlayer, szAnimation)) == -1)
	{
		iAnimDesired = 0;
	}
					
	set_pev(iPlayer, pev_sequence, iAnimDesired);
	
	Weapon_SendAnim(iPlayer, ANIM_SHOOT_B);
	
	set_pdata_float(iItem, m_flTimeWeaponIdle, 1.5, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.5, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.5, extra_offset_weapon);
	
	Punchangle(iPlayer, .iVecx = -3.5, .iVecy = 0.0, .iVecz = 0.0);

	SET_STATE(iItem, 0);
	
	new Float:vecEnd[3];GetWeaponPosition(iPlayer, 4096.0, 0.0, 0.0, vecEnd);
	new Float:vecSrc[3];GetWeaponPosition(iPlayer, 50.0, 0.0, 0.0, vecSrc);
	
	Spawn2(iPlayer, vecSrc, vecEnd);

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE2, 0.9, ATTN_NORM, 0, PITCH_NORM);
}

Weapon_ReloadEnd(const iItem, const iPlayer, const iState)
{
	Weapon_SendAnim(iPlayer, iState ? ANIM_AFTER_RELOAD_B:ANIM_AFTER_RELOAD);
	
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.6, extra_offset_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 1.4, extra_offset_weapon);
	
	set_pdata_int(iItem, m_fInSpecialReload, 0, extra_offset_weapon);
}

#define MSGID_WEAPONLIST 78

new g_iItemID;

new g_iszMuzzleKey;

#define IsCustomMuzzle(%0) (pev(%0, pev_impulse) == g_iszMuzzleKey)

#define IsCustomItem(%0) (pev(%0, pev_impulse) == WEAPON_KEY)

public plugin_precache()
{
	Weapon_OnPrecache();
	
	g_iszMuzzleKey = engfunc(EngFunc_AllocString, MUZZLE_CLASSNAME2);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_forward(FM_PlaybackEvent,				"FakeMeta_PlaybackEvent",	 false);
	register_forward(FM_SetModel,					"FakeMeta_SetModel",		 false);
	register_forward(FM_UpdateClientData,				"FakeMeta_UpdateClientData_Post",true);
	register_message(get_user_msgid("DeathMsg"), 			"Message_DeathMsg")
	
	RegisterHam(Ham_Spawn, 			"weaponbox", 		"HamHook_Weaponbox_Spawn_Post", true);

	RegisterHam(Ham_TraceAttack,		"func_breakable",	"HamHook_Entity_TraceAttack", 	false);
	RegisterHam(Ham_TraceAttack,		"info_target", 		"HamHook_Entity_TraceAttack", 	false);
	RegisterHam(Ham_TraceAttack,		"player", 		"HamHook_Entity_TraceAttack", 	false);

	RegisterHam(Ham_Item_Deploy,		WEAPON_REFERANCE, 	"HamHook_Item_Deploy_Post",	true);
	RegisterHam(Ham_Item_Holster,		WEAPON_REFERANCE, 	"HamHook_Item_Holster",		false);
	RegisterHam(Ham_Item_AddToPlayer,	WEAPON_REFERANCE, 	"HamHook_Item_AddToPlayer",	false);
	
	RegisterHam(Ham_Weapon_Reload,		WEAPON_REFERANCE, 	"HamHook_Item_Reload",		false);
	RegisterHam(Ham_Weapon_WeaponIdle,	WEAPON_REFERANCE, 	"HamHook_Item_WeaponIdle",	false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERANCE, 	"HamHook_Item_PrimaryAttack",	false);
	RegisterHam(Ham_Item_PostFrame,		WEAPON_REFERANCE, 	"HamHook_Item_PostFrame",	false);
	
	RegisterHam(Ham_Think, 			"info_target",		"HamHook_Think", 		false);
	RegisterHam(Ham_Touch, 			"info_target",		"HamHook_Touch", 		false);
	
	RegisterHam(Ham_Think, 			"env_sprite",		"MuzzleFlash_Think", 		false);
	
	g_iItemID = zp_register_extra_item(ZP_ITEM_NAME, 		ZP_ITEM_COST, 			ZP_TEAM_HUMAN);
}
	
public Event_NewRound()
{
	remove_entity_name(DRAGON_CLASSNAME)
	remove_entity_name(MISSILE_CLASSNAME)
	remove_entity_name(WATER_CLASSNAME)
}
 public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_iItemID)
	{
		Weapon_Give(id);
	}
}

public plugin_natives()
{ 
	register_native("GetBuffM3", "NativeGiveWeapon", true) 
}

public NativeGiveWeapon(iPlayer)
{
	Weapon_Give(iPlayer);
}
public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)

	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
	
	static iActiveItem;iActiveItem = get_pdata_cbase(iAttacker, m_pActiveItem, extra_offset_player);
	if(get_user_weapon(iAttacker) == CSW_XM1014)
	{
		if (IsValidPev(iActiveItem) && IsCustomItem(iActiveItem))
		{
			set_msg_arg_string(4, "m3dragon")
		}
	}
	
	return PLUGIN_CONTINUE
}

public FakeMeta_UpdateClientData_Post(const iPlayer, const iSendWeapons, const CD_Handle)
{
	static iActiveItem;iActiveItem = get_pdata_cbase(iPlayer, m_pActiveItem, extra_offset_player);

	if (!IsValidPev(iActiveItem) || !IsCustomItem(iActiveItem))
	{
		return FMRES_IGNORED;
	}

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
	
	return FMRES_IGNORED;
}
	#define _call.%0(%1,%2) \
									\
	Weapon_On%0							\
	(								\
		%1, 							\
		%2,							\
									\
		get_pdata_int(%1, m_iClip, extra_offset_weapon),	\
		GetAmmoInventory(%2, PrimaryAmmoIndex(%1)),		\
		get_pdata_int(%1, m_fInSpecialReload, extra_offset_weapon), \
		GET_STATE(%1) \
	) 

public HamHook_Item_Deploy_Post(const iItem)
{
	new iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_call.Deploy(iItem, iPlayer);
	return HAM_IGNORED;
}

public HamHook_Item_Holster(const iItem)
{
	new iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	set_pev(iPlayer, pev_viewmodel, 0);
	set_pev(iPlayer, pev_weaponmodel, 0);
	
	_call.Holster(iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_WeaponIdle(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}

	_call.Idle(iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_Reload(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_call.Reload(iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_PrimaryAttack(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_call.PrimaryAttack(iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_PostFrame(const iItem)
{
	static iPlayer, iButton;

	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	if ((iButton = pev(iPlayer, pev_button)) & IN_ATTACK2 && get_pdata_float(iItem, m_flNextSecondaryAttack, extra_offset_weapon) <= 0.0)
	{
		_call.SecondaryAttack(iItem, iPlayer);
		set_pev(iPlayer, pev_button, iButton & ~IN_ATTACK2);
	}
		
	return HAM_IGNORED;
}
public HamHook_Think(const iEntity)
{
	if (!pev_valid(iEntity))
	{
		return HAM_IGNORED;
	}
	
	static iClassname[32];pev(iEntity, pev_classname, iClassname, sizeof(iClassname));
	
	static iAttacker;iAttacker=pev(iEntity, pev_owner);
	
	new Float:OriginEnt[3];pev(iEntity, pev_origin, OriginEnt);
	
	if (equal(iClassname, MUZZLE_CLASSNAME_LEFT))
	{	
		static iItem;iItem = get_pdata_cbase(iAttacker, m_pActiveItem, extra_offset_player);
		
		if (!IsValidPev(iItem) || !IsCustomItem(iItem) || !GET_STATE(iItem) || pev(iAttacker, pev_deadflag) == DAMAGE_YES || zp_get_user_zombie(iAttacker))
		{
			set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
			nav_set_special_ammo(iAttacker, 0)
			return HAM_SUPERCEDE;
		}
		
		static Float:flFrame;

		if (flFrame >= 19.0)flFrame=0.0;
		
		flFrame+=random_float(0.4, 0.5);
		
		static Float:iAmt;pev(iEntity, pev_renderamt, iAmt);
		
		if (iAmt < 224.0)iAmt += 3.5;

		set_pev(iEntity, pev_renderamt, iAmt);
	
		set_pev(iEntity, pev_frame, flFrame);	
		set_pev(iEntity, pev_nextthink, get_gametime() + 0.01);
	}
	else if (equal(iClassname, MUZZLE_CLASSNAME_RIGHT))
	{	
		static iItem;iItem = get_pdata_cbase(iAttacker, m_pActiveItem, extra_offset_player);
		
		if (!IsValidPev(iItem) || !IsCustomItem(iItem) || !GET_STATE(iItem) || pev(iAttacker, pev_deadflag) == DAMAGE_YES || zp_get_user_zombie(iAttacker))
		{
			set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
			nav_set_special_ammo(iAttacker, 0)
			return HAM_SUPERCEDE;
		}
		
		static Float:flFrame;

		if (flFrame >= 19.0)flFrame=0.0;
		
		flFrame+=random_float(0.4, 0.5);
		
		static Float:iAmt;pev(iEntity, pev_renderamt, iAmt);
		
		if (iAmt < 224.0)iAmt += 3.5;

		set_pev(iEntity, pev_renderamt, iAmt);
	
		set_pev(iEntity, pev_frame, flFrame);	
		set_pev(iEntity, pev_nextthink, get_gametime() + 0.01);
	}
	else if (equal(iClassname, MISSILE_CLASSNAME))
	{
		static Float:iFuser;pev(iEntity, pev_fuser3, iFuser);

		if (pev(iEntity, pev_movetype) == MOVETYPE_TOSS)
		{
			set_pev(iEntity, pev_velocity, Float:{0.0,0.0, -1000.0});
		}
	
		if (iFuser && iFuser <= get_gametime())
		{
			set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
			
			set_pev(iEntity, pev_fuser3, 0.0);
			Spawn(pev(iEntity, pev_owner), OriginEnt);
			
			return HAM_SUPERCEDE;
		}
		
		new Float:iAngle[3];
		
		iAngle[0] = 0.0;
		iAngle[1] = 0.0;
		iAngle[2] = random_float(0.0, -360.0);
		
		set_pev(iEntity, pev_angles, iAngle);
		
		set_pev(iEntity, pev_nextthink, get_gametime() + 0.01);
	}
	else if ( equal(iClassname, DRAGON_CLASSNAME))
	{
		static Float:iFuser;pev(iEntity, pev_fuser2, iFuser);

		if (iFuser && iFuser <= get_gametime())
		{
			set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
			set_pev(iEntity, pev_fuser2, 0.0);
			
			return HAM_IGNORED;
		}
		
		new pNull = FM_NULLENT;
		
		while((pNull = fm_find_ent_in_sphere(pNull, OriginEnt, WEAPON_RADIUS_EXP2)) != 0)
		{	
			new Float:vOrigin[3];pev(pNull, pev_origin, vOrigin);
			
			if (IsValidPev(pNull) && pev(pNull, pev_takedamage) != DAMAGE_NO && pev(pNull, pev_solid) != SOLID_NOT)
			{
				if (is_user_connected(pNull) && zp_get_user_zombie(pNull))
				{
					new Float:vOrigin[3], Float:damage;pev(pNull, pev_origin, vOrigin);
									
					Create_Blood(vOrigin, iBlood[0], iBlood[1], 76, 10);
					damage = WEAPON_DAMAGE_EXP2;
					if (damage > 0.0)
					{
						damage = random_float(damage-5.0, damage+5.0)
						ExecuteHamB(Ham_TakeDamage, pNull, iEntity, iAttacker, is_deadlyshot(iAttacker)?damage*1.5:damage, DMG_BULLET);
					}

					static Float:iVelo[3];pev(pNull, pev_velocity, iVelo);iVelo[0] = 0.0;iVelo[1] = 0.0;iVelo[2] += 200.0;
					set_pev(pNull, pev_velocity, iVelo);	

					set_pdata_float(pNull, m_flVelocityModifier, 1.0,  extra_offset_player);
				}
			}
		}
		OriginEnt[2] += (WEAPON_RADIUS_EXP2 * 2) - 10
		while((pNull = fm_find_ent_in_sphere(pNull, OriginEnt, WEAPON_RADIUS_EXP2 * 0.75 )) != 0)
		{	
			new Float:vOrigin[3];pev(pNull, pev_origin, vOrigin);
			
			if (IsValidPev(pNull) && pev(pNull, pev_takedamage) != DAMAGE_NO && pev(pNull, pev_solid) != SOLID_NOT)
			{
				if (is_user_connected(pNull) && zp_get_user_zombie(pNull))
				{
					new Float:vOrigin[3], Float:damage;pev(pNull, pev_origin, vOrigin);
									
					Create_Blood(vOrigin, iBlood[0], iBlood[1], 76, 10);
					damage = WEAPON_DAMAGE_EXP2;
					if (damage > 0.0)
					{
						damage = random_float(damage-40.0, damage-20.0)
						ExecuteHamB(Ham_TakeDamage, pNull, iEntity, iAttacker, is_deadlyshot(iAttacker)?damage*1.5:damage, DMG_BULLET);
					}
				}
			}
		}
		
		static Float:Alpha;pev(iEntity, pev_renderamt, Alpha)
		static Float:Life;pev(iEntity, pev_fuser2, Life)
		if(Life - get_gametime() <= 0.4){
			if((Alpha - 51.0) <= 0.0)
				set_pev(iEntity, pev_renderamt, 0.0 )
			else
				set_pev(iEntity, pev_renderamt, Alpha - 51.0 )
		}
		set_pev(iEntity, pev_nextthink, get_gametime() + 0.1);
	}
	else if (equal(iClassname, WATER_CLASSNAME))
	{
		static Float:iFuser;pev(iEntity, pev_fuser4, iFuser);
		
		if (iFuser && iFuser <= get_gametime())
		{
			set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
			
			set_pev(iEntity, pev_fuser4, 0.0);
	
			return HAM_SUPERCEDE;
		}
		
		set_pev(iEntity, pev_nextthink, get_gametime() + 0.01);
	}

	return HAM_IGNORED;
}	

public HamHook_Touch(const iEntity, const iOther)
{
	if(!pev_valid(iEntity))
	{
		return HAM_IGNORED;
	}
	
	static Classname[32];pev(iEntity, pev_classname, Classname, sizeof(Classname));
	
	static Float:OriginEnt[3];pev(iEntity, pev_origin, OriginEnt);
	static Float:vOrigin[3];pev(iOther, pev_origin, vOrigin);
	
	static iAttacker;iAttacker = pev(iEntity, pev_owner);

	if (equal(Classname, MISSILE_CLASSNAME))
	{	
		if (pev(iEntity, pev_iuser1))
		{
			return HAM_IGNORED;
		}
		
		set_pev(iEntity, pev_movetype, MOVETYPE_TOSS);
		set_pev(iEntity, pev_renderamt, 0.0);
		
		engfunc(EngFunc_DropToFloor, iEntity);
		
		set_pev(iEntity, pev_iuser1, 1);
		set_pev(iEntity, pev_fuser3, get_gametime() + 0.4);
		
		new pNull = FM_NULLENT;
	
		static TE_FLAG
		
		TE_FLAG |= TE_EXPLFLAG_NOSOUND
		TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, OriginEnt[0])
		engfunc(EngFunc_WriteCoord, OriginEnt[1])
		engfunc(EngFunc_WriteCoord, OriginEnt[2]+15.0)
		write_short(g_Fire_SprId)
		write_byte(35)
		write_byte(15)
		write_byte(TE_FLAG)
		message_end()

		while((pNull = fm_find_ent_in_sphere(pNull, OriginEnt, WEAPON_RADIUS_EXP)) != 0)
		{	
			new Float:vOrigin[3];pev(pNull, pev_origin, vOrigin);
			
			if (IsValidPev(pNull) && pev(pNull, pev_takedamage) != DAMAGE_NO && pev(pNull, pev_solid) != SOLID_NOT)
			{
				if (is_user_connected(pNull) && zp_get_user_zombie(pNull)/* && !IsWallBetweenPoints(vec, vOrigin, iPlayer)*/)
				{
					new Float:vOrigin[3], Float:dist, Float:damage;pev(pNull, pev_origin, vOrigin);
									
					Create_Blood(vOrigin, iBlood[0], iBlood[1], 76, 13);
					
					set_pev(pNull, pev_velocity, {0.0, 0.0, -100.0});
					
					dist = get_distance_f(OriginEnt, vOrigin);damage = WEAPON_DAMAGE_EXP - (WEAPON_DAMAGE_EXP/WEAPON_DAMAGE_EXP) * dist;
					if (damage > 0.0)
					{
						ExecuteHamB(Ham_TakeDamage, pNull, iEntity, iAttacker, is_deadlyshot(iAttacker)?damage*1.5:damage, DMG_BULLET);
					}
				}
			}
		}
		
		engfunc(EngFunc_EmitSound, iEntity, CHAN_ITEM, SOUND_EXPLODE, 1.0, ATTN_NORM, 0, PITCH_HIGH);
		
		return HAM_IGNORED;
	}
	return HAM_IGNORED;
}

CallOrigFireBullets3(const iItem, const iPlayer)
{
	static FakeMetaTraceLine;FakeMetaTraceLine=register_forward(FM_TraceLine,"FakeMeta_TraceLine",true)
	state FireBullets: Enabled;
	static Float: vecPuncheAngle[3];pev(iPlayer, pev_punchangle, vecPuncheAngle);
	
	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);
	set_pev(iPlayer, pev_punchangle, vecPuncheAngle);
	
	state FireBullets: Disabled;
	unregister_forward(FM_TraceLine,FakeMetaTraceLine,true)
}

public FakeMeta_PlaybackEvent() <FireBullets: Enabled>
{
	return FMRES_SUPERCEDE;
}

public FakeMeta_TraceLine(Float:vecStart[3], Float:vecEnd[3], iFlag, iIgnore, iTrase)
{
	if (iFlag & IGNORE_MONSTERS)
	{
		return FMRES_IGNORED;
	}
	
	static Float:vecfEnd[3],iHit,iDecal,glassdecal;
	
	if(!glassdecal)
	{	
		glassdecal=engfunc( EngFunc_DecalIndex, "{bproof1" )
	}
	
	iHit=get_tr2(iTrase,TR_pHit)
	
	if(iHit>0 && pev_valid(iHit))
		if(pev(iHit,pev_solid)!=SOLID_BSP)return FMRES_IGNORED
		else if(pev(iHit,pev_rendermode)!=0)iDecal=glassdecal
		else iDecal=random_num(41,45)
	else iDecal=random_num(41,45)

	get_tr2(iTrase, TR_vecEndPos, vecfEnd)
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecfEnd, 0)
	write_byte(TE_GUNSHOTDECAL)
	WRITE_COORD(vecfEnd[0])
	WRITE_COORD(vecfEnd[1])
	WRITE_COORD(vecfEnd[2])
	write_short(iHit > 0 ? iHit : 0)
	write_byte(iDecal)
	message_end()

	return FMRES_IGNORED
}

public HamHook_Entity_TraceAttack(const iEntity, const iAttacker, const Float: flDamage) <FireBullets: Enabled>
{
	static iItem;iItem = get_pdata_cbase(iAttacker, m_pActiveItem, extra_offset_player);

	if (!BitCheck(g_bitIsConnected, iAttacker) || !IsValidPev(iAttacker))
	{
		return;
	}
	
	if (!IsValidPev(iItem))
	{
		return;
	}
	/*
	if (is_user_alive(iEntity) && zp_get_user_zombie(iEntity) && !GET_STATE(iItem))
	{
		SET_SHOOTS(iItem, GET_SHOOTS(iItem)+1);
	}*/
	
	SetHamParamFloat(3, flDamage * WEAPON_MULTIPLIER_DAMAGE);
}

public MsgHook_Death()			</* Empty statement */>		{ /* Fallback */ }
public MsgHook_Death()			<FireBullets: Disabled>		{ /* Do notning */ }

public FakeMeta_PlaybackEvent() 		</* Empty statement */>		{ return FMRES_IGNORED; }
public FakeMeta_PlaybackEvent() 		<FireBullets: Disabled>		{ return FMRES_IGNORED; }

public HamHook_Entity_TraceAttack() 	</* Empty statement */>		{ /* Fallback */ }
public HamHook_Entity_TraceAttack() 	<FireBullets: Disabled>		{ /* Do notning */ }

Weapon_Create(const Float: vecOrigin[3] = {0.0, 0.0, 0.0}, const Float: vecAngles[3] = {0.0, 0.0, 0.0})
{
	new iWeapon;

	static iszAllocStringCached;
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, WEAPON_REFERANCE)))
	{
		iWeapon = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	
	if (!IsValidPev(iWeapon))
	{
		return FM_NULLENT;
	}
	
	MDLL_Spawn(iWeapon);
	SET_ORIGIN(iWeapon, vecOrigin);
	
	set_pdata_int(iWeapon, m_iClip, WEAPON_MAX_CLIP, extra_offset_weapon);

	set_pev(iWeapon, pev_impulse, WEAPON_KEY);
	set_pev(iWeapon, pev_angles, vecAngles);
	
	Weapon_OnSpawn(iWeapon);
	
	return iWeapon;
}

Weapon_Give(const iPlayer)
{
	if (!IsValidPev(iPlayer))
	{
		return FM_NULLENT;
	}
	
	new iWeapon, Float: vecOrigin[3];pev(iPlayer, pev_origin, vecOrigin);
	
	if ((iWeapon = Weapon_Create(vecOrigin)) != FM_NULLENT)
	{
		Player_DropWeapons(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon));
		set_pev(iWeapon, pev_spawnflags, pev(iWeapon, pev_spawnflags) | SF_NORESPAWN);
		MDLL_Touch(iWeapon, iPlayer);
		SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iWeapon), WEAPON_DEFAULT_AMMO);
		
		return iWeapon;
	}
	
	return FM_NULLENT;
}

Player_DropWeapons(const iPlayer, const iSlot)
{
	new szWeaponName[32], iItem = get_pdata_cbase(iPlayer, m_rgpPlayerItems_CBasePlayer + iSlot, extra_offset_player);

	while (IsValidPev(iItem))
	{
		pev(iItem, pev_classname, szWeaponName, charsmax(szWeaponName));
		engclient_cmd(iPlayer, "drop", szWeaponName);

		iItem = get_pdata_cbase(iItem, m_pNext, extra_offset_weapon);
	}
}

Weapon_SendAnim(const iPlayer, const iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, iPlayer);
	WRITE_BYTE(iAnim);
	WRITE_BYTE(0);
	MESSAGE_END();
}

stock Spawn2(const iPlayer, const Float:iVec[3], const Float:vecEnd[3])
{
	static iszAllocStringCached;
	static pEntity;

	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "info_target")))
	{
		pEntity = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
		
	if (pev_valid(pEntity))
	{
		set_pev(pEntity, pev_movetype, MOVETYPE_FLYMISSILE);
		set_pev(pEntity, pev_owner, iPlayer);
			
		SET_MODEL(pEntity, MISSILEMODEL);
		SET_ORIGIN(pEntity, iVec);

		set_pev(pEntity, pev_classname, MISSILE_CLASSNAME);
		set_pev(pEntity, pev_solid, SOLID_TRIGGER);
		set_pev(pEntity, pev_gravity, 0.01);
		
		set_pev(pEntity, pev_scale, 2.0);

		set_pev(pEntity, pev_mins, Float:{-1.0, -1.0, -1.0});
		set_pev(pEntity, pev_maxs, Float:{1.0, 1.0, 1.0});
		
		Sprite_SetTransparency(pEntity, kRenderTransAdd, Float:{255.0,255.0,255.0}, 255.0);
		
		set_pev(pEntity, pev_nextthink, get_gametime() + 0.01);
		
		new Float:Velocity[3];Get_Speed_Vector(iVec, vecEnd, 1500.0, Velocity);
		set_pev(pEntity, pev_velocity, Velocity);
	}
}

stock Spawn(const iPlayer, Float:iVec[3])
{
	static iszAllocStringCached;
	static pEntity;

	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "info_target")))
	{
		pEntity = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	if (pev_valid(pEntity))
	{
		new Float:Angles[3];
		Angles[1] += random_float(0.0,360.0)
		set_pev(pEntity, pev_angles, Angles)
		
		set_pev(pEntity, pev_movetype, MOVETYPE_TOSS);
		set_pev(pEntity, pev_owner, iPlayer);
			
		SET_MODEL(pEntity, SHARKMODEL);
		SET_ORIGIN(pEntity, iVec);

		set_pev(pEntity, pev_rendermode, kRenderTransAdd)
		set_pev(pEntity, pev_renderamt, 240.0)
		set_pev(pEntity, pev_classname, DRAGON_CLASSNAME);
		set_pev(pEntity, pev_solid, SOLID_NOT);

		//SET_SIZE(pEntity, Float:{-55.0, -55.0, -100.0}, Float:{55.0, 55.0, 300.0});
		
		set_pev(pEntity, pev_framerate, 1.0);
		set_pev(pEntity, pev_sequence, 0);
		set_pev(pEntity, pev_animtime, get_gametime());

		set_pev(pEntity, pev_fuser2, get_gametime() + 3.0);

		set_pev(pEntity, pev_nextthink, get_gametime() + 0.1);

		set_task(0.5, "playSound", pEntity)
	}
	
	// static iszAllocStringCached2;
	// static pEntity2;

	// if (iszAllocStringCached2 || (iszAllocStringCached2 = engfunc(EngFunc_AllocString, "info_target")))
	// {
	// 	pEntity2 = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached2);
	// }
		
	// if (pev_valid(pEntity2))
	// {
	// 	set_pev(pEntity2, pev_movetype, MOVETYPE_TOSS);
	// 	set_pev(pEntity2, pev_owner, iPlayer);
			
	// 	SET_MODEL(pEntity2, WATERMODEL);
	// 	SET_ORIGIN(pEntity2, iVec);

	// 	set_pev(pEntity2, pev_classname, WATER_CLASSNAME);
	// 	set_pev(pEntity2, pev_solid, SOLID_NOT);

	// 	//SET_SIZE(pEntity, Float:{-100.0, -100.0, -100.0}, Float:{100.0, 100.0, 300.0});
		
	// 	set_pev(pEntity2, pev_framerate, 1.0);
	// 	set_pev(pEntity2, pev_sequence, 0);
	// 	set_pev(pEntity2, pev_animtime, get_gametime());

	// 	set_pev(pEntity2, pev_fuser4, get_gametime() + 3.5);

	// 	set_pev(pEntity2, pev_nextthink, get_gametime() + 0.1);
	// }
}
public playSound(ent)
{
		emit_sound(ent, CHAN_WEAPON, SOUND_DRAGONFX, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
stock Sprite_SetTransparency(const iSprite, const iRendermode, const Float: vecColor[3], const Float: flAmt, const iFx = kRenderFxNone)
{
	set_pev(iSprite, pev_rendermode, iRendermode);
	set_pev(iSprite, pev_rendercolor, vecColor);
	set_pev(iSprite, pev_renderamt, flAmt);
	set_pev(iSprite, pev_renderfx, iFx);
}

stock MuzzleFlash(const iPlayer, const szMuzzleSprite[], const iClass[], const Float: flScale, const Float: flFramerate, const iBody, const Float:iFrame, const Float:iAmt)
{
	if (global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < 100)
	{
		return FM_NULLENT;
	}
	
	new iSprite, iszAllocStringCached;
	
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "info_target")))
	{
		iSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	
	if (!IsValidPev(iSprite))
	{
		return FM_NULLENT;
	}
	
	new Float:Origin[3], Float:iAngles[3];engfunc(EngFunc_GetAttachment, iPlayer, 0, Origin, iAngles);

	SET_MODEL(iSprite, szMuzzleSprite);
	SET_ORIGIN(iSprite, Origin);
	
	set_pev(iSprite, pev_classname, iClass);
	set_pev(iSprite, pev_owner, iPlayer);
	set_pev(iSprite, pev_movetype, MOVETYPE_FOLLOW);
	set_pev(iSprite, pev_skin, iPlayer);
	set_pev(iSprite, pev_body, iBody);
	set_pev(iSprite, pev_frame, iFrame);
	set_pev(iSprite, pev_light_level, 255.0);

	Sprite_SetTransparency(iSprite, kRenderTransAdd, Float:{255.0,255.0,255.0}, iAmt);
	
	Sprite_SetFramerate(iSprite, flFramerate);
	Sprite_SetScale(iSprite, flScale);
	set_pev(iSprite, pev_angles, iAngles);

	set_pev(iSprite, pev_nextthink, get_gametime() + 0.01);
	
	return iSprite;
}

public MuzzleFlash_Think(const iSprite)
{
	static Float: flFrame;
	
	if (!IsValidPev(iSprite) || !IsCustomMuzzle(iSprite))
	{
		return HAM_IGNORED;
	}
	
	if (pev(iSprite, pev_frame, flFrame) && ++flFrame - 1.0 < get_pdata_float(iSprite, 35, extra_offset_weapon)) //m_MaxFrame
	{
		set_pev(iSprite, pev_frame, flFrame);
		set_pev(iSprite, pev_nextthink, get_gametime() + 0.035);
		
		return HAM_SUPERCEDE;
	}

	set_pev(iSprite, pev_flags, FL_KILLME);
	return HAM_SUPERCEDE;
}

stock Get_Speed_Vector(const Float:origin1[3], const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
}

stock Weapon_DefaultDeploy(const iPlayer, const szViewModel[], const szWeaponModel[], const iAnim, const szAnimExt[])
{
	set_pev(iPlayer, pev_viewmodel2, szViewModel);
	set_pev(iPlayer, pev_weaponmodel2, szWeaponModel);
	set_pev(iPlayer, pev_fov,90.0);
	
	set_pdata_int(iPlayer, m_iFOV, 90, extra_offset_player);
	set_pdata_int(iPlayer, m_fResumeZoom, 0, extra_offset_player);
	set_pdata_int(iPlayer, m_iLastZoom, 90, extra_offset_player);
	
	set_pdata_string(iPlayer, m_szAnimExtention * 4, szAnimExt, -1, extra_offset_player * 4);
	
	Weapon_SendAnim(iPlayer, iAnim);
}

stock Punchangle(iPlayer, Float:iVecx = 0.0, Float:iVecy = 0.0, Float:iVecz = 0.0)
{
	static Float:iVec[3];pev(iPlayer, pev_punchangle,iVec);
	iVec[0] = iVecx;iVec[1] = iVecy;iVec[2] = iVecz;
	set_pev(iPlayer, pev_punchangle, iVec);
}

stock GetWeaponPosition(const iPlayer, Float: forw, Float: right, Float: up, Float: vStart[])
{
	new Float: vOrigin[3], Float: vAngle[3], Float: vForward[3], Float: vRight[3], Float: vUp[3];
	
	pev(iPlayer, pev_origin, vOrigin);
	pev(iPlayer, pev_view_ofs, vUp);
	xs_vec_add(vOrigin, vUp, vOrigin);
	pev(iPlayer, pev_v_angle, vAngle);
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward);
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight);
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp);
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up;
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up;
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up;
}

stock Create_Blood(const Float:vStart[3], const iModel, const iModel2, const iColor, const iScale)
{
	MESSAGE_BEGIN(MSG_BROADCAST, SVC_TEMPENTITY, vStart, 0);
	WRITE_BYTE(TE_BLOODSPRITE);
	WRITE_COORD(vStart[0])
	WRITE_COORD(vStart[1])
	WRITE_COORD(vStart[2])
	WRITE_SHORT(iModel);
	WRITE_SHORT(iModel2);
	WRITE_BYTE(iColor);
	WRITE_BYTE(iScale);
	MESSAGE_END();
}
new g_bot
public client_putinserver(id)
{
	BitSet(g_bitIsConnected, id);
	if(is_user_bot(id) && !g_bot)
	{
		g_bot = 1
		set_task(0.1, "Do_RegisterHamBot", id)
	}
}
public Do_RegisterHamBot(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "HamHook_Entity_TraceAttack")
}

public client_disconnect(id)
{
	BitClear(g_bitIsConnected, id);
}


bool: CheckItem(const iItem, &iPlayer)
{
	if (!IsValidPev(iItem) || !IsCustomItem(iItem))
	{
		return false;
	}
	
	iPlayer = get_pdata_cbase(iItem, m_pPlayer, extra_offset_weapon);
	
	if (!IsValidPev(iPlayer) || !BitCheck(g_bitIsConnected, iPlayer))
	{
		return false;
	}
	
	return true;
}

public HamHook_Item_AddToPlayer(const iItem, const iPlayer)
{
	switch(pev(iItem, pev_impulse))
	{
		case WEAPON_KEY: 
		{
			SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iItem), pev(iItem, pev_iuser2));
		}
	}
	
	return HAM_IGNORED;
}
public HamHook_Weaponbox_Spawn_Post(const iWeaponBox)
{
	if (IsValidPev(iWeaponBox))
	{
		state (IsValidPev(pev(iWeaponBox, pev_owner))) WeaponBox: Enabled;
	}
	
	return HAM_IGNORED;
}

public FakeMeta_SetModel(const iEntity) <WeaponBox: Enabled>
{
	state WeaponBox: Disabled;
	
	if (!IsValidPev(iEntity))
	{
		return FMRES_IGNORED;
	}
	
	#define MAX_ITEM_TYPES	6
	
	for (new i, iItem; i < MAX_ITEM_TYPES; i++)
	{
		iItem = get_pdata_cbase(iEntity, m_rgpPlayerItems_CWeaponBox + i, extra_offset_weapon);
		
		if (IsValidPev(iItem) && IsCustomItem(iItem))
		{
			SET_MODEL(iEntity, MODEL_WORLD);	
			set_pev(iItem, pev_iuser2, GetAmmoInventory(pev(iEntity,pev_owner), PrimaryAmmoIndex(iItem)))
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public FakeMeta_SetModel()	</* Empty statement */>	{ /*  Fallback  */ return FMRES_IGNORED; }
public FakeMeta_SetModel() 	< WeaponBox: Disabled >	{ /* Do nothing */ return FMRES_IGNORED; }

PrimaryAmmoIndex(const iItem)
{
	return get_pdata_int(iItem, m_iPrimaryAmmoType, extra_offset_weapon);
}

GetAmmoInventory(const iPlayer, const iAmmoIndex)
{
	if (iAmmoIndex == -1)
	{
		return -1;
	}

	return get_pdata_int(iPlayer, m_rgAmmo_CBasePlayer + iAmmoIndex, extra_offset_player);
}

SetAmmoInventory(const iPlayer, const iAmmoIndex, const iAmount)
{
	if (iAmmoIndex == -1)
	{
		return 0;
	}

	set_pdata_int(iPlayer, m_rgAmmo_CBasePlayer + iAmmoIndex, iAmount, extra_offset_player);
	return 1;
}

stock Player_SetAnimation(const iPlayer, const szAnim[])
{
	   if(!is_user_alive(iPlayer))return;
		
	   #define ACT_RANGE_ATTACK1   28
	   
	   // Linux extra offsets
	   #define extra_offset_animating   4
	   
	   // CBaseAnimating
	   #define m_flFrameRate      36
	   #define m_flGroundSpeed      37
	   #define m_flLastEventCheck   38
	   #define m_fSequenceFinished   39
	   #define m_fSequenceLoops   40
	   
	   // CBaseMonster
	   #define m_Activity      73
	   #define m_IdealActivity      74
	   
	   // CBasePlayer
	   #define m_flLastAttackTime   220
	   
	   new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
	      
	   if ((iAnimDesired = lookup_sequence(iPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed)) == -1)
	   {
	      iAnimDesired = 0;
	   }
   
	   new Float: flGametime = get_gametime();
	
	   set_pev(iPlayer, pev_frame, 0.0);
	   set_pev(iPlayer, pev_framerate, 1.0);
	   set_pev(iPlayer, pev_animtime, flGametime );
	   set_pev(iPlayer, pev_sequence, iAnimDesired);
	   
	   set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, extra_offset_animating);
	   set_pdata_int(iPlayer, m_fSequenceFinished, 0, extra_offset_animating);
	   
	   set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, extra_offset_animating);
	   set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, extra_offset_animating);
	   set_pdata_float(iPlayer, m_flLastEventCheck, flGametime , extra_offset_animating);
	   
	   set_pdata_int(iPlayer, m_Activity, ACT_RANGE_ATTACK1, extra_offset_player);
	   set_pdata_int(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, extra_offset_player);   
	   set_pdata_float(iPlayer, m_flLastAttackTime, flGametime , extra_offset_player);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
