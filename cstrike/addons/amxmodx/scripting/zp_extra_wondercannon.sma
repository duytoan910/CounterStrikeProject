#include <amxmodx>
#include <cstrike>
#include <engine>
#include <xs>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <zombieplague>
#include <gunxpmod>

#define V_MODEL "models/v_wondercannon.mdl"
#define P_MODEL "models/p_wondercannon.mdl"
#define W_MODEL "models/w_wondercannon.mdl"

#define FIRE_SOUND "weapons/wondercannon_shoot1.wav"

#define CSW_WONDERCANNON CSW_M249
#define weapon_wondercannon "weapon_m249"
#define OLD_W_MODEL "models/w_m249.mdl"
#define OLD_EVENT "events/m249.sc"

#define WC_EXP_DAMAGE 65.4
#define WC_EXP_DELAY 0.45
#define WC_EXP_RADIUS 80.0

#define WC_MINE_DAMAGE 2325.0
#define WC_MINE_RADIUS 50.0

#define WC_RELOAD 2.0
#define WC_CLIP 30
#define WC_BP 200
#define WC_RECOIL 0.2
#define WC_SPEED 0.7

#define ANIM_RELOAD	1
#define ANIM_DRAW	2
#define ANIM_SHOOT1	3
#define ANIM_SHOOT2	4
#define ANIM_SHOOT3	5
#define ANIM_BMODE_ON	6
#define ANIM_CMODE_ST	7
#define ANIM_CMODE_ID	8
#define ANIM_CMODE_SH	9

#define MINE_CLASSNAME "WCMINE"
#define MAX_PLAYERS 32
#define WEAPONKEY 14969

new const Mine_Model[] = "models/bomb_wondercannon.mdl"
new const WeaponSprites[][]={
	"sprites/ef_wondercannon_hit.spr",
	"sprites/ef_wondercannon_hit1.spr",
	"sprites/ef_wondercannon_hit4.spr",
	"sprites/ef_wondercannon_hit2.spr",
	"sprites/ef_wondercannon_hit3.spr",
	"sprites/ef_wondercannon_bomb_ex.spr",
	"sprites/ef_wondercannon_bomb_set.spr",
	"sprites/ef_wondercannon_bomb_ex.spr"
}
new const WeaponSounds[][]={
	"weapons/wondercannon_bomd_exp.wav",
	"weapons/wondercannon_bomd_exp2.wav",
	"weapons/wondercannon_comd_shoot.wav",
	"weapons/wondercannon_comd_drop.wav",
	"weapons/wondercannon_cmod_charging.wav",
	"weapons/wondercannon_bomd_on_exp.wav"
}

native navtive_bullet_effect(id, ent, ptr)

new g_itemid,g_has_wondercannon[33],g_orign_wondercannon
new g_weapon_TmpClip[33],oldweap[33],g_HamBot
new g_exp_id[sizeof(WeaponSprites)], g_cmode[33]
new count[33],m_iBlood[2]

public plugin_init()
{
	register_plugin("Weapon Heaven Splitter", "1.0", "lol")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")

	register_think(MINE_CLASSNAME, "fw_Think")
	register_touch(MINE_CLASSNAME, "*", "fw_Touch")
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_wondercannon, "HAM_AddToPlayer")
	RegisterHam(Ham_Item_Deploy, weapon_wondercannon, "HAM_Item_Deploy_Post",1)
	RegisterHam(Ham_Item_PostFrame, weapon_wondercannon, "HAM_ItemPostFrame");
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_wondercannon, "HAM_Idle_Post", 1)
	RegisterHam(Ham_Weapon_Reload, weapon_wondercannon, "HAM_Reload");
	RegisterHam(Ham_Weapon_Reload, weapon_wondercannon, "HAM_Reload_Post", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_wondercannon, "HAM_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_wondercannon, "HAM_PrimaryAttack_Post", 1)
	
	RegisterHam(Ham_TakeDamage, "player", "HAM_TakeDamage")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")	

	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "Fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "Fw_PlaybackEvent")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")	
	
	g_itemid = zp_register_extra_item("Heaven Splitter", 10000, ZP_TEAM_HUMAN)
}

