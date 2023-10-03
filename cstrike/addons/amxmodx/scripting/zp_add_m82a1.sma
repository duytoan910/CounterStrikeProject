#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>
#include <toan>
#include <zp50_gamemodes>

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)
#define SET_MODEL(%0,%1)		engfunc(EngFunc_SetModel, %0, %1)
#define SET_ORIGIN(%0,%1)		engfunc(EngFunc_SetOrigin, %0, %1)
#define MESSAGE_BEGIN(%0,%1,%2,%3)	engfunc(EngFunc_MessageBegin, %0, %1, %2, %3)
#define MESSAGE_END()			message_end()

#define WRITE_ANGLE(%0)			engfunc(EngFunc_WriteAngle, %0)
#define WRITE_BYTE(%0)			write_byte(%0)
#define WRITE_COORD(%0)			engfunc(EngFunc_WriteCoord, %0)
#define WRITE_STRING(%0)		write_string(%0)
#define WRITE_SHORT(%0)			write_short(%0)
#define PRECACHE_MODEL(%0)		engfunc(EngFunc_PrecacheModel, %0)
#define PRECACHE_SOUND(%0)		engfunc(EngFunc_PrecacheSound, %0)

#define Reload_Time	3.0

#define	CSW_M82A1	CSW_AWP
#define	weapon_m82a1	"weapon_awp"

#define	oldevent_m82a1	"events/awp.sc"
#define	oldmodel_m82a1 	"models/w_awp.mdl"
new const M82A1_V_Model[][] = {
	"models/PV-M82A1_DemonicBeast.mdl",
	"models/PV-M82A1_IronBeast2.mdl"
}
#define M82A1_P_Model 	"models/QV-M82A1.mdl"
#define M82A1_W_Model 	"models/w_awp.mdl"
#define C7_Fire_Sound 	"weapons/BARRET_SHOOT_1.wav"

#define M82A1_CLIP 10
#define M82A1_AMMO 200
#define M82A1_RECOIL 4.0
#define M82A1_DAMAGE 1.3
#define EXP_DAMAGE random_float(300.0, 350.0)
#define CHARGE_EXPRADIUS 100.0

#define m_iClip				51
#define WEAP_LINUX_XTRA_OFF		4
#define m_fInReload			54
#define extra_offset_weapon		4
#define m_flVelocityModifier 		108 
#define extra_offset_player		5

#define ANIM_IDLE 0
#define ANIM_PREFIRE 1
#define ANIM_FIRE 2
#define ANIM_POSTFIRE 3
#define ANIM_RELOAD 4
#define ANIM_SELECT 5
#define ANIM_RUN 6

//CROW-7
new g_has_m82a1[33], g_event_m82a1, Float:g_flNextUseTime[33]
new g_bot, g_iExplo, g_iExplo_
new g_isprimary, Float:recoil[33]
new g_clip_ammo[33], g_clip[33], oldweap[33]

native navtive_bullet_effect(id, ent, ptr)

public plugin_init()
{
	register_plugin("[Weapon]: CROW Weapons [Beta Version]", "1.0", "YunusReyiz")
	register_event("CurWeapon","CurrentWeapon","be","1=1")	
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	
	register_forward(FM_SetModel, "SetModel")
	register_forward(FM_UpdateClientData, "UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "PlaybackEvent")	
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "worldspawn", "TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack", 1)
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_m82a1, "AddToPlayer")
	
	RegisterHam(Ham_Weapon_Reload, weapon_m82a1, "Reload7")
	RegisterHam(Ham_Weapon_Reload, weapon_m82a1, "Reload_Post7", 1)
	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_m82a1, "PrimaryAttack7")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_m82a1, "PrimaryAttack_Post7", 1)
	
	RegisterHam(Ham_Item_PostFrame, weapon_m82a1, "ItemPostFrame7")
	
	RegisterHam(Ham_Item_Holster, weapon_m82a1, "HolsterPost", 1)
	
}
public plugin_precache()
{	
	precache_model(M82A1_V_Model[0])
	precache_model(M82A1_V_Model[1])
	precache_model(M82A1_P_Model)
	precache_model(M82A1_W_Model)
	precache_sound(C7_Fire_Sound)
		
	register_forward(FM_PrecacheEvent, "PrecacheEvent_Post", 1)
	g_iExplo = precache_model("sprites/eexplo.spr")
	g_iExplo_ = precache_model("sprites/fexplo.spr")
}
public client_putinserver(id)
{
	if(is_user_bot(id) && !g_bot)
	{
		g_bot = 1
		set_task(0.1, "Do_RegisterHamBot", id)
	}
}
public Do_RegisterHamBot(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_TraceAttack, id, "TraceAttack")
	RegisterHamFromEntity(Ham_Spawn, id, "Player_Spawn")
}
public plugin_natives(){
	register_native("m82a1", "give_m82a1", 1)
}
public Player_Spawn(id)
{
	client_connect(id)
}
public zp_user_infected_post(id)
{
	client_connect(id)
}


