#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <xs>
#include <zombieplague>

#define WEAPONKEY 332
#define RELOAD_TIME 3.0
#define wId CSW_AUG
#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const Fire_snd[] = {"weapons/balrog5-1.wav"}
new const went[] ={"weapon_aug"}
new balrog5_V_MODEL[64] = "models/v_balrog5.mdl"
new balrog5_P_MODEL[64] = "models/p_balrog5.mdl"
new balrog5_W_MODEL[64] = "models/w_balrog5.mdl"

new balrog5_V_MODELB[64] = "models/v_balrog5b.mdl"

new g_itemid_balrog5
new g_has_balrog5[33]
new g_orig_event_balrog5, g_clip_ammo[33]
new g_balrog5_TmpClip[33],spritebalrog, spritebalrogb
new count[33]
new g_bot
new Float:cl_pushangle[32 + 1][3]

new g_skin[33]

native navtive_bullet_effect(id, ent, ptr)

public plugin_init()
{
	register_plugin("[ZP]Balrog-V", "1.0", "Barney")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	
	RegisterHam(Ham_Item_AddToPlayer, went, "fw_balrog5_AddToPlayer")	
	
	RegisterHam(Ham_Item_Deploy, went, "fw_Item_Deploy_Post",1)
	RegisterHam(Ham_Weapon_PrimaryAttack, went, "fw_balrog5_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, went, "fw_balrog5_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, went, "balrog5__ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, went, "balrog5__Reload");
	RegisterHam(Ham_Weapon_Reload, went, "balrog5__Reload_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "worldspawn", "TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	g_itemid_balrog5 = zp_register_extra_item("Balrog-V", 3000, ZP_TEAM_HUMAN)
}
public plugin_precache()
{
	precache_model(balrog5_V_MODEL)
	precache_model(balrog5_P_MODEL)
	precache_model(balrog5_W_MODEL)
	precache_model(balrog5_V_MODELB)
	
	precache_sound(Fire_snd)
	spritebalrog=precache_model("sprites/balrog5stack.spr")
	spritebalrogb=precache_model("sprites/balrog5stack_blue.spr")
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
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_balrog5[id] = false
	}
}
public Player_Spawn(id)
{
	g_has_balrog5[id] = false
}
public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[64]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(entity, pev_owner)
	
	if(equal(model, "models/w_aug.mdl"))
	{
		static weapon
		weapon = fm_get_user_weapon_entity(entity, wId)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_has_balrog5[id])
		{
			set_pev(weapon, pev_impulse, WEAPONKEY)
			set_pev(weapon, pev_iuser4, g_skin[id])
			engfunc(EngFunc_SetModel, entity, balrog5_W_MODEL)
			
			g_has_balrog5[id] = false
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED;
}
public fw_balrog5_AddToPlayer(ent, id)
{
	if(!is_user_alive(id))
		return;
	if(pev(ent, pev_impulse) == WEAPONKEY)
	{
		g_has_balrog5[id] = 1
		
		set_pev(ent, pev_impulse, 0)
		g_skin[id] = pev(ent, pev_iuser4)
		
		UTIL_PlayWeaponAnimation(id,5)
	}		
}
public give_balrog5(id)
{
	drop_weapons(id, 1);
	new iWep2 = give_item(id,went)
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, 50)
		cs_set_user_bpammo (id, wId, 300)
	}
	g_skin[id] = random_num(0,1)
	g_has_balrog5[id] = true
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_itemid_balrog5)
	{
		give_balrog5(id)
		UTIL_PlayWeaponAnimation(id,5)
	}
}
public fw_Item_Deploy_Post(weapon_ent)
{
	new id = pev(weapon_ent,pev_owner)
	if (!is_user_connected(id) || zp_get_user_zombie(id) || zp_get_user_survivor(id))
		return;
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	replace_weapon_models(id, weaponid)
	UTIL_PlayWeaponAnimation(id,5)
}
public CurrentWeapon(id)
{
	if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
		return;
	replace_weapon_models(id, read_data(2))
}
replace_weapon_models(id, weaponid)
{
switch (weaponid)
{
	case wId:
	{
		if(g_has_balrog5[id])
		{
			set_pev(id, pev_viewmodel2, g_skin[id]?balrog5_V_MODELB:balrog5_V_MODEL)
			set_pev(id, pev_weaponmodel2, balrog5_P_MODEL)
		}
	}
}
}
public fw_UpdateClientData_Post(id, SendWeapons, CD_Handle)
{
	if(!is_user_alive(id) 
	|| ((get_user_weapon(id) != wId) 
	|| (get_user_weapon(id) == wId && !g_has_balrog5[id])))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED		
}
public fw_balrog5_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	if (!g_has_balrog5[Player])
		return;
	
	pev(Player,pev_punchangle,cl_pushangle[Player])
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}
public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_balrog5))
		return FMRES_IGNORED
	if (!(1 <= invoker <= get_maxplayers()))
		return FMRES_IGNORED
	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}
