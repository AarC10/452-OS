/**
** @file	user.c
**
** @author	CSCI-452 class of 20245
**
** @brief	User-level code manipulation routines
**
** This is a MUCH SIMPLER user.c than the version that uses VM.
*/

#define	KERNEL_SRC

#include <common.h>

#include <bootstrap.h>
#include <user.h>
#include <kmem.h>

/*
** PUBLIC GLOBAL VARIABLES
*/

// need to know where the dummy startup routine is
extern void fake_exit(void);

/**
** Name:	stack_setup
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
		const char **args, bool_t sys ) {

#if TRACING_USER || TRACING_STACK
	cio_printf( "stksetup: pcb %08x, entry %08x, args %08x\n",
			(uint32_t) pcb, entry, (uint32_t) args );
#endif

	/*
	** First, we need to calculate the space we'll need for the argument
	** vector and strings.
	**
	** Keeping track of kernel vs. user VAs is tricky, so we'll use
	** a prefix on variable names: kv_* is a kernel virtual address;
	** uv_* is a user virtual address.
	**
	** We rely on the C standard, section 6.7.8, to clear these arrays:
	**
	**   "21 If there are fewer initializers in a brace-enclosed list
	**       than there are elements or members of an aggregate, or
	**       fewer characters in a string literal used to initialize an
	**       array of known size than there are elements in the array,
	**       the remainder of the aggregate shall be initialized
	**       implicitly the same as objects that have static storage
	**       duration."
	*/

	int argbytes = 0;                    // total length of arg strings
	int argc = 0;                        // number of argv entries
	const char *kv_strs[N_ARGS] = { 0 }; // converted user arg string pointers
	int strlengths[N_ARGS] = { 0 };      // length of each string
	int uv_offsets[N_ARGS] = { 0 };      // offsets into string buffer

	/*
	** IF the argument list given to us came from  user code, we need
	** to convert its address and the addresses it contains to kernel
	** VAs; otherwise, we can use them directly.
	*/
	const char **kv_args = args;

	while( kv_args[argc] != NULL ) {
		kv_strs[argc] = args[argc];
		strlengths[argc] = strlen( kv_strs[argc] ) + 1;
		// can't go over one page in size
		if( (argbytes + strlengths[argc]) > SZ_PAGE ) {
			// oops - ignore this and any others
			break;
		}
		argbytes += strlengths[argc];
		++argc;
	}

	// Round up the byte count to the next multiple of four.
	argbytes = (argbytes + 3) & MOD4_MASK;

	/*
	** We don't know where the argument strings actually live; they
	** could be inside the stack of a process that called exec(), so
	** we can't run the risk of overwriting them. Copy them into our
	** own address space.
	*/
	char argstrings[ argbytes ];
	CLEAR( argstrings );

	char *tmp = argstrings;
	for( int i = 0; i < argc; ++i ) {
		// do the copy
		strcpy( tmp, kv_strs[i] );
		// remember where this string begins in the buffer
		uv_offsets[i] = tmp - argstrings;
		// move to the next string position
		tmp += strlengths[i];
	}

	/*
	** The pages for the stack were cleared when they were allocated,
	** so we don't need to remember to do that.
	**
	** We reserve one longword at the bottom of the stack as a "buffer".
	**
	** The user code is not linked with a startup function, so it is
	** not "called" in the traditional sense. We need to simulate this
	** call by pushing a fake "return address" which points into a 
	** dummy function. That function's purpose is to handle a return
	** from the user code's main() function by calling exit().
	** 
	**      esp ->  context      <- context save area
	**              ...          <- context save area
	**              context      <- context save area
	**              fake_exit    <- return address for faked call to main()
	**              argc         <- argument count for main()
	**              argv         <- argv pointer for main()
	**               ...         <- argv array w/trailing NULL
	**               ...         <- argv character strings
	**                0          <- last word in stack
	**
	** Stack alignment rules for the SysV ABI i386 supplement dictate that
	** the 'argc' parameter must be at an address that is a multiple of 16;
	** see below for more information.
	**
	** Ultimately, this is what the bottom end of the stack will look like:
	**
	**         kvavptr
	** kvacptr   |
	**     |     |
	**     v     v
	**    argc  argv  av[0] av[1] etc  NULL       str0   str1    etc.
	**   [....][....][....][....] ... [0000] ... [......0......0.........]
	**           |    ^ |    |                    ^      ^
	**           |    | |    |                    |      |
	**           ------ |    ---------------------|-------
	**                  ---------------------------
	*/

#if TRACING_STACK
	cio_printf( "setup: stk %08x", (uint32_t) (pcb->stack) );
#endif
	/*
	** We need to find the last page of the user stack. Find the page
	** table for the 4MB user address space. The physical address of its
	** frame is in the first page directory entry. Extract that from the
	** entry and convert it into a virtual address for the kernel to use.
	*/
	// pointer to the first byte after the user stack
	uint32_t *kvptr = (uint32_t *)
		(((uint32_t)(pcb->stack)) + N_USTKPAGES * SZ_PAGE);

	// put the buffer longword into the stack
	*--kvptr = 0;
#if TRACING_STACK
	cio_printf( " put 0 @ %08x", (uint32_t) kvptr );
#endif

	/*
	** Move these pointers to where the string area will begin. We
	** will then back up to the next lower multiple-of-four address.
	*/
	uint32_t kvstrptr = ((uint32_t) kvptr) - argbytes;
	kvstrptr &= MOD4_MASK;

	// Copy over the argv strings
	memmove( (void *) kvstrptr, (void *) argstrings, argbytes );
