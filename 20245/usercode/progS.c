#ifndef PROGS_INC_C_
#define PROGS_INC_C_
#include <common.h>

/**
** User function S:   exit, sleep, write
**
** Reports itself, then loops forever, sleeping on each iteration
**
** Invoked as:  progS  x  [ s ]
**	 where x is the ID character
**		   s is the sleep time (defaults to 20)
*/

USERMAIN( progS ) {
	char *name = argv[0] ? argv[0] : "nobody";
	char ch = 's';	  // default character to print
	int nap = 20;	  // nap time
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
	case 3:	nap = ustr2int( argv[2], 10 );
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

	usprint( buf, "%s sleeping %d(%d)\n", name, nap, SEC_TO_MS(nap) );
	cwrites( buf );

	for(;;) {
		sleep( SEC_TO_MS(nap) );
		write( CHAN_SIO, &ch, 1 );
	}

	usprint( buf, "!! %c exiting!?!?!?\n", ch );
	cwrites( buf );
	exit( 1 );

	return( 42 );  // shut the compiler up!
}
#endif
