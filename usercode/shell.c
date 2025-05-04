#ifndef USHELL_INC_C_
#define USHELL_INC_C_
#include <common.h>

// should we keep going?
static bool_t time_to_stop = false;

// number of spawned but uncollected children
static int children = 0;

/*
** For the test programs in the baseline system, command-line arguments
** follow these rules. The first two entries are as follows:
**
**	argv[0] the name used to "invoke" this process
**	argv[1] the "character to print" (identifies the process)
**
** Most user programs have one or more additional arguments.
**
** See the comment at the beginning of each user-code source file for
** information on the argument list that code expects.
*/

/*
** The spawn table contains entries for processes that are started
** by the shell.
*/
static proc_t sh_spawn_table[] = {

	// Users A-C each run ProgABC, which loops printing its character
#if defined(SPAWN_A)
	PROCENT( progABC, PRIO_STD, "A", "userA", "A", "30" ),
#endif
#if defined(SPAWN_B)
	PROCENT( progABC, PRIO_STD, "B", "userB", "B", "30" ),
#endif
#if defined(SPAWN_C)
	PROCENT( progABC, PRIO_STD, "C", "userC", "C", "30" ),
#endif

	// Users D and E run progDE, which is like progABC but doesn't exit()
#if defined(SPAWN_D)
	PROCENT( progDE, PRIO_STD, "D", "userD", "D", "20" ),
#endif
#if defined(SPAWN_E)
	PROCENT( progDE, PRIO_STD, "E", "userE", "E", "20" ),
#endif

	// Users F and G run progFG, which sleeps between write() calls
#if defined(SPAWN_F)
	PROCENT( progFG, PRIO_STD, "F", "userF", "F", "20" ),
#endif
#if defined(SPAWN_G)
	PROCENT( progFG, PRIO_STD, "G", "userG", "G", "10" ),
#endif

	// User H tests reparenting of orphaned children
#if defined(SPAWN_H)
	PROCENT( progH, PRIO_STD, "H", "userH", "H", "4" ),
#endif

	// User I spawns several children, kills one, and waits for all
#if defined(SPAWN_I)
	PROCENT( progI, PRIO_STD, "I", "userI", "I" ),
#endif

	// User J tries to spawn 2 * N_PROCS children
#if defined(SPAWN_J)
	PROCENT( progJ, PRIO_STD, "J", "userJ", "J" ),
#endif

	// Users K and L iterate spawning userX and sleeping
#if defined(SPAWN_K)
	PROCENT( progKL, PRIO_STD, "K", "userK", "K", "8" ),
#endif
#if defined(SPAWN_L)
	PROCENT( progKL, PRIO_STD, "L", "userL", "L", "5" ),
#endif

	// Users M and N spawn copies of userW and userZ via progMN
#if defined(SPAWN_M)
	PROCENT( progMN, PRIO_STD, "M", "userM", "M", "5", "f" ),
#endif
#if defined(SPAWN_N)
	PROCENT( progMN, PRIO_STD, "N", "userN", "N", "5", "t" ),
#endif

	// There is no user O

	// User P iterates, reporting system time and stats, and sleeping
#if defined(SPAWN_P)
	PROCENT( progP, PRIO_STD, "P", "userP", "P", "3", "2" ),
#endif

	// User Q tries to execute a bad system call
#if defined(SPAWN_Q)
	PROCENT( progQ, PRIO_STD, "Q", "userQ", "Q" ),
#endif

	// User R reports its PID, PPID, and sequence number; it
	// calls fork() but not exec(), with each child getting the
	// next sequence number, to a total of five copies
#if defined(SPAWN_R)
	PROCENT( progR, PRIO_STD, "R", "userR", "R", "20", "1" ),
#endif

	// User S loops forever, sleeping 13 sec. on each iteration
#if defined(SPAWN_S)
	PROCENT( progS, PRIO_STD, "S", "userS", "S", "13" ),
#endif

	// Users T-V run progTUV(); they spawn copies of userW
	//	 User T waits for any child
	//	 User U waits for each child by PID
	//	 User V kills each child
#if defined(SPAWN_T)
	PROCENT( progTUV, PRIO_STD, "T", "userT", "T", "6", "w" ),
#endif
#if defined(SPAWN_U)
	PROCENT( progTUV, PRIO_STD, "U", "userU", "U", "6", "W" ),
#endif
#if defined(SPAWN_V)
	PROCENT( progTUV, PRIO_STD, "V", "userV", "V", "6", "k" ),
#endif

	PROCENT(dmxTest, PRIO_STD, "W", "test"),

	// a dummy entry to use as a sentinel
	// { TBLEND }
	{ 0 }	// all fields are zeroes, including 'valid'

	// these processes are spawned by the ones above, and are never
	// spawned directly.

	// PROCENT( progW, PRIO_STD, "?", "userW", "W", "20", "3" ),
	// PROCENT( progX, PRIO_STD, "?", "userX", "X", "20" ),
	// PROCENT( progY, PRIO_STD, "?", "userY", "Y", "10" ),
	// PROCENT( progZ, PRIO_STD, "?", "userZ", "Z", "10" )
};

