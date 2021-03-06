#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <xs>
#include <zombieplague>

#define PLUGIN "[ZP] Extra Item: Dragon Sword"
#define VERSION "2.0"
#define AUTHOR "Dias Leon"

#define v_model "models/v_dualsword_ys.mdl"
#define p_model "models/p_dualsword_a_ys.mdl"
#define spr_wpn	"knife_dualsword"

#define DAMAGE_A 30 // 200 for Zombie
#define DAMAGE_B 30 // 400 for Zombie

#define RADIUS_A 100.0
#define RADIUS_B 100.0

#define CSW_YASUO CSW_KNIFE
#define weapon_yasuo "weapon_knife"
#define WEAPON_ANIMEXT "knife" //"skullaxe"

#define TASK_STABING 2033+10
#define TASK_SLASHING 2033+20
#define TASK_DONE 2033+30
#define TASK_ULTI 2033+40
#define TASK_ONAIR 2033+50

// OFFSET
const PDATA_SAFE = 2
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_WEAPONOWNER = 41
const m_flNextAttack = 83
const m_szAnimExtention = 492

#define tornado "models/ef_Q3.mdl"
#define ATTACHMENT_CLASSNAME	"ent_tornado"

new const WeaponSounds[][] =
{
	"weapons/dualsword_stab1.wav",				// 0
	"weapons/dualsword_stab2.wav",				// 1
	"weapons/dualsword_stab1_hit.wav",			// 2
	"weapons/dualsword_stab2_hit.wav",			// 3
	"weapons/katanad_hitwall.wav",				// 4
	
	"weapons/dualsword_slash_1.wav",			// 5
	"weapons/dualsword_slash_2.wav",			// 6
	"weapons/dualsword_slash_3.wav",			// 7
	"weapons/dualsword_slash_4.wav",			// 8
	"weapons/dualsword_hit1.wav",				// 9
	"weapons/dualsword_hit2.wav",				// 10
	"weapons/dualsword_hit3.wav",				// 11
	"weapons/dualsword_slash_4_1.wav",			// 12
	"weapons/dualsword_slash_4_2.wav",			// 13
	"weapons/dualsword_skill_end.wav",			// 14
	
	"weapons/dualsword_fly1.wav",				// 15
	"weapons/dualsword_fly2.wav",				// 16
	"weapons/dualsword_fly3.wav",				// 17
	"weapons/dualsword_fly4.wav",				// 18
	"weapons/dualsword_fly5.wav",				// 19
	"weapons/dualsword_skill_start.wav",
	
	"weapons/YasuoW1.wav",
	"weapons/YasuoW2.wav",
	"weapons/YasuoW3.wav",
	"weapons/YasuoW4.wav",
	"weapons/YasuoR1.wav",
	"weapons/YasuoR2.wav",
	"weapons/YasuoR3.wav"
}

enum _:WpnAnim
{
	ANIM_IDLEA = 0,
	ANIM_SLASH1,
	ANIM_SLASH2,
	ANIM_SLASH3,
	ANIM_SLASH4,
	ANIM_SLASHEND,
	ANIM_DRAWA,
	ANIM_IDLEB,
	ANIM_STAB1,
	ANIM_STAB2,
	ANIM_STABEND,
	ANIM_DRAWB
}
enum
{
	ATTACK_SLASH= 1,
	ATTACK_STAB,
	ATTACK_ULTI
}

enum
{
	HIT_NOTHING = 0,
	HIT_ENEMY,
	HIT_WALL
}

