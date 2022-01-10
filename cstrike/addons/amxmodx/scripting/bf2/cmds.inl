//Bf2 Rank Mod Commands File
//Contains all the client command functions

#if defined bf2_cmds_included
  #endinput
#endif
#define bf2_cmds_included

//Public menu / say commands. Help motds etc..
public show_rankhelp(id)
{
	if (!get_pcvar_num(gPcvarBF2Active))
		return;

	new tempstring[100];
	new motd[2048];
	new Float:xpmult=get_pcvar_float(gPcvarXpMultiplier);

	new kills;

	formatex(motd, charsmax(motd), "<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong>");
	formatex(tempstring, charsmax(tempstring), "Rank Points Table</strong><br><br>");
	add(motd, charsmax(motd), tempstring);

	for (new counter = 0; counter < (MAX_RANKS-1); counter++)
	{
		kills = floatround(float(gRankXP[counter])*xpmult);
		formatex(tempstring, charsmax(tempstring), "%s - %d pts", gRankName[counter], kills);
		add(motd, charsmax(motd), tempstring);
		add(motd, charsmax(motd), "<br>");

		switch(counter)
		{
			case 7:
			{
				formatex(tempstring, charsmax(tempstring), "%s - Requires %s and %d Badges *", gRankName[17], gRankName[7], MAX_BADGES);
				add(motd, charsmax(motd), tempstring);
				add(motd, charsmax(motd), "<br>");
			}
			case 8:
			{
				formatex(tempstring, charsmax(tempstring), "%s - Requires %s and %d Badges *", gRankName[18], gRankName[8], MAX_BADGES*2);
				add(motd, charsmax(motd), tempstring);
				add(motd, charsmax(motd), "<br>");
			}
		}
	}

	formatex(tempstring, charsmax(tempstring), "%s - Requires %s and %d Badges", gRankName[19], gRankName[15], MAX_BADGES*3);
	add(motd, charsmax(motd), tempstring);
	add(motd, charsmax(motd), "<br>");

	kills = floatround(float(gRankXP[MAX_RANKS-1])*xpmult);
	formatex(tempstring, charsmax(tempstring), "%s - Requires %s and %d pts", gRankName[16], gRankName[19], kills);
	add(motd, charsmax(motd), tempstring);
	add(motd, charsmax(motd), "<br>");

	formatex(tempstring, charsmax(tempstring), "%s - Requires %s and to keep the #1 Rank in the server", gRankName[20], gRankName[16]);
	add(motd, charsmax(motd), tempstring);
	add(motd, charsmax(motd), "<br>");

	add(motd, charsmax(motd), "<br> * Speacial Ranks - These will be skipped if you do not have the badge requirements");
	add(motd, charsmax(motd), "</font></body></html>");

	show_motd(id, motd, "BF2: Rank Requirements");

	Bf2menu(id);
}

public show_server_stats(id)
{
	if (!get_pcvar_num(gPcvarBF2Active))
		return PLUGIN_CONTINUE;

	new tempstring[100];
	new motd[2048];
	new names[4][32];

	get_user_name(highestrankid, names[0], charsmax(names[]));

	formatex(motd,charsmax(motd),"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong>");
	formatex(tempstring,charsmax(tempstring),"Currently Playing</strong><br><br>");
	add(motd,charsmax(motd),tempstring);

	formatex(tempstring,charsmax(tempstring),"Highest Ranked: %s %s<br><br>",gRankName[highestrank],names[0]);
	add(motd,charsmax(motd),tempstring);

	formatex(tempstring,charsmax(tempstring),"<strong>Server Stats</strong><br><br>");
	add(motd,charsmax(motd),tempstring);

	formatex(tempstring,charsmax(tempstring),"Highest Ranked: %s %s<br><br>", gRankName[highestrankserver], highestrankservername);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Most Points: %s %i<br><br>",mostkillsname,mostkills);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Most Wins: %s %i<br><br>",mostwinsname,mostwins);
	add(motd,charsmax(motd),tempstring);
	add(motd,charsmax(motd),"</font></body></html>");

	show_motd(id,motd,"BF2: Server Stats");

	Bf2menu(id);

	return PLUGIN_CONTINUE;
}

public show_badgehelp(id)
{
	if (!get_pcvar_num(gPcvarBF2Active))
		return PLUGIN_CONTINUE;

	new url[100];
	get_pcvar_string(gPcvarHelpUrl,url,charsmax(url));

	if (equal(url,""))
	{
		formatex(configfile,charsmax(configfile),"%s/bf2/badges1.html",configsdir);	
	}
	else
	{
		formatex(configfile,charsmax(configfile),"%s/badges1web.html",url);
	}
	show_motd(id, configfile, "BF2: Badege Help 1");

	Bf2menu(id);

	return PLUGIN_CONTINUE;
}

