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
#include <toan>
#include <zp50_class_survivor>

public plugin_init()
{
    register_plugin("[ZP] Human Default Weapons", ZP_VERSION_STRING, "ZP Dev Team")
}

public zp_fw_core_cure_post(id, attacker)
{
    if (!is_user_alive(id) || zp_core_is_zombie(id) || zp_class_survivor_get(id))
        return;
        
    remove_task(id)
    set_task(0.1, "give_weapon", id)
}

public give_weapon(id){
    if(!is_user_bot(id))
        dinfinity(id)

    skullaxe(id)
    chaingrenade(id)
    chaingrenade(id)
        
    // Give the new weapon and full ammo
    switch(random_num(0,5))
    {
        case 0:hk416(id)
        case 1..5:at15hw(id)
    }

    // if(is_user_bot(id)){
    //     engclient_cmd(id,"weapon_smokegrenade")
    //     ExecuteHam(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, 373, 5));
    // }
}