public plugin_precache()
{
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_model(W_MODEL)
	precache_sound(FIRE_SOUND)	
	precache_model(Mine_Model)
	
	static i;
	for(i=0;i<sizeof(WeaponSprites);i++)
	g_exp_id[i] = engfunc(EngFunc_PrecacheModel, WeaponSprites[i])
	for(i = 0; i < sizeof(WeaponSounds); i++) 
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])	
	m_iBlood[0] = precache_model("sprites/blood.spr");
	m_iBlood[1] = precache_model("sprites/bloodspray.spr");	
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)	
}
public plugin_natives()
{
	register_native("get_wondercannon","give_wondercannon")
}
public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(OLD_EVENT, name))
		g_orign_wondercannon = get_orig_retval()
}
public client_putinserver(id)
{
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Do_RegisterHam", id)
	}
}

public Do_RegisterHam(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "HAM_TakeDamage")
	RegisterHamFromEntity(Ham_Spawn, id, "Player_Spawn")
}
public client_connect(id) 
{
	g_has_wondercannon[id] = false
	g_cmode[id] = false
}

public client_disconnect(id) 
{
	g_has_wondercannon[id] = false
	g_cmode[id] = false
}

public zp_user_humanized_post(id) 
{
	g_has_wondercannon[id] = false
	g_cmode[id] = false
}

public zp_user_infected_post(id) 
{
	g_has_wondercannon[id] = false
	g_cmode[id] = false
}

public Player_Spawn(id)
{
	g_has_wondercannon[id] = false
	g_cmode[id] = false
}
public zp_extra_item_selected(id, itemid) 
{
	//give_wondercannon(id)
	if(itemid == g_itemid)
	{
		g_cmode[id] = false
		count[id]=0
		drop_weapons(id, 1);
		g_has_wondercannon[id] = true;
		
		new iWep2 = give_item(id,weapon_wondercannon)
		if( iWep2 > 0 )
		{
			cs_set_weapon_ammo(iWep2, WC_CLIP)
			cs_set_user_bpammo (id, CSW_WONDERCANNON, WC_BP)
			UTIL_PlayWeaponAnimation(id, ANIM_DRAW)
		}
	}	
}

