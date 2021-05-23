#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>

#define MORE_DAMAGE 40

new g_Ham_Bot

public plugin_init()
{
	RegisterHam(Ham_TakeDamage, "player", "Ham_PlayerTakeDamage_Pre");
}

public client_putinserver(id)
{
	if(!g_Ham_Bot && is_user_bot(id))
	{
		g_Ham_Bot = 1
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
}

public Do_RegisterHam_Bot(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "Ham_PlayerTakeDamage_Pre")
}
public Ham_PlayerTakeDamage_Pre(VictimID, InflictorID, AttackerID, Float:Damage, DamageBits)
{
	if (DamageBits & (1<<24))
	{
		if(AttackerID==VictimID)
			return HAM_SUPERCEDE;
			
		SetHamParamFloat(4, Damage * MORE_DAMAGE); // Walla
	}
	return HAM_IGNORED;
}
