#include <amxmodx> 
#include <fakemeta>
#include <zombieplague>

#define PLG_VERSION "1.2"

new FPS = 0;
new Float:NC = 0.0;

new Float:g_nc[33] = 0.0;

new LASTFPS;

new Pcvar[5];

new g_fps[33];
new g_lastfps[33];
new g_average[10];
new g_started;

public plugin_init()
{ 
	register_plugin("FPS & Ping Status", PLG_VERSION ,"ReymonARG")
	register_forward(FM_StartFrame,"ForwardStartFrame")
	register_forward(FM_PlayerPreThink,"PreThink")
	register_clcmd("say /infostatus", "infomenu");
	register_cvar("amx_statusinfo_version", PLG_VERSION, FCVAR_SERVER | FCVAR_SPONLY );
	Pcvar[0] = register_cvar("amx_statusinfo", "1");
	Pcvar[1] = register_cvar("amx_statusinfo_msg", "1");
	Pcvar[2] = register_cvar("amx_statusinfo_interval", "2.0");
	
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

GetAverage()
{	
	new Average;
	
	for(new i = 0; i < 10; i++)
	{
		new calculo = g_average[i];
		Average += calculo;
	}
	
	return Average / 10;
}

public msglala()
{
	set_task(get_pcvar_float(Pcvar[2]), "msglala")
	
	if( get_pcvar_num(Pcvar[0]) != 1 )
		return;
	
	if( get_pcvar_num(Pcvar[1]) != 1 )
		return;
	
	if(!g_started)
		return;
	
	if(LASTFPS < 6){
		user_kill(getRandomBot())
	}
}

public infomenu(id)
{
	if( get_pcvar_num(Pcvar[0]) != 1 )
		return;

	new msgtitulo[64];
	formatex(msgtitulo, 63, "\r[Kz-Arg] \yInfo Server \w- \y%i \wAverage: \y%i", LASTFPS, GetAverage());
	new menu = menu_create(msgtitulo, "menuinfo");
	new contador = 0;
	
	for( new i = 1; i <= 32; i++)
	{
		if( is_user_connected(i) && !is_user_bot(i) )
		{
			contador++;
			new msg[128], name[32], numero[5], ping, loss;
			get_user_name(i, name, 31);
			get_user_ping(i, ping, loss);
			formatex(msg, 127, "\y%s \wwith \y%i \wFPS and \y%i \wPing", name, g_lastfps[i], ping );
			num_to_str(contador, numero, 4);
			menu_additem(menu, msg, numero, 0);
		}
	}
	
	menu_display(id, menu, 0);
	set_task(1.0, "infomenu", id, _, _, "b");
}

public menuinfo(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		remove_task(id);
		return PLUGIN_HANDLED;
	}
	
	return 0;
}

public getRandomBot(){
	// new id = GetRandomAlive(random_num(1, GetAliveCount()))
	// if(!is_user_bot(id) || !is_user_alive(id)){
	// 	return getRandomBot()
	// }
	// return id

	new players[32], num
	get_players(players, num, "ade", "CT")
	
	return players[random_num(0, num)]
}

// Get Alive Count -returns alive players number-
GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= 32; id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}
// Get Random Alive -returns index of alive player number target_index -
GetRandomAlive(target_index)
{
	new iAlive, id
	
	for (id = 1; id <= 32; id++)
	{
		if (is_user_connected(id) && is_user_alive(id))
			iAlive++
		
		if (iAlive == target_index)
			return id;
	}
	
	return -1;
}
