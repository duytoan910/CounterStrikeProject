/*	Formatright © 2010, ConnorMcLeod

	No See Vars is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with No See Vars; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

#include <amxmodx>

#pragma semicolon 1

#define VERSION "0.1.0"

new g_szLogFile[64];

public plugin_init()
{
	register_plugin("No See Vars", VERSION, "ConnorMcLeod");

	get_localinfo("amxx_logs", g_szLogFile, charsmax(g_szLogFile));
	add(g_szLogFile, charsmax(g_szLogFile), "/no_see_vars.log");
}

public plugin_cfg()
{
	new szConfigFile[128];
	get_localinfo("amxx_configsdir", szConfigFile, charsmax(szConfigFile));
	add(szConfigFile, charsmax(szConfigFile), "/nsv.cfg");

	new fp = fopen(szConfigFile, "rt");
	if( !fp )
	{
		return 0;
	}

	new szText[256], szCvar[128], szFlags[4];
	while( !feof(fp) )
	{
		fgets(fp, szText, charsmax(szText));
		trim(szText);
		if(!szText[0] || szText[0] == ';' || szText[0] == '#' || (szText[0] == '/' && szText[1] == '/'))
		{
			continue;
		}

		parse(szText, szCvar, charsmax(szCvar), szFlags, charsmax(szFlags));
		SetCvarFlags(szCvar, str_to_num(szFlags));
	}
	fclose(fp);
	return 1;
}

SetCvarFlags( const szCvar[] , const iFlags = 0 )
{
	new pCvar = get_cvar_pointer(szCvar);
	if( pCvar )
	{
		new iOldFlags = get_pcvar_flags(pCvar);
		if( iFlags != iOldFlags )
		{
			new fp = fopen(g_szLogFile, "at");
			fprintf(fp, "^nSetting cvar ^"%s^" flags to %s^n", szCvar, Util_FCVAR(iFlags));
			fprintf(fp, "Previous ^"%s^" flags were %s^n", szCvar, Util_FCVAR(iOldFlags));
			fclose(fp);
			set_pcvar_flags( pCvar, iFlags );
		}
		return 1;
	}
	return 0;
}

Util_FCVAR( const fCvar )
{
	new szFlags[256], n;
	if( fCvar & FCVAR_ARCHIVE ) n += formatex(szFlags[n], charsmax(szFlags)-n, "FCVAR_ARCHIVE | ");
	if( fCvar & FCVAR_USERINFO ) n += formatex(szFlags[n], charsmax(szFlags)-n, "FCVAR_USERINFO | ");
	if( fCvar & FCVAR_SERVER ) n += formatex(szFlags[n], charsmax(szFlags)-n, "FCVAR_SERVER | ");
	if( fCvar & FCVAR_EXTDLL ) n += formatex(szFlags[n], charsmax(szFlags)-n, "FCVAR_EXTDLL | ");
	if( fCvar & FCVAR_CLIENTDLL ) n += formatex(szFlags[n], charsmax(szFlags)-n, "FCVAR_CLIENTDLL | ");
	if( fCvar & FCVAR_PROTECTED ) n += formatex(szFlags[n], charsmax(szFlags)-n, "FCVAR_PROTECTED | ");
	if( fCvar & FCVAR_SPONLY ) n += formatex(szFlags[n], charsmax(szFlags)-n, "FCVAR_SPONLY | ");
	if( fCvar & FCVAR_PRINTABLEONLY ) n += formatex(szFlags[n], charsmax(szFlags)-n, "FCVAR_PRINTABLEONLY | ");
	if( fCvar & FCVAR_UNLOGGED ) n += formatex(szFlags[n], charsmax(szFlags)-n, "FCVAR_UNLOGGED | ");
	if( szFlags[0] ) szFlags[n-2] = 0;
	else szFlags = "0";
	return szFlags;
}