public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_M82A1)
		{
			if(g_has_m82a1[attacker])
			{
				SetHamParamFloat(4, damage * M82A1_DAMAGE)
			}
		}
	}
}

public TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker))
		return

	new g_currentweapon = get_user_weapon(attacker)

	if((g_currentweapon != CSW_M82A1) 
	|| (g_currentweapon == CSW_M82A1 && !g_has_m82a1[attacker])) return;
	new Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	explode(attacker, flEnd)
}

public PrecacheEvent_Post(type, const name[])
{
	if (equal(oldevent_m82a1, name)) g_event_m82a1 = get_orig_retval()
}

public client_connect(id)
{
	g_has_m82a1[id] = 0
}
public SetModel(ent, model[])
{
	if(!is_valid_ent(ent))
		return FMRES_IGNORED
	
	static szcn[33]
	entity_get_string(ent, EV_SZ_classname, szcn, charsmax(szcn))
		
	if(!equal(szcn, "weaponbox"))
		return FMRES_IGNORED
	
	static own
	
	own = entity_get_edict(ent, EV_ENT_owner)
	//CROW-7 w_model
	if(equal(model, oldmodel_m82a1))
	{
		static id
		
		id = find_ent_by_owner(-1, weapon_m82a1, ent)
	
		if(!is_valid_ent(id))
			return FMRES_IGNORED
	
		if(g_has_m82a1[own])
		{
			entity_set_int(id, EV_INT_impulse, 337871)
			
			g_has_m82a1[own] = false
			
			entity_set_model(ent, M82A1_W_Model)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}

new g_skin[33]
public give_m82a1(id)
{
	drop_weapons(id, 1)
	g_has_m82a1[id] = true
	new iWep2 = give_item(id, weapon_m82a1)
	g_skin[id] = random_num(0,1)
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, M82A1_CLIP)
		cs_set_user_bpammo (id, CSW_M82A1, M82A1_AMMO)	
		set_anim(id, ANIM_SELECT)
		set_pdata_float(id, 83, 1.0, 5)
	}
}

public AddToPlayer(ent, id)
{
	if(!is_valid_ent(ent) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(ent, EV_INT_impulse) == 337871)
	{
		g_has_m82a1[id] = true
		
		entity_set_int(ent, EV_INT_impulse, 0)
	}

	return HAM_IGNORED
}

