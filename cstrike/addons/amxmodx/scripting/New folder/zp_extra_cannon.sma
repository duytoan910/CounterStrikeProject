#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <fun>
#include <gunxpmod>
#include <toan>

#define PLUGIN 					"[ZP] Extra: CSO Weapon Dragon Cannon +6"
#define VERSION 				"1.0"
#define AUTHOR 					"KORD_12.7"

#pragma ctrlchar 				'\'
#pragma compress 				1
// Main
#define WEAPON_NAME 				"weapon_cannon"
#define WEAPON_REFERANCE			"weapon_m249"

#define WEAPON_MAX_CLIP				1
#define WEAPON_DEFAULT_AMMO			30

#define WEAPON_DAMAGE				random_float(60.0, 80.0) //FLOAT 
#define WEAPON_KNOCKBACK			2.0
#define WEAPON_RADIUS_EXP			200.0
#define WEAPON_DAMAGE_EXP			random_float(1000.0, 1500.0)

#define WEAPON_TIME_NEXT_IDLE 			10.0
#define WEAPON_TIME_DELAY_DEPLOY 		1.4

#define ZP_ITEM_NAME				"Black Dragon Cannon" 
#define ZP_ITEM_COST				10000

// Models
#define MODEL_WORLD 				"models/w_cannon_6.mdl"
#define MODEL_VIEW					"models/v_cannon_6.mdl"
#define MODEL_VIEWB					"models/v_cannon_6b.mdl"
#define MODEL_PLAYER				"models/p_cannon_6.mdl"
#define MODEL_MISSIL				"models/DragonModel.mdl"

#define MODEL_BALL				"sprites/flame_puff01.spr"
#define MODEL_BALLB				"sprites/flame_puff01_blue.spr"
#define MODEL_EXP				"sprites/ef_cannon6_explotion.spr"

// Sounds
#define SOUND_FIRE				"weapons/cannon-1.wav"
#define SOUND_DRAGON_EXP			"weapons/canon_firebal_exp.wav"
#define SOUND_FIRE2				"weapons/canon_fireball.wav"	

// Animation
#define ANIM_EXTENSION				"rifle"
#define MISSILE_CLASSNAME			"FireDragon"

// Animation sequences 
enum 
{ 
ANIM_IDLE_A, 
ANIM_SHOOT_A, 
ANIM_DRAW_A,
};

#define MDLL_Spawn(%0)				dllfunc(DLLFunc_Spawn, %0)
#define MDLL_Touch(%0,%1)			dllfunc(DLLFunc_Touch, %0, %1)

#define SET_MODEL(%0,%1)			engfunc(EngFunc_SetModel, %0, %1)
#define SET_ORIGIN(%0,%1)			engfunc(EngFunc_SetOrigin, %0, %1)
#define SET_SIZE(%0,%1,%2)			engfunc(EngFunc_SetSize, %0, %1, %2)
#define PRECACHE_MODEL(%0)			engfunc(EngFunc_PrecacheModel, %0)
#define PRECACHE_SOUND(%0)			engfunc(EngFunc_PrecacheSound, %0)
#define PRECACHE_GENERIC(%0)			engfunc(EngFunc_PrecacheGeneric, %0)

#define MESSAGE_BEGIN(%0,%1,%2,%3)		engfunc(EngFunc_MessageBegin, %0, %1, %2, %3)
#define MESSAGE_END()				message_end()

#define WRITE_BYTE(%0)				write_byte(%0)
#define WRITE_COORD(%0)				engfunc(EngFunc_WriteCoord, %0)
#define WRITE_STRING(%0)			write_string(%0)
#define WRITE_SHORT(%0)				w/rite_short(%0)

#define BitSet(%0,%1) 				(%0 |= (1 << (%1 - 1)))
#define BitClear(%0,%1) 			(%0 &= ~(1 << (%1 - 1)))
#define BitCheck(%0,%1) 			(%0 & (1 << (%1 - 1)))

// Linux extra offsets
#define extra_offset_weapon			4
#define extra_offset_player			5

new g_bitIsConnected;
#define m_rgpPlayerItems_CWeaponBox		34

// CBasePlayerItem
#define m_pPlayer				41
#define m_pNext					42

// CBasePlayerWeapon
#define m_fFireOnEmpty 				45
#define m_flNextPrimaryAttack			46
#define m_flNextSecondaryAttack			47
#define m_flTimeWeaponIdle			48
#define m_iPrimaryAmmoType			49
#define m_iClip					51
#define m_fInReload				54
#define m_iLastZoom 				109

