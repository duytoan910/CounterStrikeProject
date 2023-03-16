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

#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

#define Reload_Time	1.0
#define CROW_Time	1.0
#define Normal_Time	2.05

#define	CSW_CROW3	CSW_MP5NAVY
#define	weapon_crow3	"weapon_mp5navy"
#define	oldevent_crow3	"events/mp5n.sc"
#define	oldmodel_crow3 	"models/w_mp5.mdl"

#define CROW3_V_Model 	"models/v_crow3.mdl"
#define CROW3_P_Model 	"models/p_crow3.mdl"
#define CROW3_W_Model 	"models/w_crow3.mdl"
#define C3_Fire_Sound 	"weapons/crow3-1.wav"

#define	CROW3_NAME "CROW-3"
#define	CROW3_COST 7
#define CROW3_CLIP 64
#define CROW3_AMMO 200
#define CROW3_RECOIL 1.0
#define CROW3_DAMAGE 1.2

native navtive_bullet_effect(id, ent, ptr)

new mode[33]
enum
{
	reloading = 0,
	normal,
	crow
}

//CROW-3
new g_has_crow3[33], g_event_crow3

new g_isprimary, Float:recoil[33], g_bot
new g_clip_ammo[33], g_clip[33], oldweap[33]

public plugin_init()
{
	register_plugin("[Weapon]: CROW Weapons [Beta Version]", "1.0", "YunusReyiz")
	register_event("CurWeapon","CurrentWeapon","be","1=1")	
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	
	register_forward(FM_SetModel, "SetModel")
	register_forward(FM_UpdateClientData, "UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "PlaybackEvent")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack")
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_crow3, "AddToPlayer")
	
	RegisterHam(Ham_Weapon_Reload, weapon_crow3, "Reload3")
	RegisterHam(Ham_Weapon_Reload, weapon_crow3, "Reload_Post3", 1)
	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_crow3, "PrimaryAttack3")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_crow3, "PrimaryAttack_Post3", 1)
	
	RegisterHam(Ham_Item_PostFrame, weapon_crow3, "ItemPostFrame3")
	
	//g_crow3 = zp_register_extra_item(CROW3_NAME, CROW3_COST, ZP_TEAM_HUMAN)
}
public plugin_natives ()
{
	register_native("crow3", "native_give_crow3", 1)
}
public native_give_crow3(id)
{
	give_crow3(id)
}
public plugin_precache()
{
	precache_model(CROW3_V_Model)
	precache_model(CROW3_P_Model)
	precache_model(CROW3_W_Model)
	precache_sound(C3_Fire_Sound)

	register_forward(FM_PrecacheEvent, "PrecacheEvent_Post", 1)
}

public Player_Spawn(id)
{
	client_connect(id)
}
public zp_user_infected_post(id)
{
	client_connect(id)
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
	RegisterHamFromEntity(Ham_TraceAttack, id, "TraceAttack")
	RegisterHamFromEntity(Ham_Spawn, id, "Player_Spawn")
}

public TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker))
		return

	new g_currentweapon = get_user_weapon(attacker)

	if((g_currentweapon != CSW_CROW3) 
	|| (g_currentweapon == CSW_CROW3 && !g_has_crow3[attacker])) return;

	if(g_has_crow3[attacker])
	{
		navtive_bullet_effect(attacker, ent, ptr)
	}
	
}

public PrecacheEvent_Post(type, const name[])
{
	if (equal(oldevent_crow3, name)) g_event_crow3 = get_orig_retval()
}

public client_connect(id)
{
	g_has_crow3[id] = 0
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
	//CROW-3 w_model
	if(equal(model, oldmodel_crow3))
	{
		static id
		
		id = find_ent_by_owner(-1, weapon_crow3, ent)
	
		if(!is_valid_ent(id))
			return FMRES_IGNORED
	
		if(g_has_crow3[own])
		{
			entity_set_int(id, EV_INT_impulse, 7231563)
			
			g_has_crow3[own] = false
			
			entity_set_model(ent, CROW3_W_Model)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}

//Added CROW-3
public give_crow3(id)
{
	g_has_crow3[id] = true
	new iWep2 = give_item(id, weapon_crow3)
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, CROW3_CLIP)
		cs_set_user_bpammo (id, CSW_CROW3, CROW3_AMMO)	
		set_anim(id, 6)
		set_pdata_float(id, 83, 1.0, 5)
	}
}

