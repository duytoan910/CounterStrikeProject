#include <amxmodx>
#include <cstrike>
#include <engine>
#include <xs>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <zombieplague>
#include <metadrawer>

#define MAX_PLAYERS  32

#define WEAPONKEY     651969

#define RELOAD_TIME   1.95

#define ANIM_SHOOT1        4
#define ANIM_SHOOT2        5
#define ANIM_DRAW       2
#define ANIM_RELOAD   1

#define AMMO_CLIP        50
#define AMMO_BP           200

#define WPN_DAMAGE  2.0
#define WPN_RECOIL      0.7
#define WPN_SPEED      0.9
#define FROZENTIME 3.0

#define V_MODEL "models/v_buffsg552.mdl"
#define P_MODEL "models/p_buffsg552.mdl"
#define W_MODEL "models/w_buffsg552.mdl"

#define V_MODEL_6 "models/v_buffsg552_6.mdl"
#define P_MODEL_6 "models/p_buffsg552_6.mdl"

#define FIRE_SOUND "weapons/buffsg552-1.wav"
#define EFFECT_TGA "gfx/tga_image/Freeze.tga"

#define write_coord_f(%1) engfunc(EngFunc_WriteCoord,%1)

native navtive_bullet_effect(id, ent, ptr)

new g_itemid,g_has_sg552buff[33],g_orign_sg552buff, g_clip_ammo[33],g_weapon_TmpClip[33],oldweap[33],
Float:cl_pushangle[MAX_PLAYERS + 1][3],shell,g_HamBot
new shockwave_spr, g_skin[33]
new g_FrozeN[33]
new g_glassSpr,g_frost_gib,g_fire_gib
new dmgCount[33][33]

public plugin_init()
{
	register_plugin("Weapon sg552buff", "1.0", "lol")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")

	RegisterHam(Ham_Item_AddToPlayer, "weapon_sg552", "HAM_AddToPlayer")
	RegisterHam(Ham_Item_Deploy, "weapon_sg552", "HAM_Item_Deploy_Post",1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_sg552", "HAM_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_sg552", "HAM_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_sg552", "HAM_ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_sg552", "HAM_Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_sg552", "HAM_Reload_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "HAM_TakeDamage")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)

	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)

	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "Fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "Fw_PlaybackEvent")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	
	g_itemid = zp_register_extra_item("SG552 Lycanthrope", 3000, ZP_TEAM_HUMAN)
	md_loadimage(EFFECT_TGA)
}

public plugin_precache()
{
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_model(W_MODEL)
	precache_model(V_MODEL_6)
	precache_model(P_MODEL_6)

	precache_sound(FIRE_SOUND)
	precache_sound("zombie_plague/impalehit.wav")

	shell = precache_model("models/rshell.mdl")
	
	shockwave_spr = precache_model("sprites/shockwave.spr");
	g_frost_gib = precache_model("sprites/frost_gib.spr");
	g_fire_gib = precache_model("sprites/fire_gib.spr");
	
	g_glassSpr = engfunc(EngFunc_PrecacheModel, "models/glassgibs.mdl")
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
	g_has_sg552buff[id] = false
}

public client_disconnect(id) 
{
	g_has_sg552buff[id] = false
}

public zp_user_humanized_post(id) 
{
	g_has_sg552buff[id] = false
}

public zp_user_infected_post(id) 
{
	g_has_sg552buff[id] = false
}

public zp_extra_item_selected(id, itemid) 
{
	if(itemid == g_itemid)
	{
		drop_weapons(id, 1);
		g_skin[id] = random_num(0,1)
		g_has_sg552buff[id] = true
		new iWep2 = give_item(id,"weapon_sg552")
		if( iWep2 > 0 )
		{
			cs_set_weapon_ammo(iWep2, AMMO_CLIP)
			cs_set_user_bpammo (id, CSW_SG552, AMMO_BP)
			UTIL_PlayWeaponAnimation(id,ANIM_DRAW)
		}
	}
}

