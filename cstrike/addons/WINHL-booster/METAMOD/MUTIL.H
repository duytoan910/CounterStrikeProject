// vi: set ts=4 sw=4 :
// vim: set tw=75 :

// mutil.h - prototypes for utility functions to provide to plugins

/*
 * Copyright (c) 2001, Will Day <willday@hpgx.net>
 * This file is covered by the GPL.
 */

#ifndef MUTIL_H
#define MUTIL_H

#include "plinfo.h"		// plugin_info_t, etc

// max buffer size for printed messages
#define MAX_LOGMSG_LEN  1024

// Meta Utility Function table type.
typedef struct meta_util_funcs_s {
	void		(*pfnLogConsole)		(plid_t plid, const char *fmt, ...);
	void		(*pfnLogMessage)		(plid_t plid, const char *fmt, ...);
	void		(*pfnLogError)			(plid_t plid, const char *fmt, ...);
	void		(*pfnLogDeveloper)		(plid_t plid, const char *fmt, ...);
	void		(*pfnCenterSay)			(plid_t plid, const char *fmt, ...);
	void		(*pfnCenterSayParms)	(plid_t plid, hudtextparms_t tparms, 
											const char *fmt, ...);
	void		(*pfnCenterSayVarargs)	(plid_t plid, hudtextparms_t tparms, 
											const char *fmt, va_list ap);
} mutil_funcs_t;
extern mutil_funcs_t MetaUtilFunctions;

// Meta Utility Functions
void mutil_LogConsole(plid_t plid, const char *fmt, ...);
void mutil_LogMessage(plid_t plid, const char *fmt, ...);
void mutil_LogError(plid_t plid, const char *fmt, ...);
void mutil_LogDeveloper(plid_t plid, const char *fmt, ...);

void mutil_CenterSay(plid_t plid, const char *fmt, ...);
void mutil_CenterSayParms(plid_t plid, hudtextparms_t tparms, 
		const char *fmt, ...);
void mutil_CenterSayVarargs(plid_t plid, hudtextparms_t tparms, 
		const char *fmt, va_list ap);

// Convenience macros for MetaUtil functions
#define LOG_CONSOLE		(*gpMetaUtilFuncs->pfnLogConsole)
#define LOG_MESSAGE		(*gpMetaUtilFuncs->pfnLogMessage)
#define LOG_ERROR		(*gpMetaUtilFuncs->pfnLogError)
#define LOG_DEVELOPER	(*gpMetaUtilFuncs->pfnLogDeveloper)
#define CENTER_SAY		(*gpMetaUtilFuncs->pfnCenterSay)
#define CENTER_SAY_PARMS	(*gpMetaUtilFuncs->pfnCenterSayParms)
#define CENTER_SAY_VARARGS	(*gpMetaUtilFuncs->pfnCenterSayVarargs)

#endif /* MUTIL_H */
