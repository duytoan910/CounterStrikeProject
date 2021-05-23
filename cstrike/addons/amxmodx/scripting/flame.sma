#include <amxmodx>
#include <engine>
#include <fakemeta_util>

new const flame1[] = "sprites/flame3.spr"

new flame1_id

#define FLAME_CLASSNAME "ToanFlame"
#define FLAME_FAKE_CLASSNAME "ToanFakeFlame"

public plugin_init()
{
	register_think(FLAME_CLASSNAME, "FlameThink")
	register_think(FLAME_FAKE_CLASSNAME, "FlameFakeThink")
	
	register_clcmd("say /fl1", "draw_fl_1")
	register_clcmd("say /rmv", "remove_fl_1")
}
public plugin_precache()
{
	flame1_id = precache_model(flame1)
}
public remove_fl_1() remove_entity_name(FLAME_CLASSNAME)
public draw_fl_1(id)
{
	Draw_Sprite(id, flame1_id)
}
public Draw_Sprite(id, spr)
{
	new Float:End1[3], Float:origin[5][3]
	fm_get_aim_origin(id, End1)
	
	//Show_Sprite(id, spr, End1)
	
	get_spherical_coord(End1, 40.0, 0.0, 0.0, origin[0])
	get_spherical_coord(End1, 40.0, 90.0, 0.0, origin[1])
	get_spherical_coord(End1, 40.0, 180.0, 0.0, origin[2])
	get_spherical_coord(End1, 40.0, 270.0, 0.0, origin[3])
	//get_spherical_coord(End1, 0.0, 0.0, 0.0, origin[4])
	for (new i = 0; i < 4; i++)
	{
		Show_Sprite(id, spr, origin[i])
	}	
}
public Show_Sprite(id, spr, Float:End1[3])
{
	/*	//TE_EXPLOSION
	new TE_FLAG	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
				
	// Exp
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, End1[0])
	engfunc(EngFunc_WriteCoord, End1[1])
	engfunc(EngFunc_WriteCoord, End1[2])
	write_short(spr)	// sprite index
	write_byte(5)	// scale in 0.1's
	write_byte(5)	// framerate
	write_byte(TE_FLAG)	// flags
	message_end()
	*/
	
	/*	//TE_SPRITE
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, End1[0])
	engfunc(EngFunc_WriteCoord, End1[1])
	engfunc(EngFunc_WriteCoord, End1[2])
	write_short(spr)	// sprite index
	write_byte(5)	// scale in 0.1's
	write_byte(155)	// alpha
	message_end()
	*/

	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Ent)) return
	
	// Set info for ent
	set_pev(Ent, pev_solid, SOLID_NOT)
	set_pev(Ent, pev_movetype, MOVETYPE_NONE)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 80.0)
	set_pev(Ent, pev_scale, 0.5)
	set_pev(Ent, pev_fuser1, get_gametime())
	
	set_pev(Ent, pev_classname, FLAME_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, flame1)
	//set_pev(Ent, pev_gravity, 1.0)
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
	
	End1[2]+= 30.0
	set_pev(Ent, pev_origin, End1)	
}
public Create_Fake_Flame(ent)
{
	new Float:Origin[3];
	pev(ent, pev_origin, Origin)
	
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(Ent)) return -1;
	
	// Set info for ent
	set_pev(Ent, pev_solid, SOLID_NOT)
	set_pev(Ent, pev_movetype, MOVETYPE_FLY)
	set_pev(Ent, pev_rendermode, kRenderTransAdd)
	set_pev(Ent, pev_renderamt, 20.0)
	set_pev(Ent, pev_scale, random_float(0.4,0.6))
	set_pev(Ent, pev_owner, ent)
	
	set_pev(Ent, pev_classname, FLAME_FAKE_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, flame1)
	
	set_pev(Ent, pev_nextthink, get_gametime())
	set_pev(Ent, pev_origin, Origin)
	
	new Vel[3]
	Vel[0] += random_float(-17.0, 17.0)
	Vel[1] += random_float(-17.0, 17.0)
	Vel[2] += random_float(15.0, 25.0)
	set_pev(Ent, pev_velocity, Vel)
	
	return Ent;
}
public FlameThink(iEnt)
{
	if(!pev_valid(iEnt)) 
		return;
	
	if(pev(iEnt, pev_flags) & FL_KILLME) 
		return;
	
	static Float:fFrame
	pev(iEnt, pev_frame, fFrame)
	
	fFrame += 1.0
	if(fFrame >= 16.0) 
		fFrame = 0.0 //set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
		
	new Float:time_1; 
	pev(iEnt, pev_fuser1, time_1)
	if(time_1 + 0.1 <= get_gametime()) 
	{
		Create_Fake_Flame(iEnt)
		set_pev(iEnt, pev_fuser1, get_gametime())
	}else{
		time_1 += 0.03
		set_pev(iEnt, pev_fuser1, time_1)
	}
	
	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)
}
public FlameFakeThink(iEnt)
{
	if(!pev_valid(iEnt)) 
		return;
	
	if(pev(iEnt, pev_flags) & FL_KILLME) 
		return;
		
	new Owner = pev(iEnt, pev_owner);
	if(!pev_valid(Owner))
	{
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
		return
	}
	
	static Float:fFrame, Float:Alpha, Float:Scale; 
	pev(iEnt, pev_frame, fFrame)	
	pev(iEnt, pev_scale, Scale)	
	pev(iEnt, pev_renderamt, Alpha)
	
	fFrame += 1.0
	Alpha -= 0.5
	Scale -= 0.015
	if(fFrame >= 17.0) 
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
		
	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_scale, Scale)
	set_pev(iEnt, pev_renderamt, Alpha)
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1)
}
get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	new Float:length
	length  = redius * floatcos(vertical_angle, degrees)
	origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees)
	origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees)
	origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
