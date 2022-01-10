//Bf2 Rank Mod hamsandwich File
//Contains all the Ham Sandwich functions.

#if defined bf2_ham_included
  #endinput
#endif
#define bf2_ham_included

//Called on task from client_putinserver 
public RegisterHam_CZBot(id)
{
	// Thx to Avalanche and GunGame for which this method is based on.
	if ( gCZBotRegisterHam || !is_user_connected(id) ) return;

	// Make sure it's a bot and if quota greater than 0 it's a cz bot.
	if ( gPcvarBotQuota && get_pcvar_num(gPcvarBotQuota) > 0 && is_user_bot(id) ) {
		// Post-spawn fix for cz bots, since RegisterHam does not work for them.
		RegisterHamFromEntity(Ham_Spawn, id, "Ham_Spawn_Post", 1);
		RegisterHamFromEntity(Ham_TakeDamage, id, "Ham_TakeDamage_Pre");

		gCZBotRegisterHam = true;

		// Incase this CZ bot was spawned alive during a round, call the Ham_Spawn
		// because it would have happened before the RegisterHam.
		if ( is_user_alive(id) ) Ham_Spawn_Post(id);
	}
}

public Ham_Spawn_Post(id)
{
	if ( !get_pcvar_num(gPcvarBF2Active) ) return HAM_IGNORED;

	// Verify the client is not just put in server but is alive
	if ( !is_user_alive(id) ) return HAM_IGNORED;

	// Make sure this is not a bot creation before it spawns
	if ( cs_get_user_team(id) == CS_TEAM_UNASSIGNED ) return HAM_IGNORED;

	check_level(id);

	// Task is needed because sometimes when survived round StatusText gets cleared on spawn
	set_task(0.1, "DisplayHUD", id);

	if ( !get_pcvar_num(gPcvarBadgesActive) || !get_pcvar_num(gPcvarBadgePowers) ) return HAM_IGNORED;

	set_invis(id);

	set_task(0.5, "give_userweapon", id);
	set_task(0.6, "set_speed", id);

	return HAM_IGNORED;
}

public Ham_TakeDamage_Pre(victim, inflictor, attacker, Float:damage, damagebits)
{
	if ( !get_pcvar_num(gPcvarBadgesActive) || !get_pcvar_num(gPcvarBadgePowers) ) return HAM_IGNORED;
	if ( !is_user_connected(attacker) || !is_user_alive(victim) ) return HAM_IGNORED;
	if ( victim != attacker && cs_get_user_team(victim) == cs_get_user_team(attacker) && !get_pcvar_num(gPcvarFFA) ) return HAM_IGNORED;

	new expBadgeLevel = g_PlayerBadges[attacker][BADGE_EXPLOSIVES];
	new supBadgeLevel = g_PlayerBadges[attacker][BADGE_SUPPORT];
	
	if ( expBadgeLevel && (damagebits & DMG_GRENADE) ) //Explosives badge, nade dmg
	{
		//multiply .2 nade damage per level
		damage += damage * expBadgeLevel * 0.2;
	}
	else if ( supBadgeLevel && inflictor == attacker && get_user_weapon(attacker) == CSW_M249 ) //Support badge, bonus damg
	{
		//add to 2 m249 damage per level
		damage += supBadgeLevel * 2.0;
	}
	else
	{
		return HAM_IGNORED;
	}

	SetHamParamFloat(4, damage);

	return HAM_HANDLED;
}