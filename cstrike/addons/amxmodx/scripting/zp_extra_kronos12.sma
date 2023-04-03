#include <amxmodx>
#include <engine>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <xs>
#include <zombieplague>
#include <metadrawer>
#include <toan>

#define V_MODEL "models/v_kronos12.mdl"
#define P_MODEL "models/p_kronos12.mdl"
#define W_MODEL "models/w_kronos12.mdl"
#define SIGHT_MODEL "models/ef_kronos5.mdl"

#define CSW_BASEDON CSW_M3
#define weapon_basedon "weapon_m3"

#define DAMAGE_A 1.3
#define DAMAGE_B 250.0
#define CLIP 30
#define BPAMMO 240
#define SPEED_A 0.27
#define SPEED_B 0.27
#define RECOIL 0.3
#define RELOAD_TIME 4.0
#define	RESULT_HIT_NONE 			0
#define	RESULT_HIT_PLAYER			1
#define	RESULT_HIT_WORLD			2
#define MAX_SHOOT 10
#define RANGE 1096.0
#define ANGLE 180.0
#define KNOCKBACK 2.5
#define BODY_NUM 0
#define mf_cls "duarrmemek"
#define WEAPON_SECRETCODE 15685122
#define WEAPON_EVENT "events/m3.sc"
#define OLD_W_MODEL "models/w_m3.mdl"

new const hud[][] = {
	"gfx/tga_image/kronos_aim_bg.tga",
	"gfx/tga_image/kronos_aim_gauge.tga"
}

enum
{
	ANIM_IDLE = 0,
	ANIM_IDLE2,
	ANIM_IDLE3,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT3,
	ANIM_RELOAD,
	ANIM_RELOAD2,
	ANIM_DRAW,
	ANIM_DRAW2,
	ANIM_SCAN_ACTIVATE,
	ANIM_ZOOM,
	ANIM_SCAN_DEACTIVATE
}

new const ExtraSounds[][] =
{
	"weapons/kronos12_takeaim.wav",
	"weapons/kronos12-1.wav"
}
new g_System, Max_Shoot, Float:TargetLock[33], g_holding_attack[33], g_Shoot_Count[33]
new g_Had_Weapon, g_Old_Weapon[33], Float:g_Recoil[33][3], g_Clip[33]
new g_weapon_event, g_ShellId, g_SmokePuff_SprId,spr_blood_spray,spr_blood_drop
new g_HamBot, g_Msg_CurWeapon, laser, m_spriteTexture
new x12
// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

#define TASK_USE 10920+10
#define TASK_RESET 10920+11
#define MAX_TARGET 32

public plugin_init()
{
	register_plugin("Hunter Killer X12", "version1", "Mellowzy")
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel")	
	register_forward(FM_Think, "fw_MF_Think2")
	register_forward(FM_AddToFullPack, "fw_AddToFullPack", 1)
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")
	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_basedon, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_basedon, "fw_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon_basedon, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Weapon_Reload, weapon_basedon, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_basedon, "fw_Weapon_Reload_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_basedon, "fw_WeaponIdle", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_basedon, "fw_Item_PostFrame")	
	RegisterHam(Ham_TakeDamage, "player", "HAM_TakeDamage")
	
	RegisterHam(Ham_Spawn, "player", "Remove_Weapon", 1)
	RegisterHam(Ham_Killed, "player", "Remove_Weapon", 1)
	
	g_Msg_CurWeapon = get_user_msgid("CurWeapon")
	
	x12 = zp_register_extra_item("Hunter Killer X-12", 3000, ZP_TEAM_HUMAN)
	register_clcmd("weapon_kronos12", "weapon_hook")

	
	for(new i=0;i<sizeof(hud);i++)
		md_loadimage(hud[i])
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	spr_blood_spray = precache_model("sprites/bloodspray.spr")
	spr_blood_drop = precache_model("sprites/blood.spr")
	
	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	g_ShellId = engfunc(EngFunc_PrecacheModel, "models/rshell.mdl")
	laser = precache_model("sprites/zbeam3.spr")
	m_spriteTexture = precache_model( "sprites/laserbeam.spr" )
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	
	for(new i = 0; i < sizeof(ExtraSounds); i++)
		precache_sound(ExtraSounds[i])
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(WEAPON_EVENT, name))
		g_weapon_event = get_orig_retval()		
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
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Player")	
}
public zp_extra_item_selected(id, itemid)
{
	if(itemid == x12) Get_Weapon(id)
}

public zp_user_infected_post(id)Remove_Weapon(id)
public Get_Weapon(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id))
		return
		
	Stock_DropSlot(id, 1)
	UnSet_BitVar(g_System, id)
	UnSet_BitVar(Max_Shoot, id)
	g_holding_attack[id] = 0
	g_Shoot_Count[id] = 0
		
	Set_BitVar(g_Had_Weapon, id)
	fm_give_item(id, weapon_basedon)	
	
	// Set Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_BASEDON)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, CLIP)
	
	cs_set_user_bpammo(id, CSW_BASEDON, BPAMMO)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, g_Msg_CurWeapon, {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_BASEDON)
	write_byte(CLIP)
	message_end()	
}

