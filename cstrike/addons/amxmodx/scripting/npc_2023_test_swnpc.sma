#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <zombieplague>
#include <fakemeta_util>
#include <sypb>
#include <swnpc>
#include <fun>
#include <zp50_grenade_frost>
#include <cstrike>
//#include <crxranks>

//Boolean of when NPC spawned 
// new bool: g_NpcSpawn[256]; 
// //Boolean to check if NPC is alive or not 
// new bool: g_NpcDead[256]; 
//Classname for our NPC 
new const g_NpcClassName[] = "ent_npc"; 

new const g_NpcClassball[] = "fireball"; 

new Float:KPOWER=900.0

//new const skill_wave_color[3] = {255, 0, 0}


//Constant model for NPC 
new const g_NpcModel[] = "models/phap_su.mdl"; 


new const fire_model[] = "sprites/3dmflared.spr"
new g_exploSpr


const Float:NADE_EXPLOSION_RADIUS = 300.0

const Float:NADE_CHAYDEN_RADIUS = 740.0

const Float:NADE_BANXA_RADIUS = 840.0

const Float:NADE_DONGBANG_RADIUS = 50.0

//List of sounds our NPC will emit when damaged 

new cvar_phapsu;

new const pain_sound1[] = "sorpack/zm/jjrll.wav";

new const get_item[] = "sound/sorpack/zm/emtf.wav";


new const g_NpcSoundPain[][] =  
{ 
    "sorpack/zm/tlldll.wav"
} 

// //Sounds when killed 
// new const g_NpcSoundDeath[][] = 
// { 
//     "barney/ba_die1.wav" 
// } 

// //Sounds when we knife our flesh NPC
// new const g_NpcSoundKnifeHit[][] = 
// {
// 	"weapons/knife_hit1.wav",
// 	"weapons/knife_hit2.wav",
// 	"weapons/knife_hit3.wav",
// 	"weapons/knife_hit4.wav"
// }

// new const g_NpcSoundKnifeStab[] = "weapons/knife_stab.wav";

//List of idle animations 
new const NPC_IdleAnimations[] = { 7, 20, 25};

//Sprites for blood when our NPC is damaged
new spr_blood_drop, spr_blood_spray

//Player cooldown for using our NPC 
//new Float: g_Cooldown[32];

// new countxin[33]
new xinmotnguoi
new dangdichuyen

new g_trailSpr

#define TASKID_CHECK_IDLE 2367
#define TASKID_CHECK_SKILLGAN 2368
#define TASKID_CHECK_SKILLBANXA 2369
#define TASKID_CHECK_CHAYDEN 2370

#define ID_CHECK_SKILLGAN (taskid - TASKID_CHECK_SKILLGAN)
#define ID_CHECK_SKILLBANXA (taskid - TASKID_CHECK_SKILLBANXA)
#define ID_CHECK_IDLE (taskid - TASKID_CHECK_IDLE)
#define ID_CHECK_CHAYDEN (taskid - TASKID_CHECK_CHAYDEN)

new idpressE
// new attacker

new cvar_firespeed

//Boolean to check if we knifed our NPC
new bool: g_Hit[32];

new Float:origin_new_round[3]
new Float:flAngle_newround[3]

public plugin_init()
{
	register_plugin("NPC Plugin", "1.1", "Mazza");
	register_clcmd("say /npc", "ClCmd_NPC", ADMIN_LEVEL_H);
	cvar_firespeed = register_cvar("zp_husk_fire_speed", "700")
	//register_think("fireball", "fw_TrapThink")
	//RegisterHam(Ham_Think, "info_target", "fw_TrapThink");
	cvar_phapsu = register_cvar("zp_danh_phap_su", "1");
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0");
	//register_think(g_NpcClassName,"Think_Hound");
		
	RegisterHam(Ham_TakeDamage, "info_target", "npc_TakeDamage");
	//RegisterHam( Ham_Spawn, "player", "Fw_PlayerSpawnPost", 1 )
	RegisterHam(Ham_Killed, "info_target", "npc_Killed");
	// RegisterHam(Ham_Think, "info_target", "npc_Think");
	// RegisterHam(Ham_TraceAttack, "info_target", "npc_TraceAttack");
	//RegisterHam(Ham_TakeDamage, "info_target", "npc_TakeDamagePre")
    //register_forward(FM_CmdStart , "FakeMeta_CmdStart");
	RegisterHam(Ham_ObjectCaps, "player", "npc_ObjectCaps", 1 );
	register_forward(FM_Touch, "fw_Touch")
	
	//register_forward(FM_EmitSound, "npc_EmitSound"); 
}

public plugin_precache()
{

	spr_blood_drop = precache_model("sprites/blood.spr")
	precache_sound(pain_sound1[0]);	
	precache_generic(get_item[0]);	
	spr_blood_spray = precache_model("sprites/bloodspray.spr")
    g_exploSpr = precache_model("sprites/shockwave.spr")
	g_trailSpr = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr")
	engfunc(EngFunc_PrecacheModel, fire_model)
	
	 new i;
	 for(i = 0 ; i < sizeof g_NpcSoundPain ; i++)
	 	precache_sound(g_NpcSoundPain[i]);
	// for(i = 0 ; i < sizeof g_NpcSoundDeath ; i++)
	// 	precache_sound(g_NpcSoundDeath[i]);

	precache_model(g_NpcModel)
		
}

// public plugin_cfg()
// {
// 	Load_Npc()
// }

public ClCmd_NPC(id)
{
    if(!(get_user_flags(id) & ADMIN_LEVEL_H))
    {
    return
    }


    if(!is_user_alive(id))
    return

	//Create a new menu
	new menu = menu_create("NPC: Main Menu", "Menu_Handler");
	
	//Add some items to the newly created menu
	menu_additem(menu, "Create NPC", "1");
	menu_additem(menu, "Delete NPC", "2");
	menu_additem(menu, "Save current NPC locations", "3");
	menu_additem(menu, "Delete all NPC", "4");
	
	//Let the menu have an 'Exit' option
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	
	//Display our menu
	menu_display(id, menu);
}

