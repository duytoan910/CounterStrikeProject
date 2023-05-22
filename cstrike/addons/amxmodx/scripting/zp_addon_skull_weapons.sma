#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich> // You must update this one
#include <zombieplague>
#include <toan>

#define PLUGIN "Skull Series"
#define VERSION "2.0"
#define AUTHOR "Asdian"

#define weapon_skull3_m1 "weapon_mp5navy"
#define CSW_SKULL3_M1 CSW_MP5NAVY
#define CSW_SKULL3_M2 CSW_P90

#define CSW_SKULL4 CSW_AK47
#define weapon_skull4 "weapon_ak47"

#define CSW_SKULL5 CSW_G3SG1
#define weapon_skull5 "weapon_g3sg1"

#define weapon_sk_mg "weapon_m249"
#define CSW_SK_MG CSW_M249

#define CSW_SKULLAXE CSW_KNIFE
#define weapon_skullaxe	"weapon_knife"

#define CSW_SKULL11 CSW_XM1014
#define weapon_skull11 "weapon_xm1014"

#define SKULL3_SPR_1	"weapon_skull3"
#define SKULL3_SPR_2	"weapon_skull3d"
#define SKULL4_SPR	"weapon_skull4"
#define SKULL5_SPR	"weapon_skull5"
#define SKULL7_SPR	"weapon_m249ex"
#define SKULL8_SPR	"weapon_skull8"
#define SKULL9_SPR	"knife_skullaxe"
#define SKULL11_SPR	"weapon_skull11"

#define SKULL3_M1_KEY	999+002
#define SKULL3_M2_KEY	999+003
#define SKULL3_KEY	999+004
#define SKULL4_KEY	999+005
#define SKULL5_KEY	999+006
#define SKULL7_KEY	999+008
#define SKULL8_KEY	999+009
#define SKULL11_KEY	999+010

#define ANIM_EXTENSION	"dualpistols"
#define ANIM_EXTENSION2	"skullaxe"

#define RECOIL_M1 0.46
#define CLIP_M1 35
#define SPEED_M1 1.35
#define DAMAGE_M1 1.5

#define SKULL4_DMG 1.5
#define SKULL4_CLIP 48
#define SKULL4_BPAMMO 200

#define SKULL5_DEFAULT_BPAMMO 180
#define SKULL5_DEFAULT_CLIP 24
#define SKULL5_DAMAGE 1.5
#define SKULL5_RELOAD_TIME 2.0
#define SKULL5_SPEED 0.1
#define SKULL5_RECOIL 0.7

#define DMG_SKULL7 1.5
#define RECOIL_SKULL7 1.07
#define CLIP_SKULL7 120
#define SPD_SKULL7 0.1
#define SKULL7_AMMO 240
#define RELOAD_TIME_SK6_7 3.9

#define DMG_SKULL8 1.5
#define RECOIL_SKULL8 1.03
#define RELOAD_TIME_SK8	4.8
#define CLIP_SKULL8 120
#define SPD_SKULL8 1.2
#define SKULL8_AMMO 240
#define SKULL8_SLASH_RAD 150.0
#define SKULL8_SLASH_DMG random_float(286.0,380.0)

#define SLASH_DAMAGE random_float(300.0,400.0)
#define STAB_DAMAGE random_float(400.0,500.0)

#define SPEED_MODE_BUCKSHOT 1.3
#define SPEED_MODE_SLUG 2.0
#define BPAMMO 40
#define CLIP2 28
#define DAMAGE 3.5
#define RECOIL_SK11 0.5
#define RELOAD_TIME 4.0

enum _:SKULL3_ANIM_A_MODE
{
	ANIM_IDLE_A = 0,
	ANIM_RELOAD_A,
	ANIM_DRAW_A,
	ANIM_SHOOT1_A,
	ANIM_SHOOT2_A,
	ANIM_SHOOT3_A,
	ANIM_CHANGE_TO_A
}

enum _:SKULL3_ANIM_B_MODE
{
	ANIM_IDLE_B = 0,
	ANIM_RELOAD_B,
	ANIM_DRAW_B,
	ANIM_SHOOT_LEFT,
	ANIM_SHOOT_LEFT2,
	ANIM_SHOOT_RIGHT,
	ANIM_SHOOT_RIGHT2,
	ANIM_SHOOT_LEFTLAST,
	ANIM_IDLE_LEFTEMPTY,
	ANIM_SHOOT_RIGHTLAST,
	ANIM_CHANGE_TO_B
}

enum _:SKULL4_ANIM
{
	ANIM_IDLE = 0,
	ANIM_IDLE_EMPTY,
	ANIM_SHOOT_LEFT1,
	ANIM_SHOOT_LEFT2,
	ANIM_SHOOT_LEFTLAST,
	ANIM_SHOOT_RIGHT1,
	ANIM_SHOOT_RIGHT2,
	ANIM_SHOOT_RIGHTLAST,
	ANIM_RELOAD,
	ANIM_DRAW
}

new const WEAPONENTNAMES[][] = 
{ 
	"", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
	"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
	"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_m249",
	"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
	"weapon_ak47", "weapon_knife"
}

// Global vars
new g_is_attacking[33], g_old_weapon[33], g_blood[2], clip_shell, g_zoomed[33],  Float:g_zoom_time[33]

new g_had_skull3[33], g_skull3_mode[33], g_skull3_ammo[33], g_skull3_changing[33], Float:g_oldspeed[33], g_lastinv[33], Float:g_recoil[33], g_Clip[33], g_remove_ent[33], g_shot_anim[33], g_skull3_clip[33]
new g_pbe_skull3_m1, g_HamBot

new g_had_skull4[33], g_shot_anim2[33], g_orig_event_skull4, is_reloading[33]

new g_scope[33], g_event_sk_mg, g_event_skull5
new g_had_skull7[33], g_MG_Clip[33], Float:cl_pushangle[33][3]
new g_had_skull8[33], g_had_skull5[33], g_skull11_mode[33]


new g_had_skullaxe[33], g_Clip_Sk5[33], g_Clip_Sk4[33], g_skull5_clip[33], g_sk11_Clip[33]

new g_had_skull11[33], g_skull11_event,  Float:g_punchangles[33][3], Clip[33]


new const V_MODEL_SKULL3[] = "models/v_skull3.mdl"
new const P_MODEL_SKULL3[] = "models/p_skull3.mdl"
new const W_MODEL_SKULL3[] = "models/w_skull3.mdl"

new const V_MODEL_SKULL4[] = "models/v_skull4.mdl"
new const P_MODEL_SKULL4[] = "models/p_skull4.mdl"
new const W_MODEL_SKULL4[] = "models/w_skull4.mdl"

new const V_MODEL_SKULL5[] = "models/v_skull5.mdl"
new const P_MODEL_SKULL5[] = "models/p_skull5.mdl"
new const W_MODEL_SKULL5[] = "models/w_skull5.mdl"

new const V_MODEL_SKULL7[] = "models/v_skull7.mdl"
new const P_MODEL_SKULL7[] = "models/p_skull7.mdl"
new const W_MODEL_SKULL7[] = "models/w_skull7.mdl"

new const V_MODEL_SKULL8[] = "models/v_skull8.mdl"
new const P_MODEL_SKULL8[] = "models/p_skull8.mdl"
new const W_MODEL_SKULL8[] = "models/w_skull8.mdl"

new const P_MODEL_SKULL9[] = "models/p_skullaxe.mdl"
new const V_MODEL_SKULL9[] = "models/v_skullaxe.mdl"

new const V_MODEL_SKULL11[] = "models/v_skull11.mdl"
new const P_MODEL_SKULL11[] = "models/p_skull11.mdl"
new const W_MODEL_SKULL11[] = "models/w_skull11.mdl"

const m_szAnimExtention = 492

new const S_SOUND[][] =
{
	"weapons/skull1-1.wav",
	"weapons/skull3-1.wav",
	"weapons/skull4_shoot1.wav",
	"weapons/skull5-1.wav",
	"weapons/skull6-1.wav",
	"weapons/m249ex.wav",
	"weapons/skull8-1.wav",
	"weapons/skull8-2.wav",
	"weapons/skull8_shoot3.wav",
	"weapons/skull8_shoot4.wav",
	"weapons/skull11_1.wav"
}

new const Skullaxe_Sounds[][] = 
{
	"weapons/skullaxe_draw.wav",
	"weapons/skullaxe_hit.wav",
	"weapons/skullaxe_miss.wav",
	"weapons/skullaxe_slash1.wav",
	"weapons/skullaxe_slash2.wav",
	"weapons/skullaxe_wall.wav"
}

enum _:HitType
{
	HIT_NOTHING = 0,
	HIT_ENEMY,
	HIT_WALL
}

enum _:NewAnim_SKULL9
{
	SKULL9_ANIM_IDLE = 0,
	SKULL9_ANIM_SLASH_HIT,
	SKULL9_ANIM_STAB,
	SKULL9_ANIM_DRAW,
	SKULL9_ANIM_STAB2,
	SKULL9_ANIM_SLASH_MISS,
	SKULL9_ANIM_MIDSLASH1,
	SKULL9_ANIM_MIDSLASH2,
	SKULL9_ANIM_SLASH_START
}

