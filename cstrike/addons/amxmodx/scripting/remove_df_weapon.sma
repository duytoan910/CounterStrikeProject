 #include <amxmodx>
    #include <fakemeta>

    new gMaxClients;
    new gTimer;

    public plugin_precache() 
    { 
        new Entity;
        
        Entity = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString , "player_weaponstrip" ) );
        SetKeyValue( Entity, "targetname", "strip", "player_weaponstrip" );
        dllfunc( DLLFunc_Spawn, Entity );
        
        Entity = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString , "game_player_equip" ) );
        SetKeyValue( Entity, "weapon_knife", "1"    , "game_player_equip" );
        SetKeyValue( Entity, "targetname"  , "knife", "game_player_equip" );
        dllfunc( DLLFunc_Spawn, Entity );
        
        Entity = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString , "multi_manager" ) );
        SetKeyValue( Entity, "knife"      , "0.5"  , "multi_manager" );
        SetKeyValue( Entity, "strip"      , "0"    , "multi_manager" );
        SetKeyValue( Entity, "targetname" , "timer", "multi_manager" );
        SetKeyValue( Entity, "spawnflags" , "1"    , "multi_manager" );
        dllfunc( DLLFunc_Spawn, Entity );
        
        gTimer = Entity;
    } 
    
    public plugin_init()
    {
        register_plugin( "Disarm in new round", "0.1", "alan_el_more" );
        register_event( "HLTV", "Event_NewRound", "a", "1=0", "2=0" );
        
        gMaxClients = get_maxplayers()
    }
    
    public Event_NewRound ()
    {
        for ( new Client; Client <= gMaxClients; Client++ )
        {
            if ( is_user_alive ( Client ) )
            {
                dllfunc( DLLFunc_Use, gTimer, Client );
            }
        }
    }
    
    SetKeyValue ( Entity, const Key[], const Value[], const ClassName[] ) 
    { 
        set_kvd( 0, KV_ClassName, ClassName );
        set_kvd( 0, KV_KeyName, Key ); 
        set_kvd( 0, KV_Value, Value ); 
        set_kvd( 0, KV_fHandled, 0 );
        dllfunc( DLLFunc_KeyValue, Entity, 0 );
    }
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
