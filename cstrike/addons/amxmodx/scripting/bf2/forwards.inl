//Bf2 Rank Mod forwards File
//Contains all the standard forwarded functions

#if defined bf2_forward_included
  #endinput
#endif
#define bf2_forward_included

public plugin_precache()
{
	new tempSound[64];
	formatex(tempSound, charsmax(tempSound), "sound/%s", gSoundRank);
	if ( !file_exists(tempSound) )
	{
		copy(gSoundRank, charsmax(gSoundRank), "buttons/bell1.wav");
	}

	formatex(tempSound, charsmax(tempSound), "sound/%s", gSoundBadge);
	if ( !file_exists(tempSound) )
	{
		copy(gSoundBadge, charsmax(gSoundBadge), "fvox/bell.wav");
	}

	precache_sound(gSoundRank);
	precache_sound(gSoundBadge);

	new bool:error = false;
	new spriteFile[26];

	for ( new counter; counter < MAX_RANKS+4; counter++)
	{
		spriteFile[0] = '^0';
		formatex(spriteFile, charsmax(spriteFile), "sprites/bf2rankspr/%d.spr", counter);

		//Done this way so that a message is logged for each missing file
		if ( !file_exists( spriteFile ) )
		{
			log_amx("[ERROR] Missing plugin required sprite file: ^"%s^"", spriteFile);
			error = true;
		}
		else {
			gSprite[counter] = precache_model(spriteFile);
		}
	}

	if ( error )
	{
		set_fail_state("One or more sprite files required by the plugin not found, check amxmodx logs more info");
		//set_fail_state("Sprite files are missing, unable to load plugin");
	}
}

public plugin_cfg()
{
	get_configsdir(configsdir, charsmax(configsdir));

//SQL
#if defined SQL
	SQLenabled = false;
	sql_init();
#else
	vault_init();
#endif

	set_cvar_string("bf2_version", gPluginVersion);

	if ( gPlayerName != -1 && get_xvar_num(gPlayerName) )
	{
		log_amx("miscstats.amxx ^"PlayerName^" option is on, BF2 player aim info hud message will not be shown.");
	}

	//set_task(10.0, "ranking_officer_disconnect");
}

public client_putinserver(id)
{
	// Find a czero bot to register Ham_Spawn
	if ( !gCZBotRegisterHam && gPcvarBotQuota && get_pcvar_num(gPcvarBotQuota) > 0 && is_user_bot(id) )
	{
		// Delay for private data to initialize
		set_task(0.1, "RegisterHam_CZBot", id);
	}

	g_imobile[id] = false;
	newplayer[id] = true;
	gStatsLoaded[id] = 0;

	get_save_key(id);

	set_task(20.0, "Announcement", id);
}

public client_disconnect(id)
{
	save_badges(id);

	if ( id == highestrankid )
	{
		set_task(2.0, "ranking_officer_disconnect");
	}

	clear_stat_globals(id);
	gStatsLoaded[id] = 0;
}

public plugin_end()
{
	server_save();

#if defined SQL
	if ( SQLenabled )
	{
		//Free the handle thingy..
		SQL_FreeHandle(g_SqlTuple);
	}
#else
	new pruneDelay = (NEGATIVE_SECONDSINDAY * get_pcvar_num(gPcvarPruneDays));
	if ( pruneDelay < 0 )
	{
		nvault_prune(g_Vault, 0, get_systime(pruneDelay));
	}

	nvault_close(g_Vault);
#endif
}