enum _:Mode
{
	MODE_BUCKSHOT = 0,
	MODE_SLUG
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "Event_Death")
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_SetModel, "fw_SetModel")	
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "ham_traceattack")
	RegisterHam(Ham_TraceAttack, "player", "ham_traceattack")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_skull3_m1, "ham_add_skull3_m1", 1)
	RegisterHam(Ham_Item_Deploy, weapon_skull3_m1, "ham_deploy_skull3", 1)
	
	for(new i = 1; i <= 28; i++)
	{
		if(strlen(WEAPONENTNAMES[i]) && !equal(WEAPONENTNAMES[i], "weapon_knife"))
			RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Ham_Item_Deploy_Post", 1)
	}
	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_skull3_m1, "ham_attack_skull3")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_skull3_m1, "ham_attack_skull3_post", 1)	
	RegisterHam(Ham_Weapon_Reload, weapon_skull3_m1, "ham_reload_skull3")
	RegisterHam(Ham_Weapon_Reload, weapon_skull3_m1, "ham_reload_skull3_post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_skull3_m1, "ham_postframe_skull3")
	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_skull4, "fw_PrimaryAttack_sk4")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_skull4, "fw_PrimaryAttack_Post_sk4", 1)
	RegisterHam(Ham_Weapon_Reload, weapon_skull4, "fw_Reload_sk4")
	RegisterHam(Ham_Weapon_Reload, weapon_skull4, "fw_Reload_Post_sk4", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon_skull4, "fw_AddToPlayer_sk4", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_skull4, "fw_ItemPostFrame_sk4")
	RegisterHam(Ham_Item_Deploy, weapon_skull4, "fw_Item_Deploy_Post_sk4", 1)
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_skull5, "fw_SKULL5_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_skull5, "fw_SKULL5_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_skull5, "fw_SKULL5_Reload")	
	RegisterHam(Ham_Weapon_Reload, weapon_skull5, "fw_SKULL5_Reload_Post", 1)	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_skull5, "fw_SKULL5_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_skull5, "fw_SKULL5_PrimaryAttack_Post", 1)
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_sk_mg, "fw_AddToPlayer_Mg", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_sk_mg, "fw_ItemPostFrame_Mg")
	RegisterHam(Ham_Weapon_Reload, weapon_sk_mg, "fw_Weapon_Reload_Mg")
	RegisterHam(Ham_Weapon_Reload, weapon_sk_mg, "fw_Weapon_Reload_Mg_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_sk_mg, "fw_PrimaryAttack_Mg")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_sk_mg, "fw_PrimaryAttack_Mg_Post", 1)
	RegisterHam(Ham_Item_Deploy, weapon_sk_mg, "fw_Item_Deploy_Post_Mg", 1)
	
	RegisterHam(Ham_Item_Deploy, weapon_skullaxe, "fw_Item_Deploy_Post_SKULL9", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_skullaxe, "fw_ItemPostFrame_SKULL9")
	
	RegisterHam(Ham_Item_Deploy, weapon_skull11, "fw_Item_Deploy_Post_sk11", 1)
	RegisterHam(Ham_Weapon_Reload, weapon_skull11, "fw_Reload_sk11")
	RegisterHam(Ham_Weapon_Reload, weapon_skull11, "fw_Reload_Post_sk11", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_skull11, "fw_ItemPostFrame_sk11")
	RegisterHam(Ham_Item_AddToPlayer, weapon_skull11, "fw_Item_AddToPlayer_sk11", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_skull11, "fw_PrimaryAttack_sk11")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_skull11, "fw_PrimaryAttack_Post_sk11", 1)
	
	register_clcmd("drop", "cmd_drop")
	
	register_clcmd(SKULL3_SPR_1, "hook_change_weapon1")
	register_clcmd(SKULL4_SPR, "hook_sk4")
	register_clcmd(SKULL5_SPR, "hook_sk5")
	register_clcmd(SKULL7_SPR, "hook_mg")
	register_clcmd(SKULL8_SPR, "hook_mg")
	register_clcmd(SKULL9_SPR, "hook_sk9")
	register_clcmd(SKULL11_SPR, "hook_sk11")
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL_SKULL3)
	engfunc(EngFunc_PrecacheModel, P_MODEL_SKULL3)
	engfunc(EngFunc_PrecacheModel, W_MODEL_SKULL3)
	
	engfunc(EngFunc_PrecacheModel, V_MODEL_SKULL4)
	engfunc(EngFunc_PrecacheModel, P_MODEL_SKULL4)
	engfunc(EngFunc_PrecacheModel, W_MODEL_SKULL4)
	
	engfunc(EngFunc_PrecacheModel, V_MODEL_SKULL5)
	engfunc(EngFunc_PrecacheModel, P_MODEL_SKULL5)
	engfunc(EngFunc_PrecacheModel, W_MODEL_SKULL5)
	
	engfunc(EngFunc_PrecacheModel, V_MODEL_SKULL7)
	engfunc(EngFunc_PrecacheModel, P_MODEL_SKULL7)
	engfunc(EngFunc_PrecacheModel, W_MODEL_SKULL7)
	
	engfunc(EngFunc_PrecacheModel, V_MODEL_SKULL8)
	engfunc(EngFunc_PrecacheModel, P_MODEL_SKULL8)
	engfunc(EngFunc_PrecacheModel, W_MODEL_SKULL8)
	
	engfunc(EngFunc_PrecacheModel, V_MODEL_SKULL9)
	engfunc(EngFunc_PrecacheModel, P_MODEL_SKULL9)
	
	engfunc(EngFunc_PrecacheModel, V_MODEL_SKULL11)
	engfunc(EngFunc_PrecacheModel, P_MODEL_SKULL11)
	engfunc(EngFunc_PrecacheModel, W_MODEL_SKULL11)
	
	new i
	for(i = 0; i < sizeof(S_SOUND); i++) engfunc(EngFunc_PrecacheSound, S_SOUND[i])
	for(i = 0; i < sizeof(Skullaxe_Sounds); i++) engfunc(EngFunc_PrecacheSound, Skullaxe_Sounds[i])
	
	g_blood[0] = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr")
	g_blood[1] = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr")			
	clip_shell = engfunc(EngFunc_PrecacheModel, "models/rshell.mdl")
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}
public plugin_natives ()
{
	// register_native("skull3", "give_skull3", 1)
	// register_native("skull4", "give_skull4", 1)
	// register_native("skull5", "give_skull5", 1)
	// register_native("skull7", "give_skull7", 1)
	// register_native("skull8", "give_skull8", 1)
	// register_native("skull9", "give_skull9", 1)
	// register_native("skull11", "give_skull11", 1)

	register_native("skull3", "give_skull7", 1)
	register_native("skull4", "give_skull4", 1)
	register_native("skull5", "give_skull5", 1)
	register_native("skull7", "give_skull7", 1)
	register_native("skull8", "give_skull8", 1)
	register_native("skull9", "give_skull9", 1)
	register_native("skull11", "give_skull11", 1)
}

public client_putinserver(id)
{
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Register_HamBot", id)
	}
}
 
public Register_HamBot(id)
{
	//RegisterHamFromEntity(Ham_TraceAttack, id, "ham_traceattack")	
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
}

public zp_user_humanized_post(id)
{
	remove_skull(id, 0)
	remove_skull(id, 1)
	remove_skull(id, 2)
	remove_skull(id, 3)
	remove_skull(id, 4)
	remove_skull(id, 5)
	remove_skull(id, 6)
	remove_skull(id, 7)
	remove_skull(id, 8)
}
public zp_user_infected_pre(id)
{
	drop_weapons(id, 1)
}
public zp_user_infected_post(id)
{
	remove_skull(id, 0)
	remove_skull(id, 1)
	remove_skull(id, 2)
	remove_skull(id, 3)
	remove_skull(id, 4)
	remove_skull(id, 5)
	remove_skull(id, 6)
	remove_skull(id, 7)
	remove_skull(id, 8)
}
		
public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal("events/mp5n.sc", name)) g_pbe_skull3_m1 = get_orig_retval()
	else if(equal("events/ak47.sc", name)) g_orig_event_skull4 = get_orig_retval()
	else if(equal("events/g3sg1.sc", name)) g_event_skull5 = get_orig_retval()
	else if(equal("events/m249.sc", name)) g_event_sk_mg = get_orig_retval()
	else if(equal("events/xm1014.sc", name)) g_skull11_event = get_orig_retval()
	
	return FMRES_IGNORED
}

public hook_change_weapon1(id) engclient_cmd(id, weapon_skull3_m1)
public hook_sk4(id) engclient_cmd(id, weapon_skull4)
public hook_sk5(id) engclient_cmd(id, weapon_skull5)
public hook_mg(id) engclient_cmd(id, weapon_sk_mg)
public hook_sk9(id) engclient_cmd(id, weapon_skullaxe)
public hook_sk11(id) engclient_cmd(id, weapon_skull11)

public give_skull3(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id))
		return
	
	drop_weapons(id, 1)
	
	g_had_skull3[id] = 1
	g_skull3_mode[id] = 1
	g_skull3_ammo[id] = 200
	g_lastinv[id] = 0
	
	fm_give_item(id, weapon_skull3_m1)
	
	static ent
	
	ent = fm_find_ent_by_owner(-1, weapon_skull3_m1, id)
	set_pev(ent, pev_iuser4, SKULL3_M1_KEY)
	cs_set_weapon_ammo(ent, CLIP_M1)
	cs_set_user_bpammo(id, CSW_SKULL3_M1, g_skull3_ammo[id])
	
	engclient_cmd(id, weapon_skull3_m1)
}

public give_skull4(id)
{
	g_had_skull4[id] = 1
	is_reloading[id] = 0
	g_zoomed[id] = 0
	g_shot_anim[id] = 0
	
	drop_weapons(id, 1)
	fm_give_item(id, weapon_skull4)
	
	static ent
	ent = fm_get_user_weapon_entity(id, CSW_SKULL4)
	
	if(!pev_valid(ent))
		return
	
	cs_set_weapon_ammo(ent, SKULL4_CLIP)
	cs_set_user_bpammo(id, CSW_SKULL4, SKULL4_BPAMMO)
	
	set_weapon_anim(id, ANIM_DRAW)
	set_nextattack(ent, id, 1.23)
	Update_Ammo(id, CSW_SKULL4, SKULL4_CLIP)
}

public give_skull5(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id))
		return
		
	g_had_skull5[id] = 1
	
	drop_weapons(id, 1)
	fm_give_item(id, weapon_skull5)
	cs_set_user_bpammo(id, CSW_SKULL5, SKULL5_DEFAULT_BPAMMO)
	
	static ent
	ent = fm_get_user_weapon_entity(id, CSW_SKULL5)
	
	if(pev_valid(ent)) cs_set_weapon_ammo(ent, SKULL5_DEFAULT_CLIP)
	
	Update_Ammo(id, CSW_SKULL5, SKULL5_DEFAULT_CLIP)
}

public give_skull7(id)
{
	g_had_skull7[id] = 1
	g_zoomed[id] = 0
	
	drop_weapons(id, 1)
	fm_give_item(id,weapon_sk_mg)
	
	new ent = fm_get_user_weapon_entity(id, CSW_SK_MG)
	
	if(!pev_valid(ent))
		return
	
	cs_set_weapon_ammo(ent, CLIP_SKULL7)
	cs_set_user_bpammo(id, CSW_SK_MG, 200)	
	set_weapon_anim(id, 4)
	set_pdata_float(id, 83, 1.0, 5)
	
	Update_Ammo(id, CSW_SK_MG, CLIP_SKULL7)
}

public give_skull8(id)
{
	g_had_skull8[id] = 1
	
	drop_weapons(id, 1)
	fm_give_item(id, weapon_sk_mg)
	
	static sk8
	sk8 = fm_get_user_weapon_entity(id, CSW_SK_MG)
	
	if(!pev_valid(sk8))
		return
	
	cs_set_weapon_ammo(sk8, CLIP_SKULL8)
	cs_set_user_bpammo(id, CSW_SK_MG, 200)	
	set_weapon_anim(id, 4)
	set_pdata_float(id, 83, 1.0, 5)
	
	Update_Ammo(id, CSW_SK_MG, CLIP_SKULL8)
}

public give_skull9(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id))
		return
		
	g_had_skullaxe[id] = 1
	
	fm_give_item(id, weapon_skullaxe)
	
	if(get_user_weapon(id) == CSW_SKULLAXE)
	{
		set_pev(id, pev_viewmodel2, V_MODEL_SKULL9)
		set_pev(id, pev_weaponmodel2, P_MODEL_SKULL9)
		
		set_weapon_anim(id, SKULL9_ANIM_DRAW)
		set_pdata_float(id, 83, 1.4, 5)
		emit_sound(id, CHAN_WEAPON, Skullaxe_Sounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	} else engclient_cmd(id, weapon_skullaxe)
	
}

public give_skull11(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id))
		return
		
	g_had_skull11[id] = 1
	g_skull11_mode[id] = MODE_BUCKSHOT
	
	drop_weapons(id, 1)
	fm_give_item(id, weapon_skull11)
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_SKULL11)
	if(pev_valid(ent)) cs_set_weapon_ammo(ent, CLIP2)
	
	cs_set_user_bpammo(id, CSW_SKULL11, BPAMMO)
	
	Update_Ammo(id, CSW_SKULL11, CLIP2)
}

