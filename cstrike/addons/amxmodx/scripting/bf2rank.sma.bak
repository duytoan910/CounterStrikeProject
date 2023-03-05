/************************************************************************************************************************************
*	Battlefield 2: Rank Mod by pRED* - anaconda.182@gmail.com
*
*	An attempt to recreate the battlefield ranking system onto cs1.6
*	Currently features the basics of the ranking system, with no power up gain recieved from leveling.
*
*	Ranks are based on the number of kills from the csstats system
*
*	Badges can also be earned to get power up bonuses - See rewards list. Or look at /bf2menu in game
*
*
*	Wish list: 	Add some more badges maybe? Ive put some ideas in comments...
*			Rank pictures..
*
*	Known Bugs	General optimization stuff - Ive done most in the wiki tut but there may be more
*
*	Rewards:	Knife - 20/40/60% of damage done with knife returned to player
*			Support - +2/+4/+6 M249 damage per bullet
*			Pistol � 20/25/33% chance of stunning attacker
*			Assault - +10/+20/+30 Bonus HP when spawning
*			Sniper - 1/3,1/2,1/1 Chance of Free awp/scout
*			Explosives - .2/.4/.6 multiplier added to Grenade damage
*			Shotgun - 150/100/50 alpha level invisibility with Knife
*			SMG � 15/30/45 speed boost added for all weapons
*
*	Credits:	Xuntric and PM for their combined work on the XP based plugin tutorial (load, save and menu stuff..)
*			Avalanche for the removed cone of fire in i_aim_good plugin (used for lowered recoil on the para)
*			Phantom Warrior and palehorse for inadvertently giving me the idea for this (Military Rank Mod thread..)
*			ev0d00b cos I stole lots of code out of his/our Capture the Hax Plugin
*			Ubernet (games.uber.net.nz) for giving me a test server and help test the mod
*			stupok69 for helping fix the /whois command
*			Geesu for all his defined cs weapon speeds used in wc3ft (resetting users speed after imobilising them),
*			and some great examples of screen flashes and shakes.
*			Cheap_Suit for the extra recoil code
*			Hawk522 for his tutorial on SQLx (and helping me debug problems with it)
*			styremelaker for massive amount of csdm testing.
*			vittu for going through the code and finding heaps of mistakes and efficiency changes
*			teamme06 for his colorchat code
*			vittu again for supporting my plugin more than I do..
*			BlueRaja for player kills and score update code from his damage multiplier plugin (big copy, paste of the kill function)
*			palehorse for the web html documents
*			vittu for testing and helping fix bugs in the code.
*			Emp' for the new amxx menu tutorial
*
*	Cvars (copy/paste the following to amxx.cfg):

////////////////////////  Battlefield 2: Rank Mod  ////////////////////////

bf2_active 1		//(1|0) - Turns the plugin on or off - Default 1
bf2_badges 1		//(1|0) - Turns the badge system on or off - Default 1
bf2_badgepowers 0	//(1|0) - Enable/Disable the powers for the badges - Default 0
bf2_awp 0		//(1|0) - Is user given an awp or scout by having the sniper badge - Default 0 (scout)
bf2_ffa 0		//(1|0) - Enable/Disable team attack for receiving pts and for badge use, turn on for "free for all" servers - Default 0
bf2_xpmultiplier 0.1	//(float) - Changes the point multiplier needed to reach each level - Default 0.1 (15 points for rank 1, 20k points for top rank)
bf2_xpminplayers 2	//(int) - Minimum number of plays required to be in server before bonus bomb and flag xp (only) is awarded
bf2_reset_days 21	//(int) - Number of days without playing till xp gets pruned per user (Note: currently nvault saving only)
bf2_icon_time 1.5	//(float) - Amount of time to display the rank icons for. Default 1.5, 0 to disable icons all together.
bf2_help_url ""		//(string) - Remote folder where the bf2 web docs are stored (optional) do not include the trailing /
bf2_statustext 1	//(int) - Enable/Disable the points, # of bagdges, and rank info that replaces player name info in hud - Default 1
bf2_hud_options "abcde"	//(flags) - Set options for player aim hud message info (not shown if miscstats PlayerName option is on) - Default "abcde"
			//flag a - Display Health/Armor/Weapon for teammates
			//flag b - Display Rank for teammates
			//flag c - Display Rank for enemies
			//flag d - Hide display for invisible enemies
			//flag e - Move the display to above peoples heads

//CS Flags integration
bf2_flag_kills 2	//(int) - CS Flags - How many bf2 points are awarded for capturing a flag
bf2_flag_round_kills 0	//(int) - CS Flags - How many bf2 points are awarded for winning a round
bf2_flag_match_kills 0	//(int) - CS Flags - How many bf2 points are awarded for winning the match

///////////////////////////////////////////////////////////////////////////

*
*	Cmds:		say /bf2menu - Shows the Main Menu
*			say /who - Shows a list of player and their rank
*			say /whois <name> - Show the rank and badges of a specific player
*			say /whostats <name> - Show the stats page for a player
*			say /ranks - Shows the kill xp table
*			say /bf2stats - your personal stats pages
*			say /help - Displays a Help MOTD
*			say /badges1 - Displays a Help MOTD on some of the badges
*			say /badges2 - Displays a Help MOTD on the rest of the badges
*			say /badges3 - Badges 3
*			bf2_resetstats - Resets all of your stats
*			bf2_addbadge <player> <badge> <level> - Gives a badge to player. Requires Ban admin access. Badge <0-5>. Level <0-3>
*			bf2_addkills <player> <kills> - Adds to a players kills.. Also requires ban access
*			bf2_resetserverstats - Erases all players stats
*
*	Changelog:
*			1.5.5 -	4/21/11
*				Fixed Assult Badge health bonus to only give health if less than current health to avoid conflicts.
*				Fixed max armor bonus to only give armor if less than current armor to avoid conflicts.
*
*			1.5.4 -	4/18/11
*				Changed data to load instantly instead of on tasks in plugin_cfg due to possible bug with bots.
*				Skipped nVault pruning if bf2_reset_days is set to 0.
*				Fixed bf2_resetserverstats to clear server bf2 stats and SQL's bf2ranks2 table data.
*				Changed Lieutenant General and General to be obtainable when badges are turned off.
*
*			1.5.3 -	6/8/10
*				Fixed bf2_hud_options to allow disabling player aim hud message info by setting cvar to nothing "".
*
*			1.5.2 -	8/31/09
*				Changed bf2_flag_min_players to bf2_xpminplayers and made it include bomb xp
*				Added bf2_statustext cvar to allow disabling replacement of hud name info, may also be used by other mods
*				Changed bf2_badgepowers cvar to be off by default.
*				Changed bf2_hud_options cvar to include e by default, the comments said it was included but was not.
*				Small updates to information in help motd's and other motd edits.
*				Fixed speed check to run on spawn and round start.
*
*			1.5.1 -	4/18/09
*				Fixed bf2_resetserverstats command to use ADMIN_RESET instead of ADMIN_LEVEL define
*				Fixed pistol badge code from being run on self from a suicide
*				Removed useless /hud command
*
*			1.5 -	4/15/09
*				Added saving by IP and nick controlled by csstats_rank cvar
*				Added saving for bots controlled by csstats_rankbots cvar
*				Added bf2_ffa cvar to enable/disable team kills to count for points
*				Added use of Hamsandwich for spawn and damage change code
*				Added check for PlayerName miscstats option to disable BF2's hud info
*				Added 2 Optional sounds from BF2 for rank and badge gain
*				Fixed speed system and added calls for FOV speed changes
*				Fixed badge checking not being checked on death not from a player 
*				Updated SQL saving code for improvements
*				Removed CSDM define and bf2_csdm.inl as changes made them unnecessary now
*				Removed fakemeta_util_mini.inl and included fakemeta_util.inc
*				Removed excess calls of DisplayHUD and save_badges
*				Fixed variable length that hold player names
*				Fixed a few possible out of bounds strings, still need to fix rest
*				Changed default ADMIN_RESET define to ADMIN_RCON from ADMIN_CFG
*				Fixed knife badge max hp and to only show blue glow/screenflash if hp is given
*
*			1.4.1 - 2/27/09
*				vittu takes over maintaining the plugin due to pRED moving to Source
*				Fixed CS Flags compatibility
*				Fixed TK giving points, will set an option to enable later
*				Fixed self grenade kill from adding to grenade kills
*				Fixed missing Lt General rank issue
*				Fixed description of requirements for special and higher ranks
*				Updated rank requirements not updated when more badges were last added
*				Adjusted StatusText, points hud info, to better fit max character amount
*				Added band-aid fix for auto save by steamid or IP, will update method later
*
*			1.4 -	Fixed wrong sprites displaying
*				fixed double hp gain on round reset (CSDM)
*				added /whostats command
*				bf2_help_url (and web motds) and bf2_badgepowers cvars
*				fixed sprites
*				CSDM badges not being awarded.
*				Top ranked in server display message
*				New menus
*				reset your stats command
*				Medals other new stats
*				Logging admin commands
*				Two new badges. Fixed Explosives badge for csdm
*				Heaps of new stats options + saving them (server and player)
*				Changed power for support
*				SQL now a defined option
*				Moved needed fakemeta_util functions into a separate file (included)
*				New HUD system thanks to vittu (added cvar to control it)
*				bf2_reset_days cvar - number of days without playing till xp gets reset
*
*			1.31 -	Lowered chance of imobilising happening.
*				Changed damage event and bomb events to the csx forward versions and created a csx forward include
*				Capped knife badge damage to 130
*				Removed bf2_vaultload (pointless now.)
*				Fixed some spelling newbie mistakes..
*				Fixed immunity problems
*				Moved inl and config files into their own folder..
*				Probably a few other things too..
*
*			1.30 -	Starting work on 4 New ranks
*				Shows Teammates rank when you look at them.
*				Give 50,100,200 armour for having 6,12 or 18 badges..
*				Bf2 now saves totalkills itself. Prevents csstats resets..
*				bf2_addkills (admin abuse tool? - or to reset after csstats reset), gives x kills to a player
*				Reduced the amount of saving to vault - causing server lag.
*				Changed to nVault saving. Now uses only 1 vault data instead of 14.
*				Fixed armour being lower than you had before
*				Split file into large set of includes. Way easier to find functions you want.
*				Added +3 kills for defuse/explode. Cs flags mod support
*
*			1.23 -  Added CSDM functionality. Give hp/weapons on all spawns.
*				Recoded badge checking to be individual on player death
*				Fixed HP bug and added message "beginning badge check"
*
*			1.22 -  bf2_addbadge admin command added
*
*			1.21 -	Added a badge check 5 seconds before map changes.
*
*			1.2 - 	Massive change to make global kill counting actually work..
*				Added screen to view weapon stats "say /bf2stats" or use the menu
*				Added concmd "bf2_vaultload" to forcibly load your own data from the vault (im using it to convert my stats from vault to sql)
*				Tell people to type bf2_vaultload into console and their badges will be restored. Other than that probably a useless command
*
*			1.1 - 	Fixed Bug with Veteran Assault badge
*				Added SQL support (bf2_sql 1)
*				Changed support badge to bonus speed (added code for extra damage, recoil - will finish when amxx 1.77 is released)
*				Sounds, Screen Shake, User glows..
*
*	Requires:
*			Fun, FakeMeta, Ham Sandwich, CStrike, CSX, and (nVault or MySQL) modules
*
*	( Optional sounds edited from Battlefield 2 - http://www.battlefield.ea.com/battlefield/bf2/ )
************************************************************************************************************************************/
//#pragma semicolon 1

