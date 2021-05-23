#include <amxmodx>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include <engine>
#include <fun>
#include <zombieplague>

#define Plugin   "[ZP] Extra: Squeak Grenade"
#define Version  "1.0.6-wwm"
#define Author   "Arkshine"

// --| Zombie Plaque: Extra item configuration.
#define ZP_EXTRA_ITEM_NAME  "Snark INFECTOR"
#define ZP_EXTRA_ITEM_COST  14


// --| Snark trail.
#define TRAIL_LIFE		40	// Life
#define TRAIL_WIDTH	   4	 // Width
#define TRAIL_RED		 10	// Red
#define TRAIL_GREEN	   224   // Red
#define TRAIL_BLUE		10	// Green
#define TRAIL_BRIGTHNESS  100   // Blue


/* - - -
|  WEAPON MODELS  |
	 - - - */
	new const gModel_P[] = "models/p_alt_squeak.mdl";
	new const gModel_V[] = "models/v_alt_squeak_gflip.mdl";

/* - - -
|  SNARK SOUNDS  |
	- - - */
	new const gSnarkHunt1Sound	[] = "squeek/sqk_hunt1.wav";
	new const gSnarkHunt2Sound	[] = "squeek/sqk_hunt2.wav";
	new const gSnarkHunt3Sound	[] = "squeek/sqk_hunt3.wav";
	new const gSnarkDieSound	  [] = "squeek/sqk_die1.wav";
	new const gSnarkAttackSound   [] = "squeek/sqk_deploy1.wav";
	new const gSnarkBlastSound	[] = "weapons/sqk_blast2.wav";
	new const gSnarkBodySplatSound[] = "common/bodysplat.wav";

/* - - -
|  SNARK MODEL  |
	   - - - */
new	gSnarkModel[] = "models/w_alt_squeak.mdl";

/* - - -
|	SEQUENCE   |
	   - - - */
enum
{
	wsqueak_idle1,
	wsqueak_fidget,
	wsqueak_jump,
	wsqueak_run
};

enum
{
	squeak_idle1,
	squeak_fidgetfit,
	squeak_fidgetnip,
	squeak_down,
	squeak_up,
	squeak_throw
};
	
/* - -
|  CONSTANTS  |
	   - - */
const BLOOD_COLOR_RED		= 247;
const BLOOD_COLOR_YELLOW	 = 195;
	   
const MAX_CLIENTS			= 32;
const MAX_KNIFE_MODEL_LENGTH = 128;
const NONE				   = -1;
const NULL_ENT			   = 0;

enum _:Coord_e
{
	Float:x,
	Float:y,
	Float:z
};

enum _:Angle_e
{
	Float:Pitch,
	Float:Yaw,
	Float:Roll
};

enum
{
	HuntThink = 1,
	SuperBounceTouch,
	RemoveSnark
};

new const Float:gHullMin	[ Coord_e ] = { -16.0, -16.0, -36.0 };
new const Float:gDuckHullMin[ Coord_e ] = { -16.0, -16.0, -18.0 };

new const gWeaponCommand [] = "weapon_hegrenade";
new const gWeaponIndex	  = CSW_HEGRENADE;

new const gGenericEntity [] = "info_target";
new const gSnarkClassName[] = "wpn_snark";

/* - - - -
|  PLAYER/WEAPON OFFSETS  |
		   - - - - */
const m_flNextAttack		= 83	// Player.
const m_pActiveWeapon	   = 373;  // Player.
const m_pPlayer			 = 41;   // Weapon.
const m_flNextPrimaryAttack = 46;   // Weapon.

/* - - -
|  CUSTOM FIELD  |
	- - - */
#define pev_NextHunt			pev_fuser1
#define pev_NextBounceSoundTime pev_fuser2
#define pev_NextHit			 pev_fuser3
#define pev_NextAttack		  pev_fuser4
#define pev_DetonateDelay	   pev_ltime
#define pev_RealOwner		   pev_iuser1
#define pev_Remove			  pev_iuser2
#define pev_EnemyTarget		 pev_vuser1
#define pev_PosPrev			 pev_vuser2

/* - - -
|  CVAR POINTER  |
	- - - */
new pCvarRefireRate;
new pCvarHealth;
new pCvarVelocity;
new pCvarDamagePop;
new pCvarGravity;
new pCvarFriction;
new pCvarDetonateDelay;
new pCvarShowTrail;

/* - - - -
|  SPRITES/MODELS INDEX  |
		  - - - - */
new gBloodSpray;
new gBloodDrop;
new gSmokeTrail;

/* - - - -
|  OTHERS STUFFS  |
	 - - - */
new bool:gHasSnark	[ MAX_CLIENTS + 1 char ];
new bool:gWeaponActive[ MAX_CLIENTS + 1 char ];
new bool:gJustThrown  [ MAX_CLIENTS + 1 char ];

new Float:gNextShot	  [ MAX_CLIENTS + 1 ];
new Float:gTimeWeaponIdle[ MAX_CLIENTS + 1 ];

new const gSnarkHealthReference = 10000;
new gSnarkClassNameReference;
new gMaxEntities,g_MsgMoney
new gMaxClients;

/* - -
|  MACROS  |
	- - */
#define VectorSubtract(%1,%2,%3)  ( %3[ x ] = %1[ x ] - %2[ x ], %3[ y ] = %1[ y ] - %2[ y ], %3[ z ] = %1[ z ] - %2[ z ] )
#define VectorAdd(%1,%2,%3)	   ( %3[ x ] = %1[ x ] + %2[ x ], %3[ y ] = %1[ y ] + %2[ y ], %3[ z ] = %1[ z ] + %2[ z ] )
#define VectorCopy(%1,%2)		 ( %2[ x ] = %1[ x ],  %2[ y ] = %1[ y ], %2[ z ] = %1[ z ] )
#define VectorScale(%1,%2,%3)	 ( %3[ x ] = %2 * %1[ x ], %3[ y ] = %2 * %1[ y ], %3[ z ] = %2 * %1[ z ] )
#define VectorMA(%1,%2,%3,%4)	 ( %4[ x ] = %1[ x ] + %2 * %3[ x ], %4[ y ] = %1[ y ] + %2 * %3[ y ], %4[ z ] = %1[ z ] + %2 * %3[ z ] )
#define VectorMS(%1,%2,%3,%4)	 ( %4[ x ] = %1[ x ] - %2 * %3[ x ], %4[ y ] = %1[ y ] - %2 * %3[ y ], %4[ z ] = %1[ z ] - %2 * %3[ z ] )
#define VectorLength(%1)		  ( floatsqroot ( %1[ x ] * %1[ x ] + %1[ y ] * %1[ y ] + %1[ z ] * %1[ z ] ) )
#define VectorEqual(%1,%2)		( %1[ x ] == %2[ x ] && %1[ y ] == %2[ y ] && %1[ z ] == %2[ z ] )
#define DotProduct(%1,%2)		 ( %1[ x ] * %2[ x ]+ %1[ y ] * %2[ y ] + %1[ z ] * %2[ z ] )

