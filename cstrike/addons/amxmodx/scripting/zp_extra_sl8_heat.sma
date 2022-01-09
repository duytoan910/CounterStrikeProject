#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define PLUGIN "[ZP] Extra Item: SL8 Heat"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define CSW_SL8HEAT CSW_G3SG1
#define weapon_sl8heat "weapon_g3sg1"
const pev_check = pev_impulse
#define SECRET_KEY 1541912

new const sl8heat_model[4][] = 
{
	"models/v_sl8ex.mdl",
	"models/p_sl8ex.mdl",
	"models/w_sl8ex.mdl",
	"models/rshell.mdl"
}
new const sl8heat_sound[4][] =
{
	"weapons/sl8ex-1.wav",
	"weapons/sl8ex_clipin.wav",
	"weapons/sl8ex_clipout.wav",
	"weapons/sl8ex_draw.wav"
}
new const sl8heat_resource[3][] =
{
	"sprites/weapon_sl8ex.txt",
	"sprites/zoom_custom9.txt",
	"sprites/sniper_sl8ex.spr"
}

enum
{
	ANIM_IDLE = 0,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_RELOAD,
	ANIM_DRAW
}

new g_sl8heat
new g_had_sl8heat[33], g_attacking[33], g_sl8heat_clip[33], g_sl8heat_reload[33], 
g_sl8heat_zoom[33], Float:g_recheck_aim[33],
g_maxplayers, sl8heat_event, precache_forward, g_bloodspray, g_blood, g_ham_bot,
g_shell_index, g_sync_hud1, 
cvar_default_bpammo, cvar_default_clip, cvar_body_damage, cvar_reload_time, 
cvar_heat_light, cvar_default_light, cvar_heat_color_r, cvar_heat_color_g, 
cvar_heat_color_b, cvar_heat_alpha

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Events
	register_event("CurWeapon", "event_curweapon", "be", "1=1")
	
	// Fakemeta Forwards
	unregister_forward(FM_PrecacheEvent, precache_forward, 1)
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_AddToFullPack, "fw_AddToFullPack", 1)
	
	// Ham Forwards
	RegisterHam(Ham_Spawn, "player", "fw_Ham_Spawn_Post", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon_sl8heat, "fw_Ham_AddToPlayer", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_sl8heat, "fw_Ham_PriAttack_Post", 1)	
	RegisterHam(Ham_Weapon_Reload, weapon_sl8heat, "fw_Ham_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_sl8heat, "fw_Ham_Reload_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_sl8heat, "fw_Ham_PostFrame")
	RegisterHam(Ham_TakeDamage, "player", "fw_Ham_TakeDamage")
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_Ham_TraceAttack_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_Ham_TraceAttack_Post", 1)	
	
	// Cvars
	cvar_default_bpammo = register_cvar("zp_default_bpammo", "200")
	cvar_default_clip = register_cvar("zp_default_clip", "25")
	cvar_body_damage = register_cvar("zp_body_damage", "75")
	cvar_reload_time = register_cvar("zp_reload_time", "3.53")
	
	cvar_heat_light = register_cvar("zp_heat_light", "a")
	
	static string[3]
	get_cvar_string("zp_lighting", string, sizeof(string))
	cvar_default_light = register_cvar("zp_default_light", string)
	
	cvar_heat_color_r = register_cvar("zp_heat_color_r", "100")
	cvar_heat_color_g = register_cvar("zp_heat_color_g", "100")
	cvar_heat_color_b = register_cvar("zp_heat_color_b", "100")
	cvar_heat_alpha = register_cvar("zp_heat_alpha", "75")
	
	// Cache
	g_maxplayers = get_maxplayers()
	g_sync_hud1 = CreateHudSyncObj(8)
	g_sl8heat = zp_register_extra_item("SL8 - Heat", 3000, ZP_TEAM_HUMAN)

	set_task(2.0, "reset_light_level", _, _, _, "b")
}

