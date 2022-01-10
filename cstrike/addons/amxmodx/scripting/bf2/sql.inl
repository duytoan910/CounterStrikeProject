//Bf2 Rank Mod SQL File
//Contains subroutines for all SQL features.

#if defined bf2_sql_included
  #endinput
#endif
#define bf2_sql_included

//Load details for sql..
public sql_init()
{
	g_SqlTuple = SQL_MakeStdTuple();

	//Try and find existing table and if not create one
	SQL_ThreadQuery(g_SqlTuple, "TableHandle", "CREATE TABLE IF NOT EXISTS bf2ranks (playerid VARCHAR(35), badge1 TINYINT(4), badge2 TINYINT(4), badge3 TINYINT(4), badge4 TINYINT(4), badge5 TINYINT(4), badge6 TINYINT(4), knife SMALLINT(6), pistol SMALLINT(6), sniper SMALLINT(6), support SMALLINT(6), kills INT(11), defuses INT(11), plants INT(11), explosions INT(11), PRIMARY KEY (playerid))");
	SQL_ThreadQuery(g_SqlTuple, "TableHandle", "CREATE TABLE IF NOT EXISTS bf2ranks2 (playerid VARCHAR(35), badge7 TINYINT(4), badge8 TINYINT(4), shotgun SMALLINT(6), smg SMALLINT(6), rifle SMALLINT(6), grenade SMALLINT(6), gold INT(11), silver INT(11), bronze INT(11), highestrank VARCHAR(35), mostkills VARCHAR(35), mostwins VARCHAR(35), PRIMARY KEY (playerid))");
}

//Load all data from the sql table for given use
public sql_load(id)
{
	new index[1];
	index[0] = id;

	//Escape ' character incase save key is a name
	new tempSaveKey[63];
	copy(tempSaveKey, charsmax(tempSaveKey), gSaveKey[id]);
	replace_all(tempSaveKey, charsmax(tempSaveKey), "'", "\'" );

	//New player joined. Load their row from the table
	//NOTE: "*" (aka SQL all) is not used because we do not want playerid (the first column), be aware this changes the column order for SelectHandle info gotten.
	formatex(g_Cache, charsmax(g_Cache), "SELECT badge1, badge2, badge3, badge4, badge5, badge6, knife, pistol, sniper, support, kills, defuses, plants, explosions FROM bf2ranks WHERE playerid='%s'", tempSaveKey);
	SQL_ThreadQuery(g_SqlTuple, "SelectHandle", g_Cache, index, 1);

	formatex(g_Cache, charsmax(g_Cache), "SELECT badge7, badge8, shotgun, smg, rifle, grenade, gold, silver, bronze FROM bf2ranks2 WHERE playerid='%s'", tempSaveKey);
	SQL_ThreadQuery(g_SqlTuple, "SelectHandle2", g_Cache, index, 1);
}

public sql_server_load()
{
	//Load server Data
	//Gold, silver and bronze store the highestrank, mostkills and mostwins values repectively. The other 3 are the names
	SQL_ThreadQuery(g_SqlTuple, "SelectHandleServer", "SELECT gold, silver, bronze, highestrank, mostkills, mostwins FROM bf2ranks2 WHERE playerid='Server'");
}

