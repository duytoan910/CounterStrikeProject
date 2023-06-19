//Plugin Coded by YunusReyiz..
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

#define	CSW_BUFFAWP	CSW_AWP
#define	weapon_buffawp	"weapon_awp"

#define	oldevent_buffawp	"events/awp.sc"
#define	oldmodel_buffawp 	"models/w_awp.mdl"
#define BUFFAWP_V_Model 	"models/v_zgun.mdl"
#define BUFFAWP_P_Model 	"models/p_zgun.mdl"
#define BUFFAWP_W_Model 	"models/w_zgun.mdl"
#define C7_Fire_Sound 	"weapons/zgun-1.wav"

#define	BUFFAWP_NAME "AWP-Z"
#define	BUFFAWP_COST	10000
#define BUFFAWP_CLIP 20
#define BUFFAWP_AMMO 200
#define BUFFAWP_RECOIL 4.0
#define BUFFAWP_DAMAGE 2.5
#define CHARGE_EXPRADIUS 60.0
#define WEAPONN_KRAKEN_DAMAGE			random_float(650.0, 700.0)

#define m_iClip				51
#define WEAP_LINUX_XTRA_OFF		4
#define m_fInReload			54
#define extra_offset_weapon		4
#define m_flVelocityModifier 		108 
#define extra_offset_player		5

#define MODEL_KRAKEN				"models/ef_kraken.mdl"
#define SOUND_EXPLODE				"weapons/kraken_exp.wav"
#define SOUND_EXPLODE2				"weapons/kraken_up.wav"
#define SPRITE_EXP					"sprites/ef_kraken_exp.spr"
#define SPRITE_SMOKE				"sprites/ef_kraken_fire.spr"
#define KRAKEN_CLASSNAME			"KrakeClass"

//CROW-7
new g_has_buffawp[33], g_event_buffawp, Float:g_flNextUseTime[33]
new g_bot, id_spr_exp, id_spr_smk
new g_buffawp
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
	register_forward(FM_Think, 					"FakeMeta_Think",			false);
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "worldspawn", "TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack", 1)
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_buffawp, "AddToPlayer")
	
	RegisterHam(Ham_Weapon_Reload, weapon_buffawp, "Reload7")
	RegisterHam(Ham_Weapon_Reload, weapon_buffawp, "Reload_Post7", 1)
	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_buffawp, "PrimaryAttack7")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_buffawp, "PrimaryAttack_Post7", 1)
	
	RegisterHam(Ham_Item_PostFrame, weapon_buffawp, "ItemPostFrame7")
	
	RegisterHam(Ham_Item_Holster, weapon_buffawp, "HolsterPost", 1)
	
	g_buffawp = zp_register_extra_item(BUFFAWP_NAME, BUFFAWP_COST, ZP_TEAM_HUMAN)
}
public plugin_precache()
{	
	precache_model(BUFFAWP_V_Model)
	precache_model(BUFFAWP_P_Model)
	precache_model(BUFFAWP_W_Model)
	precache_sound(C7_Fire_Sound)
		
	register_forward(FM_PrecacheEvent, "PrecacheEvent_Post", 1)

	PRECACHE_MODEL(MODEL_KRAKEN);
	PRECACHE_SOUND(SOUND_EXPLODE);
	PRECACHE_SOUND(SOUND_EXPLODE2);
	id_spr_exp = PRECACHE_MODEL(SPRITE_EXP);
	id_spr_smk = PRECACHE_MODEL(SPRITE_SMOKE);
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
public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_buffawp) 
		give_buffawp(id)
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
		if(get_user_weapon(attacker) == CSW_BUFFAWP)
		{
			if(g_has_buffawp[attacker])
			{
				SetHamParamFloat(4, damage * BUFFAWP_DAMAGE)
			}
		}
	}
}

public TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker))
		return

	new g_currentweapon = get_user_weapon(attacker)

	if((g_currentweapon != CSW_BUFFAWP) 
	|| (g_currentweapon == CSW_BUFFAWP && !g_has_buffawp[attacker])) return;
	new Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	new hit = get_tr(TR_pHit)
	if(pev_valid(hit)&&is_user_alive(hit))
		pev(hit, pev_origin, flEnd)
		
	navtive_bullet_effect(attacker, ent, ptr)
	explode(attacker, flEnd)
	
	hit = 0;
}

public PrecacheEvent_Post(type, const name[])
{
	if (equal(oldevent_buffawp, name)) g_event_buffawp = get_orig_retval()
}