// CBaseMonster
#define m_flNextAttack				83

// CBasePlayer
#define m_fResumeZoom       			110
#define m_iFOV					363
#define m_rgpPlayerItems_CBasePlayer		367
#define m_pActiveItem				373
#define m_rgAmmo_CBasePlayer			376
#define m_szAnimExtention			492

#define IsValidPev(%0) 				(pev_valid(%0) == 2)
#define GET_ATTACHMENT(%0,%1,%2,%3)		engfunc(EngFunc_GetAttachment, %0, %1, %2, %3)

#define BALL_CLASSNAME				"FireCannon"

new iBlood[5];

Weapon_OnPrecache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_VIEWB);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_MODEL(MODEL_MISSIL);
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_FIRE2);
	PRECACHE_SOUND(SOUND_DRAGON_EXP);
	
	iBlood[0] = PRECACHE_MODEL("sprites/bloodspray.spr");
	iBlood[1] = PRECACHE_MODEL("sprites/blood.spr");
	iBlood[2] = PRECACHE_MODEL(MODEL_BALL);
	iBlood[3] = PRECACHE_MODEL(MODEL_BALLB);
	iBlood[4] = PRECACHE_MODEL(MODEL_EXP);
	
	precache_sound("weapons/cannon_draw.wav")
	precache_sound("weapons/cannon_reload.wav")
}

Weapon_OnSpawn(const iItem)
{
	// Setting world model.
	SET_MODEL(iItem, MODEL_WORLD);
}

Weapon_OnDeploy(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iClip, iAmmoPrimary
	
	static iszViewModel;

	if (iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, pev(iItem, pev_iuser4)?MODEL_VIEWB:MODEL_VIEW)))
	{
		set_pev_string(iPlayer, pev_viewmodel2, iszViewModel);
	}
	static iszPlayerModel;
	if (iszPlayerModel || (iszPlayerModel = engfunc(EngFunc_AllocString, MODEL_PLAYER)))
	{
		set_pev_string(iPlayer, pev_weaponmodel2, iszPlayerModel);
	}

	set_pdata_int(iItem, m_fInReload, 0, extra_offset_weapon);

	set_pdata_string(iPlayer, m_szAnimExtention * 4, ANIM_EXTENSION, -1, extra_offset_player * 4);
	
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_DELAY_DEPLOY, extra_offset_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_TIME_DELAY_DEPLOY, extra_offset_player);

	Weapon_DefaultDeploy(iPlayer, pev(iItem, pev_iuser4)?MODEL_VIEWB:MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW_A, ANIM_EXTENSION);
}

Weapon_OnHolster(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iPlayer, iClip, iAmmoPrimary
	
	set_pdata_int(iItem, m_fInReload, 0, extra_offset_weapon);
	
	set_pev(iItem, pev_fuser2, 0.0);
}

Weapon_OnIdle(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iClip, iAmmoPrimary
	
	ExecuteHamB(Ham_Weapon_ResetEmptySound, iItem);

	if (get_pdata_float(iItem, m_flTimeWeaponIdle, extra_offset_weapon) > 0.0)
	{
		return;
	}
	
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_IDLE, extra_offset_weapon);
	Weapon_SendAnim(iPlayer, ANIM_IDLE_A);
}

Weapon_OnPrimaryAttack(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iClip, iAmmoPrimary
	
	if (iAmmoPrimary <= 0)
	{
		if (get_pdata_int(iItem, m_fFireOnEmpty, extra_offset_player))
		{
			ExecuteHamB(Ham_Weapon_PlayEmptySound, iItem);
			set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, extra_offset_weapon);
		}	
		return;
	}
	
	switch (random(5))
	{
		case 0:Weapon_OnShoot(iItem, iPlayer, false);
		case 1:
		{
			Weapon_OnShoot(iItem, iPlayer, false);
			set_pev(iItem, pev_fuser1, get_gametime()+0.1);
			set_pev(iItem, pev_iuser1, 1);
		}
		case 2:Weapon_OnShoot(iItem, iPlayer, false);
		case 3:
		{
			Weapon_OnShoot(iItem, iPlayer, false);
			set_pev(iItem, pev_fuser1, get_gametime()+0.1);
			set_pev(iItem, pev_iuser1, 1);
		}
		case 4:Weapon_OnShoot(iItem, iPlayer, false);
	}
}