public Remove_Weapon(id)
{
	set_fov(id)
	ScreenFade(id, 0, 0, 0, 0, 0)
	UnSet_BitVar(g_Had_Weapon, id)
	UnSet_BitVar(g_System, id)
	UnSet_BitVar(Max_Shoot, id)
	g_holding_attack[id] = 0
	g_Shoot_Count[id] = 0
	remove_task(id+TASK_USE)
	remove_task(id+TASK_RESET)
}
public weapon_hook(id)
{
	engclient_cmd(id, weapon_basedon) 
	return PLUGIN_HANDLED
}
public client_connect(id)Remove_Weapon(id)
public client_disconnected(id)Remove_Weapon(id)
public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
	
	static CSWID; CSWID = read_data(2)
	
	if((CSWID == CSW_BASEDON && g_Old_Weapon[id] != CSW_BASEDON) && Get_BitVar(g_Had_Weapon, id))
	{
		set_pev(id, pev_viewmodel2, V_MODEL)
		set_pev(id, pev_weaponmodel2, "")
		if(Get_BitVar(g_System, id))
		{
			g_holding_attack[id] = 0
			g_Shoot_Count[id] = 0
			UnSet_BitVar(Max_Shoot, id)
			UnSet_BitVar(g_System, id)
			set_fov(id)
			ScreenFade(id, 0, 0, 0, 0, 0)
			remove_task(id+TASK_USE)
			remove_task(id+TASK_RESET)
			set_weapon_anim(id, ANIM_DRAW)
		} 
		else set_weapon_anim(id, Get_BitVar(Max_Shoot, id)? ANIM_DRAW2 : ANIM_DRAW)
		Draw_NewWeapon(id, CSWID)
	} else if((CSWID == CSW_BASEDON && g_Old_Weapon[id] == CSW_BASEDON) && Get_BitVar(g_Had_Weapon, id)) {
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_BASEDON)
		if(!pev_valid(Ent))
		{
			g_Old_Weapon[id] = get_user_weapon(id)
			return
		}
		new Float:flSpeed[33]
		if(Get_BitVar(g_System, id))flSpeed[id] = SPEED_B
		else flSpeed[id] = SPEED_A
		set_pdata_float(Ent, 46, get_pdata_float(Ent, 46, 4) * flSpeed[id], 4)
	} else if(CSWID != CSW_BASEDON && g_Old_Weapon[id] == CSW_BASEDON) Draw_NewWeapon(id, CSWID)
	
	g_Old_Weapon[id] = get_user_weapon(id)
}
public Message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
        
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
        
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return PLUGIN_CONTINUE
        
	if(get_user_weapon(iAttacker) == CSW_BASEDON)
	{
		if(Get_BitVar(g_Had_Weapon, iAttacker))
			set_msg_arg_string(4, "kronos12")
	}
                
	return PLUGIN_CONTINUE
}
public Draw_NewWeapon(id, CSW_ID)
{
	if(CSW_ID == CSW_BASEDON)
	{
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_BASEDON)
		
		if(pev_valid(ent) && Get_BitVar(g_Had_Weapon, id))
		{
			set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW) 
			engfunc(EngFunc_SetModel, ent, P_MODEL)	
			set_pev(ent, pev_body, BODY_NUM)
		}
	} else {
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_BASEDON)
		
		if(pev_valid(ent)) set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW) 			
	}
	
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_BASEDON && Get_BitVar(g_Had_Weapon, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_BASEDON || !Get_BitVar(g_Had_Weapon, invoker))
		return FMRES_IGNORED
	if(eventid != g_weapon_event)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
			
	Eject_Shell(invoker, g_ShellId, 0.0)
		
	return FMRES_SUPERCEDE
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[32]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, OLD_W_MODEL))
	{
		static weapon; weapon = fm_find_ent_by_owner(-1, weapon_basedon, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_Had_Weapon, iOwner))
		{
			set_fov(iOwner)
			g_holding_attack[iOwner] = 0
			ScreenFade(iOwner, 0, 0, 0, 0, 0)
			UnSet_BitVar(g_Had_Weapon, iOwner)
			remove_task(iOwner+TASK_USE)
			remove_task(iOwner+TASK_RESET)
			
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			set_pev(entity, pev_body, BODY_NUM)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_BASEDON || !Get_BitVar(g_Had_Weapon, Attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]
	
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)		
	return HAM_IGNORED
}

public fw_TraceAttack_Player(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_BASEDON || !Get_BitVar(g_Had_Weapon, Attacker))
		return HAM_IGNORED
	if(get_user_team(Victim) == get_user_team(Attacker))
		return HAM_IGNORED
	
	static Float:flEnd[3]
	get_tr2(Ptr, TR_vecEndPos, flEnd)

	return HAM_IGNORED
}

