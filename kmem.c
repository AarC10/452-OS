/**
** @file kmem.c
**
** @author Warren R. Carithers
** @author Kenneth Reek
** @author 4003-506 class of 20013
**
** @brief	Functions to perform dynamic memory allocation in the OS.
**      NOTE: these should NOT be called by user processes!
**
**
** This allocator functions as a simple "slab" allocator; it allows
** allocation of either 4096-byte ("page") or 1024-byte ("slice")
** chunks of memory from the free pool.  The free pool is initialized
** using the memory map provided by the BIOS during the boot sequence,
** and contains a series of blocks which are multiples of 4K bytes and
** which are aligned at 4K boundaries; they are held in the free list
** in order by base address.
**
** The "page" allocator allows allocation of one or more 4K blocks
** at a time.  Requests are made for a specific number of 4K pages;
** the allocator locates the first free list entry that contains at
** least the requested amount of space.  If that entry is the exact
** size requested, it is unlinked and returned; otherwise, the entry
** is split into a chunk of the requested size and the remainder.
** The chunk is returned, and the remainder replaces the original
** block in the free list.  On deallocation, the block is inserted
** at the appropriate place in the free list, and physically adjacent
** blocks are coalesced into single, larger blocks.  If a multi-page
** block is allocated, it should be deallocated one page at a time,
** because there is no record of the size of the original allocation -
** all we know is that it is N*4K bytes in length, so it's up to the
** requesting code to figure this out.
**
** The "slice" allocator operates by taking blocks from the "page"
** allocator and splitting them into four 1K slices, which it then
** manages.  Requests are made for slices one at a time.  If the free
** list contains an available slice, it is unlinked and returned;
** otherwise, a page is requested from the page allocator, split into
** slices, and the slices are added to the free list, after which the
** first one is returned.  The slice free list is a simple linked list
** of these 1K blocks; because they are all the same size, no ordering
** is done on the free list, and no coalescing is performed.
**
*/

#define KERNEL_SRC

// compatibility definitions; also includes common.h
#include <compat.h>

// all other framework includes are next
#include <lib.h>

#include <x86/arch.h>
#include <x86/bios.h>
#include <bootstrap.h>
#include <cio.h>

#include <kmem.h>

/*
** PRIVATE DEFINITIONS
*/

// combination tracing tests
#define ANY_KMEM       (TRACING_KMEM|TRACING_KMEM_INIT|TRACING_KMEM_FREELIST)
#define KMEM_OR_INIT   (TRACING_KMEM|TRACING_KMEM_INIT)

// parameters related to word and block sizes

#define WORD_SIZE           sizeof(int)
#define LOG2_OF_WORD_SIZE   2

#define LOG2_OF_PAGE_SIZE   12

#define LOG2_OF_SLICE_SIZE  10

// converters:  pages to bytes, bytes to pages

#define P2B(x)   ((x) << LOG2_OF_PAGE_SIZE)
#define B2P(x)   ((x) >> LOG2_OF_PAGE_SIZE)

/*
** Name:    adjacent
**
** Arguments:   addresses of two blocks
**
** Description: Determines whether the second block immediately
**      follows the first one.
*/
#define adjacent(first,second)  \
	( (void *) (first) + P2B((first)->pages) == (void *) (second) )

/*
** PRIVATE DATA TYPES
*/

/*
** This structure keeps track of a single block of memory.  All blocks
** are multiples of the base size (currently, 4KB).
*/

typedef struct blkinfo_s {
	uint32_t pages;           // length of this block, in pages
	struct   blkinfo_s *next; // pointer to the next free block
} Blockinfo;

/*
** Memory region information returned by the BIOS
**
** This data consists of a 32-bit integer followed
** by an array of region descriptor structures.
*/

// a handy union for playing with 64-bit addresses
typedef union b64_u {
	uint32_t part[2];
	uint64_t all;
} b64_t;

