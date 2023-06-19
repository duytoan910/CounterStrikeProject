#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN 					"[ZP] Extra: Heaven Splitter"
#define VERSION 				"1.0"
#define AUTHOR 					"KORD_12.7/PeTRoX"

#pragma ctrlchar '\'
#pragma compress 				1

#define WEAPON_KEY				23032020
#define WEAPON_NAME 				"weapon_wondercannon"

#define WEAPON_REFERANCE			"weapon_ak47"
#define WEAPON_MAX_CLIP				30
#define WEAPON_DEFAULT_AMMO			60
#define Accuracy				0.01

#define WEAPON_TIME_NEXT_IDLE 			10.0
#define WEAPON_TIME_NEXT_ATTACK 		0.6
#define WEAPON_TIME_NEXT_ATTACK_B 		1.0 
#define WEAPON_TIME_DELAY_DEPLOY 		1.0
#define WEAPON_TIME_DELAY_RELOAD 		2.0

#define MINE_RADIUS_EXPLODE			200.0
#define MINE_DAMAGE_EXPLODE			random_float(600.0, 900.0)

#define ANIM_CHANGE_TO_DEF_TIME			1.5
#define ANIM_CHANGE_TO_EX_TIME 			0.75

#define WEAPON_DAMAGE  	  			1.5
#define WEAPON_BALL_RADIUS_EXP			200.0 

#define SPEED_OWNER_FORWARD			800.0
#define SPEED_OWNER_UP				500.0

#define FIRE_DURATION				4
#define FIRE_DAMAGE				random_float(15.0,25.0)
#define TASK_FBURN				122
#define ID_FBURN                        	( taskid - TASK_FBURN )
#define ZP_ITEM_NAME				"Heaven Splitter" 
#define ZP_ITEM_COST				15000

#define MODEL_WORLD				"models/w_wondercannon.mdl"
#define MODEL_VIEW				"models/v_wondercannon.mdl"
#define MODEL_PLAYER				"models/p_wondercannon.mdl"
#define MODEL_GRENADE				"models/bomb_wondercannon.mdl"
#define MODEL_AREA				"models/ef_wondercannon_area.mdl"

#define SOUND_FIRE				"weapons/wondercannon_shoot1.wav"
#define SOUND_FIRE_B				"weapons/wondercannon_shoot2.wav"
#define SOUND_FIRE_EXP				"weapons/wondercannon_comd_exp.wav"
#define SOUND_FIRE_EXP_FOR_PLAYERS1		"weapons/wondercannon_bomd_exp.wav"
#define SOUND_BOMB_DROP				"weapons/wondercannon_comd_drop.wav"

#define WEAPON_HUD_TXT				"sprites/weapon_wondercannon.txt"
#define WEAPON_HUD_SPR_1			"sprites/640hud193.spr"
#define WEAPON_HUD_SPR_2			"sprites/640hud38.spr"

#define ANIM_EXTENSION				"rifle"
#define WONDER_AREA				"WonderCannon_area"
#define WONDER_BOMB				"WonderCannon_bomb"

#define MDLL_Touch(%0,%1)			dllfunc(DLLFunc_Touch, %0, %1)
#define MDLL_Spawn(%0)				dllfunc(DLLFunc_Spawn, %0)
#define BitSet(%0,%1) 				(%0 |= (1 << (%1 - 1)))
#define BitClear(%0,%1)				(%0 &= ~(1 << (%1 - 1)))
#define BitCheck(%0,%1) 			(%0 & (1 << (%1 - 1)))

#define extra_offset_weapon		4
#define extra_offset_player		5

#define MAX_CLIENTS			32

#define WEAPONSTATE_MODE	(1<<7)

#define m_fInSuperBullets		30
#define m_rgpPlayerItems_CWeaponBox	34
#define m_flLastEventCheck 		38
#define m_fInCheckShoots		39
#define m_pPlayer			41
#define m_pNext 			42
#define m_fFireOnEmpty 			45
#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack		47
#define m_flTimeWeaponIdle		48
#define m_iPrimaryAmmoType		49
#define m_iClip				51
#define m_fInReload			54
#define m_iDirection			60
#define m_flAccuracy 			62
#define m_iShotsFired			64
#define m_iWeaponState			74 
#define m_LastHitGroup 			75
#define m_flNextAttack			83
#define m_flVelocityModifier 		108 
#define m_iLastZoom 			109
#define m_fResumeZoom       		110
#define m_iTeam				114
#define m_iFOV				363
#define m_rgpPlayerItems_CBasePlayer	367
#define m_pActiveItem			373
#define m_rgAmmo_CBasePlayer		376
#define m_szAnimExtention		492

#define IsValidPev(%0) 			(pev_valid(%0) == 2)

#define INSTANCE(%0)			((%0 == -1) ? 0 : %0)

#define IsCustomItem(%0) 		(pev(%0, pev_impulse) == WEAPON_KEY)

