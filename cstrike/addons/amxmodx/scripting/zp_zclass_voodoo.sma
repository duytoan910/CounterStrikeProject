/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <zombieplague>
#include <fakemeta>
#include <hamsandwich> 

#define PLUGIN "[CSO LIKE] Voodoo zombie"
#define VERSION "0.1"
#define AUTHOR "Barney"

enum (+= 100)
{
	TASK_WAIT = 2000,
	TASK_ATTACK,
	TASK_BOT_USE_SKILL,
	TASK_USE_SKILL
}
// IDs inside tasks
#define ID_WAIT (taskid - TASK_WAIT)
#define ID_ATTACK (taskid - TASK_ATTACK)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)
#define ID_USE_SKILL (taskid - TASK_USE_SKILL)

native Float:entity_range(ida,idb);

new vzombi, spriteid
new cvar_debug

new const skillsound[] = "zombie_plague/zombi_heal.wav";
new const spriteheal[] = "sprites/zb_restore_health.spr";
new g_sound[][] = 
{
	"zombie_plague/zombi_death_1.wav" ,
	"zombie_plague/zombi_death_2.wav" ,
	"zombie_plague/zombi_hurt_01.wav" ,
	"zombie_plague/zombi_hurt_02.wav"
};

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	vzombi = zp_register_zombie_class("Voodoo", "", "heal_zombi_host", "v_knife_heal_zombi.mdl", 3100, 290, 0.8, 1.45);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	register_event("DeathMsg", "Death", "a");
	register_logevent("roundStart", 2, "1=Round_Start")
	register_clcmd("drop", "cmd_makeskill");
	cvar_debug = register_cvar("zp_bot_skill_debug", "0")
}

public plugin_precache() {
	spriteid = precache_model(spriteheal);
	precache_sound(skillsound);
	for(new i = 0; i < sizeof g_sound; i++)
		precache_sound(g_sound[i]);
}
new g_bot
public client_putinserver(id)
{
	if(is_user_bot(id) && !g_bot)
	{
		g_bot = 1
		set_task(0.1, "Do_RegisterHamBot", id)
	}
}
public Do_RegisterHamBot(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
}
public Death(id)
{
	new id = read_data(2)
	reset_value_player(id)

	if(zp_get_user_zombie(id) && zp_get_user_zombie_class(id)==vzombi && !zp_get_user_nemesis(id))
	{
		engfunc( EngFunc_EmitSound, id, CHAN_ITEM, g_sound[random_num(0,1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}
public fw_TakeDamage(id, iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamage)
{
	if (zp_get_user_zombie_class(id)==vzombi && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
		emit_sound(id, CHAN_WEAPON, g_sound[random_num(2,3)], 0.7, ATTN_NORM, 0, PITCH_LOW)
	}
}
public client_connect(id)
{
	reset_value_player(id)
}
public client_disconnect(id)
{
	reset_value_player(id)
}
reset_value_player(id)
{
	if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
}
public roundStart(id)
{
	for (new id=1; id<33; id++)
	{
		if (!is_user_connected(id)) continue;
		if (is_user_bot(id))
		{
			if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
			set_task(float(20), "bot_use_skill", id+TASK_BOT_USE_SKILL)
		}
	}
}
public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_bot(id)) return;

	cmd_makeskill(id)
	if (task_exists(taskid)) remove_task(taskid)
	set_task(float(random_num(10,15)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}
public cmd_makeskill(id) {
		
	static Float:fLastUse[33]
	if(zp_get_user_zombie(id)&&!zp_get_user_nemesis(id)&& zp_get_user_zombie_class(id) == vzombi&& is_user_alive(id)&& fLastUse[id] + 8.0 < get_gametime()) 
	{
		if (is_user_bot(id)&&get_pcvar_num(cvar_debug))
			return;
			
		for(new i = 0; i < get_maxplayers(); i ++) 
		{
			if(is_user_alive(i)
			//&& i!=id
			&& zp_get_user_zombie(i)
			&& entity_range(id, i) < 200.0) 
			{
				cmd_heal(i);
				set_task(10.0,"asd",id)
			}
		}
		fLastUse[id] = get_gametime();
	}
}
public asd(id)
{
	if ((zp_get_user_zombie_class(id) == vzombi) && zp_get_user_zombie(id))
	{
		client_print(id, print_center,"Cool down finish! [G]")
	}
}
public cmd_heal(id) {
	set_pev(id, pev_health, float(pev(id,pev_health)+2000));
	md_zb_skill(id, 1)
	emit_sound(id, CHAN_VOICE, skillsound, 1.0, ATTN_NORM, 0, PITCH_NORM);
	new Float: fOrigin[3];
	pev( id, pev_origin, fOrigin );
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_short(spriteid);
	write_byte(10);
	write_byte(255);
	message_end();
}