public Menu_Handler(id, menu, item)
{
	//If user chose to exit menu we will destroy our menu
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new info[6], szName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, info, charsmax(info), szName, charsmax(szName), callback);
	
	new key = str_to_num(info);
	
	switch(key)
	{
		case 1:
		{
			//Create our NPC
			Create_Npc(id);
		}
		case 2:
		{
			//Remove our NPC by the users aim
			new iEnt, body, szClassname[32];
			get_user_aiming(id, iEnt, body);
			
			if (is_valid_ent(iEnt)) 
			{
				entity_get_string(iEnt, EV_SZ_classname, szClassname, charsmax(szClassname));
				
				if (equal(szClassname, g_NpcClassName)) 
				{
					remove_entity(iEnt);
				}
				
			}
		}
		case 3:
		{
			//Save the current locations of all the NPCs
			Save_Npc();
			
			client_print(id, print_chat, "[AMXX] NPC origin saved succesfully");
		}
		case 4:
		{
			//Remove all NPCs from the map
			remove_entity_name(g_NpcClassName);
			
			client_print(id, print_chat, "[AMXX] ALL NPC origin removed");
		}
	}
	
	//Keep the menu displayed when we choose an option
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public zp_round_started()
{
    

	if(zp_is_nemesis_round() || zp_is_assassin_round() || zp_is_lnj_round() || zp_is_plague_round())
	{
	// remove_entity_name(g_NpcModel);

    // remove_task()

    CBP_KillAllHound()
	return
	}

    Load_Npc()


//  Create_Npc(0, origin_new_round,flAngle_newround)

  
}

public client_disconnect(id)
{
    // countxin[id] = 1
}


public check_origin()
{
	for(new i = 0; i < get_maxplayers() ; i++)
	{
		if(is_user_bot(i))
		{
		pev(i, pev_origin, origin_new_round)	
		entity_get_vector(i, EV_VEC_angles, flAngle_newround);
		flAngle_newround[0] = 0.0;			
		break		
		}
	}
	
}

public Event_NewRound()
{
	// for(new i = 0; i < get_maxplayers(); i++)
	// if(countxin[i] == 1)
	// {
	// 	countxin[i] = 0
	// }
	idpressE = 0
	xinmotnguoi = 0
	set_task(2.0,"check_origin")
}


public zp_round_ended()
{
 	// remove_entity_name(g_NpcModel);

    // remove_task()

    CBP_KillAllHound()
}

public npc_TakeDamage(iEnt, inflictor, attacker, Float:damage, bits)
{
	client_print(attacker, print_center,"Dmg: %f, Hp: %f",damage,entity_get_float(iEnt,EV_FL_health))
    if(!is_valid_ent(iEnt))
        return PLUGIN_HANDLED;    
	//Make sure we only catch our NPC by checking the classname
	new className[32];
	entity_get_string(iEnt, EV_SZ_classname, className, charsmax(className))

	 static Float:origin[3]
	 pev(iEnt, pev_origin, origin)    
	
	if(!equali(className, g_NpcClassName))
		return PLUGIN_HANDLED;

	// if (!zp_get_user_zombie(attacker) && get_pcvar_num(cvar_phapsu) == 1 && is_user_connected(attacker))
	// {
	// 	return HAM_SUPERCEDE;
	// }
	client_print(attacker, print_center,"Hp: %.1f",entity_get_float(iEnt,EV_FL_health))
	//Play a random animation when damanged
	Util_PlayAnimation(iEnt, 12);

	//Make our NPC say something when it is damaged
	//NOTE: Interestingly... Our NPC mouth (which is a controller) moves!! That saves us some work!!
	


    // new victim = -1
    // if(get_user_weapon(attacker) == CSW_KNIFE && zp_get_user_zombie(attacker))
    // {
    // create_blast2(origin)


	// while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, origin, NADE_EXPLOSION_RADIUS)) != 0)
	// {
	// 	// Only effect alive zombies
	// 	if (!is_user_alive(victim) || !zp_get_user_zombie(victim))
	// 		continue;
    //     fm_fakedamage(victim, g_NpcClassName, 7800.0,  DMG_BLAST);
		
	// }    
    
    // }

g_Hit[attacker] = true;
	
	return HAM_IGNORED 
}



public npc_Killed(iEnt,attacker)
{
	new className[32];
	entity_get_string(iEnt, EV_SZ_classname, className, charsmax(className))
	
	if(!equali(className, g_NpcClassName))
		return HAM_IGNORED;

	//Player a death animation once our NPC is killed
	Util_PlayAnimation(iEnt, 35)

	//Because our NPC may look like it is laying down. 
	//The bounding box size is still there and it is impossible to change it so we will make the solid of our NPC to nothing
	entity_set_int(iEnt, EV_INT_solid, SOLID_NOT);

	//The voice of the NPC when it is dead
	//emit_sound(iEnt, CHAN_VOICE, g_NpcSoundDeath[random(sizeof g_NpcSoundDeath)],  VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	if(zp_get_user_zombie(attacker) && is_user_alive(attacker))
	{
		cs_set_user_money(attacker,(cs_get_user_money(attacker) + 3000))
	}
	//Our NPC is dead so it shouldn't take any damage and play any animations
	entity_set_float(iEnt, EV_FL_takedamage, 0.0);
	if(pev_valid(iEnt) && equali(className, g_NpcClassName))
	{
    CBP_KillHound(iEnt)
	}

	//Our death boolean should now be true!!
	//g_NpcDead[iEnt] = true;

	remove_task(iEnt + TASKID_CHECK_IDLE)	
	remove_task(iEnt + TASKID_CHECK_SKILLGAN)
	remove_task(iEnt + TASKID_CHECK_SKILLBANXA)
	remove_task(iEnt + TASKID_CHECK_CHAYDEN)
	//The most important part of this forward!! We have to block the death forward.
	return HAM_SUPERCEDE
}


