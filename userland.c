/**
** @file	userland.c
**
** @author	numerous CSCI-452 classes
**
** @brief	User-level code.
**
** This is exceptionally, unbearably ugly. It is all the user-level
** code in one honkin' big file for convenience.
*/

#include <common.h>

#include <lib.h>

/*
** "Spawn table" process entry. Similar to the one in shell.c, but
** this version has a field to hold the PID of the spawned process
** to allow 'init' to respawn it when it terminates.
*/
typedef struct proc_s {
    uint32_t entry;       // process entry point
    char select[2];       // identifying character, NUL
    uint8_t prio;         // process priority
	uint8_t valid;        // is this entry valid?
    uint_t pid;           // its PID (when spawned)
    char *args[N_ARGS+1]; // argument vector strings, plus a NULL
} proc_t;

/*
** Create a spawn table entry for a process with a string literal
** as its argument buffer.  We rely on the fact that the C standard
** ensures our array of pointers will be filled out with NULLs
*/
#define PROCENT(e,p,s,...) { (uint32_t)e, s, p, 1, 0, { __VA_ARGS__ , NULL} }

// sentinel value for the end of the table - must be a value that
// will never occur as the actual entry point of a function
#define TBLEND  0xdebeaded

/*
** System processes - these should always be included here
*/

#include <usercode/idle.c>
#include <usercode/shell.c>
#include <usercode/init.c>

/*
** The user processes
**
** We #include the source code from the userland/ directory only if
** a specific process is being spawned.
**
** Remember to #include the code required by any process that will
** be spawned - e.g., userH spawns userZ.  The user code files all
** contain CPP include guards, so multiple inclusion of a source
** file shouldn't cause problems.
*/

#if defined(SPAWN_A) || defined(SPAWN_B) || defined(SPAWN_C)
#include <usercode/progABC.c>
#endif

#if defined(SPAWN_D) || defined(SPAWN_E)
#include <usercode/progDE.c>
#endif

#if defined(SPAWN_F) || defined(SPAWN_G)
#include <usercode/progFG.c>
#endif

#if defined(SPAWN_H)
#include <usercode/progH.c>
#include <usercode/progZ.c>
#endif

#if defined(SPAWN_I)
#include <usercode/progI.c>
#include <usercode/progW.c>
#endif

#if defined(SPAWN_J)
#include <usercode/progJ.c>
#include <usercode/progY.c>
#endif

#if defined(SPAWN_K) || defined(SPAWN_L)
#include <usercode/progKL.c>
#include <usercode/progX.c>
#endif

#if defined(SPAWN_M) || defined(SPAWN_N)
#include <usercode/progMN.c>
#include <usercode/progW.c>
#include <usercode/progZ.c>
#endif

#if defined(SPAWN_P)
#include <usercode/progP.c>
#endif

#if defined(SPAWN_Q)
#include <usercode/progQ.c>
#endif

#if defined(SPAWN_R)
#include <usercode/progR.c>
#endif

#if defined(SPAWN_S)
#include <usercode/progS.c>
#endif

#if defined(SPAWN_T) || defined(SPAWN_U) || defined(SPAWN_V)
#include <usercode/progTUV.c>
#include <usercode/progW.c>
#endif

#include <usercode/serialTest.c>