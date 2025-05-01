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
static proc_t in_spawn_table[] = {

	// the idle process; it runs at Deferred priority,
	// so it will only be dispatched when there is
	// nothing else available to be dispatched
	// PROCENT( idle, PRIO_DEFERRED, ".", "idle", "." ),

	// // the user shell
	// PROCENT( shell, PRIO_STD, "@", "shell" ),

	// // color_test for vertical color bars
	// PROCENT( color_test, PRIO_HIGH, "&", "color_test" ),

	// // drawing_test for various VGA drawing function testing
	// PROCENT( drawing_test, PRIO_HIGH, "&", "drawing_test" ),

	// // sprite_test for testing drawing of sprites to the screen
	// PROCENT( sprite_test, PRIO_HIGH, "&", "sprite_test" ),

	// vga_type for testing keyboard input and printing text
	PROCENT( vga_type, PRIO_HIGH, "&", "vga_type" ),

	// a dummy entry to use as a sentinel
	// { TBLEND }
	{ 0 }	// all fields are zeroes, including 'valid'
};

// static int in_spawn_len = sizeof(in_spawn_table) / sizeof(in_spawn_table[0]);

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
		
		// current priority
		uint_t cprio = getprio();

		// change child's priority if we need to
		if( cprio != proc->prio ) {
			(void) setprio( proc->prio );
		}

		// now, send it on its way
		exec( proc->entry, proc->args );

		// uh-oh - should never get here!
		usprint( buf, "INIT: exec(0x%08x) failed\n",
				(uint32_t) (proc->entry) );
		cwrites( buf );

	} else {

		// parent just reports that another one was started
		// swritech( ch );
		usprint( buf, "%c%c%c", ch, proc->select[0], ch );
		swrites( buf );

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

	usprint( buf, "%s: started\n", name );
	cwrites( buf );

	// home up, clear on a TVI 925
	// swritech( '\x1a' );

	// wait a bit
	DELAY(SHORT);

	// a bit of Dante to set the mood :-)
	swrites( "\nSpem relinquunt qui huc intrasti!\n" );

	/*
	** Start all the user processes
	*/

	usprint( buf, "%s: starting user processes\n!!! ", name );
	cwrites( buf );

	proc_t *next = in_spawn_table;
	while( next->valid ) {
		process( next );
		++next;
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
			next = in_spawn_table;
			while( next->valid ) {
				if( next->pid == whom ) {
					// one of ours - reset the PID field
					// (in case the spawn attempt fails)
					next->pid = 0;
					// and restart it
					process( next );
					break;
				}
				++next;
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
