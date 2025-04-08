/**
** @file	user.h
**
** @author	CSCI-452 class of 20245
**
** @brief	Declarations of user-level code management routines
**
** This is a MUCH SIMPLER user.c than the version that uses VM.
*/

#ifndef USER_H_
#define USER_H_

#include <common.h>

#include <procs.h>
#include <x86/arch.h>

// default value for EFLAGS in new processes
#define DEFAULT_EFLAGS     (EFL_MB1 | EFL_IF)

/*
** General (C and/or assembly) definitions
*/

#ifndef ASM_SRC

/*
** Start of C-only definitions
*/

/*
** Types
*/

/*
** Globals
*/

/*
** Prototypes
*/

/**
** Name:	user_init
**
** Initializes the user support module.
*/
void user_init( void );

/**
** Name:    stack_setup
**
** Set up the stack for a new process
**
** @param pcb    Pointer to the PCB for the process
** @param entry  Entry point for the new process
** @param args   Argument vector to be put in place
** @param sys    Is the argument vector from kernel code?
**
** @return A (user VA) pointer to the context_t on the stack, or NULL
*/
context_t *stack_setup( pcb_t *pcb, uint32_t entry,
        const char **args, bool_t sys );

/**
** Name:	user_cleanup
**
** "Unloads" a user program. Deallocates all memory frames and
** cleans up the VM structures.
**
** @param pcb   The PCB of the program to be cleaned up
*/
void user_cleanup( pcb_t *pcb );

#endif  /* !ASM_SRC */

#endif