create_blast2(const Float:origin[3])
{
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+385.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+470.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(50) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+555.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()

	// engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0);
	// write_byte(TE_BEAMCYLINDER);
	// engfunc(EngFunc_WriteCoord, flOrigin[0]); 
	// engfunc(EngFunc_WriteCoord, flOrigin[1]);
	// engfunc(EngFunc_WriteCoord, flOrigin[2]); 
	// engfunc(EngFunc_WriteCoord, flOrigin[0]); 
	// engfunc(EngFunc_WriteCoord, flOrigin[1]); 
	// engfunc(EngFunc_WriteCoord, flOrigin[2] + NADE_EXPLOSION_RADIUS);
	// write_short(g_exploSpr); 
	// write_byte(0); 
	// write_byte(0);
	// write_byte(10);
	// write_byte(25); 
	// write_byte(0); 
	// write_byte(skill_wave_color[0]); 
	// write_byte(skill_wave_color[1]);
	// write_byte(skill_wave_color[2]); 
	// write_byte(200); 
	// write_byte(0); 
	// message_end();	
}


public CBP_KillAllHound()
{
	new ent = -1;
	while((ent = find_ent_by_class(ent,g_NpcClassName)))
	{
		new classNametyranttest[32];
		entity_get_string(ent, EV_SZ_classname, classNametyranttest, charsmax(classNametyranttest))	
		if(pev_valid(ent)  && equali(classNametyranttest, g_NpcClassName))
		{
            CBP_KillHound(ent)
		}
	}
}

// public fw_touch(IEnt,id)
// {
// 	if(!is_user_alive(id))
// 		return HAM_IGNORED

// 	if(zp_get_user_zombie(id))
// 		return HAM_IGNORED

// 	if(!is_user_connected(id))
// 		return HAM_IGNORED 

// 	new iEnt = create_entity("info_target");
	
// 	entity_set_string(iEnt, EV_SZ_classname, g_NpcClassName);

//     if(!zp_get_user_zombie(id) && is_user_alive(id))
//     {
//     fm_fakedamage(id, "Cho can", 3.0,  DMG_BLAST);
//     }



//     return HAM_IGNORED

// }


public CBP_KillHound(ent)
{
	if(pev_valid(ent))
	{
		set_pev(ent,pev_nextthink,0.0);
		set_task(3.0,"remove_valid_entity",ent);

        
        //Load_Npc()
		

	}  
}

public remove_valid_entity(ent)
{
	new classNametyranttest[32];
	if(is_valid_ent(ent))
	{
		entity_get_string(ent, EV_SZ_classname, classNametyranttest, charsmax(classNametyranttest))
		 if(equali(classNametyranttest, g_NpcClassName)) 
		 {
		remove_entity(ent);
		 }

	}
}




public reset_velocity(ent)
{
	static Float:fl_Velocity[3];
	fl_Velocity[0] = 0.0;
	fl_Velocity[1] = 0.0;
	fl_Velocity[2] = 0.0;
	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity);
}


stock hook_ent(entity, target, Float:speed)
{
	
	if (!is_valid_ent(entity) || !is_valid_ent(target)) return 0;
	
	new Float:entity_origin[3], Float:target_origin[3];
	entity_get_vector(entity, EV_VEC_origin, entity_origin);
	entity_get_vector(target, EV_VEC_origin, target_origin);
 
	new Float:diff[3];
	diff[0] = target_origin[0] - entity_origin[0];
	diff[1] = target_origin[1] - entity_origin[1];
	diff[2] = target_origin[2] - entity_origin[2];

	new Float:length = floatsqroot(floatpower(diff[0], 2.0) + floatpower(diff[1], 2.0) + floatpower(diff[2], 2.0));

	new Float:Velocity[3];
	Velocity[0] = diff[0] * (speed / length);
	Velocity[1] = diff[1] * (speed / length);
	Velocity[2] = diff[2] * (speed / length);
	
	entity_set_vector(entity, EV_VEC_velocity, Velocity);
	
	return 1;
}


stock FindClosesEnemy(entid,Float:maxdistance)
{
	new Float:Dist,Float:EntOrigin[3],Float:TargetOrigin[3];
	new indexid=0;
	for(new i=1;i<=get_maxplayers();i++)
	{
		if(is_user_alive(i))
		{
			if(zp_get_user_zombie(i))
			{
				pev(entid,pev_origin,EntOrigin);
				pev(i,pev_origin,TargetOrigin);
				Dist = get_distance_f(TargetOrigin,EntOrigin);
				if(Dist <= maxdistance)
				{
					maxdistance=Dist;
					indexid=i;
					return indexid;
				}
			}	
		}
	}	
	return 0;
}

stock FindClosesEnemy2(entid,Float:maxdistance)
{
	new Float:Dist,Float:EntOrigin[3],Float:TargetOrigin[3];
	new indexid=0;
	for(new i=1;i<=get_maxplayers();i++)
	{
		if(is_user_alive(i))
		{
			if(zp_get_user_zombie(i))
			{
				pev(entid,pev_origin,EntOrigin);
				pev(i,pev_origin,TargetOrigin);
				Dist = get_distance_f(TargetOrigin,EntOrigin);
				if(Dist <= maxdistance)
				{
					maxdistance=Dist;
					indexid=i;
					return indexid;
				}
			}	
		}
	}	
	return 0;
}

stock FindHuman(entid,Float:maxdistance)
{
	new Float:Dist,Float:EntOrigin[3],Float:TargetOrigin[3];
	new indexid=0;
	for(new i=1;i<=get_maxplayers();i++)
	{
		if(is_user_alive(i))
		{
			if(!zp_get_user_zombie(i))
			{
				pev(entid,pev_origin,EntOrigin);
				pev(i,pev_origin,TargetOrigin);
				Dist = get_distance_f(TargetOrigin,EntOrigin);
				if(Dist <= maxdistance)
				{
					maxdistance=Dist;
					indexid=i;
				
					return indexid;
				}
			}	
		}
	}	
	return 0;
}