// static int sh_spawn_len = sizeof(sh_spawn_table) / sizeof(sh_spawn_table[0]);

/*
** usage function
*/
static void usage( void ) {
	swrites( "\nTests - run with '@x', where 'x' is one or more of:\n " );
	proc_t *p = sh_spawn_table;
	while( p->valid ) {
		swritech( ' ' );
		swritech( p->select[0] );
		++p;
	}
	swrites( "\nOther commands: @* (all), @h (help), @x (exit), @@ (dump)\n" );
}

/*
** run a program from the program table, or a builtin command
*/
static int run( char which ) {
	char buf[128];
	register proc_t *p;
	char lwhich = LCASE(which);

	if( lwhich == 'h' ) {

		// builtin "help" command
		usage();

	} else if( lwhich == '@' ) {

		cwrites( "Shell command table:\n" );
		p = sh_spawn_table;
		int i = 0;
		while( p->valid ) {
			usprint( buf, " %2d: 0x%08x '%s' pr %d %s pid %d",
					i, p->entry, p->select, p->prio,
					p->valid ? "V" : "!V", p->pid );
			cwrites( buf );
			int j = 0;
			while( j < N_ARGS && p->args[j] != NULL ) {
				usprint( buf, " %s", p->args[j] );
				cwrites( buf );
				++j;
			}
			cwrites( "\n" );
			++p;
			++i;
		}

	} else if( lwhich == 'x' ) {

		// builtin "exit" command
		time_to_stop = true;

	} else if( lwhich == '*' ) {

		// torture test! run everything!
		p = sh_spawn_table;
		while( p->valid ) {
			int status = spawn( p->entry, p->args );
			if( status > 0 ) {
				++children;
			}
			++p;
		}

	} else {

		// must be a single test; find and run it
		p = sh_spawn_table;
		while( p->valid ) {
			if( LCASE(p->select[0]) == lwhich ) {
				// found it!
				int status = spawn( p->entry, p->args );
				if( status > 0 ) {
					++children;
				}
				return status;
			}
			++p;
		}

		// uh-oh, made it through the table without finding the program
		usprint( buf, "shell: unknown cmd '%c'\n", which );
		swrites( buf );
		usage();
	}

	return 0;
}

/**
** edit - perform any command-line editing we need to do
**
** @param line   Input line buffer
** @param n      Number of valid bytes in the buffer
*/
static int edit( char line[], int n ) {
	char *ptr = line + n - 1;	// last char in buffer

	// strip the EOLN sequence
	while( n > 0 ) {
		if( *ptr == '\n' || *ptr == '\r' ) {
			--n;
		} else {
			break;
		}
		--ptr;
	}

	// add a trailing NUL byte
	if( n > 0 ) {
		line[n] = '\0';
	}

	return n;
}

