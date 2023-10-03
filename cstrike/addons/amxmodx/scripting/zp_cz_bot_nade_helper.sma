/***************************************************************************\
		    ===================================		   
		     * || [ZP] CZ Bot Helper v1.0 || *
		    ===================================
				*by @bdul!*

	-------------------
	 *||DESCRIPTION||*
	-------------------

	This plugins is supposed to be used with CZ Bots. The plugin has not 
	been tested with POD Bots.
	With this plugin on your server bots will throw different nades when
	they spot a zombie
	There are four chances which determine which nade the bot throws
	Either the bot throws a napalm nade or a frost nade or a flare nade
	Some times the bot will throw the frost nade first and then the 
	napalm nade
	How ever some times the bot wont throw any nade.

	-------------
	 *||CVARS||*
	-------------
	
	- zp_nade_throw_on_nem 1
		-> Whether the bot should throw a particular nade on
		   nemesis [0 - Disabled]

	- zp_nade_throw_time 1.0
		-> What should be the time difference when the bot throws
		   a frost nade first and then the napalm nade
	
	- zp_nade_throw_chance 1
		-> The chance that whether a bot should throw a nade
		   The higher the value of this CVAR, the lesser the 
		   chance that a bot will throw a particular nade

	---------------
	 *||CREDITS||*
	---------------

	- MeRcyLeZZ ----> For some useful code parts i took from ZP
	- Sn!ff3R ------> For providing me with a useful forward to detect
			  whether the bot is aiming at some one or not
	- Bugsy --------> For helping me with how to force the bot to press
			  the attack button

	------------------
	 *||CHANGE LOG||*
	------------------
	
	v1.0 ====> Initial Release
	
\***************************************************************************/

#include <amxmodx>
#include <hamsandwich>
#include <zombieplague>

// Offsets needed for forcing the bot to throw the nade
new const ActiveItemOffset = 373;
new const ExtraOffset = 5;

// Variables
new cvar_throw_time, cvar_throw_chance, cvar_throw_nem

public plugin_init()
{
	// Register Plugin
	register_plugin("[ZP] CZ Bot Nade Helper", "1.0", "@bdul!")
	
	// Register events
	register_event("StatusValue", "event_nade_throw", "be", "1=2", "2!0")
	
	// Register a cvar to detect servers with this plugin
	register_cvar("zp_nade_helper", "1.0", FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("zp_nade_helper", "1.0")
	
	// Register some CVARs
	cvar_throw_nem = 	register_cvar("zp_nade_throw_on_nem","1")
	cvar_throw_time =	register_cvar("zp_nade_throw_time","1.0")
	cvar_throw_chance =	register_cvar("zp_nade_throw_chance","1")
}

// Thnx to Sn!ff3R
public event_nade_throw(id)
{
	// Get the id of the person at which the bot is aiming
	new aim_id
	aim_id = read_data(2)
	
	// Some necassary checks
	if(is_user_bot(id) && is_user_alive(id) && !zp_get_user_zombie(id) && zp_get_user_zombie(aim_id) && is_user_alive(aim_id) && (!zp_get_user_nemesis(aim_id) || get_pcvar_num(cvar_throw_nem)))
	{
		// Some one set the cvar to 0 or less then 0
		if (get_pcvar_num(cvar_throw_chance) <= 0)
		{
			switch (random_num(0, 3))
			{
				// Throw flare Nade
				case 0: force_throw_flare(id)
	
				// Throw Napalm Nade
				case 1: force_throw_napalm(id)

				// Throw frost Nade
				case 2: force_throw_frost(id)

				// Throw first Frost Nade and then Napalm Nade
				case 3:
				{
					// Throw Frost Nade
					force_throw_frost(id)
					
					// Throw Napalm Nade after some time to prevent bugs
					set_task( (get_pcvar_float(cvar_throw_time) < 0.8) ? 0.8 : get_pcvar_float(cvar_throw_time), "force_throw_napalm", id)
				}
			}
		}
		else
		{
			// Necassary Variables
			new two ,three, four, chance 
			two = get_pcvar_num(cvar_throw_chance) + 1
			three = get_pcvar_num(cvar_throw_chance) + 2
			four = get_pcvar_num(cvar_throw_chance) + 3
			chance = random_num(0, four)
			
			// Check for whether the bot should throw a nade or not
			if ((chance == get_pcvar_num(cvar_throw_chance)))
				// Throw Flare Nade
				force_throw_flare(id)
			else if (chance == two)
				// Throw Frost Nade
				force_throw_frost(id)
			else if (chance == three)
				// Throw Napalm Nade
				force_throw_napalm(id)
			else if (chance == four)
			{
				// Throw Frost Nade
				force_throw_frost(id)

				// Throw Napalm Nade after some time to prevent bugs
				set_task( (get_pcvar_float(cvar_throw_time) < 0.8) ? 0.8 : get_pcvar_float(cvar_throw_time), "force_throw_napalm", id)
			}
			else if (!chance) return;
			else return;
		}
	}
	
}
public force_throw_napalm(id)
{
	// Check whether the user haves Napalm Nade
	if (user_has_weapon(id, CSW_HEGRENADE))
	{
		// Force to take out Napalm Nade
		engclient_cmd(id, "weapon_hegrenade");
		
		// Forced to press the attack button [Thnx to Bugsy]
		ExecuteHam(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, ActiveItemOffset, ExtraOffset));
	}
}
public force_throw_frost(id)
{
	// Check whether the user haves Frost Nade
	if (user_has_weapon(id, CSW_FLASHBANG))
	{	
		// Force to take out Frost Nade
		engclient_cmd(id, "weapon_flashbang");
		
		// Forced to press the attack button [Thnx to Bugsy]
		ExecuteHam(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, ActiveItemOffset, ExtraOffset));
	}
}
public force_throw_flare(id)
{
	// Check whether the user haves Frost Nade
	if (user_has_weapon(id, CSW_SMOKEGRENADE))
	{	
		// Force to take out Frost Nade
		engclient_cmd(id, "weapon_smokegrenade");
		
		// Forced to press the attack button [Thnx to Bugsy]
		ExecuteHam(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, ActiveItemOffset, ExtraOffset));
	}
}