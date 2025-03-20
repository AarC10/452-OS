/**
** SCCS ID: @(#)support.h	2.3        1/22/25
**
** @file	support.h
**
** @author	K. Reek
** @author	Warren R. Carithers
**
** Declarations for functions provided in support.c, and
** some hardware characteristics needed in the initialization.
**
*/

#ifndef SUPPORT_H
#define SUPPORT_H

#ifndef ASM_SRC
/**
** panic
**
** Called when we find an unrecoverable error, this routine disables
** interrupts, prints a description of the error and then goes into a
** hard loop to prevent any further processing.
**
** @param reason  NUL-terminated message to be printed.
*/
void panic( char *reason );

/**
** init_interrupts
**
** (Re)initilizes the interrupt system. This includes initializing the
** IDT and the PIC. It is up to the user to enable processor interrupts
** when they're ready.
*/
void init_interrupts( void );

/*
** install_isr
**
** Installs a second-level handler for a specific interrupt. Returns the
** previously-installed handler for reinstallation (if desired).
**
** @param vector    the interrupt vector number
** @param handler	the second-stage ISR function to be called by the stub
**
** @return a pointer to the previously-registered ISR
*/
void (*install_isr( int vector,
		void ( *handler )(int,int) ) )( int, int );

/*
** Name:    delay
**
** Notes:  The parameter to this function is poorly named. For the
** first systems this was used on (dual 500MHz Intel P3 CPUs), it
** was reasonably accurate, but at today's processor speeds it's
** anyone's guess what the actual delay unit is.
*/
void delay( int tenths );
#endif  /* !ASM_SRC */

#endif
