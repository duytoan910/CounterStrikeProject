#include <amxmodx>

static iMinutes, iSeconds;

public plugin_init( )
{
	set_task( 1.0 , "UpTime" );
}
public UpTime( )
{
	new iGetGameTime = floatround( get_gametime( ) );
	static RoundTime[6];
	
	iMinutes = iGetGameTime / 60;
	iSeconds = iGetGameTime % 60;
	
	for(new i=0;i<get_maxplayers();i++)
	{
		if(is_user_bot(i))continue
		if(iSeconds<10&&iMinutes<10)
			format(RoundTime, charsmax(RoundTime), "0%d:0%d", iMinutes,iSeconds)
		else if(iSeconds<10&&iMinutes>10)
			format(RoundTime, charsmax(RoundTime), "%d:0%d", iMinutes,iSeconds)	
		else if(iSeconds>10&&iMinutes<10)
			format(RoundTime, charsmax(RoundTime), "0%d:%d", iMinutes,iSeconds)	
		else if(iSeconds>10&&iMinutes>10)		
			format(RoundTime, charsmax(RoundTime), "%d:%d", iMinutes,iSeconds)
			
		set_hudmessage(255, 0, 0, 0.06, 0.245, 2, 1.0, 1.0, 0.1, 0.2, 1)
		show_hudmessage(i, RoundTime)		
	}
	set_task( 1.0 , "UpTime" ); 
}