public remove_skull(id, num)
{
	if(!is_user_connected(id))
		return
	
	switch(num)
	{
		case 1:
		{
			g_had_skull3[id] = 0
			g_skull3_mode[id] = 0
			g_skull3_ammo[id] = 0
			g_skull3_changing[id] = 0
			g_zoomed[id] = 0
			g_lastinv[id] = 0
		}
		case 2:
		{
			g_had_skull4[id] = 0
			is_reloading[id] = 0
			g_zoomed[id] = 0
			g_shot_anim2[id] = 0
		}
		case 3: g_had_skull5[id] = 0
		case 5:
		{
			g_had_skull7[id] = 0
			g_zoomed[id] = 0
		}
		case 6: g_had_skull8[id] = 0 
		case 7: g_had_skullaxe[id] = 0
		case 8:
		{
			g_had_skull11[id] = 0
			g_skull11_mode[id] = MODE_BUCKSHOT
		}
	}
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !is_user_connected(id))
		return PLUGIN_HANDLED
	
	static CurWeapon
	CurWeapon = get_user_weapon(id)
	
	if(CurWeapon == CSW_SKULL3_M1 && g_had_skull3[id] && g_skull3_mode[id] == 1) {
		Create_Model(id, 1)
		
		check_weapon_speed(id, 1)
	} else if(CurWeapon == CSW_SKULL4 && g_had_skull4[id]) {
		set_pev(id, pev_viewmodel2, V_MODEL_SKULL4)
		set_pev(id, pev_weaponmodel2, P_MODEL_SKULL4)
		
		if(g_old_weapon[id] != CSW_SKULL4)
		{
			set_weapon_anim(id, ANIM_DRAW)
			set_pdata_float(id, 83, 1.23, 5)
		}
	} else if(CurWeapon == CSW_SKULL5 && g_had_skull5[id]) {
		set_pev(id, pev_viewmodel2, V_MODEL_SKULL5)
		set_pev(id, pev_weaponmodel2, P_MODEL_SKULL5)
		
		static ent; ent = fm_get_user_weapon_entity(id, CSW_SKULL5)
		if(pev_valid(ent))  set_pdata_float(ent, 46, get_pdata_float(ent, 46, 4) * SKULL5_SPEED, 4)
	} else if(CurWeapon == CSW_SK_MG) {
		if(g_had_skull7[id]) {
			set_pev(id, pev_viewmodel2, V_MODEL_SKULL7)
			set_pev(id, pev_weaponmodel2, P_MODEL_SKULL7)
		} else if(g_had_skull8[id]) {
			set_pev(id, pev_viewmodel2, V_MODEL_SKULL8)
			set_pev(id, pev_weaponmodel2, P_MODEL_SKULL8)
			
			// Speed
			static ent; ent = fm_get_user_weapon_entity(id, CSW_SK_MG)
			if(!pev_valid(ent)) 
				return PLUGIN_HANDLED
				
			static Float:iSpeed
			iSpeed = SPD_SKULL8
			
			set_pdata_float(ent, 46, get_pdata_float(ent, 46, 4) * iSpeed, 4)
		}
	} else if(CurWeapon == CSW_SKULLAXE) {
		set_pev(id, pev_viewmodel2, V_MODEL_SKULL9)
		set_pev(id, pev_weaponmodel2, P_MODEL_SKULL9)
	} else if(CurWeapon == CSW_SKULL11 && g_had_skull11[id]) {
		set_pev(id, pev_viewmodel2, V_MODEL_SKULL11)
		set_pev(id, pev_weaponmodel2, P_MODEL_SKULL11)
		
		if(g_old_weapon[id] != CSW_SKULL11)
		{
			set_weapon_anim(id, 4)
			set_pdata_float(id, 83, 1.0, 5)
		}
		
		static ent; ent = fm_get_user_weapon_entity(id, CSW_SKULL11)
		static Float:speed
		speed = (g_skull11_mode[id] == MODE_BUCKSHOT ? SPEED_MODE_BUCKSHOT : SPEED_MODE_SLUG)
		
		if(pev_valid(ent)) set_pdata_float(ent, 46, get_pdata_float(ent, 46, 4) * speed, 4)
	}
	g_old_weapon[id] = get_user_weapon(id)
	
	return PLUGIN_HANDLED
}

public check_weapon_speed(id, mode)
{
	static Float:Speed, weapon[32], ent
	Speed = SPEED_M1
	get_weaponname(mode == 1 ? CSW_SKULL3_M1 : CSW_SKULL3_M2, weapon, sizeof(weapon))
	ent = find_ent_by_owner(-1, weapon, id)
	
	if(ent)
	{
		static Float:Delay, Float:M_Delay
		Delay = get_pdata_float(ent, 46, 4) * Speed
		M_Delay = get_pdata_float(ent, 47, 4) * Speed
		
		if (Delay > 0.0)
		{
			set_pdata_float(ent, 46, Delay, 4)
			set_pdata_float(ent, 47, M_Delay, 4)
		}
	}	
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !is_user_connected(id))
		return FMRES_IGNORED
	
	if((get_user_weapon(id) == CSW_SKULL3_M1 || get_user_weapon(id) == CSW_SKULL3_M2) && g_had_skull3[id]) set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001)
	else if(get_user_weapon(id) == CSW_SKULL4 && g_had_skull4[id]) set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001)
	else if(get_user_weapon(id) == CSW_SKULL5 && g_had_skull5[id]) set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001)
	else if(get_user_weapon(id) == CSW_SK_MG || g_had_skull7[id] && g_had_skull8[id]) set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001)
	else if(get_user_weapon(id) == CSW_SKULL11 && g_had_skull11[id]) set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001)
	
	return FMRES_IGNORED
}

public cmd_drop(id)
{
	if(get_user_weapon(id) == CSW_SKULL3_M1 || get_user_weapon(id) == CSW_SKULL3_M2 && g_had_skull3[id]){}
	return PLUGIN_CONTINUE
}

public fw_SetModel(ent, model[])
{
	if(!is_valid_ent(ent))
		return FMRES_IGNORED
	
	static szClassName[33]
	pev(ent, pev_classname, szClassName, charsmax(szClassName))
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(equal(model, "models/w_mp5.mdl")) {
		static weapon
		weapon = find_ent_by_owner(-1, weapon_skull3_m1, ent)	
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_skull3[id])
		{
			g_remove_ent[id] = ent
			g_had_skull3[id] = 0
			
			engfunc(EngFunc_SetModel, ent, W_MODEL_SKULL3)
			set_pev(weapon, pev_impulse, SKULL3_KEY)
			
			return FMRES_SUPERCEDE
		}
	} else if(equal(model, "models/w_ak47.mdl")) {
		static item
		item = find_ent_by_owner(-1, weapon_skull4, ent)
	
		if(!pev_valid(item))
			return FMRES_IGNORED
	
		if(g_had_skull4[id])
		{
			set_pev(item, pev_impulse, SKULL4_KEY)
			engfunc(EngFunc_SetModel, ent, W_MODEL_SKULL4)
			
			g_had_skull4[id] = 0
			
			return FMRES_SUPERCEDE
		}
	} else if(equal(model, "models/w_g3sg1.mdl")) {
		static weapon
		weapon = fm_get_user_weapon_entity(ent, CSW_SKULL5)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_skull5[id])
		{
			g_had_skull5[id] = 0
			
			set_pev(weapon, pev_impulse, SKULL5_KEY)
			engfunc(EngFunc_SetModel, ent, W_MODEL_SKULL5)
			
			return FMRES_SUPERCEDE
		}
	} else if(equal(model, "models/w_m249.mdl")) {
		static weapon
		weapon = find_ent_by_owner(-1, weapon_sk_mg, ent)
	
		if(!pev_valid(weapon))
			return FMRES_IGNORED
	
		if(g_had_skull7[id]) {
			set_pev(weapon, pev_impulse, SKULL7_KEY)
			remove_skull(id, 5)
			engfunc(EngFunc_SetModel, ent, W_MODEL_SKULL7)
			
			return FMRES_SUPERCEDE
		} else if(g_had_skull8[id]) {
			set_pev(weapon, pev_impulse, SKULL8_KEY)
			remove_skull(id, 6)
			engfunc(EngFunc_SetModel, ent, W_MODEL_SKULL8)
			
			return FMRES_SUPERCEDE
		}
	} else if(equal(model, "models/w_xm1014.mdl")) {
		static weapon
		weapon = fm_find_ent_by_owner(-1, weapon_skull11, ent)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_skull11[id])
		{
			set_pev(weapon, pev_impulse, SKULL11_KEY)
			engfunc(EngFunc_SetModel, ent, W_MODEL_SKULL11)
			remove_skull(id, 8)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public remove_gun(id, CSW) 
{ 
	new weapons[32], num = 0
	get_user_weapons(id, weapons, num) 
	
	for(new i = 0; i < num; i++)
	{ 
		if(weapons[i] == CSW)
		{
			fm_strip_user_gun(id, weapons[i])
		}
	}
} 

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(CurButton & IN_ATTACK2)
	{
		if((g_had_skull3[id] && get_user_weapon(id) == CSW_SKULL3_M1 && g_skull3_mode[id] == 1)
		|| (g_had_skull4[id] && get_user_weapon(id) == CSW_SKULL4) || (g_had_skull7[id] && get_user_weapon(id) == CSW_SK_MG))
		{
			static Float:CurTime
			CurTime = get_gametime()
			
			if(CurTime - 0.5 > g_zoom_time[id])
			{
				if(!g_zoomed[id]) g_zoomed[id] = 1
				else g_zoomed[id] = 0
				
				cs_set_user_zoom(id, g_zoomed[id] == 1 ? CS_SET_AUGSG552_ZOOM : CS_RESET_ZOOM, 1)
				g_zoom_time[id] = CurTime
			}
		} if(g_had_skull11[id] && get_user_weapon(id) == CSW_SKULL11) {
			g_skull11_mode[id] = 1 - g_skull11_mode[id]
			client_print(id, print_center, "Switched to %s mode", g_skull11_mode[id] == MODE_BUCKSHOT ? "Shotgun" : "Special")
		}
	}
	
	return FMRES_IGNORED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if(!is_user_alive(invoker) || !is_user_connected(invoker) || !g_is_attacking[invoker])
		return FMRES_IGNORED
	if(!(1 <= invoker <= get_maxplayers()))
		return FMRES_IGNORED
	
	if(g_had_skull3[invoker] && eventid == g_pbe_skull3_m1) {
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
		return FMRES_SUPERCEDE
	} else if(g_had_skull4[invoker] && eventid == g_orig_event_skull4) {
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
		static szAnim[64], iAnim, Duck, ent
		Duck = (pev(invoker, pev_flags) & FL_DUCKING)
		ent = fm_get_user_weapon_entity(invoker, CSW_SKULL4)
		
		if(!pev_valid(ent))
			return FMRES_IGNORED
		
		if(!g_shot_anim2[invoker]) g_shot_anim2[invoker] = 1
		g_shot_anim2[invoker]++
		if(g_shot_anim2[invoker] > 2) g_shot_anim2[invoker] = 1
		
		if(g_shot_anim2[invoker] == 1)
		{
			set_weapon_anim(invoker, random_num(ANIM_SHOOT_RIGHT1, ANIM_SHOOT_RIGHT2))
			EjectBrass(invoker, clip_shell, -9.0, 15.0, -5.0, -50.0, -70.0)
			formatex(szAnim, charsmax(szAnim), Duck ? "crouch_shoot2_%s" : "ref_shoot2_%s", ANIM_EXTENSION)
		} else if(g_shot_anim2[invoker] == 2) {
			set_weapon_anim(invoker, random_num(ANIM_SHOOT_LEFT1, ANIM_SHOOT_LEFT2))
			EjectBrass(invoker, clip_shell, -9.0, 15.0, 5.0, 50.0, 70.0)
			formatex(szAnim, charsmax(szAnim), Duck ? "crouch_shoot_%s" : "ref_shoot_%s", ANIM_EXTENSION)
		}
		
		if(cs_get_weapon_ammo(ent) == 1)
		{
			set_weapon_anim(invoker, ANIM_SHOOT_LEFTLAST)
			formatex(szAnim, charsmax(szAnim), Duck ? "crouch_shoot_%s" : "ref_shoot_%s", ANIM_EXTENSION)
		} else if(cs_get_weapon_ammo(ent) == 0) {
			set_weapon_anim(invoker, ANIM_SHOOT_RIGHTLAST)
			formatex(szAnim, charsmax(szAnim), Duck ? "crouch_shoot2_%s" : "ref_shoot2_%s", ANIM_EXTENSION)
			set_nextattack(ent, invoker, 0.5)
		}
		
		if((iAnim = lookup_sequence(invoker, szAnim)) == -1) iAnim = 0
		
		set_pdata_float(ent, 62, 0.4, 4)
		set_pev(invoker, pev_sequence, iAnim)
		set_nextattack(ent, invoker, 0.25)
		engfunc(EngFunc_EmitSound, invoker, CHAN_WEAPON, S_SOUND[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
		return FMRES_SUPERCEDE
	} else if(g_had_skull5[invoker] && eventid == g_event_skull5) {
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)	
		
		return FMRES_SUPERCEDE
	} else if(g_had_skull7[invoker] && g_had_skull8[invoker] && eventid == g_event_sk_mg) {
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)	
		
		return FMRES_SUPERCEDE
	} else if(g_had_skull11[invoker] && eventid == g_skull11_event) {
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
		
		return FMRES_SUPERCEDE
	}
	
	return FMRES_HANDLED
}