//Save given users data to the sql table
public sql_save(id)
{
	//Player has left. Update their row in the table
	if ( gStatsLoaded[id] >= 2 ) //only save if they correctly loaded both table data
	{
		//Maybe change this to client disconnects, not sure how bad that would lag game play.
		if ( gIntermission )
		{
			// This gets run at map change do not thread this query
			// note: intermission is not called if map is changed manually
			sql_save_nonthreaded(id);
			return;
		}

		//Escape ' character incase save key is a name
		new tempSaveKey[63];
		copy(tempSaveKey, charsmax(tempSaveKey), gSaveKey[id]);
		replace_all(tempSaveKey, charsmax(tempSaveKey), "'", "\'" );

		formatex(g_Cache, charsmax(g_Cache), "UPDATE bf2ranks SET badge1=%i, badge2=%i, badge3=%i, badge4=%i, badge5=%i, badge6=%i, knife=%i, pistol=%i, sniper=%i, support=%i, kills=%i, defuses=%i, plants=%i, explosions=%i WHERE playerid=^"%s^"",
		g_PlayerBadges[id][BADGE_KNIFE], g_PlayerBadges[id][BADGE_PISTOL], g_PlayerBadges[id][BADGE_ASSAULT], g_PlayerBadges[id][BADGE_SNIPER], g_PlayerBadges[id][BADGE_SUPPORT], g_PlayerBadges[id][BADGE_EXPLOSIVES], knifekills[id], pistolkills[id], sniperkills[id], parakills[id], totalkills[id], defuses[id], plants[id], explosions[id], tempSaveKey);
		SQL_ThreadQuery(g_SqlTuple, "QueryHandle", g_Cache);

		formatex(g_Cache, charsmax(g_Cache), "UPDATE bf2ranks2 SET badge7=%i, badge8=%i, shotgun=%i, smg=%i, rifle=%i, grenade=%i, gold=%i, silver=%i, bronze=%i WHERE playerid=^"%s^"", g_PlayerBadges[id][BADGE_SHOTGUN], g_PlayerBadges[id][BADGE_SMG], shotgunkills[id], smgkills[id], riflekills[id], grenadekills[id], gold[id], silver[id], bronze[id], tempSaveKey);
		SQL_ThreadQuery(g_SqlTuple, "QueryHandle", g_Cache);
	}
}

sql_save_nonthreaded(id)
{
	new Errcode, Error[128], Handle:SqlConnection;

	SqlConnection = SQL_Connect(g_SqlTuple, Errcode, Error, charsmax(Error));

	if ( !SqlConnection )
	{
		log_amx("Save - Could not connect to SQL database.  [%d] %s", Errcode, Error);
		SQL_FreeHandle(SqlConnection);
		return;
	}

	//Escape ' character incase save key is a name
	new tempSaveKey[63];
	copy(tempSaveKey, charsmax(tempSaveKey), gSaveKey[id]);
	replace_all(tempSaveKey, charsmax(tempSaveKey), "'", "\'" );

	new Handle:Query;
	Query = SQL_PrepareQuery(SqlConnection, "UPDATE bf2ranks SET badge1=%i, badge2=%i, badge3=%i, badge4=%i, badge5=%i, badge6=%i, knife=%i, pistol=%i, sniper=%i, support=%i, kills=%i, defuses=%i, plants=%i, explosions=%i WHERE playerid=^"%s^"",
	g_PlayerBadges[id][BADGE_KNIFE], g_PlayerBadges[id][BADGE_PISTOL], g_PlayerBadges[id][BADGE_ASSAULT], g_PlayerBadges[id][BADGE_SNIPER], g_PlayerBadges[id][BADGE_SUPPORT], g_PlayerBadges[id][BADGE_EXPLOSIVES], knifekills[id], pistolkills[id], sniperkills[id], parakills[id], totalkills[id], defuses[id], plants[id], explosions[id], tempSaveKey);
	if ( !SQL_Execute(Query) )
	{
		Errcode = SQL_QueryError(Query, Error, charsmax(Error));
		log_amx("Save Query failed. [%d] %s", Errcode, Error);
		SQL_FreeHandle(Query);
		SQL_FreeHandle(SqlConnection);
		return;
	}
	SQL_FreeHandle(Query);

	Query = SQL_PrepareQuery(SqlConnection, "UPDATE bf2ranks2 SET badge7=%i,badge8=%i, shotgun=%i, smg=%i, rifle=%i, grenade=%i, gold=%i, silver=%i, bronze=%i WHERE playerid=^"%s^"", g_PlayerBadges[id][BADGE_SHOTGUN], g_PlayerBadges[id][BADGE_SMG], shotgunkills[id], smgkills[id], riflekills[id], grenadekills[id], gold[id], silver[id], bronze[id], tempSaveKey);
	if ( !SQL_Execute(Query) )
	{
		Errcode = SQL_QueryError(Query, Error, charsmax(Error));
		log_amx("Save Query failed. [%d] %s", Errcode, Error);
	}

	SQL_FreeHandle(Query);
	SQL_FreeHandle(SqlConnection);
}

