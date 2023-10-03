/*================================================================================
	
	------------------------
	-*- [ZP] Human Armor -*-
	------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_core>
#include <zp50_gamemodes>
#include <toan>

new modeStarted;
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_init()
{
	register_plugin("[ZP] Human Default Weapons", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_forward(FM_CmdStart, "CmdStartFwd");

	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
	if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_PostFrame, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
}

public zp_fw_gamemodes_start(game_mode_id){
	modeStarted = true
}

public zp_fw_gamemodes_end(game_mode_id){
	modeStarted = false
}

public CmdStartFwd(id, handle)
{
	//check if user is alive
	if(!is_user_alive(id))
		return;
	
	//user was not zombie, survivor, nemesis, human player
	if(zp_get_user_zombie(id) 
	|| zp_get_user_nemesis(id) 
	|| zp_get_user_survivor(id) 
	|| zp_get_user_assassin(id) 
	|| zp_get_user_sniper(id) 
	|| !is_user_bot(id))
		return;
	
	//set bots flashlight
	if (!(get_uc(handle, UC_Impulse) & 100))
	{
		set_uc(handle, UC_Impulse, 100);
	}
}
public fw_Item_Deploy_Post(ent){
	
	static id
	id = fm_cs_get_weapon_ent_owner(ent)

	if(!pev_valid(id) || !is_user_alive(id) || !is_user_bot(id) || !modeStarted)
		return

	static throwChance; throwChance = random_num(0, zp_core_is_zombie(id)?5:20)
 
	if(throwChance!=2)
		return;

	new throwWhatChange = random_num(1,5)

	new gameModeName[32]
	zp_gamemodes_get_name(zp_gamemodes_get_current(), gameModeName, charsmax(gameModeName))
	if(equal(gameModeName, "Titan boss"))
		throwWhatChange = random_num(1,2)

	switch (throwWhatChange){
		case 1:{
			if(user_has_weapon(id, CSW_HEGRENADE)){
				new enemy, body
				get_user_aiming(id, enemy, body)
				if ((1 <= enemy <= 32))
				{
					if(!zp_core_is_zombie(id) && !zp_core_is_zombie(enemy))
						return
					if(zp_core_is_zombie(id) && zp_core_is_zombie(enemy))
						return

					engclient_cmd(id,"weapon_hegrenade")
					ExecuteHam(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, 373, 5));
				}
			}
		}
		case 2:{
			if(user_has_weapon(id, CSW_FLASHBANG)){
				new enemy, body
				get_user_aiming(id, enemy, body)
				if ((1 <= enemy <= 32))
				{
					if(!zp_core_is_zombie(id) && !zp_core_is_zombie(enemy))
						return
					if(zp_core_is_zombie(id) && zp_core_is_zombie(enemy))
						return

					engclient_cmd(id,"weapon_flashbang")
					ExecuteHam(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, 373, 5));
				}
			}
		}
		case 3..5:{
			if(user_has_weapon(id, CSW_SMOKEGRENADE)){
				new enemy, body
				get_user_aiming(id, enemy, body)
				if ((1 <= enemy <= 32))
				{
					if(!zp_core_is_zombie(id) && !zp_core_is_zombie(enemy))
						return
					if(zp_core_is_zombie(id) && zp_core_is_zombie(enemy))
						return

					engclient_cmd(id,"weapon_smokegrenade")
					ExecuteHam(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, 373, 5));
				}
			}
		}
	}
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, 41, 4)
}
