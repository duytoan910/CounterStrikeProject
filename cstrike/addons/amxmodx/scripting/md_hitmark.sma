#include <amxmodx>
#include <amxmisc>
#include <metadrawer>
#include <fakemeta_util>

#define PLUGIN "Advanced Bullet Damage"
#define VERSION "1.0"
#define AUTHOR "Sn!ff3r"

//new const g_hitmark[] = "gfx/tga_image/buff_hit.png";
new const g_hitmark[] = "sprites/buff_shot.spr";

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("Damage", "on_damage", "b", "2!0", "3=0", "4!0")	
	
	//md_loadimage(g_hitmark);
	md_loadsprite(g_hitmark);
}
public on_damage(id)
{	
	static attacker; attacker = get_user_attacker(id)
	if(is_user_connected(attacker))
	{
		//client_print(attacker, print_chat,"Hit!")
		//md_drawimage(attacker, 100, 0, g_hitmark, 0.5, 0.5, 1, 1, 255, 255, 255, 255, 0.0, 0.0, 0.2, ALIGN_NORMAL)
		md_drawsprite(attacker, 100, 0, g_hitmark, 0.5, 0.5, 1, 1, 255, 255, 255, 255, 0.0, 0.0, 0.2, SPR_HOLES, ALIGN_NORMAL)
	}
}