// the halves of a 64-bit address
#define LOW     part[0]
#define HIGH    part[1]

// memory region descriptor
typedef struct memregion_s {
	b64_t    base;    // base address
	b64_t    length;  // region length
	uint32_t type;    // type of region
	uint32_t acpi;    // ACPI 3.0 info
} ATTR_PACKED region_t;

/*
** Region types
*/

#define REGION_USABLE       1
#define REGION_RESERVED     2
#define REGION_ACPI_RECL    3
#define REGION_ACPI_NVS     4
#define REGION_BAD          5

/*
** ACPI 3.0 bit fields
*/

#define REGION_IGNORE       0x01
#define REGION_NONVOL       0x02

/*
** 32-bit and 64-bit address values as 64-bit literals
*/

#define ADDR_BIT_32     0x0000000100000000LL
#define ADDR_LOW_HALF   0x00000000ffffffffLL
#define ADDR_HIGH_HALR  0xffffffff00000000LL

#define ADDR_32_MAX     ADDR_LOW_HALF
#define ADDR_64_FIRST   ADDR_BIT_32

/*
** PRIVATE GLOBAL VARIABLES
*/

// freespace pools
static Blockinfo *free_pages;
static Blockinfo *free_slices;

// block counts
static uint32_t n_pages;
static uint32_t n_slices;

// initialization status
static int km_initialized = 0;

/*
** IMPORTED GLOBAL VARIABLES
*/

extern char _end[];    // end of the BSS section - provided by the linker

/*
** FUNCTIONS
*/

/*
** FREE LIST MANAGEMENT
*/

/**
** Name:    add_block
**
** Add a block to the free list
**
** @param base   Base address of the block
** @param length Block length, in bytes
*/
static void add_block( uint32_t base, uint32_t length ) {

	// don't add it if it isn't at least 4K
	if( length < SZ_PAGE ) {
		return;
	}

#if ANY_KMEM
	cio_printf( "  add(%08x,%08x): ", base, length );
#endif

	// only want to add multiples of 4K; check the lower bits
	if( (length & 0xfff) != 0 ) {
		// round it down to 4K
		length &= 0xfffff000;
	}

#if ANY_KMEM
	cio_printf( " --> base %08x length %08x", base, length );
#endif

	// create the "block"

	Blockinfo *block = (Blockinfo *) base;
	block->pages = B2P(length);
	block->next = NULL;

#if ANY_KMEM
	cio_printf( " pages %d\n", block->pages );
#endif

	/*
	** We maintain the free list in order by address, to simplify
	** coalescing adjacent free blocks.
	**
	** Handle the easiest case first.
	*/

	if( free_pages == NULL ) {
		free_pages = block;
		n_pages = block->pages;
		return;
	}

	/*
	** Unfortunately, it's not always that easy....
	**
	** Find the correct insertion spot.
	*/

	Blockinfo *prev, *curr;

	prev = NULL;
	curr = free_pages;

	while( curr && curr < block ) {
		prev = curr;
		curr = curr->next;
	}

	// the new block always points to its successor
	block->next = curr;

	/*
	** If prev is NULL, we're adding at the front; otherwise,
	** we're adding after some other entry (middle or end).
	*/

	if( prev == NULL ) {
		// sanity check - both pointers can't be NULL
		assert( curr );
		// add at the beginning
		free_pages = block;
	} else {
		// inserting in the middle or at the end
		prev->next = block;
	}

	// bump the count of available pages
	n_pages += block->pages;
}

