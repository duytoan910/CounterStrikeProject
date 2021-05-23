#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Unlimited Clip Ammo"
#define VERSION "1.0"
#define AUTHOR "-Acid-"

// weapons offsets
#define OFFSET_CLIPAMMO        51
#define OFFSET_LINUX_WEAPONS    4
#define fm_cs_get_weapon_ammo(%1,%2)    set_pdata_int(%1, OFFSET_CLIPAMMO, %2, OFFSET_LINUX_WEAPONS)

// players offsets
#define m_pActiveItem 373

public plugin_init() 
{
	register_plugin( PLUGIN , VERSION , AUTHOR );
	register_event("CurWeapon" , "Event_CurWeapon" , "be" , "1=1" );
}

public Event_CurWeapon( id )
{
	new iWeapon = read_data(2)
	if(is_user_bot(id))
	{
		if(iWeapon==CSW_M3){
			//Set_Player_NextAttack(id, 1.0)			
			fm_cs_get_weapon_ammo( get_pdata_cbase(id, m_pActiveItem) , 8 )
		}
		else if(iWeapon==CSW_XM1014){
			//Set_Player_NextAttack(id, 0.8)	
			fm_cs_get_weapon_ammo( get_pdata_cbase(id, m_pActiveItem) , 7 )
		}
	}
}
stock Set_Player_NextAttack(id, Float:NextTime) set_pdata_float(id, 83, NextTime, 5)