Weapon_OnSecondaryAttack(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iClip, iAmmoPrimary

	if (iAmmoPrimary <= 0)
	{
		if (get_pdata_int(iItem, m_fFireOnEmpty, extra_offset_player))
		{
			ExecuteHamB(Ham_Weapon_PlayEmptySound, iItem);
			set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, extra_offset_weapon);
		}	
		return;
	}
	
	static szAnimation[64];formatex(szAnimation, charsmax(szAnimation), "ref_shoot_%s", ANIM_EXTENSION);
	Player_SetAnimation(iPlayer, szAnimation);
	
	set_pdata_float(iItem, m_flNextPrimaryAttack, 3.5, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 3.5, extra_offset_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 3.5, extra_offset_weapon);
		
	Weapon_SendAnim(iPlayer, ANIM_SHOOT_A);
			
	Punchangle(iPlayer, .iVecx = random_float(-2.0, -2.5), .iVecy = 0.0, .iVecz = 0.0);
			
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE2, 0.5, ATTN_NORM, 0, PITCH_NORM);
			
	SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iItem), GetAmmoInventory(iPlayer, PrimaryAmmoIndex(iItem)) - 1);
	
	CreateMissile(iPlayer, iItem);
}

public CreateMissile(const iPlayer, skin)
{
	if (global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < 100)
	{
		return;
	}
	
	static iszAllocStringCached, pEntity;
	
	static Float:VecEnd[3];fm_get_aim_origin(iPlayer, VecEnd);
	static Float:vAngle[3], Float:Angles[3];pev(iPlayer,pev_v_angle,vAngle);
	static Float:Origin[3];GET_ATTACHMENT(iPlayer, 0, Origin, Angles);
	Angles[0] = 360.0 - vAngle[0];Angles[1] = vAngle[1];Angles[2] = vAngle[2];
	
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "info_target")))
	{
		pEntity = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
		
	if (pev_valid(pEntity))
	{
		set_pev(pEntity, pev_movetype, MOVETYPE_TOSS);
		set_pev(pEntity, pev_owner, iPlayer);
			
		SET_MODEL(pEntity, MODEL_MISSIL);
		SET_ORIGIN(pEntity, Origin);
	
		set_pev(pEntity, pev_classname, MISSILE_CLASSNAME);
		set_pev(pEntity, pev_solid, SOLID_BBOX);
		set_pev(pEntity, pev_angles, Angles);
		set_pev(pEntity, pev_gravity, 0.001);
		set_pev(pEntity, pev_iuser3, skin);
		SET_SIZE(pEntity, Float:{-2.0, -2.0, -2.0}, Float:{2.0, 2.0, 2.0});
		set_pev(pEntity, pev_nextthink, get_gametime() + 0.01);
	
		static Float:Velocity[3];Get_Speed_Vector(Origin, VecEnd, 1500.0, Velocity);
		set_pev(pEntity, pev_velocity, Velocity);
	}
}


	#define _call.%0(%1,%2) \
									\
	Weapon_On%0							\
	(								\
		%1, 							\
		%2,							\
									\
		get_pdata_int(%1, m_iClip, extra_offset_weapon),	\
		GetAmmoInventory(%2, PrimaryAmmoIndex(%1))		\
	) 

