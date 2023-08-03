/*================================================================================
	
	----------------------------------
	-*- [ZP] Class: Human: Raptor -*-
	----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_class_human>

// Raptor Human Attributes
new const humanclass2_name[] = "Classic Female"
new const humanclass2_info[] = ""
new const humanclass2_models[][] = { "WOMAN_BL", "WOMAN_GR" }
const humanclass2_health = 1000
const Float:humanclass2_speed = 1.0
const Float:humanclass2_gravity = 0.8

new g_HumanClassID

public plugin_precache()
{
	register_plugin("[ZP] Class: Human: Raptor", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_HumanClassID = zp_class_human_register(humanclass2_name, humanclass2_info, humanclass2_health, humanclass2_speed, humanclass2_gravity)
	new index
	for (index = 0; index < sizeof humanclass2_models; index++)
		zp_class_human_register_model(g_HumanClassID, humanclass2_models[index])
}
