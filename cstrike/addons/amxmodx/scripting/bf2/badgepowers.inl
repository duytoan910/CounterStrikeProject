//Bf2 Rank Mod badge powers File
//Contains all the power giving etc checking functions.

#if defined bf2_powers_included
  #endinput
#endif
#define bf2_powers_included

public set_speed(id)
{
	if ( !get_pcvar_num(gPcvarBadgesActive) || !get_pcvar_num(gPcvarBadgePowers) ) return;
	if ( !is_user_alive(id) || freezetime ) return;

	new Float:speed;

	if ( g_imobile[id] )
	{
		speed = 100.0;
	}
	else
	{
		if ( cs_get_user_vip(id) )
		{
			//VIPs only have 1 speed no matter the weapon
			speed = 227.0;
		}
		else
		{
			new weapon = get_user_weapon(id);

			speed = gCSWeaponSpeed[weapon];

			if ( gCurrentFOV[id] <= 45 )
			{
				switch(weapon)
				{
					case CSW_SCOUT: speed = 220.0;
					case CSW_SG550, CSW_AWP, CSW_G3SG1: speed = 150.0;
				}
			}
		}

		new smglevel = g_PlayerBadges[id][BADGE_SMG];
		if ( smglevel )
		{
			//15 units faster per level.
			speed += (smglevel * 15.0);
		}
	}

	if ( speed != get_user_maxspeed(id) )
	{
		set_user_maxspeed(id, speed);
	}
}

public set_invis(id)
{
	if ( !get_pcvar_num(gPcvarBadgesActive) || !get_pcvar_num(gPcvarBadgePowers) ) return;
	if ( !is_user_alive(id) ) return;

	new shotgunlevel = g_PlayerBadges[id][BADGE_SHOTGUN];

	if ( shotgunlevel && get_user_weapon(id) == CSW_KNIFE )
	{
		fm_set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, gInvisAlphaValue[shotgunlevel-1]);
		g_invis[id] = true;
	}
	else
	{
		fm_set_rendering(id);
		g_invis[id] = false;
	}
}

public remove_imobile(id)
{
	g_imobile[id] = false;

	set_speed(id);
}

public give_userweapon(id)
{
	if ( !get_pcvar_num(gPcvarBadgesActive) || !get_pcvar_num(gPcvarBadgePowers) ) return;
	if ( !is_user_alive(id) ) return;

	new bool:givenitem = false;

	new assaultlevel = g_PlayerBadges[id][BADGE_ASSAULT];
	if ( assaultlevel )
	{
		new hp;
		hp = 100 + (assaultlevel*10);

		if ( get_user_health(id) < hp )
		{
			set_user_health(id, hp);

			if ( pev(id, pev_max_health) < float(hp) )
			{
				set_pev(id, pev_max_health, float(hp));
			}

			givenitem = true;
		}
	}

	new sniperlevel = g_PlayerBadges[id][BADGE_SNIPER];

	if ( sniperlevel )
	{
		if ( random_num(1, (4-sniperlevel)) == 1 )
		{
			new weaponName[32];
			new weaponID = get_user_weapon(id);

			if ( !get_pcvar_num(gPcvarFreeAwp) )
			{
				fm_give_item(id, "weapon_scout");
			}
			else
			{
				fm_give_item(id, "weapon_awp");

			}

			if ( weaponID )
			{
				get_weaponname(weaponID, weaponName, charsmax(weaponName));
				engclient_cmd(id, weaponName);
			}

			givenitem = true;
		}
	}

	new CsArmorType:ArmorType;

	switch (numofbadges[id])
	{
		case 6 .. 11: {
			if ( cs_get_user_armor(id, ArmorType) < 50 )
			{
				cs_set_user_armor(id, 50, CS_ARMOR_VESTHELM);
				givenitem = true;
			}
		}

		case 12 .. 17: {
			if ( cs_get_user_armor(id, ArmorType) < 100 )
			{
				cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);
				givenitem = true;
			}
		}

		case 18 .. 24: {
			if ( cs_get_user_armor(id, ArmorType) < 200 )
			{
				cs_set_user_armor(id, 200, CS_ARMOR_VESTHELM);
				givenitem = true;
			}
		}
	}

	if ( givenitem )
		screen_flash(id, 0, 255, 0, 100); //Green screen flash
}