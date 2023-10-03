#include <amxmodx> 
#include <fakemeta>
#include <zombieplague>

#define PLG_VERSION "1.2"

new FPS = 0;
new Float:NC = 0.0;

new Float:g_nc[33] = 0.0;

new LASTFPS;

new g_fps[33];
new g_lastfps[33];
new g_average[10];
new g_started;

public plugin_init()
{ 
	register_plugin("FPS & Ping Status", PLG_VERSION ,"ReymonARG")
	register_forward(FM_StartFrame,"ForwardStartFrame")
	
	set_task(1.0, "msglala");
}

public client_putinserver(id)
	g_nc[id] = get_gametime();
	
public client_disconnect(id)
	remove_task(id);

public zp_round_started(){
	g_started = true
}
public zp_round_ended(){
	g_started = false
}
public ForwardStartFrame()
{
	new Float:HLT = get_gametime();
	if(NC >= HLT)
	{
		FPS++;
	}
	else
	{
		NC = NC + 1;
		LASTFPS = FPS;
		new rand = random_num(0,9);
		g_average[rand] = FPS;
		FPS = 0;
	}
}

public PreThink(id) 
{
	new Float:HLT = get_gametime();
	if( g_nc[id] >= HLT)
	{
		g_fps[id]++;
	}
	else
	{
		g_nc[id] = g_nc[id] + 1.0;
		g_lastfps[id] = g_fps[id];
		g_fps[id] = 0;
	}
}

public msglala()
{
	set_task(1.0, "msglala")
	
	if(!g_started)
		return;
	
	if(LASTFPS < 6){
		user_kill(getRandomBot())
	}
}

public getRandomBot(){
	new players[32], num
	get_players(players, num, "ade", "TR")
	
	return players[random_num(0, num)]
}