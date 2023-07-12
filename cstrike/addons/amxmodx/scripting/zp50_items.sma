/*================================================================================
	
	--------------------------
	-*- [ZP] Items Manager -*-
	--------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <amx_settings_api>
#include <zp50_colorchat>
#include <zp50_gamemodes>
#include <zp50_core_const>
#include <zp50_items_const>

// Extra Items file
new const ZP_EXTRAITEMS_FILE[] = "zp_extraitems.ini"

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205

#define MAXPLAYERS 32

// For item list menu handlers
#define MENU_PAGE_ITEMS g_menu_data[id]
new g_menu_data[MAXPLAYERS+1]

enum _:TOTAL_FORWARDS
{
	FW_ITEM_SELECT_PRE = 0,
	FW_ITEM_SELECT_POST
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

// Items data
new Array:g_ItemRealName
new Array:g_ItemName
new Array:g_ItemCost
new g_ItemCount
new g_AdditionalMenuText[32]
new g_roundStarted

enum (+=200){
	TASK_BOT_BUY_Z = 3000
}

#define ID_BOT_BUY_Z (taskid - TASK_BOT_BUY_Z)

public plugin_init()
{
	register_plugin("[ZP] Items Manager", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_clcmd("say /items", "clcmd_items")
	register_clcmd("say items", "clcmd_items")
	register_clcmd("zp_buy", "clcmd_items")
	register_clcmd("say /list", "listitem")
	
	g_Forwards[FW_ITEM_SELECT_PRE] = CreateMultiForward("zp_fw_items_select_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
	g_Forwards[FW_ITEM_SELECT_POST] = CreateMultiForward("zp_fw_items_select_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
}

public plugin_natives()
{
	register_library("zp50_items")
	register_native("zp_items_register", "native_items_register")
	register_native("zp_items_get_id", "native_items_get_id")
	register_native("zp_items_get_name", "native_items_get_name")
	register_native("zp_items_get_real_name", "native_items_get_real_name")
	register_native("zp_items_get_cost", "native_items_get_cost")
	register_native("zp_items_show_menu", "native_items_show_menu")
	register_native("zp_items_force_buy", "native_items_force_buy")
	register_native("zp_items_menu_text_add", "native_items_menu_text_add")
	
	// Initialize dynamic arrays
	g_ItemRealName = ArrayCreate(32, 1)
	g_ItemName = ArrayCreate(32, 1)
	g_ItemCost = ArrayCreate(1, 1)
}

public native_items_register(plugin_id, num_params)
{
	new name[32], cost = get_param(2)
	get_string(1, name, charsmax(name))
	
	if (strlen(name) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't register item with an empty name")
		return ZP_INVALID_ITEM;
	}
	
	new index, item_name[32]
	for (index = 0; index < g_ItemCount; index++)
	{
		ArrayGetString(g_ItemRealName, index, item_name, charsmax(item_name))
		if (equali(name, item_name))
		{
			log_error(AMX_ERR_NATIVE, "[ZP] Item already registered (%s)", name)
			return ZP_INVALID_ITEM;
		}
	}
	
	// Load settings from extra items file
	new real_name[32]
	copy(real_name, charsmax(real_name), name)
	ArrayPushString(g_ItemRealName, real_name)
	
	// Name
	if (!amx_load_setting_string(ZP_EXTRAITEMS_FILE, real_name, "NAME", name, charsmax(name)))
		amx_save_setting_string(ZP_EXTRAITEMS_FILE, real_name, "NAME", name)
	ArrayPushString(g_ItemName, name)
	
	// Cost
	if (!amx_load_setting_int(ZP_EXTRAITEMS_FILE, real_name, "COST", cost))
		amx_save_setting_int(ZP_EXTRAITEMS_FILE, real_name, "COST", cost)
	ArrayPushCell(g_ItemCost, cost)
	
	g_ItemCount++
	return g_ItemCount - 1;
}

public native_items_get_id(plugin_id, num_params)
{
	new real_name[32]
	get_string(1, real_name, charsmax(real_name))
	
	// Loop through every item
	new index, item_name[32]
	for (index = 0; index < g_ItemCount; index++)
	{
		ArrayGetString(g_ItemRealName, index, item_name, charsmax(item_name))
		if (equali(real_name, item_name))
			return index;
	}
	
	return ZP_INVALID_ITEM;
}

public native_items_get_name(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return false;
	}
	
	new name[32]
	ArrayGetString(g_ItemName, item_id, name, charsmax(name))
	
	new len = get_param(3)
	set_string(2, name, len)
	return true;
}

public native_items_get_real_name(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return false;
	}
	
	new real_name[32]
	ArrayGetString(g_ItemRealName, item_id, real_name, charsmax(real_name))
	
	new len = get_param(3)
	set_string(2, real_name, len)
	return true;
}

public native_items_get_cost(plugin_id, num_params)
{
	new item_id = get_param(1)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return -1;
	}
	
	return ArrayGetCell(g_ItemCost, item_id);
}

public native_items_show_menu(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	clcmd_items(id)
	return true;
}

public native_items_force_buy(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new item_id = get_param(2)
	
	if (item_id < 0 || item_id >= g_ItemCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid item id (%d)", item_id)
		return false;
	}
	
	new ignorecost = get_param(3)
	
	buy_item(id, item_id, ignorecost)
	return true;
}

public native_items_menu_text_add(plugin_id, num_params)
{
	static text[32]
	get_string(1, text, charsmax(text))
	format(g_AdditionalMenuText, charsmax(g_AdditionalMenuText), "%s%s", g_AdditionalMenuText, text)
}

public client_disconnect(id)
{
	// Reset remembered menu pages
	MENU_PAGE_ITEMS = 0
}

public clcmd_items(id)
{
	// Player dead
	if (!is_user_alive(id))
		return;
	
	show_items_menu(id)
}

new g_PlayerBought[33];

public zp_fw_gamemodes_start(game_mode_id){
	for(new id=0;id<get_maxplayers();id++){
		if(!is_user_bot(id))
			continue
		bot_buy_item(TASK_BOT_BUY_Z+id)
	}
	g_roundStarted = true
}

public zp_fw_gamemodes_end(game_mode_id){
	for(new id=0;id<get_maxplayers();id++){
		if(!is_user_bot(id))
			continue
		g_PlayerBought[id] = false
		remove_task(id+TASK_BOT_BUY_Z)
	}
	g_roundStarted = false
}
public zp_fw_core_infect_post(id){
	if(!g_roundStarted)
		return;
	if(!is_user_bot(id))
		return

	remove_task(id+TASK_BOT_BUY_Z)
	set_task(random_float(5.0, 30.0), "bot_buy_item", TASK_BOT_BUY_Z+id,_,_,"a", 1)
}
public zp_fw_core_cure_post(id){
	if(!g_roundStarted)
		return;
	if(!is_user_bot(id))
		return

	remove_task(id+TASK_BOT_BUY_Z)
	set_task(random_float(1.0, 5.0), "bot_buy_item", TASK_BOT_BUY_Z+id)

}
public bot_buy_item(taskid){
	new id;id = ID_BOT_BUY_Z

	if(!is_user_alive(id) || zp_core_is_zombie(id) || g_PlayerBought[id])
		 return;

	new randomIndex; randomIndex = random_num(0, g_ItemCount-1)

	ExecuteForward(g_Forwards[FW_ITEM_SELECT_PRE], g_ForwardResult, id, randomIndex, 0)


	new name[50]
	ArrayGetString(g_ItemName, randomIndex, name, charsmax(name))
	engclient_cmd(id,"say", "Buying", name)
	if (g_ForwardResult >= ZP_ITEM_DONT_SHOW){
		bot_buy_item(id)
		return
	}
	else{
		if(g_ForwardResult == ZP_ITEM_NOT_AVAILABLE){
			bot_buy_item(id)
			return
		}else{
			buy_item(id, randomIndex, 1)
			return
		}
	}
	return;
}

public listitem(id){
	static name[32], cost, transkey[64]
	for (new index = 0; index < g_ItemCount; index++){
		ExecuteForward(g_Forwards[FW_ITEM_SELECT_PRE], g_ForwardResult, id, index, 0)
		
		// Show item to player?
		if (g_ForwardResult >= ZP_ITEM_DONT_SHOW)
			continue;
		
		ArrayGetString(g_ItemName, index, name, charsmax(name))
		cost = ArrayGetCell(g_ItemCost, index)
		
		// ML support for item name
		formatex(transkey, charsmax(transkey), "ITEMNAME %s", name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(name, charsmax(name), "%L", id, transkey)

		client_print(id, print_chat, "%d: %s %d",index, name, cost)
	}
}

// Items Menu
show_items_menu(id)
{
	static menu[128], name[32], cost, transkey[64]
	new menuid, index, itemdata[2]
	
	// Title
	formatex(menu, charsmax(menu), "%L:\r", id, "MENU_EXTRABUY")
	menuid = menu_create(menu, "menu_extraitems")
	
	// Item List
	for (index = 0; index < g_ItemCount; index++)
	{
		// Additional text to display
		g_AdditionalMenuText[0] = 0
		
		// Execute item select attempt forward
		ExecuteForward(g_Forwards[FW_ITEM_SELECT_PRE], g_ForwardResult, id, index, 0)
		
		// Show item to player?
		if (g_ForwardResult >= ZP_ITEM_DONT_SHOW)
			continue;
		
		// Add Item Name and Cost
		ArrayGetString(g_ItemName, index, name, charsmax(name))
		cost = ArrayGetCell(g_ItemCost, index)
		
		// ML support for item name
		formatex(transkey, charsmax(transkey), "ITEMNAME %s", name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(name, charsmax(name), "%L", id, transkey)
		
		// Item available to player?
		if (g_ForwardResult >= ZP_ITEM_NOT_AVAILABLE)
			formatex(menu, charsmax(menu), "\d%s %d %s", name, cost, g_AdditionalMenuText)
		else
			formatex(menu, charsmax(menu), "%s \y%d \w%s", name, cost, g_AdditionalMenuText)
		
		itemdata[0] = index
		itemdata[1] = 0
		menu_additem(menuid, menu, itemdata)
	}
	
	// No items to display?
	if (menu_items(menuid) <= 0)
	{
		zp_colored_print(id, "%L", id, "NO_EXTRA_ITEMS")
		menu_destroy(menuid)
		return;
	}
	
	// Back - Next - Exit
	formatex(menu, charsmax(menu), "%L", id, "MENU_BACK")
	menu_setprop(menuid, MPROP_BACKNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_NEXT")
	menu_setprop(menuid, MPROP_NEXTNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_EXIT")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
	
	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_ITEMS = min(MENU_PAGE_ITEMS, menu_pages(menuid)-1)
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	menu_display(id, menuid, MENU_PAGE_ITEMS)
}

// Items Menu
public menu_extraitems(id, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT)
	{
		MENU_PAGE_ITEMS = 0
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Remember items menu page
	MENU_PAGE_ITEMS = item / 7
	
	// Dead players are not allowed to buy items
	if (!is_user_alive(id))
	{
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Retrieve item id
	new itemdata[2], dummy, itemid
	menu_item_getinfo(menuid, item, dummy, itemdata, charsmax(itemdata), _, _, dummy)
	itemid = itemdata[0]
	
	// Attempt to buy the item
	buy_item(id, itemid)
	menu_destroy(menuid)
	return PLUGIN_HANDLED;
}

// Buy Item
buy_item(id, itemid, ignorecost = 0)
{
	// Execute item select attempt forward
	ExecuteForward(g_Forwards[FW_ITEM_SELECT_PRE], g_ForwardResult, id, itemid, ignorecost)
	
	// Item available to player?
	if (g_ForwardResult >= ZP_ITEM_NOT_AVAILABLE)
		return;
	
	// Execute item selected forward
	ExecuteForward(g_Forwards[FW_ITEM_SELECT_POST], g_ForwardResult, id, itemid, ignorecost)

	if(!is_user_bot(id))
		return

	g_PlayerBought[id] = true
	
	new name[50]
	new num2 = random_num(1,5)
	ArrayGetString(g_ItemName, itemid, name, charsmax(name))
	switch(num2)
	{
		case 1:
		{
			engclient_cmd(id,"say", "Nice! Now i have", name)
		}
		case 2:
		{
			engclient_cmd(id,"say", "Hehe, I'll kill you with my", name)
		}
		case 5:
		{
			engclient_cmd(id,"say", "I've just trying to buy",name)
		}
	}
}
