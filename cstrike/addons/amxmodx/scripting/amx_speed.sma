#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>
#include <toan> 

#define PLUGIN "[CSO:Hunter Zombie]"
#define VERSION "1.2"
#define AUTHOR "HoRRoR/tERoR edit"

new Float:g_fastspeed = 2000.0 // sprint speed 340

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward( FM_PlayerPreThink, "client_prethink" )
	register_clcmd("say /te", "do_all_tele_player")
}
public do_all_tele_player(id){
	for(new i=0;i<get_maxplayers();i++){
		if(!pev_valid(i)) continue
		do_tele_player(i)
	}
}
public do_tele_player(id)
{	
	static Origin[3];		
	get_user_origin(id, Origin)
	Origin[2] = -2300;
	set_user_origin(id, Origin)
}

public client_prethink(id)
{
    if(is_user_alive(id))
		set_user_maxspeed(id , g_fastspeed); 
}