#if TRACING_STACK
	cio_printf( " argstrs @ %08x: %d", (uint32_t) kvstrptr, argbytes );
	for( int i = 0; i < argbytes; ++i ) {
		cio_puts( " '" );
		put_char_or_code( *( (char *)kvstrptr + i ) );
		cio_putchar( '\'' );
	}
	cio_putchar( '\n' );
#endif

	/*
	** Next, we need to copy over the other data. Start by determining
	** where 'argc' should go.
	**
	** Stack alignment is controlled by the SysV ABI i386 supplement,
	** version 1.2 (June 23, 2016), which states in section 2.2.2:
	**
	**   "The end of the input argument area shall be aligned on a 16
	**   (32 or 64, if __m256 or __m512 is passed on stack) byte boundary.
	**   In other words, the value (%esp + 4) is always a multiple of 16
	**   (32 or 64) when control is transferred to the function entry
	**   point. The stack pointer, %esp, always points to the end of the
	**   latest allocated stack frame."
	**
	** Isn't technical documentation fun?  Ultimately, this means that
	** the first parameter to main() should be on the stack at an address
	** that is a multiple of 16. In our case, that is 'argc'.
	*/

	/*
	** The space needed for argc, argv, and the argv array itself is
	** argc + 3 words (argc+1 for the argv entries, plus one word each
	** for argc and argv).  We back up that much from the string area.
	*/

	int nwords = argc + 3;
	uint32_t *kvacptr = ((uint32_t *) kvstrptr) - nwords;

	// back these up to multiple-of-16 addresses for stack alignment
	kvacptr = (uint32_t *) ( ((uint32_t)kvacptr) & MOD16_MASK );

	// copy in 'argc'
	*kvacptr = argc;
#if TRACING_STACK
	cio_printf( "setup: argc '%d' @ %08x,", argc, (uint32_t) kvacptr );
#endif

	// 'argv' immediately follows 'argc', and 'argv[0]' immediately
	// follows 'argv'
	uint32_t *kvavptr = kvacptr + 2;
	*(kvavptr-1) = (uint32_t) kvavptr;
#if TRACING_STACK
	cio_printf( " argv '%08x' @ %08x,", (uint32_t) kvavptr,
			(uint32_t) (kvavptr - 1) );
#endif

	// now, the argv entries themselves
	for( int i = 0; i < argc; ++i ) {
		*kvavptr++ = (uint32_t) (kvstrptr + uv_offsets[i]);
#if TRACING_STACK
	cio_printf( " '%08x' @ %08x",
		(uint32_t) (kvstrptr + uv_offsets[i]),
		(uint32_t) (kvavptr-1) );
#endif
	}

	// and the trailing NULL
	*kvavptr = NULL;
#if TRACING_STACK
	cio_printf( " NULL @ %08x,", (uint32_t) kvavptr );
#endif

	// push the fake return address right above 'argc' on the stack
	*--kvacptr = (uint32_t) fake_exit;
#if TRACING_STACK
	cio_printf( " ret %08x @ %08x\n", (uint32_t) fake_exit,
			(uint32_t) kvacptr );
#endif

	/*
	** Almost done!
	**
	** Now we need to set up the initial context for the executing
	** process.
	**
	** When this process is dispatched, the context restore code will
	** pop all the saved context information off the stack, including
	** the saved EIP, CS, and EFLAGS. We set those fields up so that
	** the interrupt "returns" to the entry point of the process.
	*/

	// Locate the context save area on the stack by backup up one
	// "context" from where the argc value is saved
	context_t *kvctx = ((context_t *) kvacptr) - 1;

	/*
	** We cleared the entire stack earlier, so all the context
	** fields currently contain zeroes.  We now need to fill in
	** all the important fields.
	**
	** Note: we don't need to set the ESP value for the process,
	** as the 'popa' that restores the general registers doesn't
	** actually restore ESP from the context area - it leaves it
	** where it winds up.
	*/

	kvctx->eflags = DEFAULT_EFLAGS;    // IF enabled, IOPL 0
	kvctx->eip = entry;                // initial EIP
	kvctx->cs = GDT_CODE;              // segment registers
	kvctx->ss = GDT_STACK;
	kvctx->ds = kvctx->es = kvctx->fs = kvctx->gs = GDT_DATA;
#if TRACING_STACK
	ctx_dump( "stack_setup: new context", kvctx );
	delay( DELAY_2_SEC );
#endif

	/*
	** Return the new context pointer to the caller as a user
	** space virtual address.
	*/
	
	return kvctx;
}

/**
** Name:	user_init
**
** Initializes the user support module.
*/
void user_init( void ) {

#if TRACING_INIT
	cio_puts( " User" );
#endif 

	// really not much to do here any more....
}

/**
** Name:	user_cleanup
**
** "Unloads" a user program. Deallocates all memory frames and
** cleans up the VM structures.
**
** @param pcb   The PCB of the program to be unloaded
*/
void user_cleanup( pcb_t *pcb ) {

#if TRACING_USER
	cio_printf( "Uclean: %08x\n", (uint32_t) pcb );
#endif
	
	if( pcb == NULL ) {
		// should this be an error?
		return;
	}

	// free the stack pages
	pcb_stack_free( pcb->stack, pcb->stkpgs );
}
