#include <amxmodx>
#include <fakemeta>

new  g_offset[2], g_ping[3]
new g_maxplayers, g_connected[33]

public plugin_init()
{
    register_plugin("Bot Ping Faker", "1.1", "MeRcyLeZZ\bugsy")

    g_maxplayers = get_maxplayers()
    
    register_forward(FM_UpdateClientData, "fw_UpdateClientData")
}

public client_putinserver(id)
{
    g_connected[id] = true
}

public client_disconnect(id)
{
    g_connected[id] = false
}

public fw_UpdateClientData(id)
{
    // Scoreboard key being pressed?
    if (!(pev(id, pev_button) & IN_SCORE) && !(pev(id, pev_oldbuttons) & IN_SCORE))
        return;
    
    static player, sending, ping
    sending = 0
    
    for (player = 1; player <= g_maxplayers; player++)
    {
        if (!g_connected[player] || !is_user_bot(player))
             continue;
 
        //make each players ping vary a bit
        switch( player )
        {
            case 1,2,3,4: ping = random_num( 15, 35)
            case 5,6,7,8: ping = random_num(40, 60)
            case 9,10,11,12: ping = random_num( 60, 80)
            case 13,14,15,16: ping = random_num( 75, 100)
            case 17,18,19,20: ping = random_num( 70, 90)
            case 21,22,23,24: ping = random_num( 50, 80)
            case 25,26,27,28: ping = random_num( 20, 40)
            default: ping = random_num( 45, 65)
        }
        
        // Calculate weird argument values based on target ping
        // -> first ping
        for (g_offset[0] = 0; g_offset[0] < 4; g_offset[0]++)
        {
            if ((ping - g_offset[0]) % 4 == 0)
            {
                g_ping[0] = (ping - g_offset[0]) / 4
                break;
            }
        }
        // -> second ping
        for (g_offset[1] = 0; g_offset[1] < 2; g_offset[1]++)
        {
            if ((ping - g_offset[1]) % 2 == 0)
            {
                g_ping[1] = (ping - g_offset[1]) / 2
                break;
            }
        }
        
        // -> third ping
        g_ping[2] = ping
        
        // Send message with the weird arguments
        switch (sending)
        {
            case 0:
            {
                // Start a new message
                message_begin(MSG_ONE_UNRELIABLE, SVC_PINGS, _, id)
                write_byte((g_offset[0] * 64) + ((2 * player) - 1))
                write_short(g_ping[0])
                sending++
            }
            case 1:
            {
                // Append additional data
                write_byte((g_offset[1] * 128) + (2 + 4 * (player - 1)))
                write_short(g_ping[1])
                sending++
            }
            case 2:
            {
                // Append additional data and end message
                write_byte((4 + 8 * (player - 1)))
                write_short(g_ping[2])
                write_byte(0)
                message_end()
                sending = 0
            }
        }
    }
    
    // End message if not yet sent
    if (sending)
    {
        write_byte(0)
        message_end()
    }
} 