/**
** @file	ulib.h
**
** @author	CSCI-452 class of 20245
**
** @brief	Declarations for user-level library functions
**
** This module implements a simple collection of support functions
** similar to the standard C library.
*/

#ifndef ULIB_H_
#define ULIB_H_

#include <common.h>

/*
** General (C and/or assembly) definitions
*/

#ifndef ASM_SRC

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
void ublkmov( void *dst, const void *src, register uint32_t len );

/**
** memset(buf,len,value)
**
** initialize all bytes of a block of memory to a specific value
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
** @param value  Initialization value
*/
void umemset( void *buf, register uint32_t len, register uint32_t value );

/**
** memclr(buf,len)
**
** Initialize all bytes of a block of memory to zero
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
*/
void umemclr( void *buf, register uint32_t len );

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
void umemcpy( void *dst, register const void *src, register uint32_t len );

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
void umemmove( void *dst, register const void *src, register uint32_t len );

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
int ustr2int( register const char *str, register int base );

/**
** strlen(str) - return length of a NUL-terminated string
**
** @param str The string to examine
**
** @return The length of the string, or 0
*/
uint32_t ustrlen( register const char *str );

/**
** strcmp(s1,s2) - compare two NUL-terminated strings
**
** @param s1 The first source string
** @param s2 The second source string
**
** @return negative if s1 < s2, zero if equal, and positive if s1 > s2
*/
int ustrcmp( register const char *s1, register const char *s2 );

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
char *ustrcpy( register char *dst, register const char *src );

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
char *ustrcat( register char *dst, register const char *src );

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
char *upad( char *dst, int extra, int padchar );

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
char *upadstr( char *dst, char *str, int len, int width,
				int leftadjust, int padchar );

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
void usprint( char *dst, char *fmt, ... );

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
char *ucvtuns0( char *buf, uint32_t value );

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
int ucvtuns( char *buf, uint32_t value );

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
char *ucvtdec0( char *buf, int value );

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
int ucvtdec( char *buf, int32_t value );

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
int ucvthex( char *buf, uint32_t value );

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
int ucvtoct( char *buf, uint32_t value );

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
uint32_t ubound( uint32_t min, uint32_t value, uint32_t max );

/*
*************************************************
** SYSTEM CALLS *********************************
*************************************************
*/

/**
** exit - terminate the calling process
**
** usage:   exit(status);
**
** @param status   Termination status of this process
**
** Does not return.
*/
void exit( int32_t status );

/**
** waitpid - wait for a child process to terminate
**
** usage:   pid = waitpid(pid,&status);
**
** @param pid    PID of the desired child, or 0 for any child
** @param status Pointer to int32_t into which the child's status is placed,
**               or NULL
**
** @return  The PID of the terminated child, or an error code
**
** If there are no children in the system, returns an error code (*status
** is unchanged).
**
** If there are one or more children in the system and at least one has
** terminated but hasn't yet been cleaned up, cleans up that process and
** returns its information; otherwise, blocks until a child terminates.
*/
int waitpid( uint_t pid, int32_t *status );

/**
** fork - create a duplicate of the calling process
**
** usage:   pid = fork();
**
** @return   parent - the pid of the new child, or an error code
**           child  - 0
*/
int fork( void );

/**
** exec - replace the memory image of the calling process
**
** usage:   exec( entry, args )
**
** @param entry   entry point of the 'main' function
** @param args    the command-line argument vector
**
** Does not return if it succeeds; if it returns, something has
** gone wrong.
*/
void exec( uint32_t entry, char **args );

/**
** read - read into a buffer from a stream
**
** usage:   n = read(channel,buf,length)
**
** @param chan   I/O stream to read from
** @param buf    Buffer to read into
** @param length Maximum capacity of the buffer
**
** @return   The count of bytes transferred, or an error code
*/
int read( uint_t chan, void *buffer, uint_t length );