new iBlood[10], g_burning_duration[ MAX_CLIENTS + 1 ], g_bitIsConnected, g_iszAllocString_InfoTarget,g_iszAllocString_AreaClass,g_iszAllocString_BombClass;
new g_Ham_Bot
Weapon_OnPrecache()
{
	precache_model(MODEL_VIEW);
	precache_model(MODEL_PLAYER);
	precache_model(MODEL_WORLD);
	//PRECACHE_SOUNDS_FROM_MODEL(MODEL_VIEW);
	precache_model(MODEL_GRENADE);
	precache_sound(SOUND_FIRE);
	precache_sound(SOUND_FIRE_B);
	precache_sound(SOUND_FIRE_EXP);
	precache_sound(SOUND_FIRE_EXP_FOR_PLAYERS1);
	precache_sound(SOUND_BOMB_DROP);
	
	precache_generic(WEAPON_HUD_SPR_1);
	precache_generic(WEAPON_HUD_SPR_2);
	
	iBlood[0] = precache_model("sprites/bloodspray.spr");
	iBlood[1] = precache_model("sprites/blood.spr");
	iBlood[2] = precache_model("sprites/ef_wondercannon_hit3.spr");
	iBlood[3] = precache_model("sprites/smoke.spr");
	iBlood[4] = precache_model("sprites/ef_wondercannon_hit4.spr");
	iBlood[5] = precache_model("sprites/ef_wondercannon_hit1.spr");
	iBlood[6] = precache_model("sprites/ef_wondercannon_hit2.spr");
	iBlood[7] = precache_model("sprites/ef_wondercannon_bomb_set.spr");	
	iBlood[8] = precache_model("sprites/ef_wondercannon_bomb_ex.spr");
	iBlood[9] = precache_model("sprites/ef_wondercannon_chain.spr");
	precache_model(MODEL_AREA);
	g_iszAllocString_InfoTarget = engfunc(EngFunc_AllocString, "info_target");
	g_iszAllocString_AreaClass = engfunc(EngFunc_AllocString, WONDER_AREA);
	g_iszAllocString_BombClass = engfunc(EngFunc_AllocString, WONDER_BOMB);
	
}

Weapon_OnSpawn(const iItem)
{
	engfunc(EngFunc_SetModel, iItem, MODEL_WORLD);
}

Weapon_OnDeploy(const iItem, const iPlayer, const iClip, const iShoots, const iCheckShoots, const iAmmoPrimary)

{
	#pragma unused iClip, iCheckShoots, iAmmoPrimary
	static iszViewModel, bitsWeaponState;
	if (iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, MODEL_VIEW)))
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

	Weapon_DefaultDeploy(iPlayer, MODEL_VIEW, MODEL_PLAYER, 2, ANIM_EXTENSION);
	SetExtraAmmo(iPlayer, iShoots);
	MsgHook_WeaponList(iItem, iPlayer, 1, iShoots);
	set_pdata_float(iItem, m_flLastEventCheck, get_gametime() + 0.2, extra_offset_weapon);
	bitsWeaponState = get_pdata_int(iItem, m_iWeaponState, extra_offset_weapon)
	if (bitsWeaponState & WEAPONSTATE_MODE) 
	{
		bitsWeaponState &= ~WEAPONSTATE_MODE;
	}
	set_pdata_int(iItem, m_iWeaponState, bitsWeaponState, extra_offset_weapon);
	set_pev(iPlayer, pev_body, 1);
}

Weapon_OnHolster(const iItem, const iPlayer, const iClip, const iShoots, const iCheckShoots, const iAmmoPrimary)
{
	#pragma unused iPlayer, iClip, iCheckShoots, iAmmoPrimary
	
	set_pdata_int(iItem, m_fInCheckShoots, 0, extra_offset_weapon);
	set_pdata_int(iItem, m_fInReload, 0, extra_offset_weapon);
	if(!user_has_weapon(iPlayer,28,-1))
	{	
		SetExtraAmmo(iPlayer, 0);
		MsgHook_WeaponList(iItem, iPlayer, -1, iShoots);
	}
}

Weapon_OnIdle(const iItem, const iPlayer, const iClip, const iShoots, const iCheckShoots, const iAmmoPrimary)
{
	#pragma unused iClip, iAmmoPrimary, iCheckShoots, iShoots

	ExecuteHamB(Ham_Weapon_ResetEmptySound, iItem);
	
	if (get_pdata_float(iItem, m_flTimeWeaponIdle, extra_offset_weapon) > 0.0)
	{
		return;
	}
	
	if (get_pdata_int(iItem, m_iWeaponState, extra_offset_weapon) & WEAPONSTATE_MODE) 
	{
		Weapon_SendAnim(iPlayer, 8);
	}
	else 
	{
		Weapon_SendAnim(iPlayer, 0);
	}
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_IDLE, extra_offset_weapon);	
}
Weapon_OnReload(const iItem, const iPlayer, const iClip, const iShoots, const iCheckShoots, const iAmmoPrimary)
{
	#pragma unused iCheckShoots, iAmmoPrimary, iShoots
	
	if (min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary) <= 0)
	{
		return;
	}
	
	set_pdata_int(iItem, m_iClip, 0, extra_offset_weapon);
	
	ExecuteHam(Ham_Weapon_Reload, iItem);
	
	set_pdata_int(iItem, m_iClip, iClip, extra_offset_weapon);
	
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_TIME_DELAY_RELOAD, extra_offset_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_DELAY_RELOAD, extra_offset_weapon);
	
	Weapon_SendAnim(iPlayer, 1);
}
Weapon_OnPrimaryAttack(const iItem, const iPlayer, const iClip, const iShoots, const iCheckShoots, const iAmmoPrimary)
{
	#pragma unused iAmmoPrimary, iCheckShoots
	
	if (iClip <= 0)
	{
		if (get_pdata_int(iItem, m_fFireOnEmpty, extra_offset_player))
		{
			ExecuteHamB(Ham_Weapon_PlayEmptySound, iItem);
			set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, extra_offset_weapon);
		}
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

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_TIME_NEXT_ATTACK, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_TIME_NEXT_ATTACK, extra_offset_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_ATTACK + 0.6, extra_offset_weapon);
	
	if (get_pdata_int(iItem, m_iWeaponState, extra_offset_weapon) & WEAPONSTATE_MODE) 
	{
		if (!iShoots)
		{
			if (get_pdata_int(iItem, m_fFireOnEmpty, extra_offset_player))
			{
				ExecuteHamB(Ham_Weapon_PlayEmptySound, iItem);
				set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, extra_offset_weapon);
			}
		
			return;
		}
		emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE_B,  VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		Weapon_SendAnim(iPlayer, 9);
		set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_TIME_NEXT_ATTACK+ 0.6, extra_offset_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_TIME_NEXT_ATTACK+ 0.6, extra_offset_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_ATTACK + 0.6, extra_offset_weapon);
		FireGrenade( iPlayer )
		set_pdata_int(iItem, m_fInSuperBullets, (iShoots-1), extra_offset_weapon);
		SetExtraAmmo(iPlayer, iShoots-1);
		static bitsWeaponState;bitsWeaponState = get_pdata_int(iItem, m_iWeaponState, extra_offset_weapon)
		if(get_pdata_float(iItem, m_flNextPrimaryAttack, extra_offset_weapon) > 0.0)
		{
			if (bitsWeaponState & WEAPONSTATE_MODE) 
			{
				bitsWeaponState &= ~WEAPONSTATE_MODE;
			}
			set_pdata_int(iItem, m_iWeaponState, bitsWeaponState, extra_offset_weapon);
		}
	}
	else {
		Punchangle(iPlayer, .iVecx = random_float(-0.5,-0.8), .iVecy = random_float(-0.5,0.5), .iVecz = 0.0);
		ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);
		emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		Weapon_SendAnim(iPlayer, 3);
		set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_TIME_NEXT_ATTACK, extra_offset_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_TIME_NEXT_ATTACK, extra_offset_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_ATTACK + 0.6, extra_offset_weapon);
		set_pdata_float(iItem,m_flAccuracy,Accuracy,extra_offset_weapon)
	}

}

