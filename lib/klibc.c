/*
** @file klibc.c
**
** @author  Warren R. Carithers
**
** Additional support functions for the kernel.
**
*/

#define KERNEL_SRC

#include <klib.h>
#include <cio.h>
#include <procs.h>
#include <support.h>

/**
** Name:    put_char_or_code( ch )
**
** Description: Prints a character on the console, unless it
** is a non-printing character, in which case its hex code
** is printed
**
** @param ch    The character to be printed
*/
void put_char_or_code( int ch ) {

    if( ch >= ' ' && ch < 0x7f ) {
        cio_putchar( ch );
    } else {
        cio_printf( "\\x%02x", ch );
    }
}

/**
** kpanic - kernel-level panic routine
**
** usage:  kpanic( msg )
**
** Prefix routine for panic() - can be expanded to do other things
** (e.g., printing a stack traceback)
**
** @param msg[in]  String containing a relevant message to be printed,
**			       or NULL
*/
void kpanic( const char *msg ) {

	cio_puts( "\n\n***** KERNEL PANIC *****\n\n" );
	cio_printf( "Msg: %s\n", msg ? msg : "(none)" );

	// dump a bunch of potentially useful information

	// EXAMPLES

	// dump the contents of the current PCB
	pcb_dump( "Current", current, true );

	// dump the contents of the process table
	ptable_dump( "Processes", false );

	// dump information about the queues
	pcb_queue_dump( "R", ready, true );
	pcb_queue_dump( "W", waiting, true );
	pcb_queue_dump( "S", sleeping, true );
	pcb_queue_dump( "Z", zombie, true );
	pcb_queue_dump( "I", sioread, true );

	// could dump other stuff here, too

	// could do a stack trace for the kernel, or for the current process

   panic( "KERNEL PANIC" );
}