public client_connect(id)
{
	g_has_buffawp[id] = 0
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
	if(equal(model, oldmodel_buffawp))
	{
		static id
		
		id = find_ent_by_owner(-1, weapon_buffawp, ent)
	
		if(!is_valid_ent(id))
			return FMRES_IGNORED
	
		if(g_has_buffawp[own])
		{
			entity_set_int(id, EV_INT_impulse, 33157871)
			
			g_has_buffawp[own] = false
			
			entity_set_model(ent, BUFFAWP_W_Model)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}

//Added CROW-7
public give_buffawp(id)
{
	drop_weapons(id, 1)
	g_has_buffawp[id] = true
	new iWep2 = give_item(id, weapon_buffawp)
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, BUFFAWP_CLIP)
		cs_set_user_bpammo (id, CSW_BUFFAWP, BUFFAWP_AMMO)	
		set_anim(id, 5)
		set_pdata_float(id, 83, 1.0, 5)
	}
}

public AddToPlayer(ent, id)
{
	if(!is_valid_ent(ent) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(ent, EV_INT_impulse) == 33157871)
	{
		g_has_buffawp[id] = true
		
		entity_set_int(ent, EV_INT_impulse, 0)
	}

	return HAM_IGNORED
}

public CurrentWeapon(id) replace_weapon_models(id, read_data(2))

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_BUFFAWP:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return
			if(g_has_buffawp[id])
			{
				set_pev(id, pev_viewmodel2, BUFFAWP_V_Model)
				set_pev(id, pev_weaponmodel2, BUFFAWP_P_Model)
				if(oldweap[id] != CSW_BUFFAWP) 
				{
					set_anim(id, 5)
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
	|| ((get_user_weapon(id) != CSW_BUFFAWP) 
	|| (get_user_weapon(id) == CSW_BUFFAWP && !g_has_buffawp[id])))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_event_buffawp) || !g_isprimary)
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
	
	if (!g_has_buffawp[ent])
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
		
	if(g_has_buffawp[ent])
	{
		if (!g_clip_ammo[ent])
			return
		
		new Float:push[3]
		
		pev(ent,pev_punchangle,push)
		xs_vec_sub(push,recoil[ent],push)
		
		xs_vec_mul_scalar(push,BUFFAWP_RECOIL,push)
		xs_vec_add(push,recoil[ent],push)
		set_pev(ent,pev_punchangle,push)
		
		emit_sound(ent, CHAN_WEAPON, C7_Fire_Sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		set_anim(ent, random_num(1,3))
	}
}

public explode(id, Float:End1[3])
{
	if(g_has_buffawp[id])
	{
		if(is_user_alive(id))
		{
			new TE_FLAG
			
			TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
			TE_FLAG |= TE_EXPLFLAG_NOSOUND
			TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
			
			MESSAGE_BEGIN(MSG_PVS, SVC_TEMPENTITY, End1, 0);
			WRITE_BYTE(TE_EXPLOSION);
			WRITE_COORD(End1[0]); 
			WRITE_COORD(End1[1]);
			WRITE_COORD(End1[2] + 10.0);
			WRITE_SHORT(id_spr_exp);
			WRITE_BYTE(20);
			WRITE_BYTE(10);
			WRITE_BYTE(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES);
			MESSAGE_END();
			
			MESSAGE_BEGIN(MSG_PVS, SVC_TEMPENTITY, End1, 0);
			WRITE_BYTE(TE_EXPLOSION);
			WRITE_COORD(End1[0]); 
			WRITE_COORD(End1[1]);
			WRITE_COORD(End1[2] + 10.0);
			WRITE_SHORT(id_spr_smk);
			WRITE_BYTE(20);
			WRITE_BYTE(15);
			WRITE_BYTE(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES);
			MESSAGE_END();
			
			
			new ent = create_entity("info_target")
			set_pev(ent, pev_origin, End1)			
			engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON, SOUND_EXPLODE, 0.9, ATTN_NORM, 0, PITCH_NORM);
			set_pev(ent, pev_flags, FL_KILLME)
			
			// Alive...
			new a = FM_NULLENT
			// Get distance between victim and epicenter
			while((a = find_ent_in_sphere(a, End1, CHARGE_EXPRADIUS)) != 0)
			{
				if (id == a || !is_user_alive(a) || !zp_get_user_zombie(a))
					continue 
				if(pev(a, pev_takedamage) != DAMAGE_NO)
				{
					new iEntity = create_entity("info_target");
					if (pev_valid(iEntity))
					{	
						new Origin[3];	pev(a, pev_origin, Origin)
						SET_MODEL(iEntity, MODEL_KRAKEN)
						SET_ORIGIN(iEntity, Origin)
					
						set_pev(iEntity, pev_classname, KRAKEN_CLASSNAME);
						set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
						set_pev(iEntity, pev_solid, SOLID_NOT);
						set_pev(iEntity, pev_owner, id);
						set_pev(iEntity, pev_framerate, 0.4);
						set_pev(iEntity, pev_sequence, 0);
						set_pev(iEntity, pev_animtime, get_gametime());
						set_pev(iEntity, pev_fuser2, get_gametime() + 2.5);
						set_pev(iEntity, pev_nextthink, get_gametime() + 0.4);
					}

					ExecuteHamB(Ham_TakeDamage, a, id, id, is_deadlyshot(id)?random_float(110.0-10,110.0+10)+1.5:random_float(110.0-10,110.0+10), DMG_BULLET)
				}
			}
		}
	}
}

