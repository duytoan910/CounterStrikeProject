// vi: set ts=4 sw=4 :
// vim: set tw=75 :

// osdep.h - operating system dependencies

/*
 * Copyright (c) 2001, Will Day <willday@hpgx.net>
 */

#ifndef OSDEP_H
#define OSDEP_H

// Various differences between WIN32 and Linux.

#include "support_meta.h"	// mBOOL, etc

// Macro for function-exporting from DLL..
// from SDK dlls/cbase.h:
//! C functions for external declarations that call the appropriate C++ methods

// Windows uses "__declspec(dllexport)" to mark functions in the DLL that
// should be visible/callable externally.
//
// It also apparently requires WINAPI for GiveFnptrsToDll().
//
// See doc/notes_windows.txt for more information..


// String describing platform/DLL-type, for matching lines in metamod.ini.
#ifdef linux
	#define PLATFORM	"linux"
#elif defined(_WIN32)
	#define PLATFORM	"win32"
#else /* unknown */
	#error "OS unrecognized"
#endif /* linux */


// Attributes to specify an "exported" function, visible from outside the
// DLL.
#undef DLLEXPORT
#ifdef _WIN32
	#define DLLEXPORT	__declspec(dllexport)
	// WINAPI should be provided in the windows compiler headers.
	// It's usually defined to something like "__stdcall".
#elif defined(linux)
	#define DLLEXPORT	/* */
	#define WINAPI		/* */
#endif /* _WIN32 */

// Simplified macro for declaring/defining exported DLL functions.  They
// need to be 'extern "C"' so that the C++ compiler enforces parameter
// type-matching, rather than considering routines with mis-matched
// arguments/types to be overloaded functions...
//
// AFAIK, this is os-independent, but it's included here is osdep.h where
// DLLEXPORT is defined, for convenience.
#define C_DLLEXPORT		extern "C" DLLEXPORT

// Set filename and pathname maximum lengths.  Note some windows compilers
// provide a <limits.h> which is incomplete and/or causes problems; see
// doc/windows_notes.txt for more information.
#ifdef linux
	#include <limits.h>
#elif defined(_WIN32)
	#define NAME_MAX	255
	#define PATH_MAX	255
#endif /* linux */


// Various other windows routine differences.
#ifdef linux
	#include <unistd.h>	// sleep
#elif defined(_WIN32)
	#define snprintf	_snprintf
	#define vsnprintf	_vsnprintf
	#define sleep(x)	Sleep(x*1000)
	#define strcasecmp	stricmp
	#define strncasecmp	_strnicmp
	#define S_ISREG(m)	((m) & S_IFREG)
#endif /* _WIN32 */


#endif /* OSDEP_H */