Weapon_OnShoot(const iItem, const iPlayer, bool:iType)
{
	static szAnimation[64];

	new enemy, body
	get_user_aiming(iPlayer, enemy, body)
	if ((1 <= enemy <= 32) && zp_get_user_zombie(enemy) && is_user_bot(iPlayer))
	{
		new origin1[3] ,origin2[3],range
		get_user_origin(iPlayer,origin1)
		get_user_origin(enemy,origin2)
		range = get_distance(origin1, origin2)
		if(range <= 200)
		{
			switch (iType)
			{
				case false:
				{
					Weapon_OnSpawnFlame(iPlayer, pev(iItem, pev_iuser4));
					
					set_pdata_float(iItem, m_flNextPrimaryAttack, 3.2, extra_offset_weapon);
					set_pdata_float(iItem, m_flNextSecondaryAttack, 3.2, extra_offset_weapon);
					set_pdata_float(iItem, m_flTimeWeaponIdle, 3.2, extra_offset_weapon);
				
					Weapon_SendAnim(iPlayer, ANIM_SHOOT_A);
					
					Punchangle(iPlayer, .iVecx = random_float(-2.0, -2.5), .iVecy = 0.0, .iVecz = 0.0);
					
					engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE, 1.0, ATTN_NORM, 0, PITCH_NORM);
					
					SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iItem), GetAmmoInventory(iPlayer, PrimaryAmmoIndex(iItem)) - 1);
					
					formatex(szAnimation, charsmax(szAnimation), "ref_shoot_%s", ANIM_EXTENSION);
					Player_SetAnimation(iPlayer, szAnimation);
				}
				case true:
				{
					Weapon_OnSpawnFlame(iPlayer, pev(iItem, pev_iuser4));
					
					set_pdata_float(iItem, m_flNextPrimaryAttack, 3.2, extra_offset_weapon);
					set_pdata_float(iItem, m_flNextSecondaryAttack, 3.2, extra_offset_weapon);
					set_pdata_float(iItem, m_flTimeWeaponIdle, 3.2, extra_offset_weapon);
				
			
					Punchangle(iPlayer, .iVecx = random_float(-2.0, -2.5), .iVecy = 0.0, .iVecz = 0.0);
					
					engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE, 1.0, ATTN_NORM, 0, PITCH_NORM);
					
					formatex(szAnimation, charsmax(szAnimation), "ref_shoot_%s", ANIM_EXTENSION);
					Player_SetAnimation(iPlayer, szAnimation);

					set_pev(iItem, pev_iuser1, 0);
				}
			}
		}else{
			_call.SecondaryAttack(iItem, iPlayer);
		}
	}else{
		switch (iType)
		{
			case false:
			{
				Weapon_OnSpawnFlame(iPlayer, pev(iItem, pev_iuser4));
				
				set_pdata_float(iItem, m_flNextPrimaryAttack, 3.2, extra_offset_weapon);
				set_pdata_float(iItem, m_flNextSecondaryAttack, 3.2, extra_offset_weapon);
				set_pdata_float(iItem, m_flTimeWeaponIdle, 3.2, extra_offset_weapon);
			
				Weapon_SendAnim(iPlayer, ANIM_SHOOT_A);
				
				Punchangle(iPlayer, .iVecx = random_float(-2.0, -2.5), .iVecy = 0.0, .iVecz = 0.0);
				
				engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE, 1.0, ATTN_NORM, 0, PITCH_NORM);
				
				SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iItem), GetAmmoInventory(iPlayer, PrimaryAmmoIndex(iItem)) - 1);
				
				formatex(szAnimation, charsmax(szAnimation), "ref_shoot_%s", ANIM_EXTENSION);
				Player_SetAnimation(iPlayer, szAnimation);
			}
			case true:
			{
				Weapon_OnSpawnFlame(iPlayer, pev(iItem, pev_iuser4));
				
				set_pdata_float(iItem, m_flNextPrimaryAttack, 3.2, extra_offset_weapon);
				set_pdata_float(iItem, m_flNextSecondaryAttack, 3.2, extra_offset_weapon);
				set_pdata_float(iItem, m_flTimeWeaponIdle, 3.2, extra_offset_weapon);
			
		
				Punchangle(iPlayer, .iVecx = random_float(-2.0, -2.5), .iVecy = 0.0, .iVecz = 0.0);
				
				engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE, 1.0, ATTN_NORM, 0, PITCH_NORM);
				
				formatex(szAnimation, charsmax(szAnimation), "ref_shoot_%s", ANIM_EXTENSION);
				Player_SetAnimation(iPlayer, szAnimation);

				set_pev(iItem, pev_iuser1, 0);
			}
		}
	}
}

