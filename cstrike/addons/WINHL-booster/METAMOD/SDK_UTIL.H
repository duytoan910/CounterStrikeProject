// vi: set ts=4 sw=4 :
// vim: set tw=75 :

// sdk_util.h - wrapper & extension of util.h from HL SDK

/*
 * Copyright (c) 2001, Will Day <willday@hpgx.net>
 */

// Wrap util.h from SDK with ifndef/endif, to avoid problems from multiple
// inclusions.  Dunno why Valve didn't do that in util.h themselves..

#ifndef SDK_UTIL_H
#define SDK_UTIL_H

// We're not including the DBG_EntOfVars and DBG_AssertFunction routines
// mentioned in the SDK util.h, so we're going to unset DEBUG here so that
// we don't get "unresolved symbol" errors.
#ifdef DEBUG
#undef DEBUG
#endif /* DEBUG */

#include <util.h>


// Also, create some additional macros for engine callback functions, which
// weren't in SDK dlls/enginecallbacks.h but probably should have been.

#define GET_INFOKEYBUFFER	(*g_engfuncs.pfnGetInfoKeyBuffer)
#define INFOKEY_VALUE		(*g_engfuncs.pfnInfoKeyValue)
#define SET_CLIENT_KEYVALUE	(*g_engfuncs.pfnSetClientKeyValue)
#define REG_SVR_COMMAND		(*g_engfuncs.pfnAddServerCommand)
#define SERVER_PRINT		(*g_engfuncs.pfnServerPrint)
#define SET_SERVER_KEYVALUE	(*g_engfuncs.pfnSetKeyValue)

// Also, create some nice inlines for engine callback combos.

// Get a setinfo value from a player entity.
inline char *ENTITY_KEYVALUE(edict_t *entity, char *key) {
	char *ifbuf=GET_INFOKEYBUFFER(entity);
	return(INFOKEY_VALUE(ifbuf, key));
}

// Set a setinfo value for a player entity.
inline void ENTITY_SET_KEYVALUE(edict_t *entity, char *key, char *value) {
	char *ifbuf=GET_INFOKEYBUFFER(entity);
	SET_CLIENT_KEYVALUE(ENTINDEX(entity), ifbuf, key, value);
}

// Get a "serverinfo" value.
inline char *SERVERINFO(char *key) {
	edict_t *server=INDEXENT(0);
	return(ENTITY_KEYVALUE(server, key));
}

// Set a "serverinfo" value.
inline void SET_SERVERINFO(char *key, char *value) {
	edict_t *server=INDEXENT(0);
	char *ifbuf=GET_INFOKEYBUFFER(server);
	SET_SERVER_KEYVALUE(ifbuf, key, value);
}

// Get a "localinfo" value.
inline char *LOCALINFO(char *key) {
	edict_t *server=NULL;
	return(ENTITY_KEYVALUE(server, key));
}

// Set a "localinfo" value.
inline void SET_LOCALINFO(char *key, char *value) {
	edict_t *server=NULL;
	char *ifbuf=GET_INFOKEYBUFFER(server);
	SET_SERVER_KEYVALUE(ifbuf, key, value);
}

short FixedSigned16(float value, float scale);
unsigned short FixedUnsigned16(float value, float scale);

#endif /* SDK_UTIL_H */
