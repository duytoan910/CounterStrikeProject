#include <amxmodx>
#include <zombieplague>
#include <hamsandwich>
#include <fakemeta>

#define PLUGIN "Deathtype Effects"
#define VERSION "1.0"
#define AUTHOR "anakin_cstrike"

#define TEMP_MSG	16
#define TEMP_MSG2	1936

new g_Smoke,g_Lightning;
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_event("DeathMsg","hook_death","a");
}
public plugin_precache()
{
	precache_sound("ambience/thunder_clap.wav");
	g_Lightning = precache_model("sprites/lgtning.spr");
	return PLUGIN_CONTINUE
}

public hook_death()
{
	if(!read_data(1)) return PLUGIN_CONTINUE;
	new wpn[3],vOrigin[3],coord[3];
	new victim = read_data(2);
	read_data(4,wpn,2);
	get_user_origin(victim,vOrigin);
	vOrigin[2] -= 26
	coord[0] = vOrigin[0] + 150;
	coord[1] = vOrigin[1] + 150;
	coord[2] = vOrigin[2] + 800;
	
	if(zp_get_user_nemesis(read_data(1)))
	{
		create_thunder(coord,vOrigin);
		client_cmd(0,"speak ambience/thunder_clap.wav")
	}
	return PLUGIN_CONTINUE;
}

create_thunder(vec1[3],vec2[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(0); 
	write_coord(vec1[0]); 
	write_coord(vec1[1]); 
	write_coord(vec1[2]); 
	write_coord(vec2[0]); 
	write_coord(vec2[1]); 
	write_coord(vec2[2]); 
	write_short(g_Lightning); 
	write_byte(1);
	write_byte(5);
	write_byte(2);
	write_byte(30);
	write_byte(30);
	write_byte(255); 
	write_byte(255);
	write_byte(255);
	write_byte(255);
	write_byte(200);
	message_end();

	message_begin( MSG_PVS, SVC_TEMPENTITY,vec2); 
	write_byte(TE_SPARKS); 
	write_coord(vec2[0]); 
	write_coord(vec2[1]); 
	write_coord(vec2[2]); 
	message_end();
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,vec2); 
	write_byte(TE_SMOKE); 
	write_coord(vec2[0]); 
	write_coord(vec2[1]); 
	write_coord(vec2[2]); 
	write_short(g_Smoke); 
	write_byte(10);  
	write_byte(10)  
	message_end();
}