new g_iItemID,g_Event_Base;
public plugin_precache()
{
	Weapon_OnPrecache();
	register_clcmd(WEAPON_NAME, "Cmd_WeaponSelect");
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_logevent("NewRound", 2, "1=Round_Start")
	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	register_forward(FM_UpdateClientData,				"FakeMeta_UpdateClientData_Post",	true);
	register_forward(FM_SetModel,					"FakeMeta_SetModel",			false);
	
	RegisterHam(Ham_Think, 			"info_target",		"HamHook_Think", false);
	RegisterHam(Ham_Touch, 			"info_target",		"HamHook_Touch", false);
	RegisterHam(Ham_Item_Deploy,		WEAPON_REFERANCE, 	"HamHook_Item_Deploy_Post",	true);
	RegisterHam(Ham_Item_Holster,		WEAPON_REFERANCE, 	"HamHook_Item_Holster",		false);
	RegisterHam(Ham_Item_AddToPlayer,	WEAPON_REFERANCE, 	"HamHook_Item_AddToPlayer",	false);
	RegisterHam(Ham_Item_PostFrame,		WEAPON_REFERANCE, 	"HamHook_Item_PostFrame",	false);
	
	RegisterHam(Ham_Weapon_Reload,		WEAPON_REFERANCE, 	"HamHook_Item_Reload",		false);
	RegisterHam(Ham_Weapon_WeaponIdle,	WEAPON_REFERANCE, 	"HamHook_Item_WeaponIdle",	false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERANCE, 	"HamHook_Item_PrimaryAttack",	false);
	
	RegisterHam(Ham_TraceAttack,"worldspawn","fw_TraceAttack",1);
	RegisterHam(Ham_TraceAttack,"func_breakable","fw_TraceAttack",1);
	RegisterHam(Ham_TraceAttack,"func_wall","fw_TraceAttack",1);
	RegisterHam(Ham_TraceAttack,"func_door","fw_TraceAttack", 1);
	RegisterHam(Ham_TraceAttack,"func_door_rotating","fw_TraceAttack",1);
	RegisterHam(Ham_TraceAttack,"func_plat","fw_TraceAttack",1);
	RegisterHam(Ham_TraceAttack,"func_rotating","fw_TraceAttack",1);
	RegisterHam(Ham_TraceAttack,"player","fw_TraceAttack",1);
	RegisterHam(Ham_TakeDamage,"player","CEntity__TraceAttack_Pre",0);

	g_iItemID = zp_register_extra_item(	ZP_ITEM_NAME, 		ZP_ITEM_COST, 			ZP_TEAM_HUMAN, 1);
}


public Do_RegisterHam_Bot(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack",1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "CEntity__TraceAttack_Pre")
}
public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal("events/ak47.sc", name)) g_Event_Base = get_orig_retval()		
}
public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return;

	static item; item = get_pdata_cbase(iAttacker, m_pActiveItem)
	if (!CheckItem(item, iAttacker))
	{
		return;
	}
	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	if(!iEnt)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_GUNSHOTDECAL);
		engfunc(EngFunc_WriteCoord,flEnd[0]);
		engfunc(EngFunc_WriteCoord,flEnd[1]);
		engfunc(EngFunc_WriteCoord,flEnd[2]);
		write_short(iEnt);
		write_byte(random_num(41,45));
		message_end();
	}	
	if(is_user_connected(iEnt)&&zp_get_user_zombie(iEnt))
	{ 	
		static iVictim;iVictim = FM_NULLENT;
		while((iVictim = fm_find_ent_in_sphere(iVictim,flEnd, WEAPON_BALL_RADIUS_EXP)) != 0 )
		{
			if(is_user_connected(iVictim)&&zp_get_user_zombie(iVictim))
			{ 
				static iParams[2]; iParams[0] = iAttacker;
				set_task( 0.5, "CTask__BurningFlame", iVictim + TASK_FBURN, iParams, sizeof iParams, "b" );
				g_burning_duration[ iVictim ] += FIRE_DURATION	
				engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, iVictim, 0);
				write_byte(TE_EXPLOSION);
				engfunc(EngFunc_WriteCoord,flEnd[0]);
				engfunc(EngFunc_WriteCoord,flEnd[1]);
				engfunc(EngFunc_WriteCoord,flEnd[2]-16.0);
				write_short(iBlood[4]);
				write_byte(10);
				write_byte(15);
				write_byte(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES);
				message_end();
			}
		}
	}

}	
public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_iItemID)
	{
		static iShoots; iShoots = get_pdata_int(id, m_fInSuperBullets, extra_offset_weapon)
		Weapon_Give(id, iShoots);
	}
}
public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		kemaric(id)
	}
}
public plugin_natives()
{ 
	register_native("weapon_wc", "NativeGiveWeapon", true); 
}

