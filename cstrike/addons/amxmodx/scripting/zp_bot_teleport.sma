#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <zombieplague>
#include <toan>
#include <hamsandwich>

new const PLUGIN_NAME[] = "[ZP] Teleport"
new const PLUGIN_VERSION[] = "1.2"
new const PLUGIN_AUTHOR[] = "NiHiLaNTh"

new bool:force_tele[32]
new Float:user_time[32]

#define TELE_TIME 5.0

new allowtele,teled[33]

new g_maxplayers, AvailMap
new g_spawnspot[33][3]

enum MapInfo
{
	MapName[32],
	TheOrigin[3]
}

static const map[][MapInfo] = { 
	{"zm_toan", {809, -382, -339}},
	{"zm_toan", {-747, -523, -339}},
	{"zm_toan", {883, 370, -339}},
	{"zm_toan", {-887, 150, -339}},
	{"zm_toan", {-13, 872, -339}}
}

// Plugin Initialization
public plugin_init()
{
	// Plugin Call
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	// Client Command
	register_clcmd("teleport", "ActivateTeleport");
	register_forward(FM_PlayerPreThink, "fm_pthink")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	
	//register_clcmd("say /tele", "ActivateTeleport");
	register_clcmd("say /tele", "tele");
	register_clcmd("say /checktele", "check_location");
	
	g_maxplayers = get_maxplayers()
}
public zp_round_started(gamemode, id)
{	
	if(zp_is_nemesis_round() || zp_is_survivor_round() || zp_is_swarm_round() || zp_is_plague_round())
	{
		allowtele=0
	}else 	allowtele=1
}
public zp_user_humanized_post(id)
{
	if (get_cvar_num("bot_stop")==1)
		return;
		
	if(is_user_bot(id) && !zp_get_user_survivor(id))
		ActivateTeleport(id)
}
public zp_round_ended()
{
	allowtele=0
}
public client_putinserver(id)
{
	new g_MapName[33];
	get_mapname(g_MapName,32);
	for(new i=0;i<sizeof(map);i++)
		if(equali(map[i][MapName],g_MapName))
		{
			AvailMap = true;
			return;
		}
			
	AvailMap = false;
}
public check_location(id)
{
	new NewLocation[3];
	get_user_origin(id, NewLocation);
	client_print(id,print_chat,"Location: %i %i %i",NewLocation[0],NewLocation[1],NewLocation[2])
}
public Player_Spawn(id)
{
	get_user_origin(id, g_spawnspot[id], 0);
}
public fm_pthink(id)
{
	if (get_cvar_num("bot_stop"))
		return FMRES_IGNORED
	if ( zp_get_user_nemesis(id) || zp_get_user_survivor(id))
		return FMRES_IGNORED
	if (!zp_get_user_zombie(id))
		return FMRES_IGNORED
	if (!is_user_alive(id))
		return FMRES_IGNORED
	if (!is_user_bot(id))
		return FMRES_IGNORED
		
	new button = pev(id, pev_button)
	if (button & IN_MOVELEFT || button & IN_MOVERIGHT || button & IN_FORWARD || button & IN_BACK || button & IN_JUMP)
		force_tele[id] = false
	if (!(button & IN_MOVELEFT || button & IN_MOVERIGHT || button & IN_FORWARD || button & IN_BACK || button & IN_JUMP || zp_get_user_zombie(id)))
	{
		if (!zp_get_user_zombie(id))
			return FMRES_IGNORED
			
		if (!force_tele[id])
		{
			force_tele[id] = true
			user_time[id] = get_gametime()
		}
		if (force_tele[id])
		{
			new Float:current_time = get_gametime()
			if (current_time - user_time[id] >= TELE_TIME)
			{
				set_user_origin(id, g_spawnspot[id]);
				force_tele[id] = false
			}
		}
	}
	static playercount;playercount=zp_get_human_count()+zp_get_zombie_count()
	if(zp_get_zombie_count() >= floatround(0.3 * playercount)+2 && allowtele==1)
	{
		set_task(1.0 , "tele")
		allowtele=0
	}
	return FMRES_HANDLED
}
public tele()
{
	if(!AvailMap)
		return;
	for (new i = 0; i < g_maxplayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if (zp_get_user_zombie(i) || zp_get_user_survivor(i) || zp_get_user_nemesis(i))
			continue
		if(is_user_bot(i))
		{
			ActivateTeleport(i)
		}
	}
	makefs()
}

// Activate Teleport
public ActivateTeleport(id)
{		
	//if (get_cvar_num("bot_stop"))
	//	return FMRES_IGNORED	
	
	new g_MapName[33];
	get_mapname(g_MapName,32);
	
	static ran_num;
	static Origin[3];
	
	while(!teled[id])
	{
		//client_print(id, print_chat,"Map array size: %i",sizeof(map))
		ran_num=random_num(0,sizeof(map)-1);
		
		if(!equali(map[ran_num][MapName],g_MapName))
			continue

		Origin[0] = map[ran_num][TheOrigin][0]
		Origin[1] = map[ran_num][TheOrigin][1]
		Origin[2] = map[ran_num][TheOrigin][2]
		
		client_print(id, print_chat,"Map Name: %s, Location: %i %i %i",map[ran_num][MapName],Origin[0],Origin[1],Origin[2])
		set_user_origin(id, Origin);
		teled[id] = true;
	}
	teled[id] = false
	return FMRES_HANDLED
}