public AddToPlayer(ent, id)
{
	if(!is_valid_ent(ent) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(ent, EV_INT_impulse) == 7231563)
	{
		g_has_crow3[id] = true
		
		entity_set_int(ent, EV_INT_impulse, 0)
	}

	return HAM_IGNORED
}

public CurrentWeapon(id) replace_weapon_models(id, read_data(2))

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_CROW3:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return
				
			if(g_has_crow3[id])
			{
				set_pev(id, pev_viewmodel2, CROW3_V_Model)
				set_pev(id, pev_weaponmodel2, CROW3_P_Model)
				if(oldweap[id] != CSW_CROW3) 
				{
					set_anim(id, 6)
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
	|| ((get_user_weapon(id) != CSW_CROW3) 
	|| (get_user_weapon(id) == CSW_CROW3 && !g_has_crow3[id])))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_event_crow3) || !g_isprimary)
		return FMRES_IGNORED
	if (!(1 <= invoker <= get_maxplayers()))
	return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

//CROW-3 PrimaryAttack and Post

public PrimaryAttack3(id)
{
	new ent = get_pdata_cbase(id, 41, 4)
	
	if (!g_has_crow3[ent])
		return
	
	g_isprimary = 1
	
	g_clip_ammo[ent] = cs_get_weapon_ammo(id)

}

public PrimaryAttack_Post3(id)
{
	g_isprimary = 0
	new ent = get_pdata_cbase(id, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(ent, szClip, szAmmo)
	
	if(!is_user_alive(ent))
		return
		
	if(g_has_crow3[ent])
	{
		if (!g_clip_ammo[ent])
			return
		
		new Float:push[3]
		pev(ent,pev_punchangle,push)
		xs_vec_sub(push,recoil[ent],push)
		
		xs_vec_mul_scalar(push,CROW3_RECOIL,push)
		xs_vec_add(push,recoil[ent],push)
		set_pev(ent,pev_punchangle,push)
		
		emit_sound(ent, CHAN_WEAPON, C3_Fire_Sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		set_anim(ent, 1)
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

public ItemPostFrame3(wpn, uc_handle) 
{
	new id = pev(wpn, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_crow3[id])
		return HAM_IGNORED

	static iClipExtra
     
	iClipExtra = CROW3_CLIP
	new Float:flNextAttack = get_pdata_float(id, 83, 5)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_CROW3)
	new iClip = get_pdata_int(wpn, 51, 4)

	new fInReload = get_pdata_int(wpn, 54, 4)

	if( fInReload && flNextAttack <= 0.0 )
	{	
		set_pdata_float(wpn, 48, CROW_Time, 4)
		mode[id] = crow
		set_anim(id, 4)
		set_pdata_float(id, 83, CROW_Time, 5)
		set_pdata_int(wpn, 51, g_clip[id], 4)
		
		new j = min(iClipExtra - iClip, iBpAmmo)

		set_pdata_int(wpn, 51, iClip + j, 4)
		cs_set_user_bpammo(id, CSW_CROW3, iBpAmmo-j)
		
		set_pdata_int(wpn, 54, 0, 4)

		fInReload = 0
	}		
	return HAM_IGNORED
}

public Reload3(wpn) 
{
	new id = pev(wpn, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_crow3[id])
		return HAM_IGNORED

	static iClipExtra

	iClipExtra = CROW3_CLIP

	g_clip[id] = -1
	
	new iClip = get_pdata_int(wpn, 51, 4)
	new iBpAmmo = cs_get_user_bpammo(id, CSW_CROW3)
		
	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE

	if (iClip >= iClipExtra)
		return HAM_SUPERCEDE

	g_clip[id] = iClip

	return HAM_IGNORED
}

public Reload_Post3(wpn) 
{
	new id = pev(wpn, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_crow3[id])
		return HAM_IGNORED

	if (g_clip[id] == -1)
		return HAM_IGNORED

	mode[id] = reloading
	
	set_pdata_float(wpn, 48, Reload_Time, 4)
	set_pdata_float(id, 83, Reload_Time, 5)

	set_pdata_int(wpn, 51, g_clip[id], 4)
	set_pdata_int(wpn, 54, 1, 4)

	if(mode[id] == reloading) set_anim(id, 3)

	return HAM_IGNORED
}

//Plugin Coded by YunusReyiz..

public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(get_user_weapon(iAttacker) == CSW_CROW3)
	{
		if(g_has_crow3[iAttacker])
			set_msg_arg_string(4, "crow3")
	}
                
	return PLUGIN_CONTINUE
}