public HAM_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_BASEDON)
		{
			if(Get_BitVar(g_Had_Weapon, attacker))
			{			
				new Float:_damage;
				if (Get_BitVar(g_System, attacker))
				{
					_damage = 0.0
				}else{
					_damage = DAMAGE_A
				}

				_damage = random_float(0.8, 1.2) * damage

				SetHamParamFloat(4, is_deadlyshot(attacker)?_damage*1.5:_damage)
			}

		}
	}
}
public Create_Tracer(id, Target[3])
{
	//client_print(id, print_chat, "                         %d %d %d", Target[0], Target[1], Target[2])

	new Float:Start[3]; 
	Get_Position(id, 48.0, 0.0, -6.0, Start)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMPOINTS)
	write_coord_f(Start[0]) 
	write_coord_f(Start[1]) 
	write_coord_f(Start[2]) 
	write_coord_f(float(Target[0])) 
	write_coord_f(float(Target[1])) 
	write_coord_f(float(Target[2])) 
	write_short(m_spriteTexture)
	write_byte(0) // framerate
	write_byte(0) // framerate
	write_byte(5) // life
	write_byte(2)  // width
	write_byte(0)   // noise
	write_byte(200)   // r, g, b
	write_byte(200)   // r, g, b
	write_byte(200)   // r, g, b
	write_byte(80)	// brightness
	write_byte(1)		// speed
	message_end() 
}

public fw_WeaponIdle(Ent)
{
	static id; id = get_pdata_cbase(Ent, 41, 4)
	if(!Get_BitVar(g_Had_Weapon, id))return HAM_IGNORED
	
	static Float:flTimeWeaponIdle; flTimeWeaponIdle = get_pdata_float(Ent,48, 4)
	if(!(flTimeWeaponIdle < 0.1)) return HAM_IGNORED
	
	if(Get_BitVar(g_System, id))Stock_SetAnimIdle(id, Ent, ANIM_IDLE3, 2.5)
	else Stock_SetAnimIdle(id, Ent, Get_BitVar(Max_Shoot, id)? ANIM_IDLE2 : ANIM_IDLE, 2.5)
	
	return HAM_IGNORED
}
	
public fw_Weapon_PrimaryAttack(Ent)
{
	static id; id = pev(Ent, pev_owner)
	pev(id, pev_punchangle, g_Recoil[id])
	if(!Get_BitVar(g_Had_Weapon, id))return HAM_IGNORED
	
	static iClip; iClip = get_pdata_int(Ent, 51, 4)
	set_pdata_int(Ent, 14, iClip, 4)
	set_pdata_int(Ent, 16, iClip?1:0, 4)
	
	return HAM_IGNORED
}
public AutoLockSystem(iPlayer,bool:active)
{
	if(!IsAlive(iPlayer) || !Get_BitVar(g_Had_Weapon, iPlayer))
		return 1;
	if(zp_get_user_zombie(iPlayer))
		return 1;

	if(active)
	{
		
		new Float:Org[3];
		pev(iPlayer, pev_origin, Org)
		new a = FM_NULLENT
		while((a = find_ent_in_sphere(a, Org, RANGE)) != 0)
		{
			if (iPlayer == a)
				continue 
			if (!pev_valid(a))
				continue;
			if (!is_user_alive(a))
				continue;
			if (!zp_get_user_zombie(a))
				continue;
			if(!can_see_fm(iPlayer, a))
				continue;

			new Float:Target[3];
			pev(a, pev_origin, Target)
			if(!is_in_viewcone(iPlayer, Target))
				continue;

			new TargetO[3];
			get_user_origin(a, TargetO, 0)
			Create_Tracer(iPlayer, TargetO)

			if(pev(a, pev_takedamage) != DAMAGE_NO)
			{
				Stock_BloodEffect(Target)
				ExecuteHamB(Ham_TakeDamage, a, iPlayer, iPlayer, is_deadlyshot(iPlayer)?random_float(DAMAGE_B-10,DAMAGE_B+10)*1.5:random_float(DAMAGE_B-10,DAMAGE_B+10), DMG_BULLET)
			}
		}
	}
	else
	{
		return 1;
	}
	
	return 0;
}
public fw_Weapon_PrimaryAttack_Post(Ent)
{
	static id; id = pev(Ent, pev_owner)
	if(!Get_BitVar(g_Had_Weapon, id))return HAM_IGNORED
	if(get_pdata_int(Ent, 14, 4) <= get_pdata_int(Ent, 51, 4)) return HAM_SUPERCEDE
	
	if(!get_pdata_int(Ent, 16, 4)) return HAM_IGNORED
	set_pdata_int(Ent, 16, 0, 4)
	
	static Float:Push[3]
	pev(id, pev_punchangle, Push)
	xs_vec_sub(Push, g_Recoil[id], Push)
		
	xs_vec_mul_scalar(Push, RECOIL, Push)
	xs_vec_add(Push, g_Recoil[id], Push)
	set_pev(id, pev_punchangle, Push)
	
	//MakeMuzzleFlash(id)
	if(Get_BitVar(g_System, id))
	{
		AutoLockSystem(id,true)
		set_weapon_anim(id, ANIM_SHOOT3)
	}
	else 
	{
		AutoLockSystem(id,false)
		set_weapon_anim(id, Get_BitVar(Max_Shoot, id)? ANIM_SHOOT2 : ANIM_SHOOT1)
	}
	
	g_Shoot_Count[id]++
	if(g_Shoot_Count[id] >= MAX_SHOOT)
	{
		g_Shoot_Count[id] = 0
		Set_BitVar(Max_Shoot, id)

		if(is_user_bot(id)){
			set_weapon_anim(id, ANIM_ZOOM)
			set_pdata_float(id, 83, 1.0, 5)
			set_task(0.7, "Activate_System", id+TASK_USE)
		}
	}

	client_cmd(id, "spk %s", ExtraSounds[1])
	return HAM_IGNORED
}
public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))return FMRES_IGNORED	
	if(get_user_weapon(id) != CSW_BASEDON || !Get_BitVar(g_Had_Weapon, id))return FMRES_IGNORED	
	
	static PressButton; PressButton = get_uc(uc_handle, UC_Buttons)
	static OldButton; OldButton = pev(id, pev_oldbuttons)
	
	if((PressButton & IN_RELOAD) && Get_BitVar(g_System, id))
		return FMRES_SUPERCEDE
	
	if((PressButton & IN_ATTACK))
	{
		if(!g_holding_attack[id]) g_holding_attack[id] = 1
	} else {
		if(OldButton & IN_ATTACK)
		{
			g_holding_attack[id] = 0
		}
	}
		
	if((PressButton & IN_ATTACK2))
	{
		PressButton &= ~IN_ATTACK2
		set_uc(uc_handle, UC_Buttons, PressButton)
		
		if((pev(id, pev_oldbuttons) & IN_ATTACK2))
			return FMRES_IGNORED
		if(!Get_BitVar(Max_Shoot, id) || Get_BitVar(g_System, id))
			return FMRES_IGNORED
			
		set_weapon_anim(id, ANIM_ZOOM)
		set_pdata_float(id, 83, 1.0, 5)
		set_task(0.7, "Activate_System", id+TASK_USE)
	}
	if(get_gametime() - 1.0 > TargetLock[id])
	{
		static Body, Target; get_user_aiming(id, Target, Body, 99999)
		
		if(Get_BitVar(g_System, id))
		{
			if(is_user_alive(Target))
			{
				emit_sound(id, CHAN_BODY, ExtraSounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
			} else {
				//Do nothing
			}
		}
		TargetLock[id] = get_gametime()
	}
	return FMRES_IGNORED
}

