
/*
* This is SwNPC for AMXX
* Version : 1.50
* Support Build: 1.50.5414.125
* By ' HsK-Dev Blog By CCN
*
* Support SyPB Build: 1.50.5337.769 or new
*
* Date: 2/5/2019
*/

#include <amxmodx>
#include <sypb>
#include <swnpc>
#include <xs>
#include <zombieplague>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <engine>
#include <cstrike>

#define PLUGIN	"SwNPvC Preview Plug-in [Demo]"
#define VERSION	"1.50v.5414.125"
#define AUTHOR	"ffdg@HsK"

#define NPC_CLASSNAME "npc_zombie"

#define TASKID_NPC 1242255

new const team1_model[] = "models/player/zombie_original/zombie_original.mdl"

// new countNpc = 0


#define TASKID_CHECK_SKILLBANXA 2369



#define ID_CHECK_SKILLBANXA (taskid - TASKID_CHECK_SKILLBANXA)


new Float:origin_new_round_npc[3]

new const Sound_Kill_NPC[][] =
{
	"sound/events/task_complete.wav"
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say get", "get_origin",ADMIN_CHAT)
	register_clcmd("say do", "add_swnpc_team1")
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	// RegisterHam(Ham_Killed, "info_target", "npc_Killed");
	//load_ranspawn();
}

public plugin_precache()
{
	precache_model(team1_model);
	precache_generic(Sound_Kill_NPC[0])
	//precache_model(team2_model);
	// precache_sound ("weapon/knife_slash1.wav");
	// precache_sound ("player/bhit_flesh-1.wav");
	// precache_sound ("player/bhit_flesh-2.wav");
	// precache_sound ("player/die3.wav");
}

public SwNPC_Remove(iEnt)
{
	// countNpc--
	remove_task(iEnt + TASKID_CHECK_SKILLBANXA)
}

// public npc_Killed(iEnt,attacker)
// {
// 	new className[32];
// 	entity_get_string(iEnt, EV_SZ_classname, className, charsmax(className))
	
// 	if(!equali(className, NPC_CLASSNAME))
// 		return HAM_IGNORED;

// 	client_print(0,print_chat,"chuan bi them npc")
// 	set_task(15.0,"add_swnpc_team1")

// }

// public Event_NewRound() 
// {
// 	set_task(3.0,"check_origin_npc")
// 	// countNpc = 0
// }


public check_origin_npc()
{
	for(new i = 0; i < get_maxplayers() ; i++)
	{
		if(is_user_bot(i))
		{
		pev(i, pev_origin, origin_new_round_npc)	
		break		
		}
	}
}

public SwNPC_Add(iEnt)
{
	//set_task(2.0,"check_ban_lua",iEnt + TASKID_CHECK_SKILLBANXA)
}


// public SwNPC_Think_Post (ent)
// {
// 	new className_killer[32];
// 	entity_get_string(ent, EV_SZ_classname, className_killer, charsmax(className_killer))
// 	if(!equali(className_killer, NPC_CLASSNAME))
// 		return HAM_IGNORED;	

// 	phong_cau_lua(ent)

// 	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 7.0);	
// }

public zp_round_started()
{
	
	// set_task (1.5,"them_npc");
	set_task (3.5,"them_npc");
	// return
}

public them_npc()
{
	if(zp_get_zombie_count() <= 0)
	{
		return
	}

	if(get_swnpc_num() < 5)
	{
		client_print(0,print_chat,"them npc")
		add_swnpc_team1()
	}
	set_task(1.0,"them_npc",TASKID_NPC)
}

public zp_round_ended()
{
	CBP_KillAllNPC()
	remove_task(TASKID_NPC)
}

public CBP_KillAllNPC()
{
	new ent = -1;
	while((ent = find_ent_by_class(ent,NPC_CLASSNAME)))
	{
		new classNametyranttest[32];
		entity_get_string(ent, EV_SZ_classname, classNametyranttest, charsmax(classNametyranttest))			
		if(pev_valid(ent) && equal(classNametyranttest, NPC_CLASSNAME))
		{
            //SwNPC_FakeKill(ent)
		}
	}
}


public get_origin(id)
{
	if((get_user_flags(id) & ADMIN_CHAT))
	{
		new Float:origin[3]
		pev(id, pev_origin, origin)
		//g_Origin = origin

		client_print(id,print_chat,"%.1f",origin[0])
		client_print(id,print_chat,"%.1f",origin[1])
		client_print(id,print_chat,"%.1f",origin[2])
	}

	
}


// public SwNPC_TakeDamage_Post(victim, killer)
// {
// 	new className_killer[32];
// 	// entity_get_string(victim, EV_SZ_classname, className_killer, charsmax(className_killer))
// 	// if(!equali(className_killer, NPC_CLASSNAME))
// 	// 	return HAM_IGNORED;	

// 	if(is_user_connected(killer))
// 	{
// 	if(zp_get_user_zombie(killer) && is_user_alive(killer) && is_user_connected(killer) && is_user_bot(killer))
// 	{
// 		//SwNPC_FakeKill(victim)
// 	}
// 	}

// 	//client_print(killer, print_center,"Hp: %.1f",entity_get_float(victim,EV_FL_health))	
	
// 	return PLUGIN_CONTINUE		
// }


// public SwNPC_TakeDamage_Pre(victim, killer)
// {
// 	new className_killer[32];
// 	entity_get_string(victim, EV_SZ_classname, className_killer, charsmax(className_killer))
// 	if(!equali(className_killer, NPC_CLASSNAME))
// 		return HAM_IGNORED;	


// 	client_print(killer, print_center,"Hp: %.1f",entity_get_float(victim,EV_FL_health))	
	
// 	return PLUGIN_CONTINUE		
// }

public add_swnpc_team1()
{
	if(zp_get_zombie_count() <= 0)
	{
		client_print(0,print_chat,"giet npc vi zombie chua xuat hien")
		return PLUGIN_CONTINUE

	}
	static ent
	ent = swnpc_add_npc(NPC_CLASSNAME, team1_model, 500.0, 340.0, 0, origin_new_round_npc);

	// swnpc_set_sequence_name (ent, "idle1", "run", "ref_shoot_knife", "gut_flinch", "death1");
	swnpc_set_sequence_name (ent, "idle1", "run", "ref_shoot_knife", "gut_flinch", "death1");
	//swnpc_set_attack_damage (ent, 20.0);
	// swnpc_set_attack_delay_time (ent, 0.5);

	client_print(0,print_chat,"npc da duoc tao")

	if(get_swnpc_num() >= 7)
	{
		client_print(0,print_chat,"npc qua 7 thang nen xoa di")
		//SwNPC_FakeKill(ent)
		return PLUGIN_HANDLED		
	}


	return PLUGIN_HANDLED	
}