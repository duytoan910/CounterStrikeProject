#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>
#include <toan> 

#define EV_INT_WEAPONKEY	EV_INT_impulse
#define WEAPONKEY 7213
#define JANUS7_CLIPAMMO	150
#define JANUS7_BPAMMO	200
#define JANUS7_DAMAGE	1.4
#define RELOAD_TIME 4.7
#define wId CSW_M249
#define SHOOT_NEED 100
#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

#define JANUS7_VMODEL "models/v_janus7.mdl"
#define JANUS7_PMODEL "models/p_janus7.mdl"
#define JANUS7_WMODEL "models/w_janus7.mdl"

#define JANUS7_VMODEL_X "models/v_janus7_xmas.mdl"
#define JANUS7_PMODEL_X "models/p_janus7_xmas.mdl"
#define JANUS7_WMODEL_X "models/w_janus7_xmas.mdl"

new const Fire_snd[][] = {"weapons/janus7-1.wav", "weapons/janus7-2.wav"};
new const went[] ="weapon_m249";

native navtive_bullet_effect(id, ent, ptr)

new  g_itemid_janus7,g_mode[33], g_shots[33], g_sprite, g_sprite_hit, g_sprite_hit_xmas,
g_target[33], g_sound[33],g_has_janus7[33],g_orig_event_janus7, g_clip_ammo[33],
Float:cl_pushangle[33][3], m_iBlood[2], g_janus7_TmpClip[33], g_ham_bot, g_skin[33]

public plugin_init()
{
	register_plugin("Janus-7",		"1.0",		"Akhremchik I.");
	register_clcmd("weapon_janus7", "Hook_Select");
	
	register_event("CurWeapon",	"CurrentWeapon",	"be","1=1");
	
	RegisterHam(Ham_Item_AddToPlayer,	went,	 	"fw_janus7_AddToPlayer");
	RegisterHam(Ham_Item_Deploy,		went,	 	"fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack,	went,	 	"fw_janus7_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack,	went,	 	"fw_janus7_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Item_PostFrame,		went,	 	"janus7__ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload,		went, 		"janus7__Reload");
	RegisterHam(Ham_Weapon_Reload,		went, 		"janus7__Reload_Post", 1);
	RegisterHam(Ham_TakeDamage, 		"player",	 "fw_TakeDamage");
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	register_forward(FM_SetModel,		 "fw_SetModel");
	register_forward(FM_UpdateClientData,	 "fw_UpdateClientData_Post", 1);
	register_forward(FM_PlaybackEvent,	 "fwPlaybackEvent");
	RegisterHam(Ham_TraceAttack, "worldspawn", "TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack")
	register_clcmd("setmode","set_mode")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	g_itemid_janus7 = zp_register_extra_item("Janus-VII", 6000, ZP_TEAM_HUMAN);
	
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
		if(g_has_janus7[iAttacker])
			set_msg_arg_string(4, "janus7")
	}
                
	return PLUGIN_CONTINUE
}

public Player_Spawn(id)
{
	g_has_janus7[id] = false
}
public client_putinserver(id)
{
	if(!g_ham_bot && is_user_bot(id))
	{
		g_ham_bot = 1
		set_task(0.1, "do_register", id)
	}
}

public do_register(id)
{
	RegisterHamFromEntity(Ham_Item_PostFrame,id,"janus7__ItemPostFrame")
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_Spawn, id, "Player_Spawn")
}
public plugin_precache()
{
	precache_model(JANUS7_VMODEL);
	precache_model(JANUS7_PMODEL);
	precache_model(JANUS7_WMODEL);
	precache_model(JANUS7_VMODEL_X);
	precache_model(JANUS7_PMODEL_X);
	precache_model(JANUS7_WMODEL_X);
	g_sprite = precache_model("sprites/lgtning.spr");
	g_sprite_hit = precache_model("sprites/ef_janus7_hit.spr");
	g_sprite_hit_xmas = precache_model("sprites/ef_janus7_hit_xmas.spr");
	precache_sound(Fire_snd[0]);
	precache_sound(Fire_snd[1]);
	precache_sound("weapons/janus7_change1.wav");
	precache_sound("weapons/janus7_change2.wav");
	precache_sound("weapons/change1_ready.wav")
	
	m_iBlood[0] = precache_model("sprites/blood.spr");
	m_iBlood[1] = precache_model("sprites/bloodspray.spr");	
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1);
	
}
public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/m249.sc", name))
	{
		g_orig_event_janus7 = get_orig_retval();
		return FMRES_HANDLED;
	}
	return FMRES_IGNORED;
}

