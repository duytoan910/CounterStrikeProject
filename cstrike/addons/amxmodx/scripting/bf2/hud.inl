//Bf2 Rank Mod HUD File
//Contains all the HUD functions.

#if defined bf2_hud_included
  #endinput
#endif
#define bf2_hud_included

//Show an announcement display
public Announcement(id)
{
	if ( !get_pcvar_num(gPcvarBF2Active) || is_user_bot(id) ) return;

	client_print(id, print_chat, "[BF2] This server is running %s. Say ^"/bf2menu^" for more info", gPluginName);
}

//Displays the HUD to the user
public DisplayHUD(id)
{
	if ( !get_pcvar_num(gPcvarBF2Active) || !get_pcvar_num(gPcvarStatusText) ) return; 
	if ( !is_user_alive(id) || is_user_bot(id) ) return;

	static HUD[64];

	if ( !gStatsLoaded[id] )
	{
		formatex(HUD, charsmax(HUD), "[BF2] Loading saved data...");
	}
	else
	{
		new rank = g_PlayerRank[id];
		new nextrank;

		switch(rank)
		{
			case 16, 19, 20: nextrank = 15;
			case 17: nextrank = 7;
			case 18: nextrank = 8;
			default: nextrank = rank;
		}

		++nextrank;

		new nextrankxp = floatround(gRankXP[nextrank] * get_pcvar_float(gPcvarXpMultiplier));

		if ( !get_pcvar_num(gPcvarBadgesActive) )
		{
			formatex(HUD, charsmax(HUD), "Pts: %d/%d (%s)", totalkills[id], nextrankxp, gRankName[rank]);
		}
		else
		{
			formatex(HUD, charsmax(HUD), "Pts: %d/%d Badges: %d (%s)", totalkills[id], nextrankxp, numofbadges[id], gRankName[rank]);
		}
	}

	message_begin(MSG_ONE_UNRELIABLE, gmsgStatusText, {0.5,0.8,0.0}, id);
	write_byte(0);
	write_string(HUD);
	message_end();
}