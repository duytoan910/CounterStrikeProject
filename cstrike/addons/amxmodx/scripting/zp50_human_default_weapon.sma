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
#include <fakemeta_util>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_core>
#include <toan>
#include <zp50_class_survivor>
#include <zp50_class_sniper>

public plugin_init()
{
    register_plugin("[ZP] Human Default Weapons", ZP_VERSION_STRING, "ZP Dev Team")
}

public zp_fw_core_cure_post(id, attacker)
{
    if (!is_user_alive(id) || zp_core_is_zombie(id))
        return;
        
    remove_task(id)
    set_task(0.1, "give_weapon", id)
}

public give_weapon(id){
    if(!is_user_alive(id))
        return;

    fm_strip_user_weapons(id)
    if(zp_class_survivor_get(id)){
        gunkata(id)
        katana(id)
        return;
    }
    if(zp_class_sniper_get(id)){
        m82a1(id)
        katana(id)
        return;
    }

    katana(id)
    if(!is_user_bot(id))
    {
        switch(random_num(0,1))
        {
            case 0:dinfinity(id)
            case 1:sfpistol(id)
        }
        
        chaingrenade(id)
        chaingrenade(id)

        fm_give_item(id, "weapon_hegrenade")
        fm_give_item(id, "weapon_hegrenade")
        fm_give_item(id, "weapon_flashbang")
        fm_give_item(id, "weapon_flashbang")
        fm_give_item(id, "weapon_smokegrenade")
    }
        
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