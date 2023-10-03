#include < amxmodx >
#include < cstrike >
#include < engine >
#include <fakemeta_util>
#include < fun >
#include < engine >
#include < hamsandwich >
#include < zombieplague >

#define Plugin    "[ZP] Extra Item: Jump Bomb"
#define Version    "1.2"
#define Author    "Zombie-rus"

#define KNOCK_POWER 900.0

// Модели гранаты
new const g_ViewModel[] = "models/zombie_plague/v_zombibomb.mdl"
new const g_PlayerModel[] = "models/zombie_plague/p_zombibomb.mdl"
new const g_WorldModel[] = "models/zombie_plague/w_zombibomb.mdl"

//Звук взрыва
new const g_SoundBombExplode[][] = { "zombie_plague/zombi_bomb_exp.wav" }

new const g_szItemName[] = "Knock-back Bomb" // Имя айтема

new const g_iItemPrice = 2000 // Стоимость за 1 бомбу

#define MAXCARRY    5 // Лимит гранат
#define RADIUS        500.0 // Радиус взрыва

#define MAXPLAYERS        32
#define pev_nade_type        pev_flTimeStepSound
#define NADE_TYPE_JUMPING    26517
#define AMMOID_SM        13

new g_iExplo
new g_iNadeID

new g_iJumpingNadeCount[MAXPLAYERS+1]
new g_iCurrentWeapon[MAXPLAYERS+1]

new g_msgScreenShake

new g_MaxPlayers
new g_msgAmmoPickup

const UNIT_SECOND = (1<<12)

public plugin_precache ()
{
	precache_model(g_ViewModel)
	precache_model(g_PlayerModel)
	precache_model(g_WorldModel)
	
	new i
	for(i = 0; i < sizeof g_SoundBombExplode; i++)
		precache_sound(g_SoundBombExplode[i])
	
	g_iExplo = precache_model("sprites/zombiebomb_exp.spr") // Спрайт взрыва
}

public plugin_init ()
{
	register_plugin(Plugin, Version, Author)
	
	g_iNadeID = zp_register_extra_item(g_szItemName, g_iItemPrice, ZP_TEAM_ZOMBIE)
	
	register_event("CurWeapon", "EV_CurWeapon", "be", "1=1")
	register_event("HLTV", "EV_NewRound", "a", "1=0", "2=0")
	register_event("DeathMsg", "EV_DeathMsg", "a")
	
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	
	g_msgScreenShake = get_user_msgid("ScreenShake")
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
	g_MaxPlayers = get_maxplayers ()
}

public client_connect(id)
{
	g_iJumpingNadeCount[id] = 0
}
public plugin_natives(){
	register_native("KnockbackNade", "get_JumpNade", 1)
	register_native("is_max_KnockbackNade", "count_JumpNade", 1)
}
public zp_extra_item_selected(id, Item)
{
	if(Item == g_iNadeID)
	{
		get_JumpNade(id)
	}
}
public get_JumpNade (id)
{
	if(g_iJumpingNadeCount[id] >= MAXCARRY)
	{
		return ZP_PLUGIN_HANDLED
	}        
	new iBpAmmo = cs_get_user_bpammo(id, CSW_SMOKEGRENADE)

 	g_iJumpingNadeCount[id] = iBpAmmo
	if(g_iJumpingNadeCount[id] >= 1)
	{
		cs_set_user_bpammo(id, CSW_SMOKEGRENADE, iBpAmmo+1)
		AmmoPickup(id, AMMOID_SM, 1)
		
		g_iJumpingNadeCount[id]++
	}
	else
	{
		give_item(id, "weapon_smokegrenade")			
		AmmoPickup(id, AMMOID_SM, 1)
		
		g_iJumpingNadeCount[id] = 1
	}
	return PLUGIN_CONTINUE
}

public zp_user_humanized_post (id)
{
	g_iJumpingNadeCount[id] = 0
}

public count_JumpNade (id)
{
	if(g_iJumpingNadeCount[id] >= MAXCARRY)
		return true

	return false
}