public Activate_System(id)
{
	id -= TASK_USE
	if(!Get_BitVar(g_Had_Weapon, id))return
	if(!Get_BitVar(Max_Shoot, id))return
	
	Set_BitVar(g_System, id)
	UnSet_BitVar(Max_Shoot, id)
	
	set_task(8.0, "Deactivate_System_Stage01", id+TASK_RESET)
	ScreenFade(id, 1, 246, 155, 0, 50)
	set_fov(id, 75)
}
public Deactivate_System_Stage01(id)
{
	id -= TASK_RESET
	if(!Get_BitVar(g_Had_Weapon, id))return
	if(!Get_BitVar(g_System, id))return
	
	set_task(0.5, "Deactivate_System_Stage02", id+TASK_RESET)
	
	set_weapon_anim(id, ANIM_SCAN_DEACTIVATE)
	set_fov(id)
	ScreenFade(id, 0, 0, 0, 0, 0)
	set_pdata_float(id, 83, 1.0, 5)
}
public Deactivate_System_Stage02(id)
{
	id -= TASK_RESET
	if(!Get_BitVar(g_Had_Weapon, id))return
	if(!Get_BitVar(g_System, id))return
	
	set_weapon_anim(id, ANIM_IDLE)
	
	g_holding_attack[id] = 0
	g_Shoot_Count[id] = 0
	UnSet_BitVar(Max_Shoot, id)
	UnSet_BitVar(g_System, id)
}
public fw_Item_AddToPlayer_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		Set_BitVar(g_Had_Weapon, id)
		set_pev(ent, pev_impulse, 0)
	}

	return HAM_HANDLED	
}

