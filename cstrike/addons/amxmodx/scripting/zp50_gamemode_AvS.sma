/*================================================================================
	
	----------------------------------
	-*- [ZP] Game Mode: Armageddon -*-
	----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <amx_settings_api>
#include <cs_teams_api>
#include <zp50_gamemodes>
#include <zp50_class_assassin>
#include <zp50_class_sniper>
#include <zp50_deathmatch>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_armageddon[][] = { "zombie_plague/nemesis1.wav" , "zombie_plague/survivor1.wav" }

#define SOUND_MAX_LENGTH 64

new Array:g_sound_armageddon

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 150
#define HUD_EVENT_G 50
#define HUD_EVENT_B 200

new g_MaxPlayers
new g_HudSync

new cvar_avsm_chance, cvar_avsm_min_players
new cvar_avsm_ratio
new cvar_avsm_assassin_hp_multi, cvar_avsm_sniper_hp_multi
new cvar_avsm_show_hud, cvar_avsm_sounds
new cvar_avsm_allow_respawn

public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: Assassins VS Snipers Mode", ZP_VERSION_STRING, "ZP Dev Team")
	zp_gamemodes_register("Assassins VS Snipers Mode")
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_avsm_chance = register_cvar("zp_avsm_chance", "20")
	cvar_avsm_min_players = register_cvar("zp_avsm_min_players", "0")
	cvar_avsm_ratio = register_cvar("zp_avsm_ratio", "0.5")
	cvar_avsm_assassin_hp_multi = register_cvar("zp_avsm_assassin_hp_multi", "0.25")
	cvar_avsm_sniper_hp_multi = register_cvar("zp_avsm_sniper_hp_multi", "0.25")
	cvar_avsm_show_hud = register_cvar("zp_avsm_show_hud", "1")
	cvar_avsm_sounds = register_cvar("zp_avsm_sounds", "1")
	cvar_avsm_allow_respawn = register_cvar("zp_avsm_allow_respawn", "0")
	
	// Initialize arrays
	g_sound_armageddon = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND Assassin VS Snipers", g_sound_armageddon)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_armageddon) == 0)
	{
		for (index = 0; index < sizeof sound_armageddon; index++)
			ArrayPushString(g_sound_armageddon, sound_armageddon[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND Assassin VS Sniper", g_sound_armageddon)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_armageddon); index++)
	{
		ArrayGetString(g_sound_armageddon, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
}

// Deathmatch module's player respawn forward
public zp_fw_deathmatch_respawn_pre(id)
{
	// Respawning allowed?
	if (!get_pcvar_num(cvar_avsm_allow_respawn))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_avsm_chance)) != 1)
			return PLUGIN_HANDLED;
		
		// Min players
		if (GetAliveCount() < get_pcvar_num(cvar_avsm_min_players))
			return PLUGIN_HANDLED;
	}
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_start()
{
	// Calculate player counts
	new id, alive_count = GetAliveCount()
	new sniper_count = floatround(alive_count * get_pcvar_float(cvar_avsm_ratio), floatround_ceil)
	new assassin_count = alive_count - sniper_count
	
	// Turn specified amount of players into Snipers
	new iSnipers, iMaxSnipers = sniper_count
	while (iSnipers < iMaxSnipers)
	{
		// Choose random guy
		id = GetRandomAlive(random_num(1, alive_count))
		
		// Already a sniper?
		if (zp_class_sniper_get(id))
			continue;
		
		// If not, turn him into one
		zp_class_sniper_set(id)
		iSnipers++
		
		// Apply sniper health multiplier
		set_user_health(id, floatround(get_user_health(id) * get_pcvar_float(cvar_avsm_sniper_hp_multi)))
	}
	
	// Turn specified amount of players into Assassins
	new iAssassins, iMaxAssassins = assassin_count
	while (iAssassins < iMaxAssassins)
	{
		// Choose random guy
		id = GetRandomAlive(random_num(1, alive_count))
		
		// Already a sniper or assassin?
		if (zp_class_sniper_get(id) || zp_class_assassin_get(id))
			continue;
		
		// If not, turn him into one
		zp_class_assassin_set(id)
		iAssassins++
		
		// Apply assassin health multiplier
		set_user_health(id, floatround(get_user_health(id) * get_pcvar_float(cvar_avsm_assassin_hp_multi)))
	}
	
	// Play AvS sound
	if (get_pcvar_num(cvar_avsm_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_armageddon, random_num(0, ArraySize(g_sound_armageddon) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
	
	if (get_pcvar_num(cvar_avsm_show_hud))
	{
		// Show AvS HUD notice
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "Assassins VS Snipers Mode", LANG_PLAYER, "NOTICE_Assassins VS Snipers")
	}
}

// Plays a sound on clients
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}

// Get Alive Count -returns alive players number-
GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}

// Get Random Alive -returns index of alive player number target_index -
GetRandomAlive(target_index)
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
		
		if (iAlive == target_index)
			return id;
	}
	
	return -1;
}