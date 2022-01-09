#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>
#include <zombieplague>
#include <hamsandwich>
#include <fakemeta_util>
#include <fun>

#define PLUGIN "[ZP] Extra Item: Force Field Grenade"
#define VERSION "v2.1"
#define AUTHOR "lucas_7_94" // Thanks To Users in credits too!.

#define PUSH 3.0

#define ValidTouch(%1) ( is_user_alive(%1) && is_user_bot(%1) && ( !zp_get_user_zombie(%1) || zp_get_user_nemesis(%1) ) )
#define S_MODEL "models/pallet_with_bags.mdl"

new const entclas[] = "campo_grenade_forze"
new AvailMap

enum MapInfo
{
	MapName[32],
	TheOrigin[3]
}

static const map[][MapInfo] = { 
	{	//blue wood
		"zm_toan", {-746, 98, -357}},
	{	//blue rock
		"zm_toan", {-11, 828, -357}},
	{	//green
		"zm_toan", {616, -423, -357}},
	{	//yellow 1
		"zm_toan", {-558, -369, -339}},
	{	//yellow 2
		"zm_toan", {-558, -369, -289}},
	{	//red
		"zm_toan", {610, 440, -339}},
	{	//red 1
		"zm_toan", {582, 383, -357}},
	{	//red 2
		"zm_toan", {582, 331, -357}},
	{	//red
		"zm_toan", {670, 440, -339}},
	{	//red
		"zm_toan", {730, 440, -339}},
	{	//red
		"zm_toan", {790, 440, -339}},
	{	//red
		"zm_toan", {860, 440, -339}},
	{	//red
		"zm_toan", {610, 440, -289}},
	{	//red
		"zm_toan",  {670, 440, -289}},
	{	//red
		"zm_toan", {730, 440, -289}},
	{	//red
		"zm_toan", {790, 440, -289}},
	{	//red
		"zm_toan", {860, 440, -289}
	}
}
/*=============================[End Customization]=============================*/

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_forward(FM_Touch, "fw_touch")
	register_clcmd("say /fs","make_id")
}
public event_round_start()
{
	remove_entity_name(entclas)
}
public plugin_natives()
{
	register_native("makefs", "native_make", 1)
}
public plugin_precache()
{
	precache_model(S_MODEL)	
}
public client_putinserver(id)
{
	new g_MapName[33];
	get_mapname(g_MapName,32);
	for(new i=0;i<sizeof(map);i++)
		if(equal(map[i][MapName],g_MapName))
		{
			AvailMap = true;
			return;
		}
			
	AvailMap = false;
}
public native_make(id)
{
	make()
}

public make()
{
	if(!AvailMap)
		return;
	new g_MapName[33];
	get_mapname(g_MapName,32);
	
	static ran_num;
	static Float:Origin[3];
	
	for(new i=0;i<sizeof(map);i++)
	{
		if(!equali(map[ran_num][MapName],g_MapName))
			continue

		Origin[0] = float(map[i][TheOrigin][0])
		Origin[1] = float(map[i][TheOrigin][1])
		Origin[2] = float(map[i][TheOrigin][2])
		crear_ent(Origin)
	}
}
public make_id(id)
{
	if(!AvailMap)
		return;
	new g_MapName[33];
	get_mapname(g_MapName,32);
	
	static Float:Origin[3];
	
	for(new i=0;i<sizeof(map);i++)
	{
		if(!equali(map[i][MapName],g_MapName))
			continue

		Origin[0] = float(map[i][TheOrigin][0])
		Origin[1] = float(map[i][TheOrigin][1])
		Origin[2] = float(map[i][TheOrigin][2])
		client_print(id, print_chat, "Origin: %i %i %i",map[i][TheOrigin][0],map[i][TheOrigin][1],map[i][TheOrigin][2])
		crear_ent(Origin)
	}
}
public crear_ent(Float:Origin[3]) {
	
	// Create entitity
	new iEntity = create_entity("info_target")
	
	if(!is_valid_ent(iEntity))
		return PLUGIN_HANDLED

	entity_set_string(iEntity, EV_SZ_classname, entclas)
	entity_set_vector(iEntity,EV_VEC_origin, Float:Origin)
	entity_set_int(iEntity, EV_INT_solid, SOLID_TRIGGER)
	set_pev(iEntity, pev_mins, {-25.0, -25.0, -50.0})
	set_pev(iEntity, pev_maxs, {25.0, 25.0, 50.0})
	//entity_set_model(iEntity, S_MODEL)
	engfunc(EngFunc_SetOrigin, iEntity,Origin)
	
	return PLUGIN_CONTINUE;
}
public fw_touch(ent, touched)
{
	if ( !pev_valid(ent) ) return FMRES_IGNORED;
	static entclass[32];
	pev(ent, pev_classname, entclass, 31);
	
	if ( equali(entclass, entclas) )
	{	
		if( ValidTouch(touched) )
		{
			new Float:pos_ptr[3], Float:pos_ptd[3], Float:push_power = PUSH
			
			pev(ent, pev_origin, pos_ptr)
			pev(touched, pev_origin, pos_ptd)
			
			for(new i = 0; i < 3; i++)
			{
				pos_ptd[i] -= pos_ptr[i]
				pos_ptd[i] *= push_power
			}
			set_pev(touched, pev_velocity, pos_ptd)
			set_pev(touched, pev_impulse, pos_ptd)
		}
	}
	return PLUGIN_HANDLED
}