public NativeGiveWeapon(iPlayer)
{
	static iShoots; iShoots = get_pdata_int(iPlayer, m_fInSuperBullets, extra_offset_weapon)
	Weapon_Give(iPlayer, iShoots);
}
public FireGrenade(iPlayer)
{
	if (!is_user_alive(iPlayer))
	{
		return FMRES_IGNORED;
	}
	
	static iItem;iItem = get_pdata_cbase(iPlayer, m_pActiveItem, extra_offset_player);
	
	if (!IsValidPev(iItem) || !IsCustomItem(iItem))
	{
		return FMRES_IGNORED;
	}
	
			
	static pEntity,Float:vStart[3],Float:vEnd[3];
	vStart[0]+=random_float(-0.1,0.1)
	vStart[1]+=random_float(-0.1,0.1)
	vStart[2]+=random_float(-0.1,0.1)
	fm_get_aim_origin(iPlayer, vEnd);
	GetPosition(iPlayer, 20.0, 0.0, -5.0, vStart);
		
	pEntity = fm_create_entity("info_target")
	if (pev_valid(pEntity))
	{
	
		engfunc(EngFunc_SetModel, pEntity, MODEL_GRENADE);
		engfunc(EngFunc_SetOrigin, pEntity, vStart);		
		static Float:Angles[3]
		pev(pEntity, pev_angles, Angles)

		set_pev_string(pEntity, pev_classname, g_iszAllocString_BombClass);
		set_pev(pEntity, pev_owner, iPlayer);
		set_pev(pEntity, pev_angles, Angles)
		set_pev(pEntity, pev_gravity, 0.6);
		set_pev(pEntity, pev_solid, SOLID_TRIGGER);
		set_pev(pEntity, pev_movetype, MOVETYPE_TOSS);
		set_pev(pEntity, pev_sequence, 0);
		set_pev(pEntity, pev_framerate, 0.0);
		set_pev(pEntity, pev_frame, 0.0);
		set_pev(pEntity, pev_animtime, 0.0)
		static Float:iVelocity[3];get_speed_vector(vStart, vEnd, 1000.0, iVelocity);
		set_pev(pEntity, pev_velocity, iVelocity);
		
		
	}
	return FMRES_IGNORED;
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
public Spawn_area(iEntity)
{
	if(!pev_valid(iEntity)) {return HAM_IGNORED;}

	static iOwner; iOwner = pev(iEntity, pev_owner)
	static Float:Origin[3];pev(iEntity, pev_origin, Origin);
	if(pev_valid(iEntity)) 
	{
		static pEntity;pEntity = engfunc(EngFunc_CreateNamedEntity, g_iszAllocString_InfoTarget);
		static Float:Angles[3]
		pev(iEntity, pev_angles, Angles)
						
		engfunc(EngFunc_SetModel, pEntity, MODEL_AREA);
		engfunc(EngFunc_SetOrigin, pEntity, Origin);
		
		set_pev_string(pEntity, pev_classname, g_iszAllocString_AreaClass);
		set_pev(pEntity, pev_owner, iOwner);
		set_pev(pEntity, pev_angles, Angles)
		set_pev(pEntity, pev_framerate, 0.5);
		set_pev(pEntity, pev_sequence, 0);
		set_pev(pEntity, pev_animtime, get_gametime());
		set_pev(pEntity, pev_rendermode, kRenderTransAdd);
		set_pev(pEntity, pev_renderamt, 128.0);												
		emit_sound(pEntity, CHAN_WEAPON, SOUND_BOMB_DROP, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, Origin, 0);

		write_byte(TE_SPRITE);
		engfunc(EngFunc_WriteCoord, Origin[0]);
		engfunc(EngFunc_WriteCoord, Origin[1]);
		engfunc(EngFunc_WriteCoord, Origin[2]+5.0);
		write_short(iBlood[7]);
		write_byte(3); 
		write_byte(255); 
		message_end();	
	}
	return HAM_IGNORED;
}
public HamHook_Think(iEntity)
{
	if(!pev_valid(iEntity)) {return HAM_IGNORED;}
	if(pev(iEntity, pev_classname) == g_iszAllocString_BombClass)
	{
		static Float: Origin[3]; pev(iEntity, pev_origin, Origin);
		static iVictim; iVictim = -1;
		if(engfunc(EngFunc_EntIsOnFloor, iEntity))
		{
			Spawn_area(iEntity)
		}
		if (is_user_alive(iVictim)&& zp_get_user_zombie(iVictim))
		{
			Create_ExplodeBomb(iEntity);
			
		}
	}
	return HAM_IGNORED;
}

public Create_ExplodeBomb(iEntity)
{
	static Float: Origin[3]; pev(iEntity, pev_origin, Origin);
	static iVictim;iVictim = FM_NULLENT;
	
	static iOwner; iOwner = pev(iEntity, pev_owner)
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, Origin, 200.0)) > 0)
	{
		if(is_user_alive(iVictim) && zp_get_user_zombie(iVictim))
		{
			set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, extra_offset_player)
			ExecuteHamB(Ham_TakeDamage, iVictim, iOwner, iOwner, MINE_DAMAGE_EXPLODE, DMG_BULLET);
			
			Sprite_exp1(iEntity, Origin)
		}	
	}
	emit_sound(iEntity, CHAN_WEAPON, SOUND_FIRE_EXP, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	static ent;ent = fm_find_ent_by_class(iEntity, WONDER_AREA);
	fm_remove_entity(ent);
	fm_remove_entity(iEntity);
	return HAM_IGNORED;
}
public kemaric(iPlayer)
{
	static ent,ent1
	ent = fm_find_ent_by_owner(ent, WONDER_BOMB, iPlayer);
	ent1 = fm_find_ent_by_owner(ent1, WONDER_AREA, iPlayer);
	if(!pev_valid(ent1)) {return HAM_IGNORED; }
	static iVictim;iVictim = FM_NULLENT;
	
	static iOwner; iOwner = pev(ent, pev_owner)	
	while (pev_valid(ent1))
	{
		static Float:Originw[3];pev(ent, pev_origin, Originw); 
		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, Originw, 200.0)) > 0)
		{
			if(is_user_alive(iVictim) && zp_get_user_zombie(iVictim))
			{
				Sprite_exp1(ent, Originw)
				set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, extra_offset_player)
				ExecuteHamB(Ham_TakeDamage, iVictim, iOwner, iOwner, MINE_DAMAGE_EXPLODE, DMG_BULLET);			
			}
	
		}	
		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, Originw, 200.0)) > 0)
		{	
			if(is_user_alive(iVictim) && !zp_get_user_zombie(iVictim))
			{
				Sprite_exp2(ent, Originw)
				if(iVictim != iOwner) {return HAM_IGNORED;}
				set_pdata_int(iOwner, m_LastHitGroup, HIT_GENERIC, extra_offset_player)
				new Float:flVictimOrigin [ 3 ]
				pev ( iOwner, pev_origin, flVictimOrigin )
				new Float:flDistance = get_distance_f ( Originw, flVictimOrigin )   
				if ( flDistance <= 200.0 )
				{
					static Float:flSpeed;
					flSpeed = SPEED_OWNER_FORWARD
					static Float:flNewSpeed;
					flNewSpeed = flSpeed * ( 1.0 - ( flDistance / 1000.0 ) )
					static Float:flVelocity [ 3 ]
					get_speed_vector ( Originw, flVictimOrigin, flNewSpeed, flVelocity )
					set_pev ( iOwner, pev_velocity,flVelocity )
				}
			}
		}
		if(!is_user_alive(iVictim))
		{
			Sprite_exp2(ent, Originw)			
		}
		fm_remove_entity(ent);
		fm_remove_entity(ent1);
		ent = fm_find_ent_by_owner(ent, WONDER_BOMB, iPlayer);
		ent1 = fm_find_ent_by_owner(ent1, WONDER_AREA, iPlayer);
	}
	return HAM_IGNORED;
}
stock set_speed( id, Float:speed )
{
	static Float:angles[3], Float:velocity[3];
	static Float:y, Float:x
	pev(id, pev_angles, angles);
	pev(id, pev_velocity, velocity);
	angle_vector(angles, 1, velocity);      
	y = velocity[0] * velocity[0] + 2 * velocity[1] * velocity[1];
	x = floatsqroot(speed * speed / y);
	velocity[0] *= x;
	velocity[1] *= x;
	set_pev(id, pev_velocity, velocity);

}
public HamHook_Touch(iEntity,iOther)
{
	if(!pev_valid(iEntity))
	{
		return HAM_IGNORED;
	}
	
	if(pev(iEntity, pev_classname) == g_iszAllocString_BombClass)
	{	

		static iOwner;iOwner = pev(iEntity, pev_owner);

		if(pev_valid(iOther) && !is_user_alive(iOther))
		{
			return HAM_IGNORED;
		}
		

		static Float:Origin[3];pev(iEntity, pev_origin, Origin); 
	
		if(engfunc(EngFunc_EntIsOnFloor, iEntity) && !is_user_alive(iOther))
		{
			set_pev(iEntity, pev_framerate, 0.5);
			set_pev(iEntity, pev_sequence, 0);
			set_pev(iEntity, pev_animtime, get_gametime());
			set_pev(iEntity, pev_nextthink, get_gametime() +0.3);
		
		}
		if(is_user_alive(iOther)&&zp_get_user_zombie(iOther))
		{
			
			Create_ExplodeBomb(iEntity);
			Sprite_exp1(iEntity,Origin)
		}
		
		if(is_user_alive(iOther) && iOther == iOwner)
		{
			Create_ExplodeBomb(iEntity);
			Sprite_exp2(iEntity, Origin)
			set_pdata_int(iOther, m_LastHitGroup, HIT_GENERIC, extra_offset_player)
			set_speed(iOther, SPEED_OWNER_FORWARD);
			static Float:velocity[3];
			pev(iOther,pev_velocity,velocity);
			velocity[2] = SPEED_OWNER_UP; 
			set_pev(iOther,pev_velocity,velocity);
			
		} 
	}
	
	return HAM_IGNORED;
}
public Sprite_exp1(iEntity, Float:Origin[3])
{

	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, Origin, 0);
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0]);
	engfunc(EngFunc_WriteCoord, Origin[1]);
	engfunc(EngFunc_WriteCoord, Origin[2]);
	write_short(iBlood[2])
	write_byte(10)
	write_byte(30)
	write_byte(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES)			
	message_end();	
}
public Sprite_exp2(iEntity, Float:Originw[3])
{
	new TE_FLAG
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	TE_FLAG |= TE_EXPLFLAG_NOSOUND

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION) // Temporary entity ID
	engfunc(EngFunc_WriteCoord, Originw[0]+=random_float(-10.0,10.0)) // engfunc because float
	engfunc(EngFunc_WriteCoord, Originw[1]+=random_float(-10.0,10.0))
	engfunc(EngFunc_WriteCoord, Originw[2]+=random_float(-10.0,10.0))
	write_short(iBlood[8]) // Sprite index
	write_byte(5) // Scale
	write_byte(20) // Framerate
	write_byte(TE_FLAG) // Flags
	message_end();
}
public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	

	if (!IsValidPev(invoker) || !IsCustomItem(invoker))
		return FMRES_IGNORED
	if(eventid != g_Event_Base)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)

	return FMRES_SUPERCEDE
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
		get_pdata_int(%1, m_fInSuperBullets, extra_offset_weapon), \
		get_pdata_int(iItem, m_fInCheckShoots, extra_offset_weapon), \
		GetAmmoInventory(%2, PrimaryAmmoIndex(%1))		\
	) 