public give_wondercannon(id)
{
	drop_weapons(id, 1);
	count[id]=0
	g_has_wondercannon[id] = true
	new iWep2 = give_item(id,weapon_wondercannon)
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, WC_CLIP)
		cs_set_user_bpammo (id, CSW_WONDERCANNON, WC_BP)
		UTIL_PlayWeaponAnimation(id,ANIM_DRAW)
	}
}
public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_WONDERCANNON || !g_has_wondercannon[Attacker])
		return HAM_IGNORED
		
	navtive_bullet_effect(Attacker, Victim, Ptr)
	
	return HAM_HANDLED
}
public fw_TraceAttack_Player(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_WONDERCANNON || !g_has_wondercannon[Attacker])
		return HAM_IGNORED
	
	return HAM_HANDLED
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED;
		
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED;
		
	static iOwner
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, OLD_W_MODEL))
	{
		static iStoredSVDID
		iStoredSVDID = find_ent_by_owner(-1, weapon_wondercannon, entity)
		
		if(!is_valid_ent(iStoredSVDID))
			return FMRES_IGNORED;
			
		if(g_has_wondercannon[iOwner])
		{
			entity_set_int(iStoredSVDID, EV_INT_impulse, WEAPONKEY)
			g_has_wondercannon[iOwner] = false
			
			entity_set_model(entity, W_MODEL)
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

public HAM_AddToPlayer(weapon, id)
{
	/*if(!is_valid_ent(weapon) || !is_user_connected(id))
		return HAM_IGNORED;
	if(entity_get_int(weapon, EV_INT_impulse) == WEAPONKEY)
	{
		g_has_wondercannon[id] = true
		g_cmode[id] = false
		entity_set_int(weapon, EV_INT_impulse, 0)
		return HAM_HANDLED;
	}
	return HAM_IGNORED;*/
	if(!is_valid_ent(weapon) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(weapon, EV_INT_impulse) == WEAPONKEY)
	{
		g_has_wondercannon[id] = true
		g_cmode[id] = false
		
		entity_set_int(weapon, EV_INT_impulse, 0)		
	}
	return HAM_IGNORED
}

public HAM_Item_Deploy_Post(weapon_ent)
{
	new id = pev(weapon_ent,pev_owner)
	if (!is_user_connected(id) || zp_get_user_zombie(id) || zp_get_user_survivor(id))
		return;
	if(get_user_weapon(id) != CSW_WONDERCANNON || !g_has_wondercannon[id])
		return;
		
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	
	replace_weapon_models(id, weaponid)
	UTIL_PlayWeaponAnimation(id,ANIM_DRAW)
	
	set_pdata_float(id, 83, 0.8)
	set_weapons_timeidle(id, CSW_WONDERCANNON, 0.8)
}

public fw_CmdStart(id, uc_handle, seed) 
{
	new ammo, clip, weapon = get_user_weapon(id, clip, ammo)
	if (!g_has_wondercannon[id] || weapon != CSW_WONDERCANNON || !is_user_alive(id))
		return
	
	if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)) 
	{
		if(!g_cmode[id])
		{
			UTIL_PlayWeaponAnimation(id,ANIM_CMODE_ST)
			set_pdata_float(id, 83, 1.0)
			set_weapons_timeidle(id, CSW_WONDERCANNON, 1.0)
			g_cmode[id]=true
			
			return			
		}	
	}
}
public CurrentWeapon(id)
{
	if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
		return;
	replace_weapon_models(id, read_data(2))
	
	if(read_data(2) != CSW_WONDERCANNON || !g_has_wondercannon[id])
		return	
	static Float:iSpeed
	if(g_has_wondercannon[id])
	iSpeed = WC_SPEED
	
	static weapon[32],Ent
	get_weaponname(read_data(2),weapon,31)
	Ent = find_ent_by_owner(-1,weapon,id)
	if(Ent)
	{
		static Float:Delay
		Delay = get_pdata_float( Ent, 46, 4) * iSpeed
		
		if (Delay > 0.0)
		{
			set_pdata_float(Ent, 46, Delay, 4)
          }
     }
}

public HAM_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_WONDERCANNON)
		{
			if(g_has_wondercannon[attacker])
			{			
				SetHamParamFloat(4, 0.0)
				CheckEnemy(attacker,victim)
			}

		}
	}
}

public HAM_ItemPostFrame(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;
		
	if (!g_has_wondercannon[id])
		return HAM_IGNORED;
		
	new Float:flNextAttack = get_pdata_float(id, 83, 5)
	new iBpAmmo = cs_get_user_bpammo(id, CSW_WONDERCANNON);
	new iClip = get_pdata_int(weapon_entity, 51, 4)
	new fInReload = get_pdata_int(weapon_entity,54, 4)
	
	if( fInReload && flNextAttack <= 0.02 )
	{
		new j = min(WC_CLIP - iClip, iBpAmmo)
		set_pdata_int(weapon_entity, 51, iClip + j, 4)
		cs_set_user_bpammo(id, CSW_WONDERCANNON, iBpAmmo-j);
		set_pdata_int(weapon_entity, 54, 0, 4)
		fInReload = 0
	}
	return HAM_IGNORED;
}