public fw_balrog5_PrimaryAttack_Post(Weapon)
{	
	new Player = get_pdata_cbase(Weapon, 41, 4)
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	if(Player > 0 && Player < 33)
	{
		if(g_has_balrog5[Player])
		{
			if(szClip > 0)emit_sound(Player, CHAN_WEAPON, Fire_snd, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		}
		if(g_has_balrog5[Player])
		{
			if (!g_clip_ammo[Player])
				return
			
			new Float:push[3]
			pev(Player,pev_punchangle,push)
			xs_vec_sub(push,cl_pushangle[Player],push)
			
			xs_vec_mul_scalar(push,1.0,push)
			xs_vec_add(push,cl_pushangle[Player],push)
			set_pev(Player,pev_punchangle,push)
			
			UTIL_PlayWeaponAnimation(Player, random_num(1,2))
		}
	}
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == wId)
		{
			if(g_has_balrog5[attacker])
			{
				static Float:lastdamage[33]
				if( lastdamage[attacker] + 0.5 < get_gametime() ) count[attacker] = 0
				if( count[attacker] > 5 ) 
				{
					new Float:fStart[3],TE_FLAG
					pev( victim, pev_origin, fStart)
					
					TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
					TE_FLAG |= TE_EXPLFLAG_NOSOUND
					TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
					
					// Exp
					message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
					write_byte(TE_EXPLOSION)
					engfunc(EngFunc_WriteCoord, fStart[0])
					engfunc(EngFunc_WriteCoord, fStart[1])
					engfunc(EngFunc_WriteCoord, fStart[2]+35.0)
					write_short(g_skin[attacker]?spritebalrogb:spritebalrog)// sprite index
					write_byte(4)	// scale in 0.1's
					write_byte(25)	// framerate
					write_byte(TE_FLAG)	// flags
					message_end()
					SetHamParamFloat(4, damage*2.8)
				}
				else 
				{
					count[attacker] ++
					SetHamParamFloat(4, damage*1.7)
				}
				lastdamage[attacker] = get_gametime()
			}
		}
	}
}

public TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker))
		return

	new g_currentweapon = get_user_weapon(attacker)

	if((g_currentweapon != wId) 
	|| (g_currentweapon == wId && !g_has_balrog5[attacker])) return;
	
	navtive_bullet_effect(attacker, ent, ptr)
}
stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}
public balrog5__ItemPostFrame(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;
	if (!g_has_balrog5[id])
		return HAM_IGNORED;
	new Float:flNextAttack = get_pdata_float(id, 83, 5)
	new iBpAmmo = cs_get_user_bpammo(id, wId);
	new iClip = get_pdata_int(weapon_entity, 51, 4)
	new fInReload = get_pdata_int(weapon_entity,54, 4)
	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(50 - iClip, iBpAmmo)
		set_pdata_int(weapon_entity, 51, iClip + j, 4)
		cs_set_user_bpammo(id, wId, iBpAmmo-j);
		set_pdata_int(weapon_entity, 54, 0, 4)
		fInReload = 0
	}
	return HAM_IGNORED;
}
public balrog5__Reload(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;
	if (!g_has_balrog5[id])
		return HAM_IGNORED;
	g_balrog5_TmpClip[id] = -1;
	new iBpAmmo = cs_get_user_bpammo(id, wId);
	new iClip = get_pdata_int(weapon_entity, 51, 4)
	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE;
	if (iClip >= 50)
		return HAM_SUPERCEDE;
	g_balrog5_TmpClip[id] = iClip;
	return HAM_IGNORED;
}
public balrog5__Reload_Post(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;
	if (!g_has_balrog5[id])
		return HAM_IGNORED;
	if (g_balrog5_TmpClip[id] == -1)
		return HAM_IGNORED;
	set_pdata_int(weapon_entity, 51, g_balrog5_TmpClip[id], 4)
	set_pdata_float(weapon_entity,48, RELOAD_TIME,4)
	set_pdata_float(id, 83, RELOAD_TIME, 5)
	set_pdata_int(weapon_entity, 54, 1, 4)
	UTIL_PlayWeaponAnimation(id, 4)
	return HAM_IGNORED;
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
public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(get_user_weapon(iAttacker) == wId)
	{
		if(g_has_balrog5[iAttacker])
			set_msg_arg_string(4, "balrog5")
	}
                
	return PLUGIN_CONTINUE
}