Weapon_OnSpawnFlame(const iPlayer, skin)
{
	new pEntity;
	new Float:EndOrigin[7][3], Float:Origin[3], Float:iAngle[3];pev(iPlayer, pev_origin, Origin);Get_Position(iPlayer, 5.0, 0.0, 0.0, Origin);
	Get_Position(iPlayer, 512.0, -150.0, -5.0, EndOrigin[0]);
	Get_Position(iPlayer, 512.0, -100.0, -5.0, EndOrigin[1]);
	Get_Position(iPlayer, 512.0, -50.0, 5.0, EndOrigin[2]);
	Get_Position(iPlayer, 512.0, 0.0, 0.0, EndOrigin[3]);
	Get_Position(iPlayer, 512.0, 50.0, -5.0, EndOrigin[4]);
	Get_Position(iPlayer, 512.0, 100.0, 5.0, EndOrigin[5]);
	Get_Position(iPlayer, 512.0, 150.0, 5.0, EndOrigin[6]);
	for(new i = 0; i < 7; i++)
	{
					
		static iszAllocStringCached;
		if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "info_target")))
		{
			pEntity = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
		}
			
		if (pev_valid(pEntity))
		{
			iAngle[2] = random_float(-1.0, 360.0)
				
			set_pev(pEntity, pev_movetype, MOVETYPE_TOSS);
			set_pev(pEntity, pev_owner, iPlayer);
						
			SET_MODEL(pEntity, skin?MODEL_BALLB:MODEL_BALL);
			SET_ORIGIN(pEntity, Origin);
				
			set_pev(pEntity, pev_classname, BALL_CLASSNAME);
			set_pev(pEntity, pev_scale, 0.15);
			set_pev(pEntity, pev_mins, Float:{-2.0, -2.0, -2.0});
			set_pev(pEntity, pev_maxs, Float:{2.0, 2.0, 2.0});
			set_pev(pEntity, pev_solid, SOLID_TRIGGER);
			set_pev(pEntity, pev_gravity, 0.01);
			set_pev(pEntity, pev_frame, 0.0);
			set_pev(pEntity, pev_angles, iAngle)
			set_pev(pEntity, pev_nextthink, get_gametime() + 0.01);
				
			static Float:iVelocity[3];Stock_Get_Speed_Vector(Origin, EndOrigin[i], 400.0, iVelocity);
			set_pev(pEntity, pev_velocity, iVelocity);
			
			set_pev(pEntity, pev_rendermode, kRenderTransAdd)
			set_pev(pEntity, pev_renderamt, 200.0)
		}
	}
}

new g_iItemID;
new g_iszWeaponKey;

#define IsCustomItem(%0) (pev(%0, pev_impulse) == g_iszWeaponKey)

public plugin_precache()
{
	Weapon_OnPrecache();
	
	g_iszWeaponKey = engfunc(EngFunc_AllocString, WEAPON_NAME);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_message(get_user_msgid("CurWeapon"),    		"Message_CurWeapon");
	register_message(get_user_msgid("DeathMsg"), 			"Message_DeathMsg")
	
	register_forward(FM_SetModel,					"FakeMeta_SetModel",			false);
	register_forward(FM_UpdateClientData,				"FakeMeta_UpdateClientData_Post",	true);
	register_forward(FM_Touch, 					"FakeMeta_Touch",			false);
	register_forward(FM_Think, 					"FakeMeta_Think",			false);
	
	RegisterHam(Ham_Spawn, 			"weaponbox", 	  	"HamHook_Weaponbox_Spawn_Post", 	true);
	RegisterHam(Ham_Item_Deploy,		WEAPON_REFERANCE, 	"HamHook_Item_Deploy_Post",		true);
	RegisterHam(Ham_Item_Holster,		WEAPON_REFERANCE, 	"HamHook_Item_Holster",			false);
	RegisterHam(Ham_Item_AddToPlayer,	WEAPON_REFERANCE, 	"HamHook_Item_AddToPlayer",		false);
	RegisterHam(Ham_Item_PostFrame,		WEAPON_REFERANCE, 	"HamHook_Item_PostFrame",		false);

	RegisterHam(Ham_Weapon_WeaponIdle,	WEAPON_REFERANCE, 	"HamHook_Item_WeaponIdle",		false);
	
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERANCE, 	"HamHook_Item_PrimaryAttack",		false);

	g_iItemID = zp_register_extra_item(ZP_ITEM_NAME, ZP_ITEM_COST, ZP_TEAM_HUMAN);
}
public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_iItemID)
	{
		Weapon_Give(id);
	}
}

public Message_CurWeapon(iMsgid, iMsgdest, iPlayer)
{
	static iItem;
	
	if (!CheckItem2(iPlayer, iItem))
	{
		return PLUGIN_CONTINUE;
	}
	
	if (get_msg_arg_int(2) != CSW_M249)
	{
		return PLUGIN_CONTINUE;
	}

	set_msg_arg_int(3, ARG_BYTE, -1);
	
	return PLUGIN_CONTINUE;
}