stock entity_set_aim(ent, player) 
{ 
    static Float:origin[3], Float:ent_origin[3], Float:angles[3] 
    // pev(player, pev_origin, origin) 
    origin[0] = 500.0;
	origin[1] = 500.0;
	origin[2] = 500.0;
    pev(ent, pev_origin, ent_origin) 
     
    xs_vec_sub(origin, ent_origin, origin) 
    xs_vec_normalize(origin, origin) 
    vector_to_angle(origin, angles) 
     
    angles[0] = 0.0 
     
    set_pev(ent, pev_angles, angles)
    new name_ent[32],name_player[32]
    get_user_name(ent,name_ent,charsmax(name_ent))
    get_user_name(player,name_player,charsmax(name_player))
} 

public skill_chayden(taskid)
{
	new iEnt = ID_CHECK_CHAYDEN
	if(!is_valid_ent(iEnt))
		return;
	
	static className[32];
	entity_get_string(iEnt, EV_SZ_classname, className, charsmax(className))
    
	
	if(!equali(className, g_NpcClassName))
		return;	

		new victim = -1
		new Float:EntOrigin[3];
		pev(iEnt,pev_origin,EntOrigin);

		new Float:fOrigin[3],Float:fDistance	
		while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, EntOrigin, NADE_CHAYDEN_RADIUS )) != 0)
		{         
		    if (!is_user_connected(victim))
			    continue;

			// if(zp_get_user_zombie(idpressE))
			// {
			// 	continue;
			// }

			if(victim == idpressE && !zp_get_user_zombie(idpressE))
			{
				pev(victim, pev_origin, fOrigin)
				fDistance = get_distance_f(fOrigin, EntOrigin)
				if(fDistance > 110)
				{
				Util_PlayAnimation(iEnt, 2);
				hook_ent(iEnt,victim,350.0);
				set_pev(iEnt,pev_movetype,MOVETYPE_PUSHSTEP);
				Hound_Turn_To_Taget(iEnt,victim);
				dangdichuyen = true	
				}
				else if(fDistance <= 110)
				{
					Util_PlayAnimation(iEnt, 13);
					dangdichuyen = false
				}
			
			}	
			// else
			// {
			// 		Util_PlayAnimation(iEnt, 13);
			// 		dangdichuyen = false				
			// }		 
		}
		set_task(0.55,"skill_chayden",iEnt + TASKID_CHECK_CHAYDEN )			
}

public skill_banxa(taskid)
{
	new iEnt = ID_CHECK_SKILLBANXA
	if(!is_valid_ent(iEnt))
		return;
	
	static className[32];
	entity_get_string(iEnt, EV_SZ_classname, className, charsmax(className))
    
	
	if(!equali(className, g_NpcClassName))
		return;


		new victim = -1
		new Float:EntOrigin[3];
		pev(iEnt,pev_origin,EntOrigin);

		while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, EntOrigin, NADE_BANXA_RADIUS )) != 0)
		{         
		    if (!is_user_connected(victim))
			    continue;

			if(zp_get_user_zombie(victim) && !dangdichuyen)
			{
				entity_set_aim(iEnt,victim)
				MakeFire(iEnt,victim)
				Util_PlayAnimation(iEnt, 59)
				emit_sound(iEnt, CHAN_WEAPON, pain_sound1[0], 1.0, ATTN_NORM, 0, PITCH_NORM);
				Hound_Turn_To_Taget(iEnt,victim);  
			}				 
		}		
		set_task(2.5,"setveidle",iEnt + TASKID_CHECK_IDLE)

	set_task(6.0,"skill_banxa",iEnt + TASKID_CHECK_SKILLBANXA)	
}


public skill_gan(taskid)
{
	new iEnt = ID_CHECK_SKILLGAN
	if(!is_valid_ent(iEnt))
		return;
	
	static className[32];
	entity_get_string(iEnt, EV_SZ_classname, className, charsmax(className))
    
	
	if(!equali(className, g_NpcClassName))
		return;


		new victim = -1
		new Float:EntOrigin[3];
		pev(iEnt,pev_origin,EntOrigin);

		new Float:fDistance,Float:fDamage
		while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, EntOrigin, NADE_EXPLOSION_RADIUS )) != 0)
		{         
		    if (!is_user_connected(victim))
			    continue;


			if(zp_get_user_zombie(victim) && is_user_alive(victim))
			{
            create_blast2(EntOrigin)                    
            Util_PlayAnimation(iEnt, NPC_IdleAnimations[random(sizeof NPC_IdleAnimations)]);                     
			reset_velocity(iEnt);   

			if(is_user_connected(idpressE) && !zp_get_user_zombie(idpressE))	
			{

			ExecuteHamB(Ham_TakeDamage, victim, idpressE, idpressE, 600.0, DMG_NEVERGIB)	
			}
			else
			{
				fm_fakedamage(victim, g_NpcClassName, 70.0,  DMG_BLAST)
			}	

			fDamage = KPOWER - floatmul(KPOWER, floatdiv(fDistance, NADE_EXPLOSION_RADIUS))//get the damage value
			fDamage *= EstimateDamage(EntOrigin, victim, 0)
			if ( fDamage < 0 ) continue
			CreateBombKnockBack(victim,EntOrigin,fDamage,KPOWER)
			emit_sound(iEnt, CHAN_VOICE, g_NpcSoundPain[random(sizeof g_NpcSoundPain)],  VOL_NORM, ATTN_NORM, 0, PITCH_NORM)	
			}
			 
		}		
		set_task(2.5,"setveidle",iEnt + TASKID_CHECK_IDLE)

	set_task(4.0,"skill_gan",iEnt + TASKID_CHECK_SKILLGAN)	
}