public HamHook_Item_Deploy_Post(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_call.Deploy(iItem, iPlayer);

	return HAM_IGNORED;
}

public fw_Weapon_SecondaryAttack(iItem)
{
	if (get_pdata_float(iItem, m_flNextSecondaryAttack, extra_offset_weapon) > 0.0) { return HAM_IGNORED; }

	static iPlayer, bitsButtons, bitsWeaponState;
	iPlayer = get_pdata_cbase(iItem, m_pPlayer, extra_offset_weapon);
	bitsButtons = pev(iPlayer, pev_button);
	bitsWeaponState = get_pdata_int(iItem, m_iWeaponState, extra_offset_weapon);
	if (~bitsButtons & IN_ATTACK2) { return HAM_IGNORED; }
	static iShoots; iShoots = get_pdata_int(iItem, m_fInSuperBullets, extra_offset_weapon)

	if (iShoots == 0)
	{

		if((fm_find_ent_by_owner(-1, WONDER_BOMB, iPlayer)==0) || (fm_find_ent_by_owner(-1, WONDER_AREA, iPlayer)==0)) { return HAM_IGNORED;}
		bitsWeaponState &= ~WEAPONSTATE_MODE;
		set_pdata_int(iItem, m_iWeaponState, bitsWeaponState, extra_offset_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, ANIM_CHANGE_TO_DEF_TIME, extra_offset_weapon);
		set_pdata_float(iItem, m_flNextPrimaryAttack, ANIM_CHANGE_TO_DEF_TIME, extra_offset_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_CHANGE_TO_DEF_TIME, extra_offset_weapon);
		set_pdata_float(iPlayer, m_flNextAttack, ANIM_CHANGE_TO_DEF_TIME, extra_offset_player);
		Weapon_SendAnim(iPlayer, 6);
		kemaric(iPlayer)
	}
	if (bitsWeaponState & WEAPONSTATE_MODE) {
		bitsWeaponState &= ~WEAPONSTATE_MODE;
		set_pdata_int(iItem, m_iWeaponState, bitsWeaponState, extra_offset_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, ANIM_CHANGE_TO_DEF_TIME, extra_offset_weapon);
		set_pdata_float(iItem, m_flNextPrimaryAttack, ANIM_CHANGE_TO_DEF_TIME, extra_offset_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_CHANGE_TO_DEF_TIME, extra_offset_weapon);
		set_pdata_float(iPlayer, m_flNextAttack, ANIM_CHANGE_TO_DEF_TIME, extra_offset_player);
		Weapon_SendAnim(iPlayer, 6);
		kemaric(iPlayer)
	}
	else 
	{
		if (!iShoots) return HAM_IGNORED;
		bitsWeaponState |= WEAPONSTATE_MODE;
		set_pdata_float(iItem, m_flNextSecondaryAttack, ANIM_CHANGE_TO_EX_TIME, extra_offset_weapon);
		set_pdata_float(iItem, m_flNextPrimaryAttack, ANIM_CHANGE_TO_EX_TIME, extra_offset_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_CHANGE_TO_EX_TIME, extra_offset_weapon);
		set_pdata_float(iPlayer, m_flNextAttack, ANIM_CHANGE_TO_EX_TIME, extra_offset_player);
		Weapon_SendAnim(iPlayer, 7);
	}
	set_pdata_int(iItem, m_iWeaponState, bitsWeaponState, extra_offset_weapon);
	return HAM_IGNORED;
}