public sql_server_save()
{
	// This gets run at plugin_end do not thread this query
	new Errcode, Error[128], Handle:SqlConnection;

	SqlConnection = SQL_Connect(g_SqlTuple, Errcode, Error, charsmax(Error));

	if ( !SqlConnection )
	{
		log_amx("Save - Could not connect to SQL database.  [%d] %s", Errcode, Error);
		SQL_FreeHandle(SqlConnection);
		return;
	}

	//Save server Data
	new tempTopName[63], tempPtsName[63], tempWinsName[63];
	copy(tempTopName, charsmax(tempTopName), highestrankservername);
	copy(tempPtsName, charsmax(tempPtsName), mostkillsname);
	copy(tempWinsName, charsmax(tempWinsName), mostwinsname);

	replace_all(tempTopName, charsmax(tempTopName), "'", "\'");
	replace_all(tempPtsName, charsmax(tempPtsName), "'", "\'");
	replace_all(tempWinsName, charsmax(tempWinsName), "'", "\'");

	new Handle:Query;
	Query = SQL_PrepareQuery(SqlConnection, "UPDATE bf2ranks2 SET gold=%i, silver=%i, bronze=%i, highestrank='%s', mostkills='%s', mostwins='%s' WHERE playerid=^"Server^"", highestrankserver, mostkills, mostwins, tempTopName, tempPtsName, tempWinsName);
	if ( !SQL_Execute(Query) )
	{
		Errcode = SQL_QueryError(Query, Error, charsmax(Error));
		log_amx("Save Query failed. [%d] %s", Errcode, Error);
	}

	SQL_FreeHandle(Query);
	SQL_FreeHandle(SqlConnection);
}

//Return Function for the open/create table query
public TableHandle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	//Check for errors on loading the table (connection probs etc)
	if ( FailState )
	{
		if ( FailState == TQUERY_CONNECT_FAILED )
		{
			log_amx("Table - Could not connect to SQL database.  [%d] %s", Errcode, Error);
		}
		else if ( FailState == TQUERY_QUERY_FAILED )
		{
			log_amx("Table Query failed. [%d] %s", Errcode, Error);
		}

		SQLenabled = false;

		return;
	}

	SQLenabled = true;

	if ( !mostwins )
	{
		server_load();
	}
}

//Return Function for the save data query
public QueryHandle(FailState, Handle:Query, Error[], Errcode,Data[], DataSize)
{
	//Check for errors when making a write to table query
	if ( FailState )
	{
		if ( FailState == TQUERY_CONNECT_FAILED )
		{
			log_amx("Save - Could not connect to SQL database.  [%d] %s", Errcode, Error);
		}
		else if ( FailState == TQUERY_QUERY_FAILED )
		{
			log_amx("Save Query failed. [%d] %s", Errcode, Error);
		}

		return;
	}
}

//Return Function for the select query
public SelectHandle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	//Check for errors and then process loading from table queries
	if ( FailState )
	{
		if ( FailState == TQUERY_CONNECT_FAILED )
		{
			log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);
		}
		else if ( FailState == TQUERY_QUERY_FAILED )
		{
			log_amx("Load Query failed. [%d] %s", Errcode, Error);
		}

		return;
	}

	new id = Data[0];

	if ( !SQL_NumResults(Query) ) // No more results - User not found, create them a blank entry in the table. and zero their variables
	{
		for ( new counter = 0; counter <6 ; counter++ )
		{
			g_PlayerBadges[id][counter] = 0;
		}

		knifekills[id] = 0;
		pistolkills[id] = 0;
		sniperkills[id] = 0;
		parakills[id] = 0;
		totalkills[id] = 0;
		defuses[id] = 0;
		plants[id] = 0;
		explosions[id] = 0;

		//Escape ' character incase save key is a name
		new tempSaveKey[63];
		copy(tempSaveKey, charsmax(tempSaveKey), gSaveKey[id]);
		replace_all(tempSaveKey, charsmax(tempSaveKey), "'", "\'" );

		formatex(g_Cache, charsmax(g_Cache), "INSERT INTO bf2ranks VALUES('%s', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0')", tempSaveKey);
		SQL_ThreadQuery(g_SqlTuple, "QueryHandle", g_Cache);
	}
	else
	{
		//Player must have been found. Loop through and load the columns into the global vars
		for (new counter = 0; counter < 6; counter++)
		{
			g_PlayerBadges[id][counter] = SQL_ReadResult(Query, counter);
		}

		knifekills[id] = SQL_ReadResult(Query, 6);
		pistolkills[id] = SQL_ReadResult(Query, 7);
		sniperkills[id] = SQL_ReadResult(Query, 8);
		parakills[id] = SQL_ReadResult(Query, 9);
		totalkills[id] = SQL_ReadResult(Query, 10);
		defuses[id] = SQL_ReadResult(Query, 11);
		plants[id] = SQL_ReadResult(Query, 12);
		explosions[id] = SQL_ReadResult(Query, 13);
	}

	gStatsLoaded[id]++;
}