public HAM_Idle_Post(Weapon)
{
	new id = get_pdata_cbase(Weapon, 41, 4)

	if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_has_wondercannon[id] || get_user_weapon(id) != CSW_WONDERCANNON)
		return HAM_IGNORED;

	if(g_cmode[id] == 0 && get_pdata_float(Weapon, 48, 4) <= 0.25)
	{
		UTIL_PlayWeaponAnimation(id, 0)
		set_pdata_float(Weapon, 48, 60.0, 4)
		//set_pev(id, pev_skin, 0)
		
		return HAM_SUPERCEDE;
	}
	else if(g_cmode[id] == 1 && get_pdata_float(Weapon, 48, 4) <= 0.25)
	{
		UTIL_PlayWeaponAnimation(id, ANIM_CMODE_ID)
		set_pdata_float(Weapon, 48, 60.0, 4)
		//set_pev(id, pev_skin, 0)
		
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}
public HAM_PrimaryAttack(weapon)
{
	new Player = get_pdata_cbase(weapon, 41, 4)	
	if (!g_has_wondercannon[Player])
		return HAM_IGNORED
		
	if(g_cmode[Player]) return HAM_SUPERCEDE
	return HAM_IGNORED			
}
public HAM_PrimaryAttack_Post(wpn) 
{
	new id = pev(wpn, pev_owner), clip, bpammo
	get_user_weapon(id, clip, bpammo)
	if(g_has_wondercannon[id]) 
	{
		if(!g_cmode[id])
		{
			if(clip > 0) 
			{			
				UTIL_PlayWeaponAnimation(id, random_num(ANIM_SHOOT1,ANIM_SHOOT3))
				emit_sound(id, CHAN_WEAPON, FIRE_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM)
				count[id]++
								
				//set_pdata_float(id, 83, 0.8)
				set_weapons_timeidle(id, CSW_WONDERCANNON, 0.8)
				if(is_user_bot(id)&&count[id]>=30)
				{
					UTIL_PlayWeaponAnimation(id, ANIM_SHOOT3)
					ShotMine(id)
					emit_sound(id, CHAN_WEAPON, WeaponSounds[2], 1.0, ATTN_NORM, 0, PITCH_NORM)
					set_pdata_float(id, 83, 1.0)
					count[id]=0
				}
				set_pdata_int(wpn, 51, clip-1, 4)
			}			
		}else{
			UTIL_PlayWeaponAnimation(id, ANIM_SHOOT3)
			ShotMine(id)
			emit_sound(id, CHAN_WEAPON, WeaponSounds[2], 1.0, ATTN_NORM, 0, PITCH_NORM)
			set_pdata_float(id, 83, 1.0)
			g_cmode[id]=0
			return;	
		}
	}
}
public CheckEnemy(id,victim)
{
	if(get_user_weapon(id) != CSW_WONDERCANNON || !g_has_wondercannon[id])
		return
	if(is_user_alive(victim))
	{				
		new paramN[3],idTemp
		paramN[0] = id
		paramN[1] = victim
		paramN[2] = 0;				
		
		//0
		DoExplope(paramN)
		idTemp = FindZombie(victim,-1)
		paramN[1] = idTemp
		DoExplope(paramN)
		idTemp = FindZombie(victim,idTemp)
		paramN[1] = idTemp
		DoExplope(paramN);
		
		//1
		paramN[1] = victim;paramN[2]=1
		set_task(WC_EXP_DELAY*1,"DoExplope",12345,paramN,sizeof(paramN));		
		idTemp = FindZombie(victim,-1);
		paramN[1] = idTemp
		set_task(WC_EXP_DELAY*1,"DoExplope",12345,paramN,sizeof(paramN));		
		idTemp = FindZombie(victim,idTemp);
		paramN[1] = idTemp
		set_task(WC_EXP_DELAY*1,"DoExplope",12345,paramN,sizeof(paramN));	
		
		//2
		paramN[1] = victim;paramN[2]=2
		set_task(WC_EXP_DELAY*2,"DoExplope",12345,paramN,sizeof(paramN));		
		idTemp = FindZombie(victim,-1);
		paramN[1] = idTemp
		set_task(WC_EXP_DELAY*2,"DoExplope",12345,paramN,sizeof(paramN));		
		idTemp = FindZombie(victim,idTemp);
		paramN[1] = idTemp
		set_task(WC_EXP_DELAY*2,"DoExplope",12345,paramN,sizeof(paramN));	
		
		//3
		paramN[1] = victim;paramN[2]=3
		set_task(WC_EXP_DELAY*3,"DoExplope",12345,paramN,sizeof(paramN));		
		idTemp = FindZombie(victim,-1);
		paramN[1] = idTemp
		set_task(WC_EXP_DELAY*3,"DoExplope",12345,paramN,sizeof(paramN));		
		idTemp = FindZombie(victim,idTemp);
		paramN[1] = idTemp
		set_task(WC_EXP_DELAY*3,"DoExplope",12345,paramN,sizeof(paramN));	
		
		//4
		paramN[1] = victim;paramN[2]=4
		set_task(WC_EXP_DELAY*4,"DoExplope",12345,paramN,sizeof(paramN));		
		idTemp = FindZombie(victim,-1);
		paramN[1] = idTemp
		set_task(WC_EXP_DELAY*4,"DoExplope",12345,paramN,sizeof(paramN));		
		idTemp = FindZombie(victim,idTemp);
		paramN[1] = idTemp
		set_task(WC_EXP_DELAY*4,"DoExplope",12345,paramN,sizeof(paramN));	
		
	}
}
public DoExplope(paramN[0])
{
	//client_print(1, print_chat,"Victim: %i", paramN[1])
	new attacker;attacker = paramN[0]
	new victim;victim = paramN[1]
	new Stage;Stage = paramN[2]
	
	static Float:Origin[3]	
	pev(victim, pev_origin, Origin)
	
	//client_print(1, print_chat, "Target: [%i]", victim)
	new TE_FLAG
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	TE_FLAG |= TE_EXPLFLAG_NOSOUND

	if(victim==0)
		return;
	if(!is_user_alive(victim))
		return;
	// Draw explosion
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION) // Temporary entity ID
	if(Stage<2)
	{
		engfunc(EngFunc_WriteCoord, Origin[0]+=random_float(-10.0,10.0)) // engfunc because float
		engfunc(EngFunc_WriteCoord, Origin[1]+=random_float(-10.0,10.0))
		engfunc(EngFunc_WriteCoord, Origin[2]+=random_float(-10.0,10.0))
		write_short(g_exp_id[Stage]) // Sprite index
		write_byte(5) // Scale
		write_byte(25) // Framerate}
	}else{
		engfunc(EngFunc_WriteCoord, Origin[0]+=random_float(-10.0,10.0)) // engfunc because float
		engfunc(EngFunc_WriteCoord, Origin[1]+=random_float(-10.0,10.0))
		engfunc(EngFunc_WriteCoord, Origin[2]-=10.0)
		write_short(g_exp_id[Stage]) // Sprite index
		write_byte(6) // Scale
		write_byte(35) // Framerate		
	}
	write_byte(TE_FLAG) // Flags
	message_end();	
	
	static Float:damage,Float:multi
	if(is_user_bot(attacker))
		multi=get_cvar_float("zp_human_damage_reward")*2
	else multi = get_cvar_float("zp_human_damage_reward")	
	
	damage = is_deadlyshot(attacker)?random_float(WC_EXP_DAMAGE-10,WC_EXP_DAMAGE+10)+1.5:random_float(WC_EXP_DAMAGE-10,WC_EXP_DAMAGE+10)
	new a = FM_NULLENT, Float:aOrg[3]
	while((a = find_ent_in_sphere(a, Origin, WC_EXP_RADIUS)) != 0)
	{
		if(attacker == a)continue 
		if(!is_user_alive(a))continue
		if(!zp_get_user_zombie(a))continue
		pev(a, pev_origin, aOrg)
		make_blood(aOrg)
		
		emit_sound(a, CHAN_WEAPON, WeaponSounds[random_num(0,1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
		ExecuteHam(Ham_TakeDamage, a, attacker, attacker, damage, DMG_BULLET)
		zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + floatround(floatround(damage*multi) * 0.1))
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Money"), _, attacker);
		write_long(zp_get_user_ammo_packs(attacker));
		write_byte(1);
		message_end();
	}
}
public ShotMine(id)
{
	new Float:origin[3],Float:velocity[3],Float:angles[3]
	engfunc(EngFunc_GetAttachment, id, 0, origin,angles)
	pev(id,pev_angles,angles)
	new ent = create_entity("info_target") 
	angles[0]-=90
	set_pev(ent, pev_classname, MINE_CLASSNAME)
	set_pev(ent, pev_solid, SOLID_BBOX)
	set_pev(ent, pev_movetype, MOVETYPE_TOSS)
	set_pev(ent, pev_mins, { -0.1, -0.1, -0.1 })
	set_pev(ent, pev_maxs, { 0.1, 0.1, 0.1 })
	entity_set_model(ent, Mine_Model)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_angles, angles)
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_solid, SOLID_BBOX)
	set_pev(ent, pev_fuser1, -1.0)
	
	velocity_by_aim(id, 500 , velocity)
	set_pev(ent, pev_velocity, velocity)
	
	//set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	
	return PLUGIN_CONTINUE
}