public zp_user_infected_post(id)
{
	if(id == idpressE)
	{
		idpressE = 0
		dangdichuyen = false
	}
}


public setveidle(taskid)
{
	new iEnt = TASKID_CHECK_IDLE

	if(!is_valid_ent(iEnt))
		return;
	
	static className[32];
	entity_get_string(iEnt, EV_SZ_classname, className, charsmax(className))
    
	
	if(!equali(className, g_NpcClassName))
		return;

	Util_PlayAnimation(iEnt, 13)
}

// public npc_Think(iEnt)
// {
// 	if(!is_valid_ent(iEnt))
// 		return;
	
// 	static className[32];
// 	entity_get_string(iEnt, EV_SZ_classname, className, charsmax(className))
    
	
// 	if(!equali(className, g_NpcClassName))
// 		return;
	
//     if(pev_valid(iEnt))
// 	{
// 		new Target = FindClosesEnemy(iEnt,700.0);
// 		new Float:EntOrigin[3],Float:TargetOrigin[3],Float:Distance;	

// 		pev(iEnt,pev_origin,EntOrigin);
// 		pev(Target,pev_origin,TargetOrigin);
// 		Distance = get_distance_f(TargetOrigin,EntOrigin);
//         new Float:fOrigin[3],Float:fDistance,Float:fDamage
// 		if(is_user_alive(Target) && zp_get_user_zombie(Target))
// 		{
// 			if(Distance > 640.0)
// 				{
// 					//client_print(0, print_chat,"npc chuong o xa")
//                     Util_PlayAnimation(iEnt, 59)
//                     Hound_Turn_To_Taget(iEnt,Target);                      
// 					// MakeFire(iEnt)                        
//                     emit_sound(iEnt, CHAN_WEAPON, pain_sound1[0], 1.0, ATTN_NORM, 0, PITCH_NORM);
// 					set_pev(iEnt,pev_nextthink,get_gametime() + 7.5);
// 				}      
// 		}
//         else
// 		{  
// 		client_print(0, print_chat,"npc dung im")	             
//         Util_PlayAnimation(iEnt, 13)
// 		set_pev(iEnt,pev_nextthink,get_gametime() + 1.0);
        
//         }   
// 		client_print(0, print_chat,"npc ngoai ham")
// 	}
// }

stock CreateBombKnockBack(iVictim,Float:vAttacker[3],Float:fMulti,Float:fRadius){
new Float:vVictim[3];
pev(iVictim, pev_origin, vVictim);
xs_vec_sub(vVictim, vAttacker, vVictim);
xs_vec_mul_scalar(vVictim, fMulti * 0.7, vVictim);
xs_vec_mul_scalar(vVictim, fRadius / xs_vec_len(vVictim), vVictim);
set_pev(iVictim, pev_velocity, vVictim);
}
stock ScreenShake(id, amplitude = 8, duration = 6, frequency = 18){
message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
write_short((1<<12)*amplitude)
write_short((1<<12)*duration)
write_short((1<<12)*frequency)
message_end()
}

stock Float:EstimateDamage(Float:fPoint[3], ent, ignored) {
new Float:fOrigin[3]
new tr
new Float:fFraction
pev(ent, pev_origin, fOrigin)
engfunc(EngFunc_TraceLine, fPoint, fOrigin, DONT_IGNORE_MONSTERS, ignored, tr)
get_tr2(tr, TR_flFraction, fFraction)
if ( fFraction == 1.0 || get_tr2( tr, TR_pHit ) == ent )//no valid enity between the explode point & player
return 1.0
return 0.6//if has fraise, lessen blast hurt
}


public MakeFire(id,victim)
{
	new Float:Origin[3]
	new Float:vAngle[3]
	new Float:flVelocity[3]
	
	// Get position from eyes
	get_user_eye_position(id, Origin)
	
	// Get View Angles
	entity_get_vector(id, EV_VEC_v_angle, vAngle)
	
	new NewEnt = create_entity("info_target")
	
	entity_set_string(NewEnt, EV_SZ_classname, g_NpcClassball)
	
	entity_set_model(NewEnt, fire_model)
	
	entity_set_size(NewEnt, Float:{ -1.5, -1.5, -1.5 }, Float:{ 1.5, 1.5, 1.5 })
	
	entity_set_origin(NewEnt, Origin)
	entity_set_float(NewEnt, EV_FL_gravity, 1.0)
	
	// Set Entity Angles (thanks to Arkshine)
	make_vector(vAngle)
	entity_set_vector(NewEnt, EV_VEC_angles, vAngle)
	
	entity_set_int(NewEnt, EV_INT_solid, SOLID_BBOX)
	
	entity_set_float(NewEnt, EV_FL_scale, 0.3)
	entity_set_int(NewEnt, EV_INT_spawnflags, SF_SPRITE_STARTON)
	entity_set_float(NewEnt, EV_FL_framerate, 25.0)
	set_rendering(NewEnt, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)
	
	entity_set_int(NewEnt, EV_INT_movetype, MOVETYPE_FLY)
	entity_set_edict(NewEnt, EV_ENT_owner, id)
	
	// Set Entity Velocity
	//velocity_by_aim(id, get_pcvar_num(cvar_firespeed), flVelocity)
	VelocityByAim(id, get_pcvar_num(cvar_firespeed), flVelocity)
	entity_set_vector(NewEnt, EV_VEC_velocity, flVelocity)

	victim = FindClosesEnemy2(NewEnt,1000.0);

	if(is_user_alive(victim) && zp_get_user_zombie(victim))
	{
		hook_ent(NewEnt,victim,1550.0);
        //Hound_Turn_To_Taget(NewEnt,Target);
		//set_pev(NewEnt,pev_movetype,MOVETYPE_PUSHSTEP);
		//client_print(0, print_chat,"dang di chuyen")
		set_pev(NewEnt,pev_nextthink,get_gametime() + 0.1);			
	}	
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // TE id
	write_short(NewEnt) // entity
	write_short(g_trailSpr) // sprite
	write_byte(5) // life
	write_byte(6) // width
	write_byte(255) // r
	write_byte(0) // g
	write_byte(0) // b
	write_byte(255) // brightness
	message_end()
	
}

