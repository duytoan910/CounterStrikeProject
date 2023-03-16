/*================================================================================
 [Plugin Customization]
=================================================================================*/
#include <amxmodx>
#include <zombieplague>
// Items name (note: add exact item name)

new const EXTRA_ITEMS[][] = {
	"Black Dragon Cannon",
	"Heaven Splitter",
	"M3 Black Dragon",
	"M32 MGL Venom",
	"Shining Heart Rod",
	"Petrol Boomer",
	"AWP Elven Ranger",
	"SG552 Lycanthrope",
	"PlasmaGun",
	"Bouncer",
	"Magnum Drill",
	"Bendita",
	"Advanced Crossbow",
	"M134 Predator",
	"Balrog-V",
	"Balrog-VII",
	"Balrog-XI",
	"Janus-V",
	"Janus-VII",
	"Janus-XI",
	"Thanatos-III",
	"Thanatos-V",
	"Thanatos-VII",
	"Enternal Laser Fist",
	"Void Avenger",
	"Gungnir"
}

/*================================================================================
 Customization ends here! Yes, that's it. Editing anything beyond
 here is not officially supported. Proceed at your own risk...
=================================================================================*/

enum
{
	TASK_STARTGIVE = 298,
	TASK_GIVEITEM
}

#define ID_BOT (taskid - TASK_GIVEITEM)

new cvar_max_bots, g_botname[33][32], g_has_item[33], g_maxplayers;

public plugin_init()
{
	/* Plugin register */
	register_plugin("[ZP] Bot Addon: Force buy items", "v0.2", "Crazy");

	/* Cvars */
	cvar_max_bots = register_cvar("zp_force_buy_maxbots", "15");

	/* Max players */
	g_maxplayers = get_maxplayers()
}

public client_putinserver(id)
{
	if (is_user_bot(id))
		get_user_name(id, g_botname[id], charsmax(g_botname[]));
}

public zp_round_started(gamemode, id)
{
	for (new id = 1; id <= g_maxplayers; id++)
		g_has_item[id] = false;

	if (gamemode != MODE_PLAGUE || MODE_SURVIVOR)
		set_task(2.0, "give_item_task", TASK_STARTGIVE);
}

public give_item_task(taskid)
{
	static id, iBots, iMaxBots;
	iBots = 0;
	iMaxBots = get_pcvar_num(cvar_max_bots);

	while (iBots <= iMaxBots)
	{
		id = get_random_bot(random_num(1, get_alive_bots()));

		if (!is_user_alive(id))
			continue;

		if (zp_get_user_zombie(id))
			continue;

		if (g_has_item[id])
			continue;

		set_task(1.0, "give_item", id+TASK_GIVEITEM);

		iBots++;
	}

	remove_task(TASK_STARTGIVE);
	remove_task(TASK_GIVEITEM);
}

public give_item(taskid)
{
	static id, random, itemid;
	id = ID_BOT;
	random = random_num(0, sizeof EXTRA_ITEMS - 1);
	itemid = zp_get_extra_item_id(EXTRA_ITEMS[random]);

	if (itemid == -1)
	{
		set_task(0.5, "give_item", id+TASK_GIVEITEM);
		return;
	}

	zp_force_buy_extra_item(id, itemid, 1);
	g_has_item[id] = true;
	remove_task(id+TASK_GIVEITEM);
}

get_alive_bots()
{
	static iBot, id;
	iBot = 0;

	for (id = 1; id <= g_maxplayers; id++)
	{
		if (is_user_alive(id) && is_user_bot(id))
			iBot++;
	}

	return iBot;
}

get_random_bot(n)
{
	static iBot, id;
	iBot = 0;

	for (id = 1; id <= g_maxplayers; id++)
	{
		if (is_user_alive(id) && is_user_bot(id))
			iBot++;

		if (iBot == n)
			return id;
	}

	return -1;
}