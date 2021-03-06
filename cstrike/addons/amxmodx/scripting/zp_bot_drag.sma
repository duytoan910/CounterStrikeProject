/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <zombieplague>

#define PLUGIN "New Plug-In"
#define VERSION "1.0"
#define AUTHOR "author"

new bool: g_has_drag[33],g_Line,g_hooked[33], bool: g_drag_i[33], g_unable2move[33]
public plugin_init()
{
	RegisterHam(Ham_Spawn, "player", "fw_spawn_post", 1)
	register_event("DeathMsg", "player_death", "a")
	register_clcmd("+drag","drag_start")
	register_clcmd("-drag","drag_end")
	
}
public plugin_precache()
{
	g_Line = precache_model("sprites/zbeam4.spr")
}
public fw_spawn_post(id)
{
	g_has_drag[id] = true
}
public player_death()
{
	new attacker = read_data(1)
	new id = read_data(2)
	
	if (g_hooked[attacker])
		drag_end(id)
}
public drag_start(id)
{		
	if (g_has_drag[id] && !g_drag_i[id]) 
	{
		new hooktarget, body
		get_user_aiming(id, hooktarget, body)
		
		if (is_user_alive(hooktarget)) 
		{
			g_hooked[id] = hooktarget

			new parm[2]
			parm[0] = id
			parm[1] = hooktarget
			
			set_task(0.1, "reelin_player", id, parm, 2, "b")
			harpoon_target(parm)
			
			zp_disinfect_user(hooktarget)
			
			g_drag_i[id] = true
			g_unable2move[hooktarget] = true

		} else {

			static i, Float:Origin[3],Classname[16]			
			fm_get_aim_origin(id, Origin)
			
			while((i = find_ent_in_sphere(i, Origin, 100.0)) != 0)
			{
				if(is_user_connected(i))continue
				pev(i, pev_classname, Classname, charsmax(Classname))   
				if(!equal(Classname,"weaponbox"))continue 
				break;
			} 
			if(pev_valid(i))
			{
				new parm[2]
				parm[0] = id
				parm[1] = i
				
				set_task(0.1, "reelin_player", id, parm, 2, "b")
				harpoon_target(parm)	
				
				g_hooked[id] = i
				g_drag_i[id] = true
			}else{
				g_hooked[id] = 33
				noTarget(id)
				g_drag_i[id] = true
			}			
		}
	}
	else
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public reelin_player(parm[])
{
	new id = parm[0]
	new ent = parm[1]

	if (!g_hooked[id] || !pev_valid(ent))
	{
		drag_end(id)
		return
	}

	new Float:Speed
	new Float:idOrigin[3]
	pev(id, pev_origin, idOrigin)
	//get_user_origin(id, idOrigin)
	
	if(1 <= ent <= 32)
		Speed = 1300.0
	else if(pev_valid(ent))
	{	
		Speed = 700.0
		if(entity_range(ent, id)<50.0)
		{
			set_pev(ent, pev_velocity, {0,0,0})
			idOrigin[2]-=20.0
			set_pev(ent, pev_origin, idOrigin)
			
			drag_end(id)
			return	
		}
	}
	else{
		drag_end(id)
		return
	}	
	hook_ent2(ent, idOrigin, Speed)
}

public drag_end(id)
{
	g_hooked[id] = 0
	beam_remove(id)
	remove_task(id)

	g_drag_i[id] = false
	g_unable2move[id] = false
}
public harpoon_target(parm[])
{
	new id = parm[0]
	new hooktarget = parm[1]

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(8)
	write_short(id)
	write_short(hooktarget)
	write_short(g_Line)
	write_byte(0)
	write_byte(0)
	write_byte(200)
	write_byte(8)
	write_byte(1)
	write_byte(255)
	write_byte(0)
	write_byte(0)
	write_byte(90)
	write_byte(10)
	message_end()
}

public noTarget(id)
{
	new endorigin[3]

	get_user_origin(id, endorigin, 3)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte( TE_BEAMENTPOINT );
	write_short(id)
	write_coord(endorigin[0])
	write_coord(endorigin[1])
	write_coord(endorigin[2])
	write_short(g_Line)
	write_byte(0)
	write_byte(0)
	write_byte(200)
	write_byte(8)
	write_byte(1)
	write_byte(255)
	write_byte(0)
	write_byte(0)
	write_byte(75)
	write_byte(0)
	message_end()
}

public beam_remove(id)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(99)
	write_short(id)
	message_end()
}
stock hook_ent2(ent, Float:VicOrigin[3], Float:speed)
{
	if(!pev_valid(ent))
		return
	
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(ent, pev_origin, EntOrigin)
	
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / speed
	
	if(distance_f > 15.0)
	{
		fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time
		fl_Velocity[2] += 20.0
		set_pev(ent, pev_velocity, fl_Velocity)
	}else set_pev(ent, pev_velocity, {0.0,0.0,0.0})
}