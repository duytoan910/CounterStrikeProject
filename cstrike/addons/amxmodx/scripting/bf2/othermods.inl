//Bf2 Rank Mod othermods File
//Contains all the functions for bf2 to register flag scoring from CS flag mod.

#if defined bf2_flag_included
  #endinput
#endif
#define bf2_flag_included

public csf_flag_taken(id)
{
	if ( get_playersnum() < get_pcvar_num(gPcvarXpMinPlayers) ) return;

	new tempkills = get_pcvar_num(gPcvarFlagKills);

	if ( tempkills < 1 ) return;

	totalkills[id] += tempkills;
	DisplayHUD(id);
	client_print(id, print_chat, "[BF2] You received %d points for capturing the flag", tempkills);
}

public csf_round_won(CsTeams:team)
{
	if ( get_playersnum() < get_pcvar_num(gPcvarXpMinPlayers) ) return;

	new tempkills = get_pcvar_num(gPcvarFlagRoundPoints);

	if ( tempkills < 1 ) return;

	for ( new id = 1; id <= gMaxPlayers; id++ )
	{
		if ( !is_user_connected(id) ) continue;
		if ( cs_get_user_team(id) != team ) continue;

		totalkills[id] += tempkills;
		DisplayHUD(id);
		client_print(id, print_chat, "[BF2] You received %d points because your team won the flag round", tempkills);
	}
}

public csf_match_won(CsTeams:team)
{
	if ( get_playersnum() < get_pcvar_num(gPcvarXpMinPlayers) ) return;

	new tempkills = get_pcvar_num(gPcvarFlagMatchPoints);

	if ( tempkills < 1 ) return;

	for ( new id = 1; id <= gMaxPlayers; id++ )
	{
		if ( !is_user_connected(id) ) continue;
		if ( cs_get_user_team(id) != team ) continue;

		totalkills[id] += tempkills;
		DisplayHUD(id);
		client_print(id, print_chat, "[BF2] You received %d points because your team won the flag match", tempkills);
	}
}