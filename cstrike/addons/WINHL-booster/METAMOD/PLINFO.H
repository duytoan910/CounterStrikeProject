// vi: set ts=4 sw=4 :
// vim: set tw=75 :

// plinfo.h - typedefs for plugin info structure

/*
 * Copyright (c) 2001, Will Day <willday@hpgx.net>
 * This file is covered by the GPL.
 */

#ifndef PLINFO_H
#define PLINFO_H

// Flags for plugin to indicate when it can be be loaded/unloaded.
// NOTE: order is crucial, as greater/less comparisons are made.
typedef enum {
	PT_NEVER = 0,
	PT_STARTUP,			// should only be loaded/unloaded at initial hlds execution
	PT_CHANGELEVEL,		// can be loaded/unloaded between maps
	PT_ANYTIME,			// can be loaded/unloaded at any time
	PT_ANYPAUSE,		// can be loaded/unloaded at any time, and can be "paused" during a map
} PLUG_LOADTIME;

// Information plugin provides about itself.
typedef struct {
	char *ifvers;				// meta_interface version
	char *name;					// full name of plugin
	char *version;				// version
	char *date;					// date
	char *author;				// author name/email
	char *url;					// URL
	char *logtag;				// log message prefix (unused right now)
	PLUG_LOADTIME loadable;		// when loadable
	PLUG_LOADTIME unloadable;	// when unloadable
} plugin_info_t;
extern plugin_info_t Plugin_info;

// Plugin identifier, passed to all Meta Utility Functions.
typedef plugin_info_t* plid_t;
#define PLID	&Plugin_info

#endif /* PLINFO_H */
