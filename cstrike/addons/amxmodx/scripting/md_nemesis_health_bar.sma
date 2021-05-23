#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <metadrawer>

#define PLUGIN "[ZBHeroEx] Addon: Infect Effect"
#define VERSION "1.0"
#define AUTHOR "Dias"

new boss
new Float:maxhp;
new g_gamemode

new const bosshp_bg_left[][] = {
	"gfx/tga_image/bosshp_bg_left_nemesis.tga",
	"gfx/tga_image/bosshp_bg_left.tga",
	"gfx/tga_image/bosshp_bg_left_dione.tga",
	"gfx/tga_image/bosshp_bg_left_fallentitan.tga",
	"gfx/tga_image/bosshp_bg_left_oberon.tga",
	"gfx/tga_image/bosshp_bg_left_revenant.tga"
}
new const bosshp_bg_center[] = "gfx/tga_image/bosshp_bg_center.tga"
new const bosshp_bg_right[] = "gfx/tga_image/bosshp_bg_right.tga"
new const bigbg20[] = "gfx/tga_image/bigbg20.tga"

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_event("Health", "Event_Health", "be")
	
	//register_clcmd("say /h", "draw_health_bar")
	
	for(new i=0; i<sizeof(bosshp_bg_left); i++)
		md_loadimage(bosshp_bg_left[i])
	md_loadimage(bosshp_bg_right)
	md_loadimage(bosshp_bg_center)
	md_loadimage(bigbg20)
}
public plugin_natives()
{
	register_native("set_hb_maxhp","set_maxhp",1)
}
public set_maxhp(Float:value, g_Boss_Ent)
{	
	maxhp = value
	
	new BossType[16]
	pev(g_Boss_Ent, pev_classname, BossType, charsmax(BossType))
	if(equal(BossType, "NPC_PHOBOS"))
	{
		boss = 1
	}else if(equal(BossType, "NPC_DIONE"))
	{
		boss = 2 
	}else if(equal(BossType, "NPC_FALLENTITAN"))
	{
		boss = 3 
	}else if(equal(BossType, "NPC_OBERON"))
	{
		boss = 4 
	}else if(equal(BossType, "NPC_REVENANT"))
	{
		boss = 5
	}else boss = 0 	
	
	draw_health_bar(0, 100.0)
	percent_count(0)
}
public Event_Health(id)
{
	percent_count(id)
}

public zp_round_started(gamemode)
{
	g_gamemode = gamemode
	/*
	if(gamemode == MODE_NPC)
		return;
		
	for(new i=0; i<get_maxplayers();i++)
	{
		if(!zp_get_user_nemesis(i))
			continue;
		
		set_task(0.1, "set_maxhp_player",i)
	}*/
}

public zp_user_infected_post(id, infector, nemesis)
{
	if(g_gamemode == MODE_NPC)
		return;
	if(!nemesis)
		return
		
	set_task(0.1, "set_maxhp_player",id)
}

public set_maxhp_player(id)
{
	maxhp = float(get_user_health(id))
	draw_health_bar(0, 100.0)
	percent_count(0)
}
public percent_count(id)
{
	if(!zp_get_user_nemesis(id))
		return;

	static Float:HPPercent
	HPPercent = (get_user_health(id)*100) / maxhp;
	draw_health_bar(0, HPPercent)
}
public draw_health_bar(id, Float:Percent)
{
	if(is_user_bot(id))
		return
		
	static Float:BarPercent;
	BarPercent = Percent*8.05
	if(Percent<0.1)BarPercent = 1.0
	
	md_drawimage(id, 21, 0, bosshp_bg_left[boss], 0.2, 0.1, 0, 0, 255, 255, 255, 255, 0.0, 0.0, 10.0, ALIGN_NORMAL)	
	md_drawimage(id, 22, 0, bosshp_bg_center, 0.305, 0.1, 0, 0, 255, 255, 255, 255, 0.0, 0.0, 10.0, ALIGN_NORMAL, 675)
	md_drawimage(id, 23, 0, bosshp_bg_right, 0.833, 0.1, 0, 0, 255, 255, 255, 255, 0.0, 0.0, 10.0, ALIGN_NORMAL)
	md_drawimage(id, 24, 0, bigbg20, 0.208, 0.212, 0, 0, 255, Percent<25?0:255, Percent<25?0:255, 255, 0.0, 0.0, 10.0, ALIGN_NORMAL, floatround(BarPercent))
}
public Event_NewRound()
{	 
	set_task(0.1,"Remove_BG",0)
	maxhp = 0.0
	//boss = 0
}
public Remove_BG(id)
{
	md_removedrawing(id, 1, 21)
	md_removedrawing(id, 1, 22)	
	md_removedrawing(id, 1, 23)	
	md_removedrawing(id, 1, 24)	
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