#define message_begin_f(%1,%2,%3) ( engfunc ( EngFunc_MessageBegin, %1, %2, %3 ) )
#define write_coord_f(%1)		 ( engfunc ( EngFunc_WriteCoord, %1 ) )


public plugin_precache ()
{
	// --| Weapon models.
	precache_model( gModel_P );
	precache_model( gModel_V );
	
	// --| Snark model.
	precache_model( gSnarkModel );
	
	// --| Snark sounds.
	precache_sound( gSnarkBlastSound );
	precache_sound( gSnarkBodySplatSound );
	precache_sound( gSnarkDieSound );
	precache_sound( gSnarkHunt1Sound );
	precache_sound( gSnarkHunt2Sound );
	precache_sound( gSnarkHunt3Sound );
	precache_sound( gSnarkAttackSound );
	
	gBloodSpray = precache_model( "sprites/bloodspray.spr" );   // initial blood
	gBloodDrop  = precache_model( "sprites/blood.spr" );		// splattered blood
}


public plugin_init ()
{
	register_plugin( Plugin, Version, Author );
	register_cvar( "zp_snark_version", Version, FCVAR_SERVER | FCVAR_SPONLY );
	
	pCvarRefireRate	= register_cvar( "wpn_sg_refire_rate"	, "0.3" );
	pCvarHealth		= register_cvar( "wpn_sg_health"		 , "1"  );
	pCvarVelocity	  = register_cvar( "wpn_sg_velocity"	   , "250" );
	pCvarDamagePop	 = register_cvar( "wpn_sg_damage_pop"	 , "450"   );
	pCvarGravity	   = register_cvar( "wpn_sg_gravity"		, "10" );
	pCvarFriction	  = register_cvar( "wpn_sg_friction"	   , "0.5" );
	pCvarDetonateDelay = register_cvar( "wpn_sg_detonate_delay" , "10"  );
	pCvarShowTrail	 = register_cvar( "wpn_sg_show_trail"	 , "1"   );
	
	RegisterHam( Ham_Item_Deploy , gWeaponCommand, "CSqueak_Deploy", 1 );
	RegisterHam( Ham_Item_Holster, gWeaponCommand, "CSqueak_Holster", 1 );
	RegisterHam( Ham_TakeDamage, gGenericEntity, "CSqueak_TakeDamage", 1 );
	
	register_forward( FM_CmdStart, "CSqueak_HookButtons" );
	register_forward( FM_PlayerPreThink, "CSqueak_WeaponIdle" );
	
	register_message(get_user_msgid("DeathMsg"), "event_death")
	register_think( gSnarkClassName, "CSqueak_HuntThink" );
	register_touch( gSnarkClassName, "*", "CSqueak_SuperBounceTouch" );
	
	g_MsgMoney = get_user_msgid("Money")
	register_clcmd( "say /snark", "BuyMenu" );
	
	gMaxEntities = global_get( glb_maxEntities );
	gMaxClients  = global_get( glb_maxClients );
	
	gSnarkClassNameReference = engfunc( EngFunc_AllocString, gSnarkClassName );
	
	if ( get_pcvar_num( pCvarShowTrail ) )
	{
		gSmokeTrail = engfunc( EngFunc_PrecacheModel, "sprites/smoke.spr" );
	}
}
public event_death(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, "hegrenade") && get_user_weapon(iAttacker) == gWeaponIndex)
	{
		if(gHasSnark{iAttacker})
			set_msg_arg_string(4, "snark")		
	}
	
	if (iVictim != iAttacker && is_user_connected(iAttacker) && zp_get_user_zombie(iVictim) && !zp_get_user_zombie(iAttacker))
	{
		UpdateFrags(iAttacker, 1, 1)
		zp_set_user_ammo_packs(iAttacker, zp_get_user_ammo_packs(iAttacker)+50 )
	}   
	
	return PLUGIN_CONTINUE
}

public plugin_natives()
{
	register_native("Snark","native_give_snark",1)
}
public native_give_snark(Player)
{
	CSqueak_GiveWeapon ( Player );
}
public zp_round_started(Player)
{	
	if(!zp_is_nemesis_round() || !zp_is_survivor_round() || !zp_is_swarm_round() || !zp_is_plague_round())
	{
		if(zp_get_user_ammo_packs( Player ) >= 50000)
		{
			BuyMenu(Player)
		}
	}
}

public BuyMenu(id)
{

	new menu = menu_create("^n\yBuy Snark?\y  Price: \r$50000", "BuyMenu_handler");

	menu_additem(menu, "\wYes", "1", 0);
	menu_additem(menu, "\wNo", "2", 0);
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);

	menu_display(id, menu)
}
public BuyMenu_handler(id, menu, item) 
{
  
	if( item == MENU_EXIT )
	{
		menu_destroy(menu);
 
		return PLUGIN_HANDLED;
	}


	new data[6], szName[64];
	new access, callback;

	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback);
	
	new key = str_to_num(data);

	switch(key)
	{
		case 1:
		{
		if(zp_get_user_ammo_packs( id ) >= 50000)
		{
				if(!zp_get_user_zombie(id))
				{
					CSqueak_GiveWeapon(id)
					zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id)-50000)
					loadmoney(id)
				}else client_print(id, print_center,"Zombie Can't Buy!")
		}else {
			client_print(id, print_center,"Don't Have Enough Money!")
			loadmoney(id) 
		}
		}
		case 2:
		{
		menu_destroy(menu);
	 
		return PLUGIN_HANDLED;
		}
	}

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public zp_round_ended ( WinTeam )
{
new Snark = -1;

while ( ( Snark = find_ent_by_class( Snark, gSnarkClassName ) ) != NULL_ENT )
{
	CSqueak_Killed ( Snark, 0, true );
}
for ( new Player = 1; Player <= gMaxClients; Player++ )
{
	CheckAndRemoveWeapon ( Player );
	gHasSnark{Player} = false;
}
}
public zp_user_infected_post( Player )
{
gHasSnark{Player} = false	
}
public zp_user_humanized_pre( Player, Survivor )
{
CheckAndRemoveWeapon ( Player );
}