public show_badgehelp2(id)
{
	if (!get_pcvar_num(gPcvarBF2Active))
		return PLUGIN_CONTINUE;

	new url[100];
	get_pcvar_string(gPcvarHelpUrl,url,charsmax(url));

	if (equal(url,""))
	{
		formatex(configfile,charsmax(configfile),"%s/bf2/badges2.html",configsdir);
	}
	else
	{
		formatex(configfile,charsmax(configfile),"%s/badges2web.html",url);
	}

	show_motd(id, configfile, "BF2: Badege Help 2");

	Bf2menu(id);

	return PLUGIN_CONTINUE;
}

public show_badgehelp3(id)
{
	if (!get_pcvar_num(gPcvarBF2Active))
		return PLUGIN_CONTINUE;

	new url[100];
	get_pcvar_string(gPcvarHelpUrl,url,charsmax(url));

	if (equal(url,""))
	{
		formatex(configfile,charsmax(configfile),"%s/bf2/badges3.html",configsdir);
	}
	else
	{
		formatex(configfile,charsmax(configfile),"%s/badges3web.html",url);
	}

	show_motd(id, configfile, "BF2: Badege Help 3");

	Bf2menu(id);

	return PLUGIN_CONTINUE;
}

public cmd_say(id)
{
	if (!get_pcvar_num(gPcvarBF2Active))
		return PLUGIN_CONTINUE;

	new Arg1[31];
	read_args(Arg1, charsmax(Arg1));
	remove_quotes(Arg1);

	if (!((equal(Arg1, "/whois",6)) || (equal(Arg1, "/whostats",6))))
		return PLUGIN_CONTINUE;

	if (equal(Arg1, "/whostats",6))
	{
		new player = cmd_target(id, Arg1[10], 0);
		if (!player)
		{
			client_print(id,print_chat, "[BF2] Sorry, player %s could not be found or targetted!", Arg1[10]);
			return PLUGIN_CONTINUE;
		}

		display_stats(id,player);

		return PLUGIN_CONTINUE;
	}

	new player = cmd_target(id, Arg1[7], 0);

	if (!player)
	{

		client_print(id,print_chat, "[BF2] Sorry, player %s could not be found or targetted!", Arg1[7]);
		return PLUGIN_CONTINUE;
	}

	display_badges(id,player);

	return PLUGIN_CONTINUE;
}

public display_badges(id,badgeid)
{
	new name[32];
	get_user_name(badgeid,name,charsmax(name));

	new tempstring[100];
	new motd[2048];

	formatex(motd,charsmax(motd),"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong><b>");
	formatex(tempstring,charsmax(tempstring),"Rank and Badge Info: %s </strong></b>", name);
	add(motd,charsmax(motd),tempstring);
	add(motd,charsmax(motd),"<br><br>");
	formatex(tempstring,charsmax(tempstring),"Rank: %s",gRankName[g_PlayerRank[badgeid]]);
	add(motd,charsmax(motd),tempstring);
	add(motd,charsmax(motd),"<br><br>");

	if (!get_pcvar_num(gPcvarBadgesActive))
	{
		add(motd,charsmax(motd),"</font></body></html>");
		show_motd(id,motd,"BF2: Player Info");

		return PLUGIN_CONTINUE;
	}

	formatex(tempstring,charsmax(tempstring),"Badges Awarded: %d/%d<br>", numofbadges[badgeid], MAX_BADGES*3);
	add(motd,charsmax(motd),tempstring);

	for (new counter=0; counter<MAX_BADGES; counter++)
	{
		if(g_PlayerBadges[badgeid][counter]!=0)
		{
			formatex(tempstring,charsmax(tempstring),"&nbsp;%s",gBadgeName[counter][g_PlayerBadges[badgeid][counter]]);
			add(motd,charsmax(motd),tempstring);
			formatex(tempstring,charsmax(tempstring)," - %s<br>",gBadgeInfo[counter]);
			add(motd,charsmax(motd),tempstring);
		}
	}

	add(motd,charsmax(motd),"</font></body></html>");

	show_motd(id,motd,"BF2: Player Info");

	Bf2menu(id);

 	return PLUGIN_CONTINUE;
}

public cmd_who(id)
{
	if (!get_pcvar_num(gPcvarBF2Active))
		return PLUGIN_CONTINUE;

	new tempstring[100],players[32],num,tempname[32];
	new motd[2048];

	formatex(motd,charsmax(motd),"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong><b>Player Ranks</strong></b><br><br>");

	get_players(players,num);

	for (new counter=0; counter<num; counter++)
	{
		get_user_name(players[counter], tempname, charsmax(tempname));
		formatex(tempstring,charsmax(tempstring),"%s - %s<br>",tempname,gRankName[g_PlayerRank[players[counter]]]);
		add(motd,charsmax(motd),tempstring);

	}
	add(motd,charsmax(motd),"</font></body></html>");

	show_motd(id,motd,"BF2: Player Ranks");

	Bf2menu(id);

	return PLUGIN_CONTINUE;

}