public fw_Touch(ent, id)
{
	if (!pev_valid(ent)) 
		return PLUGIN_HANDLED
	
	new class[32]
	pev(ent, pev_classname, class, charsmax(class))
	
	if(equal(class, g_NpcClassball))
	{
		// attacker = entity_get_edict(ent, EV_ENT_owner)
		husk_touch(ent)
		engfunc(EngFunc_RemoveEntity, ent)
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public husk_touch(ent)
{
	if (!pev_valid(ent)) 
		return;
	
	// Get origin
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	
	
	
	// Collisions
	static victim
	victim = -1
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, NADE_DONGBANG_RADIUS)) != 0)
	{
		// Only effect alive zombies
		if (!is_user_alive(victim) || !zp_get_user_zombie(victim))
			continue;


	//zp_dong_bang_set(victim,true)
		// switch(random_num(0,1))
		// {

		
		// case 0 :
		// {
		// 	zp_dong_bang_set(victim, true)
		// }
		// case 1 :
		// {
		// 	zp_thieu_dot_set(victim,true)
		// }
		// }

			
	}
}


stock get_user_eye_position(id, Float:flOrigin[3])
{
	static Float:flViewOffs[3]
	entity_get_vector(id, EV_VEC_view_ofs, flViewOffs)
	entity_get_vector(id, EV_VEC_origin, flOrigin)
	xs_vec_add(flOrigin, flViewOffs, flOrigin)
}

stock make_vector(Float:flVec[3])
{
	flVec[0] -= 30.0
	engfunc(EngFunc_MakeVectors, flVec)
	flVec[0] = -(flVec[0] + 30.0)
}

public npc_TraceAttack(iEnt, attacker, Float: damage, Float: direction[3], trace, damageBits)
{


      

	if(!is_valid_ent(iEnt))
		return PLUGIN_HANDLED;
	
	new className[32];
	entity_get_string(iEnt, EV_SZ_classname, className, charsmax(className))
	
	if(!equali(className, g_NpcClassName))
		return PLUGIN_HANDLED;

	if (!zp_get_user_zombie(attacker) && get_pcvar_num(cvar_phapsu) == 1)
	{
		return HAM_SUPERCEDE;
	}
		
	//Retrieve the end of the trace
	new Float: end[3]
	get_tr2(trace, TR_vecEndPos, end);


	
	//This message will draw blood sprites at the end of the trace
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, end[0])
	engfunc(EngFunc_WriteCoord, end[1])
	engfunc(EngFunc_WriteCoord, end[2])
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(247) // color index
	write_byte(random_num(1, 5)) // size
	message_end()

	return HAM_IGNORED 
}

public npc_ObjectCaps(id)
{
	//Make sure player is alive
	if(!is_user_alive(id) || xinmotnguoi >=1)
		return;

    if(zp_get_user_zombie(id))
        return;    

	//Check when player presses +USE key
	if(get_user_button(id) & IN_USE)
	{		

			//Get the classname of whatever ent we are looking at
			static iTarget, iBody, szAimingEnt[32];
			get_user_aiming(id, iTarget, iBody, 75);
			entity_get_string(iTarget, EV_SZ_classname, szAimingEnt, charsmax(szAimingEnt));
			
			//Make sure our aim is looking at a NPC
			if(equali(szAimingEnt, g_NpcClassName))
			{
				idpressE = id
				xinmotnguoi++
                // if(countxin[id] == 0)
                // {
				// //Do more fancy stuff here such as opening a menu
				// //But for this tutorial I will only display a message to prove it works
                // Hound_Turn_To_Taget(iTarget,id)
                // Util_PlayAnimation(iTarget, 28)
				// switch(random_num(0,7))
				// {
				// 	case 0:
				// 	{
                // 		cs_set_user_money(id,(cs_get_user_money(id)+ random_num(2000,10000)))
				// 		client_print(id, print_chat, "Bạn được pháp sư cho ít tiền");
                // 		countxin[id]++
				// 		//return;
				// 	}
				// 	case 1:
				// 	{
                // 		set_user_health(id,(get_user_health(id)+ random_num(10,30)))
				// 		client_print(id, print_chat, "Bạn được pháp sư cho ít hp");
                // 		countxin[id]++
				// 		//return;						
				// 	}
				// 	case 2:
				// 	{
                // 		set_user_armor(id,(get_user_armor(id)+ random_num(10,30)))
				// 		client_print(id, print_chat, "Bạn được pháp sư cho ít giáp");
                // 		countxin[id]++
				// 		//return;							
				// 	}
				// 	case 3:
				// 	{
				// 		fm_give_item(id, "weapon_hegrenade")
				// 		// BP ammo
				// 		fm_set_user_bpammo(id, CSW_HEGRENADE, 2)
				// 		client_print(id, print_chat, "Bạn được pháp sư cho 1 quả nade");
                // 		countxin[id]++
				// 		//return;							
				// 	}
				// 	case 4:
				// 	{
				// 		fm_give_item(id, "weapon_flashbang")
				// 		// BP ammo
				// 		fm_set_user_bpammo(id, CSW_FLASHBANG, 2)
				// 		client_print(id, print_chat, "Bạn được pháp sư cho 1 quả flashbang");
                // 		countxin[id]++
				// 		//return;							
				// 	}
				// 	case 5:
				// 	{
				// 		fm_give_item(id, "weapon_smokegrenade")
				// 		// BP ammo
				// 		fm_set_user_bpammo(id, CSW_SMOKEGRENADE, 2)
				// 		client_print(id, print_chat, "Bạn được pháp sư cho 1 quả smoke");
                // 		countxin[id]++
													
				// 	}
				// 	case 6:
				// 	{
				// 		crxranks_give_user_xp(id, random_num(1,10))	
				// 		client_print(id, print_chat, "Bạn được pháp sư cho 1 chút xp");
                // 		countxin[id]++
													
				// 	}
				// 	case 7:
				// 	{
				// 		zp_set_user_ammo_packs(id,(zp_get_user_ammo_packs(id) + 1))
				// 		client_print(id, print_chat, "Bạn được pháp sư cho 1 coin");
                // 		countxin[id]++
													
				// 	}																				
				// }

				// emit_sound(iTarget, CHAN_WEAPON, get_item[0], 1.0, ATTN_NORM, 0, PITCH_NORM);
				client_cmd(0,"spk ^"%s^"",get_item[0])
				static name[33]
				get_user_name(idpressE,name,charsmax(name))
				set_dhudmessage(137, 0, 0, -1.0, 0.1, 1, 3.0, 5.0,0.1,0.2)
				show_dhudmessage(0,"Người chơi %s đã bái sư",name)	
				// return;
                // }               
			}
			
	}
}



