/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <hamsandwich>
#include <metadrawer>
#include <zombieplague>
#include <engine>
#include <csx>
#include <fakemeta>

#define PLUGIN "Metadrawer Draw Radar Test"
#define VERSION "1.0"
#define AUTHOR "Agung"

#define RADAR_WIDTH 190
#define RADAR_HEIGHT 190
#define RADAR_CIRCLE 0
#define RADAR_BORDER 1
#define RADAR_ALPHA 255

//new fontChannel = 64;

new const g_iifection[] = "sprites/overviews/iinfection.spr"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	RegisterHam(Ham_Spawn, "player", "showradar", 1)
	//RegisterHam(Ham_Player_UpdateClientData, "player", "showradar", 1)
	//register_clcmd("say /show","show_radar")
	//register_clcmd("say /rev","removeradarent2")
	
	md_init()
}
public md_init()
{
	md_loadsprite(g_iifection)
	
	//md_initfont(fontChannel, "Segoe UI", 18, FS_ANTIALIAS | FS_DROPSHADOW)
}
public zp_user_infected_pre(iVictim)
{
/*
	static Origin[3],Float:tmpOrigin[3]
	pev(iVictim, pev_origin, tmpOrigin)
	FVecIVec(tmpOrigin, Origin)
	showradar_ent(iVictim,Origin)*/
}
public showradar(id)
{	
	if (!is_user_alive(id) || is_user_bot(id))
		return
	md_drawradar(id, 1, RADAR_WIDTH, RADAR_HEIGHT, 0.0, 0.0, 255, 255, 255, RADAR_ALPHA, ALIGN_NORMAL, RADAR_CIRCLE, RADAR_BORDER)
}
public show_radar(id)
{
	md_drawspriteonradar(id, 1, 0, g_iifection, {0,0,0}, 255,255,255,255, SPR_HOLES)
}
public showradar_ent(iVictim,Origin[3])
{
	new id[2];
	for(new i=0;i<32;i++)
	{
		if(!is_user_alive(i))
			continue;
			
		md_drawspriteonradar(i, iVictim, 0, g_iifection, Origin, 255,255,255,255, SPR_HOLES)
		
		id[0] = i;
		id[1] = iVictim
		
		client_print(id[0], print_chat,"Removing!")
		set_task(3.0,"removeradarent", 55, id, sizeof(id))
	}
}
public removeradarent(id[2])
{
	//md_removedrawing(id[0], 5, id[1])
	md_removedrawing(1, 5, id[1])
	client_print(id[0], print_chat,"Removed!")
}
public removeradarent2(id)
{	
	for(new i=0;i<32;i++)
	{
		md_removedrawing(id, 0, i)
		md_removedrawing(id, 1, i)
		md_removedrawing(id, 2, i)
		md_removedrawing(id, 3, i)
		md_removedrawing(id, 4, i)
		md_removedrawing(id, 5, i)
		client_print(id, print_chat,"Removed!")
	}
}