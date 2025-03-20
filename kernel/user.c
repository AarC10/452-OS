/**
** @file	user.c
**
** @author	CSCI-452 class of 20245
**
** @brief	User-level code manipulation routines
*/

#define	KERNEL_SRC

#include <common.h>

#include <bootstrap.h>
#include <elf.h>
#include <user.h>
#include <vm.h>

/*
** PRIVATE DEFINITIONS
*/

/*
** PRIVATE DATA TYPES
*/

/*
** PRIVATE GLOBAL VARIABLES
*/

/*
** PUBLIC GLOBAL VARIABLES
*/

/*
** Location of the "user blob" in memory.
**
** These variables are filled in by the code in startup.S using values
** passed to it from the bootstrap. 
**
** These are visible so that the startup code can find them.
*/
uint16_t blob_offset;      // byte offset from the segment base
uint16_t blob_segment;     // segment base address
uint16_t blob_sectors;     // number of 512-byte sectors it occupies

header_t *blob_header;    // filled in by the user_init routine
prog_t *prog_table;       // filled in by the user_init routine

/*
** PRIVATE FUNCTIONS
*/

/**
** read_phdrs(addr,phoff,phentsize,phnum)
**
** Parses the ELF program headers and each segment described into memory.
**
** @param hdr  Pointer to the program header
** @param pcb  Pointer to the PCB (and its PDE)
**
** @return status of the attempt:
**     SUCCESS         everything loaded correctly
**     E_LOAD_LIMIT    more than N_LOADABLE PT_LOAD sections
**     other           status returned from vm_add()
*/
static int read_phdrs( elfhdr_t *hdr, pcb_t *pcb ) {

	// sanity check
	assert1( hdr != NULL );
	assert2( pcb != NULL );

	// iterate through the program headers
	uint_t nhdrs = hdr->e_phnum;

	// pointer to the first header table entry
	elfproghdr_t *curr = (elfproghdr_t *) ((uint32_t) hdr + hdr->e_phoff);

	// process them all
	int loaded = 0;
	for( uint_t i = 0; i < nhdrs; ++i, ++curr ) {

		if( curr->p_type != PT_LOAD ) {
			// not loadable --> we'll skip it
			continue;
		}

		if( loaded >= N_LOADABLE ) {
			return E_LOAD_LIMIT;
		}

		// set a pointer to the bytes within the object file
		char *data = (char *) (((uint32_t)hdr) + curr->p_offset);

		// copy the pages into memory
		int stat = vm_add( pcb->pagedir, curr->p_flags & PF_W,
				(char *) curr->p_va, curr->p_memsz, data, curr->p_filesz );
		if( stat != SUCCESS ) {
			// TODO what else should we do here? check for memory leak?
			return stat;
		}

		// set the section table entry in the PCB
		pcb->sects[loaded].length = curr->p_memsz;
		pcb->sects[loaded].addr = curr->p_va;
		++loaded;
	}

	return SUCCESS;
}

