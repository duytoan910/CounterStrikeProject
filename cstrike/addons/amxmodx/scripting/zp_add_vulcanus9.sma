#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <xs>
#include <zombieplague>

#define PLUGIN "[ZP] Extra Item: Vulcanus 9"
#define VERSION "1.0"
#define AUTHOR "https://fb.com/d.toan910"

#define V_MODEL "models/v_vulcanus9.mdl"
#define P_MODEL "models/p_vulcanus9.mdl"
#define muzzleflash "sprites/flame3.spr"

#define DAMAGE_A 600.0 // 200 for Zombie
#define RADIUS_A 100.0
#define BURNDAMAGE 100.0
#define BURNDELAY 1.0
#define BURNTIME 5.0

#define CSW_VULCANUS9 CSW_KNIFE
#define weapon_vulcanus9 "weapon_knife"
#define WEAPON_ANIMEXT "knife" //"skullaxe"
#define BURN_DAMAGE_CLASSNAME "v9_burn"

#define TASK_SLASHING 2033+20
#define TASK_STABING 2033+10

// OFFSET
const PDATA_SAFE = 2
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_WEAPONOWNER = 41
const m_flNextAttack = 83
const m_szAnimExtention = 492

new g_on[33], g_FlameCharge[33]

new const WeaponSounds[][] =
{
	"weapons/vulcanus9_draw.wav", //0
	"weapons/vulcanus9_idle.wav", //1
	"weapons/vulcanus9_off.wav", //2
	"weapons/vulcanus9_off_draw.wav", //3
	"weapons/vulcanus9_off_slash1.wav", //4
	"weapons/vulcanus9_off_slash2.wav", //5
	"weapons/vulcanus9_on.wav", //6
	"weapons/vulcanus9_stab_miss.wav", //7
	"weapons/vulcanus9_stab1.wav", //8
	"weapons/tomahawk_slash1_hit.wav", //9
	"weapons/tomahawk_slash2_hit.wav", //10
	"weapons/tomahawk_stab_hit.wav", //11
	"weapons/tomahawk_wall.wav" //12
}
enum
{
	ANIM_IDLE = 0,
	ANIM_ON,
	ANIM_OFF,
	ANIM_DRAW,
	ANIM_STAB,
	ANIM_STAB_MISS,
	ANIM_MSLASH1,
	ANIM_MSLASH2,
	ANIM_OFF_DRAW,
	ANIM_OFF_IDLE,
	ANIM_OFF_SLASH1,
	ANIM_OFF_SLASH2,
}
enum
{
	ATTACK_SLASH= 1
}

enum
{
	HIT_NOTHING = 0,
	HIT_ENEMY,
	HIT_WALL
}

enum (+= 100)
{
	TASK_BURN_EFFECT = 2000
}

// IDs inside tasks
#define ID_BURN_EFFECT (taskid - TASK_BURN_EFFECT)

new g_had_vulcanus9[33], g_Attack_Mode[33], g_Checking_Mode[33], g_Hit_Ing[33]
new g_Old_Weapon[33], g_Ham_Bot,m_iBlood[2], g_flameSpr
new const g_flameBurnSpr[] = "sprites/flame.spr"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_TraceLine, "fw_TraceLine",1)
	register_forward(FM_TraceHull, "fw_TraceHull")
	register_forward(FM_Think, "fw_Think")	
	
	register_forward(FM_CheckVisibility, "fw_CheckVisibility")
	RegisterHam(Ham_TraceAttack, "player", "fw_PlayerTraceAttack")
	RegisterHam(Ham_Item_Deploy, weapon_vulcanus9, "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Item_Holster, weapon_vulcanus9, "fw_Item_Holster_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_vulcanus9, "fw_Item_Idle_Post", 1)
	RegisterHam(Ham_Think, "env_sprite",  "HamHook_Spr_Think");
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")

	register_clcmd("weapon_vulcanus9", "Hook_Weapon")
}

