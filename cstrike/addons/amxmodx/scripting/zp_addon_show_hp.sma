#include <amxmodx>
#include <zombieplague>

public plugin_init() {
    register_plugin("ZP: Show Victim HP On Damage", "1.0", "<VeCo>")
    register_event("Damage","event_damage","b","2!0","3=0","4!0")
}

public event_damage(id)
{
    new killer = get_user_attacker(id)

    if(zp_get_user_zombie(id) && get_user_health(id) > 0)
    {
    	client_print(killer,print_center,"Máu: %i",get_user_health(id))
    }
    else
    client_print(killer,print_center,"Máu: 0")
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
