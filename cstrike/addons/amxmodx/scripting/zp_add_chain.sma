#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <zombieplague>
#include <toan>

#define Plugin    "[ZP] Extra Item: Chain grenade"
#define Version    "1.0"
#define Author    "https://fb.com/d.toan910"

// Модели гранаты
new const g_ViewModel[] = "models/v_chaingren.mdl"
new const g_PlayerModel[] = "models/p_chaingren.mdl"
new const g_WorldModel[] = "models/w_chaingren.mdl"

#define CHAIN_DAMAGE    random_float(1000.0, 1500.0)
#define MAXCARRY    2
#define RADIUS        100.0

#define MAXPLAYERS        32
#define pev_nade_type        pev_flTimeStepSound
#define NADE_TYPE_CHAIN    261517
#define AMMOID_HE        12

new g_iExplo, g_iExplo_, killcount[33]

new g_iChainGrenadeCount[MAXPLAYERS+1]
new g_iCurrentWeapon[MAXPLAYERS+1]
new g_msgAmmoPickup

public plugin_precache()
{
	precache_model(g_ViewModel)
	precache_model(g_PlayerModel)
	precache_model(g_WorldModel)
	
	g_iExplo = precache_model("sprites/eexplo.spr")
	g_iExplo_ = precache_model("sprites/fexplo.spr")
}

public plugin_init()
{
	register_plugin(Plugin, Version, Author)
	
	register_event("CurWeapon", "EV_CurWeapon", "be", "1=1")
	register_event("HLTV", "EV_NewRound", "a", "1=0", "2=0")
	//register_event("DeathMsg", "EV_DeathMsg", "a")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "fw_Item_Deploy_Post", 1)
	
	RegisterHam(Ham_Item_AddToPlayer, "weapon_hegrenade", "fw_Item_AddToPlayer")
	
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
}
public plugin_natives(){
	register_native("chaingrenade","get_chain", 1)
}
public get_chain(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id))
		return

	if(g_iChainGrenadeCount[id]>= MAXCARRY)
		return

	new iBpAmmo = cs_get_user_bpammo(id, CSW_HEGRENADE)
	
	if(g_iChainGrenadeCount[id]>= 1)
	{
		if(get_user_weapon(id) == CSW_HEGRENADE)
		{
			set_pev(id, pev_viewmodel2, g_ViewModel)
			set_pev(id, pev_weaponmodel2, g_PlayerModel)	
		}
		cs_set_user_bpammo(id, CSW_HEGRENADE, iBpAmmo+1)
		AmmoPickup(id, AMMOID_HE, 1)
		
		g_iChainGrenadeCount[id]++
	}
	else
	{
		if(get_user_weapon(id) == CSW_HEGRENADE)
		{
			set_pev(id, pev_viewmodel2, g_ViewModel)
			set_pev(id, pev_weaponmodel2, g_PlayerModel)	
		}
		give_item(id, "weapon_hegrenade")
		AmmoPickup(id, AMMOID_HE, 1)
		
		g_iChainGrenadeCount[id] = 1
	}
}
public zp_user_infected_post(id)
{
	g_iChainGrenadeCount[id] = 0
	killcount[id]=0
}

public EV_CurWeapon(id)
{
	if(!is_user_alive(id) || !zp_get_user_zombie(id))
		return PLUGIN_CONTINUE
		
	g_iCurrentWeapon[id] = read_data(2)
	if(g_iChainGrenadeCount[id]> 0 && g_iCurrentWeapon[id] == CSW_HEGRENADE)
	{
		set_pev(id, pev_viewmodel2, g_ViewModel)
		set_pev(id, pev_weaponmodel2, g_PlayerModel)
	}
	return PLUGIN_CONTINUE
}

public EV_NewRound()
{
	//arrayset(g_iChainGrenadeCount, 0, 33)
}

