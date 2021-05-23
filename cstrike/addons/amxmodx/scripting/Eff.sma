#include <amxmodx>
#include <zombieplague>

public plugin_natives()
{
	register_native("nst_zb_get_user_zombie", "get_user_zombie")
	register_native("zd_get_user_zombie", "get_user_zombie")
}
public get_user_zombie(id)
{
	return zp_get_user_zombie(id)
}
