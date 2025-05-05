/**
** @file	klibc.c
**
** @author	Numerous CSCI-452 classes
**
** @brief	Kernel library functions
*/

#define KERNEL_SRC

#include <common.h>
#include <lib.h>
#include <procs.h>

/**
** blkmov(dst,src,len)
**
** Copy a word-aligned block from src to dst. Deals with overlapping
** buffers.
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void blkmov( void *dst, const void *src, register uint32_t len ) {

	// verify that the addresses are aligned and
	// the length is a multiple of four bytes
	if( (((uint32_t)dst)&0x3) != 0 ||
		(((uint32_t)src)&0x3) != 0 ||
		(len & 0x3) != 0 ) {
		// something isn't aligned, so just use memmove()
		memmove( dst, src, len );
		return;
	}

	// everything is nicely aligned, so off we go
	register uint32_t *dest = dst;
	register const uint32_t *source = src;

	// now copying 32-bit values
	len /= 4;

	if( source < dest && (source + len) > dest ) {
		source += len;
		dest += len;
		while( len-- > 0 ) {
			*--dest = *--source;
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
		}
	}
}

/**
** bound(min,value,max)
**
** This function confines an argument within specified bounds.
**
** @param min    Lower bound
** @param value  Value to be constrained
** @param max    Upper bound
**
** @return The constrained value
*/
uint32_t bound( uint32_t min, uint32_t value, uint32_t max ) {
	if( value < min ){
		value = min;
	}
	if( value > max ){
		value = max;
	}
	return value;
}

