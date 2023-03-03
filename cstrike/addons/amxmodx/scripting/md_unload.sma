/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <hamsandwich>
#define PLUGIN "Unload Metadrawer Fix"
#define VERSION "1.0"
#define AUTHOR "Toan"
const UNIT_SECOND = (1<<12)
const FFADE_IN = 0x0000
new g_msgScreenFade
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)	
	g_msgScreenFade = get_user_msgid("ScreenFade");
	register_message(g_msgScreenFade, "message_screenfade")
}

public plugin_natives()
{
	register_native("md_zb_skill","do_fade", 1)
	register_native("nav_set_special_ammo","do_nothing", 1)
	register_native("nav_reset_money","do_nothing", 1)
}


public do_nothing(id){}
public do_fade(id){
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
	write_short(UNIT_SECOND) // duration
	write_short(3) // hold time
	write_short(FFADE_IN) // fade type
	write_byte(255) // r
	write_byte(100) // g
	write_byte(100) // b
	write_byte (255) // alpha
	message_end()
}