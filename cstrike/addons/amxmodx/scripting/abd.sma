/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>

#define PLUGIN "Advanced Bullet Damage"
#define VERSION "1.0"
#define AUTHOR "Sn!ff3r"

new g_hudmsg1

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("Damage", "on_damage", "b", "2!0", "3=0", "4!0")	
	
	g_hudmsg1 = CreateHudSyncObj()	
}
public on_damage(id)
{	
	static attacker; attacker = get_user_attacker(id)
	static damage; damage = read_data(2)
	if(is_user_connected(attacker))
	{
		set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
		ShowSyncHudMsg(attacker, g_hudmsg1, "%i^n", damage)
	}
}