public Hook_Select(id)
{
	engclient_cmd(id, went);
	return PLUGIN_HANDLED;
}


public client_connect(id)
{
	g_has_janus7[id] = false;
}

public client_disconnect(id)
{
	g_has_janus7[id] = false;
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_janus7[id] = false;
	}
}

public give_janus7(id)
{
	drop_weapons(id, 1);
	g_skin[id] = random_num(0,1)
	new iWep2 = fm_give_item(id,went);
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, JANUS7_CLIPAMMO);
		cs_set_user_bpammo (id, wId, JANUS7_BPAMMO);
	}
	g_has_janus7[id] = true;
	g_shots[id] = 0;
	g_target[id] = 0;
	g_skin[id] = random_num(0,1)
	g_mode[id] = false;
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_itemid_janus7)
	{
		give_janus7(id);
	}
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED;
		
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[64]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(entity, pev_owner)
	
	if(equal(model, "models/w_m249.mdl"))
	{
		static weapon
		weapon = fm_get_user_weapon_entity(entity, wId)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_has_janus7[id])
		{
			set_pev(weapon, pev_impulse, WEAPONKEY)
			set_pev(weapon, pev_iuser4, g_skin[id])
			
			engfunc(EngFunc_SetModel, entity, g_skin[id]?JANUS7_WMODEL_X:JANUS7_WMODEL)
			
			g_has_janus7[id] = false
			g_target[id] = 0;
			//remove_task(id+1231);
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED;
}

public fw_janus7_AddToPlayer(ent, id)
{
	if(pev(ent, pev_impulse) == WEAPONKEY)
	{
		g_has_janus7[id] = true;
		
		set_pev(ent, pev_impulse, 0)
		g_skin[id] = pev(ent, pev_iuser4)		
		g_sound[id] = 0;
		g_target[id] = 0;
		
		entity_set_int(ent, EV_INT_WEAPONKEY, 0);
	}		
}

public fw_Item_Deploy_Post(weapon_ent)
{
	static owner;
	owner = pev(weapon_ent, pev_owner);
	
	if(!is_user_alive(owner) || get_user_weapon(owner) != CSW_M249)
		return;
		
	if( g_mode[owner]) UTIL_PlayWeaponAnimation(owner, 8);
	else UTIL_PlayWeaponAnimation(owner, g_shots[owner]>SHOOT_NEED?14:2);
	set_pdata_float(owner, 83, 1.0, 5)
	
	static weaponid;
	weaponid = cs_get_weapon_id(weapon_ent);
	replace_weapon_models(owner, weaponid);
	
	g_target[owner] = 0;
}

public CurrentWeapon(id)	replace_weapon_models(id, read_data(2));

replace_weapon_models(id, weaponid)
{
	static g_wpn[33];
	switch (weaponid)
	{
		case wId:
		{
			if(is_user_alive(id) && is_user_connected(id) && g_has_janus7[id])
			{
				if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
					return;
				if(g_wpn[id] != CSW_M249)
				{
					if( g_mode[id]) UTIL_PlayWeaponAnimation(id, 8);
					else UTIL_PlayWeaponAnimation(id, g_shots[id]>SHOOT_NEED?14:2);
				}
				set_pev(id, pev_viewmodel2, g_skin[id]?JANUS7_VMODEL_X:JANUS7_VMODEL);
				set_pev(id, pev_weaponmodel2, g_skin[id]?JANUS7_PMODEL_X:JANUS7_PMODEL);
			}
		}
	}
	if(is_user_alive(id))g_wpn[id] = get_user_weapon(id);
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != wId) || !g_has_janus7[Player])
		return FMRES_IGNORED;
		
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001);
	return FMRES_HANDLED;
}