stock fm_set_user_bpammo(id, weaponid, amnt) 
{ 
    static offset; 
    switch(weaponid) 
    { 
        case CSW_AWP: offset = 377; 
        case CSW_SCOUT,CSW_AK47,CSW_G3SG1: offset = 378; 
        case CSW_M249: offset = 379;         
        case CSW_FAMAS,CSW_M4A1,CSW_AUG,CSW_SG550,CSW_GALI,CSW_SG552: offset = 380; 
        case CSW_M3,CSW_XM1014: offset = 381; 
        case CSW_USP,CSW_UMP45,CSW_MAC10: offset = 382; 
        case CSW_FIVESEVEN,CSW_P90: offset = 383; 
        case CSW_DEAGLE: offset = 384; 
        case CSW_P228: offset = 385; 
        case CSW_GLOCK18,CSW_MP5NAVY,CSW_TMP,CSW_ELITE: offset = 386; 
        case CSW_FLASHBANG: offset = 387; 
        case CSW_HEGRENADE: offset = 388; 
        case CSW_SMOKEGRENADE: offset = 389; 
        default: return 0; 
    } 
    set_pdata_int(id,offset,amnt,5); 
     
    return 1; 
}


Create_Npc(id, Float:flOrigin[3]= { 0.0, 0.0, 0.0 }, Float:flAngle[3]= { 0.0, 0.0, 0.0 } )
{
	//Create an entity using type 'info_target'
	new iEnt = swnpc_add_npc(g_NpcClassName, g_NpcModel, 500.0, 340.0, 1, flOrigin);
	swnpc_set_sequence_name (iEnt, "idle1", "run", "ref_shoot_knife", "gut_flinch", "death1");

	//Set our entity to have a classname so we can filter it out later
	entity_set_string(iEnt, EV_SZ_classname, g_NpcClassName);
	//If a player called this function
	if(id)
	{
		//Retrieve the player's origin
		entity_get_vector(id, EV_VEC_origin, flOrigin);
		//Set the origin of the NPC to the current players location
		entity_set_origin(iEnt, flOrigin);
		//Increase the Z-Axis by 80 and set our player to that location so they won't be stuck
		flOrigin[2] += 80.0;
		entity_set_origin(id, flOrigin);
		
		//Retrieve the player's  angle
		entity_get_vector(id, EV_VEC_angles, flAngle);
		//Make sure the pitch is zeroed out
		flAngle[0] = 0.0;
		//Set our NPC angle based on the player's angle
		entity_set_vector(iEnt, EV_VEC_angles, flAngle);
	}
	//If we are reading from a file
	else 
	{
		//Set the origin and angle based on the values of the parameters
		// client_print(0,print_chat,"%f",flOrigin[0])
		// if(flOrigin[0] == 0)
		// {
		// 	entity_set_origin(iEnt, origin_new_round);
		// 	entity_set_vector(iEnt, EV_VEC_angles, flAngle_newround);
		// }
		// else
		// {
			entity_set_origin(iEnt, flOrigin);
			entity_set_vector(iEnt, EV_VEC_angles, flAngle);
		// }

	}

	//Set our NPC to take damange and how much health it has
	entity_set_float(iEnt, EV_FL_takedamage, 0.7);
	entity_set_float(iEnt, EV_FL_health,700.0);

	//Set a model for our NPC
	entity_set_model(iEnt, g_NpcModel);
	//Set a movetype for our NPC
	entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_PUSHSTEP);
	//Set a solid for our NPC
	entity_set_int(iEnt, EV_INT_solid, SOLID_BBOX);
    entity_set_int(iEnt, EV_INT_sequence, 2)
    set_pev( iEnt, pev_gravity, 11.0 )
	
	
	//Create a bounding box for oru NPC
	new Float: mins[3] = {-12.0, -12.0, 0.0 }
	new Float: maxs[3] = { 12.0, 12.0, 75.0 }

	entity_set_size(iEnt, mins, maxs);
	
	//Controllers for our NPC. First controller is head. Set it so it looks infront of itself
	//entity_set_byte(iEnt,EV_BYTE_controller1,125);
	// entity_set_byte(ent,EV_BYTE_controller2,125);
	// entity_set_byte(ent,EV_BYTE_controller3,125);
	// entity_set_byte(ent,EV_BYTE_controller4,125);
	
	//Drop our NPC to the floor
	drop_to_floor(iEnt);
	
	// set_rendering( ent, kRenderFxDistort, 0, 0, 0, kRenderTransAdd, 127 );
	
	//We just spawned our NPC so it should not be dead
	// g_NpcSpawn[iEnt] = true;
	// g_NpcDead[iEnt] = false;
	
	//Make it instantly think
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 0.1)
	set_task(1.0,"skill_gan",iEnt + TASKID_CHECK_SKILLGAN)
	set_task(2.0,"skill_chayden",iEnt + TASKID_CHECK_CHAYDEN)	
	set_task(2.0,"skill_banxa",iEnt + TASKID_CHECK_SKILLBANXA)	
	// skill_gan(iEnt)
	sypb_set_entity_action(iEnt,1,1)
	Util_PlayAnimation(iEnt, 13)
}