public fw_Item_PostFrame(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(is_user_alive(id) && Get_BitVar(g_Had_Weapon, id))
	{	
		static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
		static bpammo; bpammo = cs_get_user_bpammo(id, CSW_BASEDON)
		static iClip; iClip = get_pdata_int(ent, 51, 4)
		static fInReload; fInReload = get_pdata_int(ent, 54, 4)
		
		if(fInReload && flNextAttack <= 0.0)
		{
			static temp1; temp1 = min(CLIP - iClip, bpammo)

			set_pdata_int(ent, 51, iClip + temp1, 4)
			cs_set_user_bpammo(id, CSW_BASEDON, bpammo - temp1)		
			
			set_pdata_int(ent, 54, 0, 4)
			
			fInReload = 0
		}		
	}
	
	return HAM_IGNORED	
}
public fw_MF_Think2(ent)
{
	if(!pev_valid(ent))
		return
	
	static Classname[32]
	pev(ent, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, mf_cls))
	{
		set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
		return
	}
}
public fw_Weapon_Reload(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Weapon, id))
		return HAM_IGNORED
	
	g_Clip[id] = -1
	
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_BASEDON)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	
	if(bpammo <= 0) return HAM_SUPERCEDE
	
	if(iClip >= CLIP) return HAM_SUPERCEDE		
		
	g_Clip[id] = iClip

	return HAM_HANDLED
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Weapon, id))
		return HAM_IGNORED

	if (g_Clip[id] == -1)
		return HAM_IGNORED
	
	set_pdata_int(ent, 51, g_Clip[id], 4)
	set_pdata_int(ent, 54, 1, 4)
	
	if(Get_BitVar(g_System, id))
	{
		g_holding_attack[id] = 0
		g_Shoot_Count[id] = 0
		UnSet_BitVar(Max_Shoot, id)
		UnSet_BitVar(g_System, id)
		set_fov(id)
		remove_task(id+TASK_USE)
		remove_task(id+TASK_RESET)
		ScreenFade(id, 0, 0, 0, 0, 0)
		set_weapon_anim(id, ANIM_RELOAD)
	}
	else set_weapon_anim(id, Get_BitVar(Max_Shoot, id)? ANIM_RELOAD2 : ANIM_RELOAD)
	
	set_pdata_float(id, 83, RELOAD_TIME, 5)

	return HAM_HANDLED
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
	if(!zp_get_user_zombie(ent))
		return FMRES_IGNORED
	if(get_user_weapon(host) != CSW_BASEDON)
		return FMRES_IGNORED
	if(!Get_BitVar(g_Had_Weapon, host))
		return FMRES_IGNORED
	if(!Get_BitVar(g_System, host))
		return FMRES_IGNORED
	if(entity_range(host,ent) > RANGE)
		return FMRES_IGNORED

	static HeatColor[3]
	HeatColor[0] = 255
	HeatColor[1] = 0
	HeatColor[2] = 0
	set_es(es, ES_RenderFx, kRenderFxGlowShell)
	set_es(es, ES_RenderMode, kRenderNormal)
	set_es(es, ES_RenderAmt, 10)
	set_es(es, ES_RenderColor, HeatColor)
		
	return FMRES_HANDLED
}
stock Make_BulletHole(id, Float:Origin[3], Float:Damage)
{
	// Find target
	static Decal; Decal = random_num(41, 45)
	static LoopTime; 
	
	if(Damage > 100.0) LoopTime = 2
	else LoopTime = 1
	
	for(new i = 0; i < LoopTime; i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(Decal)
		message_end()
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(id)
		write_byte(Decal)
		message_end()
	}
}

public Make_BulletSmoke(id, TrResult)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(TrResult, TR_vecEndPos, vecSrc)
	get_tr2(TrResult, TR_vecPlaneNormal, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
    
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0)
	write_short(g_SmokePuff_SprId)
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()
}

// Stock
stock Stock_DropSlot(iPlayer, Slot)
{
	new item = get_pdata_cbase(iPlayer, 367+Slot, 4)
	while(item > 0)
	{
		static classname[24]
		pev(item, pev_classname, classname, charsmax(classname))
		engclient_cmd(iPlayer, "drop", classname)
		item = get_pdata_cbase(item, 42, 5)
	}
	set_pdata_cbase(iPlayer, 367, -1, 4)
}
stock Stock_CreateEntityBase(id, classtype[], mvtyp, mdl[], class[], solid, Float:fNext,Float:vOrg[3], Float:vAng[3])
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classtype))
	set_pev(pEntity, pev_movetype, mvtyp);
	set_pev(pEntity, pev_owner, id);
	engfunc(EngFunc_SetModel, pEntity, mdl);
	set_pev(pEntity, pev_classname, class);
	set_pev(pEntity, pev_solid, solid);
	if(vOrg[0]) set_pev(pEntity, pev_origin, vOrg)
	if(vAng[0]) set_pev(pEntity, pev_angles, vAng)
	if(fNext) set_pev(pEntity, pev_nextthink, get_gametime() + fNext)
	return pEntity
}
stock hook_ent2(ent, Float:VicOrigin[3], Float:speed, Float:multi, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	static Float:EntVelocity[3]
	
	pev(ent, pev_velocity, EntVelocity)
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	static Float:fl_Time; fl_Time = distance_f / speed
	static Float:fl_Time2; fl_Time2 = distance_f / (speed * multi)
	
	if(type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time2) * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time2) * 1.5
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time		
	} else if(type == 2) {
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time2) * 1.5
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time2) * 1.5
		fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time
	}

	xs_vec_add(EntVelocity, fl_Velocity, fl_Velocity)
	set_pev(ent, pev_velocity, fl_Velocity)
}

stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	static Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	static Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	static Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	static Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}

stock Eject_Shell(id, Shell_ModelIndex, Float:Time) // By Dias
{
	static Ent; Ent = get_pdata_cbase(id, 373, 5)
	if(!pev_valid(Ent))
		return

        set_pdata_int(Ent, 57, Shell_ModelIndex, 4)
        set_pdata_float(id, 111, get_gametime() + Time)
}

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
	
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}
stock set_fov(id, fov = 90)
{
	message_begin(MSG_ONE, get_user_msgid("SetFOV"), {0,0,0}, id)
	write_byte(zp_get_user_zombie(id)?get_cvar_num("zp_zombie_fov"):fov)
	message_end()
}
stock Stock_SetAnimIdle(id, iEnt, iAnim, Float:flTime) //NST Ed Cyti
{
	if(iAnim == -1) return
	if(pev(id, pev_weaponanim) != iAnim) set_weapon_anim(id, iAnim)
	set_pdata_float(iEnt, 48, flTime, 4)
}
stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
stock Create_CheatEsp(id, active)
{
	new Float:fStartOrigin [ 3 ] , Float:fView [ 3 ] , Float:fEnd [ 3 ] , Float:fOrginPlayer [ 3 ] ,bool:bSee = false , Float:fEndPosEsp [ 3 ] ,Float: fVectorTmp2 [ 3 ] , Float: fAnglesEsp [ 3 ] , Float: fRight[ 3 ], Float: fUp [ 3 ]
	if(!is_user_alive(id))return
	if(get_user_weapon(id) != CSW_BASEDON || !Get_BitVar(g_Had_Weapon, id))return
	if(!active)return
	
	pev( id ,pev_origin , fStartOrigin );
	pev( id ,pev_view_ofs , fView ) ;
		
	pev( id , pev_v_angle , fAnglesEsp );
		
	angle_vector( fAnglesEsp , ANGLEVECTOR_UP , fUp )
	angle_vector( fAnglesEsp , ANGLEVECTOR_RIGHT , fRight )
		
	xs_vec_normalize( fRight , fRight );
	xs_vec_normalize( fUp , fUp )
		
	xs_vec_add( fStartOrigin , fView , fStartOrigin );
	
	for ( new i = 1 ; i <= 32 ; i++ ){
		if( !is_user_alive( i ))continue;
		if( cs_get_user_team(i) == cs_get_user_team(id) )continue
		
		bSee = false
		pev( i , pev_origin , fEnd );

		if(!can_see_fm(id, i))
			continue;

		if(!is_in_viewcone(id, fEnd))
			continue;

		new tr	=	create_tr2();
			
		engfunc( EngFunc_TraceLine , fStartOrigin , fEnd , IGNORE_GLASS | IGNORE_MONSTERS , id , tr ); 
			
		if( pev_valid( get_tr2( tr , TR_pHit ) ) && ( get_tr2( tr , TR_pHit ) == i || pev( get_tr2( tr , TR_pHit ) , pev_owner ) == i )){
			bSee	=	true;
			get_tr2( tr , TR_vecEndPos , fEndPosEsp );
		}
			
		free_tr2( tr );
		if( !bSee ){
				
			pev( i ,pev_view_ofs , fView );
				
			xs_vec_add( fEnd , fView , fEnd );
				
			tr	=	create_tr2();
				
			engfunc( EngFunc_TraceLine , fStartOrigin , fEnd , IGNORE_GLASS | IGNORE_MONSTERS , id , tr ); 
				
			if( pev_valid( get_tr2( tr , TR_pHit ) ) && ( get_tr2( tr , TR_pHit ) == i || pev( get_tr2( tr , TR_pHit ) , pev_owner ) == i )){
				bSee	=	true;
				get_tr2( tr , TR_vecEndPos , fEndPosEsp );
			}
				
			free_tr2( tr );
		}
		if( bSee || entity_range( i , id ) < RANGE + 5){
			if( !bSee ){
				pev( i , pev_origin , fEnd );
					
				new tr	=	create_tr2();
				
				engfunc( EngFunc_TraceLine , fStartOrigin , fEnd , IGNORE_GLASS | IGNORE_MONSTERS , id , tr ); 
					
				get_tr2( tr , TR_vecEndPos , fEndPosEsp );
					
				free_tr2( tr );
			}
				
			new Float: fVector [ 3 ] , Float:fVectorTmp [ 3 ];
				
			xs_vec_sub( fEndPosEsp , fStartOrigin , fVector );
			xs_vec_normalize( fVector , fVector );
			xs_vec_mul_scalar( fVector , 5.0 , fVector );
				
			xs_vec_sub( fEndPosEsp , fVector , fVector );
				
			pev( i , pev_origin , fOrginPlayer )
				
			xs_vec_sub( fOrginPlayer , fStartOrigin , fVectorTmp )
			xs_vec_sub( fVector , fStartOrigin , fVectorTmp2 );
				
			new Float:fLen	=	25.0 * ( xs_vec_len(fVectorTmp2) / xs_vec_len( fVectorTmp ));
				
			new Float: fFourPoints [ 4 ][ 3 ] , Float: fTmpUp [ 3 ] , Float: fTmpRight[ 3 ];
				
			xs_vec_copy( fUp , fTmpUp );
			xs_vec_copy( fRight , fTmpRight );
				
			xs_vec_mul_scalar( fTmpUp , fLen , fTmpUp );
			xs_vec_mul_scalar( fTmpRight , fLen , fTmpRight );
				
			xs_vec_copy( fVector , fFourPoints [ 0 ] );
			xs_vec_add( fFourPoints [ 0 ] , fTmpUp , fFourPoints [ 0 ] );
			xs_vec_add( fFourPoints [ 0 ] , fTmpRight , fFourPoints [ 0 ] );
				
			xs_vec_copy( fVector , fFourPoints [ 1 ] );
			xs_vec_add( fFourPoints [ 1 ] , fTmpUp , fFourPoints [ 1 ] );
			xs_vec_sub( fFourPoints [ 1 ] , fTmpRight , fFourPoints [ 1 ] );
				
			xs_vec_copy( fVector , fFourPoints [ 2 ] );
			xs_vec_sub( fFourPoints [ 2 ] , fTmpUp , fFourPoints [ 2 ] );
			xs_vec_add( fFourPoints [ 2 ] , fTmpRight , fFourPoints [ 2 ] );
				
			xs_vec_copy( fVector , fFourPoints [ 3 ] );
			xs_vec_sub( fFourPoints [ 3 ] , fTmpUp , fFourPoints [ 3 ] );
			xs_vec_sub( fFourPoints [ 3 ] , fTmpRight , fFourPoints [ 3 ] );
				
			new iRed , iBlue , iGreen, Brightness ;
			iRed	=	255;
			iBlue	=	0;
			iGreen	=	0;
			Brightness = 160

			message_begin(MSG_ONE_UNRELIABLE ,SVC_TEMPENTITY,{0,0,0},id) //message begin
			write_byte(0)
			engfunc( EngFunc_WriteCoord , fFourPoints [ 0 ][ 0 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 0 ][ 1 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 0 ][ 2 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 1 ][ 0 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 1 ][ 1 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 1 ][ 2 ] )
			write_short(laser) // sprite index
			write_byte(3) // starting frame
			write_byte(0) // frame rate in 0.1's
			write_byte(1) // life in 0.1's
			write_byte(10) // line width in 0.1's
			write_byte(0) // noise amplitude in 0.01's
			write_byte(iRed)
			write_byte(iGreen)
			write_byte(iBlue)
			write_byte(Brightness)
			write_byte(0) // scroll speed in 0.1's
			message_end()
				
			message_begin(MSG_ONE_UNRELIABLE ,SVC_TEMPENTITY,{0,0,0},id) //message begin
			write_byte(0)
			engfunc( EngFunc_WriteCoord , fFourPoints [ 0 ][ 0 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 0 ][ 1 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 0 ][ 2 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 2 ][ 0 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 2 ][ 1 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 2 ][ 2 ] )
			write_short(laser) // sprite index
			write_byte(3) // starting frame
			write_byte(0) // frame rate in 0.1's
			write_byte(1) // life in 0.1's
			write_byte(10) // line width in 0.1's
			write_byte(0) // noise amplitude in 0.01's
			write_byte(iRed)
			write_byte(iGreen)
			write_byte(iBlue)
			write_byte(Brightness)
			write_byte(0) // scroll speed in 0.1's
			message_end()
				
			message_begin(MSG_ONE_UNRELIABLE ,SVC_TEMPENTITY,{0,0,0},id) //message begin
			write_byte(0)
			engfunc( EngFunc_WriteCoord , fFourPoints [ 2 ][ 0 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 2 ][ 1 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 2 ][ 2 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 3 ][ 0 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 3 ][ 1 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 3 ][ 2 ] )
			write_short(laser) // sprite index
			write_byte(3) // starting frame
			write_byte(0) // frame rate in 0.1's
			write_byte(1) // life in 0.1's
			write_byte(10) // line width in 0.1's
			write_byte(0) // noise amplitude in 0.01's
			write_byte(iRed)
			write_byte(iGreen)
			write_byte(iBlue)
			write_byte(Brightness)
			write_byte(0) // scroll speed in 0.1's
			message_end()
			
			message_begin(MSG_ONE_UNRELIABLE ,SVC_TEMPENTITY,{0,0,0},id) //message begin
			write_byte(0)
			engfunc( EngFunc_WriteCoord , fFourPoints [ 3 ][ 0 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 3 ][ 1 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 3 ][ 2 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 1 ][ 0 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 1 ][ 1 ] )
			engfunc( EngFunc_WriteCoord , fFourPoints [ 1 ][ 2 ] )
			write_short(laser) // sprite index
			write_byte(3) // starting frame
			write_byte(0) // frame rate in 0.1's
			write_byte(1) // life in 0.1's
			write_byte(10) // line width in 0.1's
			write_byte(0) // noise amplitude in 0.01's
			write_byte(iRed)
			write_byte(iGreen)
			write_byte(iBlue)
			write_byte(Brightness)
			write_byte(0) // scroll speed in 0.1's
			message_end()
		}
	}
}
stock ScreenFade(id, active, red, green, blue, alpha)
{
	if(!active || get_user_weapon(id) != CSW_BASEDON || !Get_BitVar(g_Had_Weapon, id) ||!Get_BitVar(g_System, id))
	{
		message_begin(MSG_ONE, get_user_msgid( "ScreenFade"), _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0000) // fade type
		write_byte(255) // red
		write_byte(100) // green
		write_byte(100) // blue
		write_byte(140) // alpha
		message_end()
		
		if(!is_user_bot(id)){
			md_removedrawing(id, 1, 100)
			md_removedrawing(id, 1, 101)
		}
	} else {
		message_begin(MSG_ONE, get_user_msgid( "ScreenFade"), _, id)
		write_short((1<<12)*2) // duration
		write_short((1<<10)*10) // hold time
		write_short(0x0004) // fade type
		write_byte(red) // red
		write_byte(green) // green
		write_byte(blue) // blue
		write_byte(alpha) // alpha
		message_end()

		if(!is_user_bot(id)){
			md_drawimage(id, 100, 0, hud[0], 0.5, 0.5, 1, 1, 255, 255, 255, 255, 0.0, 0.0, 0.0)
			md_drawimage(id, 101, 0, hud[1], 0.5, 0.5, 1, 1, 255, 255, 255, 255, 0.0, 0.0, 0.0)
		}
	}
}
public Stock_Fake_KnockBack(id, iVic, Float:iKb)
{
	if(iVic > 32) return
	
	new Float:vAttacker[3], Float:vVictim[3], Float:vVelocity[3], flags
	pev(id, pev_origin, vAttacker)
	pev(iVic, pev_origin, vVictim)
	vAttacker[2] = vVictim[2] = 0.0
	flags = pev(id, pev_flags)
	
	xs_vec_sub(vVictim, vAttacker, vVictim)
	new Float:fDistance
	fDistance = xs_vec_len(vVictim)
	xs_vec_mul_scalar(vVictim, 1 / fDistance, vVictim)
	
	pev(iVic, pev_velocity, vVelocity)
	xs_vec_mul_scalar(vVictim, iKb, vVictim)
	xs_vec_mul_scalar(vVictim, 50.0, vVictim)
	vVictim[2] = xs_vec_len(vVictim) * 0.15
	
	if(flags &~ FL_ONGROUND)
	{
		xs_vec_mul_scalar(vVictim, 1.2, vVictim)
		vVictim[2] *= 0.4
	}
	if(xs_vec_len(vVictim) > xs_vec_len(vVelocity)) set_pev(iVic, pev_velocity, vVictim)
}	

