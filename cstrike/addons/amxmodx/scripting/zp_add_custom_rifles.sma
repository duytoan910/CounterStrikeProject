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


#define	CSW_RIFLES	CSW_AK47
#define	weapon_rifles	"weapon_ak47"
#define	oldevent_rifles	"events/ak47.sc"
#define	oldmodel_rifles 	"models/w_ak47.mdl"

new const v_model[5][] ={
	"models/v_at15hw.mdl",
	"models/PV-AK47_K_TRANSFORMER.mdl",
	"models/PV-M4A1_S_BORN.mdl",
	"models/PV-M4A1-TRANSFORMER.mdl",
	"models/PV-M4A1_S_PREDATOR.mdl"
}
new const Fire_Sound[5][] ={
	"weapons/at15hw-1.wav",
	"weapons/AK47_TRANS_SHOOT_1.wav",
	"weapons/M4A1_S_T_SHOOT_1.wav",
	"weapons/M4A1_S_T_SHOOT_1.wav",
	"weapons/M4A1_S_T_SHOOT_1.wav"
}

enum
{
	AT15_HW = 0,
	AK47_K_TRANSFORMER,
	M4A1_BORNBEAST_NOBLE,
	M4A1_S_BORN,
	M4A1_TRANSFORMER,
	M4A1_S_PREDATOR
}


#define rifles_P_Model 	"models/p_at15hw.mdl"

#define rifles_W_Model 	"models/w_ak47.mdl"

#define	rifles_COST	15
#define rifles_CLIP 35
#define rifles_AMMO 200
#define rifles_RECOIL 0.5
#define rifles_DAMAGE 1.25
#define Reload_Time 1.7

native navtive_bullet_effect(id, ent, ptr)
enum
{
	ANIM_IDLE = 0,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT3
}

//CROW-5
new g_has_rifles[33], g_event_rifles

new g_isprimary, Float:recoil[33],g_bot
new g_clip_ammo[33], g_clip[33], oldweap[33]
new g_skin[33]

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
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_rifles, "AddToPlayer")

	RegisterHam(Ham_Weapon_Reload, weapon_rifles, "Reload5")
	RegisterHam(Ham_Weapon_Reload, weapon_rifles, "Reload_Post5", 1)
	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_rifles, "PrimaryAttack5")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_rifles, "PrimaryAttack_Post5", 1)
	RegisterHam(Ham_Item_Deploy, weapon_rifles, "Item_Deploy_Post", 1)
	
	RegisterHam(Ham_Item_PostFrame, weapon_rifles, "ItemPostFrame5")
}

public plugin_natives ()
{
	register_native("at15hw", "native_give_rifles", 1)
}
public native_give_rifles(id)
{
	give_rifles(id)
}
public plugin_precache()
{	
	for(new i=0;i<sizeof(v_model);i++){
		precache_model(v_model[i])
	}
	precache_model(rifles_P_Model)
	precache_model(rifles_W_Model)
	for(new i=0;i<sizeof(Fire_Sound);i++){
		precache_sound(Fire_Sound[i])
	}

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
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_Spawn, id, "Player_Spawn")
}

public TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker))
		return

	new g_currentweapon = get_user_weapon(attacker)

	if((g_currentweapon != CSW_RIFLES) 
	|| (g_currentweapon == CSW_RIFLES && !g_has_rifles[attacker])) return;
	
	if(g_has_rifles[attacker])
	{
		navtive_bullet_effect(attacker, ent, ptr)
	}
}

public PrecacheEvent_Post(type, const name[])
{
	if (equal(oldevent_rifles, name)) g_event_rifles = get_orig_retval()
}

public client_connect(id)
{
	g_has_rifles[id] = 0
}

public SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[64]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(entity, pev_owner)
	
	if(equal(model, oldmodel_rifles))
	{
		static weapon
		weapon = fm_get_user_weapon_entity(entity, CSW_RIFLES)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_has_rifles[id])
		{
			set_pev(weapon, pev_impulse, 981065194)		
			set_pev(weapon, pev_iuser3, g_skin[id])
			engfunc(EngFunc_SetModel, entity, rifles_W_Model)
			g_has_rifles[id] = false

			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public AddToPlayer(ent, id)
{
	if(pev(ent, pev_impulse) == 981065194)
	{
		g_has_rifles[id] = 1
		
		set_pev(ent, pev_impulse, 0)
		g_skin[id] = pev(ent, pev_iuser3)
	}
}


//Added CROW-5
public give_rifles(id)
{
	//drop_weapons(id, 0)
	g_skin[id] = random_num(0, 4)
	new iWep2;iWep2 = give_item(id, weapon_rifles)	
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, 35)
		cs_set_user_bpammo (id, CSW_AK47, 200)	
		set_anim(id, ANIM_DRAW)
		set_pdata_float(id, 83, 1.0, 5)
		set_pdata_float(iWep2, 48, 0.7, 4)
	}
	g_has_rifles[id] = true
}
public CurrentWeapon(id)
{
	replace_weapon_models(id, read_data(2))

	if(read_data(2) != CSW_RIFLES || !g_has_rifles[id])
		return;
     
	static Float:iSpeed;

	if(g_has_rifles[id])
		iSpeed = g_skin[id]==1?1.1:0.7
	
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
replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_RIFLES:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return
			if(g_has_rifles[id])
			{
				set_pev(id, pev_viewmodel2, v_model[g_skin[id]])
				set_pev(id, pev_weaponmodel2, rifles_P_Model)
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_RIFLES)
		{
			if(g_has_rifles[attacker])
			{
				
				SetHamParamFloat(4, damage * (g_skin[attacker]==1?rifles_DAMAGE+0.2:rifles_DAMAGE))
			}
		}
	}
}
public Item_Deploy_Post(ent)
{
	static owner
	owner = get_pdata_cbase(ent, 41, 4)
	if(!is_user_alive(owner) || (get_user_weapon(owner) != CSW_RIFLES) || !g_has_rifles[owner])
		return
	static weaponid
	weaponid = cs_get_weapon_id(ent)
	replace_weapon_models(owner, weaponid)
	
	set_anim(owner, ANIM_DRAW)
	set_pdata_float(ent, 48, 0.7, 4)	
	set_pdata_float(owner, 83, 1.0, 5)
}
public UpdateClientData_Post(id, SendWeapons, CD_Handle)
{
	//if(!is_user_alive(id) || (get_user_weapon(id) != CSW_CROW1 || !g_has_crow1[id]))
	if(!is_user_alive(id) 
	|| ((get_user_weapon(id) != CSW_RIFLES) 
	|| (get_user_weapon(id) == CSW_RIFLES && !g_has_rifles[id])))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_event_rifles) || !g_isprimary)
		return FMRES_IGNORED
	if (!(1 <= invoker <= get_maxplayers()))
	return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

