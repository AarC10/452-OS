/**
** @file	listblob.c
**
** @author	Warren R. Carithers
**
** Examine a binary blob of ELF files.
*/
#define	_DEFAULT_SOURCE
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <elf.h>
#include <ctype.h>

/*
** Blob file organization
**
** The file begins with a four-byte magic number and a four-byte integer
** indicating the number of ELF files contained in the blob. This is
** followed by an array of 32-byte file entries, and then the contents
** of the ELF files in the order they appear in the program file table.
**
**		Bytes        Contents
**		-----        ----------------------------
**		0 - 3        File magic number ("BLB\0")
**      4 - 7        Number of ELF files in blob ("n")
**      8 - n*32+8   Program file table
**      n*32+9 - ?   ELF file contents
**
** Each program file table entry contains the following information:
**
** 		name         File name (up to 19 characters long)
**		offset       Byte offset to the ELF header for this file
**		size         Size of this ELF file, in bytes
**		flags        Flags related to this file
*/

// blob header
typedef struct header_s {
	char magic[4];
	uint32_t num;
} header_t;

// length of the file name field
#define NAMELEN      20

// program descriptor
typedef struct prog_s {
	char name[NAMELEN];  // truncated name (15 chars)
	uint32_t offset;     // offset from the beginning of the blob
	uint32_t size;       // size of this ELF module
	uint32_t flags;      // miscellaneous flags
} prog_t;

// modules must be written as multiples of eight bytes
#define FL_ROUNDUP     0x00000001

// mask for mod 8 checking
#define FSIZE_MASK     0x00000007

// program list entry
typedef struct node_s {
	prog_t *data;
	struct node_s *next;
} node_t;

node_t *progs, *last_prog;   // list pointers
uint32_t n_progs;            // number of files being copied
uint32_t offset;             // current file area offset
bool defs = false;           // print CPP #defines?

/**
** Name:	process
**
** Process a program list entry
**
** @param i     Program list index
** @param prog  Pointer to the program list entry
*/
void process( uint32_t i, prog_t *prog ) {

	if( defs ) {

		char *slash = strrchr( prog->name, '/' );
		if( slash == NULL ) {
			slash = prog->name;
		} else {
			++slash;
		}

		slash[0] = toupper(slash[0]);

		printf( "#define %-15s %2d\n", prog->name, i );

	} else {

		printf( "Entry %2d:  ", i );
		printf( "%-s,", prog->name );
		printf( " offset %u, size %u, flags %08x\n",
				prog->offset, prog->size, prog->flags );
	}
}

void usage( char *name ) {
	fprintf( stderr, "usage: %s [-d] blob_name\n", name );
}

int main( int argc, char *argv[] ) {

	if( argc < 2 || argc > 3) {
		usage( argv[0] );
		exit( 1 );
	}
	
	int nameix = 1;

	if( argc == 3 ) {
		if( strcmp(argv[1],"-d") != 0 ) {
			usage( argv[0] );
			exit( 1 );
		}
		defs = true;
		nameix = 2;
	}

	char *name = argv[nameix];

	int fd = open( name, O_RDONLY );
	if( fd < 0 ) {
		perror( name );
		exit( 1 );
	}

	header_t hdr;

	int n = read( fd, &hdr, sizeof(header_t) );
	if( n != sizeof(header_t) ) {
		fprintf( stderr, "%s: header read returned only %d bytes\n", name, n );
		close( fd );
		exit( 1 );
	}

	if( strcmp(hdr.magic,"BLB") != 0 ) {
		fprintf( stderr, "%s: bad magic number\n", name );
		close( fd );
		exit( 1 );
	}

	if( hdr.num < 1 ) {
		fprintf( stderr, "%s: no programs in blob?\n", name );
		close( fd );
		exit( 1 );
	}

	prog_t progs[hdr.num];

	n = read( fd, progs, hdr.num * sizeof(prog_t) );
	if( n != (int) (hdr.num * sizeof(prog_t)) ) {

		fprintf( stderr, "%s: prog table only %d bytes, expected %lu\n",
				name, n, hdr.num * sizeof(prog_t) );
		close( fd );
		exit( 1 );
	}

	for( uint32_t i = 0; i < hdr.num; ++i ) {
		process( i, &progs[i] );
	}

	close( fd );
	return 0;

}
