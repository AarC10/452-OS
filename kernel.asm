
kernel:     file format elf32-i386


Disassembly of section .text:

00010000 <_start>:
** The entry point. When we get here, we have just entered protected
** mode, so all the segment registers are incorrect except for CS.
*/
begtext:

	cli			/* seems to be reset on entry to p. mode */
   10000:	fa                   	cli    
	movb	$NMI_ENABLE, %al  /* re-enable NMIs (bootstrap */
   10001:	b0 00                	mov    $0x0,%al
	outb	$CMOS_ADDR	  /*   turned them off) */
   10003:	e6 70                	out    %al,$0x70

/*
** Set the data and stack segment registers (code segment register
** was set by the long jump that switched us into protected mode).
*/
	xorl	%eax, %eax	/* clear EAX */
   10005:	31 c0                	xor    %eax,%eax
	movw	$GDT_DATA, %ax	/* GDT entry #3 - data segment */
   10007:	66 b8 18 00          	mov    $0x18,%ax
	movw	%ax, %ds	/* for all four data segment registers */
   1000b:	8e d8                	mov    %eax,%ds
	movw	%ax, %es
   1000d:	8e c0                	mov    %eax,%es
	movw	%ax, %fs
   1000f:	8e e0                	mov    %eax,%fs
	movw	%ax, %gs
   10011:	8e e8                	mov    %eax,%gs

	movw	$GDT_STACK, %ax	/* entry #4 is the stack segment */
   10013:	66 b8 20 00          	mov    $0x20,%ax
	movw	%ax, %ss
   10017:	8e d0                	mov    %eax,%ss

	movl	$TARGET_STACK, %ebp	/* set up the system stack pointer */
   10019:	bd 00 00 01 00       	mov    $0x10000,%ebp
	movl	%ebp, %esp
   1001e:	89 ec                	mov    %ebp,%esp
** defined at their virtual addresses rather than their physical addresses,
** and we haven't enabled paging yet.
*/
	.globl	__bss_start, _end

	movl	$__bss_start, %edi
   10020:	bf 00 e0 01 00       	mov    $0x1e000,%edi

00010025 <clearbss>:
clearbss:
	movl	$0, (%edi)
   10025:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
	addl	$4, %edi
   1002b:	83 c7 04             	add    $0x4,%edi
	cmpl	$_end, %edi
   1002e:	81 ff e4 28 02 00    	cmp    $0x228e4,%edi
	jb	clearbss
   10034:	72 ef                	jb     10025 <clearbss>
*/
	.globl	main

#	movl	$main, %eax
#	call	*%eax
	call	main
   10036:	e8 10 1d 00 00       	call   11d4b <main>
** we treat this as a "return from interrupt" event, and just
** transfer to the code that restores the user context.
*/

	.globl	isr_restore
	jmp	isr_restore
   1003b:	e9 2c 00 00 00       	jmp    1006c <isr_restore>

00010040 <isr_save>:
**	    error code, or 0	saved by the hardware, or the entry macro
**	    saved EIP		saved by the hardware
**	    saved CS		saved by the hardware
**	    saved EFLAGS	saved by the hardware
*/
	pusha			// save E*X, ESP, EBP, ESI, EDI
   10040:	60                   	pusha  
	pushl	%ds		// save segment registers
   10041:	1e                   	push   %ds
	pushl	%es
   10042:	06                   	push   %es
	pushl	%fs
   10043:	0f a0                	push   %fs
	pushl	%gs
   10045:	0f a8                	push   %gs
	pushl	%ss
   10047:	16                   	push   %ss
**
** Note that the saved ESP is the contents before the PUSHA.
**
** Set up parameters for the ISR call.
*/
	movl	CTX_vector(%esp),%eax	// get vector number and error code
   10048:	8b 44 24 34          	mov    0x34(%esp),%eax
	movl	CTX_code(%esp),%ebx
   1004c:	8b 5c 24 38          	mov    0x38(%esp),%ebx

	.globl	current
	.globl	kernel_esp

	// save the context pointer
	movl	current, %edx
   10050:	8b 15 14 20 02 00    	mov    0x22014,%edx
	movl	%esp, PCB_context(%edx)
   10056:	89 22                	mov    %esp,(%edx)
	// NOTE: this is inherently non-reentrant!  If/when the OS
	// is converted from monolithic to something that supports
	// reentrant or interruptable ISRs, this code will need to
	// be changed to support that!

	movl	kernel_esp, %esp
   10058:	8b 25 0c d1 01 00    	mov    0x1d10c,%esp

#
# END MOD FOR 20245
#

	pushl	%ebx		// put them on the top of the stack ...
   1005e:	53                   	push   %ebx
	pushl	%eax		// ... as parameters for the ISR
   1005f:	50                   	push   %eax

/*
** Call the ISR
*/
	movl	isr_table(,%eax,4),%ebx
   10060:	8b 1c 85 e0 24 02 00 	mov    0x224e0(,%eax,4),%ebx
	call	*%ebx
   10067:	ff d3                	call   *%ebx
	addl	$8,%esp		// pop the two parameters
   10069:	83 c4 08             	add    $0x8,%esp

0001006c <isr_restore>:
isr_restore:

#
# MOD FOR 20245
#
	movl	current, %ebx	// return to the user stack
   1006c:	8b 1d 14 20 02 00    	mov    0x22014,%ebx
	movl	PCB_context(%ebx), %esp	// ESP --> context save area
   10072:	8b 23                	mov    (%ebx),%esp
#
# Report system time and PID with context
#
	.globl	system_time

	pushl	PCB_pid(%ebx)
   10074:	ff 73 18             	pushl  0x18(%ebx)
	pushl	system_time
   10077:	ff 35 bc f1 01 00    	pushl  0x1f1bc
	pushl	$fmtall
   1007d:	68 60 a4 01 00       	push   $0x1a460
	pushl	$1
   10082:	6a 01                	push   $0x1
	pushl	$0
   10084:	6a 00                	push   $0x0
	call	cio_printf_at
   10086:	e8 7c 14 00 00       	call   11507 <cio_printf_at>
	addl	$20,%esp
   1008b:	83 c4 14             	add    $0x14,%esp
#endif

/*
** Restore the context.
*/
	popl	%ss		// restore the segment registers
   1008e:	17                   	pop    %ss
	popl	%gs
   1008f:	0f a9                	pop    %gs
	popl	%fs
   10091:	0f a1                	pop    %fs
	popl	%es
   10093:	07                   	pop    %es
	popl	%ds
   10094:	1f                   	pop    %ds
	popa			// restore others
   10095:	61                   	popa   
	addl	$8, %esp	// discard the error code and vector
   10096:	83 c4 08             	add    $0x8,%esp
	iret			// and return
   10099:	cf                   	iret   

0001009a <isr_0x00>:
#endif

/*
** Here we generate the individual stubs for each interrupt.
*/
ISR(0x00);	ISR(0x01);	ISR(0x02);	ISR(0x03);
   1009a:	6a 00                	push   $0x0
   1009c:	6a 00                	push   $0x0
   1009e:	eb a0                	jmp    10040 <isr_save>

000100a0 <isr_0x01>:
   100a0:	6a 00                	push   $0x0
   100a2:	6a 01                	push   $0x1
   100a4:	eb 9a                	jmp    10040 <isr_save>

000100a6 <isr_0x02>:
   100a6:	6a 00                	push   $0x0
   100a8:	6a 02                	push   $0x2
   100aa:	eb 94                	jmp    10040 <isr_save>

000100ac <isr_0x03>:
   100ac:	6a 00                	push   $0x0
   100ae:	6a 03                	push   $0x3
   100b0:	eb 8e                	jmp    10040 <isr_save>

000100b2 <isr_0x04>:
ISR(0x04);	ISR(0x05);	ISR(0x06);	ISR(0x07);
   100b2:	6a 00                	push   $0x0
   100b4:	6a 04                	push   $0x4
   100b6:	eb 88                	jmp    10040 <isr_save>

000100b8 <isr_0x05>:
   100b8:	6a 00                	push   $0x0
   100ba:	6a 05                	push   $0x5
   100bc:	eb 82                	jmp    10040 <isr_save>

000100be <isr_0x06>:
   100be:	6a 00                	push   $0x0
   100c0:	6a 06                	push   $0x6
   100c2:	e9 79 ff ff ff       	jmp    10040 <isr_save>

000100c7 <isr_0x07>:
   100c7:	6a 00                	push   $0x0
   100c9:	6a 07                	push   $0x7
   100cb:	e9 70 ff ff ff       	jmp    10040 <isr_save>

000100d0 <isr_0x08>:
ERR_ISR(0x08);	ISR(0x09);	ERR_ISR(0x0a);	ERR_ISR(0x0b);
   100d0:	6a 08                	push   $0x8
   100d2:	e9 69 ff ff ff       	jmp    10040 <isr_save>

000100d7 <isr_0x09>:
   100d7:	6a 00                	push   $0x0
   100d9:	6a 09                	push   $0x9
   100db:	e9 60 ff ff ff       	jmp    10040 <isr_save>

000100e0 <isr_0x0a>:
   100e0:	6a 0a                	push   $0xa
   100e2:	e9 59 ff ff ff       	jmp    10040 <isr_save>

000100e7 <isr_0x0b>:
   100e7:	6a 0b                	push   $0xb
   100e9:	e9 52 ff ff ff       	jmp    10040 <isr_save>

000100ee <isr_0x0c>:
ERR_ISR(0x0c);	ERR_ISR(0x0d);	ERR_ISR(0x0e);	ISR(0x0f);
   100ee:	6a 0c                	push   $0xc
   100f0:	e9 4b ff ff ff       	jmp    10040 <isr_save>

000100f5 <isr_0x0d>:
   100f5:	6a 0d                	push   $0xd
   100f7:	e9 44 ff ff ff       	jmp    10040 <isr_save>

000100fc <isr_0x0e>:
   100fc:	6a 0e                	push   $0xe
   100fe:	e9 3d ff ff ff       	jmp    10040 <isr_save>

00010103 <isr_0x0f>:
   10103:	6a 00                	push   $0x0
   10105:	6a 0f                	push   $0xf
   10107:	e9 34 ff ff ff       	jmp    10040 <isr_save>

0001010c <isr_0x10>:
ISR(0x10);	ERR_ISR(0x11);	ISR(0x12);	ISR(0x13);
   1010c:	6a 00                	push   $0x0
   1010e:	6a 10                	push   $0x10
   10110:	e9 2b ff ff ff       	jmp    10040 <isr_save>

00010115 <isr_0x11>:
   10115:	6a 11                	push   $0x11
   10117:	e9 24 ff ff ff       	jmp    10040 <isr_save>

0001011c <isr_0x12>:
   1011c:	6a 00                	push   $0x0
   1011e:	6a 12                	push   $0x12
   10120:	e9 1b ff ff ff       	jmp    10040 <isr_save>

00010125 <isr_0x13>:
   10125:	6a 00                	push   $0x0
   10127:	6a 13                	push   $0x13
   10129:	e9 12 ff ff ff       	jmp    10040 <isr_save>

0001012e <isr_0x14>:
ISR(0x14);	ERR_ISR(0x15);	ISR(0x16);	ISR(0x17);
   1012e:	6a 00                	push   $0x0
   10130:	6a 14                	push   $0x14
   10132:	e9 09 ff ff ff       	jmp    10040 <isr_save>

00010137 <isr_0x15>:
   10137:	6a 15                	push   $0x15
   10139:	e9 02 ff ff ff       	jmp    10040 <isr_save>

0001013e <isr_0x16>:
   1013e:	6a 00                	push   $0x0
   10140:	6a 16                	push   $0x16
   10142:	e9 f9 fe ff ff       	jmp    10040 <isr_save>

00010147 <isr_0x17>:
   10147:	6a 00                	push   $0x0
   10149:	6a 17                	push   $0x17
   1014b:	e9 f0 fe ff ff       	jmp    10040 <isr_save>

00010150 <isr_0x18>:
ISR(0x18);	ISR(0x19);	ISR(0x1a);	ISR(0x1b);
   10150:	6a 00                	push   $0x0
   10152:	6a 18                	push   $0x18
   10154:	e9 e7 fe ff ff       	jmp    10040 <isr_save>

00010159 <isr_0x19>:
   10159:	6a 00                	push   $0x0
   1015b:	6a 19                	push   $0x19
   1015d:	e9 de fe ff ff       	jmp    10040 <isr_save>

00010162 <isr_0x1a>:
   10162:	6a 00                	push   $0x0
   10164:	6a 1a                	push   $0x1a
   10166:	e9 d5 fe ff ff       	jmp    10040 <isr_save>

0001016b <isr_0x1b>:
   1016b:	6a 00                	push   $0x0
   1016d:	6a 1b                	push   $0x1b
   1016f:	e9 cc fe ff ff       	jmp    10040 <isr_save>

00010174 <isr_0x1c>:
ISR(0x1c);	ISR(0x1d);	ISR(0x1e);	ISR(0x1f);
   10174:	6a 00                	push   $0x0
   10176:	6a 1c                	push   $0x1c
   10178:	e9 c3 fe ff ff       	jmp    10040 <isr_save>

0001017d <isr_0x1d>:
   1017d:	6a 00                	push   $0x0
   1017f:	6a 1d                	push   $0x1d
   10181:	e9 ba fe ff ff       	jmp    10040 <isr_save>

00010186 <isr_0x1e>:
   10186:	6a 00                	push   $0x0
   10188:	6a 1e                	push   $0x1e
   1018a:	e9 b1 fe ff ff       	jmp    10040 <isr_save>

0001018f <isr_0x1f>:
   1018f:	6a 00                	push   $0x0
   10191:	6a 1f                	push   $0x1f
   10193:	e9 a8 fe ff ff       	jmp    10040 <isr_save>

00010198 <isr_0x20>:
ISR(0x20);	ISR(0x21);	ISR(0x22);	ISR(0x23);
   10198:	6a 00                	push   $0x0
   1019a:	6a 20                	push   $0x20
   1019c:	e9 9f fe ff ff       	jmp    10040 <isr_save>

000101a1 <isr_0x21>:
   101a1:	6a 00                	push   $0x0
   101a3:	6a 21                	push   $0x21
   101a5:	e9 96 fe ff ff       	jmp    10040 <isr_save>

000101aa <isr_0x22>:
   101aa:	6a 00                	push   $0x0
   101ac:	6a 22                	push   $0x22
   101ae:	e9 8d fe ff ff       	jmp    10040 <isr_save>

000101b3 <isr_0x23>:
   101b3:	6a 00                	push   $0x0
   101b5:	6a 23                	push   $0x23
   101b7:	e9 84 fe ff ff       	jmp    10040 <isr_save>

000101bc <isr_0x24>:
ISR(0x24);	ISR(0x25);	ISR(0x26);	ISR(0x27);
   101bc:	6a 00                	push   $0x0
   101be:	6a 24                	push   $0x24
   101c0:	e9 7b fe ff ff       	jmp    10040 <isr_save>

000101c5 <isr_0x25>:
   101c5:	6a 00                	push   $0x0
   101c7:	6a 25                	push   $0x25
   101c9:	e9 72 fe ff ff       	jmp    10040 <isr_save>

000101ce <isr_0x26>:
   101ce:	6a 00                	push   $0x0
   101d0:	6a 26                	push   $0x26
   101d2:	e9 69 fe ff ff       	jmp    10040 <isr_save>

000101d7 <isr_0x27>:
   101d7:	6a 00                	push   $0x0
   101d9:	6a 27                	push   $0x27
   101db:	e9 60 fe ff ff       	jmp    10040 <isr_save>

000101e0 <isr_0x28>:
ISR(0x28);	ISR(0x29);	ISR(0x2a);	ISR(0x2b);
   101e0:	6a 00                	push   $0x0
   101e2:	6a 28                	push   $0x28
   101e4:	e9 57 fe ff ff       	jmp    10040 <isr_save>

000101e9 <isr_0x29>:
   101e9:	6a 00                	push   $0x0
   101eb:	6a 29                	push   $0x29
   101ed:	e9 4e fe ff ff       	jmp    10040 <isr_save>

000101f2 <isr_0x2a>:
   101f2:	6a 00                	push   $0x0
   101f4:	6a 2a                	push   $0x2a
   101f6:	e9 45 fe ff ff       	jmp    10040 <isr_save>

000101fb <isr_0x2b>:
   101fb:	6a 00                	push   $0x0
   101fd:	6a 2b                	push   $0x2b
   101ff:	e9 3c fe ff ff       	jmp    10040 <isr_save>

00010204 <isr_0x2c>:
ISR(0x2c);	ISR(0x2d);	ISR(0x2e);	ISR(0x2f);
   10204:	6a 00                	push   $0x0
   10206:	6a 2c                	push   $0x2c
   10208:	e9 33 fe ff ff       	jmp    10040 <isr_save>

0001020d <isr_0x2d>:
   1020d:	6a 00                	push   $0x0
   1020f:	6a 2d                	push   $0x2d
   10211:	e9 2a fe ff ff       	jmp    10040 <isr_save>

00010216 <isr_0x2e>:
   10216:	6a 00                	push   $0x0
   10218:	6a 2e                	push   $0x2e
   1021a:	e9 21 fe ff ff       	jmp    10040 <isr_save>

0001021f <isr_0x2f>:
   1021f:	6a 00                	push   $0x0
   10221:	6a 2f                	push   $0x2f
   10223:	e9 18 fe ff ff       	jmp    10040 <isr_save>

00010228 <isr_0x30>:
ISR(0x30);	ISR(0x31);	ISR(0x32);	ISR(0x33);
   10228:	6a 00                	push   $0x0
   1022a:	6a 30                	push   $0x30
   1022c:	e9 0f fe ff ff       	jmp    10040 <isr_save>

00010231 <isr_0x31>:
   10231:	6a 00                	push   $0x0
   10233:	6a 31                	push   $0x31
   10235:	e9 06 fe ff ff       	jmp    10040 <isr_save>

0001023a <isr_0x32>:
   1023a:	6a 00                	push   $0x0
   1023c:	6a 32                	push   $0x32
   1023e:	e9 fd fd ff ff       	jmp    10040 <isr_save>

00010243 <isr_0x33>:
   10243:	6a 00                	push   $0x0
   10245:	6a 33                	push   $0x33
   10247:	e9 f4 fd ff ff       	jmp    10040 <isr_save>

0001024c <isr_0x34>:
ISR(0x34);	ISR(0x35);	ISR(0x36);	ISR(0x37);
   1024c:	6a 00                	push   $0x0
   1024e:	6a 34                	push   $0x34
   10250:	e9 eb fd ff ff       	jmp    10040 <isr_save>

00010255 <isr_0x35>:
   10255:	6a 00                	push   $0x0
   10257:	6a 35                	push   $0x35
   10259:	e9 e2 fd ff ff       	jmp    10040 <isr_save>

0001025e <isr_0x36>:
   1025e:	6a 00                	push   $0x0
   10260:	6a 36                	push   $0x36
   10262:	e9 d9 fd ff ff       	jmp    10040 <isr_save>

00010267 <isr_0x37>:
   10267:	6a 00                	push   $0x0
   10269:	6a 37                	push   $0x37
   1026b:	e9 d0 fd ff ff       	jmp    10040 <isr_save>

00010270 <isr_0x38>:
ISR(0x38);	ISR(0x39);	ISR(0x3a);	ISR(0x3b);
   10270:	6a 00                	push   $0x0
   10272:	6a 38                	push   $0x38
   10274:	e9 c7 fd ff ff       	jmp    10040 <isr_save>

00010279 <isr_0x39>:
   10279:	6a 00                	push   $0x0
   1027b:	6a 39                	push   $0x39
   1027d:	e9 be fd ff ff       	jmp    10040 <isr_save>

00010282 <isr_0x3a>:
   10282:	6a 00                	push   $0x0
   10284:	6a 3a                	push   $0x3a
   10286:	e9 b5 fd ff ff       	jmp    10040 <isr_save>

0001028b <isr_0x3b>:
   1028b:	6a 00                	push   $0x0
   1028d:	6a 3b                	push   $0x3b
   1028f:	e9 ac fd ff ff       	jmp    10040 <isr_save>

00010294 <isr_0x3c>:
ISR(0x3c);	ISR(0x3d);	ISR(0x3e);	ISR(0x3f);
   10294:	6a 00                	push   $0x0
   10296:	6a 3c                	push   $0x3c
   10298:	e9 a3 fd ff ff       	jmp    10040 <isr_save>

0001029d <isr_0x3d>:
   1029d:	6a 00                	push   $0x0
   1029f:	6a 3d                	push   $0x3d
   102a1:	e9 9a fd ff ff       	jmp    10040 <isr_save>

000102a6 <isr_0x3e>:
   102a6:	6a 00                	push   $0x0
   102a8:	6a 3e                	push   $0x3e
   102aa:	e9 91 fd ff ff       	jmp    10040 <isr_save>

000102af <isr_0x3f>:
   102af:	6a 00                	push   $0x0
   102b1:	6a 3f                	push   $0x3f
   102b3:	e9 88 fd ff ff       	jmp    10040 <isr_save>

000102b8 <isr_0x40>:
ISR(0x40);	ISR(0x41);	ISR(0x42);	ISR(0x43);
   102b8:	6a 00                	push   $0x0
   102ba:	6a 40                	push   $0x40
   102bc:	e9 7f fd ff ff       	jmp    10040 <isr_save>

000102c1 <isr_0x41>:
   102c1:	6a 00                	push   $0x0
   102c3:	6a 41                	push   $0x41
   102c5:	e9 76 fd ff ff       	jmp    10040 <isr_save>

000102ca <isr_0x42>:
   102ca:	6a 00                	push   $0x0
   102cc:	6a 42                	push   $0x42
   102ce:	e9 6d fd ff ff       	jmp    10040 <isr_save>

000102d3 <isr_0x43>:
   102d3:	6a 00                	push   $0x0
   102d5:	6a 43                	push   $0x43
   102d7:	e9 64 fd ff ff       	jmp    10040 <isr_save>

000102dc <isr_0x44>:
ISR(0x44);	ISR(0x45);	ISR(0x46);	ISR(0x47);
   102dc:	6a 00                	push   $0x0
   102de:	6a 44                	push   $0x44
   102e0:	e9 5b fd ff ff       	jmp    10040 <isr_save>

000102e5 <isr_0x45>:
   102e5:	6a 00                	push   $0x0
   102e7:	6a 45                	push   $0x45
   102e9:	e9 52 fd ff ff       	jmp    10040 <isr_save>

000102ee <isr_0x46>:
   102ee:	6a 00                	push   $0x0
   102f0:	6a 46                	push   $0x46
   102f2:	e9 49 fd ff ff       	jmp    10040 <isr_save>

000102f7 <isr_0x47>:
   102f7:	6a 00                	push   $0x0
   102f9:	6a 47                	push   $0x47
   102fb:	e9 40 fd ff ff       	jmp    10040 <isr_save>

00010300 <isr_0x48>:
ISR(0x48);	ISR(0x49);	ISR(0x4a);	ISR(0x4b);
   10300:	6a 00                	push   $0x0
   10302:	6a 48                	push   $0x48
   10304:	e9 37 fd ff ff       	jmp    10040 <isr_save>

00010309 <isr_0x49>:
   10309:	6a 00                	push   $0x0
   1030b:	6a 49                	push   $0x49
   1030d:	e9 2e fd ff ff       	jmp    10040 <isr_save>

00010312 <isr_0x4a>:
   10312:	6a 00                	push   $0x0
   10314:	6a 4a                	push   $0x4a
   10316:	e9 25 fd ff ff       	jmp    10040 <isr_save>

0001031b <isr_0x4b>:
   1031b:	6a 00                	push   $0x0
   1031d:	6a 4b                	push   $0x4b
   1031f:	e9 1c fd ff ff       	jmp    10040 <isr_save>

00010324 <isr_0x4c>:
ISR(0x4c);	ISR(0x4d);	ISR(0x4e);	ISR(0x4f);
   10324:	6a 00                	push   $0x0
   10326:	6a 4c                	push   $0x4c
   10328:	e9 13 fd ff ff       	jmp    10040 <isr_save>

0001032d <isr_0x4d>:
   1032d:	6a 00                	push   $0x0
   1032f:	6a 4d                	push   $0x4d
   10331:	e9 0a fd ff ff       	jmp    10040 <isr_save>

00010336 <isr_0x4e>:
   10336:	6a 00                	push   $0x0
   10338:	6a 4e                	push   $0x4e
   1033a:	e9 01 fd ff ff       	jmp    10040 <isr_save>

0001033f <isr_0x4f>:
   1033f:	6a 00                	push   $0x0
   10341:	6a 4f                	push   $0x4f
   10343:	e9 f8 fc ff ff       	jmp    10040 <isr_save>

00010348 <isr_0x50>:
ISR(0x50);	ISR(0x51);	ISR(0x52);	ISR(0x53);
   10348:	6a 00                	push   $0x0
   1034a:	6a 50                	push   $0x50
   1034c:	e9 ef fc ff ff       	jmp    10040 <isr_save>

00010351 <isr_0x51>:
   10351:	6a 00                	push   $0x0
   10353:	6a 51                	push   $0x51
   10355:	e9 e6 fc ff ff       	jmp    10040 <isr_save>

0001035a <isr_0x52>:
   1035a:	6a 00                	push   $0x0
   1035c:	6a 52                	push   $0x52
   1035e:	e9 dd fc ff ff       	jmp    10040 <isr_save>

00010363 <isr_0x53>:
   10363:	6a 00                	push   $0x0
   10365:	6a 53                	push   $0x53
   10367:	e9 d4 fc ff ff       	jmp    10040 <isr_save>

0001036c <isr_0x54>:
ISR(0x54);	ISR(0x55);	ISR(0x56);	ISR(0x57);
   1036c:	6a 00                	push   $0x0
   1036e:	6a 54                	push   $0x54
   10370:	e9 cb fc ff ff       	jmp    10040 <isr_save>

00010375 <isr_0x55>:
   10375:	6a 00                	push   $0x0
   10377:	6a 55                	push   $0x55
   10379:	e9 c2 fc ff ff       	jmp    10040 <isr_save>

0001037e <isr_0x56>:
   1037e:	6a 00                	push   $0x0
   10380:	6a 56                	push   $0x56
   10382:	e9 b9 fc ff ff       	jmp    10040 <isr_save>

00010387 <isr_0x57>:
   10387:	6a 00                	push   $0x0
   10389:	6a 57                	push   $0x57
   1038b:	e9 b0 fc ff ff       	jmp    10040 <isr_save>

00010390 <isr_0x58>:
ISR(0x58);	ISR(0x59);	ISR(0x5a);	ISR(0x5b);
   10390:	6a 00                	push   $0x0
   10392:	6a 58                	push   $0x58
   10394:	e9 a7 fc ff ff       	jmp    10040 <isr_save>

00010399 <isr_0x59>:
   10399:	6a 00                	push   $0x0
   1039b:	6a 59                	push   $0x59
   1039d:	e9 9e fc ff ff       	jmp    10040 <isr_save>

000103a2 <isr_0x5a>:
   103a2:	6a 00                	push   $0x0
   103a4:	6a 5a                	push   $0x5a
   103a6:	e9 95 fc ff ff       	jmp    10040 <isr_save>

000103ab <isr_0x5b>:
   103ab:	6a 00                	push   $0x0
   103ad:	6a 5b                	push   $0x5b
   103af:	e9 8c fc ff ff       	jmp    10040 <isr_save>

000103b4 <isr_0x5c>:
ISR(0x5c);	ISR(0x5d);	ISR(0x5e);	ISR(0x5f);
   103b4:	6a 00                	push   $0x0
   103b6:	6a 5c                	push   $0x5c
   103b8:	e9 83 fc ff ff       	jmp    10040 <isr_save>

000103bd <isr_0x5d>:
   103bd:	6a 00                	push   $0x0
   103bf:	6a 5d                	push   $0x5d
   103c1:	e9 7a fc ff ff       	jmp    10040 <isr_save>

000103c6 <isr_0x5e>:
   103c6:	6a 00                	push   $0x0
   103c8:	6a 5e                	push   $0x5e
   103ca:	e9 71 fc ff ff       	jmp    10040 <isr_save>

000103cf <isr_0x5f>:
   103cf:	6a 00                	push   $0x0
   103d1:	6a 5f                	push   $0x5f
   103d3:	e9 68 fc ff ff       	jmp    10040 <isr_save>

000103d8 <isr_0x60>:
ISR(0x60);	ISR(0x61);	ISR(0x62);	ISR(0x63);
   103d8:	6a 00                	push   $0x0
   103da:	6a 60                	push   $0x60
   103dc:	e9 5f fc ff ff       	jmp    10040 <isr_save>

000103e1 <isr_0x61>:
   103e1:	6a 00                	push   $0x0
   103e3:	6a 61                	push   $0x61
   103e5:	e9 56 fc ff ff       	jmp    10040 <isr_save>

000103ea <isr_0x62>:
   103ea:	6a 00                	push   $0x0
   103ec:	6a 62                	push   $0x62
   103ee:	e9 4d fc ff ff       	jmp    10040 <isr_save>

000103f3 <isr_0x63>:
   103f3:	6a 00                	push   $0x0
   103f5:	6a 63                	push   $0x63
   103f7:	e9 44 fc ff ff       	jmp    10040 <isr_save>

000103fc <isr_0x64>:
ISR(0x64);	ISR(0x65);	ISR(0x66);	ISR(0x67);
   103fc:	6a 00                	push   $0x0
   103fe:	6a 64                	push   $0x64
   10400:	e9 3b fc ff ff       	jmp    10040 <isr_save>

00010405 <isr_0x65>:
   10405:	6a 00                	push   $0x0
   10407:	6a 65                	push   $0x65
   10409:	e9 32 fc ff ff       	jmp    10040 <isr_save>

0001040e <isr_0x66>:
   1040e:	6a 00                	push   $0x0
   10410:	6a 66                	push   $0x66
   10412:	e9 29 fc ff ff       	jmp    10040 <isr_save>

00010417 <isr_0x67>:
   10417:	6a 00                	push   $0x0
   10419:	6a 67                	push   $0x67
   1041b:	e9 20 fc ff ff       	jmp    10040 <isr_save>

00010420 <isr_0x68>:
ISR(0x68);	ISR(0x69);	ISR(0x6a);	ISR(0x6b);
   10420:	6a 00                	push   $0x0
   10422:	6a 68                	push   $0x68
   10424:	e9 17 fc ff ff       	jmp    10040 <isr_save>

00010429 <isr_0x69>:
   10429:	6a 00                	push   $0x0
   1042b:	6a 69                	push   $0x69
   1042d:	e9 0e fc ff ff       	jmp    10040 <isr_save>

00010432 <isr_0x6a>:
   10432:	6a 00                	push   $0x0
   10434:	6a 6a                	push   $0x6a
   10436:	e9 05 fc ff ff       	jmp    10040 <isr_save>

0001043b <isr_0x6b>:
   1043b:	6a 00                	push   $0x0
   1043d:	6a 6b                	push   $0x6b
   1043f:	e9 fc fb ff ff       	jmp    10040 <isr_save>

00010444 <isr_0x6c>:
ISR(0x6c);	ISR(0x6d);	ISR(0x6e);	ISR(0x6f);
   10444:	6a 00                	push   $0x0
   10446:	6a 6c                	push   $0x6c
   10448:	e9 f3 fb ff ff       	jmp    10040 <isr_save>

0001044d <isr_0x6d>:
   1044d:	6a 00                	push   $0x0
   1044f:	6a 6d                	push   $0x6d
   10451:	e9 ea fb ff ff       	jmp    10040 <isr_save>

00010456 <isr_0x6e>:
   10456:	6a 00                	push   $0x0
   10458:	6a 6e                	push   $0x6e
   1045a:	e9 e1 fb ff ff       	jmp    10040 <isr_save>

0001045f <isr_0x6f>:
   1045f:	6a 00                	push   $0x0
   10461:	6a 6f                	push   $0x6f
   10463:	e9 d8 fb ff ff       	jmp    10040 <isr_save>

00010468 <isr_0x70>:
ISR(0x70);	ISR(0x71);	ISR(0x72);	ISR(0x73);
   10468:	6a 00                	push   $0x0
   1046a:	6a 70                	push   $0x70
   1046c:	e9 cf fb ff ff       	jmp    10040 <isr_save>

00010471 <isr_0x71>:
   10471:	6a 00                	push   $0x0
   10473:	6a 71                	push   $0x71
   10475:	e9 c6 fb ff ff       	jmp    10040 <isr_save>

0001047a <isr_0x72>:
   1047a:	6a 00                	push   $0x0
   1047c:	6a 72                	push   $0x72
   1047e:	e9 bd fb ff ff       	jmp    10040 <isr_save>

00010483 <isr_0x73>:
   10483:	6a 00                	push   $0x0
   10485:	6a 73                	push   $0x73
   10487:	e9 b4 fb ff ff       	jmp    10040 <isr_save>

0001048c <isr_0x74>:
ISR(0x74);	ISR(0x75);	ISR(0x76);	ISR(0x77);
   1048c:	6a 00                	push   $0x0
   1048e:	6a 74                	push   $0x74
   10490:	e9 ab fb ff ff       	jmp    10040 <isr_save>

00010495 <isr_0x75>:
   10495:	6a 00                	push   $0x0
   10497:	6a 75                	push   $0x75
   10499:	e9 a2 fb ff ff       	jmp    10040 <isr_save>

0001049e <isr_0x76>:
   1049e:	6a 00                	push   $0x0
   104a0:	6a 76                	push   $0x76
   104a2:	e9 99 fb ff ff       	jmp    10040 <isr_save>

000104a7 <isr_0x77>:
   104a7:	6a 00                	push   $0x0
   104a9:	6a 77                	push   $0x77
   104ab:	e9 90 fb ff ff       	jmp    10040 <isr_save>

000104b0 <isr_0x78>:
ISR(0x78);	ISR(0x79);	ISR(0x7a);	ISR(0x7b);
   104b0:	6a 00                	push   $0x0
   104b2:	6a 78                	push   $0x78
   104b4:	e9 87 fb ff ff       	jmp    10040 <isr_save>

000104b9 <isr_0x79>:
   104b9:	6a 00                	push   $0x0
   104bb:	6a 79                	push   $0x79
   104bd:	e9 7e fb ff ff       	jmp    10040 <isr_save>

000104c2 <isr_0x7a>:
   104c2:	6a 00                	push   $0x0
   104c4:	6a 7a                	push   $0x7a
   104c6:	e9 75 fb ff ff       	jmp    10040 <isr_save>

000104cb <isr_0x7b>:
   104cb:	6a 00                	push   $0x0
   104cd:	6a 7b                	push   $0x7b
   104cf:	e9 6c fb ff ff       	jmp    10040 <isr_save>

000104d4 <isr_0x7c>:
ISR(0x7c);	ISR(0x7d);	ISR(0x7e);	ISR(0x7f);
   104d4:	6a 00                	push   $0x0
   104d6:	6a 7c                	push   $0x7c
   104d8:	e9 63 fb ff ff       	jmp    10040 <isr_save>

000104dd <isr_0x7d>:
   104dd:	6a 00                	push   $0x0
   104df:	6a 7d                	push   $0x7d
   104e1:	e9 5a fb ff ff       	jmp    10040 <isr_save>

000104e6 <isr_0x7e>:
   104e6:	6a 00                	push   $0x0
   104e8:	6a 7e                	push   $0x7e
   104ea:	e9 51 fb ff ff       	jmp    10040 <isr_save>

000104ef <isr_0x7f>:
   104ef:	6a 00                	push   $0x0
   104f1:	6a 7f                	push   $0x7f
   104f3:	e9 48 fb ff ff       	jmp    10040 <isr_save>

000104f8 <isr_0x80>:
ISR(0x80);	ISR(0x81);	ISR(0x82);	ISR(0x83);
   104f8:	6a 00                	push   $0x0
   104fa:	68 80 00 00 00       	push   $0x80
   104ff:	e9 3c fb ff ff       	jmp    10040 <isr_save>

00010504 <isr_0x81>:
   10504:	6a 00                	push   $0x0
   10506:	68 81 00 00 00       	push   $0x81
   1050b:	e9 30 fb ff ff       	jmp    10040 <isr_save>

00010510 <isr_0x82>:
   10510:	6a 00                	push   $0x0
   10512:	68 82 00 00 00       	push   $0x82
   10517:	e9 24 fb ff ff       	jmp    10040 <isr_save>

0001051c <isr_0x83>:
   1051c:	6a 00                	push   $0x0
   1051e:	68 83 00 00 00       	push   $0x83
   10523:	e9 18 fb ff ff       	jmp    10040 <isr_save>

00010528 <isr_0x84>:
ISR(0x84);	ISR(0x85);	ISR(0x86);	ISR(0x87);
   10528:	6a 00                	push   $0x0
   1052a:	68 84 00 00 00       	push   $0x84
   1052f:	e9 0c fb ff ff       	jmp    10040 <isr_save>

00010534 <isr_0x85>:
   10534:	6a 00                	push   $0x0
   10536:	68 85 00 00 00       	push   $0x85
   1053b:	e9 00 fb ff ff       	jmp    10040 <isr_save>

00010540 <isr_0x86>:
   10540:	6a 00                	push   $0x0
   10542:	68 86 00 00 00       	push   $0x86
   10547:	e9 f4 fa ff ff       	jmp    10040 <isr_save>

0001054c <isr_0x87>:
   1054c:	6a 00                	push   $0x0
   1054e:	68 87 00 00 00       	push   $0x87
   10553:	e9 e8 fa ff ff       	jmp    10040 <isr_save>

00010558 <isr_0x88>:
ISR(0x88);	ISR(0x89);	ISR(0x8a);	ISR(0x8b);
   10558:	6a 00                	push   $0x0
   1055a:	68 88 00 00 00       	push   $0x88
   1055f:	e9 dc fa ff ff       	jmp    10040 <isr_save>

00010564 <isr_0x89>:
   10564:	6a 00                	push   $0x0
   10566:	68 89 00 00 00       	push   $0x89
   1056b:	e9 d0 fa ff ff       	jmp    10040 <isr_save>

00010570 <isr_0x8a>:
   10570:	6a 00                	push   $0x0
   10572:	68 8a 00 00 00       	push   $0x8a
   10577:	e9 c4 fa ff ff       	jmp    10040 <isr_save>

0001057c <isr_0x8b>:
   1057c:	6a 00                	push   $0x0
   1057e:	68 8b 00 00 00       	push   $0x8b
   10583:	e9 b8 fa ff ff       	jmp    10040 <isr_save>

00010588 <isr_0x8c>:
ISR(0x8c);	ISR(0x8d);	ISR(0x8e);	ISR(0x8f);
   10588:	6a 00                	push   $0x0
   1058a:	68 8c 00 00 00       	push   $0x8c
   1058f:	e9 ac fa ff ff       	jmp    10040 <isr_save>

00010594 <isr_0x8d>:
   10594:	6a 00                	push   $0x0
   10596:	68 8d 00 00 00       	push   $0x8d
   1059b:	e9 a0 fa ff ff       	jmp    10040 <isr_save>

000105a0 <isr_0x8e>:
   105a0:	6a 00                	push   $0x0
   105a2:	68 8e 00 00 00       	push   $0x8e
   105a7:	e9 94 fa ff ff       	jmp    10040 <isr_save>

000105ac <isr_0x8f>:
   105ac:	6a 00                	push   $0x0
   105ae:	68 8f 00 00 00       	push   $0x8f
   105b3:	e9 88 fa ff ff       	jmp    10040 <isr_save>

000105b8 <isr_0x90>:
ISR(0x90);	ISR(0x91);	ISR(0x92);	ISR(0x93);
   105b8:	6a 00                	push   $0x0
   105ba:	68 90 00 00 00       	push   $0x90
   105bf:	e9 7c fa ff ff       	jmp    10040 <isr_save>

000105c4 <isr_0x91>:
   105c4:	6a 00                	push   $0x0
   105c6:	68 91 00 00 00       	push   $0x91
   105cb:	e9 70 fa ff ff       	jmp    10040 <isr_save>

000105d0 <isr_0x92>:
   105d0:	6a 00                	push   $0x0
   105d2:	68 92 00 00 00       	push   $0x92
   105d7:	e9 64 fa ff ff       	jmp    10040 <isr_save>

000105dc <isr_0x93>:
   105dc:	6a 00                	push   $0x0
   105de:	68 93 00 00 00       	push   $0x93
   105e3:	e9 58 fa ff ff       	jmp    10040 <isr_save>

000105e8 <isr_0x94>:
ISR(0x94);	ISR(0x95);	ISR(0x96);	ISR(0x97);
   105e8:	6a 00                	push   $0x0
   105ea:	68 94 00 00 00       	push   $0x94
   105ef:	e9 4c fa ff ff       	jmp    10040 <isr_save>

000105f4 <isr_0x95>:
   105f4:	6a 00                	push   $0x0
   105f6:	68 95 00 00 00       	push   $0x95
   105fb:	e9 40 fa ff ff       	jmp    10040 <isr_save>

00010600 <isr_0x96>:
   10600:	6a 00                	push   $0x0
   10602:	68 96 00 00 00       	push   $0x96
   10607:	e9 34 fa ff ff       	jmp    10040 <isr_save>

0001060c <isr_0x97>:
   1060c:	6a 00                	push   $0x0
   1060e:	68 97 00 00 00       	push   $0x97
   10613:	e9 28 fa ff ff       	jmp    10040 <isr_save>

00010618 <isr_0x98>:
ISR(0x98);	ISR(0x99);	ISR(0x9a);	ISR(0x9b);
   10618:	6a 00                	push   $0x0
   1061a:	68 98 00 00 00       	push   $0x98
   1061f:	e9 1c fa ff ff       	jmp    10040 <isr_save>

00010624 <isr_0x99>:
   10624:	6a 00                	push   $0x0
   10626:	68 99 00 00 00       	push   $0x99
   1062b:	e9 10 fa ff ff       	jmp    10040 <isr_save>

00010630 <isr_0x9a>:
   10630:	6a 00                	push   $0x0
   10632:	68 9a 00 00 00       	push   $0x9a
   10637:	e9 04 fa ff ff       	jmp    10040 <isr_save>

0001063c <isr_0x9b>:
   1063c:	6a 00                	push   $0x0
   1063e:	68 9b 00 00 00       	push   $0x9b
   10643:	e9 f8 f9 ff ff       	jmp    10040 <isr_save>

00010648 <isr_0x9c>:
ISR(0x9c);	ISR(0x9d);	ISR(0x9e);	ISR(0x9f);
   10648:	6a 00                	push   $0x0
   1064a:	68 9c 00 00 00       	push   $0x9c
   1064f:	e9 ec f9 ff ff       	jmp    10040 <isr_save>

00010654 <isr_0x9d>:
   10654:	6a 00                	push   $0x0
   10656:	68 9d 00 00 00       	push   $0x9d
   1065b:	e9 e0 f9 ff ff       	jmp    10040 <isr_save>

00010660 <isr_0x9e>:
   10660:	6a 00                	push   $0x0
   10662:	68 9e 00 00 00       	push   $0x9e
   10667:	e9 d4 f9 ff ff       	jmp    10040 <isr_save>

0001066c <isr_0x9f>:
   1066c:	6a 00                	push   $0x0
   1066e:	68 9f 00 00 00       	push   $0x9f
   10673:	e9 c8 f9 ff ff       	jmp    10040 <isr_save>

00010678 <isr_0xa0>:
ISR(0xa0);	ISR(0xa1);	ISR(0xa2);	ISR(0xa3);
   10678:	6a 00                	push   $0x0
   1067a:	68 a0 00 00 00       	push   $0xa0
   1067f:	e9 bc f9 ff ff       	jmp    10040 <isr_save>

00010684 <isr_0xa1>:
   10684:	6a 00                	push   $0x0
   10686:	68 a1 00 00 00       	push   $0xa1
   1068b:	e9 b0 f9 ff ff       	jmp    10040 <isr_save>

00010690 <isr_0xa2>:
   10690:	6a 00                	push   $0x0
   10692:	68 a2 00 00 00       	push   $0xa2
   10697:	e9 a4 f9 ff ff       	jmp    10040 <isr_save>

0001069c <isr_0xa3>:
   1069c:	6a 00                	push   $0x0
   1069e:	68 a3 00 00 00       	push   $0xa3
   106a3:	e9 98 f9 ff ff       	jmp    10040 <isr_save>

000106a8 <isr_0xa4>:
ISR(0xa4);	ISR(0xa5);	ISR(0xa6);	ISR(0xa7);
   106a8:	6a 00                	push   $0x0
   106aa:	68 a4 00 00 00       	push   $0xa4
   106af:	e9 8c f9 ff ff       	jmp    10040 <isr_save>

000106b4 <isr_0xa5>:
   106b4:	6a 00                	push   $0x0
   106b6:	68 a5 00 00 00       	push   $0xa5
   106bb:	e9 80 f9 ff ff       	jmp    10040 <isr_save>

000106c0 <isr_0xa6>:
   106c0:	6a 00                	push   $0x0
   106c2:	68 a6 00 00 00       	push   $0xa6
   106c7:	e9 74 f9 ff ff       	jmp    10040 <isr_save>

000106cc <isr_0xa7>:
   106cc:	6a 00                	push   $0x0
   106ce:	68 a7 00 00 00       	push   $0xa7
   106d3:	e9 68 f9 ff ff       	jmp    10040 <isr_save>

000106d8 <isr_0xa8>:
ISR(0xa8);	ISR(0xa9);	ISR(0xaa);	ISR(0xab);
   106d8:	6a 00                	push   $0x0
   106da:	68 a8 00 00 00       	push   $0xa8
   106df:	e9 5c f9 ff ff       	jmp    10040 <isr_save>

000106e4 <isr_0xa9>:
   106e4:	6a 00                	push   $0x0
   106e6:	68 a9 00 00 00       	push   $0xa9
   106eb:	e9 50 f9 ff ff       	jmp    10040 <isr_save>

000106f0 <isr_0xaa>:
   106f0:	6a 00                	push   $0x0
   106f2:	68 aa 00 00 00       	push   $0xaa
   106f7:	e9 44 f9 ff ff       	jmp    10040 <isr_save>

000106fc <isr_0xab>:
   106fc:	6a 00                	push   $0x0
   106fe:	68 ab 00 00 00       	push   $0xab
   10703:	e9 38 f9 ff ff       	jmp    10040 <isr_save>

00010708 <isr_0xac>:
ISR(0xac);	ISR(0xad);	ISR(0xae);	ISR(0xaf);
   10708:	6a 00                	push   $0x0
   1070a:	68 ac 00 00 00       	push   $0xac
   1070f:	e9 2c f9 ff ff       	jmp    10040 <isr_save>

00010714 <isr_0xad>:
   10714:	6a 00                	push   $0x0
   10716:	68 ad 00 00 00       	push   $0xad
   1071b:	e9 20 f9 ff ff       	jmp    10040 <isr_save>

00010720 <isr_0xae>:
   10720:	6a 00                	push   $0x0
   10722:	68 ae 00 00 00       	push   $0xae
   10727:	e9 14 f9 ff ff       	jmp    10040 <isr_save>

0001072c <isr_0xaf>:
   1072c:	6a 00                	push   $0x0
   1072e:	68 af 00 00 00       	push   $0xaf
   10733:	e9 08 f9 ff ff       	jmp    10040 <isr_save>

00010738 <isr_0xb0>:
ISR(0xb0);	ISR(0xb1);	ISR(0xb2);	ISR(0xb3);
   10738:	6a 00                	push   $0x0
   1073a:	68 b0 00 00 00       	push   $0xb0
   1073f:	e9 fc f8 ff ff       	jmp    10040 <isr_save>

00010744 <isr_0xb1>:
   10744:	6a 00                	push   $0x0
   10746:	68 b1 00 00 00       	push   $0xb1
   1074b:	e9 f0 f8 ff ff       	jmp    10040 <isr_save>

00010750 <isr_0xb2>:
   10750:	6a 00                	push   $0x0
   10752:	68 b2 00 00 00       	push   $0xb2
   10757:	e9 e4 f8 ff ff       	jmp    10040 <isr_save>

0001075c <isr_0xb3>:
   1075c:	6a 00                	push   $0x0
   1075e:	68 b3 00 00 00       	push   $0xb3
   10763:	e9 d8 f8 ff ff       	jmp    10040 <isr_save>

00010768 <isr_0xb4>:
ISR(0xb4);	ISR(0xb5);	ISR(0xb6);	ISR(0xb7);
   10768:	6a 00                	push   $0x0
   1076a:	68 b4 00 00 00       	push   $0xb4
   1076f:	e9 cc f8 ff ff       	jmp    10040 <isr_save>

00010774 <isr_0xb5>:
   10774:	6a 00                	push   $0x0
   10776:	68 b5 00 00 00       	push   $0xb5
   1077b:	e9 c0 f8 ff ff       	jmp    10040 <isr_save>

00010780 <isr_0xb6>:
   10780:	6a 00                	push   $0x0
   10782:	68 b6 00 00 00       	push   $0xb6
   10787:	e9 b4 f8 ff ff       	jmp    10040 <isr_save>

0001078c <isr_0xb7>:
   1078c:	6a 00                	push   $0x0
   1078e:	68 b7 00 00 00       	push   $0xb7
   10793:	e9 a8 f8 ff ff       	jmp    10040 <isr_save>

00010798 <isr_0xb8>:
ISR(0xb8);	ISR(0xb9);	ISR(0xba);	ISR(0xbb);
   10798:	6a 00                	push   $0x0
   1079a:	68 b8 00 00 00       	push   $0xb8
   1079f:	e9 9c f8 ff ff       	jmp    10040 <isr_save>

000107a4 <isr_0xb9>:
   107a4:	6a 00                	push   $0x0
   107a6:	68 b9 00 00 00       	push   $0xb9
   107ab:	e9 90 f8 ff ff       	jmp    10040 <isr_save>

000107b0 <isr_0xba>:
   107b0:	6a 00                	push   $0x0
   107b2:	68 ba 00 00 00       	push   $0xba
   107b7:	e9 84 f8 ff ff       	jmp    10040 <isr_save>

000107bc <isr_0xbb>:
   107bc:	6a 00                	push   $0x0
   107be:	68 bb 00 00 00       	push   $0xbb
   107c3:	e9 78 f8 ff ff       	jmp    10040 <isr_save>

000107c8 <isr_0xbc>:
ISR(0xbc);	ISR(0xbd);	ISR(0xbe);	ISR(0xbf);
   107c8:	6a 00                	push   $0x0
   107ca:	68 bc 00 00 00       	push   $0xbc
   107cf:	e9 6c f8 ff ff       	jmp    10040 <isr_save>

000107d4 <isr_0xbd>:
   107d4:	6a 00                	push   $0x0
   107d6:	68 bd 00 00 00       	push   $0xbd
   107db:	e9 60 f8 ff ff       	jmp    10040 <isr_save>

000107e0 <isr_0xbe>:
   107e0:	6a 00                	push   $0x0
   107e2:	68 be 00 00 00       	push   $0xbe
   107e7:	e9 54 f8 ff ff       	jmp    10040 <isr_save>

000107ec <isr_0xbf>:
   107ec:	6a 00                	push   $0x0
   107ee:	68 bf 00 00 00       	push   $0xbf
   107f3:	e9 48 f8 ff ff       	jmp    10040 <isr_save>

000107f8 <isr_0xc0>:
ISR(0xc0);	ISR(0xc1);	ISR(0xc2);	ISR(0xc3);
   107f8:	6a 00                	push   $0x0
   107fa:	68 c0 00 00 00       	push   $0xc0
   107ff:	e9 3c f8 ff ff       	jmp    10040 <isr_save>

00010804 <isr_0xc1>:
   10804:	6a 00                	push   $0x0
   10806:	68 c1 00 00 00       	push   $0xc1
   1080b:	e9 30 f8 ff ff       	jmp    10040 <isr_save>

00010810 <isr_0xc2>:
   10810:	6a 00                	push   $0x0
   10812:	68 c2 00 00 00       	push   $0xc2
   10817:	e9 24 f8 ff ff       	jmp    10040 <isr_save>

0001081c <isr_0xc3>:
   1081c:	6a 00                	push   $0x0
   1081e:	68 c3 00 00 00       	push   $0xc3
   10823:	e9 18 f8 ff ff       	jmp    10040 <isr_save>

00010828 <isr_0xc4>:
ISR(0xc4);	ISR(0xc5);	ISR(0xc6);	ISR(0xc7);
   10828:	6a 00                	push   $0x0
   1082a:	68 c4 00 00 00       	push   $0xc4
   1082f:	e9 0c f8 ff ff       	jmp    10040 <isr_save>

00010834 <isr_0xc5>:
   10834:	6a 00                	push   $0x0
   10836:	68 c5 00 00 00       	push   $0xc5
   1083b:	e9 00 f8 ff ff       	jmp    10040 <isr_save>

00010840 <isr_0xc6>:
   10840:	6a 00                	push   $0x0
   10842:	68 c6 00 00 00       	push   $0xc6
   10847:	e9 f4 f7 ff ff       	jmp    10040 <isr_save>

0001084c <isr_0xc7>:
   1084c:	6a 00                	push   $0x0
   1084e:	68 c7 00 00 00       	push   $0xc7
   10853:	e9 e8 f7 ff ff       	jmp    10040 <isr_save>

00010858 <isr_0xc8>:
ISR(0xc8);	ISR(0xc9);	ISR(0xca);	ISR(0xcb);
   10858:	6a 00                	push   $0x0
   1085a:	68 c8 00 00 00       	push   $0xc8
   1085f:	e9 dc f7 ff ff       	jmp    10040 <isr_save>

00010864 <isr_0xc9>:
   10864:	6a 00                	push   $0x0
   10866:	68 c9 00 00 00       	push   $0xc9
   1086b:	e9 d0 f7 ff ff       	jmp    10040 <isr_save>

00010870 <isr_0xca>:
   10870:	6a 00                	push   $0x0
   10872:	68 ca 00 00 00       	push   $0xca
   10877:	e9 c4 f7 ff ff       	jmp    10040 <isr_save>

0001087c <isr_0xcb>:
   1087c:	6a 00                	push   $0x0
   1087e:	68 cb 00 00 00       	push   $0xcb
   10883:	e9 b8 f7 ff ff       	jmp    10040 <isr_save>

00010888 <isr_0xcc>:
ISR(0xcc);	ISR(0xcd);	ISR(0xce);	ISR(0xcf);
   10888:	6a 00                	push   $0x0
   1088a:	68 cc 00 00 00       	push   $0xcc
   1088f:	e9 ac f7 ff ff       	jmp    10040 <isr_save>

00010894 <isr_0xcd>:
   10894:	6a 00                	push   $0x0
   10896:	68 cd 00 00 00       	push   $0xcd
   1089b:	e9 a0 f7 ff ff       	jmp    10040 <isr_save>

000108a0 <isr_0xce>:
   108a0:	6a 00                	push   $0x0
   108a2:	68 ce 00 00 00       	push   $0xce
   108a7:	e9 94 f7 ff ff       	jmp    10040 <isr_save>

000108ac <isr_0xcf>:
   108ac:	6a 00                	push   $0x0
   108ae:	68 cf 00 00 00       	push   $0xcf
   108b3:	e9 88 f7 ff ff       	jmp    10040 <isr_save>

000108b8 <isr_0xd0>:
ISR(0xd0);	ISR(0xd1);	ISR(0xd2);	ISR(0xd3);
   108b8:	6a 00                	push   $0x0
   108ba:	68 d0 00 00 00       	push   $0xd0
   108bf:	e9 7c f7 ff ff       	jmp    10040 <isr_save>

000108c4 <isr_0xd1>:
   108c4:	6a 00                	push   $0x0
   108c6:	68 d1 00 00 00       	push   $0xd1
   108cb:	e9 70 f7 ff ff       	jmp    10040 <isr_save>

000108d0 <isr_0xd2>:
   108d0:	6a 00                	push   $0x0
   108d2:	68 d2 00 00 00       	push   $0xd2
   108d7:	e9 64 f7 ff ff       	jmp    10040 <isr_save>

000108dc <isr_0xd3>:
   108dc:	6a 00                	push   $0x0
   108de:	68 d3 00 00 00       	push   $0xd3
   108e3:	e9 58 f7 ff ff       	jmp    10040 <isr_save>

000108e8 <isr_0xd4>:
ISR(0xd4);	ISR(0xd5);	ISR(0xd6);	ISR(0xd7);
   108e8:	6a 00                	push   $0x0
   108ea:	68 d4 00 00 00       	push   $0xd4
   108ef:	e9 4c f7 ff ff       	jmp    10040 <isr_save>

000108f4 <isr_0xd5>:
   108f4:	6a 00                	push   $0x0
   108f6:	68 d5 00 00 00       	push   $0xd5
   108fb:	e9 40 f7 ff ff       	jmp    10040 <isr_save>

00010900 <isr_0xd6>:
   10900:	6a 00                	push   $0x0
   10902:	68 d6 00 00 00       	push   $0xd6
   10907:	e9 34 f7 ff ff       	jmp    10040 <isr_save>

0001090c <isr_0xd7>:
   1090c:	6a 00                	push   $0x0
   1090e:	68 d7 00 00 00       	push   $0xd7
   10913:	e9 28 f7 ff ff       	jmp    10040 <isr_save>

00010918 <isr_0xd8>:
ISR(0xd8);	ISR(0xd9);	ISR(0xda);	ISR(0xdb);
   10918:	6a 00                	push   $0x0
   1091a:	68 d8 00 00 00       	push   $0xd8
   1091f:	e9 1c f7 ff ff       	jmp    10040 <isr_save>

00010924 <isr_0xd9>:
   10924:	6a 00                	push   $0x0
   10926:	68 d9 00 00 00       	push   $0xd9
   1092b:	e9 10 f7 ff ff       	jmp    10040 <isr_save>

00010930 <isr_0xda>:
   10930:	6a 00                	push   $0x0
   10932:	68 da 00 00 00       	push   $0xda
   10937:	e9 04 f7 ff ff       	jmp    10040 <isr_save>

0001093c <isr_0xdb>:
   1093c:	6a 00                	push   $0x0
   1093e:	68 db 00 00 00       	push   $0xdb
   10943:	e9 f8 f6 ff ff       	jmp    10040 <isr_save>

00010948 <isr_0xdc>:
ISR(0xdc);	ISR(0xdd);	ISR(0xde);	ISR(0xdf);
   10948:	6a 00                	push   $0x0
   1094a:	68 dc 00 00 00       	push   $0xdc
   1094f:	e9 ec f6 ff ff       	jmp    10040 <isr_save>

00010954 <isr_0xdd>:
   10954:	6a 00                	push   $0x0
   10956:	68 dd 00 00 00       	push   $0xdd
   1095b:	e9 e0 f6 ff ff       	jmp    10040 <isr_save>

00010960 <isr_0xde>:
   10960:	6a 00                	push   $0x0
   10962:	68 de 00 00 00       	push   $0xde
   10967:	e9 d4 f6 ff ff       	jmp    10040 <isr_save>

0001096c <isr_0xdf>:
   1096c:	6a 00                	push   $0x0
   1096e:	68 df 00 00 00       	push   $0xdf
   10973:	e9 c8 f6 ff ff       	jmp    10040 <isr_save>

00010978 <isr_0xe0>:
ISR(0xe0);	ISR(0xe1);	ISR(0xe2);	ISR(0xe3);
   10978:	6a 00                	push   $0x0
   1097a:	68 e0 00 00 00       	push   $0xe0
   1097f:	e9 bc f6 ff ff       	jmp    10040 <isr_save>

00010984 <isr_0xe1>:
   10984:	6a 00                	push   $0x0
   10986:	68 e1 00 00 00       	push   $0xe1
   1098b:	e9 b0 f6 ff ff       	jmp    10040 <isr_save>

00010990 <isr_0xe2>:
   10990:	6a 00                	push   $0x0
   10992:	68 e2 00 00 00       	push   $0xe2
   10997:	e9 a4 f6 ff ff       	jmp    10040 <isr_save>

0001099c <isr_0xe3>:
   1099c:	6a 00                	push   $0x0
   1099e:	68 e3 00 00 00       	push   $0xe3
   109a3:	e9 98 f6 ff ff       	jmp    10040 <isr_save>

000109a8 <isr_0xe4>:
ISR(0xe4);	ISR(0xe5);	ISR(0xe6);	ISR(0xe7);
   109a8:	6a 00                	push   $0x0
   109aa:	68 e4 00 00 00       	push   $0xe4
   109af:	e9 8c f6 ff ff       	jmp    10040 <isr_save>

000109b4 <isr_0xe5>:
   109b4:	6a 00                	push   $0x0
   109b6:	68 e5 00 00 00       	push   $0xe5
   109bb:	e9 80 f6 ff ff       	jmp    10040 <isr_save>

000109c0 <isr_0xe6>:
   109c0:	6a 00                	push   $0x0
   109c2:	68 e6 00 00 00       	push   $0xe6
   109c7:	e9 74 f6 ff ff       	jmp    10040 <isr_save>

000109cc <isr_0xe7>:
   109cc:	6a 00                	push   $0x0
   109ce:	68 e7 00 00 00       	push   $0xe7
   109d3:	e9 68 f6 ff ff       	jmp    10040 <isr_save>

000109d8 <isr_0xe8>:
ISR(0xe8);	ISR(0xe9);	ISR(0xea);	ISR(0xeb);
   109d8:	6a 00                	push   $0x0
   109da:	68 e8 00 00 00       	push   $0xe8
   109df:	e9 5c f6 ff ff       	jmp    10040 <isr_save>

000109e4 <isr_0xe9>:
   109e4:	6a 00                	push   $0x0
   109e6:	68 e9 00 00 00       	push   $0xe9
   109eb:	e9 50 f6 ff ff       	jmp    10040 <isr_save>

000109f0 <isr_0xea>:
   109f0:	6a 00                	push   $0x0
   109f2:	68 ea 00 00 00       	push   $0xea
   109f7:	e9 44 f6 ff ff       	jmp    10040 <isr_save>

000109fc <isr_0xeb>:
   109fc:	6a 00                	push   $0x0
   109fe:	68 eb 00 00 00       	push   $0xeb
   10a03:	e9 38 f6 ff ff       	jmp    10040 <isr_save>

00010a08 <isr_0xec>:
ISR(0xec);	ISR(0xed);	ISR(0xee);	ISR(0xef);
   10a08:	6a 00                	push   $0x0
   10a0a:	68 ec 00 00 00       	push   $0xec
   10a0f:	e9 2c f6 ff ff       	jmp    10040 <isr_save>

00010a14 <isr_0xed>:
   10a14:	6a 00                	push   $0x0
   10a16:	68 ed 00 00 00       	push   $0xed
   10a1b:	e9 20 f6 ff ff       	jmp    10040 <isr_save>

00010a20 <isr_0xee>:
   10a20:	6a 00                	push   $0x0
   10a22:	68 ee 00 00 00       	push   $0xee
   10a27:	e9 14 f6 ff ff       	jmp    10040 <isr_save>

00010a2c <isr_0xef>:
   10a2c:	6a 00                	push   $0x0
   10a2e:	68 ef 00 00 00       	push   $0xef
   10a33:	e9 08 f6 ff ff       	jmp    10040 <isr_save>

00010a38 <isr_0xf0>:
ISR(0xf0);	ISR(0xf1);	ISR(0xf2);	ISR(0xf3);
   10a38:	6a 00                	push   $0x0
   10a3a:	68 f0 00 00 00       	push   $0xf0
   10a3f:	e9 fc f5 ff ff       	jmp    10040 <isr_save>

00010a44 <isr_0xf1>:
   10a44:	6a 00                	push   $0x0
   10a46:	68 f1 00 00 00       	push   $0xf1
   10a4b:	e9 f0 f5 ff ff       	jmp    10040 <isr_save>

00010a50 <isr_0xf2>:
   10a50:	6a 00                	push   $0x0
   10a52:	68 f2 00 00 00       	push   $0xf2
   10a57:	e9 e4 f5 ff ff       	jmp    10040 <isr_save>

00010a5c <isr_0xf3>:
   10a5c:	6a 00                	push   $0x0
   10a5e:	68 f3 00 00 00       	push   $0xf3
   10a63:	e9 d8 f5 ff ff       	jmp    10040 <isr_save>

00010a68 <isr_0xf4>:
ISR(0xf4);	ISR(0xf5);	ISR(0xf6);	ISR(0xf7);
   10a68:	6a 00                	push   $0x0
   10a6a:	68 f4 00 00 00       	push   $0xf4
   10a6f:	e9 cc f5 ff ff       	jmp    10040 <isr_save>

00010a74 <isr_0xf5>:
   10a74:	6a 00                	push   $0x0
   10a76:	68 f5 00 00 00       	push   $0xf5
   10a7b:	e9 c0 f5 ff ff       	jmp    10040 <isr_save>

00010a80 <isr_0xf6>:
   10a80:	6a 00                	push   $0x0
   10a82:	68 f6 00 00 00       	push   $0xf6
   10a87:	e9 b4 f5 ff ff       	jmp    10040 <isr_save>

00010a8c <isr_0xf7>:
   10a8c:	6a 00                	push   $0x0
   10a8e:	68 f7 00 00 00       	push   $0xf7
   10a93:	e9 a8 f5 ff ff       	jmp    10040 <isr_save>

00010a98 <isr_0xf8>:
ISR(0xf8);	ISR(0xf9);	ISR(0xfa);	ISR(0xfb);
   10a98:	6a 00                	push   $0x0
   10a9a:	68 f8 00 00 00       	push   $0xf8
   10a9f:	e9 9c f5 ff ff       	jmp    10040 <isr_save>

00010aa4 <isr_0xf9>:
   10aa4:	6a 00                	push   $0x0
   10aa6:	68 f9 00 00 00       	push   $0xf9
   10aab:	e9 90 f5 ff ff       	jmp    10040 <isr_save>

00010ab0 <isr_0xfa>:
   10ab0:	6a 00                	push   $0x0
   10ab2:	68 fa 00 00 00       	push   $0xfa
   10ab7:	e9 84 f5 ff ff       	jmp    10040 <isr_save>

00010abc <isr_0xfb>:
   10abc:	6a 00                	push   $0x0
   10abe:	68 fb 00 00 00       	push   $0xfb
   10ac3:	e9 78 f5 ff ff       	jmp    10040 <isr_save>

00010ac8 <isr_0xfc>:
ISR(0xfc);	ISR(0xfd);	ISR(0xfe);	ISR(0xff);
   10ac8:	6a 00                	push   $0x0
   10aca:	68 fc 00 00 00       	push   $0xfc
   10acf:	e9 6c f5 ff ff       	jmp    10040 <isr_save>

00010ad4 <isr_0xfd>:
   10ad4:	6a 00                	push   $0x0
   10ad6:	68 fd 00 00 00       	push   $0xfd
   10adb:	e9 60 f5 ff ff       	jmp    10040 <isr_save>

00010ae0 <isr_0xfe>:
   10ae0:	6a 00                	push   $0x0
   10ae2:	68 fe 00 00 00       	push   $0xfe
   10ae7:	e9 54 f5 ff ff       	jmp    10040 <isr_save>

00010aec <isr_0xff>:
   10aec:	6a 00                	push   $0x0
   10aee:	68 ff 00 00 00       	push   $0xff
   10af3:	e9 48 f5 ff ff       	jmp    10040 <isr_save>

00010af8 <setcursor>:
*/

/*
** setcursor: set the cursor location (screen coordinates)
*/
static void setcursor( void ) {
   10af8:	55                   	push   %ebp
   10af9:	89 e5                	mov    %esp,%ebp
   10afb:	83 ec 30             	sub    $0x30,%esp
	unsigned addr;
	unsigned int y = curr_y;
   10afe:	a1 14 e0 01 00       	mov    0x1e014,%eax
   10b03:	89 45 fc             	mov    %eax,-0x4(%ebp)

	if( y > scroll_max_y ) {
   10b06:	a1 0c e0 01 00       	mov    0x1e00c,%eax
   10b0b:	39 45 fc             	cmp    %eax,-0x4(%ebp)
   10b0e:	76 08                	jbe    10b18 <setcursor+0x20>
		y = scroll_max_y;
   10b10:	a1 0c e0 01 00       	mov    0x1e00c,%eax
   10b15:	89 45 fc             	mov    %eax,-0x4(%ebp)
	}

	addr = (unsigned)( y * SCREEN_X_SIZE + curr_x );
   10b18:	8b 55 fc             	mov    -0x4(%ebp),%edx
   10b1b:	89 d0                	mov    %edx,%eax
   10b1d:	c1 e0 02             	shl    $0x2,%eax
   10b20:	01 d0                	add    %edx,%eax
   10b22:	c1 e0 04             	shl    $0x4,%eax
   10b25:	89 c2                	mov    %eax,%edx
   10b27:	a1 10 e0 01 00       	mov    0x1e010,%eax
   10b2c:	01 d0                	add    %edx,%eax
   10b2e:	89 45 f8             	mov    %eax,-0x8(%ebp)
   10b31:	c7 45 dc d4 03 00 00 	movl   $0x3d4,-0x24(%ebp)
   10b38:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
** @return The data read from the specified port
*/
OPSINLINED static inline void
outb( int port, uint8_t data )
{
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   10b3c:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   10b40:	8b 55 dc             	mov    -0x24(%ebp),%edx
   10b43:	ee                   	out    %al,(%dx)

	outb( VGA_CTRL_IX_ADDR, VGA_CTRL_CUR_HIGH );
	outb( VGA_CTRL_IX_DATA, ( addr >> 8 ) & BMASK8 );
   10b44:	8b 45 f8             	mov    -0x8(%ebp),%eax
   10b47:	c1 e8 08             	shr    $0x8,%eax
   10b4a:	0f b6 c0             	movzbl %al,%eax
   10b4d:	c7 45 e4 d5 03 00 00 	movl   $0x3d5,-0x1c(%ebp)
   10b54:	88 45 e3             	mov    %al,-0x1d(%ebp)
   10b57:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
   10b5b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   10b5e:	ee                   	out    %al,(%dx)
   10b5f:	c7 45 ec d4 03 00 00 	movl   $0x3d4,-0x14(%ebp)
   10b66:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
   10b6a:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   10b6e:	8b 55 ec             	mov    -0x14(%ebp),%edx
   10b71:	ee                   	out    %al,(%dx)
	outb( VGA_CTRL_IX_ADDR, VGA_CTRL_CUR_LOW );
	outb( VGA_CTRL_IX_DATA, addr & BMASK8 );
   10b72:	8b 45 f8             	mov    -0x8(%ebp),%eax
   10b75:	0f b6 c0             	movzbl %al,%eax
   10b78:	c7 45 f4 d5 03 00 00 	movl   $0x3d5,-0xc(%ebp)
   10b7f:	88 45 f3             	mov    %al,-0xd(%ebp)
   10b82:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   10b86:	8b 55 f4             	mov    -0xc(%ebp),%edx
   10b89:	ee                   	out    %al,(%dx)
}
   10b8a:	90                   	nop
   10b8b:	c9                   	leave  
   10b8c:	c3                   	ret    

00010b8d <putchar_at>:

/*
** putchar_at: physical output to the video memory
*/
static void putchar_at( unsigned int x, unsigned int y, unsigned int c ) {
   10b8d:	55                   	push   %ebp
   10b8e:	89 e5                	mov    %esp,%ebp
   10b90:	83 ec 10             	sub    $0x10,%esp
	/*
	** If x or y is too big or small, don't do any output.
	*/
	if( x <= max_x && y <= max_y ) {
   10b93:	a1 20 e0 01 00       	mov    0x1e020,%eax
   10b98:	39 45 08             	cmp    %eax,0x8(%ebp)
   10b9b:	77 53                	ja     10bf0 <putchar_at+0x63>
   10b9d:	a1 24 e0 01 00       	mov    0x1e024,%eax
   10ba2:	39 45 0c             	cmp    %eax,0xc(%ebp)
   10ba5:	77 49                	ja     10bf0 <putchar_at+0x63>
		unsigned short *addr = VIDEO_ADDR( x, y );
   10ba7:	8b 55 0c             	mov    0xc(%ebp),%edx
   10baa:	89 d0                	mov    %edx,%eax
   10bac:	c1 e0 02             	shl    $0x2,%eax
   10baf:	01 d0                	add    %edx,%eax
   10bb1:	c1 e0 04             	shl    $0x4,%eax
   10bb4:	89 c2                	mov    %eax,%edx
   10bb6:	8b 45 08             	mov    0x8(%ebp),%eax
   10bb9:	01 d0                	add    %edx,%eax
   10bbb:	05 00 c0 05 00       	add    $0x5c000,%eax
   10bc0:	01 c0                	add    %eax,%eax
   10bc2:	89 45 fc             	mov    %eax,-0x4(%ebp)

		/*
		** The character may have attributes associated with it; if
		** so, use those, otherwise use white on black.
		*/
		c &= 0xffff;	// keep only the lower bytes
   10bc5:	81 65 10 ff ff 00 00 	andl   $0xffff,0x10(%ebp)
		if( c > BMASK8 ) {
   10bcc:	81 7d 10 ff 00 00 00 	cmpl   $0xff,0x10(%ebp)
   10bd3:	76 0d                	jbe    10be2 <putchar_at+0x55>
			*addr = (unsigned short)c;
   10bd5:	8b 45 10             	mov    0x10(%ebp),%eax
   10bd8:	89 c2                	mov    %eax,%edx
   10bda:	8b 45 fc             	mov    -0x4(%ebp),%eax
   10bdd:	66 89 10             	mov    %dx,(%eax)
		} else {
			*addr = (unsigned short)c | VGA_DEFAULT;
		}
	}
}
   10be0:	eb 0e                	jmp    10bf0 <putchar_at+0x63>
			*addr = (unsigned short)c | VGA_DEFAULT;
   10be2:	8b 45 10             	mov    0x10(%ebp),%eax
   10be5:	80 cc 07             	or     $0x7,%ah
   10be8:	89 c2                	mov    %eax,%edx
   10bea:	8b 45 fc             	mov    -0x4(%ebp),%eax
   10bed:	66 89 10             	mov    %dx,(%eax)
}
   10bf0:	90                   	nop
   10bf1:	c9                   	leave  
   10bf2:	c3                   	ret    

00010bf3 <cio_setscroll>:

/*
** Set the scrolling region
*/
void cio_setscroll( unsigned int s_min_x, unsigned int s_min_y,
					  unsigned int s_max_x, unsigned int s_max_y ) {
   10bf3:	55                   	push   %ebp
   10bf4:	89 e5                	mov    %esp,%ebp
   10bf6:	83 ec 08             	sub    $0x8,%esp
	scroll_min_x = bound( min_x, s_min_x, max_x );
   10bf9:	8b 15 20 e0 01 00    	mov    0x1e020,%edx
   10bff:	a1 18 e0 01 00       	mov    0x1e018,%eax
   10c04:	83 ec 04             	sub    $0x4,%esp
   10c07:	52                   	push   %edx
   10c08:	ff 75 08             	pushl  0x8(%ebp)
   10c0b:	50                   	push   %eax
   10c0c:	e8 cf 14 00 00       	call   120e0 <bound>
   10c11:	83 c4 10             	add    $0x10,%esp
   10c14:	a3 00 e0 01 00       	mov    %eax,0x1e000
	scroll_min_y = bound( min_y, s_min_y, max_y );
   10c19:	8b 15 24 e0 01 00    	mov    0x1e024,%edx
   10c1f:	a1 1c e0 01 00       	mov    0x1e01c,%eax
   10c24:	83 ec 04             	sub    $0x4,%esp
   10c27:	52                   	push   %edx
   10c28:	ff 75 0c             	pushl  0xc(%ebp)
   10c2b:	50                   	push   %eax
   10c2c:	e8 af 14 00 00       	call   120e0 <bound>
   10c31:	83 c4 10             	add    $0x10,%esp
   10c34:	a3 04 e0 01 00       	mov    %eax,0x1e004
	scroll_max_x = bound( scroll_min_x, s_max_x, max_x );
   10c39:	8b 15 20 e0 01 00    	mov    0x1e020,%edx
   10c3f:	a1 00 e0 01 00       	mov    0x1e000,%eax
   10c44:	83 ec 04             	sub    $0x4,%esp
   10c47:	52                   	push   %edx
   10c48:	ff 75 10             	pushl  0x10(%ebp)
   10c4b:	50                   	push   %eax
   10c4c:	e8 8f 14 00 00       	call   120e0 <bound>
   10c51:	83 c4 10             	add    $0x10,%esp
   10c54:	a3 08 e0 01 00       	mov    %eax,0x1e008
	scroll_max_y = bound( scroll_min_y, s_max_y, max_y );
   10c59:	8b 15 24 e0 01 00    	mov    0x1e024,%edx
   10c5f:	a1 04 e0 01 00       	mov    0x1e004,%eax
   10c64:	83 ec 04             	sub    $0x4,%esp
   10c67:	52                   	push   %edx
   10c68:	ff 75 14             	pushl  0x14(%ebp)
   10c6b:	50                   	push   %eax
   10c6c:	e8 6f 14 00 00       	call   120e0 <bound>
   10c71:	83 c4 10             	add    $0x10,%esp
   10c74:	a3 0c e0 01 00       	mov    %eax,0x1e00c
	curr_x = scroll_min_x;
   10c79:	a1 00 e0 01 00       	mov    0x1e000,%eax
   10c7e:	a3 10 e0 01 00       	mov    %eax,0x1e010
	curr_y = scroll_min_y;
   10c83:	a1 04 e0 01 00       	mov    0x1e004,%eax
   10c88:	a3 14 e0 01 00       	mov    %eax,0x1e014
	setcursor();
   10c8d:	e8 66 fe ff ff       	call   10af8 <setcursor>
}
   10c92:	90                   	nop
   10c93:	c9                   	leave  
   10c94:	c3                   	ret    

00010c95 <cio_moveto>:

/*
** Cursor movement in the scroll region
*/
void cio_moveto( unsigned int x, unsigned int y ) {
   10c95:	55                   	push   %ebp
   10c96:	89 e5                	mov    %esp,%ebp
   10c98:	83 ec 08             	sub    $0x8,%esp
	curr_x = bound( scroll_min_x, x + scroll_min_x, scroll_max_x );
   10c9b:	8b 15 08 e0 01 00    	mov    0x1e008,%edx
   10ca1:	8b 0d 00 e0 01 00    	mov    0x1e000,%ecx
   10ca7:	8b 45 08             	mov    0x8(%ebp),%eax
   10caa:	01 c1                	add    %eax,%ecx
   10cac:	a1 00 e0 01 00       	mov    0x1e000,%eax
   10cb1:	83 ec 04             	sub    $0x4,%esp
   10cb4:	52                   	push   %edx
   10cb5:	51                   	push   %ecx
   10cb6:	50                   	push   %eax
   10cb7:	e8 24 14 00 00       	call   120e0 <bound>
   10cbc:	83 c4 10             	add    $0x10,%esp
   10cbf:	a3 10 e0 01 00       	mov    %eax,0x1e010
	curr_y = bound( scroll_min_y, y + scroll_min_y, scroll_max_y );
   10cc4:	8b 15 0c e0 01 00    	mov    0x1e00c,%edx
   10cca:	8b 0d 04 e0 01 00    	mov    0x1e004,%ecx
   10cd0:	8b 45 0c             	mov    0xc(%ebp),%eax
   10cd3:	01 c1                	add    %eax,%ecx
   10cd5:	a1 04 e0 01 00       	mov    0x1e004,%eax
   10cda:	83 ec 04             	sub    $0x4,%esp
   10cdd:	52                   	push   %edx
   10cde:	51                   	push   %ecx
   10cdf:	50                   	push   %eax
   10ce0:	e8 fb 13 00 00       	call   120e0 <bound>
   10ce5:	83 c4 10             	add    $0x10,%esp
   10ce8:	a3 14 e0 01 00       	mov    %eax,0x1e014
	setcursor();
   10ced:	e8 06 fe ff ff       	call   10af8 <setcursor>
}
   10cf2:	90                   	nop
   10cf3:	c9                   	leave  
   10cf4:	c3                   	ret    

00010cf5 <cio_putchar_at>:

/*
** The putchar family
*/
void cio_putchar_at( unsigned int x, unsigned int y, unsigned int c ) {
   10cf5:	55                   	push   %ebp
   10cf6:	89 e5                	mov    %esp,%ebp
   10cf8:	83 ec 10             	sub    $0x10,%esp
	if( ( c & 0x7f ) == '\n' ) {
   10cfb:	8b 45 10             	mov    0x10(%ebp),%eax
   10cfe:	83 e0 7f             	and    $0x7f,%eax
   10d01:	83 f8 0a             	cmp    $0xa,%eax
   10d04:	75 53                	jne    10d59 <cio_putchar_at+0x64>
		/*
		** If we're in the scroll region, don't let this loop
		** leave it. If we're not in the scroll region, don't
		** let this loop enter it.
		*/
		if( x > scroll_max_x ) {
   10d06:	a1 08 e0 01 00       	mov    0x1e008,%eax
   10d0b:	39 45 08             	cmp    %eax,0x8(%ebp)
   10d0e:	76 0a                	jbe    10d1a <cio_putchar_at+0x25>
			limit = max_x;
   10d10:	a1 20 e0 01 00       	mov    0x1e020,%eax
   10d15:	89 45 fc             	mov    %eax,-0x4(%ebp)
   10d18:	eb 35                	jmp    10d4f <cio_putchar_at+0x5a>
		}
		else if( x >= scroll_min_x ) {
   10d1a:	a1 00 e0 01 00       	mov    0x1e000,%eax
   10d1f:	39 45 08             	cmp    %eax,0x8(%ebp)
   10d22:	72 0a                	jb     10d2e <cio_putchar_at+0x39>
			limit = scroll_max_x;
   10d24:	a1 08 e0 01 00       	mov    0x1e008,%eax
   10d29:	89 45 fc             	mov    %eax,-0x4(%ebp)
   10d2c:	eb 21                	jmp    10d4f <cio_putchar_at+0x5a>
		}
		else {
			limit = scroll_min_x - 1;
   10d2e:	a1 00 e0 01 00       	mov    0x1e000,%eax
   10d33:	83 e8 01             	sub    $0x1,%eax
   10d36:	89 45 fc             	mov    %eax,-0x4(%ebp)
		}
		while( x <= limit ) {
   10d39:	eb 14                	jmp    10d4f <cio_putchar_at+0x5a>
			putchar_at( x, y, ' ' );
   10d3b:	6a 20                	push   $0x20
   10d3d:	ff 75 0c             	pushl  0xc(%ebp)
   10d40:	ff 75 08             	pushl  0x8(%ebp)
   10d43:	e8 45 fe ff ff       	call   10b8d <putchar_at>
   10d48:	83 c4 0c             	add    $0xc,%esp
			x += 1;
   10d4b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		while( x <= limit ) {
   10d4f:	8b 45 08             	mov    0x8(%ebp),%eax
   10d52:	3b 45 fc             	cmp    -0x4(%ebp),%eax
   10d55:	76 e4                	jbe    10d3b <cio_putchar_at+0x46>
		}
	}
	else {
		putchar_at( x, y, c );
	}
}
   10d57:	eb 11                	jmp    10d6a <cio_putchar_at+0x75>
		putchar_at( x, y, c );
   10d59:	ff 75 10             	pushl  0x10(%ebp)
   10d5c:	ff 75 0c             	pushl  0xc(%ebp)
   10d5f:	ff 75 08             	pushl  0x8(%ebp)
   10d62:	e8 26 fe ff ff       	call   10b8d <putchar_at>
   10d67:	83 c4 0c             	add    $0xc,%esp
}
   10d6a:	90                   	nop
   10d6b:	c9                   	leave  
   10d6c:	c3                   	ret    

00010d6d <cio_putchar>:

#ifndef SA_DEBUG
void cio_putchar( unsigned int c ) {
   10d6d:	55                   	push   %ebp
   10d6e:	89 e5                	mov    %esp,%ebp
   10d70:	83 ec 08             	sub    $0x8,%esp
	/*
	** If we're off the bottom of the screen, scroll the window.
	*/
	if( curr_y > scroll_max_y ) {
   10d73:	8b 15 14 e0 01 00    	mov    0x1e014,%edx
   10d79:	a1 0c e0 01 00       	mov    0x1e00c,%eax
   10d7e:	39 c2                	cmp    %eax,%edx
   10d80:	76 25                	jbe    10da7 <cio_putchar+0x3a>
		cio_scroll( curr_y - scroll_max_y );
   10d82:	8b 15 14 e0 01 00    	mov    0x1e014,%edx
   10d88:	a1 0c e0 01 00       	mov    0x1e00c,%eax
   10d8d:	29 c2                	sub    %eax,%edx
   10d8f:	89 d0                	mov    %edx,%eax
   10d91:	83 ec 0c             	sub    $0xc,%esp
   10d94:	50                   	push   %eax
   10d95:	e8 65 02 00 00       	call   10fff <cio_scroll>
   10d9a:	83 c4 10             	add    $0x10,%esp
		curr_y = scroll_max_y;
   10d9d:	a1 0c e0 01 00       	mov    0x1e00c,%eax
   10da2:	a3 14 e0 01 00       	mov    %eax,0x1e014
	}

	switch( c & BMASK8 ) {
   10da7:	8b 45 08             	mov    0x8(%ebp),%eax
   10daa:	0f b6 c0             	movzbl %al,%eax
   10dad:	83 f8 0a             	cmp    $0xa,%eax
   10db0:	74 2e                	je     10de0 <cio_putchar+0x73>
   10db2:	83 f8 0d             	cmp    $0xd,%eax
   10db5:	74 51                	je     10e08 <cio_putchar+0x9b>
   10db7:	eb 5b                	jmp    10e14 <cio_putchar+0xa7>
		/*
		** Erase to the end of the line, then move to new line
		** (actual scroll is delayed until next output appears).
		*/
		while( curr_x <= scroll_max_x ) {
			putchar_at( curr_x, curr_y, ' ' );
   10db9:	8b 15 14 e0 01 00    	mov    0x1e014,%edx
   10dbf:	a1 10 e0 01 00       	mov    0x1e010,%eax
   10dc4:	83 ec 04             	sub    $0x4,%esp
   10dc7:	6a 20                	push   $0x20
   10dc9:	52                   	push   %edx
   10dca:	50                   	push   %eax
   10dcb:	e8 bd fd ff ff       	call   10b8d <putchar_at>
   10dd0:	83 c4 10             	add    $0x10,%esp
			curr_x += 1;
   10dd3:	a1 10 e0 01 00       	mov    0x1e010,%eax
   10dd8:	83 c0 01             	add    $0x1,%eax
   10ddb:	a3 10 e0 01 00       	mov    %eax,0x1e010
		while( curr_x <= scroll_max_x ) {
   10de0:	8b 15 10 e0 01 00    	mov    0x1e010,%edx
   10de6:	a1 08 e0 01 00       	mov    0x1e008,%eax
   10deb:	39 c2                	cmp    %eax,%edx
   10ded:	76 ca                	jbe    10db9 <cio_putchar+0x4c>
		}
		curr_x = scroll_min_x;
   10def:	a1 00 e0 01 00       	mov    0x1e000,%eax
   10df4:	a3 10 e0 01 00       	mov    %eax,0x1e010
		curr_y += 1;
   10df9:	a1 14 e0 01 00       	mov    0x1e014,%eax
   10dfe:	83 c0 01             	add    $0x1,%eax
   10e01:	a3 14 e0 01 00       	mov    %eax,0x1e014
		break;
   10e06:	eb 5b                	jmp    10e63 <cio_putchar+0xf6>

	case '\r':
		curr_x = scroll_min_x;
   10e08:	a1 00 e0 01 00       	mov    0x1e000,%eax
   10e0d:	a3 10 e0 01 00       	mov    %eax,0x1e010
		break;
   10e12:	eb 4f                	jmp    10e63 <cio_putchar+0xf6>

	default:
		putchar_at( curr_x, curr_y, c );
   10e14:	8b 15 14 e0 01 00    	mov    0x1e014,%edx
   10e1a:	a1 10 e0 01 00       	mov    0x1e010,%eax
   10e1f:	83 ec 04             	sub    $0x4,%esp
   10e22:	ff 75 08             	pushl  0x8(%ebp)
   10e25:	52                   	push   %edx
   10e26:	50                   	push   %eax
   10e27:	e8 61 fd ff ff       	call   10b8d <putchar_at>
   10e2c:	83 c4 10             	add    $0x10,%esp
		curr_x += 1;
   10e2f:	a1 10 e0 01 00       	mov    0x1e010,%eax
   10e34:	83 c0 01             	add    $0x1,%eax
   10e37:	a3 10 e0 01 00       	mov    %eax,0x1e010
		if( curr_x > scroll_max_x ) {
   10e3c:	8b 15 10 e0 01 00    	mov    0x1e010,%edx
   10e42:	a1 08 e0 01 00       	mov    0x1e008,%eax
   10e47:	39 c2                	cmp    %eax,%edx
   10e49:	76 17                	jbe    10e62 <cio_putchar+0xf5>
			curr_x = scroll_min_x;
   10e4b:	a1 00 e0 01 00       	mov    0x1e000,%eax
   10e50:	a3 10 e0 01 00       	mov    %eax,0x1e010
			curr_y += 1;
   10e55:	a1 14 e0 01 00       	mov    0x1e014,%eax
   10e5a:	83 c0 01             	add    $0x1,%eax
   10e5d:	a3 14 e0 01 00       	mov    %eax,0x1e014
		}
		break;
   10e62:	90                   	nop
	}
	setcursor();
   10e63:	e8 90 fc ff ff       	call   10af8 <setcursor>
}
   10e68:	90                   	nop
   10e69:	c9                   	leave  
   10e6a:	c3                   	ret    

00010e6b <cio_puts_at>:
#endif

/*
** The puts family
*/
void cio_puts_at( unsigned int x, unsigned int y, const char *str ) {
   10e6b:	55                   	push   %ebp
   10e6c:	89 e5                	mov    %esp,%ebp
   10e6e:	83 ec 10             	sub    $0x10,%esp
	unsigned int ch;

	while( (ch = *str++) != '\0' && x <= max_x ) {
   10e71:	eb 15                	jmp    10e88 <cio_puts_at+0x1d>
		cio_putchar_at( x, y, ch );
   10e73:	ff 75 fc             	pushl  -0x4(%ebp)
   10e76:	ff 75 0c             	pushl  0xc(%ebp)
   10e79:	ff 75 08             	pushl  0x8(%ebp)
   10e7c:	e8 74 fe ff ff       	call   10cf5 <cio_putchar_at>
   10e81:	83 c4 0c             	add    $0xc,%esp
		x += 1;
   10e84:	83 45 08 01          	addl   $0x1,0x8(%ebp)
	while( (ch = *str++) != '\0' && x <= max_x ) {
   10e88:	8b 45 10             	mov    0x10(%ebp),%eax
   10e8b:	8d 50 01             	lea    0x1(%eax),%edx
   10e8e:	89 55 10             	mov    %edx,0x10(%ebp)
   10e91:	0f b6 00             	movzbl (%eax),%eax
   10e94:	0f be c0             	movsbl %al,%eax
   10e97:	89 45 fc             	mov    %eax,-0x4(%ebp)
   10e9a:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
   10e9e:	74 0a                	je     10eaa <cio_puts_at+0x3f>
   10ea0:	a1 20 e0 01 00       	mov    0x1e020,%eax
   10ea5:	39 45 08             	cmp    %eax,0x8(%ebp)
   10ea8:	76 c9                	jbe    10e73 <cio_puts_at+0x8>
	}
}
   10eaa:	90                   	nop
   10eab:	c9                   	leave  
   10eac:	c3                   	ret    

00010ead <cio_puts>:

#ifndef SA_DEBUG
void cio_puts( const char *str ) {
   10ead:	55                   	push   %ebp
   10eae:	89 e5                	mov    %esp,%ebp
   10eb0:	83 ec 18             	sub    $0x18,%esp
	unsigned int ch;

	while( (ch = *str++) != '\0' ) {
   10eb3:	eb 0e                	jmp    10ec3 <cio_puts+0x16>
		cio_putchar( ch );
   10eb5:	83 ec 0c             	sub    $0xc,%esp
   10eb8:	ff 75 f4             	pushl  -0xc(%ebp)
   10ebb:	e8 ad fe ff ff       	call   10d6d <cio_putchar>
   10ec0:	83 c4 10             	add    $0x10,%esp
	while( (ch = *str++) != '\0' ) {
   10ec3:	8b 45 08             	mov    0x8(%ebp),%eax
   10ec6:	8d 50 01             	lea    0x1(%eax),%edx
   10ec9:	89 55 08             	mov    %edx,0x8(%ebp)
   10ecc:	0f b6 00             	movzbl (%eax),%eax
   10ecf:	0f be c0             	movsbl %al,%eax
   10ed2:	89 45 f4             	mov    %eax,-0xc(%ebp)
   10ed5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   10ed9:	75 da                	jne    10eb5 <cio_puts+0x8>
	}
}
   10edb:	90                   	nop
   10edc:	c9                   	leave  
   10edd:	c3                   	ret    

00010ede <cio_write>:
#endif

/*
** Write a "sized" buffer (like cio_puts(), but no NUL)
*/
void cio_write( const char *buf, int length ) {
   10ede:	55                   	push   %ebp
   10edf:	89 e5                	mov    %esp,%ebp
   10ee1:	83 ec 18             	sub    $0x18,%esp
	for( int i = 0; i < length; ++i ) {
   10ee4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   10eeb:	eb 1e                	jmp    10f0b <cio_write+0x2d>
		cio_putchar( buf[i] );
   10eed:	8b 55 f4             	mov    -0xc(%ebp),%edx
   10ef0:	8b 45 08             	mov    0x8(%ebp),%eax
   10ef3:	01 d0                	add    %edx,%eax
   10ef5:	0f b6 00             	movzbl (%eax),%eax
   10ef8:	0f be c0             	movsbl %al,%eax
   10efb:	83 ec 0c             	sub    $0xc,%esp
   10efe:	50                   	push   %eax
   10eff:	e8 69 fe ff ff       	call   10d6d <cio_putchar>
   10f04:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < length; ++i ) {
   10f07:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   10f0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   10f0e:	3b 45 0c             	cmp    0xc(%ebp),%eax
   10f11:	7c da                	jl     10eed <cio_write+0xf>
	}
}
   10f13:	90                   	nop
   10f14:	c9                   	leave  
   10f15:	c3                   	ret    

00010f16 <cio_clearscroll>:

void cio_clearscroll( void ) {
   10f16:	55                   	push   %ebp
   10f17:	89 e5                	mov    %esp,%ebp
   10f19:	83 ec 10             	sub    $0x10,%esp
	unsigned int nchars = scroll_max_x - scroll_min_x + 1;
   10f1c:	8b 15 08 e0 01 00    	mov    0x1e008,%edx
   10f22:	a1 00 e0 01 00       	mov    0x1e000,%eax
   10f27:	29 c2                	sub    %eax,%edx
   10f29:	89 d0                	mov    %edx,%eax
   10f2b:	83 c0 01             	add    $0x1,%eax
   10f2e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	unsigned int l;
	unsigned int c;

	for( l = scroll_min_y; l <= scroll_max_y; l += 1 ) {
   10f31:	a1 04 e0 01 00       	mov    0x1e004,%eax
   10f36:	89 45 fc             	mov    %eax,-0x4(%ebp)
   10f39:	eb 47                	jmp    10f82 <cio_clearscroll+0x6c>
		unsigned short *to = VIDEO_ADDR( scroll_min_x, l );
   10f3b:	8b 55 fc             	mov    -0x4(%ebp),%edx
   10f3e:	89 d0                	mov    %edx,%eax
   10f40:	c1 e0 02             	shl    $0x2,%eax
   10f43:	01 d0                	add    %edx,%eax
   10f45:	c1 e0 04             	shl    $0x4,%eax
   10f48:	89 c2                	mov    %eax,%edx
   10f4a:	a1 00 e0 01 00       	mov    0x1e000,%eax
   10f4f:	01 d0                	add    %edx,%eax
   10f51:	05 00 c0 05 00       	add    $0x5c000,%eax
   10f56:	01 c0                	add    %eax,%eax
   10f58:	89 45 f4             	mov    %eax,-0xc(%ebp)

		for( c = 0; c < nchars; c += 1 ) {
   10f5b:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
   10f62:	eb 12                	jmp    10f76 <cio_clearscroll+0x60>
			*to++ = ' ' | VGA_DEFAULT;
   10f64:	8b 45 f4             	mov    -0xc(%ebp),%eax
   10f67:	8d 50 02             	lea    0x2(%eax),%edx
   10f6a:	89 55 f4             	mov    %edx,-0xc(%ebp)
   10f6d:	66 c7 00 20 07       	movw   $0x720,(%eax)
		for( c = 0; c < nchars; c += 1 ) {
   10f72:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
   10f76:	8b 45 f8             	mov    -0x8(%ebp),%eax
   10f79:	3b 45 f0             	cmp    -0x10(%ebp),%eax
   10f7c:	72 e6                	jb     10f64 <cio_clearscroll+0x4e>
	for( l = scroll_min_y; l <= scroll_max_y; l += 1 ) {
   10f7e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   10f82:	a1 0c e0 01 00       	mov    0x1e00c,%eax
   10f87:	39 45 fc             	cmp    %eax,-0x4(%ebp)
   10f8a:	76 af                	jbe    10f3b <cio_clearscroll+0x25>
		}
	}
}
   10f8c:	90                   	nop
   10f8d:	c9                   	leave  
   10f8e:	c3                   	ret    

00010f8f <cio_clearscreen>:

void cio_clearscreen( void ) {
   10f8f:	55                   	push   %ebp
   10f90:	89 e5                	mov    %esp,%ebp
   10f92:	83 ec 10             	sub    $0x10,%esp
	unsigned short *to = VIDEO_ADDR( min_x, min_y );
   10f95:	8b 15 1c e0 01 00    	mov    0x1e01c,%edx
   10f9b:	89 d0                	mov    %edx,%eax
   10f9d:	c1 e0 02             	shl    $0x2,%eax
   10fa0:	01 d0                	add    %edx,%eax
   10fa2:	c1 e0 04             	shl    $0x4,%eax
   10fa5:	89 c2                	mov    %eax,%edx
   10fa7:	a1 18 e0 01 00       	mov    0x1e018,%eax
   10fac:	01 d0                	add    %edx,%eax
   10fae:	05 00 c0 05 00       	add    $0x5c000,%eax
   10fb3:	01 c0                	add    %eax,%eax
   10fb5:	89 45 fc             	mov    %eax,-0x4(%ebp)
	unsigned int    nchars = ( max_y - min_y + 1 ) * ( max_x - min_x + 1 );
   10fb8:	8b 15 24 e0 01 00    	mov    0x1e024,%edx
   10fbe:	a1 1c e0 01 00       	mov    0x1e01c,%eax
   10fc3:	29 c2                	sub    %eax,%edx
   10fc5:	89 d0                	mov    %edx,%eax
   10fc7:	8d 48 01             	lea    0x1(%eax),%ecx
   10fca:	8b 15 20 e0 01 00    	mov    0x1e020,%edx
   10fd0:	a1 18 e0 01 00       	mov    0x1e018,%eax
   10fd5:	29 c2                	sub    %eax,%edx
   10fd7:	89 d0                	mov    %edx,%eax
   10fd9:	83 c0 01             	add    $0x1,%eax
   10fdc:	0f af c1             	imul   %ecx,%eax
   10fdf:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while( nchars > 0 ) {
   10fe2:	eb 12                	jmp    10ff6 <cio_clearscreen+0x67>
		*to++ = ' ' | VGA_DEFAULT;
   10fe4:	8b 45 fc             	mov    -0x4(%ebp),%eax
   10fe7:	8d 50 02             	lea    0x2(%eax),%edx
   10fea:	89 55 fc             	mov    %edx,-0x4(%ebp)
   10fed:	66 c7 00 20 07       	movw   $0x720,(%eax)
		nchars -= 1;
   10ff2:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
	while( nchars > 0 ) {
   10ff6:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
   10ffa:	75 e8                	jne    10fe4 <cio_clearscreen+0x55>
	}
}
   10ffc:	90                   	nop
   10ffd:	c9                   	leave  
   10ffe:	c3                   	ret    

00010fff <cio_scroll>:


void cio_scroll( unsigned int lines ) {
   10fff:	55                   	push   %ebp
   11000:	89 e5                	mov    %esp,%ebp
   11002:	83 ec 20             	sub    $0x20,%esp
	unsigned short *from;
	unsigned short *to;
	int nchars = scroll_max_x - scroll_min_x + 1;
   11005:	8b 15 08 e0 01 00    	mov    0x1e008,%edx
   1100b:	a1 00 e0 01 00       	mov    0x1e000,%eax
   11010:	29 c2                	sub    %eax,%edx
   11012:	89 d0                	mov    %edx,%eax
   11014:	83 c0 01             	add    $0x1,%eax
   11017:	89 45 ec             	mov    %eax,-0x14(%ebp)
	int line, c;

	/*
	** If # of lines is the whole scrolling region or more, just clear.
	*/
	if( lines > scroll_max_y - scroll_min_y ) {
   1101a:	8b 15 0c e0 01 00    	mov    0x1e00c,%edx
   11020:	a1 04 e0 01 00       	mov    0x1e004,%eax
   11025:	29 c2                	sub    %eax,%edx
   11027:	89 d0                	mov    %edx,%eax
   11029:	39 45 08             	cmp    %eax,0x8(%ebp)
   1102c:	76 23                	jbe    11051 <cio_scroll+0x52>
		cio_clearscroll();
   1102e:	e8 e3 fe ff ff       	call   10f16 <cio_clearscroll>
		curr_x = scroll_min_x;
   11033:	a1 00 e0 01 00       	mov    0x1e000,%eax
   11038:	a3 10 e0 01 00       	mov    %eax,0x1e010
		curr_y = scroll_min_y;
   1103d:	a1 04 e0 01 00       	mov    0x1e004,%eax
   11042:	a3 14 e0 01 00       	mov    %eax,0x1e014
		setcursor();
   11047:	e8 ac fa ff ff       	call   10af8 <setcursor>
		return;
   1104c:	e9 ea 00 00 00       	jmp    1113b <cio_scroll+0x13c>
	}

	/*
	** Must copy it line by line.
	*/
	for( line = scroll_min_y; line <= scroll_max_y - lines; line += 1 ) {
   11051:	a1 04 e0 01 00       	mov    0x1e004,%eax
   11056:	89 45 f4             	mov    %eax,-0xc(%ebp)
   11059:	eb 76                	jmp    110d1 <cio_scroll+0xd2>
		from = VIDEO_ADDR( scroll_min_x, line + lines );
   1105b:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1105e:	8b 45 08             	mov    0x8(%ebp),%eax
   11061:	01 c2                	add    %eax,%edx
   11063:	89 d0                	mov    %edx,%eax
   11065:	c1 e0 02             	shl    $0x2,%eax
   11068:	01 d0                	add    %edx,%eax
   1106a:	c1 e0 04             	shl    $0x4,%eax
   1106d:	89 c2                	mov    %eax,%edx
   1106f:	a1 00 e0 01 00       	mov    0x1e000,%eax
   11074:	01 d0                	add    %edx,%eax
   11076:	05 00 c0 05 00       	add    $0x5c000,%eax
   1107b:	01 c0                	add    %eax,%eax
   1107d:	89 45 fc             	mov    %eax,-0x4(%ebp)
		to = VIDEO_ADDR( scroll_min_x, line );
   11080:	8b 55 f4             	mov    -0xc(%ebp),%edx
   11083:	89 d0                	mov    %edx,%eax
   11085:	c1 e0 02             	shl    $0x2,%eax
   11088:	01 d0                	add    %edx,%eax
   1108a:	c1 e0 04             	shl    $0x4,%eax
   1108d:	89 c2                	mov    %eax,%edx
   1108f:	a1 00 e0 01 00       	mov    0x1e000,%eax
   11094:	01 d0                	add    %edx,%eax
   11096:	05 00 c0 05 00       	add    $0x5c000,%eax
   1109b:	01 c0                	add    %eax,%eax
   1109d:	89 45 f8             	mov    %eax,-0x8(%ebp)
		for( c = 0; c < nchars; c += 1 ) {
   110a0:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   110a7:	eb 1c                	jmp    110c5 <cio_scroll+0xc6>
			*to++ = *from++;
   110a9:	8b 55 fc             	mov    -0x4(%ebp),%edx
   110ac:	8d 42 02             	lea    0x2(%edx),%eax
   110af:	89 45 fc             	mov    %eax,-0x4(%ebp)
   110b2:	8b 45 f8             	mov    -0x8(%ebp),%eax
   110b5:	8d 48 02             	lea    0x2(%eax),%ecx
   110b8:	89 4d f8             	mov    %ecx,-0x8(%ebp)
   110bb:	0f b7 12             	movzwl (%edx),%edx
   110be:	66 89 10             	mov    %dx,(%eax)
		for( c = 0; c < nchars; c += 1 ) {
   110c1:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   110c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
   110c8:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   110cb:	7c dc                	jl     110a9 <cio_scroll+0xaa>
	for( line = scroll_min_y; line <= scroll_max_y - lines; line += 1 ) {
   110cd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   110d1:	a1 0c e0 01 00       	mov    0x1e00c,%eax
   110d6:	2b 45 08             	sub    0x8(%ebp),%eax
   110d9:	89 c2                	mov    %eax,%edx
   110db:	8b 45 f4             	mov    -0xc(%ebp),%eax
   110de:	39 c2                	cmp    %eax,%edx
   110e0:	0f 83 75 ff ff ff    	jae    1105b <cio_scroll+0x5c>
		}
	}

	for( ; line <= scroll_max_y; line += 1 ) {
   110e6:	eb 47                	jmp    1112f <cio_scroll+0x130>
		to = VIDEO_ADDR( scroll_min_x, line );
   110e8:	8b 55 f4             	mov    -0xc(%ebp),%edx
   110eb:	89 d0                	mov    %edx,%eax
   110ed:	c1 e0 02             	shl    $0x2,%eax
   110f0:	01 d0                	add    %edx,%eax
   110f2:	c1 e0 04             	shl    $0x4,%eax
   110f5:	89 c2                	mov    %eax,%edx
   110f7:	a1 00 e0 01 00       	mov    0x1e000,%eax
   110fc:	01 d0                	add    %edx,%eax
   110fe:	05 00 c0 05 00       	add    $0x5c000,%eax
   11103:	01 c0                	add    %eax,%eax
   11105:	89 45 f8             	mov    %eax,-0x8(%ebp)
		for( c = 0; c < nchars; c += 1 ) {
   11108:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   1110f:	eb 12                	jmp    11123 <cio_scroll+0x124>
			*to++ = ' ' | VGA_DEFAULT;
   11111:	8b 45 f8             	mov    -0x8(%ebp),%eax
   11114:	8d 50 02             	lea    0x2(%eax),%edx
   11117:	89 55 f8             	mov    %edx,-0x8(%ebp)
   1111a:	66 c7 00 20 07       	movw   $0x720,(%eax)
		for( c = 0; c < nchars; c += 1 ) {
   1111f:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   11123:	8b 45 f0             	mov    -0x10(%ebp),%eax
   11126:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   11129:	7c e6                	jl     11111 <cio_scroll+0x112>
	for( ; line <= scroll_max_y; line += 1 ) {
   1112b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   1112f:	8b 55 f4             	mov    -0xc(%ebp),%edx
   11132:	a1 0c e0 01 00       	mov    0x1e00c,%eax
   11137:	39 c2                	cmp    %eax,%edx
   11139:	76 ad                	jbe    110e8 <cio_scroll+0xe9>
		}
	}
}
   1113b:	c9                   	leave  
   1113c:	c3                   	ret    

0001113d <mypad>:

static int mypad( int x, int y, int extra, int padchar ) {
   1113d:	55                   	push   %ebp
   1113e:	89 e5                	mov    %esp,%ebp
   11140:	83 ec 08             	sub    $0x8,%esp
	while( extra > 0 ) {
   11143:	eb 39                	jmp    1117e <mypad+0x41>
		if( x != -1 || y != -1 ) {
   11145:	83 7d 08 ff          	cmpl   $0xffffffff,0x8(%ebp)
   11149:	75 06                	jne    11151 <mypad+0x14>
   1114b:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
   1114f:	74 1a                	je     1116b <mypad+0x2e>
			cio_putchar_at( x, y, padchar );
   11151:	8b 4d 14             	mov    0x14(%ebp),%ecx
   11154:	8b 55 0c             	mov    0xc(%ebp),%edx
   11157:	8b 45 08             	mov    0x8(%ebp),%eax
   1115a:	51                   	push   %ecx
   1115b:	52                   	push   %edx
   1115c:	50                   	push   %eax
   1115d:	e8 93 fb ff ff       	call   10cf5 <cio_putchar_at>
   11162:	83 c4 0c             	add    $0xc,%esp
			x += 1;
   11165:	83 45 08 01          	addl   $0x1,0x8(%ebp)
   11169:	eb 0f                	jmp    1117a <mypad+0x3d>
		}
		else {
			cio_putchar( padchar );
   1116b:	8b 45 14             	mov    0x14(%ebp),%eax
   1116e:	83 ec 0c             	sub    $0xc,%esp
   11171:	50                   	push   %eax
   11172:	e8 f6 fb ff ff       	call   10d6d <cio_putchar>
   11177:	83 c4 10             	add    $0x10,%esp
		}
		extra -= 1;
   1117a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
	while( extra > 0 ) {
   1117e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
   11182:	7f c1                	jg     11145 <mypad+0x8>
	}
	return x;
   11184:	8b 45 08             	mov    0x8(%ebp),%eax
}
   11187:	c9                   	leave  
   11188:	c3                   	ret    

00011189 <mypadstr>:

static int mypadstr( int x, int y, char *str, int len, int width,
				   int leftadjust, int padchar ) {
   11189:	55                   	push   %ebp
   1118a:	89 e5                	mov    %esp,%ebp
   1118c:	83 ec 18             	sub    $0x18,%esp
	int extra;

	if( len < 0 ) {
   1118f:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
   11193:	79 11                	jns    111a6 <mypadstr+0x1d>
		len = strlen( str );
   11195:	83 ec 0c             	sub    $0xc,%esp
   11198:	ff 75 10             	pushl  0x10(%ebp)
   1119b:	e8 d4 18 00 00       	call   12a74 <strlen>
   111a0:	83 c4 10             	add    $0x10,%esp
   111a3:	89 45 14             	mov    %eax,0x14(%ebp)
	}
	extra = width - len;
   111a6:	8b 45 18             	mov    0x18(%ebp),%eax
   111a9:	2b 45 14             	sub    0x14(%ebp),%eax
   111ac:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( extra > 0 && !leftadjust ) {
   111af:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   111b3:	7e 1d                	jle    111d2 <mypadstr+0x49>
   111b5:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
   111b9:	75 17                	jne    111d2 <mypadstr+0x49>
		x = mypad( x, y, extra, padchar );
   111bb:	ff 75 20             	pushl  0x20(%ebp)
   111be:	ff 75 f4             	pushl  -0xc(%ebp)
   111c1:	ff 75 0c             	pushl  0xc(%ebp)
   111c4:	ff 75 08             	pushl  0x8(%ebp)
   111c7:	e8 71 ff ff ff       	call   1113d <mypad>
   111cc:	83 c4 10             	add    $0x10,%esp
   111cf:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	if( x != -1 || y != -1 ) {
   111d2:	83 7d 08 ff          	cmpl   $0xffffffff,0x8(%ebp)
   111d6:	75 06                	jne    111de <mypadstr+0x55>
   111d8:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
   111dc:	74 1e                	je     111fc <mypadstr+0x73>
		cio_puts_at( x, y, str );
   111de:	8b 55 0c             	mov    0xc(%ebp),%edx
   111e1:	8b 45 08             	mov    0x8(%ebp),%eax
   111e4:	83 ec 04             	sub    $0x4,%esp
   111e7:	ff 75 10             	pushl  0x10(%ebp)
   111ea:	52                   	push   %edx
   111eb:	50                   	push   %eax
   111ec:	e8 7a fc ff ff       	call   10e6b <cio_puts_at>
   111f1:	83 c4 10             	add    $0x10,%esp
		x += len;
   111f4:	8b 45 14             	mov    0x14(%ebp),%eax
   111f7:	01 45 08             	add    %eax,0x8(%ebp)
   111fa:	eb 0e                	jmp    1120a <mypadstr+0x81>
	}
	else {
		cio_puts( str );
   111fc:	83 ec 0c             	sub    $0xc,%esp
   111ff:	ff 75 10             	pushl  0x10(%ebp)
   11202:	e8 a6 fc ff ff       	call   10ead <cio_puts>
   11207:	83 c4 10             	add    $0x10,%esp
	}
	if( extra > 0 && leftadjust ) {
   1120a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1120e:	7e 1d                	jle    1122d <mypadstr+0xa4>
   11210:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
   11214:	74 17                	je     1122d <mypadstr+0xa4>
		x = mypad( x, y, extra, padchar );
   11216:	ff 75 20             	pushl  0x20(%ebp)
   11219:	ff 75 f4             	pushl  -0xc(%ebp)
   1121c:	ff 75 0c             	pushl  0xc(%ebp)
   1121f:	ff 75 08             	pushl  0x8(%ebp)
   11222:	e8 16 ff ff ff       	call   1113d <mypad>
   11227:	83 c4 10             	add    $0x10,%esp
   1122a:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	return x;
   1122d:	8b 45 08             	mov    0x8(%ebp),%eax
}
   11230:	c9                   	leave  
   11231:	c3                   	ret    

00011232 <do_printf>:

static void do_printf( int x, int y, char **f ) {
   11232:	55                   	push   %ebp
   11233:	89 e5                	mov    %esp,%ebp
   11235:	83 ec 38             	sub    $0x38,%esp
	char *fmt = *f;
   11238:	8b 45 10             	mov    0x10(%ebp),%eax
   1123b:	8b 00                	mov    (%eax),%eax
   1123d:	89 45 f4             	mov    %eax,-0xc(%ebp)

	/*
	** Get characters from the format string and process them
	*/

	ap = (int *)( f + 1 );
   11240:	8b 45 10             	mov    0x10(%ebp),%eax
   11243:	83 c0 04             	add    $0x4,%eax
   11246:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( (ch = *fmt++) != '\0' ) {
   11249:	e9 9d 02 00 00       	jmp    114eb <do_printf+0x2b9>

		/*
		** Is it the start of a format code?
		*/

		if( ch == '%' ) {
   1124e:	80 7d ef 25          	cmpb   $0x25,-0x11(%ebp)
   11252:	0f 85 3b 02 00 00    	jne    11493 <do_printf+0x261>
			** Yes, get the padding and width options (if there).
			** Alignment must come at the beginning, then fill,
			** then width.
			*/

			leftadjust = 0;
   11258:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
			padchar = ' ';
   1125f:	c7 45 e0 20 00 00 00 	movl   $0x20,-0x20(%ebp)
			width = 0;
   11266:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

			ch = *fmt++;
   1126d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   11270:	8d 50 01             	lea    0x1(%eax),%edx
   11273:	89 55 f4             	mov    %edx,-0xc(%ebp)
   11276:	0f b6 00             	movzbl (%eax),%eax
   11279:	88 45 ef             	mov    %al,-0x11(%ebp)

			if( ch == '-' ) {
   1127c:	80 7d ef 2d          	cmpb   $0x2d,-0x11(%ebp)
   11280:	75 16                	jne    11298 <do_printf+0x66>
				leftadjust = 1;
   11282:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
				ch = *fmt++;
   11289:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1128c:	8d 50 01             	lea    0x1(%eax),%edx
   1128f:	89 55 f4             	mov    %edx,-0xc(%ebp)
   11292:	0f b6 00             	movzbl (%eax),%eax
   11295:	88 45 ef             	mov    %al,-0x11(%ebp)
			}

			if( ch == '0' ) {
   11298:	80 7d ef 30          	cmpb   $0x30,-0x11(%ebp)
   1129c:	75 40                	jne    112de <do_printf+0xac>
				padchar = '0';
   1129e:	c7 45 e0 30 00 00 00 	movl   $0x30,-0x20(%ebp)
				ch = *fmt++;
   112a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
   112a8:	8d 50 01             	lea    0x1(%eax),%edx
   112ab:	89 55 f4             	mov    %edx,-0xc(%ebp)
   112ae:	0f b6 00             	movzbl (%eax),%eax
   112b1:	88 45 ef             	mov    %al,-0x11(%ebp)
			}

			while( ch >= '0' && ch <= '9' ) {
   112b4:	eb 28                	jmp    112de <do_printf+0xac>
				width *= 10;
   112b6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   112b9:	89 d0                	mov    %edx,%eax
   112bb:	c1 e0 02             	shl    $0x2,%eax
   112be:	01 d0                	add    %edx,%eax
   112c0:	01 c0                	add    %eax,%eax
   112c2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				width += ch - '0';
   112c5:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   112c9:	83 e8 30             	sub    $0x30,%eax
   112cc:	01 45 e4             	add    %eax,-0x1c(%ebp)
				ch = *fmt++;
   112cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
   112d2:	8d 50 01             	lea    0x1(%eax),%edx
   112d5:	89 55 f4             	mov    %edx,-0xc(%ebp)
   112d8:	0f b6 00             	movzbl (%eax),%eax
   112db:	88 45 ef             	mov    %al,-0x11(%ebp)
			while( ch >= '0' && ch <= '9' ) {
   112de:	80 7d ef 2f          	cmpb   $0x2f,-0x11(%ebp)
   112e2:	7e 06                	jle    112ea <do_printf+0xb8>
   112e4:	80 7d ef 39          	cmpb   $0x39,-0x11(%ebp)
   112e8:	7e cc                	jle    112b6 <do_printf+0x84>
			}

			/*
			** What data type do we have?
			*/
			switch( ch ) {
   112ea:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   112ee:	83 e8 63             	sub    $0x63,%eax
   112f1:	83 f8 15             	cmp    $0x15,%eax
   112f4:	0f 87 f1 01 00 00    	ja     114eb <do_printf+0x2b9>
   112fa:	8b 04 85 18 a9 01 00 	mov    0x1a918(,%eax,4),%eax
   11301:	ff e0                	jmp    *%eax

			case 'c':
				// ch = *( (int *)ap )++;
				ch = *ap++;
   11303:	8b 45 f0             	mov    -0x10(%ebp),%eax
   11306:	8d 50 04             	lea    0x4(%eax),%edx
   11309:	89 55 f0             	mov    %edx,-0x10(%ebp)
   1130c:	8b 00                	mov    (%eax),%eax
   1130e:	88 45 ef             	mov    %al,-0x11(%ebp)
				buf[ 0 ] = ch;
   11311:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
   11315:	88 45 cc             	mov    %al,-0x34(%ebp)
				buf[ 1 ] = '\0';
   11318:	c6 45 cd 00          	movb   $0x0,-0x33(%ebp)
				x = mypadstr( x, y, buf, 1, width, leftadjust, padchar );
   1131c:	83 ec 04             	sub    $0x4,%esp
   1131f:	ff 75 e0             	pushl  -0x20(%ebp)
   11322:	ff 75 e8             	pushl  -0x18(%ebp)
   11325:	ff 75 e4             	pushl  -0x1c(%ebp)
   11328:	6a 01                	push   $0x1
   1132a:	8d 45 cc             	lea    -0x34(%ebp),%eax
   1132d:	50                   	push   %eax
   1132e:	ff 75 0c             	pushl  0xc(%ebp)
   11331:	ff 75 08             	pushl  0x8(%ebp)
   11334:	e8 50 fe ff ff       	call   11189 <mypadstr>
   11339:	83 c4 20             	add    $0x20,%esp
   1133c:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   1133f:	e9 a7 01 00 00       	jmp    114eb <do_printf+0x2b9>

			case 'd':
				// len = cvtdec( buf, *( (int *)ap )++ );
				len = cvtdec( buf, *ap++ );
   11344:	8b 45 f0             	mov    -0x10(%ebp),%eax
   11347:	8d 50 04             	lea    0x4(%eax),%edx
   1134a:	89 55 f0             	mov    %edx,-0x10(%ebp)
   1134d:	8b 00                	mov    (%eax),%eax
   1134f:	83 ec 08             	sub    $0x8,%esp
   11352:	50                   	push   %eax
   11353:	8d 45 cc             	lea    -0x34(%ebp),%eax
   11356:	50                   	push   %eax
   11357:	e8 a8 0d 00 00       	call   12104 <cvtdec>
   1135c:	83 c4 10             	add    $0x10,%esp
   1135f:	89 45 dc             	mov    %eax,-0x24(%ebp)
				x = mypadstr( x, y, buf, len, width, leftadjust, padchar );
   11362:	83 ec 04             	sub    $0x4,%esp
   11365:	ff 75 e0             	pushl  -0x20(%ebp)
   11368:	ff 75 e8             	pushl  -0x18(%ebp)
   1136b:	ff 75 e4             	pushl  -0x1c(%ebp)
   1136e:	ff 75 dc             	pushl  -0x24(%ebp)
   11371:	8d 45 cc             	lea    -0x34(%ebp),%eax
   11374:	50                   	push   %eax
   11375:	ff 75 0c             	pushl  0xc(%ebp)
   11378:	ff 75 08             	pushl  0x8(%ebp)
   1137b:	e8 09 fe ff ff       	call   11189 <mypadstr>
   11380:	83 c4 20             	add    $0x20,%esp
   11383:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   11386:	e9 60 01 00 00       	jmp    114eb <do_printf+0x2b9>

			case 's':
				// str = *( (char **)ap )++;
				str = (char *) (*ap++);
   1138b:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1138e:	8d 50 04             	lea    0x4(%eax),%edx
   11391:	89 55 f0             	mov    %edx,-0x10(%ebp)
   11394:	8b 00                	mov    (%eax),%eax
   11396:	89 45 d8             	mov    %eax,-0x28(%ebp)
				x = mypadstr( x, y, str, -1, width, leftadjust, padchar );
   11399:	83 ec 04             	sub    $0x4,%esp
   1139c:	ff 75 e0             	pushl  -0x20(%ebp)
   1139f:	ff 75 e8             	pushl  -0x18(%ebp)
   113a2:	ff 75 e4             	pushl  -0x1c(%ebp)
   113a5:	6a ff                	push   $0xffffffff
   113a7:	ff 75 d8             	pushl  -0x28(%ebp)
   113aa:	ff 75 0c             	pushl  0xc(%ebp)
   113ad:	ff 75 08             	pushl  0x8(%ebp)
   113b0:	e8 d4 fd ff ff       	call   11189 <mypadstr>
   113b5:	83 c4 20             	add    $0x20,%esp
   113b8:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   113bb:	e9 2b 01 00 00       	jmp    114eb <do_printf+0x2b9>

			case 'x':
				// len = cvthex( buf, *( (int *)ap )++ );
				len = cvthex( buf, *ap++ );
   113c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
   113c3:	8d 50 04             	lea    0x4(%eax),%edx
   113c6:	89 55 f0             	mov    %edx,-0x10(%ebp)
   113c9:	8b 00                	mov    (%eax),%eax
   113cb:	83 ec 08             	sub    $0x8,%esp
   113ce:	50                   	push   %eax
   113cf:	8d 45 cc             	lea    -0x34(%ebp),%eax
   113d2:	50                   	push   %eax
   113d3:	e8 fc 0d 00 00       	call   121d4 <cvthex>
   113d8:	83 c4 10             	add    $0x10,%esp
   113db:	89 45 dc             	mov    %eax,-0x24(%ebp)
				x = mypadstr( x, y, buf, len, width, leftadjust, padchar );
   113de:	83 ec 04             	sub    $0x4,%esp
   113e1:	ff 75 e0             	pushl  -0x20(%ebp)
   113e4:	ff 75 e8             	pushl  -0x18(%ebp)
   113e7:	ff 75 e4             	pushl  -0x1c(%ebp)
   113ea:	ff 75 dc             	pushl  -0x24(%ebp)
   113ed:	8d 45 cc             	lea    -0x34(%ebp),%eax
   113f0:	50                   	push   %eax
   113f1:	ff 75 0c             	pushl  0xc(%ebp)
   113f4:	ff 75 08             	pushl  0x8(%ebp)
   113f7:	e8 8d fd ff ff       	call   11189 <mypadstr>
   113fc:	83 c4 20             	add    $0x20,%esp
   113ff:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   11402:	e9 e4 00 00 00       	jmp    114eb <do_printf+0x2b9>

			case 'o':
				// len = cvtoct( buf, *( (int *)ap )++ );
				len = cvtoct( buf, *ap++ );
   11407:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1140a:	8d 50 04             	lea    0x4(%eax),%edx
   1140d:	89 55 f0             	mov    %edx,-0x10(%ebp)
   11410:	8b 00                	mov    (%eax),%eax
   11412:	83 ec 08             	sub    $0x8,%esp
   11415:	50                   	push   %eax
   11416:	8d 45 cc             	lea    -0x34(%ebp),%eax
   11419:	50                   	push   %eax
   1141a:	e8 3f 0e 00 00       	call   1225e <cvtoct>
   1141f:	83 c4 10             	add    $0x10,%esp
   11422:	89 45 dc             	mov    %eax,-0x24(%ebp)
				x = mypadstr( x, y, buf, len, width, leftadjust, padchar );
   11425:	83 ec 04             	sub    $0x4,%esp
   11428:	ff 75 e0             	pushl  -0x20(%ebp)
   1142b:	ff 75 e8             	pushl  -0x18(%ebp)
   1142e:	ff 75 e4             	pushl  -0x1c(%ebp)
   11431:	ff 75 dc             	pushl  -0x24(%ebp)
   11434:	8d 45 cc             	lea    -0x34(%ebp),%eax
   11437:	50                   	push   %eax
   11438:	ff 75 0c             	pushl  0xc(%ebp)
   1143b:	ff 75 08             	pushl  0x8(%ebp)
   1143e:	e8 46 fd ff ff       	call   11189 <mypadstr>
   11443:	83 c4 20             	add    $0x20,%esp
   11446:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   11449:	e9 9d 00 00 00       	jmp    114eb <do_printf+0x2b9>

			case 'u':
				len = cvtuns( buf, *ap++ );
   1144e:	8b 45 f0             	mov    -0x10(%ebp),%eax
   11451:	8d 50 04             	lea    0x4(%eax),%edx
   11454:	89 55 f0             	mov    %edx,-0x10(%ebp)
   11457:	8b 00                	mov    (%eax),%eax
   11459:	83 ec 08             	sub    $0x8,%esp
   1145c:	50                   	push   %eax
   1145d:	8d 45 cc             	lea    -0x34(%ebp),%eax
   11460:	50                   	push   %eax
   11461:	e8 82 0e 00 00       	call   122e8 <cvtuns>
   11466:	83 c4 10             	add    $0x10,%esp
   11469:	89 45 dc             	mov    %eax,-0x24(%ebp)
				x = mypadstr( x, y, buf, len, width, leftadjust, padchar );
   1146c:	83 ec 04             	sub    $0x4,%esp
   1146f:	ff 75 e0             	pushl  -0x20(%ebp)
   11472:	ff 75 e8             	pushl  -0x18(%ebp)
   11475:	ff 75 e4             	pushl  -0x1c(%ebp)
   11478:	ff 75 dc             	pushl  -0x24(%ebp)
   1147b:	8d 45 cc             	lea    -0x34(%ebp),%eax
   1147e:	50                   	push   %eax
   1147f:	ff 75 0c             	pushl  0xc(%ebp)
   11482:	ff 75 08             	pushl  0x8(%ebp)
   11485:	e8 ff fc ff ff       	call   11189 <mypadstr>
   1148a:	83 c4 20             	add    $0x20,%esp
   1148d:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   11490:	90                   	nop
   11491:	eb 58                	jmp    114eb <do_printf+0x2b9>

			/*
			** No - just print it normally.
			*/

			if( x != -1 || y != -1 ) {
   11493:	83 7d 08 ff          	cmpl   $0xffffffff,0x8(%ebp)
   11497:	75 06                	jne    1149f <do_printf+0x26d>
   11499:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
   1149d:	74 3c                	je     114db <do_printf+0x2a9>
				cio_putchar_at( x, y, ch );
   1149f:	0f be 4d ef          	movsbl -0x11(%ebp),%ecx
   114a3:	8b 55 0c             	mov    0xc(%ebp),%edx
   114a6:	8b 45 08             	mov    0x8(%ebp),%eax
   114a9:	83 ec 04             	sub    $0x4,%esp
   114ac:	51                   	push   %ecx
   114ad:	52                   	push   %edx
   114ae:	50                   	push   %eax
   114af:	e8 41 f8 ff ff       	call   10cf5 <cio_putchar_at>
   114b4:	83 c4 10             	add    $0x10,%esp
				switch( ch ) {
   114b7:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   114bb:	83 f8 0a             	cmp    $0xa,%eax
   114be:	74 07                	je     114c7 <do_printf+0x295>
   114c0:	83 f8 0d             	cmp    $0xd,%eax
   114c3:	74 06                	je     114cb <do_printf+0x299>
   114c5:	eb 0e                	jmp    114d5 <do_printf+0x2a3>
				case '\n':
					y += 1;
   114c7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
					/* FALL THRU */

				case '\r':
					x = scroll_min_x;
   114cb:	a1 00 e0 01 00       	mov    0x1e000,%eax
   114d0:	89 45 08             	mov    %eax,0x8(%ebp)
					break;
   114d3:	eb 04                	jmp    114d9 <do_printf+0x2a7>

				default:
					x += 1;
   114d5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
				}
			}
   114d9:	eb 10                	jmp    114eb <do_printf+0x2b9>
			else {
				cio_putchar( ch );
   114db:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   114df:	83 ec 0c             	sub    $0xc,%esp
   114e2:	50                   	push   %eax
   114e3:	e8 85 f8 ff ff       	call   10d6d <cio_putchar>
   114e8:	83 c4 10             	add    $0x10,%esp
	while( (ch = *fmt++) != '\0' ) {
   114eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
   114ee:	8d 50 01             	lea    0x1(%eax),%edx
   114f1:	89 55 f4             	mov    %edx,-0xc(%ebp)
   114f4:	0f b6 00             	movzbl (%eax),%eax
   114f7:	88 45 ef             	mov    %al,-0x11(%ebp)
   114fa:	80 7d ef 00          	cmpb   $0x0,-0x11(%ebp)
   114fe:	0f 85 4a fd ff ff    	jne    1124e <do_printf+0x1c>
			}
		}
	}
}
   11504:	90                   	nop
   11505:	c9                   	leave  
   11506:	c3                   	ret    

00011507 <cio_printf_at>:

void cio_printf_at( unsigned int x, unsigned int y, char *fmt, ... ) {
   11507:	55                   	push   %ebp
   11508:	89 e5                	mov    %esp,%ebp
   1150a:	83 ec 08             	sub    $0x8,%esp
	do_printf( x, y, &fmt );
   1150d:	8b 55 0c             	mov    0xc(%ebp),%edx
   11510:	8b 45 08             	mov    0x8(%ebp),%eax
   11513:	83 ec 04             	sub    $0x4,%esp
   11516:	8d 4d 10             	lea    0x10(%ebp),%ecx
   11519:	51                   	push   %ecx
   1151a:	52                   	push   %edx
   1151b:	50                   	push   %eax
   1151c:	e8 11 fd ff ff       	call   11232 <do_printf>
   11521:	83 c4 10             	add    $0x10,%esp
}
   11524:	90                   	nop
   11525:	c9                   	leave  
   11526:	c3                   	ret    

00011527 <cio_printf>:

void cio_printf( char *fmt, ... ) {
   11527:	55                   	push   %ebp
   11528:	89 e5                	mov    %esp,%ebp
   1152a:	83 ec 08             	sub    $0x8,%esp
	do_printf( -1, -1, &fmt );
   1152d:	83 ec 04             	sub    $0x4,%esp
   11530:	8d 45 08             	lea    0x8(%ebp),%eax
   11533:	50                   	push   %eax
   11534:	6a ff                	push   $0xffffffff
   11536:	6a ff                	push   $0xffffffff
   11538:	e8 f5 fc ff ff       	call   11232 <do_printf>
   1153d:	83 c4 10             	add    $0x10,%esp
}
   11540:	90                   	nop
   11541:	c9                   	leave  
   11542:	c3                   	ret    

00011543 <increment>:

static char input_buffer[ C_BUFSIZE ];
static volatile char *next_char = input_buffer;
static volatile char *next_space = input_buffer;

static volatile char *increment( volatile char *pointer ) {
   11543:	55                   	push   %ebp
   11544:	89 e5                	mov    %esp,%ebp
	if( ++pointer >= input_buffer + C_BUFSIZE ) {
   11546:	83 45 08 01          	addl   $0x1,0x8(%ebp)
   1154a:	b8 08 e1 01 00       	mov    $0x1e108,%eax
   1154f:	39 45 08             	cmp    %eax,0x8(%ebp)
   11552:	72 07                	jb     1155b <increment+0x18>
		pointer = input_buffer;
   11554:	c7 45 08 40 e0 01 00 	movl   $0x1e040,0x8(%ebp)
	}
	return pointer;
   1155b:	8b 45 08             	mov    0x8(%ebp),%eax
}
   1155e:	5d                   	pop    %ebp
   1155f:	c3                   	ret    

00011560 <input_scan_code>:

static int input_scan_code( int code ) {
   11560:	55                   	push   %ebp
   11561:	89 e5                	mov    %esp,%ebp
   11563:	83 ec 10             	sub    $0x10,%esp
	static  int shift = 0;
	static  int ctrl_mask = BMASK8;
	int rval = -1;
   11566:	c7 45 fc ff ff ff ff 	movl   $0xffffffff,-0x4(%ebp)

	/*
	** Do the shift processing
	*/
	code &= BMASK8;
   1156d:	81 65 08 ff 00 00 00 	andl   $0xff,0x8(%ebp)
	switch( code ) {
   11574:	8b 45 08             	mov    0x8(%ebp),%eax
   11577:	83 f8 36             	cmp    $0x36,%eax
   1157a:	74 28                	je     115a4 <input_scan_code+0x44>
   1157c:	83 f8 36             	cmp    $0x36,%eax
   1157f:	7f 0c                	jg     1158d <input_scan_code+0x2d>
   11581:	83 f8 1d             	cmp    $0x1d,%eax
   11584:	74 3c                	je     115c2 <input_scan_code+0x62>
   11586:	83 f8 2a             	cmp    $0x2a,%eax
   11589:	74 19                	je     115a4 <input_scan_code+0x44>
   1158b:	eb 4d                	jmp    115da <input_scan_code+0x7a>
   1158d:	3d aa 00 00 00       	cmp    $0xaa,%eax
   11592:	74 1f                	je     115b3 <input_scan_code+0x53>
   11594:	3d b6 00 00 00       	cmp    $0xb6,%eax
   11599:	74 18                	je     115b3 <input_scan_code+0x53>
   1159b:	3d 9d 00 00 00       	cmp    $0x9d,%eax
   115a0:	74 2c                	je     115ce <input_scan_code+0x6e>
   115a2:	eb 36                	jmp    115da <input_scan_code+0x7a>
	case L_SHIFT_DN:
	case R_SHIFT_DN:
		shift = 1;
   115a4:	c7 05 08 e1 01 00 01 	movl   $0x1,0x1e108
   115ab:	00 00 00 
		break;
   115ae:	e9 99 00 00 00       	jmp    1164c <input_scan_code+0xec>

	case L_SHIFT_UP:
	case R_SHIFT_UP:
		shift = 0;
   115b3:	c7 05 08 e1 01 00 00 	movl   $0x0,0x1e108
   115ba:	00 00 00 
		break;
   115bd:	e9 8a 00 00 00       	jmp    1164c <input_scan_code+0xec>

	case L_CTRL_DN:
		ctrl_mask = BMASK5;
   115c2:	c7 05 08 d1 01 00 1f 	movl   $0x1f,0x1d108
   115c9:	00 00 00 
		break;
   115cc:	eb 7e                	jmp    1164c <input_scan_code+0xec>

	case L_CTRL_UP:
		ctrl_mask = BMASK8;
   115ce:	c7 05 08 d1 01 00 ff 	movl   $0xff,0x1d108
   115d5:	00 00 00 
		break;
   115d8:	eb 72                	jmp    1164c <input_scan_code+0xec>
	default:
		/*
		** Process ordinary characters only on the press (to handle
		** autorepeat).  Ignore undefined scan codes.
		*/
		if( IS_PRESS(code) ) {
   115da:	8b 45 08             	mov    0x8(%ebp),%eax
   115dd:	25 80 00 00 00       	and    $0x80,%eax
   115e2:	85 c0                	test   %eax,%eax
   115e4:	75 66                	jne    1164c <input_scan_code+0xec>
			code = scan_code[ shift ][ (int)code ];
   115e6:	a1 08 e1 01 00       	mov    0x1e108,%eax
   115eb:	c1 e0 07             	shl    $0x7,%eax
   115ee:	89 c2                	mov    %eax,%edx
   115f0:	8b 45 08             	mov    0x8(%ebp),%eax
   115f3:	01 d0                	add    %edx,%eax
   115f5:	05 00 d0 01 00       	add    $0x1d000,%eax
   115fa:	0f b6 00             	movzbl (%eax),%eax
   115fd:	0f b6 c0             	movzbl %al,%eax
   11600:	89 45 08             	mov    %eax,0x8(%ebp)
			if( code != '\377' ) {
   11603:	83 7d 08 ff          	cmpl   $0xffffffff,0x8(%ebp)
   11607:	74 43                	je     1164c <input_scan_code+0xec>
				volatile char   *next = increment( next_space );
   11609:	a1 04 d1 01 00       	mov    0x1d104,%eax
   1160e:	50                   	push   %eax
   1160f:	e8 2f ff ff ff       	call   11543 <increment>
   11614:	83 c4 04             	add    $0x4,%esp
   11617:	89 45 f8             	mov    %eax,-0x8(%ebp)

				/*
				** Store character only if there's room
				*/
				rval = code & ctrl_mask;
   1161a:	a1 08 d1 01 00       	mov    0x1d108,%eax
   1161f:	23 45 08             	and    0x8(%ebp),%eax
   11622:	89 45 fc             	mov    %eax,-0x4(%ebp)
				if( next != next_char ) {
   11625:	a1 00 d1 01 00       	mov    0x1d100,%eax
   1162a:	39 45 f8             	cmp    %eax,-0x8(%ebp)
   1162d:	74 1d                	je     1164c <input_scan_code+0xec>
					*next_space = code & ctrl_mask;
   1162f:	8b 45 08             	mov    0x8(%ebp),%eax
   11632:	89 c1                	mov    %eax,%ecx
   11634:	a1 08 d1 01 00       	mov    0x1d108,%eax
   11639:	89 c2                	mov    %eax,%edx
   1163b:	a1 04 d1 01 00       	mov    0x1d104,%eax
   11640:	21 ca                	and    %ecx,%edx
   11642:	88 10                	mov    %dl,(%eax)
					next_space = next;
   11644:	8b 45 f8             	mov    -0x8(%ebp),%eax
   11647:	a3 04 d1 01 00       	mov    %eax,0x1d104
				}
			}
		}
	}
	return( rval );
   1164c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   1164f:	c9                   	leave  
   11650:	c3                   	ret    

00011651 <keyboard_isr>:

static void keyboard_isr( int vector, int code ) {
   11651:	55                   	push   %ebp
   11652:	89 e5                	mov    %esp,%ebp
   11654:	83 ec 28             	sub    $0x28,%esp
   11657:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   1165e:	8b 45 ec             	mov    -0x14(%ebp),%eax
   11661:	89 c2                	mov    %eax,%edx
   11663:	ec                   	in     (%dx),%al
   11664:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
   11667:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax

	int data = inb( KBD_DATA );
   1166b:	0f b6 c0             	movzbl %al,%eax
   1166e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	int val  = input_scan_code( data );
   11671:	ff 75 f4             	pushl  -0xc(%ebp)
   11674:	e8 e7 fe ff ff       	call   11560 <input_scan_code>
   11679:	83 c4 04             	add    $0x4,%esp
   1167c:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// if there is a notification function, call it
	if( val != -1 && notify )
   1167f:	83 7d f0 ff          	cmpl   $0xffffffff,-0x10(%ebp)
   11683:	74 19                	je     1169e <keyboard_isr+0x4d>
   11685:	a1 28 e0 01 00       	mov    0x1e028,%eax
   1168a:	85 c0                	test   %eax,%eax
   1168c:	74 10                	je     1169e <keyboard_isr+0x4d>
		notify( val );
   1168e:	a1 28 e0 01 00       	mov    0x1e028,%eax
   11693:	83 ec 0c             	sub    $0xc,%esp
   11696:	ff 75 f0             	pushl  -0x10(%ebp)
   11699:	ff d0                	call   *%eax
   1169b:	83 c4 10             	add    $0x10,%esp
   1169e:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
   116a5:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   116a9:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
   116ad:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   116b0:	ee                   	out    %al,(%dx)

	outb( PIC1_CMD, PIC_EOI );
}
   116b1:	90                   	nop
   116b2:	c9                   	leave  
   116b3:	c3                   	ret    

000116b4 <cio_getchar>:

int cio_getchar( void ) {
   116b4:	55                   	push   %ebp
   116b5:	89 e5                	mov    %esp,%ebp
   116b7:	83 ec 28             	sub    $0x28,%esp
	__asm__ __volatile__( "pushfl; popl %0" : "=r" (val) );
   116ba:	9c                   	pushf  
   116bb:	58                   	pop    %eax
   116bc:	89 45 ec             	mov    %eax,-0x14(%ebp)
	return val;
   116bf:	8b 45 ec             	mov    -0x14(%ebp),%eax
	char    c;
	int interrupts_enabled = r_eflags() & EFL_IF;
   116c2:	25 00 02 00 00       	and    $0x200,%eax
   116c7:	89 45 f4             	mov    %eax,-0xc(%ebp)

	while( next_char == next_space ) {
   116ca:	eb 45                	jmp    11711 <cio_getchar+0x5d>
		if( !interrupts_enabled ) {
   116cc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   116d0:	75 3f                	jne    11711 <cio_getchar+0x5d>
			/*
			** Must read the next keystroke ourselves.
			*/
			while( ( inb( KBD_STATUS ) & READY ) == 0 ) {
   116d2:	90                   	nop
   116d3:	c7 45 e8 64 00 00 00 	movl   $0x64,-0x18(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   116da:	8b 45 e8             	mov    -0x18(%ebp),%eax
   116dd:	89 c2                	mov    %eax,%edx
   116df:	ec                   	in     (%dx),%al
   116e0:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
   116e3:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
   116e7:	0f b6 c0             	movzbl %al,%eax
   116ea:	83 e0 01             	and    $0x1,%eax
   116ed:	85 c0                	test   %eax,%eax
   116ef:	74 e2                	je     116d3 <cio_getchar+0x1f>
   116f1:	c7 45 e0 60 00 00 00 	movl   $0x60,-0x20(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   116f8:	8b 45 e0             	mov    -0x20(%ebp),%eax
   116fb:	89 c2                	mov    %eax,%edx
   116fd:	ec                   	in     (%dx),%al
   116fe:	88 45 df             	mov    %al,-0x21(%ebp)
	return data;
   11701:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
				;
			}
			(void) input_scan_code( inb( KBD_DATA ) );
   11705:	0f b6 c0             	movzbl %al,%eax
   11708:	50                   	push   %eax
   11709:	e8 52 fe ff ff       	call   11560 <input_scan_code>
   1170e:	83 c4 04             	add    $0x4,%esp
	while( next_char == next_space ) {
   11711:	8b 15 00 d1 01 00    	mov    0x1d100,%edx
   11717:	a1 04 d1 01 00       	mov    0x1d104,%eax
   1171c:	39 c2                	cmp    %eax,%edx
   1171e:	74 ac                	je     116cc <cio_getchar+0x18>
		}
	}

	c = *next_char & BMASK8;
   11720:	a1 00 d1 01 00       	mov    0x1d100,%eax
   11725:	0f b6 00             	movzbl (%eax),%eax
   11728:	88 45 f3             	mov    %al,-0xd(%ebp)
	next_char = increment( next_char );
   1172b:	a1 00 d1 01 00       	mov    0x1d100,%eax
   11730:	50                   	push   %eax
   11731:	e8 0d fe ff ff       	call   11543 <increment>
   11736:	83 c4 04             	add    $0x4,%esp
   11739:	a3 00 d1 01 00       	mov    %eax,0x1d100
	if( c != EOT ) {
   1173e:	80 7d f3 04          	cmpb   $0x4,-0xd(%ebp)
   11742:	74 10                	je     11754 <cio_getchar+0xa0>
		cio_putchar( c );
   11744:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   11748:	83 ec 0c             	sub    $0xc,%esp
   1174b:	50                   	push   %eax
   1174c:	e8 1c f6 ff ff       	call   10d6d <cio_putchar>
   11751:	83 c4 10             	add    $0x10,%esp
	}
	return c;
   11754:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
}
   11758:	c9                   	leave  
   11759:	c3                   	ret    

0001175a <cio_gets>:

int cio_gets( char *buffer, unsigned int size ) {
   1175a:	55                   	push   %ebp
   1175b:	89 e5                	mov    %esp,%ebp
   1175d:	83 ec 18             	sub    $0x18,%esp
	char    ch;
	int count = 0;
   11760:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	while( size > 1 ) {
   11767:	eb 2b                	jmp    11794 <cio_gets+0x3a>
		ch = cio_getchar();
   11769:	e8 46 ff ff ff       	call   116b4 <cio_getchar>
   1176e:	88 45 f3             	mov    %al,-0xd(%ebp)
		if( ch == EOT ) {
   11771:	80 7d f3 04          	cmpb   $0x4,-0xd(%ebp)
   11775:	74 25                	je     1179c <cio_gets+0x42>
			break;
		}
		*buffer++ = ch;
   11777:	8b 45 08             	mov    0x8(%ebp),%eax
   1177a:	8d 50 01             	lea    0x1(%eax),%edx
   1177d:	89 55 08             	mov    %edx,0x8(%ebp)
   11780:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
   11784:	88 10                	mov    %dl,(%eax)
		count += 1;
   11786:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
		size -= 1;
   1178a:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
		if( ch == '\n' ) {
   1178e:	80 7d f3 0a          	cmpb   $0xa,-0xd(%ebp)
   11792:	74 0b                	je     1179f <cio_gets+0x45>
	while( size > 1 ) {
   11794:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
   11798:	77 cf                	ja     11769 <cio_gets+0xf>
   1179a:	eb 04                	jmp    117a0 <cio_gets+0x46>
			break;
   1179c:	90                   	nop
   1179d:	eb 01                	jmp    117a0 <cio_gets+0x46>
			break;
   1179f:	90                   	nop
		}
	}
	*buffer = '\0';
   117a0:	8b 45 08             	mov    0x8(%ebp),%eax
   117a3:	c6 00 00             	movb   $0x0,(%eax)
	return count;
   117a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   117a9:	c9                   	leave  
   117aa:	c3                   	ret    

000117ab <cio_input_queue>:

int cio_input_queue( void ) {
   117ab:	55                   	push   %ebp
   117ac:	89 e5                	mov    %esp,%ebp
   117ae:	83 ec 10             	sub    $0x10,%esp
	int n_chars = next_space - next_char;
   117b1:	a1 04 d1 01 00       	mov    0x1d104,%eax
   117b6:	89 c2                	mov    %eax,%edx
   117b8:	a1 00 d1 01 00       	mov    0x1d100,%eax
   117bd:	29 c2                	sub    %eax,%edx
   117bf:	89 d0                	mov    %edx,%eax
   117c1:	89 45 fc             	mov    %eax,-0x4(%ebp)

	if( n_chars < 0 ) {
   117c4:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
   117c8:	79 07                	jns    117d1 <cio_input_queue+0x26>
		n_chars += C_BUFSIZE;
   117ca:	81 45 fc c8 00 00 00 	addl   $0xc8,-0x4(%ebp)
	}
	return n_chars;
   117d1:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   117d4:	c9                   	leave  
   117d5:	c3                   	ret    

000117d6 <cio_init>:

/*
** Initialization routines
*/
void cio_init( void (*fcn)(int) ) {
   117d6:	55                   	push   %ebp
   117d7:	89 e5                	mov    %esp,%ebp
   117d9:	83 ec 08             	sub    $0x8,%esp
	/*
	** Screen dimensions
	*/
	min_x  = SCREEN_MIN_X;  
   117dc:	c7 05 18 e0 01 00 00 	movl   $0x0,0x1e018
   117e3:	00 00 00 
	min_y  = SCREEN_MIN_Y;
   117e6:	c7 05 1c e0 01 00 00 	movl   $0x0,0x1e01c
   117ed:	00 00 00 
	max_x  = SCREEN_MAX_X;
   117f0:	c7 05 20 e0 01 00 4f 	movl   $0x4f,0x1e020
   117f7:	00 00 00 
	max_y  = SCREEN_MAX_Y;
   117fa:	c7 05 24 e0 01 00 18 	movl   $0x18,0x1e024
   11801:	00 00 00 

	/*
	** Scrolling region
	*/
	scroll_min_x = SCREEN_MIN_X;
   11804:	c7 05 00 e0 01 00 00 	movl   $0x0,0x1e000
   1180b:	00 00 00 
	scroll_min_y = SCREEN_MIN_Y;
   1180e:	c7 05 04 e0 01 00 00 	movl   $0x0,0x1e004
   11815:	00 00 00 
	scroll_max_x = SCREEN_MAX_X;
   11818:	c7 05 08 e0 01 00 4f 	movl   $0x4f,0x1e008
   1181f:	00 00 00 
	scroll_max_y = SCREEN_MAX_Y;
   11822:	c7 05 0c e0 01 00 18 	movl   $0x18,0x1e00c
   11829:	00 00 00 

	/*
	** Initial cursor location
	*/
	curr_y = min_y;
   1182c:	a1 1c e0 01 00       	mov    0x1e01c,%eax
   11831:	a3 14 e0 01 00       	mov    %eax,0x1e014
	curr_x = min_x;
   11836:	a1 18 e0 01 00       	mov    0x1e018,%eax
   1183b:	a3 10 e0 01 00       	mov    %eax,0x1e010
	setcursor();
   11840:	e8 b3 f2 ff ff       	call   10af8 <setcursor>

	/*
	** Notification function (or NULL)
	*/
	notify = fcn;
   11845:	8b 45 08             	mov    0x8(%ebp),%eax
   11848:	a3 28 e0 01 00       	mov    %eax,0x1e028

	/*
	** Set up the interrupt handler for the keyboard
	*/
	install_isr( VEC_KBD, keyboard_isr );
   1184d:	83 ec 08             	sub    $0x8,%esp
   11850:	68 51 16 01 00       	push   $0x11651
   11855:	6a 21                	push   $0x21
   11857:	e8 1a 3f 00 00       	call   15776 <install_isr>
   1185c:	83 c4 10             	add    $0x10,%esp
}
   1185f:	90                   	nop
   11860:	c9                   	leave  
   11861:	c3                   	ret    

00011862 <clk_isr>:
** The ISR for the clock
**
** @param vector    Vector number for the clock interrupt
** @param code      Error code (0 for this interrupt)
*/
static void clk_isr( int vector, int code ) {
   11862:	55                   	push   %ebp
   11863:	89 e5                	mov    %esp,%ebp
   11865:	57                   	push   %edi
   11866:	56                   	push   %esi
   11867:	53                   	push   %ebx
   11868:	83 ec 2c             	sub    $0x2c,%esp

	// spin the pinwheel

	++pinwheel;
   1186b:	a1 0c e1 01 00       	mov    0x1e10c,%eax
   11870:	83 c0 01             	add    $0x1,%eax
   11873:	a3 0c e1 01 00       	mov    %eax,0x1e10c
	if( pinwheel == (CLOCK_FREQ / 10) ) {
   11878:	a1 0c e1 01 00       	mov    0x1e10c,%eax
   1187d:	83 f8 64             	cmp    $0x64,%eax
   11880:	75 39                	jne    118bb <clk_isr+0x59>
		pinwheel = 0;
   11882:	c7 05 0c e1 01 00 00 	movl   $0x0,0x1e10c
   11889:	00 00 00 
		++pindex;
   1188c:	a1 10 e1 01 00       	mov    0x1e110,%eax
   11891:	83 c0 01             	add    $0x1,%eax
   11894:	a3 10 e1 01 00       	mov    %eax,0x1e110
		cio_putchar_at( 0, 0, "|/-\\"[ pindex & 3 ] );
   11899:	a1 10 e1 01 00       	mov    0x1e110,%eax
   1189e:	83 e0 03             	and    $0x3,%eax
   118a1:	0f b6 80 eb a9 01 00 	movzbl 0x1a9eb(%eax),%eax
   118a8:	0f be c0             	movsbl %al,%eax
   118ab:	83 ec 04             	sub    $0x4,%esp
   118ae:	50                   	push   %eax
   118af:	6a 00                	push   $0x0
   118b1:	6a 00                	push   $0x0
   118b3:	e8 3d f4 ff ff       	call   10cf5 <cio_putchar_at>
   118b8:	83 c4 10             	add    $0x10,%esp
	// with the SIO buffers, if non-empty).
	//
	// Define the symbol SYSTEM_STATUS with a value equal to the desired
	// reporting frequency, in seconds.

	if( (system_time % SEC_TO_TICKS(SYSTEM_STATUS)) == 0 ) {
   118bb:	8b 0d bc f1 01 00    	mov    0x1f1bc,%ecx
   118c1:	ba 59 17 b7 d1       	mov    $0xd1b71759,%edx
   118c6:	89 c8                	mov    %ecx,%eax
   118c8:	f7 e2                	mul    %edx
   118ca:	89 d0                	mov    %edx,%eax
   118cc:	c1 e8 0d             	shr    $0xd,%eax
   118cf:	69 c0 10 27 00 00    	imul   $0x2710,%eax,%eax
   118d5:	29 c1                	sub    %eax,%ecx
   118d7:	89 c8                	mov    %ecx,%eax
   118d9:	85 c0                	test   %eax,%eax
   118db:	75 76                	jne    11953 <clk_isr+0xf1>
		cio_printf_at( 1, 0, " queues: R[%u] W[%u] S[%u] Z[%u] I[%u]   ",
   118dd:	a1 04 20 02 00       	mov    0x22004,%eax
   118e2:	83 ec 0c             	sub    $0xc,%esp
   118e5:	50                   	push   %eax
   118e6:	e8 96 25 00 00       	call   13e81 <pcb_queue_length>
   118eb:	83 c4 10             	add    $0x10,%esp
   118ee:	89 45 d4             	mov    %eax,-0x2c(%ebp)
   118f1:	a1 18 20 02 00       	mov    0x22018,%eax
   118f6:	83 ec 0c             	sub    $0xc,%esp
   118f9:	50                   	push   %eax
   118fa:	e8 82 25 00 00       	call   13e81 <pcb_queue_length>
   118ff:	83 c4 10             	add    $0x10,%esp
   11902:	89 c7                	mov    %eax,%edi
   11904:	a1 08 20 02 00       	mov    0x22008,%eax
   11909:	83 ec 0c             	sub    $0xc,%esp
   1190c:	50                   	push   %eax
   1190d:	e8 6f 25 00 00       	call   13e81 <pcb_queue_length>
   11912:	83 c4 10             	add    $0x10,%esp
   11915:	89 c6                	mov    %eax,%esi
   11917:	a1 10 20 02 00       	mov    0x22010,%eax
   1191c:	83 ec 0c             	sub    $0xc,%esp
   1191f:	50                   	push   %eax
   11920:	e8 5c 25 00 00       	call   13e81 <pcb_queue_length>
   11925:	83 c4 10             	add    $0x10,%esp
   11928:	89 c3                	mov    %eax,%ebx
   1192a:	a1 d0 24 02 00       	mov    0x224d0,%eax
   1192f:	83 ec 0c             	sub    $0xc,%esp
   11932:	50                   	push   %eax
   11933:	e8 49 25 00 00       	call   13e81 <pcb_queue_length>
   11938:	83 c4 10             	add    $0x10,%esp
   1193b:	ff 75 d4             	pushl  -0x2c(%ebp)
   1193e:	57                   	push   %edi
   1193f:	56                   	push   %esi
   11940:	53                   	push   %ebx
   11941:	50                   	push   %eax
   11942:	68 70 a9 01 00       	push   $0x1a970
   11947:	6a 00                	push   $0x0
   11949:	6a 01                	push   $0x1
   1194b:	e8 b7 fb ff ff       	call   11507 <cio_printf_at>
   11950:	83 c4 20             	add    $0x20,%esp
		);
	}
#endif

	// time marches on!
	++system_time;
   11953:	a1 bc f1 01 00       	mov    0x1f1bc,%eax
   11958:	83 c0 01             	add    $0x1,%eax
   1195b:	a3 bc f1 01 00       	mov    %eax,0x1f1bc
	// we give them preference over the current process when
	// it is scheduled again

	do {
		// if there isn't anyone in the sleep queue, we're done
		if( pcb_queue_empty(sleeping) ) {
   11960:	a1 08 20 02 00       	mov    0x22008,%eax
   11965:	83 ec 0c             	sub    $0xc,%esp
   11968:	50                   	push   %eax
   11969:	e8 c0 24 00 00       	call   13e2e <pcb_queue_empty>
   1196e:	83 c4 10             	add    $0x10,%esp
   11971:	84 c0                	test   %al,%al
   11973:	0f 85 c7 00 00 00    	jne    11a40 <clk_isr+0x1de>
			break;
		}

		// peek at the first member of the queue
		pcb_t *tmp = pcb_queue_peek( sleeping );
   11979:	a1 08 20 02 00       	mov    0x22008,%eax
   1197e:	83 ec 0c             	sub    $0xc,%esp
   11981:	50                   	push   %eax
   11982:	e8 da 29 00 00       	call   14361 <pcb_queue_peek>
   11987:	83 c4 10             	add    $0x10,%esp
   1198a:	89 45 dc             	mov    %eax,-0x24(%ebp)
		assert( tmp != NULL );
   1198d:	8b 45 dc             	mov    -0x24(%ebp),%eax
   11990:	85 c0                	test   %eax,%eax
   11992:	75 38                	jne    119cc <clk_isr+0x16a>
   11994:	83 ec 04             	sub    $0x4,%esp
   11997:	68 9a a9 01 00       	push   $0x1a99a
   1199c:	6a 00                	push   $0x0
   1199e:	6a 64                	push   $0x64
   119a0:	68 a3 a9 01 00       	push   $0x1a9a3
   119a5:	68 f8 a9 01 00       	push   $0x1a9f8
   119aa:	68 ab a9 01 00       	push   $0x1a9ab
   119af:	68 00 00 02 00       	push   $0x20000
   119b4:	e8 3e 0d 00 00       	call   126f7 <sprint>
   119b9:	83 c4 20             	add    $0x20,%esp
   119bc:	83 ec 0c             	sub    $0xc,%esp
   119bf:	68 00 00 02 00       	push   $0x20000
   119c4:	e8 ae 0a 00 00       	call   12477 <kpanic>
   119c9:	83 c4 10             	add    $0x10,%esp
		// the sleep queue is sorted in ascending order by wakeup
		// time, so we know that the retrieved PCB's wakeup time is
		// the earliest of any process on the sleep queue; if that
		// time hasn't arrived yet, there's nobody left to awaken

		if( tmp->wakeup > system_time ) {
   119cc:	8b 45 dc             	mov    -0x24(%ebp),%eax
   119cf:	8b 50 10             	mov    0x10(%eax),%edx
   119d2:	a1 bc f1 01 00       	mov    0x1f1bc,%eax
   119d7:	39 c2                	cmp    %eax,%edx
   119d9:	77 68                	ja     11a43 <clk_isr+0x1e1>
			break;
		}

		// OK, we need to wake this process up
		assert( pcb_queue_remove(sleeping,&tmp) == SUCCESS );
   119db:	a1 08 20 02 00       	mov    0x22008,%eax
   119e0:	83 ec 08             	sub    $0x8,%esp
   119e3:	8d 55 dc             	lea    -0x24(%ebp),%edx
   119e6:	52                   	push   %edx
   119e7:	50                   	push   %eax
   119e8:	e8 df 26 00 00       	call   140cc <pcb_queue_remove>
   119ed:	83 c4 10             	add    $0x10,%esp
   119f0:	85 c0                	test   %eax,%eax
   119f2:	74 38                	je     11a2c <clk_isr+0x1ca>
   119f4:	83 ec 04             	sub    $0x4,%esp
   119f7:	68 c4 a9 01 00       	push   $0x1a9c4
   119fc:	6a 00                	push   $0x0
   119fe:	6a 70                	push   $0x70
   11a00:	68 a3 a9 01 00       	push   $0x1a9a3
   11a05:	68 f8 a9 01 00       	push   $0x1a9f8
   11a0a:	68 ab a9 01 00       	push   $0x1a9ab
   11a0f:	68 00 00 02 00       	push   $0x20000
   11a14:	e8 de 0c 00 00       	call   126f7 <sprint>
   11a19:	83 c4 20             	add    $0x20,%esp
   11a1c:	83 ec 0c             	sub    $0xc,%esp
   11a1f:	68 00 00 02 00       	push   $0x20000
   11a24:	e8 4e 0a 00 00       	call   12477 <kpanic>
   11a29:	83 c4 10             	add    $0x10,%esp
		schedule( tmp );
   11a2c:	8b 45 dc             	mov    -0x24(%ebp),%eax
   11a2f:	83 ec 0c             	sub    $0xc,%esp
   11a32:	50                   	push   %eax
   11a33:	e8 87 29 00 00       	call   143bf <schedule>
   11a38:	83 c4 10             	add    $0x10,%esp
	do {
   11a3b:	e9 20 ff ff ff       	jmp    11960 <clk_isr+0xfe>
			break;
   11a40:	90                   	nop
   11a41:	eb 01                	jmp    11a44 <clk_isr+0x1e2>
			break;
   11a43:	90                   	nop
	} while( 1 );

	// next, we decrement the current process' remaining time
	current->ticks -= 1;
   11a44:	a1 14 20 02 00       	mov    0x22014,%eax
   11a49:	8b 50 24             	mov    0x24(%eax),%edx
   11a4c:	a1 14 20 02 00       	mov    0x22014,%eax
   11a51:	83 ea 01             	sub    $0x1,%edx
   11a54:	89 50 24             	mov    %edx,0x24(%eax)

	// has it expired?
	if( current->ticks < 1 ) {
   11a57:	a1 14 20 02 00       	mov    0x22014,%eax
   11a5c:	8b 40 24             	mov    0x24(%eax),%eax
   11a5f:	85 c0                	test   %eax,%eax
   11a61:	75 20                	jne    11a83 <clk_isr+0x221>
		// yes! reschedule it
		schedule( current );
   11a63:	a1 14 20 02 00       	mov    0x22014,%eax
   11a68:	83 ec 0c             	sub    $0xc,%esp
   11a6b:	50                   	push   %eax
   11a6c:	e8 4e 29 00 00       	call   143bf <schedule>
   11a71:	83 c4 10             	add    $0x10,%esp
		current = NULL;
   11a74:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   11a7b:	00 00 00 
		// and pick a new process
		dispatch();
   11a7e:	e8 fd 29 00 00       	call   14480 <dispatch>
   11a83:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
   11a8a:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   11a8e:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
   11a92:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   11a95:	ee                   	out    %al,(%dx)
	}

	// tell the PIC we're done
	outb( PIC1_CMD, PIC_EOI );
}
   11a96:	90                   	nop
   11a97:	8d 65 f4             	lea    -0xc(%ebp),%esp
   11a9a:	5b                   	pop    %ebx
   11a9b:	5e                   	pop    %esi
   11a9c:	5f                   	pop    %edi
   11a9d:	5d                   	pop    %ebp
   11a9e:	c3                   	ret    

00011a9f <clk_init>:
** Name:  clk_init
**
** Initializes the clock module
**
*/
void clk_init( void ) {
   11a9f:	55                   	push   %ebp
   11aa0:	89 e5                	mov    %esp,%ebp
   11aa2:	83 ec 28             	sub    $0x28,%esp

#if TRACING_INIT
	cio_puts( " Clock" );
   11aa5:	83 ec 0c             	sub    $0xc,%esp
   11aa8:	68 f0 a9 01 00       	push   $0x1a9f0
   11aad:	e8 fb f3 ff ff       	call   10ead <cio_puts>
   11ab2:	83 c4 10             	add    $0x10,%esp
#endif

	// start the pinwheel
	pinwheel = (CLOCK_FREQ / 10) - 1;
   11ab5:	c7 05 0c e1 01 00 63 	movl   $0x63,0x1e10c
   11abc:	00 00 00 
	pindex = 0;
   11abf:	c7 05 10 e1 01 00 00 	movl   $0x0,0x1e110
   11ac6:	00 00 00 

	// return to the dawn of time
	system_time = 0;
   11ac9:	c7 05 bc f1 01 00 00 	movl   $0x0,0x1f1bc
   11ad0:	00 00 00 

	// configure the clock
	uint32_t divisor = PIT_FREQ / CLOCK_FREQ;
   11ad3:	c7 45 f4 a9 04 00 00 	movl   $0x4a9,-0xc(%ebp)
   11ada:	c7 45 e0 43 00 00 00 	movl   $0x43,-0x20(%ebp)
   11ae1:	c6 45 df 36          	movb   $0x36,-0x21(%ebp)
   11ae5:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
   11ae9:	8b 55 e0             	mov    -0x20(%ebp),%edx
   11aec:	ee                   	out    %al,(%dx)
	outb( PIT_CONTROL_PORT, PIT_0_LOAD | PIT_0_SQUARE );
	outb( PIT_0_PORT, divisor & 0xff );        // LSB of divisor
   11aed:	8b 45 f4             	mov    -0xc(%ebp),%eax
   11af0:	0f b6 c0             	movzbl %al,%eax
   11af3:	c7 45 e8 40 00 00 00 	movl   $0x40,-0x18(%ebp)
   11afa:	88 45 e7             	mov    %al,-0x19(%ebp)
   11afd:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
   11b01:	8b 55 e8             	mov    -0x18(%ebp),%edx
   11b04:	ee                   	out    %al,(%dx)
	outb( PIT_0_PORT, (divisor >> 8) & 0xff ); // MSB of divisor
   11b05:	8b 45 f4             	mov    -0xc(%ebp),%eax
   11b08:	c1 e8 08             	shr    $0x8,%eax
   11b0b:	0f b6 c0             	movzbl %al,%eax
   11b0e:	c7 45 f0 40 00 00 00 	movl   $0x40,-0x10(%ebp)
   11b15:	88 45 ef             	mov    %al,-0x11(%ebp)
   11b18:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
   11b1c:	8b 55 f0             	mov    -0x10(%ebp),%edx
   11b1f:	ee                   	out    %al,(%dx)

	// register the second-stage ISR
	install_isr( VEC_TIMER, clk_isr );
   11b20:	83 ec 08             	sub    $0x8,%esp
   11b23:	68 62 18 01 00       	push   $0x11862
   11b28:	6a 20                	push   $0x20
   11b2a:	e8 47 3c 00 00       	call   15776 <install_isr>
   11b2f:	83 c4 10             	add    $0x10,%esp
}
   11b32:	90                   	nop
   11b33:	c9                   	leave  
   11b34:	c3                   	ret    

00011b35 <kreport>:
**
** Prints configuration information about the OS on the console monitor.
**
** @param dtrace  Decode the TRACE options
*/
static void kreport( bool_t dtrace ) {
   11b35:	55                   	push   %ebp
   11b36:	89 e5                	mov    %esp,%ebp
   11b38:	83 ec 18             	sub    $0x18,%esp
   11b3b:	8b 45 08             	mov    0x8(%ebp),%eax
   11b3e:	88 45 f4             	mov    %al,-0xc(%ebp)

	cio_puts( "\n-------------------------------\n" );
   11b41:	83 ec 0c             	sub    $0xc,%esp
   11b44:	68 00 aa 01 00       	push   $0x1aa00
   11b49:	e8 5f f3 ff ff       	call   10ead <cio_puts>
   11b4e:	83 c4 10             	add    $0x10,%esp
	cio_printf( "Config:  N_PROCS = %d", N_PROCS );
   11b51:	83 ec 08             	sub    $0x8,%esp
   11b54:	6a 19                	push   $0x19
   11b56:	68 22 aa 01 00       	push   $0x1aa22
   11b5b:	e8 c7 f9 ff ff       	call   11527 <cio_printf>
   11b60:	83 c4 10             	add    $0x10,%esp
	cio_printf( " N_PRIOS = %d", N_PRIOS );
   11b63:	83 ec 08             	sub    $0x8,%esp
   11b66:	6a 04                	push   $0x4
   11b68:	68 38 aa 01 00       	push   $0x1aa38
   11b6d:	e8 b5 f9 ff ff       	call   11527 <cio_printf>
   11b72:	83 c4 10             	add    $0x10,%esp
	cio_printf( " N_STATES = %d", N_STATES );
   11b75:	83 ec 08             	sub    $0x8,%esp
   11b78:	6a 09                	push   $0x9
   11b7a:	68 46 aa 01 00       	push   $0x1aa46
   11b7f:	e8 a3 f9 ff ff       	call   11527 <cio_printf>
   11b84:	83 c4 10             	add    $0x10,%esp
	cio_printf( " CLOCK = %dHz\n", CLOCK_FREQ );
   11b87:	83 ec 08             	sub    $0x8,%esp
   11b8a:	68 e8 03 00 00       	push   $0x3e8
   11b8f:	68 55 aa 01 00       	push   $0x1aa55
   11b94:	e8 8e f9 ff ff       	call   11527 <cio_printf>
   11b99:	83 c4 10             	add    $0x10,%esp

	// This code is ugly, but it's the simplest way to
	// print out the values of compile-time options
	// without spending a lot of execution time at it.

	cio_puts( "Options: "
   11b9c:	83 ec 0c             	sub    $0xc,%esp
   11b9f:	68 64 aa 01 00       	push   $0x1aa64
   11ba4:	e8 04 f3 ff ff       	call   10ead <cio_puts>
   11ba9:	83 c4 10             	add    $0x10,%esp
		" Cstats"
#endif
		); // end of cio_puts() call

#ifdef SANITY
	cio_printf( " SANITY = %d", SANITY );
   11bac:	83 ec 08             	sub    $0x8,%esp
   11baf:	68 0f 27 00 00       	push   $0x270f
   11bb4:	68 7f aa 01 00       	push   $0x1aa7f
   11bb9:	e8 69 f9 ff ff       	call   11527 <cio_printf>
   11bbe:	83 c4 10             	add    $0x10,%esp
#ifdef STATUS
	cio_printf( " STATUS = %d", STATUS );
#endif

#if TRACE > 0
	cio_printf( " TRACE = 0x%04x\n", TRACE );
   11bc1:	83 ec 08             	sub    $0x8,%esp
   11bc4:	68 00 01 00 00       	push   $0x100
   11bc9:	68 8c aa 01 00       	push   $0x1aa8c
   11bce:	e8 54 f9 ff ff       	call   11527 <cio_printf>
   11bd3:	83 c4 10             	add    $0x10,%esp

	// decode the trace settings if that was requested
	if( TRACING_SOMETHING && dtrace ) {
   11bd6:	80 7d f4 00          	cmpb   $0x0,-0xc(%ebp)
   11bda:	74 10                	je     11bec <kreport+0xb7>

		// this one is simpler - we rely on string literal
		// concatenation in the C compiler to create one
		// long string to print out

		cio_puts( "Tracing:"
   11bdc:	83 ec 0c             	sub    $0xc,%esp
   11bdf:	68 9d aa 01 00       	push   $0x1aa9d
   11be4:	e8 c4 f2 ff ff       	call   10ead <cio_puts>
   11be9:	83 c4 10             	add    $0x10,%esp
#endif
			 ); // end of cio_puts() call
	}
#endif  /* TRACE > 0 */

	cio_putchar( '\n' );
   11bec:	83 ec 0c             	sub    $0xc,%esp
   11bef:	6a 0a                	push   $0xa
   11bf1:	e8 77 f1 ff ff       	call   10d6d <cio_putchar>
   11bf6:	83 c4 10             	add    $0x10,%esp
}
   11bf9:	90                   	nop
   11bfa:	c9                   	leave  
   11bfb:	c3                   	ret    

00011bfc <stats>:
** statistics on the console display, or will cause the
** user shell process to be dispatched.
**
** This code runs as part of the CIO ISR.
*/
static void stats( int code ) {
   11bfc:	55                   	push   %ebp
   11bfd:	89 e5                	mov    %esp,%ebp
   11bff:	83 ec 08             	sub    $0x8,%esp

	switch( code ) {
   11c02:	8b 45 08             	mov    0x8(%ebp),%eax
   11c05:	83 f8 63             	cmp    $0x63,%eax
   11c08:	74 63                	je     11c6d <stats+0x71>
   11c0a:	83 f8 63             	cmp    $0x63,%eax
   11c0d:	7f 1c                	jg     11c2b <stats+0x2f>
   11c0f:	83 f8 0d             	cmp    $0xd,%eax
   11c12:	0f 84 2f 01 00 00    	je     11d47 <stats+0x14b>
   11c18:	83 f8 61             	cmp    $0x61,%eax
   11c1b:	74 39                	je     11c56 <stats+0x5a>
   11c1d:	83 f8 0a             	cmp    $0xa,%eax
   11c20:	0f 84 21 01 00 00    	je     11d47 <stats+0x14b>
   11c26:	e9 f7 00 00 00       	jmp    11d22 <stats+0x126>
   11c2b:	83 f8 70             	cmp    $0x70,%eax
   11c2e:	74 52                	je     11c82 <stats+0x86>
   11c30:	83 f8 70             	cmp    $0x70,%eax
   11c33:	7f 0e                	jg     11c43 <stats+0x47>
   11c35:	83 f8 68             	cmp    $0x68,%eax
   11c38:	0f 84 f7 00 00 00    	je     11d35 <stats+0x139>
   11c3e:	e9 df 00 00 00       	jmp    11d22 <stats+0x126>
   11c43:	83 f8 71             	cmp    $0x71,%eax
   11c46:	74 51                	je     11c99 <stats+0x9d>
   11c48:	83 f8 72             	cmp    $0x72,%eax
   11c4b:	0f 84 c2 00 00 00    	je     11d13 <stats+0x117>
   11c51:	e9 cc 00 00 00       	jmp    11d22 <stats+0x126>

	case 'a':  // dump the active table
		ptable_dump( "\nActive processes", false );
   11c56:	83 ec 08             	sub    $0x8,%esp
   11c59:	6a 00                	push   $0x0
   11c5b:	68 ab aa 01 00       	push   $0x1aaab
   11c60:	e8 ab 2c 00 00       	call   14910 <ptable_dump>
   11c65:	83 c4 10             	add    $0x10,%esp
		break;
   11c68:	e9 db 00 00 00       	jmp    11d48 <stats+0x14c>

	case 'c':  // dump context info for all active PCBs
		ctx_dump_all( "\nContext dump" );
   11c6d:	83 ec 0c             	sub    $0xc,%esp
   11c70:	68 bd aa 01 00       	push   $0x1aabd
   11c75:	e8 cf 29 00 00       	call   14649 <ctx_dump_all>
   11c7a:	83 c4 10             	add    $0x10,%esp
		break;
   11c7d:	e9 c6 00 00 00       	jmp    11d48 <stats+0x14c>

	case 'p':  // dump the active table and all PCBs
		ptable_dump( "\nActive processes", true );
   11c82:	83 ec 08             	sub    $0x8,%esp
   11c85:	6a 01                	push   $0x1
   11c87:	68 ab aa 01 00       	push   $0x1aaab
   11c8c:	e8 7f 2c 00 00       	call   14910 <ptable_dump>
   11c91:	83 c4 10             	add    $0x10,%esp
		break;
   11c94:	e9 af 00 00 00       	jmp    11d48 <stats+0x14c>

	case 'q':  // dump the queues
		// code to dump out any/all queues
		pcb_queue_dump( "R", ready, true );
   11c99:	a1 d0 24 02 00       	mov    0x224d0,%eax
   11c9e:	83 ec 04             	sub    $0x4,%esp
   11ca1:	6a 01                	push   $0x1
   11ca3:	50                   	push   %eax
   11ca4:	68 cb aa 01 00       	push   $0x1aacb
   11ca9:	e8 4f 2b 00 00       	call   147fd <pcb_queue_dump>
   11cae:	83 c4 10             	add    $0x10,%esp
		pcb_queue_dump( "W", waiting, true );
   11cb1:	a1 10 20 02 00       	mov    0x22010,%eax
   11cb6:	83 ec 04             	sub    $0x4,%esp
   11cb9:	6a 01                	push   $0x1
   11cbb:	50                   	push   %eax
   11cbc:	68 cd aa 01 00       	push   $0x1aacd
   11cc1:	e8 37 2b 00 00       	call   147fd <pcb_queue_dump>
   11cc6:	83 c4 10             	add    $0x10,%esp
		pcb_queue_dump( "S", sleeping, true );
   11cc9:	a1 08 20 02 00       	mov    0x22008,%eax
   11cce:	83 ec 04             	sub    $0x4,%esp
   11cd1:	6a 01                	push   $0x1
   11cd3:	50                   	push   %eax
   11cd4:	68 cf aa 01 00       	push   $0x1aacf
   11cd9:	e8 1f 2b 00 00       	call   147fd <pcb_queue_dump>
   11cde:	83 c4 10             	add    $0x10,%esp
		pcb_queue_dump( "Z", zombie, true );
   11ce1:	a1 18 20 02 00       	mov    0x22018,%eax
   11ce6:	83 ec 04             	sub    $0x4,%esp
   11ce9:	6a 01                	push   $0x1
   11ceb:	50                   	push   %eax
   11cec:	68 d1 aa 01 00       	push   $0x1aad1
   11cf1:	e8 07 2b 00 00       	call   147fd <pcb_queue_dump>
   11cf6:	83 c4 10             	add    $0x10,%esp
		pcb_queue_dump( "I", sioread, true );
   11cf9:	a1 04 20 02 00       	mov    0x22004,%eax
   11cfe:	83 ec 04             	sub    $0x4,%esp
   11d01:	6a 01                	push   $0x1
   11d03:	50                   	push   %eax
   11d04:	68 d3 aa 01 00       	push   $0x1aad3
   11d09:	e8 ef 2a 00 00       	call   147fd <pcb_queue_dump>
   11d0e:	83 c4 10             	add    $0x10,%esp
		break;
   11d11:	eb 35                	jmp    11d48 <stats+0x14c>

	case 'r':  // print system configuration information
		kreport( true );
   11d13:	83 ec 0c             	sub    $0xc,%esp
   11d16:	6a 01                	push   $0x1
   11d18:	e8 18 fe ff ff       	call   11b35 <kreport>
   11d1d:	83 c4 10             	add    $0x10,%esp
		break;
   11d20:	eb 26                	jmp    11d48 <stats+0x14c>
	case '\r': // FALL THROUGH
	case '\n':
		break;
 
	default:
		cio_printf( "console: unknown request '0x%02x'\n", code );
   11d22:	83 ec 08             	sub    $0x8,%esp
   11d25:	ff 75 08             	pushl  0x8(%ebp)
   11d28:	68 d8 aa 01 00       	push   $0x1aad8
   11d2d:	e8 f5 f7 ff ff       	call   11527 <cio_printf>
   11d32:	83 c4 10             	add    $0x10,%esp
		// FALL THROUGH

	case 'h':  // help message
		cio_puts( "\nCommands:\n"
   11d35:	83 ec 0c             	sub    $0xc,%esp
   11d38:	68 fc aa 01 00       	push   $0x1aafc
   11d3d:	e8 6b f1 ff ff       	call   10ead <cio_puts>
   11d42:	83 c4 10             	add    $0x10,%esp
			"  h -- this message\n"
			"  p -- dump the active table and all PCBs\n"
			"  q -- dump the queues\n"
			"  r -- print system configuration\n"
		);
		break;
   11d45:	eb 01                	jmp    11d48 <stats+0x14c>
		break;
   11d47:	90                   	nop
	}
}
   11d48:	90                   	nop
   11d49:	c9                   	leave  
   11d4a:	c3                   	ret    

00011d4b <main>:
** Called by the startup code immediately before returning into the
** first user process.
**
** Making this type 'int' keeps the compiler happy.
*/
int main( void ) {
   11d4b:	8d 4c 24 04          	lea    0x4(%esp),%ecx
   11d4f:	83 e4 f0             	and    $0xfffffff0,%esp
   11d52:	ff 71 fc             	pushl  -0x4(%ecx)
   11d55:	55                   	push   %ebp
   11d56:	89 e5                	mov    %esp,%ebp
   11d58:	53                   	push   %ebx
   11d59:	51                   	push   %ecx
   11d5a:	83 ec 10             	sub    $0x10,%esp
	** BOILERPLATE CODE - taken from basic framework
	**
	** Initialize interrupt stuff.
	*/

	init_interrupts();  // IDT and PIC initialization
   11d5d:	e8 01 3a 00 00       	call   15763 <init_interrupts>
	** initialize it before we initialize the kernel memory
	** and queue modules.
	*/

#if defined(CONSOLE_STATS) 
	cio_init( stats );
   11d62:	83 ec 0c             	sub    $0xc,%esp
   11d65:	68 fc 1b 01 00       	push   $0x11bfc
   11d6a:	e8 67 fa ff ff       	call   117d6 <cio_init>
   11d6f:	83 c4 10             	add    $0x10,%esp
#else
	cio_init( NULL );	// no console callback routine
#endif

	cio_clearscreen();  // wipe out whatever is there
   11d72:	e8 18 f2 ff ff       	call   10f8f <cio_clearscreen>
	**
	** Other modules (clock, SIO, syscall, etc.) are expected to
	** install their own ISRs in their initialization routines.
	*/

	cio_puts( "System initialization starting.\n" );
   11d77:	83 ec 0c             	sub    $0xc,%esp
   11d7a:	68 c8 ab 01 00       	push   $0x1abc8
   11d7f:	e8 29 f1 ff ff       	call   10ead <cio_puts>
   11d84:	83 c4 10             	add    $0x10,%esp
	cio_puts( "-------------------------------\n" );
   11d87:	83 ec 0c             	sub    $0xc,%esp
   11d8a:	68 ec ab 01 00       	push   $0x1abec
   11d8f:	e8 19 f1 ff ff       	call   10ead <cio_puts>
   11d94:	83 c4 10             	add    $0x10,%esp

#if TRACING_INIT
	cio_puts( "Modules:" );
   11d97:	83 ec 0c             	sub    $0xc,%esp
   11d9a:	68 0d ac 01 00       	push   $0x1ac0d
   11d9f:	e8 09 f1 ff ff       	call   10ead <cio_puts>
   11da4:	83 c4 10             	add    $0x10,%esp
#endif

	// call the module initialization functions, being
	// careful to follow any module precedence requirements

	km_init();		// MUST BE FIRST
   11da7:	e8 f4 0d 00 00       	call   12ba0 <km_init>

	// other module initialization calls here
	clk_init();     // clock
   11dac:	e8 ee fc ff ff       	call   11a9f <clk_init>
	pcb_init();     // process (PCBs, queues, scheduler)
   11db1:	e8 1f 18 00 00       	call   135d5 <pcb_init>
	sio_init();     // serial i/o
   11db6:	e8 2e 30 00 00       	call   14de9 <sio_init>
	sys_init();     // system call
   11dbb:	e8 af 4c 00 00       	call   16a6f <sys_init>
	user_init();    // user code handling
   11dc0:	e8 8c 4f 00 00       	call   16d51 <user_init>

	cio_puts( "\nModule initialization complete.\n" );
   11dc5:	83 ec 0c             	sub    $0xc,%esp
   11dc8:	68 18 ac 01 00       	push   $0x1ac18
   11dcd:	e8 db f0 ff ff       	call   10ead <cio_puts>
   11dd2:	83 c4 10             	add    $0x10,%esp

#if TRACING_INIT
	// report our configuration options
	kreport( true );
   11dd5:	83 ec 0c             	sub    $0xc,%esp
   11dd8:	6a 01                	push   $0x1
   11dda:	e8 56 fd ff ff       	call   11b35 <kreport>
   11ddf:	83 c4 10             	add    $0x10,%esp
#endif
	cio_puts( "-------------------------------\n" );
   11de2:	83 ec 0c             	sub    $0xc,%esp
   11de5:	68 ec ab 01 00       	push   $0x1abec
   11dea:	e8 be f0 ff ff       	call   10ead <cio_puts>
   11def:	83 c4 10             	add    $0x10,%esp
	**
	**	Enabling any I/O devices (e.g., SIO xmit/rcv)
	*/


  intel_8255x_init();
   11df2:	e8 14 51 00 00       	call   16f0b <intel_8255x_init>
  delay(DELAY_5_SEC);
   11df7:	83 ec 0c             	sub    $0xc,%esp
   11dfa:	68 c8 00 00 00       	push   $0xc8
   11dff:	e8 97 39 00 00       	call   1579b <delay>
   11e04:	83 c4 10             	add    $0x10,%esp
	** This code is largely stolen from the fork() and exec()
	** implementations in syscalls.c; if those change, this must
	** also change.
	*/

	cio_puts( "Creating initial user process..." );
   11e07:	83 ec 0c             	sub    $0xc,%esp
   11e0a:	68 3c ac 01 00       	push   $0x1ac3c
   11e0f:	e8 99 f0 ff ff       	call   10ead <cio_puts>
   11e14:	83 c4 10             	add    $0x10,%esp

	// if we can't get a PCB, there's no use continuing!
	assert( pcb_alloc(&init_pcb) == SUCCESS );
   11e17:	83 ec 0c             	sub    $0xc,%esp
   11e1a:	68 0c 20 02 00       	push   $0x2200c
   11e1f:	e8 32 1a 00 00       	call   13856 <pcb_alloc>
   11e24:	83 c4 10             	add    $0x10,%esp
   11e27:	85 c0                	test   %eax,%eax
   11e29:	74 3b                	je     11e66 <main+0x11b>
   11e2b:	83 ec 04             	sub    $0x4,%esp
   11e2e:	68 5d ac 01 00       	push   $0x1ac5d
   11e33:	6a 00                	push   $0x0
   11e35:	68 56 01 00 00       	push   $0x156
   11e3a:	68 79 ac 01 00       	push   $0x1ac79
   11e3f:	68 a0 ad 01 00       	push   $0x1ada0
   11e44:	68 82 ac 01 00       	push   $0x1ac82
   11e49:	68 00 00 02 00       	push   $0x20000
   11e4e:	e8 a4 08 00 00       	call   126f7 <sprint>
   11e53:	83 c4 20             	add    $0x20,%esp
   11e56:	83 ec 0c             	sub    $0xc,%esp
   11e59:	68 00 00 02 00       	push   $0x20000
   11e5e:	e8 14 06 00 00       	call   12477 <kpanic>
   11e63:	83 c4 10             	add    $0x10,%esp

	// fill in the necessary details
	init_pcb->pid = PID_INIT;
   11e66:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11e6b:	c7 40 18 01 00 00 00 	movl   $0x1,0x18(%eax)
	init_pcb->state = STATE_NEW;
   11e72:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11e77:	c7 40 1c 01 00 00 00 	movl   $0x1,0x1c(%eax)
	init_pcb->priority = PRIO_HIGH;
   11e7e:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11e83:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

	// command-line arguments for 'init'
	const char *args[3] = { "init", "+", NULL };
   11e8a:	c7 45 ec 98 ac 01 00 	movl   $0x1ac98,-0x14(%ebp)
   11e91:	c7 45 f0 9d ac 01 00 	movl   $0x1ac9d,-0x10(%ebp)
   11e98:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// the entry point for 'init'
	extern int init(int,char **);

	// allocate a default-sized stack
	init_pcb->stack = pcb_stack_alloc( N_USTKPAGES );
   11e9f:	8b 1d 0c 20 02 00    	mov    0x2200c,%ebx
   11ea5:	83 ec 0c             	sub    $0xc,%esp
   11ea8:	6a 02                	push   $0x2
   11eaa:	e8 a7 1a 00 00       	call   13956 <pcb_stack_alloc>
   11eaf:	83 c4 10             	add    $0x10,%esp
   11eb2:	89 43 04             	mov    %eax,0x4(%ebx)
	assert( init_pcb->stack != NULL );
   11eb5:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11eba:	8b 40 04             	mov    0x4(%eax),%eax
   11ebd:	85 c0                	test   %eax,%eax
   11ebf:	75 3b                	jne    11efc <main+0x1b1>
   11ec1:	83 ec 04             	sub    $0x4,%esp
   11ec4:	68 9f ac 01 00       	push   $0x1ac9f
   11ec9:	6a 00                	push   $0x0
   11ecb:	68 65 01 00 00       	push   $0x165
   11ed0:	68 79 ac 01 00       	push   $0x1ac79
   11ed5:	68 a0 ad 01 00       	push   $0x1ada0
   11eda:	68 82 ac 01 00       	push   $0x1ac82
   11edf:	68 00 00 02 00       	push   $0x20000
   11ee4:	e8 0e 08 00 00       	call   126f7 <sprint>
   11ee9:	83 c4 20             	add    $0x20,%esp
   11eec:	83 ec 0c             	sub    $0xc,%esp
   11eef:	68 00 00 02 00       	push   $0x20000
   11ef4:	e8 7e 05 00 00       	call   12477 <kpanic>
   11ef9:	83 c4 10             	add    $0x10,%esp
	// remember that we used the default size
	init_pcb->stkpgs = N_USTKPAGES;
   11efc:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11f01:	c7 40 28 02 00 00 00 	movl   $0x2,0x28(%eax)

	// initialize the stack and the context to be restored
	init_pcb->context = stack_setup( init_pcb, (uint32_t) init, args, true );
   11f08:	b9 d2 74 01 00       	mov    $0x174d2,%ecx
   11f0d:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11f12:	8b 1d 0c 20 02 00    	mov    0x2200c,%ebx
   11f18:	6a 01                	push   $0x1
   11f1a:	8d 55 ec             	lea    -0x14(%ebp),%edx
   11f1d:	52                   	push   %edx
   11f1e:	51                   	push   %ecx
   11f1f:	50                   	push   %eax
   11f20:	e8 78 4b 00 00       	call   16a9d <stack_setup>
   11f25:	83 c4 10             	add    $0x10,%esp
   11f28:	89 03                	mov    %eax,(%ebx)
	assert( init_pcb->context != NULL );
   11f2a:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11f2f:	8b 00                	mov    (%eax),%eax
   11f31:	85 c0                	test   %eax,%eax
   11f33:	75 3b                	jne    11f70 <main+0x225>
   11f35:	83 ec 04             	sub    $0x4,%esp
   11f38:	68 b4 ac 01 00       	push   $0x1acb4
   11f3d:	6a 00                	push   $0x0
   11f3f:	68 6b 01 00 00       	push   $0x16b
   11f44:	68 79 ac 01 00       	push   $0x1ac79
   11f49:	68 a0 ad 01 00       	push   $0x1ada0
   11f4e:	68 82 ac 01 00       	push   $0x1ac82
   11f53:	68 00 00 02 00       	push   $0x20000
   11f58:	e8 9a 07 00 00       	call   126f7 <sprint>
   11f5d:	83 c4 20             	add    $0x20,%esp
   11f60:	83 ec 0c             	sub    $0xc,%esp
   11f63:	68 00 00 02 00       	push   $0x20000
   11f68:	e8 0a 05 00 00       	call   12477 <kpanic>
   11f6d:	83 c4 10             	add    $0x10,%esp

	// "i'm my own grandpa...."
	init_pcb->parent = init_pcb;
   11f70:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11f75:	8b 15 0c 20 02 00    	mov    0x2200c,%edx
   11f7b:	89 50 0c             	mov    %edx,0xc(%eax)

	// send it on its merry way
	schedule( init_pcb );
   11f7e:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11f83:	83 ec 0c             	sub    $0xc,%esp
   11f86:	50                   	push   %eax
   11f87:	e8 33 24 00 00       	call   143bf <schedule>
   11f8c:	83 c4 10             	add    $0x10,%esp

	// make sure there's no current process
	current = NULL;
   11f8f:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   11f96:	00 00 00 

	// pick a winner
	dispatch();
   11f99:	e8 e2 24 00 00       	call   14480 <dispatch>

	cio_puts( " done.\n" );
   11f9e:	83 ec 0c             	sub    $0xc,%esp
   11fa1:	68 cb ac 01 00       	push   $0x1accb
   11fa6:	e8 02 ef ff ff       	call   10ead <cio_puts>
   11fab:	83 c4 10             	add    $0x10,%esp

	delay( DELAY_1_SEC );
   11fae:	83 ec 0c             	sub    $0xc,%esp
   11fb1:	6a 28                	push   $0x28
   11fb3:	e8 e3 37 00 00       	call   1579b <delay>
   11fb8:	83 c4 10             	add    $0x10,%esp

#ifdef TRACE_CX

	// wipe out whatever is on the screen at the moment
	cio_clearscreen();
   11fbb:	e8 cf ef ff ff       	call   10f8f <cio_clearscreen>

	// define a scrolling region in the top 7 lines of the screen
	cio_setscroll( 0, 7, 99, 99 );
   11fc0:	6a 63                	push   $0x63
   11fc2:	6a 63                	push   $0x63
   11fc4:	6a 07                	push   $0x7
   11fc6:	6a 00                	push   $0x0
   11fc8:	e8 26 ec ff ff       	call   10bf3 <cio_setscroll>
   11fcd:	83 c4 10             	add    $0x10,%esp

	// clear it
	cio_clearscroll();
   11fd0:	e8 41 ef ff ff       	call   10f16 <cio_clearscroll>

	// clear the top line
	cio_puts_at( 0, 0, "*                                                                               " );
   11fd5:	83 ec 04             	sub    $0x4,%esp
   11fd8:	68 d4 ac 01 00       	push   $0x1acd4
   11fdd:	6a 00                	push   $0x0
   11fdf:	6a 00                	push   $0x0
   11fe1:	e8 85 ee ff ff       	call   10e6b <cio_puts_at>
   11fe6:	83 c4 10             	add    $0x10,%esp
	// separator
	cio_puts_at( 0, 6, "================================================================================" );
   11fe9:	83 ec 04             	sub    $0x4,%esp
   11fec:	68 28 ad 01 00       	push   $0x1ad28
   11ff1:	6a 06                	push   $0x6
   11ff3:	6a 00                	push   $0x0
   11ff5:	e8 71 ee ff ff       	call   10e6b <cio_puts_at>
   11ffa:	83 c4 10             	add    $0x10,%esp

	/*
	** END OF TERM-SPECIFIC CODE
	*/

	sio_flush( SIO_RX | SIO_TX );
   11ffd:	83 ec 0c             	sub    $0xc,%esp
   12000:	6a 03                	push   $0x3
   12002:	e8 45 30 00 00       	call   1504c <sio_flush>
   12007:	83 c4 10             	add    $0x10,%esp
	sio_enable( SIO_RX );
   1200a:	83 ec 0c             	sub    $0xc,%esp
   1200d:	6a 02                	push   $0x2
   1200f:	e8 48 2f 00 00       	call   14f5c <sio_enable>
   12014:	83 c4 10             	add    $0x10,%esp

	cio_puts( "System initialization complete.\n" );
   12017:	83 ec 0c             	sub    $0xc,%esp
   1201a:	68 7c ad 01 00       	push   $0x1ad7c
   1201f:	e8 89 ee ff ff       	call   10ead <cio_puts>
   12024:	83 c4 10             	add    $0x10,%esp
	cio_puts( "-------------------------------\n" );
   12027:	83 ec 0c             	sub    $0xc,%esp
   1202a:	68 ec ab 01 00       	push   $0x1abec
   1202f:	e8 79 ee ff ff       	call   10ead <cio_puts>
   12034:	83 c4 10             	add    $0x10,%esp
	pcb_dump( "Current: ", current, true );

	delay( DELAY_2_SEC );
#endif

	return 0;
   12037:	b8 00 00 00 00       	mov    $0x0,%eax
}
   1203c:	8d 65 f8             	lea    -0x8(%ebp),%esp
   1203f:	59                   	pop    %ecx
   12040:	5b                   	pop    %ebx
   12041:	5d                   	pop    %ebp
   12042:	8d 61 fc             	lea    -0x4(%ecx),%esp
   12045:	c3                   	ret    

00012046 <blkmov>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void blkmov( void *dst, const void *src, register uint32_t len ) {
   12046:	55                   	push   %ebp
   12047:	89 e5                	mov    %esp,%ebp
   12049:	56                   	push   %esi
   1204a:	53                   	push   %ebx
   1204b:	8b 45 10             	mov    0x10(%ebp),%eax

	// verify that the addresses are aligned and
	// the length is a multiple of four bytes
	if( (((uint32_t)dst)&0x3) != 0 ||
   1204e:	8b 55 08             	mov    0x8(%ebp),%edx
   12051:	83 e2 03             	and    $0x3,%edx
   12054:	85 d2                	test   %edx,%edx
   12056:	75 13                	jne    1206b <blkmov+0x25>
		(((uint32_t)src)&0x3) != 0 ||
   12058:	8b 55 0c             	mov    0xc(%ebp),%edx
   1205b:	83 e2 03             	and    $0x3,%edx
	if( (((uint32_t)dst)&0x3) != 0 ||
   1205e:	85 d2                	test   %edx,%edx
   12060:	75 09                	jne    1206b <blkmov+0x25>
		(len & 0x3) != 0 ) {
   12062:	89 c2                	mov    %eax,%edx
   12064:	83 e2 03             	and    $0x3,%edx
		(((uint32_t)src)&0x3) != 0 ||
   12067:	85 d2                	test   %edx,%edx
   12069:	74 14                	je     1207f <blkmov+0x39>
		// something isn't aligned, so just use memmove()
		memmove( dst, src, len );
   1206b:	83 ec 04             	sub    $0x4,%esp
   1206e:	50                   	push   %eax
   1206f:	ff 75 0c             	pushl  0xc(%ebp)
   12072:	ff 75 08             	pushl  0x8(%ebp)
   12075:	e8 48 05 00 00       	call   125c2 <memmove>
   1207a:	83 c4 10             	add    $0x10,%esp
		return;
   1207d:	eb 5a                	jmp    120d9 <blkmov+0x93>
	}

	// everything is nicely aligned, so off we go
	register uint32_t *dest = dst;
   1207f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint32_t *source = src;
   12082:	8b 75 0c             	mov    0xc(%ebp),%esi

	// now copying 32-bit values
	len /= 4;
   12085:	c1 e8 02             	shr    $0x2,%eax

	if( source < dest && (source + len) > dest ) {
   12088:	39 de                	cmp    %ebx,%esi
   1208a:	73 44                	jae    120d0 <blkmov+0x8a>
   1208c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   12093:	01 f2                	add    %esi,%edx
   12095:	39 d3                	cmp    %edx,%ebx
   12097:	73 37                	jae    120d0 <blkmov+0x8a>
		source += len;
   12099:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   120a0:	01 d6                	add    %edx,%esi
		dest += len;
   120a2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   120a9:	01 d3                	add    %edx,%ebx
		while( len-- > 0 ) {
   120ab:	eb 0a                	jmp    120b7 <blkmov+0x71>
			*--dest = *--source;
   120ad:	83 ee 04             	sub    $0x4,%esi
   120b0:	83 eb 04             	sub    $0x4,%ebx
   120b3:	8b 16                	mov    (%esi),%edx
   120b5:	89 13                	mov    %edx,(%ebx)
		while( len-- > 0 ) {
   120b7:	89 c2                	mov    %eax,%edx
   120b9:	8d 42 ff             	lea    -0x1(%edx),%eax
   120bc:	85 d2                	test   %edx,%edx
   120be:	75 ed                	jne    120ad <blkmov+0x67>
	if( source < dest && (source + len) > dest ) {
   120c0:	eb 17                	jmp    120d9 <blkmov+0x93>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   120c2:	89 f1                	mov    %esi,%ecx
   120c4:	8d 71 04             	lea    0x4(%ecx),%esi
   120c7:	89 da                	mov    %ebx,%edx
   120c9:	8d 5a 04             	lea    0x4(%edx),%ebx
   120cc:	8b 09                	mov    (%ecx),%ecx
   120ce:	89 0a                	mov    %ecx,(%edx)
		while( len-- ) {
   120d0:	89 c2                	mov    %eax,%edx
   120d2:	8d 42 ff             	lea    -0x1(%edx),%eax
   120d5:	85 d2                	test   %edx,%edx
   120d7:	75 e9                	jne    120c2 <blkmov+0x7c>
		}
	}
}
   120d9:	8d 65 f8             	lea    -0x8(%ebp),%esp
   120dc:	5b                   	pop    %ebx
   120dd:	5e                   	pop    %esi
   120de:	5d                   	pop    %ebp
   120df:	c3                   	ret    

000120e0 <bound>:
** @param value  Value to be constrained
** @param max    Upper bound
**
** @return The constrained value
*/
uint32_t bound( uint32_t min, uint32_t value, uint32_t max ) {
   120e0:	55                   	push   %ebp
   120e1:	89 e5                	mov    %esp,%ebp
	if( value < min ){
   120e3:	8b 45 0c             	mov    0xc(%ebp),%eax
   120e6:	3b 45 08             	cmp    0x8(%ebp),%eax
   120e9:	73 06                	jae    120f1 <bound+0x11>
		value = min;
   120eb:	8b 45 08             	mov    0x8(%ebp),%eax
   120ee:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	if( value > max ){
   120f1:	8b 45 0c             	mov    0xc(%ebp),%eax
   120f4:	3b 45 10             	cmp    0x10(%ebp),%eax
   120f7:	76 06                	jbe    120ff <bound+0x1f>
		value = max;
   120f9:	8b 45 10             	mov    0x10(%ebp),%eax
   120fc:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	return value;
   120ff:	8b 45 0c             	mov    0xc(%ebp),%eax
}
   12102:	5d                   	pop    %ebp
   12103:	c3                   	ret    

00012104 <cvtdec>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtdec( char *buf, int32_t value ) {
   12104:	55                   	push   %ebp
   12105:	89 e5                	mov    %esp,%ebp
   12107:	83 ec 18             	sub    $0x18,%esp
	char *bp = buf;
   1210a:	8b 45 08             	mov    0x8(%ebp),%eax
   1210d:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if( value < 0 ) {
   12110:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   12114:	79 0f                	jns    12125 <cvtdec+0x21>
		*bp++ = '-';
   12116:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12119:	8d 50 01             	lea    0x1(%eax),%edx
   1211c:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1211f:	c6 00 2d             	movb   $0x2d,(%eax)
		value = -value;
   12122:	f7 5d 0c             	negl   0xc(%ebp)
	}

	bp = cvtdec0( bp, value );
   12125:	83 ec 08             	sub    $0x8,%esp
   12128:	ff 75 0c             	pushl  0xc(%ebp)
   1212b:	ff 75 f4             	pushl  -0xc(%ebp)
   1212e:	e8 18 00 00 00       	call   1214b <cvtdec0>
   12133:	83 c4 10             	add    $0x10,%esp
   12136:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp  = '\0';
   12139:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1213c:	c6 00 00             	movb   $0x0,(%eax)

	return( bp - buf );
   1213f:	8b 55 f4             	mov    -0xc(%ebp),%edx
   12142:	8b 45 08             	mov    0x8(%ebp),%eax
   12145:	29 c2                	sub    %eax,%edx
   12147:	89 d0                	mov    %edx,%eax
}
   12149:	c9                   	leave  
   1214a:	c3                   	ret    

0001214b <cvtdec0>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *cvtdec0( char *buf, int value ) {
   1214b:	55                   	push   %ebp
   1214c:	89 e5                	mov    %esp,%ebp
   1214e:	83 ec 18             	sub    $0x18,%esp
	int quotient;

	quotient = value / 10;
   12151:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   12154:	ba 67 66 66 66       	mov    $0x66666667,%edx
   12159:	89 c8                	mov    %ecx,%eax
   1215b:	f7 ea                	imul   %edx
   1215d:	c1 fa 02             	sar    $0x2,%edx
   12160:	89 c8                	mov    %ecx,%eax
   12162:	c1 f8 1f             	sar    $0x1f,%eax
   12165:	29 c2                	sub    %eax,%edx
   12167:	89 d0                	mov    %edx,%eax
   12169:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient < 0 ) {
   1216c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12170:	79 0e                	jns    12180 <cvtdec0+0x35>
		quotient = 214748364;
   12172:	c7 45 f4 cc cc cc 0c 	movl   $0xccccccc,-0xc(%ebp)
		value = 8;
   12179:	c7 45 0c 08 00 00 00 	movl   $0x8,0xc(%ebp)
	}
	if( quotient != 0 ) {
   12180:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12184:	74 14                	je     1219a <cvtdec0+0x4f>
		buf = cvtdec0( buf, quotient );
   12186:	83 ec 08             	sub    $0x8,%esp
   12189:	ff 75 f4             	pushl  -0xc(%ebp)
   1218c:	ff 75 08             	pushl  0x8(%ebp)
   1218f:	e8 b7 ff ff ff       	call   1214b <cvtdec0>
   12194:	83 c4 10             	add    $0x10,%esp
   12197:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   1219a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   1219d:	ba 67 66 66 66       	mov    $0x66666667,%edx
   121a2:	89 c8                	mov    %ecx,%eax
   121a4:	f7 ea                	imul   %edx
   121a6:	c1 fa 02             	sar    $0x2,%edx
   121a9:	89 c8                	mov    %ecx,%eax
   121ab:	c1 f8 1f             	sar    $0x1f,%eax
   121ae:	29 c2                	sub    %eax,%edx
   121b0:	89 d0                	mov    %edx,%eax
   121b2:	c1 e0 02             	shl    $0x2,%eax
   121b5:	01 d0                	add    %edx,%eax
   121b7:	01 c0                	add    %eax,%eax
   121b9:	29 c1                	sub    %eax,%ecx
   121bb:	89 ca                	mov    %ecx,%edx
   121bd:	89 d0                	mov    %edx,%eax
   121bf:	8d 48 30             	lea    0x30(%eax),%ecx
   121c2:	8b 45 08             	mov    0x8(%ebp),%eax
   121c5:	8d 50 01             	lea    0x1(%eax),%edx
   121c8:	89 55 08             	mov    %edx,0x8(%ebp)
   121cb:	89 ca                	mov    %ecx,%edx
   121cd:	88 10                	mov    %dl,(%eax)
	return buf;
   121cf:	8b 45 08             	mov    0x8(%ebp),%eax
}
   121d2:	c9                   	leave  
   121d3:	c3                   	ret    

000121d4 <cvthex>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvthex( char *buf, uint32_t value ) {
   121d4:	55                   	push   %ebp
   121d5:	89 e5                	mov    %esp,%ebp
   121d7:	83 ec 20             	sub    $0x20,%esp
	const char hexdigits[] = "0123456789ABCDEF";
   121da:	c7 45 e3 30 31 32 33 	movl   $0x33323130,-0x1d(%ebp)
   121e1:	c7 45 e7 34 35 36 37 	movl   $0x37363534,-0x19(%ebp)
   121e8:	c7 45 eb 38 39 41 42 	movl   $0x42413938,-0x15(%ebp)
   121ef:	c7 45 ef 43 44 45 46 	movl   $0x46454443,-0x11(%ebp)
   121f6:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)
	int chars_stored = 0;
   121fa:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)

	for( int i = 0; i < 8; i += 1 ) {
   12201:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
   12208:	eb 43                	jmp    1224d <cvthex+0x79>
		uint32_t val = value & 0xf0000000;
   1220a:	8b 45 0c             	mov    0xc(%ebp),%eax
   1220d:	25 00 00 00 f0       	and    $0xf0000000,%eax
   12212:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if( chars_stored || val != 0 || i == 7 ) {
   12215:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
   12219:	75 0c                	jne    12227 <cvthex+0x53>
   1221b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1221f:	75 06                	jne    12227 <cvthex+0x53>
   12221:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   12225:	75 1e                	jne    12245 <cvthex+0x71>
			++chars_stored;
   12227:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
			val = (val >> 28) & 0xf;
   1222b:	c1 6d f4 1c          	shrl   $0x1c,-0xc(%ebp)
			*buf++ = hexdigits[val];
   1222f:	8b 45 08             	mov    0x8(%ebp),%eax
   12232:	8d 50 01             	lea    0x1(%eax),%edx
   12235:	89 55 08             	mov    %edx,0x8(%ebp)
   12238:	8d 4d e3             	lea    -0x1d(%ebp),%ecx
   1223b:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1223e:	01 ca                	add    %ecx,%edx
   12240:	0f b6 12             	movzbl (%edx),%edx
   12243:	88 10                	mov    %dl,(%eax)
		}
		value <<= 4;
   12245:	c1 65 0c 04          	shll   $0x4,0xc(%ebp)
	for( int i = 0; i < 8; i += 1 ) {
   12249:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
   1224d:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   12251:	7e b7                	jle    1220a <cvthex+0x36>
	}

	*buf = '\0';
   12253:	8b 45 08             	mov    0x8(%ebp),%eax
   12256:	c6 00 00             	movb   $0x0,(%eax)

	return( chars_stored );
   12259:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   1225c:	c9                   	leave  
   1225d:	c3                   	ret    

0001225e <cvtoct>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtoct( char *buf, uint32_t value ) {
   1225e:	55                   	push   %ebp
   1225f:	89 e5                	mov    %esp,%ebp
   12261:	83 ec 10             	sub    $0x10,%esp
	int i;
	int chars_stored = 0;
   12264:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	char *bp = buf;
   1226b:	8b 45 08             	mov    0x8(%ebp),%eax
   1226e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32_t val;

	val = ( value & 0xc0000000 );
   12271:	8b 45 0c             	mov    0xc(%ebp),%eax
   12274:	25 00 00 00 c0       	and    $0xc0000000,%eax
   12279:	89 45 f0             	mov    %eax,-0x10(%ebp)
	val >>= 30;
   1227c:	c1 6d f0 1e          	shrl   $0x1e,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   12280:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   12287:	eb 47                	jmp    122d0 <cvtoct+0x72>

		if( i == 10 || val != 0 || chars_stored ) {
   12289:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   1228d:	74 0c                	je     1229b <cvtoct+0x3d>
   1228f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12293:	75 06                	jne    1229b <cvtoct+0x3d>
   12295:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
   12299:	74 1e                	je     122b9 <cvtoct+0x5b>
			chars_stored = 1;
   1229b:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)
			val &= 0x7;
   122a2:	83 65 f0 07          	andl   $0x7,-0x10(%ebp)
			*bp++ = val + '0';
   122a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
   122a9:	8d 48 30             	lea    0x30(%eax),%ecx
   122ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
   122af:	8d 50 01             	lea    0x1(%eax),%edx
   122b2:	89 55 f4             	mov    %edx,-0xc(%ebp)
   122b5:	89 ca                	mov    %ecx,%edx
   122b7:	88 10                	mov    %dl,(%eax)
		}
		value <<= 3;
   122b9:	c1 65 0c 03          	shll   $0x3,0xc(%ebp)
		val = ( value & 0xe0000000 );
   122bd:	8b 45 0c             	mov    0xc(%ebp),%eax
   122c0:	25 00 00 00 e0       	and    $0xe0000000,%eax
   122c5:	89 45 f0             	mov    %eax,-0x10(%ebp)
		val >>= 29;
   122c8:	c1 6d f0 1d          	shrl   $0x1d,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   122cc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   122d0:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   122d4:	7e b3                	jle    12289 <cvtoct+0x2b>
	}
	*bp = '\0';
   122d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
   122d9:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   122dc:	8b 55 f4             	mov    -0xc(%ebp),%edx
   122df:	8b 45 08             	mov    0x8(%ebp),%eax
   122e2:	29 c2                	sub    %eax,%edx
   122e4:	89 d0                	mov    %edx,%eax
}
   122e6:	c9                   	leave  
   122e7:	c3                   	ret    

000122e8 <cvtuns>:
**
** @return Length of the resulting buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtuns( char *buf, uint32_t value ) {
   122e8:	55                   	push   %ebp
   122e9:	89 e5                	mov    %esp,%ebp
   122eb:	83 ec 18             	sub    $0x18,%esp
	char    *bp = buf;
   122ee:	8b 45 08             	mov    0x8(%ebp),%eax
   122f1:	89 45 f4             	mov    %eax,-0xc(%ebp)

	bp = cvtuns0( bp, value );
   122f4:	83 ec 08             	sub    $0x8,%esp
   122f7:	ff 75 0c             	pushl  0xc(%ebp)
   122fa:	ff 75 f4             	pushl  -0xc(%ebp)
   122fd:	e8 18 00 00 00       	call   1231a <cvtuns0>
   12302:	83 c4 10             	add    $0x10,%esp
   12305:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp = '\0';
   12308:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1230b:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   1230e:	8b 55 f4             	mov    -0xc(%ebp),%edx
   12311:	8b 45 08             	mov    0x8(%ebp),%eax
   12314:	29 c2                	sub    %eax,%edx
   12316:	89 d0                	mov    %edx,%eax
}
   12318:	c9                   	leave  
   12319:	c3                   	ret    

0001231a <cvtuns0>:
**
** @return Pointer to the first unused byte in the buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *cvtuns0( char *buf, uint32_t value ) {
   1231a:	55                   	push   %ebp
   1231b:	89 e5                	mov    %esp,%ebp
   1231d:	83 ec 18             	sub    $0x18,%esp
	uint32_t quotient;

	quotient = value / 10;
   12320:	8b 45 0c             	mov    0xc(%ebp),%eax
   12323:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   12328:	f7 e2                	mul    %edx
   1232a:	89 d0                	mov    %edx,%eax
   1232c:	c1 e8 03             	shr    $0x3,%eax
   1232f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient != 0 ){
   12332:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12336:	74 15                	je     1234d <cvtuns0+0x33>
		buf = cvtdec0( buf, quotient );
   12338:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1233b:	83 ec 08             	sub    $0x8,%esp
   1233e:	50                   	push   %eax
   1233f:	ff 75 08             	pushl  0x8(%ebp)
   12342:	e8 04 fe ff ff       	call   1214b <cvtdec0>
   12347:	83 c4 10             	add    $0x10,%esp
   1234a:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   1234d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   12350:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   12355:	89 c8                	mov    %ecx,%eax
   12357:	f7 e2                	mul    %edx
   12359:	c1 ea 03             	shr    $0x3,%edx
   1235c:	89 d0                	mov    %edx,%eax
   1235e:	c1 e0 02             	shl    $0x2,%eax
   12361:	01 d0                	add    %edx,%eax
   12363:	01 c0                	add    %eax,%eax
   12365:	29 c1                	sub    %eax,%ecx
   12367:	89 ca                	mov    %ecx,%edx
   12369:	89 d0                	mov    %edx,%eax
   1236b:	8d 48 30             	lea    0x30(%eax),%ecx
   1236e:	8b 45 08             	mov    0x8(%ebp),%eax
   12371:	8d 50 01             	lea    0x1(%eax),%edx
   12374:	89 55 08             	mov    %edx,0x8(%ebp)
   12377:	89 ca                	mov    %ecx,%edx
   12379:	88 10                	mov    %dl,(%eax)
	return buf;
   1237b:	8b 45 08             	mov    0x8(%ebp),%eax
}
   1237e:	c9                   	leave  
   1237f:	c3                   	ret    

00012380 <put_char_or_code>:
** is a non-printing character, in which case its hex code
** is printed
**
** @param ch    The character to be printed
*/
void put_char_or_code( int ch ) {
   12380:	55                   	push   %ebp
   12381:	89 e5                	mov    %esp,%ebp
   12383:	83 ec 08             	sub    $0x8,%esp

	if( ch >= ' ' && ch < 0x7f ) {
   12386:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
   1238a:	7e 17                	jle    123a3 <put_char_or_code+0x23>
   1238c:	83 7d 08 7e          	cmpl   $0x7e,0x8(%ebp)
   12390:	7f 11                	jg     123a3 <put_char_or_code+0x23>
		cio_putchar( ch );
   12392:	8b 45 08             	mov    0x8(%ebp),%eax
   12395:	83 ec 0c             	sub    $0xc,%esp
   12398:	50                   	push   %eax
   12399:	e8 cf e9 ff ff       	call   10d6d <cio_putchar>
   1239e:	83 c4 10             	add    $0x10,%esp
   123a1:	eb 13                	jmp    123b6 <put_char_or_code+0x36>
	} else {
		cio_printf( "\\x%02x", ch );
   123a3:	83 ec 08             	sub    $0x8,%esp
   123a6:	ff 75 08             	pushl  0x8(%ebp)
   123a9:	68 a8 ad 01 00       	push   $0x1ada8
   123ae:	e8 74 f1 ff ff       	call   11527 <cio_printf>
   123b3:	83 c4 10             	add    $0x10,%esp
	}
}
   123b6:	90                   	nop
   123b7:	c9                   	leave  
   123b8:	c3                   	ret    

000123b9 <backtrace>:
** Perform a stack backtrace
**
** @param ebp   Initial EBP to use
** @param args  Number of function argument values to print
*/
void backtrace( uint32_t *ebp, uint_t args ) {
   123b9:	55                   	push   %ebp
   123ba:	89 e5                	mov    %esp,%ebp
   123bc:	83 ec 18             	sub    $0x18,%esp

	cio_puts( "Trace:  " );
   123bf:	83 ec 0c             	sub    $0xc,%esp
   123c2:	68 af ad 01 00       	push   $0x1adaf
   123c7:	e8 e1 ea ff ff       	call   10ead <cio_puts>
   123cc:	83 c4 10             	add    $0x10,%esp
	if( ebp == NULL ) {
   123cf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   123d3:	75 15                	jne    123ea <backtrace+0x31>
		cio_puts( "NULL ebp, no trace possible\n" );
   123d5:	83 ec 0c             	sub    $0xc,%esp
   123d8:	68 b8 ad 01 00       	push   $0x1adb8
   123dd:	e8 cb ea ff ff       	call   10ead <cio_puts>
   123e2:	83 c4 10             	add    $0x10,%esp
		return;
   123e5:	e9 8b 00 00 00       	jmp    12475 <backtrace+0xbc>
	} else {
		cio_putchar( '\n' );
   123ea:	83 ec 0c             	sub    $0xc,%esp
   123ed:	6a 0a                	push   $0xa
   123ef:	e8 79 e9 ff ff       	call   10d6d <cio_putchar>
   123f4:	83 c4 10             	add    $0x10,%esp
	}

	while( ebp != NULL ){
   123f7:	eb 76                	jmp    1246f <backtrace+0xb6>

		// get return address and report it and EBP
		uint32_t ret = ebp[1];
   123f9:	8b 45 08             	mov    0x8(%ebp),%eax
   123fc:	8b 40 04             	mov    0x4(%eax),%eax
   123ff:	89 45 f0             	mov    %eax,-0x10(%ebp)
		cio_printf( " ebp %08x ret %08x args", (uint32_t) ebp, ret );
   12402:	8b 45 08             	mov    0x8(%ebp),%eax
   12405:	83 ec 04             	sub    $0x4,%esp
   12408:	ff 75 f0             	pushl  -0x10(%ebp)
   1240b:	50                   	push   %eax
   1240c:	68 d5 ad 01 00       	push   $0x1add5
   12411:	e8 11 f1 ff ff       	call   11527 <cio_printf>
   12416:	83 c4 10             	add    $0x10,%esp

		// print the requested number of function arguments
		for( uint_t i = 0; i < args; ++i ) {
   12419:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   12420:	eb 30                	jmp    12452 <backtrace+0x99>
			cio_printf( " [%u] %08x", i+1, ebp[2+i] );
   12422:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12425:	83 c0 02             	add    $0x2,%eax
   12428:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1242f:	8b 45 08             	mov    0x8(%ebp),%eax
   12432:	01 d0                	add    %edx,%eax
   12434:	8b 00                	mov    (%eax),%eax
   12436:	8b 55 f4             	mov    -0xc(%ebp),%edx
   12439:	83 c2 01             	add    $0x1,%edx
   1243c:	83 ec 04             	sub    $0x4,%esp
   1243f:	50                   	push   %eax
   12440:	52                   	push   %edx
   12441:	68 ed ad 01 00       	push   $0x1aded
   12446:	e8 dc f0 ff ff       	call   11527 <cio_printf>
   1244b:	83 c4 10             	add    $0x10,%esp
		for( uint_t i = 0; i < args; ++i ) {
   1244e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   12452:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12455:	3b 45 0c             	cmp    0xc(%ebp),%eax
   12458:	72 c8                	jb     12422 <backtrace+0x69>
		}
		cio_putchar( '\n' );
   1245a:	83 ec 0c             	sub    $0xc,%esp
   1245d:	6a 0a                	push   $0xa
   1245f:	e8 09 e9 ff ff       	call   10d6d <cio_putchar>
   12464:	83 c4 10             	add    $0x10,%esp

		// follow the chain
		ebp = (uint32_t *) *ebp;
   12467:	8b 45 08             	mov    0x8(%ebp),%eax
   1246a:	8b 00                	mov    (%eax),%eax
   1246c:	89 45 08             	mov    %eax,0x8(%ebp)
	while( ebp != NULL ){
   1246f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12473:	75 84                	jne    123f9 <backtrace+0x40>
	}
}
   12475:	c9                   	leave  
   12476:	c3                   	ret    

00012477 <kpanic>:
** (e.g., printing a stack traceback)
**
** @param msg[in]  String containing a relevant message to be printed,
**				   or NULL
*/
void kpanic( const char *msg ) {
   12477:	55                   	push   %ebp
   12478:	89 e5                	mov    %esp,%ebp
   1247a:	83 ec 18             	sub    $0x18,%esp

	cio_puts( "\n\n***** KERNEL PANIC *****\n\n" );
   1247d:	83 ec 0c             	sub    $0xc,%esp
   12480:	68 f8 ad 01 00       	push   $0x1adf8
   12485:	e8 23 ea ff ff       	call   10ead <cio_puts>
   1248a:	83 c4 10             	add    $0x10,%esp

	if( msg ) {
   1248d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12491:	74 13                	je     124a6 <kpanic+0x2f>
		cio_printf( "%s\n", msg );
   12493:	83 ec 08             	sub    $0x8,%esp
   12496:	ff 75 08             	pushl  0x8(%ebp)
   12499:	68 15 ae 01 00       	push   $0x1ae15
   1249e:	e8 84 f0 ff ff       	call   11527 <cio_printf>
   124a3:	83 c4 10             	add    $0x10,%esp
	}

	delay( DELAY_5_SEC );   // approximately
   124a6:	83 ec 0c             	sub    $0xc,%esp
   124a9:	68 c8 00 00 00       	push   $0xc8
   124ae:	e8 e8 32 00 00       	call   1579b <delay>
   124b3:	83 c4 10             	add    $0x10,%esp

	// dump a bunch of potentially useful information

	// dump the contents of the current PCB
	pcb_dump( "Current", current, true );
   124b6:	a1 14 20 02 00       	mov    0x22014,%eax
   124bb:	83 ec 04             	sub    $0x4,%esp
   124be:	6a 01                	push   $0x1
   124c0:	50                   	push   %eax
   124c1:	68 19 ae 01 00       	push   $0x1ae19
   124c6:	e8 f3 21 00 00       	call   146be <pcb_dump>
   124cb:	83 c4 10             	add    $0x10,%esp

	// dump the basic info about what's in the process table
	ptable_dump_counts();
   124ce:	e8 28 25 00 00       	call   149fb <ptable_dump_counts>

	// dump information about the queues
	pcb_queue_dump( "R", ready, true );
   124d3:	a1 d0 24 02 00       	mov    0x224d0,%eax
   124d8:	83 ec 04             	sub    $0x4,%esp
   124db:	6a 01                	push   $0x1
   124dd:	50                   	push   %eax
   124de:	68 21 ae 01 00       	push   $0x1ae21
   124e3:	e8 15 23 00 00       	call   147fd <pcb_queue_dump>
   124e8:	83 c4 10             	add    $0x10,%esp
	pcb_queue_dump( "W", waiting, true );
   124eb:	a1 10 20 02 00       	mov    0x22010,%eax
   124f0:	83 ec 04             	sub    $0x4,%esp
   124f3:	6a 01                	push   $0x1
   124f5:	50                   	push   %eax
   124f6:	68 23 ae 01 00       	push   $0x1ae23
   124fb:	e8 fd 22 00 00       	call   147fd <pcb_queue_dump>
   12500:	83 c4 10             	add    $0x10,%esp
	pcb_queue_dump( "S", sleeping, true );
   12503:	a1 08 20 02 00       	mov    0x22008,%eax
   12508:	83 ec 04             	sub    $0x4,%esp
   1250b:	6a 01                	push   $0x1
   1250d:	50                   	push   %eax
   1250e:	68 25 ae 01 00       	push   $0x1ae25
   12513:	e8 e5 22 00 00       	call   147fd <pcb_queue_dump>
   12518:	83 c4 10             	add    $0x10,%esp
	pcb_queue_dump( "Z", zombie, true );
   1251b:	a1 18 20 02 00       	mov    0x22018,%eax
   12520:	83 ec 04             	sub    $0x4,%esp
   12523:	6a 01                	push   $0x1
   12525:	50                   	push   %eax
   12526:	68 27 ae 01 00       	push   $0x1ae27
   1252b:	e8 cd 22 00 00       	call   147fd <pcb_queue_dump>
   12530:	83 c4 10             	add    $0x10,%esp
	pcb_queue_dump( "I", sioread, true );
   12533:	a1 04 20 02 00       	mov    0x22004,%eax
   12538:	83 ec 04             	sub    $0x4,%esp
   1253b:	6a 01                	push   $0x1
   1253d:	50                   	push   %eax
   1253e:	68 29 ae 01 00       	push   $0x1ae29
   12543:	e8 b5 22 00 00       	call   147fd <pcb_queue_dump>
   12548:	83 c4 10             	add    $0x10,%esp
	__asm__ __volatile__( "movl %%ebp,%0" : "=r" (val) );
   1254b:	89 e8                	mov    %ebp,%eax
   1254d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return val;
   12550:	8b 45 f4             	mov    -0xc(%ebp),%eax

	// perform a stack backtrace
	backtrace( (uint32_t *) r_ebp(), 3 );
   12553:	83 ec 08             	sub    $0x8,%esp
   12556:	6a 03                	push   $0x3
   12558:	50                   	push   %eax
   12559:	e8 5b fe ff ff       	call   123b9 <backtrace>
   1255e:	83 c4 10             	add    $0x10,%esp

	// could dump other stuff here, too

	panic( "KERNEL PANIC" );
   12561:	83 ec 0c             	sub    $0xc,%esp
   12564:	68 2b ae 01 00       	push   $0x1ae2b
   12569:	e8 d9 31 00 00       	call   15747 <panic>
   1256e:	83 c4 10             	add    $0x10,%esp
}
   12571:	90                   	nop
   12572:	c9                   	leave  
   12573:	c3                   	ret    

00012574 <memclr>:
** Initialize all bytes of a block of memory to zero
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
*/
void memclr( void *buf, register uint32_t len ) {
   12574:	55                   	push   %ebp
   12575:	89 e5                	mov    %esp,%ebp
   12577:	53                   	push   %ebx
   12578:	8b 55 0c             	mov    0xc(%ebp),%edx
	register uint8_t *dest = buf;
   1257b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and clearing
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   1257e:	eb 08                	jmp    12588 <memclr+0x14>
			*dest++ = 0;
   12580:	89 d8                	mov    %ebx,%eax
   12582:	8d 58 01             	lea    0x1(%eax),%ebx
   12585:	c6 00 00             	movb   $0x0,(%eax)
	while( len-- ) {
   12588:	89 d0                	mov    %edx,%eax
   1258a:	8d 50 ff             	lea    -0x1(%eax),%edx
   1258d:	85 c0                	test   %eax,%eax
   1258f:	75 ef                	jne    12580 <memclr+0xc>
	}
}
   12591:	90                   	nop
   12592:	5b                   	pop    %ebx
   12593:	5d                   	pop    %ebp
   12594:	c3                   	ret    

00012595 <memcpy>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void memcpy( void *dst, register const void *src, register uint32_t len ) {
   12595:	55                   	push   %ebp
   12596:	89 e5                	mov    %esp,%ebp
   12598:	56                   	push   %esi
   12599:	53                   	push   %ebx
   1259a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	register uint8_t *dest = dst;
   1259d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint8_t *source = src;
   125a0:	8b 75 0c             	mov    0xc(%ebp),%esi
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   125a3:	eb 0f                	jmp    125b4 <memcpy+0x1f>
		*dest++ = *source++;
   125a5:	89 f2                	mov    %esi,%edx
   125a7:	8d 72 01             	lea    0x1(%edx),%esi
   125aa:	89 d8                	mov    %ebx,%eax
   125ac:	8d 58 01             	lea    0x1(%eax),%ebx
   125af:	0f b6 12             	movzbl (%edx),%edx
   125b2:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   125b4:	89 c8                	mov    %ecx,%eax
   125b6:	8d 48 ff             	lea    -0x1(%eax),%ecx
   125b9:	85 c0                	test   %eax,%eax
   125bb:	75 e8                	jne    125a5 <memcpy+0x10>
	}
}
   125bd:	90                   	nop
   125be:	5b                   	pop    %ebx
   125bf:	5e                   	pop    %esi
   125c0:	5d                   	pop    %ebp
   125c1:	c3                   	ret    

000125c2 <memmove>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void memmove( void *dst, const void *src, register uint32_t len ) {
   125c2:	55                   	push   %ebp
   125c3:	89 e5                	mov    %esp,%ebp
   125c5:	56                   	push   %esi
   125c6:	53                   	push   %ebx
   125c7:	8b 45 10             	mov    0x10(%ebp),%eax
	register uint8_t *dest = dst;
   125ca:	8b 75 08             	mov    0x8(%ebp),%esi
	register const uint8_t *source = src;
   125cd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	if( source < dest && (source + len) > dest ) {
   125d0:	39 f3                	cmp    %esi,%ebx
   125d2:	73 32                	jae    12606 <memmove+0x44>
   125d4:	8d 14 03             	lea    (%ebx,%eax,1),%edx
   125d7:	39 d6                	cmp    %edx,%esi
   125d9:	73 2b                	jae    12606 <memmove+0x44>
		source += len;
   125db:	01 c3                	add    %eax,%ebx
		dest += len;
   125dd:	01 c6                	add    %eax,%esi
		while( len-- > 0 ) {
   125df:	eb 0b                	jmp    125ec <memmove+0x2a>
			*--dest = *--source;
   125e1:	83 eb 01             	sub    $0x1,%ebx
   125e4:	83 ee 01             	sub    $0x1,%esi
   125e7:	0f b6 13             	movzbl (%ebx),%edx
   125ea:	88 16                	mov    %dl,(%esi)
		while( len-- > 0 ) {
   125ec:	89 c2                	mov    %eax,%edx
   125ee:	8d 42 ff             	lea    -0x1(%edx),%eax
   125f1:	85 d2                	test   %edx,%edx
   125f3:	75 ec                	jne    125e1 <memmove+0x1f>
	if( source < dest && (source + len) > dest ) {
   125f5:	eb 18                	jmp    1260f <memmove+0x4d>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   125f7:	89 d9                	mov    %ebx,%ecx
   125f9:	8d 59 01             	lea    0x1(%ecx),%ebx
   125fc:	89 f2                	mov    %esi,%edx
   125fe:	8d 72 01             	lea    0x1(%edx),%esi
   12601:	0f b6 09             	movzbl (%ecx),%ecx
   12604:	88 0a                	mov    %cl,(%edx)
		while( len-- ) {
   12606:	89 c2                	mov    %eax,%edx
   12608:	8d 42 ff             	lea    -0x1(%edx),%eax
   1260b:	85 d2                	test   %edx,%edx
   1260d:	75 e8                	jne    125f7 <memmove+0x35>
		}
	}
}
   1260f:	90                   	nop
   12610:	5b                   	pop    %ebx
   12611:	5e                   	pop    %esi
   12612:	5d                   	pop    %ebp
   12613:	c3                   	ret    

00012614 <memset>:
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
** @param value  Initialization value
*/
void memset( void *buf, register uint32_t len, register uint32_t value ) {
   12614:	55                   	push   %ebp
   12615:	89 e5                	mov    %esp,%ebp
   12617:	53                   	push   %ebx
   12618:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register uint8_t *bp = buf;
   1261b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   1261e:	eb 0b                	jmp    1262b <memset+0x17>
		*bp++ = value;
   12620:	89 d8                	mov    %ebx,%eax
   12622:	8d 58 01             	lea    0x1(%eax),%ebx
   12625:	0f b6 55 10          	movzbl 0x10(%ebp),%edx
   12629:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   1262b:	89 c8                	mov    %ecx,%eax
   1262d:	8d 48 ff             	lea    -0x1(%eax),%ecx
   12630:	85 c0                	test   %eax,%eax
   12632:	75 ec                	jne    12620 <memset+0xc>
	}
}
   12634:	90                   	nop
   12635:	5b                   	pop    %ebx
   12636:	5d                   	pop    %ebp
   12637:	c3                   	ret    

00012638 <pad>:
**
** @return Pointer to the first byte after the padding
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *pad( char *dst, int extra, int padchar ) {
   12638:	55                   	push   %ebp
   12639:	89 e5                	mov    %esp,%ebp
	while( extra > 0 ){
   1263b:	eb 12                	jmp    1264f <pad+0x17>
		*dst++ = (char) padchar;
   1263d:	8b 45 08             	mov    0x8(%ebp),%eax
   12640:	8d 50 01             	lea    0x1(%eax),%edx
   12643:	89 55 08             	mov    %edx,0x8(%ebp)
   12646:	8b 55 10             	mov    0x10(%ebp),%edx
   12649:	88 10                	mov    %dl,(%eax)
		extra -= 1;
   1264b:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
	while( extra > 0 ){
   1264f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   12653:	7f e8                	jg     1263d <pad+0x5>
	}
	return dst;
   12655:	8b 45 08             	mov    0x8(%ebp),%eax
}
   12658:	5d                   	pop    %ebp
   12659:	c3                   	ret    

0001265a <padstr>:
** @return Pointer to the first byte after the padded string
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *padstr( char *dst, char *str, int len, int width,
				int leftadjust, int padchar ) {
   1265a:	55                   	push   %ebp
   1265b:	89 e5                	mov    %esp,%ebp
   1265d:	83 ec 18             	sub    $0x18,%esp
	int extra;

	// determine the length of the string if we need to
	if( len < 0 ){
   12660:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
   12664:	79 11                	jns    12677 <padstr+0x1d>
		len = strlen( str );
   12666:	83 ec 0c             	sub    $0xc,%esp
   12669:	ff 75 0c             	pushl  0xc(%ebp)
   1266c:	e8 03 04 00 00       	call   12a74 <strlen>
   12671:	83 c4 10             	add    $0x10,%esp
   12674:	89 45 10             	mov    %eax,0x10(%ebp)
	}

	// how much filler must we add?
	extra = width - len;
   12677:	8b 45 14             	mov    0x14(%ebp),%eax
   1267a:	2b 45 10             	sub    0x10(%ebp),%eax
   1267d:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// add filler on the left if we're not left-justifying
	if( extra > 0 && !leftadjust ){
   12680:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12684:	7e 1d                	jle    126a3 <padstr+0x49>
   12686:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   1268a:	75 17                	jne    126a3 <padstr+0x49>
		dst = pad( dst, extra, padchar );
   1268c:	83 ec 04             	sub    $0x4,%esp
   1268f:	ff 75 1c             	pushl  0x1c(%ebp)
   12692:	ff 75 f0             	pushl  -0x10(%ebp)
   12695:	ff 75 08             	pushl  0x8(%ebp)
   12698:	e8 9b ff ff ff       	call   12638 <pad>
   1269d:	83 c4 10             	add    $0x10,%esp
   126a0:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	// copy the string itself
	for( int i = 0; i < len; ++i ) {
   126a3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   126aa:	eb 1b                	jmp    126c7 <padstr+0x6d>
		*dst++ = str[i];
   126ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
   126af:	8b 45 0c             	mov    0xc(%ebp),%eax
   126b2:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
   126b5:	8b 45 08             	mov    0x8(%ebp),%eax
   126b8:	8d 50 01             	lea    0x1(%eax),%edx
   126bb:	89 55 08             	mov    %edx,0x8(%ebp)
   126be:	0f b6 11             	movzbl (%ecx),%edx
   126c1:	88 10                	mov    %dl,(%eax)
	for( int i = 0; i < len; ++i ) {
   126c3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   126c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
   126ca:	3b 45 10             	cmp    0x10(%ebp),%eax
   126cd:	7c dd                	jl     126ac <padstr+0x52>
	}

	// add filler on the right if we are left-justifying
	if( extra > 0 && leftadjust ){
   126cf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   126d3:	7e 1d                	jle    126f2 <padstr+0x98>
   126d5:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   126d9:	74 17                	je     126f2 <padstr+0x98>
		dst = pad( dst, extra, padchar );
   126db:	83 ec 04             	sub    $0x4,%esp
   126de:	ff 75 1c             	pushl  0x1c(%ebp)
   126e1:	ff 75 f0             	pushl  -0x10(%ebp)
   126e4:	ff 75 08             	pushl  0x8(%ebp)
   126e7:	e8 4c ff ff ff       	call   12638 <pad>
   126ec:	83 c4 10             	add    $0x10,%esp
   126ef:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	return dst;
   126f2:	8b 45 08             	mov    0x8(%ebp),%eax
}
   126f5:	c9                   	leave  
   126f6:	c3                   	ret    

000126f7 <sprint>:
**
** NOTE:  relies heavily on the x86 parameter passing convention
** (parameters are pushed onto the stack in reverse order as
** 32-bit values).
*/
void sprint( char *dst, char *fmt, ... ) {
   126f7:	55                   	push   %ebp
   126f8:	89 e5                	mov    %esp,%ebp
   126fa:	83 ec 38             	sub    $0x38,%esp
	** to point to the next "thing", and interpret it according
	** to the format string.
	*/
	
	// get the pointer to the first "value" parameter
	ap = (int *)(&fmt) + 1;
   126fd:	8d 45 0c             	lea    0xc(%ebp),%eax
   12700:	83 c0 04             	add    $0x4,%eax
   12703:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// iterate through the format string
	while( (ch = *fmt++) != '\0' ){
   12706:	e9 3f 02 00 00       	jmp    1294a <sprint+0x253>
		/*
		** Is it the start of a format code?
		*/
		if( ch == '%' ){
   1270b:	80 7d f3 25          	cmpb   $0x25,-0xd(%ebp)
   1270f:	0f 85 26 02 00 00    	jne    1293b <sprint+0x244>
			/*
			** Yes, get the padding and width options (if there).
			** Alignment must come at the beginning, then fill,
			** then width.
			*/
			leftadjust = 0;
   12715:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
			padchar = ' ';
   1271c:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
			width = 0;
   12723:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
			ch = *fmt++;
   1272a:	8b 45 0c             	mov    0xc(%ebp),%eax
   1272d:	8d 50 01             	lea    0x1(%eax),%edx
   12730:	89 55 0c             	mov    %edx,0xc(%ebp)
   12733:	0f b6 00             	movzbl (%eax),%eax
   12736:	88 45 f3             	mov    %al,-0xd(%ebp)
			if( ch == '-' ){
   12739:	80 7d f3 2d          	cmpb   $0x2d,-0xd(%ebp)
   1273d:	75 16                	jne    12755 <sprint+0x5e>
				leftadjust = 1;
   1273f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
				ch = *fmt++;
   12746:	8b 45 0c             	mov    0xc(%ebp),%eax
   12749:	8d 50 01             	lea    0x1(%eax),%edx
   1274c:	89 55 0c             	mov    %edx,0xc(%ebp)
   1274f:	0f b6 00             	movzbl (%eax),%eax
   12752:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			if( ch == '0' ){
   12755:	80 7d f3 30          	cmpb   $0x30,-0xd(%ebp)
   12759:	75 40                	jne    1279b <sprint+0xa4>
				padchar = '0';
   1275b:	c7 45 e4 30 00 00 00 	movl   $0x30,-0x1c(%ebp)
				ch = *fmt++;
   12762:	8b 45 0c             	mov    0xc(%ebp),%eax
   12765:	8d 50 01             	lea    0x1(%eax),%edx
   12768:	89 55 0c             	mov    %edx,0xc(%ebp)
   1276b:	0f b6 00             	movzbl (%eax),%eax
   1276e:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			while( ch >= '0' && ch <= '9' ){
   12771:	eb 28                	jmp    1279b <sprint+0xa4>
				width *= 10;
   12773:	8b 55 e8             	mov    -0x18(%ebp),%edx
   12776:	89 d0                	mov    %edx,%eax
   12778:	c1 e0 02             	shl    $0x2,%eax
   1277b:	01 d0                	add    %edx,%eax
   1277d:	01 c0                	add    %eax,%eax
   1277f:	89 45 e8             	mov    %eax,-0x18(%ebp)
				width += ch - '0';
   12782:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   12786:	83 e8 30             	sub    $0x30,%eax
   12789:	01 45 e8             	add    %eax,-0x18(%ebp)
				ch = *fmt++;
   1278c:	8b 45 0c             	mov    0xc(%ebp),%eax
   1278f:	8d 50 01             	lea    0x1(%eax),%edx
   12792:	89 55 0c             	mov    %edx,0xc(%ebp)
   12795:	0f b6 00             	movzbl (%eax),%eax
   12798:	88 45 f3             	mov    %al,-0xd(%ebp)
			while( ch >= '0' && ch <= '9' ){
   1279b:	80 7d f3 2f          	cmpb   $0x2f,-0xd(%ebp)
   1279f:	7e 06                	jle    127a7 <sprint+0xb0>
   127a1:	80 7d f3 39          	cmpb   $0x39,-0xd(%ebp)
   127a5:	7e cc                	jle    12773 <sprint+0x7c>
			}

			/*
			** What data type do we have?
			*/
			switch( ch ) {
   127a7:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   127ab:	83 e8 63             	sub    $0x63,%eax
   127ae:	83 f8 15             	cmp    $0x15,%eax
   127b1:	0f 87 93 01 00 00    	ja     1294a <sprint+0x253>
   127b7:	8b 04 85 38 ae 01 00 	mov    0x1ae38(,%eax,4),%eax
   127be:	ff e0                	jmp    *%eax

			case 'c':  // characters are passed as 32-bit values
				ch = *ap++;
   127c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
   127c3:	8d 50 04             	lea    0x4(%eax),%edx
   127c6:	89 55 f4             	mov    %edx,-0xc(%ebp)
   127c9:	8b 00                	mov    (%eax),%eax
   127cb:	88 45 f3             	mov    %al,-0xd(%ebp)
				buf[ 0 ] = ch;
   127ce:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   127d2:	88 45 d0             	mov    %al,-0x30(%ebp)
				buf[ 1 ] = '\0';
   127d5:	c6 45 d1 00          	movb   $0x0,-0x2f(%ebp)
				dst = padstr( dst, buf, 1, width, leftadjust, padchar );
   127d9:	83 ec 08             	sub    $0x8,%esp
   127dc:	ff 75 e4             	pushl  -0x1c(%ebp)
   127df:	ff 75 ec             	pushl  -0x14(%ebp)
   127e2:	ff 75 e8             	pushl  -0x18(%ebp)
   127e5:	6a 01                	push   $0x1
   127e7:	8d 45 d0             	lea    -0x30(%ebp),%eax
   127ea:	50                   	push   %eax
   127eb:	ff 75 08             	pushl  0x8(%ebp)
   127ee:	e8 67 fe ff ff       	call   1265a <padstr>
   127f3:	83 c4 20             	add    $0x20,%esp
   127f6:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   127f9:	e9 4c 01 00 00       	jmp    1294a <sprint+0x253>

			case 'd':
				len = cvtdec( buf, *ap++ );
   127fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12801:	8d 50 04             	lea    0x4(%eax),%edx
   12804:	89 55 f4             	mov    %edx,-0xc(%ebp)
   12807:	8b 00                	mov    (%eax),%eax
   12809:	83 ec 08             	sub    $0x8,%esp
   1280c:	50                   	push   %eax
   1280d:	8d 45 d0             	lea    -0x30(%ebp),%eax
   12810:	50                   	push   %eax
   12811:	e8 ee f8 ff ff       	call   12104 <cvtdec>
   12816:	83 c4 10             	add    $0x10,%esp
   12819:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   1281c:	83 ec 08             	sub    $0x8,%esp
   1281f:	ff 75 e4             	pushl  -0x1c(%ebp)
   12822:	ff 75 ec             	pushl  -0x14(%ebp)
   12825:	ff 75 e8             	pushl  -0x18(%ebp)
   12828:	ff 75 e0             	pushl  -0x20(%ebp)
   1282b:	8d 45 d0             	lea    -0x30(%ebp),%eax
   1282e:	50                   	push   %eax
   1282f:	ff 75 08             	pushl  0x8(%ebp)
   12832:	e8 23 fe ff ff       	call   1265a <padstr>
   12837:	83 c4 20             	add    $0x20,%esp
   1283a:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   1283d:	e9 08 01 00 00       	jmp    1294a <sprint+0x253>

			case 's':
				str = (char *) (*ap++);
   12842:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12845:	8d 50 04             	lea    0x4(%eax),%edx
   12848:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1284b:	8b 00                	mov    (%eax),%eax
   1284d:	89 45 dc             	mov    %eax,-0x24(%ebp)
				dst = padstr( dst, str, -1, width, leftadjust, padchar );
   12850:	83 ec 08             	sub    $0x8,%esp
   12853:	ff 75 e4             	pushl  -0x1c(%ebp)
   12856:	ff 75 ec             	pushl  -0x14(%ebp)
   12859:	ff 75 e8             	pushl  -0x18(%ebp)
   1285c:	6a ff                	push   $0xffffffff
   1285e:	ff 75 dc             	pushl  -0x24(%ebp)
   12861:	ff 75 08             	pushl  0x8(%ebp)
   12864:	e8 f1 fd ff ff       	call   1265a <padstr>
   12869:	83 c4 20             	add    $0x20,%esp
   1286c:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   1286f:	e9 d6 00 00 00       	jmp    1294a <sprint+0x253>

			case 'x':
				len = cvthex( buf, *ap++ );
   12874:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12877:	8d 50 04             	lea    0x4(%eax),%edx
   1287a:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1287d:	8b 00                	mov    (%eax),%eax
   1287f:	83 ec 08             	sub    $0x8,%esp
   12882:	50                   	push   %eax
   12883:	8d 45 d0             	lea    -0x30(%ebp),%eax
   12886:	50                   	push   %eax
   12887:	e8 48 f9 ff ff       	call   121d4 <cvthex>
   1288c:	83 c4 10             	add    $0x10,%esp
   1288f:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   12892:	83 ec 08             	sub    $0x8,%esp
   12895:	ff 75 e4             	pushl  -0x1c(%ebp)
   12898:	ff 75 ec             	pushl  -0x14(%ebp)
   1289b:	ff 75 e8             	pushl  -0x18(%ebp)
   1289e:	ff 75 e0             	pushl  -0x20(%ebp)
   128a1:	8d 45 d0             	lea    -0x30(%ebp),%eax
   128a4:	50                   	push   %eax
   128a5:	ff 75 08             	pushl  0x8(%ebp)
   128a8:	e8 ad fd ff ff       	call   1265a <padstr>
   128ad:	83 c4 20             	add    $0x20,%esp
   128b0:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   128b3:	e9 92 00 00 00       	jmp    1294a <sprint+0x253>

			case 'o':
				len = cvtoct( buf, *ap++ );
   128b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
   128bb:	8d 50 04             	lea    0x4(%eax),%edx
   128be:	89 55 f4             	mov    %edx,-0xc(%ebp)
   128c1:	8b 00                	mov    (%eax),%eax
   128c3:	83 ec 08             	sub    $0x8,%esp
   128c6:	50                   	push   %eax
   128c7:	8d 45 d0             	lea    -0x30(%ebp),%eax
   128ca:	50                   	push   %eax
   128cb:	e8 8e f9 ff ff       	call   1225e <cvtoct>
   128d0:	83 c4 10             	add    $0x10,%esp
   128d3:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   128d6:	83 ec 08             	sub    $0x8,%esp
   128d9:	ff 75 e4             	pushl  -0x1c(%ebp)
   128dc:	ff 75 ec             	pushl  -0x14(%ebp)
   128df:	ff 75 e8             	pushl  -0x18(%ebp)
   128e2:	ff 75 e0             	pushl  -0x20(%ebp)
   128e5:	8d 45 d0             	lea    -0x30(%ebp),%eax
   128e8:	50                   	push   %eax
   128e9:	ff 75 08             	pushl  0x8(%ebp)
   128ec:	e8 69 fd ff ff       	call   1265a <padstr>
   128f1:	83 c4 20             	add    $0x20,%esp
   128f4:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   128f7:	eb 51                	jmp    1294a <sprint+0x253>

			case 'u':
				len = cvtuns( buf, *ap++ );
   128f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
   128fc:	8d 50 04             	lea    0x4(%eax),%edx
   128ff:	89 55 f4             	mov    %edx,-0xc(%ebp)
   12902:	8b 00                	mov    (%eax),%eax
   12904:	83 ec 08             	sub    $0x8,%esp
   12907:	50                   	push   %eax
   12908:	8d 45 d0             	lea    -0x30(%ebp),%eax
   1290b:	50                   	push   %eax
   1290c:	e8 d7 f9 ff ff       	call   122e8 <cvtuns>
   12911:	83 c4 10             	add    $0x10,%esp
   12914:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   12917:	83 ec 08             	sub    $0x8,%esp
   1291a:	ff 75 e4             	pushl  -0x1c(%ebp)
   1291d:	ff 75 ec             	pushl  -0x14(%ebp)
   12920:	ff 75 e8             	pushl  -0x18(%ebp)
   12923:	ff 75 e0             	pushl  -0x20(%ebp)
   12926:	8d 45 d0             	lea    -0x30(%ebp),%eax
   12929:	50                   	push   %eax
   1292a:	ff 75 08             	pushl  0x8(%ebp)
   1292d:	e8 28 fd ff ff       	call   1265a <padstr>
   12932:	83 c4 20             	add    $0x20,%esp
   12935:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   12938:	90                   	nop
   12939:	eb 0f                	jmp    1294a <sprint+0x253>

			}
		} else {
			// no, it's just an ordinary character
			*dst++ = ch;
   1293b:	8b 45 08             	mov    0x8(%ebp),%eax
   1293e:	8d 50 01             	lea    0x1(%eax),%edx
   12941:	89 55 08             	mov    %edx,0x8(%ebp)
   12944:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
   12948:	88 10                	mov    %dl,(%eax)
	while( (ch = *fmt++) != '\0' ){
   1294a:	8b 45 0c             	mov    0xc(%ebp),%eax
   1294d:	8d 50 01             	lea    0x1(%eax),%edx
   12950:	89 55 0c             	mov    %edx,0xc(%ebp)
   12953:	0f b6 00             	movzbl (%eax),%eax
   12956:	88 45 f3             	mov    %al,-0xd(%ebp)
   12959:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   1295d:	0f 85 a8 fd ff ff    	jne    1270b <sprint+0x14>
		}
	}

	// NUL-terminate the result
	*dst = '\0';
   12963:	8b 45 08             	mov    0x8(%ebp),%eax
   12966:	c6 00 00             	movb   $0x0,(%eax)
}
   12969:	90                   	nop
   1296a:	c9                   	leave  
   1296b:	c3                   	ret    

0001296c <str2int>:
** @param str   The string to examine
** @param base  The radix to use in the conversion
**
** @return The converted integer
*/
int str2int( register const char *str, register int base ) {
   1296c:	55                   	push   %ebp
   1296d:	89 e5                	mov    %esp,%ebp
   1296f:	53                   	push   %ebx
   12970:	83 ec 14             	sub    $0x14,%esp
   12973:	8b 45 08             	mov    0x8(%ebp),%eax
   12976:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register int num = 0;
   12979:	bb 00 00 00 00       	mov    $0x0,%ebx
	register char bchar = '9';
   1297e:	c6 45 eb 39          	movb   $0x39,-0x15(%ebp)
	int sign = 1;
   12982:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)

	// check for leading '-'
	if( *str == '-' ) {
   12989:	0f b6 10             	movzbl (%eax),%edx
   1298c:	80 fa 2d             	cmp    $0x2d,%dl
   1298f:	75 0a                	jne    1299b <str2int+0x2f>
		sign = -1;
   12991:	c7 45 f8 ff ff ff ff 	movl   $0xffffffff,-0x8(%ebp)
		++str;
   12998:	83 c0 01             	add    $0x1,%eax
	}

	if( base != 10 ) {
   1299b:	83 f9 0a             	cmp    $0xa,%ecx
   1299e:	74 2b                	je     129cb <str2int+0x5f>
		bchar = '0' + base - 1;
   129a0:	89 ca                	mov    %ecx,%edx
   129a2:	83 c2 2f             	add    $0x2f,%edx
   129a5:	88 55 eb             	mov    %dl,-0x15(%ebp)
	}

	// iterate through the characters
	while( *str ) {
   129a8:	eb 21                	jmp    129cb <str2int+0x5f>
		if( *str < '0' || *str > bchar )
   129aa:	0f b6 10             	movzbl (%eax),%edx
   129ad:	80 fa 2f             	cmp    $0x2f,%dl
   129b0:	7e 20                	jle    129d2 <str2int+0x66>
   129b2:	0f b6 10             	movzbl (%eax),%edx
   129b5:	38 55 eb             	cmp    %dl,-0x15(%ebp)
   129b8:	7c 18                	jl     129d2 <str2int+0x66>
			break;
		num = num * base + *str - '0';
   129ba:	0f af d9             	imul   %ecx,%ebx
   129bd:	0f b6 10             	movzbl (%eax),%edx
   129c0:	0f be d2             	movsbl %dl,%edx
   129c3:	01 da                	add    %ebx,%edx
   129c5:	8d 5a d0             	lea    -0x30(%edx),%ebx
		++str;
   129c8:	83 c0 01             	add    $0x1,%eax
	while( *str ) {
   129cb:	0f b6 10             	movzbl (%eax),%edx
   129ce:	84 d2                	test   %dl,%dl
   129d0:	75 d8                	jne    129aa <str2int+0x3e>
	}

	// return the converted value
	return( num * sign );
   129d2:	89 d8                	mov    %ebx,%eax
   129d4:	0f af 45 f8          	imul   -0x8(%ebp),%eax
}
   129d8:	83 c4 14             	add    $0x14,%esp
   129db:	5b                   	pop    %ebx
   129dc:	5d                   	pop    %ebp
   129dd:	c3                   	ret    

000129de <strcat>:
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the resulting string
*/
char *strcat( register char *dst, register const char *src ) {
   129de:	55                   	push   %ebp
   129df:	89 e5                	mov    %esp,%ebp
   129e1:	56                   	push   %esi
   129e2:	53                   	push   %ebx
   129e3:	8b 45 08             	mov    0x8(%ebp),%eax
   129e6:	8b 75 0c             	mov    0xc(%ebp),%esi
	register char *tmp = dst;
   129e9:	89 c3                	mov    %eax,%ebx

	while( *dst )  // find the NUL
   129eb:	eb 03                	jmp    129f0 <strcat+0x12>
		++dst;
   129ed:	83 c0 01             	add    $0x1,%eax
	while( *dst )  // find the NUL
   129f0:	0f b6 10             	movzbl (%eax),%edx
   129f3:	84 d2                	test   %dl,%dl
   129f5:	75 f6                	jne    129ed <strcat+0xf>

	while( (*dst++ = *src++) )  // append the src string
   129f7:	90                   	nop
   129f8:	89 f1                	mov    %esi,%ecx
   129fa:	8d 71 01             	lea    0x1(%ecx),%esi
   129fd:	89 c2                	mov    %eax,%edx
   129ff:	8d 42 01             	lea    0x1(%edx),%eax
   12a02:	0f b6 09             	movzbl (%ecx),%ecx
   12a05:	88 0a                	mov    %cl,(%edx)
   12a07:	0f b6 12             	movzbl (%edx),%edx
   12a0a:	84 d2                	test   %dl,%dl
   12a0c:	75 ea                	jne    129f8 <strcat+0x1a>
		;

	return( tmp );
   12a0e:	89 d8                	mov    %ebx,%eax
}
   12a10:	5b                   	pop    %ebx
   12a11:	5e                   	pop    %esi
   12a12:	5d                   	pop    %ebp
   12a13:	c3                   	ret    

00012a14 <strcmp>:
** @param s1 The first source string
** @param s2 The second source string
**
** @return negative if s1 < s2, zero if equal, and positive if s1 > s2
*/
int strcmp( register const char *s1, register const char *s2 ) {
   12a14:	55                   	push   %ebp
   12a15:	89 e5                	mov    %esp,%ebp
   12a17:	53                   	push   %ebx
   12a18:	8b 45 08             	mov    0x8(%ebp),%eax
   12a1b:	8b 55 0c             	mov    0xc(%ebp),%edx

	while( *s1 != 0 && (*s1 == *s2) )
   12a1e:	eb 06                	jmp    12a26 <strcmp+0x12>
		++s1, ++s2;
   12a20:	83 c0 01             	add    $0x1,%eax
   12a23:	83 c2 01             	add    $0x1,%edx
	while( *s1 != 0 && (*s1 == *s2) )
   12a26:	0f b6 08             	movzbl (%eax),%ecx
   12a29:	84 c9                	test   %cl,%cl
   12a2b:	74 0a                	je     12a37 <strcmp+0x23>
   12a2d:	0f b6 18             	movzbl (%eax),%ebx
   12a30:	0f b6 0a             	movzbl (%edx),%ecx
   12a33:	38 cb                	cmp    %cl,%bl
   12a35:	74 e9                	je     12a20 <strcmp+0xc>

	return( *s1 - *s2 );
   12a37:	0f b6 00             	movzbl (%eax),%eax
   12a3a:	0f be c8             	movsbl %al,%ecx
   12a3d:	0f b6 02             	movzbl (%edx),%eax
   12a40:	0f be c0             	movsbl %al,%eax
   12a43:	29 c1                	sub    %eax,%ecx
   12a45:	89 c8                	mov    %ecx,%eax
}
   12a47:	5b                   	pop    %ebx
   12a48:	5d                   	pop    %ebp
   12a49:	c3                   	ret    

00012a4a <strcpy>:
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the copied string
*/
char *strcpy( register char *dst, register const char *src ) {
   12a4a:	55                   	push   %ebp
   12a4b:	89 e5                	mov    %esp,%ebp
   12a4d:	56                   	push   %esi
   12a4e:	53                   	push   %ebx
   12a4f:	8b 4d 08             	mov    0x8(%ebp),%ecx
   12a52:	8b 75 0c             	mov    0xc(%ebp),%esi
	register char *tmp = dst;
   12a55:	89 cb                	mov    %ecx,%ebx

	while( (*dst++ = *src++) )
   12a57:	90                   	nop
   12a58:	89 f2                	mov    %esi,%edx
   12a5a:	8d 72 01             	lea    0x1(%edx),%esi
   12a5d:	89 c8                	mov    %ecx,%eax
   12a5f:	8d 48 01             	lea    0x1(%eax),%ecx
   12a62:	0f b6 12             	movzbl (%edx),%edx
   12a65:	88 10                	mov    %dl,(%eax)
   12a67:	0f b6 00             	movzbl (%eax),%eax
   12a6a:	84 c0                	test   %al,%al
   12a6c:	75 ea                	jne    12a58 <strcpy+0xe>
		;

	return( tmp );
   12a6e:	89 d8                	mov    %ebx,%eax
}
   12a70:	5b                   	pop    %ebx
   12a71:	5e                   	pop    %esi
   12a72:	5d                   	pop    %ebp
   12a73:	c3                   	ret    

00012a74 <strlen>:
**
** @param str The string to examine
**
** @return The length of the string, or 0
*/
uint32_t strlen( register const char *str ) {
   12a74:	55                   	push   %ebp
   12a75:	89 e5                	mov    %esp,%ebp
   12a77:	53                   	push   %ebx
   12a78:	8b 55 08             	mov    0x8(%ebp),%edx
	register uint32_t len = 0;
   12a7b:	bb 00 00 00 00       	mov    $0x0,%ebx

	while( *str++ ) {
   12a80:	eb 03                	jmp    12a85 <strlen+0x11>
		++len;
   12a82:	83 c3 01             	add    $0x1,%ebx
	while( *str++ ) {
   12a85:	89 d0                	mov    %edx,%eax
   12a87:	8d 50 01             	lea    0x1(%eax),%edx
   12a8a:	0f b6 00             	movzbl (%eax),%eax
   12a8d:	84 c0                	test   %al,%al
   12a8f:	75 f1                	jne    12a82 <strlen+0xe>
	}

	return( len );
   12a91:	89 d8                	mov    %ebx,%eax
}
   12a93:	5b                   	pop    %ebx
   12a94:	5d                   	pop    %ebp
   12a95:	c3                   	ret    

00012a96 <add_block>:
** Add a block to the free list
**
** @param base   Base address of the block
** @param length Block length, in bytes
*/
static void add_block( uint32_t base, uint32_t length ) {
   12a96:	55                   	push   %ebp
   12a97:	89 e5                	mov    %esp,%ebp
   12a99:	83 ec 18             	sub    $0x18,%esp

	// don't add it if it isn't at least 4K
	if( length < SZ_PAGE ) {
   12a9c:	81 7d 0c ff 0f 00 00 	cmpl   $0xfff,0xc(%ebp)
   12aa3:	0f 86 f4 00 00 00    	jbe    12b9d <add_block+0x107>
#if ANY_KMEM
	cio_printf( "  add(%08x,%08x): ", base, length );
#endif

	// only want to add multiples of 4K; check the lower bits
	if( (length & 0xfff) != 0 ) {
   12aa9:	8b 45 0c             	mov    0xc(%ebp),%eax
   12aac:	25 ff 0f 00 00       	and    $0xfff,%eax
   12ab1:	85 c0                	test   %eax,%eax
   12ab3:	74 07                	je     12abc <add_block+0x26>
		// round it down to 4K
		length &= 0xfffff000;
   12ab5:	81 65 0c 00 f0 ff ff 	andl   $0xfffff000,0xc(%ebp)
	cio_printf( " --> base %08x length %08x", base, length );
#endif

	// create the "block"

	Blockinfo *block = (Blockinfo *) base;
   12abc:	8b 45 08             	mov    0x8(%ebp),%eax
   12abf:	89 45 ec             	mov    %eax,-0x14(%ebp)
	block->pages = B2P(length);
   12ac2:	8b 45 0c             	mov    0xc(%ebp),%eax
   12ac5:	c1 e8 0c             	shr    $0xc,%eax
   12ac8:	89 c2                	mov    %eax,%edx
   12aca:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12acd:	89 10                	mov    %edx,(%eax)
	block->next = NULL;
   12acf:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12ad2:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	** coalescing adjacent free blocks.
	**
	** Handle the easiest case first.
	*/

	if( free_pages == NULL ) {
   12ad9:	a1 14 e1 01 00       	mov    0x1e114,%eax
   12ade:	85 c0                	test   %eax,%eax
   12ae0:	75 17                	jne    12af9 <add_block+0x63>
		free_pages = block;
   12ae2:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12ae5:	a3 14 e1 01 00       	mov    %eax,0x1e114
		n_pages = block->pages;
   12aea:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12aed:	8b 00                	mov    (%eax),%eax
   12aef:	a3 1c e1 01 00       	mov    %eax,0x1e11c
		return;
   12af4:	e9 a5 00 00 00       	jmp    12b9e <add_block+0x108>
	** Find the correct insertion spot.
	*/

	Blockinfo *prev, *curr;

	prev = NULL;
   12af9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	curr = free_pages;
   12b00:	a1 14 e1 01 00       	mov    0x1e114,%eax
   12b05:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr && curr < block ) {
   12b08:	eb 0f                	jmp    12b19 <add_block+0x83>
		prev = curr;
   12b0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12b0d:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   12b10:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12b13:	8b 40 04             	mov    0x4(%eax),%eax
   12b16:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr && curr < block ) {
   12b19:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12b1d:	74 08                	je     12b27 <add_block+0x91>
   12b1f:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12b22:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   12b25:	72 e3                	jb     12b0a <add_block+0x74>
	}

	// the new block always points to its successor
	block->next = curr;
   12b27:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12b2a:	8b 55 f0             	mov    -0x10(%ebp),%edx
   12b2d:	89 50 04             	mov    %edx,0x4(%eax)
	/*
	** If prev is NULL, we're adding at the front; otherwise,
	** we're adding after some other entry (middle or end).
	*/

	if( prev == NULL ) {
   12b30:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12b34:	75 4b                	jne    12b81 <add_block+0xeb>
		// sanity check - both pointers can't be NULL
		assert( curr );
   12b36:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12b3a:	75 3b                	jne    12b77 <add_block+0xe1>
   12b3c:	83 ec 04             	sub    $0x4,%esp
   12b3f:	68 90 ae 01 00       	push   $0x1ae90
   12b44:	6a 00                	push   $0x0
   12b46:	68 0d 01 00 00       	push   $0x10d
   12b4b:	68 95 ae 01 00       	push   $0x1ae95
   12b50:	68 8c af 01 00       	push   $0x1af8c
   12b55:	68 9c ae 01 00       	push   $0x1ae9c
   12b5a:	68 00 00 02 00       	push   $0x20000
   12b5f:	e8 93 fb ff ff       	call   126f7 <sprint>
   12b64:	83 c4 20             	add    $0x20,%esp
   12b67:	83 ec 0c             	sub    $0xc,%esp
   12b6a:	68 00 00 02 00       	push   $0x20000
   12b6f:	e8 03 f9 ff ff       	call   12477 <kpanic>
   12b74:	83 c4 10             	add    $0x10,%esp
		// add at the beginning
		free_pages = block;
   12b77:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12b7a:	a3 14 e1 01 00       	mov    %eax,0x1e114
   12b7f:	eb 09                	jmp    12b8a <add_block+0xf4>
	} else {
		// inserting in the middle or at the end
		prev->next = block;
   12b81:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12b84:	8b 55 ec             	mov    -0x14(%ebp),%edx
   12b87:	89 50 04             	mov    %edx,0x4(%eax)
	}

	// bump the count of available pages
	n_pages += block->pages;
   12b8a:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12b8d:	8b 10                	mov    (%eax),%edx
   12b8f:	a1 1c e1 01 00       	mov    0x1e11c,%eax
   12b94:	01 d0                	add    %edx,%eax
   12b96:	a3 1c e1 01 00       	mov    %eax,0x1e11c
   12b9b:	eb 01                	jmp    12b9e <add_block+0x108>
		return;
   12b9d:	90                   	nop
}
   12b9e:	c9                   	leave  
   12b9f:	c3                   	ret    

00012ba0 <km_init>:
**
** Dependencies:
**    Must be called before any other init routine that uses
**    dynamic storage is called.
*/
void km_init( void ) {
   12ba0:	55                   	push   %ebp
   12ba1:	89 e5                	mov    %esp,%ebp
   12ba3:	53                   	push   %ebx
   12ba4:	83 ec 34             	sub    $0x34,%esp
	int32_t entries;
	region_t *region;

#if TRACING_INIT
	// announce that we're starting initialization
	cio_puts( " Kmem" );
   12ba7:	83 ec 0c             	sub    $0xc,%esp
   12baa:	68 b2 ae 01 00       	push   $0x1aeb2
   12baf:	e8 f9 e2 ff ff       	call   10ead <cio_puts>
   12bb4:	83 c4 10             	add    $0x10,%esp
#endif

	// initially, nothing in the free lists
	free_slices = NULL;
   12bb7:	c7 05 18 e1 01 00 00 	movl   $0x0,0x1e118
   12bbe:	00 00 00 
	free_pages = NULL;
   12bc1:	c7 05 14 e1 01 00 00 	movl   $0x0,0x1e114
   12bc8:	00 00 00 
	n_pages = n_slices = 0;
   12bcb:	c7 05 20 e1 01 00 00 	movl   $0x0,0x1e120
   12bd2:	00 00 00 
   12bd5:	a1 20 e1 01 00       	mov    0x1e120,%eax
   12bda:	a3 1c e1 01 00       	mov    %eax,0x1e11c
	km_initialized = 0;
   12bdf:	c7 05 24 e1 01 00 00 	movl   $0x0,0x1e124
   12be6:	00 00 00 

	// get the list length
	entries = *((int32_t *) MMAP_ADDR);
   12be9:	b8 00 2d 00 00       	mov    $0x2d00,%eax
   12bee:	8b 00                	mov    (%eax),%eax
   12bf0:	89 45 dc             	mov    %eax,-0x24(%ebp)
#if KMEM_OR_INIT
	cio_printf( "\nKmem: %d regions\n", entries );
#endif

	// if there are no entries, we have nothing to do!
	if( entries < 1 ) {  // note: entries == -1 could occur!
   12bf3:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   12bf7:	0f 8e 77 01 00 00    	jle    12d74 <km_init+0x1d4>
		return;
	}

	// iterate through the entries, adding things to the freelist

	region = ((region_t *) (MMAP_ADDR + 4));
   12bfd:	c7 45 f4 04 2d 00 00 	movl   $0x2d04,-0xc(%ebp)

	for( int i = 0; i < entries; ++i, ++region ) {
   12c04:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   12c0b:	e9 4c 01 00 00       	jmp    12d5c <km_init+0x1bc>
		** this to include ACPI "reclaimable" memory.
		*/

		// first, check the ACPI one-bit flags

		if( ((region->acpi) & REGION_IGNORE) == 0 ) {
   12c10:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c13:	8b 40 14             	mov    0x14(%eax),%eax
   12c16:	83 e0 01             	and    $0x1,%eax
   12c19:	85 c0                	test   %eax,%eax
   12c1b:	0f 84 26 01 00 00    	je     12d47 <km_init+0x1a7>
			cio_puts( " IGN\n" );
#endif
			continue;
		}

		if( ((region->acpi) & REGION_NONVOL) != 0 ) {
   12c21:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c24:	8b 40 14             	mov    0x14(%eax),%eax
   12c27:	83 e0 02             	and    $0x2,%eax
   12c2a:	85 c0                	test   %eax,%eax
   12c2c:	0f 85 18 01 00 00    	jne    12d4a <km_init+0x1aa>
			continue;  // we'll ignore this, too
		}

		// next, the region type

		if( (region->type) != REGION_USABLE ) {
   12c32:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c35:	8b 40 10             	mov    0x10(%eax),%eax
   12c38:	83 f8 01             	cmp    $0x1,%eax
   12c3b:	0f 85 0c 01 00 00    	jne    12d4d <km_init+0x1ad>
		** split it, and only use the portion that's within those
		** bounds.
		*/

		// grab the two 64-bit values to simplify things
		uint64_t base   = region->base.all;
   12c41:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c44:	8b 50 04             	mov    0x4(%eax),%edx
   12c47:	8b 00                	mov    (%eax),%eax
   12c49:	89 45 e8             	mov    %eax,-0x18(%ebp)
   12c4c:	89 55 ec             	mov    %edx,-0x14(%ebp)
		uint64_t length = region->length.all;
   12c4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c52:	8b 50 0c             	mov    0xc(%eax),%edx
   12c55:	8b 40 08             	mov    0x8(%eax),%eax
   12c58:	89 45 d0             	mov    %eax,-0x30(%ebp)
   12c5b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		uint64_t endpt  = base + length;
   12c5e:	8b 4d e8             	mov    -0x18(%ebp),%ecx
   12c61:	8b 5d ec             	mov    -0x14(%ebp),%ebx
   12c64:	8b 45 d0             	mov    -0x30(%ebp),%eax
   12c67:	8b 55 d4             	mov    -0x2c(%ebp),%edx
   12c6a:	01 c8                	add    %ecx,%eax
   12c6c:	11 da                	adc    %ebx,%edx
   12c6e:	89 45 e0             	mov    %eax,-0x20(%ebp)
   12c71:	89 55 e4             	mov    %edx,-0x1c(%ebp)

		// see if it's above our arbitrary high cutoff point
		if( base >= KM_HIGH_CUTOFF || endpt >= KM_HIGH_CUTOFF ) {
   12c74:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12c78:	77 24                	ja     12c9e <km_init+0xfe>
   12c7a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12c7e:	72 09                	jb     12c89 <km_init+0xe9>
   12c80:	81 7d e8 ff ff ff 3f 	cmpl   $0x3fffffff,-0x18(%ebp)
   12c87:	77 15                	ja     12c9e <km_init+0xfe>
   12c89:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12c8d:	72 3a                	jb     12cc9 <km_init+0x129>
   12c8f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12c93:	77 09                	ja     12c9e <km_init+0xfe>
   12c95:	81 7d e0 ff ff ff 3f 	cmpl   $0x3fffffff,-0x20(%ebp)
   12c9c:	76 2b                	jbe    12cc9 <km_init+0x129>

			// is the whole thing too high, or just part?
			if( base > KM_HIGH_CUTOFF ) {
   12c9e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12ca2:	72 17                	jb     12cbb <km_init+0x11b>
   12ca4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12ca8:	0f 87 a2 00 00 00    	ja     12d50 <km_init+0x1b0>
   12cae:	81 7d e8 00 00 00 40 	cmpl   $0x40000000,-0x18(%ebp)
   12cb5:	0f 87 95 00 00 00    	ja     12d50 <km_init+0x1b0>
#endif
				continue;
			}

			// some of it is usable - fix the end point
			endpt = KM_HIGH_CUTOFF;
   12cbb:	c7 45 e0 00 00 00 40 	movl   $0x40000000,-0x20(%ebp)
   12cc2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		}

		// see if it's below our low cutoff point
		if( base < KM_LOW_CUTOFF || endpt < KM_LOW_CUTOFF ) {
   12cc9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12ccd:	72 24                	jb     12cf3 <km_init+0x153>
   12ccf:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12cd3:	77 09                	ja     12cde <km_init+0x13e>
   12cd5:	81 7d e8 ff ff 0f 00 	cmpl   $0xfffff,-0x18(%ebp)
   12cdc:	76 15                	jbe    12cf3 <km_init+0x153>
   12cde:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12ce2:	77 32                	ja     12d16 <km_init+0x176>
   12ce4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12ce8:	72 09                	jb     12cf3 <km_init+0x153>
   12cea:	81 7d e0 ff ff 0f 00 	cmpl   $0xfffff,-0x20(%ebp)
   12cf1:	77 23                	ja     12d16 <km_init+0x176>

			// is the whole thing too low, or just part?
			if( endpt < KM_LOW_CUTOFF ) {
   12cf3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12cf7:	77 0f                	ja     12d08 <km_init+0x168>
   12cf9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12cfd:	72 54                	jb     12d53 <km_init+0x1b3>
   12cff:	81 7d e0 ff ff 0f 00 	cmpl   $0xfffff,-0x20(%ebp)
   12d06:	76 4b                	jbe    12d53 <km_init+0x1b3>
#endif
				continue;
			}

			// some of it is usable - fix the starting point
			base = KM_LOW_CUTOFF;
   12d08:	c7 45 e8 00 00 10 00 	movl   $0x100000,-0x18(%ebp)
   12d0f:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
		}

		// recalculate the length
		length = endpt - base;
   12d16:	8b 45 e0             	mov    -0x20(%ebp),%eax
   12d19:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   12d1c:	2b 45 e8             	sub    -0x18(%ebp),%eax
   12d1f:	1b 55 ec             	sbb    -0x14(%ebp),%edx
   12d22:	89 45 d0             	mov    %eax,-0x30(%ebp)
   12d25:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		cio_puts( " OK\n" );
#endif

		// we survived the gauntlet - add the new block

		uint32_t b32 = base   & ADDR_LOW_HALF;
   12d28:	8b 45 e8             	mov    -0x18(%ebp),%eax
   12d2b:	89 45 cc             	mov    %eax,-0x34(%ebp)
		uint32_t l32 = length & ADDR_LOW_HALF;
   12d2e:	8b 45 d0             	mov    -0x30(%ebp),%eax
   12d31:	89 45 c8             	mov    %eax,-0x38(%ebp)

		add_block( b32, l32 );
   12d34:	83 ec 08             	sub    $0x8,%esp
   12d37:	ff 75 c8             	pushl  -0x38(%ebp)
   12d3a:	ff 75 cc             	pushl  -0x34(%ebp)
   12d3d:	e8 54 fd ff ff       	call   12a96 <add_block>
   12d42:	83 c4 10             	add    $0x10,%esp
   12d45:	eb 0d                	jmp    12d54 <km_init+0x1b4>
			continue;
   12d47:	90                   	nop
   12d48:	eb 0a                	jmp    12d54 <km_init+0x1b4>
			continue;  // we'll ignore this, too
   12d4a:	90                   	nop
   12d4b:	eb 07                	jmp    12d54 <km_init+0x1b4>
			continue;  // we won't attempt to reclaim ACPI memory (yet)
   12d4d:	90                   	nop
   12d4e:	eb 04                	jmp    12d54 <km_init+0x1b4>
				continue;
   12d50:	90                   	nop
   12d51:	eb 01                	jmp    12d54 <km_init+0x1b4>
				continue;
   12d53:	90                   	nop
	for( int i = 0; i < entries; ++i, ++region ) {
   12d54:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   12d58:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
   12d5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12d5f:	3b 45 dc             	cmp    -0x24(%ebp),%eax
   12d62:	0f 8c a8 fe ff ff    	jl     12c10 <km_init+0x70>
	}

	// record the initialization
	km_initialized = 1;
   12d68:	c7 05 24 e1 01 00 01 	movl   $0x1,0x1e124
   12d6f:	00 00 00 
   12d72:	eb 01                	jmp    12d75 <km_init+0x1d5>
		return;
   12d74:	90                   	nop
#if KMEM_OR_INIT
	delay( DELAY_1_SEC );
#endif
}
   12d75:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   12d78:	c9                   	leave  
   12d79:	c3                   	ret    

00012d7a <km_dump>:
/**
** Name:    km_dump
**
** Dump the current contents of the free list to the console
*/
void km_dump( void ) {
   12d7a:	55                   	push   %ebp
   12d7b:	89 e5                	mov    %esp,%ebp
   12d7d:	53                   	push   %ebx
   12d7e:	83 ec 14             	sub    $0x14,%esp
	Blockinfo *block;

	cio_printf( "&free_pages=%08x, &free_slices %08x, %u pages, %u slices\n",
   12d81:	8b 15 20 e1 01 00    	mov    0x1e120,%edx
   12d87:	a1 1c e1 01 00       	mov    0x1e11c,%eax
   12d8c:	bb 18 e1 01 00       	mov    $0x1e118,%ebx
   12d91:	b9 14 e1 01 00       	mov    $0x1e114,%ecx
   12d96:	83 ec 0c             	sub    $0xc,%esp
   12d99:	52                   	push   %edx
   12d9a:	50                   	push   %eax
   12d9b:	53                   	push   %ebx
   12d9c:	51                   	push   %ecx
   12d9d:	68 b8 ae 01 00       	push   $0x1aeb8
   12da2:	e8 80 e7 ff ff       	call   11527 <cio_printf>
   12da7:	83 c4 20             	add    $0x20,%esp
			(uint32_t) &free_pages, (uint32_t) &free_slices,
			n_pages, n_slices );

	for( block = free_pages; block != NULL; block = block->next ) {
   12daa:	a1 14 e1 01 00       	mov    0x1e114,%eax
   12daf:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12db2:	eb 39                	jmp    12ded <km_dump+0x73>
		cio_printf(
   12db4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12db7:	8b 50 04             	mov    0x4(%eax),%edx
			"block @ 0x%08x 0x%08x pages (ends at 0x%08x) next @ 0x%08x\n",
				block, block->pages, P2B(block->pages) + (uint32_t) block,
   12dba:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12dbd:	8b 00                	mov    (%eax),%eax
   12dbf:	c1 e0 0c             	shl    $0xc,%eax
   12dc2:	89 c1                	mov    %eax,%ecx
   12dc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
		cio_printf(
   12dc7:	01 c1                	add    %eax,%ecx
   12dc9:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12dcc:	8b 00                	mov    (%eax),%eax
   12dce:	83 ec 0c             	sub    $0xc,%esp
   12dd1:	52                   	push   %edx
   12dd2:	51                   	push   %ecx
   12dd3:	50                   	push   %eax
   12dd4:	ff 75 f4             	pushl  -0xc(%ebp)
   12dd7:	68 f4 ae 01 00       	push   $0x1aef4
   12ddc:	e8 46 e7 ff ff       	call   11527 <cio_printf>
   12de1:	83 c4 20             	add    $0x20,%esp
	for( block = free_pages; block != NULL; block = block->next ) {
   12de4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12de7:	8b 40 04             	mov    0x4(%eax),%eax
   12dea:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12ded:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12df1:	75 c1                	jne    12db4 <km_dump+0x3a>
				block->next );
	}

	for( block = free_slices; block != NULL; block = block->next ) {
   12df3:	a1 18 e1 01 00       	mov    0x1e118,%eax
   12df8:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12dfb:	eb 39                	jmp    12e36 <km_dump+0xbc>
		cio_printf(
   12dfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12e00:	8b 50 04             	mov    0x4(%eax),%edx
			"block @ 0x%08x 0x%08x slices (ends at 0x%08x) next @ 0x%08x\n",
				block, block->pages, P2B(block->pages) + (uint32_t) block,
   12e03:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12e06:	8b 00                	mov    (%eax),%eax
   12e08:	c1 e0 0c             	shl    $0xc,%eax
   12e0b:	89 c1                	mov    %eax,%ecx
   12e0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
		cio_printf(
   12e10:	01 c1                	add    %eax,%ecx
   12e12:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12e15:	8b 00                	mov    (%eax),%eax
   12e17:	83 ec 0c             	sub    $0xc,%esp
   12e1a:	52                   	push   %edx
   12e1b:	51                   	push   %ecx
   12e1c:	50                   	push   %eax
   12e1d:	ff 75 f4             	pushl  -0xc(%ebp)
   12e20:	68 30 af 01 00       	push   $0x1af30
   12e25:	e8 fd e6 ff ff       	call   11527 <cio_printf>
   12e2a:	83 c4 20             	add    $0x20,%esp
	for( block = free_slices; block != NULL; block = block->next ) {
   12e2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12e30:	8b 40 04             	mov    0x4(%eax),%eax
   12e33:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12e36:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12e3a:	75 c1                	jne    12dfd <km_dump+0x83>
				block->next );
	}

}
   12e3c:	90                   	nop
   12e3d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   12e40:	c9                   	leave  
   12e41:	c3                   	ret    

00012e42 <km_page_alloc>:
** @param count  Number of contiguous pages desired
**
** @return a pointer to the beginning of the first allocated page,
**         or NULL if no memory is available
*/
void *km_page_alloc( unsigned int count ) {
   12e42:	55                   	push   %ebp
   12e43:	89 e5                	mov    %esp,%ebp
   12e45:	83 ec 28             	sub    $0x28,%esp

	assert( km_initialized );
   12e48:	a1 24 e1 01 00       	mov    0x1e124,%eax
   12e4d:	85 c0                	test   %eax,%eax
   12e4f:	75 3b                	jne    12e8c <km_page_alloc+0x4a>
   12e51:	83 ec 04             	sub    $0x4,%esp
   12e54:	68 6d af 01 00       	push   $0x1af6d
   12e59:	6a 00                	push   $0x0
   12e5b:	68 ee 01 00 00       	push   $0x1ee
   12e60:	68 95 ae 01 00       	push   $0x1ae95
   12e65:	68 98 af 01 00       	push   $0x1af98
   12e6a:	68 9c ae 01 00       	push   $0x1ae9c
   12e6f:	68 00 00 02 00       	push   $0x20000
   12e74:	e8 7e f8 ff ff       	call   126f7 <sprint>
   12e79:	83 c4 20             	add    $0x20,%esp
   12e7c:	83 ec 0c             	sub    $0xc,%esp
   12e7f:	68 00 00 02 00       	push   $0x20000
   12e84:	e8 ee f5 ff ff       	call   12477 <kpanic>
   12e89:	83 c4 10             	add    $0x10,%esp

	// make sure we actually need to do something!
	if( count < 1 ) {
   12e8c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12e90:	75 0a                	jne    12e9c <km_page_alloc+0x5a>
		return( NULL );
   12e92:	b8 00 00 00 00       	mov    $0x0,%eax
   12e97:	e9 a9 00 00 00       	jmp    12f45 <km_page_alloc+0x103>
	/*
	** Look for the first entry that is large enough.
	*/

	// pointer to the current block
	Blockinfo *block = free_pages;
   12e9c:	a1 14 e1 01 00       	mov    0x1e114,%eax
   12ea1:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// pointer to where the pointer to the current block is
	Blockinfo **pointer = &free_pages;
   12ea4:	c7 45 f0 14 e1 01 00 	movl   $0x1e114,-0x10(%ebp)

	while( block != NULL && block->pages < count ){
   12eab:	eb 11                	jmp    12ebe <km_page_alloc+0x7c>
		pointer = &block->next;
   12ead:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12eb0:	83 c0 04             	add    $0x4,%eax
   12eb3:	89 45 f0             	mov    %eax,-0x10(%ebp)
		block = *pointer;
   12eb6:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12eb9:	8b 00                	mov    (%eax),%eax
   12ebb:	89 45 f4             	mov    %eax,-0xc(%ebp)
	while( block != NULL && block->pages < count ){
   12ebe:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12ec2:	74 0a                	je     12ece <km_page_alloc+0x8c>
   12ec4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ec7:	8b 00                	mov    (%eax),%eax
   12ec9:	39 45 08             	cmp    %eax,0x8(%ebp)
   12ecc:	77 df                	ja     12ead <km_page_alloc+0x6b>
	}

	// did we find a big enough block?
	if( block == NULL ){
   12ece:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12ed2:	75 07                	jne    12edb <km_page_alloc+0x99>
		// nope!
		return( NULL );
   12ed4:	b8 00 00 00 00       	mov    $0x0,%eax
   12ed9:	eb 6a                	jmp    12f45 <km_page_alloc+0x103>
	}

	// found one!  check the length

	if( block->pages == count ) {
   12edb:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ede:	8b 00                	mov    (%eax),%eax
   12ee0:	39 45 08             	cmp    %eax,0x8(%ebp)
   12ee3:	75 0d                	jne    12ef2 <km_page_alloc+0xb0>

		// exactly the right size - unlink it from the list

		*pointer = block->next;
   12ee5:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ee8:	8b 50 04             	mov    0x4(%eax),%edx
   12eeb:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12eee:	89 10                	mov    %edx,(%eax)
   12ef0:	eb 43                	jmp    12f35 <km_page_alloc+0xf3>

		// bigger than we need - carve the amount we need off
		// the beginning of this block

		// remember where this chunk begins
		Blockinfo *chunk = block;
   12ef2:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ef5:	89 45 ec             	mov    %eax,-0x14(%ebp)

		// how much space will be left over?
		int excess = block->pages - count;
   12ef8:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12efb:	8b 00                	mov    (%eax),%eax
   12efd:	2b 45 08             	sub    0x8(%ebp),%eax
   12f00:	89 45 e8             	mov    %eax,-0x18(%ebp)

		// find the start of the new fragment
		Blockinfo *fragment = (Blockinfo *) ( (uint8_t *) block + P2B(count) );
   12f03:	8b 45 08             	mov    0x8(%ebp),%eax
   12f06:	c1 e0 0c             	shl    $0xc,%eax
   12f09:	89 c2                	mov    %eax,%edx
   12f0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12f0e:	01 d0                	add    %edx,%eax
   12f10:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// set the length and link for the new fragment
		fragment->pages = excess;
   12f13:	8b 55 e8             	mov    -0x18(%ebp),%edx
   12f16:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   12f19:	89 10                	mov    %edx,(%eax)
		fragment->next  = block->next;
   12f1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12f1e:	8b 50 04             	mov    0x4(%eax),%edx
   12f21:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   12f24:	89 50 04             	mov    %edx,0x4(%eax)

		// replace this chunk with the fragment
		*pointer = fragment;
   12f27:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12f2a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   12f2d:	89 10                	mov    %edx,(%eax)

		// return this chunk
		block = chunk;
   12f2f:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12f32:	89 45 f4             	mov    %eax,-0xc(%ebp)
	}

	// fix the count of available pages
	n_pages -= count;;
   12f35:	a1 1c e1 01 00       	mov    0x1e11c,%eax
   12f3a:	2b 45 08             	sub    0x8(%ebp),%eax
   12f3d:	a3 1c e1 01 00       	mov    %eax,0x1e11c

	return( block );
   12f42:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   12f45:	c9                   	leave  
   12f46:	c3                   	ret    

00012f47 <km_page_free>:
** CRITICAL NOTE:  multi-page blocks must be freed one page
** at a time OR freed using km_page_free_multi()!
**
** @param block   Pointer to the page to be returned to the free list
*/
void km_page_free( void *block ) {
   12f47:	55                   	push   %ebp
   12f48:	89 e5                	mov    %esp,%ebp
   12f4a:	83 ec 08             	sub    $0x8,%esp

	/*
	** Don't do anything if the address is NULL.
	*/
	if( block == NULL ){
   12f4d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12f51:	74 12                	je     12f65 <km_page_free+0x1e>
		return;
	}

	km_page_free_multi( block, 1 );
   12f53:	83 ec 08             	sub    $0x8,%esp
   12f56:	6a 01                	push   $0x1
   12f58:	ff 75 08             	pushl  0x8(%ebp)
   12f5b:	e8 08 00 00 00       	call   12f68 <km_page_free_multi>
   12f60:	83 c4 10             	add    $0x10,%esp
   12f63:	eb 01                	jmp    12f66 <km_page_free+0x1f>
		return;
   12f65:	90                   	nop
}
   12f66:	c9                   	leave  
   12f67:	c3                   	ret    

00012f68 <km_page_free_multi>:
** accepts a pointer to a multi-page block of memory.
**
** @param block   Pointer to the block to be returned to the free list
** @param count   Number of pages in the block
*/
void km_page_free_multi( void *block, uint32_t count ) {
   12f68:	55                   	push   %ebp
   12f69:	89 e5                	mov    %esp,%ebp
   12f6b:	83 ec 18             	sub    $0x18,%esp
	Blockinfo *used;
	Blockinfo *prev;
	Blockinfo *curr;

	assert( km_initialized );
   12f6e:	a1 24 e1 01 00       	mov    0x1e124,%eax
   12f73:	85 c0                	test   %eax,%eax
   12f75:	75 3b                	jne    12fb2 <km_page_free_multi+0x4a>
   12f77:	83 ec 04             	sub    $0x4,%esp
   12f7a:	68 6d af 01 00       	push   $0x1af6d
   12f7f:	6a 00                	push   $0x0
   12f81:	68 57 02 00 00       	push   $0x257
   12f86:	68 95 ae 01 00       	push   $0x1ae95
   12f8b:	68 a8 af 01 00       	push   $0x1afa8
   12f90:	68 9c ae 01 00       	push   $0x1ae9c
   12f95:	68 00 00 02 00       	push   $0x20000
   12f9a:	e8 58 f7 ff ff       	call   126f7 <sprint>
   12f9f:	83 c4 20             	add    $0x20,%esp
   12fa2:	83 ec 0c             	sub    $0xc,%esp
   12fa5:	68 00 00 02 00       	push   $0x20000
   12faa:	e8 c8 f4 ff ff       	call   12477 <kpanic>
   12faf:	83 c4 10             	add    $0x10,%esp

	/*
	** Don't do anything if the address is NULL.
	*/
	if( block == NULL ){
   12fb2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12fb6:	0f 84 e3 00 00 00    	je     1309f <km_page_free_multi+0x137>
		return;
	}

	used = (Blockinfo *) block;
   12fbc:	8b 45 08             	mov    0x8(%ebp),%eax
   12fbf:	89 45 f4             	mov    %eax,-0xc(%ebp)
	used->pages = count;
   12fc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12fc5:	8b 55 0c             	mov    0xc(%ebp),%edx
   12fc8:	89 10                	mov    %edx,(%eax)

	/*
	** Advance through the list until current and previous
	** straddle the place where the new block should be inserted.
	*/
	prev = NULL;
   12fca:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	curr = free_pages;
   12fd1:	a1 14 e1 01 00       	mov    0x1e114,%eax
   12fd6:	89 45 ec             	mov    %eax,-0x14(%ebp)

	while( curr != NULL && curr < used ){
   12fd9:	eb 0f                	jmp    12fea <km_page_free_multi+0x82>
		prev = curr;
   12fdb:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12fde:	89 45 f0             	mov    %eax,-0x10(%ebp)
		curr = curr->next;
   12fe1:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12fe4:	8b 40 04             	mov    0x4(%eax),%eax
   12fe7:	89 45 ec             	mov    %eax,-0x14(%ebp)
	while( curr != NULL && curr < used ){
   12fea:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12fee:	74 08                	je     12ff8 <km_page_free_multi+0x90>
   12ff0:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12ff3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   12ff6:	72 e3                	jb     12fdb <km_page_free_multi+0x73>

	/*
	** If this is not the first block in the resulting list,
	** we may need to merge it with its predecessor.
	*/
	if( prev != NULL ){
   12ff8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12ffc:	74 44                	je     13042 <km_page_free_multi+0xda>

		// There is a predecessor.  Check to see if we need to merge.
		if( adjacent( prev, used ) ){
   12ffe:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13001:	8b 00                	mov    (%eax),%eax
   13003:	c1 e0 0c             	shl    $0xc,%eax
   13006:	89 c2                	mov    %eax,%edx
   13008:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1300b:	01 d0                	add    %edx,%eax
   1300d:	39 45 f4             	cmp    %eax,-0xc(%ebp)
   13010:	75 19                	jne    1302b <km_page_free_multi+0xc3>

			// yes - merge them
			prev->pages += used->pages;
   13012:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13015:	8b 10                	mov    (%eax),%edx
   13017:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1301a:	8b 00                	mov    (%eax),%eax
   1301c:	01 c2                	add    %eax,%edx
   1301e:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13021:	89 10                	mov    %edx,(%eax)

			// the predecessor becomes the "newly inserted" block,
			// because we still need to check to see if we should
			// merge with the successor
			used = prev;
   13023:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13026:	89 45 f4             	mov    %eax,-0xc(%ebp)
   13029:	eb 2b                	jmp    13056 <km_page_free_multi+0xee>

		} else {

			// Not adjacent - just insert the new block
			// between the predecessor and the successor.
			used->next = prev->next;
   1302b:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1302e:	8b 50 04             	mov    0x4(%eax),%edx
   13031:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13034:	89 50 04             	mov    %edx,0x4(%eax)
			prev->next = used;
   13037:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1303a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1303d:	89 50 04             	mov    %edx,0x4(%eax)
   13040:	eb 14                	jmp    13056 <km_page_free_multi+0xee>
		}

	} else {

		// Yes, it is first.  Update the list pointer to insert it.
		used->next = free_pages;
   13042:	8b 15 14 e1 01 00    	mov    0x1e114,%edx
   13048:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1304b:	89 50 04             	mov    %edx,0x4(%eax)
		free_pages = used;
   1304e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13051:	a3 14 e1 01 00       	mov    %eax,0x1e114

	/*
	** If this is not the last block in the resulting list,
	** we may (also) need to merge it with its successor.
	*/
	if( curr != NULL ){
   13056:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   1305a:	74 31                	je     1308d <km_page_free_multi+0x125>

		// No.  Check to see if it should be merged with the successor.
		if( adjacent( used, curr ) ){
   1305c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1305f:	8b 00                	mov    (%eax),%eax
   13061:	c1 e0 0c             	shl    $0xc,%eax
   13064:	89 c2                	mov    %eax,%edx
   13066:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13069:	01 d0                	add    %edx,%eax
   1306b:	39 45 ec             	cmp    %eax,-0x14(%ebp)
   1306e:	75 1d                	jne    1308d <km_page_free_multi+0x125>

			// Yes, combine them.
			used->next = curr->next;
   13070:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13073:	8b 50 04             	mov    0x4(%eax),%edx
   13076:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13079:	89 50 04             	mov    %edx,0x4(%eax)
			used->pages += curr->pages;
   1307c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1307f:	8b 10                	mov    (%eax),%edx
   13081:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13084:	8b 00                	mov    (%eax),%eax
   13086:	01 c2                	add    %eax,%edx
   13088:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1308b:	89 10                	mov    %edx,(%eax)

		}
	}

	// more in the pool
	n_pages += count;
   1308d:	8b 15 1c e1 01 00    	mov    0x1e11c,%edx
   13093:	8b 45 0c             	mov    0xc(%ebp),%eax
   13096:	01 d0                	add    %edx,%eax
   13098:	a3 1c e1 01 00       	mov    %eax,0x1e11c
   1309d:	eb 01                	jmp    130a0 <km_page_free_multi+0x138>
		return;
   1309f:	90                   	nop
}
   130a0:	c9                   	leave  
   130a1:	c3                   	ret    

000130a2 <carve_slices>:
** Name:        carve_slices
**
** Allocate a page and split it into four slices;  If no
**              memory is available, we panic.
*/
static void carve_slices( void ) {
   130a2:	55                   	push   %ebp
   130a3:	89 e5                	mov    %esp,%ebp
   130a5:	83 ec 18             	sub    $0x18,%esp
	void *page;

	// get a page
	page = km_page_alloc( 1 );
   130a8:	83 ec 0c             	sub    $0xc,%esp
   130ab:	6a 01                	push   $0x1
   130ad:	e8 90 fd ff ff       	call   12e42 <km_page_alloc>
   130b2:	83 c4 10             	add    $0x10,%esp
   130b5:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// allocation failure is a show-stopping problem
	assert( page );
   130b8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   130bc:	75 3b                	jne    130f9 <carve_slices+0x57>
   130be:	83 ec 04             	sub    $0x4,%esp
   130c1:	68 7c af 01 00       	push   $0x1af7c
   130c6:	6a 00                	push   $0x0
   130c8:	68 c8 02 00 00       	push   $0x2c8
   130cd:	68 95 ae 01 00       	push   $0x1ae95
   130d2:	68 bc af 01 00       	push   $0x1afbc
   130d7:	68 9c ae 01 00       	push   $0x1ae9c
   130dc:	68 00 00 02 00       	push   $0x20000
   130e1:	e8 11 f6 ff ff       	call   126f7 <sprint>
   130e6:	83 c4 20             	add    $0x20,%esp
   130e9:	83 ec 0c             	sub    $0xc,%esp
   130ec:	68 00 00 02 00       	push   $0x20000
   130f1:	e8 81 f3 ff ff       	call   12477 <kpanic>
   130f6:	83 c4 10             	add    $0x10,%esp

	// we have the page; create the four slices from it
	uint8_t *ptr = (uint8_t *) page;
   130f9:	8b 45 ec             	mov    -0x14(%ebp),%eax
   130fc:	89 45 f4             	mov    %eax,-0xc(%ebp)
	for( int i = 0; i < 4; ++i ) {
   130ff:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   13106:	eb 26                	jmp    1312e <carve_slices+0x8c>
		km_slice_free( (void *) ptr );
   13108:	83 ec 0c             	sub    $0xc,%esp
   1310b:	ff 75 f4             	pushl  -0xc(%ebp)
   1310e:	e8 f5 00 00 00       	call   13208 <km_slice_free>
   13113:	83 c4 10             	add    $0x10,%esp
		ptr += SZ_SLICE;
   13116:	81 45 f4 00 04 00 00 	addl   $0x400,-0xc(%ebp)
		++n_slices;
   1311d:	a1 20 e1 01 00       	mov    0x1e120,%eax
   13122:	83 c0 01             	add    $0x1,%eax
   13125:	a3 20 e1 01 00       	mov    %eax,0x1e120
	for( int i = 0; i < 4; ++i ) {
   1312a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   1312e:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
   13132:	7e d4                	jle    13108 <carve_slices+0x66>
	}
}
   13134:	90                   	nop
   13135:	c9                   	leave  
   13136:	c3                   	ret    

00013137 <km_slice_alloc>:
** Dynamically allocates a slice (1/4 of a page).  If no
** memory is available, we panic.
**
** @return a pointer to the allocated slice
*/
void *km_slice_alloc( void ) {
   13137:	55                   	push   %ebp
   13138:	89 e5                	mov    %esp,%ebp
   1313a:	83 ec 18             	sub    $0x18,%esp
	Blockinfo *slice;

	assert( km_initialized );
   1313d:	a1 24 e1 01 00       	mov    0x1e124,%eax
   13142:	85 c0                	test   %eax,%eax
   13144:	75 3b                	jne    13181 <km_slice_alloc+0x4a>
   13146:	83 ec 04             	sub    $0x4,%esp
   13149:	68 6d af 01 00       	push   $0x1af6d
   1314e:	6a 00                	push   $0x0
   13150:	68 de 02 00 00       	push   $0x2de
   13155:	68 95 ae 01 00       	push   $0x1ae95
   1315a:	68 cc af 01 00       	push   $0x1afcc
   1315f:	68 9c ae 01 00       	push   $0x1ae9c
   13164:	68 00 00 02 00       	push   $0x20000
   13169:	e8 89 f5 ff ff       	call   126f7 <sprint>
   1316e:	83 c4 20             	add    $0x20,%esp
   13171:	83 ec 0c             	sub    $0xc,%esp
   13174:	68 00 00 02 00       	push   $0x20000
   13179:	e8 f9 f2 ff ff       	call   12477 <kpanic>
   1317e:	83 c4 10             	add    $0x10,%esp

	// if we are out of slices, create a few more
	if( free_slices == NULL ) {
   13181:	a1 18 e1 01 00       	mov    0x1e118,%eax
   13186:	85 c0                	test   %eax,%eax
   13188:	75 05                	jne    1318f <km_slice_alloc+0x58>
		carve_slices();
   1318a:	e8 13 ff ff ff       	call   130a2 <carve_slices>
	}

	// take the first one from the free list
	slice = free_slices;
   1318f:	a1 18 e1 01 00       	mov    0x1e118,%eax
   13194:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert( slice != NULL );
   13197:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1319b:	75 3b                	jne    131d8 <km_slice_alloc+0xa1>
   1319d:	83 ec 04             	sub    $0x4,%esp
   131a0:	68 81 af 01 00       	push   $0x1af81
   131a5:	6a 00                	push   $0x0
   131a7:	68 e7 02 00 00       	push   $0x2e7
   131ac:	68 95 ae 01 00       	push   $0x1ae95
   131b1:	68 cc af 01 00       	push   $0x1afcc
   131b6:	68 9c ae 01 00       	push   $0x1ae9c
   131bb:	68 00 00 02 00       	push   $0x20000
   131c0:	e8 32 f5 ff ff       	call   126f7 <sprint>
   131c5:	83 c4 20             	add    $0x20,%esp
   131c8:	83 ec 0c             	sub    $0xc,%esp
   131cb:	68 00 00 02 00       	push   $0x20000
   131d0:	e8 a2 f2 ff ff       	call   12477 <kpanic>
   131d5:	83 c4 10             	add    $0x10,%esp
	--n_slices;
   131d8:	a1 20 e1 01 00       	mov    0x1e120,%eax
   131dd:	83 e8 01             	sub    $0x1,%eax
   131e0:	a3 20 e1 01 00       	mov    %eax,0x1e120

	// unlink it
	free_slices = slice->next;
   131e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
   131e8:	8b 40 04             	mov    0x4(%eax),%eax
   131eb:	a3 18 e1 01 00       	mov    %eax,0x1e118

	// make it nice and shiny for the caller
	memclr( (void *) slice, SZ_SLICE );
   131f0:	83 ec 08             	sub    $0x8,%esp
   131f3:	68 00 04 00 00       	push   $0x400
   131f8:	ff 75 f4             	pushl  -0xc(%ebp)
   131fb:	e8 74 f3 ff ff       	call   12574 <memclr>
   13200:	83 c4 10             	add    $0x10,%esp

	return( slice );
   13203:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   13206:	c9                   	leave  
   13207:	c3                   	ret    

00013208 <km_slice_free>:
** We make no attempt to merge slices, as they are independent
** blocks of memory (unlike pages).
**
** @param block  Pointer to the slice (1/4 page) to be freed
*/
void km_slice_free( void *block ) {
   13208:	55                   	push   %ebp
   13209:	89 e5                	mov    %esp,%ebp
   1320b:	83 ec 18             	sub    $0x18,%esp
	Blockinfo *slice = (Blockinfo *) block;
   1320e:	8b 45 08             	mov    0x8(%ebp),%eax
   13211:	89 45 f4             	mov    %eax,-0xc(%ebp)

	assert( km_initialized );
   13214:	a1 24 e1 01 00       	mov    0x1e124,%eax
   13219:	85 c0                	test   %eax,%eax
   1321b:	75 3b                	jne    13258 <km_slice_free+0x50>
   1321d:	83 ec 04             	sub    $0x4,%esp
   13220:	68 6d af 01 00       	push   $0x1af6d
   13225:	6a 00                	push   $0x0
   13227:	68 00 03 00 00       	push   $0x300
   1322c:	68 95 ae 01 00       	push   $0x1ae95
   13231:	68 dc af 01 00       	push   $0x1afdc
   13236:	68 9c ae 01 00       	push   $0x1ae9c
   1323b:	68 00 00 02 00       	push   $0x20000
   13240:	e8 b2 f4 ff ff       	call   126f7 <sprint>
   13245:	83 c4 20             	add    $0x20,%esp
   13248:	83 ec 0c             	sub    $0xc,%esp
   1324b:	68 00 00 02 00       	push   $0x20000
   13250:	e8 22 f2 ff ff       	call   12477 <kpanic>
   13255:	83 c4 10             	add    $0x10,%esp

	// just add it to the front of the free list
	slice->pages = SZ_SLICE;
   13258:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1325b:	c7 00 00 04 00 00    	movl   $0x400,(%eax)
	slice->next = free_slices;
   13261:	8b 15 18 e1 01 00    	mov    0x1e118,%edx
   13267:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1326a:	89 50 04             	mov    %edx,0x4(%eax)
	free_slices = slice;
   1326d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13270:	a3 18 e1 01 00       	mov    %eax,0x1e118
	++n_slices;
   13275:	a1 20 e1 01 00       	mov    0x1e120,%eax
   1327a:	83 c0 01             	add    $0x1,%eax
   1327d:	a3 20 e1 01 00       	mov    %eax,0x1e120
}
   13282:	90                   	nop
   13283:	c9                   	leave  
   13284:	c3                   	ret    

00013285 <list_add>:
** Add the supplied data to the beginning of the specified list.
**
** @param[in,out] list  The address of a list_t variable
** @param[in] data      The data to prepend to the list
*/
void list_add( list_t *list, void *data ) {
   13285:	55                   	push   %ebp
   13286:	89 e5                	mov    %esp,%ebp
   13288:	83 ec 18             	sub    $0x18,%esp

	// sanity checks
	assert1( list != NULL );
   1328b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1328f:	75 38                	jne    132c9 <list_add+0x44>
   13291:	83 ec 04             	sub    $0x4,%esp
   13294:	68 ec af 01 00       	push   $0x1afec
   13299:	6a 01                	push   $0x1
   1329b:	6a 23                	push   $0x23
   1329d:	68 f6 af 01 00       	push   $0x1aff6
   132a2:	68 20 b0 01 00       	push   $0x1b020
   132a7:	68 fd af 01 00       	push   $0x1affd
   132ac:	68 00 00 02 00       	push   $0x20000
   132b1:	e8 41 f4 ff ff       	call   126f7 <sprint>
   132b6:	83 c4 20             	add    $0x20,%esp
   132b9:	83 ec 0c             	sub    $0xc,%esp
   132bc:	68 00 00 02 00       	push   $0x20000
   132c1:	e8 b1 f1 ff ff       	call   12477 <kpanic>
   132c6:	83 c4 10             	add    $0x10,%esp
	assert1( data != NULL );
   132c9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   132cd:	75 38                	jne    13307 <list_add+0x82>
   132cf:	83 ec 04             	sub    $0x4,%esp
   132d2:	68 13 b0 01 00       	push   $0x1b013
   132d7:	6a 01                	push   $0x1
   132d9:	6a 24                	push   $0x24
   132db:	68 f6 af 01 00       	push   $0x1aff6
   132e0:	68 20 b0 01 00       	push   $0x1b020
   132e5:	68 fd af 01 00       	push   $0x1affd
   132ea:	68 00 00 02 00       	push   $0x20000
   132ef:	e8 03 f4 ff ff       	call   126f7 <sprint>
   132f4:	83 c4 20             	add    $0x20,%esp
   132f7:	83 ec 0c             	sub    $0xc,%esp
   132fa:	68 00 00 02 00       	push   $0x20000
   132ff:	e8 73 f1 ff ff       	call   12477 <kpanic>
   13304:	83 c4 10             	add    $0x10,%esp

	list_t *tmp = (list_t *)data;
   13307:	8b 45 0c             	mov    0xc(%ebp),%eax
   1330a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tmp->next = list->next;
   1330d:	8b 45 08             	mov    0x8(%ebp),%eax
   13310:	8b 10                	mov    (%eax),%edx
   13312:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13315:	89 10                	mov    %edx,(%eax)
	list->next = tmp;
   13317:	8b 45 08             	mov    0x8(%ebp),%eax
   1331a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1331d:	89 10                	mov    %edx,(%eax)
}
   1331f:	90                   	nop
   13320:	c9                   	leave  
   13321:	c3                   	ret    

00013322 <list_remove>:
**
** @param[in,out] list  The address of a list_t variable
**
** @return a pointer to the removed data, or NULL if the list was empty
*/
void *list_remove( list_t *list ) {
   13322:	55                   	push   %ebp
   13323:	89 e5                	mov    %esp,%ebp
   13325:	83 ec 18             	sub    $0x18,%esp

	assert1( list != NULL );
   13328:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1332c:	75 38                	jne    13366 <list_remove+0x44>
   1332e:	83 ec 04             	sub    $0x4,%esp
   13331:	68 ec af 01 00       	push   $0x1afec
   13336:	6a 01                	push   $0x1
   13338:	6a 36                	push   $0x36
   1333a:	68 f6 af 01 00       	push   $0x1aff6
   1333f:	68 2c b0 01 00       	push   $0x1b02c
   13344:	68 fd af 01 00       	push   $0x1affd
   13349:	68 00 00 02 00       	push   $0x20000
   1334e:	e8 a4 f3 ff ff       	call   126f7 <sprint>
   13353:	83 c4 20             	add    $0x20,%esp
   13356:	83 ec 0c             	sub    $0xc,%esp
   13359:	68 00 00 02 00       	push   $0x20000
   1335e:	e8 14 f1 ff ff       	call   12477 <kpanic>
   13363:	83 c4 10             	add    $0x10,%esp

	list_t *data = list->next;
   13366:	8b 45 08             	mov    0x8(%ebp),%eax
   13369:	8b 00                	mov    (%eax),%eax
   1336b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( data != NULL ) {
   1336e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   13372:	74 13                	je     13387 <list_remove+0x65>
		list->next = data->next;
   13374:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13377:	8b 10                	mov    (%eax),%edx
   13379:	8b 45 08             	mov    0x8(%ebp),%eax
   1337c:	89 10                	mov    %edx,(%eax)
		data->next = NULL;
   1337e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13381:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}

	return (void *)data;
   13387:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   1338a:	c9                   	leave  
   1338b:	c3                   	ret    

0001338c <find_prev_wakeup>:
** @param[in] pcb    The PCB to look for
**
** @return a pointer to the predecessor in the queue, or NULL if
** this PCB would be at the beginning of the queue.
*/
static pcb_t *find_prev_wakeup( pcb_queue_t queue, pcb_t *pcb ) {
   1338c:	55                   	push   %ebp
   1338d:	89 e5                	mov    %esp,%ebp
   1338f:	83 ec 18             	sub    $0x18,%esp

	// sanity checks!
	assert1( queue != NULL );
   13392:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13396:	75 3b                	jne    133d3 <find_prev_wakeup+0x47>
   13398:	83 ec 04             	sub    $0x4,%esp
   1339b:	68 8c b0 01 00       	push   $0x1b08c
   133a0:	6a 01                	push   $0x1
   133a2:	68 84 00 00 00       	push   $0x84
   133a7:	68 97 b0 01 00       	push   $0x1b097
   133ac:	68 f4 b4 01 00       	push   $0x1b4f4
   133b1:	68 9f b0 01 00       	push   $0x1b09f
   133b6:	68 00 00 02 00       	push   $0x20000
   133bb:	e8 37 f3 ff ff       	call   126f7 <sprint>
   133c0:	83 c4 20             	add    $0x20,%esp
   133c3:	83 ec 0c             	sub    $0xc,%esp
   133c6:	68 00 00 02 00       	push   $0x20000
   133cb:	e8 a7 f0 ff ff       	call   12477 <kpanic>
   133d0:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   133d3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   133d7:	75 3b                	jne    13414 <find_prev_wakeup+0x88>
   133d9:	83 ec 04             	sub    $0x4,%esp
   133dc:	68 b5 b0 01 00       	push   $0x1b0b5
   133e1:	6a 01                	push   $0x1
   133e3:	68 85 00 00 00       	push   $0x85
   133e8:	68 97 b0 01 00       	push   $0x1b097
   133ed:	68 f4 b4 01 00       	push   $0x1b4f4
   133f2:	68 9f b0 01 00       	push   $0x1b09f
   133f7:	68 00 00 02 00       	push   $0x20000
   133fc:	e8 f6 f2 ff ff       	call   126f7 <sprint>
   13401:	83 c4 20             	add    $0x20,%esp
   13404:	83 ec 0c             	sub    $0xc,%esp
   13407:	68 00 00 02 00       	push   $0x20000
   1340c:	e8 66 f0 ff ff       	call   12477 <kpanic>
   13411:	83 c4 10             	add    $0x10,%esp

	pcb_t *prev = NULL;
   13414:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *curr = queue->head;
   1341b:	8b 45 08             	mov    0x8(%ebp),%eax
   1341e:	8b 00                	mov    (%eax),%eax
   13420:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr != NULL && curr->wakeup <= pcb->wakeup ) {
   13423:	eb 0f                	jmp    13434 <find_prev_wakeup+0xa8>
		prev = curr;
   13425:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13428:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   1342b:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1342e:	8b 40 08             	mov    0x8(%eax),%eax
   13431:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr != NULL && curr->wakeup <= pcb->wakeup ) {
   13434:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   13438:	74 10                	je     1344a <find_prev_wakeup+0xbe>
   1343a:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1343d:	8b 50 10             	mov    0x10(%eax),%edx
   13440:	8b 45 0c             	mov    0xc(%ebp),%eax
   13443:	8b 40 10             	mov    0x10(%eax),%eax
   13446:	39 c2                	cmp    %eax,%edx
   13448:	76 db                	jbe    13425 <find_prev_wakeup+0x99>
	}

	return prev;
   1344a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   1344d:	c9                   	leave  
   1344e:	c3                   	ret    

0001344f <find_prev_priority>:

static pcb_t *find_prev_priority( pcb_queue_t queue, pcb_t *pcb ) {
   1344f:	55                   	push   %ebp
   13450:	89 e5                	mov    %esp,%ebp
   13452:	83 ec 18             	sub    $0x18,%esp

	// sanity checks!
	assert1( queue != NULL );
   13455:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13459:	75 3b                	jne    13496 <find_prev_priority+0x47>
   1345b:	83 ec 04             	sub    $0x4,%esp
   1345e:	68 8c b0 01 00       	push   $0x1b08c
   13463:	6a 01                	push   $0x1
   13465:	68 95 00 00 00       	push   $0x95
   1346a:	68 97 b0 01 00       	push   $0x1b097
   1346f:	68 08 b5 01 00       	push   $0x1b508
   13474:	68 9f b0 01 00       	push   $0x1b09f
   13479:	68 00 00 02 00       	push   $0x20000
   1347e:	e8 74 f2 ff ff       	call   126f7 <sprint>
   13483:	83 c4 20             	add    $0x20,%esp
   13486:	83 ec 0c             	sub    $0xc,%esp
   13489:	68 00 00 02 00       	push   $0x20000
   1348e:	e8 e4 ef ff ff       	call   12477 <kpanic>
   13493:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   13496:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   1349a:	75 3b                	jne    134d7 <find_prev_priority+0x88>
   1349c:	83 ec 04             	sub    $0x4,%esp
   1349f:	68 b5 b0 01 00       	push   $0x1b0b5
   134a4:	6a 01                	push   $0x1
   134a6:	68 96 00 00 00       	push   $0x96
   134ab:	68 97 b0 01 00       	push   $0x1b097
   134b0:	68 08 b5 01 00       	push   $0x1b508
   134b5:	68 9f b0 01 00       	push   $0x1b09f
   134ba:	68 00 00 02 00       	push   $0x20000
   134bf:	e8 33 f2 ff ff       	call   126f7 <sprint>
   134c4:	83 c4 20             	add    $0x20,%esp
   134c7:	83 ec 0c             	sub    $0xc,%esp
   134ca:	68 00 00 02 00       	push   $0x20000
   134cf:	e8 a3 ef ff ff       	call   12477 <kpanic>
   134d4:	83 c4 10             	add    $0x10,%esp

	pcb_t *prev = NULL;
   134d7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *curr = queue->head;
   134de:	8b 45 08             	mov    0x8(%ebp),%eax
   134e1:	8b 00                	mov    (%eax),%eax
   134e3:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr != NULL && curr->priority <= pcb->priority ) {
   134e6:	eb 0f                	jmp    134f7 <find_prev_priority+0xa8>
		prev = curr;
   134e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
   134eb:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   134ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
   134f1:	8b 40 08             	mov    0x8(%eax),%eax
   134f4:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr != NULL && curr->priority <= pcb->priority ) {
   134f7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   134fb:	74 10                	je     1350d <find_prev_priority+0xbe>
   134fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13500:	8b 50 20             	mov    0x20(%eax),%edx
   13503:	8b 45 0c             	mov    0xc(%ebp),%eax
   13506:	8b 40 20             	mov    0x20(%eax),%eax
   13509:	39 c2                	cmp    %eax,%edx
   1350b:	76 db                	jbe    134e8 <find_prev_priority+0x99>
	}

	return prev;
   1350d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   13510:	c9                   	leave  
   13511:	c3                   	ret    

00013512 <find_prev_pid>:

static pcb_t *find_prev_pid( pcb_queue_t queue, pcb_t *pcb ) {
   13512:	55                   	push   %ebp
   13513:	89 e5                	mov    %esp,%ebp
   13515:	83 ec 18             	sub    $0x18,%esp

	// sanity checks!
	assert1( queue != NULL );
   13518:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1351c:	75 3b                	jne    13559 <find_prev_pid+0x47>
   1351e:	83 ec 04             	sub    $0x4,%esp
   13521:	68 8c b0 01 00       	push   $0x1b08c
   13526:	6a 01                	push   $0x1
   13528:	68 a6 00 00 00       	push   $0xa6
   1352d:	68 97 b0 01 00       	push   $0x1b097
   13532:	68 1c b5 01 00       	push   $0x1b51c
   13537:	68 9f b0 01 00       	push   $0x1b09f
   1353c:	68 00 00 02 00       	push   $0x20000
   13541:	e8 b1 f1 ff ff       	call   126f7 <sprint>
   13546:	83 c4 20             	add    $0x20,%esp
   13549:	83 ec 0c             	sub    $0xc,%esp
   1354c:	68 00 00 02 00       	push   $0x20000
   13551:	e8 21 ef ff ff       	call   12477 <kpanic>
   13556:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   13559:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   1355d:	75 3b                	jne    1359a <find_prev_pid+0x88>
   1355f:	83 ec 04             	sub    $0x4,%esp
   13562:	68 b5 b0 01 00       	push   $0x1b0b5
   13567:	6a 01                	push   $0x1
   13569:	68 a7 00 00 00       	push   $0xa7
   1356e:	68 97 b0 01 00       	push   $0x1b097
   13573:	68 1c b5 01 00       	push   $0x1b51c
   13578:	68 9f b0 01 00       	push   $0x1b09f
   1357d:	68 00 00 02 00       	push   $0x20000
   13582:	e8 70 f1 ff ff       	call   126f7 <sprint>
   13587:	83 c4 20             	add    $0x20,%esp
   1358a:	83 ec 0c             	sub    $0xc,%esp
   1358d:	68 00 00 02 00       	push   $0x20000
   13592:	e8 e0 ee ff ff       	call   12477 <kpanic>
   13597:	83 c4 10             	add    $0x10,%esp

	pcb_t *prev = NULL;
   1359a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *curr = queue->head;
   135a1:	8b 45 08             	mov    0x8(%ebp),%eax
   135a4:	8b 00                	mov    (%eax),%eax
   135a6:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr != NULL && curr->pid <= pcb->pid ) {
   135a9:	eb 0f                	jmp    135ba <find_prev_pid+0xa8>
		prev = curr;
   135ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
   135ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   135b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
   135b4:	8b 40 08             	mov    0x8(%eax),%eax
   135b7:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr != NULL && curr->pid <= pcb->pid ) {
   135ba:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   135be:	74 10                	je     135d0 <find_prev_pid+0xbe>
   135c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
   135c3:	8b 50 18             	mov    0x18(%eax),%edx
   135c6:	8b 45 0c             	mov    0xc(%ebp),%eax
   135c9:	8b 40 18             	mov    0x18(%eax),%eax
   135cc:	39 c2                	cmp    %eax,%edx
   135ce:	76 db                	jbe    135ab <find_prev_pid+0x99>
	}

	return prev;
   135d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   135d3:	c9                   	leave  
   135d4:	c3                   	ret    

000135d5 <pcb_init>:
/**
** Name:	pcb_init
**
** Initialization for the Process module.
*/
void pcb_init( void ) {
   135d5:	55                   	push   %ebp
   135d6:	89 e5                	mov    %esp,%ebp
   135d8:	83 ec 18             	sub    $0x18,%esp

#if TRACING_INIT
	cio_puts( " Procs" );
   135db:	83 ec 0c             	sub    $0xc,%esp
   135de:	68 be b0 01 00       	push   $0x1b0be
   135e3:	e8 c5 d8 ff ff       	call   10ead <cio_puts>
   135e8:	83 c4 10             	add    $0x10,%esp
#endif

	// there is no current process
	current = NULL;
   135eb:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   135f2:	00 00 00 

	// first user PID
	next_pid = FIRST_USER_PID;
   135f5:	c7 05 1c 20 02 00 02 	movl   $0x2,0x2201c
   135fc:	00 00 00 

	// set up the external links to the queues
	QINIT( pcb_freelist, O_FIFO );
   135ff:	c7 05 00 20 02 00 28 	movl   $0x1e128,0x22000
   13606:	e1 01 00 
   13609:	a1 00 20 02 00       	mov    0x22000,%eax
   1360e:	83 ec 08             	sub    $0x8,%esp
   13611:	6a 00                	push   $0x0
   13613:	50                   	push   %eax
   13614:	e8 9c 07 00 00       	call   13db5 <pcb_queue_reset>
   13619:	83 c4 10             	add    $0x10,%esp
   1361c:	85 c0                	test   %eax,%eax
   1361e:	74 3b                	je     1365b <pcb_init+0x86>
   13620:	83 ec 04             	sub    $0x4,%esp
   13623:	68 c8 b0 01 00       	push   $0x1b0c8
   13628:	6a 00                	push   $0x0
   1362a:	68 d1 00 00 00       	push   $0xd1
   1362f:	68 97 b0 01 00       	push   $0x1b097
   13634:	68 2c b5 01 00       	push   $0x1b52c
   13639:	68 9f b0 01 00       	push   $0x1b09f
   1363e:	68 00 00 02 00       	push   $0x20000
   13643:	e8 af f0 ff ff       	call   126f7 <sprint>
   13648:	83 c4 20             	add    $0x20,%esp
   1364b:	83 ec 0c             	sub    $0xc,%esp
   1364e:	68 00 00 02 00       	push   $0x20000
   13653:	e8 1f ee ff ff       	call   12477 <kpanic>
   13658:	83 c4 10             	add    $0x10,%esp
	QINIT( ready, O_PRIO );
   1365b:	c7 05 d0 24 02 00 34 	movl   $0x1e134,0x224d0
   13662:	e1 01 00 
   13665:	a1 d0 24 02 00       	mov    0x224d0,%eax
   1366a:	83 ec 08             	sub    $0x8,%esp
   1366d:	6a 01                	push   $0x1
   1366f:	50                   	push   %eax
   13670:	e8 40 07 00 00       	call   13db5 <pcb_queue_reset>
   13675:	83 c4 10             	add    $0x10,%esp
   13678:	85 c0                	test   %eax,%eax
   1367a:	74 3b                	je     136b7 <pcb_init+0xe2>
   1367c:	83 ec 04             	sub    $0x4,%esp
   1367f:	68 f0 b0 01 00       	push   $0x1b0f0
   13684:	6a 00                	push   $0x0
   13686:	68 d2 00 00 00       	push   $0xd2
   1368b:	68 97 b0 01 00       	push   $0x1b097
   13690:	68 2c b5 01 00       	push   $0x1b52c
   13695:	68 9f b0 01 00       	push   $0x1b09f
   1369a:	68 00 00 02 00       	push   $0x20000
   1369f:	e8 53 f0 ff ff       	call   126f7 <sprint>
   136a4:	83 c4 20             	add    $0x20,%esp
   136a7:	83 ec 0c             	sub    $0xc,%esp
   136aa:	68 00 00 02 00       	push   $0x20000
   136af:	e8 c3 ed ff ff       	call   12477 <kpanic>
   136b4:	83 c4 10             	add    $0x10,%esp
	QINIT( waiting, O_PID );
   136b7:	c7 05 10 20 02 00 40 	movl   $0x1e140,0x22010
   136be:	e1 01 00 
   136c1:	a1 10 20 02 00       	mov    0x22010,%eax
   136c6:	83 ec 08             	sub    $0x8,%esp
   136c9:	6a 02                	push   $0x2
   136cb:	50                   	push   %eax
   136cc:	e8 e4 06 00 00       	call   13db5 <pcb_queue_reset>
   136d1:	83 c4 10             	add    $0x10,%esp
   136d4:	85 c0                	test   %eax,%eax
   136d6:	74 3b                	je     13713 <pcb_init+0x13e>
   136d8:	83 ec 04             	sub    $0x4,%esp
   136db:	68 10 b1 01 00       	push   $0x1b110
   136e0:	6a 00                	push   $0x0
   136e2:	68 d3 00 00 00       	push   $0xd3
   136e7:	68 97 b0 01 00       	push   $0x1b097
   136ec:	68 2c b5 01 00       	push   $0x1b52c
   136f1:	68 9f b0 01 00       	push   $0x1b09f
   136f6:	68 00 00 02 00       	push   $0x20000
   136fb:	e8 f7 ef ff ff       	call   126f7 <sprint>
   13700:	83 c4 20             	add    $0x20,%esp
   13703:	83 ec 0c             	sub    $0xc,%esp
   13706:	68 00 00 02 00       	push   $0x20000
   1370b:	e8 67 ed ff ff       	call   12477 <kpanic>
   13710:	83 c4 10             	add    $0x10,%esp
	QINIT( sleeping, O_WAKEUP );
   13713:	c7 05 08 20 02 00 4c 	movl   $0x1e14c,0x22008
   1371a:	e1 01 00 
   1371d:	a1 08 20 02 00       	mov    0x22008,%eax
   13722:	83 ec 08             	sub    $0x8,%esp
   13725:	6a 03                	push   $0x3
   13727:	50                   	push   %eax
   13728:	e8 88 06 00 00       	call   13db5 <pcb_queue_reset>
   1372d:	83 c4 10             	add    $0x10,%esp
   13730:	85 c0                	test   %eax,%eax
   13732:	74 3b                	je     1376f <pcb_init+0x19a>
   13734:	83 ec 04             	sub    $0x4,%esp
   13737:	68 34 b1 01 00       	push   $0x1b134
   1373c:	6a 00                	push   $0x0
   1373e:	68 d4 00 00 00       	push   $0xd4
   13743:	68 97 b0 01 00       	push   $0x1b097
   13748:	68 2c b5 01 00       	push   $0x1b52c
   1374d:	68 9f b0 01 00       	push   $0x1b09f
   13752:	68 00 00 02 00       	push   $0x20000
   13757:	e8 9b ef ff ff       	call   126f7 <sprint>
   1375c:	83 c4 20             	add    $0x20,%esp
   1375f:	83 ec 0c             	sub    $0xc,%esp
   13762:	68 00 00 02 00       	push   $0x20000
   13767:	e8 0b ed ff ff       	call   12477 <kpanic>
   1376c:	83 c4 10             	add    $0x10,%esp
	QINIT( zombie, O_PID );
   1376f:	c7 05 18 20 02 00 58 	movl   $0x1e158,0x22018
   13776:	e1 01 00 
   13779:	a1 18 20 02 00       	mov    0x22018,%eax
   1377e:	83 ec 08             	sub    $0x8,%esp
   13781:	6a 02                	push   $0x2
   13783:	50                   	push   %eax
   13784:	e8 2c 06 00 00       	call   13db5 <pcb_queue_reset>
   13789:	83 c4 10             	add    $0x10,%esp
   1378c:	85 c0                	test   %eax,%eax
   1378e:	74 3b                	je     137cb <pcb_init+0x1f6>
   13790:	83 ec 04             	sub    $0x4,%esp
   13793:	68 58 b1 01 00       	push   $0x1b158
   13798:	6a 00                	push   $0x0
   1379a:	68 d5 00 00 00       	push   $0xd5
   1379f:	68 97 b0 01 00       	push   $0x1b097
   137a4:	68 2c b5 01 00       	push   $0x1b52c
   137a9:	68 9f b0 01 00       	push   $0x1b09f
   137ae:	68 00 00 02 00       	push   $0x20000
   137b3:	e8 3f ef ff ff       	call   126f7 <sprint>
   137b8:	83 c4 20             	add    $0x20,%esp
   137bb:	83 ec 0c             	sub    $0xc,%esp
   137be:	68 00 00 02 00       	push   $0x20000
   137c3:	e8 af ec ff ff       	call   12477 <kpanic>
   137c8:	83 c4 10             	add    $0x10,%esp
	QINIT( sioread, O_FIFO );
   137cb:	c7 05 04 20 02 00 64 	movl   $0x1e164,0x22004
   137d2:	e1 01 00 
   137d5:	a1 04 20 02 00       	mov    0x22004,%eax
   137da:	83 ec 08             	sub    $0x8,%esp
   137dd:	6a 00                	push   $0x0
   137df:	50                   	push   %eax
   137e0:	e8 d0 05 00 00       	call   13db5 <pcb_queue_reset>
   137e5:	83 c4 10             	add    $0x10,%esp
   137e8:	85 c0                	test   %eax,%eax
   137ea:	74 3b                	je     13827 <pcb_init+0x252>
   137ec:	83 ec 04             	sub    $0x4,%esp
   137ef:	68 7c b1 01 00       	push   $0x1b17c
   137f4:	6a 00                	push   $0x0
   137f6:	68 d6 00 00 00       	push   $0xd6
   137fb:	68 97 b0 01 00       	push   $0x1b097
   13800:	68 2c b5 01 00       	push   $0x1b52c
   13805:	68 9f b0 01 00       	push   $0x1b09f
   1380a:	68 00 00 02 00       	push   $0x20000
   1380f:	e8 e3 ee ff ff       	call   126f7 <sprint>
   13814:	83 c4 20             	add    $0x20,%esp
   13817:	83 ec 0c             	sub    $0xc,%esp
   1381a:	68 00 00 02 00       	push   $0x20000
   1381f:	e8 53 ec ff ff       	call   12477 <kpanic>
   13824:	83 c4 10             	add    $0x10,%esp
	** so that we dynamically allocate PCBs, this step either
	** won't be required, or could be used to pre-allocate some
	** number of PCB structures for future use.
	*/

	pcb_t *ptr = ptable;
   13827:	c7 45 f4 20 20 02 00 	movl   $0x22020,-0xc(%ebp)
	for( int i = 0; i < N_PROCS; ++i ) {
   1382e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   13835:	eb 16                	jmp    1384d <pcb_init+0x278>
		pcb_free( ptr );
   13837:	83 ec 0c             	sub    $0xc,%esp
   1383a:	ff 75 f4             	pushl  -0xc(%ebp)
   1383d:	e8 8a 00 00 00       	call   138cc <pcb_free>
   13842:	83 c4 10             	add    $0x10,%esp
		++ptr;
   13845:	83 45 f4 30          	addl   $0x30,-0xc(%ebp)
	for( int i = 0; i < N_PROCS; ++i ) {
   13849:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   1384d:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   13851:	7e e4                	jle    13837 <pcb_init+0x262>
	}
}
   13853:	90                   	nop
   13854:	c9                   	leave  
   13855:	c3                   	ret    

00013856 <pcb_alloc>:
**
** @param pcb   Pointer to a pcb_t * where the PCB pointer will be returned.
**
** @return status of the allocation attempt
*/
int pcb_alloc( pcb_t **pcb ) {
   13856:	55                   	push   %ebp
   13857:	89 e5                	mov    %esp,%ebp
   13859:	83 ec 18             	sub    $0x18,%esp

	// sanity check!
	assert1( pcb != NULL );
   1385c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13860:	75 3b                	jne    1389d <pcb_alloc+0x47>
   13862:	83 ec 04             	sub    $0x4,%esp
   13865:	68 b5 b0 01 00       	push   $0x1b0b5
   1386a:	6a 01                	push   $0x1
   1386c:	68 f3 00 00 00       	push   $0xf3
   13871:	68 97 b0 01 00       	push   $0x1b097
   13876:	68 38 b5 01 00       	push   $0x1b538
   1387b:	68 9f b0 01 00       	push   $0x1b09f
   13880:	68 00 00 02 00       	push   $0x20000
   13885:	e8 6d ee ff ff       	call   126f7 <sprint>
   1388a:	83 c4 20             	add    $0x20,%esp
   1388d:	83 ec 0c             	sub    $0xc,%esp
   13890:	68 00 00 02 00       	push   $0x20000
   13895:	e8 dd eb ff ff       	call   12477 <kpanic>
   1389a:	83 c4 10             	add    $0x10,%esp

	// remove the first PCB from the free list
	pcb_t *tmp;
	if( pcb_queue_remove(pcb_freelist,&tmp) != SUCCESS ) {
   1389d:	a1 00 20 02 00       	mov    0x22000,%eax
   138a2:	83 ec 08             	sub    $0x8,%esp
   138a5:	8d 55 f4             	lea    -0xc(%ebp),%edx
   138a8:	52                   	push   %edx
   138a9:	50                   	push   %eax
   138aa:	e8 1d 08 00 00       	call   140cc <pcb_queue_remove>
   138af:	83 c4 10             	add    $0x10,%esp
   138b2:	85 c0                	test   %eax,%eax
   138b4:	74 07                	je     138bd <pcb_alloc+0x67>
		return E_NO_PCBS;
   138b6:	b8 9b ff ff ff       	mov    $0xffffff9b,%eax
   138bb:	eb 0d                	jmp    138ca <pcb_alloc+0x74>
	}

	*pcb = tmp;
   138bd:	8b 55 f4             	mov    -0xc(%ebp),%edx
   138c0:	8b 45 08             	mov    0x8(%ebp),%eax
   138c3:	89 10                	mov    %edx,(%eax)
	return SUCCESS;
   138c5:	b8 00 00 00 00       	mov    $0x0,%eax
}
   138ca:	c9                   	leave  
   138cb:	c3                   	ret    

000138cc <pcb_free>:
**
** Return a PCB to the list of free PCBs.
**
** @param pcb   Pointer to the PCB to be deallocated.
*/
void pcb_free( pcb_t *pcb ) {
   138cc:	55                   	push   %ebp
   138cd:	89 e5                	mov    %esp,%ebp
   138cf:	83 ec 18             	sub    $0x18,%esp

	if( pcb != NULL ) {
   138d2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   138d6:	74 7b                	je     13953 <pcb_free+0x87>
		// mark the PCB as available
		pcb->state = STATE_UNUSED;
   138d8:	8b 45 08             	mov    0x8(%ebp),%eax
   138db:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

		// add it to the free list
		int status = pcb_queue_insert( pcb_freelist, pcb );
   138e2:	a1 00 20 02 00       	mov    0x22000,%eax
   138e7:	83 ec 08             	sub    $0x8,%esp
   138ea:	ff 75 08             	pushl  0x8(%ebp)
   138ed:	50                   	push   %eax
   138ee:	e8 f3 05 00 00       	call   13ee6 <pcb_queue_insert>
   138f3:	83 c4 10             	add    $0x10,%esp
   138f6:	89 45 f4             	mov    %eax,-0xc(%ebp)

		// if that failed, we're in trouble
		if( status != SUCCESS ) {
   138f9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   138fd:	74 54                	je     13953 <pcb_free+0x87>
			sprint( b256, "pcb_free(0x%08x) status %d", (uint32_t) pcb,
   138ff:	8b 45 08             	mov    0x8(%ebp),%eax
   13902:	ff 75 f4             	pushl  -0xc(%ebp)
   13905:	50                   	push   %eax
   13906:	68 9e b1 01 00       	push   $0x1b19e
   1390b:	68 00 02 02 00       	push   $0x20200
   13910:	e8 e2 ed ff ff       	call   126f7 <sprint>
   13915:	83 c4 10             	add    $0x10,%esp
					status );
			PANIC( 0, b256 );
   13918:	83 ec 04             	sub    $0x4,%esp
   1391b:	68 b9 b1 01 00       	push   $0x1b1b9
   13920:	6a 00                	push   $0x0
   13922:	68 13 01 00 00       	push   $0x113
   13927:	68 97 b0 01 00       	push   $0x1b097
   1392c:	68 44 b5 01 00       	push   $0x1b544
   13931:	68 9f b0 01 00       	push   $0x1b09f
   13936:	68 00 00 02 00       	push   $0x20000
   1393b:	e8 b7 ed ff ff       	call   126f7 <sprint>
   13940:	83 c4 20             	add    $0x20,%esp
   13943:	83 ec 0c             	sub    $0xc,%esp
   13946:	68 00 00 02 00       	push   $0x20000
   1394b:	e8 27 eb ff ff       	call   12477 <kpanic>
   13950:	83 c4 10             	add    $0x10,%esp
		}
	}
}
   13953:	90                   	nop
   13954:	c9                   	leave  
   13955:	c3                   	ret    

00013956 <pcb_stack_alloc>:
**
** @param size   Desired size (in pages, or 0 to get the default size
**
** @return pointer to the allocated space, or NULL
*/
uint32_t *pcb_stack_alloc( uint32_t size ) {
   13956:	55                   	push   %ebp
   13957:	89 e5                	mov    %esp,%ebp
   13959:	83 ec 18             	sub    $0x18,%esp

#if TRACING_STACK
	cio_printf( "stack alloc, %u", size );
#endif
	// do we have a desired size?
	if( size == 0 ) {
   1395c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13960:	75 07                	jne    13969 <pcb_stack_alloc+0x13>
		// no, so use the default
		size = N_USTKPAGES;
   13962:	c7 45 08 02 00 00 00 	movl   $0x2,0x8(%ebp)
	}

	uint32_t *ptr = (uint32_t *) km_page_alloc( size );
   13969:	83 ec 0c             	sub    $0xc,%esp
   1396c:	ff 75 08             	pushl  0x8(%ebp)
   1396f:	e8 ce f4 ff ff       	call   12e42 <km_page_alloc>
   13974:	83 c4 10             	add    $0x10,%esp
   13977:	89 45 f4             	mov    %eax,-0xc(%ebp)
#if TRACING_STACK
	cio_printf( " --> %08x\n", (uint32_t) ptr );
#endif
	if( ptr ) {
   1397a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1397e:	74 15                	je     13995 <pcb_stack_alloc+0x3f>
		// clear out the allocated space
		memclr( ptr, size * SZ_PAGE );
   13980:	8b 45 08             	mov    0x8(%ebp),%eax
   13983:	c1 e0 0c             	shl    $0xc,%eax
   13986:	83 ec 08             	sub    $0x8,%esp
   13989:	50                   	push   %eax
   1398a:	ff 75 f4             	pushl  -0xc(%ebp)
   1398d:	e8 e2 eb ff ff       	call   12574 <memclr>
   13992:	83 c4 10             	add    $0x10,%esp
	}

	return ptr;
   13995:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   13998:	c9                   	leave  
   13999:	c3                   	ret    

0001399a <pcb_stack_free>:
** Dellocate space for a stack
**
** @param stk    Pointer to the stack
** @param size   Allocation size (in pages, or 0 for the default size
*/
void pcb_stack_free( uint32_t *stk, uint32_t size ) {
   1399a:	55                   	push   %ebp
   1399b:	89 e5                	mov    %esp,%ebp
   1399d:	83 ec 08             	sub    $0x8,%esp

#if TRACING_STACK
	cio_printf( "stack free, %08x %u\n", (uint32_t) stk, size );
#endif

	assert( stk != NULL );
   139a0:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   139a4:	75 3b                	jne    139e1 <pcb_stack_free+0x47>
   139a6:	83 ec 04             	sub    $0x4,%esp
   139a9:	68 be b1 01 00       	push   $0x1b1be
   139ae:	6a 00                	push   $0x0
   139b0:	68 46 01 00 00       	push   $0x146
   139b5:	68 97 b0 01 00       	push   $0x1b097
   139ba:	68 50 b5 01 00       	push   $0x1b550
   139bf:	68 9f b0 01 00       	push   $0x1b09f
   139c4:	68 00 00 02 00       	push   $0x20000
   139c9:	e8 29 ed ff ff       	call   126f7 <sprint>
   139ce:	83 c4 20             	add    $0x20,%esp
   139d1:	83 ec 0c             	sub    $0xc,%esp
   139d4:	68 00 00 02 00       	push   $0x20000
   139d9:	e8 99 ea ff ff       	call   12477 <kpanic>
   139de:	83 c4 10             	add    $0x10,%esp

	// do we have an alternate size?
	if( size == 0 ) {
   139e1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   139e5:	75 07                	jne    139ee <pcb_stack_free+0x54>
		// no, so use the default
		size = N_USTKPAGES;
   139e7:	c7 45 0c 02 00 00 00 	movl   $0x2,0xc(%ebp)
	}

	// send it back to the pool
	km_page_free_multi( (void *)stk, size );
   139ee:	83 ec 08             	sub    $0x8,%esp
   139f1:	ff 75 0c             	pushl  0xc(%ebp)
   139f4:	ff 75 08             	pushl  0x8(%ebp)
   139f7:	e8 6c f5 ff ff       	call   12f68 <km_page_free_multi>
   139fc:	83 c4 10             	add    $0x10,%esp
}
   139ff:	90                   	nop
   13a00:	c9                   	leave  
   13a01:	c3                   	ret    

00013a02 <pcb_zombify>:
** does most of the real work for exit() and kill() calls.
** Is also called from the scheduler and dispatcher.
**
** @param pcb   Pointer to the newly-undead PCB
*/
void pcb_zombify( register pcb_t *victim ) {
   13a02:	55                   	push   %ebp
   13a03:	89 e5                	mov    %esp,%ebp
   13a05:	56                   	push   %esi
   13a06:	53                   	push   %ebx
   13a07:	83 ec 20             	sub    $0x20,%esp
   13a0a:	8b 5d 08             	mov    0x8(%ebp),%ebx

	// should this be an error?
	if( victim == NULL ) {
   13a0d:	85 db                	test   %ebx,%ebx
   13a0f:	0f 84 79 02 00 00    	je     13c8e <pcb_zombify+0x28c>
		return;
	}

	// every process must have a parent, even if it's 'init'
	assert( victim->parent != NULL );
   13a15:	8b 43 0c             	mov    0xc(%ebx),%eax
   13a18:	85 c0                	test   %eax,%eax
   13a1a:	75 3b                	jne    13a57 <pcb_zombify+0x55>
   13a1c:	83 ec 04             	sub    $0x4,%esp
   13a1f:	68 c7 b1 01 00       	push   $0x1b1c7
   13a24:	6a 00                	push   $0x0
   13a26:	68 63 01 00 00       	push   $0x163
   13a2b:	68 97 b0 01 00       	push   $0x1b097
   13a30:	68 60 b5 01 00       	push   $0x1b560
   13a35:	68 9f b0 01 00       	push   $0x1b09f
   13a3a:	68 00 00 02 00       	push   $0x20000
   13a3f:	e8 b3 ec ff ff       	call   126f7 <sprint>
   13a44:	83 c4 20             	add    $0x20,%esp
   13a47:	83 ec 0c             	sub    $0xc,%esp
   13a4a:	68 00 00 02 00       	push   $0x20000
   13a4f:	e8 23 ea ff ff       	call   12477 <kpanic>
   13a54:	83 c4 10             	add    $0x10,%esp
	/*
	** We need to locate the parent of this process.  We also need
	** to reparent any children of this process.  We do these in
	** a single loop.
	*/
	pcb_t *parent = victim->parent;
   13a57:	8b 43 0c             	mov    0xc(%ebx),%eax
   13a5a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	pcb_t *zchild = NULL;
   13a5d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// two PIDs we will look for
	uint_t vicpid = victim->pid;
   13a64:	8b 43 18             	mov    0x18(%ebx),%eax
   13a67:	89 45 e8             	mov    %eax,-0x18(%ebp)

	// speed up access to the process table entries
	register pcb_t *curr = ptable;
   13a6a:	be 20 20 02 00       	mov    $0x22020,%esi

	for( int i = 0; i < N_PROCS; ++i, ++curr ) {
   13a6f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   13a76:	eb 33                	jmp    13aab <pcb_zombify+0xa9>

		// make sure this is a valid entry
		if( curr->state == STATE_UNUSED ) {
   13a78:	8b 46 1c             	mov    0x1c(%esi),%eax
   13a7b:	85 c0                	test   %eax,%eax
   13a7d:	74 21                	je     13aa0 <pcb_zombify+0x9e>
			continue;
		}

		// if this is our parent, just keep going - we continue
		// iterating to find all the children of this process.
		if( curr == parent ) {
   13a7f:	3b 75 ec             	cmp    -0x14(%ebp),%esi
   13a82:	74 1f                	je     13aa3 <pcb_zombify+0xa1>
			continue;
		}

		if( curr->parent == victim ) {
   13a84:	8b 46 0c             	mov    0xc(%esi),%eax
   13a87:	39 c3                	cmp    %eax,%ebx
   13a89:	75 19                	jne    13aa4 <pcb_zombify+0xa2>

			// found a child - reparent it
			curr->parent = init_pcb;
   13a8b:	a1 0c 20 02 00       	mov    0x2200c,%eax
   13a90:	89 46 0c             	mov    %eax,0xc(%esi)

			// see if this child is already undead
			if( curr->state == STATE_ZOMBIE ) {
   13a93:	8b 46 1c             	mov    0x1c(%esi),%eax
   13a96:	83 f8 08             	cmp    $0x8,%eax
   13a99:	75 09                	jne    13aa4 <pcb_zombify+0xa2>
				// if it's already a zombie, remember it, so we
				// can pass it on to 'init'; also, if there are
				// two or more zombie children, it doesn't matter
				// which one we pick here, as the others will be
				// collected when 'init' loops
				zchild = curr;
   13a9b:	89 75 f4             	mov    %esi,-0xc(%ebp)
   13a9e:	eb 04                	jmp    13aa4 <pcb_zombify+0xa2>
			continue;
   13aa0:	90                   	nop
   13aa1:	eb 01                	jmp    13aa4 <pcb_zombify+0xa2>
			continue;
   13aa3:	90                   	nop
	for( int i = 0; i < N_PROCS; ++i, ++curr ) {
   13aa4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   13aa8:	83 c6 30             	add    $0x30,%esi
   13aab:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   13aaf:	7e c7                	jle    13a78 <pcb_zombify+0x76>
	** existing process itself is cleaned up by init. This will work,
	** because after init cleans up the zombie, it will loop and
	** call waitpid() again, by which time this exiting process will
	** be marked as a zombie.
	*/
	if( zchild != NULL && init_pcb->state == STATE_WAITING ) {
   13ab1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   13ab5:	0f 84 0d 01 00 00    	je     13bc8 <pcb_zombify+0x1c6>
   13abb:	a1 0c 20 02 00       	mov    0x2200c,%eax
   13ac0:	8b 40 1c             	mov    0x1c(%eax),%eax
   13ac3:	83 f8 06             	cmp    $0x6,%eax
   13ac6:	0f 85 fc 00 00 00    	jne    13bc8 <pcb_zombify+0x1c6>

		// dequeue the zombie
		assert( pcb_queue_remove_this(zombie,zchild) == SUCCESS );
   13acc:	a1 18 20 02 00       	mov    0x22018,%eax
   13ad1:	83 ec 08             	sub    $0x8,%esp
   13ad4:	ff 75 f4             	pushl  -0xc(%ebp)
   13ad7:	50                   	push   %eax
   13ad8:	e8 c6 06 00 00       	call   141a3 <pcb_queue_remove_this>
   13add:	83 c4 10             	add    $0x10,%esp
   13ae0:	85 c0                	test   %eax,%eax
   13ae2:	74 3b                	je     13b1f <pcb_zombify+0x11d>
   13ae4:	83 ec 04             	sub    $0x4,%esp
   13ae7:	68 dc b1 01 00       	push   $0x1b1dc
   13aec:	6a 00                	push   $0x0
   13aee:	68 a5 01 00 00       	push   $0x1a5
   13af3:	68 97 b0 01 00       	push   $0x1b097
   13af8:	68 60 b5 01 00       	push   $0x1b560
   13afd:	68 9f b0 01 00       	push   $0x1b09f
   13b02:	68 00 00 02 00       	push   $0x20000
   13b07:	e8 eb eb ff ff       	call   126f7 <sprint>
   13b0c:	83 c4 20             	add    $0x20,%esp
   13b0f:	83 ec 0c             	sub    $0xc,%esp
   13b12:	68 00 00 02 00       	push   $0x20000
   13b17:	e8 5b e9 ff ff       	call   12477 <kpanic>
   13b1c:	83 c4 10             	add    $0x10,%esp

		assert( pcb_queue_remove_this(waiting,init_pcb) == SUCCESS );
   13b1f:	8b 15 0c 20 02 00    	mov    0x2200c,%edx
   13b25:	a1 10 20 02 00       	mov    0x22010,%eax
   13b2a:	83 ec 08             	sub    $0x8,%esp
   13b2d:	52                   	push   %edx
   13b2e:	50                   	push   %eax
   13b2f:	e8 6f 06 00 00       	call   141a3 <pcb_queue_remove_this>
   13b34:	83 c4 10             	add    $0x10,%esp
   13b37:	85 c0                	test   %eax,%eax
   13b39:	74 3b                	je     13b76 <pcb_zombify+0x174>
   13b3b:	83 ec 04             	sub    $0x4,%esp
   13b3e:	68 08 b2 01 00       	push   $0x1b208
   13b43:	6a 00                	push   $0x0
   13b45:	68 a7 01 00 00       	push   $0x1a7
   13b4a:	68 97 b0 01 00       	push   $0x1b097
   13b4f:	68 60 b5 01 00       	push   $0x1b560
   13b54:	68 9f b0 01 00       	push   $0x1b09f
   13b59:	68 00 00 02 00       	push   $0x20000
   13b5e:	e8 94 eb ff ff       	call   126f7 <sprint>
   13b63:	83 c4 20             	add    $0x20,%esp
   13b66:	83 ec 0c             	sub    $0xc,%esp
   13b69:	68 00 00 02 00       	push   $0x20000
   13b6e:	e8 04 e9 ff ff       	call   12477 <kpanic>
   13b73:	83 c4 10             	add    $0x10,%esp

		// intrinsic return value is the PID
		RET(init_pcb) = zchild->pid;
   13b76:	a1 0c 20 02 00       	mov    0x2200c,%eax
   13b7b:	8b 00                	mov    (%eax),%eax
   13b7d:	8b 55 f4             	mov    -0xc(%ebp),%edx
   13b80:	8b 52 18             	mov    0x18(%edx),%edx
   13b83:	89 50 30             	mov    %edx,0x30(%eax)

		// may also want to return the exit status
		int32_t *ptr = (int32_t *) ARG(init_pcb,2);
   13b86:	a1 0c 20 02 00       	mov    0x2200c,%eax
   13b8b:	8b 00                	mov    (%eax),%eax
   13b8d:	83 c0 48             	add    $0x48,%eax
   13b90:	83 c0 08             	add    $0x8,%eax
   13b93:	8b 00                	mov    (%eax),%eax
   13b95:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		if( ptr != NULL ) {
   13b98:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   13b9c:	74 0b                	je     13ba9 <pcb_zombify+0x1a7>
			// ** This works in the baseline because we aren't using
			// ** any type of memory protection.  If address space
			// ** separation is implemented, this code will very likely
			// ** STOP WORKING, and will need to be fixed.
			// ********************************************************
			*ptr = zchild->exit_status;
   13b9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13ba1:	8b 50 14             	mov    0x14(%eax),%edx
   13ba4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   13ba7:	89 10                	mov    %edx,(%eax)
		}

		// all done - schedule 'init', and clean up the zombie
		schedule( init_pcb );
   13ba9:	a1 0c 20 02 00       	mov    0x2200c,%eax
   13bae:	83 ec 0c             	sub    $0xc,%esp
   13bb1:	50                   	push   %eax
   13bb2:	e8 08 08 00 00       	call   143bf <schedule>
   13bb7:	83 c4 10             	add    $0x10,%esp
		pcb_cleanup( zchild );
   13bba:	83 ec 0c             	sub    $0xc,%esp
   13bbd:	ff 75 f4             	pushl  -0xc(%ebp)
   13bc0:	e8 d1 00 00 00       	call   13c96 <pcb_cleanup>
   13bc5:	83 c4 10             	add    $0x10,%esp
	** init up to deal with a zombie child of the exiting process,
	** init's status won't be Waiting any more, so we don't have to
	** worry about it being scheduled twice.
	*/

	if( parent->state == STATE_WAITING ) {
   13bc8:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13bcb:	8b 40 1c             	mov    0x1c(%eax),%eax
   13bce:	83 f8 06             	cmp    $0x6,%eax
   13bd1:	75 61                	jne    13c34 <pcb_zombify+0x232>

		// verify that the parent is either waiting for this process
		// or is waiting for any of its children
		uint32_t target = ARG(parent,1);
   13bd3:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13bd6:	8b 00                	mov    (%eax),%eax
   13bd8:	83 c0 48             	add    $0x48,%eax
   13bdb:	8b 40 04             	mov    0x4(%eax),%eax
   13bde:	89 45 e0             	mov    %eax,-0x20(%ebp)

		if( target == 0 || target == vicpid ) {
   13be1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   13be5:	74 08                	je     13bef <pcb_zombify+0x1ed>
   13be7:	8b 45 e0             	mov    -0x20(%ebp),%eax
   13bea:	3b 45 e8             	cmp    -0x18(%ebp),%eax
   13bed:	75 45                	jne    13c34 <pcb_zombify+0x232>

			// the parent is waiting for this child or is waiting
			// for any of its children, so we can wake it up.

			// intrinsic return value is the PID
			RET(parent) = vicpid;
   13bef:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13bf2:	8b 00                	mov    (%eax),%eax
   13bf4:	8b 55 e8             	mov    -0x18(%ebp),%edx
   13bf7:	89 50 30             	mov    %edx,0x30(%eax)

			// may also want to return the exit status
			int32_t *ptr = (int32_t *) ARG(parent,2);
   13bfa:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13bfd:	8b 00                	mov    (%eax),%eax
   13bff:	83 c0 48             	add    $0x48,%eax
   13c02:	83 c0 08             	add    $0x8,%eax
   13c05:	8b 00                	mov    (%eax),%eax
   13c07:	89 45 dc             	mov    %eax,-0x24(%ebp)

			if( ptr != NULL ) {
   13c0a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   13c0e:	74 08                	je     13c18 <pcb_zombify+0x216>
				// ** This works in the baseline because we aren't using
				// ** any type of memory protection.  If address space
				// ** separation is implemented, this code will very likely
				// ** STOP WORKING, and will need to be fixed.
				// ********************************************************
				*ptr = victim->exit_status;
   13c10:	8b 53 14             	mov    0x14(%ebx),%edx
   13c13:	8b 45 dc             	mov    -0x24(%ebp),%eax
   13c16:	89 10                	mov    %edx,(%eax)
			}

			// all done - schedule the parent, and clean up the zombie
			schedule( parent );
   13c18:	83 ec 0c             	sub    $0xc,%esp
   13c1b:	ff 75 ec             	pushl  -0x14(%ebp)
   13c1e:	e8 9c 07 00 00       	call   143bf <schedule>
   13c23:	83 c4 10             	add    $0x10,%esp
			pcb_cleanup( victim );
   13c26:	83 ec 0c             	sub    $0xc,%esp
   13c29:	53                   	push   %ebx
   13c2a:	e8 67 00 00 00       	call   13c96 <pcb_cleanup>
   13c2f:	83 c4 10             	add    $0x10,%esp

			return;
   13c32:	eb 5b                	jmp    13c8f <pcb_zombify+0x28d>
	** a state of 'Zombie'.  This simplifies life immensely,
	** because we won't need to dequeue it when it is collected
	** by its parent.
	*/

	victim->state = STATE_ZOMBIE;
   13c34:	c7 43 1c 08 00 00 00 	movl   $0x8,0x1c(%ebx)
	assert( pcb_queue_insert(zombie,victim) == SUCCESS );
   13c3b:	a1 18 20 02 00       	mov    0x22018,%eax
   13c40:	83 ec 08             	sub    $0x8,%esp
   13c43:	53                   	push   %ebx
   13c44:	50                   	push   %eax
   13c45:	e8 9c 02 00 00       	call   13ee6 <pcb_queue_insert>
   13c4a:	83 c4 10             	add    $0x10,%esp
   13c4d:	85 c0                	test   %eax,%eax
   13c4f:	74 3e                	je     13c8f <pcb_zombify+0x28d>
   13c51:	83 ec 04             	sub    $0x4,%esp
   13c54:	68 38 b2 01 00       	push   $0x1b238
   13c59:	6a 00                	push   $0x0
   13c5b:	68 fc 01 00 00       	push   $0x1fc
   13c60:	68 97 b0 01 00       	push   $0x1b097
   13c65:	68 60 b5 01 00       	push   $0x1b560
   13c6a:	68 9f b0 01 00       	push   $0x1b09f
   13c6f:	68 00 00 02 00       	push   $0x20000
   13c74:	e8 7e ea ff ff       	call   126f7 <sprint>
   13c79:	83 c4 20             	add    $0x20,%esp
   13c7c:	83 ec 0c             	sub    $0xc,%esp
   13c7f:	68 00 00 02 00       	push   $0x20000
   13c84:	e8 ee e7 ff ff       	call   12477 <kpanic>
   13c89:	83 c4 10             	add    $0x10,%esp
   13c8c:	eb 01                	jmp    13c8f <pcb_zombify+0x28d>
		return;
   13c8e:	90                   	nop
	/*
	** Note: we don't call _dispatch() here - we leave that for
	** the calling routine, as it's possible we don't need to
	** choose a new current process.
	*/
}
   13c8f:	8d 65 f8             	lea    -0x8(%ebp),%esp
   13c92:	5b                   	pop    %ebx
   13c93:	5e                   	pop    %esi
   13c94:	5d                   	pop    %ebp
   13c95:	c3                   	ret    

00013c96 <pcb_cleanup>:
**
** Reclaim a process' data structures
**
** @param pcb   The PCB to reclaim
*/
void pcb_cleanup( pcb_t *pcb ) {
   13c96:	55                   	push   %ebp
   13c97:	89 e5                	mov    %esp,%ebp
   13c99:	83 ec 08             	sub    $0x8,%esp
#if TRACING_PCB
	cio_printf( "** pcb_cleanup(0x%08x)\n", (uint32_t) pcb );
#endif

	// avoid deallocating a NULL pointer
	if( pcb == NULL ) {
   13c9c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13ca0:	74 1e                	je     13cc0 <pcb_cleanup+0x2a>
		// should this be an error?
		return;
	}

	// we need to release all the VM data structures and frames
	user_cleanup( pcb );
   13ca2:	83 ec 0c             	sub    $0xc,%esp
   13ca5:	ff 75 08             	pushl  0x8(%ebp)
   13ca8:	e8 bd 30 00 00       	call   16d6a <user_cleanup>
   13cad:	83 c4 10             	add    $0x10,%esp

	// release the PCB itself
	pcb_free( pcb );
   13cb0:	83 ec 0c             	sub    $0xc,%esp
   13cb3:	ff 75 08             	pushl  0x8(%ebp)
   13cb6:	e8 11 fc ff ff       	call   138cc <pcb_free>
   13cbb:	83 c4 10             	add    $0x10,%esp
   13cbe:	eb 01                	jmp    13cc1 <pcb_cleanup+0x2b>
		return;
   13cc0:	90                   	nop
}
   13cc1:	c9                   	leave  
   13cc2:	c3                   	ret    

00013cc3 <pcb_find_pid>:
**
** @param pid   The PID to be located
**
** @return Pointer to the PCB, or NULL
*/
pcb_t *pcb_find_pid( uint_t pid ) {
   13cc3:	55                   	push   %ebp
   13cc4:	89 e5                	mov    %esp,%ebp
   13cc6:	83 ec 10             	sub    $0x10,%esp

	// must be a valid PID
	if( pid < 1 ) {
   13cc9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13ccd:	75 07                	jne    13cd6 <pcb_find_pid+0x13>
		return NULL;
   13ccf:	b8 00 00 00 00       	mov    $0x0,%eax
   13cd4:	eb 3d                	jmp    13d13 <pcb_find_pid+0x50>
	}

	// scan the process table
	pcb_t *p = ptable;
   13cd6:	c7 45 fc 20 20 02 00 	movl   $0x22020,-0x4(%ebp)

	for( int i = 0; i < N_PROCS; ++i, ++p ) {
   13cdd:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
   13ce4:	eb 22                	jmp    13d08 <pcb_find_pid+0x45>
		if( p->pid == pid && p->state != STATE_UNUSED ) {
   13ce6:	8b 45 fc             	mov    -0x4(%ebp),%eax
   13ce9:	8b 40 18             	mov    0x18(%eax),%eax
   13cec:	39 45 08             	cmp    %eax,0x8(%ebp)
   13cef:	75 0f                	jne    13d00 <pcb_find_pid+0x3d>
   13cf1:	8b 45 fc             	mov    -0x4(%ebp),%eax
   13cf4:	8b 40 1c             	mov    0x1c(%eax),%eax
   13cf7:	85 c0                	test   %eax,%eax
   13cf9:	74 05                	je     13d00 <pcb_find_pid+0x3d>
			return p;
   13cfb:	8b 45 fc             	mov    -0x4(%ebp),%eax
   13cfe:	eb 13                	jmp    13d13 <pcb_find_pid+0x50>
	for( int i = 0; i < N_PROCS; ++i, ++p ) {
   13d00:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
   13d04:	83 45 fc 30          	addl   $0x30,-0x4(%ebp)
   13d08:	83 7d f8 18          	cmpl   $0x18,-0x8(%ebp)
   13d0c:	7e d8                	jle    13ce6 <pcb_find_pid+0x23>
		}
	}

	// didn't find it!
	return NULL;
   13d0e:	b8 00 00 00 00       	mov    $0x0,%eax
}
   13d13:	c9                   	leave  
   13d14:	c3                   	ret    

00013d15 <pcb_find_ppid>:
**
** @param pid   The PID to be located
**
** @return Pointer to the PCB, or NULL
*/
pcb_t *pcb_find_ppid( uint_t pid ) {
   13d15:	55                   	push   %ebp
   13d16:	89 e5                	mov    %esp,%ebp
   13d18:	83 ec 18             	sub    $0x18,%esp

	// must be a valid PID
	if( pid < 1 ) {
   13d1b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13d1f:	75 0a                	jne    13d2b <pcb_find_ppid+0x16>
		return NULL;
   13d21:	b8 00 00 00 00       	mov    $0x0,%eax
   13d26:	e9 88 00 00 00       	jmp    13db3 <pcb_find_ppid+0x9e>
	}

	// scan the process table
	pcb_t *p = ptable;
   13d2b:	c7 45 f4 20 20 02 00 	movl   $0x22020,-0xc(%ebp)

	for( int i = 0; i < N_PROCS; ++i, ++p ) {
   13d32:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   13d39:	eb 6d                	jmp    13da8 <pcb_find_ppid+0x93>
		assert1( p->parent != NULL );
   13d3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13d3e:	8b 40 0c             	mov    0xc(%eax),%eax
   13d41:	85 c0                	test   %eax,%eax
   13d43:	75 3b                	jne    13d80 <pcb_find_ppid+0x6b>
   13d45:	83 ec 04             	sub    $0x4,%esp
   13d48:	68 5f b2 01 00       	push   $0x1b25f
   13d4d:	6a 01                	push   $0x1
   13d4f:	68 50 02 00 00       	push   $0x250
   13d54:	68 97 b0 01 00       	push   $0x1b097
   13d59:	68 6c b5 01 00       	push   $0x1b56c
   13d5e:	68 9f b0 01 00       	push   $0x1b09f
   13d63:	68 00 00 02 00       	push   $0x20000
   13d68:	e8 8a e9 ff ff       	call   126f7 <sprint>
   13d6d:	83 c4 20             	add    $0x20,%esp
   13d70:	83 ec 0c             	sub    $0xc,%esp
   13d73:	68 00 00 02 00       	push   $0x20000
   13d78:	e8 fa e6 ff ff       	call   12477 <kpanic>
   13d7d:	83 c4 10             	add    $0x10,%esp
		if( p->parent->pid == pid && p->parent->state != STATE_UNUSED ) {
   13d80:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13d83:	8b 40 0c             	mov    0xc(%eax),%eax
   13d86:	8b 40 18             	mov    0x18(%eax),%eax
   13d89:	39 45 08             	cmp    %eax,0x8(%ebp)
   13d8c:	75 12                	jne    13da0 <pcb_find_ppid+0x8b>
   13d8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13d91:	8b 40 0c             	mov    0xc(%eax),%eax
   13d94:	8b 40 1c             	mov    0x1c(%eax),%eax
   13d97:	85 c0                	test   %eax,%eax
   13d99:	74 05                	je     13da0 <pcb_find_ppid+0x8b>
			return p;
   13d9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13d9e:	eb 13                	jmp    13db3 <pcb_find_ppid+0x9e>
	for( int i = 0; i < N_PROCS; ++i, ++p ) {
   13da0:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   13da4:	83 45 f4 30          	addl   $0x30,-0xc(%ebp)
   13da8:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   13dac:	7e 8d                	jle    13d3b <pcb_find_ppid+0x26>
		}
	}

	// didn't find it!
	return NULL;
   13dae:	b8 00 00 00 00       	mov    $0x0,%eax
}
   13db3:	c9                   	leave  
   13db4:	c3                   	ret    

00013db5 <pcb_queue_reset>:
** @param queue[out]  The queue to be initialized
** @param order[in]   The desired ordering for the queue
**
** @return status of the init request
*/
int pcb_queue_reset( pcb_queue_t queue, enum pcb_queue_order_e style ) {
   13db5:	55                   	push   %ebp
   13db6:	89 e5                	mov    %esp,%ebp
   13db8:	83 ec 08             	sub    $0x8,%esp

	// sanity check
	assert1( queue != NULL );
   13dbb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13dbf:	75 3b                	jne    13dfc <pcb_queue_reset+0x47>
   13dc1:	83 ec 04             	sub    $0x4,%esp
   13dc4:	68 8c b0 01 00       	push   $0x1b08c
   13dc9:	6a 01                	push   $0x1
   13dcb:	68 68 02 00 00       	push   $0x268
   13dd0:	68 97 b0 01 00       	push   $0x1b097
   13dd5:	68 7c b5 01 00       	push   $0x1b57c
   13dda:	68 9f b0 01 00       	push   $0x1b09f
   13ddf:	68 00 00 02 00       	push   $0x20000
   13de4:	e8 0e e9 ff ff       	call   126f7 <sprint>
   13de9:	83 c4 20             	add    $0x20,%esp
   13dec:	83 ec 0c             	sub    $0xc,%esp
   13def:	68 00 00 02 00       	push   $0x20000
   13df4:	e8 7e e6 ff ff       	call   12477 <kpanic>
   13df9:	83 c4 10             	add    $0x10,%esp

	// make sure the style is valid
	if( style < O_FIRST_STYLE || style > O_LAST_STYLE ) {
   13dfc:	83 7d 0c 03          	cmpl   $0x3,0xc(%ebp)
   13e00:	76 07                	jbe    13e09 <pcb_queue_reset+0x54>
		return E_BAD_PARAM;
   13e02:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
   13e07:	eb 23                	jmp    13e2c <pcb_queue_reset+0x77>
	}

	// reset the queue
	queue->head = queue->tail = NULL;
   13e09:	8b 45 08             	mov    0x8(%ebp),%eax
   13e0c:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
   13e13:	8b 45 08             	mov    0x8(%ebp),%eax
   13e16:	8b 50 04             	mov    0x4(%eax),%edx
   13e19:	8b 45 08             	mov    0x8(%ebp),%eax
   13e1c:	89 10                	mov    %edx,(%eax)
	queue->order = style;
   13e1e:	8b 45 08             	mov    0x8(%ebp),%eax
   13e21:	8b 55 0c             	mov    0xc(%ebp),%edx
   13e24:	89 50 08             	mov    %edx,0x8(%eax)

	return SUCCESS;
   13e27:	b8 00 00 00 00       	mov    $0x0,%eax
}
   13e2c:	c9                   	leave  
   13e2d:	c3                   	ret    

00013e2e <pcb_queue_empty>:
**
** @param[in] queue  The queue to check
**
** @return true if the queue is empty, else false
*/
bool_t pcb_queue_empty( pcb_queue_t queue ) {
   13e2e:	55                   	push   %ebp
   13e2f:	89 e5                	mov    %esp,%ebp
   13e31:	83 ec 08             	sub    $0x8,%esp

	// if there is no queue, blow up
	assert1( queue != NULL );
   13e34:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13e38:	75 3b                	jne    13e75 <pcb_queue_empty+0x47>
   13e3a:	83 ec 04             	sub    $0x4,%esp
   13e3d:	68 8c b0 01 00       	push   $0x1b08c
   13e42:	6a 01                	push   $0x1
   13e44:	68 83 02 00 00       	push   $0x283
   13e49:	68 97 b0 01 00       	push   $0x1b097
   13e4e:	68 8c b5 01 00       	push   $0x1b58c
   13e53:	68 9f b0 01 00       	push   $0x1b09f
   13e58:	68 00 00 02 00       	push   $0x20000
   13e5d:	e8 95 e8 ff ff       	call   126f7 <sprint>
   13e62:	83 c4 20             	add    $0x20,%esp
   13e65:	83 ec 0c             	sub    $0xc,%esp
   13e68:	68 00 00 02 00       	push   $0x20000
   13e6d:	e8 05 e6 ff ff       	call   12477 <kpanic>
   13e72:	83 c4 10             	add    $0x10,%esp

	return PCB_QUEUE_EMPTY(queue);
   13e75:	8b 45 08             	mov    0x8(%ebp),%eax
   13e78:	8b 00                	mov    (%eax),%eax
   13e7a:	85 c0                	test   %eax,%eax
   13e7c:	0f 94 c0             	sete   %al
}
   13e7f:	c9                   	leave  
   13e80:	c3                   	ret    

00013e81 <pcb_queue_length>:
**
** @param[in] queue  The queue to check
**
** @return the count (0 if the queue is empty)
*/
uint_t pcb_queue_length( const pcb_queue_t queue ) {
   13e81:	55                   	push   %ebp
   13e82:	89 e5                	mov    %esp,%ebp
   13e84:	56                   	push   %esi
   13e85:	53                   	push   %ebx

	// sanity check
	assert1( queue != NULL );
   13e86:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13e8a:	75 3b                	jne    13ec7 <pcb_queue_length+0x46>
   13e8c:	83 ec 04             	sub    $0x4,%esp
   13e8f:	68 8c b0 01 00       	push   $0x1b08c
   13e94:	6a 01                	push   $0x1
   13e96:	68 94 02 00 00       	push   $0x294
   13e9b:	68 97 b0 01 00       	push   $0x1b097
   13ea0:	68 9c b5 01 00       	push   $0x1b59c
   13ea5:	68 9f b0 01 00       	push   $0x1b09f
   13eaa:	68 00 00 02 00       	push   $0x20000
   13eaf:	e8 43 e8 ff ff       	call   126f7 <sprint>
   13eb4:	83 c4 20             	add    $0x20,%esp
   13eb7:	83 ec 0c             	sub    $0xc,%esp
   13eba:	68 00 00 02 00       	push   $0x20000
   13ebf:	e8 b3 e5 ff ff       	call   12477 <kpanic>
   13ec4:	83 c4 10             	add    $0x10,%esp

	// this is pretty simple
	register pcb_t *tmp = queue->head;
   13ec7:	8b 45 08             	mov    0x8(%ebp),%eax
   13eca:	8b 18                	mov    (%eax),%ebx
	register int num = 0;
   13ecc:	be 00 00 00 00       	mov    $0x0,%esi
	
	while( tmp != NULL ) {
   13ed1:	eb 06                	jmp    13ed9 <pcb_queue_length+0x58>
		++num;
   13ed3:	83 c6 01             	add    $0x1,%esi
		tmp = tmp->next;
   13ed6:	8b 5b 08             	mov    0x8(%ebx),%ebx
	while( tmp != NULL ) {
   13ed9:	85 db                	test   %ebx,%ebx
   13edb:	75 f6                	jne    13ed3 <pcb_queue_length+0x52>
	}

	return num;
   13edd:	89 f0                	mov    %esi,%eax
}
   13edf:	8d 65 f8             	lea    -0x8(%ebp),%esp
   13ee2:	5b                   	pop    %ebx
   13ee3:	5e                   	pop    %esi
   13ee4:	5d                   	pop    %ebp
   13ee5:	c3                   	ret    

00013ee6 <pcb_queue_insert>:
** @param queue[in,out]  The queue to be used
** @param pcb[in]        The PCB to be inserted
**
** @return status of the insertion request
*/
int pcb_queue_insert( pcb_queue_t queue, pcb_t *pcb ) {
   13ee6:	55                   	push   %ebp
   13ee7:	89 e5                	mov    %esp,%ebp
   13ee9:	83 ec 18             	sub    $0x18,%esp

	// sanity checks
	assert1( queue != NULL );
   13eec:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13ef0:	75 3b                	jne    13f2d <pcb_queue_insert+0x47>
   13ef2:	83 ec 04             	sub    $0x4,%esp
   13ef5:	68 8c b0 01 00       	push   $0x1b08c
   13efa:	6a 01                	push   $0x1
   13efc:	68 af 02 00 00       	push   $0x2af
   13f01:	68 97 b0 01 00       	push   $0x1b097
   13f06:	68 b0 b5 01 00       	push   $0x1b5b0
   13f0b:	68 9f b0 01 00       	push   $0x1b09f
   13f10:	68 00 00 02 00       	push   $0x20000
   13f15:	e8 dd e7 ff ff       	call   126f7 <sprint>
   13f1a:	83 c4 20             	add    $0x20,%esp
   13f1d:	83 ec 0c             	sub    $0xc,%esp
   13f20:	68 00 00 02 00       	push   $0x20000
   13f25:	e8 4d e5 ff ff       	call   12477 <kpanic>
   13f2a:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   13f2d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   13f31:	75 3b                	jne    13f6e <pcb_queue_insert+0x88>
   13f33:	83 ec 04             	sub    $0x4,%esp
   13f36:	68 b5 b0 01 00       	push   $0x1b0b5
   13f3b:	6a 01                	push   $0x1
   13f3d:	68 b0 02 00 00       	push   $0x2b0
   13f42:	68 97 b0 01 00       	push   $0x1b097
   13f47:	68 b0 b5 01 00       	push   $0x1b5b0
   13f4c:	68 9f b0 01 00       	push   $0x1b09f
   13f51:	68 00 00 02 00       	push   $0x20000
   13f56:	e8 9c e7 ff ff       	call   126f7 <sprint>
   13f5b:	83 c4 20             	add    $0x20,%esp
   13f5e:	83 ec 0c             	sub    $0xc,%esp
   13f61:	68 00 00 02 00       	push   $0x20000
   13f66:	e8 0c e5 ff ff       	call   12477 <kpanic>
   13f6b:	83 c4 10             	add    $0x10,%esp

	// if this PCB is already in a queue, we won't touch it
	if( pcb->next != NULL ) {
   13f6e:	8b 45 0c             	mov    0xc(%ebp),%eax
   13f71:	8b 40 08             	mov    0x8(%eax),%eax
   13f74:	85 c0                	test   %eax,%eax
   13f76:	74 0a                	je     13f82 <pcb_queue_insert+0x9c>
		// what to do? we let the caller decide
		return E_BAD_PARAM;
   13f78:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
   13f7d:	e9 48 01 00 00       	jmp    140ca <pcb_queue_insert+0x1e4>
	}

	// is the queue empty?
	if( queue->head == NULL ) {
   13f82:	8b 45 08             	mov    0x8(%ebp),%eax
   13f85:	8b 00                	mov    (%eax),%eax
   13f87:	85 c0                	test   %eax,%eax
   13f89:	75 1e                	jne    13fa9 <pcb_queue_insert+0xc3>
		queue->head = queue->tail = pcb;
   13f8b:	8b 45 08             	mov    0x8(%ebp),%eax
   13f8e:	8b 55 0c             	mov    0xc(%ebp),%edx
   13f91:	89 50 04             	mov    %edx,0x4(%eax)
   13f94:	8b 45 08             	mov    0x8(%ebp),%eax
   13f97:	8b 50 04             	mov    0x4(%eax),%edx
   13f9a:	8b 45 08             	mov    0x8(%ebp),%eax
   13f9d:	89 10                	mov    %edx,(%eax)
		return SUCCESS;
   13f9f:	b8 00 00 00 00       	mov    $0x0,%eax
   13fa4:	e9 21 01 00 00       	jmp    140ca <pcb_queue_insert+0x1e4>
	}
	assert1( queue->tail != NULL );
   13fa9:	8b 45 08             	mov    0x8(%ebp),%eax
   13fac:	8b 40 04             	mov    0x4(%eax),%eax
   13faf:	85 c0                	test   %eax,%eax
   13fb1:	75 3b                	jne    13fee <pcb_queue_insert+0x108>
   13fb3:	83 ec 04             	sub    $0x4,%esp
   13fb6:	68 6e b2 01 00       	push   $0x1b26e
   13fbb:	6a 01                	push   $0x1
   13fbd:	68 bd 02 00 00       	push   $0x2bd
   13fc2:	68 97 b0 01 00       	push   $0x1b097
   13fc7:	68 b0 b5 01 00       	push   $0x1b5b0
   13fcc:	68 9f b0 01 00       	push   $0x1b09f
   13fd1:	68 00 00 02 00       	push   $0x20000
   13fd6:	e8 1c e7 ff ff       	call   126f7 <sprint>
   13fdb:	83 c4 20             	add    $0x20,%esp
   13fde:	83 ec 0c             	sub    $0xc,%esp
   13fe1:	68 00 00 02 00       	push   $0x20000
   13fe6:	e8 8c e4 ff ff       	call   12477 <kpanic>
   13feb:	83 c4 10             	add    $0x10,%esp

	// no, so we need to search it
	pcb_t *prev = NULL;
   13fee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// find the predecessor node
	switch( queue->order ) {
   13ff5:	8b 45 08             	mov    0x8(%ebp),%eax
   13ff8:	8b 40 08             	mov    0x8(%eax),%eax
   13ffb:	83 f8 01             	cmp    $0x1,%eax
   13ffe:	74 1c                	je     1401c <pcb_queue_insert+0x136>
   14000:	83 f8 01             	cmp    $0x1,%eax
   14003:	72 0c                	jb     14011 <pcb_queue_insert+0x12b>
   14005:	83 f8 02             	cmp    $0x2,%eax
   14008:	74 28                	je     14032 <pcb_queue_insert+0x14c>
   1400a:	83 f8 03             	cmp    $0x3,%eax
   1400d:	74 39                	je     14048 <pcb_queue_insert+0x162>
   1400f:	eb 4d                	jmp    1405e <pcb_queue_insert+0x178>
	case O_FIFO:
		prev = queue->tail;
   14011:	8b 45 08             	mov    0x8(%ebp),%eax
   14014:	8b 40 04             	mov    0x4(%eax),%eax
   14017:	89 45 f4             	mov    %eax,-0xc(%ebp)
		break;
   1401a:	eb 49                	jmp    14065 <pcb_queue_insert+0x17f>
	case O_PRIO:
		prev = find_prev_priority(queue,pcb);
   1401c:	83 ec 08             	sub    $0x8,%esp
   1401f:	ff 75 0c             	pushl  0xc(%ebp)
   14022:	ff 75 08             	pushl  0x8(%ebp)
   14025:	e8 25 f4 ff ff       	call   1344f <find_prev_priority>
   1402a:	83 c4 10             	add    $0x10,%esp
   1402d:	89 45 f4             	mov    %eax,-0xc(%ebp)
		break;
   14030:	eb 33                	jmp    14065 <pcb_queue_insert+0x17f>
	case O_PID:
		prev = find_prev_pid(queue,pcb);
   14032:	83 ec 08             	sub    $0x8,%esp
   14035:	ff 75 0c             	pushl  0xc(%ebp)
   14038:	ff 75 08             	pushl  0x8(%ebp)
   1403b:	e8 d2 f4 ff ff       	call   13512 <find_prev_pid>
   14040:	83 c4 10             	add    $0x10,%esp
   14043:	89 45 f4             	mov    %eax,-0xc(%ebp)
		break;
   14046:	eb 1d                	jmp    14065 <pcb_queue_insert+0x17f>
	case O_WAKEUP:
		prev = find_prev_wakeup(queue,pcb);
   14048:	83 ec 08             	sub    $0x8,%esp
   1404b:	ff 75 0c             	pushl  0xc(%ebp)
   1404e:	ff 75 08             	pushl  0x8(%ebp)
   14051:	e8 36 f3 ff ff       	call   1338c <find_prev_wakeup>
   14056:	83 c4 10             	add    $0x10,%esp
   14059:	89 45 f4             	mov    %eax,-0xc(%ebp)
		break;
   1405c:	eb 07                	jmp    14065 <pcb_queue_insert+0x17f>
	default:
		// do we need something more specific here?
		return E_BAD_PARAM;
   1405e:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
   14063:	eb 65                	jmp    140ca <pcb_queue_insert+0x1e4>
	}

	// OK, we found the predecessor node; time to do the insertion

	if( prev == NULL ) {
   14065:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   14069:	75 27                	jne    14092 <pcb_queue_insert+0x1ac>

		// there is no predecessor, so we're
		// inserting at the front of the queue
		pcb->next = queue->head;
   1406b:	8b 45 08             	mov    0x8(%ebp),%eax
   1406e:	8b 10                	mov    (%eax),%edx
   14070:	8b 45 0c             	mov    0xc(%ebp),%eax
   14073:	89 50 08             	mov    %edx,0x8(%eax)
		if( queue->head == NULL ) {
   14076:	8b 45 08             	mov    0x8(%ebp),%eax
   14079:	8b 00                	mov    (%eax),%eax
   1407b:	85 c0                	test   %eax,%eax
   1407d:	75 09                	jne    14088 <pcb_queue_insert+0x1a2>
			// empty queue!?! - should we panic?
			queue->tail = pcb;
   1407f:	8b 45 08             	mov    0x8(%ebp),%eax
   14082:	8b 55 0c             	mov    0xc(%ebp),%edx
   14085:	89 50 04             	mov    %edx,0x4(%eax)
		}
		queue->head = pcb;
   14088:	8b 45 08             	mov    0x8(%ebp),%eax
   1408b:	8b 55 0c             	mov    0xc(%ebp),%edx
   1408e:	89 10                	mov    %edx,(%eax)
   14090:	eb 33                	jmp    140c5 <pcb_queue_insert+0x1df>

	} else if( prev->next == NULL ) {
   14092:	8b 45 f4             	mov    -0xc(%ebp),%eax
   14095:	8b 40 08             	mov    0x8(%eax),%eax
   14098:	85 c0                	test   %eax,%eax
   1409a:	75 14                	jne    140b0 <pcb_queue_insert+0x1ca>

		// append at end
		prev->next = pcb;
   1409c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1409f:	8b 55 0c             	mov    0xc(%ebp),%edx
   140a2:	89 50 08             	mov    %edx,0x8(%eax)
		queue->tail = pcb;
   140a5:	8b 45 08             	mov    0x8(%ebp),%eax
   140a8:	8b 55 0c             	mov    0xc(%ebp),%edx
   140ab:	89 50 04             	mov    %edx,0x4(%eax)
   140ae:	eb 15                	jmp    140c5 <pcb_queue_insert+0x1df>

	} else {

		// insert between prev & prev->next
		pcb->next = prev->next;
   140b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
   140b3:	8b 50 08             	mov    0x8(%eax),%edx
   140b6:	8b 45 0c             	mov    0xc(%ebp),%eax
   140b9:	89 50 08             	mov    %edx,0x8(%eax)
		prev->next = pcb;
   140bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
   140bf:	8b 55 0c             	mov    0xc(%ebp),%edx
   140c2:	89 50 08             	mov    %edx,0x8(%eax)

	}

	return SUCCESS;
   140c5:	b8 00 00 00 00       	mov    $0x0,%eax
}
   140ca:	c9                   	leave  
   140cb:	c3                   	ret    

000140cc <pcb_queue_remove>:
** @param queue[in,out]  The queue to be used
** @param pcb[out]       Pointer to where the PCB pointer will be saved
**
** @return status of the removal request
*/
int pcb_queue_remove( pcb_queue_t queue, pcb_t **pcb ) {
   140cc:	55                   	push   %ebp
   140cd:	89 e5                	mov    %esp,%ebp
   140cf:	83 ec 18             	sub    $0x18,%esp

	//sanity checks
	assert1( queue != NULL );
   140d2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   140d6:	75 3b                	jne    14113 <pcb_queue_remove+0x47>
   140d8:	83 ec 04             	sub    $0x4,%esp
   140db:	68 8c b0 01 00       	push   $0x1b08c
   140e0:	6a 01                	push   $0x1
   140e2:	68 00 03 00 00       	push   $0x300
   140e7:	68 97 b0 01 00       	push   $0x1b097
   140ec:	68 c4 b5 01 00       	push   $0x1b5c4
   140f1:	68 9f b0 01 00       	push   $0x1b09f
   140f6:	68 00 00 02 00       	push   $0x20000
   140fb:	e8 f7 e5 ff ff       	call   126f7 <sprint>
   14100:	83 c4 20             	add    $0x20,%esp
   14103:	83 ec 0c             	sub    $0xc,%esp
   14106:	68 00 00 02 00       	push   $0x20000
   1410b:	e8 67 e3 ff ff       	call   12477 <kpanic>
   14110:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   14113:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   14117:	75 3b                	jne    14154 <pcb_queue_remove+0x88>
   14119:	83 ec 04             	sub    $0x4,%esp
   1411c:	68 b5 b0 01 00       	push   $0x1b0b5
   14121:	6a 01                	push   $0x1
   14123:	68 01 03 00 00       	push   $0x301
   14128:	68 97 b0 01 00       	push   $0x1b097
   1412d:	68 c4 b5 01 00       	push   $0x1b5c4
   14132:	68 9f b0 01 00       	push   $0x1b09f
   14137:	68 00 00 02 00       	push   $0x20000
   1413c:	e8 b6 e5 ff ff       	call   126f7 <sprint>
   14141:	83 c4 20             	add    $0x20,%esp
   14144:	83 ec 0c             	sub    $0xc,%esp
   14147:	68 00 00 02 00       	push   $0x20000
   1414c:	e8 26 e3 ff ff       	call   12477 <kpanic>
   14151:	83 c4 10             	add    $0x10,%esp

	// can't get anything if there's nothing to get!
	if( PCB_QUEUE_EMPTY(queue) ) {
   14154:	8b 45 08             	mov    0x8(%ebp),%eax
   14157:	8b 00                	mov    (%eax),%eax
   14159:	85 c0                	test   %eax,%eax
   1415b:	75 07                	jne    14164 <pcb_queue_remove+0x98>
		return E_EMPTY_QUEUE;
   1415d:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
   14162:	eb 3d                	jmp    141a1 <pcb_queue_remove+0xd5>
	}

	// take the first entry from the queue
	pcb_t *tmp = queue->head;
   14164:	8b 45 08             	mov    0x8(%ebp),%eax
   14167:	8b 00                	mov    (%eax),%eax
   14169:	89 45 f4             	mov    %eax,-0xc(%ebp)
	queue->head = tmp->next;
   1416c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1416f:	8b 50 08             	mov    0x8(%eax),%edx
   14172:	8b 45 08             	mov    0x8(%ebp),%eax
   14175:	89 10                	mov    %edx,(%eax)

	// disconnect it completely
	tmp->next = NULL;
   14177:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1417a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)

	// was this the last thing in the queue?
	if( queue->head == NULL ) {
   14181:	8b 45 08             	mov    0x8(%ebp),%eax
   14184:	8b 00                	mov    (%eax),%eax
   14186:	85 c0                	test   %eax,%eax
   14188:	75 0a                	jne    14194 <pcb_queue_remove+0xc8>
		// yes, so clear the tail pointer for consistency
		queue->tail = NULL;
   1418a:	8b 45 08             	mov    0x8(%ebp),%eax
   1418d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	}

	// save the pointer
	*pcb = tmp;
   14194:	8b 45 0c             	mov    0xc(%ebp),%eax
   14197:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1419a:	89 10                	mov    %edx,(%eax)

	return SUCCESS;
   1419c:	b8 00 00 00 00       	mov    $0x0,%eax
}
   141a1:	c9                   	leave  
   141a2:	c3                   	ret    

000141a3 <pcb_queue_remove_this>:
** @param queue[in,out]  The queue to be used
** @param pcb[in]        Pointer to the PCB to be removed
**
** @return status of the removal request
*/
int pcb_queue_remove_this( pcb_queue_t queue, pcb_t *pcb ) {
   141a3:	55                   	push   %ebp
   141a4:	89 e5                	mov    %esp,%ebp
   141a6:	83 ec 18             	sub    $0x18,%esp

	//sanity checks
	assert1( queue != NULL );
   141a9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   141ad:	75 3b                	jne    141ea <pcb_queue_remove_this+0x47>
   141af:	83 ec 04             	sub    $0x4,%esp
   141b2:	68 8c b0 01 00       	push   $0x1b08c
   141b7:	6a 01                	push   $0x1
   141b9:	68 2c 03 00 00       	push   $0x32c
   141be:	68 97 b0 01 00       	push   $0x1b097
   141c3:	68 d8 b5 01 00       	push   $0x1b5d8
   141c8:	68 9f b0 01 00       	push   $0x1b09f
   141cd:	68 00 00 02 00       	push   $0x20000
   141d2:	e8 20 e5 ff ff       	call   126f7 <sprint>
   141d7:	83 c4 20             	add    $0x20,%esp
   141da:	83 ec 0c             	sub    $0xc,%esp
   141dd:	68 00 00 02 00       	push   $0x20000
   141e2:	e8 90 e2 ff ff       	call   12477 <kpanic>
   141e7:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   141ea:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   141ee:	75 3b                	jne    1422b <pcb_queue_remove_this+0x88>
   141f0:	83 ec 04             	sub    $0x4,%esp
   141f3:	68 b5 b0 01 00       	push   $0x1b0b5
   141f8:	6a 01                	push   $0x1
   141fa:	68 2d 03 00 00       	push   $0x32d
   141ff:	68 97 b0 01 00       	push   $0x1b097
   14204:	68 d8 b5 01 00       	push   $0x1b5d8
   14209:	68 9f b0 01 00       	push   $0x1b09f
   1420e:	68 00 00 02 00       	push   $0x20000
   14213:	e8 df e4 ff ff       	call   126f7 <sprint>
   14218:	83 c4 20             	add    $0x20,%esp
   1421b:	83 ec 0c             	sub    $0xc,%esp
   1421e:	68 00 00 02 00       	push   $0x20000
   14223:	e8 4f e2 ff ff       	call   12477 <kpanic>
   14228:	83 c4 10             	add    $0x10,%esp

	// can't get anything if there's nothing to get!
	if( PCB_QUEUE_EMPTY(queue) ) {
   1422b:	8b 45 08             	mov    0x8(%ebp),%eax
   1422e:	8b 00                	mov    (%eax),%eax
   14230:	85 c0                	test   %eax,%eax
   14232:	75 0a                	jne    1423e <pcb_queue_remove_this+0x9b>
		return E_EMPTY_QUEUE;
   14234:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
   14239:	e9 21 01 00 00       	jmp    1435f <pcb_queue_remove_this+0x1bc>
	}

	// iterate through the queue until we find the desired PCB
	pcb_t *prev = NULL;
   1423e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *curr = queue->head;
   14245:	8b 45 08             	mov    0x8(%ebp),%eax
   14248:	8b 00                	mov    (%eax),%eax
   1424a:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr != NULL && curr != pcb ) {
   1424d:	eb 0f                	jmp    1425e <pcb_queue_remove_this+0xbb>
		prev = curr;
   1424f:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14252:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   14255:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14258:	8b 40 08             	mov    0x8(%eax),%eax
   1425b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr != NULL && curr != pcb ) {
   1425e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   14262:	74 08                	je     1426c <pcb_queue_remove_this+0xc9>
   14264:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14267:	3b 45 0c             	cmp    0xc(%ebp),%eax
   1426a:	75 e3                	jne    1424f <pcb_queue_remove_this+0xac>
	//   3.    0    !0    !0    removing first element
	//   4.   !0     0    --    *** NOT FOUND ***
	//   5.   !0    !0     0    removing from end
	//   6.   !0    !0    !0    removing from middle

	if( curr == NULL ) {
   1426c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   14270:	75 4b                	jne    142bd <pcb_queue_remove_this+0x11a>
		// case 1
		assert( prev != NULL );
   14272:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   14276:	75 3b                	jne    142b3 <pcb_queue_remove_this+0x110>
   14278:	83 ec 04             	sub    $0x4,%esp
   1427b:	68 7f b2 01 00       	push   $0x1b27f
   14280:	6a 00                	push   $0x0
   14282:	68 48 03 00 00       	push   $0x348
   14287:	68 97 b0 01 00       	push   $0x1b097
   1428c:	68 d8 b5 01 00       	push   $0x1b5d8
   14291:	68 9f b0 01 00       	push   $0x1b09f
   14296:	68 00 00 02 00       	push   $0x20000
   1429b:	e8 57 e4 ff ff       	call   126f7 <sprint>
   142a0:	83 c4 20             	add    $0x20,%esp
   142a3:	83 ec 0c             	sub    $0xc,%esp
   142a6:	68 00 00 02 00       	push   $0x20000
   142ab:	e8 c7 e1 ff ff       	call   12477 <kpanic>
   142b0:	83 c4 10             	add    $0x10,%esp
		// case 4
		return E_NOT_FOUND;
   142b3:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
   142b8:	e9 a2 00 00 00       	jmp    1435f <pcb_queue_remove_this+0x1bc>
	}

	// connect predecessor to successor
	if( prev != NULL ) {
   142bd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   142c1:	74 0e                	je     142d1 <pcb_queue_remove_this+0x12e>
		// not the first element
		// cases 5 and 6
		prev->next = curr->next;
   142c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
   142c6:	8b 50 08             	mov    0x8(%eax),%edx
   142c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
   142cc:	89 50 08             	mov    %edx,0x8(%eax)
   142cf:	eb 0b                	jmp    142dc <pcb_queue_remove_this+0x139>
	} else {
		// removing first element
		// cases 2 and 3
		queue->head = curr->next;
   142d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
   142d4:	8b 50 08             	mov    0x8(%eax),%edx
   142d7:	8b 45 08             	mov    0x8(%ebp),%eax
   142da:	89 10                	mov    %edx,(%eax)
	}

	// if this was the last node (cases 2 and 5),
	// also need to reset the tail pointer
	if( curr->next == NULL ) {
   142dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
   142df:	8b 40 08             	mov    0x8(%eax),%eax
   142e2:	85 c0                	test   %eax,%eax
   142e4:	75 09                	jne    142ef <pcb_queue_remove_this+0x14c>
		// if this was the only entry (2), prev is NULL,
		// so this works for that case, too
		queue->tail = prev;
   142e6:	8b 45 08             	mov    0x8(%ebp),%eax
   142e9:	8b 55 f4             	mov    -0xc(%ebp),%edx
   142ec:	89 50 04             	mov    %edx,0x4(%eax)
	}

	// unlink current from queue
	curr->next = NULL;
   142ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
   142f2:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)

	// there's a possible consistancy problem here if somehow
	// one of the queue pointers is NULL and the other one
	// is not NULL

	assert1(
   142f9:	8b 45 08             	mov    0x8(%ebp),%eax
   142fc:	8b 00                	mov    (%eax),%eax
   142fe:	85 c0                	test   %eax,%eax
   14300:	75 0a                	jne    1430c <pcb_queue_remove_this+0x169>
   14302:	8b 45 08             	mov    0x8(%ebp),%eax
   14305:	8b 40 04             	mov    0x4(%eax),%eax
   14308:	85 c0                	test   %eax,%eax
   1430a:	74 4e                	je     1435a <pcb_queue_remove_this+0x1b7>
   1430c:	8b 45 08             	mov    0x8(%ebp),%eax
   1430f:	8b 00                	mov    (%eax),%eax
   14311:	85 c0                	test   %eax,%eax
   14313:	74 0a                	je     1431f <pcb_queue_remove_this+0x17c>
   14315:	8b 45 08             	mov    0x8(%ebp),%eax
   14318:	8b 40 04             	mov    0x4(%eax),%eax
   1431b:	85 c0                	test   %eax,%eax
   1431d:	75 3b                	jne    1435a <pcb_queue_remove_this+0x1b7>
   1431f:	83 ec 04             	sub    $0x4,%esp
   14322:	68 8c b2 01 00       	push   $0x1b28c
   14327:	6a 01                	push   $0x1
   14329:	68 6a 03 00 00       	push   $0x36a
   1432e:	68 97 b0 01 00       	push   $0x1b097
   14333:	68 d8 b5 01 00       	push   $0x1b5d8
   14338:	68 9f b0 01 00       	push   $0x1b09f
   1433d:	68 00 00 02 00       	push   $0x20000
   14342:	e8 b0 e3 ff ff       	call   126f7 <sprint>
   14347:	83 c4 20             	add    $0x20,%esp
   1434a:	83 ec 0c             	sub    $0xc,%esp
   1434d:	68 00 00 02 00       	push   $0x20000
   14352:	e8 20 e1 ff ff       	call   12477 <kpanic>
   14357:	83 c4 10             	add    $0x10,%esp
		(queue->head == NULL && queue->tail == NULL) ||
		(queue->head != NULL && queue->tail != NULL)
	);

	return SUCCESS;
   1435a:	b8 00 00 00 00       	mov    $0x0,%eax
}
   1435f:	c9                   	leave  
   14360:	c3                   	ret    

00014361 <pcb_queue_peek>:
**
** @param queue[in]  The queue to be used
**
** @return the PCB poiner, or NULL if the queue is empty
*/
pcb_t *pcb_queue_peek( const pcb_queue_t queue ) {
   14361:	55                   	push   %ebp
   14362:	89 e5                	mov    %esp,%ebp
   14364:	83 ec 08             	sub    $0x8,%esp

	//sanity check
	assert1( queue != NULL );
   14367:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1436b:	75 3b                	jne    143a8 <pcb_queue_peek+0x47>
   1436d:	83 ec 04             	sub    $0x4,%esp
   14370:	68 8c b0 01 00       	push   $0x1b08c
   14375:	6a 01                	push   $0x1
   14377:	68 7c 03 00 00       	push   $0x37c
   1437c:	68 97 b0 01 00       	push   $0x1b097
   14381:	68 f0 b5 01 00       	push   $0x1b5f0
   14386:	68 9f b0 01 00       	push   $0x1b09f
   1438b:	68 00 00 02 00       	push   $0x20000
   14390:	e8 62 e3 ff ff       	call   126f7 <sprint>
   14395:	83 c4 20             	add    $0x20,%esp
   14398:	83 ec 0c             	sub    $0xc,%esp
   1439b:	68 00 00 02 00       	push   $0x20000
   143a0:	e8 d2 e0 ff ff       	call   12477 <kpanic>
   143a5:	83 c4 10             	add    $0x10,%esp

	// can't get anything if there's nothing to get!
	if( PCB_QUEUE_EMPTY(queue) ) {
   143a8:	8b 45 08             	mov    0x8(%ebp),%eax
   143ab:	8b 00                	mov    (%eax),%eax
   143ad:	85 c0                	test   %eax,%eax
   143af:	75 07                	jne    143b8 <pcb_queue_peek+0x57>
		return NULL;
   143b1:	b8 00 00 00 00       	mov    $0x0,%eax
   143b6:	eb 05                	jmp    143bd <pcb_queue_peek+0x5c>
	}

	// just return the first entry from the queue
	return queue->head;
   143b8:	8b 45 08             	mov    0x8(%ebp),%eax
   143bb:	8b 00                	mov    (%eax),%eax
}
   143bd:	c9                   	leave  
   143be:	c3                   	ret    

000143bf <schedule>:
**
** Schedule the supplied process
**
** @param pcb   Pointer to the PCB of the process to be scheduled
*/
void schedule( pcb_t *pcb ) {
   143bf:	55                   	push   %ebp
   143c0:	89 e5                	mov    %esp,%ebp
   143c2:	83 ec 08             	sub    $0x8,%esp

	// sanity check
	assert1( pcb != NULL );
   143c5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   143c9:	75 3b                	jne    14406 <schedule+0x47>
   143cb:	83 ec 04             	sub    $0x4,%esp
   143ce:	68 b5 b0 01 00       	push   $0x1b0b5
   143d3:	6a 01                	push   $0x1
   143d5:	68 95 03 00 00       	push   $0x395
   143da:	68 97 b0 01 00       	push   $0x1b097
   143df:	68 00 b6 01 00       	push   $0x1b600
   143e4:	68 9f b0 01 00       	push   $0x1b09f
   143e9:	68 00 00 02 00       	push   $0x20000
   143ee:	e8 04 e3 ff ff       	call   126f7 <sprint>
   143f3:	83 c4 20             	add    $0x20,%esp
   143f6:	83 ec 0c             	sub    $0xc,%esp
   143f9:	68 00 00 02 00       	push   $0x20000
   143fe:	e8 74 e0 ff ff       	call   12477 <kpanic>
   14403:	83 c4 10             	add    $0x10,%esp

	// check for a killed process
	if( pcb->state == STATE_KILLED ) {
   14406:	8b 45 08             	mov    0x8(%ebp),%eax
   14409:	8b 40 1c             	mov    0x1c(%eax),%eax
   1440c:	83 f8 07             	cmp    $0x7,%eax
   1440f:	75 10                	jne    14421 <schedule+0x62>
		pcb_zombify( pcb );
   14411:	83 ec 0c             	sub    $0xc,%esp
   14414:	ff 75 08             	pushl  0x8(%ebp)
   14417:	e8 e6 f5 ff ff       	call   13a02 <pcb_zombify>
   1441c:	83 c4 10             	add    $0x10,%esp
		return;
   1441f:	eb 5d                	jmp    1447e <schedule+0xbf>
	}

	// mark it as ready
	pcb->state = STATE_READY;
   14421:	8b 45 08             	mov    0x8(%ebp),%eax
   14424:	c7 40 1c 02 00 00 00 	movl   $0x2,0x1c(%eax)

	// add it to the ready queue
	if( pcb_queue_insert(ready,pcb) != SUCCESS ) {
   1442b:	a1 d0 24 02 00       	mov    0x224d0,%eax
   14430:	83 ec 08             	sub    $0x8,%esp
   14433:	ff 75 08             	pushl  0x8(%ebp)
   14436:	50                   	push   %eax
   14437:	e8 aa fa ff ff       	call   13ee6 <pcb_queue_insert>
   1443c:	83 c4 10             	add    $0x10,%esp
   1443f:	85 c0                	test   %eax,%eax
   14441:	74 3b                	je     1447e <schedule+0xbf>
		PANIC( 0, "schedule insert fail" );
   14443:	83 ec 04             	sub    $0x4,%esp
   14446:	68 dd b2 01 00       	push   $0x1b2dd
   1444b:	6a 00                	push   $0x0
   1444d:	68 a2 03 00 00       	push   $0x3a2
   14452:	68 97 b0 01 00       	push   $0x1b097
   14457:	68 00 b6 01 00       	push   $0x1b600
   1445c:	68 9f b0 01 00       	push   $0x1b09f
   14461:	68 00 00 02 00       	push   $0x20000
   14466:	e8 8c e2 ff ff       	call   126f7 <sprint>
   1446b:	83 c4 20             	add    $0x20,%esp
   1446e:	83 ec 0c             	sub    $0xc,%esp
   14471:	68 00 00 02 00       	push   $0x20000
   14476:	e8 fc df ff ff       	call   12477 <kpanic>
   1447b:	83 c4 10             	add    $0x10,%esp
	}
}
   1447e:	c9                   	leave  
   1447f:	c3                   	ret    

00014480 <dispatch>:
/**
** dispatch()
**
** Select the next process to receive the CPU
*/
void dispatch( void ) {
   14480:	55                   	push   %ebp
   14481:	89 e5                	mov    %esp,%ebp
   14483:	83 ec 18             	sub    $0x18,%esp

	// verify that there is no current process
	assert( current == NULL );
   14486:	a1 14 20 02 00       	mov    0x22014,%eax
   1448b:	85 c0                	test   %eax,%eax
   1448d:	74 3b                	je     144ca <dispatch+0x4a>
   1448f:	83 ec 04             	sub    $0x4,%esp
   14492:	68 f4 b2 01 00       	push   $0x1b2f4
   14497:	6a 00                	push   $0x0
   14499:	68 ae 03 00 00       	push   $0x3ae
   1449e:	68 97 b0 01 00       	push   $0x1b097
   144a3:	68 0c b6 01 00       	push   $0x1b60c
   144a8:	68 9f b0 01 00       	push   $0x1b09f
   144ad:	68 00 00 02 00       	push   $0x20000
   144b2:	e8 40 e2 ff ff       	call   126f7 <sprint>
   144b7:	83 c4 20             	add    $0x20,%esp
   144ba:	83 ec 0c             	sub    $0xc,%esp
   144bd:	68 00 00 02 00       	push   $0x20000
   144c2:	e8 b0 df ff ff       	call   12477 <kpanic>
   144c7:	83 c4 10             	add    $0x10,%esp

	// grab whoever is at the head of the queue
	int status = pcb_queue_remove( ready, &current );
   144ca:	a1 d0 24 02 00       	mov    0x224d0,%eax
   144cf:	83 ec 08             	sub    $0x8,%esp
   144d2:	68 14 20 02 00       	push   $0x22014
   144d7:	50                   	push   %eax
   144d8:	e8 ef fb ff ff       	call   140cc <pcb_queue_remove>
   144dd:	83 c4 10             	add    $0x10,%esp
   144e0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( status != SUCCESS ) {
   144e3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   144e7:	74 53                	je     1453c <dispatch+0xbc>
		sprint( b256, "dispatch queue remove failed, code %d", status );
   144e9:	83 ec 04             	sub    $0x4,%esp
   144ec:	ff 75 f4             	pushl  -0xc(%ebp)
   144ef:	68 04 b3 01 00       	push   $0x1b304
   144f4:	68 00 02 02 00       	push   $0x20200
   144f9:	e8 f9 e1 ff ff       	call   126f7 <sprint>
   144fe:	83 c4 10             	add    $0x10,%esp
		PANIC( 0, b256 );
   14501:	83 ec 04             	sub    $0x4,%esp
   14504:	68 b9 b1 01 00       	push   $0x1b1b9
   14509:	6a 00                	push   $0x0
   1450b:	68 b4 03 00 00       	push   $0x3b4
   14510:	68 97 b0 01 00       	push   $0x1b097
   14515:	68 0c b6 01 00       	push   $0x1b60c
   1451a:	68 9f b0 01 00       	push   $0x1b09f
   1451f:	68 00 00 02 00       	push   $0x20000
   14524:	e8 ce e1 ff ff       	call   126f7 <sprint>
   14529:	83 c4 20             	add    $0x20,%esp
   1452c:	83 ec 0c             	sub    $0xc,%esp
   1452f:	68 00 00 02 00       	push   $0x20000
   14534:	e8 3e df ff ff       	call   12477 <kpanic>
   14539:	83 c4 10             	add    $0x10,%esp
	}

	// set the process up for success
	current->state = STATE_RUNNING;
   1453c:	a1 14 20 02 00       	mov    0x22014,%eax
   14541:	c7 40 1c 03 00 00 00 	movl   $0x3,0x1c(%eax)
	current->ticks = QUANTUM_STANDARD;
   14548:	a1 14 20 02 00       	mov    0x22014,%eax
   1454d:	c7 40 24 03 00 00 00 	movl   $0x3,0x24(%eax)
}
   14554:	90                   	nop
   14555:	c9                   	leave  
   14556:	c3                   	ret    

00014557 <ctx_dump>:
** Dumps the contents of this process context to the console
**
** @param msg[in]   An optional message to print before the dump
** @param c[in]     The context to dump out
*/
void ctx_dump( const char *msg, register context_t *c ) {
   14557:	55                   	push   %ebp
   14558:	89 e5                	mov    %esp,%ebp
   1455a:	57                   	push   %edi
   1455b:	56                   	push   %esi
   1455c:	53                   	push   %ebx
   1455d:	83 ec 1c             	sub    $0x1c,%esp
   14560:	8b 5d 0c             	mov    0xc(%ebp),%ebx

	// first, the message (if there is one)
	if( msg ) {
   14563:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   14567:	74 0e                	je     14577 <ctx_dump+0x20>
		cio_puts( msg );
   14569:	83 ec 0c             	sub    $0xc,%esp
   1456c:	ff 75 08             	pushl  0x8(%ebp)
   1456f:	e8 39 c9 ff ff       	call   10ead <cio_puts>
   14574:	83 c4 10             	add    $0x10,%esp
	}

	// the pointer
	cio_printf( " @ %08x:\n", (uint32_t) c );
   14577:	89 d8                	mov    %ebx,%eax
   14579:	83 ec 08             	sub    $0x8,%esp
   1457c:	50                   	push   %eax
   1457d:	68 2a b3 01 00       	push   $0x1b32a
   14582:	e8 a0 cf ff ff       	call   11527 <cio_printf>
   14587:	83 c4 10             	add    $0x10,%esp

	// if it's NULL, why did you bother calling me?
	if( c == NULL ) {
   1458a:	85 db                	test   %ebx,%ebx
   1458c:	75 15                	jne    145a3 <ctx_dump+0x4c>
		cio_puts( " NULL???\n" );
   1458e:	83 ec 0c             	sub    $0xc,%esp
   14591:	68 34 b3 01 00       	push   $0x1b334
   14596:	e8 12 c9 ff ff       	call   10ead <cio_puts>
   1459b:	83 c4 10             	add    $0x10,%esp
		return;
   1459e:	e9 9e 00 00 00       	jmp    14641 <ctx_dump+0xea>
	}

	// now, the contents
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
				  c->es & 0xff, c->ds & 0xff, c->cs & 0xff );
   145a3:	8b 43 40             	mov    0x40(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145a6:	0f b6 c0             	movzbl %al,%eax
   145a9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				  c->es & 0xff, c->ds & 0xff, c->cs & 0xff );
   145ac:	8b 43 10             	mov    0x10(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145af:	0f b6 f8             	movzbl %al,%edi
				  c->es & 0xff, c->ds & 0xff, c->cs & 0xff );
   145b2:	8b 43 0c             	mov    0xc(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145b5:	0f b6 f0             	movzbl %al,%esi
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
   145b8:	8b 43 08             	mov    0x8(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145bb:	0f b6 c8             	movzbl %al,%ecx
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
   145be:	8b 43 04             	mov    0x4(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145c1:	0f b6 d0             	movzbl %al,%edx
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
   145c4:	8b 03                	mov    (%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145c6:	0f b6 c0             	movzbl %al,%eax
   145c9:	83 ec 04             	sub    $0x4,%esp
   145cc:	ff 75 e4             	pushl  -0x1c(%ebp)
   145cf:	57                   	push   %edi
   145d0:	56                   	push   %esi
   145d1:	51                   	push   %ecx
   145d2:	52                   	push   %edx
   145d3:	50                   	push   %eax
   145d4:	68 40 b3 01 00       	push   $0x1b340
   145d9:	e8 49 cf ff ff       	call   11527 <cio_printf>
   145de:	83 c4 20             	add    $0x20,%esp
	cio_printf( "  edi %08x esi %08x ebp %08x esp %08x\n",
   145e1:	8b 73 20             	mov    0x20(%ebx),%esi
   145e4:	8b 4b 1c             	mov    0x1c(%ebx),%ecx
   145e7:	8b 53 18             	mov    0x18(%ebx),%edx
   145ea:	8b 43 14             	mov    0x14(%ebx),%eax
   145ed:	83 ec 0c             	sub    $0xc,%esp
   145f0:	56                   	push   %esi
   145f1:	51                   	push   %ecx
   145f2:	52                   	push   %edx
   145f3:	50                   	push   %eax
   145f4:	68 74 b3 01 00       	push   $0x1b374
   145f9:	e8 29 cf ff ff       	call   11527 <cio_printf>
   145fe:	83 c4 20             	add    $0x20,%esp
				  c->edi, c->esi, c->ebp, c->esp );
	cio_printf( "  ebx %08x edx %08x ecx %08x eax %08x\n",
   14601:	8b 73 30             	mov    0x30(%ebx),%esi
   14604:	8b 4b 2c             	mov    0x2c(%ebx),%ecx
   14607:	8b 53 28             	mov    0x28(%ebx),%edx
   1460a:	8b 43 24             	mov    0x24(%ebx),%eax
   1460d:	83 ec 0c             	sub    $0xc,%esp
   14610:	56                   	push   %esi
   14611:	51                   	push   %ecx
   14612:	52                   	push   %edx
   14613:	50                   	push   %eax
   14614:	68 9c b3 01 00       	push   $0x1b39c
   14619:	e8 09 cf ff ff       	call   11527 <cio_printf>
   1461e:	83 c4 20             	add    $0x20,%esp
				  c->ebx, c->edx, c->ecx, c->eax );
	cio_printf( "  vec %08x cod %08x eip %08x efl %08x\n",
   14621:	8b 73 44             	mov    0x44(%ebx),%esi
   14624:	8b 4b 3c             	mov    0x3c(%ebx),%ecx
   14627:	8b 53 38             	mov    0x38(%ebx),%edx
   1462a:	8b 43 34             	mov    0x34(%ebx),%eax
   1462d:	83 ec 0c             	sub    $0xc,%esp
   14630:	56                   	push   %esi
   14631:	51                   	push   %ecx
   14632:	52                   	push   %edx
   14633:	50                   	push   %eax
   14634:	68 c4 b3 01 00       	push   $0x1b3c4
   14639:	e8 e9 ce ff ff       	call   11527 <cio_printf>
   1463e:	83 c4 20             	add    $0x20,%esp
				  c->vector, c->code, c->eip, c->eflags );
}
   14641:	8d 65 f4             	lea    -0xc(%ebp),%esp
   14644:	5b                   	pop    %ebx
   14645:	5e                   	pop    %esi
   14646:	5f                   	pop    %edi
   14647:	5d                   	pop    %ebp
   14648:	c3                   	ret    

00014649 <ctx_dump_all>:
**
** dump the process context for all active processes
**
** @param msg[in]  Optional message to print
*/
void ctx_dump_all( const char *msg ) {
   14649:	55                   	push   %ebp
   1464a:	89 e5                	mov    %esp,%ebp
   1464c:	53                   	push   %ebx
   1464d:	83 ec 14             	sub    $0x14,%esp

	if( msg != NULL ) {
   14650:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   14654:	74 0e                	je     14664 <ctx_dump_all+0x1b>
		cio_puts( msg );
   14656:	83 ec 0c             	sub    $0xc,%esp
   14659:	ff 75 08             	pushl  0x8(%ebp)
   1465c:	e8 4c c8 ff ff       	call   10ead <cio_puts>
   14661:	83 c4 10             	add    $0x10,%esp
	}

	int n = 0;
   14664:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	register pcb_t *pcb = ptable;
   1466b:	bb 20 20 02 00       	mov    $0x22020,%ebx
	for( int i = 0; i < N_PROCS; ++i, ++pcb ) {
   14670:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   14677:	eb 39                	jmp    146b2 <ctx_dump_all+0x69>
		if( pcb->state != STATE_UNUSED ) {
   14679:	8b 43 1c             	mov    0x1c(%ebx),%eax
   1467c:	85 c0                	test   %eax,%eax
   1467e:	74 2b                	je     146ab <ctx_dump_all+0x62>
			++n;
   14680:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
			cio_printf( "%2d(%d): ", n, pcb->pid );
   14684:	8b 43 18             	mov    0x18(%ebx),%eax
   14687:	83 ec 04             	sub    $0x4,%esp
   1468a:	50                   	push   %eax
   1468b:	ff 75 f4             	pushl  -0xc(%ebp)
   1468e:	68 eb b3 01 00       	push   $0x1b3eb
   14693:	e8 8f ce ff ff       	call   11527 <cio_printf>
   14698:	83 c4 10             	add    $0x10,%esp
			ctx_dump( NULL, pcb->context );
   1469b:	8b 03                	mov    (%ebx),%eax
   1469d:	83 ec 08             	sub    $0x8,%esp
   146a0:	50                   	push   %eax
   146a1:	6a 00                	push   $0x0
   146a3:	e8 af fe ff ff       	call   14557 <ctx_dump>
   146a8:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < N_PROCS; ++i, ++pcb ) {
   146ab:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   146af:	83 c3 30             	add    $0x30,%ebx
   146b2:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   146b6:	7e c1                	jle    14679 <ctx_dump_all+0x30>
		}
	}
}
   146b8:	90                   	nop
   146b9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   146bc:	c9                   	leave  
   146bd:	c3                   	ret    

000146be <pcb_dump>:
**
** @param msg[in]  An optional message to print before the dump
** @param pcb[in]  The PCB to dump
** @param all[in]  Dump all the contents?
*/
void pcb_dump( const char *msg, register pcb_t *pcb, bool_t all ) {
   146be:	55                   	push   %ebp
   146bf:	89 e5                	mov    %esp,%ebp
   146c1:	56                   	push   %esi
   146c2:	53                   	push   %ebx
   146c3:	83 ec 10             	sub    $0x10,%esp
   146c6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
   146c9:	8b 45 10             	mov    0x10(%ebp),%eax
   146cc:	88 45 f4             	mov    %al,-0xc(%ebp)

	// first, the message (if there is one)
	if( msg ) {
   146cf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   146d3:	74 0e                	je     146e3 <pcb_dump+0x25>
		cio_puts( msg );
   146d5:	83 ec 0c             	sub    $0xc,%esp
   146d8:	ff 75 08             	pushl  0x8(%ebp)
   146db:	e8 cd c7 ff ff       	call   10ead <cio_puts>
   146e0:	83 c4 10             	add    $0x10,%esp
	}

	// the pointer
	cio_printf( " @ %08x:", (uint32_t) pcb );
   146e3:	89 d8                	mov    %ebx,%eax
   146e5:	83 ec 08             	sub    $0x8,%esp
   146e8:	50                   	push   %eax
   146e9:	68 f5 b3 01 00       	push   $0x1b3f5
   146ee:	e8 34 ce ff ff       	call   11527 <cio_printf>
   146f3:	83 c4 10             	add    $0x10,%esp

	// if it's NULL, why did you bother calling me?
	if( pcb == NULL ) {
   146f6:	85 db                	test   %ebx,%ebx
   146f8:	75 15                	jne    1470f <pcb_dump+0x51>
		cio_puts( " NULL???\n" );
   146fa:	83 ec 0c             	sub    $0xc,%esp
   146fd:	68 34 b3 01 00       	push   $0x1b334
   14702:	e8 a6 c7 ff ff       	call   10ead <cio_puts>
   14707:	83 c4 10             	add    $0x10,%esp
		return;
   1470a:	e9 e7 00 00 00       	jmp    147f6 <pcb_dump+0x138>
	}

	cio_printf( " %d %s", pcb->pid,
			pcb->state >= N_STATES ? "???" : state_str[pcb->state] );
   1470f:	8b 43 1c             	mov    0x1c(%ebx),%eax
	cio_printf( " %d %s", pcb->pid,
   14712:	83 f8 08             	cmp    $0x8,%eax
   14715:	77 0e                	ja     14725 <pcb_dump+0x67>
			pcb->state >= N_STATES ? "???" : state_str[pcb->state] );
   14717:	8b 43 1c             	mov    0x1c(%ebx),%eax
	cio_printf( " %d %s", pcb->pid,
   1471a:	c1 e0 02             	shl    $0x2,%eax
   1471d:	8d 90 40 b0 01 00    	lea    0x1b040(%eax),%edx
   14723:	eb 05                	jmp    1472a <pcb_dump+0x6c>
   14725:	ba fe b3 01 00       	mov    $0x1b3fe,%edx
   1472a:	8b 43 18             	mov    0x18(%ebx),%eax
   1472d:	83 ec 04             	sub    $0x4,%esp
   14730:	52                   	push   %edx
   14731:	50                   	push   %eax
   14732:	68 02 b4 01 00       	push   $0x1b402
   14737:	e8 eb cd ff ff       	call   11527 <cio_printf>
   1473c:	83 c4 10             	add    $0x10,%esp

	if( !all ) {
   1473f:	80 7d f4 00          	cmpb   $0x0,-0xc(%ebp)
   14743:	0f 84 ac 00 00 00    	je     147f5 <pcb_dump+0x137>
		return;
	}

	// now, the rest of the contents
	cio_printf( " %s",
			pcb->priority >= N_PRIOS ? "???" : prio_str[pcb->priority] );
   14749:	8b 43 20             	mov    0x20(%ebx),%eax
	cio_printf( " %s",
   1474c:	83 f8 03             	cmp    $0x3,%eax
   1474f:	77 11                	ja     14762 <pcb_dump+0xa4>
			pcb->priority >= N_PRIOS ? "???" : prio_str[pcb->priority] );
   14751:	8b 53 20             	mov    0x20(%ebx),%edx
	cio_printf( " %s",
   14754:	89 d0                	mov    %edx,%eax
   14756:	c1 e0 02             	shl    $0x2,%eax
   14759:	01 d0                	add    %edx,%eax
   1475b:	05 64 b0 01 00       	add    $0x1b064,%eax
   14760:	eb 05                	jmp    14767 <pcb_dump+0xa9>
   14762:	b8 fe b3 01 00       	mov    $0x1b3fe,%eax
   14767:	83 ec 08             	sub    $0x8,%esp
   1476a:	50                   	push   %eax
   1476b:	68 09 b4 01 00       	push   $0x1b409
   14770:	e8 b2 cd ff ff       	call   11527 <cio_printf>
   14775:	83 c4 10             	add    $0x10,%esp

	cio_printf( " ticks %u xit %d wake %08x\n",
   14778:	8b 4b 10             	mov    0x10(%ebx),%ecx
   1477b:	8b 53 14             	mov    0x14(%ebx),%edx
   1477e:	8b 43 24             	mov    0x24(%ebx),%eax
   14781:	51                   	push   %ecx
   14782:	52                   	push   %edx
   14783:	50                   	push   %eax
   14784:	68 0d b4 01 00       	push   $0x1b40d
   14789:	e8 99 cd ff ff       	call   11527 <cio_printf>
   1478e:	83 c4 10             	add    $0x10,%esp
				pcb->ticks, pcb->exit_status, pcb->wakeup );

	cio_printf( " parent %08x", (uint32_t)pcb->parent );
   14791:	8b 43 0c             	mov    0xc(%ebx),%eax
   14794:	83 ec 08             	sub    $0x8,%esp
   14797:	50                   	push   %eax
   14798:	68 29 b4 01 00       	push   $0x1b429
   1479d:	e8 85 cd ff ff       	call   11527 <cio_printf>
   147a2:	83 c4 10             	add    $0x10,%esp
	if( pcb->parent != NULL ) {
   147a5:	8b 43 0c             	mov    0xc(%ebx),%eax
   147a8:	85 c0                	test   %eax,%eax
   147aa:	74 17                	je     147c3 <pcb_dump+0x105>
		cio_printf( " (%u)", pcb->parent->pid );
   147ac:	8b 43 0c             	mov    0xc(%ebx),%eax
   147af:	8b 40 18             	mov    0x18(%eax),%eax
   147b2:	83 ec 08             	sub    $0x8,%esp
   147b5:	50                   	push   %eax
   147b6:	68 36 b4 01 00       	push   $0x1b436
   147bb:	e8 67 cd ff ff       	call   11527 <cio_printf>
   147c0:	83 c4 10             	add    $0x10,%esp
	}

	cio_printf( " next %08x context %08x stk %08x (%u)",
   147c3:	8b 43 28             	mov    0x28(%ebx),%eax
			(uint32_t) pcb->next, (uint32_t) pcb->context,
			(uint32_t) pcb->stack, pcb->stkpgs );
   147c6:	8b 53 04             	mov    0x4(%ebx),%edx
	cio_printf( " next %08x context %08x stk %08x (%u)",
   147c9:	89 d6                	mov    %edx,%esi
			(uint32_t) pcb->next, (uint32_t) pcb->context,
   147cb:	8b 13                	mov    (%ebx),%edx
	cio_printf( " next %08x context %08x stk %08x (%u)",
   147cd:	89 d1                	mov    %edx,%ecx
			(uint32_t) pcb->next, (uint32_t) pcb->context,
   147cf:	8b 53 08             	mov    0x8(%ebx),%edx
	cio_printf( " next %08x context %08x stk %08x (%u)",
   147d2:	83 ec 0c             	sub    $0xc,%esp
   147d5:	50                   	push   %eax
   147d6:	56                   	push   %esi
   147d7:	51                   	push   %ecx
   147d8:	52                   	push   %edx
   147d9:	68 3c b4 01 00       	push   $0x1b43c
   147de:	e8 44 cd ff ff       	call   11527 <cio_printf>
   147e3:	83 c4 20             	add    $0x20,%esp

	cio_putchar( '\n' );
   147e6:	83 ec 0c             	sub    $0xc,%esp
   147e9:	6a 0a                	push   $0xa
   147eb:	e8 7d c5 ff ff       	call   10d6d <cio_putchar>
   147f0:	83 c4 10             	add    $0x10,%esp
   147f3:	eb 01                	jmp    147f6 <pcb_dump+0x138>
		return;
   147f5:	90                   	nop
}
   147f6:	8d 65 f8             	lea    -0x8(%ebp),%esp
   147f9:	5b                   	pop    %ebx
   147fa:	5e                   	pop    %esi
   147fb:	5d                   	pop    %ebp
   147fc:	c3                   	ret    

000147fd <pcb_queue_dump>:
**
** @param msg[in]       Optional message to print
** @param queue[in]     The queue to dump
** @param contents[in]  Also dump (some) contents?
*/
void pcb_queue_dump( const char *msg, pcb_queue_t queue, bool_t contents ) {
   147fd:	55                   	push   %ebp
   147fe:	89 e5                	mov    %esp,%ebp
   14800:	83 ec 28             	sub    $0x28,%esp
   14803:	8b 45 10             	mov    0x10(%ebp),%eax
   14806:	88 45 e4             	mov    %al,-0x1c(%ebp)

	// report on this queue
	cio_printf( "%s: ", msg );
   14809:	83 ec 08             	sub    $0x8,%esp
   1480c:	ff 75 08             	pushl  0x8(%ebp)
   1480f:	68 62 b4 01 00       	push   $0x1b462
   14814:	e8 0e cd ff ff       	call   11527 <cio_printf>
   14819:	83 c4 10             	add    $0x10,%esp
	if( queue == NULL ) {
   1481c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   14820:	75 15                	jne    14837 <pcb_queue_dump+0x3a>
		cio_puts( "NULL???\n" );
   14822:	83 ec 0c             	sub    $0xc,%esp
   14825:	68 67 b4 01 00       	push   $0x1b467
   1482a:	e8 7e c6 ff ff       	call   10ead <cio_puts>
   1482f:	83 c4 10             	add    $0x10,%esp
		return;
   14832:	e9 d7 00 00 00       	jmp    1490e <pcb_queue_dump+0x111>
	}

	// first, the basic data
	cio_printf( "head %08x tail %08x",
			(uint32_t) queue->head, (uint32_t) queue->tail );
   14837:	8b 45 0c             	mov    0xc(%ebp),%eax
   1483a:	8b 40 04             	mov    0x4(%eax),%eax
	cio_printf( "head %08x tail %08x",
   1483d:	89 c2                	mov    %eax,%edx
			(uint32_t) queue->head, (uint32_t) queue->tail );
   1483f:	8b 45 0c             	mov    0xc(%ebp),%eax
   14842:	8b 00                	mov    (%eax),%eax
	cio_printf( "head %08x tail %08x",
   14844:	83 ec 04             	sub    $0x4,%esp
   14847:	52                   	push   %edx
   14848:	50                   	push   %eax
   14849:	68 70 b4 01 00       	push   $0x1b470
   1484e:	e8 d4 cc ff ff       	call   11527 <cio_printf>
   14853:	83 c4 10             	add    $0x10,%esp

	// next, how the queue is ordered
	cio_printf( " order %s\n",
			queue->order >= N_ORDERINGS ? "????" : ord_str[queue->order] );
   14856:	8b 45 0c             	mov    0xc(%ebp),%eax
   14859:	8b 40 08             	mov    0x8(%eax),%eax
	cio_printf( " order %s\n",
   1485c:	83 f8 03             	cmp    $0x3,%eax
   1485f:	77 14                	ja     14875 <pcb_queue_dump+0x78>
			queue->order >= N_ORDERINGS ? "????" : ord_str[queue->order] );
   14861:	8b 45 0c             	mov    0xc(%ebp),%eax
   14864:	8b 50 08             	mov    0x8(%eax),%edx
	cio_printf( " order %s\n",
   14867:	89 d0                	mov    %edx,%eax
   14869:	c1 e0 02             	shl    $0x2,%eax
   1486c:	01 d0                	add    %edx,%eax
   1486e:	05 78 b0 01 00       	add    $0x1b078,%eax
   14873:	eb 05                	jmp    1487a <pcb_queue_dump+0x7d>
   14875:	b8 84 b4 01 00       	mov    $0x1b484,%eax
   1487a:	83 ec 08             	sub    $0x8,%esp
   1487d:	50                   	push   %eax
   1487e:	68 89 b4 01 00       	push   $0x1b489
   14883:	e8 9f cc ff ff       	call   11527 <cio_printf>
   14888:	83 c4 10             	add    $0x10,%esp

	// if there are members in the queue, dump the first few PIDs
	if( contents && queue->head != NULL ) {
   1488b:	80 7d e4 00          	cmpb   $0x0,-0x1c(%ebp)
   1488f:	74 7d                	je     1490e <pcb_queue_dump+0x111>
   14891:	8b 45 0c             	mov    0xc(%ebp),%eax
   14894:	8b 00                	mov    (%eax),%eax
   14896:	85 c0                	test   %eax,%eax
   14898:	74 74                	je     1490e <pcb_queue_dump+0x111>
		cio_puts( " PIDs: " );
   1489a:	83 ec 0c             	sub    $0xc,%esp
   1489d:	68 94 b4 01 00       	push   $0x1b494
   148a2:	e8 06 c6 ff ff       	call   10ead <cio_puts>
   148a7:	83 c4 10             	add    $0x10,%esp
		pcb_t *tmp = queue->head;
   148aa:	8b 45 0c             	mov    0xc(%ebp),%eax
   148ad:	8b 00                	mov    (%eax),%eax
   148af:	89 45 f4             	mov    %eax,-0xc(%ebp)
		for( int i = 0; i < 5 && tmp != NULL; ++i, tmp = tmp->next ) {
   148b2:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   148b9:	eb 24                	jmp    148df <pcb_queue_dump+0xe2>
			cio_printf( " [%u]", tmp->pid );
   148bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
   148be:	8b 40 18             	mov    0x18(%eax),%eax
   148c1:	83 ec 08             	sub    $0x8,%esp
   148c4:	50                   	push   %eax
   148c5:	68 9c b4 01 00       	push   $0x1b49c
   148ca:	e8 58 cc ff ff       	call   11527 <cio_printf>
   148cf:	83 c4 10             	add    $0x10,%esp
		for( int i = 0; i < 5 && tmp != NULL; ++i, tmp = tmp->next ) {
   148d2:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   148d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
   148d9:	8b 40 08             	mov    0x8(%eax),%eax
   148dc:	89 45 f4             	mov    %eax,-0xc(%ebp)
   148df:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
   148e3:	7f 06                	jg     148eb <pcb_queue_dump+0xee>
   148e5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   148e9:	75 d0                	jne    148bb <pcb_queue_dump+0xbe>
		}

		if( tmp != NULL ) {
   148eb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   148ef:	74 10                	je     14901 <pcb_queue_dump+0x104>
			cio_puts( " ..." );
   148f1:	83 ec 0c             	sub    $0xc,%esp
   148f4:	68 a2 b4 01 00       	push   $0x1b4a2
   148f9:	e8 af c5 ff ff       	call   10ead <cio_puts>
   148fe:	83 c4 10             	add    $0x10,%esp
		}

		cio_putchar( '\n' );
   14901:	83 ec 0c             	sub    $0xc,%esp
   14904:	6a 0a                	push   $0xa
   14906:	e8 62 c4 ff ff       	call   10d6d <cio_putchar>
   1490b:	83 c4 10             	add    $0x10,%esp
	}
}
   1490e:	c9                   	leave  
   1490f:	c3                   	ret    

00014910 <ptable_dump>:
** dump the contents of the "active processes" table
**
** @param msg[in]  Optional message to print
** @param all[in]  Dump all or only part of the relevant data
*/
void ptable_dump( const char *msg, bool_t all ) {
   14910:	55                   	push   %ebp
   14911:	89 e5                	mov    %esp,%ebp
   14913:	53                   	push   %ebx
   14914:	83 ec 24             	sub    $0x24,%esp
   14917:	8b 45 0c             	mov    0xc(%ebp),%eax
   1491a:	88 45 e4             	mov    %al,-0x1c(%ebp)

	if( msg ) {
   1491d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   14921:	74 0e                	je     14931 <ptable_dump+0x21>
		cio_puts( msg );
   14923:	83 ec 0c             	sub    $0xc,%esp
   14926:	ff 75 08             	pushl  0x8(%ebp)
   14929:	e8 7f c5 ff ff       	call   10ead <cio_puts>
   1492e:	83 c4 10             	add    $0x10,%esp
	}
	cio_putchar( ' ' );
   14931:	83 ec 0c             	sub    $0xc,%esp
   14934:	6a 20                	push   $0x20
   14936:	e8 32 c4 ff ff       	call   10d6d <cio_putchar>
   1493b:	83 c4 10             	add    $0x10,%esp

	int used = 0;
   1493e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	int empty = 0;
   14945:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

	register pcb_t *pcb = ptable;
   1494c:	bb 20 20 02 00       	mov    $0x22020,%ebx
	for( int i = 0; i < N_PROCS; ++i ) {
   14951:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   14958:	eb 54                	jmp    149ae <ptable_dump+0x9e>
		if( pcb->state == STATE_UNUSED ) {
   1495a:	8b 43 1c             	mov    0x1c(%ebx),%eax
   1495d:	85 c0                	test   %eax,%eax
   1495f:	75 06                	jne    14967 <ptable_dump+0x57>

			// an empty slot
			++empty;
   14961:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   14965:	eb 43                	jmp    149aa <ptable_dump+0x9a>

		} else {

			// a non-empty slot
			++used;
   14967:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

			// if not dumping everything, add commas if needed
			if( !all && used ) {
   1496b:	80 7d e4 00          	cmpb   $0x0,-0x1c(%ebp)
   1496f:	75 13                	jne    14984 <ptable_dump+0x74>
   14971:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   14975:	74 0d                	je     14984 <ptable_dump+0x74>
				cio_putchar( ',' );
   14977:	83 ec 0c             	sub    $0xc,%esp
   1497a:	6a 2c                	push   $0x2c
   1497c:	e8 ec c3 ff ff       	call   10d6d <cio_putchar>
   14981:	83 c4 10             	add    $0x10,%esp
			}

			// report the table slot #
			cio_printf( " #%d:", i );
   14984:	83 ec 08             	sub    $0x8,%esp
   14987:	ff 75 ec             	pushl  -0x14(%ebp)
   1498a:	68 a7 b4 01 00       	push   $0x1b4a7
   1498f:	e8 93 cb ff ff       	call   11527 <cio_printf>
   14994:	83 c4 10             	add    $0x10,%esp

			// and dump the contents
			pcb_dump( NULL, pcb, all );
   14997:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
   1499b:	83 ec 04             	sub    $0x4,%esp
   1499e:	50                   	push   %eax
   1499f:	53                   	push   %ebx
   149a0:	6a 00                	push   $0x0
   149a2:	e8 17 fd ff ff       	call   146be <pcb_dump>
   149a7:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < N_PROCS; ++i ) {
   149aa:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   149ae:	83 7d ec 18          	cmpl   $0x18,-0x14(%ebp)
   149b2:	7e a6                	jle    1495a <ptable_dump+0x4a>
		}
	}

	// only need this if we're doing one-line output
	if( !all ) {
   149b4:	80 7d e4 00          	cmpb   $0x0,-0x1c(%ebp)
   149b8:	75 0d                	jne    149c7 <ptable_dump+0xb7>
		cio_putchar( '\n' );
   149ba:	83 ec 0c             	sub    $0xc,%esp
   149bd:	6a 0a                	push   $0xa
   149bf:	e8 a9 c3 ff ff       	call   10d6d <cio_putchar>
   149c4:	83 c4 10             	add    $0x10,%esp
	}

	// sanity check - make sure we saw the correct number of table slots
	if( (used + empty) != N_PROCS ) {
   149c7:	8b 55 f4             	mov    -0xc(%ebp),%edx
   149ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
   149cd:	01 d0                	add    %edx,%eax
   149cf:	83 f8 19             	cmp    $0x19,%eax
   149d2:	74 21                	je     149f5 <ptable_dump+0xe5>
		cio_printf( "Table size %d, used %d + empty %d = %d???\n",
   149d4:	8b 55 f4             	mov    -0xc(%ebp),%edx
   149d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
   149da:	01 d0                	add    %edx,%eax
   149dc:	83 ec 0c             	sub    $0xc,%esp
   149df:	50                   	push   %eax
   149e0:	ff 75 f0             	pushl  -0x10(%ebp)
   149e3:	ff 75 f4             	pushl  -0xc(%ebp)
   149e6:	6a 19                	push   $0x19
   149e8:	68 b0 b4 01 00       	push   $0x1b4b0
   149ed:	e8 35 cb ff ff       	call   11527 <cio_printf>
   149f2:	83 c4 20             	add    $0x20,%esp
					  N_PROCS, used, empty, used + empty );
	}
}
   149f5:	90                   	nop
   149f6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   149f9:	c9                   	leave  
   149fa:	c3                   	ret    

000149fb <ptable_dump_counts>:
** Name:    ptable_dump_counts
**
** Prints basic information about the process table (number of
** entries, number with each process state, etc.).
*/
void ptable_dump_counts( void ) {
   149fb:	55                   	push   %ebp
   149fc:	89 e5                	mov    %esp,%ebp
   149fe:	57                   	push   %edi
   149ff:	83 ec 34             	sub    $0x34,%esp
	uint_t nstate[N_STATES] = { 0 };
   14a02:	8d 55 c8             	lea    -0x38(%ebp),%edx
   14a05:	b8 00 00 00 00       	mov    $0x0,%eax
   14a0a:	b9 09 00 00 00       	mov    $0x9,%ecx
   14a0f:	89 d7                	mov    %edx,%edi
   14a11:	f3 ab                	rep stos %eax,%es:(%edi)
	uint_t unknown = 0;
   14a13:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	int n = 0;
   14a1a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	pcb_t *ptr = ptable;
   14a21:	c7 45 ec 20 20 02 00 	movl   $0x22020,-0x14(%ebp)
	while( n < N_PROCS ) {
   14a28:	eb 2a                	jmp    14a54 <ptable_dump_counts+0x59>
		if( ptr->state < 0 || ptr->state >= N_STATES ) {
   14a2a:	8b 45 ec             	mov    -0x14(%ebp),%eax
   14a2d:	8b 40 1c             	mov    0x1c(%eax),%eax
   14a30:	83 f8 08             	cmp    $0x8,%eax
   14a33:	76 06                	jbe    14a3b <ptable_dump_counts+0x40>
			++unknown;
   14a35:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   14a39:	eb 11                	jmp    14a4c <ptable_dump_counts+0x51>
		} else {
			++nstate[ptr->state];
   14a3b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   14a3e:	8b 40 1c             	mov    0x1c(%eax),%eax
   14a41:	8b 54 85 c8          	mov    -0x38(%ebp,%eax,4),%edx
   14a45:	83 c2 01             	add    $0x1,%edx
   14a48:	89 54 85 c8          	mov    %edx,-0x38(%ebp,%eax,4)
		}
		++n;
   14a4c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
		++ptr;
   14a50:	83 45 ec 30          	addl   $0x30,-0x14(%ebp)
	while( n < N_PROCS ) {
   14a54:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   14a58:	7e d0                	jle    14a2a <ptable_dump_counts+0x2f>
	}

	cio_printf( "Ptable: %u ***", unknown );
   14a5a:	83 ec 08             	sub    $0x8,%esp
   14a5d:	ff 75 f4             	pushl  -0xc(%ebp)
   14a60:	68 db b4 01 00       	push   $0x1b4db
   14a65:	e8 bd ca ff ff       	call   11527 <cio_printf>
   14a6a:	83 c4 10             	add    $0x10,%esp
	for( n = 0; n < N_STATES; ++n ) {
   14a6d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   14a74:	eb 34                	jmp    14aaa <ptable_dump_counts+0xaf>
		if( nstate[n] ) {
   14a76:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14a79:	8b 44 85 c8          	mov    -0x38(%ebp,%eax,4),%eax
   14a7d:	85 c0                	test   %eax,%eax
   14a7f:	74 25                	je     14aa6 <ptable_dump_counts+0xab>
			cio_printf( " %u %s", nstate[n],
					state_str[n] != NULL ? state_str[n] : "???" );
   14a81:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14a84:	c1 e0 02             	shl    $0x2,%eax
   14a87:	8d 90 40 b0 01 00    	lea    0x1b040(%eax),%edx
			cio_printf( " %u %s", nstate[n],
   14a8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14a90:	8b 44 85 c8          	mov    -0x38(%ebp,%eax,4),%eax
   14a94:	83 ec 04             	sub    $0x4,%esp
   14a97:	52                   	push   %edx
   14a98:	50                   	push   %eax
   14a99:	68 ea b4 01 00       	push   $0x1b4ea
   14a9e:	e8 84 ca ff ff       	call   11527 <cio_printf>
   14aa3:	83 c4 10             	add    $0x10,%esp
	for( n = 0; n < N_STATES; ++n ) {
   14aa6:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   14aaa:	83 7d f0 08          	cmpl   $0x8,-0x10(%ebp)
   14aae:	7e c6                	jle    14a76 <ptable_dump_counts+0x7b>
		}
	}
	cio_putchar( '\n' );
   14ab0:	83 ec 0c             	sub    $0xc,%esp
   14ab3:	6a 0a                	push   $0xa
   14ab5:	e8 b3 c2 ff ff       	call   10d6d <cio_putchar>
   14aba:	83 c4 10             	add    $0x10,%esp
}
   14abd:	90                   	nop
   14abe:	8b 7d fc             	mov    -0x4(%ebp),%edi
   14ac1:	c9                   	leave  
   14ac2:	c3                   	ret    

00014ac3 <sio_isr>:
** events (as described by the SIO controller).
**
** @param vector   The interrupt vector number for this interrupt
** @param ecode    The error code associated with this interrupt
*/
static void sio_isr( int vector, int ecode ) {
   14ac3:	55                   	push   %ebp
   14ac4:	89 e5                	mov    %esp,%ebp
   14ac6:	83 ec 58             	sub    $0x58,%esp
   14ac9:	c7 45 e8 fa 03 00 00 	movl   $0x3fa,-0x18(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14ad0:	8b 45 e8             	mov    -0x18(%ebp),%eax
   14ad3:	89 c2                	mov    %eax,%edx
   14ad5:	ec                   	in     (%dx),%al
   14ad6:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
   14ad9:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
	//

	for(;;) {

		// get the "pending event" indicator
		int iir = inb( UA4_IIR ) & UA4_IIR_INT_PRI_MASK;
   14add:	0f b6 c0             	movzbl %al,%eax
   14ae0:	83 e0 0f             	and    $0xf,%eax
   14ae3:	89 45 f0             	mov    %eax,-0x10(%ebp)

		// process this event
		switch( iir ) {
   14ae6:	83 7d f0 0c          	cmpl   $0xc,-0x10(%ebp)
   14aea:	0f 87 95 02 00 00    	ja     14d85 <sio_isr+0x2c2>
   14af0:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14af3:	c1 e0 02             	shl    $0x2,%eax
   14af6:	05 dc b6 01 00       	add    $0x1b6dc,%eax
   14afb:	8b 00                	mov    (%eax),%eax
   14afd:	ff e0                	jmp    *%eax
   14aff:	c7 45 e0 fd 03 00 00 	movl   $0x3fd,-0x20(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14b06:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14b09:	89 c2                	mov    %eax,%edx
   14b0b:	ec                   	in     (%dx),%al
   14b0c:	88 45 df             	mov    %al,-0x21(%ebp)
	return data;
   14b0f:	0f b6 45 df          	movzbl -0x21(%ebp),%eax

		case UA4_IIR_LINE_STATUS:
			// shouldn't happen, but just in case....
			cio_printf( "** SIO int, LSR = %02x\n", inb(UA4_LSR) );
   14b13:	0f b6 c0             	movzbl %al,%eax
   14b16:	83 ec 08             	sub    $0x8,%esp
   14b19:	50                   	push   %eax
   14b1a:	68 18 b6 01 00       	push   $0x1b618
   14b1f:	e8 03 ca ff ff       	call   11527 <cio_printf>
   14b24:	83 c4 10             	add    $0x10,%esp
			break;
   14b27:	e9 b6 02 00 00       	jmp    14de2 <sio_isr+0x31f>
   14b2c:	c7 45 d8 f8 03 00 00 	movl   $0x3f8,-0x28(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14b33:	8b 45 d8             	mov    -0x28(%ebp),%eax
   14b36:	89 c2                	mov    %eax,%edx
   14b38:	ec                   	in     (%dx),%al
   14b39:	88 45 d7             	mov    %al,-0x29(%ebp)
	return data;
   14b3c:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
		case UA4_IIR_RX:
#if TRACING_SIO_ISR
	cio_puts( " RX" );
#endif
			// get the character
			ch = inb( UA4_RXD );
   14b40:	0f b6 c0             	movzbl %al,%eax
   14b43:	89 45 f4             	mov    %eax,-0xc(%ebp)
			if( ch == '\r' ) {    // map CR to LF
   14b46:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
   14b4a:	75 07                	jne    14b53 <sio_isr+0x90>
				ch = '\n';
   14b4c:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
			// If there is a waiting process, this must be
			// the first input character; give it to that
			// process and awaken the process.
			//

			if( !QEMPTY(QNAME) ) {
   14b53:	a1 04 20 02 00       	mov    0x22004,%eax
   14b58:	83 ec 0c             	sub    $0xc,%esp
   14b5b:	50                   	push   %eax
   14b5c:	e8 cd f2 ff ff       	call   13e2e <pcb_queue_empty>
   14b61:	83 c4 10             	add    $0x10,%esp
   14b64:	84 c0                	test   %al,%al
   14b66:	0f 85 d0 00 00 00    	jne    14c3c <sio_isr+0x179>
				PCBTYPE *pcb;

				QDEQUE( QNAME, pcb );
   14b6c:	a1 04 20 02 00       	mov    0x22004,%eax
   14b71:	83 ec 08             	sub    $0x8,%esp
   14b74:	8d 55 b0             	lea    -0x50(%ebp),%edx
   14b77:	52                   	push   %edx
   14b78:	50                   	push   %eax
   14b79:	e8 4e f5 ff ff       	call   140cc <pcb_queue_remove>
   14b7e:	83 c4 10             	add    $0x10,%esp
   14b81:	85 c0                	test   %eax,%eax
   14b83:	74 3b                	je     14bc0 <sio_isr+0xfd>
   14b85:	83 ec 04             	sub    $0x4,%esp
   14b88:	68 30 b6 01 00       	push   $0x1b630
   14b8d:	6a 00                	push   $0x0
   14b8f:	68 ac 00 00 00       	push   $0xac
   14b94:	68 68 b6 01 00       	push   $0x1b668
   14b99:	68 6c b7 01 00       	push   $0x1b76c
   14b9e:	68 6e b6 01 00       	push   $0x1b66e
   14ba3:	68 00 00 02 00       	push   $0x20000
   14ba8:	e8 4a db ff ff       	call   126f7 <sprint>
   14bad:	83 c4 20             	add    $0x20,%esp
   14bb0:	83 ec 0c             	sub    $0xc,%esp
   14bb3:	68 00 00 02 00       	push   $0x20000
   14bb8:	e8 ba d8 ff ff       	call   12477 <kpanic>
   14bbd:	83 c4 10             	add    $0x10,%esp
				// make sure we got a non-NULL result
				assert( pcb );
   14bc0:	8b 45 b0             	mov    -0x50(%ebp),%eax
   14bc3:	85 c0                	test   %eax,%eax
   14bc5:	75 3b                	jne    14c02 <sio_isr+0x13f>
   14bc7:	83 ec 04             	sub    $0x4,%esp
   14bca:	68 84 b6 01 00       	push   $0x1b684
   14bcf:	6a 00                	push   $0x0
   14bd1:	68 ae 00 00 00       	push   $0xae
   14bd6:	68 68 b6 01 00       	push   $0x1b668
   14bdb:	68 6c b7 01 00       	push   $0x1b76c
   14be0:	68 6e b6 01 00       	push   $0x1b66e
   14be5:	68 00 00 02 00       	push   $0x20000
   14bea:	e8 08 db ff ff       	call   126f7 <sprint>
   14bef:	83 c4 20             	add    $0x20,%esp
   14bf2:	83 ec 0c             	sub    $0xc,%esp
   14bf5:	68 00 00 02 00       	push   $0x20000
   14bfa:	e8 78 d8 ff ff       	call   12477 <kpanic>
   14bff:	83 c4 10             	add    $0x10,%esp

				// return char via arg #2 and count in EAX
				char *buf = (char *) ARG(pcb,2);
   14c02:	8b 45 b0             	mov    -0x50(%ebp),%eax
   14c05:	8b 00                	mov    (%eax),%eax
   14c07:	83 c0 48             	add    $0x48,%eax
   14c0a:	83 c0 08             	add    $0x8,%eax
   14c0d:	8b 00                	mov    (%eax),%eax
   14c0f:	89 45 ec             	mov    %eax,-0x14(%ebp)
				*buf = ch & 0xff;
   14c12:	8b 45 f4             	mov    -0xc(%ebp),%eax
   14c15:	89 c2                	mov    %eax,%edx
   14c17:	8b 45 ec             	mov    -0x14(%ebp),%eax
   14c1a:	88 10                	mov    %dl,(%eax)
				RET(pcb) = 1;
   14c1c:	8b 45 b0             	mov    -0x50(%ebp),%eax
   14c1f:	8b 00                	mov    (%eax),%eax
   14c21:	c7 40 30 01 00 00 00 	movl   $0x1,0x30(%eax)
				SCHED( pcb );
   14c28:	8b 45 b0             	mov    -0x50(%ebp),%eax
   14c2b:	83 ec 0c             	sub    $0xc,%esp
   14c2e:	50                   	push   %eax
   14c2f:	e8 8b f7 ff ff       	call   143bf <schedule>
   14c34:	83 c4 10             	add    $0x10,%esp
				}

#ifdef QNAME
			}
#endif /* QNAME */
			break;
   14c37:	e9 a5 01 00 00       	jmp    14de1 <sio_isr+0x31e>
				if( incount < BUF_SIZE ) {
   14c3c:	a1 88 e9 01 00       	mov    0x1e988,%eax
   14c41:	3d ff 07 00 00       	cmp    $0x7ff,%eax
   14c46:	0f 87 95 01 00 00    	ja     14de1 <sio_isr+0x31e>
					*inlast++ = ch;
   14c4c:	a1 80 e9 01 00       	mov    0x1e980,%eax
   14c51:	8d 50 01             	lea    0x1(%eax),%edx
   14c54:	89 15 80 e9 01 00    	mov    %edx,0x1e980
   14c5a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   14c5d:	88 10                	mov    %dl,(%eax)
					++incount;
   14c5f:	a1 88 e9 01 00       	mov    0x1e988,%eax
   14c64:	83 c0 01             	add    $0x1,%eax
   14c67:	a3 88 e9 01 00       	mov    %eax,0x1e988
			break;
   14c6c:	e9 70 01 00 00       	jmp    14de1 <sio_isr+0x31e>
   14c71:	c7 45 d0 f8 03 00 00 	movl   $0x3f8,-0x30(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14c78:	8b 45 d0             	mov    -0x30(%ebp),%eax
   14c7b:	89 c2                	mov    %eax,%edx
   14c7d:	ec                   	in     (%dx),%al
   14c7e:	88 45 cf             	mov    %al,-0x31(%ebp)
	return data;
   14c81:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax

		case UA5_IIR_RX_FIFO:
			// shouldn't happen, but just in case....
			ch = inb( UA4_RXD );
   14c85:	0f b6 c0             	movzbl %al,%eax
   14c88:	89 45 f4             	mov    %eax,-0xc(%ebp)
			cio_printf( "** SIO FIFO timeout, RXD = %02x\n", ch );
   14c8b:	83 ec 08             	sub    $0x8,%esp
   14c8e:	ff 75 f4             	pushl  -0xc(%ebp)
   14c91:	68 88 b6 01 00       	push   $0x1b688
   14c96:	e8 8c c8 ff ff       	call   11527 <cio_printf>
   14c9b:	83 c4 10             	add    $0x10,%esp
			break;
   14c9e:	e9 3f 01 00 00       	jmp    14de2 <sio_isr+0x31f>
		case UA4_IIR_TX:
#if TRACING_SIO_ISR
	cio_puts( " TX" );
#endif
			// if there is another character, send it
			if( sending && outcount > 0 ) {
   14ca3:	a1 ac f1 01 00       	mov    0x1f1ac,%eax
   14ca8:	85 c0                	test   %eax,%eax
   14caa:	74 5d                	je     14d09 <sio_isr+0x246>
   14cac:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   14cb1:	85 c0                	test   %eax,%eax
   14cb3:	74 54                	je     14d09 <sio_isr+0x246>
#if TRACING_SIO_ISR
	cio_printf( " ch %02x", *outnext );
#endif
				outb( UA4_TXD, *outnext );
   14cb5:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   14cba:	0f b6 00             	movzbl (%eax),%eax
   14cbd:	0f b6 c0             	movzbl %al,%eax
   14cc0:	c7 45 c8 f8 03 00 00 	movl   $0x3f8,-0x38(%ebp)
   14cc7:	88 45 c7             	mov    %al,-0x39(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   14cca:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   14cce:	8b 55 c8             	mov    -0x38(%ebp),%edx
   14cd1:	ee                   	out    %al,(%dx)
				++outnext;
   14cd2:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   14cd7:	83 c0 01             	add    $0x1,%eax
   14cda:	a3 a4 f1 01 00       	mov    %eax,0x1f1a4
				// wrap around if necessary
				if( outnext >= (outbuffer + BUF_SIZE) ) {
   14cdf:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   14ce4:	ba a0 f1 01 00       	mov    $0x1f1a0,%edx
   14ce9:	39 d0                	cmp    %edx,%eax
   14ceb:	72 0a                	jb     14cf7 <sio_isr+0x234>
					outnext = outbuffer;
   14ced:	c7 05 a4 f1 01 00 a0 	movl   $0x1e9a0,0x1f1a4
   14cf4:	e9 01 00 
				}
				--outcount;
   14cf7:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   14cfc:	83 e8 01             	sub    $0x1,%eax
   14cff:	a3 a8 f1 01 00       	mov    %eax,0x1f1a8
				outlast = outnext = outbuffer;
				sending = 0;
				// disable TX interrupts
				sio_disable( SIO_TX );
			}
			break;
   14d04:	e9 d9 00 00 00       	jmp    14de2 <sio_isr+0x31f>
				outcount = 0;
   14d09:	c7 05 a8 f1 01 00 00 	movl   $0x0,0x1f1a8
   14d10:	00 00 00 
				outlast = outnext = outbuffer;
   14d13:	c7 05 a4 f1 01 00 a0 	movl   $0x1e9a0,0x1f1a4
   14d1a:	e9 01 00 
   14d1d:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   14d22:	a3 a0 f1 01 00       	mov    %eax,0x1f1a0
				sending = 0;
   14d27:	c7 05 ac f1 01 00 00 	movl   $0x0,0x1f1ac
   14d2e:	00 00 00 
				sio_disable( SIO_TX );
   14d31:	83 ec 0c             	sub    $0xc,%esp
   14d34:	6a 01                	push   $0x1
   14d36:	e8 99 02 00 00       	call   14fd4 <sio_disable>
   14d3b:	83 c4 10             	add    $0x10,%esp
			break;
   14d3e:	e9 9f 00 00 00       	jmp    14de2 <sio_isr+0x31f>
   14d43:	c7 45 c0 20 00 00 00 	movl   $0x20,-0x40(%ebp)
   14d4a:	c6 45 bf 20          	movb   $0x20,-0x41(%ebp)
   14d4e:	0f b6 45 bf          	movzbl -0x41(%ebp),%eax
   14d52:	8b 55 c0             	mov    -0x40(%ebp),%edx
   14d55:	ee                   	out    %al,(%dx)
#if TRACING_SIO_ISR
	cio_puts( " EOI\n" );
#endif
			// nothing to do - tell the PIC we're done
			outb( PIC1_CMD, PIC_EOI );
			return;
   14d56:	e9 8c 00 00 00       	jmp    14de7 <sio_isr+0x324>
   14d5b:	c7 45 b8 fe 03 00 00 	movl   $0x3fe,-0x48(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14d62:	8b 45 b8             	mov    -0x48(%ebp),%eax
   14d65:	89 c2                	mov    %eax,%edx
   14d67:	ec                   	in     (%dx),%al
   14d68:	88 45 b7             	mov    %al,-0x49(%ebp)
	return data;
   14d6b:	0f b6 45 b7          	movzbl -0x49(%ebp),%eax

		case UA4_IIR_MODEM_STATUS:
			// shouldn't happen, but just in case....
			cio_printf( "** SIO int, MSR = %02x\n", inb(UA4_MSR) );
   14d6f:	0f b6 c0             	movzbl %al,%eax
   14d72:	83 ec 08             	sub    $0x8,%esp
   14d75:	50                   	push   %eax
   14d76:	68 a9 b6 01 00       	push   $0x1b6a9
   14d7b:	e8 a7 c7 ff ff       	call   11527 <cio_printf>
   14d80:	83 c4 10             	add    $0x10,%esp
			break;
   14d83:	eb 5d                	jmp    14de2 <sio_isr+0x31f>

		default:
			// uh-oh....
			sprint( b256, "sio isr: IIR %02x\n", ((uint32_t) iir) & 0xff );
   14d85:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14d88:	0f b6 c0             	movzbl %al,%eax
   14d8b:	83 ec 04             	sub    $0x4,%esp
   14d8e:	50                   	push   %eax
   14d8f:	68 c1 b6 01 00       	push   $0x1b6c1
   14d94:	68 00 02 02 00       	push   $0x20200
   14d99:	e8 59 d9 ff ff       	call   126f7 <sprint>
   14d9e:	83 c4 10             	add    $0x10,%esp
			PANIC( 0, b256 );
   14da1:	83 ec 04             	sub    $0x4,%esp
   14da4:	68 d4 b6 01 00       	push   $0x1b6d4
   14da9:	6a 00                	push   $0x0
   14dab:	68 fe 00 00 00       	push   $0xfe
   14db0:	68 68 b6 01 00       	push   $0x1b668
   14db5:	68 6c b7 01 00       	push   $0x1b76c
   14dba:	68 6e b6 01 00       	push   $0x1b66e
   14dbf:	68 00 00 02 00       	push   $0x20000
   14dc4:	e8 2e d9 ff ff       	call   126f7 <sprint>
   14dc9:	83 c4 20             	add    $0x20,%esp
   14dcc:	83 ec 0c             	sub    $0xc,%esp
   14dcf:	68 00 00 02 00       	push   $0x20000
   14dd4:	e8 9e d6 ff ff       	call   12477 <kpanic>
   14dd9:	83 c4 10             	add    $0x10,%esp
   14ddc:	e9 e8 fc ff ff       	jmp    14ac9 <sio_isr+0x6>
			break;
   14de1:	90                   	nop
	for(;;) {
   14de2:	e9 e2 fc ff ff       	jmp    14ac9 <sio_isr+0x6>
	
	}

	// should never reach this point!
	assert( false );
}
   14de7:	c9                   	leave  
   14de8:	c3                   	ret    

00014de9 <sio_init>:
/**
** sio_init()
**
** Initialize the UART chip.
*/
void sio_init( void ) {
   14de9:	55                   	push   %ebp
   14dea:	89 e5                	mov    %esp,%ebp
   14dec:	83 ec 68             	sub    $0x68,%esp

#if TRACING_INIT
	cio_puts( " Sio" );
   14def:	83 ec 0c             	sub    $0xc,%esp
   14df2:	68 10 b7 01 00       	push   $0x1b710
   14df7:	e8 b1 c0 ff ff       	call   10ead <cio_puts>
   14dfc:	83 c4 10             	add    $0x10,%esp

	/*
	** Initialize SIO variables.
	*/

	memclr( (void *) inbuffer, sizeof(inbuffer) );
   14dff:	83 ec 08             	sub    $0x8,%esp
   14e02:	68 00 08 00 00       	push   $0x800
   14e07:	68 80 e1 01 00       	push   $0x1e180
   14e0c:	e8 63 d7 ff ff       	call   12574 <memclr>
   14e11:	83 c4 10             	add    $0x10,%esp
	inlast = innext = inbuffer;
   14e14:	c7 05 84 e9 01 00 80 	movl   $0x1e180,0x1e984
   14e1b:	e1 01 00 
   14e1e:	a1 84 e9 01 00       	mov    0x1e984,%eax
   14e23:	a3 80 e9 01 00       	mov    %eax,0x1e980
	incount = 0;
   14e28:	c7 05 88 e9 01 00 00 	movl   $0x0,0x1e988
   14e2f:	00 00 00 

	memclr( (void *) outbuffer, sizeof(outbuffer) );
   14e32:	83 ec 08             	sub    $0x8,%esp
   14e35:	68 00 08 00 00       	push   $0x800
   14e3a:	68 a0 e9 01 00       	push   $0x1e9a0
   14e3f:	e8 30 d7 ff ff       	call   12574 <memclr>
   14e44:	83 c4 10             	add    $0x10,%esp
	outlast = outnext = outbuffer;
   14e47:	c7 05 a4 f1 01 00 a0 	movl   $0x1e9a0,0x1f1a4
   14e4e:	e9 01 00 
   14e51:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   14e56:	a3 a0 f1 01 00       	mov    %eax,0x1f1a0
	outcount = 0;
   14e5b:	c7 05 a8 f1 01 00 00 	movl   $0x0,0x1f1a8
   14e62:	00 00 00 
	sending = 0;
   14e65:	c7 05 ac f1 01 00 00 	movl   $0x0,0x1f1ac
   14e6c:	00 00 00 
   14e6f:	c7 45 a4 fa 03 00 00 	movl   $0x3fa,-0x5c(%ebp)
   14e76:	c6 45 a3 20          	movb   $0x20,-0x5d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   14e7a:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
   14e7e:	8b 55 a4             	mov    -0x5c(%ebp),%edx
   14e81:	ee                   	out    %al,(%dx)
   14e82:	c7 45 ac fa 03 00 00 	movl   $0x3fa,-0x54(%ebp)
   14e89:	c6 45 ab 00          	movb   $0x0,-0x55(%ebp)
   14e8d:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
   14e91:	8b 55 ac             	mov    -0x54(%ebp),%edx
   14e94:	ee                   	out    %al,(%dx)
   14e95:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
   14e9c:	c6 45 b3 01          	movb   $0x1,-0x4d(%ebp)
   14ea0:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
   14ea4:	8b 55 b4             	mov    -0x4c(%ebp),%edx
   14ea7:	ee                   	out    %al,(%dx)
   14ea8:	c7 45 bc fa 03 00 00 	movl   $0x3fa,-0x44(%ebp)
   14eaf:	c6 45 bb 03          	movb   $0x3,-0x45(%ebp)
   14eb3:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
   14eb7:	8b 55 bc             	mov    -0x44(%ebp),%edx
   14eba:	ee                   	out    %al,(%dx)
   14ebb:	c7 45 c4 fa 03 00 00 	movl   $0x3fa,-0x3c(%ebp)
   14ec2:	c6 45 c3 07          	movb   $0x7,-0x3d(%ebp)
   14ec6:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
   14eca:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   14ecd:	ee                   	out    %al,(%dx)
   14ece:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
   14ed5:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
   14ed9:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
   14edd:	8b 55 cc             	mov    -0x34(%ebp),%edx
   14ee0:	ee                   	out    %al,(%dx)
	** note that we leave them disabled; sio_enable() must be
	** called to switch them back on
	*/

	outb( UA4_IER, 0 );
	ier = 0;
   14ee1:	c6 05 b0 f1 01 00 00 	movb   $0x0,0x1f1b0
   14ee8:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
   14eef:	c6 45 d3 80          	movb   $0x80,-0x2d(%ebp)
   14ef3:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
   14ef7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
   14efa:	ee                   	out    %al,(%dx)
   14efb:	c7 45 dc f8 03 00 00 	movl   $0x3f8,-0x24(%ebp)
   14f02:	c6 45 db 0c          	movb   $0xc,-0x25(%ebp)
   14f06:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   14f0a:	8b 55 dc             	mov    -0x24(%ebp),%edx
   14f0d:	ee                   	out    %al,(%dx)
   14f0e:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
   14f15:	c6 45 e3 00          	movb   $0x0,-0x1d(%ebp)
   14f19:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
   14f1d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   14f20:	ee                   	out    %al,(%dx)
   14f21:	c7 45 ec fb 03 00 00 	movl   $0x3fb,-0x14(%ebp)
   14f28:	c6 45 eb 03          	movb   $0x3,-0x15(%ebp)
   14f2c:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   14f30:	8b 55 ec             	mov    -0x14(%ebp),%edx
   14f33:	ee                   	out    %al,(%dx)
   14f34:	c7 45 f4 fc 03 00 00 	movl   $0x3fc,-0xc(%ebp)
   14f3b:	c6 45 f3 0b          	movb   $0xb,-0xd(%ebp)
   14f3f:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   14f43:	8b 55 f4             	mov    -0xc(%ebp),%edx
   14f46:	ee                   	out    %al,(%dx)

	/*
	** Install our ISR
	*/

	install_isr( VEC_COM1, sio_isr );
   14f47:	83 ec 08             	sub    $0x8,%esp
   14f4a:	68 c3 4a 01 00       	push   $0x14ac3
   14f4f:	6a 24                	push   $0x24
   14f51:	e8 20 08 00 00       	call   15776 <install_isr>
   14f56:	83 c4 10             	add    $0x10,%esp
}
   14f59:	90                   	nop
   14f5a:	c9                   	leave  
   14f5b:	c3                   	ret    

00014f5c <sio_enable>:
**
** @param which   Bit mask indicating which interrupt(s) to enable
**
** @return the prior IER setting
*/
uint8_t sio_enable( uint8_t which ) {
   14f5c:	55                   	push   %ebp
   14f5d:	89 e5                	mov    %esp,%ebp
   14f5f:	83 ec 14             	sub    $0x14,%esp
   14f62:	8b 45 08             	mov    0x8(%ebp),%eax
   14f65:	88 45 ec             	mov    %al,-0x14(%ebp)
	uint8_t old;

	// remember the current status

	old = ier;
   14f68:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14f6f:	88 45 ff             	mov    %al,-0x1(%ebp)

	// figure out what to enable

	if( which & SIO_TX ) {
   14f72:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   14f76:	83 e0 01             	and    $0x1,%eax
   14f79:	85 c0                	test   %eax,%eax
   14f7b:	74 0f                	je     14f8c <sio_enable+0x30>
		ier |= UA4_IER_TX_IE;
   14f7d:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14f84:	83 c8 02             	or     $0x2,%eax
   14f87:	a2 b0 f1 01 00       	mov    %al,0x1f1b0
	}

	if( which & SIO_RX ) {
   14f8c:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   14f90:	83 e0 02             	and    $0x2,%eax
   14f93:	85 c0                	test   %eax,%eax
   14f95:	74 0f                	je     14fa6 <sio_enable+0x4a>
		ier |= UA4_IER_RX_IE;
   14f97:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14f9e:	83 c8 01             	or     $0x1,%eax
   14fa1:	a2 b0 f1 01 00       	mov    %al,0x1f1b0
	}

	// if there was a change, make it

	if( old != ier ) {
   14fa6:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14fad:	38 45 ff             	cmp    %al,-0x1(%ebp)
   14fb0:	74 1c                	je     14fce <sio_enable+0x72>
		outb( UA4_IER, ier );
   14fb2:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14fb9:	0f b6 c0             	movzbl %al,%eax
   14fbc:	c7 45 f8 f9 03 00 00 	movl   $0x3f9,-0x8(%ebp)
   14fc3:	88 45 f7             	mov    %al,-0x9(%ebp)
   14fc6:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
   14fca:	8b 55 f8             	mov    -0x8(%ebp),%edx
   14fcd:	ee                   	out    %al,(%dx)
	}

	// return the prior settings

	return( old );
   14fce:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
   14fd2:	c9                   	leave  
   14fd3:	c3                   	ret    

00014fd4 <sio_disable>:
**
** @param which   Bit mask indicating which interrupt(s) to disable
**
** @return the prior IER setting
*/
uint8_t sio_disable( uint8_t which ) {
   14fd4:	55                   	push   %ebp
   14fd5:	89 e5                	mov    %esp,%ebp
   14fd7:	83 ec 14             	sub    $0x14,%esp
   14fda:	8b 45 08             	mov    0x8(%ebp),%eax
   14fdd:	88 45 ec             	mov    %al,-0x14(%ebp)
	uint8_t old;

	// remember the current status

	old = ier;
   14fe0:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14fe7:	88 45 ff             	mov    %al,-0x1(%ebp)

	// figure out what to disable

	if( which & SIO_TX ) {
   14fea:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   14fee:	83 e0 01             	and    $0x1,%eax
   14ff1:	85 c0                	test   %eax,%eax
   14ff3:	74 0f                	je     15004 <sio_disable+0x30>
		ier &= ~UA4_IER_TX_IE;
   14ff5:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14ffc:	83 e0 fd             	and    $0xfffffffd,%eax
   14fff:	a2 b0 f1 01 00       	mov    %al,0x1f1b0
	}

	if( which & SIO_RX ) {
   15004:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   15008:	83 e0 02             	and    $0x2,%eax
   1500b:	85 c0                	test   %eax,%eax
   1500d:	74 0f                	je     1501e <sio_disable+0x4a>
		ier &= ~UA4_IER_RX_IE;
   1500f:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   15016:	83 e0 fe             	and    $0xfffffffe,%eax
   15019:	a2 b0 f1 01 00       	mov    %al,0x1f1b0
	}

	// if there was a change, make it

	if( old != ier ) {
   1501e:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   15025:	38 45 ff             	cmp    %al,-0x1(%ebp)
   15028:	74 1c                	je     15046 <sio_disable+0x72>
		outb( UA4_IER, ier );
   1502a:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   15031:	0f b6 c0             	movzbl %al,%eax
   15034:	c7 45 f8 f9 03 00 00 	movl   $0x3f9,-0x8(%ebp)
   1503b:	88 45 f7             	mov    %al,-0x9(%ebp)
   1503e:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
   15042:	8b 55 f8             	mov    -0x8(%ebp),%edx
   15045:	ee                   	out    %al,(%dx)
	}

	// return the prior settings

	return( old );
   15046:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
   1504a:	c9                   	leave  
   1504b:	c3                   	ret    

0001504c <sio_flush>:
**
** Flush the SIO input and/or output.
**
** @param which  Bit mask indicating which queue(s) to flush.
*/
void sio_flush( uint8_t which ) {
   1504c:	55                   	push   %ebp
   1504d:	89 e5                	mov    %esp,%ebp
   1504f:	83 ec 24             	sub    $0x24,%esp
   15052:	8b 45 08             	mov    0x8(%ebp),%eax
   15055:	88 45 dc             	mov    %al,-0x24(%ebp)

	if( (which & SIO_RX) != 0 ) {
   15058:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
   1505c:	83 e0 02             	and    $0x2,%eax
   1505f:	85 c0                	test   %eax,%eax
   15061:	74 69                	je     150cc <sio_flush+0x80>
		// empty the queue
		incount = 0;
   15063:	c7 05 88 e9 01 00 00 	movl   $0x0,0x1e988
   1506a:	00 00 00 
		inlast = innext = inbuffer;
   1506d:	c7 05 84 e9 01 00 80 	movl   $0x1e180,0x1e984
   15074:	e1 01 00 
   15077:	a1 84 e9 01 00       	mov    0x1e984,%eax
   1507c:	a3 80 e9 01 00       	mov    %eax,0x1e980
   15081:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   15088:	8b 45 f8             	mov    -0x8(%ebp),%eax
   1508b:	89 c2                	mov    %eax,%edx
   1508d:	ec                   	in     (%dx),%al
   1508e:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
   15091:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax

		// discard any characters in the receiver FIFO
		uint8_t lsr = inb( UA4_LSR );
   15095:	88 45 ff             	mov    %al,-0x1(%ebp)
		while( (lsr & UA4_LSR_RXDA) != 0 ) {
   15098:	eb 27                	jmp    150c1 <sio_flush+0x75>
   1509a:	c7 45 e8 f8 03 00 00 	movl   $0x3f8,-0x18(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   150a1:	8b 45 e8             	mov    -0x18(%ebp),%eax
   150a4:	89 c2                	mov    %eax,%edx
   150a6:	ec                   	in     (%dx),%al
   150a7:	88 45 e7             	mov    %al,-0x19(%ebp)
   150aa:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
   150b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
   150b4:	89 c2                	mov    %eax,%edx
   150b6:	ec                   	in     (%dx),%al
   150b7:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
   150ba:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
			(void) inb( UA4_RXD );
			lsr = inb( UA4_LSR );
   150be:	88 45 ff             	mov    %al,-0x1(%ebp)
		while( (lsr & UA4_LSR_RXDA) != 0 ) {
   150c1:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
   150c5:	83 e0 01             	and    $0x1,%eax
   150c8:	85 c0                	test   %eax,%eax
   150ca:	75 ce                	jne    1509a <sio_flush+0x4e>
		}
	}

	if( (which & SIO_TX) != 0 ) {
   150cc:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
   150d0:	83 e0 01             	and    $0x1,%eax
   150d3:	85 c0                	test   %eax,%eax
   150d5:	74 28                	je     150ff <sio_flush+0xb3>
		// empty the queue
		outcount = 0;
   150d7:	c7 05 a8 f1 01 00 00 	movl   $0x0,0x1f1a8
   150de:	00 00 00 
		outlast = outnext = outbuffer;
   150e1:	c7 05 a4 f1 01 00 a0 	movl   $0x1e9a0,0x1f1a4
   150e8:	e9 01 00 
   150eb:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   150f0:	a3 a0 f1 01 00       	mov    %eax,0x1f1a0

		// terminate any in-progress send operation
		sending = 0;
   150f5:	c7 05 ac f1 01 00 00 	movl   $0x0,0x1f1ac
   150fc:	00 00 00 
	}
}
   150ff:	90                   	nop
   15100:	c9                   	leave  
   15101:	c3                   	ret    

00015102 <sio_inq_length>:
**
** usage:    int num = sio_inq_length()
**
** @return the count of characters still in the input queue
*/
int sio_inq_length( void ) {
   15102:	55                   	push   %ebp
   15103:	89 e5                	mov    %esp,%ebp
	return( incount );
   15105:	a1 88 e9 01 00       	mov    0x1e988,%eax
}
   1510a:	5d                   	pop    %ebp
   1510b:	c3                   	ret    

0001510c <sio_readc>:
**
** usage:    int ch = sio_readc()
**
** @return the next character, or -1 if no character is available
*/
int sio_readc( void ) {
   1510c:	55                   	push   %ebp
   1510d:	89 e5                	mov    %esp,%ebp
   1510f:	83 ec 10             	sub    $0x10,%esp
	int ch;

	// assume there is no character available
	ch = -1;
   15112:	c7 45 fc ff ff ff ff 	movl   $0xffffffff,-0x4(%ebp)

	// 
	// If there is a character, return it
	//

	if( incount > 0 ) {
   15119:	a1 88 e9 01 00       	mov    0x1e988,%eax
   1511e:	85 c0                	test   %eax,%eax
   15120:	74 46                	je     15168 <sio_readc+0x5c>

		// take it out of the input buffer
		ch = ((int)(*innext++)) & 0xff;
   15122:	a1 84 e9 01 00       	mov    0x1e984,%eax
   15127:	8d 50 01             	lea    0x1(%eax),%edx
   1512a:	89 15 84 e9 01 00    	mov    %edx,0x1e984
   15130:	0f b6 00             	movzbl (%eax),%eax
   15133:	0f be c0             	movsbl %al,%eax
   15136:	25 ff 00 00 00       	and    $0xff,%eax
   1513b:	89 45 fc             	mov    %eax,-0x4(%ebp)
		--incount;
   1513e:	a1 88 e9 01 00       	mov    0x1e988,%eax
   15143:	83 e8 01             	sub    $0x1,%eax
   15146:	a3 88 e9 01 00       	mov    %eax,0x1e988

		// reset the buffer variables if this was the last one
		if( incount < 1 ) {
   1514b:	a1 88 e9 01 00       	mov    0x1e988,%eax
   15150:	85 c0                	test   %eax,%eax
   15152:	75 14                	jne    15168 <sio_readc+0x5c>
			inlast = innext = inbuffer;
   15154:	c7 05 84 e9 01 00 80 	movl   $0x1e180,0x1e984
   1515b:	e1 01 00 
   1515e:	a1 84 e9 01 00       	mov    0x1e984,%eax
   15163:	a3 80 e9 01 00       	mov    %eax,0x1e980
		}

	}

	return( ch );
   15168:	8b 45 fc             	mov    -0x4(%ebp),%eax

}
   1516b:	c9                   	leave  
   1516c:	c3                   	ret    

0001516d <sio_read>:
** @param length  Length of the buffer
**
** @return the number of bytes copied, or 0 if no characters were available
*/

int sio_read( char *buf, int length ) {
   1516d:	55                   	push   %ebp
   1516e:	89 e5                	mov    %esp,%ebp
   15170:	83 ec 10             	sub    $0x10,%esp
	char *ptr = buf;
   15173:	8b 45 08             	mov    0x8(%ebp),%eax
   15176:	89 45 fc             	mov    %eax,-0x4(%ebp)
	int copied = 0;
   15179:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// if there are no characters, just return 0

	if( incount < 1 ) {
   15180:	a1 88 e9 01 00       	mov    0x1e988,%eax
   15185:	85 c0                	test   %eax,%eax
   15187:	75 4c                	jne    151d5 <sio_read+0x68>
		return( 0 );
   15189:	b8 00 00 00 00       	mov    $0x0,%eax
   1518e:	eb 76                	jmp    15206 <sio_read+0x99>
	// We have characters.  Copy as many of them into the user
	// buffer as will fit.
	//

	while( incount > 0 && copied < length ) {
		*ptr++ = *innext++ & 0xff;
   15190:	8b 15 84 e9 01 00    	mov    0x1e984,%edx
   15196:	8d 42 01             	lea    0x1(%edx),%eax
   15199:	a3 84 e9 01 00       	mov    %eax,0x1e984
   1519e:	8b 45 fc             	mov    -0x4(%ebp),%eax
   151a1:	8d 48 01             	lea    0x1(%eax),%ecx
   151a4:	89 4d fc             	mov    %ecx,-0x4(%ebp)
   151a7:	0f b6 12             	movzbl (%edx),%edx
   151aa:	88 10                	mov    %dl,(%eax)
		if( innext > (inbuffer + BUF_SIZE) ) {
   151ac:	a1 84 e9 01 00       	mov    0x1e984,%eax
   151b1:	ba 80 e9 01 00       	mov    $0x1e980,%edx
   151b6:	39 d0                	cmp    %edx,%eax
   151b8:	76 0a                	jbe    151c4 <sio_read+0x57>
			innext = inbuffer;
   151ba:	c7 05 84 e9 01 00 80 	movl   $0x1e180,0x1e984
   151c1:	e1 01 00 
		}
		--incount;
   151c4:	a1 88 e9 01 00       	mov    0x1e988,%eax
   151c9:	83 e8 01             	sub    $0x1,%eax
   151cc:	a3 88 e9 01 00       	mov    %eax,0x1e988
		++copied;
   151d1:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
	while( incount > 0 && copied < length ) {
   151d5:	a1 88 e9 01 00       	mov    0x1e988,%eax
   151da:	85 c0                	test   %eax,%eax
   151dc:	74 08                	je     151e6 <sio_read+0x79>
   151de:	8b 45 f8             	mov    -0x8(%ebp),%eax
   151e1:	3b 45 0c             	cmp    0xc(%ebp),%eax
   151e4:	7c aa                	jl     15190 <sio_read+0x23>
	}

	// reset the input buffer if necessary

	if( incount < 1 ) {
   151e6:	a1 88 e9 01 00       	mov    0x1e988,%eax
   151eb:	85 c0                	test   %eax,%eax
   151ed:	75 14                	jne    15203 <sio_read+0x96>
		inlast = innext = inbuffer;
   151ef:	c7 05 84 e9 01 00 80 	movl   $0x1e180,0x1e984
   151f6:	e1 01 00 
   151f9:	a1 84 e9 01 00       	mov    0x1e984,%eax
   151fe:	a3 80 e9 01 00       	mov    %eax,0x1e980
	}

	// return the copy count

	return( copied );
   15203:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
   15206:	c9                   	leave  
   15207:	c3                   	ret    

00015208 <sio_writec>:
**
** usage:    sio_writec( int ch )
**
** @param ch   Character to be written (in the low-order 8 bits)
*/
void sio_writec( int ch ){
   15208:	55                   	push   %ebp
   15209:	89 e5                	mov    %esp,%ebp
   1520b:	83 ec 18             	sub    $0x18,%esp

	//
	// Must do LF -> CRLF mapping
	//

	if( ch == '\n' ) {
   1520e:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
   15212:	75 0d                	jne    15221 <sio_writec+0x19>
		sio_writec( '\r' );
   15214:	83 ec 0c             	sub    $0xc,%esp
   15217:	6a 0d                	push   $0xd
   15219:	e8 ea ff ff ff       	call   15208 <sio_writec>
   1521e:	83 c4 10             	add    $0x10,%esp

	//
	// If we're currently transmitting, just add this to the buffer
	//

	if( sending ) {
   15221:	a1 ac f1 01 00       	mov    0x1f1ac,%eax
   15226:	85 c0                	test   %eax,%eax
   15228:	74 22                	je     1524c <sio_writec+0x44>
		*outlast++ = ch;
   1522a:	a1 a0 f1 01 00       	mov    0x1f1a0,%eax
   1522f:	8d 50 01             	lea    0x1(%eax),%edx
   15232:	89 15 a0 f1 01 00    	mov    %edx,0x1f1a0
   15238:	8b 55 08             	mov    0x8(%ebp),%edx
   1523b:	88 10                	mov    %dl,(%eax)
		++outcount;
   1523d:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   15242:	83 c0 01             	add    $0x1,%eax
   15245:	a3 a8 f1 01 00       	mov    %eax,0x1f1a8
		return;
   1524a:	eb 2f                	jmp    1527b <sio_writec+0x73>

	//
	// Not sending - must prime the pump
	//

	sending = 1;
   1524c:	c7 05 ac f1 01 00 01 	movl   $0x1,0x1f1ac
   15253:	00 00 00 
	outb( UA4_TXD, ch );
   15256:	8b 45 08             	mov    0x8(%ebp),%eax
   15259:	0f b6 c0             	movzbl %al,%eax
   1525c:	c7 45 f4 f8 03 00 00 	movl   $0x3f8,-0xc(%ebp)
   15263:	88 45 f3             	mov    %al,-0xd(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   15266:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   1526a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1526d:	ee                   	out    %al,(%dx)

	// Also must enable transmitter interrupts

	sio_enable( SIO_TX );
   1526e:	83 ec 0c             	sub    $0xc,%esp
   15271:	6a 01                	push   $0x1
   15273:	e8 e4 fc ff ff       	call   14f5c <sio_enable>
   15278:	83 c4 10             	add    $0x10,%esp

}
   1527b:	c9                   	leave  
   1527c:	c3                   	ret    

0001527d <sio_write>:
** @param buffer   Buffer containing characters to write
** @param length   Number of characters to write
**
** @return the number of characters copied into the SIO output buffer
*/
int sio_write( const char *buffer, int length ) {
   1527d:	55                   	push   %ebp
   1527e:	89 e5                	mov    %esp,%ebp
   15280:	83 ec 18             	sub    $0x18,%esp
	int first = *buffer;
   15283:	8b 45 08             	mov    0x8(%ebp),%eax
   15286:	0f b6 00             	movzbl (%eax),%eax
   15289:	0f be c0             	movsbl %al,%eax
   1528c:	89 45 ec             	mov    %eax,-0x14(%ebp)
	const char *ptr = buffer;
   1528f:	8b 45 08             	mov    0x8(%ebp),%eax
   15292:	89 45 f4             	mov    %eax,-0xc(%ebp)
	int copied = 0;
   15295:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	// the characters to the output buffer; else, we want
	// to append all but the first character, and then use
	// sio_writec() to send the first one out.
	//

	if( !sending ) {
   1529c:	a1 ac f1 01 00       	mov    0x1f1ac,%eax
   152a1:	85 c0                	test   %eax,%eax
   152a3:	75 4f                	jne    152f4 <sio_write+0x77>
		ptr += 1;
   152a5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
		copied++;
   152a9:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
	}

	while( copied < length && outcount < BUF_SIZE ) {
   152ad:	eb 45                	jmp    152f4 <sio_write+0x77>
		*outlast++ = *ptr++;
   152af:	8b 55 f4             	mov    -0xc(%ebp),%edx
   152b2:	8d 42 01             	lea    0x1(%edx),%eax
   152b5:	89 45 f4             	mov    %eax,-0xc(%ebp)
   152b8:	a1 a0 f1 01 00       	mov    0x1f1a0,%eax
   152bd:	8d 48 01             	lea    0x1(%eax),%ecx
   152c0:	89 0d a0 f1 01 00    	mov    %ecx,0x1f1a0
   152c6:	0f b6 12             	movzbl (%edx),%edx
   152c9:	88 10                	mov    %dl,(%eax)
		// wrap around if necessary
		if( outlast >= (outbuffer + BUF_SIZE) ) {
   152cb:	a1 a0 f1 01 00       	mov    0x1f1a0,%eax
   152d0:	ba a0 f1 01 00       	mov    $0x1f1a0,%edx
   152d5:	39 d0                	cmp    %edx,%eax
   152d7:	72 0a                	jb     152e3 <sio_write+0x66>
			outlast = outbuffer;
   152d9:	c7 05 a0 f1 01 00 a0 	movl   $0x1e9a0,0x1f1a0
   152e0:	e9 01 00 
		}
		++outcount;
   152e3:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   152e8:	83 c0 01             	add    $0x1,%eax
   152eb:	a3 a8 f1 01 00       	mov    %eax,0x1f1a8
		++copied;
   152f0:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
	while( copied < length && outcount < BUF_SIZE ) {
   152f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
   152f7:	3b 45 0c             	cmp    0xc(%ebp),%eax
   152fa:	7d 0c                	jge    15308 <sio_write+0x8b>
   152fc:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   15301:	3d ff 07 00 00       	cmp    $0x7ff,%eax
   15306:	76 a7                	jbe    152af <sio_write+0x32>
	// We use sio_writec() to send out the first character,
	// as it will correctly set all the other necessary
	// variables for us.
	//

	if( !sending ) {
   15308:	a1 ac f1 01 00       	mov    0x1f1ac,%eax
   1530d:	85 c0                	test   %eax,%eax
   1530f:	75 0e                	jne    1531f <sio_write+0xa2>
		sio_writec( first );
   15311:	83 ec 0c             	sub    $0xc,%esp
   15314:	ff 75 ec             	pushl  -0x14(%ebp)
   15317:	e8 ec fe ff ff       	call   15208 <sio_writec>
   1531c:	83 c4 10             	add    $0x10,%esp
	}

	// Return the transfer count


	return( copied );
   1531f:	8b 45 f0             	mov    -0x10(%ebp),%eax

}
   15322:	c9                   	leave  
   15323:	c3                   	ret    

00015324 <sio_puts>:
**
** @param buffer  The buffer containing a NUL-terminated string
**
** @return the count of bytes transferred
*/
int sio_puts( const char *buffer ) {
   15324:	55                   	push   %ebp
   15325:	89 e5                	mov    %esp,%ebp
   15327:	83 ec 18             	sub    $0x18,%esp
	int n;  // must be outside the loop so we can return it

	n = SLENGTH( buffer );
   1532a:	83 ec 0c             	sub    $0xc,%esp
   1532d:	ff 75 08             	pushl  0x8(%ebp)
   15330:	e8 3f d7 ff ff       	call   12a74 <strlen>
   15335:	83 c4 10             	add    $0x10,%esp
   15338:	89 45 f4             	mov    %eax,-0xc(%ebp)
	sio_write( buffer, n );
   1533b:	83 ec 08             	sub    $0x8,%esp
   1533e:	ff 75 f4             	pushl  -0xc(%ebp)
   15341:	ff 75 08             	pushl  0x8(%ebp)
   15344:	e8 34 ff ff ff       	call   1527d <sio_write>
   15349:	83 c4 10             	add    $0x10,%esp

	return( n );
   1534c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   1534f:	c9                   	leave  
   15350:	c3                   	ret    

00015351 <sio_dump>:
** @param full   Boolean indicating whether or not a "full" dump
**               is being requested (which includes the contents
**               of the queues)
*/

void sio_dump( bool_t full ) {
   15351:	55                   	push   %ebp
   15352:	89 e5                	mov    %esp,%ebp
   15354:	57                   	push   %edi
   15355:	56                   	push   %esi
   15356:	53                   	push   %ebx
   15357:	83 ec 2c             	sub    $0x2c,%esp
   1535a:	8b 45 08             	mov    0x8(%ebp),%eax
   1535d:	88 45 d4             	mov    %al,-0x2c(%ebp)
	int n;
	char *ptr;

	// dump basic info into the status region

	cio_printf_at( 48, 0,
   15360:	8b 0d a8 f1 01 00    	mov    0x1f1a8,%ecx
   15366:	8b 15 88 e9 01 00    	mov    0x1e988,%edx
		"SIO: IER %02x (%c%c%c) in %d ot %d",
			((uint32_t)ier) & 0xff, sending ? '*' : '.',
			(ier & UA4_IER_TX_IE) ? 'T' : 't',
			(ier & UA4_IER_RX_IE) ? 'R' : 'r',
   1536c:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   15373:	0f b6 c0             	movzbl %al,%eax
   15376:	83 e0 01             	and    $0x1,%eax
	cio_printf_at( 48, 0,
   15379:	85 c0                	test   %eax,%eax
   1537b:	74 07                	je     15384 <sio_dump+0x33>
   1537d:	bf 52 00 00 00       	mov    $0x52,%edi
   15382:	eb 05                	jmp    15389 <sio_dump+0x38>
   15384:	bf 72 00 00 00       	mov    $0x72,%edi
			(ier & UA4_IER_TX_IE) ? 'T' : 't',
   15389:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   15390:	0f b6 c0             	movzbl %al,%eax
   15393:	83 e0 02             	and    $0x2,%eax
	cio_printf_at( 48, 0,
   15396:	85 c0                	test   %eax,%eax
   15398:	74 07                	je     153a1 <sio_dump+0x50>
   1539a:	be 54 00 00 00       	mov    $0x54,%esi
   1539f:	eb 05                	jmp    153a6 <sio_dump+0x55>
   153a1:	be 74 00 00 00       	mov    $0x74,%esi
			((uint32_t)ier) & 0xff, sending ? '*' : '.',
   153a6:	a1 ac f1 01 00       	mov    0x1f1ac,%eax
	cio_printf_at( 48, 0,
   153ab:	85 c0                	test   %eax,%eax
   153ad:	74 07                	je     153b6 <sio_dump+0x65>
   153af:	bb 2a 00 00 00       	mov    $0x2a,%ebx
   153b4:	eb 05                	jmp    153bb <sio_dump+0x6a>
   153b6:	bb 2e 00 00 00       	mov    $0x2e,%ebx
   153bb:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   153c2:	0f b6 c0             	movzbl %al,%eax
   153c5:	83 ec 0c             	sub    $0xc,%esp
   153c8:	51                   	push   %ecx
   153c9:	52                   	push   %edx
   153ca:	57                   	push   %edi
   153cb:	56                   	push   %esi
   153cc:	53                   	push   %ebx
   153cd:	50                   	push   %eax
   153ce:	68 18 b7 01 00       	push   $0x1b718
   153d3:	6a 00                	push   $0x0
   153d5:	6a 30                	push   $0x30
   153d7:	e8 2b c1 ff ff       	call   11507 <cio_printf_at>
   153dc:	83 c4 30             	add    $0x30,%esp
			incount, outcount );

	// if we're not doing a full dump, stop now

	if( !full ) {
   153df:	80 7d d4 00          	cmpb   $0x0,-0x2c(%ebp)
   153e3:	0f 84 dc 00 00 00    	je     154c5 <sio_dump+0x174>
	}

	// also want the queue contents, but we'll
	// dump them into the scrolling region

	if( incount ) {
   153e9:	a1 88 e9 01 00       	mov    0x1e988,%eax
   153ee:	85 c0                	test   %eax,%eax
   153f0:	74 5c                	je     1544e <sio_dump+0xfd>
		cio_puts( "SIO input queue: \"" );
   153f2:	83 ec 0c             	sub    $0xc,%esp
   153f5:	68 3b b7 01 00       	push   $0x1b73b
   153fa:	e8 ae ba ff ff       	call   10ead <cio_puts>
   153ff:	83 c4 10             	add    $0x10,%esp
		ptr = innext; 
   15402:	a1 84 e9 01 00       	mov    0x1e984,%eax
   15407:	89 45 e0             	mov    %eax,-0x20(%ebp)
		for( n = 0; n < incount; ++n ) {
   1540a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   15411:	eb 1f                	jmp    15432 <sio_dump+0xe1>
			put_char_or_code( *ptr++ );
   15413:	8b 45 e0             	mov    -0x20(%ebp),%eax
   15416:	8d 50 01             	lea    0x1(%eax),%edx
   15419:	89 55 e0             	mov    %edx,-0x20(%ebp)
   1541c:	0f b6 00             	movzbl (%eax),%eax
   1541f:	0f be c0             	movsbl %al,%eax
   15422:	83 ec 0c             	sub    $0xc,%esp
   15425:	50                   	push   %eax
   15426:	e8 55 cf ff ff       	call   12380 <put_char_or_code>
   1542b:	83 c4 10             	add    $0x10,%esp
		for( n = 0; n < incount; ++n ) {
   1542e:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   15432:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   15435:	a1 88 e9 01 00       	mov    0x1e988,%eax
   1543a:	39 c2                	cmp    %eax,%edx
   1543c:	72 d5                	jb     15413 <sio_dump+0xc2>
		}
		cio_puts( "\"\n" );
   1543e:	83 ec 0c             	sub    $0xc,%esp
   15441:	68 4e b7 01 00       	push   $0x1b74e
   15446:	e8 62 ba ff ff       	call   10ead <cio_puts>
   1544b:	83 c4 10             	add    $0x10,%esp
	}

	if( outcount ) {
   1544e:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   15453:	85 c0                	test   %eax,%eax
   15455:	74 6f                	je     154c6 <sio_dump+0x175>
		cio_puts( "SIO output queue: \"" );
   15457:	83 ec 0c             	sub    $0xc,%esp
   1545a:	68 51 b7 01 00       	push   $0x1b751
   1545f:	e8 49 ba ff ff       	call   10ead <cio_puts>
   15464:	83 c4 10             	add    $0x10,%esp
		cio_puts( " ot: \"" );
   15467:	83 ec 0c             	sub    $0xc,%esp
   1546a:	68 65 b7 01 00       	push   $0x1b765
   1546f:	e8 39 ba ff ff       	call   10ead <cio_puts>
   15474:	83 c4 10             	add    $0x10,%esp
		ptr = outnext; 
   15477:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   1547c:	89 45 e0             	mov    %eax,-0x20(%ebp)
		for( n = 0; n < outcount; ++n )  {
   1547f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   15486:	eb 1f                	jmp    154a7 <sio_dump+0x156>
			put_char_or_code( *ptr++ );
   15488:	8b 45 e0             	mov    -0x20(%ebp),%eax
   1548b:	8d 50 01             	lea    0x1(%eax),%edx
   1548e:	89 55 e0             	mov    %edx,-0x20(%ebp)
   15491:	0f b6 00             	movzbl (%eax),%eax
   15494:	0f be c0             	movsbl %al,%eax
   15497:	83 ec 0c             	sub    $0xc,%esp
   1549a:	50                   	push   %eax
   1549b:	e8 e0 ce ff ff       	call   12380 <put_char_or_code>
   154a0:	83 c4 10             	add    $0x10,%esp
		for( n = 0; n < outcount; ++n )  {
   154a3:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   154a7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   154aa:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   154af:	39 c2                	cmp    %eax,%edx
   154b1:	72 d5                	jb     15488 <sio_dump+0x137>
		}
		cio_puts( "\"\n" );
   154b3:	83 ec 0c             	sub    $0xc,%esp
   154b6:	68 4e b7 01 00       	push   $0x1b74e
   154bb:	e8 ed b9 ff ff       	call   10ead <cio_puts>
   154c0:	83 c4 10             	add    $0x10,%esp
   154c3:	eb 01                	jmp    154c6 <sio_dump+0x175>
		return;
   154c5:	90                   	nop
	}
}
   154c6:	8d 65 f4             	lea    -0xc(%ebp),%esp
   154c9:	5b                   	pop    %ebx
   154ca:	5e                   	pop    %esi
   154cb:	5f                   	pop    %edi
   154cc:	5d                   	pop    %ebp
   154cd:	c3                   	ret    

000154ce <unexpected_handler>:
** @param vector   vector number for the interrupt that occurred
** @param code     error code, or a dummy value
**
** Does not return.
*/
static void unexpected_handler( int vector, int code ) {
   154ce:	55                   	push   %ebp
   154cf:	89 e5                	mov    %esp,%ebp
   154d1:	83 ec 08             	sub    $0x8,%esp
#ifdef RPT_INT_UNEXP
	cio_printf( "\n** UNEXPECTED vector %d code %d\n", vector, code );
   154d4:	83 ec 04             	sub    $0x4,%esp
   154d7:	ff 75 0c             	pushl  0xc(%ebp)
   154da:	ff 75 08             	pushl  0x8(%ebp)
   154dd:	68 74 b7 01 00       	push   $0x1b774
   154e2:	e8 40 c0 ff ff       	call   11527 <cio_printf>
   154e7:	83 c4 10             	add    $0x10,%esp
#endif
	panic( "Unexpected interrupt" );
   154ea:	83 ec 0c             	sub    $0xc,%esp
   154ed:	68 96 b7 01 00       	push   $0x1b796
   154f2:	e8 50 02 00 00       	call   15747 <panic>
   154f7:	83 c4 10             	add    $0x10,%esp
}
   154fa:	90                   	nop
   154fb:	c9                   	leave  
   154fc:	c3                   	ret    

000154fd <default_handler>:
** handling (yet).  We just reset the PIC and return.
**
** @param vector   vector number for the interrupt that occurred
** @param code     error code, or a dummy value
*/
static void default_handler( int vector, int code ) {
   154fd:	55                   	push   %ebp
   154fe:	89 e5                	mov    %esp,%ebp
   15500:	83 ec 18             	sub    $0x18,%esp
#ifdef RPT_INT_UNEXP
	cio_printf( "\n** vector %d code %d\n", vector, code );
   15503:	83 ec 04             	sub    $0x4,%esp
   15506:	ff 75 0c             	pushl  0xc(%ebp)
   15509:	ff 75 08             	pushl  0x8(%ebp)
   1550c:	68 ab b7 01 00       	push   $0x1b7ab
   15511:	e8 11 c0 ff ff       	call   11527 <cio_printf>
   15516:	83 c4 10             	add    $0x10,%esp
#endif
	if( vector >= 0x20 && vector < 0x30 ) {
   15519:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
   1551d:	7e 34                	jle    15553 <default_handler+0x56>
   1551f:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
   15523:	7f 2e                	jg     15553 <default_handler+0x56>
		if( vector > 0x27 ) {
   15525:	83 7d 08 27          	cmpl   $0x27,0x8(%ebp)
   15529:	7e 13                	jle    1553e <default_handler+0x41>
   1552b:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
   15532:	c6 45 f3 20          	movb   $0x20,-0xd(%ebp)
   15536:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   1553a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1553d:	ee                   	out    %al,(%dx)
   1553e:	c7 45 ec 20 00 00 00 	movl   $0x20,-0x14(%ebp)
   15545:	c6 45 eb 20          	movb   $0x20,-0x15(%ebp)
   15549:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   1554d:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15550:	ee                   	out    %al,(%dx)
			// must also ACK the secondary PIC
			outb( PIC2_CMD, PIC_EOI );
		}
		outb( PIC1_CMD, PIC_EOI );
   15551:	eb 10                	jmp    15563 <default_handler+0x66>
		/*
		** All the "expected" interrupts will be handled by the
		** code above.  If we get down here, the isr table may
		** have been corrupted.  Print a message and don't return.
		*/
		panic( "Unexpected \"expected\" interrupt!" );
   15553:	83 ec 0c             	sub    $0xc,%esp
   15556:	68 c4 b7 01 00       	push   $0x1b7c4
   1555b:	e8 e7 01 00 00       	call   15747 <panic>
   15560:	83 c4 10             	add    $0x10,%esp
	}
}
   15563:	90                   	nop
   15564:	c9                   	leave  
   15565:	c3                   	ret    

00015566 <mystery_handler>:
** source.
**
** @param vector   vector number for the interrupt that occurred
** @param code     error code, or a dummy value
*/
static void mystery_handler( int vector, int code ) {
   15566:	55                   	push   %ebp
   15567:	89 e5                	mov    %esp,%ebp
   15569:	83 ec 18             	sub    $0x18,%esp
#if defined(RPT_INT_MYSTERY) || defined(RPT_INT_UNEXP)
	cio_printf( "\nMystery interrupt!\nVector=0x%02x, code=%d\n",
   1556c:	83 ec 04             	sub    $0x4,%esp
   1556f:	ff 75 0c             	pushl  0xc(%ebp)
   15572:	ff 75 08             	pushl  0x8(%ebp)
   15575:	68 e8 b7 01 00       	push   $0x1b7e8
   1557a:	e8 a8 bf ff ff       	call   11527 <cio_printf>
   1557f:	83 c4 10             	add    $0x10,%esp
   15582:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
   15589:	c6 45 f3 20          	movb   $0x20,-0xd(%ebp)
   1558d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   15591:	8b 55 f4             	mov    -0xc(%ebp),%edx
   15594:	ee                   	out    %al,(%dx)
		  vector, code );
#endif
	outb( PIC1_CMD, PIC_EOI );
}
   15595:	90                   	nop
   15596:	c9                   	leave  
   15597:	c3                   	ret    

00015598 <init_pic>:
/**
** init_pic
**
** Initialize the 8259 Programmable Interrupt Controller.
*/
static void init_pic( void ) {
   15598:	55                   	push   %ebp
   15599:	89 e5                	mov    %esp,%ebp
   1559b:	83 ec 50             	sub    $0x50,%esp
   1559e:	c7 45 b4 20 00 00 00 	movl   $0x20,-0x4c(%ebp)
   155a5:	c6 45 b3 11          	movb   $0x11,-0x4d(%ebp)
   155a9:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
   155ad:	8b 55 b4             	mov    -0x4c(%ebp),%edx
   155b0:	ee                   	out    %al,(%dx)
   155b1:	c7 45 bc a0 00 00 00 	movl   $0xa0,-0x44(%ebp)
   155b8:	c6 45 bb 11          	movb   $0x11,-0x45(%ebp)
   155bc:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
   155c0:	8b 55 bc             	mov    -0x44(%ebp),%edx
   155c3:	ee                   	out    %al,(%dx)
   155c4:	c7 45 c4 21 00 00 00 	movl   $0x21,-0x3c(%ebp)
   155cb:	c6 45 c3 20          	movb   $0x20,-0x3d(%ebp)
   155cf:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
   155d3:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   155d6:	ee                   	out    %al,(%dx)
   155d7:	c7 45 cc a1 00 00 00 	movl   $0xa1,-0x34(%ebp)
   155de:	c6 45 cb 28          	movb   $0x28,-0x35(%ebp)
   155e2:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
   155e6:	8b 55 cc             	mov    -0x34(%ebp),%edx
   155e9:	ee                   	out    %al,(%dx)
   155ea:	c7 45 d4 21 00 00 00 	movl   $0x21,-0x2c(%ebp)
   155f1:	c6 45 d3 04          	movb   $0x4,-0x2d(%ebp)
   155f5:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
   155f9:	8b 55 d4             	mov    -0x2c(%ebp),%edx
   155fc:	ee                   	out    %al,(%dx)
   155fd:	c7 45 dc a1 00 00 00 	movl   $0xa1,-0x24(%ebp)
   15604:	c6 45 db 02          	movb   $0x2,-0x25(%ebp)
   15608:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   1560c:	8b 55 dc             	mov    -0x24(%ebp),%edx
   1560f:	ee                   	out    %al,(%dx)
   15610:	c7 45 e4 21 00 00 00 	movl   $0x21,-0x1c(%ebp)
   15617:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
   1561b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
   1561f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   15622:	ee                   	out    %al,(%dx)
   15623:	c7 45 ec a1 00 00 00 	movl   $0xa1,-0x14(%ebp)
   1562a:	c6 45 eb 01          	movb   $0x1,-0x15(%ebp)
   1562e:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   15632:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15635:	ee                   	out    %al,(%dx)
   15636:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
   1563d:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)
   15641:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   15645:	8b 55 f4             	mov    -0xc(%ebp),%edx
   15648:	ee                   	out    %al,(%dx)
   15649:	c7 45 fc a1 00 00 00 	movl   $0xa1,-0x4(%ebp)
   15650:	c6 45 fb 00          	movb   $0x0,-0x5(%ebp)
   15654:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
   15658:	8b 55 fc             	mov    -0x4(%ebp),%edx
   1565b:	ee                   	out    %al,(%dx)
	/*
	** OCW1: allow interrupts on all lines
	*/
	outb( PIC1_DATA, PIC_MASK_NONE );
	outb( PIC2_DATA, PIC_MASK_NONE );
}
   1565c:	90                   	nop
   1565d:	c9                   	leave  
   1565e:	c3                   	ret    

0001565f <set_idt_entry>:
** @param handler  ISR address to be put into the IDT entry
**
** Note: generally, the handler invoked from the IDT will be a "stub"
** that calls the second-level C handler via the isr_table array.
*/
static void set_idt_entry( int entry, void ( *handler )( void ) ) {
   1565f:	55                   	push   %ebp
   15660:	89 e5                	mov    %esp,%ebp
   15662:	83 ec 10             	sub    $0x10,%esp
	IDT_Gate *g = (IDT_Gate *)IDT_ADDR + entry;
   15665:	8b 45 08             	mov    0x8(%ebp),%eax
   15668:	c1 e0 03             	shl    $0x3,%eax
   1566b:	05 00 25 00 00       	add    $0x2500,%eax
   15670:	89 45 fc             	mov    %eax,-0x4(%ebp)

	g->offset_15_0 = (int)handler & 0xffff;
   15673:	8b 45 0c             	mov    0xc(%ebp),%eax
   15676:	89 c2                	mov    %eax,%edx
   15678:	8b 45 fc             	mov    -0x4(%ebp),%eax
   1567b:	66 89 10             	mov    %dx,(%eax)
	g->segment_selector = 0x0010;
   1567e:	8b 45 fc             	mov    -0x4(%ebp),%eax
   15681:	66 c7 40 02 10 00    	movw   $0x10,0x2(%eax)
	g->flags = IDT_PRESENT | IDT_DPL_0 | IDT_INT32_GATE;
   15687:	8b 45 fc             	mov    -0x4(%ebp),%eax
   1568a:	66 c7 40 04 00 8e    	movw   $0x8e00,0x4(%eax)
	g->offset_31_16 = (int)handler >> 16 & 0xffff;
   15690:	8b 45 0c             	mov    0xc(%ebp),%eax
   15693:	c1 e8 10             	shr    $0x10,%eax
   15696:	89 c2                	mov    %eax,%edx
   15698:	8b 45 fc             	mov    -0x4(%ebp),%eax
   1569b:	66 89 50 06          	mov    %dx,0x6(%eax)
}
   1569f:	90                   	nop
   156a0:	c9                   	leave  
   156a1:	c3                   	ret    

000156a2 <init_idt>:
** the entries in the IDT point to the isr stub for that entry, and
** installs a default handler in the handler table.  Temporary handlers
** are then installed for those interrupts we may get before a real
** handler is set up.
*/
static void init_idt( void ) {
   156a2:	55                   	push   %ebp
   156a3:	89 e5                	mov    %esp,%ebp
   156a5:	83 ec 18             	sub    $0x18,%esp

	/*
	** Make each IDT entry point to the stub for that vector.  Also
	** make each entry in the ISR table point to the default handler.
	*/
	for ( i=0; i < N_EXCEPTIONS; i++ ) {
   156a8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   156af:	eb 2d                	jmp    156de <init_idt+0x3c>
		set_idt_entry( i, isr_stub_table[ i ] );
   156b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
   156b4:	8b 04 85 16 a5 01 00 	mov    0x1a516(,%eax,4),%eax
   156bb:	50                   	push   %eax
   156bc:	ff 75 f4             	pushl  -0xc(%ebp)
   156bf:	e8 9b ff ff ff       	call   1565f <set_idt_entry>
   156c4:	83 c4 08             	add    $0x8,%esp
		install_isr( i, unexpected_handler );
   156c7:	83 ec 08             	sub    $0x8,%esp
   156ca:	68 ce 54 01 00       	push   $0x154ce
   156cf:	ff 75 f4             	pushl  -0xc(%ebp)
   156d2:	e8 9f 00 00 00       	call   15776 <install_isr>
   156d7:	83 c4 10             	add    $0x10,%esp
	for ( i=0; i < N_EXCEPTIONS; i++ ) {
   156da:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   156de:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
   156e5:	7e ca                	jle    156b1 <init_idt+0xf>
	** Install the handlers for interrupts that have (or will have) a
	** specific handler. Comments indicate which module init function
	** will eventually install the "real" handler.
	*/

	install_isr( VEC_KBD, default_handler );         // cio_init()
   156e7:	83 ec 08             	sub    $0x8,%esp
   156ea:	68 fd 54 01 00       	push   $0x154fd
   156ef:	6a 21                	push   $0x21
   156f1:	e8 80 00 00 00       	call   15776 <install_isr>
   156f6:	83 c4 10             	add    $0x10,%esp
	install_isr( VEC_COM1, default_handler );        // sio_init()
   156f9:	83 ec 08             	sub    $0x8,%esp
   156fc:	68 fd 54 01 00       	push   $0x154fd
   15701:	6a 24                	push   $0x24
   15703:	e8 6e 00 00 00       	call   15776 <install_isr>
   15708:	83 c4 10             	add    $0x10,%esp
	install_isr( VEC_TIMER, default_handler );       // clk_init()
   1570b:	83 ec 08             	sub    $0x8,%esp
   1570e:	68 fd 54 01 00       	push   $0x154fd
   15713:	6a 20                	push   $0x20
   15715:	e8 5c 00 00 00       	call   15776 <install_isr>
   1571a:	83 c4 10             	add    $0x10,%esp
	install_isr( VEC_SYSCALL, default_handler );     // sys_init()
   1571d:	83 ec 08             	sub    $0x8,%esp
   15720:	68 fd 54 01 00       	push   $0x154fd
   15725:	68 80 00 00 00       	push   $0x80
   1572a:	e8 47 00 00 00       	call   15776 <install_isr>
   1572f:	83 c4 10             	add    $0x10,%esp
	// install_isr( VEC_PAGE_FAULT, default_handler );  // vm_init()

	install_isr( VEC_MYSTERY, mystery_handler );
   15732:	83 ec 08             	sub    $0x8,%esp
   15735:	68 66 55 01 00       	push   $0x15566
   1573a:	6a 27                	push   $0x27
   1573c:	e8 35 00 00 00       	call   15776 <install_isr>
   15741:	83 c4 10             	add    $0x10,%esp
}
   15744:	90                   	nop
   15745:	c9                   	leave  
   15746:	c3                   	ret    

00015747 <panic>:
/*
** panic
**
** Called when we find an unrecoverable error.
*/
void panic( char *reason ) {
   15747:	55                   	push   %ebp
   15748:	89 e5                	mov    %esp,%ebp
   1574a:	83 ec 08             	sub    $0x8,%esp
	__asm__( "cli" );
   1574d:	fa                   	cli    
	cio_printf( "\nPANIC: %s\nHalting...", reason );
   1574e:	83 ec 08             	sub    $0x8,%esp
   15751:	ff 75 08             	pushl  0x8(%ebp)
   15754:	68 14 b8 01 00       	push   $0x1b814
   15759:	e8 c9 bd ff ff       	call   11527 <cio_printf>
   1575e:	83 c4 10             	add    $0x10,%esp
	for(;;) {
   15761:	eb fe                	jmp    15761 <panic+0x1a>

00015763 <init_interrupts>:
/*
** init_interrupts
**
** (Re)initilizes the interrupt system.
*/
void init_interrupts( void ) {
   15763:	55                   	push   %ebp
   15764:	89 e5                	mov    %esp,%ebp
   15766:	83 ec 08             	sub    $0x8,%esp
	init_idt();
   15769:	e8 34 ff ff ff       	call   156a2 <init_idt>
	init_pic();
   1576e:	e8 25 fe ff ff       	call   15598 <init_pic>
}
   15773:	90                   	nop
   15774:	c9                   	leave  
   15775:	c3                   	ret    

00015776 <install_isr>:
** install_isr
**
** Installs a second-level handler for a specific interrupt.
*/
void (*install_isr( int vector,
		void (*handler)(int,int) ) ) ( int, int ) {
   15776:	55                   	push   %ebp
   15777:	89 e5                	mov    %esp,%ebp
   15779:	83 ec 10             	sub    $0x10,%esp

	void ( *old_handler )( int vector, int code );

	old_handler = isr_table[ vector ];
   1577c:	8b 45 08             	mov    0x8(%ebp),%eax
   1577f:	8b 04 85 e0 24 02 00 	mov    0x224e0(,%eax,4),%eax
   15786:	89 45 fc             	mov    %eax,-0x4(%ebp)
	isr_table[ vector ] = handler;
   15789:	8b 45 08             	mov    0x8(%ebp),%eax
   1578c:	8b 55 0c             	mov    0xc(%ebp),%edx
   1578f:	89 14 85 e0 24 02 00 	mov    %edx,0x224e0(,%eax,4)
	return old_handler;
   15796:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   15799:	c9                   	leave  
   1579a:	c3                   	ret    

0001579b <delay>:
** On the current machines (Intel Core i5-7500), delay(100) is about
** 2.5 seconds, so each "unit" is roughly 0.025 seconds.
**
** Ultimately, just remember that DELAY VALUES ARE APPROXIMATE AT BEST.
*/
void delay( int length ) {
   1579b:	55                   	push   %ebp
   1579c:	89 e5                	mov    %esp,%ebp
   1579e:	83 ec 10             	sub    $0x10,%esp

	while( --length >= 0 ) {
   157a1:	eb 16                	jmp    157b9 <delay+0x1e>
		for( int i = 0; i < 10000000; ++i )
   157a3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   157aa:	eb 04                	jmp    157b0 <delay+0x15>
   157ac:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   157b0:	81 7d fc 7f 96 98 00 	cmpl   $0x98967f,-0x4(%ebp)
   157b7:	7e f3                	jle    157ac <delay+0x11>
	while( --length >= 0 ) {
   157b9:	83 6d 08 01          	subl   $0x1,0x8(%ebp)
   157bd:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   157c1:	79 e0                	jns    157a3 <delay+0x8>
			;
	}
}
   157c3:	90                   	nop
   157c4:	c9                   	leave  
   157c5:	c3                   	ret    

000157c6 <sys_exit>:
** Implements:
**		void exit( int32_t status );
**
** Does not return
*/
SYSIMPL(exit) {
   157c6:	55                   	push   %ebp
   157c7:	89 e5                	mov    %esp,%ebp
   157c9:	83 ec 08             	sub    $0x8,%esp

	// sanity check
	assert( pcb != NULL );
   157cc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   157d0:	75 38                	jne    1580a <sys_exit+0x44>
   157d2:	83 ec 04             	sub    $0x4,%esp
   157d5:	68 40 b8 01 00       	push   $0x1b840
   157da:	6a 00                	push   $0x0
   157dc:	6a 65                	push   $0x65
   157de:	68 49 b8 01 00       	push   $0x1b849
   157e3:	68 fc b9 01 00       	push   $0x1b9fc
   157e8:	68 54 b8 01 00       	push   $0x1b854
   157ed:	68 00 00 02 00       	push   $0x20000
   157f2:	e8 00 cf ff ff       	call   126f7 <sprint>
   157f7:	83 c4 20             	add    $0x20,%esp
   157fa:	83 ec 0c             	sub    $0xc,%esp
   157fd:	68 00 00 02 00       	push   $0x20000
   15802:	e8 70 cc ff ff       	call   12477 <kpanic>
   15807:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   1580a:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1580f:	85 c0                	test   %eax,%eax
   15811:	74 1c                	je     1582f <sys_exit+0x69>
   15813:	8b 45 08             	mov    0x8(%ebp),%eax
   15816:	8b 40 18             	mov    0x18(%eax),%eax
   15819:	83 ec 04             	sub    $0x4,%esp
   1581c:	50                   	push   %eax
   1581d:	68 fc b9 01 00       	push   $0x1b9fc
   15822:	68 6a b8 01 00       	push   $0x1b86a
   15827:	e8 fb bc ff ff       	call   11527 <cio_printf>
   1582c:	83 c4 10             	add    $0x10,%esp

	// retrieve the exit status of this process
	pcb->exit_status = (int32_t) ARG(pcb,1);
   1582f:	8b 45 08             	mov    0x8(%ebp),%eax
   15832:	8b 00                	mov    (%eax),%eax
   15834:	83 c0 48             	add    $0x48,%eax
   15837:	83 c0 04             	add    $0x4,%eax
   1583a:	8b 00                	mov    (%eax),%eax
   1583c:	89 c2                	mov    %eax,%edx
   1583e:	8b 45 08             	mov    0x8(%ebp),%eax
   15841:	89 50 14             	mov    %edx,0x14(%eax)

	// now, we need to do the following:
	// 	reparent any children of this process and wake up init if need be
	// 	find this process' parent and wake it up if it's waiting
	
	pcb_zombify( pcb );
   15844:	83 ec 0c             	sub    $0xc,%esp
   15847:	ff 75 08             	pushl  0x8(%ebp)
   1584a:	e8 b3 e1 ff ff       	call   13a02 <pcb_zombify>
   1584f:	83 c4 10             	add    $0x10,%esp

	// pick a new winner
	current = NULL;
   15852:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   15859:	00 00 00 
	dispatch();
   1585c:	e8 1f ec ff ff       	call   14480 <dispatch>

	SYSCALL_EXIT( 0 );
   15861:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15866:	85 c0                	test   %eax,%eax
   15868:	74 18                	je     15882 <sys_exit+0xbc>
   1586a:	83 ec 04             	sub    $0x4,%esp
   1586d:	6a 00                	push   $0x0
   1586f:	68 fc b9 01 00       	push   $0x1b9fc
   15874:	68 7b b8 01 00       	push   $0x1b87b
   15879:	e8 a9 bc ff ff       	call   11527 <cio_printf>
   1587e:	83 c4 10             	add    $0x10,%esp
	return;
   15881:	90                   	nop
   15882:	90                   	nop
}
   15883:	c9                   	leave  
   15884:	c3                   	ret    

00015885 <sys_waitpid>:
** Blocks the calling process until the specified child (or any child)
** of the caller terminates. Intrinsic return is the PID of the child that
** terminated, or an error code; on success, returns the child's termination
** status via 'status' if that pointer is non-NULL.
*/
SYSIMPL(waitpid) {
   15885:	55                   	push   %ebp
   15886:	89 e5                	mov    %esp,%ebp
   15888:	53                   	push   %ebx
   15889:	83 ec 24             	sub    $0x24,%esp

	// sanity check
	assert( pcb != NULL );
   1588c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15890:	75 3b                	jne    158cd <sys_waitpid+0x48>
   15892:	83 ec 04             	sub    $0x4,%esp
   15895:	68 40 b8 01 00       	push   $0x1b840
   1589a:	6a 00                	push   $0x0
   1589c:	68 88 00 00 00       	push   $0x88
   158a1:	68 49 b8 01 00       	push   $0x1b849
   158a6:	68 08 ba 01 00       	push   $0x1ba08
   158ab:	68 54 b8 01 00       	push   $0x1b854
   158b0:	68 00 00 02 00       	push   $0x20000
   158b5:	e8 3d ce ff ff       	call   126f7 <sprint>
   158ba:	83 c4 20             	add    $0x20,%esp
   158bd:	83 ec 0c             	sub    $0xc,%esp
   158c0:	68 00 00 02 00       	push   $0x20000
   158c5:	e8 ad cb ff ff       	call   12477 <kpanic>
   158ca:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   158cd:	a1 e0 28 02 00       	mov    0x228e0,%eax
   158d2:	85 c0                	test   %eax,%eax
   158d4:	74 1c                	je     158f2 <sys_waitpid+0x6d>
   158d6:	8b 45 08             	mov    0x8(%ebp),%eax
   158d9:	8b 40 18             	mov    0x18(%eax),%eax
   158dc:	83 ec 04             	sub    $0x4,%esp
   158df:	50                   	push   %eax
   158e0:	68 08 ba 01 00       	push   $0x1ba08
   158e5:	68 6a b8 01 00       	push   $0x1b86a
   158ea:	e8 38 bc ff ff       	call   11527 <cio_printf>
   158ef:	83 c4 10             	add    $0x10,%esp
	** we reap here; there could be several, but we only need to
	** find one.
	*/

	// verify that we aren't looking for ourselves!
	uint_t target = ARG(pcb,1);
   158f2:	8b 45 08             	mov    0x8(%ebp),%eax
   158f5:	8b 00                	mov    (%eax),%eax
   158f7:	83 c0 48             	add    $0x48,%eax
   158fa:	8b 40 04             	mov    0x4(%eax),%eax
   158fd:	89 45 e8             	mov    %eax,-0x18(%ebp)

	if( target == pcb->pid ) {
   15900:	8b 45 08             	mov    0x8(%ebp),%eax
   15903:	8b 40 18             	mov    0x18(%eax),%eax
   15906:	39 45 e8             	cmp    %eax,-0x18(%ebp)
   15909:	75 35                	jne    15940 <sys_waitpid+0xbb>
		RET(pcb) = E_BAD_PARAM;
   1590b:	8b 45 08             	mov    0x8(%ebp),%eax
   1590e:	8b 00                	mov    (%eax),%eax
   15910:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
		SYSCALL_EXIT( E_BAD_PARAM );
   15917:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1591c:	85 c0                	test   %eax,%eax
   1591e:	0f 84 55 02 00 00    	je     15b79 <sys_waitpid+0x2f4>
   15924:	83 ec 04             	sub    $0x4,%esp
   15927:	6a fe                	push   $0xfffffffe
   15929:	68 08 ba 01 00       	push   $0x1ba08
   1592e:	68 7b b8 01 00       	push   $0x1b87b
   15933:	e8 ef bb ff ff       	call   11527 <cio_printf>
   15938:	83 c4 10             	add    $0x10,%esp
		return;
   1593b:	e9 39 02 00 00       	jmp    15b79 <sys_waitpid+0x2f4>
	}

	// Good.  Now, figure out what we're looking for.

	pcb_t *child = NULL;
   15940:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if( target != 0 ) {
   15947:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   1594b:	0f 84 a7 00 00 00    	je     159f8 <sys_waitpid+0x173>

		// we're looking for a specific child
		child = pcb_find_pid( target );
   15951:	83 ec 0c             	sub    $0xc,%esp
   15954:	ff 75 e8             	pushl  -0x18(%ebp)
   15957:	e8 67 e3 ff ff       	call   13cc3 <pcb_find_pid>
   1595c:	83 c4 10             	add    $0x10,%esp
   1595f:	89 45 f4             	mov    %eax,-0xc(%ebp)

		if( child != NULL ) {
   15962:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15966:	74 5b                	je     159c3 <sys_waitpid+0x13e>

			// found the process; is it one of our children:
			if( child->parent != pcb ) {
   15968:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1596b:	8b 40 0c             	mov    0xc(%eax),%eax
   1596e:	39 45 08             	cmp    %eax,0x8(%ebp)
   15971:	74 35                	je     159a8 <sys_waitpid+0x123>
				// NO, so we can't wait for it
				RET(pcb) = E_BAD_PARAM;
   15973:	8b 45 08             	mov    0x8(%ebp),%eax
   15976:	8b 00                	mov    (%eax),%eax
   15978:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
				SYSCALL_EXIT( E_BAD_PARAM );
   1597f:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15984:	85 c0                	test   %eax,%eax
   15986:	0f 84 f0 01 00 00    	je     15b7c <sys_waitpid+0x2f7>
   1598c:	83 ec 04             	sub    $0x4,%esp
   1598f:	6a fe                	push   $0xfffffffe
   15991:	68 08 ba 01 00       	push   $0x1ba08
   15996:	68 7b b8 01 00       	push   $0x1b87b
   1599b:	e8 87 bb ff ff       	call   11527 <cio_printf>
   159a0:	83 c4 10             	add    $0x10,%esp
				return;
   159a3:	e9 d4 01 00 00       	jmp    15b7c <sys_waitpid+0x2f7>
			}

			// yes!  is this one ready to be collected?
			if( child->state != STATE_ZOMBIE ) {
   159a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
   159ab:	8b 40 1c             	mov    0x1c(%eax),%eax
   159ae:	83 f8 08             	cmp    $0x8,%eax
   159b1:	0f 84 bb 00 00 00    	je     15a72 <sys_waitpid+0x1ed>
				// no, so we'll have to block for now
				child = NULL;
   159b7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   159be:	e9 af 00 00 00       	jmp    15a72 <sys_waitpid+0x1ed>
			}

		} else {

			// no such child
			RET(pcb) = E_BAD_PARAM;
   159c3:	8b 45 08             	mov    0x8(%ebp),%eax
   159c6:	8b 00                	mov    (%eax),%eax
   159c8:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
			SYSCALL_EXIT( E_BAD_PARAM );
   159cf:	a1 e0 28 02 00       	mov    0x228e0,%eax
   159d4:	85 c0                	test   %eax,%eax
   159d6:	0f 84 a3 01 00 00    	je     15b7f <sys_waitpid+0x2fa>
   159dc:	83 ec 04             	sub    $0x4,%esp
   159df:	6a fe                	push   $0xfffffffe
   159e1:	68 08 ba 01 00       	push   $0x1ba08
   159e6:	68 7b b8 01 00       	push   $0x1b87b
   159eb:	e8 37 bb ff ff       	call   11527 <cio_printf>
   159f0:	83 c4 10             	add    $0x10,%esp
			return;
   159f3:	e9 87 01 00 00       	jmp    15b7f <sys_waitpid+0x2fa>
		// looking for any child

		// we need to find a process that is our child
		// and has already exited

		child = NULL;
   159f8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
		bool_t found = false;
   159ff:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)

		// unfortunately, we can't stop at the first child,
		// so we need to do the iteration ourselves
		register pcb_t *curr = ptable;
   15a03:	bb 20 20 02 00       	mov    $0x22020,%ebx

		for( int i = 0; i < N_PROCS; ++i, ++curr ) {
   15a08:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   15a0f:	eb 20                	jmp    15a31 <sys_waitpid+0x1ac>

			if( curr->parent == pcb ) {
   15a11:	8b 43 0c             	mov    0xc(%ebx),%eax
   15a14:	39 45 08             	cmp    %eax,0x8(%ebp)
   15a17:	75 11                	jne    15a2a <sys_waitpid+0x1a5>

				// found one!
				found = true;
   15a19:	c6 45 f3 01          	movb   $0x1,-0xd(%ebp)

				// has it already exited?
				if( curr->state == STATE_ZOMBIE ) {
   15a1d:	8b 43 1c             	mov    0x1c(%ebx),%eax
   15a20:	83 f8 08             	cmp    $0x8,%eax
   15a23:	75 05                	jne    15a2a <sys_waitpid+0x1a5>
					// yes, so we're done here
					child = curr;
   15a25:	89 5d f4             	mov    %ebx,-0xc(%ebp)
					break;
   15a28:	eb 0d                	jmp    15a37 <sys_waitpid+0x1b2>
		for( int i = 0; i < N_PROCS; ++i, ++curr ) {
   15a2a:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   15a2e:	83 c3 30             	add    $0x30,%ebx
   15a31:	83 7d ec 18          	cmpl   $0x18,-0x14(%ebp)
   15a35:	7e da                	jle    15a11 <sys_waitpid+0x18c>
				}
			}
		}

		if( !found ) {
   15a37:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   15a3b:	75 35                	jne    15a72 <sys_waitpid+0x1ed>
			// got through the loop without finding a child!
			RET(pcb) = E_NO_CHILDREN;
   15a3d:	8b 45 08             	mov    0x8(%ebp),%eax
   15a40:	8b 00                	mov    (%eax),%eax
   15a42:	c7 40 30 fc ff ff ff 	movl   $0xfffffffc,0x30(%eax)
			SYSCALL_EXIT( E_NO_CHILDREN );
   15a49:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15a4e:	85 c0                	test   %eax,%eax
   15a50:	0f 84 2c 01 00 00    	je     15b82 <sys_waitpid+0x2fd>
   15a56:	83 ec 04             	sub    $0x4,%esp
   15a59:	6a fc                	push   $0xfffffffc
   15a5b:	68 08 ba 01 00       	push   $0x1ba08
   15a60:	68 7b b8 01 00       	push   $0x1b87b
   15a65:	e8 bd ba ff ff       	call   11527 <cio_printf>
   15a6a:	83 c4 10             	add    $0x10,%esp
			return;
   15a6d:	e9 10 01 00 00       	jmp    15b82 <sys_waitpid+0x2fd>
	** case, we collect its status and clean it up; otherwise,
	** we block this process.
	*/

	// did we find one to collect?
	if( child == NULL ) {
   15a72:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15a76:	0f 85 96 00 00 00    	jne    15b12 <sys_waitpid+0x28d>

		// no - mark the parent as "Waiting"
		pcb->state = STATE_WAITING;
   15a7c:	8b 45 08             	mov    0x8(%ebp),%eax
   15a7f:	c7 40 1c 06 00 00 00 	movl   $0x6,0x1c(%eax)
		assert( pcb_queue_insert(waiting,pcb) == SUCCESS );
   15a86:	a1 10 20 02 00       	mov    0x22010,%eax
   15a8b:	83 ec 08             	sub    $0x8,%esp
   15a8e:	ff 75 08             	pushl  0x8(%ebp)
   15a91:	50                   	push   %eax
   15a92:	e8 4f e4 ff ff       	call   13ee6 <pcb_queue_insert>
   15a97:	83 c4 10             	add    $0x10,%esp
   15a9a:	85 c0                	test   %eax,%eax
   15a9c:	74 3b                	je     15ad9 <sys_waitpid+0x254>
   15a9e:	83 ec 04             	sub    $0x4,%esp
   15aa1:	68 88 b8 01 00       	push   $0x1b888
   15aa6:	6a 00                	push   $0x0
   15aa8:	68 fe 00 00 00       	push   $0xfe
   15aad:	68 49 b8 01 00       	push   $0x1b849
   15ab2:	68 08 ba 01 00       	push   $0x1ba08
   15ab7:	68 54 b8 01 00       	push   $0x1b854
   15abc:	68 00 00 02 00       	push   $0x20000
   15ac1:	e8 31 cc ff ff       	call   126f7 <sprint>
   15ac6:	83 c4 20             	add    $0x20,%esp
   15ac9:	83 ec 0c             	sub    $0xc,%esp
   15acc:	68 00 00 02 00       	push   $0x20000
   15ad1:	e8 a1 c9 ff ff       	call   12477 <kpanic>
   15ad6:	83 c4 10             	add    $0x10,%esp

		// select a new current process
		current = NULL;
   15ad9:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   15ae0:	00 00 00 
		dispatch();
   15ae3:	e8 98 e9 ff ff       	call   14480 <dispatch>
		SYSCALL_EXIT( (uint32_t) current );
   15ae8:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15aed:	85 c0                	test   %eax,%eax
   15aef:	0f 84 90 00 00 00    	je     15b85 <sys_waitpid+0x300>
   15af5:	a1 14 20 02 00       	mov    0x22014,%eax
   15afa:	83 ec 04             	sub    $0x4,%esp
   15afd:	50                   	push   %eax
   15afe:	68 08 ba 01 00       	push   $0x1ba08
   15b03:	68 7b b8 01 00       	push   $0x1b87b
   15b08:	e8 1a ba ff ff       	call   11527 <cio_printf>
   15b0d:	83 c4 10             	add    $0x10,%esp
		return;
   15b10:	eb 73                	jmp    15b85 <sys_waitpid+0x300>
	}

	// found a Zombie; collect its information and clean it up
	RET(pcb) = child->pid;
   15b12:	8b 45 08             	mov    0x8(%ebp),%eax
   15b15:	8b 00                	mov    (%eax),%eax
   15b17:	8b 55 f4             	mov    -0xc(%ebp),%edx
   15b1a:	8b 52 18             	mov    0x18(%edx),%edx
   15b1d:	89 50 30             	mov    %edx,0x30(%eax)

	// get "status" pointer from parent
	int32_t *stat = (int32_t *) ARG(pcb,2);
   15b20:	8b 45 08             	mov    0x8(%ebp),%eax
   15b23:	8b 00                	mov    (%eax),%eax
   15b25:	83 c0 48             	add    $0x48,%eax
   15b28:	83 c0 08             	add    $0x8,%eax
   15b2b:	8b 00                	mov    (%eax),%eax
   15b2d:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	// if stat is NULL, the parent doesn't want the status
	if( stat != NULL ) {
   15b30:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   15b34:	74 0b                	je     15b41 <sys_waitpid+0x2bc>
		// ** This works in the baseline because we aren't using
		// ** any type of memory protection.  If address space
		// ** separation is implemented, this code will very likely
		// ** STOP WORKING, and will need to be fixed.
		// ********************************************************
		*stat = child->exit_status;
   15b36:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15b39:	8b 50 14             	mov    0x14(%eax),%edx
   15b3c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15b3f:	89 10                	mov    %edx,(%eax)
	}

	// clean up the child
	pcb_cleanup( child );
   15b41:	83 ec 0c             	sub    $0xc,%esp
   15b44:	ff 75 f4             	pushl  -0xc(%ebp)
   15b47:	e8 4a e1 ff ff       	call   13c96 <pcb_cleanup>
   15b4c:	83 c4 10             	add    $0x10,%esp

	SYSCALL_EXIT( RET(pcb) );
   15b4f:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15b54:	85 c0                	test   %eax,%eax
   15b56:	74 30                	je     15b88 <sys_waitpid+0x303>
   15b58:	8b 45 08             	mov    0x8(%ebp),%eax
   15b5b:	8b 00                	mov    (%eax),%eax
   15b5d:	8b 40 30             	mov    0x30(%eax),%eax
   15b60:	83 ec 04             	sub    $0x4,%esp
   15b63:	50                   	push   %eax
   15b64:	68 08 ba 01 00       	push   $0x1ba08
   15b69:	68 7b b8 01 00       	push   $0x1b87b
   15b6e:	e8 b4 b9 ff ff       	call   11527 <cio_printf>
   15b73:	83 c4 10             	add    $0x10,%esp
	return;
   15b76:	90                   	nop
   15b77:	eb 0f                	jmp    15b88 <sys_waitpid+0x303>
		return;
   15b79:	90                   	nop
   15b7a:	eb 0d                	jmp    15b89 <sys_waitpid+0x304>
				return;
   15b7c:	90                   	nop
   15b7d:	eb 0a                	jmp    15b89 <sys_waitpid+0x304>
			return;
   15b7f:	90                   	nop
   15b80:	eb 07                	jmp    15b89 <sys_waitpid+0x304>
			return;
   15b82:	90                   	nop
   15b83:	eb 04                	jmp    15b89 <sys_waitpid+0x304>
		return;
   15b85:	90                   	nop
   15b86:	eb 01                	jmp    15b89 <sys_waitpid+0x304>
	return;
   15b88:	90                   	nop
}
   15b89:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   15b8c:	c9                   	leave  
   15b8d:	c3                   	ret    

00015b8e <sys_fork>:
**
** Creates a new process that is a duplicate of the calling process.
** Returns the child's PID to the parent, and 0 to the child, on success;
** else, returns an error code to the parent.
*/
SYSIMPL(fork) {
   15b8e:	55                   	push   %ebp
   15b8f:	89 e5                	mov    %esp,%ebp
   15b91:	53                   	push   %ebx
   15b92:	83 ec 14             	sub    $0x14,%esp

	// sanity check
	assert( pcb != NULL );
   15b95:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15b99:	75 3b                	jne    15bd6 <sys_fork+0x48>
   15b9b:	83 ec 04             	sub    $0x4,%esp
   15b9e:	68 40 b8 01 00       	push   $0x1b840
   15ba3:	6a 00                	push   $0x0
   15ba5:	68 2e 01 00 00       	push   $0x12e
   15baa:	68 49 b8 01 00       	push   $0x1b849
   15baf:	68 14 ba 01 00       	push   $0x1ba14
   15bb4:	68 54 b8 01 00       	push   $0x1b854
   15bb9:	68 00 00 02 00       	push   $0x20000
   15bbe:	e8 34 cb ff ff       	call   126f7 <sprint>
   15bc3:	83 c4 20             	add    $0x20,%esp
   15bc6:	83 ec 0c             	sub    $0xc,%esp
   15bc9:	68 00 00 02 00       	push   $0x20000
   15bce:	e8 a4 c8 ff ff       	call   12477 <kpanic>
   15bd3:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   15bd6:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15bdb:	85 c0                	test   %eax,%eax
   15bdd:	74 1c                	je     15bfb <sys_fork+0x6d>
   15bdf:	8b 45 08             	mov    0x8(%ebp),%eax
   15be2:	8b 40 18             	mov    0x18(%eax),%eax
   15be5:	83 ec 04             	sub    $0x4,%esp
   15be8:	50                   	push   %eax
   15be9:	68 14 ba 01 00       	push   $0x1ba14
   15bee:	68 6a b8 01 00       	push   $0x1b86a
   15bf3:	e8 2f b9 ff ff       	call   11527 <cio_printf>
   15bf8:	83 c4 10             	add    $0x10,%esp

	// Make sure there's room for another process!
	pcb_t *new;
	if( pcb_alloc(&new) != SUCCESS || new == NULL ) {
   15bfb:	83 ec 0c             	sub    $0xc,%esp
   15bfe:	8d 45 ec             	lea    -0x14(%ebp),%eax
   15c01:	50                   	push   %eax
   15c02:	e8 4f dc ff ff       	call   13856 <pcb_alloc>
   15c07:	83 c4 10             	add    $0x10,%esp
   15c0a:	85 c0                	test   %eax,%eax
   15c0c:	75 07                	jne    15c15 <sys_fork+0x87>
   15c0e:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15c11:	85 c0                	test   %eax,%eax
   15c13:	75 3c                	jne    15c51 <sys_fork+0xc3>
		RET(pcb) = E_NO_PROCS;
   15c15:	8b 45 08             	mov    0x8(%ebp),%eax
   15c18:	8b 00                	mov    (%eax),%eax
   15c1a:	c7 40 30 f9 ff ff ff 	movl   $0xfffffff9,0x30(%eax)
		SYSCALL_EXIT( RET(pcb) );
   15c21:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15c26:	85 c0                	test   %eax,%eax
   15c28:	0f 84 c0 01 00 00    	je     15dee <sys_fork+0x260>
   15c2e:	8b 45 08             	mov    0x8(%ebp),%eax
   15c31:	8b 00                	mov    (%eax),%eax
   15c33:	8b 40 30             	mov    0x30(%eax),%eax
   15c36:	83 ec 04             	sub    $0x4,%esp
   15c39:	50                   	push   %eax
   15c3a:	68 14 ba 01 00       	push   $0x1ba14
   15c3f:	68 7b b8 01 00       	push   $0x1b87b
   15c44:	e8 de b8 ff ff       	call   11527 <cio_printf>
   15c49:	83 c4 10             	add    $0x10,%esp
		return;
   15c4c:	e9 9d 01 00 00       	jmp    15dee <sys_fork+0x260>
	}

	// create a stack for the new child
	new->stack = pcb_stack_alloc( N_USTKPAGES );
   15c51:	8b 5d ec             	mov    -0x14(%ebp),%ebx
   15c54:	83 ec 0c             	sub    $0xc,%esp
   15c57:	6a 02                	push   $0x2
   15c59:	e8 f8 dc ff ff       	call   13956 <pcb_stack_alloc>
   15c5e:	83 c4 10             	add    $0x10,%esp
   15c61:	89 43 04             	mov    %eax,0x4(%ebx)
	if( new->stack == NULL ) {
   15c64:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15c67:	8b 40 04             	mov    0x4(%eax),%eax
   15c6a:	85 c0                	test   %eax,%eax
   15c6c:	75 44                	jne    15cb2 <sys_fork+0x124>
		pcb_free( new );
   15c6e:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15c71:	83 ec 0c             	sub    $0xc,%esp
   15c74:	50                   	push   %eax
   15c75:	e8 52 dc ff ff       	call   138cc <pcb_free>
   15c7a:	83 c4 10             	add    $0x10,%esp
		RET(pcb) = E_NO_PROCS;
   15c7d:	8b 45 08             	mov    0x8(%ebp),%eax
   15c80:	8b 00                	mov    (%eax),%eax
   15c82:	c7 40 30 f9 ff ff ff 	movl   $0xfffffff9,0x30(%eax)
		SYSCALL_EXIT(E_NO_PROCS);
   15c89:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15c8e:	85 c0                	test   %eax,%eax
   15c90:	0f 84 5b 01 00 00    	je     15df1 <sys_fork+0x263>
   15c96:	83 ec 04             	sub    $0x4,%esp
   15c99:	6a f9                	push   $0xfffffff9
   15c9b:	68 14 ba 01 00       	push   $0x1ba14
   15ca0:	68 7b b8 01 00       	push   $0x1b87b
   15ca5:	e8 7d b8 ff ff       	call   11527 <cio_printf>
   15caa:	83 c4 10             	add    $0x10,%esp
		return;
   15cad:	e9 3f 01 00 00       	jmp    15df1 <sys_fork+0x263>
	}
	// remember that we used the default size
	new->stkpgs = N_USTKPAGES;
   15cb2:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15cb5:	c7 40 28 02 00 00 00 	movl   $0x2,0x28(%eax)

	// duplicate the parent's stack
	memcpy( (void *)new->stack, (void *)pcb->stack, N_USTKPAGES * SZ_PAGE );
   15cbc:	8b 45 08             	mov    0x8(%ebp),%eax
   15cbf:	8b 50 04             	mov    0x4(%eax),%edx
   15cc2:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15cc5:	8b 40 04             	mov    0x4(%eax),%eax
   15cc8:	83 ec 04             	sub    $0x4,%esp
   15ccb:	68 00 20 00 00       	push   $0x2000
   15cd0:	52                   	push   %edx
   15cd1:	50                   	push   %eax
   15cd2:	e8 be c8 ff ff       	call   12595 <memcpy>
   15cd7:	83 c4 10             	add    $0x10,%esp
    ** them, as that's impractical. As a result, user code that relies on
    ** such pointers may behave strangely after a fork().
    */

    // Figure out the byte offset from one stack to the other.
    int32_t offset = (void *) new->stack - (void *) pcb->stack;
   15cda:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15cdd:	8b 40 04             	mov    0x4(%eax),%eax
   15ce0:	89 c2                	mov    %eax,%edx
   15ce2:	8b 45 08             	mov    0x8(%ebp),%eax
   15ce5:	8b 40 04             	mov    0x4(%eax),%eax
   15ce8:	29 c2                	sub    %eax,%edx
   15cea:	89 d0                	mov    %edx,%eax
   15cec:	89 45 f0             	mov    %eax,-0x10(%ebp)

    // Add this to the child's context pointer.
    new->context = (context_t *) (((void *)pcb->context) + offset);
   15cef:	8b 45 08             	mov    0x8(%ebp),%eax
   15cf2:	8b 08                	mov    (%eax),%ecx
   15cf4:	8b 55 f0             	mov    -0x10(%ebp),%edx
   15cf7:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15cfa:	01 ca                	add    %ecx,%edx
   15cfc:	89 10                	mov    %edx,(%eax)

    // Fix the child's ESP and EBP values IFF they're non-zero.
    if( REG(new,ebp) != 0 ) {
   15cfe:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d01:	8b 00                	mov    (%eax),%eax
   15d03:	8b 40 1c             	mov    0x1c(%eax),%eax
   15d06:	85 c0                	test   %eax,%eax
   15d08:	74 15                	je     15d1f <sys_fork+0x191>
        REG(new,ebp) += offset;
   15d0a:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d0d:	8b 00                	mov    (%eax),%eax
   15d0f:	8b 48 1c             	mov    0x1c(%eax),%ecx
   15d12:	8b 55 f0             	mov    -0x10(%ebp),%edx
   15d15:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d18:	8b 00                	mov    (%eax),%eax
   15d1a:	01 ca                	add    %ecx,%edx
   15d1c:	89 50 1c             	mov    %edx,0x1c(%eax)
    }
    if( REG(new,esp) != 0 ) {
   15d1f:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d22:	8b 00                	mov    (%eax),%eax
   15d24:	8b 40 20             	mov    0x20(%eax),%eax
   15d27:	85 c0                	test   %eax,%eax
   15d29:	74 15                	je     15d40 <sys_fork+0x1b2>
        REG(new,esp) += offset;
   15d2b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d2e:	8b 00                	mov    (%eax),%eax
   15d30:	8b 48 20             	mov    0x20(%eax),%ecx
   15d33:	8b 55 f0             	mov    -0x10(%ebp),%edx
   15d36:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d39:	8b 00                	mov    (%eax),%eax
   15d3b:	01 ca                	add    %ecx,%edx
   15d3d:	89 50 20             	mov    %edx,0x20(%eax)
    }

    // Follow the EBP chain through the child's stack.
    uint32_t *bp = (uint32_t *) REG(new,ebp);
   15d40:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d43:	8b 00                	mov    (%eax),%eax
   15d45:	8b 40 1c             	mov    0x1c(%eax),%eax
   15d48:	89 45 f4             	mov    %eax,-0xc(%ebp)
    while( bp ) {
   15d4b:	eb 17                	jmp    15d64 <sys_fork+0x1d6>
        *bp += offset;
   15d4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15d50:	8b 10                	mov    (%eax),%edx
   15d52:	8b 45 f0             	mov    -0x10(%ebp),%eax
   15d55:	01 c2                	add    %eax,%edx
   15d57:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15d5a:	89 10                	mov    %edx,(%eax)
        bp = (uint32_t *) *bp;
   15d5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15d5f:	8b 00                	mov    (%eax),%eax
   15d61:	89 45 f4             	mov    %eax,-0xc(%ebp)
    while( bp ) {
   15d64:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15d68:	75 e3                	jne    15d4d <sys_fork+0x1bf>
    }

	// Set the child's identity.
	new->pid = next_pid++;
   15d6a:	a1 1c 20 02 00       	mov    0x2201c,%eax
   15d6f:	8d 50 01             	lea    0x1(%eax),%edx
   15d72:	89 15 1c 20 02 00    	mov    %edx,0x2201c
   15d78:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15d7b:	89 42 18             	mov    %eax,0x18(%edx)
	new->parent = pcb;
   15d7e:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d81:	8b 55 08             	mov    0x8(%ebp),%edx
   15d84:	89 50 0c             	mov    %edx,0xc(%eax)
	new->state = STATE_NEW;
   15d87:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d8a:	c7 40 1c 01 00 00 00 	movl   $0x1,0x1c(%eax)

	// replicate other things inherited from the parent
	new->priority = pcb->priority;
   15d91:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d94:	8b 55 08             	mov    0x8(%ebp),%edx
   15d97:	8b 52 20             	mov    0x20(%edx),%edx
   15d9a:	89 50 20             	mov    %edx,0x20(%eax)

	// Set the return values for the two processes.
	RET(pcb) = new->pid;
   15d9d:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15da0:	8b 45 08             	mov    0x8(%ebp),%eax
   15da3:	8b 00                	mov    (%eax),%eax
   15da5:	8b 52 18             	mov    0x18(%edx),%edx
   15da8:	89 50 30             	mov    %edx,0x30(%eax)
	RET(new) = 0;
   15dab:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15dae:	8b 00                	mov    (%eax),%eax
   15db0:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)

	// Schedule the child, and let the parent continue.
	schedule( new );
   15db7:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15dba:	83 ec 0c             	sub    $0xc,%esp
   15dbd:	50                   	push   %eax
   15dbe:	e8 fc e5 ff ff       	call   143bf <schedule>
   15dc3:	83 c4 10             	add    $0x10,%esp

	SYSCALL_EXIT( new->pid );
   15dc6:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15dcb:	85 c0                	test   %eax,%eax
   15dcd:	74 25                	je     15df4 <sys_fork+0x266>
   15dcf:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15dd2:	8b 40 18             	mov    0x18(%eax),%eax
   15dd5:	83 ec 04             	sub    $0x4,%esp
   15dd8:	50                   	push   %eax
   15dd9:	68 14 ba 01 00       	push   $0x1ba14
   15dde:	68 7b b8 01 00       	push   $0x1b87b
   15de3:	e8 3f b7 ff ff       	call   11527 <cio_printf>
   15de8:	83 c4 10             	add    $0x10,%esp
	return;
   15deb:	90                   	nop
   15dec:	eb 06                	jmp    15df4 <sys_fork+0x266>
		return;
   15dee:	90                   	nop
   15def:	eb 04                	jmp    15df5 <sys_fork+0x267>
		return;
   15df1:	90                   	nop
   15df2:	eb 01                	jmp    15df5 <sys_fork+0x267>
	return;
   15df4:	90                   	nop
}
   15df5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   15df8:	c9                   	leave  
   15df9:	c3                   	ret    

00015dfa <sys_exec>:
** indicated program.
**
** Returns only on failure.
*/
SYSIMPL(exec)
{
   15dfa:	55                   	push   %ebp
   15dfb:	89 e5                	mov    %esp,%ebp
   15dfd:	83 ec 18             	sub    $0x18,%esp
	// sanity check
	assert( pcb != NULL );
   15e00:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15e04:	75 3b                	jne    15e41 <sys_exec+0x47>
   15e06:	83 ec 04             	sub    $0x4,%esp
   15e09:	68 40 b8 01 00       	push   $0x1b840
   15e0e:	6a 00                	push   $0x0
   15e10:	68 8a 01 00 00       	push   $0x18a
   15e15:	68 49 b8 01 00       	push   $0x1b849
   15e1a:	68 20 ba 01 00       	push   $0x1ba20
   15e1f:	68 54 b8 01 00       	push   $0x1b854
   15e24:	68 00 00 02 00       	push   $0x20000
   15e29:	e8 c9 c8 ff ff       	call   126f7 <sprint>
   15e2e:	83 c4 20             	add    $0x20,%esp
   15e31:	83 ec 0c             	sub    $0xc,%esp
   15e34:	68 00 00 02 00       	push   $0x20000
   15e39:	e8 39 c6 ff ff       	call   12477 <kpanic>
   15e3e:	83 c4 10             	add    $0x10,%esp

	uint_t what = ARG(pcb,1);
   15e41:	8b 45 08             	mov    0x8(%ebp),%eax
   15e44:	8b 00                	mov    (%eax),%eax
   15e46:	83 c0 48             	add    $0x48,%eax
   15e49:	8b 40 04             	mov    0x4(%eax),%eax
   15e4c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	const char **args = (const char **) ARG(pcb,2);
   15e4f:	8b 45 08             	mov    0x8(%ebp),%eax
   15e52:	8b 00                	mov    (%eax),%eax
   15e54:	83 c0 48             	add    $0x48,%eax
   15e57:	83 c0 08             	add    $0x8,%eax
   15e5a:	8b 00                	mov    (%eax),%eax
   15e5c:	89 45 f0             	mov    %eax,-0x10(%ebp)

	SYSCALL_ENTER( pcb->pid );
   15e5f:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15e64:	85 c0                	test   %eax,%eax
   15e66:	74 1c                	je     15e84 <sys_exec+0x8a>
   15e68:	8b 45 08             	mov    0x8(%ebp),%eax
   15e6b:	8b 40 18             	mov    0x18(%eax),%eax
   15e6e:	83 ec 04             	sub    $0x4,%esp
   15e71:	50                   	push   %eax
   15e72:	68 20 ba 01 00       	push   $0x1ba20
   15e77:	68 6a b8 01 00       	push   $0x1b86a
   15e7c:	e8 a6 b6 ff ff       	call   11527 <cio_printf>
   15e81:	83 c4 10             	add    $0x10,%esp

	// we create a new stack for the process so we don't have to
	// worry about overwriting data in the old stack; however, we
	// need to keep the old one around until after we have copied
	// all the argument data from it.
	void *oldstack = (void *) pcb->stack;
   15e84:	8b 45 08             	mov    0x8(%ebp),%eax
   15e87:	8b 40 04             	mov    0x4(%eax),%eax
   15e8a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32_t oldsize = pcb->stkpgs;
   15e8d:	8b 45 08             	mov    0x8(%ebp),%eax
   15e90:	8b 40 28             	mov    0x28(%eax),%eax
   15e93:	89 45 e8             	mov    %eax,-0x18(%ebp)

	// allocate a new stack of the default size
	pcb->stack = pcb_stack_alloc( N_USTKPAGES );
   15e96:	83 ec 0c             	sub    $0xc,%esp
   15e99:	6a 02                	push   $0x2
   15e9b:	e8 b6 da ff ff       	call   13956 <pcb_stack_alloc>
   15ea0:	83 c4 10             	add    $0x10,%esp
   15ea3:	89 c2                	mov    %eax,%edx
   15ea5:	8b 45 08             	mov    0x8(%ebp),%eax
   15ea8:	89 50 04             	mov    %edx,0x4(%eax)
	assert( pcb->stack != NULL );
   15eab:	8b 45 08             	mov    0x8(%ebp),%eax
   15eae:	8b 40 04             	mov    0x4(%eax),%eax
   15eb1:	85 c0                	test   %eax,%eax
   15eb3:	75 3b                	jne    15ef0 <sys_exec+0xf6>
   15eb5:	83 ec 04             	sub    $0x4,%esp
   15eb8:	68 ad b8 01 00       	push   $0x1b8ad
   15ebd:	6a 00                	push   $0x0
   15ebf:	68 9d 01 00 00       	push   $0x19d
   15ec4:	68 49 b8 01 00       	push   $0x1b849
   15ec9:	68 20 ba 01 00       	push   $0x1ba20
   15ece:	68 54 b8 01 00       	push   $0x1b854
   15ed3:	68 00 00 02 00       	push   $0x20000
   15ed8:	e8 1a c8 ff ff       	call   126f7 <sprint>
   15edd:	83 c4 20             	add    $0x20,%esp
   15ee0:	83 ec 0c             	sub    $0xc,%esp
   15ee3:	68 00 00 02 00       	push   $0x20000
   15ee8:	e8 8a c5 ff ff       	call   12477 <kpanic>
   15eed:	83 c4 10             	add    $0x10,%esp
	pcb->stkpgs = N_USTKPAGES;
   15ef0:	8b 45 08             	mov    0x8(%ebp),%eax
   15ef3:	c7 40 28 02 00 00 00 	movl   $0x2,0x28(%eax)

	// set up the new stack using the old stack data
	pcb->context = stack_setup( pcb, what, args, true );
   15efa:	6a 01                	push   $0x1
   15efc:	ff 75 f0             	pushl  -0x10(%ebp)
   15eff:	ff 75 f4             	pushl  -0xc(%ebp)
   15f02:	ff 75 08             	pushl  0x8(%ebp)
   15f05:	e8 93 0b 00 00       	call   16a9d <stack_setup>
   15f0a:	83 c4 10             	add    $0x10,%esp
   15f0d:	89 c2                	mov    %eax,%edx
   15f0f:	8b 45 08             	mov    0x8(%ebp),%eax
   15f12:	89 10                	mov    %edx,(%eax)
	assert( pcb->context != NULL );
   15f14:	8b 45 08             	mov    0x8(%ebp),%eax
   15f17:	8b 00                	mov    (%eax),%eax
   15f19:	85 c0                	test   %eax,%eax
   15f1b:	75 3b                	jne    15f58 <sys_exec+0x15e>
   15f1d:	83 ec 04             	sub    $0x4,%esp
   15f20:	68 bd b8 01 00       	push   $0x1b8bd
   15f25:	6a 00                	push   $0x0
   15f27:	68 a2 01 00 00       	push   $0x1a2
   15f2c:	68 49 b8 01 00       	push   $0x1b849
   15f31:	68 20 ba 01 00       	push   $0x1ba20
   15f36:	68 54 b8 01 00       	push   $0x1b854
   15f3b:	68 00 00 02 00       	push   $0x20000
   15f40:	e8 b2 c7 ff ff       	call   126f7 <sprint>
   15f45:	83 c4 20             	add    $0x20,%esp
   15f48:	83 ec 0c             	sub    $0xc,%esp
   15f4b:	68 00 00 02 00       	push   $0x20000
   15f50:	e8 22 c5 ff ff       	call   12477 <kpanic>
   15f55:	83 c4 10             	add    $0x10,%esp

	// now we can safely free the old stack
	pcb_stack_free( oldstack, oldsize );
   15f58:	83 ec 08             	sub    $0x8,%esp
   15f5b:	ff 75 e8             	pushl  -0x18(%ebp)
   15f5e:	ff 75 ec             	pushl  -0x14(%ebp)
   15f61:	e8 34 da ff ff       	call   1399a <pcb_stack_free>
   15f66:	83 c4 10             	add    $0x10,%esp
	 **	(C) reset this one's time slice and let it continue
	 **
	 ** We choose option A.
	 */

	schedule( pcb );
   15f69:	83 ec 0c             	sub    $0xc,%esp
   15f6c:	ff 75 08             	pushl  0x8(%ebp)
   15f6f:	e8 4b e4 ff ff       	call   143bf <schedule>
   15f74:	83 c4 10             	add    $0x10,%esp

	// reset 'current' to keep dispatch() happy
	current = NULL;
   15f77:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   15f7e:	00 00 00 
	dispatch();
   15f81:	e8 fa e4 ff ff       	call   14480 <dispatch>
}
   15f86:	90                   	nop
   15f87:	c9                   	leave  
   15f88:	c3                   	ret    

00015f89 <sys_read>:
**		int read( uint_t chan, void *buffer, uint_t length );
**
** Reads up to 'length' bytes from 'chan' into 'buffer'. Returns the
** count of bytes actually transferred.
*/
SYSIMPL(read) {
   15f89:	55                   	push   %ebp
   15f8a:	89 e5                	mov    %esp,%ebp
   15f8c:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   15f8f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15f93:	75 3b                	jne    15fd0 <sys_read+0x47>
   15f95:	83 ec 04             	sub    $0x4,%esp
   15f98:	68 40 b8 01 00       	push   $0x1b840
   15f9d:	6a 00                	push   $0x0
   15f9f:	68 c3 01 00 00       	push   $0x1c3
   15fa4:	68 49 b8 01 00       	push   $0x1b849
   15fa9:	68 2c ba 01 00       	push   $0x1ba2c
   15fae:	68 54 b8 01 00       	push   $0x1b854
   15fb3:	68 00 00 02 00       	push   $0x20000
   15fb8:	e8 3a c7 ff ff       	call   126f7 <sprint>
   15fbd:	83 c4 20             	add    $0x20,%esp
   15fc0:	83 ec 0c             	sub    $0xc,%esp
   15fc3:	68 00 00 02 00       	push   $0x20000
   15fc8:	e8 aa c4 ff ff       	call   12477 <kpanic>
   15fcd:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   15fd0:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15fd5:	85 c0                	test   %eax,%eax
   15fd7:	74 1c                	je     15ff5 <sys_read+0x6c>
   15fd9:	8b 45 08             	mov    0x8(%ebp),%eax
   15fdc:	8b 40 18             	mov    0x18(%eax),%eax
   15fdf:	83 ec 04             	sub    $0x4,%esp
   15fe2:	50                   	push   %eax
   15fe3:	68 2c ba 01 00       	push   $0x1ba2c
   15fe8:	68 6a b8 01 00       	push   $0x1b86a
   15fed:	e8 35 b5 ff ff       	call   11527 <cio_printf>
   15ff2:	83 c4 10             	add    $0x10,%esp
	
	// grab the arguments
	uint_t chan = ARG(pcb,1);
   15ff5:	8b 45 08             	mov    0x8(%ebp),%eax
   15ff8:	8b 00                	mov    (%eax),%eax
   15ffa:	83 c0 48             	add    $0x48,%eax
   15ffd:	8b 40 04             	mov    0x4(%eax),%eax
   16000:	89 45 f4             	mov    %eax,-0xc(%ebp)
	char *buf = (char *) ARG(pcb,2);
   16003:	8b 45 08             	mov    0x8(%ebp),%eax
   16006:	8b 00                	mov    (%eax),%eax
   16008:	83 c0 48             	add    $0x48,%eax
   1600b:	83 c0 08             	add    $0x8,%eax
   1600e:	8b 00                	mov    (%eax),%eax
   16010:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint_t len = ARG(pcb,3);
   16013:	8b 45 08             	mov    0x8(%ebp),%eax
   16016:	8b 00                	mov    (%eax),%eax
   16018:	83 c0 48             	add    $0x48,%eax
   1601b:	8b 40 0c             	mov    0xc(%eax),%eax
   1601e:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// if the buffer is of length 0, we're done!
	if( len == 0 ) {
   16021:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   16025:	75 35                	jne    1605c <sys_read+0xd3>
		RET(pcb) = 0;
   16027:	8b 45 08             	mov    0x8(%ebp),%eax
   1602a:	8b 00                	mov    (%eax),%eax
   1602c:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
		SYSCALL_EXIT( 0 );
   16033:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16038:	85 c0                	test   %eax,%eax
   1603a:	0f 84 2b 01 00 00    	je     1616b <sys_read+0x1e2>
   16040:	83 ec 04             	sub    $0x4,%esp
   16043:	6a 00                	push   $0x0
   16045:	68 2c ba 01 00       	push   $0x1ba2c
   1604a:	68 7b b8 01 00       	push   $0x1b87b
   1604f:	e8 d3 b4 ff ff       	call   11527 <cio_printf>
   16054:	83 c4 10             	add    $0x10,%esp
		return;
   16057:	e9 0f 01 00 00       	jmp    1616b <sys_read+0x1e2>
	}

	// try to get the next character(s)
	int n = 0;
   1605c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	if( chan == CHAN_CIO ) {
   16063:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   16067:	0f 85 85 00 00 00    	jne    160f2 <sys_read+0x169>

		// console input is non-blocking
		if( cio_input_queue() < 1 ) {
   1606d:	e8 39 b7 ff ff       	call   117ab <cio_input_queue>
   16072:	85 c0                	test   %eax,%eax
   16074:	7f 35                	jg     160ab <sys_read+0x122>
			RET(pcb) = 0;
   16076:	8b 45 08             	mov    0x8(%ebp),%eax
   16079:	8b 00                	mov    (%eax),%eax
   1607b:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
			SYSCALL_EXIT( 0 );
   16082:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16087:	85 c0                	test   %eax,%eax
   16089:	0f 84 df 00 00 00    	je     1616e <sys_read+0x1e5>
   1608f:	83 ec 04             	sub    $0x4,%esp
   16092:	6a 00                	push   $0x0
   16094:	68 2c ba 01 00       	push   $0x1ba2c
   16099:	68 7b b8 01 00       	push   $0x1b87b
   1609e:	e8 84 b4 ff ff       	call   11527 <cio_printf>
   160a3:	83 c4 10             	add    $0x10,%esp
			return;
   160a6:	e9 c3 00 00 00       	jmp    1616e <sys_read+0x1e5>
		}
		// at least one character
		n = cio_gets( buf, len );
   160ab:	83 ec 08             	sub    $0x8,%esp
   160ae:	ff 75 ec             	pushl  -0x14(%ebp)
   160b1:	ff 75 f0             	pushl  -0x10(%ebp)
   160b4:	e8 a1 b6 ff ff       	call   1175a <cio_gets>
   160b9:	83 c4 10             	add    $0x10,%esp
   160bc:	89 45 e8             	mov    %eax,-0x18(%ebp)
		RET(pcb) = n;
   160bf:	8b 45 08             	mov    0x8(%ebp),%eax
   160c2:	8b 00                	mov    (%eax),%eax
   160c4:	8b 55 e8             	mov    -0x18(%ebp),%edx
   160c7:	89 50 30             	mov    %edx,0x30(%eax)
		SYSCALL_EXIT( n );
   160ca:	a1 e0 28 02 00       	mov    0x228e0,%eax
   160cf:	85 c0                	test   %eax,%eax
   160d1:	0f 84 9a 00 00 00    	je     16171 <sys_read+0x1e8>
   160d7:	8b 45 e8             	mov    -0x18(%ebp),%eax
   160da:	83 ec 04             	sub    $0x4,%esp
   160dd:	50                   	push   %eax
   160de:	68 2c ba 01 00       	push   $0x1ba2c
   160e3:	68 7b b8 01 00       	push   $0x1b87b
   160e8:	e8 3a b4 ff ff       	call   11527 <cio_printf>
   160ed:	83 c4 10             	add    $0x10,%esp
		return;
   160f0:	eb 7f                	jmp    16171 <sys_read+0x1e8>

	} else if( chan == CHAN_SIO ) {
   160f2:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
   160f6:	75 44                	jne    1613c <sys_read+0x1b3>

		// SIO input is blocking, so if there are no characters
		// available, we'll block this process
		n = sio_read( buf, len );
   160f8:	8b 45 ec             	mov    -0x14(%ebp),%eax
   160fb:	83 ec 08             	sub    $0x8,%esp
   160fe:	50                   	push   %eax
   160ff:	ff 75 f0             	pushl  -0x10(%ebp)
   16102:	e8 66 f0 ff ff       	call   1516d <sio_read>
   16107:	83 c4 10             	add    $0x10,%esp
   1610a:	89 45 e8             	mov    %eax,-0x18(%ebp)
		RET(pcb) = n;
   1610d:	8b 45 08             	mov    0x8(%ebp),%eax
   16110:	8b 00                	mov    (%eax),%eax
   16112:	8b 55 e8             	mov    -0x18(%ebp),%edx
   16115:	89 50 30             	mov    %edx,0x30(%eax)
		SYSCALL_EXIT( n );
   16118:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1611d:	85 c0                	test   %eax,%eax
   1611f:	74 53                	je     16174 <sys_read+0x1eb>
   16121:	8b 45 e8             	mov    -0x18(%ebp),%eax
   16124:	83 ec 04             	sub    $0x4,%esp
   16127:	50                   	push   %eax
   16128:	68 2c ba 01 00       	push   $0x1ba2c
   1612d:	68 7b b8 01 00       	push   $0x1b87b
   16132:	e8 f0 b3 ff ff       	call   11527 <cio_printf>
   16137:	83 c4 10             	add    $0x10,%esp
		return;
   1613a:	eb 38                	jmp    16174 <sys_read+0x1eb>

	}

	// bad channel code
	RET(pcb) = E_BAD_PARAM;
   1613c:	8b 45 08             	mov    0x8(%ebp),%eax
   1613f:	8b 00                	mov    (%eax),%eax
   16141:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
	SYSCALL_EXIT( E_BAD_PARAM );
   16148:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1614d:	85 c0                	test   %eax,%eax
   1614f:	74 26                	je     16177 <sys_read+0x1ee>
   16151:	83 ec 04             	sub    $0x4,%esp
   16154:	6a fe                	push   $0xfffffffe
   16156:	68 2c ba 01 00       	push   $0x1ba2c
   1615b:	68 7b b8 01 00       	push   $0x1b87b
   16160:	e8 c2 b3 ff ff       	call   11527 <cio_printf>
   16165:	83 c4 10             	add    $0x10,%esp
	return;
   16168:	90                   	nop
   16169:	eb 0c                	jmp    16177 <sys_read+0x1ee>
		return;
   1616b:	90                   	nop
   1616c:	eb 0a                	jmp    16178 <sys_read+0x1ef>
			return;
   1616e:	90                   	nop
   1616f:	eb 07                	jmp    16178 <sys_read+0x1ef>
		return;
   16171:	90                   	nop
   16172:	eb 04                	jmp    16178 <sys_read+0x1ef>
		return;
   16174:	90                   	nop
   16175:	eb 01                	jmp    16178 <sys_read+0x1ef>
	return;
   16177:	90                   	nop
}
   16178:	c9                   	leave  
   16179:	c3                   	ret    

0001617a <sys_write>:
**		int write( uint_t chan, const void *buffer, uint_t length );
**
** Writes 'length' bytes from 'buffer' to 'chan'. Returns the
** count of bytes actually transferred.
*/
SYSIMPL(write) {
   1617a:	55                   	push   %ebp
   1617b:	89 e5                	mov    %esp,%ebp
   1617d:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   16180:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16184:	75 3b                	jne    161c1 <sys_write+0x47>
   16186:	83 ec 04             	sub    $0x4,%esp
   16189:	68 40 b8 01 00       	push   $0x1b840
   1618e:	6a 00                	push   $0x0
   16190:	68 01 02 00 00       	push   $0x201
   16195:	68 49 b8 01 00       	push   $0x1b849
   1619a:	68 38 ba 01 00       	push   $0x1ba38
   1619f:	68 54 b8 01 00       	push   $0x1b854
   161a4:	68 00 00 02 00       	push   $0x20000
   161a9:	e8 49 c5 ff ff       	call   126f7 <sprint>
   161ae:	83 c4 20             	add    $0x20,%esp
   161b1:	83 ec 0c             	sub    $0xc,%esp
   161b4:	68 00 00 02 00       	push   $0x20000
   161b9:	e8 b9 c2 ff ff       	call   12477 <kpanic>
   161be:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   161c1:	a1 e0 28 02 00       	mov    0x228e0,%eax
   161c6:	85 c0                	test   %eax,%eax
   161c8:	74 1c                	je     161e6 <sys_write+0x6c>
   161ca:	8b 45 08             	mov    0x8(%ebp),%eax
   161cd:	8b 40 18             	mov    0x18(%eax),%eax
   161d0:	83 ec 04             	sub    $0x4,%esp
   161d3:	50                   	push   %eax
   161d4:	68 38 ba 01 00       	push   $0x1ba38
   161d9:	68 6a b8 01 00       	push   $0x1b86a
   161de:	e8 44 b3 ff ff       	call   11527 <cio_printf>
   161e3:	83 c4 10             	add    $0x10,%esp

	// grab the parameters
	uint_t chan = ARG(pcb,1);
   161e6:	8b 45 08             	mov    0x8(%ebp),%eax
   161e9:	8b 00                	mov    (%eax),%eax
   161eb:	83 c0 48             	add    $0x48,%eax
   161ee:	8b 40 04             	mov    0x4(%eax),%eax
   161f1:	89 45 f0             	mov    %eax,-0x10(%ebp)
	char *buf = (char *) ARG(pcb,2);
   161f4:	8b 45 08             	mov    0x8(%ebp),%eax
   161f7:	8b 00                	mov    (%eax),%eax
   161f9:	83 c0 48             	add    $0x48,%eax
   161fc:	83 c0 08             	add    $0x8,%eax
   161ff:	8b 00                	mov    (%eax),%eax
   16201:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint_t length = ARG(pcb,3);
   16204:	8b 45 08             	mov    0x8(%ebp),%eax
   16207:	8b 00                	mov    (%eax),%eax
   16209:	83 c0 48             	add    $0x48,%eax
   1620c:	8b 40 0c             	mov    0xc(%eax),%eax
   1620f:	89 45 e8             	mov    %eax,-0x18(%ebp)

	// this is almost insanely simple, but it does separate the
	// low-level device access fromm the higher-level syscall implementation

	// assume we write the indicated amount
	int rval = length;
   16212:	8b 45 e8             	mov    -0x18(%ebp),%eax
   16215:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// simplest case
	if( length >= 0 ) {

		if( chan == CHAN_CIO ) {
   16218:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   1621c:	75 14                	jne    16232 <sys_write+0xb8>

			cio_write( buf, length );
   1621e:	8b 45 e8             	mov    -0x18(%ebp),%eax
   16221:	83 ec 08             	sub    $0x8,%esp
   16224:	50                   	push   %eax
   16225:	ff 75 ec             	pushl  -0x14(%ebp)
   16228:	e8 b1 ac ff ff       	call   10ede <cio_write>
   1622d:	83 c4 10             	add    $0x10,%esp
   16230:	eb 21                	jmp    16253 <sys_write+0xd9>

		} else if( chan == CHAN_SIO ) {
   16232:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
   16236:	75 14                	jne    1624c <sys_write+0xd2>

			sio_write( buf, length );
   16238:	8b 45 e8             	mov    -0x18(%ebp),%eax
   1623b:	83 ec 08             	sub    $0x8,%esp
   1623e:	50                   	push   %eax
   1623f:	ff 75 ec             	pushl  -0x14(%ebp)
   16242:	e8 36 f0 ff ff       	call   1527d <sio_write>
   16247:	83 c4 10             	add    $0x10,%esp
   1624a:	eb 07                	jmp    16253 <sys_write+0xd9>

		} else {

			rval = E_BAD_CHAN;
   1624c:	c7 45 f4 fd ff ff ff 	movl   $0xfffffffd,-0xc(%ebp)

		}

	}

	RET(pcb) = rval;
   16253:	8b 45 08             	mov    0x8(%ebp),%eax
   16256:	8b 00                	mov    (%eax),%eax
   16258:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1625b:	89 50 30             	mov    %edx,0x30(%eax)

	SYSCALL_EXIT( rval );
   1625e:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16263:	85 c0                	test   %eax,%eax
   16265:	74 1a                	je     16281 <sys_write+0x107>
   16267:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1626a:	83 ec 04             	sub    $0x4,%esp
   1626d:	50                   	push   %eax
   1626e:	68 38 ba 01 00       	push   $0x1ba38
   16273:	68 7b b8 01 00       	push   $0x1b87b
   16278:	e8 aa b2 ff ff       	call   11527 <cio_printf>
   1627d:	83 c4 10             	add    $0x10,%esp
	return;
   16280:	90                   	nop
   16281:	90                   	nop
}
   16282:	c9                   	leave  
   16283:	c3                   	ret    

00016284 <sys_getpid>:
** sys_getpid - returns the PID of the calling process
**
** Implements:
**		uint_t getpid( void );
*/
SYSIMPL(getpid) {
   16284:	55                   	push   %ebp
   16285:	89 e5                	mov    %esp,%ebp
   16287:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   1628a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1628e:	75 3b                	jne    162cb <sys_getpid+0x47>
   16290:	83 ec 04             	sub    $0x4,%esp
   16293:	68 40 b8 01 00       	push   $0x1b840
   16298:	6a 00                	push   $0x0
   1629a:	68 32 02 00 00       	push   $0x232
   1629f:	68 49 b8 01 00       	push   $0x1b849
   162a4:	68 44 ba 01 00       	push   $0x1ba44
   162a9:	68 54 b8 01 00       	push   $0x1b854
   162ae:	68 00 00 02 00       	push   $0x20000
   162b3:	e8 3f c4 ff ff       	call   126f7 <sprint>
   162b8:	83 c4 20             	add    $0x20,%esp
   162bb:	83 ec 0c             	sub    $0xc,%esp
   162be:	68 00 00 02 00       	push   $0x20000
   162c3:	e8 af c1 ff ff       	call   12477 <kpanic>
   162c8:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   162cb:	a1 e0 28 02 00       	mov    0x228e0,%eax
   162d0:	85 c0                	test   %eax,%eax
   162d2:	74 1c                	je     162f0 <sys_getpid+0x6c>
   162d4:	8b 45 08             	mov    0x8(%ebp),%eax
   162d7:	8b 40 18             	mov    0x18(%eax),%eax
   162da:	83 ec 04             	sub    $0x4,%esp
   162dd:	50                   	push   %eax
   162de:	68 44 ba 01 00       	push   $0x1ba44
   162e3:	68 6a b8 01 00       	push   $0x1b86a
   162e8:	e8 3a b2 ff ff       	call   11527 <cio_printf>
   162ed:	83 c4 10             	add    $0x10,%esp

	// return the time
	RET(pcb) = pcb->pid;
   162f0:	8b 45 08             	mov    0x8(%ebp),%eax
   162f3:	8b 00                	mov    (%eax),%eax
   162f5:	8b 55 08             	mov    0x8(%ebp),%edx
   162f8:	8b 52 18             	mov    0x18(%edx),%edx
   162fb:	89 50 30             	mov    %edx,0x30(%eax)
}
   162fe:	90                   	nop
   162ff:	c9                   	leave  
   16300:	c3                   	ret    

00016301 <sys_getppid>:
** sys_getppid - returns the PID of the parent of the calling process
**
** Implements:
**		uint_t getppid( void );
*/
SYSIMPL(getppid) {
   16301:	55                   	push   %ebp
   16302:	89 e5                	mov    %esp,%ebp
   16304:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   16307:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1630b:	75 3b                	jne    16348 <sys_getppid+0x47>
   1630d:	83 ec 04             	sub    $0x4,%esp
   16310:	68 40 b8 01 00       	push   $0x1b840
   16315:	6a 00                	push   $0x0
   16317:	68 43 02 00 00       	push   $0x243
   1631c:	68 49 b8 01 00       	push   $0x1b849
   16321:	68 50 ba 01 00       	push   $0x1ba50
   16326:	68 54 b8 01 00       	push   $0x1b854
   1632b:	68 00 00 02 00       	push   $0x20000
   16330:	e8 c2 c3 ff ff       	call   126f7 <sprint>
   16335:	83 c4 20             	add    $0x20,%esp
   16338:	83 ec 0c             	sub    $0xc,%esp
   1633b:	68 00 00 02 00       	push   $0x20000
   16340:	e8 32 c1 ff ff       	call   12477 <kpanic>
   16345:	83 c4 10             	add    $0x10,%esp
	assert( pcb->parent != NULL );
   16348:	8b 45 08             	mov    0x8(%ebp),%eax
   1634b:	8b 40 0c             	mov    0xc(%eax),%eax
   1634e:	85 c0                	test   %eax,%eax
   16350:	75 3b                	jne    1638d <sys_getppid+0x8c>
   16352:	83 ec 04             	sub    $0x4,%esp
   16355:	68 cf b8 01 00       	push   $0x1b8cf
   1635a:	6a 00                	push   $0x0
   1635c:	68 44 02 00 00       	push   $0x244
   16361:	68 49 b8 01 00       	push   $0x1b849
   16366:	68 50 ba 01 00       	push   $0x1ba50
   1636b:	68 54 b8 01 00       	push   $0x1b854
   16370:	68 00 00 02 00       	push   $0x20000
   16375:	e8 7d c3 ff ff       	call   126f7 <sprint>
   1637a:	83 c4 20             	add    $0x20,%esp
   1637d:	83 ec 0c             	sub    $0xc,%esp
   16380:	68 00 00 02 00       	push   $0x20000
   16385:	e8 ed c0 ff ff       	call   12477 <kpanic>
   1638a:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   1638d:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16392:	85 c0                	test   %eax,%eax
   16394:	74 1c                	je     163b2 <sys_getppid+0xb1>
   16396:	8b 45 08             	mov    0x8(%ebp),%eax
   16399:	8b 40 18             	mov    0x18(%eax),%eax
   1639c:	83 ec 04             	sub    $0x4,%esp
   1639f:	50                   	push   %eax
   163a0:	68 50 ba 01 00       	push   $0x1ba50
   163a5:	68 6a b8 01 00       	push   $0x1b86a
   163aa:	e8 78 b1 ff ff       	call   11527 <cio_printf>
   163af:	83 c4 10             	add    $0x10,%esp

	// return the time
	RET(pcb) = pcb->parent->pid;
   163b2:	8b 45 08             	mov    0x8(%ebp),%eax
   163b5:	8b 50 0c             	mov    0xc(%eax),%edx
   163b8:	8b 45 08             	mov    0x8(%ebp),%eax
   163bb:	8b 00                	mov    (%eax),%eax
   163bd:	8b 52 18             	mov    0x18(%edx),%edx
   163c0:	89 50 30             	mov    %edx,0x30(%eax)
}
   163c3:	90                   	nop
   163c4:	c9                   	leave  
   163c5:	c3                   	ret    

000163c6 <sys_gettime>:
** sys_gettime - returns the current system time
**
** Implements:
**		uint32_t gettime( void );
*/
SYSIMPL(gettime) {
   163c6:	55                   	push   %ebp
   163c7:	89 e5                	mov    %esp,%ebp
   163c9:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   163cc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   163d0:	75 3b                	jne    1640d <sys_gettime+0x47>
   163d2:	83 ec 04             	sub    $0x4,%esp
   163d5:	68 40 b8 01 00       	push   $0x1b840
   163da:	6a 00                	push   $0x0
   163dc:	68 55 02 00 00       	push   $0x255
   163e1:	68 49 b8 01 00       	push   $0x1b849
   163e6:	68 5c ba 01 00       	push   $0x1ba5c
   163eb:	68 54 b8 01 00       	push   $0x1b854
   163f0:	68 00 00 02 00       	push   $0x20000
   163f5:	e8 fd c2 ff ff       	call   126f7 <sprint>
   163fa:	83 c4 20             	add    $0x20,%esp
   163fd:	83 ec 0c             	sub    $0xc,%esp
   16400:	68 00 00 02 00       	push   $0x20000
   16405:	e8 6d c0 ff ff       	call   12477 <kpanic>
   1640a:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   1640d:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16412:	85 c0                	test   %eax,%eax
   16414:	74 1c                	je     16432 <sys_gettime+0x6c>
   16416:	8b 45 08             	mov    0x8(%ebp),%eax
   16419:	8b 40 18             	mov    0x18(%eax),%eax
   1641c:	83 ec 04             	sub    $0x4,%esp
   1641f:	50                   	push   %eax
   16420:	68 5c ba 01 00       	push   $0x1ba5c
   16425:	68 6a b8 01 00       	push   $0x1b86a
   1642a:	e8 f8 b0 ff ff       	call   11527 <cio_printf>
   1642f:	83 c4 10             	add    $0x10,%esp

	// return the time
	RET(pcb) = system_time;
   16432:	8b 45 08             	mov    0x8(%ebp),%eax
   16435:	8b 00                	mov    (%eax),%eax
   16437:	8b 15 bc f1 01 00    	mov    0x1f1bc,%edx
   1643d:	89 50 30             	mov    %edx,0x30(%eax)
}
   16440:	90                   	nop
   16441:	c9                   	leave  
   16442:	c3                   	ret    

00016443 <sys_getprio>:
** sys_getprio - the scheduling priority of the calling process
**
** Implements:
**		int getprio( void );
*/
SYSIMPL(getprio) {
   16443:	55                   	push   %ebp
   16444:	89 e5                	mov    %esp,%ebp
   16446:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   16449:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1644d:	75 3b                	jne    1648a <sys_getprio+0x47>
   1644f:	83 ec 04             	sub    $0x4,%esp
   16452:	68 40 b8 01 00       	push   $0x1b840
   16457:	6a 00                	push   $0x0
   16459:	68 66 02 00 00       	push   $0x266
   1645e:	68 49 b8 01 00       	push   $0x1b849
   16463:	68 68 ba 01 00       	push   $0x1ba68
   16468:	68 54 b8 01 00       	push   $0x1b854
   1646d:	68 00 00 02 00       	push   $0x20000
   16472:	e8 80 c2 ff ff       	call   126f7 <sprint>
   16477:	83 c4 20             	add    $0x20,%esp
   1647a:	83 ec 0c             	sub    $0xc,%esp
   1647d:	68 00 00 02 00       	push   $0x20000
   16482:	e8 f0 bf ff ff       	call   12477 <kpanic>
   16487:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   1648a:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1648f:	85 c0                	test   %eax,%eax
   16491:	74 1c                	je     164af <sys_getprio+0x6c>
   16493:	8b 45 08             	mov    0x8(%ebp),%eax
   16496:	8b 40 18             	mov    0x18(%eax),%eax
   16499:	83 ec 04             	sub    $0x4,%esp
   1649c:	50                   	push   %eax
   1649d:	68 68 ba 01 00       	push   $0x1ba68
   164a2:	68 6a b8 01 00       	push   $0x1b86a
   164a7:	e8 7b b0 ff ff       	call   11527 <cio_printf>
   164ac:	83 c4 10             	add    $0x10,%esp

	// return the time
	RET(pcb) = pcb->priority;
   164af:	8b 45 08             	mov    0x8(%ebp),%eax
   164b2:	8b 00                	mov    (%eax),%eax
   164b4:	8b 55 08             	mov    0x8(%ebp),%edx
   164b7:	8b 52 20             	mov    0x20(%edx),%edx
   164ba:	89 50 30             	mov    %edx,0x30(%eax)
}
   164bd:	90                   	nop
   164be:	c9                   	leave  
   164bf:	c3                   	ret    

000164c0 <sys_setprio>:
** sys_setprio - sets the scheduling priority of the calling process
**
** Implements:
**		int setprio( int new );
*/
SYSIMPL(setprio) {
   164c0:	55                   	push   %ebp
   164c1:	89 e5                	mov    %esp,%ebp
   164c3:	83 ec 18             	sub    $0x18,%esp

	// sanity check!
	assert( pcb != NULL );
   164c6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   164ca:	75 3b                	jne    16507 <sys_setprio+0x47>
   164cc:	83 ec 04             	sub    $0x4,%esp
   164cf:	68 40 b8 01 00       	push   $0x1b840
   164d4:	6a 00                	push   $0x0
   164d6:	68 77 02 00 00       	push   $0x277
   164db:	68 49 b8 01 00       	push   $0x1b849
   164e0:	68 74 ba 01 00       	push   $0x1ba74
   164e5:	68 54 b8 01 00       	push   $0x1b854
   164ea:	68 00 00 02 00       	push   $0x20000
   164ef:	e8 03 c2 ff ff       	call   126f7 <sprint>
   164f4:	83 c4 20             	add    $0x20,%esp
   164f7:	83 ec 0c             	sub    $0xc,%esp
   164fa:	68 00 00 02 00       	push   $0x20000
   164ff:	e8 73 bf ff ff       	call   12477 <kpanic>
   16504:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   16507:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1650c:	85 c0                	test   %eax,%eax
   1650e:	74 1c                	je     1652c <sys_setprio+0x6c>
   16510:	8b 45 08             	mov    0x8(%ebp),%eax
   16513:	8b 40 18             	mov    0x18(%eax),%eax
   16516:	83 ec 04             	sub    $0x4,%esp
   16519:	50                   	push   %eax
   1651a:	68 74 ba 01 00       	push   $0x1ba74
   1651f:	68 6a b8 01 00       	push   $0x1b86a
   16524:	e8 fe af ff ff       	call   11527 <cio_printf>
   16529:	83 c4 10             	add    $0x10,%esp

	// remember the old priority
	int old = pcb->priority;
   1652c:	8b 45 08             	mov    0x8(%ebp),%eax
   1652f:	8b 40 20             	mov    0x20(%eax),%eax
   16532:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// set the priority
	pcb->priority = ARG(pcb,1);
   16535:	8b 45 08             	mov    0x8(%ebp),%eax
   16538:	8b 00                	mov    (%eax),%eax
   1653a:	83 c0 48             	add    $0x48,%eax
   1653d:	83 c0 04             	add    $0x4,%eax
   16540:	8b 10                	mov    (%eax),%edx
   16542:	8b 45 08             	mov    0x8(%ebp),%eax
   16545:	89 50 20             	mov    %edx,0x20(%eax)

	// return the old value
	RET(pcb) = old;
   16548:	8b 45 08             	mov    0x8(%ebp),%eax
   1654b:	8b 00                	mov    (%eax),%eax
   1654d:	8b 55 f4             	mov    -0xc(%ebp),%edx
   16550:	89 50 30             	mov    %edx,0x30(%eax)
}
   16553:	90                   	nop
   16554:	c9                   	leave  
   16555:	c3                   	ret    

00016556 <sys_kill>:
**		int32_t kill( uint_t pid );
**
** Marks the specified process (or the calling process, if PID is 0)
** as "killed". Returns 0 on success, else an error code.
*/
SYSIMPL(kill) {
   16556:	55                   	push   %ebp
   16557:	89 e5                	mov    %esp,%ebp
   16559:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   1655c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16560:	75 3b                	jne    1659d <sys_kill+0x47>
   16562:	83 ec 04             	sub    $0x4,%esp
   16565:	68 40 b8 01 00       	push   $0x1b840
   1656a:	6a 00                	push   $0x0
   1656c:	68 91 02 00 00       	push   $0x291
   16571:	68 49 b8 01 00       	push   $0x1b849
   16576:	68 80 ba 01 00       	push   $0x1ba80
   1657b:	68 54 b8 01 00       	push   $0x1b854
   16580:	68 00 00 02 00       	push   $0x20000
   16585:	e8 6d c1 ff ff       	call   126f7 <sprint>
   1658a:	83 c4 20             	add    $0x20,%esp
   1658d:	83 ec 0c             	sub    $0xc,%esp
   16590:	68 00 00 02 00       	push   $0x20000
   16595:	e8 dd be ff ff       	call   12477 <kpanic>
   1659a:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   1659d:	a1 e0 28 02 00       	mov    0x228e0,%eax
   165a2:	85 c0                	test   %eax,%eax
   165a4:	74 1c                	je     165c2 <sys_kill+0x6c>
   165a6:	8b 45 08             	mov    0x8(%ebp),%eax
   165a9:	8b 40 18             	mov    0x18(%eax),%eax
   165ac:	83 ec 04             	sub    $0x4,%esp
   165af:	50                   	push   %eax
   165b0:	68 80 ba 01 00       	push   $0x1ba80
   165b5:	68 6a b8 01 00       	push   $0x1b86a
   165ba:	e8 68 af ff ff       	call   11527 <cio_printf>
   165bf:	83 c4 10             	add    $0x10,%esp

	// who is the victim?
	uint_t pid = ARG(pcb,1);
   165c2:	8b 45 08             	mov    0x8(%ebp),%eax
   165c5:	8b 00                	mov    (%eax),%eax
   165c7:	83 c0 48             	add    $0x48,%eax
   165ca:	8b 40 04             	mov    0x4(%eax),%eax
   165cd:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// if it's this process, convert this into a call to exit()
	if( pid == pcb->pid ) {
   165d0:	8b 45 08             	mov    0x8(%ebp),%eax
   165d3:	8b 40 18             	mov    0x18(%eax),%eax
   165d6:	39 45 f0             	cmp    %eax,-0x10(%ebp)
   165d9:	75 50                	jne    1662b <sys_kill+0xd5>
		pcb->exit_status = EXIT_KILLED;
   165db:	8b 45 08             	mov    0x8(%ebp),%eax
   165de:	c7 40 14 9b ff ff ff 	movl   $0xffffff9b,0x14(%eax)
		pcb_zombify( pcb );
   165e5:	83 ec 0c             	sub    $0xc,%esp
   165e8:	ff 75 08             	pushl  0x8(%ebp)
   165eb:	e8 12 d4 ff ff       	call   13a02 <pcb_zombify>
   165f0:	83 c4 10             	add    $0x10,%esp
		// reset 'current' to keep dispatch() happy
		current = NULL;
   165f3:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   165fa:	00 00 00 
		dispatch();
   165fd:	e8 7e de ff ff       	call   14480 <dispatch>
		SYSCALL_EXIT( EXIT_KILLED );
   16602:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16607:	85 c0                	test   %eax,%eax
   16609:	0f 84 2e 02 00 00    	je     1683d <sys_kill+0x2e7>
   1660f:	83 ec 04             	sub    $0x4,%esp
   16612:	6a 9b                	push   $0xffffff9b
   16614:	68 80 ba 01 00       	push   $0x1ba80
   16619:	68 7b b8 01 00       	push   $0x1b87b
   1661e:	e8 04 af ff ff       	call   11527 <cio_printf>
   16623:	83 c4 10             	add    $0x10,%esp
		return;
   16626:	e9 12 02 00 00       	jmp    1683d <sys_kill+0x2e7>
	}

	// must be a valid "ordinary user" PID
	// QUESTION: what if it's the idle process?
	if( pid < FIRST_USER_PID ) {
   1662b:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
   1662f:	77 35                	ja     16666 <sys_kill+0x110>
		RET(pcb) = E_FAILURE;
   16631:	8b 45 08             	mov    0x8(%ebp),%eax
   16634:	8b 00                	mov    (%eax),%eax
   16636:	c7 40 30 ff ff ff ff 	movl   $0xffffffff,0x30(%eax)
		SYSCALL_EXIT( E_FAILURE );
   1663d:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16642:	85 c0                	test   %eax,%eax
   16644:	0f 84 f6 01 00 00    	je     16840 <sys_kill+0x2ea>
   1664a:	83 ec 04             	sub    $0x4,%esp
   1664d:	6a ff                	push   $0xffffffff
   1664f:	68 80 ba 01 00       	push   $0x1ba80
   16654:	68 7b b8 01 00       	push   $0x1b87b
   16659:	e8 c9 ae ff ff       	call   11527 <cio_printf>
   1665e:	83 c4 10             	add    $0x10,%esp
		return;
   16661:	e9 da 01 00 00       	jmp    16840 <sys_kill+0x2ea>
	}

	// OK, this is an acceptable victim; see if it exists
	pcb_t *victim = pcb_find_pid( pid );
   16666:	83 ec 0c             	sub    $0xc,%esp
   16669:	ff 75 f0             	pushl  -0x10(%ebp)
   1666c:	e8 52 d6 ff ff       	call   13cc3 <pcb_find_pid>
   16671:	83 c4 10             	add    $0x10,%esp
   16674:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if( victim == NULL ) {
   16677:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   1667b:	75 35                	jne    166b2 <sys_kill+0x15c>
		// nope!
		RET(pcb) = E_NOT_FOUND;
   1667d:	8b 45 08             	mov    0x8(%ebp),%eax
   16680:	8b 00                	mov    (%eax),%eax
   16682:	c7 40 30 fa ff ff ff 	movl   $0xfffffffa,0x30(%eax)
		SYSCALL_EXIT( E_NOT_FOUND );
   16689:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1668e:	85 c0                	test   %eax,%eax
   16690:	0f 84 ad 01 00 00    	je     16843 <sys_kill+0x2ed>
   16696:	83 ec 04             	sub    $0x4,%esp
   16699:	6a fa                	push   $0xfffffffa
   1669b:	68 80 ba 01 00       	push   $0x1ba80
   166a0:	68 7b b8 01 00       	push   $0x1b87b
   166a5:	e8 7d ae ff ff       	call   11527 <cio_printf>
   166aa:	83 c4 10             	add    $0x10,%esp
		return;
   166ad:	e9 91 01 00 00       	jmp    16843 <sys_kill+0x2ed>
	}

	// must have a state that is possible
	assert( victim->state >= FIRST_VIABLE && victim->state < N_STATES );
   166b2:	8b 45 ec             	mov    -0x14(%ebp),%eax
   166b5:	8b 40 1c             	mov    0x1c(%eax),%eax
   166b8:	83 f8 01             	cmp    $0x1,%eax
   166bb:	76 0b                	jbe    166c8 <sys_kill+0x172>
   166bd:	8b 45 ec             	mov    -0x14(%ebp),%eax
   166c0:	8b 40 1c             	mov    0x1c(%eax),%eax
   166c3:	83 f8 08             	cmp    $0x8,%eax
   166c6:	76 3b                	jbe    16703 <sys_kill+0x1ad>
   166c8:	83 ec 04             	sub    $0x4,%esp
   166cb:	68 e0 b8 01 00       	push   $0x1b8e0
   166d0:	6a 00                	push   $0x0
   166d2:	68 b5 02 00 00       	push   $0x2b5
   166d7:	68 49 b8 01 00       	push   $0x1b849
   166dc:	68 80 ba 01 00       	push   $0x1ba80
   166e1:	68 54 b8 01 00       	push   $0x1b854
   166e6:	68 00 00 02 00       	push   $0x20000
   166eb:	e8 07 c0 ff ff       	call   126f7 <sprint>
   166f0:	83 c4 20             	add    $0x20,%esp
   166f3:	83 ec 0c             	sub    $0xc,%esp
   166f6:	68 00 00 02 00       	push   $0x20000
   166fb:	e8 77 bd ff ff       	call   12477 <kpanic>
   16700:	83 c4 10             	add    $0x10,%esp

	// how we perform the kill depends on the victim's state
	int32_t status = SUCCESS;
   16703:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	switch( victim->state ) {
   1670a:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1670d:	8b 40 1c             	mov    0x1c(%eax),%eax
   16710:	83 f8 08             	cmp    $0x8,%eax
   16713:	0f 87 a4 00 00 00    	ja     167bd <sys_kill+0x267>
   16719:	8b 04 85 48 b9 01 00 	mov    0x1b948(,%eax,4),%eax
   16720:	ff e0                	jmp    *%eax

	case STATE_KILLED:    // FALL THROUGH
	case STATE_ZOMBIE:
		// you can't kill it if it's already dead
		RET(pcb) = SUCCESS;
   16722:	8b 45 08             	mov    0x8(%ebp),%eax
   16725:	8b 00                	mov    (%eax),%eax
   16727:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
		break;
   1672e:	e9 e5 00 00 00       	jmp    16818 <sys_kill+0x2c2>
	case STATE_READY:     // FALL THROUGH
	case STATE_SLEEPING:  // FALL THROUGH
	case STATE_BLOCKED:   // FALL THROUGH
		// here, the process is on a queue somewhere; mark
		// it as "killed", and let the scheduler deal with it
		victim->state = STATE_KILLED;
   16733:	8b 45 ec             	mov    -0x14(%ebp),%eax
   16736:	c7 40 1c 07 00 00 00 	movl   $0x7,0x1c(%eax)
		RET(pcb) = SUCCESS;
   1673d:	8b 45 08             	mov    0x8(%ebp),%eax
   16740:	8b 00                	mov    (%eax),%eax
   16742:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
		break;
   16749:	e9 ca 00 00 00       	jmp    16818 <sys_kill+0x2c2>

	case STATE_RUNNING:
		// we have met the enemy, and it is us!
		pcb->exit_status = EXIT_KILLED;
   1674e:	8b 45 08             	mov    0x8(%ebp),%eax
   16751:	c7 40 14 9b ff ff ff 	movl   $0xffffff9b,0x14(%eax)
		pcb_zombify( pcb );
   16758:	83 ec 0c             	sub    $0xc,%esp
   1675b:	ff 75 08             	pushl  0x8(%ebp)
   1675e:	e8 9f d2 ff ff       	call   13a02 <pcb_zombify>
   16763:	83 c4 10             	add    $0x10,%esp
		status = EXIT_KILLED;
   16766:	c7 45 f4 9b ff ff ff 	movl   $0xffffff9b,-0xc(%ebp)
		// we need a new current process
		// reset 'current' to keep dispatch() happy
		current = NULL;
   1676d:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   16774:	00 00 00 
		dispatch();
   16777:	e8 04 dd ff ff       	call   14480 <dispatch>
		break;
   1677c:	e9 97 00 00 00       	jmp    16818 <sys_kill+0x2c2>

	case STATE_WAITING:
		// similar to the 'running' state, but we don't need
		// to dispatch a new process
		victim->exit_status = EXIT_KILLED;
   16781:	8b 45 ec             	mov    -0x14(%ebp),%eax
   16784:	c7 40 14 9b ff ff ff 	movl   $0xffffff9b,0x14(%eax)
		status = pcb_queue_remove_this( waiting, victim );
   1678b:	a1 10 20 02 00       	mov    0x22010,%eax
   16790:	83 ec 08             	sub    $0x8,%esp
   16793:	ff 75 ec             	pushl  -0x14(%ebp)
   16796:	50                   	push   %eax
   16797:	e8 07 da ff ff       	call   141a3 <pcb_queue_remove_this>
   1679c:	83 c4 10             	add    $0x10,%esp
   1679f:	89 45 f4             	mov    %eax,-0xc(%ebp)
		pcb_zombify( victim );
   167a2:	83 ec 0c             	sub    $0xc,%esp
   167a5:	ff 75 ec             	pushl  -0x14(%ebp)
   167a8:	e8 55 d2 ff ff       	call   13a02 <pcb_zombify>
   167ad:	83 c4 10             	add    $0x10,%esp
		RET(pcb) = status;
   167b0:	8b 45 08             	mov    0x8(%ebp),%eax
   167b3:	8b 00                	mov    (%eax),%eax
   167b5:	8b 55 f4             	mov    -0xc(%ebp),%edx
   167b8:	89 50 30             	mov    %edx,0x30(%eax)
		break;
   167bb:	eb 5b                	jmp    16818 <sys_kill+0x2c2>
	default:
		// this is a really bad potential problem - we have an
		// unexpected or bogus process state, but we didn't
		// catch that earlier.
		sprint( b256, "*** kill(): victim %d, odd state %d\n",
				victim->pid, victim->state );
   167bd:	8b 45 ec             	mov    -0x14(%ebp),%eax
   167c0:	8b 50 1c             	mov    0x1c(%eax),%edx
		sprint( b256, "*** kill(): victim %d, odd state %d\n",
   167c3:	8b 45 ec             	mov    -0x14(%ebp),%eax
   167c6:	8b 40 18             	mov    0x18(%eax),%eax
   167c9:	52                   	push   %edx
   167ca:	50                   	push   %eax
   167cb:	68 1c b9 01 00       	push   $0x1b91c
   167d0:	68 00 02 02 00       	push   $0x20200
   167d5:	e8 1d bf ff ff       	call   126f7 <sprint>
   167da:	83 c4 10             	add    $0x10,%esp
		PANIC( 0, b256 );
   167dd:	83 ec 04             	sub    $0x4,%esp
   167e0:	68 41 b9 01 00       	push   $0x1b941
   167e5:	6a 00                	push   $0x0
   167e7:	68 e5 02 00 00       	push   $0x2e5
   167ec:	68 49 b8 01 00       	push   $0x1b849
   167f1:	68 80 ba 01 00       	push   $0x1ba80
   167f6:	68 54 b8 01 00       	push   $0x1b854
   167fb:	68 00 00 02 00       	push   $0x20000
   16800:	e8 f2 be ff ff       	call   126f7 <sprint>
   16805:	83 c4 20             	add    $0x20,%esp
   16808:	83 ec 0c             	sub    $0xc,%esp
   1680b:	68 00 00 02 00       	push   $0x20000
   16810:	e8 62 bc ff ff       	call   12477 <kpanic>
   16815:	83 c4 10             	add    $0x10,%esp
	}

	SYSCALL_EXIT( status );
   16818:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1681d:	85 c0                	test   %eax,%eax
   1681f:	74 25                	je     16846 <sys_kill+0x2f0>
   16821:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16824:	83 ec 04             	sub    $0x4,%esp
   16827:	50                   	push   %eax
   16828:	68 80 ba 01 00       	push   $0x1ba80
   1682d:	68 7b b8 01 00       	push   $0x1b87b
   16832:	e8 f0 ac ff ff       	call   11527 <cio_printf>
   16837:	83 c4 10             	add    $0x10,%esp
	return;
   1683a:	90                   	nop
   1683b:	eb 09                	jmp    16846 <sys_kill+0x2f0>
		return;
   1683d:	90                   	nop
   1683e:	eb 07                	jmp    16847 <sys_kill+0x2f1>
		return;
   16840:	90                   	nop
   16841:	eb 04                	jmp    16847 <sys_kill+0x2f1>
		return;
   16843:	90                   	nop
   16844:	eb 01                	jmp    16847 <sys_kill+0x2f1>
	return;
   16846:	90                   	nop
}
   16847:	c9                   	leave  
   16848:	c3                   	ret    

00016849 <sys_sleep>:
**		uint_t sleep( uint_t ms );
**
** Puts the calling process to sleep for 'ms' milliseconds (or just yields
** the CPU if 'ms' is 0).  ** Returns the time the process spent sleeping.
*/
SYSIMPL(sleep) {
   16849:	55                   	push   %ebp
   1684a:	89 e5                	mov    %esp,%ebp
   1684c:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   1684f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16853:	75 3b                	jne    16890 <sys_sleep+0x47>
   16855:	83 ec 04             	sub    $0x4,%esp
   16858:	68 40 b8 01 00       	push   $0x1b840
   1685d:	6a 00                	push   $0x0
   1685f:	68 f9 02 00 00       	push   $0x2f9
   16864:	68 49 b8 01 00       	push   $0x1b849
   16869:	68 8c ba 01 00       	push   $0x1ba8c
   1686e:	68 54 b8 01 00       	push   $0x1b854
   16873:	68 00 00 02 00       	push   $0x20000
   16878:	e8 7a be ff ff       	call   126f7 <sprint>
   1687d:	83 c4 20             	add    $0x20,%esp
   16880:	83 ec 0c             	sub    $0xc,%esp
   16883:	68 00 00 02 00       	push   $0x20000
   16888:	e8 ea bb ff ff       	call   12477 <kpanic>
   1688d:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   16890:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16895:	85 c0                	test   %eax,%eax
   16897:	74 1c                	je     168b5 <sys_sleep+0x6c>
   16899:	8b 45 08             	mov    0x8(%ebp),%eax
   1689c:	8b 40 18             	mov    0x18(%eax),%eax
   1689f:	83 ec 04             	sub    $0x4,%esp
   168a2:	50                   	push   %eax
   168a3:	68 8c ba 01 00       	push   $0x1ba8c
   168a8:	68 6a b8 01 00       	push   $0x1b86a
   168ad:	e8 75 ac ff ff       	call   11527 <cio_printf>
   168b2:	83 c4 10             	add    $0x10,%esp

	// get the desired duration
	uint_t length = ARG( pcb, 1 );
   168b5:	8b 45 08             	mov    0x8(%ebp),%eax
   168b8:	8b 00                	mov    (%eax),%eax
   168ba:	83 c0 48             	add    $0x48,%eax
   168bd:	8b 40 04             	mov    0x4(%eax),%eax
   168c0:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if( length == 0 ) {
   168c3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   168c7:	75 1c                	jne    168e5 <sys_sleep+0x9c>

		// just yield the CPU
		// sleep duration is 0
		RET(pcb) = 0;
   168c9:	8b 45 08             	mov    0x8(%ebp),%eax
   168cc:	8b 00                	mov    (%eax),%eax
   168ce:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)

		// back on the ready queue
		schedule( pcb );
   168d5:	83 ec 0c             	sub    $0xc,%esp
   168d8:	ff 75 08             	pushl  0x8(%ebp)
   168db:	e8 df da ff ff       	call   143bf <schedule>
   168e0:	83 c4 10             	add    $0x10,%esp
   168e3:	eb 7a                	jmp    1695f <sys_sleep+0x116>

	} else {

		// sleep for a while
		pcb->wakeup = system_time + length;
   168e5:	8b 15 bc f1 01 00    	mov    0x1f1bc,%edx
   168eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
   168ee:	01 c2                	add    %eax,%edx
   168f0:	8b 45 08             	mov    0x8(%ebp),%eax
   168f3:	89 50 10             	mov    %edx,0x10(%eax)

		if( pcb_queue_insert(sleeping,pcb) != SUCCESS ) {
   168f6:	a1 08 20 02 00       	mov    0x22008,%eax
   168fb:	83 ec 08             	sub    $0x8,%esp
   168fe:	ff 75 08             	pushl  0x8(%ebp)
   16901:	50                   	push   %eax
   16902:	e8 df d5 ff ff       	call   13ee6 <pcb_queue_insert>
   16907:	83 c4 10             	add    $0x10,%esp
   1690a:	85 c0                	test   %eax,%eax
   1690c:	74 51                	je     1695f <sys_sleep+0x116>
			// something strange is happening
			WARNING( "sleep pcb insert failed" );
   1690e:	68 10 03 00 00       	push   $0x310
   16913:	68 49 b8 01 00       	push   $0x1b849
   16918:	68 8c ba 01 00       	push   $0x1ba8c
   1691d:	68 6c b9 01 00       	push   $0x1b96c
   16922:	e8 00 ac ff ff       	call   11527 <cio_printf>
   16927:	83 c4 10             	add    $0x10,%esp
   1692a:	83 ec 0c             	sub    $0xc,%esp
   1692d:	68 7f b9 01 00       	push   $0x1b97f
   16932:	e8 76 a5 ff ff       	call   10ead <cio_puts>
   16937:	83 c4 10             	add    $0x10,%esp
   1693a:	83 ec 0c             	sub    $0xc,%esp
   1693d:	6a 0a                	push   $0xa
   1693f:	e8 29 a4 ff ff       	call   10d6d <cio_putchar>
   16944:	83 c4 10             	add    $0x10,%esp
			// if this is the current process, report an error
			if( current == pcb ) {
   16947:	a1 14 20 02 00       	mov    0x22014,%eax
   1694c:	39 45 08             	cmp    %eax,0x8(%ebp)
   1694f:	75 29                	jne    1697a <sys_sleep+0x131>
				RET(pcb) = -1;
   16951:	8b 45 08             	mov    0x8(%ebp),%eax
   16954:	8b 00                	mov    (%eax),%eax
   16956:	c7 40 30 ff ff ff ff 	movl   $0xffffffff,0x30(%eax)
			}
			// return without dispatching a new process
			return;
   1695d:	eb 1b                	jmp    1697a <sys_sleep+0x131>
		}
	}

	// only dispatch if the current process called us
	if( pcb == current ) {
   1695f:	a1 14 20 02 00       	mov    0x22014,%eax
   16964:	39 45 08             	cmp    %eax,0x8(%ebp)
   16967:	75 12                	jne    1697b <sys_sleep+0x132>
		current = NULL;
   16969:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   16970:	00 00 00 
		dispatch();
   16973:	e8 08 db ff ff       	call   14480 <dispatch>
   16978:	eb 01                	jmp    1697b <sys_sleep+0x132>
			return;
   1697a:	90                   	nop
	}
}
   1697b:	c9                   	leave  
   1697c:	c3                   	ret    

0001697d <sys_isr>:
** System call ISR
**
** @param vector   Vector number for this interrupt
** @param code     Error code (0 for this interrupt)
*/
static void sys_isr( int vector, int code ) {
   1697d:	55                   	push   %ebp
   1697e:	89 e5                	mov    %esp,%ebp
   16980:	83 ec 18             	sub    $0x18,%esp
	// keep the compiler happy
	(void) vector;
	(void) code;

	// sanity check!
	assert( current != NULL );
   16983:	a1 14 20 02 00       	mov    0x22014,%eax
   16988:	85 c0                	test   %eax,%eax
   1698a:	75 3b                	jne    169c7 <sys_isr+0x4a>
   1698c:	83 ec 04             	sub    $0x4,%esp
   1698f:	68 d4 b9 01 00       	push   $0x1b9d4
   16994:	6a 00                	push   $0x0
   16996:	68 4d 03 00 00       	push   $0x34d
   1699b:	68 49 b8 01 00       	push   $0x1b849
   169a0:	68 98 ba 01 00       	push   $0x1ba98
   169a5:	68 54 b8 01 00       	push   $0x1b854
   169aa:	68 00 00 02 00       	push   $0x20000
   169af:	e8 43 bd ff ff       	call   126f7 <sprint>
   169b4:	83 c4 20             	add    $0x20,%esp
   169b7:	83 ec 0c             	sub    $0xc,%esp
   169ba:	68 00 00 02 00       	push   $0x20000
   169bf:	e8 b3 ba ff ff       	call   12477 <kpanic>
   169c4:	83 c4 10             	add    $0x10,%esp
	assert( current->context != NULL );
   169c7:	a1 14 20 02 00       	mov    0x22014,%eax
   169cc:	8b 00                	mov    (%eax),%eax
   169ce:	85 c0                	test   %eax,%eax
   169d0:	75 3b                	jne    16a0d <sys_isr+0x90>
   169d2:	83 ec 04             	sub    $0x4,%esp
   169d5:	68 e1 b9 01 00       	push   $0x1b9e1
   169da:	6a 00                	push   $0x0
   169dc:	68 4e 03 00 00       	push   $0x34e
   169e1:	68 49 b8 01 00       	push   $0x1b849
   169e6:	68 98 ba 01 00       	push   $0x1ba98
   169eb:	68 54 b8 01 00       	push   $0x1b854
   169f0:	68 00 00 02 00       	push   $0x20000
   169f5:	e8 fd bc ff ff       	call   126f7 <sprint>
   169fa:	83 c4 20             	add    $0x20,%esp
   169fd:	83 ec 0c             	sub    $0xc,%esp
   16a00:	68 00 00 02 00       	push   $0x20000
   16a05:	e8 6d ba ff ff       	call   12477 <kpanic>
   16a0a:	83 c4 10             	add    $0x10,%esp

	// retrieve the syscall code
	int num = REG( current, eax );
   16a0d:	a1 14 20 02 00       	mov    0x22014,%eax
   16a12:	8b 00                	mov    (%eax),%eax
   16a14:	8b 40 30             	mov    0x30(%eax),%eax
   16a17:	89 45 f4             	mov    %eax,-0xc(%ebp)
#if TRACING_SYSCALLS
	cio_printf( "** --> SYS pid %u code %u\n", current->pid, num );
#endif

	// validate it
	if( num < 0 || num >= N_SYSCALLS ) {
   16a1a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   16a1e:	78 06                	js     16a26 <sys_isr+0xa9>
   16a20:	83 7d f4 0c          	cmpl   $0xc,-0xc(%ebp)
   16a24:	7e 1a                	jle    16a40 <sys_isr+0xc3>
		// bad syscall number
		// could kill it, but we'll just force it to exit
		num = SYS_exit;
   16a26:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
		ARG(current,1) = EXIT_BAD_SYSCALL;
   16a2d:	a1 14 20 02 00       	mov    0x22014,%eax
   16a32:	8b 00                	mov    (%eax),%eax
   16a34:	83 c0 48             	add    $0x48,%eax
   16a37:	83 c0 04             	add    $0x4,%eax
   16a3a:	c7 00 9a ff ff ff    	movl   $0xffffff9a,(%eax)
	}

	// call the handler
	syscalls[num]( current );
   16a40:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16a43:	8b 04 85 a0 b9 01 00 	mov    0x1b9a0(,%eax,4),%eax
   16a4a:	8b 15 14 20 02 00    	mov    0x22014,%edx
   16a50:	83 ec 0c             	sub    $0xc,%esp
   16a53:	52                   	push   %edx
   16a54:	ff d0                	call   *%eax
   16a56:	83 c4 10             	add    $0x10,%esp
   16a59:	c7 45 f0 20 00 00 00 	movl   $0x20,-0x10(%ebp)
   16a60:	c6 45 ef 20          	movb   $0x20,-0x11(%ebp)
   16a64:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
   16a68:	8b 55 f0             	mov    -0x10(%ebp),%edx
   16a6b:	ee                   	out    %al,(%dx)
	cio_printf( "** <-- SYS pid %u ret %u\n", current->pid, RET(current) );
#endif

	// tell the PIC we're done
	outb( PIC1_CMD, PIC_EOI );
}
   16a6c:	90                   	nop
   16a6d:	c9                   	leave  
   16a6e:	c3                   	ret    

00016a6f <sys_init>:
** Syscall module initialization routine
**
** Dependencies:
**    Must be called after cio_init()
*/
void sys_init( void ) {
   16a6f:	55                   	push   %ebp
   16a70:	89 e5                	mov    %esp,%ebp
   16a72:	83 ec 08             	sub    $0x8,%esp

#if TRACING_INIT
	cio_puts( " Sys" );
   16a75:	83 ec 0c             	sub    $0xc,%esp
   16a78:	68 f7 b9 01 00       	push   $0x1b9f7
   16a7d:	e8 2b a4 ff ff       	call   10ead <cio_puts>
   16a82:	83 c4 10             	add    $0x10,%esp
#endif

	// install the second-stage ISR
	install_isr( VEC_SYSCALL, sys_isr );
   16a85:	83 ec 08             	sub    $0x8,%esp
   16a88:	68 7d 69 01 00       	push   $0x1697d
   16a8d:	68 80 00 00 00       	push   $0x80
   16a92:	e8 df ec ff ff       	call   15776 <install_isr>
   16a97:	83 c4 10             	add    $0x10,%esp
}
   16a9a:	90                   	nop
   16a9b:	c9                   	leave  
   16a9c:	c3                   	ret    

00016a9d <stack_setup>:
** @param sys    Is the argument vector from kernel code?
**
** @return A (user VA) pointer to the context_t on the stack, or NULL
*/
context_t *stack_setup( pcb_t *pcb, uint32_t entry,
		const char **args, bool_t sys ) {
   16a9d:	55                   	push   %ebp
   16a9e:	89 e5                	mov    %esp,%ebp
   16aa0:	57                   	push   %edi
   16aa1:	56                   	push   %esi
   16aa2:	53                   	push   %ebx
   16aa3:	81 ec cc 00 00 00    	sub    $0xcc,%esp
   16aa9:	8b 45 14             	mov    0x14(%ebp),%eax
   16aac:	88 85 34 ff ff ff    	mov    %al,-0xcc(%ebp)
	**       the remainder of the aggregate shall be initialized
	**       implicitly the same as objects that have static storage
	**       duration."
	*/

	int argbytes = 0;                    // total length of arg strings
   16ab2:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
	int argc = 0;                        // number of argv entries
   16ab9:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
	const char *kv_strs[N_ARGS] = { 0 }; // converted user arg string pointers
   16ac0:	8d 55 88             	lea    -0x78(%ebp),%edx
   16ac3:	b8 00 00 00 00       	mov    $0x0,%eax
   16ac8:	b9 0a 00 00 00       	mov    $0xa,%ecx
   16acd:	89 d7                	mov    %edx,%edi
   16acf:	f3 ab                	rep stos %eax,%es:(%edi)
	int strlengths[N_ARGS] = { 0 };      // length of each string
   16ad1:	8d 95 60 ff ff ff    	lea    -0xa0(%ebp),%edx
   16ad7:	b8 00 00 00 00       	mov    $0x0,%eax
   16adc:	b9 0a 00 00 00       	mov    $0xa,%ecx
   16ae1:	89 d7                	mov    %edx,%edi
   16ae3:	f3 ab                	rep stos %eax,%es:(%edi)
	int uv_offsets[N_ARGS] = { 0 };      // offsets into string buffer
   16ae5:	8d 95 38 ff ff ff    	lea    -0xc8(%ebp),%edx
   16aeb:	b8 00 00 00 00       	mov    $0x0,%eax
   16af0:	b9 0a 00 00 00       	mov    $0xa,%ecx
   16af5:	89 d7                	mov    %edx,%edi
   16af7:	f3 ab                	rep stos %eax,%es:(%edi)
	/*
	** IF the argument list given to us came from  user code, we need
	** to convert its address and the addresses it contains to kernel
	** VAs; otherwise, we can use them directly.
	*/
	const char **kv_args = args;
   16af9:	8b 45 10             	mov    0x10(%ebp),%eax
   16afc:	89 45 cc             	mov    %eax,-0x34(%ebp)

	while( kv_args[argc] != NULL ) {
   16aff:	eb 61                	jmp    16b62 <stack_setup+0xc5>
		kv_strs[argc] = args[argc];
   16b01:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b04:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   16b0b:	8b 45 10             	mov    0x10(%ebp),%eax
   16b0e:	01 d0                	add    %edx,%eax
   16b10:	8b 10                	mov    (%eax),%edx
   16b12:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b15:	89 54 85 88          	mov    %edx,-0x78(%ebp,%eax,4)
		strlengths[argc] = strlen( kv_strs[argc] ) + 1;
   16b19:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b1c:	8b 44 85 88          	mov    -0x78(%ebp,%eax,4),%eax
   16b20:	83 ec 0c             	sub    $0xc,%esp
   16b23:	50                   	push   %eax
   16b24:	e8 4b bf ff ff       	call   12a74 <strlen>
   16b29:	83 c4 10             	add    $0x10,%esp
   16b2c:	83 c0 01             	add    $0x1,%eax
   16b2f:	89 c2                	mov    %eax,%edx
   16b31:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b34:	89 94 85 60 ff ff ff 	mov    %edx,-0xa0(%ebp,%eax,4)
		// can't go over one page in size
		if( (argbytes + strlengths[argc]) > SZ_PAGE ) {
   16b3b:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b3e:	8b 94 85 60 ff ff ff 	mov    -0xa0(%ebp,%eax,4),%edx
   16b45:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   16b48:	01 d0                	add    %edx,%eax
   16b4a:	3d 00 10 00 00       	cmp    $0x1000,%eax
   16b4f:	7f 28                	jg     16b79 <stack_setup+0xdc>
			// oops - ignore this and any others
			break;
		}
		argbytes += strlengths[argc];
   16b51:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b54:	8b 84 85 60 ff ff ff 	mov    -0xa0(%ebp,%eax,4),%eax
   16b5b:	01 45 d4             	add    %eax,-0x2c(%ebp)
		++argc;
   16b5e:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
	while( kv_args[argc] != NULL ) {
   16b62:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b65:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   16b6c:	8b 45 cc             	mov    -0x34(%ebp),%eax
   16b6f:	01 d0                	add    %edx,%eax
   16b71:	8b 00                	mov    (%eax),%eax
   16b73:	85 c0                	test   %eax,%eax
   16b75:	75 8a                	jne    16b01 <stack_setup+0x64>
   16b77:	eb 01                	jmp    16b7a <stack_setup+0xdd>
			break;
   16b79:	90                   	nop
	}

	// Round up the byte count to the next multiple of four.
	argbytes = (argbytes + 3) & MOD4_MASK;
   16b7a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   16b7d:	83 c0 03             	add    $0x3,%eax
   16b80:	83 e0 fc             	and    $0xfffffffc,%eax
   16b83:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	** We don't know where the argument strings actually live; they
	** could be inside the stack of a process that called exec(), so
	** we can't run the risk of overwriting them. Copy them into our
	** own address space.
	*/
	char argstrings[ argbytes ];
   16b86:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
   16b89:	89 e0                	mov    %esp,%eax
   16b8b:	89 c3                	mov    %eax,%ebx
   16b8d:	8d 41 ff             	lea    -0x1(%ecx),%eax
   16b90:	89 45 c8             	mov    %eax,-0x38(%ebp)
   16b93:	89 ca                	mov    %ecx,%edx
   16b95:	b8 10 00 00 00       	mov    $0x10,%eax
   16b9a:	83 e8 01             	sub    $0x1,%eax
   16b9d:	01 d0                	add    %edx,%eax
   16b9f:	be 10 00 00 00       	mov    $0x10,%esi
   16ba4:	ba 00 00 00 00       	mov    $0x0,%edx
   16ba9:	f7 f6                	div    %esi
   16bab:	6b c0 10             	imul   $0x10,%eax,%eax
   16bae:	29 c4                	sub    %eax,%esp
   16bb0:	89 e0                	mov    %esp,%eax
   16bb2:	83 c0 00             	add    $0x0,%eax
   16bb5:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	CLEAR( argstrings );
   16bb8:	89 ca                	mov    %ecx,%edx
   16bba:	8b 45 c4             	mov    -0x3c(%ebp),%eax
   16bbd:	83 ec 08             	sub    $0x8,%esp
   16bc0:	52                   	push   %edx
   16bc1:	50                   	push   %eax
   16bc2:	e8 ad b9 ff ff       	call   12574 <memclr>
   16bc7:	83 c4 10             	add    $0x10,%esp

	char *tmp = argstrings;
   16bca:	8b 45 c4             	mov    -0x3c(%ebp),%eax
   16bcd:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for( int i = 0; i < argc; ++i ) {
   16bd0:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
   16bd7:	eb 3b                	jmp    16c14 <stack_setup+0x177>
		// do the copy
		strcpy( tmp, kv_strs[i] );
   16bd9:	8b 45 e0             	mov    -0x20(%ebp),%eax
   16bdc:	8b 44 85 88          	mov    -0x78(%ebp,%eax,4),%eax
   16be0:	83 ec 08             	sub    $0x8,%esp
   16be3:	50                   	push   %eax
   16be4:	ff 75 dc             	pushl  -0x24(%ebp)
   16be7:	e8 5e be ff ff       	call   12a4a <strcpy>
   16bec:	83 c4 10             	add    $0x10,%esp
		// remember where this string begins in the buffer
		uv_offsets[i] = tmp - argstrings;
   16bef:	8b 45 dc             	mov    -0x24(%ebp),%eax
   16bf2:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   16bf5:	29 d0                	sub    %edx,%eax
   16bf7:	89 c2                	mov    %eax,%edx
   16bf9:	8b 45 e0             	mov    -0x20(%ebp),%eax
   16bfc:	89 94 85 38 ff ff ff 	mov    %edx,-0xc8(%ebp,%eax,4)
		// move to the next string position
		tmp += strlengths[i];
   16c03:	8b 45 e0             	mov    -0x20(%ebp),%eax
   16c06:	8b 84 85 60 ff ff ff 	mov    -0xa0(%ebp,%eax,4),%eax
   16c0d:	01 45 dc             	add    %eax,-0x24(%ebp)
	for( int i = 0; i < argc; ++i ) {
   16c10:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
   16c14:	8b 45 e0             	mov    -0x20(%ebp),%eax
   16c17:	3b 45 d8             	cmp    -0x28(%ebp),%eax
   16c1a:	7c bd                	jl     16bd9 <stack_setup+0x13c>
	** frame is in the first page directory entry. Extract that from the
	** entry and convert it into a virtual address for the kernel to use.
	*/
	// pointer to the first byte after the user stack
	uint32_t *kvptr = (uint32_t *)
		(((uint32_t)(pcb->stack)) + N_USTKPAGES * SZ_PAGE);
   16c1c:	8b 45 08             	mov    0x8(%ebp),%eax
   16c1f:	8b 40 04             	mov    0x4(%eax),%eax
   16c22:	05 00 20 00 00       	add    $0x2000,%eax
	uint32_t *kvptr = (uint32_t *)
   16c27:	89 45 c0             	mov    %eax,-0x40(%ebp)

	// put the buffer longword into the stack
	*--kvptr = 0;
   16c2a:	83 6d c0 04          	subl   $0x4,-0x40(%ebp)
   16c2e:	8b 45 c0             	mov    -0x40(%ebp),%eax
   16c31:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	/*
	** Move these pointers to where the string area will begin. We
	** will then back up to the next lower multiple-of-four address.
	*/
	uint32_t kvstrptr = ((uint32_t) kvptr) - argbytes;
   16c37:	8b 55 c0             	mov    -0x40(%ebp),%edx
   16c3a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   16c3d:	29 c2                	sub    %eax,%edx
   16c3f:	89 d0                	mov    %edx,%eax
   16c41:	89 45 bc             	mov    %eax,-0x44(%ebp)
	kvstrptr &= MOD4_MASK;
   16c44:	83 65 bc fc          	andl   $0xfffffffc,-0x44(%ebp)

	// Copy over the argv strings
	memmove( (void *) kvstrptr, (void *) argstrings, argbytes );
   16c48:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
   16c4b:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   16c4e:	8b 45 bc             	mov    -0x44(%ebp),%eax
   16c51:	83 ec 04             	sub    $0x4,%esp
   16c54:	51                   	push   %ecx
   16c55:	52                   	push   %edx
   16c56:	50                   	push   %eax
   16c57:	e8 66 b9 ff ff       	call   125c2 <memmove>
   16c5c:	83 c4 10             	add    $0x10,%esp
	** The space needed for argc, argv, and the argv array itself is
	** argc + 3 words (argc+1 for the argv entries, plus one word each
	** for argc and argv).  We back up that much from the string area.
	*/

	int nwords = argc + 3;
   16c5f:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16c62:	83 c0 03             	add    $0x3,%eax
   16c65:	89 45 b8             	mov    %eax,-0x48(%ebp)
	uint32_t *kvacptr = ((uint32_t *) kvstrptr) - nwords;
   16c68:	8b 45 b8             	mov    -0x48(%ebp),%eax
   16c6b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   16c72:	8b 45 bc             	mov    -0x44(%ebp),%eax
   16c75:	29 d0                	sub    %edx,%eax
   16c77:	89 45 b4             	mov    %eax,-0x4c(%ebp)

	// back these up to multiple-of-16 addresses for stack alignment
	kvacptr = (uint32_t *) ( ((uint32_t)kvacptr) & MOD16_MASK );
   16c7a:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16c7d:	83 e0 f0             	and    $0xfffffff0,%eax
   16c80:	89 45 b4             	mov    %eax,-0x4c(%ebp)

	// copy in 'argc'
	*kvacptr = argc;
   16c83:	8b 55 d8             	mov    -0x28(%ebp),%edx
   16c86:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16c89:	89 10                	mov    %edx,(%eax)
	cio_printf( "setup: argc '%d' @ %08x,", argc, (uint32_t) kvacptr );
#endif

	// 'argv' immediately follows 'argc', and 'argv[0]' immediately
	// follows 'argv'
	uint32_t *kvavptr = kvacptr + 2;
   16c8b:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16c8e:	83 c0 08             	add    $0x8,%eax
   16c91:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	*(kvavptr-1) = (uint32_t) kvavptr;
   16c94:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16c97:	8d 50 fc             	lea    -0x4(%eax),%edx
   16c9a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16c9d:	89 02                	mov    %eax,(%edx)
	cio_printf( " argv '%08x' @ %08x,", (uint32_t) kvavptr,
			(uint32_t) (kvavptr - 1) );
#endif

	// now, the argv entries themselves
	for( int i = 0; i < argc; ++i ) {
   16c9f:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
   16ca6:	eb 20                	jmp    16cc8 <stack_setup+0x22b>
		*kvavptr++ = (uint32_t) (kvstrptr + uv_offsets[i]);
   16ca8:	8b 45 d0             	mov    -0x30(%ebp),%eax
   16cab:	8b 84 85 38 ff ff ff 	mov    -0xc8(%ebp,%eax,4),%eax
   16cb2:	89 c1                	mov    %eax,%ecx
   16cb4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16cb7:	8d 50 04             	lea    0x4(%eax),%edx
   16cba:	89 55 e4             	mov    %edx,-0x1c(%ebp)
   16cbd:	8b 55 bc             	mov    -0x44(%ebp),%edx
   16cc0:	01 ca                	add    %ecx,%edx
   16cc2:	89 10                	mov    %edx,(%eax)
	for( int i = 0; i < argc; ++i ) {
   16cc4:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
   16cc8:	8b 45 d0             	mov    -0x30(%ebp),%eax
   16ccb:	3b 45 d8             	cmp    -0x28(%ebp),%eax
   16cce:	7c d8                	jl     16ca8 <stack_setup+0x20b>
		(uint32_t) (kvavptr-1) );
#endif
	}

	// and the trailing NULL
	*kvavptr = NULL;
   16cd0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16cd3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#if TRACING_STACK
	cio_printf( " NULL @ %08x,", (uint32_t) kvavptr );
#endif

	// push the fake return address right above 'argc' on the stack
	*--kvacptr = (uint32_t) fake_exit;
   16cd9:	83 6d b4 04          	subl   $0x4,-0x4c(%ebp)
   16cdd:	ba 88 6f 01 00       	mov    $0x16f88,%edx
   16ce2:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16ce5:	89 10                	mov    %edx,(%eax)
	** the interrupt "returns" to the entry point of the process.
	*/

	// Locate the context save area on the stack by backup up one
	// "context" from where the argc value is saved
	context_t *kvctx = ((context_t *) kvacptr) - 1;
   16ce7:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16cea:	83 e8 48             	sub    $0x48,%eax
   16ced:	89 45 b0             	mov    %eax,-0x50(%ebp)
	** as the 'popa' that restores the general registers doesn't
	** actually restore ESP from the context area - it leaves it
	** where it winds up.
	*/

	kvctx->eflags = DEFAULT_EFLAGS;    // IF enabled, IOPL 0
   16cf0:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16cf3:	c7 40 44 02 02 00 00 	movl   $0x202,0x44(%eax)
	kvctx->eip = entry;                // initial EIP
   16cfa:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16cfd:	8b 55 0c             	mov    0xc(%ebp),%edx
   16d00:	89 50 3c             	mov    %edx,0x3c(%eax)
	kvctx->cs = GDT_CODE;              // segment registers
   16d03:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d06:	c7 40 40 10 00 00 00 	movl   $0x10,0x40(%eax)
	kvctx->ss = GDT_STACK;
   16d0d:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d10:	c7 00 20 00 00 00    	movl   $0x20,(%eax)
	kvctx->ds = kvctx->es = kvctx->fs = kvctx->gs = GDT_DATA;
   16d16:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d19:	c7 40 04 18 00 00 00 	movl   $0x18,0x4(%eax)
   16d20:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d23:	8b 50 04             	mov    0x4(%eax),%edx
   16d26:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d29:	89 50 08             	mov    %edx,0x8(%eax)
   16d2c:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d2f:	8b 50 08             	mov    0x8(%eax),%edx
   16d32:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d35:	89 50 0c             	mov    %edx,0xc(%eax)
   16d38:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d3b:	8b 50 0c             	mov    0xc(%eax),%edx
   16d3e:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d41:	89 50 10             	mov    %edx,0x10(%eax)
	/*
	** Return the new context pointer to the caller as a user
	** space virtual address.
	*/
	
	return kvctx;
   16d44:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d47:	89 dc                	mov    %ebx,%esp
}
   16d49:	8d 65 f4             	lea    -0xc(%ebp),%esp
   16d4c:	5b                   	pop    %ebx
   16d4d:	5e                   	pop    %esi
   16d4e:	5f                   	pop    %edi
   16d4f:	5d                   	pop    %ebp
   16d50:	c3                   	ret    

00016d51 <user_init>:
/**
** Name:	user_init
**
** Initializes the user support module.
*/
void user_init( void ) {
   16d51:	55                   	push   %ebp
   16d52:	89 e5                	mov    %esp,%ebp
   16d54:	83 ec 08             	sub    $0x8,%esp

#if TRACING_INIT
	cio_puts( " User" );
   16d57:	83 ec 0c             	sub    $0xc,%esp
   16d5a:	68 a0 ba 01 00       	push   $0x1baa0
   16d5f:	e8 49 a1 ff ff       	call   10ead <cio_puts>
   16d64:	83 c4 10             	add    $0x10,%esp
#endif 

	// really not much to do here any more....
}
   16d67:	90                   	nop
   16d68:	c9                   	leave  
   16d69:	c3                   	ret    

00016d6a <user_cleanup>:
** "Unloads" a user program. Deallocates all memory frames and
** cleans up the VM structures.
**
** @param pcb   The PCB of the program to be unloaded
*/
void user_cleanup( pcb_t *pcb ) {
   16d6a:	55                   	push   %ebp
   16d6b:	89 e5                	mov    %esp,%ebp
   16d6d:	83 ec 08             	sub    $0x8,%esp

#if TRACING_USER
	cio_printf( "Uclean: %08x\n", (uint32_t) pcb );
#endif
	
	if( pcb == NULL ) {
   16d70:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16d74:	74 1b                	je     16d91 <user_cleanup+0x27>
		// should this be an error?
		return;
	}

	// free the stack pages
	pcb_stack_free( pcb->stack, pcb->stkpgs );
   16d76:	8b 45 08             	mov    0x8(%ebp),%eax
   16d79:	8b 50 28             	mov    0x28(%eax),%edx
   16d7c:	8b 45 08             	mov    0x8(%ebp),%eax
   16d7f:	8b 40 04             	mov    0x4(%eax),%eax
   16d82:	83 ec 08             	sub    $0x8,%esp
   16d85:	52                   	push   %edx
   16d86:	50                   	push   %eax
   16d87:	e8 0e cc ff ff       	call   1399a <pcb_stack_free>
   16d8c:	83 c4 10             	add    $0x10,%esp
   16d8f:	eb 01                	jmp    16d92 <user_cleanup+0x28>
		return;
   16d91:	90                   	nop
}
   16d92:	c9                   	leave  
   16d93:	c3                   	ret    

00016d94 <pci_read_config>:
#include <drivers/intel_8255x.h>
#include <types.h>
#include <x86/ops.h>
#include <cio.h>

static uint32_t pci_read_config(int bus, int device, int func, int offset) {
   16d94:	55                   	push   %ebp
   16d95:	89 e5                	mov    %esp,%ebp
   16d97:	83 ec 20             	sub    $0x20,%esp
  uint32_t address =
      (1 << 31)          /* Enable bit */
      | (bus << 16)      /* Bus number */
   16d9a:	8b 45 08             	mov    0x8(%ebp),%eax
   16d9d:	c1 e0 10             	shl    $0x10,%eax
   16da0:	0d 00 00 00 80       	or     $0x80000000,%eax
   16da5:	89 c2                	mov    %eax,%edx
      | (device << 11)   /* Device number */
   16da7:	8b 45 0c             	mov    0xc(%ebp),%eax
   16daa:	c1 e0 0b             	shl    $0xb,%eax
   16dad:	09 c2                	or     %eax,%edx
      | (func << 8)      /* Function number */
   16daf:	8b 45 10             	mov    0x10(%ebp),%eax
   16db2:	c1 e0 08             	shl    $0x8,%eax
   16db5:	09 c2                	or     %eax,%edx
      | (offset & 0xFC); /* Register number (must be 4-byte aligned) */
   16db7:	8b 45 14             	mov    0x14(%ebp),%eax
   16dba:	25 fc 00 00 00       	and    $0xfc,%eax
   16dbf:	09 d0                	or     %edx,%eax
  uint32_t address =
   16dc1:	89 45 fc             	mov    %eax,-0x4(%ebp)
   16dc4:	c7 45 f0 f8 0c 00 00 	movl   $0xcf8,-0x10(%ebp)
   16dcb:	8b 45 fc             	mov    -0x4(%ebp),%eax
   16dce:	89 45 ec             	mov    %eax,-0x14(%ebp)
}

OPSINLINED static inline void
outl( int port, uint32_t data )
{
	__asm__ __volatile__( "outl %0,%w1" : : "a" (data), "d" (port) );
   16dd1:	8b 45 ec             	mov    -0x14(%ebp),%eax
   16dd4:	8b 55 f0             	mov    -0x10(%ebp),%edx
   16dd7:	ef                   	out    %eax,(%dx)
   16dd8:	c7 45 f8 fc 0c 00 00 	movl   $0xcfc,-0x8(%ebp)
	__asm__ __volatile__( "inl %w1,%0" : "=a" (data) : "d" (port) );
   16ddf:	8b 45 f8             	mov    -0x8(%ebp),%eax
   16de2:	89 c2                	mov    %eax,%edx
   16de4:	ed                   	in     (%dx),%eax
   16de5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return data;
   16de8:	8b 45 f4             	mov    -0xc(%ebp),%eax

  outl(0xCF8, address); /* Write address to PCI config space */
  return inl(0xCFC);    /* Read data from PCI config space */
   16deb:	90                   	nop
}
   16dec:	c9                   	leave  
   16ded:	c3                   	ret    

00016dee <detect_intel_8255x>:

int detect_intel_8255x() {
   16dee:	55                   	push   %ebp
   16def:	89 e5                	mov    %esp,%ebp
   16df1:	83 ec 38             	sub    $0x38,%esp
  int bus;
  int dev;
  int func;
  uint32_t val;
  int found = 0;
   16df4:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  /* Set up the function pointers */
  // e100_state.dev.read = xv6_read;
  // e100_state.dev.write = xv6_write;

  /* Search PCI bus for Intel 8255x device */
  for (bus = 0; bus < 256 && !found; bus++) {
   16dfb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   16e02:	e9 ef 00 00 00       	jmp    16ef6 <detect_intel_8255x+0x108>
    for (dev = 0; dev < 32 && !found; dev++) {
   16e07:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   16e0e:	e9 cf 00 00 00       	jmp    16ee2 <detect_intel_8255x+0xf4>
      for (func = 0; func < 8 && !found; func++) {
   16e13:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   16e1a:	e9 af 00 00 00       	jmp    16ece <detect_intel_8255x+0xe0>
        val = pci_read_config(bus, dev, func, 0);
   16e1f:	6a 00                	push   $0x0
   16e21:	ff 75 ec             	pushl  -0x14(%ebp)
   16e24:	ff 75 f0             	pushl  -0x10(%ebp)
   16e27:	ff 75 f4             	pushl  -0xc(%ebp)
   16e2a:	e8 65 ff ff ff       	call   16d94 <pci_read_config>
   16e2f:	83 c4 10             	add    $0x10,%esp
   16e32:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        if ((val & 0xFFFF) == 0x8086) { /* Intel vendor ID */
   16e35:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16e38:	0f b7 c0             	movzwl %ax,%eax
   16e3b:	3d 86 80 00 00       	cmp    $0x8086,%eax
   16e40:	0f 85 84 00 00 00    	jne    16eca <detect_intel_8255x+0xdc>
          uint16_t device_id = (val >> 16) & 0xFFFF;
   16e46:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16e49:	c1 e8 10             	shr    $0x10,%eax
   16e4c:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)

          if (device_id == 0x1227 || /* 82557 */
   16e50:	66 81 7d e2 27 12    	cmpw   $0x1227,-0x1e(%ebp)
   16e56:	74 08                	je     16e60 <detect_intel_8255x+0x72>
   16e58:	66 81 7d e2 29 12    	cmpw   $0x1229,-0x1e(%ebp)
   16e5e:	75 6a                	jne    16eca <detect_intel_8255x+0xdc>
              device_id == 0x1229) { /* 82559 */
                cio_printf("e100: found Intel 8255x at bus %d, device %d, function %d\n", bus, dev, func);
   16e60:	ff 75 ec             	pushl  -0x14(%ebp)
   16e63:	ff 75 f0             	pushl  -0x10(%ebp)
   16e66:	ff 75 f4             	pushl  -0xc(%ebp)
   16e69:	68 a8 ba 01 00       	push   $0x1baa8
   16e6e:	e8 b4 a6 ff ff       	call   11527 <cio_printf>
   16e73:	83 c4 10             	add    $0x10,%esp

                // Get I/O base address
                uint32_t io_bar = pci_read_config(bus, dev, func, 0x10);
   16e76:	6a 10                	push   $0x10
   16e78:	ff 75 ec             	pushl  -0x14(%ebp)
   16e7b:	ff 75 f0             	pushl  -0x10(%ebp)
   16e7e:	ff 75 f4             	pushl  -0xc(%ebp)
   16e81:	e8 0e ff ff ff       	call   16d94 <pci_read_config>
   16e86:	83 c4 10             	add    $0x10,%esp
   16e89:	89 45 dc             	mov    %eax,-0x24(%ebp)
                uint32_t io_base = io_bar & ~0x3; /* Mask off the low bits */
   16e8c:	8b 45 dc             	mov    -0x24(%ebp),%eax
   16e8f:	83 e0 fc             	and    $0xfffffffc,%eax
   16e92:	89 45 d8             	mov    %eax,-0x28(%ebp)

                // Get interrupt line
                uint8_t irq = pci_read_config(bus, dev, func, 0x3C) & 0xFF;
   16e95:	6a 3c                	push   $0x3c
   16e97:	ff 75 ec             	pushl  -0x14(%ebp)
   16e9a:	ff 75 f0             	pushl  -0x10(%ebp)
   16e9d:	ff 75 f4             	pushl  -0xc(%ebp)
   16ea0:	e8 ef fe ff ff       	call   16d94 <pci_read_config>
   16ea5:	83 c4 10             	add    $0x10,%esp
   16ea8:	88 45 d7             	mov    %al,-0x29(%ebp)
                cio_printf("e100: I/O base = 0x%x, IRQ = %d\n", io_base, irq);
   16eab:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
   16eaf:	83 ec 04             	sub    $0x4,%esp
   16eb2:	50                   	push   %eax
   16eb3:	ff 75 d8             	pushl  -0x28(%ebp)
   16eb6:	68 e4 ba 01 00       	push   $0x1bae4
   16ebb:	e8 67 a6 ff ff       	call   11527 <cio_printf>
   16ec0:	83 c4 10             	add    $0x10,%esp

                return 0;
   16ec3:	b8 00 00 00 00       	mov    $0x0,%eax
   16ec8:	eb 3f                	jmp    16f09 <detect_intel_8255x+0x11b>
      for (func = 0; func < 8 && !found; func++) {
   16eca:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   16ece:	83 7d ec 07          	cmpl   $0x7,-0x14(%ebp)
   16ed2:	7f 0a                	jg     16ede <detect_intel_8255x+0xf0>
   16ed4:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   16ed8:	0f 84 41 ff ff ff    	je     16e1f <detect_intel_8255x+0x31>
    for (dev = 0; dev < 32 && !found; dev++) {
   16ede:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   16ee2:	83 7d f0 1f          	cmpl   $0x1f,-0x10(%ebp)
   16ee6:	7f 0a                	jg     16ef2 <detect_intel_8255x+0x104>
   16ee8:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   16eec:	0f 84 21 ff ff ff    	je     16e13 <detect_intel_8255x+0x25>
  for (bus = 0; bus < 256 && !found; bus++) {
   16ef2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   16ef6:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
   16efd:	7f 0a                	jg     16f09 <detect_intel_8255x+0x11b>
   16eff:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   16f03:	0f 84 fe fe ff ff    	je     16e07 <detect_intel_8255x+0x19>
          }
        }
      }
    }
  }
}
   16f09:	c9                   	leave  
   16f0a:	c3                   	ret    

00016f0b <intel_8255x_init>:

int intel_8255x_init(void) { return detect_intel_8255x(); }
   16f0b:	55                   	push   %ebp
   16f0c:	89 e5                	mov    %esp,%ebp
   16f0e:	83 ec 08             	sub    $0x8,%esp
   16f11:	e8 d8 fe ff ff       	call   16dee <detect_intel_8255x>
   16f16:	c9                   	leave  
   16f17:	c3                   	ret    

00016f18 <exit>:

/*
** "real" system calls
*/

SYSCALL(exit)
   16f18:	b8 00 00 00 00       	mov    $0x0,%eax
   16f1d:	cd 80                	int    $0x80
   16f1f:	c3                   	ret    

00016f20 <waitpid>:
SYSCALL(waitpid)
   16f20:	b8 01 00 00 00       	mov    $0x1,%eax
   16f25:	cd 80                	int    $0x80
   16f27:	c3                   	ret    

00016f28 <fork>:
SYSCALL(fork)
   16f28:	b8 02 00 00 00       	mov    $0x2,%eax
   16f2d:	cd 80                	int    $0x80
   16f2f:	c3                   	ret    

00016f30 <exec>:
SYSCALL(exec)
   16f30:	b8 03 00 00 00       	mov    $0x3,%eax
   16f35:	cd 80                	int    $0x80
   16f37:	c3                   	ret    

00016f38 <read>:
SYSCALL(read)
   16f38:	b8 04 00 00 00       	mov    $0x4,%eax
   16f3d:	cd 80                	int    $0x80
   16f3f:	c3                   	ret    

00016f40 <write>:
SYSCALL(write)
   16f40:	b8 05 00 00 00       	mov    $0x5,%eax
   16f45:	cd 80                	int    $0x80
   16f47:	c3                   	ret    

00016f48 <getpid>:
SYSCALL(getpid)
   16f48:	b8 06 00 00 00       	mov    $0x6,%eax
   16f4d:	cd 80                	int    $0x80
   16f4f:	c3                   	ret    

00016f50 <getppid>:
SYSCALL(getppid)
   16f50:	b8 07 00 00 00       	mov    $0x7,%eax
   16f55:	cd 80                	int    $0x80
   16f57:	c3                   	ret    

00016f58 <gettime>:
SYSCALL(gettime)
   16f58:	b8 08 00 00 00       	mov    $0x8,%eax
   16f5d:	cd 80                	int    $0x80
   16f5f:	c3                   	ret    

00016f60 <getprio>:
SYSCALL(getprio)
   16f60:	b8 09 00 00 00       	mov    $0x9,%eax
   16f65:	cd 80                	int    $0x80
   16f67:	c3                   	ret    

00016f68 <setprio>:
SYSCALL(setprio)
   16f68:	b8 0a 00 00 00       	mov    $0xa,%eax
   16f6d:	cd 80                	int    $0x80
   16f6f:	c3                   	ret    

00016f70 <kill>:
SYSCALL(kill)
   16f70:	b8 0b 00 00 00       	mov    $0xb,%eax
   16f75:	cd 80                	int    $0x80
   16f77:	c3                   	ret    

00016f78 <sleep>:
SYSCALL(sleep)
   16f78:	b8 0c 00 00 00       	mov    $0xc,%eax
   16f7d:	cd 80                	int    $0x80
   16f7f:	c3                   	ret    

00016f80 <bogus>:

/*
** This is a bogus system call; it's here so that we can test
** our handling of out-of-range syscall codes in the syscall ISR.
*/
SYSCALL(bogus)
   16f80:	b8 ad 0b 00 00       	mov    $0xbad,%eax
   16f85:	cd 80                	int    $0x80
   16f87:	c3                   	ret    

00016f88 <fake_exit>:
*/

	.globl	fake_exit
fake_exit:
	// alternate: could push a "fake exit" status
	pushl	%eax	// termination status returned by main()
   16f88:	50                   	push   %eax
	call	exit	// terminate this process
   16f89:	e8 8a ff ff ff       	call   16f18 <exit>

00016f8e <idle>:
** when there is no other process to dispatch.
**
** Invoked as:	idle
*/

USERMAIN( idle ) {
   16f8e:	55                   	push   %ebp
   16f8f:	89 e5                	mov    %esp,%ebp
   16f91:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char ch = '.';
#endif

	// ignore the command-line arguments
	(void) argc;
	char *name = argv[0] ? argv[0] : "nobody";
   16f97:	8b 45 0c             	mov    0xc(%ebp),%eax
   16f9a:	8b 00                	mov    (%eax),%eax
   16f9c:	85 c0                	test   %eax,%eax
   16f9e:	74 07                	je     16fa7 <idle+0x19>
   16fa0:	8b 45 0c             	mov    0xc(%ebp),%eax
   16fa3:	8b 00                	mov    (%eax),%eax
   16fa5:	eb 05                	jmp    16fac <idle+0x1e>
   16fa7:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   16fac:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// get some current information
	uint_t pid = getpid();
   16faf:	e8 94 ff ff ff       	call   16f48 <getpid>
   16fb4:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32_t now = gettime();
   16fb7:	e8 9c ff ff ff       	call   16f58 <gettime>
   16fbc:	89 45 e8             	mov    %eax,-0x18(%ebp)
	enum priority_e prio = getprio();
   16fbf:	e8 9c ff ff ff       	call   16f60 <getprio>
   16fc4:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	char buf[128];
	usprint( buf, "%s [%d], started @ %u\n", name, pid, prio, now );
   16fc7:	83 ec 08             	sub    $0x8,%esp
   16fca:	ff 75 e8             	pushl  -0x18(%ebp)
   16fcd:	ff 75 e4             	pushl  -0x1c(%ebp)
   16fd0:	ff 75 ec             	pushl  -0x14(%ebp)
   16fd3:	ff 75 f0             	pushl  -0x10(%ebp)
   16fd6:	68 0f bb 01 00       	push   $0x1bb0f
   16fdb:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
   16fe1:	50                   	push   %eax
   16fe2:	e8 db 2c 00 00       	call   19cc2 <usprint>
   16fe7:	83 c4 20             	add    $0x20,%esp
	cwrites( buf );
   16fea:	83 ec 0c             	sub    $0xc,%esp
   16fed:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
   16ff3:	50                   	push   %eax
   16ff4:	e8 b6 33 00 00       	call   1a3af <cwrites>
   16ff9:	83 c4 10             	add    $0x10,%esp

	// idle() should never block - it must always be available
	// for dispatching when we need to pick a new current process

	for(;;) {
		DELAY(LONG);
   16ffc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   17003:	eb 04                	jmp    17009 <idle+0x7b>
   17005:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   17009:	81 7d f4 ff e0 f5 05 	cmpl   $0x5f5e0ff,-0xc(%ebp)
   17010:	7e f3                	jle    17005 <idle+0x77>
   17012:	eb e8                	jmp    16ffc <idle+0x6e>

00017014 <usage>:
};

/*
** usage function
*/
static void usage( void ) {
   17014:	55                   	push   %ebp
   17015:	89 e5                	mov    %esp,%ebp
   17017:	83 ec 18             	sub    $0x18,%esp
	swrites( "\nTests - run with '@x', where 'x' is one or more of:\n " );
   1701a:	83 ec 0c             	sub    $0xc,%esp
   1701d:	68 f4 bb 01 00       	push   $0x1bbf4
   17022:	e8 ee 33 00 00       	call   1a415 <swrites>
   17027:	83 c4 10             	add    $0x10,%esp
	proc_t *p = sh_spawn_table;
   1702a:	c7 45 f4 20 d1 01 00 	movl   $0x1d120,-0xc(%ebp)
	while( p->entry != TBLEND ) {
   17031:	eb 23                	jmp    17056 <usage+0x42>
		swritech( ' ' );
   17033:	83 ec 0c             	sub    $0xc,%esp
   17036:	6a 20                	push   $0x20
   17038:	e8 b7 33 00 00       	call   1a3f4 <swritech>
   1703d:	83 c4 10             	add    $0x10,%esp
		swritech( p->select[0] );
   17040:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17043:	0f b6 40 09          	movzbl 0x9(%eax),%eax
   17047:	0f be c0             	movsbl %al,%eax
   1704a:	83 ec 0c             	sub    $0xc,%esp
   1704d:	50                   	push   %eax
   1704e:	e8 a1 33 00 00       	call   1a3f4 <swritech>
   17053:	83 c4 10             	add    $0x10,%esp
	while( p->entry != TBLEND ) {
   17056:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17059:	8b 00                	mov    (%eax),%eax
   1705b:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   17060:	75 d1                	jne    17033 <usage+0x1f>
	}
	swrites( "\nOther commands: @* (all), @h (help), @x (exit)\n" );
   17062:	83 ec 0c             	sub    $0xc,%esp
   17065:	68 2c bc 01 00       	push   $0x1bc2c
   1706a:	e8 a6 33 00 00       	call   1a415 <swrites>
   1706f:	83 c4 10             	add    $0x10,%esp
}
   17072:	90                   	nop
   17073:	c9                   	leave  
   17074:	c3                   	ret    

00017075 <run>:

/*
** run a program from the program table, or a builtin command
*/
static int run( char which ) {
   17075:	55                   	push   %ebp
   17076:	89 e5                	mov    %esp,%ebp
   17078:	53                   	push   %ebx
   17079:	81 ec a4 00 00 00    	sub    $0xa4,%esp
   1707f:	8b 45 08             	mov    0x8(%ebp),%eax
   17082:	88 85 64 ff ff ff    	mov    %al,-0x9c(%ebp)
	char buf[128];
	register proc_t *p;

	if( which == 'h' ) {
   17088:	80 bd 64 ff ff ff 68 	cmpb   $0x68,-0x9c(%ebp)
   1708f:	75 0a                	jne    1709b <run+0x26>

		// builtin "help" command
		usage();
   17091:	e8 7e ff ff ff       	call   17014 <usage>
   17096:	e9 e0 00 00 00       	jmp    1717b <run+0x106>

	} else if( which == 'x' ) {
   1709b:	80 bd 64 ff ff ff 78 	cmpb   $0x78,-0x9c(%ebp)
   170a2:	75 0c                	jne    170b0 <run+0x3b>

		// builtin "exit" command
		time_to_stop = true;
   170a4:	c6 05 b4 f1 01 00 01 	movb   $0x1,0x1f1b4
   170ab:	e9 cb 00 00 00       	jmp    1717b <run+0x106>

	} else if( which == '*' ) {
   170b0:	80 bd 64 ff ff ff 2a 	cmpb   $0x2a,-0x9c(%ebp)
   170b7:	75 40                	jne    170f9 <run+0x84>

		// torture test! run everything!
		for( p = sh_spawn_table; p->entry != TBLEND; ++p ) {
   170b9:	bb 20 d1 01 00       	mov    $0x1d120,%ebx
   170be:	eb 2b                	jmp    170eb <run+0x76>
			int status = spawn( p->entry, p->args );
   170c0:	8d 53 0c             	lea    0xc(%ebx),%edx
   170c3:	8b 03                	mov    (%ebx),%eax
   170c5:	83 ec 08             	sub    $0x8,%esp
   170c8:	52                   	push   %edx
   170c9:	50                   	push   %eax
   170ca:	e8 4a 32 00 00       	call   1a319 <spawn>
   170cf:	83 c4 10             	add    $0x10,%esp
   170d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
			if( status > 0 ) {
   170d5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   170d9:	7e 0d                	jle    170e8 <run+0x73>
				++children;
   170db:	a1 b8 f1 01 00       	mov    0x1f1b8,%eax
   170e0:	83 c0 01             	add    $0x1,%eax
   170e3:	a3 b8 f1 01 00       	mov    %eax,0x1f1b8
		for( p = sh_spawn_table; p->entry != TBLEND; ++p ) {
   170e8:	83 c3 34             	add    $0x34,%ebx
   170eb:	8b 03                	mov    (%ebx),%eax
   170ed:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   170f2:	75 cc                	jne    170c0 <run+0x4b>
   170f4:	e9 82 00 00 00       	jmp    1717b <run+0x106>
		}

	} else {

		// must be a single test; find and run it
		for( p = sh_spawn_table; p->entry != TBLEND; ++p ) {
   170f9:	bb 20 d1 01 00       	mov    $0x1d120,%ebx
   170fe:	eb 3c                	jmp    1713c <run+0xc7>
			if( p->select[0] == which ) {
   17100:	0f b6 43 09          	movzbl 0x9(%ebx),%eax
   17104:	38 85 64 ff ff ff    	cmp    %al,-0x9c(%ebp)
   1710a:	75 2d                	jne    17139 <run+0xc4>
				// found it!
				int status = spawn( p->entry, p->args );
   1710c:	8d 53 0c             	lea    0xc(%ebx),%edx
   1710f:	8b 03                	mov    (%ebx),%eax
   17111:	83 ec 08             	sub    $0x8,%esp
   17114:	52                   	push   %edx
   17115:	50                   	push   %eax
   17116:	e8 fe 31 00 00       	call   1a319 <spawn>
   1711b:	83 c4 10             	add    $0x10,%esp
   1711e:	89 45 f4             	mov    %eax,-0xc(%ebp)
				if( status > 0 ) {
   17121:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   17125:	7e 0d                	jle    17134 <run+0xbf>
					++children;
   17127:	a1 b8 f1 01 00       	mov    0x1f1b8,%eax
   1712c:	83 c0 01             	add    $0x1,%eax
   1712f:	a3 b8 f1 01 00       	mov    %eax,0x1f1b8
				}
				return status;
   17134:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17137:	eb 47                	jmp    17180 <run+0x10b>
		for( p = sh_spawn_table; p->entry != TBLEND; ++p ) {
   17139:	83 c3 34             	add    $0x34,%ebx
   1713c:	8b 03                	mov    (%ebx),%eax
   1713e:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   17143:	75 bb                	jne    17100 <run+0x8b>
			}
		}

		// uh-oh, made it through the table without finding the program
		usprint( buf, "shell: unknown cmd '%c'\n", which );
   17145:	0f be 85 64 ff ff ff 	movsbl -0x9c(%ebp),%eax
   1714c:	83 ec 04             	sub    $0x4,%esp
   1714f:	50                   	push   %eax
   17150:	68 5d bc 01 00       	push   $0x1bc5d
   17155:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
   1715b:	50                   	push   %eax
   1715c:	e8 61 2b 00 00       	call   19cc2 <usprint>
   17161:	83 c4 10             	add    $0x10,%esp
		swrites( buf );
   17164:	83 ec 0c             	sub    $0xc,%esp
   17167:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
   1716d:	50                   	push   %eax
   1716e:	e8 a2 32 00 00       	call   1a415 <swrites>
   17173:	83 c4 10             	add    $0x10,%esp
		usage();
   17176:	e8 99 fe ff ff       	call   17014 <usage>
	}

	return 0;
   1717b:	b8 00 00 00 00       	mov    $0x0,%eax
}
   17180:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   17183:	c9                   	leave  
   17184:	c3                   	ret    

00017185 <edit>:
** edit - perform any command-line editing we need to do
**
** @param line   Input line buffer
** @param n      Number of valid bytes in the buffer
*/
static int edit( char line[], int n ) {
   17185:	55                   	push   %ebp
   17186:	89 e5                	mov    %esp,%ebp
   17188:	83 ec 10             	sub    $0x10,%esp
	char *ptr = line + n - 1;	// last char in buffer
   1718b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1718e:	8d 50 ff             	lea    -0x1(%eax),%edx
   17191:	8b 45 08             	mov    0x8(%ebp),%eax
   17194:	01 d0                	add    %edx,%eax
   17196:	89 45 fc             	mov    %eax,-0x4(%ebp)

	// strip the EOLN sequence
	while( n > 0 ) {
   17199:	eb 18                	jmp    171b3 <edit+0x2e>
		if( *ptr == '\n' || *ptr == '\r' ) {
   1719b:	8b 45 fc             	mov    -0x4(%ebp),%eax
   1719e:	0f b6 00             	movzbl (%eax),%eax
   171a1:	3c 0a                	cmp    $0xa,%al
   171a3:	74 0a                	je     171af <edit+0x2a>
   171a5:	8b 45 fc             	mov    -0x4(%ebp),%eax
   171a8:	0f b6 00             	movzbl (%eax),%eax
   171ab:	3c 0d                	cmp    $0xd,%al
   171ad:	75 0a                	jne    171b9 <edit+0x34>
			--n;
   171af:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
	while( n > 0 ) {
   171b3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   171b7:	7f e2                	jg     1719b <edit+0x16>
			break;
		}
	}

	// add a trailing NUL byte
	if( n > 0 ) {
   171b9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   171bd:	7e 0b                	jle    171ca <edit+0x45>
		line[n] = '\0';
   171bf:	8b 55 0c             	mov    0xc(%ebp),%edx
   171c2:	8b 45 08             	mov    0x8(%ebp),%eax
   171c5:	01 d0                	add    %edx,%eax
   171c7:	c6 00 00             	movb   $0x0,(%eax)
	}

	return n;
   171ca:	8b 45 0c             	mov    0xc(%ebp),%eax
}
   171cd:	c9                   	leave  
   171ce:	c3                   	ret    

000171cf <shell>:
** shell - extremely simple shell for spawning test programs
**
** Scheduled by _kshell() when the character 'u' is typed on
** the console keyboard.
*/
USERMAIN( shell ) {
   171cf:	55                   	push   %ebp
   171d0:	89 e5                	mov    %esp,%ebp
   171d2:	81 ec 28 01 00 00    	sub    $0x128,%esp
	char line[128];

	// keep the compiler happy
	(void) argc;
	char *name = argv[0] ? argv[0] : "nobody";
   171d8:	8b 45 0c             	mov    0xc(%ebp),%eax
   171db:	8b 00                	mov    (%eax),%eax
   171dd:	85 c0                	test   %eax,%eax
   171df:	74 07                	je     171e8 <shell+0x19>
   171e1:	8b 45 0c             	mov    0xc(%ebp),%eax
   171e4:	8b 00                	mov    (%eax),%eax
   171e6:	eb 05                	jmp    171ed <shell+0x1e>
   171e8:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   171ed:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// report that we're up and running
	usprint( line, "%s is ready\n", name );
   171f0:	83 ec 04             	sub    $0x4,%esp
   171f3:	ff 75 ec             	pushl  -0x14(%ebp)
   171f6:	68 76 bc 01 00       	push   $0x1bc76
   171fb:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17201:	50                   	push   %eax
   17202:	e8 bb 2a 00 00       	call   19cc2 <usprint>
   17207:	83 c4 10             	add    $0x10,%esp
	swrites( line );
   1720a:	83 ec 0c             	sub    $0xc,%esp
   1720d:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17213:	50                   	push   %eax
   17214:	e8 fc 31 00 00       	call   1a415 <swrites>
   17219:	83 c4 10             	add    $0x10,%esp

	// print a summary of the commands we'll accept
	usage();
   1721c:	e8 f3 fd ff ff       	call   17014 <usage>

	// loop forever
	while( !time_to_stop ) {
   17221:	e9 a7 01 00 00       	jmp    173cd <shell+0x1fe>
		char *ptr;

		// the shell reads one line from the keyboard, parses it,
		// and performs whatever command it requests.

		swrites( "\n> " );
   17226:	83 ec 0c             	sub    $0xc,%esp
   17229:	68 83 bc 01 00       	push   $0x1bc83
   1722e:	e8 e2 31 00 00       	call   1a415 <swrites>
   17233:	83 c4 10             	add    $0x10,%esp
		int n = read( CHAN_SIO, line, sizeof(line) );
   17236:	83 ec 04             	sub    $0x4,%esp
   17239:	68 80 00 00 00       	push   $0x80
   1723e:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17244:	50                   	push   %eax
   17245:	6a 01                	push   $0x1
   17247:	e8 ec fc ff ff       	call   16f38 <read>
   1724c:	83 c4 10             	add    $0x10,%esp
   1724f:	89 45 e8             	mov    %eax,-0x18(%ebp)
		
		// shortest valid command is "@?", so must have 3+ chars here
		if( n < 3 ) {
   17252:	83 7d e8 02          	cmpl   $0x2,-0x18(%ebp)
   17256:	7f 05                	jg     1725d <shell+0x8e>
			// ignore it
			continue;
   17258:	e9 70 01 00 00       	jmp    173cd <shell+0x1fe>
		}

		// edit it as needed; new shortest command is 2+ chars
		if( (n=edit(line,n)) < 2 ) {
   1725d:	83 ec 08             	sub    $0x8,%esp
   17260:	ff 75 e8             	pushl  -0x18(%ebp)
   17263:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17269:	50                   	push   %eax
   1726a:	e8 16 ff ff ff       	call   17185 <edit>
   1726f:	83 c4 10             	add    $0x10,%esp
   17272:	89 45 e8             	mov    %eax,-0x18(%ebp)
   17275:	83 7d e8 01          	cmpl   $0x1,-0x18(%ebp)
   17279:	7f 05                	jg     17280 <shell+0xb1>
			continue;
   1727b:	e9 4d 01 00 00       	jmp    173cd <shell+0x1fe>
		}

		// find the '@'
		int i = 0;
   17280:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
		for( ptr = line; i < n; ++i, ++ptr ) {
   17287:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   1728d:	89 45 f4             	mov    %eax,-0xc(%ebp)
   17290:	eb 12                	jmp    172a4 <shell+0xd5>
			if( *ptr == '@' ) {
   17292:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17295:	0f b6 00             	movzbl (%eax),%eax
   17298:	3c 40                	cmp    $0x40,%al
   1729a:	74 12                	je     172ae <shell+0xdf>
		for( ptr = line; i < n; ++i, ++ptr ) {
   1729c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   172a0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   172a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
   172a7:	3b 45 e8             	cmp    -0x18(%ebp),%eax
   172aa:	7c e6                	jl     17292 <shell+0xc3>
   172ac:	eb 01                	jmp    172af <shell+0xe0>
				break;
   172ae:	90                   	nop
			}
		}

		// did we find an '@'?
		if( i < n ) {
   172af:	8b 45 f0             	mov    -0x10(%ebp),%eax
   172b2:	3b 45 e8             	cmp    -0x18(%ebp),%eax
   172b5:	0f 8d 12 01 00 00    	jge    173cd <shell+0x1fe>

			// yes; process any commands that follow it
			++ptr;
   172bb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

			for( ; *ptr != '\0'; ++ptr ) {
   172bf:	eb 66                	jmp    17327 <shell+0x158>
				char buf[128];
				int pid = run( *ptr );
   172c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
   172c4:	0f b6 00             	movzbl (%eax),%eax
   172c7:	0f be c0             	movsbl %al,%eax
   172ca:	83 ec 0c             	sub    $0xc,%esp
   172cd:	50                   	push   %eax
   172ce:	e8 a2 fd ff ff       	call   17075 <run>
   172d3:	83 c4 10             	add    $0x10,%esp
   172d6:	89 45 e4             	mov    %eax,-0x1c(%ebp)

				if( pid < 0 ) {
   172d9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   172dd:	79 39                	jns    17318 <shell+0x149>
					// spawn() failed
					usprint( buf, "+++ %s spawn %c failed, code %d\n",
							name, *ptr, pid );
   172df:	8b 45 f4             	mov    -0xc(%ebp),%eax
   172e2:	0f b6 00             	movzbl (%eax),%eax
					usprint( buf, "+++ %s spawn %c failed, code %d\n",
   172e5:	0f be c0             	movsbl %al,%eax
   172e8:	83 ec 0c             	sub    $0xc,%esp
   172eb:	ff 75 e4             	pushl  -0x1c(%ebp)
   172ee:	50                   	push   %eax
   172ef:	ff 75 ec             	pushl  -0x14(%ebp)
   172f2:	68 88 bc 01 00       	push   $0x1bc88
   172f7:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   172fd:	50                   	push   %eax
   172fe:	e8 bf 29 00 00       	call   19cc2 <usprint>
   17303:	83 c4 20             	add    $0x20,%esp
					cwrites( buf );
   17306:	83 ec 0c             	sub    $0xc,%esp
   17309:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   1730f:	50                   	push   %eax
   17310:	e8 9a 30 00 00       	call   1a3af <cwrites>
   17315:	83 c4 10             	add    $0x10,%esp
				}

				// should we end it all?
				if( time_to_stop ) {
   17318:	0f b6 05 b4 f1 01 00 	movzbl 0x1f1b4,%eax
   1731f:	84 c0                	test   %al,%al
   17321:	75 13                	jne    17336 <shell+0x167>
			for( ; *ptr != '\0'; ++ptr ) {
   17323:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   17327:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1732a:	0f b6 00             	movzbl (%eax),%eax
   1732d:	84 c0                	test   %al,%al
   1732f:	75 90                	jne    172c1 <shell+0xf2>
   17331:	e9 8a 00 00 00       	jmp    173c0 <shell+0x1f1>
					break;
   17336:	90                   	nop
				}
			} // for

			// now, wait for all the spawned children
			while( children > 0 ) {
   17337:	e9 84 00 00 00       	jmp    173c0 <shell+0x1f1>
				// wait for the child
				int32_t status;
				char buf[128];
				int whom = waitpid( 0, &status );
   1733c:	83 ec 08             	sub    $0x8,%esp
   1733f:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17345:	50                   	push   %eax
   17346:	6a 00                	push   $0x0
   17348:	e8 d3 fb ff ff       	call   16f20 <waitpid>
   1734d:	83 c4 10             	add    $0x10,%esp
   17350:	89 45 e0             	mov    %eax,-0x20(%ebp)

				// figure out the result
				if( whom == E_NO_CHILDREN ) {
   17353:	83 7d e0 fc          	cmpl   $0xfffffffc,-0x20(%ebp)
   17357:	75 02                	jne    1735b <shell+0x18c>
   17359:	eb 72                	jmp    173cd <shell+0x1fe>
					break;
				} else if( whom < 1 ) {
   1735b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   1735f:	7f 1c                	jg     1737d <shell+0x1ae>
					usprint( buf, "%s: waitpid() returned %d\n", name, whom );
   17361:	ff 75 e0             	pushl  -0x20(%ebp)
   17364:	ff 75 ec             	pushl  -0x14(%ebp)
   17367:	68 a9 bc 01 00       	push   $0x1bca9
   1736c:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   17372:	50                   	push   %eax
   17373:	e8 4a 29 00 00       	call   19cc2 <usprint>
   17378:	83 c4 10             	add    $0x10,%esp
   1737b:	eb 31                	jmp    173ae <shell+0x1df>
				} else {
					--children;
   1737d:	a1 b8 f1 01 00       	mov    0x1f1b8,%eax
   17382:	83 e8 01             	sub    $0x1,%eax
   17385:	a3 b8 f1 01 00       	mov    %eax,0x1f1b8
					usprint( buf, "%s: PID %d exit status %d\n",
   1738a:	8b 85 5c ff ff ff    	mov    -0xa4(%ebp),%eax
   17390:	83 ec 0c             	sub    $0xc,%esp
   17393:	50                   	push   %eax
   17394:	ff 75 e0             	pushl  -0x20(%ebp)
   17397:	ff 75 ec             	pushl  -0x14(%ebp)
   1739a:	68 c4 bc 01 00       	push   $0x1bcc4
   1739f:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   173a5:	50                   	push   %eax
   173a6:	e8 17 29 00 00       	call   19cc2 <usprint>
   173ab:	83 c4 20             	add    $0x20,%esp
							name, whom, status );
				}
				// report it
				swrites( buf );
   173ae:	83 ec 0c             	sub    $0xc,%esp
   173b1:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   173b7:	50                   	push   %eax
   173b8:	e8 58 30 00 00       	call   1a415 <swrites>
   173bd:	83 c4 10             	add    $0x10,%esp
			while( children > 0 ) {
   173c0:	a1 b8 f1 01 00       	mov    0x1f1b8,%eax
   173c5:	85 c0                	test   %eax,%eax
   173c7:	0f 8f 6f ff ff ff    	jg     1733c <shell+0x16d>
	while( !time_to_stop ) {
   173cd:	0f b6 05 b4 f1 01 00 	movzbl 0x1f1b4,%eax
   173d4:	84 c0                	test   %al,%al
   173d6:	0f 84 4a fe ff ff    	je     17226 <shell+0x57>
			}
		}  // if i < n
	}  // while

	cwrites( "!!! shell exited loop???\n" );
   173dc:	83 ec 0c             	sub    $0xc,%esp
   173df:	68 df bc 01 00       	push   $0x1bcdf
   173e4:	e8 c6 2f 00 00       	call   1a3af <cwrites>
   173e9:	83 c4 10             	add    $0x10,%esp
	exit( 1 );
   173ec:	83 ec 0c             	sub    $0xc,%esp
   173ef:	6a 01                	push   $0x1
   173f1:	e8 22 fb ff ff       	call   16f18 <exit>
   173f6:	83 c4 10             	add    $0x10,%esp

	// yeah, yeah....
	return( 0 );
   173f9:	b8 00 00 00 00       	mov    $0x0,%eax
}
   173fe:	c9                   	leave  
   173ff:	c3                   	ret    

00017400 <process>:
**
** @param proc  pointer to the spawn table entry to be used
*/

static void process( proc_t *proc )
{
   17400:	55                   	push   %ebp
   17401:	89 e5                	mov    %esp,%ebp
   17403:	81 ec 98 00 00 00    	sub    $0x98,%esp
	char buf[128];

	// kick off the process
	int32_t p = fork();
   17409:	e8 1a fb ff ff       	call   16f28 <fork>
   1740e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( p < 0 ) {
   17411:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   17415:	79 34                	jns    1744b <process+0x4b>

		// error!
		usprint( buf, "INIT: fork for #%d failed\n",
				(uint32_t) (proc->entry) );
   17417:	8b 45 08             	mov    0x8(%ebp),%eax
   1741a:	8b 00                	mov    (%eax),%eax
		usprint( buf, "INIT: fork for #%d failed\n",
   1741c:	83 ec 04             	sub    $0x4,%esp
   1741f:	50                   	push   %eax
   17420:	68 06 bd 01 00       	push   $0x1bd06
   17425:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
   1742b:	50                   	push   %eax
   1742c:	e8 91 28 00 00       	call   19cc2 <usprint>
   17431:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   17434:	83 ec 0c             	sub    $0xc,%esp
   17437:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
   1743d:	50                   	push   %eax
   1743e:	e8 6c 2f 00 00       	call   1a3af <cwrites>
   17443:	83 c4 10             	add    $0x10,%esp
		swritech( ch );

		proc->pid = p;

	}
}
   17446:	e9 84 00 00 00       	jmp    174cf <process+0xcf>
	} else if( p == 0 ) {
   1744b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1744f:	75 5f                	jne    174b0 <process+0xb0>
		(void) setprio( proc->e_prio );
   17451:	8b 45 08             	mov    0x8(%ebp),%eax
   17454:	0f b6 40 08          	movzbl 0x8(%eax),%eax
   17458:	0f b6 c0             	movzbl %al,%eax
   1745b:	83 ec 0c             	sub    $0xc,%esp
   1745e:	50                   	push   %eax
   1745f:	e8 04 fb ff ff       	call   16f68 <setprio>
   17464:	83 c4 10             	add    $0x10,%esp
		exec( proc->entry, proc->args );
   17467:	8b 45 08             	mov    0x8(%ebp),%eax
   1746a:	8d 50 0c             	lea    0xc(%eax),%edx
   1746d:	8b 45 08             	mov    0x8(%ebp),%eax
   17470:	8b 00                	mov    (%eax),%eax
   17472:	83 ec 08             	sub    $0x8,%esp
   17475:	52                   	push   %edx
   17476:	50                   	push   %eax
   17477:	e8 b4 fa ff ff       	call   16f30 <exec>
   1747c:	83 c4 10             	add    $0x10,%esp
				(uint32_t) (proc->entry) );
   1747f:	8b 45 08             	mov    0x8(%ebp),%eax
   17482:	8b 00                	mov    (%eax),%eax
		usprint( buf, "INIT: exec(0x%08x) failed\n",
   17484:	83 ec 04             	sub    $0x4,%esp
   17487:	50                   	push   %eax
   17488:	68 21 bd 01 00       	push   $0x1bd21
   1748d:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
   17493:	50                   	push   %eax
   17494:	e8 29 28 00 00       	call   19cc2 <usprint>
   17499:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   1749c:	83 ec 0c             	sub    $0xc,%esp
   1749f:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
   174a5:	50                   	push   %eax
   174a6:	e8 04 2f 00 00       	call   1a3af <cwrites>
   174ab:	83 c4 10             	add    $0x10,%esp
}
   174ae:	eb 1f                	jmp    174cf <process+0xcf>
		swritech( ch );
   174b0:	0f b6 05 3c d6 01 00 	movzbl 0x1d63c,%eax
   174b7:	0f be c0             	movsbl %al,%eax
   174ba:	83 ec 0c             	sub    $0xc,%esp
   174bd:	50                   	push   %eax
   174be:	e8 31 2f 00 00       	call   1a3f4 <swritech>
   174c3:	83 c4 10             	add    $0x10,%esp
		proc->pid = p;
   174c6:	8b 55 f4             	mov    -0xc(%ebp),%edx
   174c9:	8b 45 08             	mov    0x8(%ebp),%eax
   174cc:	89 50 04             	mov    %edx,0x4(%eax)
}
   174cf:	90                   	nop
   174d0:	c9                   	leave  
   174d1:	c3                   	ret    

000174d2 <init>:
/*
** The initial user process. Should be invoked with zero or one
** argument; if provided, the first argument should be the ASCII
** character 'init' will print to indicate the spawning of a process.
*/
USERMAIN( init ) {
   174d2:	55                   	push   %ebp
   174d3:	89 e5                	mov    %esp,%ebp
   174d5:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   174db:	8b 45 0c             	mov    0xc(%ebp),%eax
   174de:	8b 00                	mov    (%eax),%eax
   174e0:	85 c0                	test   %eax,%eax
   174e2:	74 07                	je     174eb <init+0x19>
   174e4:	8b 45 0c             	mov    0xc(%ebp),%eax
   174e7:	8b 00                	mov    (%eax),%eax
   174e9:	eb 05                	jmp    174f0 <init+0x1e>
   174eb:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   174f0:	89 45 e8             	mov    %eax,-0x18(%ebp)
	char buf[128];

	// check to see if we got a non-standard "spawn" character
	if( argc > 1 ) {
   174f3:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
   174f7:	7e 2d                	jle    17526 <init+0x54>
		// maybe - check it to be sure it's printable
		uint_t i = argv[1][0];
   174f9:	8b 45 0c             	mov    0xc(%ebp),%eax
   174fc:	83 c0 04             	add    $0x4,%eax
   174ff:	8b 00                	mov    (%eax),%eax
   17501:	0f b6 00             	movzbl (%eax),%eax
   17504:	0f be c0             	movsbl %al,%eax
   17507:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		if( i > ' ' && i < 0x7f ) {
   1750a:	83 7d e4 20          	cmpl   $0x20,-0x1c(%ebp)
   1750e:	76 16                	jbe    17526 <init+0x54>
   17510:	83 7d e4 7e          	cmpl   $0x7e,-0x1c(%ebp)
   17514:	77 10                	ja     17526 <init+0x54>
			ch = argv[1][0];
   17516:	8b 45 0c             	mov    0xc(%ebp),%eax
   17519:	83 c0 04             	add    $0x4,%eax
   1751c:	8b 00                	mov    (%eax),%eax
   1751e:	0f b6 00             	movzbl (%eax),%eax
   17521:	a2 3c d6 01 00       	mov    %al,0x1d63c
		}
	}

	// test the sio
	write( CHAN_SIO, "$+$\n", 4 );
   17526:	83 ec 04             	sub    $0x4,%esp
   17529:	6a 04                	push   $0x4
   1752b:	68 3c bd 01 00       	push   $0x1bd3c
   17530:	6a 01                	push   $0x1
   17532:	e8 09 fa ff ff       	call   16f40 <write>
   17537:	83 c4 10             	add    $0x10,%esp
	DELAY(SHORT);
   1753a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   17541:	eb 04                	jmp    17547 <init+0x75>
   17543:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   17547:	81 7d f4 9f 25 26 00 	cmpl   $0x26259f,-0xc(%ebp)
   1754e:	7e f3                	jle    17543 <init+0x71>

	usprint( buf, "%s: started\n", name );
   17550:	83 ec 04             	sub    $0x4,%esp
   17553:	ff 75 e8             	pushl  -0x18(%ebp)
   17556:	68 41 bd 01 00       	push   $0x1bd41
   1755b:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17561:	50                   	push   %eax
   17562:	e8 5b 27 00 00       	call   19cc2 <usprint>
   17567:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   1756a:	83 ec 0c             	sub    $0xc,%esp
   1756d:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17573:	50                   	push   %eax
   17574:	e8 36 2e 00 00       	call   1a3af <cwrites>
   17579:	83 c4 10             	add    $0x10,%esp

	// home up, clear on a TVI 925
	// swritech( '\x1a' );

	// wait a bit
	DELAY(SHORT);
   1757c:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   17583:	eb 04                	jmp    17589 <init+0xb7>
   17585:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   17589:	81 7d f0 9f 25 26 00 	cmpl   $0x26259f,-0x10(%ebp)
   17590:	7e f3                	jle    17585 <init+0xb3>

	// a bit of Dante to set the mood :-)
	swrites( "\n\nSpem relinquunt qui huc intrasti!\n\n\r" );
   17592:	83 ec 0c             	sub    $0xc,%esp
   17595:	68 50 bd 01 00       	push   $0x1bd50
   1759a:	e8 76 2e 00 00       	call   1a415 <swrites>
   1759f:	83 c4 10             	add    $0x10,%esp

	/*
	** Start all the user processes
	*/

	usprint( buf, "%s: starting user processes\n", name );
   175a2:	83 ec 04             	sub    $0x4,%esp
   175a5:	ff 75 e8             	pushl  -0x18(%ebp)
   175a8:	68 77 bd 01 00       	push   $0x1bd77
   175ad:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   175b3:	50                   	push   %eax
   175b4:	e8 09 27 00 00       	call   19cc2 <usprint>
   175b9:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   175bc:	83 ec 0c             	sub    $0xc,%esp
   175bf:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   175c5:	50                   	push   %eax
   175c6:	e8 e4 2d 00 00       	call   1a3af <cwrites>
   175cb:	83 c4 10             	add    $0x10,%esp

	proc_t *next;
	for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
   175ce:	c7 45 ec a0 d5 01 00 	movl   $0x1d5a0,-0x14(%ebp)
   175d5:	eb 12                	jmp    175e9 <init+0x117>
		process( next );
   175d7:	83 ec 0c             	sub    $0xc,%esp
   175da:	ff 75 ec             	pushl  -0x14(%ebp)
   175dd:	e8 1e fe ff ff       	call   17400 <process>
   175e2:	83 c4 10             	add    $0x10,%esp
	for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
   175e5:	83 45 ec 34          	addl   $0x34,-0x14(%ebp)
   175e9:	8b 45 ec             	mov    -0x14(%ebp),%eax
   175ec:	8b 00                	mov    (%eax),%eax
   175ee:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   175f3:	75 e2                	jne    175d7 <init+0x105>
	}

	swrites( " !!!\r\n\n" );
   175f5:	83 ec 0c             	sub    $0xc,%esp
   175f8:	68 94 bd 01 00       	push   $0x1bd94
   175fd:	e8 13 2e 00 00       	call   1a415 <swrites>
   17602:	83 c4 10             	add    $0x10,%esp
	/*
	** At this point, we go into an infinite loop waiting
	** for our children (direct, or inherited) to exit.
	*/

	usprint( buf, "%s: transitioning to wait() mode\n", name );
   17605:	83 ec 04             	sub    $0x4,%esp
   17608:	ff 75 e8             	pushl  -0x18(%ebp)
   1760b:	68 9c bd 01 00       	push   $0x1bd9c
   17610:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17616:	50                   	push   %eax
   17617:	e8 a6 26 00 00       	call   19cc2 <usprint>
   1761c:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   1761f:	83 ec 0c             	sub    $0xc,%esp
   17622:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17628:	50                   	push   %eax
   17629:	e8 81 2d 00 00       	call   1a3af <cwrites>
   1762e:	83 c4 10             	add    $0x10,%esp

	for(;;) {
		int32_t status;
		int whom = waitpid( 0, &status );
   17631:	83 ec 08             	sub    $0x8,%esp
   17634:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1763a:	50                   	push   %eax
   1763b:	6a 00                	push   $0x0
   1763d:	e8 de f8 ff ff       	call   16f20 <waitpid>
   17642:	83 c4 10             	add    $0x10,%esp
   17645:	89 45 e0             	mov    %eax,-0x20(%ebp)

		// PIDs must be positive numbers!
		if( whom <= 0 ) {
   17648:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   1764c:	7f 2e                	jg     1767c <init+0x1aa>

			usprint( buf, "%s: waitpid() returned %d???\n", name, whom );
   1764e:	ff 75 e0             	pushl  -0x20(%ebp)
   17651:	ff 75 e8             	pushl  -0x18(%ebp)
   17654:	68 be bd 01 00       	push   $0x1bdbe
   17659:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   1765f:	50                   	push   %eax
   17660:	e8 5d 26 00 00       	call   19cc2 <usprint>
   17665:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17668:	83 ec 0c             	sub    $0xc,%esp
   1766b:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17671:	50                   	push   %eax
   17672:	e8 38 2d 00 00       	call   1a3af <cwrites>
   17677:	83 c4 10             	add    $0x10,%esp
   1767a:	eb b5                	jmp    17631 <init+0x15f>

		} else {

			// got one; report it
			usprint( buf, "%s: pid %d exit(%d)\n", name, whom, status );
   1767c:	8b 85 5c ff ff ff    	mov    -0xa4(%ebp),%eax
   17682:	83 ec 0c             	sub    $0xc,%esp
   17685:	50                   	push   %eax
   17686:	ff 75 e0             	pushl  -0x20(%ebp)
   17689:	ff 75 e8             	pushl  -0x18(%ebp)
   1768c:	68 dc bd 01 00       	push   $0x1bddc
   17691:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17697:	50                   	push   %eax
   17698:	e8 25 26 00 00       	call   19cc2 <usprint>
   1769d:	83 c4 20             	add    $0x20,%esp
			cwrites( buf );
   176a0:	83 ec 0c             	sub    $0xc,%esp
   176a3:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   176a9:	50                   	push   %eax
   176aa:	e8 00 2d 00 00       	call   1a3af <cwrites>
   176af:	83 c4 10             	add    $0x10,%esp

			// figure out if this is one of ours
			for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
   176b2:	c7 45 ec a0 d5 01 00 	movl   $0x1d5a0,-0x14(%ebp)
   176b9:	eb 2b                	jmp    176e6 <init+0x214>
				if( next->pid == whom ) {
   176bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
   176be:	8b 50 04             	mov    0x4(%eax),%edx
   176c1:	8b 45 e0             	mov    -0x20(%ebp),%eax
   176c4:	39 c2                	cmp    %eax,%edx
   176c6:	75 1a                	jne    176e2 <init+0x210>
					// one of ours - reset the PID field
					// (in case the spawn attempt fails)
					next->pid = 0;
   176c8:	8b 45 ec             	mov    -0x14(%ebp),%eax
   176cb:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
					// and restart it
					process( next );
   176d2:	83 ec 0c             	sub    $0xc,%esp
   176d5:	ff 75 ec             	pushl  -0x14(%ebp)
   176d8:	e8 23 fd ff ff       	call   17400 <process>
   176dd:	83 c4 10             	add    $0x10,%esp
					break;
   176e0:	eb 10                	jmp    176f2 <init+0x220>
			for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
   176e2:	83 45 ec 34          	addl   $0x34,-0x14(%ebp)
   176e6:	8b 45 ec             	mov    -0x14(%ebp),%eax
   176e9:	8b 00                	mov    (%eax),%eax
   176eb:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   176f0:	75 c9                	jne    176bb <init+0x1e9>
	for(;;) {
   176f2:	e9 3a ff ff ff       	jmp    17631 <init+0x15f>

000176f7 <progABC>:
** Invoked as:  progABC  x  n
**	 where x is the ID character
**		   n is the iteration count
*/

USERMAIN( progABC ) {
   176f7:	55                   	push   %ebp
   176f8:	89 e5                	mov    %esp,%ebp
   176fa:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   17700:	8b 45 0c             	mov    0xc(%ebp),%eax
   17703:	8b 00                	mov    (%eax),%eax
   17705:	85 c0                	test   %eax,%eax
   17707:	74 07                	je     17710 <progABC+0x19>
   17709:	8b 45 0c             	mov    0xc(%ebp),%eax
   1770c:	8b 00                	mov    (%eax),%eax
   1770e:	eb 05                	jmp    17715 <progABC+0x1e>
   17710:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   17715:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 30; // default iteration count
   17718:	c7 45 f4 1e 00 00 00 	movl   $0x1e,-0xc(%ebp)
	char ch = '1';	// default character to print
   1771f:	c6 45 f3 31          	movb   $0x31,-0xd(%ebp)
	char buf[128];	// local char buffer

	// process the command-line arguments
	switch( argc ) {
   17723:	8b 45 08             	mov    0x8(%ebp),%eax
   17726:	83 f8 02             	cmp    $0x2,%eax
   17729:	74 1e                	je     17749 <progABC+0x52>
   1772b:	83 f8 03             	cmp    $0x3,%eax
   1772e:	75 2c                	jne    1775c <progABC+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   17730:	8b 45 0c             	mov    0xc(%ebp),%eax
   17733:	83 c0 08             	add    $0x8,%eax
   17736:	8b 00                	mov    (%eax),%eax
   17738:	83 ec 08             	sub    $0x8,%esp
   1773b:	6a 0a                	push   $0xa
   1773d:	50                   	push   %eax
   1773e:	e8 f4 27 00 00       	call   19f37 <ustr2int>
   17743:	83 c4 10             	add    $0x10,%esp
   17746:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17749:	8b 45 0c             	mov    0xc(%ebp),%eax
   1774c:	83 c0 04             	add    $0x4,%eax
   1774f:	8b 00                	mov    (%eax),%eax
   17751:	0f b6 00             	movzbl (%eax),%eax
   17754:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   17757:	e9 a8 00 00 00       	jmp    17804 <progABC+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   1775c:	ff 75 08             	pushl  0x8(%ebp)
   1775f:	ff 75 e0             	pushl  -0x20(%ebp)
   17762:	68 f1 bd 01 00       	push   $0x1bdf1
   17767:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1776d:	50                   	push   %eax
   1776e:	e8 4f 25 00 00       	call   19cc2 <usprint>
   17773:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17776:	83 ec 0c             	sub    $0xc,%esp
   17779:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1777f:	50                   	push   %eax
   17780:	e8 2a 2c 00 00       	call   1a3af <cwrites>
   17785:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17788:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   1778f:	eb 5b                	jmp    177ec <progABC+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   17791:	8b 45 08             	mov    0x8(%ebp),%eax
   17794:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1779b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1779e:	01 d0                	add    %edx,%eax
   177a0:	8b 00                	mov    (%eax),%eax
   177a2:	85 c0                	test   %eax,%eax
   177a4:	74 13                	je     177b9 <progABC+0xc2>
   177a6:	8b 45 08             	mov    0x8(%ebp),%eax
   177a9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   177b0:	8b 45 0c             	mov    0xc(%ebp),%eax
   177b3:	01 d0                	add    %edx,%eax
   177b5:	8b 00                	mov    (%eax),%eax
   177b7:	eb 05                	jmp    177be <progABC+0xc7>
   177b9:	b8 05 be 01 00       	mov    $0x1be05,%eax
   177be:	83 ec 04             	sub    $0x4,%esp
   177c1:	50                   	push   %eax
   177c2:	68 0c be 01 00       	push   $0x1be0c
   177c7:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   177cd:	50                   	push   %eax
   177ce:	e8 ef 24 00 00       	call   19cc2 <usprint>
   177d3:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   177d6:	83 ec 0c             	sub    $0xc,%esp
   177d9:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   177df:	50                   	push   %eax
   177e0:	e8 ca 2b 00 00       	call   1a3af <cwrites>
   177e5:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   177e8:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   177ec:	8b 45 ec             	mov    -0x14(%ebp),%eax
   177ef:	3b 45 08             	cmp    0x8(%ebp),%eax
   177f2:	7e 9d                	jle    17791 <progABC+0x9a>
			}
			cwrites( "\n" );
   177f4:	83 ec 0c             	sub    $0xc,%esp
   177f7:	68 10 be 01 00       	push   $0x1be10
   177fc:	e8 ae 2b 00 00       	call   1a3af <cwrites>
   17801:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int n = swritech( ch );
   17804:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17808:	83 ec 0c             	sub    $0xc,%esp
   1780b:	50                   	push   %eax
   1780c:	e8 e3 2b 00 00       	call   1a3f4 <swritech>
   17811:	83 c4 10             	add    $0x10,%esp
   17814:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if( n != 1 ) {
   17817:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   1781b:	74 2e                	je     1784b <progABC+0x154>
		usprint( buf, "== %c, write #1 returned %d\n", ch, n );
   1781d:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17821:	ff 75 dc             	pushl  -0x24(%ebp)
   17824:	50                   	push   %eax
   17825:	68 12 be 01 00       	push   $0x1be12
   1782a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17830:	50                   	push   %eax
   17831:	e8 8c 24 00 00       	call   19cc2 <usprint>
   17836:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   17839:	83 ec 0c             	sub    $0xc,%esp
   1783c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17842:	50                   	push   %eax
   17843:	e8 67 2b 00 00       	call   1a3af <cwrites>
   17848:	83 c4 10             	add    $0x10,%esp
	}

	// iterate and print the required number of other characters
	for( int i = 0; i < count; ++i ) {
   1784b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   17852:	eb 61                	jmp    178b5 <progABC+0x1be>
		DELAY(STD);
   17854:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   1785b:	eb 04                	jmp    17861 <progABC+0x16a>
   1785d:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   17861:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   17868:	7e f3                	jle    1785d <progABC+0x166>
		n = swritech( ch );
   1786a:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   1786e:	83 ec 0c             	sub    $0xc,%esp
   17871:	50                   	push   %eax
   17872:	e8 7d 2b 00 00       	call   1a3f4 <swritech>
   17877:	83 c4 10             	add    $0x10,%esp
   1787a:	89 45 dc             	mov    %eax,-0x24(%ebp)
		if( n != 1 ) {
   1787d:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   17881:	74 2e                	je     178b1 <progABC+0x1ba>
			usprint( buf, "== %c, write #2 returned %d\n", ch, n );
   17883:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17887:	ff 75 dc             	pushl  -0x24(%ebp)
   1788a:	50                   	push   %eax
   1788b:	68 2f be 01 00       	push   $0x1be2f
   17890:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17896:	50                   	push   %eax
   17897:	e8 26 24 00 00       	call   19cc2 <usprint>
   1789c:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1789f:	83 ec 0c             	sub    $0xc,%esp
   178a2:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   178a8:	50                   	push   %eax
   178a9:	e8 01 2b 00 00       	call   1a3af <cwrites>
   178ae:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   178b1:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   178b5:	8b 45 e8             	mov    -0x18(%ebp),%eax
   178b8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   178bb:	7c 97                	jl     17854 <progABC+0x15d>
		}
	}

	// all done!
	exit( 0 );
   178bd:	83 ec 0c             	sub    $0xc,%esp
   178c0:	6a 00                	push   $0x0
   178c2:	e8 51 f6 ff ff       	call   16f18 <exit>
   178c7:	83 c4 10             	add    $0x10,%esp

	// should never reach this code; if we do, something is
	// wrong with exit(), so we'll report it

	char msg[] = "*1*";
   178ca:	c7 85 58 ff ff ff 2a 	movl   $0x2a312a,-0xa8(%ebp)
   178d1:	31 2a 00 
	msg[1] = ch;
   178d4:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   178d8:	88 85 59 ff ff ff    	mov    %al,-0xa7(%ebp)
	n = write( CHAN_SIO, msg, 3 );	  /* shouldn't happen! */
   178de:	83 ec 04             	sub    $0x4,%esp
   178e1:	6a 03                	push   $0x3
   178e3:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   178e9:	50                   	push   %eax
   178ea:	6a 01                	push   $0x1
   178ec:	e8 4f f6 ff ff       	call   16f40 <write>
   178f1:	83 c4 10             	add    $0x10,%esp
   178f4:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if( n != 3 ) {
   178f7:	83 7d dc 03          	cmpl   $0x3,-0x24(%ebp)
   178fb:	74 2e                	je     1792b <progABC+0x234>
		usprint( buf, "User %c, write #3 returned %d\n", ch, n );
   178fd:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17901:	ff 75 dc             	pushl  -0x24(%ebp)
   17904:	50                   	push   %eax
   17905:	68 4c be 01 00       	push   $0x1be4c
   1790a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17910:	50                   	push   %eax
   17911:	e8 ac 23 00 00       	call   19cc2 <usprint>
   17916:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   17919:	83 ec 0c             	sub    $0xc,%esp
   1791c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17922:	50                   	push   %eax
   17923:	e8 87 2a 00 00       	call   1a3af <cwrites>
   17928:	83 c4 10             	add    $0x10,%esp
	}

	// this should really get us out of here
	return( 42 );
   1792b:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   17930:	c9                   	leave  
   17931:	c3                   	ret    

00017932 <progDE>:
** Invoked as:  progDE  x  n
**	 where x is the ID character
**		   n is the iteration count
*/

USERMAIN( progDE ) {
   17932:	55                   	push   %ebp
   17933:	89 e5                	mov    %esp,%ebp
   17935:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   1793b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1793e:	8b 00                	mov    (%eax),%eax
   17940:	85 c0                	test   %eax,%eax
   17942:	74 07                	je     1794b <progDE+0x19>
   17944:	8b 45 0c             	mov    0xc(%ebp),%eax
   17947:	8b 00                	mov    (%eax),%eax
   17949:	eb 05                	jmp    17950 <progDE+0x1e>
   1794b:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   17950:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int n;
	int count = 30;	  // default iteration count
   17953:	c7 45 f4 1e 00 00 00 	movl   $0x1e,-0xc(%ebp)
	char ch = '2';	  // default character to print
   1795a:	c6 45 f3 32          	movb   $0x32,-0xd(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   1795e:	8b 45 08             	mov    0x8(%ebp),%eax
   17961:	83 f8 02             	cmp    $0x2,%eax
   17964:	74 1e                	je     17984 <progDE+0x52>
   17966:	83 f8 03             	cmp    $0x3,%eax
   17969:	75 2c                	jne    17997 <progDE+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   1796b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1796e:	83 c0 08             	add    $0x8,%eax
   17971:	8b 00                	mov    (%eax),%eax
   17973:	83 ec 08             	sub    $0x8,%esp
   17976:	6a 0a                	push   $0xa
   17978:	50                   	push   %eax
   17979:	e8 b9 25 00 00       	call   19f37 <ustr2int>
   1797e:	83 c4 10             	add    $0x10,%esp
   17981:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17984:	8b 45 0c             	mov    0xc(%ebp),%eax
   17987:	83 c0 04             	add    $0x4,%eax
   1798a:	8b 00                	mov    (%eax),%eax
   1798c:	0f b6 00             	movzbl (%eax),%eax
   1798f:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   17992:	e9 a8 00 00 00       	jmp    17a3f <progDE+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   17997:	ff 75 08             	pushl  0x8(%ebp)
   1799a:	ff 75 e0             	pushl  -0x20(%ebp)
   1799d:	68 f1 bd 01 00       	push   $0x1bdf1
   179a2:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   179a8:	50                   	push   %eax
   179a9:	e8 14 23 00 00       	call   19cc2 <usprint>
   179ae:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   179b1:	83 ec 0c             	sub    $0xc,%esp
   179b4:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   179ba:	50                   	push   %eax
   179bb:	e8 ef 29 00 00       	call   1a3af <cwrites>
   179c0:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   179c3:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   179ca:	eb 5b                	jmp    17a27 <progDE+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   179cc:	8b 45 08             	mov    0x8(%ebp),%eax
   179cf:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   179d6:	8b 45 0c             	mov    0xc(%ebp),%eax
   179d9:	01 d0                	add    %edx,%eax
   179db:	8b 00                	mov    (%eax),%eax
   179dd:	85 c0                	test   %eax,%eax
   179df:	74 13                	je     179f4 <progDE+0xc2>
   179e1:	8b 45 08             	mov    0x8(%ebp),%eax
   179e4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   179eb:	8b 45 0c             	mov    0xc(%ebp),%eax
   179ee:	01 d0                	add    %edx,%eax
   179f0:	8b 00                	mov    (%eax),%eax
   179f2:	eb 05                	jmp    179f9 <progDE+0xc7>
   179f4:	b8 05 be 01 00       	mov    $0x1be05,%eax
   179f9:	83 ec 04             	sub    $0x4,%esp
   179fc:	50                   	push   %eax
   179fd:	68 0c be 01 00       	push   $0x1be0c
   17a02:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17a08:	50                   	push   %eax
   17a09:	e8 b4 22 00 00       	call   19cc2 <usprint>
   17a0e:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17a11:	83 ec 0c             	sub    $0xc,%esp
   17a14:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17a1a:	50                   	push   %eax
   17a1b:	e8 8f 29 00 00       	call   1a3af <cwrites>
   17a20:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17a23:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   17a27:	8b 45 ec             	mov    -0x14(%ebp),%eax
   17a2a:	3b 45 08             	cmp    0x8(%ebp),%eax
   17a2d:	7e 9d                	jle    179cc <progDE+0x9a>
			}
			cwrites( "\n" );
   17a2f:	83 ec 0c             	sub    $0xc,%esp
   17a32:	68 10 be 01 00       	push   $0x1be10
   17a37:	e8 73 29 00 00       	call   1a3af <cwrites>
   17a3c:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	n = swritech( ch );
   17a3f:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17a43:	83 ec 0c             	sub    $0xc,%esp
   17a46:	50                   	push   %eax
   17a47:	e8 a8 29 00 00       	call   1a3f4 <swritech>
   17a4c:	83 c4 10             	add    $0x10,%esp
   17a4f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if( n != 1 ) {
   17a52:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   17a56:	74 2e                	je     17a86 <progDE+0x154>
		usprint( buf, "== %c, write #1 returned %d\n", ch, n );
   17a58:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17a5c:	ff 75 dc             	pushl  -0x24(%ebp)
   17a5f:	50                   	push   %eax
   17a60:	68 12 be 01 00       	push   $0x1be12
   17a65:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17a6b:	50                   	push   %eax
   17a6c:	e8 51 22 00 00       	call   19cc2 <usprint>
   17a71:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   17a74:	83 ec 0c             	sub    $0xc,%esp
   17a77:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17a7d:	50                   	push   %eax
   17a7e:	e8 2c 29 00 00       	call   1a3af <cwrites>
   17a83:	83 c4 10             	add    $0x10,%esp
	}

	// iterate and print the required number of other characters
	for( int i = 0; i < count; ++i ) {
   17a86:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   17a8d:	eb 61                	jmp    17af0 <progDE+0x1be>
		DELAY(STD);
   17a8f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   17a96:	eb 04                	jmp    17a9c <progDE+0x16a>
   17a98:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   17a9c:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   17aa3:	7e f3                	jle    17a98 <progDE+0x166>
		n = swritech( ch );
   17aa5:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17aa9:	83 ec 0c             	sub    $0xc,%esp
   17aac:	50                   	push   %eax
   17aad:	e8 42 29 00 00       	call   1a3f4 <swritech>
   17ab2:	83 c4 10             	add    $0x10,%esp
   17ab5:	89 45 dc             	mov    %eax,-0x24(%ebp)
		if( n != 1 ) {
   17ab8:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   17abc:	74 2e                	je     17aec <progDE+0x1ba>
			usprint( buf, "== %c, write #2 returned %d\n", ch, n );
   17abe:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17ac2:	ff 75 dc             	pushl  -0x24(%ebp)
   17ac5:	50                   	push   %eax
   17ac6:	68 2f be 01 00       	push   $0x1be2f
   17acb:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17ad1:	50                   	push   %eax
   17ad2:	e8 eb 21 00 00       	call   19cc2 <usprint>
   17ad7:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17ada:	83 ec 0c             	sub    $0xc,%esp
   17add:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17ae3:	50                   	push   %eax
   17ae4:	e8 c6 28 00 00       	call   1a3af <cwrites>
   17ae9:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   17aec:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   17af0:	8b 45 e8             	mov    -0x18(%ebp),%eax
   17af3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   17af6:	7c 97                	jl     17a8f <progDE+0x15d>
		}
	}

	// all done!
	return( 0 );
   17af8:	b8 00 00 00 00       	mov    $0x0,%eax
}
   17afd:	c9                   	leave  
   17afe:	c3                   	ret    

00017aff <progFG>:
**	 where x is the ID character
**		   n is the iteration count
**		   s is the sleep time in seconds
*/

USERMAIN( progFG ) {
   17aff:	55                   	push   %ebp
   17b00:	89 e5                	mov    %esp,%ebp
   17b02:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   17b08:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b0b:	8b 00                	mov    (%eax),%eax
   17b0d:	85 c0                	test   %eax,%eax
   17b0f:	74 07                	je     17b18 <progFG+0x19>
   17b11:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b14:	8b 00                	mov    (%eax),%eax
   17b16:	eb 05                	jmp    17b1d <progFG+0x1e>
   17b18:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   17b1d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	char ch = '3';	// default character to print
   17b20:	c6 45 df 33          	movb   $0x33,-0x21(%ebp)
	int nap = 10;	// default sleep time
   17b24:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
	int count = 30;	// iteration count
   17b2b:	c7 45 f0 1e 00 00 00 	movl   $0x1e,-0x10(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   17b32:	8b 45 08             	mov    0x8(%ebp),%eax
   17b35:	83 f8 03             	cmp    $0x3,%eax
   17b38:	74 25                	je     17b5f <progFG+0x60>
   17b3a:	83 f8 04             	cmp    $0x4,%eax
   17b3d:	74 07                	je     17b46 <progFG+0x47>
   17b3f:	83 f8 02             	cmp    $0x2,%eax
   17b42:	74 34                	je     17b78 <progFG+0x79>
   17b44:	eb 45                	jmp    17b8b <progFG+0x8c>
	case 4:	nap = ustr2int( argv[3], 10 );
   17b46:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b49:	83 c0 0c             	add    $0xc,%eax
   17b4c:	8b 00                	mov    (%eax),%eax
   17b4e:	83 ec 08             	sub    $0x8,%esp
   17b51:	6a 0a                	push   $0xa
   17b53:	50                   	push   %eax
   17b54:	e8 de 23 00 00       	call   19f37 <ustr2int>
   17b59:	83 c4 10             	add    $0x10,%esp
   17b5c:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   17b5f:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b62:	83 c0 08             	add    $0x8,%eax
   17b65:	8b 00                	mov    (%eax),%eax
   17b67:	83 ec 08             	sub    $0x8,%esp
   17b6a:	6a 0a                	push   $0xa
   17b6c:	50                   	push   %eax
   17b6d:	e8 c5 23 00 00       	call   19f37 <ustr2int>
   17b72:	83 c4 10             	add    $0x10,%esp
   17b75:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17b78:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b7b:	83 c0 04             	add    $0x4,%eax
   17b7e:	8b 00                	mov    (%eax),%eax
   17b80:	0f b6 00             	movzbl (%eax),%eax
   17b83:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   17b86:	e9 a8 00 00 00       	jmp    17c33 <progFG+0x134>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   17b8b:	ff 75 08             	pushl  0x8(%ebp)
   17b8e:	ff 75 e4             	pushl  -0x1c(%ebp)
   17b91:	68 f1 bd 01 00       	push   $0x1bdf1
   17b96:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17b9c:	50                   	push   %eax
   17b9d:	e8 20 21 00 00       	call   19cc2 <usprint>
   17ba2:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17ba5:	83 ec 0c             	sub    $0xc,%esp
   17ba8:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17bae:	50                   	push   %eax
   17baf:	e8 fb 27 00 00       	call   1a3af <cwrites>
   17bb4:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17bb7:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   17bbe:	eb 5b                	jmp    17c1b <progFG+0x11c>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   17bc0:	8b 45 08             	mov    0x8(%ebp),%eax
   17bc3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17bca:	8b 45 0c             	mov    0xc(%ebp),%eax
   17bcd:	01 d0                	add    %edx,%eax
   17bcf:	8b 00                	mov    (%eax),%eax
   17bd1:	85 c0                	test   %eax,%eax
   17bd3:	74 13                	je     17be8 <progFG+0xe9>
   17bd5:	8b 45 08             	mov    0x8(%ebp),%eax
   17bd8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17bdf:	8b 45 0c             	mov    0xc(%ebp),%eax
   17be2:	01 d0                	add    %edx,%eax
   17be4:	8b 00                	mov    (%eax),%eax
   17be6:	eb 05                	jmp    17bed <progFG+0xee>
   17be8:	b8 05 be 01 00       	mov    $0x1be05,%eax
   17bed:	83 ec 04             	sub    $0x4,%esp
   17bf0:	50                   	push   %eax
   17bf1:	68 0c be 01 00       	push   $0x1be0c
   17bf6:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17bfc:	50                   	push   %eax
   17bfd:	e8 c0 20 00 00       	call   19cc2 <usprint>
   17c02:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17c05:	83 ec 0c             	sub    $0xc,%esp
   17c08:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17c0e:	50                   	push   %eax
   17c0f:	e8 9b 27 00 00       	call   1a3af <cwrites>
   17c14:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17c17:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   17c1b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   17c1e:	3b 45 08             	cmp    0x8(%ebp),%eax
   17c21:	7e 9d                	jle    17bc0 <progFG+0xc1>
			}
			cwrites( "\n" );
   17c23:	83 ec 0c             	sub    $0xc,%esp
   17c26:	68 10 be 01 00       	push   $0x1be10
   17c2b:	e8 7f 27 00 00       	call   1a3af <cwrites>
   17c30:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int n = swritech( ch );
   17c33:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
   17c37:	0f be c0             	movsbl %al,%eax
   17c3a:	83 ec 0c             	sub    $0xc,%esp
   17c3d:	50                   	push   %eax
   17c3e:	e8 b1 27 00 00       	call   1a3f4 <swritech>
   17c43:	83 c4 10             	add    $0x10,%esp
   17c46:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if( n != 1 ) {
   17c49:	83 7d e0 01          	cmpl   $0x1,-0x20(%ebp)
   17c4d:	74 31                	je     17c80 <progFG+0x181>
		usprint( buf, "=== %c, write #1 returned %d\n", ch, n );
   17c4f:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
   17c53:	0f be c0             	movsbl %al,%eax
   17c56:	ff 75 e0             	pushl  -0x20(%ebp)
   17c59:	50                   	push   %eax
   17c5a:	68 6b be 01 00       	push   $0x1be6b
   17c5f:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17c65:	50                   	push   %eax
   17c66:	e8 57 20 00 00       	call   19cc2 <usprint>
   17c6b:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   17c6e:	83 ec 0c             	sub    $0xc,%esp
   17c71:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17c77:	50                   	push   %eax
   17c78:	e8 32 27 00 00       	call   1a3af <cwrites>
   17c7d:	83 c4 10             	add    $0x10,%esp
	}

	write( CHAN_SIO, &ch, 1 );
   17c80:	83 ec 04             	sub    $0x4,%esp
   17c83:	6a 01                	push   $0x1
   17c85:	8d 45 df             	lea    -0x21(%ebp),%eax
   17c88:	50                   	push   %eax
   17c89:	6a 01                	push   $0x1
   17c8b:	e8 b0 f2 ff ff       	call   16f40 <write>
   17c90:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   17c93:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   17c9a:	eb 2c                	jmp    17cc8 <progFG+0x1c9>
		sleep( SEC_TO_MS(nap) );
   17c9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17c9f:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   17ca5:	83 ec 0c             	sub    $0xc,%esp
   17ca8:	50                   	push   %eax
   17ca9:	e8 ca f2 ff ff       	call   16f78 <sleep>
   17cae:	83 c4 10             	add    $0x10,%esp
		write( CHAN_SIO, &ch, 1 );
   17cb1:	83 ec 04             	sub    $0x4,%esp
   17cb4:	6a 01                	push   $0x1
   17cb6:	8d 45 df             	lea    -0x21(%ebp),%eax
   17cb9:	50                   	push   %eax
   17cba:	6a 01                	push   $0x1
   17cbc:	e8 7f f2 ff ff       	call   16f40 <write>
   17cc1:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   17cc4:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   17cc8:	8b 45 e8             	mov    -0x18(%ebp),%eax
   17ccb:	3b 45 f0             	cmp    -0x10(%ebp),%eax
   17cce:	7c cc                	jl     17c9c <progFG+0x19d>
	}

	exit( 0 );
   17cd0:	83 ec 0c             	sub    $0xc,%esp
   17cd3:	6a 00                	push   $0x0
   17cd5:	e8 3e f2 ff ff       	call   16f18 <exit>
   17cda:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   17cdd:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   17ce2:	c9                   	leave  
   17ce3:	c3                   	ret    

00017ce4 <progH>:
** Invoked as:  progH  x  n
**	 where x is the ID character
**		   n is the number of children to spawn
*/

USERMAIN( progH ) {
   17ce4:	55                   	push   %ebp
   17ce5:	89 e5                	mov    %esp,%ebp
   17ce7:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   17ced:	8b 45 0c             	mov    0xc(%ebp),%eax
   17cf0:	8b 00                	mov    (%eax),%eax
   17cf2:	85 c0                	test   %eax,%eax
   17cf4:	74 07                	je     17cfd <progH+0x19>
   17cf6:	8b 45 0c             	mov    0xc(%ebp),%eax
   17cf9:	8b 00                	mov    (%eax),%eax
   17cfb:	eb 05                	jmp    17d02 <progH+0x1e>
   17cfd:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   17d02:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int32_t ret = 0;  // return value
   17d05:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	int count = 5;	  // child count
   17d0c:	c7 45 f0 05 00 00 00 	movl   $0x5,-0x10(%ebp)
	char ch = 'h';	  // default character to print
   17d13:	c6 45 ef 68          	movb   $0x68,-0x11(%ebp)
	char buf[128];
	int whom;

	// process the argument(s)
	switch( argc ) {
   17d17:	8b 45 08             	mov    0x8(%ebp),%eax
   17d1a:	83 f8 02             	cmp    $0x2,%eax
   17d1d:	74 1e                	je     17d3d <progH+0x59>
   17d1f:	83 f8 03             	cmp    $0x3,%eax
   17d22:	75 2c                	jne    17d50 <progH+0x6c>
	case 3:	count = ustr2int( argv[2], 10 );
   17d24:	8b 45 0c             	mov    0xc(%ebp),%eax
   17d27:	83 c0 08             	add    $0x8,%eax
   17d2a:	8b 00                	mov    (%eax),%eax
   17d2c:	83 ec 08             	sub    $0x8,%esp
   17d2f:	6a 0a                	push   $0xa
   17d31:	50                   	push   %eax
   17d32:	e8 00 22 00 00       	call   19f37 <ustr2int>
   17d37:	83 c4 10             	add    $0x10,%esp
   17d3a:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17d3d:	8b 45 0c             	mov    0xc(%ebp),%eax
   17d40:	83 c0 04             	add    $0x4,%eax
   17d43:	8b 00                	mov    (%eax),%eax
   17d45:	0f b6 00             	movzbl (%eax),%eax
   17d48:	88 45 ef             	mov    %al,-0x11(%ebp)
			break;
   17d4b:	e9 a8 00 00 00       	jmp    17df8 <progH+0x114>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   17d50:	ff 75 08             	pushl  0x8(%ebp)
   17d53:	ff 75 e0             	pushl  -0x20(%ebp)
   17d56:	68 f1 bd 01 00       	push   $0x1bdf1
   17d5b:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17d61:	50                   	push   %eax
   17d62:	e8 5b 1f 00 00       	call   19cc2 <usprint>
   17d67:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17d6a:	83 ec 0c             	sub    $0xc,%esp
   17d6d:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17d73:	50                   	push   %eax
   17d74:	e8 36 26 00 00       	call   1a3af <cwrites>
   17d79:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17d7c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   17d83:	eb 5b                	jmp    17de0 <progH+0xfc>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   17d85:	8b 45 08             	mov    0x8(%ebp),%eax
   17d88:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17d8f:	8b 45 0c             	mov    0xc(%ebp),%eax
   17d92:	01 d0                	add    %edx,%eax
   17d94:	8b 00                	mov    (%eax),%eax
   17d96:	85 c0                	test   %eax,%eax
   17d98:	74 13                	je     17dad <progH+0xc9>
   17d9a:	8b 45 08             	mov    0x8(%ebp),%eax
   17d9d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17da4:	8b 45 0c             	mov    0xc(%ebp),%eax
   17da7:	01 d0                	add    %edx,%eax
   17da9:	8b 00                	mov    (%eax),%eax
   17dab:	eb 05                	jmp    17db2 <progH+0xce>
   17dad:	b8 05 be 01 00       	mov    $0x1be05,%eax
   17db2:	83 ec 04             	sub    $0x4,%esp
   17db5:	50                   	push   %eax
   17db6:	68 0c be 01 00       	push   $0x1be0c
   17dbb:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17dc1:	50                   	push   %eax
   17dc2:	e8 fb 1e 00 00       	call   19cc2 <usprint>
   17dc7:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17dca:	83 ec 0c             	sub    $0xc,%esp
   17dcd:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17dd3:	50                   	push   %eax
   17dd4:	e8 d6 25 00 00       	call   1a3af <cwrites>
   17dd9:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17ddc:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   17de0:	8b 45 e8             	mov    -0x18(%ebp),%eax
   17de3:	3b 45 08             	cmp    0x8(%ebp),%eax
   17de6:	7e 9d                	jle    17d85 <progH+0xa1>
			}
			cwrites( "\n" );
   17de8:	83 ec 0c             	sub    $0xc,%esp
   17deb:	68 10 be 01 00       	push   $0x1be10
   17df0:	e8 ba 25 00 00       	call   1a3af <cwrites>
   17df5:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	swritech( ch );
   17df8:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   17dfc:	83 ec 0c             	sub    $0xc,%esp
   17dff:	50                   	push   %eax
   17e00:	e8 ef 25 00 00       	call   1a3f4 <swritech>
   17e05:	83 c4 10             	add    $0x10,%esp

	// we spawn user Z and then exit before it can terminate
	// progZ 'Z' 10

	char *argsz[] = { "progZ", "Z", "10", NULL };
   17e08:	c7 85 4c ff ff ff 89 	movl   $0x1be89,-0xb4(%ebp)
   17e0f:	be 01 00 
   17e12:	c7 85 50 ff ff ff 8f 	movl   $0x1be8f,-0xb0(%ebp)
   17e19:	be 01 00 
   17e1c:	c7 85 54 ff ff ff 64 	movl   $0x1bb64,-0xac(%ebp)
   17e23:	bb 01 00 
   17e26:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
   17e2d:	00 00 00 

	for( int i = 0; i < count; ++i ) {
   17e30:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   17e37:	eb 57                	jmp    17e90 <progH+0x1ac>

		// spawn a child
		whom = spawn( (uint32_t) progZ, argsz );
   17e39:	ba ca 7e 01 00       	mov    $0x17eca,%edx
   17e3e:	83 ec 08             	sub    $0x8,%esp
   17e41:	8d 85 4c ff ff ff    	lea    -0xb4(%ebp),%eax
   17e47:	50                   	push   %eax
   17e48:	52                   	push   %edx
   17e49:	e8 cb 24 00 00       	call   1a319 <spawn>
   17e4e:	83 c4 10             	add    $0x10,%esp
   17e51:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// our exit status is the number of failed spawn() calls
		if( whom < 0 ) {
   17e54:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   17e58:	79 32                	jns    17e8c <progH+0x1a8>
			usprint( buf, "!! %c spawn() failed, returned %d\n", ch, whom );
   17e5a:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   17e5e:	ff 75 dc             	pushl  -0x24(%ebp)
   17e61:	50                   	push   %eax
   17e62:	68 94 be 01 00       	push   $0x1be94
   17e67:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17e6d:	50                   	push   %eax
   17e6e:	e8 4f 1e 00 00       	call   19cc2 <usprint>
   17e73:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17e76:	83 ec 0c             	sub    $0xc,%esp
   17e79:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17e7f:	50                   	push   %eax
   17e80:	e8 2a 25 00 00       	call   1a3af <cwrites>
   17e85:	83 c4 10             	add    $0x10,%esp
			ret += 1;
   17e88:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
	for( int i = 0; i < count; ++i ) {
   17e8c:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   17e90:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   17e93:	3b 45 f0             	cmp    -0x10(%ebp),%eax
   17e96:	7c a1                	jl     17e39 <progH+0x155>
		}
	}

	// yield the CPU so that our child(ren) can run
	sleep( 0 );
   17e98:	83 ec 0c             	sub    $0xc,%esp
   17e9b:	6a 00                	push   $0x0
   17e9d:	e8 d6 f0 ff ff       	call   16f78 <sleep>
   17ea2:	83 c4 10             	add    $0x10,%esp

	// announce our departure
	swritech( ch );
   17ea5:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   17ea9:	83 ec 0c             	sub    $0xc,%esp
   17eac:	50                   	push   %eax
   17ead:	e8 42 25 00 00       	call   1a3f4 <swritech>
   17eb2:	83 c4 10             	add    $0x10,%esp

	exit( ret );
   17eb5:	83 ec 0c             	sub    $0xc,%esp
   17eb8:	ff 75 f4             	pushl  -0xc(%ebp)
   17ebb:	e8 58 f0 ff ff       	call   16f18 <exit>
   17ec0:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   17ec3:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   17ec8:	c9                   	leave  
   17ec9:	c3                   	ret    

00017eca <progZ>:
** Invoked as:	progZ  x  [ n ]
**	 where x is the ID character
**		   n is the iteration count (defaults to 10)
*/

USERMAIN( progZ ) {
   17eca:	55                   	push   %ebp
   17ecb:	89 e5                	mov    %esp,%ebp
   17ecd:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   17ed3:	8b 45 0c             	mov    0xc(%ebp),%eax
   17ed6:	8b 00                	mov    (%eax),%eax
   17ed8:	85 c0                	test   %eax,%eax
   17eda:	74 07                	je     17ee3 <progZ+0x19>
   17edc:	8b 45 0c             	mov    0xc(%ebp),%eax
   17edf:	8b 00                	mov    (%eax),%eax
   17ee1:	eb 05                	jmp    17ee8 <progZ+0x1e>
   17ee3:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   17ee8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 10;	  // default iteration count
   17eeb:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
	char ch = 'z';	  // default character to print
   17ef2:	c6 45 f3 7a          	movb   $0x7a,-0xd(%ebp)
	char buf[128];

	(void) name;

	// process the command-line arguments
	switch( argc ) {
   17ef6:	8b 45 08             	mov    0x8(%ebp),%eax
   17ef9:	83 f8 02             	cmp    $0x2,%eax
   17efc:	74 1e                	je     17f1c <progZ+0x52>
   17efe:	83 f8 03             	cmp    $0x3,%eax
   17f01:	75 2c                	jne    17f2f <progZ+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   17f03:	8b 45 0c             	mov    0xc(%ebp),%eax
   17f06:	83 c0 08             	add    $0x8,%eax
   17f09:	8b 00                	mov    (%eax),%eax
   17f0b:	83 ec 08             	sub    $0x8,%esp
   17f0e:	6a 0a                	push   $0xa
   17f10:	50                   	push   %eax
   17f11:	e8 21 20 00 00       	call   19f37 <ustr2int>
   17f16:	83 c4 10             	add    $0x10,%esp
   17f19:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17f1c:	8b 45 0c             	mov    0xc(%ebp),%eax
   17f1f:	83 c0 04             	add    $0x4,%eax
   17f22:	8b 00                	mov    (%eax),%eax
   17f24:	0f b6 00             	movzbl (%eax),%eax
   17f27:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   17f2a:	e9 a8 00 00 00       	jmp    17fd7 <progZ+0x10d>
	default:
			usprint( buf, "?: argc %d, args: ", argc );
   17f2f:	83 ec 04             	sub    $0x4,%esp
   17f32:	ff 75 08             	pushl  0x8(%ebp)
   17f35:	68 b7 be 01 00       	push   $0x1beb7
   17f3a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17f40:	50                   	push   %eax
   17f41:	e8 7c 1d 00 00       	call   19cc2 <usprint>
   17f46:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17f49:	83 ec 0c             	sub    $0xc,%esp
   17f4c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17f52:	50                   	push   %eax
   17f53:	e8 57 24 00 00       	call   1a3af <cwrites>
   17f58:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17f5b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   17f62:	eb 5b                	jmp    17fbf <progZ+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   17f64:	8b 45 08             	mov    0x8(%ebp),%eax
   17f67:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17f6e:	8b 45 0c             	mov    0xc(%ebp),%eax
   17f71:	01 d0                	add    %edx,%eax
   17f73:	8b 00                	mov    (%eax),%eax
   17f75:	85 c0                	test   %eax,%eax
   17f77:	74 13                	je     17f8c <progZ+0xc2>
   17f79:	8b 45 08             	mov    0x8(%ebp),%eax
   17f7c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17f83:	8b 45 0c             	mov    0xc(%ebp),%eax
   17f86:	01 d0                	add    %edx,%eax
   17f88:	8b 00                	mov    (%eax),%eax
   17f8a:	eb 05                	jmp    17f91 <progZ+0xc7>
   17f8c:	b8 05 be 01 00       	mov    $0x1be05,%eax
   17f91:	83 ec 04             	sub    $0x4,%esp
   17f94:	50                   	push   %eax
   17f95:	68 0c be 01 00       	push   $0x1be0c
   17f9a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17fa0:	50                   	push   %eax
   17fa1:	e8 1c 1d 00 00       	call   19cc2 <usprint>
   17fa6:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17fa9:	83 ec 0c             	sub    $0xc,%esp
   17fac:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17fb2:	50                   	push   %eax
   17fb3:	e8 f7 23 00 00       	call   1a3af <cwrites>
   17fb8:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17fbb:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   17fbf:	8b 45 ec             	mov    -0x14(%ebp),%eax
   17fc2:	3b 45 08             	cmp    0x8(%ebp),%eax
   17fc5:	7e 9d                	jle    17f64 <progZ+0x9a>
			}
			cwrites( "\n" );
   17fc7:	83 ec 0c             	sub    $0xc,%esp
   17fca:	68 10 be 01 00       	push   $0x1be10
   17fcf:	e8 db 23 00 00       	call   1a3af <cwrites>
   17fd4:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int pid = getpid();
   17fd7:	e8 6c ef ff ff       	call   16f48 <getpid>
   17fdc:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d]", ch, pid );
   17fdf:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17fe3:	ff 75 dc             	pushl  -0x24(%ebp)
   17fe6:	50                   	push   %eax
   17fe7:	68 ca be 01 00       	push   $0x1beca
   17fec:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17ff2:	50                   	push   %eax
   17ff3:	e8 ca 1c 00 00       	call   19cc2 <usprint>
   17ff8:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   17ffb:	83 ec 0c             	sub    $0xc,%esp
   17ffe:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18004:	50                   	push   %eax
   18005:	e8 0b 24 00 00       	call   1a415 <swrites>
   1800a:	83 c4 10             	add    $0x10,%esp

	// iterate for a while; occasionally yield the CPU
	for( int i = 0; i < count ; ++i ) {
   1800d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18014:	eb 5f                	jmp    18075 <progZ+0x1ab>
		usprint( buf, " %c[%d]", ch, i );
   18016:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   1801a:	ff 75 e8             	pushl  -0x18(%ebp)
   1801d:	50                   	push   %eax
   1801e:	68 ca be 01 00       	push   $0x1beca
   18023:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18029:	50                   	push   %eax
   1802a:	e8 93 1c 00 00       	call   19cc2 <usprint>
   1802f:	83 c4 10             	add    $0x10,%esp
		swrites( buf );
   18032:	83 ec 0c             	sub    $0xc,%esp
   18035:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1803b:	50                   	push   %eax
   1803c:	e8 d4 23 00 00       	call   1a415 <swrites>
   18041:	83 c4 10             	add    $0x10,%esp
		DELAY(STD);
   18044:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   1804b:	eb 04                	jmp    18051 <progZ+0x187>
   1804d:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   18051:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   18058:	7e f3                	jle    1804d <progZ+0x183>
		if( i & 1 ) {
   1805a:	8b 45 e8             	mov    -0x18(%ebp),%eax
   1805d:	83 e0 01             	and    $0x1,%eax
   18060:	85 c0                	test   %eax,%eax
   18062:	74 0d                	je     18071 <progZ+0x1a7>
			sleep( 0 );
   18064:	83 ec 0c             	sub    $0xc,%esp
   18067:	6a 00                	push   $0x0
   18069:	e8 0a ef ff ff       	call   16f78 <sleep>
   1806e:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   18071:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18075:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18078:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   1807b:	7c 99                	jl     18016 <progZ+0x14c>
		}
	}

	exit( 0 );
   1807d:	83 ec 0c             	sub    $0xc,%esp
   18080:	6a 00                	push   $0x0
   18082:	e8 91 ee ff ff       	call   16f18 <exit>
   18087:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   1808a:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   1808f:	c9                   	leave  
   18090:	c3                   	ret    

00018091 <progI>:
** Invoked as:  progI [ x [ n ] ]
**	 where x is the ID character (defaults to 'i')
**		   n is the number of children to spawn (defaults to 5)
*/

USERMAIN( progI ) {
   18091:	55                   	push   %ebp
   18092:	89 e5                	mov    %esp,%ebp
   18094:	81 ec 98 01 00 00    	sub    $0x198,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   1809a:	8b 45 0c             	mov    0xc(%ebp),%eax
   1809d:	8b 00                	mov    (%eax),%eax
   1809f:	85 c0                	test   %eax,%eax
   180a1:	74 07                	je     180aa <progI+0x19>
   180a3:	8b 45 0c             	mov    0xc(%ebp),%eax
   180a6:	8b 00                	mov    (%eax),%eax
   180a8:	eb 05                	jmp    180af <progI+0x1e>
   180aa:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   180af:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 5;	  // default child count
   180b2:	c7 45 f4 05 00 00 00 	movl   $0x5,-0xc(%ebp)
	char ch = 'i';	  // default character to print
   180b9:	c6 45 cf 69          	movb   $0x69,-0x31(%ebp)
	int nap = 5;	  // nap time
   180bd:	c7 45 dc 05 00 00 00 	movl   $0x5,-0x24(%ebp)
	char buf[128];
	char ch2[] = "*?*";
   180c4:	c7 85 4b ff ff ff 2a 	movl   $0x2a3f2a,-0xb5(%ebp)
   180cb:	3f 2a 00 
	uint_t children[MAX_CHILDREN];
	int nkids = 0;
   180ce:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

	// process the command-line arguments
	switch( argc ) {
   180d5:	8b 45 08             	mov    0x8(%ebp),%eax
   180d8:	83 f8 02             	cmp    $0x2,%eax
   180db:	74 29                	je     18106 <progI+0x75>
   180dd:	83 f8 03             	cmp    $0x3,%eax
   180e0:	74 0b                	je     180ed <progI+0x5c>
   180e2:	83 f8 01             	cmp    $0x1,%eax
   180e5:	0f 84 d8 00 00 00    	je     181c3 <progI+0x132>
   180eb:	eb 2c                	jmp    18119 <progI+0x88>
	case 3:	count = ustr2int( argv[2], 10 );
   180ed:	8b 45 0c             	mov    0xc(%ebp),%eax
   180f0:	83 c0 08             	add    $0x8,%eax
   180f3:	8b 00                	mov    (%eax),%eax
   180f5:	83 ec 08             	sub    $0x8,%esp
   180f8:	6a 0a                	push   $0xa
   180fa:	50                   	push   %eax
   180fb:	e8 37 1e 00 00       	call   19f37 <ustr2int>
   18100:	83 c4 10             	add    $0x10,%esp
   18103:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18106:	8b 45 0c             	mov    0xc(%ebp),%eax
   18109:	83 c0 04             	add    $0x4,%eax
   1810c:	8b 00                	mov    (%eax),%eax
   1810e:	0f b6 00             	movzbl (%eax),%eax
   18111:	88 45 cf             	mov    %al,-0x31(%ebp)
			break;
   18114:	e9 ab 00 00 00       	jmp    181c4 <progI+0x133>
	case 1:	// just use the defaults
			break;
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18119:	ff 75 08             	pushl  0x8(%ebp)
   1811c:	ff 75 e0             	pushl  -0x20(%ebp)
   1811f:	68 f1 bd 01 00       	push   $0x1bdf1
   18124:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   1812a:	50                   	push   %eax
   1812b:	e8 92 1b 00 00       	call   19cc2 <usprint>
   18130:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18133:	83 ec 0c             	sub    $0xc,%esp
   18136:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   1813c:	50                   	push   %eax
   1813d:	e8 6d 22 00 00       	call   1a3af <cwrites>
   18142:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18145:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   1814c:	eb 5b                	jmp    181a9 <progI+0x118>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   1814e:	8b 45 08             	mov    0x8(%ebp),%eax
   18151:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18158:	8b 45 0c             	mov    0xc(%ebp),%eax
   1815b:	01 d0                	add    %edx,%eax
   1815d:	8b 00                	mov    (%eax),%eax
   1815f:	85 c0                	test   %eax,%eax
   18161:	74 13                	je     18176 <progI+0xe5>
   18163:	8b 45 08             	mov    0x8(%ebp),%eax
   18166:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1816d:	8b 45 0c             	mov    0xc(%ebp),%eax
   18170:	01 d0                	add    %edx,%eax
   18172:	8b 00                	mov    (%eax),%eax
   18174:	eb 05                	jmp    1817b <progI+0xea>
   18176:	b8 05 be 01 00       	mov    $0x1be05,%eax
   1817b:	83 ec 04             	sub    $0x4,%esp
   1817e:	50                   	push   %eax
   1817f:	68 0c be 01 00       	push   $0x1be0c
   18184:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   1818a:	50                   	push   %eax
   1818b:	e8 32 1b 00 00       	call   19cc2 <usprint>
   18190:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   18193:	83 ec 0c             	sub    $0xc,%esp
   18196:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   1819c:	50                   	push   %eax
   1819d:	e8 0d 22 00 00       	call   1a3af <cwrites>
   181a2:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   181a5:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   181a9:	8b 45 ec             	mov    -0x14(%ebp),%eax
   181ac:	3b 45 08             	cmp    0x8(%ebp),%eax
   181af:	7e 9d                	jle    1814e <progI+0xbd>
			}
			cwrites( "\n" );
   181b1:	83 ec 0c             	sub    $0xc,%esp
   181b4:	68 10 be 01 00       	push   $0x1be10
   181b9:	e8 f1 21 00 00       	call   1a3af <cwrites>
   181be:	83 c4 10             	add    $0x10,%esp
   181c1:	eb 01                	jmp    181c4 <progI+0x133>
			break;
   181c3:	90                   	nop
	}

	// secondary output (for indicating errors)
	ch2[1] = ch;
   181c4:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   181c8:	88 85 4c ff ff ff    	mov    %al,-0xb4(%ebp)

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   181ce:	83 ec 04             	sub    $0x4,%esp
   181d1:	6a 01                	push   $0x1
   181d3:	8d 45 cf             	lea    -0x31(%ebp),%eax
   181d6:	50                   	push   %eax
   181d7:	6a 01                	push   $0x1
   181d9:	e8 62 ed ff ff       	call   16f40 <write>
   181de:	83 c4 10             	add    $0x10,%esp

	// set up the argument vector
	// we run:	progW 10 5

	char *argsw[] = { "progW", "W", "10", "5", NULL };
   181e1:	c7 85 6c fe ff ff d2 	movl   $0x1bed2,-0x194(%ebp)
   181e8:	be 01 00 
   181eb:	c7 85 70 fe ff ff e6 	movl   $0x1bbe6,-0x190(%ebp)
   181f2:	bb 01 00 
   181f5:	c7 85 74 fe ff ff 64 	movl   $0x1bb64,-0x18c(%ebp)
   181fc:	bb 01 00 
   181ff:	c7 85 78 fe ff ff 93 	movl   $0x1bb93,-0x188(%ebp)
   18206:	bb 01 00 
   18209:	c7 85 7c fe ff ff 00 	movl   $0x0,-0x184(%ebp)
   18210:	00 00 00 

	for( int i = 0; i < count; ++i ) {
   18213:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   1821a:	eb 5f                	jmp    1827b <progI+0x1ea>
		int whom = spawn( (uint32_t) progW, argsw );
   1821c:	ba 04 84 01 00       	mov    $0x18404,%edx
   18221:	83 ec 08             	sub    $0x8,%esp
   18224:	8d 85 6c fe ff ff    	lea    -0x194(%ebp),%eax
   1822a:	50                   	push   %eax
   1822b:	52                   	push   %edx
   1822c:	e8 e8 20 00 00       	call   1a319 <spawn>
   18231:	83 c4 10             	add    $0x10,%esp
   18234:	89 45 d0             	mov    %eax,-0x30(%ebp)
		if( whom < 0 ) {
   18237:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
   1823b:	79 14                	jns    18251 <progI+0x1c0>
			swrites( ch2 );
   1823d:	83 ec 0c             	sub    $0xc,%esp
   18240:	8d 85 4b ff ff ff    	lea    -0xb5(%ebp),%eax
   18246:	50                   	push   %eax
   18247:	e8 c9 21 00 00       	call   1a415 <swrites>
   1824c:	83 c4 10             	add    $0x10,%esp
   1824f:	eb 26                	jmp    18277 <progI+0x1e6>
		} else {
			swritech( ch );
   18251:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   18255:	0f be c0             	movsbl %al,%eax
   18258:	83 ec 0c             	sub    $0xc,%esp
   1825b:	50                   	push   %eax
   1825c:	e8 93 21 00 00       	call   1a3f4 <swritech>
   18261:	83 c4 10             	add    $0x10,%esp
			children[nkids++] = whom;
   18264:	8b 45 f0             	mov    -0x10(%ebp),%eax
   18267:	8d 50 01             	lea    0x1(%eax),%edx
   1826a:	89 55 f0             	mov    %edx,-0x10(%ebp)
   1826d:	8b 55 d0             	mov    -0x30(%ebp),%edx
   18270:	89 94 85 80 fe ff ff 	mov    %edx,-0x180(%ebp,%eax,4)
	for( int i = 0; i < count; ++i ) {
   18277:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   1827b:	8b 45 e8             	mov    -0x18(%ebp),%eax
   1827e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18281:	7c 99                	jl     1821c <progI+0x18b>
		}
	}

	// let the children start
	sleep( SEC_TO_MS(nap) );
   18283:	8b 45 dc             	mov    -0x24(%ebp),%eax
   18286:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   1828c:	83 ec 0c             	sub    $0xc,%esp
   1828f:	50                   	push   %eax
   18290:	e8 e3 ec ff ff       	call   16f78 <sleep>
   18295:	83 c4 10             	add    $0x10,%esp

	// kill two of them
	int32_t status = kill( children[1] );
   18298:	8b 85 84 fe ff ff    	mov    -0x17c(%ebp),%eax
   1829e:	83 ec 0c             	sub    $0xc,%esp
   182a1:	50                   	push   %eax
   182a2:	e8 c9 ec ff ff       	call   16f70 <kill>
   182a7:	83 c4 10             	add    $0x10,%esp
   182aa:	89 45 d8             	mov    %eax,-0x28(%ebp)
	if( status ) {
   182ad:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   182b1:	74 45                	je     182f8 <progI+0x267>
		usprint( buf, "!! %c: kill(%d) status %d\n", ch, children[1], status );
   182b3:	8b 95 84 fe ff ff    	mov    -0x17c(%ebp),%edx
   182b9:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   182bd:	0f be c0             	movsbl %al,%eax
   182c0:	83 ec 0c             	sub    $0xc,%esp
   182c3:	ff 75 d8             	pushl  -0x28(%ebp)
   182c6:	52                   	push   %edx
   182c7:	50                   	push   %eax
   182c8:	68 d8 be 01 00       	push   $0x1bed8
   182cd:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   182d3:	50                   	push   %eax
   182d4:	e8 e9 19 00 00       	call   19cc2 <usprint>
   182d9:	83 c4 20             	add    $0x20,%esp
		cwrites( buf );
   182dc:	83 ec 0c             	sub    $0xc,%esp
   182df:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   182e5:	50                   	push   %eax
   182e6:	e8 c4 20 00 00       	call   1a3af <cwrites>
   182eb:	83 c4 10             	add    $0x10,%esp
		children[1] = -42;
   182ee:	c7 85 84 fe ff ff d6 	movl   $0xffffffd6,-0x17c(%ebp)
   182f5:	ff ff ff 
	}
	status = kill( children[3] );
   182f8:	8b 85 8c fe ff ff    	mov    -0x174(%ebp),%eax
   182fe:	83 ec 0c             	sub    $0xc,%esp
   18301:	50                   	push   %eax
   18302:	e8 69 ec ff ff       	call   16f70 <kill>
   18307:	83 c4 10             	add    $0x10,%esp
   1830a:	89 45 d8             	mov    %eax,-0x28(%ebp)
	if( status ) {
   1830d:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   18311:	74 45                	je     18358 <progI+0x2c7>
		usprint( buf, "!! %c: kill(%d) status %d\n", ch, children[3], status );
   18313:	8b 95 8c fe ff ff    	mov    -0x174(%ebp),%edx
   18319:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   1831d:	0f be c0             	movsbl %al,%eax
   18320:	83 ec 0c             	sub    $0xc,%esp
   18323:	ff 75 d8             	pushl  -0x28(%ebp)
   18326:	52                   	push   %edx
   18327:	50                   	push   %eax
   18328:	68 d8 be 01 00       	push   $0x1bed8
   1832d:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   18333:	50                   	push   %eax
   18334:	e8 89 19 00 00       	call   19cc2 <usprint>
   18339:	83 c4 20             	add    $0x20,%esp
		cwrites( buf );
   1833c:	83 ec 0c             	sub    $0xc,%esp
   1833f:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   18345:	50                   	push   %eax
   18346:	e8 64 20 00 00       	call   1a3af <cwrites>
   1834b:	83 c4 10             	add    $0x10,%esp
		children[3] = -42;
   1834e:	c7 85 8c fe ff ff d6 	movl   $0xffffffd6,-0x174(%ebp)
   18355:	ff ff ff 
	}

	// collect child information
	while( 1 ) {
		int n = waitpid( 0, NULL );
   18358:	83 ec 08             	sub    $0x8,%esp
   1835b:	6a 00                	push   $0x0
   1835d:	6a 00                	push   $0x0
   1835f:	e8 bc eb ff ff       	call   16f20 <waitpid>
   18364:	83 c4 10             	add    $0x10,%esp
   18367:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		if( n == E_NO_CHILDREN ) {
   1836a:	83 7d d4 fc          	cmpl   $0xfffffffc,-0x2c(%ebp)
   1836e:	74 7f                	je     183ef <progI+0x35e>
			// all done!
			break;
		}
		for( int i = 0; i < count; ++i ) {
   18370:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   18377:	eb 54                	jmp    183cd <progI+0x33c>
			if( children[i] == n ) {
   18379:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   1837c:	8b 94 85 80 fe ff ff 	mov    -0x180(%ebp,%eax,4),%edx
   18383:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   18386:	39 c2                	cmp    %eax,%edx
   18388:	75 3f                	jne    183c9 <progI+0x338>
				usprint( buf, "== %c: child %d (%d)\n", ch, i, children[i] );
   1838a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   1838d:	8b 94 85 80 fe ff ff 	mov    -0x180(%ebp,%eax,4),%edx
   18394:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   18398:	0f be c0             	movsbl %al,%eax
   1839b:	83 ec 0c             	sub    $0xc,%esp
   1839e:	52                   	push   %edx
   1839f:	ff 75 e4             	pushl  -0x1c(%ebp)
   183a2:	50                   	push   %eax
   183a3:	68 f3 be 01 00       	push   $0x1bef3
   183a8:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   183ae:	50                   	push   %eax
   183af:	e8 0e 19 00 00       	call   19cc2 <usprint>
   183b4:	83 c4 20             	add    $0x20,%esp
				cwrites( buf );
   183b7:	83 ec 0c             	sub    $0xc,%esp
   183ba:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   183c0:	50                   	push   %eax
   183c1:	e8 e9 1f 00 00       	call   1a3af <cwrites>
   183c6:	83 c4 10             	add    $0x10,%esp
		for( int i = 0; i < count; ++i ) {
   183c9:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   183cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   183d0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   183d3:	7c a4                	jl     18379 <progI+0x2e8>
			}
		}
		sleep( SEC_TO_MS(nap) );
   183d5:	8b 45 dc             	mov    -0x24(%ebp),%eax
   183d8:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   183de:	83 ec 0c             	sub    $0xc,%esp
   183e1:	50                   	push   %eax
   183e2:	e8 91 eb ff ff       	call   16f78 <sleep>
   183e7:	83 c4 10             	add    $0x10,%esp
	while( 1 ) {
   183ea:	e9 69 ff ff ff       	jmp    18358 <progI+0x2c7>
			break;
   183ef:	90                   	nop
	};

	// let init() clean up after us!

	exit( 0 );
   183f0:	83 ec 0c             	sub    $0xc,%esp
   183f3:	6a 00                	push   $0x0
   183f5:	e8 1e eb ff ff       	call   16f18 <exit>
   183fa:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   183fd:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   18402:	c9                   	leave  
   18403:	c3                   	ret    

00018404 <progW>:
**	 where x is the ID character
**		   n is the iteration count (defaults to 20)
**		   s is the sleep time (defaults to 3 seconds)
*/

USERMAIN( progW ) {
   18404:	55                   	push   %ebp
   18405:	89 e5                	mov    %esp,%ebp
   18407:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   1840d:	8b 45 0c             	mov    0xc(%ebp),%eax
   18410:	8b 00                	mov    (%eax),%eax
   18412:	85 c0                	test   %eax,%eax
   18414:	74 07                	je     1841d <progW+0x19>
   18416:	8b 45 0c             	mov    0xc(%ebp),%eax
   18419:	8b 00                	mov    (%eax),%eax
   1841b:	eb 05                	jmp    18422 <progW+0x1e>
   1841d:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   18422:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int count = 20;	  // default iteration count
   18425:	c7 45 f4 14 00 00 00 	movl   $0x14,-0xc(%ebp)
	char ch = 'w';	  // default character to print
   1842c:	c6 45 db 77          	movb   $0x77,-0x25(%ebp)
	int nap = 3;	  // nap length
   18430:	c7 45 f0 03 00 00 00 	movl   $0x3,-0x10(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   18437:	8b 45 08             	mov    0x8(%ebp),%eax
   1843a:	83 f8 03             	cmp    $0x3,%eax
   1843d:	74 25                	je     18464 <progW+0x60>
   1843f:	83 f8 04             	cmp    $0x4,%eax
   18442:	74 07                	je     1844b <progW+0x47>
   18444:	83 f8 02             	cmp    $0x2,%eax
   18447:	74 34                	je     1847d <progW+0x79>
   18449:	eb 45                	jmp    18490 <progW+0x8c>
	case 4:	nap = ustr2int( argv[3], 10 );
   1844b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1844e:	83 c0 0c             	add    $0xc,%eax
   18451:	8b 00                	mov    (%eax),%eax
   18453:	83 ec 08             	sub    $0x8,%esp
   18456:	6a 0a                	push   $0xa
   18458:	50                   	push   %eax
   18459:	e8 d9 1a 00 00       	call   19f37 <ustr2int>
   1845e:	83 c4 10             	add    $0x10,%esp
   18461:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   18464:	8b 45 0c             	mov    0xc(%ebp),%eax
   18467:	83 c0 08             	add    $0x8,%eax
   1846a:	8b 00                	mov    (%eax),%eax
   1846c:	83 ec 08             	sub    $0x8,%esp
   1846f:	6a 0a                	push   $0xa
   18471:	50                   	push   %eax
   18472:	e8 c0 1a 00 00       	call   19f37 <ustr2int>
   18477:	83 c4 10             	add    $0x10,%esp
   1847a:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   1847d:	8b 45 0c             	mov    0xc(%ebp),%eax
   18480:	83 c0 04             	add    $0x4,%eax
   18483:	8b 00                	mov    (%eax),%eax
   18485:	0f b6 00             	movzbl (%eax),%eax
   18488:	88 45 db             	mov    %al,-0x25(%ebp)
			break;
   1848b:	e9 a8 00 00 00       	jmp    18538 <progW+0x134>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18490:	ff 75 08             	pushl  0x8(%ebp)
   18493:	ff 75 e4             	pushl  -0x1c(%ebp)
   18496:	68 f1 bd 01 00       	push   $0x1bdf1
   1849b:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   184a1:	50                   	push   %eax
   184a2:	e8 1b 18 00 00       	call   19cc2 <usprint>
   184a7:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   184aa:	83 ec 0c             	sub    $0xc,%esp
   184ad:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   184b3:	50                   	push   %eax
   184b4:	e8 f6 1e 00 00       	call   1a3af <cwrites>
   184b9:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   184bc:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   184c3:	eb 5b                	jmp    18520 <progW+0x11c>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   184c5:	8b 45 08             	mov    0x8(%ebp),%eax
   184c8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   184cf:	8b 45 0c             	mov    0xc(%ebp),%eax
   184d2:	01 d0                	add    %edx,%eax
   184d4:	8b 00                	mov    (%eax),%eax
   184d6:	85 c0                	test   %eax,%eax
   184d8:	74 13                	je     184ed <progW+0xe9>
   184da:	8b 45 08             	mov    0x8(%ebp),%eax
   184dd:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   184e4:	8b 45 0c             	mov    0xc(%ebp),%eax
   184e7:	01 d0                	add    %edx,%eax
   184e9:	8b 00                	mov    (%eax),%eax
   184eb:	eb 05                	jmp    184f2 <progW+0xee>
   184ed:	b8 05 be 01 00       	mov    $0x1be05,%eax
   184f2:	83 ec 04             	sub    $0x4,%esp
   184f5:	50                   	push   %eax
   184f6:	68 0c be 01 00       	push   $0x1be0c
   184fb:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18501:	50                   	push   %eax
   18502:	e8 bb 17 00 00       	call   19cc2 <usprint>
   18507:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1850a:	83 ec 0c             	sub    $0xc,%esp
   1850d:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18513:	50                   	push   %eax
   18514:	e8 96 1e 00 00       	call   1a3af <cwrites>
   18519:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1851c:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18520:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18523:	3b 45 08             	cmp    0x8(%ebp),%eax
   18526:	7e 9d                	jle    184c5 <progW+0xc1>
			}
			cwrites( "\n" );
   18528:	83 ec 0c             	sub    $0xc,%esp
   1852b:	68 10 be 01 00       	push   $0x1be10
   18530:	e8 7a 1e 00 00       	call   1a3af <cwrites>
   18535:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int pid = getpid();
   18538:	e8 0b ea ff ff       	call   16f48 <getpid>
   1853d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	uint32_t now = gettime();
   18540:	e8 13 ea ff ff       	call   16f58 <gettime>
   18545:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d,%u]", ch, pid, now );
   18548:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   1854c:	0f be c0             	movsbl %al,%eax
   1854f:	83 ec 0c             	sub    $0xc,%esp
   18552:	ff 75 dc             	pushl  -0x24(%ebp)
   18555:	ff 75 e0             	pushl  -0x20(%ebp)
   18558:	50                   	push   %eax
   18559:	68 09 bf 01 00       	push   $0x1bf09
   1855e:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18564:	50                   	push   %eax
   18565:	e8 58 17 00 00       	call   19cc2 <usprint>
   1856a:	83 c4 20             	add    $0x20,%esp
	swrites( buf );
   1856d:	83 ec 0c             	sub    $0xc,%esp
   18570:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18576:	50                   	push   %eax
   18577:	e8 99 1e 00 00       	call   1a415 <swrites>
   1857c:	83 c4 10             	add    $0x10,%esp

	write( CHAN_SIO, &ch, 1 );
   1857f:	83 ec 04             	sub    $0x4,%esp
   18582:	6a 01                	push   $0x1
   18584:	8d 45 db             	lea    -0x25(%ebp),%eax
   18587:	50                   	push   %eax
   18588:	6a 01                	push   $0x1
   1858a:	e8 b1 e9 ff ff       	call   16f40 <write>
   1858f:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   18592:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18599:	eb 58                	jmp    185f3 <progW+0x1ef>
		now = gettime();
   1859b:	e8 b8 e9 ff ff       	call   16f58 <gettime>
   185a0:	89 45 dc             	mov    %eax,-0x24(%ebp)
		usprint( buf, " %c[%d,%u] ", ch, pid, now );
   185a3:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   185a7:	0f be c0             	movsbl %al,%eax
   185aa:	83 ec 0c             	sub    $0xc,%esp
   185ad:	ff 75 dc             	pushl  -0x24(%ebp)
   185b0:	ff 75 e0             	pushl  -0x20(%ebp)
   185b3:	50                   	push   %eax
   185b4:	68 14 bf 01 00       	push   $0x1bf14
   185b9:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   185bf:	50                   	push   %eax
   185c0:	e8 fd 16 00 00       	call   19cc2 <usprint>
   185c5:	83 c4 20             	add    $0x20,%esp
		swrites( buf );
   185c8:	83 ec 0c             	sub    $0xc,%esp
   185cb:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   185d1:	50                   	push   %eax
   185d2:	e8 3e 1e 00 00       	call   1a415 <swrites>
   185d7:	83 c4 10             	add    $0x10,%esp
		sleep( SEC_TO_MS(nap) );
   185da:	8b 45 f0             	mov    -0x10(%ebp),%eax
   185dd:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   185e3:	83 ec 0c             	sub    $0xc,%esp
   185e6:	50                   	push   %eax
   185e7:	e8 8c e9 ff ff       	call   16f78 <sleep>
   185ec:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   185ef:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   185f3:	8b 45 e8             	mov    -0x18(%ebp),%eax
   185f6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   185f9:	7c a0                	jl     1859b <progW+0x197>
	}

	exit( 0 );
   185fb:	83 ec 0c             	sub    $0xc,%esp
   185fe:	6a 00                	push   $0x0
   18600:	e8 13 e9 ff ff       	call   16f18 <exit>
   18605:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18608:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   1860d:	c9                   	leave  
   1860e:	c3                   	ret    

0001860f <progJ>:
** Invoked as:  progJ  x  [ n ]
**	 where x is the ID character
**		   n is the number of children to spawn (defaults to 2 * N_PROCS)
*/

USERMAIN( progJ ) {
   1860f:	55                   	push   %ebp
   18610:	89 e5                	mov    %esp,%ebp
   18612:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18618:	8b 45 0c             	mov    0xc(%ebp),%eax
   1861b:	8b 00                	mov    (%eax),%eax
   1861d:	85 c0                	test   %eax,%eax
   1861f:	74 07                	je     18628 <progJ+0x19>
   18621:	8b 45 0c             	mov    0xc(%ebp),%eax
   18624:	8b 00                	mov    (%eax),%eax
   18626:	eb 05                	jmp    1862d <progJ+0x1e>
   18628:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   1862d:	89 45 e8             	mov    %eax,-0x18(%ebp)
	int count = 2 * N_PROCS;	// number of children to spawn
   18630:	c7 45 f4 32 00 00 00 	movl   $0x32,-0xc(%ebp)
	char ch = 'j';				// default character to print
   18637:	c6 45 e3 6a          	movb   $0x6a,-0x1d(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   1863b:	8b 45 08             	mov    0x8(%ebp),%eax
   1863e:	83 f8 02             	cmp    $0x2,%eax
   18641:	74 1e                	je     18661 <progJ+0x52>
   18643:	83 f8 03             	cmp    $0x3,%eax
   18646:	75 2c                	jne    18674 <progJ+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   18648:	8b 45 0c             	mov    0xc(%ebp),%eax
   1864b:	83 c0 08             	add    $0x8,%eax
   1864e:	8b 00                	mov    (%eax),%eax
   18650:	83 ec 08             	sub    $0x8,%esp
   18653:	6a 0a                	push   $0xa
   18655:	50                   	push   %eax
   18656:	e8 dc 18 00 00       	call   19f37 <ustr2int>
   1865b:	83 c4 10             	add    $0x10,%esp
   1865e:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18661:	8b 45 0c             	mov    0xc(%ebp),%eax
   18664:	83 c0 04             	add    $0x4,%eax
   18667:	8b 00                	mov    (%eax),%eax
   18669:	0f b6 00             	movzbl (%eax),%eax
   1866c:	88 45 e3             	mov    %al,-0x1d(%ebp)
			break;
   1866f:	e9 a8 00 00 00       	jmp    1871c <progJ+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18674:	ff 75 08             	pushl  0x8(%ebp)
   18677:	ff 75 e8             	pushl  -0x18(%ebp)
   1867a:	68 f1 bd 01 00       	push   $0x1bdf1
   1867f:	8d 85 63 ff ff ff    	lea    -0x9d(%ebp),%eax
   18685:	50                   	push   %eax
   18686:	e8 37 16 00 00       	call   19cc2 <usprint>
   1868b:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1868e:	83 ec 0c             	sub    $0xc,%esp
   18691:	8d 85 63 ff ff ff    	lea    -0x9d(%ebp),%eax
   18697:	50                   	push   %eax
   18698:	e8 12 1d 00 00       	call   1a3af <cwrites>
   1869d:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   186a0:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   186a7:	eb 5b                	jmp    18704 <progJ+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   186a9:	8b 45 08             	mov    0x8(%ebp),%eax
   186ac:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   186b3:	8b 45 0c             	mov    0xc(%ebp),%eax
   186b6:	01 d0                	add    %edx,%eax
   186b8:	8b 00                	mov    (%eax),%eax
   186ba:	85 c0                	test   %eax,%eax
   186bc:	74 13                	je     186d1 <progJ+0xc2>
   186be:	8b 45 08             	mov    0x8(%ebp),%eax
   186c1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   186c8:	8b 45 0c             	mov    0xc(%ebp),%eax
   186cb:	01 d0                	add    %edx,%eax
   186cd:	8b 00                	mov    (%eax),%eax
   186cf:	eb 05                	jmp    186d6 <progJ+0xc7>
   186d1:	b8 05 be 01 00       	mov    $0x1be05,%eax
   186d6:	83 ec 04             	sub    $0x4,%esp
   186d9:	50                   	push   %eax
   186da:	68 0c be 01 00       	push   $0x1be0c
   186df:	8d 85 63 ff ff ff    	lea    -0x9d(%ebp),%eax
   186e5:	50                   	push   %eax
   186e6:	e8 d7 15 00 00       	call   19cc2 <usprint>
   186eb:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   186ee:	83 ec 0c             	sub    $0xc,%esp
   186f1:	8d 85 63 ff ff ff    	lea    -0x9d(%ebp),%eax
   186f7:	50                   	push   %eax
   186f8:	e8 b2 1c 00 00       	call   1a3af <cwrites>
   186fd:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18700:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   18704:	8b 45 f0             	mov    -0x10(%ebp),%eax
   18707:	3b 45 08             	cmp    0x8(%ebp),%eax
   1870a:	7e 9d                	jle    186a9 <progJ+0x9a>
			}
			cwrites( "\n" );
   1870c:	83 ec 0c             	sub    $0xc,%esp
   1870f:	68 10 be 01 00       	push   $0x1be10
   18714:	e8 96 1c 00 00       	call   1a3af <cwrites>
   18719:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   1871c:	83 ec 04             	sub    $0x4,%esp
   1871f:	6a 01                	push   $0x1
   18721:	8d 45 e3             	lea    -0x1d(%ebp),%eax
   18724:	50                   	push   %eax
   18725:	6a 01                	push   $0x1
   18727:	e8 14 e8 ff ff       	call   16f40 <write>
   1872c:	83 c4 10             	add    $0x10,%esp

	// set up the command-line arguments
	char *argsy[] = { "progY", "Y", "10", NULL };
   1872f:	c7 85 50 ff ff ff 20 	movl   $0x1bf20,-0xb0(%ebp)
   18736:	bf 01 00 
   18739:	c7 85 54 ff ff ff 26 	movl   $0x1bf26,-0xac(%ebp)
   18740:	bf 01 00 
   18743:	c7 85 58 ff ff ff 64 	movl   $0x1bb64,-0xa8(%ebp)
   1874a:	bb 01 00 
   1874d:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
   18754:	00 00 00 

	for( int i = 0; i < count ; ++i ) {
   18757:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   1875e:	eb 4e                	jmp    187ae <progJ+0x19f>
		int whom = spawn( (uint32_t) progY, argsy );
   18760:	ba ca 87 01 00       	mov    $0x187ca,%edx
   18765:	83 ec 08             	sub    $0x8,%esp
   18768:	8d 85 50 ff ff ff    	lea    -0xb0(%ebp),%eax
   1876e:	50                   	push   %eax
   1876f:	52                   	push   %edx
   18770:	e8 a4 1b 00 00       	call   1a319 <spawn>
   18775:	83 c4 10             	add    $0x10,%esp
   18778:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		if( whom < 0 ) {
   1877b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   1877f:	79 16                	jns    18797 <progJ+0x188>
			write( CHAN_SIO, "!j!", 3 );
   18781:	83 ec 04             	sub    $0x4,%esp
   18784:	6a 03                	push   $0x3
   18786:	68 28 bf 01 00       	push   $0x1bf28
   1878b:	6a 01                	push   $0x1
   1878d:	e8 ae e7 ff ff       	call   16f40 <write>
   18792:	83 c4 10             	add    $0x10,%esp
   18795:	eb 13                	jmp    187aa <progJ+0x19b>
		} else {
			write( CHAN_SIO, &ch, 1 );
   18797:	83 ec 04             	sub    $0x4,%esp
   1879a:	6a 01                	push   $0x1
   1879c:	8d 45 e3             	lea    -0x1d(%ebp),%eax
   1879f:	50                   	push   %eax
   187a0:	6a 01                	push   $0x1
   187a2:	e8 99 e7 ff ff       	call   16f40 <write>
   187a7:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   187aa:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   187ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
   187b1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   187b4:	7c aa                	jl     18760 <progJ+0x151>
		}
	}

	exit( 0 );
   187b6:	83 ec 0c             	sub    $0xc,%esp
   187b9:	6a 00                	push   $0x0
   187bb:	e8 58 e7 ff ff       	call   16f18 <exit>
   187c0:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   187c3:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   187c8:	c9                   	leave  
   187c9:	c3                   	ret    

000187ca <progY>:
** Invoked as:	progY  x  [ n ]
**	 where x is the ID character
**		   n is the iteration count (defaults to 10)
*/

USERMAIN( progY ) {
   187ca:	55                   	push   %ebp
   187cb:	89 e5                	mov    %esp,%ebp
   187cd:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   187d3:	8b 45 0c             	mov    0xc(%ebp),%eax
   187d6:	8b 00                	mov    (%eax),%eax
   187d8:	85 c0                	test   %eax,%eax
   187da:	74 07                	je     187e3 <progY+0x19>
   187dc:	8b 45 0c             	mov    0xc(%ebp),%eax
   187df:	8b 00                	mov    (%eax),%eax
   187e1:	eb 05                	jmp    187e8 <progY+0x1e>
   187e3:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   187e8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 10;	  // default iteration count
   187eb:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
	char ch = 'y';	  // default character to print
   187f2:	c6 45 f3 79          	movb   $0x79,-0xd(%ebp)
	char buf[128];

	(void) name;

	// process the command-line arguments
	switch( argc ) {
   187f6:	8b 45 08             	mov    0x8(%ebp),%eax
   187f9:	83 f8 02             	cmp    $0x2,%eax
   187fc:	74 1e                	je     1881c <progY+0x52>
   187fe:	83 f8 03             	cmp    $0x3,%eax
   18801:	75 2c                	jne    1882f <progY+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   18803:	8b 45 0c             	mov    0xc(%ebp),%eax
   18806:	83 c0 08             	add    $0x8,%eax
   18809:	8b 00                	mov    (%eax),%eax
   1880b:	83 ec 08             	sub    $0x8,%esp
   1880e:	6a 0a                	push   $0xa
   18810:	50                   	push   %eax
   18811:	e8 21 17 00 00       	call   19f37 <ustr2int>
   18816:	83 c4 10             	add    $0x10,%esp
   18819:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   1881c:	8b 45 0c             	mov    0xc(%ebp),%eax
   1881f:	83 c0 04             	add    $0x4,%eax
   18822:	8b 00                	mov    (%eax),%eax
   18824:	0f b6 00             	movzbl (%eax),%eax
   18827:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   1882a:	e9 a8 00 00 00       	jmp    188d7 <progY+0x10d>
	default:
			usprint( buf, "?: argc %d, args: ", argc );
   1882f:	83 ec 04             	sub    $0x4,%esp
   18832:	ff 75 08             	pushl  0x8(%ebp)
   18835:	68 b7 be 01 00       	push   $0x1beb7
   1883a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18840:	50                   	push   %eax
   18841:	e8 7c 14 00 00       	call   19cc2 <usprint>
   18846:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18849:	83 ec 0c             	sub    $0xc,%esp
   1884c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18852:	50                   	push   %eax
   18853:	e8 57 1b 00 00       	call   1a3af <cwrites>
   18858:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1885b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18862:	eb 5b                	jmp    188bf <progY+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18864:	8b 45 08             	mov    0x8(%ebp),%eax
   18867:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1886e:	8b 45 0c             	mov    0xc(%ebp),%eax
   18871:	01 d0                	add    %edx,%eax
   18873:	8b 00                	mov    (%eax),%eax
   18875:	85 c0                	test   %eax,%eax
   18877:	74 13                	je     1888c <progY+0xc2>
   18879:	8b 45 08             	mov    0x8(%ebp),%eax
   1887c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18883:	8b 45 0c             	mov    0xc(%ebp),%eax
   18886:	01 d0                	add    %edx,%eax
   18888:	8b 00                	mov    (%eax),%eax
   1888a:	eb 05                	jmp    18891 <progY+0xc7>
   1888c:	b8 05 be 01 00       	mov    $0x1be05,%eax
   18891:	83 ec 04             	sub    $0x4,%esp
   18894:	50                   	push   %eax
   18895:	68 0c be 01 00       	push   $0x1be0c
   1889a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   188a0:	50                   	push   %eax
   188a1:	e8 1c 14 00 00       	call   19cc2 <usprint>
   188a6:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   188a9:	83 ec 0c             	sub    $0xc,%esp
   188ac:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   188b2:	50                   	push   %eax
   188b3:	e8 f7 1a 00 00       	call   1a3af <cwrites>
   188b8:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   188bb:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   188bf:	8b 45 ec             	mov    -0x14(%ebp),%eax
   188c2:	3b 45 08             	cmp    0x8(%ebp),%eax
   188c5:	7e 9d                	jle    18864 <progY+0x9a>
			}
			cwrites( "\n" );
   188c7:	83 ec 0c             	sub    $0xc,%esp
   188ca:	68 10 be 01 00       	push   $0x1be10
   188cf:	e8 db 1a 00 00       	call   1a3af <cwrites>
   188d4:	83 c4 10             	add    $0x10,%esp
	}

	// report our presence
	int pid = getpid();
   188d7:	e8 6c e6 ff ff       	call   16f48 <getpid>
   188dc:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d]", ch, pid );
   188df:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   188e3:	ff 75 dc             	pushl  -0x24(%ebp)
   188e6:	50                   	push   %eax
   188e7:	68 ca be 01 00       	push   $0x1beca
   188ec:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   188f2:	50                   	push   %eax
   188f3:	e8 ca 13 00 00       	call   19cc2 <usprint>
   188f8:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   188fb:	83 ec 0c             	sub    $0xc,%esp
   188fe:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18904:	50                   	push   %eax
   18905:	e8 0b 1b 00 00       	call   1a415 <swrites>
   1890a:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   1890d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18914:	eb 3c                	jmp    18952 <progY+0x188>
		swrites( buf );
   18916:	83 ec 0c             	sub    $0xc,%esp
   18919:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1891f:	50                   	push   %eax
   18920:	e8 f0 1a 00 00       	call   1a415 <swrites>
   18925:	83 c4 10             	add    $0x10,%esp
		DELAY(STD);
   18928:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   1892f:	eb 04                	jmp    18935 <progY+0x16b>
   18931:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   18935:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   1893c:	7e f3                	jle    18931 <progY+0x167>
		sleep( SEC_TO_MS(1) );
   1893e:	83 ec 0c             	sub    $0xc,%esp
   18941:	68 e8 03 00 00       	push   $0x3e8
   18946:	e8 2d e6 ff ff       	call   16f78 <sleep>
   1894b:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   1894e:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18952:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18955:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18958:	7c bc                	jl     18916 <progY+0x14c>
	}

	exit( 0 );
   1895a:	83 ec 0c             	sub    $0xc,%esp
   1895d:	6a 00                	push   $0x0
   1895f:	e8 b4 e5 ff ff       	call   16f18 <exit>
   18964:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18967:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   1896c:	c9                   	leave  
   1896d:	c3                   	ret    

0001896e <progKL>:
** Invoked as:  progKL  x  n
**	 where x is the ID character
**		   n is the iteration count (defaults to 5)
*/

USERMAIN( progKL ) {
   1896e:	55                   	push   %ebp
   1896f:	89 e5                	mov    %esp,%ebp
   18971:	83 ec 58             	sub    $0x58,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18974:	8b 45 0c             	mov    0xc(%ebp),%eax
   18977:	8b 00                	mov    (%eax),%eax
   18979:	85 c0                	test   %eax,%eax
   1897b:	74 07                	je     18984 <progKL+0x16>
   1897d:	8b 45 0c             	mov    0xc(%ebp),%eax
   18980:	8b 00                	mov    (%eax),%eax
   18982:	eb 05                	jmp    18989 <progKL+0x1b>
   18984:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   18989:	89 45 e8             	mov    %eax,-0x18(%ebp)
	int count = 5;			// default iteration count
   1898c:	c7 45 f4 05 00 00 00 	movl   $0x5,-0xc(%ebp)
	char ch = '4';			// default character to print
   18993:	c6 45 df 34          	movb   $0x34,-0x21(%ebp)
	int nap = 30;			// nap time
   18997:	c7 45 e4 1e 00 00 00 	movl   $0x1e,-0x1c(%ebp)
	char msg2[] = "*4*";	// "error" message to print
   1899e:	c7 45 db 2a 34 2a 00 	movl   $0x2a342a,-0x25(%ebp)
	char buf[32];

	// process the command-line arguments
	switch( argc ) {
   189a5:	8b 45 08             	mov    0x8(%ebp),%eax
   189a8:	83 f8 02             	cmp    $0x2,%eax
   189ab:	74 1e                	je     189cb <progKL+0x5d>
   189ad:	83 f8 03             	cmp    $0x3,%eax
   189b0:	75 2c                	jne    189de <progKL+0x70>
	case 3:	count = ustr2int( argv[2], 10 );
   189b2:	8b 45 0c             	mov    0xc(%ebp),%eax
   189b5:	83 c0 08             	add    $0x8,%eax
   189b8:	8b 00                	mov    (%eax),%eax
   189ba:	83 ec 08             	sub    $0x8,%esp
   189bd:	6a 0a                	push   $0xa
   189bf:	50                   	push   %eax
   189c0:	e8 72 15 00 00       	call   19f37 <ustr2int>
   189c5:	83 c4 10             	add    $0x10,%esp
   189c8:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   189cb:	8b 45 0c             	mov    0xc(%ebp),%eax
   189ce:	83 c0 04             	add    $0x4,%eax
   189d1:	8b 00                	mov    (%eax),%eax
   189d3:	0f b6 00             	movzbl (%eax),%eax
   189d6:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   189d9:	e9 9c 00 00 00       	jmp    18a7a <progKL+0x10c>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   189de:	ff 75 08             	pushl  0x8(%ebp)
   189e1:	ff 75 e8             	pushl  -0x18(%ebp)
   189e4:	68 f1 bd 01 00       	push   $0x1bdf1
   189e9:	8d 45 bb             	lea    -0x45(%ebp),%eax
   189ec:	50                   	push   %eax
   189ed:	e8 d0 12 00 00       	call   19cc2 <usprint>
   189f2:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   189f5:	83 ec 0c             	sub    $0xc,%esp
   189f8:	8d 45 bb             	lea    -0x45(%ebp),%eax
   189fb:	50                   	push   %eax
   189fc:	e8 ae 19 00 00       	call   1a3af <cwrites>
   18a01:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18a04:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   18a0b:	eb 55                	jmp    18a62 <progKL+0xf4>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18a0d:	8b 45 08             	mov    0x8(%ebp),%eax
   18a10:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18a17:	8b 45 0c             	mov    0xc(%ebp),%eax
   18a1a:	01 d0                	add    %edx,%eax
   18a1c:	8b 00                	mov    (%eax),%eax
   18a1e:	85 c0                	test   %eax,%eax
   18a20:	74 13                	je     18a35 <progKL+0xc7>
   18a22:	8b 45 08             	mov    0x8(%ebp),%eax
   18a25:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18a2c:	8b 45 0c             	mov    0xc(%ebp),%eax
   18a2f:	01 d0                	add    %edx,%eax
   18a31:	8b 00                	mov    (%eax),%eax
   18a33:	eb 05                	jmp    18a3a <progKL+0xcc>
   18a35:	b8 05 be 01 00       	mov    $0x1be05,%eax
   18a3a:	83 ec 04             	sub    $0x4,%esp
   18a3d:	50                   	push   %eax
   18a3e:	68 0c be 01 00       	push   $0x1be0c
   18a43:	8d 45 bb             	lea    -0x45(%ebp),%eax
   18a46:	50                   	push   %eax
   18a47:	e8 76 12 00 00       	call   19cc2 <usprint>
   18a4c:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   18a4f:	83 ec 0c             	sub    $0xc,%esp
   18a52:	8d 45 bb             	lea    -0x45(%ebp),%eax
   18a55:	50                   	push   %eax
   18a56:	e8 54 19 00 00       	call   1a3af <cwrites>
   18a5b:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18a5e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   18a62:	8b 45 f0             	mov    -0x10(%ebp),%eax
   18a65:	3b 45 08             	cmp    0x8(%ebp),%eax
   18a68:	7e a3                	jle    18a0d <progKL+0x9f>
			}
			cwrites( "\n" );
   18a6a:	83 ec 0c             	sub    $0xc,%esp
   18a6d:	68 10 be 01 00       	push   $0x1be10
   18a72:	e8 38 19 00 00       	call   1a3af <cwrites>
   18a77:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   18a7a:	83 ec 04             	sub    $0x4,%esp
   18a7d:	6a 01                	push   $0x1
   18a7f:	8d 45 df             	lea    -0x21(%ebp),%eax
   18a82:	50                   	push   %eax
   18a83:	6a 01                	push   $0x1
   18a85:	e8 b6 e4 ff ff       	call   16f40 <write>
   18a8a:	83 c4 10             	add    $0x10,%esp

	// argument vector for the processes we will spawn
	char *arglist[] = { "progX", "X", buf, NULL };
   18a8d:	c7 45 a8 2c bf 01 00 	movl   $0x1bf2c,-0x58(%ebp)
   18a94:	c7 45 ac 32 bf 01 00 	movl   $0x1bf32,-0x54(%ebp)
   18a9b:	8d 45 bb             	lea    -0x45(%ebp),%eax
   18a9e:	89 45 b0             	mov    %eax,-0x50(%ebp)
   18aa1:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)

	for( int i = 0; i < count ; ++i ) {
   18aa8:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18aaf:	e9 89 00 00 00       	jmp    18b3d <progKL+0x1cf>

		write( CHAN_SIO, &ch, 1 );
   18ab4:	83 ec 04             	sub    $0x4,%esp
   18ab7:	6a 01                	push   $0x1
   18ab9:	8d 45 df             	lea    -0x21(%ebp),%eax
   18abc:	50                   	push   %eax
   18abd:	6a 01                	push   $0x1
   18abf:	e8 7c e4 ff ff       	call   16f40 <write>
   18ac4:	83 c4 10             	add    $0x10,%esp

		// second argument to X is 100 plus the iteration number
		usprint( buf, "%d", 100 + i );
   18ac7:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18aca:	83 c0 64             	add    $0x64,%eax
   18acd:	83 ec 04             	sub    $0x4,%esp
   18ad0:	50                   	push   %eax
   18ad1:	68 34 bf 01 00       	push   $0x1bf34
   18ad6:	8d 45 bb             	lea    -0x45(%ebp),%eax
   18ad9:	50                   	push   %eax
   18ada:	e8 e3 11 00 00       	call   19cc2 <usprint>
   18adf:	83 c4 10             	add    $0x10,%esp
		int whom = spawn( (uint32_t) progX, arglist );
   18ae2:	ba 5d 8b 01 00       	mov    $0x18b5d,%edx
   18ae7:	83 ec 08             	sub    $0x8,%esp
   18aea:	8d 45 a8             	lea    -0x58(%ebp),%eax
   18aed:	50                   	push   %eax
   18aee:	52                   	push   %edx
   18aef:	e8 25 18 00 00       	call   1a319 <spawn>
   18af4:	83 c4 10             	add    $0x10,%esp
   18af7:	89 45 e0             	mov    %eax,-0x20(%ebp)
		if( whom < 0 ) {
   18afa:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   18afe:	79 11                	jns    18b11 <progKL+0x1a3>
			swrites( msg2 );
   18b00:	83 ec 0c             	sub    $0xc,%esp
   18b03:	8d 45 db             	lea    -0x25(%ebp),%eax
   18b06:	50                   	push   %eax
   18b07:	e8 09 19 00 00       	call   1a415 <swrites>
   18b0c:	83 c4 10             	add    $0x10,%esp
   18b0f:	eb 13                	jmp    18b24 <progKL+0x1b6>
		} else {
			write( CHAN_SIO, &ch, 1 );
   18b11:	83 ec 04             	sub    $0x4,%esp
   18b14:	6a 01                	push   $0x1
   18b16:	8d 45 df             	lea    -0x21(%ebp),%eax
   18b19:	50                   	push   %eax
   18b1a:	6a 01                	push   $0x1
   18b1c:	e8 1f e4 ff ff       	call   16f40 <write>
   18b21:	83 c4 10             	add    $0x10,%esp
		}

		sleep( SEC_TO_MS(nap) );
   18b24:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   18b27:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   18b2d:	83 ec 0c             	sub    $0xc,%esp
   18b30:	50                   	push   %eax
   18b31:	e8 42 e4 ff ff       	call   16f78 <sleep>
   18b36:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   18b39:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18b3d:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18b40:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18b43:	0f 8c 6b ff ff ff    	jl     18ab4 <progKL+0x146>
	}

	exit( 0 );
   18b49:	83 ec 0c             	sub    $0xc,%esp
   18b4c:	6a 00                	push   $0x0
   18b4e:	e8 c5 e3 ff ff       	call   16f18 <exit>
   18b53:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18b56:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   18b5b:	c9                   	leave  
   18b5c:	c3                   	ret    

00018b5d <progX>:
** Invoked as:  progX  x  n
**	 where x is the ID character
**		   n is the iteration count
*/

USERMAIN( progX ) {
   18b5d:	55                   	push   %ebp
   18b5e:	89 e5                	mov    %esp,%ebp
   18b60:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18b66:	8b 45 0c             	mov    0xc(%ebp),%eax
   18b69:	8b 00                	mov    (%eax),%eax
   18b6b:	85 c0                	test   %eax,%eax
   18b6d:	74 07                	je     18b76 <progX+0x19>
   18b6f:	8b 45 0c             	mov    0xc(%ebp),%eax
   18b72:	8b 00                	mov    (%eax),%eax
   18b74:	eb 05                	jmp    18b7b <progX+0x1e>
   18b76:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   18b7b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 20;	  // iteration count
   18b7e:	c7 45 f4 14 00 00 00 	movl   $0x14,-0xc(%ebp)
	char ch = 'x';	  // default character to print
   18b85:	c6 45 f3 78          	movb   $0x78,-0xd(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   18b89:	8b 45 08             	mov    0x8(%ebp),%eax
   18b8c:	83 f8 02             	cmp    $0x2,%eax
   18b8f:	74 1e                	je     18baf <progX+0x52>
   18b91:	83 f8 03             	cmp    $0x3,%eax
   18b94:	75 2c                	jne    18bc2 <progX+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   18b96:	8b 45 0c             	mov    0xc(%ebp),%eax
   18b99:	83 c0 08             	add    $0x8,%eax
   18b9c:	8b 00                	mov    (%eax),%eax
   18b9e:	83 ec 08             	sub    $0x8,%esp
   18ba1:	6a 0a                	push   $0xa
   18ba3:	50                   	push   %eax
   18ba4:	e8 8e 13 00 00       	call   19f37 <ustr2int>
   18ba9:	83 c4 10             	add    $0x10,%esp
   18bac:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18baf:	8b 45 0c             	mov    0xc(%ebp),%eax
   18bb2:	83 c0 04             	add    $0x4,%eax
   18bb5:	8b 00                	mov    (%eax),%eax
   18bb7:	0f b6 00             	movzbl (%eax),%eax
   18bba:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   18bbd:	e9 a8 00 00 00       	jmp    18c6a <progX+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18bc2:	ff 75 08             	pushl  0x8(%ebp)
   18bc5:	ff 75 e0             	pushl  -0x20(%ebp)
   18bc8:	68 f1 bd 01 00       	push   $0x1bdf1
   18bcd:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18bd3:	50                   	push   %eax
   18bd4:	e8 e9 10 00 00       	call   19cc2 <usprint>
   18bd9:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18bdc:	83 ec 0c             	sub    $0xc,%esp
   18bdf:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18be5:	50                   	push   %eax
   18be6:	e8 c4 17 00 00       	call   1a3af <cwrites>
   18beb:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18bee:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18bf5:	eb 5b                	jmp    18c52 <progX+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18bf7:	8b 45 08             	mov    0x8(%ebp),%eax
   18bfa:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18c01:	8b 45 0c             	mov    0xc(%ebp),%eax
   18c04:	01 d0                	add    %edx,%eax
   18c06:	8b 00                	mov    (%eax),%eax
   18c08:	85 c0                	test   %eax,%eax
   18c0a:	74 13                	je     18c1f <progX+0xc2>
   18c0c:	8b 45 08             	mov    0x8(%ebp),%eax
   18c0f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18c16:	8b 45 0c             	mov    0xc(%ebp),%eax
   18c19:	01 d0                	add    %edx,%eax
   18c1b:	8b 00                	mov    (%eax),%eax
   18c1d:	eb 05                	jmp    18c24 <progX+0xc7>
   18c1f:	b8 05 be 01 00       	mov    $0x1be05,%eax
   18c24:	83 ec 04             	sub    $0x4,%esp
   18c27:	50                   	push   %eax
   18c28:	68 0c be 01 00       	push   $0x1be0c
   18c2d:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18c33:	50                   	push   %eax
   18c34:	e8 89 10 00 00       	call   19cc2 <usprint>
   18c39:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   18c3c:	83 ec 0c             	sub    $0xc,%esp
   18c3f:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18c45:	50                   	push   %eax
   18c46:	e8 64 17 00 00       	call   1a3af <cwrites>
   18c4b:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18c4e:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18c52:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18c55:	3b 45 08             	cmp    0x8(%ebp),%eax
   18c58:	7e 9d                	jle    18bf7 <progX+0x9a>
			}
			cwrites( "\n" );
   18c5a:	83 ec 0c             	sub    $0xc,%esp
   18c5d:	68 10 be 01 00       	push   $0x1be10
   18c62:	e8 48 17 00 00       	call   1a3af <cwrites>
   18c67:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int pid = getpid();
   18c6a:	e8 d9 e2 ff ff       	call   16f48 <getpid>
   18c6f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d]", ch, pid );
   18c72:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   18c76:	ff 75 dc             	pushl  -0x24(%ebp)
   18c79:	50                   	push   %eax
   18c7a:	68 ca be 01 00       	push   $0x1beca
   18c7f:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18c85:	50                   	push   %eax
   18c86:	e8 37 10 00 00       	call   19cc2 <usprint>
   18c8b:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   18c8e:	83 ec 0c             	sub    $0xc,%esp
   18c91:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18c97:	50                   	push   %eax
   18c98:	e8 78 17 00 00       	call   1a415 <swrites>
   18c9d:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   18ca0:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18ca7:	eb 2c                	jmp    18cd5 <progX+0x178>
		swrites( buf );
   18ca9:	83 ec 0c             	sub    $0xc,%esp
   18cac:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18cb2:	50                   	push   %eax
   18cb3:	e8 5d 17 00 00       	call   1a415 <swrites>
   18cb8:	83 c4 10             	add    $0x10,%esp
		DELAY(STD);
   18cbb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   18cc2:	eb 04                	jmp    18cc8 <progX+0x16b>
   18cc4:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   18cc8:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   18ccf:	7e f3                	jle    18cc4 <progX+0x167>
	for( int i = 0; i < count ; ++i ) {
   18cd1:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18cd5:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18cd8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18cdb:	7c cc                	jl     18ca9 <progX+0x14c>
	}

	exit( 12 );
   18cdd:	83 ec 0c             	sub    $0xc,%esp
   18ce0:	6a 0c                	push   $0xc
   18ce2:	e8 31 e2 ff ff       	call   16f18 <exit>
   18ce7:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18cea:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   18cef:	c9                   	leave  
   18cf0:	c3                   	ret    

00018cf1 <progMN>:
**	 where x is the ID character
**		   n is the iteration count
**		   b is the w&z boolean
*/

USERMAIN( progMN ) {
   18cf1:	55                   	push   %ebp
   18cf2:	89 e5                	mov    %esp,%ebp
   18cf4:	81 ec d8 00 00 00    	sub    $0xd8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18cfa:	8b 45 0c             	mov    0xc(%ebp),%eax
   18cfd:	8b 00                	mov    (%eax),%eax
   18cff:	85 c0                	test   %eax,%eax
   18d01:	74 07                	je     18d0a <progMN+0x19>
   18d03:	8b 45 0c             	mov    0xc(%ebp),%eax
   18d06:	8b 00                	mov    (%eax),%eax
   18d08:	eb 05                	jmp    18d0f <progMN+0x1e>
   18d0a:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   18d0f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int count = 5;	// default iteration count
   18d12:	c7 45 f4 05 00 00 00 	movl   $0x5,-0xc(%ebp)
	char ch = '5';	// default character to print
   18d19:	c6 45 df 35          	movb   $0x35,-0x21(%ebp)
	int alsoZ = 0;	// also do progZ?
   18d1d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	char msgw[] = "*5w*";
   18d24:	c7 45 da 2a 35 77 2a 	movl   $0x2a77352a,-0x26(%ebp)
   18d2b:	c6 45 de 00          	movb   $0x0,-0x22(%ebp)
	char msgz[] = "*5z*";
   18d2f:	c7 45 d5 2a 35 7a 2a 	movl   $0x2a7a352a,-0x2b(%ebp)
   18d36:	c6 45 d9 00          	movb   $0x0,-0x27(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   18d3a:	8b 45 08             	mov    0x8(%ebp),%eax
   18d3d:	83 f8 03             	cmp    $0x3,%eax
   18d40:	74 22                	je     18d64 <progMN+0x73>
   18d42:	83 f8 04             	cmp    $0x4,%eax
   18d45:	74 07                	je     18d4e <progMN+0x5d>
   18d47:	83 f8 02             	cmp    $0x2,%eax
   18d4a:	74 31                	je     18d7d <progMN+0x8c>
   18d4c:	eb 42                	jmp    18d90 <progMN+0x9f>
	case 4:	alsoZ = argv[3][0] == 't';
   18d4e:	8b 45 0c             	mov    0xc(%ebp),%eax
   18d51:	83 c0 0c             	add    $0xc,%eax
   18d54:	8b 00                	mov    (%eax),%eax
   18d56:	0f b6 00             	movzbl (%eax),%eax
   18d59:	3c 74                	cmp    $0x74,%al
   18d5b:	0f 94 c0             	sete   %al
   18d5e:	0f b6 c0             	movzbl %al,%eax
   18d61:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   18d64:	8b 45 0c             	mov    0xc(%ebp),%eax
   18d67:	83 c0 08             	add    $0x8,%eax
   18d6a:	8b 00                	mov    (%eax),%eax
   18d6c:	83 ec 08             	sub    $0x8,%esp
   18d6f:	6a 0a                	push   $0xa
   18d71:	50                   	push   %eax
   18d72:	e8 c0 11 00 00       	call   19f37 <ustr2int>
   18d77:	83 c4 10             	add    $0x10,%esp
   18d7a:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18d7d:	8b 45 0c             	mov    0xc(%ebp),%eax
   18d80:	83 c0 04             	add    $0x4,%eax
   18d83:	8b 00                	mov    (%eax),%eax
   18d85:	0f b6 00             	movzbl (%eax),%eax
   18d88:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   18d8b:	e9 a8 00 00 00       	jmp    18e38 <progMN+0x147>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18d90:	ff 75 08             	pushl  0x8(%ebp)
   18d93:	ff 75 e4             	pushl  -0x1c(%ebp)
   18d96:	68 f1 bd 01 00       	push   $0x1bdf1
   18d9b:	8d 85 55 ff ff ff    	lea    -0xab(%ebp),%eax
   18da1:	50                   	push   %eax
   18da2:	e8 1b 0f 00 00       	call   19cc2 <usprint>
   18da7:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18daa:	83 ec 0c             	sub    $0xc,%esp
   18dad:	8d 85 55 ff ff ff    	lea    -0xab(%ebp),%eax
   18db3:	50                   	push   %eax
   18db4:	e8 f6 15 00 00       	call   1a3af <cwrites>
   18db9:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18dbc:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18dc3:	eb 5b                	jmp    18e20 <progMN+0x12f>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18dc5:	8b 45 08             	mov    0x8(%ebp),%eax
   18dc8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18dcf:	8b 45 0c             	mov    0xc(%ebp),%eax
   18dd2:	01 d0                	add    %edx,%eax
   18dd4:	8b 00                	mov    (%eax),%eax
   18dd6:	85 c0                	test   %eax,%eax
   18dd8:	74 13                	je     18ded <progMN+0xfc>
   18dda:	8b 45 08             	mov    0x8(%ebp),%eax
   18ddd:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18de4:	8b 45 0c             	mov    0xc(%ebp),%eax
   18de7:	01 d0                	add    %edx,%eax
   18de9:	8b 00                	mov    (%eax),%eax
   18deb:	eb 05                	jmp    18df2 <progMN+0x101>
   18ded:	b8 05 be 01 00       	mov    $0x1be05,%eax
   18df2:	83 ec 04             	sub    $0x4,%esp
   18df5:	50                   	push   %eax
   18df6:	68 0c be 01 00       	push   $0x1be0c
   18dfb:	8d 85 55 ff ff ff    	lea    -0xab(%ebp),%eax
   18e01:	50                   	push   %eax
   18e02:	e8 bb 0e 00 00       	call   19cc2 <usprint>
   18e07:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   18e0a:	83 ec 0c             	sub    $0xc,%esp
   18e0d:	8d 85 55 ff ff ff    	lea    -0xab(%ebp),%eax
   18e13:	50                   	push   %eax
   18e14:	e8 96 15 00 00       	call   1a3af <cwrites>
   18e19:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18e1c:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18e20:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18e23:	3b 45 08             	cmp    0x8(%ebp),%eax
   18e26:	7e 9d                	jle    18dc5 <progMN+0xd4>
			}
			cwrites( "\n" );
   18e28:	83 ec 0c             	sub    $0xc,%esp
   18e2b:	68 10 be 01 00       	push   $0x1be10
   18e30:	e8 7a 15 00 00       	call   1a3af <cwrites>
   18e35:	83 c4 10             	add    $0x10,%esp
	}

	// update the extra message strings
	msgw[1] = msgz[1] = ch;
   18e38:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
   18e3c:	88 45 d6             	mov    %al,-0x2a(%ebp)
   18e3f:	0f b6 45 d6          	movzbl -0x2a(%ebp),%eax
   18e43:	88 45 db             	mov    %al,-0x25(%ebp)

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   18e46:	83 ec 04             	sub    $0x4,%esp
   18e49:	6a 01                	push   $0x1
   18e4b:	8d 45 df             	lea    -0x21(%ebp),%eax
   18e4e:	50                   	push   %eax
   18e4f:	6a 01                	push   $0x1
   18e51:	e8 ea e0 ff ff       	call   16f40 <write>
   18e56:	83 c4 10             	add    $0x10,%esp

	// set up the argument vector(s)

	// W:  15 iterations, 5-second sleep
	char *argsw[] = { "progW", "W", "15", "5", NULL };
   18e59:	c7 85 40 ff ff ff d2 	movl   $0x1bed2,-0xc0(%ebp)
   18e60:	be 01 00 
   18e63:	c7 85 44 ff ff ff e6 	movl   $0x1bbe6,-0xbc(%ebp)
   18e6a:	bb 01 00 
   18e6d:	c7 85 48 ff ff ff 37 	movl   $0x1bf37,-0xb8(%ebp)
   18e74:	bf 01 00 
   18e77:	c7 85 4c ff ff ff 93 	movl   $0x1bb93,-0xb4(%ebp)
   18e7e:	bb 01 00 
   18e81:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
   18e88:	00 00 00 

	// Z:  15 iterations
	char *argsz[] = { "progZ", "Z", "15", NULL };
   18e8b:	c7 85 30 ff ff ff 89 	movl   $0x1be89,-0xd0(%ebp)
   18e92:	be 01 00 
   18e95:	c7 85 34 ff ff ff 8f 	movl   $0x1be8f,-0xcc(%ebp)
   18e9c:	be 01 00 
   18e9f:	c7 85 38 ff ff ff 37 	movl   $0x1bf37,-0xc8(%ebp)
   18ea6:	bf 01 00 
   18ea9:	c7 85 3c ff ff ff 00 	movl   $0x0,-0xc4(%ebp)
   18eb0:	00 00 00 

	for( int i = 0; i < count; ++i ) {
   18eb3:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18eba:	eb 7d                	jmp    18f39 <progMN+0x248>
		write( CHAN_SIO, &ch, 1 );
   18ebc:	83 ec 04             	sub    $0x4,%esp
   18ebf:	6a 01                	push   $0x1
   18ec1:	8d 45 df             	lea    -0x21(%ebp),%eax
   18ec4:	50                   	push   %eax
   18ec5:	6a 01                	push   $0x1
   18ec7:	e8 74 e0 ff ff       	call   16f40 <write>
   18ecc:	83 c4 10             	add    $0x10,%esp
		int whom = spawn( (uint32_t) progW, argsw	);
   18ecf:	ba 04 84 01 00       	mov    $0x18404,%edx
   18ed4:	83 ec 08             	sub    $0x8,%esp
   18ed7:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
   18edd:	50                   	push   %eax
   18ede:	52                   	push   %edx
   18edf:	e8 35 14 00 00       	call   1a319 <spawn>
   18ee4:	83 c4 10             	add    $0x10,%esp
   18ee7:	89 45 e0             	mov    %eax,-0x20(%ebp)
		if( whom < 1 ) {
   18eea:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   18eee:	7f 0f                	jg     18eff <progMN+0x20e>
			swrites( msgw );
   18ef0:	83 ec 0c             	sub    $0xc,%esp
   18ef3:	8d 45 da             	lea    -0x26(%ebp),%eax
   18ef6:	50                   	push   %eax
   18ef7:	e8 19 15 00 00       	call   1a415 <swrites>
   18efc:	83 c4 10             	add    $0x10,%esp
		}
		if( alsoZ ) {
   18eff:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   18f03:	74 30                	je     18f35 <progMN+0x244>
			whom = spawn( (uint32_t) progZ, argsz );
   18f05:	ba ca 7e 01 00       	mov    $0x17eca,%edx
   18f0a:	83 ec 08             	sub    $0x8,%esp
   18f0d:	8d 85 30 ff ff ff    	lea    -0xd0(%ebp),%eax
   18f13:	50                   	push   %eax
   18f14:	52                   	push   %edx
   18f15:	e8 ff 13 00 00       	call   1a319 <spawn>
   18f1a:	83 c4 10             	add    $0x10,%esp
   18f1d:	89 45 e0             	mov    %eax,-0x20(%ebp)
			if( whom < 1 ) {
   18f20:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   18f24:	7f 0f                	jg     18f35 <progMN+0x244>
				swrites( msgz );
   18f26:	83 ec 0c             	sub    $0xc,%esp
   18f29:	8d 45 d5             	lea    -0x2b(%ebp),%eax
   18f2c:	50                   	push   %eax
   18f2d:	e8 e3 14 00 00       	call   1a415 <swrites>
   18f32:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   18f35:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18f39:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18f3c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18f3f:	0f 8c 77 ff ff ff    	jl     18ebc <progMN+0x1cb>
			}
		}
	}

	exit( 0 );
   18f45:	83 ec 0c             	sub    $0xc,%esp
   18f48:	6a 00                	push   $0x0
   18f4a:	e8 c9 df ff ff       	call   16f18 <exit>
   18f4f:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18f52:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   18f57:	c9                   	leave  
   18f58:	c3                   	ret    

00018f59 <progP>:
**	 where x is the ID character
**		   n is the iteration count (defaults to 3)
**		   t is the sleep time (defaults to 2 seconds)
*/

USERMAIN( progP ) {
   18f59:	55                   	push   %ebp
   18f5a:	89 e5                	mov    %esp,%ebp
   18f5c:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18f62:	8b 45 0c             	mov    0xc(%ebp),%eax
   18f65:	8b 00                	mov    (%eax),%eax
   18f67:	85 c0                	test   %eax,%eax
   18f69:	74 07                	je     18f72 <progP+0x19>
   18f6b:	8b 45 0c             	mov    0xc(%ebp),%eax
   18f6e:	8b 00                	mov    (%eax),%eax
   18f70:	eb 05                	jmp    18f77 <progP+0x1e>
   18f72:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   18f77:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int count = 3;	  // default iteration count
   18f7a:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
	char ch = 'p';	  // default character to print
   18f81:	c6 45 df 70          	movb   $0x70,-0x21(%ebp)
	int nap = 2;	  // nap time
   18f85:	c7 45 f0 02 00 00 00 	movl   $0x2,-0x10(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   18f8c:	8b 45 08             	mov    0x8(%ebp),%eax
   18f8f:	83 f8 03             	cmp    $0x3,%eax
   18f92:	74 25                	je     18fb9 <progP+0x60>
   18f94:	83 f8 04             	cmp    $0x4,%eax
   18f97:	74 07                	je     18fa0 <progP+0x47>
   18f99:	83 f8 02             	cmp    $0x2,%eax
   18f9c:	74 34                	je     18fd2 <progP+0x79>
   18f9e:	eb 45                	jmp    18fe5 <progP+0x8c>
	case 4:	nap = ustr2int( argv[3], 10 );
   18fa0:	8b 45 0c             	mov    0xc(%ebp),%eax
   18fa3:	83 c0 0c             	add    $0xc,%eax
   18fa6:	8b 00                	mov    (%eax),%eax
   18fa8:	83 ec 08             	sub    $0x8,%esp
   18fab:	6a 0a                	push   $0xa
   18fad:	50                   	push   %eax
   18fae:	e8 84 0f 00 00       	call   19f37 <ustr2int>
   18fb3:	83 c4 10             	add    $0x10,%esp
   18fb6:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   18fb9:	8b 45 0c             	mov    0xc(%ebp),%eax
   18fbc:	83 c0 08             	add    $0x8,%eax
   18fbf:	8b 00                	mov    (%eax),%eax
   18fc1:	83 ec 08             	sub    $0x8,%esp
   18fc4:	6a 0a                	push   $0xa
   18fc6:	50                   	push   %eax
   18fc7:	e8 6b 0f 00 00       	call   19f37 <ustr2int>
   18fcc:	83 c4 10             	add    $0x10,%esp
   18fcf:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18fd2:	8b 45 0c             	mov    0xc(%ebp),%eax
   18fd5:	83 c0 04             	add    $0x4,%eax
   18fd8:	8b 00                	mov    (%eax),%eax
   18fda:	0f b6 00             	movzbl (%eax),%eax
   18fdd:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   18fe0:	e9 a8 00 00 00       	jmp    1908d <progP+0x134>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18fe5:	ff 75 08             	pushl  0x8(%ebp)
   18fe8:	ff 75 e4             	pushl  -0x1c(%ebp)
   18feb:	68 f1 bd 01 00       	push   $0x1bdf1
   18ff0:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   18ff6:	50                   	push   %eax
   18ff7:	e8 c6 0c 00 00       	call   19cc2 <usprint>
   18ffc:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18fff:	83 ec 0c             	sub    $0xc,%esp
   19002:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   19008:	50                   	push   %eax
   19009:	e8 a1 13 00 00       	call   1a3af <cwrites>
   1900e:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   19011:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   19018:	eb 5b                	jmp    19075 <progP+0x11c>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   1901a:	8b 45 08             	mov    0x8(%ebp),%eax
   1901d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19024:	8b 45 0c             	mov    0xc(%ebp),%eax
   19027:	01 d0                	add    %edx,%eax
   19029:	8b 00                	mov    (%eax),%eax
   1902b:	85 c0                	test   %eax,%eax
   1902d:	74 13                	je     19042 <progP+0xe9>
   1902f:	8b 45 08             	mov    0x8(%ebp),%eax
   19032:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19039:	8b 45 0c             	mov    0xc(%ebp),%eax
   1903c:	01 d0                	add    %edx,%eax
   1903e:	8b 00                	mov    (%eax),%eax
   19040:	eb 05                	jmp    19047 <progP+0xee>
   19042:	b8 05 be 01 00       	mov    $0x1be05,%eax
   19047:	83 ec 04             	sub    $0x4,%esp
   1904a:	50                   	push   %eax
   1904b:	68 0c be 01 00       	push   $0x1be0c
   19050:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   19056:	50                   	push   %eax
   19057:	e8 66 0c 00 00       	call   19cc2 <usprint>
   1905c:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1905f:	83 ec 0c             	sub    $0xc,%esp
   19062:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   19068:	50                   	push   %eax
   19069:	e8 41 13 00 00       	call   1a3af <cwrites>
   1906e:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   19071:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   19075:	8b 45 ec             	mov    -0x14(%ebp),%eax
   19078:	3b 45 08             	cmp    0x8(%ebp),%eax
   1907b:	7e 9d                	jle    1901a <progP+0xc1>
			}
			cwrites( "\n" );
   1907d:	83 ec 0c             	sub    $0xc,%esp
   19080:	68 10 be 01 00       	push   $0x1be10
   19085:	e8 25 13 00 00       	call   1a3af <cwrites>
   1908a:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	uint32_t now = gettime();
   1908d:	e8 c6 de ff ff       	call   16f58 <gettime>
   19092:	89 45 e0             	mov    %eax,-0x20(%ebp)
	usprint( buf, " P@%u", now );
   19095:	83 ec 04             	sub    $0x4,%esp
   19098:	ff 75 e0             	pushl  -0x20(%ebp)
   1909b:	68 3a bf 01 00       	push   $0x1bf3a
   190a0:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   190a6:	50                   	push   %eax
   190a7:	e8 16 0c 00 00       	call   19cc2 <usprint>
   190ac:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   190af:	83 ec 0c             	sub    $0xc,%esp
   190b2:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   190b8:	50                   	push   %eax
   190b9:	e8 57 13 00 00       	call   1a415 <swrites>
   190be:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count; ++i ) {
   190c1:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   190c8:	eb 2c                	jmp    190f6 <progP+0x19d>
		sleep( SEC_TO_MS(nap) );
   190ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
   190cd:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   190d3:	83 ec 0c             	sub    $0xc,%esp
   190d6:	50                   	push   %eax
   190d7:	e8 9c de ff ff       	call   16f78 <sleep>
   190dc:	83 c4 10             	add    $0x10,%esp
		write( CHAN_SIO, &ch, 1 );
   190df:	83 ec 04             	sub    $0x4,%esp
   190e2:	6a 01                	push   $0x1
   190e4:	8d 45 df             	lea    -0x21(%ebp),%eax
   190e7:	50                   	push   %eax
   190e8:	6a 01                	push   $0x1
   190ea:	e8 51 de ff ff       	call   16f40 <write>
   190ef:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   190f2:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   190f6:	8b 45 e8             	mov    -0x18(%ebp),%eax
   190f9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   190fc:	7c cc                	jl     190ca <progP+0x171>
	}

	exit( 0 );
   190fe:	83 ec 0c             	sub    $0xc,%esp
   19101:	6a 00                	push   $0x0
   19103:	e8 10 de ff ff       	call   16f18 <exit>
   19108:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   1910b:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   19110:	c9                   	leave  
   19111:	c3                   	ret    

00019112 <progQ>:
**
** Invoked as:  progQ  x
**	 where x is the ID character
*/

USERMAIN( progQ ) {
   19112:	55                   	push   %ebp
   19113:	89 e5                	mov    %esp,%ebp
   19115:	81 ec 98 00 00 00    	sub    $0x98,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   1911b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1911e:	8b 00                	mov    (%eax),%eax
   19120:	85 c0                	test   %eax,%eax
   19122:	74 07                	je     1912b <progQ+0x19>
   19124:	8b 45 0c             	mov    0xc(%ebp),%eax
   19127:	8b 00                	mov    (%eax),%eax
   19129:	eb 05                	jmp    19130 <progQ+0x1e>
   1912b:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   19130:	89 45 f0             	mov    %eax,-0x10(%ebp)
	char ch = 'q';	  // default character to print
   19133:	c6 45 ef 71          	movb   $0x71,-0x11(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   19137:	8b 45 08             	mov    0x8(%ebp),%eax
   1913a:	83 f8 02             	cmp    $0x2,%eax
   1913d:	75 13                	jne    19152 <progQ+0x40>
	case 2:	ch = argv[1][0];
   1913f:	8b 45 0c             	mov    0xc(%ebp),%eax
   19142:	83 c0 04             	add    $0x4,%eax
   19145:	8b 00                	mov    (%eax),%eax
   19147:	0f b6 00             	movzbl (%eax),%eax
   1914a:	88 45 ef             	mov    %al,-0x11(%ebp)
			break;
   1914d:	e9 a8 00 00 00       	jmp    191fa <progQ+0xe8>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   19152:	ff 75 08             	pushl  0x8(%ebp)
   19155:	ff 75 f0             	pushl  -0x10(%ebp)
   19158:	68 f1 bd 01 00       	push   $0x1bdf1
   1915d:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   19163:	50                   	push   %eax
   19164:	e8 59 0b 00 00       	call   19cc2 <usprint>
   19169:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1916c:	83 ec 0c             	sub    $0xc,%esp
   1916f:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   19175:	50                   	push   %eax
   19176:	e8 34 12 00 00       	call   1a3af <cwrites>
   1917b:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1917e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   19185:	eb 5b                	jmp    191e2 <progQ+0xd0>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   19187:	8b 45 08             	mov    0x8(%ebp),%eax
   1918a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19191:	8b 45 0c             	mov    0xc(%ebp),%eax
   19194:	01 d0                	add    %edx,%eax
   19196:	8b 00                	mov    (%eax),%eax
   19198:	85 c0                	test   %eax,%eax
   1919a:	74 13                	je     191af <progQ+0x9d>
   1919c:	8b 45 08             	mov    0x8(%ebp),%eax
   1919f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   191a6:	8b 45 0c             	mov    0xc(%ebp),%eax
   191a9:	01 d0                	add    %edx,%eax
   191ab:	8b 00                	mov    (%eax),%eax
   191ad:	eb 05                	jmp    191b4 <progQ+0xa2>
   191af:	b8 05 be 01 00       	mov    $0x1be05,%eax
   191b4:	83 ec 04             	sub    $0x4,%esp
   191b7:	50                   	push   %eax
   191b8:	68 0c be 01 00       	push   $0x1be0c
   191bd:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   191c3:	50                   	push   %eax
   191c4:	e8 f9 0a 00 00       	call   19cc2 <usprint>
   191c9:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   191cc:	83 ec 0c             	sub    $0xc,%esp
   191cf:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   191d5:	50                   	push   %eax
   191d6:	e8 d4 11 00 00       	call   1a3af <cwrites>
   191db:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   191de:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   191e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
   191e5:	3b 45 08             	cmp    0x8(%ebp),%eax
   191e8:	7e 9d                	jle    19187 <progQ+0x75>
			}
			cwrites( "\n" );
   191ea:	83 ec 0c             	sub    $0xc,%esp
   191ed:	68 10 be 01 00       	push   $0x1be10
   191f2:	e8 b8 11 00 00       	call   1a3af <cwrites>
   191f7:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   191fa:	83 ec 04             	sub    $0x4,%esp
   191fd:	6a 01                	push   $0x1
   191ff:	8d 45 ef             	lea    -0x11(%ebp),%eax
   19202:	50                   	push   %eax
   19203:	6a 01                	push   $0x1
   19205:	e8 36 dd ff ff       	call   16f40 <write>
   1920a:	83 c4 10             	add    $0x10,%esp

	// try something weird
	bogus();
   1920d:	e8 6e dd ff ff       	call   16f80 <bogus>

	// should not have come back here!
	usprint( buf, "!!!!! %c returned from bogus syscall!?!?!\n", ch );
   19212:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
   19216:	0f be c0             	movsbl %al,%eax
   19219:	83 ec 04             	sub    $0x4,%esp
   1921c:	50                   	push   %eax
   1921d:	68 40 bf 01 00       	push   $0x1bf40
   19222:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   19228:	50                   	push   %eax
   19229:	e8 94 0a 00 00       	call   19cc2 <usprint>
   1922e:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   19231:	83 ec 0c             	sub    $0xc,%esp
   19234:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   1923a:	50                   	push   %eax
   1923b:	e8 6f 11 00 00       	call   1a3af <cwrites>
   19240:	83 c4 10             	add    $0x10,%esp

	exit( 1 );
   19243:	83 ec 0c             	sub    $0xc,%esp
   19246:	6a 01                	push   $0x1
   19248:	e8 cb dc ff ff       	call   16f18 <exit>
   1924d:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   19250:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   19255:	c9                   	leave  
   19256:	c3                   	ret    

00019257 <progR>:
**	 where x is the ID character
**		   n is the sequence number of the initial incarnation
**		   s is the initial delay time (defaults to 10)
*/

USERMAIN( progR ) {
   19257:	55                   	push   %ebp
   19258:	89 e5                	mov    %esp,%ebp
   1925a:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   19260:	8b 45 0c             	mov    0xc(%ebp),%eax
   19263:	8b 00                	mov    (%eax),%eax
   19265:	85 c0                	test   %eax,%eax
   19267:	74 07                	je     19270 <progR+0x19>
   19269:	8b 45 0c             	mov    0xc(%ebp),%eax
   1926c:	8b 00                	mov    (%eax),%eax
   1926e:	eb 05                	jmp    19275 <progR+0x1e>
   19270:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   19275:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	char ch = 'r';	// default character to print
   19278:	c6 45 f7 72          	movb   $0x72,-0x9(%ebp)
	int delay = 10;	// initial delay count
   1927c:	c7 45 f0 0a 00 00 00 	movl   $0xa,-0x10(%ebp)
	int seq = 99;	// my sequence number
   19283:	c7 45 ec 63 00 00 00 	movl   $0x63,-0x14(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   1928a:	8b 45 08             	mov    0x8(%ebp),%eax
   1928d:	83 f8 03             	cmp    $0x3,%eax
   19290:	74 25                	je     192b7 <progR+0x60>
   19292:	83 f8 04             	cmp    $0x4,%eax
   19295:	74 07                	je     1929e <progR+0x47>
   19297:	83 f8 02             	cmp    $0x2,%eax
   1929a:	74 34                	je     192d0 <progR+0x79>
   1929c:	eb 45                	jmp    192e3 <progR+0x8c>
	case 4:	delay = ustr2int( argv[3], 10 );
   1929e:	8b 45 0c             	mov    0xc(%ebp),%eax
   192a1:	83 c0 0c             	add    $0xc,%eax
   192a4:	8b 00                	mov    (%eax),%eax
   192a6:	83 ec 08             	sub    $0x8,%esp
   192a9:	6a 0a                	push   $0xa
   192ab:	50                   	push   %eax
   192ac:	e8 86 0c 00 00       	call   19f37 <ustr2int>
   192b1:	83 c4 10             	add    $0x10,%esp
   192b4:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	seq = ustr2int( argv[2], 10 );
   192b7:	8b 45 0c             	mov    0xc(%ebp),%eax
   192ba:	83 c0 08             	add    $0x8,%eax
   192bd:	8b 00                	mov    (%eax),%eax
   192bf:	83 ec 08             	sub    $0x8,%esp
   192c2:	6a 0a                	push   $0xa
   192c4:	50                   	push   %eax
   192c5:	e8 6d 0c 00 00       	call   19f37 <ustr2int>
   192ca:	83 c4 10             	add    $0x10,%esp
   192cd:	89 45 ec             	mov    %eax,-0x14(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   192d0:	8b 45 0c             	mov    0xc(%ebp),%eax
   192d3:	83 c0 04             	add    $0x4,%eax
   192d6:	8b 00                	mov    (%eax),%eax
   192d8:	0f b6 00             	movzbl (%eax),%eax
   192db:	88 45 f7             	mov    %al,-0x9(%ebp)
			break;
   192de:	e9 a8 00 00 00       	jmp    1938b <progR+0x134>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   192e3:	ff 75 08             	pushl  0x8(%ebp)
   192e6:	ff 75 e4             	pushl  -0x1c(%ebp)
   192e9:	68 f1 bd 01 00       	push   $0x1bdf1
   192ee:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   192f4:	50                   	push   %eax
   192f5:	e8 c8 09 00 00       	call   19cc2 <usprint>
   192fa:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   192fd:	83 ec 0c             	sub    $0xc,%esp
   19300:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19306:	50                   	push   %eax
   19307:	e8 a3 10 00 00       	call   1a3af <cwrites>
   1930c:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1930f:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   19316:	eb 5b                	jmp    19373 <progR+0x11c>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   19318:	8b 45 08             	mov    0x8(%ebp),%eax
   1931b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19322:	8b 45 0c             	mov    0xc(%ebp),%eax
   19325:	01 d0                	add    %edx,%eax
   19327:	8b 00                	mov    (%eax),%eax
   19329:	85 c0                	test   %eax,%eax
   1932b:	74 13                	je     19340 <progR+0xe9>
   1932d:	8b 45 08             	mov    0x8(%ebp),%eax
   19330:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19337:	8b 45 0c             	mov    0xc(%ebp),%eax
   1933a:	01 d0                	add    %edx,%eax
   1933c:	8b 00                	mov    (%eax),%eax
   1933e:	eb 05                	jmp    19345 <progR+0xee>
   19340:	b8 05 be 01 00       	mov    $0x1be05,%eax
   19345:	83 ec 04             	sub    $0x4,%esp
   19348:	50                   	push   %eax
   19349:	68 0c be 01 00       	push   $0x1be0c
   1934e:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19354:	50                   	push   %eax
   19355:	e8 68 09 00 00       	call   19cc2 <usprint>
   1935a:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1935d:	83 ec 0c             	sub    $0xc,%esp
   19360:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19366:	50                   	push   %eax
   19367:	e8 43 10 00 00       	call   1a3af <cwrites>
   1936c:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1936f:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   19373:	8b 45 e8             	mov    -0x18(%ebp),%eax
   19376:	3b 45 08             	cmp    0x8(%ebp),%eax
   19379:	7e 9d                	jle    19318 <progR+0xc1>
			}
			cwrites( "\n" );
   1937b:	83 ec 0c             	sub    $0xc,%esp
   1937e:	68 10 be 01 00       	push   $0x1be10
   19383:	e8 27 10 00 00       	call   1a3af <cwrites>
   19388:	83 c4 10             	add    $0x10,%esp
	int32_t ppid;

 restart:

	// announce our presence
	pid = getpid();
   1938b:	e8 b8 db ff ff       	call   16f48 <getpid>
   19390:	89 45 e0             	mov    %eax,-0x20(%ebp)
	ppid = getppid();
   19393:	e8 b8 db ff ff       	call   16f50 <getppid>
   19398:	89 45 dc             	mov    %eax,-0x24(%ebp)

	usprint( buf, " %c[%d,%d,%d]", ch, seq, pid, ppid );
   1939b:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
   1939f:	83 ec 08             	sub    $0x8,%esp
   193a2:	ff 75 dc             	pushl  -0x24(%ebp)
   193a5:	ff 75 e0             	pushl  -0x20(%ebp)
   193a8:	ff 75 ec             	pushl  -0x14(%ebp)
   193ab:	50                   	push   %eax
   193ac:	68 6b bf 01 00       	push   $0x1bf6b
   193b1:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   193b7:	50                   	push   %eax
   193b8:	e8 05 09 00 00       	call   19cc2 <usprint>
   193bd:	83 c4 20             	add    $0x20,%esp
	swrites( buf );
   193c0:	83 ec 0c             	sub    $0xc,%esp
   193c3:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   193c9:	50                   	push   %eax
   193ca:	e8 46 10 00 00       	call   1a415 <swrites>
   193cf:	83 c4 10             	add    $0x10,%esp

	sleep( SEC_TO_MS(delay) );
   193d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
   193d5:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   193db:	83 ec 0c             	sub    $0xc,%esp
   193de:	50                   	push   %eax
   193df:	e8 94 db ff ff       	call   16f78 <sleep>
   193e4:	83 c4 10             	add    $0x10,%esp

	// create the next child in sequence
	if( seq < 5 ) {
   193e7:	83 7d ec 04          	cmpl   $0x4,-0x14(%ebp)
   193eb:	7f 63                	jg     19450 <progR+0x1f9>
		++seq;
   193ed:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
		int32_t n = fork();
   193f1:	e8 32 db ff ff       	call   16f28 <fork>
   193f6:	89 45 d8             	mov    %eax,-0x28(%ebp)
		switch( n ) {
   193f9:	8b 45 d8             	mov    -0x28(%ebp),%eax
   193fc:	83 f8 ff             	cmp    $0xffffffff,%eax
   193ff:	74 06                	je     19407 <progR+0x1b0>
   19401:	85 c0                	test   %eax,%eax
   19403:	74 86                	je     1938b <progR+0x134>
   19405:	eb 2e                	jmp    19435 <progR+0x1de>
		case -1:
			// failure?
			usprint( buf, "** R[%d] fork code %d\n", pid, n );
   19407:	ff 75 d8             	pushl  -0x28(%ebp)
   1940a:	ff 75 e0             	pushl  -0x20(%ebp)
   1940d:	68 79 bf 01 00       	push   $0x1bf79
   19412:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19418:	50                   	push   %eax
   19419:	e8 a4 08 00 00       	call   19cc2 <usprint>
   1941e:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   19421:	83 ec 0c             	sub    $0xc,%esp
   19424:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   1942a:	50                   	push   %eax
   1942b:	e8 7f 0f 00 00       	call   1a3af <cwrites>
   19430:	83 c4 10             	add    $0x10,%esp
			break;
   19433:	eb 1c                	jmp    19451 <progR+0x1fa>
		case 0:
			// child
			goto restart;
		default:
			// parent
			--seq;
   19435:	83 6d ec 01          	subl   $0x1,-0x14(%ebp)
			sleep( SEC_TO_MS(delay) );
   19439:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1943c:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   19442:	83 ec 0c             	sub    $0xc,%esp
   19445:	50                   	push   %eax
   19446:	e8 2d db ff ff       	call   16f78 <sleep>
   1944b:	83 c4 10             	add    $0x10,%esp
   1944e:	eb 01                	jmp    19451 <progR+0x1fa>
		}
	}
   19450:	90                   	nop

	// final report - PPID may change, but PID and seq shouldn't
	pid = getpid();
   19451:	e8 f2 da ff ff       	call   16f48 <getpid>
   19456:	89 45 e0             	mov    %eax,-0x20(%ebp)
	ppid = getppid();
   19459:	e8 f2 da ff ff       	call   16f50 <getppid>
   1945e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d,%d,%d]", ch, seq, pid, ppid );
   19461:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
   19465:	83 ec 08             	sub    $0x8,%esp
   19468:	ff 75 dc             	pushl  -0x24(%ebp)
   1946b:	ff 75 e0             	pushl  -0x20(%ebp)
   1946e:	ff 75 ec             	pushl  -0x14(%ebp)
   19471:	50                   	push   %eax
   19472:	68 6b bf 01 00       	push   $0x1bf6b
   19477:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   1947d:	50                   	push   %eax
   1947e:	e8 3f 08 00 00       	call   19cc2 <usprint>
   19483:	83 c4 20             	add    $0x20,%esp
	swrites( buf );
   19486:	83 ec 0c             	sub    $0xc,%esp
   19489:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   1948f:	50                   	push   %eax
   19490:	e8 80 0f 00 00       	call   1a415 <swrites>
   19495:	83 c4 10             	add    $0x10,%esp

	exit( 0 );
   19498:	83 ec 0c             	sub    $0xc,%esp
   1949b:	6a 00                	push   $0x0
   1949d:	e8 76 da ff ff       	call   16f18 <exit>
   194a2:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   194a5:	b8 2a 00 00 00       	mov    $0x2a,%eax

}
   194aa:	c9                   	leave  
   194ab:	c3                   	ret    

000194ac <progS>:
** Invoked as:  progS  x  [ s ]
**	 where x is the ID character
**		   s is the sleep time (defaults to 20)
*/

USERMAIN( progS ) {
   194ac:	55                   	push   %ebp
   194ad:	89 e5                	mov    %esp,%ebp
   194af:	81 ec 98 00 00 00    	sub    $0x98,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   194b5:	8b 45 0c             	mov    0xc(%ebp),%eax
   194b8:	8b 00                	mov    (%eax),%eax
   194ba:	85 c0                	test   %eax,%eax
   194bc:	74 07                	je     194c5 <progS+0x19>
   194be:	8b 45 0c             	mov    0xc(%ebp),%eax
   194c1:	8b 00                	mov    (%eax),%eax
   194c3:	eb 05                	jmp    194ca <progS+0x1e>
   194c5:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   194ca:	89 45 ec             	mov    %eax,-0x14(%ebp)
	char ch = 's';	  // default character to print
   194cd:	c6 45 eb 73          	movb   $0x73,-0x15(%ebp)
	int nap = 20;	  // nap time
   194d1:	c7 45 f4 14 00 00 00 	movl   $0x14,-0xc(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   194d8:	8b 45 08             	mov    0x8(%ebp),%eax
   194db:	83 f8 02             	cmp    $0x2,%eax
   194de:	74 1e                	je     194fe <progS+0x52>
   194e0:	83 f8 03             	cmp    $0x3,%eax
   194e3:	75 2c                	jne    19511 <progS+0x65>
	case 3:	nap = ustr2int( argv[2], 10 );
   194e5:	8b 45 0c             	mov    0xc(%ebp),%eax
   194e8:	83 c0 08             	add    $0x8,%eax
   194eb:	8b 00                	mov    (%eax),%eax
   194ed:	83 ec 08             	sub    $0x8,%esp
   194f0:	6a 0a                	push   $0xa
   194f2:	50                   	push   %eax
   194f3:	e8 3f 0a 00 00       	call   19f37 <ustr2int>
   194f8:	83 c4 10             	add    $0x10,%esp
   194fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   194fe:	8b 45 0c             	mov    0xc(%ebp),%eax
   19501:	83 c0 04             	add    $0x4,%eax
   19504:	8b 00                	mov    (%eax),%eax
   19506:	0f b6 00             	movzbl (%eax),%eax
   19509:	88 45 eb             	mov    %al,-0x15(%ebp)
			break;
   1950c:	e9 a8 00 00 00       	jmp    195b9 <progS+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   19511:	ff 75 08             	pushl  0x8(%ebp)
   19514:	ff 75 ec             	pushl  -0x14(%ebp)
   19517:	68 f1 bd 01 00       	push   $0x1bdf1
   1951c:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   19522:	50                   	push   %eax
   19523:	e8 9a 07 00 00       	call   19cc2 <usprint>
   19528:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1952b:	83 ec 0c             	sub    $0xc,%esp
   1952e:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   19534:	50                   	push   %eax
   19535:	e8 75 0e 00 00       	call   1a3af <cwrites>
   1953a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1953d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   19544:	eb 5b                	jmp    195a1 <progS+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   19546:	8b 45 08             	mov    0x8(%ebp),%eax
   19549:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19550:	8b 45 0c             	mov    0xc(%ebp),%eax
   19553:	01 d0                	add    %edx,%eax
   19555:	8b 00                	mov    (%eax),%eax
   19557:	85 c0                	test   %eax,%eax
   19559:	74 13                	je     1956e <progS+0xc2>
   1955b:	8b 45 08             	mov    0x8(%ebp),%eax
   1955e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19565:	8b 45 0c             	mov    0xc(%ebp),%eax
   19568:	01 d0                	add    %edx,%eax
   1956a:	8b 00                	mov    (%eax),%eax
   1956c:	eb 05                	jmp    19573 <progS+0xc7>
   1956e:	b8 05 be 01 00       	mov    $0x1be05,%eax
   19573:	83 ec 04             	sub    $0x4,%esp
   19576:	50                   	push   %eax
   19577:	68 0c be 01 00       	push   $0x1be0c
   1957c:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   19582:	50                   	push   %eax
   19583:	e8 3a 07 00 00       	call   19cc2 <usprint>
   19588:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1958b:	83 ec 0c             	sub    $0xc,%esp
   1958e:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   19594:	50                   	push   %eax
   19595:	e8 15 0e 00 00       	call   1a3af <cwrites>
   1959a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1959d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   195a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
   195a4:	3b 45 08             	cmp    0x8(%ebp),%eax
   195a7:	7e 9d                	jle    19546 <progS+0x9a>
			}
			cwrites( "\n" );
   195a9:	83 ec 0c             	sub    $0xc,%esp
   195ac:	68 10 be 01 00       	push   $0x1be10
   195b1:	e8 f9 0d 00 00       	call   1a3af <cwrites>
   195b6:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   195b9:	83 ec 04             	sub    $0x4,%esp
   195bc:	6a 01                	push   $0x1
   195be:	8d 45 eb             	lea    -0x15(%ebp),%eax
   195c1:	50                   	push   %eax
   195c2:	6a 01                	push   $0x1
   195c4:	e8 77 d9 ff ff       	call   16f40 <write>
   195c9:	83 c4 10             	add    $0x10,%esp

	usprint( buf, "%s sleeping %d(%d)\n", name, nap, SEC_TO_MS(nap) );
   195cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
   195cf:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   195d5:	83 ec 0c             	sub    $0xc,%esp
   195d8:	50                   	push   %eax
   195d9:	ff 75 f4             	pushl  -0xc(%ebp)
   195dc:	ff 75 ec             	pushl  -0x14(%ebp)
   195df:	68 90 bf 01 00       	push   $0x1bf90
   195e4:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   195ea:	50                   	push   %eax
   195eb:	e8 d2 06 00 00       	call   19cc2 <usprint>
   195f0:	83 c4 20             	add    $0x20,%esp
	cwrites( buf );
   195f3:	83 ec 0c             	sub    $0xc,%esp
   195f6:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   195fc:	50                   	push   %eax
   195fd:	e8 ad 0d 00 00       	call   1a3af <cwrites>
   19602:	83 c4 10             	add    $0x10,%esp

	for(;;) {
		sleep( SEC_TO_MS(nap) );
   19605:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19608:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   1960e:	83 ec 0c             	sub    $0xc,%esp
   19611:	50                   	push   %eax
   19612:	e8 61 d9 ff ff       	call   16f78 <sleep>
   19617:	83 c4 10             	add    $0x10,%esp
		write( CHAN_SIO, &ch, 1 );
   1961a:	83 ec 04             	sub    $0x4,%esp
   1961d:	6a 01                	push   $0x1
   1961f:	8d 45 eb             	lea    -0x15(%ebp),%eax
   19622:	50                   	push   %eax
   19623:	6a 01                	push   $0x1
   19625:	e8 16 d9 ff ff       	call   16f40 <write>
   1962a:	83 c4 10             	add    $0x10,%esp
		sleep( SEC_TO_MS(nap) );
   1962d:	eb d6                	jmp    19605 <progS+0x159>

0001962f <progTUV>:

#ifndef MAX_CHILDREN
#define MAX_CHILDREN	50
#endif

USERMAIN( progTUV ) {
   1962f:	55                   	push   %ebp
   19630:	89 e5                	mov    %esp,%ebp
   19632:	81 ec a8 01 00 00    	sub    $0x1a8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   19638:	8b 45 0c             	mov    0xc(%ebp),%eax
   1963b:	8b 00                	mov    (%eax),%eax
   1963d:	85 c0                	test   %eax,%eax
   1963f:	74 07                	je     19648 <progTUV+0x19>
   19641:	8b 45 0c             	mov    0xc(%ebp),%eax
   19644:	8b 00                	mov    (%eax),%eax
   19646:	eb 05                	jmp    1964d <progTUV+0x1e>
   19648:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   1964d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	int count = 3;			// default child count
   19650:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
	char ch = '6';			// default character to print
   19657:	c6 45 c7 36          	movb   $0x36,-0x39(%ebp)
	int nap = 8;			// nap time
   1965b:	c7 45 cc 08 00 00 00 	movl   $0x8,-0x34(%ebp)
	bool_t waiting = true;	// default is waiting by PID
   19662:	c6 45 f3 01          	movb   $0x1,-0xd(%ebp)
	bool_t bypid = true;
   19666:	c6 45 f2 01          	movb   $0x1,-0xe(%ebp)
	char buf[128];
	uint_t children[MAX_CHILDREN];
	int nkids = 0;
   1966a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	char ch2[] = "*?*";
   19671:	c7 85 78 fe ff ff 2a 	movl   $0x2a3f2a,-0x188(%ebp)
   19678:	3f 2a 00 

	// process the command-line arguments
	switch( argc ) {
   1967b:	8b 45 08             	mov    0x8(%ebp),%eax
   1967e:	83 f8 03             	cmp    $0x3,%eax
   19681:	74 32                	je     196b5 <progTUV+0x86>
   19683:	83 f8 04             	cmp    $0x4,%eax
   19686:	74 07                	je     1968f <progTUV+0x60>
   19688:	83 f8 02             	cmp    $0x2,%eax
   1968b:	74 41                	je     196ce <progTUV+0x9f>
   1968d:	eb 52                	jmp    196e1 <progTUV+0xb2>
	case 4:	waiting = argv[3][0] != 'k';	// 'w'/'W' -> wait, else -> kill
   1968f:	8b 45 0c             	mov    0xc(%ebp),%eax
   19692:	83 c0 0c             	add    $0xc,%eax
   19695:	8b 00                	mov    (%eax),%eax
   19697:	0f b6 00             	movzbl (%eax),%eax
   1969a:	3c 6b                	cmp    $0x6b,%al
   1969c:	0f 95 c0             	setne  %al
   1969f:	88 45 f3             	mov    %al,-0xd(%ebp)
			bypid   = argv[3][0] != 'w';	// 'W'/'k' -> by PID
   196a2:	8b 45 0c             	mov    0xc(%ebp),%eax
   196a5:	83 c0 0c             	add    $0xc,%eax
   196a8:	8b 00                	mov    (%eax),%eax
   196aa:	0f b6 00             	movzbl (%eax),%eax
   196ad:	3c 77                	cmp    $0x77,%al
   196af:	0f 95 c0             	setne  %al
   196b2:	88 45 f2             	mov    %al,-0xe(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   196b5:	8b 45 0c             	mov    0xc(%ebp),%eax
   196b8:	83 c0 08             	add    $0x8,%eax
   196bb:	8b 00                	mov    (%eax),%eax
   196bd:	83 ec 08             	sub    $0x8,%esp
   196c0:	6a 0a                	push   $0xa
   196c2:	50                   	push   %eax
   196c3:	e8 6f 08 00 00       	call   19f37 <ustr2int>
   196c8:	83 c4 10             	add    $0x10,%esp
   196cb:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   196ce:	8b 45 0c             	mov    0xc(%ebp),%eax
   196d1:	83 c0 04             	add    $0x4,%eax
   196d4:	8b 00                	mov    (%eax),%eax
   196d6:	0f b6 00             	movzbl (%eax),%eax
   196d9:	88 45 c7             	mov    %al,-0x39(%ebp)
			break;
   196dc:	e9 a8 00 00 00       	jmp    19789 <progTUV+0x15a>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   196e1:	ff 75 08             	pushl  0x8(%ebp)
   196e4:	ff 75 d0             	pushl  -0x30(%ebp)
   196e7:	68 f1 bd 01 00       	push   $0x1bdf1
   196ec:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   196f2:	50                   	push   %eax
   196f3:	e8 ca 05 00 00       	call   19cc2 <usprint>
   196f8:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   196fb:	83 ec 0c             	sub    $0xc,%esp
   196fe:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19704:	50                   	push   %eax
   19705:	e8 a5 0c 00 00       	call   1a3af <cwrites>
   1970a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1970d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   19714:	eb 5b                	jmp    19771 <progTUV+0x142>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   19716:	8b 45 08             	mov    0x8(%ebp),%eax
   19719:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19720:	8b 45 0c             	mov    0xc(%ebp),%eax
   19723:	01 d0                	add    %edx,%eax
   19725:	8b 00                	mov    (%eax),%eax
   19727:	85 c0                	test   %eax,%eax
   19729:	74 13                	je     1973e <progTUV+0x10f>
   1972b:	8b 45 08             	mov    0x8(%ebp),%eax
   1972e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19735:	8b 45 0c             	mov    0xc(%ebp),%eax
   19738:	01 d0                	add    %edx,%eax
   1973a:	8b 00                	mov    (%eax),%eax
   1973c:	eb 05                	jmp    19743 <progTUV+0x114>
   1973e:	b8 05 be 01 00       	mov    $0x1be05,%eax
   19743:	83 ec 04             	sub    $0x4,%esp
   19746:	50                   	push   %eax
   19747:	68 0c be 01 00       	push   $0x1be0c
   1974c:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19752:	50                   	push   %eax
   19753:	e8 6a 05 00 00       	call   19cc2 <usprint>
   19758:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1975b:	83 ec 0c             	sub    $0xc,%esp
   1975e:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19764:	50                   	push   %eax
   19765:	e8 45 0c 00 00       	call   1a3af <cwrites>
   1976a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1976d:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   19771:	8b 45 e8             	mov    -0x18(%ebp),%eax
   19774:	3b 45 08             	cmp    0x8(%ebp),%eax
   19777:	7e 9d                	jle    19716 <progTUV+0xe7>
			}
			cwrites( "\n" );
   19779:	83 ec 0c             	sub    $0xc,%esp
   1977c:	68 10 be 01 00       	push   $0x1be10
   19781:	e8 29 0c 00 00       	call   1a3af <cwrites>
   19786:	83 c4 10             	add    $0x10,%esp
	}

	// fix the secondary output message (for indicating errors)
	ch2[1] = ch;
   19789:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   1978d:	88 85 79 fe ff ff    	mov    %al,-0x187(%ebp)

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   19793:	83 ec 04             	sub    $0x4,%esp
   19796:	6a 01                	push   $0x1
   19798:	8d 45 c7             	lea    -0x39(%ebp),%eax
   1979b:	50                   	push   %eax
   1979c:	6a 01                	push   $0x1
   1979e:	e8 9d d7 ff ff       	call   16f40 <write>
   197a3:	83 c4 10             	add    $0x10,%esp

	// set up the argument vector
	char *argsw[] = { "progW", "W", "10", "5", NULL };
   197a6:	c7 85 64 fe ff ff d2 	movl   $0x1bed2,-0x19c(%ebp)
   197ad:	be 01 00 
   197b0:	c7 85 68 fe ff ff e6 	movl   $0x1bbe6,-0x198(%ebp)
   197b7:	bb 01 00 
   197ba:	c7 85 6c fe ff ff 64 	movl   $0x1bb64,-0x194(%ebp)
   197c1:	bb 01 00 
   197c4:	c7 85 70 fe ff ff 93 	movl   $0x1bb93,-0x190(%ebp)
   197cb:	bb 01 00 
   197ce:	c7 85 74 fe ff ff 00 	movl   $0x0,-0x18c(%ebp)
   197d5:	00 00 00 

	for( int i = 0; i < count; ++i ) {
   197d8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   197df:	eb 4c                	jmp    1982d <progTUV+0x1fe>
		int whom = spawn( (uint32_t) progW, argsw );
   197e1:	ba 04 84 01 00       	mov    $0x18404,%edx
   197e6:	83 ec 08             	sub    $0x8,%esp
   197e9:	8d 85 64 fe ff ff    	lea    -0x19c(%ebp),%eax
   197ef:	50                   	push   %eax
   197f0:	52                   	push   %edx
   197f1:	e8 23 0b 00 00       	call   1a319 <spawn>
   197f6:	83 c4 10             	add    $0x10,%esp
   197f9:	89 45 c8             	mov    %eax,-0x38(%ebp)
		if( whom < 0 ) {
   197fc:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
   19800:	79 14                	jns    19816 <progTUV+0x1e7>
			swrites( ch2 );
   19802:	83 ec 0c             	sub    $0xc,%esp
   19805:	8d 85 78 fe ff ff    	lea    -0x188(%ebp),%eax
   1980b:	50                   	push   %eax
   1980c:	e8 04 0c 00 00       	call   1a415 <swrites>
   19811:	83 c4 10             	add    $0x10,%esp
   19814:	eb 13                	jmp    19829 <progTUV+0x1fa>
		} else {
			children[nkids++] = whom;
   19816:	8b 45 ec             	mov    -0x14(%ebp),%eax
   19819:	8d 50 01             	lea    0x1(%eax),%edx
   1981c:	89 55 ec             	mov    %edx,-0x14(%ebp)
   1981f:	8b 55 c8             	mov    -0x38(%ebp),%edx
   19822:	89 94 85 7c fe ff ff 	mov    %edx,-0x184(%ebp,%eax,4)
	for( int i = 0; i < count; ++i ) {
   19829:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   1982d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   19830:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   19833:	7c ac                	jl     197e1 <progTUV+0x1b2>
		}
	}

	// let the children start
	sleep( SEC_TO_MS(nap) );
   19835:	8b 45 cc             	mov    -0x34(%ebp),%eax
   19838:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   1983e:	83 ec 0c             	sub    $0xc,%esp
   19841:	50                   	push   %eax
   19842:	e8 31 d7 ff ff       	call   16f78 <sleep>
   19847:	83 c4 10             	add    $0x10,%esp

	// collect exit status information

	// current child index
	int n = 0;
   1984a:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	do {
		int this;
		int32_t status;

		// are we waiting for or killing it?
		if( waiting ) {
   19851:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   19855:	74 2f                	je     19886 <progTUV+0x257>
			this = waitpid( bypid ? children[n] : 0, &status );
   19857:	80 7d f2 00          	cmpb   $0x0,-0xe(%ebp)
   1985b:	74 0c                	je     19869 <progTUV+0x23a>
   1985d:	8b 45 e0             	mov    -0x20(%ebp),%eax
   19860:	8b 84 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%eax
   19867:	eb 05                	jmp    1986e <progTUV+0x23f>
   19869:	b8 00 00 00 00       	mov    $0x0,%eax
   1986e:	83 ec 08             	sub    $0x8,%esp
   19871:	8d 95 60 fe ff ff    	lea    -0x1a0(%ebp),%edx
   19877:	52                   	push   %edx
   19878:	50                   	push   %eax
   19879:	e8 a2 d6 ff ff       	call   16f20 <waitpid>
   1987e:	83 c4 10             	add    $0x10,%esp
   19881:	89 45 dc             	mov    %eax,-0x24(%ebp)
   19884:	eb 19                	jmp    1989f <progTUV+0x270>
		} else {
			// always by PID
			this = kill( children[n] );
   19886:	8b 45 e0             	mov    -0x20(%ebp),%eax
   19889:	8b 84 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%eax
   19890:	83 ec 0c             	sub    $0xc,%esp
   19893:	50                   	push   %eax
   19894:	e8 d7 d6 ff ff       	call   16f70 <kill>
   19899:	83 c4 10             	add    $0x10,%esp
   1989c:	89 45 dc             	mov    %eax,-0x24(%ebp)
		}

		// what was the result?
		if( this < SUCCESS ) {
   1989f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   198a3:	0f 89 a1 00 00 00    	jns    1994a <progTUV+0x31b>

			// uh-oh - something went wrong

			// "no children" means we're all done
			if( this != E_NO_CHILDREN ) {
   198a9:	83 7d dc fc          	cmpl   $0xfffffffc,-0x24(%ebp)
   198ad:	74 77                	je     19926 <progTUV+0x2f7>
				if( waiting ) {
   198af:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   198b3:	74 3f                	je     198f4 <progTUV+0x2c5>
					usprint( buf, "!! %c: waitpid(%d) status %d\n",
   198b5:	80 7d f2 00          	cmpb   $0x0,-0xe(%ebp)
   198b9:	74 0c                	je     198c7 <progTUV+0x298>
   198bb:	8b 45 e0             	mov    -0x20(%ebp),%eax
   198be:	8b 84 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%eax
   198c5:	eb 05                	jmp    198cc <progTUV+0x29d>
   198c7:	b8 00 00 00 00       	mov    $0x0,%eax
   198cc:	0f b6 55 c7          	movzbl -0x39(%ebp),%edx
   198d0:	0f be d2             	movsbl %dl,%edx
   198d3:	83 ec 0c             	sub    $0xc,%esp
   198d6:	ff 75 dc             	pushl  -0x24(%ebp)
   198d9:	50                   	push   %eax
   198da:	52                   	push   %edx
   198db:	68 a4 bf 01 00       	push   $0x1bfa4
   198e0:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   198e6:	50                   	push   %eax
   198e7:	e8 d6 03 00 00       	call   19cc2 <usprint>
   198ec:	83 c4 20             	add    $0x20,%esp
			} else {
				usprint( buf, "!! %c: no children\n", ch );
			}

			// regardless, we're outta here
			break;
   198ef:	e9 9d 01 00 00       	jmp    19a91 <progTUV+0x462>
					usprint( buf, "!! %c: kill(%d) status %d\n",
   198f4:	8b 45 e0             	mov    -0x20(%ebp),%eax
   198f7:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   198fe:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   19902:	0f be c0             	movsbl %al,%eax
   19905:	83 ec 0c             	sub    $0xc,%esp
   19908:	ff 75 dc             	pushl  -0x24(%ebp)
   1990b:	52                   	push   %edx
   1990c:	50                   	push   %eax
   1990d:	68 d8 be 01 00       	push   $0x1bed8
   19912:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19918:	50                   	push   %eax
   19919:	e8 a4 03 00 00       	call   19cc2 <usprint>
   1991e:	83 c4 20             	add    $0x20,%esp
			break;
   19921:	e9 6b 01 00 00       	jmp    19a91 <progTUV+0x462>
				usprint( buf, "!! %c: no children\n", ch );
   19926:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   1992a:	0f be c0             	movsbl %al,%eax
   1992d:	83 ec 04             	sub    $0x4,%esp
   19930:	50                   	push   %eax
   19931:	68 c2 bf 01 00       	push   $0x1bfc2
   19936:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   1993c:	50                   	push   %eax
   1993d:	e8 80 03 00 00       	call   19cc2 <usprint>
   19942:	83 c4 10             	add    $0x10,%esp
   19945:	e9 47 01 00 00       	jmp    19a91 <progTUV+0x462>

		} else {

			// locate the child
			int ix = -1;
   1994a:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)

			// were we looking by PID?
			if( bypid ) {
   19951:	80 7d f2 00          	cmpb   $0x0,-0xe(%ebp)
   19955:	74 58                	je     199af <progTUV+0x380>
				// we should have just gotten the one we were looking for
				if( this != children[n] ) {
   19957:	8b 45 e0             	mov    -0x20(%ebp),%eax
   1995a:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   19961:	8b 45 dc             	mov    -0x24(%ebp),%eax
   19964:	39 c2                	cmp    %eax,%edx
   19966:	74 41                	je     199a9 <progTUV+0x37a>
					// uh-oh
					usprint( buf, "** %c: wait/kill PID %d, got %d\n",
   19968:	8b 45 e0             	mov    -0x20(%ebp),%eax
   1996b:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   19972:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   19976:	0f be c0             	movsbl %al,%eax
   19979:	83 ec 0c             	sub    $0xc,%esp
   1997c:	ff 75 dc             	pushl  -0x24(%ebp)
   1997f:	52                   	push   %edx
   19980:	50                   	push   %eax
   19981:	68 d8 bf 01 00       	push   $0x1bfd8
   19986:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   1998c:	50                   	push   %eax
   1998d:	e8 30 03 00 00       	call   19cc2 <usprint>
   19992:	83 c4 20             	add    $0x20,%esp
							ch, children[n], this );
					cwrites( buf );
   19995:	83 ec 0c             	sub    $0xc,%esp
   19998:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   1999e:	50                   	push   %eax
   1999f:	e8 0b 0a 00 00       	call   1a3af <cwrites>
   199a4:	83 c4 10             	add    $0x10,%esp
   199a7:	eb 06                	jmp    199af <progTUV+0x380>
				} else {
					ix = n;
   199a9:	8b 45 e0             	mov    -0x20(%ebp),%eax
   199ac:	89 45 d8             	mov    %eax,-0x28(%ebp)
				}
			}

			// either not looking by PID, or the lookup failed somehow
			if( ix < 0 ) {
   199af:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   199b3:	79 2e                	jns    199e3 <progTUV+0x3b4>
				int i;
				for( i = 0; i < nkids; ++i ) {
   199b5:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
   199bc:	eb 1d                	jmp    199db <progTUV+0x3ac>
					if( children[i] == this ) {
   199be:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   199c1:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   199c8:	8b 45 dc             	mov    -0x24(%ebp),%eax
   199cb:	39 c2                	cmp    %eax,%edx
   199cd:	75 08                	jne    199d7 <progTUV+0x3a8>
						ix = i;
   199cf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   199d2:	89 45 d8             	mov    %eax,-0x28(%ebp)
						break;
   199d5:	eb 0c                	jmp    199e3 <progTUV+0x3b4>
				for( i = 0; i < nkids; ++i ) {
   199d7:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
   199db:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   199de:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   199e1:	7c db                	jl     199be <progTUV+0x38f>
				}
			}

			// if ix == -1, the PID we received isn't in our list of children

			if( ix < 0 ) {
   199e3:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   199e7:	79 21                	jns    19a0a <progTUV+0x3db>

				// didn't find an entry for this PID???
				usprint( buf, "!! %c: child PID %d term, NOT FOUND\n",
   199e9:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   199ed:	0f be c0             	movsbl %al,%eax
   199f0:	ff 75 dc             	pushl  -0x24(%ebp)
   199f3:	50                   	push   %eax
   199f4:	68 fc bf 01 00       	push   $0x1bffc
   199f9:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   199ff:	50                   	push   %eax
   19a00:	e8 bd 02 00 00       	call   19cc2 <usprint>
   19a05:	83 c4 10             	add    $0x10,%esp
   19a08:	eb 65                	jmp    19a6f <progTUV+0x440>
						ch, this );

			} else {

				// found this PID in our list of children
				if( ix != n ) {
   19a0a:	8b 45 d8             	mov    -0x28(%ebp),%eax
   19a0d:	3b 45 e0             	cmp    -0x20(%ebp),%eax
   19a10:	74 31                	je     19a43 <progTUV+0x414>
					// ... but it's out of sequence
					usprint( buf, "== %c: child %d (%d,%d) status %d\n",
   19a12:	8b 95 60 fe ff ff    	mov    -0x1a0(%ebp),%edx
   19a18:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   19a1c:	0f be c0             	movsbl %al,%eax
   19a1f:	83 ec 04             	sub    $0x4,%esp
   19a22:	52                   	push   %edx
   19a23:	ff 75 dc             	pushl  -0x24(%ebp)
   19a26:	ff 75 e0             	pushl  -0x20(%ebp)
   19a29:	ff 75 d8             	pushl  -0x28(%ebp)
   19a2c:	50                   	push   %eax
   19a2d:	68 24 c0 01 00       	push   $0x1c024
   19a32:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19a38:	50                   	push   %eax
   19a39:	e8 84 02 00 00       	call   19cc2 <usprint>
   19a3e:	83 c4 20             	add    $0x20,%esp
   19a41:	eb 2c                	jmp    19a6f <progTUV+0x440>
							ch, ix, n, this, status );
				} else {
					usprint( buf, "== %c: child %d (%d) status %d\n",
   19a43:	8b 95 60 fe ff ff    	mov    -0x1a0(%ebp),%edx
   19a49:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   19a4d:	0f be c0             	movsbl %al,%eax
   19a50:	83 ec 08             	sub    $0x8,%esp
   19a53:	52                   	push   %edx
   19a54:	ff 75 dc             	pushl  -0x24(%ebp)
   19a57:	ff 75 d8             	pushl  -0x28(%ebp)
   19a5a:	50                   	push   %eax
   19a5b:	68 48 c0 01 00       	push   $0x1c048
   19a60:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19a66:	50                   	push   %eax
   19a67:	e8 56 02 00 00       	call   19cc2 <usprint>
   19a6c:	83 c4 20             	add    $0x20,%esp
				}
			}

		}

		cwrites( buf );
   19a6f:	83 ec 0c             	sub    $0xc,%esp
   19a72:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19a78:	50                   	push   %eax
   19a79:	e8 31 09 00 00       	call   1a3af <cwrites>
   19a7e:	83 c4 10             	add    $0x10,%esp

		++n;
   19a81:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)

	} while( n < nkids );
   19a85:	8b 45 e0             	mov    -0x20(%ebp),%eax
   19a88:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   19a8b:	0f 8c c0 fd ff ff    	jl     19851 <progTUV+0x222>

	exit( 0 );
   19a91:	83 ec 0c             	sub    $0xc,%esp
   19a94:	6a 00                	push   $0x0
   19a96:	e8 7d d4 ff ff       	call   16f18 <exit>
   19a9b:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   19a9e:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   19aa3:	c9                   	leave  
   19aa4:	c3                   	ret    

00019aa5 <ublkmov>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void ublkmov( void *dst, const void *src, register uint32_t len ) {
   19aa5:	55                   	push   %ebp
   19aa6:	89 e5                	mov    %esp,%ebp
   19aa8:	56                   	push   %esi
   19aa9:	53                   	push   %ebx
   19aaa:	8b 45 10             	mov    0x10(%ebp),%eax

	// verify that the addresses are aligned and
	// the length is a multiple of four bytes
	if( (((uint32_t)dst)&0x3) != 0 ||
   19aad:	8b 55 08             	mov    0x8(%ebp),%edx
   19ab0:	83 e2 03             	and    $0x3,%edx
   19ab3:	85 d2                	test   %edx,%edx
   19ab5:	75 13                	jne    19aca <ublkmov+0x25>
		(((uint32_t)src)&0x3) != 0 ||
   19ab7:	8b 55 0c             	mov    0xc(%ebp),%edx
   19aba:	83 e2 03             	and    $0x3,%edx
	if( (((uint32_t)dst)&0x3) != 0 ||
   19abd:	85 d2                	test   %edx,%edx
   19abf:	75 09                	jne    19aca <ublkmov+0x25>
		(len & 0x3) != 0 ) {
   19ac1:	89 c2                	mov    %eax,%edx
   19ac3:	83 e2 03             	and    $0x3,%edx
		(((uint32_t)src)&0x3) != 0 ||
   19ac6:	85 d2                	test   %edx,%edx
   19ac8:	74 14                	je     19ade <ublkmov+0x39>
		// something isn't aligned, so just use memmove()
		umemmove( dst, src, len );
   19aca:	83 ec 04             	sub    $0x4,%esp
   19acd:	50                   	push   %eax
   19ace:	ff 75 0c             	pushl  0xc(%ebp)
   19ad1:	ff 75 08             	pushl  0x8(%ebp)
   19ad4:	e8 b4 00 00 00       	call   19b8d <umemmove>
   19ad9:	83 c4 10             	add    $0x10,%esp
		return;
   19adc:	eb 5a                	jmp    19b38 <ublkmov+0x93>
	}

	// everything is nicely aligned, so off we go
	register uint32_t *dest = dst;
   19ade:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint32_t *source = src;
   19ae1:	8b 75 0c             	mov    0xc(%ebp),%esi

	// now copying 32-bit values
	len /= 4;
   19ae4:	c1 e8 02             	shr    $0x2,%eax

	if( source < dest && (source + len) > dest ) {
   19ae7:	39 de                	cmp    %ebx,%esi
   19ae9:	73 44                	jae    19b2f <ublkmov+0x8a>
   19aeb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19af2:	01 f2                	add    %esi,%edx
   19af4:	39 d3                	cmp    %edx,%ebx
   19af6:	73 37                	jae    19b2f <ublkmov+0x8a>
		source += len;
   19af8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19aff:	01 d6                	add    %edx,%esi
		dest += len;
   19b01:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19b08:	01 d3                	add    %edx,%ebx
		while( len-- > 0 ) {
   19b0a:	eb 0a                	jmp    19b16 <ublkmov+0x71>
			*--dest = *--source;
   19b0c:	83 ee 04             	sub    $0x4,%esi
   19b0f:	83 eb 04             	sub    $0x4,%ebx
   19b12:	8b 16                	mov    (%esi),%edx
   19b14:	89 13                	mov    %edx,(%ebx)
		while( len-- > 0 ) {
   19b16:	89 c2                	mov    %eax,%edx
   19b18:	8d 42 ff             	lea    -0x1(%edx),%eax
   19b1b:	85 d2                	test   %edx,%edx
   19b1d:	75 ed                	jne    19b0c <ublkmov+0x67>
	if( source < dest && (source + len) > dest ) {
   19b1f:	eb 17                	jmp    19b38 <ublkmov+0x93>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   19b21:	89 f1                	mov    %esi,%ecx
   19b23:	8d 71 04             	lea    0x4(%ecx),%esi
   19b26:	89 da                	mov    %ebx,%edx
   19b28:	8d 5a 04             	lea    0x4(%edx),%ebx
   19b2b:	8b 09                	mov    (%ecx),%ecx
   19b2d:	89 0a                	mov    %ecx,(%edx)
		while( len-- ) {
   19b2f:	89 c2                	mov    %eax,%edx
   19b31:	8d 42 ff             	lea    -0x1(%edx),%eax
   19b34:	85 d2                	test   %edx,%edx
   19b36:	75 e9                	jne    19b21 <ublkmov+0x7c>
		}
	}
}
   19b38:	8d 65 f8             	lea    -0x8(%ebp),%esp
   19b3b:	5b                   	pop    %ebx
   19b3c:	5e                   	pop    %esi
   19b3d:	5d                   	pop    %ebp
   19b3e:	c3                   	ret    

00019b3f <umemclr>:
** Initialize all bytes of a block of memory to zero
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
*/
void umemclr( void *buf, register uint32_t len ) {
   19b3f:	55                   	push   %ebp
   19b40:	89 e5                	mov    %esp,%ebp
   19b42:	53                   	push   %ebx
   19b43:	8b 55 0c             	mov    0xc(%ebp),%edx
	register uint8_t *dest = buf;
   19b46:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and clearing
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   19b49:	eb 08                	jmp    19b53 <umemclr+0x14>
			*dest++ = 0;
   19b4b:	89 d8                	mov    %ebx,%eax
   19b4d:	8d 58 01             	lea    0x1(%eax),%ebx
   19b50:	c6 00 00             	movb   $0x0,(%eax)
	while( len-- ) {
   19b53:	89 d0                	mov    %edx,%eax
   19b55:	8d 50 ff             	lea    -0x1(%eax),%edx
   19b58:	85 c0                	test   %eax,%eax
   19b5a:	75 ef                	jne    19b4b <umemclr+0xc>
	}
}
   19b5c:	90                   	nop
   19b5d:	5b                   	pop    %ebx
   19b5e:	5d                   	pop    %ebp
   19b5f:	c3                   	ret    

00019b60 <umemcpy>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void umemcpy( void *dst, register const void *src, register uint32_t len ) {
   19b60:	55                   	push   %ebp
   19b61:	89 e5                	mov    %esp,%ebp
   19b63:	56                   	push   %esi
   19b64:	53                   	push   %ebx
   19b65:	8b 4d 10             	mov    0x10(%ebp),%ecx
	register uint8_t *dest = dst;
   19b68:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint8_t *source = src;
   19b6b:	8b 75 0c             	mov    0xc(%ebp),%esi
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   19b6e:	eb 0f                	jmp    19b7f <umemcpy+0x1f>
		*dest++ = *source++;
   19b70:	89 f2                	mov    %esi,%edx
   19b72:	8d 72 01             	lea    0x1(%edx),%esi
   19b75:	89 d8                	mov    %ebx,%eax
   19b77:	8d 58 01             	lea    0x1(%eax),%ebx
   19b7a:	0f b6 12             	movzbl (%edx),%edx
   19b7d:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   19b7f:	89 c8                	mov    %ecx,%eax
   19b81:	8d 48 ff             	lea    -0x1(%eax),%ecx
   19b84:	85 c0                	test   %eax,%eax
   19b86:	75 e8                	jne    19b70 <umemcpy+0x10>
	}
}
   19b88:	90                   	nop
   19b89:	5b                   	pop    %ebx
   19b8a:	5e                   	pop    %esi
   19b8b:	5d                   	pop    %ebp
   19b8c:	c3                   	ret    

00019b8d <umemmove>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void umemmove( void *dst, const void *src, register uint32_t len ) {
   19b8d:	55                   	push   %ebp
   19b8e:	89 e5                	mov    %esp,%ebp
   19b90:	56                   	push   %esi
   19b91:	53                   	push   %ebx
   19b92:	8b 45 10             	mov    0x10(%ebp),%eax
	register uint8_t *dest = dst;
   19b95:	8b 75 08             	mov    0x8(%ebp),%esi
	register const uint8_t *source = src;
   19b98:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	if( source < dest && (source + len) > dest ) {
   19b9b:	39 f3                	cmp    %esi,%ebx
   19b9d:	73 32                	jae    19bd1 <umemmove+0x44>
   19b9f:	8d 14 03             	lea    (%ebx,%eax,1),%edx
   19ba2:	39 d6                	cmp    %edx,%esi
   19ba4:	73 2b                	jae    19bd1 <umemmove+0x44>
		source += len;
   19ba6:	01 c3                	add    %eax,%ebx
		dest += len;
   19ba8:	01 c6                	add    %eax,%esi
		while( len-- > 0 ) {
   19baa:	eb 0b                	jmp    19bb7 <umemmove+0x2a>
			*--dest = *--source;
   19bac:	83 eb 01             	sub    $0x1,%ebx
   19baf:	83 ee 01             	sub    $0x1,%esi
   19bb2:	0f b6 13             	movzbl (%ebx),%edx
   19bb5:	88 16                	mov    %dl,(%esi)
		while( len-- > 0 ) {
   19bb7:	89 c2                	mov    %eax,%edx
   19bb9:	8d 42 ff             	lea    -0x1(%edx),%eax
   19bbc:	85 d2                	test   %edx,%edx
   19bbe:	75 ec                	jne    19bac <umemmove+0x1f>
	if( source < dest && (source + len) > dest ) {
   19bc0:	eb 18                	jmp    19bda <umemmove+0x4d>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   19bc2:	89 d9                	mov    %ebx,%ecx
   19bc4:	8d 59 01             	lea    0x1(%ecx),%ebx
   19bc7:	89 f2                	mov    %esi,%edx
   19bc9:	8d 72 01             	lea    0x1(%edx),%esi
   19bcc:	0f b6 09             	movzbl (%ecx),%ecx
   19bcf:	88 0a                	mov    %cl,(%edx)
		while( len-- ) {
   19bd1:	89 c2                	mov    %eax,%edx
   19bd3:	8d 42 ff             	lea    -0x1(%edx),%eax
   19bd6:	85 d2                	test   %edx,%edx
   19bd8:	75 e8                	jne    19bc2 <umemmove+0x35>
		}
	}
}
   19bda:	90                   	nop
   19bdb:	5b                   	pop    %ebx
   19bdc:	5e                   	pop    %esi
   19bdd:	5d                   	pop    %ebp
   19bde:	c3                   	ret    

00019bdf <umemset>:
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
** @param value  Initialization value
*/
void umemset( void *buf, register uint32_t len, register uint32_t value ) {
   19bdf:	55                   	push   %ebp
   19be0:	89 e5                	mov    %esp,%ebp
   19be2:	53                   	push   %ebx
   19be3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register uint8_t *bp = buf;
   19be6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   19be9:	eb 0b                	jmp    19bf6 <umemset+0x17>
		*bp++ = value;
   19beb:	89 d8                	mov    %ebx,%eax
   19bed:	8d 58 01             	lea    0x1(%eax),%ebx
   19bf0:	0f b6 55 10          	movzbl 0x10(%ebp),%edx
   19bf4:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   19bf6:	89 c8                	mov    %ecx,%eax
   19bf8:	8d 48 ff             	lea    -0x1(%eax),%ecx
   19bfb:	85 c0                	test   %eax,%eax
   19bfd:	75 ec                	jne    19beb <umemset+0xc>
	}
}
   19bff:	90                   	nop
   19c00:	5b                   	pop    %ebx
   19c01:	5d                   	pop    %ebp
   19c02:	c3                   	ret    

00019c03 <upad>:
**
** @return Pointer to the first byte after the padding
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *upad( char *dst, int extra, int padchar ) {
   19c03:	55                   	push   %ebp
   19c04:	89 e5                	mov    %esp,%ebp
	while( extra > 0 ){
   19c06:	eb 12                	jmp    19c1a <upad+0x17>
		*dst++ = (char) padchar;
   19c08:	8b 45 08             	mov    0x8(%ebp),%eax
   19c0b:	8d 50 01             	lea    0x1(%eax),%edx
   19c0e:	89 55 08             	mov    %edx,0x8(%ebp)
   19c11:	8b 55 10             	mov    0x10(%ebp),%edx
   19c14:	88 10                	mov    %dl,(%eax)
		extra -= 1;
   19c16:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
	while( extra > 0 ){
   19c1a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   19c1e:	7f e8                	jg     19c08 <upad+0x5>
	}
	return dst;
   19c20:	8b 45 08             	mov    0x8(%ebp),%eax
}
   19c23:	5d                   	pop    %ebp
   19c24:	c3                   	ret    

00019c25 <upadstr>:
** @return Pointer to the first byte after the padded string
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *upadstr( char *dst, char *str, int len, int width,
				int leftadjust, int padchar ) {
   19c25:	55                   	push   %ebp
   19c26:	89 e5                	mov    %esp,%ebp
   19c28:	83 ec 18             	sub    $0x18,%esp
	int extra;

	// determine the length of the string if we need to
	if( len < 0 ){
   19c2b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
   19c2f:	79 11                	jns    19c42 <upadstr+0x1d>
		len = ustrlen( str );
   19c31:	83 ec 0c             	sub    $0xc,%esp
   19c34:	ff 75 0c             	pushl  0xc(%ebp)
   19c37:	e8 03 04 00 00       	call   1a03f <ustrlen>
   19c3c:	83 c4 10             	add    $0x10,%esp
   19c3f:	89 45 10             	mov    %eax,0x10(%ebp)
	}

	// how much filler must we add?
	extra = width - len;
   19c42:	8b 45 14             	mov    0x14(%ebp),%eax
   19c45:	2b 45 10             	sub    0x10(%ebp),%eax
   19c48:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// add filler on the left if we're not left-justifying
	if( extra > 0 && !leftadjust ){
   19c4b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   19c4f:	7e 1d                	jle    19c6e <upadstr+0x49>
   19c51:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   19c55:	75 17                	jne    19c6e <upadstr+0x49>
		dst = upad( dst, extra, padchar );
   19c57:	83 ec 04             	sub    $0x4,%esp
   19c5a:	ff 75 1c             	pushl  0x1c(%ebp)
   19c5d:	ff 75 f0             	pushl  -0x10(%ebp)
   19c60:	ff 75 08             	pushl  0x8(%ebp)
   19c63:	e8 9b ff ff ff       	call   19c03 <upad>
   19c68:	83 c4 10             	add    $0x10,%esp
   19c6b:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	// copy the string itself
	for( int i = 0; i < len; ++i ) {
   19c6e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   19c75:	eb 1b                	jmp    19c92 <upadstr+0x6d>
		*dst++ = str[i];
   19c77:	8b 55 f4             	mov    -0xc(%ebp),%edx
   19c7a:	8b 45 0c             	mov    0xc(%ebp),%eax
   19c7d:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
   19c80:	8b 45 08             	mov    0x8(%ebp),%eax
   19c83:	8d 50 01             	lea    0x1(%eax),%edx
   19c86:	89 55 08             	mov    %edx,0x8(%ebp)
   19c89:	0f b6 11             	movzbl (%ecx),%edx
   19c8c:	88 10                	mov    %dl,(%eax)
	for( int i = 0; i < len; ++i ) {
   19c8e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   19c92:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19c95:	3b 45 10             	cmp    0x10(%ebp),%eax
   19c98:	7c dd                	jl     19c77 <upadstr+0x52>
	}

	// add filler on the right if we are left-justifying
	if( extra > 0 && leftadjust ){
   19c9a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   19c9e:	7e 1d                	jle    19cbd <upadstr+0x98>
   19ca0:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   19ca4:	74 17                	je     19cbd <upadstr+0x98>
		dst = upad( dst, extra, padchar );
   19ca6:	83 ec 04             	sub    $0x4,%esp
   19ca9:	ff 75 1c             	pushl  0x1c(%ebp)
   19cac:	ff 75 f0             	pushl  -0x10(%ebp)
   19caf:	ff 75 08             	pushl  0x8(%ebp)
   19cb2:	e8 4c ff ff ff       	call   19c03 <upad>
   19cb7:	83 c4 10             	add    $0x10,%esp
   19cba:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	return dst;
   19cbd:	8b 45 08             	mov    0x8(%ebp),%eax
}
   19cc0:	c9                   	leave  
   19cc1:	c3                   	ret    

00019cc2 <usprint>:
**
** NOTE:  relies heavily on the x86 parameter passing convention
** (parameters are pushed onto the stack in reverse order as
** 32-bit values).
*/
void usprint( char *dst, char *fmt, ... ) {
   19cc2:	55                   	push   %ebp
   19cc3:	89 e5                	mov    %esp,%ebp
   19cc5:	83 ec 38             	sub    $0x38,%esp
	** to point to the next "thing", and interpret it according
	** to the format string.
	*/
	
	// get the pointer to the first "value" parameter
	ap = (int *)(&fmt) + 1;
   19cc8:	8d 45 0c             	lea    0xc(%ebp),%eax
   19ccb:	83 c0 04             	add    $0x4,%eax
   19cce:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// iterate through the format string
	while( (ch = *fmt++) != '\0' ){
   19cd1:	e9 3f 02 00 00       	jmp    19f15 <usprint+0x253>
		/*
		** Is it the start of a format code?
		*/
		if( ch == '%' ){
   19cd6:	80 7d f3 25          	cmpb   $0x25,-0xd(%ebp)
   19cda:	0f 85 26 02 00 00    	jne    19f06 <usprint+0x244>
			/*
			** Yes, get the padding and width options (if there).
			** Alignment must come at the beginning, then fill,
			** then width.
			*/
			leftadjust = 0;
   19ce0:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
			padchar = ' ';
   19ce7:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
			width = 0;
   19cee:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
			ch = *fmt++;
   19cf5:	8b 45 0c             	mov    0xc(%ebp),%eax
   19cf8:	8d 50 01             	lea    0x1(%eax),%edx
   19cfb:	89 55 0c             	mov    %edx,0xc(%ebp)
   19cfe:	0f b6 00             	movzbl (%eax),%eax
   19d01:	88 45 f3             	mov    %al,-0xd(%ebp)
			if( ch == '-' ){
   19d04:	80 7d f3 2d          	cmpb   $0x2d,-0xd(%ebp)
   19d08:	75 16                	jne    19d20 <usprint+0x5e>
				leftadjust = 1;
   19d0a:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
				ch = *fmt++;
   19d11:	8b 45 0c             	mov    0xc(%ebp),%eax
   19d14:	8d 50 01             	lea    0x1(%eax),%edx
   19d17:	89 55 0c             	mov    %edx,0xc(%ebp)
   19d1a:	0f b6 00             	movzbl (%eax),%eax
   19d1d:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			if( ch == '0' ){
   19d20:	80 7d f3 30          	cmpb   $0x30,-0xd(%ebp)
   19d24:	75 40                	jne    19d66 <usprint+0xa4>
				padchar = '0';
   19d26:	c7 45 e4 30 00 00 00 	movl   $0x30,-0x1c(%ebp)
				ch = *fmt++;
   19d2d:	8b 45 0c             	mov    0xc(%ebp),%eax
   19d30:	8d 50 01             	lea    0x1(%eax),%edx
   19d33:	89 55 0c             	mov    %edx,0xc(%ebp)
   19d36:	0f b6 00             	movzbl (%eax),%eax
   19d39:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			while( ch >= '0' && ch <= '9' ){
   19d3c:	eb 28                	jmp    19d66 <usprint+0xa4>
				width *= 10;
   19d3e:	8b 55 e8             	mov    -0x18(%ebp),%edx
   19d41:	89 d0                	mov    %edx,%eax
   19d43:	c1 e0 02             	shl    $0x2,%eax
   19d46:	01 d0                	add    %edx,%eax
   19d48:	01 c0                	add    %eax,%eax
   19d4a:	89 45 e8             	mov    %eax,-0x18(%ebp)
				width += ch - '0';
   19d4d:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   19d51:	83 e8 30             	sub    $0x30,%eax
   19d54:	01 45 e8             	add    %eax,-0x18(%ebp)
				ch = *fmt++;
   19d57:	8b 45 0c             	mov    0xc(%ebp),%eax
   19d5a:	8d 50 01             	lea    0x1(%eax),%edx
   19d5d:	89 55 0c             	mov    %edx,0xc(%ebp)
   19d60:	0f b6 00             	movzbl (%eax),%eax
   19d63:	88 45 f3             	mov    %al,-0xd(%ebp)
			while( ch >= '0' && ch <= '9' ){
   19d66:	80 7d f3 2f          	cmpb   $0x2f,-0xd(%ebp)
   19d6a:	7e 06                	jle    19d72 <usprint+0xb0>
   19d6c:	80 7d f3 39          	cmpb   $0x39,-0xd(%ebp)
   19d70:	7e cc                	jle    19d3e <usprint+0x7c>
			}

			/*
			** What data type do we have?
			*/
			switch( ch ) {
   19d72:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   19d76:	83 e8 63             	sub    $0x63,%eax
   19d79:	83 f8 15             	cmp    $0x15,%eax
   19d7c:	0f 87 93 01 00 00    	ja     19f15 <usprint+0x253>
   19d82:	8b 04 85 68 c0 01 00 	mov    0x1c068(,%eax,4),%eax
   19d89:	ff e0                	jmp    *%eax

			case 'c':  // characters are passed as 32-bit values
				ch = *ap++;
   19d8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19d8e:	8d 50 04             	lea    0x4(%eax),%edx
   19d91:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19d94:	8b 00                	mov    (%eax),%eax
   19d96:	88 45 f3             	mov    %al,-0xd(%ebp)
				buf[ 0 ] = ch;
   19d99:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   19d9d:	88 45 d0             	mov    %al,-0x30(%ebp)
				buf[ 1 ] = '\0';
   19da0:	c6 45 d1 00          	movb   $0x0,-0x2f(%ebp)
				dst = upadstr( dst, buf, 1, width, leftadjust, padchar );
   19da4:	83 ec 08             	sub    $0x8,%esp
   19da7:	ff 75 e4             	pushl  -0x1c(%ebp)
   19daa:	ff 75 ec             	pushl  -0x14(%ebp)
   19dad:	ff 75 e8             	pushl  -0x18(%ebp)
   19db0:	6a 01                	push   $0x1
   19db2:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19db5:	50                   	push   %eax
   19db6:	ff 75 08             	pushl  0x8(%ebp)
   19db9:	e8 67 fe ff ff       	call   19c25 <upadstr>
   19dbe:	83 c4 20             	add    $0x20,%esp
   19dc1:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19dc4:	e9 4c 01 00 00       	jmp    19f15 <usprint+0x253>

			case 'd':
				len = ucvtdec( buf, *ap++ );
   19dc9:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19dcc:	8d 50 04             	lea    0x4(%eax),%edx
   19dcf:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19dd2:	8b 00                	mov    (%eax),%eax
   19dd4:	83 ec 08             	sub    $0x8,%esp
   19dd7:	50                   	push   %eax
   19dd8:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19ddb:	50                   	push   %eax
   19ddc:	e8 a4 02 00 00       	call   1a085 <ucvtdec>
   19de1:	83 c4 10             	add    $0x10,%esp
   19de4:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = upadstr( dst, buf, len, width, leftadjust, padchar );
   19de7:	83 ec 08             	sub    $0x8,%esp
   19dea:	ff 75 e4             	pushl  -0x1c(%ebp)
   19ded:	ff 75 ec             	pushl  -0x14(%ebp)
   19df0:	ff 75 e8             	pushl  -0x18(%ebp)
   19df3:	ff 75 e0             	pushl  -0x20(%ebp)
   19df6:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19df9:	50                   	push   %eax
   19dfa:	ff 75 08             	pushl  0x8(%ebp)
   19dfd:	e8 23 fe ff ff       	call   19c25 <upadstr>
   19e02:	83 c4 20             	add    $0x20,%esp
   19e05:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19e08:	e9 08 01 00 00       	jmp    19f15 <usprint+0x253>

			case 's':
				str = (char *) (*ap++);
   19e0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19e10:	8d 50 04             	lea    0x4(%eax),%edx
   19e13:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19e16:	8b 00                	mov    (%eax),%eax
   19e18:	89 45 dc             	mov    %eax,-0x24(%ebp)
				dst = upadstr( dst, str, -1, width, leftadjust, padchar );
   19e1b:	83 ec 08             	sub    $0x8,%esp
   19e1e:	ff 75 e4             	pushl  -0x1c(%ebp)
   19e21:	ff 75 ec             	pushl  -0x14(%ebp)
   19e24:	ff 75 e8             	pushl  -0x18(%ebp)
   19e27:	6a ff                	push   $0xffffffff
   19e29:	ff 75 dc             	pushl  -0x24(%ebp)
   19e2c:	ff 75 08             	pushl  0x8(%ebp)
   19e2f:	e8 f1 fd ff ff       	call   19c25 <upadstr>
   19e34:	83 c4 20             	add    $0x20,%esp
   19e37:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19e3a:	e9 d6 00 00 00       	jmp    19f15 <usprint+0x253>

			case 'x':
				len = ucvthex( buf, *ap++ );
   19e3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19e42:	8d 50 04             	lea    0x4(%eax),%edx
   19e45:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19e48:	8b 00                	mov    (%eax),%eax
   19e4a:	83 ec 08             	sub    $0x8,%esp
   19e4d:	50                   	push   %eax
   19e4e:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19e51:	50                   	push   %eax
   19e52:	e8 fe 02 00 00       	call   1a155 <ucvthex>
   19e57:	83 c4 10             	add    $0x10,%esp
   19e5a:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = upadstr( dst, buf, len, width, leftadjust, padchar );
   19e5d:	83 ec 08             	sub    $0x8,%esp
   19e60:	ff 75 e4             	pushl  -0x1c(%ebp)
   19e63:	ff 75 ec             	pushl  -0x14(%ebp)
   19e66:	ff 75 e8             	pushl  -0x18(%ebp)
   19e69:	ff 75 e0             	pushl  -0x20(%ebp)
   19e6c:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19e6f:	50                   	push   %eax
   19e70:	ff 75 08             	pushl  0x8(%ebp)
   19e73:	e8 ad fd ff ff       	call   19c25 <upadstr>
   19e78:	83 c4 20             	add    $0x20,%esp
   19e7b:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19e7e:	e9 92 00 00 00       	jmp    19f15 <usprint+0x253>

			case 'o':
				len = ucvtoct( buf, *ap++ );
   19e83:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19e86:	8d 50 04             	lea    0x4(%eax),%edx
   19e89:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19e8c:	8b 00                	mov    (%eax),%eax
   19e8e:	83 ec 08             	sub    $0x8,%esp
   19e91:	50                   	push   %eax
   19e92:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19e95:	50                   	push   %eax
   19e96:	e8 44 03 00 00       	call   1a1df <ucvtoct>
   19e9b:	83 c4 10             	add    $0x10,%esp
   19e9e:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = upadstr( dst, buf, len, width, leftadjust, padchar );
   19ea1:	83 ec 08             	sub    $0x8,%esp
   19ea4:	ff 75 e4             	pushl  -0x1c(%ebp)
   19ea7:	ff 75 ec             	pushl  -0x14(%ebp)
   19eaa:	ff 75 e8             	pushl  -0x18(%ebp)
   19ead:	ff 75 e0             	pushl  -0x20(%ebp)
   19eb0:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19eb3:	50                   	push   %eax
   19eb4:	ff 75 08             	pushl  0x8(%ebp)
   19eb7:	e8 69 fd ff ff       	call   19c25 <upadstr>
   19ebc:	83 c4 20             	add    $0x20,%esp
   19ebf:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19ec2:	eb 51                	jmp    19f15 <usprint+0x253>

			case 'u':
				len = ucvtuns( buf, *ap++ );
   19ec4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19ec7:	8d 50 04             	lea    0x4(%eax),%edx
   19eca:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19ecd:	8b 00                	mov    (%eax),%eax
   19ecf:	83 ec 08             	sub    $0x8,%esp
   19ed2:	50                   	push   %eax
   19ed3:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19ed6:	50                   	push   %eax
   19ed7:	e8 8d 03 00 00       	call   1a269 <ucvtuns>
   19edc:	83 c4 10             	add    $0x10,%esp
   19edf:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = upadstr( dst, buf, len, width, leftadjust, padchar );
   19ee2:	83 ec 08             	sub    $0x8,%esp
   19ee5:	ff 75 e4             	pushl  -0x1c(%ebp)
   19ee8:	ff 75 ec             	pushl  -0x14(%ebp)
   19eeb:	ff 75 e8             	pushl  -0x18(%ebp)
   19eee:	ff 75 e0             	pushl  -0x20(%ebp)
   19ef1:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19ef4:	50                   	push   %eax
   19ef5:	ff 75 08             	pushl  0x8(%ebp)
   19ef8:	e8 28 fd ff ff       	call   19c25 <upadstr>
   19efd:	83 c4 20             	add    $0x20,%esp
   19f00:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19f03:	90                   	nop
   19f04:	eb 0f                	jmp    19f15 <usprint+0x253>

			}
		} else {
			// no, it's just an ordinary character
			*dst++ = ch;
   19f06:	8b 45 08             	mov    0x8(%ebp),%eax
   19f09:	8d 50 01             	lea    0x1(%eax),%edx
   19f0c:	89 55 08             	mov    %edx,0x8(%ebp)
   19f0f:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
   19f13:	88 10                	mov    %dl,(%eax)
	while( (ch = *fmt++) != '\0' ){
   19f15:	8b 45 0c             	mov    0xc(%ebp),%eax
   19f18:	8d 50 01             	lea    0x1(%eax),%edx
   19f1b:	89 55 0c             	mov    %edx,0xc(%ebp)
   19f1e:	0f b6 00             	movzbl (%eax),%eax
   19f21:	88 45 f3             	mov    %al,-0xd(%ebp)
   19f24:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   19f28:	0f 85 a8 fd ff ff    	jne    19cd6 <usprint+0x14>
		}
	}

	// NUL-terminate the result
	*dst = '\0';
   19f2e:	8b 45 08             	mov    0x8(%ebp),%eax
   19f31:	c6 00 00             	movb   $0x0,(%eax)
}
   19f34:	90                   	nop
   19f35:	c9                   	leave  
   19f36:	c3                   	ret    

00019f37 <ustr2int>:
** @param str   The string to examine
** @param base  The radix to use in the conversion
**
** @return The converted integer
*/
int ustr2int( register const char *str, register int base ) {
   19f37:	55                   	push   %ebp
   19f38:	89 e5                	mov    %esp,%ebp
   19f3a:	53                   	push   %ebx
   19f3b:	83 ec 14             	sub    $0x14,%esp
   19f3e:	8b 45 08             	mov    0x8(%ebp),%eax
   19f41:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register int num = 0;
   19f44:	bb 00 00 00 00       	mov    $0x0,%ebx
	register char bchar = '9';
   19f49:	c6 45 eb 39          	movb   $0x39,-0x15(%ebp)
	int sign = 1;
   19f4d:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)

	// check for leading '-'
	if( *str == '-' ) {
   19f54:	0f b6 10             	movzbl (%eax),%edx
   19f57:	80 fa 2d             	cmp    $0x2d,%dl
   19f5a:	75 0a                	jne    19f66 <ustr2int+0x2f>
		sign = -1;
   19f5c:	c7 45 f8 ff ff ff ff 	movl   $0xffffffff,-0x8(%ebp)
		++str;
   19f63:	83 c0 01             	add    $0x1,%eax
	}

	if( base != 10 ) {
   19f66:	83 f9 0a             	cmp    $0xa,%ecx
   19f69:	74 2b                	je     19f96 <ustr2int+0x5f>
		bchar = '0' + base - 1;
   19f6b:	89 ca                	mov    %ecx,%edx
   19f6d:	83 c2 2f             	add    $0x2f,%edx
   19f70:	88 55 eb             	mov    %dl,-0x15(%ebp)
	}

	// iterate through the characters
	while( *str ) {
   19f73:	eb 21                	jmp    19f96 <ustr2int+0x5f>
		if( *str < '0' || *str > bchar )
   19f75:	0f b6 10             	movzbl (%eax),%edx
   19f78:	80 fa 2f             	cmp    $0x2f,%dl
   19f7b:	7e 20                	jle    19f9d <ustr2int+0x66>
   19f7d:	0f b6 10             	movzbl (%eax),%edx
   19f80:	38 55 eb             	cmp    %dl,-0x15(%ebp)
   19f83:	7c 18                	jl     19f9d <ustr2int+0x66>
			break;
		num = num * base + *str - '0';
   19f85:	0f af d9             	imul   %ecx,%ebx
   19f88:	0f b6 10             	movzbl (%eax),%edx
   19f8b:	0f be d2             	movsbl %dl,%edx
   19f8e:	01 da                	add    %ebx,%edx
   19f90:	8d 5a d0             	lea    -0x30(%edx),%ebx
		++str;
   19f93:	83 c0 01             	add    $0x1,%eax
	while( *str ) {
   19f96:	0f b6 10             	movzbl (%eax),%edx
   19f99:	84 d2                	test   %dl,%dl
   19f9b:	75 d8                	jne    19f75 <ustr2int+0x3e>
	}

	// return the converted value
	return( num * sign );
   19f9d:	89 d8                	mov    %ebx,%eax
   19f9f:	0f af 45 f8          	imul   -0x8(%ebp),%eax
}
   19fa3:	83 c4 14             	add    $0x14,%esp
   19fa6:	5b                   	pop    %ebx
   19fa7:	5d                   	pop    %ebp
   19fa8:	c3                   	ret    

00019fa9 <ustrcat>:
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the resulting string
*/
char *ustrcat( register char *dst, register const char *src ) {
   19fa9:	55                   	push   %ebp
   19faa:	89 e5                	mov    %esp,%ebp
   19fac:	56                   	push   %esi
   19fad:	53                   	push   %ebx
   19fae:	8b 45 08             	mov    0x8(%ebp),%eax
   19fb1:	8b 75 0c             	mov    0xc(%ebp),%esi
	register char *tmp = dst;
   19fb4:	89 c3                	mov    %eax,%ebx

	while( *dst )  // find the NUL
   19fb6:	eb 03                	jmp    19fbb <ustrcat+0x12>
		++dst;
   19fb8:	83 c0 01             	add    $0x1,%eax
	while( *dst )  // find the NUL
   19fbb:	0f b6 10             	movzbl (%eax),%edx
   19fbe:	84 d2                	test   %dl,%dl
   19fc0:	75 f6                	jne    19fb8 <ustrcat+0xf>

	while( (*dst++ = *src++) )  // append the src string
   19fc2:	90                   	nop
   19fc3:	89 f1                	mov    %esi,%ecx
   19fc5:	8d 71 01             	lea    0x1(%ecx),%esi
   19fc8:	89 c2                	mov    %eax,%edx
   19fca:	8d 42 01             	lea    0x1(%edx),%eax
   19fcd:	0f b6 09             	movzbl (%ecx),%ecx
   19fd0:	88 0a                	mov    %cl,(%edx)
   19fd2:	0f b6 12             	movzbl (%edx),%edx
   19fd5:	84 d2                	test   %dl,%dl
   19fd7:	75 ea                	jne    19fc3 <ustrcat+0x1a>
		;

	return( tmp );
   19fd9:	89 d8                	mov    %ebx,%eax
}
   19fdb:	5b                   	pop    %ebx
   19fdc:	5e                   	pop    %esi
   19fdd:	5d                   	pop    %ebp
   19fde:	c3                   	ret    

00019fdf <ustrcmp>:
** @param s1 The first source string
** @param s2 The second source string
**
** @return negative if s1 < s2, zero if equal, and positive if s1 > s2
*/
int ustrcmp( register const char *s1, register const char *s2 ) {
   19fdf:	55                   	push   %ebp
   19fe0:	89 e5                	mov    %esp,%ebp
   19fe2:	53                   	push   %ebx
   19fe3:	8b 45 08             	mov    0x8(%ebp),%eax
   19fe6:	8b 55 0c             	mov    0xc(%ebp),%edx

	while( *s1 != 0 && (*s1 == *s2) )
   19fe9:	eb 06                	jmp    19ff1 <ustrcmp+0x12>
		++s1, ++s2;
   19feb:	83 c0 01             	add    $0x1,%eax
   19fee:	83 c2 01             	add    $0x1,%edx
	while( *s1 != 0 && (*s1 == *s2) )
   19ff1:	0f b6 08             	movzbl (%eax),%ecx
   19ff4:	84 c9                	test   %cl,%cl
   19ff6:	74 0a                	je     1a002 <ustrcmp+0x23>
   19ff8:	0f b6 18             	movzbl (%eax),%ebx
   19ffb:	0f b6 0a             	movzbl (%edx),%ecx
   19ffe:	38 cb                	cmp    %cl,%bl
   1a000:	74 e9                	je     19feb <ustrcmp+0xc>

	return( *s1 - *s2 );
   1a002:	0f b6 00             	movzbl (%eax),%eax
   1a005:	0f be c8             	movsbl %al,%ecx
   1a008:	0f b6 02             	movzbl (%edx),%eax
   1a00b:	0f be c0             	movsbl %al,%eax
   1a00e:	29 c1                	sub    %eax,%ecx
   1a010:	89 c8                	mov    %ecx,%eax
}
   1a012:	5b                   	pop    %ebx
   1a013:	5d                   	pop    %ebp
   1a014:	c3                   	ret    

0001a015 <ustrcpy>:
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the copied string
*/
char *ustrcpy( register char *dst, register const char *src ) {
   1a015:	55                   	push   %ebp
   1a016:	89 e5                	mov    %esp,%ebp
   1a018:	56                   	push   %esi
   1a019:	53                   	push   %ebx
   1a01a:	8b 4d 08             	mov    0x8(%ebp),%ecx
   1a01d:	8b 75 0c             	mov    0xc(%ebp),%esi
	register char *tmp = dst;
   1a020:	89 cb                	mov    %ecx,%ebx

	while( (*dst++ = *src++) )
   1a022:	90                   	nop
   1a023:	89 f2                	mov    %esi,%edx
   1a025:	8d 72 01             	lea    0x1(%edx),%esi
   1a028:	89 c8                	mov    %ecx,%eax
   1a02a:	8d 48 01             	lea    0x1(%eax),%ecx
   1a02d:	0f b6 12             	movzbl (%edx),%edx
   1a030:	88 10                	mov    %dl,(%eax)
   1a032:	0f b6 00             	movzbl (%eax),%eax
   1a035:	84 c0                	test   %al,%al
   1a037:	75 ea                	jne    1a023 <ustrcpy+0xe>
		;

	return( tmp );
   1a039:	89 d8                	mov    %ebx,%eax
}
   1a03b:	5b                   	pop    %ebx
   1a03c:	5e                   	pop    %esi
   1a03d:	5d                   	pop    %ebp
   1a03e:	c3                   	ret    

0001a03f <ustrlen>:
**
** @param str The string to examine
**
** @return The length of the string, or 0
*/
uint32_t ustrlen( register const char *str ) {
   1a03f:	55                   	push   %ebp
   1a040:	89 e5                	mov    %esp,%ebp
   1a042:	53                   	push   %ebx
   1a043:	8b 55 08             	mov    0x8(%ebp),%edx
	register uint32_t len = 0;
   1a046:	bb 00 00 00 00       	mov    $0x0,%ebx

	while( *str++ ) {
   1a04b:	eb 03                	jmp    1a050 <ustrlen+0x11>
		++len;
   1a04d:	83 c3 01             	add    $0x1,%ebx
	while( *str++ ) {
   1a050:	89 d0                	mov    %edx,%eax
   1a052:	8d 50 01             	lea    0x1(%eax),%edx
   1a055:	0f b6 00             	movzbl (%eax),%eax
   1a058:	84 c0                	test   %al,%al
   1a05a:	75 f1                	jne    1a04d <ustrlen+0xe>
	}

	return( len );
   1a05c:	89 d8                	mov    %ebx,%eax
}
   1a05e:	5b                   	pop    %ebx
   1a05f:	5d                   	pop    %ebp
   1a060:	c3                   	ret    

0001a061 <ubound>:
** @param value  Value to be constrained
** @param max    Upper bound
**
** @return The constrained value
*/
uint32_t ubound( uint32_t min, uint32_t value, uint32_t max ) {
   1a061:	55                   	push   %ebp
   1a062:	89 e5                	mov    %esp,%ebp
	if( value < min ){
   1a064:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a067:	3b 45 08             	cmp    0x8(%ebp),%eax
   1a06a:	73 06                	jae    1a072 <ubound+0x11>
		value = min;
   1a06c:	8b 45 08             	mov    0x8(%ebp),%eax
   1a06f:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	if( value > max ){
   1a072:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a075:	3b 45 10             	cmp    0x10(%ebp),%eax
   1a078:	76 06                	jbe    1a080 <ubound+0x1f>
		value = max;
   1a07a:	8b 45 10             	mov    0x10(%ebp),%eax
   1a07d:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	return value;
   1a080:	8b 45 0c             	mov    0xc(%ebp),%eax
}
   1a083:	5d                   	pop    %ebp
   1a084:	c3                   	ret    

0001a085 <ucvtdec>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int ucvtdec( char *buf, int32_t value ) {
   1a085:	55                   	push   %ebp
   1a086:	89 e5                	mov    %esp,%ebp
   1a088:	83 ec 18             	sub    $0x18,%esp
	char *bp = buf;
   1a08b:	8b 45 08             	mov    0x8(%ebp),%eax
   1a08e:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if( value < 0 ) {
   1a091:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   1a095:	79 0f                	jns    1a0a6 <ucvtdec+0x21>
		*bp++ = '-';
   1a097:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a09a:	8d 50 01             	lea    0x1(%eax),%edx
   1a09d:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1a0a0:	c6 00 2d             	movb   $0x2d,(%eax)
		value = -value;
   1a0a3:	f7 5d 0c             	negl   0xc(%ebp)
	}

	bp = ucvtdec0( bp, value );
   1a0a6:	83 ec 08             	sub    $0x8,%esp
   1a0a9:	ff 75 0c             	pushl  0xc(%ebp)
   1a0ac:	ff 75 f4             	pushl  -0xc(%ebp)
   1a0af:	e8 18 00 00 00       	call   1a0cc <ucvtdec0>
   1a0b4:	83 c4 10             	add    $0x10,%esp
   1a0b7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp  = '\0';
   1a0ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a0bd:	c6 00 00             	movb   $0x0,(%eax)

	return( bp - buf );
   1a0c0:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1a0c3:	8b 45 08             	mov    0x8(%ebp),%eax
   1a0c6:	29 c2                	sub    %eax,%edx
   1a0c8:	89 d0                	mov    %edx,%eax
}
   1a0ca:	c9                   	leave  
   1a0cb:	c3                   	ret    

0001a0cc <ucvtdec0>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *ucvtdec0( char *buf, int value ) {
   1a0cc:	55                   	push   %ebp
   1a0cd:	89 e5                	mov    %esp,%ebp
   1a0cf:	83 ec 18             	sub    $0x18,%esp
	int quotient;

	quotient = value / 10;
   1a0d2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   1a0d5:	ba 67 66 66 66       	mov    $0x66666667,%edx
   1a0da:	89 c8                	mov    %ecx,%eax
   1a0dc:	f7 ea                	imul   %edx
   1a0de:	c1 fa 02             	sar    $0x2,%edx
   1a0e1:	89 c8                	mov    %ecx,%eax
   1a0e3:	c1 f8 1f             	sar    $0x1f,%eax
   1a0e6:	29 c2                	sub    %eax,%edx
   1a0e8:	89 d0                	mov    %edx,%eax
   1a0ea:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient < 0 ) {
   1a0ed:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a0f1:	79 0e                	jns    1a101 <ucvtdec0+0x35>
		quotient = 214748364;
   1a0f3:	c7 45 f4 cc cc cc 0c 	movl   $0xccccccc,-0xc(%ebp)
		value = 8;
   1a0fa:	c7 45 0c 08 00 00 00 	movl   $0x8,0xc(%ebp)
	}
	if( quotient != 0 ) {
   1a101:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a105:	74 14                	je     1a11b <ucvtdec0+0x4f>
		buf = ucvtdec0( buf, quotient );
   1a107:	83 ec 08             	sub    $0x8,%esp
   1a10a:	ff 75 f4             	pushl  -0xc(%ebp)
   1a10d:	ff 75 08             	pushl  0x8(%ebp)
   1a110:	e8 b7 ff ff ff       	call   1a0cc <ucvtdec0>
   1a115:	83 c4 10             	add    $0x10,%esp
   1a118:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   1a11b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   1a11e:	ba 67 66 66 66       	mov    $0x66666667,%edx
   1a123:	89 c8                	mov    %ecx,%eax
   1a125:	f7 ea                	imul   %edx
   1a127:	c1 fa 02             	sar    $0x2,%edx
   1a12a:	89 c8                	mov    %ecx,%eax
   1a12c:	c1 f8 1f             	sar    $0x1f,%eax
   1a12f:	29 c2                	sub    %eax,%edx
   1a131:	89 d0                	mov    %edx,%eax
   1a133:	c1 e0 02             	shl    $0x2,%eax
   1a136:	01 d0                	add    %edx,%eax
   1a138:	01 c0                	add    %eax,%eax
   1a13a:	29 c1                	sub    %eax,%ecx
   1a13c:	89 ca                	mov    %ecx,%edx
   1a13e:	89 d0                	mov    %edx,%eax
   1a140:	8d 48 30             	lea    0x30(%eax),%ecx
   1a143:	8b 45 08             	mov    0x8(%ebp),%eax
   1a146:	8d 50 01             	lea    0x1(%eax),%edx
   1a149:	89 55 08             	mov    %edx,0x8(%ebp)
   1a14c:	89 ca                	mov    %ecx,%edx
   1a14e:	88 10                	mov    %dl,(%eax)
	return buf;
   1a150:	8b 45 08             	mov    0x8(%ebp),%eax
}
   1a153:	c9                   	leave  
   1a154:	c3                   	ret    

0001a155 <ucvthex>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int ucvthex( char *buf, uint32_t value ) {
   1a155:	55                   	push   %ebp
   1a156:	89 e5                	mov    %esp,%ebp
   1a158:	83 ec 20             	sub    $0x20,%esp
	const char hexdigits[] = "0123456789ABCDEF";
   1a15b:	c7 45 e3 30 31 32 33 	movl   $0x33323130,-0x1d(%ebp)
   1a162:	c7 45 e7 34 35 36 37 	movl   $0x37363534,-0x19(%ebp)
   1a169:	c7 45 eb 38 39 41 42 	movl   $0x42413938,-0x15(%ebp)
   1a170:	c7 45 ef 43 44 45 46 	movl   $0x46454443,-0x11(%ebp)
   1a177:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)
	int chars_stored = 0;
   1a17b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)

	for( int i = 0; i < 8; i += 1 ) {
   1a182:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
   1a189:	eb 43                	jmp    1a1ce <ucvthex+0x79>
		uint32_t val = value & 0xf0000000;
   1a18b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a18e:	25 00 00 00 f0       	and    $0xf0000000,%eax
   1a193:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if( chars_stored || val != 0 || i == 7 ) {
   1a196:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
   1a19a:	75 0c                	jne    1a1a8 <ucvthex+0x53>
   1a19c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a1a0:	75 06                	jne    1a1a8 <ucvthex+0x53>
   1a1a2:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   1a1a6:	75 1e                	jne    1a1c6 <ucvthex+0x71>
			++chars_stored;
   1a1a8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
			val = (val >> 28) & 0xf;
   1a1ac:	c1 6d f4 1c          	shrl   $0x1c,-0xc(%ebp)
			*buf++ = hexdigits[val];
   1a1b0:	8b 45 08             	mov    0x8(%ebp),%eax
   1a1b3:	8d 50 01             	lea    0x1(%eax),%edx
   1a1b6:	89 55 08             	mov    %edx,0x8(%ebp)
   1a1b9:	8d 4d e3             	lea    -0x1d(%ebp),%ecx
   1a1bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1a1bf:	01 ca                	add    %ecx,%edx
   1a1c1:	0f b6 12             	movzbl (%edx),%edx
   1a1c4:	88 10                	mov    %dl,(%eax)
		}
		value <<= 4;
   1a1c6:	c1 65 0c 04          	shll   $0x4,0xc(%ebp)
	for( int i = 0; i < 8; i += 1 ) {
   1a1ca:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
   1a1ce:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   1a1d2:	7e b7                	jle    1a18b <ucvthex+0x36>
	}

	*buf = '\0';
   1a1d4:	8b 45 08             	mov    0x8(%ebp),%eax
   1a1d7:	c6 00 00             	movb   $0x0,(%eax)

	return( chars_stored );
   1a1da:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   1a1dd:	c9                   	leave  
   1a1de:	c3                   	ret    

0001a1df <ucvtoct>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int ucvtoct( char *buf, uint32_t value ) {
   1a1df:	55                   	push   %ebp
   1a1e0:	89 e5                	mov    %esp,%ebp
   1a1e2:	83 ec 10             	sub    $0x10,%esp
	int i;
	int chars_stored = 0;
   1a1e5:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	char *bp = buf;
   1a1ec:	8b 45 08             	mov    0x8(%ebp),%eax
   1a1ef:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32_t val;

	val = ( value & 0xc0000000 );
   1a1f2:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a1f5:	25 00 00 00 c0       	and    $0xc0000000,%eax
   1a1fa:	89 45 f0             	mov    %eax,-0x10(%ebp)
	val >>= 30;
   1a1fd:	c1 6d f0 1e          	shrl   $0x1e,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   1a201:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   1a208:	eb 47                	jmp    1a251 <ucvtoct+0x72>

		if( i == 10 || val != 0 || chars_stored ) {
   1a20a:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   1a20e:	74 0c                	je     1a21c <ucvtoct+0x3d>
   1a210:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   1a214:	75 06                	jne    1a21c <ucvtoct+0x3d>
   1a216:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
   1a21a:	74 1e                	je     1a23a <ucvtoct+0x5b>
			chars_stored = 1;
   1a21c:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)
			val &= 0x7;
   1a223:	83 65 f0 07          	andl   $0x7,-0x10(%ebp)
			*bp++ = val + '0';
   1a227:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1a22a:	8d 48 30             	lea    0x30(%eax),%ecx
   1a22d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a230:	8d 50 01             	lea    0x1(%eax),%edx
   1a233:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1a236:	89 ca                	mov    %ecx,%edx
   1a238:	88 10                	mov    %dl,(%eax)
		}
		value <<= 3;
   1a23a:	c1 65 0c 03          	shll   $0x3,0xc(%ebp)
		val = ( value & 0xe0000000 );
   1a23e:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a241:	25 00 00 00 e0       	and    $0xe0000000,%eax
   1a246:	89 45 f0             	mov    %eax,-0x10(%ebp)
		val >>= 29;
   1a249:	c1 6d f0 1d          	shrl   $0x1d,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   1a24d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   1a251:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   1a255:	7e b3                	jle    1a20a <ucvtoct+0x2b>
	}
	*bp = '\0';
   1a257:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a25a:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   1a25d:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1a260:	8b 45 08             	mov    0x8(%ebp),%eax
   1a263:	29 c2                	sub    %eax,%edx
   1a265:	89 d0                	mov    %edx,%eax
}
   1a267:	c9                   	leave  
   1a268:	c3                   	ret    

0001a269 <ucvtuns>:
**
** @return Length of the resulting buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int ucvtuns( char *buf, uint32_t value ) {
   1a269:	55                   	push   %ebp
   1a26a:	89 e5                	mov    %esp,%ebp
   1a26c:	83 ec 18             	sub    $0x18,%esp
	char    *bp = buf;
   1a26f:	8b 45 08             	mov    0x8(%ebp),%eax
   1a272:	89 45 f4             	mov    %eax,-0xc(%ebp)

	bp = ucvtuns0( bp, value );
   1a275:	83 ec 08             	sub    $0x8,%esp
   1a278:	ff 75 0c             	pushl  0xc(%ebp)
   1a27b:	ff 75 f4             	pushl  -0xc(%ebp)
   1a27e:	e8 18 00 00 00       	call   1a29b <ucvtuns0>
   1a283:	83 c4 10             	add    $0x10,%esp
   1a286:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp = '\0';
   1a289:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a28c:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   1a28f:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1a292:	8b 45 08             	mov    0x8(%ebp),%eax
   1a295:	29 c2                	sub    %eax,%edx
   1a297:	89 d0                	mov    %edx,%eax
}
   1a299:	c9                   	leave  
   1a29a:	c3                   	ret    

0001a29b <ucvtuns0>:
**
** @return Pointer to the first unused byte in the buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *ucvtuns0( char *buf, uint32_t value ) {
   1a29b:	55                   	push   %ebp
   1a29c:	89 e5                	mov    %esp,%ebp
   1a29e:	83 ec 18             	sub    $0x18,%esp
	uint32_t quotient;

	quotient = value / 10;
   1a2a1:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a2a4:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   1a2a9:	f7 e2                	mul    %edx
   1a2ab:	89 d0                	mov    %edx,%eax
   1a2ad:	c1 e8 03             	shr    $0x3,%eax
   1a2b0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient != 0 ){
   1a2b3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a2b7:	74 15                	je     1a2ce <ucvtuns0+0x33>
		buf = ucvtdec0( buf, quotient );
   1a2b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a2bc:	83 ec 08             	sub    $0x8,%esp
   1a2bf:	50                   	push   %eax
   1a2c0:	ff 75 08             	pushl  0x8(%ebp)
   1a2c3:	e8 04 fe ff ff       	call   1a0cc <ucvtdec0>
   1a2c8:	83 c4 10             	add    $0x10,%esp
   1a2cb:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   1a2ce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   1a2d1:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   1a2d6:	89 c8                	mov    %ecx,%eax
   1a2d8:	f7 e2                	mul    %edx
   1a2da:	c1 ea 03             	shr    $0x3,%edx
   1a2dd:	89 d0                	mov    %edx,%eax
   1a2df:	c1 e0 02             	shl    $0x2,%eax
   1a2e2:	01 d0                	add    %edx,%eax
   1a2e4:	01 c0                	add    %eax,%eax
   1a2e6:	29 c1                	sub    %eax,%ecx
   1a2e8:	89 ca                	mov    %ecx,%edx
   1a2ea:	89 d0                	mov    %edx,%eax
   1a2ec:	8d 48 30             	lea    0x30(%eax),%ecx
   1a2ef:	8b 45 08             	mov    0x8(%ebp),%eax
   1a2f2:	8d 50 01             	lea    0x1(%eax),%edx
   1a2f5:	89 55 08             	mov    %edx,0x8(%ebp)
   1a2f8:	89 ca                	mov    %ecx,%edx
   1a2fa:	88 10                	mov    %dl,(%eax)
	return buf;
   1a2fc:	8b 45 08             	mov    0x8(%ebp),%eax
}
   1a2ff:	c9                   	leave  
   1a300:	c3                   	ret    

0001a301 <wait>:
** @param status Pointer to int32_t into which the child's status is placed,
**               or NULL
**
** @returns The PID of the terminated child, or an error code
*/
int wait( int32_t *status ) {
   1a301:	55                   	push   %ebp
   1a302:	89 e5                	mov    %esp,%ebp
   1a304:	83 ec 08             	sub    $0x8,%esp
	return( waitpid(0,status) );
   1a307:	83 ec 08             	sub    $0x8,%esp
   1a30a:	ff 75 08             	pushl  0x8(%ebp)
   1a30d:	6a 00                	push   $0x0
   1a30f:	e8 0c cc ff ff       	call   16f20 <waitpid>
   1a314:	83 c4 10             	add    $0x10,%esp
}
   1a317:	c9                   	leave  
   1a318:	c3                   	ret    

0001a319 <spawn>:
** @param entry The entry point of the 'main' function for the process
** @param args  The command-line argument vector for the new process
**
** @returns PID of the new process, or an error code
*/
int32_t spawn( uint32_t entry, char **args ) {
   1a319:	55                   	push   %ebp
   1a31a:	89 e5                	mov    %esp,%ebp
   1a31c:	81 ec 18 01 00 00    	sub    $0x118,%esp
	int32_t pid;
	char buf[256];

	pid = fork();
   1a322:	e8 01 cc ff ff       	call   16f28 <fork>
   1a327:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( pid != 0 ) {
   1a32a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a32e:	74 05                	je     1a335 <spawn+0x1c>
		// failure, or we are the parent
		return( pid );
   1a330:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a333:	eb 57                	jmp    1a38c <spawn+0x73>
	}

	// we are the child
	pid = getpid();
   1a335:	e8 0e cc ff ff       	call   16f48 <getpid>
   1a33a:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// child inherits parent's priority level

	exec( entry, args );
   1a33d:	83 ec 08             	sub    $0x8,%esp
   1a340:	ff 75 0c             	pushl  0xc(%ebp)
   1a343:	ff 75 08             	pushl  0x8(%ebp)
   1a346:	e8 e5 cb ff ff       	call   16f30 <exec>
   1a34b:	83 c4 10             	add    $0x10,%esp

	// uh-oh....

	usprint( buf, "Child %d exec() %08x failed\n", pid, entry );
   1a34e:	ff 75 08             	pushl  0x8(%ebp)
   1a351:	ff 75 f4             	pushl  -0xc(%ebp)
   1a354:	68 c0 c0 01 00       	push   $0x1c0c0
   1a359:	8d 85 f4 fe ff ff    	lea    -0x10c(%ebp),%eax
   1a35f:	50                   	push   %eax
   1a360:	e8 5d f9 ff ff       	call   19cc2 <usprint>
   1a365:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   1a368:	83 ec 0c             	sub    $0xc,%esp
   1a36b:	8d 85 f4 fe ff ff    	lea    -0x10c(%ebp),%eax
   1a371:	50                   	push   %eax
   1a372:	e8 38 00 00 00       	call   1a3af <cwrites>
   1a377:	83 c4 10             	add    $0x10,%esp

	exit( EXIT_FAILURE );
   1a37a:	83 ec 0c             	sub    $0xc,%esp
   1a37d:	6a ff                	push   $0xffffffff
   1a37f:	e8 94 cb ff ff       	call   16f18 <exit>
   1a384:	83 c4 10             	add    $0x10,%esp
	return( 0 );   // shut the compiler up
   1a387:	b8 00 00 00 00       	mov    $0x0,%eax
}
   1a38c:	c9                   	leave  
   1a38d:	c3                   	ret    

0001a38e <cwritech>:
**
** @param ch The character to write
**
** @returns The return value from calling write()
*/
int cwritech( char ch ) {
   1a38e:	55                   	push   %ebp
   1a38f:	89 e5                	mov    %esp,%ebp
   1a391:	83 ec 18             	sub    $0x18,%esp
   1a394:	8b 45 08             	mov    0x8(%ebp),%eax
   1a397:	88 45 f4             	mov    %al,-0xc(%ebp)
	return( write(CHAN_CIO,&ch,1) );
   1a39a:	83 ec 04             	sub    $0x4,%esp
   1a39d:	6a 01                	push   $0x1
   1a39f:	8d 45 f4             	lea    -0xc(%ebp),%eax
   1a3a2:	50                   	push   %eax
   1a3a3:	6a 00                	push   $0x0
   1a3a5:	e8 96 cb ff ff       	call   16f40 <write>
   1a3aa:	83 c4 10             	add    $0x10,%esp
}
   1a3ad:	c9                   	leave  
   1a3ae:	c3                   	ret    

0001a3af <cwrites>:
** cwrites(str) - write a NUL-terminated string to the console
**
** @param str The string to write
**
*/
int cwrites( const char *str ) {
   1a3af:	55                   	push   %ebp
   1a3b0:	89 e5                	mov    %esp,%ebp
   1a3b2:	83 ec 18             	sub    $0x18,%esp
	int len = ustrlen(str);
   1a3b5:	ff 75 08             	pushl  0x8(%ebp)
   1a3b8:	e8 82 fc ff ff       	call   1a03f <ustrlen>
   1a3bd:	83 c4 04             	add    $0x4,%esp
   1a3c0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return( write(CHAN_CIO,str,len) );
   1a3c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a3c6:	83 ec 04             	sub    $0x4,%esp
   1a3c9:	50                   	push   %eax
   1a3ca:	ff 75 08             	pushl  0x8(%ebp)
   1a3cd:	6a 00                	push   $0x0
   1a3cf:	e8 6c cb ff ff       	call   16f40 <write>
   1a3d4:	83 c4 10             	add    $0x10,%esp
}
   1a3d7:	c9                   	leave  
   1a3d8:	c3                   	ret    

0001a3d9 <cwrite>:
** @param buf  The buffer to write
** @param size The number of bytes to write
**
** @returns The return value from calling write()
*/
int cwrite( const char *buf, uint32_t size ) {
   1a3d9:	55                   	push   %ebp
   1a3da:	89 e5                	mov    %esp,%ebp
   1a3dc:	83 ec 08             	sub    $0x8,%esp
	return( write(CHAN_CIO,buf,size) );
   1a3df:	83 ec 04             	sub    $0x4,%esp
   1a3e2:	ff 75 0c             	pushl  0xc(%ebp)
   1a3e5:	ff 75 08             	pushl  0x8(%ebp)
   1a3e8:	6a 00                	push   $0x0
   1a3ea:	e8 51 cb ff ff       	call   16f40 <write>
   1a3ef:	83 c4 10             	add    $0x10,%esp
}
   1a3f2:	c9                   	leave  
   1a3f3:	c3                   	ret    

0001a3f4 <swritech>:
**
** @param ch The character to write
**
** @returns The return value from calling write()
*/
int swritech( char ch ) {
   1a3f4:	55                   	push   %ebp
   1a3f5:	89 e5                	mov    %esp,%ebp
   1a3f7:	83 ec 18             	sub    $0x18,%esp
   1a3fa:	8b 45 08             	mov    0x8(%ebp),%eax
   1a3fd:	88 45 f4             	mov    %al,-0xc(%ebp)
	return( write(CHAN_SIO,&ch,1) );
   1a400:	83 ec 04             	sub    $0x4,%esp
   1a403:	6a 01                	push   $0x1
   1a405:	8d 45 f4             	lea    -0xc(%ebp),%eax
   1a408:	50                   	push   %eax
   1a409:	6a 01                	push   $0x1
   1a40b:	e8 30 cb ff ff       	call   16f40 <write>
   1a410:	83 c4 10             	add    $0x10,%esp
}
   1a413:	c9                   	leave  
   1a414:	c3                   	ret    

0001a415 <swrites>:
**
** @param str The string to write
**
** @returns The return value from calling write()
*/
int swrites( const char *str ) {
   1a415:	55                   	push   %ebp
   1a416:	89 e5                	mov    %esp,%ebp
   1a418:	83 ec 18             	sub    $0x18,%esp
	int len = ustrlen(str);
   1a41b:	ff 75 08             	pushl  0x8(%ebp)
   1a41e:	e8 1c fc ff ff       	call   1a03f <ustrlen>
   1a423:	83 c4 04             	add    $0x4,%esp
   1a426:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return( write(CHAN_SIO,str,len) );
   1a429:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a42c:	83 ec 04             	sub    $0x4,%esp
   1a42f:	50                   	push   %eax
   1a430:	ff 75 08             	pushl  0x8(%ebp)
   1a433:	6a 01                	push   $0x1
   1a435:	e8 06 cb ff ff       	call   16f40 <write>
   1a43a:	83 c4 10             	add    $0x10,%esp
}
   1a43d:	c9                   	leave  
   1a43e:	c3                   	ret    

0001a43f <swrite>:
** @param buf  The buffer to write
** @param size The number of bytes to write
**
** @returns The return value from calling write()
*/
int swrite( const char *buf, uint32_t size ) {
   1a43f:	55                   	push   %ebp
   1a440:	89 e5                	mov    %esp,%ebp
   1a442:	83 ec 08             	sub    $0x8,%esp
	return( write(CHAN_SIO,buf,size) );
   1a445:	83 ec 04             	sub    $0x4,%esp
   1a448:	ff 75 0c             	pushl  0xc(%ebp)
   1a44b:	ff 75 08             	pushl  0x8(%ebp)
   1a44e:	6a 01                	push   $0x1
   1a450:	e8 eb ca ff ff       	call   16f40 <write>
   1a455:	83 c4 10             	add    $0x10,%esp
}
   1a458:	c9                   	leave  
   1a459:	c3                   	ret    
