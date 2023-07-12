#include <amxmodx>
#include <amxmisc>
#include <amx_settings_api>
#include <zp50_core>
#include <zp50_items>

#define PLUGIN "[ZP50] Class unlocker"
#define VERSION "1.1"
#define AUTHOR "Catastrophe"

#define MAX_LIST 128
#define PLUGIN_MODE 2

new const EXTRAS_FILE[] = "zp_extra_limit.ini"

new Array:extra_id
new Array:extra_limit

#if defined PLUGIN_MODE 1
new extra_count[33][MAX_LIST]
#endif

#if defined PLUGIN_MODE 2
new extra_count_global[MAX_LIST]
#endif

new zpel_cvars[3]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
        register_event("HLTV", "event_newround", "a", "1=0", "2=0")
        register_cvar("ZPEL","1",(FCVAR_SERVER|FCVAR_SPONLY))
 
        zpel_cvars[0] = register_cvar("zp_extra_limit_mode", "0")
}

public plugin_precache()
{
       extra_id = ArrayCreate(64, 1)
       extra_limit = ArrayCreate(4, 1)
      
       amx_load_setting_string_arr(EXTRAS_FILE, "LIMIT", "item_id", extra_id)
       amx_load_setting_string_arr(EXTRAS_FILE, "LIMIT", "item_limit", extra_limit)

}

public event_newround()
{
       if(get_pcvar_num(zpel_cvars[0]) != 0)
       return

       #if defined PLUGIN_MODE 1
       for(new i = 1; i <= get_maxplayers(); i++)
       {
             arrayset(extra_count[i], 0, MAX_LIST - 1)
       }
       #endif
	    
       #if defined PLUGIN_MODE 2
       for(new j = 0; j <= MAX_LIST - 1; j++)
       {
             extra_count_global[j] = 0
       }
       #endif
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
    new txt[32]

    for(new i = 0; i <= ArraySize(extra_id) - 1; i++)
    {
        new e_id[64], e_lim[4]
        new e_lim_num 
        ArrayGetString(extra_id, i, e_id, charsmax(e_id))
        ArrayGetString(extra_limit, i, e_lim, charsmax(e_lim))
        e_lim_num = str_to_num(e_lim)
	
        if(itemid == zp_items_get_id(e_id))
        {
               #if defined PLUGIN_MODE 1
	      if(extra_count[id][i] >= e_lim_num)
	      {
	      format(txt, charsmax(txt), "\d[%d/%d]", extra_count[id][i],e_lim_num)
	      zp_items_menu_text_add(txt)
	      return ZP_ITEM_NOT_AVAILABLE
	      }	

              else
              {
              format(txt, charsmax(txt), "\w[%d/%d]", extra_count[id][i],e_lim_num)
	      zp_items_menu_text_add(txt)
	      return ZP_ITEM_AVAILABLE
              }
	     #endif
	     
	    #if defined PLUGIN_MODE 2
	      if(extra_count_global[i] >= e_lim_num)
	      {
	      format(txt, charsmax(txt), "\d[%d/%d]", extra_count[i],e_lim_num)
	      zp_items_menu_text_add(txt)
	      return ZP_ITEM_NOT_AVAILABLE
	      }	

              else
              {
              format(txt, charsmax(txt), "\w[%d/%d]", extra_count[i],e_lim_num)
	      zp_items_menu_text_add(txt)
	      return ZP_ITEM_AVAILABLE
              }
	     #endif
        }
	
    }
    return ZP_ITEM_AVAILABLE
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{	
	    
    for(new i = 0; i <= ArraySize(extra_id) - 1; i++)
    {
        new e_id[64]
        ArrayGetString(extra_id, i, e_id, charsmax(e_id))

        if(itemid == zp_items_get_id(e_id))
        {    
	   #if defined PLUGIN_MODE 1	
            extra_count[id][i]++      
	   #endif
	   
	   #if defined PLUGIN_MODE 2	
            extra_count_global[i]++      
	   #endif
        }
    }
}
