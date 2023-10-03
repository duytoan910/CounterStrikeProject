
#include <amxmodx>
#include <fakemeta>
#include <zombieplague>

#define PLUGIN "[ZP] Extra Item : Leap"
#define VERSION "1.5.7"
#define AUTHOR "Fry!"

/*================================================================================
 [Plugin Customization]
=================================================================================*/

new bool:g_hasLongJump[33]
new Float:g_last_LongJump_time[33]
new g_itemid_long

#define NAME "Long Jump"
#define COST 3500

#define LJ_FORCE 600
#define LJ_HEIGHT 320.0
#define LJ_COOLDOWN 3

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	g_itemid_long = zp_register_extra_item(NAME, COST, ZP_TEAM_ZOMBIE)
}

// Reset on disconnection
public client_disconnect(id)
{
	g_hasLongJump[id] = false
}

// Reset if turned into human
public zp_user_humanized_post(id)
{
	g_hasLongJump[id] = false
}

// Reset at round start (for everyone)
public event_round_start()
{
	for (new i = 1; i <= 32; i++)
		g_hasLongJump[i] = false
}

// Buy throught extra items menu
public zp_extra_item_selected(player, itemid)
{
	if (itemid == g_itemid_long)
	{
		if(g_hasLongJump[player])
		{
			zp_set_user_ammo_packs(player, zp_get_user_ammo_packs(player) + COST)
			client_print(player, print_chat,"[ZP] You already have Jump Pack.")
		}else{
			g_hasLongJump[player] = true
			client_print(player, print_chat,"[ZP] You have bought a Jump Pack. To use it, press duck and jump while moving forward.")
		}
		
	}
}    	
public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED
	if (allow_LongJump(id)&&zp_get_user_zombie(id)&&!zp_get_user_first_zombie(id))
	{
		static Float:velocity[3]
		velocity_by_aim(id, LJ_FORCE, velocity)
		
		velocity[2] = LJ_HEIGHT
		
		set_pev(id, pev_velocity, velocity)
		
		g_last_LongJump_time[id] = get_gametime()
	}
	
	return FMRES_IGNORED
}

// Check if the player can longjump
allow_LongJump(id)
{
	if (!g_hasLongJump[id])
		return false
	
	if (!(pev(id, pev_flags) & FL_ONGROUND) || fm_get_speed(id) < 60)
		return false
	
	static buttons
	buttons = pev(id, pev_button)
	
	if (!is_user_bot(id) && (!(buttons & IN_JUMP) || !(buttons & IN_DUCK)))
		return false
		
	if (is_user_bot(id) && !(buttons & IN_FORWARD))
		return false
	
	if (get_gametime() - g_last_LongJump_time[id] < LJ_COOLDOWN)
		return false
	
	return true
}

// Get entity's speed (from fakemeta_util)
stock fm_get_speed(entity)
{
	static Float:velocity[3]
	pev(entity, pev_velocity, velocity)
	
	return floatround(vector_length(velocity))
}