public HamHook_Item_Holster(const iItem)
{
	static iPlayer; 
	
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

public CEntity__TraceAttack_Pre(victim, inflictor, attacker, Float:DAMAGE)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		static iItem; iItem = get_pdata_cbase(attacker, m_pActiveItem, extra_offset_player);
		if(iItem <= 0 || !CheckItem(iItem, attacker)) return;
		SetHamParamFloat(4,DAMAGE*WEAPON_DAMAGE)		
	}
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
	static iPlayer;
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	fw_Weapon_SecondaryAttack(iItem);
	if (get_pdata_int(iItem, m_fInReload, extra_offset_weapon))
	{
		static iClip;iClip = get_pdata_int(iItem, m_iClip, extra_offset_weapon); 
		static iPrimaryAmmoIndex;iPrimaryAmmoIndex = PrimaryAmmoIndex(iItem);
		static iAmmoPrimary;iAmmoPrimary = GetAmmoInventory(iPlayer, iPrimaryAmmoIndex);
		static iAmount;iAmount= min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary);
		
		set_pdata_int(iItem, m_iClip, iClip + iAmount, extra_offset_weapon);
		set_pdata_int(iItem, m_fInReload, false, extra_offset_weapon);

		SetAmmoInventory(iPlayer, iPrimaryAmmoIndex, iAmmoPrimary - iAmount);
	}

	return HAM_IGNORED;
}	