public give_sg552buff(id)
{
	drop_weapons(id, 1);
	g_skin[id] = random_num(0,1)
	g_has_sg552buff[id] = true
	new iWep2 = give_item(id,"weapon_sg552")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, AMMO_CLIP)
		cs_set_user_bpammo (id, CSW_SG552, AMMO_BP)
		UTIL_PlayWeaponAnimation(id,ANIM_DRAW)
	}
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_connected(iAttacker) || !is_user_alive(iAttacker))
		return HAM_IGNORED
	
	if(get_user_weapon(iAttacker) != CSW_SG552 || !g_has_sg552buff[iAttacker])
		return HAM_IGNORED

	navtive_bullet_effect(iAttacker, iEnt, ptr)
	
	return HAM_IGNORED
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
	
	if(equal(model, "models/w_sg552.mdl"))
	{
		static iStoredSVDID
		iStoredSVDID = find_ent_by_owner(-1, "weapon_sg552", entity)
		
		if(!is_valid_ent(iStoredSVDID))
			return FMRES_IGNORED;
			
		if(g_has_sg552buff[iOwner])
		{
			entity_set_int(iStoredSVDID, EV_INT_impulse, WEAPONKEY)
			g_has_sg552buff[iOwner] = false
			
			set_pev(iStoredSVDID, pev_iuser4, g_skin[iOwner])
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
	if(entity_get_int(weapon, EV_INT_impulse))
	{
		g_has_sg552buff[id] = true
		entity_set_int(weapon, EV_INT_impulse, 0)
		g_skin[id] = pev(weapon, pev_iuser4)
		return HAM_HANDLED;
	}
	return HAM_IGNORED;*/
	if(!is_valid_ent(weapon) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(weapon, EV_INT_impulse) == WEAPONKEY)
	{
		g_has_sg552buff[id] = true
		entity_set_int(weapon, EV_INT_impulse, 0)
		g_skin[id] = pev(weapon, pev_iuser4)
		
	}
	return HAM_IGNORED	
}

public HAM_Item_Deploy_Post(weapon_ent)
{
	new id = pev(weapon_ent,pev_owner)
	if (!is_user_connected(id) || zp_get_user_zombie(id) || zp_get_user_survivor(id))
		return;
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	replace_weapon_models(id, weaponid)
	UTIL_PlayWeaponAnimation(id,ANIM_DRAW)
}

public HAM_PrimaryAttack(weapon)
{
	new Player = get_pdata_cbase(weapon, 41, 4)
	
	if (!g_has_sg552buff[Player])
		return;
		
	g_clip_ammo[Player] = cs_get_weapon_ammo(weapon)
}

public HAM_PrimaryAttack_Post(Weapon, shell_index)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(g_has_sg552buff[Player])
	{
		if (!g_clip_ammo[Player])
			return		
		
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push, WPN_RECOIL,push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		emit_sound(Player, CHAN_WEAPON, FIRE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		
		UTIL_PlayWeaponAnimation(Player, random_num(ANIM_SHOOT1, ANIM_SHOOT2))
		
		make_shell(Player)
	}
}

public Fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orign_sg552buff))
		return FMRES_IGNORED
		
	if (!(1 <= invoker <= get_maxplayers()))
		return FMRES_IGNORED
		
	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public CurrentWeapon(id)
{
	if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
		return;
	replace_weapon_models(id, read_data(2))
	
	if(read_data(2) != CSW_SG552 || !g_has_sg552buff[id])
		return	
	static Float:iSpeed
	if(g_has_sg552buff[id])
	iSpeed = WPN_SPEED
	
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
		//static name[64];
		//get_user_name(victim,name,sizeof(name))
		
		if(get_user_weapon(attacker) == CSW_SG552)
		{
			if(g_has_sg552buff[attacker])
			{			
				dmgCount[attacker][victim] += floatround(damage)
				//client_print(attacker,print_chat,"Damage: %i on %s",dmgCount[attacker][victim],name)
				if(dmgCount[attacker][victim] >= 1000)
				{
					Frozen(attacker,victim)
					dmgCount[attacker][victim] = 0
					emit_sound(victim, CHAN_WEAPON, "zombie_plague/impalehit.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				}	
				SetHamParamFloat(4, damage * WPN_DAMAGE)
			}

		}
	}
}

public Player_Spawn(id)
{
	g_FrozeN[id] = false
	
	for(new i=0;i<get_maxplayers();i++)
	{
		dmgCount[id][i]=0
	}
	g_has_sg552buff[id] = false
}
public Frozen(attacker, id)
{
	// Not alive
	if (!is_user_alive(id))
		return;
	if (!zp_get_user_zombie(id))
		return;
	if (zp_get_user_nemesis(id))
		return;
	if(g_FrozeN[id])
		return;

	g_FrozeN[id] = true
	emit_sound(id, CHAN_WEAPON, "zombie_plague/impalehit.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	static Float:originF[3]
	pev(id, pev_origin, originF)
	FrostEffect(id, attacker)
	FrostEffectRing(attacker,originF)
	
	set_task(FROZENTIME,"UnFrozen",id)
}
public UnFrozen(id)
{
	fm_set_rendering(id)
	g_FrozeN[id] = false
	
	static origin2[3]
	get_user_origin(id, origin2)

	message_begin(MSG_PVS, SVC_TEMPENTITY, origin2)
	write_byte(TE_BREAKMODEL)
	write_coord(origin2[0])
	write_coord(origin2[1])
	write_coord(origin2[2] + 24)
	write_coord(16)
	write_coord(16)
	write_coord(16)
	write_coord(random_num(-50, 50))
	write_coord(random_num(-50, 50))
	write_coord(25)
	write_byte(10)
	write_short(g_glassSpr)
	write_byte(10)
	write_byte(25)
	write_byte(0x01)
	message_end()
}
// Forward Player PreThink
public fw_PlayerPreThink(id)
{
	// Not alive
	if (!is_user_alive(id))
		return;
	if (!zp_get_user_zombie(id))
		return;
		
	// Set Player MaxSpeed
	if (g_FrozeN[id]) 
	{
		set_pev(id, pev_velocity, Float:{0.0,0.0,0.0}) // stop motion
		set_pev(id, pev_maxspeed, 1.0) // prevent from moving
	}
}  
public HAM_ItemPostFrame(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;
		
	if (!g_has_sg552buff[id])
		return HAM_IGNORED;
		
	new Float:flNextAttack = get_pdata_float(id, 83, 5)
	new iBpAmmo = cs_get_user_bpammo(id, CSW_SG552);
	new iClip = get_pdata_int(weapon_entity, 51, 4)
	new fInReload = get_pdata_int(weapon_entity,54, 4)
	
	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(AMMO_CLIP - iClip, iBpAmmo)
		set_pdata_int(weapon_entity, 51, iClip + j, 4)
		cs_set_user_bpammo(id, CSW_SG552, iBpAmmo-j);
		set_pdata_int(weapon_entity, 54, 0, 4)
		fInReload = 0
	}
	return HAM_IGNORED;
}

public HAM_Reload(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;
		
	if (!g_has_sg552buff[id])
		return HAM_IGNORED;
		
	g_weapon_TmpClip[id] = -1;
	
	new iBpAmmo = cs_get_user_bpammo(id, CSW_SG552);
	new iClip = get_pdata_int(weapon_entity, 51, 4)
	
	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE;
		
	if (iClip >= AMMO_CLIP)
		return HAM_SUPERCEDE;
		
	g_weapon_TmpClip[id] = iClip;
	return HAM_IGNORED;
}

public HAM_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	
	if (!is_user_connected(id))
		return HAM_IGNORED;
		
	if (!g_has_sg552buff[id])
		return HAM_IGNORED;
		
	if (g_weapon_TmpClip[id] == -1)
		return HAM_IGNORED;
		
	set_pdata_int(weapon_entity, 51, g_weapon_TmpClip[id], 4)
	set_pdata_float(weapon_entity,48, RELOAD_TIME,4)
	set_pdata_float(id, 83, RELOAD_TIME, 5)
	set_pdata_int(weapon_entity, 54, 1, 4)
	UTIL_PlayWeaponAnimation(id, ANIM_RELOAD)
	return HAM_IGNORED;
}

public Fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_SG552 || !g_has_sg552buff[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_SG552:
		{
			if(g_has_sg552buff[id])
			{
				set_pev(id, pev_viewmodel2, g_skin[id]?V_MODEL_6:V_MODEL)
				set_pev(id, pev_weaponmodel2, g_skin[id]?P_MODEL_6:P_MODEL)
				if(oldweap[id] != CSW_SG552) 
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
	
	if(equal(szTruncatedWeapon, "sg552") && get_user_weapon(iAttacker) == CSW_SG552)
	{
		if(g_has_sg552buff[iAttacker])
			set_msg_arg_string(4, "buffsg552")		
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

stock make_shell(id)
{
	static Float:player_origin[3],Float:origin[3],Float:origin2[3],Float:gunorigin[3], Float:oldangles[3],Float:v_forward[3], Float:v_forward2[3], Float:v_up[3],Float:v_up2[3],Float:v_right[3],Float:v_right2[3],Float:viewoffsets[3];
	pev(id,pev_v_angle, oldangles)
	pev(id,pev_origin,player_origin)
	pev(id, pev_view_ofs, viewoffsets);

	engfunc(EngFunc_MakeVectors, oldangles);

	global_get(glb_v_forward, v_forward);
	global_get(glb_v_up, v_up);
	global_get(glb_v_right, v_right);

	global_get(glb_v_forward, v_forward2);
	global_get(glb_v_up, v_up2);
	global_get(glb_v_right, v_right2);

	xs_vec_add(player_origin, viewoffsets, gunorigin);

	xs_vec_mul_scalar(v_forward, 8.3, v_forward);
	xs_vec_mul_scalar(v_right, 5.0 , v_right);
	xs_vec_mul_scalar(v_up, -5.0, v_up);

	xs_vec_mul_scalar(v_forward2, random_float ( -15.0 , -20.0 ), v_forward2);
	xs_vec_mul_scalar(v_right2, random_float ( 10.0 , 18.0 ), v_right2);
	xs_vec_mul_scalar(v_up2, random_float ( -12.0 , -18.0) , v_up2);

	xs_vec_add(gunorigin, v_forward, origin);
	xs_vec_add(gunorigin, v_forward2, origin2);
	xs_vec_add(origin, v_right, origin);
	xs_vec_add(origin2, v_right2, origin2);
	xs_vec_add(origin, v_up, origin);
	xs_vec_add(origin2, v_up2, origin2);

	new Float:velocity[3]
	get_speed_vector(origin2,origin,random_float(120.0, 140.0),velocity)
	
	new angle = random_num(180, 360)

	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY,_,id)
	write_byte(TE_MODEL)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	engfunc(EngFunc_WriteCoord, velocity[0])
	engfunc(EngFunc_WriteCoord, velocity[1])
	engfunc(EngFunc_WriteCoord, velocity[2])
	write_angle(angle)
	write_short(shell)
	write_byte(1)
	write_byte(30)
	message_end()
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

// Frost Effect
public FrostEffect(id, attacker)
{
	// Only effect alive unfrozen zombies
	if (!is_user_alive(id) || !zp_get_user_zombie(id))
	return;
	
	new color[3];
	color[0] = g_skin[attacker]?200:0
	color[1] = 100
	color[2] = g_skin[attacker]?0:200
	if(!is_user_bot(id))
		md_drawimage(id, 4, 0, EFFECT_TGA, 0.5, 0.5, 1, 1, color[0], color[1], color[2], 255, 0.1, 2.0, 0.1, ALIGN_NORMAL, md_getscreenwidth(), md_getscreenheight())
	
	fm_set_rendering(id, kRenderFxGlowShell, color[0], color[1], color[2], kRenderNormal, 25)
}

// Frost Effect Ring
FrostEffectRing(id, const Float:originF3[3])
{
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST ,SVC_TEMPENTITY, originF3, 0) 
	write_byte(TE_SPRITETRAIL) // TE ID 
	engfunc(EngFunc_WriteCoord, originF3[0]) // x axis 
	engfunc(EngFunc_WriteCoord, originF3[1]) // y axis 
	engfunc(EngFunc_WriteCoord, originF3[2]+70) // z axis 
	engfunc(EngFunc_WriteCoord, originF3[0]) // x axis 
	engfunc(EngFunc_WriteCoord, originF3[1]) // y axis 
	engfunc(EngFunc_WriteCoord, originF3[2]) // z axis 
	write_short(g_skin[id]?g_fire_gib:g_frost_gib) // Sprite Index 
	write_byte(80) // Count 
	write_byte(20) // Life 
	write_byte(2) // Scale 
	write_byte(50) // Velocity Along Vector 
	write_byte(10) // Rendomness of Velocity 
	message_end(); 
	
	new color[3];
	color[0] = g_skin[id]?200:0
	color[1] = 100
	color[2] = g_skin[id]?0:200
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF3, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF3[0]) // x
	engfunc(EngFunc_WriteCoord, originF3[1]) // y
	engfunc(EngFunc_WriteCoord, originF3[2]) // z
	engfunc(EngFunc_WriteCoord, originF3[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF3[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF3[2]+60.0) // z axis
	write_short(shockwave_spr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(color[0]) // red
	write_byte(color[1]) // green
	write_byte(color[2]) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF3, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF3[0]) // x
	engfunc(EngFunc_WriteCoord, originF3[1]) // y
	engfunc(EngFunc_WriteCoord, originF3[2]) // z
	engfunc(EngFunc_WriteCoord, originF3[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF3[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF3[2]+80.0) // z axis
	write_short(shockwave_spr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(color[0]) // red
	write_byte(color[1]) // green
	write_byte(color[2]) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF3, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF3[0]) // x
	engfunc(EngFunc_WriteCoord, originF3[1]) // y
	engfunc(EngFunc_WriteCoord, originF3[2]) // z
	engfunc(EngFunc_WriteCoord, originF3[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF3[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF3[2]+100.0) // z axis
	write_short(shockwave_spr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(color[0]) // red
	write_byte(color[1]) // green
	write_byte(color[2]) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}