public ham_traceattack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker) || !is_user_connected(attacker))
		return HAM_IGNORED	
	
	static Float:flEnd[3], Damage_New, body
	get_tr2(ptr, TR_vecEndPos, flEnd)
	body = get_tr2(ptr, TR_iHitgroup)
	
	if((get_user_weapon(attacker) == CSW_SKULL3_M1 || get_user_weapon(attacker) == CSW_SKULL3_M2) && g_had_skull3[attacker]) {
		Damage_New = get_damage_body(body, DAMAGE_M1)
		
		make_bullet(attacker, flEnd, CSW_SKULL3_M1)
	} else if(get_user_weapon(attacker) == CSW_SKULL4 && g_had_skull4[attacker]) {
		Damage_New = get_damage_body(body, SKULL4_DMG)
		
		make_bullet(attacker, flEnd, CSW_SKULL4)
	} else if(get_user_weapon(attacker) == CSW_SKULL5 && g_had_skull5[attacker]) {
		
		make_bullet(attacker, flEnd, CSW_SKULL5)
	} else if(get_user_weapon(attacker) == CSW_SK_MG || g_had_skull7[attacker] && g_had_skull8[attacker]) {
		static Float:dmg
		if(g_had_skull7[attacker]) dmg = DMG_SKULL7
		else if(g_had_skull8[attacker]) dmg = DMG_SKULL8
		
		Damage_New = get_damage_body(body, dmg)
		
		make_bullet(attacker, flEnd, CSW_SK_MG)
	} else if(get_user_weapon(attacker) == CSW_SKULL11 && g_had_skull11[attacker]) {
		Damage_New = get_damage_body(body, DAMAGE)
		
		make_bullet(attacker, flEnd, CSW_SKULL11)
	}
	
	//SetHamParamFloat(3, float(Damage_New))
	return HAM_IGNORED
}


public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if((get_user_weapon(attacker) == CSW_SKULL3_M1 || get_user_weapon(attacker) == CSW_SKULL3_M2) && g_had_skull3[attacker]) {
		SetHamParamFloat(4, damage * DAMAGE_M1 )
		} else if(get_user_weapon(attacker) == CSW_SKULL4 && g_had_skull4[attacker]) {
			SetHamParamFloat(4, damage * SKULL4_DMG )
		} else if(get_user_weapon(attacker) == CSW_SKULL5 && g_had_skull5[attacker]) {
			SetHamParamFloat(4, damage * SKULL5_DAMAGE )
		} else if(get_user_weapon(attacker) == CSW_SK_MG || g_had_skull7[attacker] && g_had_skull8[attacker]) {
			static Float:dmg
			if(g_had_skull7[attacker]) dmg = DMG_SKULL8
			else if(g_had_skull8[attacker]) dmg = DMG_SKULL8
			SetHamParamFloat(4, damage * dmg )
		} else if(get_user_weapon(attacker) == CSW_SKULL11 && g_had_skull11[attacker]) {
			SetHamParamFloat(4, damage * DAMAGE )
		}
	}
}
public get_damage_body(body, Float:damage)
{
	switch(body)
	{
		case HIT_HEAD: damage *= 2.0
		case HIT_CHEST: damage *= 1.5
		case HIT_STOMACH: damage *= 1.25
		case HIT_LEFTARM | HIT_RIGHTARM: damage *= 1.20
		case HIT_LEFTLEG | HIT_RIGHTLEG: damage *= 1.15
		default: damage *= 1.0
	}
	return floatround(damage)
}

public ham_add_skull3_m1(ent, id)
{
	if(!pev_valid(ent))
		return
	
	if(pev(ent, pev_impulse) == SKULL3_KEY)
	{
		if(pev_valid(g_remove_ent[id])) Remove_Ent(g_remove_ent[id])
		
		g_had_skull3[id] = 1
		set_pev(id, pev_impulse, 0)
		g_skull3_mode[id] = 1
		client_cmd(id, weapon_skull3_m1)
		
		Create_Model(id, 1)
	}
}
Remove_Ent(ent)
{
	set_pev(ent, pev_renderfx, kRenderFxGlowShell)
	set_pev(ent, pev_rendermode, kRenderTransAlpha)
	set_pev(ent, pev_renderamt, 0)
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_flags, FL_KILLME)
}

Create_Model(id, mode)
{
	set_pev(id, pev_viewmodel2, mode == 1 ? V_MODEL_SKULL3 : V_MODEL_SKULL3)
	set_pev(id, pev_weaponmodel2, mode == 1 ? P_MODEL_SKULL3 : V_MODEL_SKULL3)
}
public fw_AddToPlayer_sk4(ent, id)
{
	if(!pev_valid(ent) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(pev(ent, pev_impulse) == SKULL4_KEY)
	{
		g_had_skull4[id] = 1
		set_pev(ent, pev_impulse, 0)
	}
	
	return HAM_IGNORED
}

public fw_SKULL5_AddToPlayer_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	if(pev(ent, pev_impulse) == SKULL5_KEY)
	{
		g_had_skull5[id] = 1
		set_pev(ent, pev_impulse, 0)
		
		return HAM_HANDLED
	}
	
	return HAM_HANDLED
}

public fw_AddToPlayer_Mg(ent, id)
{
	if(!is_valid_ent(ent) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(pev(ent, pev_impulse) == SKULL7_KEY) {
		g_had_skull7[id] = 1
		set_pev(ent, pev_impulse, 0)
	} else if(pev(ent, pev_impulse) == SKULL8_KEY) {
		g_had_skull8[id] = 1
		set_pev(ent, pev_impulse, 0)
	}
	return HAM_IGNORED
}

public fw_Item_AddToPlayer_sk11(ent, id)
{
	if(!is_valid_ent(ent) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(pev(ent, pev_impulse) == SKULL11_KEY)
	{
		g_had_skull11[id] = 1
		set_pev(ent, pev_impulse, 0)
	}
	
	return HAM_IGNORED
}

public ham_anim_skull3_m1(ent, anim, skiplocal, body)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)	
	
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !is_user_connected(id))
		return HAM_IGNORED
	if(!g_had_skull3[id])
		return HAM_IGNORED
	
	if(anim == 2)
	{
		if(g_skull3_mode[id] == 2)
		{
			g_skull3_changing[id] = 1
			g_lastinv[id] = 0
			
			Create_Model(id, 1)
			set_weapon_anim(id, ANIM_CHANGE_TO_A)
			
			set_task(3.0, "change_complete1", id)
			set_nextattack(ent, id, 3.0)
			
			reset_player_maxspeed(id)
		} else if(g_skull3_mode[id] == 1) {
			if(!g_skull3_changing[id])
			{
				Create_Model(id, 1)
				set_weapon_anim(id, ANIM_DRAW_A)
				
				g_lastinv[id] = 1
				set_nextattack(ent, id, 1.0)
			} else {
				Create_Model(id, 1)
				set_weapon_anim(id, ANIM_DRAW_A)
				
				g_lastinv[id] = 1
				set_nextattack(ent, id, 1.0)
			}
		}
	}
	
	if(anim == 0)
	{
		if(g_skull3_mode[id] == 1)
		{
			Update_Ammo(id, CSW_SKULL3_M1, cs_get_weapon_ammo(ent))
			cs_set_user_bpammo(id, CSW_SKULL3_M2, cs_get_user_bpammo(id, CSW_SKULL3_M1))
			g_skull3_ammo[id] = cs_get_user_bpammo(id, CSW_SKULL3_M2)
		} else if(g_skull3_mode[id] == 2) {
			Update_Ammo(id, CSW_SKULL3_M2, cs_get_weapon_ammo(ent))
			cs_set_user_bpammo(id, CSW_SKULL3_M1, cs_get_user_bpammo(id, CSW_SKULL3_M2))
			g_skull3_ammo[id] = cs_get_user_bpammo(id, CSW_SKULL3_M1)
		}
	}
	return HAM_IGNORED
}

public ham_anim_skull3_m2(ent, anim, skiplocal, body)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !is_user_connected(id))
		return HAM_IGNORED
	if(!g_had_skull3[id])
		return HAM_IGNORED
	
	
	if(anim == 0)
	{
		if(g_skull3_mode[id] == 1)
		{
			Update_Ammo(id, CSW_SKULL3_M1, cs_get_weapon_ammo(ent))
			cs_set_user_bpammo(id, CSW_SKULL3_M2, cs_get_user_bpammo(id, CSW_SKULL3_M1))
			g_skull3_ammo[id] = cs_get_user_bpammo(id, CSW_SKULL3_M2)
		} else if(g_skull3_mode[id] == 2) {
			Update_Ammo(id, CSW_SKULL3_M2, cs_get_weapon_ammo(ent))
			cs_set_user_bpammo(id, CSW_SKULL3_M1, cs_get_user_bpammo(id, CSW_SKULL3_M2))
			g_skull3_ammo[id] = cs_get_user_bpammo(id, CSW_SKULL3_M1)
		}
	}
	return HAM_IGNORED
}

public fw_Ham_Item_Deploy_Post(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !is_user_connected(id))
		return HAM_IGNORED

	return HAM_IGNORED
}

public ham_deploy_skull3(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !is_user_connected(id))
		return HAM_IGNORED
	if(!g_had_skull3[id])
		return HAM_IGNORED
	
	if(g_lastinv[id]) set_nextattack(ent, id, 1.0)
	else if(g_skull3_changing[id]) set_nextattack(ent, id, 3.0)
	
	return HAM_IGNORED
}

public fw_Item_Deploy_Post_sk4(ent)
{
	static id
	id = fm_cs_get_weapon_ent_owner(ent)
	
	if(!pev_valid(id))
		return
	if(!g_had_skull4[id])
		return
		
	set_pev(id, pev_viewmodel2, V_MODEL_SKULL4)
	set_pev(id, pev_weaponmodel2, P_MODEL_SKULL4)
}

public fw_Item_Deploy_Post_Mg(ent)
{
	static id
	id = fm_cs_get_weapon_ent_owner(ent)
	
	if(!pev_valid(id))
		return
	
	if(g_had_skull7[id]) {
		set_pev(id, pev_viewmodel2, V_MODEL_SKULL7)
		set_pev(id, pev_weaponmodel2, P_MODEL_SKULL7)
	} else if(g_had_skull8[id]) {
		set_pev(id, pev_viewmodel2, V_MODEL_SKULL8)
		set_pev(id, pev_weaponmodel2, P_MODEL_SKULL8)
	}
}

public fw_Item_Deploy_Post_SKULL9(ent)
{
	static id
	id = fm_cs_get_weapon_ent_owner(ent)
	
	if (!pev_valid(id))
		return
	if(!g_had_skullaxe[id] || zp_get_user_zombie(id))
		return
		
	set_pdata_string(id, 492 * 4, ANIM_EXTENSION2, -1 , 20)
	
	set_pev(id, pev_viewmodel2, V_MODEL_SKULL9)
	set_pev(id, pev_weaponmodel2, P_MODEL_SKULL9)
}