//************************************ Compile Settings ************************************//
// Uncomment to use MySQL instead of the default nVault saving
//#define SQL

// Admin flag settings for giving points/badges and server saved data reset
// These can also be set in cmdaccess.ini without need to change here
// (See amxconst.inc for more admin level constants)
#define ADMIN_LEVEL ADMIN_BAN
#define ADMIN_RESET ADMIN_RCON

// Note: Changing any of the above the above requires plugin to be recompiled
//******************************************************************************************//

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <csx>
#include <fun>
#include <zombieplague>

new const gPluginName[] = "Battlefield 2: Rank Mod";
new const gPluginVersion[] = "1.5.5";

//Message sending variables
new gmsgStatusText;
new gmsgScreenFade;
new gmsgScreenShake;
new gmsgSayText;

new gHudSyncAimInfo;
new gMaxPlayers;
new bool:gCZBotRegisterHam;

#define MAX_RANKS 17
#define MAX_BADGES 8

//Motd variables
new configsdir[200];
new configfile[200];

//Cvar vars
new gPcvarBF2Active;
new gPcvarBadgesActive;
new gPcvarFreeAwp;
new gPcvarXpMultiplier;
new gPcvarIconTime;
new gPcvarFlagKills;
new gPcvarHelpUrl;
new gPcvarBadgePowers;
new gPcvarFlagRoundPoints;
new gPcvarFlagMatchPoints;
new gPcvarXpMinPlayers;
new gPcvarHudOptions;
new gPcvarStatusText;
new gPcvarFFA;
new gPcvarSaveType;
new gPcvarRankBots;
new gPcvarBotQuota;
new gPcvarSVLan;