public plugin_natives()
{
	register_native("skullaxe", "get_vulcanus9", 1)
}
public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	
	for(new i = 0; i < sizeof(WeaponSounds); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
	m_iBlood[0] = precache_model("sprites/blood.spr");
	m_iBlood[1] = precache_model("sprites/bloodspray.spr");	
	g_flameSpr = engfunc(EngFunc_PrecacheModel, "sprites/flame3.spr")

	engfunc(EngFunc_PrecacheModel, g_flameBurnSpr)
	precache_model(muzzleflash)
}

public zp_user_infected_post(id) remove_vulcanus9(id)
public get_vulcanus9(id)
{
	remove_task(id+TASK_SLASHING)
	remove_task(id+TASK_STABING)
		
	g_had_vulcanus9[id] = 1
	g_Attack_Mode[id] = 0
	g_Checking_Mode[id] = 0
	g_Hit_Ing[id] = 0
	g_on[id] = 0
	g_FlameCharge[id] = 10

	fm_give_item(id, "weapon_knife")
	if (get_user_weapon(id) == CSW_VULCANUS9) Event_CurWeapon(id)
	else engclient_cmd(id,"weapon_vulcanus9")
}

public remove_vulcanus9(id)
{
	remove_task(id+TASK_SLASHING)
	remove_task(id+TASK_STABING)
		
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string("weapon_vulcanus9")
	write_byte(-1)
	write_byte(-1)
	write_byte(-1)
	write_byte(-1)
	write_byte(2)
	write_byte(1)
	write_byte(CSW_VULCANUS9)
	write_byte(0)
	message_end()

	g_had_vulcanus9[id] = 0
	g_Attack_Mode[id] = 0
	g_Checking_Mode[id] = 0
	g_Hit_Ing[id] = 0
	g_on[id] = 0
	g_FlameCharge[id] = 0
}

public Hook_Weapon(id)
{
	engclient_cmd(id, weapon_vulcanus9)
	return PLUGIN_HANDLED
}
public client_putinserver(id)
{
	if(!g_Ham_Bot && is_user_bot(id))
	{
		g_Ham_Bot = 1
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
}

public Do_RegisterHam_Bot(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_PlayerTraceAttack")
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return

	// Problem Here ?. SHUT THE FUCK UP
	if((read_data(2) == CSW_VULCANUS9 && g_Old_Weapon[id] != CSW_VULCANUS9) && g_had_vulcanus9[id])
	{
		set_pev(id, pev_viewmodel2, V_MODEL)
		set_pev(id, pev_weaponmodel2, P_MODEL)
	
		set_weapon_anim(id, g_on[id]?ANIM_DRAW:ANIM_OFF_DRAW)
		set_weapons_timeidle(id, CSW_VULCANUS9, 0.5)
		set_player_nextattack(id, 0.5)
		
		set_pdata_string(id, m_szAnimExtention * 4, WEAPON_ANIMEXT, -1 , 20)
		
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
		write_string(g_had_vulcanus9[id] == 1 ? weapon_vulcanus9 : "weapon_knife")
		write_byte(1)
		write_byte(100)
		write_byte(-1)
		write_byte(-1)
		write_byte(2)
		write_byte(1)
		write_byte(CSW_VULCANUS9)
		write_byte(0)
		message_end()
	}else{
		remove_burn_effect(id)
	}
		
	g_Old_Weapon[id] = read_data(2)
}

public fw_CheckVisibility(iEnt, pSet)
{
	static classname[64]; pev(iEnt, pev_classname, classname, sizeof(classname))
	if(equal(classname, "wpn_muzzleflash"))
	{
		forward_return(FMV_CELL, 1)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}
public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static id; id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(id, 373) != Ent)
		return
	if(!g_had_vulcanus9[id])
		return
	if(zp_get_user_zombie(id))
		return
	
	set_pev(id, pev_viewmodel2, V_MODEL)
	set_pev(id, pev_weaponmodel2, P_MODEL)

	set_weapon_anim(id, g_on[id]?ANIM_DRAW:ANIM_OFF_DRAW)
	set_weapons_timeidle(id, CSW_VULCANUS9, 0.5)
	set_player_nextattack(id, 0.5)
	
	set_pdata_string(id, m_szAnimExtention * 4, WEAPON_ANIMEXT, -1 , 20)
	emit_sound(id, CHAN_ITEM, WeaponSounds[g_on[id]?0:6], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	UpdateAmmo(id)

	if(g_FlameCharge[id]>0 && g_on[id] && !is_user_bot(id)){
		//Mirror error
		// MakeMuzzleFlash(id, 1, 0.1, "wpn_muzzleflash", muzzleflash)
		// MakeMuzzleFlash(id, 2, 0.1, "wpn_muzzleflash", muzzleflash)
		// MakeMuzzleFlash(id, 3, 0.1, "wpn_muzzleflash", muzzleflash)
		// MakeMuzzleFlash(id, 4, 0.1, "wpn_muzzleflash", muzzleflash)

		set_task(0.1, "burn_effect", id+TASK_BURN_EFFECT, _, _, "b")
	}
}

public fw_Item_Holster_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static id; id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(id, 373) != Ent)
		return
	if(!g_had_vulcanus9[id])
		return
	if(zp_get_user_zombie(id))
		return
	
	remove_burn_effect(id)
}