public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	static iItem;	

	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
	
	if(get_user_weapon(iAttacker) == CSW_M249)
	{
		if(CheckItem2(iAttacker, iItem))
		{
			set_msg_arg_string(4, "cannon_6")
			//zp_set_user_ammo_packs(iAttacker, zp_get_user_ammo_packs(iAttacker) - 100)
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

public FakeMeta_Touch(const iEnt, const iOther)
{
	if(!pev_valid(iEnt))
	{
		return FMRES_IGNORED;
	}
	
	static Classname[32];pev(iEnt, pev_classname, Classname, sizeof(Classname));
	static Float:Origin[3];pev(iEnt, pev_origin, Origin);
	static iAttacker; 
	
	if (equal(Classname, BALL_CLASSNAME))
	{
		if (pev(iEnt, pev_fuser2) < get_gametime())
		{
			static Float:eOrigin[3];pev(iEnt, pev_origin, eOrigin);
			
			iAttacker = pev(iEnt, pev_owner);

			if (!is_user_connected(iAttacker))
			{
				set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
				return FMRES_IGNORED;
			}
			
			static Float:vOrigin[3];pev(iOther, pev_origin, vOrigin);
				
			if (is_user_alive(iOther))
			{
				if (zp_get_user_zombie(iOther))
				{
					Create_Blood(vOrigin, iBlood[0], iBlood[1], 248, random_num(8,15));
					
					static Float:vecViewAngle[3]; pev(iAttacker, pev_v_angle, vecViewAngle);
					static Float:vecForward[3]; angle_vector(vecViewAngle, ANGLEVECTOR_FORWARD, vecForward);

					FakeKnockBack(iOther, vecForward, WEAPON_KNOCKBACK);
					
					//ExecuteHamB(Ham_TakeDamage, iOther, iAttacker, iAttacker, random_float(WEAPON_DAMAGE-10,WEAPON_DAMAGE+10), DMG_BULLET)	
					//ExecuteHam(Ham_TakeDamage, iOther, iAttacker, iAttacker, WEAPON_DAMAGE, DMG_BURN);
				}
			}
			set_pev(iEnt, pev_fuser2, get_gametime() + 0.25);
		}
	}
	
	if (equal(Classname, MISSILE_CLASSNAME))
	{
		CreateExplosion(Origin, iBlood[4], 2.3, random_float(2.6,3.0), TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES);
		engfunc(EngFunc_EmitSound, iEnt, CHAN_BODY, SOUND_DRAGON_EXP, 1.0, ATTN_NORM, 0, PITCH_NORM);
		
		iAttacker = pev(iEnt, pev_owner);

		new pNull = FM_NULLENT;
			
		while((pNull = fm_find_ent_in_sphere(pNull, Origin, WEAPON_RADIUS_EXP)) != 0)
		{	
			new Float:vOrigin[3];pev(pNull, pev_origin, vOrigin);
				
			if (IsValidPev(pNull) && pev(pNull, pev_takedamage) != DAMAGE_NO && pev(pNull, pev_solid) != SOLID_NOT)
			{
				if (is_user_connected(pNull))
				{
					if (zp_get_user_zombie(pNull))
					{
						new Float:vOrigin[3], Float:dist, Float:damage;pev(pNull, pev_origin, vOrigin);
							
						Create_Blood(vOrigin, iBlood[0], iBlood[1], 76, 13);
		
						dist = get_distance_f(Origin, vOrigin);damage = WEAPON_DAMAGE_EXP - (WEAPON_DAMAGE_EXP/WEAPON_DAMAGE_EXP) * dist;
						if (damage > 0.0)
						{
							damage = is_deadlyshot(iAttacker)?random_float(damage-10,damage+10)*1.5:random_float(damage-10,damage+10)
							ExecuteHamB(Ham_TakeDamage, pNull, iAttacker, iAttacker, damage, DMG_BULLET)
							
						}
					}
				}
			}
		}
		
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}
new Float:Damage[33]
public FakeMeta_Think(const iEnt)
{
	if (!pev_valid(iEnt))
	{
		return FMRES_IGNORED;
	}
	
	static Classname[32];pev(iEnt, pev_classname, Classname, sizeof(Classname));
	
	if (equal(Classname, BALL_CLASSNAME))
	{
		static Float:iFrame;pev(iEnt, pev_frame, iFrame);
		static Float:iScale;pev(iEnt, pev_scale, iScale);
		
		if (pev(iEnt, pev_movetype) == MOVETYPE_NONE)
		{
			iFrame += 0.82;
			iScale += 0.065;
			
			if (iFrame > 21.0)
			{ 
				set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
				return FMRES_IGNORED;
			}
		}
		else
		{
			iFrame += 1.0;
			iScale += 0.07;
			
			if (iFrame >= 21.0)
			{
				set_pev (iEnt, pev_movetype, MOVETYPE_NONE);
			}
		}
		
		set_pev(iEnt, pev_scale, iScale);
		set_pev(iEnt, pev_frame, iFrame);
		
		static Float:fDamage, Float:vecOrigin[3]; 
		pev(iEnt, pev_origin, vecOrigin)
		new iOwner,iVictim;
		iOwner = pev(iEnt, pev_owner);
		
		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, 40.0)) > 0)
		{
			if(pev(iVictim, pev_takedamage) == DAMAGE_NO) continue;
			if(is_user_alive(iVictim))
			{
				if(iVictim == iOwner || !zp_get_user_zombie(iVictim))
					continue;
			}
			if(is_user_alive(iVictim))
			{
				set_pdata_int(iVictim, 75, HIT_GENERIC, 5);
				//zp_set_user_ammo_packs(iOwner, zp_get_user_ammo_packs(iOwner)-3)
			}	
			fDamage = is_deadlyshot(iOwner)?random_float(WEAPON_DAMAGE-20,WEAPON_DAMAGE-10)+1.5:random_float(WEAPON_DAMAGE-20,WEAPON_DAMAGE-10)
			
			new Float:multi
			if(is_user_bot(iOwner))
				multi=get_cvar_float("zp_human_damage_reward")*2
			else multi = get_cvar_float("zp_human_damage_reward")
			
			static health
			health = pev(iVictim, pev_health)
			
			if (health - floatround(fDamage, floatround_ceil) > 0)
			{	
				fm_set_user_health(iVictim, health - floatround(fDamage, floatround_ceil))
				Damage[iOwner]+=fDamage
				
			}
			else ExecuteHam(Ham_TakeDamage, iVictim, iOwner, iOwner, 10.0, DMG_BULLET)
			
			if(Damage[iOwner]>= 100.0)
			{
				zp_set_user_ammo_packs(iOwner, zp_get_user_ammo_packs(iOwner) + floatround(Damage[iOwner] * multi * 0.5))
				Damage[iOwner]=0.0
			}
		}		
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.04);
	}

	else if (equal(Classname, MISSILE_CLASSNAME))
	{
		static Float:Origin[3];pev(iEnt, pev_origin, Origin);
		CreateExplosion(Origin, pev(pev(iEnt,pev_iuser3), pev_iuser4)?iBlood[3]:iBlood[2], 1.1, 8.0, TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES);
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.1);
	}
	return FMRES_IGNORED;
}

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
	static iState;pev(iItem, pev_iuser1, iState);
	static Float:iTime;pev(iItem, pev_fuser1, iTime);

	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	if ((iButton = pev(iPlayer, pev_button)) & IN_ATTACK2 && get_pdata_float(iItem, m_flNextSecondaryAttack, extra_offset_weapon) <= 0.0)
	{
		_call.SecondaryAttack(iItem, iPlayer);
		set_pev(iPlayer, pev_button, iButton & ~IN_ATTACK2);
	}
	
	if (iState && iTime < get_gametime())
	{
		Weapon_OnShoot(iItem, iPlayer, true);

		return HAM_IGNORED;
	}
 	return HAM_IGNORED;
}		

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
	
	new num = random_num(0,1);

	set_pev(iWeapon, pev_iuser4, num)
	MDLL_Spawn(iWeapon);
	SET_ORIGIN(iWeapon, vecOrigin);
	
	set_pdata_int(iWeapon, m_iClip, WEAPON_MAX_CLIP, extra_offset_weapon);

	set_pev(iWeapon, pev_impulse, g_iszWeaponKey);
	set_pev(iWeapon, pev_angles, vecAngles);
	
	Weapon_OnSpawn(iWeapon);
	
	return iWeapon;
}