stock CheckAndRemoveWeapon ( const Player )
{
if ( user_has_weapon( Player, gWeaponIndex ) )
{
	RemoveWeapon ( Player, get_user_weapon( Player ) == gWeaponIndex ? 
	
	get_pdata_cbase( Player, m_pActiveWeapon ) : 
	find_ent_by_owner ( -1, gWeaponCommand, Player ) );
}
}


public client_connect ( Player )
{
gHasSnark	{ Player } = false;
gWeaponActive{ Player } = false;
gJustThrown  { Player } = false;
}


public CSqueak_GiveWeapon( const Player )
{
if(is_user_bot(Player))
{
	fm_strip_user_weapons(Player)
}
gHasSnark{ Player } = true;
give_item( Player, gWeaponCommand );
engclient_cmd( Player, gWeaponCommand );

}


public CSqueak_PrimaryAttack ( const Player )
{
	static Float:VAngle	 [ Angle_e ];
	static Float:Origin	 [ Coord_e ];
	static Float:TraceOrigin[ Coord_e ];
	static Float:Forward	[ Coord_e ];
	static Float:Start	  [ Coord_e ];
	static Float:End		[ Coord_e ];
	static Float:EndPos	 [ Coord_e ];
	static Float:Velocity   [ Coord_e ];
	static Float:Fraction;
	
	if ( pev( Player, pev_waterlevel ) >= 3 )
	{
		emit_sound( Player, CHAN_WEAPON, gSnarkDieSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM + 5 );
		gNextShot[ Player ] = get_gametime() + get_pcvar_float( pCvarRefireRate );
		return PLUGIN_HANDLED;
	}
	
	pev( Player, pev_origin, Origin );
	pev( Player, pev_v_angle, VAngle );
	pev( Player, pev_velocity, Velocity );
	
	engfunc( EngFunc_MakeVectors, VAngle );
	
	VectorCopy( Origin, TraceOrigin );
	
	if ( pev( Player, pev_flags ) & FL_DUCKING )
	{
		TraceOrigin[ x ] = TraceOrigin[ x ] - ( gHullMin[ x ] - gDuckHullMin[ x ] );
		TraceOrigin[ y ] = TraceOrigin[ y ] - ( gHullMin[ y ] - gDuckHullMin[ y ] );
		TraceOrigin[ z ] = TraceOrigin[ z ] - ( gHullMin[ z ] - gDuckHullMin[ z ] );
	}
	
	global_get( glb_v_forward, Forward );
	
	VectorMA ( TraceOrigin, 20.0, Forward, Start );
	VectorMA ( TraceOrigin, 64.0, Forward, End );
	
	engfunc( EngFunc_TraceLine, Start, End, DONT_IGNORE_MONSTERS, NULL_ENT, 0 );
	
	get_tr2( 0, TR_Fraction, Fraction );
	get_tr2( 0, TR_vecEndPos, EndPos );
	
	if ( !get_tr2( 0, TR_AllSolid ) && !get_tr2( 0, TR_StartSolid ) && Fraction > 0.25 )
	{
		// --| Play the throw animation.
		UTIL_PlayWeaponAnimation ( Player, squeak_throw );
		
		// --| player "shoot" animation
		//
		
		VectorMA ( Velocity, get_pcvar_float( pCvarVelocity ), Forward, Velocity );
	
		if ( CSqueak_Create ( Player, EndPos, VAngle, Velocity ) )
		{
			new Float:CurrentTime = get_gametime();
		
			switch ( random_num( 0, 2 ) )
			{
				case 0: emit_sound( Player, CHAN_WEAPON, gSnarkHunt1Sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
				case 1: emit_sound( Player, CHAN_WEAPON, gSnarkHunt2Sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
				case 2: emit_sound( Player, CHAN_WEAPON, gSnarkHunt3Sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
			}
			gJustThrown{ Player } = true;
			gNextShot[ Player ] = CurrentTime + get_pcvar_float( pCvarRefireRate );
			gTimeWeaponIdle[ Player ] = CurrentTime + 1.0;
		
			return PLUGIN_CONTINUE;
		}
	}
	return PLUGIN_HANDLED;
}


public CSqueak_Deploy ( const Weapon )
{
// --| Get the knife's owner index.
new Player = get_pdata_cbase( Weapon, m_pPlayer, 4 );

if ( Player && gHasSnark{ Player } )
{
	// --| Change knife to snark weapon.
	ChangeWeaponToSnark ( Player );

	// --| Play the deploy animation.
	UTIL_PlayWeaponAnimation ( Player, squeak_up );
	emit_sound ( Weapon, CHAN_VOICE , random_float ( 0.0, 1.0 ) <= 0.5 ? gSnarkHunt2Sound : gSnarkHunt3Sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

	// --| Block the primary attack.
	set_pdata_float( Weapon, m_flNextPrimaryAttack, 9999.0, 4 );
	set_pdata_float( Player, m_flNextAttack, 9999.0 );
	
	// --| We are holding the weapon.
	gWeaponActive{ Player } = true;
}
}


public CSqueak_Holster ( const Weapon )
{
// --| Get the knife's owner index.
new Player = get_pdata_cbase( Weapon, m_pPlayer, 4 );

if ( Player && gHasSnark{ Player } && gWeaponActive{ Player } )
{
	// --| We are not holding the weapon anymore.
	gWeaponActive{ Player } = false;
	set_pdata_float( Player, m_flNextAttack, get_gametime() + 0.5 );

	// --| Play the holster animation.
	UTIL_PlayWeaponAnimation ( Player, squeak_down );
	emit_sound( Player, CHAN_WEAPON, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
}
}


public CSqueak_Killed ( const Snark, const Killer, const bool:ShouldGib )
{
new Float:Direction[ Coord_e ];
new Float:Origin   [ Coord_e ];

pev( Snark, pev_origin, Origin );

set_pev( Snark, pev_model, 0 );
set_pev( Snark, pev_Remove, RemoveSnark );
set_pev( Snark, pev_DetonateDelay, get_gametime() + 0.1 );

set_pev( Snark, pev_takedamage, DAMAGE_NO );

emit_sound( Snark, CHAN_ITEM, gSnarkBlastSound, VOL_NORM, ATTN_NORM / 2, 0, PITCH_NORM );
emit_sound( Snark, CHAN_VOICE, gSnarkBodySplatSound, 0.75, ATTN_NORM, 0, PITCH_NORM * 2 );

UTIL_RandomBloodVector( Direction );

FX_BloodDrips ( Origin, BLOOD_COLOR_YELLOW, .Amount = 60 )
FX_StreakSplash ( Origin, Direction, .Color = 5, .Count = 16, .Speed = 50, .VelocityRange = 200 );

//UTIL_RadiusDamage ( Origin, Snark, pev( Snark, pev_RealOwner ), get_pcvar_float( pCvarDamagePop ), get_pcvar_float( pCvarDamageRadius ), DMG_BLAST );
}


/* public CZombie_Killed ( const Zombie, const Human, const bool:ShouldGid )
{
if ( zp_get_user_zombie( Zombie ) && gHasSnark{ Zombie } )
{
	
}
} */


public CSqueak_TakeDamage ( const Snark, const Inflictor, const Attacker, const Float:Damage, const DamageBits )
{
if ( is_valid_ent( Snark ) && pev( Snark, pev_groupinfo ) == gSnarkClassNameReference )
{
	if(!zp_get_user_zombie(Attacker))
		return
		
	if ( pev( Snark, pev_health ) - gSnarkHealthReference <= 0 )
	{
	CSqueak_Killed ( Snark, Attacker, .ShouldGib = true );
	}
}
}


public CSqueak_HookButtons ( const Player, const UC_Handle, const Seed )
{
static Float:CurrentTime;
static Buttons;

if ( gHasSnark{ Player } && gWeaponActive{ Player } && ( Buttons = get_uc( UC_Handle, UC_Buttons ) ) & IN_ATTACK )
{
	CurrentTime = get_gametime();

	if ( gNextShot[ Player ] > CurrentTime )
	{
	return FMRES_HANDLED;
	}
	
	if ( CSqueak_PrimaryAttack ( Player ) == PLUGIN_HANDLED )
	{
	return FMRES_HANDLED;
	}

	set_uc( UC_Handle, UC_Buttons, Buttons & ~IN_ATTACK );
	return FMRES_HANDLED;
}

return FMRES_IGNORED;
}


public CSqueak_HuntThink ( const Snark )
{
if ( !is_valid_ent( Snark ) )
{
	return HAM_IGNORED;
}

static Float:Origin  [ Coord_e ];
static Float:Velocity[ Coord_e ];
static Float:Angles  [ Coord_e ];
static Float:Flat	[ Coord_e ];
static Float:CurrentTime;
static Float:DieDelay;
static Float:NextHunt;
static Float:SPitch;
static Enemy;

pev( Snark, pev_velocity, Velocity );
pev( Snark, pev_origin, Origin );

if ( !UTIL_IsInWorld ( Origin, Velocity ) )
{
	set_pev( Snark, pev_flags, pev( Snark, pev_flags ) | FL_KILLME );
	return HAM_IGNORED;
}

CurrentTime = get_gametime();
set_pev( Snark, pev_nextthink, CurrentTime + 0.1 );

pev( Snark, pev_NextHunt, NextHunt );
pev( Snark, pev_DetonateDelay, DieDelay );
pev( Snark, pev_angles, Angles );

if ( CurrentTime >= DieDelay )
{
	if ( pev( Snark, pev_Remove ) )
	{
	set_pev( Snark, pev_flags, pev( Snark, pev_flags ) | FL_KILLME );
	return HAM_IGNORED;
	}

	set_pev( Snark, pev_health, -1.0 );
	CSqueak_Killed ( Snark, 0, true );
	return HAM_IGNORED;
}

if ( pev( Snark, pev_waterlevel ) != 0 )
{
	if ( pev( Snark, pev_movetype ) == MOVETYPE_BOUNCE )
	{
	set_pev( Snark, pev_movetype, MOVETYPE_FLY );
	}

	VectorScale ( Velocity, 0.9, Velocity );
	Velocity[ z ] += 8.0;

	set_pev( Snark, pev_velocity, Velocity );
}
else if ( pev( Snark, pev_movetype ) == MOVETYPE_FLY )
{
	set_pev( Snark, pev_movetype, MOVETYPE_BOUNCE );
}

if ( NextHunt > CurrentTime )
{
	return HAM_IGNORED;
}

set_pev( Snark, pev_NextHunt, CurrentTime + 2.0 );

VectorCopy ( Velocity, Flat );
Flat[ z ] = 0.0;
VectorNormalize ( Flat, Flat );

engfunc( EngFunc_MakeVectors, Angles );

if ( ( Enemy = pev( Snark, pev_enemy ) ) == NULL_ENT || !is_user_alive( Enemy ) || !zp_get_user_zombie( Enemy ) )
{
	Enemy = UTIL_BestVisibleEnemy ( Snark, 512.0 );
}

if ( 0.3 <= DieDelay - CurrentTime <= 0.5 )
{
	set_pev( Snark, pev_scale, 2.0 );
	emit_sound( Snark, CHAN_VOICE, gSnarkDieSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM + random_num( 0, 0x3F ) );
}

SPitch = 155.0 - 60.0 * ( ( DieDelay - CurrentTime ) / get_pcvar_float( pCvarDetonateDelay ) );

if ( SPitch < 80.0 )  { SPitch = 80.0; }

if ( Enemy != NULL_ENT && zp_get_user_zombie( Enemy ) )
{
	static Float:Target[ Coord_e ];
	static Float:Vel;
	static Float:Adj;

	pev( Snark, pev_EnemyTarget, Target );

	if ( UTIL_FVisible( Snark, Enemy ) )
	{
	static Float:EyePosition[ Coord_e ];
	UTIL_EyePosition ( Enemy, EyePosition );

	VectorSubtract ( EyePosition, Origin, Target );
	VectorNormalize ( Target, Target );

	set_pev( Snark, pev_EnemyTarget, Target );
	}

	Vel = VectorLength ( Velocity );
	Adj = 50.0 / ( Vel + 10.0 );

	if ( Adj > 1.2 )  { Adj = 1.2; }

	Velocity[ x ] = Velocity[ x ] * Adj + Target[ x ] * 300.0;
	Velocity[ y ] = Velocity[ y ] * Adj + Target[ y ] * 300.0;
	Velocity[ z ] = Velocity[ z ] * Adj + Target[ z ] * 300.0;

	set_pev( Snark, pev_velocity, Velocity );
}

if ( pev( Snark, pev_flags ) & FL_ONGROUND )
{
	set_pev( Snark, pev_avelocity, Float:{ 0.0, 0.0, 0.0 } );
}
else
{
	static Float:AVelocity[ Coord_e ];
	pev( Snark, pev_avelocity, AVelocity );

	if ( AVelocity[ x ] == 0.0 && AVelocity[ y ] == 0.0 && AVelocity[ z ] == 0.0 )
	{
	AVelocity[ x ] = random_float( -100.0, 100.0 );
	AVelocity[ z ] = random_float( -100.0, 100.0 );

	set_pev( Snark, pev_avelocity, AVelocity );
	}
}

static Float:PosPrev[ Coord_e ];
pev( Snark, pev_PosPrev, PosPrev );

VectorSubtract ( Origin, PosPrev, PosPrev );

if ( VectorLength ( PosPrev ) < 1.0 )
{
	Velocity[ x ] = random_float( -100.0, 100.0 );
	Velocity[ y ] = random_float( -100.0, 100.0 );

	set_pev( Snark, pev_velocity, Velocity );
}

set_pev( Snark, pev_PosPrev, Origin );

vector_to_angle( Velocity, Angles );

Angles[ z ] = 0.0;
Angles[ x ] = 0.0;

set_pev( Snark, pev_angles, Angles );

return HAM_IGNORED;
}


public CSqueak_SuperBounceTouch ( const Snark, const Other )
{
		if ( !is_valid_ent( Snark ) )
		{
			return;
		}
		
		static Float:Angles [ Angle_e ];
		static Float:NextHit;
		static Float:DieDelay;
		static Float:NextAttack;
		static Float:NextBounceSoundTime;
		static Float:SPitch;
		static Float:CurrentTime;
		static Owner;

		Owner = pev( Snark, pev_owner );

		if ( Owner && Other == Owner )
		{
			return;
		}

		SPitch = PITCH_NORM * 1.0;
		CurrentTime = get_gametime();

		set_pev( Snark, pev_owner, NULL_ENT );

		pev( Snark, pev_angles, Angles );
		pev( Snark, pev_NextHit, NextHit );
		pev( Snark, pev_DetonateDelay, DieDelay );
		pev( Snark, pev_NextAttack, NextAttack );
		pev( Snark, pev_NextBounceSoundTime, NextBounceSoundTime );

		Angles[ x ] = 0.0;
		Angles[ z ] = 0.0;

		set_pev( Snark, pev_angles, Angles );

		if ( NextHit > CurrentTime )
		{
			return;
		}

		SPitch = 155.0 - 60.0 * ( ( DieDelay - CurrentTime ) / get_pcvar_float( pCvarDetonateDelay ) );

		if ( 1 <= Other <= gMaxClients && pev( Other, pev_takedamage ) && NextAttack < CurrentTime )
		{
			static Hit;
			Hit = global_get( glb_trace_ent );

			if ( Hit == Other && pev( Hit, pev_modelindex ) != pev( Snark, pev_modelindex ) && 1 <= Other <= gMaxClients )
			{
				Owner = pev( Snark, pev_RealOwner );
				
				if ( zp_get_user_zombie( Other ))
				{
			static Float:Forward	[ Coord_e ];
			static Float:EndPos	 [ Coord_e ];
			static Float:OriginSnark[ Coord_e ];
			static Float:OriginOther[ Coord_e ];
			static Trace;
			static Float:Damage;
			
			Trace = create_tr2();
			
			pev( Snark, pev_dmg, Damage );
			pev( Snark, pev_origin, OriginSnark );
			pev( Other, pev_origin, OriginOther );
			
			engfunc( EngFunc_TraceLine, OriginSnark, OriginOther, DONT_IGNORE_MONSTERS, Snark, Trace );
			
			get_tr2( Trace, TR_vecPlaneNormal, Forward );
			get_tr2( Trace, TR_vecEndPos, EndPos );
			
			
			FX_BloodDrips ( EndPos, BLOOD_COLOR_RED, .Amount = floatround( Damage ) ); 
			free_tr2( Trace );
			set_pev( Snark, pev_dmg, pev( Snark, pev_dmg ) + get_pcvar_float( pCvarDamagePop ) );
			
			//ExecuteHamB(Ham_TakeDamage, Other, Owner, Owner, get_pcvar_float( pCvarDamagePop ), DMG_BULLET)
			ExecuteHam( Ham_TakeDamage, Other, Owner, Owner, get_pcvar_float( pCvarDamagePop ) , DMG_SLASH );
			
			set_pev( Snark, pev_enemy, NULL_ENT );
				}
				
				emit_sound( Snark, CHAN_WEAPON, gSnarkAttackSound, VOL_NORM, ATTN_NORM, 0, floatround( SPitch ) );
				set_pev( Snark, pev_NextAttack, CurrentTime + 0.1 );
			}
		}

		set_pev( Snark, pev_NextHit, CurrentTime + 0.1 );
		set_pev( Snark, pev_NextHunt, CurrentTime );

		if ( CurrentTime < NextBounceSoundTime )
		{
			return;
		}

		if ( !( pev( Snark, pev_flags ) & FL_ONGROUND ) )
		{
			switch ( random( 10 ) )
			{
				case 0 .. 3 : emit_sound( Snark, CHAN_VOICE, gSnarkHunt1Sound, VOL_NORM, ATTN_NORM, 0, floatround( SPitch ) );
				case 4 .. 7 : emit_sound( Snark, CHAN_VOICE, gSnarkHunt2Sound, VOL_NORM, ATTN_NORM, 0, floatround( SPitch ) );
				default	 : emit_sound( Snark, CHAN_VOICE, gSnarkHunt3Sound, VOL_NORM, ATTN_NORM, 0, floatround( SPitch ) );
			}
		}

		set_pev( Snark, pev_NextBounceSoundTime, CurrentTime + 0.5 );
}


CSqueak_Create ( const Player, const Float:Origin[ Coord_e ], const Float:Angles[ Coord_e], const Float:Velocity[ Coord_e ] )
{
new Snark = create_entity( gGenericEntity );

if ( is_valid_ent( Snark ) )
{
	set_pev( Snark, pev_classname, gSnarkClassName );
	set_pev( Snark, pev_groupinfo, gSnarkClassNameReference );
	set_pev( Snark, pev_owner, Player );
	set_pev( Snark, pev_origin, Origin );
	set_pev( Snark, pev_angles, Angles );
	set_pev( Snark, pev_velocity, Velocity );

	CSqueak_Spawn ( Player, Snark, Origin );

	return Snark;
}

return NULL_ENT;
}


CSqueak_Spawn ( const Player, const Snark, const Float:Origin[ Coord_e ] )
{
new Float:CurrentTime = get_gametime();

set_pev( Snark, pev_movetype, MOVETYPE_BOUNCE );
set_pev( Snark, pev_solid, SOLID_BBOX );

entity_set_model ( Snark, gSnarkModel );
entity_set_size  ( Snark, Float:{ -4.0, -4.0, 0.0 }, Float:{ 4.0, 4.0, 8.0 } );
entity_set_origin( Snark, Origin );

set_pev( Snark, pev_nextthink, CurrentTime + 0.1 );

set_pev( Snark, pev_NextHunt, CurrentTime + 1000000.0 ); // NextHunt
set_pev( Snark, pev_DetonateDelay, CurrentTime + get_pcvar_float( pCvarDetonateDelay ) ); // DetonateDelay
set_pev( Snark, pev_NextBounceSoundTime, CurrentTime ); // NextBounceSoundTime
set_pev( Snark, pev_RealOwner, Player ); // RealOwner

set_pev( Snark, pev_flags, pev( Snark, pev_flags ) | FL_MONSTER );
set_pev( Snark, pev_takedamage, DAMAGE_AIM );
set_pev( Snark, pev_health, get_pcvar_float( pCvarHealth ) + gSnarkHealthReference );
set_pev( Snark, pev_gravity, get_pcvar_float( pCvarGravity ) );
set_pev( Snark, pev_friction, get_pcvar_float( pCvarFriction ) );
// set_pev( Snark, pev_dmg, get_pcvar_float( pCvarDamagePop ) );

// --| Force snark to run.
set_pev( Snark, pev_sequence, wsqueak_run );
set_pev( Snark, pev_framerate, 1.0 );
set_pev( Snark, pev_animtime, CurrentTime );

if ( get_pcvar_num( pCvarShowTrail ) )
{
	message_begin ( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte ( TE_BEAMFOLLOW );
	write_short ( Snark );
	write_short ( gSmokeTrail );
	write_byte ( TRAIL_LIFE );   // life
	write_byte ( TRAIL_WIDTH );  // width
	write_byte ( TRAIL_RED );
	write_byte ( TRAIL_GREEN );
	write_byte ( TRAIL_BLUE );
	write_byte ( TRAIL_BRIGTHNESS );
	message_end();
}
}

public CSqueak_WeaponIdle ( const Player )
{
	if ( gHasSnark{ Player } && gWeaponActive{ Player } && !zp_get_user_zombie(Player))
	{		
		static Float:CurrentTime;
		CurrentTime = get_gametime();		
		if(is_user_bot(Player)&&gHasSnark{Player})
		{
			CurrentTime = get_gametime();
		
			if ( gNextShot[ Player ] > CurrentTime )
			{
				return FMRES_HANDLED;
			}
			
			if ( CSqueak_PrimaryAttack ( Player ) == PLUGIN_HANDLED )
			{
				return FMRES_HANDLED;
			}
		}
	
		if ( gTimeWeaponIdle[ Player ] > CurrentTime )
		{
			return FMRES_HANDLED;
		}
		if ( gJustThrown{ Player } )
		{
			gJustThrown{ Player } = false;
		
			UTIL_PlayWeaponAnimation ( Player, squeak_up );
			gTimeWeaponIdle[ Player ] = CurrentTime + random_float ( 10.0, 15.0 );
		
			return FMRES_HANDLED;
		}

		new Animation;
		new Float:NewTime;
	
		switch ( random_num( 0, 10 ) )
		{
			case 0 .. 6 :
			{
				Animation = squeak_idle1;
				NewTime   = 30.0 / 16.0 * ( 2.0 );
			}
			case 7 .. 8 :
			{
				Animation = squeak_fidgetfit;
				NewTime   = 70.0 / 16.0;
			}
			default :
			{
				Animation = squeak_fidgetnip;
				NewTime   = 80.0 / 16.0;
			}
		}
		
		UTIL_PlayWeaponAnimation ( Player, Animation );
		gTimeWeaponIdle[ Player ] = CurrentTime + NewTime;
	}
	return FMRES_IGNORED;
}


ChangeWeaponToSnark ( const Player )
{
set_pev( Player, pev_viewmodel2  , gModel_V );
set_pev( Player, pev_weaponmodel2, gModel_P );
}

RemoveWeapon ( const Player, const Weapon )
{
ExecuteHamB( Ham_Weapon_RetireWeapon, Weapon );
ExecuteHamB( Ham_RemovePlayerItem, Player, Weapon );
ExecuteHamB( Ham_Item_Kill, Weapon );

set_pev( Player, pev_weapons, pev( Player, pev_weapons ) & ~( 1 << gWeaponIndex ) );
cs_set_user_bpammo( Player, gWeaponIndex, 0 );

gHasSnark{ Player } = false;
gWeaponActive{ Player } = false;
}


stock bool:UTIL_IsBSPModel ( const Entity )
{
return ( pev( entity, pev_solid ) == SOLID_BSP || pev( Entity, pev_movetype ) == MOVETYPE_STEP );
}


UTIL_BestVisibleEnemy ( const Snark, const Float:DistanceToSearch /* , const Flags */ )
{
static List[ MAX_CLIENTS ];
static Float:Distance;
static Float:Nearest;
static ReturnEntity;
static Count;
static Entity;
static i;

Nearest = 8192.0;
ReturnEntity = NULL_ENT;

Count = find_sphere_class( Snark, "player", DistanceToSearch, List, sizeof List );

for ( i = 0; i < Count; i++ )
{
	Entity = List[ i ];
	
	if ( !zp_get_user_zombie( Entity ) )
	{
	continue;
	}

	if ( UTIL_FInViewCone ( Snark, Entity ) && UTIL_FVisible( Snark, Entity ) )
	{
	if ( ( Distance = entity_range( Snark, Entity ) ) <= Nearest )
	{
		Nearest = Distance;
		ReturnEntity = Entity;
	}
	}
}

set_pev( Snark, pev_enemy, ReturnEntity );
return ReturnEntity;
}



UTIL_PlayWeaponAnimation ( const Player, const Sequence )
{
set_pev( Player, pev_weaponanim, Sequence );

message_begin( MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player );
write_byte( Sequence );
write_byte( pev( Player, pev_body ) );
message_end();
}


bool:UTIL_IsInWorld ( const Float:Origin[ Coord_e ], const Float:Velocity[ Coord_e ] )
{
static i;

for ( i = x; i <= z; i++ )
{
	if ( !( -4096.0 < Origin[ i ] < 4096.0 ) && !( -2000.0 < Velocity[ x ] < 2000.0 ) )
	{
	return false;
	}
}

return true;
}


UTIL_RandomBloodVector ( Float:Direction[ Coord_e ] )
{
Direction[ x ] = random_float( -1.0, 1.0 );
Direction[ y ] = random_float( -1.0, 1.0 );
Direction[ z ] = random_float(  0.0, 1.0 );
}


FX_BloodDrips ( const Float:Origin[ Coord_e ], const BloodColor, const Amount )
{
message_begin_f( MSG_PVS, SVC_TEMPENTITY, Origin, NULL_ENT );
write_byte( TE_BLOODSPRITE );
write_coord_f( Origin[ x ] );
write_coord_f( Origin[ y ] );
write_coord_f( Origin[ z ] );
write_short( gBloodSpray );		 // initial sprite model
write_short( gBloodDrop );		  // droplet sprite models
write_byte( BloodColor );		   // color index into host_basepal
write_byte( min( max( 3, ( Amount > 255 ? 255 : Amount ) / 10 ), 16 ) );  // size
message_end();
}


FX_StreakSplash ( const Float:Origin[ Coord_e ], const Float:Direction[ Coord_e ], const Color, const Count, const Speed, const VelocityRange )
{
message_begin_f( MSG_PVS, SVC_TEMPENTITY, Origin, NULL_ENT );
write_byte( TE_STREAK_SPLASH );
write_coord_f( Origin[ x ] );
write_coord_f( Origin[ y ] );
write_coord_f( Origin[ z ] );
write_coord_f( Direction[ x ] );
write_coord_f( Direction[ y ] );
write_coord_f( Direction[ z ] );
write_byte( min( Color, 255 ) );
write_short( Count );
write_short( Speed );
write_short( VelocityRange );// random velocity modifier
message_end();
}


stock FX_TraceBleed( const Victim, const Float:Damage, const Float:Dir[ Coord_e ], const TraceResult:Trace )
{
new TraceResult:BloodTrace;
new Float:TraceDir[ Coord_e ]; 
new Float:EndPos  [ Coord_e ];
new Float:Noise;
new Float:Fraction;
new Count;

if ( Damage < 10 )
{
	Noise = 0.1;
	Count = 1;
}
else if ( Damage < 25 )
{
	Noise = 0.2;
	Count = 2;
}
else
{
	Noise = 0.3;
	Count = 4;
}

for ( new i = 0 ; i < Count ; i++ )
{
	VectorScale ( Dir, -1.0, TraceDir );

	TraceDir[ x ] += random_float( -Noise, Noise );
	TraceDir[ y ] += random_float( -Noise, Noise );
	TraceDir[ z ] += random_float( -Noise, Noise );
	
	get_tr2( Trace, TR_vecEndPos, EndPos );
	VectorMA ( EndPos, -172.0, TraceDir, TraceDir );
	
	engfunc( EngFunc_TraceLine, EndPos, TraceDir, IGNORE_MONSTERS, Victim, BloodTrace );
	get_tr2( BloodTrace, TR_flFraction, Fraction );

	if ( Fraction != 1.0 )
	{
	FX_BloodDecalTrace( BloodTrace, EndPos, BLOOD_COLOR_RED );
	}
}
}


stock FX_BloodDecalTrace ( const TraceResult:Trace, const Float:EndPos[ Coord_e ], const BloodColor )
{
new Hit;
new BaseIndex;
new DecalIndex;
new Float:Fraction; 

switch ( BloodColor )
{
	case BLOOD_COLOR_YELLOW : BaseIndex = get_decal_index( "{yblood1" );
	case BLOOD_COLOR_RED	: BaseIndex = get_decal_index( "{blood1" );
}

DecalIndex = BaseIndex + random_num( 0, 5 );

Hit = max( 0, get_tr2( Trace, TR_pHit ) );
get_tr2( Trace, TR_flFraction, Fraction );

if ( Fraction == 1.0 || ( Hit && !UTIL_IsBSPModel ( Hit ) ) )
{
	return;
}   

message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
write_byte( Hit ? TE_DECAL : TE_WORLDDECAL );
write_coord_f( EndPos[ x ] );
write_coord_f( EndPos[ y ] );
write_coord_f( EndPos[ z ] );
write_byte( DecalIndex );
if ( Hit )
{
	write_short( Hit );
}
message_end();
}


stock UTIL_RadiusDamage ( const Float:Origin[ Coord_e ], const Inflictor, const Attacker, const Float:Damage, const Float:Radius, const DamageBits )
{
static Entity;
static Trace;
static Float:AdjustedDamage;
static bool:InWater;

Entity = NULL_ENT;
InWater = UTIL_LiquidContents( Origin );

while ( ( Entity = find_ent_in_sphere( Entity, Origin, Radius ) ) != NULL_ENT )
{
	if ( Entity == Inflictor )
	{
	continue;
	}

	if ( pev( Entity, pev_takedamage ) && zp_get_user_zombie( Entity ) )
	{
	static Float:EntOrigin[ Coord_e ];
	static Float:EndPos   [ Coord_e ];
	static Float:Fraction;

	pev( Entity, pev_origin, EntOrigin );

	engfunc( EngFunc_TraceLine, Origin, EntOrigin, IGNORE_MONSTERS, Inflictor, Trace );

	get_tr2( Trace, TR_flFraction, Fraction );
	get_tr2( Trace, TR_vecEndPos, EndPos );

	if ( Fraction == 1.0 || get_tr2( Trace, TR_pHit ) == Entity )
	{
		static Float:Delta[ Coord_e ];
		static Float:Len;

		if ( get_tr2( Trace, TR_StartSolid ) )
		{
		EndPos = Origin;
		Fraction = 0.0;
		}

		AdjustedDamage = Damage;
		VectorSubtract ( EndPos, Origin, Delta );

		if ( ( Len = VectorLength ( Delta ) ) != 0.0 )
		{
		VectorScale ( Delta, 1 / Len, Delta );
		}

		if ( Len > 2.0 )
		{
		Len -= 2.0;
		}

		if ( ( AdjustedDamage *= ( 1.0 - Len / Radius ) ) <= 0 )
		{
		continue;
		}

		if ( InWater || pev( Entity, pev_waterlevel ) > 2 )
		{
		AdjustedDamage *= 0.5;
		}

		if ( Fraction != 1.0 )
		{
		ExecuteHam( Ham_TraceAttack, Entity, Inflictor, AdjustedDamage, Delta, Trace, DamageBits );
		ExecuteHam( Ham_TakeDamage, Entity, Inflictor, Attacker, AdjustedDamage, DamageBits );
		}
		else
		{
		ExecuteHam( Ham_TakeDamage, Entity, Inflictor, Attacker, AdjustedDamage, DamageBits );
		}
	}
	}
}
}


stock UTIL_EntitiesInBox ( List[], const ListMax, const Float:Mins[ Coord_e ], const Float:Maxs[ Coord_e ], const Flags )
{
/*
static Float:Origin [ Coord_e ];
static Float:Delta  [ Coord_e ];
static Float:Mins   [ Coord_e ];
static Float:Maxs   [ Coord_e ];

pev( Snark, pev_origin, Origin );

Delta[ x ] = Delta[ y ] = Delta[ z ] = DistanceToSearch;

VectorSubtract ( Origin, Delta, Mins );
VectorAdd ( Origin, Delta, Maxs );

Count = UTIL_EntitiesInBox ( List, sizeof List, Mins, Maxs, Flags );
*/

static Float:AbsMins[ Coord_e ];
static Float:AbsMaxs[ Coord_e ];
static Count;
static Entity;

Count = 0;

for ( Entity = 1; Entity <= gMaxEntities; Entity++ )  if( is_valid_ent( Entity ) )
{
	if ( !( pev( Entity, pev_flags ) & Flags ) )
	{
	continue;
	}

	pev( Entity, pev_absmin, AbsMins );
	pev( Entity, pev_absmax, AbsMaxs );

	if ( Mins[ x ] > AbsMaxs[ x ] || Mins[ y ] > AbsMaxs[ y ] || Mins[ z ] > AbsMaxs[ z ] ||
	 Maxs[ x ] < AbsMins[ x ] || Maxs[ y ] < AbsMins[ y ] || Maxs[ z ] < AbsMins[ z ] )
	{
	continue;
	}

	List[ Count ] = Entity;

	if ( Count++ >= ListMax )
	{
	return Count;
	}
}

return Count;
}


bool:UTIL_FVisible ( const Entity, const Other )
{
static Float:LookerOrigin[ Coord_e ];
static Float:TargetOrigin[ Coord_e ];
static Float:Fraction;
static LookerWLevel;
static TargetWLevel;

if ( pev( Other, pev_flags ) & FL_NOTARGET )
{
	return false;
}

LookerWLevel = pev ( Entity, pev_waterlevel );
TargetWLevel = pev ( Other, pev_waterlevel );

if ( ( LookerWLevel != 3 && TargetWLevel == 3 ) || ( LookerWLevel == 3 && TargetWLevel == 0  ) )
{
	return false;
}

UTIL_EyePosition ( Entity, LookerOrigin );
UTIL_EyePosition ( Other, TargetOrigin );

engfunc( EngFunc_TraceLine, LookerOrigin, TargetOrigin, IGNORE_MONSTERS | IGNORE_GLASS, Entity, 0 );
get_tr2( 0, TR_flFraction, Fraction );

return Fraction == 1.0 ? true : false;
}


bool:UTIL_FInViewCone ( const Entity, const Other )
{
static Float:Angles [ Coord_e ];
static Float:HOrigin[ Coord_e ];
static Float:Origin [ Coord_e ];

pev( Entity, pev_angles, Angles );
engfunc( EngFunc_MakeVectors, Angles );
global_get( glb_v_forward, Angles );

Angles[ z ] = 0.0;

pev( Entity, pev_origin, HOrigin );
pev( Other, pev_origin, Origin );

VectorSubtract ( Origin, HOrigin, Origin );
Origin[ z ] = 0.0;

VectorNormalize ( Origin, Origin );

if ( DotProduct ( Origin, Angles ) > pev( Entity, pev_fov ) )
{
	return true;
}

return false;
}


UTIL_EyePosition ( const Entity, Float:Origin[ Coord_e ] )
{
static Float:ViewOfs[ Coord_e ];

pev( Entity, pev_origin, Origin );
pev( Entity, pev_view_ofs, ViewOfs );

VectorAdd ( Origin, ViewOfs, Origin );
}


stock bool:UTIL_LiquidContents( const Float:Source[ Coord_e ] )
{
new Contents = point_contents( Source );
return ( Contents == CONTENTS_WATER || Contents == CONTENTS_SLIME || Contents == CONTENTS_LAVA );
}


VectorNormalize ( const Float:Source[ Coord_e ], Float:Output[ Coord_e ] )
{
static Float:InvLen;

InvLen = 1.0 / VectorLength ( Source );

Output[ x ] = Source[ x ] * InvLen;
Output[ y ] = Source[ y ] * InvLen;
Output[ z ] = Source[ z ] * InvLen;
}

// Give an item to a player (from fakemeta_util)
stock fm_give_item(id, const item[])
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if (!pev_valid(ent)) return;
	
	static Float:originF[3]
	pev(id, pev_origin, originF)
	set_pev(ent, pev_origin, originF)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)
	
	static save
	save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, id)
	if (pev(ent, pev_solid) != save)
		return;
	
	engfunc(EngFunc_RemoveEntity, ent)
}

// Strip user weapons (from fakemeta_util)
stock fm_strip_user_weapons(id)
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "player_weaponstrip"))
	if (!pev_valid(ent)) return;
	
	dllfunc(DLLFunc_Spawn, ent)
	dllfunc(DLLFunc_Use, ent, id)
	engfunc(EngFunc_RemoveEntity, ent)
}
// Update Player Frags and Deaths
UpdateFrags(attacker, frags, scoreboard)
{
	// Set attacker frags
	set_pev(attacker, pev_frags, float(pev(attacker, pev_frags) + frags))

	// Update scoreboard with attacker and victim info
	if (scoreboard)
	{
		message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
		write_byte(attacker) // id
		write_short(pev(attacker, pev_frags)) // frags
		write_short(cs_get_user_deaths(attacker)) // deaths
		write_short(0) // class?
		write_short(fm_cs_get_user_team(attacker)) // team
		message_end()
	}
}
stock fm_cs_get_user_team(id)
{
	return get_pdata_int(id, 114, 5);
}
public loadmoney(id)
{
	/*
	if (is_user_bot(id))
		set_pdata_int(id,OFFSET_MONEY,16000,OFFSET_LINUX)
	else 
		set_pdata_int(id,OFFSET_MONEY,0,OFFSET_LINUX)
	*/
	//static money;money=zp_get_user_ammo_packs(id)
	message_begin(MSG_ONE_UNRELIABLE, g_MsgMoney, _, id);
	write_long(zp_get_user_ammo_packs(id));
	write_byte(1);
	message_end();
	
}



