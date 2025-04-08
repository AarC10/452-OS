#ifndef PROGX_INC_C_
#define PROGX_INC_C_
#include <common.h>

/**
** User function X:   exit, write, getpid
**
** Prints its PID at start and exit, iterates printing its character
** N times, and exits with a status of 12.
**
** Invoked as:  progX  x  n
**	 where x is the ID character
**		   n is the iteration count
*/

USERMAIN( progX ) {
	char *name = argv[0] ? argv[0] : "nobody";
	int count = 20;	  // iteration count
	char ch = 'x';	  // default character to print
	char buf[128];

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
	int pid = getpid();
	usprint( buf, " %c[%d]", ch, pid );
	swrites( buf );

	for( int i = 0; i < count ; ++i ) {
		swrites( buf );
		DELAY(STD);
	}

	exit( 12 );

	return( 42 );  // shut the compiler up!
}
#endif
