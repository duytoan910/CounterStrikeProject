#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>

#define PICKUP_RANGE 200.0

new bool:g_allowpickup

public plugin_init() 
{
	register_plugin("Bot auto pickup gun","1.0","Toan")
	RegisterHam(Ham_Item_PostFrame, "weapon_knife", "PickItUp", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_usp", "PickItUp", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_hegrenade", "PickItUp", 1)
}
public zp_round_started()
{
	g_allowpickup = true
}
public zp_round_ended()
{
	g_allowpickup = false
}
public PickItUp(ent)
{
	if(pev_valid(ent) != 2)
		return
		
	if(!g_allowpickup)
		return
		
	static id; id = get_pdata_cbase(ent, 41, 4)
	if(!is_user_alive(id) || !is_user_bot(id) || zp_get_user_zombie(id) || get_pdata_cbase(id, 373) != ent)
		return	
		
	new i, Float:Origin[3], classname[32];
	
	pev( id , pev_origin , Origin );
	
	while((i = find_ent_in_sphere(i, Origin, PICKUP_RANGE)) != 0)
	{
		if(is_user_connected(i))continue
		
		pev(i,pev_classname,classname,charsmax(classname))        
		if(!equal(classname,"weaponbox"))continue
		fake_touch(i,id)		
		break;
	} 
} 
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
