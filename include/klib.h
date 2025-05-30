/*
** @file    klib.h
**
** @author  Warren R. Carithers
**
** Additional support functions for the kernel.
*/

#ifndef KLIB_H_
#define KLIB_H_

#include <common.h>

#ifndef ASM_SRC

#ifdef USE_STDLIB_MEM_FUNCTIONS
#include <string.h>
#endif

#include <x86/ops.h>

/*
**********************************************
** MEMORY MANIPULATION FUNCTIONS
**********************************************
*/

/**
** blkmov(dst,src,len)
**
** Copy a word-aligned block from src to dst. Deals with overlapping
** buffers.
**
** If the buffer addresses aren't word-aligned or the length is not a
** multiple of four, calls memmove().
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void blkmov(void *dst, const void *src, register uint32_t len);

#ifndef USE_STDLIB_MEM_FUNCTIONS
/**
** memset(buf,len,value)
**
** initialize all bytes of a block of memory to a specific value
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
** @param value  Initialization value
*/
void memset(void *buf, register uint32_t len, register uint32_t value);

/**
** memclr(buf,len)
**
** Initialize all bytes of a block of memory to zero
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
*/
void memclr(void *buf, register uint32_t len);

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
void memcpy(void *dst, register const void *src, register uint32_t len);

/**
** memmove(dst,src,len)
**
** Copy a block from one place to another. Deals with overlapping
** buffers
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void memmove(void *dst, register const void *src, register uint32_t len);
#endif

/*
**********************************************
** STRING MANIPULATION FUNCTIONS
**********************************************
*/

/**
** str2int(str,base) - convert a string to a number in the specified base
**
** @param str   The string to examine
** @param base  The radix to use in the conversion
**
** @return The converted integer
*/
int str2int(register const char *str, register int base);

/**
** strlen(str) - return length of a NUL-terminated string
**
** @param str The string to examine
**
** @return The length of the string, or 0
*/
uint32_t strlen(register const char *str);

/**
** strcmp(s1,s2) - compare two NUL-terminated strings
**
** @param s1 The first source string
** @param s2 The second source string
**
** @return negative if s1 < s2, zero if equal, and positive if s1 > s2
*/
int strcmp(register const char *s1, register const char *s2);

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
char *strcpy(register char *dst, register const char *src);

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
char *strcat(register char *dst, register const char *src);

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
char *pad(char *dst, int extra, int padchar);

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
char *padstr(char *dst, char *str, int len, int width, int leftadjust,
             int padchar);

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
void sprint(char *dst, char *fmt, ...);

/*
**********************************************
** CONVERSION FUNCTIONS
**********************************************
*/

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
char *cvtuns0(char *buf, uint32_t value);

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
int cvtuns(char *buf, uint32_t value);

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
char *cvtdec0(char *buf, int value);

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
int cvtdec(char *buf, int32_t value);

/**
** cvthex(buf,value)
**
** convert a 32-bit unsigned value into a mininal-length (up to
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
int cvthex(char *buf, uint32_t value);

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
int cvtbin( char *buf, uint32_t value );

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
int cvtoct(char *buf, uint32_t value);

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
uint32_t bound(uint32_t min, uint32_t value, uint32_t max);

/**
** Name:    put_char_or_code( ch )
**
** Description: Prints a character on the console, unless it
** is a non-printing character, in which case its hex code
** is printed
**
** @param ch    The character to be printed
*/
void put_char_or_code(int ch);

/**
** Name:    backtrace
**
** Perform a simple stack backtrace. Could be augmented to use the
** symbol table to print function/variable names, etc., if so desired.
**
** @param ebp   Initial EBP to use
** @param args  Number of function argument values to print
*/
void backtrace(uint32_t *ebp, uint_t args);

/**
** Name:	kpanic
**
** Kernel-level panic routine
**
** usage:  kpanic( msg )
**
** Prefix routine for panic() - can be expanded to do other things
** (e.g., printing a stack traceback)
**
** @param msg[in]  String containing a relevant message to be printed,
**                 or NULL
*/
void kpanic(const char *msg);

#endif /* !ASM_SRC */

#endif