public fw_janus7_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4);
	if (!g_has_janus7[Player])
		return HAM_IGNORED;
	pev(Player,pev_punchangle,cl_pushangle[Player]);
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon);
	
	if( g_mode[Player] ) return HAM_SUPERCEDE;
	return HAM_IGNORED;
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_janus7))
		return FMRES_IGNORED;
		
	if (!(1 <= invoker <= get_maxplayers()))
		return FMRES_IGNORED;
		
	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2);
	return FMRES_SUPERCEDE;
}

public fw_janus7_PrimaryAttack_Post(Weapon) {
	
	new Player = get_pdata_cbase(Weapon, 41, 4);
	new szClip, szAmmo;
	get_user_weapon(Player, szClip, szAmmo);
	if(Player > 0 && Player < 33)
	{
		if(g_has_janus7[Player])
		{
			if(szClip > 0 && !g_sound[Player]) {
				emit_sound(Player, CHAN_WEAPON, Fire_snd[g_mode[Player]], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				if(g_mode[Player])g_sound[Player] = true;
			}
		}
		if(g_has_janus7[Player])
		{
			new Float:push[3];
			pev(Player,pev_punchangle,push);
			xs_vec_sub(push,cl_pushangle[Player],push);
			xs_vec_mul_scalar(push,0.9,push);
			xs_vec_add(push,cl_pushangle[Player],push);
			set_pev(Player,pev_punchangle,push);
			
			if (!g_clip_ammo[Player])
				return;
				
			set_pdata_float(Player, 83, g_mode[Player]?0.06:0.08);
			
			if(g_mode[Player]) UTIL_PlayWeaponAnimation(Player, random_num(9,10));
			else UTIL_PlayWeaponAnimation(Player, g_shots[Player]>=SHOOT_NEED? 5 : random_num(3,4));
			
			if(!g_mode[Player]&&g_shots[Player]==SHOOT_NEED-1)				
				emit_sound(Player, CHAN_WEAPON, "weapons/change1_ready.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			
			g_shots[Player] ++
			//client_print(Player, print_center,"Shot: %i",g_shots[Player])
			new Float:origin1[3], targ, body
			
			if( g_target[Player] ) 
			{
				pev(g_target[Player], pev_origin, origin1);
			}
			else 
			fm_get_aim_origin(Player, origin1);
			
			get_user_aiming(Player, targ, body);
			
			if(g_mode[Player]) {
				message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
				write_byte(TE_BEAMENTPOINT)
				write_short(Player| 0x1000) 
				write_coord(floatround(origin1[0]));
				write_coord(floatround(origin1[1]));
				write_coord(floatround(origin1[2]));
				write_short(g_sprite)
				write_byte(0) // framerate
				write_byte(0) // framerate
				write_byte(1) // life
				write_byte(15)  // width
				write_byte(30)   // noise
				write_byte(255)   // r, g, b
				write_byte(g_skin[Player]?0:170)   // r, g, b
				write_byte(0)   // r, g, b
				write_byte(255)	// brightness
				write_byte(25)		// speed
				message_end()     
				if( targ && is_user_alive(targ) && zp_get_user_zombie(targ) && !g_target[Player]) {
					
					pev(targ, pev_origin, origin1);
					ExecuteHam(Ham_TakeDamage, targ, Player, Player, is_deadlyshot(Player)?JANUS7_DAMAGE*random_float(25.0,35.0)*1.5:JANUS7_DAMAGE*random_float(25.0,35.0), DMG_SLASH);
			
			
					g_target[Player] = targ;
					message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
					write_byte(TE_EXPLOSION);
					write_coord(floatround(origin1[0]));
					write_coord(floatround(origin1[1]));
					write_coord(floatround(origin1[2]));
					write_short(g_skin[Player]?g_sprite_hit_xmas:g_sprite_hit);
					write_byte(4);
					write_byte(30);
					write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NODLIGHTS);
					message_end(); 
					
					// Alive...
					new a = FM_NULLENT
					// Get distance between victim and epicenter
					while((a = find_ent_in_sphere(a, origin1, 50.0)) != 0)
					{
						if (Player == a)
							continue 
						if (targ == a)
							continue 
							
						if(pev(a, pev_takedamage) != DAMAGE_NO)
						{
							ExecuteHam(Ham_TakeDamage, a, Player, Player, is_deadlyshot(Player)?JANUS7_DAMAGE*random_float(15.0,25.0)*1.5:JANUS7_DAMAGE*random_float(25.0,35.0), DMG_SLASH);
						}
					}
					
				}
				else if( g_target[Player] && is_user_alive(g_target[Player]) && zp_get_user_zombie(g_target[Player]) ) {
					
					ExecuteHam(Ham_TakeDamage, g_target[Player], Player, Player, is_deadlyshot(Player)?JANUS7_DAMAGE*random_float(25.0,35.0)*1.5:JANUS7_DAMAGE*random_float(25.0,35.0), DMG_SLASH);
					pev(g_target[Player], pev_origin, origin1);
					
					message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
					write_byte(TE_EXPLOSION);
					write_coord(floatround(origin1[0]));
					write_coord(floatround(origin1[1]));
					write_coord(floatround(origin1[2]));
					write_short(g_skin[Player]?g_sprite_hit_xmas:g_sprite_hit);
					write_byte(4);
					write_byte(30);
					write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NODLIGHTS);
					message_end(); 
					
					// Alive...
					new a = FM_NULLENT
					// Get distance between victim and epicenter
					while((a = find_ent_in_sphere(a, origin1, 50.0)) != 0)
					{
						if (Player == a)
							continue 
						if (g_target[Player] == a)
							continue 
							
						if(pev(a, pev_takedamage) != DAMAGE_NO)
						{
							ExecuteHam(Ham_TakeDamage, a, Player, Player, is_deadlyshot(Player)?JANUS7_DAMAGE*random_float(15.0,25.0)*1.5:JANUS7_DAMAGE*random_float(25.0,35.0), DMG_SLASH);
						}
					}
				}
	
			}
			
		}
	}
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == wId)
		{
			if(g_has_janus7[attacker]) {
				SetHamParamFloat(4, damage * JANUS7_DAMAGE);
			}
		}
	}
}
stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence);
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player);
	write_byte(Sequence);
	write_byte(0);
	message_end();
}
	
stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	new Float:vfEnd[3] 
	fm_get_aim_origin(id, vfEnd);
	new Float:fOrigin[3], Float:fAngle[3]
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	new Float:fAttack[3]
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	new Float:fRate
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	xs_vec_add(fOrigin, fAttack, output)
}

public janus7__ItemPostFrame(weapon_entity) {
	new id = pev(weapon_entity, pev_owner);
	if (!is_user_connected(id))
		return HAM_IGNORED;
		
	if (!g_has_janus7[id])
		return HAM_IGNORED;
		
	if(get_user_weapon(id) != CSW_M249)
		g_target[id] = 0
		
	new Float:flNextAttack = get_pdata_float(id, 83, 5);
	new iBpAmmo = cs_get_user_bpammo(id, wId);
	new iClip = get_pdata_int(weapon_entity, 51, 4);
	new fInReload = get_pdata_int(weapon_entity, 54, 4);
	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(JANUS7_CLIPAMMO- iClip, iBpAmmo);
		set_pdata_int(weapon_entity, 51, iClip + j, 4);
		cs_set_user_bpammo(id, wId, iBpAmmo-j);
		set_pdata_int(weapon_entity, 54, 0, 4);
		fInReload = 0;
	}
	new Float:origin[3];
	pev(g_target[id], pev_origin, origin);
	
	if(is_user_bot(id) && g_shots[id] >= SHOOT_NEED && flNextAttack <= 0.0 && !g_mode[id]) set_mode(id)
	if(!is_user_bot(id) && g_shots[id] >= SHOOT_NEED && flNextAttack <= 0.0 && !g_mode[id] ) {
		
		UTIL_PlayWeaponAnimation(id, 12);
		//if(is_user_bot(id) || !is_user_bot(id)) set_mode(id)
		if( get_user_button(id) & IN_ATTACK2 && flNextAttack <= 0.0 ) 
		{
			set_pdata_int(weapon_entity, 51, iClip + 1, 4);
			UTIL_PlayWeaponAnimation(id, 6);
			set_pdata_float( id, 83, 2.0);
			g_mode[id] = 1;
			g_shots[id] = 0;
			set_task( 20.0, "remove_mode", id+1231 );
		}
			
	
	}
	else if (g_mode[id] && flNextAttack <= 0.0 ) {
		
		if( !(get_user_button(id) & IN_ATTACK) ) {
			g_target[id] = 0;
			emit_sound(id, CHAN_WEAPON, Fire_snd[g_mode[id]], 0.0, ATTN_NORM, 0, PITCH_NORM);
			g_sound[id] = 0;
		}
		if( !is_user_alive(g_target[id]) || !zp_get_user_zombie(g_target[id])  || !can_see_fm(id,g_target[id]) || !is_in_viewcone(id, origin))
			g_target[id] = 0;
		
		UTIL_PlayWeaponAnimation(id, 7);
		
	}
	return HAM_IGNORED;
}
public set_mode(id)
{
	UTIL_PlayWeaponAnimation(id, 6);
	set_pdata_float( id, 83, 2.0);
	g_mode[id] = 1;
	g_shots[id] = 0;
	set_task( 20.0, "remove_mode", id+1231 );	
}
public remove_mode(id) {
	id-=1231;
	//if(!g_mode[id]) return;
	g_mode[id] = false;
	g_shots[id] = false;
	g_sound[id] = false;
	g_target[id] = 0;
	emit_sound(id, CHAN_WEAPON, Fire_snd[g_mode[id]], 0.0, ATTN_NORM, 0, PITCH_NORM);
	UTIL_PlayWeaponAnimation(id, 11);
	set_pdata_float(id, 83, 2.0);
}
	