public plugin_precache()
{
	new i
	for(i = 0; i < sizeof(sl8heat_model); i++)
	{
		if(i != 3)
			engfunc(EngFunc_PrecacheModel, sl8heat_model[i])
		else
			g_shell_index = engfunc(EngFunc_PrecacheModel, sl8heat_model[i])
	}
	for(i = 0; i < sizeof(sl8heat_sound); i++)
		engfunc(EngFunc_PrecacheSound, sl8heat_sound[i])	
	for(i = 0; i < sizeof(sl8heat_resource); i++)
		engfunc(EngFunc_PrecacheGeneric, sl8heat_resource[i])
		
	precache_forward = register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	
	g_blood = precache_model("sprites/blood.spr")
	g_bloodspray = precache_model("sprites/bloodspray.spr")		
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal("events/g3sg1.sc", name))
		sl8heat_event = get_orig_retval()
}

public reset_light_level()
{
	static string[3]
	get_cvar_string("zp_lighting", string, sizeof(string))
	
	set_pcvar_string(cvar_default_light, string)
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_sl8heat)
	{
		g_had_sl8heat[id] = 1
		g_attacking[id] = 0
		g_sl8heat_zoom[id] = 0
		
		fm_give_item(id, weapon_sl8heat)
		
		new sl8heat = fm_get_user_weapon_entity(id, CSW_SL8HEAT)
		
		cs_set_weapon_ammo(sl8heat, get_pcvar_num(cvar_default_clip))
		cs_set_user_bpammo(id, CSW_SL8HEAT, get_pcvar_num(cvar_default_bpammo))
		
		client_printc(id, "!g[ZP]!n You bought !gSL8 - Heat!n. Press !t(Right Mouse)!n view heat map !!!")
	}
}

public zp_user_infected_post(id)
{
	static string[2]
	get_pcvar_string(cvar_default_light, string, sizeof(string))		
	
	set_player_light(id, string)
	set_player_screenfade(id)
}

// =========================== MAIN PUBLIC ==================================
public client_connect(id)
{
	if(!g_ham_bot && is_user_bot(id))
	{
		g_ham_bot = 1
		set_task(1.0, "ham_register_bot")
	}
}

public ham_register_bot(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Ham_Spawn_Post", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_Ham_TakeDamage")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_Ham_TraceAttack_Post", 1)		
}

public event_curweapon(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return PLUGIN_HANDLED
	if(get_user_weapon(id) != CSW_SL8HEAT)
		return PLUGIN_HANDLED
	if(!g_had_sl8heat[id])
		return PLUGIN_HANDLED
		
	set_pev(id, pev_viewmodel2, sl8heat_model[0])
	set_pev(id, pev_weaponmodel2, sl8heat_model[1])
	
	return PLUGIN_HANDLED
}

public custom_shell(ent, id)
{
	//new sl8heat = fm_get_user_weapon_entity(id, CSW_SL8HEAT)
	
	//new Float:Origin[3], Float:Angles[3]
	//engfunc(EngFunc_GetAttachment, sl8heat, 0, Origin, Angles)
	
	/*
	message_begin(MSG_BROADCAST, get_user_msgid("Brass"))
	write_byte(TE_MODEL)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	engfunc(EngFunc_WriteCoord, Angles[0])
	engfunc(EngFunc_WriteCoord, Angles[1])
	engfunc(EngFunc_WriteCoord, Angles[2])
	engfunc(EngFunc_WriteAngle, 45) 
	write_short(g_shell_index) 
	write_byte(1) 
	write_byte(30)
	message_end()*/
}

// ========================== FAKEMETA FORWARDS =============================
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_SL8HEAT)
		return FMRES_IGNORED
	if(!g_had_sl8heat[id])
		return FMRES_IGNORED
	
	set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(!g_attacking[invoker])
		return FMRES_IGNORED
	if(eventid != sl8heat_event)
		return FMRES_IGNORED
		
	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	return FMRES_SUPERCEDE
}