public fw_Item_Deploy_Post_sk11(ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(ent)
	if (!pev_valid(id))
		return
	
	static weaponid
	weaponid = cs_get_weapon_id(ent)
	
	if(weaponid != CSW_SKULL11)
		return
	if(!g_had_skull11[id])
		return
		
	set_pev(id, pev_viewmodel2, V_MODEL_SKULL11)
	set_pev(id, pev_weaponmodel2, P_MODEL_SKULL11)
	
	set_weapon_anim(id, 4)
}

public fw_PrimaryAttack_sk11(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!g_had_skull11[id])
		return
		
	pev(id, pev_punchangle, g_punchangles[id])
	Clip[id] = cs_get_weapon_ammo(ent)
}

public ham_attack_skull3(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !is_user_connected(id))
		return HAM_IGNORED
	if(!g_had_skull3[id])
		return HAM_IGNORED
	
	g_is_attacking[id] = 1
	g_Clip[id] = cs_get_weapon_ammo(ent)
	pev(id, pev_punchangle, g_recoil[id])
	
	return HAM_IGNORED
}

public ham_attack_skull3_post(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	g_is_attacking[id] = 0
	
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !is_user_connected(id))
		return HAM_IGNORED
	if(!g_had_skull3[id] || !g_Clip[id])
		return HAM_IGNORED
	
	static Float:recoil[3], Float:Recoil, szAnim[64], iAnim, Duck
	Recoil = RECOIL_M1
	Duck = pev(id, pev_flags) & FL_DUCKING
	
	pev(id, pev_punchangle, recoil)
	xs_vec_sub(recoil, g_recoil[id], recoil)
	xs_vec_mul_scalar(recoil, Recoil, recoil)
	xs_vec_add(recoil, g_recoil[id], recoil)
	set_pev(id, pev_punchangle, recoil)
	
	engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, S_SOUND[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	if(g_skull3_mode[id] == 1)
	{
		set_weapon_anim(id, random_num(ANIM_SHOOT1_A, ANIM_SHOOT3_A))
		EjectBrass(id, clip_shell, -7.0, 15.0, 0.0, -20.0, -100.0)
	} else if(g_skull3_mode[id] == 2) {
		set_pdata_float(ent, 62, 0.4, 4)
		if(g_shot_anim[id] == 0)
		{
			set_weapon_anim(id, random_num(ANIM_SHOOT_LEFT, ANIM_SHOOT_LEFT2))
			g_shot_anim[id] = 1
			EjectBrass(id, clip_shell, -7.0, 15.0, 0.0, -20.0, -100.0)
			formatex(szAnim, charsmax(szAnim), Duck ? "crouch_shoot_%s" : "ref_shoot_%s", ANIM_EXTENSION)
		} else if(g_shot_anim[id] == 1) {
			set_weapon_anim(id, random_num(ANIM_SHOOT_RIGHT, ANIM_SHOOT_RIGHT2))
			g_shot_anim[id] = 0
			EjectBrass(id, clip_shell, -7.0, 15.0, 0.0, 20.0, 100.0)
			formatex(szAnim, charsmax(szAnim), Duck ? "crouch_shoot2_%s" : "ref_shoot2_%s", ANIM_EXTENSION)
		}
		
		if(cs_get_weapon_ammo(ent) == 1) 
		{
			set_weapon_anim(id, ANIM_SHOOT_LEFTLAST)
			formatex(szAnim, charsmax(szAnim), Duck ? "crouch_shoot_%s" : "ref_shoot_%s", ANIM_EXTENSION)
		} else if(cs_get_weapon_ammo(ent) == 0) {
			set_weapon_anim(id, ANIM_SHOOT_RIGHTLAST)
			formatex(szAnim, charsmax(szAnim), Duck ? "crouch_shoot2_%s" : "ref_shoot2_%s", ANIM_EXTENSION)
			set_nextattack(ent, id, 0.5)
		}
		
		if((iAnim = lookup_sequence(id, szAnim)) == -1) iAnim = 0
		set_pev(id, pev_sequence, iAnim)
	}
	return HAM_IGNORED
}

public fw_PrimaryAttack_sk4(ent)
{
	new id = get_pdata_cbase(ent, 41, 4)
	
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !is_user_connected(id))
		return
	if(!g_had_skull4[id])
		return
	
	g_is_attacking[id] = 1
}

public fw_PrimaryAttack_Post_sk4(ent)
{
	new id = get_pdata_cbase(ent, 41, 4)
	
	g_is_attacking[id] = 0
	
	if(!is_user_alive(id) || zp_get_user_zombie(id))
		return
	if(!g_had_skull4[id])
		return
	if(!cs_get_weapon_ammo(ent))
		return
}

public fw_SKULL5_PrimaryAttack(ent)
{
	static id; id = pev(ent, pev_owner)
	
	pev(id, pev_punchangle, g_recoil[id])
	g_Clip_Sk5[id] = cs_get_weapon_ammo(ent)
	return HAM_IGNORED	
}

public fw_SKULL5_PrimaryAttack_Post(ent)
{
	static id
	id = pev(ent,pev_owner)
	
	if(g_had_skull5[id])
	{
		if(!g_Clip_Sk5[id])
			return HAM_IGNORED
		
		static Float:push[3]
		pev(id,pev_punchangle,push)
		xs_vec_sub(push, g_recoil[id],push)
		
		push[0] += random_float(0.0, -2.0)
		xs_vec_mul_scalar(push, SKULL5_RECOIL,push)
		xs_vec_add(push, g_recoil[id], push)
		set_pev(id, pev_punchangle, push)
		
		set_pdata_float(ent, 62, 0.0, 4)
		
		set_weapon_anim(id, random_num(1, 2))
		emit_sound(id, CHAN_WEAPON, S_SOUND[3], 1.0, ATTN_NORM, 0, PITCH_NORM)	
	}
	
	return HAM_IGNORED
}

public fw_PrimaryAttack_Mg(ent)
{
	new id = get_pdata_cbase(ent, 41, 4)
	
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_had_skull7[id])
		return
	
	g_is_attacking[id] = 1
	g_MG_Clip[id] = cs_get_weapon_ammo(ent)
	pev(id, pev_punchangle, cl_pushangle[id])
}

public fw_PrimaryAttack_Mg_Post(ent)
{
	new id = get_pdata_cbase(ent, 41, 4)
	g_is_attacking[id] = 0
	
	if(!is_user_alive(id) || zp_get_user_zombie(id))
		return
	if(!g_MG_Clip[id])
		return

	if(g_had_skull7[id]) {
		set_recoil(id, RECOIL_SKULL7)
		emit_sound(id, CHAN_WEAPON, S_SOUND[5], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		set_weapon_anim(id, random_num(1, 2))
		set_pdata_float(id, 83, SPD_SKULL7, 5)
	} else if(g_had_skull8[id]) {
		set_recoil(id, RECOIL_SKULL8)
		emit_sound(id, CHAN_WEAPON, S_SOUND[random_num(6, 7)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		set_weapon_anim(id, random_num(1, 2))
	}
}

public fw_PrimaryAttack_Post_sk11(ent)
{
	static id
	id = pev(ent, pev_owner)
	
	if(!g_had_skull11[id] || !Clip[id])
		return
		
	static Float:push[3]
	pev(id, pev_punchangle, push)
	xs_vec_sub(push, g_punchangles[id], push)
	xs_vec_mul_scalar(push, RECOIL_SK11, push)
	xs_vec_add(push, g_punchangles[id], push)
	set_pev(id, pev_punchangle, push)
	
	set_weapon_anim(id, random_num(1, 2))
	emit_sound(id, CHAN_WEAPON, S_SOUND[10], 1.0, ATTN_NORM, 0, PITCH_NORM)	
}

public ham_postframe_skull3(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !is_user_connected(id))
		return HAM_IGNORED
	if(!g_had_skull3[id])
		return HAM_IGNORED
	
	new Float:flNextAttack = get_pdata_float(id, 83, 5), iClip = get_pdata_int(ent, 51, 4), fInReload = get_pdata_int(ent, 54, 4)
	static Bpammo, Clip
	Bpammo = cs_get_user_bpammo(id, g_skull3_mode[id] == 1 ? CSW_SKULL3_M1 : CSW_SKULL3_M2)
	Clip = get_pcvar_num(CLIP_M1)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		new temp1 = min(Clip - iClip, Bpammo)			
		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, g_skull3_mode[id] == 1 ? CSW_SKULL3_M1 : CSW_SKULL3_M2, Bpammo - temp1)
		set_pdata_int(ent, 54, 0, 4)
		fInReload = 0
	}
	
	if(get_pdata_float(ent, 48, 4) <= 0.1) 
	{
		if(g_skull3_mode[id] == 2)
		{
			if(iClip == 1) set_weapon_anim(id, ANIM_IDLE_LEFTEMPTY)
			set_pdata_float(ent, 48, 60.0, 4)
			return HAM_IGNORED
		}
	}
	
	return HAM_IGNORED
}

public ham_reload_skull3(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !is_user_connected(id))
		return HAM_IGNORED
	if(!g_had_skull3[id])
		return HAM_IGNORED
	
	g_skull3_clip[id] = -1
	
	static bpammo, clip, iClip
	iClip = get_pdata_int(ent, 51, 4)
	bpammo = cs_get_user_bpammo(id, g_skull3_mode[id] == 1 ? CSW_SKULL3_M1 : CSW_SKULL3_M2)
	clip = CLIP_M1
	
	if(bpammo <= 0 || iClip >= clip)
		return HAM_SUPERCEDE
		
	g_skull3_clip[id] = iClip
	
	return HAM_IGNORED
}

public ham_reload_skull3_post(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !is_user_connected(id))
		return HAM_IGNORED
	if(!g_had_skull3[id])
		return HAM_IGNORED
	if (g_skull3_clip[id] == -1)
		return HAM_IGNORED
	
	static Float:reload_time
	if(g_skull3_mode[id] == 1) reload_time = 2.2
	else
	{
		reload_time = 3.4
		set_pdata_string(id, m_szAnimExtention * 4, ANIM_EXTENSION, -1 , 20)
	}
	
	set_pdata_int(ent, 51, g_skull3_clip[id], 4)
	set_pdata_int(ent, 54, 1, 4)
	set_nextattack(ent, id, reload_time)
	set_weapon_anim(id, g_skull3_mode[id] == 1 ? ANIM_RELOAD_A : ANIM_RELOAD_B)
	
	return HAM_IGNORED
}

public fw_ItemPostFrame_sk4(ent) 
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_had_skull4[id])
		return HAM_IGNORED
     
	new Float:flNextAttack = get_pdata_float(id, 83, 5), iBpAmmo = cs_get_user_bpammo(id, CSW_SKULL4)
	new iClip = get_pdata_int(ent, 51, 4), fInReload = get_pdata_int(ent, 54, 4) 

	if(get_pdata_float(ent, 48, 4) <= 0.25)
	{
		if(iClip == 1) set_weapon_anim(id, ANIM_IDLE_EMPTY)
		set_pdata_float(ent, 48, 20.0, 4)
		return HAM_SUPERCEDE
	}
	
	if(fInReload && flNextAttack <= 0.0)
	{
		new Bla = min(SKULL4_CLIP - iClip, iBpAmmo)
		set_pdata_int(ent, 51, iClip + Bla, 4)
		set_pdata_int(id, 381, iBpAmmo - Bla, 5)
		set_pdata_int(ent, 54, 0, 4)
		fInReload = 0
		is_reloading[id] = 1
	}
	return HAM_IGNORED
}

