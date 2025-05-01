/**
** @file	udefs.h
**
** @author	CSCI-452 class of 20245
**
** @brief	"Userland" configuration information
*/

#ifndef UDEFS_H_
#define UDEFS_H_

#include <common.h>

/*
** General (C and/or assembly) definitions
**
** This section of the header file contains definitions that can be
** used in either C or assembly-language source code.
*/

// delay loop counts

#define DELAY_LONG		100000000
#define DELAY_MED		4500000
#define DELAY_SHORT		2500000

#define DELAY_STD		DELAY_SHORT

#ifndef ASM_SRC

/*
** Start of C-only definitions
*/

// convenience macros

// a delay loop - kind of ugly, but it works

#define DELAY(n)	do { \
		for(int _dlc = 0; _dlc < (DELAY_##n); ++_dlc) continue; \
	} while(0)

/*
** We need the list of program IDs so that we can request 
** their execution
*/

// not using a separate user blob
// #include <userids.h>

/*
** All user main() functions have the following prototype:
**
**	int name( int argc, char *argv[] );
**
** To simplify declaring them, we define a macro that expands into
** that header. This can be used both in the implementation (followed
** by the function body) and in places where we just need the prototype
** (following it with a semicolon).
**
** Each is designed to test some facility of the OS; see the users.h
** header file for a summary of which system calls are tested by
** each user function.
**
** Output from user processes is usually alphabetic.  Uppercase
** characters are "expected" output; lowercase are (typically) "erroneous"
** output.
**
** More specific information about each user process can be found in
** the header comment for that function in its source file.
**
** To make a specific user process available for spawning, uncomment its
** SPAWN_x definition in the list at the end of this header file.
*/

#define USERMAIN(f)	int f( int argc, char *argv[] )

// these are always started
USERMAIN(init);    USERMAIN(idle);    USERMAIN(shell);

// these are started by other processes (e.g., the shell)
USERMAIN(progABC); USERMAIN(progDE);  USERMAIN(progFG);     USERMAIN(progH);
USERMAIN(progI);   USERMAIN(progJ);   USERMAIN(progKL);     USERMAIN(progMN);
USERMAIN(progO);   USERMAIN(progP);   USERMAIN(progQ);      USERMAIN(progR);
USERMAIN(progS);   USERMAIN(progTUV); USERMAIN(progW);      USERMAIN(progX);
USERMAIN(progY);   USERMAIN(progZ);   USERMAIN(color_test); USERMAIN(drawing_test);
USERMAIN(sprite_test); USERMAIN(vga_type); USERMAIN(snake);

#endif /* !ASM_SRC */

/*
** User process controls.
**
** To enable a specific test, define the symbol SPAWN_name here, and
** guard the places in other code that use or refer to that test. For
** example, test 'A' is enabled by definining SPAWN_A here, and all
** places that refer to test 'A' are guarded with:
**
**      #ifdef SPAWN_A
**          ... conditionally-compiled code
**      #endif
**
** Generally, most of these will exit with a status of 0.  If a process
** returns from its main function when it shouldn't (e.g., if it had
** called exit() but continued to run), it will usually return a status
** of ?.
*/

/*
** The standard set of test programs, start by the shell (which is started
** automatically from the initial user process)
**
** There is no user 'O' program, and programs 'W' through 'Z' are spawned
** from other processes and are never spawned directly.
*/

#define SPAWN_A
#define SPAWN_B
#define SPAWN_C
#define SPAWN_D
#define SPAWN_E
#define SPAWN_F
#define SPAWN_G
#define SPAWN_H
#define SPAWN_I
#define SPAWN_J
#define SPAWN_K
#define SPAWN_L
#define SPAWN_M
#define SPAWN_N
#define SPAWN_P
#define SPAWN_Q
#define SPAWN_R
#define SPAWN_S
#define SPAWN_T
#define SPAWN_U
#define SPAWN_V
#define SPAWN_COLOR_TEST
#define SPAWN_DRAWING_TEST
#define SPAWN_SPRITE_TEST
#define SPAWN_VGA_TYPE
#define SPAWN_SNAKE

#endif
