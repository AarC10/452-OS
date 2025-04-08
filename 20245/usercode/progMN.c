#ifndef PROGMN_INC_C_
#define PROGMN_INC_C_
#include <common.h>

/**
** User function main #5:  exit, fork, exec, write
**
** Iterates spawning copies of progW (and possibly progZ), reporting
** their PIDs as it goes.
**
** Invoked as:  progMN  x  n  b
**	 where x is the ID character
**		   n is the iteration count
**		   b is the w&z boolean
*/

USERMAIN( progMN ) {
	char *name = argv[0] ? argv[0] : "nobody";
	int count = 5;	// default iteration count
	char ch = '5';	// default character to print
	int alsoZ = 0;	// also do progZ?
	char msgw[] = "*5w*";
	char msgz[] = "*5z*";
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
	case 4:	alsoZ = argv[3][0] == 't';
			// FALL THROUGH
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

	// update the extra message strings
	msgw[1] = msgz[1] = ch;

	// announce our presence
	write( CHAN_SIO, &ch, 1 );

	// set up the argument vector(s)

	// W:  15 iterations, 5-second sleep
	char *argsw[] = { "progW", "W", "15", "5", NULL };

	// Z:  15 iterations
	char *argsz[] = { "progZ", "Z", "15", NULL };

	for( int i = 0; i < count; ++i ) {
		write( CHAN_SIO, &ch, 1 );
		int whom = spawn( (uint32_t) progW, argsw	);
		if( whom < 1 ) {
			swrites( msgw );
		}
		if( alsoZ ) {
			whom = spawn( (uint32_t) progZ, argsz );
			if( whom < 1 ) {
				swrites( msgz );
			}
		}
	}

	exit( 0 );

	return( 42 );  // shut the compiler up!
}
#endif