public remove_burn_effect(id){
	if(is_user_bot(id))
		return
		
	new a = FM_NULLENT
	while((a = fm_find_ent_by_class(id, "wpn_muzzleflash")) != 0)
	{
		if (!pev_valid(a))
			continue 
			
		static owner
		owner = pev(a, pev_owner)
		if(id == owner)
		{
			remove_entity(a)
		}
	}
	
	remove_task(id+TASK_BURN_EFFECT)
}

public fw_Item_Idle_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static id; id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(id, 373) != Ent)
		return
	if(!g_had_vulcanus9[id])
		return
	if(zp_get_user_zombie(id))
		return

	if(get_pdata_float(Ent, 48, 4) <= 0.1 && !g_on[id]) 
	{
		set_weapon_anim(id, ANIM_OFF_IDLE)
		set_pdata_float(Ent, 48, 161.0/30,OFFSET_LINUX_WEAPONS)
	}

	if(g_FlameCharge[id]<=0){
		remove_burn_effect(id)
	}
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED
	if(/*get_user_weapon(id) != CSW_VULCANUS9 || */!g_had_vulcanus9[id])
		return FMRES_IGNORED
		
	if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
			return FMRES_SUPERCEDE
		if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
		{
			if (sample[17] == 'w') // wall
			{
				g_Hit_Ing[id] = HIT_WALL
				return FMRES_SUPERCEDE
			} else {
				g_Hit_Ing[id] = HIT_ENEMY
				return FMRES_SUPERCEDE
			}
		}
		if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
			return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id)) 
		return
	if(get_user_weapon(id) != CSW_VULCANUS9 || !g_had_vulcanus9[id])
		return
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_VULCANUS9)
	
	if(!pev_valid(ent))
		return
	if(get_pdata_float(ent, 46, OFFSET_LINUX_WEAPONS) > 0.0 || get_pdata_float(ent, 47, OFFSET_LINUX_WEAPONS) > 0.0) 
		return
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if (CurButton & IN_ATTACK)
	{
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK)

		g_Attack_Mode[id] = ATTACK_SLASH
		g_Checking_Mode[id] = 1
		ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
		g_Checking_Mode[id] = 0

		Primary_Attack(id, g_on[id]?1:0)
	} else if (CurButton & IN_ATTACK2) {
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK2)
			
		set_pev(id, pev_framerate, 1.0)
		set_weapons_timeidle(id, CSW_VULCANUS9, 2.37)
		set_player_nextattack(id, 2.37)
		
		set_weapon_anim(id, g_on[id]?ANIM_OFF:ANIM_ON)

		remove_task(id+TASK_STABING)
		set_task(2.37, "Do_OnOff", id+TASK_STABING)
	}
}
public Primary_Attack(id, on)
{
	if(on){
		set_weapons_timeidle(id, CSW_VULCANUS9, 1.87)
		set_player_nextattack(id, 1.87)	
		set_weapon_anim(id, random_num(ANIM_MSLASH1, ANIM_MSLASH2))
		set_task(0.43, "Do_Slashing", id+TASK_SLASHING)
	}else{
		set_weapons_timeidle(id, CSW_VULCANUS9, 1.53)
		set_player_nextattack(id, 1.53)	
		set_weapon_anim(id, random_num(ANIM_OFF_SLASH1, ANIM_OFF_SLASH2))
		set_task(0.2, "Do_Slashing", id+TASK_SLASHING)
	}	
}
public Do_Slashing(id)
{
	id -= TASK_SLASHING
	
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_VULCANUS9 || !g_had_vulcanus9[id])
		return
		
	emit_sound(id, CHAN_ITEM, WeaponSounds[g_on[id]?random_num(7, 8):random_num(4, 5)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	if(Check_Attack(id, ATTACK_SLASH))
	{
		emit_sound(id, CHAN_ITEM, WeaponSounds[9], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	} else {
		if(g_Hit_Ing[id] == HIT_WALL)
		{
			emit_sound(id, CHAN_ITEM, WeaponSounds[12], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)	
		}
	}
	
	g_Attack_Mode[id] = 0
	g_Hit_Ing[id] = 0
}

public Do_OnOff(id)
{
	id -= TASK_STABING
		
	if (!is_user_alive(id)) 
		return
	if(get_user_weapon(id) != CSW_VULCANUS9 || !g_had_vulcanus9[id])
		return

	if(g_on[id]){
		g_on[id] = false
		remove_burn_effect(id)
	}else {
		g_on[id] = true
		if(g_FlameCharge[id]>0 && g_on[id] && !is_user_bot(id)){
			//Mirror error
			// MakeMuzzleFlash(id, 1, 0.1, "wpn_muzzleflash", muzzleflash)
			// MakeMuzzleFlash(id, 2, 0.1, "wpn_muzzleflash", muzzleflash)
			// MakeMuzzleFlash(id, 3, 0.1, "wpn_muzzleflash", muzzleflash)
			// MakeMuzzleFlash(id, 4, 0.1, "wpn_muzzleflash", muzzleflash)

			set_task(0.1, "burn_effect", id+TASK_BURN_EFFECT, _, _, "b")
		}
	}
}

public Check_Attack(id, Mode)
{
	static Float:Max_Distance, Float:Point[4][3], Float:TB_Distance, Float:Point_Dis
	
	if(Mode == ATTACK_SLASH)
	{
		Point_Dis = RADIUS_A/2
		Max_Distance = RADIUS_A
		TB_Distance = Max_Distance / 4.0
	}
	
	static Float:VicOrigin[3], Float:MyOrigin[3]
	pev(id, pev_origin, MyOrigin)
	
	for(new i = 0; i < 4; i++)
		get_position(id, TB_Distance * (i + 1), 0.0, 0.0, Point[i])
		
	static Have_Victim; Have_Victim = 0
	static ent
	ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
		
	if(!pev_valid(ent))
		return 0
		
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(id == i)
			continue
		if(entity_range(id, i) > Max_Distance)
			continue
	
		pev(i, pev_origin, VicOrigin)
		if(is_wall_between_points(MyOrigin, VicOrigin, id))
			continue
			
		if(get_distance_f(VicOrigin, Point[0]) <= Point_Dis
		|| get_distance_f(VicOrigin, Point[1]) <= Point_Dis
		|| get_distance_f(VicOrigin, Point[2]) <= Point_Dis
		|| get_distance_f(VicOrigin, Point[3]) <= Point_Dis)
		{
			if(!Have_Victim) Have_Victim = 1
			if(!zp_get_user_zombie(i))
				continue
			static Float:vecViewAngle[3]; pev(id, pev_v_angle, vecViewAngle);
			static Float:vecForward[3]; angle_vector(vecViewAngle, ANGLEVECTOR_FORWARD, vecForward);
			if(Mode == ATTACK_SLASH){
				new Float:FinalDamage;FinalDamage = DAMAGE_A

				if(g_on[id])
					if(g_FlameCharge[id]>0){
						FinalDamage *= 2
						Make_BurnFire(i, id)
					}
					else
						FinalDamage *= 1.5

				do_attack(id, i, ent, random_float(FinalDamage-10.0,FinalDamage+10.0))
			}
			make_blood(VicOrigin)				
		}	
	}	
	
	if(Have_Victim)
		return 1
	else
		return 0
	
	return 0
}	
public client_PostThink(id){
	if(!is_user_connected(id))
		return 	
	if(!g_had_vulcanus9[id])
		return 
	
	static Wpn; Wpn = get_pdata_cbase(id, 373)
	if(!pev_valid(Wpn)) return
	
	static Float:flLastCheckTime
	pev(Wpn, pev_fuser2, flLastCheckTime)
	
	if(!g_on[id] && flLastCheckTime < get_gametime())
	{		
		if(g_FlameCharge[id] < 10)
		{
			g_FlameCharge[id]++
			
			if(get_user_weapon(id) == CSW_VULCANUS9)
			{
				UpdateAmmo(id)
				
				if(g_FlameCharge[id] == 10)
				{
					set_pev(Wpn, pev_fuser2, get_gametime() + 1.5)
					return
				}
			}
			
			set_pev(Wpn, pev_fuser2, get_gametime() + 1.5)
		}
	}
	
	if(g_on[id] && flLastCheckTime < get_gametime())
	{
		if(g_FlameCharge[id] > 0) g_FlameCharge[id]--
		else g_FlameCharge[id] = 0
		
		if(get_user_weapon(id) == CSW_VULCANUS9)
			UpdateAmmo(id)
		 
		set_pev(Wpn, pev_fuser2, get_gametime() + 1.0)	
	}
}
public HamHook_Spr_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Classname[32]
	pev(ent, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, "wpn_muzzleflash"))
	{
		static Float:fFrame, Float:fFrameMax
		pev(ent, pev_frame, fFrame)

		static Float:Originf[3]
		pev(ent, pev_origin, Originf)
		//client_print(0, print_chat, "%f; %f; %f", Originf[0],Originf[1],Originf[2])
		Originf[0] *= -1.0
		Originf[1] *= -1.0
		Originf[2] *= -1.0
		//client_print(0, print_chat, "%f; %f; %f__", Originf[0],Originf[1],Originf[2])
		set_pev(ent, pev_origin, Originf)
		
		fFrameMax = 15.0
		
		fFrame += 0.5
		if(fFrame >= fFrameMax) 
		{
			fFrame = 0.0;
			//set_pev(ent, pev_flags, FL_KILLME)
		}
		set_pev(ent, pev_frame, fFrame)
		
		set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW) 
		
		set_pev(ent, pev_nextthink, get_gametime() + 0.01)
	}
}
public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED	
	if (get_user_weapon(id) != CSW_VULCANUS9 || !g_had_vulcanus9[id])
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)

	if(g_Attack_Mode[id] == ATTACK_SLASH) xs_vec_mul_scalar(v_forward, RADIUS_A, v_forward)
	else xs_vec_mul_scalar(v_forward, 0.0, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, ignored_monster, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Classname[32]; pev(ent, pev_classname, Classname, sizeof(Classname))
	if(!equal(Classname, BURN_DAMAGE_CLASSNAME))
		return
	
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id)){
		engfunc(EngFunc_RemoveEntity, ent)
		return
	}

	static Float:fFrame, Float:fFrameMax
	pev(ent, pev_frame, fFrame)

	fFrameMax = 8.0
	fFrame += 1.0

	if(fFrame >= fFrameMax) 
	{
		fFrame = 0.0;
	}
	set_pev(ent, pev_frame, fFrame)

	static attacker; attacker = pev(ent, pev_iuser2)
	if(get_gametime() - BURNDELAY > pev(ent, pev_fuser2))
	{
		ExecuteHamB(Ham_TakeDamage, id, attacker, attacker, BURNDAMAGE, DMG_BURN)
		set_pev(ent, pev_fuser2, get_gametime())
	}
	
	static Float:fTimeRemove
	pev(ent, pev_fuser1, fTimeRemove)
	if (get_gametime() >= fTimeRemove)
	{
		engfunc(EngFunc_RemoveEntity, ent)
		return;
	}	
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}
public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED	
	if (get_user_weapon(id) != CSW_VULCANUS9 || !g_had_vulcanus9[id])
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)
	
	if(g_Attack_Mode[id] == ATTACK_SLASH) xs_vec_mul_scalar(v_forward, RADIUS_A, v_forward)
	else xs_vec_mul_scalar(v_forward, 0.0, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceHull, vecStart, vecEnd, ignored_monster, hull, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_PlayerTraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], TraceResult, DamageBits) 
{
	if(!is_user_alive(Attacker))	
		return HAM_IGNORED
	if(!g_had_vulcanus9[Attacker] || !g_Checking_Mode[Attacker])
		return HAM_IGNORED
		
	return HAM_SUPERCEDE
}