public EV_CurWeapon(id)
{
	if(!is_user_alive(id) || !zp_get_user_zombie(id))
		return PLUGIN_CONTINUE
		
	g_iCurrentWeapon[id] = read_data(2)
	if(g_iJumpingNadeCount[id] > 0 && g_iCurrentWeapon[id] == CSW_SMOKEGRENADE)
	{
		set_pev(id, pev_viewmodel2, g_ViewModel)
		set_pev(id, pev_weaponmodel2, g_PlayerModel)
	}
	return PLUGIN_CONTINUE
}

public EV_NewRound ()
{
	arrayset(g_iJumpingNadeCount, 0, 33)
}

public EV_DeathMsg ()
{
	new iVictim = read_data(2)
	
	if(!is_user_connected(iVictim))
		return
	
	g_iJumpingNadeCount[iVictim] = 0
}

public fw_SetModel(Entity, const Model[])
{
	if(Entity < 0)
		return FMRES_IGNORED
	
	if(pev(Entity, pev_dmgtime) == 0.0)
		return FMRES_IGNORED
	
	new iOwner = entity_get_edict(Entity, EV_ENT_owner)   
	
	if(g_iJumpingNadeCount[iOwner] >= 1 && equal(Model[7], "w_sm", 4))
	{
		// Reset any other nade
		set_pev(Entity, pev_nade_type, 0)
		
		set_pev(Entity, pev_nade_type, NADE_TYPE_JUMPING)
		set_pev(Entity, pev_owner, iOwner)
		
		g_iJumpingNadeCount[iOwner]--
		entity_set_model(Entity, g_WorldModel)
		
		return FMRES_SUPERCEDE    
	}
	return FMRES_IGNORED
}
public fw_ThinkGrenade(Entity)
{
	if(!pev_valid(Entity))
		return HAM_IGNORED
	
	static Float:dmg_time
	pev(Entity, pev_dmgtime, dmg_time)
	
	if(dmg_time > get_gametime ())
		return HAM_IGNORED
	
	if(pev(Entity, pev_nade_type) == NADE_TYPE_JUMPING)
	{
		jumping_explode(Entity)
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

public jumping_explode(Entity)
{
	if(Entity < 0)
		return
	
	static Float:flOrigin[3]
	pev(Entity, pev_origin, flOrigin)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, flOrigin[0])
	engfunc(EngFunc_WriteCoord, flOrigin[1])
	engfunc(EngFunc_WriteCoord, flOrigin[2] + 45.0)
	write_short(g_iExplo)
	write_byte(35)
	write_byte(186)
	message_end ()
	
	emit_sound(Entity, CHAN_WEAPON, g_SoundBombExplode[random_num(0, sizeof g_SoundBombExplode-1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	new id;id = pev(Entity, pev_owner)

	for(new i = 1; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive (i))
			continue
		
		new Float:flVictimOrigin[3]
		pev(i, pev_origin, flVictimOrigin)
		
		new Float:flDistance = get_distance_f(flOrigin, flVictimOrigin)   
		
		if(flDistance <= RADIUS)
		{
			static Float:flSpeed
			flSpeed = KNOCK_POWER
			
			static Float:flNewSpeed
			flNewSpeed = flSpeed *(1.0 -(flDistance / RADIUS))
			
			static Float:flVelocity[3]
			flVictimOrigin[2] += 10.0
			get_speed_vector(flOrigin, flVictimOrigin, flNewSpeed, flVelocity)
			
			set_pev(i, pev_velocity,flVelocity)
			
			message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, i)
			write_short(8<<12)
			write_short(1<<12)
			write_short(4<<12)
			message_end()	
			
			//fm_fakedamage(i, "knockback-bomb", 100.0,  DMG_BLAST);
			ExecuteHam(Ham_TakeDamage, i, id, id, 80.0, DMG_BLAST);
		}
	}
	
	engfunc(EngFunc_RemoveEntity, Entity)
}       

public AmmoPickup(id, AmmoID, AmmoAmount)
{
	message_begin(MSG_ONE, g_msgAmmoPickup, _, id)
	write_byte(AmmoID)
	write_byte(AmmoAmount)
	message_end ()
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