public NewRound()
{
	fm_remove_entity_name(WONDER_BOMB)
	fm_remove_entity_name(WONDER_AREA)
}
Weapon_Create(const Float: vecOrigin[3] = {0.0, 0.0, 0.0}, const Float: vecAngles[3] = {0.0, 0.0, 0.0})
{
	static iWeapon,iszAllocStringCached; 
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, WEAPON_REFERANCE)))
	{
		iWeapon = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	
	if (!IsValidPev(iWeapon))
	{
		return FM_NULLENT;
	}
	
	MDLL_Spawn(iWeapon);
	fm_entity_set_origin(iWeapon,vecOrigin)
	set_pdata_int(iWeapon, m_iClip, WEAPON_MAX_CLIP, extra_offset_weapon);
	set_pdata_int(iWeapon, m_fInSuperBullets, 0, extra_offset_weapon);
	set_pdata_int(iWeapon, m_fInCheckShoots, 0, extra_offset_weapon);
	set_pev(iWeapon, pev_impulse, WEAPON_KEY);
	set_pev(iWeapon, pev_angles, vecAngles);
	
	Weapon_OnSpawn(iWeapon);
	
	return iWeapon;
}

Weapon_Give(const iPlayer, const iShoots)
{
	if (!IsValidPev(iPlayer))
	{
		return FM_NULLENT;
	}
	
	static iWeapon, Float: vecOrigin[3];
	pev(iPlayer, pev_origin, vecOrigin);
	
	if ((iWeapon = Weapon_Create(vecOrigin)) != FM_NULLENT)
	{
		Player_DropWeapons(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon));
		
		set_pev(iWeapon, pev_spawnflags, pev(iWeapon, pev_spawnflags) | SF_NORESPAWN);
		MDLL_Touch(iWeapon, iPlayer);
		
		set_pdata_int(iWeapon, m_fInSuperBullets, (iShoots+3), extra_offset_weapon);
		SetExtraAmmo(iPlayer, (iShoots+3));
		
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

public Weapon_SendAnim(const iPlayer, const iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
	return HAM_IGNORED
}

stock Weapon_DefaultDeploy(const iPlayer, const szViewModel[], const szWeaponModel[], const iAnim, const szAnimExt[])
{
	set_pev(iPlayer, pev_viewmodel2, szViewModel);
	set_pev(iPlayer, pev_weaponmodel2, szWeaponModel);
	
	set_pdata_int(iPlayer, m_iFOV, 90, extra_offset_player);
	set_pdata_int(iPlayer, m_fResumeZoom, 0, extra_offset_player);
	set_pdata_int(iPlayer, m_iLastZoom, 90, extra_offset_player);
	
	set_pdata_string(iPlayer, m_szAnimExtention * 4, szAnimExt, -1, extra_offset_player * 4);
	
	Weapon_SendAnim(iPlayer, iAnim);
}

stock Punchangle(iPlayer, Float:iVecx = 0.0, Float:iVecy = 0.0, Float:iVecz = 0.0)
{
	static Float:iVec[3];pev(iPlayer, pev_punchangle,iVec);
	iVec[0] = iVecx;iVec[1] = iVecy;iVec[2] = iVecz
	set_pev(iPlayer, pev_punchangle, iVec);
}

stock GetWeaponPosition(const iPlayer, Float: forw, Float: right, Float: up, Float: vStart[])
{
	static Float: vOrigin[3], Float: vAngle[3], Float: vForward[3], Float: vRight[3], Float: vUp[3];
	
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

public client_putinserver(id)
{
	BitSet(g_bitIsConnected, id);
	if(!g_Ham_Bot && is_user_bot(id))
	{
		g_Ham_Bot = 1
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
}
public client_disconnected(id)
{
	BitClear(g_bitIsConnected, id);
}

public Cmd_WeaponSelect(const iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERANCE);
	return PLUGIN_HANDLED;
}

public HamHook_Item_AddToPlayer(const iItem, const iPlayer, const iShoots)
{
	switch(pev(iItem, pev_impulse))
	{
		case 0: 
		{
			MsgHook_WeaponList(iItem, iPlayer, -1, 0);
		}
		case WEAPON_KEY: 
		{
			MsgHook_WeaponList(iItem, iPlayer, 1, iShoots);
			SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iItem), pev(iItem, pev_iuser2));
		}
	}
	
	return HAM_IGNORED;
}

public MsgHook_WeaponList(const iItem, const iPlayer, const iByte, const iShoots)
{	
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, iPlayer);
	write_string(IsCustomItem(iItem) ? WEAPON_NAME : WEAPON_REFERANCE);
	write_byte(2);
	write_byte(90);
	write_byte(iByte);
	write_byte(3);
	write_byte(0);
	write_byte(1);
	write_byte(CSW_AK47);
	write_byte(0);
	message_end();
}
public FakeMeta_SetModel(const iEntity)
{
	if (!IsValidPev(iEntity))
	{
		return FMRES_IGNORED;
	}
	static i, szClassName[32], iItem;
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	for (i = 0; i < 6; i++)
	{
		iItem = get_pdata_cbase(iEntity, m_rgpPlayerItems_CWeaponBox + i, extra_offset_weapon);
		
		if (IsValidPev(iItem) && IsCustomItem(iItem))
		{
			engfunc(EngFunc_SetModel, iEntity, MODEL_WORLD);
			set_pev(iEntity, pev_body, 1);
			set_pev(iItem, pev_iuser2, GetAmmoInventory(pev(iEntity,pev_owner), PrimaryAmmoIndex(iItem)))
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

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
stock SetExtraAmmo(const iPlayer, const iClip)
{
	message_begin(MSG_ONE, get_user_msgid("AmmoX"), _, iPlayer);
	write_byte(1);
	write_byte(iClip);
	message_end();
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


stock GetPosition(id,Float:forw, Float:right, Float:up, Float:vStart[]) 
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3];
	
	pev(id, pev_origin, vOrigin);
	pev(id, pev_view_ofs, vUp);
	
	vOrigin[0] = vOrigin[0] + vUp[0];
	vOrigin[1] = vOrigin[1] + vUp[1];
	vOrigin[2] = vOrigin[2] + vUp[2];
	
	pev(id, pev_v_angle, vAngle);
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward);
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight);
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp);
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up;
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up;
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up;
}



