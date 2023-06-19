#include <amxmodx>
#include <fakemeta>
#include <zombieplague>
#include <hamsandwich>
#include <engine>

new g_started[33], g_ham_bot

public plugin_init()
{
	register_plugin("Bot not attack when round begin", "0.1", "Dolph_ziggler")
	
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	register_forward( FM_CmdStart , "fm_CmdStart" );
}
public client_putinserver(id)
{
	if(!g_ham_bot && is_user_bot(id))
	{
		g_ham_bot = 1
		set_task(0.1, "do_register", id)
	}
}

public do_register(id)
{
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
}

public Player_Spawn(id){
	set_task(5.0, "ThrowSK", id)
}
public ThrowSK(id){
	g_started[id] = false
}
public zp_round_started(){
	for(new i=0;i<get_maxplayers();i++){
		set_task(random_float(0.1, 3.0), "setIt", i)
	}
}
public setIt(id){
	g_started[id] = true
}
public zp_round_ended(){
	for(new i=0;i<get_maxplayers();i++){
		g_started[i] = false
	}
}
public fm_CmdStart(id,Handle)
{
	new Buttons; Buttons = get_uc(Handle,UC_Buttons);

	if(is_user_bot(id) && !g_started[id])
	{

		Buttons &= ~IN_ATTACK;
		set_uc( Handle , UC_Buttons , Buttons );
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
} 