public fw_Reload_sk4(ent) 
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_had_skull4[id])
		return HAM_IGNORED
	
	g_Clip_Sk4[id] = -1
	is_reloading[id] = 0
	
	new iBpAmmo = cs_get_user_bpammo(id, CSW_SKULL4), iClip = get_pdata_int(ent, 51, 4)

	if(iBpAmmo <= 0 || iClip >= SKULL4_CLIP)
		return HAM_SUPERCEDE
	
	g_Clip_Sk4[id] = iClip
	
	return HAM_IGNORED
}

public fw_Reload_Post_sk4(ent) 
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_had_skull4[id])
		return HAM_IGNORED
	if(g_Clip_Sk4[id] == -1)
		return HAM_IGNORED
	
	if(g_zoomed[id]) cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
	
	set_pdata_int(ent, 51, g_Clip_Sk4[id], 4)
	set_pdata_int(ent, 54, 1, 4)
	set_nextattack(ent, id, 3.43)
	set_weapon_anim(id, ANIM_RELOAD)
	set_pdata_string(id, m_szAnimExtention * 4, ANIM_EXTENSION, -1 , 20)
		
	return HAM_IGNORED
}

public fw_SKULL5_PostFrame(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(is_user_alive(id) && is_user_connected(id) && g_had_skull5[id])
	{	
		static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
		static bpammo; bpammo = cs_get_user_bpammo(id, CSW_SKULL5)
		static iClip; iClip = get_pdata_int(ent, 51, 4)
		static fInReload; fInReload = get_pdata_int(ent, 54, 4)
		
		if(fInReload && flNextAttack <= 0.0)
		{
			static temp1
			temp1 = min(SKULL5_DEFAULT_CLIP - iClip, bpammo)

			set_pdata_int(ent, 51, iClip + temp1, 4)
			cs_set_user_bpammo(id, CSW_SKULL5, bpammo - temp1)
			set_pdata_int(ent, 54, 0, 4)
			
			fInReload = 0
		}		
	}
	
	return HAM_IGNORED	
}

public fw_SKULL5_Reload(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(is_user_alive(id) && is_user_connected(id) && g_had_skull5[id])
	{		
		g_skull5_clip[id] = -1
		
		static bpammo
		bpammo = cs_get_user_bpammo(id, CSW_SKULL5)
		
		static iClip; iClip = get_pdata_int(ent, 51, 4)
		
		if(bpammo <= 0 || iClip >= SKULL5_DEFAULT_CLIP)
			return HAM_SUPERCEDE
		
		g_skull5_clip[id] = iClip
	}
	
	return HAM_IGNORED
}

public fw_SKULL5_Reload_Post(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(is_user_alive(id) && is_user_connected(id) && g_had_skull5[id])
	{	
		if (g_skull5_clip[id] == -1)
			return HAM_IGNORED
		
		static Float:reload_time
		reload_time = SKULL5_RELOAD_TIME
		
		set_pdata_int(ent, 51, g_skull5_clip[id], 4)
		set_pdata_float(ent, 48, reload_time, 4)
		set_pdata_float(id, 83, reload_time, 5)
		set_pdata_int(ent, 54, 1, 4)
		set_weapon_anim(id, 3)
	}
	
	return HAM_IGNORED
}

public fw_ItemPostFrame_Mg(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_had_skull7[id] && !g_had_skull8[id])
		return HAM_IGNORED
	
	new iBpAmmo = cs_get_user_bpammo(id, CSW_SK_MG), iClip = get_pdata_int(ent, 51, 4), fInReload = get_pdata_int(ent, 54, 4) 
	new amount
	if(g_had_skull7[id]) amount = CLIP_SKULL7
	else if(g_had_skull8[id]) amount = CLIP_SKULL8
	
	if(fInReload && get_pdata_float(id, 83, 5) <= 0.0)
	{
		new Clip = min(amount - iClip, iBpAmmo)
	
		set_pdata_int(ent, 51, iClip + Clip, 4)
		cs_set_user_bpammo(id, CSW_SK_MG, iBpAmmo - Clip)
		set_pdata_int(ent, 54, 0, 4)
		is_reloading[id] = 0
		fInReload = 0
	}
	if(g_had_skull8[id]) Skull8_Attack_Knife(id, ent, pev(id, pev_button))
	
	return HAM_IGNORED
}

public fw_Weapon_Reload_Mg(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_had_skull7[id] && !g_had_skull8[id])
		return HAM_IGNORED
	
	g_MG_Clip[id] = -1

	new iBpAmmo = cs_get_user_bpammo(id, CSW_SK_MG), iClip = get_pdata_int(ent, 51, 4)
	new amount
	if(g_had_skull7[id]) amount = CLIP_SKULL7
	else if(g_had_skull8[id]) amount = CLIP_SKULL8
	
	if(iBpAmmo <= 0 || iClip >= amount)
		return HAM_SUPERCEDE

	g_MG_Clip[id] = iClip
	is_reloading[id] = 1

	return HAM_IGNORED
}

public fw_Weapon_Reload_Mg_Post(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_had_skull7[id] && !g_had_skull8[id])
		return HAM_IGNORED
	if(g_MG_Clip[id] == -1)
		return HAM_IGNORED
	
	new Float:reload
	if(g_had_skull7[id]) reload = RELOAD_TIME_SK6_7
	else if(g_had_skull8[id]) reload = RELOAD_TIME_SK8
	
	set_pdata_int(ent, 51, g_MG_Clip[id], 4)
	set_pdata_float(ent, 48, reload, 4)
	set_pdata_float(ent, 83, reload, 5)
	set_pdata_int(ent, 54, 1, 4)
	set_weapon_anim(id, 3)
	g_scope[id] = 0
	
	return HAM_IGNORED
}

public fw_ItemPostFrame_SKULL9(ent)
{
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !is_user_connected(id))
		return HAM_IGNORED
	if(!g_had_skullaxe[id] || get_user_weapon(id) != CSW_SKULLAXE)
		return HAM_IGNORED
	
	Attack_Skull9(id, ent, pev(id, pev_button))
	return HAM_IGNORED
}

public fw_ItemPostFrame_sk11(ent) 
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id) || !is_user_alive(id) || zp_get_user_zombie(id))
		return HAM_IGNORED
	if(get_user_weapon(id) != CSW_SKULL11 || !g_had_skull11[id])
		return HAM_IGNORED
	
	new Float:flNextAttack = get_pdata_float(id, 83, 5), iBpAmmo = cs_get_user_bpammo(id, CSW_SKULL11)
	new iClip = get_pdata_int(ent, 51, 4), fInReload = get_pdata_int(ent, 54, 4) 
	
	if(fInReload && flNextAttack <= 0.0)
	{
		new Clip = min(CLIP2 - iClip, iBpAmmo)
		set_pdata_int(ent, 51, iClip + Clip, 4)
		cs_set_user_bpammo(id, CSW_SKULL11, iBpAmmo - Clip)
		set_pdata_int(ent, 54, 0, 4)
		fInReload = 0
	}
	
	return HAM_IGNORED
}

public fw_Reload_sk11(ent) 
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id) || !is_user_alive(id) || zp_get_user_zombie(id))
		return HAM_IGNORED
	if(get_user_weapon(id) != CSW_SKULL11 || !g_had_skull11[id])
		return HAM_IGNORED
	
	g_sk11_Clip[id] = -1
	
	new iBpAmmo = cs_get_user_bpammo(id, CSW_SKULL11), iClip = get_pdata_int(ent, 51, 4)
	
	if(iBpAmmo <= 0 || iClip >= CLIP2)
		return HAM_SUPERCEDE
	
	g_sk11_Clip[id] = iClip
	
	return HAM_IGNORED
}

public fw_Reload_Post_sk11(ent) 
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_had_skull11[id])
		return HAM_IGNORED
	if(g_sk11_Clip[id] == -1)
		return HAM_IGNORED
		
	set_pdata_int(ent, 51, g_sk11_Clip[id], 4)
	set_pdata_float(ent, 48, RELOAD_TIME, 4)
	set_pdata_float(id, 83, RELOAD_TIME, 5)
	set_pdata_int(ent, 54, 1, 4)
	set_weapon_anim(id, 3)
	
	return HAM_IGNORED
}

public Event_Death()
{
	static weapon[32], attacker
	get_msg_arg_string(4, weapon, charsmax(weapon))
	attacker = get_msg_arg_int(1)
	
	if(!is_user_alive(attacker) && !is_user_connected(attacker))
		return PLUGIN_CONTINUE
	
	if(g_had_skull3[attacker] && equal(weapon, "mp5navy") && get_user_weapon(attacker) == CSW_SKULL3_M1) set_msg_arg_string(4, "skull3")
	else if(g_had_skull3[attacker] && equal(weapon, "p90") && get_user_weapon(attacker) == CSW_SKULL3_M2) set_msg_arg_string(4, "skull3d")
	else if(g_had_skull4[attacker] && equal(weapon, "ak47") && get_user_weapon(attacker) == CSW_SKULL4) set_msg_arg_string(4, "skull4")
	else if(g_had_skull5[attacker] && equal(weapon, "g3sg1") && get_user_weapon(attacker) == CSW_SKULL5) set_msg_arg_string(4, "skull5")
	else if(equal(weapon, "m249") && get_user_weapon(attacker) == CSW_SK_MG)
	{
		if(g_had_skull7[attacker]) set_msg_arg_string(4, "m249ex")
		else if(g_had_skull8[attacker]) set_msg_arg_string(4, "skull8")
	} else if(g_had_skullaxe[attacker] && equal(weapon, "knife") && get_user_weapon(attacker) == CSW_SKULLAXE) set_msg_arg_string(4, "skullaxe")
	
	return PLUGIN_CONTINUE
}

stock set_recoil(id, Float:recoil)
{
	new Float:push[3]
	
	pev(id, pev_punchangle, push)
	xs_vec_sub(push, cl_pushangle[id], push)
	xs_vec_mul_scalar(push, recoil, push)
	xs_vec_add(push, cl_pushangle[id], push)
	set_pev(id, pev_punchangle, push)
}

public client_PostThink(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !is_user_connected(id))
		return
	if(!g_had_skull3[id])
		return
	if(get_user_weapon(id) != CSW_SKULL3_M2 || g_skull3_mode[id] != 2)
		return
	

	set_pdata_string(id, m_szAnimExtention * 4, ANIM_EXTENSION, -1 , 20)
}

