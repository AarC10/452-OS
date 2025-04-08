#ifndef PROGQ_INC_C_
#define PROGQ_INC_C_
#include <common.h>

/**
** User function Q:   exit, write, bogus
**
** Reports itself, then tries to execute a bogus system call
**
** Invoked as:  progQ  x
**	 where x is the ID character
*/

USERMAIN( progQ ) {
	char *name = argv[0] ? argv[0] : "nobody";
	char ch = 'q';	  // default character to print
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
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

	// try something weird
	bogus();

	// should not have come back here!
	usprint( buf, "!!!!! %c returned from bogus syscall!?!?!\n", ch );
	cwrites( buf );

	exit( 1 );

	return( 42 );  // shut the compiler up!
}
#endif