/**
** Name:    km_init
**
** Find what memory is present on the system and
** construct the list of free memory blocks.
**
** Dependencies:
**    Must be called before any other init routine that uses
**    dynamic storage is called.
*/
void km_init( void ) {
	int32_t entries;
	region_t *region;

#if TRACING_INIT
	// announce that we're starting initialization
	cio_puts( " Kmem" );
#endif

	// initially, nothing in the free lists
	free_slices = NULL;
	free_pages = NULL;
	n_pages = n_slices = 0;
	km_initialized = 0;

	// get the list length
	entries = *((int32_t *) MMAP_ADDR);

#if KMEM_OR_INIT
	cio_printf( "\nKmem: %d regions\n", entries );
#endif

	// if there are no entries, we have nothing to do!
	if( entries < 1 ) {  // note: entries == -1 could occur!
		return;
	}

	// iterate through the entries, adding things to the freelist

	region = ((region_t *) (MMAP_ADDR + 4));

	for( int i = 0; i < entries; ++i, ++region ) {

#if KMEM_OR_INIT
		// report this region
		cio_printf( "%3d: ", i );
		cio_printf( " B %08x%08x",
				region->base.HIGH, region->base.LOW );
		cio_printf( " L %08x%08x",
				region->length.HIGH, region->length.LOW );
		cio_printf( " T %08x A %08x",
				region->type, region->acpi );
#endif

		/*
		** Determine whether or not we should ignore this region.
		**
		** We ignore regions for several reasons:
		**
		**  ACPI indicates it should be ignored
		**  ACPI indicates it's non-volatile memory
		**  Region type isn't "usable"
		**  Region is above the 4GB address limit
		**
		** Currently, only "normal" (type 1) regions are considered
		** "usable" for our purposes.  We could potentially expand
		** this to include ACPI "reclaimable" memory.
		*/

		// first, check the ACPI one-bit flags

		if( ((region->acpi) & REGION_IGNORE) == 0 ) {
#if KMEM_OR_INIT
			cio_puts( " IGN\n" );
#endif
			continue;
		}

		if( ((region->acpi) & REGION_NONVOL) != 0 ) {
#if KMEM_OR_INIT
			cio_puts( " NVOL\n" );
#endif
			continue;  // we'll ignore this, too
		}

		// next, the region type

		if( (region->type) != REGION_USABLE ) {
#if KMEM_OR_INIT
			cio_puts( " RCLM\n" );
#endif
			continue;  // we won't attempt to reclaim ACPI memory (yet)
		}

		/*
		** We have a "normal" memory region. We need to verify
		** that it's within our constraints.
		**
		** We ignore anything below our KM_LOW_CUTOFF address. (In theory,
		** we should be able to re-use much of that space; in practice,
		** this is safer.) We won't add anything to the free list if it is:
		**
		**    * below our KM_LOW_CUTOFF value
		**    * above out KM_HIGH_CUTOFF value.
		**
		** For blocks which straddle one of those limits, we will
		** split it, and only use the portion that's within those
		** bounds.
		*/

		// grab the two 64-bit values to simplify things
		uint64_t base   = region->base.all;
		uint64_t length = region->length.all;
		uint64_t endpt  = base + length;

		// see if it's above our arbitrary high cutoff point
		if( base >= KM_HIGH_CUTOFF || endpt >= KM_HIGH_CUTOFF ) {

			// is the whole thing too high, or just part?
			if( base > KM_HIGH_CUTOFF ) {
				// it's all above the cutoff!
#if KMEM_OR_INIT
				cio_puts( " HIGH\n" );
#endif
				continue;
			}

			// some of it is usable - fix the end point
			endpt = KM_HIGH_CUTOFF;
		}

		// see if it's below our low cutoff point
		if( base < KM_LOW_CUTOFF || endpt < KM_LOW_CUTOFF ) {

			// is the whole thing too low, or just part?
			if( endpt < KM_LOW_CUTOFF ) {
				// it's all below the cutoff!
#if KMEM_OR_INIT
				cio_puts( " LOW\n" );
#endif
				continue;
			}

			// some of it is usable - fix the starting point
			base = KM_LOW_CUTOFF;
		}

		// recalculate the length
		length = endpt - base;

#if KMEM_OR_INIT
		cio_puts( " OK\n" );
#endif

		// we survived the gauntlet - add the new block

		uint32_t b32 = base   & ADDR_LOW_HALF;
		uint32_t l32 = length & ADDR_LOW_HALF;

		add_block( b32, l32 );
	}

	// record the initialization
	km_initialized = 1;
#if KMEM_OR_INIT
	delay( DELAY_1_SEC );
#endif
}