/**
** write - write from a buffer to a stream
**
** usage:   n = write(channel,buf,length)
**
** @param chan   I/O stream to write to
** @param buf    Buffer to write from
** @param length Maximum capacity of the buffer
**
** @return   The count of bytes transferred, or an error code
*/
int write( uint_t chan, const void *buffer, uint_t length );

/**
** getpid - get the PID of the calling process
**
** usage:   pid = getpid()
**
** @return   the PID of this process
*/
uint_t getpid( void );

/**
** getppid - get the PID of the calling process' parent
**
** usage:   pid = getppid()
**
** @return   the PID of this process' parent
*/
uint_t getppid( void );

/**
** gettime - get the current system time
**
** usage:   pid = gettime()
**
** @return   the system time
*/
uint32_t gettime( void );

/**
** getprio - get the scheduling priority of the calling process
**
** usage:   prio = getprio()
**
** @return   the process' priority
*/
int getprio( void );

/**
** setprio - set the scheduling priority of the calling process
**
** usage:   oldprio = setprio(newprio)
**
** @param new   the desired new priority
**
** @return   the old priority value
*/
int setprio( int new );

/**
** kill - terminate a process with extreme prejudice
**
** usage:   n = kill( pid )
**
** @param pid  the intended victim
**
** @return   0 on success, else an error code
*/
int32_t kill( uint_t pid );

/**
** sleep - put the current process to sleep for some length of time
**
** usage:   sleep(n);
**
** @param ms Desired sleep time (in ms), or 0 to yield the CPU
**
** @return the time the process spent sleeping (in ms)
*/
int sleep( uint32_t ms );

/**
** bogus - a nonexistent system call, to test our syscall ISR
**
** usage:   bogus()
**
** Does not return.
*/
void bogus( void );

/*
*************************************************
** CONVENIENT "SHORTHAND" VERSIONS OF SYSCALLS **
*************************************************
**
** These are library functions that perform specific common
** variants of system calls. This helps reduce the total number
** of system calls, keeping our baseline OS as lean and mean
** as we can make it. :-)
*/

/**
** wait - wait for any child to exit
**
** usage:   pid = wait(&status)
**
** Calls waitpid(0,status)
**
** @param status Pointer to int32_t into which the child's status is placed,
**               or NULL
**
** @return  The PID of the terminated child, or an error code
*/
int wait( int32_t *status );

/**
** spawn - create a new process running a different program
**
** usage:       n = spawn(entry,args)
**
** Creates a new process and then execs 'entry'
**
** @param entry The entry point of the 'main' function for the process
** @param args  The command-line argument vector for the process
**
** @return      The PID of the child, or an error code
*/
int spawn( uint32_t entry, char **args );

/**
** cwritech(ch) - write a single character to the console
**
** @param ch The character to write
**
** @return  The return value from calling write()
*/
int cwritech( char ch );

/**
** cwrites(str) - write a NUL-terminated string to the console
**
** @param str The string to write
**
*/
int cwrites( const char *str );

/**
** cwrite(buf,leng) - write a sized buffer to the console
**
** @param buf  The buffer to write
** @param leng The number of bytes to write
**
** @return  The return value from calling write()
*/
int cwrite( const char *buf, uint32_t leng );

/**
** swritech(ch) - write a single character to the SIO
**
** @param ch The character to write
**
** @return  The return value from calling write()
*/
int swritech( char ch );

/**
** swrites(str) - write a NUL-terminated string to the SIO
**
** @param str The string to write
**
** @return  The return value from calling write()
*/
int swrites( const char *str );

/**
** swrite(buf,leng) - write a sized buffer to the SIO
**
** @param buf  The buffer to write
** @param leng The number of bytes to write
**
** @return  The return value from calling write()
*/
int swrite( const char *buf, uint32_t leng );

/*
*************************************************
** MISCELLANEOUS USEFUL SUPPORT FUNCTIONS *******
*************************************************
*/

/**
** fake_exit()
**
** dummy "startup" function
**
** calls exit(%eax) - serves as the "return to" code for
** main() functions, in case they don't call exit() themselves
*/
void fake_exit( void );

#endif /* !ASM_SRC */

#endif
