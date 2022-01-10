//Bf2 Rank Mod save File
//Contains all the saving/loading functions

#if defined bf2_save_included
  #endinput
#endif
#define bf2_save_included

public get_save_key(id)
{
	if ( is_user_bot(id) ) {
		// Should bots get ranked?

		// Save bots by name but strip tags and skill since those can change for same bot name
		new botname[32];
		get_user_name(id, botname, charsmax(botname));

		// Get Rid of BOT Tag

		// PODBot
		replace(botname, charsmax(botname), "[POD]", "");
		replace(botname, charsmax(botname), "[P*D]", "");
		replace(botname, charsmax(botname), "[P0D]", "");

		// CZ Bots
		replace(botname, charsmax(botname), "[BOT] ", "");

		// Attempt to get rid of the skill tag so we save with bots true name
		new lastchar = strlen(botname) - 1;
		if ( botname[lastchar] == ')' ) {
			for ( new x = lastchar - 1; x > 0; x-- ) {
				if ( botname[x] == '(' ) {
					botname[x - 1] = '^0';
					break;
				}
				if ( !isdigit(botname[x]) ) break;
			}
		}

		if ( botname[0] != '^0' ) {
			replace_all(botname, charsmax(botname), " ", "_");
			formatex(gSaveKey[id], charsmax(gSaveKey[]), "[BOT]%s", botname);
		}
	}
	else if ( !is_dedicated_server() && id == 1 ) {
		// Trick for listen servers
		copy(gSaveKey[id], charsmax(gSaveKey[]), "loopback");
	}
	else
	{
		// Follows csstats_rank cvar
		switch( get_pcvar_num(gPcvarSaveType) )
		{
			case 0:
			{
				get_user_name(id, gSaveKey[id], charsmax(gSaveKey[]));
			}
			case 1:
			{
				if ( get_pcvar_num(gPcvarSVLan) ) {
					// Just make sure sv_lan is correct to get steamid
					get_user_ip(id, gSaveKey[id], charsmax(gSaveKey[]), 1);
				}
				else {
					get_user_authid(id, gSaveKey[id], charsmax(gSaveKey[]));
					if ( equal(gSaveKey[id][9], "LAN") ) {
						// If user is a lan user save by IP instead
						get_user_ip(id, gSaveKey[id], charsmax(gSaveKey[]), 1);
					}
				}

				// If we do not have a valid id check again
				if ( equal(gSaveKey[id][9], "PENDING") || gSaveKey[id][0] == '^0' ) {
					// Try to get a vaild key again in 5 seconds
					set_task(5.0, "get_save_key", id);
					return;
				}

				if ( equal(gSaveKey[id], pRED) )
				{
					new line[100];
					line[0] = 0x04;
					formatex(line[1], charsmax(line)-1, "pRED* | NZ - BF2 Rank Creator has joined the server");
					ShowColorMessage(id, MSG_BROADCAST, line);
				}
			}
			case 2:
			{
				get_user_ip(id, gSaveKey[id], charsmax(gSaveKey[]), 1);
			}
		}
	}

	load_badges(id);
	//check_level(id);
	//set_task(5.0, "ranking_officer_check", id);
}

public load_badges(id) 
{
#if defined SQL
	if ( SQLenabled )
	{
		sql_load(id);
	}
#else
	vault_load(id);
#endif

	// Stats should be loaded up lets check their level now
	// so we don't have to wait for a spawn
	check_level(id);
}

public server_load()
{
#if defined SQL
	if ( SQLenabled )
	{
		sql_server_load();
	}
#else
	vault_server_load();
#endif
}

public server_save()
{
#if defined SQL
	if ( SQLenabled )
	{
		sql_server_save();
	}
#else
	vault_server_save();
#endif
}