/**
** Name:    km_dump
**
** Dump the current contents of the free list to the console
*/
void km_dump( void ) {
	Blockinfo *block;

	cio_printf( "&free_pages=%08x, &free_slices %08x, %u pages, %u slices\n",
			(uint32_t) &free_pages, (uint32_t) &free_slices,
			n_pages, n_slices );

	for( block = free_pages; block != NULL; block = block->next ) {
		cio_printf(
			"block @ 0x%08x 0x%08x pages (ends at 0x%08x) next @ 0x%08x\n",
				block, block->pages, P2B(block->pages) + (uint32_t) block,
				block->next );
	}

	for( block = free_slices; block != NULL; block = block->next ) {
		cio_printf(
			"block @ 0x%08x 0x%08x slices (ends at 0x%08x) next @ 0x%08x\n",
				block, block->pages, P2B(block->pages) + (uint32_t) block,
				block->next );
	}

}

/*
** PAGE MANAGEMENT
*/

/**
** Name:    km_page_alloc
**
** Allocate a page of memory from the free list.
**
** @param count  Number of contiguous pages desired
**
** @return a pointer to the beginning of the first allocated page,
**         or NULL if no memory is available
*/
void *km_page_alloc( unsigned int count ) {

	assert( km_initialized );

	// make sure we actually need to do something!
	if( count < 1 ) {
		return( NULL );
	}

	/*
	** Look for the first entry that is large enough.
	*/

	// pointer to the current block
	Blockinfo *block = free_pages;

	// pointer to where the pointer to the current block is
	Blockinfo **pointer = &free_pages;

	while( block != NULL && block->pages < count ){
		pointer = &block->next;
		block = *pointer;
	}

	// did we find a big enough block?
	if( block == NULL ){
		// nope!
		return( NULL );
	}

	// found one!  check the length

	if( block->pages == count ) {

		// exactly the right size - unlink it from the list

		*pointer = block->next;

	} else {

		// bigger than we need - carve the amount we need off
		// the beginning of this block

		// remember where this chunk begins
		Blockinfo *chunk = block;

		// how much space will be left over?
		int excess = block->pages - count;

		// find the start of the new fragment
		Blockinfo *fragment = (Blockinfo *) ( (uint8_t *) block + P2B(count) );

		// set the length and link for the new fragment
		fragment->pages = excess;
		fragment->next  = block->next;

		// replace this chunk with the fragment
		*pointer = fragment;

		// return this chunk
		block = chunk;
	}

	// fix the count of available pages
	n_pages -= count;;

	return( block );
}

/**
** Name:    km_page_free
**
** Returns a single page to the list of available blocks,
** combining it with adjacent blocks if they're present.
**
** CRITICAL NOTE:  multi-page blocks must be freed one page
** at a time OR freed using km_page_free_multi()!
**
** @param block   Pointer to the page to be returned to the free list
*/
void km_page_free( void *block ) {

	/*
	** Don't do anything if the address is NULL.
	*/
	if( block == NULL ){
		return;
	}

	km_page_free_multi( block, 1 );
}

