#include <amxmodx>
#include <zombieplague>
#include <hamsandwich>

public plugin_init() {
    register_plugin("ZP: Show Victim HP On Damage", "1.0", "<VeCo>")
    register_event("Damage","event_damage","b","2!0","3=0","4!0")
}

public event_damage(id)
{
	if(is_user_connected(id)&&is_user_alive(id))
		return HAM_IGNORED;
		
	if(!is_user_connected(get_user_attacker(id))&&!is_user_alive(get_user_attacker(id)))
		return HAM_IGNORED;
		
	set_hudmessage(155, 0, 0, -1.0, -1.0, 1, 0.0, 0.0)
	show_hudmessage(get_user_attacker(id), "X")
	
	return HAM_IGNORED;
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