PRECACHE_SOUNDS_FROM_MODEL(const szModelPath[])
{
	new iFile;
	
	if ((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for (new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);

			for (k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if (iEvent != 5004)
				{
					continue;
				}

				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if (strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					precache_sound(szSoundPath);
				}
			}
		}
	}
	
	fclose(iFile);
}
public CTask__BurningFlame( szArgs[1], taskid )
{
	static pevAttacker,health,iVictim; pevAttacker = szArgs[0];
	iVictim = FM_NULLENT;
	static Float: origin[3]; pev(ID_FBURN, pev_origin, origin);
	if(!is_user_alive(ID_FBURN) || !is_user_alive(pevAttacker) || pevAttacker == ID_FBURN || zp_get_user_zombie(pevAttacker) || g_burning_duration[ID_FBURN] < 1)
	{
		remove_task(taskid)
		return
	}
	
	health = pev(ID_FBURN, pev_health);

	if (health - FIRE_DAMAGE > 0.0)
	{	
		set_pdata_int(ID_FBURN, m_LastHitGroup, HIT_GENERIC, extra_offset_player);
		ExecuteHamB(Ham_TakeDamage, ID_FBURN, pevAttacker, pevAttacker, FIRE_DAMAGE, DMG_GENERIC);
	}	
	else
	{
		set_pdata_int(ID_FBURN, m_LastHitGroup, HIT_GENERIC, extra_offset_player);
		ExecuteHamB(Ham_Killed, ID_FBURN, pevAttacker, 0);
		remove_task(taskid);
		return
	}
	new TE_FLAG
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	TE_FLAG |= TE_EXPLFLAG_NOSOUND

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION) // Temporary entity ID
	engfunc(EngFunc_WriteCoord, origin[0]+=random_float(-10.0,10.0)) // engfunc because float
	engfunc(EngFunc_WriteCoord, origin[1]+=random_float(-10.0,10.0))
	engfunc(EngFunc_WriteCoord, origin[2]+=random_float(-10.0,10.0))
	write_short(iBlood[random_num(4,6)])
	write_byte(5) // Scale
	write_byte(20) // Framerate
	write_byte(TE_FLAG) // Flags
	message_end();
	
	emit_sound(ID_FBURN, CHAN_WEAPON,SOUND_FIRE_EXP_FOR_PLAYERS1,  VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	g_burning_duration[ID_FBURN]--
	while((iVictim = fm_find_ent_in_sphere(iVictim,origin, WEAPON_BALL_RADIUS_EXP)) != 0 )
	{
		if(is_user_alive(iVictim))
		{
			if(iVictim == pevAttacker || !zp_get_user_zombie(iVictim) || !is_wall_between_points(zp_get_user_zombie(ID_FBURN), iVictim))
				return;
		}	
		if(is_user_alive(iVictim)&&zp_get_user_zombie(iVictim)&&zp_get_user_zombie(ID_FBURN))
		{ 
			UTIL_CreateBeamEntPoint(iVictim, origin, iBlood[9], 255, 0, { 243, 156, 18 });
		}
		if(is_user_alive(iVictim)&&zp_get_user_zombie(iVictim))
		{
			if(iVictim==ID_FBURN) return;
			static iParams[2]; iParams[0] = pevAttacker;
			set_task( 0.5, "CTask__BurningFlame", iVictim + TASK_FBURN, iParams, sizeof iParams, "b");
			g_burning_duration[ iVictim ] += FIRE_DURATION	
			return
		}
	}
} 		
stock UTIL_CreateBeamEntPoint(iPlayer, Float: vecEnd[3], iszModelIndex, iWidth, iNoise, iColor[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT);
	write_short(iPlayer); 
	engfunc(EngFunc_WriteCoord, vecEnd[0]); 
	engfunc(EngFunc_WriteCoord, vecEnd[1]); 
	engfunc(EngFunc_WriteCoord, vecEnd[2]); 
	write_short(iszModelIndex); 
	write_byte(0); 
	write_byte(60); 
	write_byte(5); 
	write_byte(iWidth);
	write_byte(iNoise);
	write_byte(iColor[0]);
	write_byte(iColor[1]); 
	write_byte(iColor[2]);
	write_byte(180);
	write_byte(50);
	message_end();
}
stock is_wall_between_points(iPlayer, iEntity)
{
	if(!is_user_alive(iEntity))
		return 0;

	new iTrace = create_tr2();
	new Float: flStart[3], Float: flEnd[3], Float: flEndPos[3];

	pev(iPlayer, pev_origin, flStart);
	pev(iEntity, pev_origin, flEnd);

	engfunc(EngFunc_TraceLine, flStart, flEnd, IGNORE_MONSTERS, iPlayer, iTrace);
	get_tr2(iTrace, TR_vecEndPos, flEndPos);

	free_tr2(iTrace);

	return xs_vec_equal(flEnd, flEndPos);
}