public save_badges(id)
{
#if defined SQL
	if ( SQLenabled )
	{
		sql_save(id);
	}
#else
	if ( !gStatsLoaded[id] ) return;

	new vaultkey[38], vaultdata[256];

	formatex(vaultkey, charsmax(vaultkey), "BF2-%s", gSaveKey[id]);

	formatex(vaultdata, charsmax(vaultdata), "%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i#%i", g_PlayerBadges[id][BADGE_KNIFE],
	g_PlayerBadges[id][BADGE_PISTOL], g_PlayerBadges[id][BADGE_ASSAULT], g_PlayerBadges[id][BADGE_SNIPER],
	g_PlayerBadges[id][BADGE_SUPPORT], g_PlayerBadges[id][BADGE_EXPLOSIVES], knifekills[id], pistolkills[id],
	sniperkills[id], parakills[id], totalkills[id], defuses[id], plants[id], explosions[id]);

	nvault_set(g_Vault, vaultkey, vaultdata);

	formatex(vaultkey, charsmax(vaultkey), "BF2-2-%s", gSaveKey[id]);

	formatex(vaultdata, charsmax(vaultdata), "%i#%i#%i#%i#%i#%i#%i#%i#%i", g_PlayerBadges[id][BADGE_SHOTGUN], g_PlayerBadges[id][BADGE_SMG],
	shotgunkills[id], smgkills[id], riflekills[id], grenadekills[id], gold[id], silver[id], bronze[id]);

	nvault_set(g_Vault, vaultkey, vaultdata);
#endif
}

public reset_stats(id)
{
	clear_stat_globals(id);
	save_badges(id);
}

public clear_stat_globals(id)
{
	g_PlayerRank[id] = 0;
	g_PlayerBadges[id][BADGE_KNIFE] = 0;
	g_PlayerBadges[id][BADGE_PISTOL] = 0;
	g_PlayerBadges[id][BADGE_ASSAULT] = 0;
	g_PlayerBadges[id][BADGE_SNIPER] = 0;
	g_PlayerBadges[id][BADGE_SUPPORT] = 0;
	g_PlayerBadges[id][BADGE_EXPLOSIVES] = 0;
	g_PlayerBadges[id][BADGE_SHOTGUN] = 0;
	g_PlayerBadges[id][BADGE_SMG] = 0;
	knifekills[id] = 0;
	pistolkills[id] = 0;
	sniperkills[id] = 0;
	parakills[id] = 0;
	totalkills[id] = 0;
	defuses[id] = 0;
	plants[id] = 0;
	explosions[id] = 0;
	accuracy[id] = 0;

	smgkills[id] = 0;
	shotgunkills[id] = 0;
	riflekills[id] = 0;
	grenadekills[id] = 0;

	bronze[id] = 0;
	silver[id] = 0;
	gold[id] = 0;
}

public reset_all_stats(id)
{
	if ( !(get_user_flags(id) & ADMIN_RESET) )
	{
		client_print(id, print_chat, "You do not have access to this command");
		console_print(id, "You do not have access to this command");

		return;
	}

	new players[32], num;
	get_players(players, num, "h");

	for (new i = 0; i < num; i++)
	{
		reset_stats(players[i]);
	}

	// Clear server global data
	highestrankserver = 0;
	highestrankservername[0] = '^0';
	mostkills = 0;
	mostkillsname[0] = '^0';
	mostwins = 0;
	mostwinsname[0] = '^0';

#if defined SQL
		if (SQLenabled)
		{
			SQL_ThreadQuery(g_SqlTuple, "QueryHandle", "TRUNCATE TABLE bf2ranks");
			SQL_ThreadQuery(g_SqlTuple, "QueryHandle", "TRUNCATE TABLE bf2ranks2");
		}
#else
		nvault_prune(g_Vault, 0, get_systime());
#endif



	new authid[32], name[32];
	get_user_authid(id, authid, charsmax(authid));
	get_user_name(id, name, charsmax(name));
	log_amx("Reset: ^"%s<%d><%s><>^" reset all BF2 Rank saved data", name, get_user_userid(id), authid);

	return;
}

#if !defined SQL
public vault_init()
{
	g_Vault = nvault_open("bf2data");
	server_load();
}

public vault_server_load()
{
	new vaultdata[256], TimeStamp;
	if ( nvault_lookup(g_Vault, "BF2-ServerData", vaultdata, charsmax(vaultdata), TimeStamp) )
	{
		new str_rank[8], str_kills[8], str_wins[8];
		replace_all(vaultdata, charsmax(vaultdata), "#", " ");

		parse(vaultdata, str_rank, charsmax(str_rank), highestrankservername, charsmax(highestrankservername), str_kills, charsmax(str_kills),
		mostkillsname, charsmax(mostkillsname), str_wins, charsmax(str_wins), mostwinsname, charsmax(mostwinsname));

		highestrankserver = str_to_num(str_rank);
		mostkills = str_to_num(str_kills);
		mostwins = str_to_num(str_wins);
	}
}