public cmd_help(id)
{
	if (!get_pcvar_num(gPcvarBF2Active))
		return PLUGIN_CONTINUE;

	new url[100];
	get_pcvar_string(gPcvarHelpUrl,url,charsmax(url));

	if (equal(url,""))
	{
		formatex(configfile,charsmax(configfile),"%s/bf2/help.html",configsdir);
	}
	else
	{
		formatex(configfile,charsmax(configfile),"%s/helpweb.html",url);
	}

	show_motd(id, configfile, "BF2: Help");

	Bf2menu(id);

	return PLUGIN_CONTINUE;

}

public show_stats(id)
{
	if (!get_pcvar_num(gPcvarBF2Active))
		return PLUGIN_CONTINUE;

	display_stats(id,id);

	Bf2menu(id);

	return PLUGIN_CONTINUE;

}

public display_stats(id,statsid)
{
	new tempstring[100];
	new motd[2048];
	new stats[8],bodyhits[8];
	new ranked=get_user_stats(statsid, stats, bodyhits);
	new tempname[32];
	get_user_name(statsid,tempname,charsmax(tempname));

	formatex(motd,charsmax(motd),"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong>Player Stats: %s</strong><br>", tempname);
	add(motd,charsmax(motd),"(updated on spawn/round)<br><br>");

	formatex(tempstring,charsmax(tempstring),"Global Points: %d<br>",totalkills[statsid]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Global Knife Kills: %d<br>",knifekills[statsid]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Global Pistol Kills: %d<br>",pistolkills[statsid]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Global M249 Kills: %d<br>",parakills[statsid]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Global Sniper Kills: %d<br>",sniperkills[statsid]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Global Rifle Kills: %d<br>",riflekills[statsid]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Global Shotgun Kills: %d<br>",shotgunkills[statsid]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Global SMG Kills: %d<br>",smgkills[statsid]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Global Accuracy: %d percent<br>",accuracy[statsid]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Global Bomb Plants: %d<br>",plants[statsid]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Global Bomb Explosions: %d<br>",explosions[statsid]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Global Bomb Defuses: %d<br>",defuses[statsid]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Global Grenade Kills: %d<br>",grenadekills[statsid]);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Player Rank: #%d<br>",ranked);
	add(motd,charsmax(motd),tempstring);
	formatex(tempstring,charsmax(tempstring),"Medals Earned: Gold %d, Silver %d, Bronze %d<br>",gold[statsid],silver[statsid],bronze[statsid]);
	add(motd,charsmax(motd),tempstring);

	add(motd,charsmax(motd),"</font></body></html>");

	show_motd(id,motd,"BF2: Player Stats");

}

//Admin only commands below here


//Gives badge to specified player
public add_badge(id,level,cid)
{
	if (!cmd_access(id, level, cid, 4)) return PLUGIN_HANDLED;

	new Arg1[24];
	new Arg2[4];
	new Arg3[4];


	read_argv(1, Arg1, charsmax(Arg1));
	read_argv(2, Arg2, charsmax(Arg2));
	read_argv(3, Arg3, charsmax(Arg3));

	new badge = str_to_num(Arg2);
	new level = str_to_num(Arg3);

	new player = cmd_target(id, Arg1, 0);

	if (!player || (level>3) || (level<0) || (badge>7) || (badge<0))
        {
			console_print(id, "Sorry, player %s could not be found or targetted!, Or invalid badge/level", Arg1);
			return PLUGIN_HANDLED;
	} else {
			g_PlayerBadges[player][badge]=level;
			client_print(id,print_chat,"[BF2] %s badge has been awarded to %s",gBadgeName[badge][level],Arg1);
			save_badges(player);
			DisplayHUD(player);
        }

	new adminauthid[35];
	new awardauthid[35];
	get_user_authid (id,adminauthid,charsmax(adminauthid));
	get_user_authid (player,awardauthid,charsmax(awardauthid));

	log_amx("[BF2-ADMIN]Admin %s awarded badge %s to player %s",adminauthid,gBadgeName[badge][level],awardauthid);

	return PLUGIN_HANDLED;
}

//Gives kills to specified player
public add_kills(id,level,cid)
{
	if (!cmd_access(id, level, cid, 3))
        	return PLUGIN_HANDLED;

     	new Arg1[24];
     	new Arg2[6];

     	read_argv(1, Arg1, charsmax(Arg1));
     	read_argv(2, Arg2, charsmax(Arg2));

     	new kills = str_to_num(Arg2);

	new player = cmd_target(id, Arg1, 0);

	if (!player)
        {
			console_print(id, "Sorry, player %s could not be found or targetted!", Arg1);
			return PLUGIN_HANDLED;
        } else {
			totalkills[player]+=kills;
			client_print(id,print_chat,"[BF2] %d kills have been awarded to %s",kills,Arg1);
			save_badges(player);
			DisplayHUD(player);
        }

	new adminauthid[35];
	new awardauthid[35];
	get_user_authid(id,adminauthid,charsmax(adminauthid));
	get_user_authid(player,awardauthid,charsmax(awardauthid));

	log_amx("[BF2-ADMIN]Admin %s awarded %i kills to player %s",adminauthid,kills,awardauthid);

	return PLUGIN_HANDLED;
}