do_attack(Attacker, Victim, Inflictor, Float:fDamage)
{
	fake_player_trace_attack(Attacker, Victim, fDamage)
	fake_take_damage(Attacker, Victim, fDamage, Inflictor)
}

fake_player_trace_attack(iAttacker, iVictim, &Float:fDamage)
{
	// get fDirection
	new Float:fAngles[3], Float:fDirection[3]
	pev(iAttacker, pev_angles, fAngles)
	angle_vector(fAngles, ANGLEVECTOR_FORWARD, fDirection)
	
	// get fStart
	new Float:fStart[3], Float:fViewOfs[3]
	pev(iAttacker, pev_origin, fStart)
	pev(iAttacker, pev_view_ofs, fViewOfs)
	xs_vec_add(fViewOfs, fStart, fStart)
	
	// get aimOrigin
	new iAimOrigin[3], Float:fAimOrigin[3]
	get_user_origin(iAttacker, iAimOrigin, 3)
	IVecFVec(iAimOrigin, fAimOrigin)
	
	// TraceLine from fStart to AimOrigin
	new ptr = create_tr2() 
	engfunc(EngFunc_TraceLine, fStart, fAimOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr)
	new pHit = get_tr2(ptr, TR_pHit)
	new iHitgroup = get_tr2(ptr, TR_iHitgroup)
	new Float:fEndPos[3]
	get_tr2(ptr, TR_vecEndPos, fEndPos)

	// get target & body at aiming
	new iTarget, iBody
	get_user_aiming(iAttacker, iTarget, iBody)
	
	// if aiming find target is iVictim then update iHitgroup
	if (iTarget == iVictim)
	{
		iHitgroup = iBody
	}
	
	// if ptr find target not is iVictim
	else if (pHit != iVictim)
	{
		// get AimOrigin in iVictim
		new Float:fVicOrigin[3], Float:fVicViewOfs[3], Float:fAimInVictim[3]
		pev(iVictim, pev_origin, fVicOrigin)
		pev(iVictim, pev_view_ofs, fVicViewOfs) 
		xs_vec_add(fVicViewOfs, fVicOrigin, fAimInVictim)
		fAimInVictim[2] = fStart[2]
		fAimInVictim[2] += get_distance_f(fStart, fAimInVictim) * floattan( fAngles[0] * 2.0, degrees )
		
		// check aim in size of iVictim
		new iAngleToVictim = get_angle_to_target(iAttacker, fVicOrigin)
		iAngleToVictim = abs(iAngleToVictim)
		new Float:fDis = 2.0 * get_distance_f(fStart, fAimInVictim) * floatsin( float(iAngleToVictim) * 0.5, degrees )
		new Float:fVicSize[3]
		pev(iVictim, pev_size , fVicSize)
		if ( fDis <= fVicSize[0] * 0.5 )
		{
			// TraceLine from fStart to aimOrigin in iVictim
			new ptr2 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fAimInVictim, DONT_IGNORE_MONSTERS, iAttacker, ptr2)
			new pHit2 = get_tr2(ptr2, TR_pHit)
			new iHitgroup2 = get_tr2(ptr2, TR_iHitgroup)
			
			// if ptr2 find target is iVictim
			if ( pHit2 == iVictim && (iHitgroup2 != HIT_HEAD || fDis <= fVicSize[0] * 0.25) )
			{
				pHit = iVictim
				iHitgroup = iHitgroup2
				get_tr2(ptr2, TR_vecEndPos, fEndPos)
			}
			
			free_tr2(ptr2)
		}
		
		// if pHit still not is iVictim then set default HitGroup
		if (pHit != iVictim)
		{
			// set default iHitgroup
			iHitgroup = HIT_GENERIC
			
			new ptr3 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fVicOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr3)
			get_tr2(ptr3, TR_vecEndPos, fEndPos)
			
			// free ptr3
			free_tr2(ptr3)
		}
	}
	
	// set new Hit & Hitgroup & EndPos
	set_tr2(ptr, TR_pHit, iVictim)
	set_tr2(ptr, TR_iHitgroup, iHitgroup)
	set_tr2(ptr, TR_vecEndPos, fEndPos)
	
	// hitgroup multi fDamage
	new Float:fMultifDamage 
	switch(iHitgroup)
	{
		case HIT_HEAD: fMultifDamage  = 2.0
		case HIT_CHEST: fMultifDamage  = 1.5
		case HIT_STOMACH: fMultifDamage  = 1.4
		case HIT_LEFTLEG: fMultifDamage  = 0.85
		case HIT_RIGHTLEG: fMultifDamage  = 0.85
		default: fMultifDamage  = 1.0
	}
	
	fDamage *= fMultifDamage
	
	// ExecuteHam
	fake_trake_attack(iAttacker, iVictim, fDamage, fDirection, ptr)
	
	// free ptr
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
	get_user_origin(id, iAimOrigin, 3) // end position from eyes
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

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
		
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
	message_end()	
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entwpn, 47, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, OFFSET_LINUX_WEAPONS)
}

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
}

stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
	

stock is_wall_between_points(Float:start[3], Float:end[3], ignore_ent)
{
	static ptr
	ptr = create_tr2()

	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	free_tr2(ptr)
	return floatround(get_distance_f(end, EndPos))
} 

stock FakeKnockBack(iPlayer, Float: vecDirection[3], Float:flKnockBack)
{
	static Float:vecVelocity[3]; pev(iPlayer, pev_velocity, vecVelocity);
	
	if (pev(iPlayer, pev_flags) & FL_DUCKING)
	{
		flKnockBack *= 0.7;
	}
	
	vecVelocity[0] = vecDirection[0] * 500.0 * flKnockBack;
	vecVelocity[1] = vecDirection[1] * 500.0 * flKnockBack;
	vecVelocity[2] = 400.0;
	
	set_pev(iPlayer, pev_velocity, vecVelocity);
}
stock make_blood(Float:origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]+random_num(15,25)))
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(248)
	write_byte(random_num(8,15))
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]+random_num(15,25)))
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(248)
	write_byte(random_num(8,15))
	message_end()
}

public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(get_user_weapon(iAttacker) == CSW_VULCANUS9)
	{
		if(g_had_vulcanus9[iAttacker])
			set_msg_arg_string(4, "vulcanus9")
	}
                
	return PLUGIN_CONTINUE
}

