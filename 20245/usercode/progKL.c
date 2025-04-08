#ifndef PROGKL_INC_C_
#define PROGKL_INC_C_
#include <common.h>

/**
** User function main #4:  exit, fork, exec, sleep, write
**
** Loops, spawning N copies of progX and sleeping between spawns.
**
** Invoked as:  progKL  x  n
**	 where x is the ID character
**		   n is the iteration count (defaults to 5)
*/

USERMAIN( progKL ) {
	char *name = argv[0] ? argv[0] : "nobody";
	int count = 5;			// default iteration count
	char ch = '4';			// default character to print
	int nap = 30;			// nap time
	char msg2[] = "*4*";	// "error" message to print
	char buf[32];

	// process the command-line arguments
	switch( argc ) {
	case 3:	count = ustr2int( argv[2], 10 );
			// FALL THROUGH
	case 2:	ch = argv[1][0];
			break;
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
			cwrites( buf );
			for( int i = 0; i <= argc; ++i ) {
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
				cwrites( buf );
			}
			cwrites( "\n" );
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );

	// argument vector for the processes we will spawn
	char *arglist[] = { "progX", "X", buf, NULL };

	for( int i = 0; i < count ; ++i ) {

		write( CHAN_SIO, &ch, 1 );

		// second argument to X is 100 plus the iteration number
		usprint( buf, "%d", 100 + i );
		int whom = spawn( (uint32_t) progX, arglist );
		if( whom < 0 ) {
			swrites( msg2 );
		} else {
			write( CHAN_SIO, &ch, 1 );
		}

		sleep( SEC_TO_MS(nap) );
	}

	exit( 0 );

	return( 42 );  // shut the compiler up!
}
#endif