public fw_SetModel(ent, model[])
{
	if(!is_valid_ent(ent))
		return FMRES_IGNORED
	
	static classname[33]
	pev(ent, pev_classname, classname, sizeof(classname))
	
	if(!equal(classname, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(equal(model, "models/w_g3sg1.mdl"))
	{
		static weapon
		weapon = find_ent_by_owner(-1, weapon_sl8heat, ent)	
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_sl8heat[id])
		{
			g_had_sl8heat[id] = 0
			
			engfunc(EngFunc_SetModel, ent, sl8heat_model[2])
			set_pev(weapon, pev_check, SECRET_KEY)

			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_SL8HEAT)
	{
		static string[2]
		get_pcvar_string(cvar_default_light, string, sizeof(string))		
	
		set_player_light(id, string)
		//set_player_screenfade(id)
		
		return FMRES_IGNORED
	}
	if(!g_had_sl8heat[id])
		return FMRES_IGNORED
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(CurButton & IN_ATTACK2)
	{
		CurButton &= ~IN_ATTACK2
		set_uc(uc_handle, UC_Buttons, CurButton)
		
		static weapon
		weapon = find_ent_by_owner(-1, weapon_sl8heat, id)	
		
		if(!(pev(id, pev_oldbuttons) & IN_ATTACK2) && get_pdata_int(weapon, 54, 4) == 0
		&& pev(id, pev_weaponanim) != ANIM_DRAW)
		{
			if(!g_sl8heat_zoom[id])
			{
				g_sl8heat_zoom[id] = 1
				cs_set_user_zoom(id, CS_SET_FIRST_ZOOM, 1)
				
				emit_sound(id, CHAN_ITEM, "items/nvg_on.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			} else {
				g_sl8heat_zoom[id] = 0
				cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
				
				emit_sound(id, CHAN_ITEM, "items/nvg_off.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
		}	
	}
	
	static Float:CurTime
	CurTime = get_gametime()
	
	if(CurTime - 0.1 > g_recheck_aim[id])
	{
		set_hudmessage(0, 200, 0, -1.0, -1.0, 0, 0.1, 0.1)
		if(cs_get_user_zoom(id) == CS_SET_FIRST_ZOOM)
		{
			ShowSyncHudMsg(id, g_sync_hud1, "|^n-- + --^n|")
			g_sl8heat_zoom[id] = 1
			
			set_player_screenfade
			(
			.pPlayer = id,
			.sDuration = (1 << 12),
			.sHoldTime = 0,
			.sFlags = 0x0004,
			.r = get_pcvar_num(cvar_heat_color_r),
			.g = get_pcvar_num(cvar_heat_color_g),
			.b = get_pcvar_num(cvar_heat_color_b),
			.a = get_pcvar_num(cvar_heat_alpha)
			)
			
			static string[2]
			get_pcvar_string(cvar_heat_light, string, sizeof(string))
			
			set_player_light(id, string)
		} else {
			ShowSyncHudMsg(id, g_sync_hud1, "")
			g_sl8heat_zoom[id] = 0		
		
			static string[2]
			get_pcvar_string(cvar_default_light, string, sizeof(string))		
		
			set_player_light(id, string)
			set_player_screenfade(id)
		}
		
		g_recheck_aim[id] = CurTime
	}
	
	return FMRES_HANDLED
}

public fw_AddToFullPack(es, e, ent, host, host_flags, player, p_set)
{
	if(!(1 <= host <= 32))
		return FMRES_IGNORED
	if(!is_user_alive(host))
		return FMRES_IGNORED
	if(!(1 <= ent <= 32))
		return FMRES_IGNORED
	if(!is_user_alive(ent))
		return FMRES_IGNORED
	if(get_user_weapon(host) != CSW_SL8HEAT)
		return FMRES_IGNORED
	if(!g_had_sl8heat[host])
		return FMRES_IGNORED	
	if(!g_sl8heat_zoom[host])
		return FMRES_IGNORED
		
	static HeatColor[3]
	
	if(cs_get_user_team(ent) == CS_TEAM_T)
	{
		HeatColor[0] = 255
		HeatColor[1] = 0
		HeatColor[2] = 0
	} else if(cs_get_user_team(ent) == CS_TEAM_CT) {
		HeatColor[0] = 0
		HeatColor[1] = 255
		HeatColor[2] = 0		
	}
	
	set_es(es, ES_RenderFx, kRenderFxGlowShell)
	set_es(es, ES_RenderMode, kRenderNormal)
	set_es(es, ES_RenderAmt, 50)
	set_es(es, ES_RenderColor, HeatColor)
		
	return FMRES_HANDLED
}

// =========================== HAM FORWARDS ================================
public fw_Ham_Spawn_Post(id)
{
	if(is_user_connected(id))
	{
		static string[2]
		get_pcvar_string(cvar_default_light, string, sizeof(string))		
	
		set_player_light(id, string)
		set_player_screenfade(id)
	}
}

public fw_Ham_AddToPlayer(ent, id)
{
	if(pev(ent, pev_check) == SECRET_KEY)
	{
		g_had_sl8heat[id] = 1
		set_pev(ent, pev_check, 0)
	}			
	
	if(g_had_sl8heat[id])
	{
		message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id)
		write_string("weapon_sl8ex")
		write_byte(2)
		write_byte(90)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(3)
		write_byte(CSW_SL8HEAT)
		write_byte(0)
		message_end()	
	} else {
		message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id)
		write_string("weapon_g3sg1")
		write_byte(2)
		write_byte(90)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(3)
		write_byte(CSW_G3SG1)
		write_byte(0)
		message_end()			
	}
}

public fw_Ham_PriAttack_Post(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_sl8heat[id])
		return HAM_IGNORED
	
	static clip
	clip = cs_get_weapon_ammo(ent)
	
	if(clip > 0)
	{
		set_weapon_anim(id, random_num(ANIM_SHOOT1, ANIM_SHOOT2))
		emit_sound(id, CHAN_WEAPON, sl8heat_sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
		custom_shell(ent, id)
	}
	
	return HAM_HANDLED
}

public fw_Ham_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_alive(attacker) || !is_user_connected(attacker))
		return HAM_IGNORED
	if(get_user_weapon(attacker) != CSW_SL8HEAT)
		return HAM_IGNORED
	if(!g_had_sl8heat[attacker])
		return HAM_IGNORED
	
	new Float:WeaponDamage = get_pcvar_float(cvar_body_damage)
	
	if(is_user_connected(victim))
	{
		new Body, Target, Float:NewDamage
		get_user_aiming(attacker, Target, Body, 999999)
		
		NewDamage = float(get_damage_body(Body, WeaponDamage))

		SetHamParamFloat(4, NewDamage)
	} else {
		SetHamParamFloat(4, WeaponDamage)
	}
	
	return HAM_HANDLED
}

public fw_Ham_TraceAttack_Post(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker) || !is_user_connected(attacker))
		return HAM_IGNORED
	if(get_user_weapon(attacker) != CSW_SL8HEAT)
		return HAM_IGNORED
	if(!g_had_sl8heat[attacker])
		return HAM_IGNORED
	
	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
	make_bullet(attacker, flEnd)
	
	return HAM_HANDLED
}