public fw_SetModel(Entity, const Model[])
{
	if(Entity <0 || !pev_valid(Entity))
		return FMRES_IGNORED
	
	if(pev(Entity, pev_dmgtime) == 0.0)
		return FMRES_IGNORED
	
	new iOwner = entity_get_edict(Entity, EV_ENT_owner)  
	
	if(g_iChainGrenadeCount[iOwner]>= 1 && equal(Model[7], "w_he", 4))
	{
		// Reset any other nade
		set_pev(Entity, pev_nade_type, 0)
		set_pev(Entity, pev_nade_type, NADE_TYPE_CHAIN)
		
		g_iChainGrenadeCount[iOwner]--
		entity_set_model(Entity, g_WorldModel)
		
		set_task(0.5, "explode_chain", Entity)
		set_task(1.0, "explode_chain", Entity)

		return FMRES_SUPERCEDE    
	}
	return FMRES_IGNORED
}
public explode_chain(Entity){
	if(!pev_valid(Entity))
		return;
	jumping_explode(Entity, 0)
}
public fw_ThinkGrenade(Entity)
{
	if(!pev_valid(Entity))
		return HAM_IGNORED
	
	static Float:dmg_time
	pev(Entity, pev_dmgtime, dmg_time)
	
	if(dmg_time> get_gametime())
		return HAM_IGNORED
	
	if(pev(Entity, pev_nade_type) == NADE_TYPE_CHAIN)
	{
		jumping_explode(Entity, 1)
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

public jumping_explode(Entity, remove)
{
	if(Entity <0)
		return
	
	static Float:flOrigin[3], a = FM_NULLENT;
	pev(Entity, pev_origin, flOrigin)

	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, flOrigin[0])
	engfunc(EngFunc_WriteCoord, flOrigin[1])
	engfunc(EngFunc_WriteCoord, flOrigin[2]+40.0)
	write_short(g_iExplo)	// sprite index
	write_byte(23)	// scale in 0.1's
	write_byte(30)	// framerate
	write_byte(0)	// flags
	message_end()

	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, flOrigin[0])
	engfunc(EngFunc_WriteCoord, flOrigin[1])
	engfunc(EngFunc_WriteCoord, flOrigin[2]+40.0)
	write_short(g_iExplo_)	// sprite index
	write_byte(23)	// scale in 0.1's
	write_byte(30)	// framerate
	write_byte(0)	// flags
	message_end()

	new Attacker;Attacker = entity_get_edict(Entity, EV_ENT_owner)  
	while((a = find_ent_in_sphere(a, flOrigin, RADIUS+50.0)) != 0)
	{
		if (Attacker == a)
			continue 
		if(!is_user_alive(a))
			continue	
		if(!zp_get_user_zombie(a))
			continue	
		if(pev(a, pev_takedamage) != DAMAGE_NO)
		{
			ExecuteHamB(Ham_TakeDamage, a, Attacker, Attacker, is_deadlyshot(Attacker)?CHAIN_DAMAGE*1.5:CHAIN_DAMAGE, DMG_BULLET);
		}
	}
	if(remove)
		engfunc(EngFunc_RemoveEntity, Entity)
}       
public fw_Item_Deploy_Post(weapon_ent)
{
	static owner
	owner = get_pdata_cbase(weapon_ent, 41, 4)
	
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	if(weaponid == CSW_HEGRENADE && g_iChainGrenadeCount[owner] > 0){
		set_pev(owner, pev_viewmodel2, g_ViewModel)
		set_pev(owner, pev_weaponmodel2, g_PlayerModel)	
	}
}
public fw_Item_AddToPlayer(ent, id){
	if(!is_valid_ent(ent) || !is_user_connected(id))
		return HAM_IGNORED

	static weaponid
	weaponid = cs_get_weapon_id(ent)

	if(weaponid == CSW_HEGRENADE && g_iChainGrenadeCount[id] > 0){
		set_pev(id, pev_viewmodel2, g_ViewModel)
		set_pev(id, pev_weaponmodel2, g_PlayerModel)	
	}
	
	return HAM_IGNORED
}
public AmmoPickup(id, AmmoID, AmmoAmount)
{
	message_begin(MSG_ONE, g_msgAmmoPickup, _, id)
	write_byte(AmmoID)
	write_byte(AmmoAmount)
	message_end()
}

public Player_Spawn(id)
{
	killcount[id]=0
}
public EV_DeathMsg(id)
{
	new ikiller = read_data(1)
	new ivictim = read_data(2)
	
	if (!is_user_alive(ikiller))
		return PLUGIN_HANDLED
	if (ikiller == ivictim)
		return PLUGIN_HANDLED
	if (zp_get_user_zombie(ikiller))
		return PLUGIN_HANDLED

	if(!is_user_connected(ivictim))
		return PLUGIN_HANDLED
	
	g_iChainGrenadeCount[ivictim] = 0

	killcount[ikiller]++
	
	if (killcount[ikiller]>=is_user_bot(ikiller)?5:10)
	{
		get_chain(ikiller)
		killcount[ikiller]=0	
	}
	return PLUGIN_HANDLED
} 