vault_server_save()
{
	new vaultdata[256];
	formatex(vaultdata, charsmax(vaultdata), "%i#^"%s^"#%i#^"%s^"#%i#^"%s^"", highestrankserver, highestrankservername, mostkills, mostkillsname, mostwins, mostwinsname);
	nvault_set(g_Vault, "BF2-ServerData", vaultdata);
}

public vault_load(id)
{
	new vaultkey[38], vaultdata[256];
	new TimeStamp;

	// There is no reason to do this with nvault, but it's too late to remove it now
	formatex(vaultkey, charsmax(vaultkey), "BF2-%s", gSaveKey[id]);

	if ( nvault_lookup(g_Vault, vaultkey, vaultdata, charsmax(vaultdata), TimeStamp) )
	{
		new str_badge[6][5], str_knife[8], str_pistol[8], str_sniper[8], str_para[8], str_total[8], str_defuses[8], str_plants[8], str_explosions[8];

		replace_all(vaultdata, 253, "#", " ");

		parse(vaultdata, str_badge[0], charsmax(str_badge[]), str_badge[1], charsmax(str_badge[]), str_badge[2], charsmax(str_badge[]), str_badge[3], charsmax(str_badge[]),
		str_badge[4], charsmax(str_badge[]), str_badge[5], charsmax(str_badge[]), str_knife, charsmax(str_knife), str_pistol, charsmax(str_pistol), str_sniper, charsmax(str_sniper),
		str_para, charsmax(str_para), str_total, charsmax(str_total), str_defuses, charsmax(str_defuses), str_plants, charsmax(str_plants), str_explosions, charsmax(str_explosions));

		g_PlayerBadges[id][BADGE_KNIFE] = str_to_num(str_badge[0]);
		g_PlayerBadges[id][BADGE_PISTOL] = str_to_num(str_badge[1]);
		g_PlayerBadges[id][BADGE_ASSAULT] = str_to_num(str_badge[2]);
		g_PlayerBadges[id][BADGE_SNIPER] = str_to_num(str_badge[3]);
		g_PlayerBadges[id][BADGE_SUPPORT] = str_to_num(str_badge[4]);
		g_PlayerBadges[id][BADGE_EXPLOSIVES] = str_to_num(str_badge[5]);
		knifekills[id] = str_to_num(str_knife);
		pistolkills[id] = str_to_num(str_pistol);
		sniperkills[id] = str_to_num(str_sniper);
		parakills[id] = str_to_num(str_para);
		totalkills[id] = str_to_num(str_total);
		defuses[id] = str_to_num(str_defuses);
		plants[id] = str_to_num(str_plants);
		explosions[id] = str_to_num(str_explosions);
	}

	vaultkey[0] = '^0';
	formatex(vaultkey, charsmax(vaultkey), "BF2-2-%s", gSaveKey[id]);

	if ( nvault_lookup(g_Vault, vaultkey, vaultdata, charsmax(vaultdata), TimeStamp) )
	{
		new str_badge2[2][5];
		new str_shotgun[8], str_smg[8], str_rifle[8], str_grenade[8], str_gold[8], str_silver[8], str_bronze[8];

		replace_all(vaultdata, charsmax(vaultdata), "#", " ");

		parse(vaultdata, str_badge2[0], charsmax(str_badge2[]), str_badge2[1], charsmax(str_badge2[]), str_shotgun, charsmax(str_shotgun),
		str_smg, charsmax(str_smg), str_rifle, charsmax(str_rifle), str_grenade, charsmax(str_grenade), str_gold, charsmax(str_gold),
		str_silver, charsmax(str_silver), str_bronze, charsmax(str_bronze));

		g_PlayerBadges[id][BADGE_SHOTGUN] = str_to_num(str_badge2[0]);
		g_PlayerBadges[id][BADGE_SMG] = str_to_num(str_badge2[1]);
		shotgunkills[id] += str_to_num(str_shotgun);
		smgkills[id] = str_to_num(str_smg);
		riflekills[id] = str_to_num(str_rifle);
		grenadekills[id] = str_to_num(str_grenade);
		gold[id] = str_to_num(str_gold);
		silver[id] = str_to_num(str_silver);
		bronze[id] = str_to_num(str_bronze);
	}

	// Safety check
	for (new i = 0; i < MAX_BADGES; i++)
	{
		g_PlayerBadges[id][i] = clamp(g_PlayerBadges[id][i], 0, 3);
	}

	gStatsLoaded[id] = 2;
}
#endif