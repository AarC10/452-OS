#ifndef UINIT_INC_C_
#define UINIT_INC_C_
#include <common.h>

/**
** Initial process; it starts the other top-level user processes.
**
** Prints a message at startup, '+' after each user process is spawned,
** and '!' before transitioning to wait() mode to the SIO, and
** startup and transition messages to the console. It also reports
** each child process it collects via wait() to the console along
** with that child's exit status.
*/

/*
** This table contains one entry for each process that should be
** started by 'init'. Typically, this includes the 'idle' process
** and a 'shell' process.
*/
static proc_t init_spawn_table[] = {

	// the idle process; it runs at Deferred priority,
	// so it will only be dispatched when there is
	// nothing else available to be dispatched
	PROCENT( idle, PRIO_DEFERRED, "!", "idle", "." ),

	// the user shell
	PROCENT( idle, PRIO_STD, "@", "shell" ),

	// PROCENT( 0, 0, 0, 0 )
	{ TBLEND }
};

// character to be printed by 'init'
static char ch = '+';

/**
** process - spawn all user processes listed in the supplied table
**
** @param proc  pointer to the spawn table entry to be used
*/

static void process( proc_t *proc )
{
	char buf[128];

	// kick off the process
	int32_t p = fork();
	if( p < 0 ) {

		// error!
		usprint( buf, "INIT: fork for #%d failed\n",
				(uint32_t) (proc->entry) );
		cwrites( buf );

	} else if( p == 0 ) {

		// change child's priority
		(void) setprio( proc->e_prio );

		// now, send it on its way
		exec( proc->entry, proc->args );

		// uh-oh - should never get here!
		usprint( buf, "INIT: exec(0x%08x) failed\n",
				(uint32_t) (proc->entry) );
		cwrites( buf );

	} else {

		// parent just reports that another one was started
		swritech( ch );

		proc->pid = p;

	}
}

/*
** The initial user process. Should be invoked with zero or one
** argument; if provided, the first argument should be the ASCII
** character 'init' will print to indicate the spawning of a process.
*/
USERMAIN( init ) {
	char *name = argv[0] ? argv[0] : "nobody";
	char buf[128];

	// check to see if we got a non-standard "spawn" character
	if( argc > 1 ) {
		// maybe - check it to be sure it's printable
		uint_t i = argv[1][0];
		if( i > ' ' && i < 0x7f ) {
			ch = argv[1][0];
		}
	}

	// test the sio
	write( CHAN_SIO, "$+$\n", 4 );
	DELAY(SHORT);

	usprint( buf, "%s: started\n", name );
	cwrites( buf );

	// home up, clear on a TVI 925
	// swritech( '\x1a' );

	// wait a bit
	DELAY(SHORT);

	// a bit of Dante to set the mood :-)
	swrites( "\n\nSpem relinquunt qui huc intrasti!\n\n\r" );

	/*
	** Start all the user processes
	*/

	usprint( buf, "%s: starting user processes\n", name );
	cwrites( buf );

	proc_t *next;
	for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
		process( next );
	}

	swrites( " !!!\r\n\n" );

	/*
	** At this point, we go into an infinite loop waiting
	** for our children (direct, or inherited) to exit.
	*/

	usprint( buf, "%s: transitioning to wait() mode\n", name );
	cwrites( buf );

	for(;;) {
		int32_t status;
		int whom = waitpid( 0, &status );

		// PIDs must be positive numbers!
		if( whom <= 0 ) {

			usprint( buf, "%s: waitpid() returned %d???\n", name, whom );
			cwrites( buf );

		} else {

			// got one; report it
			usprint( buf, "%s: pid %d exit(%d)\n", name, whom, status );
			cwrites( buf );

			// figure out if this is one of ours
			for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
				if( next->pid == whom ) {
					// one of ours - reset the PID field
					// (in case the spawn attempt fails)
					next->pid = 0;
					// and restart it
					process( next );
					break;
				}
			}
		}
	}

	/*
	** SHOULD NEVER REACH HERE
	*/

	cwrites( "*** INIT IS EXITING???\n" );
	exit( 1 );

	return( 1 );  // shut the compiler up
}
#endif
