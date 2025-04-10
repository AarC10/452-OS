
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
   10c0c:	e8 bf 14 00 00       	call   120d0 <bound>
   10c11:	83 c4 10             	add    $0x10,%esp
   10c14:	a3 00 e0 01 00       	mov    %eax,0x1e000
	scroll_min_y = bound( min_y, s_min_y, max_y );
   10c19:	8b 15 24 e0 01 00    	mov    0x1e024,%edx
   10c1f:	a1 1c e0 01 00       	mov    0x1e01c,%eax
   10c24:	83 ec 04             	sub    $0x4,%esp
   10c27:	52                   	push   %edx
   10c28:	ff 75 0c             	pushl  0xc(%ebp)
   10c2b:	50                   	push   %eax
   10c2c:	e8 9f 14 00 00       	call   120d0 <bound>
   10c31:	83 c4 10             	add    $0x10,%esp
   10c34:	a3 04 e0 01 00       	mov    %eax,0x1e004
	scroll_max_x = bound( scroll_min_x, s_max_x, max_x );
   10c39:	8b 15 20 e0 01 00    	mov    0x1e020,%edx
   10c3f:	a1 00 e0 01 00       	mov    0x1e000,%eax
   10c44:	83 ec 04             	sub    $0x4,%esp
   10c47:	52                   	push   %edx
   10c48:	ff 75 10             	pushl  0x10(%ebp)
   10c4b:	50                   	push   %eax
   10c4c:	e8 7f 14 00 00       	call   120d0 <bound>
   10c51:	83 c4 10             	add    $0x10,%esp
   10c54:	a3 08 e0 01 00       	mov    %eax,0x1e008
	scroll_max_y = bound( scroll_min_y, s_max_y, max_y );
   10c59:	8b 15 24 e0 01 00    	mov    0x1e024,%edx
   10c5f:	a1 04 e0 01 00       	mov    0x1e004,%eax
   10c64:	83 ec 04             	sub    $0x4,%esp
   10c67:	52                   	push   %edx
   10c68:	ff 75 14             	pushl  0x14(%ebp)
   10c6b:	50                   	push   %eax
   10c6c:	e8 5f 14 00 00       	call   120d0 <bound>
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
   10cb7:	e8 14 14 00 00       	call   120d0 <bound>
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
   10ce0:	e8 eb 13 00 00       	call   120d0 <bound>
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
   1119b:	e8 c4 18 00 00       	call   12a64 <strlen>
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
   11357:	e8 98 0d 00 00       	call   120f4 <cvtdec>
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
   113d3:	e8 ec 0d 00 00       	call   121c4 <cvthex>
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
   1141a:	e8 2f 0e 00 00       	call   1224e <cvtoct>
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
   11461:	e8 72 0e 00 00       	call   122d8 <cvtuns>
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
   11857:	e8 0a 3f 00 00       	call   15766 <install_isr>
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
   118e6:	e8 86 25 00 00       	call   13e71 <pcb_queue_length>
   118eb:	83 c4 10             	add    $0x10,%esp
   118ee:	89 45 d4             	mov    %eax,-0x2c(%ebp)
   118f1:	a1 18 20 02 00       	mov    0x22018,%eax
   118f6:	83 ec 0c             	sub    $0xc,%esp
   118f9:	50                   	push   %eax
   118fa:	e8 72 25 00 00       	call   13e71 <pcb_queue_length>
   118ff:	83 c4 10             	add    $0x10,%esp
   11902:	89 c7                	mov    %eax,%edi
   11904:	a1 08 20 02 00       	mov    0x22008,%eax
   11909:	83 ec 0c             	sub    $0xc,%esp
   1190c:	50                   	push   %eax
   1190d:	e8 5f 25 00 00       	call   13e71 <pcb_queue_length>
   11912:	83 c4 10             	add    $0x10,%esp
   11915:	89 c6                	mov    %eax,%esi
   11917:	a1 10 20 02 00       	mov    0x22010,%eax
   1191c:	83 ec 0c             	sub    $0xc,%esp
   1191f:	50                   	push   %eax
   11920:	e8 4c 25 00 00       	call   13e71 <pcb_queue_length>
   11925:	83 c4 10             	add    $0x10,%esp
   11928:	89 c3                	mov    %eax,%ebx
   1192a:	a1 d0 24 02 00       	mov    0x224d0,%eax
   1192f:	83 ec 0c             	sub    $0xc,%esp
   11932:	50                   	push   %eax
   11933:	e8 39 25 00 00       	call   13e71 <pcb_queue_length>
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
   11969:	e8 b0 24 00 00       	call   13e1e <pcb_queue_empty>
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
   11982:	e8 ca 29 00 00       	call   14351 <pcb_queue_peek>
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
   119b4:	e8 2e 0d 00 00       	call   126e7 <sprint>
   119b9:	83 c4 20             	add    $0x20,%esp
   119bc:	83 ec 0c             	sub    $0xc,%esp
   119bf:	68 00 00 02 00       	push   $0x20000
   119c4:	e8 9e 0a 00 00       	call   12467 <kpanic>
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
   119e8:	e8 cf 26 00 00       	call   140bc <pcb_queue_remove>
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
   11a14:	e8 ce 0c 00 00       	call   126e7 <sprint>
   11a19:	83 c4 20             	add    $0x20,%esp
   11a1c:	83 ec 0c             	sub    $0xc,%esp
   11a1f:	68 00 00 02 00       	push   $0x20000
   11a24:	e8 3e 0a 00 00       	call   12467 <kpanic>
   11a29:	83 c4 10             	add    $0x10,%esp
		schedule( tmp );
   11a2c:	8b 45 dc             	mov    -0x24(%ebp),%eax
   11a2f:	83 ec 0c             	sub    $0xc,%esp
   11a32:	50                   	push   %eax
   11a33:	e8 77 29 00 00       	call   143af <schedule>
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
   11a6c:	e8 3e 29 00 00       	call   143af <schedule>
   11a71:	83 c4 10             	add    $0x10,%esp
		current = NULL;
   11a74:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   11a7b:	00 00 00 
		// and pick a new process
		dispatch();
   11a7e:	e8 ed 29 00 00       	call   14470 <dispatch>
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
   11b2a:	e8 37 3c 00 00       	call   15766 <install_isr>
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
static void kreport(bool_t dtrace) {
   11b35:	55                   	push   %ebp
   11b36:	89 e5                	mov    %esp,%ebp
   11b38:	83 ec 18             	sub    $0x18,%esp
   11b3b:	8b 45 08             	mov    0x8(%ebp),%eax
   11b3e:	88 45 f4             	mov    %al,-0xc(%ebp)

  cio_puts("\n-------------------------------\n");
   11b41:	83 ec 0c             	sub    $0xc,%esp
   11b44:	68 00 aa 01 00       	push   $0x1aa00
   11b49:	e8 5f f3 ff ff       	call   10ead <cio_puts>
   11b4e:	83 c4 10             	add    $0x10,%esp
  cio_printf("Config:  N_PROCS = %d", N_PROCS);
   11b51:	83 ec 08             	sub    $0x8,%esp
   11b54:	6a 19                	push   $0x19
   11b56:	68 22 aa 01 00       	push   $0x1aa22
   11b5b:	e8 c7 f9 ff ff       	call   11527 <cio_printf>
   11b60:	83 c4 10             	add    $0x10,%esp
  cio_printf(" N_PRIOS = %d", N_PRIOS);
   11b63:	83 ec 08             	sub    $0x8,%esp
   11b66:	6a 04                	push   $0x4
   11b68:	68 38 aa 01 00       	push   $0x1aa38
   11b6d:	e8 b5 f9 ff ff       	call   11527 <cio_printf>
   11b72:	83 c4 10             	add    $0x10,%esp
  cio_printf(" N_STATES = %d", N_STATES);
   11b75:	83 ec 08             	sub    $0x8,%esp
   11b78:	6a 09                	push   $0x9
   11b7a:	68 46 aa 01 00       	push   $0x1aa46
   11b7f:	e8 a3 f9 ff ff       	call   11527 <cio_printf>
   11b84:	83 c4 10             	add    $0x10,%esp
  cio_printf(" CLOCK = %dHz\n", CLOCK_FREQ);
   11b87:	83 ec 08             	sub    $0x8,%esp
   11b8a:	68 e8 03 00 00       	push   $0x3e8
   11b8f:	68 55 aa 01 00       	push   $0x1aa55
   11b94:	e8 8e f9 ff ff       	call   11527 <cio_printf>
   11b99:	83 c4 10             	add    $0x10,%esp

  // This code is ugly, but it's the simplest way to
  // print out the values of compile-time options
  // without spending a lot of execution time at it.

  cio_puts("Options: "
   11b9c:	83 ec 0c             	sub    $0xc,%esp
   11b9f:	68 64 aa 01 00       	push   $0x1aa64
   11ba4:	e8 04 f3 ff ff       	call   10ead <cio_puts>
   11ba9:	83 c4 10             	add    $0x10,%esp
           " Cstats"
#endif
  ); // end of cio_puts() call

#ifdef SANITY
  cio_printf(" SANITY = %d", SANITY);
   11bac:	83 ec 08             	sub    $0x8,%esp
   11baf:	68 0f 27 00 00       	push   $0x270f
   11bb4:	68 7f aa 01 00       	push   $0x1aa7f
   11bb9:	e8 69 f9 ff ff       	call   11527 <cio_printf>
   11bbe:	83 c4 10             	add    $0x10,%esp
#ifdef STATUS
  cio_printf(" STATUS = %d", STATUS);
#endif

#if TRACE > 0
  cio_printf(" TRACE = 0x%04x\n", TRACE);
   11bc1:	83 ec 08             	sub    $0x8,%esp
   11bc4:	68 00 01 00 00       	push   $0x100
   11bc9:	68 8c aa 01 00       	push   $0x1aa8c
   11bce:	e8 54 f9 ff ff       	call   11527 <cio_printf>
   11bd3:	83 c4 10             	add    $0x10,%esp

  // decode the trace settings if that was requested
  if (TRACING_SOMETHING && dtrace) {
   11bd6:	80 7d f4 00          	cmpb   $0x0,-0xc(%ebp)
   11bda:	74 10                	je     11bec <kreport+0xb7>

    // this one is simpler - we rely on string literal
    // concatenation in the C compiler to create one
    // long string to print out

    cio_puts("Tracing:"
   11bdc:	83 ec 0c             	sub    $0xc,%esp
   11bdf:	68 9d aa 01 00       	push   $0x1aa9d
   11be4:	e8 c4 f2 ff ff       	call   10ead <cio_puts>
   11be9:	83 c4 10             	add    $0x10,%esp
#endif
    ); // end of cio_puts() call
  }
#endif /* TRACE > 0 */

  cio_putchar('\n');
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
static void stats(int code) {
   11bfc:	55                   	push   %ebp
   11bfd:	89 e5                	mov    %esp,%ebp
   11bff:	83 ec 08             	sub    $0x8,%esp

  switch (code) {
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

  case 'a': // dump the active table
    ptable_dump("\nActive processes", false);
   11c56:	83 ec 08             	sub    $0x8,%esp
   11c59:	6a 00                	push   $0x0
   11c5b:	68 ab aa 01 00       	push   $0x1aaab
   11c60:	e8 9b 2c 00 00       	call   14900 <ptable_dump>
   11c65:	83 c4 10             	add    $0x10,%esp
    break;
   11c68:	e9 db 00 00 00       	jmp    11d48 <stats+0x14c>

  case 'c': // dump context info for all active PCBs
    ctx_dump_all("\nContext dump");
   11c6d:	83 ec 0c             	sub    $0xc,%esp
   11c70:	68 bd aa 01 00       	push   $0x1aabd
   11c75:	e8 bf 29 00 00       	call   14639 <ctx_dump_all>
   11c7a:	83 c4 10             	add    $0x10,%esp
    break;
   11c7d:	e9 c6 00 00 00       	jmp    11d48 <stats+0x14c>

  case 'p': // dump the active table and all PCBs
    ptable_dump("\nActive processes", true);
   11c82:	83 ec 08             	sub    $0x8,%esp
   11c85:	6a 01                	push   $0x1
   11c87:	68 ab aa 01 00       	push   $0x1aaab
   11c8c:	e8 6f 2c 00 00       	call   14900 <ptable_dump>
   11c91:	83 c4 10             	add    $0x10,%esp
    break;
   11c94:	e9 af 00 00 00       	jmp    11d48 <stats+0x14c>

  case 'q': // dump the queues
    // code to dump out any/all queues
    pcb_queue_dump("R", ready, true);
   11c99:	a1 d0 24 02 00       	mov    0x224d0,%eax
   11c9e:	83 ec 04             	sub    $0x4,%esp
   11ca1:	6a 01                	push   $0x1
   11ca3:	50                   	push   %eax
   11ca4:	68 cb aa 01 00       	push   $0x1aacb
   11ca9:	e8 3f 2b 00 00       	call   147ed <pcb_queue_dump>
   11cae:	83 c4 10             	add    $0x10,%esp
    pcb_queue_dump("W", waiting, true);
   11cb1:	a1 10 20 02 00       	mov    0x22010,%eax
   11cb6:	83 ec 04             	sub    $0x4,%esp
   11cb9:	6a 01                	push   $0x1
   11cbb:	50                   	push   %eax
   11cbc:	68 cd aa 01 00       	push   $0x1aacd
   11cc1:	e8 27 2b 00 00       	call   147ed <pcb_queue_dump>
   11cc6:	83 c4 10             	add    $0x10,%esp
    pcb_queue_dump("S", sleeping, true);
   11cc9:	a1 08 20 02 00       	mov    0x22008,%eax
   11cce:	83 ec 04             	sub    $0x4,%esp
   11cd1:	6a 01                	push   $0x1
   11cd3:	50                   	push   %eax
   11cd4:	68 cf aa 01 00       	push   $0x1aacf
   11cd9:	e8 0f 2b 00 00       	call   147ed <pcb_queue_dump>
   11cde:	83 c4 10             	add    $0x10,%esp
    pcb_queue_dump("Z", zombie, true);
   11ce1:	a1 18 20 02 00       	mov    0x22018,%eax
   11ce6:	83 ec 04             	sub    $0x4,%esp
   11ce9:	6a 01                	push   $0x1
   11ceb:	50                   	push   %eax
   11cec:	68 d1 aa 01 00       	push   $0x1aad1
   11cf1:	e8 f7 2a 00 00       	call   147ed <pcb_queue_dump>
   11cf6:	83 c4 10             	add    $0x10,%esp
    pcb_queue_dump("I", sioread, true);
   11cf9:	a1 04 20 02 00       	mov    0x22004,%eax
   11cfe:	83 ec 04             	sub    $0x4,%esp
   11d01:	6a 01                	push   $0x1
   11d03:	50                   	push   %eax
   11d04:	68 d3 aa 01 00       	push   $0x1aad3
   11d09:	e8 df 2a 00 00       	call   147ed <pcb_queue_dump>
   11d0e:	83 c4 10             	add    $0x10,%esp
    break;
   11d11:	eb 35                	jmp    11d48 <stats+0x14c>

  case 'r': // print system configuration information
    kreport(true);
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
    cio_printf("console: unknown request '0x%02x'\n", code);
   11d22:	83 ec 08             	sub    $0x8,%esp
   11d25:	ff 75 08             	pushl  0x8(%ebp)
   11d28:	68 d8 aa 01 00       	push   $0x1aad8
   11d2d:	e8 f5 f7 ff ff       	call   11527 <cio_printf>
   11d32:	83 c4 10             	add    $0x10,%esp
    // FALL THROUGH

  case 'h': // help message
    cio_puts("\nCommands:\n"
   11d35:	83 ec 0c             	sub    $0xc,%esp
   11d38:	68 fc aa 01 00       	push   $0x1aafc
   11d3d:	e8 6b f1 ff ff       	call   10ead <cio_puts>
   11d42:	83 c4 10             	add    $0x10,%esp
             "  c -- dump contexts for active processes\n"
             "  h -- this message\n"
             "  p -- dump the active table and all PCBs\n"
             "  q -- dump the queues\n"
             "  r -- print system configuration\n");
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
int main(void) {
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

  init_interrupts(); // IDT and PIC initialization
   11d5d:	e8 f1 39 00 00       	call   15753 <init_interrupts>
  ** initialize it before we initialize the kernel memory
  ** and queue modules.
  */

#if defined(CONSOLE_STATS)
  cio_init(stats);
   11d62:	83 ec 0c             	sub    $0xc,%esp
   11d65:	68 fc 1b 01 00       	push   $0x11bfc
   11d6a:	e8 67 fa ff ff       	call   117d6 <cio_init>
   11d6f:	83 c4 10             	add    $0x10,%esp
#else
  cio_init(NULL); // no console callback routine
#endif

  cio_clearscreen(); // wipe out whatever is there
   11d72:	e8 18 f2 ff ff       	call   10f8f <cio_clearscreen>
  **
  ** Other modules (clock, SIO, syscall, etc.) are expected to
  ** install their own ISRs in their initialization routines.
  */

  cio_puts("System initialization starting.\n");
   11d77:	83 ec 0c             	sub    $0xc,%esp
   11d7a:	68 c8 ab 01 00       	push   $0x1abc8
   11d7f:	e8 29 f1 ff ff       	call   10ead <cio_puts>
   11d84:	83 c4 10             	add    $0x10,%esp
  cio_puts("-------------------------------\n");
   11d87:	83 ec 0c             	sub    $0xc,%esp
   11d8a:	68 ec ab 01 00       	push   $0x1abec
   11d8f:	e8 19 f1 ff ff       	call   10ead <cio_puts>
   11d94:	83 c4 10             	add    $0x10,%esp

#if TRACING_INIT
  cio_puts("Modules:");
   11d97:	83 ec 0c             	sub    $0xc,%esp
   11d9a:	68 0d ac 01 00       	push   $0x1ac0d
   11d9f:	e8 09 f1 ff ff       	call   10ead <cio_puts>
   11da4:	83 c4 10             	add    $0x10,%esp
#endif

  // call the module initialization functions, being
  // careful to follow any module precedence requirements

  km_init(); // MUST BE FIRST
   11da7:	e8 e4 0d 00 00       	call   12b90 <km_init>

  // other module initialization calls here
  clk_init();  // clock
   11dac:	e8 ee fc ff ff       	call   11a9f <clk_init>
  pcb_init();  // process (PCBs, queues, scheduler)
   11db1:	e8 0f 18 00 00       	call   135c5 <pcb_init>
  sio_init();  // serial i/o
   11db6:	e8 1e 30 00 00       	call   14dd9 <sio_init>
  sys_init();  // system call
   11dbb:	e8 9f 4c 00 00       	call   16a5f <sys_init>
  user_init(); // user code handling
   11dc0:	e8 7c 4f 00 00       	call   16d41 <user_init>
  intel_8255x_init();
   11dc5:	e8 31 51 00 00       	call   16efb <intel_8255x_init>
  cio_puts("\nModule initialization complete.\n");
   11dca:	83 ec 0c             	sub    $0xc,%esp
   11dcd:	68 18 ac 01 00       	push   $0x1ac18
   11dd2:	e8 d6 f0 ff ff       	call   10ead <cio_puts>
   11dd7:	83 c4 10             	add    $0x10,%esp

#if TRACING_INIT
  // report our configuration options
  kreport(true);
   11dda:	83 ec 0c             	sub    $0xc,%esp
   11ddd:	6a 01                	push   $0x1
   11ddf:	e8 51 fd ff ff       	call   11b35 <kreport>
   11de4:	83 c4 10             	add    $0x10,%esp
#endif
  cio_puts("-------------------------------\n");
   11de7:	83 ec 0c             	sub    $0xc,%esp
   11dea:	68 ec ab 01 00       	push   $0x1abec
   11def:	e8 b9 f0 ff ff       	call   10ead <cio_puts>
   11df4:	83 c4 10             	add    $0x10,%esp
  ** This code is largely stolen from the fork() and exec()
  ** implementations in syscalls.c; if those change, this must
  ** also change.
  */

  cio_puts("Creating initial user process...");
   11df7:	83 ec 0c             	sub    $0xc,%esp
   11dfa:	68 3c ac 01 00       	push   $0x1ac3c
   11dff:	e8 a9 f0 ff ff       	call   10ead <cio_puts>
   11e04:	83 c4 10             	add    $0x10,%esp

  // if we can't get a PCB, there's no use continuing!
  assert(pcb_alloc(&init_pcb) == SUCCESS);
   11e07:	83 ec 0c             	sub    $0xc,%esp
   11e0a:	68 0c 20 02 00       	push   $0x2200c
   11e0f:	e8 32 1a 00 00       	call   13846 <pcb_alloc>
   11e14:	83 c4 10             	add    $0x10,%esp
   11e17:	85 c0                	test   %eax,%eax
   11e19:	74 3b                	je     11e56 <main+0x10b>
   11e1b:	83 ec 04             	sub    $0x4,%esp
   11e1e:	68 5d ac 01 00       	push   $0x1ac5d
   11e23:	6a 00                	push   $0x0
   11e25:	68 52 01 00 00       	push   $0x152
   11e2a:	68 79 ac 01 00       	push   $0x1ac79
   11e2f:	68 a0 ad 01 00       	push   $0x1ada0
   11e34:	68 82 ac 01 00       	push   $0x1ac82
   11e39:	68 00 00 02 00       	push   $0x20000
   11e3e:	e8 a4 08 00 00       	call   126e7 <sprint>
   11e43:	83 c4 20             	add    $0x20,%esp
   11e46:	83 ec 0c             	sub    $0xc,%esp
   11e49:	68 00 00 02 00       	push   $0x20000
   11e4e:	e8 14 06 00 00       	call   12467 <kpanic>
   11e53:	83 c4 10             	add    $0x10,%esp

  // fill in the necessary details
  init_pcb->pid = PID_INIT;
   11e56:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11e5b:	c7 40 18 01 00 00 00 	movl   $0x1,0x18(%eax)
  init_pcb->state = STATE_NEW;
   11e62:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11e67:	c7 40 1c 01 00 00 00 	movl   $0x1,0x1c(%eax)
  init_pcb->priority = PRIO_HIGH;
   11e6e:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11e73:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // command-line arguments for 'init'
  const char *args[3] = {"init", "+", NULL};
   11e7a:	c7 45 ec 98 ac 01 00 	movl   $0x1ac98,-0x14(%ebp)
   11e81:	c7 45 f0 9d ac 01 00 	movl   $0x1ac9d,-0x10(%ebp)
   11e88:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  // the entry point for 'init'
  extern int init(int, char **);

  // allocate a default-sized stack
  init_pcb->stack = pcb_stack_alloc(N_USTKPAGES);
   11e8f:	8b 1d 0c 20 02 00    	mov    0x2200c,%ebx
   11e95:	83 ec 0c             	sub    $0xc,%esp
   11e98:	6a 02                	push   $0x2
   11e9a:	e8 a7 1a 00 00       	call   13946 <pcb_stack_alloc>
   11e9f:	83 c4 10             	add    $0x10,%esp
   11ea2:	89 43 04             	mov    %eax,0x4(%ebx)
  assert(init_pcb->stack != NULL);
   11ea5:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11eaa:	8b 40 04             	mov    0x4(%eax),%eax
   11ead:	85 c0                	test   %eax,%eax
   11eaf:	75 3b                	jne    11eec <main+0x1a1>
   11eb1:	83 ec 04             	sub    $0x4,%esp
   11eb4:	68 9f ac 01 00       	push   $0x1ac9f
   11eb9:	6a 00                	push   $0x0
   11ebb:	68 61 01 00 00       	push   $0x161
   11ec0:	68 79 ac 01 00       	push   $0x1ac79
   11ec5:	68 a0 ad 01 00       	push   $0x1ada0
   11eca:	68 82 ac 01 00       	push   $0x1ac82
   11ecf:	68 00 00 02 00       	push   $0x20000
   11ed4:	e8 0e 08 00 00       	call   126e7 <sprint>
   11ed9:	83 c4 20             	add    $0x20,%esp
   11edc:	83 ec 0c             	sub    $0xc,%esp
   11edf:	68 00 00 02 00       	push   $0x20000
   11ee4:	e8 7e 05 00 00       	call   12467 <kpanic>
   11ee9:	83 c4 10             	add    $0x10,%esp
  // remember that we used the default size
  init_pcb->stkpgs = N_USTKPAGES;
   11eec:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11ef1:	c7 40 28 02 00 00 00 	movl   $0x2,0x28(%eax)

  // initialize the stack and the context to be restored
  init_pcb->context = stack_setup(init_pcb, (uint32_t)init, args, true);
   11ef8:	b9 c2 74 01 00       	mov    $0x174c2,%ecx
   11efd:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11f02:	8b 1d 0c 20 02 00    	mov    0x2200c,%ebx
   11f08:	6a 01                	push   $0x1
   11f0a:	8d 55 ec             	lea    -0x14(%ebp),%edx
   11f0d:	52                   	push   %edx
   11f0e:	51                   	push   %ecx
   11f0f:	50                   	push   %eax
   11f10:	e8 78 4b 00 00       	call   16a8d <stack_setup>
   11f15:	83 c4 10             	add    $0x10,%esp
   11f18:	89 03                	mov    %eax,(%ebx)
  assert(init_pcb->context != NULL);
   11f1a:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11f1f:	8b 00                	mov    (%eax),%eax
   11f21:	85 c0                	test   %eax,%eax
   11f23:	75 3b                	jne    11f60 <main+0x215>
   11f25:	83 ec 04             	sub    $0x4,%esp
   11f28:	68 b4 ac 01 00       	push   $0x1acb4
   11f2d:	6a 00                	push   $0x0
   11f2f:	68 67 01 00 00       	push   $0x167
   11f34:	68 79 ac 01 00       	push   $0x1ac79
   11f39:	68 a0 ad 01 00       	push   $0x1ada0
   11f3e:	68 82 ac 01 00       	push   $0x1ac82
   11f43:	68 00 00 02 00       	push   $0x20000
   11f48:	e8 9a 07 00 00       	call   126e7 <sprint>
   11f4d:	83 c4 20             	add    $0x20,%esp
   11f50:	83 ec 0c             	sub    $0xc,%esp
   11f53:	68 00 00 02 00       	push   $0x20000
   11f58:	e8 0a 05 00 00       	call   12467 <kpanic>
   11f5d:	83 c4 10             	add    $0x10,%esp

  // "i'm my own grandpa...."
  init_pcb->parent = init_pcb;
   11f60:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11f65:	8b 15 0c 20 02 00    	mov    0x2200c,%edx
   11f6b:	89 50 0c             	mov    %edx,0xc(%eax)

  // send it on its merry way
  schedule(init_pcb);
   11f6e:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11f73:	83 ec 0c             	sub    $0xc,%esp
   11f76:	50                   	push   %eax
   11f77:	e8 33 24 00 00       	call   143af <schedule>
   11f7c:	83 c4 10             	add    $0x10,%esp

  // make sure there's no current process
  current = NULL;
   11f7f:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   11f86:	00 00 00 

  // pick a winner
  dispatch();
   11f89:	e8 e2 24 00 00       	call   14470 <dispatch>

  cio_puts(" done.\n");
   11f8e:	83 ec 0c             	sub    $0xc,%esp
   11f91:	68 cb ac 01 00       	push   $0x1accb
   11f96:	e8 12 ef ff ff       	call   10ead <cio_puts>
   11f9b:	83 c4 10             	add    $0x10,%esp

  delay(DELAY_1_SEC);
   11f9e:	83 ec 0c             	sub    $0xc,%esp
   11fa1:	6a 28                	push   $0x28
   11fa3:	e8 e3 37 00 00       	call   1578b <delay>
   11fa8:	83 c4 10             	add    $0x10,%esp

#ifdef TRACE_CX

  // wipe out whatever is on the screen at the moment
  cio_clearscreen();
   11fab:	e8 df ef ff ff       	call   10f8f <cio_clearscreen>

  // define a scrolling region in the top 7 lines of the screen
  cio_setscroll(0, 7, 99, 99);
   11fb0:	6a 63                	push   $0x63
   11fb2:	6a 63                	push   $0x63
   11fb4:	6a 07                	push   $0x7
   11fb6:	6a 00                	push   $0x0
   11fb8:	e8 36 ec ff ff       	call   10bf3 <cio_setscroll>
   11fbd:	83 c4 10             	add    $0x10,%esp

  // clear it
  cio_clearscroll();
   11fc0:	e8 51 ef ff ff       	call   10f16 <cio_clearscroll>

  // clear the top line
  cio_puts_at(0, 0,
   11fc5:	83 ec 04             	sub    $0x4,%esp
   11fc8:	68 d4 ac 01 00       	push   $0x1acd4
   11fcd:	6a 00                	push   $0x0
   11fcf:	6a 00                	push   $0x0
   11fd1:	e8 95 ee ff ff       	call   10e6b <cio_puts_at>
   11fd6:	83 c4 10             	add    $0x10,%esp
              "*                                                               "
              "                ");
  // separator
  cio_puts_at(0, 6,
   11fd9:	83 ec 04             	sub    $0x4,%esp
   11fdc:	68 28 ad 01 00       	push   $0x1ad28
   11fe1:	6a 06                	push   $0x6
   11fe3:	6a 00                	push   $0x0
   11fe5:	e8 81 ee ff ff       	call   10e6b <cio_puts_at>
   11fea:	83 c4 10             	add    $0x10,%esp

  /*
  ** END OF TERM-SPECIFIC CODE
  */

  sio_flush(SIO_RX | SIO_TX);
   11fed:	83 ec 0c             	sub    $0xc,%esp
   11ff0:	6a 03                	push   $0x3
   11ff2:	e8 45 30 00 00       	call   1503c <sio_flush>
   11ff7:	83 c4 10             	add    $0x10,%esp
  sio_enable(SIO_RX);
   11ffa:	83 ec 0c             	sub    $0xc,%esp
   11ffd:	6a 02                	push   $0x2
   11fff:	e8 48 2f 00 00       	call   14f4c <sio_enable>
   12004:	83 c4 10             	add    $0x10,%esp

  cio_puts("System initialization complete.\n");
   12007:	83 ec 0c             	sub    $0xc,%esp
   1200a:	68 7c ad 01 00       	push   $0x1ad7c
   1200f:	e8 99 ee ff ff       	call   10ead <cio_puts>
   12014:	83 c4 10             	add    $0x10,%esp
  cio_puts("-------------------------------\n");
   12017:	83 ec 0c             	sub    $0xc,%esp
   1201a:	68 ec ab 01 00       	push   $0x1abec
   1201f:	e8 89 ee ff ff       	call   10ead <cio_puts>
   12024:	83 c4 10             	add    $0x10,%esp
	pcb_dump( "Current: ", current, true );

	delay( DELAY_2_SEC );
#endif

  return 0;
   12027:	b8 00 00 00 00       	mov    $0x0,%eax
}
   1202c:	8d 65 f8             	lea    -0x8(%ebp),%esp
   1202f:	59                   	pop    %ecx
   12030:	5b                   	pop    %ebx
   12031:	5d                   	pop    %ebp
   12032:	8d 61 fc             	lea    -0x4(%ecx),%esp
   12035:	c3                   	ret    

00012036 <blkmov>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void blkmov( void *dst, const void *src, register uint32_t len ) {
   12036:	55                   	push   %ebp
   12037:	89 e5                	mov    %esp,%ebp
   12039:	56                   	push   %esi
   1203a:	53                   	push   %ebx
   1203b:	8b 45 10             	mov    0x10(%ebp),%eax

	// verify that the addresses are aligned and
	// the length is a multiple of four bytes
	if( (((uint32_t)dst)&0x3) != 0 ||
   1203e:	8b 55 08             	mov    0x8(%ebp),%edx
   12041:	83 e2 03             	and    $0x3,%edx
   12044:	85 d2                	test   %edx,%edx
   12046:	75 13                	jne    1205b <blkmov+0x25>
		(((uint32_t)src)&0x3) != 0 ||
   12048:	8b 55 0c             	mov    0xc(%ebp),%edx
   1204b:	83 e2 03             	and    $0x3,%edx
	if( (((uint32_t)dst)&0x3) != 0 ||
   1204e:	85 d2                	test   %edx,%edx
   12050:	75 09                	jne    1205b <blkmov+0x25>
		(len & 0x3) != 0 ) {
   12052:	89 c2                	mov    %eax,%edx
   12054:	83 e2 03             	and    $0x3,%edx
		(((uint32_t)src)&0x3) != 0 ||
   12057:	85 d2                	test   %edx,%edx
   12059:	74 14                	je     1206f <blkmov+0x39>
		// something isn't aligned, so just use memmove()
		memmove( dst, src, len );
   1205b:	83 ec 04             	sub    $0x4,%esp
   1205e:	50                   	push   %eax
   1205f:	ff 75 0c             	pushl  0xc(%ebp)
   12062:	ff 75 08             	pushl  0x8(%ebp)
   12065:	e8 48 05 00 00       	call   125b2 <memmove>
   1206a:	83 c4 10             	add    $0x10,%esp
		return;
   1206d:	eb 5a                	jmp    120c9 <blkmov+0x93>
	}

	// everything is nicely aligned, so off we go
	register uint32_t *dest = dst;
   1206f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint32_t *source = src;
   12072:	8b 75 0c             	mov    0xc(%ebp),%esi

	// now copying 32-bit values
	len /= 4;
   12075:	c1 e8 02             	shr    $0x2,%eax

	if( source < dest && (source + len) > dest ) {
   12078:	39 de                	cmp    %ebx,%esi
   1207a:	73 44                	jae    120c0 <blkmov+0x8a>
   1207c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   12083:	01 f2                	add    %esi,%edx
   12085:	39 d3                	cmp    %edx,%ebx
   12087:	73 37                	jae    120c0 <blkmov+0x8a>
		source += len;
   12089:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   12090:	01 d6                	add    %edx,%esi
		dest += len;
   12092:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   12099:	01 d3                	add    %edx,%ebx
		while( len-- > 0 ) {
   1209b:	eb 0a                	jmp    120a7 <blkmov+0x71>
			*--dest = *--source;
   1209d:	83 ee 04             	sub    $0x4,%esi
   120a0:	83 eb 04             	sub    $0x4,%ebx
   120a3:	8b 16                	mov    (%esi),%edx
   120a5:	89 13                	mov    %edx,(%ebx)
		while( len-- > 0 ) {
   120a7:	89 c2                	mov    %eax,%edx
   120a9:	8d 42 ff             	lea    -0x1(%edx),%eax
   120ac:	85 d2                	test   %edx,%edx
   120ae:	75 ed                	jne    1209d <blkmov+0x67>
	if( source < dest && (source + len) > dest ) {
   120b0:	eb 17                	jmp    120c9 <blkmov+0x93>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   120b2:	89 f1                	mov    %esi,%ecx
   120b4:	8d 71 04             	lea    0x4(%ecx),%esi
   120b7:	89 da                	mov    %ebx,%edx
   120b9:	8d 5a 04             	lea    0x4(%edx),%ebx
   120bc:	8b 09                	mov    (%ecx),%ecx
   120be:	89 0a                	mov    %ecx,(%edx)
		while( len-- ) {
   120c0:	89 c2                	mov    %eax,%edx
   120c2:	8d 42 ff             	lea    -0x1(%edx),%eax
   120c5:	85 d2                	test   %edx,%edx
   120c7:	75 e9                	jne    120b2 <blkmov+0x7c>
		}
	}
}
   120c9:	8d 65 f8             	lea    -0x8(%ebp),%esp
   120cc:	5b                   	pop    %ebx
   120cd:	5e                   	pop    %esi
   120ce:	5d                   	pop    %ebp
   120cf:	c3                   	ret    

000120d0 <bound>:
** @param value  Value to be constrained
** @param max    Upper bound
**
** @return The constrained value
*/
uint32_t bound( uint32_t min, uint32_t value, uint32_t max ) {
   120d0:	55                   	push   %ebp
   120d1:	89 e5                	mov    %esp,%ebp
	if( value < min ){
   120d3:	8b 45 0c             	mov    0xc(%ebp),%eax
   120d6:	3b 45 08             	cmp    0x8(%ebp),%eax
   120d9:	73 06                	jae    120e1 <bound+0x11>
		value = min;
   120db:	8b 45 08             	mov    0x8(%ebp),%eax
   120de:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	if( value > max ){
   120e1:	8b 45 0c             	mov    0xc(%ebp),%eax
   120e4:	3b 45 10             	cmp    0x10(%ebp),%eax
   120e7:	76 06                	jbe    120ef <bound+0x1f>
		value = max;
   120e9:	8b 45 10             	mov    0x10(%ebp),%eax
   120ec:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	return value;
   120ef:	8b 45 0c             	mov    0xc(%ebp),%eax
}
   120f2:	5d                   	pop    %ebp
   120f3:	c3                   	ret    

000120f4 <cvtdec>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtdec( char *buf, int32_t value ) {
   120f4:	55                   	push   %ebp
   120f5:	89 e5                	mov    %esp,%ebp
   120f7:	83 ec 18             	sub    $0x18,%esp
	char *bp = buf;
   120fa:	8b 45 08             	mov    0x8(%ebp),%eax
   120fd:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if( value < 0 ) {
   12100:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   12104:	79 0f                	jns    12115 <cvtdec+0x21>
		*bp++ = '-';
   12106:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12109:	8d 50 01             	lea    0x1(%eax),%edx
   1210c:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1210f:	c6 00 2d             	movb   $0x2d,(%eax)
		value = -value;
   12112:	f7 5d 0c             	negl   0xc(%ebp)
	}

	bp = cvtdec0( bp, value );
   12115:	83 ec 08             	sub    $0x8,%esp
   12118:	ff 75 0c             	pushl  0xc(%ebp)
   1211b:	ff 75 f4             	pushl  -0xc(%ebp)
   1211e:	e8 18 00 00 00       	call   1213b <cvtdec0>
   12123:	83 c4 10             	add    $0x10,%esp
   12126:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp  = '\0';
   12129:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1212c:	c6 00 00             	movb   $0x0,(%eax)

	return( bp - buf );
   1212f:	8b 55 f4             	mov    -0xc(%ebp),%edx
   12132:	8b 45 08             	mov    0x8(%ebp),%eax
   12135:	29 c2                	sub    %eax,%edx
   12137:	89 d0                	mov    %edx,%eax
}
   12139:	c9                   	leave  
   1213a:	c3                   	ret    

0001213b <cvtdec0>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *cvtdec0( char *buf, int value ) {
   1213b:	55                   	push   %ebp
   1213c:	89 e5                	mov    %esp,%ebp
   1213e:	83 ec 18             	sub    $0x18,%esp
	int quotient;

	quotient = value / 10;
   12141:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   12144:	ba 67 66 66 66       	mov    $0x66666667,%edx
   12149:	89 c8                	mov    %ecx,%eax
   1214b:	f7 ea                	imul   %edx
   1214d:	c1 fa 02             	sar    $0x2,%edx
   12150:	89 c8                	mov    %ecx,%eax
   12152:	c1 f8 1f             	sar    $0x1f,%eax
   12155:	29 c2                	sub    %eax,%edx
   12157:	89 d0                	mov    %edx,%eax
   12159:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient < 0 ) {
   1215c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12160:	79 0e                	jns    12170 <cvtdec0+0x35>
		quotient = 214748364;
   12162:	c7 45 f4 cc cc cc 0c 	movl   $0xccccccc,-0xc(%ebp)
		value = 8;
   12169:	c7 45 0c 08 00 00 00 	movl   $0x8,0xc(%ebp)
	}
	if( quotient != 0 ) {
   12170:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12174:	74 14                	je     1218a <cvtdec0+0x4f>
		buf = cvtdec0( buf, quotient );
   12176:	83 ec 08             	sub    $0x8,%esp
   12179:	ff 75 f4             	pushl  -0xc(%ebp)
   1217c:	ff 75 08             	pushl  0x8(%ebp)
   1217f:	e8 b7 ff ff ff       	call   1213b <cvtdec0>
   12184:	83 c4 10             	add    $0x10,%esp
   12187:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   1218a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   1218d:	ba 67 66 66 66       	mov    $0x66666667,%edx
   12192:	89 c8                	mov    %ecx,%eax
   12194:	f7 ea                	imul   %edx
   12196:	c1 fa 02             	sar    $0x2,%edx
   12199:	89 c8                	mov    %ecx,%eax
   1219b:	c1 f8 1f             	sar    $0x1f,%eax
   1219e:	29 c2                	sub    %eax,%edx
   121a0:	89 d0                	mov    %edx,%eax
   121a2:	c1 e0 02             	shl    $0x2,%eax
   121a5:	01 d0                	add    %edx,%eax
   121a7:	01 c0                	add    %eax,%eax
   121a9:	29 c1                	sub    %eax,%ecx
   121ab:	89 ca                	mov    %ecx,%edx
   121ad:	89 d0                	mov    %edx,%eax
   121af:	8d 48 30             	lea    0x30(%eax),%ecx
   121b2:	8b 45 08             	mov    0x8(%ebp),%eax
   121b5:	8d 50 01             	lea    0x1(%eax),%edx
   121b8:	89 55 08             	mov    %edx,0x8(%ebp)
   121bb:	89 ca                	mov    %ecx,%edx
   121bd:	88 10                	mov    %dl,(%eax)
	return buf;
   121bf:	8b 45 08             	mov    0x8(%ebp),%eax
}
   121c2:	c9                   	leave  
   121c3:	c3                   	ret    

000121c4 <cvthex>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvthex( char *buf, uint32_t value ) {
   121c4:	55                   	push   %ebp
   121c5:	89 e5                	mov    %esp,%ebp
   121c7:	83 ec 20             	sub    $0x20,%esp
	const char hexdigits[] = "0123456789ABCDEF";
   121ca:	c7 45 e3 30 31 32 33 	movl   $0x33323130,-0x1d(%ebp)
   121d1:	c7 45 e7 34 35 36 37 	movl   $0x37363534,-0x19(%ebp)
   121d8:	c7 45 eb 38 39 41 42 	movl   $0x42413938,-0x15(%ebp)
   121df:	c7 45 ef 43 44 45 46 	movl   $0x46454443,-0x11(%ebp)
   121e6:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)
	int chars_stored = 0;
   121ea:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)

	for( int i = 0; i < 8; i += 1 ) {
   121f1:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
   121f8:	eb 43                	jmp    1223d <cvthex+0x79>
		uint32_t val = value & 0xf0000000;
   121fa:	8b 45 0c             	mov    0xc(%ebp),%eax
   121fd:	25 00 00 00 f0       	and    $0xf0000000,%eax
   12202:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if( chars_stored || val != 0 || i == 7 ) {
   12205:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
   12209:	75 0c                	jne    12217 <cvthex+0x53>
   1220b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1220f:	75 06                	jne    12217 <cvthex+0x53>
   12211:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   12215:	75 1e                	jne    12235 <cvthex+0x71>
			++chars_stored;
   12217:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
			val = (val >> 28) & 0xf;
   1221b:	c1 6d f4 1c          	shrl   $0x1c,-0xc(%ebp)
			*buf++ = hexdigits[val];
   1221f:	8b 45 08             	mov    0x8(%ebp),%eax
   12222:	8d 50 01             	lea    0x1(%eax),%edx
   12225:	89 55 08             	mov    %edx,0x8(%ebp)
   12228:	8d 4d e3             	lea    -0x1d(%ebp),%ecx
   1222b:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1222e:	01 ca                	add    %ecx,%edx
   12230:	0f b6 12             	movzbl (%edx),%edx
   12233:	88 10                	mov    %dl,(%eax)
		}
		value <<= 4;
   12235:	c1 65 0c 04          	shll   $0x4,0xc(%ebp)
	for( int i = 0; i < 8; i += 1 ) {
   12239:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
   1223d:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   12241:	7e b7                	jle    121fa <cvthex+0x36>
	}

	*buf = '\0';
   12243:	8b 45 08             	mov    0x8(%ebp),%eax
   12246:	c6 00 00             	movb   $0x0,(%eax)

	return( chars_stored );
   12249:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   1224c:	c9                   	leave  
   1224d:	c3                   	ret    

0001224e <cvtoct>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtoct( char *buf, uint32_t value ) {
   1224e:	55                   	push   %ebp
   1224f:	89 e5                	mov    %esp,%ebp
   12251:	83 ec 10             	sub    $0x10,%esp
	int i;
	int chars_stored = 0;
   12254:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	char *bp = buf;
   1225b:	8b 45 08             	mov    0x8(%ebp),%eax
   1225e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32_t val;

	val = ( value & 0xc0000000 );
   12261:	8b 45 0c             	mov    0xc(%ebp),%eax
   12264:	25 00 00 00 c0       	and    $0xc0000000,%eax
   12269:	89 45 f0             	mov    %eax,-0x10(%ebp)
	val >>= 30;
   1226c:	c1 6d f0 1e          	shrl   $0x1e,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   12270:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   12277:	eb 47                	jmp    122c0 <cvtoct+0x72>

		if( i == 10 || val != 0 || chars_stored ) {
   12279:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   1227d:	74 0c                	je     1228b <cvtoct+0x3d>
   1227f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12283:	75 06                	jne    1228b <cvtoct+0x3d>
   12285:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
   12289:	74 1e                	je     122a9 <cvtoct+0x5b>
			chars_stored = 1;
   1228b:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)
			val &= 0x7;
   12292:	83 65 f0 07          	andl   $0x7,-0x10(%ebp)
			*bp++ = val + '0';
   12296:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12299:	8d 48 30             	lea    0x30(%eax),%ecx
   1229c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1229f:	8d 50 01             	lea    0x1(%eax),%edx
   122a2:	89 55 f4             	mov    %edx,-0xc(%ebp)
   122a5:	89 ca                	mov    %ecx,%edx
   122a7:	88 10                	mov    %dl,(%eax)
		}
		value <<= 3;
   122a9:	c1 65 0c 03          	shll   $0x3,0xc(%ebp)
		val = ( value & 0xe0000000 );
   122ad:	8b 45 0c             	mov    0xc(%ebp),%eax
   122b0:	25 00 00 00 e0       	and    $0xe0000000,%eax
   122b5:	89 45 f0             	mov    %eax,-0x10(%ebp)
		val >>= 29;
   122b8:	c1 6d f0 1d          	shrl   $0x1d,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   122bc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   122c0:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   122c4:	7e b3                	jle    12279 <cvtoct+0x2b>
	}
	*bp = '\0';
   122c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
   122c9:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   122cc:	8b 55 f4             	mov    -0xc(%ebp),%edx
   122cf:	8b 45 08             	mov    0x8(%ebp),%eax
   122d2:	29 c2                	sub    %eax,%edx
   122d4:	89 d0                	mov    %edx,%eax
}
   122d6:	c9                   	leave  
   122d7:	c3                   	ret    

000122d8 <cvtuns>:
**
** @return Length of the resulting buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtuns( char *buf, uint32_t value ) {
   122d8:	55                   	push   %ebp
   122d9:	89 e5                	mov    %esp,%ebp
   122db:	83 ec 18             	sub    $0x18,%esp
	char    *bp = buf;
   122de:	8b 45 08             	mov    0x8(%ebp),%eax
   122e1:	89 45 f4             	mov    %eax,-0xc(%ebp)

	bp = cvtuns0( bp, value );
   122e4:	83 ec 08             	sub    $0x8,%esp
   122e7:	ff 75 0c             	pushl  0xc(%ebp)
   122ea:	ff 75 f4             	pushl  -0xc(%ebp)
   122ed:	e8 18 00 00 00       	call   1230a <cvtuns0>
   122f2:	83 c4 10             	add    $0x10,%esp
   122f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp = '\0';
   122f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
   122fb:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   122fe:	8b 55 f4             	mov    -0xc(%ebp),%edx
   12301:	8b 45 08             	mov    0x8(%ebp),%eax
   12304:	29 c2                	sub    %eax,%edx
   12306:	89 d0                	mov    %edx,%eax
}
   12308:	c9                   	leave  
   12309:	c3                   	ret    

0001230a <cvtuns0>:
**
** @return Pointer to the first unused byte in the buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *cvtuns0( char *buf, uint32_t value ) {
   1230a:	55                   	push   %ebp
   1230b:	89 e5                	mov    %esp,%ebp
   1230d:	83 ec 18             	sub    $0x18,%esp
	uint32_t quotient;

	quotient = value / 10;
   12310:	8b 45 0c             	mov    0xc(%ebp),%eax
   12313:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   12318:	f7 e2                	mul    %edx
   1231a:	89 d0                	mov    %edx,%eax
   1231c:	c1 e8 03             	shr    $0x3,%eax
   1231f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient != 0 ){
   12322:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12326:	74 15                	je     1233d <cvtuns0+0x33>
		buf = cvtdec0( buf, quotient );
   12328:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1232b:	83 ec 08             	sub    $0x8,%esp
   1232e:	50                   	push   %eax
   1232f:	ff 75 08             	pushl  0x8(%ebp)
   12332:	e8 04 fe ff ff       	call   1213b <cvtdec0>
   12337:	83 c4 10             	add    $0x10,%esp
   1233a:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   1233d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   12340:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   12345:	89 c8                	mov    %ecx,%eax
   12347:	f7 e2                	mul    %edx
   12349:	c1 ea 03             	shr    $0x3,%edx
   1234c:	89 d0                	mov    %edx,%eax
   1234e:	c1 e0 02             	shl    $0x2,%eax
   12351:	01 d0                	add    %edx,%eax
   12353:	01 c0                	add    %eax,%eax
   12355:	29 c1                	sub    %eax,%ecx
   12357:	89 ca                	mov    %ecx,%edx
   12359:	89 d0                	mov    %edx,%eax
   1235b:	8d 48 30             	lea    0x30(%eax),%ecx
   1235e:	8b 45 08             	mov    0x8(%ebp),%eax
   12361:	8d 50 01             	lea    0x1(%eax),%edx
   12364:	89 55 08             	mov    %edx,0x8(%ebp)
   12367:	89 ca                	mov    %ecx,%edx
   12369:	88 10                	mov    %dl,(%eax)
	return buf;
   1236b:	8b 45 08             	mov    0x8(%ebp),%eax
}
   1236e:	c9                   	leave  
   1236f:	c3                   	ret    

00012370 <put_char_or_code>:
** is a non-printing character, in which case its hex code
** is printed
**
** @param ch    The character to be printed
*/
void put_char_or_code( int ch ) {
   12370:	55                   	push   %ebp
   12371:	89 e5                	mov    %esp,%ebp
   12373:	83 ec 08             	sub    $0x8,%esp

	if( ch >= ' ' && ch < 0x7f ) {
   12376:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
   1237a:	7e 17                	jle    12393 <put_char_or_code+0x23>
   1237c:	83 7d 08 7e          	cmpl   $0x7e,0x8(%ebp)
   12380:	7f 11                	jg     12393 <put_char_or_code+0x23>
		cio_putchar( ch );
   12382:	8b 45 08             	mov    0x8(%ebp),%eax
   12385:	83 ec 0c             	sub    $0xc,%esp
   12388:	50                   	push   %eax
   12389:	e8 df e9 ff ff       	call   10d6d <cio_putchar>
   1238e:	83 c4 10             	add    $0x10,%esp
   12391:	eb 13                	jmp    123a6 <put_char_or_code+0x36>
	} else {
		cio_printf( "\\x%02x", ch );
   12393:	83 ec 08             	sub    $0x8,%esp
   12396:	ff 75 08             	pushl  0x8(%ebp)
   12399:	68 a8 ad 01 00       	push   $0x1ada8
   1239e:	e8 84 f1 ff ff       	call   11527 <cio_printf>
   123a3:	83 c4 10             	add    $0x10,%esp
	}
}
   123a6:	90                   	nop
   123a7:	c9                   	leave  
   123a8:	c3                   	ret    

000123a9 <backtrace>:
** Perform a stack backtrace
**
** @param ebp   Initial EBP to use
** @param args  Number of function argument values to print
*/
void backtrace( uint32_t *ebp, uint_t args ) {
   123a9:	55                   	push   %ebp
   123aa:	89 e5                	mov    %esp,%ebp
   123ac:	83 ec 18             	sub    $0x18,%esp

	cio_puts( "Trace:  " );
   123af:	83 ec 0c             	sub    $0xc,%esp
   123b2:	68 af ad 01 00       	push   $0x1adaf
   123b7:	e8 f1 ea ff ff       	call   10ead <cio_puts>
   123bc:	83 c4 10             	add    $0x10,%esp
	if( ebp == NULL ) {
   123bf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   123c3:	75 15                	jne    123da <backtrace+0x31>
		cio_puts( "NULL ebp, no trace possible\n" );
   123c5:	83 ec 0c             	sub    $0xc,%esp
   123c8:	68 b8 ad 01 00       	push   $0x1adb8
   123cd:	e8 db ea ff ff       	call   10ead <cio_puts>
   123d2:	83 c4 10             	add    $0x10,%esp
		return;
   123d5:	e9 8b 00 00 00       	jmp    12465 <backtrace+0xbc>
	} else {
		cio_putchar( '\n' );
   123da:	83 ec 0c             	sub    $0xc,%esp
   123dd:	6a 0a                	push   $0xa
   123df:	e8 89 e9 ff ff       	call   10d6d <cio_putchar>
   123e4:	83 c4 10             	add    $0x10,%esp
	}

	while( ebp != NULL ){
   123e7:	eb 76                	jmp    1245f <backtrace+0xb6>

		// get return address and report it and EBP
		uint32_t ret = ebp[1];
   123e9:	8b 45 08             	mov    0x8(%ebp),%eax
   123ec:	8b 40 04             	mov    0x4(%eax),%eax
   123ef:	89 45 f0             	mov    %eax,-0x10(%ebp)
		cio_printf( " ebp %08x ret %08x args", (uint32_t) ebp, ret );
   123f2:	8b 45 08             	mov    0x8(%ebp),%eax
   123f5:	83 ec 04             	sub    $0x4,%esp
   123f8:	ff 75 f0             	pushl  -0x10(%ebp)
   123fb:	50                   	push   %eax
   123fc:	68 d5 ad 01 00       	push   $0x1add5
   12401:	e8 21 f1 ff ff       	call   11527 <cio_printf>
   12406:	83 c4 10             	add    $0x10,%esp

		// print the requested number of function arguments
		for( uint_t i = 0; i < args; ++i ) {
   12409:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   12410:	eb 30                	jmp    12442 <backtrace+0x99>
			cio_printf( " [%u] %08x", i+1, ebp[2+i] );
   12412:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12415:	83 c0 02             	add    $0x2,%eax
   12418:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1241f:	8b 45 08             	mov    0x8(%ebp),%eax
   12422:	01 d0                	add    %edx,%eax
   12424:	8b 00                	mov    (%eax),%eax
   12426:	8b 55 f4             	mov    -0xc(%ebp),%edx
   12429:	83 c2 01             	add    $0x1,%edx
   1242c:	83 ec 04             	sub    $0x4,%esp
   1242f:	50                   	push   %eax
   12430:	52                   	push   %edx
   12431:	68 ed ad 01 00       	push   $0x1aded
   12436:	e8 ec f0 ff ff       	call   11527 <cio_printf>
   1243b:	83 c4 10             	add    $0x10,%esp
		for( uint_t i = 0; i < args; ++i ) {
   1243e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   12442:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12445:	3b 45 0c             	cmp    0xc(%ebp),%eax
   12448:	72 c8                	jb     12412 <backtrace+0x69>
		}
		cio_putchar( '\n' );
   1244a:	83 ec 0c             	sub    $0xc,%esp
   1244d:	6a 0a                	push   $0xa
   1244f:	e8 19 e9 ff ff       	call   10d6d <cio_putchar>
   12454:	83 c4 10             	add    $0x10,%esp

		// follow the chain
		ebp = (uint32_t *) *ebp;
   12457:	8b 45 08             	mov    0x8(%ebp),%eax
   1245a:	8b 00                	mov    (%eax),%eax
   1245c:	89 45 08             	mov    %eax,0x8(%ebp)
	while( ebp != NULL ){
   1245f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12463:	75 84                	jne    123e9 <backtrace+0x40>
	}
}
   12465:	c9                   	leave  
   12466:	c3                   	ret    

00012467 <kpanic>:
** (e.g., printing a stack traceback)
**
** @param msg[in]  String containing a relevant message to be printed,
**				   or NULL
*/
void kpanic( const char *msg ) {
   12467:	55                   	push   %ebp
   12468:	89 e5                	mov    %esp,%ebp
   1246a:	83 ec 18             	sub    $0x18,%esp

	cio_puts( "\n\n***** KERNEL PANIC *****\n\n" );
   1246d:	83 ec 0c             	sub    $0xc,%esp
   12470:	68 f8 ad 01 00       	push   $0x1adf8
   12475:	e8 33 ea ff ff       	call   10ead <cio_puts>
   1247a:	83 c4 10             	add    $0x10,%esp

	if( msg ) {
   1247d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12481:	74 13                	je     12496 <kpanic+0x2f>
		cio_printf( "%s\n", msg );
   12483:	83 ec 08             	sub    $0x8,%esp
   12486:	ff 75 08             	pushl  0x8(%ebp)
   12489:	68 15 ae 01 00       	push   $0x1ae15
   1248e:	e8 94 f0 ff ff       	call   11527 <cio_printf>
   12493:	83 c4 10             	add    $0x10,%esp
	}

	delay( DELAY_5_SEC );   // approximately
   12496:	83 ec 0c             	sub    $0xc,%esp
   12499:	68 c8 00 00 00       	push   $0xc8
   1249e:	e8 e8 32 00 00       	call   1578b <delay>
   124a3:	83 c4 10             	add    $0x10,%esp

	// dump a bunch of potentially useful information

	// dump the contents of the current PCB
	pcb_dump( "Current", current, true );
   124a6:	a1 14 20 02 00       	mov    0x22014,%eax
   124ab:	83 ec 04             	sub    $0x4,%esp
   124ae:	6a 01                	push   $0x1
   124b0:	50                   	push   %eax
   124b1:	68 19 ae 01 00       	push   $0x1ae19
   124b6:	e8 f3 21 00 00       	call   146ae <pcb_dump>
   124bb:	83 c4 10             	add    $0x10,%esp

	// dump the basic info about what's in the process table
	ptable_dump_counts();
   124be:	e8 28 25 00 00       	call   149eb <ptable_dump_counts>

	// dump information about the queues
	pcb_queue_dump( "R", ready, true );
   124c3:	a1 d0 24 02 00       	mov    0x224d0,%eax
   124c8:	83 ec 04             	sub    $0x4,%esp
   124cb:	6a 01                	push   $0x1
   124cd:	50                   	push   %eax
   124ce:	68 21 ae 01 00       	push   $0x1ae21
   124d3:	e8 15 23 00 00       	call   147ed <pcb_queue_dump>
   124d8:	83 c4 10             	add    $0x10,%esp
	pcb_queue_dump( "W", waiting, true );
   124db:	a1 10 20 02 00       	mov    0x22010,%eax
   124e0:	83 ec 04             	sub    $0x4,%esp
   124e3:	6a 01                	push   $0x1
   124e5:	50                   	push   %eax
   124e6:	68 23 ae 01 00       	push   $0x1ae23
   124eb:	e8 fd 22 00 00       	call   147ed <pcb_queue_dump>
   124f0:	83 c4 10             	add    $0x10,%esp
	pcb_queue_dump( "S", sleeping, true );
   124f3:	a1 08 20 02 00       	mov    0x22008,%eax
   124f8:	83 ec 04             	sub    $0x4,%esp
   124fb:	6a 01                	push   $0x1
   124fd:	50                   	push   %eax
   124fe:	68 25 ae 01 00       	push   $0x1ae25
   12503:	e8 e5 22 00 00       	call   147ed <pcb_queue_dump>
   12508:	83 c4 10             	add    $0x10,%esp
	pcb_queue_dump( "Z", zombie, true );
   1250b:	a1 18 20 02 00       	mov    0x22018,%eax
   12510:	83 ec 04             	sub    $0x4,%esp
   12513:	6a 01                	push   $0x1
   12515:	50                   	push   %eax
   12516:	68 27 ae 01 00       	push   $0x1ae27
   1251b:	e8 cd 22 00 00       	call   147ed <pcb_queue_dump>
   12520:	83 c4 10             	add    $0x10,%esp
	pcb_queue_dump( "I", sioread, true );
   12523:	a1 04 20 02 00       	mov    0x22004,%eax
   12528:	83 ec 04             	sub    $0x4,%esp
   1252b:	6a 01                	push   $0x1
   1252d:	50                   	push   %eax
   1252e:	68 29 ae 01 00       	push   $0x1ae29
   12533:	e8 b5 22 00 00       	call   147ed <pcb_queue_dump>
   12538:	83 c4 10             	add    $0x10,%esp
	__asm__ __volatile__( "movl %%ebp,%0" : "=r" (val) );
   1253b:	89 e8                	mov    %ebp,%eax
   1253d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return val;
   12540:	8b 45 f4             	mov    -0xc(%ebp),%eax

	// perform a stack backtrace
	backtrace( (uint32_t *) r_ebp(), 3 );
   12543:	83 ec 08             	sub    $0x8,%esp
   12546:	6a 03                	push   $0x3
   12548:	50                   	push   %eax
   12549:	e8 5b fe ff ff       	call   123a9 <backtrace>
   1254e:	83 c4 10             	add    $0x10,%esp

	// could dump other stuff here, too

	panic( "KERNEL PANIC" );
   12551:	83 ec 0c             	sub    $0xc,%esp
   12554:	68 2b ae 01 00       	push   $0x1ae2b
   12559:	e8 d9 31 00 00       	call   15737 <panic>
   1255e:	83 c4 10             	add    $0x10,%esp
}
   12561:	90                   	nop
   12562:	c9                   	leave  
   12563:	c3                   	ret    

00012564 <memclr>:
** Initialize all bytes of a block of memory to zero
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
*/
void memclr( void *buf, register uint32_t len ) {
   12564:	55                   	push   %ebp
   12565:	89 e5                	mov    %esp,%ebp
   12567:	53                   	push   %ebx
   12568:	8b 55 0c             	mov    0xc(%ebp),%edx
	register uint8_t *dest = buf;
   1256b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and clearing
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   1256e:	eb 08                	jmp    12578 <memclr+0x14>
			*dest++ = 0;
   12570:	89 d8                	mov    %ebx,%eax
   12572:	8d 58 01             	lea    0x1(%eax),%ebx
   12575:	c6 00 00             	movb   $0x0,(%eax)
	while( len-- ) {
   12578:	89 d0                	mov    %edx,%eax
   1257a:	8d 50 ff             	lea    -0x1(%eax),%edx
   1257d:	85 c0                	test   %eax,%eax
   1257f:	75 ef                	jne    12570 <memclr+0xc>
	}
}
   12581:	90                   	nop
   12582:	5b                   	pop    %ebx
   12583:	5d                   	pop    %ebp
   12584:	c3                   	ret    

00012585 <memcpy>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void memcpy( void *dst, register const void *src, register uint32_t len ) {
   12585:	55                   	push   %ebp
   12586:	89 e5                	mov    %esp,%ebp
   12588:	56                   	push   %esi
   12589:	53                   	push   %ebx
   1258a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	register uint8_t *dest = dst;
   1258d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint8_t *source = src;
   12590:	8b 75 0c             	mov    0xc(%ebp),%esi
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   12593:	eb 0f                	jmp    125a4 <memcpy+0x1f>
		*dest++ = *source++;
   12595:	89 f2                	mov    %esi,%edx
   12597:	8d 72 01             	lea    0x1(%edx),%esi
   1259a:	89 d8                	mov    %ebx,%eax
   1259c:	8d 58 01             	lea    0x1(%eax),%ebx
   1259f:	0f b6 12             	movzbl (%edx),%edx
   125a2:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   125a4:	89 c8                	mov    %ecx,%eax
   125a6:	8d 48 ff             	lea    -0x1(%eax),%ecx
   125a9:	85 c0                	test   %eax,%eax
   125ab:	75 e8                	jne    12595 <memcpy+0x10>
	}
}
   125ad:	90                   	nop
   125ae:	5b                   	pop    %ebx
   125af:	5e                   	pop    %esi
   125b0:	5d                   	pop    %ebp
   125b1:	c3                   	ret    

000125b2 <memmove>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void memmove( void *dst, const void *src, register uint32_t len ) {
   125b2:	55                   	push   %ebp
   125b3:	89 e5                	mov    %esp,%ebp
   125b5:	56                   	push   %esi
   125b6:	53                   	push   %ebx
   125b7:	8b 45 10             	mov    0x10(%ebp),%eax
	register uint8_t *dest = dst;
   125ba:	8b 75 08             	mov    0x8(%ebp),%esi
	register const uint8_t *source = src;
   125bd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	if( source < dest && (source + len) > dest ) {
   125c0:	39 f3                	cmp    %esi,%ebx
   125c2:	73 32                	jae    125f6 <memmove+0x44>
   125c4:	8d 14 03             	lea    (%ebx,%eax,1),%edx
   125c7:	39 d6                	cmp    %edx,%esi
   125c9:	73 2b                	jae    125f6 <memmove+0x44>
		source += len;
   125cb:	01 c3                	add    %eax,%ebx
		dest += len;
   125cd:	01 c6                	add    %eax,%esi
		while( len-- > 0 ) {
   125cf:	eb 0b                	jmp    125dc <memmove+0x2a>
			*--dest = *--source;
   125d1:	83 eb 01             	sub    $0x1,%ebx
   125d4:	83 ee 01             	sub    $0x1,%esi
   125d7:	0f b6 13             	movzbl (%ebx),%edx
   125da:	88 16                	mov    %dl,(%esi)
		while( len-- > 0 ) {
   125dc:	89 c2                	mov    %eax,%edx
   125de:	8d 42 ff             	lea    -0x1(%edx),%eax
   125e1:	85 d2                	test   %edx,%edx
   125e3:	75 ec                	jne    125d1 <memmove+0x1f>
	if( source < dest && (source + len) > dest ) {
   125e5:	eb 18                	jmp    125ff <memmove+0x4d>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   125e7:	89 d9                	mov    %ebx,%ecx
   125e9:	8d 59 01             	lea    0x1(%ecx),%ebx
   125ec:	89 f2                	mov    %esi,%edx
   125ee:	8d 72 01             	lea    0x1(%edx),%esi
   125f1:	0f b6 09             	movzbl (%ecx),%ecx
   125f4:	88 0a                	mov    %cl,(%edx)
		while( len-- ) {
   125f6:	89 c2                	mov    %eax,%edx
   125f8:	8d 42 ff             	lea    -0x1(%edx),%eax
   125fb:	85 d2                	test   %edx,%edx
   125fd:	75 e8                	jne    125e7 <memmove+0x35>
		}
	}
}
   125ff:	90                   	nop
   12600:	5b                   	pop    %ebx
   12601:	5e                   	pop    %esi
   12602:	5d                   	pop    %ebp
   12603:	c3                   	ret    

00012604 <memset>:
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
** @param value  Initialization value
*/
void memset( void *buf, register uint32_t len, register uint32_t value ) {
   12604:	55                   	push   %ebp
   12605:	89 e5                	mov    %esp,%ebp
   12607:	53                   	push   %ebx
   12608:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register uint8_t *bp = buf;
   1260b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   1260e:	eb 0b                	jmp    1261b <memset+0x17>
		*bp++ = value;
   12610:	89 d8                	mov    %ebx,%eax
   12612:	8d 58 01             	lea    0x1(%eax),%ebx
   12615:	0f b6 55 10          	movzbl 0x10(%ebp),%edx
   12619:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   1261b:	89 c8                	mov    %ecx,%eax
   1261d:	8d 48 ff             	lea    -0x1(%eax),%ecx
   12620:	85 c0                	test   %eax,%eax
   12622:	75 ec                	jne    12610 <memset+0xc>
	}
}
   12624:	90                   	nop
   12625:	5b                   	pop    %ebx
   12626:	5d                   	pop    %ebp
   12627:	c3                   	ret    

00012628 <pad>:
**
** @return Pointer to the first byte after the padding
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *pad( char *dst, int extra, int padchar ) {
   12628:	55                   	push   %ebp
   12629:	89 e5                	mov    %esp,%ebp
	while( extra > 0 ){
   1262b:	eb 12                	jmp    1263f <pad+0x17>
		*dst++ = (char) padchar;
   1262d:	8b 45 08             	mov    0x8(%ebp),%eax
   12630:	8d 50 01             	lea    0x1(%eax),%edx
   12633:	89 55 08             	mov    %edx,0x8(%ebp)
   12636:	8b 55 10             	mov    0x10(%ebp),%edx
   12639:	88 10                	mov    %dl,(%eax)
		extra -= 1;
   1263b:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
	while( extra > 0 ){
   1263f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   12643:	7f e8                	jg     1262d <pad+0x5>
	}
	return dst;
   12645:	8b 45 08             	mov    0x8(%ebp),%eax
}
   12648:	5d                   	pop    %ebp
   12649:	c3                   	ret    

0001264a <padstr>:
** @return Pointer to the first byte after the padded string
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *padstr( char *dst, char *str, int len, int width,
				int leftadjust, int padchar ) {
   1264a:	55                   	push   %ebp
   1264b:	89 e5                	mov    %esp,%ebp
   1264d:	83 ec 18             	sub    $0x18,%esp
	int extra;

	// determine the length of the string if we need to
	if( len < 0 ){
   12650:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
   12654:	79 11                	jns    12667 <padstr+0x1d>
		len = strlen( str );
   12656:	83 ec 0c             	sub    $0xc,%esp
   12659:	ff 75 0c             	pushl  0xc(%ebp)
   1265c:	e8 03 04 00 00       	call   12a64 <strlen>
   12661:	83 c4 10             	add    $0x10,%esp
   12664:	89 45 10             	mov    %eax,0x10(%ebp)
	}

	// how much filler must we add?
	extra = width - len;
   12667:	8b 45 14             	mov    0x14(%ebp),%eax
   1266a:	2b 45 10             	sub    0x10(%ebp),%eax
   1266d:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// add filler on the left if we're not left-justifying
	if( extra > 0 && !leftadjust ){
   12670:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12674:	7e 1d                	jle    12693 <padstr+0x49>
   12676:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   1267a:	75 17                	jne    12693 <padstr+0x49>
		dst = pad( dst, extra, padchar );
   1267c:	83 ec 04             	sub    $0x4,%esp
   1267f:	ff 75 1c             	pushl  0x1c(%ebp)
   12682:	ff 75 f0             	pushl  -0x10(%ebp)
   12685:	ff 75 08             	pushl  0x8(%ebp)
   12688:	e8 9b ff ff ff       	call   12628 <pad>
   1268d:	83 c4 10             	add    $0x10,%esp
   12690:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	// copy the string itself
	for( int i = 0; i < len; ++i ) {
   12693:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   1269a:	eb 1b                	jmp    126b7 <padstr+0x6d>
		*dst++ = str[i];
   1269c:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1269f:	8b 45 0c             	mov    0xc(%ebp),%eax
   126a2:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
   126a5:	8b 45 08             	mov    0x8(%ebp),%eax
   126a8:	8d 50 01             	lea    0x1(%eax),%edx
   126ab:	89 55 08             	mov    %edx,0x8(%ebp)
   126ae:	0f b6 11             	movzbl (%ecx),%edx
   126b1:	88 10                	mov    %dl,(%eax)
	for( int i = 0; i < len; ++i ) {
   126b3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   126b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
   126ba:	3b 45 10             	cmp    0x10(%ebp),%eax
   126bd:	7c dd                	jl     1269c <padstr+0x52>
	}

	// add filler on the right if we are left-justifying
	if( extra > 0 && leftadjust ){
   126bf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   126c3:	7e 1d                	jle    126e2 <padstr+0x98>
   126c5:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   126c9:	74 17                	je     126e2 <padstr+0x98>
		dst = pad( dst, extra, padchar );
   126cb:	83 ec 04             	sub    $0x4,%esp
   126ce:	ff 75 1c             	pushl  0x1c(%ebp)
   126d1:	ff 75 f0             	pushl  -0x10(%ebp)
   126d4:	ff 75 08             	pushl  0x8(%ebp)
   126d7:	e8 4c ff ff ff       	call   12628 <pad>
   126dc:	83 c4 10             	add    $0x10,%esp
   126df:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	return dst;
   126e2:	8b 45 08             	mov    0x8(%ebp),%eax
}
   126e5:	c9                   	leave  
   126e6:	c3                   	ret    

000126e7 <sprint>:
**
** NOTE:  relies heavily on the x86 parameter passing convention
** (parameters are pushed onto the stack in reverse order as
** 32-bit values).
*/
void sprint( char *dst, char *fmt, ... ) {
   126e7:	55                   	push   %ebp
   126e8:	89 e5                	mov    %esp,%ebp
   126ea:	83 ec 38             	sub    $0x38,%esp
	** to point to the next "thing", and interpret it according
	** to the format string.
	*/
	
	// get the pointer to the first "value" parameter
	ap = (int *)(&fmt) + 1;
   126ed:	8d 45 0c             	lea    0xc(%ebp),%eax
   126f0:	83 c0 04             	add    $0x4,%eax
   126f3:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// iterate through the format string
	while( (ch = *fmt++) != '\0' ){
   126f6:	e9 3f 02 00 00       	jmp    1293a <sprint+0x253>
		/*
		** Is it the start of a format code?
		*/
		if( ch == '%' ){
   126fb:	80 7d f3 25          	cmpb   $0x25,-0xd(%ebp)
   126ff:	0f 85 26 02 00 00    	jne    1292b <sprint+0x244>
			/*
			** Yes, get the padding and width options (if there).
			** Alignment must come at the beginning, then fill,
			** then width.
			*/
			leftadjust = 0;
   12705:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
			padchar = ' ';
   1270c:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
			width = 0;
   12713:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
			ch = *fmt++;
   1271a:	8b 45 0c             	mov    0xc(%ebp),%eax
   1271d:	8d 50 01             	lea    0x1(%eax),%edx
   12720:	89 55 0c             	mov    %edx,0xc(%ebp)
   12723:	0f b6 00             	movzbl (%eax),%eax
   12726:	88 45 f3             	mov    %al,-0xd(%ebp)
			if( ch == '-' ){
   12729:	80 7d f3 2d          	cmpb   $0x2d,-0xd(%ebp)
   1272d:	75 16                	jne    12745 <sprint+0x5e>
				leftadjust = 1;
   1272f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
				ch = *fmt++;
   12736:	8b 45 0c             	mov    0xc(%ebp),%eax
   12739:	8d 50 01             	lea    0x1(%eax),%edx
   1273c:	89 55 0c             	mov    %edx,0xc(%ebp)
   1273f:	0f b6 00             	movzbl (%eax),%eax
   12742:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			if( ch == '0' ){
   12745:	80 7d f3 30          	cmpb   $0x30,-0xd(%ebp)
   12749:	75 40                	jne    1278b <sprint+0xa4>
				padchar = '0';
   1274b:	c7 45 e4 30 00 00 00 	movl   $0x30,-0x1c(%ebp)
				ch = *fmt++;
   12752:	8b 45 0c             	mov    0xc(%ebp),%eax
   12755:	8d 50 01             	lea    0x1(%eax),%edx
   12758:	89 55 0c             	mov    %edx,0xc(%ebp)
   1275b:	0f b6 00             	movzbl (%eax),%eax
   1275e:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			while( ch >= '0' && ch <= '9' ){
   12761:	eb 28                	jmp    1278b <sprint+0xa4>
				width *= 10;
   12763:	8b 55 e8             	mov    -0x18(%ebp),%edx
   12766:	89 d0                	mov    %edx,%eax
   12768:	c1 e0 02             	shl    $0x2,%eax
   1276b:	01 d0                	add    %edx,%eax
   1276d:	01 c0                	add    %eax,%eax
   1276f:	89 45 e8             	mov    %eax,-0x18(%ebp)
				width += ch - '0';
   12772:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   12776:	83 e8 30             	sub    $0x30,%eax
   12779:	01 45 e8             	add    %eax,-0x18(%ebp)
				ch = *fmt++;
   1277c:	8b 45 0c             	mov    0xc(%ebp),%eax
   1277f:	8d 50 01             	lea    0x1(%eax),%edx
   12782:	89 55 0c             	mov    %edx,0xc(%ebp)
   12785:	0f b6 00             	movzbl (%eax),%eax
   12788:	88 45 f3             	mov    %al,-0xd(%ebp)
			while( ch >= '0' && ch <= '9' ){
   1278b:	80 7d f3 2f          	cmpb   $0x2f,-0xd(%ebp)
   1278f:	7e 06                	jle    12797 <sprint+0xb0>
   12791:	80 7d f3 39          	cmpb   $0x39,-0xd(%ebp)
   12795:	7e cc                	jle    12763 <sprint+0x7c>
			}

			/*
			** What data type do we have?
			*/
			switch( ch ) {
   12797:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   1279b:	83 e8 63             	sub    $0x63,%eax
   1279e:	83 f8 15             	cmp    $0x15,%eax
   127a1:	0f 87 93 01 00 00    	ja     1293a <sprint+0x253>
   127a7:	8b 04 85 38 ae 01 00 	mov    0x1ae38(,%eax,4),%eax
   127ae:	ff e0                	jmp    *%eax

			case 'c':  // characters are passed as 32-bit values
				ch = *ap++;
   127b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
   127b3:	8d 50 04             	lea    0x4(%eax),%edx
   127b6:	89 55 f4             	mov    %edx,-0xc(%ebp)
   127b9:	8b 00                	mov    (%eax),%eax
   127bb:	88 45 f3             	mov    %al,-0xd(%ebp)
				buf[ 0 ] = ch;
   127be:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   127c2:	88 45 d0             	mov    %al,-0x30(%ebp)
				buf[ 1 ] = '\0';
   127c5:	c6 45 d1 00          	movb   $0x0,-0x2f(%ebp)
				dst = padstr( dst, buf, 1, width, leftadjust, padchar );
   127c9:	83 ec 08             	sub    $0x8,%esp
   127cc:	ff 75 e4             	pushl  -0x1c(%ebp)
   127cf:	ff 75 ec             	pushl  -0x14(%ebp)
   127d2:	ff 75 e8             	pushl  -0x18(%ebp)
   127d5:	6a 01                	push   $0x1
   127d7:	8d 45 d0             	lea    -0x30(%ebp),%eax
   127da:	50                   	push   %eax
   127db:	ff 75 08             	pushl  0x8(%ebp)
   127de:	e8 67 fe ff ff       	call   1264a <padstr>
   127e3:	83 c4 20             	add    $0x20,%esp
   127e6:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   127e9:	e9 4c 01 00 00       	jmp    1293a <sprint+0x253>

			case 'd':
				len = cvtdec( buf, *ap++ );
   127ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
   127f1:	8d 50 04             	lea    0x4(%eax),%edx
   127f4:	89 55 f4             	mov    %edx,-0xc(%ebp)
   127f7:	8b 00                	mov    (%eax),%eax
   127f9:	83 ec 08             	sub    $0x8,%esp
   127fc:	50                   	push   %eax
   127fd:	8d 45 d0             	lea    -0x30(%ebp),%eax
   12800:	50                   	push   %eax
   12801:	e8 ee f8 ff ff       	call   120f4 <cvtdec>
   12806:	83 c4 10             	add    $0x10,%esp
   12809:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   1280c:	83 ec 08             	sub    $0x8,%esp
   1280f:	ff 75 e4             	pushl  -0x1c(%ebp)
   12812:	ff 75 ec             	pushl  -0x14(%ebp)
   12815:	ff 75 e8             	pushl  -0x18(%ebp)
   12818:	ff 75 e0             	pushl  -0x20(%ebp)
   1281b:	8d 45 d0             	lea    -0x30(%ebp),%eax
   1281e:	50                   	push   %eax
   1281f:	ff 75 08             	pushl  0x8(%ebp)
   12822:	e8 23 fe ff ff       	call   1264a <padstr>
   12827:	83 c4 20             	add    $0x20,%esp
   1282a:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   1282d:	e9 08 01 00 00       	jmp    1293a <sprint+0x253>

			case 's':
				str = (char *) (*ap++);
   12832:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12835:	8d 50 04             	lea    0x4(%eax),%edx
   12838:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1283b:	8b 00                	mov    (%eax),%eax
   1283d:	89 45 dc             	mov    %eax,-0x24(%ebp)
				dst = padstr( dst, str, -1, width, leftadjust, padchar );
   12840:	83 ec 08             	sub    $0x8,%esp
   12843:	ff 75 e4             	pushl  -0x1c(%ebp)
   12846:	ff 75 ec             	pushl  -0x14(%ebp)
   12849:	ff 75 e8             	pushl  -0x18(%ebp)
   1284c:	6a ff                	push   $0xffffffff
   1284e:	ff 75 dc             	pushl  -0x24(%ebp)
   12851:	ff 75 08             	pushl  0x8(%ebp)
   12854:	e8 f1 fd ff ff       	call   1264a <padstr>
   12859:	83 c4 20             	add    $0x20,%esp
   1285c:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   1285f:	e9 d6 00 00 00       	jmp    1293a <sprint+0x253>

			case 'x':
				len = cvthex( buf, *ap++ );
   12864:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12867:	8d 50 04             	lea    0x4(%eax),%edx
   1286a:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1286d:	8b 00                	mov    (%eax),%eax
   1286f:	83 ec 08             	sub    $0x8,%esp
   12872:	50                   	push   %eax
   12873:	8d 45 d0             	lea    -0x30(%ebp),%eax
   12876:	50                   	push   %eax
   12877:	e8 48 f9 ff ff       	call   121c4 <cvthex>
   1287c:	83 c4 10             	add    $0x10,%esp
   1287f:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   12882:	83 ec 08             	sub    $0x8,%esp
   12885:	ff 75 e4             	pushl  -0x1c(%ebp)
   12888:	ff 75 ec             	pushl  -0x14(%ebp)
   1288b:	ff 75 e8             	pushl  -0x18(%ebp)
   1288e:	ff 75 e0             	pushl  -0x20(%ebp)
   12891:	8d 45 d0             	lea    -0x30(%ebp),%eax
   12894:	50                   	push   %eax
   12895:	ff 75 08             	pushl  0x8(%ebp)
   12898:	e8 ad fd ff ff       	call   1264a <padstr>
   1289d:	83 c4 20             	add    $0x20,%esp
   128a0:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   128a3:	e9 92 00 00 00       	jmp    1293a <sprint+0x253>

			case 'o':
				len = cvtoct( buf, *ap++ );
   128a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
   128ab:	8d 50 04             	lea    0x4(%eax),%edx
   128ae:	89 55 f4             	mov    %edx,-0xc(%ebp)
   128b1:	8b 00                	mov    (%eax),%eax
   128b3:	83 ec 08             	sub    $0x8,%esp
   128b6:	50                   	push   %eax
   128b7:	8d 45 d0             	lea    -0x30(%ebp),%eax
   128ba:	50                   	push   %eax
   128bb:	e8 8e f9 ff ff       	call   1224e <cvtoct>
   128c0:	83 c4 10             	add    $0x10,%esp
   128c3:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   128c6:	83 ec 08             	sub    $0x8,%esp
   128c9:	ff 75 e4             	pushl  -0x1c(%ebp)
   128cc:	ff 75 ec             	pushl  -0x14(%ebp)
   128cf:	ff 75 e8             	pushl  -0x18(%ebp)
   128d2:	ff 75 e0             	pushl  -0x20(%ebp)
   128d5:	8d 45 d0             	lea    -0x30(%ebp),%eax
   128d8:	50                   	push   %eax
   128d9:	ff 75 08             	pushl  0x8(%ebp)
   128dc:	e8 69 fd ff ff       	call   1264a <padstr>
   128e1:	83 c4 20             	add    $0x20,%esp
   128e4:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   128e7:	eb 51                	jmp    1293a <sprint+0x253>

			case 'u':
				len = cvtuns( buf, *ap++ );
   128e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
   128ec:	8d 50 04             	lea    0x4(%eax),%edx
   128ef:	89 55 f4             	mov    %edx,-0xc(%ebp)
   128f2:	8b 00                	mov    (%eax),%eax
   128f4:	83 ec 08             	sub    $0x8,%esp
   128f7:	50                   	push   %eax
   128f8:	8d 45 d0             	lea    -0x30(%ebp),%eax
   128fb:	50                   	push   %eax
   128fc:	e8 d7 f9 ff ff       	call   122d8 <cvtuns>
   12901:	83 c4 10             	add    $0x10,%esp
   12904:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   12907:	83 ec 08             	sub    $0x8,%esp
   1290a:	ff 75 e4             	pushl  -0x1c(%ebp)
   1290d:	ff 75 ec             	pushl  -0x14(%ebp)
   12910:	ff 75 e8             	pushl  -0x18(%ebp)
   12913:	ff 75 e0             	pushl  -0x20(%ebp)
   12916:	8d 45 d0             	lea    -0x30(%ebp),%eax
   12919:	50                   	push   %eax
   1291a:	ff 75 08             	pushl  0x8(%ebp)
   1291d:	e8 28 fd ff ff       	call   1264a <padstr>
   12922:	83 c4 20             	add    $0x20,%esp
   12925:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   12928:	90                   	nop
   12929:	eb 0f                	jmp    1293a <sprint+0x253>

			}
		} else {
			// no, it's just an ordinary character
			*dst++ = ch;
   1292b:	8b 45 08             	mov    0x8(%ebp),%eax
   1292e:	8d 50 01             	lea    0x1(%eax),%edx
   12931:	89 55 08             	mov    %edx,0x8(%ebp)
   12934:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
   12938:	88 10                	mov    %dl,(%eax)
	while( (ch = *fmt++) != '\0' ){
   1293a:	8b 45 0c             	mov    0xc(%ebp),%eax
   1293d:	8d 50 01             	lea    0x1(%eax),%edx
   12940:	89 55 0c             	mov    %edx,0xc(%ebp)
   12943:	0f b6 00             	movzbl (%eax),%eax
   12946:	88 45 f3             	mov    %al,-0xd(%ebp)
   12949:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   1294d:	0f 85 a8 fd ff ff    	jne    126fb <sprint+0x14>
		}
	}

	// NUL-terminate the result
	*dst = '\0';
   12953:	8b 45 08             	mov    0x8(%ebp),%eax
   12956:	c6 00 00             	movb   $0x0,(%eax)
}
   12959:	90                   	nop
   1295a:	c9                   	leave  
   1295b:	c3                   	ret    

0001295c <str2int>:
** @param str   The string to examine
** @param base  The radix to use in the conversion
**
** @return The converted integer
*/
int str2int( register const char *str, register int base ) {
   1295c:	55                   	push   %ebp
   1295d:	89 e5                	mov    %esp,%ebp
   1295f:	53                   	push   %ebx
   12960:	83 ec 14             	sub    $0x14,%esp
   12963:	8b 45 08             	mov    0x8(%ebp),%eax
   12966:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register int num = 0;
   12969:	bb 00 00 00 00       	mov    $0x0,%ebx
	register char bchar = '9';
   1296e:	c6 45 eb 39          	movb   $0x39,-0x15(%ebp)
	int sign = 1;
   12972:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)

	// check for leading '-'
	if( *str == '-' ) {
   12979:	0f b6 10             	movzbl (%eax),%edx
   1297c:	80 fa 2d             	cmp    $0x2d,%dl
   1297f:	75 0a                	jne    1298b <str2int+0x2f>
		sign = -1;
   12981:	c7 45 f8 ff ff ff ff 	movl   $0xffffffff,-0x8(%ebp)
		++str;
   12988:	83 c0 01             	add    $0x1,%eax
	}

	if( base != 10 ) {
   1298b:	83 f9 0a             	cmp    $0xa,%ecx
   1298e:	74 2b                	je     129bb <str2int+0x5f>
		bchar = '0' + base - 1;
   12990:	89 ca                	mov    %ecx,%edx
   12992:	83 c2 2f             	add    $0x2f,%edx
   12995:	88 55 eb             	mov    %dl,-0x15(%ebp)
	}

	// iterate through the characters
	while( *str ) {
   12998:	eb 21                	jmp    129bb <str2int+0x5f>
		if( *str < '0' || *str > bchar )
   1299a:	0f b6 10             	movzbl (%eax),%edx
   1299d:	80 fa 2f             	cmp    $0x2f,%dl
   129a0:	7e 20                	jle    129c2 <str2int+0x66>
   129a2:	0f b6 10             	movzbl (%eax),%edx
   129a5:	38 55 eb             	cmp    %dl,-0x15(%ebp)
   129a8:	7c 18                	jl     129c2 <str2int+0x66>
			break;
		num = num * base + *str - '0';
   129aa:	0f af d9             	imul   %ecx,%ebx
   129ad:	0f b6 10             	movzbl (%eax),%edx
   129b0:	0f be d2             	movsbl %dl,%edx
   129b3:	01 da                	add    %ebx,%edx
   129b5:	8d 5a d0             	lea    -0x30(%edx),%ebx
		++str;
   129b8:	83 c0 01             	add    $0x1,%eax
	while( *str ) {
   129bb:	0f b6 10             	movzbl (%eax),%edx
   129be:	84 d2                	test   %dl,%dl
   129c0:	75 d8                	jne    1299a <str2int+0x3e>
	}

	// return the converted value
	return( num * sign );
   129c2:	89 d8                	mov    %ebx,%eax
   129c4:	0f af 45 f8          	imul   -0x8(%ebp),%eax
}
   129c8:	83 c4 14             	add    $0x14,%esp
   129cb:	5b                   	pop    %ebx
   129cc:	5d                   	pop    %ebp
   129cd:	c3                   	ret    

000129ce <strcat>:
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the resulting string
*/
char *strcat( register char *dst, register const char *src ) {
   129ce:	55                   	push   %ebp
   129cf:	89 e5                	mov    %esp,%ebp
   129d1:	56                   	push   %esi
   129d2:	53                   	push   %ebx
   129d3:	8b 45 08             	mov    0x8(%ebp),%eax
   129d6:	8b 75 0c             	mov    0xc(%ebp),%esi
	register char *tmp = dst;
   129d9:	89 c3                	mov    %eax,%ebx

	while( *dst )  // find the NUL
   129db:	eb 03                	jmp    129e0 <strcat+0x12>
		++dst;
   129dd:	83 c0 01             	add    $0x1,%eax
	while( *dst )  // find the NUL
   129e0:	0f b6 10             	movzbl (%eax),%edx
   129e3:	84 d2                	test   %dl,%dl
   129e5:	75 f6                	jne    129dd <strcat+0xf>

	while( (*dst++ = *src++) )  // append the src string
   129e7:	90                   	nop
   129e8:	89 f1                	mov    %esi,%ecx
   129ea:	8d 71 01             	lea    0x1(%ecx),%esi
   129ed:	89 c2                	mov    %eax,%edx
   129ef:	8d 42 01             	lea    0x1(%edx),%eax
   129f2:	0f b6 09             	movzbl (%ecx),%ecx
   129f5:	88 0a                	mov    %cl,(%edx)
   129f7:	0f b6 12             	movzbl (%edx),%edx
   129fa:	84 d2                	test   %dl,%dl
   129fc:	75 ea                	jne    129e8 <strcat+0x1a>
		;

	return( tmp );
   129fe:	89 d8                	mov    %ebx,%eax
}
   12a00:	5b                   	pop    %ebx
   12a01:	5e                   	pop    %esi
   12a02:	5d                   	pop    %ebp
   12a03:	c3                   	ret    

00012a04 <strcmp>:
** @param s1 The first source string
** @param s2 The second source string
**
** @return negative if s1 < s2, zero if equal, and positive if s1 > s2
*/
int strcmp( register const char *s1, register const char *s2 ) {
   12a04:	55                   	push   %ebp
   12a05:	89 e5                	mov    %esp,%ebp
   12a07:	53                   	push   %ebx
   12a08:	8b 45 08             	mov    0x8(%ebp),%eax
   12a0b:	8b 55 0c             	mov    0xc(%ebp),%edx

	while( *s1 != 0 && (*s1 == *s2) )
   12a0e:	eb 06                	jmp    12a16 <strcmp+0x12>
		++s1, ++s2;
   12a10:	83 c0 01             	add    $0x1,%eax
   12a13:	83 c2 01             	add    $0x1,%edx
	while( *s1 != 0 && (*s1 == *s2) )
   12a16:	0f b6 08             	movzbl (%eax),%ecx
   12a19:	84 c9                	test   %cl,%cl
   12a1b:	74 0a                	je     12a27 <strcmp+0x23>
   12a1d:	0f b6 18             	movzbl (%eax),%ebx
   12a20:	0f b6 0a             	movzbl (%edx),%ecx
   12a23:	38 cb                	cmp    %cl,%bl
   12a25:	74 e9                	je     12a10 <strcmp+0xc>

	return( *s1 - *s2 );
   12a27:	0f b6 00             	movzbl (%eax),%eax
   12a2a:	0f be c8             	movsbl %al,%ecx
   12a2d:	0f b6 02             	movzbl (%edx),%eax
   12a30:	0f be c0             	movsbl %al,%eax
   12a33:	29 c1                	sub    %eax,%ecx
   12a35:	89 c8                	mov    %ecx,%eax
}
   12a37:	5b                   	pop    %ebx
   12a38:	5d                   	pop    %ebp
   12a39:	c3                   	ret    

00012a3a <strcpy>:
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the copied string
*/
char *strcpy( register char *dst, register const char *src ) {
   12a3a:	55                   	push   %ebp
   12a3b:	89 e5                	mov    %esp,%ebp
   12a3d:	56                   	push   %esi
   12a3e:	53                   	push   %ebx
   12a3f:	8b 4d 08             	mov    0x8(%ebp),%ecx
   12a42:	8b 75 0c             	mov    0xc(%ebp),%esi
	register char *tmp = dst;
   12a45:	89 cb                	mov    %ecx,%ebx

	while( (*dst++ = *src++) )
   12a47:	90                   	nop
   12a48:	89 f2                	mov    %esi,%edx
   12a4a:	8d 72 01             	lea    0x1(%edx),%esi
   12a4d:	89 c8                	mov    %ecx,%eax
   12a4f:	8d 48 01             	lea    0x1(%eax),%ecx
   12a52:	0f b6 12             	movzbl (%edx),%edx
   12a55:	88 10                	mov    %dl,(%eax)
   12a57:	0f b6 00             	movzbl (%eax),%eax
   12a5a:	84 c0                	test   %al,%al
   12a5c:	75 ea                	jne    12a48 <strcpy+0xe>
		;

	return( tmp );
   12a5e:	89 d8                	mov    %ebx,%eax
}
   12a60:	5b                   	pop    %ebx
   12a61:	5e                   	pop    %esi
   12a62:	5d                   	pop    %ebp
   12a63:	c3                   	ret    

00012a64 <strlen>:
**
** @param str The string to examine
**
** @return The length of the string, or 0
*/
uint32_t strlen( register const char *str ) {
   12a64:	55                   	push   %ebp
   12a65:	89 e5                	mov    %esp,%ebp
   12a67:	53                   	push   %ebx
   12a68:	8b 55 08             	mov    0x8(%ebp),%edx
	register uint32_t len = 0;
   12a6b:	bb 00 00 00 00       	mov    $0x0,%ebx

	while( *str++ ) {
   12a70:	eb 03                	jmp    12a75 <strlen+0x11>
		++len;
   12a72:	83 c3 01             	add    $0x1,%ebx
	while( *str++ ) {
   12a75:	89 d0                	mov    %edx,%eax
   12a77:	8d 50 01             	lea    0x1(%eax),%edx
   12a7a:	0f b6 00             	movzbl (%eax),%eax
   12a7d:	84 c0                	test   %al,%al
   12a7f:	75 f1                	jne    12a72 <strlen+0xe>
	}

	return( len );
   12a81:	89 d8                	mov    %ebx,%eax
}
   12a83:	5b                   	pop    %ebx
   12a84:	5d                   	pop    %ebp
   12a85:	c3                   	ret    

00012a86 <add_block>:
** Add a block to the free list
**
** @param base   Base address of the block
** @param length Block length, in bytes
*/
static void add_block( uint32_t base, uint32_t length ) {
   12a86:	55                   	push   %ebp
   12a87:	89 e5                	mov    %esp,%ebp
   12a89:	83 ec 18             	sub    $0x18,%esp

	// don't add it if it isn't at least 4K
	if( length < SZ_PAGE ) {
   12a8c:	81 7d 0c ff 0f 00 00 	cmpl   $0xfff,0xc(%ebp)
   12a93:	0f 86 f4 00 00 00    	jbe    12b8d <add_block+0x107>
#if ANY_KMEM
	cio_printf( "  add(%08x,%08x): ", base, length );
#endif

	// only want to add multiples of 4K; check the lower bits
	if( (length & 0xfff) != 0 ) {
   12a99:	8b 45 0c             	mov    0xc(%ebp),%eax
   12a9c:	25 ff 0f 00 00       	and    $0xfff,%eax
   12aa1:	85 c0                	test   %eax,%eax
   12aa3:	74 07                	je     12aac <add_block+0x26>
		// round it down to 4K
		length &= 0xfffff000;
   12aa5:	81 65 0c 00 f0 ff ff 	andl   $0xfffff000,0xc(%ebp)
	cio_printf( " --> base %08x length %08x", base, length );
#endif

	// create the "block"

	Blockinfo *block = (Blockinfo *) base;
   12aac:	8b 45 08             	mov    0x8(%ebp),%eax
   12aaf:	89 45 ec             	mov    %eax,-0x14(%ebp)
	block->pages = B2P(length);
   12ab2:	8b 45 0c             	mov    0xc(%ebp),%eax
   12ab5:	c1 e8 0c             	shr    $0xc,%eax
   12ab8:	89 c2                	mov    %eax,%edx
   12aba:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12abd:	89 10                	mov    %edx,(%eax)
	block->next = NULL;
   12abf:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12ac2:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	** coalescing adjacent free blocks.
	**
	** Handle the easiest case first.
	*/

	if( free_pages == NULL ) {
   12ac9:	a1 14 e1 01 00       	mov    0x1e114,%eax
   12ace:	85 c0                	test   %eax,%eax
   12ad0:	75 17                	jne    12ae9 <add_block+0x63>
		free_pages = block;
   12ad2:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12ad5:	a3 14 e1 01 00       	mov    %eax,0x1e114
		n_pages = block->pages;
   12ada:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12add:	8b 00                	mov    (%eax),%eax
   12adf:	a3 1c e1 01 00       	mov    %eax,0x1e11c
		return;
   12ae4:	e9 a5 00 00 00       	jmp    12b8e <add_block+0x108>
	** Find the correct insertion spot.
	*/

	Blockinfo *prev, *curr;

	prev = NULL;
   12ae9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	curr = free_pages;
   12af0:	a1 14 e1 01 00       	mov    0x1e114,%eax
   12af5:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr && curr < block ) {
   12af8:	eb 0f                	jmp    12b09 <add_block+0x83>
		prev = curr;
   12afa:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12afd:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   12b00:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12b03:	8b 40 04             	mov    0x4(%eax),%eax
   12b06:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr && curr < block ) {
   12b09:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12b0d:	74 08                	je     12b17 <add_block+0x91>
   12b0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12b12:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   12b15:	72 e3                	jb     12afa <add_block+0x74>
	}

	// the new block always points to its successor
	block->next = curr;
   12b17:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12b1a:	8b 55 f0             	mov    -0x10(%ebp),%edx
   12b1d:	89 50 04             	mov    %edx,0x4(%eax)
	/*
	** If prev is NULL, we're adding at the front; otherwise,
	** we're adding after some other entry (middle or end).
	*/

	if( prev == NULL ) {
   12b20:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12b24:	75 4b                	jne    12b71 <add_block+0xeb>
		// sanity check - both pointers can't be NULL
		assert( curr );
   12b26:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12b2a:	75 3b                	jne    12b67 <add_block+0xe1>
   12b2c:	83 ec 04             	sub    $0x4,%esp
   12b2f:	68 90 ae 01 00       	push   $0x1ae90
   12b34:	6a 00                	push   $0x0
   12b36:	68 0d 01 00 00       	push   $0x10d
   12b3b:	68 95 ae 01 00       	push   $0x1ae95
   12b40:	68 8c af 01 00       	push   $0x1af8c
   12b45:	68 9c ae 01 00       	push   $0x1ae9c
   12b4a:	68 00 00 02 00       	push   $0x20000
   12b4f:	e8 93 fb ff ff       	call   126e7 <sprint>
   12b54:	83 c4 20             	add    $0x20,%esp
   12b57:	83 ec 0c             	sub    $0xc,%esp
   12b5a:	68 00 00 02 00       	push   $0x20000
   12b5f:	e8 03 f9 ff ff       	call   12467 <kpanic>
   12b64:	83 c4 10             	add    $0x10,%esp
		// add at the beginning
		free_pages = block;
   12b67:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12b6a:	a3 14 e1 01 00       	mov    %eax,0x1e114
   12b6f:	eb 09                	jmp    12b7a <add_block+0xf4>
	} else {
		// inserting in the middle or at the end
		prev->next = block;
   12b71:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12b74:	8b 55 ec             	mov    -0x14(%ebp),%edx
   12b77:	89 50 04             	mov    %edx,0x4(%eax)
	}

	// bump the count of available pages
	n_pages += block->pages;
   12b7a:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12b7d:	8b 10                	mov    (%eax),%edx
   12b7f:	a1 1c e1 01 00       	mov    0x1e11c,%eax
   12b84:	01 d0                	add    %edx,%eax
   12b86:	a3 1c e1 01 00       	mov    %eax,0x1e11c
   12b8b:	eb 01                	jmp    12b8e <add_block+0x108>
		return;
   12b8d:	90                   	nop
}
   12b8e:	c9                   	leave  
   12b8f:	c3                   	ret    

00012b90 <km_init>:
**
** Dependencies:
**    Must be called before any other init routine that uses
**    dynamic storage is called.
*/
void km_init( void ) {
   12b90:	55                   	push   %ebp
   12b91:	89 e5                	mov    %esp,%ebp
   12b93:	53                   	push   %ebx
   12b94:	83 ec 34             	sub    $0x34,%esp
	int32_t entries;
	region_t *region;

#if TRACING_INIT
	// announce that we're starting initialization
	cio_puts( " Kmem" );
   12b97:	83 ec 0c             	sub    $0xc,%esp
   12b9a:	68 b2 ae 01 00       	push   $0x1aeb2
   12b9f:	e8 09 e3 ff ff       	call   10ead <cio_puts>
   12ba4:	83 c4 10             	add    $0x10,%esp
#endif

	// initially, nothing in the free lists
	free_slices = NULL;
   12ba7:	c7 05 18 e1 01 00 00 	movl   $0x0,0x1e118
   12bae:	00 00 00 
	free_pages = NULL;
   12bb1:	c7 05 14 e1 01 00 00 	movl   $0x0,0x1e114
   12bb8:	00 00 00 
	n_pages = n_slices = 0;
   12bbb:	c7 05 20 e1 01 00 00 	movl   $0x0,0x1e120
   12bc2:	00 00 00 
   12bc5:	a1 20 e1 01 00       	mov    0x1e120,%eax
   12bca:	a3 1c e1 01 00       	mov    %eax,0x1e11c
	km_initialized = 0;
   12bcf:	c7 05 24 e1 01 00 00 	movl   $0x0,0x1e124
   12bd6:	00 00 00 

	// get the list length
	entries = *((int32_t *) MMAP_ADDR);
   12bd9:	b8 00 2d 00 00       	mov    $0x2d00,%eax
   12bde:	8b 00                	mov    (%eax),%eax
   12be0:	89 45 dc             	mov    %eax,-0x24(%ebp)
#if KMEM_OR_INIT
	cio_printf( "\nKmem: %d regions\n", entries );
#endif

	// if there are no entries, we have nothing to do!
	if( entries < 1 ) {  // note: entries == -1 could occur!
   12be3:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   12be7:	0f 8e 77 01 00 00    	jle    12d64 <km_init+0x1d4>
		return;
	}

	// iterate through the entries, adding things to the freelist

	region = ((region_t *) (MMAP_ADDR + 4));
   12bed:	c7 45 f4 04 2d 00 00 	movl   $0x2d04,-0xc(%ebp)

	for( int i = 0; i < entries; ++i, ++region ) {
   12bf4:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   12bfb:	e9 4c 01 00 00       	jmp    12d4c <km_init+0x1bc>
		** this to include ACPI "reclaimable" memory.
		*/

		// first, check the ACPI one-bit flags

		if( ((region->acpi) & REGION_IGNORE) == 0 ) {
   12c00:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c03:	8b 40 14             	mov    0x14(%eax),%eax
   12c06:	83 e0 01             	and    $0x1,%eax
   12c09:	85 c0                	test   %eax,%eax
   12c0b:	0f 84 26 01 00 00    	je     12d37 <km_init+0x1a7>
			cio_puts( " IGN\n" );
#endif
			continue;
		}

		if( ((region->acpi) & REGION_NONVOL) != 0 ) {
   12c11:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c14:	8b 40 14             	mov    0x14(%eax),%eax
   12c17:	83 e0 02             	and    $0x2,%eax
   12c1a:	85 c0                	test   %eax,%eax
   12c1c:	0f 85 18 01 00 00    	jne    12d3a <km_init+0x1aa>
			continue;  // we'll ignore this, too
		}

		// next, the region type

		if( (region->type) != REGION_USABLE ) {
   12c22:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c25:	8b 40 10             	mov    0x10(%eax),%eax
   12c28:	83 f8 01             	cmp    $0x1,%eax
   12c2b:	0f 85 0c 01 00 00    	jne    12d3d <km_init+0x1ad>
		** split it, and only use the portion that's within those
		** bounds.
		*/

		// grab the two 64-bit values to simplify things
		uint64_t base   = region->base.all;
   12c31:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c34:	8b 50 04             	mov    0x4(%eax),%edx
   12c37:	8b 00                	mov    (%eax),%eax
   12c39:	89 45 e8             	mov    %eax,-0x18(%ebp)
   12c3c:	89 55 ec             	mov    %edx,-0x14(%ebp)
		uint64_t length = region->length.all;
   12c3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c42:	8b 50 0c             	mov    0xc(%eax),%edx
   12c45:	8b 40 08             	mov    0x8(%eax),%eax
   12c48:	89 45 d0             	mov    %eax,-0x30(%ebp)
   12c4b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		uint64_t endpt  = base + length;
   12c4e:	8b 4d e8             	mov    -0x18(%ebp),%ecx
   12c51:	8b 5d ec             	mov    -0x14(%ebp),%ebx
   12c54:	8b 45 d0             	mov    -0x30(%ebp),%eax
   12c57:	8b 55 d4             	mov    -0x2c(%ebp),%edx
   12c5a:	01 c8                	add    %ecx,%eax
   12c5c:	11 da                	adc    %ebx,%edx
   12c5e:	89 45 e0             	mov    %eax,-0x20(%ebp)
   12c61:	89 55 e4             	mov    %edx,-0x1c(%ebp)

		// see if it's above our arbitrary high cutoff point
		if( base >= KM_HIGH_CUTOFF || endpt >= KM_HIGH_CUTOFF ) {
   12c64:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12c68:	77 24                	ja     12c8e <km_init+0xfe>
   12c6a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12c6e:	72 09                	jb     12c79 <km_init+0xe9>
   12c70:	81 7d e8 ff ff ff 3f 	cmpl   $0x3fffffff,-0x18(%ebp)
   12c77:	77 15                	ja     12c8e <km_init+0xfe>
   12c79:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12c7d:	72 3a                	jb     12cb9 <km_init+0x129>
   12c7f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12c83:	77 09                	ja     12c8e <km_init+0xfe>
   12c85:	81 7d e0 ff ff ff 3f 	cmpl   $0x3fffffff,-0x20(%ebp)
   12c8c:	76 2b                	jbe    12cb9 <km_init+0x129>

			// is the whole thing too high, or just part?
			if( base > KM_HIGH_CUTOFF ) {
   12c8e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12c92:	72 17                	jb     12cab <km_init+0x11b>
   12c94:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12c98:	0f 87 a2 00 00 00    	ja     12d40 <km_init+0x1b0>
   12c9e:	81 7d e8 00 00 00 40 	cmpl   $0x40000000,-0x18(%ebp)
   12ca5:	0f 87 95 00 00 00    	ja     12d40 <km_init+0x1b0>
#endif
				continue;
			}

			// some of it is usable - fix the end point
			endpt = KM_HIGH_CUTOFF;
   12cab:	c7 45 e0 00 00 00 40 	movl   $0x40000000,-0x20(%ebp)
   12cb2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		}

		// see if it's below our low cutoff point
		if( base < KM_LOW_CUTOFF || endpt < KM_LOW_CUTOFF ) {
   12cb9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12cbd:	72 24                	jb     12ce3 <km_init+0x153>
   12cbf:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12cc3:	77 09                	ja     12cce <km_init+0x13e>
   12cc5:	81 7d e8 ff ff 0f 00 	cmpl   $0xfffff,-0x18(%ebp)
   12ccc:	76 15                	jbe    12ce3 <km_init+0x153>
   12cce:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12cd2:	77 32                	ja     12d06 <km_init+0x176>
   12cd4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12cd8:	72 09                	jb     12ce3 <km_init+0x153>
   12cda:	81 7d e0 ff ff 0f 00 	cmpl   $0xfffff,-0x20(%ebp)
   12ce1:	77 23                	ja     12d06 <km_init+0x176>

			// is the whole thing too low, or just part?
			if( endpt < KM_LOW_CUTOFF ) {
   12ce3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12ce7:	77 0f                	ja     12cf8 <km_init+0x168>
   12ce9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12ced:	72 54                	jb     12d43 <km_init+0x1b3>
   12cef:	81 7d e0 ff ff 0f 00 	cmpl   $0xfffff,-0x20(%ebp)
   12cf6:	76 4b                	jbe    12d43 <km_init+0x1b3>
#endif
				continue;
			}

			// some of it is usable - fix the starting point
			base = KM_LOW_CUTOFF;
   12cf8:	c7 45 e8 00 00 10 00 	movl   $0x100000,-0x18(%ebp)
   12cff:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
		}

		// recalculate the length
		length = endpt - base;
   12d06:	8b 45 e0             	mov    -0x20(%ebp),%eax
   12d09:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   12d0c:	2b 45 e8             	sub    -0x18(%ebp),%eax
   12d0f:	1b 55 ec             	sbb    -0x14(%ebp),%edx
   12d12:	89 45 d0             	mov    %eax,-0x30(%ebp)
   12d15:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		cio_puts( " OK\n" );
#endif

		// we survived the gauntlet - add the new block

		uint32_t b32 = base   & ADDR_LOW_HALF;
   12d18:	8b 45 e8             	mov    -0x18(%ebp),%eax
   12d1b:	89 45 cc             	mov    %eax,-0x34(%ebp)
		uint32_t l32 = length & ADDR_LOW_HALF;
   12d1e:	8b 45 d0             	mov    -0x30(%ebp),%eax
   12d21:	89 45 c8             	mov    %eax,-0x38(%ebp)

		add_block( b32, l32 );
   12d24:	83 ec 08             	sub    $0x8,%esp
   12d27:	ff 75 c8             	pushl  -0x38(%ebp)
   12d2a:	ff 75 cc             	pushl  -0x34(%ebp)
   12d2d:	e8 54 fd ff ff       	call   12a86 <add_block>
   12d32:	83 c4 10             	add    $0x10,%esp
   12d35:	eb 0d                	jmp    12d44 <km_init+0x1b4>
			continue;
   12d37:	90                   	nop
   12d38:	eb 0a                	jmp    12d44 <km_init+0x1b4>
			continue;  // we'll ignore this, too
   12d3a:	90                   	nop
   12d3b:	eb 07                	jmp    12d44 <km_init+0x1b4>
			continue;  // we won't attempt to reclaim ACPI memory (yet)
   12d3d:	90                   	nop
   12d3e:	eb 04                	jmp    12d44 <km_init+0x1b4>
				continue;
   12d40:	90                   	nop
   12d41:	eb 01                	jmp    12d44 <km_init+0x1b4>
				continue;
   12d43:	90                   	nop
	for( int i = 0; i < entries; ++i, ++region ) {
   12d44:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   12d48:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
   12d4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12d4f:	3b 45 dc             	cmp    -0x24(%ebp),%eax
   12d52:	0f 8c a8 fe ff ff    	jl     12c00 <km_init+0x70>
	}

	// record the initialization
	km_initialized = 1;
   12d58:	c7 05 24 e1 01 00 01 	movl   $0x1,0x1e124
   12d5f:	00 00 00 
   12d62:	eb 01                	jmp    12d65 <km_init+0x1d5>
		return;
   12d64:	90                   	nop
#if KMEM_OR_INIT
	delay( DELAY_1_SEC );
#endif
}
   12d65:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   12d68:	c9                   	leave  
   12d69:	c3                   	ret    

00012d6a <km_dump>:
/**
** Name:    km_dump
**
** Dump the current contents of the free list to the console
*/
void km_dump( void ) {
   12d6a:	55                   	push   %ebp
   12d6b:	89 e5                	mov    %esp,%ebp
   12d6d:	53                   	push   %ebx
   12d6e:	83 ec 14             	sub    $0x14,%esp
	Blockinfo *block;

	cio_printf( "&free_pages=%08x, &free_slices %08x, %u pages, %u slices\n",
   12d71:	8b 15 20 e1 01 00    	mov    0x1e120,%edx
   12d77:	a1 1c e1 01 00       	mov    0x1e11c,%eax
   12d7c:	bb 18 e1 01 00       	mov    $0x1e118,%ebx
   12d81:	b9 14 e1 01 00       	mov    $0x1e114,%ecx
   12d86:	83 ec 0c             	sub    $0xc,%esp
   12d89:	52                   	push   %edx
   12d8a:	50                   	push   %eax
   12d8b:	53                   	push   %ebx
   12d8c:	51                   	push   %ecx
   12d8d:	68 b8 ae 01 00       	push   $0x1aeb8
   12d92:	e8 90 e7 ff ff       	call   11527 <cio_printf>
   12d97:	83 c4 20             	add    $0x20,%esp
			(uint32_t) &free_pages, (uint32_t) &free_slices,
			n_pages, n_slices );

	for( block = free_pages; block != NULL; block = block->next ) {
   12d9a:	a1 14 e1 01 00       	mov    0x1e114,%eax
   12d9f:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12da2:	eb 39                	jmp    12ddd <km_dump+0x73>
		cio_printf(
   12da4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12da7:	8b 50 04             	mov    0x4(%eax),%edx
			"block @ 0x%08x 0x%08x pages (ends at 0x%08x) next @ 0x%08x\n",
				block, block->pages, P2B(block->pages) + (uint32_t) block,
   12daa:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12dad:	8b 00                	mov    (%eax),%eax
   12daf:	c1 e0 0c             	shl    $0xc,%eax
   12db2:	89 c1                	mov    %eax,%ecx
   12db4:	8b 45 f4             	mov    -0xc(%ebp),%eax
		cio_printf(
   12db7:	01 c1                	add    %eax,%ecx
   12db9:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12dbc:	8b 00                	mov    (%eax),%eax
   12dbe:	83 ec 0c             	sub    $0xc,%esp
   12dc1:	52                   	push   %edx
   12dc2:	51                   	push   %ecx
   12dc3:	50                   	push   %eax
   12dc4:	ff 75 f4             	pushl  -0xc(%ebp)
   12dc7:	68 f4 ae 01 00       	push   $0x1aef4
   12dcc:	e8 56 e7 ff ff       	call   11527 <cio_printf>
   12dd1:	83 c4 20             	add    $0x20,%esp
	for( block = free_pages; block != NULL; block = block->next ) {
   12dd4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12dd7:	8b 40 04             	mov    0x4(%eax),%eax
   12dda:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12ddd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12de1:	75 c1                	jne    12da4 <km_dump+0x3a>
				block->next );
	}

	for( block = free_slices; block != NULL; block = block->next ) {
   12de3:	a1 18 e1 01 00       	mov    0x1e118,%eax
   12de8:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12deb:	eb 39                	jmp    12e26 <km_dump+0xbc>
		cio_printf(
   12ded:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12df0:	8b 50 04             	mov    0x4(%eax),%edx
			"block @ 0x%08x 0x%08x slices (ends at 0x%08x) next @ 0x%08x\n",
				block, block->pages, P2B(block->pages) + (uint32_t) block,
   12df3:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12df6:	8b 00                	mov    (%eax),%eax
   12df8:	c1 e0 0c             	shl    $0xc,%eax
   12dfb:	89 c1                	mov    %eax,%ecx
   12dfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
		cio_printf(
   12e00:	01 c1                	add    %eax,%ecx
   12e02:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12e05:	8b 00                	mov    (%eax),%eax
   12e07:	83 ec 0c             	sub    $0xc,%esp
   12e0a:	52                   	push   %edx
   12e0b:	51                   	push   %ecx
   12e0c:	50                   	push   %eax
   12e0d:	ff 75 f4             	pushl  -0xc(%ebp)
   12e10:	68 30 af 01 00       	push   $0x1af30
   12e15:	e8 0d e7 ff ff       	call   11527 <cio_printf>
   12e1a:	83 c4 20             	add    $0x20,%esp
	for( block = free_slices; block != NULL; block = block->next ) {
   12e1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12e20:	8b 40 04             	mov    0x4(%eax),%eax
   12e23:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12e26:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12e2a:	75 c1                	jne    12ded <km_dump+0x83>
				block->next );
	}

}
   12e2c:	90                   	nop
   12e2d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   12e30:	c9                   	leave  
   12e31:	c3                   	ret    

00012e32 <km_page_alloc>:
** @param count  Number of contiguous pages desired
**
** @return a pointer to the beginning of the first allocated page,
**         or NULL if no memory is available
*/
void *km_page_alloc( unsigned int count ) {
   12e32:	55                   	push   %ebp
   12e33:	89 e5                	mov    %esp,%ebp
   12e35:	83 ec 28             	sub    $0x28,%esp

	assert( km_initialized );
   12e38:	a1 24 e1 01 00       	mov    0x1e124,%eax
   12e3d:	85 c0                	test   %eax,%eax
   12e3f:	75 3b                	jne    12e7c <km_page_alloc+0x4a>
   12e41:	83 ec 04             	sub    $0x4,%esp
   12e44:	68 6d af 01 00       	push   $0x1af6d
   12e49:	6a 00                	push   $0x0
   12e4b:	68 ee 01 00 00       	push   $0x1ee
   12e50:	68 95 ae 01 00       	push   $0x1ae95
   12e55:	68 98 af 01 00       	push   $0x1af98
   12e5a:	68 9c ae 01 00       	push   $0x1ae9c
   12e5f:	68 00 00 02 00       	push   $0x20000
   12e64:	e8 7e f8 ff ff       	call   126e7 <sprint>
   12e69:	83 c4 20             	add    $0x20,%esp
   12e6c:	83 ec 0c             	sub    $0xc,%esp
   12e6f:	68 00 00 02 00       	push   $0x20000
   12e74:	e8 ee f5 ff ff       	call   12467 <kpanic>
   12e79:	83 c4 10             	add    $0x10,%esp

	// make sure we actually need to do something!
	if( count < 1 ) {
   12e7c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12e80:	75 0a                	jne    12e8c <km_page_alloc+0x5a>
		return( NULL );
   12e82:	b8 00 00 00 00       	mov    $0x0,%eax
   12e87:	e9 a9 00 00 00       	jmp    12f35 <km_page_alloc+0x103>
	/*
	** Look for the first entry that is large enough.
	*/

	// pointer to the current block
	Blockinfo *block = free_pages;
   12e8c:	a1 14 e1 01 00       	mov    0x1e114,%eax
   12e91:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// pointer to where the pointer to the current block is
	Blockinfo **pointer = &free_pages;
   12e94:	c7 45 f0 14 e1 01 00 	movl   $0x1e114,-0x10(%ebp)

	while( block != NULL && block->pages < count ){
   12e9b:	eb 11                	jmp    12eae <km_page_alloc+0x7c>
		pointer = &block->next;
   12e9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ea0:	83 c0 04             	add    $0x4,%eax
   12ea3:	89 45 f0             	mov    %eax,-0x10(%ebp)
		block = *pointer;
   12ea6:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12ea9:	8b 00                	mov    (%eax),%eax
   12eab:	89 45 f4             	mov    %eax,-0xc(%ebp)
	while( block != NULL && block->pages < count ){
   12eae:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12eb2:	74 0a                	je     12ebe <km_page_alloc+0x8c>
   12eb4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12eb7:	8b 00                	mov    (%eax),%eax
   12eb9:	39 45 08             	cmp    %eax,0x8(%ebp)
   12ebc:	77 df                	ja     12e9d <km_page_alloc+0x6b>
	}

	// did we find a big enough block?
	if( block == NULL ){
   12ebe:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12ec2:	75 07                	jne    12ecb <km_page_alloc+0x99>
		// nope!
		return( NULL );
   12ec4:	b8 00 00 00 00       	mov    $0x0,%eax
   12ec9:	eb 6a                	jmp    12f35 <km_page_alloc+0x103>
	}

	// found one!  check the length

	if( block->pages == count ) {
   12ecb:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ece:	8b 00                	mov    (%eax),%eax
   12ed0:	39 45 08             	cmp    %eax,0x8(%ebp)
   12ed3:	75 0d                	jne    12ee2 <km_page_alloc+0xb0>

		// exactly the right size - unlink it from the list

		*pointer = block->next;
   12ed5:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ed8:	8b 50 04             	mov    0x4(%eax),%edx
   12edb:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12ede:	89 10                	mov    %edx,(%eax)
   12ee0:	eb 43                	jmp    12f25 <km_page_alloc+0xf3>

		// bigger than we need - carve the amount we need off
		// the beginning of this block

		// remember where this chunk begins
		Blockinfo *chunk = block;
   12ee2:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ee5:	89 45 ec             	mov    %eax,-0x14(%ebp)

		// how much space will be left over?
		int excess = block->pages - count;
   12ee8:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12eeb:	8b 00                	mov    (%eax),%eax
   12eed:	2b 45 08             	sub    0x8(%ebp),%eax
   12ef0:	89 45 e8             	mov    %eax,-0x18(%ebp)

		// find the start of the new fragment
		Blockinfo *fragment = (Blockinfo *) ( (uint8_t *) block + P2B(count) );
   12ef3:	8b 45 08             	mov    0x8(%ebp),%eax
   12ef6:	c1 e0 0c             	shl    $0xc,%eax
   12ef9:	89 c2                	mov    %eax,%edx
   12efb:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12efe:	01 d0                	add    %edx,%eax
   12f00:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// set the length and link for the new fragment
		fragment->pages = excess;
   12f03:	8b 55 e8             	mov    -0x18(%ebp),%edx
   12f06:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   12f09:	89 10                	mov    %edx,(%eax)
		fragment->next  = block->next;
   12f0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12f0e:	8b 50 04             	mov    0x4(%eax),%edx
   12f11:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   12f14:	89 50 04             	mov    %edx,0x4(%eax)

		// replace this chunk with the fragment
		*pointer = fragment;
   12f17:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12f1a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   12f1d:	89 10                	mov    %edx,(%eax)

		// return this chunk
		block = chunk;
   12f1f:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12f22:	89 45 f4             	mov    %eax,-0xc(%ebp)
	}

	// fix the count of available pages
	n_pages -= count;;
   12f25:	a1 1c e1 01 00       	mov    0x1e11c,%eax
   12f2a:	2b 45 08             	sub    0x8(%ebp),%eax
   12f2d:	a3 1c e1 01 00       	mov    %eax,0x1e11c

	return( block );
   12f32:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   12f35:	c9                   	leave  
   12f36:	c3                   	ret    

00012f37 <km_page_free>:
** CRITICAL NOTE:  multi-page blocks must be freed one page
** at a time OR freed using km_page_free_multi()!
**
** @param block   Pointer to the page to be returned to the free list
*/
void km_page_free( void *block ) {
   12f37:	55                   	push   %ebp
   12f38:	89 e5                	mov    %esp,%ebp
   12f3a:	83 ec 08             	sub    $0x8,%esp

	/*
	** Don't do anything if the address is NULL.
	*/
	if( block == NULL ){
   12f3d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12f41:	74 12                	je     12f55 <km_page_free+0x1e>
		return;
	}

	km_page_free_multi( block, 1 );
   12f43:	83 ec 08             	sub    $0x8,%esp
   12f46:	6a 01                	push   $0x1
   12f48:	ff 75 08             	pushl  0x8(%ebp)
   12f4b:	e8 08 00 00 00       	call   12f58 <km_page_free_multi>
   12f50:	83 c4 10             	add    $0x10,%esp
   12f53:	eb 01                	jmp    12f56 <km_page_free+0x1f>
		return;
   12f55:	90                   	nop
}
   12f56:	c9                   	leave  
   12f57:	c3                   	ret    

00012f58 <km_page_free_multi>:
** accepts a pointer to a multi-page block of memory.
**
** @param block   Pointer to the block to be returned to the free list
** @param count   Number of pages in the block
*/
void km_page_free_multi( void *block, uint32_t count ) {
   12f58:	55                   	push   %ebp
   12f59:	89 e5                	mov    %esp,%ebp
   12f5b:	83 ec 18             	sub    $0x18,%esp
	Blockinfo *used;
	Blockinfo *prev;
	Blockinfo *curr;

	assert( km_initialized );
   12f5e:	a1 24 e1 01 00       	mov    0x1e124,%eax
   12f63:	85 c0                	test   %eax,%eax
   12f65:	75 3b                	jne    12fa2 <km_page_free_multi+0x4a>
   12f67:	83 ec 04             	sub    $0x4,%esp
   12f6a:	68 6d af 01 00       	push   $0x1af6d
   12f6f:	6a 00                	push   $0x0
   12f71:	68 57 02 00 00       	push   $0x257
   12f76:	68 95 ae 01 00       	push   $0x1ae95
   12f7b:	68 a8 af 01 00       	push   $0x1afa8
   12f80:	68 9c ae 01 00       	push   $0x1ae9c
   12f85:	68 00 00 02 00       	push   $0x20000
   12f8a:	e8 58 f7 ff ff       	call   126e7 <sprint>
   12f8f:	83 c4 20             	add    $0x20,%esp
   12f92:	83 ec 0c             	sub    $0xc,%esp
   12f95:	68 00 00 02 00       	push   $0x20000
   12f9a:	e8 c8 f4 ff ff       	call   12467 <kpanic>
   12f9f:	83 c4 10             	add    $0x10,%esp

	/*
	** Don't do anything if the address is NULL.
	*/
	if( block == NULL ){
   12fa2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12fa6:	0f 84 e3 00 00 00    	je     1308f <km_page_free_multi+0x137>
		return;
	}

	used = (Blockinfo *) block;
   12fac:	8b 45 08             	mov    0x8(%ebp),%eax
   12faf:	89 45 f4             	mov    %eax,-0xc(%ebp)
	used->pages = count;
   12fb2:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12fb5:	8b 55 0c             	mov    0xc(%ebp),%edx
   12fb8:	89 10                	mov    %edx,(%eax)

	/*
	** Advance through the list until current and previous
	** straddle the place where the new block should be inserted.
	*/
	prev = NULL;
   12fba:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	curr = free_pages;
   12fc1:	a1 14 e1 01 00       	mov    0x1e114,%eax
   12fc6:	89 45 ec             	mov    %eax,-0x14(%ebp)

	while( curr != NULL && curr < used ){
   12fc9:	eb 0f                	jmp    12fda <km_page_free_multi+0x82>
		prev = curr;
   12fcb:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12fce:	89 45 f0             	mov    %eax,-0x10(%ebp)
		curr = curr->next;
   12fd1:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12fd4:	8b 40 04             	mov    0x4(%eax),%eax
   12fd7:	89 45 ec             	mov    %eax,-0x14(%ebp)
	while( curr != NULL && curr < used ){
   12fda:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12fde:	74 08                	je     12fe8 <km_page_free_multi+0x90>
   12fe0:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12fe3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   12fe6:	72 e3                	jb     12fcb <km_page_free_multi+0x73>

	/*
	** If this is not the first block in the resulting list,
	** we may need to merge it with its predecessor.
	*/
	if( prev != NULL ){
   12fe8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12fec:	74 44                	je     13032 <km_page_free_multi+0xda>

		// There is a predecessor.  Check to see if we need to merge.
		if( adjacent( prev, used ) ){
   12fee:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12ff1:	8b 00                	mov    (%eax),%eax
   12ff3:	c1 e0 0c             	shl    $0xc,%eax
   12ff6:	89 c2                	mov    %eax,%edx
   12ff8:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12ffb:	01 d0                	add    %edx,%eax
   12ffd:	39 45 f4             	cmp    %eax,-0xc(%ebp)
   13000:	75 19                	jne    1301b <km_page_free_multi+0xc3>

			// yes - merge them
			prev->pages += used->pages;
   13002:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13005:	8b 10                	mov    (%eax),%edx
   13007:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1300a:	8b 00                	mov    (%eax),%eax
   1300c:	01 c2                	add    %eax,%edx
   1300e:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13011:	89 10                	mov    %edx,(%eax)

			// the predecessor becomes the "newly inserted" block,
			// because we still need to check to see if we should
			// merge with the successor
			used = prev;
   13013:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13016:	89 45 f4             	mov    %eax,-0xc(%ebp)
   13019:	eb 2b                	jmp    13046 <km_page_free_multi+0xee>

		} else {

			// Not adjacent - just insert the new block
			// between the predecessor and the successor.
			used->next = prev->next;
   1301b:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1301e:	8b 50 04             	mov    0x4(%eax),%edx
   13021:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13024:	89 50 04             	mov    %edx,0x4(%eax)
			prev->next = used;
   13027:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1302a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1302d:	89 50 04             	mov    %edx,0x4(%eax)
   13030:	eb 14                	jmp    13046 <km_page_free_multi+0xee>
		}

	} else {

		// Yes, it is first.  Update the list pointer to insert it.
		used->next = free_pages;
   13032:	8b 15 14 e1 01 00    	mov    0x1e114,%edx
   13038:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1303b:	89 50 04             	mov    %edx,0x4(%eax)
		free_pages = used;
   1303e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13041:	a3 14 e1 01 00       	mov    %eax,0x1e114

	/*
	** If this is not the last block in the resulting list,
	** we may (also) need to merge it with its successor.
	*/
	if( curr != NULL ){
   13046:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   1304a:	74 31                	je     1307d <km_page_free_multi+0x125>

		// No.  Check to see if it should be merged with the successor.
		if( adjacent( used, curr ) ){
   1304c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1304f:	8b 00                	mov    (%eax),%eax
   13051:	c1 e0 0c             	shl    $0xc,%eax
   13054:	89 c2                	mov    %eax,%edx
   13056:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13059:	01 d0                	add    %edx,%eax
   1305b:	39 45 ec             	cmp    %eax,-0x14(%ebp)
   1305e:	75 1d                	jne    1307d <km_page_free_multi+0x125>

			// Yes, combine them.
			used->next = curr->next;
   13060:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13063:	8b 50 04             	mov    0x4(%eax),%edx
   13066:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13069:	89 50 04             	mov    %edx,0x4(%eax)
			used->pages += curr->pages;
   1306c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1306f:	8b 10                	mov    (%eax),%edx
   13071:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13074:	8b 00                	mov    (%eax),%eax
   13076:	01 c2                	add    %eax,%edx
   13078:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1307b:	89 10                	mov    %edx,(%eax)

		}
	}

	// more in the pool
	n_pages += count;
   1307d:	8b 15 1c e1 01 00    	mov    0x1e11c,%edx
   13083:	8b 45 0c             	mov    0xc(%ebp),%eax
   13086:	01 d0                	add    %edx,%eax
   13088:	a3 1c e1 01 00       	mov    %eax,0x1e11c
   1308d:	eb 01                	jmp    13090 <km_page_free_multi+0x138>
		return;
   1308f:	90                   	nop
}
   13090:	c9                   	leave  
   13091:	c3                   	ret    

00013092 <carve_slices>:
** Name:        carve_slices
**
** Allocate a page and split it into four slices;  If no
**              memory is available, we panic.
*/
static void carve_slices( void ) {
   13092:	55                   	push   %ebp
   13093:	89 e5                	mov    %esp,%ebp
   13095:	83 ec 18             	sub    $0x18,%esp
	void *page;

	// get a page
	page = km_page_alloc( 1 );
   13098:	83 ec 0c             	sub    $0xc,%esp
   1309b:	6a 01                	push   $0x1
   1309d:	e8 90 fd ff ff       	call   12e32 <km_page_alloc>
   130a2:	83 c4 10             	add    $0x10,%esp
   130a5:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// allocation failure is a show-stopping problem
	assert( page );
   130a8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   130ac:	75 3b                	jne    130e9 <carve_slices+0x57>
   130ae:	83 ec 04             	sub    $0x4,%esp
   130b1:	68 7c af 01 00       	push   $0x1af7c
   130b6:	6a 00                	push   $0x0
   130b8:	68 c8 02 00 00       	push   $0x2c8
   130bd:	68 95 ae 01 00       	push   $0x1ae95
   130c2:	68 bc af 01 00       	push   $0x1afbc
   130c7:	68 9c ae 01 00       	push   $0x1ae9c
   130cc:	68 00 00 02 00       	push   $0x20000
   130d1:	e8 11 f6 ff ff       	call   126e7 <sprint>
   130d6:	83 c4 20             	add    $0x20,%esp
   130d9:	83 ec 0c             	sub    $0xc,%esp
   130dc:	68 00 00 02 00       	push   $0x20000
   130e1:	e8 81 f3 ff ff       	call   12467 <kpanic>
   130e6:	83 c4 10             	add    $0x10,%esp

	// we have the page; create the four slices from it
	uint8_t *ptr = (uint8_t *) page;
   130e9:	8b 45 ec             	mov    -0x14(%ebp),%eax
   130ec:	89 45 f4             	mov    %eax,-0xc(%ebp)
	for( int i = 0; i < 4; ++i ) {
   130ef:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   130f6:	eb 26                	jmp    1311e <carve_slices+0x8c>
		km_slice_free( (void *) ptr );
   130f8:	83 ec 0c             	sub    $0xc,%esp
   130fb:	ff 75 f4             	pushl  -0xc(%ebp)
   130fe:	e8 f5 00 00 00       	call   131f8 <km_slice_free>
   13103:	83 c4 10             	add    $0x10,%esp
		ptr += SZ_SLICE;
   13106:	81 45 f4 00 04 00 00 	addl   $0x400,-0xc(%ebp)
		++n_slices;
   1310d:	a1 20 e1 01 00       	mov    0x1e120,%eax
   13112:	83 c0 01             	add    $0x1,%eax
   13115:	a3 20 e1 01 00       	mov    %eax,0x1e120
	for( int i = 0; i < 4; ++i ) {
   1311a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   1311e:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
   13122:	7e d4                	jle    130f8 <carve_slices+0x66>
	}
}
   13124:	90                   	nop
   13125:	c9                   	leave  
   13126:	c3                   	ret    

00013127 <km_slice_alloc>:
** Dynamically allocates a slice (1/4 of a page).  If no
** memory is available, we panic.
**
** @return a pointer to the allocated slice
*/
void *km_slice_alloc( void ) {
   13127:	55                   	push   %ebp
   13128:	89 e5                	mov    %esp,%ebp
   1312a:	83 ec 18             	sub    $0x18,%esp
	Blockinfo *slice;

	assert( km_initialized );
   1312d:	a1 24 e1 01 00       	mov    0x1e124,%eax
   13132:	85 c0                	test   %eax,%eax
   13134:	75 3b                	jne    13171 <km_slice_alloc+0x4a>
   13136:	83 ec 04             	sub    $0x4,%esp
   13139:	68 6d af 01 00       	push   $0x1af6d
   1313e:	6a 00                	push   $0x0
   13140:	68 de 02 00 00       	push   $0x2de
   13145:	68 95 ae 01 00       	push   $0x1ae95
   1314a:	68 cc af 01 00       	push   $0x1afcc
   1314f:	68 9c ae 01 00       	push   $0x1ae9c
   13154:	68 00 00 02 00       	push   $0x20000
   13159:	e8 89 f5 ff ff       	call   126e7 <sprint>
   1315e:	83 c4 20             	add    $0x20,%esp
   13161:	83 ec 0c             	sub    $0xc,%esp
   13164:	68 00 00 02 00       	push   $0x20000
   13169:	e8 f9 f2 ff ff       	call   12467 <kpanic>
   1316e:	83 c4 10             	add    $0x10,%esp

	// if we are out of slices, create a few more
	if( free_slices == NULL ) {
   13171:	a1 18 e1 01 00       	mov    0x1e118,%eax
   13176:	85 c0                	test   %eax,%eax
   13178:	75 05                	jne    1317f <km_slice_alloc+0x58>
		carve_slices();
   1317a:	e8 13 ff ff ff       	call   13092 <carve_slices>
	}

	// take the first one from the free list
	slice = free_slices;
   1317f:	a1 18 e1 01 00       	mov    0x1e118,%eax
   13184:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert( slice != NULL );
   13187:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1318b:	75 3b                	jne    131c8 <km_slice_alloc+0xa1>
   1318d:	83 ec 04             	sub    $0x4,%esp
   13190:	68 81 af 01 00       	push   $0x1af81
   13195:	6a 00                	push   $0x0
   13197:	68 e7 02 00 00       	push   $0x2e7
   1319c:	68 95 ae 01 00       	push   $0x1ae95
   131a1:	68 cc af 01 00       	push   $0x1afcc
   131a6:	68 9c ae 01 00       	push   $0x1ae9c
   131ab:	68 00 00 02 00       	push   $0x20000
   131b0:	e8 32 f5 ff ff       	call   126e7 <sprint>
   131b5:	83 c4 20             	add    $0x20,%esp
   131b8:	83 ec 0c             	sub    $0xc,%esp
   131bb:	68 00 00 02 00       	push   $0x20000
   131c0:	e8 a2 f2 ff ff       	call   12467 <kpanic>
   131c5:	83 c4 10             	add    $0x10,%esp
	--n_slices;
   131c8:	a1 20 e1 01 00       	mov    0x1e120,%eax
   131cd:	83 e8 01             	sub    $0x1,%eax
   131d0:	a3 20 e1 01 00       	mov    %eax,0x1e120

	// unlink it
	free_slices = slice->next;
   131d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
   131d8:	8b 40 04             	mov    0x4(%eax),%eax
   131db:	a3 18 e1 01 00       	mov    %eax,0x1e118

	// make it nice and shiny for the caller
	memclr( (void *) slice, SZ_SLICE );
   131e0:	83 ec 08             	sub    $0x8,%esp
   131e3:	68 00 04 00 00       	push   $0x400
   131e8:	ff 75 f4             	pushl  -0xc(%ebp)
   131eb:	e8 74 f3 ff ff       	call   12564 <memclr>
   131f0:	83 c4 10             	add    $0x10,%esp

	return( slice );
   131f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   131f6:	c9                   	leave  
   131f7:	c3                   	ret    

000131f8 <km_slice_free>:
** We make no attempt to merge slices, as they are independent
** blocks of memory (unlike pages).
**
** @param block  Pointer to the slice (1/4 page) to be freed
*/
void km_slice_free( void *block ) {
   131f8:	55                   	push   %ebp
   131f9:	89 e5                	mov    %esp,%ebp
   131fb:	83 ec 18             	sub    $0x18,%esp
	Blockinfo *slice = (Blockinfo *) block;
   131fe:	8b 45 08             	mov    0x8(%ebp),%eax
   13201:	89 45 f4             	mov    %eax,-0xc(%ebp)

	assert( km_initialized );
   13204:	a1 24 e1 01 00       	mov    0x1e124,%eax
   13209:	85 c0                	test   %eax,%eax
   1320b:	75 3b                	jne    13248 <km_slice_free+0x50>
   1320d:	83 ec 04             	sub    $0x4,%esp
   13210:	68 6d af 01 00       	push   $0x1af6d
   13215:	6a 00                	push   $0x0
   13217:	68 00 03 00 00       	push   $0x300
   1321c:	68 95 ae 01 00       	push   $0x1ae95
   13221:	68 dc af 01 00       	push   $0x1afdc
   13226:	68 9c ae 01 00       	push   $0x1ae9c
   1322b:	68 00 00 02 00       	push   $0x20000
   13230:	e8 b2 f4 ff ff       	call   126e7 <sprint>
   13235:	83 c4 20             	add    $0x20,%esp
   13238:	83 ec 0c             	sub    $0xc,%esp
   1323b:	68 00 00 02 00       	push   $0x20000
   13240:	e8 22 f2 ff ff       	call   12467 <kpanic>
   13245:	83 c4 10             	add    $0x10,%esp

	// just add it to the front of the free list
	slice->pages = SZ_SLICE;
   13248:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1324b:	c7 00 00 04 00 00    	movl   $0x400,(%eax)
	slice->next = free_slices;
   13251:	8b 15 18 e1 01 00    	mov    0x1e118,%edx
   13257:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1325a:	89 50 04             	mov    %edx,0x4(%eax)
	free_slices = slice;
   1325d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13260:	a3 18 e1 01 00       	mov    %eax,0x1e118
	++n_slices;
   13265:	a1 20 e1 01 00       	mov    0x1e120,%eax
   1326a:	83 c0 01             	add    $0x1,%eax
   1326d:	a3 20 e1 01 00       	mov    %eax,0x1e120
}
   13272:	90                   	nop
   13273:	c9                   	leave  
   13274:	c3                   	ret    

00013275 <list_add>:
** Add the supplied data to the beginning of the specified list.
**
** @param[in,out] list  The address of a list_t variable
** @param[in] data      The data to prepend to the list
*/
void list_add( list_t *list, void *data ) {
   13275:	55                   	push   %ebp
   13276:	89 e5                	mov    %esp,%ebp
   13278:	83 ec 18             	sub    $0x18,%esp

	// sanity checks
	assert1( list != NULL );
   1327b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1327f:	75 38                	jne    132b9 <list_add+0x44>
   13281:	83 ec 04             	sub    $0x4,%esp
   13284:	68 ec af 01 00       	push   $0x1afec
   13289:	6a 01                	push   $0x1
   1328b:	6a 23                	push   $0x23
   1328d:	68 f6 af 01 00       	push   $0x1aff6
   13292:	68 20 b0 01 00       	push   $0x1b020
   13297:	68 fd af 01 00       	push   $0x1affd
   1329c:	68 00 00 02 00       	push   $0x20000
   132a1:	e8 41 f4 ff ff       	call   126e7 <sprint>
   132a6:	83 c4 20             	add    $0x20,%esp
   132a9:	83 ec 0c             	sub    $0xc,%esp
   132ac:	68 00 00 02 00       	push   $0x20000
   132b1:	e8 b1 f1 ff ff       	call   12467 <kpanic>
   132b6:	83 c4 10             	add    $0x10,%esp
	assert1( data != NULL );
   132b9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   132bd:	75 38                	jne    132f7 <list_add+0x82>
   132bf:	83 ec 04             	sub    $0x4,%esp
   132c2:	68 13 b0 01 00       	push   $0x1b013
   132c7:	6a 01                	push   $0x1
   132c9:	6a 24                	push   $0x24
   132cb:	68 f6 af 01 00       	push   $0x1aff6
   132d0:	68 20 b0 01 00       	push   $0x1b020
   132d5:	68 fd af 01 00       	push   $0x1affd
   132da:	68 00 00 02 00       	push   $0x20000
   132df:	e8 03 f4 ff ff       	call   126e7 <sprint>
   132e4:	83 c4 20             	add    $0x20,%esp
   132e7:	83 ec 0c             	sub    $0xc,%esp
   132ea:	68 00 00 02 00       	push   $0x20000
   132ef:	e8 73 f1 ff ff       	call   12467 <kpanic>
   132f4:	83 c4 10             	add    $0x10,%esp

	list_t *tmp = (list_t *)data;
   132f7:	8b 45 0c             	mov    0xc(%ebp),%eax
   132fa:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tmp->next = list->next;
   132fd:	8b 45 08             	mov    0x8(%ebp),%eax
   13300:	8b 10                	mov    (%eax),%edx
   13302:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13305:	89 10                	mov    %edx,(%eax)
	list->next = tmp;
   13307:	8b 45 08             	mov    0x8(%ebp),%eax
   1330a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1330d:	89 10                	mov    %edx,(%eax)
}
   1330f:	90                   	nop
   13310:	c9                   	leave  
   13311:	c3                   	ret    

00013312 <list_remove>:
**
** @param[in,out] list  The address of a list_t variable
**
** @return a pointer to the removed data, or NULL if the list was empty
*/
void *list_remove( list_t *list ) {
   13312:	55                   	push   %ebp
   13313:	89 e5                	mov    %esp,%ebp
   13315:	83 ec 18             	sub    $0x18,%esp

	assert1( list != NULL );
   13318:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1331c:	75 38                	jne    13356 <list_remove+0x44>
   1331e:	83 ec 04             	sub    $0x4,%esp
   13321:	68 ec af 01 00       	push   $0x1afec
   13326:	6a 01                	push   $0x1
   13328:	6a 36                	push   $0x36
   1332a:	68 f6 af 01 00       	push   $0x1aff6
   1332f:	68 2c b0 01 00       	push   $0x1b02c
   13334:	68 fd af 01 00       	push   $0x1affd
   13339:	68 00 00 02 00       	push   $0x20000
   1333e:	e8 a4 f3 ff ff       	call   126e7 <sprint>
   13343:	83 c4 20             	add    $0x20,%esp
   13346:	83 ec 0c             	sub    $0xc,%esp
   13349:	68 00 00 02 00       	push   $0x20000
   1334e:	e8 14 f1 ff ff       	call   12467 <kpanic>
   13353:	83 c4 10             	add    $0x10,%esp

	list_t *data = list->next;
   13356:	8b 45 08             	mov    0x8(%ebp),%eax
   13359:	8b 00                	mov    (%eax),%eax
   1335b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( data != NULL ) {
   1335e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   13362:	74 13                	je     13377 <list_remove+0x65>
		list->next = data->next;
   13364:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13367:	8b 10                	mov    (%eax),%edx
   13369:	8b 45 08             	mov    0x8(%ebp),%eax
   1336c:	89 10                	mov    %edx,(%eax)
		data->next = NULL;
   1336e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13371:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}

	return (void *)data;
   13377:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   1337a:	c9                   	leave  
   1337b:	c3                   	ret    

0001337c <find_prev_wakeup>:
** @param[in] pcb    The PCB to look for
**
** @return a pointer to the predecessor in the queue, or NULL if
** this PCB would be at the beginning of the queue.
*/
static pcb_t *find_prev_wakeup( pcb_queue_t queue, pcb_t *pcb ) {
   1337c:	55                   	push   %ebp
   1337d:	89 e5                	mov    %esp,%ebp
   1337f:	83 ec 18             	sub    $0x18,%esp

	// sanity checks!
	assert1( queue != NULL );
   13382:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13386:	75 3b                	jne    133c3 <find_prev_wakeup+0x47>
   13388:	83 ec 04             	sub    $0x4,%esp
   1338b:	68 8c b0 01 00       	push   $0x1b08c
   13390:	6a 01                	push   $0x1
   13392:	68 84 00 00 00       	push   $0x84
   13397:	68 97 b0 01 00       	push   $0x1b097
   1339c:	68 f4 b4 01 00       	push   $0x1b4f4
   133a1:	68 9f b0 01 00       	push   $0x1b09f
   133a6:	68 00 00 02 00       	push   $0x20000
   133ab:	e8 37 f3 ff ff       	call   126e7 <sprint>
   133b0:	83 c4 20             	add    $0x20,%esp
   133b3:	83 ec 0c             	sub    $0xc,%esp
   133b6:	68 00 00 02 00       	push   $0x20000
   133bb:	e8 a7 f0 ff ff       	call   12467 <kpanic>
   133c0:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   133c3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   133c7:	75 3b                	jne    13404 <find_prev_wakeup+0x88>
   133c9:	83 ec 04             	sub    $0x4,%esp
   133cc:	68 b5 b0 01 00       	push   $0x1b0b5
   133d1:	6a 01                	push   $0x1
   133d3:	68 85 00 00 00       	push   $0x85
   133d8:	68 97 b0 01 00       	push   $0x1b097
   133dd:	68 f4 b4 01 00       	push   $0x1b4f4
   133e2:	68 9f b0 01 00       	push   $0x1b09f
   133e7:	68 00 00 02 00       	push   $0x20000
   133ec:	e8 f6 f2 ff ff       	call   126e7 <sprint>
   133f1:	83 c4 20             	add    $0x20,%esp
   133f4:	83 ec 0c             	sub    $0xc,%esp
   133f7:	68 00 00 02 00       	push   $0x20000
   133fc:	e8 66 f0 ff ff       	call   12467 <kpanic>
   13401:	83 c4 10             	add    $0x10,%esp

	pcb_t *prev = NULL;
   13404:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *curr = queue->head;
   1340b:	8b 45 08             	mov    0x8(%ebp),%eax
   1340e:	8b 00                	mov    (%eax),%eax
   13410:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr != NULL && curr->wakeup <= pcb->wakeup ) {
   13413:	eb 0f                	jmp    13424 <find_prev_wakeup+0xa8>
		prev = curr;
   13415:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13418:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   1341b:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1341e:	8b 40 08             	mov    0x8(%eax),%eax
   13421:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr != NULL && curr->wakeup <= pcb->wakeup ) {
   13424:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   13428:	74 10                	je     1343a <find_prev_wakeup+0xbe>
   1342a:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1342d:	8b 50 10             	mov    0x10(%eax),%edx
   13430:	8b 45 0c             	mov    0xc(%ebp),%eax
   13433:	8b 40 10             	mov    0x10(%eax),%eax
   13436:	39 c2                	cmp    %eax,%edx
   13438:	76 db                	jbe    13415 <find_prev_wakeup+0x99>
	}

	return prev;
   1343a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   1343d:	c9                   	leave  
   1343e:	c3                   	ret    

0001343f <find_prev_priority>:

static pcb_t *find_prev_priority( pcb_queue_t queue, pcb_t *pcb ) {
   1343f:	55                   	push   %ebp
   13440:	89 e5                	mov    %esp,%ebp
   13442:	83 ec 18             	sub    $0x18,%esp

	// sanity checks!
	assert1( queue != NULL );
   13445:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13449:	75 3b                	jne    13486 <find_prev_priority+0x47>
   1344b:	83 ec 04             	sub    $0x4,%esp
   1344e:	68 8c b0 01 00       	push   $0x1b08c
   13453:	6a 01                	push   $0x1
   13455:	68 95 00 00 00       	push   $0x95
   1345a:	68 97 b0 01 00       	push   $0x1b097
   1345f:	68 08 b5 01 00       	push   $0x1b508
   13464:	68 9f b0 01 00       	push   $0x1b09f
   13469:	68 00 00 02 00       	push   $0x20000
   1346e:	e8 74 f2 ff ff       	call   126e7 <sprint>
   13473:	83 c4 20             	add    $0x20,%esp
   13476:	83 ec 0c             	sub    $0xc,%esp
   13479:	68 00 00 02 00       	push   $0x20000
   1347e:	e8 e4 ef ff ff       	call   12467 <kpanic>
   13483:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   13486:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   1348a:	75 3b                	jne    134c7 <find_prev_priority+0x88>
   1348c:	83 ec 04             	sub    $0x4,%esp
   1348f:	68 b5 b0 01 00       	push   $0x1b0b5
   13494:	6a 01                	push   $0x1
   13496:	68 96 00 00 00       	push   $0x96
   1349b:	68 97 b0 01 00       	push   $0x1b097
   134a0:	68 08 b5 01 00       	push   $0x1b508
   134a5:	68 9f b0 01 00       	push   $0x1b09f
   134aa:	68 00 00 02 00       	push   $0x20000
   134af:	e8 33 f2 ff ff       	call   126e7 <sprint>
   134b4:	83 c4 20             	add    $0x20,%esp
   134b7:	83 ec 0c             	sub    $0xc,%esp
   134ba:	68 00 00 02 00       	push   $0x20000
   134bf:	e8 a3 ef ff ff       	call   12467 <kpanic>
   134c4:	83 c4 10             	add    $0x10,%esp

	pcb_t *prev = NULL;
   134c7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *curr = queue->head;
   134ce:	8b 45 08             	mov    0x8(%ebp),%eax
   134d1:	8b 00                	mov    (%eax),%eax
   134d3:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr != NULL && curr->priority <= pcb->priority ) {
   134d6:	eb 0f                	jmp    134e7 <find_prev_priority+0xa8>
		prev = curr;
   134d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
   134db:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   134de:	8b 45 f0             	mov    -0x10(%ebp),%eax
   134e1:	8b 40 08             	mov    0x8(%eax),%eax
   134e4:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr != NULL && curr->priority <= pcb->priority ) {
   134e7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   134eb:	74 10                	je     134fd <find_prev_priority+0xbe>
   134ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
   134f0:	8b 50 20             	mov    0x20(%eax),%edx
   134f3:	8b 45 0c             	mov    0xc(%ebp),%eax
   134f6:	8b 40 20             	mov    0x20(%eax),%eax
   134f9:	39 c2                	cmp    %eax,%edx
   134fb:	76 db                	jbe    134d8 <find_prev_priority+0x99>
	}

	return prev;
   134fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   13500:	c9                   	leave  
   13501:	c3                   	ret    

00013502 <find_prev_pid>:

static pcb_t *find_prev_pid( pcb_queue_t queue, pcb_t *pcb ) {
   13502:	55                   	push   %ebp
   13503:	89 e5                	mov    %esp,%ebp
   13505:	83 ec 18             	sub    $0x18,%esp

	// sanity checks!
	assert1( queue != NULL );
   13508:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1350c:	75 3b                	jne    13549 <find_prev_pid+0x47>
   1350e:	83 ec 04             	sub    $0x4,%esp
   13511:	68 8c b0 01 00       	push   $0x1b08c
   13516:	6a 01                	push   $0x1
   13518:	68 a6 00 00 00       	push   $0xa6
   1351d:	68 97 b0 01 00       	push   $0x1b097
   13522:	68 1c b5 01 00       	push   $0x1b51c
   13527:	68 9f b0 01 00       	push   $0x1b09f
   1352c:	68 00 00 02 00       	push   $0x20000
   13531:	e8 b1 f1 ff ff       	call   126e7 <sprint>
   13536:	83 c4 20             	add    $0x20,%esp
   13539:	83 ec 0c             	sub    $0xc,%esp
   1353c:	68 00 00 02 00       	push   $0x20000
   13541:	e8 21 ef ff ff       	call   12467 <kpanic>
   13546:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   13549:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   1354d:	75 3b                	jne    1358a <find_prev_pid+0x88>
   1354f:	83 ec 04             	sub    $0x4,%esp
   13552:	68 b5 b0 01 00       	push   $0x1b0b5
   13557:	6a 01                	push   $0x1
   13559:	68 a7 00 00 00       	push   $0xa7
   1355e:	68 97 b0 01 00       	push   $0x1b097
   13563:	68 1c b5 01 00       	push   $0x1b51c
   13568:	68 9f b0 01 00       	push   $0x1b09f
   1356d:	68 00 00 02 00       	push   $0x20000
   13572:	e8 70 f1 ff ff       	call   126e7 <sprint>
   13577:	83 c4 20             	add    $0x20,%esp
   1357a:	83 ec 0c             	sub    $0xc,%esp
   1357d:	68 00 00 02 00       	push   $0x20000
   13582:	e8 e0 ee ff ff       	call   12467 <kpanic>
   13587:	83 c4 10             	add    $0x10,%esp

	pcb_t *prev = NULL;
   1358a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *curr = queue->head;
   13591:	8b 45 08             	mov    0x8(%ebp),%eax
   13594:	8b 00                	mov    (%eax),%eax
   13596:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr != NULL && curr->pid <= pcb->pid ) {
   13599:	eb 0f                	jmp    135aa <find_prev_pid+0xa8>
		prev = curr;
   1359b:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1359e:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   135a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
   135a4:	8b 40 08             	mov    0x8(%eax),%eax
   135a7:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr != NULL && curr->pid <= pcb->pid ) {
   135aa:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   135ae:	74 10                	je     135c0 <find_prev_pid+0xbe>
   135b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
   135b3:	8b 50 18             	mov    0x18(%eax),%edx
   135b6:	8b 45 0c             	mov    0xc(%ebp),%eax
   135b9:	8b 40 18             	mov    0x18(%eax),%eax
   135bc:	39 c2                	cmp    %eax,%edx
   135be:	76 db                	jbe    1359b <find_prev_pid+0x99>
	}

	return prev;
   135c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   135c3:	c9                   	leave  
   135c4:	c3                   	ret    

000135c5 <pcb_init>:
/**
** Name:	pcb_init
**
** Initialization for the Process module.
*/
void pcb_init( void ) {
   135c5:	55                   	push   %ebp
   135c6:	89 e5                	mov    %esp,%ebp
   135c8:	83 ec 18             	sub    $0x18,%esp

#if TRACING_INIT
	cio_puts( " Procs" );
   135cb:	83 ec 0c             	sub    $0xc,%esp
   135ce:	68 be b0 01 00       	push   $0x1b0be
   135d3:	e8 d5 d8 ff ff       	call   10ead <cio_puts>
   135d8:	83 c4 10             	add    $0x10,%esp
#endif

	// there is no current process
	current = NULL;
   135db:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   135e2:	00 00 00 

	// first user PID
	next_pid = FIRST_USER_PID;
   135e5:	c7 05 1c 20 02 00 02 	movl   $0x2,0x2201c
   135ec:	00 00 00 

	// set up the external links to the queues
	QINIT( pcb_freelist, O_FIFO );
   135ef:	c7 05 00 20 02 00 28 	movl   $0x1e128,0x22000
   135f6:	e1 01 00 
   135f9:	a1 00 20 02 00       	mov    0x22000,%eax
   135fe:	83 ec 08             	sub    $0x8,%esp
   13601:	6a 00                	push   $0x0
   13603:	50                   	push   %eax
   13604:	e8 9c 07 00 00       	call   13da5 <pcb_queue_reset>
   13609:	83 c4 10             	add    $0x10,%esp
   1360c:	85 c0                	test   %eax,%eax
   1360e:	74 3b                	je     1364b <pcb_init+0x86>
   13610:	83 ec 04             	sub    $0x4,%esp
   13613:	68 c8 b0 01 00       	push   $0x1b0c8
   13618:	6a 00                	push   $0x0
   1361a:	68 d1 00 00 00       	push   $0xd1
   1361f:	68 97 b0 01 00       	push   $0x1b097
   13624:	68 2c b5 01 00       	push   $0x1b52c
   13629:	68 9f b0 01 00       	push   $0x1b09f
   1362e:	68 00 00 02 00       	push   $0x20000
   13633:	e8 af f0 ff ff       	call   126e7 <sprint>
   13638:	83 c4 20             	add    $0x20,%esp
   1363b:	83 ec 0c             	sub    $0xc,%esp
   1363e:	68 00 00 02 00       	push   $0x20000
   13643:	e8 1f ee ff ff       	call   12467 <kpanic>
   13648:	83 c4 10             	add    $0x10,%esp
	QINIT( ready, O_PRIO );
   1364b:	c7 05 d0 24 02 00 34 	movl   $0x1e134,0x224d0
   13652:	e1 01 00 
   13655:	a1 d0 24 02 00       	mov    0x224d0,%eax
   1365a:	83 ec 08             	sub    $0x8,%esp
   1365d:	6a 01                	push   $0x1
   1365f:	50                   	push   %eax
   13660:	e8 40 07 00 00       	call   13da5 <pcb_queue_reset>
   13665:	83 c4 10             	add    $0x10,%esp
   13668:	85 c0                	test   %eax,%eax
   1366a:	74 3b                	je     136a7 <pcb_init+0xe2>
   1366c:	83 ec 04             	sub    $0x4,%esp
   1366f:	68 f0 b0 01 00       	push   $0x1b0f0
   13674:	6a 00                	push   $0x0
   13676:	68 d2 00 00 00       	push   $0xd2
   1367b:	68 97 b0 01 00       	push   $0x1b097
   13680:	68 2c b5 01 00       	push   $0x1b52c
   13685:	68 9f b0 01 00       	push   $0x1b09f
   1368a:	68 00 00 02 00       	push   $0x20000
   1368f:	e8 53 f0 ff ff       	call   126e7 <sprint>
   13694:	83 c4 20             	add    $0x20,%esp
   13697:	83 ec 0c             	sub    $0xc,%esp
   1369a:	68 00 00 02 00       	push   $0x20000
   1369f:	e8 c3 ed ff ff       	call   12467 <kpanic>
   136a4:	83 c4 10             	add    $0x10,%esp
	QINIT( waiting, O_PID );
   136a7:	c7 05 10 20 02 00 40 	movl   $0x1e140,0x22010
   136ae:	e1 01 00 
   136b1:	a1 10 20 02 00       	mov    0x22010,%eax
   136b6:	83 ec 08             	sub    $0x8,%esp
   136b9:	6a 02                	push   $0x2
   136bb:	50                   	push   %eax
   136bc:	e8 e4 06 00 00       	call   13da5 <pcb_queue_reset>
   136c1:	83 c4 10             	add    $0x10,%esp
   136c4:	85 c0                	test   %eax,%eax
   136c6:	74 3b                	je     13703 <pcb_init+0x13e>
   136c8:	83 ec 04             	sub    $0x4,%esp
   136cb:	68 10 b1 01 00       	push   $0x1b110
   136d0:	6a 00                	push   $0x0
   136d2:	68 d3 00 00 00       	push   $0xd3
   136d7:	68 97 b0 01 00       	push   $0x1b097
   136dc:	68 2c b5 01 00       	push   $0x1b52c
   136e1:	68 9f b0 01 00       	push   $0x1b09f
   136e6:	68 00 00 02 00       	push   $0x20000
   136eb:	e8 f7 ef ff ff       	call   126e7 <sprint>
   136f0:	83 c4 20             	add    $0x20,%esp
   136f3:	83 ec 0c             	sub    $0xc,%esp
   136f6:	68 00 00 02 00       	push   $0x20000
   136fb:	e8 67 ed ff ff       	call   12467 <kpanic>
   13700:	83 c4 10             	add    $0x10,%esp
	QINIT( sleeping, O_WAKEUP );
   13703:	c7 05 08 20 02 00 4c 	movl   $0x1e14c,0x22008
   1370a:	e1 01 00 
   1370d:	a1 08 20 02 00       	mov    0x22008,%eax
   13712:	83 ec 08             	sub    $0x8,%esp
   13715:	6a 03                	push   $0x3
   13717:	50                   	push   %eax
   13718:	e8 88 06 00 00       	call   13da5 <pcb_queue_reset>
   1371d:	83 c4 10             	add    $0x10,%esp
   13720:	85 c0                	test   %eax,%eax
   13722:	74 3b                	je     1375f <pcb_init+0x19a>
   13724:	83 ec 04             	sub    $0x4,%esp
   13727:	68 34 b1 01 00       	push   $0x1b134
   1372c:	6a 00                	push   $0x0
   1372e:	68 d4 00 00 00       	push   $0xd4
   13733:	68 97 b0 01 00       	push   $0x1b097
   13738:	68 2c b5 01 00       	push   $0x1b52c
   1373d:	68 9f b0 01 00       	push   $0x1b09f
   13742:	68 00 00 02 00       	push   $0x20000
   13747:	e8 9b ef ff ff       	call   126e7 <sprint>
   1374c:	83 c4 20             	add    $0x20,%esp
   1374f:	83 ec 0c             	sub    $0xc,%esp
   13752:	68 00 00 02 00       	push   $0x20000
   13757:	e8 0b ed ff ff       	call   12467 <kpanic>
   1375c:	83 c4 10             	add    $0x10,%esp
	QINIT( zombie, O_PID );
   1375f:	c7 05 18 20 02 00 58 	movl   $0x1e158,0x22018
   13766:	e1 01 00 
   13769:	a1 18 20 02 00       	mov    0x22018,%eax
   1376e:	83 ec 08             	sub    $0x8,%esp
   13771:	6a 02                	push   $0x2
   13773:	50                   	push   %eax
   13774:	e8 2c 06 00 00       	call   13da5 <pcb_queue_reset>
   13779:	83 c4 10             	add    $0x10,%esp
   1377c:	85 c0                	test   %eax,%eax
   1377e:	74 3b                	je     137bb <pcb_init+0x1f6>
   13780:	83 ec 04             	sub    $0x4,%esp
   13783:	68 58 b1 01 00       	push   $0x1b158
   13788:	6a 00                	push   $0x0
   1378a:	68 d5 00 00 00       	push   $0xd5
   1378f:	68 97 b0 01 00       	push   $0x1b097
   13794:	68 2c b5 01 00       	push   $0x1b52c
   13799:	68 9f b0 01 00       	push   $0x1b09f
   1379e:	68 00 00 02 00       	push   $0x20000
   137a3:	e8 3f ef ff ff       	call   126e7 <sprint>
   137a8:	83 c4 20             	add    $0x20,%esp
   137ab:	83 ec 0c             	sub    $0xc,%esp
   137ae:	68 00 00 02 00       	push   $0x20000
   137b3:	e8 af ec ff ff       	call   12467 <kpanic>
   137b8:	83 c4 10             	add    $0x10,%esp
	QINIT( sioread, O_FIFO );
   137bb:	c7 05 04 20 02 00 64 	movl   $0x1e164,0x22004
   137c2:	e1 01 00 
   137c5:	a1 04 20 02 00       	mov    0x22004,%eax
   137ca:	83 ec 08             	sub    $0x8,%esp
   137cd:	6a 00                	push   $0x0
   137cf:	50                   	push   %eax
   137d0:	e8 d0 05 00 00       	call   13da5 <pcb_queue_reset>
   137d5:	83 c4 10             	add    $0x10,%esp
   137d8:	85 c0                	test   %eax,%eax
   137da:	74 3b                	je     13817 <pcb_init+0x252>
   137dc:	83 ec 04             	sub    $0x4,%esp
   137df:	68 7c b1 01 00       	push   $0x1b17c
   137e4:	6a 00                	push   $0x0
   137e6:	68 d6 00 00 00       	push   $0xd6
   137eb:	68 97 b0 01 00       	push   $0x1b097
   137f0:	68 2c b5 01 00       	push   $0x1b52c
   137f5:	68 9f b0 01 00       	push   $0x1b09f
   137fa:	68 00 00 02 00       	push   $0x20000
   137ff:	e8 e3 ee ff ff       	call   126e7 <sprint>
   13804:	83 c4 20             	add    $0x20,%esp
   13807:	83 ec 0c             	sub    $0xc,%esp
   1380a:	68 00 00 02 00       	push   $0x20000
   1380f:	e8 53 ec ff ff       	call   12467 <kpanic>
   13814:	83 c4 10             	add    $0x10,%esp
	** so that we dynamically allocate PCBs, this step either
	** won't be required, or could be used to pre-allocate some
	** number of PCB structures for future use.
	*/

	pcb_t *ptr = ptable;
   13817:	c7 45 f4 20 20 02 00 	movl   $0x22020,-0xc(%ebp)
	for( int i = 0; i < N_PROCS; ++i ) {
   1381e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   13825:	eb 16                	jmp    1383d <pcb_init+0x278>
		pcb_free( ptr );
   13827:	83 ec 0c             	sub    $0xc,%esp
   1382a:	ff 75 f4             	pushl  -0xc(%ebp)
   1382d:	e8 8a 00 00 00       	call   138bc <pcb_free>
   13832:	83 c4 10             	add    $0x10,%esp
		++ptr;
   13835:	83 45 f4 30          	addl   $0x30,-0xc(%ebp)
	for( int i = 0; i < N_PROCS; ++i ) {
   13839:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   1383d:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   13841:	7e e4                	jle    13827 <pcb_init+0x262>
	}
}
   13843:	90                   	nop
   13844:	c9                   	leave  
   13845:	c3                   	ret    

00013846 <pcb_alloc>:
**
** @param pcb   Pointer to a pcb_t * where the PCB pointer will be returned.
**
** @return status of the allocation attempt
*/
int pcb_alloc( pcb_t **pcb ) {
   13846:	55                   	push   %ebp
   13847:	89 e5                	mov    %esp,%ebp
   13849:	83 ec 18             	sub    $0x18,%esp

	// sanity check!
	assert1( pcb != NULL );
   1384c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13850:	75 3b                	jne    1388d <pcb_alloc+0x47>
   13852:	83 ec 04             	sub    $0x4,%esp
   13855:	68 b5 b0 01 00       	push   $0x1b0b5
   1385a:	6a 01                	push   $0x1
   1385c:	68 f3 00 00 00       	push   $0xf3
   13861:	68 97 b0 01 00       	push   $0x1b097
   13866:	68 38 b5 01 00       	push   $0x1b538
   1386b:	68 9f b0 01 00       	push   $0x1b09f
   13870:	68 00 00 02 00       	push   $0x20000
   13875:	e8 6d ee ff ff       	call   126e7 <sprint>
   1387a:	83 c4 20             	add    $0x20,%esp
   1387d:	83 ec 0c             	sub    $0xc,%esp
   13880:	68 00 00 02 00       	push   $0x20000
   13885:	e8 dd eb ff ff       	call   12467 <kpanic>
   1388a:	83 c4 10             	add    $0x10,%esp

	// remove the first PCB from the free list
	pcb_t *tmp;
	if( pcb_queue_remove(pcb_freelist,&tmp) != SUCCESS ) {
   1388d:	a1 00 20 02 00       	mov    0x22000,%eax
   13892:	83 ec 08             	sub    $0x8,%esp
   13895:	8d 55 f4             	lea    -0xc(%ebp),%edx
   13898:	52                   	push   %edx
   13899:	50                   	push   %eax
   1389a:	e8 1d 08 00 00       	call   140bc <pcb_queue_remove>
   1389f:	83 c4 10             	add    $0x10,%esp
   138a2:	85 c0                	test   %eax,%eax
   138a4:	74 07                	je     138ad <pcb_alloc+0x67>
		return E_NO_PCBS;
   138a6:	b8 9b ff ff ff       	mov    $0xffffff9b,%eax
   138ab:	eb 0d                	jmp    138ba <pcb_alloc+0x74>
	}

	*pcb = tmp;
   138ad:	8b 55 f4             	mov    -0xc(%ebp),%edx
   138b0:	8b 45 08             	mov    0x8(%ebp),%eax
   138b3:	89 10                	mov    %edx,(%eax)
	return SUCCESS;
   138b5:	b8 00 00 00 00       	mov    $0x0,%eax
}
   138ba:	c9                   	leave  
   138bb:	c3                   	ret    

000138bc <pcb_free>:
**
** Return a PCB to the list of free PCBs.
**
** @param pcb   Pointer to the PCB to be deallocated.
*/
void pcb_free( pcb_t *pcb ) {
   138bc:	55                   	push   %ebp
   138bd:	89 e5                	mov    %esp,%ebp
   138bf:	83 ec 18             	sub    $0x18,%esp

	if( pcb != NULL ) {
   138c2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   138c6:	74 7b                	je     13943 <pcb_free+0x87>
		// mark the PCB as available
		pcb->state = STATE_UNUSED;
   138c8:	8b 45 08             	mov    0x8(%ebp),%eax
   138cb:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

		// add it to the free list
		int status = pcb_queue_insert( pcb_freelist, pcb );
   138d2:	a1 00 20 02 00       	mov    0x22000,%eax
   138d7:	83 ec 08             	sub    $0x8,%esp
   138da:	ff 75 08             	pushl  0x8(%ebp)
   138dd:	50                   	push   %eax
   138de:	e8 f3 05 00 00       	call   13ed6 <pcb_queue_insert>
   138e3:	83 c4 10             	add    $0x10,%esp
   138e6:	89 45 f4             	mov    %eax,-0xc(%ebp)

		// if that failed, we're in trouble
		if( status != SUCCESS ) {
   138e9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   138ed:	74 54                	je     13943 <pcb_free+0x87>
			sprint( b256, "pcb_free(0x%08x) status %d", (uint32_t) pcb,
   138ef:	8b 45 08             	mov    0x8(%ebp),%eax
   138f2:	ff 75 f4             	pushl  -0xc(%ebp)
   138f5:	50                   	push   %eax
   138f6:	68 9e b1 01 00       	push   $0x1b19e
   138fb:	68 00 02 02 00       	push   $0x20200
   13900:	e8 e2 ed ff ff       	call   126e7 <sprint>
   13905:	83 c4 10             	add    $0x10,%esp
					status );
			PANIC( 0, b256 );
   13908:	83 ec 04             	sub    $0x4,%esp
   1390b:	68 b9 b1 01 00       	push   $0x1b1b9
   13910:	6a 00                	push   $0x0
   13912:	68 13 01 00 00       	push   $0x113
   13917:	68 97 b0 01 00       	push   $0x1b097
   1391c:	68 44 b5 01 00       	push   $0x1b544
   13921:	68 9f b0 01 00       	push   $0x1b09f
   13926:	68 00 00 02 00       	push   $0x20000
   1392b:	e8 b7 ed ff ff       	call   126e7 <sprint>
   13930:	83 c4 20             	add    $0x20,%esp
   13933:	83 ec 0c             	sub    $0xc,%esp
   13936:	68 00 00 02 00       	push   $0x20000
   1393b:	e8 27 eb ff ff       	call   12467 <kpanic>
   13940:	83 c4 10             	add    $0x10,%esp
		}
	}
}
   13943:	90                   	nop
   13944:	c9                   	leave  
   13945:	c3                   	ret    

00013946 <pcb_stack_alloc>:
**
** @param size   Desired size (in pages, or 0 to get the default size
**
** @return pointer to the allocated space, or NULL
*/
uint32_t *pcb_stack_alloc( uint32_t size ) {
   13946:	55                   	push   %ebp
   13947:	89 e5                	mov    %esp,%ebp
   13949:	83 ec 18             	sub    $0x18,%esp

#if TRACING_STACK
	cio_printf( "stack alloc, %u", size );
#endif
	// do we have a desired size?
	if( size == 0 ) {
   1394c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13950:	75 07                	jne    13959 <pcb_stack_alloc+0x13>
		// no, so use the default
		size = N_USTKPAGES;
   13952:	c7 45 08 02 00 00 00 	movl   $0x2,0x8(%ebp)
	}

	uint32_t *ptr = (uint32_t *) km_page_alloc( size );
   13959:	83 ec 0c             	sub    $0xc,%esp
   1395c:	ff 75 08             	pushl  0x8(%ebp)
   1395f:	e8 ce f4 ff ff       	call   12e32 <km_page_alloc>
   13964:	83 c4 10             	add    $0x10,%esp
   13967:	89 45 f4             	mov    %eax,-0xc(%ebp)
#if TRACING_STACK
	cio_printf( " --> %08x\n", (uint32_t) ptr );
#endif
	if( ptr ) {
   1396a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1396e:	74 15                	je     13985 <pcb_stack_alloc+0x3f>
		// clear out the allocated space
		memclr( ptr, size * SZ_PAGE );
   13970:	8b 45 08             	mov    0x8(%ebp),%eax
   13973:	c1 e0 0c             	shl    $0xc,%eax
   13976:	83 ec 08             	sub    $0x8,%esp
   13979:	50                   	push   %eax
   1397a:	ff 75 f4             	pushl  -0xc(%ebp)
   1397d:	e8 e2 eb ff ff       	call   12564 <memclr>
   13982:	83 c4 10             	add    $0x10,%esp
	}

	return ptr;
   13985:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   13988:	c9                   	leave  
   13989:	c3                   	ret    

0001398a <pcb_stack_free>:
** Dellocate space for a stack
**
** @param stk    Pointer to the stack
** @param size   Allocation size (in pages, or 0 for the default size
*/
void pcb_stack_free( uint32_t *stk, uint32_t size ) {
   1398a:	55                   	push   %ebp
   1398b:	89 e5                	mov    %esp,%ebp
   1398d:	83 ec 08             	sub    $0x8,%esp

#if TRACING_STACK
	cio_printf( "stack free, %08x %u\n", (uint32_t) stk, size );
#endif

	assert( stk != NULL );
   13990:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13994:	75 3b                	jne    139d1 <pcb_stack_free+0x47>
   13996:	83 ec 04             	sub    $0x4,%esp
   13999:	68 be b1 01 00       	push   $0x1b1be
   1399e:	6a 00                	push   $0x0
   139a0:	68 46 01 00 00       	push   $0x146
   139a5:	68 97 b0 01 00       	push   $0x1b097
   139aa:	68 50 b5 01 00       	push   $0x1b550
   139af:	68 9f b0 01 00       	push   $0x1b09f
   139b4:	68 00 00 02 00       	push   $0x20000
   139b9:	e8 29 ed ff ff       	call   126e7 <sprint>
   139be:	83 c4 20             	add    $0x20,%esp
   139c1:	83 ec 0c             	sub    $0xc,%esp
   139c4:	68 00 00 02 00       	push   $0x20000
   139c9:	e8 99 ea ff ff       	call   12467 <kpanic>
   139ce:	83 c4 10             	add    $0x10,%esp

	// do we have an alternate size?
	if( size == 0 ) {
   139d1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   139d5:	75 07                	jne    139de <pcb_stack_free+0x54>
		// no, so use the default
		size = N_USTKPAGES;
   139d7:	c7 45 0c 02 00 00 00 	movl   $0x2,0xc(%ebp)
	}

	// send it back to the pool
	km_page_free_multi( (void *)stk, size );
   139de:	83 ec 08             	sub    $0x8,%esp
   139e1:	ff 75 0c             	pushl  0xc(%ebp)
   139e4:	ff 75 08             	pushl  0x8(%ebp)
   139e7:	e8 6c f5 ff ff       	call   12f58 <km_page_free_multi>
   139ec:	83 c4 10             	add    $0x10,%esp
}
   139ef:	90                   	nop
   139f0:	c9                   	leave  
   139f1:	c3                   	ret    

000139f2 <pcb_zombify>:
** does most of the real work for exit() and kill() calls.
** Is also called from the scheduler and dispatcher.
**
** @param pcb   Pointer to the newly-undead PCB
*/
void pcb_zombify( register pcb_t *victim ) {
   139f2:	55                   	push   %ebp
   139f3:	89 e5                	mov    %esp,%ebp
   139f5:	56                   	push   %esi
   139f6:	53                   	push   %ebx
   139f7:	83 ec 20             	sub    $0x20,%esp
   139fa:	8b 5d 08             	mov    0x8(%ebp),%ebx

	// should this be an error?
	if( victim == NULL ) {
   139fd:	85 db                	test   %ebx,%ebx
   139ff:	0f 84 79 02 00 00    	je     13c7e <pcb_zombify+0x28c>
		return;
	}

	// every process must have a parent, even if it's 'init'
	assert( victim->parent != NULL );
   13a05:	8b 43 0c             	mov    0xc(%ebx),%eax
   13a08:	85 c0                	test   %eax,%eax
   13a0a:	75 3b                	jne    13a47 <pcb_zombify+0x55>
   13a0c:	83 ec 04             	sub    $0x4,%esp
   13a0f:	68 c7 b1 01 00       	push   $0x1b1c7
   13a14:	6a 00                	push   $0x0
   13a16:	68 63 01 00 00       	push   $0x163
   13a1b:	68 97 b0 01 00       	push   $0x1b097
   13a20:	68 60 b5 01 00       	push   $0x1b560
   13a25:	68 9f b0 01 00       	push   $0x1b09f
   13a2a:	68 00 00 02 00       	push   $0x20000
   13a2f:	e8 b3 ec ff ff       	call   126e7 <sprint>
   13a34:	83 c4 20             	add    $0x20,%esp
   13a37:	83 ec 0c             	sub    $0xc,%esp
   13a3a:	68 00 00 02 00       	push   $0x20000
   13a3f:	e8 23 ea ff ff       	call   12467 <kpanic>
   13a44:	83 c4 10             	add    $0x10,%esp
	/*
	** We need to locate the parent of this process.  We also need
	** to reparent any children of this process.  We do these in
	** a single loop.
	*/
	pcb_t *parent = victim->parent;
   13a47:	8b 43 0c             	mov    0xc(%ebx),%eax
   13a4a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	pcb_t *zchild = NULL;
   13a4d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// two PIDs we will look for
	uint_t vicpid = victim->pid;
   13a54:	8b 43 18             	mov    0x18(%ebx),%eax
   13a57:	89 45 e8             	mov    %eax,-0x18(%ebp)

	// speed up access to the process table entries
	register pcb_t *curr = ptable;
   13a5a:	be 20 20 02 00       	mov    $0x22020,%esi

	for( int i = 0; i < N_PROCS; ++i, ++curr ) {
   13a5f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   13a66:	eb 33                	jmp    13a9b <pcb_zombify+0xa9>

		// make sure this is a valid entry
		if( curr->state == STATE_UNUSED ) {
   13a68:	8b 46 1c             	mov    0x1c(%esi),%eax
   13a6b:	85 c0                	test   %eax,%eax
   13a6d:	74 21                	je     13a90 <pcb_zombify+0x9e>
			continue;
		}

		// if this is our parent, just keep going - we continue
		// iterating to find all the children of this process.
		if( curr == parent ) {
   13a6f:	3b 75 ec             	cmp    -0x14(%ebp),%esi
   13a72:	74 1f                	je     13a93 <pcb_zombify+0xa1>
			continue;
		}

		if( curr->parent == victim ) {
   13a74:	8b 46 0c             	mov    0xc(%esi),%eax
   13a77:	39 c3                	cmp    %eax,%ebx
   13a79:	75 19                	jne    13a94 <pcb_zombify+0xa2>

			// found a child - reparent it
			curr->parent = init_pcb;
   13a7b:	a1 0c 20 02 00       	mov    0x2200c,%eax
   13a80:	89 46 0c             	mov    %eax,0xc(%esi)

			// see if this child is already undead
			if( curr->state == STATE_ZOMBIE ) {
   13a83:	8b 46 1c             	mov    0x1c(%esi),%eax
   13a86:	83 f8 08             	cmp    $0x8,%eax
   13a89:	75 09                	jne    13a94 <pcb_zombify+0xa2>
				// if it's already a zombie, remember it, so we
				// can pass it on to 'init'; also, if there are
				// two or more zombie children, it doesn't matter
				// which one we pick here, as the others will be
				// collected when 'init' loops
				zchild = curr;
   13a8b:	89 75 f4             	mov    %esi,-0xc(%ebp)
   13a8e:	eb 04                	jmp    13a94 <pcb_zombify+0xa2>
			continue;
   13a90:	90                   	nop
   13a91:	eb 01                	jmp    13a94 <pcb_zombify+0xa2>
			continue;
   13a93:	90                   	nop
	for( int i = 0; i < N_PROCS; ++i, ++curr ) {
   13a94:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   13a98:	83 c6 30             	add    $0x30,%esi
   13a9b:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   13a9f:	7e c7                	jle    13a68 <pcb_zombify+0x76>
	** existing process itself is cleaned up by init. This will work,
	** because after init cleans up the zombie, it will loop and
	** call waitpid() again, by which time this exiting process will
	** be marked as a zombie.
	*/
	if( zchild != NULL && init_pcb->state == STATE_WAITING ) {
   13aa1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   13aa5:	0f 84 0d 01 00 00    	je     13bb8 <pcb_zombify+0x1c6>
   13aab:	a1 0c 20 02 00       	mov    0x2200c,%eax
   13ab0:	8b 40 1c             	mov    0x1c(%eax),%eax
   13ab3:	83 f8 06             	cmp    $0x6,%eax
   13ab6:	0f 85 fc 00 00 00    	jne    13bb8 <pcb_zombify+0x1c6>

		// dequeue the zombie
		assert( pcb_queue_remove_this(zombie,zchild) == SUCCESS );
   13abc:	a1 18 20 02 00       	mov    0x22018,%eax
   13ac1:	83 ec 08             	sub    $0x8,%esp
   13ac4:	ff 75 f4             	pushl  -0xc(%ebp)
   13ac7:	50                   	push   %eax
   13ac8:	e8 c6 06 00 00       	call   14193 <pcb_queue_remove_this>
   13acd:	83 c4 10             	add    $0x10,%esp
   13ad0:	85 c0                	test   %eax,%eax
   13ad2:	74 3b                	je     13b0f <pcb_zombify+0x11d>
   13ad4:	83 ec 04             	sub    $0x4,%esp
   13ad7:	68 dc b1 01 00       	push   $0x1b1dc
   13adc:	6a 00                	push   $0x0
   13ade:	68 a5 01 00 00       	push   $0x1a5
   13ae3:	68 97 b0 01 00       	push   $0x1b097
   13ae8:	68 60 b5 01 00       	push   $0x1b560
   13aed:	68 9f b0 01 00       	push   $0x1b09f
   13af2:	68 00 00 02 00       	push   $0x20000
   13af7:	e8 eb eb ff ff       	call   126e7 <sprint>
   13afc:	83 c4 20             	add    $0x20,%esp
   13aff:	83 ec 0c             	sub    $0xc,%esp
   13b02:	68 00 00 02 00       	push   $0x20000
   13b07:	e8 5b e9 ff ff       	call   12467 <kpanic>
   13b0c:	83 c4 10             	add    $0x10,%esp

		assert( pcb_queue_remove_this(waiting,init_pcb) == SUCCESS );
   13b0f:	8b 15 0c 20 02 00    	mov    0x2200c,%edx
   13b15:	a1 10 20 02 00       	mov    0x22010,%eax
   13b1a:	83 ec 08             	sub    $0x8,%esp
   13b1d:	52                   	push   %edx
   13b1e:	50                   	push   %eax
   13b1f:	e8 6f 06 00 00       	call   14193 <pcb_queue_remove_this>
   13b24:	83 c4 10             	add    $0x10,%esp
   13b27:	85 c0                	test   %eax,%eax
   13b29:	74 3b                	je     13b66 <pcb_zombify+0x174>
   13b2b:	83 ec 04             	sub    $0x4,%esp
   13b2e:	68 08 b2 01 00       	push   $0x1b208
   13b33:	6a 00                	push   $0x0
   13b35:	68 a7 01 00 00       	push   $0x1a7
   13b3a:	68 97 b0 01 00       	push   $0x1b097
   13b3f:	68 60 b5 01 00       	push   $0x1b560
   13b44:	68 9f b0 01 00       	push   $0x1b09f
   13b49:	68 00 00 02 00       	push   $0x20000
   13b4e:	e8 94 eb ff ff       	call   126e7 <sprint>
   13b53:	83 c4 20             	add    $0x20,%esp
   13b56:	83 ec 0c             	sub    $0xc,%esp
   13b59:	68 00 00 02 00       	push   $0x20000
   13b5e:	e8 04 e9 ff ff       	call   12467 <kpanic>
   13b63:	83 c4 10             	add    $0x10,%esp

		// intrinsic return value is the PID
		RET(init_pcb) = zchild->pid;
   13b66:	a1 0c 20 02 00       	mov    0x2200c,%eax
   13b6b:	8b 00                	mov    (%eax),%eax
   13b6d:	8b 55 f4             	mov    -0xc(%ebp),%edx
   13b70:	8b 52 18             	mov    0x18(%edx),%edx
   13b73:	89 50 30             	mov    %edx,0x30(%eax)

		// may also want to return the exit status
		int32_t *ptr = (int32_t *) ARG(init_pcb,2);
   13b76:	a1 0c 20 02 00       	mov    0x2200c,%eax
   13b7b:	8b 00                	mov    (%eax),%eax
   13b7d:	83 c0 48             	add    $0x48,%eax
   13b80:	83 c0 08             	add    $0x8,%eax
   13b83:	8b 00                	mov    (%eax),%eax
   13b85:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		if( ptr != NULL ) {
   13b88:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   13b8c:	74 0b                	je     13b99 <pcb_zombify+0x1a7>
			// ** This works in the baseline because we aren't using
			// ** any type of memory protection.  If address space
			// ** separation is implemented, this code will very likely
			// ** STOP WORKING, and will need to be fixed.
			// ********************************************************
			*ptr = zchild->exit_status;
   13b8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13b91:	8b 50 14             	mov    0x14(%eax),%edx
   13b94:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   13b97:	89 10                	mov    %edx,(%eax)
		}

		// all done - schedule 'init', and clean up the zombie
		schedule( init_pcb );
   13b99:	a1 0c 20 02 00       	mov    0x2200c,%eax
   13b9e:	83 ec 0c             	sub    $0xc,%esp
   13ba1:	50                   	push   %eax
   13ba2:	e8 08 08 00 00       	call   143af <schedule>
   13ba7:	83 c4 10             	add    $0x10,%esp
		pcb_cleanup( zchild );
   13baa:	83 ec 0c             	sub    $0xc,%esp
   13bad:	ff 75 f4             	pushl  -0xc(%ebp)
   13bb0:	e8 d1 00 00 00       	call   13c86 <pcb_cleanup>
   13bb5:	83 c4 10             	add    $0x10,%esp
	** init up to deal with a zombie child of the exiting process,
	** init's status won't be Waiting any more, so we don't have to
	** worry about it being scheduled twice.
	*/

	if( parent->state == STATE_WAITING ) {
   13bb8:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13bbb:	8b 40 1c             	mov    0x1c(%eax),%eax
   13bbe:	83 f8 06             	cmp    $0x6,%eax
   13bc1:	75 61                	jne    13c24 <pcb_zombify+0x232>

		// verify that the parent is either waiting for this process
		// or is waiting for any of its children
		uint32_t target = ARG(parent,1);
   13bc3:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13bc6:	8b 00                	mov    (%eax),%eax
   13bc8:	83 c0 48             	add    $0x48,%eax
   13bcb:	8b 40 04             	mov    0x4(%eax),%eax
   13bce:	89 45 e0             	mov    %eax,-0x20(%ebp)

		if( target == 0 || target == vicpid ) {
   13bd1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   13bd5:	74 08                	je     13bdf <pcb_zombify+0x1ed>
   13bd7:	8b 45 e0             	mov    -0x20(%ebp),%eax
   13bda:	3b 45 e8             	cmp    -0x18(%ebp),%eax
   13bdd:	75 45                	jne    13c24 <pcb_zombify+0x232>

			// the parent is waiting for this child or is waiting
			// for any of its children, so we can wake it up.

			// intrinsic return value is the PID
			RET(parent) = vicpid;
   13bdf:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13be2:	8b 00                	mov    (%eax),%eax
   13be4:	8b 55 e8             	mov    -0x18(%ebp),%edx
   13be7:	89 50 30             	mov    %edx,0x30(%eax)

			// may also want to return the exit status
			int32_t *ptr = (int32_t *) ARG(parent,2);
   13bea:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13bed:	8b 00                	mov    (%eax),%eax
   13bef:	83 c0 48             	add    $0x48,%eax
   13bf2:	83 c0 08             	add    $0x8,%eax
   13bf5:	8b 00                	mov    (%eax),%eax
   13bf7:	89 45 dc             	mov    %eax,-0x24(%ebp)

			if( ptr != NULL ) {
   13bfa:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   13bfe:	74 08                	je     13c08 <pcb_zombify+0x216>
				// ** This works in the baseline because we aren't using
				// ** any type of memory protection.  If address space
				// ** separation is implemented, this code will very likely
				// ** STOP WORKING, and will need to be fixed.
				// ********************************************************
				*ptr = victim->exit_status;
   13c00:	8b 53 14             	mov    0x14(%ebx),%edx
   13c03:	8b 45 dc             	mov    -0x24(%ebp),%eax
   13c06:	89 10                	mov    %edx,(%eax)
			}

			// all done - schedule the parent, and clean up the zombie
			schedule( parent );
   13c08:	83 ec 0c             	sub    $0xc,%esp
   13c0b:	ff 75 ec             	pushl  -0x14(%ebp)
   13c0e:	e8 9c 07 00 00       	call   143af <schedule>
   13c13:	83 c4 10             	add    $0x10,%esp
			pcb_cleanup( victim );
   13c16:	83 ec 0c             	sub    $0xc,%esp
   13c19:	53                   	push   %ebx
   13c1a:	e8 67 00 00 00       	call   13c86 <pcb_cleanup>
   13c1f:	83 c4 10             	add    $0x10,%esp

			return;
   13c22:	eb 5b                	jmp    13c7f <pcb_zombify+0x28d>
	** a state of 'Zombie'.  This simplifies life immensely,
	** because we won't need to dequeue it when it is collected
	** by its parent.
	*/

	victim->state = STATE_ZOMBIE;
   13c24:	c7 43 1c 08 00 00 00 	movl   $0x8,0x1c(%ebx)
	assert( pcb_queue_insert(zombie,victim) == SUCCESS );
   13c2b:	a1 18 20 02 00       	mov    0x22018,%eax
   13c30:	83 ec 08             	sub    $0x8,%esp
   13c33:	53                   	push   %ebx
   13c34:	50                   	push   %eax
   13c35:	e8 9c 02 00 00       	call   13ed6 <pcb_queue_insert>
   13c3a:	83 c4 10             	add    $0x10,%esp
   13c3d:	85 c0                	test   %eax,%eax
   13c3f:	74 3e                	je     13c7f <pcb_zombify+0x28d>
   13c41:	83 ec 04             	sub    $0x4,%esp
   13c44:	68 38 b2 01 00       	push   $0x1b238
   13c49:	6a 00                	push   $0x0
   13c4b:	68 fc 01 00 00       	push   $0x1fc
   13c50:	68 97 b0 01 00       	push   $0x1b097
   13c55:	68 60 b5 01 00       	push   $0x1b560
   13c5a:	68 9f b0 01 00       	push   $0x1b09f
   13c5f:	68 00 00 02 00       	push   $0x20000
   13c64:	e8 7e ea ff ff       	call   126e7 <sprint>
   13c69:	83 c4 20             	add    $0x20,%esp
   13c6c:	83 ec 0c             	sub    $0xc,%esp
   13c6f:	68 00 00 02 00       	push   $0x20000
   13c74:	e8 ee e7 ff ff       	call   12467 <kpanic>
   13c79:	83 c4 10             	add    $0x10,%esp
   13c7c:	eb 01                	jmp    13c7f <pcb_zombify+0x28d>
		return;
   13c7e:	90                   	nop
	/*
	** Note: we don't call _dispatch() here - we leave that for
	** the calling routine, as it's possible we don't need to
	** choose a new current process.
	*/
}
   13c7f:	8d 65 f8             	lea    -0x8(%ebp),%esp
   13c82:	5b                   	pop    %ebx
   13c83:	5e                   	pop    %esi
   13c84:	5d                   	pop    %ebp
   13c85:	c3                   	ret    

00013c86 <pcb_cleanup>:
**
** Reclaim a process' data structures
**
** @param pcb   The PCB to reclaim
*/
void pcb_cleanup( pcb_t *pcb ) {
   13c86:	55                   	push   %ebp
   13c87:	89 e5                	mov    %esp,%ebp
   13c89:	83 ec 08             	sub    $0x8,%esp
#if TRACING_PCB
	cio_printf( "** pcb_cleanup(0x%08x)\n", (uint32_t) pcb );
#endif

	// avoid deallocating a NULL pointer
	if( pcb == NULL ) {
   13c8c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13c90:	74 1e                	je     13cb0 <pcb_cleanup+0x2a>
		// should this be an error?
		return;
	}

	// we need to release all the VM data structures and frames
	user_cleanup( pcb );
   13c92:	83 ec 0c             	sub    $0xc,%esp
   13c95:	ff 75 08             	pushl  0x8(%ebp)
   13c98:	e8 bd 30 00 00       	call   16d5a <user_cleanup>
   13c9d:	83 c4 10             	add    $0x10,%esp

	// release the PCB itself
	pcb_free( pcb );
   13ca0:	83 ec 0c             	sub    $0xc,%esp
   13ca3:	ff 75 08             	pushl  0x8(%ebp)
   13ca6:	e8 11 fc ff ff       	call   138bc <pcb_free>
   13cab:	83 c4 10             	add    $0x10,%esp
   13cae:	eb 01                	jmp    13cb1 <pcb_cleanup+0x2b>
		return;
   13cb0:	90                   	nop
}
   13cb1:	c9                   	leave  
   13cb2:	c3                   	ret    

00013cb3 <pcb_find_pid>:
**
** @param pid   The PID to be located
**
** @return Pointer to the PCB, or NULL
*/
pcb_t *pcb_find_pid( uint_t pid ) {
   13cb3:	55                   	push   %ebp
   13cb4:	89 e5                	mov    %esp,%ebp
   13cb6:	83 ec 10             	sub    $0x10,%esp

	// must be a valid PID
	if( pid < 1 ) {
   13cb9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13cbd:	75 07                	jne    13cc6 <pcb_find_pid+0x13>
		return NULL;
   13cbf:	b8 00 00 00 00       	mov    $0x0,%eax
   13cc4:	eb 3d                	jmp    13d03 <pcb_find_pid+0x50>
	}

	// scan the process table
	pcb_t *p = ptable;
   13cc6:	c7 45 fc 20 20 02 00 	movl   $0x22020,-0x4(%ebp)

	for( int i = 0; i < N_PROCS; ++i, ++p ) {
   13ccd:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
   13cd4:	eb 22                	jmp    13cf8 <pcb_find_pid+0x45>
		if( p->pid == pid && p->state != STATE_UNUSED ) {
   13cd6:	8b 45 fc             	mov    -0x4(%ebp),%eax
   13cd9:	8b 40 18             	mov    0x18(%eax),%eax
   13cdc:	39 45 08             	cmp    %eax,0x8(%ebp)
   13cdf:	75 0f                	jne    13cf0 <pcb_find_pid+0x3d>
   13ce1:	8b 45 fc             	mov    -0x4(%ebp),%eax
   13ce4:	8b 40 1c             	mov    0x1c(%eax),%eax
   13ce7:	85 c0                	test   %eax,%eax
   13ce9:	74 05                	je     13cf0 <pcb_find_pid+0x3d>
			return p;
   13ceb:	8b 45 fc             	mov    -0x4(%ebp),%eax
   13cee:	eb 13                	jmp    13d03 <pcb_find_pid+0x50>
	for( int i = 0; i < N_PROCS; ++i, ++p ) {
   13cf0:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
   13cf4:	83 45 fc 30          	addl   $0x30,-0x4(%ebp)
   13cf8:	83 7d f8 18          	cmpl   $0x18,-0x8(%ebp)
   13cfc:	7e d8                	jle    13cd6 <pcb_find_pid+0x23>
		}
	}

	// didn't find it!
	return NULL;
   13cfe:	b8 00 00 00 00       	mov    $0x0,%eax
}
   13d03:	c9                   	leave  
   13d04:	c3                   	ret    

00013d05 <pcb_find_ppid>:
**
** @param pid   The PID to be located
**
** @return Pointer to the PCB, or NULL
*/
pcb_t *pcb_find_ppid( uint_t pid ) {
   13d05:	55                   	push   %ebp
   13d06:	89 e5                	mov    %esp,%ebp
   13d08:	83 ec 18             	sub    $0x18,%esp

	// must be a valid PID
	if( pid < 1 ) {
   13d0b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13d0f:	75 0a                	jne    13d1b <pcb_find_ppid+0x16>
		return NULL;
   13d11:	b8 00 00 00 00       	mov    $0x0,%eax
   13d16:	e9 88 00 00 00       	jmp    13da3 <pcb_find_ppid+0x9e>
	}

	// scan the process table
	pcb_t *p = ptable;
   13d1b:	c7 45 f4 20 20 02 00 	movl   $0x22020,-0xc(%ebp)

	for( int i = 0; i < N_PROCS; ++i, ++p ) {
   13d22:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   13d29:	eb 6d                	jmp    13d98 <pcb_find_ppid+0x93>
		assert1( p->parent != NULL );
   13d2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13d2e:	8b 40 0c             	mov    0xc(%eax),%eax
   13d31:	85 c0                	test   %eax,%eax
   13d33:	75 3b                	jne    13d70 <pcb_find_ppid+0x6b>
   13d35:	83 ec 04             	sub    $0x4,%esp
   13d38:	68 5f b2 01 00       	push   $0x1b25f
   13d3d:	6a 01                	push   $0x1
   13d3f:	68 50 02 00 00       	push   $0x250
   13d44:	68 97 b0 01 00       	push   $0x1b097
   13d49:	68 6c b5 01 00       	push   $0x1b56c
   13d4e:	68 9f b0 01 00       	push   $0x1b09f
   13d53:	68 00 00 02 00       	push   $0x20000
   13d58:	e8 8a e9 ff ff       	call   126e7 <sprint>
   13d5d:	83 c4 20             	add    $0x20,%esp
   13d60:	83 ec 0c             	sub    $0xc,%esp
   13d63:	68 00 00 02 00       	push   $0x20000
   13d68:	e8 fa e6 ff ff       	call   12467 <kpanic>
   13d6d:	83 c4 10             	add    $0x10,%esp
		if( p->parent->pid == pid && p->parent->state != STATE_UNUSED ) {
   13d70:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13d73:	8b 40 0c             	mov    0xc(%eax),%eax
   13d76:	8b 40 18             	mov    0x18(%eax),%eax
   13d79:	39 45 08             	cmp    %eax,0x8(%ebp)
   13d7c:	75 12                	jne    13d90 <pcb_find_ppid+0x8b>
   13d7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13d81:	8b 40 0c             	mov    0xc(%eax),%eax
   13d84:	8b 40 1c             	mov    0x1c(%eax),%eax
   13d87:	85 c0                	test   %eax,%eax
   13d89:	74 05                	je     13d90 <pcb_find_ppid+0x8b>
			return p;
   13d8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13d8e:	eb 13                	jmp    13da3 <pcb_find_ppid+0x9e>
	for( int i = 0; i < N_PROCS; ++i, ++p ) {
   13d90:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   13d94:	83 45 f4 30          	addl   $0x30,-0xc(%ebp)
   13d98:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   13d9c:	7e 8d                	jle    13d2b <pcb_find_ppid+0x26>
		}
	}

	// didn't find it!
	return NULL;
   13d9e:	b8 00 00 00 00       	mov    $0x0,%eax
}
   13da3:	c9                   	leave  
   13da4:	c3                   	ret    

00013da5 <pcb_queue_reset>:
** @param queue[out]  The queue to be initialized
** @param order[in]   The desired ordering for the queue
**
** @return status of the init request
*/
int pcb_queue_reset( pcb_queue_t queue, enum pcb_queue_order_e style ) {
   13da5:	55                   	push   %ebp
   13da6:	89 e5                	mov    %esp,%ebp
   13da8:	83 ec 08             	sub    $0x8,%esp

	// sanity check
	assert1( queue != NULL );
   13dab:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13daf:	75 3b                	jne    13dec <pcb_queue_reset+0x47>
   13db1:	83 ec 04             	sub    $0x4,%esp
   13db4:	68 8c b0 01 00       	push   $0x1b08c
   13db9:	6a 01                	push   $0x1
   13dbb:	68 68 02 00 00       	push   $0x268
   13dc0:	68 97 b0 01 00       	push   $0x1b097
   13dc5:	68 7c b5 01 00       	push   $0x1b57c
   13dca:	68 9f b0 01 00       	push   $0x1b09f
   13dcf:	68 00 00 02 00       	push   $0x20000
   13dd4:	e8 0e e9 ff ff       	call   126e7 <sprint>
   13dd9:	83 c4 20             	add    $0x20,%esp
   13ddc:	83 ec 0c             	sub    $0xc,%esp
   13ddf:	68 00 00 02 00       	push   $0x20000
   13de4:	e8 7e e6 ff ff       	call   12467 <kpanic>
   13de9:	83 c4 10             	add    $0x10,%esp

	// make sure the style is valid
	if( style < O_FIRST_STYLE || style > O_LAST_STYLE ) {
   13dec:	83 7d 0c 03          	cmpl   $0x3,0xc(%ebp)
   13df0:	76 07                	jbe    13df9 <pcb_queue_reset+0x54>
		return E_BAD_PARAM;
   13df2:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
   13df7:	eb 23                	jmp    13e1c <pcb_queue_reset+0x77>
	}

	// reset the queue
	queue->head = queue->tail = NULL;
   13df9:	8b 45 08             	mov    0x8(%ebp),%eax
   13dfc:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
   13e03:	8b 45 08             	mov    0x8(%ebp),%eax
   13e06:	8b 50 04             	mov    0x4(%eax),%edx
   13e09:	8b 45 08             	mov    0x8(%ebp),%eax
   13e0c:	89 10                	mov    %edx,(%eax)
	queue->order = style;
   13e0e:	8b 45 08             	mov    0x8(%ebp),%eax
   13e11:	8b 55 0c             	mov    0xc(%ebp),%edx
   13e14:	89 50 08             	mov    %edx,0x8(%eax)

	return SUCCESS;
   13e17:	b8 00 00 00 00       	mov    $0x0,%eax
}
   13e1c:	c9                   	leave  
   13e1d:	c3                   	ret    

00013e1e <pcb_queue_empty>:
**
** @param[in] queue  The queue to check
**
** @return true if the queue is empty, else false
*/
bool_t pcb_queue_empty( pcb_queue_t queue ) {
   13e1e:	55                   	push   %ebp
   13e1f:	89 e5                	mov    %esp,%ebp
   13e21:	83 ec 08             	sub    $0x8,%esp

	// if there is no queue, blow up
	assert1( queue != NULL );
   13e24:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13e28:	75 3b                	jne    13e65 <pcb_queue_empty+0x47>
   13e2a:	83 ec 04             	sub    $0x4,%esp
   13e2d:	68 8c b0 01 00       	push   $0x1b08c
   13e32:	6a 01                	push   $0x1
   13e34:	68 83 02 00 00       	push   $0x283
   13e39:	68 97 b0 01 00       	push   $0x1b097
   13e3e:	68 8c b5 01 00       	push   $0x1b58c
   13e43:	68 9f b0 01 00       	push   $0x1b09f
   13e48:	68 00 00 02 00       	push   $0x20000
   13e4d:	e8 95 e8 ff ff       	call   126e7 <sprint>
   13e52:	83 c4 20             	add    $0x20,%esp
   13e55:	83 ec 0c             	sub    $0xc,%esp
   13e58:	68 00 00 02 00       	push   $0x20000
   13e5d:	e8 05 e6 ff ff       	call   12467 <kpanic>
   13e62:	83 c4 10             	add    $0x10,%esp

	return PCB_QUEUE_EMPTY(queue);
   13e65:	8b 45 08             	mov    0x8(%ebp),%eax
   13e68:	8b 00                	mov    (%eax),%eax
   13e6a:	85 c0                	test   %eax,%eax
   13e6c:	0f 94 c0             	sete   %al
}
   13e6f:	c9                   	leave  
   13e70:	c3                   	ret    

00013e71 <pcb_queue_length>:
**
** @param[in] queue  The queue to check
**
** @return the count (0 if the queue is empty)
*/
uint_t pcb_queue_length( const pcb_queue_t queue ) {
   13e71:	55                   	push   %ebp
   13e72:	89 e5                	mov    %esp,%ebp
   13e74:	56                   	push   %esi
   13e75:	53                   	push   %ebx

	// sanity check
	assert1( queue != NULL );
   13e76:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13e7a:	75 3b                	jne    13eb7 <pcb_queue_length+0x46>
   13e7c:	83 ec 04             	sub    $0x4,%esp
   13e7f:	68 8c b0 01 00       	push   $0x1b08c
   13e84:	6a 01                	push   $0x1
   13e86:	68 94 02 00 00       	push   $0x294
   13e8b:	68 97 b0 01 00       	push   $0x1b097
   13e90:	68 9c b5 01 00       	push   $0x1b59c
   13e95:	68 9f b0 01 00       	push   $0x1b09f
   13e9a:	68 00 00 02 00       	push   $0x20000
   13e9f:	e8 43 e8 ff ff       	call   126e7 <sprint>
   13ea4:	83 c4 20             	add    $0x20,%esp
   13ea7:	83 ec 0c             	sub    $0xc,%esp
   13eaa:	68 00 00 02 00       	push   $0x20000
   13eaf:	e8 b3 e5 ff ff       	call   12467 <kpanic>
   13eb4:	83 c4 10             	add    $0x10,%esp

	// this is pretty simple
	register pcb_t *tmp = queue->head;
   13eb7:	8b 45 08             	mov    0x8(%ebp),%eax
   13eba:	8b 18                	mov    (%eax),%ebx
	register int num = 0;
   13ebc:	be 00 00 00 00       	mov    $0x0,%esi
	
	while( tmp != NULL ) {
   13ec1:	eb 06                	jmp    13ec9 <pcb_queue_length+0x58>
		++num;
   13ec3:	83 c6 01             	add    $0x1,%esi
		tmp = tmp->next;
   13ec6:	8b 5b 08             	mov    0x8(%ebx),%ebx
	while( tmp != NULL ) {
   13ec9:	85 db                	test   %ebx,%ebx
   13ecb:	75 f6                	jne    13ec3 <pcb_queue_length+0x52>
	}

	return num;
   13ecd:	89 f0                	mov    %esi,%eax
}
   13ecf:	8d 65 f8             	lea    -0x8(%ebp),%esp
   13ed2:	5b                   	pop    %ebx
   13ed3:	5e                   	pop    %esi
   13ed4:	5d                   	pop    %ebp
   13ed5:	c3                   	ret    

00013ed6 <pcb_queue_insert>:
** @param queue[in,out]  The queue to be used
** @param pcb[in]        The PCB to be inserted
**
** @return status of the insertion request
*/
int pcb_queue_insert( pcb_queue_t queue, pcb_t *pcb ) {
   13ed6:	55                   	push   %ebp
   13ed7:	89 e5                	mov    %esp,%ebp
   13ed9:	83 ec 18             	sub    $0x18,%esp

	// sanity checks
	assert1( queue != NULL );
   13edc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13ee0:	75 3b                	jne    13f1d <pcb_queue_insert+0x47>
   13ee2:	83 ec 04             	sub    $0x4,%esp
   13ee5:	68 8c b0 01 00       	push   $0x1b08c
   13eea:	6a 01                	push   $0x1
   13eec:	68 af 02 00 00       	push   $0x2af
   13ef1:	68 97 b0 01 00       	push   $0x1b097
   13ef6:	68 b0 b5 01 00       	push   $0x1b5b0
   13efb:	68 9f b0 01 00       	push   $0x1b09f
   13f00:	68 00 00 02 00       	push   $0x20000
   13f05:	e8 dd e7 ff ff       	call   126e7 <sprint>
   13f0a:	83 c4 20             	add    $0x20,%esp
   13f0d:	83 ec 0c             	sub    $0xc,%esp
   13f10:	68 00 00 02 00       	push   $0x20000
   13f15:	e8 4d e5 ff ff       	call   12467 <kpanic>
   13f1a:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   13f1d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   13f21:	75 3b                	jne    13f5e <pcb_queue_insert+0x88>
   13f23:	83 ec 04             	sub    $0x4,%esp
   13f26:	68 b5 b0 01 00       	push   $0x1b0b5
   13f2b:	6a 01                	push   $0x1
   13f2d:	68 b0 02 00 00       	push   $0x2b0
   13f32:	68 97 b0 01 00       	push   $0x1b097
   13f37:	68 b0 b5 01 00       	push   $0x1b5b0
   13f3c:	68 9f b0 01 00       	push   $0x1b09f
   13f41:	68 00 00 02 00       	push   $0x20000
   13f46:	e8 9c e7 ff ff       	call   126e7 <sprint>
   13f4b:	83 c4 20             	add    $0x20,%esp
   13f4e:	83 ec 0c             	sub    $0xc,%esp
   13f51:	68 00 00 02 00       	push   $0x20000
   13f56:	e8 0c e5 ff ff       	call   12467 <kpanic>
   13f5b:	83 c4 10             	add    $0x10,%esp

	// if this PCB is already in a queue, we won't touch it
	if( pcb->next != NULL ) {
   13f5e:	8b 45 0c             	mov    0xc(%ebp),%eax
   13f61:	8b 40 08             	mov    0x8(%eax),%eax
   13f64:	85 c0                	test   %eax,%eax
   13f66:	74 0a                	je     13f72 <pcb_queue_insert+0x9c>
		// what to do? we let the caller decide
		return E_BAD_PARAM;
   13f68:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
   13f6d:	e9 48 01 00 00       	jmp    140ba <pcb_queue_insert+0x1e4>
	}

	// is the queue empty?
	if( queue->head == NULL ) {
   13f72:	8b 45 08             	mov    0x8(%ebp),%eax
   13f75:	8b 00                	mov    (%eax),%eax
   13f77:	85 c0                	test   %eax,%eax
   13f79:	75 1e                	jne    13f99 <pcb_queue_insert+0xc3>
		queue->head = queue->tail = pcb;
   13f7b:	8b 45 08             	mov    0x8(%ebp),%eax
   13f7e:	8b 55 0c             	mov    0xc(%ebp),%edx
   13f81:	89 50 04             	mov    %edx,0x4(%eax)
   13f84:	8b 45 08             	mov    0x8(%ebp),%eax
   13f87:	8b 50 04             	mov    0x4(%eax),%edx
   13f8a:	8b 45 08             	mov    0x8(%ebp),%eax
   13f8d:	89 10                	mov    %edx,(%eax)
		return SUCCESS;
   13f8f:	b8 00 00 00 00       	mov    $0x0,%eax
   13f94:	e9 21 01 00 00       	jmp    140ba <pcb_queue_insert+0x1e4>
	}
	assert1( queue->tail != NULL );
   13f99:	8b 45 08             	mov    0x8(%ebp),%eax
   13f9c:	8b 40 04             	mov    0x4(%eax),%eax
   13f9f:	85 c0                	test   %eax,%eax
   13fa1:	75 3b                	jne    13fde <pcb_queue_insert+0x108>
   13fa3:	83 ec 04             	sub    $0x4,%esp
   13fa6:	68 6e b2 01 00       	push   $0x1b26e
   13fab:	6a 01                	push   $0x1
   13fad:	68 bd 02 00 00       	push   $0x2bd
   13fb2:	68 97 b0 01 00       	push   $0x1b097
   13fb7:	68 b0 b5 01 00       	push   $0x1b5b0
   13fbc:	68 9f b0 01 00       	push   $0x1b09f
   13fc1:	68 00 00 02 00       	push   $0x20000
   13fc6:	e8 1c e7 ff ff       	call   126e7 <sprint>
   13fcb:	83 c4 20             	add    $0x20,%esp
   13fce:	83 ec 0c             	sub    $0xc,%esp
   13fd1:	68 00 00 02 00       	push   $0x20000
   13fd6:	e8 8c e4 ff ff       	call   12467 <kpanic>
   13fdb:	83 c4 10             	add    $0x10,%esp

	// no, so we need to search it
	pcb_t *prev = NULL;
   13fde:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// find the predecessor node
	switch( queue->order ) {
   13fe5:	8b 45 08             	mov    0x8(%ebp),%eax
   13fe8:	8b 40 08             	mov    0x8(%eax),%eax
   13feb:	83 f8 01             	cmp    $0x1,%eax
   13fee:	74 1c                	je     1400c <pcb_queue_insert+0x136>
   13ff0:	83 f8 01             	cmp    $0x1,%eax
   13ff3:	72 0c                	jb     14001 <pcb_queue_insert+0x12b>
   13ff5:	83 f8 02             	cmp    $0x2,%eax
   13ff8:	74 28                	je     14022 <pcb_queue_insert+0x14c>
   13ffa:	83 f8 03             	cmp    $0x3,%eax
   13ffd:	74 39                	je     14038 <pcb_queue_insert+0x162>
   13fff:	eb 4d                	jmp    1404e <pcb_queue_insert+0x178>
	case O_FIFO:
		prev = queue->tail;
   14001:	8b 45 08             	mov    0x8(%ebp),%eax
   14004:	8b 40 04             	mov    0x4(%eax),%eax
   14007:	89 45 f4             	mov    %eax,-0xc(%ebp)
		break;
   1400a:	eb 49                	jmp    14055 <pcb_queue_insert+0x17f>
	case O_PRIO:
		prev = find_prev_priority(queue,pcb);
   1400c:	83 ec 08             	sub    $0x8,%esp
   1400f:	ff 75 0c             	pushl  0xc(%ebp)
   14012:	ff 75 08             	pushl  0x8(%ebp)
   14015:	e8 25 f4 ff ff       	call   1343f <find_prev_priority>
   1401a:	83 c4 10             	add    $0x10,%esp
   1401d:	89 45 f4             	mov    %eax,-0xc(%ebp)
		break;
   14020:	eb 33                	jmp    14055 <pcb_queue_insert+0x17f>
	case O_PID:
		prev = find_prev_pid(queue,pcb);
   14022:	83 ec 08             	sub    $0x8,%esp
   14025:	ff 75 0c             	pushl  0xc(%ebp)
   14028:	ff 75 08             	pushl  0x8(%ebp)
   1402b:	e8 d2 f4 ff ff       	call   13502 <find_prev_pid>
   14030:	83 c4 10             	add    $0x10,%esp
   14033:	89 45 f4             	mov    %eax,-0xc(%ebp)
		break;
   14036:	eb 1d                	jmp    14055 <pcb_queue_insert+0x17f>
	case O_WAKEUP:
		prev = find_prev_wakeup(queue,pcb);
   14038:	83 ec 08             	sub    $0x8,%esp
   1403b:	ff 75 0c             	pushl  0xc(%ebp)
   1403e:	ff 75 08             	pushl  0x8(%ebp)
   14041:	e8 36 f3 ff ff       	call   1337c <find_prev_wakeup>
   14046:	83 c4 10             	add    $0x10,%esp
   14049:	89 45 f4             	mov    %eax,-0xc(%ebp)
		break;
   1404c:	eb 07                	jmp    14055 <pcb_queue_insert+0x17f>
	default:
		// do we need something more specific here?
		return E_BAD_PARAM;
   1404e:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
   14053:	eb 65                	jmp    140ba <pcb_queue_insert+0x1e4>
	}

	// OK, we found the predecessor node; time to do the insertion

	if( prev == NULL ) {
   14055:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   14059:	75 27                	jne    14082 <pcb_queue_insert+0x1ac>

		// there is no predecessor, so we're
		// inserting at the front of the queue
		pcb->next = queue->head;
   1405b:	8b 45 08             	mov    0x8(%ebp),%eax
   1405e:	8b 10                	mov    (%eax),%edx
   14060:	8b 45 0c             	mov    0xc(%ebp),%eax
   14063:	89 50 08             	mov    %edx,0x8(%eax)
		if( queue->head == NULL ) {
   14066:	8b 45 08             	mov    0x8(%ebp),%eax
   14069:	8b 00                	mov    (%eax),%eax
   1406b:	85 c0                	test   %eax,%eax
   1406d:	75 09                	jne    14078 <pcb_queue_insert+0x1a2>
			// empty queue!?! - should we panic?
			queue->tail = pcb;
   1406f:	8b 45 08             	mov    0x8(%ebp),%eax
   14072:	8b 55 0c             	mov    0xc(%ebp),%edx
   14075:	89 50 04             	mov    %edx,0x4(%eax)
		}
		queue->head = pcb;
   14078:	8b 45 08             	mov    0x8(%ebp),%eax
   1407b:	8b 55 0c             	mov    0xc(%ebp),%edx
   1407e:	89 10                	mov    %edx,(%eax)
   14080:	eb 33                	jmp    140b5 <pcb_queue_insert+0x1df>

	} else if( prev->next == NULL ) {
   14082:	8b 45 f4             	mov    -0xc(%ebp),%eax
   14085:	8b 40 08             	mov    0x8(%eax),%eax
   14088:	85 c0                	test   %eax,%eax
   1408a:	75 14                	jne    140a0 <pcb_queue_insert+0x1ca>

		// append at end
		prev->next = pcb;
   1408c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1408f:	8b 55 0c             	mov    0xc(%ebp),%edx
   14092:	89 50 08             	mov    %edx,0x8(%eax)
		queue->tail = pcb;
   14095:	8b 45 08             	mov    0x8(%ebp),%eax
   14098:	8b 55 0c             	mov    0xc(%ebp),%edx
   1409b:	89 50 04             	mov    %edx,0x4(%eax)
   1409e:	eb 15                	jmp    140b5 <pcb_queue_insert+0x1df>

	} else {

		// insert between prev & prev->next
		pcb->next = prev->next;
   140a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
   140a3:	8b 50 08             	mov    0x8(%eax),%edx
   140a6:	8b 45 0c             	mov    0xc(%ebp),%eax
   140a9:	89 50 08             	mov    %edx,0x8(%eax)
		prev->next = pcb;
   140ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
   140af:	8b 55 0c             	mov    0xc(%ebp),%edx
   140b2:	89 50 08             	mov    %edx,0x8(%eax)

	}

	return SUCCESS;
   140b5:	b8 00 00 00 00       	mov    $0x0,%eax
}
   140ba:	c9                   	leave  
   140bb:	c3                   	ret    

000140bc <pcb_queue_remove>:
** @param queue[in,out]  The queue to be used
** @param pcb[out]       Pointer to where the PCB pointer will be saved
**
** @return status of the removal request
*/
int pcb_queue_remove( pcb_queue_t queue, pcb_t **pcb ) {
   140bc:	55                   	push   %ebp
   140bd:	89 e5                	mov    %esp,%ebp
   140bf:	83 ec 18             	sub    $0x18,%esp

	//sanity checks
	assert1( queue != NULL );
   140c2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   140c6:	75 3b                	jne    14103 <pcb_queue_remove+0x47>
   140c8:	83 ec 04             	sub    $0x4,%esp
   140cb:	68 8c b0 01 00       	push   $0x1b08c
   140d0:	6a 01                	push   $0x1
   140d2:	68 00 03 00 00       	push   $0x300
   140d7:	68 97 b0 01 00       	push   $0x1b097
   140dc:	68 c4 b5 01 00       	push   $0x1b5c4
   140e1:	68 9f b0 01 00       	push   $0x1b09f
   140e6:	68 00 00 02 00       	push   $0x20000
   140eb:	e8 f7 e5 ff ff       	call   126e7 <sprint>
   140f0:	83 c4 20             	add    $0x20,%esp
   140f3:	83 ec 0c             	sub    $0xc,%esp
   140f6:	68 00 00 02 00       	push   $0x20000
   140fb:	e8 67 e3 ff ff       	call   12467 <kpanic>
   14100:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   14103:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   14107:	75 3b                	jne    14144 <pcb_queue_remove+0x88>
   14109:	83 ec 04             	sub    $0x4,%esp
   1410c:	68 b5 b0 01 00       	push   $0x1b0b5
   14111:	6a 01                	push   $0x1
   14113:	68 01 03 00 00       	push   $0x301
   14118:	68 97 b0 01 00       	push   $0x1b097
   1411d:	68 c4 b5 01 00       	push   $0x1b5c4
   14122:	68 9f b0 01 00       	push   $0x1b09f
   14127:	68 00 00 02 00       	push   $0x20000
   1412c:	e8 b6 e5 ff ff       	call   126e7 <sprint>
   14131:	83 c4 20             	add    $0x20,%esp
   14134:	83 ec 0c             	sub    $0xc,%esp
   14137:	68 00 00 02 00       	push   $0x20000
   1413c:	e8 26 e3 ff ff       	call   12467 <kpanic>
   14141:	83 c4 10             	add    $0x10,%esp

	// can't get anything if there's nothing to get!
	if( PCB_QUEUE_EMPTY(queue) ) {
   14144:	8b 45 08             	mov    0x8(%ebp),%eax
   14147:	8b 00                	mov    (%eax),%eax
   14149:	85 c0                	test   %eax,%eax
   1414b:	75 07                	jne    14154 <pcb_queue_remove+0x98>
		return E_EMPTY_QUEUE;
   1414d:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
   14152:	eb 3d                	jmp    14191 <pcb_queue_remove+0xd5>
	}

	// take the first entry from the queue
	pcb_t *tmp = queue->head;
   14154:	8b 45 08             	mov    0x8(%ebp),%eax
   14157:	8b 00                	mov    (%eax),%eax
   14159:	89 45 f4             	mov    %eax,-0xc(%ebp)
	queue->head = tmp->next;
   1415c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1415f:	8b 50 08             	mov    0x8(%eax),%edx
   14162:	8b 45 08             	mov    0x8(%ebp),%eax
   14165:	89 10                	mov    %edx,(%eax)

	// disconnect it completely
	tmp->next = NULL;
   14167:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1416a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)

	// was this the last thing in the queue?
	if( queue->head == NULL ) {
   14171:	8b 45 08             	mov    0x8(%ebp),%eax
   14174:	8b 00                	mov    (%eax),%eax
   14176:	85 c0                	test   %eax,%eax
   14178:	75 0a                	jne    14184 <pcb_queue_remove+0xc8>
		// yes, so clear the tail pointer for consistency
		queue->tail = NULL;
   1417a:	8b 45 08             	mov    0x8(%ebp),%eax
   1417d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	}

	// save the pointer
	*pcb = tmp;
   14184:	8b 45 0c             	mov    0xc(%ebp),%eax
   14187:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1418a:	89 10                	mov    %edx,(%eax)

	return SUCCESS;
   1418c:	b8 00 00 00 00       	mov    $0x0,%eax
}
   14191:	c9                   	leave  
   14192:	c3                   	ret    

00014193 <pcb_queue_remove_this>:
** @param queue[in,out]  The queue to be used
** @param pcb[in]        Pointer to the PCB to be removed
**
** @return status of the removal request
*/
int pcb_queue_remove_this( pcb_queue_t queue, pcb_t *pcb ) {
   14193:	55                   	push   %ebp
   14194:	89 e5                	mov    %esp,%ebp
   14196:	83 ec 18             	sub    $0x18,%esp

	//sanity checks
	assert1( queue != NULL );
   14199:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1419d:	75 3b                	jne    141da <pcb_queue_remove_this+0x47>
   1419f:	83 ec 04             	sub    $0x4,%esp
   141a2:	68 8c b0 01 00       	push   $0x1b08c
   141a7:	6a 01                	push   $0x1
   141a9:	68 2c 03 00 00       	push   $0x32c
   141ae:	68 97 b0 01 00       	push   $0x1b097
   141b3:	68 d8 b5 01 00       	push   $0x1b5d8
   141b8:	68 9f b0 01 00       	push   $0x1b09f
   141bd:	68 00 00 02 00       	push   $0x20000
   141c2:	e8 20 e5 ff ff       	call   126e7 <sprint>
   141c7:	83 c4 20             	add    $0x20,%esp
   141ca:	83 ec 0c             	sub    $0xc,%esp
   141cd:	68 00 00 02 00       	push   $0x20000
   141d2:	e8 90 e2 ff ff       	call   12467 <kpanic>
   141d7:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   141da:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   141de:	75 3b                	jne    1421b <pcb_queue_remove_this+0x88>
   141e0:	83 ec 04             	sub    $0x4,%esp
   141e3:	68 b5 b0 01 00       	push   $0x1b0b5
   141e8:	6a 01                	push   $0x1
   141ea:	68 2d 03 00 00       	push   $0x32d
   141ef:	68 97 b0 01 00       	push   $0x1b097
   141f4:	68 d8 b5 01 00       	push   $0x1b5d8
   141f9:	68 9f b0 01 00       	push   $0x1b09f
   141fe:	68 00 00 02 00       	push   $0x20000
   14203:	e8 df e4 ff ff       	call   126e7 <sprint>
   14208:	83 c4 20             	add    $0x20,%esp
   1420b:	83 ec 0c             	sub    $0xc,%esp
   1420e:	68 00 00 02 00       	push   $0x20000
   14213:	e8 4f e2 ff ff       	call   12467 <kpanic>
   14218:	83 c4 10             	add    $0x10,%esp

	// can't get anything if there's nothing to get!
	if( PCB_QUEUE_EMPTY(queue) ) {
   1421b:	8b 45 08             	mov    0x8(%ebp),%eax
   1421e:	8b 00                	mov    (%eax),%eax
   14220:	85 c0                	test   %eax,%eax
   14222:	75 0a                	jne    1422e <pcb_queue_remove_this+0x9b>
		return E_EMPTY_QUEUE;
   14224:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
   14229:	e9 21 01 00 00       	jmp    1434f <pcb_queue_remove_this+0x1bc>
	}

	// iterate through the queue until we find the desired PCB
	pcb_t *prev = NULL;
   1422e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *curr = queue->head;
   14235:	8b 45 08             	mov    0x8(%ebp),%eax
   14238:	8b 00                	mov    (%eax),%eax
   1423a:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr != NULL && curr != pcb ) {
   1423d:	eb 0f                	jmp    1424e <pcb_queue_remove_this+0xbb>
		prev = curr;
   1423f:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14242:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   14245:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14248:	8b 40 08             	mov    0x8(%eax),%eax
   1424b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr != NULL && curr != pcb ) {
   1424e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   14252:	74 08                	je     1425c <pcb_queue_remove_this+0xc9>
   14254:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14257:	3b 45 0c             	cmp    0xc(%ebp),%eax
   1425a:	75 e3                	jne    1423f <pcb_queue_remove_this+0xac>
	//   3.    0    !0    !0    removing first element
	//   4.   !0     0    --    *** NOT FOUND ***
	//   5.   !0    !0     0    removing from end
	//   6.   !0    !0    !0    removing from middle

	if( curr == NULL ) {
   1425c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   14260:	75 4b                	jne    142ad <pcb_queue_remove_this+0x11a>
		// case 1
		assert( prev != NULL );
   14262:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   14266:	75 3b                	jne    142a3 <pcb_queue_remove_this+0x110>
   14268:	83 ec 04             	sub    $0x4,%esp
   1426b:	68 7f b2 01 00       	push   $0x1b27f
   14270:	6a 00                	push   $0x0
   14272:	68 48 03 00 00       	push   $0x348
   14277:	68 97 b0 01 00       	push   $0x1b097
   1427c:	68 d8 b5 01 00       	push   $0x1b5d8
   14281:	68 9f b0 01 00       	push   $0x1b09f
   14286:	68 00 00 02 00       	push   $0x20000
   1428b:	e8 57 e4 ff ff       	call   126e7 <sprint>
   14290:	83 c4 20             	add    $0x20,%esp
   14293:	83 ec 0c             	sub    $0xc,%esp
   14296:	68 00 00 02 00       	push   $0x20000
   1429b:	e8 c7 e1 ff ff       	call   12467 <kpanic>
   142a0:	83 c4 10             	add    $0x10,%esp
		// case 4
		return E_NOT_FOUND;
   142a3:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
   142a8:	e9 a2 00 00 00       	jmp    1434f <pcb_queue_remove_this+0x1bc>
	}

	// connect predecessor to successor
	if( prev != NULL ) {
   142ad:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   142b1:	74 0e                	je     142c1 <pcb_queue_remove_this+0x12e>
		// not the first element
		// cases 5 and 6
		prev->next = curr->next;
   142b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
   142b6:	8b 50 08             	mov    0x8(%eax),%edx
   142b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
   142bc:	89 50 08             	mov    %edx,0x8(%eax)
   142bf:	eb 0b                	jmp    142cc <pcb_queue_remove_this+0x139>
	} else {
		// removing first element
		// cases 2 and 3
		queue->head = curr->next;
   142c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
   142c4:	8b 50 08             	mov    0x8(%eax),%edx
   142c7:	8b 45 08             	mov    0x8(%ebp),%eax
   142ca:	89 10                	mov    %edx,(%eax)
	}

	// if this was the last node (cases 2 and 5),
	// also need to reset the tail pointer
	if( curr->next == NULL ) {
   142cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
   142cf:	8b 40 08             	mov    0x8(%eax),%eax
   142d2:	85 c0                	test   %eax,%eax
   142d4:	75 09                	jne    142df <pcb_queue_remove_this+0x14c>
		// if this was the only entry (2), prev is NULL,
		// so this works for that case, too
		queue->tail = prev;
   142d6:	8b 45 08             	mov    0x8(%ebp),%eax
   142d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
   142dc:	89 50 04             	mov    %edx,0x4(%eax)
	}

	// unlink current from queue
	curr->next = NULL;
   142df:	8b 45 f0             	mov    -0x10(%ebp),%eax
   142e2:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)

	// there's a possible consistancy problem here if somehow
	// one of the queue pointers is NULL and the other one
	// is not NULL

	assert1(
   142e9:	8b 45 08             	mov    0x8(%ebp),%eax
   142ec:	8b 00                	mov    (%eax),%eax
   142ee:	85 c0                	test   %eax,%eax
   142f0:	75 0a                	jne    142fc <pcb_queue_remove_this+0x169>
   142f2:	8b 45 08             	mov    0x8(%ebp),%eax
   142f5:	8b 40 04             	mov    0x4(%eax),%eax
   142f8:	85 c0                	test   %eax,%eax
   142fa:	74 4e                	je     1434a <pcb_queue_remove_this+0x1b7>
   142fc:	8b 45 08             	mov    0x8(%ebp),%eax
   142ff:	8b 00                	mov    (%eax),%eax
   14301:	85 c0                	test   %eax,%eax
   14303:	74 0a                	je     1430f <pcb_queue_remove_this+0x17c>
   14305:	8b 45 08             	mov    0x8(%ebp),%eax
   14308:	8b 40 04             	mov    0x4(%eax),%eax
   1430b:	85 c0                	test   %eax,%eax
   1430d:	75 3b                	jne    1434a <pcb_queue_remove_this+0x1b7>
   1430f:	83 ec 04             	sub    $0x4,%esp
   14312:	68 8c b2 01 00       	push   $0x1b28c
   14317:	6a 01                	push   $0x1
   14319:	68 6a 03 00 00       	push   $0x36a
   1431e:	68 97 b0 01 00       	push   $0x1b097
   14323:	68 d8 b5 01 00       	push   $0x1b5d8
   14328:	68 9f b0 01 00       	push   $0x1b09f
   1432d:	68 00 00 02 00       	push   $0x20000
   14332:	e8 b0 e3 ff ff       	call   126e7 <sprint>
   14337:	83 c4 20             	add    $0x20,%esp
   1433a:	83 ec 0c             	sub    $0xc,%esp
   1433d:	68 00 00 02 00       	push   $0x20000
   14342:	e8 20 e1 ff ff       	call   12467 <kpanic>
   14347:	83 c4 10             	add    $0x10,%esp
		(queue->head == NULL && queue->tail == NULL) ||
		(queue->head != NULL && queue->tail != NULL)
	);

	return SUCCESS;
   1434a:	b8 00 00 00 00       	mov    $0x0,%eax
}
   1434f:	c9                   	leave  
   14350:	c3                   	ret    

00014351 <pcb_queue_peek>:
**
** @param queue[in]  The queue to be used
**
** @return the PCB poiner, or NULL if the queue is empty
*/
pcb_t *pcb_queue_peek( const pcb_queue_t queue ) {
   14351:	55                   	push   %ebp
   14352:	89 e5                	mov    %esp,%ebp
   14354:	83 ec 08             	sub    $0x8,%esp

	//sanity check
	assert1( queue != NULL );
   14357:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1435b:	75 3b                	jne    14398 <pcb_queue_peek+0x47>
   1435d:	83 ec 04             	sub    $0x4,%esp
   14360:	68 8c b0 01 00       	push   $0x1b08c
   14365:	6a 01                	push   $0x1
   14367:	68 7c 03 00 00       	push   $0x37c
   1436c:	68 97 b0 01 00       	push   $0x1b097
   14371:	68 f0 b5 01 00       	push   $0x1b5f0
   14376:	68 9f b0 01 00       	push   $0x1b09f
   1437b:	68 00 00 02 00       	push   $0x20000
   14380:	e8 62 e3 ff ff       	call   126e7 <sprint>
   14385:	83 c4 20             	add    $0x20,%esp
   14388:	83 ec 0c             	sub    $0xc,%esp
   1438b:	68 00 00 02 00       	push   $0x20000
   14390:	e8 d2 e0 ff ff       	call   12467 <kpanic>
   14395:	83 c4 10             	add    $0x10,%esp

	// can't get anything if there's nothing to get!
	if( PCB_QUEUE_EMPTY(queue) ) {
   14398:	8b 45 08             	mov    0x8(%ebp),%eax
   1439b:	8b 00                	mov    (%eax),%eax
   1439d:	85 c0                	test   %eax,%eax
   1439f:	75 07                	jne    143a8 <pcb_queue_peek+0x57>
		return NULL;
   143a1:	b8 00 00 00 00       	mov    $0x0,%eax
   143a6:	eb 05                	jmp    143ad <pcb_queue_peek+0x5c>
	}

	// just return the first entry from the queue
	return queue->head;
   143a8:	8b 45 08             	mov    0x8(%ebp),%eax
   143ab:	8b 00                	mov    (%eax),%eax
}
   143ad:	c9                   	leave  
   143ae:	c3                   	ret    

000143af <schedule>:
**
** Schedule the supplied process
**
** @param pcb   Pointer to the PCB of the process to be scheduled
*/
void schedule( pcb_t *pcb ) {
   143af:	55                   	push   %ebp
   143b0:	89 e5                	mov    %esp,%ebp
   143b2:	83 ec 08             	sub    $0x8,%esp

	// sanity check
	assert1( pcb != NULL );
   143b5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   143b9:	75 3b                	jne    143f6 <schedule+0x47>
   143bb:	83 ec 04             	sub    $0x4,%esp
   143be:	68 b5 b0 01 00       	push   $0x1b0b5
   143c3:	6a 01                	push   $0x1
   143c5:	68 95 03 00 00       	push   $0x395
   143ca:	68 97 b0 01 00       	push   $0x1b097
   143cf:	68 00 b6 01 00       	push   $0x1b600
   143d4:	68 9f b0 01 00       	push   $0x1b09f
   143d9:	68 00 00 02 00       	push   $0x20000
   143de:	e8 04 e3 ff ff       	call   126e7 <sprint>
   143e3:	83 c4 20             	add    $0x20,%esp
   143e6:	83 ec 0c             	sub    $0xc,%esp
   143e9:	68 00 00 02 00       	push   $0x20000
   143ee:	e8 74 e0 ff ff       	call   12467 <kpanic>
   143f3:	83 c4 10             	add    $0x10,%esp

	// check for a killed process
	if( pcb->state == STATE_KILLED ) {
   143f6:	8b 45 08             	mov    0x8(%ebp),%eax
   143f9:	8b 40 1c             	mov    0x1c(%eax),%eax
   143fc:	83 f8 07             	cmp    $0x7,%eax
   143ff:	75 10                	jne    14411 <schedule+0x62>
		pcb_zombify( pcb );
   14401:	83 ec 0c             	sub    $0xc,%esp
   14404:	ff 75 08             	pushl  0x8(%ebp)
   14407:	e8 e6 f5 ff ff       	call   139f2 <pcb_zombify>
   1440c:	83 c4 10             	add    $0x10,%esp
		return;
   1440f:	eb 5d                	jmp    1446e <schedule+0xbf>
	}

	// mark it as ready
	pcb->state = STATE_READY;
   14411:	8b 45 08             	mov    0x8(%ebp),%eax
   14414:	c7 40 1c 02 00 00 00 	movl   $0x2,0x1c(%eax)

	// add it to the ready queue
	if( pcb_queue_insert(ready,pcb) != SUCCESS ) {
   1441b:	a1 d0 24 02 00       	mov    0x224d0,%eax
   14420:	83 ec 08             	sub    $0x8,%esp
   14423:	ff 75 08             	pushl  0x8(%ebp)
   14426:	50                   	push   %eax
   14427:	e8 aa fa ff ff       	call   13ed6 <pcb_queue_insert>
   1442c:	83 c4 10             	add    $0x10,%esp
   1442f:	85 c0                	test   %eax,%eax
   14431:	74 3b                	je     1446e <schedule+0xbf>
		PANIC( 0, "schedule insert fail" );
   14433:	83 ec 04             	sub    $0x4,%esp
   14436:	68 dd b2 01 00       	push   $0x1b2dd
   1443b:	6a 00                	push   $0x0
   1443d:	68 a2 03 00 00       	push   $0x3a2
   14442:	68 97 b0 01 00       	push   $0x1b097
   14447:	68 00 b6 01 00       	push   $0x1b600
   1444c:	68 9f b0 01 00       	push   $0x1b09f
   14451:	68 00 00 02 00       	push   $0x20000
   14456:	e8 8c e2 ff ff       	call   126e7 <sprint>
   1445b:	83 c4 20             	add    $0x20,%esp
   1445e:	83 ec 0c             	sub    $0xc,%esp
   14461:	68 00 00 02 00       	push   $0x20000
   14466:	e8 fc df ff ff       	call   12467 <kpanic>
   1446b:	83 c4 10             	add    $0x10,%esp
	}
}
   1446e:	c9                   	leave  
   1446f:	c3                   	ret    

00014470 <dispatch>:
/**
** dispatch()
**
** Select the next process to receive the CPU
*/
void dispatch( void ) {
   14470:	55                   	push   %ebp
   14471:	89 e5                	mov    %esp,%ebp
   14473:	83 ec 18             	sub    $0x18,%esp

	// verify that there is no current process
	assert( current == NULL );
   14476:	a1 14 20 02 00       	mov    0x22014,%eax
   1447b:	85 c0                	test   %eax,%eax
   1447d:	74 3b                	je     144ba <dispatch+0x4a>
   1447f:	83 ec 04             	sub    $0x4,%esp
   14482:	68 f4 b2 01 00       	push   $0x1b2f4
   14487:	6a 00                	push   $0x0
   14489:	68 ae 03 00 00       	push   $0x3ae
   1448e:	68 97 b0 01 00       	push   $0x1b097
   14493:	68 0c b6 01 00       	push   $0x1b60c
   14498:	68 9f b0 01 00       	push   $0x1b09f
   1449d:	68 00 00 02 00       	push   $0x20000
   144a2:	e8 40 e2 ff ff       	call   126e7 <sprint>
   144a7:	83 c4 20             	add    $0x20,%esp
   144aa:	83 ec 0c             	sub    $0xc,%esp
   144ad:	68 00 00 02 00       	push   $0x20000
   144b2:	e8 b0 df ff ff       	call   12467 <kpanic>
   144b7:	83 c4 10             	add    $0x10,%esp

	// grab whoever is at the head of the queue
	int status = pcb_queue_remove( ready, &current );
   144ba:	a1 d0 24 02 00       	mov    0x224d0,%eax
   144bf:	83 ec 08             	sub    $0x8,%esp
   144c2:	68 14 20 02 00       	push   $0x22014
   144c7:	50                   	push   %eax
   144c8:	e8 ef fb ff ff       	call   140bc <pcb_queue_remove>
   144cd:	83 c4 10             	add    $0x10,%esp
   144d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( status != SUCCESS ) {
   144d3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   144d7:	74 53                	je     1452c <dispatch+0xbc>
		sprint( b256, "dispatch queue remove failed, code %d", status );
   144d9:	83 ec 04             	sub    $0x4,%esp
   144dc:	ff 75 f4             	pushl  -0xc(%ebp)
   144df:	68 04 b3 01 00       	push   $0x1b304
   144e4:	68 00 02 02 00       	push   $0x20200
   144e9:	e8 f9 e1 ff ff       	call   126e7 <sprint>
   144ee:	83 c4 10             	add    $0x10,%esp
		PANIC( 0, b256 );
   144f1:	83 ec 04             	sub    $0x4,%esp
   144f4:	68 b9 b1 01 00       	push   $0x1b1b9
   144f9:	6a 00                	push   $0x0
   144fb:	68 b4 03 00 00       	push   $0x3b4
   14500:	68 97 b0 01 00       	push   $0x1b097
   14505:	68 0c b6 01 00       	push   $0x1b60c
   1450a:	68 9f b0 01 00       	push   $0x1b09f
   1450f:	68 00 00 02 00       	push   $0x20000
   14514:	e8 ce e1 ff ff       	call   126e7 <sprint>
   14519:	83 c4 20             	add    $0x20,%esp
   1451c:	83 ec 0c             	sub    $0xc,%esp
   1451f:	68 00 00 02 00       	push   $0x20000
   14524:	e8 3e df ff ff       	call   12467 <kpanic>
   14529:	83 c4 10             	add    $0x10,%esp
	}

	// set the process up for success
	current->state = STATE_RUNNING;
   1452c:	a1 14 20 02 00       	mov    0x22014,%eax
   14531:	c7 40 1c 03 00 00 00 	movl   $0x3,0x1c(%eax)
	current->ticks = QUANTUM_STANDARD;
   14538:	a1 14 20 02 00       	mov    0x22014,%eax
   1453d:	c7 40 24 03 00 00 00 	movl   $0x3,0x24(%eax)
}
   14544:	90                   	nop
   14545:	c9                   	leave  
   14546:	c3                   	ret    

00014547 <ctx_dump>:
** Dumps the contents of this process context to the console
**
** @param msg[in]   An optional message to print before the dump
** @param c[in]     The context to dump out
*/
void ctx_dump( const char *msg, register context_t *c ) {
   14547:	55                   	push   %ebp
   14548:	89 e5                	mov    %esp,%ebp
   1454a:	57                   	push   %edi
   1454b:	56                   	push   %esi
   1454c:	53                   	push   %ebx
   1454d:	83 ec 1c             	sub    $0x1c,%esp
   14550:	8b 5d 0c             	mov    0xc(%ebp),%ebx

	// first, the message (if there is one)
	if( msg ) {
   14553:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   14557:	74 0e                	je     14567 <ctx_dump+0x20>
		cio_puts( msg );
   14559:	83 ec 0c             	sub    $0xc,%esp
   1455c:	ff 75 08             	pushl  0x8(%ebp)
   1455f:	e8 49 c9 ff ff       	call   10ead <cio_puts>
   14564:	83 c4 10             	add    $0x10,%esp
	}

	// the pointer
	cio_printf( " @ %08x:\n", (uint32_t) c );
   14567:	89 d8                	mov    %ebx,%eax
   14569:	83 ec 08             	sub    $0x8,%esp
   1456c:	50                   	push   %eax
   1456d:	68 2a b3 01 00       	push   $0x1b32a
   14572:	e8 b0 cf ff ff       	call   11527 <cio_printf>
   14577:	83 c4 10             	add    $0x10,%esp

	// if it's NULL, why did you bother calling me?
	if( c == NULL ) {
   1457a:	85 db                	test   %ebx,%ebx
   1457c:	75 15                	jne    14593 <ctx_dump+0x4c>
		cio_puts( " NULL???\n" );
   1457e:	83 ec 0c             	sub    $0xc,%esp
   14581:	68 34 b3 01 00       	push   $0x1b334
   14586:	e8 22 c9 ff ff       	call   10ead <cio_puts>
   1458b:	83 c4 10             	add    $0x10,%esp
		return;
   1458e:	e9 9e 00 00 00       	jmp    14631 <ctx_dump+0xea>
	}

	// now, the contents
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
				  c->es & 0xff, c->ds & 0xff, c->cs & 0xff );
   14593:	8b 43 40             	mov    0x40(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   14596:	0f b6 c0             	movzbl %al,%eax
   14599:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				  c->es & 0xff, c->ds & 0xff, c->cs & 0xff );
   1459c:	8b 43 10             	mov    0x10(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   1459f:	0f b6 f8             	movzbl %al,%edi
				  c->es & 0xff, c->ds & 0xff, c->cs & 0xff );
   145a2:	8b 43 0c             	mov    0xc(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145a5:	0f b6 f0             	movzbl %al,%esi
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
   145a8:	8b 43 08             	mov    0x8(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145ab:	0f b6 c8             	movzbl %al,%ecx
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
   145ae:	8b 43 04             	mov    0x4(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145b1:	0f b6 d0             	movzbl %al,%edx
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
   145b4:	8b 03                	mov    (%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145b6:	0f b6 c0             	movzbl %al,%eax
   145b9:	83 ec 04             	sub    $0x4,%esp
   145bc:	ff 75 e4             	pushl  -0x1c(%ebp)
   145bf:	57                   	push   %edi
   145c0:	56                   	push   %esi
   145c1:	51                   	push   %ecx
   145c2:	52                   	push   %edx
   145c3:	50                   	push   %eax
   145c4:	68 40 b3 01 00       	push   $0x1b340
   145c9:	e8 59 cf ff ff       	call   11527 <cio_printf>
   145ce:	83 c4 20             	add    $0x20,%esp
	cio_printf( "  edi %08x esi %08x ebp %08x esp %08x\n",
   145d1:	8b 73 20             	mov    0x20(%ebx),%esi
   145d4:	8b 4b 1c             	mov    0x1c(%ebx),%ecx
   145d7:	8b 53 18             	mov    0x18(%ebx),%edx
   145da:	8b 43 14             	mov    0x14(%ebx),%eax
   145dd:	83 ec 0c             	sub    $0xc,%esp
   145e0:	56                   	push   %esi
   145e1:	51                   	push   %ecx
   145e2:	52                   	push   %edx
   145e3:	50                   	push   %eax
   145e4:	68 74 b3 01 00       	push   $0x1b374
   145e9:	e8 39 cf ff ff       	call   11527 <cio_printf>
   145ee:	83 c4 20             	add    $0x20,%esp
				  c->edi, c->esi, c->ebp, c->esp );
	cio_printf( "  ebx %08x edx %08x ecx %08x eax %08x\n",
   145f1:	8b 73 30             	mov    0x30(%ebx),%esi
   145f4:	8b 4b 2c             	mov    0x2c(%ebx),%ecx
   145f7:	8b 53 28             	mov    0x28(%ebx),%edx
   145fa:	8b 43 24             	mov    0x24(%ebx),%eax
   145fd:	83 ec 0c             	sub    $0xc,%esp
   14600:	56                   	push   %esi
   14601:	51                   	push   %ecx
   14602:	52                   	push   %edx
   14603:	50                   	push   %eax
   14604:	68 9c b3 01 00       	push   $0x1b39c
   14609:	e8 19 cf ff ff       	call   11527 <cio_printf>
   1460e:	83 c4 20             	add    $0x20,%esp
				  c->ebx, c->edx, c->ecx, c->eax );
	cio_printf( "  vec %08x cod %08x eip %08x efl %08x\n",
   14611:	8b 73 44             	mov    0x44(%ebx),%esi
   14614:	8b 4b 3c             	mov    0x3c(%ebx),%ecx
   14617:	8b 53 38             	mov    0x38(%ebx),%edx
   1461a:	8b 43 34             	mov    0x34(%ebx),%eax
   1461d:	83 ec 0c             	sub    $0xc,%esp
   14620:	56                   	push   %esi
   14621:	51                   	push   %ecx
   14622:	52                   	push   %edx
   14623:	50                   	push   %eax
   14624:	68 c4 b3 01 00       	push   $0x1b3c4
   14629:	e8 f9 ce ff ff       	call   11527 <cio_printf>
   1462e:	83 c4 20             	add    $0x20,%esp
				  c->vector, c->code, c->eip, c->eflags );
}
   14631:	8d 65 f4             	lea    -0xc(%ebp),%esp
   14634:	5b                   	pop    %ebx
   14635:	5e                   	pop    %esi
   14636:	5f                   	pop    %edi
   14637:	5d                   	pop    %ebp
   14638:	c3                   	ret    

00014639 <ctx_dump_all>:
**
** dump the process context for all active processes
**
** @param msg[in]  Optional message to print
*/
void ctx_dump_all( const char *msg ) {
   14639:	55                   	push   %ebp
   1463a:	89 e5                	mov    %esp,%ebp
   1463c:	53                   	push   %ebx
   1463d:	83 ec 14             	sub    $0x14,%esp

	if( msg != NULL ) {
   14640:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   14644:	74 0e                	je     14654 <ctx_dump_all+0x1b>
		cio_puts( msg );
   14646:	83 ec 0c             	sub    $0xc,%esp
   14649:	ff 75 08             	pushl  0x8(%ebp)
   1464c:	e8 5c c8 ff ff       	call   10ead <cio_puts>
   14651:	83 c4 10             	add    $0x10,%esp
	}

	int n = 0;
   14654:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	register pcb_t *pcb = ptable;
   1465b:	bb 20 20 02 00       	mov    $0x22020,%ebx
	for( int i = 0; i < N_PROCS; ++i, ++pcb ) {
   14660:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   14667:	eb 39                	jmp    146a2 <ctx_dump_all+0x69>
		if( pcb->state != STATE_UNUSED ) {
   14669:	8b 43 1c             	mov    0x1c(%ebx),%eax
   1466c:	85 c0                	test   %eax,%eax
   1466e:	74 2b                	je     1469b <ctx_dump_all+0x62>
			++n;
   14670:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
			cio_printf( "%2d(%d): ", n, pcb->pid );
   14674:	8b 43 18             	mov    0x18(%ebx),%eax
   14677:	83 ec 04             	sub    $0x4,%esp
   1467a:	50                   	push   %eax
   1467b:	ff 75 f4             	pushl  -0xc(%ebp)
   1467e:	68 eb b3 01 00       	push   $0x1b3eb
   14683:	e8 9f ce ff ff       	call   11527 <cio_printf>
   14688:	83 c4 10             	add    $0x10,%esp
			ctx_dump( NULL, pcb->context );
   1468b:	8b 03                	mov    (%ebx),%eax
   1468d:	83 ec 08             	sub    $0x8,%esp
   14690:	50                   	push   %eax
   14691:	6a 00                	push   $0x0
   14693:	e8 af fe ff ff       	call   14547 <ctx_dump>
   14698:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < N_PROCS; ++i, ++pcb ) {
   1469b:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   1469f:	83 c3 30             	add    $0x30,%ebx
   146a2:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   146a6:	7e c1                	jle    14669 <ctx_dump_all+0x30>
		}
	}
}
   146a8:	90                   	nop
   146a9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   146ac:	c9                   	leave  
   146ad:	c3                   	ret    

000146ae <pcb_dump>:
**
** @param msg[in]  An optional message to print before the dump
** @param pcb[in]  The PCB to dump
** @param all[in]  Dump all the contents?
*/
void pcb_dump( const char *msg, register pcb_t *pcb, bool_t all ) {
   146ae:	55                   	push   %ebp
   146af:	89 e5                	mov    %esp,%ebp
   146b1:	56                   	push   %esi
   146b2:	53                   	push   %ebx
   146b3:	83 ec 10             	sub    $0x10,%esp
   146b6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
   146b9:	8b 45 10             	mov    0x10(%ebp),%eax
   146bc:	88 45 f4             	mov    %al,-0xc(%ebp)

	// first, the message (if there is one)
	if( msg ) {
   146bf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   146c3:	74 0e                	je     146d3 <pcb_dump+0x25>
		cio_puts( msg );
   146c5:	83 ec 0c             	sub    $0xc,%esp
   146c8:	ff 75 08             	pushl  0x8(%ebp)
   146cb:	e8 dd c7 ff ff       	call   10ead <cio_puts>
   146d0:	83 c4 10             	add    $0x10,%esp
	}

	// the pointer
	cio_printf( " @ %08x:", (uint32_t) pcb );
   146d3:	89 d8                	mov    %ebx,%eax
   146d5:	83 ec 08             	sub    $0x8,%esp
   146d8:	50                   	push   %eax
   146d9:	68 f5 b3 01 00       	push   $0x1b3f5
   146de:	e8 44 ce ff ff       	call   11527 <cio_printf>
   146e3:	83 c4 10             	add    $0x10,%esp

	// if it's NULL, why did you bother calling me?
	if( pcb == NULL ) {
   146e6:	85 db                	test   %ebx,%ebx
   146e8:	75 15                	jne    146ff <pcb_dump+0x51>
		cio_puts( " NULL???\n" );
   146ea:	83 ec 0c             	sub    $0xc,%esp
   146ed:	68 34 b3 01 00       	push   $0x1b334
   146f2:	e8 b6 c7 ff ff       	call   10ead <cio_puts>
   146f7:	83 c4 10             	add    $0x10,%esp
		return;
   146fa:	e9 e7 00 00 00       	jmp    147e6 <pcb_dump+0x138>
	}

	cio_printf( " %d %s", pcb->pid,
			pcb->state >= N_STATES ? "???" : state_str[pcb->state] );
   146ff:	8b 43 1c             	mov    0x1c(%ebx),%eax
	cio_printf( " %d %s", pcb->pid,
   14702:	83 f8 08             	cmp    $0x8,%eax
   14705:	77 0e                	ja     14715 <pcb_dump+0x67>
			pcb->state >= N_STATES ? "???" : state_str[pcb->state] );
   14707:	8b 43 1c             	mov    0x1c(%ebx),%eax
	cio_printf( " %d %s", pcb->pid,
   1470a:	c1 e0 02             	shl    $0x2,%eax
   1470d:	8d 90 40 b0 01 00    	lea    0x1b040(%eax),%edx
   14713:	eb 05                	jmp    1471a <pcb_dump+0x6c>
   14715:	ba fe b3 01 00       	mov    $0x1b3fe,%edx
   1471a:	8b 43 18             	mov    0x18(%ebx),%eax
   1471d:	83 ec 04             	sub    $0x4,%esp
   14720:	52                   	push   %edx
   14721:	50                   	push   %eax
   14722:	68 02 b4 01 00       	push   $0x1b402
   14727:	e8 fb cd ff ff       	call   11527 <cio_printf>
   1472c:	83 c4 10             	add    $0x10,%esp

	if( !all ) {
   1472f:	80 7d f4 00          	cmpb   $0x0,-0xc(%ebp)
   14733:	0f 84 ac 00 00 00    	je     147e5 <pcb_dump+0x137>
		return;
	}

	// now, the rest of the contents
	cio_printf( " %s",
			pcb->priority >= N_PRIOS ? "???" : prio_str[pcb->priority] );
   14739:	8b 43 20             	mov    0x20(%ebx),%eax
	cio_printf( " %s",
   1473c:	83 f8 03             	cmp    $0x3,%eax
   1473f:	77 11                	ja     14752 <pcb_dump+0xa4>
			pcb->priority >= N_PRIOS ? "???" : prio_str[pcb->priority] );
   14741:	8b 53 20             	mov    0x20(%ebx),%edx
	cio_printf( " %s",
   14744:	89 d0                	mov    %edx,%eax
   14746:	c1 e0 02             	shl    $0x2,%eax
   14749:	01 d0                	add    %edx,%eax
   1474b:	05 64 b0 01 00       	add    $0x1b064,%eax
   14750:	eb 05                	jmp    14757 <pcb_dump+0xa9>
   14752:	b8 fe b3 01 00       	mov    $0x1b3fe,%eax
   14757:	83 ec 08             	sub    $0x8,%esp
   1475a:	50                   	push   %eax
   1475b:	68 09 b4 01 00       	push   $0x1b409
   14760:	e8 c2 cd ff ff       	call   11527 <cio_printf>
   14765:	83 c4 10             	add    $0x10,%esp

	cio_printf( " ticks %u xit %d wake %08x\n",
   14768:	8b 4b 10             	mov    0x10(%ebx),%ecx
   1476b:	8b 53 14             	mov    0x14(%ebx),%edx
   1476e:	8b 43 24             	mov    0x24(%ebx),%eax
   14771:	51                   	push   %ecx
   14772:	52                   	push   %edx
   14773:	50                   	push   %eax
   14774:	68 0d b4 01 00       	push   $0x1b40d
   14779:	e8 a9 cd ff ff       	call   11527 <cio_printf>
   1477e:	83 c4 10             	add    $0x10,%esp
				pcb->ticks, pcb->exit_status, pcb->wakeup );

	cio_printf( " parent %08x", (uint32_t)pcb->parent );
   14781:	8b 43 0c             	mov    0xc(%ebx),%eax
   14784:	83 ec 08             	sub    $0x8,%esp
   14787:	50                   	push   %eax
   14788:	68 29 b4 01 00       	push   $0x1b429
   1478d:	e8 95 cd ff ff       	call   11527 <cio_printf>
   14792:	83 c4 10             	add    $0x10,%esp
	if( pcb->parent != NULL ) {
   14795:	8b 43 0c             	mov    0xc(%ebx),%eax
   14798:	85 c0                	test   %eax,%eax
   1479a:	74 17                	je     147b3 <pcb_dump+0x105>
		cio_printf( " (%u)", pcb->parent->pid );
   1479c:	8b 43 0c             	mov    0xc(%ebx),%eax
   1479f:	8b 40 18             	mov    0x18(%eax),%eax
   147a2:	83 ec 08             	sub    $0x8,%esp
   147a5:	50                   	push   %eax
   147a6:	68 36 b4 01 00       	push   $0x1b436
   147ab:	e8 77 cd ff ff       	call   11527 <cio_printf>
   147b0:	83 c4 10             	add    $0x10,%esp
	}

	cio_printf( " next %08x context %08x stk %08x (%u)",
   147b3:	8b 43 28             	mov    0x28(%ebx),%eax
			(uint32_t) pcb->next, (uint32_t) pcb->context,
			(uint32_t) pcb->stack, pcb->stkpgs );
   147b6:	8b 53 04             	mov    0x4(%ebx),%edx
	cio_printf( " next %08x context %08x stk %08x (%u)",
   147b9:	89 d6                	mov    %edx,%esi
			(uint32_t) pcb->next, (uint32_t) pcb->context,
   147bb:	8b 13                	mov    (%ebx),%edx
	cio_printf( " next %08x context %08x stk %08x (%u)",
   147bd:	89 d1                	mov    %edx,%ecx
			(uint32_t) pcb->next, (uint32_t) pcb->context,
   147bf:	8b 53 08             	mov    0x8(%ebx),%edx
	cio_printf( " next %08x context %08x stk %08x (%u)",
   147c2:	83 ec 0c             	sub    $0xc,%esp
   147c5:	50                   	push   %eax
   147c6:	56                   	push   %esi
   147c7:	51                   	push   %ecx
   147c8:	52                   	push   %edx
   147c9:	68 3c b4 01 00       	push   $0x1b43c
   147ce:	e8 54 cd ff ff       	call   11527 <cio_printf>
   147d3:	83 c4 20             	add    $0x20,%esp

	cio_putchar( '\n' );
   147d6:	83 ec 0c             	sub    $0xc,%esp
   147d9:	6a 0a                	push   $0xa
   147db:	e8 8d c5 ff ff       	call   10d6d <cio_putchar>
   147e0:	83 c4 10             	add    $0x10,%esp
   147e3:	eb 01                	jmp    147e6 <pcb_dump+0x138>
		return;
   147e5:	90                   	nop
}
   147e6:	8d 65 f8             	lea    -0x8(%ebp),%esp
   147e9:	5b                   	pop    %ebx
   147ea:	5e                   	pop    %esi
   147eb:	5d                   	pop    %ebp
   147ec:	c3                   	ret    

000147ed <pcb_queue_dump>:
**
** @param msg[in]       Optional message to print
** @param queue[in]     The queue to dump
** @param contents[in]  Also dump (some) contents?
*/
void pcb_queue_dump( const char *msg, pcb_queue_t queue, bool_t contents ) {
   147ed:	55                   	push   %ebp
   147ee:	89 e5                	mov    %esp,%ebp
   147f0:	83 ec 28             	sub    $0x28,%esp
   147f3:	8b 45 10             	mov    0x10(%ebp),%eax
   147f6:	88 45 e4             	mov    %al,-0x1c(%ebp)

	// report on this queue
	cio_printf( "%s: ", msg );
   147f9:	83 ec 08             	sub    $0x8,%esp
   147fc:	ff 75 08             	pushl  0x8(%ebp)
   147ff:	68 62 b4 01 00       	push   $0x1b462
   14804:	e8 1e cd ff ff       	call   11527 <cio_printf>
   14809:	83 c4 10             	add    $0x10,%esp
	if( queue == NULL ) {
   1480c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   14810:	75 15                	jne    14827 <pcb_queue_dump+0x3a>
		cio_puts( "NULL???\n" );
   14812:	83 ec 0c             	sub    $0xc,%esp
   14815:	68 67 b4 01 00       	push   $0x1b467
   1481a:	e8 8e c6 ff ff       	call   10ead <cio_puts>
   1481f:	83 c4 10             	add    $0x10,%esp
		return;
   14822:	e9 d7 00 00 00       	jmp    148fe <pcb_queue_dump+0x111>
	}

	// first, the basic data
	cio_printf( "head %08x tail %08x",
			(uint32_t) queue->head, (uint32_t) queue->tail );
   14827:	8b 45 0c             	mov    0xc(%ebp),%eax
   1482a:	8b 40 04             	mov    0x4(%eax),%eax
	cio_printf( "head %08x tail %08x",
   1482d:	89 c2                	mov    %eax,%edx
			(uint32_t) queue->head, (uint32_t) queue->tail );
   1482f:	8b 45 0c             	mov    0xc(%ebp),%eax
   14832:	8b 00                	mov    (%eax),%eax
	cio_printf( "head %08x tail %08x",
   14834:	83 ec 04             	sub    $0x4,%esp
   14837:	52                   	push   %edx
   14838:	50                   	push   %eax
   14839:	68 70 b4 01 00       	push   $0x1b470
   1483e:	e8 e4 cc ff ff       	call   11527 <cio_printf>
   14843:	83 c4 10             	add    $0x10,%esp

	// next, how the queue is ordered
	cio_printf( " order %s\n",
			queue->order >= N_ORDERINGS ? "????" : ord_str[queue->order] );
   14846:	8b 45 0c             	mov    0xc(%ebp),%eax
   14849:	8b 40 08             	mov    0x8(%eax),%eax
	cio_printf( " order %s\n",
   1484c:	83 f8 03             	cmp    $0x3,%eax
   1484f:	77 14                	ja     14865 <pcb_queue_dump+0x78>
			queue->order >= N_ORDERINGS ? "????" : ord_str[queue->order] );
   14851:	8b 45 0c             	mov    0xc(%ebp),%eax
   14854:	8b 50 08             	mov    0x8(%eax),%edx
	cio_printf( " order %s\n",
   14857:	89 d0                	mov    %edx,%eax
   14859:	c1 e0 02             	shl    $0x2,%eax
   1485c:	01 d0                	add    %edx,%eax
   1485e:	05 78 b0 01 00       	add    $0x1b078,%eax
   14863:	eb 05                	jmp    1486a <pcb_queue_dump+0x7d>
   14865:	b8 84 b4 01 00       	mov    $0x1b484,%eax
   1486a:	83 ec 08             	sub    $0x8,%esp
   1486d:	50                   	push   %eax
   1486e:	68 89 b4 01 00       	push   $0x1b489
   14873:	e8 af cc ff ff       	call   11527 <cio_printf>
   14878:	83 c4 10             	add    $0x10,%esp

	// if there are members in the queue, dump the first few PIDs
	if( contents && queue->head != NULL ) {
   1487b:	80 7d e4 00          	cmpb   $0x0,-0x1c(%ebp)
   1487f:	74 7d                	je     148fe <pcb_queue_dump+0x111>
   14881:	8b 45 0c             	mov    0xc(%ebp),%eax
   14884:	8b 00                	mov    (%eax),%eax
   14886:	85 c0                	test   %eax,%eax
   14888:	74 74                	je     148fe <pcb_queue_dump+0x111>
		cio_puts( " PIDs: " );
   1488a:	83 ec 0c             	sub    $0xc,%esp
   1488d:	68 94 b4 01 00       	push   $0x1b494
   14892:	e8 16 c6 ff ff       	call   10ead <cio_puts>
   14897:	83 c4 10             	add    $0x10,%esp
		pcb_t *tmp = queue->head;
   1489a:	8b 45 0c             	mov    0xc(%ebp),%eax
   1489d:	8b 00                	mov    (%eax),%eax
   1489f:	89 45 f4             	mov    %eax,-0xc(%ebp)
		for( int i = 0; i < 5 && tmp != NULL; ++i, tmp = tmp->next ) {
   148a2:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   148a9:	eb 24                	jmp    148cf <pcb_queue_dump+0xe2>
			cio_printf( " [%u]", tmp->pid );
   148ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
   148ae:	8b 40 18             	mov    0x18(%eax),%eax
   148b1:	83 ec 08             	sub    $0x8,%esp
   148b4:	50                   	push   %eax
   148b5:	68 9c b4 01 00       	push   $0x1b49c
   148ba:	e8 68 cc ff ff       	call   11527 <cio_printf>
   148bf:	83 c4 10             	add    $0x10,%esp
		for( int i = 0; i < 5 && tmp != NULL; ++i, tmp = tmp->next ) {
   148c2:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   148c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
   148c9:	8b 40 08             	mov    0x8(%eax),%eax
   148cc:	89 45 f4             	mov    %eax,-0xc(%ebp)
   148cf:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
   148d3:	7f 06                	jg     148db <pcb_queue_dump+0xee>
   148d5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   148d9:	75 d0                	jne    148ab <pcb_queue_dump+0xbe>
		}

		if( tmp != NULL ) {
   148db:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   148df:	74 10                	je     148f1 <pcb_queue_dump+0x104>
			cio_puts( " ..." );
   148e1:	83 ec 0c             	sub    $0xc,%esp
   148e4:	68 a2 b4 01 00       	push   $0x1b4a2
   148e9:	e8 bf c5 ff ff       	call   10ead <cio_puts>
   148ee:	83 c4 10             	add    $0x10,%esp
		}

		cio_putchar( '\n' );
   148f1:	83 ec 0c             	sub    $0xc,%esp
   148f4:	6a 0a                	push   $0xa
   148f6:	e8 72 c4 ff ff       	call   10d6d <cio_putchar>
   148fb:	83 c4 10             	add    $0x10,%esp
	}
}
   148fe:	c9                   	leave  
   148ff:	c3                   	ret    

00014900 <ptable_dump>:
** dump the contents of the "active processes" table
**
** @param msg[in]  Optional message to print
** @param all[in]  Dump all or only part of the relevant data
*/
void ptable_dump( const char *msg, bool_t all ) {
   14900:	55                   	push   %ebp
   14901:	89 e5                	mov    %esp,%ebp
   14903:	53                   	push   %ebx
   14904:	83 ec 24             	sub    $0x24,%esp
   14907:	8b 45 0c             	mov    0xc(%ebp),%eax
   1490a:	88 45 e4             	mov    %al,-0x1c(%ebp)

	if( msg ) {
   1490d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   14911:	74 0e                	je     14921 <ptable_dump+0x21>
		cio_puts( msg );
   14913:	83 ec 0c             	sub    $0xc,%esp
   14916:	ff 75 08             	pushl  0x8(%ebp)
   14919:	e8 8f c5 ff ff       	call   10ead <cio_puts>
   1491e:	83 c4 10             	add    $0x10,%esp
	}
	cio_putchar( ' ' );
   14921:	83 ec 0c             	sub    $0xc,%esp
   14924:	6a 20                	push   $0x20
   14926:	e8 42 c4 ff ff       	call   10d6d <cio_putchar>
   1492b:	83 c4 10             	add    $0x10,%esp

	int used = 0;
   1492e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	int empty = 0;
   14935:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

	register pcb_t *pcb = ptable;
   1493c:	bb 20 20 02 00       	mov    $0x22020,%ebx
	for( int i = 0; i < N_PROCS; ++i ) {
   14941:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   14948:	eb 54                	jmp    1499e <ptable_dump+0x9e>
		if( pcb->state == STATE_UNUSED ) {
   1494a:	8b 43 1c             	mov    0x1c(%ebx),%eax
   1494d:	85 c0                	test   %eax,%eax
   1494f:	75 06                	jne    14957 <ptable_dump+0x57>

			// an empty slot
			++empty;
   14951:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   14955:	eb 43                	jmp    1499a <ptable_dump+0x9a>

		} else {

			// a non-empty slot
			++used;
   14957:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

			// if not dumping everything, add commas if needed
			if( !all && used ) {
   1495b:	80 7d e4 00          	cmpb   $0x0,-0x1c(%ebp)
   1495f:	75 13                	jne    14974 <ptable_dump+0x74>
   14961:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   14965:	74 0d                	je     14974 <ptable_dump+0x74>
				cio_putchar( ',' );
   14967:	83 ec 0c             	sub    $0xc,%esp
   1496a:	6a 2c                	push   $0x2c
   1496c:	e8 fc c3 ff ff       	call   10d6d <cio_putchar>
   14971:	83 c4 10             	add    $0x10,%esp
			}

			// report the table slot #
			cio_printf( " #%d:", i );
   14974:	83 ec 08             	sub    $0x8,%esp
   14977:	ff 75 ec             	pushl  -0x14(%ebp)
   1497a:	68 a7 b4 01 00       	push   $0x1b4a7
   1497f:	e8 a3 cb ff ff       	call   11527 <cio_printf>
   14984:	83 c4 10             	add    $0x10,%esp

			// and dump the contents
			pcb_dump( NULL, pcb, all );
   14987:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
   1498b:	83 ec 04             	sub    $0x4,%esp
   1498e:	50                   	push   %eax
   1498f:	53                   	push   %ebx
   14990:	6a 00                	push   $0x0
   14992:	e8 17 fd ff ff       	call   146ae <pcb_dump>
   14997:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < N_PROCS; ++i ) {
   1499a:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   1499e:	83 7d ec 18          	cmpl   $0x18,-0x14(%ebp)
   149a2:	7e a6                	jle    1494a <ptable_dump+0x4a>
		}
	}

	// only need this if we're doing one-line output
	if( !all ) {
   149a4:	80 7d e4 00          	cmpb   $0x0,-0x1c(%ebp)
   149a8:	75 0d                	jne    149b7 <ptable_dump+0xb7>
		cio_putchar( '\n' );
   149aa:	83 ec 0c             	sub    $0xc,%esp
   149ad:	6a 0a                	push   $0xa
   149af:	e8 b9 c3 ff ff       	call   10d6d <cio_putchar>
   149b4:	83 c4 10             	add    $0x10,%esp
	}

	// sanity check - make sure we saw the correct number of table slots
	if( (used + empty) != N_PROCS ) {
   149b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
   149ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
   149bd:	01 d0                	add    %edx,%eax
   149bf:	83 f8 19             	cmp    $0x19,%eax
   149c2:	74 21                	je     149e5 <ptable_dump+0xe5>
		cio_printf( "Table size %d, used %d + empty %d = %d???\n",
   149c4:	8b 55 f4             	mov    -0xc(%ebp),%edx
   149c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
   149ca:	01 d0                	add    %edx,%eax
   149cc:	83 ec 0c             	sub    $0xc,%esp
   149cf:	50                   	push   %eax
   149d0:	ff 75 f0             	pushl  -0x10(%ebp)
   149d3:	ff 75 f4             	pushl  -0xc(%ebp)
   149d6:	6a 19                	push   $0x19
   149d8:	68 b0 b4 01 00       	push   $0x1b4b0
   149dd:	e8 45 cb ff ff       	call   11527 <cio_printf>
   149e2:	83 c4 20             	add    $0x20,%esp
					  N_PROCS, used, empty, used + empty );
	}
}
   149e5:	90                   	nop
   149e6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   149e9:	c9                   	leave  
   149ea:	c3                   	ret    

000149eb <ptable_dump_counts>:
** Name:    ptable_dump_counts
**
** Prints basic information about the process table (number of
** entries, number with each process state, etc.).
*/
void ptable_dump_counts( void ) {
   149eb:	55                   	push   %ebp
   149ec:	89 e5                	mov    %esp,%ebp
   149ee:	57                   	push   %edi
   149ef:	83 ec 34             	sub    $0x34,%esp
	uint_t nstate[N_STATES] = { 0 };
   149f2:	8d 55 c8             	lea    -0x38(%ebp),%edx
   149f5:	b8 00 00 00 00       	mov    $0x0,%eax
   149fa:	b9 09 00 00 00       	mov    $0x9,%ecx
   149ff:	89 d7                	mov    %edx,%edi
   14a01:	f3 ab                	rep stos %eax,%es:(%edi)
	uint_t unknown = 0;
   14a03:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	int n = 0;
   14a0a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	pcb_t *ptr = ptable;
   14a11:	c7 45 ec 20 20 02 00 	movl   $0x22020,-0x14(%ebp)
	while( n < N_PROCS ) {
   14a18:	eb 2a                	jmp    14a44 <ptable_dump_counts+0x59>
		if( ptr->state < 0 || ptr->state >= N_STATES ) {
   14a1a:	8b 45 ec             	mov    -0x14(%ebp),%eax
   14a1d:	8b 40 1c             	mov    0x1c(%eax),%eax
   14a20:	83 f8 08             	cmp    $0x8,%eax
   14a23:	76 06                	jbe    14a2b <ptable_dump_counts+0x40>
			++unknown;
   14a25:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   14a29:	eb 11                	jmp    14a3c <ptable_dump_counts+0x51>
		} else {
			++nstate[ptr->state];
   14a2b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   14a2e:	8b 40 1c             	mov    0x1c(%eax),%eax
   14a31:	8b 54 85 c8          	mov    -0x38(%ebp,%eax,4),%edx
   14a35:	83 c2 01             	add    $0x1,%edx
   14a38:	89 54 85 c8          	mov    %edx,-0x38(%ebp,%eax,4)
		}
		++n;
   14a3c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
		++ptr;
   14a40:	83 45 ec 30          	addl   $0x30,-0x14(%ebp)
	while( n < N_PROCS ) {
   14a44:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   14a48:	7e d0                	jle    14a1a <ptable_dump_counts+0x2f>
	}

	cio_printf( "Ptable: %u ***", unknown );
   14a4a:	83 ec 08             	sub    $0x8,%esp
   14a4d:	ff 75 f4             	pushl  -0xc(%ebp)
   14a50:	68 db b4 01 00       	push   $0x1b4db
   14a55:	e8 cd ca ff ff       	call   11527 <cio_printf>
   14a5a:	83 c4 10             	add    $0x10,%esp
	for( n = 0; n < N_STATES; ++n ) {
   14a5d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   14a64:	eb 34                	jmp    14a9a <ptable_dump_counts+0xaf>
		if( nstate[n] ) {
   14a66:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14a69:	8b 44 85 c8          	mov    -0x38(%ebp,%eax,4),%eax
   14a6d:	85 c0                	test   %eax,%eax
   14a6f:	74 25                	je     14a96 <ptable_dump_counts+0xab>
			cio_printf( " %u %s", nstate[n],
					state_str[n] != NULL ? state_str[n] : "???" );
   14a71:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14a74:	c1 e0 02             	shl    $0x2,%eax
   14a77:	8d 90 40 b0 01 00    	lea    0x1b040(%eax),%edx
			cio_printf( " %u %s", nstate[n],
   14a7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14a80:	8b 44 85 c8          	mov    -0x38(%ebp,%eax,4),%eax
   14a84:	83 ec 04             	sub    $0x4,%esp
   14a87:	52                   	push   %edx
   14a88:	50                   	push   %eax
   14a89:	68 ea b4 01 00       	push   $0x1b4ea
   14a8e:	e8 94 ca ff ff       	call   11527 <cio_printf>
   14a93:	83 c4 10             	add    $0x10,%esp
	for( n = 0; n < N_STATES; ++n ) {
   14a96:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   14a9a:	83 7d f0 08          	cmpl   $0x8,-0x10(%ebp)
   14a9e:	7e c6                	jle    14a66 <ptable_dump_counts+0x7b>
		}
	}
	cio_putchar( '\n' );
   14aa0:	83 ec 0c             	sub    $0xc,%esp
   14aa3:	6a 0a                	push   $0xa
   14aa5:	e8 c3 c2 ff ff       	call   10d6d <cio_putchar>
   14aaa:	83 c4 10             	add    $0x10,%esp
}
   14aad:	90                   	nop
   14aae:	8b 7d fc             	mov    -0x4(%ebp),%edi
   14ab1:	c9                   	leave  
   14ab2:	c3                   	ret    

00014ab3 <sio_isr>:
** events (as described by the SIO controller).
**
** @param vector   The interrupt vector number for this interrupt
** @param ecode    The error code associated with this interrupt
*/
static void sio_isr( int vector, int ecode ) {
   14ab3:	55                   	push   %ebp
   14ab4:	89 e5                	mov    %esp,%ebp
   14ab6:	83 ec 58             	sub    $0x58,%esp
   14ab9:	c7 45 e8 fa 03 00 00 	movl   $0x3fa,-0x18(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14ac0:	8b 45 e8             	mov    -0x18(%ebp),%eax
   14ac3:	89 c2                	mov    %eax,%edx
   14ac5:	ec                   	in     (%dx),%al
   14ac6:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
   14ac9:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
	//

	for(;;) {

		// get the "pending event" indicator
		int iir = inb( UA4_IIR ) & UA4_IIR_INT_PRI_MASK;
   14acd:	0f b6 c0             	movzbl %al,%eax
   14ad0:	83 e0 0f             	and    $0xf,%eax
   14ad3:	89 45 f0             	mov    %eax,-0x10(%ebp)

		// process this event
		switch( iir ) {
   14ad6:	83 7d f0 0c          	cmpl   $0xc,-0x10(%ebp)
   14ada:	0f 87 95 02 00 00    	ja     14d75 <sio_isr+0x2c2>
   14ae0:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14ae3:	c1 e0 02             	shl    $0x2,%eax
   14ae6:	05 dc b6 01 00       	add    $0x1b6dc,%eax
   14aeb:	8b 00                	mov    (%eax),%eax
   14aed:	ff e0                	jmp    *%eax
   14aef:	c7 45 e0 fd 03 00 00 	movl   $0x3fd,-0x20(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14af6:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14af9:	89 c2                	mov    %eax,%edx
   14afb:	ec                   	in     (%dx),%al
   14afc:	88 45 df             	mov    %al,-0x21(%ebp)
	return data;
   14aff:	0f b6 45 df          	movzbl -0x21(%ebp),%eax

		case UA4_IIR_LINE_STATUS:
			// shouldn't happen, but just in case....
			cio_printf( "** SIO int, LSR = %02x\n", inb(UA4_LSR) );
   14b03:	0f b6 c0             	movzbl %al,%eax
   14b06:	83 ec 08             	sub    $0x8,%esp
   14b09:	50                   	push   %eax
   14b0a:	68 18 b6 01 00       	push   $0x1b618
   14b0f:	e8 13 ca ff ff       	call   11527 <cio_printf>
   14b14:	83 c4 10             	add    $0x10,%esp
			break;
   14b17:	e9 b6 02 00 00       	jmp    14dd2 <sio_isr+0x31f>
   14b1c:	c7 45 d8 f8 03 00 00 	movl   $0x3f8,-0x28(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14b23:	8b 45 d8             	mov    -0x28(%ebp),%eax
   14b26:	89 c2                	mov    %eax,%edx
   14b28:	ec                   	in     (%dx),%al
   14b29:	88 45 d7             	mov    %al,-0x29(%ebp)
	return data;
   14b2c:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
		case UA4_IIR_RX:
#if TRACING_SIO_ISR
	cio_puts( " RX" );
#endif
			// get the character
			ch = inb( UA4_RXD );
   14b30:	0f b6 c0             	movzbl %al,%eax
   14b33:	89 45 f4             	mov    %eax,-0xc(%ebp)
			if( ch == '\r' ) {    // map CR to LF
   14b36:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
   14b3a:	75 07                	jne    14b43 <sio_isr+0x90>
				ch = '\n';
   14b3c:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
			// If there is a waiting process, this must be
			// the first input character; give it to that
			// process and awaken the process.
			//

			if( !QEMPTY(QNAME) ) {
   14b43:	a1 04 20 02 00       	mov    0x22004,%eax
   14b48:	83 ec 0c             	sub    $0xc,%esp
   14b4b:	50                   	push   %eax
   14b4c:	e8 cd f2 ff ff       	call   13e1e <pcb_queue_empty>
   14b51:	83 c4 10             	add    $0x10,%esp
   14b54:	84 c0                	test   %al,%al
   14b56:	0f 85 d0 00 00 00    	jne    14c2c <sio_isr+0x179>
				PCBTYPE *pcb;

				QDEQUE( QNAME, pcb );
   14b5c:	a1 04 20 02 00       	mov    0x22004,%eax
   14b61:	83 ec 08             	sub    $0x8,%esp
   14b64:	8d 55 b0             	lea    -0x50(%ebp),%edx
   14b67:	52                   	push   %edx
   14b68:	50                   	push   %eax
   14b69:	e8 4e f5 ff ff       	call   140bc <pcb_queue_remove>
   14b6e:	83 c4 10             	add    $0x10,%esp
   14b71:	85 c0                	test   %eax,%eax
   14b73:	74 3b                	je     14bb0 <sio_isr+0xfd>
   14b75:	83 ec 04             	sub    $0x4,%esp
   14b78:	68 30 b6 01 00       	push   $0x1b630
   14b7d:	6a 00                	push   $0x0
   14b7f:	68 ac 00 00 00       	push   $0xac
   14b84:	68 68 b6 01 00       	push   $0x1b668
   14b89:	68 6c b7 01 00       	push   $0x1b76c
   14b8e:	68 6e b6 01 00       	push   $0x1b66e
   14b93:	68 00 00 02 00       	push   $0x20000
   14b98:	e8 4a db ff ff       	call   126e7 <sprint>
   14b9d:	83 c4 20             	add    $0x20,%esp
   14ba0:	83 ec 0c             	sub    $0xc,%esp
   14ba3:	68 00 00 02 00       	push   $0x20000
   14ba8:	e8 ba d8 ff ff       	call   12467 <kpanic>
   14bad:	83 c4 10             	add    $0x10,%esp
				// make sure we got a non-NULL result
				assert( pcb );
   14bb0:	8b 45 b0             	mov    -0x50(%ebp),%eax
   14bb3:	85 c0                	test   %eax,%eax
   14bb5:	75 3b                	jne    14bf2 <sio_isr+0x13f>
   14bb7:	83 ec 04             	sub    $0x4,%esp
   14bba:	68 84 b6 01 00       	push   $0x1b684
   14bbf:	6a 00                	push   $0x0
   14bc1:	68 ae 00 00 00       	push   $0xae
   14bc6:	68 68 b6 01 00       	push   $0x1b668
   14bcb:	68 6c b7 01 00       	push   $0x1b76c
   14bd0:	68 6e b6 01 00       	push   $0x1b66e
   14bd5:	68 00 00 02 00       	push   $0x20000
   14bda:	e8 08 db ff ff       	call   126e7 <sprint>
   14bdf:	83 c4 20             	add    $0x20,%esp
   14be2:	83 ec 0c             	sub    $0xc,%esp
   14be5:	68 00 00 02 00       	push   $0x20000
   14bea:	e8 78 d8 ff ff       	call   12467 <kpanic>
   14bef:	83 c4 10             	add    $0x10,%esp

				// return char via arg #2 and count in EAX
				char *buf = (char *) ARG(pcb,2);
   14bf2:	8b 45 b0             	mov    -0x50(%ebp),%eax
   14bf5:	8b 00                	mov    (%eax),%eax
   14bf7:	83 c0 48             	add    $0x48,%eax
   14bfa:	83 c0 08             	add    $0x8,%eax
   14bfd:	8b 00                	mov    (%eax),%eax
   14bff:	89 45 ec             	mov    %eax,-0x14(%ebp)
				*buf = ch & 0xff;
   14c02:	8b 45 f4             	mov    -0xc(%ebp),%eax
   14c05:	89 c2                	mov    %eax,%edx
   14c07:	8b 45 ec             	mov    -0x14(%ebp),%eax
   14c0a:	88 10                	mov    %dl,(%eax)
				RET(pcb) = 1;
   14c0c:	8b 45 b0             	mov    -0x50(%ebp),%eax
   14c0f:	8b 00                	mov    (%eax),%eax
   14c11:	c7 40 30 01 00 00 00 	movl   $0x1,0x30(%eax)
				SCHED( pcb );
   14c18:	8b 45 b0             	mov    -0x50(%ebp),%eax
   14c1b:	83 ec 0c             	sub    $0xc,%esp
   14c1e:	50                   	push   %eax
   14c1f:	e8 8b f7 ff ff       	call   143af <schedule>
   14c24:	83 c4 10             	add    $0x10,%esp
				}

#ifdef QNAME
			}
#endif /* QNAME */
			break;
   14c27:	e9 a5 01 00 00       	jmp    14dd1 <sio_isr+0x31e>
				if( incount < BUF_SIZE ) {
   14c2c:	a1 88 e9 01 00       	mov    0x1e988,%eax
   14c31:	3d ff 07 00 00       	cmp    $0x7ff,%eax
   14c36:	0f 87 95 01 00 00    	ja     14dd1 <sio_isr+0x31e>
					*inlast++ = ch;
   14c3c:	a1 80 e9 01 00       	mov    0x1e980,%eax
   14c41:	8d 50 01             	lea    0x1(%eax),%edx
   14c44:	89 15 80 e9 01 00    	mov    %edx,0x1e980
   14c4a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   14c4d:	88 10                	mov    %dl,(%eax)
					++incount;
   14c4f:	a1 88 e9 01 00       	mov    0x1e988,%eax
   14c54:	83 c0 01             	add    $0x1,%eax
   14c57:	a3 88 e9 01 00       	mov    %eax,0x1e988
			break;
   14c5c:	e9 70 01 00 00       	jmp    14dd1 <sio_isr+0x31e>
   14c61:	c7 45 d0 f8 03 00 00 	movl   $0x3f8,-0x30(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14c68:	8b 45 d0             	mov    -0x30(%ebp),%eax
   14c6b:	89 c2                	mov    %eax,%edx
   14c6d:	ec                   	in     (%dx),%al
   14c6e:	88 45 cf             	mov    %al,-0x31(%ebp)
	return data;
   14c71:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax

		case UA5_IIR_RX_FIFO:
			// shouldn't happen, but just in case....
			ch = inb( UA4_RXD );
   14c75:	0f b6 c0             	movzbl %al,%eax
   14c78:	89 45 f4             	mov    %eax,-0xc(%ebp)
			cio_printf( "** SIO FIFO timeout, RXD = %02x\n", ch );
   14c7b:	83 ec 08             	sub    $0x8,%esp
   14c7e:	ff 75 f4             	pushl  -0xc(%ebp)
   14c81:	68 88 b6 01 00       	push   $0x1b688
   14c86:	e8 9c c8 ff ff       	call   11527 <cio_printf>
   14c8b:	83 c4 10             	add    $0x10,%esp
			break;
   14c8e:	e9 3f 01 00 00       	jmp    14dd2 <sio_isr+0x31f>
		case UA4_IIR_TX:
#if TRACING_SIO_ISR
	cio_puts( " TX" );
#endif
			// if there is another character, send it
			if( sending && outcount > 0 ) {
   14c93:	a1 ac f1 01 00       	mov    0x1f1ac,%eax
   14c98:	85 c0                	test   %eax,%eax
   14c9a:	74 5d                	je     14cf9 <sio_isr+0x246>
   14c9c:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   14ca1:	85 c0                	test   %eax,%eax
   14ca3:	74 54                	je     14cf9 <sio_isr+0x246>
#if TRACING_SIO_ISR
	cio_printf( " ch %02x", *outnext );
#endif
				outb( UA4_TXD, *outnext );
   14ca5:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   14caa:	0f b6 00             	movzbl (%eax),%eax
   14cad:	0f b6 c0             	movzbl %al,%eax
   14cb0:	c7 45 c8 f8 03 00 00 	movl   $0x3f8,-0x38(%ebp)
   14cb7:	88 45 c7             	mov    %al,-0x39(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   14cba:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   14cbe:	8b 55 c8             	mov    -0x38(%ebp),%edx
   14cc1:	ee                   	out    %al,(%dx)
				++outnext;
   14cc2:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   14cc7:	83 c0 01             	add    $0x1,%eax
   14cca:	a3 a4 f1 01 00       	mov    %eax,0x1f1a4
				// wrap around if necessary
				if( outnext >= (outbuffer + BUF_SIZE) ) {
   14ccf:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   14cd4:	ba a0 f1 01 00       	mov    $0x1f1a0,%edx
   14cd9:	39 d0                	cmp    %edx,%eax
   14cdb:	72 0a                	jb     14ce7 <sio_isr+0x234>
					outnext = outbuffer;
   14cdd:	c7 05 a4 f1 01 00 a0 	movl   $0x1e9a0,0x1f1a4
   14ce4:	e9 01 00 
				}
				--outcount;
   14ce7:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   14cec:	83 e8 01             	sub    $0x1,%eax
   14cef:	a3 a8 f1 01 00       	mov    %eax,0x1f1a8
				outlast = outnext = outbuffer;
				sending = 0;
				// disable TX interrupts
				sio_disable( SIO_TX );
			}
			break;
   14cf4:	e9 d9 00 00 00       	jmp    14dd2 <sio_isr+0x31f>
				outcount = 0;
   14cf9:	c7 05 a8 f1 01 00 00 	movl   $0x0,0x1f1a8
   14d00:	00 00 00 
				outlast = outnext = outbuffer;
   14d03:	c7 05 a4 f1 01 00 a0 	movl   $0x1e9a0,0x1f1a4
   14d0a:	e9 01 00 
   14d0d:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   14d12:	a3 a0 f1 01 00       	mov    %eax,0x1f1a0
				sending = 0;
   14d17:	c7 05 ac f1 01 00 00 	movl   $0x0,0x1f1ac
   14d1e:	00 00 00 
				sio_disable( SIO_TX );
   14d21:	83 ec 0c             	sub    $0xc,%esp
   14d24:	6a 01                	push   $0x1
   14d26:	e8 99 02 00 00       	call   14fc4 <sio_disable>
   14d2b:	83 c4 10             	add    $0x10,%esp
			break;
   14d2e:	e9 9f 00 00 00       	jmp    14dd2 <sio_isr+0x31f>
   14d33:	c7 45 c0 20 00 00 00 	movl   $0x20,-0x40(%ebp)
   14d3a:	c6 45 bf 20          	movb   $0x20,-0x41(%ebp)
   14d3e:	0f b6 45 bf          	movzbl -0x41(%ebp),%eax
   14d42:	8b 55 c0             	mov    -0x40(%ebp),%edx
   14d45:	ee                   	out    %al,(%dx)
#if TRACING_SIO_ISR
	cio_puts( " EOI\n" );
#endif
			// nothing to do - tell the PIC we're done
			outb( PIC1_CMD, PIC_EOI );
			return;
   14d46:	e9 8c 00 00 00       	jmp    14dd7 <sio_isr+0x324>
   14d4b:	c7 45 b8 fe 03 00 00 	movl   $0x3fe,-0x48(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14d52:	8b 45 b8             	mov    -0x48(%ebp),%eax
   14d55:	89 c2                	mov    %eax,%edx
   14d57:	ec                   	in     (%dx),%al
   14d58:	88 45 b7             	mov    %al,-0x49(%ebp)
	return data;
   14d5b:	0f b6 45 b7          	movzbl -0x49(%ebp),%eax

		case UA4_IIR_MODEM_STATUS:
			// shouldn't happen, but just in case....
			cio_printf( "** SIO int, MSR = %02x\n", inb(UA4_MSR) );
   14d5f:	0f b6 c0             	movzbl %al,%eax
   14d62:	83 ec 08             	sub    $0x8,%esp
   14d65:	50                   	push   %eax
   14d66:	68 a9 b6 01 00       	push   $0x1b6a9
   14d6b:	e8 b7 c7 ff ff       	call   11527 <cio_printf>
   14d70:	83 c4 10             	add    $0x10,%esp
			break;
   14d73:	eb 5d                	jmp    14dd2 <sio_isr+0x31f>

		default:
			// uh-oh....
			sprint( b256, "sio isr: IIR %02x\n", ((uint32_t) iir) & 0xff );
   14d75:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14d78:	0f b6 c0             	movzbl %al,%eax
   14d7b:	83 ec 04             	sub    $0x4,%esp
   14d7e:	50                   	push   %eax
   14d7f:	68 c1 b6 01 00       	push   $0x1b6c1
   14d84:	68 00 02 02 00       	push   $0x20200
   14d89:	e8 59 d9 ff ff       	call   126e7 <sprint>
   14d8e:	83 c4 10             	add    $0x10,%esp
			PANIC( 0, b256 );
   14d91:	83 ec 04             	sub    $0x4,%esp
   14d94:	68 d4 b6 01 00       	push   $0x1b6d4
   14d99:	6a 00                	push   $0x0
   14d9b:	68 fe 00 00 00       	push   $0xfe
   14da0:	68 68 b6 01 00       	push   $0x1b668
   14da5:	68 6c b7 01 00       	push   $0x1b76c
   14daa:	68 6e b6 01 00       	push   $0x1b66e
   14daf:	68 00 00 02 00       	push   $0x20000
   14db4:	e8 2e d9 ff ff       	call   126e7 <sprint>
   14db9:	83 c4 20             	add    $0x20,%esp
   14dbc:	83 ec 0c             	sub    $0xc,%esp
   14dbf:	68 00 00 02 00       	push   $0x20000
   14dc4:	e8 9e d6 ff ff       	call   12467 <kpanic>
   14dc9:	83 c4 10             	add    $0x10,%esp
   14dcc:	e9 e8 fc ff ff       	jmp    14ab9 <sio_isr+0x6>
			break;
   14dd1:	90                   	nop
	for(;;) {
   14dd2:	e9 e2 fc ff ff       	jmp    14ab9 <sio_isr+0x6>
	
	}

	// should never reach this point!
	assert( false );
}
   14dd7:	c9                   	leave  
   14dd8:	c3                   	ret    

00014dd9 <sio_init>:
/**
** sio_init()
**
** Initialize the UART chip.
*/
void sio_init( void ) {
   14dd9:	55                   	push   %ebp
   14dda:	89 e5                	mov    %esp,%ebp
   14ddc:	83 ec 68             	sub    $0x68,%esp

#if TRACING_INIT
	cio_puts( " Sio" );
   14ddf:	83 ec 0c             	sub    $0xc,%esp
   14de2:	68 10 b7 01 00       	push   $0x1b710
   14de7:	e8 c1 c0 ff ff       	call   10ead <cio_puts>
   14dec:	83 c4 10             	add    $0x10,%esp

	/*
	** Initialize SIO variables.
	*/

	memclr( (void *) inbuffer, sizeof(inbuffer) );
   14def:	83 ec 08             	sub    $0x8,%esp
   14df2:	68 00 08 00 00       	push   $0x800
   14df7:	68 80 e1 01 00       	push   $0x1e180
   14dfc:	e8 63 d7 ff ff       	call   12564 <memclr>
   14e01:	83 c4 10             	add    $0x10,%esp
	inlast = innext = inbuffer;
   14e04:	c7 05 84 e9 01 00 80 	movl   $0x1e180,0x1e984
   14e0b:	e1 01 00 
   14e0e:	a1 84 e9 01 00       	mov    0x1e984,%eax
   14e13:	a3 80 e9 01 00       	mov    %eax,0x1e980
	incount = 0;
   14e18:	c7 05 88 e9 01 00 00 	movl   $0x0,0x1e988
   14e1f:	00 00 00 

	memclr( (void *) outbuffer, sizeof(outbuffer) );
   14e22:	83 ec 08             	sub    $0x8,%esp
   14e25:	68 00 08 00 00       	push   $0x800
   14e2a:	68 a0 e9 01 00       	push   $0x1e9a0
   14e2f:	e8 30 d7 ff ff       	call   12564 <memclr>
   14e34:	83 c4 10             	add    $0x10,%esp
	outlast = outnext = outbuffer;
   14e37:	c7 05 a4 f1 01 00 a0 	movl   $0x1e9a0,0x1f1a4
   14e3e:	e9 01 00 
   14e41:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   14e46:	a3 a0 f1 01 00       	mov    %eax,0x1f1a0
	outcount = 0;
   14e4b:	c7 05 a8 f1 01 00 00 	movl   $0x0,0x1f1a8
   14e52:	00 00 00 
	sending = 0;
   14e55:	c7 05 ac f1 01 00 00 	movl   $0x0,0x1f1ac
   14e5c:	00 00 00 
   14e5f:	c7 45 a4 fa 03 00 00 	movl   $0x3fa,-0x5c(%ebp)
   14e66:	c6 45 a3 20          	movb   $0x20,-0x5d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   14e6a:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
   14e6e:	8b 55 a4             	mov    -0x5c(%ebp),%edx
   14e71:	ee                   	out    %al,(%dx)
   14e72:	c7 45 ac fa 03 00 00 	movl   $0x3fa,-0x54(%ebp)
   14e79:	c6 45 ab 00          	movb   $0x0,-0x55(%ebp)
   14e7d:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
   14e81:	8b 55 ac             	mov    -0x54(%ebp),%edx
   14e84:	ee                   	out    %al,(%dx)
   14e85:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
   14e8c:	c6 45 b3 01          	movb   $0x1,-0x4d(%ebp)
   14e90:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
   14e94:	8b 55 b4             	mov    -0x4c(%ebp),%edx
   14e97:	ee                   	out    %al,(%dx)
   14e98:	c7 45 bc fa 03 00 00 	movl   $0x3fa,-0x44(%ebp)
   14e9f:	c6 45 bb 03          	movb   $0x3,-0x45(%ebp)
   14ea3:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
   14ea7:	8b 55 bc             	mov    -0x44(%ebp),%edx
   14eaa:	ee                   	out    %al,(%dx)
   14eab:	c7 45 c4 fa 03 00 00 	movl   $0x3fa,-0x3c(%ebp)
   14eb2:	c6 45 c3 07          	movb   $0x7,-0x3d(%ebp)
   14eb6:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
   14eba:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   14ebd:	ee                   	out    %al,(%dx)
   14ebe:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
   14ec5:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
   14ec9:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
   14ecd:	8b 55 cc             	mov    -0x34(%ebp),%edx
   14ed0:	ee                   	out    %al,(%dx)
	** note that we leave them disabled; sio_enable() must be
	** called to switch them back on
	*/

	outb( UA4_IER, 0 );
	ier = 0;
   14ed1:	c6 05 b0 f1 01 00 00 	movb   $0x0,0x1f1b0
   14ed8:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
   14edf:	c6 45 d3 80          	movb   $0x80,-0x2d(%ebp)
   14ee3:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
   14ee7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
   14eea:	ee                   	out    %al,(%dx)
   14eeb:	c7 45 dc f8 03 00 00 	movl   $0x3f8,-0x24(%ebp)
   14ef2:	c6 45 db 0c          	movb   $0xc,-0x25(%ebp)
   14ef6:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   14efa:	8b 55 dc             	mov    -0x24(%ebp),%edx
   14efd:	ee                   	out    %al,(%dx)
   14efe:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
   14f05:	c6 45 e3 00          	movb   $0x0,-0x1d(%ebp)
   14f09:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
   14f0d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   14f10:	ee                   	out    %al,(%dx)
   14f11:	c7 45 ec fb 03 00 00 	movl   $0x3fb,-0x14(%ebp)
   14f18:	c6 45 eb 03          	movb   $0x3,-0x15(%ebp)
   14f1c:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   14f20:	8b 55 ec             	mov    -0x14(%ebp),%edx
   14f23:	ee                   	out    %al,(%dx)
   14f24:	c7 45 f4 fc 03 00 00 	movl   $0x3fc,-0xc(%ebp)
   14f2b:	c6 45 f3 0b          	movb   $0xb,-0xd(%ebp)
   14f2f:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   14f33:	8b 55 f4             	mov    -0xc(%ebp),%edx
   14f36:	ee                   	out    %al,(%dx)

	/*
	** Install our ISR
	*/

	install_isr( VEC_COM1, sio_isr );
   14f37:	83 ec 08             	sub    $0x8,%esp
   14f3a:	68 b3 4a 01 00       	push   $0x14ab3
   14f3f:	6a 24                	push   $0x24
   14f41:	e8 20 08 00 00       	call   15766 <install_isr>
   14f46:	83 c4 10             	add    $0x10,%esp
}
   14f49:	90                   	nop
   14f4a:	c9                   	leave  
   14f4b:	c3                   	ret    

00014f4c <sio_enable>:
**
** @param which   Bit mask indicating which interrupt(s) to enable
**
** @return the prior IER setting
*/
uint8_t sio_enable( uint8_t which ) {
   14f4c:	55                   	push   %ebp
   14f4d:	89 e5                	mov    %esp,%ebp
   14f4f:	83 ec 14             	sub    $0x14,%esp
   14f52:	8b 45 08             	mov    0x8(%ebp),%eax
   14f55:	88 45 ec             	mov    %al,-0x14(%ebp)
	uint8_t old;

	// remember the current status

	old = ier;
   14f58:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14f5f:	88 45 ff             	mov    %al,-0x1(%ebp)

	// figure out what to enable

	if( which & SIO_TX ) {
   14f62:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   14f66:	83 e0 01             	and    $0x1,%eax
   14f69:	85 c0                	test   %eax,%eax
   14f6b:	74 0f                	je     14f7c <sio_enable+0x30>
		ier |= UA4_IER_TX_IE;
   14f6d:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14f74:	83 c8 02             	or     $0x2,%eax
   14f77:	a2 b0 f1 01 00       	mov    %al,0x1f1b0
	}

	if( which & SIO_RX ) {
   14f7c:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   14f80:	83 e0 02             	and    $0x2,%eax
   14f83:	85 c0                	test   %eax,%eax
   14f85:	74 0f                	je     14f96 <sio_enable+0x4a>
		ier |= UA4_IER_RX_IE;
   14f87:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14f8e:	83 c8 01             	or     $0x1,%eax
   14f91:	a2 b0 f1 01 00       	mov    %al,0x1f1b0
	}

	// if there was a change, make it

	if( old != ier ) {
   14f96:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14f9d:	38 45 ff             	cmp    %al,-0x1(%ebp)
   14fa0:	74 1c                	je     14fbe <sio_enable+0x72>
		outb( UA4_IER, ier );
   14fa2:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14fa9:	0f b6 c0             	movzbl %al,%eax
   14fac:	c7 45 f8 f9 03 00 00 	movl   $0x3f9,-0x8(%ebp)
   14fb3:	88 45 f7             	mov    %al,-0x9(%ebp)
   14fb6:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
   14fba:	8b 55 f8             	mov    -0x8(%ebp),%edx
   14fbd:	ee                   	out    %al,(%dx)
	}

	// return the prior settings

	return( old );
   14fbe:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
   14fc2:	c9                   	leave  
   14fc3:	c3                   	ret    

00014fc4 <sio_disable>:
**
** @param which   Bit mask indicating which interrupt(s) to disable
**
** @return the prior IER setting
*/
uint8_t sio_disable( uint8_t which ) {
   14fc4:	55                   	push   %ebp
   14fc5:	89 e5                	mov    %esp,%ebp
   14fc7:	83 ec 14             	sub    $0x14,%esp
   14fca:	8b 45 08             	mov    0x8(%ebp),%eax
   14fcd:	88 45 ec             	mov    %al,-0x14(%ebp)
	uint8_t old;

	// remember the current status

	old = ier;
   14fd0:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14fd7:	88 45 ff             	mov    %al,-0x1(%ebp)

	// figure out what to disable

	if( which & SIO_TX ) {
   14fda:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   14fde:	83 e0 01             	and    $0x1,%eax
   14fe1:	85 c0                	test   %eax,%eax
   14fe3:	74 0f                	je     14ff4 <sio_disable+0x30>
		ier &= ~UA4_IER_TX_IE;
   14fe5:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14fec:	83 e0 fd             	and    $0xfffffffd,%eax
   14fef:	a2 b0 f1 01 00       	mov    %al,0x1f1b0
	}

	if( which & SIO_RX ) {
   14ff4:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   14ff8:	83 e0 02             	and    $0x2,%eax
   14ffb:	85 c0                	test   %eax,%eax
   14ffd:	74 0f                	je     1500e <sio_disable+0x4a>
		ier &= ~UA4_IER_RX_IE;
   14fff:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   15006:	83 e0 fe             	and    $0xfffffffe,%eax
   15009:	a2 b0 f1 01 00       	mov    %al,0x1f1b0
	}

	// if there was a change, make it

	if( old != ier ) {
   1500e:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   15015:	38 45 ff             	cmp    %al,-0x1(%ebp)
   15018:	74 1c                	je     15036 <sio_disable+0x72>
		outb( UA4_IER, ier );
   1501a:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   15021:	0f b6 c0             	movzbl %al,%eax
   15024:	c7 45 f8 f9 03 00 00 	movl   $0x3f9,-0x8(%ebp)
   1502b:	88 45 f7             	mov    %al,-0x9(%ebp)
   1502e:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
   15032:	8b 55 f8             	mov    -0x8(%ebp),%edx
   15035:	ee                   	out    %al,(%dx)
	}

	// return the prior settings

	return( old );
   15036:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
   1503a:	c9                   	leave  
   1503b:	c3                   	ret    

0001503c <sio_flush>:
**
** Flush the SIO input and/or output.
**
** @param which  Bit mask indicating which queue(s) to flush.
*/
void sio_flush( uint8_t which ) {
   1503c:	55                   	push   %ebp
   1503d:	89 e5                	mov    %esp,%ebp
   1503f:	83 ec 24             	sub    $0x24,%esp
   15042:	8b 45 08             	mov    0x8(%ebp),%eax
   15045:	88 45 dc             	mov    %al,-0x24(%ebp)

	if( (which & SIO_RX) != 0 ) {
   15048:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
   1504c:	83 e0 02             	and    $0x2,%eax
   1504f:	85 c0                	test   %eax,%eax
   15051:	74 69                	je     150bc <sio_flush+0x80>
		// empty the queue
		incount = 0;
   15053:	c7 05 88 e9 01 00 00 	movl   $0x0,0x1e988
   1505a:	00 00 00 
		inlast = innext = inbuffer;
   1505d:	c7 05 84 e9 01 00 80 	movl   $0x1e180,0x1e984
   15064:	e1 01 00 
   15067:	a1 84 e9 01 00       	mov    0x1e984,%eax
   1506c:	a3 80 e9 01 00       	mov    %eax,0x1e980
   15071:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   15078:	8b 45 f8             	mov    -0x8(%ebp),%eax
   1507b:	89 c2                	mov    %eax,%edx
   1507d:	ec                   	in     (%dx),%al
   1507e:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
   15081:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax

		// discard any characters in the receiver FIFO
		uint8_t lsr = inb( UA4_LSR );
   15085:	88 45 ff             	mov    %al,-0x1(%ebp)
		while( (lsr & UA4_LSR_RXDA) != 0 ) {
   15088:	eb 27                	jmp    150b1 <sio_flush+0x75>
   1508a:	c7 45 e8 f8 03 00 00 	movl   $0x3f8,-0x18(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   15091:	8b 45 e8             	mov    -0x18(%ebp),%eax
   15094:	89 c2                	mov    %eax,%edx
   15096:	ec                   	in     (%dx),%al
   15097:	88 45 e7             	mov    %al,-0x19(%ebp)
   1509a:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
   150a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
   150a4:	89 c2                	mov    %eax,%edx
   150a6:	ec                   	in     (%dx),%al
   150a7:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
   150aa:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
			(void) inb( UA4_RXD );
			lsr = inb( UA4_LSR );
   150ae:	88 45 ff             	mov    %al,-0x1(%ebp)
		while( (lsr & UA4_LSR_RXDA) != 0 ) {
   150b1:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
   150b5:	83 e0 01             	and    $0x1,%eax
   150b8:	85 c0                	test   %eax,%eax
   150ba:	75 ce                	jne    1508a <sio_flush+0x4e>
		}
	}

	if( (which & SIO_TX) != 0 ) {
   150bc:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
   150c0:	83 e0 01             	and    $0x1,%eax
   150c3:	85 c0                	test   %eax,%eax
   150c5:	74 28                	je     150ef <sio_flush+0xb3>
		// empty the queue
		outcount = 0;
   150c7:	c7 05 a8 f1 01 00 00 	movl   $0x0,0x1f1a8
   150ce:	00 00 00 
		outlast = outnext = outbuffer;
   150d1:	c7 05 a4 f1 01 00 a0 	movl   $0x1e9a0,0x1f1a4
   150d8:	e9 01 00 
   150db:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   150e0:	a3 a0 f1 01 00       	mov    %eax,0x1f1a0

		// terminate any in-progress send operation
		sending = 0;
   150e5:	c7 05 ac f1 01 00 00 	movl   $0x0,0x1f1ac
   150ec:	00 00 00 
	}
}
   150ef:	90                   	nop
   150f0:	c9                   	leave  
   150f1:	c3                   	ret    

000150f2 <sio_inq_length>:
**
** usage:    int num = sio_inq_length()
**
** @return the count of characters still in the input queue
*/
int sio_inq_length( void ) {
   150f2:	55                   	push   %ebp
   150f3:	89 e5                	mov    %esp,%ebp
	return( incount );
   150f5:	a1 88 e9 01 00       	mov    0x1e988,%eax
}
   150fa:	5d                   	pop    %ebp
   150fb:	c3                   	ret    

000150fc <sio_readc>:
**
** usage:    int ch = sio_readc()
**
** @return the next character, or -1 if no character is available
*/
int sio_readc( void ) {
   150fc:	55                   	push   %ebp
   150fd:	89 e5                	mov    %esp,%ebp
   150ff:	83 ec 10             	sub    $0x10,%esp
	int ch;

	// assume there is no character available
	ch = -1;
   15102:	c7 45 fc ff ff ff ff 	movl   $0xffffffff,-0x4(%ebp)

	// 
	// If there is a character, return it
	//

	if( incount > 0 ) {
   15109:	a1 88 e9 01 00       	mov    0x1e988,%eax
   1510e:	85 c0                	test   %eax,%eax
   15110:	74 46                	je     15158 <sio_readc+0x5c>

		// take it out of the input buffer
		ch = ((int)(*innext++)) & 0xff;
   15112:	a1 84 e9 01 00       	mov    0x1e984,%eax
   15117:	8d 50 01             	lea    0x1(%eax),%edx
   1511a:	89 15 84 e9 01 00    	mov    %edx,0x1e984
   15120:	0f b6 00             	movzbl (%eax),%eax
   15123:	0f be c0             	movsbl %al,%eax
   15126:	25 ff 00 00 00       	and    $0xff,%eax
   1512b:	89 45 fc             	mov    %eax,-0x4(%ebp)
		--incount;
   1512e:	a1 88 e9 01 00       	mov    0x1e988,%eax
   15133:	83 e8 01             	sub    $0x1,%eax
   15136:	a3 88 e9 01 00       	mov    %eax,0x1e988

		// reset the buffer variables if this was the last one
		if( incount < 1 ) {
   1513b:	a1 88 e9 01 00       	mov    0x1e988,%eax
   15140:	85 c0                	test   %eax,%eax
   15142:	75 14                	jne    15158 <sio_readc+0x5c>
			inlast = innext = inbuffer;
   15144:	c7 05 84 e9 01 00 80 	movl   $0x1e180,0x1e984
   1514b:	e1 01 00 
   1514e:	a1 84 e9 01 00       	mov    0x1e984,%eax
   15153:	a3 80 e9 01 00       	mov    %eax,0x1e980
		}

	}

	return( ch );
   15158:	8b 45 fc             	mov    -0x4(%ebp),%eax

}
   1515b:	c9                   	leave  
   1515c:	c3                   	ret    

0001515d <sio_read>:
** @param length  Length of the buffer
**
** @return the number of bytes copied, or 0 if no characters were available
*/

int sio_read( char *buf, int length ) {
   1515d:	55                   	push   %ebp
   1515e:	89 e5                	mov    %esp,%ebp
   15160:	83 ec 10             	sub    $0x10,%esp
	char *ptr = buf;
   15163:	8b 45 08             	mov    0x8(%ebp),%eax
   15166:	89 45 fc             	mov    %eax,-0x4(%ebp)
	int copied = 0;
   15169:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// if there are no characters, just return 0

	if( incount < 1 ) {
   15170:	a1 88 e9 01 00       	mov    0x1e988,%eax
   15175:	85 c0                	test   %eax,%eax
   15177:	75 4c                	jne    151c5 <sio_read+0x68>
		return( 0 );
   15179:	b8 00 00 00 00       	mov    $0x0,%eax
   1517e:	eb 76                	jmp    151f6 <sio_read+0x99>
	// We have characters.  Copy as many of them into the user
	// buffer as will fit.
	//

	while( incount > 0 && copied < length ) {
		*ptr++ = *innext++ & 0xff;
   15180:	8b 15 84 e9 01 00    	mov    0x1e984,%edx
   15186:	8d 42 01             	lea    0x1(%edx),%eax
   15189:	a3 84 e9 01 00       	mov    %eax,0x1e984
   1518e:	8b 45 fc             	mov    -0x4(%ebp),%eax
   15191:	8d 48 01             	lea    0x1(%eax),%ecx
   15194:	89 4d fc             	mov    %ecx,-0x4(%ebp)
   15197:	0f b6 12             	movzbl (%edx),%edx
   1519a:	88 10                	mov    %dl,(%eax)
		if( innext > (inbuffer + BUF_SIZE) ) {
   1519c:	a1 84 e9 01 00       	mov    0x1e984,%eax
   151a1:	ba 80 e9 01 00       	mov    $0x1e980,%edx
   151a6:	39 d0                	cmp    %edx,%eax
   151a8:	76 0a                	jbe    151b4 <sio_read+0x57>
			innext = inbuffer;
   151aa:	c7 05 84 e9 01 00 80 	movl   $0x1e180,0x1e984
   151b1:	e1 01 00 
		}
		--incount;
   151b4:	a1 88 e9 01 00       	mov    0x1e988,%eax
   151b9:	83 e8 01             	sub    $0x1,%eax
   151bc:	a3 88 e9 01 00       	mov    %eax,0x1e988
		++copied;
   151c1:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
	while( incount > 0 && copied < length ) {
   151c5:	a1 88 e9 01 00       	mov    0x1e988,%eax
   151ca:	85 c0                	test   %eax,%eax
   151cc:	74 08                	je     151d6 <sio_read+0x79>
   151ce:	8b 45 f8             	mov    -0x8(%ebp),%eax
   151d1:	3b 45 0c             	cmp    0xc(%ebp),%eax
   151d4:	7c aa                	jl     15180 <sio_read+0x23>
	}

	// reset the input buffer if necessary

	if( incount < 1 ) {
   151d6:	a1 88 e9 01 00       	mov    0x1e988,%eax
   151db:	85 c0                	test   %eax,%eax
   151dd:	75 14                	jne    151f3 <sio_read+0x96>
		inlast = innext = inbuffer;
   151df:	c7 05 84 e9 01 00 80 	movl   $0x1e180,0x1e984
   151e6:	e1 01 00 
   151e9:	a1 84 e9 01 00       	mov    0x1e984,%eax
   151ee:	a3 80 e9 01 00       	mov    %eax,0x1e980
	}

	// return the copy count

	return( copied );
   151f3:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
   151f6:	c9                   	leave  
   151f7:	c3                   	ret    

000151f8 <sio_writec>:
**
** usage:    sio_writec( int ch )
**
** @param ch   Character to be written (in the low-order 8 bits)
*/
void sio_writec( int ch ){
   151f8:	55                   	push   %ebp
   151f9:	89 e5                	mov    %esp,%ebp
   151fb:	83 ec 18             	sub    $0x18,%esp

	//
	// Must do LF -> CRLF mapping
	//

	if( ch == '\n' ) {
   151fe:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
   15202:	75 0d                	jne    15211 <sio_writec+0x19>
		sio_writec( '\r' );
   15204:	83 ec 0c             	sub    $0xc,%esp
   15207:	6a 0d                	push   $0xd
   15209:	e8 ea ff ff ff       	call   151f8 <sio_writec>
   1520e:	83 c4 10             	add    $0x10,%esp

	//
	// If we're currently transmitting, just add this to the buffer
	//

	if( sending ) {
   15211:	a1 ac f1 01 00       	mov    0x1f1ac,%eax
   15216:	85 c0                	test   %eax,%eax
   15218:	74 22                	je     1523c <sio_writec+0x44>
		*outlast++ = ch;
   1521a:	a1 a0 f1 01 00       	mov    0x1f1a0,%eax
   1521f:	8d 50 01             	lea    0x1(%eax),%edx
   15222:	89 15 a0 f1 01 00    	mov    %edx,0x1f1a0
   15228:	8b 55 08             	mov    0x8(%ebp),%edx
   1522b:	88 10                	mov    %dl,(%eax)
		++outcount;
   1522d:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   15232:	83 c0 01             	add    $0x1,%eax
   15235:	a3 a8 f1 01 00       	mov    %eax,0x1f1a8
		return;
   1523a:	eb 2f                	jmp    1526b <sio_writec+0x73>

	//
	// Not sending - must prime the pump
	//

	sending = 1;
   1523c:	c7 05 ac f1 01 00 01 	movl   $0x1,0x1f1ac
   15243:	00 00 00 
	outb( UA4_TXD, ch );
   15246:	8b 45 08             	mov    0x8(%ebp),%eax
   15249:	0f b6 c0             	movzbl %al,%eax
   1524c:	c7 45 f4 f8 03 00 00 	movl   $0x3f8,-0xc(%ebp)
   15253:	88 45 f3             	mov    %al,-0xd(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   15256:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   1525a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1525d:	ee                   	out    %al,(%dx)

	// Also must enable transmitter interrupts

	sio_enable( SIO_TX );
   1525e:	83 ec 0c             	sub    $0xc,%esp
   15261:	6a 01                	push   $0x1
   15263:	e8 e4 fc ff ff       	call   14f4c <sio_enable>
   15268:	83 c4 10             	add    $0x10,%esp

}
   1526b:	c9                   	leave  
   1526c:	c3                   	ret    

0001526d <sio_write>:
** @param buffer   Buffer containing characters to write
** @param length   Number of characters to write
**
** @return the number of characters copied into the SIO output buffer
*/
int sio_write( const char *buffer, int length ) {
   1526d:	55                   	push   %ebp
   1526e:	89 e5                	mov    %esp,%ebp
   15270:	83 ec 18             	sub    $0x18,%esp
	int first = *buffer;
   15273:	8b 45 08             	mov    0x8(%ebp),%eax
   15276:	0f b6 00             	movzbl (%eax),%eax
   15279:	0f be c0             	movsbl %al,%eax
   1527c:	89 45 ec             	mov    %eax,-0x14(%ebp)
	const char *ptr = buffer;
   1527f:	8b 45 08             	mov    0x8(%ebp),%eax
   15282:	89 45 f4             	mov    %eax,-0xc(%ebp)
	int copied = 0;
   15285:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	// the characters to the output buffer; else, we want
	// to append all but the first character, and then use
	// sio_writec() to send the first one out.
	//

	if( !sending ) {
   1528c:	a1 ac f1 01 00       	mov    0x1f1ac,%eax
   15291:	85 c0                	test   %eax,%eax
   15293:	75 4f                	jne    152e4 <sio_write+0x77>
		ptr += 1;
   15295:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
		copied++;
   15299:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
	}

	while( copied < length && outcount < BUF_SIZE ) {
   1529d:	eb 45                	jmp    152e4 <sio_write+0x77>
		*outlast++ = *ptr++;
   1529f:	8b 55 f4             	mov    -0xc(%ebp),%edx
   152a2:	8d 42 01             	lea    0x1(%edx),%eax
   152a5:	89 45 f4             	mov    %eax,-0xc(%ebp)
   152a8:	a1 a0 f1 01 00       	mov    0x1f1a0,%eax
   152ad:	8d 48 01             	lea    0x1(%eax),%ecx
   152b0:	89 0d a0 f1 01 00    	mov    %ecx,0x1f1a0
   152b6:	0f b6 12             	movzbl (%edx),%edx
   152b9:	88 10                	mov    %dl,(%eax)
		// wrap around if necessary
		if( outlast >= (outbuffer + BUF_SIZE) ) {
   152bb:	a1 a0 f1 01 00       	mov    0x1f1a0,%eax
   152c0:	ba a0 f1 01 00       	mov    $0x1f1a0,%edx
   152c5:	39 d0                	cmp    %edx,%eax
   152c7:	72 0a                	jb     152d3 <sio_write+0x66>
			outlast = outbuffer;
   152c9:	c7 05 a0 f1 01 00 a0 	movl   $0x1e9a0,0x1f1a0
   152d0:	e9 01 00 
		}
		++outcount;
   152d3:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   152d8:	83 c0 01             	add    $0x1,%eax
   152db:	a3 a8 f1 01 00       	mov    %eax,0x1f1a8
		++copied;
   152e0:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
	while( copied < length && outcount < BUF_SIZE ) {
   152e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
   152e7:	3b 45 0c             	cmp    0xc(%ebp),%eax
   152ea:	7d 0c                	jge    152f8 <sio_write+0x8b>
   152ec:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   152f1:	3d ff 07 00 00       	cmp    $0x7ff,%eax
   152f6:	76 a7                	jbe    1529f <sio_write+0x32>
	// We use sio_writec() to send out the first character,
	// as it will correctly set all the other necessary
	// variables for us.
	//

	if( !sending ) {
   152f8:	a1 ac f1 01 00       	mov    0x1f1ac,%eax
   152fd:	85 c0                	test   %eax,%eax
   152ff:	75 0e                	jne    1530f <sio_write+0xa2>
		sio_writec( first );
   15301:	83 ec 0c             	sub    $0xc,%esp
   15304:	ff 75 ec             	pushl  -0x14(%ebp)
   15307:	e8 ec fe ff ff       	call   151f8 <sio_writec>
   1530c:	83 c4 10             	add    $0x10,%esp
	}

	// Return the transfer count


	return( copied );
   1530f:	8b 45 f0             	mov    -0x10(%ebp),%eax

}
   15312:	c9                   	leave  
   15313:	c3                   	ret    

00015314 <sio_puts>:
**
** @param buffer  The buffer containing a NUL-terminated string
**
** @return the count of bytes transferred
*/
int sio_puts( const char *buffer ) {
   15314:	55                   	push   %ebp
   15315:	89 e5                	mov    %esp,%ebp
   15317:	83 ec 18             	sub    $0x18,%esp
	int n;  // must be outside the loop so we can return it

	n = SLENGTH( buffer );
   1531a:	83 ec 0c             	sub    $0xc,%esp
   1531d:	ff 75 08             	pushl  0x8(%ebp)
   15320:	e8 3f d7 ff ff       	call   12a64 <strlen>
   15325:	83 c4 10             	add    $0x10,%esp
   15328:	89 45 f4             	mov    %eax,-0xc(%ebp)
	sio_write( buffer, n );
   1532b:	83 ec 08             	sub    $0x8,%esp
   1532e:	ff 75 f4             	pushl  -0xc(%ebp)
   15331:	ff 75 08             	pushl  0x8(%ebp)
   15334:	e8 34 ff ff ff       	call   1526d <sio_write>
   15339:	83 c4 10             	add    $0x10,%esp

	return( n );
   1533c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   1533f:	c9                   	leave  
   15340:	c3                   	ret    

00015341 <sio_dump>:
** @param full   Boolean indicating whether or not a "full" dump
**               is being requested (which includes the contents
**               of the queues)
*/

void sio_dump( bool_t full ) {
   15341:	55                   	push   %ebp
   15342:	89 e5                	mov    %esp,%ebp
   15344:	57                   	push   %edi
   15345:	56                   	push   %esi
   15346:	53                   	push   %ebx
   15347:	83 ec 2c             	sub    $0x2c,%esp
   1534a:	8b 45 08             	mov    0x8(%ebp),%eax
   1534d:	88 45 d4             	mov    %al,-0x2c(%ebp)
	int n;
	char *ptr;

	// dump basic info into the status region

	cio_printf_at( 48, 0,
   15350:	8b 0d a8 f1 01 00    	mov    0x1f1a8,%ecx
   15356:	8b 15 88 e9 01 00    	mov    0x1e988,%edx
		"SIO: IER %02x (%c%c%c) in %d ot %d",
			((uint32_t)ier) & 0xff, sending ? '*' : '.',
			(ier & UA4_IER_TX_IE) ? 'T' : 't',
			(ier & UA4_IER_RX_IE) ? 'R' : 'r',
   1535c:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   15363:	0f b6 c0             	movzbl %al,%eax
   15366:	83 e0 01             	and    $0x1,%eax
	cio_printf_at( 48, 0,
   15369:	85 c0                	test   %eax,%eax
   1536b:	74 07                	je     15374 <sio_dump+0x33>
   1536d:	bf 52 00 00 00       	mov    $0x52,%edi
   15372:	eb 05                	jmp    15379 <sio_dump+0x38>
   15374:	bf 72 00 00 00       	mov    $0x72,%edi
			(ier & UA4_IER_TX_IE) ? 'T' : 't',
   15379:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   15380:	0f b6 c0             	movzbl %al,%eax
   15383:	83 e0 02             	and    $0x2,%eax
	cio_printf_at( 48, 0,
   15386:	85 c0                	test   %eax,%eax
   15388:	74 07                	je     15391 <sio_dump+0x50>
   1538a:	be 54 00 00 00       	mov    $0x54,%esi
   1538f:	eb 05                	jmp    15396 <sio_dump+0x55>
   15391:	be 74 00 00 00       	mov    $0x74,%esi
			((uint32_t)ier) & 0xff, sending ? '*' : '.',
   15396:	a1 ac f1 01 00       	mov    0x1f1ac,%eax
	cio_printf_at( 48, 0,
   1539b:	85 c0                	test   %eax,%eax
   1539d:	74 07                	je     153a6 <sio_dump+0x65>
   1539f:	bb 2a 00 00 00       	mov    $0x2a,%ebx
   153a4:	eb 05                	jmp    153ab <sio_dump+0x6a>
   153a6:	bb 2e 00 00 00       	mov    $0x2e,%ebx
   153ab:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   153b2:	0f b6 c0             	movzbl %al,%eax
   153b5:	83 ec 0c             	sub    $0xc,%esp
   153b8:	51                   	push   %ecx
   153b9:	52                   	push   %edx
   153ba:	57                   	push   %edi
   153bb:	56                   	push   %esi
   153bc:	53                   	push   %ebx
   153bd:	50                   	push   %eax
   153be:	68 18 b7 01 00       	push   $0x1b718
   153c3:	6a 00                	push   $0x0
   153c5:	6a 30                	push   $0x30
   153c7:	e8 3b c1 ff ff       	call   11507 <cio_printf_at>
   153cc:	83 c4 30             	add    $0x30,%esp
			incount, outcount );

	// if we're not doing a full dump, stop now

	if( !full ) {
   153cf:	80 7d d4 00          	cmpb   $0x0,-0x2c(%ebp)
   153d3:	0f 84 dc 00 00 00    	je     154b5 <sio_dump+0x174>
	}

	// also want the queue contents, but we'll
	// dump them into the scrolling region

	if( incount ) {
   153d9:	a1 88 e9 01 00       	mov    0x1e988,%eax
   153de:	85 c0                	test   %eax,%eax
   153e0:	74 5c                	je     1543e <sio_dump+0xfd>
		cio_puts( "SIO input queue: \"" );
   153e2:	83 ec 0c             	sub    $0xc,%esp
   153e5:	68 3b b7 01 00       	push   $0x1b73b
   153ea:	e8 be ba ff ff       	call   10ead <cio_puts>
   153ef:	83 c4 10             	add    $0x10,%esp
		ptr = innext; 
   153f2:	a1 84 e9 01 00       	mov    0x1e984,%eax
   153f7:	89 45 e0             	mov    %eax,-0x20(%ebp)
		for( n = 0; n < incount; ++n ) {
   153fa:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   15401:	eb 1f                	jmp    15422 <sio_dump+0xe1>
			put_char_or_code( *ptr++ );
   15403:	8b 45 e0             	mov    -0x20(%ebp),%eax
   15406:	8d 50 01             	lea    0x1(%eax),%edx
   15409:	89 55 e0             	mov    %edx,-0x20(%ebp)
   1540c:	0f b6 00             	movzbl (%eax),%eax
   1540f:	0f be c0             	movsbl %al,%eax
   15412:	83 ec 0c             	sub    $0xc,%esp
   15415:	50                   	push   %eax
   15416:	e8 55 cf ff ff       	call   12370 <put_char_or_code>
   1541b:	83 c4 10             	add    $0x10,%esp
		for( n = 0; n < incount; ++n ) {
   1541e:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   15422:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   15425:	a1 88 e9 01 00       	mov    0x1e988,%eax
   1542a:	39 c2                	cmp    %eax,%edx
   1542c:	72 d5                	jb     15403 <sio_dump+0xc2>
		}
		cio_puts( "\"\n" );
   1542e:	83 ec 0c             	sub    $0xc,%esp
   15431:	68 4e b7 01 00       	push   $0x1b74e
   15436:	e8 72 ba ff ff       	call   10ead <cio_puts>
   1543b:	83 c4 10             	add    $0x10,%esp
	}

	if( outcount ) {
   1543e:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   15443:	85 c0                	test   %eax,%eax
   15445:	74 6f                	je     154b6 <sio_dump+0x175>
		cio_puts( "SIO output queue: \"" );
   15447:	83 ec 0c             	sub    $0xc,%esp
   1544a:	68 51 b7 01 00       	push   $0x1b751
   1544f:	e8 59 ba ff ff       	call   10ead <cio_puts>
   15454:	83 c4 10             	add    $0x10,%esp
		cio_puts( " ot: \"" );
   15457:	83 ec 0c             	sub    $0xc,%esp
   1545a:	68 65 b7 01 00       	push   $0x1b765
   1545f:	e8 49 ba ff ff       	call   10ead <cio_puts>
   15464:	83 c4 10             	add    $0x10,%esp
		ptr = outnext; 
   15467:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   1546c:	89 45 e0             	mov    %eax,-0x20(%ebp)
		for( n = 0; n < outcount; ++n )  {
   1546f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   15476:	eb 1f                	jmp    15497 <sio_dump+0x156>
			put_char_or_code( *ptr++ );
   15478:	8b 45 e0             	mov    -0x20(%ebp),%eax
   1547b:	8d 50 01             	lea    0x1(%eax),%edx
   1547e:	89 55 e0             	mov    %edx,-0x20(%ebp)
   15481:	0f b6 00             	movzbl (%eax),%eax
   15484:	0f be c0             	movsbl %al,%eax
   15487:	83 ec 0c             	sub    $0xc,%esp
   1548a:	50                   	push   %eax
   1548b:	e8 e0 ce ff ff       	call   12370 <put_char_or_code>
   15490:	83 c4 10             	add    $0x10,%esp
		for( n = 0; n < outcount; ++n )  {
   15493:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   15497:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   1549a:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   1549f:	39 c2                	cmp    %eax,%edx
   154a1:	72 d5                	jb     15478 <sio_dump+0x137>
		}
		cio_puts( "\"\n" );
   154a3:	83 ec 0c             	sub    $0xc,%esp
   154a6:	68 4e b7 01 00       	push   $0x1b74e
   154ab:	e8 fd b9 ff ff       	call   10ead <cio_puts>
   154b0:	83 c4 10             	add    $0x10,%esp
   154b3:	eb 01                	jmp    154b6 <sio_dump+0x175>
		return;
   154b5:	90                   	nop
	}
}
   154b6:	8d 65 f4             	lea    -0xc(%ebp),%esp
   154b9:	5b                   	pop    %ebx
   154ba:	5e                   	pop    %esi
   154bb:	5f                   	pop    %edi
   154bc:	5d                   	pop    %ebp
   154bd:	c3                   	ret    

000154be <unexpected_handler>:
** @param vector   vector number for the interrupt that occurred
** @param code     error code, or a dummy value
**
** Does not return.
*/
static void unexpected_handler( int vector, int code ) {
   154be:	55                   	push   %ebp
   154bf:	89 e5                	mov    %esp,%ebp
   154c1:	83 ec 08             	sub    $0x8,%esp
#ifdef RPT_INT_UNEXP
	cio_printf( "\n** UNEXPECTED vector %d code %d\n", vector, code );
   154c4:	83 ec 04             	sub    $0x4,%esp
   154c7:	ff 75 0c             	pushl  0xc(%ebp)
   154ca:	ff 75 08             	pushl  0x8(%ebp)
   154cd:	68 74 b7 01 00       	push   $0x1b774
   154d2:	e8 50 c0 ff ff       	call   11527 <cio_printf>
   154d7:	83 c4 10             	add    $0x10,%esp
#endif
	panic( "Unexpected interrupt" );
   154da:	83 ec 0c             	sub    $0xc,%esp
   154dd:	68 96 b7 01 00       	push   $0x1b796
   154e2:	e8 50 02 00 00       	call   15737 <panic>
   154e7:	83 c4 10             	add    $0x10,%esp
}
   154ea:	90                   	nop
   154eb:	c9                   	leave  
   154ec:	c3                   	ret    

000154ed <default_handler>:
** handling (yet).  We just reset the PIC and return.
**
** @param vector   vector number for the interrupt that occurred
** @param code     error code, or a dummy value
*/
static void default_handler( int vector, int code ) {
   154ed:	55                   	push   %ebp
   154ee:	89 e5                	mov    %esp,%ebp
   154f0:	83 ec 18             	sub    $0x18,%esp
#ifdef RPT_INT_UNEXP
	cio_printf( "\n** vector %d code %d\n", vector, code );
   154f3:	83 ec 04             	sub    $0x4,%esp
   154f6:	ff 75 0c             	pushl  0xc(%ebp)
   154f9:	ff 75 08             	pushl  0x8(%ebp)
   154fc:	68 ab b7 01 00       	push   $0x1b7ab
   15501:	e8 21 c0 ff ff       	call   11527 <cio_printf>
   15506:	83 c4 10             	add    $0x10,%esp
#endif
	if( vector >= 0x20 && vector < 0x30 ) {
   15509:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
   1550d:	7e 34                	jle    15543 <default_handler+0x56>
   1550f:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
   15513:	7f 2e                	jg     15543 <default_handler+0x56>
		if( vector > 0x27 ) {
   15515:	83 7d 08 27          	cmpl   $0x27,0x8(%ebp)
   15519:	7e 13                	jle    1552e <default_handler+0x41>
   1551b:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
   15522:	c6 45 f3 20          	movb   $0x20,-0xd(%ebp)
   15526:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   1552a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1552d:	ee                   	out    %al,(%dx)
   1552e:	c7 45 ec 20 00 00 00 	movl   $0x20,-0x14(%ebp)
   15535:	c6 45 eb 20          	movb   $0x20,-0x15(%ebp)
   15539:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   1553d:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15540:	ee                   	out    %al,(%dx)
			// must also ACK the secondary PIC
			outb( PIC2_CMD, PIC_EOI );
		}
		outb( PIC1_CMD, PIC_EOI );
   15541:	eb 10                	jmp    15553 <default_handler+0x66>
		/*
		** All the "expected" interrupts will be handled by the
		** code above.  If we get down here, the isr table may
		** have been corrupted.  Print a message and don't return.
		*/
		panic( "Unexpected \"expected\" interrupt!" );
   15543:	83 ec 0c             	sub    $0xc,%esp
   15546:	68 c4 b7 01 00       	push   $0x1b7c4
   1554b:	e8 e7 01 00 00       	call   15737 <panic>
   15550:	83 c4 10             	add    $0x10,%esp
	}
}
   15553:	90                   	nop
   15554:	c9                   	leave  
   15555:	c3                   	ret    

00015556 <mystery_handler>:
** source.
**
** @param vector   vector number for the interrupt that occurred
** @param code     error code, or a dummy value
*/
static void mystery_handler( int vector, int code ) {
   15556:	55                   	push   %ebp
   15557:	89 e5                	mov    %esp,%ebp
   15559:	83 ec 18             	sub    $0x18,%esp
#if defined(RPT_INT_MYSTERY) || defined(RPT_INT_UNEXP)
	cio_printf( "\nMystery interrupt!\nVector=0x%02x, code=%d\n",
   1555c:	83 ec 04             	sub    $0x4,%esp
   1555f:	ff 75 0c             	pushl  0xc(%ebp)
   15562:	ff 75 08             	pushl  0x8(%ebp)
   15565:	68 e8 b7 01 00       	push   $0x1b7e8
   1556a:	e8 b8 bf ff ff       	call   11527 <cio_printf>
   1556f:	83 c4 10             	add    $0x10,%esp
   15572:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
   15579:	c6 45 f3 20          	movb   $0x20,-0xd(%ebp)
   1557d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   15581:	8b 55 f4             	mov    -0xc(%ebp),%edx
   15584:	ee                   	out    %al,(%dx)
		  vector, code );
#endif
	outb( PIC1_CMD, PIC_EOI );
}
   15585:	90                   	nop
   15586:	c9                   	leave  
   15587:	c3                   	ret    

00015588 <init_pic>:
/**
** init_pic
**
** Initialize the 8259 Programmable Interrupt Controller.
*/
static void init_pic( void ) {
   15588:	55                   	push   %ebp
   15589:	89 e5                	mov    %esp,%ebp
   1558b:	83 ec 50             	sub    $0x50,%esp
   1558e:	c7 45 b4 20 00 00 00 	movl   $0x20,-0x4c(%ebp)
   15595:	c6 45 b3 11          	movb   $0x11,-0x4d(%ebp)
   15599:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
   1559d:	8b 55 b4             	mov    -0x4c(%ebp),%edx
   155a0:	ee                   	out    %al,(%dx)
   155a1:	c7 45 bc a0 00 00 00 	movl   $0xa0,-0x44(%ebp)
   155a8:	c6 45 bb 11          	movb   $0x11,-0x45(%ebp)
   155ac:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
   155b0:	8b 55 bc             	mov    -0x44(%ebp),%edx
   155b3:	ee                   	out    %al,(%dx)
   155b4:	c7 45 c4 21 00 00 00 	movl   $0x21,-0x3c(%ebp)
   155bb:	c6 45 c3 20          	movb   $0x20,-0x3d(%ebp)
   155bf:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
   155c3:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   155c6:	ee                   	out    %al,(%dx)
   155c7:	c7 45 cc a1 00 00 00 	movl   $0xa1,-0x34(%ebp)
   155ce:	c6 45 cb 28          	movb   $0x28,-0x35(%ebp)
   155d2:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
   155d6:	8b 55 cc             	mov    -0x34(%ebp),%edx
   155d9:	ee                   	out    %al,(%dx)
   155da:	c7 45 d4 21 00 00 00 	movl   $0x21,-0x2c(%ebp)
   155e1:	c6 45 d3 04          	movb   $0x4,-0x2d(%ebp)
   155e5:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
   155e9:	8b 55 d4             	mov    -0x2c(%ebp),%edx
   155ec:	ee                   	out    %al,(%dx)
   155ed:	c7 45 dc a1 00 00 00 	movl   $0xa1,-0x24(%ebp)
   155f4:	c6 45 db 02          	movb   $0x2,-0x25(%ebp)
   155f8:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   155fc:	8b 55 dc             	mov    -0x24(%ebp),%edx
   155ff:	ee                   	out    %al,(%dx)
   15600:	c7 45 e4 21 00 00 00 	movl   $0x21,-0x1c(%ebp)
   15607:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
   1560b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
   1560f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   15612:	ee                   	out    %al,(%dx)
   15613:	c7 45 ec a1 00 00 00 	movl   $0xa1,-0x14(%ebp)
   1561a:	c6 45 eb 01          	movb   $0x1,-0x15(%ebp)
   1561e:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   15622:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15625:	ee                   	out    %al,(%dx)
   15626:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
   1562d:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)
   15631:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   15635:	8b 55 f4             	mov    -0xc(%ebp),%edx
   15638:	ee                   	out    %al,(%dx)
   15639:	c7 45 fc a1 00 00 00 	movl   $0xa1,-0x4(%ebp)
   15640:	c6 45 fb 00          	movb   $0x0,-0x5(%ebp)
   15644:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
   15648:	8b 55 fc             	mov    -0x4(%ebp),%edx
   1564b:	ee                   	out    %al,(%dx)
	/*
	** OCW1: allow interrupts on all lines
	*/
	outb( PIC1_DATA, PIC_MASK_NONE );
	outb( PIC2_DATA, PIC_MASK_NONE );
}
   1564c:	90                   	nop
   1564d:	c9                   	leave  
   1564e:	c3                   	ret    

0001564f <set_idt_entry>:
** @param handler  ISR address to be put into the IDT entry
**
** Note: generally, the handler invoked from the IDT will be a "stub"
** that calls the second-level C handler via the isr_table array.
*/
static void set_idt_entry( int entry, void ( *handler )( void ) ) {
   1564f:	55                   	push   %ebp
   15650:	89 e5                	mov    %esp,%ebp
   15652:	83 ec 10             	sub    $0x10,%esp
	IDT_Gate *g = (IDT_Gate *)IDT_ADDR + entry;
   15655:	8b 45 08             	mov    0x8(%ebp),%eax
   15658:	c1 e0 03             	shl    $0x3,%eax
   1565b:	05 00 25 00 00       	add    $0x2500,%eax
   15660:	89 45 fc             	mov    %eax,-0x4(%ebp)

	g->offset_15_0 = (int)handler & 0xffff;
   15663:	8b 45 0c             	mov    0xc(%ebp),%eax
   15666:	89 c2                	mov    %eax,%edx
   15668:	8b 45 fc             	mov    -0x4(%ebp),%eax
   1566b:	66 89 10             	mov    %dx,(%eax)
	g->segment_selector = 0x0010;
   1566e:	8b 45 fc             	mov    -0x4(%ebp),%eax
   15671:	66 c7 40 02 10 00    	movw   $0x10,0x2(%eax)
	g->flags = IDT_PRESENT | IDT_DPL_0 | IDT_INT32_GATE;
   15677:	8b 45 fc             	mov    -0x4(%ebp),%eax
   1567a:	66 c7 40 04 00 8e    	movw   $0x8e00,0x4(%eax)
	g->offset_31_16 = (int)handler >> 16 & 0xffff;
   15680:	8b 45 0c             	mov    0xc(%ebp),%eax
   15683:	c1 e8 10             	shr    $0x10,%eax
   15686:	89 c2                	mov    %eax,%edx
   15688:	8b 45 fc             	mov    -0x4(%ebp),%eax
   1568b:	66 89 50 06          	mov    %dx,0x6(%eax)
}
   1568f:	90                   	nop
   15690:	c9                   	leave  
   15691:	c3                   	ret    

00015692 <init_idt>:
** the entries in the IDT point to the isr stub for that entry, and
** installs a default handler in the handler table.  Temporary handlers
** are then installed for those interrupts we may get before a real
** handler is set up.
*/
static void init_idt( void ) {
   15692:	55                   	push   %ebp
   15693:	89 e5                	mov    %esp,%ebp
   15695:	83 ec 18             	sub    $0x18,%esp

	/*
	** Make each IDT entry point to the stub for that vector.  Also
	** make each entry in the ISR table point to the default handler.
	*/
	for ( i=0; i < N_EXCEPTIONS; i++ ) {
   15698:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   1569f:	eb 2d                	jmp    156ce <init_idt+0x3c>
		set_idt_entry( i, isr_stub_table[ i ] );
   156a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
   156a4:	8b 04 85 16 a5 01 00 	mov    0x1a516(,%eax,4),%eax
   156ab:	50                   	push   %eax
   156ac:	ff 75 f4             	pushl  -0xc(%ebp)
   156af:	e8 9b ff ff ff       	call   1564f <set_idt_entry>
   156b4:	83 c4 08             	add    $0x8,%esp
		install_isr( i, unexpected_handler );
   156b7:	83 ec 08             	sub    $0x8,%esp
   156ba:	68 be 54 01 00       	push   $0x154be
   156bf:	ff 75 f4             	pushl  -0xc(%ebp)
   156c2:	e8 9f 00 00 00       	call   15766 <install_isr>
   156c7:	83 c4 10             	add    $0x10,%esp
	for ( i=0; i < N_EXCEPTIONS; i++ ) {
   156ca:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   156ce:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
   156d5:	7e ca                	jle    156a1 <init_idt+0xf>
	** Install the handlers for interrupts that have (or will have) a
	** specific handler. Comments indicate which module init function
	** will eventually install the "real" handler.
	*/

	install_isr( VEC_KBD, default_handler );         // cio_init()
   156d7:	83 ec 08             	sub    $0x8,%esp
   156da:	68 ed 54 01 00       	push   $0x154ed
   156df:	6a 21                	push   $0x21
   156e1:	e8 80 00 00 00       	call   15766 <install_isr>
   156e6:	83 c4 10             	add    $0x10,%esp
	install_isr( VEC_COM1, default_handler );        // sio_init()
   156e9:	83 ec 08             	sub    $0x8,%esp
   156ec:	68 ed 54 01 00       	push   $0x154ed
   156f1:	6a 24                	push   $0x24
   156f3:	e8 6e 00 00 00       	call   15766 <install_isr>
   156f8:	83 c4 10             	add    $0x10,%esp
	install_isr( VEC_TIMER, default_handler );       // clk_init()
   156fb:	83 ec 08             	sub    $0x8,%esp
   156fe:	68 ed 54 01 00       	push   $0x154ed
   15703:	6a 20                	push   $0x20
   15705:	e8 5c 00 00 00       	call   15766 <install_isr>
   1570a:	83 c4 10             	add    $0x10,%esp
	install_isr( VEC_SYSCALL, default_handler );     // sys_init()
   1570d:	83 ec 08             	sub    $0x8,%esp
   15710:	68 ed 54 01 00       	push   $0x154ed
   15715:	68 80 00 00 00       	push   $0x80
   1571a:	e8 47 00 00 00       	call   15766 <install_isr>
   1571f:	83 c4 10             	add    $0x10,%esp
	// install_isr( VEC_PAGE_FAULT, default_handler );  // vm_init()

	install_isr( VEC_MYSTERY, mystery_handler );
   15722:	83 ec 08             	sub    $0x8,%esp
   15725:	68 56 55 01 00       	push   $0x15556
   1572a:	6a 27                	push   $0x27
   1572c:	e8 35 00 00 00       	call   15766 <install_isr>
   15731:	83 c4 10             	add    $0x10,%esp
}
   15734:	90                   	nop
   15735:	c9                   	leave  
   15736:	c3                   	ret    

00015737 <panic>:
/*
** panic
**
** Called when we find an unrecoverable error.
*/
void panic( char *reason ) {
   15737:	55                   	push   %ebp
   15738:	89 e5                	mov    %esp,%ebp
   1573a:	83 ec 08             	sub    $0x8,%esp
	__asm__( "cli" );
   1573d:	fa                   	cli    
	cio_printf( "\nPANIC: %s\nHalting...", reason );
   1573e:	83 ec 08             	sub    $0x8,%esp
   15741:	ff 75 08             	pushl  0x8(%ebp)
   15744:	68 14 b8 01 00       	push   $0x1b814
   15749:	e8 d9 bd ff ff       	call   11527 <cio_printf>
   1574e:	83 c4 10             	add    $0x10,%esp
	for(;;) {
   15751:	eb fe                	jmp    15751 <panic+0x1a>

00015753 <init_interrupts>:
/*
** init_interrupts
**
** (Re)initilizes the interrupt system.
*/
void init_interrupts( void ) {
   15753:	55                   	push   %ebp
   15754:	89 e5                	mov    %esp,%ebp
   15756:	83 ec 08             	sub    $0x8,%esp
	init_idt();
   15759:	e8 34 ff ff ff       	call   15692 <init_idt>
	init_pic();
   1575e:	e8 25 fe ff ff       	call   15588 <init_pic>
}
   15763:	90                   	nop
   15764:	c9                   	leave  
   15765:	c3                   	ret    

00015766 <install_isr>:
** install_isr
**
** Installs a second-level handler for a specific interrupt.
*/
void (*install_isr( int vector,
		void (*handler)(int,int) ) ) ( int, int ) {
   15766:	55                   	push   %ebp
   15767:	89 e5                	mov    %esp,%ebp
   15769:	83 ec 10             	sub    $0x10,%esp

	void ( *old_handler )( int vector, int code );

	old_handler = isr_table[ vector ];
   1576c:	8b 45 08             	mov    0x8(%ebp),%eax
   1576f:	8b 04 85 e0 24 02 00 	mov    0x224e0(,%eax,4),%eax
   15776:	89 45 fc             	mov    %eax,-0x4(%ebp)
	isr_table[ vector ] = handler;
   15779:	8b 45 08             	mov    0x8(%ebp),%eax
   1577c:	8b 55 0c             	mov    0xc(%ebp),%edx
   1577f:	89 14 85 e0 24 02 00 	mov    %edx,0x224e0(,%eax,4)
	return old_handler;
   15786:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   15789:	c9                   	leave  
   1578a:	c3                   	ret    

0001578b <delay>:
** On the current machines (Intel Core i5-7500), delay(100) is about
** 2.5 seconds, so each "unit" is roughly 0.025 seconds.
**
** Ultimately, just remember that DELAY VALUES ARE APPROXIMATE AT BEST.
*/
void delay( int length ) {
   1578b:	55                   	push   %ebp
   1578c:	89 e5                	mov    %esp,%ebp
   1578e:	83 ec 10             	sub    $0x10,%esp

	while( --length >= 0 ) {
   15791:	eb 16                	jmp    157a9 <delay+0x1e>
		for( int i = 0; i < 10000000; ++i )
   15793:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   1579a:	eb 04                	jmp    157a0 <delay+0x15>
   1579c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   157a0:	81 7d fc 7f 96 98 00 	cmpl   $0x98967f,-0x4(%ebp)
   157a7:	7e f3                	jle    1579c <delay+0x11>
	while( --length >= 0 ) {
   157a9:	83 6d 08 01          	subl   $0x1,0x8(%ebp)
   157ad:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   157b1:	79 e0                	jns    15793 <delay+0x8>
			;
	}
}
   157b3:	90                   	nop
   157b4:	c9                   	leave  
   157b5:	c3                   	ret    

000157b6 <sys_exit>:
** Implements:
**		void exit( int32_t status );
**
** Does not return
*/
SYSIMPL(exit) {
   157b6:	55                   	push   %ebp
   157b7:	89 e5                	mov    %esp,%ebp
   157b9:	83 ec 08             	sub    $0x8,%esp

	// sanity check
	assert( pcb != NULL );
   157bc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   157c0:	75 38                	jne    157fa <sys_exit+0x44>
   157c2:	83 ec 04             	sub    $0x4,%esp
   157c5:	68 40 b8 01 00       	push   $0x1b840
   157ca:	6a 00                	push   $0x0
   157cc:	6a 65                	push   $0x65
   157ce:	68 49 b8 01 00       	push   $0x1b849
   157d3:	68 fc b9 01 00       	push   $0x1b9fc
   157d8:	68 54 b8 01 00       	push   $0x1b854
   157dd:	68 00 00 02 00       	push   $0x20000
   157e2:	e8 00 cf ff ff       	call   126e7 <sprint>
   157e7:	83 c4 20             	add    $0x20,%esp
   157ea:	83 ec 0c             	sub    $0xc,%esp
   157ed:	68 00 00 02 00       	push   $0x20000
   157f2:	e8 70 cc ff ff       	call   12467 <kpanic>
   157f7:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   157fa:	a1 e0 28 02 00       	mov    0x228e0,%eax
   157ff:	85 c0                	test   %eax,%eax
   15801:	74 1c                	je     1581f <sys_exit+0x69>
   15803:	8b 45 08             	mov    0x8(%ebp),%eax
   15806:	8b 40 18             	mov    0x18(%eax),%eax
   15809:	83 ec 04             	sub    $0x4,%esp
   1580c:	50                   	push   %eax
   1580d:	68 fc b9 01 00       	push   $0x1b9fc
   15812:	68 6a b8 01 00       	push   $0x1b86a
   15817:	e8 0b bd ff ff       	call   11527 <cio_printf>
   1581c:	83 c4 10             	add    $0x10,%esp

	// retrieve the exit status of this process
	pcb->exit_status = (int32_t) ARG(pcb,1);
   1581f:	8b 45 08             	mov    0x8(%ebp),%eax
   15822:	8b 00                	mov    (%eax),%eax
   15824:	83 c0 48             	add    $0x48,%eax
   15827:	83 c0 04             	add    $0x4,%eax
   1582a:	8b 00                	mov    (%eax),%eax
   1582c:	89 c2                	mov    %eax,%edx
   1582e:	8b 45 08             	mov    0x8(%ebp),%eax
   15831:	89 50 14             	mov    %edx,0x14(%eax)

	// now, we need to do the following:
	// 	reparent any children of this process and wake up init if need be
	// 	find this process' parent and wake it up if it's waiting
	
	pcb_zombify( pcb );
   15834:	83 ec 0c             	sub    $0xc,%esp
   15837:	ff 75 08             	pushl  0x8(%ebp)
   1583a:	e8 b3 e1 ff ff       	call   139f2 <pcb_zombify>
   1583f:	83 c4 10             	add    $0x10,%esp

	// pick a new winner
	current = NULL;
   15842:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   15849:	00 00 00 
	dispatch();
   1584c:	e8 1f ec ff ff       	call   14470 <dispatch>

	SYSCALL_EXIT( 0 );
   15851:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15856:	85 c0                	test   %eax,%eax
   15858:	74 18                	je     15872 <sys_exit+0xbc>
   1585a:	83 ec 04             	sub    $0x4,%esp
   1585d:	6a 00                	push   $0x0
   1585f:	68 fc b9 01 00       	push   $0x1b9fc
   15864:	68 7b b8 01 00       	push   $0x1b87b
   15869:	e8 b9 bc ff ff       	call   11527 <cio_printf>
   1586e:	83 c4 10             	add    $0x10,%esp
	return;
   15871:	90                   	nop
   15872:	90                   	nop
}
   15873:	c9                   	leave  
   15874:	c3                   	ret    

00015875 <sys_waitpid>:
** Blocks the calling process until the specified child (or any child)
** of the caller terminates. Intrinsic return is the PID of the child that
** terminated, or an error code; on success, returns the child's termination
** status via 'status' if that pointer is non-NULL.
*/
SYSIMPL(waitpid) {
   15875:	55                   	push   %ebp
   15876:	89 e5                	mov    %esp,%ebp
   15878:	53                   	push   %ebx
   15879:	83 ec 24             	sub    $0x24,%esp

	// sanity check
	assert( pcb != NULL );
   1587c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15880:	75 3b                	jne    158bd <sys_waitpid+0x48>
   15882:	83 ec 04             	sub    $0x4,%esp
   15885:	68 40 b8 01 00       	push   $0x1b840
   1588a:	6a 00                	push   $0x0
   1588c:	68 88 00 00 00       	push   $0x88
   15891:	68 49 b8 01 00       	push   $0x1b849
   15896:	68 08 ba 01 00       	push   $0x1ba08
   1589b:	68 54 b8 01 00       	push   $0x1b854
   158a0:	68 00 00 02 00       	push   $0x20000
   158a5:	e8 3d ce ff ff       	call   126e7 <sprint>
   158aa:	83 c4 20             	add    $0x20,%esp
   158ad:	83 ec 0c             	sub    $0xc,%esp
   158b0:	68 00 00 02 00       	push   $0x20000
   158b5:	e8 ad cb ff ff       	call   12467 <kpanic>
   158ba:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   158bd:	a1 e0 28 02 00       	mov    0x228e0,%eax
   158c2:	85 c0                	test   %eax,%eax
   158c4:	74 1c                	je     158e2 <sys_waitpid+0x6d>
   158c6:	8b 45 08             	mov    0x8(%ebp),%eax
   158c9:	8b 40 18             	mov    0x18(%eax),%eax
   158cc:	83 ec 04             	sub    $0x4,%esp
   158cf:	50                   	push   %eax
   158d0:	68 08 ba 01 00       	push   $0x1ba08
   158d5:	68 6a b8 01 00       	push   $0x1b86a
   158da:	e8 48 bc ff ff       	call   11527 <cio_printf>
   158df:	83 c4 10             	add    $0x10,%esp
	** we reap here; there could be several, but we only need to
	** find one.
	*/

	// verify that we aren't looking for ourselves!
	uint_t target = ARG(pcb,1);
   158e2:	8b 45 08             	mov    0x8(%ebp),%eax
   158e5:	8b 00                	mov    (%eax),%eax
   158e7:	83 c0 48             	add    $0x48,%eax
   158ea:	8b 40 04             	mov    0x4(%eax),%eax
   158ed:	89 45 e8             	mov    %eax,-0x18(%ebp)

	if( target == pcb->pid ) {
   158f0:	8b 45 08             	mov    0x8(%ebp),%eax
   158f3:	8b 40 18             	mov    0x18(%eax),%eax
   158f6:	39 45 e8             	cmp    %eax,-0x18(%ebp)
   158f9:	75 35                	jne    15930 <sys_waitpid+0xbb>
		RET(pcb) = E_BAD_PARAM;
   158fb:	8b 45 08             	mov    0x8(%ebp),%eax
   158fe:	8b 00                	mov    (%eax),%eax
   15900:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
		SYSCALL_EXIT( E_BAD_PARAM );
   15907:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1590c:	85 c0                	test   %eax,%eax
   1590e:	0f 84 55 02 00 00    	je     15b69 <sys_waitpid+0x2f4>
   15914:	83 ec 04             	sub    $0x4,%esp
   15917:	6a fe                	push   $0xfffffffe
   15919:	68 08 ba 01 00       	push   $0x1ba08
   1591e:	68 7b b8 01 00       	push   $0x1b87b
   15923:	e8 ff bb ff ff       	call   11527 <cio_printf>
   15928:	83 c4 10             	add    $0x10,%esp
		return;
   1592b:	e9 39 02 00 00       	jmp    15b69 <sys_waitpid+0x2f4>
	}

	// Good.  Now, figure out what we're looking for.

	pcb_t *child = NULL;
   15930:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if( target != 0 ) {
   15937:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   1593b:	0f 84 a7 00 00 00    	je     159e8 <sys_waitpid+0x173>

		// we're looking for a specific child
		child = pcb_find_pid( target );
   15941:	83 ec 0c             	sub    $0xc,%esp
   15944:	ff 75 e8             	pushl  -0x18(%ebp)
   15947:	e8 67 e3 ff ff       	call   13cb3 <pcb_find_pid>
   1594c:	83 c4 10             	add    $0x10,%esp
   1594f:	89 45 f4             	mov    %eax,-0xc(%ebp)

		if( child != NULL ) {
   15952:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15956:	74 5b                	je     159b3 <sys_waitpid+0x13e>

			// found the process; is it one of our children:
			if( child->parent != pcb ) {
   15958:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1595b:	8b 40 0c             	mov    0xc(%eax),%eax
   1595e:	39 45 08             	cmp    %eax,0x8(%ebp)
   15961:	74 35                	je     15998 <sys_waitpid+0x123>
				// NO, so we can't wait for it
				RET(pcb) = E_BAD_PARAM;
   15963:	8b 45 08             	mov    0x8(%ebp),%eax
   15966:	8b 00                	mov    (%eax),%eax
   15968:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
				SYSCALL_EXIT( E_BAD_PARAM );
   1596f:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15974:	85 c0                	test   %eax,%eax
   15976:	0f 84 f0 01 00 00    	je     15b6c <sys_waitpid+0x2f7>
   1597c:	83 ec 04             	sub    $0x4,%esp
   1597f:	6a fe                	push   $0xfffffffe
   15981:	68 08 ba 01 00       	push   $0x1ba08
   15986:	68 7b b8 01 00       	push   $0x1b87b
   1598b:	e8 97 bb ff ff       	call   11527 <cio_printf>
   15990:	83 c4 10             	add    $0x10,%esp
				return;
   15993:	e9 d4 01 00 00       	jmp    15b6c <sys_waitpid+0x2f7>
			}

			// yes!  is this one ready to be collected?
			if( child->state != STATE_ZOMBIE ) {
   15998:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1599b:	8b 40 1c             	mov    0x1c(%eax),%eax
   1599e:	83 f8 08             	cmp    $0x8,%eax
   159a1:	0f 84 bb 00 00 00    	je     15a62 <sys_waitpid+0x1ed>
				// no, so we'll have to block for now
				child = NULL;
   159a7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   159ae:	e9 af 00 00 00       	jmp    15a62 <sys_waitpid+0x1ed>
			}

		} else {

			// no such child
			RET(pcb) = E_BAD_PARAM;
   159b3:	8b 45 08             	mov    0x8(%ebp),%eax
   159b6:	8b 00                	mov    (%eax),%eax
   159b8:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
			SYSCALL_EXIT( E_BAD_PARAM );
   159bf:	a1 e0 28 02 00       	mov    0x228e0,%eax
   159c4:	85 c0                	test   %eax,%eax
   159c6:	0f 84 a3 01 00 00    	je     15b6f <sys_waitpid+0x2fa>
   159cc:	83 ec 04             	sub    $0x4,%esp
   159cf:	6a fe                	push   $0xfffffffe
   159d1:	68 08 ba 01 00       	push   $0x1ba08
   159d6:	68 7b b8 01 00       	push   $0x1b87b
   159db:	e8 47 bb ff ff       	call   11527 <cio_printf>
   159e0:	83 c4 10             	add    $0x10,%esp
			return;
   159e3:	e9 87 01 00 00       	jmp    15b6f <sys_waitpid+0x2fa>
		// looking for any child

		// we need to find a process that is our child
		// and has already exited

		child = NULL;
   159e8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
		bool_t found = false;
   159ef:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)

		// unfortunately, we can't stop at the first child,
		// so we need to do the iteration ourselves
		register pcb_t *curr = ptable;
   159f3:	bb 20 20 02 00       	mov    $0x22020,%ebx

		for( int i = 0; i < N_PROCS; ++i, ++curr ) {
   159f8:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   159ff:	eb 20                	jmp    15a21 <sys_waitpid+0x1ac>

			if( curr->parent == pcb ) {
   15a01:	8b 43 0c             	mov    0xc(%ebx),%eax
   15a04:	39 45 08             	cmp    %eax,0x8(%ebp)
   15a07:	75 11                	jne    15a1a <sys_waitpid+0x1a5>

				// found one!
				found = true;
   15a09:	c6 45 f3 01          	movb   $0x1,-0xd(%ebp)

				// has it already exited?
				if( curr->state == STATE_ZOMBIE ) {
   15a0d:	8b 43 1c             	mov    0x1c(%ebx),%eax
   15a10:	83 f8 08             	cmp    $0x8,%eax
   15a13:	75 05                	jne    15a1a <sys_waitpid+0x1a5>
					// yes, so we're done here
					child = curr;
   15a15:	89 5d f4             	mov    %ebx,-0xc(%ebp)
					break;
   15a18:	eb 0d                	jmp    15a27 <sys_waitpid+0x1b2>
		for( int i = 0; i < N_PROCS; ++i, ++curr ) {
   15a1a:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   15a1e:	83 c3 30             	add    $0x30,%ebx
   15a21:	83 7d ec 18          	cmpl   $0x18,-0x14(%ebp)
   15a25:	7e da                	jle    15a01 <sys_waitpid+0x18c>
				}
			}
		}

		if( !found ) {
   15a27:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   15a2b:	75 35                	jne    15a62 <sys_waitpid+0x1ed>
			// got through the loop without finding a child!
			RET(pcb) = E_NO_CHILDREN;
   15a2d:	8b 45 08             	mov    0x8(%ebp),%eax
   15a30:	8b 00                	mov    (%eax),%eax
   15a32:	c7 40 30 fc ff ff ff 	movl   $0xfffffffc,0x30(%eax)
			SYSCALL_EXIT( E_NO_CHILDREN );
   15a39:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15a3e:	85 c0                	test   %eax,%eax
   15a40:	0f 84 2c 01 00 00    	je     15b72 <sys_waitpid+0x2fd>
   15a46:	83 ec 04             	sub    $0x4,%esp
   15a49:	6a fc                	push   $0xfffffffc
   15a4b:	68 08 ba 01 00       	push   $0x1ba08
   15a50:	68 7b b8 01 00       	push   $0x1b87b
   15a55:	e8 cd ba ff ff       	call   11527 <cio_printf>
   15a5a:	83 c4 10             	add    $0x10,%esp
			return;
   15a5d:	e9 10 01 00 00       	jmp    15b72 <sys_waitpid+0x2fd>
	** case, we collect its status and clean it up; otherwise,
	** we block this process.
	*/

	// did we find one to collect?
	if( child == NULL ) {
   15a62:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15a66:	0f 85 96 00 00 00    	jne    15b02 <sys_waitpid+0x28d>

		// no - mark the parent as "Waiting"
		pcb->state = STATE_WAITING;
   15a6c:	8b 45 08             	mov    0x8(%ebp),%eax
   15a6f:	c7 40 1c 06 00 00 00 	movl   $0x6,0x1c(%eax)
		assert( pcb_queue_insert(waiting,pcb) == SUCCESS );
   15a76:	a1 10 20 02 00       	mov    0x22010,%eax
   15a7b:	83 ec 08             	sub    $0x8,%esp
   15a7e:	ff 75 08             	pushl  0x8(%ebp)
   15a81:	50                   	push   %eax
   15a82:	e8 4f e4 ff ff       	call   13ed6 <pcb_queue_insert>
   15a87:	83 c4 10             	add    $0x10,%esp
   15a8a:	85 c0                	test   %eax,%eax
   15a8c:	74 3b                	je     15ac9 <sys_waitpid+0x254>
   15a8e:	83 ec 04             	sub    $0x4,%esp
   15a91:	68 88 b8 01 00       	push   $0x1b888
   15a96:	6a 00                	push   $0x0
   15a98:	68 fe 00 00 00       	push   $0xfe
   15a9d:	68 49 b8 01 00       	push   $0x1b849
   15aa2:	68 08 ba 01 00       	push   $0x1ba08
   15aa7:	68 54 b8 01 00       	push   $0x1b854
   15aac:	68 00 00 02 00       	push   $0x20000
   15ab1:	e8 31 cc ff ff       	call   126e7 <sprint>
   15ab6:	83 c4 20             	add    $0x20,%esp
   15ab9:	83 ec 0c             	sub    $0xc,%esp
   15abc:	68 00 00 02 00       	push   $0x20000
   15ac1:	e8 a1 c9 ff ff       	call   12467 <kpanic>
   15ac6:	83 c4 10             	add    $0x10,%esp

		// select a new current process
		current = NULL;
   15ac9:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   15ad0:	00 00 00 
		dispatch();
   15ad3:	e8 98 e9 ff ff       	call   14470 <dispatch>
		SYSCALL_EXIT( (uint32_t) current );
   15ad8:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15add:	85 c0                	test   %eax,%eax
   15adf:	0f 84 90 00 00 00    	je     15b75 <sys_waitpid+0x300>
   15ae5:	a1 14 20 02 00       	mov    0x22014,%eax
   15aea:	83 ec 04             	sub    $0x4,%esp
   15aed:	50                   	push   %eax
   15aee:	68 08 ba 01 00       	push   $0x1ba08
   15af3:	68 7b b8 01 00       	push   $0x1b87b
   15af8:	e8 2a ba ff ff       	call   11527 <cio_printf>
   15afd:	83 c4 10             	add    $0x10,%esp
		return;
   15b00:	eb 73                	jmp    15b75 <sys_waitpid+0x300>
	}

	// found a Zombie; collect its information and clean it up
	RET(pcb) = child->pid;
   15b02:	8b 45 08             	mov    0x8(%ebp),%eax
   15b05:	8b 00                	mov    (%eax),%eax
   15b07:	8b 55 f4             	mov    -0xc(%ebp),%edx
   15b0a:	8b 52 18             	mov    0x18(%edx),%edx
   15b0d:	89 50 30             	mov    %edx,0x30(%eax)

	// get "status" pointer from parent
	int32_t *stat = (int32_t *) ARG(pcb,2);
   15b10:	8b 45 08             	mov    0x8(%ebp),%eax
   15b13:	8b 00                	mov    (%eax),%eax
   15b15:	83 c0 48             	add    $0x48,%eax
   15b18:	83 c0 08             	add    $0x8,%eax
   15b1b:	8b 00                	mov    (%eax),%eax
   15b1d:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	// if stat is NULL, the parent doesn't want the status
	if( stat != NULL ) {
   15b20:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   15b24:	74 0b                	je     15b31 <sys_waitpid+0x2bc>
		// ** This works in the baseline because we aren't using
		// ** any type of memory protection.  If address space
		// ** separation is implemented, this code will very likely
		// ** STOP WORKING, and will need to be fixed.
		// ********************************************************
		*stat = child->exit_status;
   15b26:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15b29:	8b 50 14             	mov    0x14(%eax),%edx
   15b2c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15b2f:	89 10                	mov    %edx,(%eax)
	}

	// clean up the child
	pcb_cleanup( child );
   15b31:	83 ec 0c             	sub    $0xc,%esp
   15b34:	ff 75 f4             	pushl  -0xc(%ebp)
   15b37:	e8 4a e1 ff ff       	call   13c86 <pcb_cleanup>
   15b3c:	83 c4 10             	add    $0x10,%esp

	SYSCALL_EXIT( RET(pcb) );
   15b3f:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15b44:	85 c0                	test   %eax,%eax
   15b46:	74 30                	je     15b78 <sys_waitpid+0x303>
   15b48:	8b 45 08             	mov    0x8(%ebp),%eax
   15b4b:	8b 00                	mov    (%eax),%eax
   15b4d:	8b 40 30             	mov    0x30(%eax),%eax
   15b50:	83 ec 04             	sub    $0x4,%esp
   15b53:	50                   	push   %eax
   15b54:	68 08 ba 01 00       	push   $0x1ba08
   15b59:	68 7b b8 01 00       	push   $0x1b87b
   15b5e:	e8 c4 b9 ff ff       	call   11527 <cio_printf>
   15b63:	83 c4 10             	add    $0x10,%esp
	return;
   15b66:	90                   	nop
   15b67:	eb 0f                	jmp    15b78 <sys_waitpid+0x303>
		return;
   15b69:	90                   	nop
   15b6a:	eb 0d                	jmp    15b79 <sys_waitpid+0x304>
				return;
   15b6c:	90                   	nop
   15b6d:	eb 0a                	jmp    15b79 <sys_waitpid+0x304>
			return;
   15b6f:	90                   	nop
   15b70:	eb 07                	jmp    15b79 <sys_waitpid+0x304>
			return;
   15b72:	90                   	nop
   15b73:	eb 04                	jmp    15b79 <sys_waitpid+0x304>
		return;
   15b75:	90                   	nop
   15b76:	eb 01                	jmp    15b79 <sys_waitpid+0x304>
	return;
   15b78:	90                   	nop
}
   15b79:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   15b7c:	c9                   	leave  
   15b7d:	c3                   	ret    

00015b7e <sys_fork>:
**
** Creates a new process that is a duplicate of the calling process.
** Returns the child's PID to the parent, and 0 to the child, on success;
** else, returns an error code to the parent.
*/
SYSIMPL(fork) {
   15b7e:	55                   	push   %ebp
   15b7f:	89 e5                	mov    %esp,%ebp
   15b81:	53                   	push   %ebx
   15b82:	83 ec 14             	sub    $0x14,%esp

	// sanity check
	assert( pcb != NULL );
   15b85:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15b89:	75 3b                	jne    15bc6 <sys_fork+0x48>
   15b8b:	83 ec 04             	sub    $0x4,%esp
   15b8e:	68 40 b8 01 00       	push   $0x1b840
   15b93:	6a 00                	push   $0x0
   15b95:	68 2e 01 00 00       	push   $0x12e
   15b9a:	68 49 b8 01 00       	push   $0x1b849
   15b9f:	68 14 ba 01 00       	push   $0x1ba14
   15ba4:	68 54 b8 01 00       	push   $0x1b854
   15ba9:	68 00 00 02 00       	push   $0x20000
   15bae:	e8 34 cb ff ff       	call   126e7 <sprint>
   15bb3:	83 c4 20             	add    $0x20,%esp
   15bb6:	83 ec 0c             	sub    $0xc,%esp
   15bb9:	68 00 00 02 00       	push   $0x20000
   15bbe:	e8 a4 c8 ff ff       	call   12467 <kpanic>
   15bc3:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   15bc6:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15bcb:	85 c0                	test   %eax,%eax
   15bcd:	74 1c                	je     15beb <sys_fork+0x6d>
   15bcf:	8b 45 08             	mov    0x8(%ebp),%eax
   15bd2:	8b 40 18             	mov    0x18(%eax),%eax
   15bd5:	83 ec 04             	sub    $0x4,%esp
   15bd8:	50                   	push   %eax
   15bd9:	68 14 ba 01 00       	push   $0x1ba14
   15bde:	68 6a b8 01 00       	push   $0x1b86a
   15be3:	e8 3f b9 ff ff       	call   11527 <cio_printf>
   15be8:	83 c4 10             	add    $0x10,%esp

	// Make sure there's room for another process!
	pcb_t *new;
	if( pcb_alloc(&new) != SUCCESS || new == NULL ) {
   15beb:	83 ec 0c             	sub    $0xc,%esp
   15bee:	8d 45 ec             	lea    -0x14(%ebp),%eax
   15bf1:	50                   	push   %eax
   15bf2:	e8 4f dc ff ff       	call   13846 <pcb_alloc>
   15bf7:	83 c4 10             	add    $0x10,%esp
   15bfa:	85 c0                	test   %eax,%eax
   15bfc:	75 07                	jne    15c05 <sys_fork+0x87>
   15bfe:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15c01:	85 c0                	test   %eax,%eax
   15c03:	75 3c                	jne    15c41 <sys_fork+0xc3>
		RET(pcb) = E_NO_PROCS;
   15c05:	8b 45 08             	mov    0x8(%ebp),%eax
   15c08:	8b 00                	mov    (%eax),%eax
   15c0a:	c7 40 30 f9 ff ff ff 	movl   $0xfffffff9,0x30(%eax)
		SYSCALL_EXIT( RET(pcb) );
   15c11:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15c16:	85 c0                	test   %eax,%eax
   15c18:	0f 84 c0 01 00 00    	je     15dde <sys_fork+0x260>
   15c1e:	8b 45 08             	mov    0x8(%ebp),%eax
   15c21:	8b 00                	mov    (%eax),%eax
   15c23:	8b 40 30             	mov    0x30(%eax),%eax
   15c26:	83 ec 04             	sub    $0x4,%esp
   15c29:	50                   	push   %eax
   15c2a:	68 14 ba 01 00       	push   $0x1ba14
   15c2f:	68 7b b8 01 00       	push   $0x1b87b
   15c34:	e8 ee b8 ff ff       	call   11527 <cio_printf>
   15c39:	83 c4 10             	add    $0x10,%esp
		return;
   15c3c:	e9 9d 01 00 00       	jmp    15dde <sys_fork+0x260>
	}

	// create a stack for the new child
	new->stack = pcb_stack_alloc( N_USTKPAGES );
   15c41:	8b 5d ec             	mov    -0x14(%ebp),%ebx
   15c44:	83 ec 0c             	sub    $0xc,%esp
   15c47:	6a 02                	push   $0x2
   15c49:	e8 f8 dc ff ff       	call   13946 <pcb_stack_alloc>
   15c4e:	83 c4 10             	add    $0x10,%esp
   15c51:	89 43 04             	mov    %eax,0x4(%ebx)
	if( new->stack == NULL ) {
   15c54:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15c57:	8b 40 04             	mov    0x4(%eax),%eax
   15c5a:	85 c0                	test   %eax,%eax
   15c5c:	75 44                	jne    15ca2 <sys_fork+0x124>
		pcb_free( new );
   15c5e:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15c61:	83 ec 0c             	sub    $0xc,%esp
   15c64:	50                   	push   %eax
   15c65:	e8 52 dc ff ff       	call   138bc <pcb_free>
   15c6a:	83 c4 10             	add    $0x10,%esp
		RET(pcb) = E_NO_PROCS;
   15c6d:	8b 45 08             	mov    0x8(%ebp),%eax
   15c70:	8b 00                	mov    (%eax),%eax
   15c72:	c7 40 30 f9 ff ff ff 	movl   $0xfffffff9,0x30(%eax)
		SYSCALL_EXIT(E_NO_PROCS);
   15c79:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15c7e:	85 c0                	test   %eax,%eax
   15c80:	0f 84 5b 01 00 00    	je     15de1 <sys_fork+0x263>
   15c86:	83 ec 04             	sub    $0x4,%esp
   15c89:	6a f9                	push   $0xfffffff9
   15c8b:	68 14 ba 01 00       	push   $0x1ba14
   15c90:	68 7b b8 01 00       	push   $0x1b87b
   15c95:	e8 8d b8 ff ff       	call   11527 <cio_printf>
   15c9a:	83 c4 10             	add    $0x10,%esp
		return;
   15c9d:	e9 3f 01 00 00       	jmp    15de1 <sys_fork+0x263>
	}
	// remember that we used the default size
	new->stkpgs = N_USTKPAGES;
   15ca2:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15ca5:	c7 40 28 02 00 00 00 	movl   $0x2,0x28(%eax)

	// duplicate the parent's stack
	memcpy( (void *)new->stack, (void *)pcb->stack, N_USTKPAGES * SZ_PAGE );
   15cac:	8b 45 08             	mov    0x8(%ebp),%eax
   15caf:	8b 50 04             	mov    0x4(%eax),%edx
   15cb2:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15cb5:	8b 40 04             	mov    0x4(%eax),%eax
   15cb8:	83 ec 04             	sub    $0x4,%esp
   15cbb:	68 00 20 00 00       	push   $0x2000
   15cc0:	52                   	push   %edx
   15cc1:	50                   	push   %eax
   15cc2:	e8 be c8 ff ff       	call   12585 <memcpy>
   15cc7:	83 c4 10             	add    $0x10,%esp
    ** them, as that's impractical. As a result, user code that relies on
    ** such pointers may behave strangely after a fork().
    */

    // Figure out the byte offset from one stack to the other.
    int32_t offset = (void *) new->stack - (void *) pcb->stack;
   15cca:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15ccd:	8b 40 04             	mov    0x4(%eax),%eax
   15cd0:	89 c2                	mov    %eax,%edx
   15cd2:	8b 45 08             	mov    0x8(%ebp),%eax
   15cd5:	8b 40 04             	mov    0x4(%eax),%eax
   15cd8:	29 c2                	sub    %eax,%edx
   15cda:	89 d0                	mov    %edx,%eax
   15cdc:	89 45 f0             	mov    %eax,-0x10(%ebp)

    // Add this to the child's context pointer.
    new->context = (context_t *) (((void *)pcb->context) + offset);
   15cdf:	8b 45 08             	mov    0x8(%ebp),%eax
   15ce2:	8b 08                	mov    (%eax),%ecx
   15ce4:	8b 55 f0             	mov    -0x10(%ebp),%edx
   15ce7:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15cea:	01 ca                	add    %ecx,%edx
   15cec:	89 10                	mov    %edx,(%eax)

    // Fix the child's ESP and EBP values IFF they're non-zero.
    if( REG(new,ebp) != 0 ) {
   15cee:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15cf1:	8b 00                	mov    (%eax),%eax
   15cf3:	8b 40 1c             	mov    0x1c(%eax),%eax
   15cf6:	85 c0                	test   %eax,%eax
   15cf8:	74 15                	je     15d0f <sys_fork+0x191>
        REG(new,ebp) += offset;
   15cfa:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15cfd:	8b 00                	mov    (%eax),%eax
   15cff:	8b 48 1c             	mov    0x1c(%eax),%ecx
   15d02:	8b 55 f0             	mov    -0x10(%ebp),%edx
   15d05:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d08:	8b 00                	mov    (%eax),%eax
   15d0a:	01 ca                	add    %ecx,%edx
   15d0c:	89 50 1c             	mov    %edx,0x1c(%eax)
    }
    if( REG(new,esp) != 0 ) {
   15d0f:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d12:	8b 00                	mov    (%eax),%eax
   15d14:	8b 40 20             	mov    0x20(%eax),%eax
   15d17:	85 c0                	test   %eax,%eax
   15d19:	74 15                	je     15d30 <sys_fork+0x1b2>
        REG(new,esp) += offset;
   15d1b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d1e:	8b 00                	mov    (%eax),%eax
   15d20:	8b 48 20             	mov    0x20(%eax),%ecx
   15d23:	8b 55 f0             	mov    -0x10(%ebp),%edx
   15d26:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d29:	8b 00                	mov    (%eax),%eax
   15d2b:	01 ca                	add    %ecx,%edx
   15d2d:	89 50 20             	mov    %edx,0x20(%eax)
    }

    // Follow the EBP chain through the child's stack.
    uint32_t *bp = (uint32_t *) REG(new,ebp);
   15d30:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d33:	8b 00                	mov    (%eax),%eax
   15d35:	8b 40 1c             	mov    0x1c(%eax),%eax
   15d38:	89 45 f4             	mov    %eax,-0xc(%ebp)
    while( bp ) {
   15d3b:	eb 17                	jmp    15d54 <sys_fork+0x1d6>
        *bp += offset;
   15d3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15d40:	8b 10                	mov    (%eax),%edx
   15d42:	8b 45 f0             	mov    -0x10(%ebp),%eax
   15d45:	01 c2                	add    %eax,%edx
   15d47:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15d4a:	89 10                	mov    %edx,(%eax)
        bp = (uint32_t *) *bp;
   15d4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15d4f:	8b 00                	mov    (%eax),%eax
   15d51:	89 45 f4             	mov    %eax,-0xc(%ebp)
    while( bp ) {
   15d54:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15d58:	75 e3                	jne    15d3d <sys_fork+0x1bf>
    }

	// Set the child's identity.
	new->pid = next_pid++;
   15d5a:	a1 1c 20 02 00       	mov    0x2201c,%eax
   15d5f:	8d 50 01             	lea    0x1(%eax),%edx
   15d62:	89 15 1c 20 02 00    	mov    %edx,0x2201c
   15d68:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15d6b:	89 42 18             	mov    %eax,0x18(%edx)
	new->parent = pcb;
   15d6e:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d71:	8b 55 08             	mov    0x8(%ebp),%edx
   15d74:	89 50 0c             	mov    %edx,0xc(%eax)
	new->state = STATE_NEW;
   15d77:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d7a:	c7 40 1c 01 00 00 00 	movl   $0x1,0x1c(%eax)

	// replicate other things inherited from the parent
	new->priority = pcb->priority;
   15d81:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d84:	8b 55 08             	mov    0x8(%ebp),%edx
   15d87:	8b 52 20             	mov    0x20(%edx),%edx
   15d8a:	89 50 20             	mov    %edx,0x20(%eax)

	// Set the return values for the two processes.
	RET(pcb) = new->pid;
   15d8d:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15d90:	8b 45 08             	mov    0x8(%ebp),%eax
   15d93:	8b 00                	mov    (%eax),%eax
   15d95:	8b 52 18             	mov    0x18(%edx),%edx
   15d98:	89 50 30             	mov    %edx,0x30(%eax)
	RET(new) = 0;
   15d9b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d9e:	8b 00                	mov    (%eax),%eax
   15da0:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)

	// Schedule the child, and let the parent continue.
	schedule( new );
   15da7:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15daa:	83 ec 0c             	sub    $0xc,%esp
   15dad:	50                   	push   %eax
   15dae:	e8 fc e5 ff ff       	call   143af <schedule>
   15db3:	83 c4 10             	add    $0x10,%esp

	SYSCALL_EXIT( new->pid );
   15db6:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15dbb:	85 c0                	test   %eax,%eax
   15dbd:	74 25                	je     15de4 <sys_fork+0x266>
   15dbf:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15dc2:	8b 40 18             	mov    0x18(%eax),%eax
   15dc5:	83 ec 04             	sub    $0x4,%esp
   15dc8:	50                   	push   %eax
   15dc9:	68 14 ba 01 00       	push   $0x1ba14
   15dce:	68 7b b8 01 00       	push   $0x1b87b
   15dd3:	e8 4f b7 ff ff       	call   11527 <cio_printf>
   15dd8:	83 c4 10             	add    $0x10,%esp
	return;
   15ddb:	90                   	nop
   15ddc:	eb 06                	jmp    15de4 <sys_fork+0x266>
		return;
   15dde:	90                   	nop
   15ddf:	eb 04                	jmp    15de5 <sys_fork+0x267>
		return;
   15de1:	90                   	nop
   15de2:	eb 01                	jmp    15de5 <sys_fork+0x267>
	return;
   15de4:	90                   	nop
}
   15de5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   15de8:	c9                   	leave  
   15de9:	c3                   	ret    

00015dea <sys_exec>:
** indicated program.
**
** Returns only on failure.
*/
SYSIMPL(exec)
{
   15dea:	55                   	push   %ebp
   15deb:	89 e5                	mov    %esp,%ebp
   15ded:	83 ec 18             	sub    $0x18,%esp
	// sanity check
	assert( pcb != NULL );
   15df0:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15df4:	75 3b                	jne    15e31 <sys_exec+0x47>
   15df6:	83 ec 04             	sub    $0x4,%esp
   15df9:	68 40 b8 01 00       	push   $0x1b840
   15dfe:	6a 00                	push   $0x0
   15e00:	68 8a 01 00 00       	push   $0x18a
   15e05:	68 49 b8 01 00       	push   $0x1b849
   15e0a:	68 20 ba 01 00       	push   $0x1ba20
   15e0f:	68 54 b8 01 00       	push   $0x1b854
   15e14:	68 00 00 02 00       	push   $0x20000
   15e19:	e8 c9 c8 ff ff       	call   126e7 <sprint>
   15e1e:	83 c4 20             	add    $0x20,%esp
   15e21:	83 ec 0c             	sub    $0xc,%esp
   15e24:	68 00 00 02 00       	push   $0x20000
   15e29:	e8 39 c6 ff ff       	call   12467 <kpanic>
   15e2e:	83 c4 10             	add    $0x10,%esp

	uint_t what = ARG(pcb,1);
   15e31:	8b 45 08             	mov    0x8(%ebp),%eax
   15e34:	8b 00                	mov    (%eax),%eax
   15e36:	83 c0 48             	add    $0x48,%eax
   15e39:	8b 40 04             	mov    0x4(%eax),%eax
   15e3c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	const char **args = (const char **) ARG(pcb,2);
   15e3f:	8b 45 08             	mov    0x8(%ebp),%eax
   15e42:	8b 00                	mov    (%eax),%eax
   15e44:	83 c0 48             	add    $0x48,%eax
   15e47:	83 c0 08             	add    $0x8,%eax
   15e4a:	8b 00                	mov    (%eax),%eax
   15e4c:	89 45 f0             	mov    %eax,-0x10(%ebp)

	SYSCALL_ENTER( pcb->pid );
   15e4f:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15e54:	85 c0                	test   %eax,%eax
   15e56:	74 1c                	je     15e74 <sys_exec+0x8a>
   15e58:	8b 45 08             	mov    0x8(%ebp),%eax
   15e5b:	8b 40 18             	mov    0x18(%eax),%eax
   15e5e:	83 ec 04             	sub    $0x4,%esp
   15e61:	50                   	push   %eax
   15e62:	68 20 ba 01 00       	push   $0x1ba20
   15e67:	68 6a b8 01 00       	push   $0x1b86a
   15e6c:	e8 b6 b6 ff ff       	call   11527 <cio_printf>
   15e71:	83 c4 10             	add    $0x10,%esp

	// we create a new stack for the process so we don't have to
	// worry about overwriting data in the old stack; however, we
	// need to keep the old one around until after we have copied
	// all the argument data from it.
	void *oldstack = (void *) pcb->stack;
   15e74:	8b 45 08             	mov    0x8(%ebp),%eax
   15e77:	8b 40 04             	mov    0x4(%eax),%eax
   15e7a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32_t oldsize = pcb->stkpgs;
   15e7d:	8b 45 08             	mov    0x8(%ebp),%eax
   15e80:	8b 40 28             	mov    0x28(%eax),%eax
   15e83:	89 45 e8             	mov    %eax,-0x18(%ebp)

	// allocate a new stack of the default size
	pcb->stack = pcb_stack_alloc( N_USTKPAGES );
   15e86:	83 ec 0c             	sub    $0xc,%esp
   15e89:	6a 02                	push   $0x2
   15e8b:	e8 b6 da ff ff       	call   13946 <pcb_stack_alloc>
   15e90:	83 c4 10             	add    $0x10,%esp
   15e93:	89 c2                	mov    %eax,%edx
   15e95:	8b 45 08             	mov    0x8(%ebp),%eax
   15e98:	89 50 04             	mov    %edx,0x4(%eax)
	assert( pcb->stack != NULL );
   15e9b:	8b 45 08             	mov    0x8(%ebp),%eax
   15e9e:	8b 40 04             	mov    0x4(%eax),%eax
   15ea1:	85 c0                	test   %eax,%eax
   15ea3:	75 3b                	jne    15ee0 <sys_exec+0xf6>
   15ea5:	83 ec 04             	sub    $0x4,%esp
   15ea8:	68 ad b8 01 00       	push   $0x1b8ad
   15ead:	6a 00                	push   $0x0
   15eaf:	68 9d 01 00 00       	push   $0x19d
   15eb4:	68 49 b8 01 00       	push   $0x1b849
   15eb9:	68 20 ba 01 00       	push   $0x1ba20
   15ebe:	68 54 b8 01 00       	push   $0x1b854
   15ec3:	68 00 00 02 00       	push   $0x20000
   15ec8:	e8 1a c8 ff ff       	call   126e7 <sprint>
   15ecd:	83 c4 20             	add    $0x20,%esp
   15ed0:	83 ec 0c             	sub    $0xc,%esp
   15ed3:	68 00 00 02 00       	push   $0x20000
   15ed8:	e8 8a c5 ff ff       	call   12467 <kpanic>
   15edd:	83 c4 10             	add    $0x10,%esp
	pcb->stkpgs = N_USTKPAGES;
   15ee0:	8b 45 08             	mov    0x8(%ebp),%eax
   15ee3:	c7 40 28 02 00 00 00 	movl   $0x2,0x28(%eax)

	// set up the new stack using the old stack data
	pcb->context = stack_setup( pcb, what, args, true );
   15eea:	6a 01                	push   $0x1
   15eec:	ff 75 f0             	pushl  -0x10(%ebp)
   15eef:	ff 75 f4             	pushl  -0xc(%ebp)
   15ef2:	ff 75 08             	pushl  0x8(%ebp)
   15ef5:	e8 93 0b 00 00       	call   16a8d <stack_setup>
   15efa:	83 c4 10             	add    $0x10,%esp
   15efd:	89 c2                	mov    %eax,%edx
   15eff:	8b 45 08             	mov    0x8(%ebp),%eax
   15f02:	89 10                	mov    %edx,(%eax)
	assert( pcb->context != NULL );
   15f04:	8b 45 08             	mov    0x8(%ebp),%eax
   15f07:	8b 00                	mov    (%eax),%eax
   15f09:	85 c0                	test   %eax,%eax
   15f0b:	75 3b                	jne    15f48 <sys_exec+0x15e>
   15f0d:	83 ec 04             	sub    $0x4,%esp
   15f10:	68 bd b8 01 00       	push   $0x1b8bd
   15f15:	6a 00                	push   $0x0
   15f17:	68 a2 01 00 00       	push   $0x1a2
   15f1c:	68 49 b8 01 00       	push   $0x1b849
   15f21:	68 20 ba 01 00       	push   $0x1ba20
   15f26:	68 54 b8 01 00       	push   $0x1b854
   15f2b:	68 00 00 02 00       	push   $0x20000
   15f30:	e8 b2 c7 ff ff       	call   126e7 <sprint>
   15f35:	83 c4 20             	add    $0x20,%esp
   15f38:	83 ec 0c             	sub    $0xc,%esp
   15f3b:	68 00 00 02 00       	push   $0x20000
   15f40:	e8 22 c5 ff ff       	call   12467 <kpanic>
   15f45:	83 c4 10             	add    $0x10,%esp

	// now we can safely free the old stack
	pcb_stack_free( oldstack, oldsize );
   15f48:	83 ec 08             	sub    $0x8,%esp
   15f4b:	ff 75 e8             	pushl  -0x18(%ebp)
   15f4e:	ff 75 ec             	pushl  -0x14(%ebp)
   15f51:	e8 34 da ff ff       	call   1398a <pcb_stack_free>
   15f56:	83 c4 10             	add    $0x10,%esp
	 **	(C) reset this one's time slice and let it continue
	 **
	 ** We choose option A.
	 */

	schedule( pcb );
   15f59:	83 ec 0c             	sub    $0xc,%esp
   15f5c:	ff 75 08             	pushl  0x8(%ebp)
   15f5f:	e8 4b e4 ff ff       	call   143af <schedule>
   15f64:	83 c4 10             	add    $0x10,%esp

	// reset 'current' to keep dispatch() happy
	current = NULL;
   15f67:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   15f6e:	00 00 00 
	dispatch();
   15f71:	e8 fa e4 ff ff       	call   14470 <dispatch>
}
   15f76:	90                   	nop
   15f77:	c9                   	leave  
   15f78:	c3                   	ret    

00015f79 <sys_read>:
**		int read( uint_t chan, void *buffer, uint_t length );
**
** Reads up to 'length' bytes from 'chan' into 'buffer'. Returns the
** count of bytes actually transferred.
*/
SYSIMPL(read) {
   15f79:	55                   	push   %ebp
   15f7a:	89 e5                	mov    %esp,%ebp
   15f7c:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   15f7f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15f83:	75 3b                	jne    15fc0 <sys_read+0x47>
   15f85:	83 ec 04             	sub    $0x4,%esp
   15f88:	68 40 b8 01 00       	push   $0x1b840
   15f8d:	6a 00                	push   $0x0
   15f8f:	68 c3 01 00 00       	push   $0x1c3
   15f94:	68 49 b8 01 00       	push   $0x1b849
   15f99:	68 2c ba 01 00       	push   $0x1ba2c
   15f9e:	68 54 b8 01 00       	push   $0x1b854
   15fa3:	68 00 00 02 00       	push   $0x20000
   15fa8:	e8 3a c7 ff ff       	call   126e7 <sprint>
   15fad:	83 c4 20             	add    $0x20,%esp
   15fb0:	83 ec 0c             	sub    $0xc,%esp
   15fb3:	68 00 00 02 00       	push   $0x20000
   15fb8:	e8 aa c4 ff ff       	call   12467 <kpanic>
   15fbd:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   15fc0:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15fc5:	85 c0                	test   %eax,%eax
   15fc7:	74 1c                	je     15fe5 <sys_read+0x6c>
   15fc9:	8b 45 08             	mov    0x8(%ebp),%eax
   15fcc:	8b 40 18             	mov    0x18(%eax),%eax
   15fcf:	83 ec 04             	sub    $0x4,%esp
   15fd2:	50                   	push   %eax
   15fd3:	68 2c ba 01 00       	push   $0x1ba2c
   15fd8:	68 6a b8 01 00       	push   $0x1b86a
   15fdd:	e8 45 b5 ff ff       	call   11527 <cio_printf>
   15fe2:	83 c4 10             	add    $0x10,%esp
	
	// grab the arguments
	uint_t chan = ARG(pcb,1);
   15fe5:	8b 45 08             	mov    0x8(%ebp),%eax
   15fe8:	8b 00                	mov    (%eax),%eax
   15fea:	83 c0 48             	add    $0x48,%eax
   15fed:	8b 40 04             	mov    0x4(%eax),%eax
   15ff0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	char *buf = (char *) ARG(pcb,2);
   15ff3:	8b 45 08             	mov    0x8(%ebp),%eax
   15ff6:	8b 00                	mov    (%eax),%eax
   15ff8:	83 c0 48             	add    $0x48,%eax
   15ffb:	83 c0 08             	add    $0x8,%eax
   15ffe:	8b 00                	mov    (%eax),%eax
   16000:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint_t len = ARG(pcb,3);
   16003:	8b 45 08             	mov    0x8(%ebp),%eax
   16006:	8b 00                	mov    (%eax),%eax
   16008:	83 c0 48             	add    $0x48,%eax
   1600b:	8b 40 0c             	mov    0xc(%eax),%eax
   1600e:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// if the buffer is of length 0, we're done!
	if( len == 0 ) {
   16011:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   16015:	75 35                	jne    1604c <sys_read+0xd3>
		RET(pcb) = 0;
   16017:	8b 45 08             	mov    0x8(%ebp),%eax
   1601a:	8b 00                	mov    (%eax),%eax
   1601c:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
		SYSCALL_EXIT( 0 );
   16023:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16028:	85 c0                	test   %eax,%eax
   1602a:	0f 84 2b 01 00 00    	je     1615b <sys_read+0x1e2>
   16030:	83 ec 04             	sub    $0x4,%esp
   16033:	6a 00                	push   $0x0
   16035:	68 2c ba 01 00       	push   $0x1ba2c
   1603a:	68 7b b8 01 00       	push   $0x1b87b
   1603f:	e8 e3 b4 ff ff       	call   11527 <cio_printf>
   16044:	83 c4 10             	add    $0x10,%esp
		return;
   16047:	e9 0f 01 00 00       	jmp    1615b <sys_read+0x1e2>
	}

	// try to get the next character(s)
	int n = 0;
   1604c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	if( chan == CHAN_CIO ) {
   16053:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   16057:	0f 85 85 00 00 00    	jne    160e2 <sys_read+0x169>

		// console input is non-blocking
		if( cio_input_queue() < 1 ) {
   1605d:	e8 49 b7 ff ff       	call   117ab <cio_input_queue>
   16062:	85 c0                	test   %eax,%eax
   16064:	7f 35                	jg     1609b <sys_read+0x122>
			RET(pcb) = 0;
   16066:	8b 45 08             	mov    0x8(%ebp),%eax
   16069:	8b 00                	mov    (%eax),%eax
   1606b:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
			SYSCALL_EXIT( 0 );
   16072:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16077:	85 c0                	test   %eax,%eax
   16079:	0f 84 df 00 00 00    	je     1615e <sys_read+0x1e5>
   1607f:	83 ec 04             	sub    $0x4,%esp
   16082:	6a 00                	push   $0x0
   16084:	68 2c ba 01 00       	push   $0x1ba2c
   16089:	68 7b b8 01 00       	push   $0x1b87b
   1608e:	e8 94 b4 ff ff       	call   11527 <cio_printf>
   16093:	83 c4 10             	add    $0x10,%esp
			return;
   16096:	e9 c3 00 00 00       	jmp    1615e <sys_read+0x1e5>
		}
		// at least one character
		n = cio_gets( buf, len );
   1609b:	83 ec 08             	sub    $0x8,%esp
   1609e:	ff 75 ec             	pushl  -0x14(%ebp)
   160a1:	ff 75 f0             	pushl  -0x10(%ebp)
   160a4:	e8 b1 b6 ff ff       	call   1175a <cio_gets>
   160a9:	83 c4 10             	add    $0x10,%esp
   160ac:	89 45 e8             	mov    %eax,-0x18(%ebp)
		RET(pcb) = n;
   160af:	8b 45 08             	mov    0x8(%ebp),%eax
   160b2:	8b 00                	mov    (%eax),%eax
   160b4:	8b 55 e8             	mov    -0x18(%ebp),%edx
   160b7:	89 50 30             	mov    %edx,0x30(%eax)
		SYSCALL_EXIT( n );
   160ba:	a1 e0 28 02 00       	mov    0x228e0,%eax
   160bf:	85 c0                	test   %eax,%eax
   160c1:	0f 84 9a 00 00 00    	je     16161 <sys_read+0x1e8>
   160c7:	8b 45 e8             	mov    -0x18(%ebp),%eax
   160ca:	83 ec 04             	sub    $0x4,%esp
   160cd:	50                   	push   %eax
   160ce:	68 2c ba 01 00       	push   $0x1ba2c
   160d3:	68 7b b8 01 00       	push   $0x1b87b
   160d8:	e8 4a b4 ff ff       	call   11527 <cio_printf>
   160dd:	83 c4 10             	add    $0x10,%esp
		return;
   160e0:	eb 7f                	jmp    16161 <sys_read+0x1e8>

	} else if( chan == CHAN_SIO ) {
   160e2:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
   160e6:	75 44                	jne    1612c <sys_read+0x1b3>

		// SIO input is blocking, so if there are no characters
		// available, we'll block this process
		n = sio_read( buf, len );
   160e8:	8b 45 ec             	mov    -0x14(%ebp),%eax
   160eb:	83 ec 08             	sub    $0x8,%esp
   160ee:	50                   	push   %eax
   160ef:	ff 75 f0             	pushl  -0x10(%ebp)
   160f2:	e8 66 f0 ff ff       	call   1515d <sio_read>
   160f7:	83 c4 10             	add    $0x10,%esp
   160fa:	89 45 e8             	mov    %eax,-0x18(%ebp)
		RET(pcb) = n;
   160fd:	8b 45 08             	mov    0x8(%ebp),%eax
   16100:	8b 00                	mov    (%eax),%eax
   16102:	8b 55 e8             	mov    -0x18(%ebp),%edx
   16105:	89 50 30             	mov    %edx,0x30(%eax)
		SYSCALL_EXIT( n );
   16108:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1610d:	85 c0                	test   %eax,%eax
   1610f:	74 53                	je     16164 <sys_read+0x1eb>
   16111:	8b 45 e8             	mov    -0x18(%ebp),%eax
   16114:	83 ec 04             	sub    $0x4,%esp
   16117:	50                   	push   %eax
   16118:	68 2c ba 01 00       	push   $0x1ba2c
   1611d:	68 7b b8 01 00       	push   $0x1b87b
   16122:	e8 00 b4 ff ff       	call   11527 <cio_printf>
   16127:	83 c4 10             	add    $0x10,%esp
		return;
   1612a:	eb 38                	jmp    16164 <sys_read+0x1eb>

	}

	// bad channel code
	RET(pcb) = E_BAD_PARAM;
   1612c:	8b 45 08             	mov    0x8(%ebp),%eax
   1612f:	8b 00                	mov    (%eax),%eax
   16131:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
	SYSCALL_EXIT( E_BAD_PARAM );
   16138:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1613d:	85 c0                	test   %eax,%eax
   1613f:	74 26                	je     16167 <sys_read+0x1ee>
   16141:	83 ec 04             	sub    $0x4,%esp
   16144:	6a fe                	push   $0xfffffffe
   16146:	68 2c ba 01 00       	push   $0x1ba2c
   1614b:	68 7b b8 01 00       	push   $0x1b87b
   16150:	e8 d2 b3 ff ff       	call   11527 <cio_printf>
   16155:	83 c4 10             	add    $0x10,%esp
	return;
   16158:	90                   	nop
   16159:	eb 0c                	jmp    16167 <sys_read+0x1ee>
		return;
   1615b:	90                   	nop
   1615c:	eb 0a                	jmp    16168 <sys_read+0x1ef>
			return;
   1615e:	90                   	nop
   1615f:	eb 07                	jmp    16168 <sys_read+0x1ef>
		return;
   16161:	90                   	nop
   16162:	eb 04                	jmp    16168 <sys_read+0x1ef>
		return;
   16164:	90                   	nop
   16165:	eb 01                	jmp    16168 <sys_read+0x1ef>
	return;
   16167:	90                   	nop
}
   16168:	c9                   	leave  
   16169:	c3                   	ret    

0001616a <sys_write>:
**		int write( uint_t chan, const void *buffer, uint_t length );
**
** Writes 'length' bytes from 'buffer' to 'chan'. Returns the
** count of bytes actually transferred.
*/
SYSIMPL(write) {
   1616a:	55                   	push   %ebp
   1616b:	89 e5                	mov    %esp,%ebp
   1616d:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   16170:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16174:	75 3b                	jne    161b1 <sys_write+0x47>
   16176:	83 ec 04             	sub    $0x4,%esp
   16179:	68 40 b8 01 00       	push   $0x1b840
   1617e:	6a 00                	push   $0x0
   16180:	68 01 02 00 00       	push   $0x201
   16185:	68 49 b8 01 00       	push   $0x1b849
   1618a:	68 38 ba 01 00       	push   $0x1ba38
   1618f:	68 54 b8 01 00       	push   $0x1b854
   16194:	68 00 00 02 00       	push   $0x20000
   16199:	e8 49 c5 ff ff       	call   126e7 <sprint>
   1619e:	83 c4 20             	add    $0x20,%esp
   161a1:	83 ec 0c             	sub    $0xc,%esp
   161a4:	68 00 00 02 00       	push   $0x20000
   161a9:	e8 b9 c2 ff ff       	call   12467 <kpanic>
   161ae:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   161b1:	a1 e0 28 02 00       	mov    0x228e0,%eax
   161b6:	85 c0                	test   %eax,%eax
   161b8:	74 1c                	je     161d6 <sys_write+0x6c>
   161ba:	8b 45 08             	mov    0x8(%ebp),%eax
   161bd:	8b 40 18             	mov    0x18(%eax),%eax
   161c0:	83 ec 04             	sub    $0x4,%esp
   161c3:	50                   	push   %eax
   161c4:	68 38 ba 01 00       	push   $0x1ba38
   161c9:	68 6a b8 01 00       	push   $0x1b86a
   161ce:	e8 54 b3 ff ff       	call   11527 <cio_printf>
   161d3:	83 c4 10             	add    $0x10,%esp

	// grab the parameters
	uint_t chan = ARG(pcb,1);
   161d6:	8b 45 08             	mov    0x8(%ebp),%eax
   161d9:	8b 00                	mov    (%eax),%eax
   161db:	83 c0 48             	add    $0x48,%eax
   161de:	8b 40 04             	mov    0x4(%eax),%eax
   161e1:	89 45 f0             	mov    %eax,-0x10(%ebp)
	char *buf = (char *) ARG(pcb,2);
   161e4:	8b 45 08             	mov    0x8(%ebp),%eax
   161e7:	8b 00                	mov    (%eax),%eax
   161e9:	83 c0 48             	add    $0x48,%eax
   161ec:	83 c0 08             	add    $0x8,%eax
   161ef:	8b 00                	mov    (%eax),%eax
   161f1:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint_t length = ARG(pcb,3);
   161f4:	8b 45 08             	mov    0x8(%ebp),%eax
   161f7:	8b 00                	mov    (%eax),%eax
   161f9:	83 c0 48             	add    $0x48,%eax
   161fc:	8b 40 0c             	mov    0xc(%eax),%eax
   161ff:	89 45 e8             	mov    %eax,-0x18(%ebp)

	// this is almost insanely simple, but it does separate the
	// low-level device access fromm the higher-level syscall implementation

	// assume we write the indicated amount
	int rval = length;
   16202:	8b 45 e8             	mov    -0x18(%ebp),%eax
   16205:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// simplest case
	if( length >= 0 ) {

		if( chan == CHAN_CIO ) {
   16208:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   1620c:	75 14                	jne    16222 <sys_write+0xb8>

			cio_write( buf, length );
   1620e:	8b 45 e8             	mov    -0x18(%ebp),%eax
   16211:	83 ec 08             	sub    $0x8,%esp
   16214:	50                   	push   %eax
   16215:	ff 75 ec             	pushl  -0x14(%ebp)
   16218:	e8 c1 ac ff ff       	call   10ede <cio_write>
   1621d:	83 c4 10             	add    $0x10,%esp
   16220:	eb 21                	jmp    16243 <sys_write+0xd9>

		} else if( chan == CHAN_SIO ) {
   16222:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
   16226:	75 14                	jne    1623c <sys_write+0xd2>

			sio_write( buf, length );
   16228:	8b 45 e8             	mov    -0x18(%ebp),%eax
   1622b:	83 ec 08             	sub    $0x8,%esp
   1622e:	50                   	push   %eax
   1622f:	ff 75 ec             	pushl  -0x14(%ebp)
   16232:	e8 36 f0 ff ff       	call   1526d <sio_write>
   16237:	83 c4 10             	add    $0x10,%esp
   1623a:	eb 07                	jmp    16243 <sys_write+0xd9>

		} else {

			rval = E_BAD_CHAN;
   1623c:	c7 45 f4 fd ff ff ff 	movl   $0xfffffffd,-0xc(%ebp)

		}

	}

	RET(pcb) = rval;
   16243:	8b 45 08             	mov    0x8(%ebp),%eax
   16246:	8b 00                	mov    (%eax),%eax
   16248:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1624b:	89 50 30             	mov    %edx,0x30(%eax)

	SYSCALL_EXIT( rval );
   1624e:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16253:	85 c0                	test   %eax,%eax
   16255:	74 1a                	je     16271 <sys_write+0x107>
   16257:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1625a:	83 ec 04             	sub    $0x4,%esp
   1625d:	50                   	push   %eax
   1625e:	68 38 ba 01 00       	push   $0x1ba38
   16263:	68 7b b8 01 00       	push   $0x1b87b
   16268:	e8 ba b2 ff ff       	call   11527 <cio_printf>
   1626d:	83 c4 10             	add    $0x10,%esp
	return;
   16270:	90                   	nop
   16271:	90                   	nop
}
   16272:	c9                   	leave  
   16273:	c3                   	ret    

00016274 <sys_getpid>:
** sys_getpid - returns the PID of the calling process
**
** Implements:
**		uint_t getpid( void );
*/
SYSIMPL(getpid) {
   16274:	55                   	push   %ebp
   16275:	89 e5                	mov    %esp,%ebp
   16277:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   1627a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1627e:	75 3b                	jne    162bb <sys_getpid+0x47>
   16280:	83 ec 04             	sub    $0x4,%esp
   16283:	68 40 b8 01 00       	push   $0x1b840
   16288:	6a 00                	push   $0x0
   1628a:	68 32 02 00 00       	push   $0x232
   1628f:	68 49 b8 01 00       	push   $0x1b849
   16294:	68 44 ba 01 00       	push   $0x1ba44
   16299:	68 54 b8 01 00       	push   $0x1b854
   1629e:	68 00 00 02 00       	push   $0x20000
   162a3:	e8 3f c4 ff ff       	call   126e7 <sprint>
   162a8:	83 c4 20             	add    $0x20,%esp
   162ab:	83 ec 0c             	sub    $0xc,%esp
   162ae:	68 00 00 02 00       	push   $0x20000
   162b3:	e8 af c1 ff ff       	call   12467 <kpanic>
   162b8:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   162bb:	a1 e0 28 02 00       	mov    0x228e0,%eax
   162c0:	85 c0                	test   %eax,%eax
   162c2:	74 1c                	je     162e0 <sys_getpid+0x6c>
   162c4:	8b 45 08             	mov    0x8(%ebp),%eax
   162c7:	8b 40 18             	mov    0x18(%eax),%eax
   162ca:	83 ec 04             	sub    $0x4,%esp
   162cd:	50                   	push   %eax
   162ce:	68 44 ba 01 00       	push   $0x1ba44
   162d3:	68 6a b8 01 00       	push   $0x1b86a
   162d8:	e8 4a b2 ff ff       	call   11527 <cio_printf>
   162dd:	83 c4 10             	add    $0x10,%esp

	// return the time
	RET(pcb) = pcb->pid;
   162e0:	8b 45 08             	mov    0x8(%ebp),%eax
   162e3:	8b 00                	mov    (%eax),%eax
   162e5:	8b 55 08             	mov    0x8(%ebp),%edx
   162e8:	8b 52 18             	mov    0x18(%edx),%edx
   162eb:	89 50 30             	mov    %edx,0x30(%eax)
}
   162ee:	90                   	nop
   162ef:	c9                   	leave  
   162f0:	c3                   	ret    

000162f1 <sys_getppid>:
** sys_getppid - returns the PID of the parent of the calling process
**
** Implements:
**		uint_t getppid( void );
*/
SYSIMPL(getppid) {
   162f1:	55                   	push   %ebp
   162f2:	89 e5                	mov    %esp,%ebp
   162f4:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   162f7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   162fb:	75 3b                	jne    16338 <sys_getppid+0x47>
   162fd:	83 ec 04             	sub    $0x4,%esp
   16300:	68 40 b8 01 00       	push   $0x1b840
   16305:	6a 00                	push   $0x0
   16307:	68 43 02 00 00       	push   $0x243
   1630c:	68 49 b8 01 00       	push   $0x1b849
   16311:	68 50 ba 01 00       	push   $0x1ba50
   16316:	68 54 b8 01 00       	push   $0x1b854
   1631b:	68 00 00 02 00       	push   $0x20000
   16320:	e8 c2 c3 ff ff       	call   126e7 <sprint>
   16325:	83 c4 20             	add    $0x20,%esp
   16328:	83 ec 0c             	sub    $0xc,%esp
   1632b:	68 00 00 02 00       	push   $0x20000
   16330:	e8 32 c1 ff ff       	call   12467 <kpanic>
   16335:	83 c4 10             	add    $0x10,%esp
	assert( pcb->parent != NULL );
   16338:	8b 45 08             	mov    0x8(%ebp),%eax
   1633b:	8b 40 0c             	mov    0xc(%eax),%eax
   1633e:	85 c0                	test   %eax,%eax
   16340:	75 3b                	jne    1637d <sys_getppid+0x8c>
   16342:	83 ec 04             	sub    $0x4,%esp
   16345:	68 cf b8 01 00       	push   $0x1b8cf
   1634a:	6a 00                	push   $0x0
   1634c:	68 44 02 00 00       	push   $0x244
   16351:	68 49 b8 01 00       	push   $0x1b849
   16356:	68 50 ba 01 00       	push   $0x1ba50
   1635b:	68 54 b8 01 00       	push   $0x1b854
   16360:	68 00 00 02 00       	push   $0x20000
   16365:	e8 7d c3 ff ff       	call   126e7 <sprint>
   1636a:	83 c4 20             	add    $0x20,%esp
   1636d:	83 ec 0c             	sub    $0xc,%esp
   16370:	68 00 00 02 00       	push   $0x20000
   16375:	e8 ed c0 ff ff       	call   12467 <kpanic>
   1637a:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   1637d:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16382:	85 c0                	test   %eax,%eax
   16384:	74 1c                	je     163a2 <sys_getppid+0xb1>
   16386:	8b 45 08             	mov    0x8(%ebp),%eax
   16389:	8b 40 18             	mov    0x18(%eax),%eax
   1638c:	83 ec 04             	sub    $0x4,%esp
   1638f:	50                   	push   %eax
   16390:	68 50 ba 01 00       	push   $0x1ba50
   16395:	68 6a b8 01 00       	push   $0x1b86a
   1639a:	e8 88 b1 ff ff       	call   11527 <cio_printf>
   1639f:	83 c4 10             	add    $0x10,%esp

	// return the time
	RET(pcb) = pcb->parent->pid;
   163a2:	8b 45 08             	mov    0x8(%ebp),%eax
   163a5:	8b 50 0c             	mov    0xc(%eax),%edx
   163a8:	8b 45 08             	mov    0x8(%ebp),%eax
   163ab:	8b 00                	mov    (%eax),%eax
   163ad:	8b 52 18             	mov    0x18(%edx),%edx
   163b0:	89 50 30             	mov    %edx,0x30(%eax)
}
   163b3:	90                   	nop
   163b4:	c9                   	leave  
   163b5:	c3                   	ret    

000163b6 <sys_gettime>:
** sys_gettime - returns the current system time
**
** Implements:
**		uint32_t gettime( void );
*/
SYSIMPL(gettime) {
   163b6:	55                   	push   %ebp
   163b7:	89 e5                	mov    %esp,%ebp
   163b9:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   163bc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   163c0:	75 3b                	jne    163fd <sys_gettime+0x47>
   163c2:	83 ec 04             	sub    $0x4,%esp
   163c5:	68 40 b8 01 00       	push   $0x1b840
   163ca:	6a 00                	push   $0x0
   163cc:	68 55 02 00 00       	push   $0x255
   163d1:	68 49 b8 01 00       	push   $0x1b849
   163d6:	68 5c ba 01 00       	push   $0x1ba5c
   163db:	68 54 b8 01 00       	push   $0x1b854
   163e0:	68 00 00 02 00       	push   $0x20000
   163e5:	e8 fd c2 ff ff       	call   126e7 <sprint>
   163ea:	83 c4 20             	add    $0x20,%esp
   163ed:	83 ec 0c             	sub    $0xc,%esp
   163f0:	68 00 00 02 00       	push   $0x20000
   163f5:	e8 6d c0 ff ff       	call   12467 <kpanic>
   163fa:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   163fd:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16402:	85 c0                	test   %eax,%eax
   16404:	74 1c                	je     16422 <sys_gettime+0x6c>
   16406:	8b 45 08             	mov    0x8(%ebp),%eax
   16409:	8b 40 18             	mov    0x18(%eax),%eax
   1640c:	83 ec 04             	sub    $0x4,%esp
   1640f:	50                   	push   %eax
   16410:	68 5c ba 01 00       	push   $0x1ba5c
   16415:	68 6a b8 01 00       	push   $0x1b86a
   1641a:	e8 08 b1 ff ff       	call   11527 <cio_printf>
   1641f:	83 c4 10             	add    $0x10,%esp

	// return the time
	RET(pcb) = system_time;
   16422:	8b 45 08             	mov    0x8(%ebp),%eax
   16425:	8b 00                	mov    (%eax),%eax
   16427:	8b 15 bc f1 01 00    	mov    0x1f1bc,%edx
   1642d:	89 50 30             	mov    %edx,0x30(%eax)
}
   16430:	90                   	nop
   16431:	c9                   	leave  
   16432:	c3                   	ret    

00016433 <sys_getprio>:
** sys_getprio - the scheduling priority of the calling process
**
** Implements:
**		int getprio( void );
*/
SYSIMPL(getprio) {
   16433:	55                   	push   %ebp
   16434:	89 e5                	mov    %esp,%ebp
   16436:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   16439:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1643d:	75 3b                	jne    1647a <sys_getprio+0x47>
   1643f:	83 ec 04             	sub    $0x4,%esp
   16442:	68 40 b8 01 00       	push   $0x1b840
   16447:	6a 00                	push   $0x0
   16449:	68 66 02 00 00       	push   $0x266
   1644e:	68 49 b8 01 00       	push   $0x1b849
   16453:	68 68 ba 01 00       	push   $0x1ba68
   16458:	68 54 b8 01 00       	push   $0x1b854
   1645d:	68 00 00 02 00       	push   $0x20000
   16462:	e8 80 c2 ff ff       	call   126e7 <sprint>
   16467:	83 c4 20             	add    $0x20,%esp
   1646a:	83 ec 0c             	sub    $0xc,%esp
   1646d:	68 00 00 02 00       	push   $0x20000
   16472:	e8 f0 bf ff ff       	call   12467 <kpanic>
   16477:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   1647a:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1647f:	85 c0                	test   %eax,%eax
   16481:	74 1c                	je     1649f <sys_getprio+0x6c>
   16483:	8b 45 08             	mov    0x8(%ebp),%eax
   16486:	8b 40 18             	mov    0x18(%eax),%eax
   16489:	83 ec 04             	sub    $0x4,%esp
   1648c:	50                   	push   %eax
   1648d:	68 68 ba 01 00       	push   $0x1ba68
   16492:	68 6a b8 01 00       	push   $0x1b86a
   16497:	e8 8b b0 ff ff       	call   11527 <cio_printf>
   1649c:	83 c4 10             	add    $0x10,%esp

	// return the time
	RET(pcb) = pcb->priority;
   1649f:	8b 45 08             	mov    0x8(%ebp),%eax
   164a2:	8b 00                	mov    (%eax),%eax
   164a4:	8b 55 08             	mov    0x8(%ebp),%edx
   164a7:	8b 52 20             	mov    0x20(%edx),%edx
   164aa:	89 50 30             	mov    %edx,0x30(%eax)
}
   164ad:	90                   	nop
   164ae:	c9                   	leave  
   164af:	c3                   	ret    

000164b0 <sys_setprio>:
** sys_setprio - sets the scheduling priority of the calling process
**
** Implements:
**		int setprio( int new );
*/
SYSIMPL(setprio) {
   164b0:	55                   	push   %ebp
   164b1:	89 e5                	mov    %esp,%ebp
   164b3:	83 ec 18             	sub    $0x18,%esp

	// sanity check!
	assert( pcb != NULL );
   164b6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   164ba:	75 3b                	jne    164f7 <sys_setprio+0x47>
   164bc:	83 ec 04             	sub    $0x4,%esp
   164bf:	68 40 b8 01 00       	push   $0x1b840
   164c4:	6a 00                	push   $0x0
   164c6:	68 77 02 00 00       	push   $0x277
   164cb:	68 49 b8 01 00       	push   $0x1b849
   164d0:	68 74 ba 01 00       	push   $0x1ba74
   164d5:	68 54 b8 01 00       	push   $0x1b854
   164da:	68 00 00 02 00       	push   $0x20000
   164df:	e8 03 c2 ff ff       	call   126e7 <sprint>
   164e4:	83 c4 20             	add    $0x20,%esp
   164e7:	83 ec 0c             	sub    $0xc,%esp
   164ea:	68 00 00 02 00       	push   $0x20000
   164ef:	e8 73 bf ff ff       	call   12467 <kpanic>
   164f4:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   164f7:	a1 e0 28 02 00       	mov    0x228e0,%eax
   164fc:	85 c0                	test   %eax,%eax
   164fe:	74 1c                	je     1651c <sys_setprio+0x6c>
   16500:	8b 45 08             	mov    0x8(%ebp),%eax
   16503:	8b 40 18             	mov    0x18(%eax),%eax
   16506:	83 ec 04             	sub    $0x4,%esp
   16509:	50                   	push   %eax
   1650a:	68 74 ba 01 00       	push   $0x1ba74
   1650f:	68 6a b8 01 00       	push   $0x1b86a
   16514:	e8 0e b0 ff ff       	call   11527 <cio_printf>
   16519:	83 c4 10             	add    $0x10,%esp

	// remember the old priority
	int old = pcb->priority;
   1651c:	8b 45 08             	mov    0x8(%ebp),%eax
   1651f:	8b 40 20             	mov    0x20(%eax),%eax
   16522:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// set the priority
	pcb->priority = ARG(pcb,1);
   16525:	8b 45 08             	mov    0x8(%ebp),%eax
   16528:	8b 00                	mov    (%eax),%eax
   1652a:	83 c0 48             	add    $0x48,%eax
   1652d:	83 c0 04             	add    $0x4,%eax
   16530:	8b 10                	mov    (%eax),%edx
   16532:	8b 45 08             	mov    0x8(%ebp),%eax
   16535:	89 50 20             	mov    %edx,0x20(%eax)

	// return the old value
	RET(pcb) = old;
   16538:	8b 45 08             	mov    0x8(%ebp),%eax
   1653b:	8b 00                	mov    (%eax),%eax
   1653d:	8b 55 f4             	mov    -0xc(%ebp),%edx
   16540:	89 50 30             	mov    %edx,0x30(%eax)
}
   16543:	90                   	nop
   16544:	c9                   	leave  
   16545:	c3                   	ret    

00016546 <sys_kill>:
**		int32_t kill( uint_t pid );
**
** Marks the specified process (or the calling process, if PID is 0)
** as "killed". Returns 0 on success, else an error code.
*/
SYSIMPL(kill) {
   16546:	55                   	push   %ebp
   16547:	89 e5                	mov    %esp,%ebp
   16549:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   1654c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16550:	75 3b                	jne    1658d <sys_kill+0x47>
   16552:	83 ec 04             	sub    $0x4,%esp
   16555:	68 40 b8 01 00       	push   $0x1b840
   1655a:	6a 00                	push   $0x0
   1655c:	68 91 02 00 00       	push   $0x291
   16561:	68 49 b8 01 00       	push   $0x1b849
   16566:	68 80 ba 01 00       	push   $0x1ba80
   1656b:	68 54 b8 01 00       	push   $0x1b854
   16570:	68 00 00 02 00       	push   $0x20000
   16575:	e8 6d c1 ff ff       	call   126e7 <sprint>
   1657a:	83 c4 20             	add    $0x20,%esp
   1657d:	83 ec 0c             	sub    $0xc,%esp
   16580:	68 00 00 02 00       	push   $0x20000
   16585:	e8 dd be ff ff       	call   12467 <kpanic>
   1658a:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   1658d:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16592:	85 c0                	test   %eax,%eax
   16594:	74 1c                	je     165b2 <sys_kill+0x6c>
   16596:	8b 45 08             	mov    0x8(%ebp),%eax
   16599:	8b 40 18             	mov    0x18(%eax),%eax
   1659c:	83 ec 04             	sub    $0x4,%esp
   1659f:	50                   	push   %eax
   165a0:	68 80 ba 01 00       	push   $0x1ba80
   165a5:	68 6a b8 01 00       	push   $0x1b86a
   165aa:	e8 78 af ff ff       	call   11527 <cio_printf>
   165af:	83 c4 10             	add    $0x10,%esp

	// who is the victim?
	uint_t pid = ARG(pcb,1);
   165b2:	8b 45 08             	mov    0x8(%ebp),%eax
   165b5:	8b 00                	mov    (%eax),%eax
   165b7:	83 c0 48             	add    $0x48,%eax
   165ba:	8b 40 04             	mov    0x4(%eax),%eax
   165bd:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// if it's this process, convert this into a call to exit()
	if( pid == pcb->pid ) {
   165c0:	8b 45 08             	mov    0x8(%ebp),%eax
   165c3:	8b 40 18             	mov    0x18(%eax),%eax
   165c6:	39 45 f0             	cmp    %eax,-0x10(%ebp)
   165c9:	75 50                	jne    1661b <sys_kill+0xd5>
		pcb->exit_status = EXIT_KILLED;
   165cb:	8b 45 08             	mov    0x8(%ebp),%eax
   165ce:	c7 40 14 9b ff ff ff 	movl   $0xffffff9b,0x14(%eax)
		pcb_zombify( pcb );
   165d5:	83 ec 0c             	sub    $0xc,%esp
   165d8:	ff 75 08             	pushl  0x8(%ebp)
   165db:	e8 12 d4 ff ff       	call   139f2 <pcb_zombify>
   165e0:	83 c4 10             	add    $0x10,%esp
		// reset 'current' to keep dispatch() happy
		current = NULL;
   165e3:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   165ea:	00 00 00 
		dispatch();
   165ed:	e8 7e de ff ff       	call   14470 <dispatch>
		SYSCALL_EXIT( EXIT_KILLED );
   165f2:	a1 e0 28 02 00       	mov    0x228e0,%eax
   165f7:	85 c0                	test   %eax,%eax
   165f9:	0f 84 2e 02 00 00    	je     1682d <sys_kill+0x2e7>
   165ff:	83 ec 04             	sub    $0x4,%esp
   16602:	6a 9b                	push   $0xffffff9b
   16604:	68 80 ba 01 00       	push   $0x1ba80
   16609:	68 7b b8 01 00       	push   $0x1b87b
   1660e:	e8 14 af ff ff       	call   11527 <cio_printf>
   16613:	83 c4 10             	add    $0x10,%esp
		return;
   16616:	e9 12 02 00 00       	jmp    1682d <sys_kill+0x2e7>
	}

	// must be a valid "ordinary user" PID
	// QUESTION: what if it's the idle process?
	if( pid < FIRST_USER_PID ) {
   1661b:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
   1661f:	77 35                	ja     16656 <sys_kill+0x110>
		RET(pcb) = E_FAILURE;
   16621:	8b 45 08             	mov    0x8(%ebp),%eax
   16624:	8b 00                	mov    (%eax),%eax
   16626:	c7 40 30 ff ff ff ff 	movl   $0xffffffff,0x30(%eax)
		SYSCALL_EXIT( E_FAILURE );
   1662d:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16632:	85 c0                	test   %eax,%eax
   16634:	0f 84 f6 01 00 00    	je     16830 <sys_kill+0x2ea>
   1663a:	83 ec 04             	sub    $0x4,%esp
   1663d:	6a ff                	push   $0xffffffff
   1663f:	68 80 ba 01 00       	push   $0x1ba80
   16644:	68 7b b8 01 00       	push   $0x1b87b
   16649:	e8 d9 ae ff ff       	call   11527 <cio_printf>
   1664e:	83 c4 10             	add    $0x10,%esp
		return;
   16651:	e9 da 01 00 00       	jmp    16830 <sys_kill+0x2ea>
	}

	// OK, this is an acceptable victim; see if it exists
	pcb_t *victim = pcb_find_pid( pid );
   16656:	83 ec 0c             	sub    $0xc,%esp
   16659:	ff 75 f0             	pushl  -0x10(%ebp)
   1665c:	e8 52 d6 ff ff       	call   13cb3 <pcb_find_pid>
   16661:	83 c4 10             	add    $0x10,%esp
   16664:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if( victim == NULL ) {
   16667:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   1666b:	75 35                	jne    166a2 <sys_kill+0x15c>
		// nope!
		RET(pcb) = E_NOT_FOUND;
   1666d:	8b 45 08             	mov    0x8(%ebp),%eax
   16670:	8b 00                	mov    (%eax),%eax
   16672:	c7 40 30 fa ff ff ff 	movl   $0xfffffffa,0x30(%eax)
		SYSCALL_EXIT( E_NOT_FOUND );
   16679:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1667e:	85 c0                	test   %eax,%eax
   16680:	0f 84 ad 01 00 00    	je     16833 <sys_kill+0x2ed>
   16686:	83 ec 04             	sub    $0x4,%esp
   16689:	6a fa                	push   $0xfffffffa
   1668b:	68 80 ba 01 00       	push   $0x1ba80
   16690:	68 7b b8 01 00       	push   $0x1b87b
   16695:	e8 8d ae ff ff       	call   11527 <cio_printf>
   1669a:	83 c4 10             	add    $0x10,%esp
		return;
   1669d:	e9 91 01 00 00       	jmp    16833 <sys_kill+0x2ed>
	}

	// must have a state that is possible
	assert( victim->state >= FIRST_VIABLE && victim->state < N_STATES );
   166a2:	8b 45 ec             	mov    -0x14(%ebp),%eax
   166a5:	8b 40 1c             	mov    0x1c(%eax),%eax
   166a8:	83 f8 01             	cmp    $0x1,%eax
   166ab:	76 0b                	jbe    166b8 <sys_kill+0x172>
   166ad:	8b 45 ec             	mov    -0x14(%ebp),%eax
   166b0:	8b 40 1c             	mov    0x1c(%eax),%eax
   166b3:	83 f8 08             	cmp    $0x8,%eax
   166b6:	76 3b                	jbe    166f3 <sys_kill+0x1ad>
   166b8:	83 ec 04             	sub    $0x4,%esp
   166bb:	68 e0 b8 01 00       	push   $0x1b8e0
   166c0:	6a 00                	push   $0x0
   166c2:	68 b5 02 00 00       	push   $0x2b5
   166c7:	68 49 b8 01 00       	push   $0x1b849
   166cc:	68 80 ba 01 00       	push   $0x1ba80
   166d1:	68 54 b8 01 00       	push   $0x1b854
   166d6:	68 00 00 02 00       	push   $0x20000
   166db:	e8 07 c0 ff ff       	call   126e7 <sprint>
   166e0:	83 c4 20             	add    $0x20,%esp
   166e3:	83 ec 0c             	sub    $0xc,%esp
   166e6:	68 00 00 02 00       	push   $0x20000
   166eb:	e8 77 bd ff ff       	call   12467 <kpanic>
   166f0:	83 c4 10             	add    $0x10,%esp

	// how we perform the kill depends on the victim's state
	int32_t status = SUCCESS;
   166f3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	switch( victim->state ) {
   166fa:	8b 45 ec             	mov    -0x14(%ebp),%eax
   166fd:	8b 40 1c             	mov    0x1c(%eax),%eax
   16700:	83 f8 08             	cmp    $0x8,%eax
   16703:	0f 87 a4 00 00 00    	ja     167ad <sys_kill+0x267>
   16709:	8b 04 85 48 b9 01 00 	mov    0x1b948(,%eax,4),%eax
   16710:	ff e0                	jmp    *%eax

	case STATE_KILLED:    // FALL THROUGH
	case STATE_ZOMBIE:
		// you can't kill it if it's already dead
		RET(pcb) = SUCCESS;
   16712:	8b 45 08             	mov    0x8(%ebp),%eax
   16715:	8b 00                	mov    (%eax),%eax
   16717:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
		break;
   1671e:	e9 e5 00 00 00       	jmp    16808 <sys_kill+0x2c2>
	case STATE_READY:     // FALL THROUGH
	case STATE_SLEEPING:  // FALL THROUGH
	case STATE_BLOCKED:   // FALL THROUGH
		// here, the process is on a queue somewhere; mark
		// it as "killed", and let the scheduler deal with it
		victim->state = STATE_KILLED;
   16723:	8b 45 ec             	mov    -0x14(%ebp),%eax
   16726:	c7 40 1c 07 00 00 00 	movl   $0x7,0x1c(%eax)
		RET(pcb) = SUCCESS;
   1672d:	8b 45 08             	mov    0x8(%ebp),%eax
   16730:	8b 00                	mov    (%eax),%eax
   16732:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
		break;
   16739:	e9 ca 00 00 00       	jmp    16808 <sys_kill+0x2c2>

	case STATE_RUNNING:
		// we have met the enemy, and it is us!
		pcb->exit_status = EXIT_KILLED;
   1673e:	8b 45 08             	mov    0x8(%ebp),%eax
   16741:	c7 40 14 9b ff ff ff 	movl   $0xffffff9b,0x14(%eax)
		pcb_zombify( pcb );
   16748:	83 ec 0c             	sub    $0xc,%esp
   1674b:	ff 75 08             	pushl  0x8(%ebp)
   1674e:	e8 9f d2 ff ff       	call   139f2 <pcb_zombify>
   16753:	83 c4 10             	add    $0x10,%esp
		status = EXIT_KILLED;
   16756:	c7 45 f4 9b ff ff ff 	movl   $0xffffff9b,-0xc(%ebp)
		// we need a new current process
		// reset 'current' to keep dispatch() happy
		current = NULL;
   1675d:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   16764:	00 00 00 
		dispatch();
   16767:	e8 04 dd ff ff       	call   14470 <dispatch>
		break;
   1676c:	e9 97 00 00 00       	jmp    16808 <sys_kill+0x2c2>

	case STATE_WAITING:
		// similar to the 'running' state, but we don't need
		// to dispatch a new process
		victim->exit_status = EXIT_KILLED;
   16771:	8b 45 ec             	mov    -0x14(%ebp),%eax
   16774:	c7 40 14 9b ff ff ff 	movl   $0xffffff9b,0x14(%eax)
		status = pcb_queue_remove_this( waiting, victim );
   1677b:	a1 10 20 02 00       	mov    0x22010,%eax
   16780:	83 ec 08             	sub    $0x8,%esp
   16783:	ff 75 ec             	pushl  -0x14(%ebp)
   16786:	50                   	push   %eax
   16787:	e8 07 da ff ff       	call   14193 <pcb_queue_remove_this>
   1678c:	83 c4 10             	add    $0x10,%esp
   1678f:	89 45 f4             	mov    %eax,-0xc(%ebp)
		pcb_zombify( victim );
   16792:	83 ec 0c             	sub    $0xc,%esp
   16795:	ff 75 ec             	pushl  -0x14(%ebp)
   16798:	e8 55 d2 ff ff       	call   139f2 <pcb_zombify>
   1679d:	83 c4 10             	add    $0x10,%esp
		RET(pcb) = status;
   167a0:	8b 45 08             	mov    0x8(%ebp),%eax
   167a3:	8b 00                	mov    (%eax),%eax
   167a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
   167a8:	89 50 30             	mov    %edx,0x30(%eax)
		break;
   167ab:	eb 5b                	jmp    16808 <sys_kill+0x2c2>
	default:
		// this is a really bad potential problem - we have an
		// unexpected or bogus process state, but we didn't
		// catch that earlier.
		sprint( b256, "*** kill(): victim %d, odd state %d\n",
				victim->pid, victim->state );
   167ad:	8b 45 ec             	mov    -0x14(%ebp),%eax
   167b0:	8b 50 1c             	mov    0x1c(%eax),%edx
		sprint( b256, "*** kill(): victim %d, odd state %d\n",
   167b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
   167b6:	8b 40 18             	mov    0x18(%eax),%eax
   167b9:	52                   	push   %edx
   167ba:	50                   	push   %eax
   167bb:	68 1c b9 01 00       	push   $0x1b91c
   167c0:	68 00 02 02 00       	push   $0x20200
   167c5:	e8 1d bf ff ff       	call   126e7 <sprint>
   167ca:	83 c4 10             	add    $0x10,%esp
		PANIC( 0, b256 );
   167cd:	83 ec 04             	sub    $0x4,%esp
   167d0:	68 41 b9 01 00       	push   $0x1b941
   167d5:	6a 00                	push   $0x0
   167d7:	68 e5 02 00 00       	push   $0x2e5
   167dc:	68 49 b8 01 00       	push   $0x1b849
   167e1:	68 80 ba 01 00       	push   $0x1ba80
   167e6:	68 54 b8 01 00       	push   $0x1b854
   167eb:	68 00 00 02 00       	push   $0x20000
   167f0:	e8 f2 be ff ff       	call   126e7 <sprint>
   167f5:	83 c4 20             	add    $0x20,%esp
   167f8:	83 ec 0c             	sub    $0xc,%esp
   167fb:	68 00 00 02 00       	push   $0x20000
   16800:	e8 62 bc ff ff       	call   12467 <kpanic>
   16805:	83 c4 10             	add    $0x10,%esp
	}

	SYSCALL_EXIT( status );
   16808:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1680d:	85 c0                	test   %eax,%eax
   1680f:	74 25                	je     16836 <sys_kill+0x2f0>
   16811:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16814:	83 ec 04             	sub    $0x4,%esp
   16817:	50                   	push   %eax
   16818:	68 80 ba 01 00       	push   $0x1ba80
   1681d:	68 7b b8 01 00       	push   $0x1b87b
   16822:	e8 00 ad ff ff       	call   11527 <cio_printf>
   16827:	83 c4 10             	add    $0x10,%esp
	return;
   1682a:	90                   	nop
   1682b:	eb 09                	jmp    16836 <sys_kill+0x2f0>
		return;
   1682d:	90                   	nop
   1682e:	eb 07                	jmp    16837 <sys_kill+0x2f1>
		return;
   16830:	90                   	nop
   16831:	eb 04                	jmp    16837 <sys_kill+0x2f1>
		return;
   16833:	90                   	nop
   16834:	eb 01                	jmp    16837 <sys_kill+0x2f1>
	return;
   16836:	90                   	nop
}
   16837:	c9                   	leave  
   16838:	c3                   	ret    

00016839 <sys_sleep>:
**		uint_t sleep( uint_t ms );
**
** Puts the calling process to sleep for 'ms' milliseconds (or just yields
** the CPU if 'ms' is 0).  ** Returns the time the process spent sleeping.
*/
SYSIMPL(sleep) {
   16839:	55                   	push   %ebp
   1683a:	89 e5                	mov    %esp,%ebp
   1683c:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   1683f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16843:	75 3b                	jne    16880 <sys_sleep+0x47>
   16845:	83 ec 04             	sub    $0x4,%esp
   16848:	68 40 b8 01 00       	push   $0x1b840
   1684d:	6a 00                	push   $0x0
   1684f:	68 f9 02 00 00       	push   $0x2f9
   16854:	68 49 b8 01 00       	push   $0x1b849
   16859:	68 8c ba 01 00       	push   $0x1ba8c
   1685e:	68 54 b8 01 00       	push   $0x1b854
   16863:	68 00 00 02 00       	push   $0x20000
   16868:	e8 7a be ff ff       	call   126e7 <sprint>
   1686d:	83 c4 20             	add    $0x20,%esp
   16870:	83 ec 0c             	sub    $0xc,%esp
   16873:	68 00 00 02 00       	push   $0x20000
   16878:	e8 ea bb ff ff       	call   12467 <kpanic>
   1687d:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   16880:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16885:	85 c0                	test   %eax,%eax
   16887:	74 1c                	je     168a5 <sys_sleep+0x6c>
   16889:	8b 45 08             	mov    0x8(%ebp),%eax
   1688c:	8b 40 18             	mov    0x18(%eax),%eax
   1688f:	83 ec 04             	sub    $0x4,%esp
   16892:	50                   	push   %eax
   16893:	68 8c ba 01 00       	push   $0x1ba8c
   16898:	68 6a b8 01 00       	push   $0x1b86a
   1689d:	e8 85 ac ff ff       	call   11527 <cio_printf>
   168a2:	83 c4 10             	add    $0x10,%esp

	// get the desired duration
	uint_t length = ARG( pcb, 1 );
   168a5:	8b 45 08             	mov    0x8(%ebp),%eax
   168a8:	8b 00                	mov    (%eax),%eax
   168aa:	83 c0 48             	add    $0x48,%eax
   168ad:	8b 40 04             	mov    0x4(%eax),%eax
   168b0:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if( length == 0 ) {
   168b3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   168b7:	75 1c                	jne    168d5 <sys_sleep+0x9c>

		// just yield the CPU
		// sleep duration is 0
		RET(pcb) = 0;
   168b9:	8b 45 08             	mov    0x8(%ebp),%eax
   168bc:	8b 00                	mov    (%eax),%eax
   168be:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)

		// back on the ready queue
		schedule( pcb );
   168c5:	83 ec 0c             	sub    $0xc,%esp
   168c8:	ff 75 08             	pushl  0x8(%ebp)
   168cb:	e8 df da ff ff       	call   143af <schedule>
   168d0:	83 c4 10             	add    $0x10,%esp
   168d3:	eb 7a                	jmp    1694f <sys_sleep+0x116>

	} else {

		// sleep for a while
		pcb->wakeup = system_time + length;
   168d5:	8b 15 bc f1 01 00    	mov    0x1f1bc,%edx
   168db:	8b 45 f4             	mov    -0xc(%ebp),%eax
   168de:	01 c2                	add    %eax,%edx
   168e0:	8b 45 08             	mov    0x8(%ebp),%eax
   168e3:	89 50 10             	mov    %edx,0x10(%eax)

		if( pcb_queue_insert(sleeping,pcb) != SUCCESS ) {
   168e6:	a1 08 20 02 00       	mov    0x22008,%eax
   168eb:	83 ec 08             	sub    $0x8,%esp
   168ee:	ff 75 08             	pushl  0x8(%ebp)
   168f1:	50                   	push   %eax
   168f2:	e8 df d5 ff ff       	call   13ed6 <pcb_queue_insert>
   168f7:	83 c4 10             	add    $0x10,%esp
   168fa:	85 c0                	test   %eax,%eax
   168fc:	74 51                	je     1694f <sys_sleep+0x116>
			// something strange is happening
			WARNING( "sleep pcb insert failed" );
   168fe:	68 10 03 00 00       	push   $0x310
   16903:	68 49 b8 01 00       	push   $0x1b849
   16908:	68 8c ba 01 00       	push   $0x1ba8c
   1690d:	68 6c b9 01 00       	push   $0x1b96c
   16912:	e8 10 ac ff ff       	call   11527 <cio_printf>
   16917:	83 c4 10             	add    $0x10,%esp
   1691a:	83 ec 0c             	sub    $0xc,%esp
   1691d:	68 7f b9 01 00       	push   $0x1b97f
   16922:	e8 86 a5 ff ff       	call   10ead <cio_puts>
   16927:	83 c4 10             	add    $0x10,%esp
   1692a:	83 ec 0c             	sub    $0xc,%esp
   1692d:	6a 0a                	push   $0xa
   1692f:	e8 39 a4 ff ff       	call   10d6d <cio_putchar>
   16934:	83 c4 10             	add    $0x10,%esp
			// if this is the current process, report an error
			if( current == pcb ) {
   16937:	a1 14 20 02 00       	mov    0x22014,%eax
   1693c:	39 45 08             	cmp    %eax,0x8(%ebp)
   1693f:	75 29                	jne    1696a <sys_sleep+0x131>
				RET(pcb) = -1;
   16941:	8b 45 08             	mov    0x8(%ebp),%eax
   16944:	8b 00                	mov    (%eax),%eax
   16946:	c7 40 30 ff ff ff ff 	movl   $0xffffffff,0x30(%eax)
			}
			// return without dispatching a new process
			return;
   1694d:	eb 1b                	jmp    1696a <sys_sleep+0x131>
		}
	}

	// only dispatch if the current process called us
	if( pcb == current ) {
   1694f:	a1 14 20 02 00       	mov    0x22014,%eax
   16954:	39 45 08             	cmp    %eax,0x8(%ebp)
   16957:	75 12                	jne    1696b <sys_sleep+0x132>
		current = NULL;
   16959:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   16960:	00 00 00 
		dispatch();
   16963:	e8 08 db ff ff       	call   14470 <dispatch>
   16968:	eb 01                	jmp    1696b <sys_sleep+0x132>
			return;
   1696a:	90                   	nop
	}
}
   1696b:	c9                   	leave  
   1696c:	c3                   	ret    

0001696d <sys_isr>:
** System call ISR
**
** @param vector   Vector number for this interrupt
** @param code     Error code (0 for this interrupt)
*/
static void sys_isr( int vector, int code ) {
   1696d:	55                   	push   %ebp
   1696e:	89 e5                	mov    %esp,%ebp
   16970:	83 ec 18             	sub    $0x18,%esp
	// keep the compiler happy
	(void) vector;
	(void) code;

	// sanity check!
	assert( current != NULL );
   16973:	a1 14 20 02 00       	mov    0x22014,%eax
   16978:	85 c0                	test   %eax,%eax
   1697a:	75 3b                	jne    169b7 <sys_isr+0x4a>
   1697c:	83 ec 04             	sub    $0x4,%esp
   1697f:	68 d4 b9 01 00       	push   $0x1b9d4
   16984:	6a 00                	push   $0x0
   16986:	68 4d 03 00 00       	push   $0x34d
   1698b:	68 49 b8 01 00       	push   $0x1b849
   16990:	68 98 ba 01 00       	push   $0x1ba98
   16995:	68 54 b8 01 00       	push   $0x1b854
   1699a:	68 00 00 02 00       	push   $0x20000
   1699f:	e8 43 bd ff ff       	call   126e7 <sprint>
   169a4:	83 c4 20             	add    $0x20,%esp
   169a7:	83 ec 0c             	sub    $0xc,%esp
   169aa:	68 00 00 02 00       	push   $0x20000
   169af:	e8 b3 ba ff ff       	call   12467 <kpanic>
   169b4:	83 c4 10             	add    $0x10,%esp
	assert( current->context != NULL );
   169b7:	a1 14 20 02 00       	mov    0x22014,%eax
   169bc:	8b 00                	mov    (%eax),%eax
   169be:	85 c0                	test   %eax,%eax
   169c0:	75 3b                	jne    169fd <sys_isr+0x90>
   169c2:	83 ec 04             	sub    $0x4,%esp
   169c5:	68 e1 b9 01 00       	push   $0x1b9e1
   169ca:	6a 00                	push   $0x0
   169cc:	68 4e 03 00 00       	push   $0x34e
   169d1:	68 49 b8 01 00       	push   $0x1b849
   169d6:	68 98 ba 01 00       	push   $0x1ba98
   169db:	68 54 b8 01 00       	push   $0x1b854
   169e0:	68 00 00 02 00       	push   $0x20000
   169e5:	e8 fd bc ff ff       	call   126e7 <sprint>
   169ea:	83 c4 20             	add    $0x20,%esp
   169ed:	83 ec 0c             	sub    $0xc,%esp
   169f0:	68 00 00 02 00       	push   $0x20000
   169f5:	e8 6d ba ff ff       	call   12467 <kpanic>
   169fa:	83 c4 10             	add    $0x10,%esp

	// retrieve the syscall code
	int num = REG( current, eax );
   169fd:	a1 14 20 02 00       	mov    0x22014,%eax
   16a02:	8b 00                	mov    (%eax),%eax
   16a04:	8b 40 30             	mov    0x30(%eax),%eax
   16a07:	89 45 f4             	mov    %eax,-0xc(%ebp)
#if TRACING_SYSCALLS
	cio_printf( "** --> SYS pid %u code %u\n", current->pid, num );
#endif

	// validate it
	if( num < 0 || num >= N_SYSCALLS ) {
   16a0a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   16a0e:	78 06                	js     16a16 <sys_isr+0xa9>
   16a10:	83 7d f4 0c          	cmpl   $0xc,-0xc(%ebp)
   16a14:	7e 1a                	jle    16a30 <sys_isr+0xc3>
		// bad syscall number
		// could kill it, but we'll just force it to exit
		num = SYS_exit;
   16a16:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
		ARG(current,1) = EXIT_BAD_SYSCALL;
   16a1d:	a1 14 20 02 00       	mov    0x22014,%eax
   16a22:	8b 00                	mov    (%eax),%eax
   16a24:	83 c0 48             	add    $0x48,%eax
   16a27:	83 c0 04             	add    $0x4,%eax
   16a2a:	c7 00 9a ff ff ff    	movl   $0xffffff9a,(%eax)
	}

	// call the handler
	syscalls[num]( current );
   16a30:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16a33:	8b 04 85 a0 b9 01 00 	mov    0x1b9a0(,%eax,4),%eax
   16a3a:	8b 15 14 20 02 00    	mov    0x22014,%edx
   16a40:	83 ec 0c             	sub    $0xc,%esp
   16a43:	52                   	push   %edx
   16a44:	ff d0                	call   *%eax
   16a46:	83 c4 10             	add    $0x10,%esp
   16a49:	c7 45 f0 20 00 00 00 	movl   $0x20,-0x10(%ebp)
   16a50:	c6 45 ef 20          	movb   $0x20,-0x11(%ebp)
   16a54:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
   16a58:	8b 55 f0             	mov    -0x10(%ebp),%edx
   16a5b:	ee                   	out    %al,(%dx)
	cio_printf( "** <-- SYS pid %u ret %u\n", current->pid, RET(current) );
#endif

	// tell the PIC we're done
	outb( PIC1_CMD, PIC_EOI );
}
   16a5c:	90                   	nop
   16a5d:	c9                   	leave  
   16a5e:	c3                   	ret    

00016a5f <sys_init>:
** Syscall module initialization routine
**
** Dependencies:
**    Must be called after cio_init()
*/
void sys_init( void ) {
   16a5f:	55                   	push   %ebp
   16a60:	89 e5                	mov    %esp,%ebp
   16a62:	83 ec 08             	sub    $0x8,%esp

#if TRACING_INIT
	cio_puts( " Sys" );
   16a65:	83 ec 0c             	sub    $0xc,%esp
   16a68:	68 f7 b9 01 00       	push   $0x1b9f7
   16a6d:	e8 3b a4 ff ff       	call   10ead <cio_puts>
   16a72:	83 c4 10             	add    $0x10,%esp
#endif

	// install the second-stage ISR
	install_isr( VEC_SYSCALL, sys_isr );
   16a75:	83 ec 08             	sub    $0x8,%esp
   16a78:	68 6d 69 01 00       	push   $0x1696d
   16a7d:	68 80 00 00 00       	push   $0x80
   16a82:	e8 df ec ff ff       	call   15766 <install_isr>
   16a87:	83 c4 10             	add    $0x10,%esp
}
   16a8a:	90                   	nop
   16a8b:	c9                   	leave  
   16a8c:	c3                   	ret    

00016a8d <stack_setup>:
** @param sys    Is the argument vector from kernel code?
**
** @return A (user VA) pointer to the context_t on the stack, or NULL
*/
context_t *stack_setup( pcb_t *pcb, uint32_t entry,
		const char **args, bool_t sys ) {
   16a8d:	55                   	push   %ebp
   16a8e:	89 e5                	mov    %esp,%ebp
   16a90:	57                   	push   %edi
   16a91:	56                   	push   %esi
   16a92:	53                   	push   %ebx
   16a93:	81 ec cc 00 00 00    	sub    $0xcc,%esp
   16a99:	8b 45 14             	mov    0x14(%ebp),%eax
   16a9c:	88 85 34 ff ff ff    	mov    %al,-0xcc(%ebp)
	**       the remainder of the aggregate shall be initialized
	**       implicitly the same as objects that have static storage
	**       duration."
	*/

	int argbytes = 0;                    // total length of arg strings
   16aa2:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
	int argc = 0;                        // number of argv entries
   16aa9:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
	const char *kv_strs[N_ARGS] = { 0 }; // converted user arg string pointers
   16ab0:	8d 55 88             	lea    -0x78(%ebp),%edx
   16ab3:	b8 00 00 00 00       	mov    $0x0,%eax
   16ab8:	b9 0a 00 00 00       	mov    $0xa,%ecx
   16abd:	89 d7                	mov    %edx,%edi
   16abf:	f3 ab                	rep stos %eax,%es:(%edi)
	int strlengths[N_ARGS] = { 0 };      // length of each string
   16ac1:	8d 95 60 ff ff ff    	lea    -0xa0(%ebp),%edx
   16ac7:	b8 00 00 00 00       	mov    $0x0,%eax
   16acc:	b9 0a 00 00 00       	mov    $0xa,%ecx
   16ad1:	89 d7                	mov    %edx,%edi
   16ad3:	f3 ab                	rep stos %eax,%es:(%edi)
	int uv_offsets[N_ARGS] = { 0 };      // offsets into string buffer
   16ad5:	8d 95 38 ff ff ff    	lea    -0xc8(%ebp),%edx
   16adb:	b8 00 00 00 00       	mov    $0x0,%eax
   16ae0:	b9 0a 00 00 00       	mov    $0xa,%ecx
   16ae5:	89 d7                	mov    %edx,%edi
   16ae7:	f3 ab                	rep stos %eax,%es:(%edi)
	/*
	** IF the argument list given to us came from  user code, we need
	** to convert its address and the addresses it contains to kernel
	** VAs; otherwise, we can use them directly.
	*/
	const char **kv_args = args;
   16ae9:	8b 45 10             	mov    0x10(%ebp),%eax
   16aec:	89 45 cc             	mov    %eax,-0x34(%ebp)

	while( kv_args[argc] != NULL ) {
   16aef:	eb 61                	jmp    16b52 <stack_setup+0xc5>
		kv_strs[argc] = args[argc];
   16af1:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16af4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   16afb:	8b 45 10             	mov    0x10(%ebp),%eax
   16afe:	01 d0                	add    %edx,%eax
   16b00:	8b 10                	mov    (%eax),%edx
   16b02:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b05:	89 54 85 88          	mov    %edx,-0x78(%ebp,%eax,4)
		strlengths[argc] = strlen( kv_strs[argc] ) + 1;
   16b09:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b0c:	8b 44 85 88          	mov    -0x78(%ebp,%eax,4),%eax
   16b10:	83 ec 0c             	sub    $0xc,%esp
   16b13:	50                   	push   %eax
   16b14:	e8 4b bf ff ff       	call   12a64 <strlen>
   16b19:	83 c4 10             	add    $0x10,%esp
   16b1c:	83 c0 01             	add    $0x1,%eax
   16b1f:	89 c2                	mov    %eax,%edx
   16b21:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b24:	89 94 85 60 ff ff ff 	mov    %edx,-0xa0(%ebp,%eax,4)
		// can't go over one page in size
		if( (argbytes + strlengths[argc]) > SZ_PAGE ) {
   16b2b:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b2e:	8b 94 85 60 ff ff ff 	mov    -0xa0(%ebp,%eax,4),%edx
   16b35:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   16b38:	01 d0                	add    %edx,%eax
   16b3a:	3d 00 10 00 00       	cmp    $0x1000,%eax
   16b3f:	7f 28                	jg     16b69 <stack_setup+0xdc>
			// oops - ignore this and any others
			break;
		}
		argbytes += strlengths[argc];
   16b41:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b44:	8b 84 85 60 ff ff ff 	mov    -0xa0(%ebp,%eax,4),%eax
   16b4b:	01 45 d4             	add    %eax,-0x2c(%ebp)
		++argc;
   16b4e:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
	while( kv_args[argc] != NULL ) {
   16b52:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b55:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   16b5c:	8b 45 cc             	mov    -0x34(%ebp),%eax
   16b5f:	01 d0                	add    %edx,%eax
   16b61:	8b 00                	mov    (%eax),%eax
   16b63:	85 c0                	test   %eax,%eax
   16b65:	75 8a                	jne    16af1 <stack_setup+0x64>
   16b67:	eb 01                	jmp    16b6a <stack_setup+0xdd>
			break;
   16b69:	90                   	nop
	}

	// Round up the byte count to the next multiple of four.
	argbytes = (argbytes + 3) & MOD4_MASK;
   16b6a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   16b6d:	83 c0 03             	add    $0x3,%eax
   16b70:	83 e0 fc             	and    $0xfffffffc,%eax
   16b73:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	** We don't know where the argument strings actually live; they
	** could be inside the stack of a process that called exec(), so
	** we can't run the risk of overwriting them. Copy them into our
	** own address space.
	*/
	char argstrings[ argbytes ];
   16b76:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
   16b79:	89 e0                	mov    %esp,%eax
   16b7b:	89 c3                	mov    %eax,%ebx
   16b7d:	8d 41 ff             	lea    -0x1(%ecx),%eax
   16b80:	89 45 c8             	mov    %eax,-0x38(%ebp)
   16b83:	89 ca                	mov    %ecx,%edx
   16b85:	b8 10 00 00 00       	mov    $0x10,%eax
   16b8a:	83 e8 01             	sub    $0x1,%eax
   16b8d:	01 d0                	add    %edx,%eax
   16b8f:	be 10 00 00 00       	mov    $0x10,%esi
   16b94:	ba 00 00 00 00       	mov    $0x0,%edx
   16b99:	f7 f6                	div    %esi
   16b9b:	6b c0 10             	imul   $0x10,%eax,%eax
   16b9e:	29 c4                	sub    %eax,%esp
   16ba0:	89 e0                	mov    %esp,%eax
   16ba2:	83 c0 00             	add    $0x0,%eax
   16ba5:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	CLEAR( argstrings );
   16ba8:	89 ca                	mov    %ecx,%edx
   16baa:	8b 45 c4             	mov    -0x3c(%ebp),%eax
   16bad:	83 ec 08             	sub    $0x8,%esp
   16bb0:	52                   	push   %edx
   16bb1:	50                   	push   %eax
   16bb2:	e8 ad b9 ff ff       	call   12564 <memclr>
   16bb7:	83 c4 10             	add    $0x10,%esp

	char *tmp = argstrings;
   16bba:	8b 45 c4             	mov    -0x3c(%ebp),%eax
   16bbd:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for( int i = 0; i < argc; ++i ) {
   16bc0:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
   16bc7:	eb 3b                	jmp    16c04 <stack_setup+0x177>
		// do the copy
		strcpy( tmp, kv_strs[i] );
   16bc9:	8b 45 e0             	mov    -0x20(%ebp),%eax
   16bcc:	8b 44 85 88          	mov    -0x78(%ebp,%eax,4),%eax
   16bd0:	83 ec 08             	sub    $0x8,%esp
   16bd3:	50                   	push   %eax
   16bd4:	ff 75 dc             	pushl  -0x24(%ebp)
   16bd7:	e8 5e be ff ff       	call   12a3a <strcpy>
   16bdc:	83 c4 10             	add    $0x10,%esp
		// remember where this string begins in the buffer
		uv_offsets[i] = tmp - argstrings;
   16bdf:	8b 45 dc             	mov    -0x24(%ebp),%eax
   16be2:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   16be5:	29 d0                	sub    %edx,%eax
   16be7:	89 c2                	mov    %eax,%edx
   16be9:	8b 45 e0             	mov    -0x20(%ebp),%eax
   16bec:	89 94 85 38 ff ff ff 	mov    %edx,-0xc8(%ebp,%eax,4)
		// move to the next string position
		tmp += strlengths[i];
   16bf3:	8b 45 e0             	mov    -0x20(%ebp),%eax
   16bf6:	8b 84 85 60 ff ff ff 	mov    -0xa0(%ebp,%eax,4),%eax
   16bfd:	01 45 dc             	add    %eax,-0x24(%ebp)
	for( int i = 0; i < argc; ++i ) {
   16c00:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
   16c04:	8b 45 e0             	mov    -0x20(%ebp),%eax
   16c07:	3b 45 d8             	cmp    -0x28(%ebp),%eax
   16c0a:	7c bd                	jl     16bc9 <stack_setup+0x13c>
	** frame is in the first page directory entry. Extract that from the
	** entry and convert it into a virtual address for the kernel to use.
	*/
	// pointer to the first byte after the user stack
	uint32_t *kvptr = (uint32_t *)
		(((uint32_t)(pcb->stack)) + N_USTKPAGES * SZ_PAGE);
   16c0c:	8b 45 08             	mov    0x8(%ebp),%eax
   16c0f:	8b 40 04             	mov    0x4(%eax),%eax
   16c12:	05 00 20 00 00       	add    $0x2000,%eax
	uint32_t *kvptr = (uint32_t *)
   16c17:	89 45 c0             	mov    %eax,-0x40(%ebp)

	// put the buffer longword into the stack
	*--kvptr = 0;
   16c1a:	83 6d c0 04          	subl   $0x4,-0x40(%ebp)
   16c1e:	8b 45 c0             	mov    -0x40(%ebp),%eax
   16c21:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	/*
	** Move these pointers to where the string area will begin. We
	** will then back up to the next lower multiple-of-four address.
	*/
	uint32_t kvstrptr = ((uint32_t) kvptr) - argbytes;
   16c27:	8b 55 c0             	mov    -0x40(%ebp),%edx
   16c2a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   16c2d:	29 c2                	sub    %eax,%edx
   16c2f:	89 d0                	mov    %edx,%eax
   16c31:	89 45 bc             	mov    %eax,-0x44(%ebp)
	kvstrptr &= MOD4_MASK;
   16c34:	83 65 bc fc          	andl   $0xfffffffc,-0x44(%ebp)

	// Copy over the argv strings
	memmove( (void *) kvstrptr, (void *) argstrings, argbytes );
   16c38:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
   16c3b:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   16c3e:	8b 45 bc             	mov    -0x44(%ebp),%eax
   16c41:	83 ec 04             	sub    $0x4,%esp
   16c44:	51                   	push   %ecx
   16c45:	52                   	push   %edx
   16c46:	50                   	push   %eax
   16c47:	e8 66 b9 ff ff       	call   125b2 <memmove>
   16c4c:	83 c4 10             	add    $0x10,%esp
	** The space needed for argc, argv, and the argv array itself is
	** argc + 3 words (argc+1 for the argv entries, plus one word each
	** for argc and argv).  We back up that much from the string area.
	*/

	int nwords = argc + 3;
   16c4f:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16c52:	83 c0 03             	add    $0x3,%eax
   16c55:	89 45 b8             	mov    %eax,-0x48(%ebp)
	uint32_t *kvacptr = ((uint32_t *) kvstrptr) - nwords;
   16c58:	8b 45 b8             	mov    -0x48(%ebp),%eax
   16c5b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   16c62:	8b 45 bc             	mov    -0x44(%ebp),%eax
   16c65:	29 d0                	sub    %edx,%eax
   16c67:	89 45 b4             	mov    %eax,-0x4c(%ebp)

	// back these up to multiple-of-16 addresses for stack alignment
	kvacptr = (uint32_t *) ( ((uint32_t)kvacptr) & MOD16_MASK );
   16c6a:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16c6d:	83 e0 f0             	and    $0xfffffff0,%eax
   16c70:	89 45 b4             	mov    %eax,-0x4c(%ebp)

	// copy in 'argc'
	*kvacptr = argc;
   16c73:	8b 55 d8             	mov    -0x28(%ebp),%edx
   16c76:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16c79:	89 10                	mov    %edx,(%eax)
	cio_printf( "setup: argc '%d' @ %08x,", argc, (uint32_t) kvacptr );
#endif

	// 'argv' immediately follows 'argc', and 'argv[0]' immediately
	// follows 'argv'
	uint32_t *kvavptr = kvacptr + 2;
   16c7b:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16c7e:	83 c0 08             	add    $0x8,%eax
   16c81:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	*(kvavptr-1) = (uint32_t) kvavptr;
   16c84:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16c87:	8d 50 fc             	lea    -0x4(%eax),%edx
   16c8a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16c8d:	89 02                	mov    %eax,(%edx)
	cio_printf( " argv '%08x' @ %08x,", (uint32_t) kvavptr,
			(uint32_t) (kvavptr - 1) );
#endif

	// now, the argv entries themselves
	for( int i = 0; i < argc; ++i ) {
   16c8f:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
   16c96:	eb 20                	jmp    16cb8 <stack_setup+0x22b>
		*kvavptr++ = (uint32_t) (kvstrptr + uv_offsets[i]);
   16c98:	8b 45 d0             	mov    -0x30(%ebp),%eax
   16c9b:	8b 84 85 38 ff ff ff 	mov    -0xc8(%ebp,%eax,4),%eax
   16ca2:	89 c1                	mov    %eax,%ecx
   16ca4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16ca7:	8d 50 04             	lea    0x4(%eax),%edx
   16caa:	89 55 e4             	mov    %edx,-0x1c(%ebp)
   16cad:	8b 55 bc             	mov    -0x44(%ebp),%edx
   16cb0:	01 ca                	add    %ecx,%edx
   16cb2:	89 10                	mov    %edx,(%eax)
	for( int i = 0; i < argc; ++i ) {
   16cb4:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
   16cb8:	8b 45 d0             	mov    -0x30(%ebp),%eax
   16cbb:	3b 45 d8             	cmp    -0x28(%ebp),%eax
   16cbe:	7c d8                	jl     16c98 <stack_setup+0x20b>
		(uint32_t) (kvavptr-1) );
#endif
	}

	// and the trailing NULL
	*kvavptr = NULL;
   16cc0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16cc3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#if TRACING_STACK
	cio_printf( " NULL @ %08x,", (uint32_t) kvavptr );
#endif

	// push the fake return address right above 'argc' on the stack
	*--kvacptr = (uint32_t) fake_exit;
   16cc9:	83 6d b4 04          	subl   $0x4,-0x4c(%ebp)
   16ccd:	ba 78 6f 01 00       	mov    $0x16f78,%edx
   16cd2:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16cd5:	89 10                	mov    %edx,(%eax)
	** the interrupt "returns" to the entry point of the process.
	*/

	// Locate the context save area on the stack by backup up one
	// "context" from where the argc value is saved
	context_t *kvctx = ((context_t *) kvacptr) - 1;
   16cd7:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16cda:	83 e8 48             	sub    $0x48,%eax
   16cdd:	89 45 b0             	mov    %eax,-0x50(%ebp)
	** as the 'popa' that restores the general registers doesn't
	** actually restore ESP from the context area - it leaves it
	** where it winds up.
	*/

	kvctx->eflags = DEFAULT_EFLAGS;    // IF enabled, IOPL 0
   16ce0:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16ce3:	c7 40 44 02 02 00 00 	movl   $0x202,0x44(%eax)
	kvctx->eip = entry;                // initial EIP
   16cea:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16ced:	8b 55 0c             	mov    0xc(%ebp),%edx
   16cf0:	89 50 3c             	mov    %edx,0x3c(%eax)
	kvctx->cs = GDT_CODE;              // segment registers
   16cf3:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16cf6:	c7 40 40 10 00 00 00 	movl   $0x10,0x40(%eax)
	kvctx->ss = GDT_STACK;
   16cfd:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d00:	c7 00 20 00 00 00    	movl   $0x20,(%eax)
	kvctx->ds = kvctx->es = kvctx->fs = kvctx->gs = GDT_DATA;
   16d06:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d09:	c7 40 04 18 00 00 00 	movl   $0x18,0x4(%eax)
   16d10:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d13:	8b 50 04             	mov    0x4(%eax),%edx
   16d16:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d19:	89 50 08             	mov    %edx,0x8(%eax)
   16d1c:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d1f:	8b 50 08             	mov    0x8(%eax),%edx
   16d22:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d25:	89 50 0c             	mov    %edx,0xc(%eax)
   16d28:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d2b:	8b 50 0c             	mov    0xc(%eax),%edx
   16d2e:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d31:	89 50 10             	mov    %edx,0x10(%eax)
	/*
	** Return the new context pointer to the caller as a user
	** space virtual address.
	*/
	
	return kvctx;
   16d34:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d37:	89 dc                	mov    %ebx,%esp
}
   16d39:	8d 65 f4             	lea    -0xc(%ebp),%esp
   16d3c:	5b                   	pop    %ebx
   16d3d:	5e                   	pop    %esi
   16d3e:	5f                   	pop    %edi
   16d3f:	5d                   	pop    %ebp
   16d40:	c3                   	ret    

00016d41 <user_init>:
/**
** Name:	user_init
**
** Initializes the user support module.
*/
void user_init( void ) {
   16d41:	55                   	push   %ebp
   16d42:	89 e5                	mov    %esp,%ebp
   16d44:	83 ec 08             	sub    $0x8,%esp

#if TRACING_INIT
	cio_puts( " User" );
   16d47:	83 ec 0c             	sub    $0xc,%esp
   16d4a:	68 a0 ba 01 00       	push   $0x1baa0
   16d4f:	e8 59 a1 ff ff       	call   10ead <cio_puts>
   16d54:	83 c4 10             	add    $0x10,%esp
#endif 

	// really not much to do here any more....
}
   16d57:	90                   	nop
   16d58:	c9                   	leave  
   16d59:	c3                   	ret    

00016d5a <user_cleanup>:
** "Unloads" a user program. Deallocates all memory frames and
** cleans up the VM structures.
**
** @param pcb   The PCB of the program to be unloaded
*/
void user_cleanup( pcb_t *pcb ) {
   16d5a:	55                   	push   %ebp
   16d5b:	89 e5                	mov    %esp,%ebp
   16d5d:	83 ec 08             	sub    $0x8,%esp

#if TRACING_USER
	cio_printf( "Uclean: %08x\n", (uint32_t) pcb );
#endif
	
	if( pcb == NULL ) {
   16d60:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16d64:	74 1b                	je     16d81 <user_cleanup+0x27>
		// should this be an error?
		return;
	}

	// free the stack pages
	pcb_stack_free( pcb->stack, pcb->stkpgs );
   16d66:	8b 45 08             	mov    0x8(%ebp),%eax
   16d69:	8b 50 28             	mov    0x28(%eax),%edx
   16d6c:	8b 45 08             	mov    0x8(%ebp),%eax
   16d6f:	8b 40 04             	mov    0x4(%eax),%eax
   16d72:	83 ec 08             	sub    $0x8,%esp
   16d75:	52                   	push   %edx
   16d76:	50                   	push   %eax
   16d77:	e8 0e cc ff ff       	call   1398a <pcb_stack_free>
   16d7c:	83 c4 10             	add    $0x10,%esp
   16d7f:	eb 01                	jmp    16d82 <user_cleanup+0x28>
		return;
   16d81:	90                   	nop
}
   16d82:	c9                   	leave  
   16d83:	c3                   	ret    

00016d84 <pci_read_config>:
#include "drivers/intel_8255x.h"
#include <common.h>
#include <types.h>
#include <x86/ops.h>

static uint32_t pci_read_config(int bus, int device, int func, int offset) {
   16d84:	55                   	push   %ebp
   16d85:	89 e5                	mov    %esp,%ebp
   16d87:	83 ec 20             	sub    $0x20,%esp
  uint32_t address =
      (1 << 31)          /* Enable bit */
      | (bus << 16)      /* Bus number */
   16d8a:	8b 45 08             	mov    0x8(%ebp),%eax
   16d8d:	c1 e0 10             	shl    $0x10,%eax
   16d90:	0d 00 00 00 80       	or     $0x80000000,%eax
   16d95:	89 c2                	mov    %eax,%edx
      | (device << 11)   /* Device number */
   16d97:	8b 45 0c             	mov    0xc(%ebp),%eax
   16d9a:	c1 e0 0b             	shl    $0xb,%eax
   16d9d:	09 c2                	or     %eax,%edx
      | (func << 8)      /* Function number */
   16d9f:	8b 45 10             	mov    0x10(%ebp),%eax
   16da2:	c1 e0 08             	shl    $0x8,%eax
   16da5:	09 c2                	or     %eax,%edx
      | (offset & 0xFC); /* Register number (must be 4-byte aligned) */
   16da7:	8b 45 14             	mov    0x14(%ebp),%eax
   16daa:	25 fc 00 00 00       	and    $0xfc,%eax
   16daf:	09 d0                	or     %edx,%eax
  uint32_t address =
   16db1:	89 45 fc             	mov    %eax,-0x4(%ebp)
   16db4:	c7 45 f0 f8 0c 00 00 	movl   $0xcf8,-0x10(%ebp)
   16dbb:	8b 45 fc             	mov    -0x4(%ebp),%eax
   16dbe:	89 45 ec             	mov    %eax,-0x14(%ebp)
}

OPSINLINED static inline void
outl( int port, uint32_t data )
{
	__asm__ __volatile__( "outl %0,%w1" : : "a" (data), "d" (port) );
   16dc1:	8b 45 ec             	mov    -0x14(%ebp),%eax
   16dc4:	8b 55 f0             	mov    -0x10(%ebp),%edx
   16dc7:	ef                   	out    %eax,(%dx)
   16dc8:	c7 45 f8 fc 0c 00 00 	movl   $0xcfc,-0x8(%ebp)
	__asm__ __volatile__( "inl %w1,%0" : "=a" (data) : "d" (port) );
   16dcf:	8b 45 f8             	mov    -0x8(%ebp),%eax
   16dd2:	89 c2                	mov    %eax,%edx
   16dd4:	ed                   	in     (%dx),%eax
   16dd5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return data;
   16dd8:	8b 45 f4             	mov    -0xc(%ebp),%eax

  outl(0xCF8, address); /* Write address to PCI config space */
  return inl(0xCFC);    /* Read data from PCI config space */
   16ddb:	90                   	nop
}
   16ddc:	c9                   	leave  
   16ddd:	c3                   	ret    

00016dde <detect_intel_8255x>:

int detect_intel_8255x() {
   16dde:	55                   	push   %ebp
   16ddf:	89 e5                	mov    %esp,%ebp
   16de1:	83 ec 38             	sub    $0x38,%esp
  int bus;
  int dev;
  int func;
  uint32_t val;
  int found = 0;
   16de4:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  /* Set up the function pointers */
  // e100_state.dev.read = xv6_read;
  // e100_state.dev.write = xv6_write;

  /* Search PCI bus for Intel 8255x device */
  for (bus = 0; bus < 256 && !found; bus++) {
   16deb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   16df2:	e9 ef 00 00 00       	jmp    16ee6 <detect_intel_8255x+0x108>
    for (dev = 0; dev < 32 && !found; dev++) {
   16df7:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   16dfe:	e9 cf 00 00 00       	jmp    16ed2 <detect_intel_8255x+0xf4>
      for (func = 0; func < 8 && !found; func++) {
   16e03:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   16e0a:	e9 af 00 00 00       	jmp    16ebe <detect_intel_8255x+0xe0>
        val = pci_read_config(bus, dev, func, 0);
   16e0f:	6a 00                	push   $0x0
   16e11:	ff 75 ec             	pushl  -0x14(%ebp)
   16e14:	ff 75 f0             	pushl  -0x10(%ebp)
   16e17:	ff 75 f4             	pushl  -0xc(%ebp)
   16e1a:	e8 65 ff ff ff       	call   16d84 <pci_read_config>
   16e1f:	83 c4 10             	add    $0x10,%esp
   16e22:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        if ((val & 0xFFFF) == 0x8086) { /* Intel vendor ID */
   16e25:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16e28:	0f b7 c0             	movzwl %ax,%eax
   16e2b:	3d 86 80 00 00       	cmp    $0x8086,%eax
   16e30:	0f 85 84 00 00 00    	jne    16eba <detect_intel_8255x+0xdc>
          uint16_t device_id = (val >> 16) & 0xFFFF;
   16e36:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16e39:	c1 e8 10             	shr    $0x10,%eax
   16e3c:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)

          if (device_id == 0x1227 || /* 82557 */
   16e40:	66 81 7d e2 27 12    	cmpw   $0x1227,-0x1e(%ebp)
   16e46:	74 08                	je     16e50 <detect_intel_8255x+0x72>
   16e48:	66 81 7d e2 29 12    	cmpw   $0x1229,-0x1e(%ebp)
   16e4e:	75 6a                	jne    16eba <detect_intel_8255x+0xdc>
              device_id == 0x1229) { /* 82559 */

            cio_printf(
   16e50:	ff 75 ec             	pushl  -0x14(%ebp)
   16e53:	ff 75 f0             	pushl  -0x10(%ebp)
   16e56:	ff 75 f4             	pushl  -0xc(%ebp)
   16e59:	68 a8 ba 01 00       	push   $0x1baa8
   16e5e:	e8 c4 a6 ff ff       	call   11527 <cio_printf>
   16e63:	83 c4 10             	add    $0x10,%esp
                "e100: found Intel 8255x at bus %d, device %d, function %d\n",
                bus, dev, func);

            // Get I/O base address
            uint32_t io_bar = pci_read_config(bus, dev, func, 0x10);
   16e66:	6a 10                	push   $0x10
   16e68:	ff 75 ec             	pushl  -0x14(%ebp)
   16e6b:	ff 75 f0             	pushl  -0x10(%ebp)
   16e6e:	ff 75 f4             	pushl  -0xc(%ebp)
   16e71:	e8 0e ff ff ff       	call   16d84 <pci_read_config>
   16e76:	83 c4 10             	add    $0x10,%esp
   16e79:	89 45 dc             	mov    %eax,-0x24(%ebp)
            uint32_t io_base = io_bar & ~0x3; /* Mask off the low bits */
   16e7c:	8b 45 dc             	mov    -0x24(%ebp),%eax
   16e7f:	83 e0 fc             	and    $0xfffffffc,%eax
   16e82:	89 45 d8             	mov    %eax,-0x28(%ebp)

            // Get interrupt line
            uint8_t irq = pci_read_config(bus, dev, func, 0x3C) & 0xFF;
   16e85:	6a 3c                	push   $0x3c
   16e87:	ff 75 ec             	pushl  -0x14(%ebp)
   16e8a:	ff 75 f0             	pushl  -0x10(%ebp)
   16e8d:	ff 75 f4             	pushl  -0xc(%ebp)
   16e90:	e8 ef fe ff ff       	call   16d84 <pci_read_config>
   16e95:	83 c4 10             	add    $0x10,%esp
   16e98:	88 45 d7             	mov    %al,-0x29(%ebp)

            cio_printf("e100: I/O base = 0x%x, IRQ = %d\n", io_base, irq);
   16e9b:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
   16e9f:	83 ec 04             	sub    $0x4,%esp
   16ea2:	50                   	push   %eax
   16ea3:	ff 75 d8             	pushl  -0x28(%ebp)
   16ea6:	68 e4 ba 01 00       	push   $0x1bae4
   16eab:	e8 77 a6 ff ff       	call   11527 <cio_printf>
   16eb0:	83 c4 10             	add    $0x10,%esp

            return 0;
   16eb3:	b8 00 00 00 00       	mov    $0x0,%eax
   16eb8:	eb 3f                	jmp    16ef9 <detect_intel_8255x+0x11b>
      for (func = 0; func < 8 && !found; func++) {
   16eba:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   16ebe:	83 7d ec 07          	cmpl   $0x7,-0x14(%ebp)
   16ec2:	7f 0a                	jg     16ece <detect_intel_8255x+0xf0>
   16ec4:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   16ec8:	0f 84 41 ff ff ff    	je     16e0f <detect_intel_8255x+0x31>
    for (dev = 0; dev < 32 && !found; dev++) {
   16ece:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   16ed2:	83 7d f0 1f          	cmpl   $0x1f,-0x10(%ebp)
   16ed6:	7f 0a                	jg     16ee2 <detect_intel_8255x+0x104>
   16ed8:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   16edc:	0f 84 21 ff ff ff    	je     16e03 <detect_intel_8255x+0x25>
  for (bus = 0; bus < 256 && !found; bus++) {
   16ee2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   16ee6:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
   16eed:	7f 0a                	jg     16ef9 <detect_intel_8255x+0x11b>
   16eef:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   16ef3:	0f 84 fe fe ff ff    	je     16df7 <detect_intel_8255x+0x19>
          }
        }
      }
    }
  }
}
   16ef9:	c9                   	leave  
   16efa:	c3                   	ret    

00016efb <intel_8255x_init>:

int intel_8255x_init(void) { return detect_intel_8255x(); }
   16efb:	55                   	push   %ebp
   16efc:	89 e5                	mov    %esp,%ebp
   16efe:	83 ec 08             	sub    $0x8,%esp
   16f01:	e8 d8 fe ff ff       	call   16dde <detect_intel_8255x>
   16f06:	c9                   	leave  
   16f07:	c3                   	ret    

00016f08 <exit>:

/*
** "real" system calls
*/

SYSCALL(exit)
   16f08:	b8 00 00 00 00       	mov    $0x0,%eax
   16f0d:	cd 80                	int    $0x80
   16f0f:	c3                   	ret    

00016f10 <waitpid>:
SYSCALL(waitpid)
   16f10:	b8 01 00 00 00       	mov    $0x1,%eax
   16f15:	cd 80                	int    $0x80
   16f17:	c3                   	ret    

00016f18 <fork>:
SYSCALL(fork)
   16f18:	b8 02 00 00 00       	mov    $0x2,%eax
   16f1d:	cd 80                	int    $0x80
   16f1f:	c3                   	ret    

00016f20 <exec>:
SYSCALL(exec)
   16f20:	b8 03 00 00 00       	mov    $0x3,%eax
   16f25:	cd 80                	int    $0x80
   16f27:	c3                   	ret    

00016f28 <read>:
SYSCALL(read)
   16f28:	b8 04 00 00 00       	mov    $0x4,%eax
   16f2d:	cd 80                	int    $0x80
   16f2f:	c3                   	ret    

00016f30 <write>:
SYSCALL(write)
   16f30:	b8 05 00 00 00       	mov    $0x5,%eax
   16f35:	cd 80                	int    $0x80
   16f37:	c3                   	ret    

00016f38 <getpid>:
SYSCALL(getpid)
   16f38:	b8 06 00 00 00       	mov    $0x6,%eax
   16f3d:	cd 80                	int    $0x80
   16f3f:	c3                   	ret    

00016f40 <getppid>:
SYSCALL(getppid)
   16f40:	b8 07 00 00 00       	mov    $0x7,%eax
   16f45:	cd 80                	int    $0x80
   16f47:	c3                   	ret    

00016f48 <gettime>:
SYSCALL(gettime)
   16f48:	b8 08 00 00 00       	mov    $0x8,%eax
   16f4d:	cd 80                	int    $0x80
   16f4f:	c3                   	ret    

00016f50 <getprio>:
SYSCALL(getprio)
   16f50:	b8 09 00 00 00       	mov    $0x9,%eax
   16f55:	cd 80                	int    $0x80
   16f57:	c3                   	ret    

00016f58 <setprio>:
SYSCALL(setprio)
   16f58:	b8 0a 00 00 00       	mov    $0xa,%eax
   16f5d:	cd 80                	int    $0x80
   16f5f:	c3                   	ret    

00016f60 <kill>:
SYSCALL(kill)
   16f60:	b8 0b 00 00 00       	mov    $0xb,%eax
   16f65:	cd 80                	int    $0x80
   16f67:	c3                   	ret    

00016f68 <sleep>:
SYSCALL(sleep)
   16f68:	b8 0c 00 00 00       	mov    $0xc,%eax
   16f6d:	cd 80                	int    $0x80
   16f6f:	c3                   	ret    

00016f70 <bogus>:

/*
** This is a bogus system call; it's here so that we can test
** our handling of out-of-range syscall codes in the syscall ISR.
*/
SYSCALL(bogus)
   16f70:	b8 ad 0b 00 00       	mov    $0xbad,%eax
   16f75:	cd 80                	int    $0x80
   16f77:	c3                   	ret    

00016f78 <fake_exit>:
*/

	.globl	fake_exit
fake_exit:
	// alternate: could push a "fake exit" status
	pushl	%eax	// termination status returned by main()
   16f78:	50                   	push   %eax
	call	exit	// terminate this process
   16f79:	e8 8a ff ff ff       	call   16f08 <exit>

00016f7e <idle>:
** when there is no other process to dispatch.
**
** Invoked as:	idle
*/

USERMAIN( idle ) {
   16f7e:	55                   	push   %ebp
   16f7f:	89 e5                	mov    %esp,%ebp
   16f81:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char ch = '.';
#endif

	// ignore the command-line arguments
	(void) argc;
	char *name = argv[0] ? argv[0] : "nobody";
   16f87:	8b 45 0c             	mov    0xc(%ebp),%eax
   16f8a:	8b 00                	mov    (%eax),%eax
   16f8c:	85 c0                	test   %eax,%eax
   16f8e:	74 07                	je     16f97 <idle+0x19>
   16f90:	8b 45 0c             	mov    0xc(%ebp),%eax
   16f93:	8b 00                	mov    (%eax),%eax
   16f95:	eb 05                	jmp    16f9c <idle+0x1e>
   16f97:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   16f9c:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// get some current information
	uint_t pid = getpid();
   16f9f:	e8 94 ff ff ff       	call   16f38 <getpid>
   16fa4:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32_t now = gettime();
   16fa7:	e8 9c ff ff ff       	call   16f48 <gettime>
   16fac:	89 45 e8             	mov    %eax,-0x18(%ebp)
	enum priority_e prio = getprio();
   16faf:	e8 9c ff ff ff       	call   16f50 <getprio>
   16fb4:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	char buf[128];
	usprint( buf, "%s [%d], started @ %u\n", name, pid, prio, now );
   16fb7:	83 ec 08             	sub    $0x8,%esp
   16fba:	ff 75 e8             	pushl  -0x18(%ebp)
   16fbd:	ff 75 e4             	pushl  -0x1c(%ebp)
   16fc0:	ff 75 ec             	pushl  -0x14(%ebp)
   16fc3:	ff 75 f0             	pushl  -0x10(%ebp)
   16fc6:	68 0f bb 01 00       	push   $0x1bb0f
   16fcb:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
   16fd1:	50                   	push   %eax
   16fd2:	e8 db 2c 00 00       	call   19cb2 <usprint>
   16fd7:	83 c4 20             	add    $0x20,%esp
	cwrites( buf );
   16fda:	83 ec 0c             	sub    $0xc,%esp
   16fdd:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
   16fe3:	50                   	push   %eax
   16fe4:	e8 b6 33 00 00       	call   1a39f <cwrites>
   16fe9:	83 c4 10             	add    $0x10,%esp

	// idle() should never block - it must always be available
	// for dispatching when we need to pick a new current process

	for(;;) {
		DELAY(LONG);
   16fec:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   16ff3:	eb 04                	jmp    16ff9 <idle+0x7b>
   16ff5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   16ff9:	81 7d f4 ff e0 f5 05 	cmpl   $0x5f5e0ff,-0xc(%ebp)
   17000:	7e f3                	jle    16ff5 <idle+0x77>
   17002:	eb e8                	jmp    16fec <idle+0x6e>

00017004 <usage>:
};

/*
** usage function
*/
static void usage( void ) {
   17004:	55                   	push   %ebp
   17005:	89 e5                	mov    %esp,%ebp
   17007:	83 ec 18             	sub    $0x18,%esp
	swrites( "\nTests - run with '@x', where 'x' is one or more of:\n " );
   1700a:	83 ec 0c             	sub    $0xc,%esp
   1700d:	68 f4 bb 01 00       	push   $0x1bbf4
   17012:	e8 ee 33 00 00       	call   1a405 <swrites>
   17017:	83 c4 10             	add    $0x10,%esp
	proc_t *p = sh_spawn_table;
   1701a:	c7 45 f4 20 d1 01 00 	movl   $0x1d120,-0xc(%ebp)
	while( p->entry != TBLEND ) {
   17021:	eb 23                	jmp    17046 <usage+0x42>
		swritech( ' ' );
   17023:	83 ec 0c             	sub    $0xc,%esp
   17026:	6a 20                	push   $0x20
   17028:	e8 b7 33 00 00       	call   1a3e4 <swritech>
   1702d:	83 c4 10             	add    $0x10,%esp
		swritech( p->select[0] );
   17030:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17033:	0f b6 40 09          	movzbl 0x9(%eax),%eax
   17037:	0f be c0             	movsbl %al,%eax
   1703a:	83 ec 0c             	sub    $0xc,%esp
   1703d:	50                   	push   %eax
   1703e:	e8 a1 33 00 00       	call   1a3e4 <swritech>
   17043:	83 c4 10             	add    $0x10,%esp
	while( p->entry != TBLEND ) {
   17046:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17049:	8b 00                	mov    (%eax),%eax
   1704b:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   17050:	75 d1                	jne    17023 <usage+0x1f>
	}
	swrites( "\nOther commands: @* (all), @h (help), @x (exit)\n" );
   17052:	83 ec 0c             	sub    $0xc,%esp
   17055:	68 2c bc 01 00       	push   $0x1bc2c
   1705a:	e8 a6 33 00 00       	call   1a405 <swrites>
   1705f:	83 c4 10             	add    $0x10,%esp
}
   17062:	90                   	nop
   17063:	c9                   	leave  
   17064:	c3                   	ret    

00017065 <run>:

/*
** run a program from the program table, or a builtin command
*/
static int run( char which ) {
   17065:	55                   	push   %ebp
   17066:	89 e5                	mov    %esp,%ebp
   17068:	53                   	push   %ebx
   17069:	81 ec a4 00 00 00    	sub    $0xa4,%esp
   1706f:	8b 45 08             	mov    0x8(%ebp),%eax
   17072:	88 85 64 ff ff ff    	mov    %al,-0x9c(%ebp)
	char buf[128];
	register proc_t *p;

	if( which == 'h' ) {
   17078:	80 bd 64 ff ff ff 68 	cmpb   $0x68,-0x9c(%ebp)
   1707f:	75 0a                	jne    1708b <run+0x26>

		// builtin "help" command
		usage();
   17081:	e8 7e ff ff ff       	call   17004 <usage>
   17086:	e9 e0 00 00 00       	jmp    1716b <run+0x106>

	} else if( which == 'x' ) {
   1708b:	80 bd 64 ff ff ff 78 	cmpb   $0x78,-0x9c(%ebp)
   17092:	75 0c                	jne    170a0 <run+0x3b>

		// builtin "exit" command
		time_to_stop = true;
   17094:	c6 05 b4 f1 01 00 01 	movb   $0x1,0x1f1b4
   1709b:	e9 cb 00 00 00       	jmp    1716b <run+0x106>

	} else if( which == '*' ) {
   170a0:	80 bd 64 ff ff ff 2a 	cmpb   $0x2a,-0x9c(%ebp)
   170a7:	75 40                	jne    170e9 <run+0x84>

		// torture test! run everything!
		for( p = sh_spawn_table; p->entry != TBLEND; ++p ) {
   170a9:	bb 20 d1 01 00       	mov    $0x1d120,%ebx
   170ae:	eb 2b                	jmp    170db <run+0x76>
			int status = spawn( p->entry, p->args );
   170b0:	8d 53 0c             	lea    0xc(%ebx),%edx
   170b3:	8b 03                	mov    (%ebx),%eax
   170b5:	83 ec 08             	sub    $0x8,%esp
   170b8:	52                   	push   %edx
   170b9:	50                   	push   %eax
   170ba:	e8 4a 32 00 00       	call   1a309 <spawn>
   170bf:	83 c4 10             	add    $0x10,%esp
   170c2:	89 45 f0             	mov    %eax,-0x10(%ebp)
			if( status > 0 ) {
   170c5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   170c9:	7e 0d                	jle    170d8 <run+0x73>
				++children;
   170cb:	a1 b8 f1 01 00       	mov    0x1f1b8,%eax
   170d0:	83 c0 01             	add    $0x1,%eax
   170d3:	a3 b8 f1 01 00       	mov    %eax,0x1f1b8
		for( p = sh_spawn_table; p->entry != TBLEND; ++p ) {
   170d8:	83 c3 34             	add    $0x34,%ebx
   170db:	8b 03                	mov    (%ebx),%eax
   170dd:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   170e2:	75 cc                	jne    170b0 <run+0x4b>
   170e4:	e9 82 00 00 00       	jmp    1716b <run+0x106>
		}

	} else {

		// must be a single test; find and run it
		for( p = sh_spawn_table; p->entry != TBLEND; ++p ) {
   170e9:	bb 20 d1 01 00       	mov    $0x1d120,%ebx
   170ee:	eb 3c                	jmp    1712c <run+0xc7>
			if( p->select[0] == which ) {
   170f0:	0f b6 43 09          	movzbl 0x9(%ebx),%eax
   170f4:	38 85 64 ff ff ff    	cmp    %al,-0x9c(%ebp)
   170fa:	75 2d                	jne    17129 <run+0xc4>
				// found it!
				int status = spawn( p->entry, p->args );
   170fc:	8d 53 0c             	lea    0xc(%ebx),%edx
   170ff:	8b 03                	mov    (%ebx),%eax
   17101:	83 ec 08             	sub    $0x8,%esp
   17104:	52                   	push   %edx
   17105:	50                   	push   %eax
   17106:	e8 fe 31 00 00       	call   1a309 <spawn>
   1710b:	83 c4 10             	add    $0x10,%esp
   1710e:	89 45 f4             	mov    %eax,-0xc(%ebp)
				if( status > 0 ) {
   17111:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   17115:	7e 0d                	jle    17124 <run+0xbf>
					++children;
   17117:	a1 b8 f1 01 00       	mov    0x1f1b8,%eax
   1711c:	83 c0 01             	add    $0x1,%eax
   1711f:	a3 b8 f1 01 00       	mov    %eax,0x1f1b8
				}
				return status;
   17124:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17127:	eb 47                	jmp    17170 <run+0x10b>
		for( p = sh_spawn_table; p->entry != TBLEND; ++p ) {
   17129:	83 c3 34             	add    $0x34,%ebx
   1712c:	8b 03                	mov    (%ebx),%eax
   1712e:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   17133:	75 bb                	jne    170f0 <run+0x8b>
			}
		}

		// uh-oh, made it through the table without finding the program
		usprint( buf, "shell: unknown cmd '%c'\n", which );
   17135:	0f be 85 64 ff ff ff 	movsbl -0x9c(%ebp),%eax
   1713c:	83 ec 04             	sub    $0x4,%esp
   1713f:	50                   	push   %eax
   17140:	68 5d bc 01 00       	push   $0x1bc5d
   17145:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
   1714b:	50                   	push   %eax
   1714c:	e8 61 2b 00 00       	call   19cb2 <usprint>
   17151:	83 c4 10             	add    $0x10,%esp
		swrites( buf );
   17154:	83 ec 0c             	sub    $0xc,%esp
   17157:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
   1715d:	50                   	push   %eax
   1715e:	e8 a2 32 00 00       	call   1a405 <swrites>
   17163:	83 c4 10             	add    $0x10,%esp
		usage();
   17166:	e8 99 fe ff ff       	call   17004 <usage>
	}

	return 0;
   1716b:	b8 00 00 00 00       	mov    $0x0,%eax
}
   17170:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   17173:	c9                   	leave  
   17174:	c3                   	ret    

00017175 <edit>:
** edit - perform any command-line editing we need to do
**
** @param line   Input line buffer
** @param n      Number of valid bytes in the buffer
*/
static int edit( char line[], int n ) {
   17175:	55                   	push   %ebp
   17176:	89 e5                	mov    %esp,%ebp
   17178:	83 ec 10             	sub    $0x10,%esp
	char *ptr = line + n - 1;	// last char in buffer
   1717b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1717e:	8d 50 ff             	lea    -0x1(%eax),%edx
   17181:	8b 45 08             	mov    0x8(%ebp),%eax
   17184:	01 d0                	add    %edx,%eax
   17186:	89 45 fc             	mov    %eax,-0x4(%ebp)

	// strip the EOLN sequence
	while( n > 0 ) {
   17189:	eb 18                	jmp    171a3 <edit+0x2e>
		if( *ptr == '\n' || *ptr == '\r' ) {
   1718b:	8b 45 fc             	mov    -0x4(%ebp),%eax
   1718e:	0f b6 00             	movzbl (%eax),%eax
   17191:	3c 0a                	cmp    $0xa,%al
   17193:	74 0a                	je     1719f <edit+0x2a>
   17195:	8b 45 fc             	mov    -0x4(%ebp),%eax
   17198:	0f b6 00             	movzbl (%eax),%eax
   1719b:	3c 0d                	cmp    $0xd,%al
   1719d:	75 0a                	jne    171a9 <edit+0x34>
			--n;
   1719f:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
	while( n > 0 ) {
   171a3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   171a7:	7f e2                	jg     1718b <edit+0x16>
			break;
		}
	}

	// add a trailing NUL byte
	if( n > 0 ) {
   171a9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   171ad:	7e 0b                	jle    171ba <edit+0x45>
		line[n] = '\0';
   171af:	8b 55 0c             	mov    0xc(%ebp),%edx
   171b2:	8b 45 08             	mov    0x8(%ebp),%eax
   171b5:	01 d0                	add    %edx,%eax
   171b7:	c6 00 00             	movb   $0x0,(%eax)
	}

	return n;
   171ba:	8b 45 0c             	mov    0xc(%ebp),%eax
}
   171bd:	c9                   	leave  
   171be:	c3                   	ret    

000171bf <shell>:
** shell - extremely simple shell for spawning test programs
**
** Scheduled by _kshell() when the character 'u' is typed on
** the console keyboard.
*/
USERMAIN( shell ) {
   171bf:	55                   	push   %ebp
   171c0:	89 e5                	mov    %esp,%ebp
   171c2:	81 ec 28 01 00 00    	sub    $0x128,%esp
	char line[128];

	// keep the compiler happy
	(void) argc;
	char *name = argv[0] ? argv[0] : "nobody";
   171c8:	8b 45 0c             	mov    0xc(%ebp),%eax
   171cb:	8b 00                	mov    (%eax),%eax
   171cd:	85 c0                	test   %eax,%eax
   171cf:	74 07                	je     171d8 <shell+0x19>
   171d1:	8b 45 0c             	mov    0xc(%ebp),%eax
   171d4:	8b 00                	mov    (%eax),%eax
   171d6:	eb 05                	jmp    171dd <shell+0x1e>
   171d8:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   171dd:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// report that we're up and running
	usprint( line, "%s is ready\n", name );
   171e0:	83 ec 04             	sub    $0x4,%esp
   171e3:	ff 75 ec             	pushl  -0x14(%ebp)
   171e6:	68 76 bc 01 00       	push   $0x1bc76
   171eb:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   171f1:	50                   	push   %eax
   171f2:	e8 bb 2a 00 00       	call   19cb2 <usprint>
   171f7:	83 c4 10             	add    $0x10,%esp
	swrites( line );
   171fa:	83 ec 0c             	sub    $0xc,%esp
   171fd:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17203:	50                   	push   %eax
   17204:	e8 fc 31 00 00       	call   1a405 <swrites>
   17209:	83 c4 10             	add    $0x10,%esp

	// print a summary of the commands we'll accept
	usage();
   1720c:	e8 f3 fd ff ff       	call   17004 <usage>

	// loop forever
	while( !time_to_stop ) {
   17211:	e9 a7 01 00 00       	jmp    173bd <shell+0x1fe>
		char *ptr;

		// the shell reads one line from the keyboard, parses it,
		// and performs whatever command it requests.

		swrites( "\n> " );
   17216:	83 ec 0c             	sub    $0xc,%esp
   17219:	68 83 bc 01 00       	push   $0x1bc83
   1721e:	e8 e2 31 00 00       	call   1a405 <swrites>
   17223:	83 c4 10             	add    $0x10,%esp
		int n = read( CHAN_SIO, line, sizeof(line) );
   17226:	83 ec 04             	sub    $0x4,%esp
   17229:	68 80 00 00 00       	push   $0x80
   1722e:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17234:	50                   	push   %eax
   17235:	6a 01                	push   $0x1
   17237:	e8 ec fc ff ff       	call   16f28 <read>
   1723c:	83 c4 10             	add    $0x10,%esp
   1723f:	89 45 e8             	mov    %eax,-0x18(%ebp)
		
		// shortest valid command is "@?", so must have 3+ chars here
		if( n < 3 ) {
   17242:	83 7d e8 02          	cmpl   $0x2,-0x18(%ebp)
   17246:	7f 05                	jg     1724d <shell+0x8e>
			// ignore it
			continue;
   17248:	e9 70 01 00 00       	jmp    173bd <shell+0x1fe>
		}

		// edit it as needed; new shortest command is 2+ chars
		if( (n=edit(line,n)) < 2 ) {
   1724d:	83 ec 08             	sub    $0x8,%esp
   17250:	ff 75 e8             	pushl  -0x18(%ebp)
   17253:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17259:	50                   	push   %eax
   1725a:	e8 16 ff ff ff       	call   17175 <edit>
   1725f:	83 c4 10             	add    $0x10,%esp
   17262:	89 45 e8             	mov    %eax,-0x18(%ebp)
   17265:	83 7d e8 01          	cmpl   $0x1,-0x18(%ebp)
   17269:	7f 05                	jg     17270 <shell+0xb1>
			continue;
   1726b:	e9 4d 01 00 00       	jmp    173bd <shell+0x1fe>
		}

		// find the '@'
		int i = 0;
   17270:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
		for( ptr = line; i < n; ++i, ++ptr ) {
   17277:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   1727d:	89 45 f4             	mov    %eax,-0xc(%ebp)
   17280:	eb 12                	jmp    17294 <shell+0xd5>
			if( *ptr == '@' ) {
   17282:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17285:	0f b6 00             	movzbl (%eax),%eax
   17288:	3c 40                	cmp    $0x40,%al
   1728a:	74 12                	je     1729e <shell+0xdf>
		for( ptr = line; i < n; ++i, ++ptr ) {
   1728c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   17290:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   17294:	8b 45 f0             	mov    -0x10(%ebp),%eax
   17297:	3b 45 e8             	cmp    -0x18(%ebp),%eax
   1729a:	7c e6                	jl     17282 <shell+0xc3>
   1729c:	eb 01                	jmp    1729f <shell+0xe0>
				break;
   1729e:	90                   	nop
			}
		}

		// did we find an '@'?
		if( i < n ) {
   1729f:	8b 45 f0             	mov    -0x10(%ebp),%eax
   172a2:	3b 45 e8             	cmp    -0x18(%ebp),%eax
   172a5:	0f 8d 12 01 00 00    	jge    173bd <shell+0x1fe>

			// yes; process any commands that follow it
			++ptr;
   172ab:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

			for( ; *ptr != '\0'; ++ptr ) {
   172af:	eb 66                	jmp    17317 <shell+0x158>
				char buf[128];
				int pid = run( *ptr );
   172b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
   172b4:	0f b6 00             	movzbl (%eax),%eax
   172b7:	0f be c0             	movsbl %al,%eax
   172ba:	83 ec 0c             	sub    $0xc,%esp
   172bd:	50                   	push   %eax
   172be:	e8 a2 fd ff ff       	call   17065 <run>
   172c3:	83 c4 10             	add    $0x10,%esp
   172c6:	89 45 e4             	mov    %eax,-0x1c(%ebp)

				if( pid < 0 ) {
   172c9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   172cd:	79 39                	jns    17308 <shell+0x149>
					// spawn() failed
					usprint( buf, "+++ %s spawn %c failed, code %d\n",
							name, *ptr, pid );
   172cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
   172d2:	0f b6 00             	movzbl (%eax),%eax
					usprint( buf, "+++ %s spawn %c failed, code %d\n",
   172d5:	0f be c0             	movsbl %al,%eax
   172d8:	83 ec 0c             	sub    $0xc,%esp
   172db:	ff 75 e4             	pushl  -0x1c(%ebp)
   172de:	50                   	push   %eax
   172df:	ff 75 ec             	pushl  -0x14(%ebp)
   172e2:	68 88 bc 01 00       	push   $0x1bc88
   172e7:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   172ed:	50                   	push   %eax
   172ee:	e8 bf 29 00 00       	call   19cb2 <usprint>
   172f3:	83 c4 20             	add    $0x20,%esp
					cwrites( buf );
   172f6:	83 ec 0c             	sub    $0xc,%esp
   172f9:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   172ff:	50                   	push   %eax
   17300:	e8 9a 30 00 00       	call   1a39f <cwrites>
   17305:	83 c4 10             	add    $0x10,%esp
				}

				// should we end it all?
				if( time_to_stop ) {
   17308:	0f b6 05 b4 f1 01 00 	movzbl 0x1f1b4,%eax
   1730f:	84 c0                	test   %al,%al
   17311:	75 13                	jne    17326 <shell+0x167>
			for( ; *ptr != '\0'; ++ptr ) {
   17313:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   17317:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1731a:	0f b6 00             	movzbl (%eax),%eax
   1731d:	84 c0                	test   %al,%al
   1731f:	75 90                	jne    172b1 <shell+0xf2>
   17321:	e9 8a 00 00 00       	jmp    173b0 <shell+0x1f1>
					break;
   17326:	90                   	nop
				}
			} // for

			// now, wait for all the spawned children
			while( children > 0 ) {
   17327:	e9 84 00 00 00       	jmp    173b0 <shell+0x1f1>
				// wait for the child
				int32_t status;
				char buf[128];
				int whom = waitpid( 0, &status );
   1732c:	83 ec 08             	sub    $0x8,%esp
   1732f:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17335:	50                   	push   %eax
   17336:	6a 00                	push   $0x0
   17338:	e8 d3 fb ff ff       	call   16f10 <waitpid>
   1733d:	83 c4 10             	add    $0x10,%esp
   17340:	89 45 e0             	mov    %eax,-0x20(%ebp)

				// figure out the result
				if( whom == E_NO_CHILDREN ) {
   17343:	83 7d e0 fc          	cmpl   $0xfffffffc,-0x20(%ebp)
   17347:	75 02                	jne    1734b <shell+0x18c>
   17349:	eb 72                	jmp    173bd <shell+0x1fe>
					break;
				} else if( whom < 1 ) {
   1734b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   1734f:	7f 1c                	jg     1736d <shell+0x1ae>
					usprint( buf, "%s: waitpid() returned %d\n", name, whom );
   17351:	ff 75 e0             	pushl  -0x20(%ebp)
   17354:	ff 75 ec             	pushl  -0x14(%ebp)
   17357:	68 a9 bc 01 00       	push   $0x1bca9
   1735c:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   17362:	50                   	push   %eax
   17363:	e8 4a 29 00 00       	call   19cb2 <usprint>
   17368:	83 c4 10             	add    $0x10,%esp
   1736b:	eb 31                	jmp    1739e <shell+0x1df>
				} else {
					--children;
   1736d:	a1 b8 f1 01 00       	mov    0x1f1b8,%eax
   17372:	83 e8 01             	sub    $0x1,%eax
   17375:	a3 b8 f1 01 00       	mov    %eax,0x1f1b8
					usprint( buf, "%s: PID %d exit status %d\n",
   1737a:	8b 85 5c ff ff ff    	mov    -0xa4(%ebp),%eax
   17380:	83 ec 0c             	sub    $0xc,%esp
   17383:	50                   	push   %eax
   17384:	ff 75 e0             	pushl  -0x20(%ebp)
   17387:	ff 75 ec             	pushl  -0x14(%ebp)
   1738a:	68 c4 bc 01 00       	push   $0x1bcc4
   1738f:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   17395:	50                   	push   %eax
   17396:	e8 17 29 00 00       	call   19cb2 <usprint>
   1739b:	83 c4 20             	add    $0x20,%esp
							name, whom, status );
				}
				// report it
				swrites( buf );
   1739e:	83 ec 0c             	sub    $0xc,%esp
   173a1:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   173a7:	50                   	push   %eax
   173a8:	e8 58 30 00 00       	call   1a405 <swrites>
   173ad:	83 c4 10             	add    $0x10,%esp
			while( children > 0 ) {
   173b0:	a1 b8 f1 01 00       	mov    0x1f1b8,%eax
   173b5:	85 c0                	test   %eax,%eax
   173b7:	0f 8f 6f ff ff ff    	jg     1732c <shell+0x16d>
	while( !time_to_stop ) {
   173bd:	0f b6 05 b4 f1 01 00 	movzbl 0x1f1b4,%eax
   173c4:	84 c0                	test   %al,%al
   173c6:	0f 84 4a fe ff ff    	je     17216 <shell+0x57>
			}
		}  // if i < n
	}  // while

	cwrites( "!!! shell exited loop???\n" );
   173cc:	83 ec 0c             	sub    $0xc,%esp
   173cf:	68 df bc 01 00       	push   $0x1bcdf
   173d4:	e8 c6 2f 00 00       	call   1a39f <cwrites>
   173d9:	83 c4 10             	add    $0x10,%esp
	exit( 1 );
   173dc:	83 ec 0c             	sub    $0xc,%esp
   173df:	6a 01                	push   $0x1
   173e1:	e8 22 fb ff ff       	call   16f08 <exit>
   173e6:	83 c4 10             	add    $0x10,%esp

	// yeah, yeah....
	return( 0 );
   173e9:	b8 00 00 00 00       	mov    $0x0,%eax
}
   173ee:	c9                   	leave  
   173ef:	c3                   	ret    

000173f0 <process>:
**
** @param proc  pointer to the spawn table entry to be used
*/

static void process( proc_t *proc )
{
   173f0:	55                   	push   %ebp
   173f1:	89 e5                	mov    %esp,%ebp
   173f3:	81 ec 98 00 00 00    	sub    $0x98,%esp
	char buf[128];

	// kick off the process
	int32_t p = fork();
   173f9:	e8 1a fb ff ff       	call   16f18 <fork>
   173fe:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( p < 0 ) {
   17401:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   17405:	79 34                	jns    1743b <process+0x4b>

		// error!
		usprint( buf, "INIT: fork for #%d failed\n",
				(uint32_t) (proc->entry) );
   17407:	8b 45 08             	mov    0x8(%ebp),%eax
   1740a:	8b 00                	mov    (%eax),%eax
		usprint( buf, "INIT: fork for #%d failed\n",
   1740c:	83 ec 04             	sub    $0x4,%esp
   1740f:	50                   	push   %eax
   17410:	68 06 bd 01 00       	push   $0x1bd06
   17415:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
   1741b:	50                   	push   %eax
   1741c:	e8 91 28 00 00       	call   19cb2 <usprint>
   17421:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   17424:	83 ec 0c             	sub    $0xc,%esp
   17427:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
   1742d:	50                   	push   %eax
   1742e:	e8 6c 2f 00 00       	call   1a39f <cwrites>
   17433:	83 c4 10             	add    $0x10,%esp
		swritech( ch );

		proc->pid = p;

	}
}
   17436:	e9 84 00 00 00       	jmp    174bf <process+0xcf>
	} else if( p == 0 ) {
   1743b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1743f:	75 5f                	jne    174a0 <process+0xb0>
		(void) setprio( proc->e_prio );
   17441:	8b 45 08             	mov    0x8(%ebp),%eax
   17444:	0f b6 40 08          	movzbl 0x8(%eax),%eax
   17448:	0f b6 c0             	movzbl %al,%eax
   1744b:	83 ec 0c             	sub    $0xc,%esp
   1744e:	50                   	push   %eax
   1744f:	e8 04 fb ff ff       	call   16f58 <setprio>
   17454:	83 c4 10             	add    $0x10,%esp
		exec( proc->entry, proc->args );
   17457:	8b 45 08             	mov    0x8(%ebp),%eax
   1745a:	8d 50 0c             	lea    0xc(%eax),%edx
   1745d:	8b 45 08             	mov    0x8(%ebp),%eax
   17460:	8b 00                	mov    (%eax),%eax
   17462:	83 ec 08             	sub    $0x8,%esp
   17465:	52                   	push   %edx
   17466:	50                   	push   %eax
   17467:	e8 b4 fa ff ff       	call   16f20 <exec>
   1746c:	83 c4 10             	add    $0x10,%esp
				(uint32_t) (proc->entry) );
   1746f:	8b 45 08             	mov    0x8(%ebp),%eax
   17472:	8b 00                	mov    (%eax),%eax
		usprint( buf, "INIT: exec(0x%08x) failed\n",
   17474:	83 ec 04             	sub    $0x4,%esp
   17477:	50                   	push   %eax
   17478:	68 21 bd 01 00       	push   $0x1bd21
   1747d:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
   17483:	50                   	push   %eax
   17484:	e8 29 28 00 00       	call   19cb2 <usprint>
   17489:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   1748c:	83 ec 0c             	sub    $0xc,%esp
   1748f:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
   17495:	50                   	push   %eax
   17496:	e8 04 2f 00 00       	call   1a39f <cwrites>
   1749b:	83 c4 10             	add    $0x10,%esp
}
   1749e:	eb 1f                	jmp    174bf <process+0xcf>
		swritech( ch );
   174a0:	0f b6 05 3c d6 01 00 	movzbl 0x1d63c,%eax
   174a7:	0f be c0             	movsbl %al,%eax
   174aa:	83 ec 0c             	sub    $0xc,%esp
   174ad:	50                   	push   %eax
   174ae:	e8 31 2f 00 00       	call   1a3e4 <swritech>
   174b3:	83 c4 10             	add    $0x10,%esp
		proc->pid = p;
   174b6:	8b 55 f4             	mov    -0xc(%ebp),%edx
   174b9:	8b 45 08             	mov    0x8(%ebp),%eax
   174bc:	89 50 04             	mov    %edx,0x4(%eax)
}
   174bf:	90                   	nop
   174c0:	c9                   	leave  
   174c1:	c3                   	ret    

000174c2 <init>:
/*
** The initial user process. Should be invoked with zero or one
** argument; if provided, the first argument should be the ASCII
** character 'init' will print to indicate the spawning of a process.
*/
USERMAIN( init ) {
   174c2:	55                   	push   %ebp
   174c3:	89 e5                	mov    %esp,%ebp
   174c5:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   174cb:	8b 45 0c             	mov    0xc(%ebp),%eax
   174ce:	8b 00                	mov    (%eax),%eax
   174d0:	85 c0                	test   %eax,%eax
   174d2:	74 07                	je     174db <init+0x19>
   174d4:	8b 45 0c             	mov    0xc(%ebp),%eax
   174d7:	8b 00                	mov    (%eax),%eax
   174d9:	eb 05                	jmp    174e0 <init+0x1e>
   174db:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   174e0:	89 45 e8             	mov    %eax,-0x18(%ebp)
	char buf[128];

	// check to see if we got a non-standard "spawn" character
	if( argc > 1 ) {
   174e3:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
   174e7:	7e 2d                	jle    17516 <init+0x54>
		// maybe - check it to be sure it's printable
		uint_t i = argv[1][0];
   174e9:	8b 45 0c             	mov    0xc(%ebp),%eax
   174ec:	83 c0 04             	add    $0x4,%eax
   174ef:	8b 00                	mov    (%eax),%eax
   174f1:	0f b6 00             	movzbl (%eax),%eax
   174f4:	0f be c0             	movsbl %al,%eax
   174f7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		if( i > ' ' && i < 0x7f ) {
   174fa:	83 7d e4 20          	cmpl   $0x20,-0x1c(%ebp)
   174fe:	76 16                	jbe    17516 <init+0x54>
   17500:	83 7d e4 7e          	cmpl   $0x7e,-0x1c(%ebp)
   17504:	77 10                	ja     17516 <init+0x54>
			ch = argv[1][0];
   17506:	8b 45 0c             	mov    0xc(%ebp),%eax
   17509:	83 c0 04             	add    $0x4,%eax
   1750c:	8b 00                	mov    (%eax),%eax
   1750e:	0f b6 00             	movzbl (%eax),%eax
   17511:	a2 3c d6 01 00       	mov    %al,0x1d63c
		}
	}

	// test the sio
	write( CHAN_SIO, "$+$\n", 4 );
   17516:	83 ec 04             	sub    $0x4,%esp
   17519:	6a 04                	push   $0x4
   1751b:	68 3c bd 01 00       	push   $0x1bd3c
   17520:	6a 01                	push   $0x1
   17522:	e8 09 fa ff ff       	call   16f30 <write>
   17527:	83 c4 10             	add    $0x10,%esp
	DELAY(SHORT);
   1752a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   17531:	eb 04                	jmp    17537 <init+0x75>
   17533:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   17537:	81 7d f4 9f 25 26 00 	cmpl   $0x26259f,-0xc(%ebp)
   1753e:	7e f3                	jle    17533 <init+0x71>

	usprint( buf, "%s: started\n", name );
   17540:	83 ec 04             	sub    $0x4,%esp
   17543:	ff 75 e8             	pushl  -0x18(%ebp)
   17546:	68 41 bd 01 00       	push   $0x1bd41
   1754b:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17551:	50                   	push   %eax
   17552:	e8 5b 27 00 00       	call   19cb2 <usprint>
   17557:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   1755a:	83 ec 0c             	sub    $0xc,%esp
   1755d:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17563:	50                   	push   %eax
   17564:	e8 36 2e 00 00       	call   1a39f <cwrites>
   17569:	83 c4 10             	add    $0x10,%esp

	// home up, clear on a TVI 925
	// swritech( '\x1a' );

	// wait a bit
	DELAY(SHORT);
   1756c:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   17573:	eb 04                	jmp    17579 <init+0xb7>
   17575:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   17579:	81 7d f0 9f 25 26 00 	cmpl   $0x26259f,-0x10(%ebp)
   17580:	7e f3                	jle    17575 <init+0xb3>

	// a bit of Dante to set the mood :-)
	swrites( "\n\nSpem relinquunt qui huc intrasti!\n\n\r" );
   17582:	83 ec 0c             	sub    $0xc,%esp
   17585:	68 50 bd 01 00       	push   $0x1bd50
   1758a:	e8 76 2e 00 00       	call   1a405 <swrites>
   1758f:	83 c4 10             	add    $0x10,%esp

	/*
	** Start all the user processes
	*/

	usprint( buf, "%s: starting user processes\n", name );
   17592:	83 ec 04             	sub    $0x4,%esp
   17595:	ff 75 e8             	pushl  -0x18(%ebp)
   17598:	68 77 bd 01 00       	push   $0x1bd77
   1759d:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   175a3:	50                   	push   %eax
   175a4:	e8 09 27 00 00       	call   19cb2 <usprint>
   175a9:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   175ac:	83 ec 0c             	sub    $0xc,%esp
   175af:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   175b5:	50                   	push   %eax
   175b6:	e8 e4 2d 00 00       	call   1a39f <cwrites>
   175bb:	83 c4 10             	add    $0x10,%esp

	proc_t *next;
	for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
   175be:	c7 45 ec a0 d5 01 00 	movl   $0x1d5a0,-0x14(%ebp)
   175c5:	eb 12                	jmp    175d9 <init+0x117>
		process( next );
   175c7:	83 ec 0c             	sub    $0xc,%esp
   175ca:	ff 75 ec             	pushl  -0x14(%ebp)
   175cd:	e8 1e fe ff ff       	call   173f0 <process>
   175d2:	83 c4 10             	add    $0x10,%esp
	for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
   175d5:	83 45 ec 34          	addl   $0x34,-0x14(%ebp)
   175d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
   175dc:	8b 00                	mov    (%eax),%eax
   175de:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   175e3:	75 e2                	jne    175c7 <init+0x105>
	}

	swrites( " !!!\r\n\n" );
   175e5:	83 ec 0c             	sub    $0xc,%esp
   175e8:	68 94 bd 01 00       	push   $0x1bd94
   175ed:	e8 13 2e 00 00       	call   1a405 <swrites>
   175f2:	83 c4 10             	add    $0x10,%esp
	/*
	** At this point, we go into an infinite loop waiting
	** for our children (direct, or inherited) to exit.
	*/

	usprint( buf, "%s: transitioning to wait() mode\n", name );
   175f5:	83 ec 04             	sub    $0x4,%esp
   175f8:	ff 75 e8             	pushl  -0x18(%ebp)
   175fb:	68 9c bd 01 00       	push   $0x1bd9c
   17600:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17606:	50                   	push   %eax
   17607:	e8 a6 26 00 00       	call   19cb2 <usprint>
   1760c:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   1760f:	83 ec 0c             	sub    $0xc,%esp
   17612:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17618:	50                   	push   %eax
   17619:	e8 81 2d 00 00       	call   1a39f <cwrites>
   1761e:	83 c4 10             	add    $0x10,%esp

	for(;;) {
		int32_t status;
		int whom = waitpid( 0, &status );
   17621:	83 ec 08             	sub    $0x8,%esp
   17624:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1762a:	50                   	push   %eax
   1762b:	6a 00                	push   $0x0
   1762d:	e8 de f8 ff ff       	call   16f10 <waitpid>
   17632:	83 c4 10             	add    $0x10,%esp
   17635:	89 45 e0             	mov    %eax,-0x20(%ebp)

		// PIDs must be positive numbers!
		if( whom <= 0 ) {
   17638:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   1763c:	7f 2e                	jg     1766c <init+0x1aa>

			usprint( buf, "%s: waitpid() returned %d???\n", name, whom );
   1763e:	ff 75 e0             	pushl  -0x20(%ebp)
   17641:	ff 75 e8             	pushl  -0x18(%ebp)
   17644:	68 be bd 01 00       	push   $0x1bdbe
   17649:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   1764f:	50                   	push   %eax
   17650:	e8 5d 26 00 00       	call   19cb2 <usprint>
   17655:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17658:	83 ec 0c             	sub    $0xc,%esp
   1765b:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17661:	50                   	push   %eax
   17662:	e8 38 2d 00 00       	call   1a39f <cwrites>
   17667:	83 c4 10             	add    $0x10,%esp
   1766a:	eb b5                	jmp    17621 <init+0x15f>

		} else {

			// got one; report it
			usprint( buf, "%s: pid %d exit(%d)\n", name, whom, status );
   1766c:	8b 85 5c ff ff ff    	mov    -0xa4(%ebp),%eax
   17672:	83 ec 0c             	sub    $0xc,%esp
   17675:	50                   	push   %eax
   17676:	ff 75 e0             	pushl  -0x20(%ebp)
   17679:	ff 75 e8             	pushl  -0x18(%ebp)
   1767c:	68 dc bd 01 00       	push   $0x1bddc
   17681:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17687:	50                   	push   %eax
   17688:	e8 25 26 00 00       	call   19cb2 <usprint>
   1768d:	83 c4 20             	add    $0x20,%esp
			cwrites( buf );
   17690:	83 ec 0c             	sub    $0xc,%esp
   17693:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17699:	50                   	push   %eax
   1769a:	e8 00 2d 00 00       	call   1a39f <cwrites>
   1769f:	83 c4 10             	add    $0x10,%esp

			// figure out if this is one of ours
			for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
   176a2:	c7 45 ec a0 d5 01 00 	movl   $0x1d5a0,-0x14(%ebp)
   176a9:	eb 2b                	jmp    176d6 <init+0x214>
				if( next->pid == whom ) {
   176ab:	8b 45 ec             	mov    -0x14(%ebp),%eax
   176ae:	8b 50 04             	mov    0x4(%eax),%edx
   176b1:	8b 45 e0             	mov    -0x20(%ebp),%eax
   176b4:	39 c2                	cmp    %eax,%edx
   176b6:	75 1a                	jne    176d2 <init+0x210>
					// one of ours - reset the PID field
					// (in case the spawn attempt fails)
					next->pid = 0;
   176b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
   176bb:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
					// and restart it
					process( next );
   176c2:	83 ec 0c             	sub    $0xc,%esp
   176c5:	ff 75 ec             	pushl  -0x14(%ebp)
   176c8:	e8 23 fd ff ff       	call   173f0 <process>
   176cd:	83 c4 10             	add    $0x10,%esp
					break;
   176d0:	eb 10                	jmp    176e2 <init+0x220>
			for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
   176d2:	83 45 ec 34          	addl   $0x34,-0x14(%ebp)
   176d6:	8b 45 ec             	mov    -0x14(%ebp),%eax
   176d9:	8b 00                	mov    (%eax),%eax
   176db:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   176e0:	75 c9                	jne    176ab <init+0x1e9>
	for(;;) {
   176e2:	e9 3a ff ff ff       	jmp    17621 <init+0x15f>

000176e7 <progABC>:
** Invoked as:  progABC  x  n
**	 where x is the ID character
**		   n is the iteration count
*/

USERMAIN( progABC ) {
   176e7:	55                   	push   %ebp
   176e8:	89 e5                	mov    %esp,%ebp
   176ea:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   176f0:	8b 45 0c             	mov    0xc(%ebp),%eax
   176f3:	8b 00                	mov    (%eax),%eax
   176f5:	85 c0                	test   %eax,%eax
   176f7:	74 07                	je     17700 <progABC+0x19>
   176f9:	8b 45 0c             	mov    0xc(%ebp),%eax
   176fc:	8b 00                	mov    (%eax),%eax
   176fe:	eb 05                	jmp    17705 <progABC+0x1e>
   17700:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   17705:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 30; // default iteration count
   17708:	c7 45 f4 1e 00 00 00 	movl   $0x1e,-0xc(%ebp)
	char ch = '1';	// default character to print
   1770f:	c6 45 f3 31          	movb   $0x31,-0xd(%ebp)
	char buf[128];	// local char buffer

	// process the command-line arguments
	switch( argc ) {
   17713:	8b 45 08             	mov    0x8(%ebp),%eax
   17716:	83 f8 02             	cmp    $0x2,%eax
   17719:	74 1e                	je     17739 <progABC+0x52>
   1771b:	83 f8 03             	cmp    $0x3,%eax
   1771e:	75 2c                	jne    1774c <progABC+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   17720:	8b 45 0c             	mov    0xc(%ebp),%eax
   17723:	83 c0 08             	add    $0x8,%eax
   17726:	8b 00                	mov    (%eax),%eax
   17728:	83 ec 08             	sub    $0x8,%esp
   1772b:	6a 0a                	push   $0xa
   1772d:	50                   	push   %eax
   1772e:	e8 f4 27 00 00       	call   19f27 <ustr2int>
   17733:	83 c4 10             	add    $0x10,%esp
   17736:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17739:	8b 45 0c             	mov    0xc(%ebp),%eax
   1773c:	83 c0 04             	add    $0x4,%eax
   1773f:	8b 00                	mov    (%eax),%eax
   17741:	0f b6 00             	movzbl (%eax),%eax
   17744:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   17747:	e9 a8 00 00 00       	jmp    177f4 <progABC+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   1774c:	ff 75 08             	pushl  0x8(%ebp)
   1774f:	ff 75 e0             	pushl  -0x20(%ebp)
   17752:	68 f1 bd 01 00       	push   $0x1bdf1
   17757:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1775d:	50                   	push   %eax
   1775e:	e8 4f 25 00 00       	call   19cb2 <usprint>
   17763:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17766:	83 ec 0c             	sub    $0xc,%esp
   17769:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1776f:	50                   	push   %eax
   17770:	e8 2a 2c 00 00       	call   1a39f <cwrites>
   17775:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17778:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   1777f:	eb 5b                	jmp    177dc <progABC+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   17781:	8b 45 08             	mov    0x8(%ebp),%eax
   17784:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1778b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1778e:	01 d0                	add    %edx,%eax
   17790:	8b 00                	mov    (%eax),%eax
   17792:	85 c0                	test   %eax,%eax
   17794:	74 13                	je     177a9 <progABC+0xc2>
   17796:	8b 45 08             	mov    0x8(%ebp),%eax
   17799:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   177a0:	8b 45 0c             	mov    0xc(%ebp),%eax
   177a3:	01 d0                	add    %edx,%eax
   177a5:	8b 00                	mov    (%eax),%eax
   177a7:	eb 05                	jmp    177ae <progABC+0xc7>
   177a9:	b8 05 be 01 00       	mov    $0x1be05,%eax
   177ae:	83 ec 04             	sub    $0x4,%esp
   177b1:	50                   	push   %eax
   177b2:	68 0c be 01 00       	push   $0x1be0c
   177b7:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   177bd:	50                   	push   %eax
   177be:	e8 ef 24 00 00       	call   19cb2 <usprint>
   177c3:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   177c6:	83 ec 0c             	sub    $0xc,%esp
   177c9:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   177cf:	50                   	push   %eax
   177d0:	e8 ca 2b 00 00       	call   1a39f <cwrites>
   177d5:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   177d8:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   177dc:	8b 45 ec             	mov    -0x14(%ebp),%eax
   177df:	3b 45 08             	cmp    0x8(%ebp),%eax
   177e2:	7e 9d                	jle    17781 <progABC+0x9a>
			}
			cwrites( "\n" );
   177e4:	83 ec 0c             	sub    $0xc,%esp
   177e7:	68 10 be 01 00       	push   $0x1be10
   177ec:	e8 ae 2b 00 00       	call   1a39f <cwrites>
   177f1:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int n = swritech( ch );
   177f4:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   177f8:	83 ec 0c             	sub    $0xc,%esp
   177fb:	50                   	push   %eax
   177fc:	e8 e3 2b 00 00       	call   1a3e4 <swritech>
   17801:	83 c4 10             	add    $0x10,%esp
   17804:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if( n != 1 ) {
   17807:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   1780b:	74 2e                	je     1783b <progABC+0x154>
		usprint( buf, "== %c, write #1 returned %d\n", ch, n );
   1780d:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17811:	ff 75 dc             	pushl  -0x24(%ebp)
   17814:	50                   	push   %eax
   17815:	68 12 be 01 00       	push   $0x1be12
   1781a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17820:	50                   	push   %eax
   17821:	e8 8c 24 00 00       	call   19cb2 <usprint>
   17826:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   17829:	83 ec 0c             	sub    $0xc,%esp
   1782c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17832:	50                   	push   %eax
   17833:	e8 67 2b 00 00       	call   1a39f <cwrites>
   17838:	83 c4 10             	add    $0x10,%esp
	}

	// iterate and print the required number of other characters
	for( int i = 0; i < count; ++i ) {
   1783b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   17842:	eb 61                	jmp    178a5 <progABC+0x1be>
		DELAY(STD);
   17844:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   1784b:	eb 04                	jmp    17851 <progABC+0x16a>
   1784d:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   17851:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   17858:	7e f3                	jle    1784d <progABC+0x166>
		n = swritech( ch );
   1785a:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   1785e:	83 ec 0c             	sub    $0xc,%esp
   17861:	50                   	push   %eax
   17862:	e8 7d 2b 00 00       	call   1a3e4 <swritech>
   17867:	83 c4 10             	add    $0x10,%esp
   1786a:	89 45 dc             	mov    %eax,-0x24(%ebp)
		if( n != 1 ) {
   1786d:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   17871:	74 2e                	je     178a1 <progABC+0x1ba>
			usprint( buf, "== %c, write #2 returned %d\n", ch, n );
   17873:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17877:	ff 75 dc             	pushl  -0x24(%ebp)
   1787a:	50                   	push   %eax
   1787b:	68 2f be 01 00       	push   $0x1be2f
   17880:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17886:	50                   	push   %eax
   17887:	e8 26 24 00 00       	call   19cb2 <usprint>
   1788c:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1788f:	83 ec 0c             	sub    $0xc,%esp
   17892:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17898:	50                   	push   %eax
   17899:	e8 01 2b 00 00       	call   1a39f <cwrites>
   1789e:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   178a1:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   178a5:	8b 45 e8             	mov    -0x18(%ebp),%eax
   178a8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   178ab:	7c 97                	jl     17844 <progABC+0x15d>
		}
	}

	// all done!
	exit( 0 );
   178ad:	83 ec 0c             	sub    $0xc,%esp
   178b0:	6a 00                	push   $0x0
   178b2:	e8 51 f6 ff ff       	call   16f08 <exit>
   178b7:	83 c4 10             	add    $0x10,%esp

	// should never reach this code; if we do, something is
	// wrong with exit(), so we'll report it

	char msg[] = "*1*";
   178ba:	c7 85 58 ff ff ff 2a 	movl   $0x2a312a,-0xa8(%ebp)
   178c1:	31 2a 00 
	msg[1] = ch;
   178c4:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   178c8:	88 85 59 ff ff ff    	mov    %al,-0xa7(%ebp)
	n = write( CHAN_SIO, msg, 3 );	  /* shouldn't happen! */
   178ce:	83 ec 04             	sub    $0x4,%esp
   178d1:	6a 03                	push   $0x3
   178d3:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   178d9:	50                   	push   %eax
   178da:	6a 01                	push   $0x1
   178dc:	e8 4f f6 ff ff       	call   16f30 <write>
   178e1:	83 c4 10             	add    $0x10,%esp
   178e4:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if( n != 3 ) {
   178e7:	83 7d dc 03          	cmpl   $0x3,-0x24(%ebp)
   178eb:	74 2e                	je     1791b <progABC+0x234>
		usprint( buf, "User %c, write #3 returned %d\n", ch, n );
   178ed:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   178f1:	ff 75 dc             	pushl  -0x24(%ebp)
   178f4:	50                   	push   %eax
   178f5:	68 4c be 01 00       	push   $0x1be4c
   178fa:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17900:	50                   	push   %eax
   17901:	e8 ac 23 00 00       	call   19cb2 <usprint>
   17906:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   17909:	83 ec 0c             	sub    $0xc,%esp
   1790c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17912:	50                   	push   %eax
   17913:	e8 87 2a 00 00       	call   1a39f <cwrites>
   17918:	83 c4 10             	add    $0x10,%esp
	}

	// this should really get us out of here
	return( 42 );
   1791b:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   17920:	c9                   	leave  
   17921:	c3                   	ret    

00017922 <progDE>:
** Invoked as:  progDE  x  n
**	 where x is the ID character
**		   n is the iteration count
*/

USERMAIN( progDE ) {
   17922:	55                   	push   %ebp
   17923:	89 e5                	mov    %esp,%ebp
   17925:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   1792b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1792e:	8b 00                	mov    (%eax),%eax
   17930:	85 c0                	test   %eax,%eax
   17932:	74 07                	je     1793b <progDE+0x19>
   17934:	8b 45 0c             	mov    0xc(%ebp),%eax
   17937:	8b 00                	mov    (%eax),%eax
   17939:	eb 05                	jmp    17940 <progDE+0x1e>
   1793b:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   17940:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int n;
	int count = 30;	  // default iteration count
   17943:	c7 45 f4 1e 00 00 00 	movl   $0x1e,-0xc(%ebp)
	char ch = '2';	  // default character to print
   1794a:	c6 45 f3 32          	movb   $0x32,-0xd(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   1794e:	8b 45 08             	mov    0x8(%ebp),%eax
   17951:	83 f8 02             	cmp    $0x2,%eax
   17954:	74 1e                	je     17974 <progDE+0x52>
   17956:	83 f8 03             	cmp    $0x3,%eax
   17959:	75 2c                	jne    17987 <progDE+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   1795b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1795e:	83 c0 08             	add    $0x8,%eax
   17961:	8b 00                	mov    (%eax),%eax
   17963:	83 ec 08             	sub    $0x8,%esp
   17966:	6a 0a                	push   $0xa
   17968:	50                   	push   %eax
   17969:	e8 b9 25 00 00       	call   19f27 <ustr2int>
   1796e:	83 c4 10             	add    $0x10,%esp
   17971:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17974:	8b 45 0c             	mov    0xc(%ebp),%eax
   17977:	83 c0 04             	add    $0x4,%eax
   1797a:	8b 00                	mov    (%eax),%eax
   1797c:	0f b6 00             	movzbl (%eax),%eax
   1797f:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   17982:	e9 a8 00 00 00       	jmp    17a2f <progDE+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   17987:	ff 75 08             	pushl  0x8(%ebp)
   1798a:	ff 75 e0             	pushl  -0x20(%ebp)
   1798d:	68 f1 bd 01 00       	push   $0x1bdf1
   17992:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17998:	50                   	push   %eax
   17999:	e8 14 23 00 00       	call   19cb2 <usprint>
   1799e:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   179a1:	83 ec 0c             	sub    $0xc,%esp
   179a4:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   179aa:	50                   	push   %eax
   179ab:	e8 ef 29 00 00       	call   1a39f <cwrites>
   179b0:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   179b3:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   179ba:	eb 5b                	jmp    17a17 <progDE+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   179bc:	8b 45 08             	mov    0x8(%ebp),%eax
   179bf:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   179c6:	8b 45 0c             	mov    0xc(%ebp),%eax
   179c9:	01 d0                	add    %edx,%eax
   179cb:	8b 00                	mov    (%eax),%eax
   179cd:	85 c0                	test   %eax,%eax
   179cf:	74 13                	je     179e4 <progDE+0xc2>
   179d1:	8b 45 08             	mov    0x8(%ebp),%eax
   179d4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   179db:	8b 45 0c             	mov    0xc(%ebp),%eax
   179de:	01 d0                	add    %edx,%eax
   179e0:	8b 00                	mov    (%eax),%eax
   179e2:	eb 05                	jmp    179e9 <progDE+0xc7>
   179e4:	b8 05 be 01 00       	mov    $0x1be05,%eax
   179e9:	83 ec 04             	sub    $0x4,%esp
   179ec:	50                   	push   %eax
   179ed:	68 0c be 01 00       	push   $0x1be0c
   179f2:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   179f8:	50                   	push   %eax
   179f9:	e8 b4 22 00 00       	call   19cb2 <usprint>
   179fe:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17a01:	83 ec 0c             	sub    $0xc,%esp
   17a04:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17a0a:	50                   	push   %eax
   17a0b:	e8 8f 29 00 00       	call   1a39f <cwrites>
   17a10:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17a13:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   17a17:	8b 45 ec             	mov    -0x14(%ebp),%eax
   17a1a:	3b 45 08             	cmp    0x8(%ebp),%eax
   17a1d:	7e 9d                	jle    179bc <progDE+0x9a>
			}
			cwrites( "\n" );
   17a1f:	83 ec 0c             	sub    $0xc,%esp
   17a22:	68 10 be 01 00       	push   $0x1be10
   17a27:	e8 73 29 00 00       	call   1a39f <cwrites>
   17a2c:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	n = swritech( ch );
   17a2f:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17a33:	83 ec 0c             	sub    $0xc,%esp
   17a36:	50                   	push   %eax
   17a37:	e8 a8 29 00 00       	call   1a3e4 <swritech>
   17a3c:	83 c4 10             	add    $0x10,%esp
   17a3f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if( n != 1 ) {
   17a42:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   17a46:	74 2e                	je     17a76 <progDE+0x154>
		usprint( buf, "== %c, write #1 returned %d\n", ch, n );
   17a48:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17a4c:	ff 75 dc             	pushl  -0x24(%ebp)
   17a4f:	50                   	push   %eax
   17a50:	68 12 be 01 00       	push   $0x1be12
   17a55:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17a5b:	50                   	push   %eax
   17a5c:	e8 51 22 00 00       	call   19cb2 <usprint>
   17a61:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   17a64:	83 ec 0c             	sub    $0xc,%esp
   17a67:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17a6d:	50                   	push   %eax
   17a6e:	e8 2c 29 00 00       	call   1a39f <cwrites>
   17a73:	83 c4 10             	add    $0x10,%esp
	}

	// iterate and print the required number of other characters
	for( int i = 0; i < count; ++i ) {
   17a76:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   17a7d:	eb 61                	jmp    17ae0 <progDE+0x1be>
		DELAY(STD);
   17a7f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   17a86:	eb 04                	jmp    17a8c <progDE+0x16a>
   17a88:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   17a8c:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   17a93:	7e f3                	jle    17a88 <progDE+0x166>
		n = swritech( ch );
   17a95:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17a99:	83 ec 0c             	sub    $0xc,%esp
   17a9c:	50                   	push   %eax
   17a9d:	e8 42 29 00 00       	call   1a3e4 <swritech>
   17aa2:	83 c4 10             	add    $0x10,%esp
   17aa5:	89 45 dc             	mov    %eax,-0x24(%ebp)
		if( n != 1 ) {
   17aa8:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   17aac:	74 2e                	je     17adc <progDE+0x1ba>
			usprint( buf, "== %c, write #2 returned %d\n", ch, n );
   17aae:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17ab2:	ff 75 dc             	pushl  -0x24(%ebp)
   17ab5:	50                   	push   %eax
   17ab6:	68 2f be 01 00       	push   $0x1be2f
   17abb:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17ac1:	50                   	push   %eax
   17ac2:	e8 eb 21 00 00       	call   19cb2 <usprint>
   17ac7:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17aca:	83 ec 0c             	sub    $0xc,%esp
   17acd:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17ad3:	50                   	push   %eax
   17ad4:	e8 c6 28 00 00       	call   1a39f <cwrites>
   17ad9:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   17adc:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   17ae0:	8b 45 e8             	mov    -0x18(%ebp),%eax
   17ae3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   17ae6:	7c 97                	jl     17a7f <progDE+0x15d>
		}
	}

	// all done!
	return( 0 );
   17ae8:	b8 00 00 00 00       	mov    $0x0,%eax
}
   17aed:	c9                   	leave  
   17aee:	c3                   	ret    

00017aef <progFG>:
**	 where x is the ID character
**		   n is the iteration count
**		   s is the sleep time in seconds
*/

USERMAIN( progFG ) {
   17aef:	55                   	push   %ebp
   17af0:	89 e5                	mov    %esp,%ebp
   17af2:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   17af8:	8b 45 0c             	mov    0xc(%ebp),%eax
   17afb:	8b 00                	mov    (%eax),%eax
   17afd:	85 c0                	test   %eax,%eax
   17aff:	74 07                	je     17b08 <progFG+0x19>
   17b01:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b04:	8b 00                	mov    (%eax),%eax
   17b06:	eb 05                	jmp    17b0d <progFG+0x1e>
   17b08:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   17b0d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	char ch = '3';	// default character to print
   17b10:	c6 45 df 33          	movb   $0x33,-0x21(%ebp)
	int nap = 10;	// default sleep time
   17b14:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
	int count = 30;	// iteration count
   17b1b:	c7 45 f0 1e 00 00 00 	movl   $0x1e,-0x10(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   17b22:	8b 45 08             	mov    0x8(%ebp),%eax
   17b25:	83 f8 03             	cmp    $0x3,%eax
   17b28:	74 25                	je     17b4f <progFG+0x60>
   17b2a:	83 f8 04             	cmp    $0x4,%eax
   17b2d:	74 07                	je     17b36 <progFG+0x47>
   17b2f:	83 f8 02             	cmp    $0x2,%eax
   17b32:	74 34                	je     17b68 <progFG+0x79>
   17b34:	eb 45                	jmp    17b7b <progFG+0x8c>
	case 4:	nap = ustr2int( argv[3], 10 );
   17b36:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b39:	83 c0 0c             	add    $0xc,%eax
   17b3c:	8b 00                	mov    (%eax),%eax
   17b3e:	83 ec 08             	sub    $0x8,%esp
   17b41:	6a 0a                	push   $0xa
   17b43:	50                   	push   %eax
   17b44:	e8 de 23 00 00       	call   19f27 <ustr2int>
   17b49:	83 c4 10             	add    $0x10,%esp
   17b4c:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   17b4f:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b52:	83 c0 08             	add    $0x8,%eax
   17b55:	8b 00                	mov    (%eax),%eax
   17b57:	83 ec 08             	sub    $0x8,%esp
   17b5a:	6a 0a                	push   $0xa
   17b5c:	50                   	push   %eax
   17b5d:	e8 c5 23 00 00       	call   19f27 <ustr2int>
   17b62:	83 c4 10             	add    $0x10,%esp
   17b65:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17b68:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b6b:	83 c0 04             	add    $0x4,%eax
   17b6e:	8b 00                	mov    (%eax),%eax
   17b70:	0f b6 00             	movzbl (%eax),%eax
   17b73:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   17b76:	e9 a8 00 00 00       	jmp    17c23 <progFG+0x134>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   17b7b:	ff 75 08             	pushl  0x8(%ebp)
   17b7e:	ff 75 e4             	pushl  -0x1c(%ebp)
   17b81:	68 f1 bd 01 00       	push   $0x1bdf1
   17b86:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17b8c:	50                   	push   %eax
   17b8d:	e8 20 21 00 00       	call   19cb2 <usprint>
   17b92:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17b95:	83 ec 0c             	sub    $0xc,%esp
   17b98:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17b9e:	50                   	push   %eax
   17b9f:	e8 fb 27 00 00       	call   1a39f <cwrites>
   17ba4:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17ba7:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   17bae:	eb 5b                	jmp    17c0b <progFG+0x11c>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   17bb0:	8b 45 08             	mov    0x8(%ebp),%eax
   17bb3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17bba:	8b 45 0c             	mov    0xc(%ebp),%eax
   17bbd:	01 d0                	add    %edx,%eax
   17bbf:	8b 00                	mov    (%eax),%eax
   17bc1:	85 c0                	test   %eax,%eax
   17bc3:	74 13                	je     17bd8 <progFG+0xe9>
   17bc5:	8b 45 08             	mov    0x8(%ebp),%eax
   17bc8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17bcf:	8b 45 0c             	mov    0xc(%ebp),%eax
   17bd2:	01 d0                	add    %edx,%eax
   17bd4:	8b 00                	mov    (%eax),%eax
   17bd6:	eb 05                	jmp    17bdd <progFG+0xee>
   17bd8:	b8 05 be 01 00       	mov    $0x1be05,%eax
   17bdd:	83 ec 04             	sub    $0x4,%esp
   17be0:	50                   	push   %eax
   17be1:	68 0c be 01 00       	push   $0x1be0c
   17be6:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17bec:	50                   	push   %eax
   17bed:	e8 c0 20 00 00       	call   19cb2 <usprint>
   17bf2:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17bf5:	83 ec 0c             	sub    $0xc,%esp
   17bf8:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17bfe:	50                   	push   %eax
   17bff:	e8 9b 27 00 00       	call   1a39f <cwrites>
   17c04:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17c07:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   17c0b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   17c0e:	3b 45 08             	cmp    0x8(%ebp),%eax
   17c11:	7e 9d                	jle    17bb0 <progFG+0xc1>
			}
			cwrites( "\n" );
   17c13:	83 ec 0c             	sub    $0xc,%esp
   17c16:	68 10 be 01 00       	push   $0x1be10
   17c1b:	e8 7f 27 00 00       	call   1a39f <cwrites>
   17c20:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int n = swritech( ch );
   17c23:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
   17c27:	0f be c0             	movsbl %al,%eax
   17c2a:	83 ec 0c             	sub    $0xc,%esp
   17c2d:	50                   	push   %eax
   17c2e:	e8 b1 27 00 00       	call   1a3e4 <swritech>
   17c33:	83 c4 10             	add    $0x10,%esp
   17c36:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if( n != 1 ) {
   17c39:	83 7d e0 01          	cmpl   $0x1,-0x20(%ebp)
   17c3d:	74 31                	je     17c70 <progFG+0x181>
		usprint( buf, "=== %c, write #1 returned %d\n", ch, n );
   17c3f:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
   17c43:	0f be c0             	movsbl %al,%eax
   17c46:	ff 75 e0             	pushl  -0x20(%ebp)
   17c49:	50                   	push   %eax
   17c4a:	68 6b be 01 00       	push   $0x1be6b
   17c4f:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17c55:	50                   	push   %eax
   17c56:	e8 57 20 00 00       	call   19cb2 <usprint>
   17c5b:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   17c5e:	83 ec 0c             	sub    $0xc,%esp
   17c61:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17c67:	50                   	push   %eax
   17c68:	e8 32 27 00 00       	call   1a39f <cwrites>
   17c6d:	83 c4 10             	add    $0x10,%esp
	}

	write( CHAN_SIO, &ch, 1 );
   17c70:	83 ec 04             	sub    $0x4,%esp
   17c73:	6a 01                	push   $0x1
   17c75:	8d 45 df             	lea    -0x21(%ebp),%eax
   17c78:	50                   	push   %eax
   17c79:	6a 01                	push   $0x1
   17c7b:	e8 b0 f2 ff ff       	call   16f30 <write>
   17c80:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   17c83:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   17c8a:	eb 2c                	jmp    17cb8 <progFG+0x1c9>
		sleep( SEC_TO_MS(nap) );
   17c8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17c8f:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   17c95:	83 ec 0c             	sub    $0xc,%esp
   17c98:	50                   	push   %eax
   17c99:	e8 ca f2 ff ff       	call   16f68 <sleep>
   17c9e:	83 c4 10             	add    $0x10,%esp
		write( CHAN_SIO, &ch, 1 );
   17ca1:	83 ec 04             	sub    $0x4,%esp
   17ca4:	6a 01                	push   $0x1
   17ca6:	8d 45 df             	lea    -0x21(%ebp),%eax
   17ca9:	50                   	push   %eax
   17caa:	6a 01                	push   $0x1
   17cac:	e8 7f f2 ff ff       	call   16f30 <write>
   17cb1:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   17cb4:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   17cb8:	8b 45 e8             	mov    -0x18(%ebp),%eax
   17cbb:	3b 45 f0             	cmp    -0x10(%ebp),%eax
   17cbe:	7c cc                	jl     17c8c <progFG+0x19d>
	}

	exit( 0 );
   17cc0:	83 ec 0c             	sub    $0xc,%esp
   17cc3:	6a 00                	push   $0x0
   17cc5:	e8 3e f2 ff ff       	call   16f08 <exit>
   17cca:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   17ccd:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   17cd2:	c9                   	leave  
   17cd3:	c3                   	ret    

00017cd4 <progH>:
** Invoked as:  progH  x  n
**	 where x is the ID character
**		   n is the number of children to spawn
*/

USERMAIN( progH ) {
   17cd4:	55                   	push   %ebp
   17cd5:	89 e5                	mov    %esp,%ebp
   17cd7:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   17cdd:	8b 45 0c             	mov    0xc(%ebp),%eax
   17ce0:	8b 00                	mov    (%eax),%eax
   17ce2:	85 c0                	test   %eax,%eax
   17ce4:	74 07                	je     17ced <progH+0x19>
   17ce6:	8b 45 0c             	mov    0xc(%ebp),%eax
   17ce9:	8b 00                	mov    (%eax),%eax
   17ceb:	eb 05                	jmp    17cf2 <progH+0x1e>
   17ced:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   17cf2:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int32_t ret = 0;  // return value
   17cf5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	int count = 5;	  // child count
   17cfc:	c7 45 f0 05 00 00 00 	movl   $0x5,-0x10(%ebp)
	char ch = 'h';	  // default character to print
   17d03:	c6 45 ef 68          	movb   $0x68,-0x11(%ebp)
	char buf[128];
	int whom;

	// process the argument(s)
	switch( argc ) {
   17d07:	8b 45 08             	mov    0x8(%ebp),%eax
   17d0a:	83 f8 02             	cmp    $0x2,%eax
   17d0d:	74 1e                	je     17d2d <progH+0x59>
   17d0f:	83 f8 03             	cmp    $0x3,%eax
   17d12:	75 2c                	jne    17d40 <progH+0x6c>
	case 3:	count = ustr2int( argv[2], 10 );
   17d14:	8b 45 0c             	mov    0xc(%ebp),%eax
   17d17:	83 c0 08             	add    $0x8,%eax
   17d1a:	8b 00                	mov    (%eax),%eax
   17d1c:	83 ec 08             	sub    $0x8,%esp
   17d1f:	6a 0a                	push   $0xa
   17d21:	50                   	push   %eax
   17d22:	e8 00 22 00 00       	call   19f27 <ustr2int>
   17d27:	83 c4 10             	add    $0x10,%esp
   17d2a:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17d2d:	8b 45 0c             	mov    0xc(%ebp),%eax
   17d30:	83 c0 04             	add    $0x4,%eax
   17d33:	8b 00                	mov    (%eax),%eax
   17d35:	0f b6 00             	movzbl (%eax),%eax
   17d38:	88 45 ef             	mov    %al,-0x11(%ebp)
			break;
   17d3b:	e9 a8 00 00 00       	jmp    17de8 <progH+0x114>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   17d40:	ff 75 08             	pushl  0x8(%ebp)
   17d43:	ff 75 e0             	pushl  -0x20(%ebp)
   17d46:	68 f1 bd 01 00       	push   $0x1bdf1
   17d4b:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17d51:	50                   	push   %eax
   17d52:	e8 5b 1f 00 00       	call   19cb2 <usprint>
   17d57:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17d5a:	83 ec 0c             	sub    $0xc,%esp
   17d5d:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17d63:	50                   	push   %eax
   17d64:	e8 36 26 00 00       	call   1a39f <cwrites>
   17d69:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17d6c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   17d73:	eb 5b                	jmp    17dd0 <progH+0xfc>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   17d75:	8b 45 08             	mov    0x8(%ebp),%eax
   17d78:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17d7f:	8b 45 0c             	mov    0xc(%ebp),%eax
   17d82:	01 d0                	add    %edx,%eax
   17d84:	8b 00                	mov    (%eax),%eax
   17d86:	85 c0                	test   %eax,%eax
   17d88:	74 13                	je     17d9d <progH+0xc9>
   17d8a:	8b 45 08             	mov    0x8(%ebp),%eax
   17d8d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17d94:	8b 45 0c             	mov    0xc(%ebp),%eax
   17d97:	01 d0                	add    %edx,%eax
   17d99:	8b 00                	mov    (%eax),%eax
   17d9b:	eb 05                	jmp    17da2 <progH+0xce>
   17d9d:	b8 05 be 01 00       	mov    $0x1be05,%eax
   17da2:	83 ec 04             	sub    $0x4,%esp
   17da5:	50                   	push   %eax
   17da6:	68 0c be 01 00       	push   $0x1be0c
   17dab:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17db1:	50                   	push   %eax
   17db2:	e8 fb 1e 00 00       	call   19cb2 <usprint>
   17db7:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17dba:	83 ec 0c             	sub    $0xc,%esp
   17dbd:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17dc3:	50                   	push   %eax
   17dc4:	e8 d6 25 00 00       	call   1a39f <cwrites>
   17dc9:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17dcc:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   17dd0:	8b 45 e8             	mov    -0x18(%ebp),%eax
   17dd3:	3b 45 08             	cmp    0x8(%ebp),%eax
   17dd6:	7e 9d                	jle    17d75 <progH+0xa1>
			}
			cwrites( "\n" );
   17dd8:	83 ec 0c             	sub    $0xc,%esp
   17ddb:	68 10 be 01 00       	push   $0x1be10
   17de0:	e8 ba 25 00 00       	call   1a39f <cwrites>
   17de5:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	swritech( ch );
   17de8:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   17dec:	83 ec 0c             	sub    $0xc,%esp
   17def:	50                   	push   %eax
   17df0:	e8 ef 25 00 00       	call   1a3e4 <swritech>
   17df5:	83 c4 10             	add    $0x10,%esp

	// we spawn user Z and then exit before it can terminate
	// progZ 'Z' 10

	char *argsz[] = { "progZ", "Z", "10", NULL };
   17df8:	c7 85 4c ff ff ff 89 	movl   $0x1be89,-0xb4(%ebp)
   17dff:	be 01 00 
   17e02:	c7 85 50 ff ff ff 8f 	movl   $0x1be8f,-0xb0(%ebp)
   17e09:	be 01 00 
   17e0c:	c7 85 54 ff ff ff 64 	movl   $0x1bb64,-0xac(%ebp)
   17e13:	bb 01 00 
   17e16:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
   17e1d:	00 00 00 

	for( int i = 0; i < count; ++i ) {
   17e20:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   17e27:	eb 57                	jmp    17e80 <progH+0x1ac>

		// spawn a child
		whom = spawn( (uint32_t) progZ, argsz );
   17e29:	ba ba 7e 01 00       	mov    $0x17eba,%edx
   17e2e:	83 ec 08             	sub    $0x8,%esp
   17e31:	8d 85 4c ff ff ff    	lea    -0xb4(%ebp),%eax
   17e37:	50                   	push   %eax
   17e38:	52                   	push   %edx
   17e39:	e8 cb 24 00 00       	call   1a309 <spawn>
   17e3e:	83 c4 10             	add    $0x10,%esp
   17e41:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// our exit status is the number of failed spawn() calls
		if( whom < 0 ) {
   17e44:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   17e48:	79 32                	jns    17e7c <progH+0x1a8>
			usprint( buf, "!! %c spawn() failed, returned %d\n", ch, whom );
   17e4a:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   17e4e:	ff 75 dc             	pushl  -0x24(%ebp)
   17e51:	50                   	push   %eax
   17e52:	68 94 be 01 00       	push   $0x1be94
   17e57:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17e5d:	50                   	push   %eax
   17e5e:	e8 4f 1e 00 00       	call   19cb2 <usprint>
   17e63:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17e66:	83 ec 0c             	sub    $0xc,%esp
   17e69:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17e6f:	50                   	push   %eax
   17e70:	e8 2a 25 00 00       	call   1a39f <cwrites>
   17e75:	83 c4 10             	add    $0x10,%esp
			ret += 1;
   17e78:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
	for( int i = 0; i < count; ++i ) {
   17e7c:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   17e80:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   17e83:	3b 45 f0             	cmp    -0x10(%ebp),%eax
   17e86:	7c a1                	jl     17e29 <progH+0x155>
		}
	}

	// yield the CPU so that our child(ren) can run
	sleep( 0 );
   17e88:	83 ec 0c             	sub    $0xc,%esp
   17e8b:	6a 00                	push   $0x0
   17e8d:	e8 d6 f0 ff ff       	call   16f68 <sleep>
   17e92:	83 c4 10             	add    $0x10,%esp

	// announce our departure
	swritech( ch );
   17e95:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   17e99:	83 ec 0c             	sub    $0xc,%esp
   17e9c:	50                   	push   %eax
   17e9d:	e8 42 25 00 00       	call   1a3e4 <swritech>
   17ea2:	83 c4 10             	add    $0x10,%esp

	exit( ret );
   17ea5:	83 ec 0c             	sub    $0xc,%esp
   17ea8:	ff 75 f4             	pushl  -0xc(%ebp)
   17eab:	e8 58 f0 ff ff       	call   16f08 <exit>
   17eb0:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   17eb3:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   17eb8:	c9                   	leave  
   17eb9:	c3                   	ret    

00017eba <progZ>:
** Invoked as:	progZ  x  [ n ]
**	 where x is the ID character
**		   n is the iteration count (defaults to 10)
*/

USERMAIN( progZ ) {
   17eba:	55                   	push   %ebp
   17ebb:	89 e5                	mov    %esp,%ebp
   17ebd:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   17ec3:	8b 45 0c             	mov    0xc(%ebp),%eax
   17ec6:	8b 00                	mov    (%eax),%eax
   17ec8:	85 c0                	test   %eax,%eax
   17eca:	74 07                	je     17ed3 <progZ+0x19>
   17ecc:	8b 45 0c             	mov    0xc(%ebp),%eax
   17ecf:	8b 00                	mov    (%eax),%eax
   17ed1:	eb 05                	jmp    17ed8 <progZ+0x1e>
   17ed3:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   17ed8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 10;	  // default iteration count
   17edb:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
	char ch = 'z';	  // default character to print
   17ee2:	c6 45 f3 7a          	movb   $0x7a,-0xd(%ebp)
	char buf[128];

	(void) name;

	// process the command-line arguments
	switch( argc ) {
   17ee6:	8b 45 08             	mov    0x8(%ebp),%eax
   17ee9:	83 f8 02             	cmp    $0x2,%eax
   17eec:	74 1e                	je     17f0c <progZ+0x52>
   17eee:	83 f8 03             	cmp    $0x3,%eax
   17ef1:	75 2c                	jne    17f1f <progZ+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   17ef3:	8b 45 0c             	mov    0xc(%ebp),%eax
   17ef6:	83 c0 08             	add    $0x8,%eax
   17ef9:	8b 00                	mov    (%eax),%eax
   17efb:	83 ec 08             	sub    $0x8,%esp
   17efe:	6a 0a                	push   $0xa
   17f00:	50                   	push   %eax
   17f01:	e8 21 20 00 00       	call   19f27 <ustr2int>
   17f06:	83 c4 10             	add    $0x10,%esp
   17f09:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17f0c:	8b 45 0c             	mov    0xc(%ebp),%eax
   17f0f:	83 c0 04             	add    $0x4,%eax
   17f12:	8b 00                	mov    (%eax),%eax
   17f14:	0f b6 00             	movzbl (%eax),%eax
   17f17:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   17f1a:	e9 a8 00 00 00       	jmp    17fc7 <progZ+0x10d>
	default:
			usprint( buf, "?: argc %d, args: ", argc );
   17f1f:	83 ec 04             	sub    $0x4,%esp
   17f22:	ff 75 08             	pushl  0x8(%ebp)
   17f25:	68 b7 be 01 00       	push   $0x1beb7
   17f2a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17f30:	50                   	push   %eax
   17f31:	e8 7c 1d 00 00       	call   19cb2 <usprint>
   17f36:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17f39:	83 ec 0c             	sub    $0xc,%esp
   17f3c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17f42:	50                   	push   %eax
   17f43:	e8 57 24 00 00       	call   1a39f <cwrites>
   17f48:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17f4b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   17f52:	eb 5b                	jmp    17faf <progZ+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   17f54:	8b 45 08             	mov    0x8(%ebp),%eax
   17f57:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17f5e:	8b 45 0c             	mov    0xc(%ebp),%eax
   17f61:	01 d0                	add    %edx,%eax
   17f63:	8b 00                	mov    (%eax),%eax
   17f65:	85 c0                	test   %eax,%eax
   17f67:	74 13                	je     17f7c <progZ+0xc2>
   17f69:	8b 45 08             	mov    0x8(%ebp),%eax
   17f6c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17f73:	8b 45 0c             	mov    0xc(%ebp),%eax
   17f76:	01 d0                	add    %edx,%eax
   17f78:	8b 00                	mov    (%eax),%eax
   17f7a:	eb 05                	jmp    17f81 <progZ+0xc7>
   17f7c:	b8 05 be 01 00       	mov    $0x1be05,%eax
   17f81:	83 ec 04             	sub    $0x4,%esp
   17f84:	50                   	push   %eax
   17f85:	68 0c be 01 00       	push   $0x1be0c
   17f8a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17f90:	50                   	push   %eax
   17f91:	e8 1c 1d 00 00       	call   19cb2 <usprint>
   17f96:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17f99:	83 ec 0c             	sub    $0xc,%esp
   17f9c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17fa2:	50                   	push   %eax
   17fa3:	e8 f7 23 00 00       	call   1a39f <cwrites>
   17fa8:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17fab:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   17faf:	8b 45 ec             	mov    -0x14(%ebp),%eax
   17fb2:	3b 45 08             	cmp    0x8(%ebp),%eax
   17fb5:	7e 9d                	jle    17f54 <progZ+0x9a>
			}
			cwrites( "\n" );
   17fb7:	83 ec 0c             	sub    $0xc,%esp
   17fba:	68 10 be 01 00       	push   $0x1be10
   17fbf:	e8 db 23 00 00       	call   1a39f <cwrites>
   17fc4:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int pid = getpid();
   17fc7:	e8 6c ef ff ff       	call   16f38 <getpid>
   17fcc:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d]", ch, pid );
   17fcf:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17fd3:	ff 75 dc             	pushl  -0x24(%ebp)
   17fd6:	50                   	push   %eax
   17fd7:	68 ca be 01 00       	push   $0x1beca
   17fdc:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17fe2:	50                   	push   %eax
   17fe3:	e8 ca 1c 00 00       	call   19cb2 <usprint>
   17fe8:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   17feb:	83 ec 0c             	sub    $0xc,%esp
   17fee:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17ff4:	50                   	push   %eax
   17ff5:	e8 0b 24 00 00       	call   1a405 <swrites>
   17ffa:	83 c4 10             	add    $0x10,%esp

	// iterate for a while; occasionally yield the CPU
	for( int i = 0; i < count ; ++i ) {
   17ffd:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18004:	eb 5f                	jmp    18065 <progZ+0x1ab>
		usprint( buf, " %c[%d]", ch, i );
   18006:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   1800a:	ff 75 e8             	pushl  -0x18(%ebp)
   1800d:	50                   	push   %eax
   1800e:	68 ca be 01 00       	push   $0x1beca
   18013:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18019:	50                   	push   %eax
   1801a:	e8 93 1c 00 00       	call   19cb2 <usprint>
   1801f:	83 c4 10             	add    $0x10,%esp
		swrites( buf );
   18022:	83 ec 0c             	sub    $0xc,%esp
   18025:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1802b:	50                   	push   %eax
   1802c:	e8 d4 23 00 00       	call   1a405 <swrites>
   18031:	83 c4 10             	add    $0x10,%esp
		DELAY(STD);
   18034:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   1803b:	eb 04                	jmp    18041 <progZ+0x187>
   1803d:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   18041:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   18048:	7e f3                	jle    1803d <progZ+0x183>
		if( i & 1 ) {
   1804a:	8b 45 e8             	mov    -0x18(%ebp),%eax
   1804d:	83 e0 01             	and    $0x1,%eax
   18050:	85 c0                	test   %eax,%eax
   18052:	74 0d                	je     18061 <progZ+0x1a7>
			sleep( 0 );
   18054:	83 ec 0c             	sub    $0xc,%esp
   18057:	6a 00                	push   $0x0
   18059:	e8 0a ef ff ff       	call   16f68 <sleep>
   1805e:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   18061:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18065:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18068:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   1806b:	7c 99                	jl     18006 <progZ+0x14c>
		}
	}

	exit( 0 );
   1806d:	83 ec 0c             	sub    $0xc,%esp
   18070:	6a 00                	push   $0x0
   18072:	e8 91 ee ff ff       	call   16f08 <exit>
   18077:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   1807a:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   1807f:	c9                   	leave  
   18080:	c3                   	ret    

00018081 <progI>:
** Invoked as:  progI [ x [ n ] ]
**	 where x is the ID character (defaults to 'i')
**		   n is the number of children to spawn (defaults to 5)
*/

USERMAIN( progI ) {
   18081:	55                   	push   %ebp
   18082:	89 e5                	mov    %esp,%ebp
   18084:	81 ec 98 01 00 00    	sub    $0x198,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   1808a:	8b 45 0c             	mov    0xc(%ebp),%eax
   1808d:	8b 00                	mov    (%eax),%eax
   1808f:	85 c0                	test   %eax,%eax
   18091:	74 07                	je     1809a <progI+0x19>
   18093:	8b 45 0c             	mov    0xc(%ebp),%eax
   18096:	8b 00                	mov    (%eax),%eax
   18098:	eb 05                	jmp    1809f <progI+0x1e>
   1809a:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   1809f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 5;	  // default child count
   180a2:	c7 45 f4 05 00 00 00 	movl   $0x5,-0xc(%ebp)
	char ch = 'i';	  // default character to print
   180a9:	c6 45 cf 69          	movb   $0x69,-0x31(%ebp)
	int nap = 5;	  // nap time
   180ad:	c7 45 dc 05 00 00 00 	movl   $0x5,-0x24(%ebp)
	char buf[128];
	char ch2[] = "*?*";
   180b4:	c7 85 4b ff ff ff 2a 	movl   $0x2a3f2a,-0xb5(%ebp)
   180bb:	3f 2a 00 
	uint_t children[MAX_CHILDREN];
	int nkids = 0;
   180be:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

	// process the command-line arguments
	switch( argc ) {
   180c5:	8b 45 08             	mov    0x8(%ebp),%eax
   180c8:	83 f8 02             	cmp    $0x2,%eax
   180cb:	74 29                	je     180f6 <progI+0x75>
   180cd:	83 f8 03             	cmp    $0x3,%eax
   180d0:	74 0b                	je     180dd <progI+0x5c>
   180d2:	83 f8 01             	cmp    $0x1,%eax
   180d5:	0f 84 d8 00 00 00    	je     181b3 <progI+0x132>
   180db:	eb 2c                	jmp    18109 <progI+0x88>
	case 3:	count = ustr2int( argv[2], 10 );
   180dd:	8b 45 0c             	mov    0xc(%ebp),%eax
   180e0:	83 c0 08             	add    $0x8,%eax
   180e3:	8b 00                	mov    (%eax),%eax
   180e5:	83 ec 08             	sub    $0x8,%esp
   180e8:	6a 0a                	push   $0xa
   180ea:	50                   	push   %eax
   180eb:	e8 37 1e 00 00       	call   19f27 <ustr2int>
   180f0:	83 c4 10             	add    $0x10,%esp
   180f3:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   180f6:	8b 45 0c             	mov    0xc(%ebp),%eax
   180f9:	83 c0 04             	add    $0x4,%eax
   180fc:	8b 00                	mov    (%eax),%eax
   180fe:	0f b6 00             	movzbl (%eax),%eax
   18101:	88 45 cf             	mov    %al,-0x31(%ebp)
			break;
   18104:	e9 ab 00 00 00       	jmp    181b4 <progI+0x133>
	case 1:	// just use the defaults
			break;
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18109:	ff 75 08             	pushl  0x8(%ebp)
   1810c:	ff 75 e0             	pushl  -0x20(%ebp)
   1810f:	68 f1 bd 01 00       	push   $0x1bdf1
   18114:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   1811a:	50                   	push   %eax
   1811b:	e8 92 1b 00 00       	call   19cb2 <usprint>
   18120:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18123:	83 ec 0c             	sub    $0xc,%esp
   18126:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   1812c:	50                   	push   %eax
   1812d:	e8 6d 22 00 00       	call   1a39f <cwrites>
   18132:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18135:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   1813c:	eb 5b                	jmp    18199 <progI+0x118>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   1813e:	8b 45 08             	mov    0x8(%ebp),%eax
   18141:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18148:	8b 45 0c             	mov    0xc(%ebp),%eax
   1814b:	01 d0                	add    %edx,%eax
   1814d:	8b 00                	mov    (%eax),%eax
   1814f:	85 c0                	test   %eax,%eax
   18151:	74 13                	je     18166 <progI+0xe5>
   18153:	8b 45 08             	mov    0x8(%ebp),%eax
   18156:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1815d:	8b 45 0c             	mov    0xc(%ebp),%eax
   18160:	01 d0                	add    %edx,%eax
   18162:	8b 00                	mov    (%eax),%eax
   18164:	eb 05                	jmp    1816b <progI+0xea>
   18166:	b8 05 be 01 00       	mov    $0x1be05,%eax
   1816b:	83 ec 04             	sub    $0x4,%esp
   1816e:	50                   	push   %eax
   1816f:	68 0c be 01 00       	push   $0x1be0c
   18174:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   1817a:	50                   	push   %eax
   1817b:	e8 32 1b 00 00       	call   19cb2 <usprint>
   18180:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   18183:	83 ec 0c             	sub    $0xc,%esp
   18186:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   1818c:	50                   	push   %eax
   1818d:	e8 0d 22 00 00       	call   1a39f <cwrites>
   18192:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18195:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18199:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1819c:	3b 45 08             	cmp    0x8(%ebp),%eax
   1819f:	7e 9d                	jle    1813e <progI+0xbd>
			}
			cwrites( "\n" );
   181a1:	83 ec 0c             	sub    $0xc,%esp
   181a4:	68 10 be 01 00       	push   $0x1be10
   181a9:	e8 f1 21 00 00       	call   1a39f <cwrites>
   181ae:	83 c4 10             	add    $0x10,%esp
   181b1:	eb 01                	jmp    181b4 <progI+0x133>
			break;
   181b3:	90                   	nop
	}

	// secondary output (for indicating errors)
	ch2[1] = ch;
   181b4:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   181b8:	88 85 4c ff ff ff    	mov    %al,-0xb4(%ebp)

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   181be:	83 ec 04             	sub    $0x4,%esp
   181c1:	6a 01                	push   $0x1
   181c3:	8d 45 cf             	lea    -0x31(%ebp),%eax
   181c6:	50                   	push   %eax
   181c7:	6a 01                	push   $0x1
   181c9:	e8 62 ed ff ff       	call   16f30 <write>
   181ce:	83 c4 10             	add    $0x10,%esp

	// set up the argument vector
	// we run:	progW 10 5

	char *argsw[] = { "progW", "W", "10", "5", NULL };
   181d1:	c7 85 6c fe ff ff d2 	movl   $0x1bed2,-0x194(%ebp)
   181d8:	be 01 00 
   181db:	c7 85 70 fe ff ff e6 	movl   $0x1bbe6,-0x190(%ebp)
   181e2:	bb 01 00 
   181e5:	c7 85 74 fe ff ff 64 	movl   $0x1bb64,-0x18c(%ebp)
   181ec:	bb 01 00 
   181ef:	c7 85 78 fe ff ff 93 	movl   $0x1bb93,-0x188(%ebp)
   181f6:	bb 01 00 
   181f9:	c7 85 7c fe ff ff 00 	movl   $0x0,-0x184(%ebp)
   18200:	00 00 00 

	for( int i = 0; i < count; ++i ) {
   18203:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   1820a:	eb 5f                	jmp    1826b <progI+0x1ea>
		int whom = spawn( (uint32_t) progW, argsw );
   1820c:	ba f4 83 01 00       	mov    $0x183f4,%edx
   18211:	83 ec 08             	sub    $0x8,%esp
   18214:	8d 85 6c fe ff ff    	lea    -0x194(%ebp),%eax
   1821a:	50                   	push   %eax
   1821b:	52                   	push   %edx
   1821c:	e8 e8 20 00 00       	call   1a309 <spawn>
   18221:	83 c4 10             	add    $0x10,%esp
   18224:	89 45 d0             	mov    %eax,-0x30(%ebp)
		if( whom < 0 ) {
   18227:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
   1822b:	79 14                	jns    18241 <progI+0x1c0>
			swrites( ch2 );
   1822d:	83 ec 0c             	sub    $0xc,%esp
   18230:	8d 85 4b ff ff ff    	lea    -0xb5(%ebp),%eax
   18236:	50                   	push   %eax
   18237:	e8 c9 21 00 00       	call   1a405 <swrites>
   1823c:	83 c4 10             	add    $0x10,%esp
   1823f:	eb 26                	jmp    18267 <progI+0x1e6>
		} else {
			swritech( ch );
   18241:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   18245:	0f be c0             	movsbl %al,%eax
   18248:	83 ec 0c             	sub    $0xc,%esp
   1824b:	50                   	push   %eax
   1824c:	e8 93 21 00 00       	call   1a3e4 <swritech>
   18251:	83 c4 10             	add    $0x10,%esp
			children[nkids++] = whom;
   18254:	8b 45 f0             	mov    -0x10(%ebp),%eax
   18257:	8d 50 01             	lea    0x1(%eax),%edx
   1825a:	89 55 f0             	mov    %edx,-0x10(%ebp)
   1825d:	8b 55 d0             	mov    -0x30(%ebp),%edx
   18260:	89 94 85 80 fe ff ff 	mov    %edx,-0x180(%ebp,%eax,4)
	for( int i = 0; i < count; ++i ) {
   18267:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   1826b:	8b 45 e8             	mov    -0x18(%ebp),%eax
   1826e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18271:	7c 99                	jl     1820c <progI+0x18b>
		}
	}

	// let the children start
	sleep( SEC_TO_MS(nap) );
   18273:	8b 45 dc             	mov    -0x24(%ebp),%eax
   18276:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   1827c:	83 ec 0c             	sub    $0xc,%esp
   1827f:	50                   	push   %eax
   18280:	e8 e3 ec ff ff       	call   16f68 <sleep>
   18285:	83 c4 10             	add    $0x10,%esp

	// kill two of them
	int32_t status = kill( children[1] );
   18288:	8b 85 84 fe ff ff    	mov    -0x17c(%ebp),%eax
   1828e:	83 ec 0c             	sub    $0xc,%esp
   18291:	50                   	push   %eax
   18292:	e8 c9 ec ff ff       	call   16f60 <kill>
   18297:	83 c4 10             	add    $0x10,%esp
   1829a:	89 45 d8             	mov    %eax,-0x28(%ebp)
	if( status ) {
   1829d:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   182a1:	74 45                	je     182e8 <progI+0x267>
		usprint( buf, "!! %c: kill(%d) status %d\n", ch, children[1], status );
   182a3:	8b 95 84 fe ff ff    	mov    -0x17c(%ebp),%edx
   182a9:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   182ad:	0f be c0             	movsbl %al,%eax
   182b0:	83 ec 0c             	sub    $0xc,%esp
   182b3:	ff 75 d8             	pushl  -0x28(%ebp)
   182b6:	52                   	push   %edx
   182b7:	50                   	push   %eax
   182b8:	68 d8 be 01 00       	push   $0x1bed8
   182bd:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   182c3:	50                   	push   %eax
   182c4:	e8 e9 19 00 00       	call   19cb2 <usprint>
   182c9:	83 c4 20             	add    $0x20,%esp
		cwrites( buf );
   182cc:	83 ec 0c             	sub    $0xc,%esp
   182cf:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   182d5:	50                   	push   %eax
   182d6:	e8 c4 20 00 00       	call   1a39f <cwrites>
   182db:	83 c4 10             	add    $0x10,%esp
		children[1] = -42;
   182de:	c7 85 84 fe ff ff d6 	movl   $0xffffffd6,-0x17c(%ebp)
   182e5:	ff ff ff 
	}
	status = kill( children[3] );
   182e8:	8b 85 8c fe ff ff    	mov    -0x174(%ebp),%eax
   182ee:	83 ec 0c             	sub    $0xc,%esp
   182f1:	50                   	push   %eax
   182f2:	e8 69 ec ff ff       	call   16f60 <kill>
   182f7:	83 c4 10             	add    $0x10,%esp
   182fa:	89 45 d8             	mov    %eax,-0x28(%ebp)
	if( status ) {
   182fd:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   18301:	74 45                	je     18348 <progI+0x2c7>
		usprint( buf, "!! %c: kill(%d) status %d\n", ch, children[3], status );
   18303:	8b 95 8c fe ff ff    	mov    -0x174(%ebp),%edx
   18309:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   1830d:	0f be c0             	movsbl %al,%eax
   18310:	83 ec 0c             	sub    $0xc,%esp
   18313:	ff 75 d8             	pushl  -0x28(%ebp)
   18316:	52                   	push   %edx
   18317:	50                   	push   %eax
   18318:	68 d8 be 01 00       	push   $0x1bed8
   1831d:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   18323:	50                   	push   %eax
   18324:	e8 89 19 00 00       	call   19cb2 <usprint>
   18329:	83 c4 20             	add    $0x20,%esp
		cwrites( buf );
   1832c:	83 ec 0c             	sub    $0xc,%esp
   1832f:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   18335:	50                   	push   %eax
   18336:	e8 64 20 00 00       	call   1a39f <cwrites>
   1833b:	83 c4 10             	add    $0x10,%esp
		children[3] = -42;
   1833e:	c7 85 8c fe ff ff d6 	movl   $0xffffffd6,-0x174(%ebp)
   18345:	ff ff ff 
	}

	// collect child information
	while( 1 ) {
		int n = waitpid( 0, NULL );
   18348:	83 ec 08             	sub    $0x8,%esp
   1834b:	6a 00                	push   $0x0
   1834d:	6a 00                	push   $0x0
   1834f:	e8 bc eb ff ff       	call   16f10 <waitpid>
   18354:	83 c4 10             	add    $0x10,%esp
   18357:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		if( n == E_NO_CHILDREN ) {
   1835a:	83 7d d4 fc          	cmpl   $0xfffffffc,-0x2c(%ebp)
   1835e:	74 7f                	je     183df <progI+0x35e>
			// all done!
			break;
		}
		for( int i = 0; i < count; ++i ) {
   18360:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   18367:	eb 54                	jmp    183bd <progI+0x33c>
			if( children[i] == n ) {
   18369:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   1836c:	8b 94 85 80 fe ff ff 	mov    -0x180(%ebp,%eax,4),%edx
   18373:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   18376:	39 c2                	cmp    %eax,%edx
   18378:	75 3f                	jne    183b9 <progI+0x338>
				usprint( buf, "== %c: child %d (%d)\n", ch, i, children[i] );
   1837a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   1837d:	8b 94 85 80 fe ff ff 	mov    -0x180(%ebp,%eax,4),%edx
   18384:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   18388:	0f be c0             	movsbl %al,%eax
   1838b:	83 ec 0c             	sub    $0xc,%esp
   1838e:	52                   	push   %edx
   1838f:	ff 75 e4             	pushl  -0x1c(%ebp)
   18392:	50                   	push   %eax
   18393:	68 f3 be 01 00       	push   $0x1bef3
   18398:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   1839e:	50                   	push   %eax
   1839f:	e8 0e 19 00 00       	call   19cb2 <usprint>
   183a4:	83 c4 20             	add    $0x20,%esp
				cwrites( buf );
   183a7:	83 ec 0c             	sub    $0xc,%esp
   183aa:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   183b0:	50                   	push   %eax
   183b1:	e8 e9 1f 00 00       	call   1a39f <cwrites>
   183b6:	83 c4 10             	add    $0x10,%esp
		for( int i = 0; i < count; ++i ) {
   183b9:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   183bd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   183c0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   183c3:	7c a4                	jl     18369 <progI+0x2e8>
			}
		}
		sleep( SEC_TO_MS(nap) );
   183c5:	8b 45 dc             	mov    -0x24(%ebp),%eax
   183c8:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   183ce:	83 ec 0c             	sub    $0xc,%esp
   183d1:	50                   	push   %eax
   183d2:	e8 91 eb ff ff       	call   16f68 <sleep>
   183d7:	83 c4 10             	add    $0x10,%esp
	while( 1 ) {
   183da:	e9 69 ff ff ff       	jmp    18348 <progI+0x2c7>
			break;
   183df:	90                   	nop
	};

	// let init() clean up after us!

	exit( 0 );
   183e0:	83 ec 0c             	sub    $0xc,%esp
   183e3:	6a 00                	push   $0x0
   183e5:	e8 1e eb ff ff       	call   16f08 <exit>
   183ea:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   183ed:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   183f2:	c9                   	leave  
   183f3:	c3                   	ret    

000183f4 <progW>:
**	 where x is the ID character
**		   n is the iteration count (defaults to 20)
**		   s is the sleep time (defaults to 3 seconds)
*/

USERMAIN( progW ) {
   183f4:	55                   	push   %ebp
   183f5:	89 e5                	mov    %esp,%ebp
   183f7:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   183fd:	8b 45 0c             	mov    0xc(%ebp),%eax
   18400:	8b 00                	mov    (%eax),%eax
   18402:	85 c0                	test   %eax,%eax
   18404:	74 07                	je     1840d <progW+0x19>
   18406:	8b 45 0c             	mov    0xc(%ebp),%eax
   18409:	8b 00                	mov    (%eax),%eax
   1840b:	eb 05                	jmp    18412 <progW+0x1e>
   1840d:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   18412:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int count = 20;	  // default iteration count
   18415:	c7 45 f4 14 00 00 00 	movl   $0x14,-0xc(%ebp)
	char ch = 'w';	  // default character to print
   1841c:	c6 45 db 77          	movb   $0x77,-0x25(%ebp)
	int nap = 3;	  // nap length
   18420:	c7 45 f0 03 00 00 00 	movl   $0x3,-0x10(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   18427:	8b 45 08             	mov    0x8(%ebp),%eax
   1842a:	83 f8 03             	cmp    $0x3,%eax
   1842d:	74 25                	je     18454 <progW+0x60>
   1842f:	83 f8 04             	cmp    $0x4,%eax
   18432:	74 07                	je     1843b <progW+0x47>
   18434:	83 f8 02             	cmp    $0x2,%eax
   18437:	74 34                	je     1846d <progW+0x79>
   18439:	eb 45                	jmp    18480 <progW+0x8c>
	case 4:	nap = ustr2int( argv[3], 10 );
   1843b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1843e:	83 c0 0c             	add    $0xc,%eax
   18441:	8b 00                	mov    (%eax),%eax
   18443:	83 ec 08             	sub    $0x8,%esp
   18446:	6a 0a                	push   $0xa
   18448:	50                   	push   %eax
   18449:	e8 d9 1a 00 00       	call   19f27 <ustr2int>
   1844e:	83 c4 10             	add    $0x10,%esp
   18451:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   18454:	8b 45 0c             	mov    0xc(%ebp),%eax
   18457:	83 c0 08             	add    $0x8,%eax
   1845a:	8b 00                	mov    (%eax),%eax
   1845c:	83 ec 08             	sub    $0x8,%esp
   1845f:	6a 0a                	push   $0xa
   18461:	50                   	push   %eax
   18462:	e8 c0 1a 00 00       	call   19f27 <ustr2int>
   18467:	83 c4 10             	add    $0x10,%esp
   1846a:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   1846d:	8b 45 0c             	mov    0xc(%ebp),%eax
   18470:	83 c0 04             	add    $0x4,%eax
   18473:	8b 00                	mov    (%eax),%eax
   18475:	0f b6 00             	movzbl (%eax),%eax
   18478:	88 45 db             	mov    %al,-0x25(%ebp)
			break;
   1847b:	e9 a8 00 00 00       	jmp    18528 <progW+0x134>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18480:	ff 75 08             	pushl  0x8(%ebp)
   18483:	ff 75 e4             	pushl  -0x1c(%ebp)
   18486:	68 f1 bd 01 00       	push   $0x1bdf1
   1848b:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18491:	50                   	push   %eax
   18492:	e8 1b 18 00 00       	call   19cb2 <usprint>
   18497:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1849a:	83 ec 0c             	sub    $0xc,%esp
   1849d:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   184a3:	50                   	push   %eax
   184a4:	e8 f6 1e 00 00       	call   1a39f <cwrites>
   184a9:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   184ac:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   184b3:	eb 5b                	jmp    18510 <progW+0x11c>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   184b5:	8b 45 08             	mov    0x8(%ebp),%eax
   184b8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   184bf:	8b 45 0c             	mov    0xc(%ebp),%eax
   184c2:	01 d0                	add    %edx,%eax
   184c4:	8b 00                	mov    (%eax),%eax
   184c6:	85 c0                	test   %eax,%eax
   184c8:	74 13                	je     184dd <progW+0xe9>
   184ca:	8b 45 08             	mov    0x8(%ebp),%eax
   184cd:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   184d4:	8b 45 0c             	mov    0xc(%ebp),%eax
   184d7:	01 d0                	add    %edx,%eax
   184d9:	8b 00                	mov    (%eax),%eax
   184db:	eb 05                	jmp    184e2 <progW+0xee>
   184dd:	b8 05 be 01 00       	mov    $0x1be05,%eax
   184e2:	83 ec 04             	sub    $0x4,%esp
   184e5:	50                   	push   %eax
   184e6:	68 0c be 01 00       	push   $0x1be0c
   184eb:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   184f1:	50                   	push   %eax
   184f2:	e8 bb 17 00 00       	call   19cb2 <usprint>
   184f7:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   184fa:	83 ec 0c             	sub    $0xc,%esp
   184fd:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18503:	50                   	push   %eax
   18504:	e8 96 1e 00 00       	call   1a39f <cwrites>
   18509:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1850c:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18510:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18513:	3b 45 08             	cmp    0x8(%ebp),%eax
   18516:	7e 9d                	jle    184b5 <progW+0xc1>
			}
			cwrites( "\n" );
   18518:	83 ec 0c             	sub    $0xc,%esp
   1851b:	68 10 be 01 00       	push   $0x1be10
   18520:	e8 7a 1e 00 00       	call   1a39f <cwrites>
   18525:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int pid = getpid();
   18528:	e8 0b ea ff ff       	call   16f38 <getpid>
   1852d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	uint32_t now = gettime();
   18530:	e8 13 ea ff ff       	call   16f48 <gettime>
   18535:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d,%u]", ch, pid, now );
   18538:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   1853c:	0f be c0             	movsbl %al,%eax
   1853f:	83 ec 0c             	sub    $0xc,%esp
   18542:	ff 75 dc             	pushl  -0x24(%ebp)
   18545:	ff 75 e0             	pushl  -0x20(%ebp)
   18548:	50                   	push   %eax
   18549:	68 09 bf 01 00       	push   $0x1bf09
   1854e:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18554:	50                   	push   %eax
   18555:	e8 58 17 00 00       	call   19cb2 <usprint>
   1855a:	83 c4 20             	add    $0x20,%esp
	swrites( buf );
   1855d:	83 ec 0c             	sub    $0xc,%esp
   18560:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18566:	50                   	push   %eax
   18567:	e8 99 1e 00 00       	call   1a405 <swrites>
   1856c:	83 c4 10             	add    $0x10,%esp

	write( CHAN_SIO, &ch, 1 );
   1856f:	83 ec 04             	sub    $0x4,%esp
   18572:	6a 01                	push   $0x1
   18574:	8d 45 db             	lea    -0x25(%ebp),%eax
   18577:	50                   	push   %eax
   18578:	6a 01                	push   $0x1
   1857a:	e8 b1 e9 ff ff       	call   16f30 <write>
   1857f:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   18582:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18589:	eb 58                	jmp    185e3 <progW+0x1ef>
		now = gettime();
   1858b:	e8 b8 e9 ff ff       	call   16f48 <gettime>
   18590:	89 45 dc             	mov    %eax,-0x24(%ebp)
		usprint( buf, " %c[%d,%u] ", ch, pid, now );
   18593:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   18597:	0f be c0             	movsbl %al,%eax
   1859a:	83 ec 0c             	sub    $0xc,%esp
   1859d:	ff 75 dc             	pushl  -0x24(%ebp)
   185a0:	ff 75 e0             	pushl  -0x20(%ebp)
   185a3:	50                   	push   %eax
   185a4:	68 14 bf 01 00       	push   $0x1bf14
   185a9:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   185af:	50                   	push   %eax
   185b0:	e8 fd 16 00 00       	call   19cb2 <usprint>
   185b5:	83 c4 20             	add    $0x20,%esp
		swrites( buf );
   185b8:	83 ec 0c             	sub    $0xc,%esp
   185bb:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   185c1:	50                   	push   %eax
   185c2:	e8 3e 1e 00 00       	call   1a405 <swrites>
   185c7:	83 c4 10             	add    $0x10,%esp
		sleep( SEC_TO_MS(nap) );
   185ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
   185cd:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   185d3:	83 ec 0c             	sub    $0xc,%esp
   185d6:	50                   	push   %eax
   185d7:	e8 8c e9 ff ff       	call   16f68 <sleep>
   185dc:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   185df:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   185e3:	8b 45 e8             	mov    -0x18(%ebp),%eax
   185e6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   185e9:	7c a0                	jl     1858b <progW+0x197>
	}

	exit( 0 );
   185eb:	83 ec 0c             	sub    $0xc,%esp
   185ee:	6a 00                	push   $0x0
   185f0:	e8 13 e9 ff ff       	call   16f08 <exit>
   185f5:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   185f8:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   185fd:	c9                   	leave  
   185fe:	c3                   	ret    

000185ff <progJ>:
** Invoked as:  progJ  x  [ n ]
**	 where x is the ID character
**		   n is the number of children to spawn (defaults to 2 * N_PROCS)
*/

USERMAIN( progJ ) {
   185ff:	55                   	push   %ebp
   18600:	89 e5                	mov    %esp,%ebp
   18602:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18608:	8b 45 0c             	mov    0xc(%ebp),%eax
   1860b:	8b 00                	mov    (%eax),%eax
   1860d:	85 c0                	test   %eax,%eax
   1860f:	74 07                	je     18618 <progJ+0x19>
   18611:	8b 45 0c             	mov    0xc(%ebp),%eax
   18614:	8b 00                	mov    (%eax),%eax
   18616:	eb 05                	jmp    1861d <progJ+0x1e>
   18618:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   1861d:	89 45 e8             	mov    %eax,-0x18(%ebp)
	int count = 2 * N_PROCS;	// number of children to spawn
   18620:	c7 45 f4 32 00 00 00 	movl   $0x32,-0xc(%ebp)
	char ch = 'j';				// default character to print
   18627:	c6 45 e3 6a          	movb   $0x6a,-0x1d(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   1862b:	8b 45 08             	mov    0x8(%ebp),%eax
   1862e:	83 f8 02             	cmp    $0x2,%eax
   18631:	74 1e                	je     18651 <progJ+0x52>
   18633:	83 f8 03             	cmp    $0x3,%eax
   18636:	75 2c                	jne    18664 <progJ+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   18638:	8b 45 0c             	mov    0xc(%ebp),%eax
   1863b:	83 c0 08             	add    $0x8,%eax
   1863e:	8b 00                	mov    (%eax),%eax
   18640:	83 ec 08             	sub    $0x8,%esp
   18643:	6a 0a                	push   $0xa
   18645:	50                   	push   %eax
   18646:	e8 dc 18 00 00       	call   19f27 <ustr2int>
   1864b:	83 c4 10             	add    $0x10,%esp
   1864e:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18651:	8b 45 0c             	mov    0xc(%ebp),%eax
   18654:	83 c0 04             	add    $0x4,%eax
   18657:	8b 00                	mov    (%eax),%eax
   18659:	0f b6 00             	movzbl (%eax),%eax
   1865c:	88 45 e3             	mov    %al,-0x1d(%ebp)
			break;
   1865f:	e9 a8 00 00 00       	jmp    1870c <progJ+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18664:	ff 75 08             	pushl  0x8(%ebp)
   18667:	ff 75 e8             	pushl  -0x18(%ebp)
   1866a:	68 f1 bd 01 00       	push   $0x1bdf1
   1866f:	8d 85 63 ff ff ff    	lea    -0x9d(%ebp),%eax
   18675:	50                   	push   %eax
   18676:	e8 37 16 00 00       	call   19cb2 <usprint>
   1867b:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1867e:	83 ec 0c             	sub    $0xc,%esp
   18681:	8d 85 63 ff ff ff    	lea    -0x9d(%ebp),%eax
   18687:	50                   	push   %eax
   18688:	e8 12 1d 00 00       	call   1a39f <cwrites>
   1868d:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18690:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   18697:	eb 5b                	jmp    186f4 <progJ+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18699:	8b 45 08             	mov    0x8(%ebp),%eax
   1869c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   186a3:	8b 45 0c             	mov    0xc(%ebp),%eax
   186a6:	01 d0                	add    %edx,%eax
   186a8:	8b 00                	mov    (%eax),%eax
   186aa:	85 c0                	test   %eax,%eax
   186ac:	74 13                	je     186c1 <progJ+0xc2>
   186ae:	8b 45 08             	mov    0x8(%ebp),%eax
   186b1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   186b8:	8b 45 0c             	mov    0xc(%ebp),%eax
   186bb:	01 d0                	add    %edx,%eax
   186bd:	8b 00                	mov    (%eax),%eax
   186bf:	eb 05                	jmp    186c6 <progJ+0xc7>
   186c1:	b8 05 be 01 00       	mov    $0x1be05,%eax
   186c6:	83 ec 04             	sub    $0x4,%esp
   186c9:	50                   	push   %eax
   186ca:	68 0c be 01 00       	push   $0x1be0c
   186cf:	8d 85 63 ff ff ff    	lea    -0x9d(%ebp),%eax
   186d5:	50                   	push   %eax
   186d6:	e8 d7 15 00 00       	call   19cb2 <usprint>
   186db:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   186de:	83 ec 0c             	sub    $0xc,%esp
   186e1:	8d 85 63 ff ff ff    	lea    -0x9d(%ebp),%eax
   186e7:	50                   	push   %eax
   186e8:	e8 b2 1c 00 00       	call   1a39f <cwrites>
   186ed:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   186f0:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   186f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
   186f7:	3b 45 08             	cmp    0x8(%ebp),%eax
   186fa:	7e 9d                	jle    18699 <progJ+0x9a>
			}
			cwrites( "\n" );
   186fc:	83 ec 0c             	sub    $0xc,%esp
   186ff:	68 10 be 01 00       	push   $0x1be10
   18704:	e8 96 1c 00 00       	call   1a39f <cwrites>
   18709:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   1870c:	83 ec 04             	sub    $0x4,%esp
   1870f:	6a 01                	push   $0x1
   18711:	8d 45 e3             	lea    -0x1d(%ebp),%eax
   18714:	50                   	push   %eax
   18715:	6a 01                	push   $0x1
   18717:	e8 14 e8 ff ff       	call   16f30 <write>
   1871c:	83 c4 10             	add    $0x10,%esp

	// set up the command-line arguments
	char *argsy[] = { "progY", "Y", "10", NULL };
   1871f:	c7 85 50 ff ff ff 20 	movl   $0x1bf20,-0xb0(%ebp)
   18726:	bf 01 00 
   18729:	c7 85 54 ff ff ff 26 	movl   $0x1bf26,-0xac(%ebp)
   18730:	bf 01 00 
   18733:	c7 85 58 ff ff ff 64 	movl   $0x1bb64,-0xa8(%ebp)
   1873a:	bb 01 00 
   1873d:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
   18744:	00 00 00 

	for( int i = 0; i < count ; ++i ) {
   18747:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   1874e:	eb 4e                	jmp    1879e <progJ+0x19f>
		int whom = spawn( (uint32_t) progY, argsy );
   18750:	ba ba 87 01 00       	mov    $0x187ba,%edx
   18755:	83 ec 08             	sub    $0x8,%esp
   18758:	8d 85 50 ff ff ff    	lea    -0xb0(%ebp),%eax
   1875e:	50                   	push   %eax
   1875f:	52                   	push   %edx
   18760:	e8 a4 1b 00 00       	call   1a309 <spawn>
   18765:	83 c4 10             	add    $0x10,%esp
   18768:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		if( whom < 0 ) {
   1876b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   1876f:	79 16                	jns    18787 <progJ+0x188>
			write( CHAN_SIO, "!j!", 3 );
   18771:	83 ec 04             	sub    $0x4,%esp
   18774:	6a 03                	push   $0x3
   18776:	68 28 bf 01 00       	push   $0x1bf28
   1877b:	6a 01                	push   $0x1
   1877d:	e8 ae e7 ff ff       	call   16f30 <write>
   18782:	83 c4 10             	add    $0x10,%esp
   18785:	eb 13                	jmp    1879a <progJ+0x19b>
		} else {
			write( CHAN_SIO, &ch, 1 );
   18787:	83 ec 04             	sub    $0x4,%esp
   1878a:	6a 01                	push   $0x1
   1878c:	8d 45 e3             	lea    -0x1d(%ebp),%eax
   1878f:	50                   	push   %eax
   18790:	6a 01                	push   $0x1
   18792:	e8 99 e7 ff ff       	call   16f30 <write>
   18797:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   1879a:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   1879e:	8b 45 ec             	mov    -0x14(%ebp),%eax
   187a1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   187a4:	7c aa                	jl     18750 <progJ+0x151>
		}
	}

	exit( 0 );
   187a6:	83 ec 0c             	sub    $0xc,%esp
   187a9:	6a 00                	push   $0x0
   187ab:	e8 58 e7 ff ff       	call   16f08 <exit>
   187b0:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   187b3:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   187b8:	c9                   	leave  
   187b9:	c3                   	ret    

000187ba <progY>:
** Invoked as:	progY  x  [ n ]
**	 where x is the ID character
**		   n is the iteration count (defaults to 10)
*/

USERMAIN( progY ) {
   187ba:	55                   	push   %ebp
   187bb:	89 e5                	mov    %esp,%ebp
   187bd:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   187c3:	8b 45 0c             	mov    0xc(%ebp),%eax
   187c6:	8b 00                	mov    (%eax),%eax
   187c8:	85 c0                	test   %eax,%eax
   187ca:	74 07                	je     187d3 <progY+0x19>
   187cc:	8b 45 0c             	mov    0xc(%ebp),%eax
   187cf:	8b 00                	mov    (%eax),%eax
   187d1:	eb 05                	jmp    187d8 <progY+0x1e>
   187d3:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   187d8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 10;	  // default iteration count
   187db:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
	char ch = 'y';	  // default character to print
   187e2:	c6 45 f3 79          	movb   $0x79,-0xd(%ebp)
	char buf[128];

	(void) name;

	// process the command-line arguments
	switch( argc ) {
   187e6:	8b 45 08             	mov    0x8(%ebp),%eax
   187e9:	83 f8 02             	cmp    $0x2,%eax
   187ec:	74 1e                	je     1880c <progY+0x52>
   187ee:	83 f8 03             	cmp    $0x3,%eax
   187f1:	75 2c                	jne    1881f <progY+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   187f3:	8b 45 0c             	mov    0xc(%ebp),%eax
   187f6:	83 c0 08             	add    $0x8,%eax
   187f9:	8b 00                	mov    (%eax),%eax
   187fb:	83 ec 08             	sub    $0x8,%esp
   187fe:	6a 0a                	push   $0xa
   18800:	50                   	push   %eax
   18801:	e8 21 17 00 00       	call   19f27 <ustr2int>
   18806:	83 c4 10             	add    $0x10,%esp
   18809:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   1880c:	8b 45 0c             	mov    0xc(%ebp),%eax
   1880f:	83 c0 04             	add    $0x4,%eax
   18812:	8b 00                	mov    (%eax),%eax
   18814:	0f b6 00             	movzbl (%eax),%eax
   18817:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   1881a:	e9 a8 00 00 00       	jmp    188c7 <progY+0x10d>
	default:
			usprint( buf, "?: argc %d, args: ", argc );
   1881f:	83 ec 04             	sub    $0x4,%esp
   18822:	ff 75 08             	pushl  0x8(%ebp)
   18825:	68 b7 be 01 00       	push   $0x1beb7
   1882a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18830:	50                   	push   %eax
   18831:	e8 7c 14 00 00       	call   19cb2 <usprint>
   18836:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18839:	83 ec 0c             	sub    $0xc,%esp
   1883c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18842:	50                   	push   %eax
   18843:	e8 57 1b 00 00       	call   1a39f <cwrites>
   18848:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1884b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18852:	eb 5b                	jmp    188af <progY+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18854:	8b 45 08             	mov    0x8(%ebp),%eax
   18857:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1885e:	8b 45 0c             	mov    0xc(%ebp),%eax
   18861:	01 d0                	add    %edx,%eax
   18863:	8b 00                	mov    (%eax),%eax
   18865:	85 c0                	test   %eax,%eax
   18867:	74 13                	je     1887c <progY+0xc2>
   18869:	8b 45 08             	mov    0x8(%ebp),%eax
   1886c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18873:	8b 45 0c             	mov    0xc(%ebp),%eax
   18876:	01 d0                	add    %edx,%eax
   18878:	8b 00                	mov    (%eax),%eax
   1887a:	eb 05                	jmp    18881 <progY+0xc7>
   1887c:	b8 05 be 01 00       	mov    $0x1be05,%eax
   18881:	83 ec 04             	sub    $0x4,%esp
   18884:	50                   	push   %eax
   18885:	68 0c be 01 00       	push   $0x1be0c
   1888a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18890:	50                   	push   %eax
   18891:	e8 1c 14 00 00       	call   19cb2 <usprint>
   18896:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   18899:	83 ec 0c             	sub    $0xc,%esp
   1889c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   188a2:	50                   	push   %eax
   188a3:	e8 f7 1a 00 00       	call   1a39f <cwrites>
   188a8:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   188ab:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   188af:	8b 45 ec             	mov    -0x14(%ebp),%eax
   188b2:	3b 45 08             	cmp    0x8(%ebp),%eax
   188b5:	7e 9d                	jle    18854 <progY+0x9a>
			}
			cwrites( "\n" );
   188b7:	83 ec 0c             	sub    $0xc,%esp
   188ba:	68 10 be 01 00       	push   $0x1be10
   188bf:	e8 db 1a 00 00       	call   1a39f <cwrites>
   188c4:	83 c4 10             	add    $0x10,%esp
	}

	// report our presence
	int pid = getpid();
   188c7:	e8 6c e6 ff ff       	call   16f38 <getpid>
   188cc:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d]", ch, pid );
   188cf:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   188d3:	ff 75 dc             	pushl  -0x24(%ebp)
   188d6:	50                   	push   %eax
   188d7:	68 ca be 01 00       	push   $0x1beca
   188dc:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   188e2:	50                   	push   %eax
   188e3:	e8 ca 13 00 00       	call   19cb2 <usprint>
   188e8:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   188eb:	83 ec 0c             	sub    $0xc,%esp
   188ee:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   188f4:	50                   	push   %eax
   188f5:	e8 0b 1b 00 00       	call   1a405 <swrites>
   188fa:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   188fd:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18904:	eb 3c                	jmp    18942 <progY+0x188>
		swrites( buf );
   18906:	83 ec 0c             	sub    $0xc,%esp
   18909:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1890f:	50                   	push   %eax
   18910:	e8 f0 1a 00 00       	call   1a405 <swrites>
   18915:	83 c4 10             	add    $0x10,%esp
		DELAY(STD);
   18918:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   1891f:	eb 04                	jmp    18925 <progY+0x16b>
   18921:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   18925:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   1892c:	7e f3                	jle    18921 <progY+0x167>
		sleep( SEC_TO_MS(1) );
   1892e:	83 ec 0c             	sub    $0xc,%esp
   18931:	68 e8 03 00 00       	push   $0x3e8
   18936:	e8 2d e6 ff ff       	call   16f68 <sleep>
   1893b:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   1893e:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18942:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18945:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18948:	7c bc                	jl     18906 <progY+0x14c>
	}

	exit( 0 );
   1894a:	83 ec 0c             	sub    $0xc,%esp
   1894d:	6a 00                	push   $0x0
   1894f:	e8 b4 e5 ff ff       	call   16f08 <exit>
   18954:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18957:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   1895c:	c9                   	leave  
   1895d:	c3                   	ret    

0001895e <progKL>:
** Invoked as:  progKL  x  n
**	 where x is the ID character
**		   n is the iteration count (defaults to 5)
*/

USERMAIN( progKL ) {
   1895e:	55                   	push   %ebp
   1895f:	89 e5                	mov    %esp,%ebp
   18961:	83 ec 58             	sub    $0x58,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18964:	8b 45 0c             	mov    0xc(%ebp),%eax
   18967:	8b 00                	mov    (%eax),%eax
   18969:	85 c0                	test   %eax,%eax
   1896b:	74 07                	je     18974 <progKL+0x16>
   1896d:	8b 45 0c             	mov    0xc(%ebp),%eax
   18970:	8b 00                	mov    (%eax),%eax
   18972:	eb 05                	jmp    18979 <progKL+0x1b>
   18974:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   18979:	89 45 e8             	mov    %eax,-0x18(%ebp)
	int count = 5;			// default iteration count
   1897c:	c7 45 f4 05 00 00 00 	movl   $0x5,-0xc(%ebp)
	char ch = '4';			// default character to print
   18983:	c6 45 df 34          	movb   $0x34,-0x21(%ebp)
	int nap = 30;			// nap time
   18987:	c7 45 e4 1e 00 00 00 	movl   $0x1e,-0x1c(%ebp)
	char msg2[] = "*4*";	// "error" message to print
   1898e:	c7 45 db 2a 34 2a 00 	movl   $0x2a342a,-0x25(%ebp)
	char buf[32];

	// process the command-line arguments
	switch( argc ) {
   18995:	8b 45 08             	mov    0x8(%ebp),%eax
   18998:	83 f8 02             	cmp    $0x2,%eax
   1899b:	74 1e                	je     189bb <progKL+0x5d>
   1899d:	83 f8 03             	cmp    $0x3,%eax
   189a0:	75 2c                	jne    189ce <progKL+0x70>
	case 3:	count = ustr2int( argv[2], 10 );
   189a2:	8b 45 0c             	mov    0xc(%ebp),%eax
   189a5:	83 c0 08             	add    $0x8,%eax
   189a8:	8b 00                	mov    (%eax),%eax
   189aa:	83 ec 08             	sub    $0x8,%esp
   189ad:	6a 0a                	push   $0xa
   189af:	50                   	push   %eax
   189b0:	e8 72 15 00 00       	call   19f27 <ustr2int>
   189b5:	83 c4 10             	add    $0x10,%esp
   189b8:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   189bb:	8b 45 0c             	mov    0xc(%ebp),%eax
   189be:	83 c0 04             	add    $0x4,%eax
   189c1:	8b 00                	mov    (%eax),%eax
   189c3:	0f b6 00             	movzbl (%eax),%eax
   189c6:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   189c9:	e9 9c 00 00 00       	jmp    18a6a <progKL+0x10c>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   189ce:	ff 75 08             	pushl  0x8(%ebp)
   189d1:	ff 75 e8             	pushl  -0x18(%ebp)
   189d4:	68 f1 bd 01 00       	push   $0x1bdf1
   189d9:	8d 45 bb             	lea    -0x45(%ebp),%eax
   189dc:	50                   	push   %eax
   189dd:	e8 d0 12 00 00       	call   19cb2 <usprint>
   189e2:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   189e5:	83 ec 0c             	sub    $0xc,%esp
   189e8:	8d 45 bb             	lea    -0x45(%ebp),%eax
   189eb:	50                   	push   %eax
   189ec:	e8 ae 19 00 00       	call   1a39f <cwrites>
   189f1:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   189f4:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   189fb:	eb 55                	jmp    18a52 <progKL+0xf4>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   189fd:	8b 45 08             	mov    0x8(%ebp),%eax
   18a00:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18a07:	8b 45 0c             	mov    0xc(%ebp),%eax
   18a0a:	01 d0                	add    %edx,%eax
   18a0c:	8b 00                	mov    (%eax),%eax
   18a0e:	85 c0                	test   %eax,%eax
   18a10:	74 13                	je     18a25 <progKL+0xc7>
   18a12:	8b 45 08             	mov    0x8(%ebp),%eax
   18a15:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18a1c:	8b 45 0c             	mov    0xc(%ebp),%eax
   18a1f:	01 d0                	add    %edx,%eax
   18a21:	8b 00                	mov    (%eax),%eax
   18a23:	eb 05                	jmp    18a2a <progKL+0xcc>
   18a25:	b8 05 be 01 00       	mov    $0x1be05,%eax
   18a2a:	83 ec 04             	sub    $0x4,%esp
   18a2d:	50                   	push   %eax
   18a2e:	68 0c be 01 00       	push   $0x1be0c
   18a33:	8d 45 bb             	lea    -0x45(%ebp),%eax
   18a36:	50                   	push   %eax
   18a37:	e8 76 12 00 00       	call   19cb2 <usprint>
   18a3c:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   18a3f:	83 ec 0c             	sub    $0xc,%esp
   18a42:	8d 45 bb             	lea    -0x45(%ebp),%eax
   18a45:	50                   	push   %eax
   18a46:	e8 54 19 00 00       	call   1a39f <cwrites>
   18a4b:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18a4e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   18a52:	8b 45 f0             	mov    -0x10(%ebp),%eax
   18a55:	3b 45 08             	cmp    0x8(%ebp),%eax
   18a58:	7e a3                	jle    189fd <progKL+0x9f>
			}
			cwrites( "\n" );
   18a5a:	83 ec 0c             	sub    $0xc,%esp
   18a5d:	68 10 be 01 00       	push   $0x1be10
   18a62:	e8 38 19 00 00       	call   1a39f <cwrites>
   18a67:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   18a6a:	83 ec 04             	sub    $0x4,%esp
   18a6d:	6a 01                	push   $0x1
   18a6f:	8d 45 df             	lea    -0x21(%ebp),%eax
   18a72:	50                   	push   %eax
   18a73:	6a 01                	push   $0x1
   18a75:	e8 b6 e4 ff ff       	call   16f30 <write>
   18a7a:	83 c4 10             	add    $0x10,%esp

	// argument vector for the processes we will spawn
	char *arglist[] = { "progX", "X", buf, NULL };
   18a7d:	c7 45 a8 2c bf 01 00 	movl   $0x1bf2c,-0x58(%ebp)
   18a84:	c7 45 ac 32 bf 01 00 	movl   $0x1bf32,-0x54(%ebp)
   18a8b:	8d 45 bb             	lea    -0x45(%ebp),%eax
   18a8e:	89 45 b0             	mov    %eax,-0x50(%ebp)
   18a91:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)

	for( int i = 0; i < count ; ++i ) {
   18a98:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18a9f:	e9 89 00 00 00       	jmp    18b2d <progKL+0x1cf>

		write( CHAN_SIO, &ch, 1 );
   18aa4:	83 ec 04             	sub    $0x4,%esp
   18aa7:	6a 01                	push   $0x1
   18aa9:	8d 45 df             	lea    -0x21(%ebp),%eax
   18aac:	50                   	push   %eax
   18aad:	6a 01                	push   $0x1
   18aaf:	e8 7c e4 ff ff       	call   16f30 <write>
   18ab4:	83 c4 10             	add    $0x10,%esp

		// second argument to X is 100 plus the iteration number
		usprint( buf, "%d", 100 + i );
   18ab7:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18aba:	83 c0 64             	add    $0x64,%eax
   18abd:	83 ec 04             	sub    $0x4,%esp
   18ac0:	50                   	push   %eax
   18ac1:	68 34 bf 01 00       	push   $0x1bf34
   18ac6:	8d 45 bb             	lea    -0x45(%ebp),%eax
   18ac9:	50                   	push   %eax
   18aca:	e8 e3 11 00 00       	call   19cb2 <usprint>
   18acf:	83 c4 10             	add    $0x10,%esp
		int whom = spawn( (uint32_t) progX, arglist );
   18ad2:	ba 4d 8b 01 00       	mov    $0x18b4d,%edx
   18ad7:	83 ec 08             	sub    $0x8,%esp
   18ada:	8d 45 a8             	lea    -0x58(%ebp),%eax
   18add:	50                   	push   %eax
   18ade:	52                   	push   %edx
   18adf:	e8 25 18 00 00       	call   1a309 <spawn>
   18ae4:	83 c4 10             	add    $0x10,%esp
   18ae7:	89 45 e0             	mov    %eax,-0x20(%ebp)
		if( whom < 0 ) {
   18aea:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   18aee:	79 11                	jns    18b01 <progKL+0x1a3>
			swrites( msg2 );
   18af0:	83 ec 0c             	sub    $0xc,%esp
   18af3:	8d 45 db             	lea    -0x25(%ebp),%eax
   18af6:	50                   	push   %eax
   18af7:	e8 09 19 00 00       	call   1a405 <swrites>
   18afc:	83 c4 10             	add    $0x10,%esp
   18aff:	eb 13                	jmp    18b14 <progKL+0x1b6>
		} else {
			write( CHAN_SIO, &ch, 1 );
   18b01:	83 ec 04             	sub    $0x4,%esp
   18b04:	6a 01                	push   $0x1
   18b06:	8d 45 df             	lea    -0x21(%ebp),%eax
   18b09:	50                   	push   %eax
   18b0a:	6a 01                	push   $0x1
   18b0c:	e8 1f e4 ff ff       	call   16f30 <write>
   18b11:	83 c4 10             	add    $0x10,%esp
		}

		sleep( SEC_TO_MS(nap) );
   18b14:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   18b17:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   18b1d:	83 ec 0c             	sub    $0xc,%esp
   18b20:	50                   	push   %eax
   18b21:	e8 42 e4 ff ff       	call   16f68 <sleep>
   18b26:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   18b29:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18b2d:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18b30:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18b33:	0f 8c 6b ff ff ff    	jl     18aa4 <progKL+0x146>
	}

	exit( 0 );
   18b39:	83 ec 0c             	sub    $0xc,%esp
   18b3c:	6a 00                	push   $0x0
   18b3e:	e8 c5 e3 ff ff       	call   16f08 <exit>
   18b43:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18b46:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   18b4b:	c9                   	leave  
   18b4c:	c3                   	ret    

00018b4d <progX>:
** Invoked as:  progX  x  n
**	 where x is the ID character
**		   n is the iteration count
*/

USERMAIN( progX ) {
   18b4d:	55                   	push   %ebp
   18b4e:	89 e5                	mov    %esp,%ebp
   18b50:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18b56:	8b 45 0c             	mov    0xc(%ebp),%eax
   18b59:	8b 00                	mov    (%eax),%eax
   18b5b:	85 c0                	test   %eax,%eax
   18b5d:	74 07                	je     18b66 <progX+0x19>
   18b5f:	8b 45 0c             	mov    0xc(%ebp),%eax
   18b62:	8b 00                	mov    (%eax),%eax
   18b64:	eb 05                	jmp    18b6b <progX+0x1e>
   18b66:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   18b6b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 20;	  // iteration count
   18b6e:	c7 45 f4 14 00 00 00 	movl   $0x14,-0xc(%ebp)
	char ch = 'x';	  // default character to print
   18b75:	c6 45 f3 78          	movb   $0x78,-0xd(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   18b79:	8b 45 08             	mov    0x8(%ebp),%eax
   18b7c:	83 f8 02             	cmp    $0x2,%eax
   18b7f:	74 1e                	je     18b9f <progX+0x52>
   18b81:	83 f8 03             	cmp    $0x3,%eax
   18b84:	75 2c                	jne    18bb2 <progX+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   18b86:	8b 45 0c             	mov    0xc(%ebp),%eax
   18b89:	83 c0 08             	add    $0x8,%eax
   18b8c:	8b 00                	mov    (%eax),%eax
   18b8e:	83 ec 08             	sub    $0x8,%esp
   18b91:	6a 0a                	push   $0xa
   18b93:	50                   	push   %eax
   18b94:	e8 8e 13 00 00       	call   19f27 <ustr2int>
   18b99:	83 c4 10             	add    $0x10,%esp
   18b9c:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18b9f:	8b 45 0c             	mov    0xc(%ebp),%eax
   18ba2:	83 c0 04             	add    $0x4,%eax
   18ba5:	8b 00                	mov    (%eax),%eax
   18ba7:	0f b6 00             	movzbl (%eax),%eax
   18baa:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   18bad:	e9 a8 00 00 00       	jmp    18c5a <progX+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18bb2:	ff 75 08             	pushl  0x8(%ebp)
   18bb5:	ff 75 e0             	pushl  -0x20(%ebp)
   18bb8:	68 f1 bd 01 00       	push   $0x1bdf1
   18bbd:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18bc3:	50                   	push   %eax
   18bc4:	e8 e9 10 00 00       	call   19cb2 <usprint>
   18bc9:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18bcc:	83 ec 0c             	sub    $0xc,%esp
   18bcf:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18bd5:	50                   	push   %eax
   18bd6:	e8 c4 17 00 00       	call   1a39f <cwrites>
   18bdb:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18bde:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18be5:	eb 5b                	jmp    18c42 <progX+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18be7:	8b 45 08             	mov    0x8(%ebp),%eax
   18bea:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18bf1:	8b 45 0c             	mov    0xc(%ebp),%eax
   18bf4:	01 d0                	add    %edx,%eax
   18bf6:	8b 00                	mov    (%eax),%eax
   18bf8:	85 c0                	test   %eax,%eax
   18bfa:	74 13                	je     18c0f <progX+0xc2>
   18bfc:	8b 45 08             	mov    0x8(%ebp),%eax
   18bff:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18c06:	8b 45 0c             	mov    0xc(%ebp),%eax
   18c09:	01 d0                	add    %edx,%eax
   18c0b:	8b 00                	mov    (%eax),%eax
   18c0d:	eb 05                	jmp    18c14 <progX+0xc7>
   18c0f:	b8 05 be 01 00       	mov    $0x1be05,%eax
   18c14:	83 ec 04             	sub    $0x4,%esp
   18c17:	50                   	push   %eax
   18c18:	68 0c be 01 00       	push   $0x1be0c
   18c1d:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18c23:	50                   	push   %eax
   18c24:	e8 89 10 00 00       	call   19cb2 <usprint>
   18c29:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   18c2c:	83 ec 0c             	sub    $0xc,%esp
   18c2f:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18c35:	50                   	push   %eax
   18c36:	e8 64 17 00 00       	call   1a39f <cwrites>
   18c3b:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18c3e:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18c42:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18c45:	3b 45 08             	cmp    0x8(%ebp),%eax
   18c48:	7e 9d                	jle    18be7 <progX+0x9a>
			}
			cwrites( "\n" );
   18c4a:	83 ec 0c             	sub    $0xc,%esp
   18c4d:	68 10 be 01 00       	push   $0x1be10
   18c52:	e8 48 17 00 00       	call   1a39f <cwrites>
   18c57:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int pid = getpid();
   18c5a:	e8 d9 e2 ff ff       	call   16f38 <getpid>
   18c5f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d]", ch, pid );
   18c62:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   18c66:	ff 75 dc             	pushl  -0x24(%ebp)
   18c69:	50                   	push   %eax
   18c6a:	68 ca be 01 00       	push   $0x1beca
   18c6f:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18c75:	50                   	push   %eax
   18c76:	e8 37 10 00 00       	call   19cb2 <usprint>
   18c7b:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   18c7e:	83 ec 0c             	sub    $0xc,%esp
   18c81:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18c87:	50                   	push   %eax
   18c88:	e8 78 17 00 00       	call   1a405 <swrites>
   18c8d:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   18c90:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18c97:	eb 2c                	jmp    18cc5 <progX+0x178>
		swrites( buf );
   18c99:	83 ec 0c             	sub    $0xc,%esp
   18c9c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18ca2:	50                   	push   %eax
   18ca3:	e8 5d 17 00 00       	call   1a405 <swrites>
   18ca8:	83 c4 10             	add    $0x10,%esp
		DELAY(STD);
   18cab:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   18cb2:	eb 04                	jmp    18cb8 <progX+0x16b>
   18cb4:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   18cb8:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   18cbf:	7e f3                	jle    18cb4 <progX+0x167>
	for( int i = 0; i < count ; ++i ) {
   18cc1:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18cc5:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18cc8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18ccb:	7c cc                	jl     18c99 <progX+0x14c>
	}

	exit( 12 );
   18ccd:	83 ec 0c             	sub    $0xc,%esp
   18cd0:	6a 0c                	push   $0xc
   18cd2:	e8 31 e2 ff ff       	call   16f08 <exit>
   18cd7:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18cda:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   18cdf:	c9                   	leave  
   18ce0:	c3                   	ret    

00018ce1 <progMN>:
**	 where x is the ID character
**		   n is the iteration count
**		   b is the w&z boolean
*/

USERMAIN( progMN ) {
   18ce1:	55                   	push   %ebp
   18ce2:	89 e5                	mov    %esp,%ebp
   18ce4:	81 ec d8 00 00 00    	sub    $0xd8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18cea:	8b 45 0c             	mov    0xc(%ebp),%eax
   18ced:	8b 00                	mov    (%eax),%eax
   18cef:	85 c0                	test   %eax,%eax
   18cf1:	74 07                	je     18cfa <progMN+0x19>
   18cf3:	8b 45 0c             	mov    0xc(%ebp),%eax
   18cf6:	8b 00                	mov    (%eax),%eax
   18cf8:	eb 05                	jmp    18cff <progMN+0x1e>
   18cfa:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   18cff:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int count = 5;	// default iteration count
   18d02:	c7 45 f4 05 00 00 00 	movl   $0x5,-0xc(%ebp)
	char ch = '5';	// default character to print
   18d09:	c6 45 df 35          	movb   $0x35,-0x21(%ebp)
	int alsoZ = 0;	// also do progZ?
   18d0d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	char msgw[] = "*5w*";
   18d14:	c7 45 da 2a 35 77 2a 	movl   $0x2a77352a,-0x26(%ebp)
   18d1b:	c6 45 de 00          	movb   $0x0,-0x22(%ebp)
	char msgz[] = "*5z*";
   18d1f:	c7 45 d5 2a 35 7a 2a 	movl   $0x2a7a352a,-0x2b(%ebp)
   18d26:	c6 45 d9 00          	movb   $0x0,-0x27(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   18d2a:	8b 45 08             	mov    0x8(%ebp),%eax
   18d2d:	83 f8 03             	cmp    $0x3,%eax
   18d30:	74 22                	je     18d54 <progMN+0x73>
   18d32:	83 f8 04             	cmp    $0x4,%eax
   18d35:	74 07                	je     18d3e <progMN+0x5d>
   18d37:	83 f8 02             	cmp    $0x2,%eax
   18d3a:	74 31                	je     18d6d <progMN+0x8c>
   18d3c:	eb 42                	jmp    18d80 <progMN+0x9f>
	case 4:	alsoZ = argv[3][0] == 't';
   18d3e:	8b 45 0c             	mov    0xc(%ebp),%eax
   18d41:	83 c0 0c             	add    $0xc,%eax
   18d44:	8b 00                	mov    (%eax),%eax
   18d46:	0f b6 00             	movzbl (%eax),%eax
   18d49:	3c 74                	cmp    $0x74,%al
   18d4b:	0f 94 c0             	sete   %al
   18d4e:	0f b6 c0             	movzbl %al,%eax
   18d51:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   18d54:	8b 45 0c             	mov    0xc(%ebp),%eax
   18d57:	83 c0 08             	add    $0x8,%eax
   18d5a:	8b 00                	mov    (%eax),%eax
   18d5c:	83 ec 08             	sub    $0x8,%esp
   18d5f:	6a 0a                	push   $0xa
   18d61:	50                   	push   %eax
   18d62:	e8 c0 11 00 00       	call   19f27 <ustr2int>
   18d67:	83 c4 10             	add    $0x10,%esp
   18d6a:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18d6d:	8b 45 0c             	mov    0xc(%ebp),%eax
   18d70:	83 c0 04             	add    $0x4,%eax
   18d73:	8b 00                	mov    (%eax),%eax
   18d75:	0f b6 00             	movzbl (%eax),%eax
   18d78:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   18d7b:	e9 a8 00 00 00       	jmp    18e28 <progMN+0x147>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18d80:	ff 75 08             	pushl  0x8(%ebp)
   18d83:	ff 75 e4             	pushl  -0x1c(%ebp)
   18d86:	68 f1 bd 01 00       	push   $0x1bdf1
   18d8b:	8d 85 55 ff ff ff    	lea    -0xab(%ebp),%eax
   18d91:	50                   	push   %eax
   18d92:	e8 1b 0f 00 00       	call   19cb2 <usprint>
   18d97:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18d9a:	83 ec 0c             	sub    $0xc,%esp
   18d9d:	8d 85 55 ff ff ff    	lea    -0xab(%ebp),%eax
   18da3:	50                   	push   %eax
   18da4:	e8 f6 15 00 00       	call   1a39f <cwrites>
   18da9:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18dac:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18db3:	eb 5b                	jmp    18e10 <progMN+0x12f>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18db5:	8b 45 08             	mov    0x8(%ebp),%eax
   18db8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18dbf:	8b 45 0c             	mov    0xc(%ebp),%eax
   18dc2:	01 d0                	add    %edx,%eax
   18dc4:	8b 00                	mov    (%eax),%eax
   18dc6:	85 c0                	test   %eax,%eax
   18dc8:	74 13                	je     18ddd <progMN+0xfc>
   18dca:	8b 45 08             	mov    0x8(%ebp),%eax
   18dcd:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18dd4:	8b 45 0c             	mov    0xc(%ebp),%eax
   18dd7:	01 d0                	add    %edx,%eax
   18dd9:	8b 00                	mov    (%eax),%eax
   18ddb:	eb 05                	jmp    18de2 <progMN+0x101>
   18ddd:	b8 05 be 01 00       	mov    $0x1be05,%eax
   18de2:	83 ec 04             	sub    $0x4,%esp
   18de5:	50                   	push   %eax
   18de6:	68 0c be 01 00       	push   $0x1be0c
   18deb:	8d 85 55 ff ff ff    	lea    -0xab(%ebp),%eax
   18df1:	50                   	push   %eax
   18df2:	e8 bb 0e 00 00       	call   19cb2 <usprint>
   18df7:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   18dfa:	83 ec 0c             	sub    $0xc,%esp
   18dfd:	8d 85 55 ff ff ff    	lea    -0xab(%ebp),%eax
   18e03:	50                   	push   %eax
   18e04:	e8 96 15 00 00       	call   1a39f <cwrites>
   18e09:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18e0c:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18e10:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18e13:	3b 45 08             	cmp    0x8(%ebp),%eax
   18e16:	7e 9d                	jle    18db5 <progMN+0xd4>
			}
			cwrites( "\n" );
   18e18:	83 ec 0c             	sub    $0xc,%esp
   18e1b:	68 10 be 01 00       	push   $0x1be10
   18e20:	e8 7a 15 00 00       	call   1a39f <cwrites>
   18e25:	83 c4 10             	add    $0x10,%esp
	}

	// update the extra message strings
	msgw[1] = msgz[1] = ch;
   18e28:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
   18e2c:	88 45 d6             	mov    %al,-0x2a(%ebp)
   18e2f:	0f b6 45 d6          	movzbl -0x2a(%ebp),%eax
   18e33:	88 45 db             	mov    %al,-0x25(%ebp)

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   18e36:	83 ec 04             	sub    $0x4,%esp
   18e39:	6a 01                	push   $0x1
   18e3b:	8d 45 df             	lea    -0x21(%ebp),%eax
   18e3e:	50                   	push   %eax
   18e3f:	6a 01                	push   $0x1
   18e41:	e8 ea e0 ff ff       	call   16f30 <write>
   18e46:	83 c4 10             	add    $0x10,%esp

	// set up the argument vector(s)

	// W:  15 iterations, 5-second sleep
	char *argsw[] = { "progW", "W", "15", "5", NULL };
   18e49:	c7 85 40 ff ff ff d2 	movl   $0x1bed2,-0xc0(%ebp)
   18e50:	be 01 00 
   18e53:	c7 85 44 ff ff ff e6 	movl   $0x1bbe6,-0xbc(%ebp)
   18e5a:	bb 01 00 
   18e5d:	c7 85 48 ff ff ff 37 	movl   $0x1bf37,-0xb8(%ebp)
   18e64:	bf 01 00 
   18e67:	c7 85 4c ff ff ff 93 	movl   $0x1bb93,-0xb4(%ebp)
   18e6e:	bb 01 00 
   18e71:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
   18e78:	00 00 00 

	// Z:  15 iterations
	char *argsz[] = { "progZ", "Z", "15", NULL };
   18e7b:	c7 85 30 ff ff ff 89 	movl   $0x1be89,-0xd0(%ebp)
   18e82:	be 01 00 
   18e85:	c7 85 34 ff ff ff 8f 	movl   $0x1be8f,-0xcc(%ebp)
   18e8c:	be 01 00 
   18e8f:	c7 85 38 ff ff ff 37 	movl   $0x1bf37,-0xc8(%ebp)
   18e96:	bf 01 00 
   18e99:	c7 85 3c ff ff ff 00 	movl   $0x0,-0xc4(%ebp)
   18ea0:	00 00 00 

	for( int i = 0; i < count; ++i ) {
   18ea3:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18eaa:	eb 7d                	jmp    18f29 <progMN+0x248>
		write( CHAN_SIO, &ch, 1 );
   18eac:	83 ec 04             	sub    $0x4,%esp
   18eaf:	6a 01                	push   $0x1
   18eb1:	8d 45 df             	lea    -0x21(%ebp),%eax
   18eb4:	50                   	push   %eax
   18eb5:	6a 01                	push   $0x1
   18eb7:	e8 74 e0 ff ff       	call   16f30 <write>
   18ebc:	83 c4 10             	add    $0x10,%esp
		int whom = spawn( (uint32_t) progW, argsw	);
   18ebf:	ba f4 83 01 00       	mov    $0x183f4,%edx
   18ec4:	83 ec 08             	sub    $0x8,%esp
   18ec7:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
   18ecd:	50                   	push   %eax
   18ece:	52                   	push   %edx
   18ecf:	e8 35 14 00 00       	call   1a309 <spawn>
   18ed4:	83 c4 10             	add    $0x10,%esp
   18ed7:	89 45 e0             	mov    %eax,-0x20(%ebp)
		if( whom < 1 ) {
   18eda:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   18ede:	7f 0f                	jg     18eef <progMN+0x20e>
			swrites( msgw );
   18ee0:	83 ec 0c             	sub    $0xc,%esp
   18ee3:	8d 45 da             	lea    -0x26(%ebp),%eax
   18ee6:	50                   	push   %eax
   18ee7:	e8 19 15 00 00       	call   1a405 <swrites>
   18eec:	83 c4 10             	add    $0x10,%esp
		}
		if( alsoZ ) {
   18eef:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   18ef3:	74 30                	je     18f25 <progMN+0x244>
			whom = spawn( (uint32_t) progZ, argsz );
   18ef5:	ba ba 7e 01 00       	mov    $0x17eba,%edx
   18efa:	83 ec 08             	sub    $0x8,%esp
   18efd:	8d 85 30 ff ff ff    	lea    -0xd0(%ebp),%eax
   18f03:	50                   	push   %eax
   18f04:	52                   	push   %edx
   18f05:	e8 ff 13 00 00       	call   1a309 <spawn>
   18f0a:	83 c4 10             	add    $0x10,%esp
   18f0d:	89 45 e0             	mov    %eax,-0x20(%ebp)
			if( whom < 1 ) {
   18f10:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   18f14:	7f 0f                	jg     18f25 <progMN+0x244>
				swrites( msgz );
   18f16:	83 ec 0c             	sub    $0xc,%esp
   18f19:	8d 45 d5             	lea    -0x2b(%ebp),%eax
   18f1c:	50                   	push   %eax
   18f1d:	e8 e3 14 00 00       	call   1a405 <swrites>
   18f22:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   18f25:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18f29:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18f2c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18f2f:	0f 8c 77 ff ff ff    	jl     18eac <progMN+0x1cb>
			}
		}
	}

	exit( 0 );
   18f35:	83 ec 0c             	sub    $0xc,%esp
   18f38:	6a 00                	push   $0x0
   18f3a:	e8 c9 df ff ff       	call   16f08 <exit>
   18f3f:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18f42:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   18f47:	c9                   	leave  
   18f48:	c3                   	ret    

00018f49 <progP>:
**	 where x is the ID character
**		   n is the iteration count (defaults to 3)
**		   t is the sleep time (defaults to 2 seconds)
*/

USERMAIN( progP ) {
   18f49:	55                   	push   %ebp
   18f4a:	89 e5                	mov    %esp,%ebp
   18f4c:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18f52:	8b 45 0c             	mov    0xc(%ebp),%eax
   18f55:	8b 00                	mov    (%eax),%eax
   18f57:	85 c0                	test   %eax,%eax
   18f59:	74 07                	je     18f62 <progP+0x19>
   18f5b:	8b 45 0c             	mov    0xc(%ebp),%eax
   18f5e:	8b 00                	mov    (%eax),%eax
   18f60:	eb 05                	jmp    18f67 <progP+0x1e>
   18f62:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   18f67:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int count = 3;	  // default iteration count
   18f6a:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
	char ch = 'p';	  // default character to print
   18f71:	c6 45 df 70          	movb   $0x70,-0x21(%ebp)
	int nap = 2;	  // nap time
   18f75:	c7 45 f0 02 00 00 00 	movl   $0x2,-0x10(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   18f7c:	8b 45 08             	mov    0x8(%ebp),%eax
   18f7f:	83 f8 03             	cmp    $0x3,%eax
   18f82:	74 25                	je     18fa9 <progP+0x60>
   18f84:	83 f8 04             	cmp    $0x4,%eax
   18f87:	74 07                	je     18f90 <progP+0x47>
   18f89:	83 f8 02             	cmp    $0x2,%eax
   18f8c:	74 34                	je     18fc2 <progP+0x79>
   18f8e:	eb 45                	jmp    18fd5 <progP+0x8c>
	case 4:	nap = ustr2int( argv[3], 10 );
   18f90:	8b 45 0c             	mov    0xc(%ebp),%eax
   18f93:	83 c0 0c             	add    $0xc,%eax
   18f96:	8b 00                	mov    (%eax),%eax
   18f98:	83 ec 08             	sub    $0x8,%esp
   18f9b:	6a 0a                	push   $0xa
   18f9d:	50                   	push   %eax
   18f9e:	e8 84 0f 00 00       	call   19f27 <ustr2int>
   18fa3:	83 c4 10             	add    $0x10,%esp
   18fa6:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   18fa9:	8b 45 0c             	mov    0xc(%ebp),%eax
   18fac:	83 c0 08             	add    $0x8,%eax
   18faf:	8b 00                	mov    (%eax),%eax
   18fb1:	83 ec 08             	sub    $0x8,%esp
   18fb4:	6a 0a                	push   $0xa
   18fb6:	50                   	push   %eax
   18fb7:	e8 6b 0f 00 00       	call   19f27 <ustr2int>
   18fbc:	83 c4 10             	add    $0x10,%esp
   18fbf:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18fc2:	8b 45 0c             	mov    0xc(%ebp),%eax
   18fc5:	83 c0 04             	add    $0x4,%eax
   18fc8:	8b 00                	mov    (%eax),%eax
   18fca:	0f b6 00             	movzbl (%eax),%eax
   18fcd:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   18fd0:	e9 a8 00 00 00       	jmp    1907d <progP+0x134>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18fd5:	ff 75 08             	pushl  0x8(%ebp)
   18fd8:	ff 75 e4             	pushl  -0x1c(%ebp)
   18fdb:	68 f1 bd 01 00       	push   $0x1bdf1
   18fe0:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   18fe6:	50                   	push   %eax
   18fe7:	e8 c6 0c 00 00       	call   19cb2 <usprint>
   18fec:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18fef:	83 ec 0c             	sub    $0xc,%esp
   18ff2:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   18ff8:	50                   	push   %eax
   18ff9:	e8 a1 13 00 00       	call   1a39f <cwrites>
   18ffe:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   19001:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   19008:	eb 5b                	jmp    19065 <progP+0x11c>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   1900a:	8b 45 08             	mov    0x8(%ebp),%eax
   1900d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19014:	8b 45 0c             	mov    0xc(%ebp),%eax
   19017:	01 d0                	add    %edx,%eax
   19019:	8b 00                	mov    (%eax),%eax
   1901b:	85 c0                	test   %eax,%eax
   1901d:	74 13                	je     19032 <progP+0xe9>
   1901f:	8b 45 08             	mov    0x8(%ebp),%eax
   19022:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19029:	8b 45 0c             	mov    0xc(%ebp),%eax
   1902c:	01 d0                	add    %edx,%eax
   1902e:	8b 00                	mov    (%eax),%eax
   19030:	eb 05                	jmp    19037 <progP+0xee>
   19032:	b8 05 be 01 00       	mov    $0x1be05,%eax
   19037:	83 ec 04             	sub    $0x4,%esp
   1903a:	50                   	push   %eax
   1903b:	68 0c be 01 00       	push   $0x1be0c
   19040:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   19046:	50                   	push   %eax
   19047:	e8 66 0c 00 00       	call   19cb2 <usprint>
   1904c:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1904f:	83 ec 0c             	sub    $0xc,%esp
   19052:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   19058:	50                   	push   %eax
   19059:	e8 41 13 00 00       	call   1a39f <cwrites>
   1905e:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   19061:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   19065:	8b 45 ec             	mov    -0x14(%ebp),%eax
   19068:	3b 45 08             	cmp    0x8(%ebp),%eax
   1906b:	7e 9d                	jle    1900a <progP+0xc1>
			}
			cwrites( "\n" );
   1906d:	83 ec 0c             	sub    $0xc,%esp
   19070:	68 10 be 01 00       	push   $0x1be10
   19075:	e8 25 13 00 00       	call   1a39f <cwrites>
   1907a:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	uint32_t now = gettime();
   1907d:	e8 c6 de ff ff       	call   16f48 <gettime>
   19082:	89 45 e0             	mov    %eax,-0x20(%ebp)
	usprint( buf, " P@%u", now );
   19085:	83 ec 04             	sub    $0x4,%esp
   19088:	ff 75 e0             	pushl  -0x20(%ebp)
   1908b:	68 3a bf 01 00       	push   $0x1bf3a
   19090:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   19096:	50                   	push   %eax
   19097:	e8 16 0c 00 00       	call   19cb2 <usprint>
   1909c:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   1909f:	83 ec 0c             	sub    $0xc,%esp
   190a2:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   190a8:	50                   	push   %eax
   190a9:	e8 57 13 00 00       	call   1a405 <swrites>
   190ae:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count; ++i ) {
   190b1:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   190b8:	eb 2c                	jmp    190e6 <progP+0x19d>
		sleep( SEC_TO_MS(nap) );
   190ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
   190bd:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   190c3:	83 ec 0c             	sub    $0xc,%esp
   190c6:	50                   	push   %eax
   190c7:	e8 9c de ff ff       	call   16f68 <sleep>
   190cc:	83 c4 10             	add    $0x10,%esp
		write( CHAN_SIO, &ch, 1 );
   190cf:	83 ec 04             	sub    $0x4,%esp
   190d2:	6a 01                	push   $0x1
   190d4:	8d 45 df             	lea    -0x21(%ebp),%eax
   190d7:	50                   	push   %eax
   190d8:	6a 01                	push   $0x1
   190da:	e8 51 de ff ff       	call   16f30 <write>
   190df:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   190e2:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   190e6:	8b 45 e8             	mov    -0x18(%ebp),%eax
   190e9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   190ec:	7c cc                	jl     190ba <progP+0x171>
	}

	exit( 0 );
   190ee:	83 ec 0c             	sub    $0xc,%esp
   190f1:	6a 00                	push   $0x0
   190f3:	e8 10 de ff ff       	call   16f08 <exit>
   190f8:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   190fb:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   19100:	c9                   	leave  
   19101:	c3                   	ret    

00019102 <progQ>:
**
** Invoked as:  progQ  x
**	 where x is the ID character
*/

USERMAIN( progQ ) {
   19102:	55                   	push   %ebp
   19103:	89 e5                	mov    %esp,%ebp
   19105:	81 ec 98 00 00 00    	sub    $0x98,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   1910b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1910e:	8b 00                	mov    (%eax),%eax
   19110:	85 c0                	test   %eax,%eax
   19112:	74 07                	je     1911b <progQ+0x19>
   19114:	8b 45 0c             	mov    0xc(%ebp),%eax
   19117:	8b 00                	mov    (%eax),%eax
   19119:	eb 05                	jmp    19120 <progQ+0x1e>
   1911b:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   19120:	89 45 f0             	mov    %eax,-0x10(%ebp)
	char ch = 'q';	  // default character to print
   19123:	c6 45 ef 71          	movb   $0x71,-0x11(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   19127:	8b 45 08             	mov    0x8(%ebp),%eax
   1912a:	83 f8 02             	cmp    $0x2,%eax
   1912d:	75 13                	jne    19142 <progQ+0x40>
	case 2:	ch = argv[1][0];
   1912f:	8b 45 0c             	mov    0xc(%ebp),%eax
   19132:	83 c0 04             	add    $0x4,%eax
   19135:	8b 00                	mov    (%eax),%eax
   19137:	0f b6 00             	movzbl (%eax),%eax
   1913a:	88 45 ef             	mov    %al,-0x11(%ebp)
			break;
   1913d:	e9 a8 00 00 00       	jmp    191ea <progQ+0xe8>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   19142:	ff 75 08             	pushl  0x8(%ebp)
   19145:	ff 75 f0             	pushl  -0x10(%ebp)
   19148:	68 f1 bd 01 00       	push   $0x1bdf1
   1914d:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   19153:	50                   	push   %eax
   19154:	e8 59 0b 00 00       	call   19cb2 <usprint>
   19159:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1915c:	83 ec 0c             	sub    $0xc,%esp
   1915f:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   19165:	50                   	push   %eax
   19166:	e8 34 12 00 00       	call   1a39f <cwrites>
   1916b:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1916e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   19175:	eb 5b                	jmp    191d2 <progQ+0xd0>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   19177:	8b 45 08             	mov    0x8(%ebp),%eax
   1917a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19181:	8b 45 0c             	mov    0xc(%ebp),%eax
   19184:	01 d0                	add    %edx,%eax
   19186:	8b 00                	mov    (%eax),%eax
   19188:	85 c0                	test   %eax,%eax
   1918a:	74 13                	je     1919f <progQ+0x9d>
   1918c:	8b 45 08             	mov    0x8(%ebp),%eax
   1918f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19196:	8b 45 0c             	mov    0xc(%ebp),%eax
   19199:	01 d0                	add    %edx,%eax
   1919b:	8b 00                	mov    (%eax),%eax
   1919d:	eb 05                	jmp    191a4 <progQ+0xa2>
   1919f:	b8 05 be 01 00       	mov    $0x1be05,%eax
   191a4:	83 ec 04             	sub    $0x4,%esp
   191a7:	50                   	push   %eax
   191a8:	68 0c be 01 00       	push   $0x1be0c
   191ad:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   191b3:	50                   	push   %eax
   191b4:	e8 f9 0a 00 00       	call   19cb2 <usprint>
   191b9:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   191bc:	83 ec 0c             	sub    $0xc,%esp
   191bf:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   191c5:	50                   	push   %eax
   191c6:	e8 d4 11 00 00       	call   1a39f <cwrites>
   191cb:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   191ce:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   191d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
   191d5:	3b 45 08             	cmp    0x8(%ebp),%eax
   191d8:	7e 9d                	jle    19177 <progQ+0x75>
			}
			cwrites( "\n" );
   191da:	83 ec 0c             	sub    $0xc,%esp
   191dd:	68 10 be 01 00       	push   $0x1be10
   191e2:	e8 b8 11 00 00       	call   1a39f <cwrites>
   191e7:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   191ea:	83 ec 04             	sub    $0x4,%esp
   191ed:	6a 01                	push   $0x1
   191ef:	8d 45 ef             	lea    -0x11(%ebp),%eax
   191f2:	50                   	push   %eax
   191f3:	6a 01                	push   $0x1
   191f5:	e8 36 dd ff ff       	call   16f30 <write>
   191fa:	83 c4 10             	add    $0x10,%esp

	// try something weird
	bogus();
   191fd:	e8 6e dd ff ff       	call   16f70 <bogus>

	// should not have come back here!
	usprint( buf, "!!!!! %c returned from bogus syscall!?!?!\n", ch );
   19202:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
   19206:	0f be c0             	movsbl %al,%eax
   19209:	83 ec 04             	sub    $0x4,%esp
   1920c:	50                   	push   %eax
   1920d:	68 40 bf 01 00       	push   $0x1bf40
   19212:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   19218:	50                   	push   %eax
   19219:	e8 94 0a 00 00       	call   19cb2 <usprint>
   1921e:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   19221:	83 ec 0c             	sub    $0xc,%esp
   19224:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   1922a:	50                   	push   %eax
   1922b:	e8 6f 11 00 00       	call   1a39f <cwrites>
   19230:	83 c4 10             	add    $0x10,%esp

	exit( 1 );
   19233:	83 ec 0c             	sub    $0xc,%esp
   19236:	6a 01                	push   $0x1
   19238:	e8 cb dc ff ff       	call   16f08 <exit>
   1923d:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   19240:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   19245:	c9                   	leave  
   19246:	c3                   	ret    

00019247 <progR>:
**	 where x is the ID character
**		   n is the sequence number of the initial incarnation
**		   s is the initial delay time (defaults to 10)
*/

USERMAIN( progR ) {
   19247:	55                   	push   %ebp
   19248:	89 e5                	mov    %esp,%ebp
   1924a:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   19250:	8b 45 0c             	mov    0xc(%ebp),%eax
   19253:	8b 00                	mov    (%eax),%eax
   19255:	85 c0                	test   %eax,%eax
   19257:	74 07                	je     19260 <progR+0x19>
   19259:	8b 45 0c             	mov    0xc(%ebp),%eax
   1925c:	8b 00                	mov    (%eax),%eax
   1925e:	eb 05                	jmp    19265 <progR+0x1e>
   19260:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   19265:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	char ch = 'r';	// default character to print
   19268:	c6 45 f7 72          	movb   $0x72,-0x9(%ebp)
	int delay = 10;	// initial delay count
   1926c:	c7 45 f0 0a 00 00 00 	movl   $0xa,-0x10(%ebp)
	int seq = 99;	// my sequence number
   19273:	c7 45 ec 63 00 00 00 	movl   $0x63,-0x14(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   1927a:	8b 45 08             	mov    0x8(%ebp),%eax
   1927d:	83 f8 03             	cmp    $0x3,%eax
   19280:	74 25                	je     192a7 <progR+0x60>
   19282:	83 f8 04             	cmp    $0x4,%eax
   19285:	74 07                	je     1928e <progR+0x47>
   19287:	83 f8 02             	cmp    $0x2,%eax
   1928a:	74 34                	je     192c0 <progR+0x79>
   1928c:	eb 45                	jmp    192d3 <progR+0x8c>
	case 4:	delay = ustr2int( argv[3], 10 );
   1928e:	8b 45 0c             	mov    0xc(%ebp),%eax
   19291:	83 c0 0c             	add    $0xc,%eax
   19294:	8b 00                	mov    (%eax),%eax
   19296:	83 ec 08             	sub    $0x8,%esp
   19299:	6a 0a                	push   $0xa
   1929b:	50                   	push   %eax
   1929c:	e8 86 0c 00 00       	call   19f27 <ustr2int>
   192a1:	83 c4 10             	add    $0x10,%esp
   192a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	seq = ustr2int( argv[2], 10 );
   192a7:	8b 45 0c             	mov    0xc(%ebp),%eax
   192aa:	83 c0 08             	add    $0x8,%eax
   192ad:	8b 00                	mov    (%eax),%eax
   192af:	83 ec 08             	sub    $0x8,%esp
   192b2:	6a 0a                	push   $0xa
   192b4:	50                   	push   %eax
   192b5:	e8 6d 0c 00 00       	call   19f27 <ustr2int>
   192ba:	83 c4 10             	add    $0x10,%esp
   192bd:	89 45 ec             	mov    %eax,-0x14(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   192c0:	8b 45 0c             	mov    0xc(%ebp),%eax
   192c3:	83 c0 04             	add    $0x4,%eax
   192c6:	8b 00                	mov    (%eax),%eax
   192c8:	0f b6 00             	movzbl (%eax),%eax
   192cb:	88 45 f7             	mov    %al,-0x9(%ebp)
			break;
   192ce:	e9 a8 00 00 00       	jmp    1937b <progR+0x134>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   192d3:	ff 75 08             	pushl  0x8(%ebp)
   192d6:	ff 75 e4             	pushl  -0x1c(%ebp)
   192d9:	68 f1 bd 01 00       	push   $0x1bdf1
   192de:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   192e4:	50                   	push   %eax
   192e5:	e8 c8 09 00 00       	call   19cb2 <usprint>
   192ea:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   192ed:	83 ec 0c             	sub    $0xc,%esp
   192f0:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   192f6:	50                   	push   %eax
   192f7:	e8 a3 10 00 00       	call   1a39f <cwrites>
   192fc:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   192ff:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   19306:	eb 5b                	jmp    19363 <progR+0x11c>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   19308:	8b 45 08             	mov    0x8(%ebp),%eax
   1930b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19312:	8b 45 0c             	mov    0xc(%ebp),%eax
   19315:	01 d0                	add    %edx,%eax
   19317:	8b 00                	mov    (%eax),%eax
   19319:	85 c0                	test   %eax,%eax
   1931b:	74 13                	je     19330 <progR+0xe9>
   1931d:	8b 45 08             	mov    0x8(%ebp),%eax
   19320:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19327:	8b 45 0c             	mov    0xc(%ebp),%eax
   1932a:	01 d0                	add    %edx,%eax
   1932c:	8b 00                	mov    (%eax),%eax
   1932e:	eb 05                	jmp    19335 <progR+0xee>
   19330:	b8 05 be 01 00       	mov    $0x1be05,%eax
   19335:	83 ec 04             	sub    $0x4,%esp
   19338:	50                   	push   %eax
   19339:	68 0c be 01 00       	push   $0x1be0c
   1933e:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19344:	50                   	push   %eax
   19345:	e8 68 09 00 00       	call   19cb2 <usprint>
   1934a:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1934d:	83 ec 0c             	sub    $0xc,%esp
   19350:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19356:	50                   	push   %eax
   19357:	e8 43 10 00 00       	call   1a39f <cwrites>
   1935c:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1935f:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   19363:	8b 45 e8             	mov    -0x18(%ebp),%eax
   19366:	3b 45 08             	cmp    0x8(%ebp),%eax
   19369:	7e 9d                	jle    19308 <progR+0xc1>
			}
			cwrites( "\n" );
   1936b:	83 ec 0c             	sub    $0xc,%esp
   1936e:	68 10 be 01 00       	push   $0x1be10
   19373:	e8 27 10 00 00       	call   1a39f <cwrites>
   19378:	83 c4 10             	add    $0x10,%esp
	int32_t ppid;

 restart:

	// announce our presence
	pid = getpid();
   1937b:	e8 b8 db ff ff       	call   16f38 <getpid>
   19380:	89 45 e0             	mov    %eax,-0x20(%ebp)
	ppid = getppid();
   19383:	e8 b8 db ff ff       	call   16f40 <getppid>
   19388:	89 45 dc             	mov    %eax,-0x24(%ebp)

	usprint( buf, " %c[%d,%d,%d]", ch, seq, pid, ppid );
   1938b:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
   1938f:	83 ec 08             	sub    $0x8,%esp
   19392:	ff 75 dc             	pushl  -0x24(%ebp)
   19395:	ff 75 e0             	pushl  -0x20(%ebp)
   19398:	ff 75 ec             	pushl  -0x14(%ebp)
   1939b:	50                   	push   %eax
   1939c:	68 6b bf 01 00       	push   $0x1bf6b
   193a1:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   193a7:	50                   	push   %eax
   193a8:	e8 05 09 00 00       	call   19cb2 <usprint>
   193ad:	83 c4 20             	add    $0x20,%esp
	swrites( buf );
   193b0:	83 ec 0c             	sub    $0xc,%esp
   193b3:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   193b9:	50                   	push   %eax
   193ba:	e8 46 10 00 00       	call   1a405 <swrites>
   193bf:	83 c4 10             	add    $0x10,%esp

	sleep( SEC_TO_MS(delay) );
   193c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
   193c5:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   193cb:	83 ec 0c             	sub    $0xc,%esp
   193ce:	50                   	push   %eax
   193cf:	e8 94 db ff ff       	call   16f68 <sleep>
   193d4:	83 c4 10             	add    $0x10,%esp

	// create the next child in sequence
	if( seq < 5 ) {
   193d7:	83 7d ec 04          	cmpl   $0x4,-0x14(%ebp)
   193db:	7f 63                	jg     19440 <progR+0x1f9>
		++seq;
   193dd:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
		int32_t n = fork();
   193e1:	e8 32 db ff ff       	call   16f18 <fork>
   193e6:	89 45 d8             	mov    %eax,-0x28(%ebp)
		switch( n ) {
   193e9:	8b 45 d8             	mov    -0x28(%ebp),%eax
   193ec:	83 f8 ff             	cmp    $0xffffffff,%eax
   193ef:	74 06                	je     193f7 <progR+0x1b0>
   193f1:	85 c0                	test   %eax,%eax
   193f3:	74 86                	je     1937b <progR+0x134>
   193f5:	eb 2e                	jmp    19425 <progR+0x1de>
		case -1:
			// failure?
			usprint( buf, "** R[%d] fork code %d\n", pid, n );
   193f7:	ff 75 d8             	pushl  -0x28(%ebp)
   193fa:	ff 75 e0             	pushl  -0x20(%ebp)
   193fd:	68 79 bf 01 00       	push   $0x1bf79
   19402:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19408:	50                   	push   %eax
   19409:	e8 a4 08 00 00       	call   19cb2 <usprint>
   1940e:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   19411:	83 ec 0c             	sub    $0xc,%esp
   19414:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   1941a:	50                   	push   %eax
   1941b:	e8 7f 0f 00 00       	call   1a39f <cwrites>
   19420:	83 c4 10             	add    $0x10,%esp
			break;
   19423:	eb 1c                	jmp    19441 <progR+0x1fa>
		case 0:
			// child
			goto restart;
		default:
			// parent
			--seq;
   19425:	83 6d ec 01          	subl   $0x1,-0x14(%ebp)
			sleep( SEC_TO_MS(delay) );
   19429:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1942c:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   19432:	83 ec 0c             	sub    $0xc,%esp
   19435:	50                   	push   %eax
   19436:	e8 2d db ff ff       	call   16f68 <sleep>
   1943b:	83 c4 10             	add    $0x10,%esp
   1943e:	eb 01                	jmp    19441 <progR+0x1fa>
		}
	}
   19440:	90                   	nop

	// final report - PPID may change, but PID and seq shouldn't
	pid = getpid();
   19441:	e8 f2 da ff ff       	call   16f38 <getpid>
   19446:	89 45 e0             	mov    %eax,-0x20(%ebp)
	ppid = getppid();
   19449:	e8 f2 da ff ff       	call   16f40 <getppid>
   1944e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d,%d,%d]", ch, seq, pid, ppid );
   19451:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
   19455:	83 ec 08             	sub    $0x8,%esp
   19458:	ff 75 dc             	pushl  -0x24(%ebp)
   1945b:	ff 75 e0             	pushl  -0x20(%ebp)
   1945e:	ff 75 ec             	pushl  -0x14(%ebp)
   19461:	50                   	push   %eax
   19462:	68 6b bf 01 00       	push   $0x1bf6b
   19467:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   1946d:	50                   	push   %eax
   1946e:	e8 3f 08 00 00       	call   19cb2 <usprint>
   19473:	83 c4 20             	add    $0x20,%esp
	swrites( buf );
   19476:	83 ec 0c             	sub    $0xc,%esp
   19479:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   1947f:	50                   	push   %eax
   19480:	e8 80 0f 00 00       	call   1a405 <swrites>
   19485:	83 c4 10             	add    $0x10,%esp

	exit( 0 );
   19488:	83 ec 0c             	sub    $0xc,%esp
   1948b:	6a 00                	push   $0x0
   1948d:	e8 76 da ff ff       	call   16f08 <exit>
   19492:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   19495:	b8 2a 00 00 00       	mov    $0x2a,%eax

}
   1949a:	c9                   	leave  
   1949b:	c3                   	ret    

0001949c <progS>:
** Invoked as:  progS  x  [ s ]
**	 where x is the ID character
**		   s is the sleep time (defaults to 20)
*/

USERMAIN( progS ) {
   1949c:	55                   	push   %ebp
   1949d:	89 e5                	mov    %esp,%ebp
   1949f:	81 ec 98 00 00 00    	sub    $0x98,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   194a5:	8b 45 0c             	mov    0xc(%ebp),%eax
   194a8:	8b 00                	mov    (%eax),%eax
   194aa:	85 c0                	test   %eax,%eax
   194ac:	74 07                	je     194b5 <progS+0x19>
   194ae:	8b 45 0c             	mov    0xc(%ebp),%eax
   194b1:	8b 00                	mov    (%eax),%eax
   194b3:	eb 05                	jmp    194ba <progS+0x1e>
   194b5:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   194ba:	89 45 ec             	mov    %eax,-0x14(%ebp)
	char ch = 's';	  // default character to print
   194bd:	c6 45 eb 73          	movb   $0x73,-0x15(%ebp)
	int nap = 20;	  // nap time
   194c1:	c7 45 f4 14 00 00 00 	movl   $0x14,-0xc(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   194c8:	8b 45 08             	mov    0x8(%ebp),%eax
   194cb:	83 f8 02             	cmp    $0x2,%eax
   194ce:	74 1e                	je     194ee <progS+0x52>
   194d0:	83 f8 03             	cmp    $0x3,%eax
   194d3:	75 2c                	jne    19501 <progS+0x65>
	case 3:	nap = ustr2int( argv[2], 10 );
   194d5:	8b 45 0c             	mov    0xc(%ebp),%eax
   194d8:	83 c0 08             	add    $0x8,%eax
   194db:	8b 00                	mov    (%eax),%eax
   194dd:	83 ec 08             	sub    $0x8,%esp
   194e0:	6a 0a                	push   $0xa
   194e2:	50                   	push   %eax
   194e3:	e8 3f 0a 00 00       	call   19f27 <ustr2int>
   194e8:	83 c4 10             	add    $0x10,%esp
   194eb:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   194ee:	8b 45 0c             	mov    0xc(%ebp),%eax
   194f1:	83 c0 04             	add    $0x4,%eax
   194f4:	8b 00                	mov    (%eax),%eax
   194f6:	0f b6 00             	movzbl (%eax),%eax
   194f9:	88 45 eb             	mov    %al,-0x15(%ebp)
			break;
   194fc:	e9 a8 00 00 00       	jmp    195a9 <progS+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   19501:	ff 75 08             	pushl  0x8(%ebp)
   19504:	ff 75 ec             	pushl  -0x14(%ebp)
   19507:	68 f1 bd 01 00       	push   $0x1bdf1
   1950c:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   19512:	50                   	push   %eax
   19513:	e8 9a 07 00 00       	call   19cb2 <usprint>
   19518:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1951b:	83 ec 0c             	sub    $0xc,%esp
   1951e:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   19524:	50                   	push   %eax
   19525:	e8 75 0e 00 00       	call   1a39f <cwrites>
   1952a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1952d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   19534:	eb 5b                	jmp    19591 <progS+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   19536:	8b 45 08             	mov    0x8(%ebp),%eax
   19539:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19540:	8b 45 0c             	mov    0xc(%ebp),%eax
   19543:	01 d0                	add    %edx,%eax
   19545:	8b 00                	mov    (%eax),%eax
   19547:	85 c0                	test   %eax,%eax
   19549:	74 13                	je     1955e <progS+0xc2>
   1954b:	8b 45 08             	mov    0x8(%ebp),%eax
   1954e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19555:	8b 45 0c             	mov    0xc(%ebp),%eax
   19558:	01 d0                	add    %edx,%eax
   1955a:	8b 00                	mov    (%eax),%eax
   1955c:	eb 05                	jmp    19563 <progS+0xc7>
   1955e:	b8 05 be 01 00       	mov    $0x1be05,%eax
   19563:	83 ec 04             	sub    $0x4,%esp
   19566:	50                   	push   %eax
   19567:	68 0c be 01 00       	push   $0x1be0c
   1956c:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   19572:	50                   	push   %eax
   19573:	e8 3a 07 00 00       	call   19cb2 <usprint>
   19578:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1957b:	83 ec 0c             	sub    $0xc,%esp
   1957e:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   19584:	50                   	push   %eax
   19585:	e8 15 0e 00 00       	call   1a39f <cwrites>
   1958a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1958d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   19591:	8b 45 f0             	mov    -0x10(%ebp),%eax
   19594:	3b 45 08             	cmp    0x8(%ebp),%eax
   19597:	7e 9d                	jle    19536 <progS+0x9a>
			}
			cwrites( "\n" );
   19599:	83 ec 0c             	sub    $0xc,%esp
   1959c:	68 10 be 01 00       	push   $0x1be10
   195a1:	e8 f9 0d 00 00       	call   1a39f <cwrites>
   195a6:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   195a9:	83 ec 04             	sub    $0x4,%esp
   195ac:	6a 01                	push   $0x1
   195ae:	8d 45 eb             	lea    -0x15(%ebp),%eax
   195b1:	50                   	push   %eax
   195b2:	6a 01                	push   $0x1
   195b4:	e8 77 d9 ff ff       	call   16f30 <write>
   195b9:	83 c4 10             	add    $0x10,%esp

	usprint( buf, "%s sleeping %d(%d)\n", name, nap, SEC_TO_MS(nap) );
   195bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
   195bf:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   195c5:	83 ec 0c             	sub    $0xc,%esp
   195c8:	50                   	push   %eax
   195c9:	ff 75 f4             	pushl  -0xc(%ebp)
   195cc:	ff 75 ec             	pushl  -0x14(%ebp)
   195cf:	68 90 bf 01 00       	push   $0x1bf90
   195d4:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   195da:	50                   	push   %eax
   195db:	e8 d2 06 00 00       	call   19cb2 <usprint>
   195e0:	83 c4 20             	add    $0x20,%esp
	cwrites( buf );
   195e3:	83 ec 0c             	sub    $0xc,%esp
   195e6:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   195ec:	50                   	push   %eax
   195ed:	e8 ad 0d 00 00       	call   1a39f <cwrites>
   195f2:	83 c4 10             	add    $0x10,%esp

	for(;;) {
		sleep( SEC_TO_MS(nap) );
   195f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
   195f8:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   195fe:	83 ec 0c             	sub    $0xc,%esp
   19601:	50                   	push   %eax
   19602:	e8 61 d9 ff ff       	call   16f68 <sleep>
   19607:	83 c4 10             	add    $0x10,%esp
		write( CHAN_SIO, &ch, 1 );
   1960a:	83 ec 04             	sub    $0x4,%esp
   1960d:	6a 01                	push   $0x1
   1960f:	8d 45 eb             	lea    -0x15(%ebp),%eax
   19612:	50                   	push   %eax
   19613:	6a 01                	push   $0x1
   19615:	e8 16 d9 ff ff       	call   16f30 <write>
   1961a:	83 c4 10             	add    $0x10,%esp
		sleep( SEC_TO_MS(nap) );
   1961d:	eb d6                	jmp    195f5 <progS+0x159>

0001961f <progTUV>:

#ifndef MAX_CHILDREN
#define MAX_CHILDREN	50
#endif

USERMAIN( progTUV ) {
   1961f:	55                   	push   %ebp
   19620:	89 e5                	mov    %esp,%ebp
   19622:	81 ec a8 01 00 00    	sub    $0x1a8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   19628:	8b 45 0c             	mov    0xc(%ebp),%eax
   1962b:	8b 00                	mov    (%eax),%eax
   1962d:	85 c0                	test   %eax,%eax
   1962f:	74 07                	je     19638 <progTUV+0x19>
   19631:	8b 45 0c             	mov    0xc(%ebp),%eax
   19634:	8b 00                	mov    (%eax),%eax
   19636:	eb 05                	jmp    1963d <progTUV+0x1e>
   19638:	b8 08 bb 01 00       	mov    $0x1bb08,%eax
   1963d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	int count = 3;			// default child count
   19640:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
	char ch = '6';			// default character to print
   19647:	c6 45 c7 36          	movb   $0x36,-0x39(%ebp)
	int nap = 8;			// nap time
   1964b:	c7 45 cc 08 00 00 00 	movl   $0x8,-0x34(%ebp)
	bool_t waiting = true;	// default is waiting by PID
   19652:	c6 45 f3 01          	movb   $0x1,-0xd(%ebp)
	bool_t bypid = true;
   19656:	c6 45 f2 01          	movb   $0x1,-0xe(%ebp)
	char buf[128];
	uint_t children[MAX_CHILDREN];
	int nkids = 0;
   1965a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	char ch2[] = "*?*";
   19661:	c7 85 78 fe ff ff 2a 	movl   $0x2a3f2a,-0x188(%ebp)
   19668:	3f 2a 00 

	// process the command-line arguments
	switch( argc ) {
   1966b:	8b 45 08             	mov    0x8(%ebp),%eax
   1966e:	83 f8 03             	cmp    $0x3,%eax
   19671:	74 32                	je     196a5 <progTUV+0x86>
   19673:	83 f8 04             	cmp    $0x4,%eax
   19676:	74 07                	je     1967f <progTUV+0x60>
   19678:	83 f8 02             	cmp    $0x2,%eax
   1967b:	74 41                	je     196be <progTUV+0x9f>
   1967d:	eb 52                	jmp    196d1 <progTUV+0xb2>
	case 4:	waiting = argv[3][0] != 'k';	// 'w'/'W' -> wait, else -> kill
   1967f:	8b 45 0c             	mov    0xc(%ebp),%eax
   19682:	83 c0 0c             	add    $0xc,%eax
   19685:	8b 00                	mov    (%eax),%eax
   19687:	0f b6 00             	movzbl (%eax),%eax
   1968a:	3c 6b                	cmp    $0x6b,%al
   1968c:	0f 95 c0             	setne  %al
   1968f:	88 45 f3             	mov    %al,-0xd(%ebp)
			bypid   = argv[3][0] != 'w';	// 'W'/'k' -> by PID
   19692:	8b 45 0c             	mov    0xc(%ebp),%eax
   19695:	83 c0 0c             	add    $0xc,%eax
   19698:	8b 00                	mov    (%eax),%eax
   1969a:	0f b6 00             	movzbl (%eax),%eax
   1969d:	3c 77                	cmp    $0x77,%al
   1969f:	0f 95 c0             	setne  %al
   196a2:	88 45 f2             	mov    %al,-0xe(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   196a5:	8b 45 0c             	mov    0xc(%ebp),%eax
   196a8:	83 c0 08             	add    $0x8,%eax
   196ab:	8b 00                	mov    (%eax),%eax
   196ad:	83 ec 08             	sub    $0x8,%esp
   196b0:	6a 0a                	push   $0xa
   196b2:	50                   	push   %eax
   196b3:	e8 6f 08 00 00       	call   19f27 <ustr2int>
   196b8:	83 c4 10             	add    $0x10,%esp
   196bb:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   196be:	8b 45 0c             	mov    0xc(%ebp),%eax
   196c1:	83 c0 04             	add    $0x4,%eax
   196c4:	8b 00                	mov    (%eax),%eax
   196c6:	0f b6 00             	movzbl (%eax),%eax
   196c9:	88 45 c7             	mov    %al,-0x39(%ebp)
			break;
   196cc:	e9 a8 00 00 00       	jmp    19779 <progTUV+0x15a>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   196d1:	ff 75 08             	pushl  0x8(%ebp)
   196d4:	ff 75 d0             	pushl  -0x30(%ebp)
   196d7:	68 f1 bd 01 00       	push   $0x1bdf1
   196dc:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   196e2:	50                   	push   %eax
   196e3:	e8 ca 05 00 00       	call   19cb2 <usprint>
   196e8:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   196eb:	83 ec 0c             	sub    $0xc,%esp
   196ee:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   196f4:	50                   	push   %eax
   196f5:	e8 a5 0c 00 00       	call   1a39f <cwrites>
   196fa:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   196fd:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   19704:	eb 5b                	jmp    19761 <progTUV+0x142>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   19706:	8b 45 08             	mov    0x8(%ebp),%eax
   19709:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19710:	8b 45 0c             	mov    0xc(%ebp),%eax
   19713:	01 d0                	add    %edx,%eax
   19715:	8b 00                	mov    (%eax),%eax
   19717:	85 c0                	test   %eax,%eax
   19719:	74 13                	je     1972e <progTUV+0x10f>
   1971b:	8b 45 08             	mov    0x8(%ebp),%eax
   1971e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19725:	8b 45 0c             	mov    0xc(%ebp),%eax
   19728:	01 d0                	add    %edx,%eax
   1972a:	8b 00                	mov    (%eax),%eax
   1972c:	eb 05                	jmp    19733 <progTUV+0x114>
   1972e:	b8 05 be 01 00       	mov    $0x1be05,%eax
   19733:	83 ec 04             	sub    $0x4,%esp
   19736:	50                   	push   %eax
   19737:	68 0c be 01 00       	push   $0x1be0c
   1973c:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19742:	50                   	push   %eax
   19743:	e8 6a 05 00 00       	call   19cb2 <usprint>
   19748:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1974b:	83 ec 0c             	sub    $0xc,%esp
   1974e:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19754:	50                   	push   %eax
   19755:	e8 45 0c 00 00       	call   1a39f <cwrites>
   1975a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1975d:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   19761:	8b 45 e8             	mov    -0x18(%ebp),%eax
   19764:	3b 45 08             	cmp    0x8(%ebp),%eax
   19767:	7e 9d                	jle    19706 <progTUV+0xe7>
			}
			cwrites( "\n" );
   19769:	83 ec 0c             	sub    $0xc,%esp
   1976c:	68 10 be 01 00       	push   $0x1be10
   19771:	e8 29 0c 00 00       	call   1a39f <cwrites>
   19776:	83 c4 10             	add    $0x10,%esp
	}

	// fix the secondary output message (for indicating errors)
	ch2[1] = ch;
   19779:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   1977d:	88 85 79 fe ff ff    	mov    %al,-0x187(%ebp)

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   19783:	83 ec 04             	sub    $0x4,%esp
   19786:	6a 01                	push   $0x1
   19788:	8d 45 c7             	lea    -0x39(%ebp),%eax
   1978b:	50                   	push   %eax
   1978c:	6a 01                	push   $0x1
   1978e:	e8 9d d7 ff ff       	call   16f30 <write>
   19793:	83 c4 10             	add    $0x10,%esp

	// set up the argument vector
	char *argsw[] = { "progW", "W", "10", "5", NULL };
   19796:	c7 85 64 fe ff ff d2 	movl   $0x1bed2,-0x19c(%ebp)
   1979d:	be 01 00 
   197a0:	c7 85 68 fe ff ff e6 	movl   $0x1bbe6,-0x198(%ebp)
   197a7:	bb 01 00 
   197aa:	c7 85 6c fe ff ff 64 	movl   $0x1bb64,-0x194(%ebp)
   197b1:	bb 01 00 
   197b4:	c7 85 70 fe ff ff 93 	movl   $0x1bb93,-0x190(%ebp)
   197bb:	bb 01 00 
   197be:	c7 85 74 fe ff ff 00 	movl   $0x0,-0x18c(%ebp)
   197c5:	00 00 00 

	for( int i = 0; i < count; ++i ) {
   197c8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   197cf:	eb 4c                	jmp    1981d <progTUV+0x1fe>
		int whom = spawn( (uint32_t) progW, argsw );
   197d1:	ba f4 83 01 00       	mov    $0x183f4,%edx
   197d6:	83 ec 08             	sub    $0x8,%esp
   197d9:	8d 85 64 fe ff ff    	lea    -0x19c(%ebp),%eax
   197df:	50                   	push   %eax
   197e0:	52                   	push   %edx
   197e1:	e8 23 0b 00 00       	call   1a309 <spawn>
   197e6:	83 c4 10             	add    $0x10,%esp
   197e9:	89 45 c8             	mov    %eax,-0x38(%ebp)
		if( whom < 0 ) {
   197ec:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
   197f0:	79 14                	jns    19806 <progTUV+0x1e7>
			swrites( ch2 );
   197f2:	83 ec 0c             	sub    $0xc,%esp
   197f5:	8d 85 78 fe ff ff    	lea    -0x188(%ebp),%eax
   197fb:	50                   	push   %eax
   197fc:	e8 04 0c 00 00       	call   1a405 <swrites>
   19801:	83 c4 10             	add    $0x10,%esp
   19804:	eb 13                	jmp    19819 <progTUV+0x1fa>
		} else {
			children[nkids++] = whom;
   19806:	8b 45 ec             	mov    -0x14(%ebp),%eax
   19809:	8d 50 01             	lea    0x1(%eax),%edx
   1980c:	89 55 ec             	mov    %edx,-0x14(%ebp)
   1980f:	8b 55 c8             	mov    -0x38(%ebp),%edx
   19812:	89 94 85 7c fe ff ff 	mov    %edx,-0x184(%ebp,%eax,4)
	for( int i = 0; i < count; ++i ) {
   19819:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   1981d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   19820:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   19823:	7c ac                	jl     197d1 <progTUV+0x1b2>
		}
	}

	// let the children start
	sleep( SEC_TO_MS(nap) );
   19825:	8b 45 cc             	mov    -0x34(%ebp),%eax
   19828:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   1982e:	83 ec 0c             	sub    $0xc,%esp
   19831:	50                   	push   %eax
   19832:	e8 31 d7 ff ff       	call   16f68 <sleep>
   19837:	83 c4 10             	add    $0x10,%esp

	// collect exit status information

	// current child index
	int n = 0;
   1983a:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	do {
		int this;
		int32_t status;

		// are we waiting for or killing it?
		if( waiting ) {
   19841:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   19845:	74 2f                	je     19876 <progTUV+0x257>
			this = waitpid( bypid ? children[n] : 0, &status );
   19847:	80 7d f2 00          	cmpb   $0x0,-0xe(%ebp)
   1984b:	74 0c                	je     19859 <progTUV+0x23a>
   1984d:	8b 45 e0             	mov    -0x20(%ebp),%eax
   19850:	8b 84 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%eax
   19857:	eb 05                	jmp    1985e <progTUV+0x23f>
   19859:	b8 00 00 00 00       	mov    $0x0,%eax
   1985e:	83 ec 08             	sub    $0x8,%esp
   19861:	8d 95 60 fe ff ff    	lea    -0x1a0(%ebp),%edx
   19867:	52                   	push   %edx
   19868:	50                   	push   %eax
   19869:	e8 a2 d6 ff ff       	call   16f10 <waitpid>
   1986e:	83 c4 10             	add    $0x10,%esp
   19871:	89 45 dc             	mov    %eax,-0x24(%ebp)
   19874:	eb 19                	jmp    1988f <progTUV+0x270>
		} else {
			// always by PID
			this = kill( children[n] );
   19876:	8b 45 e0             	mov    -0x20(%ebp),%eax
   19879:	8b 84 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%eax
   19880:	83 ec 0c             	sub    $0xc,%esp
   19883:	50                   	push   %eax
   19884:	e8 d7 d6 ff ff       	call   16f60 <kill>
   19889:	83 c4 10             	add    $0x10,%esp
   1988c:	89 45 dc             	mov    %eax,-0x24(%ebp)
		}

		// what was the result?
		if( this < SUCCESS ) {
   1988f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   19893:	0f 89 a1 00 00 00    	jns    1993a <progTUV+0x31b>

			// uh-oh - something went wrong

			// "no children" means we're all done
			if( this != E_NO_CHILDREN ) {
   19899:	83 7d dc fc          	cmpl   $0xfffffffc,-0x24(%ebp)
   1989d:	74 77                	je     19916 <progTUV+0x2f7>
				if( waiting ) {
   1989f:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   198a3:	74 3f                	je     198e4 <progTUV+0x2c5>
					usprint( buf, "!! %c: waitpid(%d) status %d\n",
   198a5:	80 7d f2 00          	cmpb   $0x0,-0xe(%ebp)
   198a9:	74 0c                	je     198b7 <progTUV+0x298>
   198ab:	8b 45 e0             	mov    -0x20(%ebp),%eax
   198ae:	8b 84 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%eax
   198b5:	eb 05                	jmp    198bc <progTUV+0x29d>
   198b7:	b8 00 00 00 00       	mov    $0x0,%eax
   198bc:	0f b6 55 c7          	movzbl -0x39(%ebp),%edx
   198c0:	0f be d2             	movsbl %dl,%edx
   198c3:	83 ec 0c             	sub    $0xc,%esp
   198c6:	ff 75 dc             	pushl  -0x24(%ebp)
   198c9:	50                   	push   %eax
   198ca:	52                   	push   %edx
   198cb:	68 a4 bf 01 00       	push   $0x1bfa4
   198d0:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   198d6:	50                   	push   %eax
   198d7:	e8 d6 03 00 00       	call   19cb2 <usprint>
   198dc:	83 c4 20             	add    $0x20,%esp
			} else {
				usprint( buf, "!! %c: no children\n", ch );
			}

			// regardless, we're outta here
			break;
   198df:	e9 9d 01 00 00       	jmp    19a81 <progTUV+0x462>
					usprint( buf, "!! %c: kill(%d) status %d\n",
   198e4:	8b 45 e0             	mov    -0x20(%ebp),%eax
   198e7:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   198ee:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   198f2:	0f be c0             	movsbl %al,%eax
   198f5:	83 ec 0c             	sub    $0xc,%esp
   198f8:	ff 75 dc             	pushl  -0x24(%ebp)
   198fb:	52                   	push   %edx
   198fc:	50                   	push   %eax
   198fd:	68 d8 be 01 00       	push   $0x1bed8
   19902:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19908:	50                   	push   %eax
   19909:	e8 a4 03 00 00       	call   19cb2 <usprint>
   1990e:	83 c4 20             	add    $0x20,%esp
			break;
   19911:	e9 6b 01 00 00       	jmp    19a81 <progTUV+0x462>
				usprint( buf, "!! %c: no children\n", ch );
   19916:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   1991a:	0f be c0             	movsbl %al,%eax
   1991d:	83 ec 04             	sub    $0x4,%esp
   19920:	50                   	push   %eax
   19921:	68 c2 bf 01 00       	push   $0x1bfc2
   19926:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   1992c:	50                   	push   %eax
   1992d:	e8 80 03 00 00       	call   19cb2 <usprint>
   19932:	83 c4 10             	add    $0x10,%esp
   19935:	e9 47 01 00 00       	jmp    19a81 <progTUV+0x462>

		} else {

			// locate the child
			int ix = -1;
   1993a:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)

			// were we looking by PID?
			if( bypid ) {
   19941:	80 7d f2 00          	cmpb   $0x0,-0xe(%ebp)
   19945:	74 58                	je     1999f <progTUV+0x380>
				// we should have just gotten the one we were looking for
				if( this != children[n] ) {
   19947:	8b 45 e0             	mov    -0x20(%ebp),%eax
   1994a:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   19951:	8b 45 dc             	mov    -0x24(%ebp),%eax
   19954:	39 c2                	cmp    %eax,%edx
   19956:	74 41                	je     19999 <progTUV+0x37a>
					// uh-oh
					usprint( buf, "** %c: wait/kill PID %d, got %d\n",
   19958:	8b 45 e0             	mov    -0x20(%ebp),%eax
   1995b:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   19962:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   19966:	0f be c0             	movsbl %al,%eax
   19969:	83 ec 0c             	sub    $0xc,%esp
   1996c:	ff 75 dc             	pushl  -0x24(%ebp)
   1996f:	52                   	push   %edx
   19970:	50                   	push   %eax
   19971:	68 d8 bf 01 00       	push   $0x1bfd8
   19976:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   1997c:	50                   	push   %eax
   1997d:	e8 30 03 00 00       	call   19cb2 <usprint>
   19982:	83 c4 20             	add    $0x20,%esp
							ch, children[n], this );
					cwrites( buf );
   19985:	83 ec 0c             	sub    $0xc,%esp
   19988:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   1998e:	50                   	push   %eax
   1998f:	e8 0b 0a 00 00       	call   1a39f <cwrites>
   19994:	83 c4 10             	add    $0x10,%esp
   19997:	eb 06                	jmp    1999f <progTUV+0x380>
				} else {
					ix = n;
   19999:	8b 45 e0             	mov    -0x20(%ebp),%eax
   1999c:	89 45 d8             	mov    %eax,-0x28(%ebp)
				}
			}

			// either not looking by PID, or the lookup failed somehow
			if( ix < 0 ) {
   1999f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   199a3:	79 2e                	jns    199d3 <progTUV+0x3b4>
				int i;
				for( i = 0; i < nkids; ++i ) {
   199a5:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
   199ac:	eb 1d                	jmp    199cb <progTUV+0x3ac>
					if( children[i] == this ) {
   199ae:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   199b1:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   199b8:	8b 45 dc             	mov    -0x24(%ebp),%eax
   199bb:	39 c2                	cmp    %eax,%edx
   199bd:	75 08                	jne    199c7 <progTUV+0x3a8>
						ix = i;
   199bf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   199c2:	89 45 d8             	mov    %eax,-0x28(%ebp)
						break;
   199c5:	eb 0c                	jmp    199d3 <progTUV+0x3b4>
				for( i = 0; i < nkids; ++i ) {
   199c7:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
   199cb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   199ce:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   199d1:	7c db                	jl     199ae <progTUV+0x38f>
				}
			}

			// if ix == -1, the PID we received isn't in our list of children

			if( ix < 0 ) {
   199d3:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   199d7:	79 21                	jns    199fa <progTUV+0x3db>

				// didn't find an entry for this PID???
				usprint( buf, "!! %c: child PID %d term, NOT FOUND\n",
   199d9:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   199dd:	0f be c0             	movsbl %al,%eax
   199e0:	ff 75 dc             	pushl  -0x24(%ebp)
   199e3:	50                   	push   %eax
   199e4:	68 fc bf 01 00       	push   $0x1bffc
   199e9:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   199ef:	50                   	push   %eax
   199f0:	e8 bd 02 00 00       	call   19cb2 <usprint>
   199f5:	83 c4 10             	add    $0x10,%esp
   199f8:	eb 65                	jmp    19a5f <progTUV+0x440>
						ch, this );

			} else {

				// found this PID in our list of children
				if( ix != n ) {
   199fa:	8b 45 d8             	mov    -0x28(%ebp),%eax
   199fd:	3b 45 e0             	cmp    -0x20(%ebp),%eax
   19a00:	74 31                	je     19a33 <progTUV+0x414>
					// ... but it's out of sequence
					usprint( buf, "== %c: child %d (%d,%d) status %d\n",
   19a02:	8b 95 60 fe ff ff    	mov    -0x1a0(%ebp),%edx
   19a08:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   19a0c:	0f be c0             	movsbl %al,%eax
   19a0f:	83 ec 04             	sub    $0x4,%esp
   19a12:	52                   	push   %edx
   19a13:	ff 75 dc             	pushl  -0x24(%ebp)
   19a16:	ff 75 e0             	pushl  -0x20(%ebp)
   19a19:	ff 75 d8             	pushl  -0x28(%ebp)
   19a1c:	50                   	push   %eax
   19a1d:	68 24 c0 01 00       	push   $0x1c024
   19a22:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19a28:	50                   	push   %eax
   19a29:	e8 84 02 00 00       	call   19cb2 <usprint>
   19a2e:	83 c4 20             	add    $0x20,%esp
   19a31:	eb 2c                	jmp    19a5f <progTUV+0x440>
							ch, ix, n, this, status );
				} else {
					usprint( buf, "== %c: child %d (%d) status %d\n",
   19a33:	8b 95 60 fe ff ff    	mov    -0x1a0(%ebp),%edx
   19a39:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   19a3d:	0f be c0             	movsbl %al,%eax
   19a40:	83 ec 08             	sub    $0x8,%esp
   19a43:	52                   	push   %edx
   19a44:	ff 75 dc             	pushl  -0x24(%ebp)
   19a47:	ff 75 d8             	pushl  -0x28(%ebp)
   19a4a:	50                   	push   %eax
   19a4b:	68 48 c0 01 00       	push   $0x1c048
   19a50:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19a56:	50                   	push   %eax
   19a57:	e8 56 02 00 00       	call   19cb2 <usprint>
   19a5c:	83 c4 20             	add    $0x20,%esp
				}
			}

		}

		cwrites( buf );
   19a5f:	83 ec 0c             	sub    $0xc,%esp
   19a62:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19a68:	50                   	push   %eax
   19a69:	e8 31 09 00 00       	call   1a39f <cwrites>
   19a6e:	83 c4 10             	add    $0x10,%esp

		++n;
   19a71:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)

	} while( n < nkids );
   19a75:	8b 45 e0             	mov    -0x20(%ebp),%eax
   19a78:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   19a7b:	0f 8c c0 fd ff ff    	jl     19841 <progTUV+0x222>

	exit( 0 );
   19a81:	83 ec 0c             	sub    $0xc,%esp
   19a84:	6a 00                	push   $0x0
   19a86:	e8 7d d4 ff ff       	call   16f08 <exit>
   19a8b:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   19a8e:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   19a93:	c9                   	leave  
   19a94:	c3                   	ret    

00019a95 <ublkmov>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void ublkmov( void *dst, const void *src, register uint32_t len ) {
   19a95:	55                   	push   %ebp
   19a96:	89 e5                	mov    %esp,%ebp
   19a98:	56                   	push   %esi
   19a99:	53                   	push   %ebx
   19a9a:	8b 45 10             	mov    0x10(%ebp),%eax

	// verify that the addresses are aligned and
	// the length is a multiple of four bytes
	if( (((uint32_t)dst)&0x3) != 0 ||
   19a9d:	8b 55 08             	mov    0x8(%ebp),%edx
   19aa0:	83 e2 03             	and    $0x3,%edx
   19aa3:	85 d2                	test   %edx,%edx
   19aa5:	75 13                	jne    19aba <ublkmov+0x25>
		(((uint32_t)src)&0x3) != 0 ||
   19aa7:	8b 55 0c             	mov    0xc(%ebp),%edx
   19aaa:	83 e2 03             	and    $0x3,%edx
	if( (((uint32_t)dst)&0x3) != 0 ||
   19aad:	85 d2                	test   %edx,%edx
   19aaf:	75 09                	jne    19aba <ublkmov+0x25>
		(len & 0x3) != 0 ) {
   19ab1:	89 c2                	mov    %eax,%edx
   19ab3:	83 e2 03             	and    $0x3,%edx
		(((uint32_t)src)&0x3) != 0 ||
   19ab6:	85 d2                	test   %edx,%edx
   19ab8:	74 14                	je     19ace <ublkmov+0x39>
		// something isn't aligned, so just use memmove()
		umemmove( dst, src, len );
   19aba:	83 ec 04             	sub    $0x4,%esp
   19abd:	50                   	push   %eax
   19abe:	ff 75 0c             	pushl  0xc(%ebp)
   19ac1:	ff 75 08             	pushl  0x8(%ebp)
   19ac4:	e8 b4 00 00 00       	call   19b7d <umemmove>
   19ac9:	83 c4 10             	add    $0x10,%esp
		return;
   19acc:	eb 5a                	jmp    19b28 <ublkmov+0x93>
	}

	// everything is nicely aligned, so off we go
	register uint32_t *dest = dst;
   19ace:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint32_t *source = src;
   19ad1:	8b 75 0c             	mov    0xc(%ebp),%esi

	// now copying 32-bit values
	len /= 4;
   19ad4:	c1 e8 02             	shr    $0x2,%eax

	if( source < dest && (source + len) > dest ) {
   19ad7:	39 de                	cmp    %ebx,%esi
   19ad9:	73 44                	jae    19b1f <ublkmov+0x8a>
   19adb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19ae2:	01 f2                	add    %esi,%edx
   19ae4:	39 d3                	cmp    %edx,%ebx
   19ae6:	73 37                	jae    19b1f <ublkmov+0x8a>
		source += len;
   19ae8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19aef:	01 d6                	add    %edx,%esi
		dest += len;
   19af1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19af8:	01 d3                	add    %edx,%ebx
		while( len-- > 0 ) {
   19afa:	eb 0a                	jmp    19b06 <ublkmov+0x71>
			*--dest = *--source;
   19afc:	83 ee 04             	sub    $0x4,%esi
   19aff:	83 eb 04             	sub    $0x4,%ebx
   19b02:	8b 16                	mov    (%esi),%edx
   19b04:	89 13                	mov    %edx,(%ebx)
		while( len-- > 0 ) {
   19b06:	89 c2                	mov    %eax,%edx
   19b08:	8d 42 ff             	lea    -0x1(%edx),%eax
   19b0b:	85 d2                	test   %edx,%edx
   19b0d:	75 ed                	jne    19afc <ublkmov+0x67>
	if( source < dest && (source + len) > dest ) {
   19b0f:	eb 17                	jmp    19b28 <ublkmov+0x93>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   19b11:	89 f1                	mov    %esi,%ecx
   19b13:	8d 71 04             	lea    0x4(%ecx),%esi
   19b16:	89 da                	mov    %ebx,%edx
   19b18:	8d 5a 04             	lea    0x4(%edx),%ebx
   19b1b:	8b 09                	mov    (%ecx),%ecx
   19b1d:	89 0a                	mov    %ecx,(%edx)
		while( len-- ) {
   19b1f:	89 c2                	mov    %eax,%edx
   19b21:	8d 42 ff             	lea    -0x1(%edx),%eax
   19b24:	85 d2                	test   %edx,%edx
   19b26:	75 e9                	jne    19b11 <ublkmov+0x7c>
		}
	}
}
   19b28:	8d 65 f8             	lea    -0x8(%ebp),%esp
   19b2b:	5b                   	pop    %ebx
   19b2c:	5e                   	pop    %esi
   19b2d:	5d                   	pop    %ebp
   19b2e:	c3                   	ret    

00019b2f <umemclr>:
** Initialize all bytes of a block of memory to zero
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
*/
void umemclr( void *buf, register uint32_t len ) {
   19b2f:	55                   	push   %ebp
   19b30:	89 e5                	mov    %esp,%ebp
   19b32:	53                   	push   %ebx
   19b33:	8b 55 0c             	mov    0xc(%ebp),%edx
	register uint8_t *dest = buf;
   19b36:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and clearing
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   19b39:	eb 08                	jmp    19b43 <umemclr+0x14>
			*dest++ = 0;
   19b3b:	89 d8                	mov    %ebx,%eax
   19b3d:	8d 58 01             	lea    0x1(%eax),%ebx
   19b40:	c6 00 00             	movb   $0x0,(%eax)
	while( len-- ) {
   19b43:	89 d0                	mov    %edx,%eax
   19b45:	8d 50 ff             	lea    -0x1(%eax),%edx
   19b48:	85 c0                	test   %eax,%eax
   19b4a:	75 ef                	jne    19b3b <umemclr+0xc>
	}
}
   19b4c:	90                   	nop
   19b4d:	5b                   	pop    %ebx
   19b4e:	5d                   	pop    %ebp
   19b4f:	c3                   	ret    

00019b50 <umemcpy>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void umemcpy( void *dst, register const void *src, register uint32_t len ) {
   19b50:	55                   	push   %ebp
   19b51:	89 e5                	mov    %esp,%ebp
   19b53:	56                   	push   %esi
   19b54:	53                   	push   %ebx
   19b55:	8b 4d 10             	mov    0x10(%ebp),%ecx
	register uint8_t *dest = dst;
   19b58:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint8_t *source = src;
   19b5b:	8b 75 0c             	mov    0xc(%ebp),%esi
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   19b5e:	eb 0f                	jmp    19b6f <umemcpy+0x1f>
		*dest++ = *source++;
   19b60:	89 f2                	mov    %esi,%edx
   19b62:	8d 72 01             	lea    0x1(%edx),%esi
   19b65:	89 d8                	mov    %ebx,%eax
   19b67:	8d 58 01             	lea    0x1(%eax),%ebx
   19b6a:	0f b6 12             	movzbl (%edx),%edx
   19b6d:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   19b6f:	89 c8                	mov    %ecx,%eax
   19b71:	8d 48 ff             	lea    -0x1(%eax),%ecx
   19b74:	85 c0                	test   %eax,%eax
   19b76:	75 e8                	jne    19b60 <umemcpy+0x10>
	}
}
   19b78:	90                   	nop
   19b79:	5b                   	pop    %ebx
   19b7a:	5e                   	pop    %esi
   19b7b:	5d                   	pop    %ebp
   19b7c:	c3                   	ret    

00019b7d <umemmove>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void umemmove( void *dst, const void *src, register uint32_t len ) {
   19b7d:	55                   	push   %ebp
   19b7e:	89 e5                	mov    %esp,%ebp
   19b80:	56                   	push   %esi
   19b81:	53                   	push   %ebx
   19b82:	8b 45 10             	mov    0x10(%ebp),%eax
	register uint8_t *dest = dst;
   19b85:	8b 75 08             	mov    0x8(%ebp),%esi
	register const uint8_t *source = src;
   19b88:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	if( source < dest && (source + len) > dest ) {
   19b8b:	39 f3                	cmp    %esi,%ebx
   19b8d:	73 32                	jae    19bc1 <umemmove+0x44>
   19b8f:	8d 14 03             	lea    (%ebx,%eax,1),%edx
   19b92:	39 d6                	cmp    %edx,%esi
   19b94:	73 2b                	jae    19bc1 <umemmove+0x44>
		source += len;
   19b96:	01 c3                	add    %eax,%ebx
		dest += len;
   19b98:	01 c6                	add    %eax,%esi
		while( len-- > 0 ) {
   19b9a:	eb 0b                	jmp    19ba7 <umemmove+0x2a>
			*--dest = *--source;
   19b9c:	83 eb 01             	sub    $0x1,%ebx
   19b9f:	83 ee 01             	sub    $0x1,%esi
   19ba2:	0f b6 13             	movzbl (%ebx),%edx
   19ba5:	88 16                	mov    %dl,(%esi)
		while( len-- > 0 ) {
   19ba7:	89 c2                	mov    %eax,%edx
   19ba9:	8d 42 ff             	lea    -0x1(%edx),%eax
   19bac:	85 d2                	test   %edx,%edx
   19bae:	75 ec                	jne    19b9c <umemmove+0x1f>
	if( source < dest && (source + len) > dest ) {
   19bb0:	eb 18                	jmp    19bca <umemmove+0x4d>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   19bb2:	89 d9                	mov    %ebx,%ecx
   19bb4:	8d 59 01             	lea    0x1(%ecx),%ebx
   19bb7:	89 f2                	mov    %esi,%edx
   19bb9:	8d 72 01             	lea    0x1(%edx),%esi
   19bbc:	0f b6 09             	movzbl (%ecx),%ecx
   19bbf:	88 0a                	mov    %cl,(%edx)
		while( len-- ) {
   19bc1:	89 c2                	mov    %eax,%edx
   19bc3:	8d 42 ff             	lea    -0x1(%edx),%eax
   19bc6:	85 d2                	test   %edx,%edx
   19bc8:	75 e8                	jne    19bb2 <umemmove+0x35>
		}
	}
}
   19bca:	90                   	nop
   19bcb:	5b                   	pop    %ebx
   19bcc:	5e                   	pop    %esi
   19bcd:	5d                   	pop    %ebp
   19bce:	c3                   	ret    

00019bcf <umemset>:
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
** @param value  Initialization value
*/
void umemset( void *buf, register uint32_t len, register uint32_t value ) {
   19bcf:	55                   	push   %ebp
   19bd0:	89 e5                	mov    %esp,%ebp
   19bd2:	53                   	push   %ebx
   19bd3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register uint8_t *bp = buf;
   19bd6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   19bd9:	eb 0b                	jmp    19be6 <umemset+0x17>
		*bp++ = value;
   19bdb:	89 d8                	mov    %ebx,%eax
   19bdd:	8d 58 01             	lea    0x1(%eax),%ebx
   19be0:	0f b6 55 10          	movzbl 0x10(%ebp),%edx
   19be4:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   19be6:	89 c8                	mov    %ecx,%eax
   19be8:	8d 48 ff             	lea    -0x1(%eax),%ecx
   19beb:	85 c0                	test   %eax,%eax
   19bed:	75 ec                	jne    19bdb <umemset+0xc>
	}
}
   19bef:	90                   	nop
   19bf0:	5b                   	pop    %ebx
   19bf1:	5d                   	pop    %ebp
   19bf2:	c3                   	ret    

00019bf3 <upad>:
**
** @return Pointer to the first byte after the padding
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *upad( char *dst, int extra, int padchar ) {
   19bf3:	55                   	push   %ebp
   19bf4:	89 e5                	mov    %esp,%ebp
	while( extra > 0 ){
   19bf6:	eb 12                	jmp    19c0a <upad+0x17>
		*dst++ = (char) padchar;
   19bf8:	8b 45 08             	mov    0x8(%ebp),%eax
   19bfb:	8d 50 01             	lea    0x1(%eax),%edx
   19bfe:	89 55 08             	mov    %edx,0x8(%ebp)
   19c01:	8b 55 10             	mov    0x10(%ebp),%edx
   19c04:	88 10                	mov    %dl,(%eax)
		extra -= 1;
   19c06:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
	while( extra > 0 ){
   19c0a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   19c0e:	7f e8                	jg     19bf8 <upad+0x5>
	}
	return dst;
   19c10:	8b 45 08             	mov    0x8(%ebp),%eax
}
   19c13:	5d                   	pop    %ebp
   19c14:	c3                   	ret    

00019c15 <upadstr>:
** @return Pointer to the first byte after the padded string
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *upadstr( char *dst, char *str, int len, int width,
				int leftadjust, int padchar ) {
   19c15:	55                   	push   %ebp
   19c16:	89 e5                	mov    %esp,%ebp
   19c18:	83 ec 18             	sub    $0x18,%esp
	int extra;

	// determine the length of the string if we need to
	if( len < 0 ){
   19c1b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
   19c1f:	79 11                	jns    19c32 <upadstr+0x1d>
		len = ustrlen( str );
   19c21:	83 ec 0c             	sub    $0xc,%esp
   19c24:	ff 75 0c             	pushl  0xc(%ebp)
   19c27:	e8 03 04 00 00       	call   1a02f <ustrlen>
   19c2c:	83 c4 10             	add    $0x10,%esp
   19c2f:	89 45 10             	mov    %eax,0x10(%ebp)
	}

	// how much filler must we add?
	extra = width - len;
   19c32:	8b 45 14             	mov    0x14(%ebp),%eax
   19c35:	2b 45 10             	sub    0x10(%ebp),%eax
   19c38:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// add filler on the left if we're not left-justifying
	if( extra > 0 && !leftadjust ){
   19c3b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   19c3f:	7e 1d                	jle    19c5e <upadstr+0x49>
   19c41:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   19c45:	75 17                	jne    19c5e <upadstr+0x49>
		dst = upad( dst, extra, padchar );
   19c47:	83 ec 04             	sub    $0x4,%esp
   19c4a:	ff 75 1c             	pushl  0x1c(%ebp)
   19c4d:	ff 75 f0             	pushl  -0x10(%ebp)
   19c50:	ff 75 08             	pushl  0x8(%ebp)
   19c53:	e8 9b ff ff ff       	call   19bf3 <upad>
   19c58:	83 c4 10             	add    $0x10,%esp
   19c5b:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	// copy the string itself
	for( int i = 0; i < len; ++i ) {
   19c5e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   19c65:	eb 1b                	jmp    19c82 <upadstr+0x6d>
		*dst++ = str[i];
   19c67:	8b 55 f4             	mov    -0xc(%ebp),%edx
   19c6a:	8b 45 0c             	mov    0xc(%ebp),%eax
   19c6d:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
   19c70:	8b 45 08             	mov    0x8(%ebp),%eax
   19c73:	8d 50 01             	lea    0x1(%eax),%edx
   19c76:	89 55 08             	mov    %edx,0x8(%ebp)
   19c79:	0f b6 11             	movzbl (%ecx),%edx
   19c7c:	88 10                	mov    %dl,(%eax)
	for( int i = 0; i < len; ++i ) {
   19c7e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   19c82:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19c85:	3b 45 10             	cmp    0x10(%ebp),%eax
   19c88:	7c dd                	jl     19c67 <upadstr+0x52>
	}

	// add filler on the right if we are left-justifying
	if( extra > 0 && leftadjust ){
   19c8a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   19c8e:	7e 1d                	jle    19cad <upadstr+0x98>
   19c90:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   19c94:	74 17                	je     19cad <upadstr+0x98>
		dst = upad( dst, extra, padchar );
   19c96:	83 ec 04             	sub    $0x4,%esp
   19c99:	ff 75 1c             	pushl  0x1c(%ebp)
   19c9c:	ff 75 f0             	pushl  -0x10(%ebp)
   19c9f:	ff 75 08             	pushl  0x8(%ebp)
   19ca2:	e8 4c ff ff ff       	call   19bf3 <upad>
   19ca7:	83 c4 10             	add    $0x10,%esp
   19caa:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	return dst;
   19cad:	8b 45 08             	mov    0x8(%ebp),%eax
}
   19cb0:	c9                   	leave  
   19cb1:	c3                   	ret    

00019cb2 <usprint>:
**
** NOTE:  relies heavily on the x86 parameter passing convention
** (parameters are pushed onto the stack in reverse order as
** 32-bit values).
*/
void usprint( char *dst, char *fmt, ... ) {
   19cb2:	55                   	push   %ebp
   19cb3:	89 e5                	mov    %esp,%ebp
   19cb5:	83 ec 38             	sub    $0x38,%esp
	** to point to the next "thing", and interpret it according
	** to the format string.
	*/
	
	// get the pointer to the first "value" parameter
	ap = (int *)(&fmt) + 1;
   19cb8:	8d 45 0c             	lea    0xc(%ebp),%eax
   19cbb:	83 c0 04             	add    $0x4,%eax
   19cbe:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// iterate through the format string
	while( (ch = *fmt++) != '\0' ){
   19cc1:	e9 3f 02 00 00       	jmp    19f05 <usprint+0x253>
		/*
		** Is it the start of a format code?
		*/
		if( ch == '%' ){
   19cc6:	80 7d f3 25          	cmpb   $0x25,-0xd(%ebp)
   19cca:	0f 85 26 02 00 00    	jne    19ef6 <usprint+0x244>
			/*
			** Yes, get the padding and width options (if there).
			** Alignment must come at the beginning, then fill,
			** then width.
			*/
			leftadjust = 0;
   19cd0:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
			padchar = ' ';
   19cd7:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
			width = 0;
   19cde:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
			ch = *fmt++;
   19ce5:	8b 45 0c             	mov    0xc(%ebp),%eax
   19ce8:	8d 50 01             	lea    0x1(%eax),%edx
   19ceb:	89 55 0c             	mov    %edx,0xc(%ebp)
   19cee:	0f b6 00             	movzbl (%eax),%eax
   19cf1:	88 45 f3             	mov    %al,-0xd(%ebp)
			if( ch == '-' ){
   19cf4:	80 7d f3 2d          	cmpb   $0x2d,-0xd(%ebp)
   19cf8:	75 16                	jne    19d10 <usprint+0x5e>
				leftadjust = 1;
   19cfa:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
				ch = *fmt++;
   19d01:	8b 45 0c             	mov    0xc(%ebp),%eax
   19d04:	8d 50 01             	lea    0x1(%eax),%edx
   19d07:	89 55 0c             	mov    %edx,0xc(%ebp)
   19d0a:	0f b6 00             	movzbl (%eax),%eax
   19d0d:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			if( ch == '0' ){
   19d10:	80 7d f3 30          	cmpb   $0x30,-0xd(%ebp)
   19d14:	75 40                	jne    19d56 <usprint+0xa4>
				padchar = '0';
   19d16:	c7 45 e4 30 00 00 00 	movl   $0x30,-0x1c(%ebp)
				ch = *fmt++;
   19d1d:	8b 45 0c             	mov    0xc(%ebp),%eax
   19d20:	8d 50 01             	lea    0x1(%eax),%edx
   19d23:	89 55 0c             	mov    %edx,0xc(%ebp)
   19d26:	0f b6 00             	movzbl (%eax),%eax
   19d29:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			while( ch >= '0' && ch <= '9' ){
   19d2c:	eb 28                	jmp    19d56 <usprint+0xa4>
				width *= 10;
   19d2e:	8b 55 e8             	mov    -0x18(%ebp),%edx
   19d31:	89 d0                	mov    %edx,%eax
   19d33:	c1 e0 02             	shl    $0x2,%eax
   19d36:	01 d0                	add    %edx,%eax
   19d38:	01 c0                	add    %eax,%eax
   19d3a:	89 45 e8             	mov    %eax,-0x18(%ebp)
				width += ch - '0';
   19d3d:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   19d41:	83 e8 30             	sub    $0x30,%eax
   19d44:	01 45 e8             	add    %eax,-0x18(%ebp)
				ch = *fmt++;
   19d47:	8b 45 0c             	mov    0xc(%ebp),%eax
   19d4a:	8d 50 01             	lea    0x1(%eax),%edx
   19d4d:	89 55 0c             	mov    %edx,0xc(%ebp)
   19d50:	0f b6 00             	movzbl (%eax),%eax
   19d53:	88 45 f3             	mov    %al,-0xd(%ebp)
			while( ch >= '0' && ch <= '9' ){
   19d56:	80 7d f3 2f          	cmpb   $0x2f,-0xd(%ebp)
   19d5a:	7e 06                	jle    19d62 <usprint+0xb0>
   19d5c:	80 7d f3 39          	cmpb   $0x39,-0xd(%ebp)
   19d60:	7e cc                	jle    19d2e <usprint+0x7c>
			}

			/*
			** What data type do we have?
			*/
			switch( ch ) {
   19d62:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   19d66:	83 e8 63             	sub    $0x63,%eax
   19d69:	83 f8 15             	cmp    $0x15,%eax
   19d6c:	0f 87 93 01 00 00    	ja     19f05 <usprint+0x253>
   19d72:	8b 04 85 68 c0 01 00 	mov    0x1c068(,%eax,4),%eax
   19d79:	ff e0                	jmp    *%eax

			case 'c':  // characters are passed as 32-bit values
				ch = *ap++;
   19d7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19d7e:	8d 50 04             	lea    0x4(%eax),%edx
   19d81:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19d84:	8b 00                	mov    (%eax),%eax
   19d86:	88 45 f3             	mov    %al,-0xd(%ebp)
				buf[ 0 ] = ch;
   19d89:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   19d8d:	88 45 d0             	mov    %al,-0x30(%ebp)
				buf[ 1 ] = '\0';
   19d90:	c6 45 d1 00          	movb   $0x0,-0x2f(%ebp)
				dst = upadstr( dst, buf, 1, width, leftadjust, padchar );
   19d94:	83 ec 08             	sub    $0x8,%esp
   19d97:	ff 75 e4             	pushl  -0x1c(%ebp)
   19d9a:	ff 75 ec             	pushl  -0x14(%ebp)
   19d9d:	ff 75 e8             	pushl  -0x18(%ebp)
   19da0:	6a 01                	push   $0x1
   19da2:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19da5:	50                   	push   %eax
   19da6:	ff 75 08             	pushl  0x8(%ebp)
   19da9:	e8 67 fe ff ff       	call   19c15 <upadstr>
   19dae:	83 c4 20             	add    $0x20,%esp
   19db1:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19db4:	e9 4c 01 00 00       	jmp    19f05 <usprint+0x253>

			case 'd':
				len = ucvtdec( buf, *ap++ );
   19db9:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19dbc:	8d 50 04             	lea    0x4(%eax),%edx
   19dbf:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19dc2:	8b 00                	mov    (%eax),%eax
   19dc4:	83 ec 08             	sub    $0x8,%esp
   19dc7:	50                   	push   %eax
   19dc8:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19dcb:	50                   	push   %eax
   19dcc:	e8 a4 02 00 00       	call   1a075 <ucvtdec>
   19dd1:	83 c4 10             	add    $0x10,%esp
   19dd4:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = upadstr( dst, buf, len, width, leftadjust, padchar );
   19dd7:	83 ec 08             	sub    $0x8,%esp
   19dda:	ff 75 e4             	pushl  -0x1c(%ebp)
   19ddd:	ff 75 ec             	pushl  -0x14(%ebp)
   19de0:	ff 75 e8             	pushl  -0x18(%ebp)
   19de3:	ff 75 e0             	pushl  -0x20(%ebp)
   19de6:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19de9:	50                   	push   %eax
   19dea:	ff 75 08             	pushl  0x8(%ebp)
   19ded:	e8 23 fe ff ff       	call   19c15 <upadstr>
   19df2:	83 c4 20             	add    $0x20,%esp
   19df5:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19df8:	e9 08 01 00 00       	jmp    19f05 <usprint+0x253>

			case 's':
				str = (char *) (*ap++);
   19dfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19e00:	8d 50 04             	lea    0x4(%eax),%edx
   19e03:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19e06:	8b 00                	mov    (%eax),%eax
   19e08:	89 45 dc             	mov    %eax,-0x24(%ebp)
				dst = upadstr( dst, str, -1, width, leftadjust, padchar );
   19e0b:	83 ec 08             	sub    $0x8,%esp
   19e0e:	ff 75 e4             	pushl  -0x1c(%ebp)
   19e11:	ff 75 ec             	pushl  -0x14(%ebp)
   19e14:	ff 75 e8             	pushl  -0x18(%ebp)
   19e17:	6a ff                	push   $0xffffffff
   19e19:	ff 75 dc             	pushl  -0x24(%ebp)
   19e1c:	ff 75 08             	pushl  0x8(%ebp)
   19e1f:	e8 f1 fd ff ff       	call   19c15 <upadstr>
   19e24:	83 c4 20             	add    $0x20,%esp
   19e27:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19e2a:	e9 d6 00 00 00       	jmp    19f05 <usprint+0x253>

			case 'x':
				len = ucvthex( buf, *ap++ );
   19e2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19e32:	8d 50 04             	lea    0x4(%eax),%edx
   19e35:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19e38:	8b 00                	mov    (%eax),%eax
   19e3a:	83 ec 08             	sub    $0x8,%esp
   19e3d:	50                   	push   %eax
   19e3e:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19e41:	50                   	push   %eax
   19e42:	e8 fe 02 00 00       	call   1a145 <ucvthex>
   19e47:	83 c4 10             	add    $0x10,%esp
   19e4a:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = upadstr( dst, buf, len, width, leftadjust, padchar );
   19e4d:	83 ec 08             	sub    $0x8,%esp
   19e50:	ff 75 e4             	pushl  -0x1c(%ebp)
   19e53:	ff 75 ec             	pushl  -0x14(%ebp)
   19e56:	ff 75 e8             	pushl  -0x18(%ebp)
   19e59:	ff 75 e0             	pushl  -0x20(%ebp)
   19e5c:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19e5f:	50                   	push   %eax
   19e60:	ff 75 08             	pushl  0x8(%ebp)
   19e63:	e8 ad fd ff ff       	call   19c15 <upadstr>
   19e68:	83 c4 20             	add    $0x20,%esp
   19e6b:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19e6e:	e9 92 00 00 00       	jmp    19f05 <usprint+0x253>

			case 'o':
				len = ucvtoct( buf, *ap++ );
   19e73:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19e76:	8d 50 04             	lea    0x4(%eax),%edx
   19e79:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19e7c:	8b 00                	mov    (%eax),%eax
   19e7e:	83 ec 08             	sub    $0x8,%esp
   19e81:	50                   	push   %eax
   19e82:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19e85:	50                   	push   %eax
   19e86:	e8 44 03 00 00       	call   1a1cf <ucvtoct>
   19e8b:	83 c4 10             	add    $0x10,%esp
   19e8e:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = upadstr( dst, buf, len, width, leftadjust, padchar );
   19e91:	83 ec 08             	sub    $0x8,%esp
   19e94:	ff 75 e4             	pushl  -0x1c(%ebp)
   19e97:	ff 75 ec             	pushl  -0x14(%ebp)
   19e9a:	ff 75 e8             	pushl  -0x18(%ebp)
   19e9d:	ff 75 e0             	pushl  -0x20(%ebp)
   19ea0:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19ea3:	50                   	push   %eax
   19ea4:	ff 75 08             	pushl  0x8(%ebp)
   19ea7:	e8 69 fd ff ff       	call   19c15 <upadstr>
   19eac:	83 c4 20             	add    $0x20,%esp
   19eaf:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19eb2:	eb 51                	jmp    19f05 <usprint+0x253>

			case 'u':
				len = ucvtuns( buf, *ap++ );
   19eb4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19eb7:	8d 50 04             	lea    0x4(%eax),%edx
   19eba:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19ebd:	8b 00                	mov    (%eax),%eax
   19ebf:	83 ec 08             	sub    $0x8,%esp
   19ec2:	50                   	push   %eax
   19ec3:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19ec6:	50                   	push   %eax
   19ec7:	e8 8d 03 00 00       	call   1a259 <ucvtuns>
   19ecc:	83 c4 10             	add    $0x10,%esp
   19ecf:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = upadstr( dst, buf, len, width, leftadjust, padchar );
   19ed2:	83 ec 08             	sub    $0x8,%esp
   19ed5:	ff 75 e4             	pushl  -0x1c(%ebp)
   19ed8:	ff 75 ec             	pushl  -0x14(%ebp)
   19edb:	ff 75 e8             	pushl  -0x18(%ebp)
   19ede:	ff 75 e0             	pushl  -0x20(%ebp)
   19ee1:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19ee4:	50                   	push   %eax
   19ee5:	ff 75 08             	pushl  0x8(%ebp)
   19ee8:	e8 28 fd ff ff       	call   19c15 <upadstr>
   19eed:	83 c4 20             	add    $0x20,%esp
   19ef0:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19ef3:	90                   	nop
   19ef4:	eb 0f                	jmp    19f05 <usprint+0x253>

			}
		} else {
			// no, it's just an ordinary character
			*dst++ = ch;
   19ef6:	8b 45 08             	mov    0x8(%ebp),%eax
   19ef9:	8d 50 01             	lea    0x1(%eax),%edx
   19efc:	89 55 08             	mov    %edx,0x8(%ebp)
   19eff:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
   19f03:	88 10                	mov    %dl,(%eax)
	while( (ch = *fmt++) != '\0' ){
   19f05:	8b 45 0c             	mov    0xc(%ebp),%eax
   19f08:	8d 50 01             	lea    0x1(%eax),%edx
   19f0b:	89 55 0c             	mov    %edx,0xc(%ebp)
   19f0e:	0f b6 00             	movzbl (%eax),%eax
   19f11:	88 45 f3             	mov    %al,-0xd(%ebp)
   19f14:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   19f18:	0f 85 a8 fd ff ff    	jne    19cc6 <usprint+0x14>
		}
	}

	// NUL-terminate the result
	*dst = '\0';
   19f1e:	8b 45 08             	mov    0x8(%ebp),%eax
   19f21:	c6 00 00             	movb   $0x0,(%eax)
}
   19f24:	90                   	nop
   19f25:	c9                   	leave  
   19f26:	c3                   	ret    

00019f27 <ustr2int>:
** @param str   The string to examine
** @param base  The radix to use in the conversion
**
** @return The converted integer
*/
int ustr2int( register const char *str, register int base ) {
   19f27:	55                   	push   %ebp
   19f28:	89 e5                	mov    %esp,%ebp
   19f2a:	53                   	push   %ebx
   19f2b:	83 ec 14             	sub    $0x14,%esp
   19f2e:	8b 45 08             	mov    0x8(%ebp),%eax
   19f31:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register int num = 0;
   19f34:	bb 00 00 00 00       	mov    $0x0,%ebx
	register char bchar = '9';
   19f39:	c6 45 eb 39          	movb   $0x39,-0x15(%ebp)
	int sign = 1;
   19f3d:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)

	// check for leading '-'
	if( *str == '-' ) {
   19f44:	0f b6 10             	movzbl (%eax),%edx
   19f47:	80 fa 2d             	cmp    $0x2d,%dl
   19f4a:	75 0a                	jne    19f56 <ustr2int+0x2f>
		sign = -1;
   19f4c:	c7 45 f8 ff ff ff ff 	movl   $0xffffffff,-0x8(%ebp)
		++str;
   19f53:	83 c0 01             	add    $0x1,%eax
	}

	if( base != 10 ) {
   19f56:	83 f9 0a             	cmp    $0xa,%ecx
   19f59:	74 2b                	je     19f86 <ustr2int+0x5f>
		bchar = '0' + base - 1;
   19f5b:	89 ca                	mov    %ecx,%edx
   19f5d:	83 c2 2f             	add    $0x2f,%edx
   19f60:	88 55 eb             	mov    %dl,-0x15(%ebp)
	}

	// iterate through the characters
	while( *str ) {
   19f63:	eb 21                	jmp    19f86 <ustr2int+0x5f>
		if( *str < '0' || *str > bchar )
   19f65:	0f b6 10             	movzbl (%eax),%edx
   19f68:	80 fa 2f             	cmp    $0x2f,%dl
   19f6b:	7e 20                	jle    19f8d <ustr2int+0x66>
   19f6d:	0f b6 10             	movzbl (%eax),%edx
   19f70:	38 55 eb             	cmp    %dl,-0x15(%ebp)
   19f73:	7c 18                	jl     19f8d <ustr2int+0x66>
			break;
		num = num * base + *str - '0';
   19f75:	0f af d9             	imul   %ecx,%ebx
   19f78:	0f b6 10             	movzbl (%eax),%edx
   19f7b:	0f be d2             	movsbl %dl,%edx
   19f7e:	01 da                	add    %ebx,%edx
   19f80:	8d 5a d0             	lea    -0x30(%edx),%ebx
		++str;
   19f83:	83 c0 01             	add    $0x1,%eax
	while( *str ) {
   19f86:	0f b6 10             	movzbl (%eax),%edx
   19f89:	84 d2                	test   %dl,%dl
   19f8b:	75 d8                	jne    19f65 <ustr2int+0x3e>
	}

	// return the converted value
	return( num * sign );
   19f8d:	89 d8                	mov    %ebx,%eax
   19f8f:	0f af 45 f8          	imul   -0x8(%ebp),%eax
}
   19f93:	83 c4 14             	add    $0x14,%esp
   19f96:	5b                   	pop    %ebx
   19f97:	5d                   	pop    %ebp
   19f98:	c3                   	ret    

00019f99 <ustrcat>:
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the resulting string
*/
char *ustrcat( register char *dst, register const char *src ) {
   19f99:	55                   	push   %ebp
   19f9a:	89 e5                	mov    %esp,%ebp
   19f9c:	56                   	push   %esi
   19f9d:	53                   	push   %ebx
   19f9e:	8b 45 08             	mov    0x8(%ebp),%eax
   19fa1:	8b 75 0c             	mov    0xc(%ebp),%esi
	register char *tmp = dst;
   19fa4:	89 c3                	mov    %eax,%ebx

	while( *dst )  // find the NUL
   19fa6:	eb 03                	jmp    19fab <ustrcat+0x12>
		++dst;
   19fa8:	83 c0 01             	add    $0x1,%eax
	while( *dst )  // find the NUL
   19fab:	0f b6 10             	movzbl (%eax),%edx
   19fae:	84 d2                	test   %dl,%dl
   19fb0:	75 f6                	jne    19fa8 <ustrcat+0xf>

	while( (*dst++ = *src++) )  // append the src string
   19fb2:	90                   	nop
   19fb3:	89 f1                	mov    %esi,%ecx
   19fb5:	8d 71 01             	lea    0x1(%ecx),%esi
   19fb8:	89 c2                	mov    %eax,%edx
   19fba:	8d 42 01             	lea    0x1(%edx),%eax
   19fbd:	0f b6 09             	movzbl (%ecx),%ecx
   19fc0:	88 0a                	mov    %cl,(%edx)
   19fc2:	0f b6 12             	movzbl (%edx),%edx
   19fc5:	84 d2                	test   %dl,%dl
   19fc7:	75 ea                	jne    19fb3 <ustrcat+0x1a>
		;

	return( tmp );
   19fc9:	89 d8                	mov    %ebx,%eax
}
   19fcb:	5b                   	pop    %ebx
   19fcc:	5e                   	pop    %esi
   19fcd:	5d                   	pop    %ebp
   19fce:	c3                   	ret    

00019fcf <ustrcmp>:
** @param s1 The first source string
** @param s2 The second source string
**
** @return negative if s1 < s2, zero if equal, and positive if s1 > s2
*/
int ustrcmp( register const char *s1, register const char *s2 ) {
   19fcf:	55                   	push   %ebp
   19fd0:	89 e5                	mov    %esp,%ebp
   19fd2:	53                   	push   %ebx
   19fd3:	8b 45 08             	mov    0x8(%ebp),%eax
   19fd6:	8b 55 0c             	mov    0xc(%ebp),%edx

	while( *s1 != 0 && (*s1 == *s2) )
   19fd9:	eb 06                	jmp    19fe1 <ustrcmp+0x12>
		++s1, ++s2;
   19fdb:	83 c0 01             	add    $0x1,%eax
   19fde:	83 c2 01             	add    $0x1,%edx
	while( *s1 != 0 && (*s1 == *s2) )
   19fe1:	0f b6 08             	movzbl (%eax),%ecx
   19fe4:	84 c9                	test   %cl,%cl
   19fe6:	74 0a                	je     19ff2 <ustrcmp+0x23>
   19fe8:	0f b6 18             	movzbl (%eax),%ebx
   19feb:	0f b6 0a             	movzbl (%edx),%ecx
   19fee:	38 cb                	cmp    %cl,%bl
   19ff0:	74 e9                	je     19fdb <ustrcmp+0xc>

	return( *s1 - *s2 );
   19ff2:	0f b6 00             	movzbl (%eax),%eax
   19ff5:	0f be c8             	movsbl %al,%ecx
   19ff8:	0f b6 02             	movzbl (%edx),%eax
   19ffb:	0f be c0             	movsbl %al,%eax
   19ffe:	29 c1                	sub    %eax,%ecx
   1a000:	89 c8                	mov    %ecx,%eax
}
   1a002:	5b                   	pop    %ebx
   1a003:	5d                   	pop    %ebp
   1a004:	c3                   	ret    

0001a005 <ustrcpy>:
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the copied string
*/
char *ustrcpy( register char *dst, register const char *src ) {
   1a005:	55                   	push   %ebp
   1a006:	89 e5                	mov    %esp,%ebp
   1a008:	56                   	push   %esi
   1a009:	53                   	push   %ebx
   1a00a:	8b 4d 08             	mov    0x8(%ebp),%ecx
   1a00d:	8b 75 0c             	mov    0xc(%ebp),%esi
	register char *tmp = dst;
   1a010:	89 cb                	mov    %ecx,%ebx

	while( (*dst++ = *src++) )
   1a012:	90                   	nop
   1a013:	89 f2                	mov    %esi,%edx
   1a015:	8d 72 01             	lea    0x1(%edx),%esi
   1a018:	89 c8                	mov    %ecx,%eax
   1a01a:	8d 48 01             	lea    0x1(%eax),%ecx
   1a01d:	0f b6 12             	movzbl (%edx),%edx
   1a020:	88 10                	mov    %dl,(%eax)
   1a022:	0f b6 00             	movzbl (%eax),%eax
   1a025:	84 c0                	test   %al,%al
   1a027:	75 ea                	jne    1a013 <ustrcpy+0xe>
		;

	return( tmp );
   1a029:	89 d8                	mov    %ebx,%eax
}
   1a02b:	5b                   	pop    %ebx
   1a02c:	5e                   	pop    %esi
   1a02d:	5d                   	pop    %ebp
   1a02e:	c3                   	ret    

0001a02f <ustrlen>:
**
** @param str The string to examine
**
** @return The length of the string, or 0
*/
uint32_t ustrlen( register const char *str ) {
   1a02f:	55                   	push   %ebp
   1a030:	89 e5                	mov    %esp,%ebp
   1a032:	53                   	push   %ebx
   1a033:	8b 55 08             	mov    0x8(%ebp),%edx
	register uint32_t len = 0;
   1a036:	bb 00 00 00 00       	mov    $0x0,%ebx

	while( *str++ ) {
   1a03b:	eb 03                	jmp    1a040 <ustrlen+0x11>
		++len;
   1a03d:	83 c3 01             	add    $0x1,%ebx
	while( *str++ ) {
   1a040:	89 d0                	mov    %edx,%eax
   1a042:	8d 50 01             	lea    0x1(%eax),%edx
   1a045:	0f b6 00             	movzbl (%eax),%eax
   1a048:	84 c0                	test   %al,%al
   1a04a:	75 f1                	jne    1a03d <ustrlen+0xe>
	}

	return( len );
   1a04c:	89 d8                	mov    %ebx,%eax
}
   1a04e:	5b                   	pop    %ebx
   1a04f:	5d                   	pop    %ebp
   1a050:	c3                   	ret    

0001a051 <ubound>:
** @param value  Value to be constrained
** @param max    Upper bound
**
** @return The constrained value
*/
uint32_t ubound( uint32_t min, uint32_t value, uint32_t max ) {
   1a051:	55                   	push   %ebp
   1a052:	89 e5                	mov    %esp,%ebp
	if( value < min ){
   1a054:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a057:	3b 45 08             	cmp    0x8(%ebp),%eax
   1a05a:	73 06                	jae    1a062 <ubound+0x11>
		value = min;
   1a05c:	8b 45 08             	mov    0x8(%ebp),%eax
   1a05f:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	if( value > max ){
   1a062:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a065:	3b 45 10             	cmp    0x10(%ebp),%eax
   1a068:	76 06                	jbe    1a070 <ubound+0x1f>
		value = max;
   1a06a:	8b 45 10             	mov    0x10(%ebp),%eax
   1a06d:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	return value;
   1a070:	8b 45 0c             	mov    0xc(%ebp),%eax
}
   1a073:	5d                   	pop    %ebp
   1a074:	c3                   	ret    

0001a075 <ucvtdec>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int ucvtdec( char *buf, int32_t value ) {
   1a075:	55                   	push   %ebp
   1a076:	89 e5                	mov    %esp,%ebp
   1a078:	83 ec 18             	sub    $0x18,%esp
	char *bp = buf;
   1a07b:	8b 45 08             	mov    0x8(%ebp),%eax
   1a07e:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if( value < 0 ) {
   1a081:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   1a085:	79 0f                	jns    1a096 <ucvtdec+0x21>
		*bp++ = '-';
   1a087:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a08a:	8d 50 01             	lea    0x1(%eax),%edx
   1a08d:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1a090:	c6 00 2d             	movb   $0x2d,(%eax)
		value = -value;
   1a093:	f7 5d 0c             	negl   0xc(%ebp)
	}

	bp = ucvtdec0( bp, value );
   1a096:	83 ec 08             	sub    $0x8,%esp
   1a099:	ff 75 0c             	pushl  0xc(%ebp)
   1a09c:	ff 75 f4             	pushl  -0xc(%ebp)
   1a09f:	e8 18 00 00 00       	call   1a0bc <ucvtdec0>
   1a0a4:	83 c4 10             	add    $0x10,%esp
   1a0a7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp  = '\0';
   1a0aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a0ad:	c6 00 00             	movb   $0x0,(%eax)

	return( bp - buf );
   1a0b0:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1a0b3:	8b 45 08             	mov    0x8(%ebp),%eax
   1a0b6:	29 c2                	sub    %eax,%edx
   1a0b8:	89 d0                	mov    %edx,%eax
}
   1a0ba:	c9                   	leave  
   1a0bb:	c3                   	ret    

0001a0bc <ucvtdec0>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *ucvtdec0( char *buf, int value ) {
   1a0bc:	55                   	push   %ebp
   1a0bd:	89 e5                	mov    %esp,%ebp
   1a0bf:	83 ec 18             	sub    $0x18,%esp
	int quotient;

	quotient = value / 10;
   1a0c2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   1a0c5:	ba 67 66 66 66       	mov    $0x66666667,%edx
   1a0ca:	89 c8                	mov    %ecx,%eax
   1a0cc:	f7 ea                	imul   %edx
   1a0ce:	c1 fa 02             	sar    $0x2,%edx
   1a0d1:	89 c8                	mov    %ecx,%eax
   1a0d3:	c1 f8 1f             	sar    $0x1f,%eax
   1a0d6:	29 c2                	sub    %eax,%edx
   1a0d8:	89 d0                	mov    %edx,%eax
   1a0da:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient < 0 ) {
   1a0dd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a0e1:	79 0e                	jns    1a0f1 <ucvtdec0+0x35>
		quotient = 214748364;
   1a0e3:	c7 45 f4 cc cc cc 0c 	movl   $0xccccccc,-0xc(%ebp)
		value = 8;
   1a0ea:	c7 45 0c 08 00 00 00 	movl   $0x8,0xc(%ebp)
	}
	if( quotient != 0 ) {
   1a0f1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a0f5:	74 14                	je     1a10b <ucvtdec0+0x4f>
		buf = ucvtdec0( buf, quotient );
   1a0f7:	83 ec 08             	sub    $0x8,%esp
   1a0fa:	ff 75 f4             	pushl  -0xc(%ebp)
   1a0fd:	ff 75 08             	pushl  0x8(%ebp)
   1a100:	e8 b7 ff ff ff       	call   1a0bc <ucvtdec0>
   1a105:	83 c4 10             	add    $0x10,%esp
   1a108:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   1a10b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   1a10e:	ba 67 66 66 66       	mov    $0x66666667,%edx
   1a113:	89 c8                	mov    %ecx,%eax
   1a115:	f7 ea                	imul   %edx
   1a117:	c1 fa 02             	sar    $0x2,%edx
   1a11a:	89 c8                	mov    %ecx,%eax
   1a11c:	c1 f8 1f             	sar    $0x1f,%eax
   1a11f:	29 c2                	sub    %eax,%edx
   1a121:	89 d0                	mov    %edx,%eax
   1a123:	c1 e0 02             	shl    $0x2,%eax
   1a126:	01 d0                	add    %edx,%eax
   1a128:	01 c0                	add    %eax,%eax
   1a12a:	29 c1                	sub    %eax,%ecx
   1a12c:	89 ca                	mov    %ecx,%edx
   1a12e:	89 d0                	mov    %edx,%eax
   1a130:	8d 48 30             	lea    0x30(%eax),%ecx
   1a133:	8b 45 08             	mov    0x8(%ebp),%eax
   1a136:	8d 50 01             	lea    0x1(%eax),%edx
   1a139:	89 55 08             	mov    %edx,0x8(%ebp)
   1a13c:	89 ca                	mov    %ecx,%edx
   1a13e:	88 10                	mov    %dl,(%eax)
	return buf;
   1a140:	8b 45 08             	mov    0x8(%ebp),%eax
}
   1a143:	c9                   	leave  
   1a144:	c3                   	ret    

0001a145 <ucvthex>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int ucvthex( char *buf, uint32_t value ) {
   1a145:	55                   	push   %ebp
   1a146:	89 e5                	mov    %esp,%ebp
   1a148:	83 ec 20             	sub    $0x20,%esp
	const char hexdigits[] = "0123456789ABCDEF";
   1a14b:	c7 45 e3 30 31 32 33 	movl   $0x33323130,-0x1d(%ebp)
   1a152:	c7 45 e7 34 35 36 37 	movl   $0x37363534,-0x19(%ebp)
   1a159:	c7 45 eb 38 39 41 42 	movl   $0x42413938,-0x15(%ebp)
   1a160:	c7 45 ef 43 44 45 46 	movl   $0x46454443,-0x11(%ebp)
   1a167:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)
	int chars_stored = 0;
   1a16b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)

	for( int i = 0; i < 8; i += 1 ) {
   1a172:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
   1a179:	eb 43                	jmp    1a1be <ucvthex+0x79>
		uint32_t val = value & 0xf0000000;
   1a17b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a17e:	25 00 00 00 f0       	and    $0xf0000000,%eax
   1a183:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if( chars_stored || val != 0 || i == 7 ) {
   1a186:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
   1a18a:	75 0c                	jne    1a198 <ucvthex+0x53>
   1a18c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a190:	75 06                	jne    1a198 <ucvthex+0x53>
   1a192:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   1a196:	75 1e                	jne    1a1b6 <ucvthex+0x71>
			++chars_stored;
   1a198:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
			val = (val >> 28) & 0xf;
   1a19c:	c1 6d f4 1c          	shrl   $0x1c,-0xc(%ebp)
			*buf++ = hexdigits[val];
   1a1a0:	8b 45 08             	mov    0x8(%ebp),%eax
   1a1a3:	8d 50 01             	lea    0x1(%eax),%edx
   1a1a6:	89 55 08             	mov    %edx,0x8(%ebp)
   1a1a9:	8d 4d e3             	lea    -0x1d(%ebp),%ecx
   1a1ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1a1af:	01 ca                	add    %ecx,%edx
   1a1b1:	0f b6 12             	movzbl (%edx),%edx
   1a1b4:	88 10                	mov    %dl,(%eax)
		}
		value <<= 4;
   1a1b6:	c1 65 0c 04          	shll   $0x4,0xc(%ebp)
	for( int i = 0; i < 8; i += 1 ) {
   1a1ba:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
   1a1be:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   1a1c2:	7e b7                	jle    1a17b <ucvthex+0x36>
	}

	*buf = '\0';
   1a1c4:	8b 45 08             	mov    0x8(%ebp),%eax
   1a1c7:	c6 00 00             	movb   $0x0,(%eax)

	return( chars_stored );
   1a1ca:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   1a1cd:	c9                   	leave  
   1a1ce:	c3                   	ret    

0001a1cf <ucvtoct>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int ucvtoct( char *buf, uint32_t value ) {
   1a1cf:	55                   	push   %ebp
   1a1d0:	89 e5                	mov    %esp,%ebp
   1a1d2:	83 ec 10             	sub    $0x10,%esp
	int i;
	int chars_stored = 0;
   1a1d5:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	char *bp = buf;
   1a1dc:	8b 45 08             	mov    0x8(%ebp),%eax
   1a1df:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32_t val;

	val = ( value & 0xc0000000 );
   1a1e2:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a1e5:	25 00 00 00 c0       	and    $0xc0000000,%eax
   1a1ea:	89 45 f0             	mov    %eax,-0x10(%ebp)
	val >>= 30;
   1a1ed:	c1 6d f0 1e          	shrl   $0x1e,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   1a1f1:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   1a1f8:	eb 47                	jmp    1a241 <ucvtoct+0x72>

		if( i == 10 || val != 0 || chars_stored ) {
   1a1fa:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   1a1fe:	74 0c                	je     1a20c <ucvtoct+0x3d>
   1a200:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   1a204:	75 06                	jne    1a20c <ucvtoct+0x3d>
   1a206:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
   1a20a:	74 1e                	je     1a22a <ucvtoct+0x5b>
			chars_stored = 1;
   1a20c:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)
			val &= 0x7;
   1a213:	83 65 f0 07          	andl   $0x7,-0x10(%ebp)
			*bp++ = val + '0';
   1a217:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1a21a:	8d 48 30             	lea    0x30(%eax),%ecx
   1a21d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a220:	8d 50 01             	lea    0x1(%eax),%edx
   1a223:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1a226:	89 ca                	mov    %ecx,%edx
   1a228:	88 10                	mov    %dl,(%eax)
		}
		value <<= 3;
   1a22a:	c1 65 0c 03          	shll   $0x3,0xc(%ebp)
		val = ( value & 0xe0000000 );
   1a22e:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a231:	25 00 00 00 e0       	and    $0xe0000000,%eax
   1a236:	89 45 f0             	mov    %eax,-0x10(%ebp)
		val >>= 29;
   1a239:	c1 6d f0 1d          	shrl   $0x1d,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   1a23d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   1a241:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   1a245:	7e b3                	jle    1a1fa <ucvtoct+0x2b>
	}
	*bp = '\0';
   1a247:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a24a:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   1a24d:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1a250:	8b 45 08             	mov    0x8(%ebp),%eax
   1a253:	29 c2                	sub    %eax,%edx
   1a255:	89 d0                	mov    %edx,%eax
}
   1a257:	c9                   	leave  
   1a258:	c3                   	ret    

0001a259 <ucvtuns>:
**
** @return Length of the resulting buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int ucvtuns( char *buf, uint32_t value ) {
   1a259:	55                   	push   %ebp
   1a25a:	89 e5                	mov    %esp,%ebp
   1a25c:	83 ec 18             	sub    $0x18,%esp
	char    *bp = buf;
   1a25f:	8b 45 08             	mov    0x8(%ebp),%eax
   1a262:	89 45 f4             	mov    %eax,-0xc(%ebp)

	bp = ucvtuns0( bp, value );
   1a265:	83 ec 08             	sub    $0x8,%esp
   1a268:	ff 75 0c             	pushl  0xc(%ebp)
   1a26b:	ff 75 f4             	pushl  -0xc(%ebp)
   1a26e:	e8 18 00 00 00       	call   1a28b <ucvtuns0>
   1a273:	83 c4 10             	add    $0x10,%esp
   1a276:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp = '\0';
   1a279:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a27c:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   1a27f:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1a282:	8b 45 08             	mov    0x8(%ebp),%eax
   1a285:	29 c2                	sub    %eax,%edx
   1a287:	89 d0                	mov    %edx,%eax
}
   1a289:	c9                   	leave  
   1a28a:	c3                   	ret    

0001a28b <ucvtuns0>:
**
** @return Pointer to the first unused byte in the buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *ucvtuns0( char *buf, uint32_t value ) {
   1a28b:	55                   	push   %ebp
   1a28c:	89 e5                	mov    %esp,%ebp
   1a28e:	83 ec 18             	sub    $0x18,%esp
	uint32_t quotient;

	quotient = value / 10;
   1a291:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a294:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   1a299:	f7 e2                	mul    %edx
   1a29b:	89 d0                	mov    %edx,%eax
   1a29d:	c1 e8 03             	shr    $0x3,%eax
   1a2a0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient != 0 ){
   1a2a3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a2a7:	74 15                	je     1a2be <ucvtuns0+0x33>
		buf = ucvtdec0( buf, quotient );
   1a2a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a2ac:	83 ec 08             	sub    $0x8,%esp
   1a2af:	50                   	push   %eax
   1a2b0:	ff 75 08             	pushl  0x8(%ebp)
   1a2b3:	e8 04 fe ff ff       	call   1a0bc <ucvtdec0>
   1a2b8:	83 c4 10             	add    $0x10,%esp
   1a2bb:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   1a2be:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   1a2c1:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   1a2c6:	89 c8                	mov    %ecx,%eax
   1a2c8:	f7 e2                	mul    %edx
   1a2ca:	c1 ea 03             	shr    $0x3,%edx
   1a2cd:	89 d0                	mov    %edx,%eax
   1a2cf:	c1 e0 02             	shl    $0x2,%eax
   1a2d2:	01 d0                	add    %edx,%eax
   1a2d4:	01 c0                	add    %eax,%eax
   1a2d6:	29 c1                	sub    %eax,%ecx
   1a2d8:	89 ca                	mov    %ecx,%edx
   1a2da:	89 d0                	mov    %edx,%eax
   1a2dc:	8d 48 30             	lea    0x30(%eax),%ecx
   1a2df:	8b 45 08             	mov    0x8(%ebp),%eax
   1a2e2:	8d 50 01             	lea    0x1(%eax),%edx
   1a2e5:	89 55 08             	mov    %edx,0x8(%ebp)
   1a2e8:	89 ca                	mov    %ecx,%edx
   1a2ea:	88 10                	mov    %dl,(%eax)
	return buf;
   1a2ec:	8b 45 08             	mov    0x8(%ebp),%eax
}
   1a2ef:	c9                   	leave  
   1a2f0:	c3                   	ret    

0001a2f1 <wait>:
** @param status Pointer to int32_t into which the child's status is placed,
**               or NULL
**
** @returns The PID of the terminated child, or an error code
*/
int wait( int32_t *status ) {
   1a2f1:	55                   	push   %ebp
   1a2f2:	89 e5                	mov    %esp,%ebp
   1a2f4:	83 ec 08             	sub    $0x8,%esp
	return( waitpid(0,status) );
   1a2f7:	83 ec 08             	sub    $0x8,%esp
   1a2fa:	ff 75 08             	pushl  0x8(%ebp)
   1a2fd:	6a 00                	push   $0x0
   1a2ff:	e8 0c cc ff ff       	call   16f10 <waitpid>
   1a304:	83 c4 10             	add    $0x10,%esp
}
   1a307:	c9                   	leave  
   1a308:	c3                   	ret    

0001a309 <spawn>:
** @param entry The entry point of the 'main' function for the process
** @param args  The command-line argument vector for the new process
**
** @returns PID of the new process, or an error code
*/
int32_t spawn( uint32_t entry, char **args ) {
   1a309:	55                   	push   %ebp
   1a30a:	89 e5                	mov    %esp,%ebp
   1a30c:	81 ec 18 01 00 00    	sub    $0x118,%esp
	int32_t pid;
	char buf[256];

	pid = fork();
   1a312:	e8 01 cc ff ff       	call   16f18 <fork>
   1a317:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( pid != 0 ) {
   1a31a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a31e:	74 05                	je     1a325 <spawn+0x1c>
		// failure, or we are the parent
		return( pid );
   1a320:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a323:	eb 57                	jmp    1a37c <spawn+0x73>
	}

	// we are the child
	pid = getpid();
   1a325:	e8 0e cc ff ff       	call   16f38 <getpid>
   1a32a:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// child inherits parent's priority level

	exec( entry, args );
   1a32d:	83 ec 08             	sub    $0x8,%esp
   1a330:	ff 75 0c             	pushl  0xc(%ebp)
   1a333:	ff 75 08             	pushl  0x8(%ebp)
   1a336:	e8 e5 cb ff ff       	call   16f20 <exec>
   1a33b:	83 c4 10             	add    $0x10,%esp

	// uh-oh....

	usprint( buf, "Child %d exec() %08x failed\n", pid, entry );
   1a33e:	ff 75 08             	pushl  0x8(%ebp)
   1a341:	ff 75 f4             	pushl  -0xc(%ebp)
   1a344:	68 c0 c0 01 00       	push   $0x1c0c0
   1a349:	8d 85 f4 fe ff ff    	lea    -0x10c(%ebp),%eax
   1a34f:	50                   	push   %eax
   1a350:	e8 5d f9 ff ff       	call   19cb2 <usprint>
   1a355:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   1a358:	83 ec 0c             	sub    $0xc,%esp
   1a35b:	8d 85 f4 fe ff ff    	lea    -0x10c(%ebp),%eax
   1a361:	50                   	push   %eax
   1a362:	e8 38 00 00 00       	call   1a39f <cwrites>
   1a367:	83 c4 10             	add    $0x10,%esp

	exit( EXIT_FAILURE );
   1a36a:	83 ec 0c             	sub    $0xc,%esp
   1a36d:	6a ff                	push   $0xffffffff
   1a36f:	e8 94 cb ff ff       	call   16f08 <exit>
   1a374:	83 c4 10             	add    $0x10,%esp
	return( 0 );   // shut the compiler up
   1a377:	b8 00 00 00 00       	mov    $0x0,%eax
}
   1a37c:	c9                   	leave  
   1a37d:	c3                   	ret    

0001a37e <cwritech>:
**
** @param ch The character to write
**
** @returns The return value from calling write()
*/
int cwritech( char ch ) {
   1a37e:	55                   	push   %ebp
   1a37f:	89 e5                	mov    %esp,%ebp
   1a381:	83 ec 18             	sub    $0x18,%esp
   1a384:	8b 45 08             	mov    0x8(%ebp),%eax
   1a387:	88 45 f4             	mov    %al,-0xc(%ebp)
	return( write(CHAN_CIO,&ch,1) );
   1a38a:	83 ec 04             	sub    $0x4,%esp
   1a38d:	6a 01                	push   $0x1
   1a38f:	8d 45 f4             	lea    -0xc(%ebp),%eax
   1a392:	50                   	push   %eax
   1a393:	6a 00                	push   $0x0
   1a395:	e8 96 cb ff ff       	call   16f30 <write>
   1a39a:	83 c4 10             	add    $0x10,%esp
}
   1a39d:	c9                   	leave  
   1a39e:	c3                   	ret    

0001a39f <cwrites>:
** cwrites(str) - write a NUL-terminated string to the console
**
** @param str The string to write
**
*/
int cwrites( const char *str ) {
   1a39f:	55                   	push   %ebp
   1a3a0:	89 e5                	mov    %esp,%ebp
   1a3a2:	83 ec 18             	sub    $0x18,%esp
	int len = ustrlen(str);
   1a3a5:	ff 75 08             	pushl  0x8(%ebp)
   1a3a8:	e8 82 fc ff ff       	call   1a02f <ustrlen>
   1a3ad:	83 c4 04             	add    $0x4,%esp
   1a3b0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return( write(CHAN_CIO,str,len) );
   1a3b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a3b6:	83 ec 04             	sub    $0x4,%esp
   1a3b9:	50                   	push   %eax
   1a3ba:	ff 75 08             	pushl  0x8(%ebp)
   1a3bd:	6a 00                	push   $0x0
   1a3bf:	e8 6c cb ff ff       	call   16f30 <write>
   1a3c4:	83 c4 10             	add    $0x10,%esp
}
   1a3c7:	c9                   	leave  
   1a3c8:	c3                   	ret    

0001a3c9 <cwrite>:
** @param buf  The buffer to write
** @param size The number of bytes to write
**
** @returns The return value from calling write()
*/
int cwrite( const char *buf, uint32_t size ) {
   1a3c9:	55                   	push   %ebp
   1a3ca:	89 e5                	mov    %esp,%ebp
   1a3cc:	83 ec 08             	sub    $0x8,%esp
	return( write(CHAN_CIO,buf,size) );
   1a3cf:	83 ec 04             	sub    $0x4,%esp
   1a3d2:	ff 75 0c             	pushl  0xc(%ebp)
   1a3d5:	ff 75 08             	pushl  0x8(%ebp)
   1a3d8:	6a 00                	push   $0x0
   1a3da:	e8 51 cb ff ff       	call   16f30 <write>
   1a3df:	83 c4 10             	add    $0x10,%esp
}
   1a3e2:	c9                   	leave  
   1a3e3:	c3                   	ret    

0001a3e4 <swritech>:
**
** @param ch The character to write
**
** @returns The return value from calling write()
*/
int swritech( char ch ) {
   1a3e4:	55                   	push   %ebp
   1a3e5:	89 e5                	mov    %esp,%ebp
   1a3e7:	83 ec 18             	sub    $0x18,%esp
   1a3ea:	8b 45 08             	mov    0x8(%ebp),%eax
   1a3ed:	88 45 f4             	mov    %al,-0xc(%ebp)
	return( write(CHAN_SIO,&ch,1) );
   1a3f0:	83 ec 04             	sub    $0x4,%esp
   1a3f3:	6a 01                	push   $0x1
   1a3f5:	8d 45 f4             	lea    -0xc(%ebp),%eax
   1a3f8:	50                   	push   %eax
   1a3f9:	6a 01                	push   $0x1
   1a3fb:	e8 30 cb ff ff       	call   16f30 <write>
   1a400:	83 c4 10             	add    $0x10,%esp
}
   1a403:	c9                   	leave  
   1a404:	c3                   	ret    

0001a405 <swrites>:
**
** @param str The string to write
**
** @returns The return value from calling write()
*/
int swrites( const char *str ) {
   1a405:	55                   	push   %ebp
   1a406:	89 e5                	mov    %esp,%ebp
   1a408:	83 ec 18             	sub    $0x18,%esp
	int len = ustrlen(str);
   1a40b:	ff 75 08             	pushl  0x8(%ebp)
   1a40e:	e8 1c fc ff ff       	call   1a02f <ustrlen>
   1a413:	83 c4 04             	add    $0x4,%esp
   1a416:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return( write(CHAN_SIO,str,len) );
   1a419:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a41c:	83 ec 04             	sub    $0x4,%esp
   1a41f:	50                   	push   %eax
   1a420:	ff 75 08             	pushl  0x8(%ebp)
   1a423:	6a 01                	push   $0x1
   1a425:	e8 06 cb ff ff       	call   16f30 <write>
   1a42a:	83 c4 10             	add    $0x10,%esp
}
   1a42d:	c9                   	leave  
   1a42e:	c3                   	ret    

0001a42f <swrite>:
** @param buf  The buffer to write
** @param size The number of bytes to write
**
** @returns The return value from calling write()
*/
int swrite( const char *buf, uint32_t size ) {
   1a42f:	55                   	push   %ebp
   1a430:	89 e5                	mov    %esp,%ebp
   1a432:	83 ec 08             	sub    $0x8,%esp
	return( write(CHAN_SIO,buf,size) );
   1a435:	83 ec 04             	sub    $0x4,%esp
   1a438:	ff 75 0c             	pushl  0xc(%ebp)
   1a43b:	ff 75 08             	pushl  0x8(%ebp)
   1a43e:	6a 01                	push   $0x1
   1a440:	e8 eb ca ff ff       	call   16f30 <write>
   1a445:	83 c4 10             	add    $0x10,%esp
}
   1a448:	c9                   	leave  
   1a449:	c3                   	ret    