stock Hound_Turn_To_Taget(ent,target) 
{
	new Float:Vic_Origin[3], Float:Ent_Origin[3];
	pev(ent,pev_origin,Ent_Origin);
	pev(target,pev_origin,Vic_Origin);
	
	if(target) 
	{
		new Float:newAngle[3];
		entity_get_vector(ent, EV_VEC_angles, newAngle);
		new Float:x = Vic_Origin[0] - Ent_Origin[0];
		new Float:z = Vic_Origin[1] - Ent_Origin[1];

		new Float:radians = floatatan(z/x, radian);
		newAngle[1] = radians * (180 / 3.14);
		
		if (Vic_Origin[0] < Ent_Origin[0])
			newAngle[1] -= 180.0;
		entity_set_vector(ent, EV_VEC_angles, newAngle);
	}
}


Load_Npc()
{
	//Get the correct filepath and mapname
	new szConfigDir[256], szFile[256], szNpcDir[256];
	
	get_configsdir(szConfigDir, charsmax(szConfigDir));
	
	new szMapName[32];
	get_mapname(szMapName, charsmax(szMapName));
	
	formatex(szNpcDir, charsmax(szNpcDir),"%s/NPC", szConfigDir);
	formatex(szFile, charsmax(szFile),  "%s/%s.cfg", szNpcDir, szMapName);
		
	//If the filepath does not exist then we will make one
	if(!dir_exists(szNpcDir))
	{
		mkdir(szNpcDir);
	}
	
	//If the map config file does not exist we will make one
	if(!file_exists(szFile))
	{
		write_file(szFile, "");
	}
	
	//Variables to store when reading our file
	new szFileOrigin[3][32]
	new sOrigin[128], sAngle[128];
	new Float:fOrigin[3], Float:fAngles[3];
	new iLine, iLength, sBuffer[256];
	fOrigin[0] = 0.0
	//When we are reading our file...
	while(read_file(szFile, iLine++, sBuffer, charsmax(sBuffer), iLength))
	{
		//Move to next line if the line is commented
		if((sBuffer[0]== ';') || !iLength)
			continue;
		
		//Split our line so we have origin and angle. The split is the vertical bar character
		strtok(sBuffer, sOrigin, charsmax(sOrigin), sAngle, charsmax(sAngle), '|', 0);
				
		//Store the X, Y and Z axis to our variables made earlier
		parse(sOrigin, szFileOrigin[0], charsmax(szFileOrigin[]), szFileOrigin[1], charsmax(szFileOrigin[]), szFileOrigin[2], charsmax(szFileOrigin[]));
		
		fOrigin[0] = str_to_float(szFileOrigin[0]);
		fOrigin[1] = str_to_float(szFileOrigin[1]);
		fOrigin[2] = str_to_float(szFileOrigin[2]);
				
		//Store the yawn angle
		fAngles[1] = str_to_float(sAngle[1]);


		// if(fOrigin[0] == 0.0)
		// {
		// 	Create_Npc(0, origin_new_round,flAngle_newround)
		// }
		// else
		// {
			Create_Npc(0, fOrigin, fAngles)
		// }
		
		//Create our NPC
		
		
		//Keep reading the file until the end
	}
	if(fOrigin[0] == 0.0)
	{
		Create_Npc(0, origin_new_round,flAngle_newround)
	}
}


Save_Npc()
{
	//Variables
	new szConfigsDir[256], szFile[256], szNpcDir[256];
	
	//Get the configs directory.
	get_configsdir(szConfigsDir, charsmax(szConfigsDir));
	
	//Get the current map name
	new szMapName[32];
	get_mapname(szMapName, charsmax(szMapName));
	
	//Format 'szNpcDir' to ../configs/NPC
	formatex(szNpcDir, charsmax(szNpcDir),"%s/NPC", szConfigsDir);
	//Format 'szFile to ../configs/NPC/mapname.cfg
	formatex(szFile, charsmax(szFile), "%s/%s.cfg", szNpcDir, szMapName);
		
	//If there is already a .cfg for the current map. Delete it
	if(file_exists(szFile))
		delete_file(szFile);
	
	//Variables
	new iEnt = -1, Float:fEntOrigin[3], Float:fEntAngles[3];
	new sBuffer[256];
	
	//Scan and find all of my custom ents
	while( ( iEnt = find_ent_by_class(iEnt, g_NpcClassName) ) )
	{
		//Get the entities' origin and angle
		entity_get_vector(iEnt, EV_VEC_origin, fEntOrigin);
		entity_get_vector(iEnt, EV_VEC_angles, fEntAngles);
		
		//Format the line of one custom ent.
		formatex(sBuffer, charsmax(sBuffer), "%d %d %d | %d", floatround(fEntOrigin[0]), floatround(fEntOrigin[1]), floatround(fEntOrigin[2]), floatround(fEntAngles[1]));
		
		//Finally write to the mapname.cfg file and move on to the next line
		write_file(szFile, sBuffer, -1);
		
		//We are currentlying looping to find all custom ents on the map. If found another ent. Do the above till there is none.
	}
	
}

stock Util_PlayAnimation(index, sequence, Float: framerate = 1.0)
{
	entity_set_float(index, EV_FL_animtime, get_gametime());
	entity_set_float(index, EV_FL_framerate,  framerate);
	entity_set_float(index, EV_FL_frame, 0.0);
	entity_set_int(index, EV_INT_sequence, sequence);
}

stock Util_Dungim(index, sequence = 13, Float: framerate = 1.0)
{
	entity_set_float(index, EV_FL_animtime, get_gametime());
	entity_set_float(index, EV_FL_framerate,  framerate);
	entity_set_float(index, EV_FL_frame, 0.0);
	entity_set_int(index, EV_INT_sequence, sequence);
}