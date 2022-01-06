#include <amxmodx>
#include <fakemeta>
#include <xs>
#include <zombieplague>
#include <metadrawer>

#define PLUGIN "[ZBHeroEx] Addon: Infect Effect"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define EFFECT_BIK "gfx/tga_image/infection.bik"
#define EFFECT2_TGA "gfx/tga_image/infection2.tga"
#define SKILL_TGA "gfx/tga_image/zombie_skill.tga"
#define SKILL_DS_TGA "gfx/tga_image/retina_damagedouble.tga"
#define SKILL_HEAL_TGA "gfx/tga_image/zombie_skill_heal.tga"

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	md_loadbink(EFFECT_BIK)
	md_loadimage(EFFECT2_TGA)
	md_loadimage(SKILL_TGA)
	md_loadimage(SKILL_HEAL_TGA)
	md_loadimage(SKILL_DS_TGA)
}

public plugin_natives()
{
	register_native("md_zb_skill", "ShowScreen", 1)
}
public ShowScreen(id, type)
{
	if(!is_user_alive(id)||is_user_bot(id))
		return
	
	switch(type){
		case 0:{
			md_drawimage(id, 0, 0, SKILL_TGA, 0.5, 0.5, 1, 1, 255, 255, 255, 255, 0.1, 1.5, 0.1, ALIGN_NORMAL, md_getscreenwidth(), md_getscreenheight())
			
		}
		case 1:{
			md_drawimage(id, 0, 0, SKILL_HEAL_TGA, 0.5, 0.5, 1, 1, 255, 255, 255, 255, 0.1, 1.5, 0.1, ALIGN_NORMAL, md_getscreenwidth(), md_getscreenheight())
			
		}
		case 2:{
			md_drawimage(id, 0, 0, SKILL_DS_TGA, 0.5, 0.5, 1, 1, 255, 255, 255, 255, 0, 1.5, 0.1, ALIGN_NORMAL, md_getscreenwidth(), md_getscreenheight())
			
		}
	}
}
public zp_user_humanized_post(id)
{
	md_removedrawing(id, 3, 1)
	md_removedrawing(id, 1, 0)	
}
public zp_user_infected_post(id, infector)
{
	if(is_user_bot(id)) return
	if(infector)
		md_playbink(id, 1, EFFECT_BIK, 0.2, 0.3, 1, 1, 255, 255, 255, 255, 0, 0, ALIGN_NORMAL, md_getscreenwidth(), md_getscreenheight())
	md_drawimage(id, 0, 0, EFFECT2_TGA, 0.5, 0.5, 1, 1, 255, 255, 255, 255, 0.1, 1.0, 0.1, ALIGN_NORMAL, md_getscreenwidth(), md_getscreenheight())
}