public Skull8_Attack_Knife(id, iEnt, iButton)
{
	if(get_pdata_float(id, 83) > 0.0)
		return
	
	new attcking = pev(iEnt, pev_iuser1)
	new anim = pev(iEnt, pev_iuser2)
		
	new enemy, body
	get_user_aiming(id, enemy, body)
	if ((1 <= enemy <= 32) && zp_get_user_zombie(enemy) && is_user_bot(id))
	{
		new origin1[3] ,origin2[3],range
		get_user_origin(id,origin1)
		get_user_origin(enemy,origin2)
		range = get_distance(origin1, origin2)
		if(range <= floatround(SKULL8_SLASH_RAD) + 50) {
			anim = 1 - anim
			set_pev(iEnt, pev_iuser2, anim)
			set_pev(iEnt, pev_iuser1, 1)
			set_weapon_anim(id, anim ? 5 : 6)
			
			set_pdata_float(iEnt, 48, 1.76, 4)
			set_pdata_float(iEnt, 46, 1.76)
			set_pdata_float(id, 83, 0.84)
		}
	}
	if(get_pdata_float(iEnt, 46, 4) <= 0.0 && iButton & IN_ATTACK2 && iButton & ~IN_ATTACK)
	{
		anim = 1 - anim
		set_pev(iEnt, pev_iuser2, anim)
		set_pev(iEnt, pev_iuser1, 1)
		set_weapon_anim(id, anim ? 5 : 6)
		
		set_pdata_float(iEnt, 48, 1.76, 4)
		set_pdata_float(iEnt, 46, 1.76)
		set_pdata_float(id, 83, 0.84)
	}
	
	if(attcking)
	{
		new Result = Damage_Stab(id, true, SKULL8_SLASH_RAD, 120.0, is_deadlyshot(id)?SKULL8_SLASH_DMG*1.5:SKULL8_SLASH_DMG)
		new sound[128]
		
		switch(Result)
		{
			case HIT_ENEMY: format(sound, charsmax(sound), Skullaxe_Sounds[1])
			case HIT_WALL: format(sound, charsmax(sound), Skullaxe_Sounds[5])
		}
		
		emit_sound(id, CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		set_pev(iEnt, pev_iuser1, 0)
		set_pdata_float(iEnt, 48, 0.92, 4)
		set_pdata_float(id, 83, 0.92)
	}
}

public Attack_Skull9(id, iEnt, iButton)
{
	set_pdata_string(id, 492 * 4, ANIM_EXTENSION2, -1 , 20)
	
	if(get_pdata_float(iEnt, 46) <= 0.0)
	{
		if(iButton & IN_ATTACK)
		{
			set_pdata_float(iEnt, 46, 1.3375, 4)
			set_pdata_float(iEnt, 47, 1.3775 + 0.1, 4)
			set_pdata_float(iEnt, 48, 1.3775 + 3.0, 4)
			set_pdata_float(id, 83, 1.0, 5)
			
			set_pev(iEnt, pev_iuser2, 0)
			set_weapon_anim(id, SKULL9_ANIM_SLASH_START)
			
			set_task(1.0, "Attack", id)
		} else if(iButton & IN_ATTACK2) {
			set_pdata_float(iEnt, 46, 1.5, 4)
			set_pdata_float(iEnt, 47, 1.5, 4)
			set_pdata_float(iEnt, 48, 1.5 + 2.0, 4)
			set_pdata_float(id, 83, 1.08, 5)
			
			set_pev(iEnt, pev_iuser2, 1)
			
			set_weapon_anim(id, SKULL9_ANIM_STAB)
			set_task(1.1, "Attack", id)
		}
		iButton &= ~IN_ATTACK
		iButton &= ~IN_ATTACK2
		set_pev(id, pev_button, iButton)
	}
}

public Attack(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !is_user_connected(id) || !g_had_skullaxe[id])
		return
	
	new ent = fm_get_user_weapon_entity(id, CSW_SKULLAXE)
	
	if(!pev_valid(ent))
		return
	
	new iHitResult, sound[128], bool:bStab = pev(ent, pev_iuser2) ? true : false
	if(!bStab)
	{			
		iHitResult = Damage_Slash(id, false, 100.0, is_deadlyshot(id)?SLASH_DAMAGE*1.5:SLASH_DAMAGE)
		
		switch(iHitResult)
		{
			case HIT_ENEMY: format(sound, charsmax(sound), Skullaxe_Sounds[1])
			case HIT_WALL: format(sound, charsmax(sound), Skullaxe_Sounds[5])
			case HIT_NOTHING: format(sound, charsmax(sound), Skullaxe_Sounds[2])
		}
		if(iHitResult != HIT_NOTHING) set_weapon_anim(id, SKULL9_ANIM_SLASH_HIT)
		else set_weapon_anim(id, SKULL9_ANIM_SLASH_MISS)
	} else {
		iHitResult = Damage_Stab(id, true, 120.0, 120.0, is_deadlyshot(id)?STAB_DAMAGE*1.5:STAB_DAMAGE)
		
		switch(iHitResult)
		{
			case HIT_ENEMY: format(sound, charsmax(sound), Skullaxe_Sounds[1])
			case HIT_WALL: format(sound, charsmax(sound), Skullaxe_Sounds[5])
			case HIT_NOTHING: format(sound, charsmax(sound), Skullaxe_Sounds[2])
		}
	}
	emit_sound(id, CHAN_WEAPON, sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

public change_complete1(id)
{
	g_skull3_changing[id] = 0
	
	if(get_user_weapon(id) == CSW_SKULL3_M1 && g_had_skull3[id])
		g_skull3_mode[id] = 1
}

public change_complete2(id)
{
	g_skull3_changing[id] = 0
	
	if(get_user_weapon(id) == CSW_SKULL3_M2 && g_had_skull3[id])
		g_skull3_mode[id] = 2
}

stock set_weapon_anim(id, anim)
{ 
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock set_nextattack(weapon, player, Float:nextTime)
{
	if(!pev_valid(weapon))	
		return
	
	set_pdata_float(weapon, 46, nextTime, 4)
	set_pdata_float(weapon, 47, nextTime, 4)
	set_pdata_float(weapon, 48, nextTime, 4)
	set_pdata_float(player, 83, nextTime, 5)
}

stock Update_Ammo(id, CSW, clip)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), _, id)
	write_byte(1)
	write_byte(CSW)
	write_byte(clip)
	message_end()
}

stock fm_cs_get_weapon_ent_owner(ent) return get_pdata_cbase(ent, 41, 4)

stock make_bullet(id, Float:Origin[3], Wpn)
{
	if(get_user_weapon(id) != Wpn)
		return
	
	new target, body, TE_FLAG, decal = 41
	get_user_aiming(id, target, body)
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	if(target > 0 && target <= get_maxplayers())
	{
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3]
		pev(id, pev_origin, fStart)
		velocity_by_aim(id, 64, fVel)
		
		fStart[0] = Origin[0]
		fStart[1] = Origin[1]
		fStart[2] = Origin[2]
		fEnd[0] = fStart[0] + fVel[0]
		fEnd[1] = fStart[1] + fVel[1]
		fEnd[2] = fStart[2] + fVel[2]
		
		new res
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res)
		get_tr2(res, TR_vecEndPos, fRes)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(TE_BLOODSPRITE)
		write_coord(floatround(fStart[0])) 
		write_coord(floatround(fStart[1])) 
		write_coord(floatround(fStart[2])) 
		write_short(g_blood[1])
		write_short(g_blood[0])
		write_byte(70)
		write_byte(random_num(3,7))
		message_end()
	} else {
		if(target)
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_DECAL)
			write_coord(floatround(Origin[0]))
			write_coord(floatround(Origin[1]))
			write_coord(floatround(Origin[2]))
			write_byte(decal)
			write_short(target)
			message_end()
		} else {
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_WORLDDECAL)
			write_coord(floatround(Origin[0]))
			write_coord(floatround(Origin[1]))
			write_coord(floatround(Origin[2]))
			write_byte(decal)
			message_end()
		}
		
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

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)
	
	// Weapon bitsums
	const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
	const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
	
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			static wname[32]
			get_weaponname(weaponid, wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock reset_player_maxspeed(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id))
		return
		
	fm_set_user_maxspeed(id, g_oldspeed[id])
}

enum (<<=1)
{
	v_angle = 1,
	punchangle
}

public EjectBrass(id, mdl, Float:up, Float:forw, Float:right , Float:right_coord1 , Float:right_coord2)
{
	static Float:velocity[3], Float:angle[3], Float:origin[3], Float:ViewOfs[3], i, Float:ShellOrigin[3],  Float:ShellVelocity[3], Float:Right[3], Float:Up[3], Float:Forward[3]
	
	make_vectors(id, v_angle + punchangle)
	
	pev(id, pev_velocity, velocity)
	pev(id, pev_view_ofs, ViewOfs)
	pev(id, pev_angles, angle)
	pev(id, pev_origin, origin)
	global_get(glb_v_right, Right)
	global_get(glb_v_up, Up)
	global_get(glb_v_forward, Forward)
	
	for( i = 0; i < 3; i++ )
	{
		ShellOrigin[i] = origin[i] + ViewOfs[i] + Up[i] * up + Forward[i] * forw + Right[i] * right
		ShellVelocity[i] = velocity[i] + Right[i] * random_float(right_coord1, right_coord2) + Up[i] * random_float(100.0, 150.0) + Forward[i] * 25.0
	}
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, ShellOrigin, 0)
	write_byte(TE_MODEL)
	engfunc(EngFunc_WriteCoord, ShellOrigin[0])
	engfunc(EngFunc_WriteCoord, ShellOrigin[1])
	engfunc(EngFunc_WriteCoord, ShellOrigin[2])	
	engfunc(EngFunc_WriteCoord, ShellVelocity[0])
	engfunc(EngFunc_WriteCoord, ShellVelocity[1])
	engfunc(EngFunc_WriteCoord, ShellVelocity[2])
	engfunc(EngFunc_WriteAngle, angle[1])
	write_short(mdl)
	write_byte(1)
	write_byte(15) // 2.5 seconds
	message_end()
}

stock make_vectors(id, AngleType)
{
	static Float:PunchAngles[3], Float:angle[3]
	if(AngleType & v_angle) pev(id, pev_v_angle, angle)
	if(AngleType & punchangle) pev(id, pev_punchangle, PunchAngles)
	
	xs_vec_add(angle, PunchAngles, angle)
	engfunc(EngFunc_MakeVectors, angle)
}

stock precache_sounds_from_model(const model[])
{
	new file, i, k
	if((file = fopen(model, "rt")))
	{
		new szsoundpath[64], num_seq, seq_id, event, num_events, event_id
		
		fseek(file, 164, SEEK_SET)
		fread(file, num_seq, BLOCK_INT)
		fread(file, seq_id, BLOCK_INT)
		
		for(i = 0; i < num_seq; i++)
		{
			fseek(file, seq_id + 48 + 176 * i, SEEK_SET)
			fread(file, num_events, BLOCK_INT)
			fread(file, event_id, BLOCK_INT)
			fseek(file, event_id + 176 * i, SEEK_SET)

			for(k = 0; k < num_events; k++)
			{
				fseek(file, event_id + 4 + 76 * k, SEEK_SET)
				fread(file, event, BLOCK_INT)
				fseek(file, 4, SEEK_CUR)
				
				if(event != 5004)
					continue
				
				fread_blocks(file, szsoundpath, 64, BLOCK_CHAR)
				
				if(strlen(szsoundpath))
				{
					strtolower(szsoundpath)
					engfunc(EngFunc_PrecacheSound, szsoundpath)
				}
			}
		}
	}
	fclose(file)
}

stock Damage_Slash(id, bool:bStab, Float:fRange, Float:flDamage)
{
	new Float:vecScr[3], Float:vecEnd[3], Float:V_angle[3], Float:vecForward[3]
	GetGunPosition(id, vecScr)
	pev(id, pev_v_angle, V_angle)
	engfunc(EngFunc_MakeVectors, V_angle)
	global_get(glb_v_forward, vecForward)
	xs_vec_mul_scalar(vecForward, fRange, vecForward)
	xs_vec_add(vecScr, vecForward, vecEnd)

	new tr = create_tr2()
	engfunc(EngFunc_TraceLine, vecScr, vecEnd, 0, id, tr)
	new Float:flFraction
	get_tr2(tr, TR_flFraction, flFraction)
	
	if(flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecScr, vecEnd, 0, 3, id, tr)

	get_tr2(tr, TR_flFraction, flFraction)

	new iHitResult = HIT_NOTHING
	
	if(flFraction < 1.0)
	{
		new pEntity = get_tr2(tr, TR_pHit)
		iHitResult = HIT_WALL

		if(pev_valid(pEntity) && (IsPlayer(pEntity) || IsHostage(pEntity)))
		{
			if(CheckBack(id, pEntity) && bStab) flDamage *= 3.0
			iHitResult = HIT_ENEMY
		}

		if(pev_valid(pEntity))
		{
			do_attack(id, pEntity, 0, Float:flDamage)
			
			if(IsAlive(pEntity))
			{
				free_tr2(tr)
				return iHitResult
			}
		}
	}
	free_tr2(tr)
	return iHitResult
}

