//Bf2 Rank Mod events File
//Contains all the client command functions

#if defined bf2_events_included
  #endinput
#endif
#define bf2_events_included

//Normal register event functions..
public Event_HLTV()
{
	freezetime = true;
}

public Event_CurWeapon(id)
{
	if ( !is_user_alive(id) || !get_pcvar_num(gPcvarBF2Active) )
		return;

	if ( !get_pcvar_num(gPcvarBadgePowers) )
		return;

	new weapon_id = read_data(2);

	g_invis[id] = false;

	if ( g_lastwpn[id] != weapon_id )
	{
		set_speed(id);
		set_invis(id);
	}

	g_lastwpn[id] = weapon_id;
}

public Event_SetFOV(id)
{
	// Sniper rifle scoping can reset user speed lets fix that

	if ( !get_pcvar_num(gPcvarBF2Active) || !is_user_alive(id) ) return;

	new fov = read_data(1);

	if ( gCurrentFOV[id] != fov ) {
		gCurrentFOV[id] = fov;

		switch(g_lastwpn[id]) {
			// Only need to check speed for sniper rifles
			case  CSW_SCOUT, CSW_SG550, CSW_AWP, CSW_G3SG1: {
				set_speed(id);
			}
		}
	}
}

public Event_DeathMsg()
{
	// csx's client_death does not catch death by world
	// if killer is not a player lets check badges for the victim
	if ( 0 < read_data(1) <= gMaxPlayers ) return;

	check_badges(read_data(2));
}

public setTeam(id)
{
	g_friend[id] = read_data(2);
}

public on_HideStatus(id)
{
	// If miscstats PlayerName option is on do not show this info
	if ( get_xvar_num(gPlayerName) ) return;

	ClearSyncHud(id, gHudSyncAimInfo);
}

public flags_check()
{
	new temp[8];
	get_pcvar_string(gPcvarHudOptions, temp, 7);

	return read_flags(temp);
}

//called when id looks at someone, this needs to be rewritten into one function
public on_ShowStatus(id)
{
	// If miscstats PlayerName option is on do not show this info
	new statsHudMessage = get_xvar_num(gPlayerName);

	new pid = read_data(2);
	new pidrank = g_PlayerRank[pid];
	new flags = flags_check();
	new name[32];
	new color1 = 0, color2 = 0;
	new Float:height;

	get_user_name(pid, name, 31);

	if ( get_user_team(pid) == 1 )
		color1 = 255;
	else
		color2 = 255;

	if (flags & ABOVEHEAD)
		height=0.35;
	else
		height=0.60;

	if ( g_friend[id] == 1 )	// friend
	{
		if ( flags && !statsHudMessage )
		{
			new wpnid = get_user_weapon(pid);
			new wpnname[32];

			if ( wpnid )
				xmod_get_wpnname(wpnid, wpnname, 31);

			set_hudmessage(color1, 50, color2, -1.0, height, 1, 0.01, 3.0, 0.01, 0.01);

			if (flags & TEAMRANK)
			{
				if (flags & STATS)
					ShowSyncHudMsg(id, gHudSyncAimInfo, "%s : %s^n%d HP / %d AP / %s", name, gRankName[pidrank], get_user_health(pid), get_user_armor(pid), wpnname);
				else
					ShowSyncHudMsg(id, gHudSyncAimInfo, "%s : %s", name, gRankName[pidrank]);
			}
			else
			{
				if (flags & STATS)
					ShowSyncHudMsg(id, gHudSyncAimInfo, "%s^n%d HP / %d AP / %s", name, get_user_health(pid), get_user_armor(pid), wpnname);
				else
					ShowSyncHudMsg(id, gHudSyncAimInfo, "%s", name);
			}
		}

		new time = floatround(get_pcvar_float(gPcvarIconTime)*10);
		if ( time > 0 )
			Create_TE_PLAYERATTACHMENT(id, pid, 55, gSprite[pidrank], time);
	}
	else if ( flags && !statsHudMessage )
	{
		if (!((flags & HIDEINVIS) && (g_invis[pid])))
		{
			set_hudmessage(color1, 50, color2, -1.0, height, 1, 0.01, 3.0, 0.01, 0.01);

			if (flags & ENEMYRANK)
				ShowSyncHudMsg(id, gHudSyncAimInfo, "%s : %s", name, gRankName[pidrank]);
			else
				ShowSyncHudMsg(id, gHudSyncAimInfo, "%s", name);
		}
	}
}

public Message_Intermission()
{
#if defined SQL
	gIntermission = true;
#endif
	set_task(0.1, "award_check");
}

public Message_StatusValue()
{
	if ( !get_pcvar_num(gPcvarBF2Active) || !get_pcvar_num(gPcvarStatusText) ) return; 

	//Block the name info, of person you aim at
	set_msg_block(gmsgStatusText, BLOCK_SET);
}

//Register logevent functions

public LogEvent_Round_End()
{
	set_task(0.2, "badge_check_loop");
}

public LogEvent_Round_Start()
{
	freezetime = false;

	for(new i = 1; i <= gMaxPlayers; i++) {
		set_task(0.1, "set_speed", i);
	}
}