/**
** Name:	stack_setup
**
** Set up the stack for a new process
**
** @param pcb    Pointer to the PCB for the process
** @param entry  Entry point for the new process
** @param args   Argument vector to be put in place
**
** @return A pointer to the context_t on the stack, or NULL
*/
static context_t *stack_setup( pcb_t *pcb, uint32_t entry, const char **args ) {

	/*
	** First, we need to count the space we'll need for the argument
	** vector and strings.
	*/

	int argbytes = 0;
	int argc = 0;

	while( args[argc] != NULL ) {
		int n = strlen( args[argc] ) + 1;
		// can't go over one page in size
		if( (argbytes + n) > SZ_PAGE ) {
			// oops - ignore this and any others
			break;
		}
		argbytes += n;
		++argc;
	}

	// Round up the byte count to the next multiple of four.
	argbytes = (argbytes + 3) & MOD4_MASK;

	/*
	** Allocate the arrays.  We are safe using dynamic arrays here
	** because we're using the OS stack, not the user stack.
	**
	** We want the argstrings and argv arrays to contain all zeroes.
	** The C standard states, in section 6.7.8, that
	**
	**   "21 If there are fewer initializers in a brace-enclosed list
	**       than there are elements or members of an aggregate, or
	**       fewer characters in a string literal used to initialize an
	**       array of known size than there are elements in the array,
	**       the remainder of the aggregate shall be initialized
	**       implicitly the same as objects that have static storage
	**       duration."
	**
	** Sadly, because we're using variable-sized arrays, we can't
	** rely on this, so we have to call memclr() instead. :-(  In
	** truth, it doesn't really cost us much more time, but it's an
	** annoyance.
	*/

	char argstrings[ argbytes ];
	char *argv[ argc + 1 ];

	CLEAR( argstrings );
	CLEAR( argv );

	// Next, duplicate the argument strings, and create pointers to
	// each one in our argv.
	char *tmp = argstrings;
	for( int i = 0; i < argc; ++i ) {
		int nb = strlen(args[i]) + 1; // bytes (incl. NUL) in this string
		strcpy( tmp, args[i] );   // add to our buffer
		argv[i] = tmp;              // remember where it was
		tmp += nb;                  // move on
	}

	// trailing NULL pointer
	argv[argc] = NULL;

	/*
	** The pages for the stack were cleared when they were allocated,
	** so we don't need to remember to do that.
	**
	** We reserve one longword at the bottom of the stack to hold a
	** pointer to where argv is on the stack.
	**
	** The user code was linked with a startup function that defines
	** the entry point (_start), calls main(), and then calls exit()
	** if main() returns. We need to set up the stack this way:
	** 
	**      esp ->  context      <- context save area
	**              ...          <- context save area
	**              context      <- context save area
	**              entry_pt     <- return address for the ISR
	**              argc         <- argument count for main()
	**         /->  argv         <- argv pointer for main()
	**         |     ...         <- argv array w/trailing NULL
	**         |     ...         <- argv character strings
	**         \--- ptr          <- last word in stack
	**
	** Stack alignment rules for the SysV ABI i386 supplement dictate that
	** the 'argc' parameter must be at an address that is a multiple of 16;
	** see below for more information.
	*/

	// Pointer to the last word in stack. We get this from the 
	// VM hierarchy. Get the PDE entry for the user address space.
	pde_t stack_pde = pcb->pagedir[USER_PDE];

	// The PDE entry points to the PT, which is an array of PTE. The last
	// two entries are for the stack; pull out the last one.
	pte_t stack_pte = ((pte_t *)(stack_pde & MOD4K_MASK))[USER_STK_PTE2];

	// OK, now we have the PTE. The frame address of the last page is
	// in this PTE. Find the address immediately after that.
	uint32_t *ptr = (uint32_t *)
		((uint32_t)(stack_pte & MOD4K_MASK) + SZ_PAGE);

	// Pointer to where the arg strings should be filled in.
	char *strings = (char *) ( (uint32_t) ptr - argbytes );

	// back the pointer up to the nearest word boundary; because we're
	// moving toward location 0, the nearest word boundary is just the
	// next smaller address whose low-order two bits are zeroes
	strings = (char *) ((uint32_t) strings & MOD4_MASK);

	// Copy over the argv strings.
	memcpy( (void *)strings, argstrings, argbytes );

	/*
	** Next, we need to copy over the argv pointers.  Start by
	** determining where 'argc' should go.
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
	** that is a multiple of 16.
	**
	** The space needed for argc, argv, and the argv array itself is
	** argc + 3 words (argc+1 for the argv entries, plus one word each
	** for argc and argv).  We back up that much from 'strings'.
	*/

	int nwords = argc + 3;
	uint32_t *acptr = ((uint32_t *) strings) - nwords;

	/*
	** Next, back up until we're at a multiple-of-16 address. Because we
	** are moving to a lower address, its upper 28 bits are identical to
	** the address we currently have, so we can do this with a bitwise
	** AND to just turn off the lower four bits.
	*/

	acptr = (uint32_t *) ( ((uint32_t)acptr) & MOD16_MASK );

	// copy in 'argc'
	*acptr = argc;

	// next, 'argv', which follows 'argc'; 'argv' points to the
	// word that follows it in the stack
	uint32_t *avptr = acptr + 2;
	*(acptr+1) = (uint32_t) avptr;

	/*
	** Next, we copy in all argc+1 pointers.
	*/

	// Adjust and copy the string pointers.
	for( int i = 0; i <= argc; ++i ) {
		if( argv[i] != NULL ) {
			// an actual pointer - adjust it and copy it in
			*avptr = (uint32_t) strings;
			// skip to the next entry in the array
			strings += strlen(argv[i]) + 1;
		} else {
			// end of the line!
			*avptr = NULL;
		}
		++avptr;
	}

	/*
	** Now, we need to set up the initial context for the executing
	** process.
	**
	** When this process is dispatched, the context restore code will
	** pop all the saved context information off the stack, including
	** the saved EIP, CS, and EFLAGS. We set those fields up so that
	** the interrupt "returns" to the entry point of the process.
	*/

	// Locate the context save area on the stack.
	context_t *ctx = ((context_t *) avptr) - 1;

	/*
	** We cleared the entire stack earlier, so all the context
	** fields currently contain zeroes.  We now need to fill in
	** all the important fields.
	*/

	ctx->eflags = DEFAULT_EFLAGS;    // IE enabled, PPL 0
	ctx->eip = entry;                // initial EIP
	ctx->cs = GDT_CODE;              // segment registers
	ctx->ss = GDT_STACK;
	ctx->ds = ctx->es = ctx->fs = ctx->gs = GDT_DATA;

	/*
	** Return the new context pointer to the caller.  It will be our
	** caller's responsibility to schedule this process.
	*/
	
	return( ctx );
}

