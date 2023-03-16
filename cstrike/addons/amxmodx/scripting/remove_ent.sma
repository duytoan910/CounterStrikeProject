
#include <amxmodx>
#include <engine>
#include <hamsandwich>

public plugin_init()
{
    register_plugin("Remove Ent", "1.0", "Toan")
    register_clcmd("ent_list", "remove_ent")
}

public remove_ent(id){
    
    client_print(id, print_console, "Checking!")
    new a;
    // Get distance between victim and epicenter
    while((a = find_ent_in_sphere(a, Float:{0,0,0}, 3000.0)) != 0)
    {
        if (id == a)
            continue;
         
        static szClassName[33];
        entity_get_string(a, EV_SZ_classname, szClassName, charsmax(szClassName))

        if(equal(szClassName, "player")
        ||equal(szClassName, "info_player_deathmatch")
        ||equal(szClassName, "info_player_start")
        ||strfind(szClassName, "env_", 0, 0) > -1
        ||strfind(szClassName, "func_", 0, 0) > -1
        ||strfind(szClassName, "weapon_", 0, 0) > -1
        ){
            continue
        }

        client_print(id, print_console, "Classname: %s", szClassName)
    }
}