public fw_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return

	new pevAttacker = pev(iEnt, pev_owner);
	if(!is_user_connected(pevAttacker) || !is_user_alive(pevAttacker) || !g_has_wondercannon[pevAttacker])
	{
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
		return
	}
	if(!pev_valid(iEnt)) return;
	if(pev(iEnt, pev_flags) & FL_KILLME) return;
	
	if(pev(iEnt, pev_fuser1)+1 < get_gametime())
	{
		new Float:Origin[3];
		pev(iEnt, pev_origin, Origin)
		
		new TE_FLAG
		TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
		TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
		TE_FLAG |= TE_EXPLFLAG_NOSOUND
	
		emit_sound(iEnt, CHAN_WEAPON, WeaponSounds[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		// Draw explosion
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION) // Temporary entity ID
		engfunc(EngFunc_WriteCoord, Origin[0]) // engfunc because float
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2]-2.0)
		write_short(g_exp_id[6]) // Sprite index
		write_byte(2) // Scale
		write_byte(100) // Framerate
		write_byte(TE_FLAG) // Flags
		message_end();
		
		DoExplopeMine(iEnt)
	}
	set_pev(iEnt, pev_nextthink, halflife_time() + 0.1)	
}
public fw_Touch(ent, id)
{
	if(!pev_valid(ent))
		return
	
	static Float:Origin[3],Float:Origin2[3],Float:Vector[3],Float:Angles[3]
	pev(ent, pev_origin, Origin)
	
	Origin2[0] = Origin[0]
	Origin2[1] = Origin[1]
	Origin2[2] = Origin[2]+100.0
	
	get_speed_vector ( Origin, Origin2, 20.0, Vector )	
	vector_to_angle(Vector,Angles)
	Angles[0]-=90
	set_pev(ent, pev_angles, Angles)
	
	set_pev(ent, pev_sequence, 0)
	set_pev(ent, pev_animtime, get_gametime())
	set_pev(ent, pev_framerate, 1.0)
	set_pev(ent, pev_fuser1, get_gametime())
	
	if(is_user_alive(id))
		DoExplopeMine(ent)
	
	emit_sound(ent, CHAN_WEAPON, WeaponSounds[3], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_solid, SOLID_NOT)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.5)
}
public DoExplopeMine(iEnt)
{
	if(!pev_valid(iEnt))
		return

	new Float:Origin[3];
	pev(iEnt, pev_origin, Origin)		
	new pevAttacker = pev(iEnt, pev_owner);	
	// Alive...
	new a = FM_NULLENT
	// Get distance between victim and epicenter
	while((a = find_ent_in_sphere(a, Origin, WC_MINE_RADIUS)) != 0)
	{
		if(!is_user_alive(a))continue
		if(pev(a, pev_takedamage) != DAMAGE_NO)
		{
			
			new TE_FLAG
			TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
			TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
			TE_FLAG |= TE_EXPLFLAG_NOSOUND			
			// Draw explosion
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION) // Temporary entity ID
			engfunc(EngFunc_WriteCoord, Origin[0]) // engfunc because float
			engfunc(EngFunc_WriteCoord, Origin[1])
			engfunc(EngFunc_WriteCoord, Origin[2]+50.0)
			write_short(g_exp_id[3]) // Sprite index
			write_byte(10) // Scale
			write_byte(30) // Framerate
			write_byte(TE_FLAG) // Flags
			message_end();
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION) // Temporary entity ID
			engfunc(EngFunc_WriteCoord, Origin[0]) // engfunc because float
			engfunc(EngFunc_WriteCoord, Origin[1])
			engfunc(EngFunc_WriteCoord, Origin[2]+50.0)
			write_short(g_exp_id[4]) // Sprite index
			write_byte(10) // Scale
			write_byte(30) // Framerate
			write_byte(TE_FLAG) // Flags
			message_end();
			
			emit_sound(iEnt, CHAN_WEAPON, WeaponSounds[5], 1.0, ATTN_NORM, 0, PITCH_NORM)
			emit_sound(a, CHAN_WEAPON, WeaponSounds[random_num(0,1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			new Float:flVictimOrigin[3], Float:flVelocity[3]
			pev ( a, pev_origin, flVictimOrigin )
			//new Float:flDistance = get_distance_f ( Origin, flVictimOrigin )   
			static Float:flSpeed = 450.0
			if(a==pevAttacker) flSpeed = 800.0
			
			if(zp_get_user_zombie(a))
			{				
				ExecuteHam(Ham_TakeDamage, a, pevAttacker, pevAttacker, random_float(WC_MINE_DAMAGE-10,WC_MINE_DAMAGE+10), DMG_BULLET)	
				flVictimOrigin[2]+=50.0
				get_speed_vector ( Origin, flVictimOrigin, flSpeed, flVelocity )			
				set_pev ( a, pev_velocity,flVelocity )
			}else if(pevAttacker==a){
				flVictimOrigin[2]+=50.0
				get_speed_vector ( Origin, flVictimOrigin, flSpeed, flVelocity )
				set_pev(a, pev_velocity, flVelocity)
			}
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
		}
	}					
}

public HAM_Reload(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;
		
	if (!g_has_wondercannon[id])
		return HAM_IGNORED;
		
	g_weapon_TmpClip[id] = -1;
	
	new iBpAmmo = cs_get_user_bpammo(id, CSW_WONDERCANNON);
	new iClip = get_pdata_int(weapon_entity, 51, 4)
	
	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE;
		
	if (iClip >= WC_CLIP)
		return HAM_SUPERCEDE;
		
	g_weapon_TmpClip[id] = iClip;
	return HAM_IGNORED;
}

public HAM_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	
	if (!is_user_connected(id))
		return HAM_IGNORED;
		
	if (!g_has_wondercannon[id])
		return HAM_IGNORED;
		
	if (g_weapon_TmpClip[id] == -1)
		return HAM_IGNORED;
	
	
	set_pdata_int(weapon_entity, 51, g_weapon_TmpClip[id], 4)
	set_pdata_int(weapon_entity, 54, 1, 4)

	set_pdata_float(id, 83, WC_RELOAD)
	set_weapons_timeidle(id, CSW_WONDERCANNON, WC_RELOAD)	
	
	UTIL_PlayWeaponAnimation(id, ANIM_RELOAD)
	return HAM_IGNORED;
}

public Fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orign_wondercannon))
		return FMRES_IGNORED
		
	if (!(1 <= invoker <= get_maxplayers()))
		return FMRES_IGNORED
		
	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}
public Fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_WONDERCANNON || !g_has_wondercannon[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_WONDERCANNON:
		{
			if(g_has_wondercannon[id])
			{
				set_pev(id, pev_viewmodel2, V_MODEL)
				set_pev(id, pev_weaponmodel2, P_MODEL)
				if(oldweap[id] != CSW_WONDERCANNON) 
				{
					UTIL_PlayWeaponAnimation(id, ANIM_DRAW)
					set_pdata_float(id, 51, 1.0, 4)
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, "m249") && get_user_weapon(iAttacker) == CSW_WONDERCANNON)
	{
		if(g_has_wondercannon[iAttacker])
			set_msg_arg_string(4, "wondercannon")		
	}
	
	return PLUGIN_CONTINUE
}
stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, 4)
}


stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	for (i = 0; i < num; i++)
	{
		const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
		weaponid = weapons[i]
		if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
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
public FindZombie(entid,lastid)
{
	new Float:Dist
	new Float:maxdistance=0.0
	new Float:rad=WC_EXP_RADIUS+50
	new indexid=0
	for(new i=1;i<=get_maxplayers();i++)
	{
		if(i==lastid) continue
		if(entid==i) continue
		if(is_user_alive(i) && is_valid_ent(i) && can_see_fm(entid, i))
		{
			if(!zp_get_user_zombie(i))continue
			Dist = entity_range(entid, i)
			if(Dist >= maxdistance && Dist<=rad)
			{
				maxdistance=Dist
				indexid=i				
			}
		}
	}    
	return indexid
} 
public bool:can_see_fm(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false;

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags);
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false;
		}

		new Float:lookerOrig[3];
		new Float:targetBaseOrig[3];
		new Float:targetOrig[3];
		new Float:temp[3];

		pev(entindex1, pev_origin, lookerOrig);
		pev(entindex1, pev_view_ofs, temp);
		lookerOrig[0] += temp[0];
		lookerOrig[1] += temp[1];
		lookerOrig[2] += temp[2];

		pev(entindex2, pev_origin, targetBaseOrig);
		pev(entindex2, pev_view_ofs, temp);
		targetOrig[0] = targetBaseOrig [0] + temp[0];
		targetOrig[1] = targetBaseOrig [1] + temp[1];
		targetOrig[2] = targetBaseOrig [2] + temp[2];

		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0);//  checks the had of seen player
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		{
			return false;
		} 
		else 
		{
			new Float:flFraction;
			get_tr2(0, TraceResult:TR_flFraction, flFraction);
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
				return true;
			}
			else
			{
				targetOrig[0] = targetBaseOrig [0];
				targetOrig[1] = targetBaseOrig [1];
				targetOrig[2] = targetBaseOrig [2];
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0); //  checks the body of seen player		skype:paska2000701(Planeshift)
				get_tr2(0, TraceResult:TR_flFraction, flFraction);
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
				{
					return true;
				}
				else
				{
					targetOrig[0] = targetBaseOrig [0];
					targetOrig[1] = targetBaseOrig [1];
					targetOrig[2] = targetBaseOrig [2] - 17.0;
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0); //  checks the legs of seen player
					get_tr2(0, TraceResult:TR_flFraction, flFraction);
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					{
						return true;
					}
				}
			}
		}
	}
	return false;
}

stock make_blood(Float:origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]+15))
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(248)
	write_byte(8)
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]+15))
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(248)
	write_byte(8)
	message_end()
}
