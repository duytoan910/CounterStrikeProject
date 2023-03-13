#include <amxmodx>
#include <zombieplague>


/*================================================================================
 [Plugin Customization]
=================================================================================*/

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

new g_has_item[33], g_maxplayers;

public plugin_init()
{
	/* Plugin register */
	register_plugin("[ZP] Bot Addon: Force buy items", "v0.2", "Crazy");

	/* Max players */
	g_maxplayers = get_maxplayers()
}

public zp_round_started(gamemode, id)
{
	for (new id = 1; id <= g_maxplayers; id++)
		g_has_item[id] = false;

	if (gamemode != MODE_SURVIVOR)
		set_task(2.0, "give_item_task", TASK_STARTGIVE);
}

public zp_user_infected_post(id){
	g_has_item[id] = false;
}

public zp_user_humanized_post(id){
	set_task(1.0, "give_item", id+TASK_GIVEITEM)
}

public give_item_task(taskid)
{
	for (new id = 1; id <= g_maxplayers; id++)
	{
		if (!is_user_alive(id))
			continue;

		if (zp_get_user_zombie(id))
			continue;

		if (g_has_item[id])
			continue;

		set_task(random_float(0.1,3.0), "give_item", id+TASK_GIVEITEM);
	}
	remove_task(TASK_STARTGIVE);
	remove_task(TASK_GIVEITEM);
}

public give_item(taskid)
{
	static id;
	id = ID_BOT;
	
	if (zp_get_user_zombie(id))
		return;

	new num = zp_get_extra_item_length()
	zp_force_buy_extra_item(id, num, 1);

	g_has_item[id] = true;
	remove_task(id+TASK_GIVEITEM);
}