public MakeMuzzleFlash(id, iBody, Float:iSize, szclassname[], cache_muf[])//Thx Asdian DX
{
	if(is_user_bot(id)) return;
	static iMuz
	iMuz = Stock_CreateEntityBase(id, "env_sprite", MOVETYPE_FOLLOW, cache_muf, szclassname, SOLID_NOT,0.01)
	set_pev(iMuz, pev_body, iBody)
	set_pev(iMuz, pev_owner, id)
	set_pev(iMuz, pev_rendermode, kRenderTransAdd)
	set_pev(iMuz, pev_renderamt, 255.0)
	set_pev(iMuz, pev_aiment, id)
	set_pev(iMuz, pev_scale, iSize)
	set_pev(iMuz, pev_frame, 0.0)
	dllfunc(DLLFunc_Spawn, iMuz)
}

stock Stock_CreateEntityBase(id, classtype[], mvtyp, mdl[], class[], solid, Float:fNext)
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classtype))
	set_pev(pEntity, pev_movetype, mvtyp);
	set_pev(pEntity, pev_owner, id);
	engfunc(EngFunc_SetModel, pEntity, mdl);
	set_pev(pEntity, pev_classname, class);
	set_pev(pEntity, pev_solid, solid);
	set_pev(pEntity, pev_nextthink, get_gametime() + fNext)
	return pEntity
}