//CROW-5 PrimaryAttack and Post
public PrimaryAttack5(id)
{
	new ent = get_pdata_cbase(id, 41, 4)
	
	if (!g_has_rifles[ent])
		return
	
	g_isprimary = 1
	
	g_clip_ammo[ent] = cs_get_weapon_ammo(id)

}

public PrimaryAttack_Post5(id)
{
	g_isprimary = 0
	new ent = get_pdata_cbase(id, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(ent, szClip, szAmmo)
	
	if(!is_user_alive(ent))
		return
		
	if(g_has_rifles[ent])
	{
		if (!g_clip_ammo[ent])
			return
		
		new Float:push[3]
		pev(ent,pev_punchangle,push)
		xs_vec_sub(push,recoil[ent],push)
		
		xs_vec_mul_scalar(push, g_skin[ent]==1?0.8:rifles_RECOIL,push)
		xs_vec_add(push,recoil[ent],push)
		set_pev(ent,pev_punchangle,push)
		
		set_anim(ent, random_num(ANIM_SHOOT1,ANIM_SHOOT3))
		set_pdata_float(id, 48, 0.4, 4)
		emit_sound(id, CHAN_WEAPON, Fire_Sound[g_skin[ent]], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
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

public ItemPostFrame5(wpn, uc_handle) 
{
	new id = pev(wpn, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_rifles[id])
		return HAM_IGNORED

	static iClipExtra
     
	iClipExtra = rifles_CLIP
	new Float:flNextAttack = get_pdata_float(id, 83, 5)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_RIFLES)
	new iClip = get_pdata_int(wpn, 51, 4)

	new fInReload = get_pdata_int(wpn, 54, 4)

	if( fInReload && flNextAttack <= 0.0 )
	{			
		new j = min(iClipExtra - iClip, iBpAmmo)

		set_pdata_int(wpn, 51, iClip + j, 4)
		cs_set_user_bpammo(id, CSW_RIFLES, iBpAmmo-j)
		
		set_pdata_int(wpn, 54, 0, 4)

		fInReload = 0
	}		

	return HAM_IGNORED
}

public Reload5(wpn) 
{
	new id = pev(wpn, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_rifles[id])
		return HAM_IGNORED

	static iClipExtra

	iClipExtra = rifles_CLIP

	g_clip[id] = -1
	
	new iClip = get_pdata_int(wpn, 51, 4)
	new iBpAmmo = cs_get_user_bpammo(id, CSW_RIFLES)
		
	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE

	if (iClip >= iClipExtra)
		return HAM_SUPERCEDE

	g_clip[id] = iClip

	return HAM_IGNORED
}

public Reload_Post5(wpn) 
{
	new id = pev(wpn, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_has_rifles[id])
		return HAM_IGNORED

	if (g_clip[id] == -1)
		return HAM_IGNORED
	
	set_pdata_float(wpn, 48, g_skin[id]==1?2.0:Reload_Time, 4)
	set_pdata_float(id, 83, g_skin[id]==1?2.0:Reload_Time, 5)

	set_pdata_int(wpn, 51, g_clip[id], 4)
	set_pdata_int(wpn, 54, 1, 4)

	set_anim(id, ANIM_RELOAD)

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
        
	if(get_user_weapon(iAttacker) == CSW_RIFLES)
	{
		if(g_has_rifles[iAttacker]){
			switch(g_skin[iAttacker]){
				case AT15_HW: set_msg_arg_string(4, "at15hw")
				case AK47_K_TRANSFORMER: set_msg_arg_string(4, "ak47")
				default: set_msg_arg_string(4, "m4a1")
			}
		}
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
					if (dropwhat == 1 && ((1<<weaponid) & (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)))
					{
							 static wname[32]
							 get_weaponname(weaponid, wname, sizeof wname - 1)
							 engclient_cmd(id, "drop", wname)
					}
		 }
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