public SelectHandle2(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	//Check for errors and then process loading from table queries
	if ( FailState )
	{
		if ( FailState == TQUERY_CONNECT_FAILED )
		{
			log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);
		}
		else if ( FailState == TQUERY_QUERY_FAILED )
		{
			log_amx("Load Query failed. [%d] %s", Errcode, Error);
		}

		return;
	}

	new id = Data[0];

	if ( !SQL_NumResults(Query) ) // No more results - User not found, create them a blank entry in the table. and zero their variables
	{
		for ( new counter = 6; counter < 8; counter++ )
		{
			g_PlayerBadges[id][counter] = 0;
		}

		shotgunkills[id] = 0;
		smgkills[id] = 0;
		riflekills[id] = 0;
		grenadekills[id] = 0;
		gold[id] = 0;
		silver[id] = 0;
		bronze[id] = 0;

		//Escape ' character incase save key is a name
		new tempSaveKey[63];
		copy(tempSaveKey, charsmax(tempSaveKey), gSaveKey[id]);
		replace_all(tempSaveKey, charsmax(tempSaveKey), "'", "\'" );

		formatex(g_Cache, charsmax(g_Cache), "INSERT INTO bf2ranks2 VALUES('%s','0','0','0','0','0','0','0','0','0','0','0','0')", tempSaveKey);
		SQL_ThreadQuery(g_SqlTuple, "QueryHandle", g_Cache);
	}
	else
	{
		//Player must have been found. Loop through and load the columns into the global vars
		g_PlayerBadges[id][6] = SQL_ReadResult(Query, 0);
		g_PlayerBadges[id][7] = SQL_ReadResult(Query, 1);
		shotgunkills[id] = SQL_ReadResult(Query, 2);
		smgkills[id] = SQL_ReadResult(Query, 3);
		riflekills[id] = SQL_ReadResult(Query, 4);
		grenadekills[id] = SQL_ReadResult(Query, 5);
		gold[id] = SQL_ReadResult(Query, 6);
		silver[id] = SQL_ReadResult(Query, 7);
		bronze[id] = SQL_ReadResult(Query, 8);
	}

	gStatsLoaded[id]++;
}

public SelectHandleServer(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	//Check for errors and then process loading from table queries
	if ( FailState )
	{
		if ( FailState == TQUERY_CONNECT_FAILED )
		{
			log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);
		}
		else if ( FailState == TQUERY_QUERY_FAILED )
		{
			log_amx("Load Query failed. [%d] %s", Errcode, Error);
		}

		return;
	}

	if ( !SQL_NumResults(Query) ) // No more results - User not found, create them a blank entry in the table. and zero their variables
	{
		highestrankserver = 0;
		mostkills = 0;
		mostkillsid = 0;
		mostwins = 0;

		SQL_ThreadQuery(g_SqlTuple, "QueryHandle", "INSERT INTO bf2ranks2 VALUES('Server','0','0','0','0','0','0','0','0','0','0','0','0')");
		return;
	}

	highestrankserver = SQL_ReadResult(Query, 0);
	mostkills = SQL_ReadResult(Query, 1);
	mostwins = SQL_ReadResult(Query, 2);
	SQL_ReadResult(Query, 3, highestrankservername, charsmax(highestrankservername));
	SQL_ReadResult(Query, 4, mostkillsname, charsmax(mostkillsname));
	SQL_ReadResult(Query, 5, mostwinsname, charsmax(mostwinsname));
}