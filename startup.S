/*
** @file	startup.S
**
** @author	Jon Coles
** @authors	Warren R. Carithers, K. Reek
**
** SP startup code.
**
** This code prepares the various registers for execution of
** the program.  It sets up all the segment registers and the
** runtime stack.  By the time this code is running, we're in
** protected mode already.
*/

#define KERNEL_SRC
#define ASM_SRC

#undef i386
	.arch	i386

#include <common.h>
#include <bootstrap.h>
#include <x86/arch.h>
#include <x86/bios.h>
#include <vm.h>

/*
** Compile-time options:
**
**    CLEAR_BSS      include code to clear all BSS space
**    OS_CONFIG      OS-related (vs. just standalone) variations;
**                   also enables CLEAR_BSS
*/

/*
** A symbol for locating the beginning of the code.
*/
	.text

	.globl	begtext
	.globl	_start
_start = begtext

/*
** The entry point. When we get here, we have just entered protected
** mode, so all the segment registers are incorrect except for CS.
*/
begtext:

	cli			/* seems to be reset on entry to p. mode */
	movb	$NMI_ENABLE, %al  /* re-enable NMIs (bootstrap */
	outb	$CMOS_ADDR	  /*   turned them off) */

/*
** Set the data and stack segment registers (code segment register
** was set by the long jump that switched us into protected mode).
*/
	xorl	%eax, %eax	/* clear EAX */
	movw	$GDT_DATA, %ax	/* GDT entry #3 - data segment */
	movw	%ax, %ds	/* for all four data segment registers */
	movw	%ax, %es
	movw	%ax, %fs
	movw	%ax, %gs

	movw	$GDT_STACK, %ax	/* entry #4 is the stack segment */
	movw	%ax, %ss

	movl	$TARGET_STACK, %ebp	/* set up the system stack pointer */
	movl	%ebp, %esp

#if defined(CLEAR_BSS) || defined(OS_CONFIG)
/*
** Zero the BSS segment
**
** These symbols are defined automatically by the linker, but they're
** defined at their virtual addresses rather than their physical addresses,
** and we haven't enabled paging yet.
*/
	.globl	__bss_start, _end

	movl	$__bss_start, %edi
clearbss:
	movl	$0, (%edi)
	addl	$4, %edi
	cmpl	$_end, %edi
	jb	clearbss
#endif	/* CLEAR_BSS || OS_CONFIG */

/*
** Call the system initialization routine.
**
** Alternate idea: push the address of isr_restore
** and just do an indirect jump?
*/
	.globl	main

#	movl	$main, %eax
#	call	*%eax
	call	main

/*
** At this point, main() must have created the first user
** process, and we're ready to shift into user mode.  The user
** stack for that process must have the initial context in it;
** we treat this as a "return from interrupt" event, and just
** transfer to the code that restores the user context.
*/

	.globl	isr_restore
	jmp	isr_restore

	.data

/*
** Define the kernel stack here, at a multiple-of-16 address
*/
#	.p2align 4
#	.globl	kstack
#kstack:	.space	SZ_KSTACK, 0

/*
** Define the initial kernel ESP here, as well. It should point
** to the first byte after the stack.
*/

#	.globl	kernel_esp
#kernel_esp:
#	.long	kstack + SZ_KSTACK