public fw_Ham_Reload(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_sl8heat[id])
		return HAM_IGNORED
		
	g_sl8heat_clip[id] = -1
	
	new bpammo = cs_get_user_bpammo(id, CSW_SL8HEAT)
	if (bpammo <= 0)
		return HAM_SUPERCEDE
	
	new iClip = get_pdata_int(ent, 51, 4)
	if(iClip >= get_pcvar_num(cvar_default_clip))
		return HAM_SUPERCEDE		
	
	g_sl8heat_clip[id] = iClip
	g_sl8heat_reload[id] = 1

	return HAM_IGNORED
}

public fw_Ham_Reload_Post(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_sl8heat[id])
		return HAM_IGNORED
		
	if (g_sl8heat_clip[id] == -1)
		return HAM_IGNORED
	
	new Float:reload_time = get_pcvar_float(cvar_reload_time)
	
	set_pdata_int(ent, 51, g_sl8heat_clip[id], 4)
	set_pdata_float(ent, 48, reload_time, 4)
	set_pdata_float(id, 83, reload_time, 5)
	set_pdata_int(ent, 54, 1, 4)
	
	set_weapon_anim(id, ANIM_RELOAD)
	
	return HAM_IGNORED
}

public fw_Ham_PostFrame(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	new id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_sl8heat[id])
		return HAM_IGNORED
		
	new Float:flNextAttack = get_pdata_float(id, 83, 5)
	new bpammo = cs_get_user_bpammo(id, CSW_SL8HEAT)
	
	new iClip = get_pdata_int(ent, 51, 4)
	new fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		new temp = min(get_pcvar_num(cvar_default_clip) - iClip, bpammo)
		
		set_pdata_int(ent, 51, iClip + temp, 4)
		cs_set_user_bpammo(id, CSW_SL8HEAT, bpammo - temp)		
		set_pdata_int(ent, 54, 0, 4)
		
		fInReload = 0
		g_sl8heat_reload[id] = 0
	}		
	
	return HAM_IGNORED
}