stock UpdateAmmo(id)
{
	if(!is_user_alive(id))
		return

	static weapon_ent; weapon_ent = fm_get_user_weapon_entity(id, CSW_VULCANUS9)
	if(!pev_valid(weapon_ent)) return
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_VULCANUS9)
	write_byte(-1)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(1)
	write_byte(g_FlameCharge[id])
	message_end()
}

public Make_BurnFire(id, attacker)
{
	static Ent; Ent = fm_find_ent_by_owner(-1, BURN_DAMAGE_CLASSNAME, id)
	if(!pev_valid(Ent))
	{
		static iEnt; iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
		static Float:MyOrigin[3]
		
		pev(id, pev_origin, MyOrigin)
		
		// set info for ent
		set_pev(iEnt, pev_movetype, MOVETYPE_FOLLOW)
		set_pev(iEnt, pev_rendermode, kRenderTransAdd)
		set_pev(iEnt, pev_renderamt, 250.0)
		set_pev(iEnt, pev_iuser2, attacker)
		set_pev(iEnt, pev_fuser1, get_gametime() + BURNTIME)
		set_pev(iEnt, pev_scale, 0.6)
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)
		
		set_pev(iEnt, pev_classname, BURN_DAMAGE_CLASSNAME)
		engfunc(EngFunc_SetModel, iEnt, g_flameBurnSpr)
		set_pev(iEnt, pev_owner, id)
		set_pev(iEnt, pev_aiment, id)
	}	
}
public burn_effect(taskid)
{
	// Not nemesis, not in zombie madness
	if (!is_user_alive(ID_BURN_EFFECT))
	{
		// Task not needed anymore
		remove_task(taskid);
		return;
	}
	
	// Get player's origin
	static origin[3]
	get_user_origin(ID_BURN_EFFECT, origin)
	
	// Colored Aura
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, destoriginF, 0)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(10) // radius
	write_byte(226) // r
	write_byte(88) // g
	write_byte(34) // b
	write_byte(3) // life
	write_byte(0) // decay rate
	message_end()

	// Add a blue tint to their screen
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, ID_BURN_EFFECT)
	write_short((1<<12))
	write_short(0)
	write_short(0x0000)
	write_byte(226) // red
	write_byte(88) // green
	write_byte(34) // blue
	write_byte(50) // alpha
	message_end()

	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Damage"), _, ID_BURN_EFFECT)
	write_byte(0) // damage save
	write_byte(0) // damage take
	write_long(DMG_BURN) // damage type
	write_coord(0) // x
	write_coord(0) // y
	write_coord(0) // z
	message_end()

	new TE_FLAG
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, origin[0]+random_float(-10.0, 10.0))
	engfunc(EngFunc_WriteCoord, origin[1]+random_float(-10.0, 10.0))
	engfunc(EngFunc_WriteCoord, origin[2]+random_float(-20.0, -10.0))
	write_short(g_flameSpr)	// sprite index
	write_byte(5)	// scale in 0.1's
	write_byte(20)	// framerate
	write_byte(TE_FLAG)	// flags
	message_end()
}