public Weapon_Give(const iPlayer)
{
	if (!IsValidPev(iPlayer))
	{
		return FM_NULLENT;
	}
	
	new iWeapon, Float: vecOrigin[3];
	pev(iPlayer, pev_origin, vecOrigin);
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

stock Sprite_SetTransparency(const iSprite, const iRendermode, const Float: vecColor[3], const Float: flAmt, const iFx = kRenderFxClampMinScale)//kRenderFxNone)
{
	set_pev(iSprite, pev_rendermode, iRendermode);
	set_pev(iSprite, pev_rendercolor, vecColor);
	set_pev(iSprite, pev_renderamt, flAmt);
	set_pev(iSprite, pev_renderfx, iFx);
}

stock Punchangle(iPlayer, Float:iVecx = 0.0, Float:iVecy = 0.0, Float:iVecz = 0.0)
{
	static Float:iVec[3];pev(iPlayer, pev_punchangle,iVec);
	iVec[0] = iVecx;iVec[1] = iVecy;iVec[2] = iVecz
	set_pev(iPlayer, pev_punchangle, iVec);
}

stock Get_Position(id,Float:forw, Float:right, Float:up, Float:vStart[]) 
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3];
	
	pev(id, pev_origin, vOrigin);
	pev(id, pev_view_ofs, vUp);
	
	xs_vec_add(vOrigin, vUp, vOrigin);
	
	pev(id, pev_v_angle, vAngle);
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward);
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight);
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp);
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up;
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up;
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up;
}