public CurrentWeapon(id) replace_weapon_models(id, read_data(2))

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_M82A1:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return
			if(g_has_m82a1[id])
			{
				set_pev(id, pev_viewmodel2, M82A1_V_Model[g_skin[id]])
				set_pev(id, pev_weaponmodel2, M82A1_P_Model)
				if(oldweap[id] != CSW_M82A1) 
				{
					set_anim(id, ANIM_SELECT)
					set_pdata_float(id, 83, 1.0, 5)
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public UpdateClientData_Post(id, SendWeapons, CD_Handle)
{
	//if(!is_user_alive(id) || (get_user_weapon(id) != CSW_CROW1 || !g_has_crow1[id]))
	if(!is_user_alive(id) 
	|| ((get_user_weapon(id) != CSW_M82A1) 
	|| (get_user_weapon(id) == CSW_M82A1 && !g_has_m82a1[id])))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_event_m82a1) || !g_isprimary)
		return FMRES_IGNORED
	if (!(1 <= invoker <= get_maxplayers()))
	return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

//CROW-7 PrimaryAttack and Post

public PrimaryAttack7(id)
{
	new ent = get_pdata_cbase(id, 41, 4)
	
	if (!g_has_m82a1[ent])
		return
	
	g_isprimary = 1
	
	g_clip_ammo[ent] = cs_get_weapon_ammo(id)

}

public PrimaryAttack_Post7(id)
{
	g_isprimary = 0
	new ent = get_pdata_cbase(id, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(ent, szClip, szAmmo)
	
	if(!is_user_alive(ent))
		return
		
	if(g_has_m82a1[ent])
	{
		if (!g_clip_ammo[ent])
			return
		
		new Float:push[3]
		
		pev(ent,pev_punchangle,push)
		xs_vec_sub(push,recoil[ent],push)
		
		xs_vec_mul_scalar(push,M82A1_RECOIL,push)
		xs_vec_add(push,recoil[ent],push)
		set_pev(ent,pev_punchangle,push)
		
		emit_sound(ent, CHAN_WEAPON, C7_Fire_Sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		set_anim(ent, ANIM_FIRE)

		set_weapons_timeidle(id, ent, 1.4)
		set_player_nextattack(id, 1.4)
	}
}

public explode(id, Float:End1[3])
{
	if(g_has_m82a1[id])
	{
		if(is_user_alive(id))
		{
			new TE_FLAG
			TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
			
			message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION)
			engfunc(EngFunc_WriteCoord, End1[0])
			engfunc(EngFunc_WriteCoord, End1[1])
			engfunc(EngFunc_WriteCoord, End1[2]+40.0)
			write_short(g_iExplo)	// sprite index
			write_byte(23)	// scale in 0.1's
			write_byte(30)	// framerate
			write_byte(TE_FLAG)	// flags
			message_end()

			TE_FLAG |= TE_EXPLFLAG_NOSOUND
			message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION)
			engfunc(EngFunc_WriteCoord, End1[0])
			engfunc(EngFunc_WriteCoord, End1[1])
			engfunc(EngFunc_WriteCoord, End1[2]+40.0)
			write_short(g_iExplo_)	// sprite index
			write_byte(23)	// scale in 0.1's
			write_byte(30)	// framerate
			write_byte(TE_FLAG)	// flags
			message_end()

			new a
			while((a = find_ent_in_sphere(a, End1, CHARGE_EXPRADIUS+50.0)) != 0)
			{
				if (id == a)
					continue 
				if(!is_user_alive(a))
					continue	
				if(!zp_get_user_zombie(a))
					continue	
				if(pev(a, pev_takedamage) != DAMAGE_NO)
				{
					ExecuteHamB(Ham_TakeDamage, a, id, id, is_deadlyshot(id)?EXP_DAMAGE*1.5:EXP_DAMAGE, DMG_BULLET);
				}
			}
		}
	}
}

stock set_anim(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

public ItemPostFrame7(wpn, uc_handle) 
{
	new id = pev(wpn, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_m82a1[id])
		return HAM_IGNORED

	static iClipExtra
     
	iClipExtra = M82A1_CLIP
	new Float:flNextAttack = get_pdata_float(id, 83, 5)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_M82A1)
	new iClip = get_pdata_int(wpn, 51, 4)

	new fInReload = get_pdata_int(wpn, 54, 4)

	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(iClipExtra - iClip, iBpAmmo)
		
		set_pdata_int(wpn, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, CSW_M82A1, iBpAmmo-j)
		
		set_pdata_int(wpn, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		fInReload = 0
	}		

	return HAM_IGNORED
}

public Reload7(wpn) 
{
	new id = pev(wpn, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_m82a1[id])
		return HAM_IGNORED

	static iClipExtra

	iClipExtra = M82A1_CLIP

	g_clip[id] = -1
	
	new iClip = get_pdata_int(wpn, 51, 4)
	new iBpAmmo = cs_get_user_bpammo(id, CSW_M82A1)
		
	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE

	if (iClip >= iClipExtra)
		return HAM_SUPERCEDE

	g_clip[id] = iClip

	return HAM_IGNORED
}

public Reload_Post7(wpn) 
{
	new id = pev(wpn, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_m82a1[id])
		return HAM_IGNORED

	if (g_clip[id] == -1)
		return HAM_IGNORED

	set_anim(id, ANIM_RELOAD)
	set_pdata_float(wpn, 48, 3.3, 4)
	set_pdata_float(id, 83, 3.3, 5)

	set_pdata_int(wpn, 51, g_clip[id], 4)
	set_pdata_int(wpn, 54, 1, 4)
	
	return HAM_IGNORED
}

public HolsterPost(wpn)
{
	static id
	id = get_pdata_cbase(wpn, 41, 4)
	
	g_flNextUseTime[id] = 0.0

	if(!g_has_m82a1[id])
		return;
}


//Plugin Coded by YunusReyiz..

public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(get_user_weapon(iAttacker) == CSW_M82A1)
	{
		if(g_has_m82a1[iAttacker])
			set_msg_arg_string(4, "m82a1")
	}
                
	return PLUGIN_CONTINUE
}

stock drop_weapons(id, dropwhat)
{
     static weapons[32], num, i, weaponid
     num = 0
     get_user_weapons(id, weapons, num)
     
     for (i = 0; i < num; i++)
     {
          weaponid = weapons[i]
          
          if (dropwhat == 1 && ((1<<weaponid) & ((1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90))))
          {
               static wname[32]
               get_weaponname(weaponid, wname, sizeof wname - 1)
               engclient_cmd(id, "drop", wname)
          }
     }
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

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, 83, nexttime, 5)
}