/*
** PUBLIC FUNCTIONS
*/

/**
** Name:	user_init
**
** Initializes the user support module.
*/
void user_init( void ) {

#if TRACING_INIT
	cio_puts( " User" );
#endif 

	// calculate the location of the user blob
	if( blob_sectors > 0 ) {

		// calculate the "protected mode" address of the header
		blob_header = (header_t *)
			( (((uint_t)blob_segment) << 4) + ((uint_t)blob_offset) );

		// the program table immediate follows the blob header
		prog_table = (prog_t *) (blob_header + 1);

	} else {
		// too bad, so sad!
		blob_header = NULL;
		prog_table = NULL;
	}
}

/**
** Name:	user_locate
**
** Locates a user program in the user code archive.
**
** @param what   The ID of the user program to find
**
** @return a pointer to the code archive, or NULL
*/
void *user_locate( uint_t what ) {
	
	// no programs if there is no blob!
	if( blob_header == NULL ) {
		return NULL;
	}

	// make sure this is a reasonable program to request
	if( what >= blob_header->num ) {
		// no such program!
		return NULL;
	}

	// find the entry in the program table
	prog_t *prog = &prog_table[what];

	// if there are no bytes, it's useless
	if( prog->size < 1 ) {
		return NULL;
	}

	// calculate the start of the ELF file
	return ((void *) blob_header) + prog->offset;
}

/**
** Name:    user_duplicate
**
** Duplicates the memory setup for an existing process.
**
** @param new   The PCB for the new copy of the program
** @param old   The PCB for the existing the program
**
** @return the status of the duplicate attempt
*/
int user_duplicate( pcb_t *new, pcb_t *old ) {

	// We need to do a recursive duplication of the process address
	// space of the current process. First, we create a new user
	// page directory. Next, we'll duplicate the USER_PDE page
	// table. Finally, we'll go through that table and duplicate
	// all the frames.

	// create the initial VM hierarchy
	pde_t *pdir = vm_mkuvm();
	if( pdir == NULL ) {
		return E_NO_MEMORY;
	}
	new->pagedir = pdir;

	// next, add a USER_PDE page table that's a duplicate of the
	// current process' page table
	if( !vm_uvmdup(old->pagedir,new->pagedir) ) {
		// check for memory leak?
		return E_NO_MEMORY;
	}

	// now, iterate through the entries, replacing the frame
	// numbers with duplicate frames
	//
	// NOTE: we only deal with pdir[0] here, as we are limiting
	// the user address space to the first 4MB
	pte_t *pt = (pte_t *) (pdir[USER_PDE]);

	for( int i = 0; i < N_PTE; ++i ) {

		// if this entry is present,
		if( IS_PRESENT(*pt) ) {

			// duplicate the page
			void *tmp = vm_pagedup( (void *) (*pt & FRAME_MASK) );
			// replace the old frame number with the new one
			*pt = (pte_t) (((uint32_t)tmp) | (*pt & PERM_MASK));

		} else {

			*pt = 0;

		}
		++pt;
	}

	return SUCCESS;
}

/**
** Name:	user_load
**
** Loads a user program from the user code archive into memory.
** Allocates all needed frames and sets up the VM tables.
**
** @param prog   A pointer to the program ELF file in memory
** @param pcb    The PCB for the program being loaded
** @param args   The argument vector for the program
**
** @return the status of the load attempt
*/
int user_load( void *prog, pcb_t *pcb, const char **args ) {

	// NULL pointers are bad!
	assert1( prog != NULL );
	assert1( pcb != NULL );
	assert1( args != NULL );

	// verify the ELF header
	elfhdr_t *hdr = (elfhdr_t *) prog;

	if( ((elfhdr_t *)prog)->e_ident.f.magic != ELF_MAGIC ) {
		return E_BAD_PARAM;
	}

	// allocate a page directory
	pcb->pagedir = vm_mkuvm();
	if( pcb->pagedir == NULL ) {
		return E_NO_MEMORY;
	}

	// read all the program headers
	int stat = read_phdrs( hdr, pcb );
	if( stat != SUCCESS ) {
		// TODO figure out a better way to deal with this
		PANIC( 0, "user_load: phdr read failed" );
	}

	// next, set up the runtime stack - just like setting up loadable
	// sections, except nothing to copy
	stat = vm_add( pcb->pagedir, true, (void *) USER_STACK,
			SZ_USTACK, NULL, 0 );
	if( stat != SUCCESS ) {
		// TODO yadda yadda...
		PANIC( 0, "user_load: vm_add failed" );
	}

	// set up the command-line arguments
	pcb->context = stack_setup( pcb, hdr->e_entry, args );

	return SUCCESS;
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
	
	if( pcb == NULL ) {
		// should this be an error?
		return;
	}

	vm_free( pcb->pagedir );
	pcb->pagedir = NULL;
}
