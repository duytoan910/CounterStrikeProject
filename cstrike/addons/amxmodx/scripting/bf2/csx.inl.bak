//Bf2 Rank Mod CSX forwards File
//Contains all the CSX forwarded functions

#if defined bf2_csx_forward_included
  #endinput
#endif
#define bf2_csx_forward_included

public client_death(killer, victim, wpnindex, hitplace, TK)
{
	if ( !get_pcvar_num(gPcvarBF2Active) ) return;

	if ( killer == victim )
	{
		check_badges(victim);
		return;
	}

	//if ( is_user_bot(victim) && !get_pcvar_num(gPcvarRankBots) ) return;

	if ( TK && !get_pcvar_num(gPcvarFFA) ) return;
	if ( killer < 1 || killer > gMaxPlayers ) return;

	switch ( wpnindex )
	{
		case CSW_KNIFE: knifekills[killer]++;
		case CSW_M249: parakills[killer]++;
		case CSW_AWP, CSW_SCOUT, CSW_G3SG1, CSW_SG550 : sniperkills[killer]++;
		case CSW_DEAGLE, CSW_ELITE, CSW_USP, CSW_FIVESEVEN, CSW_P228, CSW_GLOCK18: pistolkills[killer]++;
		case CSW_HEGRENADE: grenadekills[killer]++;
		case CSW_XM1014, CSW_M3: shotgunkills[killer]++;
		case CSW_MAC10, CSW_UMP45, CSW_MP5NAVY, CSW_TMP, CSW_P90: smgkills[killer]++;
		case CSW_AUG, CSW_GALIL, CSW_FAMAS, CSW_M4A1, CSW_SG552, CSW_AK47: riflekills[killer]++;
	}

	totalkills[killer]++;

	check_badges(victim);

	if ( mostkillsid == killer )
	{
		mostkills++;
	}
	else if ( totalkills[killer] > mostkills )
	{
		mostkills = totalkills[killer];
		mostkillsid = killer;

		new line[100], name[32];
		get_user_name(killer, name, charsmax(name));
		line[0] = 0x04;
		formatex(line[1], charsmax(line)-1, "Congratulations to %s, The new Kill Leader with %i Kills", name, mostkills);
		copy(mostkillsname, charsmax(mostkillsname), name);
		ShowColorMessage(killer, MSG_BROADCAST, line);
	}

	DisplayHUD(killer);
}

public client_damage(attacker, victim, damage, wpnindex, hitplace, TA)
{
	if ( !get_pcvar_num(gPcvarBF2Active) || !get_pcvar_num(gPcvarBadgesActive) || !get_pcvar_num(gPcvarBadgePowers) )
		return;

	// Check in case of suicide, pistol code may run on self
	if ( attacker == victim )
		return;

	if ( TA && !get_pcvar_num(gPcvarFFA)  )	//add check for free for all later
		return;

	new pistollevel = g_PlayerBadges[victim][BADGE_PISTOL];

	if ( pistollevel > 0 )
	{
		if ( random_num(1, (9-pistollevel)) == 1 )
		{
			g_imobile[attacker] = true;
			set_speed(attacker);
			screen_flash(attacker, 255, 0, 0, 100); //Red screen flash
			player_glow(attacker, 255, 0, 0); //Make the player glow red too

			message_begin(MSG_ONE_UNRELIABLE, gmsgScreenShake, _, attacker);
			write_short(10<<12);
			write_short(2<<12);
			write_short(5<<12);
			message_end();

			set_task(1.0, "remove_imobile", attacker);
		}
	}

	if ( !is_user_alive(attacker) )
		return;

	if ( wpnindex == CSW_KNIFE )
	{
		new attackerknifelevel = g_PlayerBadges[attacker][BADGE_KNIFE];

		if ( attackerknifelevel == 0 )
			return;

		// Health to add is dependent on assault badge
		new hp = get_user_health(attacker);
		new maxHP = 100 + g_PlayerBadges[attacker][BADGE_ASSAULT]*10;

		if ( hp >= maxHP )
			return;

		hp += floatround(damage*(attackerknifelevel/5.0));

		set_user_health(attacker, min(hp, maxHP));

		screen_flash(attacker, 0, 0, 255, 100); //Blue screen flash
		player_glow(attacker, 0, 0, 255); //Blue model flash
	}
}

public bomb_planted(planter)
{
	if ( get_playersnum() < get_pcvar_num(gPcvarXpMinPlayers) ) return;

	plants[planter]++;
	DisplayHUD(planter);
}

public bomb_explode(planter, defuser)
{
	if ( get_playersnum() < get_pcvar_num(gPcvarXpMinPlayers) ) return;

	explosions[planter]++;
	totalkills[planter] += 3;
	DisplayHUD(planter);
	client_print(planter, print_chat, "[BF2] You received 3 points for destroying the target");
}

public bomb_defused(defuser)
{
	if ( get_playersnum() < get_pcvar_num(gPcvarXpMinPlayers) ) return;

	defuses[defuser]++;
	totalkills[defuser] += 3;
	DisplayHUD(defuser);
	client_print(defuser, print_chat, "[BF2] You received 3 points for defusing the bomb");
}