public janus7__Reload(weapon_entity) {
	new id = pev(weapon_entity, pev_owner);
	if (!is_user_connected(id))
		return HAM_IGNORED;
	if (!g_has_janus7[id])
		return HAM_IGNORED;
	if(g_mode[id])
		return HAM_SUPERCEDE;
	g_janus7_TmpClip[id] = -1;
	new iBpAmmo = cs_get_user_bpammo(id, wId);
	new iClip = get_pdata_int(weapon_entity, 51, 4);
	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE;
	if (iClip >= JANUS7_CLIPAMMO)
		return HAM_SUPERCEDE;
	g_janus7_TmpClip[id] = iClip;
	return HAM_IGNORED;
}
public janus7__Reload_Post(weapon_entity) {
	new id = pev(weapon_entity, pev_owner);
	if (!is_user_connected(id))
		return HAM_IGNORED;
	if (!g_has_janus7[id])
		return HAM_IGNORED;
	if (g_janus7_TmpClip[id] == -1)
		return HAM_IGNORED;
	if(g_mode[id])
		return HAM_SUPERCEDE;
	set_pdata_int(weapon_entity, 51, g_janus7_TmpClip[id], 4);
	set_pdata_float(weapon_entity, 48, RELOAD_TIME, 4);
	set_pdata_float(id, 83, RELOAD_TIME, 5);
	set_pdata_int(weapon_entity, 54, 1, 4);
	if( g_mode[id]) g_mode[id] = 0;
	UTIL_PlayWeaponAnimation(id, g_shots[id]>SHOOT_NEED?13:1);
	return HAM_IGNORED;
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid;
	num = 0;
	get_user_weapons(id, weapons, num);
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i];
		const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|
		(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)| (1<<CSW_M249)|(1<<CSW_M3)|
		(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90);
		if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		{
			static wname[32];
			get_weaponname(weaponid, wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname);
		}
	}
}

public TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker))
		return
	if(g_mode[attacker])
		return
	new g_currentweapon = get_user_weapon(attacker)

	if((g_currentweapon != wId) 
	|| (g_currentweapon == wId && !g_has_janus7[attacker])) return;
	
	navtive_bullet_effect(attacker, ent, ptr)
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