//Current players info
new g_PlayerRank[33];
new g_PlayerBadges[33][MAX_BADGES];
new knifekills[33];
new pistolkills[33];
new sniperkills[33];
new parakills[33];
new defuses[33];
new plants[33];
new explosions[33];
new accuracy[33];
new totalkills[33];
new gSaveKey[33][32];
new smgkills[33];
new shotgunkills[33];
new riflekills[33];
new grenadekills[33];

new bronze[33];
new silver[33];
new gold[33];

//Temp storage variables
new numofbadges[33];
new bool:newplayer[33];
new g_lastwpn[33];
new bool:g_imobile[33];
new bool:freezetime;
new highestrank;
new highestrankid;
new gStatsLoaded[33];
new gCurrentFOV[33];

new g_friend[33];
new bool:g_invis[33];

new menuselection[33];

//Server stats
new highestrankserver;
new highestrankservername[32];

new mostkills;
new mostkillsid;
new mostkillsname[32];

new mostwins;
new mostwinsname[32];


new menuselected[33][3];
//0 - Badge/Kills selected 0/1
//1 - Badgenum/Kills
//2 - Badgelevel

//Sound Vars
new gSoundRank[] = "bf2rank/bf2rank_promotion.wav"; //Rank gained sound
new gSoundBadge[] = "bf2rank/bf2rank_award.wav"; //Badges earned sound

