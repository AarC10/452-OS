
ulibs.o:     file format elf32-i386


Disassembly of section .text:

00000000 <exit>:

/*
** "real" system calls
*/

SYSCALL(exit)
   0:	b8 00 00 00 00       	mov    $0x0,%eax
   5:	cd 80                	int    $0x80
   7:	c3                   	ret    

00000008 <waitpid>:
SYSCALL(waitpid)
   8:	b8 01 00 00 00       	mov    $0x1,%eax
   d:	cd 80                	int    $0x80
   f:	c3                   	ret    

00000010 <fork>:
SYSCALL(fork)
  10:	b8 02 00 00 00       	mov    $0x2,%eax
  15:	cd 80                	int    $0x80
  17:	c3                   	ret    

00000018 <exec>:
SYSCALL(exec)
  18:	b8 03 00 00 00       	mov    $0x3,%eax
  1d:	cd 80                	int    $0x80
  1f:	c3                   	ret    

00000020 <read>:
SYSCALL(read)
  20:	b8 04 00 00 00       	mov    $0x4,%eax
  25:	cd 80                	int    $0x80
  27:	c3                   	ret    

00000028 <write>:
SYSCALL(write)
  28:	b8 05 00 00 00       	mov    $0x5,%eax
  2d:	cd 80                	int    $0x80
  2f:	c3                   	ret    

00000030 <getpid>:
SYSCALL(getpid)
  30:	b8 06 00 00 00       	mov    $0x6,%eax
  35:	cd 80                	int    $0x80
  37:	c3                   	ret    

00000038 <getppid>:
SYSCALL(getppid)
  38:	b8 07 00 00 00       	mov    $0x7,%eax
  3d:	cd 80                	int    $0x80
  3f:	c3                   	ret    

00000040 <gettime>:
SYSCALL(gettime)
  40:	b8 08 00 00 00       	mov    $0x8,%eax
  45:	cd 80                	int    $0x80
  47:	c3                   	ret    

00000048 <getprio>:
SYSCALL(getprio)
  48:	b8 09 00 00 00       	mov    $0x9,%eax
  4d:	cd 80                	int    $0x80
  4f:	c3                   	ret    

00000050 <setprio>:
SYSCALL(setprio)
  50:	b8 0a 00 00 00       	mov    $0xa,%eax
  55:	cd 80                	int    $0x80
  57:	c3                   	ret    

00000058 <kill>:
SYSCALL(kill)
  58:	b8 0b 00 00 00       	mov    $0xb,%eax
  5d:	cd 80                	int    $0x80
  5f:	c3                   	ret    

00000060 <sleep>:
SYSCALL(sleep)
  60:	b8 0c 00 00 00       	mov    $0xc,%eax
  65:	cd 80                	int    $0x80
  67:	c3                   	ret    

00000068 <bogus>:

/*
** This is a bogus system call; it's here so that we can test
** our handling of out-of-range syscall codes in the syscall ISR.
*/
SYSCALL(bogus)
  68:	b8 ad 0b 00 00       	mov    $0xbad,%eax
  6d:	cd 80                	int    $0x80
  6f:	c3                   	ret    

00000070 <fake_exit>:
*/

	.globl	fake_exit
fake_exit:
	// alternate: could push a "fake exit" status
	pushl	%eax	// termination status returned by main()
  70:	50                   	push   %eax
	call	exit	// terminate this process
  71:	e8 fc ff ff ff       	call   72 <fake_exit+0x2>