/**
** cvtdec(buf,value)
**
** convert a 32-bit signed value into a NUL-terminated character string
**
** @param buf    Destination buffer
** @param value  Value to convert
**
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtdec( char *buf, int32_t value ) {
	char *bp = buf;

	if( value < 0 ) {
		*bp++ = '-';
		value = -value;
	}

	bp = cvtdec0( bp, value );
	*bp  = '\0';

	return( bp - buf );
}

/**
** cvtdec0(buf,value) - local support routine for cvtdec()
**
** convert a 32-bit unsigned integer into a NUL-terminated character string
**
** @param buf    Destination buffer
** @param value  Value to convert
**
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *cvtdec0( char *buf, int value ) {
	int quotient;

	quotient = value / 10;
	if( quotient < 0 ) {
		quotient = 214748364;
		value = 8;
	}
	if( quotient != 0 ) {
		buf = cvtdec0( buf, quotient );
	}
	*buf++ = value % 10 + '0';
	return buf;
}

/**
** cvthex(buf,value)
**
** convert a 32-bit unsigned value into a minimal-length (up to
** 8-character) NUL-terminated character string
**
** @param buf    Destination buffer
** @param value  Value to convert
**
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvthex( char *buf, uint32_t value ) {
	const char hexdigits[] = "0123456789ABCDEF";
	int chars_stored = 0;

	for( int i = 0; i < 8; i += 1 ) {
		uint32_t val = value & 0xf0000000;
		if( chars_stored || val != 0 || i == 7 ) {
			++chars_stored;
			val = (val >> 28) & 0xf;
			*buf++ = hexdigits[val];
		}
		value <<= 4;
	}

	*buf = '\0';

	return( chars_stored );
}

/**
** cvtbin(buf,value)
**
** convert a 32-bit unsigned value into a binary NUL-terminated
** character string
**
** @param buf    Destination buffer
** @param value  Value to convert
**
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtbin(char *buf, uint32_t value) {
	int bits = sizeof(uint32_t) * 8;

	for (int i = 0; i < bits; i++) {
		uint32_t bit = value >> (bits - 1 - i) & 1;

		*buf++ = (bit == 0) ? '0' : '1';
	}

	*buf = '\0';

	return( bits );
}

/**
** cvtoct(buf,value)
**
** convert a 32-bit unsigned value into a mininal-length (up to
** 11-character) NUL-terminated character string
**
** @param buf   Destination buffer
** @param value Value to convert
**
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtoct( char *buf, uint32_t value ) {
	int i;
	int chars_stored = 0;
	char *bp = buf;
	uint32_t val;

	val = ( value & 0xc0000000 );
	val >>= 30;
	for( i = 0; i < 11; i += 1 ){

		if( i == 10 || val != 0 || chars_stored ) {
			chars_stored = 1;
			val &= 0x7;
			*bp++ = val + '0';
		}
		value <<= 3;
		val = ( value & 0xe0000000 );
		val >>= 29;
	}
	*bp = '\0';

	return bp - buf;
}

/**
** cvtuns(buf,value)
**
** Convert a 32-bit unsigned value into a NUL-terminated character string
**
** @param buf    Result buffer
** @param value  Value to be converted
**
** @return Length of the resulting buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtuns( char *buf, uint32_t value ) {
	char    *bp = buf;

	bp = cvtuns0( bp, value );
	*bp = '\0';

	return bp - buf;
}

/**
** cvtuns0(buf,value) - local support routine for cvtuns()
**
** Convert a 32-bit unsigned value into a NUL-terminated character string
**
** @param buf    Result buffer
** @param value  Value to be converted
**
** @return Pointer to the first unused byte in the buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *cvtuns0( char *buf, uint32_t value ) {
	uint32_t quotient;

	quotient = value / 10;
	if( quotient != 0 ){
		buf = cvtdec0( buf, quotient );
	}
	*buf++ = value % 10 + '0';
	return buf;
}

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
** Name:    backtrace
**
** Perform a stack backtrace
**
** @param ebp   Initial EBP to use
** @param args  Number of function argument values to print
*/
void backtrace( uint32_t *ebp, uint_t args ) {

	cio_puts( "Trace:  " );
	if( ebp == NULL ) {
		cio_puts( "NULL ebp, no trace possible\n" );
		return;
	} else {
		cio_putchar( '\n' );
	}

	while( ebp != NULL ){

		// get return address and report it and EBP
		uint32_t ret = ebp[1];
		cio_printf( " ebp %08x ret %08x args", (uint32_t) ebp, ret );

		// print the requested number of function arguments
		for( uint_t i = 0; i < args; ++i ) {
			cio_printf( " [%u] %08x", i+1, ebp[2+i] );
		}
		cio_putchar( '\n' );

		// follow the chain
		ebp = (uint32_t *) *ebp;
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
**				   or NULL
*/
void kpanic( const char *msg ) {

	cio_puts( "\n\n***** KERNEL PANIC *****\n\n" );

	if( msg ) {
		cio_printf( "%s\n", msg );
	}

	delay( DELAY_5_SEC );   // approximately

	// dump a bunch of potentially useful information

	// dump the contents of the current PCB
	pcb_dump( "Current", current, true );

	// dump the basic info about what's in the process table
	ptable_dump_counts();

	// dump information about the queues
	pcb_queue_dump( "R", ready, true );
	pcb_queue_dump( "W", waiting, true );
	pcb_queue_dump( "S", sleeping, true );
	pcb_queue_dump( "Z", zombie, true );
	pcb_queue_dump( "I", sioread, true );

	// perform a stack backtrace
	backtrace( (uint32_t *) r_ebp(), 3 );

	// could dump other stuff here, too

	panic( "KERNEL PANIC" );
}

/**
** memclr(buf,len)
**
** Initialize all bytes of a block of memory to zero
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
*/
void memclr( void *buf, register uint32_t len ) {
	register uint8_t *dest = buf;

	/*
	** We could speed this up by unrolling it and clearing
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
			*dest++ = 0;
	}
}

/**
** memcpy(dst,src,len)
**
** Copy a block from one place to another
**
** May not correctly deal with overlapping buffers
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void memcpy( void *dst, register const void *src, register uint32_t len ) {
	register uint8_t *dest = dst;
	register const uint8_t *source = src;

	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
		*dest++ = *source++;
	}
}

/**
** memmove(dst,src,len)
**
** Copy a block from one place to another. Deals with overlapping
** buffers.
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void memmove( void *dst, const void *src, register uint32_t len ) {
	register uint8_t *dest = dst;
	register const uint8_t *source = src;

	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	if( source < dest && (source + len) > dest ) {
		source += len;
		dest += len;
		while( len-- > 0 ) {
			*--dest = *--source;
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
		}
	}
}

/**
** memset(buf,len,value)
**
** initialize all bytes of a block of memory to a specific value
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
** @param value  Initialization value
*/
void memset( void *buf, register uint32_t len, register uint32_t value ) {
	register uint8_t *bp = buf;

	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
		*bp++ = value;
	}
}

/**
** pad(dst,extra,padchar) - generate a padding string
**
** @param dst     Pointer to where the padding should begin
** @param extra   How many padding bytes to add
** @param padchar What character to pad with
**
** @return Pointer to the first byte after the padding
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *pad( char *dst, int extra, int padchar ) {
	while( extra > 0 ){
		*dst++ = (char) padchar;
		extra -= 1;
	}
	return dst;
}

/**
** padstr(dst,str,len,width,leftadjust,padchar - add padding characters
**                                               to a string
**
** @param dst        The destination buffer
** @param str        The string to be padded
** @param len        The string length, or -1
** @param width      The desired final length of the string
** @param leftadjust Should the string be left-justified?
** @param padchar    What character to pad with
**
** @return Pointer to the first byte after the padded string
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *padstr( char *dst, char *str, int len, int width,
				int leftadjust, int padchar ) {
	int extra;

	// determine the length of the string if we need to
	if( len < 0 ){
		len = strlen( str );
	}

	// how much filler must we add?
	extra = width - len;

	// add filler on the left if we're not left-justifying
	if( extra > 0 && !leftadjust ){
		dst = pad( dst, extra, padchar );
	}

	// copy the string itself
	for( int i = 0; i < len; ++i ) {
		*dst++ = str[i];
	}

	// add filler on the right if we are left-justifying
	if( extra > 0 && leftadjust ){
		dst = pad( dst, extra, padchar );
	}

	return dst;
}

/**
** sprint(dst,fmt,...) - formatted output into a string buffer
**
** @param dst The string buffer
** @param fmt Format string
**
** The format string parameter is followed by zero or more additional
** parameters which are interpreted according to the format string.
**
** NOTE:  assumes the buffer is large enough to hold the result string
**
** NOTE:  relies heavily on the x86 parameter passing convention
** (parameters are pushed onto the stack in reverse order as
** 32-bit values).
*/
void sprint( char *dst, char *fmt, ... ) {
	int32_t *ap;
	char buf[ 12 ];
	char ch;
	char *str;
	int leftadjust;
	int width;
	int len;
	int padchar;

	/*
	** Get characters from the format string and process them
	**
	** We use the "old-school" method of handling variable numbers
	** of parameters.  We assume that parameters are passed on the
	** runtime stack in consecutive longwords; thus, if the first
	** parameter is at location 'x', the second is at 'x+4', the
	** third at 'x+8', etc.  We use a pointer to a 32-bit thing
	** to point to the next "thing", and interpret it according
	** to the format string.
	*/
	
	// get the pointer to the first "value" parameter
	ap = (int *)(&fmt) + 1;

	// iterate through the format string
	while( (ch = *fmt++) != '\0' ){
		/*
		** Is it the start of a format code?
		*/
		if( ch == '%' ){
			/*
			** Yes, get the padding and width options (if there).
			** Alignment must come at the beginning, then fill,
			** then width.
			*/
			leftadjust = 0;
			padchar = ' ';
			width = 0;
			ch = *fmt++;
			if( ch == '-' ){
				leftadjust = 1;
				ch = *fmt++;
			}
			if( ch == '0' ){
				padchar = '0';
				ch = *fmt++;
			}
			while( ch >= '0' && ch <= '9' ){
				width *= 10;
				width += ch - '0';
				ch = *fmt++;
			}

			/*
			** What data type do we have?
			*/
			switch( ch ) {

			case 'c':  // characters are passed as 32-bit values
				ch = *ap++;
				buf[ 0 ] = ch;
				buf[ 1 ] = '\0';
				dst = padstr( dst, buf, 1, width, leftadjust, padchar );
				break;

			case 'd':
				len = cvtdec( buf, *ap++ );
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
				break;

			case 's':
				str = (char *) (*ap++);
				dst = padstr( dst, str, -1, width, leftadjust, padchar );
				break;

			case 'x':
				len = cvthex( buf, *ap++ );
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
				break;

			case 'o':
				len = cvtoct( buf, *ap++ );
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
				break;

			case 'u':
				len = cvtuns( buf, *ap++ );
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
				break;

			}
		} else {
			// no, it's just an ordinary character
			*dst++ = ch;
		}
	}

	// NUL-terminate the result
	*dst = '\0';
}

/**
** str2int(str,base) - convert a string to a number in the specified base
**
** @param str   The string to examine
** @param base  The radix to use in the conversion
**
** @return The converted integer
*/
int str2int( register const char *str, register int base ) {
	register int num = 0;
	register char bchar = '9';
	int sign = 1;

	// check for leading '-'
	if( *str == '-' ) {
		sign = -1;
		++str;
	}

	if( base != 10 ) {
		bchar = '0' + base - 1;
	}

	// iterate through the characters
	while( *str ) {
		if( *str < '0' || *str > bchar )
			break;
		num = num * base + *str - '0';
		++str;
	}

	// return the converted value
	return( num * sign );
}

/**
** strcat(dst,src) - append one string to another
**
** @param dst The destination buffer
** @param src The source buffer
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the resulting string
*/
char *strcat( register char *dst, register const char *src ) {
	register char *tmp = dst;

	while( *dst )  // find the NUL
		++dst;

	while( (*dst++ = *src++) )  // append the src string
		;

	return( tmp );
}

/**
** strcmp(s1,s2) - compare two NUL-terminated strings
**
** @param s1 The first source string
** @param s2 The second source string
**
** @return negative if s1 < s2, zero if equal, and positive if s1 > s2
*/
int strcmp( register const char *s1, register const char *s2 ) {

	while( *s1 != 0 && (*s1 == *s2) )
		++s1, ++s2;

	return( *s1 - *s2 );
}

/**
** strcpy(dst,src) - copy a NUL-terminated string
**
** @param dst The destination buffer
** @param src The source buffer
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the copied string
*/
char *strcpy( register char *dst, register const char *src ) {
	register char *tmp = dst;

	while( (*dst++ = *src++) )
		;

	return( tmp );
}

/**
** strlen(str) - return length of a NUL-terminated string
**
** @param str The string to examine
**
** @return The length of the string, or 0
*/
uint32_t strlen( register const char *str ) {
	register uint32_t len = 0;

	while( *str++ ) {
		++len;
	}

	return( len );
}