//Sprite vars
new gSprite[21];

#if defined SQL
	//SQl vars
	#include <sqlx>
	new Handle:g_SqlTuple;
	new g_Cache[512];
	new bool:SQLenabled;
	new bool:gIntermission;
#else
	//nVault
	#include <nvault>
	new g_Vault;
	new gPcvarPruneDays;
#endif

new gPlayerName;

//Bf2 includes
#include "bf2/const.inl"
#include "bf2/effect.inl"
#include "bf2/cmds.inl"
#include "bf2/events.inl"
#include "bf2/save.inl"
#include "bf2/forwards.inl"
#include "bf2/check.inl"
#include "bf2/badgepowers.inl"
#include "bf2/menu.inl"
#include "bf2/hud.inl"
#include "bf2/othermods.inl"
#include "bf2/csx.inl"
#include "bf2/ham.inl"
#if defined SQL
#include "bf2/sql.inl"
#endif

public plugin_init()
{
	register_plugin(gPluginName, gPluginVersion, "pRED*");

	//Register all the say commands

	//Public
	register_clcmd("say /ranks","show_rankhelp",0, "Shows The Rank Help");
	register_clcmd("say_team /ranks","show_rankhelp",0, "Shows The Rank Help");

	register_clcmd("say /badges1","show_badgehelp",0, "Shows The Badge Help");
	register_clcmd("say_team /badges1","show_badgehelp",0, "Shows The Badge Help");

	register_clcmd("say /badges2","show_badgehelp2",0, "Shows The Badge Help 2");
	register_clcmd("say_team /badges2","show_badgehelp2",0, "Shows The Badge Help 2");

	register_clcmd("say /badges3","show_badgehelp3",0, "Shows The Badge Help 3");
	register_clcmd("say_team /badges3","show_badgehelp3",0, "Shows The Badge Help 3");

	register_clcmd("say", "cmd_say", 0, "<target> ");
	register_clcmd("say_team", "cmd_say", 0, "<target> ");

	register_clcmd("say /who", "cmd_who", 0, "Display a list of player and their levels");
	register_clcmd("say_team /who", "cmd_who", 0, "Display a list of player and their levels");

	register_clcmd("say /help", "cmd_help", 0, "Displays the Help");
	register_clcmd("say_team /help", "cmd_help", 0, "Displays the Help");

	register_clcmd("say /bf2menu", "Bf2menu", 0, "Displays the Menu");
	register_clcmd("say_team /bf2menu", "Bf2menu", 0, "Displays the Menu");
	register_clcmd("say bf2menu", "Bf2menu", 0, "Displays the Menu");
	register_clcmd("say_team bf2menu", "Bf2menu", 0, "Displays the Menu");
	register_clcmd("say /bf2", "Bf2menu", 0, "Displays the Menu");
	register_clcmd("say_team /bf2", "Bf2menu", 0, "Displays the Menu");
	register_clcmd("say bf2", "Bf2menu", 0, "Displays the Menu");
	register_clcmd("say_team bf2", "Bf2menu", 0, "Displays the Menu");
	register_clcmd("say /menu", "Bf2menu", 0, "Displays the Menu");
	register_clcmd("say_team /menu", "Bf2menu", 0, "Displays the Menu");
	register_clcmd("say menu", "Bf2menu", 0, "Displays the Menu");
	register_clcmd("say_team menu", "Bf2menu", 0, "Displays the Menu");
	register_clcmd("say /help", "Bf2menu", 0, "Displays the Menu");
	register_clcmd("say_team /help", "Bf2menu", 0, "Displays the Menu");
	register_clcmd("say help", "Bf2menu", 0, "Displays the Menu");
	register_clcmd("say_team help", "Bf2menu", 0, "Displays the Menu");

	register_clcmd("say /bf2helpmenu", "helpmenu", 0, "Displays the Help Menu");
	register_clcmd("say_team /bf2helpmenu", "helpmenu", 0, "Displays the Help Menu");

	register_clcmd("say /bf2statsmenu", "helpmenu", 0, "Displays the Stats Menu");
	register_clcmd("say_team /bf2statsmenu", "helpmenu", 0, "Displays the Stats Menu");

	register_clcmd("say /bf2adminmenu", "adminmenu", 0, "Displays the Admin Menu");
	register_clcmd("say_team /bf2adminmenu", "adminmenu", 0, "Displays the Admin Menu");

	register_clcmd("say /bf2stats", "show_stats", 0, "Shows your current weapon stats");
	register_clcmd("say_team /bf2stats", "show_stats", 0, "Shows your current weapon stats");

	register_clcmd("say /serverstats", "show_server_stats", 0, "Shows your current weapon stats");
	register_clcmd("say_team /serverstats", "show_server_stats", 0, "Shows your current weapon stats");

	register_clcmd("say /bf2save", "save_badges", 0, "Shows your current weapon stats");
	register_clcmd("say_team /bf2save", "save_badges", 0, "Shows your current weapon stats");

	register_clcmd("bf2_resetstats", "reset_stats", 0, "Resets all of your stats");

	//Admin
	register_clcmd("bf2_addbadge", "add_badge", ADMIN_LEVEL, "<player> <badge#> <level#>");
	register_clcmd("bf2_addkills", "add_kills", ADMIN_LEVEL, "<player> <kills#>");
	register_clcmd("bf2_resetserverstats", "reset_all_stats", ADMIN_RESET, "Erases all players stats");


	//Cvars

	//FCVAR_SERVER cvar for game monitor.
	register_cvar("bf2_version", gPluginVersion, FCVAR_SERVER);

	// Set cvar to update version in case new version loaded while server still running
	set_cvar_string("bf2_version", gPluginVersion);

	gPcvarBF2Active = register_cvar("bf2_active", "1");
	gPcvarBadgesActive = register_cvar("bf2_badges", "1");
	gPcvarFreeAwp = register_cvar("bf2_awp", "0");
	gPcvarXpMultiplier = register_cvar("bf2_xpmultiplier", "0.1");
	gPcvarXpMinPlayers = register_cvar("bf2_xpminplayers", "2");
	gPcvarIconTime = register_cvar("bf2_icon_time", "1.5");
	gPcvarHelpUrl = register_cvar("bf2_help_url", "");
	gPcvarBadgePowers = register_cvar("bf2_badgepowers", "0");
	gPcvarHudOptions = register_cvar("bf2_hud_options", "abcde");
	gPcvarStatusText = register_cvar("bf2_statustext", "1");
#if !defined SQL
	gPcvarPruneDays = register_cvar("bf2_reset_days", "99999");
#endif
	gPcvarFFA = register_cvar("bf2_ffa", "0");
	gPcvarFlagKills = register_cvar("bf2_flag_kills", "2");
	gPcvarFlagRoundPoints = register_cvar("bf2_flag_round_kills", "0");
	gPcvarFlagMatchPoints = register_cvar("bf2_flag_match_kills", "0");

	gPcvarSaveType = get_cvar_pointer("csstats_rank");
	gPcvarRankBots = get_cvar_pointer("csstats_rankbots");
	gPcvarBotQuota = get_cvar_pointer("bot_quota");
	gPcvarSVLan = get_cvar_pointer("sv_lan");

	//Message sending.
	gmsgStatusText = get_user_msgid("StatusText");
	gmsgScreenFade = get_user_msgid("ScreenFade");
	gmsgScreenShake = get_user_msgid("ScreenShake");
	gmsgSayText = get_user_msgid("SayText");

	//Register events, logs and forwards to be captured
	register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0"); //add freeztime start code
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");
	register_event("SetFOV", "Event_SetFOV", "be");
	register_event("DeathMsg", "Event_DeathMsg", "a");

	register_logevent("LogEvent_Round_Start", 2, "0=World triggered", "1=Round_Start"); //freezetime end code
	register_logevent("LogEvent_Round_End", 2, "1=Round_End");

	register_message(SVC_INTERMISSION, "Message_Intermission");
	register_message(get_user_msgid("StatusValue"), "Message_StatusValue");

	register_event("StatusValue", "setTeam", "be", "1=1");
	register_event("StatusValue", "on_ShowStatus", "be", "1=2", "2!0");
	register_event("StatusValue", "on_HideStatus", "be", "1=1", "2=0");

	// Must use post or else is_user_alive will return false when dead player respawns
	RegisterHam(Ham_Spawn, "player", "Ham_Spawn_Post", 1);	// cz bots won't hook here must RegisterHamFromEntity
	RegisterHam(Ham_TakeDamage, "player", "Ham_TakeDamage_Pre");

	gHudSyncAimInfo = CreateHudSyncObj();
	gMaxPlayers = get_maxplayers();
	gPlayerName = get_xvar_id("PlayerName");
}


public zp_user_infected_post( victim, killer, nemesis){
	if ( !killer) return;
	if ( !get_pcvar_num(gPcvarBF2Active) ) return;

	if ( killer == victim )
	{
		check_badges(victim);
		return;
	}

	//if ( is_user_bot(victim) && !get_pcvar_num(gPcvarRankBots) ) return;

	if ( killer < 1 || killer > gMaxPlayers ) return;

	knifekills[killer]++;
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