/**
** readline - read an entire line of input from the SIO
**
** Reads character-by-character until a newline is read, then
** NUL-terminates the buffer.
**
** @param buf  Buffer to hold the line
** @param len  Size of the buffer (bytes)
**
** @return the number of bytes placed into the buffer, or -1 on error
*/
static int readline( char *buf, uint32_t len ) {

	// sanity check
	if( buf == NULL ) {
		return -1;
	}

	// need room for at least one character plus a NUL
	if( len < 2 ) {
		return 0;
	}

	// leave room for the NUL
	len -= 1;

	// read incrementally until we find the newline
	char *ptr = buf;
	int num = 0;
	while( len > 0 ) {

		// can accept up to 'len' more characters
		int n = read( CHAN_SIO, ptr, len );

		if( n < 0 ) {
			// problem!
			break;
		} else if( n == 0 ) {
			// pause for a bit
			sleep( SEC_TO_MS(1) );
			continue;
		}

		// reduce the remaining buffer size
		len -= n;

		// add these characters to our input total
		num += n;

		// find the newline
		while( n-- > 0 ) {
			if( *ptr++ == '\n' ) {
				// found it - reset 'len' so that we
				// also get out of the outer loop
				len = 0;
				break;
			}
		}
	}

	// NUL-terminate it
	*ptr = '\0';

	return num;
}

/**
** shell - extremely simple shell for spawning test programs
**
** Scheduled by _kshell() when the character 'u' is typed on
** the console keyboard.
*/
USERMAIN( shell ) {
	char line[128];

	// keep the compiler happy
	(void) argc;
	char *name = argv[0] ? argv[0] : "nobody";

	// report that we're up and running
	usprint( line, "%s is ready\n", name );
	swrites( line );

	// print a summary of the commands we'll accept
	usage();

	// loop forever
	while( !time_to_stop ) {
		char *ptr;

		// the shell reads one line from the keyboard, parses it,
		// and performs whatever command it requests.

		umemclr( (void *)line, sizeof(line) );

		swrites( "\n> " );
		int n = readline( line, sizeof(line) );
		
		// shortest valid command is "@?", so must have 3+ chars here
		if( n < 3 ) {
			// ignore it
			continue;
		}

		// edit it as needed; new shortest command is 2+ chars
		if( (n=edit(line,n)) < 2 ) {
			continue;
		}

		// find the '@'
		int i = 0;
		for( ptr = line; i < n; ++i, ++ptr ) {
			if( *ptr == '@' ) {
				break;
			}
		}

		// did we find an '@'?
		if( i < n ) {

			// yes; process any commands that follow it
			++ptr;

			for( ; *ptr != '\0'; ++ptr ) {
				char buf[128];
				int pid = run( *ptr );

				if( pid < 0 ) {
					// spawn() failed
					usprint( buf, "+++ %s spawn %c failed, code %d\n",
							name, *ptr, pid );
					cwrites( buf );
				}

				// should we end it all?
				if( time_to_stop ) {
					break;
				}
			} // for

			// now, wait for all the spawned children
			while( children > 0 ) {
				// wait for the child
				int32_t status;
				char buf[128];
				int whom = waitpid( 0, &status );

				// figure out the result
				if( whom == E_NO_CHILDREN ) {
					break;
				} else if( whom < 1 ) {
					usprint( buf, "%s: waitpid() returned %d\n", name, whom );
					swrites( buf );
				} else {
					--children;
					if( status != 0 ) {
						usprint( buf, "%s: PID %d exit status %d\n",
								name, whom, status );
						swrites( buf );
					}
				}
			}
		}  // if i < n
	}  // while

	cwrites( "!!! shell exited loop???\n" );
	exit( 1 );

	// yeah, yeah....
	return( 0 );
}
#endif