stock Stock_Get_Origin(id, Float:origin[3])
{
	new Float:maxs[3],Float:mins[3]
	if (pev(id, pev_solid) == SOLID_BSP)
	{
		pev(id,pev_maxs,maxs)
		pev(id,pev_mins,mins)
		origin[0] = (maxs[0] - mins[0]) / 2 + mins[0]
		origin[1] = (maxs[1] - mins[1]) / 2 + mins[1]
		origin[2] = (maxs[2] - mins[2]) / 2 + mins[2]
	} else pev(id, pev_origin, origin)
}
stock GetGunPosition(id, Float:vecScr[3])
{
	new Float:vecViewOfs[3]
	pev(id, pev_origin, vecScr)
	pev(id, pev_view_ofs, vecViewOfs)
	xs_vec_add(vecScr, vecViewOfs, vecScr)
}

stock IsPlayer(pEntity) return is_user_connected(pEntity)
stock IsPlayerTeam(pEntity) return get_user_team(pEntity)
stock Stock_BloodEffect(Float:vecOri[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord,vecOri[0])
	engfunc(EngFunc_WriteCoord,vecOri[1])
	engfunc(EngFunc_WriteCoord,vecOri[2]+random_num(15,25))
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(75)
	write_byte(random_num(15,25))
	message_end()
}
stock IsHostage(pEntity)
{
	new classname[32]; pev(pEntity, pev_classname, classname, charsmax(classname))
	return equal(classname, "hostage_entity")
}

public IsAlive(pEntity)
{
	if(!pev_valid(pEntity))
		return 0
	if (pEntity < 1) return 0
	return (pev(pEntity, pev_deadflag) == DEAD_NO && pev(pEntity, pev_health) > 0)
}
stock Get_Position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
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

stock set_player_light(id, const LightStyle[])
{
	message_begin( MSG_ONE, SVC_LIGHTSTYLE, .player = id)
	write_byte(0)
	write_string(LightStyle)
	message_end()
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