/**
** Name:    km_page_free_multi
**
** Returns a memory block to the list of available blocks, combining
** it with adjacent blocks if they're present. Unlike km_page_free(),
** accepts a pointer to a multi-page block of memory.
**
** @param block   Pointer to the block to be returned to the free list
** @param count   Number of pages in the block
*/
void km_page_free_multi( void *block, uint32_t count ) {
	Blockinfo *used;
	Blockinfo *prev;
	Blockinfo *curr;

	assert( km_initialized );

	/*
	** Don't do anything if the address is NULL.
	*/
	if( block == NULL ){
		return;
	}

	used = (Blockinfo *) block;
	used->pages = count;

	/*
	** Advance through the list until current and previous
	** straddle the place where the new block should be inserted.
	*/
	prev = NULL;
	curr = free_pages;

	while( curr != NULL && curr < used ){
		prev = curr;
		curr = curr->next;
	}

	/*
	** At this point, we have the following list structure:
	**
	**   ....    BLOCK       BLOCK      ....
	**          (*prev)  ^  (*curr)
	**                   |
	**                "used" goes here
	**
	** We may need to merge the inserted block with either its
	** predecessor or its successor (or both).
	*/

	/*
	** If this is not the first block in the resulting list,
	** we may need to merge it with its predecessor.
	*/
	if( prev != NULL ){

		// There is a predecessor.  Check to see if we need to merge.
		if( adjacent( prev, used ) ){

			// yes - merge them
			prev->pages += used->pages;

			// the predecessor becomes the "newly inserted" block,
			// because we still need to check to see if we should
			// merge with the successor
			used = prev;

		} else {

			// Not adjacent - just insert the new block
			// between the predecessor and the successor.
			used->next = prev->next;
			prev->next = used;

		}

	} else {

		// Yes, it is first.  Update the list pointer to insert it.
		used->next = free_pages;
		free_pages = used;

	}

	/*
	** If this is not the last block in the resulting list,
	** we may (also) need to merge it with its successor.
	*/
	if( curr != NULL ){

		// No.  Check to see if it should be merged with the successor.
		if( adjacent( used, curr ) ){

			// Yes, combine them.
			used->next = curr->next;
			used->pages += curr->pages;

		}
	}

	// more in the pool
	n_pages += count;
}

/*
** SLICE MANAGEMENT
*/

/*
** Slices are 1024-byte fragments from pages.  We maintain a free list of
** slices for those parts of the OS which don't need full 4096-byte chunks
** of space (e.g., the QNode and Queue allocators).
*/

/**
** Name:        carve_slices
**
** Allocate a page and split it into four slices;  If no
**              memory is available, we panic.
*/
static void carve_slices( void ) {
	void *page;

	// get a page
	page = km_page_alloc( 1 );

	// allocation failure is a show-stopping problem
	assert( page );

	// we have the page; create the four slices from it
	uint8_t *ptr = (uint8_t *) page;
	for( int i = 0; i < 4; ++i ) {
		km_slice_free( (void *) ptr );
		ptr += SZ_SLICE;
		++n_slices;
	}
}

/**
** Name:        km_slice_alloc
**
** Dynamically allocates a slice (1/4 of a page).  If no
** memory is available, we panic.
**
** @return a pointer to the allocated slice
*/
void *km_slice_alloc( void ) {
	Blockinfo *slice;

	assert( km_initialized );

	// if we are out of slices, create a few more
	if( free_slices == NULL ) {
		carve_slices();
	}

	// take the first one from the free list
	slice = free_slices;
	assert( slice != NULL );
	--n_slices;

	// unlink it
	free_slices = slice->next;

	// make it nice and shiny for the caller
	memclr( (void *) slice, SZ_SLICE );

	return( slice );
}

/**
** Name:        km_slice_free
**
** Returns a slice to the list of available slices.
**
** We make no attempt to merge slices, as they are independent
** blocks of memory (unlike pages).
**
** @param block  Pointer to the slice (1/4 page) to be freed
*/
void km_slice_free( void *block ) {
	Blockinfo *slice = (Blockinfo *) block;

	assert( km_initialized );

	// just add it to the front of the free list
	slice->pages = SZ_SLICE;
	slice->next = free_slices;
	free_slices = slice;
	++n_slices;
}
