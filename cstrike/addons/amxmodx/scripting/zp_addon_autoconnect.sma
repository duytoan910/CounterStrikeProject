#include <amxmodx>

#define PLUGIN_NAME "Auto Join on Connect"
#define PLUGIN_VERSION "0.1"
#define PLUGIN_AUTHOR "VEN"

#define IMMUNITY_ACCESS_LEVEL ADMIN_IMMUNITY

#define AUTO_TEAM_JOIN_DELAY 0.1

#define TEAM_SELECT_VGUI_MENU_ID 2

new bool:saw[33]

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	register_message(get_user_msgid("ShowMenu"), "message_show_menu")
	register_message(get_user_msgid("VGUIMenu"), "message_vgui_menu")
	register_message(get_user_msgid("MOTD"), "message_MOTD")

}

public client_connect(id)
{
	saw[id] = false
}
public message_MOTD(const MsgId, const MsgDest, const MsgEntity)
{
	if(!saw[MsgEntity])
	{
		if(get_msg_arg_int(1) == 1)
		{
			saw[MsgEntity] = true
			return PLUGIN_HANDLED
		}		
	}
	return PLUGIN_CONTINUE
}

public message_show_menu(msgid, dest, id) {
	static team_select[] = "#Team_Select"
	static menu_text_code[sizeof team_select]
	get_msg_arg_string(4, menu_text_code, sizeof menu_text_code - 1)
	if (!equal(menu_text_code, team_select))
		return PLUGIN_CONTINUE

	set_force_team_join_task(id, msgid)

	return PLUGIN_HANDLED
}

public message_vgui_menu(msgid, dest, id) {
	if (get_msg_arg_int(1) != TEAM_SELECT_VGUI_MENU_ID)
		return PLUGIN_CONTINUE

	set_force_team_join_task(id, msgid)

	return PLUGIN_HANDLED
}

set_force_team_join_task(id, menu_msgid) {
	static param_menu_msgid[2]
	param_menu_msgid[0] = menu_msgid
	set_task(AUTO_TEAM_JOIN_DELAY, "task_force_team_join", id, param_menu_msgid, sizeof param_menu_msgid)
}

public task_force_team_join(menu_msgid[], id) {
	if (get_user_team(id))
		return

	force_team_join(id, menu_msgid[0], "5", "5")
}

stock force_team_join(id, menu_msgid, /* const */ team[] = "5", /* const */ class[] = "0") {
	static jointeam[] = "jointeam"
	if (class[0] == '0') {
		engclient_cmd(id, jointeam, team)
		return
	}

	static msg_block, joinclass[] = "joinclass"
	msg_block = get_msg_block(menu_msgid)
	set_msg_block(menu_msgid, BLOCK_SET)
	engclient_cmd(id, jointeam, team)
	engclient_cmd(id, joinclass, class)
	set_msg_block(menu_msgid, msg_block)
}