stock Stock_Get_Speed_Vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
}

stock FakeKnockBack(iPlayer, Float: vecDirection[3], Float:flKnockBack)
{
	static Float:vecVelocity[3]; pev(iPlayer, pev_velocity, vecVelocity);
	
	if (pev(iPlayer, pev_flags) & FL_DUCKING)
	{
		flKnockBack *= 0.7;
	}
	
	vecVelocity[0] = vecDirection[0] * 500.0 * flKnockBack;
	vecVelocity[1] = vecDirection[1] * 500.0 * flKnockBack;
	vecVelocity[2] = 100.0;
	
	set_pev(iPlayer, pev_velocity, vecVelocity);
}

stock Create_Blood(const Float:vStart[3], const iModel, const iModel2, const iColor, const iScale)
{
	new pos[3];
	pos[0] = floatround(vStart[0])
	pos[1] = floatround(vStart[1])
	pos[2] = floatround(vStart[2])
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, pos, 0);
	write_byte(TE_BLOODSPRITE);
	write_coord(pos[0])
	write_coord(pos[1])
	write_coord(pos[2])
	write_short(iModel);
	write_short(iModel2);
	write_byte(iColor);
	write_byte(iScale);
	message_end();
}

stock Player_SetAnimation(const iPlayer, const szAnim[])
{
	if(!is_user_alive(iPlayer))
		return;
		
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

stock Weapon_DefaultDeploy(const iPlayer, const szViewModel[], const szWeaponModel[], const iAnim, const szAnimExt[])
{
	set_pev(iPlayer, pev_viewmodel2, szViewModel);
	set_pev(iPlayer, pev_weaponmodel2, szWeaponModel);
	set_pev(iPlayer, pev_fov, 90.0);
	
	set_pdata_int(iPlayer, m_iFOV, 90, extra_offset_player);
	set_pdata_int(iPlayer, m_fResumeZoom, 0, extra_offset_player);
	set_pdata_int(iPlayer, m_iLastZoom, 90, extra_offset_player);
	
	set_pdata_string(iPlayer, m_szAnimExtention * 4, szAnimExt, -1, extra_offset_player * 4);

	Weapon_SendAnim(iPlayer, iAnim);
}

public client_putinserver(id)
{
	BitSet(g_bitIsConnected, id);
}

public client_disconnect(id)
{
	BitClear(g_bitIsConnected, id);
}

bool: CheckItem2(const iPlayer, &iItem)
{
	if (!BitCheck(g_bitIsConnected, iPlayer) || !IsValidPev(iPlayer))
	{
		return false;
	}
	
	iItem = get_pdata_cbase(iPlayer, m_pActiveItem, extra_offset_player);
	
	if (!IsValidPev(iItem) || !IsCustomItem(iItem))
	{
		return false;
	}
	
	return true;
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
	if (!IsValidPev(iItem) || !IsValidPev(iPlayer))
	{
		return HAM_IGNORED;
	}
	
	SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iItem), pev(iItem, pev_iuser2));
	
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

stock Get_Speed_Vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
}

stock CreateExplosion(Float:vecOrigin[3], const szSprite, Float:fScale, Float:fFramerate, iFlags)
{
	new iScale = floatround(fScale * 10.0);
	new iFramerate = floatround(fFramerate * 10.0);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(szSprite);
	write_byte(iScale);
	write_byte(iFramerate);
	write_byte(iFlags);
	message_end();
}