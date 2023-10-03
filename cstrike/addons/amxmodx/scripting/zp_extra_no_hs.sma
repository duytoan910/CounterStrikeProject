#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN "[ZP] Extra item: No HeadShots" // Nombre del plugin
#define VERSION "1.0" // Version del plugin
#define AUTHOR "[N.S.C] El MoRe" // Nombre del autor

///////////////////////////////////////////////////////////////
////////////////////////Customizacion//////////////////////////
///////////////////////////////////////////////////////////////

new const g_item_name[] = "No Head Shots" // Nombre del Item
new const g_item_cost = 4000 // Costo del item

new const g_item_msg_buy[] = "You have bought No HeadShots" // Mensaje que aparecera al comprarlo
new const g_item_msg_not[] = "You already have No HeadShots" // Mensaje que aparecera al comprarlo si ya lo tenes

///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////

new g_item // Variable del item extra
new bool:g_hasnohs[33] // Booleans del item extra

enum
{
	CVAR_ON, // Cvar On/Off el plugin
	CVAR_MODO // Cvar para elegir el modo
}
#define TASK_GLOW 21398

new g_maxplayers // Variable para almacenar la cantidad de jugadores que pueden entrar al server
const m_LastHitGroup = 75 // Constante para detectar el headshot
new g_ham_bot

// Forward principal
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR) // Registro del nombre del plugin, version y autor
	
	g_item = zp_register_extra_item(g_item_name, g_item_cost, ZP_TEAM_ZOMBIE) // Registramos el item extra
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage") // Hookeamos el evento de damage
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled") // Registramos el evento cuando un jugador muere
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0") // Evento donde empieza la ronda
	
	g_maxplayers = get_maxplayers() // Tomamos la cantidad de jugadores que pueden entrar al server
}
public client_putinserver(id)
{
	if(!g_ham_bot && is_user_bot(id))
	{
		g_ham_bot = 1
		set_task(0.1, "Do_Register_HamBot", id)
	}
}

public Do_Register_HamBot(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
}
// Forward del zp donde colocaremos lo que hara el item extra al comprarlo
public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_item) // Si el item coincide con el registrado...
	{
		if(!g_hasnohs[id]) // Si no compraste "No HeadShots"...
		{
			g_hasnohs[id] = true // Seteamos la booleans a verdadera
			client_print(id, print_chat, "[ZP] %s", g_item_msg_buy) // Mensaje al comprar
		}
		else // Si ya tenes "No HeadShots"
		{
			no_buy_item(id) // Mensaje y devolucion de ammos
		}
	}
}
public zp_user_humanized_post(id)
{
	g_hasnohs[id] = false;
}/*
public zp_user_infected_post(id)
{
	g_hasnohs[id] = true 
}*/
// Forward que se ejecuta al empezar la ronda (termina el freezetime)
public event_round_start()
{
	// Loopeamos a todos los jugadores
	for(new i = 1;i <= g_maxplayers;i++)
	{
		if(g_hasnohs[i]) // Si tenes el "No HeadShots"
			g_hasnohs[i] = false // Seteamos a falso la booleans
	}
	
	return PLUGIN_CONTINUE // Continuamos con el plugin
}

// Hookeamos el evento de muerte de un jugador
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Si tiene "No HeadShots"
	if(g_hasnohs[victim])
		g_hasnohs[victim] = false // Le sacamos el item
		
	return HAM_IGNORED
}

// Mensaje y devolucion de ammos
public no_buy_item(id)
{
	client_print(id, print_chat, "[ZP] %s", g_item_msg_not) // Otro mensaje
	zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + g_item_cost) // Devolvemos la cantidad de ammo packs del item
}

// Forward donde detectamos el da�o
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Si la victima tiene "No HeadShots", es zombie y el atacante es valido..
	if(g_hasnohs[victim] && zp_get_user_zombie(victim) && (1 <= attacker <= g_maxplayers))
	{						
		// Get player's origin
		static origin[3]
		get_user_origin(victim, origin)
		
		// Si le dispara en la cabeza...
		if(get_pdata_int(victim, m_LastHitGroup) == HIT_HEAD)
		{
			// Colored Aura
			
			fm_set_rendering(victim, kRenderFxGlowShell, 255, 255, 255, kRenderNormal , 5)
			if(task_exists(victim+TASK_GLOW))remove_task(victim+TASK_GLOW)
			set_task(0.4, "Reset_Glow", victim+TASK_GLOW)			
			return HAM_SUPERCEDE // Que no da�e a la victima
		}
			
			
	}
	
	return HAM_IGNORED // Returnamos el forward
}
public Reset_Glow(id)
{
	id-=TASK_GLOW
	fm_set_rendering(id)	
}