// =========================== STOCKS ================================
stock client_printc(index, const text[], any:...)
{
	new szMsg[128];
	vformat(szMsg, sizeof(szMsg) - 1, text, 3);

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04");
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01");
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03");

	if(index == 0)
	{
		for(new i = 0; i < g_maxplayers; i++)
		{
			if(is_user_alive(i) && is_user_connected(i))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, i);
				write_byte(i);
				write_string(szMsg);
				message_end();	
			}
		}		
	} else {
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
} 

stock set_weapon_anim(id, anim)
{ 
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock make_bullet(id, Float:Origin[3])
{
	// Find target
	new target, body
	get_user_aiming(id, target, body, 999999)
	
	if(target > 0 && target <= get_maxplayers())
	{
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3]
		pev(id, pev_origin, fStart)
		
		// Get ids view direction
		velocity_by_aim(id, 64, fVel)
		
		// Calculate position where blood should be displayed
		fStart[0] = Origin[0]
		fStart[1] = Origin[1]
		fStart[2] = Origin[2]
		fEnd[0] = fStart[0]+fVel[0]
		fEnd[1] = fStart[1]+fVel[1]
		fEnd[2] = fStart[2]+fVel[2]
		
		// Draw traceline from victims origin into ids view direction to find
		// the location on the wall to put some blood on there
		new res
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res)
		get_tr2(res, TR_vecEndPos, fRes)
		
		// Show some blood :)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(TE_BLOODSPRITE)
		write_coord(floatround(fStart[0])) 
		write_coord(floatround(fStart[1])) 
		write_coord(floatround(fStart[2])) 
		write_short(g_bloodspray)
		write_short(g_blood)
		write_byte(70)
		write_byte(random_num(1,2))
		message_end()
		
		
		} else {
		new decal = 41
		
		// Check if the wall hit is an entity
		if(target)
		{
			// Put decal on an entity
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_DECAL)
			write_coord(floatround(Origin[0]))
			write_coord(floatround(Origin[1]))
			write_coord(floatround(Origin[2]))
			write_byte(decal)
			write_short(target)
			message_end()
			} else {
			// Put decal on "world" (a wall)
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_WORLDDECAL)
			write_coord(floatround(Origin[0]))
			write_coord(floatround(Origin[1]))
			write_coord(floatround(Origin[2]))
			write_byte(decal)
			message_end()
		}
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		write_coord(floatround(Origin[0]))
		write_coord(floatround(Origin[1]))
		write_coord(floatround(Origin[2]))
		write_short(id)
		write_byte(decal)
		message_end()
	}
}

stock get_damage_body(body, Float:damage)
{
	switch (body)
	{
		case HIT_HEAD: damage *= 4.0
		case HIT_STOMACH: damage *= 1.25
		case HIT_LEFTLEG: damage *= 0.75
		case HIT_RIGHTLEG: damage *= 0.75
		default: damage *= 1.0
	}
	
	return floatround(damage);
}

stock set_player_light(id, const LightStyle[])
{
	message_begin( MSG_ONE, SVC_LIGHTSTYLE, .player = id)
	write_byte(0)
	write_string(LightStyle)
	message_end()
}

stock set_player_screenfade( pPlayer, sDuration = 0, sHoldTime = 0, sFlags = 0, r = 0, g = 0, b = 0, a = 0 )
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, pPlayer)
	write_short(sDuration)
	write_short(sHoldTime)
	write_short(sFlags)
	write_byte(r)
	write_byte(g)
	write_byte(b)
	write_byte(a)
	message_end()
}