new g_Had_Yasuo[33], g_isattacking[33], g_Attack_Mode[33], g_Checking_Mode[33], g_Hit_Ing[33]
new g_Old_Weapon[33], g_Ham_Bot,m_iBlood[2], g_is_ulti[33]
new g_count[33], g_Line ,g_wpn[33]
new Float:g_lastpost[33][2][3], g_Target[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	//register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_TraceLine, "fw_TraceLine",1)
	register_forward(FM_TraceHull, "fw_TraceHull")
	register_forward(FM_AddToFullPack, "Fw_AddToFullPack_Post", 1);

	register_think("dps_entytyd", "Fw_DPSEnt_Think")
	
	register_think(ATTACHMENT_CLASSNAME, "fw_Tornado_Think")
	
	RegisterHam(Ham_Spawn, "player", "fw_Player_Spawn", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_PlayerTraceAttack")
	RegisterHam(Ham_Item_Deploy, weapon_yasuo, "fw_Item_Deploy_Post", 1)
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	register_clcmd("say /y", "get_jaydagger")
	register_clcmd("say /t1","BotTest1")
	register_clcmd("say /t2","BotTest2")
}
public BotTest1()
{
	emit_sound(2, CHAN_VOICE, WeaponSounds[random_num(23,24)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	set_task(0.1, "Do_TornadoNow", 2+TASK_STABING)
}
public BotTest2()
{
	pev(2, pev_origin, g_lastpost[2][0])	
	pev(2, pev_angles, g_lastpost[2][1])	
	set_task(0.1, "Ulti_Attack", 2)
}
public plugin_natives()
{
	register_native("jaydagger", "get_jaydagger", 1)
}
public plugin_precache()
{
	precache_model(v_model)
	precache_model(p_model)	
	precache_model(tornado)	
	precache_model("models/dualsword_ys_fx.mdl")	
	
	for(new i = 0; i < sizeof(WeaponSounds); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
	g_Line = precache_model("sprites/zbeam4.spr")
	m_iBlood[0] = precache_model("sprites/blood.spr");
	m_iBlood[1] = precache_model("sprites/bloodspray.spr");	
}

public zp_user_infected_post(id) remove_jaydagger(id)
public fw_Player_Spawn(id) get_jaydagger(id)
public get_jaydagger(id)
{
	remove_task(id+TASK_SLASHING)
	remove_task(id+TASK_STABING)
		
	g_Had_Yasuo[id] = 1
	g_Attack_Mode[id] = 0
	g_isattacking[id] = 0
	g_Checking_Mode[id] = 0
	g_Hit_Ing[id] = 0
	//fm_give_item(id, "weapon_knife")
}

public remove_jaydagger(id)
{
	remove_task(id+TASK_SLASHING)
	remove_task(id+TASK_STABING)
	remove_task(id+TASK_DONE)
	remove_task(id+TASK_ULTI)
	remove_task(id+TASK_ONAIR)
		
	g_Had_Yasuo[id] = 0
	g_Attack_Mode[id] = 0
	g_isattacking[id] = 0
	g_Checking_Mode[id] = 0
	g_Hit_Ing[id] = 0
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
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Player_Spawn", 1)
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return

	// Problem Here ?. SHUT THE FUCK UP
	if((read_data(2) == CSW_YASUO && g_Old_Weapon[id] != CSW_YASUO) && g_Had_Yasuo[id])
	{
		set_pev(id, pev_viewmodel2, v_model)
		set_pev(id, pev_weaponmodel2, p_model)
	
		set_weapon_anim(id, ANIM_DRAWA)
		set_weapons_timeidle(id, CSW_YASUO, 0.5)
		set_player_nextattack(id, 0.5)
		
		set_pdata_string(id, m_szAnimExtention * 4, WEAPON_ANIMEXT, -1 , 20)
	}
		
	g_Old_Weapon[id] = read_data(2)
}

public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!g_Had_Yasuo[Id])
		return
	if(zp_get_user_zombie(Id))
		return
	
	set_pev(Id, pev_viewmodel2, v_model)
	set_pev(Id, pev_weaponmodel2, p_model)

	set_weapon_anim(Id, ANIM_DRAWA)
	set_weapons_timeidle(Id, CSW_YASUO, 0.5)
	set_player_nextattack(Id, 0.5)
	g_wpn[Id] = Ent
	set_pdata_string(Id, m_szAnimExtention * 4, WEAPON_ANIMEXT, -1 , 20)
	emit_sound(Id, CHAN_ITEM, WeaponSounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED
	if(/*get_user_weapon(id) != CSW_YASUO || */!g_Had_Yasuo[id])
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
	if(get_user_weapon(id) != CSW_YASUO || !g_Had_Yasuo[id] || zp_get_user_zombie(id))
		return
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_YASUO)
	
	if(!pev_valid(ent))
		return
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	if (CurButton & IN_RELOAD && !g_is_ulti[id] && is_user_alive(g_Target[id]))
	{
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_RELOAD)	
		
		g_Attack_Mode[id] = ATTACK_ULTI
		g_Checking_Mode[id] = 1
		ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
		g_Checking_Mode[id] = 0
		pev(id, pev_origin, g_lastpost[id][0])	
		pev(id, pev_angles, g_lastpost[id][1])	
		g_isattacking[id] = 1
		set_task(0.1, "Ulti_Attack", id)
	}	
	
	if(get_pdata_float(ent, 46, OFFSET_LINUX_WEAPONS) > 0.0 || get_pdata_float(ent, 47, OFFSET_LINUX_WEAPONS) > 0.0 ) 
		return
		
	if (CurButton & IN_ATTACK)
	{
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK)

		g_Attack_Mode[id] = ATTACK_SLASH
		g_Checking_Mode[id] = 1
		ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
		g_Checking_Mode[id] = 0
		
		g_isattacking[id] = 1
	
		static num;num=random_num(ANIM_SLASH1,ANIM_SLASH4)
		set_weapon_anim(id, num)
		Create_Slash(id,g_wpn[id],num-1,1)		
		
		if(task_exists(id+TASK_DONE)) remove_task(id+TASK_DONE)
		set_task(0.55,"DoneAttack",id+TASK_DONE)	
		
		set_task(0.1, "Do_Slashing", id+TASK_SLASHING)	
		
		set_weapons_timeidle(id, CSW_YASUO, 0.5)
		set_player_nextattack(id, 0.5)		
		
	} else if (CurButton & IN_ATTACK2 && !g_isattacking[id]) {
		
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK2)
		
		g_Attack_Mode[id] = ATTACK_STAB
		g_Checking_Mode[id] = 1
		ExecuteHamB(Ham_Weapon_SecondaryAttack, ent)
		g_Checking_Mode[id] = 0
		if(g_count[id]<2)
		{						
			set_pev(id, pev_framerate, 1.5)
			set_weapons_timeidle(id, CSW_YASUO, 1.0)
			set_player_nextattack(id, 1.0)
			
			set_weapon_anim(id, ANIM_STAB1)
			
			//remove_task(id+TASK_STABING)
			set_task(0.2, "Do_StabNow", id+TASK_STABING)
		}else{
			set_weapons_timeidle(id, CSW_YASUO, 0.5)
			set_player_nextattack(id, 0.5)
			set_weapon_anim(id, random_num(ANIM_SLASH1,ANIM_SLASH4))
			
			//remove_task(id+TASK_STABING)
			emit_sound(id, CHAN_VOICE, WeaponSounds[random_num(23,24)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			set_task(0.1, "Do_TornadoNow", id+TASK_STABING)
			g_count[id] = 0
		}
	
		g_isattacking[id] = 1
		if(task_exists(id+TASK_DONE)) remove_task(id+TASK_DONE)
		set_task(0.4,"DoneAttack",id+TASK_DONE)
	}
}
public Ulti_Attack(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id))
	{	
		set_task(0.1, "Done_Ulti", id)	
		return	
	}
	if(get_user_weapon(id) != CSW_YASUO || !g_Had_Yasuo[id] || !is_user_alive(g_Target[id]))
	{
		set_task(0.1, "Done_Ulti", id)	
		return	
	}
	if(pev(g_Target[id], pev_flags) & FL_ONGROUND)
	{
		g_Target[id] = 0
		set_task(0.1, "Done_Ulti", id)	
		return	
	}
	
	g_is_ulti[id] = true
	
	set_pev(id, pev_takedamage, DAMAGE_NO)
	set_task(0.2, "Do_Damge", id+TASK_ONAIR, _, _, "b")
	set_task(0.1, "MakeSlash", id+TASK_SLASHING, _, _, "b")
	set_task(0.4, "MakeSound", id)	
	set_task(2.0, "Done_Ulti", id)
}
public MakeSlash(id)
{
	id-=TASK_SLASHING
	static num;num=random_num(ANIM_SLASH1,ANIM_SLASH4)
	set_weapon_anim(id, num)
	Create_Slash(id,g_wpn[id],num-1,0)
	Create_Slash(id,g_wpn[id],random_num(0,3),0)
	emit_sound(id, CHAN_ITEM, WeaponSounds[random_num(9, 11)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}
public MakeSound(id) emit_sound(id, CHAN_VOICE, WeaponSounds[random_num(25,27)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
public Do_Damge(id)
{
	id-=TASK_ONAIR
	
	if(!is_user_alive(g_Target[id]) || !zp_get_user_zombie(g_Target[id]) || zp_get_user_zombie(id))
	{
		Done_Ulti(id)
		return
	}
	static a,Float:Origin[3],Float:VicOrigin[3]
	
	pev(id, pev_origin, Origin)
	pev(g_Target[id], pev_origin, VicOrigin)
	
	VicOrigin[0] += 50.0 * (random_num(0,1)?-1.0:1.0)
	VicOrigin[1] += 50.0 * (random_num(0,1)?-1.0:1.0)
	VicOrigin[2] += 50.0 * (random_num(0,1)?-1.0:1.0)
	set_pev(id, pev_origin, VicOrigin)
	
	pev(g_Target[id], pev_origin, VicOrigin)
	entity_set_aim(id, VicOrigin, 8)
	
	while((a = find_ent_in_sphere(a, Origin, 200.0)) != 0)
	{
		if(!is_user_alive(a) || !zp_get_user_zombie(a))
			continue
			
		//g_Target[id] = a
		
		set_pev(a, pev_velocity, {0.0, 0.0, 90.0})
		set_pev(id, pev_velocity, {0.0, 0.0, 130.0})
		
		if(a==id) continue
		pev(a, pev_origin, VicOrigin)
		make_blood(VicOrigin)
		do_attack(id, a, id, 2.0*float(random_num(DAMAGE_B-10,DAMAGE_B+10)))
	}
}
public Done_Ulti(id)
{
	set_pev(id, pev_takedamage, DAMAGE_YES)
	g_is_ulti[id] = false
	
	remove_task(id+TASK_ONAIR+70)
	remove_task(id+TASK_SLASHING)
	for(new i=0; i<get_maxplayers();i++)
	{	
		remove_task(i+TASK_ONAIR)
	}
	set_pev(id, pev_origin, g_lastpost[id][0])	
	set_pev(id, pev_angles, g_lastpost[id][1])	
	set_pev(id, pev_v_angle, g_lastpost[id][1])
	
	if(task_exists(id+TASK_DONE)) remove_task(id+TASK_DONE)
	set_task(0.1,"DoneAttack",id+TASK_DONE)
}
public Do_Slashing(id)
{
	id -= TASK_SLASHING
	
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_YASUO || !g_Had_Yasuo[id])
		return
		
	if(Check_Attack(id, ATTACK_SLASH))
	{
		emit_sound(id, CHAN_ITEM, WeaponSounds[random_num(9, 11)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	} else {
		if(g_Hit_Ing[id] == HIT_WALL)
		{
			emit_sound(id, CHAN_ITEM, WeaponSounds[4], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)	
		}
		else if(g_Hit_Ing[id] == HIT_NOTHING) emit_sound(id, CHAN_WEAPON, WeaponSounds[random_num(5,8)], ATTN_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
	g_Attack_Mode[id] = 0
	g_Hit_Ing[id] = 0
}
public DoneAttack(id)
{
	id-=TASK_DONE
	
	//g_isattacking[id] = 1
	set_weapon_anim(id, ANIM_SLASHEND)
	set_player_nextattack(id, 2.03)
	set_weapons_timeidle(id, CSW_YASUO, 2.03)
	set_task(2.0, "DoneAttack2", id+TASK_DONE+1)
}
public DoneAttack2(id)
{
	id-=TASK_DONE+1
	g_isattacking[id] = 0	
}
public Do_StabNow(id)
{
	id -= TASK_STABING
	
	if (!is_user_alive(id)) 
		return
	if(get_user_weapon(id) != CSW_YASUO || !g_Had_Yasuo[id])
		return

	emit_sound(id, CHAN_VOICE, WeaponSounds[random_num(21,22)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	if(Check_Attack(id, ATTACK_STAB))
	{
		emit_sound(id, CHAN_ITEM, WeaponSounds[random_num(2, 3)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		g_count[id]++
	} else {
		if(g_Hit_Ing[id] == HIT_WALL)
		{
			emit_sound(id, CHAN_ITEM, WeaponSounds[4], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)	
		}
		else if(g_Hit_Ing[id] == HIT_NOTHING) emit_sound(id, CHAN_WEAPON, WeaponSounds[random_num(0,1)], ATTN_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
	
	g_Attack_Mode[id] = 0
	g_Hit_Ing[id] = 0
}

public Do_TornadoNow(id)
{
	id -= TASK_STABING
	
	if (!is_user_alive(id)) 
		return
	if(get_user_weapon(id) != CSW_YASUO || !g_Had_Yasuo[id])
		return
		
	CreateTorndo(id)

	g_Attack_Mode[id] = 0
	g_Hit_Ing[id] = 0
}
public CreateTorndo(id)
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Ent)) return

	new Float:StartOrigin[3],Float:TargetOrigin[3];	
	get_position(id, 10.0, 0.0, -8.0, StartOrigin)
	get_position(id, 1500.0, 0.0, -8.0, TargetOrigin)
	
	// Set info for ent
	set_pev(Ent, pev_movetype, MOVETYPE_NOCLIP)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 255.0)
	set_pev(Ent, pev_owner, id)
	
	entity_set_string(Ent, EV_SZ_classname, ATTACHMENT_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, tornado)
	set_pev(Ent, pev_maxs, Float:{15.0, 15.0, 50.5})
	set_pev(Ent, pev_mins, Float:{-15.0, -15.0, -1.5})
	set_pev(Ent, pev_origin, StartOrigin)
	set_pev(Ent, pev_gravity, 0.01)
	set_pev(Ent, pev_scale, 5)
	set_pev(Ent, pev_owner, id)
	set_pev(Ent, pev_solid, SOLID_NOT)
	set_pev(Ent, pev_fuser1, get_gametime())
	
	static Float:Velocity[3]
	pev(id, pev_origin, StartOrigin)
	TargetOrigin[2] = StartOrigin[2]
	Get_Speed_Vector(StartOrigin, TargetOrigin, 700.0, Velocity)
	set_pev(Ent, pev_velocity, Velocity)	
	
	// Animation
	set_pev(Ent, pev_animtime, get_gametime())
	set_pev(Ent, pev_framerate, 2.0)
	set_pev(Ent, pev_sequence, 0)
	
	set_pev(Ent, pev_nextthink, halflife_time() + 0.1)	
}
public fw_Tornado_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return

	engfunc(EngFunc_DropToFloor, iEnt)
		
	new pevAttacker = pev(iEnt, pev_owner);
	if(!is_user_connected(pevAttacker) || !is_user_alive(pevAttacker) || !g_Had_Yasuo[pevAttacker] || pev(iEnt, pev_fuser1) + 3.0 < get_gametime())
	{
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
		return
	}
	if(!pev_valid(iEnt)) return;
	if(pev(iEnt, pev_flags) & FL_KILLME) return;
	
	static a, Float:Origin[3], Float:VicOrigin[3];
	pev(iEnt, pev_origin, Origin)
	
	while((a = find_ent_in_sphere(a, Origin, 100.0)) != 0)
	{
		if(a==iEnt) continue
		if(a==pevAttacker) continue		
		set_pev(a, pev_velocity, {0.0, 0.0, 400.0})
		
		if(!is_user_alive(a) || !zp_get_user_zombie(a))
			continue
		pev(a, pev_origin, VicOrigin)
		do_attack(pevAttacker, a, pevAttacker, float(random_num(DAMAGE_B-10,DAMAGE_B+10)))
		make_blood(VicOrigin)
		
		if(g_is_ulti[pevAttacker])
			continue
			
		g_Target[pevAttacker] = a
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(8)
		write_short(pevAttacker)
		write_short(a)
		write_short(g_Line)
		write_byte(0)
		write_byte(0)
		write_byte(10)
		write_byte(8)
		write_byte(1)
		write_byte(0)
		write_byte(255)
		write_byte(255)
		write_byte(90)
		write_byte(10)
		message_end()
	}
	set_pev(iEnt, pev_nextthink, halflife_time() + 0.1)	
}
public beam_remove(id)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(99)
	write_short(id)
	message_end()
}
public Check_Attack(id, Mode)
{
	static Float:Max_Distance, Float:Point[4][3], Float:TB_Distance, Float:Point_Dis
	
	if(Mode == ATTACK_SLASH)
	{
		Point_Dis = RADIUS_A/2
		Max_Distance = RADIUS_A
		TB_Distance = Max_Distance / 4.0
	} else if(Mode == ATTACK_STAB) {
		Point_Dis = RADIUS_B/2
		Max_Distance = RADIUS_B
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
			if(Mode == ATTACK_SLASH)		
				do_attack(id, i, ent, float(random_num(DAMAGE_A-10,DAMAGE_A+10)))
			else if(Mode == ATTACK_STAB)
			{
				FakeKnockBack(i, vecForward, 0.5);
				do_attack(id, i, ent, float(random_num(DAMAGE_B-10,DAMAGE_B+10)))
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

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED	
	if (get_user_weapon(id) != CSW_YASUO || !g_Had_Yasuo[id])
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)

	if(g_Attack_Mode[id] == ATTACK_SLASH) xs_vec_mul_scalar(v_forward, RADIUS_A, v_forward)
	else if(g_Attack_Mode[id] == ATTACK_STAB) xs_vec_mul_scalar(v_forward, RADIUS_B, v_forward)
	else xs_vec_mul_scalar(v_forward, 0.0, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, ignored_monster, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED	
	if (get_user_weapon(id) != CSW_YASUO || !g_Had_Yasuo[id])
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)
	
	if(g_Attack_Mode[id] == ATTACK_SLASH) xs_vec_mul_scalar(v_forward, RADIUS_A, v_forward)
	else if(g_Attack_Mode[id] == ATTACK_STAB) xs_vec_mul_scalar(v_forward, RADIUS_B, v_forward)
	else xs_vec_mul_scalar(v_forward, 0.0, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceHull, vecStart, vecEnd, ignored_monster, hull, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_PlayerTraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], TraceResult, DamageBits) 
{
	if(!is_user_alive(Attacker))	
		return HAM_IGNORED
	if(!g_Had_Yasuo[Attacker] || !g_Checking_Mode[Attacker])
		return HAM_IGNORED
		
	return HAM_SUPERCEDE
}

public Fw_AddToFullPack_Post(esState, iE, iEnt, iHost, iHostFlags, iPlayer, pSet)
{
	if (!pev_valid(iEnt))
		return;
	if (pev(iEnt, pev_flags) & FL_KILLME) 
		return;

	new classname[32];
	pev(iEnt, pev_classname, classname, 31);

	if (equal(classname,"dps_entytyd") && pev(iEnt, pev_iuser4))
	{
		if (iHost != pev(iEnt, pev_owner))
			set_es(esState, ES_Effects, (get_es(esState, ES_Effects) | EF_NODRAW));
	}
}

public Fw_DPSEnt_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
	
	new iOwner
	iOwner = pev(iEnt, pev_owner)
	
	if(!is_user_alive(iOwner) || !is_user_connected(iOwner) || zp_get_user_zombie(iOwner))
	{
		remove_entity(iEnt)
		//g_soundmode[iOwner] = 0
		return
	}
	
	if(!Get_Entity_Mode(iEnt))
	{
		new iWpn,iState,Float:vecOrigin[3], Float:vecAngle[3];
		iWpn = pev(iEnt, pev_iuser1)
		iState = pev(iWpn, pev_iuser4)
		get_position(iOwner, 0.0, 0.0, 0.0, vecOrigin);
		
		pev(iOwner, pev_v_angle, vecAngle);
		vecAngle[0] = -vecAngle[0];
		
		//set_pev(iEnt, pev_origin, vecOrigin);
		//set_pev(iEnt, pev_angles, vecAngle);
		
		if(!iState || get_user_weapon(iOwner) != CSW_YASUO)
		{
			new Float:fRenderAmount;
			pev(iEnt, pev_renderamt, fRenderAmount);

			fRenderAmount -= 4.5;

			if (fRenderAmount <= 5.0)
			{
				remove_entity(iEnt);
				return;
			}
			set_pev(iEnt, pev_renderamt, fRenderAmount);
		}
	}
	
	if(Get_Entity_Mode(iEnt) == 1)
	{
		new iWpn,iState,Float:vecOrigin[3], Float:vecAngle[3];
		iWpn = pev(iEnt, pev_iuser1)
		iState = pev(iWpn, pev_iuser4)
		get_position(iOwner, 0.0, 0.0, 0.0, vecOrigin);
		
		pev(iOwner, pev_v_angle, vecAngle);
		vecAngle[0] = -vecAngle[0];
		
		//set_pev(iEnt, pev_origin, vecOrigin);
		//set_pev(iEnt, pev_angles, vecAngle);
		
		if(!iState || get_user_weapon(iOwner) != CSW_YASUO)
		{
			new Float:fRenderAmount;
			pev(iEnt, pev_renderamt, fRenderAmount);

			fRenderAmount -= 4.5;

			if (fRenderAmount <= 5.0)
			{
				remove_entity(iEnt);
				return;
			}
			set_pev(iEnt, pev_renderamt, fRenderAmount);
		}
	}
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.01)
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
	set_pdata_float(entwpn, 48, TimeIdle+0.5, OFFSET_LINUX_WEAPONS)
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
        
	if(get_user_weapon(iAttacker) == CSW_YASUO)
	{
		if(g_Had_Yasuo[iAttacker])
			set_msg_arg_string(4, "dualsword")
	}
                
	return PLUGIN_CONTINUE
}

stock Get_Speed_Vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
}
stock entity_set_aim(ent,const Float:origin2[3],bone=0)
{
	if(!pev_valid(ent))
		return 0;

	static Float:origin[3]
	origin[0] = origin2[0]
	origin[1] = origin2[1]
	origin[2] = origin2[2]

	static Float:ent_origin[3], Float:angles[3]

	if(bone)
		engfunc(EngFunc_GetBonePosition,ent,bone,ent_origin,angles)
	else
		pev(ent,pev_origin,ent_origin)

	origin[0] -= ent_origin[0]
	origin[1] -= ent_origin[1]
	origin[2] -= ent_origin[2]

	static Float:v_length
	v_length = vector_length(origin)

	static Float:aim_vector[3]
	aim_vector[0] = origin[0] / v_length
	aim_vector[1] = origin[1] / v_length
	aim_vector[2] = origin[2] / v_length

	static Float:new_angles[3]
	vector_to_angle(aim_vector,new_angles)

	new_angles[0] *= -1

	if(new_angles[1]>180.0) new_angles[1] -= 360
	if(new_angles[1]<-180.0) new_angles[1] += 360
	if(new_angles[1]==180.0 || new_angles[1]==-180.0) new_angles[1]=-179.999999

	set_pev(ent,pev_angles,new_angles)
	set_pev(ent,pev_fixangle,1)

	return 1;
}

stock Create_Slash(id,iEnt,seq, mode)
{
	new Float:vecOrigin[3], Float:vecAngle[3];
	GetGunPosition(id, vecOrigin);
	pev(id, pev_v_angle, vecAngle);
	vecAngle[0] = -vecAngle[0];
	
	new pEntity = DPS_Entites(id,"models/dualsword_ys_fx.mdl",vecOrigin,vecOrigin,0.01,SOLID_NOT,seq)
		
	// Set info for ent	
	Set_Entity_Mode(pEntity, mode)
	set_pev(pEntity, pev_scale, 0.1);
	set_pev(pEntity, pev_iuser1, iEnt);
	set_pev(pEntity, pev_velocity, Float:{0.01,0.01,0.01});
	set_pev(pEntity, pev_angles, vecAngle);
	set_pev(pEntity, pev_nextthink, get_gametime()+0.01);
}
stock Set_Entity_Mode(iEnt, mode) set_pev(iEnt, pev_iuser3, mode)
stock Get_Entity_Mode(iEnt) return pev(iEnt,pev_iuser3)
stock DPS_Entites(id, models[], Float:Start[3], Float:End[3], Float:speed, solid, seq, move=MOVETYPE_FLY)
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
		
	// Set info for ent	
	set_pev(pEntity, pev_movetype, move);
	set_pev(pEntity, pev_owner, id);
	engfunc(EngFunc_SetModel, pEntity, models);
	set_pev(pEntity, pev_classname, "dps_entytyd");
	set_pev(pEntity, pev_mins, Float:{-1.0, -1.0, -1.0});
	set_pev(pEntity, pev_maxs, Float:{1.0, 1.0, 1.0});
	set_pev(pEntity, pev_origin, Start);
	set_pev(pEntity, pev_gravity, 0.01);
	set_pev(pEntity, pev_solid, solid);
	
	static Float:Velocity[3];
	Get_Speed_Vector(Start, End, speed, Velocity);
	set_pev(pEntity, pev_velocity, Velocity);

	new Float:vecVAngle[3]; pev(id, pev_v_angle, vecVAngle);
	vector_to_angle(Velocity, vecVAngle)
	
	if(vecVAngle[0] > 90.0) vecVAngle[0] = -(360.0 - vecVAngle[0]);
	set_pev(pEntity, pev_angles, vecVAngle);
	
	set_pev(pEntity, pev_rendermode, kRenderTransAdd);
	set_pev(pEntity, pev_renderamt, 255.0);
	set_pev(pEntity, pev_sequence, seq)
	set_pev(pEntity, pev_animtime, get_gametime());
	set_pev(pEntity, pev_framerate, 1.0)
	return pEntity;
}stock GetGunPosition(id, Float:vecSrc[3])
{
	new Float:vecViewOfs[3];
	pev(id, pev_origin, vecSrc);
	pev(id, pev_view_ofs, vecViewOfs);
	xs_vec_add(vecSrc, vecViewOfs, vecSrc);
}

stock Stock_Hook_Ent(ent, Float:TargetOrigin[3], Float:Speed, mode=0)
{
	static Float:fl_Velocity[3],Float:EntOrigin[3],Float:distance_f,Float:fl_Time
	pev(ent, pev_origin, EntOrigin)
	
	if(!mode)
	{
		distance_f = get_distance_f(EntOrigin, TargetOrigin)
		fl_Time = distance_f / Speed
			
		pev(ent, pev_velocity, fl_Velocity)
			
		fl_Velocity[0] = (TargetOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (TargetOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = (TargetOrigin[2] - EntOrigin[2]) / fl_Time

		if(vector_length(fl_Velocity) > 1.0) set_pev(ent, pev_velocity, fl_Velocity)
		else set_pev(ent, pev_velocity, Float:{0.01, 0.01, 0.01})
	} else {
		static Float:fl_EntVelocity[3], Float:fl_Acc[3]
		Stock_Directed_Vector(TargetOrigin, EntOrigin, fl_Velocity)
		xs_vec_mul_scalar(fl_Velocity, Speed, fl_Velocity)
		
		for(new i =0; i<3; i++)
		{
			if(fl_Velocity[i] > fl_EntVelocity[i]) 
			{
				fl_Acc[i] = fl_Velocity[i]-fl_EntVelocity[i]
				fl_Acc[i] = floatmin(70.0, fl_Acc[i])
				fl_EntVelocity[i] += fl_Acc[i]
			}
			else if(fl_Velocity[i] < fl_EntVelocity[i])
			{
				fl_Acc[i] = fl_EntVelocity[i]-fl_Velocity[i]
				fl_Acc[i] = floatmin(70.0, fl_Acc[i])
				fl_EntVelocity[i] -= fl_Acc[i]
			}
		}
		set_pev(ent, pev_velocity, fl_EntVelocity)
	}
}
stock Stock_Directed_Vector(Float:start[3],Float:end[3],Float:reOri[3])
{	
	new Float:v3[3],i
	for(i=0;i<3;i++) v3[i]=start[i]-end[i]

	new Float:vl = vector_length(v3)
	for(i=0;i<3;i++) reOri[i] = v3[i] / vl
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
