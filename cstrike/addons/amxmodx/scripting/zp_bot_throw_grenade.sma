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

public plugin_init()
{
    register_plugin("[ZP] Human Default Weapons", ZP_VERSION_STRING, "ZP Dev Team")
    
    register_forward(FM_PlayerPreThink, "fm_pthink")
}

public zp_fw_gamemodes_start(game_mode_id){
    modeStarted = true
}

public zp_fw_gamemodes_end(game_mode_id){
    modeStarted = false
}

public fm_pthink(id){
    if(!pev_valid(id) || !is_user_alive(id) || !is_user_bot(id) || !modeStarted)
        return

    static throwChance; throwChance = random_num(0, 10)

 
    if(throwChance!=2)
        return;

    switch (random_num(1,3)){
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
                    client_cmd(id,"weapon_hegrenade")
                    if(get_user_weapon(id) == CSW_HEGRENADE)
                        ExecuteHam(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, 373, 5));
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
                    client_cmd(id,"weapon_flashbang")
                    if(get_user_weapon(id) == CSW_FLASHBANG)
                        ExecuteHam(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, 373, 5));
                    ExecuteHam(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, 373, 5));
                }
            }
        }
        case 3:{
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
                    client_cmd(id,"weapon_smokegrenade")
                    if(get_user_weapon(id) == CSW_SMOKEGRENADE)
                        ExecuteHam(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, 373, 5));
                    ExecuteHam(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, 373, 5));
                }
            }
        }
    }

    set_pev(id, pev_nextthink, 1.0)
}