stock Damage_Stab(id, bool:bStab, Float:flRange, Float:fAngle, Float:flDamage)
{
	new iHitResult = HIT_NOTHING
	new Float:vecOrigin[3], Float:vecScr[3], Float:vecEnd[3], Float:V_Angle[3], Float:vecForward[3]
	pev(id, pev_origin, vecOrigin)
	GetGunPosition(id, vecScr)
	pev(id, pev_v_angle, V_Angle)
	engfunc(EngFunc_MakeVectors, V_Angle)
	global_get(glb_v_forward, vecForward)
	xs_vec_mul_scalar(vecForward, flRange, vecForward)
	xs_vec_add(vecScr, vecForward, vecEnd)

	new tr = create_tr2()
	engfunc(EngFunc_TraceLine, vecScr, vecEnd, 0, id, tr)
	new Float:flFraction
	get_tr2(tr, TR_flFraction, flFraction)

	if(flFraction < 1.0) iHitResult = HIT_WALL

	new Float:vecEndZ = vecEnd[2]
	new pEntity = -1
	
	while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, flRange)) != 0)
	{
		if(!pev_valid(pEntity))
			continue
		if(!IsAlive(pEntity))
			continue
		if(!CheckAngle(id, pEntity, fAngle))
			continue

		GetGunPosition(id, vecScr)
		Stock_Get_Origin(pEntity, vecEnd)
		vecEnd[2] = vecScr[2] + (vecEndZ - vecScr[2]) * (get_distance_f(vecScr, vecEnd) / flRange)
		
		engfunc(EngFunc_TraceLine, vecScr, vecEnd, 0, id, tr)
		get_tr2(tr, TR_flFraction, flFraction)

		if(flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecScr, vecEnd, 0, 3, id, tr)
		
		get_tr2(tr, TR_flFraction, flFraction)
		new pHit = get_tr2(tr, TR_pHit)
		
		if(flFraction < 1.0)
		{
			if(IsPlayer(pEntity) || IsHostage(pEntity))
			{
				iHitResult = HIT_ENEMY

				if(CheckBack(id, pEntity) && bStab)
					flDamage *= 3.0
			}
			if(pev_valid(pEntity) && pHit == pEntity && id != pEntity)
			{
				do_attack(id, pEntity, 0, Float:flDamage)
				make_blood(flDamage, pHit)
			}
		}
		free_tr2(tr)
	}
	return iHitResult
}

do_attack(Attacker, Victim, Inflictor, Float:fDamage)
{
	fake_player_trace_attack(Attacker, Victim, fDamage)
	fake_take_damage(Attacker, Victim, fDamage, Inflictor)
}

fake_player_trace_attack(iAttacker, iVictim, &Float:fDamage)
{
	new Float:fAngles[3], Float:fDirection[3]
	pev(iAttacker, pev_angles, fAngles)
	angle_vector(fAngles, ANGLEVECTOR_FORWARD, fDirection)
	
	new Float:fStart[3], Float:fViewOfs[3]
	pev(iAttacker, pev_origin, fStart)
	pev(iAttacker, pev_view_ofs, fViewOfs)
	xs_vec_add(fViewOfs, fStart, fStart)
	
	new iAimOrigin[3], Float:fAimOrigin[3]
	get_user_origin(iAttacker, iAimOrigin, 3)
	IVecFVec(iAimOrigin, fAimOrigin)
	
	new ptr = create_tr2(), pHit = get_tr2(ptr, TR_pHit), iHitgroup = get_tr2(ptr, TR_iHitgroup), Float:fEndPos[3], iTarget, iBody
	engfunc(EngFunc_TraceLine, fStart, fAimOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr)
	get_tr2(ptr, TR_vecEndPos, fEndPos)
	get_user_aiming(iAttacker, iTarget, iBody)
	
	if (iTarget == iVictim) iHitgroup = iBody
	else if (pHit != iVictim)
	{
		new Float:fVicOrigin[3], Float:fVicViewOfs[3], Float:fAimInVictim[3]
		pev(iVictim, pev_origin, fVicOrigin)
		pev(iVictim, pev_view_ofs, fVicViewOfs) 
		xs_vec_add(fVicViewOfs, fVicOrigin, fAimInVictim)
		fAimInVictim[2] = fStart[2]
		fAimInVictim[2] += get_distance_f(fStart, fAimInVictim) * floattan( fAngles[0] * 2.0, degrees )
		
		new iAngleToVictim = get_angle_to_target(iAttacker, fVicOrigin)
		iAngleToVictim = abs(iAngleToVictim)
		new Float:fDis = 2.0 * get_distance_f(fStart, fAimInVictim) * floatsin( float(iAngleToVictim) * 0.5, degrees )
		new Float:fVicSize[3]
		pev(iVictim, pev_size , fVicSize)
		
		if(fDis <= fVicSize[0] * 0.5)
		{
			new ptr2 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fAimInVictim, DONT_IGNORE_MONSTERS, iAttacker, ptr2)
			new pHit2 = get_tr2(ptr2, TR_pHit)
			new iHitgroup2 = get_tr2(ptr2, TR_iHitgroup)
			
			if(pHit2 == iVictim && (iHitgroup2 != HIT_HEAD || fDis <= fVicSize[0] * 0.25))
			{
				pHit = iVictim
				iHitgroup = iHitgroup2
				get_tr2(ptr2, TR_vecEndPos, fEndPos)
			}
			free_tr2(ptr2)
		}
		
		if(pHit != iVictim)
		{
			iHitgroup = HIT_GENERIC
			new ptr3 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fVicOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr3)
			get_tr2(ptr3, TR_vecEndPos, fEndPos)
			
			free_tr2(ptr3)
		}
	}
	
	set_tr2(ptr, TR_pHit, iVictim)
	set_tr2(ptr, TR_iHitgroup, iHitgroup)
	set_tr2(ptr, TR_vecEndPos, fEndPos)
	
	new Float:fMultifDamage 
	switch(iHitgroup)
	{
		case HIT_HEAD: fMultifDamage  = 4.0
		case HIT_STOMACH: fMultifDamage  = 1.25
		case HIT_LEFTLEG|HIT_RIGHTLEG: fMultifDamage  = 0.75
		case HIT_RIGHTARM|HIT_LEFTARM: fMultifDamage  = 0.75
		default: fMultifDamage  = 1.0
	}
	fDamage *= fMultifDamage
	fake_trake_attack(iAttacker, iVictim, fDamage, fDirection, ptr)
	free_tr2(ptr)
}

stock fake_trake_attack(iAttacker, iVictim, Float:fDamage, Float:fDirection[3], iTraceHandle, iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
	ExecuteHamB(Ham_TraceAttack, iVictim, iAttacker, fDamage, fDirection, iTraceHandle, iDamageBit)
}

stock fake_take_damage(iAttacker, iVictim, Float:fDamage, iInflictor = 0, iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
	iInflictor = (!iInflictor) ? iAttacker : iInflictor
	ExecuteHamB(Ham_TakeDamage, iVictim, iInflictor, iAttacker, fDamage, iDamageBit)
}

stock get_angle_to_target(id, const Float:fTarget[3], Float:TargetSize = 0.0)
{
	new Float:fOrigin[3], iAimOrigin[3], Float:fAimOrigin[3], Float:fV1[3]
	pev(id, pev_origin, fOrigin)
	get_user_origin(id, iAimOrigin, 3)
	IVecFVec(iAimOrigin, fAimOrigin)
	xs_vec_sub(fAimOrigin, fOrigin, fV1)
	
	new Float:fV2[3]
	xs_vec_sub(fTarget, fOrigin, fV2)
	
	new iResult = get_angle_between_vectors(fV1, fV2)
	
	if (TargetSize > 0.0)
	{
		new Float:fTan = TargetSize / get_distance_f(fOrigin, fTarget)
		new fAngleToTargetSize = floatround( floatatan(fTan, degrees) )
		iResult -= (iResult > 0) ? fAngleToTargetSize : -fAngleToTargetSize
	}
	return iResult
}

stock get_angle_between_vectors(const Float:fV1[3], const Float:fV2[3])
{
	new Float:fA1[3], Float:fA2[3]
	engfunc(EngFunc_VecToAngles, fV1, fA1)
	engfunc(EngFunc_VecToAngles, fV2, fA2)
	
	new iResult = floatround(fA1[1] - fA2[1])
	iResult = iResult % 360
	iResult = (iResult > 180) ? (iResult - 360) : iResult
	
	return iResult
}

stock make_blood(Float:Damage, pHit)
{
	new bloodColor = ExecuteHam(Ham_BloodColor, pHit), Float:origin[3]
	pev(pHit, pev_origin, origin)

	if (bloodColor == -1)
		return

	new amount = floatround(Damage)
	amount *= 2

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_short(g_blood[1])
	write_short(g_blood[0])
	write_byte(bloodColor)
	write_byte(min(max(3, amount/10), 16))
	message_end()
}

stock IsPlayer(pEntity) return is_user_connected(pEntity)
stock IsHostage(pEntity)
{
	new classname[32]; pev(pEntity, pev_classname, classname, charsmax(classname))
	return equal(classname, "hostage_entity")
}
stock IsAlive(pEntity)
{
	if(pEntity < 1) return 0
	return (pev(pEntity, pev_deadflag) == DEAD_NO && pev(pEntity, pev_health) > 0)
}
stock GetGunPosition(id, Float:vecScr[3])
{
	new Float:vecViewOfs[3]
	pev(id, pev_origin, vecScr)
	pev(id, pev_view_ofs, vecViewOfs)
	xs_vec_add(vecScr, vecViewOfs, vecScr)
}
stock CheckBack(iEnemy,id)
{
	new Float:anglea[3], Float:anglev[3]
	pev(iEnemy, pev_v_angle, anglea)
	pev(id, pev_v_angle, anglev)
	new Float:angle = anglea[1] - anglev[1] 
	if(angle < -180.0) angle += 360.0
	if(angle <= 45.0 && angle >= -45.0) return 1
	return 0
}
stock CheckAngle(iAttacker, iVictim, Float:fAngle) return(Stock_CheckAngle(iAttacker, iVictim) > floatcos(fAngle,degrees))
stock Float:Stock_CheckAngle(id,iTarget)
{
	new Float:vOricross[2],Float:fRad,Float:vId_ori[3],Float:vTar_ori[3],Float:vId_ang[3],Float:fLength,Float:vForward[3]
	Stock_Get_Origin(id, vId_ori)
	Stock_Get_Origin(iTarget, vTar_ori)
	
	pev(id,pev_angles,vId_ang)
	for(new i=0;i<2;i++) vOricross[i] = vTar_ori[i] - vId_ori[i]
	
	fLength = floatsqroot(vOricross[0]*vOricross[0] + vOricross[1]*vOricross[1])
	
	if(fLength<=0.0)
	{
		vOricross[0]=0.0
		vOricross[1]=0.0
	} else {
		vOricross[0]=vOricross[0]*(1.0/fLength)
		vOricross[1]=vOricross[1]*(1.0/fLength)
	}
	
	engfunc(EngFunc_MakeVectors,vId_ang)
	global_get(glb_v_forward,vForward)
	
	fRad = vOricross[0]*vForward[0]+vOricross[1]*vForward[1]
	
	return fRad   //->   RAD 90' = 0.5rad
}
stock Stock_Get_Origin(id, Float:origin[3])
{
	new Float:maxs[3],Float:mins[3]
	if(pev(id,pev_solid)==SOLID_BSP)
	{
		pev(id,pev_maxs,maxs)
		pev(id,pev_mins,mins)
		origin[0] = (maxs[0] - mins[0]) / 2 + mins[0]
		origin[1] = (maxs[1] - mins[1]) / 2 + mins[1]
		origin[2] = (maxs[2] - mins[2]) / 2 + mins[2]
	} else pev(id,pev_origin,origin)
}