public FakeMeta_Think(const iSprite)
{
	if (!pev_valid(iSprite))
	{
		return FMRES_IGNORED;
	}
	
	static Classname[32];pev(iSprite, pev_classname, Classname, sizeof(Classname));

	static iAttacker; iAttacker = pev(iSprite, pev_owner);

	if (equal(Classname, KRAKEN_CLASSNAME))
	{
		static Float:Origin[3];pev(iSprite, pev_origin, Origin);
		static Float:iTime;pev(iSprite, pev_fuser2, iTime);
		static iVictim;iVictim = -1;

		if (iTime <= get_gametime())
		{
			engfunc(EngFunc_RemoveEntity, iSprite);
			return FMRES_SUPERCEDE;
		}
		
		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, Origin, 20.0)) != 0)
		{
			static Float:iVelo[3];pev(iVictim, pev_velocity, iVelo);
			
			if (!is_user_alive(iVictim))continue;
			if (!zp_get_user_zombie(iVictim))continue;	
			
			iVelo[2] = 350.0;

			ExecuteHamB(Ham_TakeDamage, iVictim, iSprite, iAttacker, is_deadlyshot(iAttacker)?WEAPONN_KRAKEN_DAMAGE*1.5:WEAPONN_KRAKEN_DAMAGE, DMG_SONIC);
			
			set_pdata_float(iVictim, m_flVelocityModifier, 1.0,  extra_offset_player);
			set_pev(iVictim, pev_velocity, iVelo);
		}
		set_pev(iSprite, pev_nextthink, get_gametime() + 2.4);
	}
	
	return FMRES_IGNORED;
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

	if (!g_has_buffawp[id])
		return HAM_IGNORED

	static iClipExtra
     
	iClipExtra = BUFFAWP_CLIP
	new Float:flNextAttack = get_pdata_float(id, 83, 5)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_BUFFAWP)
	new iClip = get_pdata_int(wpn, 51, 4)

	new fInReload = get_pdata_int(wpn, 54, 4)

	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(iClipExtra - iClip, iBpAmmo)
		
		set_pdata_int(wpn, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, CSW_BUFFAWP, iBpAmmo-j)
		
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

	if (!g_has_buffawp[id])
		return HAM_IGNORED

	static iClipExtra

	iClipExtra = BUFFAWP_CLIP

	g_clip[id] = -1
	
	new iClip = get_pdata_int(wpn, 51, 4)
	new iBpAmmo = cs_get_user_bpammo(id, CSW_BUFFAWP)
		
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

	if (!g_has_buffawp[id])
		return HAM_IGNORED

	if (g_clip[id] == -1)
		return HAM_IGNORED

	set_pdata_float(wpn, 48, Reload_Time, 4)
	set_pdata_float(id, 83, Reload_Time, 5)

	set_pdata_int(wpn, 51, g_clip[id], 4)
	set_pdata_int(wpn, 54, 1, 4)
	
	return HAM_IGNORED
}

public HolsterPost(wpn)
{
	static id
	id = get_pdata_cbase(wpn, 41, 4)
	
	g_flNextUseTime[id] = 0.0

	if(!g_has_buffawp[id])
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
        
	if(get_user_weapon(iAttacker) == CSW_BUFFAWP)
	{
		if(g_has_buffawp[iAttacker])
			set_msg_arg_string(4, "buffawp")
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
