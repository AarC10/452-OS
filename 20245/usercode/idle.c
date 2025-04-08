#ifndef UIDLE_INC_C_
#define UIDLE_INC_C_
#include <common.h>

/**
** Idle process:  write, getpid, gettime, exit
**
** Reports itself, then loops forever delaying and printing a character.
** MUST NOT SLEEP, as it must always be available in the ready queue 
** when there is no other process to dispatch.
**
** Invoked as:	idle
*/

USERMAIN( idle ) {
#ifdef VERBOSE_IDLE
	// this is the character we will repeatedly print
	char ch = '.';
#endif

	// ignore the command-line arguments
	(void) argc;
	char *name = argv[0] ? argv[0] : "nobody";

	// get some current information
	uint_t pid = getpid();
	uint32_t now = gettime();
	enum priority_e prio = getprio();

	char buf[128];
	usprint( buf, "%s [%d], started @ %u\n", name, pid, prio, now );
	cwrites( buf );
	
#ifdef VERBOSE_IDLE
	write( CHAN_SIO, &ch, 1 );
#endif

	// idle() should never block - it must always be available
	// for dispatching when we need to pick a new current process

	for(;;) {
		DELAY(LONG);
#ifdef VERBOSE_IDLE
		write( CHAN_SIO, &ch, 1 );
#endif
	}

	// we should never reach this point!
	now = gettime();
	usprint( buf, "%s [%d] EXITING @ %u!?!?!\n", name, pid, now );
	cwrites( buf );

	exit( 1 );

	return( 42 );
}
#endif
