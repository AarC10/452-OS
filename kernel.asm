
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
   1007d:	68 80 a4 01 00       	push   $0x1a480
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
   10c0c:	e8 df 14 00 00       	call   120f0 <bound>
   10c11:	83 c4 10             	add    $0x10,%esp
   10c14:	a3 00 e0 01 00       	mov    %eax,0x1e000
	scroll_min_y = bound( min_y, s_min_y, max_y );
   10c19:	8b 15 24 e0 01 00    	mov    0x1e024,%edx
   10c1f:	a1 1c e0 01 00       	mov    0x1e01c,%eax
   10c24:	83 ec 04             	sub    $0x4,%esp
   10c27:	52                   	push   %edx
   10c28:	ff 75 0c             	pushl  0xc(%ebp)
   10c2b:	50                   	push   %eax
   10c2c:	e8 bf 14 00 00       	call   120f0 <bound>
   10c31:	83 c4 10             	add    $0x10,%esp
   10c34:	a3 04 e0 01 00       	mov    %eax,0x1e004
	scroll_max_x = bound( scroll_min_x, s_max_x, max_x );
   10c39:	8b 15 20 e0 01 00    	mov    0x1e020,%edx
   10c3f:	a1 00 e0 01 00       	mov    0x1e000,%eax
   10c44:	83 ec 04             	sub    $0x4,%esp
   10c47:	52                   	push   %edx
   10c48:	ff 75 10             	pushl  0x10(%ebp)
   10c4b:	50                   	push   %eax
   10c4c:	e8 9f 14 00 00       	call   120f0 <bound>
   10c51:	83 c4 10             	add    $0x10,%esp
   10c54:	a3 08 e0 01 00       	mov    %eax,0x1e008
	scroll_max_y = bound( scroll_min_y, s_max_y, max_y );
   10c59:	8b 15 24 e0 01 00    	mov    0x1e024,%edx
   10c5f:	a1 04 e0 01 00       	mov    0x1e004,%eax
   10c64:	83 ec 04             	sub    $0x4,%esp
   10c67:	52                   	push   %edx
   10c68:	ff 75 14             	pushl  0x14(%ebp)
   10c6b:	50                   	push   %eax
   10c6c:	e8 7f 14 00 00       	call   120f0 <bound>
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
   10cb7:	e8 34 14 00 00       	call   120f0 <bound>
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
   10ce0:	e8 0b 14 00 00       	call   120f0 <bound>
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
   1119b:	e8 e4 18 00 00       	call   12a84 <strlen>
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
   112fa:	8b 04 85 38 a9 01 00 	mov    0x1a938(,%eax,4),%eax
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
   11357:	e8 b8 0d 00 00       	call   12114 <cvtdec>
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
   113d3:	e8 0c 0e 00 00       	call   121e4 <cvthex>
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
   1141a:	e8 4f 0e 00 00       	call   1226e <cvtoct>
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
   11461:	e8 92 0e 00 00       	call   122f8 <cvtuns>
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
   11857:	e8 2a 3f 00 00       	call   15786 <install_isr>
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
   118a1:	0f b6 80 0b aa 01 00 	movzbl 0x1aa0b(%eax),%eax
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
   118e6:	e8 a6 25 00 00       	call   13e91 <pcb_queue_length>
   118eb:	83 c4 10             	add    $0x10,%esp
   118ee:	89 45 d4             	mov    %eax,-0x2c(%ebp)
   118f1:	a1 18 20 02 00       	mov    0x22018,%eax
   118f6:	83 ec 0c             	sub    $0xc,%esp
   118f9:	50                   	push   %eax
   118fa:	e8 92 25 00 00       	call   13e91 <pcb_queue_length>
   118ff:	83 c4 10             	add    $0x10,%esp
   11902:	89 c7                	mov    %eax,%edi
   11904:	a1 08 20 02 00       	mov    0x22008,%eax
   11909:	83 ec 0c             	sub    $0xc,%esp
   1190c:	50                   	push   %eax
   1190d:	e8 7f 25 00 00       	call   13e91 <pcb_queue_length>
   11912:	83 c4 10             	add    $0x10,%esp
   11915:	89 c6                	mov    %eax,%esi
   11917:	a1 10 20 02 00       	mov    0x22010,%eax
   1191c:	83 ec 0c             	sub    $0xc,%esp
   1191f:	50                   	push   %eax
   11920:	e8 6c 25 00 00       	call   13e91 <pcb_queue_length>
   11925:	83 c4 10             	add    $0x10,%esp
   11928:	89 c3                	mov    %eax,%ebx
   1192a:	a1 d0 24 02 00       	mov    0x224d0,%eax
   1192f:	83 ec 0c             	sub    $0xc,%esp
   11932:	50                   	push   %eax
   11933:	e8 59 25 00 00       	call   13e91 <pcb_queue_length>
   11938:	83 c4 10             	add    $0x10,%esp
   1193b:	ff 75 d4             	pushl  -0x2c(%ebp)
   1193e:	57                   	push   %edi
   1193f:	56                   	push   %esi
   11940:	53                   	push   %ebx
   11941:	50                   	push   %eax
   11942:	68 90 a9 01 00       	push   $0x1a990
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
   11969:	e8 d0 24 00 00       	call   13e3e <pcb_queue_empty>
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
   11982:	e8 ea 29 00 00       	call   14371 <pcb_queue_peek>
   11987:	83 c4 10             	add    $0x10,%esp
   1198a:	89 45 dc             	mov    %eax,-0x24(%ebp)
		assert( tmp != NULL );
   1198d:	8b 45 dc             	mov    -0x24(%ebp),%eax
   11990:	85 c0                	test   %eax,%eax
   11992:	75 38                	jne    119cc <clk_isr+0x16a>
   11994:	83 ec 04             	sub    $0x4,%esp
   11997:	68 ba a9 01 00       	push   $0x1a9ba
   1199c:	6a 00                	push   $0x0
   1199e:	6a 64                	push   $0x64
   119a0:	68 c3 a9 01 00       	push   $0x1a9c3
   119a5:	68 18 aa 01 00       	push   $0x1aa18
   119aa:	68 cb a9 01 00       	push   $0x1a9cb
   119af:	68 00 00 02 00       	push   $0x20000
   119b4:	e8 4e 0d 00 00       	call   12707 <sprint>
   119b9:	83 c4 20             	add    $0x20,%esp
   119bc:	83 ec 0c             	sub    $0xc,%esp
   119bf:	68 00 00 02 00       	push   $0x20000
   119c4:	e8 be 0a 00 00       	call   12487 <kpanic>
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
   119e8:	e8 ef 26 00 00       	call   140dc <pcb_queue_remove>
   119ed:	83 c4 10             	add    $0x10,%esp
   119f0:	85 c0                	test   %eax,%eax
   119f2:	74 38                	je     11a2c <clk_isr+0x1ca>
   119f4:	83 ec 04             	sub    $0x4,%esp
   119f7:	68 e4 a9 01 00       	push   $0x1a9e4
   119fc:	6a 00                	push   $0x0
   119fe:	6a 70                	push   $0x70
   11a00:	68 c3 a9 01 00       	push   $0x1a9c3
   11a05:	68 18 aa 01 00       	push   $0x1aa18
   11a0a:	68 cb a9 01 00       	push   $0x1a9cb
   11a0f:	68 00 00 02 00       	push   $0x20000
   11a14:	e8 ee 0c 00 00       	call   12707 <sprint>
   11a19:	83 c4 20             	add    $0x20,%esp
   11a1c:	83 ec 0c             	sub    $0xc,%esp
   11a1f:	68 00 00 02 00       	push   $0x20000
   11a24:	e8 5e 0a 00 00       	call   12487 <kpanic>
   11a29:	83 c4 10             	add    $0x10,%esp
		schedule( tmp );
   11a2c:	8b 45 dc             	mov    -0x24(%ebp),%eax
   11a2f:	83 ec 0c             	sub    $0xc,%esp
   11a32:	50                   	push   %eax
   11a33:	e8 97 29 00 00       	call   143cf <schedule>
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
   11a6c:	e8 5e 29 00 00       	call   143cf <schedule>
   11a71:	83 c4 10             	add    $0x10,%esp
		current = NULL;
   11a74:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   11a7b:	00 00 00 
		// and pick a new process
		dispatch();
   11a7e:	e8 0d 2a 00 00       	call   14490 <dispatch>
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
   11aa8:	68 10 aa 01 00       	push   $0x1aa10
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
   11b2a:	e8 57 3c 00 00       	call   15786 <install_isr>
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
   11b44:	68 20 aa 01 00       	push   $0x1aa20
   11b49:	e8 5f f3 ff ff       	call   10ead <cio_puts>
   11b4e:	83 c4 10             	add    $0x10,%esp
	cio_printf( "Config:  N_PROCS = %d", N_PROCS );
   11b51:	83 ec 08             	sub    $0x8,%esp
   11b54:	6a 19                	push   $0x19
   11b56:	68 42 aa 01 00       	push   $0x1aa42
   11b5b:	e8 c7 f9 ff ff       	call   11527 <cio_printf>
   11b60:	83 c4 10             	add    $0x10,%esp
	cio_printf( " N_PRIOS = %d", N_PRIOS );
   11b63:	83 ec 08             	sub    $0x8,%esp
   11b66:	6a 04                	push   $0x4
   11b68:	68 58 aa 01 00       	push   $0x1aa58
   11b6d:	e8 b5 f9 ff ff       	call   11527 <cio_printf>
   11b72:	83 c4 10             	add    $0x10,%esp
	cio_printf( " N_STATES = %d", N_STATES );
   11b75:	83 ec 08             	sub    $0x8,%esp
   11b78:	6a 09                	push   $0x9
   11b7a:	68 66 aa 01 00       	push   $0x1aa66
   11b7f:	e8 a3 f9 ff ff       	call   11527 <cio_printf>
   11b84:	83 c4 10             	add    $0x10,%esp
	cio_printf( " CLOCK = %dHz\n", CLOCK_FREQ );
   11b87:	83 ec 08             	sub    $0x8,%esp
   11b8a:	68 e8 03 00 00       	push   $0x3e8
   11b8f:	68 75 aa 01 00       	push   $0x1aa75
   11b94:	e8 8e f9 ff ff       	call   11527 <cio_printf>
   11b99:	83 c4 10             	add    $0x10,%esp

	// This code is ugly, but it's the simplest way to
	// print out the values of compile-time options
	// without spending a lot of execution time at it.

	cio_puts( "Options: "
   11b9c:	83 ec 0c             	sub    $0xc,%esp
   11b9f:	68 84 aa 01 00       	push   $0x1aa84
   11ba4:	e8 04 f3 ff ff       	call   10ead <cio_puts>
   11ba9:	83 c4 10             	add    $0x10,%esp
		" Cstats"
#endif
		); // end of cio_puts() call

#ifdef SANITY
	cio_printf( " SANITY = %d", SANITY );
   11bac:	83 ec 08             	sub    $0x8,%esp
   11baf:	68 0f 27 00 00       	push   $0x270f
   11bb4:	68 9f aa 01 00       	push   $0x1aa9f
   11bb9:	e8 69 f9 ff ff       	call   11527 <cio_printf>
   11bbe:	83 c4 10             	add    $0x10,%esp
#ifdef STATUS
	cio_printf( " STATUS = %d", STATUS );
#endif

#if TRACE > 0
	cio_printf( " TRACE = 0x%04x\n", TRACE );
   11bc1:	83 ec 08             	sub    $0x8,%esp
   11bc4:	68 00 01 00 00       	push   $0x100
   11bc9:	68 ac aa 01 00       	push   $0x1aaac
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
   11bdf:	68 bd aa 01 00       	push   $0x1aabd
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
   11c5b:	68 cb aa 01 00       	push   $0x1aacb
   11c60:	e8 bb 2c 00 00       	call   14920 <ptable_dump>
   11c65:	83 c4 10             	add    $0x10,%esp
		break;
   11c68:	e9 db 00 00 00       	jmp    11d48 <stats+0x14c>

	case 'c':  // dump context info for all active PCBs
		ctx_dump_all( "\nContext dump" );
   11c6d:	83 ec 0c             	sub    $0xc,%esp
   11c70:	68 dd aa 01 00       	push   $0x1aadd
   11c75:	e8 df 29 00 00       	call   14659 <ctx_dump_all>
   11c7a:	83 c4 10             	add    $0x10,%esp
		break;
   11c7d:	e9 c6 00 00 00       	jmp    11d48 <stats+0x14c>

	case 'p':  // dump the active table and all PCBs
		ptable_dump( "\nActive processes", true );
   11c82:	83 ec 08             	sub    $0x8,%esp
   11c85:	6a 01                	push   $0x1
   11c87:	68 cb aa 01 00       	push   $0x1aacb
   11c8c:	e8 8f 2c 00 00       	call   14920 <ptable_dump>
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
   11ca4:	68 eb aa 01 00       	push   $0x1aaeb
   11ca9:	e8 5f 2b 00 00       	call   1480d <pcb_queue_dump>
   11cae:	83 c4 10             	add    $0x10,%esp
		pcb_queue_dump( "W", waiting, true );
   11cb1:	a1 10 20 02 00       	mov    0x22010,%eax
   11cb6:	83 ec 04             	sub    $0x4,%esp
   11cb9:	6a 01                	push   $0x1
   11cbb:	50                   	push   %eax
   11cbc:	68 ed aa 01 00       	push   $0x1aaed
   11cc1:	e8 47 2b 00 00       	call   1480d <pcb_queue_dump>
   11cc6:	83 c4 10             	add    $0x10,%esp
		pcb_queue_dump( "S", sleeping, true );
   11cc9:	a1 08 20 02 00       	mov    0x22008,%eax
   11cce:	83 ec 04             	sub    $0x4,%esp
   11cd1:	6a 01                	push   $0x1
   11cd3:	50                   	push   %eax
   11cd4:	68 ef aa 01 00       	push   $0x1aaef
   11cd9:	e8 2f 2b 00 00       	call   1480d <pcb_queue_dump>
   11cde:	83 c4 10             	add    $0x10,%esp
		pcb_queue_dump( "Z", zombie, true );
   11ce1:	a1 18 20 02 00       	mov    0x22018,%eax
   11ce6:	83 ec 04             	sub    $0x4,%esp
   11ce9:	6a 01                	push   $0x1
   11ceb:	50                   	push   %eax
   11cec:	68 f1 aa 01 00       	push   $0x1aaf1
   11cf1:	e8 17 2b 00 00       	call   1480d <pcb_queue_dump>
   11cf6:	83 c4 10             	add    $0x10,%esp
		pcb_queue_dump( "I", sioread, true );
   11cf9:	a1 04 20 02 00       	mov    0x22004,%eax
   11cfe:	83 ec 04             	sub    $0x4,%esp
   11d01:	6a 01                	push   $0x1
   11d03:	50                   	push   %eax
   11d04:	68 f3 aa 01 00       	push   $0x1aaf3
   11d09:	e8 ff 2a 00 00       	call   1480d <pcb_queue_dump>
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
   11d28:	68 f8 aa 01 00       	push   $0x1aaf8
   11d2d:	e8 f5 f7 ff ff       	call   11527 <cio_printf>
   11d32:	83 c4 10             	add    $0x10,%esp
		// FALL THROUGH

	case 'h':  // help message
		cio_puts( "\nCommands:\n"
   11d35:	83 ec 0c             	sub    $0xc,%esp
   11d38:	68 1c ab 01 00       	push   $0x1ab1c
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
   11d5d:	e8 11 3a 00 00       	call   15773 <init_interrupts>
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
   11d7a:	68 e8 ab 01 00       	push   $0x1abe8
   11d7f:	e8 29 f1 ff ff       	call   10ead <cio_puts>
   11d84:	83 c4 10             	add    $0x10,%esp
	cio_puts( "-------------------------------\n" );
   11d87:	83 ec 0c             	sub    $0xc,%esp
   11d8a:	68 0c ac 01 00       	push   $0x1ac0c
   11d8f:	e8 19 f1 ff ff       	call   10ead <cio_puts>
   11d94:	83 c4 10             	add    $0x10,%esp

#if TRACING_INIT
	cio_puts( "Modules:" );
   11d97:	83 ec 0c             	sub    $0xc,%esp
   11d9a:	68 2d ac 01 00       	push   $0x1ac2d
   11d9f:	e8 09 f1 ff ff       	call   10ead <cio_puts>
   11da4:	83 c4 10             	add    $0x10,%esp
#endif

	// call the module initialization functions, being
	// careful to follow any module precedence requirements

	km_init();		// MUST BE FIRST
   11da7:	e8 04 0e 00 00       	call   12bb0 <km_init>

	// other module initialization calls here
	clk_init();     // clock
   11dac:	e8 ee fc ff ff       	call   11a9f <clk_init>
	pcb_init();     // process (PCBs, queues, scheduler)
   11db1:	e8 2f 18 00 00       	call   135e5 <pcb_init>
	sio_init();     // serial i/o
   11db6:	e8 3e 30 00 00       	call   14df9 <sio_init>
	sys_init();     // system call
   11dbb:	e8 bf 4c 00 00       	call   16a7f <sys_init>
	user_init();    // user code handling
   11dc0:	e8 9c 4f 00 00       	call   16d61 <user_init>

	cio_puts( "\nModule initialization complete.\n" );
   11dc5:	83 ec 0c             	sub    $0xc,%esp
   11dc8:	68 38 ac 01 00       	push   $0x1ac38
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
   11de5:	68 0c ac 01 00       	push   $0x1ac0c
   11dea:	e8 be f0 ff ff       	call   10ead <cio_puts>
   11def:	83 c4 10             	add    $0x10,%esp
	**
	**	Enabling any I/O devices (e.g., SIO xmit/rcv)
	*/


  intel_8255x_init();
   11df2:	e8 24 51 00 00       	call   16f1b <intel_8255x_init>
  cio_puts("Waiting 5 secondsd before starting user procs");
   11df7:	83 ec 0c             	sub    $0xc,%esp
   11dfa:	68 5c ac 01 00       	push   $0x1ac5c
   11dff:	e8 a9 f0 ff ff       	call   10ead <cio_puts>
   11e04:	83 c4 10             	add    $0x10,%esp
  delay(DELAY_5_SEC);
   11e07:	83 ec 0c             	sub    $0xc,%esp
   11e0a:	68 c8 00 00 00       	push   $0xc8
   11e0f:	e8 97 39 00 00       	call   157ab <delay>
   11e14:	83 c4 10             	add    $0x10,%esp
	** This code is largely stolen from the fork() and exec()
	** implementations in syscalls.c; if those change, this must
	** also change.
	*/

	cio_puts( "Creating initial user process..." );
   11e17:	83 ec 0c             	sub    $0xc,%esp
   11e1a:	68 8c ac 01 00       	push   $0x1ac8c
   11e1f:	e8 89 f0 ff ff       	call   10ead <cio_puts>
   11e24:	83 c4 10             	add    $0x10,%esp

	// if we can't get a PCB, there's no use continuing!
	assert( pcb_alloc(&init_pcb) == SUCCESS );
   11e27:	83 ec 0c             	sub    $0xc,%esp
   11e2a:	68 0c 20 02 00       	push   $0x2200c
   11e2f:	e8 32 1a 00 00       	call   13866 <pcb_alloc>
   11e34:	83 c4 10             	add    $0x10,%esp
   11e37:	85 c0                	test   %eax,%eax
   11e39:	74 3b                	je     11e76 <main+0x12b>
   11e3b:	83 ec 04             	sub    $0x4,%esp
   11e3e:	68 ad ac 01 00       	push   $0x1acad
   11e43:	6a 00                	push   $0x0
   11e45:	68 57 01 00 00       	push   $0x157
   11e4a:	68 c9 ac 01 00       	push   $0x1acc9
   11e4f:	68 f0 ad 01 00       	push   $0x1adf0
   11e54:	68 d2 ac 01 00       	push   $0x1acd2
   11e59:	68 00 00 02 00       	push   $0x20000
   11e5e:	e8 a4 08 00 00       	call   12707 <sprint>
   11e63:	83 c4 20             	add    $0x20,%esp
   11e66:	83 ec 0c             	sub    $0xc,%esp
   11e69:	68 00 00 02 00       	push   $0x20000
   11e6e:	e8 14 06 00 00       	call   12487 <kpanic>
   11e73:	83 c4 10             	add    $0x10,%esp

	// fill in the necessary details
	init_pcb->pid = PID_INIT;
   11e76:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11e7b:	c7 40 18 01 00 00 00 	movl   $0x1,0x18(%eax)
	init_pcb->state = STATE_NEW;
   11e82:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11e87:	c7 40 1c 01 00 00 00 	movl   $0x1,0x1c(%eax)
	init_pcb->priority = PRIO_HIGH;
   11e8e:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11e93:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

	// command-line arguments for 'init'
	const char *args[3] = { "init", "+", NULL };
   11e9a:	c7 45 ec e8 ac 01 00 	movl   $0x1ace8,-0x14(%ebp)
   11ea1:	c7 45 f0 ed ac 01 00 	movl   $0x1aced,-0x10(%ebp)
   11ea8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// the entry point for 'init'
	extern int init(int,char **);

	// allocate a default-sized stack
	init_pcb->stack = pcb_stack_alloc( N_USTKPAGES );
   11eaf:	8b 1d 0c 20 02 00    	mov    0x2200c,%ebx
   11eb5:	83 ec 0c             	sub    $0xc,%esp
   11eb8:	6a 02                	push   $0x2
   11eba:	e8 a7 1a 00 00       	call   13966 <pcb_stack_alloc>
   11ebf:	83 c4 10             	add    $0x10,%esp
   11ec2:	89 43 04             	mov    %eax,0x4(%ebx)
	assert( init_pcb->stack != NULL );
   11ec5:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11eca:	8b 40 04             	mov    0x4(%eax),%eax
   11ecd:	85 c0                	test   %eax,%eax
   11ecf:	75 3b                	jne    11f0c <main+0x1c1>
   11ed1:	83 ec 04             	sub    $0x4,%esp
   11ed4:	68 ef ac 01 00       	push   $0x1acef
   11ed9:	6a 00                	push   $0x0
   11edb:	68 66 01 00 00       	push   $0x166
   11ee0:	68 c9 ac 01 00       	push   $0x1acc9
   11ee5:	68 f0 ad 01 00       	push   $0x1adf0
   11eea:	68 d2 ac 01 00       	push   $0x1acd2
   11eef:	68 00 00 02 00       	push   $0x20000
   11ef4:	e8 0e 08 00 00       	call   12707 <sprint>
   11ef9:	83 c4 20             	add    $0x20,%esp
   11efc:	83 ec 0c             	sub    $0xc,%esp
   11eff:	68 00 00 02 00       	push   $0x20000
   11f04:	e8 7e 05 00 00       	call   12487 <kpanic>
   11f09:	83 c4 10             	add    $0x10,%esp
	// remember that we used the default size
	init_pcb->stkpgs = N_USTKPAGES;
   11f0c:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11f11:	c7 40 28 02 00 00 00 	movl   $0x2,0x28(%eax)

	// initialize the stack and the context to be restored
	init_pcb->context = stack_setup( init_pcb, (uint32_t) init, args, true );
   11f18:	b9 e2 74 01 00       	mov    $0x174e2,%ecx
   11f1d:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11f22:	8b 1d 0c 20 02 00    	mov    0x2200c,%ebx
   11f28:	6a 01                	push   $0x1
   11f2a:	8d 55 ec             	lea    -0x14(%ebp),%edx
   11f2d:	52                   	push   %edx
   11f2e:	51                   	push   %ecx
   11f2f:	50                   	push   %eax
   11f30:	e8 78 4b 00 00       	call   16aad <stack_setup>
   11f35:	83 c4 10             	add    $0x10,%esp
   11f38:	89 03                	mov    %eax,(%ebx)
	assert( init_pcb->context != NULL );
   11f3a:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11f3f:	8b 00                	mov    (%eax),%eax
   11f41:	85 c0                	test   %eax,%eax
   11f43:	75 3b                	jne    11f80 <main+0x235>
   11f45:	83 ec 04             	sub    $0x4,%esp
   11f48:	68 04 ad 01 00       	push   $0x1ad04
   11f4d:	6a 00                	push   $0x0
   11f4f:	68 6c 01 00 00       	push   $0x16c
   11f54:	68 c9 ac 01 00       	push   $0x1acc9
   11f59:	68 f0 ad 01 00       	push   $0x1adf0
   11f5e:	68 d2 ac 01 00       	push   $0x1acd2
   11f63:	68 00 00 02 00       	push   $0x20000
   11f68:	e8 9a 07 00 00       	call   12707 <sprint>
   11f6d:	83 c4 20             	add    $0x20,%esp
   11f70:	83 ec 0c             	sub    $0xc,%esp
   11f73:	68 00 00 02 00       	push   $0x20000
   11f78:	e8 0a 05 00 00       	call   12487 <kpanic>
   11f7d:	83 c4 10             	add    $0x10,%esp

	// "i'm my own grandpa...."
	init_pcb->parent = init_pcb;
   11f80:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11f85:	8b 15 0c 20 02 00    	mov    0x2200c,%edx
   11f8b:	89 50 0c             	mov    %edx,0xc(%eax)

	// send it on its merry way
	schedule( init_pcb );
   11f8e:	a1 0c 20 02 00       	mov    0x2200c,%eax
   11f93:	83 ec 0c             	sub    $0xc,%esp
   11f96:	50                   	push   %eax
   11f97:	e8 33 24 00 00       	call   143cf <schedule>
   11f9c:	83 c4 10             	add    $0x10,%esp

	// make sure there's no current process
	current = NULL;
   11f9f:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   11fa6:	00 00 00 

	// pick a winner
	dispatch();
   11fa9:	e8 e2 24 00 00       	call   14490 <dispatch>

	cio_puts( " done.\n" );
   11fae:	83 ec 0c             	sub    $0xc,%esp
   11fb1:	68 1b ad 01 00       	push   $0x1ad1b
   11fb6:	e8 f2 ee ff ff       	call   10ead <cio_puts>
   11fbb:	83 c4 10             	add    $0x10,%esp

	delay( DELAY_1_SEC );
   11fbe:	83 ec 0c             	sub    $0xc,%esp
   11fc1:	6a 28                	push   $0x28
   11fc3:	e8 e3 37 00 00       	call   157ab <delay>
   11fc8:	83 c4 10             	add    $0x10,%esp

#ifdef TRACE_CX

	// wipe out whatever is on the screen at the moment
	cio_clearscreen();
   11fcb:	e8 bf ef ff ff       	call   10f8f <cio_clearscreen>

	// define a scrolling region in the top 7 lines of the screen
	cio_setscroll( 0, 7, 99, 99 );
   11fd0:	6a 63                	push   $0x63
   11fd2:	6a 63                	push   $0x63
   11fd4:	6a 07                	push   $0x7
   11fd6:	6a 00                	push   $0x0
   11fd8:	e8 16 ec ff ff       	call   10bf3 <cio_setscroll>
   11fdd:	83 c4 10             	add    $0x10,%esp

	// clear it
	cio_clearscroll();
   11fe0:	e8 31 ef ff ff       	call   10f16 <cio_clearscroll>

	// clear the top line
	cio_puts_at( 0, 0, "*                                                                               " );
   11fe5:	83 ec 04             	sub    $0x4,%esp
   11fe8:	68 24 ad 01 00       	push   $0x1ad24
   11fed:	6a 00                	push   $0x0
   11fef:	6a 00                	push   $0x0
   11ff1:	e8 75 ee ff ff       	call   10e6b <cio_puts_at>
   11ff6:	83 c4 10             	add    $0x10,%esp
	// separator
	cio_puts_at( 0, 6, "================================================================================" );
   11ff9:	83 ec 04             	sub    $0x4,%esp
   11ffc:	68 78 ad 01 00       	push   $0x1ad78
   12001:	6a 06                	push   $0x6
   12003:	6a 00                	push   $0x0
   12005:	e8 61 ee ff ff       	call   10e6b <cio_puts_at>
   1200a:	83 c4 10             	add    $0x10,%esp

	/*
	** END OF TERM-SPECIFIC CODE
	*/

	sio_flush( SIO_RX | SIO_TX );
   1200d:	83 ec 0c             	sub    $0xc,%esp
   12010:	6a 03                	push   $0x3
   12012:	e8 45 30 00 00       	call   1505c <sio_flush>
   12017:	83 c4 10             	add    $0x10,%esp
	sio_enable( SIO_RX );
   1201a:	83 ec 0c             	sub    $0xc,%esp
   1201d:	6a 02                	push   $0x2
   1201f:	e8 48 2f 00 00       	call   14f6c <sio_enable>
   12024:	83 c4 10             	add    $0x10,%esp

	cio_puts( "System initialization complete.\n" );
   12027:	83 ec 0c             	sub    $0xc,%esp
   1202a:	68 cc ad 01 00       	push   $0x1adcc
   1202f:	e8 79 ee ff ff       	call   10ead <cio_puts>
   12034:	83 c4 10             	add    $0x10,%esp
	cio_puts( "-------------------------------\n" );
   12037:	83 ec 0c             	sub    $0xc,%esp
   1203a:	68 0c ac 01 00       	push   $0x1ac0c
   1203f:	e8 69 ee ff ff       	call   10ead <cio_puts>
   12044:	83 c4 10             	add    $0x10,%esp
	pcb_dump( "Current: ", current, true );

	delay( DELAY_2_SEC );
#endif

	return 0;
   12047:	b8 00 00 00 00       	mov    $0x0,%eax
}
   1204c:	8d 65 f8             	lea    -0x8(%ebp),%esp
   1204f:	59                   	pop    %ecx
   12050:	5b                   	pop    %ebx
   12051:	5d                   	pop    %ebp
   12052:	8d 61 fc             	lea    -0x4(%ecx),%esp
   12055:	c3                   	ret    

00012056 <blkmov>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void blkmov( void *dst, const void *src, register uint32_t len ) {
   12056:	55                   	push   %ebp
   12057:	89 e5                	mov    %esp,%ebp
   12059:	56                   	push   %esi
   1205a:	53                   	push   %ebx
   1205b:	8b 45 10             	mov    0x10(%ebp),%eax

	// verify that the addresses are aligned and
	// the length is a multiple of four bytes
	if( (((uint32_t)dst)&0x3) != 0 ||
   1205e:	8b 55 08             	mov    0x8(%ebp),%edx
   12061:	83 e2 03             	and    $0x3,%edx
   12064:	85 d2                	test   %edx,%edx
   12066:	75 13                	jne    1207b <blkmov+0x25>
		(((uint32_t)src)&0x3) != 0 ||
   12068:	8b 55 0c             	mov    0xc(%ebp),%edx
   1206b:	83 e2 03             	and    $0x3,%edx
	if( (((uint32_t)dst)&0x3) != 0 ||
   1206e:	85 d2                	test   %edx,%edx
   12070:	75 09                	jne    1207b <blkmov+0x25>
		(len & 0x3) != 0 ) {
   12072:	89 c2                	mov    %eax,%edx
   12074:	83 e2 03             	and    $0x3,%edx
		(((uint32_t)src)&0x3) != 0 ||
   12077:	85 d2                	test   %edx,%edx
   12079:	74 14                	je     1208f <blkmov+0x39>
		// something isn't aligned, so just use memmove()
		memmove( dst, src, len );
   1207b:	83 ec 04             	sub    $0x4,%esp
   1207e:	50                   	push   %eax
   1207f:	ff 75 0c             	pushl  0xc(%ebp)
   12082:	ff 75 08             	pushl  0x8(%ebp)
   12085:	e8 48 05 00 00       	call   125d2 <memmove>
   1208a:	83 c4 10             	add    $0x10,%esp
		return;
   1208d:	eb 5a                	jmp    120e9 <blkmov+0x93>
	}

	// everything is nicely aligned, so off we go
	register uint32_t *dest = dst;
   1208f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint32_t *source = src;
   12092:	8b 75 0c             	mov    0xc(%ebp),%esi

	// now copying 32-bit values
	len /= 4;
   12095:	c1 e8 02             	shr    $0x2,%eax

	if( source < dest && (source + len) > dest ) {
   12098:	39 de                	cmp    %ebx,%esi
   1209a:	73 44                	jae    120e0 <blkmov+0x8a>
   1209c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   120a3:	01 f2                	add    %esi,%edx
   120a5:	39 d3                	cmp    %edx,%ebx
   120a7:	73 37                	jae    120e0 <blkmov+0x8a>
		source += len;
   120a9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   120b0:	01 d6                	add    %edx,%esi
		dest += len;
   120b2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   120b9:	01 d3                	add    %edx,%ebx
		while( len-- > 0 ) {
   120bb:	eb 0a                	jmp    120c7 <blkmov+0x71>
			*--dest = *--source;
   120bd:	83 ee 04             	sub    $0x4,%esi
   120c0:	83 eb 04             	sub    $0x4,%ebx
   120c3:	8b 16                	mov    (%esi),%edx
   120c5:	89 13                	mov    %edx,(%ebx)
		while( len-- > 0 ) {
   120c7:	89 c2                	mov    %eax,%edx
   120c9:	8d 42 ff             	lea    -0x1(%edx),%eax
   120cc:	85 d2                	test   %edx,%edx
   120ce:	75 ed                	jne    120bd <blkmov+0x67>
	if( source < dest && (source + len) > dest ) {
   120d0:	eb 17                	jmp    120e9 <blkmov+0x93>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   120d2:	89 f1                	mov    %esi,%ecx
   120d4:	8d 71 04             	lea    0x4(%ecx),%esi
   120d7:	89 da                	mov    %ebx,%edx
   120d9:	8d 5a 04             	lea    0x4(%edx),%ebx
   120dc:	8b 09                	mov    (%ecx),%ecx
   120de:	89 0a                	mov    %ecx,(%edx)
		while( len-- ) {
   120e0:	89 c2                	mov    %eax,%edx
   120e2:	8d 42 ff             	lea    -0x1(%edx),%eax
   120e5:	85 d2                	test   %edx,%edx
   120e7:	75 e9                	jne    120d2 <blkmov+0x7c>
		}
	}
}
   120e9:	8d 65 f8             	lea    -0x8(%ebp),%esp
   120ec:	5b                   	pop    %ebx
   120ed:	5e                   	pop    %esi
   120ee:	5d                   	pop    %ebp
   120ef:	c3                   	ret    

000120f0 <bound>:
** @param value  Value to be constrained
** @param max    Upper bound
**
** @return The constrained value
*/
uint32_t bound( uint32_t min, uint32_t value, uint32_t max ) {
   120f0:	55                   	push   %ebp
   120f1:	89 e5                	mov    %esp,%ebp
	if( value < min ){
   120f3:	8b 45 0c             	mov    0xc(%ebp),%eax
   120f6:	3b 45 08             	cmp    0x8(%ebp),%eax
   120f9:	73 06                	jae    12101 <bound+0x11>
		value = min;
   120fb:	8b 45 08             	mov    0x8(%ebp),%eax
   120fe:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	if( value > max ){
   12101:	8b 45 0c             	mov    0xc(%ebp),%eax
   12104:	3b 45 10             	cmp    0x10(%ebp),%eax
   12107:	76 06                	jbe    1210f <bound+0x1f>
		value = max;
   12109:	8b 45 10             	mov    0x10(%ebp),%eax
   1210c:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	return value;
   1210f:	8b 45 0c             	mov    0xc(%ebp),%eax
}
   12112:	5d                   	pop    %ebp
   12113:	c3                   	ret    

00012114 <cvtdec>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtdec( char *buf, int32_t value ) {
   12114:	55                   	push   %ebp
   12115:	89 e5                	mov    %esp,%ebp
   12117:	83 ec 18             	sub    $0x18,%esp
	char *bp = buf;
   1211a:	8b 45 08             	mov    0x8(%ebp),%eax
   1211d:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if( value < 0 ) {
   12120:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   12124:	79 0f                	jns    12135 <cvtdec+0x21>
		*bp++ = '-';
   12126:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12129:	8d 50 01             	lea    0x1(%eax),%edx
   1212c:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1212f:	c6 00 2d             	movb   $0x2d,(%eax)
		value = -value;
   12132:	f7 5d 0c             	negl   0xc(%ebp)
	}

	bp = cvtdec0( bp, value );
   12135:	83 ec 08             	sub    $0x8,%esp
   12138:	ff 75 0c             	pushl  0xc(%ebp)
   1213b:	ff 75 f4             	pushl  -0xc(%ebp)
   1213e:	e8 18 00 00 00       	call   1215b <cvtdec0>
   12143:	83 c4 10             	add    $0x10,%esp
   12146:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp  = '\0';
   12149:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1214c:	c6 00 00             	movb   $0x0,(%eax)

	return( bp - buf );
   1214f:	8b 55 f4             	mov    -0xc(%ebp),%edx
   12152:	8b 45 08             	mov    0x8(%ebp),%eax
   12155:	29 c2                	sub    %eax,%edx
   12157:	89 d0                	mov    %edx,%eax
}
   12159:	c9                   	leave  
   1215a:	c3                   	ret    

0001215b <cvtdec0>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *cvtdec0( char *buf, int value ) {
   1215b:	55                   	push   %ebp
   1215c:	89 e5                	mov    %esp,%ebp
   1215e:	83 ec 18             	sub    $0x18,%esp
	int quotient;

	quotient = value / 10;
   12161:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   12164:	ba 67 66 66 66       	mov    $0x66666667,%edx
   12169:	89 c8                	mov    %ecx,%eax
   1216b:	f7 ea                	imul   %edx
   1216d:	c1 fa 02             	sar    $0x2,%edx
   12170:	89 c8                	mov    %ecx,%eax
   12172:	c1 f8 1f             	sar    $0x1f,%eax
   12175:	29 c2                	sub    %eax,%edx
   12177:	89 d0                	mov    %edx,%eax
   12179:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient < 0 ) {
   1217c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12180:	79 0e                	jns    12190 <cvtdec0+0x35>
		quotient = 214748364;
   12182:	c7 45 f4 cc cc cc 0c 	movl   $0xccccccc,-0xc(%ebp)
		value = 8;
   12189:	c7 45 0c 08 00 00 00 	movl   $0x8,0xc(%ebp)
	}
	if( quotient != 0 ) {
   12190:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12194:	74 14                	je     121aa <cvtdec0+0x4f>
		buf = cvtdec0( buf, quotient );
   12196:	83 ec 08             	sub    $0x8,%esp
   12199:	ff 75 f4             	pushl  -0xc(%ebp)
   1219c:	ff 75 08             	pushl  0x8(%ebp)
   1219f:	e8 b7 ff ff ff       	call   1215b <cvtdec0>
   121a4:	83 c4 10             	add    $0x10,%esp
   121a7:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   121aa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   121ad:	ba 67 66 66 66       	mov    $0x66666667,%edx
   121b2:	89 c8                	mov    %ecx,%eax
   121b4:	f7 ea                	imul   %edx
   121b6:	c1 fa 02             	sar    $0x2,%edx
   121b9:	89 c8                	mov    %ecx,%eax
   121bb:	c1 f8 1f             	sar    $0x1f,%eax
   121be:	29 c2                	sub    %eax,%edx
   121c0:	89 d0                	mov    %edx,%eax
   121c2:	c1 e0 02             	shl    $0x2,%eax
   121c5:	01 d0                	add    %edx,%eax
   121c7:	01 c0                	add    %eax,%eax
   121c9:	29 c1                	sub    %eax,%ecx
   121cb:	89 ca                	mov    %ecx,%edx
   121cd:	89 d0                	mov    %edx,%eax
   121cf:	8d 48 30             	lea    0x30(%eax),%ecx
   121d2:	8b 45 08             	mov    0x8(%ebp),%eax
   121d5:	8d 50 01             	lea    0x1(%eax),%edx
   121d8:	89 55 08             	mov    %edx,0x8(%ebp)
   121db:	89 ca                	mov    %ecx,%edx
   121dd:	88 10                	mov    %dl,(%eax)
	return buf;
   121df:	8b 45 08             	mov    0x8(%ebp),%eax
}
   121e2:	c9                   	leave  
   121e3:	c3                   	ret    

000121e4 <cvthex>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvthex( char *buf, uint32_t value ) {
   121e4:	55                   	push   %ebp
   121e5:	89 e5                	mov    %esp,%ebp
   121e7:	83 ec 20             	sub    $0x20,%esp
	const char hexdigits[] = "0123456789ABCDEF";
   121ea:	c7 45 e3 30 31 32 33 	movl   $0x33323130,-0x1d(%ebp)
   121f1:	c7 45 e7 34 35 36 37 	movl   $0x37363534,-0x19(%ebp)
   121f8:	c7 45 eb 38 39 41 42 	movl   $0x42413938,-0x15(%ebp)
   121ff:	c7 45 ef 43 44 45 46 	movl   $0x46454443,-0x11(%ebp)
   12206:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)
	int chars_stored = 0;
   1220a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)

	for( int i = 0; i < 8; i += 1 ) {
   12211:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
   12218:	eb 43                	jmp    1225d <cvthex+0x79>
		uint32_t val = value & 0xf0000000;
   1221a:	8b 45 0c             	mov    0xc(%ebp),%eax
   1221d:	25 00 00 00 f0       	and    $0xf0000000,%eax
   12222:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if( chars_stored || val != 0 || i == 7 ) {
   12225:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
   12229:	75 0c                	jne    12237 <cvthex+0x53>
   1222b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1222f:	75 06                	jne    12237 <cvthex+0x53>
   12231:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   12235:	75 1e                	jne    12255 <cvthex+0x71>
			++chars_stored;
   12237:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
			val = (val >> 28) & 0xf;
   1223b:	c1 6d f4 1c          	shrl   $0x1c,-0xc(%ebp)
			*buf++ = hexdigits[val];
   1223f:	8b 45 08             	mov    0x8(%ebp),%eax
   12242:	8d 50 01             	lea    0x1(%eax),%edx
   12245:	89 55 08             	mov    %edx,0x8(%ebp)
   12248:	8d 4d e3             	lea    -0x1d(%ebp),%ecx
   1224b:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1224e:	01 ca                	add    %ecx,%edx
   12250:	0f b6 12             	movzbl (%edx),%edx
   12253:	88 10                	mov    %dl,(%eax)
		}
		value <<= 4;
   12255:	c1 65 0c 04          	shll   $0x4,0xc(%ebp)
	for( int i = 0; i < 8; i += 1 ) {
   12259:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
   1225d:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   12261:	7e b7                	jle    1221a <cvthex+0x36>
	}

	*buf = '\0';
   12263:	8b 45 08             	mov    0x8(%ebp),%eax
   12266:	c6 00 00             	movb   $0x0,(%eax)

	return( chars_stored );
   12269:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   1226c:	c9                   	leave  
   1226d:	c3                   	ret    

0001226e <cvtoct>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtoct( char *buf, uint32_t value ) {
   1226e:	55                   	push   %ebp
   1226f:	89 e5                	mov    %esp,%ebp
   12271:	83 ec 10             	sub    $0x10,%esp
	int i;
	int chars_stored = 0;
   12274:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	char *bp = buf;
   1227b:	8b 45 08             	mov    0x8(%ebp),%eax
   1227e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32_t val;

	val = ( value & 0xc0000000 );
   12281:	8b 45 0c             	mov    0xc(%ebp),%eax
   12284:	25 00 00 00 c0       	and    $0xc0000000,%eax
   12289:	89 45 f0             	mov    %eax,-0x10(%ebp)
	val >>= 30;
   1228c:	c1 6d f0 1e          	shrl   $0x1e,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   12290:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   12297:	eb 47                	jmp    122e0 <cvtoct+0x72>

		if( i == 10 || val != 0 || chars_stored ) {
   12299:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   1229d:	74 0c                	je     122ab <cvtoct+0x3d>
   1229f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   122a3:	75 06                	jne    122ab <cvtoct+0x3d>
   122a5:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
   122a9:	74 1e                	je     122c9 <cvtoct+0x5b>
			chars_stored = 1;
   122ab:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)
			val &= 0x7;
   122b2:	83 65 f0 07          	andl   $0x7,-0x10(%ebp)
			*bp++ = val + '0';
   122b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
   122b9:	8d 48 30             	lea    0x30(%eax),%ecx
   122bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
   122bf:	8d 50 01             	lea    0x1(%eax),%edx
   122c2:	89 55 f4             	mov    %edx,-0xc(%ebp)
   122c5:	89 ca                	mov    %ecx,%edx
   122c7:	88 10                	mov    %dl,(%eax)
		}
		value <<= 3;
   122c9:	c1 65 0c 03          	shll   $0x3,0xc(%ebp)
		val = ( value & 0xe0000000 );
   122cd:	8b 45 0c             	mov    0xc(%ebp),%eax
   122d0:	25 00 00 00 e0       	and    $0xe0000000,%eax
   122d5:	89 45 f0             	mov    %eax,-0x10(%ebp)
		val >>= 29;
   122d8:	c1 6d f0 1d          	shrl   $0x1d,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   122dc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   122e0:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   122e4:	7e b3                	jle    12299 <cvtoct+0x2b>
	}
	*bp = '\0';
   122e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
   122e9:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   122ec:	8b 55 f4             	mov    -0xc(%ebp),%edx
   122ef:	8b 45 08             	mov    0x8(%ebp),%eax
   122f2:	29 c2                	sub    %eax,%edx
   122f4:	89 d0                	mov    %edx,%eax
}
   122f6:	c9                   	leave  
   122f7:	c3                   	ret    

000122f8 <cvtuns>:
**
** @return Length of the resulting buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtuns( char *buf, uint32_t value ) {
   122f8:	55                   	push   %ebp
   122f9:	89 e5                	mov    %esp,%ebp
   122fb:	83 ec 18             	sub    $0x18,%esp
	char    *bp = buf;
   122fe:	8b 45 08             	mov    0x8(%ebp),%eax
   12301:	89 45 f4             	mov    %eax,-0xc(%ebp)

	bp = cvtuns0( bp, value );
   12304:	83 ec 08             	sub    $0x8,%esp
   12307:	ff 75 0c             	pushl  0xc(%ebp)
   1230a:	ff 75 f4             	pushl  -0xc(%ebp)
   1230d:	e8 18 00 00 00       	call   1232a <cvtuns0>
   12312:	83 c4 10             	add    $0x10,%esp
   12315:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp = '\0';
   12318:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1231b:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   1231e:	8b 55 f4             	mov    -0xc(%ebp),%edx
   12321:	8b 45 08             	mov    0x8(%ebp),%eax
   12324:	29 c2                	sub    %eax,%edx
   12326:	89 d0                	mov    %edx,%eax
}
   12328:	c9                   	leave  
   12329:	c3                   	ret    

0001232a <cvtuns0>:
**
** @return Pointer to the first unused byte in the buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *cvtuns0( char *buf, uint32_t value ) {
   1232a:	55                   	push   %ebp
   1232b:	89 e5                	mov    %esp,%ebp
   1232d:	83 ec 18             	sub    $0x18,%esp
	uint32_t quotient;

	quotient = value / 10;
   12330:	8b 45 0c             	mov    0xc(%ebp),%eax
   12333:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   12338:	f7 e2                	mul    %edx
   1233a:	89 d0                	mov    %edx,%eax
   1233c:	c1 e8 03             	shr    $0x3,%eax
   1233f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient != 0 ){
   12342:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12346:	74 15                	je     1235d <cvtuns0+0x33>
		buf = cvtdec0( buf, quotient );
   12348:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1234b:	83 ec 08             	sub    $0x8,%esp
   1234e:	50                   	push   %eax
   1234f:	ff 75 08             	pushl  0x8(%ebp)
   12352:	e8 04 fe ff ff       	call   1215b <cvtdec0>
   12357:	83 c4 10             	add    $0x10,%esp
   1235a:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   1235d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   12360:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   12365:	89 c8                	mov    %ecx,%eax
   12367:	f7 e2                	mul    %edx
   12369:	c1 ea 03             	shr    $0x3,%edx
   1236c:	89 d0                	mov    %edx,%eax
   1236e:	c1 e0 02             	shl    $0x2,%eax
   12371:	01 d0                	add    %edx,%eax
   12373:	01 c0                	add    %eax,%eax
   12375:	29 c1                	sub    %eax,%ecx
   12377:	89 ca                	mov    %ecx,%edx
   12379:	89 d0                	mov    %edx,%eax
   1237b:	8d 48 30             	lea    0x30(%eax),%ecx
   1237e:	8b 45 08             	mov    0x8(%ebp),%eax
   12381:	8d 50 01             	lea    0x1(%eax),%edx
   12384:	89 55 08             	mov    %edx,0x8(%ebp)
   12387:	89 ca                	mov    %ecx,%edx
   12389:	88 10                	mov    %dl,(%eax)
	return buf;
   1238b:	8b 45 08             	mov    0x8(%ebp),%eax
}
   1238e:	c9                   	leave  
   1238f:	c3                   	ret    

00012390 <put_char_or_code>:
** is a non-printing character, in which case its hex code
** is printed
**
** @param ch    The character to be printed
*/
void put_char_or_code( int ch ) {
   12390:	55                   	push   %ebp
   12391:	89 e5                	mov    %esp,%ebp
   12393:	83 ec 08             	sub    $0x8,%esp

	if( ch >= ' ' && ch < 0x7f ) {
   12396:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
   1239a:	7e 17                	jle    123b3 <put_char_or_code+0x23>
   1239c:	83 7d 08 7e          	cmpl   $0x7e,0x8(%ebp)
   123a0:	7f 11                	jg     123b3 <put_char_or_code+0x23>
		cio_putchar( ch );
   123a2:	8b 45 08             	mov    0x8(%ebp),%eax
   123a5:	83 ec 0c             	sub    $0xc,%esp
   123a8:	50                   	push   %eax
   123a9:	e8 bf e9 ff ff       	call   10d6d <cio_putchar>
   123ae:	83 c4 10             	add    $0x10,%esp
   123b1:	eb 13                	jmp    123c6 <put_char_or_code+0x36>
	} else {
		cio_printf( "\\x%02x", ch );
   123b3:	83 ec 08             	sub    $0x8,%esp
   123b6:	ff 75 08             	pushl  0x8(%ebp)
   123b9:	68 f8 ad 01 00       	push   $0x1adf8
   123be:	e8 64 f1 ff ff       	call   11527 <cio_printf>
   123c3:	83 c4 10             	add    $0x10,%esp
	}
}
   123c6:	90                   	nop
   123c7:	c9                   	leave  
   123c8:	c3                   	ret    

000123c9 <backtrace>:
** Perform a stack backtrace
**
** @param ebp   Initial EBP to use
** @param args  Number of function argument values to print
*/
void backtrace( uint32_t *ebp, uint_t args ) {
   123c9:	55                   	push   %ebp
   123ca:	89 e5                	mov    %esp,%ebp
   123cc:	83 ec 18             	sub    $0x18,%esp

	cio_puts( "Trace:  " );
   123cf:	83 ec 0c             	sub    $0xc,%esp
   123d2:	68 ff ad 01 00       	push   $0x1adff
   123d7:	e8 d1 ea ff ff       	call   10ead <cio_puts>
   123dc:	83 c4 10             	add    $0x10,%esp
	if( ebp == NULL ) {
   123df:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   123e3:	75 15                	jne    123fa <backtrace+0x31>
		cio_puts( "NULL ebp, no trace possible\n" );
   123e5:	83 ec 0c             	sub    $0xc,%esp
   123e8:	68 08 ae 01 00       	push   $0x1ae08
   123ed:	e8 bb ea ff ff       	call   10ead <cio_puts>
   123f2:	83 c4 10             	add    $0x10,%esp
		return;
   123f5:	e9 8b 00 00 00       	jmp    12485 <backtrace+0xbc>
	} else {
		cio_putchar( '\n' );
   123fa:	83 ec 0c             	sub    $0xc,%esp
   123fd:	6a 0a                	push   $0xa
   123ff:	e8 69 e9 ff ff       	call   10d6d <cio_putchar>
   12404:	83 c4 10             	add    $0x10,%esp
	}

	while( ebp != NULL ){
   12407:	eb 76                	jmp    1247f <backtrace+0xb6>

		// get return address and report it and EBP
		uint32_t ret = ebp[1];
   12409:	8b 45 08             	mov    0x8(%ebp),%eax
   1240c:	8b 40 04             	mov    0x4(%eax),%eax
   1240f:	89 45 f0             	mov    %eax,-0x10(%ebp)
		cio_printf( " ebp %08x ret %08x args", (uint32_t) ebp, ret );
   12412:	8b 45 08             	mov    0x8(%ebp),%eax
   12415:	83 ec 04             	sub    $0x4,%esp
   12418:	ff 75 f0             	pushl  -0x10(%ebp)
   1241b:	50                   	push   %eax
   1241c:	68 25 ae 01 00       	push   $0x1ae25
   12421:	e8 01 f1 ff ff       	call   11527 <cio_printf>
   12426:	83 c4 10             	add    $0x10,%esp

		// print the requested number of function arguments
		for( uint_t i = 0; i < args; ++i ) {
   12429:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   12430:	eb 30                	jmp    12462 <backtrace+0x99>
			cio_printf( " [%u] %08x", i+1, ebp[2+i] );
   12432:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12435:	83 c0 02             	add    $0x2,%eax
   12438:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1243f:	8b 45 08             	mov    0x8(%ebp),%eax
   12442:	01 d0                	add    %edx,%eax
   12444:	8b 00                	mov    (%eax),%eax
   12446:	8b 55 f4             	mov    -0xc(%ebp),%edx
   12449:	83 c2 01             	add    $0x1,%edx
   1244c:	83 ec 04             	sub    $0x4,%esp
   1244f:	50                   	push   %eax
   12450:	52                   	push   %edx
   12451:	68 3d ae 01 00       	push   $0x1ae3d
   12456:	e8 cc f0 ff ff       	call   11527 <cio_printf>
   1245b:	83 c4 10             	add    $0x10,%esp
		for( uint_t i = 0; i < args; ++i ) {
   1245e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   12462:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12465:	3b 45 0c             	cmp    0xc(%ebp),%eax
   12468:	72 c8                	jb     12432 <backtrace+0x69>
		}
		cio_putchar( '\n' );
   1246a:	83 ec 0c             	sub    $0xc,%esp
   1246d:	6a 0a                	push   $0xa
   1246f:	e8 f9 e8 ff ff       	call   10d6d <cio_putchar>
   12474:	83 c4 10             	add    $0x10,%esp

		// follow the chain
		ebp = (uint32_t *) *ebp;
   12477:	8b 45 08             	mov    0x8(%ebp),%eax
   1247a:	8b 00                	mov    (%eax),%eax
   1247c:	89 45 08             	mov    %eax,0x8(%ebp)
	while( ebp != NULL ){
   1247f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12483:	75 84                	jne    12409 <backtrace+0x40>
	}
}
   12485:	c9                   	leave  
   12486:	c3                   	ret    

00012487 <kpanic>:
** (e.g., printing a stack traceback)
**
** @param msg[in]  String containing a relevant message to be printed,
**				   or NULL
*/
void kpanic( const char *msg ) {
   12487:	55                   	push   %ebp
   12488:	89 e5                	mov    %esp,%ebp
   1248a:	83 ec 18             	sub    $0x18,%esp

	cio_puts( "\n\n***** KERNEL PANIC *****\n\n" );
   1248d:	83 ec 0c             	sub    $0xc,%esp
   12490:	68 48 ae 01 00       	push   $0x1ae48
   12495:	e8 13 ea ff ff       	call   10ead <cio_puts>
   1249a:	83 c4 10             	add    $0x10,%esp

	if( msg ) {
   1249d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   124a1:	74 13                	je     124b6 <kpanic+0x2f>
		cio_printf( "%s\n", msg );
   124a3:	83 ec 08             	sub    $0x8,%esp
   124a6:	ff 75 08             	pushl  0x8(%ebp)
   124a9:	68 65 ae 01 00       	push   $0x1ae65
   124ae:	e8 74 f0 ff ff       	call   11527 <cio_printf>
   124b3:	83 c4 10             	add    $0x10,%esp
	}

	delay( DELAY_5_SEC );   // approximately
   124b6:	83 ec 0c             	sub    $0xc,%esp
   124b9:	68 c8 00 00 00       	push   $0xc8
   124be:	e8 e8 32 00 00       	call   157ab <delay>
   124c3:	83 c4 10             	add    $0x10,%esp

	// dump a bunch of potentially useful information

	// dump the contents of the current PCB
	pcb_dump( "Current", current, true );
   124c6:	a1 14 20 02 00       	mov    0x22014,%eax
   124cb:	83 ec 04             	sub    $0x4,%esp
   124ce:	6a 01                	push   $0x1
   124d0:	50                   	push   %eax
   124d1:	68 69 ae 01 00       	push   $0x1ae69
   124d6:	e8 f3 21 00 00       	call   146ce <pcb_dump>
   124db:	83 c4 10             	add    $0x10,%esp

	// dump the basic info about what's in the process table
	ptable_dump_counts();
   124de:	e8 28 25 00 00       	call   14a0b <ptable_dump_counts>

	// dump information about the queues
	pcb_queue_dump( "R", ready, true );
   124e3:	a1 d0 24 02 00       	mov    0x224d0,%eax
   124e8:	83 ec 04             	sub    $0x4,%esp
   124eb:	6a 01                	push   $0x1
   124ed:	50                   	push   %eax
   124ee:	68 71 ae 01 00       	push   $0x1ae71
   124f3:	e8 15 23 00 00       	call   1480d <pcb_queue_dump>
   124f8:	83 c4 10             	add    $0x10,%esp
	pcb_queue_dump( "W", waiting, true );
   124fb:	a1 10 20 02 00       	mov    0x22010,%eax
   12500:	83 ec 04             	sub    $0x4,%esp
   12503:	6a 01                	push   $0x1
   12505:	50                   	push   %eax
   12506:	68 73 ae 01 00       	push   $0x1ae73
   1250b:	e8 fd 22 00 00       	call   1480d <pcb_queue_dump>
   12510:	83 c4 10             	add    $0x10,%esp
	pcb_queue_dump( "S", sleeping, true );
   12513:	a1 08 20 02 00       	mov    0x22008,%eax
   12518:	83 ec 04             	sub    $0x4,%esp
   1251b:	6a 01                	push   $0x1
   1251d:	50                   	push   %eax
   1251e:	68 75 ae 01 00       	push   $0x1ae75
   12523:	e8 e5 22 00 00       	call   1480d <pcb_queue_dump>
   12528:	83 c4 10             	add    $0x10,%esp
	pcb_queue_dump( "Z", zombie, true );
   1252b:	a1 18 20 02 00       	mov    0x22018,%eax
   12530:	83 ec 04             	sub    $0x4,%esp
   12533:	6a 01                	push   $0x1
   12535:	50                   	push   %eax
   12536:	68 77 ae 01 00       	push   $0x1ae77
   1253b:	e8 cd 22 00 00       	call   1480d <pcb_queue_dump>
   12540:	83 c4 10             	add    $0x10,%esp
	pcb_queue_dump( "I", sioread, true );
   12543:	a1 04 20 02 00       	mov    0x22004,%eax
   12548:	83 ec 04             	sub    $0x4,%esp
   1254b:	6a 01                	push   $0x1
   1254d:	50                   	push   %eax
   1254e:	68 79 ae 01 00       	push   $0x1ae79
   12553:	e8 b5 22 00 00       	call   1480d <pcb_queue_dump>
   12558:	83 c4 10             	add    $0x10,%esp
	__asm__ __volatile__( "movl %%ebp,%0" : "=r" (val) );
   1255b:	89 e8                	mov    %ebp,%eax
   1255d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return val;
   12560:	8b 45 f4             	mov    -0xc(%ebp),%eax

	// perform a stack backtrace
	backtrace( (uint32_t *) r_ebp(), 3 );
   12563:	83 ec 08             	sub    $0x8,%esp
   12566:	6a 03                	push   $0x3
   12568:	50                   	push   %eax
   12569:	e8 5b fe ff ff       	call   123c9 <backtrace>
   1256e:	83 c4 10             	add    $0x10,%esp

	// could dump other stuff here, too

	panic( "KERNEL PANIC" );
   12571:	83 ec 0c             	sub    $0xc,%esp
   12574:	68 7b ae 01 00       	push   $0x1ae7b
   12579:	e8 d9 31 00 00       	call   15757 <panic>
   1257e:	83 c4 10             	add    $0x10,%esp
}
   12581:	90                   	nop
   12582:	c9                   	leave  
   12583:	c3                   	ret    

00012584 <memclr>:
** Initialize all bytes of a block of memory to zero
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
*/
void memclr( void *buf, register uint32_t len ) {
   12584:	55                   	push   %ebp
   12585:	89 e5                	mov    %esp,%ebp
   12587:	53                   	push   %ebx
   12588:	8b 55 0c             	mov    0xc(%ebp),%edx
	register uint8_t *dest = buf;
   1258b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and clearing
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   1258e:	eb 08                	jmp    12598 <memclr+0x14>
			*dest++ = 0;
   12590:	89 d8                	mov    %ebx,%eax
   12592:	8d 58 01             	lea    0x1(%eax),%ebx
   12595:	c6 00 00             	movb   $0x0,(%eax)
	while( len-- ) {
   12598:	89 d0                	mov    %edx,%eax
   1259a:	8d 50 ff             	lea    -0x1(%eax),%edx
   1259d:	85 c0                	test   %eax,%eax
   1259f:	75 ef                	jne    12590 <memclr+0xc>
	}
}
   125a1:	90                   	nop
   125a2:	5b                   	pop    %ebx
   125a3:	5d                   	pop    %ebp
   125a4:	c3                   	ret    

000125a5 <memcpy>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void memcpy( void *dst, register const void *src, register uint32_t len ) {
   125a5:	55                   	push   %ebp
   125a6:	89 e5                	mov    %esp,%ebp
   125a8:	56                   	push   %esi
   125a9:	53                   	push   %ebx
   125aa:	8b 4d 10             	mov    0x10(%ebp),%ecx
	register uint8_t *dest = dst;
   125ad:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint8_t *source = src;
   125b0:	8b 75 0c             	mov    0xc(%ebp),%esi
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   125b3:	eb 0f                	jmp    125c4 <memcpy+0x1f>
		*dest++ = *source++;
   125b5:	89 f2                	mov    %esi,%edx
   125b7:	8d 72 01             	lea    0x1(%edx),%esi
   125ba:	89 d8                	mov    %ebx,%eax
   125bc:	8d 58 01             	lea    0x1(%eax),%ebx
   125bf:	0f b6 12             	movzbl (%edx),%edx
   125c2:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   125c4:	89 c8                	mov    %ecx,%eax
   125c6:	8d 48 ff             	lea    -0x1(%eax),%ecx
   125c9:	85 c0                	test   %eax,%eax
   125cb:	75 e8                	jne    125b5 <memcpy+0x10>
	}
}
   125cd:	90                   	nop
   125ce:	5b                   	pop    %ebx
   125cf:	5e                   	pop    %esi
   125d0:	5d                   	pop    %ebp
   125d1:	c3                   	ret    

000125d2 <memmove>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void memmove( void *dst, const void *src, register uint32_t len ) {
   125d2:	55                   	push   %ebp
   125d3:	89 e5                	mov    %esp,%ebp
   125d5:	56                   	push   %esi
   125d6:	53                   	push   %ebx
   125d7:	8b 45 10             	mov    0x10(%ebp),%eax
	register uint8_t *dest = dst;
   125da:	8b 75 08             	mov    0x8(%ebp),%esi
	register const uint8_t *source = src;
   125dd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	if( source < dest && (source + len) > dest ) {
   125e0:	39 f3                	cmp    %esi,%ebx
   125e2:	73 32                	jae    12616 <memmove+0x44>
   125e4:	8d 14 03             	lea    (%ebx,%eax,1),%edx
   125e7:	39 d6                	cmp    %edx,%esi
   125e9:	73 2b                	jae    12616 <memmove+0x44>
		source += len;
   125eb:	01 c3                	add    %eax,%ebx
		dest += len;
   125ed:	01 c6                	add    %eax,%esi
		while( len-- > 0 ) {
   125ef:	eb 0b                	jmp    125fc <memmove+0x2a>
			*--dest = *--source;
   125f1:	83 eb 01             	sub    $0x1,%ebx
   125f4:	83 ee 01             	sub    $0x1,%esi
   125f7:	0f b6 13             	movzbl (%ebx),%edx
   125fa:	88 16                	mov    %dl,(%esi)
		while( len-- > 0 ) {
   125fc:	89 c2                	mov    %eax,%edx
   125fe:	8d 42 ff             	lea    -0x1(%edx),%eax
   12601:	85 d2                	test   %edx,%edx
   12603:	75 ec                	jne    125f1 <memmove+0x1f>
	if( source < dest && (source + len) > dest ) {
   12605:	eb 18                	jmp    1261f <memmove+0x4d>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   12607:	89 d9                	mov    %ebx,%ecx
   12609:	8d 59 01             	lea    0x1(%ecx),%ebx
   1260c:	89 f2                	mov    %esi,%edx
   1260e:	8d 72 01             	lea    0x1(%edx),%esi
   12611:	0f b6 09             	movzbl (%ecx),%ecx
   12614:	88 0a                	mov    %cl,(%edx)
		while( len-- ) {
   12616:	89 c2                	mov    %eax,%edx
   12618:	8d 42 ff             	lea    -0x1(%edx),%eax
   1261b:	85 d2                	test   %edx,%edx
   1261d:	75 e8                	jne    12607 <memmove+0x35>
		}
	}
}
   1261f:	90                   	nop
   12620:	5b                   	pop    %ebx
   12621:	5e                   	pop    %esi
   12622:	5d                   	pop    %ebp
   12623:	c3                   	ret    

00012624 <memset>:
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
** @param value  Initialization value
*/
void memset( void *buf, register uint32_t len, register uint32_t value ) {
   12624:	55                   	push   %ebp
   12625:	89 e5                	mov    %esp,%ebp
   12627:	53                   	push   %ebx
   12628:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register uint8_t *bp = buf;
   1262b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   1262e:	eb 0b                	jmp    1263b <memset+0x17>
		*bp++ = value;
   12630:	89 d8                	mov    %ebx,%eax
   12632:	8d 58 01             	lea    0x1(%eax),%ebx
   12635:	0f b6 55 10          	movzbl 0x10(%ebp),%edx
   12639:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   1263b:	89 c8                	mov    %ecx,%eax
   1263d:	8d 48 ff             	lea    -0x1(%eax),%ecx
   12640:	85 c0                	test   %eax,%eax
   12642:	75 ec                	jne    12630 <memset+0xc>
	}
}
   12644:	90                   	nop
   12645:	5b                   	pop    %ebx
   12646:	5d                   	pop    %ebp
   12647:	c3                   	ret    

00012648 <pad>:
**
** @return Pointer to the first byte after the padding
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *pad( char *dst, int extra, int padchar ) {
   12648:	55                   	push   %ebp
   12649:	89 e5                	mov    %esp,%ebp
	while( extra > 0 ){
   1264b:	eb 12                	jmp    1265f <pad+0x17>
		*dst++ = (char) padchar;
   1264d:	8b 45 08             	mov    0x8(%ebp),%eax
   12650:	8d 50 01             	lea    0x1(%eax),%edx
   12653:	89 55 08             	mov    %edx,0x8(%ebp)
   12656:	8b 55 10             	mov    0x10(%ebp),%edx
   12659:	88 10                	mov    %dl,(%eax)
		extra -= 1;
   1265b:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
	while( extra > 0 ){
   1265f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   12663:	7f e8                	jg     1264d <pad+0x5>
	}
	return dst;
   12665:	8b 45 08             	mov    0x8(%ebp),%eax
}
   12668:	5d                   	pop    %ebp
   12669:	c3                   	ret    

0001266a <padstr>:
** @return Pointer to the first byte after the padded string
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *padstr( char *dst, char *str, int len, int width,
				int leftadjust, int padchar ) {
   1266a:	55                   	push   %ebp
   1266b:	89 e5                	mov    %esp,%ebp
   1266d:	83 ec 18             	sub    $0x18,%esp
	int extra;

	// determine the length of the string if we need to
	if( len < 0 ){
   12670:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
   12674:	79 11                	jns    12687 <padstr+0x1d>
		len = strlen( str );
   12676:	83 ec 0c             	sub    $0xc,%esp
   12679:	ff 75 0c             	pushl  0xc(%ebp)
   1267c:	e8 03 04 00 00       	call   12a84 <strlen>
   12681:	83 c4 10             	add    $0x10,%esp
   12684:	89 45 10             	mov    %eax,0x10(%ebp)
	}

	// how much filler must we add?
	extra = width - len;
   12687:	8b 45 14             	mov    0x14(%ebp),%eax
   1268a:	2b 45 10             	sub    0x10(%ebp),%eax
   1268d:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// add filler on the left if we're not left-justifying
	if( extra > 0 && !leftadjust ){
   12690:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12694:	7e 1d                	jle    126b3 <padstr+0x49>
   12696:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   1269a:	75 17                	jne    126b3 <padstr+0x49>
		dst = pad( dst, extra, padchar );
   1269c:	83 ec 04             	sub    $0x4,%esp
   1269f:	ff 75 1c             	pushl  0x1c(%ebp)
   126a2:	ff 75 f0             	pushl  -0x10(%ebp)
   126a5:	ff 75 08             	pushl  0x8(%ebp)
   126a8:	e8 9b ff ff ff       	call   12648 <pad>
   126ad:	83 c4 10             	add    $0x10,%esp
   126b0:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	// copy the string itself
	for( int i = 0; i < len; ++i ) {
   126b3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   126ba:	eb 1b                	jmp    126d7 <padstr+0x6d>
		*dst++ = str[i];
   126bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
   126bf:	8b 45 0c             	mov    0xc(%ebp),%eax
   126c2:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
   126c5:	8b 45 08             	mov    0x8(%ebp),%eax
   126c8:	8d 50 01             	lea    0x1(%eax),%edx
   126cb:	89 55 08             	mov    %edx,0x8(%ebp)
   126ce:	0f b6 11             	movzbl (%ecx),%edx
   126d1:	88 10                	mov    %dl,(%eax)
	for( int i = 0; i < len; ++i ) {
   126d3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   126d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
   126da:	3b 45 10             	cmp    0x10(%ebp),%eax
   126dd:	7c dd                	jl     126bc <padstr+0x52>
	}

	// add filler on the right if we are left-justifying
	if( extra > 0 && leftadjust ){
   126df:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   126e3:	7e 1d                	jle    12702 <padstr+0x98>
   126e5:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   126e9:	74 17                	je     12702 <padstr+0x98>
		dst = pad( dst, extra, padchar );
   126eb:	83 ec 04             	sub    $0x4,%esp
   126ee:	ff 75 1c             	pushl  0x1c(%ebp)
   126f1:	ff 75 f0             	pushl  -0x10(%ebp)
   126f4:	ff 75 08             	pushl  0x8(%ebp)
   126f7:	e8 4c ff ff ff       	call   12648 <pad>
   126fc:	83 c4 10             	add    $0x10,%esp
   126ff:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	return dst;
   12702:	8b 45 08             	mov    0x8(%ebp),%eax
}
   12705:	c9                   	leave  
   12706:	c3                   	ret    

00012707 <sprint>:
**
** NOTE:  relies heavily on the x86 parameter passing convention
** (parameters are pushed onto the stack in reverse order as
** 32-bit values).
*/
void sprint( char *dst, char *fmt, ... ) {
   12707:	55                   	push   %ebp
   12708:	89 e5                	mov    %esp,%ebp
   1270a:	83 ec 38             	sub    $0x38,%esp
	** to point to the next "thing", and interpret it according
	** to the format string.
	*/
	
	// get the pointer to the first "value" parameter
	ap = (int *)(&fmt) + 1;
   1270d:	8d 45 0c             	lea    0xc(%ebp),%eax
   12710:	83 c0 04             	add    $0x4,%eax
   12713:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// iterate through the format string
	while( (ch = *fmt++) != '\0' ){
   12716:	e9 3f 02 00 00       	jmp    1295a <sprint+0x253>
		/*
		** Is it the start of a format code?
		*/
		if( ch == '%' ){
   1271b:	80 7d f3 25          	cmpb   $0x25,-0xd(%ebp)
   1271f:	0f 85 26 02 00 00    	jne    1294b <sprint+0x244>
			/*
			** Yes, get the padding and width options (if there).
			** Alignment must come at the beginning, then fill,
			** then width.
			*/
			leftadjust = 0;
   12725:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
			padchar = ' ';
   1272c:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
			width = 0;
   12733:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
			ch = *fmt++;
   1273a:	8b 45 0c             	mov    0xc(%ebp),%eax
   1273d:	8d 50 01             	lea    0x1(%eax),%edx
   12740:	89 55 0c             	mov    %edx,0xc(%ebp)
   12743:	0f b6 00             	movzbl (%eax),%eax
   12746:	88 45 f3             	mov    %al,-0xd(%ebp)
			if( ch == '-' ){
   12749:	80 7d f3 2d          	cmpb   $0x2d,-0xd(%ebp)
   1274d:	75 16                	jne    12765 <sprint+0x5e>
				leftadjust = 1;
   1274f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
				ch = *fmt++;
   12756:	8b 45 0c             	mov    0xc(%ebp),%eax
   12759:	8d 50 01             	lea    0x1(%eax),%edx
   1275c:	89 55 0c             	mov    %edx,0xc(%ebp)
   1275f:	0f b6 00             	movzbl (%eax),%eax
   12762:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			if( ch == '0' ){
   12765:	80 7d f3 30          	cmpb   $0x30,-0xd(%ebp)
   12769:	75 40                	jne    127ab <sprint+0xa4>
				padchar = '0';
   1276b:	c7 45 e4 30 00 00 00 	movl   $0x30,-0x1c(%ebp)
				ch = *fmt++;
   12772:	8b 45 0c             	mov    0xc(%ebp),%eax
   12775:	8d 50 01             	lea    0x1(%eax),%edx
   12778:	89 55 0c             	mov    %edx,0xc(%ebp)
   1277b:	0f b6 00             	movzbl (%eax),%eax
   1277e:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			while( ch >= '0' && ch <= '9' ){
   12781:	eb 28                	jmp    127ab <sprint+0xa4>
				width *= 10;
   12783:	8b 55 e8             	mov    -0x18(%ebp),%edx
   12786:	89 d0                	mov    %edx,%eax
   12788:	c1 e0 02             	shl    $0x2,%eax
   1278b:	01 d0                	add    %edx,%eax
   1278d:	01 c0                	add    %eax,%eax
   1278f:	89 45 e8             	mov    %eax,-0x18(%ebp)
				width += ch - '0';
   12792:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   12796:	83 e8 30             	sub    $0x30,%eax
   12799:	01 45 e8             	add    %eax,-0x18(%ebp)
				ch = *fmt++;
   1279c:	8b 45 0c             	mov    0xc(%ebp),%eax
   1279f:	8d 50 01             	lea    0x1(%eax),%edx
   127a2:	89 55 0c             	mov    %edx,0xc(%ebp)
   127a5:	0f b6 00             	movzbl (%eax),%eax
   127a8:	88 45 f3             	mov    %al,-0xd(%ebp)
			while( ch >= '0' && ch <= '9' ){
   127ab:	80 7d f3 2f          	cmpb   $0x2f,-0xd(%ebp)
   127af:	7e 06                	jle    127b7 <sprint+0xb0>
   127b1:	80 7d f3 39          	cmpb   $0x39,-0xd(%ebp)
   127b5:	7e cc                	jle    12783 <sprint+0x7c>
			}

			/*
			** What data type do we have?
			*/
			switch( ch ) {
   127b7:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   127bb:	83 e8 63             	sub    $0x63,%eax
   127be:	83 f8 15             	cmp    $0x15,%eax
   127c1:	0f 87 93 01 00 00    	ja     1295a <sprint+0x253>
   127c7:	8b 04 85 88 ae 01 00 	mov    0x1ae88(,%eax,4),%eax
   127ce:	ff e0                	jmp    *%eax

			case 'c':  // characters are passed as 32-bit values
				ch = *ap++;
   127d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
   127d3:	8d 50 04             	lea    0x4(%eax),%edx
   127d6:	89 55 f4             	mov    %edx,-0xc(%ebp)
   127d9:	8b 00                	mov    (%eax),%eax
   127db:	88 45 f3             	mov    %al,-0xd(%ebp)
				buf[ 0 ] = ch;
   127de:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   127e2:	88 45 d0             	mov    %al,-0x30(%ebp)
				buf[ 1 ] = '\0';
   127e5:	c6 45 d1 00          	movb   $0x0,-0x2f(%ebp)
				dst = padstr( dst, buf, 1, width, leftadjust, padchar );
   127e9:	83 ec 08             	sub    $0x8,%esp
   127ec:	ff 75 e4             	pushl  -0x1c(%ebp)
   127ef:	ff 75 ec             	pushl  -0x14(%ebp)
   127f2:	ff 75 e8             	pushl  -0x18(%ebp)
   127f5:	6a 01                	push   $0x1
   127f7:	8d 45 d0             	lea    -0x30(%ebp),%eax
   127fa:	50                   	push   %eax
   127fb:	ff 75 08             	pushl  0x8(%ebp)
   127fe:	e8 67 fe ff ff       	call   1266a <padstr>
   12803:	83 c4 20             	add    $0x20,%esp
   12806:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   12809:	e9 4c 01 00 00       	jmp    1295a <sprint+0x253>

			case 'd':
				len = cvtdec( buf, *ap++ );
   1280e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12811:	8d 50 04             	lea    0x4(%eax),%edx
   12814:	89 55 f4             	mov    %edx,-0xc(%ebp)
   12817:	8b 00                	mov    (%eax),%eax
   12819:	83 ec 08             	sub    $0x8,%esp
   1281c:	50                   	push   %eax
   1281d:	8d 45 d0             	lea    -0x30(%ebp),%eax
   12820:	50                   	push   %eax
   12821:	e8 ee f8 ff ff       	call   12114 <cvtdec>
   12826:	83 c4 10             	add    $0x10,%esp
   12829:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   1282c:	83 ec 08             	sub    $0x8,%esp
   1282f:	ff 75 e4             	pushl  -0x1c(%ebp)
   12832:	ff 75 ec             	pushl  -0x14(%ebp)
   12835:	ff 75 e8             	pushl  -0x18(%ebp)
   12838:	ff 75 e0             	pushl  -0x20(%ebp)
   1283b:	8d 45 d0             	lea    -0x30(%ebp),%eax
   1283e:	50                   	push   %eax
   1283f:	ff 75 08             	pushl  0x8(%ebp)
   12842:	e8 23 fe ff ff       	call   1266a <padstr>
   12847:	83 c4 20             	add    $0x20,%esp
   1284a:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   1284d:	e9 08 01 00 00       	jmp    1295a <sprint+0x253>

			case 's':
				str = (char *) (*ap++);
   12852:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12855:	8d 50 04             	lea    0x4(%eax),%edx
   12858:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1285b:	8b 00                	mov    (%eax),%eax
   1285d:	89 45 dc             	mov    %eax,-0x24(%ebp)
				dst = padstr( dst, str, -1, width, leftadjust, padchar );
   12860:	83 ec 08             	sub    $0x8,%esp
   12863:	ff 75 e4             	pushl  -0x1c(%ebp)
   12866:	ff 75 ec             	pushl  -0x14(%ebp)
   12869:	ff 75 e8             	pushl  -0x18(%ebp)
   1286c:	6a ff                	push   $0xffffffff
   1286e:	ff 75 dc             	pushl  -0x24(%ebp)
   12871:	ff 75 08             	pushl  0x8(%ebp)
   12874:	e8 f1 fd ff ff       	call   1266a <padstr>
   12879:	83 c4 20             	add    $0x20,%esp
   1287c:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   1287f:	e9 d6 00 00 00       	jmp    1295a <sprint+0x253>

			case 'x':
				len = cvthex( buf, *ap++ );
   12884:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12887:	8d 50 04             	lea    0x4(%eax),%edx
   1288a:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1288d:	8b 00                	mov    (%eax),%eax
   1288f:	83 ec 08             	sub    $0x8,%esp
   12892:	50                   	push   %eax
   12893:	8d 45 d0             	lea    -0x30(%ebp),%eax
   12896:	50                   	push   %eax
   12897:	e8 48 f9 ff ff       	call   121e4 <cvthex>
   1289c:	83 c4 10             	add    $0x10,%esp
   1289f:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   128a2:	83 ec 08             	sub    $0x8,%esp
   128a5:	ff 75 e4             	pushl  -0x1c(%ebp)
   128a8:	ff 75 ec             	pushl  -0x14(%ebp)
   128ab:	ff 75 e8             	pushl  -0x18(%ebp)
   128ae:	ff 75 e0             	pushl  -0x20(%ebp)
   128b1:	8d 45 d0             	lea    -0x30(%ebp),%eax
   128b4:	50                   	push   %eax
   128b5:	ff 75 08             	pushl  0x8(%ebp)
   128b8:	e8 ad fd ff ff       	call   1266a <padstr>
   128bd:	83 c4 20             	add    $0x20,%esp
   128c0:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   128c3:	e9 92 00 00 00       	jmp    1295a <sprint+0x253>

			case 'o':
				len = cvtoct( buf, *ap++ );
   128c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
   128cb:	8d 50 04             	lea    0x4(%eax),%edx
   128ce:	89 55 f4             	mov    %edx,-0xc(%ebp)
   128d1:	8b 00                	mov    (%eax),%eax
   128d3:	83 ec 08             	sub    $0x8,%esp
   128d6:	50                   	push   %eax
   128d7:	8d 45 d0             	lea    -0x30(%ebp),%eax
   128da:	50                   	push   %eax
   128db:	e8 8e f9 ff ff       	call   1226e <cvtoct>
   128e0:	83 c4 10             	add    $0x10,%esp
   128e3:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   128e6:	83 ec 08             	sub    $0x8,%esp
   128e9:	ff 75 e4             	pushl  -0x1c(%ebp)
   128ec:	ff 75 ec             	pushl  -0x14(%ebp)
   128ef:	ff 75 e8             	pushl  -0x18(%ebp)
   128f2:	ff 75 e0             	pushl  -0x20(%ebp)
   128f5:	8d 45 d0             	lea    -0x30(%ebp),%eax
   128f8:	50                   	push   %eax
   128f9:	ff 75 08             	pushl  0x8(%ebp)
   128fc:	e8 69 fd ff ff       	call   1266a <padstr>
   12901:	83 c4 20             	add    $0x20,%esp
   12904:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   12907:	eb 51                	jmp    1295a <sprint+0x253>

			case 'u':
				len = cvtuns( buf, *ap++ );
   12909:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1290c:	8d 50 04             	lea    0x4(%eax),%edx
   1290f:	89 55 f4             	mov    %edx,-0xc(%ebp)
   12912:	8b 00                	mov    (%eax),%eax
   12914:	83 ec 08             	sub    $0x8,%esp
   12917:	50                   	push   %eax
   12918:	8d 45 d0             	lea    -0x30(%ebp),%eax
   1291b:	50                   	push   %eax
   1291c:	e8 d7 f9 ff ff       	call   122f8 <cvtuns>
   12921:	83 c4 10             	add    $0x10,%esp
   12924:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   12927:	83 ec 08             	sub    $0x8,%esp
   1292a:	ff 75 e4             	pushl  -0x1c(%ebp)
   1292d:	ff 75 ec             	pushl  -0x14(%ebp)
   12930:	ff 75 e8             	pushl  -0x18(%ebp)
   12933:	ff 75 e0             	pushl  -0x20(%ebp)
   12936:	8d 45 d0             	lea    -0x30(%ebp),%eax
   12939:	50                   	push   %eax
   1293a:	ff 75 08             	pushl  0x8(%ebp)
   1293d:	e8 28 fd ff ff       	call   1266a <padstr>
   12942:	83 c4 20             	add    $0x20,%esp
   12945:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   12948:	90                   	nop
   12949:	eb 0f                	jmp    1295a <sprint+0x253>

			}
		} else {
			// no, it's just an ordinary character
			*dst++ = ch;
   1294b:	8b 45 08             	mov    0x8(%ebp),%eax
   1294e:	8d 50 01             	lea    0x1(%eax),%edx
   12951:	89 55 08             	mov    %edx,0x8(%ebp)
   12954:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
   12958:	88 10                	mov    %dl,(%eax)
	while( (ch = *fmt++) != '\0' ){
   1295a:	8b 45 0c             	mov    0xc(%ebp),%eax
   1295d:	8d 50 01             	lea    0x1(%eax),%edx
   12960:	89 55 0c             	mov    %edx,0xc(%ebp)
   12963:	0f b6 00             	movzbl (%eax),%eax
   12966:	88 45 f3             	mov    %al,-0xd(%ebp)
   12969:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   1296d:	0f 85 a8 fd ff ff    	jne    1271b <sprint+0x14>
		}
	}

	// NUL-terminate the result
	*dst = '\0';
   12973:	8b 45 08             	mov    0x8(%ebp),%eax
   12976:	c6 00 00             	movb   $0x0,(%eax)
}
   12979:	90                   	nop
   1297a:	c9                   	leave  
   1297b:	c3                   	ret    

0001297c <str2int>:
** @param str   The string to examine
** @param base  The radix to use in the conversion
**
** @return The converted integer
*/
int str2int( register const char *str, register int base ) {
   1297c:	55                   	push   %ebp
   1297d:	89 e5                	mov    %esp,%ebp
   1297f:	53                   	push   %ebx
   12980:	83 ec 14             	sub    $0x14,%esp
   12983:	8b 45 08             	mov    0x8(%ebp),%eax
   12986:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register int num = 0;
   12989:	bb 00 00 00 00       	mov    $0x0,%ebx
	register char bchar = '9';
   1298e:	c6 45 eb 39          	movb   $0x39,-0x15(%ebp)
	int sign = 1;
   12992:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)

	// check for leading '-'
	if( *str == '-' ) {
   12999:	0f b6 10             	movzbl (%eax),%edx
   1299c:	80 fa 2d             	cmp    $0x2d,%dl
   1299f:	75 0a                	jne    129ab <str2int+0x2f>
		sign = -1;
   129a1:	c7 45 f8 ff ff ff ff 	movl   $0xffffffff,-0x8(%ebp)
		++str;
   129a8:	83 c0 01             	add    $0x1,%eax
	}

	if( base != 10 ) {
   129ab:	83 f9 0a             	cmp    $0xa,%ecx
   129ae:	74 2b                	je     129db <str2int+0x5f>
		bchar = '0' + base - 1;
   129b0:	89 ca                	mov    %ecx,%edx
   129b2:	83 c2 2f             	add    $0x2f,%edx
   129b5:	88 55 eb             	mov    %dl,-0x15(%ebp)
	}

	// iterate through the characters
	while( *str ) {
   129b8:	eb 21                	jmp    129db <str2int+0x5f>
		if( *str < '0' || *str > bchar )
   129ba:	0f b6 10             	movzbl (%eax),%edx
   129bd:	80 fa 2f             	cmp    $0x2f,%dl
   129c0:	7e 20                	jle    129e2 <str2int+0x66>
   129c2:	0f b6 10             	movzbl (%eax),%edx
   129c5:	38 55 eb             	cmp    %dl,-0x15(%ebp)
   129c8:	7c 18                	jl     129e2 <str2int+0x66>
			break;
		num = num * base + *str - '0';
   129ca:	0f af d9             	imul   %ecx,%ebx
   129cd:	0f b6 10             	movzbl (%eax),%edx
   129d0:	0f be d2             	movsbl %dl,%edx
   129d3:	01 da                	add    %ebx,%edx
   129d5:	8d 5a d0             	lea    -0x30(%edx),%ebx
		++str;
   129d8:	83 c0 01             	add    $0x1,%eax
	while( *str ) {
   129db:	0f b6 10             	movzbl (%eax),%edx
   129de:	84 d2                	test   %dl,%dl
   129e0:	75 d8                	jne    129ba <str2int+0x3e>
	}

	// return the converted value
	return( num * sign );
   129e2:	89 d8                	mov    %ebx,%eax
   129e4:	0f af 45 f8          	imul   -0x8(%ebp),%eax
}
   129e8:	83 c4 14             	add    $0x14,%esp
   129eb:	5b                   	pop    %ebx
   129ec:	5d                   	pop    %ebp
   129ed:	c3                   	ret    

000129ee <strcat>:
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the resulting string
*/
char *strcat( register char *dst, register const char *src ) {
   129ee:	55                   	push   %ebp
   129ef:	89 e5                	mov    %esp,%ebp
   129f1:	56                   	push   %esi
   129f2:	53                   	push   %ebx
   129f3:	8b 45 08             	mov    0x8(%ebp),%eax
   129f6:	8b 75 0c             	mov    0xc(%ebp),%esi
	register char *tmp = dst;
   129f9:	89 c3                	mov    %eax,%ebx

	while( *dst )  // find the NUL
   129fb:	eb 03                	jmp    12a00 <strcat+0x12>
		++dst;
   129fd:	83 c0 01             	add    $0x1,%eax
	while( *dst )  // find the NUL
   12a00:	0f b6 10             	movzbl (%eax),%edx
   12a03:	84 d2                	test   %dl,%dl
   12a05:	75 f6                	jne    129fd <strcat+0xf>

	while( (*dst++ = *src++) )  // append the src string
   12a07:	90                   	nop
   12a08:	89 f1                	mov    %esi,%ecx
   12a0a:	8d 71 01             	lea    0x1(%ecx),%esi
   12a0d:	89 c2                	mov    %eax,%edx
   12a0f:	8d 42 01             	lea    0x1(%edx),%eax
   12a12:	0f b6 09             	movzbl (%ecx),%ecx
   12a15:	88 0a                	mov    %cl,(%edx)
   12a17:	0f b6 12             	movzbl (%edx),%edx
   12a1a:	84 d2                	test   %dl,%dl
   12a1c:	75 ea                	jne    12a08 <strcat+0x1a>
		;

	return( tmp );
   12a1e:	89 d8                	mov    %ebx,%eax
}
   12a20:	5b                   	pop    %ebx
   12a21:	5e                   	pop    %esi
   12a22:	5d                   	pop    %ebp
   12a23:	c3                   	ret    

00012a24 <strcmp>:
** @param s1 The first source string
** @param s2 The second source string
**
** @return negative if s1 < s2, zero if equal, and positive if s1 > s2
*/
int strcmp( register const char *s1, register const char *s2 ) {
   12a24:	55                   	push   %ebp
   12a25:	89 e5                	mov    %esp,%ebp
   12a27:	53                   	push   %ebx
   12a28:	8b 45 08             	mov    0x8(%ebp),%eax
   12a2b:	8b 55 0c             	mov    0xc(%ebp),%edx

	while( *s1 != 0 && (*s1 == *s2) )
   12a2e:	eb 06                	jmp    12a36 <strcmp+0x12>
		++s1, ++s2;
   12a30:	83 c0 01             	add    $0x1,%eax
   12a33:	83 c2 01             	add    $0x1,%edx
	while( *s1 != 0 && (*s1 == *s2) )
   12a36:	0f b6 08             	movzbl (%eax),%ecx
   12a39:	84 c9                	test   %cl,%cl
   12a3b:	74 0a                	je     12a47 <strcmp+0x23>
   12a3d:	0f b6 18             	movzbl (%eax),%ebx
   12a40:	0f b6 0a             	movzbl (%edx),%ecx
   12a43:	38 cb                	cmp    %cl,%bl
   12a45:	74 e9                	je     12a30 <strcmp+0xc>

	return( *s1 - *s2 );
   12a47:	0f b6 00             	movzbl (%eax),%eax
   12a4a:	0f be c8             	movsbl %al,%ecx
   12a4d:	0f b6 02             	movzbl (%edx),%eax
   12a50:	0f be c0             	movsbl %al,%eax
   12a53:	29 c1                	sub    %eax,%ecx
   12a55:	89 c8                	mov    %ecx,%eax
}
   12a57:	5b                   	pop    %ebx
   12a58:	5d                   	pop    %ebp
   12a59:	c3                   	ret    

00012a5a <strcpy>:
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the copied string
*/
char *strcpy( register char *dst, register const char *src ) {
   12a5a:	55                   	push   %ebp
   12a5b:	89 e5                	mov    %esp,%ebp
   12a5d:	56                   	push   %esi
   12a5e:	53                   	push   %ebx
   12a5f:	8b 4d 08             	mov    0x8(%ebp),%ecx
   12a62:	8b 75 0c             	mov    0xc(%ebp),%esi
	register char *tmp = dst;
   12a65:	89 cb                	mov    %ecx,%ebx

	while( (*dst++ = *src++) )
   12a67:	90                   	nop
   12a68:	89 f2                	mov    %esi,%edx
   12a6a:	8d 72 01             	lea    0x1(%edx),%esi
   12a6d:	89 c8                	mov    %ecx,%eax
   12a6f:	8d 48 01             	lea    0x1(%eax),%ecx
   12a72:	0f b6 12             	movzbl (%edx),%edx
   12a75:	88 10                	mov    %dl,(%eax)
   12a77:	0f b6 00             	movzbl (%eax),%eax
   12a7a:	84 c0                	test   %al,%al
   12a7c:	75 ea                	jne    12a68 <strcpy+0xe>
		;

	return( tmp );
   12a7e:	89 d8                	mov    %ebx,%eax
}
   12a80:	5b                   	pop    %ebx
   12a81:	5e                   	pop    %esi
   12a82:	5d                   	pop    %ebp
   12a83:	c3                   	ret    

00012a84 <strlen>:
**
** @param str The string to examine
**
** @return The length of the string, or 0
*/
uint32_t strlen( register const char *str ) {
   12a84:	55                   	push   %ebp
   12a85:	89 e5                	mov    %esp,%ebp
   12a87:	53                   	push   %ebx
   12a88:	8b 55 08             	mov    0x8(%ebp),%edx
	register uint32_t len = 0;
   12a8b:	bb 00 00 00 00       	mov    $0x0,%ebx

	while( *str++ ) {
   12a90:	eb 03                	jmp    12a95 <strlen+0x11>
		++len;
   12a92:	83 c3 01             	add    $0x1,%ebx
	while( *str++ ) {
   12a95:	89 d0                	mov    %edx,%eax
   12a97:	8d 50 01             	lea    0x1(%eax),%edx
   12a9a:	0f b6 00             	movzbl (%eax),%eax
   12a9d:	84 c0                	test   %al,%al
   12a9f:	75 f1                	jne    12a92 <strlen+0xe>
	}

	return( len );
   12aa1:	89 d8                	mov    %ebx,%eax
}
   12aa3:	5b                   	pop    %ebx
   12aa4:	5d                   	pop    %ebp
   12aa5:	c3                   	ret    

00012aa6 <add_block>:
** Add a block to the free list
**
** @param base   Base address of the block
** @param length Block length, in bytes
*/
static void add_block( uint32_t base, uint32_t length ) {
   12aa6:	55                   	push   %ebp
   12aa7:	89 e5                	mov    %esp,%ebp
   12aa9:	83 ec 18             	sub    $0x18,%esp

	// don't add it if it isn't at least 4K
	if( length < SZ_PAGE ) {
   12aac:	81 7d 0c ff 0f 00 00 	cmpl   $0xfff,0xc(%ebp)
   12ab3:	0f 86 f4 00 00 00    	jbe    12bad <add_block+0x107>
#if ANY_KMEM
	cio_printf( "  add(%08x,%08x): ", base, length );
#endif

	// only want to add multiples of 4K; check the lower bits
	if( (length & 0xfff) != 0 ) {
   12ab9:	8b 45 0c             	mov    0xc(%ebp),%eax
   12abc:	25 ff 0f 00 00       	and    $0xfff,%eax
   12ac1:	85 c0                	test   %eax,%eax
   12ac3:	74 07                	je     12acc <add_block+0x26>
		// round it down to 4K
		length &= 0xfffff000;
   12ac5:	81 65 0c 00 f0 ff ff 	andl   $0xfffff000,0xc(%ebp)
	cio_printf( " --> base %08x length %08x", base, length );
#endif

	// create the "block"

	Blockinfo *block = (Blockinfo *) base;
   12acc:	8b 45 08             	mov    0x8(%ebp),%eax
   12acf:	89 45 ec             	mov    %eax,-0x14(%ebp)
	block->pages = B2P(length);
   12ad2:	8b 45 0c             	mov    0xc(%ebp),%eax
   12ad5:	c1 e8 0c             	shr    $0xc,%eax
   12ad8:	89 c2                	mov    %eax,%edx
   12ada:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12add:	89 10                	mov    %edx,(%eax)
	block->next = NULL;
   12adf:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12ae2:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	** coalescing adjacent free blocks.
	**
	** Handle the easiest case first.
	*/

	if( free_pages == NULL ) {
   12ae9:	a1 14 e1 01 00       	mov    0x1e114,%eax
   12aee:	85 c0                	test   %eax,%eax
   12af0:	75 17                	jne    12b09 <add_block+0x63>
		free_pages = block;
   12af2:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12af5:	a3 14 e1 01 00       	mov    %eax,0x1e114
		n_pages = block->pages;
   12afa:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12afd:	8b 00                	mov    (%eax),%eax
   12aff:	a3 1c e1 01 00       	mov    %eax,0x1e11c
		return;
   12b04:	e9 a5 00 00 00       	jmp    12bae <add_block+0x108>
	** Find the correct insertion spot.
	*/

	Blockinfo *prev, *curr;

	prev = NULL;
   12b09:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	curr = free_pages;
   12b10:	a1 14 e1 01 00       	mov    0x1e114,%eax
   12b15:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr && curr < block ) {
   12b18:	eb 0f                	jmp    12b29 <add_block+0x83>
		prev = curr;
   12b1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12b1d:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   12b20:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12b23:	8b 40 04             	mov    0x4(%eax),%eax
   12b26:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr && curr < block ) {
   12b29:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12b2d:	74 08                	je     12b37 <add_block+0x91>
   12b2f:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12b32:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   12b35:	72 e3                	jb     12b1a <add_block+0x74>
	}

	// the new block always points to its successor
	block->next = curr;
   12b37:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12b3a:	8b 55 f0             	mov    -0x10(%ebp),%edx
   12b3d:	89 50 04             	mov    %edx,0x4(%eax)
	/*
	** If prev is NULL, we're adding at the front; otherwise,
	** we're adding after some other entry (middle or end).
	*/

	if( prev == NULL ) {
   12b40:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12b44:	75 4b                	jne    12b91 <add_block+0xeb>
		// sanity check - both pointers can't be NULL
		assert( curr );
   12b46:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12b4a:	75 3b                	jne    12b87 <add_block+0xe1>
   12b4c:	83 ec 04             	sub    $0x4,%esp
   12b4f:	68 e0 ae 01 00       	push   $0x1aee0
   12b54:	6a 00                	push   $0x0
   12b56:	68 0d 01 00 00       	push   $0x10d
   12b5b:	68 e5 ae 01 00       	push   $0x1aee5
   12b60:	68 dc af 01 00       	push   $0x1afdc
   12b65:	68 ec ae 01 00       	push   $0x1aeec
   12b6a:	68 00 00 02 00       	push   $0x20000
   12b6f:	e8 93 fb ff ff       	call   12707 <sprint>
   12b74:	83 c4 20             	add    $0x20,%esp
   12b77:	83 ec 0c             	sub    $0xc,%esp
   12b7a:	68 00 00 02 00       	push   $0x20000
   12b7f:	e8 03 f9 ff ff       	call   12487 <kpanic>
   12b84:	83 c4 10             	add    $0x10,%esp
		// add at the beginning
		free_pages = block;
   12b87:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12b8a:	a3 14 e1 01 00       	mov    %eax,0x1e114
   12b8f:	eb 09                	jmp    12b9a <add_block+0xf4>
	} else {
		// inserting in the middle or at the end
		prev->next = block;
   12b91:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12b94:	8b 55 ec             	mov    -0x14(%ebp),%edx
   12b97:	89 50 04             	mov    %edx,0x4(%eax)
	}

	// bump the count of available pages
	n_pages += block->pages;
   12b9a:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12b9d:	8b 10                	mov    (%eax),%edx
   12b9f:	a1 1c e1 01 00       	mov    0x1e11c,%eax
   12ba4:	01 d0                	add    %edx,%eax
   12ba6:	a3 1c e1 01 00       	mov    %eax,0x1e11c
   12bab:	eb 01                	jmp    12bae <add_block+0x108>
		return;
   12bad:	90                   	nop
}
   12bae:	c9                   	leave  
   12baf:	c3                   	ret    

00012bb0 <km_init>:
**
** Dependencies:
**    Must be called before any other init routine that uses
**    dynamic storage is called.
*/
void km_init( void ) {
   12bb0:	55                   	push   %ebp
   12bb1:	89 e5                	mov    %esp,%ebp
   12bb3:	53                   	push   %ebx
   12bb4:	83 ec 34             	sub    $0x34,%esp
	int32_t entries;
	region_t *region;

#if TRACING_INIT
	// announce that we're starting initialization
	cio_puts( " Kmem" );
   12bb7:	83 ec 0c             	sub    $0xc,%esp
   12bba:	68 02 af 01 00       	push   $0x1af02
   12bbf:	e8 e9 e2 ff ff       	call   10ead <cio_puts>
   12bc4:	83 c4 10             	add    $0x10,%esp
#endif

	// initially, nothing in the free lists
	free_slices = NULL;
   12bc7:	c7 05 18 e1 01 00 00 	movl   $0x0,0x1e118
   12bce:	00 00 00 
	free_pages = NULL;
   12bd1:	c7 05 14 e1 01 00 00 	movl   $0x0,0x1e114
   12bd8:	00 00 00 
	n_pages = n_slices = 0;
   12bdb:	c7 05 20 e1 01 00 00 	movl   $0x0,0x1e120
   12be2:	00 00 00 
   12be5:	a1 20 e1 01 00       	mov    0x1e120,%eax
   12bea:	a3 1c e1 01 00       	mov    %eax,0x1e11c
	km_initialized = 0;
   12bef:	c7 05 24 e1 01 00 00 	movl   $0x0,0x1e124
   12bf6:	00 00 00 

	// get the list length
	entries = *((int32_t *) MMAP_ADDR);
   12bf9:	b8 00 2d 00 00       	mov    $0x2d00,%eax
   12bfe:	8b 00                	mov    (%eax),%eax
   12c00:	89 45 dc             	mov    %eax,-0x24(%ebp)
#if KMEM_OR_INIT
	cio_printf( "\nKmem: %d regions\n", entries );
#endif

	// if there are no entries, we have nothing to do!
	if( entries < 1 ) {  // note: entries == -1 could occur!
   12c03:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   12c07:	0f 8e 77 01 00 00    	jle    12d84 <km_init+0x1d4>
		return;
	}

	// iterate through the entries, adding things to the freelist

	region = ((region_t *) (MMAP_ADDR + 4));
   12c0d:	c7 45 f4 04 2d 00 00 	movl   $0x2d04,-0xc(%ebp)

	for( int i = 0; i < entries; ++i, ++region ) {
   12c14:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   12c1b:	e9 4c 01 00 00       	jmp    12d6c <km_init+0x1bc>
		** this to include ACPI "reclaimable" memory.
		*/

		// first, check the ACPI one-bit flags

		if( ((region->acpi) & REGION_IGNORE) == 0 ) {
   12c20:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c23:	8b 40 14             	mov    0x14(%eax),%eax
   12c26:	83 e0 01             	and    $0x1,%eax
   12c29:	85 c0                	test   %eax,%eax
   12c2b:	0f 84 26 01 00 00    	je     12d57 <km_init+0x1a7>
			cio_puts( " IGN\n" );
#endif
			continue;
		}

		if( ((region->acpi) & REGION_NONVOL) != 0 ) {
   12c31:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c34:	8b 40 14             	mov    0x14(%eax),%eax
   12c37:	83 e0 02             	and    $0x2,%eax
   12c3a:	85 c0                	test   %eax,%eax
   12c3c:	0f 85 18 01 00 00    	jne    12d5a <km_init+0x1aa>
			continue;  // we'll ignore this, too
		}

		// next, the region type

		if( (region->type) != REGION_USABLE ) {
   12c42:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c45:	8b 40 10             	mov    0x10(%eax),%eax
   12c48:	83 f8 01             	cmp    $0x1,%eax
   12c4b:	0f 85 0c 01 00 00    	jne    12d5d <km_init+0x1ad>
		** split it, and only use the portion that's within those
		** bounds.
		*/

		// grab the two 64-bit values to simplify things
		uint64_t base   = region->base.all;
   12c51:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c54:	8b 50 04             	mov    0x4(%eax),%edx
   12c57:	8b 00                	mov    (%eax),%eax
   12c59:	89 45 e8             	mov    %eax,-0x18(%ebp)
   12c5c:	89 55 ec             	mov    %edx,-0x14(%ebp)
		uint64_t length = region->length.all;
   12c5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c62:	8b 50 0c             	mov    0xc(%eax),%edx
   12c65:	8b 40 08             	mov    0x8(%eax),%eax
   12c68:	89 45 d0             	mov    %eax,-0x30(%ebp)
   12c6b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		uint64_t endpt  = base + length;
   12c6e:	8b 4d e8             	mov    -0x18(%ebp),%ecx
   12c71:	8b 5d ec             	mov    -0x14(%ebp),%ebx
   12c74:	8b 45 d0             	mov    -0x30(%ebp),%eax
   12c77:	8b 55 d4             	mov    -0x2c(%ebp),%edx
   12c7a:	01 c8                	add    %ecx,%eax
   12c7c:	11 da                	adc    %ebx,%edx
   12c7e:	89 45 e0             	mov    %eax,-0x20(%ebp)
   12c81:	89 55 e4             	mov    %edx,-0x1c(%ebp)

		// see if it's above our arbitrary high cutoff point
		if( base >= KM_HIGH_CUTOFF || endpt >= KM_HIGH_CUTOFF ) {
   12c84:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12c88:	77 24                	ja     12cae <km_init+0xfe>
   12c8a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12c8e:	72 09                	jb     12c99 <km_init+0xe9>
   12c90:	81 7d e8 ff ff ff 3f 	cmpl   $0x3fffffff,-0x18(%ebp)
   12c97:	77 15                	ja     12cae <km_init+0xfe>
   12c99:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12c9d:	72 3a                	jb     12cd9 <km_init+0x129>
   12c9f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12ca3:	77 09                	ja     12cae <km_init+0xfe>
   12ca5:	81 7d e0 ff ff ff 3f 	cmpl   $0x3fffffff,-0x20(%ebp)
   12cac:	76 2b                	jbe    12cd9 <km_init+0x129>

			// is the whole thing too high, or just part?
			if( base > KM_HIGH_CUTOFF ) {
   12cae:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12cb2:	72 17                	jb     12ccb <km_init+0x11b>
   12cb4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12cb8:	0f 87 a2 00 00 00    	ja     12d60 <km_init+0x1b0>
   12cbe:	81 7d e8 00 00 00 40 	cmpl   $0x40000000,-0x18(%ebp)
   12cc5:	0f 87 95 00 00 00    	ja     12d60 <km_init+0x1b0>
#endif
				continue;
			}

			// some of it is usable - fix the end point
			endpt = KM_HIGH_CUTOFF;
   12ccb:	c7 45 e0 00 00 00 40 	movl   $0x40000000,-0x20(%ebp)
   12cd2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		}

		// see if it's below our low cutoff point
		if( base < KM_LOW_CUTOFF || endpt < KM_LOW_CUTOFF ) {
   12cd9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12cdd:	72 24                	jb     12d03 <km_init+0x153>
   12cdf:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12ce3:	77 09                	ja     12cee <km_init+0x13e>
   12ce5:	81 7d e8 ff ff 0f 00 	cmpl   $0xfffff,-0x18(%ebp)
   12cec:	76 15                	jbe    12d03 <km_init+0x153>
   12cee:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12cf2:	77 32                	ja     12d26 <km_init+0x176>
   12cf4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12cf8:	72 09                	jb     12d03 <km_init+0x153>
   12cfa:	81 7d e0 ff ff 0f 00 	cmpl   $0xfffff,-0x20(%ebp)
   12d01:	77 23                	ja     12d26 <km_init+0x176>

			// is the whole thing too low, or just part?
			if( endpt < KM_LOW_CUTOFF ) {
   12d03:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12d07:	77 0f                	ja     12d18 <km_init+0x168>
   12d09:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12d0d:	72 54                	jb     12d63 <km_init+0x1b3>
   12d0f:	81 7d e0 ff ff 0f 00 	cmpl   $0xfffff,-0x20(%ebp)
   12d16:	76 4b                	jbe    12d63 <km_init+0x1b3>
#endif
				continue;
			}

			// some of it is usable - fix the starting point
			base = KM_LOW_CUTOFF;
   12d18:	c7 45 e8 00 00 10 00 	movl   $0x100000,-0x18(%ebp)
   12d1f:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
		}

		// recalculate the length
		length = endpt - base;
   12d26:	8b 45 e0             	mov    -0x20(%ebp),%eax
   12d29:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   12d2c:	2b 45 e8             	sub    -0x18(%ebp),%eax
   12d2f:	1b 55 ec             	sbb    -0x14(%ebp),%edx
   12d32:	89 45 d0             	mov    %eax,-0x30(%ebp)
   12d35:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		cio_puts( " OK\n" );
#endif

		// we survived the gauntlet - add the new block

		uint32_t b32 = base   & ADDR_LOW_HALF;
   12d38:	8b 45 e8             	mov    -0x18(%ebp),%eax
   12d3b:	89 45 cc             	mov    %eax,-0x34(%ebp)
		uint32_t l32 = length & ADDR_LOW_HALF;
   12d3e:	8b 45 d0             	mov    -0x30(%ebp),%eax
   12d41:	89 45 c8             	mov    %eax,-0x38(%ebp)

		add_block( b32, l32 );
   12d44:	83 ec 08             	sub    $0x8,%esp
   12d47:	ff 75 c8             	pushl  -0x38(%ebp)
   12d4a:	ff 75 cc             	pushl  -0x34(%ebp)
   12d4d:	e8 54 fd ff ff       	call   12aa6 <add_block>
   12d52:	83 c4 10             	add    $0x10,%esp
   12d55:	eb 0d                	jmp    12d64 <km_init+0x1b4>
			continue;
   12d57:	90                   	nop
   12d58:	eb 0a                	jmp    12d64 <km_init+0x1b4>
			continue;  // we'll ignore this, too
   12d5a:	90                   	nop
   12d5b:	eb 07                	jmp    12d64 <km_init+0x1b4>
			continue;  // we won't attempt to reclaim ACPI memory (yet)
   12d5d:	90                   	nop
   12d5e:	eb 04                	jmp    12d64 <km_init+0x1b4>
				continue;
   12d60:	90                   	nop
   12d61:	eb 01                	jmp    12d64 <km_init+0x1b4>
				continue;
   12d63:	90                   	nop
	for( int i = 0; i < entries; ++i, ++region ) {
   12d64:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   12d68:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
   12d6c:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12d6f:	3b 45 dc             	cmp    -0x24(%ebp),%eax
   12d72:	0f 8c a8 fe ff ff    	jl     12c20 <km_init+0x70>
	}

	// record the initialization
	km_initialized = 1;
   12d78:	c7 05 24 e1 01 00 01 	movl   $0x1,0x1e124
   12d7f:	00 00 00 
   12d82:	eb 01                	jmp    12d85 <km_init+0x1d5>
		return;
   12d84:	90                   	nop
#if KMEM_OR_INIT
	delay( DELAY_1_SEC );
#endif
}
   12d85:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   12d88:	c9                   	leave  
   12d89:	c3                   	ret    

00012d8a <km_dump>:
/**
** Name:    km_dump
**
** Dump the current contents of the free list to the console
*/
void km_dump( void ) {
   12d8a:	55                   	push   %ebp
   12d8b:	89 e5                	mov    %esp,%ebp
   12d8d:	53                   	push   %ebx
   12d8e:	83 ec 14             	sub    $0x14,%esp
	Blockinfo *block;

	cio_printf( "&free_pages=%08x, &free_slices %08x, %u pages, %u slices\n",
   12d91:	8b 15 20 e1 01 00    	mov    0x1e120,%edx
   12d97:	a1 1c e1 01 00       	mov    0x1e11c,%eax
   12d9c:	bb 18 e1 01 00       	mov    $0x1e118,%ebx
   12da1:	b9 14 e1 01 00       	mov    $0x1e114,%ecx
   12da6:	83 ec 0c             	sub    $0xc,%esp
   12da9:	52                   	push   %edx
   12daa:	50                   	push   %eax
   12dab:	53                   	push   %ebx
   12dac:	51                   	push   %ecx
   12dad:	68 08 af 01 00       	push   $0x1af08
   12db2:	e8 70 e7 ff ff       	call   11527 <cio_printf>
   12db7:	83 c4 20             	add    $0x20,%esp
			(uint32_t) &free_pages, (uint32_t) &free_slices,
			n_pages, n_slices );

	for( block = free_pages; block != NULL; block = block->next ) {
   12dba:	a1 14 e1 01 00       	mov    0x1e114,%eax
   12dbf:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12dc2:	eb 39                	jmp    12dfd <km_dump+0x73>
		cio_printf(
   12dc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12dc7:	8b 50 04             	mov    0x4(%eax),%edx
			"block @ 0x%08x 0x%08x pages (ends at 0x%08x) next @ 0x%08x\n",
				block, block->pages, P2B(block->pages) + (uint32_t) block,
   12dca:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12dcd:	8b 00                	mov    (%eax),%eax
   12dcf:	c1 e0 0c             	shl    $0xc,%eax
   12dd2:	89 c1                	mov    %eax,%ecx
   12dd4:	8b 45 f4             	mov    -0xc(%ebp),%eax
		cio_printf(
   12dd7:	01 c1                	add    %eax,%ecx
   12dd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ddc:	8b 00                	mov    (%eax),%eax
   12dde:	83 ec 0c             	sub    $0xc,%esp
   12de1:	52                   	push   %edx
   12de2:	51                   	push   %ecx
   12de3:	50                   	push   %eax
   12de4:	ff 75 f4             	pushl  -0xc(%ebp)
   12de7:	68 44 af 01 00       	push   $0x1af44
   12dec:	e8 36 e7 ff ff       	call   11527 <cio_printf>
   12df1:	83 c4 20             	add    $0x20,%esp
	for( block = free_pages; block != NULL; block = block->next ) {
   12df4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12df7:	8b 40 04             	mov    0x4(%eax),%eax
   12dfa:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12dfd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12e01:	75 c1                	jne    12dc4 <km_dump+0x3a>
				block->next );
	}

	for( block = free_slices; block != NULL; block = block->next ) {
   12e03:	a1 18 e1 01 00       	mov    0x1e118,%eax
   12e08:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12e0b:	eb 39                	jmp    12e46 <km_dump+0xbc>
		cio_printf(
   12e0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12e10:	8b 50 04             	mov    0x4(%eax),%edx
			"block @ 0x%08x 0x%08x slices (ends at 0x%08x) next @ 0x%08x\n",
				block, block->pages, P2B(block->pages) + (uint32_t) block,
   12e13:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12e16:	8b 00                	mov    (%eax),%eax
   12e18:	c1 e0 0c             	shl    $0xc,%eax
   12e1b:	89 c1                	mov    %eax,%ecx
   12e1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
		cio_printf(
   12e20:	01 c1                	add    %eax,%ecx
   12e22:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12e25:	8b 00                	mov    (%eax),%eax
   12e27:	83 ec 0c             	sub    $0xc,%esp
   12e2a:	52                   	push   %edx
   12e2b:	51                   	push   %ecx
   12e2c:	50                   	push   %eax
   12e2d:	ff 75 f4             	pushl  -0xc(%ebp)
   12e30:	68 80 af 01 00       	push   $0x1af80
   12e35:	e8 ed e6 ff ff       	call   11527 <cio_printf>
   12e3a:	83 c4 20             	add    $0x20,%esp
	for( block = free_slices; block != NULL; block = block->next ) {
   12e3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12e40:	8b 40 04             	mov    0x4(%eax),%eax
   12e43:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12e46:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12e4a:	75 c1                	jne    12e0d <km_dump+0x83>
				block->next );
	}

}
   12e4c:	90                   	nop
   12e4d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   12e50:	c9                   	leave  
   12e51:	c3                   	ret    

00012e52 <km_page_alloc>:
** @param count  Number of contiguous pages desired
**
** @return a pointer to the beginning of the first allocated page,
**         or NULL if no memory is available
*/
void *km_page_alloc( unsigned int count ) {
   12e52:	55                   	push   %ebp
   12e53:	89 e5                	mov    %esp,%ebp
   12e55:	83 ec 28             	sub    $0x28,%esp

	assert( km_initialized );
   12e58:	a1 24 e1 01 00       	mov    0x1e124,%eax
   12e5d:	85 c0                	test   %eax,%eax
   12e5f:	75 3b                	jne    12e9c <km_page_alloc+0x4a>
   12e61:	83 ec 04             	sub    $0x4,%esp
   12e64:	68 bd af 01 00       	push   $0x1afbd
   12e69:	6a 00                	push   $0x0
   12e6b:	68 ee 01 00 00       	push   $0x1ee
   12e70:	68 e5 ae 01 00       	push   $0x1aee5
   12e75:	68 e8 af 01 00       	push   $0x1afe8
   12e7a:	68 ec ae 01 00       	push   $0x1aeec
   12e7f:	68 00 00 02 00       	push   $0x20000
   12e84:	e8 7e f8 ff ff       	call   12707 <sprint>
   12e89:	83 c4 20             	add    $0x20,%esp
   12e8c:	83 ec 0c             	sub    $0xc,%esp
   12e8f:	68 00 00 02 00       	push   $0x20000
   12e94:	e8 ee f5 ff ff       	call   12487 <kpanic>
   12e99:	83 c4 10             	add    $0x10,%esp

	// make sure we actually need to do something!
	if( count < 1 ) {
   12e9c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12ea0:	75 0a                	jne    12eac <km_page_alloc+0x5a>
		return( NULL );
   12ea2:	b8 00 00 00 00       	mov    $0x0,%eax
   12ea7:	e9 a9 00 00 00       	jmp    12f55 <km_page_alloc+0x103>
	/*
	** Look for the first entry that is large enough.
	*/

	// pointer to the current block
	Blockinfo *block = free_pages;
   12eac:	a1 14 e1 01 00       	mov    0x1e114,%eax
   12eb1:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// pointer to where the pointer to the current block is
	Blockinfo **pointer = &free_pages;
   12eb4:	c7 45 f0 14 e1 01 00 	movl   $0x1e114,-0x10(%ebp)

	while( block != NULL && block->pages < count ){
   12ebb:	eb 11                	jmp    12ece <km_page_alloc+0x7c>
		pointer = &block->next;
   12ebd:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ec0:	83 c0 04             	add    $0x4,%eax
   12ec3:	89 45 f0             	mov    %eax,-0x10(%ebp)
		block = *pointer;
   12ec6:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12ec9:	8b 00                	mov    (%eax),%eax
   12ecb:	89 45 f4             	mov    %eax,-0xc(%ebp)
	while( block != NULL && block->pages < count ){
   12ece:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12ed2:	74 0a                	je     12ede <km_page_alloc+0x8c>
   12ed4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ed7:	8b 00                	mov    (%eax),%eax
   12ed9:	39 45 08             	cmp    %eax,0x8(%ebp)
   12edc:	77 df                	ja     12ebd <km_page_alloc+0x6b>
	}

	// did we find a big enough block?
	if( block == NULL ){
   12ede:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12ee2:	75 07                	jne    12eeb <km_page_alloc+0x99>
		// nope!
		return( NULL );
   12ee4:	b8 00 00 00 00       	mov    $0x0,%eax
   12ee9:	eb 6a                	jmp    12f55 <km_page_alloc+0x103>
	}

	// found one!  check the length

	if( block->pages == count ) {
   12eeb:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12eee:	8b 00                	mov    (%eax),%eax
   12ef0:	39 45 08             	cmp    %eax,0x8(%ebp)
   12ef3:	75 0d                	jne    12f02 <km_page_alloc+0xb0>

		// exactly the right size - unlink it from the list

		*pointer = block->next;
   12ef5:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ef8:	8b 50 04             	mov    0x4(%eax),%edx
   12efb:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12efe:	89 10                	mov    %edx,(%eax)
   12f00:	eb 43                	jmp    12f45 <km_page_alloc+0xf3>

		// bigger than we need - carve the amount we need off
		// the beginning of this block

		// remember where this chunk begins
		Blockinfo *chunk = block;
   12f02:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12f05:	89 45 ec             	mov    %eax,-0x14(%ebp)

		// how much space will be left over?
		int excess = block->pages - count;
   12f08:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12f0b:	8b 00                	mov    (%eax),%eax
   12f0d:	2b 45 08             	sub    0x8(%ebp),%eax
   12f10:	89 45 e8             	mov    %eax,-0x18(%ebp)

		// find the start of the new fragment
		Blockinfo *fragment = (Blockinfo *) ( (uint8_t *) block + P2B(count) );
   12f13:	8b 45 08             	mov    0x8(%ebp),%eax
   12f16:	c1 e0 0c             	shl    $0xc,%eax
   12f19:	89 c2                	mov    %eax,%edx
   12f1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12f1e:	01 d0                	add    %edx,%eax
   12f20:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// set the length and link for the new fragment
		fragment->pages = excess;
   12f23:	8b 55 e8             	mov    -0x18(%ebp),%edx
   12f26:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   12f29:	89 10                	mov    %edx,(%eax)
		fragment->next  = block->next;
   12f2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12f2e:	8b 50 04             	mov    0x4(%eax),%edx
   12f31:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   12f34:	89 50 04             	mov    %edx,0x4(%eax)

		// replace this chunk with the fragment
		*pointer = fragment;
   12f37:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12f3a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   12f3d:	89 10                	mov    %edx,(%eax)

		// return this chunk
		block = chunk;
   12f3f:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12f42:	89 45 f4             	mov    %eax,-0xc(%ebp)
	}

	// fix the count of available pages
	n_pages -= count;;
   12f45:	a1 1c e1 01 00       	mov    0x1e11c,%eax
   12f4a:	2b 45 08             	sub    0x8(%ebp),%eax
   12f4d:	a3 1c e1 01 00       	mov    %eax,0x1e11c

	return( block );
   12f52:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   12f55:	c9                   	leave  
   12f56:	c3                   	ret    

00012f57 <km_page_free>:
** CRITICAL NOTE:  multi-page blocks must be freed one page
** at a time OR freed using km_page_free_multi()!
**
** @param block   Pointer to the page to be returned to the free list
*/
void km_page_free( void *block ) {
   12f57:	55                   	push   %ebp
   12f58:	89 e5                	mov    %esp,%ebp
   12f5a:	83 ec 08             	sub    $0x8,%esp

	/*
	** Don't do anything if the address is NULL.
	*/
	if( block == NULL ){
   12f5d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12f61:	74 12                	je     12f75 <km_page_free+0x1e>
		return;
	}

	km_page_free_multi( block, 1 );
   12f63:	83 ec 08             	sub    $0x8,%esp
   12f66:	6a 01                	push   $0x1
   12f68:	ff 75 08             	pushl  0x8(%ebp)
   12f6b:	e8 08 00 00 00       	call   12f78 <km_page_free_multi>
   12f70:	83 c4 10             	add    $0x10,%esp
   12f73:	eb 01                	jmp    12f76 <km_page_free+0x1f>
		return;
   12f75:	90                   	nop
}
   12f76:	c9                   	leave  
   12f77:	c3                   	ret    

00012f78 <km_page_free_multi>:
** accepts a pointer to a multi-page block of memory.
**
** @param block   Pointer to the block to be returned to the free list
** @param count   Number of pages in the block
*/
void km_page_free_multi( void *block, uint32_t count ) {
   12f78:	55                   	push   %ebp
   12f79:	89 e5                	mov    %esp,%ebp
   12f7b:	83 ec 18             	sub    $0x18,%esp
	Blockinfo *used;
	Blockinfo *prev;
	Blockinfo *curr;

	assert( km_initialized );
   12f7e:	a1 24 e1 01 00       	mov    0x1e124,%eax
   12f83:	85 c0                	test   %eax,%eax
   12f85:	75 3b                	jne    12fc2 <km_page_free_multi+0x4a>
   12f87:	83 ec 04             	sub    $0x4,%esp
   12f8a:	68 bd af 01 00       	push   $0x1afbd
   12f8f:	6a 00                	push   $0x0
   12f91:	68 57 02 00 00       	push   $0x257
   12f96:	68 e5 ae 01 00       	push   $0x1aee5
   12f9b:	68 f8 af 01 00       	push   $0x1aff8
   12fa0:	68 ec ae 01 00       	push   $0x1aeec
   12fa5:	68 00 00 02 00       	push   $0x20000
   12faa:	e8 58 f7 ff ff       	call   12707 <sprint>
   12faf:	83 c4 20             	add    $0x20,%esp
   12fb2:	83 ec 0c             	sub    $0xc,%esp
   12fb5:	68 00 00 02 00       	push   $0x20000
   12fba:	e8 c8 f4 ff ff       	call   12487 <kpanic>
   12fbf:	83 c4 10             	add    $0x10,%esp

	/*
	** Don't do anything if the address is NULL.
	*/
	if( block == NULL ){
   12fc2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12fc6:	0f 84 e3 00 00 00    	je     130af <km_page_free_multi+0x137>
		return;
	}

	used = (Blockinfo *) block;
   12fcc:	8b 45 08             	mov    0x8(%ebp),%eax
   12fcf:	89 45 f4             	mov    %eax,-0xc(%ebp)
	used->pages = count;
   12fd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12fd5:	8b 55 0c             	mov    0xc(%ebp),%edx
   12fd8:	89 10                	mov    %edx,(%eax)

	/*
	** Advance through the list until current and previous
	** straddle the place where the new block should be inserted.
	*/
	prev = NULL;
   12fda:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	curr = free_pages;
   12fe1:	a1 14 e1 01 00       	mov    0x1e114,%eax
   12fe6:	89 45 ec             	mov    %eax,-0x14(%ebp)

	while( curr != NULL && curr < used ){
   12fe9:	eb 0f                	jmp    12ffa <km_page_free_multi+0x82>
		prev = curr;
   12feb:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12fee:	89 45 f0             	mov    %eax,-0x10(%ebp)
		curr = curr->next;
   12ff1:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12ff4:	8b 40 04             	mov    0x4(%eax),%eax
   12ff7:	89 45 ec             	mov    %eax,-0x14(%ebp)
	while( curr != NULL && curr < used ){
   12ffa:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12ffe:	74 08                	je     13008 <km_page_free_multi+0x90>
   13000:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13003:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   13006:	72 e3                	jb     12feb <km_page_free_multi+0x73>

	/*
	** If this is not the first block in the resulting list,
	** we may need to merge it with its predecessor.
	*/
	if( prev != NULL ){
   13008:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   1300c:	74 44                	je     13052 <km_page_free_multi+0xda>

		// There is a predecessor.  Check to see if we need to merge.
		if( adjacent( prev, used ) ){
   1300e:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13011:	8b 00                	mov    (%eax),%eax
   13013:	c1 e0 0c             	shl    $0xc,%eax
   13016:	89 c2                	mov    %eax,%edx
   13018:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1301b:	01 d0                	add    %edx,%eax
   1301d:	39 45 f4             	cmp    %eax,-0xc(%ebp)
   13020:	75 19                	jne    1303b <km_page_free_multi+0xc3>

			// yes - merge them
			prev->pages += used->pages;
   13022:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13025:	8b 10                	mov    (%eax),%edx
   13027:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1302a:	8b 00                	mov    (%eax),%eax
   1302c:	01 c2                	add    %eax,%edx
   1302e:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13031:	89 10                	mov    %edx,(%eax)

			// the predecessor becomes the "newly inserted" block,
			// because we still need to check to see if we should
			// merge with the successor
			used = prev;
   13033:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13036:	89 45 f4             	mov    %eax,-0xc(%ebp)
   13039:	eb 2b                	jmp    13066 <km_page_free_multi+0xee>

		} else {

			// Not adjacent - just insert the new block
			// between the predecessor and the successor.
			used->next = prev->next;
   1303b:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1303e:	8b 50 04             	mov    0x4(%eax),%edx
   13041:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13044:	89 50 04             	mov    %edx,0x4(%eax)
			prev->next = used;
   13047:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1304a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1304d:	89 50 04             	mov    %edx,0x4(%eax)
   13050:	eb 14                	jmp    13066 <km_page_free_multi+0xee>
		}

	} else {

		// Yes, it is first.  Update the list pointer to insert it.
		used->next = free_pages;
   13052:	8b 15 14 e1 01 00    	mov    0x1e114,%edx
   13058:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1305b:	89 50 04             	mov    %edx,0x4(%eax)
		free_pages = used;
   1305e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13061:	a3 14 e1 01 00       	mov    %eax,0x1e114

	/*
	** If this is not the last block in the resulting list,
	** we may (also) need to merge it with its successor.
	*/
	if( curr != NULL ){
   13066:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   1306a:	74 31                	je     1309d <km_page_free_multi+0x125>

		// No.  Check to see if it should be merged with the successor.
		if( adjacent( used, curr ) ){
   1306c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1306f:	8b 00                	mov    (%eax),%eax
   13071:	c1 e0 0c             	shl    $0xc,%eax
   13074:	89 c2                	mov    %eax,%edx
   13076:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13079:	01 d0                	add    %edx,%eax
   1307b:	39 45 ec             	cmp    %eax,-0x14(%ebp)
   1307e:	75 1d                	jne    1309d <km_page_free_multi+0x125>

			// Yes, combine them.
			used->next = curr->next;
   13080:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13083:	8b 50 04             	mov    0x4(%eax),%edx
   13086:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13089:	89 50 04             	mov    %edx,0x4(%eax)
			used->pages += curr->pages;
   1308c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1308f:	8b 10                	mov    (%eax),%edx
   13091:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13094:	8b 00                	mov    (%eax),%eax
   13096:	01 c2                	add    %eax,%edx
   13098:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1309b:	89 10                	mov    %edx,(%eax)

		}
	}

	// more in the pool
	n_pages += count;
   1309d:	8b 15 1c e1 01 00    	mov    0x1e11c,%edx
   130a3:	8b 45 0c             	mov    0xc(%ebp),%eax
   130a6:	01 d0                	add    %edx,%eax
   130a8:	a3 1c e1 01 00       	mov    %eax,0x1e11c
   130ad:	eb 01                	jmp    130b0 <km_page_free_multi+0x138>
		return;
   130af:	90                   	nop
}
   130b0:	c9                   	leave  
   130b1:	c3                   	ret    

000130b2 <carve_slices>:
** Name:        carve_slices
**
** Allocate a page and split it into four slices;  If no
**              memory is available, we panic.
*/
static void carve_slices( void ) {
   130b2:	55                   	push   %ebp
   130b3:	89 e5                	mov    %esp,%ebp
   130b5:	83 ec 18             	sub    $0x18,%esp
	void *page;

	// get a page
	page = km_page_alloc( 1 );
   130b8:	83 ec 0c             	sub    $0xc,%esp
   130bb:	6a 01                	push   $0x1
   130bd:	e8 90 fd ff ff       	call   12e52 <km_page_alloc>
   130c2:	83 c4 10             	add    $0x10,%esp
   130c5:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// allocation failure is a show-stopping problem
	assert( page );
   130c8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   130cc:	75 3b                	jne    13109 <carve_slices+0x57>
   130ce:	83 ec 04             	sub    $0x4,%esp
   130d1:	68 cc af 01 00       	push   $0x1afcc
   130d6:	6a 00                	push   $0x0
   130d8:	68 c8 02 00 00       	push   $0x2c8
   130dd:	68 e5 ae 01 00       	push   $0x1aee5
   130e2:	68 0c b0 01 00       	push   $0x1b00c
   130e7:	68 ec ae 01 00       	push   $0x1aeec
   130ec:	68 00 00 02 00       	push   $0x20000
   130f1:	e8 11 f6 ff ff       	call   12707 <sprint>
   130f6:	83 c4 20             	add    $0x20,%esp
   130f9:	83 ec 0c             	sub    $0xc,%esp
   130fc:	68 00 00 02 00       	push   $0x20000
   13101:	e8 81 f3 ff ff       	call   12487 <kpanic>
   13106:	83 c4 10             	add    $0x10,%esp

	// we have the page; create the four slices from it
	uint8_t *ptr = (uint8_t *) page;
   13109:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1310c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	for( int i = 0; i < 4; ++i ) {
   1310f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   13116:	eb 26                	jmp    1313e <carve_slices+0x8c>
		km_slice_free( (void *) ptr );
   13118:	83 ec 0c             	sub    $0xc,%esp
   1311b:	ff 75 f4             	pushl  -0xc(%ebp)
   1311e:	e8 f5 00 00 00       	call   13218 <km_slice_free>
   13123:	83 c4 10             	add    $0x10,%esp
		ptr += SZ_SLICE;
   13126:	81 45 f4 00 04 00 00 	addl   $0x400,-0xc(%ebp)
		++n_slices;
   1312d:	a1 20 e1 01 00       	mov    0x1e120,%eax
   13132:	83 c0 01             	add    $0x1,%eax
   13135:	a3 20 e1 01 00       	mov    %eax,0x1e120
	for( int i = 0; i < 4; ++i ) {
   1313a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   1313e:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
   13142:	7e d4                	jle    13118 <carve_slices+0x66>
	}
}
   13144:	90                   	nop
   13145:	c9                   	leave  
   13146:	c3                   	ret    

00013147 <km_slice_alloc>:
** Dynamically allocates a slice (1/4 of a page).  If no
** memory is available, we panic.
**
** @return a pointer to the allocated slice
*/
void *km_slice_alloc( void ) {
   13147:	55                   	push   %ebp
   13148:	89 e5                	mov    %esp,%ebp
   1314a:	83 ec 18             	sub    $0x18,%esp
	Blockinfo *slice;

	assert( km_initialized );
   1314d:	a1 24 e1 01 00       	mov    0x1e124,%eax
   13152:	85 c0                	test   %eax,%eax
   13154:	75 3b                	jne    13191 <km_slice_alloc+0x4a>
   13156:	83 ec 04             	sub    $0x4,%esp
   13159:	68 bd af 01 00       	push   $0x1afbd
   1315e:	6a 00                	push   $0x0
   13160:	68 de 02 00 00       	push   $0x2de
   13165:	68 e5 ae 01 00       	push   $0x1aee5
   1316a:	68 1c b0 01 00       	push   $0x1b01c
   1316f:	68 ec ae 01 00       	push   $0x1aeec
   13174:	68 00 00 02 00       	push   $0x20000
   13179:	e8 89 f5 ff ff       	call   12707 <sprint>
   1317e:	83 c4 20             	add    $0x20,%esp
   13181:	83 ec 0c             	sub    $0xc,%esp
   13184:	68 00 00 02 00       	push   $0x20000
   13189:	e8 f9 f2 ff ff       	call   12487 <kpanic>
   1318e:	83 c4 10             	add    $0x10,%esp

	// if we are out of slices, create a few more
	if( free_slices == NULL ) {
   13191:	a1 18 e1 01 00       	mov    0x1e118,%eax
   13196:	85 c0                	test   %eax,%eax
   13198:	75 05                	jne    1319f <km_slice_alloc+0x58>
		carve_slices();
   1319a:	e8 13 ff ff ff       	call   130b2 <carve_slices>
	}

	// take the first one from the free list
	slice = free_slices;
   1319f:	a1 18 e1 01 00       	mov    0x1e118,%eax
   131a4:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert( slice != NULL );
   131a7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   131ab:	75 3b                	jne    131e8 <km_slice_alloc+0xa1>
   131ad:	83 ec 04             	sub    $0x4,%esp
   131b0:	68 d1 af 01 00       	push   $0x1afd1
   131b5:	6a 00                	push   $0x0
   131b7:	68 e7 02 00 00       	push   $0x2e7
   131bc:	68 e5 ae 01 00       	push   $0x1aee5
   131c1:	68 1c b0 01 00       	push   $0x1b01c
   131c6:	68 ec ae 01 00       	push   $0x1aeec
   131cb:	68 00 00 02 00       	push   $0x20000
   131d0:	e8 32 f5 ff ff       	call   12707 <sprint>
   131d5:	83 c4 20             	add    $0x20,%esp
   131d8:	83 ec 0c             	sub    $0xc,%esp
   131db:	68 00 00 02 00       	push   $0x20000
   131e0:	e8 a2 f2 ff ff       	call   12487 <kpanic>
   131e5:	83 c4 10             	add    $0x10,%esp
	--n_slices;
   131e8:	a1 20 e1 01 00       	mov    0x1e120,%eax
   131ed:	83 e8 01             	sub    $0x1,%eax
   131f0:	a3 20 e1 01 00       	mov    %eax,0x1e120

	// unlink it
	free_slices = slice->next;
   131f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
   131f8:	8b 40 04             	mov    0x4(%eax),%eax
   131fb:	a3 18 e1 01 00       	mov    %eax,0x1e118

	// make it nice and shiny for the caller
	memclr( (void *) slice, SZ_SLICE );
   13200:	83 ec 08             	sub    $0x8,%esp
   13203:	68 00 04 00 00       	push   $0x400
   13208:	ff 75 f4             	pushl  -0xc(%ebp)
   1320b:	e8 74 f3 ff ff       	call   12584 <memclr>
   13210:	83 c4 10             	add    $0x10,%esp

	return( slice );
   13213:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   13216:	c9                   	leave  
   13217:	c3                   	ret    

00013218 <km_slice_free>:
** We make no attempt to merge slices, as they are independent
** blocks of memory (unlike pages).
**
** @param block  Pointer to the slice (1/4 page) to be freed
*/
void km_slice_free( void *block ) {
   13218:	55                   	push   %ebp
   13219:	89 e5                	mov    %esp,%ebp
   1321b:	83 ec 18             	sub    $0x18,%esp
	Blockinfo *slice = (Blockinfo *) block;
   1321e:	8b 45 08             	mov    0x8(%ebp),%eax
   13221:	89 45 f4             	mov    %eax,-0xc(%ebp)

	assert( km_initialized );
   13224:	a1 24 e1 01 00       	mov    0x1e124,%eax
   13229:	85 c0                	test   %eax,%eax
   1322b:	75 3b                	jne    13268 <km_slice_free+0x50>
   1322d:	83 ec 04             	sub    $0x4,%esp
   13230:	68 bd af 01 00       	push   $0x1afbd
   13235:	6a 00                	push   $0x0
   13237:	68 00 03 00 00       	push   $0x300
   1323c:	68 e5 ae 01 00       	push   $0x1aee5
   13241:	68 2c b0 01 00       	push   $0x1b02c
   13246:	68 ec ae 01 00       	push   $0x1aeec
   1324b:	68 00 00 02 00       	push   $0x20000
   13250:	e8 b2 f4 ff ff       	call   12707 <sprint>
   13255:	83 c4 20             	add    $0x20,%esp
   13258:	83 ec 0c             	sub    $0xc,%esp
   1325b:	68 00 00 02 00       	push   $0x20000
   13260:	e8 22 f2 ff ff       	call   12487 <kpanic>
   13265:	83 c4 10             	add    $0x10,%esp

	// just add it to the front of the free list
	slice->pages = SZ_SLICE;
   13268:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1326b:	c7 00 00 04 00 00    	movl   $0x400,(%eax)
	slice->next = free_slices;
   13271:	8b 15 18 e1 01 00    	mov    0x1e118,%edx
   13277:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1327a:	89 50 04             	mov    %edx,0x4(%eax)
	free_slices = slice;
   1327d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13280:	a3 18 e1 01 00       	mov    %eax,0x1e118
	++n_slices;
   13285:	a1 20 e1 01 00       	mov    0x1e120,%eax
   1328a:	83 c0 01             	add    $0x1,%eax
   1328d:	a3 20 e1 01 00       	mov    %eax,0x1e120
}
   13292:	90                   	nop
   13293:	c9                   	leave  
   13294:	c3                   	ret    

00013295 <list_add>:
** Add the supplied data to the beginning of the specified list.
**
** @param[in,out] list  The address of a list_t variable
** @param[in] data      The data to prepend to the list
*/
void list_add( list_t *list, void *data ) {
   13295:	55                   	push   %ebp
   13296:	89 e5                	mov    %esp,%ebp
   13298:	83 ec 18             	sub    $0x18,%esp

	// sanity checks
	assert1( list != NULL );
   1329b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1329f:	75 38                	jne    132d9 <list_add+0x44>
   132a1:	83 ec 04             	sub    $0x4,%esp
   132a4:	68 3c b0 01 00       	push   $0x1b03c
   132a9:	6a 01                	push   $0x1
   132ab:	6a 23                	push   $0x23
   132ad:	68 46 b0 01 00       	push   $0x1b046
   132b2:	68 70 b0 01 00       	push   $0x1b070
   132b7:	68 4d b0 01 00       	push   $0x1b04d
   132bc:	68 00 00 02 00       	push   $0x20000
   132c1:	e8 41 f4 ff ff       	call   12707 <sprint>
   132c6:	83 c4 20             	add    $0x20,%esp
   132c9:	83 ec 0c             	sub    $0xc,%esp
   132cc:	68 00 00 02 00       	push   $0x20000
   132d1:	e8 b1 f1 ff ff       	call   12487 <kpanic>
   132d6:	83 c4 10             	add    $0x10,%esp
	assert1( data != NULL );
   132d9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   132dd:	75 38                	jne    13317 <list_add+0x82>
   132df:	83 ec 04             	sub    $0x4,%esp
   132e2:	68 63 b0 01 00       	push   $0x1b063
   132e7:	6a 01                	push   $0x1
   132e9:	6a 24                	push   $0x24
   132eb:	68 46 b0 01 00       	push   $0x1b046
   132f0:	68 70 b0 01 00       	push   $0x1b070
   132f5:	68 4d b0 01 00       	push   $0x1b04d
   132fa:	68 00 00 02 00       	push   $0x20000
   132ff:	e8 03 f4 ff ff       	call   12707 <sprint>
   13304:	83 c4 20             	add    $0x20,%esp
   13307:	83 ec 0c             	sub    $0xc,%esp
   1330a:	68 00 00 02 00       	push   $0x20000
   1330f:	e8 73 f1 ff ff       	call   12487 <kpanic>
   13314:	83 c4 10             	add    $0x10,%esp

	list_t *tmp = (list_t *)data;
   13317:	8b 45 0c             	mov    0xc(%ebp),%eax
   1331a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tmp->next = list->next;
   1331d:	8b 45 08             	mov    0x8(%ebp),%eax
   13320:	8b 10                	mov    (%eax),%edx
   13322:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13325:	89 10                	mov    %edx,(%eax)
	list->next = tmp;
   13327:	8b 45 08             	mov    0x8(%ebp),%eax
   1332a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1332d:	89 10                	mov    %edx,(%eax)
}
   1332f:	90                   	nop
   13330:	c9                   	leave  
   13331:	c3                   	ret    

00013332 <list_remove>:
**
** @param[in,out] list  The address of a list_t variable
**
** @return a pointer to the removed data, or NULL if the list was empty
*/
void *list_remove( list_t *list ) {
   13332:	55                   	push   %ebp
   13333:	89 e5                	mov    %esp,%ebp
   13335:	83 ec 18             	sub    $0x18,%esp

	assert1( list != NULL );
   13338:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1333c:	75 38                	jne    13376 <list_remove+0x44>
   1333e:	83 ec 04             	sub    $0x4,%esp
   13341:	68 3c b0 01 00       	push   $0x1b03c
   13346:	6a 01                	push   $0x1
   13348:	6a 36                	push   $0x36
   1334a:	68 46 b0 01 00       	push   $0x1b046
   1334f:	68 7c b0 01 00       	push   $0x1b07c
   13354:	68 4d b0 01 00       	push   $0x1b04d
   13359:	68 00 00 02 00       	push   $0x20000
   1335e:	e8 a4 f3 ff ff       	call   12707 <sprint>
   13363:	83 c4 20             	add    $0x20,%esp
   13366:	83 ec 0c             	sub    $0xc,%esp
   13369:	68 00 00 02 00       	push   $0x20000
   1336e:	e8 14 f1 ff ff       	call   12487 <kpanic>
   13373:	83 c4 10             	add    $0x10,%esp

	list_t *data = list->next;
   13376:	8b 45 08             	mov    0x8(%ebp),%eax
   13379:	8b 00                	mov    (%eax),%eax
   1337b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( data != NULL ) {
   1337e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   13382:	74 13                	je     13397 <list_remove+0x65>
		list->next = data->next;
   13384:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13387:	8b 10                	mov    (%eax),%edx
   13389:	8b 45 08             	mov    0x8(%ebp),%eax
   1338c:	89 10                	mov    %edx,(%eax)
		data->next = NULL;
   1338e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13391:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}

	return (void *)data;
   13397:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   1339a:	c9                   	leave  
   1339b:	c3                   	ret    

0001339c <find_prev_wakeup>:
** @param[in] pcb    The PCB to look for
**
** @return a pointer to the predecessor in the queue, or NULL if
** this PCB would be at the beginning of the queue.
*/
static pcb_t *find_prev_wakeup( pcb_queue_t queue, pcb_t *pcb ) {
   1339c:	55                   	push   %ebp
   1339d:	89 e5                	mov    %esp,%ebp
   1339f:	83 ec 18             	sub    $0x18,%esp

	// sanity checks!
	assert1( queue != NULL );
   133a2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   133a6:	75 3b                	jne    133e3 <find_prev_wakeup+0x47>
   133a8:	83 ec 04             	sub    $0x4,%esp
   133ab:	68 ec b0 01 00       	push   $0x1b0ec
   133b0:	6a 01                	push   $0x1
   133b2:	68 84 00 00 00       	push   $0x84
   133b7:	68 f7 b0 01 00       	push   $0x1b0f7
   133bc:	68 54 b5 01 00       	push   $0x1b554
   133c1:	68 ff b0 01 00       	push   $0x1b0ff
   133c6:	68 00 00 02 00       	push   $0x20000
   133cb:	e8 37 f3 ff ff       	call   12707 <sprint>
   133d0:	83 c4 20             	add    $0x20,%esp
   133d3:	83 ec 0c             	sub    $0xc,%esp
   133d6:	68 00 00 02 00       	push   $0x20000
   133db:	e8 a7 f0 ff ff       	call   12487 <kpanic>
   133e0:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   133e3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   133e7:	75 3b                	jne    13424 <find_prev_wakeup+0x88>
   133e9:	83 ec 04             	sub    $0x4,%esp
   133ec:	68 15 b1 01 00       	push   $0x1b115
   133f1:	6a 01                	push   $0x1
   133f3:	68 85 00 00 00       	push   $0x85
   133f8:	68 f7 b0 01 00       	push   $0x1b0f7
   133fd:	68 54 b5 01 00       	push   $0x1b554
   13402:	68 ff b0 01 00       	push   $0x1b0ff
   13407:	68 00 00 02 00       	push   $0x20000
   1340c:	e8 f6 f2 ff ff       	call   12707 <sprint>
   13411:	83 c4 20             	add    $0x20,%esp
   13414:	83 ec 0c             	sub    $0xc,%esp
   13417:	68 00 00 02 00       	push   $0x20000
   1341c:	e8 66 f0 ff ff       	call   12487 <kpanic>
   13421:	83 c4 10             	add    $0x10,%esp

	pcb_t *prev = NULL;
   13424:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *curr = queue->head;
   1342b:	8b 45 08             	mov    0x8(%ebp),%eax
   1342e:	8b 00                	mov    (%eax),%eax
   13430:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr != NULL && curr->wakeup <= pcb->wakeup ) {
   13433:	eb 0f                	jmp    13444 <find_prev_wakeup+0xa8>
		prev = curr;
   13435:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13438:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   1343b:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1343e:	8b 40 08             	mov    0x8(%eax),%eax
   13441:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr != NULL && curr->wakeup <= pcb->wakeup ) {
   13444:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   13448:	74 10                	je     1345a <find_prev_wakeup+0xbe>
   1344a:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1344d:	8b 50 10             	mov    0x10(%eax),%edx
   13450:	8b 45 0c             	mov    0xc(%ebp),%eax
   13453:	8b 40 10             	mov    0x10(%eax),%eax
   13456:	39 c2                	cmp    %eax,%edx
   13458:	76 db                	jbe    13435 <find_prev_wakeup+0x99>
	}

	return prev;
   1345a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   1345d:	c9                   	leave  
   1345e:	c3                   	ret    

0001345f <find_prev_priority>:

static pcb_t *find_prev_priority( pcb_queue_t queue, pcb_t *pcb ) {
   1345f:	55                   	push   %ebp
   13460:	89 e5                	mov    %esp,%ebp
   13462:	83 ec 18             	sub    $0x18,%esp

	// sanity checks!
	assert1( queue != NULL );
   13465:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13469:	75 3b                	jne    134a6 <find_prev_priority+0x47>
   1346b:	83 ec 04             	sub    $0x4,%esp
   1346e:	68 ec b0 01 00       	push   $0x1b0ec
   13473:	6a 01                	push   $0x1
   13475:	68 95 00 00 00       	push   $0x95
   1347a:	68 f7 b0 01 00       	push   $0x1b0f7
   1347f:	68 68 b5 01 00       	push   $0x1b568
   13484:	68 ff b0 01 00       	push   $0x1b0ff
   13489:	68 00 00 02 00       	push   $0x20000
   1348e:	e8 74 f2 ff ff       	call   12707 <sprint>
   13493:	83 c4 20             	add    $0x20,%esp
   13496:	83 ec 0c             	sub    $0xc,%esp
   13499:	68 00 00 02 00       	push   $0x20000
   1349e:	e8 e4 ef ff ff       	call   12487 <kpanic>
   134a3:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   134a6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   134aa:	75 3b                	jne    134e7 <find_prev_priority+0x88>
   134ac:	83 ec 04             	sub    $0x4,%esp
   134af:	68 15 b1 01 00       	push   $0x1b115
   134b4:	6a 01                	push   $0x1
   134b6:	68 96 00 00 00       	push   $0x96
   134bb:	68 f7 b0 01 00       	push   $0x1b0f7
   134c0:	68 68 b5 01 00       	push   $0x1b568
   134c5:	68 ff b0 01 00       	push   $0x1b0ff
   134ca:	68 00 00 02 00       	push   $0x20000
   134cf:	e8 33 f2 ff ff       	call   12707 <sprint>
   134d4:	83 c4 20             	add    $0x20,%esp
   134d7:	83 ec 0c             	sub    $0xc,%esp
   134da:	68 00 00 02 00       	push   $0x20000
   134df:	e8 a3 ef ff ff       	call   12487 <kpanic>
   134e4:	83 c4 10             	add    $0x10,%esp

	pcb_t *prev = NULL;
   134e7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *curr = queue->head;
   134ee:	8b 45 08             	mov    0x8(%ebp),%eax
   134f1:	8b 00                	mov    (%eax),%eax
   134f3:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr != NULL && curr->priority <= pcb->priority ) {
   134f6:	eb 0f                	jmp    13507 <find_prev_priority+0xa8>
		prev = curr;
   134f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
   134fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   134fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13501:	8b 40 08             	mov    0x8(%eax),%eax
   13504:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr != NULL && curr->priority <= pcb->priority ) {
   13507:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   1350b:	74 10                	je     1351d <find_prev_priority+0xbe>
   1350d:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13510:	8b 50 20             	mov    0x20(%eax),%edx
   13513:	8b 45 0c             	mov    0xc(%ebp),%eax
   13516:	8b 40 20             	mov    0x20(%eax),%eax
   13519:	39 c2                	cmp    %eax,%edx
   1351b:	76 db                	jbe    134f8 <find_prev_priority+0x99>
	}

	return prev;
   1351d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   13520:	c9                   	leave  
   13521:	c3                   	ret    

00013522 <find_prev_pid>:

static pcb_t *find_prev_pid( pcb_queue_t queue, pcb_t *pcb ) {
   13522:	55                   	push   %ebp
   13523:	89 e5                	mov    %esp,%ebp
   13525:	83 ec 18             	sub    $0x18,%esp

	// sanity checks!
	assert1( queue != NULL );
   13528:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1352c:	75 3b                	jne    13569 <find_prev_pid+0x47>
   1352e:	83 ec 04             	sub    $0x4,%esp
   13531:	68 ec b0 01 00       	push   $0x1b0ec
   13536:	6a 01                	push   $0x1
   13538:	68 a6 00 00 00       	push   $0xa6
   1353d:	68 f7 b0 01 00       	push   $0x1b0f7
   13542:	68 7c b5 01 00       	push   $0x1b57c
   13547:	68 ff b0 01 00       	push   $0x1b0ff
   1354c:	68 00 00 02 00       	push   $0x20000
   13551:	e8 b1 f1 ff ff       	call   12707 <sprint>
   13556:	83 c4 20             	add    $0x20,%esp
   13559:	83 ec 0c             	sub    $0xc,%esp
   1355c:	68 00 00 02 00       	push   $0x20000
   13561:	e8 21 ef ff ff       	call   12487 <kpanic>
   13566:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   13569:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   1356d:	75 3b                	jne    135aa <find_prev_pid+0x88>
   1356f:	83 ec 04             	sub    $0x4,%esp
   13572:	68 15 b1 01 00       	push   $0x1b115
   13577:	6a 01                	push   $0x1
   13579:	68 a7 00 00 00       	push   $0xa7
   1357e:	68 f7 b0 01 00       	push   $0x1b0f7
   13583:	68 7c b5 01 00       	push   $0x1b57c
   13588:	68 ff b0 01 00       	push   $0x1b0ff
   1358d:	68 00 00 02 00       	push   $0x20000
   13592:	e8 70 f1 ff ff       	call   12707 <sprint>
   13597:	83 c4 20             	add    $0x20,%esp
   1359a:	83 ec 0c             	sub    $0xc,%esp
   1359d:	68 00 00 02 00       	push   $0x20000
   135a2:	e8 e0 ee ff ff       	call   12487 <kpanic>
   135a7:	83 c4 10             	add    $0x10,%esp

	pcb_t *prev = NULL;
   135aa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *curr = queue->head;
   135b1:	8b 45 08             	mov    0x8(%ebp),%eax
   135b4:	8b 00                	mov    (%eax),%eax
   135b6:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr != NULL && curr->pid <= pcb->pid ) {
   135b9:	eb 0f                	jmp    135ca <find_prev_pid+0xa8>
		prev = curr;
   135bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
   135be:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   135c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
   135c4:	8b 40 08             	mov    0x8(%eax),%eax
   135c7:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr != NULL && curr->pid <= pcb->pid ) {
   135ca:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   135ce:	74 10                	je     135e0 <find_prev_pid+0xbe>
   135d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
   135d3:	8b 50 18             	mov    0x18(%eax),%edx
   135d6:	8b 45 0c             	mov    0xc(%ebp),%eax
   135d9:	8b 40 18             	mov    0x18(%eax),%eax
   135dc:	39 c2                	cmp    %eax,%edx
   135de:	76 db                	jbe    135bb <find_prev_pid+0x99>
	}

	return prev;
   135e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   135e3:	c9                   	leave  
   135e4:	c3                   	ret    

000135e5 <pcb_init>:
/**
** Name:	pcb_init
**
** Initialization for the Process module.
*/
void pcb_init( void ) {
   135e5:	55                   	push   %ebp
   135e6:	89 e5                	mov    %esp,%ebp
   135e8:	83 ec 18             	sub    $0x18,%esp

#if TRACING_INIT
	cio_puts( " Procs" );
   135eb:	83 ec 0c             	sub    $0xc,%esp
   135ee:	68 1e b1 01 00       	push   $0x1b11e
   135f3:	e8 b5 d8 ff ff       	call   10ead <cio_puts>
   135f8:	83 c4 10             	add    $0x10,%esp
#endif

	// there is no current process
	current = NULL;
   135fb:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   13602:	00 00 00 

	// first user PID
	next_pid = FIRST_USER_PID;
   13605:	c7 05 1c 20 02 00 02 	movl   $0x2,0x2201c
   1360c:	00 00 00 

	// set up the external links to the queues
	QINIT( pcb_freelist, O_FIFO );
   1360f:	c7 05 00 20 02 00 28 	movl   $0x1e128,0x22000
   13616:	e1 01 00 
   13619:	a1 00 20 02 00       	mov    0x22000,%eax
   1361e:	83 ec 08             	sub    $0x8,%esp
   13621:	6a 00                	push   $0x0
   13623:	50                   	push   %eax
   13624:	e8 9c 07 00 00       	call   13dc5 <pcb_queue_reset>
   13629:	83 c4 10             	add    $0x10,%esp
   1362c:	85 c0                	test   %eax,%eax
   1362e:	74 3b                	je     1366b <pcb_init+0x86>
   13630:	83 ec 04             	sub    $0x4,%esp
   13633:	68 28 b1 01 00       	push   $0x1b128
   13638:	6a 00                	push   $0x0
   1363a:	68 d1 00 00 00       	push   $0xd1
   1363f:	68 f7 b0 01 00       	push   $0x1b0f7
   13644:	68 8c b5 01 00       	push   $0x1b58c
   13649:	68 ff b0 01 00       	push   $0x1b0ff
   1364e:	68 00 00 02 00       	push   $0x20000
   13653:	e8 af f0 ff ff       	call   12707 <sprint>
   13658:	83 c4 20             	add    $0x20,%esp
   1365b:	83 ec 0c             	sub    $0xc,%esp
   1365e:	68 00 00 02 00       	push   $0x20000
   13663:	e8 1f ee ff ff       	call   12487 <kpanic>
   13668:	83 c4 10             	add    $0x10,%esp
	QINIT( ready, O_PRIO );
   1366b:	c7 05 d0 24 02 00 34 	movl   $0x1e134,0x224d0
   13672:	e1 01 00 
   13675:	a1 d0 24 02 00       	mov    0x224d0,%eax
   1367a:	83 ec 08             	sub    $0x8,%esp
   1367d:	6a 01                	push   $0x1
   1367f:	50                   	push   %eax
   13680:	e8 40 07 00 00       	call   13dc5 <pcb_queue_reset>
   13685:	83 c4 10             	add    $0x10,%esp
   13688:	85 c0                	test   %eax,%eax
   1368a:	74 3b                	je     136c7 <pcb_init+0xe2>
   1368c:	83 ec 04             	sub    $0x4,%esp
   1368f:	68 50 b1 01 00       	push   $0x1b150
   13694:	6a 00                	push   $0x0
   13696:	68 d2 00 00 00       	push   $0xd2
   1369b:	68 f7 b0 01 00       	push   $0x1b0f7
   136a0:	68 8c b5 01 00       	push   $0x1b58c
   136a5:	68 ff b0 01 00       	push   $0x1b0ff
   136aa:	68 00 00 02 00       	push   $0x20000
   136af:	e8 53 f0 ff ff       	call   12707 <sprint>
   136b4:	83 c4 20             	add    $0x20,%esp
   136b7:	83 ec 0c             	sub    $0xc,%esp
   136ba:	68 00 00 02 00       	push   $0x20000
   136bf:	e8 c3 ed ff ff       	call   12487 <kpanic>
   136c4:	83 c4 10             	add    $0x10,%esp
	QINIT( waiting, O_PID );
   136c7:	c7 05 10 20 02 00 40 	movl   $0x1e140,0x22010
   136ce:	e1 01 00 
   136d1:	a1 10 20 02 00       	mov    0x22010,%eax
   136d6:	83 ec 08             	sub    $0x8,%esp
   136d9:	6a 02                	push   $0x2
   136db:	50                   	push   %eax
   136dc:	e8 e4 06 00 00       	call   13dc5 <pcb_queue_reset>
   136e1:	83 c4 10             	add    $0x10,%esp
   136e4:	85 c0                	test   %eax,%eax
   136e6:	74 3b                	je     13723 <pcb_init+0x13e>
   136e8:	83 ec 04             	sub    $0x4,%esp
   136eb:	68 70 b1 01 00       	push   $0x1b170
   136f0:	6a 00                	push   $0x0
   136f2:	68 d3 00 00 00       	push   $0xd3
   136f7:	68 f7 b0 01 00       	push   $0x1b0f7
   136fc:	68 8c b5 01 00       	push   $0x1b58c
   13701:	68 ff b0 01 00       	push   $0x1b0ff
   13706:	68 00 00 02 00       	push   $0x20000
   1370b:	e8 f7 ef ff ff       	call   12707 <sprint>
   13710:	83 c4 20             	add    $0x20,%esp
   13713:	83 ec 0c             	sub    $0xc,%esp
   13716:	68 00 00 02 00       	push   $0x20000
   1371b:	e8 67 ed ff ff       	call   12487 <kpanic>
   13720:	83 c4 10             	add    $0x10,%esp
	QINIT( sleeping, O_WAKEUP );
   13723:	c7 05 08 20 02 00 4c 	movl   $0x1e14c,0x22008
   1372a:	e1 01 00 
   1372d:	a1 08 20 02 00       	mov    0x22008,%eax
   13732:	83 ec 08             	sub    $0x8,%esp
   13735:	6a 03                	push   $0x3
   13737:	50                   	push   %eax
   13738:	e8 88 06 00 00       	call   13dc5 <pcb_queue_reset>
   1373d:	83 c4 10             	add    $0x10,%esp
   13740:	85 c0                	test   %eax,%eax
   13742:	74 3b                	je     1377f <pcb_init+0x19a>
   13744:	83 ec 04             	sub    $0x4,%esp
   13747:	68 94 b1 01 00       	push   $0x1b194
   1374c:	6a 00                	push   $0x0
   1374e:	68 d4 00 00 00       	push   $0xd4
   13753:	68 f7 b0 01 00       	push   $0x1b0f7
   13758:	68 8c b5 01 00       	push   $0x1b58c
   1375d:	68 ff b0 01 00       	push   $0x1b0ff
   13762:	68 00 00 02 00       	push   $0x20000
   13767:	e8 9b ef ff ff       	call   12707 <sprint>
   1376c:	83 c4 20             	add    $0x20,%esp
   1376f:	83 ec 0c             	sub    $0xc,%esp
   13772:	68 00 00 02 00       	push   $0x20000
   13777:	e8 0b ed ff ff       	call   12487 <kpanic>
   1377c:	83 c4 10             	add    $0x10,%esp
	QINIT( zombie, O_PID );
   1377f:	c7 05 18 20 02 00 58 	movl   $0x1e158,0x22018
   13786:	e1 01 00 
   13789:	a1 18 20 02 00       	mov    0x22018,%eax
   1378e:	83 ec 08             	sub    $0x8,%esp
   13791:	6a 02                	push   $0x2
   13793:	50                   	push   %eax
   13794:	e8 2c 06 00 00       	call   13dc5 <pcb_queue_reset>
   13799:	83 c4 10             	add    $0x10,%esp
   1379c:	85 c0                	test   %eax,%eax
   1379e:	74 3b                	je     137db <pcb_init+0x1f6>
   137a0:	83 ec 04             	sub    $0x4,%esp
   137a3:	68 b8 b1 01 00       	push   $0x1b1b8
   137a8:	6a 00                	push   $0x0
   137aa:	68 d5 00 00 00       	push   $0xd5
   137af:	68 f7 b0 01 00       	push   $0x1b0f7
   137b4:	68 8c b5 01 00       	push   $0x1b58c
   137b9:	68 ff b0 01 00       	push   $0x1b0ff
   137be:	68 00 00 02 00       	push   $0x20000
   137c3:	e8 3f ef ff ff       	call   12707 <sprint>
   137c8:	83 c4 20             	add    $0x20,%esp
   137cb:	83 ec 0c             	sub    $0xc,%esp
   137ce:	68 00 00 02 00       	push   $0x20000
   137d3:	e8 af ec ff ff       	call   12487 <kpanic>
   137d8:	83 c4 10             	add    $0x10,%esp
	QINIT( sioread, O_FIFO );
   137db:	c7 05 04 20 02 00 64 	movl   $0x1e164,0x22004
   137e2:	e1 01 00 
   137e5:	a1 04 20 02 00       	mov    0x22004,%eax
   137ea:	83 ec 08             	sub    $0x8,%esp
   137ed:	6a 00                	push   $0x0
   137ef:	50                   	push   %eax
   137f0:	e8 d0 05 00 00       	call   13dc5 <pcb_queue_reset>
   137f5:	83 c4 10             	add    $0x10,%esp
   137f8:	85 c0                	test   %eax,%eax
   137fa:	74 3b                	je     13837 <pcb_init+0x252>
   137fc:	83 ec 04             	sub    $0x4,%esp
   137ff:	68 dc b1 01 00       	push   $0x1b1dc
   13804:	6a 00                	push   $0x0
   13806:	68 d6 00 00 00       	push   $0xd6
   1380b:	68 f7 b0 01 00       	push   $0x1b0f7
   13810:	68 8c b5 01 00       	push   $0x1b58c
   13815:	68 ff b0 01 00       	push   $0x1b0ff
   1381a:	68 00 00 02 00       	push   $0x20000
   1381f:	e8 e3 ee ff ff       	call   12707 <sprint>
   13824:	83 c4 20             	add    $0x20,%esp
   13827:	83 ec 0c             	sub    $0xc,%esp
   1382a:	68 00 00 02 00       	push   $0x20000
   1382f:	e8 53 ec ff ff       	call   12487 <kpanic>
   13834:	83 c4 10             	add    $0x10,%esp
	** so that we dynamically allocate PCBs, this step either
	** won't be required, or could be used to pre-allocate some
	** number of PCB structures for future use.
	*/

	pcb_t *ptr = ptable;
   13837:	c7 45 f4 20 20 02 00 	movl   $0x22020,-0xc(%ebp)
	for( int i = 0; i < N_PROCS; ++i ) {
   1383e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   13845:	eb 16                	jmp    1385d <pcb_init+0x278>
		pcb_free( ptr );
   13847:	83 ec 0c             	sub    $0xc,%esp
   1384a:	ff 75 f4             	pushl  -0xc(%ebp)
   1384d:	e8 8a 00 00 00       	call   138dc <pcb_free>
   13852:	83 c4 10             	add    $0x10,%esp
		++ptr;
   13855:	83 45 f4 30          	addl   $0x30,-0xc(%ebp)
	for( int i = 0; i < N_PROCS; ++i ) {
   13859:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   1385d:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   13861:	7e e4                	jle    13847 <pcb_init+0x262>
	}
}
   13863:	90                   	nop
   13864:	c9                   	leave  
   13865:	c3                   	ret    

00013866 <pcb_alloc>:
**
** @param pcb   Pointer to a pcb_t * where the PCB pointer will be returned.
**
** @return status of the allocation attempt
*/
int pcb_alloc( pcb_t **pcb ) {
   13866:	55                   	push   %ebp
   13867:	89 e5                	mov    %esp,%ebp
   13869:	83 ec 18             	sub    $0x18,%esp

	// sanity check!
	assert1( pcb != NULL );
   1386c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13870:	75 3b                	jne    138ad <pcb_alloc+0x47>
   13872:	83 ec 04             	sub    $0x4,%esp
   13875:	68 15 b1 01 00       	push   $0x1b115
   1387a:	6a 01                	push   $0x1
   1387c:	68 f3 00 00 00       	push   $0xf3
   13881:	68 f7 b0 01 00       	push   $0x1b0f7
   13886:	68 98 b5 01 00       	push   $0x1b598
   1388b:	68 ff b0 01 00       	push   $0x1b0ff
   13890:	68 00 00 02 00       	push   $0x20000
   13895:	e8 6d ee ff ff       	call   12707 <sprint>
   1389a:	83 c4 20             	add    $0x20,%esp
   1389d:	83 ec 0c             	sub    $0xc,%esp
   138a0:	68 00 00 02 00       	push   $0x20000
   138a5:	e8 dd eb ff ff       	call   12487 <kpanic>
   138aa:	83 c4 10             	add    $0x10,%esp

	// remove the first PCB from the free list
	pcb_t *tmp;
	if( pcb_queue_remove(pcb_freelist,&tmp) != SUCCESS ) {
   138ad:	a1 00 20 02 00       	mov    0x22000,%eax
   138b2:	83 ec 08             	sub    $0x8,%esp
   138b5:	8d 55 f4             	lea    -0xc(%ebp),%edx
   138b8:	52                   	push   %edx
   138b9:	50                   	push   %eax
   138ba:	e8 1d 08 00 00       	call   140dc <pcb_queue_remove>
   138bf:	83 c4 10             	add    $0x10,%esp
   138c2:	85 c0                	test   %eax,%eax
   138c4:	74 07                	je     138cd <pcb_alloc+0x67>
		return E_NO_PCBS;
   138c6:	b8 9b ff ff ff       	mov    $0xffffff9b,%eax
   138cb:	eb 0d                	jmp    138da <pcb_alloc+0x74>
	}

	*pcb = tmp;
   138cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
   138d0:	8b 45 08             	mov    0x8(%ebp),%eax
   138d3:	89 10                	mov    %edx,(%eax)
	return SUCCESS;
   138d5:	b8 00 00 00 00       	mov    $0x0,%eax
}
   138da:	c9                   	leave  
   138db:	c3                   	ret    

000138dc <pcb_free>:
**
** Return a PCB to the list of free PCBs.
**
** @param pcb   Pointer to the PCB to be deallocated.
*/
void pcb_free( pcb_t *pcb ) {
   138dc:	55                   	push   %ebp
   138dd:	89 e5                	mov    %esp,%ebp
   138df:	83 ec 18             	sub    $0x18,%esp

	if( pcb != NULL ) {
   138e2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   138e6:	74 7b                	je     13963 <pcb_free+0x87>
		// mark the PCB as available
		pcb->state = STATE_UNUSED;
   138e8:	8b 45 08             	mov    0x8(%ebp),%eax
   138eb:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

		// add it to the free list
		int status = pcb_queue_insert( pcb_freelist, pcb );
   138f2:	a1 00 20 02 00       	mov    0x22000,%eax
   138f7:	83 ec 08             	sub    $0x8,%esp
   138fa:	ff 75 08             	pushl  0x8(%ebp)
   138fd:	50                   	push   %eax
   138fe:	e8 f3 05 00 00       	call   13ef6 <pcb_queue_insert>
   13903:	83 c4 10             	add    $0x10,%esp
   13906:	89 45 f4             	mov    %eax,-0xc(%ebp)

		// if that failed, we're in trouble
		if( status != SUCCESS ) {
   13909:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1390d:	74 54                	je     13963 <pcb_free+0x87>
			sprint( b256, "pcb_free(0x%08x) status %d", (uint32_t) pcb,
   1390f:	8b 45 08             	mov    0x8(%ebp),%eax
   13912:	ff 75 f4             	pushl  -0xc(%ebp)
   13915:	50                   	push   %eax
   13916:	68 fe b1 01 00       	push   $0x1b1fe
   1391b:	68 00 02 02 00       	push   $0x20200
   13920:	e8 e2 ed ff ff       	call   12707 <sprint>
   13925:	83 c4 10             	add    $0x10,%esp
					status );
			PANIC( 0, b256 );
   13928:	83 ec 04             	sub    $0x4,%esp
   1392b:	68 19 b2 01 00       	push   $0x1b219
   13930:	6a 00                	push   $0x0
   13932:	68 13 01 00 00       	push   $0x113
   13937:	68 f7 b0 01 00       	push   $0x1b0f7
   1393c:	68 a4 b5 01 00       	push   $0x1b5a4
   13941:	68 ff b0 01 00       	push   $0x1b0ff
   13946:	68 00 00 02 00       	push   $0x20000
   1394b:	e8 b7 ed ff ff       	call   12707 <sprint>
   13950:	83 c4 20             	add    $0x20,%esp
   13953:	83 ec 0c             	sub    $0xc,%esp
   13956:	68 00 00 02 00       	push   $0x20000
   1395b:	e8 27 eb ff ff       	call   12487 <kpanic>
   13960:	83 c4 10             	add    $0x10,%esp
		}
	}
}
   13963:	90                   	nop
   13964:	c9                   	leave  
   13965:	c3                   	ret    

00013966 <pcb_stack_alloc>:
**
** @param size   Desired size (in pages, or 0 to get the default size
**
** @return pointer to the allocated space, or NULL
*/
uint32_t *pcb_stack_alloc( uint32_t size ) {
   13966:	55                   	push   %ebp
   13967:	89 e5                	mov    %esp,%ebp
   13969:	83 ec 18             	sub    $0x18,%esp

#if TRACING_STACK
	cio_printf( "stack alloc, %u", size );
#endif
	// do we have a desired size?
	if( size == 0 ) {
   1396c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13970:	75 07                	jne    13979 <pcb_stack_alloc+0x13>
		// no, so use the default
		size = N_USTKPAGES;
   13972:	c7 45 08 02 00 00 00 	movl   $0x2,0x8(%ebp)
	}

	uint32_t *ptr = (uint32_t *) km_page_alloc( size );
   13979:	83 ec 0c             	sub    $0xc,%esp
   1397c:	ff 75 08             	pushl  0x8(%ebp)
   1397f:	e8 ce f4 ff ff       	call   12e52 <km_page_alloc>
   13984:	83 c4 10             	add    $0x10,%esp
   13987:	89 45 f4             	mov    %eax,-0xc(%ebp)
#if TRACING_STACK
	cio_printf( " --> %08x\n", (uint32_t) ptr );
#endif
	if( ptr ) {
   1398a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1398e:	74 15                	je     139a5 <pcb_stack_alloc+0x3f>
		// clear out the allocated space
		memclr( ptr, size * SZ_PAGE );
   13990:	8b 45 08             	mov    0x8(%ebp),%eax
   13993:	c1 e0 0c             	shl    $0xc,%eax
   13996:	83 ec 08             	sub    $0x8,%esp
   13999:	50                   	push   %eax
   1399a:	ff 75 f4             	pushl  -0xc(%ebp)
   1399d:	e8 e2 eb ff ff       	call   12584 <memclr>
   139a2:	83 c4 10             	add    $0x10,%esp
	}

	return ptr;
   139a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   139a8:	c9                   	leave  
   139a9:	c3                   	ret    

000139aa <pcb_stack_free>:
** Dellocate space for a stack
**
** @param stk    Pointer to the stack
** @param size   Allocation size (in pages, or 0 for the default size
*/
void pcb_stack_free( uint32_t *stk, uint32_t size ) {
   139aa:	55                   	push   %ebp
   139ab:	89 e5                	mov    %esp,%ebp
   139ad:	83 ec 08             	sub    $0x8,%esp

#if TRACING_STACK
	cio_printf( "stack free, %08x %u\n", (uint32_t) stk, size );
#endif

	assert( stk != NULL );
   139b0:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   139b4:	75 3b                	jne    139f1 <pcb_stack_free+0x47>
   139b6:	83 ec 04             	sub    $0x4,%esp
   139b9:	68 1e b2 01 00       	push   $0x1b21e
   139be:	6a 00                	push   $0x0
   139c0:	68 46 01 00 00       	push   $0x146
   139c5:	68 f7 b0 01 00       	push   $0x1b0f7
   139ca:	68 b0 b5 01 00       	push   $0x1b5b0
   139cf:	68 ff b0 01 00       	push   $0x1b0ff
   139d4:	68 00 00 02 00       	push   $0x20000
   139d9:	e8 29 ed ff ff       	call   12707 <sprint>
   139de:	83 c4 20             	add    $0x20,%esp
   139e1:	83 ec 0c             	sub    $0xc,%esp
   139e4:	68 00 00 02 00       	push   $0x20000
   139e9:	e8 99 ea ff ff       	call   12487 <kpanic>
   139ee:	83 c4 10             	add    $0x10,%esp

	// do we have an alternate size?
	if( size == 0 ) {
   139f1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   139f5:	75 07                	jne    139fe <pcb_stack_free+0x54>
		// no, so use the default
		size = N_USTKPAGES;
   139f7:	c7 45 0c 02 00 00 00 	movl   $0x2,0xc(%ebp)
	}

	// send it back to the pool
	km_page_free_multi( (void *)stk, size );
   139fe:	83 ec 08             	sub    $0x8,%esp
   13a01:	ff 75 0c             	pushl  0xc(%ebp)
   13a04:	ff 75 08             	pushl  0x8(%ebp)
   13a07:	e8 6c f5 ff ff       	call   12f78 <km_page_free_multi>
   13a0c:	83 c4 10             	add    $0x10,%esp
}
   13a0f:	90                   	nop
   13a10:	c9                   	leave  
   13a11:	c3                   	ret    

00013a12 <pcb_zombify>:
** does most of the real work for exit() and kill() calls.
** Is also called from the scheduler and dispatcher.
**
** @param pcb   Pointer to the newly-undead PCB
*/
void pcb_zombify( register pcb_t *victim ) {
   13a12:	55                   	push   %ebp
   13a13:	89 e5                	mov    %esp,%ebp
   13a15:	56                   	push   %esi
   13a16:	53                   	push   %ebx
   13a17:	83 ec 20             	sub    $0x20,%esp
   13a1a:	8b 5d 08             	mov    0x8(%ebp),%ebx

	// should this be an error?
	if( victim == NULL ) {
   13a1d:	85 db                	test   %ebx,%ebx
   13a1f:	0f 84 79 02 00 00    	je     13c9e <pcb_zombify+0x28c>
		return;
	}

	// every process must have a parent, even if it's 'init'
	assert( victim->parent != NULL );
   13a25:	8b 43 0c             	mov    0xc(%ebx),%eax
   13a28:	85 c0                	test   %eax,%eax
   13a2a:	75 3b                	jne    13a67 <pcb_zombify+0x55>
   13a2c:	83 ec 04             	sub    $0x4,%esp
   13a2f:	68 27 b2 01 00       	push   $0x1b227
   13a34:	6a 00                	push   $0x0
   13a36:	68 63 01 00 00       	push   $0x163
   13a3b:	68 f7 b0 01 00       	push   $0x1b0f7
   13a40:	68 c0 b5 01 00       	push   $0x1b5c0
   13a45:	68 ff b0 01 00       	push   $0x1b0ff
   13a4a:	68 00 00 02 00       	push   $0x20000
   13a4f:	e8 b3 ec ff ff       	call   12707 <sprint>
   13a54:	83 c4 20             	add    $0x20,%esp
   13a57:	83 ec 0c             	sub    $0xc,%esp
   13a5a:	68 00 00 02 00       	push   $0x20000
   13a5f:	e8 23 ea ff ff       	call   12487 <kpanic>
   13a64:	83 c4 10             	add    $0x10,%esp
	/*
	** We need to locate the parent of this process.  We also need
	** to reparent any children of this process.  We do these in
	** a single loop.
	*/
	pcb_t *parent = victim->parent;
   13a67:	8b 43 0c             	mov    0xc(%ebx),%eax
   13a6a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	pcb_t *zchild = NULL;
   13a6d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// two PIDs we will look for
	uint_t vicpid = victim->pid;
   13a74:	8b 43 18             	mov    0x18(%ebx),%eax
   13a77:	89 45 e8             	mov    %eax,-0x18(%ebp)

	// speed up access to the process table entries
	register pcb_t *curr = ptable;
   13a7a:	be 20 20 02 00       	mov    $0x22020,%esi

	for( int i = 0; i < N_PROCS; ++i, ++curr ) {
   13a7f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   13a86:	eb 33                	jmp    13abb <pcb_zombify+0xa9>

		// make sure this is a valid entry
		if( curr->state == STATE_UNUSED ) {
   13a88:	8b 46 1c             	mov    0x1c(%esi),%eax
   13a8b:	85 c0                	test   %eax,%eax
   13a8d:	74 21                	je     13ab0 <pcb_zombify+0x9e>
			continue;
		}

		// if this is our parent, just keep going - we continue
		// iterating to find all the children of this process.
		if( curr == parent ) {
   13a8f:	3b 75 ec             	cmp    -0x14(%ebp),%esi
   13a92:	74 1f                	je     13ab3 <pcb_zombify+0xa1>
			continue;
		}

		if( curr->parent == victim ) {
   13a94:	8b 46 0c             	mov    0xc(%esi),%eax
   13a97:	39 c3                	cmp    %eax,%ebx
   13a99:	75 19                	jne    13ab4 <pcb_zombify+0xa2>

			// found a child - reparent it
			curr->parent = init_pcb;
   13a9b:	a1 0c 20 02 00       	mov    0x2200c,%eax
   13aa0:	89 46 0c             	mov    %eax,0xc(%esi)

			// see if this child is already undead
			if( curr->state == STATE_ZOMBIE ) {
   13aa3:	8b 46 1c             	mov    0x1c(%esi),%eax
   13aa6:	83 f8 08             	cmp    $0x8,%eax
   13aa9:	75 09                	jne    13ab4 <pcb_zombify+0xa2>
				// if it's already a zombie, remember it, so we
				// can pass it on to 'init'; also, if there are
				// two or more zombie children, it doesn't matter
				// which one we pick here, as the others will be
				// collected when 'init' loops
				zchild = curr;
   13aab:	89 75 f4             	mov    %esi,-0xc(%ebp)
   13aae:	eb 04                	jmp    13ab4 <pcb_zombify+0xa2>
			continue;
   13ab0:	90                   	nop
   13ab1:	eb 01                	jmp    13ab4 <pcb_zombify+0xa2>
			continue;
   13ab3:	90                   	nop
	for( int i = 0; i < N_PROCS; ++i, ++curr ) {
   13ab4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   13ab8:	83 c6 30             	add    $0x30,%esi
   13abb:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   13abf:	7e c7                	jle    13a88 <pcb_zombify+0x76>
	** existing process itself is cleaned up by init. This will work,
	** because after init cleans up the zombie, it will loop and
	** call waitpid() again, by which time this exiting process will
	** be marked as a zombie.
	*/
	if( zchild != NULL && init_pcb->state == STATE_WAITING ) {
   13ac1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   13ac5:	0f 84 0d 01 00 00    	je     13bd8 <pcb_zombify+0x1c6>
   13acb:	a1 0c 20 02 00       	mov    0x2200c,%eax
   13ad0:	8b 40 1c             	mov    0x1c(%eax),%eax
   13ad3:	83 f8 06             	cmp    $0x6,%eax
   13ad6:	0f 85 fc 00 00 00    	jne    13bd8 <pcb_zombify+0x1c6>

		// dequeue the zombie
		assert( pcb_queue_remove_this(zombie,zchild) == SUCCESS );
   13adc:	a1 18 20 02 00       	mov    0x22018,%eax
   13ae1:	83 ec 08             	sub    $0x8,%esp
   13ae4:	ff 75 f4             	pushl  -0xc(%ebp)
   13ae7:	50                   	push   %eax
   13ae8:	e8 c6 06 00 00       	call   141b3 <pcb_queue_remove_this>
   13aed:	83 c4 10             	add    $0x10,%esp
   13af0:	85 c0                	test   %eax,%eax
   13af2:	74 3b                	je     13b2f <pcb_zombify+0x11d>
   13af4:	83 ec 04             	sub    $0x4,%esp
   13af7:	68 3c b2 01 00       	push   $0x1b23c
   13afc:	6a 00                	push   $0x0
   13afe:	68 a5 01 00 00       	push   $0x1a5
   13b03:	68 f7 b0 01 00       	push   $0x1b0f7
   13b08:	68 c0 b5 01 00       	push   $0x1b5c0
   13b0d:	68 ff b0 01 00       	push   $0x1b0ff
   13b12:	68 00 00 02 00       	push   $0x20000
   13b17:	e8 eb eb ff ff       	call   12707 <sprint>
   13b1c:	83 c4 20             	add    $0x20,%esp
   13b1f:	83 ec 0c             	sub    $0xc,%esp
   13b22:	68 00 00 02 00       	push   $0x20000
   13b27:	e8 5b e9 ff ff       	call   12487 <kpanic>
   13b2c:	83 c4 10             	add    $0x10,%esp

		assert( pcb_queue_remove_this(waiting,init_pcb) == SUCCESS );
   13b2f:	8b 15 0c 20 02 00    	mov    0x2200c,%edx
   13b35:	a1 10 20 02 00       	mov    0x22010,%eax
   13b3a:	83 ec 08             	sub    $0x8,%esp
   13b3d:	52                   	push   %edx
   13b3e:	50                   	push   %eax
   13b3f:	e8 6f 06 00 00       	call   141b3 <pcb_queue_remove_this>
   13b44:	83 c4 10             	add    $0x10,%esp
   13b47:	85 c0                	test   %eax,%eax
   13b49:	74 3b                	je     13b86 <pcb_zombify+0x174>
   13b4b:	83 ec 04             	sub    $0x4,%esp
   13b4e:	68 68 b2 01 00       	push   $0x1b268
   13b53:	6a 00                	push   $0x0
   13b55:	68 a7 01 00 00       	push   $0x1a7
   13b5a:	68 f7 b0 01 00       	push   $0x1b0f7
   13b5f:	68 c0 b5 01 00       	push   $0x1b5c0
   13b64:	68 ff b0 01 00       	push   $0x1b0ff
   13b69:	68 00 00 02 00       	push   $0x20000
   13b6e:	e8 94 eb ff ff       	call   12707 <sprint>
   13b73:	83 c4 20             	add    $0x20,%esp
   13b76:	83 ec 0c             	sub    $0xc,%esp
   13b79:	68 00 00 02 00       	push   $0x20000
   13b7e:	e8 04 e9 ff ff       	call   12487 <kpanic>
   13b83:	83 c4 10             	add    $0x10,%esp

		// intrinsic return value is the PID
		RET(init_pcb) = zchild->pid;
   13b86:	a1 0c 20 02 00       	mov    0x2200c,%eax
   13b8b:	8b 00                	mov    (%eax),%eax
   13b8d:	8b 55 f4             	mov    -0xc(%ebp),%edx
   13b90:	8b 52 18             	mov    0x18(%edx),%edx
   13b93:	89 50 30             	mov    %edx,0x30(%eax)

		// may also want to return the exit status
		int32_t *ptr = (int32_t *) ARG(init_pcb,2);
   13b96:	a1 0c 20 02 00       	mov    0x2200c,%eax
   13b9b:	8b 00                	mov    (%eax),%eax
   13b9d:	83 c0 48             	add    $0x48,%eax
   13ba0:	83 c0 08             	add    $0x8,%eax
   13ba3:	8b 00                	mov    (%eax),%eax
   13ba5:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		if( ptr != NULL ) {
   13ba8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   13bac:	74 0b                	je     13bb9 <pcb_zombify+0x1a7>
			// ** This works in the baseline because we aren't using
			// ** any type of memory protection.  If address space
			// ** separation is implemented, this code will very likely
			// ** STOP WORKING, and will need to be fixed.
			// ********************************************************
			*ptr = zchild->exit_status;
   13bae:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13bb1:	8b 50 14             	mov    0x14(%eax),%edx
   13bb4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   13bb7:	89 10                	mov    %edx,(%eax)
		}

		// all done - schedule 'init', and clean up the zombie
		schedule( init_pcb );
   13bb9:	a1 0c 20 02 00       	mov    0x2200c,%eax
   13bbe:	83 ec 0c             	sub    $0xc,%esp
   13bc1:	50                   	push   %eax
   13bc2:	e8 08 08 00 00       	call   143cf <schedule>
   13bc7:	83 c4 10             	add    $0x10,%esp
		pcb_cleanup( zchild );
   13bca:	83 ec 0c             	sub    $0xc,%esp
   13bcd:	ff 75 f4             	pushl  -0xc(%ebp)
   13bd0:	e8 d1 00 00 00       	call   13ca6 <pcb_cleanup>
   13bd5:	83 c4 10             	add    $0x10,%esp
	** init up to deal with a zombie child of the exiting process,
	** init's status won't be Waiting any more, so we don't have to
	** worry about it being scheduled twice.
	*/

	if( parent->state == STATE_WAITING ) {
   13bd8:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13bdb:	8b 40 1c             	mov    0x1c(%eax),%eax
   13bde:	83 f8 06             	cmp    $0x6,%eax
   13be1:	75 61                	jne    13c44 <pcb_zombify+0x232>

		// verify that the parent is either waiting for this process
		// or is waiting for any of its children
		uint32_t target = ARG(parent,1);
   13be3:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13be6:	8b 00                	mov    (%eax),%eax
   13be8:	83 c0 48             	add    $0x48,%eax
   13beb:	8b 40 04             	mov    0x4(%eax),%eax
   13bee:	89 45 e0             	mov    %eax,-0x20(%ebp)

		if( target == 0 || target == vicpid ) {
   13bf1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   13bf5:	74 08                	je     13bff <pcb_zombify+0x1ed>
   13bf7:	8b 45 e0             	mov    -0x20(%ebp),%eax
   13bfa:	3b 45 e8             	cmp    -0x18(%ebp),%eax
   13bfd:	75 45                	jne    13c44 <pcb_zombify+0x232>

			// the parent is waiting for this child or is waiting
			// for any of its children, so we can wake it up.

			// intrinsic return value is the PID
			RET(parent) = vicpid;
   13bff:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13c02:	8b 00                	mov    (%eax),%eax
   13c04:	8b 55 e8             	mov    -0x18(%ebp),%edx
   13c07:	89 50 30             	mov    %edx,0x30(%eax)

			// may also want to return the exit status
			int32_t *ptr = (int32_t *) ARG(parent,2);
   13c0a:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13c0d:	8b 00                	mov    (%eax),%eax
   13c0f:	83 c0 48             	add    $0x48,%eax
   13c12:	83 c0 08             	add    $0x8,%eax
   13c15:	8b 00                	mov    (%eax),%eax
   13c17:	89 45 dc             	mov    %eax,-0x24(%ebp)

			if( ptr != NULL ) {
   13c1a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   13c1e:	74 08                	je     13c28 <pcb_zombify+0x216>
				// ** This works in the baseline because we aren't using
				// ** any type of memory protection.  If address space
				// ** separation is implemented, this code will very likely
				// ** STOP WORKING, and will need to be fixed.
				// ********************************************************
				*ptr = victim->exit_status;
   13c20:	8b 53 14             	mov    0x14(%ebx),%edx
   13c23:	8b 45 dc             	mov    -0x24(%ebp),%eax
   13c26:	89 10                	mov    %edx,(%eax)
			}

			// all done - schedule the parent, and clean up the zombie
			schedule( parent );
   13c28:	83 ec 0c             	sub    $0xc,%esp
   13c2b:	ff 75 ec             	pushl  -0x14(%ebp)
   13c2e:	e8 9c 07 00 00       	call   143cf <schedule>
   13c33:	83 c4 10             	add    $0x10,%esp
			pcb_cleanup( victim );
   13c36:	83 ec 0c             	sub    $0xc,%esp
   13c39:	53                   	push   %ebx
   13c3a:	e8 67 00 00 00       	call   13ca6 <pcb_cleanup>
   13c3f:	83 c4 10             	add    $0x10,%esp

			return;
   13c42:	eb 5b                	jmp    13c9f <pcb_zombify+0x28d>
	** a state of 'Zombie'.  This simplifies life immensely,
	** because we won't need to dequeue it when it is collected
	** by its parent.
	*/

	victim->state = STATE_ZOMBIE;
   13c44:	c7 43 1c 08 00 00 00 	movl   $0x8,0x1c(%ebx)
	assert( pcb_queue_insert(zombie,victim) == SUCCESS );
   13c4b:	a1 18 20 02 00       	mov    0x22018,%eax
   13c50:	83 ec 08             	sub    $0x8,%esp
   13c53:	53                   	push   %ebx
   13c54:	50                   	push   %eax
   13c55:	e8 9c 02 00 00       	call   13ef6 <pcb_queue_insert>
   13c5a:	83 c4 10             	add    $0x10,%esp
   13c5d:	85 c0                	test   %eax,%eax
   13c5f:	74 3e                	je     13c9f <pcb_zombify+0x28d>
   13c61:	83 ec 04             	sub    $0x4,%esp
   13c64:	68 98 b2 01 00       	push   $0x1b298
   13c69:	6a 00                	push   $0x0
   13c6b:	68 fc 01 00 00       	push   $0x1fc
   13c70:	68 f7 b0 01 00       	push   $0x1b0f7
   13c75:	68 c0 b5 01 00       	push   $0x1b5c0
   13c7a:	68 ff b0 01 00       	push   $0x1b0ff
   13c7f:	68 00 00 02 00       	push   $0x20000
   13c84:	e8 7e ea ff ff       	call   12707 <sprint>
   13c89:	83 c4 20             	add    $0x20,%esp
   13c8c:	83 ec 0c             	sub    $0xc,%esp
   13c8f:	68 00 00 02 00       	push   $0x20000
   13c94:	e8 ee e7 ff ff       	call   12487 <kpanic>
   13c99:	83 c4 10             	add    $0x10,%esp
   13c9c:	eb 01                	jmp    13c9f <pcb_zombify+0x28d>
		return;
   13c9e:	90                   	nop
	/*
	** Note: we don't call _dispatch() here - we leave that for
	** the calling routine, as it's possible we don't need to
	** choose a new current process.
	*/
}
   13c9f:	8d 65 f8             	lea    -0x8(%ebp),%esp
   13ca2:	5b                   	pop    %ebx
   13ca3:	5e                   	pop    %esi
   13ca4:	5d                   	pop    %ebp
   13ca5:	c3                   	ret    

00013ca6 <pcb_cleanup>:
**
** Reclaim a process' data structures
**
** @param pcb   The PCB to reclaim
*/
void pcb_cleanup( pcb_t *pcb ) {
   13ca6:	55                   	push   %ebp
   13ca7:	89 e5                	mov    %esp,%ebp
   13ca9:	83 ec 08             	sub    $0x8,%esp
#if TRACING_PCB
	cio_printf( "** pcb_cleanup(0x%08x)\n", (uint32_t) pcb );
#endif

	// avoid deallocating a NULL pointer
	if( pcb == NULL ) {
   13cac:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13cb0:	74 1e                	je     13cd0 <pcb_cleanup+0x2a>
		// should this be an error?
		return;
	}

	// we need to release all the VM data structures and frames
	user_cleanup( pcb );
   13cb2:	83 ec 0c             	sub    $0xc,%esp
   13cb5:	ff 75 08             	pushl  0x8(%ebp)
   13cb8:	e8 bd 30 00 00       	call   16d7a <user_cleanup>
   13cbd:	83 c4 10             	add    $0x10,%esp

	// release the PCB itself
	pcb_free( pcb );
   13cc0:	83 ec 0c             	sub    $0xc,%esp
   13cc3:	ff 75 08             	pushl  0x8(%ebp)
   13cc6:	e8 11 fc ff ff       	call   138dc <pcb_free>
   13ccb:	83 c4 10             	add    $0x10,%esp
   13cce:	eb 01                	jmp    13cd1 <pcb_cleanup+0x2b>
		return;
   13cd0:	90                   	nop
}
   13cd1:	c9                   	leave  
   13cd2:	c3                   	ret    

00013cd3 <pcb_find_pid>:
**
** @param pid   The PID to be located
**
** @return Pointer to the PCB, or NULL
*/
pcb_t *pcb_find_pid( uint_t pid ) {
   13cd3:	55                   	push   %ebp
   13cd4:	89 e5                	mov    %esp,%ebp
   13cd6:	83 ec 10             	sub    $0x10,%esp

	// must be a valid PID
	if( pid < 1 ) {
   13cd9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13cdd:	75 07                	jne    13ce6 <pcb_find_pid+0x13>
		return NULL;
   13cdf:	b8 00 00 00 00       	mov    $0x0,%eax
   13ce4:	eb 3d                	jmp    13d23 <pcb_find_pid+0x50>
	}

	// scan the process table
	pcb_t *p = ptable;
   13ce6:	c7 45 fc 20 20 02 00 	movl   $0x22020,-0x4(%ebp)

	for( int i = 0; i < N_PROCS; ++i, ++p ) {
   13ced:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
   13cf4:	eb 22                	jmp    13d18 <pcb_find_pid+0x45>
		if( p->pid == pid && p->state != STATE_UNUSED ) {
   13cf6:	8b 45 fc             	mov    -0x4(%ebp),%eax
   13cf9:	8b 40 18             	mov    0x18(%eax),%eax
   13cfc:	39 45 08             	cmp    %eax,0x8(%ebp)
   13cff:	75 0f                	jne    13d10 <pcb_find_pid+0x3d>
   13d01:	8b 45 fc             	mov    -0x4(%ebp),%eax
   13d04:	8b 40 1c             	mov    0x1c(%eax),%eax
   13d07:	85 c0                	test   %eax,%eax
   13d09:	74 05                	je     13d10 <pcb_find_pid+0x3d>
			return p;
   13d0b:	8b 45 fc             	mov    -0x4(%ebp),%eax
   13d0e:	eb 13                	jmp    13d23 <pcb_find_pid+0x50>
	for( int i = 0; i < N_PROCS; ++i, ++p ) {
   13d10:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
   13d14:	83 45 fc 30          	addl   $0x30,-0x4(%ebp)
   13d18:	83 7d f8 18          	cmpl   $0x18,-0x8(%ebp)
   13d1c:	7e d8                	jle    13cf6 <pcb_find_pid+0x23>
		}
	}

	// didn't find it!
	return NULL;
   13d1e:	b8 00 00 00 00       	mov    $0x0,%eax
}
   13d23:	c9                   	leave  
   13d24:	c3                   	ret    

00013d25 <pcb_find_ppid>:
**
** @param pid   The PID to be located
**
** @return Pointer to the PCB, or NULL
*/
pcb_t *pcb_find_ppid( uint_t pid ) {
   13d25:	55                   	push   %ebp
   13d26:	89 e5                	mov    %esp,%ebp
   13d28:	83 ec 18             	sub    $0x18,%esp

	// must be a valid PID
	if( pid < 1 ) {
   13d2b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13d2f:	75 0a                	jne    13d3b <pcb_find_ppid+0x16>
		return NULL;
   13d31:	b8 00 00 00 00       	mov    $0x0,%eax
   13d36:	e9 88 00 00 00       	jmp    13dc3 <pcb_find_ppid+0x9e>
	}

	// scan the process table
	pcb_t *p = ptable;
   13d3b:	c7 45 f4 20 20 02 00 	movl   $0x22020,-0xc(%ebp)

	for( int i = 0; i < N_PROCS; ++i, ++p ) {
   13d42:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   13d49:	eb 6d                	jmp    13db8 <pcb_find_ppid+0x93>
		assert1( p->parent != NULL );
   13d4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13d4e:	8b 40 0c             	mov    0xc(%eax),%eax
   13d51:	85 c0                	test   %eax,%eax
   13d53:	75 3b                	jne    13d90 <pcb_find_ppid+0x6b>
   13d55:	83 ec 04             	sub    $0x4,%esp
   13d58:	68 bf b2 01 00       	push   $0x1b2bf
   13d5d:	6a 01                	push   $0x1
   13d5f:	68 50 02 00 00       	push   $0x250
   13d64:	68 f7 b0 01 00       	push   $0x1b0f7
   13d69:	68 cc b5 01 00       	push   $0x1b5cc
   13d6e:	68 ff b0 01 00       	push   $0x1b0ff
   13d73:	68 00 00 02 00       	push   $0x20000
   13d78:	e8 8a e9 ff ff       	call   12707 <sprint>
   13d7d:	83 c4 20             	add    $0x20,%esp
   13d80:	83 ec 0c             	sub    $0xc,%esp
   13d83:	68 00 00 02 00       	push   $0x20000
   13d88:	e8 fa e6 ff ff       	call   12487 <kpanic>
   13d8d:	83 c4 10             	add    $0x10,%esp
		if( p->parent->pid == pid && p->parent->state != STATE_UNUSED ) {
   13d90:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13d93:	8b 40 0c             	mov    0xc(%eax),%eax
   13d96:	8b 40 18             	mov    0x18(%eax),%eax
   13d99:	39 45 08             	cmp    %eax,0x8(%ebp)
   13d9c:	75 12                	jne    13db0 <pcb_find_ppid+0x8b>
   13d9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13da1:	8b 40 0c             	mov    0xc(%eax),%eax
   13da4:	8b 40 1c             	mov    0x1c(%eax),%eax
   13da7:	85 c0                	test   %eax,%eax
   13da9:	74 05                	je     13db0 <pcb_find_ppid+0x8b>
			return p;
   13dab:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13dae:	eb 13                	jmp    13dc3 <pcb_find_ppid+0x9e>
	for( int i = 0; i < N_PROCS; ++i, ++p ) {
   13db0:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   13db4:	83 45 f4 30          	addl   $0x30,-0xc(%ebp)
   13db8:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   13dbc:	7e 8d                	jle    13d4b <pcb_find_ppid+0x26>
		}
	}

	// didn't find it!
	return NULL;
   13dbe:	b8 00 00 00 00       	mov    $0x0,%eax
}
   13dc3:	c9                   	leave  
   13dc4:	c3                   	ret    

00013dc5 <pcb_queue_reset>:
** @param queue[out]  The queue to be initialized
** @param order[in]   The desired ordering for the queue
**
** @return status of the init request
*/
int pcb_queue_reset( pcb_queue_t queue, enum pcb_queue_order_e style ) {
   13dc5:	55                   	push   %ebp
   13dc6:	89 e5                	mov    %esp,%ebp
   13dc8:	83 ec 08             	sub    $0x8,%esp

	// sanity check
	assert1( queue != NULL );
   13dcb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13dcf:	75 3b                	jne    13e0c <pcb_queue_reset+0x47>
   13dd1:	83 ec 04             	sub    $0x4,%esp
   13dd4:	68 ec b0 01 00       	push   $0x1b0ec
   13dd9:	6a 01                	push   $0x1
   13ddb:	68 68 02 00 00       	push   $0x268
   13de0:	68 f7 b0 01 00       	push   $0x1b0f7
   13de5:	68 dc b5 01 00       	push   $0x1b5dc
   13dea:	68 ff b0 01 00       	push   $0x1b0ff
   13def:	68 00 00 02 00       	push   $0x20000
   13df4:	e8 0e e9 ff ff       	call   12707 <sprint>
   13df9:	83 c4 20             	add    $0x20,%esp
   13dfc:	83 ec 0c             	sub    $0xc,%esp
   13dff:	68 00 00 02 00       	push   $0x20000
   13e04:	e8 7e e6 ff ff       	call   12487 <kpanic>
   13e09:	83 c4 10             	add    $0x10,%esp

	// make sure the style is valid
	if( style < O_FIRST_STYLE || style > O_LAST_STYLE ) {
   13e0c:	83 7d 0c 03          	cmpl   $0x3,0xc(%ebp)
   13e10:	76 07                	jbe    13e19 <pcb_queue_reset+0x54>
		return E_BAD_PARAM;
   13e12:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
   13e17:	eb 23                	jmp    13e3c <pcb_queue_reset+0x77>
	}

	// reset the queue
	queue->head = queue->tail = NULL;
   13e19:	8b 45 08             	mov    0x8(%ebp),%eax
   13e1c:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
   13e23:	8b 45 08             	mov    0x8(%ebp),%eax
   13e26:	8b 50 04             	mov    0x4(%eax),%edx
   13e29:	8b 45 08             	mov    0x8(%ebp),%eax
   13e2c:	89 10                	mov    %edx,(%eax)
	queue->order = style;
   13e2e:	8b 45 08             	mov    0x8(%ebp),%eax
   13e31:	8b 55 0c             	mov    0xc(%ebp),%edx
   13e34:	89 50 08             	mov    %edx,0x8(%eax)

	return SUCCESS;
   13e37:	b8 00 00 00 00       	mov    $0x0,%eax
}
   13e3c:	c9                   	leave  
   13e3d:	c3                   	ret    

00013e3e <pcb_queue_empty>:
**
** @param[in] queue  The queue to check
**
** @return true if the queue is empty, else false
*/
bool_t pcb_queue_empty( pcb_queue_t queue ) {
   13e3e:	55                   	push   %ebp
   13e3f:	89 e5                	mov    %esp,%ebp
   13e41:	83 ec 08             	sub    $0x8,%esp

	// if there is no queue, blow up
	assert1( queue != NULL );
   13e44:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13e48:	75 3b                	jne    13e85 <pcb_queue_empty+0x47>
   13e4a:	83 ec 04             	sub    $0x4,%esp
   13e4d:	68 ec b0 01 00       	push   $0x1b0ec
   13e52:	6a 01                	push   $0x1
   13e54:	68 83 02 00 00       	push   $0x283
   13e59:	68 f7 b0 01 00       	push   $0x1b0f7
   13e5e:	68 ec b5 01 00       	push   $0x1b5ec
   13e63:	68 ff b0 01 00       	push   $0x1b0ff
   13e68:	68 00 00 02 00       	push   $0x20000
   13e6d:	e8 95 e8 ff ff       	call   12707 <sprint>
   13e72:	83 c4 20             	add    $0x20,%esp
   13e75:	83 ec 0c             	sub    $0xc,%esp
   13e78:	68 00 00 02 00       	push   $0x20000
   13e7d:	e8 05 e6 ff ff       	call   12487 <kpanic>
   13e82:	83 c4 10             	add    $0x10,%esp

	return PCB_QUEUE_EMPTY(queue);
   13e85:	8b 45 08             	mov    0x8(%ebp),%eax
   13e88:	8b 00                	mov    (%eax),%eax
   13e8a:	85 c0                	test   %eax,%eax
   13e8c:	0f 94 c0             	sete   %al
}
   13e8f:	c9                   	leave  
   13e90:	c3                   	ret    

00013e91 <pcb_queue_length>:
**
** @param[in] queue  The queue to check
**
** @return the count (0 if the queue is empty)
*/
uint_t pcb_queue_length( const pcb_queue_t queue ) {
   13e91:	55                   	push   %ebp
   13e92:	89 e5                	mov    %esp,%ebp
   13e94:	56                   	push   %esi
   13e95:	53                   	push   %ebx

	// sanity check
	assert1( queue != NULL );
   13e96:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13e9a:	75 3b                	jne    13ed7 <pcb_queue_length+0x46>
   13e9c:	83 ec 04             	sub    $0x4,%esp
   13e9f:	68 ec b0 01 00       	push   $0x1b0ec
   13ea4:	6a 01                	push   $0x1
   13ea6:	68 94 02 00 00       	push   $0x294
   13eab:	68 f7 b0 01 00       	push   $0x1b0f7
   13eb0:	68 fc b5 01 00       	push   $0x1b5fc
   13eb5:	68 ff b0 01 00       	push   $0x1b0ff
   13eba:	68 00 00 02 00       	push   $0x20000
   13ebf:	e8 43 e8 ff ff       	call   12707 <sprint>
   13ec4:	83 c4 20             	add    $0x20,%esp
   13ec7:	83 ec 0c             	sub    $0xc,%esp
   13eca:	68 00 00 02 00       	push   $0x20000
   13ecf:	e8 b3 e5 ff ff       	call   12487 <kpanic>
   13ed4:	83 c4 10             	add    $0x10,%esp

	// this is pretty simple
	register pcb_t *tmp = queue->head;
   13ed7:	8b 45 08             	mov    0x8(%ebp),%eax
   13eda:	8b 18                	mov    (%eax),%ebx
	register int num = 0;
   13edc:	be 00 00 00 00       	mov    $0x0,%esi
	
	while( tmp != NULL ) {
   13ee1:	eb 06                	jmp    13ee9 <pcb_queue_length+0x58>
		++num;
   13ee3:	83 c6 01             	add    $0x1,%esi
		tmp = tmp->next;
   13ee6:	8b 5b 08             	mov    0x8(%ebx),%ebx
	while( tmp != NULL ) {
   13ee9:	85 db                	test   %ebx,%ebx
   13eeb:	75 f6                	jne    13ee3 <pcb_queue_length+0x52>
	}

	return num;
   13eed:	89 f0                	mov    %esi,%eax
}
   13eef:	8d 65 f8             	lea    -0x8(%ebp),%esp
   13ef2:	5b                   	pop    %ebx
   13ef3:	5e                   	pop    %esi
   13ef4:	5d                   	pop    %ebp
   13ef5:	c3                   	ret    

00013ef6 <pcb_queue_insert>:
** @param queue[in,out]  The queue to be used
** @param pcb[in]        The PCB to be inserted
**
** @return status of the insertion request
*/
int pcb_queue_insert( pcb_queue_t queue, pcb_t *pcb ) {
   13ef6:	55                   	push   %ebp
   13ef7:	89 e5                	mov    %esp,%ebp
   13ef9:	83 ec 18             	sub    $0x18,%esp

	// sanity checks
	assert1( queue != NULL );
   13efc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13f00:	75 3b                	jne    13f3d <pcb_queue_insert+0x47>
   13f02:	83 ec 04             	sub    $0x4,%esp
   13f05:	68 ec b0 01 00       	push   $0x1b0ec
   13f0a:	6a 01                	push   $0x1
   13f0c:	68 af 02 00 00       	push   $0x2af
   13f11:	68 f7 b0 01 00       	push   $0x1b0f7
   13f16:	68 10 b6 01 00       	push   $0x1b610
   13f1b:	68 ff b0 01 00       	push   $0x1b0ff
   13f20:	68 00 00 02 00       	push   $0x20000
   13f25:	e8 dd e7 ff ff       	call   12707 <sprint>
   13f2a:	83 c4 20             	add    $0x20,%esp
   13f2d:	83 ec 0c             	sub    $0xc,%esp
   13f30:	68 00 00 02 00       	push   $0x20000
   13f35:	e8 4d e5 ff ff       	call   12487 <kpanic>
   13f3a:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   13f3d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   13f41:	75 3b                	jne    13f7e <pcb_queue_insert+0x88>
   13f43:	83 ec 04             	sub    $0x4,%esp
   13f46:	68 15 b1 01 00       	push   $0x1b115
   13f4b:	6a 01                	push   $0x1
   13f4d:	68 b0 02 00 00       	push   $0x2b0
   13f52:	68 f7 b0 01 00       	push   $0x1b0f7
   13f57:	68 10 b6 01 00       	push   $0x1b610
   13f5c:	68 ff b0 01 00       	push   $0x1b0ff
   13f61:	68 00 00 02 00       	push   $0x20000
   13f66:	e8 9c e7 ff ff       	call   12707 <sprint>
   13f6b:	83 c4 20             	add    $0x20,%esp
   13f6e:	83 ec 0c             	sub    $0xc,%esp
   13f71:	68 00 00 02 00       	push   $0x20000
   13f76:	e8 0c e5 ff ff       	call   12487 <kpanic>
   13f7b:	83 c4 10             	add    $0x10,%esp

	// if this PCB is already in a queue, we won't touch it
	if( pcb->next != NULL ) {
   13f7e:	8b 45 0c             	mov    0xc(%ebp),%eax
   13f81:	8b 40 08             	mov    0x8(%eax),%eax
   13f84:	85 c0                	test   %eax,%eax
   13f86:	74 0a                	je     13f92 <pcb_queue_insert+0x9c>
		// what to do? we let the caller decide
		return E_BAD_PARAM;
   13f88:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
   13f8d:	e9 48 01 00 00       	jmp    140da <pcb_queue_insert+0x1e4>
	}

	// is the queue empty?
	if( queue->head == NULL ) {
   13f92:	8b 45 08             	mov    0x8(%ebp),%eax
   13f95:	8b 00                	mov    (%eax),%eax
   13f97:	85 c0                	test   %eax,%eax
   13f99:	75 1e                	jne    13fb9 <pcb_queue_insert+0xc3>
		queue->head = queue->tail = pcb;
   13f9b:	8b 45 08             	mov    0x8(%ebp),%eax
   13f9e:	8b 55 0c             	mov    0xc(%ebp),%edx
   13fa1:	89 50 04             	mov    %edx,0x4(%eax)
   13fa4:	8b 45 08             	mov    0x8(%ebp),%eax
   13fa7:	8b 50 04             	mov    0x4(%eax),%edx
   13faa:	8b 45 08             	mov    0x8(%ebp),%eax
   13fad:	89 10                	mov    %edx,(%eax)
		return SUCCESS;
   13faf:	b8 00 00 00 00       	mov    $0x0,%eax
   13fb4:	e9 21 01 00 00       	jmp    140da <pcb_queue_insert+0x1e4>
	}
	assert1( queue->tail != NULL );
   13fb9:	8b 45 08             	mov    0x8(%ebp),%eax
   13fbc:	8b 40 04             	mov    0x4(%eax),%eax
   13fbf:	85 c0                	test   %eax,%eax
   13fc1:	75 3b                	jne    13ffe <pcb_queue_insert+0x108>
   13fc3:	83 ec 04             	sub    $0x4,%esp
   13fc6:	68 ce b2 01 00       	push   $0x1b2ce
   13fcb:	6a 01                	push   $0x1
   13fcd:	68 bd 02 00 00       	push   $0x2bd
   13fd2:	68 f7 b0 01 00       	push   $0x1b0f7
   13fd7:	68 10 b6 01 00       	push   $0x1b610
   13fdc:	68 ff b0 01 00       	push   $0x1b0ff
   13fe1:	68 00 00 02 00       	push   $0x20000
   13fe6:	e8 1c e7 ff ff       	call   12707 <sprint>
   13feb:	83 c4 20             	add    $0x20,%esp
   13fee:	83 ec 0c             	sub    $0xc,%esp
   13ff1:	68 00 00 02 00       	push   $0x20000
   13ff6:	e8 8c e4 ff ff       	call   12487 <kpanic>
   13ffb:	83 c4 10             	add    $0x10,%esp

	// no, so we need to search it
	pcb_t *prev = NULL;
   13ffe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// find the predecessor node
	switch( queue->order ) {
   14005:	8b 45 08             	mov    0x8(%ebp),%eax
   14008:	8b 40 08             	mov    0x8(%eax),%eax
   1400b:	83 f8 01             	cmp    $0x1,%eax
   1400e:	74 1c                	je     1402c <pcb_queue_insert+0x136>
   14010:	83 f8 01             	cmp    $0x1,%eax
   14013:	72 0c                	jb     14021 <pcb_queue_insert+0x12b>
   14015:	83 f8 02             	cmp    $0x2,%eax
   14018:	74 28                	je     14042 <pcb_queue_insert+0x14c>
   1401a:	83 f8 03             	cmp    $0x3,%eax
   1401d:	74 39                	je     14058 <pcb_queue_insert+0x162>
   1401f:	eb 4d                	jmp    1406e <pcb_queue_insert+0x178>
	case O_FIFO:
		prev = queue->tail;
   14021:	8b 45 08             	mov    0x8(%ebp),%eax
   14024:	8b 40 04             	mov    0x4(%eax),%eax
   14027:	89 45 f4             	mov    %eax,-0xc(%ebp)
		break;
   1402a:	eb 49                	jmp    14075 <pcb_queue_insert+0x17f>
	case O_PRIO:
		prev = find_prev_priority(queue,pcb);
   1402c:	83 ec 08             	sub    $0x8,%esp
   1402f:	ff 75 0c             	pushl  0xc(%ebp)
   14032:	ff 75 08             	pushl  0x8(%ebp)
   14035:	e8 25 f4 ff ff       	call   1345f <find_prev_priority>
   1403a:	83 c4 10             	add    $0x10,%esp
   1403d:	89 45 f4             	mov    %eax,-0xc(%ebp)
		break;
   14040:	eb 33                	jmp    14075 <pcb_queue_insert+0x17f>
	case O_PID:
		prev = find_prev_pid(queue,pcb);
   14042:	83 ec 08             	sub    $0x8,%esp
   14045:	ff 75 0c             	pushl  0xc(%ebp)
   14048:	ff 75 08             	pushl  0x8(%ebp)
   1404b:	e8 d2 f4 ff ff       	call   13522 <find_prev_pid>
   14050:	83 c4 10             	add    $0x10,%esp
   14053:	89 45 f4             	mov    %eax,-0xc(%ebp)
		break;
   14056:	eb 1d                	jmp    14075 <pcb_queue_insert+0x17f>
	case O_WAKEUP:
		prev = find_prev_wakeup(queue,pcb);
   14058:	83 ec 08             	sub    $0x8,%esp
   1405b:	ff 75 0c             	pushl  0xc(%ebp)
   1405e:	ff 75 08             	pushl  0x8(%ebp)
   14061:	e8 36 f3 ff ff       	call   1339c <find_prev_wakeup>
   14066:	83 c4 10             	add    $0x10,%esp
   14069:	89 45 f4             	mov    %eax,-0xc(%ebp)
		break;
   1406c:	eb 07                	jmp    14075 <pcb_queue_insert+0x17f>
	default:
		// do we need something more specific here?
		return E_BAD_PARAM;
   1406e:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
   14073:	eb 65                	jmp    140da <pcb_queue_insert+0x1e4>
	}

	// OK, we found the predecessor node; time to do the insertion

	if( prev == NULL ) {
   14075:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   14079:	75 27                	jne    140a2 <pcb_queue_insert+0x1ac>

		// there is no predecessor, so we're
		// inserting at the front of the queue
		pcb->next = queue->head;
   1407b:	8b 45 08             	mov    0x8(%ebp),%eax
   1407e:	8b 10                	mov    (%eax),%edx
   14080:	8b 45 0c             	mov    0xc(%ebp),%eax
   14083:	89 50 08             	mov    %edx,0x8(%eax)
		if( queue->head == NULL ) {
   14086:	8b 45 08             	mov    0x8(%ebp),%eax
   14089:	8b 00                	mov    (%eax),%eax
   1408b:	85 c0                	test   %eax,%eax
   1408d:	75 09                	jne    14098 <pcb_queue_insert+0x1a2>
			// empty queue!?! - should we panic?
			queue->tail = pcb;
   1408f:	8b 45 08             	mov    0x8(%ebp),%eax
   14092:	8b 55 0c             	mov    0xc(%ebp),%edx
   14095:	89 50 04             	mov    %edx,0x4(%eax)
		}
		queue->head = pcb;
   14098:	8b 45 08             	mov    0x8(%ebp),%eax
   1409b:	8b 55 0c             	mov    0xc(%ebp),%edx
   1409e:	89 10                	mov    %edx,(%eax)
   140a0:	eb 33                	jmp    140d5 <pcb_queue_insert+0x1df>

	} else if( prev->next == NULL ) {
   140a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
   140a5:	8b 40 08             	mov    0x8(%eax),%eax
   140a8:	85 c0                	test   %eax,%eax
   140aa:	75 14                	jne    140c0 <pcb_queue_insert+0x1ca>

		// append at end
		prev->next = pcb;
   140ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
   140af:	8b 55 0c             	mov    0xc(%ebp),%edx
   140b2:	89 50 08             	mov    %edx,0x8(%eax)
		queue->tail = pcb;
   140b5:	8b 45 08             	mov    0x8(%ebp),%eax
   140b8:	8b 55 0c             	mov    0xc(%ebp),%edx
   140bb:	89 50 04             	mov    %edx,0x4(%eax)
   140be:	eb 15                	jmp    140d5 <pcb_queue_insert+0x1df>

	} else {

		// insert between prev & prev->next
		pcb->next = prev->next;
   140c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
   140c3:	8b 50 08             	mov    0x8(%eax),%edx
   140c6:	8b 45 0c             	mov    0xc(%ebp),%eax
   140c9:	89 50 08             	mov    %edx,0x8(%eax)
		prev->next = pcb;
   140cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
   140cf:	8b 55 0c             	mov    0xc(%ebp),%edx
   140d2:	89 50 08             	mov    %edx,0x8(%eax)

	}

	return SUCCESS;
   140d5:	b8 00 00 00 00       	mov    $0x0,%eax
}
   140da:	c9                   	leave  
   140db:	c3                   	ret    

000140dc <pcb_queue_remove>:
** @param queue[in,out]  The queue to be used
** @param pcb[out]       Pointer to where the PCB pointer will be saved
**
** @return status of the removal request
*/
int pcb_queue_remove( pcb_queue_t queue, pcb_t **pcb ) {
   140dc:	55                   	push   %ebp
   140dd:	89 e5                	mov    %esp,%ebp
   140df:	83 ec 18             	sub    $0x18,%esp

	//sanity checks
	assert1( queue != NULL );
   140e2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   140e6:	75 3b                	jne    14123 <pcb_queue_remove+0x47>
   140e8:	83 ec 04             	sub    $0x4,%esp
   140eb:	68 ec b0 01 00       	push   $0x1b0ec
   140f0:	6a 01                	push   $0x1
   140f2:	68 00 03 00 00       	push   $0x300
   140f7:	68 f7 b0 01 00       	push   $0x1b0f7
   140fc:	68 24 b6 01 00       	push   $0x1b624
   14101:	68 ff b0 01 00       	push   $0x1b0ff
   14106:	68 00 00 02 00       	push   $0x20000
   1410b:	e8 f7 e5 ff ff       	call   12707 <sprint>
   14110:	83 c4 20             	add    $0x20,%esp
   14113:	83 ec 0c             	sub    $0xc,%esp
   14116:	68 00 00 02 00       	push   $0x20000
   1411b:	e8 67 e3 ff ff       	call   12487 <kpanic>
   14120:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   14123:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   14127:	75 3b                	jne    14164 <pcb_queue_remove+0x88>
   14129:	83 ec 04             	sub    $0x4,%esp
   1412c:	68 15 b1 01 00       	push   $0x1b115
   14131:	6a 01                	push   $0x1
   14133:	68 01 03 00 00       	push   $0x301
   14138:	68 f7 b0 01 00       	push   $0x1b0f7
   1413d:	68 24 b6 01 00       	push   $0x1b624
   14142:	68 ff b0 01 00       	push   $0x1b0ff
   14147:	68 00 00 02 00       	push   $0x20000
   1414c:	e8 b6 e5 ff ff       	call   12707 <sprint>
   14151:	83 c4 20             	add    $0x20,%esp
   14154:	83 ec 0c             	sub    $0xc,%esp
   14157:	68 00 00 02 00       	push   $0x20000
   1415c:	e8 26 e3 ff ff       	call   12487 <kpanic>
   14161:	83 c4 10             	add    $0x10,%esp

	// can't get anything if there's nothing to get!
	if( PCB_QUEUE_EMPTY(queue) ) {
   14164:	8b 45 08             	mov    0x8(%ebp),%eax
   14167:	8b 00                	mov    (%eax),%eax
   14169:	85 c0                	test   %eax,%eax
   1416b:	75 07                	jne    14174 <pcb_queue_remove+0x98>
		return E_EMPTY_QUEUE;
   1416d:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
   14172:	eb 3d                	jmp    141b1 <pcb_queue_remove+0xd5>
	}

	// take the first entry from the queue
	pcb_t *tmp = queue->head;
   14174:	8b 45 08             	mov    0x8(%ebp),%eax
   14177:	8b 00                	mov    (%eax),%eax
   14179:	89 45 f4             	mov    %eax,-0xc(%ebp)
	queue->head = tmp->next;
   1417c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1417f:	8b 50 08             	mov    0x8(%eax),%edx
   14182:	8b 45 08             	mov    0x8(%ebp),%eax
   14185:	89 10                	mov    %edx,(%eax)

	// disconnect it completely
	tmp->next = NULL;
   14187:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1418a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)

	// was this the last thing in the queue?
	if( queue->head == NULL ) {
   14191:	8b 45 08             	mov    0x8(%ebp),%eax
   14194:	8b 00                	mov    (%eax),%eax
   14196:	85 c0                	test   %eax,%eax
   14198:	75 0a                	jne    141a4 <pcb_queue_remove+0xc8>
		// yes, so clear the tail pointer for consistency
		queue->tail = NULL;
   1419a:	8b 45 08             	mov    0x8(%ebp),%eax
   1419d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	}

	// save the pointer
	*pcb = tmp;
   141a4:	8b 45 0c             	mov    0xc(%ebp),%eax
   141a7:	8b 55 f4             	mov    -0xc(%ebp),%edx
   141aa:	89 10                	mov    %edx,(%eax)

	return SUCCESS;
   141ac:	b8 00 00 00 00       	mov    $0x0,%eax
}
   141b1:	c9                   	leave  
   141b2:	c3                   	ret    

000141b3 <pcb_queue_remove_this>:
** @param queue[in,out]  The queue to be used
** @param pcb[in]        Pointer to the PCB to be removed
**
** @return status of the removal request
*/
int pcb_queue_remove_this( pcb_queue_t queue, pcb_t *pcb ) {
   141b3:	55                   	push   %ebp
   141b4:	89 e5                	mov    %esp,%ebp
   141b6:	83 ec 18             	sub    $0x18,%esp

	//sanity checks
	assert1( queue != NULL );
   141b9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   141bd:	75 3b                	jne    141fa <pcb_queue_remove_this+0x47>
   141bf:	83 ec 04             	sub    $0x4,%esp
   141c2:	68 ec b0 01 00       	push   $0x1b0ec
   141c7:	6a 01                	push   $0x1
   141c9:	68 2c 03 00 00       	push   $0x32c
   141ce:	68 f7 b0 01 00       	push   $0x1b0f7
   141d3:	68 38 b6 01 00       	push   $0x1b638
   141d8:	68 ff b0 01 00       	push   $0x1b0ff
   141dd:	68 00 00 02 00       	push   $0x20000
   141e2:	e8 20 e5 ff ff       	call   12707 <sprint>
   141e7:	83 c4 20             	add    $0x20,%esp
   141ea:	83 ec 0c             	sub    $0xc,%esp
   141ed:	68 00 00 02 00       	push   $0x20000
   141f2:	e8 90 e2 ff ff       	call   12487 <kpanic>
   141f7:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   141fa:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   141fe:	75 3b                	jne    1423b <pcb_queue_remove_this+0x88>
   14200:	83 ec 04             	sub    $0x4,%esp
   14203:	68 15 b1 01 00       	push   $0x1b115
   14208:	6a 01                	push   $0x1
   1420a:	68 2d 03 00 00       	push   $0x32d
   1420f:	68 f7 b0 01 00       	push   $0x1b0f7
   14214:	68 38 b6 01 00       	push   $0x1b638
   14219:	68 ff b0 01 00       	push   $0x1b0ff
   1421e:	68 00 00 02 00       	push   $0x20000
   14223:	e8 df e4 ff ff       	call   12707 <sprint>
   14228:	83 c4 20             	add    $0x20,%esp
   1422b:	83 ec 0c             	sub    $0xc,%esp
   1422e:	68 00 00 02 00       	push   $0x20000
   14233:	e8 4f e2 ff ff       	call   12487 <kpanic>
   14238:	83 c4 10             	add    $0x10,%esp

	// can't get anything if there's nothing to get!
	if( PCB_QUEUE_EMPTY(queue) ) {
   1423b:	8b 45 08             	mov    0x8(%ebp),%eax
   1423e:	8b 00                	mov    (%eax),%eax
   14240:	85 c0                	test   %eax,%eax
   14242:	75 0a                	jne    1424e <pcb_queue_remove_this+0x9b>
		return E_EMPTY_QUEUE;
   14244:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
   14249:	e9 21 01 00 00       	jmp    1436f <pcb_queue_remove_this+0x1bc>
	}

	// iterate through the queue until we find the desired PCB
	pcb_t *prev = NULL;
   1424e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *curr = queue->head;
   14255:	8b 45 08             	mov    0x8(%ebp),%eax
   14258:	8b 00                	mov    (%eax),%eax
   1425a:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr != NULL && curr != pcb ) {
   1425d:	eb 0f                	jmp    1426e <pcb_queue_remove_this+0xbb>
		prev = curr;
   1425f:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14262:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   14265:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14268:	8b 40 08             	mov    0x8(%eax),%eax
   1426b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr != NULL && curr != pcb ) {
   1426e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   14272:	74 08                	je     1427c <pcb_queue_remove_this+0xc9>
   14274:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14277:	3b 45 0c             	cmp    0xc(%ebp),%eax
   1427a:	75 e3                	jne    1425f <pcb_queue_remove_this+0xac>
	//   3.    0    !0    !0    removing first element
	//   4.   !0     0    --    *** NOT FOUND ***
	//   5.   !0    !0     0    removing from end
	//   6.   !0    !0    !0    removing from middle

	if( curr == NULL ) {
   1427c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   14280:	75 4b                	jne    142cd <pcb_queue_remove_this+0x11a>
		// case 1
		assert( prev != NULL );
   14282:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   14286:	75 3b                	jne    142c3 <pcb_queue_remove_this+0x110>
   14288:	83 ec 04             	sub    $0x4,%esp
   1428b:	68 df b2 01 00       	push   $0x1b2df
   14290:	6a 00                	push   $0x0
   14292:	68 48 03 00 00       	push   $0x348
   14297:	68 f7 b0 01 00       	push   $0x1b0f7
   1429c:	68 38 b6 01 00       	push   $0x1b638
   142a1:	68 ff b0 01 00       	push   $0x1b0ff
   142a6:	68 00 00 02 00       	push   $0x20000
   142ab:	e8 57 e4 ff ff       	call   12707 <sprint>
   142b0:	83 c4 20             	add    $0x20,%esp
   142b3:	83 ec 0c             	sub    $0xc,%esp
   142b6:	68 00 00 02 00       	push   $0x20000
   142bb:	e8 c7 e1 ff ff       	call   12487 <kpanic>
   142c0:	83 c4 10             	add    $0x10,%esp
		// case 4
		return E_NOT_FOUND;
   142c3:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
   142c8:	e9 a2 00 00 00       	jmp    1436f <pcb_queue_remove_this+0x1bc>
	}

	// connect predecessor to successor
	if( prev != NULL ) {
   142cd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   142d1:	74 0e                	je     142e1 <pcb_queue_remove_this+0x12e>
		// not the first element
		// cases 5 and 6
		prev->next = curr->next;
   142d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
   142d6:	8b 50 08             	mov    0x8(%eax),%edx
   142d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
   142dc:	89 50 08             	mov    %edx,0x8(%eax)
   142df:	eb 0b                	jmp    142ec <pcb_queue_remove_this+0x139>
	} else {
		// removing first element
		// cases 2 and 3
		queue->head = curr->next;
   142e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
   142e4:	8b 50 08             	mov    0x8(%eax),%edx
   142e7:	8b 45 08             	mov    0x8(%ebp),%eax
   142ea:	89 10                	mov    %edx,(%eax)
	}

	// if this was the last node (cases 2 and 5),
	// also need to reset the tail pointer
	if( curr->next == NULL ) {
   142ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
   142ef:	8b 40 08             	mov    0x8(%eax),%eax
   142f2:	85 c0                	test   %eax,%eax
   142f4:	75 09                	jne    142ff <pcb_queue_remove_this+0x14c>
		// if this was the only entry (2), prev is NULL,
		// so this works for that case, too
		queue->tail = prev;
   142f6:	8b 45 08             	mov    0x8(%ebp),%eax
   142f9:	8b 55 f4             	mov    -0xc(%ebp),%edx
   142fc:	89 50 04             	mov    %edx,0x4(%eax)
	}

	// unlink current from queue
	curr->next = NULL;
   142ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14302:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)

	// there's a possible consistancy problem here if somehow
	// one of the queue pointers is NULL and the other one
	// is not NULL

	assert1(
   14309:	8b 45 08             	mov    0x8(%ebp),%eax
   1430c:	8b 00                	mov    (%eax),%eax
   1430e:	85 c0                	test   %eax,%eax
   14310:	75 0a                	jne    1431c <pcb_queue_remove_this+0x169>
   14312:	8b 45 08             	mov    0x8(%ebp),%eax
   14315:	8b 40 04             	mov    0x4(%eax),%eax
   14318:	85 c0                	test   %eax,%eax
   1431a:	74 4e                	je     1436a <pcb_queue_remove_this+0x1b7>
   1431c:	8b 45 08             	mov    0x8(%ebp),%eax
   1431f:	8b 00                	mov    (%eax),%eax
   14321:	85 c0                	test   %eax,%eax
   14323:	74 0a                	je     1432f <pcb_queue_remove_this+0x17c>
   14325:	8b 45 08             	mov    0x8(%ebp),%eax
   14328:	8b 40 04             	mov    0x4(%eax),%eax
   1432b:	85 c0                	test   %eax,%eax
   1432d:	75 3b                	jne    1436a <pcb_queue_remove_this+0x1b7>
   1432f:	83 ec 04             	sub    $0x4,%esp
   14332:	68 ec b2 01 00       	push   $0x1b2ec
   14337:	6a 01                	push   $0x1
   14339:	68 6a 03 00 00       	push   $0x36a
   1433e:	68 f7 b0 01 00       	push   $0x1b0f7
   14343:	68 38 b6 01 00       	push   $0x1b638
   14348:	68 ff b0 01 00       	push   $0x1b0ff
   1434d:	68 00 00 02 00       	push   $0x20000
   14352:	e8 b0 e3 ff ff       	call   12707 <sprint>
   14357:	83 c4 20             	add    $0x20,%esp
   1435a:	83 ec 0c             	sub    $0xc,%esp
   1435d:	68 00 00 02 00       	push   $0x20000
   14362:	e8 20 e1 ff ff       	call   12487 <kpanic>
   14367:	83 c4 10             	add    $0x10,%esp
		(queue->head == NULL && queue->tail == NULL) ||
		(queue->head != NULL && queue->tail != NULL)
	);

	return SUCCESS;
   1436a:	b8 00 00 00 00       	mov    $0x0,%eax
}
   1436f:	c9                   	leave  
   14370:	c3                   	ret    

00014371 <pcb_queue_peek>:
**
** @param queue[in]  The queue to be used
**
** @return the PCB poiner, or NULL if the queue is empty
*/
pcb_t *pcb_queue_peek( const pcb_queue_t queue ) {
   14371:	55                   	push   %ebp
   14372:	89 e5                	mov    %esp,%ebp
   14374:	83 ec 08             	sub    $0x8,%esp

	//sanity check
	assert1( queue != NULL );
   14377:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1437b:	75 3b                	jne    143b8 <pcb_queue_peek+0x47>
   1437d:	83 ec 04             	sub    $0x4,%esp
   14380:	68 ec b0 01 00       	push   $0x1b0ec
   14385:	6a 01                	push   $0x1
   14387:	68 7c 03 00 00       	push   $0x37c
   1438c:	68 f7 b0 01 00       	push   $0x1b0f7
   14391:	68 50 b6 01 00       	push   $0x1b650
   14396:	68 ff b0 01 00       	push   $0x1b0ff
   1439b:	68 00 00 02 00       	push   $0x20000
   143a0:	e8 62 e3 ff ff       	call   12707 <sprint>
   143a5:	83 c4 20             	add    $0x20,%esp
   143a8:	83 ec 0c             	sub    $0xc,%esp
   143ab:	68 00 00 02 00       	push   $0x20000
   143b0:	e8 d2 e0 ff ff       	call   12487 <kpanic>
   143b5:	83 c4 10             	add    $0x10,%esp

	// can't get anything if there's nothing to get!
	if( PCB_QUEUE_EMPTY(queue) ) {
   143b8:	8b 45 08             	mov    0x8(%ebp),%eax
   143bb:	8b 00                	mov    (%eax),%eax
   143bd:	85 c0                	test   %eax,%eax
   143bf:	75 07                	jne    143c8 <pcb_queue_peek+0x57>
		return NULL;
   143c1:	b8 00 00 00 00       	mov    $0x0,%eax
   143c6:	eb 05                	jmp    143cd <pcb_queue_peek+0x5c>
	}

	// just return the first entry from the queue
	return queue->head;
   143c8:	8b 45 08             	mov    0x8(%ebp),%eax
   143cb:	8b 00                	mov    (%eax),%eax
}
   143cd:	c9                   	leave  
   143ce:	c3                   	ret    

000143cf <schedule>:
**
** Schedule the supplied process
**
** @param pcb   Pointer to the PCB of the process to be scheduled
*/
void schedule( pcb_t *pcb ) {
   143cf:	55                   	push   %ebp
   143d0:	89 e5                	mov    %esp,%ebp
   143d2:	83 ec 08             	sub    $0x8,%esp

	// sanity check
	assert1( pcb != NULL );
   143d5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   143d9:	75 3b                	jne    14416 <schedule+0x47>
   143db:	83 ec 04             	sub    $0x4,%esp
   143de:	68 15 b1 01 00       	push   $0x1b115
   143e3:	6a 01                	push   $0x1
   143e5:	68 95 03 00 00       	push   $0x395
   143ea:	68 f7 b0 01 00       	push   $0x1b0f7
   143ef:	68 60 b6 01 00       	push   $0x1b660
   143f4:	68 ff b0 01 00       	push   $0x1b0ff
   143f9:	68 00 00 02 00       	push   $0x20000
   143fe:	e8 04 e3 ff ff       	call   12707 <sprint>
   14403:	83 c4 20             	add    $0x20,%esp
   14406:	83 ec 0c             	sub    $0xc,%esp
   14409:	68 00 00 02 00       	push   $0x20000
   1440e:	e8 74 e0 ff ff       	call   12487 <kpanic>
   14413:	83 c4 10             	add    $0x10,%esp

	// check for a killed process
	if( pcb->state == STATE_KILLED ) {
   14416:	8b 45 08             	mov    0x8(%ebp),%eax
   14419:	8b 40 1c             	mov    0x1c(%eax),%eax
   1441c:	83 f8 07             	cmp    $0x7,%eax
   1441f:	75 10                	jne    14431 <schedule+0x62>
		pcb_zombify( pcb );
   14421:	83 ec 0c             	sub    $0xc,%esp
   14424:	ff 75 08             	pushl  0x8(%ebp)
   14427:	e8 e6 f5 ff ff       	call   13a12 <pcb_zombify>
   1442c:	83 c4 10             	add    $0x10,%esp
		return;
   1442f:	eb 5d                	jmp    1448e <schedule+0xbf>
	}

	// mark it as ready
	pcb->state = STATE_READY;
   14431:	8b 45 08             	mov    0x8(%ebp),%eax
   14434:	c7 40 1c 02 00 00 00 	movl   $0x2,0x1c(%eax)

	// add it to the ready queue
	if( pcb_queue_insert(ready,pcb) != SUCCESS ) {
   1443b:	a1 d0 24 02 00       	mov    0x224d0,%eax
   14440:	83 ec 08             	sub    $0x8,%esp
   14443:	ff 75 08             	pushl  0x8(%ebp)
   14446:	50                   	push   %eax
   14447:	e8 aa fa ff ff       	call   13ef6 <pcb_queue_insert>
   1444c:	83 c4 10             	add    $0x10,%esp
   1444f:	85 c0                	test   %eax,%eax
   14451:	74 3b                	je     1448e <schedule+0xbf>
		PANIC( 0, "schedule insert fail" );
   14453:	83 ec 04             	sub    $0x4,%esp
   14456:	68 3d b3 01 00       	push   $0x1b33d
   1445b:	6a 00                	push   $0x0
   1445d:	68 a2 03 00 00       	push   $0x3a2
   14462:	68 f7 b0 01 00       	push   $0x1b0f7
   14467:	68 60 b6 01 00       	push   $0x1b660
   1446c:	68 ff b0 01 00       	push   $0x1b0ff
   14471:	68 00 00 02 00       	push   $0x20000
   14476:	e8 8c e2 ff ff       	call   12707 <sprint>
   1447b:	83 c4 20             	add    $0x20,%esp
   1447e:	83 ec 0c             	sub    $0xc,%esp
   14481:	68 00 00 02 00       	push   $0x20000
   14486:	e8 fc df ff ff       	call   12487 <kpanic>
   1448b:	83 c4 10             	add    $0x10,%esp
	}
}
   1448e:	c9                   	leave  
   1448f:	c3                   	ret    

00014490 <dispatch>:
/**
** dispatch()
**
** Select the next process to receive the CPU
*/
void dispatch( void ) {
   14490:	55                   	push   %ebp
   14491:	89 e5                	mov    %esp,%ebp
   14493:	83 ec 18             	sub    $0x18,%esp

	// verify that there is no current process
	assert( current == NULL );
   14496:	a1 14 20 02 00       	mov    0x22014,%eax
   1449b:	85 c0                	test   %eax,%eax
   1449d:	74 3b                	je     144da <dispatch+0x4a>
   1449f:	83 ec 04             	sub    $0x4,%esp
   144a2:	68 54 b3 01 00       	push   $0x1b354
   144a7:	6a 00                	push   $0x0
   144a9:	68 ae 03 00 00       	push   $0x3ae
   144ae:	68 f7 b0 01 00       	push   $0x1b0f7
   144b3:	68 6c b6 01 00       	push   $0x1b66c
   144b8:	68 ff b0 01 00       	push   $0x1b0ff
   144bd:	68 00 00 02 00       	push   $0x20000
   144c2:	e8 40 e2 ff ff       	call   12707 <sprint>
   144c7:	83 c4 20             	add    $0x20,%esp
   144ca:	83 ec 0c             	sub    $0xc,%esp
   144cd:	68 00 00 02 00       	push   $0x20000
   144d2:	e8 b0 df ff ff       	call   12487 <kpanic>
   144d7:	83 c4 10             	add    $0x10,%esp

	// grab whoever is at the head of the queue
	int status = pcb_queue_remove( ready, &current );
   144da:	a1 d0 24 02 00       	mov    0x224d0,%eax
   144df:	83 ec 08             	sub    $0x8,%esp
   144e2:	68 14 20 02 00       	push   $0x22014
   144e7:	50                   	push   %eax
   144e8:	e8 ef fb ff ff       	call   140dc <pcb_queue_remove>
   144ed:	83 c4 10             	add    $0x10,%esp
   144f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( status != SUCCESS ) {
   144f3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   144f7:	74 53                	je     1454c <dispatch+0xbc>
		sprint( b256, "dispatch queue remove failed, code %d", status );
   144f9:	83 ec 04             	sub    $0x4,%esp
   144fc:	ff 75 f4             	pushl  -0xc(%ebp)
   144ff:	68 64 b3 01 00       	push   $0x1b364
   14504:	68 00 02 02 00       	push   $0x20200
   14509:	e8 f9 e1 ff ff       	call   12707 <sprint>
   1450e:	83 c4 10             	add    $0x10,%esp
		PANIC( 0, b256 );
   14511:	83 ec 04             	sub    $0x4,%esp
   14514:	68 19 b2 01 00       	push   $0x1b219
   14519:	6a 00                	push   $0x0
   1451b:	68 b4 03 00 00       	push   $0x3b4
   14520:	68 f7 b0 01 00       	push   $0x1b0f7
   14525:	68 6c b6 01 00       	push   $0x1b66c
   1452a:	68 ff b0 01 00       	push   $0x1b0ff
   1452f:	68 00 00 02 00       	push   $0x20000
   14534:	e8 ce e1 ff ff       	call   12707 <sprint>
   14539:	83 c4 20             	add    $0x20,%esp
   1453c:	83 ec 0c             	sub    $0xc,%esp
   1453f:	68 00 00 02 00       	push   $0x20000
   14544:	e8 3e df ff ff       	call   12487 <kpanic>
   14549:	83 c4 10             	add    $0x10,%esp
	}

	// set the process up for success
	current->state = STATE_RUNNING;
   1454c:	a1 14 20 02 00       	mov    0x22014,%eax
   14551:	c7 40 1c 03 00 00 00 	movl   $0x3,0x1c(%eax)
	current->ticks = QUANTUM_STANDARD;
   14558:	a1 14 20 02 00       	mov    0x22014,%eax
   1455d:	c7 40 24 03 00 00 00 	movl   $0x3,0x24(%eax)
}
   14564:	90                   	nop
   14565:	c9                   	leave  
   14566:	c3                   	ret    

00014567 <ctx_dump>:
** Dumps the contents of this process context to the console
**
** @param msg[in]   An optional message to print before the dump
** @param c[in]     The context to dump out
*/
void ctx_dump( const char *msg, register context_t *c ) {
   14567:	55                   	push   %ebp
   14568:	89 e5                	mov    %esp,%ebp
   1456a:	57                   	push   %edi
   1456b:	56                   	push   %esi
   1456c:	53                   	push   %ebx
   1456d:	83 ec 1c             	sub    $0x1c,%esp
   14570:	8b 5d 0c             	mov    0xc(%ebp),%ebx

	// first, the message (if there is one)
	if( msg ) {
   14573:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   14577:	74 0e                	je     14587 <ctx_dump+0x20>
		cio_puts( msg );
   14579:	83 ec 0c             	sub    $0xc,%esp
   1457c:	ff 75 08             	pushl  0x8(%ebp)
   1457f:	e8 29 c9 ff ff       	call   10ead <cio_puts>
   14584:	83 c4 10             	add    $0x10,%esp
	}

	// the pointer
	cio_printf( " @ %08x:\n", (uint32_t) c );
   14587:	89 d8                	mov    %ebx,%eax
   14589:	83 ec 08             	sub    $0x8,%esp
   1458c:	50                   	push   %eax
   1458d:	68 8a b3 01 00       	push   $0x1b38a
   14592:	e8 90 cf ff ff       	call   11527 <cio_printf>
   14597:	83 c4 10             	add    $0x10,%esp

	// if it's NULL, why did you bother calling me?
	if( c == NULL ) {
   1459a:	85 db                	test   %ebx,%ebx
   1459c:	75 15                	jne    145b3 <ctx_dump+0x4c>
		cio_puts( " NULL???\n" );
   1459e:	83 ec 0c             	sub    $0xc,%esp
   145a1:	68 94 b3 01 00       	push   $0x1b394
   145a6:	e8 02 c9 ff ff       	call   10ead <cio_puts>
   145ab:	83 c4 10             	add    $0x10,%esp
		return;
   145ae:	e9 9e 00 00 00       	jmp    14651 <ctx_dump+0xea>
	}

	// now, the contents
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
				  c->es & 0xff, c->ds & 0xff, c->cs & 0xff );
   145b3:	8b 43 40             	mov    0x40(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145b6:	0f b6 c0             	movzbl %al,%eax
   145b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				  c->es & 0xff, c->ds & 0xff, c->cs & 0xff );
   145bc:	8b 43 10             	mov    0x10(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145bf:	0f b6 f8             	movzbl %al,%edi
				  c->es & 0xff, c->ds & 0xff, c->cs & 0xff );
   145c2:	8b 43 0c             	mov    0xc(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145c5:	0f b6 f0             	movzbl %al,%esi
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
   145c8:	8b 43 08             	mov    0x8(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145cb:	0f b6 c8             	movzbl %al,%ecx
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
   145ce:	8b 43 04             	mov    0x4(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145d1:	0f b6 d0             	movzbl %al,%edx
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
   145d4:	8b 03                	mov    (%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145d6:	0f b6 c0             	movzbl %al,%eax
   145d9:	83 ec 04             	sub    $0x4,%esp
   145dc:	ff 75 e4             	pushl  -0x1c(%ebp)
   145df:	57                   	push   %edi
   145e0:	56                   	push   %esi
   145e1:	51                   	push   %ecx
   145e2:	52                   	push   %edx
   145e3:	50                   	push   %eax
   145e4:	68 a0 b3 01 00       	push   $0x1b3a0
   145e9:	e8 39 cf ff ff       	call   11527 <cio_printf>
   145ee:	83 c4 20             	add    $0x20,%esp
	cio_printf( "  edi %08x esi %08x ebp %08x esp %08x\n",
   145f1:	8b 73 20             	mov    0x20(%ebx),%esi
   145f4:	8b 4b 1c             	mov    0x1c(%ebx),%ecx
   145f7:	8b 53 18             	mov    0x18(%ebx),%edx
   145fa:	8b 43 14             	mov    0x14(%ebx),%eax
   145fd:	83 ec 0c             	sub    $0xc,%esp
   14600:	56                   	push   %esi
   14601:	51                   	push   %ecx
   14602:	52                   	push   %edx
   14603:	50                   	push   %eax
   14604:	68 d4 b3 01 00       	push   $0x1b3d4
   14609:	e8 19 cf ff ff       	call   11527 <cio_printf>
   1460e:	83 c4 20             	add    $0x20,%esp
				  c->edi, c->esi, c->ebp, c->esp );
	cio_printf( "  ebx %08x edx %08x ecx %08x eax %08x\n",
   14611:	8b 73 30             	mov    0x30(%ebx),%esi
   14614:	8b 4b 2c             	mov    0x2c(%ebx),%ecx
   14617:	8b 53 28             	mov    0x28(%ebx),%edx
   1461a:	8b 43 24             	mov    0x24(%ebx),%eax
   1461d:	83 ec 0c             	sub    $0xc,%esp
   14620:	56                   	push   %esi
   14621:	51                   	push   %ecx
   14622:	52                   	push   %edx
   14623:	50                   	push   %eax
   14624:	68 fc b3 01 00       	push   $0x1b3fc
   14629:	e8 f9 ce ff ff       	call   11527 <cio_printf>
   1462e:	83 c4 20             	add    $0x20,%esp
				  c->ebx, c->edx, c->ecx, c->eax );
	cio_printf( "  vec %08x cod %08x eip %08x efl %08x\n",
   14631:	8b 73 44             	mov    0x44(%ebx),%esi
   14634:	8b 4b 3c             	mov    0x3c(%ebx),%ecx
   14637:	8b 53 38             	mov    0x38(%ebx),%edx
   1463a:	8b 43 34             	mov    0x34(%ebx),%eax
   1463d:	83 ec 0c             	sub    $0xc,%esp
   14640:	56                   	push   %esi
   14641:	51                   	push   %ecx
   14642:	52                   	push   %edx
   14643:	50                   	push   %eax
   14644:	68 24 b4 01 00       	push   $0x1b424
   14649:	e8 d9 ce ff ff       	call   11527 <cio_printf>
   1464e:	83 c4 20             	add    $0x20,%esp
				  c->vector, c->code, c->eip, c->eflags );
}
   14651:	8d 65 f4             	lea    -0xc(%ebp),%esp
   14654:	5b                   	pop    %ebx
   14655:	5e                   	pop    %esi
   14656:	5f                   	pop    %edi
   14657:	5d                   	pop    %ebp
   14658:	c3                   	ret    

00014659 <ctx_dump_all>:
**
** dump the process context for all active processes
**
** @param msg[in]  Optional message to print
*/
void ctx_dump_all( const char *msg ) {
   14659:	55                   	push   %ebp
   1465a:	89 e5                	mov    %esp,%ebp
   1465c:	53                   	push   %ebx
   1465d:	83 ec 14             	sub    $0x14,%esp

	if( msg != NULL ) {
   14660:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   14664:	74 0e                	je     14674 <ctx_dump_all+0x1b>
		cio_puts( msg );
   14666:	83 ec 0c             	sub    $0xc,%esp
   14669:	ff 75 08             	pushl  0x8(%ebp)
   1466c:	e8 3c c8 ff ff       	call   10ead <cio_puts>
   14671:	83 c4 10             	add    $0x10,%esp
	}

	int n = 0;
   14674:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	register pcb_t *pcb = ptable;
   1467b:	bb 20 20 02 00       	mov    $0x22020,%ebx
	for( int i = 0; i < N_PROCS; ++i, ++pcb ) {
   14680:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   14687:	eb 39                	jmp    146c2 <ctx_dump_all+0x69>
		if( pcb->state != STATE_UNUSED ) {
   14689:	8b 43 1c             	mov    0x1c(%ebx),%eax
   1468c:	85 c0                	test   %eax,%eax
   1468e:	74 2b                	je     146bb <ctx_dump_all+0x62>
			++n;
   14690:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
			cio_printf( "%2d(%d): ", n, pcb->pid );
   14694:	8b 43 18             	mov    0x18(%ebx),%eax
   14697:	83 ec 04             	sub    $0x4,%esp
   1469a:	50                   	push   %eax
   1469b:	ff 75 f4             	pushl  -0xc(%ebp)
   1469e:	68 4b b4 01 00       	push   $0x1b44b
   146a3:	e8 7f ce ff ff       	call   11527 <cio_printf>
   146a8:	83 c4 10             	add    $0x10,%esp
			ctx_dump( NULL, pcb->context );
   146ab:	8b 03                	mov    (%ebx),%eax
   146ad:	83 ec 08             	sub    $0x8,%esp
   146b0:	50                   	push   %eax
   146b1:	6a 00                	push   $0x0
   146b3:	e8 af fe ff ff       	call   14567 <ctx_dump>
   146b8:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < N_PROCS; ++i, ++pcb ) {
   146bb:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   146bf:	83 c3 30             	add    $0x30,%ebx
   146c2:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   146c6:	7e c1                	jle    14689 <ctx_dump_all+0x30>
		}
	}
}
   146c8:	90                   	nop
   146c9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   146cc:	c9                   	leave  
   146cd:	c3                   	ret    

000146ce <pcb_dump>:
**
** @param msg[in]  An optional message to print before the dump
** @param pcb[in]  The PCB to dump
** @param all[in]  Dump all the contents?
*/
void pcb_dump( const char *msg, register pcb_t *pcb, bool_t all ) {
   146ce:	55                   	push   %ebp
   146cf:	89 e5                	mov    %esp,%ebp
   146d1:	56                   	push   %esi
   146d2:	53                   	push   %ebx
   146d3:	83 ec 10             	sub    $0x10,%esp
   146d6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
   146d9:	8b 45 10             	mov    0x10(%ebp),%eax
   146dc:	88 45 f4             	mov    %al,-0xc(%ebp)

	// first, the message (if there is one)
	if( msg ) {
   146df:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   146e3:	74 0e                	je     146f3 <pcb_dump+0x25>
		cio_puts( msg );
   146e5:	83 ec 0c             	sub    $0xc,%esp
   146e8:	ff 75 08             	pushl  0x8(%ebp)
   146eb:	e8 bd c7 ff ff       	call   10ead <cio_puts>
   146f0:	83 c4 10             	add    $0x10,%esp
	}

	// the pointer
	cio_printf( " @ %08x:", (uint32_t) pcb );
   146f3:	89 d8                	mov    %ebx,%eax
   146f5:	83 ec 08             	sub    $0x8,%esp
   146f8:	50                   	push   %eax
   146f9:	68 55 b4 01 00       	push   $0x1b455
   146fe:	e8 24 ce ff ff       	call   11527 <cio_printf>
   14703:	83 c4 10             	add    $0x10,%esp

	// if it's NULL, why did you bother calling me?
	if( pcb == NULL ) {
   14706:	85 db                	test   %ebx,%ebx
   14708:	75 15                	jne    1471f <pcb_dump+0x51>
		cio_puts( " NULL???\n" );
   1470a:	83 ec 0c             	sub    $0xc,%esp
   1470d:	68 94 b3 01 00       	push   $0x1b394
   14712:	e8 96 c7 ff ff       	call   10ead <cio_puts>
   14717:	83 c4 10             	add    $0x10,%esp
		return;
   1471a:	e9 e7 00 00 00       	jmp    14806 <pcb_dump+0x138>
	}

	cio_printf( " %d %s", pcb->pid,
			pcb->state >= N_STATES ? "???" : state_str[pcb->state] );
   1471f:	8b 43 1c             	mov    0x1c(%ebx),%eax
	cio_printf( " %d %s", pcb->pid,
   14722:	83 f8 08             	cmp    $0x8,%eax
   14725:	77 0e                	ja     14735 <pcb_dump+0x67>
			pcb->state >= N_STATES ? "???" : state_str[pcb->state] );
   14727:	8b 43 1c             	mov    0x1c(%ebx),%eax
	cio_printf( " %d %s", pcb->pid,
   1472a:	c1 e0 02             	shl    $0x2,%eax
   1472d:	8d 90 a0 b0 01 00    	lea    0x1b0a0(%eax),%edx
   14733:	eb 05                	jmp    1473a <pcb_dump+0x6c>
   14735:	ba 5e b4 01 00       	mov    $0x1b45e,%edx
   1473a:	8b 43 18             	mov    0x18(%ebx),%eax
   1473d:	83 ec 04             	sub    $0x4,%esp
   14740:	52                   	push   %edx
   14741:	50                   	push   %eax
   14742:	68 62 b4 01 00       	push   $0x1b462
   14747:	e8 db cd ff ff       	call   11527 <cio_printf>
   1474c:	83 c4 10             	add    $0x10,%esp

	if( !all ) {
   1474f:	80 7d f4 00          	cmpb   $0x0,-0xc(%ebp)
   14753:	0f 84 ac 00 00 00    	je     14805 <pcb_dump+0x137>
		return;
	}

	// now, the rest of the contents
	cio_printf( " %s",
			pcb->priority >= N_PRIOS ? "???" : prio_str[pcb->priority] );
   14759:	8b 43 20             	mov    0x20(%ebx),%eax
	cio_printf( " %s",
   1475c:	83 f8 03             	cmp    $0x3,%eax
   1475f:	77 11                	ja     14772 <pcb_dump+0xa4>
			pcb->priority >= N_PRIOS ? "???" : prio_str[pcb->priority] );
   14761:	8b 53 20             	mov    0x20(%ebx),%edx
	cio_printf( " %s",
   14764:	89 d0                	mov    %edx,%eax
   14766:	c1 e0 02             	shl    $0x2,%eax
   14769:	01 d0                	add    %edx,%eax
   1476b:	05 c4 b0 01 00       	add    $0x1b0c4,%eax
   14770:	eb 05                	jmp    14777 <pcb_dump+0xa9>
   14772:	b8 5e b4 01 00       	mov    $0x1b45e,%eax
   14777:	83 ec 08             	sub    $0x8,%esp
   1477a:	50                   	push   %eax
   1477b:	68 69 b4 01 00       	push   $0x1b469
   14780:	e8 a2 cd ff ff       	call   11527 <cio_printf>
   14785:	83 c4 10             	add    $0x10,%esp

	cio_printf( " ticks %u xit %d wake %08x\n",
   14788:	8b 4b 10             	mov    0x10(%ebx),%ecx
   1478b:	8b 53 14             	mov    0x14(%ebx),%edx
   1478e:	8b 43 24             	mov    0x24(%ebx),%eax
   14791:	51                   	push   %ecx
   14792:	52                   	push   %edx
   14793:	50                   	push   %eax
   14794:	68 6d b4 01 00       	push   $0x1b46d
   14799:	e8 89 cd ff ff       	call   11527 <cio_printf>
   1479e:	83 c4 10             	add    $0x10,%esp
				pcb->ticks, pcb->exit_status, pcb->wakeup );

	cio_printf( " parent %08x", (uint32_t)pcb->parent );
   147a1:	8b 43 0c             	mov    0xc(%ebx),%eax
   147a4:	83 ec 08             	sub    $0x8,%esp
   147a7:	50                   	push   %eax
   147a8:	68 89 b4 01 00       	push   $0x1b489
   147ad:	e8 75 cd ff ff       	call   11527 <cio_printf>
   147b2:	83 c4 10             	add    $0x10,%esp
	if( pcb->parent != NULL ) {
   147b5:	8b 43 0c             	mov    0xc(%ebx),%eax
   147b8:	85 c0                	test   %eax,%eax
   147ba:	74 17                	je     147d3 <pcb_dump+0x105>
		cio_printf( " (%u)", pcb->parent->pid );
   147bc:	8b 43 0c             	mov    0xc(%ebx),%eax
   147bf:	8b 40 18             	mov    0x18(%eax),%eax
   147c2:	83 ec 08             	sub    $0x8,%esp
   147c5:	50                   	push   %eax
   147c6:	68 96 b4 01 00       	push   $0x1b496
   147cb:	e8 57 cd ff ff       	call   11527 <cio_printf>
   147d0:	83 c4 10             	add    $0x10,%esp
	}

	cio_printf( " next %08x context %08x stk %08x (%u)",
   147d3:	8b 43 28             	mov    0x28(%ebx),%eax
			(uint32_t) pcb->next, (uint32_t) pcb->context,
			(uint32_t) pcb->stack, pcb->stkpgs );
   147d6:	8b 53 04             	mov    0x4(%ebx),%edx
	cio_printf( " next %08x context %08x stk %08x (%u)",
   147d9:	89 d6                	mov    %edx,%esi
			(uint32_t) pcb->next, (uint32_t) pcb->context,
   147db:	8b 13                	mov    (%ebx),%edx
	cio_printf( " next %08x context %08x stk %08x (%u)",
   147dd:	89 d1                	mov    %edx,%ecx
			(uint32_t) pcb->next, (uint32_t) pcb->context,
   147df:	8b 53 08             	mov    0x8(%ebx),%edx
	cio_printf( " next %08x context %08x stk %08x (%u)",
   147e2:	83 ec 0c             	sub    $0xc,%esp
   147e5:	50                   	push   %eax
   147e6:	56                   	push   %esi
   147e7:	51                   	push   %ecx
   147e8:	52                   	push   %edx
   147e9:	68 9c b4 01 00       	push   $0x1b49c
   147ee:	e8 34 cd ff ff       	call   11527 <cio_printf>
   147f3:	83 c4 20             	add    $0x20,%esp

	cio_putchar( '\n' );
   147f6:	83 ec 0c             	sub    $0xc,%esp
   147f9:	6a 0a                	push   $0xa
   147fb:	e8 6d c5 ff ff       	call   10d6d <cio_putchar>
   14800:	83 c4 10             	add    $0x10,%esp
   14803:	eb 01                	jmp    14806 <pcb_dump+0x138>
		return;
   14805:	90                   	nop
}
   14806:	8d 65 f8             	lea    -0x8(%ebp),%esp
   14809:	5b                   	pop    %ebx
   1480a:	5e                   	pop    %esi
   1480b:	5d                   	pop    %ebp
   1480c:	c3                   	ret    

0001480d <pcb_queue_dump>:
**
** @param msg[in]       Optional message to print
** @param queue[in]     The queue to dump
** @param contents[in]  Also dump (some) contents?
*/
void pcb_queue_dump( const char *msg, pcb_queue_t queue, bool_t contents ) {
   1480d:	55                   	push   %ebp
   1480e:	89 e5                	mov    %esp,%ebp
   14810:	83 ec 28             	sub    $0x28,%esp
   14813:	8b 45 10             	mov    0x10(%ebp),%eax
   14816:	88 45 e4             	mov    %al,-0x1c(%ebp)

	// report on this queue
	cio_printf( "%s: ", msg );
   14819:	83 ec 08             	sub    $0x8,%esp
   1481c:	ff 75 08             	pushl  0x8(%ebp)
   1481f:	68 c2 b4 01 00       	push   $0x1b4c2
   14824:	e8 fe cc ff ff       	call   11527 <cio_printf>
   14829:	83 c4 10             	add    $0x10,%esp
	if( queue == NULL ) {
   1482c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   14830:	75 15                	jne    14847 <pcb_queue_dump+0x3a>
		cio_puts( "NULL???\n" );
   14832:	83 ec 0c             	sub    $0xc,%esp
   14835:	68 c7 b4 01 00       	push   $0x1b4c7
   1483a:	e8 6e c6 ff ff       	call   10ead <cio_puts>
   1483f:	83 c4 10             	add    $0x10,%esp
		return;
   14842:	e9 d7 00 00 00       	jmp    1491e <pcb_queue_dump+0x111>
	}

	// first, the basic data
	cio_printf( "head %08x tail %08x",
			(uint32_t) queue->head, (uint32_t) queue->tail );
   14847:	8b 45 0c             	mov    0xc(%ebp),%eax
   1484a:	8b 40 04             	mov    0x4(%eax),%eax
	cio_printf( "head %08x tail %08x",
   1484d:	89 c2                	mov    %eax,%edx
			(uint32_t) queue->head, (uint32_t) queue->tail );
   1484f:	8b 45 0c             	mov    0xc(%ebp),%eax
   14852:	8b 00                	mov    (%eax),%eax
	cio_printf( "head %08x tail %08x",
   14854:	83 ec 04             	sub    $0x4,%esp
   14857:	52                   	push   %edx
   14858:	50                   	push   %eax
   14859:	68 d0 b4 01 00       	push   $0x1b4d0
   1485e:	e8 c4 cc ff ff       	call   11527 <cio_printf>
   14863:	83 c4 10             	add    $0x10,%esp

	// next, how the queue is ordered
	cio_printf( " order %s\n",
			queue->order >= N_ORDERINGS ? "????" : ord_str[queue->order] );
   14866:	8b 45 0c             	mov    0xc(%ebp),%eax
   14869:	8b 40 08             	mov    0x8(%eax),%eax
	cio_printf( " order %s\n",
   1486c:	83 f8 03             	cmp    $0x3,%eax
   1486f:	77 14                	ja     14885 <pcb_queue_dump+0x78>
			queue->order >= N_ORDERINGS ? "????" : ord_str[queue->order] );
   14871:	8b 45 0c             	mov    0xc(%ebp),%eax
   14874:	8b 50 08             	mov    0x8(%eax),%edx
	cio_printf( " order %s\n",
   14877:	89 d0                	mov    %edx,%eax
   14879:	c1 e0 02             	shl    $0x2,%eax
   1487c:	01 d0                	add    %edx,%eax
   1487e:	05 d8 b0 01 00       	add    $0x1b0d8,%eax
   14883:	eb 05                	jmp    1488a <pcb_queue_dump+0x7d>
   14885:	b8 e4 b4 01 00       	mov    $0x1b4e4,%eax
   1488a:	83 ec 08             	sub    $0x8,%esp
   1488d:	50                   	push   %eax
   1488e:	68 e9 b4 01 00       	push   $0x1b4e9
   14893:	e8 8f cc ff ff       	call   11527 <cio_printf>
   14898:	83 c4 10             	add    $0x10,%esp

	// if there are members in the queue, dump the first few PIDs
	if( contents && queue->head != NULL ) {
   1489b:	80 7d e4 00          	cmpb   $0x0,-0x1c(%ebp)
   1489f:	74 7d                	je     1491e <pcb_queue_dump+0x111>
   148a1:	8b 45 0c             	mov    0xc(%ebp),%eax
   148a4:	8b 00                	mov    (%eax),%eax
   148a6:	85 c0                	test   %eax,%eax
   148a8:	74 74                	je     1491e <pcb_queue_dump+0x111>
		cio_puts( " PIDs: " );
   148aa:	83 ec 0c             	sub    $0xc,%esp
   148ad:	68 f4 b4 01 00       	push   $0x1b4f4
   148b2:	e8 f6 c5 ff ff       	call   10ead <cio_puts>
   148b7:	83 c4 10             	add    $0x10,%esp
		pcb_t *tmp = queue->head;
   148ba:	8b 45 0c             	mov    0xc(%ebp),%eax
   148bd:	8b 00                	mov    (%eax),%eax
   148bf:	89 45 f4             	mov    %eax,-0xc(%ebp)
		for( int i = 0; i < 5 && tmp != NULL; ++i, tmp = tmp->next ) {
   148c2:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   148c9:	eb 24                	jmp    148ef <pcb_queue_dump+0xe2>
			cio_printf( " [%u]", tmp->pid );
   148cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
   148ce:	8b 40 18             	mov    0x18(%eax),%eax
   148d1:	83 ec 08             	sub    $0x8,%esp
   148d4:	50                   	push   %eax
   148d5:	68 fc b4 01 00       	push   $0x1b4fc
   148da:	e8 48 cc ff ff       	call   11527 <cio_printf>
   148df:	83 c4 10             	add    $0x10,%esp
		for( int i = 0; i < 5 && tmp != NULL; ++i, tmp = tmp->next ) {
   148e2:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   148e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
   148e9:	8b 40 08             	mov    0x8(%eax),%eax
   148ec:	89 45 f4             	mov    %eax,-0xc(%ebp)
   148ef:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
   148f3:	7f 06                	jg     148fb <pcb_queue_dump+0xee>
   148f5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   148f9:	75 d0                	jne    148cb <pcb_queue_dump+0xbe>
		}

		if( tmp != NULL ) {
   148fb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   148ff:	74 10                	je     14911 <pcb_queue_dump+0x104>
			cio_puts( " ..." );
   14901:	83 ec 0c             	sub    $0xc,%esp
   14904:	68 02 b5 01 00       	push   $0x1b502
   14909:	e8 9f c5 ff ff       	call   10ead <cio_puts>
   1490e:	83 c4 10             	add    $0x10,%esp
		}

		cio_putchar( '\n' );
   14911:	83 ec 0c             	sub    $0xc,%esp
   14914:	6a 0a                	push   $0xa
   14916:	e8 52 c4 ff ff       	call   10d6d <cio_putchar>
   1491b:	83 c4 10             	add    $0x10,%esp
	}
}
   1491e:	c9                   	leave  
   1491f:	c3                   	ret    

00014920 <ptable_dump>:
** dump the contents of the "active processes" table
**
** @param msg[in]  Optional message to print
** @param all[in]  Dump all or only part of the relevant data
*/
void ptable_dump( const char *msg, bool_t all ) {
   14920:	55                   	push   %ebp
   14921:	89 e5                	mov    %esp,%ebp
   14923:	53                   	push   %ebx
   14924:	83 ec 24             	sub    $0x24,%esp
   14927:	8b 45 0c             	mov    0xc(%ebp),%eax
   1492a:	88 45 e4             	mov    %al,-0x1c(%ebp)

	if( msg ) {
   1492d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   14931:	74 0e                	je     14941 <ptable_dump+0x21>
		cio_puts( msg );
   14933:	83 ec 0c             	sub    $0xc,%esp
   14936:	ff 75 08             	pushl  0x8(%ebp)
   14939:	e8 6f c5 ff ff       	call   10ead <cio_puts>
   1493e:	83 c4 10             	add    $0x10,%esp
	}
	cio_putchar( ' ' );
   14941:	83 ec 0c             	sub    $0xc,%esp
   14944:	6a 20                	push   $0x20
   14946:	e8 22 c4 ff ff       	call   10d6d <cio_putchar>
   1494b:	83 c4 10             	add    $0x10,%esp

	int used = 0;
   1494e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	int empty = 0;
   14955:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

	register pcb_t *pcb = ptable;
   1495c:	bb 20 20 02 00       	mov    $0x22020,%ebx
	for( int i = 0; i < N_PROCS; ++i ) {
   14961:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   14968:	eb 54                	jmp    149be <ptable_dump+0x9e>
		if( pcb->state == STATE_UNUSED ) {
   1496a:	8b 43 1c             	mov    0x1c(%ebx),%eax
   1496d:	85 c0                	test   %eax,%eax
   1496f:	75 06                	jne    14977 <ptable_dump+0x57>

			// an empty slot
			++empty;
   14971:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   14975:	eb 43                	jmp    149ba <ptable_dump+0x9a>

		} else {

			// a non-empty slot
			++used;
   14977:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

			// if not dumping everything, add commas if needed
			if( !all && used ) {
   1497b:	80 7d e4 00          	cmpb   $0x0,-0x1c(%ebp)
   1497f:	75 13                	jne    14994 <ptable_dump+0x74>
   14981:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   14985:	74 0d                	je     14994 <ptable_dump+0x74>
				cio_putchar( ',' );
   14987:	83 ec 0c             	sub    $0xc,%esp
   1498a:	6a 2c                	push   $0x2c
   1498c:	e8 dc c3 ff ff       	call   10d6d <cio_putchar>
   14991:	83 c4 10             	add    $0x10,%esp
			}

			// report the table slot #
			cio_printf( " #%d:", i );
   14994:	83 ec 08             	sub    $0x8,%esp
   14997:	ff 75 ec             	pushl  -0x14(%ebp)
   1499a:	68 07 b5 01 00       	push   $0x1b507
   1499f:	e8 83 cb ff ff       	call   11527 <cio_printf>
   149a4:	83 c4 10             	add    $0x10,%esp

			// and dump the contents
			pcb_dump( NULL, pcb, all );
   149a7:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
   149ab:	83 ec 04             	sub    $0x4,%esp
   149ae:	50                   	push   %eax
   149af:	53                   	push   %ebx
   149b0:	6a 00                	push   $0x0
   149b2:	e8 17 fd ff ff       	call   146ce <pcb_dump>
   149b7:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < N_PROCS; ++i ) {
   149ba:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   149be:	83 7d ec 18          	cmpl   $0x18,-0x14(%ebp)
   149c2:	7e a6                	jle    1496a <ptable_dump+0x4a>
		}
	}

	// only need this if we're doing one-line output
	if( !all ) {
   149c4:	80 7d e4 00          	cmpb   $0x0,-0x1c(%ebp)
   149c8:	75 0d                	jne    149d7 <ptable_dump+0xb7>
		cio_putchar( '\n' );
   149ca:	83 ec 0c             	sub    $0xc,%esp
   149cd:	6a 0a                	push   $0xa
   149cf:	e8 99 c3 ff ff       	call   10d6d <cio_putchar>
   149d4:	83 c4 10             	add    $0x10,%esp
	}

	// sanity check - make sure we saw the correct number of table slots
	if( (used + empty) != N_PROCS ) {
   149d7:	8b 55 f4             	mov    -0xc(%ebp),%edx
   149da:	8b 45 f0             	mov    -0x10(%ebp),%eax
   149dd:	01 d0                	add    %edx,%eax
   149df:	83 f8 19             	cmp    $0x19,%eax
   149e2:	74 21                	je     14a05 <ptable_dump+0xe5>
		cio_printf( "Table size %d, used %d + empty %d = %d???\n",
   149e4:	8b 55 f4             	mov    -0xc(%ebp),%edx
   149e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
   149ea:	01 d0                	add    %edx,%eax
   149ec:	83 ec 0c             	sub    $0xc,%esp
   149ef:	50                   	push   %eax
   149f0:	ff 75 f0             	pushl  -0x10(%ebp)
   149f3:	ff 75 f4             	pushl  -0xc(%ebp)
   149f6:	6a 19                	push   $0x19
   149f8:	68 10 b5 01 00       	push   $0x1b510
   149fd:	e8 25 cb ff ff       	call   11527 <cio_printf>
   14a02:	83 c4 20             	add    $0x20,%esp
					  N_PROCS, used, empty, used + empty );
	}
}
   14a05:	90                   	nop
   14a06:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   14a09:	c9                   	leave  
   14a0a:	c3                   	ret    

00014a0b <ptable_dump_counts>:
** Name:    ptable_dump_counts
**
** Prints basic information about the process table (number of
** entries, number with each process state, etc.).
*/
void ptable_dump_counts( void ) {
   14a0b:	55                   	push   %ebp
   14a0c:	89 e5                	mov    %esp,%ebp
   14a0e:	57                   	push   %edi
   14a0f:	83 ec 34             	sub    $0x34,%esp
	uint_t nstate[N_STATES] = { 0 };
   14a12:	8d 55 c8             	lea    -0x38(%ebp),%edx
   14a15:	b8 00 00 00 00       	mov    $0x0,%eax
   14a1a:	b9 09 00 00 00       	mov    $0x9,%ecx
   14a1f:	89 d7                	mov    %edx,%edi
   14a21:	f3 ab                	rep stos %eax,%es:(%edi)
	uint_t unknown = 0;
   14a23:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	int n = 0;
   14a2a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	pcb_t *ptr = ptable;
   14a31:	c7 45 ec 20 20 02 00 	movl   $0x22020,-0x14(%ebp)
	while( n < N_PROCS ) {
   14a38:	eb 2a                	jmp    14a64 <ptable_dump_counts+0x59>
		if( ptr->state < 0 || ptr->state >= N_STATES ) {
   14a3a:	8b 45 ec             	mov    -0x14(%ebp),%eax
   14a3d:	8b 40 1c             	mov    0x1c(%eax),%eax
   14a40:	83 f8 08             	cmp    $0x8,%eax
   14a43:	76 06                	jbe    14a4b <ptable_dump_counts+0x40>
			++unknown;
   14a45:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   14a49:	eb 11                	jmp    14a5c <ptable_dump_counts+0x51>
		} else {
			++nstate[ptr->state];
   14a4b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   14a4e:	8b 40 1c             	mov    0x1c(%eax),%eax
   14a51:	8b 54 85 c8          	mov    -0x38(%ebp,%eax,4),%edx
   14a55:	83 c2 01             	add    $0x1,%edx
   14a58:	89 54 85 c8          	mov    %edx,-0x38(%ebp,%eax,4)
		}
		++n;
   14a5c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
		++ptr;
   14a60:	83 45 ec 30          	addl   $0x30,-0x14(%ebp)
	while( n < N_PROCS ) {
   14a64:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   14a68:	7e d0                	jle    14a3a <ptable_dump_counts+0x2f>
	}

	cio_printf( "Ptable: %u ***", unknown );
   14a6a:	83 ec 08             	sub    $0x8,%esp
   14a6d:	ff 75 f4             	pushl  -0xc(%ebp)
   14a70:	68 3b b5 01 00       	push   $0x1b53b
   14a75:	e8 ad ca ff ff       	call   11527 <cio_printf>
   14a7a:	83 c4 10             	add    $0x10,%esp
	for( n = 0; n < N_STATES; ++n ) {
   14a7d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   14a84:	eb 34                	jmp    14aba <ptable_dump_counts+0xaf>
		if( nstate[n] ) {
   14a86:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14a89:	8b 44 85 c8          	mov    -0x38(%ebp,%eax,4),%eax
   14a8d:	85 c0                	test   %eax,%eax
   14a8f:	74 25                	je     14ab6 <ptable_dump_counts+0xab>
			cio_printf( " %u %s", nstate[n],
					state_str[n] != NULL ? state_str[n] : "???" );
   14a91:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14a94:	c1 e0 02             	shl    $0x2,%eax
   14a97:	8d 90 a0 b0 01 00    	lea    0x1b0a0(%eax),%edx
			cio_printf( " %u %s", nstate[n],
   14a9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14aa0:	8b 44 85 c8          	mov    -0x38(%ebp,%eax,4),%eax
   14aa4:	83 ec 04             	sub    $0x4,%esp
   14aa7:	52                   	push   %edx
   14aa8:	50                   	push   %eax
   14aa9:	68 4a b5 01 00       	push   $0x1b54a
   14aae:	e8 74 ca ff ff       	call   11527 <cio_printf>
   14ab3:	83 c4 10             	add    $0x10,%esp
	for( n = 0; n < N_STATES; ++n ) {
   14ab6:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   14aba:	83 7d f0 08          	cmpl   $0x8,-0x10(%ebp)
   14abe:	7e c6                	jle    14a86 <ptable_dump_counts+0x7b>
		}
	}
	cio_putchar( '\n' );
   14ac0:	83 ec 0c             	sub    $0xc,%esp
   14ac3:	6a 0a                	push   $0xa
   14ac5:	e8 a3 c2 ff ff       	call   10d6d <cio_putchar>
   14aca:	83 c4 10             	add    $0x10,%esp
}
   14acd:	90                   	nop
   14ace:	8b 7d fc             	mov    -0x4(%ebp),%edi
   14ad1:	c9                   	leave  
   14ad2:	c3                   	ret    

00014ad3 <sio_isr>:
** events (as described by the SIO controller).
**
** @param vector   The interrupt vector number for this interrupt
** @param ecode    The error code associated with this interrupt
*/
static void sio_isr( int vector, int ecode ) {
   14ad3:	55                   	push   %ebp
   14ad4:	89 e5                	mov    %esp,%ebp
   14ad6:	83 ec 58             	sub    $0x58,%esp
   14ad9:	c7 45 e8 fa 03 00 00 	movl   $0x3fa,-0x18(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14ae0:	8b 45 e8             	mov    -0x18(%ebp),%eax
   14ae3:	89 c2                	mov    %eax,%edx
   14ae5:	ec                   	in     (%dx),%al
   14ae6:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
   14ae9:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
	//

	for(;;) {

		// get the "pending event" indicator
		int iir = inb( UA4_IIR ) & UA4_IIR_INT_PRI_MASK;
   14aed:	0f b6 c0             	movzbl %al,%eax
   14af0:	83 e0 0f             	and    $0xf,%eax
   14af3:	89 45 f0             	mov    %eax,-0x10(%ebp)

		// process this event
		switch( iir ) {
   14af6:	83 7d f0 0c          	cmpl   $0xc,-0x10(%ebp)
   14afa:	0f 87 95 02 00 00    	ja     14d95 <sio_isr+0x2c2>
   14b00:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14b03:	c1 e0 02             	shl    $0x2,%eax
   14b06:	05 3c b7 01 00       	add    $0x1b73c,%eax
   14b0b:	8b 00                	mov    (%eax),%eax
   14b0d:	ff e0                	jmp    *%eax
   14b0f:	c7 45 e0 fd 03 00 00 	movl   $0x3fd,-0x20(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14b16:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14b19:	89 c2                	mov    %eax,%edx
   14b1b:	ec                   	in     (%dx),%al
   14b1c:	88 45 df             	mov    %al,-0x21(%ebp)
	return data;
   14b1f:	0f b6 45 df          	movzbl -0x21(%ebp),%eax

		case UA4_IIR_LINE_STATUS:
			// shouldn't happen, but just in case....
			cio_printf( "** SIO int, LSR = %02x\n", inb(UA4_LSR) );
   14b23:	0f b6 c0             	movzbl %al,%eax
   14b26:	83 ec 08             	sub    $0x8,%esp
   14b29:	50                   	push   %eax
   14b2a:	68 78 b6 01 00       	push   $0x1b678
   14b2f:	e8 f3 c9 ff ff       	call   11527 <cio_printf>
   14b34:	83 c4 10             	add    $0x10,%esp
			break;
   14b37:	e9 b6 02 00 00       	jmp    14df2 <sio_isr+0x31f>
   14b3c:	c7 45 d8 f8 03 00 00 	movl   $0x3f8,-0x28(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14b43:	8b 45 d8             	mov    -0x28(%ebp),%eax
   14b46:	89 c2                	mov    %eax,%edx
   14b48:	ec                   	in     (%dx),%al
   14b49:	88 45 d7             	mov    %al,-0x29(%ebp)
	return data;
   14b4c:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
		case UA4_IIR_RX:
#if TRACING_SIO_ISR
	cio_puts( " RX" );
#endif
			// get the character
			ch = inb( UA4_RXD );
   14b50:	0f b6 c0             	movzbl %al,%eax
   14b53:	89 45 f4             	mov    %eax,-0xc(%ebp)
			if( ch == '\r' ) {    // map CR to LF
   14b56:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
   14b5a:	75 07                	jne    14b63 <sio_isr+0x90>
				ch = '\n';
   14b5c:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
			// If there is a waiting process, this must be
			// the first input character; give it to that
			// process and awaken the process.
			//

			if( !QEMPTY(QNAME) ) {
   14b63:	a1 04 20 02 00       	mov    0x22004,%eax
   14b68:	83 ec 0c             	sub    $0xc,%esp
   14b6b:	50                   	push   %eax
   14b6c:	e8 cd f2 ff ff       	call   13e3e <pcb_queue_empty>
   14b71:	83 c4 10             	add    $0x10,%esp
   14b74:	84 c0                	test   %al,%al
   14b76:	0f 85 d0 00 00 00    	jne    14c4c <sio_isr+0x179>
				PCBTYPE *pcb;

				QDEQUE( QNAME, pcb );
   14b7c:	a1 04 20 02 00       	mov    0x22004,%eax
   14b81:	83 ec 08             	sub    $0x8,%esp
   14b84:	8d 55 b0             	lea    -0x50(%ebp),%edx
   14b87:	52                   	push   %edx
   14b88:	50                   	push   %eax
   14b89:	e8 4e f5 ff ff       	call   140dc <pcb_queue_remove>
   14b8e:	83 c4 10             	add    $0x10,%esp
   14b91:	85 c0                	test   %eax,%eax
   14b93:	74 3b                	je     14bd0 <sio_isr+0xfd>
   14b95:	83 ec 04             	sub    $0x4,%esp
   14b98:	68 90 b6 01 00       	push   $0x1b690
   14b9d:	6a 00                	push   $0x0
   14b9f:	68 ac 00 00 00       	push   $0xac
   14ba4:	68 c8 b6 01 00       	push   $0x1b6c8
   14ba9:	68 cc b7 01 00       	push   $0x1b7cc
   14bae:	68 ce b6 01 00       	push   $0x1b6ce
   14bb3:	68 00 00 02 00       	push   $0x20000
   14bb8:	e8 4a db ff ff       	call   12707 <sprint>
   14bbd:	83 c4 20             	add    $0x20,%esp
   14bc0:	83 ec 0c             	sub    $0xc,%esp
   14bc3:	68 00 00 02 00       	push   $0x20000
   14bc8:	e8 ba d8 ff ff       	call   12487 <kpanic>
   14bcd:	83 c4 10             	add    $0x10,%esp
				// make sure we got a non-NULL result
				assert( pcb );
   14bd0:	8b 45 b0             	mov    -0x50(%ebp),%eax
   14bd3:	85 c0                	test   %eax,%eax
   14bd5:	75 3b                	jne    14c12 <sio_isr+0x13f>
   14bd7:	83 ec 04             	sub    $0x4,%esp
   14bda:	68 e4 b6 01 00       	push   $0x1b6e4
   14bdf:	6a 00                	push   $0x0
   14be1:	68 ae 00 00 00       	push   $0xae
   14be6:	68 c8 b6 01 00       	push   $0x1b6c8
   14beb:	68 cc b7 01 00       	push   $0x1b7cc
   14bf0:	68 ce b6 01 00       	push   $0x1b6ce
   14bf5:	68 00 00 02 00       	push   $0x20000
   14bfa:	e8 08 db ff ff       	call   12707 <sprint>
   14bff:	83 c4 20             	add    $0x20,%esp
   14c02:	83 ec 0c             	sub    $0xc,%esp
   14c05:	68 00 00 02 00       	push   $0x20000
   14c0a:	e8 78 d8 ff ff       	call   12487 <kpanic>
   14c0f:	83 c4 10             	add    $0x10,%esp

				// return char via arg #2 and count in EAX
				char *buf = (char *) ARG(pcb,2);
   14c12:	8b 45 b0             	mov    -0x50(%ebp),%eax
   14c15:	8b 00                	mov    (%eax),%eax
   14c17:	83 c0 48             	add    $0x48,%eax
   14c1a:	83 c0 08             	add    $0x8,%eax
   14c1d:	8b 00                	mov    (%eax),%eax
   14c1f:	89 45 ec             	mov    %eax,-0x14(%ebp)
				*buf = ch & 0xff;
   14c22:	8b 45 f4             	mov    -0xc(%ebp),%eax
   14c25:	89 c2                	mov    %eax,%edx
   14c27:	8b 45 ec             	mov    -0x14(%ebp),%eax
   14c2a:	88 10                	mov    %dl,(%eax)
				RET(pcb) = 1;
   14c2c:	8b 45 b0             	mov    -0x50(%ebp),%eax
   14c2f:	8b 00                	mov    (%eax),%eax
   14c31:	c7 40 30 01 00 00 00 	movl   $0x1,0x30(%eax)
				SCHED( pcb );
   14c38:	8b 45 b0             	mov    -0x50(%ebp),%eax
   14c3b:	83 ec 0c             	sub    $0xc,%esp
   14c3e:	50                   	push   %eax
   14c3f:	e8 8b f7 ff ff       	call   143cf <schedule>
   14c44:	83 c4 10             	add    $0x10,%esp
				}

#ifdef QNAME
			}
#endif /* QNAME */
			break;
   14c47:	e9 a5 01 00 00       	jmp    14df1 <sio_isr+0x31e>
				if( incount < BUF_SIZE ) {
   14c4c:	a1 88 e9 01 00       	mov    0x1e988,%eax
   14c51:	3d ff 07 00 00       	cmp    $0x7ff,%eax
   14c56:	0f 87 95 01 00 00    	ja     14df1 <sio_isr+0x31e>
					*inlast++ = ch;
   14c5c:	a1 80 e9 01 00       	mov    0x1e980,%eax
   14c61:	8d 50 01             	lea    0x1(%eax),%edx
   14c64:	89 15 80 e9 01 00    	mov    %edx,0x1e980
   14c6a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   14c6d:	88 10                	mov    %dl,(%eax)
					++incount;
   14c6f:	a1 88 e9 01 00       	mov    0x1e988,%eax
   14c74:	83 c0 01             	add    $0x1,%eax
   14c77:	a3 88 e9 01 00       	mov    %eax,0x1e988
			break;
   14c7c:	e9 70 01 00 00       	jmp    14df1 <sio_isr+0x31e>
   14c81:	c7 45 d0 f8 03 00 00 	movl   $0x3f8,-0x30(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14c88:	8b 45 d0             	mov    -0x30(%ebp),%eax
   14c8b:	89 c2                	mov    %eax,%edx
   14c8d:	ec                   	in     (%dx),%al
   14c8e:	88 45 cf             	mov    %al,-0x31(%ebp)
	return data;
   14c91:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax

		case UA5_IIR_RX_FIFO:
			// shouldn't happen, but just in case....
			ch = inb( UA4_RXD );
   14c95:	0f b6 c0             	movzbl %al,%eax
   14c98:	89 45 f4             	mov    %eax,-0xc(%ebp)
			cio_printf( "** SIO FIFO timeout, RXD = %02x\n", ch );
   14c9b:	83 ec 08             	sub    $0x8,%esp
   14c9e:	ff 75 f4             	pushl  -0xc(%ebp)
   14ca1:	68 e8 b6 01 00       	push   $0x1b6e8
   14ca6:	e8 7c c8 ff ff       	call   11527 <cio_printf>
   14cab:	83 c4 10             	add    $0x10,%esp
			break;
   14cae:	e9 3f 01 00 00       	jmp    14df2 <sio_isr+0x31f>
		case UA4_IIR_TX:
#if TRACING_SIO_ISR
	cio_puts( " TX" );
#endif
			// if there is another character, send it
			if( sending && outcount > 0 ) {
   14cb3:	a1 ac f1 01 00       	mov    0x1f1ac,%eax
   14cb8:	85 c0                	test   %eax,%eax
   14cba:	74 5d                	je     14d19 <sio_isr+0x246>
   14cbc:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   14cc1:	85 c0                	test   %eax,%eax
   14cc3:	74 54                	je     14d19 <sio_isr+0x246>
#if TRACING_SIO_ISR
	cio_printf( " ch %02x", *outnext );
#endif
				outb( UA4_TXD, *outnext );
   14cc5:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   14cca:	0f b6 00             	movzbl (%eax),%eax
   14ccd:	0f b6 c0             	movzbl %al,%eax
   14cd0:	c7 45 c8 f8 03 00 00 	movl   $0x3f8,-0x38(%ebp)
   14cd7:	88 45 c7             	mov    %al,-0x39(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   14cda:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   14cde:	8b 55 c8             	mov    -0x38(%ebp),%edx
   14ce1:	ee                   	out    %al,(%dx)
				++outnext;
   14ce2:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   14ce7:	83 c0 01             	add    $0x1,%eax
   14cea:	a3 a4 f1 01 00       	mov    %eax,0x1f1a4
				// wrap around if necessary
				if( outnext >= (outbuffer + BUF_SIZE) ) {
   14cef:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   14cf4:	ba a0 f1 01 00       	mov    $0x1f1a0,%edx
   14cf9:	39 d0                	cmp    %edx,%eax
   14cfb:	72 0a                	jb     14d07 <sio_isr+0x234>
					outnext = outbuffer;
   14cfd:	c7 05 a4 f1 01 00 a0 	movl   $0x1e9a0,0x1f1a4
   14d04:	e9 01 00 
				}
				--outcount;
   14d07:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   14d0c:	83 e8 01             	sub    $0x1,%eax
   14d0f:	a3 a8 f1 01 00       	mov    %eax,0x1f1a8
				outlast = outnext = outbuffer;
				sending = 0;
				// disable TX interrupts
				sio_disable( SIO_TX );
			}
			break;
   14d14:	e9 d9 00 00 00       	jmp    14df2 <sio_isr+0x31f>
				outcount = 0;
   14d19:	c7 05 a8 f1 01 00 00 	movl   $0x0,0x1f1a8
   14d20:	00 00 00 
				outlast = outnext = outbuffer;
   14d23:	c7 05 a4 f1 01 00 a0 	movl   $0x1e9a0,0x1f1a4
   14d2a:	e9 01 00 
   14d2d:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   14d32:	a3 a0 f1 01 00       	mov    %eax,0x1f1a0
				sending = 0;
   14d37:	c7 05 ac f1 01 00 00 	movl   $0x0,0x1f1ac
   14d3e:	00 00 00 
				sio_disable( SIO_TX );
   14d41:	83 ec 0c             	sub    $0xc,%esp
   14d44:	6a 01                	push   $0x1
   14d46:	e8 99 02 00 00       	call   14fe4 <sio_disable>
   14d4b:	83 c4 10             	add    $0x10,%esp
			break;
   14d4e:	e9 9f 00 00 00       	jmp    14df2 <sio_isr+0x31f>
   14d53:	c7 45 c0 20 00 00 00 	movl   $0x20,-0x40(%ebp)
   14d5a:	c6 45 bf 20          	movb   $0x20,-0x41(%ebp)
   14d5e:	0f b6 45 bf          	movzbl -0x41(%ebp),%eax
   14d62:	8b 55 c0             	mov    -0x40(%ebp),%edx
   14d65:	ee                   	out    %al,(%dx)
#if TRACING_SIO_ISR
	cio_puts( " EOI\n" );
#endif
			// nothing to do - tell the PIC we're done
			outb( PIC1_CMD, PIC_EOI );
			return;
   14d66:	e9 8c 00 00 00       	jmp    14df7 <sio_isr+0x324>
   14d6b:	c7 45 b8 fe 03 00 00 	movl   $0x3fe,-0x48(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14d72:	8b 45 b8             	mov    -0x48(%ebp),%eax
   14d75:	89 c2                	mov    %eax,%edx
   14d77:	ec                   	in     (%dx),%al
   14d78:	88 45 b7             	mov    %al,-0x49(%ebp)
	return data;
   14d7b:	0f b6 45 b7          	movzbl -0x49(%ebp),%eax

		case UA4_IIR_MODEM_STATUS:
			// shouldn't happen, but just in case....
			cio_printf( "** SIO int, MSR = %02x\n", inb(UA4_MSR) );
   14d7f:	0f b6 c0             	movzbl %al,%eax
   14d82:	83 ec 08             	sub    $0x8,%esp
   14d85:	50                   	push   %eax
   14d86:	68 09 b7 01 00       	push   $0x1b709
   14d8b:	e8 97 c7 ff ff       	call   11527 <cio_printf>
   14d90:	83 c4 10             	add    $0x10,%esp
			break;
   14d93:	eb 5d                	jmp    14df2 <sio_isr+0x31f>

		default:
			// uh-oh....
			sprint( b256, "sio isr: IIR %02x\n", ((uint32_t) iir) & 0xff );
   14d95:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14d98:	0f b6 c0             	movzbl %al,%eax
   14d9b:	83 ec 04             	sub    $0x4,%esp
   14d9e:	50                   	push   %eax
   14d9f:	68 21 b7 01 00       	push   $0x1b721
   14da4:	68 00 02 02 00       	push   $0x20200
   14da9:	e8 59 d9 ff ff       	call   12707 <sprint>
   14dae:	83 c4 10             	add    $0x10,%esp
			PANIC( 0, b256 );
   14db1:	83 ec 04             	sub    $0x4,%esp
   14db4:	68 34 b7 01 00       	push   $0x1b734
   14db9:	6a 00                	push   $0x0
   14dbb:	68 fe 00 00 00       	push   $0xfe
   14dc0:	68 c8 b6 01 00       	push   $0x1b6c8
   14dc5:	68 cc b7 01 00       	push   $0x1b7cc
   14dca:	68 ce b6 01 00       	push   $0x1b6ce
   14dcf:	68 00 00 02 00       	push   $0x20000
   14dd4:	e8 2e d9 ff ff       	call   12707 <sprint>
   14dd9:	83 c4 20             	add    $0x20,%esp
   14ddc:	83 ec 0c             	sub    $0xc,%esp
   14ddf:	68 00 00 02 00       	push   $0x20000
   14de4:	e8 9e d6 ff ff       	call   12487 <kpanic>
   14de9:	83 c4 10             	add    $0x10,%esp
   14dec:	e9 e8 fc ff ff       	jmp    14ad9 <sio_isr+0x6>
			break;
   14df1:	90                   	nop
	for(;;) {
   14df2:	e9 e2 fc ff ff       	jmp    14ad9 <sio_isr+0x6>
	
	}

	// should never reach this point!
	assert( false );
}
   14df7:	c9                   	leave  
   14df8:	c3                   	ret    

00014df9 <sio_init>:
/**
** sio_init()
**
** Initialize the UART chip.
*/
void sio_init( void ) {
   14df9:	55                   	push   %ebp
   14dfa:	89 e5                	mov    %esp,%ebp
   14dfc:	83 ec 68             	sub    $0x68,%esp

#if TRACING_INIT
	cio_puts( " Sio" );
   14dff:	83 ec 0c             	sub    $0xc,%esp
   14e02:	68 70 b7 01 00       	push   $0x1b770
   14e07:	e8 a1 c0 ff ff       	call   10ead <cio_puts>
   14e0c:	83 c4 10             	add    $0x10,%esp

	/*
	** Initialize SIO variables.
	*/

	memclr( (void *) inbuffer, sizeof(inbuffer) );
   14e0f:	83 ec 08             	sub    $0x8,%esp
   14e12:	68 00 08 00 00       	push   $0x800
   14e17:	68 80 e1 01 00       	push   $0x1e180
   14e1c:	e8 63 d7 ff ff       	call   12584 <memclr>
   14e21:	83 c4 10             	add    $0x10,%esp
	inlast = innext = inbuffer;
   14e24:	c7 05 84 e9 01 00 80 	movl   $0x1e180,0x1e984
   14e2b:	e1 01 00 
   14e2e:	a1 84 e9 01 00       	mov    0x1e984,%eax
   14e33:	a3 80 e9 01 00       	mov    %eax,0x1e980
	incount = 0;
   14e38:	c7 05 88 e9 01 00 00 	movl   $0x0,0x1e988
   14e3f:	00 00 00 

	memclr( (void *) outbuffer, sizeof(outbuffer) );
   14e42:	83 ec 08             	sub    $0x8,%esp
   14e45:	68 00 08 00 00       	push   $0x800
   14e4a:	68 a0 e9 01 00       	push   $0x1e9a0
   14e4f:	e8 30 d7 ff ff       	call   12584 <memclr>
   14e54:	83 c4 10             	add    $0x10,%esp
	outlast = outnext = outbuffer;
   14e57:	c7 05 a4 f1 01 00 a0 	movl   $0x1e9a0,0x1f1a4
   14e5e:	e9 01 00 
   14e61:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   14e66:	a3 a0 f1 01 00       	mov    %eax,0x1f1a0
	outcount = 0;
   14e6b:	c7 05 a8 f1 01 00 00 	movl   $0x0,0x1f1a8
   14e72:	00 00 00 
	sending = 0;
   14e75:	c7 05 ac f1 01 00 00 	movl   $0x0,0x1f1ac
   14e7c:	00 00 00 
   14e7f:	c7 45 a4 fa 03 00 00 	movl   $0x3fa,-0x5c(%ebp)
   14e86:	c6 45 a3 20          	movb   $0x20,-0x5d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   14e8a:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
   14e8e:	8b 55 a4             	mov    -0x5c(%ebp),%edx
   14e91:	ee                   	out    %al,(%dx)
   14e92:	c7 45 ac fa 03 00 00 	movl   $0x3fa,-0x54(%ebp)
   14e99:	c6 45 ab 00          	movb   $0x0,-0x55(%ebp)
   14e9d:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
   14ea1:	8b 55 ac             	mov    -0x54(%ebp),%edx
   14ea4:	ee                   	out    %al,(%dx)
   14ea5:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
   14eac:	c6 45 b3 01          	movb   $0x1,-0x4d(%ebp)
   14eb0:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
   14eb4:	8b 55 b4             	mov    -0x4c(%ebp),%edx
   14eb7:	ee                   	out    %al,(%dx)
   14eb8:	c7 45 bc fa 03 00 00 	movl   $0x3fa,-0x44(%ebp)
   14ebf:	c6 45 bb 03          	movb   $0x3,-0x45(%ebp)
   14ec3:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
   14ec7:	8b 55 bc             	mov    -0x44(%ebp),%edx
   14eca:	ee                   	out    %al,(%dx)
   14ecb:	c7 45 c4 fa 03 00 00 	movl   $0x3fa,-0x3c(%ebp)
   14ed2:	c6 45 c3 07          	movb   $0x7,-0x3d(%ebp)
   14ed6:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
   14eda:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   14edd:	ee                   	out    %al,(%dx)
   14ede:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
   14ee5:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
   14ee9:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
   14eed:	8b 55 cc             	mov    -0x34(%ebp),%edx
   14ef0:	ee                   	out    %al,(%dx)
	** note that we leave them disabled; sio_enable() must be
	** called to switch them back on
	*/

	outb( UA4_IER, 0 );
	ier = 0;
   14ef1:	c6 05 b0 f1 01 00 00 	movb   $0x0,0x1f1b0
   14ef8:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
   14eff:	c6 45 d3 80          	movb   $0x80,-0x2d(%ebp)
   14f03:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
   14f07:	8b 55 d4             	mov    -0x2c(%ebp),%edx
   14f0a:	ee                   	out    %al,(%dx)
   14f0b:	c7 45 dc f8 03 00 00 	movl   $0x3f8,-0x24(%ebp)
   14f12:	c6 45 db 0c          	movb   $0xc,-0x25(%ebp)
   14f16:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   14f1a:	8b 55 dc             	mov    -0x24(%ebp),%edx
   14f1d:	ee                   	out    %al,(%dx)
   14f1e:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
   14f25:	c6 45 e3 00          	movb   $0x0,-0x1d(%ebp)
   14f29:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
   14f2d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   14f30:	ee                   	out    %al,(%dx)
   14f31:	c7 45 ec fb 03 00 00 	movl   $0x3fb,-0x14(%ebp)
   14f38:	c6 45 eb 03          	movb   $0x3,-0x15(%ebp)
   14f3c:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   14f40:	8b 55 ec             	mov    -0x14(%ebp),%edx
   14f43:	ee                   	out    %al,(%dx)
   14f44:	c7 45 f4 fc 03 00 00 	movl   $0x3fc,-0xc(%ebp)
   14f4b:	c6 45 f3 0b          	movb   $0xb,-0xd(%ebp)
   14f4f:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   14f53:	8b 55 f4             	mov    -0xc(%ebp),%edx
   14f56:	ee                   	out    %al,(%dx)

	/*
	** Install our ISR
	*/

	install_isr( VEC_COM1, sio_isr );
   14f57:	83 ec 08             	sub    $0x8,%esp
   14f5a:	68 d3 4a 01 00       	push   $0x14ad3
   14f5f:	6a 24                	push   $0x24
   14f61:	e8 20 08 00 00       	call   15786 <install_isr>
   14f66:	83 c4 10             	add    $0x10,%esp
}
   14f69:	90                   	nop
   14f6a:	c9                   	leave  
   14f6b:	c3                   	ret    

00014f6c <sio_enable>:
**
** @param which   Bit mask indicating which interrupt(s) to enable
**
** @return the prior IER setting
*/
uint8_t sio_enable( uint8_t which ) {
   14f6c:	55                   	push   %ebp
   14f6d:	89 e5                	mov    %esp,%ebp
   14f6f:	83 ec 14             	sub    $0x14,%esp
   14f72:	8b 45 08             	mov    0x8(%ebp),%eax
   14f75:	88 45 ec             	mov    %al,-0x14(%ebp)
	uint8_t old;

	// remember the current status

	old = ier;
   14f78:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14f7f:	88 45 ff             	mov    %al,-0x1(%ebp)

	// figure out what to enable

	if( which & SIO_TX ) {
   14f82:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   14f86:	83 e0 01             	and    $0x1,%eax
   14f89:	85 c0                	test   %eax,%eax
   14f8b:	74 0f                	je     14f9c <sio_enable+0x30>
		ier |= UA4_IER_TX_IE;
   14f8d:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14f94:	83 c8 02             	or     $0x2,%eax
   14f97:	a2 b0 f1 01 00       	mov    %al,0x1f1b0
	}

	if( which & SIO_RX ) {
   14f9c:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   14fa0:	83 e0 02             	and    $0x2,%eax
   14fa3:	85 c0                	test   %eax,%eax
   14fa5:	74 0f                	je     14fb6 <sio_enable+0x4a>
		ier |= UA4_IER_RX_IE;
   14fa7:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14fae:	83 c8 01             	or     $0x1,%eax
   14fb1:	a2 b0 f1 01 00       	mov    %al,0x1f1b0
	}

	// if there was a change, make it

	if( old != ier ) {
   14fb6:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14fbd:	38 45 ff             	cmp    %al,-0x1(%ebp)
   14fc0:	74 1c                	je     14fde <sio_enable+0x72>
		outb( UA4_IER, ier );
   14fc2:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14fc9:	0f b6 c0             	movzbl %al,%eax
   14fcc:	c7 45 f8 f9 03 00 00 	movl   $0x3f9,-0x8(%ebp)
   14fd3:	88 45 f7             	mov    %al,-0x9(%ebp)
   14fd6:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
   14fda:	8b 55 f8             	mov    -0x8(%ebp),%edx
   14fdd:	ee                   	out    %al,(%dx)
	}

	// return the prior settings

	return( old );
   14fde:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
   14fe2:	c9                   	leave  
   14fe3:	c3                   	ret    

00014fe4 <sio_disable>:
**
** @param which   Bit mask indicating which interrupt(s) to disable
**
** @return the prior IER setting
*/
uint8_t sio_disable( uint8_t which ) {
   14fe4:	55                   	push   %ebp
   14fe5:	89 e5                	mov    %esp,%ebp
   14fe7:	83 ec 14             	sub    $0x14,%esp
   14fea:	8b 45 08             	mov    0x8(%ebp),%eax
   14fed:	88 45 ec             	mov    %al,-0x14(%ebp)
	uint8_t old;

	// remember the current status

	old = ier;
   14ff0:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   14ff7:	88 45 ff             	mov    %al,-0x1(%ebp)

	// figure out what to disable

	if( which & SIO_TX ) {
   14ffa:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   14ffe:	83 e0 01             	and    $0x1,%eax
   15001:	85 c0                	test   %eax,%eax
   15003:	74 0f                	je     15014 <sio_disable+0x30>
		ier &= ~UA4_IER_TX_IE;
   15005:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   1500c:	83 e0 fd             	and    $0xfffffffd,%eax
   1500f:	a2 b0 f1 01 00       	mov    %al,0x1f1b0
	}

	if( which & SIO_RX ) {
   15014:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   15018:	83 e0 02             	and    $0x2,%eax
   1501b:	85 c0                	test   %eax,%eax
   1501d:	74 0f                	je     1502e <sio_disable+0x4a>
		ier &= ~UA4_IER_RX_IE;
   1501f:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   15026:	83 e0 fe             	and    $0xfffffffe,%eax
   15029:	a2 b0 f1 01 00       	mov    %al,0x1f1b0
	}

	// if there was a change, make it

	if( old != ier ) {
   1502e:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   15035:	38 45 ff             	cmp    %al,-0x1(%ebp)
   15038:	74 1c                	je     15056 <sio_disable+0x72>
		outb( UA4_IER, ier );
   1503a:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   15041:	0f b6 c0             	movzbl %al,%eax
   15044:	c7 45 f8 f9 03 00 00 	movl   $0x3f9,-0x8(%ebp)
   1504b:	88 45 f7             	mov    %al,-0x9(%ebp)
   1504e:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
   15052:	8b 55 f8             	mov    -0x8(%ebp),%edx
   15055:	ee                   	out    %al,(%dx)
	}

	// return the prior settings

	return( old );
   15056:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
   1505a:	c9                   	leave  
   1505b:	c3                   	ret    

0001505c <sio_flush>:
**
** Flush the SIO input and/or output.
**
** @param which  Bit mask indicating which queue(s) to flush.
*/
void sio_flush( uint8_t which ) {
   1505c:	55                   	push   %ebp
   1505d:	89 e5                	mov    %esp,%ebp
   1505f:	83 ec 24             	sub    $0x24,%esp
   15062:	8b 45 08             	mov    0x8(%ebp),%eax
   15065:	88 45 dc             	mov    %al,-0x24(%ebp)

	if( (which & SIO_RX) != 0 ) {
   15068:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
   1506c:	83 e0 02             	and    $0x2,%eax
   1506f:	85 c0                	test   %eax,%eax
   15071:	74 69                	je     150dc <sio_flush+0x80>
		// empty the queue
		incount = 0;
   15073:	c7 05 88 e9 01 00 00 	movl   $0x0,0x1e988
   1507a:	00 00 00 
		inlast = innext = inbuffer;
   1507d:	c7 05 84 e9 01 00 80 	movl   $0x1e180,0x1e984
   15084:	e1 01 00 
   15087:	a1 84 e9 01 00       	mov    0x1e984,%eax
   1508c:	a3 80 e9 01 00       	mov    %eax,0x1e980
   15091:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   15098:	8b 45 f8             	mov    -0x8(%ebp),%eax
   1509b:	89 c2                	mov    %eax,%edx
   1509d:	ec                   	in     (%dx),%al
   1509e:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
   150a1:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax

		// discard any characters in the receiver FIFO
		uint8_t lsr = inb( UA4_LSR );
   150a5:	88 45 ff             	mov    %al,-0x1(%ebp)
		while( (lsr & UA4_LSR_RXDA) != 0 ) {
   150a8:	eb 27                	jmp    150d1 <sio_flush+0x75>
   150aa:	c7 45 e8 f8 03 00 00 	movl   $0x3f8,-0x18(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   150b1:	8b 45 e8             	mov    -0x18(%ebp),%eax
   150b4:	89 c2                	mov    %eax,%edx
   150b6:	ec                   	in     (%dx),%al
   150b7:	88 45 e7             	mov    %al,-0x19(%ebp)
   150ba:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
   150c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
   150c4:	89 c2                	mov    %eax,%edx
   150c6:	ec                   	in     (%dx),%al
   150c7:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
   150ca:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
			(void) inb( UA4_RXD );
			lsr = inb( UA4_LSR );
   150ce:	88 45 ff             	mov    %al,-0x1(%ebp)
		while( (lsr & UA4_LSR_RXDA) != 0 ) {
   150d1:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
   150d5:	83 e0 01             	and    $0x1,%eax
   150d8:	85 c0                	test   %eax,%eax
   150da:	75 ce                	jne    150aa <sio_flush+0x4e>
		}
	}

	if( (which & SIO_TX) != 0 ) {
   150dc:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
   150e0:	83 e0 01             	and    $0x1,%eax
   150e3:	85 c0                	test   %eax,%eax
   150e5:	74 28                	je     1510f <sio_flush+0xb3>
		// empty the queue
		outcount = 0;
   150e7:	c7 05 a8 f1 01 00 00 	movl   $0x0,0x1f1a8
   150ee:	00 00 00 
		outlast = outnext = outbuffer;
   150f1:	c7 05 a4 f1 01 00 a0 	movl   $0x1e9a0,0x1f1a4
   150f8:	e9 01 00 
   150fb:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   15100:	a3 a0 f1 01 00       	mov    %eax,0x1f1a0

		// terminate any in-progress send operation
		sending = 0;
   15105:	c7 05 ac f1 01 00 00 	movl   $0x0,0x1f1ac
   1510c:	00 00 00 
	}
}
   1510f:	90                   	nop
   15110:	c9                   	leave  
   15111:	c3                   	ret    

00015112 <sio_inq_length>:
**
** usage:    int num = sio_inq_length()
**
** @return the count of characters still in the input queue
*/
int sio_inq_length( void ) {
   15112:	55                   	push   %ebp
   15113:	89 e5                	mov    %esp,%ebp
	return( incount );
   15115:	a1 88 e9 01 00       	mov    0x1e988,%eax
}
   1511a:	5d                   	pop    %ebp
   1511b:	c3                   	ret    

0001511c <sio_readc>:
**
** usage:    int ch = sio_readc()
**
** @return the next character, or -1 if no character is available
*/
int sio_readc( void ) {
   1511c:	55                   	push   %ebp
   1511d:	89 e5                	mov    %esp,%ebp
   1511f:	83 ec 10             	sub    $0x10,%esp
	int ch;

	// assume there is no character available
	ch = -1;
   15122:	c7 45 fc ff ff ff ff 	movl   $0xffffffff,-0x4(%ebp)

	// 
	// If there is a character, return it
	//

	if( incount > 0 ) {
   15129:	a1 88 e9 01 00       	mov    0x1e988,%eax
   1512e:	85 c0                	test   %eax,%eax
   15130:	74 46                	je     15178 <sio_readc+0x5c>

		// take it out of the input buffer
		ch = ((int)(*innext++)) & 0xff;
   15132:	a1 84 e9 01 00       	mov    0x1e984,%eax
   15137:	8d 50 01             	lea    0x1(%eax),%edx
   1513a:	89 15 84 e9 01 00    	mov    %edx,0x1e984
   15140:	0f b6 00             	movzbl (%eax),%eax
   15143:	0f be c0             	movsbl %al,%eax
   15146:	25 ff 00 00 00       	and    $0xff,%eax
   1514b:	89 45 fc             	mov    %eax,-0x4(%ebp)
		--incount;
   1514e:	a1 88 e9 01 00       	mov    0x1e988,%eax
   15153:	83 e8 01             	sub    $0x1,%eax
   15156:	a3 88 e9 01 00       	mov    %eax,0x1e988

		// reset the buffer variables if this was the last one
		if( incount < 1 ) {
   1515b:	a1 88 e9 01 00       	mov    0x1e988,%eax
   15160:	85 c0                	test   %eax,%eax
   15162:	75 14                	jne    15178 <sio_readc+0x5c>
			inlast = innext = inbuffer;
   15164:	c7 05 84 e9 01 00 80 	movl   $0x1e180,0x1e984
   1516b:	e1 01 00 
   1516e:	a1 84 e9 01 00       	mov    0x1e984,%eax
   15173:	a3 80 e9 01 00       	mov    %eax,0x1e980
		}

	}

	return( ch );
   15178:	8b 45 fc             	mov    -0x4(%ebp),%eax

}
   1517b:	c9                   	leave  
   1517c:	c3                   	ret    

0001517d <sio_read>:
** @param length  Length of the buffer
**
** @return the number of bytes copied, or 0 if no characters were available
*/

int sio_read( char *buf, int length ) {
   1517d:	55                   	push   %ebp
   1517e:	89 e5                	mov    %esp,%ebp
   15180:	83 ec 10             	sub    $0x10,%esp
	char *ptr = buf;
   15183:	8b 45 08             	mov    0x8(%ebp),%eax
   15186:	89 45 fc             	mov    %eax,-0x4(%ebp)
	int copied = 0;
   15189:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// if there are no characters, just return 0

	if( incount < 1 ) {
   15190:	a1 88 e9 01 00       	mov    0x1e988,%eax
   15195:	85 c0                	test   %eax,%eax
   15197:	75 4c                	jne    151e5 <sio_read+0x68>
		return( 0 );
   15199:	b8 00 00 00 00       	mov    $0x0,%eax
   1519e:	eb 76                	jmp    15216 <sio_read+0x99>
	// We have characters.  Copy as many of them into the user
	// buffer as will fit.
	//

	while( incount > 0 && copied < length ) {
		*ptr++ = *innext++ & 0xff;
   151a0:	8b 15 84 e9 01 00    	mov    0x1e984,%edx
   151a6:	8d 42 01             	lea    0x1(%edx),%eax
   151a9:	a3 84 e9 01 00       	mov    %eax,0x1e984
   151ae:	8b 45 fc             	mov    -0x4(%ebp),%eax
   151b1:	8d 48 01             	lea    0x1(%eax),%ecx
   151b4:	89 4d fc             	mov    %ecx,-0x4(%ebp)
   151b7:	0f b6 12             	movzbl (%edx),%edx
   151ba:	88 10                	mov    %dl,(%eax)
		if( innext > (inbuffer + BUF_SIZE) ) {
   151bc:	a1 84 e9 01 00       	mov    0x1e984,%eax
   151c1:	ba 80 e9 01 00       	mov    $0x1e980,%edx
   151c6:	39 d0                	cmp    %edx,%eax
   151c8:	76 0a                	jbe    151d4 <sio_read+0x57>
			innext = inbuffer;
   151ca:	c7 05 84 e9 01 00 80 	movl   $0x1e180,0x1e984
   151d1:	e1 01 00 
		}
		--incount;
   151d4:	a1 88 e9 01 00       	mov    0x1e988,%eax
   151d9:	83 e8 01             	sub    $0x1,%eax
   151dc:	a3 88 e9 01 00       	mov    %eax,0x1e988
		++copied;
   151e1:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
	while( incount > 0 && copied < length ) {
   151e5:	a1 88 e9 01 00       	mov    0x1e988,%eax
   151ea:	85 c0                	test   %eax,%eax
   151ec:	74 08                	je     151f6 <sio_read+0x79>
   151ee:	8b 45 f8             	mov    -0x8(%ebp),%eax
   151f1:	3b 45 0c             	cmp    0xc(%ebp),%eax
   151f4:	7c aa                	jl     151a0 <sio_read+0x23>
	}

	// reset the input buffer if necessary

	if( incount < 1 ) {
   151f6:	a1 88 e9 01 00       	mov    0x1e988,%eax
   151fb:	85 c0                	test   %eax,%eax
   151fd:	75 14                	jne    15213 <sio_read+0x96>
		inlast = innext = inbuffer;
   151ff:	c7 05 84 e9 01 00 80 	movl   $0x1e180,0x1e984
   15206:	e1 01 00 
   15209:	a1 84 e9 01 00       	mov    0x1e984,%eax
   1520e:	a3 80 e9 01 00       	mov    %eax,0x1e980
	}

	// return the copy count

	return( copied );
   15213:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
   15216:	c9                   	leave  
   15217:	c3                   	ret    

00015218 <sio_writec>:
**
** usage:    sio_writec( int ch )
**
** @param ch   Character to be written (in the low-order 8 bits)
*/
void sio_writec( int ch ){
   15218:	55                   	push   %ebp
   15219:	89 e5                	mov    %esp,%ebp
   1521b:	83 ec 18             	sub    $0x18,%esp

	//
	// Must do LF -> CRLF mapping
	//

	if( ch == '\n' ) {
   1521e:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
   15222:	75 0d                	jne    15231 <sio_writec+0x19>
		sio_writec( '\r' );
   15224:	83 ec 0c             	sub    $0xc,%esp
   15227:	6a 0d                	push   $0xd
   15229:	e8 ea ff ff ff       	call   15218 <sio_writec>
   1522e:	83 c4 10             	add    $0x10,%esp

	//
	// If we're currently transmitting, just add this to the buffer
	//

	if( sending ) {
   15231:	a1 ac f1 01 00       	mov    0x1f1ac,%eax
   15236:	85 c0                	test   %eax,%eax
   15238:	74 22                	je     1525c <sio_writec+0x44>
		*outlast++ = ch;
   1523a:	a1 a0 f1 01 00       	mov    0x1f1a0,%eax
   1523f:	8d 50 01             	lea    0x1(%eax),%edx
   15242:	89 15 a0 f1 01 00    	mov    %edx,0x1f1a0
   15248:	8b 55 08             	mov    0x8(%ebp),%edx
   1524b:	88 10                	mov    %dl,(%eax)
		++outcount;
   1524d:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   15252:	83 c0 01             	add    $0x1,%eax
   15255:	a3 a8 f1 01 00       	mov    %eax,0x1f1a8
		return;
   1525a:	eb 2f                	jmp    1528b <sio_writec+0x73>

	//
	// Not sending - must prime the pump
	//

	sending = 1;
   1525c:	c7 05 ac f1 01 00 01 	movl   $0x1,0x1f1ac
   15263:	00 00 00 
	outb( UA4_TXD, ch );
   15266:	8b 45 08             	mov    0x8(%ebp),%eax
   15269:	0f b6 c0             	movzbl %al,%eax
   1526c:	c7 45 f4 f8 03 00 00 	movl   $0x3f8,-0xc(%ebp)
   15273:	88 45 f3             	mov    %al,-0xd(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   15276:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   1527a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1527d:	ee                   	out    %al,(%dx)

	// Also must enable transmitter interrupts

	sio_enable( SIO_TX );
   1527e:	83 ec 0c             	sub    $0xc,%esp
   15281:	6a 01                	push   $0x1
   15283:	e8 e4 fc ff ff       	call   14f6c <sio_enable>
   15288:	83 c4 10             	add    $0x10,%esp

}
   1528b:	c9                   	leave  
   1528c:	c3                   	ret    

0001528d <sio_write>:
** @param buffer   Buffer containing characters to write
** @param length   Number of characters to write
**
** @return the number of characters copied into the SIO output buffer
*/
int sio_write( const char *buffer, int length ) {
   1528d:	55                   	push   %ebp
   1528e:	89 e5                	mov    %esp,%ebp
   15290:	83 ec 18             	sub    $0x18,%esp
	int first = *buffer;
   15293:	8b 45 08             	mov    0x8(%ebp),%eax
   15296:	0f b6 00             	movzbl (%eax),%eax
   15299:	0f be c0             	movsbl %al,%eax
   1529c:	89 45 ec             	mov    %eax,-0x14(%ebp)
	const char *ptr = buffer;
   1529f:	8b 45 08             	mov    0x8(%ebp),%eax
   152a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
	int copied = 0;
   152a5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	// the characters to the output buffer; else, we want
	// to append all but the first character, and then use
	// sio_writec() to send the first one out.
	//

	if( !sending ) {
   152ac:	a1 ac f1 01 00       	mov    0x1f1ac,%eax
   152b1:	85 c0                	test   %eax,%eax
   152b3:	75 4f                	jne    15304 <sio_write+0x77>
		ptr += 1;
   152b5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
		copied++;
   152b9:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
	}

	while( copied < length && outcount < BUF_SIZE ) {
   152bd:	eb 45                	jmp    15304 <sio_write+0x77>
		*outlast++ = *ptr++;
   152bf:	8b 55 f4             	mov    -0xc(%ebp),%edx
   152c2:	8d 42 01             	lea    0x1(%edx),%eax
   152c5:	89 45 f4             	mov    %eax,-0xc(%ebp)
   152c8:	a1 a0 f1 01 00       	mov    0x1f1a0,%eax
   152cd:	8d 48 01             	lea    0x1(%eax),%ecx
   152d0:	89 0d a0 f1 01 00    	mov    %ecx,0x1f1a0
   152d6:	0f b6 12             	movzbl (%edx),%edx
   152d9:	88 10                	mov    %dl,(%eax)
		// wrap around if necessary
		if( outlast >= (outbuffer + BUF_SIZE) ) {
   152db:	a1 a0 f1 01 00       	mov    0x1f1a0,%eax
   152e0:	ba a0 f1 01 00       	mov    $0x1f1a0,%edx
   152e5:	39 d0                	cmp    %edx,%eax
   152e7:	72 0a                	jb     152f3 <sio_write+0x66>
			outlast = outbuffer;
   152e9:	c7 05 a0 f1 01 00 a0 	movl   $0x1e9a0,0x1f1a0
   152f0:	e9 01 00 
		}
		++outcount;
   152f3:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   152f8:	83 c0 01             	add    $0x1,%eax
   152fb:	a3 a8 f1 01 00       	mov    %eax,0x1f1a8
		++copied;
   15300:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
	while( copied < length && outcount < BUF_SIZE ) {
   15304:	8b 45 f0             	mov    -0x10(%ebp),%eax
   15307:	3b 45 0c             	cmp    0xc(%ebp),%eax
   1530a:	7d 0c                	jge    15318 <sio_write+0x8b>
   1530c:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   15311:	3d ff 07 00 00       	cmp    $0x7ff,%eax
   15316:	76 a7                	jbe    152bf <sio_write+0x32>
	// We use sio_writec() to send out the first character,
	// as it will correctly set all the other necessary
	// variables for us.
	//

	if( !sending ) {
   15318:	a1 ac f1 01 00       	mov    0x1f1ac,%eax
   1531d:	85 c0                	test   %eax,%eax
   1531f:	75 0e                	jne    1532f <sio_write+0xa2>
		sio_writec( first );
   15321:	83 ec 0c             	sub    $0xc,%esp
   15324:	ff 75 ec             	pushl  -0x14(%ebp)
   15327:	e8 ec fe ff ff       	call   15218 <sio_writec>
   1532c:	83 c4 10             	add    $0x10,%esp
	}

	// Return the transfer count


	return( copied );
   1532f:	8b 45 f0             	mov    -0x10(%ebp),%eax

}
   15332:	c9                   	leave  
   15333:	c3                   	ret    

00015334 <sio_puts>:
**
** @param buffer  The buffer containing a NUL-terminated string
**
** @return the count of bytes transferred
*/
int sio_puts( const char *buffer ) {
   15334:	55                   	push   %ebp
   15335:	89 e5                	mov    %esp,%ebp
   15337:	83 ec 18             	sub    $0x18,%esp
	int n;  // must be outside the loop so we can return it

	n = SLENGTH( buffer );
   1533a:	83 ec 0c             	sub    $0xc,%esp
   1533d:	ff 75 08             	pushl  0x8(%ebp)
   15340:	e8 3f d7 ff ff       	call   12a84 <strlen>
   15345:	83 c4 10             	add    $0x10,%esp
   15348:	89 45 f4             	mov    %eax,-0xc(%ebp)
	sio_write( buffer, n );
   1534b:	83 ec 08             	sub    $0x8,%esp
   1534e:	ff 75 f4             	pushl  -0xc(%ebp)
   15351:	ff 75 08             	pushl  0x8(%ebp)
   15354:	e8 34 ff ff ff       	call   1528d <sio_write>
   15359:	83 c4 10             	add    $0x10,%esp

	return( n );
   1535c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   1535f:	c9                   	leave  
   15360:	c3                   	ret    

00015361 <sio_dump>:
** @param full   Boolean indicating whether or not a "full" dump
**               is being requested (which includes the contents
**               of the queues)
*/

void sio_dump( bool_t full ) {
   15361:	55                   	push   %ebp
   15362:	89 e5                	mov    %esp,%ebp
   15364:	57                   	push   %edi
   15365:	56                   	push   %esi
   15366:	53                   	push   %ebx
   15367:	83 ec 2c             	sub    $0x2c,%esp
   1536a:	8b 45 08             	mov    0x8(%ebp),%eax
   1536d:	88 45 d4             	mov    %al,-0x2c(%ebp)
	int n;
	char *ptr;

	// dump basic info into the status region

	cio_printf_at( 48, 0,
   15370:	8b 0d a8 f1 01 00    	mov    0x1f1a8,%ecx
   15376:	8b 15 88 e9 01 00    	mov    0x1e988,%edx
		"SIO: IER %02x (%c%c%c) in %d ot %d",
			((uint32_t)ier) & 0xff, sending ? '*' : '.',
			(ier & UA4_IER_TX_IE) ? 'T' : 't',
			(ier & UA4_IER_RX_IE) ? 'R' : 'r',
   1537c:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   15383:	0f b6 c0             	movzbl %al,%eax
   15386:	83 e0 01             	and    $0x1,%eax
	cio_printf_at( 48, 0,
   15389:	85 c0                	test   %eax,%eax
   1538b:	74 07                	je     15394 <sio_dump+0x33>
   1538d:	bf 52 00 00 00       	mov    $0x52,%edi
   15392:	eb 05                	jmp    15399 <sio_dump+0x38>
   15394:	bf 72 00 00 00       	mov    $0x72,%edi
			(ier & UA4_IER_TX_IE) ? 'T' : 't',
   15399:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   153a0:	0f b6 c0             	movzbl %al,%eax
   153a3:	83 e0 02             	and    $0x2,%eax
	cio_printf_at( 48, 0,
   153a6:	85 c0                	test   %eax,%eax
   153a8:	74 07                	je     153b1 <sio_dump+0x50>
   153aa:	be 54 00 00 00       	mov    $0x54,%esi
   153af:	eb 05                	jmp    153b6 <sio_dump+0x55>
   153b1:	be 74 00 00 00       	mov    $0x74,%esi
			((uint32_t)ier) & 0xff, sending ? '*' : '.',
   153b6:	a1 ac f1 01 00       	mov    0x1f1ac,%eax
	cio_printf_at( 48, 0,
   153bb:	85 c0                	test   %eax,%eax
   153bd:	74 07                	je     153c6 <sio_dump+0x65>
   153bf:	bb 2a 00 00 00       	mov    $0x2a,%ebx
   153c4:	eb 05                	jmp    153cb <sio_dump+0x6a>
   153c6:	bb 2e 00 00 00       	mov    $0x2e,%ebx
   153cb:	0f b6 05 b0 f1 01 00 	movzbl 0x1f1b0,%eax
   153d2:	0f b6 c0             	movzbl %al,%eax
   153d5:	83 ec 0c             	sub    $0xc,%esp
   153d8:	51                   	push   %ecx
   153d9:	52                   	push   %edx
   153da:	57                   	push   %edi
   153db:	56                   	push   %esi
   153dc:	53                   	push   %ebx
   153dd:	50                   	push   %eax
   153de:	68 78 b7 01 00       	push   $0x1b778
   153e3:	6a 00                	push   $0x0
   153e5:	6a 30                	push   $0x30
   153e7:	e8 1b c1 ff ff       	call   11507 <cio_printf_at>
   153ec:	83 c4 30             	add    $0x30,%esp
			incount, outcount );

	// if we're not doing a full dump, stop now

	if( !full ) {
   153ef:	80 7d d4 00          	cmpb   $0x0,-0x2c(%ebp)
   153f3:	0f 84 dc 00 00 00    	je     154d5 <sio_dump+0x174>
	}

	// also want the queue contents, but we'll
	// dump them into the scrolling region

	if( incount ) {
   153f9:	a1 88 e9 01 00       	mov    0x1e988,%eax
   153fe:	85 c0                	test   %eax,%eax
   15400:	74 5c                	je     1545e <sio_dump+0xfd>
		cio_puts( "SIO input queue: \"" );
   15402:	83 ec 0c             	sub    $0xc,%esp
   15405:	68 9b b7 01 00       	push   $0x1b79b
   1540a:	e8 9e ba ff ff       	call   10ead <cio_puts>
   1540f:	83 c4 10             	add    $0x10,%esp
		ptr = innext; 
   15412:	a1 84 e9 01 00       	mov    0x1e984,%eax
   15417:	89 45 e0             	mov    %eax,-0x20(%ebp)
		for( n = 0; n < incount; ++n ) {
   1541a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   15421:	eb 1f                	jmp    15442 <sio_dump+0xe1>
			put_char_or_code( *ptr++ );
   15423:	8b 45 e0             	mov    -0x20(%ebp),%eax
   15426:	8d 50 01             	lea    0x1(%eax),%edx
   15429:	89 55 e0             	mov    %edx,-0x20(%ebp)
   1542c:	0f b6 00             	movzbl (%eax),%eax
   1542f:	0f be c0             	movsbl %al,%eax
   15432:	83 ec 0c             	sub    $0xc,%esp
   15435:	50                   	push   %eax
   15436:	e8 55 cf ff ff       	call   12390 <put_char_or_code>
   1543b:	83 c4 10             	add    $0x10,%esp
		for( n = 0; n < incount; ++n ) {
   1543e:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   15442:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   15445:	a1 88 e9 01 00       	mov    0x1e988,%eax
   1544a:	39 c2                	cmp    %eax,%edx
   1544c:	72 d5                	jb     15423 <sio_dump+0xc2>
		}
		cio_puts( "\"\n" );
   1544e:	83 ec 0c             	sub    $0xc,%esp
   15451:	68 ae b7 01 00       	push   $0x1b7ae
   15456:	e8 52 ba ff ff       	call   10ead <cio_puts>
   1545b:	83 c4 10             	add    $0x10,%esp
	}

	if( outcount ) {
   1545e:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   15463:	85 c0                	test   %eax,%eax
   15465:	74 6f                	je     154d6 <sio_dump+0x175>
		cio_puts( "SIO output queue: \"" );
   15467:	83 ec 0c             	sub    $0xc,%esp
   1546a:	68 b1 b7 01 00       	push   $0x1b7b1
   1546f:	e8 39 ba ff ff       	call   10ead <cio_puts>
   15474:	83 c4 10             	add    $0x10,%esp
		cio_puts( " ot: \"" );
   15477:	83 ec 0c             	sub    $0xc,%esp
   1547a:	68 c5 b7 01 00       	push   $0x1b7c5
   1547f:	e8 29 ba ff ff       	call   10ead <cio_puts>
   15484:	83 c4 10             	add    $0x10,%esp
		ptr = outnext; 
   15487:	a1 a4 f1 01 00       	mov    0x1f1a4,%eax
   1548c:	89 45 e0             	mov    %eax,-0x20(%ebp)
		for( n = 0; n < outcount; ++n )  {
   1548f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   15496:	eb 1f                	jmp    154b7 <sio_dump+0x156>
			put_char_or_code( *ptr++ );
   15498:	8b 45 e0             	mov    -0x20(%ebp),%eax
   1549b:	8d 50 01             	lea    0x1(%eax),%edx
   1549e:	89 55 e0             	mov    %edx,-0x20(%ebp)
   154a1:	0f b6 00             	movzbl (%eax),%eax
   154a4:	0f be c0             	movsbl %al,%eax
   154a7:	83 ec 0c             	sub    $0xc,%esp
   154aa:	50                   	push   %eax
   154ab:	e8 e0 ce ff ff       	call   12390 <put_char_or_code>
   154b0:	83 c4 10             	add    $0x10,%esp
		for( n = 0; n < outcount; ++n )  {
   154b3:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   154b7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   154ba:	a1 a8 f1 01 00       	mov    0x1f1a8,%eax
   154bf:	39 c2                	cmp    %eax,%edx
   154c1:	72 d5                	jb     15498 <sio_dump+0x137>
		}
		cio_puts( "\"\n" );
   154c3:	83 ec 0c             	sub    $0xc,%esp
   154c6:	68 ae b7 01 00       	push   $0x1b7ae
   154cb:	e8 dd b9 ff ff       	call   10ead <cio_puts>
   154d0:	83 c4 10             	add    $0x10,%esp
   154d3:	eb 01                	jmp    154d6 <sio_dump+0x175>
		return;
   154d5:	90                   	nop
	}
}
   154d6:	8d 65 f4             	lea    -0xc(%ebp),%esp
   154d9:	5b                   	pop    %ebx
   154da:	5e                   	pop    %esi
   154db:	5f                   	pop    %edi
   154dc:	5d                   	pop    %ebp
   154dd:	c3                   	ret    

000154de <unexpected_handler>:
** @param vector   vector number for the interrupt that occurred
** @param code     error code, or a dummy value
**
** Does not return.
*/
static void unexpected_handler( int vector, int code ) {
   154de:	55                   	push   %ebp
   154df:	89 e5                	mov    %esp,%ebp
   154e1:	83 ec 08             	sub    $0x8,%esp
#ifdef RPT_INT_UNEXP
	cio_printf( "\n** UNEXPECTED vector %d code %d\n", vector, code );
   154e4:	83 ec 04             	sub    $0x4,%esp
   154e7:	ff 75 0c             	pushl  0xc(%ebp)
   154ea:	ff 75 08             	pushl  0x8(%ebp)
   154ed:	68 d4 b7 01 00       	push   $0x1b7d4
   154f2:	e8 30 c0 ff ff       	call   11527 <cio_printf>
   154f7:	83 c4 10             	add    $0x10,%esp
#endif
	panic( "Unexpected interrupt" );
   154fa:	83 ec 0c             	sub    $0xc,%esp
   154fd:	68 f6 b7 01 00       	push   $0x1b7f6
   15502:	e8 50 02 00 00       	call   15757 <panic>
   15507:	83 c4 10             	add    $0x10,%esp
}
   1550a:	90                   	nop
   1550b:	c9                   	leave  
   1550c:	c3                   	ret    

0001550d <default_handler>:
** handling (yet).  We just reset the PIC and return.
**
** @param vector   vector number for the interrupt that occurred
** @param code     error code, or a dummy value
*/
static void default_handler( int vector, int code ) {
   1550d:	55                   	push   %ebp
   1550e:	89 e5                	mov    %esp,%ebp
   15510:	83 ec 18             	sub    $0x18,%esp
#ifdef RPT_INT_UNEXP
	cio_printf( "\n** vector %d code %d\n", vector, code );
   15513:	83 ec 04             	sub    $0x4,%esp
   15516:	ff 75 0c             	pushl  0xc(%ebp)
   15519:	ff 75 08             	pushl  0x8(%ebp)
   1551c:	68 0b b8 01 00       	push   $0x1b80b
   15521:	e8 01 c0 ff ff       	call   11527 <cio_printf>
   15526:	83 c4 10             	add    $0x10,%esp
#endif
	if( vector >= 0x20 && vector < 0x30 ) {
   15529:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
   1552d:	7e 34                	jle    15563 <default_handler+0x56>
   1552f:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
   15533:	7f 2e                	jg     15563 <default_handler+0x56>
		if( vector > 0x27 ) {
   15535:	83 7d 08 27          	cmpl   $0x27,0x8(%ebp)
   15539:	7e 13                	jle    1554e <default_handler+0x41>
   1553b:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
   15542:	c6 45 f3 20          	movb   $0x20,-0xd(%ebp)
   15546:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   1554a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1554d:	ee                   	out    %al,(%dx)
   1554e:	c7 45 ec 20 00 00 00 	movl   $0x20,-0x14(%ebp)
   15555:	c6 45 eb 20          	movb   $0x20,-0x15(%ebp)
   15559:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   1555d:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15560:	ee                   	out    %al,(%dx)
			// must also ACK the secondary PIC
			outb( PIC2_CMD, PIC_EOI );
		}
		outb( PIC1_CMD, PIC_EOI );
   15561:	eb 10                	jmp    15573 <default_handler+0x66>
		/*
		** All the "expected" interrupts will be handled by the
		** code above.  If we get down here, the isr table may
		** have been corrupted.  Print a message and don't return.
		*/
		panic( "Unexpected \"expected\" interrupt!" );
   15563:	83 ec 0c             	sub    $0xc,%esp
   15566:	68 24 b8 01 00       	push   $0x1b824
   1556b:	e8 e7 01 00 00       	call   15757 <panic>
   15570:	83 c4 10             	add    $0x10,%esp
	}
}
   15573:	90                   	nop
   15574:	c9                   	leave  
   15575:	c3                   	ret    

00015576 <mystery_handler>:
** source.
**
** @param vector   vector number for the interrupt that occurred
** @param code     error code, or a dummy value
*/
static void mystery_handler( int vector, int code ) {
   15576:	55                   	push   %ebp
   15577:	89 e5                	mov    %esp,%ebp
   15579:	83 ec 18             	sub    $0x18,%esp
#if defined(RPT_INT_MYSTERY) || defined(RPT_INT_UNEXP)
	cio_printf( "\nMystery interrupt!\nVector=0x%02x, code=%d\n",
   1557c:	83 ec 04             	sub    $0x4,%esp
   1557f:	ff 75 0c             	pushl  0xc(%ebp)
   15582:	ff 75 08             	pushl  0x8(%ebp)
   15585:	68 48 b8 01 00       	push   $0x1b848
   1558a:	e8 98 bf ff ff       	call   11527 <cio_printf>
   1558f:	83 c4 10             	add    $0x10,%esp
   15592:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
   15599:	c6 45 f3 20          	movb   $0x20,-0xd(%ebp)
   1559d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   155a1:	8b 55 f4             	mov    -0xc(%ebp),%edx
   155a4:	ee                   	out    %al,(%dx)
		  vector, code );
#endif
	outb( PIC1_CMD, PIC_EOI );
}
   155a5:	90                   	nop
   155a6:	c9                   	leave  
   155a7:	c3                   	ret    

000155a8 <init_pic>:
/**
** init_pic
**
** Initialize the 8259 Programmable Interrupt Controller.
*/
static void init_pic( void ) {
   155a8:	55                   	push   %ebp
   155a9:	89 e5                	mov    %esp,%ebp
   155ab:	83 ec 50             	sub    $0x50,%esp
   155ae:	c7 45 b4 20 00 00 00 	movl   $0x20,-0x4c(%ebp)
   155b5:	c6 45 b3 11          	movb   $0x11,-0x4d(%ebp)
   155b9:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
   155bd:	8b 55 b4             	mov    -0x4c(%ebp),%edx
   155c0:	ee                   	out    %al,(%dx)
   155c1:	c7 45 bc a0 00 00 00 	movl   $0xa0,-0x44(%ebp)
   155c8:	c6 45 bb 11          	movb   $0x11,-0x45(%ebp)
   155cc:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
   155d0:	8b 55 bc             	mov    -0x44(%ebp),%edx
   155d3:	ee                   	out    %al,(%dx)
   155d4:	c7 45 c4 21 00 00 00 	movl   $0x21,-0x3c(%ebp)
   155db:	c6 45 c3 20          	movb   $0x20,-0x3d(%ebp)
   155df:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
   155e3:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   155e6:	ee                   	out    %al,(%dx)
   155e7:	c7 45 cc a1 00 00 00 	movl   $0xa1,-0x34(%ebp)
   155ee:	c6 45 cb 28          	movb   $0x28,-0x35(%ebp)
   155f2:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
   155f6:	8b 55 cc             	mov    -0x34(%ebp),%edx
   155f9:	ee                   	out    %al,(%dx)
   155fa:	c7 45 d4 21 00 00 00 	movl   $0x21,-0x2c(%ebp)
   15601:	c6 45 d3 04          	movb   $0x4,-0x2d(%ebp)
   15605:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
   15609:	8b 55 d4             	mov    -0x2c(%ebp),%edx
   1560c:	ee                   	out    %al,(%dx)
   1560d:	c7 45 dc a1 00 00 00 	movl   $0xa1,-0x24(%ebp)
   15614:	c6 45 db 02          	movb   $0x2,-0x25(%ebp)
   15618:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   1561c:	8b 55 dc             	mov    -0x24(%ebp),%edx
   1561f:	ee                   	out    %al,(%dx)
   15620:	c7 45 e4 21 00 00 00 	movl   $0x21,-0x1c(%ebp)
   15627:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
   1562b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
   1562f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   15632:	ee                   	out    %al,(%dx)
   15633:	c7 45 ec a1 00 00 00 	movl   $0xa1,-0x14(%ebp)
   1563a:	c6 45 eb 01          	movb   $0x1,-0x15(%ebp)
   1563e:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   15642:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15645:	ee                   	out    %al,(%dx)
   15646:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
   1564d:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)
   15651:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   15655:	8b 55 f4             	mov    -0xc(%ebp),%edx
   15658:	ee                   	out    %al,(%dx)
   15659:	c7 45 fc a1 00 00 00 	movl   $0xa1,-0x4(%ebp)
   15660:	c6 45 fb 00          	movb   $0x0,-0x5(%ebp)
   15664:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
   15668:	8b 55 fc             	mov    -0x4(%ebp),%edx
   1566b:	ee                   	out    %al,(%dx)
	/*
	** OCW1: allow interrupts on all lines
	*/
	outb( PIC1_DATA, PIC_MASK_NONE );
	outb( PIC2_DATA, PIC_MASK_NONE );
}
   1566c:	90                   	nop
   1566d:	c9                   	leave  
   1566e:	c3                   	ret    

0001566f <set_idt_entry>:
** @param handler  ISR address to be put into the IDT entry
**
** Note: generally, the handler invoked from the IDT will be a "stub"
** that calls the second-level C handler via the isr_table array.
*/
static void set_idt_entry( int entry, void ( *handler )( void ) ) {
   1566f:	55                   	push   %ebp
   15670:	89 e5                	mov    %esp,%ebp
   15672:	83 ec 10             	sub    $0x10,%esp
	IDT_Gate *g = (IDT_Gate *)IDT_ADDR + entry;
   15675:	8b 45 08             	mov    0x8(%ebp),%eax
   15678:	c1 e0 03             	shl    $0x3,%eax
   1567b:	05 00 25 00 00       	add    $0x2500,%eax
   15680:	89 45 fc             	mov    %eax,-0x4(%ebp)

	g->offset_15_0 = (int)handler & 0xffff;
   15683:	8b 45 0c             	mov    0xc(%ebp),%eax
   15686:	89 c2                	mov    %eax,%edx
   15688:	8b 45 fc             	mov    -0x4(%ebp),%eax
   1568b:	66 89 10             	mov    %dx,(%eax)
	g->segment_selector = 0x0010;
   1568e:	8b 45 fc             	mov    -0x4(%ebp),%eax
   15691:	66 c7 40 02 10 00    	movw   $0x10,0x2(%eax)
	g->flags = IDT_PRESENT | IDT_DPL_0 | IDT_INT32_GATE;
   15697:	8b 45 fc             	mov    -0x4(%ebp),%eax
   1569a:	66 c7 40 04 00 8e    	movw   $0x8e00,0x4(%eax)
	g->offset_31_16 = (int)handler >> 16 & 0xffff;
   156a0:	8b 45 0c             	mov    0xc(%ebp),%eax
   156a3:	c1 e8 10             	shr    $0x10,%eax
   156a6:	89 c2                	mov    %eax,%edx
   156a8:	8b 45 fc             	mov    -0x4(%ebp),%eax
   156ab:	66 89 50 06          	mov    %dx,0x6(%eax)
}
   156af:	90                   	nop
   156b0:	c9                   	leave  
   156b1:	c3                   	ret    

000156b2 <init_idt>:
** the entries in the IDT point to the isr stub for that entry, and
** installs a default handler in the handler table.  Temporary handlers
** are then installed for those interrupts we may get before a real
** handler is set up.
*/
static void init_idt( void ) {
   156b2:	55                   	push   %ebp
   156b3:	89 e5                	mov    %esp,%ebp
   156b5:	83 ec 18             	sub    $0x18,%esp

	/*
	** Make each IDT entry point to the stub for that vector.  Also
	** make each entry in the ISR table point to the default handler.
	*/
	for ( i=0; i < N_EXCEPTIONS; i++ ) {
   156b8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   156bf:	eb 2d                	jmp    156ee <init_idt+0x3c>
		set_idt_entry( i, isr_stub_table[ i ] );
   156c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
   156c4:	8b 04 85 36 a5 01 00 	mov    0x1a536(,%eax,4),%eax
   156cb:	50                   	push   %eax
   156cc:	ff 75 f4             	pushl  -0xc(%ebp)
   156cf:	e8 9b ff ff ff       	call   1566f <set_idt_entry>
   156d4:	83 c4 08             	add    $0x8,%esp
		install_isr( i, unexpected_handler );
   156d7:	83 ec 08             	sub    $0x8,%esp
   156da:	68 de 54 01 00       	push   $0x154de
   156df:	ff 75 f4             	pushl  -0xc(%ebp)
   156e2:	e8 9f 00 00 00       	call   15786 <install_isr>
   156e7:	83 c4 10             	add    $0x10,%esp
	for ( i=0; i < N_EXCEPTIONS; i++ ) {
   156ea:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   156ee:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
   156f5:	7e ca                	jle    156c1 <init_idt+0xf>
	** Install the handlers for interrupts that have (or will have) a
	** specific handler. Comments indicate which module init function
	** will eventually install the "real" handler.
	*/

	install_isr( VEC_KBD, default_handler );         // cio_init()
   156f7:	83 ec 08             	sub    $0x8,%esp
   156fa:	68 0d 55 01 00       	push   $0x1550d
   156ff:	6a 21                	push   $0x21
   15701:	e8 80 00 00 00       	call   15786 <install_isr>
   15706:	83 c4 10             	add    $0x10,%esp
	install_isr( VEC_COM1, default_handler );        // sio_init()
   15709:	83 ec 08             	sub    $0x8,%esp
   1570c:	68 0d 55 01 00       	push   $0x1550d
   15711:	6a 24                	push   $0x24
   15713:	e8 6e 00 00 00       	call   15786 <install_isr>
   15718:	83 c4 10             	add    $0x10,%esp
	install_isr( VEC_TIMER, default_handler );       // clk_init()
   1571b:	83 ec 08             	sub    $0x8,%esp
   1571e:	68 0d 55 01 00       	push   $0x1550d
   15723:	6a 20                	push   $0x20
   15725:	e8 5c 00 00 00       	call   15786 <install_isr>
   1572a:	83 c4 10             	add    $0x10,%esp
	install_isr( VEC_SYSCALL, default_handler );     // sys_init()
   1572d:	83 ec 08             	sub    $0x8,%esp
   15730:	68 0d 55 01 00       	push   $0x1550d
   15735:	68 80 00 00 00       	push   $0x80
   1573a:	e8 47 00 00 00       	call   15786 <install_isr>
   1573f:	83 c4 10             	add    $0x10,%esp
	// install_isr( VEC_PAGE_FAULT, default_handler );  // vm_init()

	install_isr( VEC_MYSTERY, mystery_handler );
   15742:	83 ec 08             	sub    $0x8,%esp
   15745:	68 76 55 01 00       	push   $0x15576
   1574a:	6a 27                	push   $0x27
   1574c:	e8 35 00 00 00       	call   15786 <install_isr>
   15751:	83 c4 10             	add    $0x10,%esp
}
   15754:	90                   	nop
   15755:	c9                   	leave  
   15756:	c3                   	ret    

00015757 <panic>:
/*
** panic
**
** Called when we find an unrecoverable error.
*/
void panic( char *reason ) {
   15757:	55                   	push   %ebp
   15758:	89 e5                	mov    %esp,%ebp
   1575a:	83 ec 08             	sub    $0x8,%esp
	__asm__( "cli" );
   1575d:	fa                   	cli    
	cio_printf( "\nPANIC: %s\nHalting...", reason );
   1575e:	83 ec 08             	sub    $0x8,%esp
   15761:	ff 75 08             	pushl  0x8(%ebp)
   15764:	68 74 b8 01 00       	push   $0x1b874
   15769:	e8 b9 bd ff ff       	call   11527 <cio_printf>
   1576e:	83 c4 10             	add    $0x10,%esp
	for(;;) {
   15771:	eb fe                	jmp    15771 <panic+0x1a>

00015773 <init_interrupts>:
/*
** init_interrupts
**
** (Re)initilizes the interrupt system.
*/
void init_interrupts( void ) {
   15773:	55                   	push   %ebp
   15774:	89 e5                	mov    %esp,%ebp
   15776:	83 ec 08             	sub    $0x8,%esp
	init_idt();
   15779:	e8 34 ff ff ff       	call   156b2 <init_idt>
	init_pic();
   1577e:	e8 25 fe ff ff       	call   155a8 <init_pic>
}
   15783:	90                   	nop
   15784:	c9                   	leave  
   15785:	c3                   	ret    

00015786 <install_isr>:
** install_isr
**
** Installs a second-level handler for a specific interrupt.
*/
void (*install_isr( int vector,
		void (*handler)(int,int) ) ) ( int, int ) {
   15786:	55                   	push   %ebp
   15787:	89 e5                	mov    %esp,%ebp
   15789:	83 ec 10             	sub    $0x10,%esp

	void ( *old_handler )( int vector, int code );

	old_handler = isr_table[ vector ];
   1578c:	8b 45 08             	mov    0x8(%ebp),%eax
   1578f:	8b 04 85 e0 24 02 00 	mov    0x224e0(,%eax,4),%eax
   15796:	89 45 fc             	mov    %eax,-0x4(%ebp)
	isr_table[ vector ] = handler;
   15799:	8b 45 08             	mov    0x8(%ebp),%eax
   1579c:	8b 55 0c             	mov    0xc(%ebp),%edx
   1579f:	89 14 85 e0 24 02 00 	mov    %edx,0x224e0(,%eax,4)
	return old_handler;
   157a6:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   157a9:	c9                   	leave  
   157aa:	c3                   	ret    

000157ab <delay>:
** On the current machines (Intel Core i5-7500), delay(100) is about
** 2.5 seconds, so each "unit" is roughly 0.025 seconds.
**
** Ultimately, just remember that DELAY VALUES ARE APPROXIMATE AT BEST.
*/
void delay( int length ) {
   157ab:	55                   	push   %ebp
   157ac:	89 e5                	mov    %esp,%ebp
   157ae:	83 ec 10             	sub    $0x10,%esp

	while( --length >= 0 ) {
   157b1:	eb 16                	jmp    157c9 <delay+0x1e>
		for( int i = 0; i < 10000000; ++i )
   157b3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   157ba:	eb 04                	jmp    157c0 <delay+0x15>
   157bc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   157c0:	81 7d fc 7f 96 98 00 	cmpl   $0x98967f,-0x4(%ebp)
   157c7:	7e f3                	jle    157bc <delay+0x11>
	while( --length >= 0 ) {
   157c9:	83 6d 08 01          	subl   $0x1,0x8(%ebp)
   157cd:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   157d1:	79 e0                	jns    157b3 <delay+0x8>
			;
	}
}
   157d3:	90                   	nop
   157d4:	c9                   	leave  
   157d5:	c3                   	ret    

000157d6 <sys_exit>:
** Implements:
**		void exit( int32_t status );
**
** Does not return
*/
SYSIMPL(exit) {
   157d6:	55                   	push   %ebp
   157d7:	89 e5                	mov    %esp,%ebp
   157d9:	83 ec 08             	sub    $0x8,%esp

	// sanity check
	assert( pcb != NULL );
   157dc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   157e0:	75 38                	jne    1581a <sys_exit+0x44>
   157e2:	83 ec 04             	sub    $0x4,%esp
   157e5:	68 a0 b8 01 00       	push   $0x1b8a0
   157ea:	6a 00                	push   $0x0
   157ec:	6a 65                	push   $0x65
   157ee:	68 a9 b8 01 00       	push   $0x1b8a9
   157f3:	68 5c ba 01 00       	push   $0x1ba5c
   157f8:	68 b4 b8 01 00       	push   $0x1b8b4
   157fd:	68 00 00 02 00       	push   $0x20000
   15802:	e8 00 cf ff ff       	call   12707 <sprint>
   15807:	83 c4 20             	add    $0x20,%esp
   1580a:	83 ec 0c             	sub    $0xc,%esp
   1580d:	68 00 00 02 00       	push   $0x20000
   15812:	e8 70 cc ff ff       	call   12487 <kpanic>
   15817:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   1581a:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1581f:	85 c0                	test   %eax,%eax
   15821:	74 1c                	je     1583f <sys_exit+0x69>
   15823:	8b 45 08             	mov    0x8(%ebp),%eax
   15826:	8b 40 18             	mov    0x18(%eax),%eax
   15829:	83 ec 04             	sub    $0x4,%esp
   1582c:	50                   	push   %eax
   1582d:	68 5c ba 01 00       	push   $0x1ba5c
   15832:	68 ca b8 01 00       	push   $0x1b8ca
   15837:	e8 eb bc ff ff       	call   11527 <cio_printf>
   1583c:	83 c4 10             	add    $0x10,%esp

	// retrieve the exit status of this process
	pcb->exit_status = (int32_t) ARG(pcb,1);
   1583f:	8b 45 08             	mov    0x8(%ebp),%eax
   15842:	8b 00                	mov    (%eax),%eax
   15844:	83 c0 48             	add    $0x48,%eax
   15847:	83 c0 04             	add    $0x4,%eax
   1584a:	8b 00                	mov    (%eax),%eax
   1584c:	89 c2                	mov    %eax,%edx
   1584e:	8b 45 08             	mov    0x8(%ebp),%eax
   15851:	89 50 14             	mov    %edx,0x14(%eax)

	// now, we need to do the following:
	// 	reparent any children of this process and wake up init if need be
	// 	find this process' parent and wake it up if it's waiting
	
	pcb_zombify( pcb );
   15854:	83 ec 0c             	sub    $0xc,%esp
   15857:	ff 75 08             	pushl  0x8(%ebp)
   1585a:	e8 b3 e1 ff ff       	call   13a12 <pcb_zombify>
   1585f:	83 c4 10             	add    $0x10,%esp

	// pick a new winner
	current = NULL;
   15862:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   15869:	00 00 00 
	dispatch();
   1586c:	e8 1f ec ff ff       	call   14490 <dispatch>

	SYSCALL_EXIT( 0 );
   15871:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15876:	85 c0                	test   %eax,%eax
   15878:	74 18                	je     15892 <sys_exit+0xbc>
   1587a:	83 ec 04             	sub    $0x4,%esp
   1587d:	6a 00                	push   $0x0
   1587f:	68 5c ba 01 00       	push   $0x1ba5c
   15884:	68 db b8 01 00       	push   $0x1b8db
   15889:	e8 99 bc ff ff       	call   11527 <cio_printf>
   1588e:	83 c4 10             	add    $0x10,%esp
	return;
   15891:	90                   	nop
   15892:	90                   	nop
}
   15893:	c9                   	leave  
   15894:	c3                   	ret    

00015895 <sys_waitpid>:
** Blocks the calling process until the specified child (or any child)
** of the caller terminates. Intrinsic return is the PID of the child that
** terminated, or an error code; on success, returns the child's termination
** status via 'status' if that pointer is non-NULL.
*/
SYSIMPL(waitpid) {
   15895:	55                   	push   %ebp
   15896:	89 e5                	mov    %esp,%ebp
   15898:	53                   	push   %ebx
   15899:	83 ec 24             	sub    $0x24,%esp

	// sanity check
	assert( pcb != NULL );
   1589c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   158a0:	75 3b                	jne    158dd <sys_waitpid+0x48>
   158a2:	83 ec 04             	sub    $0x4,%esp
   158a5:	68 a0 b8 01 00       	push   $0x1b8a0
   158aa:	6a 00                	push   $0x0
   158ac:	68 88 00 00 00       	push   $0x88
   158b1:	68 a9 b8 01 00       	push   $0x1b8a9
   158b6:	68 68 ba 01 00       	push   $0x1ba68
   158bb:	68 b4 b8 01 00       	push   $0x1b8b4
   158c0:	68 00 00 02 00       	push   $0x20000
   158c5:	e8 3d ce ff ff       	call   12707 <sprint>
   158ca:	83 c4 20             	add    $0x20,%esp
   158cd:	83 ec 0c             	sub    $0xc,%esp
   158d0:	68 00 00 02 00       	push   $0x20000
   158d5:	e8 ad cb ff ff       	call   12487 <kpanic>
   158da:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   158dd:	a1 e0 28 02 00       	mov    0x228e0,%eax
   158e2:	85 c0                	test   %eax,%eax
   158e4:	74 1c                	je     15902 <sys_waitpid+0x6d>
   158e6:	8b 45 08             	mov    0x8(%ebp),%eax
   158e9:	8b 40 18             	mov    0x18(%eax),%eax
   158ec:	83 ec 04             	sub    $0x4,%esp
   158ef:	50                   	push   %eax
   158f0:	68 68 ba 01 00       	push   $0x1ba68
   158f5:	68 ca b8 01 00       	push   $0x1b8ca
   158fa:	e8 28 bc ff ff       	call   11527 <cio_printf>
   158ff:	83 c4 10             	add    $0x10,%esp
	** we reap here; there could be several, but we only need to
	** find one.
	*/

	// verify that we aren't looking for ourselves!
	uint_t target = ARG(pcb,1);
   15902:	8b 45 08             	mov    0x8(%ebp),%eax
   15905:	8b 00                	mov    (%eax),%eax
   15907:	83 c0 48             	add    $0x48,%eax
   1590a:	8b 40 04             	mov    0x4(%eax),%eax
   1590d:	89 45 e8             	mov    %eax,-0x18(%ebp)

	if( target == pcb->pid ) {
   15910:	8b 45 08             	mov    0x8(%ebp),%eax
   15913:	8b 40 18             	mov    0x18(%eax),%eax
   15916:	39 45 e8             	cmp    %eax,-0x18(%ebp)
   15919:	75 35                	jne    15950 <sys_waitpid+0xbb>
		RET(pcb) = E_BAD_PARAM;
   1591b:	8b 45 08             	mov    0x8(%ebp),%eax
   1591e:	8b 00                	mov    (%eax),%eax
   15920:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
		SYSCALL_EXIT( E_BAD_PARAM );
   15927:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1592c:	85 c0                	test   %eax,%eax
   1592e:	0f 84 55 02 00 00    	je     15b89 <sys_waitpid+0x2f4>
   15934:	83 ec 04             	sub    $0x4,%esp
   15937:	6a fe                	push   $0xfffffffe
   15939:	68 68 ba 01 00       	push   $0x1ba68
   1593e:	68 db b8 01 00       	push   $0x1b8db
   15943:	e8 df bb ff ff       	call   11527 <cio_printf>
   15948:	83 c4 10             	add    $0x10,%esp
		return;
   1594b:	e9 39 02 00 00       	jmp    15b89 <sys_waitpid+0x2f4>
	}

	// Good.  Now, figure out what we're looking for.

	pcb_t *child = NULL;
   15950:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if( target != 0 ) {
   15957:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   1595b:	0f 84 a7 00 00 00    	je     15a08 <sys_waitpid+0x173>

		// we're looking for a specific child
		child = pcb_find_pid( target );
   15961:	83 ec 0c             	sub    $0xc,%esp
   15964:	ff 75 e8             	pushl  -0x18(%ebp)
   15967:	e8 67 e3 ff ff       	call   13cd3 <pcb_find_pid>
   1596c:	83 c4 10             	add    $0x10,%esp
   1596f:	89 45 f4             	mov    %eax,-0xc(%ebp)

		if( child != NULL ) {
   15972:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15976:	74 5b                	je     159d3 <sys_waitpid+0x13e>

			// found the process; is it one of our children:
			if( child->parent != pcb ) {
   15978:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1597b:	8b 40 0c             	mov    0xc(%eax),%eax
   1597e:	39 45 08             	cmp    %eax,0x8(%ebp)
   15981:	74 35                	je     159b8 <sys_waitpid+0x123>
				// NO, so we can't wait for it
				RET(pcb) = E_BAD_PARAM;
   15983:	8b 45 08             	mov    0x8(%ebp),%eax
   15986:	8b 00                	mov    (%eax),%eax
   15988:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
				SYSCALL_EXIT( E_BAD_PARAM );
   1598f:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15994:	85 c0                	test   %eax,%eax
   15996:	0f 84 f0 01 00 00    	je     15b8c <sys_waitpid+0x2f7>
   1599c:	83 ec 04             	sub    $0x4,%esp
   1599f:	6a fe                	push   $0xfffffffe
   159a1:	68 68 ba 01 00       	push   $0x1ba68
   159a6:	68 db b8 01 00       	push   $0x1b8db
   159ab:	e8 77 bb ff ff       	call   11527 <cio_printf>
   159b0:	83 c4 10             	add    $0x10,%esp
				return;
   159b3:	e9 d4 01 00 00       	jmp    15b8c <sys_waitpid+0x2f7>
			}

			// yes!  is this one ready to be collected?
			if( child->state != STATE_ZOMBIE ) {
   159b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
   159bb:	8b 40 1c             	mov    0x1c(%eax),%eax
   159be:	83 f8 08             	cmp    $0x8,%eax
   159c1:	0f 84 bb 00 00 00    	je     15a82 <sys_waitpid+0x1ed>
				// no, so we'll have to block for now
				child = NULL;
   159c7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   159ce:	e9 af 00 00 00       	jmp    15a82 <sys_waitpid+0x1ed>
			}

		} else {

			// no such child
			RET(pcb) = E_BAD_PARAM;
   159d3:	8b 45 08             	mov    0x8(%ebp),%eax
   159d6:	8b 00                	mov    (%eax),%eax
   159d8:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
			SYSCALL_EXIT( E_BAD_PARAM );
   159df:	a1 e0 28 02 00       	mov    0x228e0,%eax
   159e4:	85 c0                	test   %eax,%eax
   159e6:	0f 84 a3 01 00 00    	je     15b8f <sys_waitpid+0x2fa>
   159ec:	83 ec 04             	sub    $0x4,%esp
   159ef:	6a fe                	push   $0xfffffffe
   159f1:	68 68 ba 01 00       	push   $0x1ba68
   159f6:	68 db b8 01 00       	push   $0x1b8db
   159fb:	e8 27 bb ff ff       	call   11527 <cio_printf>
   15a00:	83 c4 10             	add    $0x10,%esp
			return;
   15a03:	e9 87 01 00 00       	jmp    15b8f <sys_waitpid+0x2fa>
		// looking for any child

		// we need to find a process that is our child
		// and has already exited

		child = NULL;
   15a08:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
		bool_t found = false;
   15a0f:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)

		// unfortunately, we can't stop at the first child,
		// so we need to do the iteration ourselves
		register pcb_t *curr = ptable;
   15a13:	bb 20 20 02 00       	mov    $0x22020,%ebx

		for( int i = 0; i < N_PROCS; ++i, ++curr ) {
   15a18:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   15a1f:	eb 20                	jmp    15a41 <sys_waitpid+0x1ac>

			if( curr->parent == pcb ) {
   15a21:	8b 43 0c             	mov    0xc(%ebx),%eax
   15a24:	39 45 08             	cmp    %eax,0x8(%ebp)
   15a27:	75 11                	jne    15a3a <sys_waitpid+0x1a5>

				// found one!
				found = true;
   15a29:	c6 45 f3 01          	movb   $0x1,-0xd(%ebp)

				// has it already exited?
				if( curr->state == STATE_ZOMBIE ) {
   15a2d:	8b 43 1c             	mov    0x1c(%ebx),%eax
   15a30:	83 f8 08             	cmp    $0x8,%eax
   15a33:	75 05                	jne    15a3a <sys_waitpid+0x1a5>
					// yes, so we're done here
					child = curr;
   15a35:	89 5d f4             	mov    %ebx,-0xc(%ebp)
					break;
   15a38:	eb 0d                	jmp    15a47 <sys_waitpid+0x1b2>
		for( int i = 0; i < N_PROCS; ++i, ++curr ) {
   15a3a:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   15a3e:	83 c3 30             	add    $0x30,%ebx
   15a41:	83 7d ec 18          	cmpl   $0x18,-0x14(%ebp)
   15a45:	7e da                	jle    15a21 <sys_waitpid+0x18c>
				}
			}
		}

		if( !found ) {
   15a47:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   15a4b:	75 35                	jne    15a82 <sys_waitpid+0x1ed>
			// got through the loop without finding a child!
			RET(pcb) = E_NO_CHILDREN;
   15a4d:	8b 45 08             	mov    0x8(%ebp),%eax
   15a50:	8b 00                	mov    (%eax),%eax
   15a52:	c7 40 30 fc ff ff ff 	movl   $0xfffffffc,0x30(%eax)
			SYSCALL_EXIT( E_NO_CHILDREN );
   15a59:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15a5e:	85 c0                	test   %eax,%eax
   15a60:	0f 84 2c 01 00 00    	je     15b92 <sys_waitpid+0x2fd>
   15a66:	83 ec 04             	sub    $0x4,%esp
   15a69:	6a fc                	push   $0xfffffffc
   15a6b:	68 68 ba 01 00       	push   $0x1ba68
   15a70:	68 db b8 01 00       	push   $0x1b8db
   15a75:	e8 ad ba ff ff       	call   11527 <cio_printf>
   15a7a:	83 c4 10             	add    $0x10,%esp
			return;
   15a7d:	e9 10 01 00 00       	jmp    15b92 <sys_waitpid+0x2fd>
	** case, we collect its status and clean it up; otherwise,
	** we block this process.
	*/

	// did we find one to collect?
	if( child == NULL ) {
   15a82:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15a86:	0f 85 96 00 00 00    	jne    15b22 <sys_waitpid+0x28d>

		// no - mark the parent as "Waiting"
		pcb->state = STATE_WAITING;
   15a8c:	8b 45 08             	mov    0x8(%ebp),%eax
   15a8f:	c7 40 1c 06 00 00 00 	movl   $0x6,0x1c(%eax)
		assert( pcb_queue_insert(waiting,pcb) == SUCCESS );
   15a96:	a1 10 20 02 00       	mov    0x22010,%eax
   15a9b:	83 ec 08             	sub    $0x8,%esp
   15a9e:	ff 75 08             	pushl  0x8(%ebp)
   15aa1:	50                   	push   %eax
   15aa2:	e8 4f e4 ff ff       	call   13ef6 <pcb_queue_insert>
   15aa7:	83 c4 10             	add    $0x10,%esp
   15aaa:	85 c0                	test   %eax,%eax
   15aac:	74 3b                	je     15ae9 <sys_waitpid+0x254>
   15aae:	83 ec 04             	sub    $0x4,%esp
   15ab1:	68 e8 b8 01 00       	push   $0x1b8e8
   15ab6:	6a 00                	push   $0x0
   15ab8:	68 fe 00 00 00       	push   $0xfe
   15abd:	68 a9 b8 01 00       	push   $0x1b8a9
   15ac2:	68 68 ba 01 00       	push   $0x1ba68
   15ac7:	68 b4 b8 01 00       	push   $0x1b8b4
   15acc:	68 00 00 02 00       	push   $0x20000
   15ad1:	e8 31 cc ff ff       	call   12707 <sprint>
   15ad6:	83 c4 20             	add    $0x20,%esp
   15ad9:	83 ec 0c             	sub    $0xc,%esp
   15adc:	68 00 00 02 00       	push   $0x20000
   15ae1:	e8 a1 c9 ff ff       	call   12487 <kpanic>
   15ae6:	83 c4 10             	add    $0x10,%esp

		// select a new current process
		current = NULL;
   15ae9:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   15af0:	00 00 00 
		dispatch();
   15af3:	e8 98 e9 ff ff       	call   14490 <dispatch>
		SYSCALL_EXIT( (uint32_t) current );
   15af8:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15afd:	85 c0                	test   %eax,%eax
   15aff:	0f 84 90 00 00 00    	je     15b95 <sys_waitpid+0x300>
   15b05:	a1 14 20 02 00       	mov    0x22014,%eax
   15b0a:	83 ec 04             	sub    $0x4,%esp
   15b0d:	50                   	push   %eax
   15b0e:	68 68 ba 01 00       	push   $0x1ba68
   15b13:	68 db b8 01 00       	push   $0x1b8db
   15b18:	e8 0a ba ff ff       	call   11527 <cio_printf>
   15b1d:	83 c4 10             	add    $0x10,%esp
		return;
   15b20:	eb 73                	jmp    15b95 <sys_waitpid+0x300>
	}

	// found a Zombie; collect its information and clean it up
	RET(pcb) = child->pid;
   15b22:	8b 45 08             	mov    0x8(%ebp),%eax
   15b25:	8b 00                	mov    (%eax),%eax
   15b27:	8b 55 f4             	mov    -0xc(%ebp),%edx
   15b2a:	8b 52 18             	mov    0x18(%edx),%edx
   15b2d:	89 50 30             	mov    %edx,0x30(%eax)

	// get "status" pointer from parent
	int32_t *stat = (int32_t *) ARG(pcb,2);
   15b30:	8b 45 08             	mov    0x8(%ebp),%eax
   15b33:	8b 00                	mov    (%eax),%eax
   15b35:	83 c0 48             	add    $0x48,%eax
   15b38:	83 c0 08             	add    $0x8,%eax
   15b3b:	8b 00                	mov    (%eax),%eax
   15b3d:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	// if stat is NULL, the parent doesn't want the status
	if( stat != NULL ) {
   15b40:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   15b44:	74 0b                	je     15b51 <sys_waitpid+0x2bc>
		// ** This works in the baseline because we aren't using
		// ** any type of memory protection.  If address space
		// ** separation is implemented, this code will very likely
		// ** STOP WORKING, and will need to be fixed.
		// ********************************************************
		*stat = child->exit_status;
   15b46:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15b49:	8b 50 14             	mov    0x14(%eax),%edx
   15b4c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15b4f:	89 10                	mov    %edx,(%eax)
	}

	// clean up the child
	pcb_cleanup( child );
   15b51:	83 ec 0c             	sub    $0xc,%esp
   15b54:	ff 75 f4             	pushl  -0xc(%ebp)
   15b57:	e8 4a e1 ff ff       	call   13ca6 <pcb_cleanup>
   15b5c:	83 c4 10             	add    $0x10,%esp

	SYSCALL_EXIT( RET(pcb) );
   15b5f:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15b64:	85 c0                	test   %eax,%eax
   15b66:	74 30                	je     15b98 <sys_waitpid+0x303>
   15b68:	8b 45 08             	mov    0x8(%ebp),%eax
   15b6b:	8b 00                	mov    (%eax),%eax
   15b6d:	8b 40 30             	mov    0x30(%eax),%eax
   15b70:	83 ec 04             	sub    $0x4,%esp
   15b73:	50                   	push   %eax
   15b74:	68 68 ba 01 00       	push   $0x1ba68
   15b79:	68 db b8 01 00       	push   $0x1b8db
   15b7e:	e8 a4 b9 ff ff       	call   11527 <cio_printf>
   15b83:	83 c4 10             	add    $0x10,%esp
	return;
   15b86:	90                   	nop
   15b87:	eb 0f                	jmp    15b98 <sys_waitpid+0x303>
		return;
   15b89:	90                   	nop
   15b8a:	eb 0d                	jmp    15b99 <sys_waitpid+0x304>
				return;
   15b8c:	90                   	nop
   15b8d:	eb 0a                	jmp    15b99 <sys_waitpid+0x304>
			return;
   15b8f:	90                   	nop
   15b90:	eb 07                	jmp    15b99 <sys_waitpid+0x304>
			return;
   15b92:	90                   	nop
   15b93:	eb 04                	jmp    15b99 <sys_waitpid+0x304>
		return;
   15b95:	90                   	nop
   15b96:	eb 01                	jmp    15b99 <sys_waitpid+0x304>
	return;
   15b98:	90                   	nop
}
   15b99:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   15b9c:	c9                   	leave  
   15b9d:	c3                   	ret    

00015b9e <sys_fork>:
**
** Creates a new process that is a duplicate of the calling process.
** Returns the child's PID to the parent, and 0 to the child, on success;
** else, returns an error code to the parent.
*/
SYSIMPL(fork) {
   15b9e:	55                   	push   %ebp
   15b9f:	89 e5                	mov    %esp,%ebp
   15ba1:	53                   	push   %ebx
   15ba2:	83 ec 14             	sub    $0x14,%esp

	// sanity check
	assert( pcb != NULL );
   15ba5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15ba9:	75 3b                	jne    15be6 <sys_fork+0x48>
   15bab:	83 ec 04             	sub    $0x4,%esp
   15bae:	68 a0 b8 01 00       	push   $0x1b8a0
   15bb3:	6a 00                	push   $0x0
   15bb5:	68 2e 01 00 00       	push   $0x12e
   15bba:	68 a9 b8 01 00       	push   $0x1b8a9
   15bbf:	68 74 ba 01 00       	push   $0x1ba74
   15bc4:	68 b4 b8 01 00       	push   $0x1b8b4
   15bc9:	68 00 00 02 00       	push   $0x20000
   15bce:	e8 34 cb ff ff       	call   12707 <sprint>
   15bd3:	83 c4 20             	add    $0x20,%esp
   15bd6:	83 ec 0c             	sub    $0xc,%esp
   15bd9:	68 00 00 02 00       	push   $0x20000
   15bde:	e8 a4 c8 ff ff       	call   12487 <kpanic>
   15be3:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   15be6:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15beb:	85 c0                	test   %eax,%eax
   15bed:	74 1c                	je     15c0b <sys_fork+0x6d>
   15bef:	8b 45 08             	mov    0x8(%ebp),%eax
   15bf2:	8b 40 18             	mov    0x18(%eax),%eax
   15bf5:	83 ec 04             	sub    $0x4,%esp
   15bf8:	50                   	push   %eax
   15bf9:	68 74 ba 01 00       	push   $0x1ba74
   15bfe:	68 ca b8 01 00       	push   $0x1b8ca
   15c03:	e8 1f b9 ff ff       	call   11527 <cio_printf>
   15c08:	83 c4 10             	add    $0x10,%esp

	// Make sure there's room for another process!
	pcb_t *new;
	if( pcb_alloc(&new) != SUCCESS || new == NULL ) {
   15c0b:	83 ec 0c             	sub    $0xc,%esp
   15c0e:	8d 45 ec             	lea    -0x14(%ebp),%eax
   15c11:	50                   	push   %eax
   15c12:	e8 4f dc ff ff       	call   13866 <pcb_alloc>
   15c17:	83 c4 10             	add    $0x10,%esp
   15c1a:	85 c0                	test   %eax,%eax
   15c1c:	75 07                	jne    15c25 <sys_fork+0x87>
   15c1e:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15c21:	85 c0                	test   %eax,%eax
   15c23:	75 3c                	jne    15c61 <sys_fork+0xc3>
		RET(pcb) = E_NO_PROCS;
   15c25:	8b 45 08             	mov    0x8(%ebp),%eax
   15c28:	8b 00                	mov    (%eax),%eax
   15c2a:	c7 40 30 f9 ff ff ff 	movl   $0xfffffff9,0x30(%eax)
		SYSCALL_EXIT( RET(pcb) );
   15c31:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15c36:	85 c0                	test   %eax,%eax
   15c38:	0f 84 c0 01 00 00    	je     15dfe <sys_fork+0x260>
   15c3e:	8b 45 08             	mov    0x8(%ebp),%eax
   15c41:	8b 00                	mov    (%eax),%eax
   15c43:	8b 40 30             	mov    0x30(%eax),%eax
   15c46:	83 ec 04             	sub    $0x4,%esp
   15c49:	50                   	push   %eax
   15c4a:	68 74 ba 01 00       	push   $0x1ba74
   15c4f:	68 db b8 01 00       	push   $0x1b8db
   15c54:	e8 ce b8 ff ff       	call   11527 <cio_printf>
   15c59:	83 c4 10             	add    $0x10,%esp
		return;
   15c5c:	e9 9d 01 00 00       	jmp    15dfe <sys_fork+0x260>
	}

	// create a stack for the new child
	new->stack = pcb_stack_alloc( N_USTKPAGES );
   15c61:	8b 5d ec             	mov    -0x14(%ebp),%ebx
   15c64:	83 ec 0c             	sub    $0xc,%esp
   15c67:	6a 02                	push   $0x2
   15c69:	e8 f8 dc ff ff       	call   13966 <pcb_stack_alloc>
   15c6e:	83 c4 10             	add    $0x10,%esp
   15c71:	89 43 04             	mov    %eax,0x4(%ebx)
	if( new->stack == NULL ) {
   15c74:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15c77:	8b 40 04             	mov    0x4(%eax),%eax
   15c7a:	85 c0                	test   %eax,%eax
   15c7c:	75 44                	jne    15cc2 <sys_fork+0x124>
		pcb_free( new );
   15c7e:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15c81:	83 ec 0c             	sub    $0xc,%esp
   15c84:	50                   	push   %eax
   15c85:	e8 52 dc ff ff       	call   138dc <pcb_free>
   15c8a:	83 c4 10             	add    $0x10,%esp
		RET(pcb) = E_NO_PROCS;
   15c8d:	8b 45 08             	mov    0x8(%ebp),%eax
   15c90:	8b 00                	mov    (%eax),%eax
   15c92:	c7 40 30 f9 ff ff ff 	movl   $0xfffffff9,0x30(%eax)
		SYSCALL_EXIT(E_NO_PROCS);
   15c99:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15c9e:	85 c0                	test   %eax,%eax
   15ca0:	0f 84 5b 01 00 00    	je     15e01 <sys_fork+0x263>
   15ca6:	83 ec 04             	sub    $0x4,%esp
   15ca9:	6a f9                	push   $0xfffffff9
   15cab:	68 74 ba 01 00       	push   $0x1ba74
   15cb0:	68 db b8 01 00       	push   $0x1b8db
   15cb5:	e8 6d b8 ff ff       	call   11527 <cio_printf>
   15cba:	83 c4 10             	add    $0x10,%esp
		return;
   15cbd:	e9 3f 01 00 00       	jmp    15e01 <sys_fork+0x263>
	}
	// remember that we used the default size
	new->stkpgs = N_USTKPAGES;
   15cc2:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15cc5:	c7 40 28 02 00 00 00 	movl   $0x2,0x28(%eax)

	// duplicate the parent's stack
	memcpy( (void *)new->stack, (void *)pcb->stack, N_USTKPAGES * SZ_PAGE );
   15ccc:	8b 45 08             	mov    0x8(%ebp),%eax
   15ccf:	8b 50 04             	mov    0x4(%eax),%edx
   15cd2:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15cd5:	8b 40 04             	mov    0x4(%eax),%eax
   15cd8:	83 ec 04             	sub    $0x4,%esp
   15cdb:	68 00 20 00 00       	push   $0x2000
   15ce0:	52                   	push   %edx
   15ce1:	50                   	push   %eax
   15ce2:	e8 be c8 ff ff       	call   125a5 <memcpy>
   15ce7:	83 c4 10             	add    $0x10,%esp
    ** them, as that's impractical. As a result, user code that relies on
    ** such pointers may behave strangely after a fork().
    */

    // Figure out the byte offset from one stack to the other.
    int32_t offset = (void *) new->stack - (void *) pcb->stack;
   15cea:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15ced:	8b 40 04             	mov    0x4(%eax),%eax
   15cf0:	89 c2                	mov    %eax,%edx
   15cf2:	8b 45 08             	mov    0x8(%ebp),%eax
   15cf5:	8b 40 04             	mov    0x4(%eax),%eax
   15cf8:	29 c2                	sub    %eax,%edx
   15cfa:	89 d0                	mov    %edx,%eax
   15cfc:	89 45 f0             	mov    %eax,-0x10(%ebp)

    // Add this to the child's context pointer.
    new->context = (context_t *) (((void *)pcb->context) + offset);
   15cff:	8b 45 08             	mov    0x8(%ebp),%eax
   15d02:	8b 08                	mov    (%eax),%ecx
   15d04:	8b 55 f0             	mov    -0x10(%ebp),%edx
   15d07:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d0a:	01 ca                	add    %ecx,%edx
   15d0c:	89 10                	mov    %edx,(%eax)

    // Fix the child's ESP and EBP values IFF they're non-zero.
    if( REG(new,ebp) != 0 ) {
   15d0e:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d11:	8b 00                	mov    (%eax),%eax
   15d13:	8b 40 1c             	mov    0x1c(%eax),%eax
   15d16:	85 c0                	test   %eax,%eax
   15d18:	74 15                	je     15d2f <sys_fork+0x191>
        REG(new,ebp) += offset;
   15d1a:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d1d:	8b 00                	mov    (%eax),%eax
   15d1f:	8b 48 1c             	mov    0x1c(%eax),%ecx
   15d22:	8b 55 f0             	mov    -0x10(%ebp),%edx
   15d25:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d28:	8b 00                	mov    (%eax),%eax
   15d2a:	01 ca                	add    %ecx,%edx
   15d2c:	89 50 1c             	mov    %edx,0x1c(%eax)
    }
    if( REG(new,esp) != 0 ) {
   15d2f:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d32:	8b 00                	mov    (%eax),%eax
   15d34:	8b 40 20             	mov    0x20(%eax),%eax
   15d37:	85 c0                	test   %eax,%eax
   15d39:	74 15                	je     15d50 <sys_fork+0x1b2>
        REG(new,esp) += offset;
   15d3b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d3e:	8b 00                	mov    (%eax),%eax
   15d40:	8b 48 20             	mov    0x20(%eax),%ecx
   15d43:	8b 55 f0             	mov    -0x10(%ebp),%edx
   15d46:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d49:	8b 00                	mov    (%eax),%eax
   15d4b:	01 ca                	add    %ecx,%edx
   15d4d:	89 50 20             	mov    %edx,0x20(%eax)
    }

    // Follow the EBP chain through the child's stack.
    uint32_t *bp = (uint32_t *) REG(new,ebp);
   15d50:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d53:	8b 00                	mov    (%eax),%eax
   15d55:	8b 40 1c             	mov    0x1c(%eax),%eax
   15d58:	89 45 f4             	mov    %eax,-0xc(%ebp)
    while( bp ) {
   15d5b:	eb 17                	jmp    15d74 <sys_fork+0x1d6>
        *bp += offset;
   15d5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15d60:	8b 10                	mov    (%eax),%edx
   15d62:	8b 45 f0             	mov    -0x10(%ebp),%eax
   15d65:	01 c2                	add    %eax,%edx
   15d67:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15d6a:	89 10                	mov    %edx,(%eax)
        bp = (uint32_t *) *bp;
   15d6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15d6f:	8b 00                	mov    (%eax),%eax
   15d71:	89 45 f4             	mov    %eax,-0xc(%ebp)
    while( bp ) {
   15d74:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15d78:	75 e3                	jne    15d5d <sys_fork+0x1bf>
    }

	// Set the child's identity.
	new->pid = next_pid++;
   15d7a:	a1 1c 20 02 00       	mov    0x2201c,%eax
   15d7f:	8d 50 01             	lea    0x1(%eax),%edx
   15d82:	89 15 1c 20 02 00    	mov    %edx,0x2201c
   15d88:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15d8b:	89 42 18             	mov    %eax,0x18(%edx)
	new->parent = pcb;
   15d8e:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d91:	8b 55 08             	mov    0x8(%ebp),%edx
   15d94:	89 50 0c             	mov    %edx,0xc(%eax)
	new->state = STATE_NEW;
   15d97:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d9a:	c7 40 1c 01 00 00 00 	movl   $0x1,0x1c(%eax)

	// replicate other things inherited from the parent
	new->priority = pcb->priority;
   15da1:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15da4:	8b 55 08             	mov    0x8(%ebp),%edx
   15da7:	8b 52 20             	mov    0x20(%edx),%edx
   15daa:	89 50 20             	mov    %edx,0x20(%eax)

	// Set the return values for the two processes.
	RET(pcb) = new->pid;
   15dad:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15db0:	8b 45 08             	mov    0x8(%ebp),%eax
   15db3:	8b 00                	mov    (%eax),%eax
   15db5:	8b 52 18             	mov    0x18(%edx),%edx
   15db8:	89 50 30             	mov    %edx,0x30(%eax)
	RET(new) = 0;
   15dbb:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15dbe:	8b 00                	mov    (%eax),%eax
   15dc0:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)

	// Schedule the child, and let the parent continue.
	schedule( new );
   15dc7:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15dca:	83 ec 0c             	sub    $0xc,%esp
   15dcd:	50                   	push   %eax
   15dce:	e8 fc e5 ff ff       	call   143cf <schedule>
   15dd3:	83 c4 10             	add    $0x10,%esp

	SYSCALL_EXIT( new->pid );
   15dd6:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15ddb:	85 c0                	test   %eax,%eax
   15ddd:	74 25                	je     15e04 <sys_fork+0x266>
   15ddf:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15de2:	8b 40 18             	mov    0x18(%eax),%eax
   15de5:	83 ec 04             	sub    $0x4,%esp
   15de8:	50                   	push   %eax
   15de9:	68 74 ba 01 00       	push   $0x1ba74
   15dee:	68 db b8 01 00       	push   $0x1b8db
   15df3:	e8 2f b7 ff ff       	call   11527 <cio_printf>
   15df8:	83 c4 10             	add    $0x10,%esp
	return;
   15dfb:	90                   	nop
   15dfc:	eb 06                	jmp    15e04 <sys_fork+0x266>
		return;
   15dfe:	90                   	nop
   15dff:	eb 04                	jmp    15e05 <sys_fork+0x267>
		return;
   15e01:	90                   	nop
   15e02:	eb 01                	jmp    15e05 <sys_fork+0x267>
	return;
   15e04:	90                   	nop
}
   15e05:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   15e08:	c9                   	leave  
   15e09:	c3                   	ret    

00015e0a <sys_exec>:
** indicated program.
**
** Returns only on failure.
*/
SYSIMPL(exec)
{
   15e0a:	55                   	push   %ebp
   15e0b:	89 e5                	mov    %esp,%ebp
   15e0d:	83 ec 18             	sub    $0x18,%esp
	// sanity check
	assert( pcb != NULL );
   15e10:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15e14:	75 3b                	jne    15e51 <sys_exec+0x47>
   15e16:	83 ec 04             	sub    $0x4,%esp
   15e19:	68 a0 b8 01 00       	push   $0x1b8a0
   15e1e:	6a 00                	push   $0x0
   15e20:	68 8a 01 00 00       	push   $0x18a
   15e25:	68 a9 b8 01 00       	push   $0x1b8a9
   15e2a:	68 80 ba 01 00       	push   $0x1ba80
   15e2f:	68 b4 b8 01 00       	push   $0x1b8b4
   15e34:	68 00 00 02 00       	push   $0x20000
   15e39:	e8 c9 c8 ff ff       	call   12707 <sprint>
   15e3e:	83 c4 20             	add    $0x20,%esp
   15e41:	83 ec 0c             	sub    $0xc,%esp
   15e44:	68 00 00 02 00       	push   $0x20000
   15e49:	e8 39 c6 ff ff       	call   12487 <kpanic>
   15e4e:	83 c4 10             	add    $0x10,%esp

	uint_t what = ARG(pcb,1);
   15e51:	8b 45 08             	mov    0x8(%ebp),%eax
   15e54:	8b 00                	mov    (%eax),%eax
   15e56:	83 c0 48             	add    $0x48,%eax
   15e59:	8b 40 04             	mov    0x4(%eax),%eax
   15e5c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	const char **args = (const char **) ARG(pcb,2);
   15e5f:	8b 45 08             	mov    0x8(%ebp),%eax
   15e62:	8b 00                	mov    (%eax),%eax
   15e64:	83 c0 48             	add    $0x48,%eax
   15e67:	83 c0 08             	add    $0x8,%eax
   15e6a:	8b 00                	mov    (%eax),%eax
   15e6c:	89 45 f0             	mov    %eax,-0x10(%ebp)

	SYSCALL_ENTER( pcb->pid );
   15e6f:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15e74:	85 c0                	test   %eax,%eax
   15e76:	74 1c                	je     15e94 <sys_exec+0x8a>
   15e78:	8b 45 08             	mov    0x8(%ebp),%eax
   15e7b:	8b 40 18             	mov    0x18(%eax),%eax
   15e7e:	83 ec 04             	sub    $0x4,%esp
   15e81:	50                   	push   %eax
   15e82:	68 80 ba 01 00       	push   $0x1ba80
   15e87:	68 ca b8 01 00       	push   $0x1b8ca
   15e8c:	e8 96 b6 ff ff       	call   11527 <cio_printf>
   15e91:	83 c4 10             	add    $0x10,%esp

	// we create a new stack for the process so we don't have to
	// worry about overwriting data in the old stack; however, we
	// need to keep the old one around until after we have copied
	// all the argument data from it.
	void *oldstack = (void *) pcb->stack;
   15e94:	8b 45 08             	mov    0x8(%ebp),%eax
   15e97:	8b 40 04             	mov    0x4(%eax),%eax
   15e9a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32_t oldsize = pcb->stkpgs;
   15e9d:	8b 45 08             	mov    0x8(%ebp),%eax
   15ea0:	8b 40 28             	mov    0x28(%eax),%eax
   15ea3:	89 45 e8             	mov    %eax,-0x18(%ebp)

	// allocate a new stack of the default size
	pcb->stack = pcb_stack_alloc( N_USTKPAGES );
   15ea6:	83 ec 0c             	sub    $0xc,%esp
   15ea9:	6a 02                	push   $0x2
   15eab:	e8 b6 da ff ff       	call   13966 <pcb_stack_alloc>
   15eb0:	83 c4 10             	add    $0x10,%esp
   15eb3:	89 c2                	mov    %eax,%edx
   15eb5:	8b 45 08             	mov    0x8(%ebp),%eax
   15eb8:	89 50 04             	mov    %edx,0x4(%eax)
	assert( pcb->stack != NULL );
   15ebb:	8b 45 08             	mov    0x8(%ebp),%eax
   15ebe:	8b 40 04             	mov    0x4(%eax),%eax
   15ec1:	85 c0                	test   %eax,%eax
   15ec3:	75 3b                	jne    15f00 <sys_exec+0xf6>
   15ec5:	83 ec 04             	sub    $0x4,%esp
   15ec8:	68 0d b9 01 00       	push   $0x1b90d
   15ecd:	6a 00                	push   $0x0
   15ecf:	68 9d 01 00 00       	push   $0x19d
   15ed4:	68 a9 b8 01 00       	push   $0x1b8a9
   15ed9:	68 80 ba 01 00       	push   $0x1ba80
   15ede:	68 b4 b8 01 00       	push   $0x1b8b4
   15ee3:	68 00 00 02 00       	push   $0x20000
   15ee8:	e8 1a c8 ff ff       	call   12707 <sprint>
   15eed:	83 c4 20             	add    $0x20,%esp
   15ef0:	83 ec 0c             	sub    $0xc,%esp
   15ef3:	68 00 00 02 00       	push   $0x20000
   15ef8:	e8 8a c5 ff ff       	call   12487 <kpanic>
   15efd:	83 c4 10             	add    $0x10,%esp
	pcb->stkpgs = N_USTKPAGES;
   15f00:	8b 45 08             	mov    0x8(%ebp),%eax
   15f03:	c7 40 28 02 00 00 00 	movl   $0x2,0x28(%eax)

	// set up the new stack using the old stack data
	pcb->context = stack_setup( pcb, what, args, true );
   15f0a:	6a 01                	push   $0x1
   15f0c:	ff 75 f0             	pushl  -0x10(%ebp)
   15f0f:	ff 75 f4             	pushl  -0xc(%ebp)
   15f12:	ff 75 08             	pushl  0x8(%ebp)
   15f15:	e8 93 0b 00 00       	call   16aad <stack_setup>
   15f1a:	83 c4 10             	add    $0x10,%esp
   15f1d:	89 c2                	mov    %eax,%edx
   15f1f:	8b 45 08             	mov    0x8(%ebp),%eax
   15f22:	89 10                	mov    %edx,(%eax)
	assert( pcb->context != NULL );
   15f24:	8b 45 08             	mov    0x8(%ebp),%eax
   15f27:	8b 00                	mov    (%eax),%eax
   15f29:	85 c0                	test   %eax,%eax
   15f2b:	75 3b                	jne    15f68 <sys_exec+0x15e>
   15f2d:	83 ec 04             	sub    $0x4,%esp
   15f30:	68 1d b9 01 00       	push   $0x1b91d
   15f35:	6a 00                	push   $0x0
   15f37:	68 a2 01 00 00       	push   $0x1a2
   15f3c:	68 a9 b8 01 00       	push   $0x1b8a9
   15f41:	68 80 ba 01 00       	push   $0x1ba80
   15f46:	68 b4 b8 01 00       	push   $0x1b8b4
   15f4b:	68 00 00 02 00       	push   $0x20000
   15f50:	e8 b2 c7 ff ff       	call   12707 <sprint>
   15f55:	83 c4 20             	add    $0x20,%esp
   15f58:	83 ec 0c             	sub    $0xc,%esp
   15f5b:	68 00 00 02 00       	push   $0x20000
   15f60:	e8 22 c5 ff ff       	call   12487 <kpanic>
   15f65:	83 c4 10             	add    $0x10,%esp

	// now we can safely free the old stack
	pcb_stack_free( oldstack, oldsize );
   15f68:	83 ec 08             	sub    $0x8,%esp
   15f6b:	ff 75 e8             	pushl  -0x18(%ebp)
   15f6e:	ff 75 ec             	pushl  -0x14(%ebp)
   15f71:	e8 34 da ff ff       	call   139aa <pcb_stack_free>
   15f76:	83 c4 10             	add    $0x10,%esp
	 **	(C) reset this one's time slice and let it continue
	 **
	 ** We choose option A.
	 */

	schedule( pcb );
   15f79:	83 ec 0c             	sub    $0xc,%esp
   15f7c:	ff 75 08             	pushl  0x8(%ebp)
   15f7f:	e8 4b e4 ff ff       	call   143cf <schedule>
   15f84:	83 c4 10             	add    $0x10,%esp

	// reset 'current' to keep dispatch() happy
	current = NULL;
   15f87:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   15f8e:	00 00 00 
	dispatch();
   15f91:	e8 fa e4 ff ff       	call   14490 <dispatch>
}
   15f96:	90                   	nop
   15f97:	c9                   	leave  
   15f98:	c3                   	ret    

00015f99 <sys_read>:
**		int read( uint_t chan, void *buffer, uint_t length );
**
** Reads up to 'length' bytes from 'chan' into 'buffer'. Returns the
** count of bytes actually transferred.
*/
SYSIMPL(read) {
   15f99:	55                   	push   %ebp
   15f9a:	89 e5                	mov    %esp,%ebp
   15f9c:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   15f9f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15fa3:	75 3b                	jne    15fe0 <sys_read+0x47>
   15fa5:	83 ec 04             	sub    $0x4,%esp
   15fa8:	68 a0 b8 01 00       	push   $0x1b8a0
   15fad:	6a 00                	push   $0x0
   15faf:	68 c3 01 00 00       	push   $0x1c3
   15fb4:	68 a9 b8 01 00       	push   $0x1b8a9
   15fb9:	68 8c ba 01 00       	push   $0x1ba8c
   15fbe:	68 b4 b8 01 00       	push   $0x1b8b4
   15fc3:	68 00 00 02 00       	push   $0x20000
   15fc8:	e8 3a c7 ff ff       	call   12707 <sprint>
   15fcd:	83 c4 20             	add    $0x20,%esp
   15fd0:	83 ec 0c             	sub    $0xc,%esp
   15fd3:	68 00 00 02 00       	push   $0x20000
   15fd8:	e8 aa c4 ff ff       	call   12487 <kpanic>
   15fdd:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   15fe0:	a1 e0 28 02 00       	mov    0x228e0,%eax
   15fe5:	85 c0                	test   %eax,%eax
   15fe7:	74 1c                	je     16005 <sys_read+0x6c>
   15fe9:	8b 45 08             	mov    0x8(%ebp),%eax
   15fec:	8b 40 18             	mov    0x18(%eax),%eax
   15fef:	83 ec 04             	sub    $0x4,%esp
   15ff2:	50                   	push   %eax
   15ff3:	68 8c ba 01 00       	push   $0x1ba8c
   15ff8:	68 ca b8 01 00       	push   $0x1b8ca
   15ffd:	e8 25 b5 ff ff       	call   11527 <cio_printf>
   16002:	83 c4 10             	add    $0x10,%esp
	
	// grab the arguments
	uint_t chan = ARG(pcb,1);
   16005:	8b 45 08             	mov    0x8(%ebp),%eax
   16008:	8b 00                	mov    (%eax),%eax
   1600a:	83 c0 48             	add    $0x48,%eax
   1600d:	8b 40 04             	mov    0x4(%eax),%eax
   16010:	89 45 f4             	mov    %eax,-0xc(%ebp)
	char *buf = (char *) ARG(pcb,2);
   16013:	8b 45 08             	mov    0x8(%ebp),%eax
   16016:	8b 00                	mov    (%eax),%eax
   16018:	83 c0 48             	add    $0x48,%eax
   1601b:	83 c0 08             	add    $0x8,%eax
   1601e:	8b 00                	mov    (%eax),%eax
   16020:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint_t len = ARG(pcb,3);
   16023:	8b 45 08             	mov    0x8(%ebp),%eax
   16026:	8b 00                	mov    (%eax),%eax
   16028:	83 c0 48             	add    $0x48,%eax
   1602b:	8b 40 0c             	mov    0xc(%eax),%eax
   1602e:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// if the buffer is of length 0, we're done!
	if( len == 0 ) {
   16031:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   16035:	75 35                	jne    1606c <sys_read+0xd3>
		RET(pcb) = 0;
   16037:	8b 45 08             	mov    0x8(%ebp),%eax
   1603a:	8b 00                	mov    (%eax),%eax
   1603c:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
		SYSCALL_EXIT( 0 );
   16043:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16048:	85 c0                	test   %eax,%eax
   1604a:	0f 84 2b 01 00 00    	je     1617b <sys_read+0x1e2>
   16050:	83 ec 04             	sub    $0x4,%esp
   16053:	6a 00                	push   $0x0
   16055:	68 8c ba 01 00       	push   $0x1ba8c
   1605a:	68 db b8 01 00       	push   $0x1b8db
   1605f:	e8 c3 b4 ff ff       	call   11527 <cio_printf>
   16064:	83 c4 10             	add    $0x10,%esp
		return;
   16067:	e9 0f 01 00 00       	jmp    1617b <sys_read+0x1e2>
	}

	// try to get the next character(s)
	int n = 0;
   1606c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	if( chan == CHAN_CIO ) {
   16073:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   16077:	0f 85 85 00 00 00    	jne    16102 <sys_read+0x169>

		// console input is non-blocking
		if( cio_input_queue() < 1 ) {
   1607d:	e8 29 b7 ff ff       	call   117ab <cio_input_queue>
   16082:	85 c0                	test   %eax,%eax
   16084:	7f 35                	jg     160bb <sys_read+0x122>
			RET(pcb) = 0;
   16086:	8b 45 08             	mov    0x8(%ebp),%eax
   16089:	8b 00                	mov    (%eax),%eax
   1608b:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
			SYSCALL_EXIT( 0 );
   16092:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16097:	85 c0                	test   %eax,%eax
   16099:	0f 84 df 00 00 00    	je     1617e <sys_read+0x1e5>
   1609f:	83 ec 04             	sub    $0x4,%esp
   160a2:	6a 00                	push   $0x0
   160a4:	68 8c ba 01 00       	push   $0x1ba8c
   160a9:	68 db b8 01 00       	push   $0x1b8db
   160ae:	e8 74 b4 ff ff       	call   11527 <cio_printf>
   160b3:	83 c4 10             	add    $0x10,%esp
			return;
   160b6:	e9 c3 00 00 00       	jmp    1617e <sys_read+0x1e5>
		}
		// at least one character
		n = cio_gets( buf, len );
   160bb:	83 ec 08             	sub    $0x8,%esp
   160be:	ff 75 ec             	pushl  -0x14(%ebp)
   160c1:	ff 75 f0             	pushl  -0x10(%ebp)
   160c4:	e8 91 b6 ff ff       	call   1175a <cio_gets>
   160c9:	83 c4 10             	add    $0x10,%esp
   160cc:	89 45 e8             	mov    %eax,-0x18(%ebp)
		RET(pcb) = n;
   160cf:	8b 45 08             	mov    0x8(%ebp),%eax
   160d2:	8b 00                	mov    (%eax),%eax
   160d4:	8b 55 e8             	mov    -0x18(%ebp),%edx
   160d7:	89 50 30             	mov    %edx,0x30(%eax)
		SYSCALL_EXIT( n );
   160da:	a1 e0 28 02 00       	mov    0x228e0,%eax
   160df:	85 c0                	test   %eax,%eax
   160e1:	0f 84 9a 00 00 00    	je     16181 <sys_read+0x1e8>
   160e7:	8b 45 e8             	mov    -0x18(%ebp),%eax
   160ea:	83 ec 04             	sub    $0x4,%esp
   160ed:	50                   	push   %eax
   160ee:	68 8c ba 01 00       	push   $0x1ba8c
   160f3:	68 db b8 01 00       	push   $0x1b8db
   160f8:	e8 2a b4 ff ff       	call   11527 <cio_printf>
   160fd:	83 c4 10             	add    $0x10,%esp
		return;
   16100:	eb 7f                	jmp    16181 <sys_read+0x1e8>

	} else if( chan == CHAN_SIO ) {
   16102:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
   16106:	75 44                	jne    1614c <sys_read+0x1b3>

		// SIO input is blocking, so if there are no characters
		// available, we'll block this process
		n = sio_read( buf, len );
   16108:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1610b:	83 ec 08             	sub    $0x8,%esp
   1610e:	50                   	push   %eax
   1610f:	ff 75 f0             	pushl  -0x10(%ebp)
   16112:	e8 66 f0 ff ff       	call   1517d <sio_read>
   16117:	83 c4 10             	add    $0x10,%esp
   1611a:	89 45 e8             	mov    %eax,-0x18(%ebp)
		RET(pcb) = n;
   1611d:	8b 45 08             	mov    0x8(%ebp),%eax
   16120:	8b 00                	mov    (%eax),%eax
   16122:	8b 55 e8             	mov    -0x18(%ebp),%edx
   16125:	89 50 30             	mov    %edx,0x30(%eax)
		SYSCALL_EXIT( n );
   16128:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1612d:	85 c0                	test   %eax,%eax
   1612f:	74 53                	je     16184 <sys_read+0x1eb>
   16131:	8b 45 e8             	mov    -0x18(%ebp),%eax
   16134:	83 ec 04             	sub    $0x4,%esp
   16137:	50                   	push   %eax
   16138:	68 8c ba 01 00       	push   $0x1ba8c
   1613d:	68 db b8 01 00       	push   $0x1b8db
   16142:	e8 e0 b3 ff ff       	call   11527 <cio_printf>
   16147:	83 c4 10             	add    $0x10,%esp
		return;
   1614a:	eb 38                	jmp    16184 <sys_read+0x1eb>

	}

	// bad channel code
	RET(pcb) = E_BAD_PARAM;
   1614c:	8b 45 08             	mov    0x8(%ebp),%eax
   1614f:	8b 00                	mov    (%eax),%eax
   16151:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
	SYSCALL_EXIT( E_BAD_PARAM );
   16158:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1615d:	85 c0                	test   %eax,%eax
   1615f:	74 26                	je     16187 <sys_read+0x1ee>
   16161:	83 ec 04             	sub    $0x4,%esp
   16164:	6a fe                	push   $0xfffffffe
   16166:	68 8c ba 01 00       	push   $0x1ba8c
   1616b:	68 db b8 01 00       	push   $0x1b8db
   16170:	e8 b2 b3 ff ff       	call   11527 <cio_printf>
   16175:	83 c4 10             	add    $0x10,%esp
	return;
   16178:	90                   	nop
   16179:	eb 0c                	jmp    16187 <sys_read+0x1ee>
		return;
   1617b:	90                   	nop
   1617c:	eb 0a                	jmp    16188 <sys_read+0x1ef>
			return;
   1617e:	90                   	nop
   1617f:	eb 07                	jmp    16188 <sys_read+0x1ef>
		return;
   16181:	90                   	nop
   16182:	eb 04                	jmp    16188 <sys_read+0x1ef>
		return;
   16184:	90                   	nop
   16185:	eb 01                	jmp    16188 <sys_read+0x1ef>
	return;
   16187:	90                   	nop
}
   16188:	c9                   	leave  
   16189:	c3                   	ret    

0001618a <sys_write>:
**		int write( uint_t chan, const void *buffer, uint_t length );
**
** Writes 'length' bytes from 'buffer' to 'chan'. Returns the
** count of bytes actually transferred.
*/
SYSIMPL(write) {
   1618a:	55                   	push   %ebp
   1618b:	89 e5                	mov    %esp,%ebp
   1618d:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   16190:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16194:	75 3b                	jne    161d1 <sys_write+0x47>
   16196:	83 ec 04             	sub    $0x4,%esp
   16199:	68 a0 b8 01 00       	push   $0x1b8a0
   1619e:	6a 00                	push   $0x0
   161a0:	68 01 02 00 00       	push   $0x201
   161a5:	68 a9 b8 01 00       	push   $0x1b8a9
   161aa:	68 98 ba 01 00       	push   $0x1ba98
   161af:	68 b4 b8 01 00       	push   $0x1b8b4
   161b4:	68 00 00 02 00       	push   $0x20000
   161b9:	e8 49 c5 ff ff       	call   12707 <sprint>
   161be:	83 c4 20             	add    $0x20,%esp
   161c1:	83 ec 0c             	sub    $0xc,%esp
   161c4:	68 00 00 02 00       	push   $0x20000
   161c9:	e8 b9 c2 ff ff       	call   12487 <kpanic>
   161ce:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   161d1:	a1 e0 28 02 00       	mov    0x228e0,%eax
   161d6:	85 c0                	test   %eax,%eax
   161d8:	74 1c                	je     161f6 <sys_write+0x6c>
   161da:	8b 45 08             	mov    0x8(%ebp),%eax
   161dd:	8b 40 18             	mov    0x18(%eax),%eax
   161e0:	83 ec 04             	sub    $0x4,%esp
   161e3:	50                   	push   %eax
   161e4:	68 98 ba 01 00       	push   $0x1ba98
   161e9:	68 ca b8 01 00       	push   $0x1b8ca
   161ee:	e8 34 b3 ff ff       	call   11527 <cio_printf>
   161f3:	83 c4 10             	add    $0x10,%esp

	// grab the parameters
	uint_t chan = ARG(pcb,1);
   161f6:	8b 45 08             	mov    0x8(%ebp),%eax
   161f9:	8b 00                	mov    (%eax),%eax
   161fb:	83 c0 48             	add    $0x48,%eax
   161fe:	8b 40 04             	mov    0x4(%eax),%eax
   16201:	89 45 f0             	mov    %eax,-0x10(%ebp)
	char *buf = (char *) ARG(pcb,2);
   16204:	8b 45 08             	mov    0x8(%ebp),%eax
   16207:	8b 00                	mov    (%eax),%eax
   16209:	83 c0 48             	add    $0x48,%eax
   1620c:	83 c0 08             	add    $0x8,%eax
   1620f:	8b 00                	mov    (%eax),%eax
   16211:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint_t length = ARG(pcb,3);
   16214:	8b 45 08             	mov    0x8(%ebp),%eax
   16217:	8b 00                	mov    (%eax),%eax
   16219:	83 c0 48             	add    $0x48,%eax
   1621c:	8b 40 0c             	mov    0xc(%eax),%eax
   1621f:	89 45 e8             	mov    %eax,-0x18(%ebp)

	// this is almost insanely simple, but it does separate the
	// low-level device access fromm the higher-level syscall implementation

	// assume we write the indicated amount
	int rval = length;
   16222:	8b 45 e8             	mov    -0x18(%ebp),%eax
   16225:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// simplest case
	if( length >= 0 ) {

		if( chan == CHAN_CIO ) {
   16228:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   1622c:	75 14                	jne    16242 <sys_write+0xb8>

			cio_write( buf, length );
   1622e:	8b 45 e8             	mov    -0x18(%ebp),%eax
   16231:	83 ec 08             	sub    $0x8,%esp
   16234:	50                   	push   %eax
   16235:	ff 75 ec             	pushl  -0x14(%ebp)
   16238:	e8 a1 ac ff ff       	call   10ede <cio_write>
   1623d:	83 c4 10             	add    $0x10,%esp
   16240:	eb 21                	jmp    16263 <sys_write+0xd9>

		} else if( chan == CHAN_SIO ) {
   16242:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
   16246:	75 14                	jne    1625c <sys_write+0xd2>

			sio_write( buf, length );
   16248:	8b 45 e8             	mov    -0x18(%ebp),%eax
   1624b:	83 ec 08             	sub    $0x8,%esp
   1624e:	50                   	push   %eax
   1624f:	ff 75 ec             	pushl  -0x14(%ebp)
   16252:	e8 36 f0 ff ff       	call   1528d <sio_write>
   16257:	83 c4 10             	add    $0x10,%esp
   1625a:	eb 07                	jmp    16263 <sys_write+0xd9>

		} else {

			rval = E_BAD_CHAN;
   1625c:	c7 45 f4 fd ff ff ff 	movl   $0xfffffffd,-0xc(%ebp)

		}

	}

	RET(pcb) = rval;
   16263:	8b 45 08             	mov    0x8(%ebp),%eax
   16266:	8b 00                	mov    (%eax),%eax
   16268:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1626b:	89 50 30             	mov    %edx,0x30(%eax)

	SYSCALL_EXIT( rval );
   1626e:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16273:	85 c0                	test   %eax,%eax
   16275:	74 1a                	je     16291 <sys_write+0x107>
   16277:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1627a:	83 ec 04             	sub    $0x4,%esp
   1627d:	50                   	push   %eax
   1627e:	68 98 ba 01 00       	push   $0x1ba98
   16283:	68 db b8 01 00       	push   $0x1b8db
   16288:	e8 9a b2 ff ff       	call   11527 <cio_printf>
   1628d:	83 c4 10             	add    $0x10,%esp
	return;
   16290:	90                   	nop
   16291:	90                   	nop
}
   16292:	c9                   	leave  
   16293:	c3                   	ret    

00016294 <sys_getpid>:
** sys_getpid - returns the PID of the calling process
**
** Implements:
**		uint_t getpid( void );
*/
SYSIMPL(getpid) {
   16294:	55                   	push   %ebp
   16295:	89 e5                	mov    %esp,%ebp
   16297:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   1629a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1629e:	75 3b                	jne    162db <sys_getpid+0x47>
   162a0:	83 ec 04             	sub    $0x4,%esp
   162a3:	68 a0 b8 01 00       	push   $0x1b8a0
   162a8:	6a 00                	push   $0x0
   162aa:	68 32 02 00 00       	push   $0x232
   162af:	68 a9 b8 01 00       	push   $0x1b8a9
   162b4:	68 a4 ba 01 00       	push   $0x1baa4
   162b9:	68 b4 b8 01 00       	push   $0x1b8b4
   162be:	68 00 00 02 00       	push   $0x20000
   162c3:	e8 3f c4 ff ff       	call   12707 <sprint>
   162c8:	83 c4 20             	add    $0x20,%esp
   162cb:	83 ec 0c             	sub    $0xc,%esp
   162ce:	68 00 00 02 00       	push   $0x20000
   162d3:	e8 af c1 ff ff       	call   12487 <kpanic>
   162d8:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   162db:	a1 e0 28 02 00       	mov    0x228e0,%eax
   162e0:	85 c0                	test   %eax,%eax
   162e2:	74 1c                	je     16300 <sys_getpid+0x6c>
   162e4:	8b 45 08             	mov    0x8(%ebp),%eax
   162e7:	8b 40 18             	mov    0x18(%eax),%eax
   162ea:	83 ec 04             	sub    $0x4,%esp
   162ed:	50                   	push   %eax
   162ee:	68 a4 ba 01 00       	push   $0x1baa4
   162f3:	68 ca b8 01 00       	push   $0x1b8ca
   162f8:	e8 2a b2 ff ff       	call   11527 <cio_printf>
   162fd:	83 c4 10             	add    $0x10,%esp

	// return the time
	RET(pcb) = pcb->pid;
   16300:	8b 45 08             	mov    0x8(%ebp),%eax
   16303:	8b 00                	mov    (%eax),%eax
   16305:	8b 55 08             	mov    0x8(%ebp),%edx
   16308:	8b 52 18             	mov    0x18(%edx),%edx
   1630b:	89 50 30             	mov    %edx,0x30(%eax)
}
   1630e:	90                   	nop
   1630f:	c9                   	leave  
   16310:	c3                   	ret    

00016311 <sys_getppid>:
** sys_getppid - returns the PID of the parent of the calling process
**
** Implements:
**		uint_t getppid( void );
*/
SYSIMPL(getppid) {
   16311:	55                   	push   %ebp
   16312:	89 e5                	mov    %esp,%ebp
   16314:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   16317:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1631b:	75 3b                	jne    16358 <sys_getppid+0x47>
   1631d:	83 ec 04             	sub    $0x4,%esp
   16320:	68 a0 b8 01 00       	push   $0x1b8a0
   16325:	6a 00                	push   $0x0
   16327:	68 43 02 00 00       	push   $0x243
   1632c:	68 a9 b8 01 00       	push   $0x1b8a9
   16331:	68 b0 ba 01 00       	push   $0x1bab0
   16336:	68 b4 b8 01 00       	push   $0x1b8b4
   1633b:	68 00 00 02 00       	push   $0x20000
   16340:	e8 c2 c3 ff ff       	call   12707 <sprint>
   16345:	83 c4 20             	add    $0x20,%esp
   16348:	83 ec 0c             	sub    $0xc,%esp
   1634b:	68 00 00 02 00       	push   $0x20000
   16350:	e8 32 c1 ff ff       	call   12487 <kpanic>
   16355:	83 c4 10             	add    $0x10,%esp
	assert( pcb->parent != NULL );
   16358:	8b 45 08             	mov    0x8(%ebp),%eax
   1635b:	8b 40 0c             	mov    0xc(%eax),%eax
   1635e:	85 c0                	test   %eax,%eax
   16360:	75 3b                	jne    1639d <sys_getppid+0x8c>
   16362:	83 ec 04             	sub    $0x4,%esp
   16365:	68 2f b9 01 00       	push   $0x1b92f
   1636a:	6a 00                	push   $0x0
   1636c:	68 44 02 00 00       	push   $0x244
   16371:	68 a9 b8 01 00       	push   $0x1b8a9
   16376:	68 b0 ba 01 00       	push   $0x1bab0
   1637b:	68 b4 b8 01 00       	push   $0x1b8b4
   16380:	68 00 00 02 00       	push   $0x20000
   16385:	e8 7d c3 ff ff       	call   12707 <sprint>
   1638a:	83 c4 20             	add    $0x20,%esp
   1638d:	83 ec 0c             	sub    $0xc,%esp
   16390:	68 00 00 02 00       	push   $0x20000
   16395:	e8 ed c0 ff ff       	call   12487 <kpanic>
   1639a:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   1639d:	a1 e0 28 02 00       	mov    0x228e0,%eax
   163a2:	85 c0                	test   %eax,%eax
   163a4:	74 1c                	je     163c2 <sys_getppid+0xb1>
   163a6:	8b 45 08             	mov    0x8(%ebp),%eax
   163a9:	8b 40 18             	mov    0x18(%eax),%eax
   163ac:	83 ec 04             	sub    $0x4,%esp
   163af:	50                   	push   %eax
   163b0:	68 b0 ba 01 00       	push   $0x1bab0
   163b5:	68 ca b8 01 00       	push   $0x1b8ca
   163ba:	e8 68 b1 ff ff       	call   11527 <cio_printf>
   163bf:	83 c4 10             	add    $0x10,%esp

	// return the time
	RET(pcb) = pcb->parent->pid;
   163c2:	8b 45 08             	mov    0x8(%ebp),%eax
   163c5:	8b 50 0c             	mov    0xc(%eax),%edx
   163c8:	8b 45 08             	mov    0x8(%ebp),%eax
   163cb:	8b 00                	mov    (%eax),%eax
   163cd:	8b 52 18             	mov    0x18(%edx),%edx
   163d0:	89 50 30             	mov    %edx,0x30(%eax)
}
   163d3:	90                   	nop
   163d4:	c9                   	leave  
   163d5:	c3                   	ret    

000163d6 <sys_gettime>:
** sys_gettime - returns the current system time
**
** Implements:
**		uint32_t gettime( void );
*/
SYSIMPL(gettime) {
   163d6:	55                   	push   %ebp
   163d7:	89 e5                	mov    %esp,%ebp
   163d9:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   163dc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   163e0:	75 3b                	jne    1641d <sys_gettime+0x47>
   163e2:	83 ec 04             	sub    $0x4,%esp
   163e5:	68 a0 b8 01 00       	push   $0x1b8a0
   163ea:	6a 00                	push   $0x0
   163ec:	68 55 02 00 00       	push   $0x255
   163f1:	68 a9 b8 01 00       	push   $0x1b8a9
   163f6:	68 bc ba 01 00       	push   $0x1babc
   163fb:	68 b4 b8 01 00       	push   $0x1b8b4
   16400:	68 00 00 02 00       	push   $0x20000
   16405:	e8 fd c2 ff ff       	call   12707 <sprint>
   1640a:	83 c4 20             	add    $0x20,%esp
   1640d:	83 ec 0c             	sub    $0xc,%esp
   16410:	68 00 00 02 00       	push   $0x20000
   16415:	e8 6d c0 ff ff       	call   12487 <kpanic>
   1641a:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   1641d:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16422:	85 c0                	test   %eax,%eax
   16424:	74 1c                	je     16442 <sys_gettime+0x6c>
   16426:	8b 45 08             	mov    0x8(%ebp),%eax
   16429:	8b 40 18             	mov    0x18(%eax),%eax
   1642c:	83 ec 04             	sub    $0x4,%esp
   1642f:	50                   	push   %eax
   16430:	68 bc ba 01 00       	push   $0x1babc
   16435:	68 ca b8 01 00       	push   $0x1b8ca
   1643a:	e8 e8 b0 ff ff       	call   11527 <cio_printf>
   1643f:	83 c4 10             	add    $0x10,%esp

	// return the time
	RET(pcb) = system_time;
   16442:	8b 45 08             	mov    0x8(%ebp),%eax
   16445:	8b 00                	mov    (%eax),%eax
   16447:	8b 15 bc f1 01 00    	mov    0x1f1bc,%edx
   1644d:	89 50 30             	mov    %edx,0x30(%eax)
}
   16450:	90                   	nop
   16451:	c9                   	leave  
   16452:	c3                   	ret    

00016453 <sys_getprio>:
** sys_getprio - the scheduling priority of the calling process
**
** Implements:
**		int getprio( void );
*/
SYSIMPL(getprio) {
   16453:	55                   	push   %ebp
   16454:	89 e5                	mov    %esp,%ebp
   16456:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   16459:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1645d:	75 3b                	jne    1649a <sys_getprio+0x47>
   1645f:	83 ec 04             	sub    $0x4,%esp
   16462:	68 a0 b8 01 00       	push   $0x1b8a0
   16467:	6a 00                	push   $0x0
   16469:	68 66 02 00 00       	push   $0x266
   1646e:	68 a9 b8 01 00       	push   $0x1b8a9
   16473:	68 c8 ba 01 00       	push   $0x1bac8
   16478:	68 b4 b8 01 00       	push   $0x1b8b4
   1647d:	68 00 00 02 00       	push   $0x20000
   16482:	e8 80 c2 ff ff       	call   12707 <sprint>
   16487:	83 c4 20             	add    $0x20,%esp
   1648a:	83 ec 0c             	sub    $0xc,%esp
   1648d:	68 00 00 02 00       	push   $0x20000
   16492:	e8 f0 bf ff ff       	call   12487 <kpanic>
   16497:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   1649a:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1649f:	85 c0                	test   %eax,%eax
   164a1:	74 1c                	je     164bf <sys_getprio+0x6c>
   164a3:	8b 45 08             	mov    0x8(%ebp),%eax
   164a6:	8b 40 18             	mov    0x18(%eax),%eax
   164a9:	83 ec 04             	sub    $0x4,%esp
   164ac:	50                   	push   %eax
   164ad:	68 c8 ba 01 00       	push   $0x1bac8
   164b2:	68 ca b8 01 00       	push   $0x1b8ca
   164b7:	e8 6b b0 ff ff       	call   11527 <cio_printf>
   164bc:	83 c4 10             	add    $0x10,%esp

	// return the time
	RET(pcb) = pcb->priority;
   164bf:	8b 45 08             	mov    0x8(%ebp),%eax
   164c2:	8b 00                	mov    (%eax),%eax
   164c4:	8b 55 08             	mov    0x8(%ebp),%edx
   164c7:	8b 52 20             	mov    0x20(%edx),%edx
   164ca:	89 50 30             	mov    %edx,0x30(%eax)
}
   164cd:	90                   	nop
   164ce:	c9                   	leave  
   164cf:	c3                   	ret    

000164d0 <sys_setprio>:
** sys_setprio - sets the scheduling priority of the calling process
**
** Implements:
**		int setprio( int new );
*/
SYSIMPL(setprio) {
   164d0:	55                   	push   %ebp
   164d1:	89 e5                	mov    %esp,%ebp
   164d3:	83 ec 18             	sub    $0x18,%esp

	// sanity check!
	assert( pcb != NULL );
   164d6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   164da:	75 3b                	jne    16517 <sys_setprio+0x47>
   164dc:	83 ec 04             	sub    $0x4,%esp
   164df:	68 a0 b8 01 00       	push   $0x1b8a0
   164e4:	6a 00                	push   $0x0
   164e6:	68 77 02 00 00       	push   $0x277
   164eb:	68 a9 b8 01 00       	push   $0x1b8a9
   164f0:	68 d4 ba 01 00       	push   $0x1bad4
   164f5:	68 b4 b8 01 00       	push   $0x1b8b4
   164fa:	68 00 00 02 00       	push   $0x20000
   164ff:	e8 03 c2 ff ff       	call   12707 <sprint>
   16504:	83 c4 20             	add    $0x20,%esp
   16507:	83 ec 0c             	sub    $0xc,%esp
   1650a:	68 00 00 02 00       	push   $0x20000
   1650f:	e8 73 bf ff ff       	call   12487 <kpanic>
   16514:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   16517:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1651c:	85 c0                	test   %eax,%eax
   1651e:	74 1c                	je     1653c <sys_setprio+0x6c>
   16520:	8b 45 08             	mov    0x8(%ebp),%eax
   16523:	8b 40 18             	mov    0x18(%eax),%eax
   16526:	83 ec 04             	sub    $0x4,%esp
   16529:	50                   	push   %eax
   1652a:	68 d4 ba 01 00       	push   $0x1bad4
   1652f:	68 ca b8 01 00       	push   $0x1b8ca
   16534:	e8 ee af ff ff       	call   11527 <cio_printf>
   16539:	83 c4 10             	add    $0x10,%esp

	// remember the old priority
	int old = pcb->priority;
   1653c:	8b 45 08             	mov    0x8(%ebp),%eax
   1653f:	8b 40 20             	mov    0x20(%eax),%eax
   16542:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// set the priority
	pcb->priority = ARG(pcb,1);
   16545:	8b 45 08             	mov    0x8(%ebp),%eax
   16548:	8b 00                	mov    (%eax),%eax
   1654a:	83 c0 48             	add    $0x48,%eax
   1654d:	83 c0 04             	add    $0x4,%eax
   16550:	8b 10                	mov    (%eax),%edx
   16552:	8b 45 08             	mov    0x8(%ebp),%eax
   16555:	89 50 20             	mov    %edx,0x20(%eax)

	// return the old value
	RET(pcb) = old;
   16558:	8b 45 08             	mov    0x8(%ebp),%eax
   1655b:	8b 00                	mov    (%eax),%eax
   1655d:	8b 55 f4             	mov    -0xc(%ebp),%edx
   16560:	89 50 30             	mov    %edx,0x30(%eax)
}
   16563:	90                   	nop
   16564:	c9                   	leave  
   16565:	c3                   	ret    

00016566 <sys_kill>:
**		int32_t kill( uint_t pid );
**
** Marks the specified process (or the calling process, if PID is 0)
** as "killed". Returns 0 on success, else an error code.
*/
SYSIMPL(kill) {
   16566:	55                   	push   %ebp
   16567:	89 e5                	mov    %esp,%ebp
   16569:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   1656c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16570:	75 3b                	jne    165ad <sys_kill+0x47>
   16572:	83 ec 04             	sub    $0x4,%esp
   16575:	68 a0 b8 01 00       	push   $0x1b8a0
   1657a:	6a 00                	push   $0x0
   1657c:	68 91 02 00 00       	push   $0x291
   16581:	68 a9 b8 01 00       	push   $0x1b8a9
   16586:	68 e0 ba 01 00       	push   $0x1bae0
   1658b:	68 b4 b8 01 00       	push   $0x1b8b4
   16590:	68 00 00 02 00       	push   $0x20000
   16595:	e8 6d c1 ff ff       	call   12707 <sprint>
   1659a:	83 c4 20             	add    $0x20,%esp
   1659d:	83 ec 0c             	sub    $0xc,%esp
   165a0:	68 00 00 02 00       	push   $0x20000
   165a5:	e8 dd be ff ff       	call   12487 <kpanic>
   165aa:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   165ad:	a1 e0 28 02 00       	mov    0x228e0,%eax
   165b2:	85 c0                	test   %eax,%eax
   165b4:	74 1c                	je     165d2 <sys_kill+0x6c>
   165b6:	8b 45 08             	mov    0x8(%ebp),%eax
   165b9:	8b 40 18             	mov    0x18(%eax),%eax
   165bc:	83 ec 04             	sub    $0x4,%esp
   165bf:	50                   	push   %eax
   165c0:	68 e0 ba 01 00       	push   $0x1bae0
   165c5:	68 ca b8 01 00       	push   $0x1b8ca
   165ca:	e8 58 af ff ff       	call   11527 <cio_printf>
   165cf:	83 c4 10             	add    $0x10,%esp

	// who is the victim?
	uint_t pid = ARG(pcb,1);
   165d2:	8b 45 08             	mov    0x8(%ebp),%eax
   165d5:	8b 00                	mov    (%eax),%eax
   165d7:	83 c0 48             	add    $0x48,%eax
   165da:	8b 40 04             	mov    0x4(%eax),%eax
   165dd:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// if it's this process, convert this into a call to exit()
	if( pid == pcb->pid ) {
   165e0:	8b 45 08             	mov    0x8(%ebp),%eax
   165e3:	8b 40 18             	mov    0x18(%eax),%eax
   165e6:	39 45 f0             	cmp    %eax,-0x10(%ebp)
   165e9:	75 50                	jne    1663b <sys_kill+0xd5>
		pcb->exit_status = EXIT_KILLED;
   165eb:	8b 45 08             	mov    0x8(%ebp),%eax
   165ee:	c7 40 14 9b ff ff ff 	movl   $0xffffff9b,0x14(%eax)
		pcb_zombify( pcb );
   165f5:	83 ec 0c             	sub    $0xc,%esp
   165f8:	ff 75 08             	pushl  0x8(%ebp)
   165fb:	e8 12 d4 ff ff       	call   13a12 <pcb_zombify>
   16600:	83 c4 10             	add    $0x10,%esp
		// reset 'current' to keep dispatch() happy
		current = NULL;
   16603:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   1660a:	00 00 00 
		dispatch();
   1660d:	e8 7e de ff ff       	call   14490 <dispatch>
		SYSCALL_EXIT( EXIT_KILLED );
   16612:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16617:	85 c0                	test   %eax,%eax
   16619:	0f 84 2e 02 00 00    	je     1684d <sys_kill+0x2e7>
   1661f:	83 ec 04             	sub    $0x4,%esp
   16622:	6a 9b                	push   $0xffffff9b
   16624:	68 e0 ba 01 00       	push   $0x1bae0
   16629:	68 db b8 01 00       	push   $0x1b8db
   1662e:	e8 f4 ae ff ff       	call   11527 <cio_printf>
   16633:	83 c4 10             	add    $0x10,%esp
		return;
   16636:	e9 12 02 00 00       	jmp    1684d <sys_kill+0x2e7>
	}

	// must be a valid "ordinary user" PID
	// QUESTION: what if it's the idle process?
	if( pid < FIRST_USER_PID ) {
   1663b:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
   1663f:	77 35                	ja     16676 <sys_kill+0x110>
		RET(pcb) = E_FAILURE;
   16641:	8b 45 08             	mov    0x8(%ebp),%eax
   16644:	8b 00                	mov    (%eax),%eax
   16646:	c7 40 30 ff ff ff ff 	movl   $0xffffffff,0x30(%eax)
		SYSCALL_EXIT( E_FAILURE );
   1664d:	a1 e0 28 02 00       	mov    0x228e0,%eax
   16652:	85 c0                	test   %eax,%eax
   16654:	0f 84 f6 01 00 00    	je     16850 <sys_kill+0x2ea>
   1665a:	83 ec 04             	sub    $0x4,%esp
   1665d:	6a ff                	push   $0xffffffff
   1665f:	68 e0 ba 01 00       	push   $0x1bae0
   16664:	68 db b8 01 00       	push   $0x1b8db
   16669:	e8 b9 ae ff ff       	call   11527 <cio_printf>
   1666e:	83 c4 10             	add    $0x10,%esp
		return;
   16671:	e9 da 01 00 00       	jmp    16850 <sys_kill+0x2ea>
	}

	// OK, this is an acceptable victim; see if it exists
	pcb_t *victim = pcb_find_pid( pid );
   16676:	83 ec 0c             	sub    $0xc,%esp
   16679:	ff 75 f0             	pushl  -0x10(%ebp)
   1667c:	e8 52 d6 ff ff       	call   13cd3 <pcb_find_pid>
   16681:	83 c4 10             	add    $0x10,%esp
   16684:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if( victim == NULL ) {
   16687:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   1668b:	75 35                	jne    166c2 <sys_kill+0x15c>
		// nope!
		RET(pcb) = E_NOT_FOUND;
   1668d:	8b 45 08             	mov    0x8(%ebp),%eax
   16690:	8b 00                	mov    (%eax),%eax
   16692:	c7 40 30 fa ff ff ff 	movl   $0xfffffffa,0x30(%eax)
		SYSCALL_EXIT( E_NOT_FOUND );
   16699:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1669e:	85 c0                	test   %eax,%eax
   166a0:	0f 84 ad 01 00 00    	je     16853 <sys_kill+0x2ed>
   166a6:	83 ec 04             	sub    $0x4,%esp
   166a9:	6a fa                	push   $0xfffffffa
   166ab:	68 e0 ba 01 00       	push   $0x1bae0
   166b0:	68 db b8 01 00       	push   $0x1b8db
   166b5:	e8 6d ae ff ff       	call   11527 <cio_printf>
   166ba:	83 c4 10             	add    $0x10,%esp
		return;
   166bd:	e9 91 01 00 00       	jmp    16853 <sys_kill+0x2ed>
	}

	// must have a state that is possible
	assert( victim->state >= FIRST_VIABLE && victim->state < N_STATES );
   166c2:	8b 45 ec             	mov    -0x14(%ebp),%eax
   166c5:	8b 40 1c             	mov    0x1c(%eax),%eax
   166c8:	83 f8 01             	cmp    $0x1,%eax
   166cb:	76 0b                	jbe    166d8 <sys_kill+0x172>
   166cd:	8b 45 ec             	mov    -0x14(%ebp),%eax
   166d0:	8b 40 1c             	mov    0x1c(%eax),%eax
   166d3:	83 f8 08             	cmp    $0x8,%eax
   166d6:	76 3b                	jbe    16713 <sys_kill+0x1ad>
   166d8:	83 ec 04             	sub    $0x4,%esp
   166db:	68 40 b9 01 00       	push   $0x1b940
   166e0:	6a 00                	push   $0x0
   166e2:	68 b5 02 00 00       	push   $0x2b5
   166e7:	68 a9 b8 01 00       	push   $0x1b8a9
   166ec:	68 e0 ba 01 00       	push   $0x1bae0
   166f1:	68 b4 b8 01 00       	push   $0x1b8b4
   166f6:	68 00 00 02 00       	push   $0x20000
   166fb:	e8 07 c0 ff ff       	call   12707 <sprint>
   16700:	83 c4 20             	add    $0x20,%esp
   16703:	83 ec 0c             	sub    $0xc,%esp
   16706:	68 00 00 02 00       	push   $0x20000
   1670b:	e8 77 bd ff ff       	call   12487 <kpanic>
   16710:	83 c4 10             	add    $0x10,%esp

	// how we perform the kill depends on the victim's state
	int32_t status = SUCCESS;
   16713:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	switch( victim->state ) {
   1671a:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1671d:	8b 40 1c             	mov    0x1c(%eax),%eax
   16720:	83 f8 08             	cmp    $0x8,%eax
   16723:	0f 87 a4 00 00 00    	ja     167cd <sys_kill+0x267>
   16729:	8b 04 85 a8 b9 01 00 	mov    0x1b9a8(,%eax,4),%eax
   16730:	ff e0                	jmp    *%eax

	case STATE_KILLED:    // FALL THROUGH
	case STATE_ZOMBIE:
		// you can't kill it if it's already dead
		RET(pcb) = SUCCESS;
   16732:	8b 45 08             	mov    0x8(%ebp),%eax
   16735:	8b 00                	mov    (%eax),%eax
   16737:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
		break;
   1673e:	e9 e5 00 00 00       	jmp    16828 <sys_kill+0x2c2>
	case STATE_READY:     // FALL THROUGH
	case STATE_SLEEPING:  // FALL THROUGH
	case STATE_BLOCKED:   // FALL THROUGH
		// here, the process is on a queue somewhere; mark
		// it as "killed", and let the scheduler deal with it
		victim->state = STATE_KILLED;
   16743:	8b 45 ec             	mov    -0x14(%ebp),%eax
   16746:	c7 40 1c 07 00 00 00 	movl   $0x7,0x1c(%eax)
		RET(pcb) = SUCCESS;
   1674d:	8b 45 08             	mov    0x8(%ebp),%eax
   16750:	8b 00                	mov    (%eax),%eax
   16752:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
		break;
   16759:	e9 ca 00 00 00       	jmp    16828 <sys_kill+0x2c2>

	case STATE_RUNNING:
		// we have met the enemy, and it is us!
		pcb->exit_status = EXIT_KILLED;
   1675e:	8b 45 08             	mov    0x8(%ebp),%eax
   16761:	c7 40 14 9b ff ff ff 	movl   $0xffffff9b,0x14(%eax)
		pcb_zombify( pcb );
   16768:	83 ec 0c             	sub    $0xc,%esp
   1676b:	ff 75 08             	pushl  0x8(%ebp)
   1676e:	e8 9f d2 ff ff       	call   13a12 <pcb_zombify>
   16773:	83 c4 10             	add    $0x10,%esp
		status = EXIT_KILLED;
   16776:	c7 45 f4 9b ff ff ff 	movl   $0xffffff9b,-0xc(%ebp)
		// we need a new current process
		// reset 'current' to keep dispatch() happy
		current = NULL;
   1677d:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   16784:	00 00 00 
		dispatch();
   16787:	e8 04 dd ff ff       	call   14490 <dispatch>
		break;
   1678c:	e9 97 00 00 00       	jmp    16828 <sys_kill+0x2c2>

	case STATE_WAITING:
		// similar to the 'running' state, but we don't need
		// to dispatch a new process
		victim->exit_status = EXIT_KILLED;
   16791:	8b 45 ec             	mov    -0x14(%ebp),%eax
   16794:	c7 40 14 9b ff ff ff 	movl   $0xffffff9b,0x14(%eax)
		status = pcb_queue_remove_this( waiting, victim );
   1679b:	a1 10 20 02 00       	mov    0x22010,%eax
   167a0:	83 ec 08             	sub    $0x8,%esp
   167a3:	ff 75 ec             	pushl  -0x14(%ebp)
   167a6:	50                   	push   %eax
   167a7:	e8 07 da ff ff       	call   141b3 <pcb_queue_remove_this>
   167ac:	83 c4 10             	add    $0x10,%esp
   167af:	89 45 f4             	mov    %eax,-0xc(%ebp)
		pcb_zombify( victim );
   167b2:	83 ec 0c             	sub    $0xc,%esp
   167b5:	ff 75 ec             	pushl  -0x14(%ebp)
   167b8:	e8 55 d2 ff ff       	call   13a12 <pcb_zombify>
   167bd:	83 c4 10             	add    $0x10,%esp
		RET(pcb) = status;
   167c0:	8b 45 08             	mov    0x8(%ebp),%eax
   167c3:	8b 00                	mov    (%eax),%eax
   167c5:	8b 55 f4             	mov    -0xc(%ebp),%edx
   167c8:	89 50 30             	mov    %edx,0x30(%eax)
		break;
   167cb:	eb 5b                	jmp    16828 <sys_kill+0x2c2>
	default:
		// this is a really bad potential problem - we have an
		// unexpected or bogus process state, but we didn't
		// catch that earlier.
		sprint( b256, "*** kill(): victim %d, odd state %d\n",
				victim->pid, victim->state );
   167cd:	8b 45 ec             	mov    -0x14(%ebp),%eax
   167d0:	8b 50 1c             	mov    0x1c(%eax),%edx
		sprint( b256, "*** kill(): victim %d, odd state %d\n",
   167d3:	8b 45 ec             	mov    -0x14(%ebp),%eax
   167d6:	8b 40 18             	mov    0x18(%eax),%eax
   167d9:	52                   	push   %edx
   167da:	50                   	push   %eax
   167db:	68 7c b9 01 00       	push   $0x1b97c
   167e0:	68 00 02 02 00       	push   $0x20200
   167e5:	e8 1d bf ff ff       	call   12707 <sprint>
   167ea:	83 c4 10             	add    $0x10,%esp
		PANIC( 0, b256 );
   167ed:	83 ec 04             	sub    $0x4,%esp
   167f0:	68 a1 b9 01 00       	push   $0x1b9a1
   167f5:	6a 00                	push   $0x0
   167f7:	68 e5 02 00 00       	push   $0x2e5
   167fc:	68 a9 b8 01 00       	push   $0x1b8a9
   16801:	68 e0 ba 01 00       	push   $0x1bae0
   16806:	68 b4 b8 01 00       	push   $0x1b8b4
   1680b:	68 00 00 02 00       	push   $0x20000
   16810:	e8 f2 be ff ff       	call   12707 <sprint>
   16815:	83 c4 20             	add    $0x20,%esp
   16818:	83 ec 0c             	sub    $0xc,%esp
   1681b:	68 00 00 02 00       	push   $0x20000
   16820:	e8 62 bc ff ff       	call   12487 <kpanic>
   16825:	83 c4 10             	add    $0x10,%esp
	}

	SYSCALL_EXIT( status );
   16828:	a1 e0 28 02 00       	mov    0x228e0,%eax
   1682d:	85 c0                	test   %eax,%eax
   1682f:	74 25                	je     16856 <sys_kill+0x2f0>
   16831:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16834:	83 ec 04             	sub    $0x4,%esp
   16837:	50                   	push   %eax
   16838:	68 e0 ba 01 00       	push   $0x1bae0
   1683d:	68 db b8 01 00       	push   $0x1b8db
   16842:	e8 e0 ac ff ff       	call   11527 <cio_printf>
   16847:	83 c4 10             	add    $0x10,%esp
	return;
   1684a:	90                   	nop
   1684b:	eb 09                	jmp    16856 <sys_kill+0x2f0>
		return;
   1684d:	90                   	nop
   1684e:	eb 07                	jmp    16857 <sys_kill+0x2f1>
		return;
   16850:	90                   	nop
   16851:	eb 04                	jmp    16857 <sys_kill+0x2f1>
		return;
   16853:	90                   	nop
   16854:	eb 01                	jmp    16857 <sys_kill+0x2f1>
	return;
   16856:	90                   	nop
}
   16857:	c9                   	leave  
   16858:	c3                   	ret    

00016859 <sys_sleep>:
**		uint_t sleep( uint_t ms );
**
** Puts the calling process to sleep for 'ms' milliseconds (or just yields
** the CPU if 'ms' is 0).  ** Returns the time the process spent sleeping.
*/
SYSIMPL(sleep) {
   16859:	55                   	push   %ebp
   1685a:	89 e5                	mov    %esp,%ebp
   1685c:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   1685f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16863:	75 3b                	jne    168a0 <sys_sleep+0x47>
   16865:	83 ec 04             	sub    $0x4,%esp
   16868:	68 a0 b8 01 00       	push   $0x1b8a0
   1686d:	6a 00                	push   $0x0
   1686f:	68 f9 02 00 00       	push   $0x2f9
   16874:	68 a9 b8 01 00       	push   $0x1b8a9
   16879:	68 ec ba 01 00       	push   $0x1baec
   1687e:	68 b4 b8 01 00       	push   $0x1b8b4
   16883:	68 00 00 02 00       	push   $0x20000
   16888:	e8 7a be ff ff       	call   12707 <sprint>
   1688d:	83 c4 20             	add    $0x20,%esp
   16890:	83 ec 0c             	sub    $0xc,%esp
   16893:	68 00 00 02 00       	push   $0x20000
   16898:	e8 ea bb ff ff       	call   12487 <kpanic>
   1689d:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   168a0:	a1 e0 28 02 00       	mov    0x228e0,%eax
   168a5:	85 c0                	test   %eax,%eax
   168a7:	74 1c                	je     168c5 <sys_sleep+0x6c>
   168a9:	8b 45 08             	mov    0x8(%ebp),%eax
   168ac:	8b 40 18             	mov    0x18(%eax),%eax
   168af:	83 ec 04             	sub    $0x4,%esp
   168b2:	50                   	push   %eax
   168b3:	68 ec ba 01 00       	push   $0x1baec
   168b8:	68 ca b8 01 00       	push   $0x1b8ca
   168bd:	e8 65 ac ff ff       	call   11527 <cio_printf>
   168c2:	83 c4 10             	add    $0x10,%esp

	// get the desired duration
	uint_t length = ARG( pcb, 1 );
   168c5:	8b 45 08             	mov    0x8(%ebp),%eax
   168c8:	8b 00                	mov    (%eax),%eax
   168ca:	83 c0 48             	add    $0x48,%eax
   168cd:	8b 40 04             	mov    0x4(%eax),%eax
   168d0:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if( length == 0 ) {
   168d3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   168d7:	75 1c                	jne    168f5 <sys_sleep+0x9c>

		// just yield the CPU
		// sleep duration is 0
		RET(pcb) = 0;
   168d9:	8b 45 08             	mov    0x8(%ebp),%eax
   168dc:	8b 00                	mov    (%eax),%eax
   168de:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)

		// back on the ready queue
		schedule( pcb );
   168e5:	83 ec 0c             	sub    $0xc,%esp
   168e8:	ff 75 08             	pushl  0x8(%ebp)
   168eb:	e8 df da ff ff       	call   143cf <schedule>
   168f0:	83 c4 10             	add    $0x10,%esp
   168f3:	eb 7a                	jmp    1696f <sys_sleep+0x116>

	} else {

		// sleep for a while
		pcb->wakeup = system_time + length;
   168f5:	8b 15 bc f1 01 00    	mov    0x1f1bc,%edx
   168fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
   168fe:	01 c2                	add    %eax,%edx
   16900:	8b 45 08             	mov    0x8(%ebp),%eax
   16903:	89 50 10             	mov    %edx,0x10(%eax)

		if( pcb_queue_insert(sleeping,pcb) != SUCCESS ) {
   16906:	a1 08 20 02 00       	mov    0x22008,%eax
   1690b:	83 ec 08             	sub    $0x8,%esp
   1690e:	ff 75 08             	pushl  0x8(%ebp)
   16911:	50                   	push   %eax
   16912:	e8 df d5 ff ff       	call   13ef6 <pcb_queue_insert>
   16917:	83 c4 10             	add    $0x10,%esp
   1691a:	85 c0                	test   %eax,%eax
   1691c:	74 51                	je     1696f <sys_sleep+0x116>
			// something strange is happening
			WARNING( "sleep pcb insert failed" );
   1691e:	68 10 03 00 00       	push   $0x310
   16923:	68 a9 b8 01 00       	push   $0x1b8a9
   16928:	68 ec ba 01 00       	push   $0x1baec
   1692d:	68 cc b9 01 00       	push   $0x1b9cc
   16932:	e8 f0 ab ff ff       	call   11527 <cio_printf>
   16937:	83 c4 10             	add    $0x10,%esp
   1693a:	83 ec 0c             	sub    $0xc,%esp
   1693d:	68 df b9 01 00       	push   $0x1b9df
   16942:	e8 66 a5 ff ff       	call   10ead <cio_puts>
   16947:	83 c4 10             	add    $0x10,%esp
   1694a:	83 ec 0c             	sub    $0xc,%esp
   1694d:	6a 0a                	push   $0xa
   1694f:	e8 19 a4 ff ff       	call   10d6d <cio_putchar>
   16954:	83 c4 10             	add    $0x10,%esp
			// if this is the current process, report an error
			if( current == pcb ) {
   16957:	a1 14 20 02 00       	mov    0x22014,%eax
   1695c:	39 45 08             	cmp    %eax,0x8(%ebp)
   1695f:	75 29                	jne    1698a <sys_sleep+0x131>
				RET(pcb) = -1;
   16961:	8b 45 08             	mov    0x8(%ebp),%eax
   16964:	8b 00                	mov    (%eax),%eax
   16966:	c7 40 30 ff ff ff ff 	movl   $0xffffffff,0x30(%eax)
			}
			// return without dispatching a new process
			return;
   1696d:	eb 1b                	jmp    1698a <sys_sleep+0x131>
		}
	}

	// only dispatch if the current process called us
	if( pcb == current ) {
   1696f:	a1 14 20 02 00       	mov    0x22014,%eax
   16974:	39 45 08             	cmp    %eax,0x8(%ebp)
   16977:	75 12                	jne    1698b <sys_sleep+0x132>
		current = NULL;
   16979:	c7 05 14 20 02 00 00 	movl   $0x0,0x22014
   16980:	00 00 00 
		dispatch();
   16983:	e8 08 db ff ff       	call   14490 <dispatch>
   16988:	eb 01                	jmp    1698b <sys_sleep+0x132>
			return;
   1698a:	90                   	nop
	}
}
   1698b:	c9                   	leave  
   1698c:	c3                   	ret    

0001698d <sys_isr>:
** System call ISR
**
** @param vector   Vector number for this interrupt
** @param code     Error code (0 for this interrupt)
*/
static void sys_isr( int vector, int code ) {
   1698d:	55                   	push   %ebp
   1698e:	89 e5                	mov    %esp,%ebp
   16990:	83 ec 18             	sub    $0x18,%esp
	// keep the compiler happy
	(void) vector;
	(void) code;

	// sanity check!
	assert( current != NULL );
   16993:	a1 14 20 02 00       	mov    0x22014,%eax
   16998:	85 c0                	test   %eax,%eax
   1699a:	75 3b                	jne    169d7 <sys_isr+0x4a>
   1699c:	83 ec 04             	sub    $0x4,%esp
   1699f:	68 34 ba 01 00       	push   $0x1ba34
   169a4:	6a 00                	push   $0x0
   169a6:	68 4d 03 00 00       	push   $0x34d
   169ab:	68 a9 b8 01 00       	push   $0x1b8a9
   169b0:	68 f8 ba 01 00       	push   $0x1baf8
   169b5:	68 b4 b8 01 00       	push   $0x1b8b4
   169ba:	68 00 00 02 00       	push   $0x20000
   169bf:	e8 43 bd ff ff       	call   12707 <sprint>
   169c4:	83 c4 20             	add    $0x20,%esp
   169c7:	83 ec 0c             	sub    $0xc,%esp
   169ca:	68 00 00 02 00       	push   $0x20000
   169cf:	e8 b3 ba ff ff       	call   12487 <kpanic>
   169d4:	83 c4 10             	add    $0x10,%esp
	assert( current->context != NULL );
   169d7:	a1 14 20 02 00       	mov    0x22014,%eax
   169dc:	8b 00                	mov    (%eax),%eax
   169de:	85 c0                	test   %eax,%eax
   169e0:	75 3b                	jne    16a1d <sys_isr+0x90>
   169e2:	83 ec 04             	sub    $0x4,%esp
   169e5:	68 41 ba 01 00       	push   $0x1ba41
   169ea:	6a 00                	push   $0x0
   169ec:	68 4e 03 00 00       	push   $0x34e
   169f1:	68 a9 b8 01 00       	push   $0x1b8a9
   169f6:	68 f8 ba 01 00       	push   $0x1baf8
   169fb:	68 b4 b8 01 00       	push   $0x1b8b4
   16a00:	68 00 00 02 00       	push   $0x20000
   16a05:	e8 fd bc ff ff       	call   12707 <sprint>
   16a0a:	83 c4 20             	add    $0x20,%esp
   16a0d:	83 ec 0c             	sub    $0xc,%esp
   16a10:	68 00 00 02 00       	push   $0x20000
   16a15:	e8 6d ba ff ff       	call   12487 <kpanic>
   16a1a:	83 c4 10             	add    $0x10,%esp

	// retrieve the syscall code
	int num = REG( current, eax );
   16a1d:	a1 14 20 02 00       	mov    0x22014,%eax
   16a22:	8b 00                	mov    (%eax),%eax
   16a24:	8b 40 30             	mov    0x30(%eax),%eax
   16a27:	89 45 f4             	mov    %eax,-0xc(%ebp)
#if TRACING_SYSCALLS
	cio_printf( "** --> SYS pid %u code %u\n", current->pid, num );
#endif

	// validate it
	if( num < 0 || num >= N_SYSCALLS ) {
   16a2a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   16a2e:	78 06                	js     16a36 <sys_isr+0xa9>
   16a30:	83 7d f4 0c          	cmpl   $0xc,-0xc(%ebp)
   16a34:	7e 1a                	jle    16a50 <sys_isr+0xc3>
		// bad syscall number
		// could kill it, but we'll just force it to exit
		num = SYS_exit;
   16a36:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
		ARG(current,1) = EXIT_BAD_SYSCALL;
   16a3d:	a1 14 20 02 00       	mov    0x22014,%eax
   16a42:	8b 00                	mov    (%eax),%eax
   16a44:	83 c0 48             	add    $0x48,%eax
   16a47:	83 c0 04             	add    $0x4,%eax
   16a4a:	c7 00 9a ff ff ff    	movl   $0xffffff9a,(%eax)
	}

	// call the handler
	syscalls[num]( current );
   16a50:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16a53:	8b 04 85 00 ba 01 00 	mov    0x1ba00(,%eax,4),%eax
   16a5a:	8b 15 14 20 02 00    	mov    0x22014,%edx
   16a60:	83 ec 0c             	sub    $0xc,%esp
   16a63:	52                   	push   %edx
   16a64:	ff d0                	call   *%eax
   16a66:	83 c4 10             	add    $0x10,%esp
   16a69:	c7 45 f0 20 00 00 00 	movl   $0x20,-0x10(%ebp)
   16a70:	c6 45 ef 20          	movb   $0x20,-0x11(%ebp)
   16a74:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
   16a78:	8b 55 f0             	mov    -0x10(%ebp),%edx
   16a7b:	ee                   	out    %al,(%dx)
	cio_printf( "** <-- SYS pid %u ret %u\n", current->pid, RET(current) );
#endif

	// tell the PIC we're done
	outb( PIC1_CMD, PIC_EOI );
}
   16a7c:	90                   	nop
   16a7d:	c9                   	leave  
   16a7e:	c3                   	ret    

00016a7f <sys_init>:
** Syscall module initialization routine
**
** Dependencies:
**    Must be called after cio_init()
*/
void sys_init( void ) {
   16a7f:	55                   	push   %ebp
   16a80:	89 e5                	mov    %esp,%ebp
   16a82:	83 ec 08             	sub    $0x8,%esp

#if TRACING_INIT
	cio_puts( " Sys" );
   16a85:	83 ec 0c             	sub    $0xc,%esp
   16a88:	68 57 ba 01 00       	push   $0x1ba57
   16a8d:	e8 1b a4 ff ff       	call   10ead <cio_puts>
   16a92:	83 c4 10             	add    $0x10,%esp
#endif

	// install the second-stage ISR
	install_isr( VEC_SYSCALL, sys_isr );
   16a95:	83 ec 08             	sub    $0x8,%esp
   16a98:	68 8d 69 01 00       	push   $0x1698d
   16a9d:	68 80 00 00 00       	push   $0x80
   16aa2:	e8 df ec ff ff       	call   15786 <install_isr>
   16aa7:	83 c4 10             	add    $0x10,%esp
}
   16aaa:	90                   	nop
   16aab:	c9                   	leave  
   16aac:	c3                   	ret    

00016aad <stack_setup>:
** @param sys    Is the argument vector from kernel code?
**
** @return A (user VA) pointer to the context_t on the stack, or NULL
*/
context_t *stack_setup( pcb_t *pcb, uint32_t entry,
		const char **args, bool_t sys ) {
   16aad:	55                   	push   %ebp
   16aae:	89 e5                	mov    %esp,%ebp
   16ab0:	57                   	push   %edi
   16ab1:	56                   	push   %esi
   16ab2:	53                   	push   %ebx
   16ab3:	81 ec cc 00 00 00    	sub    $0xcc,%esp
   16ab9:	8b 45 14             	mov    0x14(%ebp),%eax
   16abc:	88 85 34 ff ff ff    	mov    %al,-0xcc(%ebp)
	**       the remainder of the aggregate shall be initialized
	**       implicitly the same as objects that have static storage
	**       duration."
	*/

	int argbytes = 0;                    // total length of arg strings
   16ac2:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
	int argc = 0;                        // number of argv entries
   16ac9:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
	const char *kv_strs[N_ARGS] = { 0 }; // converted user arg string pointers
   16ad0:	8d 55 88             	lea    -0x78(%ebp),%edx
   16ad3:	b8 00 00 00 00       	mov    $0x0,%eax
   16ad8:	b9 0a 00 00 00       	mov    $0xa,%ecx
   16add:	89 d7                	mov    %edx,%edi
   16adf:	f3 ab                	rep stos %eax,%es:(%edi)
	int strlengths[N_ARGS] = { 0 };      // length of each string
   16ae1:	8d 95 60 ff ff ff    	lea    -0xa0(%ebp),%edx
   16ae7:	b8 00 00 00 00       	mov    $0x0,%eax
   16aec:	b9 0a 00 00 00       	mov    $0xa,%ecx
   16af1:	89 d7                	mov    %edx,%edi
   16af3:	f3 ab                	rep stos %eax,%es:(%edi)
	int uv_offsets[N_ARGS] = { 0 };      // offsets into string buffer
   16af5:	8d 95 38 ff ff ff    	lea    -0xc8(%ebp),%edx
   16afb:	b8 00 00 00 00       	mov    $0x0,%eax
   16b00:	b9 0a 00 00 00       	mov    $0xa,%ecx
   16b05:	89 d7                	mov    %edx,%edi
   16b07:	f3 ab                	rep stos %eax,%es:(%edi)
	/*
	** IF the argument list given to us came from  user code, we need
	** to convert its address and the addresses it contains to kernel
	** VAs; otherwise, we can use them directly.
	*/
	const char **kv_args = args;
   16b09:	8b 45 10             	mov    0x10(%ebp),%eax
   16b0c:	89 45 cc             	mov    %eax,-0x34(%ebp)

	while( kv_args[argc] != NULL ) {
   16b0f:	eb 61                	jmp    16b72 <stack_setup+0xc5>
		kv_strs[argc] = args[argc];
   16b11:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b14:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   16b1b:	8b 45 10             	mov    0x10(%ebp),%eax
   16b1e:	01 d0                	add    %edx,%eax
   16b20:	8b 10                	mov    (%eax),%edx
   16b22:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b25:	89 54 85 88          	mov    %edx,-0x78(%ebp,%eax,4)
		strlengths[argc] = strlen( kv_strs[argc] ) + 1;
   16b29:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b2c:	8b 44 85 88          	mov    -0x78(%ebp,%eax,4),%eax
   16b30:	83 ec 0c             	sub    $0xc,%esp
   16b33:	50                   	push   %eax
   16b34:	e8 4b bf ff ff       	call   12a84 <strlen>
   16b39:	83 c4 10             	add    $0x10,%esp
   16b3c:	83 c0 01             	add    $0x1,%eax
   16b3f:	89 c2                	mov    %eax,%edx
   16b41:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b44:	89 94 85 60 ff ff ff 	mov    %edx,-0xa0(%ebp,%eax,4)
		// can't go over one page in size
		if( (argbytes + strlengths[argc]) > SZ_PAGE ) {
   16b4b:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b4e:	8b 94 85 60 ff ff ff 	mov    -0xa0(%ebp,%eax,4),%edx
   16b55:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   16b58:	01 d0                	add    %edx,%eax
   16b5a:	3d 00 10 00 00       	cmp    $0x1000,%eax
   16b5f:	7f 28                	jg     16b89 <stack_setup+0xdc>
			// oops - ignore this and any others
			break;
		}
		argbytes += strlengths[argc];
   16b61:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b64:	8b 84 85 60 ff ff ff 	mov    -0xa0(%ebp,%eax,4),%eax
   16b6b:	01 45 d4             	add    %eax,-0x2c(%ebp)
		++argc;
   16b6e:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
	while( kv_args[argc] != NULL ) {
   16b72:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b75:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   16b7c:	8b 45 cc             	mov    -0x34(%ebp),%eax
   16b7f:	01 d0                	add    %edx,%eax
   16b81:	8b 00                	mov    (%eax),%eax
   16b83:	85 c0                	test   %eax,%eax
   16b85:	75 8a                	jne    16b11 <stack_setup+0x64>
   16b87:	eb 01                	jmp    16b8a <stack_setup+0xdd>
			break;
   16b89:	90                   	nop
	}

	// Round up the byte count to the next multiple of four.
	argbytes = (argbytes + 3) & MOD4_MASK;
   16b8a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   16b8d:	83 c0 03             	add    $0x3,%eax
   16b90:	83 e0 fc             	and    $0xfffffffc,%eax
   16b93:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	** We don't know where the argument strings actually live; they
	** could be inside the stack of a process that called exec(), so
	** we can't run the risk of overwriting them. Copy them into our
	** own address space.
	*/
	char argstrings[ argbytes ];
   16b96:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
   16b99:	89 e0                	mov    %esp,%eax
   16b9b:	89 c3                	mov    %eax,%ebx
   16b9d:	8d 41 ff             	lea    -0x1(%ecx),%eax
   16ba0:	89 45 c8             	mov    %eax,-0x38(%ebp)
   16ba3:	89 ca                	mov    %ecx,%edx
   16ba5:	b8 10 00 00 00       	mov    $0x10,%eax
   16baa:	83 e8 01             	sub    $0x1,%eax
   16bad:	01 d0                	add    %edx,%eax
   16baf:	be 10 00 00 00       	mov    $0x10,%esi
   16bb4:	ba 00 00 00 00       	mov    $0x0,%edx
   16bb9:	f7 f6                	div    %esi
   16bbb:	6b c0 10             	imul   $0x10,%eax,%eax
   16bbe:	29 c4                	sub    %eax,%esp
   16bc0:	89 e0                	mov    %esp,%eax
   16bc2:	83 c0 00             	add    $0x0,%eax
   16bc5:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	CLEAR( argstrings );
   16bc8:	89 ca                	mov    %ecx,%edx
   16bca:	8b 45 c4             	mov    -0x3c(%ebp),%eax
   16bcd:	83 ec 08             	sub    $0x8,%esp
   16bd0:	52                   	push   %edx
   16bd1:	50                   	push   %eax
   16bd2:	e8 ad b9 ff ff       	call   12584 <memclr>
   16bd7:	83 c4 10             	add    $0x10,%esp

	char *tmp = argstrings;
   16bda:	8b 45 c4             	mov    -0x3c(%ebp),%eax
   16bdd:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for( int i = 0; i < argc; ++i ) {
   16be0:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
   16be7:	eb 3b                	jmp    16c24 <stack_setup+0x177>
		// do the copy
		strcpy( tmp, kv_strs[i] );
   16be9:	8b 45 e0             	mov    -0x20(%ebp),%eax
   16bec:	8b 44 85 88          	mov    -0x78(%ebp,%eax,4),%eax
   16bf0:	83 ec 08             	sub    $0x8,%esp
   16bf3:	50                   	push   %eax
   16bf4:	ff 75 dc             	pushl  -0x24(%ebp)
   16bf7:	e8 5e be ff ff       	call   12a5a <strcpy>
   16bfc:	83 c4 10             	add    $0x10,%esp
		// remember where this string begins in the buffer
		uv_offsets[i] = tmp - argstrings;
   16bff:	8b 45 dc             	mov    -0x24(%ebp),%eax
   16c02:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   16c05:	29 d0                	sub    %edx,%eax
   16c07:	89 c2                	mov    %eax,%edx
   16c09:	8b 45 e0             	mov    -0x20(%ebp),%eax
   16c0c:	89 94 85 38 ff ff ff 	mov    %edx,-0xc8(%ebp,%eax,4)
		// move to the next string position
		tmp += strlengths[i];
   16c13:	8b 45 e0             	mov    -0x20(%ebp),%eax
   16c16:	8b 84 85 60 ff ff ff 	mov    -0xa0(%ebp,%eax,4),%eax
   16c1d:	01 45 dc             	add    %eax,-0x24(%ebp)
	for( int i = 0; i < argc; ++i ) {
   16c20:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
   16c24:	8b 45 e0             	mov    -0x20(%ebp),%eax
   16c27:	3b 45 d8             	cmp    -0x28(%ebp),%eax
   16c2a:	7c bd                	jl     16be9 <stack_setup+0x13c>
	** frame is in the first page directory entry. Extract that from the
	** entry and convert it into a virtual address for the kernel to use.
	*/
	// pointer to the first byte after the user stack
	uint32_t *kvptr = (uint32_t *)
		(((uint32_t)(pcb->stack)) + N_USTKPAGES * SZ_PAGE);
   16c2c:	8b 45 08             	mov    0x8(%ebp),%eax
   16c2f:	8b 40 04             	mov    0x4(%eax),%eax
   16c32:	05 00 20 00 00       	add    $0x2000,%eax
	uint32_t *kvptr = (uint32_t *)
   16c37:	89 45 c0             	mov    %eax,-0x40(%ebp)

	// put the buffer longword into the stack
	*--kvptr = 0;
   16c3a:	83 6d c0 04          	subl   $0x4,-0x40(%ebp)
   16c3e:	8b 45 c0             	mov    -0x40(%ebp),%eax
   16c41:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	/*
	** Move these pointers to where the string area will begin. We
	** will then back up to the next lower multiple-of-four address.
	*/
	uint32_t kvstrptr = ((uint32_t) kvptr) - argbytes;
   16c47:	8b 55 c0             	mov    -0x40(%ebp),%edx
   16c4a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   16c4d:	29 c2                	sub    %eax,%edx
   16c4f:	89 d0                	mov    %edx,%eax
   16c51:	89 45 bc             	mov    %eax,-0x44(%ebp)
	kvstrptr &= MOD4_MASK;
   16c54:	83 65 bc fc          	andl   $0xfffffffc,-0x44(%ebp)

	// Copy over the argv strings
	memmove( (void *) kvstrptr, (void *) argstrings, argbytes );
   16c58:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
   16c5b:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   16c5e:	8b 45 bc             	mov    -0x44(%ebp),%eax
   16c61:	83 ec 04             	sub    $0x4,%esp
   16c64:	51                   	push   %ecx
   16c65:	52                   	push   %edx
   16c66:	50                   	push   %eax
   16c67:	e8 66 b9 ff ff       	call   125d2 <memmove>
   16c6c:	83 c4 10             	add    $0x10,%esp
	** The space needed for argc, argv, and the argv array itself is
	** argc + 3 words (argc+1 for the argv entries, plus one word each
	** for argc and argv).  We back up that much from the string area.
	*/

	int nwords = argc + 3;
   16c6f:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16c72:	83 c0 03             	add    $0x3,%eax
   16c75:	89 45 b8             	mov    %eax,-0x48(%ebp)
	uint32_t *kvacptr = ((uint32_t *) kvstrptr) - nwords;
   16c78:	8b 45 b8             	mov    -0x48(%ebp),%eax
   16c7b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   16c82:	8b 45 bc             	mov    -0x44(%ebp),%eax
   16c85:	29 d0                	sub    %edx,%eax
   16c87:	89 45 b4             	mov    %eax,-0x4c(%ebp)

	// back these up to multiple-of-16 addresses for stack alignment
	kvacptr = (uint32_t *) ( ((uint32_t)kvacptr) & MOD16_MASK );
   16c8a:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16c8d:	83 e0 f0             	and    $0xfffffff0,%eax
   16c90:	89 45 b4             	mov    %eax,-0x4c(%ebp)

	// copy in 'argc'
	*kvacptr = argc;
   16c93:	8b 55 d8             	mov    -0x28(%ebp),%edx
   16c96:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16c99:	89 10                	mov    %edx,(%eax)
	cio_printf( "setup: argc '%d' @ %08x,", argc, (uint32_t) kvacptr );
#endif

	// 'argv' immediately follows 'argc', and 'argv[0]' immediately
	// follows 'argv'
	uint32_t *kvavptr = kvacptr + 2;
   16c9b:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16c9e:	83 c0 08             	add    $0x8,%eax
   16ca1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	*(kvavptr-1) = (uint32_t) kvavptr;
   16ca4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16ca7:	8d 50 fc             	lea    -0x4(%eax),%edx
   16caa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16cad:	89 02                	mov    %eax,(%edx)
	cio_printf( " argv '%08x' @ %08x,", (uint32_t) kvavptr,
			(uint32_t) (kvavptr - 1) );
#endif

	// now, the argv entries themselves
	for( int i = 0; i < argc; ++i ) {
   16caf:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
   16cb6:	eb 20                	jmp    16cd8 <stack_setup+0x22b>
		*kvavptr++ = (uint32_t) (kvstrptr + uv_offsets[i]);
   16cb8:	8b 45 d0             	mov    -0x30(%ebp),%eax
   16cbb:	8b 84 85 38 ff ff ff 	mov    -0xc8(%ebp,%eax,4),%eax
   16cc2:	89 c1                	mov    %eax,%ecx
   16cc4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16cc7:	8d 50 04             	lea    0x4(%eax),%edx
   16cca:	89 55 e4             	mov    %edx,-0x1c(%ebp)
   16ccd:	8b 55 bc             	mov    -0x44(%ebp),%edx
   16cd0:	01 ca                	add    %ecx,%edx
   16cd2:	89 10                	mov    %edx,(%eax)
	for( int i = 0; i < argc; ++i ) {
   16cd4:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
   16cd8:	8b 45 d0             	mov    -0x30(%ebp),%eax
   16cdb:	3b 45 d8             	cmp    -0x28(%ebp),%eax
   16cde:	7c d8                	jl     16cb8 <stack_setup+0x20b>
		(uint32_t) (kvavptr-1) );
#endif
	}

	// and the trailing NULL
	*kvavptr = NULL;
   16ce0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16ce3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#if TRACING_STACK
	cio_printf( " NULL @ %08x,", (uint32_t) kvavptr );
#endif

	// push the fake return address right above 'argc' on the stack
	*--kvacptr = (uint32_t) fake_exit;
   16ce9:	83 6d b4 04          	subl   $0x4,-0x4c(%ebp)
   16ced:	ba 98 6f 01 00       	mov    $0x16f98,%edx
   16cf2:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16cf5:	89 10                	mov    %edx,(%eax)
	** the interrupt "returns" to the entry point of the process.
	*/

	// Locate the context save area on the stack by backup up one
	// "context" from where the argc value is saved
	context_t *kvctx = ((context_t *) kvacptr) - 1;
   16cf7:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16cfa:	83 e8 48             	sub    $0x48,%eax
   16cfd:	89 45 b0             	mov    %eax,-0x50(%ebp)
	** as the 'popa' that restores the general registers doesn't
	** actually restore ESP from the context area - it leaves it
	** where it winds up.
	*/

	kvctx->eflags = DEFAULT_EFLAGS;    // IF enabled, IOPL 0
   16d00:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d03:	c7 40 44 02 02 00 00 	movl   $0x202,0x44(%eax)
	kvctx->eip = entry;                // initial EIP
   16d0a:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d0d:	8b 55 0c             	mov    0xc(%ebp),%edx
   16d10:	89 50 3c             	mov    %edx,0x3c(%eax)
	kvctx->cs = GDT_CODE;              // segment registers
   16d13:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d16:	c7 40 40 10 00 00 00 	movl   $0x10,0x40(%eax)
	kvctx->ss = GDT_STACK;
   16d1d:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d20:	c7 00 20 00 00 00    	movl   $0x20,(%eax)
	kvctx->ds = kvctx->es = kvctx->fs = kvctx->gs = GDT_DATA;
   16d26:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d29:	c7 40 04 18 00 00 00 	movl   $0x18,0x4(%eax)
   16d30:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d33:	8b 50 04             	mov    0x4(%eax),%edx
   16d36:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d39:	89 50 08             	mov    %edx,0x8(%eax)
   16d3c:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d3f:	8b 50 08             	mov    0x8(%eax),%edx
   16d42:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d45:	89 50 0c             	mov    %edx,0xc(%eax)
   16d48:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d4b:	8b 50 0c             	mov    0xc(%eax),%edx
   16d4e:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d51:	89 50 10             	mov    %edx,0x10(%eax)
	/*
	** Return the new context pointer to the caller as a user
	** space virtual address.
	*/
	
	return kvctx;
   16d54:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d57:	89 dc                	mov    %ebx,%esp
}
   16d59:	8d 65 f4             	lea    -0xc(%ebp),%esp
   16d5c:	5b                   	pop    %ebx
   16d5d:	5e                   	pop    %esi
   16d5e:	5f                   	pop    %edi
   16d5f:	5d                   	pop    %ebp
   16d60:	c3                   	ret    

00016d61 <user_init>:
/**
** Name:	user_init
**
** Initializes the user support module.
*/
void user_init( void ) {
   16d61:	55                   	push   %ebp
   16d62:	89 e5                	mov    %esp,%ebp
   16d64:	83 ec 08             	sub    $0x8,%esp

#if TRACING_INIT
	cio_puts( " User" );
   16d67:	83 ec 0c             	sub    $0xc,%esp
   16d6a:	68 00 bb 01 00       	push   $0x1bb00
   16d6f:	e8 39 a1 ff ff       	call   10ead <cio_puts>
   16d74:	83 c4 10             	add    $0x10,%esp
#endif 

	// really not much to do here any more....
}
   16d77:	90                   	nop
   16d78:	c9                   	leave  
   16d79:	c3                   	ret    

00016d7a <user_cleanup>:
** "Unloads" a user program. Deallocates all memory frames and
** cleans up the VM structures.
**
** @param pcb   The PCB of the program to be unloaded
*/
void user_cleanup( pcb_t *pcb ) {
   16d7a:	55                   	push   %ebp
   16d7b:	89 e5                	mov    %esp,%ebp
   16d7d:	83 ec 08             	sub    $0x8,%esp

#if TRACING_USER
	cio_printf( "Uclean: %08x\n", (uint32_t) pcb );
#endif
	
	if( pcb == NULL ) {
   16d80:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16d84:	74 1b                	je     16da1 <user_cleanup+0x27>
		// should this be an error?
		return;
	}

	// free the stack pages
	pcb_stack_free( pcb->stack, pcb->stkpgs );
   16d86:	8b 45 08             	mov    0x8(%ebp),%eax
   16d89:	8b 50 28             	mov    0x28(%eax),%edx
   16d8c:	8b 45 08             	mov    0x8(%ebp),%eax
   16d8f:	8b 40 04             	mov    0x4(%eax),%eax
   16d92:	83 ec 08             	sub    $0x8,%esp
   16d95:	52                   	push   %edx
   16d96:	50                   	push   %eax
   16d97:	e8 0e cc ff ff       	call   139aa <pcb_stack_free>
   16d9c:	83 c4 10             	add    $0x10,%esp
   16d9f:	eb 01                	jmp    16da2 <user_cleanup+0x28>
		return;
   16da1:	90                   	nop
}
   16da2:	c9                   	leave  
   16da3:	c3                   	ret    

00016da4 <pci_read_config>:
#include <drivers/intel_8255x.h>
#include <types.h>
#include <x86/ops.h>
#include <cio.h>

static uint32_t pci_read_config(int bus, int device, int func, int offset) {
   16da4:	55                   	push   %ebp
   16da5:	89 e5                	mov    %esp,%ebp
   16da7:	83 ec 20             	sub    $0x20,%esp
  uint32_t address =
      (1 << 31)          /* Enable bit */
      | (bus << 16)      /* Bus number */
   16daa:	8b 45 08             	mov    0x8(%ebp),%eax
   16dad:	c1 e0 10             	shl    $0x10,%eax
   16db0:	0d 00 00 00 80       	or     $0x80000000,%eax
   16db5:	89 c2                	mov    %eax,%edx
      | (device << 11)   /* Device number */
   16db7:	8b 45 0c             	mov    0xc(%ebp),%eax
   16dba:	c1 e0 0b             	shl    $0xb,%eax
   16dbd:	09 c2                	or     %eax,%edx
      | (func << 8)      /* Function number */
   16dbf:	8b 45 10             	mov    0x10(%ebp),%eax
   16dc2:	c1 e0 08             	shl    $0x8,%eax
   16dc5:	09 c2                	or     %eax,%edx
      | (offset & 0xFC); /* Register number (must be 4-byte aligned) */
   16dc7:	8b 45 14             	mov    0x14(%ebp),%eax
   16dca:	25 fc 00 00 00       	and    $0xfc,%eax
   16dcf:	09 d0                	or     %edx,%eax
  uint32_t address =
   16dd1:	89 45 fc             	mov    %eax,-0x4(%ebp)
   16dd4:	c7 45 f0 f8 0c 00 00 	movl   $0xcf8,-0x10(%ebp)
   16ddb:	8b 45 fc             	mov    -0x4(%ebp),%eax
   16dde:	89 45 ec             	mov    %eax,-0x14(%ebp)
}

OPSINLINED static inline void
outl( int port, uint32_t data )
{
	__asm__ __volatile__( "outl %0,%w1" : : "a" (data), "d" (port) );
   16de1:	8b 45 ec             	mov    -0x14(%ebp),%eax
   16de4:	8b 55 f0             	mov    -0x10(%ebp),%edx
   16de7:	ef                   	out    %eax,(%dx)
   16de8:	c7 45 f8 fc 0c 00 00 	movl   $0xcfc,-0x8(%ebp)
	__asm__ __volatile__( "inl %w1,%0" : "=a" (data) : "d" (port) );
   16def:	8b 45 f8             	mov    -0x8(%ebp),%eax
   16df2:	89 c2                	mov    %eax,%edx
   16df4:	ed                   	in     (%dx),%eax
   16df5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return data;
   16df8:	8b 45 f4             	mov    -0xc(%ebp),%eax

  outl(0xCF8, address); /* Write address to PCI config space */
  return inl(0xCFC);    /* Read data from PCI config space */
   16dfb:	90                   	nop
}
   16dfc:	c9                   	leave  
   16dfd:	c3                   	ret    

00016dfe <detect_intel_8255x>:

int detect_intel_8255x() {
   16dfe:	55                   	push   %ebp
   16dff:	89 e5                	mov    %esp,%ebp
   16e01:	83 ec 38             	sub    $0x38,%esp
  int bus;
  int dev;
  int func;
  uint32_t val;
  int found = 0;
   16e04:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  /* Set up the function pointers */
  // e100_state.dev.read = xv6_read;
  // e100_state.dev.write = xv6_write;

  /* Search PCI bus for Intel 8255x device */
  for (bus = 0; bus < 256 && !found; bus++) {
   16e0b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   16e12:	e9 ef 00 00 00       	jmp    16f06 <detect_intel_8255x+0x108>
    for (dev = 0; dev < 32 && !found; dev++) {
   16e17:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   16e1e:	e9 cf 00 00 00       	jmp    16ef2 <detect_intel_8255x+0xf4>
      for (func = 0; func < 8 && !found; func++) {
   16e23:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   16e2a:	e9 af 00 00 00       	jmp    16ede <detect_intel_8255x+0xe0>
        val = pci_read_config(bus, dev, func, 0);
   16e2f:	6a 00                	push   $0x0
   16e31:	ff 75 ec             	pushl  -0x14(%ebp)
   16e34:	ff 75 f0             	pushl  -0x10(%ebp)
   16e37:	ff 75 f4             	pushl  -0xc(%ebp)
   16e3a:	e8 65 ff ff ff       	call   16da4 <pci_read_config>
   16e3f:	83 c4 10             	add    $0x10,%esp
   16e42:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        if ((val & 0xFFFF) == 0x8086) { /* Intel vendor ID */
   16e45:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16e48:	0f b7 c0             	movzwl %ax,%eax
   16e4b:	3d 86 80 00 00       	cmp    $0x8086,%eax
   16e50:	0f 85 84 00 00 00    	jne    16eda <detect_intel_8255x+0xdc>
          uint16_t device_id = (val >> 16) & 0xFFFF;
   16e56:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16e59:	c1 e8 10             	shr    $0x10,%eax
   16e5c:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)

          if (device_id == 0x1227 || /* 82557 */
   16e60:	66 81 7d e2 27 12    	cmpw   $0x1227,-0x1e(%ebp)
   16e66:	74 08                	je     16e70 <detect_intel_8255x+0x72>
   16e68:	66 81 7d e2 29 12    	cmpw   $0x1229,-0x1e(%ebp)
   16e6e:	75 6a                	jne    16eda <detect_intel_8255x+0xdc>
              device_id == 0x1229) { /* 82559 */
                cio_printf("e100: found Intel 8255x at bus %d, device %d, function %d\n", bus, dev, func);
   16e70:	ff 75 ec             	pushl  -0x14(%ebp)
   16e73:	ff 75 f0             	pushl  -0x10(%ebp)
   16e76:	ff 75 f4             	pushl  -0xc(%ebp)
   16e79:	68 08 bb 01 00       	push   $0x1bb08
   16e7e:	e8 a4 a6 ff ff       	call   11527 <cio_printf>
   16e83:	83 c4 10             	add    $0x10,%esp

                // Get I/O base address
                uint32_t io_bar = pci_read_config(bus, dev, func, 0x10);
   16e86:	6a 10                	push   $0x10
   16e88:	ff 75 ec             	pushl  -0x14(%ebp)
   16e8b:	ff 75 f0             	pushl  -0x10(%ebp)
   16e8e:	ff 75 f4             	pushl  -0xc(%ebp)
   16e91:	e8 0e ff ff ff       	call   16da4 <pci_read_config>
   16e96:	83 c4 10             	add    $0x10,%esp
   16e99:	89 45 dc             	mov    %eax,-0x24(%ebp)
                uint32_t io_base = io_bar & ~0x3; /* Mask off the low bits */
   16e9c:	8b 45 dc             	mov    -0x24(%ebp),%eax
   16e9f:	83 e0 fc             	and    $0xfffffffc,%eax
   16ea2:	89 45 d8             	mov    %eax,-0x28(%ebp)

                // Get interrupt line
                uint8_t irq = pci_read_config(bus, dev, func, 0x3C) & 0xFF;
   16ea5:	6a 3c                	push   $0x3c
   16ea7:	ff 75 ec             	pushl  -0x14(%ebp)
   16eaa:	ff 75 f0             	pushl  -0x10(%ebp)
   16ead:	ff 75 f4             	pushl  -0xc(%ebp)
   16eb0:	e8 ef fe ff ff       	call   16da4 <pci_read_config>
   16eb5:	83 c4 10             	add    $0x10,%esp
   16eb8:	88 45 d7             	mov    %al,-0x29(%ebp)
                cio_printf("e100: I/O base = 0x%x, IRQ = %d\n", io_base, irq);
   16ebb:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
   16ebf:	83 ec 04             	sub    $0x4,%esp
   16ec2:	50                   	push   %eax
   16ec3:	ff 75 d8             	pushl  -0x28(%ebp)
   16ec6:	68 44 bb 01 00       	push   $0x1bb44
   16ecb:	e8 57 a6 ff ff       	call   11527 <cio_printf>
   16ed0:	83 c4 10             	add    $0x10,%esp

                return 0;
   16ed3:	b8 00 00 00 00       	mov    $0x0,%eax
   16ed8:	eb 3f                	jmp    16f19 <detect_intel_8255x+0x11b>
      for (func = 0; func < 8 && !found; func++) {
   16eda:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   16ede:	83 7d ec 07          	cmpl   $0x7,-0x14(%ebp)
   16ee2:	7f 0a                	jg     16eee <detect_intel_8255x+0xf0>
   16ee4:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   16ee8:	0f 84 41 ff ff ff    	je     16e2f <detect_intel_8255x+0x31>
    for (dev = 0; dev < 32 && !found; dev++) {
   16eee:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   16ef2:	83 7d f0 1f          	cmpl   $0x1f,-0x10(%ebp)
   16ef6:	7f 0a                	jg     16f02 <detect_intel_8255x+0x104>
   16ef8:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   16efc:	0f 84 21 ff ff ff    	je     16e23 <detect_intel_8255x+0x25>
  for (bus = 0; bus < 256 && !found; bus++) {
   16f02:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   16f06:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
   16f0d:	7f 0a                	jg     16f19 <detect_intel_8255x+0x11b>
   16f0f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   16f13:	0f 84 fe fe ff ff    	je     16e17 <detect_intel_8255x+0x19>
          }
        }
      }
    }
  }
}
   16f19:	c9                   	leave  
   16f1a:	c3                   	ret    

00016f1b <intel_8255x_init>:

int intel_8255x_init(void) { return detect_intel_8255x(); }
   16f1b:	55                   	push   %ebp
   16f1c:	89 e5                	mov    %esp,%ebp
   16f1e:	83 ec 08             	sub    $0x8,%esp
   16f21:	e8 d8 fe ff ff       	call   16dfe <detect_intel_8255x>
   16f26:	c9                   	leave  
   16f27:	c3                   	ret    

00016f28 <exit>:

/*
** "real" system calls
*/

SYSCALL(exit)
   16f28:	b8 00 00 00 00       	mov    $0x0,%eax
   16f2d:	cd 80                	int    $0x80
   16f2f:	c3                   	ret    

00016f30 <waitpid>:
SYSCALL(waitpid)
   16f30:	b8 01 00 00 00       	mov    $0x1,%eax
   16f35:	cd 80                	int    $0x80
   16f37:	c3                   	ret    

00016f38 <fork>:
SYSCALL(fork)
   16f38:	b8 02 00 00 00       	mov    $0x2,%eax
   16f3d:	cd 80                	int    $0x80
   16f3f:	c3                   	ret    

00016f40 <exec>:
SYSCALL(exec)
   16f40:	b8 03 00 00 00       	mov    $0x3,%eax
   16f45:	cd 80                	int    $0x80
   16f47:	c3                   	ret    

00016f48 <read>:
SYSCALL(read)
   16f48:	b8 04 00 00 00       	mov    $0x4,%eax
   16f4d:	cd 80                	int    $0x80
   16f4f:	c3                   	ret    

00016f50 <write>:
SYSCALL(write)
   16f50:	b8 05 00 00 00       	mov    $0x5,%eax
   16f55:	cd 80                	int    $0x80
   16f57:	c3                   	ret    

00016f58 <getpid>:
SYSCALL(getpid)
   16f58:	b8 06 00 00 00       	mov    $0x6,%eax
   16f5d:	cd 80                	int    $0x80
   16f5f:	c3                   	ret    

00016f60 <getppid>:
SYSCALL(getppid)
   16f60:	b8 07 00 00 00       	mov    $0x7,%eax
   16f65:	cd 80                	int    $0x80
   16f67:	c3                   	ret    

00016f68 <gettime>:
SYSCALL(gettime)
   16f68:	b8 08 00 00 00       	mov    $0x8,%eax
   16f6d:	cd 80                	int    $0x80
   16f6f:	c3                   	ret    

00016f70 <getprio>:
SYSCALL(getprio)
   16f70:	b8 09 00 00 00       	mov    $0x9,%eax
   16f75:	cd 80                	int    $0x80
   16f77:	c3                   	ret    

00016f78 <setprio>:
SYSCALL(setprio)
   16f78:	b8 0a 00 00 00       	mov    $0xa,%eax
   16f7d:	cd 80                	int    $0x80
   16f7f:	c3                   	ret    

00016f80 <kill>:
SYSCALL(kill)
   16f80:	b8 0b 00 00 00       	mov    $0xb,%eax
   16f85:	cd 80                	int    $0x80
   16f87:	c3                   	ret    

00016f88 <sleep>:
SYSCALL(sleep)
   16f88:	b8 0c 00 00 00       	mov    $0xc,%eax
   16f8d:	cd 80                	int    $0x80
   16f8f:	c3                   	ret    

00016f90 <bogus>:

/*
** This is a bogus system call; it's here so that we can test
** our handling of out-of-range syscall codes in the syscall ISR.
*/
SYSCALL(bogus)
   16f90:	b8 ad 0b 00 00       	mov    $0xbad,%eax
   16f95:	cd 80                	int    $0x80
   16f97:	c3                   	ret    

00016f98 <fake_exit>:
*/

	.globl	fake_exit
fake_exit:
	// alternate: could push a "fake exit" status
	pushl	%eax	// termination status returned by main()
   16f98:	50                   	push   %eax
	call	exit	// terminate this process
   16f99:	e8 8a ff ff ff       	call   16f28 <exit>

00016f9e <idle>:
** when there is no other process to dispatch.
**
** Invoked as:	idle
*/

USERMAIN( idle ) {
   16f9e:	55                   	push   %ebp
   16f9f:	89 e5                	mov    %esp,%ebp
   16fa1:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char ch = '.';
#endif

	// ignore the command-line arguments
	(void) argc;
	char *name = argv[0] ? argv[0] : "nobody";
   16fa7:	8b 45 0c             	mov    0xc(%ebp),%eax
   16faa:	8b 00                	mov    (%eax),%eax
   16fac:	85 c0                	test   %eax,%eax
   16fae:	74 07                	je     16fb7 <idle+0x19>
   16fb0:	8b 45 0c             	mov    0xc(%ebp),%eax
   16fb3:	8b 00                	mov    (%eax),%eax
   16fb5:	eb 05                	jmp    16fbc <idle+0x1e>
   16fb7:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   16fbc:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// get some current information
	uint_t pid = getpid();
   16fbf:	e8 94 ff ff ff       	call   16f58 <getpid>
   16fc4:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32_t now = gettime();
   16fc7:	e8 9c ff ff ff       	call   16f68 <gettime>
   16fcc:	89 45 e8             	mov    %eax,-0x18(%ebp)
	enum priority_e prio = getprio();
   16fcf:	e8 9c ff ff ff       	call   16f70 <getprio>
   16fd4:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	char buf[128];
	usprint( buf, "%s [%d], started @ %u\n", name, pid, prio, now );
   16fd7:	83 ec 08             	sub    $0x8,%esp
   16fda:	ff 75 e8             	pushl  -0x18(%ebp)
   16fdd:	ff 75 e4             	pushl  -0x1c(%ebp)
   16fe0:	ff 75 ec             	pushl  -0x14(%ebp)
   16fe3:	ff 75 f0             	pushl  -0x10(%ebp)
   16fe6:	68 6f bb 01 00       	push   $0x1bb6f
   16feb:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
   16ff1:	50                   	push   %eax
   16ff2:	e8 db 2c 00 00       	call   19cd2 <usprint>
   16ff7:	83 c4 20             	add    $0x20,%esp
	cwrites( buf );
   16ffa:	83 ec 0c             	sub    $0xc,%esp
   16ffd:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
   17003:	50                   	push   %eax
   17004:	e8 b6 33 00 00       	call   1a3bf <cwrites>
   17009:	83 c4 10             	add    $0x10,%esp

	// idle() should never block - it must always be available
	// for dispatching when we need to pick a new current process

	for(;;) {
		DELAY(LONG);
   1700c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   17013:	eb 04                	jmp    17019 <idle+0x7b>
   17015:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   17019:	81 7d f4 ff e0 f5 05 	cmpl   $0x5f5e0ff,-0xc(%ebp)
   17020:	7e f3                	jle    17015 <idle+0x77>
   17022:	eb e8                	jmp    1700c <idle+0x6e>

00017024 <usage>:
};

/*
** usage function
*/
static void usage( void ) {
   17024:	55                   	push   %ebp
   17025:	89 e5                	mov    %esp,%ebp
   17027:	83 ec 18             	sub    $0x18,%esp
	swrites( "\nTests - run with '@x', where 'x' is one or more of:\n " );
   1702a:	83 ec 0c             	sub    $0xc,%esp
   1702d:	68 54 bc 01 00       	push   $0x1bc54
   17032:	e8 ee 33 00 00       	call   1a425 <swrites>
   17037:	83 c4 10             	add    $0x10,%esp
	proc_t *p = sh_spawn_table;
   1703a:	c7 45 f4 20 d1 01 00 	movl   $0x1d120,-0xc(%ebp)
	while( p->entry != TBLEND ) {
   17041:	eb 23                	jmp    17066 <usage+0x42>
		swritech( ' ' );
   17043:	83 ec 0c             	sub    $0xc,%esp
   17046:	6a 20                	push   $0x20
   17048:	e8 b7 33 00 00       	call   1a404 <swritech>
   1704d:	83 c4 10             	add    $0x10,%esp
		swritech( p->select[0] );
   17050:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17053:	0f b6 40 09          	movzbl 0x9(%eax),%eax
   17057:	0f be c0             	movsbl %al,%eax
   1705a:	83 ec 0c             	sub    $0xc,%esp
   1705d:	50                   	push   %eax
   1705e:	e8 a1 33 00 00       	call   1a404 <swritech>
   17063:	83 c4 10             	add    $0x10,%esp
	while( p->entry != TBLEND ) {
   17066:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17069:	8b 00                	mov    (%eax),%eax
   1706b:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   17070:	75 d1                	jne    17043 <usage+0x1f>
	}
	swrites( "\nOther commands: @* (all), @h (help), @x (exit)\n" );
   17072:	83 ec 0c             	sub    $0xc,%esp
   17075:	68 8c bc 01 00       	push   $0x1bc8c
   1707a:	e8 a6 33 00 00       	call   1a425 <swrites>
   1707f:	83 c4 10             	add    $0x10,%esp
}
   17082:	90                   	nop
   17083:	c9                   	leave  
   17084:	c3                   	ret    

00017085 <run>:

/*
** run a program from the program table, or a builtin command
*/
static int run( char which ) {
   17085:	55                   	push   %ebp
   17086:	89 e5                	mov    %esp,%ebp
   17088:	53                   	push   %ebx
   17089:	81 ec a4 00 00 00    	sub    $0xa4,%esp
   1708f:	8b 45 08             	mov    0x8(%ebp),%eax
   17092:	88 85 64 ff ff ff    	mov    %al,-0x9c(%ebp)
	char buf[128];
	register proc_t *p;

	if( which == 'h' ) {
   17098:	80 bd 64 ff ff ff 68 	cmpb   $0x68,-0x9c(%ebp)
   1709f:	75 0a                	jne    170ab <run+0x26>

		// builtin "help" command
		usage();
   170a1:	e8 7e ff ff ff       	call   17024 <usage>
   170a6:	e9 e0 00 00 00       	jmp    1718b <run+0x106>

	} else if( which == 'x' ) {
   170ab:	80 bd 64 ff ff ff 78 	cmpb   $0x78,-0x9c(%ebp)
   170b2:	75 0c                	jne    170c0 <run+0x3b>

		// builtin "exit" command
		time_to_stop = true;
   170b4:	c6 05 b4 f1 01 00 01 	movb   $0x1,0x1f1b4
   170bb:	e9 cb 00 00 00       	jmp    1718b <run+0x106>

	} else if( which == '*' ) {
   170c0:	80 bd 64 ff ff ff 2a 	cmpb   $0x2a,-0x9c(%ebp)
   170c7:	75 40                	jne    17109 <run+0x84>

		// torture test! run everything!
		for( p = sh_spawn_table; p->entry != TBLEND; ++p ) {
   170c9:	bb 20 d1 01 00       	mov    $0x1d120,%ebx
   170ce:	eb 2b                	jmp    170fb <run+0x76>
			int status = spawn( p->entry, p->args );
   170d0:	8d 53 0c             	lea    0xc(%ebx),%edx
   170d3:	8b 03                	mov    (%ebx),%eax
   170d5:	83 ec 08             	sub    $0x8,%esp
   170d8:	52                   	push   %edx
   170d9:	50                   	push   %eax
   170da:	e8 4a 32 00 00       	call   1a329 <spawn>
   170df:	83 c4 10             	add    $0x10,%esp
   170e2:	89 45 f0             	mov    %eax,-0x10(%ebp)
			if( status > 0 ) {
   170e5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   170e9:	7e 0d                	jle    170f8 <run+0x73>
				++children;
   170eb:	a1 b8 f1 01 00       	mov    0x1f1b8,%eax
   170f0:	83 c0 01             	add    $0x1,%eax
   170f3:	a3 b8 f1 01 00       	mov    %eax,0x1f1b8
		for( p = sh_spawn_table; p->entry != TBLEND; ++p ) {
   170f8:	83 c3 34             	add    $0x34,%ebx
   170fb:	8b 03                	mov    (%ebx),%eax
   170fd:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   17102:	75 cc                	jne    170d0 <run+0x4b>
   17104:	e9 82 00 00 00       	jmp    1718b <run+0x106>
		}

	} else {

		// must be a single test; find and run it
		for( p = sh_spawn_table; p->entry != TBLEND; ++p ) {
   17109:	bb 20 d1 01 00       	mov    $0x1d120,%ebx
   1710e:	eb 3c                	jmp    1714c <run+0xc7>
			if( p->select[0] == which ) {
   17110:	0f b6 43 09          	movzbl 0x9(%ebx),%eax
   17114:	38 85 64 ff ff ff    	cmp    %al,-0x9c(%ebp)
   1711a:	75 2d                	jne    17149 <run+0xc4>
				// found it!
				int status = spawn( p->entry, p->args );
   1711c:	8d 53 0c             	lea    0xc(%ebx),%edx
   1711f:	8b 03                	mov    (%ebx),%eax
   17121:	83 ec 08             	sub    $0x8,%esp
   17124:	52                   	push   %edx
   17125:	50                   	push   %eax
   17126:	e8 fe 31 00 00       	call   1a329 <spawn>
   1712b:	83 c4 10             	add    $0x10,%esp
   1712e:	89 45 f4             	mov    %eax,-0xc(%ebp)
				if( status > 0 ) {
   17131:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   17135:	7e 0d                	jle    17144 <run+0xbf>
					++children;
   17137:	a1 b8 f1 01 00       	mov    0x1f1b8,%eax
   1713c:	83 c0 01             	add    $0x1,%eax
   1713f:	a3 b8 f1 01 00       	mov    %eax,0x1f1b8
				}
				return status;
   17144:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17147:	eb 47                	jmp    17190 <run+0x10b>
		for( p = sh_spawn_table; p->entry != TBLEND; ++p ) {
   17149:	83 c3 34             	add    $0x34,%ebx
   1714c:	8b 03                	mov    (%ebx),%eax
   1714e:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   17153:	75 bb                	jne    17110 <run+0x8b>
			}
		}

		// uh-oh, made it through the table without finding the program
		usprint( buf, "shell: unknown cmd '%c'\n", which );
   17155:	0f be 85 64 ff ff ff 	movsbl -0x9c(%ebp),%eax
   1715c:	83 ec 04             	sub    $0x4,%esp
   1715f:	50                   	push   %eax
   17160:	68 bd bc 01 00       	push   $0x1bcbd
   17165:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
   1716b:	50                   	push   %eax
   1716c:	e8 61 2b 00 00       	call   19cd2 <usprint>
   17171:	83 c4 10             	add    $0x10,%esp
		swrites( buf );
   17174:	83 ec 0c             	sub    $0xc,%esp
   17177:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
   1717d:	50                   	push   %eax
   1717e:	e8 a2 32 00 00       	call   1a425 <swrites>
   17183:	83 c4 10             	add    $0x10,%esp
		usage();
   17186:	e8 99 fe ff ff       	call   17024 <usage>
	}

	return 0;
   1718b:	b8 00 00 00 00       	mov    $0x0,%eax
}
   17190:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   17193:	c9                   	leave  
   17194:	c3                   	ret    

00017195 <edit>:
** edit - perform any command-line editing we need to do
**
** @param line   Input line buffer
** @param n      Number of valid bytes in the buffer
*/
static int edit( char line[], int n ) {
   17195:	55                   	push   %ebp
   17196:	89 e5                	mov    %esp,%ebp
   17198:	83 ec 10             	sub    $0x10,%esp
	char *ptr = line + n - 1;	// last char in buffer
   1719b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1719e:	8d 50 ff             	lea    -0x1(%eax),%edx
   171a1:	8b 45 08             	mov    0x8(%ebp),%eax
   171a4:	01 d0                	add    %edx,%eax
   171a6:	89 45 fc             	mov    %eax,-0x4(%ebp)

	// strip the EOLN sequence
	while( n > 0 ) {
   171a9:	eb 18                	jmp    171c3 <edit+0x2e>
		if( *ptr == '\n' || *ptr == '\r' ) {
   171ab:	8b 45 fc             	mov    -0x4(%ebp),%eax
   171ae:	0f b6 00             	movzbl (%eax),%eax
   171b1:	3c 0a                	cmp    $0xa,%al
   171b3:	74 0a                	je     171bf <edit+0x2a>
   171b5:	8b 45 fc             	mov    -0x4(%ebp),%eax
   171b8:	0f b6 00             	movzbl (%eax),%eax
   171bb:	3c 0d                	cmp    $0xd,%al
   171bd:	75 0a                	jne    171c9 <edit+0x34>
			--n;
   171bf:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
	while( n > 0 ) {
   171c3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   171c7:	7f e2                	jg     171ab <edit+0x16>
			break;
		}
	}

	// add a trailing NUL byte
	if( n > 0 ) {
   171c9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   171cd:	7e 0b                	jle    171da <edit+0x45>
		line[n] = '\0';
   171cf:	8b 55 0c             	mov    0xc(%ebp),%edx
   171d2:	8b 45 08             	mov    0x8(%ebp),%eax
   171d5:	01 d0                	add    %edx,%eax
   171d7:	c6 00 00             	movb   $0x0,(%eax)
	}

	return n;
   171da:	8b 45 0c             	mov    0xc(%ebp),%eax
}
   171dd:	c9                   	leave  
   171de:	c3                   	ret    

000171df <shell>:
** shell - extremely simple shell for spawning test programs
**
** Scheduled by _kshell() when the character 'u' is typed on
** the console keyboard.
*/
USERMAIN( shell ) {
   171df:	55                   	push   %ebp
   171e0:	89 e5                	mov    %esp,%ebp
   171e2:	81 ec 28 01 00 00    	sub    $0x128,%esp
	char line[128];

	// keep the compiler happy
	(void) argc;
	char *name = argv[0] ? argv[0] : "nobody";
   171e8:	8b 45 0c             	mov    0xc(%ebp),%eax
   171eb:	8b 00                	mov    (%eax),%eax
   171ed:	85 c0                	test   %eax,%eax
   171ef:	74 07                	je     171f8 <shell+0x19>
   171f1:	8b 45 0c             	mov    0xc(%ebp),%eax
   171f4:	8b 00                	mov    (%eax),%eax
   171f6:	eb 05                	jmp    171fd <shell+0x1e>
   171f8:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   171fd:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// report that we're up and running
	usprint( line, "%s is ready\n", name );
   17200:	83 ec 04             	sub    $0x4,%esp
   17203:	ff 75 ec             	pushl  -0x14(%ebp)
   17206:	68 d6 bc 01 00       	push   $0x1bcd6
   1720b:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17211:	50                   	push   %eax
   17212:	e8 bb 2a 00 00       	call   19cd2 <usprint>
   17217:	83 c4 10             	add    $0x10,%esp
	swrites( line );
   1721a:	83 ec 0c             	sub    $0xc,%esp
   1721d:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17223:	50                   	push   %eax
   17224:	e8 fc 31 00 00       	call   1a425 <swrites>
   17229:	83 c4 10             	add    $0x10,%esp

	// print a summary of the commands we'll accept
	usage();
   1722c:	e8 f3 fd ff ff       	call   17024 <usage>

	// loop forever
	while( !time_to_stop ) {
   17231:	e9 a7 01 00 00       	jmp    173dd <shell+0x1fe>
		char *ptr;

		// the shell reads one line from the keyboard, parses it,
		// and performs whatever command it requests.

		swrites( "\n> " );
   17236:	83 ec 0c             	sub    $0xc,%esp
   17239:	68 e3 bc 01 00       	push   $0x1bce3
   1723e:	e8 e2 31 00 00       	call   1a425 <swrites>
   17243:	83 c4 10             	add    $0x10,%esp
		int n = read( CHAN_SIO, line, sizeof(line) );
   17246:	83 ec 04             	sub    $0x4,%esp
   17249:	68 80 00 00 00       	push   $0x80
   1724e:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17254:	50                   	push   %eax
   17255:	6a 01                	push   $0x1
   17257:	e8 ec fc ff ff       	call   16f48 <read>
   1725c:	83 c4 10             	add    $0x10,%esp
   1725f:	89 45 e8             	mov    %eax,-0x18(%ebp)
		
		// shortest valid command is "@?", so must have 3+ chars here
		if( n < 3 ) {
   17262:	83 7d e8 02          	cmpl   $0x2,-0x18(%ebp)
   17266:	7f 05                	jg     1726d <shell+0x8e>
			// ignore it
			continue;
   17268:	e9 70 01 00 00       	jmp    173dd <shell+0x1fe>
		}

		// edit it as needed; new shortest command is 2+ chars
		if( (n=edit(line,n)) < 2 ) {
   1726d:	83 ec 08             	sub    $0x8,%esp
   17270:	ff 75 e8             	pushl  -0x18(%ebp)
   17273:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17279:	50                   	push   %eax
   1727a:	e8 16 ff ff ff       	call   17195 <edit>
   1727f:	83 c4 10             	add    $0x10,%esp
   17282:	89 45 e8             	mov    %eax,-0x18(%ebp)
   17285:	83 7d e8 01          	cmpl   $0x1,-0x18(%ebp)
   17289:	7f 05                	jg     17290 <shell+0xb1>
			continue;
   1728b:	e9 4d 01 00 00       	jmp    173dd <shell+0x1fe>
		}

		// find the '@'
		int i = 0;
   17290:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
		for( ptr = line; i < n; ++i, ++ptr ) {
   17297:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   1729d:	89 45 f4             	mov    %eax,-0xc(%ebp)
   172a0:	eb 12                	jmp    172b4 <shell+0xd5>
			if( *ptr == '@' ) {
   172a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
   172a5:	0f b6 00             	movzbl (%eax),%eax
   172a8:	3c 40                	cmp    $0x40,%al
   172aa:	74 12                	je     172be <shell+0xdf>
		for( ptr = line; i < n; ++i, ++ptr ) {
   172ac:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   172b0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   172b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
   172b7:	3b 45 e8             	cmp    -0x18(%ebp),%eax
   172ba:	7c e6                	jl     172a2 <shell+0xc3>
   172bc:	eb 01                	jmp    172bf <shell+0xe0>
				break;
   172be:	90                   	nop
			}
		}

		// did we find an '@'?
		if( i < n ) {
   172bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
   172c2:	3b 45 e8             	cmp    -0x18(%ebp),%eax
   172c5:	0f 8d 12 01 00 00    	jge    173dd <shell+0x1fe>

			// yes; process any commands that follow it
			++ptr;
   172cb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

			for( ; *ptr != '\0'; ++ptr ) {
   172cf:	eb 66                	jmp    17337 <shell+0x158>
				char buf[128];
				int pid = run( *ptr );
   172d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
   172d4:	0f b6 00             	movzbl (%eax),%eax
   172d7:	0f be c0             	movsbl %al,%eax
   172da:	83 ec 0c             	sub    $0xc,%esp
   172dd:	50                   	push   %eax
   172de:	e8 a2 fd ff ff       	call   17085 <run>
   172e3:	83 c4 10             	add    $0x10,%esp
   172e6:	89 45 e4             	mov    %eax,-0x1c(%ebp)

				if( pid < 0 ) {
   172e9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   172ed:	79 39                	jns    17328 <shell+0x149>
					// spawn() failed
					usprint( buf, "+++ %s spawn %c failed, code %d\n",
							name, *ptr, pid );
   172ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
   172f2:	0f b6 00             	movzbl (%eax),%eax
					usprint( buf, "+++ %s spawn %c failed, code %d\n",
   172f5:	0f be c0             	movsbl %al,%eax
   172f8:	83 ec 0c             	sub    $0xc,%esp
   172fb:	ff 75 e4             	pushl  -0x1c(%ebp)
   172fe:	50                   	push   %eax
   172ff:	ff 75 ec             	pushl  -0x14(%ebp)
   17302:	68 e8 bc 01 00       	push   $0x1bce8
   17307:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   1730d:	50                   	push   %eax
   1730e:	e8 bf 29 00 00       	call   19cd2 <usprint>
   17313:	83 c4 20             	add    $0x20,%esp
					cwrites( buf );
   17316:	83 ec 0c             	sub    $0xc,%esp
   17319:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   1731f:	50                   	push   %eax
   17320:	e8 9a 30 00 00       	call   1a3bf <cwrites>
   17325:	83 c4 10             	add    $0x10,%esp
				}

				// should we end it all?
				if( time_to_stop ) {
   17328:	0f b6 05 b4 f1 01 00 	movzbl 0x1f1b4,%eax
   1732f:	84 c0                	test   %al,%al
   17331:	75 13                	jne    17346 <shell+0x167>
			for( ; *ptr != '\0'; ++ptr ) {
   17333:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   17337:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1733a:	0f b6 00             	movzbl (%eax),%eax
   1733d:	84 c0                	test   %al,%al
   1733f:	75 90                	jne    172d1 <shell+0xf2>
   17341:	e9 8a 00 00 00       	jmp    173d0 <shell+0x1f1>
					break;
   17346:	90                   	nop
				}
			} // for

			// now, wait for all the spawned children
			while( children > 0 ) {
   17347:	e9 84 00 00 00       	jmp    173d0 <shell+0x1f1>
				// wait for the child
				int32_t status;
				char buf[128];
				int whom = waitpid( 0, &status );
   1734c:	83 ec 08             	sub    $0x8,%esp
   1734f:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17355:	50                   	push   %eax
   17356:	6a 00                	push   $0x0
   17358:	e8 d3 fb ff ff       	call   16f30 <waitpid>
   1735d:	83 c4 10             	add    $0x10,%esp
   17360:	89 45 e0             	mov    %eax,-0x20(%ebp)

				// figure out the result
				if( whom == E_NO_CHILDREN ) {
   17363:	83 7d e0 fc          	cmpl   $0xfffffffc,-0x20(%ebp)
   17367:	75 02                	jne    1736b <shell+0x18c>
   17369:	eb 72                	jmp    173dd <shell+0x1fe>
					break;
				} else if( whom < 1 ) {
   1736b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   1736f:	7f 1c                	jg     1738d <shell+0x1ae>
					usprint( buf, "%s: waitpid() returned %d\n", name, whom );
   17371:	ff 75 e0             	pushl  -0x20(%ebp)
   17374:	ff 75 ec             	pushl  -0x14(%ebp)
   17377:	68 09 bd 01 00       	push   $0x1bd09
   1737c:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   17382:	50                   	push   %eax
   17383:	e8 4a 29 00 00       	call   19cd2 <usprint>
   17388:	83 c4 10             	add    $0x10,%esp
   1738b:	eb 31                	jmp    173be <shell+0x1df>
				} else {
					--children;
   1738d:	a1 b8 f1 01 00       	mov    0x1f1b8,%eax
   17392:	83 e8 01             	sub    $0x1,%eax
   17395:	a3 b8 f1 01 00       	mov    %eax,0x1f1b8
					usprint( buf, "%s: PID %d exit status %d\n",
   1739a:	8b 85 5c ff ff ff    	mov    -0xa4(%ebp),%eax
   173a0:	83 ec 0c             	sub    $0xc,%esp
   173a3:	50                   	push   %eax
   173a4:	ff 75 e0             	pushl  -0x20(%ebp)
   173a7:	ff 75 ec             	pushl  -0x14(%ebp)
   173aa:	68 24 bd 01 00       	push   $0x1bd24
   173af:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   173b5:	50                   	push   %eax
   173b6:	e8 17 29 00 00       	call   19cd2 <usprint>
   173bb:	83 c4 20             	add    $0x20,%esp
							name, whom, status );
				}
				// report it
				swrites( buf );
   173be:	83 ec 0c             	sub    $0xc,%esp
   173c1:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   173c7:	50                   	push   %eax
   173c8:	e8 58 30 00 00       	call   1a425 <swrites>
   173cd:	83 c4 10             	add    $0x10,%esp
			while( children > 0 ) {
   173d0:	a1 b8 f1 01 00       	mov    0x1f1b8,%eax
   173d5:	85 c0                	test   %eax,%eax
   173d7:	0f 8f 6f ff ff ff    	jg     1734c <shell+0x16d>
	while( !time_to_stop ) {
   173dd:	0f b6 05 b4 f1 01 00 	movzbl 0x1f1b4,%eax
   173e4:	84 c0                	test   %al,%al
   173e6:	0f 84 4a fe ff ff    	je     17236 <shell+0x57>
			}
		}  // if i < n
	}  // while

	cwrites( "!!! shell exited loop???\n" );
   173ec:	83 ec 0c             	sub    $0xc,%esp
   173ef:	68 3f bd 01 00       	push   $0x1bd3f
   173f4:	e8 c6 2f 00 00       	call   1a3bf <cwrites>
   173f9:	83 c4 10             	add    $0x10,%esp
	exit( 1 );
   173fc:	83 ec 0c             	sub    $0xc,%esp
   173ff:	6a 01                	push   $0x1
   17401:	e8 22 fb ff ff       	call   16f28 <exit>
   17406:	83 c4 10             	add    $0x10,%esp

	// yeah, yeah....
	return( 0 );
   17409:	b8 00 00 00 00       	mov    $0x0,%eax
}
   1740e:	c9                   	leave  
   1740f:	c3                   	ret    

00017410 <process>:
**
** @param proc  pointer to the spawn table entry to be used
*/

static void process( proc_t *proc )
{
   17410:	55                   	push   %ebp
   17411:	89 e5                	mov    %esp,%ebp
   17413:	81 ec 98 00 00 00    	sub    $0x98,%esp
	char buf[128];

	// kick off the process
	int32_t p = fork();
   17419:	e8 1a fb ff ff       	call   16f38 <fork>
   1741e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( p < 0 ) {
   17421:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   17425:	79 34                	jns    1745b <process+0x4b>

		// error!
		usprint( buf, "INIT: fork for #%d failed\n",
				(uint32_t) (proc->entry) );
   17427:	8b 45 08             	mov    0x8(%ebp),%eax
   1742a:	8b 00                	mov    (%eax),%eax
		usprint( buf, "INIT: fork for #%d failed\n",
   1742c:	83 ec 04             	sub    $0x4,%esp
   1742f:	50                   	push   %eax
   17430:	68 66 bd 01 00       	push   $0x1bd66
   17435:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
   1743b:	50                   	push   %eax
   1743c:	e8 91 28 00 00       	call   19cd2 <usprint>
   17441:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   17444:	83 ec 0c             	sub    $0xc,%esp
   17447:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
   1744d:	50                   	push   %eax
   1744e:	e8 6c 2f 00 00       	call   1a3bf <cwrites>
   17453:	83 c4 10             	add    $0x10,%esp
		swritech( ch );

		proc->pid = p;

	}
}
   17456:	e9 84 00 00 00       	jmp    174df <process+0xcf>
	} else if( p == 0 ) {
   1745b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1745f:	75 5f                	jne    174c0 <process+0xb0>
		(void) setprio( proc->e_prio );
   17461:	8b 45 08             	mov    0x8(%ebp),%eax
   17464:	0f b6 40 08          	movzbl 0x8(%eax),%eax
   17468:	0f b6 c0             	movzbl %al,%eax
   1746b:	83 ec 0c             	sub    $0xc,%esp
   1746e:	50                   	push   %eax
   1746f:	e8 04 fb ff ff       	call   16f78 <setprio>
   17474:	83 c4 10             	add    $0x10,%esp
		exec( proc->entry, proc->args );
   17477:	8b 45 08             	mov    0x8(%ebp),%eax
   1747a:	8d 50 0c             	lea    0xc(%eax),%edx
   1747d:	8b 45 08             	mov    0x8(%ebp),%eax
   17480:	8b 00                	mov    (%eax),%eax
   17482:	83 ec 08             	sub    $0x8,%esp
   17485:	52                   	push   %edx
   17486:	50                   	push   %eax
   17487:	e8 b4 fa ff ff       	call   16f40 <exec>
   1748c:	83 c4 10             	add    $0x10,%esp
				(uint32_t) (proc->entry) );
   1748f:	8b 45 08             	mov    0x8(%ebp),%eax
   17492:	8b 00                	mov    (%eax),%eax
		usprint( buf, "INIT: exec(0x%08x) failed\n",
   17494:	83 ec 04             	sub    $0x4,%esp
   17497:	50                   	push   %eax
   17498:	68 81 bd 01 00       	push   $0x1bd81
   1749d:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
   174a3:	50                   	push   %eax
   174a4:	e8 29 28 00 00       	call   19cd2 <usprint>
   174a9:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   174ac:	83 ec 0c             	sub    $0xc,%esp
   174af:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
   174b5:	50                   	push   %eax
   174b6:	e8 04 2f 00 00       	call   1a3bf <cwrites>
   174bb:	83 c4 10             	add    $0x10,%esp
}
   174be:	eb 1f                	jmp    174df <process+0xcf>
		swritech( ch );
   174c0:	0f b6 05 3c d6 01 00 	movzbl 0x1d63c,%eax
   174c7:	0f be c0             	movsbl %al,%eax
   174ca:	83 ec 0c             	sub    $0xc,%esp
   174cd:	50                   	push   %eax
   174ce:	e8 31 2f 00 00       	call   1a404 <swritech>
   174d3:	83 c4 10             	add    $0x10,%esp
		proc->pid = p;
   174d6:	8b 55 f4             	mov    -0xc(%ebp),%edx
   174d9:	8b 45 08             	mov    0x8(%ebp),%eax
   174dc:	89 50 04             	mov    %edx,0x4(%eax)
}
   174df:	90                   	nop
   174e0:	c9                   	leave  
   174e1:	c3                   	ret    

000174e2 <init>:
/*
** The initial user process. Should be invoked with zero or one
** argument; if provided, the first argument should be the ASCII
** character 'init' will print to indicate the spawning of a process.
*/
USERMAIN( init ) {
   174e2:	55                   	push   %ebp
   174e3:	89 e5                	mov    %esp,%ebp
   174e5:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   174eb:	8b 45 0c             	mov    0xc(%ebp),%eax
   174ee:	8b 00                	mov    (%eax),%eax
   174f0:	85 c0                	test   %eax,%eax
   174f2:	74 07                	je     174fb <init+0x19>
   174f4:	8b 45 0c             	mov    0xc(%ebp),%eax
   174f7:	8b 00                	mov    (%eax),%eax
   174f9:	eb 05                	jmp    17500 <init+0x1e>
   174fb:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   17500:	89 45 e8             	mov    %eax,-0x18(%ebp)
	char buf[128];

	// check to see if we got a non-standard "spawn" character
	if( argc > 1 ) {
   17503:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
   17507:	7e 2d                	jle    17536 <init+0x54>
		// maybe - check it to be sure it's printable
		uint_t i = argv[1][0];
   17509:	8b 45 0c             	mov    0xc(%ebp),%eax
   1750c:	83 c0 04             	add    $0x4,%eax
   1750f:	8b 00                	mov    (%eax),%eax
   17511:	0f b6 00             	movzbl (%eax),%eax
   17514:	0f be c0             	movsbl %al,%eax
   17517:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		if( i > ' ' && i < 0x7f ) {
   1751a:	83 7d e4 20          	cmpl   $0x20,-0x1c(%ebp)
   1751e:	76 16                	jbe    17536 <init+0x54>
   17520:	83 7d e4 7e          	cmpl   $0x7e,-0x1c(%ebp)
   17524:	77 10                	ja     17536 <init+0x54>
			ch = argv[1][0];
   17526:	8b 45 0c             	mov    0xc(%ebp),%eax
   17529:	83 c0 04             	add    $0x4,%eax
   1752c:	8b 00                	mov    (%eax),%eax
   1752e:	0f b6 00             	movzbl (%eax),%eax
   17531:	a2 3c d6 01 00       	mov    %al,0x1d63c
		}
	}

	// test the sio
	write( CHAN_SIO, "$+$\n", 4 );
   17536:	83 ec 04             	sub    $0x4,%esp
   17539:	6a 04                	push   $0x4
   1753b:	68 9c bd 01 00       	push   $0x1bd9c
   17540:	6a 01                	push   $0x1
   17542:	e8 09 fa ff ff       	call   16f50 <write>
   17547:	83 c4 10             	add    $0x10,%esp
	DELAY(SHORT);
   1754a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   17551:	eb 04                	jmp    17557 <init+0x75>
   17553:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   17557:	81 7d f4 9f 25 26 00 	cmpl   $0x26259f,-0xc(%ebp)
   1755e:	7e f3                	jle    17553 <init+0x71>

	usprint( buf, "%s: started\n", name );
   17560:	83 ec 04             	sub    $0x4,%esp
   17563:	ff 75 e8             	pushl  -0x18(%ebp)
   17566:	68 a1 bd 01 00       	push   $0x1bda1
   1756b:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17571:	50                   	push   %eax
   17572:	e8 5b 27 00 00       	call   19cd2 <usprint>
   17577:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   1757a:	83 ec 0c             	sub    $0xc,%esp
   1757d:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17583:	50                   	push   %eax
   17584:	e8 36 2e 00 00       	call   1a3bf <cwrites>
   17589:	83 c4 10             	add    $0x10,%esp

	// home up, clear on a TVI 925
	// swritech( '\x1a' );

	// wait a bit
	DELAY(SHORT);
   1758c:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   17593:	eb 04                	jmp    17599 <init+0xb7>
   17595:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   17599:	81 7d f0 9f 25 26 00 	cmpl   $0x26259f,-0x10(%ebp)
   175a0:	7e f3                	jle    17595 <init+0xb3>

	// a bit of Dante to set the mood :-)
	swrites( "\n\nSpem relinquunt qui huc intrasti!\n\n\r" );
   175a2:	83 ec 0c             	sub    $0xc,%esp
   175a5:	68 b0 bd 01 00       	push   $0x1bdb0
   175aa:	e8 76 2e 00 00       	call   1a425 <swrites>
   175af:	83 c4 10             	add    $0x10,%esp

	/*
	** Start all the user processes
	*/

	usprint( buf, "%s: starting user processes\n", name );
   175b2:	83 ec 04             	sub    $0x4,%esp
   175b5:	ff 75 e8             	pushl  -0x18(%ebp)
   175b8:	68 d7 bd 01 00       	push   $0x1bdd7
   175bd:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   175c3:	50                   	push   %eax
   175c4:	e8 09 27 00 00       	call   19cd2 <usprint>
   175c9:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   175cc:	83 ec 0c             	sub    $0xc,%esp
   175cf:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   175d5:	50                   	push   %eax
   175d6:	e8 e4 2d 00 00       	call   1a3bf <cwrites>
   175db:	83 c4 10             	add    $0x10,%esp

	proc_t *next;
	for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
   175de:	c7 45 ec a0 d5 01 00 	movl   $0x1d5a0,-0x14(%ebp)
   175e5:	eb 12                	jmp    175f9 <init+0x117>
		process( next );
   175e7:	83 ec 0c             	sub    $0xc,%esp
   175ea:	ff 75 ec             	pushl  -0x14(%ebp)
   175ed:	e8 1e fe ff ff       	call   17410 <process>
   175f2:	83 c4 10             	add    $0x10,%esp
	for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
   175f5:	83 45 ec 34          	addl   $0x34,-0x14(%ebp)
   175f9:	8b 45 ec             	mov    -0x14(%ebp),%eax
   175fc:	8b 00                	mov    (%eax),%eax
   175fe:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   17603:	75 e2                	jne    175e7 <init+0x105>
	}

	swrites( " !!!\r\n\n" );
   17605:	83 ec 0c             	sub    $0xc,%esp
   17608:	68 f4 bd 01 00       	push   $0x1bdf4
   1760d:	e8 13 2e 00 00       	call   1a425 <swrites>
   17612:	83 c4 10             	add    $0x10,%esp
	/*
	** At this point, we go into an infinite loop waiting
	** for our children (direct, or inherited) to exit.
	*/

	usprint( buf, "%s: transitioning to wait() mode\n", name );
   17615:	83 ec 04             	sub    $0x4,%esp
   17618:	ff 75 e8             	pushl  -0x18(%ebp)
   1761b:	68 fc bd 01 00       	push   $0x1bdfc
   17620:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17626:	50                   	push   %eax
   17627:	e8 a6 26 00 00       	call   19cd2 <usprint>
   1762c:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   1762f:	83 ec 0c             	sub    $0xc,%esp
   17632:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17638:	50                   	push   %eax
   17639:	e8 81 2d 00 00       	call   1a3bf <cwrites>
   1763e:	83 c4 10             	add    $0x10,%esp

	for(;;) {
		int32_t status;
		int whom = waitpid( 0, &status );
   17641:	83 ec 08             	sub    $0x8,%esp
   17644:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1764a:	50                   	push   %eax
   1764b:	6a 00                	push   $0x0
   1764d:	e8 de f8 ff ff       	call   16f30 <waitpid>
   17652:	83 c4 10             	add    $0x10,%esp
   17655:	89 45 e0             	mov    %eax,-0x20(%ebp)

		// PIDs must be positive numbers!
		if( whom <= 0 ) {
   17658:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   1765c:	7f 2e                	jg     1768c <init+0x1aa>

			usprint( buf, "%s: waitpid() returned %d???\n", name, whom );
   1765e:	ff 75 e0             	pushl  -0x20(%ebp)
   17661:	ff 75 e8             	pushl  -0x18(%ebp)
   17664:	68 1e be 01 00       	push   $0x1be1e
   17669:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   1766f:	50                   	push   %eax
   17670:	e8 5d 26 00 00       	call   19cd2 <usprint>
   17675:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17678:	83 ec 0c             	sub    $0xc,%esp
   1767b:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17681:	50                   	push   %eax
   17682:	e8 38 2d 00 00       	call   1a3bf <cwrites>
   17687:	83 c4 10             	add    $0x10,%esp
   1768a:	eb b5                	jmp    17641 <init+0x15f>

		} else {

			// got one; report it
			usprint( buf, "%s: pid %d exit(%d)\n", name, whom, status );
   1768c:	8b 85 5c ff ff ff    	mov    -0xa4(%ebp),%eax
   17692:	83 ec 0c             	sub    $0xc,%esp
   17695:	50                   	push   %eax
   17696:	ff 75 e0             	pushl  -0x20(%ebp)
   17699:	ff 75 e8             	pushl  -0x18(%ebp)
   1769c:	68 3c be 01 00       	push   $0x1be3c
   176a1:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   176a7:	50                   	push   %eax
   176a8:	e8 25 26 00 00       	call   19cd2 <usprint>
   176ad:	83 c4 20             	add    $0x20,%esp
			cwrites( buf );
   176b0:	83 ec 0c             	sub    $0xc,%esp
   176b3:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   176b9:	50                   	push   %eax
   176ba:	e8 00 2d 00 00       	call   1a3bf <cwrites>
   176bf:	83 c4 10             	add    $0x10,%esp

			// figure out if this is one of ours
			for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
   176c2:	c7 45 ec a0 d5 01 00 	movl   $0x1d5a0,-0x14(%ebp)
   176c9:	eb 2b                	jmp    176f6 <init+0x214>
				if( next->pid == whom ) {
   176cb:	8b 45 ec             	mov    -0x14(%ebp),%eax
   176ce:	8b 50 04             	mov    0x4(%eax),%edx
   176d1:	8b 45 e0             	mov    -0x20(%ebp),%eax
   176d4:	39 c2                	cmp    %eax,%edx
   176d6:	75 1a                	jne    176f2 <init+0x210>
					// one of ours - reset the PID field
					// (in case the spawn attempt fails)
					next->pid = 0;
   176d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
   176db:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
					// and restart it
					process( next );
   176e2:	83 ec 0c             	sub    $0xc,%esp
   176e5:	ff 75 ec             	pushl  -0x14(%ebp)
   176e8:	e8 23 fd ff ff       	call   17410 <process>
   176ed:	83 c4 10             	add    $0x10,%esp
					break;
   176f0:	eb 10                	jmp    17702 <init+0x220>
			for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
   176f2:	83 45 ec 34          	addl   $0x34,-0x14(%ebp)
   176f6:	8b 45 ec             	mov    -0x14(%ebp),%eax
   176f9:	8b 00                	mov    (%eax),%eax
   176fb:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   17700:	75 c9                	jne    176cb <init+0x1e9>
	for(;;) {
   17702:	e9 3a ff ff ff       	jmp    17641 <init+0x15f>

00017707 <progABC>:
** Invoked as:  progABC  x  n
**	 where x is the ID character
**		   n is the iteration count
*/

USERMAIN( progABC ) {
   17707:	55                   	push   %ebp
   17708:	89 e5                	mov    %esp,%ebp
   1770a:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   17710:	8b 45 0c             	mov    0xc(%ebp),%eax
   17713:	8b 00                	mov    (%eax),%eax
   17715:	85 c0                	test   %eax,%eax
   17717:	74 07                	je     17720 <progABC+0x19>
   17719:	8b 45 0c             	mov    0xc(%ebp),%eax
   1771c:	8b 00                	mov    (%eax),%eax
   1771e:	eb 05                	jmp    17725 <progABC+0x1e>
   17720:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   17725:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 30; // default iteration count
   17728:	c7 45 f4 1e 00 00 00 	movl   $0x1e,-0xc(%ebp)
	char ch = '1';	// default character to print
   1772f:	c6 45 f3 31          	movb   $0x31,-0xd(%ebp)
	char buf[128];	// local char buffer

	// process the command-line arguments
	switch( argc ) {
   17733:	8b 45 08             	mov    0x8(%ebp),%eax
   17736:	83 f8 02             	cmp    $0x2,%eax
   17739:	74 1e                	je     17759 <progABC+0x52>
   1773b:	83 f8 03             	cmp    $0x3,%eax
   1773e:	75 2c                	jne    1776c <progABC+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   17740:	8b 45 0c             	mov    0xc(%ebp),%eax
   17743:	83 c0 08             	add    $0x8,%eax
   17746:	8b 00                	mov    (%eax),%eax
   17748:	83 ec 08             	sub    $0x8,%esp
   1774b:	6a 0a                	push   $0xa
   1774d:	50                   	push   %eax
   1774e:	e8 f4 27 00 00       	call   19f47 <ustr2int>
   17753:	83 c4 10             	add    $0x10,%esp
   17756:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17759:	8b 45 0c             	mov    0xc(%ebp),%eax
   1775c:	83 c0 04             	add    $0x4,%eax
   1775f:	8b 00                	mov    (%eax),%eax
   17761:	0f b6 00             	movzbl (%eax),%eax
   17764:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   17767:	e9 a8 00 00 00       	jmp    17814 <progABC+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   1776c:	ff 75 08             	pushl  0x8(%ebp)
   1776f:	ff 75 e0             	pushl  -0x20(%ebp)
   17772:	68 51 be 01 00       	push   $0x1be51
   17777:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1777d:	50                   	push   %eax
   1777e:	e8 4f 25 00 00       	call   19cd2 <usprint>
   17783:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17786:	83 ec 0c             	sub    $0xc,%esp
   17789:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1778f:	50                   	push   %eax
   17790:	e8 2a 2c 00 00       	call   1a3bf <cwrites>
   17795:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17798:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   1779f:	eb 5b                	jmp    177fc <progABC+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   177a1:	8b 45 08             	mov    0x8(%ebp),%eax
   177a4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   177ab:	8b 45 0c             	mov    0xc(%ebp),%eax
   177ae:	01 d0                	add    %edx,%eax
   177b0:	8b 00                	mov    (%eax),%eax
   177b2:	85 c0                	test   %eax,%eax
   177b4:	74 13                	je     177c9 <progABC+0xc2>
   177b6:	8b 45 08             	mov    0x8(%ebp),%eax
   177b9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   177c0:	8b 45 0c             	mov    0xc(%ebp),%eax
   177c3:	01 d0                	add    %edx,%eax
   177c5:	8b 00                	mov    (%eax),%eax
   177c7:	eb 05                	jmp    177ce <progABC+0xc7>
   177c9:	b8 65 be 01 00       	mov    $0x1be65,%eax
   177ce:	83 ec 04             	sub    $0x4,%esp
   177d1:	50                   	push   %eax
   177d2:	68 6c be 01 00       	push   $0x1be6c
   177d7:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   177dd:	50                   	push   %eax
   177de:	e8 ef 24 00 00       	call   19cd2 <usprint>
   177e3:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   177e6:	83 ec 0c             	sub    $0xc,%esp
   177e9:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   177ef:	50                   	push   %eax
   177f0:	e8 ca 2b 00 00       	call   1a3bf <cwrites>
   177f5:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   177f8:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   177fc:	8b 45 ec             	mov    -0x14(%ebp),%eax
   177ff:	3b 45 08             	cmp    0x8(%ebp),%eax
   17802:	7e 9d                	jle    177a1 <progABC+0x9a>
			}
			cwrites( "\n" );
   17804:	83 ec 0c             	sub    $0xc,%esp
   17807:	68 70 be 01 00       	push   $0x1be70
   1780c:	e8 ae 2b 00 00       	call   1a3bf <cwrites>
   17811:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int n = swritech( ch );
   17814:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17818:	83 ec 0c             	sub    $0xc,%esp
   1781b:	50                   	push   %eax
   1781c:	e8 e3 2b 00 00       	call   1a404 <swritech>
   17821:	83 c4 10             	add    $0x10,%esp
   17824:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if( n != 1 ) {
   17827:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   1782b:	74 2e                	je     1785b <progABC+0x154>
		usprint( buf, "== %c, write #1 returned %d\n", ch, n );
   1782d:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17831:	ff 75 dc             	pushl  -0x24(%ebp)
   17834:	50                   	push   %eax
   17835:	68 72 be 01 00       	push   $0x1be72
   1783a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17840:	50                   	push   %eax
   17841:	e8 8c 24 00 00       	call   19cd2 <usprint>
   17846:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   17849:	83 ec 0c             	sub    $0xc,%esp
   1784c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17852:	50                   	push   %eax
   17853:	e8 67 2b 00 00       	call   1a3bf <cwrites>
   17858:	83 c4 10             	add    $0x10,%esp
	}

	// iterate and print the required number of other characters
	for( int i = 0; i < count; ++i ) {
   1785b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   17862:	eb 61                	jmp    178c5 <progABC+0x1be>
		DELAY(STD);
   17864:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   1786b:	eb 04                	jmp    17871 <progABC+0x16a>
   1786d:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   17871:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   17878:	7e f3                	jle    1786d <progABC+0x166>
		n = swritech( ch );
   1787a:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   1787e:	83 ec 0c             	sub    $0xc,%esp
   17881:	50                   	push   %eax
   17882:	e8 7d 2b 00 00       	call   1a404 <swritech>
   17887:	83 c4 10             	add    $0x10,%esp
   1788a:	89 45 dc             	mov    %eax,-0x24(%ebp)
		if( n != 1 ) {
   1788d:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   17891:	74 2e                	je     178c1 <progABC+0x1ba>
			usprint( buf, "== %c, write #2 returned %d\n", ch, n );
   17893:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17897:	ff 75 dc             	pushl  -0x24(%ebp)
   1789a:	50                   	push   %eax
   1789b:	68 8f be 01 00       	push   $0x1be8f
   178a0:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   178a6:	50                   	push   %eax
   178a7:	e8 26 24 00 00       	call   19cd2 <usprint>
   178ac:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   178af:	83 ec 0c             	sub    $0xc,%esp
   178b2:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   178b8:	50                   	push   %eax
   178b9:	e8 01 2b 00 00       	call   1a3bf <cwrites>
   178be:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   178c1:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   178c5:	8b 45 e8             	mov    -0x18(%ebp),%eax
   178c8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   178cb:	7c 97                	jl     17864 <progABC+0x15d>
		}
	}

	// all done!
	exit( 0 );
   178cd:	83 ec 0c             	sub    $0xc,%esp
   178d0:	6a 00                	push   $0x0
   178d2:	e8 51 f6 ff ff       	call   16f28 <exit>
   178d7:	83 c4 10             	add    $0x10,%esp

	// should never reach this code; if we do, something is
	// wrong with exit(), so we'll report it

	char msg[] = "*1*";
   178da:	c7 85 58 ff ff ff 2a 	movl   $0x2a312a,-0xa8(%ebp)
   178e1:	31 2a 00 
	msg[1] = ch;
   178e4:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   178e8:	88 85 59 ff ff ff    	mov    %al,-0xa7(%ebp)
	n = write( CHAN_SIO, msg, 3 );	  /* shouldn't happen! */
   178ee:	83 ec 04             	sub    $0x4,%esp
   178f1:	6a 03                	push   $0x3
   178f3:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   178f9:	50                   	push   %eax
   178fa:	6a 01                	push   $0x1
   178fc:	e8 4f f6 ff ff       	call   16f50 <write>
   17901:	83 c4 10             	add    $0x10,%esp
   17904:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if( n != 3 ) {
   17907:	83 7d dc 03          	cmpl   $0x3,-0x24(%ebp)
   1790b:	74 2e                	je     1793b <progABC+0x234>
		usprint( buf, "User %c, write #3 returned %d\n", ch, n );
   1790d:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17911:	ff 75 dc             	pushl  -0x24(%ebp)
   17914:	50                   	push   %eax
   17915:	68 ac be 01 00       	push   $0x1beac
   1791a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17920:	50                   	push   %eax
   17921:	e8 ac 23 00 00       	call   19cd2 <usprint>
   17926:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   17929:	83 ec 0c             	sub    $0xc,%esp
   1792c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17932:	50                   	push   %eax
   17933:	e8 87 2a 00 00       	call   1a3bf <cwrites>
   17938:	83 c4 10             	add    $0x10,%esp
	}

	// this should really get us out of here
	return( 42 );
   1793b:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   17940:	c9                   	leave  
   17941:	c3                   	ret    

00017942 <progDE>:
** Invoked as:  progDE  x  n
**	 where x is the ID character
**		   n is the iteration count
*/

USERMAIN( progDE ) {
   17942:	55                   	push   %ebp
   17943:	89 e5                	mov    %esp,%ebp
   17945:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   1794b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1794e:	8b 00                	mov    (%eax),%eax
   17950:	85 c0                	test   %eax,%eax
   17952:	74 07                	je     1795b <progDE+0x19>
   17954:	8b 45 0c             	mov    0xc(%ebp),%eax
   17957:	8b 00                	mov    (%eax),%eax
   17959:	eb 05                	jmp    17960 <progDE+0x1e>
   1795b:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   17960:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int n;
	int count = 30;	  // default iteration count
   17963:	c7 45 f4 1e 00 00 00 	movl   $0x1e,-0xc(%ebp)
	char ch = '2';	  // default character to print
   1796a:	c6 45 f3 32          	movb   $0x32,-0xd(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   1796e:	8b 45 08             	mov    0x8(%ebp),%eax
   17971:	83 f8 02             	cmp    $0x2,%eax
   17974:	74 1e                	je     17994 <progDE+0x52>
   17976:	83 f8 03             	cmp    $0x3,%eax
   17979:	75 2c                	jne    179a7 <progDE+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   1797b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1797e:	83 c0 08             	add    $0x8,%eax
   17981:	8b 00                	mov    (%eax),%eax
   17983:	83 ec 08             	sub    $0x8,%esp
   17986:	6a 0a                	push   $0xa
   17988:	50                   	push   %eax
   17989:	e8 b9 25 00 00       	call   19f47 <ustr2int>
   1798e:	83 c4 10             	add    $0x10,%esp
   17991:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17994:	8b 45 0c             	mov    0xc(%ebp),%eax
   17997:	83 c0 04             	add    $0x4,%eax
   1799a:	8b 00                	mov    (%eax),%eax
   1799c:	0f b6 00             	movzbl (%eax),%eax
   1799f:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   179a2:	e9 a8 00 00 00       	jmp    17a4f <progDE+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   179a7:	ff 75 08             	pushl  0x8(%ebp)
   179aa:	ff 75 e0             	pushl  -0x20(%ebp)
   179ad:	68 51 be 01 00       	push   $0x1be51
   179b2:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   179b8:	50                   	push   %eax
   179b9:	e8 14 23 00 00       	call   19cd2 <usprint>
   179be:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   179c1:	83 ec 0c             	sub    $0xc,%esp
   179c4:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   179ca:	50                   	push   %eax
   179cb:	e8 ef 29 00 00       	call   1a3bf <cwrites>
   179d0:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   179d3:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   179da:	eb 5b                	jmp    17a37 <progDE+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   179dc:	8b 45 08             	mov    0x8(%ebp),%eax
   179df:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   179e6:	8b 45 0c             	mov    0xc(%ebp),%eax
   179e9:	01 d0                	add    %edx,%eax
   179eb:	8b 00                	mov    (%eax),%eax
   179ed:	85 c0                	test   %eax,%eax
   179ef:	74 13                	je     17a04 <progDE+0xc2>
   179f1:	8b 45 08             	mov    0x8(%ebp),%eax
   179f4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   179fb:	8b 45 0c             	mov    0xc(%ebp),%eax
   179fe:	01 d0                	add    %edx,%eax
   17a00:	8b 00                	mov    (%eax),%eax
   17a02:	eb 05                	jmp    17a09 <progDE+0xc7>
   17a04:	b8 65 be 01 00       	mov    $0x1be65,%eax
   17a09:	83 ec 04             	sub    $0x4,%esp
   17a0c:	50                   	push   %eax
   17a0d:	68 6c be 01 00       	push   $0x1be6c
   17a12:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17a18:	50                   	push   %eax
   17a19:	e8 b4 22 00 00       	call   19cd2 <usprint>
   17a1e:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17a21:	83 ec 0c             	sub    $0xc,%esp
   17a24:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17a2a:	50                   	push   %eax
   17a2b:	e8 8f 29 00 00       	call   1a3bf <cwrites>
   17a30:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17a33:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   17a37:	8b 45 ec             	mov    -0x14(%ebp),%eax
   17a3a:	3b 45 08             	cmp    0x8(%ebp),%eax
   17a3d:	7e 9d                	jle    179dc <progDE+0x9a>
			}
			cwrites( "\n" );
   17a3f:	83 ec 0c             	sub    $0xc,%esp
   17a42:	68 70 be 01 00       	push   $0x1be70
   17a47:	e8 73 29 00 00       	call   1a3bf <cwrites>
   17a4c:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	n = swritech( ch );
   17a4f:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17a53:	83 ec 0c             	sub    $0xc,%esp
   17a56:	50                   	push   %eax
   17a57:	e8 a8 29 00 00       	call   1a404 <swritech>
   17a5c:	83 c4 10             	add    $0x10,%esp
   17a5f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if( n != 1 ) {
   17a62:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   17a66:	74 2e                	je     17a96 <progDE+0x154>
		usprint( buf, "== %c, write #1 returned %d\n", ch, n );
   17a68:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17a6c:	ff 75 dc             	pushl  -0x24(%ebp)
   17a6f:	50                   	push   %eax
   17a70:	68 72 be 01 00       	push   $0x1be72
   17a75:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17a7b:	50                   	push   %eax
   17a7c:	e8 51 22 00 00       	call   19cd2 <usprint>
   17a81:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   17a84:	83 ec 0c             	sub    $0xc,%esp
   17a87:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17a8d:	50                   	push   %eax
   17a8e:	e8 2c 29 00 00       	call   1a3bf <cwrites>
   17a93:	83 c4 10             	add    $0x10,%esp
	}

	// iterate and print the required number of other characters
	for( int i = 0; i < count; ++i ) {
   17a96:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   17a9d:	eb 61                	jmp    17b00 <progDE+0x1be>
		DELAY(STD);
   17a9f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   17aa6:	eb 04                	jmp    17aac <progDE+0x16a>
   17aa8:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   17aac:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   17ab3:	7e f3                	jle    17aa8 <progDE+0x166>
		n = swritech( ch );
   17ab5:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17ab9:	83 ec 0c             	sub    $0xc,%esp
   17abc:	50                   	push   %eax
   17abd:	e8 42 29 00 00       	call   1a404 <swritech>
   17ac2:	83 c4 10             	add    $0x10,%esp
   17ac5:	89 45 dc             	mov    %eax,-0x24(%ebp)
		if( n != 1 ) {
   17ac8:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   17acc:	74 2e                	je     17afc <progDE+0x1ba>
			usprint( buf, "== %c, write #2 returned %d\n", ch, n );
   17ace:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17ad2:	ff 75 dc             	pushl  -0x24(%ebp)
   17ad5:	50                   	push   %eax
   17ad6:	68 8f be 01 00       	push   $0x1be8f
   17adb:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17ae1:	50                   	push   %eax
   17ae2:	e8 eb 21 00 00       	call   19cd2 <usprint>
   17ae7:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17aea:	83 ec 0c             	sub    $0xc,%esp
   17aed:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17af3:	50                   	push   %eax
   17af4:	e8 c6 28 00 00       	call   1a3bf <cwrites>
   17af9:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   17afc:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   17b00:	8b 45 e8             	mov    -0x18(%ebp),%eax
   17b03:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   17b06:	7c 97                	jl     17a9f <progDE+0x15d>
		}
	}

	// all done!
	return( 0 );
   17b08:	b8 00 00 00 00       	mov    $0x0,%eax
}
   17b0d:	c9                   	leave  
   17b0e:	c3                   	ret    

00017b0f <progFG>:
**	 where x is the ID character
**		   n is the iteration count
**		   s is the sleep time in seconds
*/

USERMAIN( progFG ) {
   17b0f:	55                   	push   %ebp
   17b10:	89 e5                	mov    %esp,%ebp
   17b12:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   17b18:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b1b:	8b 00                	mov    (%eax),%eax
   17b1d:	85 c0                	test   %eax,%eax
   17b1f:	74 07                	je     17b28 <progFG+0x19>
   17b21:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b24:	8b 00                	mov    (%eax),%eax
   17b26:	eb 05                	jmp    17b2d <progFG+0x1e>
   17b28:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   17b2d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	char ch = '3';	// default character to print
   17b30:	c6 45 df 33          	movb   $0x33,-0x21(%ebp)
	int nap = 10;	// default sleep time
   17b34:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
	int count = 30;	// iteration count
   17b3b:	c7 45 f0 1e 00 00 00 	movl   $0x1e,-0x10(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   17b42:	8b 45 08             	mov    0x8(%ebp),%eax
   17b45:	83 f8 03             	cmp    $0x3,%eax
   17b48:	74 25                	je     17b6f <progFG+0x60>
   17b4a:	83 f8 04             	cmp    $0x4,%eax
   17b4d:	74 07                	je     17b56 <progFG+0x47>
   17b4f:	83 f8 02             	cmp    $0x2,%eax
   17b52:	74 34                	je     17b88 <progFG+0x79>
   17b54:	eb 45                	jmp    17b9b <progFG+0x8c>
	case 4:	nap = ustr2int( argv[3], 10 );
   17b56:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b59:	83 c0 0c             	add    $0xc,%eax
   17b5c:	8b 00                	mov    (%eax),%eax
   17b5e:	83 ec 08             	sub    $0x8,%esp
   17b61:	6a 0a                	push   $0xa
   17b63:	50                   	push   %eax
   17b64:	e8 de 23 00 00       	call   19f47 <ustr2int>
   17b69:	83 c4 10             	add    $0x10,%esp
   17b6c:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   17b6f:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b72:	83 c0 08             	add    $0x8,%eax
   17b75:	8b 00                	mov    (%eax),%eax
   17b77:	83 ec 08             	sub    $0x8,%esp
   17b7a:	6a 0a                	push   $0xa
   17b7c:	50                   	push   %eax
   17b7d:	e8 c5 23 00 00       	call   19f47 <ustr2int>
   17b82:	83 c4 10             	add    $0x10,%esp
   17b85:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17b88:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b8b:	83 c0 04             	add    $0x4,%eax
   17b8e:	8b 00                	mov    (%eax),%eax
   17b90:	0f b6 00             	movzbl (%eax),%eax
   17b93:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   17b96:	e9 a8 00 00 00       	jmp    17c43 <progFG+0x134>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   17b9b:	ff 75 08             	pushl  0x8(%ebp)
   17b9e:	ff 75 e4             	pushl  -0x1c(%ebp)
   17ba1:	68 51 be 01 00       	push   $0x1be51
   17ba6:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17bac:	50                   	push   %eax
   17bad:	e8 20 21 00 00       	call   19cd2 <usprint>
   17bb2:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17bb5:	83 ec 0c             	sub    $0xc,%esp
   17bb8:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17bbe:	50                   	push   %eax
   17bbf:	e8 fb 27 00 00       	call   1a3bf <cwrites>
   17bc4:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17bc7:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   17bce:	eb 5b                	jmp    17c2b <progFG+0x11c>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   17bd0:	8b 45 08             	mov    0x8(%ebp),%eax
   17bd3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17bda:	8b 45 0c             	mov    0xc(%ebp),%eax
   17bdd:	01 d0                	add    %edx,%eax
   17bdf:	8b 00                	mov    (%eax),%eax
   17be1:	85 c0                	test   %eax,%eax
   17be3:	74 13                	je     17bf8 <progFG+0xe9>
   17be5:	8b 45 08             	mov    0x8(%ebp),%eax
   17be8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17bef:	8b 45 0c             	mov    0xc(%ebp),%eax
   17bf2:	01 d0                	add    %edx,%eax
   17bf4:	8b 00                	mov    (%eax),%eax
   17bf6:	eb 05                	jmp    17bfd <progFG+0xee>
   17bf8:	b8 65 be 01 00       	mov    $0x1be65,%eax
   17bfd:	83 ec 04             	sub    $0x4,%esp
   17c00:	50                   	push   %eax
   17c01:	68 6c be 01 00       	push   $0x1be6c
   17c06:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17c0c:	50                   	push   %eax
   17c0d:	e8 c0 20 00 00       	call   19cd2 <usprint>
   17c12:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17c15:	83 ec 0c             	sub    $0xc,%esp
   17c18:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17c1e:	50                   	push   %eax
   17c1f:	e8 9b 27 00 00       	call   1a3bf <cwrites>
   17c24:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17c27:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   17c2b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   17c2e:	3b 45 08             	cmp    0x8(%ebp),%eax
   17c31:	7e 9d                	jle    17bd0 <progFG+0xc1>
			}
			cwrites( "\n" );
   17c33:	83 ec 0c             	sub    $0xc,%esp
   17c36:	68 70 be 01 00       	push   $0x1be70
   17c3b:	e8 7f 27 00 00       	call   1a3bf <cwrites>
   17c40:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int n = swritech( ch );
   17c43:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
   17c47:	0f be c0             	movsbl %al,%eax
   17c4a:	83 ec 0c             	sub    $0xc,%esp
   17c4d:	50                   	push   %eax
   17c4e:	e8 b1 27 00 00       	call   1a404 <swritech>
   17c53:	83 c4 10             	add    $0x10,%esp
   17c56:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if( n != 1 ) {
   17c59:	83 7d e0 01          	cmpl   $0x1,-0x20(%ebp)
   17c5d:	74 31                	je     17c90 <progFG+0x181>
		usprint( buf, "=== %c, write #1 returned %d\n", ch, n );
   17c5f:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
   17c63:	0f be c0             	movsbl %al,%eax
   17c66:	ff 75 e0             	pushl  -0x20(%ebp)
   17c69:	50                   	push   %eax
   17c6a:	68 cb be 01 00       	push   $0x1becb
   17c6f:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17c75:	50                   	push   %eax
   17c76:	e8 57 20 00 00       	call   19cd2 <usprint>
   17c7b:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   17c7e:	83 ec 0c             	sub    $0xc,%esp
   17c81:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17c87:	50                   	push   %eax
   17c88:	e8 32 27 00 00       	call   1a3bf <cwrites>
   17c8d:	83 c4 10             	add    $0x10,%esp
	}

	write( CHAN_SIO, &ch, 1 );
   17c90:	83 ec 04             	sub    $0x4,%esp
   17c93:	6a 01                	push   $0x1
   17c95:	8d 45 df             	lea    -0x21(%ebp),%eax
   17c98:	50                   	push   %eax
   17c99:	6a 01                	push   $0x1
   17c9b:	e8 b0 f2 ff ff       	call   16f50 <write>
   17ca0:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   17ca3:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   17caa:	eb 2c                	jmp    17cd8 <progFG+0x1c9>
		sleep( SEC_TO_MS(nap) );
   17cac:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17caf:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   17cb5:	83 ec 0c             	sub    $0xc,%esp
   17cb8:	50                   	push   %eax
   17cb9:	e8 ca f2 ff ff       	call   16f88 <sleep>
   17cbe:	83 c4 10             	add    $0x10,%esp
		write( CHAN_SIO, &ch, 1 );
   17cc1:	83 ec 04             	sub    $0x4,%esp
   17cc4:	6a 01                	push   $0x1
   17cc6:	8d 45 df             	lea    -0x21(%ebp),%eax
   17cc9:	50                   	push   %eax
   17cca:	6a 01                	push   $0x1
   17ccc:	e8 7f f2 ff ff       	call   16f50 <write>
   17cd1:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   17cd4:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   17cd8:	8b 45 e8             	mov    -0x18(%ebp),%eax
   17cdb:	3b 45 f0             	cmp    -0x10(%ebp),%eax
   17cde:	7c cc                	jl     17cac <progFG+0x19d>
	}

	exit( 0 );
   17ce0:	83 ec 0c             	sub    $0xc,%esp
   17ce3:	6a 00                	push   $0x0
   17ce5:	e8 3e f2 ff ff       	call   16f28 <exit>
   17cea:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   17ced:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   17cf2:	c9                   	leave  
   17cf3:	c3                   	ret    

00017cf4 <progH>:
** Invoked as:  progH  x  n
**	 where x is the ID character
**		   n is the number of children to spawn
*/

USERMAIN( progH ) {
   17cf4:	55                   	push   %ebp
   17cf5:	89 e5                	mov    %esp,%ebp
   17cf7:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   17cfd:	8b 45 0c             	mov    0xc(%ebp),%eax
   17d00:	8b 00                	mov    (%eax),%eax
   17d02:	85 c0                	test   %eax,%eax
   17d04:	74 07                	je     17d0d <progH+0x19>
   17d06:	8b 45 0c             	mov    0xc(%ebp),%eax
   17d09:	8b 00                	mov    (%eax),%eax
   17d0b:	eb 05                	jmp    17d12 <progH+0x1e>
   17d0d:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   17d12:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int32_t ret = 0;  // return value
   17d15:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	int count = 5;	  // child count
   17d1c:	c7 45 f0 05 00 00 00 	movl   $0x5,-0x10(%ebp)
	char ch = 'h';	  // default character to print
   17d23:	c6 45 ef 68          	movb   $0x68,-0x11(%ebp)
	char buf[128];
	int whom;

	// process the argument(s)
	switch( argc ) {
   17d27:	8b 45 08             	mov    0x8(%ebp),%eax
   17d2a:	83 f8 02             	cmp    $0x2,%eax
   17d2d:	74 1e                	je     17d4d <progH+0x59>
   17d2f:	83 f8 03             	cmp    $0x3,%eax
   17d32:	75 2c                	jne    17d60 <progH+0x6c>
	case 3:	count = ustr2int( argv[2], 10 );
   17d34:	8b 45 0c             	mov    0xc(%ebp),%eax
   17d37:	83 c0 08             	add    $0x8,%eax
   17d3a:	8b 00                	mov    (%eax),%eax
   17d3c:	83 ec 08             	sub    $0x8,%esp
   17d3f:	6a 0a                	push   $0xa
   17d41:	50                   	push   %eax
   17d42:	e8 00 22 00 00       	call   19f47 <ustr2int>
   17d47:	83 c4 10             	add    $0x10,%esp
   17d4a:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17d4d:	8b 45 0c             	mov    0xc(%ebp),%eax
   17d50:	83 c0 04             	add    $0x4,%eax
   17d53:	8b 00                	mov    (%eax),%eax
   17d55:	0f b6 00             	movzbl (%eax),%eax
   17d58:	88 45 ef             	mov    %al,-0x11(%ebp)
			break;
   17d5b:	e9 a8 00 00 00       	jmp    17e08 <progH+0x114>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   17d60:	ff 75 08             	pushl  0x8(%ebp)
   17d63:	ff 75 e0             	pushl  -0x20(%ebp)
   17d66:	68 51 be 01 00       	push   $0x1be51
   17d6b:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17d71:	50                   	push   %eax
   17d72:	e8 5b 1f 00 00       	call   19cd2 <usprint>
   17d77:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17d7a:	83 ec 0c             	sub    $0xc,%esp
   17d7d:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17d83:	50                   	push   %eax
   17d84:	e8 36 26 00 00       	call   1a3bf <cwrites>
   17d89:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17d8c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   17d93:	eb 5b                	jmp    17df0 <progH+0xfc>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   17d95:	8b 45 08             	mov    0x8(%ebp),%eax
   17d98:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17d9f:	8b 45 0c             	mov    0xc(%ebp),%eax
   17da2:	01 d0                	add    %edx,%eax
   17da4:	8b 00                	mov    (%eax),%eax
   17da6:	85 c0                	test   %eax,%eax
   17da8:	74 13                	je     17dbd <progH+0xc9>
   17daa:	8b 45 08             	mov    0x8(%ebp),%eax
   17dad:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17db4:	8b 45 0c             	mov    0xc(%ebp),%eax
   17db7:	01 d0                	add    %edx,%eax
   17db9:	8b 00                	mov    (%eax),%eax
   17dbb:	eb 05                	jmp    17dc2 <progH+0xce>
   17dbd:	b8 65 be 01 00       	mov    $0x1be65,%eax
   17dc2:	83 ec 04             	sub    $0x4,%esp
   17dc5:	50                   	push   %eax
   17dc6:	68 6c be 01 00       	push   $0x1be6c
   17dcb:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17dd1:	50                   	push   %eax
   17dd2:	e8 fb 1e 00 00       	call   19cd2 <usprint>
   17dd7:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17dda:	83 ec 0c             	sub    $0xc,%esp
   17ddd:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17de3:	50                   	push   %eax
   17de4:	e8 d6 25 00 00       	call   1a3bf <cwrites>
   17de9:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17dec:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   17df0:	8b 45 e8             	mov    -0x18(%ebp),%eax
   17df3:	3b 45 08             	cmp    0x8(%ebp),%eax
   17df6:	7e 9d                	jle    17d95 <progH+0xa1>
			}
			cwrites( "\n" );
   17df8:	83 ec 0c             	sub    $0xc,%esp
   17dfb:	68 70 be 01 00       	push   $0x1be70
   17e00:	e8 ba 25 00 00       	call   1a3bf <cwrites>
   17e05:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	swritech( ch );
   17e08:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   17e0c:	83 ec 0c             	sub    $0xc,%esp
   17e0f:	50                   	push   %eax
   17e10:	e8 ef 25 00 00       	call   1a404 <swritech>
   17e15:	83 c4 10             	add    $0x10,%esp

	// we spawn user Z and then exit before it can terminate
	// progZ 'Z' 10

	char *argsz[] = { "progZ", "Z", "10", NULL };
   17e18:	c7 85 4c ff ff ff e9 	movl   $0x1bee9,-0xb4(%ebp)
   17e1f:	be 01 00 
   17e22:	c7 85 50 ff ff ff ef 	movl   $0x1beef,-0xb0(%ebp)
   17e29:	be 01 00 
   17e2c:	c7 85 54 ff ff ff c4 	movl   $0x1bbc4,-0xac(%ebp)
   17e33:	bb 01 00 
   17e36:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
   17e3d:	00 00 00 

	for( int i = 0; i < count; ++i ) {
   17e40:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   17e47:	eb 57                	jmp    17ea0 <progH+0x1ac>

		// spawn a child
		whom = spawn( (uint32_t) progZ, argsz );
   17e49:	ba da 7e 01 00       	mov    $0x17eda,%edx
   17e4e:	83 ec 08             	sub    $0x8,%esp
   17e51:	8d 85 4c ff ff ff    	lea    -0xb4(%ebp),%eax
   17e57:	50                   	push   %eax
   17e58:	52                   	push   %edx
   17e59:	e8 cb 24 00 00       	call   1a329 <spawn>
   17e5e:	83 c4 10             	add    $0x10,%esp
   17e61:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// our exit status is the number of failed spawn() calls
		if( whom < 0 ) {
   17e64:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   17e68:	79 32                	jns    17e9c <progH+0x1a8>
			usprint( buf, "!! %c spawn() failed, returned %d\n", ch, whom );
   17e6a:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   17e6e:	ff 75 dc             	pushl  -0x24(%ebp)
   17e71:	50                   	push   %eax
   17e72:	68 f4 be 01 00       	push   $0x1bef4
   17e77:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17e7d:	50                   	push   %eax
   17e7e:	e8 4f 1e 00 00       	call   19cd2 <usprint>
   17e83:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17e86:	83 ec 0c             	sub    $0xc,%esp
   17e89:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17e8f:	50                   	push   %eax
   17e90:	e8 2a 25 00 00       	call   1a3bf <cwrites>
   17e95:	83 c4 10             	add    $0x10,%esp
			ret += 1;
   17e98:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
	for( int i = 0; i < count; ++i ) {
   17e9c:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   17ea0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   17ea3:	3b 45 f0             	cmp    -0x10(%ebp),%eax
   17ea6:	7c a1                	jl     17e49 <progH+0x155>
		}
	}

	// yield the CPU so that our child(ren) can run
	sleep( 0 );
   17ea8:	83 ec 0c             	sub    $0xc,%esp
   17eab:	6a 00                	push   $0x0
   17ead:	e8 d6 f0 ff ff       	call   16f88 <sleep>
   17eb2:	83 c4 10             	add    $0x10,%esp

	// announce our departure
	swritech( ch );
   17eb5:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   17eb9:	83 ec 0c             	sub    $0xc,%esp
   17ebc:	50                   	push   %eax
   17ebd:	e8 42 25 00 00       	call   1a404 <swritech>
   17ec2:	83 c4 10             	add    $0x10,%esp

	exit( ret );
   17ec5:	83 ec 0c             	sub    $0xc,%esp
   17ec8:	ff 75 f4             	pushl  -0xc(%ebp)
   17ecb:	e8 58 f0 ff ff       	call   16f28 <exit>
   17ed0:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   17ed3:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   17ed8:	c9                   	leave  
   17ed9:	c3                   	ret    

00017eda <progZ>:
** Invoked as:	progZ  x  [ n ]
**	 where x is the ID character
**		   n is the iteration count (defaults to 10)
*/

USERMAIN( progZ ) {
   17eda:	55                   	push   %ebp
   17edb:	89 e5                	mov    %esp,%ebp
   17edd:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   17ee3:	8b 45 0c             	mov    0xc(%ebp),%eax
   17ee6:	8b 00                	mov    (%eax),%eax
   17ee8:	85 c0                	test   %eax,%eax
   17eea:	74 07                	je     17ef3 <progZ+0x19>
   17eec:	8b 45 0c             	mov    0xc(%ebp),%eax
   17eef:	8b 00                	mov    (%eax),%eax
   17ef1:	eb 05                	jmp    17ef8 <progZ+0x1e>
   17ef3:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   17ef8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 10;	  // default iteration count
   17efb:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
	char ch = 'z';	  // default character to print
   17f02:	c6 45 f3 7a          	movb   $0x7a,-0xd(%ebp)
	char buf[128];

	(void) name;

	// process the command-line arguments
	switch( argc ) {
   17f06:	8b 45 08             	mov    0x8(%ebp),%eax
   17f09:	83 f8 02             	cmp    $0x2,%eax
   17f0c:	74 1e                	je     17f2c <progZ+0x52>
   17f0e:	83 f8 03             	cmp    $0x3,%eax
   17f11:	75 2c                	jne    17f3f <progZ+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   17f13:	8b 45 0c             	mov    0xc(%ebp),%eax
   17f16:	83 c0 08             	add    $0x8,%eax
   17f19:	8b 00                	mov    (%eax),%eax
   17f1b:	83 ec 08             	sub    $0x8,%esp
   17f1e:	6a 0a                	push   $0xa
   17f20:	50                   	push   %eax
   17f21:	e8 21 20 00 00       	call   19f47 <ustr2int>
   17f26:	83 c4 10             	add    $0x10,%esp
   17f29:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17f2c:	8b 45 0c             	mov    0xc(%ebp),%eax
   17f2f:	83 c0 04             	add    $0x4,%eax
   17f32:	8b 00                	mov    (%eax),%eax
   17f34:	0f b6 00             	movzbl (%eax),%eax
   17f37:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   17f3a:	e9 a8 00 00 00       	jmp    17fe7 <progZ+0x10d>
	default:
			usprint( buf, "?: argc %d, args: ", argc );
   17f3f:	83 ec 04             	sub    $0x4,%esp
   17f42:	ff 75 08             	pushl  0x8(%ebp)
   17f45:	68 17 bf 01 00       	push   $0x1bf17
   17f4a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17f50:	50                   	push   %eax
   17f51:	e8 7c 1d 00 00       	call   19cd2 <usprint>
   17f56:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17f59:	83 ec 0c             	sub    $0xc,%esp
   17f5c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17f62:	50                   	push   %eax
   17f63:	e8 57 24 00 00       	call   1a3bf <cwrites>
   17f68:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17f6b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   17f72:	eb 5b                	jmp    17fcf <progZ+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   17f74:	8b 45 08             	mov    0x8(%ebp),%eax
   17f77:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17f7e:	8b 45 0c             	mov    0xc(%ebp),%eax
   17f81:	01 d0                	add    %edx,%eax
   17f83:	8b 00                	mov    (%eax),%eax
   17f85:	85 c0                	test   %eax,%eax
   17f87:	74 13                	je     17f9c <progZ+0xc2>
   17f89:	8b 45 08             	mov    0x8(%ebp),%eax
   17f8c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17f93:	8b 45 0c             	mov    0xc(%ebp),%eax
   17f96:	01 d0                	add    %edx,%eax
   17f98:	8b 00                	mov    (%eax),%eax
   17f9a:	eb 05                	jmp    17fa1 <progZ+0xc7>
   17f9c:	b8 65 be 01 00       	mov    $0x1be65,%eax
   17fa1:	83 ec 04             	sub    $0x4,%esp
   17fa4:	50                   	push   %eax
   17fa5:	68 6c be 01 00       	push   $0x1be6c
   17faa:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17fb0:	50                   	push   %eax
   17fb1:	e8 1c 1d 00 00       	call   19cd2 <usprint>
   17fb6:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17fb9:	83 ec 0c             	sub    $0xc,%esp
   17fbc:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17fc2:	50                   	push   %eax
   17fc3:	e8 f7 23 00 00       	call   1a3bf <cwrites>
   17fc8:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17fcb:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   17fcf:	8b 45 ec             	mov    -0x14(%ebp),%eax
   17fd2:	3b 45 08             	cmp    0x8(%ebp),%eax
   17fd5:	7e 9d                	jle    17f74 <progZ+0x9a>
			}
			cwrites( "\n" );
   17fd7:	83 ec 0c             	sub    $0xc,%esp
   17fda:	68 70 be 01 00       	push   $0x1be70
   17fdf:	e8 db 23 00 00       	call   1a3bf <cwrites>
   17fe4:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int pid = getpid();
   17fe7:	e8 6c ef ff ff       	call   16f58 <getpid>
   17fec:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d]", ch, pid );
   17fef:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17ff3:	ff 75 dc             	pushl  -0x24(%ebp)
   17ff6:	50                   	push   %eax
   17ff7:	68 2a bf 01 00       	push   $0x1bf2a
   17ffc:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18002:	50                   	push   %eax
   18003:	e8 ca 1c 00 00       	call   19cd2 <usprint>
   18008:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   1800b:	83 ec 0c             	sub    $0xc,%esp
   1800e:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18014:	50                   	push   %eax
   18015:	e8 0b 24 00 00       	call   1a425 <swrites>
   1801a:	83 c4 10             	add    $0x10,%esp

	// iterate for a while; occasionally yield the CPU
	for( int i = 0; i < count ; ++i ) {
   1801d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18024:	eb 5f                	jmp    18085 <progZ+0x1ab>
		usprint( buf, " %c[%d]", ch, i );
   18026:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   1802a:	ff 75 e8             	pushl  -0x18(%ebp)
   1802d:	50                   	push   %eax
   1802e:	68 2a bf 01 00       	push   $0x1bf2a
   18033:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18039:	50                   	push   %eax
   1803a:	e8 93 1c 00 00       	call   19cd2 <usprint>
   1803f:	83 c4 10             	add    $0x10,%esp
		swrites( buf );
   18042:	83 ec 0c             	sub    $0xc,%esp
   18045:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1804b:	50                   	push   %eax
   1804c:	e8 d4 23 00 00       	call   1a425 <swrites>
   18051:	83 c4 10             	add    $0x10,%esp
		DELAY(STD);
   18054:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   1805b:	eb 04                	jmp    18061 <progZ+0x187>
   1805d:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   18061:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   18068:	7e f3                	jle    1805d <progZ+0x183>
		if( i & 1 ) {
   1806a:	8b 45 e8             	mov    -0x18(%ebp),%eax
   1806d:	83 e0 01             	and    $0x1,%eax
   18070:	85 c0                	test   %eax,%eax
   18072:	74 0d                	je     18081 <progZ+0x1a7>
			sleep( 0 );
   18074:	83 ec 0c             	sub    $0xc,%esp
   18077:	6a 00                	push   $0x0
   18079:	e8 0a ef ff ff       	call   16f88 <sleep>
   1807e:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   18081:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18085:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18088:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   1808b:	7c 99                	jl     18026 <progZ+0x14c>
		}
	}

	exit( 0 );
   1808d:	83 ec 0c             	sub    $0xc,%esp
   18090:	6a 00                	push   $0x0
   18092:	e8 91 ee ff ff       	call   16f28 <exit>
   18097:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   1809a:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   1809f:	c9                   	leave  
   180a0:	c3                   	ret    

000180a1 <progI>:
** Invoked as:  progI [ x [ n ] ]
**	 where x is the ID character (defaults to 'i')
**		   n is the number of children to spawn (defaults to 5)
*/

USERMAIN( progI ) {
   180a1:	55                   	push   %ebp
   180a2:	89 e5                	mov    %esp,%ebp
   180a4:	81 ec 98 01 00 00    	sub    $0x198,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   180aa:	8b 45 0c             	mov    0xc(%ebp),%eax
   180ad:	8b 00                	mov    (%eax),%eax
   180af:	85 c0                	test   %eax,%eax
   180b1:	74 07                	je     180ba <progI+0x19>
   180b3:	8b 45 0c             	mov    0xc(%ebp),%eax
   180b6:	8b 00                	mov    (%eax),%eax
   180b8:	eb 05                	jmp    180bf <progI+0x1e>
   180ba:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   180bf:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 5;	  // default child count
   180c2:	c7 45 f4 05 00 00 00 	movl   $0x5,-0xc(%ebp)
	char ch = 'i';	  // default character to print
   180c9:	c6 45 cf 69          	movb   $0x69,-0x31(%ebp)
	int nap = 5;	  // nap time
   180cd:	c7 45 dc 05 00 00 00 	movl   $0x5,-0x24(%ebp)
	char buf[128];
	char ch2[] = "*?*";
   180d4:	c7 85 4b ff ff ff 2a 	movl   $0x2a3f2a,-0xb5(%ebp)
   180db:	3f 2a 00 
	uint_t children[MAX_CHILDREN];
	int nkids = 0;
   180de:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

	// process the command-line arguments
	switch( argc ) {
   180e5:	8b 45 08             	mov    0x8(%ebp),%eax
   180e8:	83 f8 02             	cmp    $0x2,%eax
   180eb:	74 29                	je     18116 <progI+0x75>
   180ed:	83 f8 03             	cmp    $0x3,%eax
   180f0:	74 0b                	je     180fd <progI+0x5c>
   180f2:	83 f8 01             	cmp    $0x1,%eax
   180f5:	0f 84 d8 00 00 00    	je     181d3 <progI+0x132>
   180fb:	eb 2c                	jmp    18129 <progI+0x88>
	case 3:	count = ustr2int( argv[2], 10 );
   180fd:	8b 45 0c             	mov    0xc(%ebp),%eax
   18100:	83 c0 08             	add    $0x8,%eax
   18103:	8b 00                	mov    (%eax),%eax
   18105:	83 ec 08             	sub    $0x8,%esp
   18108:	6a 0a                	push   $0xa
   1810a:	50                   	push   %eax
   1810b:	e8 37 1e 00 00       	call   19f47 <ustr2int>
   18110:	83 c4 10             	add    $0x10,%esp
   18113:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18116:	8b 45 0c             	mov    0xc(%ebp),%eax
   18119:	83 c0 04             	add    $0x4,%eax
   1811c:	8b 00                	mov    (%eax),%eax
   1811e:	0f b6 00             	movzbl (%eax),%eax
   18121:	88 45 cf             	mov    %al,-0x31(%ebp)
			break;
   18124:	e9 ab 00 00 00       	jmp    181d4 <progI+0x133>
	case 1:	// just use the defaults
			break;
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18129:	ff 75 08             	pushl  0x8(%ebp)
   1812c:	ff 75 e0             	pushl  -0x20(%ebp)
   1812f:	68 51 be 01 00       	push   $0x1be51
   18134:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   1813a:	50                   	push   %eax
   1813b:	e8 92 1b 00 00       	call   19cd2 <usprint>
   18140:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18143:	83 ec 0c             	sub    $0xc,%esp
   18146:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   1814c:	50                   	push   %eax
   1814d:	e8 6d 22 00 00       	call   1a3bf <cwrites>
   18152:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18155:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   1815c:	eb 5b                	jmp    181b9 <progI+0x118>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   1815e:	8b 45 08             	mov    0x8(%ebp),%eax
   18161:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18168:	8b 45 0c             	mov    0xc(%ebp),%eax
   1816b:	01 d0                	add    %edx,%eax
   1816d:	8b 00                	mov    (%eax),%eax
   1816f:	85 c0                	test   %eax,%eax
   18171:	74 13                	je     18186 <progI+0xe5>
   18173:	8b 45 08             	mov    0x8(%ebp),%eax
   18176:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1817d:	8b 45 0c             	mov    0xc(%ebp),%eax
   18180:	01 d0                	add    %edx,%eax
   18182:	8b 00                	mov    (%eax),%eax
   18184:	eb 05                	jmp    1818b <progI+0xea>
   18186:	b8 65 be 01 00       	mov    $0x1be65,%eax
   1818b:	83 ec 04             	sub    $0x4,%esp
   1818e:	50                   	push   %eax
   1818f:	68 6c be 01 00       	push   $0x1be6c
   18194:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   1819a:	50                   	push   %eax
   1819b:	e8 32 1b 00 00       	call   19cd2 <usprint>
   181a0:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   181a3:	83 ec 0c             	sub    $0xc,%esp
   181a6:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   181ac:	50                   	push   %eax
   181ad:	e8 0d 22 00 00       	call   1a3bf <cwrites>
   181b2:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   181b5:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   181b9:	8b 45 ec             	mov    -0x14(%ebp),%eax
   181bc:	3b 45 08             	cmp    0x8(%ebp),%eax
   181bf:	7e 9d                	jle    1815e <progI+0xbd>
			}
			cwrites( "\n" );
   181c1:	83 ec 0c             	sub    $0xc,%esp
   181c4:	68 70 be 01 00       	push   $0x1be70
   181c9:	e8 f1 21 00 00       	call   1a3bf <cwrites>
   181ce:	83 c4 10             	add    $0x10,%esp
   181d1:	eb 01                	jmp    181d4 <progI+0x133>
			break;
   181d3:	90                   	nop
	}

	// secondary output (for indicating errors)
	ch2[1] = ch;
   181d4:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   181d8:	88 85 4c ff ff ff    	mov    %al,-0xb4(%ebp)

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   181de:	83 ec 04             	sub    $0x4,%esp
   181e1:	6a 01                	push   $0x1
   181e3:	8d 45 cf             	lea    -0x31(%ebp),%eax
   181e6:	50                   	push   %eax
   181e7:	6a 01                	push   $0x1
   181e9:	e8 62 ed ff ff       	call   16f50 <write>
   181ee:	83 c4 10             	add    $0x10,%esp

	// set up the argument vector
	// we run:	progW 10 5

	char *argsw[] = { "progW", "W", "10", "5", NULL };
   181f1:	c7 85 6c fe ff ff 32 	movl   $0x1bf32,-0x194(%ebp)
   181f8:	bf 01 00 
   181fb:	c7 85 70 fe ff ff 46 	movl   $0x1bc46,-0x190(%ebp)
   18202:	bc 01 00 
   18205:	c7 85 74 fe ff ff c4 	movl   $0x1bbc4,-0x18c(%ebp)
   1820c:	bb 01 00 
   1820f:	c7 85 78 fe ff ff f3 	movl   $0x1bbf3,-0x188(%ebp)
   18216:	bb 01 00 
   18219:	c7 85 7c fe ff ff 00 	movl   $0x0,-0x184(%ebp)
   18220:	00 00 00 

	for( int i = 0; i < count; ++i ) {
   18223:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   1822a:	eb 5f                	jmp    1828b <progI+0x1ea>
		int whom = spawn( (uint32_t) progW, argsw );
   1822c:	ba 14 84 01 00       	mov    $0x18414,%edx
   18231:	83 ec 08             	sub    $0x8,%esp
   18234:	8d 85 6c fe ff ff    	lea    -0x194(%ebp),%eax
   1823a:	50                   	push   %eax
   1823b:	52                   	push   %edx
   1823c:	e8 e8 20 00 00       	call   1a329 <spawn>
   18241:	83 c4 10             	add    $0x10,%esp
   18244:	89 45 d0             	mov    %eax,-0x30(%ebp)
		if( whom < 0 ) {
   18247:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
   1824b:	79 14                	jns    18261 <progI+0x1c0>
			swrites( ch2 );
   1824d:	83 ec 0c             	sub    $0xc,%esp
   18250:	8d 85 4b ff ff ff    	lea    -0xb5(%ebp),%eax
   18256:	50                   	push   %eax
   18257:	e8 c9 21 00 00       	call   1a425 <swrites>
   1825c:	83 c4 10             	add    $0x10,%esp
   1825f:	eb 26                	jmp    18287 <progI+0x1e6>
		} else {
			swritech( ch );
   18261:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   18265:	0f be c0             	movsbl %al,%eax
   18268:	83 ec 0c             	sub    $0xc,%esp
   1826b:	50                   	push   %eax
   1826c:	e8 93 21 00 00       	call   1a404 <swritech>
   18271:	83 c4 10             	add    $0x10,%esp
			children[nkids++] = whom;
   18274:	8b 45 f0             	mov    -0x10(%ebp),%eax
   18277:	8d 50 01             	lea    0x1(%eax),%edx
   1827a:	89 55 f0             	mov    %edx,-0x10(%ebp)
   1827d:	8b 55 d0             	mov    -0x30(%ebp),%edx
   18280:	89 94 85 80 fe ff ff 	mov    %edx,-0x180(%ebp,%eax,4)
	for( int i = 0; i < count; ++i ) {
   18287:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   1828b:	8b 45 e8             	mov    -0x18(%ebp),%eax
   1828e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18291:	7c 99                	jl     1822c <progI+0x18b>
		}
	}

	// let the children start
	sleep( SEC_TO_MS(nap) );
   18293:	8b 45 dc             	mov    -0x24(%ebp),%eax
   18296:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   1829c:	83 ec 0c             	sub    $0xc,%esp
   1829f:	50                   	push   %eax
   182a0:	e8 e3 ec ff ff       	call   16f88 <sleep>
   182a5:	83 c4 10             	add    $0x10,%esp

	// kill two of them
	int32_t status = kill( children[1] );
   182a8:	8b 85 84 fe ff ff    	mov    -0x17c(%ebp),%eax
   182ae:	83 ec 0c             	sub    $0xc,%esp
   182b1:	50                   	push   %eax
   182b2:	e8 c9 ec ff ff       	call   16f80 <kill>
   182b7:	83 c4 10             	add    $0x10,%esp
   182ba:	89 45 d8             	mov    %eax,-0x28(%ebp)
	if( status ) {
   182bd:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   182c1:	74 45                	je     18308 <progI+0x267>
		usprint( buf, "!! %c: kill(%d) status %d\n", ch, children[1], status );
   182c3:	8b 95 84 fe ff ff    	mov    -0x17c(%ebp),%edx
   182c9:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   182cd:	0f be c0             	movsbl %al,%eax
   182d0:	83 ec 0c             	sub    $0xc,%esp
   182d3:	ff 75 d8             	pushl  -0x28(%ebp)
   182d6:	52                   	push   %edx
   182d7:	50                   	push   %eax
   182d8:	68 38 bf 01 00       	push   $0x1bf38
   182dd:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   182e3:	50                   	push   %eax
   182e4:	e8 e9 19 00 00       	call   19cd2 <usprint>
   182e9:	83 c4 20             	add    $0x20,%esp
		cwrites( buf );
   182ec:	83 ec 0c             	sub    $0xc,%esp
   182ef:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   182f5:	50                   	push   %eax
   182f6:	e8 c4 20 00 00       	call   1a3bf <cwrites>
   182fb:	83 c4 10             	add    $0x10,%esp
		children[1] = -42;
   182fe:	c7 85 84 fe ff ff d6 	movl   $0xffffffd6,-0x17c(%ebp)
   18305:	ff ff ff 
	}
	status = kill( children[3] );
   18308:	8b 85 8c fe ff ff    	mov    -0x174(%ebp),%eax
   1830e:	83 ec 0c             	sub    $0xc,%esp
   18311:	50                   	push   %eax
   18312:	e8 69 ec ff ff       	call   16f80 <kill>
   18317:	83 c4 10             	add    $0x10,%esp
   1831a:	89 45 d8             	mov    %eax,-0x28(%ebp)
	if( status ) {
   1831d:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   18321:	74 45                	je     18368 <progI+0x2c7>
		usprint( buf, "!! %c: kill(%d) status %d\n", ch, children[3], status );
   18323:	8b 95 8c fe ff ff    	mov    -0x174(%ebp),%edx
   18329:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   1832d:	0f be c0             	movsbl %al,%eax
   18330:	83 ec 0c             	sub    $0xc,%esp
   18333:	ff 75 d8             	pushl  -0x28(%ebp)
   18336:	52                   	push   %edx
   18337:	50                   	push   %eax
   18338:	68 38 bf 01 00       	push   $0x1bf38
   1833d:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   18343:	50                   	push   %eax
   18344:	e8 89 19 00 00       	call   19cd2 <usprint>
   18349:	83 c4 20             	add    $0x20,%esp
		cwrites( buf );
   1834c:	83 ec 0c             	sub    $0xc,%esp
   1834f:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   18355:	50                   	push   %eax
   18356:	e8 64 20 00 00       	call   1a3bf <cwrites>
   1835b:	83 c4 10             	add    $0x10,%esp
		children[3] = -42;
   1835e:	c7 85 8c fe ff ff d6 	movl   $0xffffffd6,-0x174(%ebp)
   18365:	ff ff ff 
	}

	// collect child information
	while( 1 ) {
		int n = waitpid( 0, NULL );
   18368:	83 ec 08             	sub    $0x8,%esp
   1836b:	6a 00                	push   $0x0
   1836d:	6a 00                	push   $0x0
   1836f:	e8 bc eb ff ff       	call   16f30 <waitpid>
   18374:	83 c4 10             	add    $0x10,%esp
   18377:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		if( n == E_NO_CHILDREN ) {
   1837a:	83 7d d4 fc          	cmpl   $0xfffffffc,-0x2c(%ebp)
   1837e:	74 7f                	je     183ff <progI+0x35e>
			// all done!
			break;
		}
		for( int i = 0; i < count; ++i ) {
   18380:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   18387:	eb 54                	jmp    183dd <progI+0x33c>
			if( children[i] == n ) {
   18389:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   1838c:	8b 94 85 80 fe ff ff 	mov    -0x180(%ebp,%eax,4),%edx
   18393:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   18396:	39 c2                	cmp    %eax,%edx
   18398:	75 3f                	jne    183d9 <progI+0x338>
				usprint( buf, "== %c: child %d (%d)\n", ch, i, children[i] );
   1839a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   1839d:	8b 94 85 80 fe ff ff 	mov    -0x180(%ebp,%eax,4),%edx
   183a4:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   183a8:	0f be c0             	movsbl %al,%eax
   183ab:	83 ec 0c             	sub    $0xc,%esp
   183ae:	52                   	push   %edx
   183af:	ff 75 e4             	pushl  -0x1c(%ebp)
   183b2:	50                   	push   %eax
   183b3:	68 53 bf 01 00       	push   $0x1bf53
   183b8:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   183be:	50                   	push   %eax
   183bf:	e8 0e 19 00 00       	call   19cd2 <usprint>
   183c4:	83 c4 20             	add    $0x20,%esp
				cwrites( buf );
   183c7:	83 ec 0c             	sub    $0xc,%esp
   183ca:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   183d0:	50                   	push   %eax
   183d1:	e8 e9 1f 00 00       	call   1a3bf <cwrites>
   183d6:	83 c4 10             	add    $0x10,%esp
		for( int i = 0; i < count; ++i ) {
   183d9:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   183dd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   183e0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   183e3:	7c a4                	jl     18389 <progI+0x2e8>
			}
		}
		sleep( SEC_TO_MS(nap) );
   183e5:	8b 45 dc             	mov    -0x24(%ebp),%eax
   183e8:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   183ee:	83 ec 0c             	sub    $0xc,%esp
   183f1:	50                   	push   %eax
   183f2:	e8 91 eb ff ff       	call   16f88 <sleep>
   183f7:	83 c4 10             	add    $0x10,%esp
	while( 1 ) {
   183fa:	e9 69 ff ff ff       	jmp    18368 <progI+0x2c7>
			break;
   183ff:	90                   	nop
	};

	// let init() clean up after us!

	exit( 0 );
   18400:	83 ec 0c             	sub    $0xc,%esp
   18403:	6a 00                	push   $0x0
   18405:	e8 1e eb ff ff       	call   16f28 <exit>
   1840a:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   1840d:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   18412:	c9                   	leave  
   18413:	c3                   	ret    

00018414 <progW>:
**	 where x is the ID character
**		   n is the iteration count (defaults to 20)
**		   s is the sleep time (defaults to 3 seconds)
*/

USERMAIN( progW ) {
   18414:	55                   	push   %ebp
   18415:	89 e5                	mov    %esp,%ebp
   18417:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   1841d:	8b 45 0c             	mov    0xc(%ebp),%eax
   18420:	8b 00                	mov    (%eax),%eax
   18422:	85 c0                	test   %eax,%eax
   18424:	74 07                	je     1842d <progW+0x19>
   18426:	8b 45 0c             	mov    0xc(%ebp),%eax
   18429:	8b 00                	mov    (%eax),%eax
   1842b:	eb 05                	jmp    18432 <progW+0x1e>
   1842d:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   18432:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int count = 20;	  // default iteration count
   18435:	c7 45 f4 14 00 00 00 	movl   $0x14,-0xc(%ebp)
	char ch = 'w';	  // default character to print
   1843c:	c6 45 db 77          	movb   $0x77,-0x25(%ebp)
	int nap = 3;	  // nap length
   18440:	c7 45 f0 03 00 00 00 	movl   $0x3,-0x10(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   18447:	8b 45 08             	mov    0x8(%ebp),%eax
   1844a:	83 f8 03             	cmp    $0x3,%eax
   1844d:	74 25                	je     18474 <progW+0x60>
   1844f:	83 f8 04             	cmp    $0x4,%eax
   18452:	74 07                	je     1845b <progW+0x47>
   18454:	83 f8 02             	cmp    $0x2,%eax
   18457:	74 34                	je     1848d <progW+0x79>
   18459:	eb 45                	jmp    184a0 <progW+0x8c>
	case 4:	nap = ustr2int( argv[3], 10 );
   1845b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1845e:	83 c0 0c             	add    $0xc,%eax
   18461:	8b 00                	mov    (%eax),%eax
   18463:	83 ec 08             	sub    $0x8,%esp
   18466:	6a 0a                	push   $0xa
   18468:	50                   	push   %eax
   18469:	e8 d9 1a 00 00       	call   19f47 <ustr2int>
   1846e:	83 c4 10             	add    $0x10,%esp
   18471:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   18474:	8b 45 0c             	mov    0xc(%ebp),%eax
   18477:	83 c0 08             	add    $0x8,%eax
   1847a:	8b 00                	mov    (%eax),%eax
   1847c:	83 ec 08             	sub    $0x8,%esp
   1847f:	6a 0a                	push   $0xa
   18481:	50                   	push   %eax
   18482:	e8 c0 1a 00 00       	call   19f47 <ustr2int>
   18487:	83 c4 10             	add    $0x10,%esp
   1848a:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   1848d:	8b 45 0c             	mov    0xc(%ebp),%eax
   18490:	83 c0 04             	add    $0x4,%eax
   18493:	8b 00                	mov    (%eax),%eax
   18495:	0f b6 00             	movzbl (%eax),%eax
   18498:	88 45 db             	mov    %al,-0x25(%ebp)
			break;
   1849b:	e9 a8 00 00 00       	jmp    18548 <progW+0x134>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   184a0:	ff 75 08             	pushl  0x8(%ebp)
   184a3:	ff 75 e4             	pushl  -0x1c(%ebp)
   184a6:	68 51 be 01 00       	push   $0x1be51
   184ab:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   184b1:	50                   	push   %eax
   184b2:	e8 1b 18 00 00       	call   19cd2 <usprint>
   184b7:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   184ba:	83 ec 0c             	sub    $0xc,%esp
   184bd:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   184c3:	50                   	push   %eax
   184c4:	e8 f6 1e 00 00       	call   1a3bf <cwrites>
   184c9:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   184cc:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   184d3:	eb 5b                	jmp    18530 <progW+0x11c>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   184d5:	8b 45 08             	mov    0x8(%ebp),%eax
   184d8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   184df:	8b 45 0c             	mov    0xc(%ebp),%eax
   184e2:	01 d0                	add    %edx,%eax
   184e4:	8b 00                	mov    (%eax),%eax
   184e6:	85 c0                	test   %eax,%eax
   184e8:	74 13                	je     184fd <progW+0xe9>
   184ea:	8b 45 08             	mov    0x8(%ebp),%eax
   184ed:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   184f4:	8b 45 0c             	mov    0xc(%ebp),%eax
   184f7:	01 d0                	add    %edx,%eax
   184f9:	8b 00                	mov    (%eax),%eax
   184fb:	eb 05                	jmp    18502 <progW+0xee>
   184fd:	b8 65 be 01 00       	mov    $0x1be65,%eax
   18502:	83 ec 04             	sub    $0x4,%esp
   18505:	50                   	push   %eax
   18506:	68 6c be 01 00       	push   $0x1be6c
   1850b:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18511:	50                   	push   %eax
   18512:	e8 bb 17 00 00       	call   19cd2 <usprint>
   18517:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1851a:	83 ec 0c             	sub    $0xc,%esp
   1851d:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18523:	50                   	push   %eax
   18524:	e8 96 1e 00 00       	call   1a3bf <cwrites>
   18529:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1852c:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18530:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18533:	3b 45 08             	cmp    0x8(%ebp),%eax
   18536:	7e 9d                	jle    184d5 <progW+0xc1>
			}
			cwrites( "\n" );
   18538:	83 ec 0c             	sub    $0xc,%esp
   1853b:	68 70 be 01 00       	push   $0x1be70
   18540:	e8 7a 1e 00 00       	call   1a3bf <cwrites>
   18545:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int pid = getpid();
   18548:	e8 0b ea ff ff       	call   16f58 <getpid>
   1854d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	uint32_t now = gettime();
   18550:	e8 13 ea ff ff       	call   16f68 <gettime>
   18555:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d,%u]", ch, pid, now );
   18558:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   1855c:	0f be c0             	movsbl %al,%eax
   1855f:	83 ec 0c             	sub    $0xc,%esp
   18562:	ff 75 dc             	pushl  -0x24(%ebp)
   18565:	ff 75 e0             	pushl  -0x20(%ebp)
   18568:	50                   	push   %eax
   18569:	68 69 bf 01 00       	push   $0x1bf69
   1856e:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18574:	50                   	push   %eax
   18575:	e8 58 17 00 00       	call   19cd2 <usprint>
   1857a:	83 c4 20             	add    $0x20,%esp
	swrites( buf );
   1857d:	83 ec 0c             	sub    $0xc,%esp
   18580:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18586:	50                   	push   %eax
   18587:	e8 99 1e 00 00       	call   1a425 <swrites>
   1858c:	83 c4 10             	add    $0x10,%esp

	write( CHAN_SIO, &ch, 1 );
   1858f:	83 ec 04             	sub    $0x4,%esp
   18592:	6a 01                	push   $0x1
   18594:	8d 45 db             	lea    -0x25(%ebp),%eax
   18597:	50                   	push   %eax
   18598:	6a 01                	push   $0x1
   1859a:	e8 b1 e9 ff ff       	call   16f50 <write>
   1859f:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   185a2:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   185a9:	eb 58                	jmp    18603 <progW+0x1ef>
		now = gettime();
   185ab:	e8 b8 e9 ff ff       	call   16f68 <gettime>
   185b0:	89 45 dc             	mov    %eax,-0x24(%ebp)
		usprint( buf, " %c[%d,%u] ", ch, pid, now );
   185b3:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   185b7:	0f be c0             	movsbl %al,%eax
   185ba:	83 ec 0c             	sub    $0xc,%esp
   185bd:	ff 75 dc             	pushl  -0x24(%ebp)
   185c0:	ff 75 e0             	pushl  -0x20(%ebp)
   185c3:	50                   	push   %eax
   185c4:	68 74 bf 01 00       	push   $0x1bf74
   185c9:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   185cf:	50                   	push   %eax
   185d0:	e8 fd 16 00 00       	call   19cd2 <usprint>
   185d5:	83 c4 20             	add    $0x20,%esp
		swrites( buf );
   185d8:	83 ec 0c             	sub    $0xc,%esp
   185db:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   185e1:	50                   	push   %eax
   185e2:	e8 3e 1e 00 00       	call   1a425 <swrites>
   185e7:	83 c4 10             	add    $0x10,%esp
		sleep( SEC_TO_MS(nap) );
   185ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
   185ed:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   185f3:	83 ec 0c             	sub    $0xc,%esp
   185f6:	50                   	push   %eax
   185f7:	e8 8c e9 ff ff       	call   16f88 <sleep>
   185fc:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   185ff:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18603:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18606:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18609:	7c a0                	jl     185ab <progW+0x197>
	}

	exit( 0 );
   1860b:	83 ec 0c             	sub    $0xc,%esp
   1860e:	6a 00                	push   $0x0
   18610:	e8 13 e9 ff ff       	call   16f28 <exit>
   18615:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18618:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   1861d:	c9                   	leave  
   1861e:	c3                   	ret    

0001861f <progJ>:
** Invoked as:  progJ  x  [ n ]
**	 where x is the ID character
**		   n is the number of children to spawn (defaults to 2 * N_PROCS)
*/

USERMAIN( progJ ) {
   1861f:	55                   	push   %ebp
   18620:	89 e5                	mov    %esp,%ebp
   18622:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18628:	8b 45 0c             	mov    0xc(%ebp),%eax
   1862b:	8b 00                	mov    (%eax),%eax
   1862d:	85 c0                	test   %eax,%eax
   1862f:	74 07                	je     18638 <progJ+0x19>
   18631:	8b 45 0c             	mov    0xc(%ebp),%eax
   18634:	8b 00                	mov    (%eax),%eax
   18636:	eb 05                	jmp    1863d <progJ+0x1e>
   18638:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   1863d:	89 45 e8             	mov    %eax,-0x18(%ebp)
	int count = 2 * N_PROCS;	// number of children to spawn
   18640:	c7 45 f4 32 00 00 00 	movl   $0x32,-0xc(%ebp)
	char ch = 'j';				// default character to print
   18647:	c6 45 e3 6a          	movb   $0x6a,-0x1d(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   1864b:	8b 45 08             	mov    0x8(%ebp),%eax
   1864e:	83 f8 02             	cmp    $0x2,%eax
   18651:	74 1e                	je     18671 <progJ+0x52>
   18653:	83 f8 03             	cmp    $0x3,%eax
   18656:	75 2c                	jne    18684 <progJ+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   18658:	8b 45 0c             	mov    0xc(%ebp),%eax
   1865b:	83 c0 08             	add    $0x8,%eax
   1865e:	8b 00                	mov    (%eax),%eax
   18660:	83 ec 08             	sub    $0x8,%esp
   18663:	6a 0a                	push   $0xa
   18665:	50                   	push   %eax
   18666:	e8 dc 18 00 00       	call   19f47 <ustr2int>
   1866b:	83 c4 10             	add    $0x10,%esp
   1866e:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18671:	8b 45 0c             	mov    0xc(%ebp),%eax
   18674:	83 c0 04             	add    $0x4,%eax
   18677:	8b 00                	mov    (%eax),%eax
   18679:	0f b6 00             	movzbl (%eax),%eax
   1867c:	88 45 e3             	mov    %al,-0x1d(%ebp)
			break;
   1867f:	e9 a8 00 00 00       	jmp    1872c <progJ+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18684:	ff 75 08             	pushl  0x8(%ebp)
   18687:	ff 75 e8             	pushl  -0x18(%ebp)
   1868a:	68 51 be 01 00       	push   $0x1be51
   1868f:	8d 85 63 ff ff ff    	lea    -0x9d(%ebp),%eax
   18695:	50                   	push   %eax
   18696:	e8 37 16 00 00       	call   19cd2 <usprint>
   1869b:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1869e:	83 ec 0c             	sub    $0xc,%esp
   186a1:	8d 85 63 ff ff ff    	lea    -0x9d(%ebp),%eax
   186a7:	50                   	push   %eax
   186a8:	e8 12 1d 00 00       	call   1a3bf <cwrites>
   186ad:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   186b0:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   186b7:	eb 5b                	jmp    18714 <progJ+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   186b9:	8b 45 08             	mov    0x8(%ebp),%eax
   186bc:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   186c3:	8b 45 0c             	mov    0xc(%ebp),%eax
   186c6:	01 d0                	add    %edx,%eax
   186c8:	8b 00                	mov    (%eax),%eax
   186ca:	85 c0                	test   %eax,%eax
   186cc:	74 13                	je     186e1 <progJ+0xc2>
   186ce:	8b 45 08             	mov    0x8(%ebp),%eax
   186d1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   186d8:	8b 45 0c             	mov    0xc(%ebp),%eax
   186db:	01 d0                	add    %edx,%eax
   186dd:	8b 00                	mov    (%eax),%eax
   186df:	eb 05                	jmp    186e6 <progJ+0xc7>
   186e1:	b8 65 be 01 00       	mov    $0x1be65,%eax
   186e6:	83 ec 04             	sub    $0x4,%esp
   186e9:	50                   	push   %eax
   186ea:	68 6c be 01 00       	push   $0x1be6c
   186ef:	8d 85 63 ff ff ff    	lea    -0x9d(%ebp),%eax
   186f5:	50                   	push   %eax
   186f6:	e8 d7 15 00 00       	call   19cd2 <usprint>
   186fb:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   186fe:	83 ec 0c             	sub    $0xc,%esp
   18701:	8d 85 63 ff ff ff    	lea    -0x9d(%ebp),%eax
   18707:	50                   	push   %eax
   18708:	e8 b2 1c 00 00       	call   1a3bf <cwrites>
   1870d:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18710:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   18714:	8b 45 f0             	mov    -0x10(%ebp),%eax
   18717:	3b 45 08             	cmp    0x8(%ebp),%eax
   1871a:	7e 9d                	jle    186b9 <progJ+0x9a>
			}
			cwrites( "\n" );
   1871c:	83 ec 0c             	sub    $0xc,%esp
   1871f:	68 70 be 01 00       	push   $0x1be70
   18724:	e8 96 1c 00 00       	call   1a3bf <cwrites>
   18729:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   1872c:	83 ec 04             	sub    $0x4,%esp
   1872f:	6a 01                	push   $0x1
   18731:	8d 45 e3             	lea    -0x1d(%ebp),%eax
   18734:	50                   	push   %eax
   18735:	6a 01                	push   $0x1
   18737:	e8 14 e8 ff ff       	call   16f50 <write>
   1873c:	83 c4 10             	add    $0x10,%esp

	// set up the command-line arguments
	char *argsy[] = { "progY", "Y", "10", NULL };
   1873f:	c7 85 50 ff ff ff 80 	movl   $0x1bf80,-0xb0(%ebp)
   18746:	bf 01 00 
   18749:	c7 85 54 ff ff ff 86 	movl   $0x1bf86,-0xac(%ebp)
   18750:	bf 01 00 
   18753:	c7 85 58 ff ff ff c4 	movl   $0x1bbc4,-0xa8(%ebp)
   1875a:	bb 01 00 
   1875d:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
   18764:	00 00 00 

	for( int i = 0; i < count ; ++i ) {
   18767:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   1876e:	eb 4e                	jmp    187be <progJ+0x19f>
		int whom = spawn( (uint32_t) progY, argsy );
   18770:	ba da 87 01 00       	mov    $0x187da,%edx
   18775:	83 ec 08             	sub    $0x8,%esp
   18778:	8d 85 50 ff ff ff    	lea    -0xb0(%ebp),%eax
   1877e:	50                   	push   %eax
   1877f:	52                   	push   %edx
   18780:	e8 a4 1b 00 00       	call   1a329 <spawn>
   18785:	83 c4 10             	add    $0x10,%esp
   18788:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		if( whom < 0 ) {
   1878b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   1878f:	79 16                	jns    187a7 <progJ+0x188>
			write( CHAN_SIO, "!j!", 3 );
   18791:	83 ec 04             	sub    $0x4,%esp
   18794:	6a 03                	push   $0x3
   18796:	68 88 bf 01 00       	push   $0x1bf88
   1879b:	6a 01                	push   $0x1
   1879d:	e8 ae e7 ff ff       	call   16f50 <write>
   187a2:	83 c4 10             	add    $0x10,%esp
   187a5:	eb 13                	jmp    187ba <progJ+0x19b>
		} else {
			write( CHAN_SIO, &ch, 1 );
   187a7:	83 ec 04             	sub    $0x4,%esp
   187aa:	6a 01                	push   $0x1
   187ac:	8d 45 e3             	lea    -0x1d(%ebp),%eax
   187af:	50                   	push   %eax
   187b0:	6a 01                	push   $0x1
   187b2:	e8 99 e7 ff ff       	call   16f50 <write>
   187b7:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   187ba:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   187be:	8b 45 ec             	mov    -0x14(%ebp),%eax
   187c1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   187c4:	7c aa                	jl     18770 <progJ+0x151>
		}
	}

	exit( 0 );
   187c6:	83 ec 0c             	sub    $0xc,%esp
   187c9:	6a 00                	push   $0x0
   187cb:	e8 58 e7 ff ff       	call   16f28 <exit>
   187d0:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   187d3:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   187d8:	c9                   	leave  
   187d9:	c3                   	ret    

000187da <progY>:
** Invoked as:	progY  x  [ n ]
**	 where x is the ID character
**		   n is the iteration count (defaults to 10)
*/

USERMAIN( progY ) {
   187da:	55                   	push   %ebp
   187db:	89 e5                	mov    %esp,%ebp
   187dd:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   187e3:	8b 45 0c             	mov    0xc(%ebp),%eax
   187e6:	8b 00                	mov    (%eax),%eax
   187e8:	85 c0                	test   %eax,%eax
   187ea:	74 07                	je     187f3 <progY+0x19>
   187ec:	8b 45 0c             	mov    0xc(%ebp),%eax
   187ef:	8b 00                	mov    (%eax),%eax
   187f1:	eb 05                	jmp    187f8 <progY+0x1e>
   187f3:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   187f8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 10;	  // default iteration count
   187fb:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
	char ch = 'y';	  // default character to print
   18802:	c6 45 f3 79          	movb   $0x79,-0xd(%ebp)
	char buf[128];

	(void) name;

	// process the command-line arguments
	switch( argc ) {
   18806:	8b 45 08             	mov    0x8(%ebp),%eax
   18809:	83 f8 02             	cmp    $0x2,%eax
   1880c:	74 1e                	je     1882c <progY+0x52>
   1880e:	83 f8 03             	cmp    $0x3,%eax
   18811:	75 2c                	jne    1883f <progY+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   18813:	8b 45 0c             	mov    0xc(%ebp),%eax
   18816:	83 c0 08             	add    $0x8,%eax
   18819:	8b 00                	mov    (%eax),%eax
   1881b:	83 ec 08             	sub    $0x8,%esp
   1881e:	6a 0a                	push   $0xa
   18820:	50                   	push   %eax
   18821:	e8 21 17 00 00       	call   19f47 <ustr2int>
   18826:	83 c4 10             	add    $0x10,%esp
   18829:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   1882c:	8b 45 0c             	mov    0xc(%ebp),%eax
   1882f:	83 c0 04             	add    $0x4,%eax
   18832:	8b 00                	mov    (%eax),%eax
   18834:	0f b6 00             	movzbl (%eax),%eax
   18837:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   1883a:	e9 a8 00 00 00       	jmp    188e7 <progY+0x10d>
	default:
			usprint( buf, "?: argc %d, args: ", argc );
   1883f:	83 ec 04             	sub    $0x4,%esp
   18842:	ff 75 08             	pushl  0x8(%ebp)
   18845:	68 17 bf 01 00       	push   $0x1bf17
   1884a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18850:	50                   	push   %eax
   18851:	e8 7c 14 00 00       	call   19cd2 <usprint>
   18856:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18859:	83 ec 0c             	sub    $0xc,%esp
   1885c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18862:	50                   	push   %eax
   18863:	e8 57 1b 00 00       	call   1a3bf <cwrites>
   18868:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1886b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18872:	eb 5b                	jmp    188cf <progY+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18874:	8b 45 08             	mov    0x8(%ebp),%eax
   18877:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1887e:	8b 45 0c             	mov    0xc(%ebp),%eax
   18881:	01 d0                	add    %edx,%eax
   18883:	8b 00                	mov    (%eax),%eax
   18885:	85 c0                	test   %eax,%eax
   18887:	74 13                	je     1889c <progY+0xc2>
   18889:	8b 45 08             	mov    0x8(%ebp),%eax
   1888c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18893:	8b 45 0c             	mov    0xc(%ebp),%eax
   18896:	01 d0                	add    %edx,%eax
   18898:	8b 00                	mov    (%eax),%eax
   1889a:	eb 05                	jmp    188a1 <progY+0xc7>
   1889c:	b8 65 be 01 00       	mov    $0x1be65,%eax
   188a1:	83 ec 04             	sub    $0x4,%esp
   188a4:	50                   	push   %eax
   188a5:	68 6c be 01 00       	push   $0x1be6c
   188aa:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   188b0:	50                   	push   %eax
   188b1:	e8 1c 14 00 00       	call   19cd2 <usprint>
   188b6:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   188b9:	83 ec 0c             	sub    $0xc,%esp
   188bc:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   188c2:	50                   	push   %eax
   188c3:	e8 f7 1a 00 00       	call   1a3bf <cwrites>
   188c8:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   188cb:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   188cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
   188d2:	3b 45 08             	cmp    0x8(%ebp),%eax
   188d5:	7e 9d                	jle    18874 <progY+0x9a>
			}
			cwrites( "\n" );
   188d7:	83 ec 0c             	sub    $0xc,%esp
   188da:	68 70 be 01 00       	push   $0x1be70
   188df:	e8 db 1a 00 00       	call   1a3bf <cwrites>
   188e4:	83 c4 10             	add    $0x10,%esp
	}

	// report our presence
	int pid = getpid();
   188e7:	e8 6c e6 ff ff       	call   16f58 <getpid>
   188ec:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d]", ch, pid );
   188ef:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   188f3:	ff 75 dc             	pushl  -0x24(%ebp)
   188f6:	50                   	push   %eax
   188f7:	68 2a bf 01 00       	push   $0x1bf2a
   188fc:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18902:	50                   	push   %eax
   18903:	e8 ca 13 00 00       	call   19cd2 <usprint>
   18908:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   1890b:	83 ec 0c             	sub    $0xc,%esp
   1890e:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18914:	50                   	push   %eax
   18915:	e8 0b 1b 00 00       	call   1a425 <swrites>
   1891a:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   1891d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18924:	eb 3c                	jmp    18962 <progY+0x188>
		swrites( buf );
   18926:	83 ec 0c             	sub    $0xc,%esp
   18929:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1892f:	50                   	push   %eax
   18930:	e8 f0 1a 00 00       	call   1a425 <swrites>
   18935:	83 c4 10             	add    $0x10,%esp
		DELAY(STD);
   18938:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   1893f:	eb 04                	jmp    18945 <progY+0x16b>
   18941:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   18945:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   1894c:	7e f3                	jle    18941 <progY+0x167>
		sleep( SEC_TO_MS(1) );
   1894e:	83 ec 0c             	sub    $0xc,%esp
   18951:	68 e8 03 00 00       	push   $0x3e8
   18956:	e8 2d e6 ff ff       	call   16f88 <sleep>
   1895b:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   1895e:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18962:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18965:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18968:	7c bc                	jl     18926 <progY+0x14c>
	}

	exit( 0 );
   1896a:	83 ec 0c             	sub    $0xc,%esp
   1896d:	6a 00                	push   $0x0
   1896f:	e8 b4 e5 ff ff       	call   16f28 <exit>
   18974:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18977:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   1897c:	c9                   	leave  
   1897d:	c3                   	ret    

0001897e <progKL>:
** Invoked as:  progKL  x  n
**	 where x is the ID character
**		   n is the iteration count (defaults to 5)
*/

USERMAIN( progKL ) {
   1897e:	55                   	push   %ebp
   1897f:	89 e5                	mov    %esp,%ebp
   18981:	83 ec 58             	sub    $0x58,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18984:	8b 45 0c             	mov    0xc(%ebp),%eax
   18987:	8b 00                	mov    (%eax),%eax
   18989:	85 c0                	test   %eax,%eax
   1898b:	74 07                	je     18994 <progKL+0x16>
   1898d:	8b 45 0c             	mov    0xc(%ebp),%eax
   18990:	8b 00                	mov    (%eax),%eax
   18992:	eb 05                	jmp    18999 <progKL+0x1b>
   18994:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   18999:	89 45 e8             	mov    %eax,-0x18(%ebp)
	int count = 5;			// default iteration count
   1899c:	c7 45 f4 05 00 00 00 	movl   $0x5,-0xc(%ebp)
	char ch = '4';			// default character to print
   189a3:	c6 45 df 34          	movb   $0x34,-0x21(%ebp)
	int nap = 30;			// nap time
   189a7:	c7 45 e4 1e 00 00 00 	movl   $0x1e,-0x1c(%ebp)
	char msg2[] = "*4*";	// "error" message to print
   189ae:	c7 45 db 2a 34 2a 00 	movl   $0x2a342a,-0x25(%ebp)
	char buf[32];

	// process the command-line arguments
	switch( argc ) {
   189b5:	8b 45 08             	mov    0x8(%ebp),%eax
   189b8:	83 f8 02             	cmp    $0x2,%eax
   189bb:	74 1e                	je     189db <progKL+0x5d>
   189bd:	83 f8 03             	cmp    $0x3,%eax
   189c0:	75 2c                	jne    189ee <progKL+0x70>
	case 3:	count = ustr2int( argv[2], 10 );
   189c2:	8b 45 0c             	mov    0xc(%ebp),%eax
   189c5:	83 c0 08             	add    $0x8,%eax
   189c8:	8b 00                	mov    (%eax),%eax
   189ca:	83 ec 08             	sub    $0x8,%esp
   189cd:	6a 0a                	push   $0xa
   189cf:	50                   	push   %eax
   189d0:	e8 72 15 00 00       	call   19f47 <ustr2int>
   189d5:	83 c4 10             	add    $0x10,%esp
   189d8:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   189db:	8b 45 0c             	mov    0xc(%ebp),%eax
   189de:	83 c0 04             	add    $0x4,%eax
   189e1:	8b 00                	mov    (%eax),%eax
   189e3:	0f b6 00             	movzbl (%eax),%eax
   189e6:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   189e9:	e9 9c 00 00 00       	jmp    18a8a <progKL+0x10c>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   189ee:	ff 75 08             	pushl  0x8(%ebp)
   189f1:	ff 75 e8             	pushl  -0x18(%ebp)
   189f4:	68 51 be 01 00       	push   $0x1be51
   189f9:	8d 45 bb             	lea    -0x45(%ebp),%eax
   189fc:	50                   	push   %eax
   189fd:	e8 d0 12 00 00       	call   19cd2 <usprint>
   18a02:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18a05:	83 ec 0c             	sub    $0xc,%esp
   18a08:	8d 45 bb             	lea    -0x45(%ebp),%eax
   18a0b:	50                   	push   %eax
   18a0c:	e8 ae 19 00 00       	call   1a3bf <cwrites>
   18a11:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18a14:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   18a1b:	eb 55                	jmp    18a72 <progKL+0xf4>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18a1d:	8b 45 08             	mov    0x8(%ebp),%eax
   18a20:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18a27:	8b 45 0c             	mov    0xc(%ebp),%eax
   18a2a:	01 d0                	add    %edx,%eax
   18a2c:	8b 00                	mov    (%eax),%eax
   18a2e:	85 c0                	test   %eax,%eax
   18a30:	74 13                	je     18a45 <progKL+0xc7>
   18a32:	8b 45 08             	mov    0x8(%ebp),%eax
   18a35:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18a3c:	8b 45 0c             	mov    0xc(%ebp),%eax
   18a3f:	01 d0                	add    %edx,%eax
   18a41:	8b 00                	mov    (%eax),%eax
   18a43:	eb 05                	jmp    18a4a <progKL+0xcc>
   18a45:	b8 65 be 01 00       	mov    $0x1be65,%eax
   18a4a:	83 ec 04             	sub    $0x4,%esp
   18a4d:	50                   	push   %eax
   18a4e:	68 6c be 01 00       	push   $0x1be6c
   18a53:	8d 45 bb             	lea    -0x45(%ebp),%eax
   18a56:	50                   	push   %eax
   18a57:	e8 76 12 00 00       	call   19cd2 <usprint>
   18a5c:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   18a5f:	83 ec 0c             	sub    $0xc,%esp
   18a62:	8d 45 bb             	lea    -0x45(%ebp),%eax
   18a65:	50                   	push   %eax
   18a66:	e8 54 19 00 00       	call   1a3bf <cwrites>
   18a6b:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18a6e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   18a72:	8b 45 f0             	mov    -0x10(%ebp),%eax
   18a75:	3b 45 08             	cmp    0x8(%ebp),%eax
   18a78:	7e a3                	jle    18a1d <progKL+0x9f>
			}
			cwrites( "\n" );
   18a7a:	83 ec 0c             	sub    $0xc,%esp
   18a7d:	68 70 be 01 00       	push   $0x1be70
   18a82:	e8 38 19 00 00       	call   1a3bf <cwrites>
   18a87:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   18a8a:	83 ec 04             	sub    $0x4,%esp
   18a8d:	6a 01                	push   $0x1
   18a8f:	8d 45 df             	lea    -0x21(%ebp),%eax
   18a92:	50                   	push   %eax
   18a93:	6a 01                	push   $0x1
   18a95:	e8 b6 e4 ff ff       	call   16f50 <write>
   18a9a:	83 c4 10             	add    $0x10,%esp

	// argument vector for the processes we will spawn
	char *arglist[] = { "progX", "X", buf, NULL };
   18a9d:	c7 45 a8 8c bf 01 00 	movl   $0x1bf8c,-0x58(%ebp)
   18aa4:	c7 45 ac 92 bf 01 00 	movl   $0x1bf92,-0x54(%ebp)
   18aab:	8d 45 bb             	lea    -0x45(%ebp),%eax
   18aae:	89 45 b0             	mov    %eax,-0x50(%ebp)
   18ab1:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)

	for( int i = 0; i < count ; ++i ) {
   18ab8:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18abf:	e9 89 00 00 00       	jmp    18b4d <progKL+0x1cf>

		write( CHAN_SIO, &ch, 1 );
   18ac4:	83 ec 04             	sub    $0x4,%esp
   18ac7:	6a 01                	push   $0x1
   18ac9:	8d 45 df             	lea    -0x21(%ebp),%eax
   18acc:	50                   	push   %eax
   18acd:	6a 01                	push   $0x1
   18acf:	e8 7c e4 ff ff       	call   16f50 <write>
   18ad4:	83 c4 10             	add    $0x10,%esp

		// second argument to X is 100 plus the iteration number
		usprint( buf, "%d", 100 + i );
   18ad7:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18ada:	83 c0 64             	add    $0x64,%eax
   18add:	83 ec 04             	sub    $0x4,%esp
   18ae0:	50                   	push   %eax
   18ae1:	68 94 bf 01 00       	push   $0x1bf94
   18ae6:	8d 45 bb             	lea    -0x45(%ebp),%eax
   18ae9:	50                   	push   %eax
   18aea:	e8 e3 11 00 00       	call   19cd2 <usprint>
   18aef:	83 c4 10             	add    $0x10,%esp
		int whom = spawn( (uint32_t) progX, arglist );
   18af2:	ba 6d 8b 01 00       	mov    $0x18b6d,%edx
   18af7:	83 ec 08             	sub    $0x8,%esp
   18afa:	8d 45 a8             	lea    -0x58(%ebp),%eax
   18afd:	50                   	push   %eax
   18afe:	52                   	push   %edx
   18aff:	e8 25 18 00 00       	call   1a329 <spawn>
   18b04:	83 c4 10             	add    $0x10,%esp
   18b07:	89 45 e0             	mov    %eax,-0x20(%ebp)
		if( whom < 0 ) {
   18b0a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   18b0e:	79 11                	jns    18b21 <progKL+0x1a3>
			swrites( msg2 );
   18b10:	83 ec 0c             	sub    $0xc,%esp
   18b13:	8d 45 db             	lea    -0x25(%ebp),%eax
   18b16:	50                   	push   %eax
   18b17:	e8 09 19 00 00       	call   1a425 <swrites>
   18b1c:	83 c4 10             	add    $0x10,%esp
   18b1f:	eb 13                	jmp    18b34 <progKL+0x1b6>
		} else {
			write( CHAN_SIO, &ch, 1 );
   18b21:	83 ec 04             	sub    $0x4,%esp
   18b24:	6a 01                	push   $0x1
   18b26:	8d 45 df             	lea    -0x21(%ebp),%eax
   18b29:	50                   	push   %eax
   18b2a:	6a 01                	push   $0x1
   18b2c:	e8 1f e4 ff ff       	call   16f50 <write>
   18b31:	83 c4 10             	add    $0x10,%esp
		}

		sleep( SEC_TO_MS(nap) );
   18b34:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   18b37:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   18b3d:	83 ec 0c             	sub    $0xc,%esp
   18b40:	50                   	push   %eax
   18b41:	e8 42 e4 ff ff       	call   16f88 <sleep>
   18b46:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   18b49:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18b4d:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18b50:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18b53:	0f 8c 6b ff ff ff    	jl     18ac4 <progKL+0x146>
	}

	exit( 0 );
   18b59:	83 ec 0c             	sub    $0xc,%esp
   18b5c:	6a 00                	push   $0x0
   18b5e:	e8 c5 e3 ff ff       	call   16f28 <exit>
   18b63:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18b66:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   18b6b:	c9                   	leave  
   18b6c:	c3                   	ret    

00018b6d <progX>:
** Invoked as:  progX  x  n
**	 where x is the ID character
**		   n is the iteration count
*/

USERMAIN( progX ) {
   18b6d:	55                   	push   %ebp
   18b6e:	89 e5                	mov    %esp,%ebp
   18b70:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18b76:	8b 45 0c             	mov    0xc(%ebp),%eax
   18b79:	8b 00                	mov    (%eax),%eax
   18b7b:	85 c0                	test   %eax,%eax
   18b7d:	74 07                	je     18b86 <progX+0x19>
   18b7f:	8b 45 0c             	mov    0xc(%ebp),%eax
   18b82:	8b 00                	mov    (%eax),%eax
   18b84:	eb 05                	jmp    18b8b <progX+0x1e>
   18b86:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   18b8b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 20;	  // iteration count
   18b8e:	c7 45 f4 14 00 00 00 	movl   $0x14,-0xc(%ebp)
	char ch = 'x';	  // default character to print
   18b95:	c6 45 f3 78          	movb   $0x78,-0xd(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   18b99:	8b 45 08             	mov    0x8(%ebp),%eax
   18b9c:	83 f8 02             	cmp    $0x2,%eax
   18b9f:	74 1e                	je     18bbf <progX+0x52>
   18ba1:	83 f8 03             	cmp    $0x3,%eax
   18ba4:	75 2c                	jne    18bd2 <progX+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   18ba6:	8b 45 0c             	mov    0xc(%ebp),%eax
   18ba9:	83 c0 08             	add    $0x8,%eax
   18bac:	8b 00                	mov    (%eax),%eax
   18bae:	83 ec 08             	sub    $0x8,%esp
   18bb1:	6a 0a                	push   $0xa
   18bb3:	50                   	push   %eax
   18bb4:	e8 8e 13 00 00       	call   19f47 <ustr2int>
   18bb9:	83 c4 10             	add    $0x10,%esp
   18bbc:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18bbf:	8b 45 0c             	mov    0xc(%ebp),%eax
   18bc2:	83 c0 04             	add    $0x4,%eax
   18bc5:	8b 00                	mov    (%eax),%eax
   18bc7:	0f b6 00             	movzbl (%eax),%eax
   18bca:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   18bcd:	e9 a8 00 00 00       	jmp    18c7a <progX+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18bd2:	ff 75 08             	pushl  0x8(%ebp)
   18bd5:	ff 75 e0             	pushl  -0x20(%ebp)
   18bd8:	68 51 be 01 00       	push   $0x1be51
   18bdd:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18be3:	50                   	push   %eax
   18be4:	e8 e9 10 00 00       	call   19cd2 <usprint>
   18be9:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18bec:	83 ec 0c             	sub    $0xc,%esp
   18bef:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18bf5:	50                   	push   %eax
   18bf6:	e8 c4 17 00 00       	call   1a3bf <cwrites>
   18bfb:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18bfe:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18c05:	eb 5b                	jmp    18c62 <progX+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18c07:	8b 45 08             	mov    0x8(%ebp),%eax
   18c0a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18c11:	8b 45 0c             	mov    0xc(%ebp),%eax
   18c14:	01 d0                	add    %edx,%eax
   18c16:	8b 00                	mov    (%eax),%eax
   18c18:	85 c0                	test   %eax,%eax
   18c1a:	74 13                	je     18c2f <progX+0xc2>
   18c1c:	8b 45 08             	mov    0x8(%ebp),%eax
   18c1f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18c26:	8b 45 0c             	mov    0xc(%ebp),%eax
   18c29:	01 d0                	add    %edx,%eax
   18c2b:	8b 00                	mov    (%eax),%eax
   18c2d:	eb 05                	jmp    18c34 <progX+0xc7>
   18c2f:	b8 65 be 01 00       	mov    $0x1be65,%eax
   18c34:	83 ec 04             	sub    $0x4,%esp
   18c37:	50                   	push   %eax
   18c38:	68 6c be 01 00       	push   $0x1be6c
   18c3d:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18c43:	50                   	push   %eax
   18c44:	e8 89 10 00 00       	call   19cd2 <usprint>
   18c49:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   18c4c:	83 ec 0c             	sub    $0xc,%esp
   18c4f:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18c55:	50                   	push   %eax
   18c56:	e8 64 17 00 00       	call   1a3bf <cwrites>
   18c5b:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18c5e:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18c62:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18c65:	3b 45 08             	cmp    0x8(%ebp),%eax
   18c68:	7e 9d                	jle    18c07 <progX+0x9a>
			}
			cwrites( "\n" );
   18c6a:	83 ec 0c             	sub    $0xc,%esp
   18c6d:	68 70 be 01 00       	push   $0x1be70
   18c72:	e8 48 17 00 00       	call   1a3bf <cwrites>
   18c77:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int pid = getpid();
   18c7a:	e8 d9 e2 ff ff       	call   16f58 <getpid>
   18c7f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d]", ch, pid );
   18c82:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   18c86:	ff 75 dc             	pushl  -0x24(%ebp)
   18c89:	50                   	push   %eax
   18c8a:	68 2a bf 01 00       	push   $0x1bf2a
   18c8f:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18c95:	50                   	push   %eax
   18c96:	e8 37 10 00 00       	call   19cd2 <usprint>
   18c9b:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   18c9e:	83 ec 0c             	sub    $0xc,%esp
   18ca1:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18ca7:	50                   	push   %eax
   18ca8:	e8 78 17 00 00       	call   1a425 <swrites>
   18cad:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   18cb0:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18cb7:	eb 2c                	jmp    18ce5 <progX+0x178>
		swrites( buf );
   18cb9:	83 ec 0c             	sub    $0xc,%esp
   18cbc:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18cc2:	50                   	push   %eax
   18cc3:	e8 5d 17 00 00       	call   1a425 <swrites>
   18cc8:	83 c4 10             	add    $0x10,%esp
		DELAY(STD);
   18ccb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   18cd2:	eb 04                	jmp    18cd8 <progX+0x16b>
   18cd4:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   18cd8:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   18cdf:	7e f3                	jle    18cd4 <progX+0x167>
	for( int i = 0; i < count ; ++i ) {
   18ce1:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18ce5:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18ce8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18ceb:	7c cc                	jl     18cb9 <progX+0x14c>
	}

	exit( 12 );
   18ced:	83 ec 0c             	sub    $0xc,%esp
   18cf0:	6a 0c                	push   $0xc
   18cf2:	e8 31 e2 ff ff       	call   16f28 <exit>
   18cf7:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18cfa:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   18cff:	c9                   	leave  
   18d00:	c3                   	ret    

00018d01 <progMN>:
**	 where x is the ID character
**		   n is the iteration count
**		   b is the w&z boolean
*/

USERMAIN( progMN ) {
   18d01:	55                   	push   %ebp
   18d02:	89 e5                	mov    %esp,%ebp
   18d04:	81 ec d8 00 00 00    	sub    $0xd8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18d0a:	8b 45 0c             	mov    0xc(%ebp),%eax
   18d0d:	8b 00                	mov    (%eax),%eax
   18d0f:	85 c0                	test   %eax,%eax
   18d11:	74 07                	je     18d1a <progMN+0x19>
   18d13:	8b 45 0c             	mov    0xc(%ebp),%eax
   18d16:	8b 00                	mov    (%eax),%eax
   18d18:	eb 05                	jmp    18d1f <progMN+0x1e>
   18d1a:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   18d1f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int count = 5;	// default iteration count
   18d22:	c7 45 f4 05 00 00 00 	movl   $0x5,-0xc(%ebp)
	char ch = '5';	// default character to print
   18d29:	c6 45 df 35          	movb   $0x35,-0x21(%ebp)
	int alsoZ = 0;	// also do progZ?
   18d2d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	char msgw[] = "*5w*";
   18d34:	c7 45 da 2a 35 77 2a 	movl   $0x2a77352a,-0x26(%ebp)
   18d3b:	c6 45 de 00          	movb   $0x0,-0x22(%ebp)
	char msgz[] = "*5z*";
   18d3f:	c7 45 d5 2a 35 7a 2a 	movl   $0x2a7a352a,-0x2b(%ebp)
   18d46:	c6 45 d9 00          	movb   $0x0,-0x27(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   18d4a:	8b 45 08             	mov    0x8(%ebp),%eax
   18d4d:	83 f8 03             	cmp    $0x3,%eax
   18d50:	74 22                	je     18d74 <progMN+0x73>
   18d52:	83 f8 04             	cmp    $0x4,%eax
   18d55:	74 07                	je     18d5e <progMN+0x5d>
   18d57:	83 f8 02             	cmp    $0x2,%eax
   18d5a:	74 31                	je     18d8d <progMN+0x8c>
   18d5c:	eb 42                	jmp    18da0 <progMN+0x9f>
	case 4:	alsoZ = argv[3][0] == 't';
   18d5e:	8b 45 0c             	mov    0xc(%ebp),%eax
   18d61:	83 c0 0c             	add    $0xc,%eax
   18d64:	8b 00                	mov    (%eax),%eax
   18d66:	0f b6 00             	movzbl (%eax),%eax
   18d69:	3c 74                	cmp    $0x74,%al
   18d6b:	0f 94 c0             	sete   %al
   18d6e:	0f b6 c0             	movzbl %al,%eax
   18d71:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   18d74:	8b 45 0c             	mov    0xc(%ebp),%eax
   18d77:	83 c0 08             	add    $0x8,%eax
   18d7a:	8b 00                	mov    (%eax),%eax
   18d7c:	83 ec 08             	sub    $0x8,%esp
   18d7f:	6a 0a                	push   $0xa
   18d81:	50                   	push   %eax
   18d82:	e8 c0 11 00 00       	call   19f47 <ustr2int>
   18d87:	83 c4 10             	add    $0x10,%esp
   18d8a:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18d8d:	8b 45 0c             	mov    0xc(%ebp),%eax
   18d90:	83 c0 04             	add    $0x4,%eax
   18d93:	8b 00                	mov    (%eax),%eax
   18d95:	0f b6 00             	movzbl (%eax),%eax
   18d98:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   18d9b:	e9 a8 00 00 00       	jmp    18e48 <progMN+0x147>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18da0:	ff 75 08             	pushl  0x8(%ebp)
   18da3:	ff 75 e4             	pushl  -0x1c(%ebp)
   18da6:	68 51 be 01 00       	push   $0x1be51
   18dab:	8d 85 55 ff ff ff    	lea    -0xab(%ebp),%eax
   18db1:	50                   	push   %eax
   18db2:	e8 1b 0f 00 00       	call   19cd2 <usprint>
   18db7:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18dba:	83 ec 0c             	sub    $0xc,%esp
   18dbd:	8d 85 55 ff ff ff    	lea    -0xab(%ebp),%eax
   18dc3:	50                   	push   %eax
   18dc4:	e8 f6 15 00 00       	call   1a3bf <cwrites>
   18dc9:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18dcc:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18dd3:	eb 5b                	jmp    18e30 <progMN+0x12f>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18dd5:	8b 45 08             	mov    0x8(%ebp),%eax
   18dd8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18ddf:	8b 45 0c             	mov    0xc(%ebp),%eax
   18de2:	01 d0                	add    %edx,%eax
   18de4:	8b 00                	mov    (%eax),%eax
   18de6:	85 c0                	test   %eax,%eax
   18de8:	74 13                	je     18dfd <progMN+0xfc>
   18dea:	8b 45 08             	mov    0x8(%ebp),%eax
   18ded:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18df4:	8b 45 0c             	mov    0xc(%ebp),%eax
   18df7:	01 d0                	add    %edx,%eax
   18df9:	8b 00                	mov    (%eax),%eax
   18dfb:	eb 05                	jmp    18e02 <progMN+0x101>
   18dfd:	b8 65 be 01 00       	mov    $0x1be65,%eax
   18e02:	83 ec 04             	sub    $0x4,%esp
   18e05:	50                   	push   %eax
   18e06:	68 6c be 01 00       	push   $0x1be6c
   18e0b:	8d 85 55 ff ff ff    	lea    -0xab(%ebp),%eax
   18e11:	50                   	push   %eax
   18e12:	e8 bb 0e 00 00       	call   19cd2 <usprint>
   18e17:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   18e1a:	83 ec 0c             	sub    $0xc,%esp
   18e1d:	8d 85 55 ff ff ff    	lea    -0xab(%ebp),%eax
   18e23:	50                   	push   %eax
   18e24:	e8 96 15 00 00       	call   1a3bf <cwrites>
   18e29:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18e2c:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18e30:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18e33:	3b 45 08             	cmp    0x8(%ebp),%eax
   18e36:	7e 9d                	jle    18dd5 <progMN+0xd4>
			}
			cwrites( "\n" );
   18e38:	83 ec 0c             	sub    $0xc,%esp
   18e3b:	68 70 be 01 00       	push   $0x1be70
   18e40:	e8 7a 15 00 00       	call   1a3bf <cwrites>
   18e45:	83 c4 10             	add    $0x10,%esp
	}

	// update the extra message strings
	msgw[1] = msgz[1] = ch;
   18e48:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
   18e4c:	88 45 d6             	mov    %al,-0x2a(%ebp)
   18e4f:	0f b6 45 d6          	movzbl -0x2a(%ebp),%eax
   18e53:	88 45 db             	mov    %al,-0x25(%ebp)

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   18e56:	83 ec 04             	sub    $0x4,%esp
   18e59:	6a 01                	push   $0x1
   18e5b:	8d 45 df             	lea    -0x21(%ebp),%eax
   18e5e:	50                   	push   %eax
   18e5f:	6a 01                	push   $0x1
   18e61:	e8 ea e0 ff ff       	call   16f50 <write>
   18e66:	83 c4 10             	add    $0x10,%esp

	// set up the argument vector(s)

	// W:  15 iterations, 5-second sleep
	char *argsw[] = { "progW", "W", "15", "5", NULL };
   18e69:	c7 85 40 ff ff ff 32 	movl   $0x1bf32,-0xc0(%ebp)
   18e70:	bf 01 00 
   18e73:	c7 85 44 ff ff ff 46 	movl   $0x1bc46,-0xbc(%ebp)
   18e7a:	bc 01 00 
   18e7d:	c7 85 48 ff ff ff 97 	movl   $0x1bf97,-0xb8(%ebp)
   18e84:	bf 01 00 
   18e87:	c7 85 4c ff ff ff f3 	movl   $0x1bbf3,-0xb4(%ebp)
   18e8e:	bb 01 00 
   18e91:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
   18e98:	00 00 00 

	// Z:  15 iterations
	char *argsz[] = { "progZ", "Z", "15", NULL };
   18e9b:	c7 85 30 ff ff ff e9 	movl   $0x1bee9,-0xd0(%ebp)
   18ea2:	be 01 00 
   18ea5:	c7 85 34 ff ff ff ef 	movl   $0x1beef,-0xcc(%ebp)
   18eac:	be 01 00 
   18eaf:	c7 85 38 ff ff ff 97 	movl   $0x1bf97,-0xc8(%ebp)
   18eb6:	bf 01 00 
   18eb9:	c7 85 3c ff ff ff 00 	movl   $0x0,-0xc4(%ebp)
   18ec0:	00 00 00 

	for( int i = 0; i < count; ++i ) {
   18ec3:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18eca:	eb 7d                	jmp    18f49 <progMN+0x248>
		write( CHAN_SIO, &ch, 1 );
   18ecc:	83 ec 04             	sub    $0x4,%esp
   18ecf:	6a 01                	push   $0x1
   18ed1:	8d 45 df             	lea    -0x21(%ebp),%eax
   18ed4:	50                   	push   %eax
   18ed5:	6a 01                	push   $0x1
   18ed7:	e8 74 e0 ff ff       	call   16f50 <write>
   18edc:	83 c4 10             	add    $0x10,%esp
		int whom = spawn( (uint32_t) progW, argsw	);
   18edf:	ba 14 84 01 00       	mov    $0x18414,%edx
   18ee4:	83 ec 08             	sub    $0x8,%esp
   18ee7:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
   18eed:	50                   	push   %eax
   18eee:	52                   	push   %edx
   18eef:	e8 35 14 00 00       	call   1a329 <spawn>
   18ef4:	83 c4 10             	add    $0x10,%esp
   18ef7:	89 45 e0             	mov    %eax,-0x20(%ebp)
		if( whom < 1 ) {
   18efa:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   18efe:	7f 0f                	jg     18f0f <progMN+0x20e>
			swrites( msgw );
   18f00:	83 ec 0c             	sub    $0xc,%esp
   18f03:	8d 45 da             	lea    -0x26(%ebp),%eax
   18f06:	50                   	push   %eax
   18f07:	e8 19 15 00 00       	call   1a425 <swrites>
   18f0c:	83 c4 10             	add    $0x10,%esp
		}
		if( alsoZ ) {
   18f0f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   18f13:	74 30                	je     18f45 <progMN+0x244>
			whom = spawn( (uint32_t) progZ, argsz );
   18f15:	ba da 7e 01 00       	mov    $0x17eda,%edx
   18f1a:	83 ec 08             	sub    $0x8,%esp
   18f1d:	8d 85 30 ff ff ff    	lea    -0xd0(%ebp),%eax
   18f23:	50                   	push   %eax
   18f24:	52                   	push   %edx
   18f25:	e8 ff 13 00 00       	call   1a329 <spawn>
   18f2a:	83 c4 10             	add    $0x10,%esp
   18f2d:	89 45 e0             	mov    %eax,-0x20(%ebp)
			if( whom < 1 ) {
   18f30:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   18f34:	7f 0f                	jg     18f45 <progMN+0x244>
				swrites( msgz );
   18f36:	83 ec 0c             	sub    $0xc,%esp
   18f39:	8d 45 d5             	lea    -0x2b(%ebp),%eax
   18f3c:	50                   	push   %eax
   18f3d:	e8 e3 14 00 00       	call   1a425 <swrites>
   18f42:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   18f45:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18f49:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18f4c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18f4f:	0f 8c 77 ff ff ff    	jl     18ecc <progMN+0x1cb>
			}
		}
	}

	exit( 0 );
   18f55:	83 ec 0c             	sub    $0xc,%esp
   18f58:	6a 00                	push   $0x0
   18f5a:	e8 c9 df ff ff       	call   16f28 <exit>
   18f5f:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18f62:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   18f67:	c9                   	leave  
   18f68:	c3                   	ret    

00018f69 <progP>:
**	 where x is the ID character
**		   n is the iteration count (defaults to 3)
**		   t is the sleep time (defaults to 2 seconds)
*/

USERMAIN( progP ) {
   18f69:	55                   	push   %ebp
   18f6a:	89 e5                	mov    %esp,%ebp
   18f6c:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18f72:	8b 45 0c             	mov    0xc(%ebp),%eax
   18f75:	8b 00                	mov    (%eax),%eax
   18f77:	85 c0                	test   %eax,%eax
   18f79:	74 07                	je     18f82 <progP+0x19>
   18f7b:	8b 45 0c             	mov    0xc(%ebp),%eax
   18f7e:	8b 00                	mov    (%eax),%eax
   18f80:	eb 05                	jmp    18f87 <progP+0x1e>
   18f82:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   18f87:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int count = 3;	  // default iteration count
   18f8a:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
	char ch = 'p';	  // default character to print
   18f91:	c6 45 df 70          	movb   $0x70,-0x21(%ebp)
	int nap = 2;	  // nap time
   18f95:	c7 45 f0 02 00 00 00 	movl   $0x2,-0x10(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   18f9c:	8b 45 08             	mov    0x8(%ebp),%eax
   18f9f:	83 f8 03             	cmp    $0x3,%eax
   18fa2:	74 25                	je     18fc9 <progP+0x60>
   18fa4:	83 f8 04             	cmp    $0x4,%eax
   18fa7:	74 07                	je     18fb0 <progP+0x47>
   18fa9:	83 f8 02             	cmp    $0x2,%eax
   18fac:	74 34                	je     18fe2 <progP+0x79>
   18fae:	eb 45                	jmp    18ff5 <progP+0x8c>
	case 4:	nap = ustr2int( argv[3], 10 );
   18fb0:	8b 45 0c             	mov    0xc(%ebp),%eax
   18fb3:	83 c0 0c             	add    $0xc,%eax
   18fb6:	8b 00                	mov    (%eax),%eax
   18fb8:	83 ec 08             	sub    $0x8,%esp
   18fbb:	6a 0a                	push   $0xa
   18fbd:	50                   	push   %eax
   18fbe:	e8 84 0f 00 00       	call   19f47 <ustr2int>
   18fc3:	83 c4 10             	add    $0x10,%esp
   18fc6:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   18fc9:	8b 45 0c             	mov    0xc(%ebp),%eax
   18fcc:	83 c0 08             	add    $0x8,%eax
   18fcf:	8b 00                	mov    (%eax),%eax
   18fd1:	83 ec 08             	sub    $0x8,%esp
   18fd4:	6a 0a                	push   $0xa
   18fd6:	50                   	push   %eax
   18fd7:	e8 6b 0f 00 00       	call   19f47 <ustr2int>
   18fdc:	83 c4 10             	add    $0x10,%esp
   18fdf:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18fe2:	8b 45 0c             	mov    0xc(%ebp),%eax
   18fe5:	83 c0 04             	add    $0x4,%eax
   18fe8:	8b 00                	mov    (%eax),%eax
   18fea:	0f b6 00             	movzbl (%eax),%eax
   18fed:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   18ff0:	e9 a8 00 00 00       	jmp    1909d <progP+0x134>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18ff5:	ff 75 08             	pushl  0x8(%ebp)
   18ff8:	ff 75 e4             	pushl  -0x1c(%ebp)
   18ffb:	68 51 be 01 00       	push   $0x1be51
   19000:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   19006:	50                   	push   %eax
   19007:	e8 c6 0c 00 00       	call   19cd2 <usprint>
   1900c:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1900f:	83 ec 0c             	sub    $0xc,%esp
   19012:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   19018:	50                   	push   %eax
   19019:	e8 a1 13 00 00       	call   1a3bf <cwrites>
   1901e:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   19021:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   19028:	eb 5b                	jmp    19085 <progP+0x11c>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   1902a:	8b 45 08             	mov    0x8(%ebp),%eax
   1902d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19034:	8b 45 0c             	mov    0xc(%ebp),%eax
   19037:	01 d0                	add    %edx,%eax
   19039:	8b 00                	mov    (%eax),%eax
   1903b:	85 c0                	test   %eax,%eax
   1903d:	74 13                	je     19052 <progP+0xe9>
   1903f:	8b 45 08             	mov    0x8(%ebp),%eax
   19042:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19049:	8b 45 0c             	mov    0xc(%ebp),%eax
   1904c:	01 d0                	add    %edx,%eax
   1904e:	8b 00                	mov    (%eax),%eax
   19050:	eb 05                	jmp    19057 <progP+0xee>
   19052:	b8 65 be 01 00       	mov    $0x1be65,%eax
   19057:	83 ec 04             	sub    $0x4,%esp
   1905a:	50                   	push   %eax
   1905b:	68 6c be 01 00       	push   $0x1be6c
   19060:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   19066:	50                   	push   %eax
   19067:	e8 66 0c 00 00       	call   19cd2 <usprint>
   1906c:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1906f:	83 ec 0c             	sub    $0xc,%esp
   19072:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   19078:	50                   	push   %eax
   19079:	e8 41 13 00 00       	call   1a3bf <cwrites>
   1907e:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   19081:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   19085:	8b 45 ec             	mov    -0x14(%ebp),%eax
   19088:	3b 45 08             	cmp    0x8(%ebp),%eax
   1908b:	7e 9d                	jle    1902a <progP+0xc1>
			}
			cwrites( "\n" );
   1908d:	83 ec 0c             	sub    $0xc,%esp
   19090:	68 70 be 01 00       	push   $0x1be70
   19095:	e8 25 13 00 00       	call   1a3bf <cwrites>
   1909a:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	uint32_t now = gettime();
   1909d:	e8 c6 de ff ff       	call   16f68 <gettime>
   190a2:	89 45 e0             	mov    %eax,-0x20(%ebp)
	usprint( buf, " P@%u", now );
   190a5:	83 ec 04             	sub    $0x4,%esp
   190a8:	ff 75 e0             	pushl  -0x20(%ebp)
   190ab:	68 9a bf 01 00       	push   $0x1bf9a
   190b0:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   190b6:	50                   	push   %eax
   190b7:	e8 16 0c 00 00       	call   19cd2 <usprint>
   190bc:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   190bf:	83 ec 0c             	sub    $0xc,%esp
   190c2:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   190c8:	50                   	push   %eax
   190c9:	e8 57 13 00 00       	call   1a425 <swrites>
   190ce:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count; ++i ) {
   190d1:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   190d8:	eb 2c                	jmp    19106 <progP+0x19d>
		sleep( SEC_TO_MS(nap) );
   190da:	8b 45 f0             	mov    -0x10(%ebp),%eax
   190dd:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   190e3:	83 ec 0c             	sub    $0xc,%esp
   190e6:	50                   	push   %eax
   190e7:	e8 9c de ff ff       	call   16f88 <sleep>
   190ec:	83 c4 10             	add    $0x10,%esp
		write( CHAN_SIO, &ch, 1 );
   190ef:	83 ec 04             	sub    $0x4,%esp
   190f2:	6a 01                	push   $0x1
   190f4:	8d 45 df             	lea    -0x21(%ebp),%eax
   190f7:	50                   	push   %eax
   190f8:	6a 01                	push   $0x1
   190fa:	e8 51 de ff ff       	call   16f50 <write>
   190ff:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   19102:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   19106:	8b 45 e8             	mov    -0x18(%ebp),%eax
   19109:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   1910c:	7c cc                	jl     190da <progP+0x171>
	}

	exit( 0 );
   1910e:	83 ec 0c             	sub    $0xc,%esp
   19111:	6a 00                	push   $0x0
   19113:	e8 10 de ff ff       	call   16f28 <exit>
   19118:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   1911b:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   19120:	c9                   	leave  
   19121:	c3                   	ret    

00019122 <progQ>:
**
** Invoked as:  progQ  x
**	 where x is the ID character
*/

USERMAIN( progQ ) {
   19122:	55                   	push   %ebp
   19123:	89 e5                	mov    %esp,%ebp
   19125:	81 ec 98 00 00 00    	sub    $0x98,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   1912b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1912e:	8b 00                	mov    (%eax),%eax
   19130:	85 c0                	test   %eax,%eax
   19132:	74 07                	je     1913b <progQ+0x19>
   19134:	8b 45 0c             	mov    0xc(%ebp),%eax
   19137:	8b 00                	mov    (%eax),%eax
   19139:	eb 05                	jmp    19140 <progQ+0x1e>
   1913b:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   19140:	89 45 f0             	mov    %eax,-0x10(%ebp)
	char ch = 'q';	  // default character to print
   19143:	c6 45 ef 71          	movb   $0x71,-0x11(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   19147:	8b 45 08             	mov    0x8(%ebp),%eax
   1914a:	83 f8 02             	cmp    $0x2,%eax
   1914d:	75 13                	jne    19162 <progQ+0x40>
	case 2:	ch = argv[1][0];
   1914f:	8b 45 0c             	mov    0xc(%ebp),%eax
   19152:	83 c0 04             	add    $0x4,%eax
   19155:	8b 00                	mov    (%eax),%eax
   19157:	0f b6 00             	movzbl (%eax),%eax
   1915a:	88 45 ef             	mov    %al,-0x11(%ebp)
			break;
   1915d:	e9 a8 00 00 00       	jmp    1920a <progQ+0xe8>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   19162:	ff 75 08             	pushl  0x8(%ebp)
   19165:	ff 75 f0             	pushl  -0x10(%ebp)
   19168:	68 51 be 01 00       	push   $0x1be51
   1916d:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   19173:	50                   	push   %eax
   19174:	e8 59 0b 00 00       	call   19cd2 <usprint>
   19179:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1917c:	83 ec 0c             	sub    $0xc,%esp
   1917f:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   19185:	50                   	push   %eax
   19186:	e8 34 12 00 00       	call   1a3bf <cwrites>
   1918b:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1918e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   19195:	eb 5b                	jmp    191f2 <progQ+0xd0>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   19197:	8b 45 08             	mov    0x8(%ebp),%eax
   1919a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   191a1:	8b 45 0c             	mov    0xc(%ebp),%eax
   191a4:	01 d0                	add    %edx,%eax
   191a6:	8b 00                	mov    (%eax),%eax
   191a8:	85 c0                	test   %eax,%eax
   191aa:	74 13                	je     191bf <progQ+0x9d>
   191ac:	8b 45 08             	mov    0x8(%ebp),%eax
   191af:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   191b6:	8b 45 0c             	mov    0xc(%ebp),%eax
   191b9:	01 d0                	add    %edx,%eax
   191bb:	8b 00                	mov    (%eax),%eax
   191bd:	eb 05                	jmp    191c4 <progQ+0xa2>
   191bf:	b8 65 be 01 00       	mov    $0x1be65,%eax
   191c4:	83 ec 04             	sub    $0x4,%esp
   191c7:	50                   	push   %eax
   191c8:	68 6c be 01 00       	push   $0x1be6c
   191cd:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   191d3:	50                   	push   %eax
   191d4:	e8 f9 0a 00 00       	call   19cd2 <usprint>
   191d9:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   191dc:	83 ec 0c             	sub    $0xc,%esp
   191df:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   191e5:	50                   	push   %eax
   191e6:	e8 d4 11 00 00       	call   1a3bf <cwrites>
   191eb:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   191ee:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   191f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
   191f5:	3b 45 08             	cmp    0x8(%ebp),%eax
   191f8:	7e 9d                	jle    19197 <progQ+0x75>
			}
			cwrites( "\n" );
   191fa:	83 ec 0c             	sub    $0xc,%esp
   191fd:	68 70 be 01 00       	push   $0x1be70
   19202:	e8 b8 11 00 00       	call   1a3bf <cwrites>
   19207:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   1920a:	83 ec 04             	sub    $0x4,%esp
   1920d:	6a 01                	push   $0x1
   1920f:	8d 45 ef             	lea    -0x11(%ebp),%eax
   19212:	50                   	push   %eax
   19213:	6a 01                	push   $0x1
   19215:	e8 36 dd ff ff       	call   16f50 <write>
   1921a:	83 c4 10             	add    $0x10,%esp

	// try something weird
	bogus();
   1921d:	e8 6e dd ff ff       	call   16f90 <bogus>

	// should not have come back here!
	usprint( buf, "!!!!! %c returned from bogus syscall!?!?!\n", ch );
   19222:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
   19226:	0f be c0             	movsbl %al,%eax
   19229:	83 ec 04             	sub    $0x4,%esp
   1922c:	50                   	push   %eax
   1922d:	68 a0 bf 01 00       	push   $0x1bfa0
   19232:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   19238:	50                   	push   %eax
   19239:	e8 94 0a 00 00       	call   19cd2 <usprint>
   1923e:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   19241:	83 ec 0c             	sub    $0xc,%esp
   19244:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   1924a:	50                   	push   %eax
   1924b:	e8 6f 11 00 00       	call   1a3bf <cwrites>
   19250:	83 c4 10             	add    $0x10,%esp

	exit( 1 );
   19253:	83 ec 0c             	sub    $0xc,%esp
   19256:	6a 01                	push   $0x1
   19258:	e8 cb dc ff ff       	call   16f28 <exit>
   1925d:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   19260:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   19265:	c9                   	leave  
   19266:	c3                   	ret    

00019267 <progR>:
**	 where x is the ID character
**		   n is the sequence number of the initial incarnation
**		   s is the initial delay time (defaults to 10)
*/

USERMAIN( progR ) {
   19267:	55                   	push   %ebp
   19268:	89 e5                	mov    %esp,%ebp
   1926a:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   19270:	8b 45 0c             	mov    0xc(%ebp),%eax
   19273:	8b 00                	mov    (%eax),%eax
   19275:	85 c0                	test   %eax,%eax
   19277:	74 07                	je     19280 <progR+0x19>
   19279:	8b 45 0c             	mov    0xc(%ebp),%eax
   1927c:	8b 00                	mov    (%eax),%eax
   1927e:	eb 05                	jmp    19285 <progR+0x1e>
   19280:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   19285:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	char ch = 'r';	// default character to print
   19288:	c6 45 f7 72          	movb   $0x72,-0x9(%ebp)
	int delay = 10;	// initial delay count
   1928c:	c7 45 f0 0a 00 00 00 	movl   $0xa,-0x10(%ebp)
	int seq = 99;	// my sequence number
   19293:	c7 45 ec 63 00 00 00 	movl   $0x63,-0x14(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   1929a:	8b 45 08             	mov    0x8(%ebp),%eax
   1929d:	83 f8 03             	cmp    $0x3,%eax
   192a0:	74 25                	je     192c7 <progR+0x60>
   192a2:	83 f8 04             	cmp    $0x4,%eax
   192a5:	74 07                	je     192ae <progR+0x47>
   192a7:	83 f8 02             	cmp    $0x2,%eax
   192aa:	74 34                	je     192e0 <progR+0x79>
   192ac:	eb 45                	jmp    192f3 <progR+0x8c>
	case 4:	delay = ustr2int( argv[3], 10 );
   192ae:	8b 45 0c             	mov    0xc(%ebp),%eax
   192b1:	83 c0 0c             	add    $0xc,%eax
   192b4:	8b 00                	mov    (%eax),%eax
   192b6:	83 ec 08             	sub    $0x8,%esp
   192b9:	6a 0a                	push   $0xa
   192bb:	50                   	push   %eax
   192bc:	e8 86 0c 00 00       	call   19f47 <ustr2int>
   192c1:	83 c4 10             	add    $0x10,%esp
   192c4:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	seq = ustr2int( argv[2], 10 );
   192c7:	8b 45 0c             	mov    0xc(%ebp),%eax
   192ca:	83 c0 08             	add    $0x8,%eax
   192cd:	8b 00                	mov    (%eax),%eax
   192cf:	83 ec 08             	sub    $0x8,%esp
   192d2:	6a 0a                	push   $0xa
   192d4:	50                   	push   %eax
   192d5:	e8 6d 0c 00 00       	call   19f47 <ustr2int>
   192da:	83 c4 10             	add    $0x10,%esp
   192dd:	89 45 ec             	mov    %eax,-0x14(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   192e0:	8b 45 0c             	mov    0xc(%ebp),%eax
   192e3:	83 c0 04             	add    $0x4,%eax
   192e6:	8b 00                	mov    (%eax),%eax
   192e8:	0f b6 00             	movzbl (%eax),%eax
   192eb:	88 45 f7             	mov    %al,-0x9(%ebp)
			break;
   192ee:	e9 a8 00 00 00       	jmp    1939b <progR+0x134>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   192f3:	ff 75 08             	pushl  0x8(%ebp)
   192f6:	ff 75 e4             	pushl  -0x1c(%ebp)
   192f9:	68 51 be 01 00       	push   $0x1be51
   192fe:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19304:	50                   	push   %eax
   19305:	e8 c8 09 00 00       	call   19cd2 <usprint>
   1930a:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1930d:	83 ec 0c             	sub    $0xc,%esp
   19310:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19316:	50                   	push   %eax
   19317:	e8 a3 10 00 00       	call   1a3bf <cwrites>
   1931c:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1931f:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   19326:	eb 5b                	jmp    19383 <progR+0x11c>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   19328:	8b 45 08             	mov    0x8(%ebp),%eax
   1932b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19332:	8b 45 0c             	mov    0xc(%ebp),%eax
   19335:	01 d0                	add    %edx,%eax
   19337:	8b 00                	mov    (%eax),%eax
   19339:	85 c0                	test   %eax,%eax
   1933b:	74 13                	je     19350 <progR+0xe9>
   1933d:	8b 45 08             	mov    0x8(%ebp),%eax
   19340:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19347:	8b 45 0c             	mov    0xc(%ebp),%eax
   1934a:	01 d0                	add    %edx,%eax
   1934c:	8b 00                	mov    (%eax),%eax
   1934e:	eb 05                	jmp    19355 <progR+0xee>
   19350:	b8 65 be 01 00       	mov    $0x1be65,%eax
   19355:	83 ec 04             	sub    $0x4,%esp
   19358:	50                   	push   %eax
   19359:	68 6c be 01 00       	push   $0x1be6c
   1935e:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19364:	50                   	push   %eax
   19365:	e8 68 09 00 00       	call   19cd2 <usprint>
   1936a:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1936d:	83 ec 0c             	sub    $0xc,%esp
   19370:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19376:	50                   	push   %eax
   19377:	e8 43 10 00 00       	call   1a3bf <cwrites>
   1937c:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1937f:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   19383:	8b 45 e8             	mov    -0x18(%ebp),%eax
   19386:	3b 45 08             	cmp    0x8(%ebp),%eax
   19389:	7e 9d                	jle    19328 <progR+0xc1>
			}
			cwrites( "\n" );
   1938b:	83 ec 0c             	sub    $0xc,%esp
   1938e:	68 70 be 01 00       	push   $0x1be70
   19393:	e8 27 10 00 00       	call   1a3bf <cwrites>
   19398:	83 c4 10             	add    $0x10,%esp
	int32_t ppid;

 restart:

	// announce our presence
	pid = getpid();
   1939b:	e8 b8 db ff ff       	call   16f58 <getpid>
   193a0:	89 45 e0             	mov    %eax,-0x20(%ebp)
	ppid = getppid();
   193a3:	e8 b8 db ff ff       	call   16f60 <getppid>
   193a8:	89 45 dc             	mov    %eax,-0x24(%ebp)

	usprint( buf, " %c[%d,%d,%d]", ch, seq, pid, ppid );
   193ab:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
   193af:	83 ec 08             	sub    $0x8,%esp
   193b2:	ff 75 dc             	pushl  -0x24(%ebp)
   193b5:	ff 75 e0             	pushl  -0x20(%ebp)
   193b8:	ff 75 ec             	pushl  -0x14(%ebp)
   193bb:	50                   	push   %eax
   193bc:	68 cb bf 01 00       	push   $0x1bfcb
   193c1:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   193c7:	50                   	push   %eax
   193c8:	e8 05 09 00 00       	call   19cd2 <usprint>
   193cd:	83 c4 20             	add    $0x20,%esp
	swrites( buf );
   193d0:	83 ec 0c             	sub    $0xc,%esp
   193d3:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   193d9:	50                   	push   %eax
   193da:	e8 46 10 00 00       	call   1a425 <swrites>
   193df:	83 c4 10             	add    $0x10,%esp

	sleep( SEC_TO_MS(delay) );
   193e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
   193e5:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   193eb:	83 ec 0c             	sub    $0xc,%esp
   193ee:	50                   	push   %eax
   193ef:	e8 94 db ff ff       	call   16f88 <sleep>
   193f4:	83 c4 10             	add    $0x10,%esp

	// create the next child in sequence
	if( seq < 5 ) {
   193f7:	83 7d ec 04          	cmpl   $0x4,-0x14(%ebp)
   193fb:	7f 63                	jg     19460 <progR+0x1f9>
		++seq;
   193fd:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
		int32_t n = fork();
   19401:	e8 32 db ff ff       	call   16f38 <fork>
   19406:	89 45 d8             	mov    %eax,-0x28(%ebp)
		switch( n ) {
   19409:	8b 45 d8             	mov    -0x28(%ebp),%eax
   1940c:	83 f8 ff             	cmp    $0xffffffff,%eax
   1940f:	74 06                	je     19417 <progR+0x1b0>
   19411:	85 c0                	test   %eax,%eax
   19413:	74 86                	je     1939b <progR+0x134>
   19415:	eb 2e                	jmp    19445 <progR+0x1de>
		case -1:
			// failure?
			usprint( buf, "** R[%d] fork code %d\n", pid, n );
   19417:	ff 75 d8             	pushl  -0x28(%ebp)
   1941a:	ff 75 e0             	pushl  -0x20(%ebp)
   1941d:	68 d9 bf 01 00       	push   $0x1bfd9
   19422:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19428:	50                   	push   %eax
   19429:	e8 a4 08 00 00       	call   19cd2 <usprint>
   1942e:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   19431:	83 ec 0c             	sub    $0xc,%esp
   19434:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   1943a:	50                   	push   %eax
   1943b:	e8 7f 0f 00 00       	call   1a3bf <cwrites>
   19440:	83 c4 10             	add    $0x10,%esp
			break;
   19443:	eb 1c                	jmp    19461 <progR+0x1fa>
		case 0:
			// child
			goto restart;
		default:
			// parent
			--seq;
   19445:	83 6d ec 01          	subl   $0x1,-0x14(%ebp)
			sleep( SEC_TO_MS(delay) );
   19449:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1944c:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   19452:	83 ec 0c             	sub    $0xc,%esp
   19455:	50                   	push   %eax
   19456:	e8 2d db ff ff       	call   16f88 <sleep>
   1945b:	83 c4 10             	add    $0x10,%esp
   1945e:	eb 01                	jmp    19461 <progR+0x1fa>
		}
	}
   19460:	90                   	nop

	// final report - PPID may change, but PID and seq shouldn't
	pid = getpid();
   19461:	e8 f2 da ff ff       	call   16f58 <getpid>
   19466:	89 45 e0             	mov    %eax,-0x20(%ebp)
	ppid = getppid();
   19469:	e8 f2 da ff ff       	call   16f60 <getppid>
   1946e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d,%d,%d]", ch, seq, pid, ppid );
   19471:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
   19475:	83 ec 08             	sub    $0x8,%esp
   19478:	ff 75 dc             	pushl  -0x24(%ebp)
   1947b:	ff 75 e0             	pushl  -0x20(%ebp)
   1947e:	ff 75 ec             	pushl  -0x14(%ebp)
   19481:	50                   	push   %eax
   19482:	68 cb bf 01 00       	push   $0x1bfcb
   19487:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   1948d:	50                   	push   %eax
   1948e:	e8 3f 08 00 00       	call   19cd2 <usprint>
   19493:	83 c4 20             	add    $0x20,%esp
	swrites( buf );
   19496:	83 ec 0c             	sub    $0xc,%esp
   19499:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   1949f:	50                   	push   %eax
   194a0:	e8 80 0f 00 00       	call   1a425 <swrites>
   194a5:	83 c4 10             	add    $0x10,%esp

	exit( 0 );
   194a8:	83 ec 0c             	sub    $0xc,%esp
   194ab:	6a 00                	push   $0x0
   194ad:	e8 76 da ff ff       	call   16f28 <exit>
   194b2:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   194b5:	b8 2a 00 00 00       	mov    $0x2a,%eax

}
   194ba:	c9                   	leave  
   194bb:	c3                   	ret    

000194bc <progS>:
** Invoked as:  progS  x  [ s ]
**	 where x is the ID character
**		   s is the sleep time (defaults to 20)
*/

USERMAIN( progS ) {
   194bc:	55                   	push   %ebp
   194bd:	89 e5                	mov    %esp,%ebp
   194bf:	81 ec 98 00 00 00    	sub    $0x98,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   194c5:	8b 45 0c             	mov    0xc(%ebp),%eax
   194c8:	8b 00                	mov    (%eax),%eax
   194ca:	85 c0                	test   %eax,%eax
   194cc:	74 07                	je     194d5 <progS+0x19>
   194ce:	8b 45 0c             	mov    0xc(%ebp),%eax
   194d1:	8b 00                	mov    (%eax),%eax
   194d3:	eb 05                	jmp    194da <progS+0x1e>
   194d5:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   194da:	89 45 ec             	mov    %eax,-0x14(%ebp)
	char ch = 's';	  // default character to print
   194dd:	c6 45 eb 73          	movb   $0x73,-0x15(%ebp)
	int nap = 20;	  // nap time
   194e1:	c7 45 f4 14 00 00 00 	movl   $0x14,-0xc(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   194e8:	8b 45 08             	mov    0x8(%ebp),%eax
   194eb:	83 f8 02             	cmp    $0x2,%eax
   194ee:	74 1e                	je     1950e <progS+0x52>
   194f0:	83 f8 03             	cmp    $0x3,%eax
   194f3:	75 2c                	jne    19521 <progS+0x65>
	case 3:	nap = ustr2int( argv[2], 10 );
   194f5:	8b 45 0c             	mov    0xc(%ebp),%eax
   194f8:	83 c0 08             	add    $0x8,%eax
   194fb:	8b 00                	mov    (%eax),%eax
   194fd:	83 ec 08             	sub    $0x8,%esp
   19500:	6a 0a                	push   $0xa
   19502:	50                   	push   %eax
   19503:	e8 3f 0a 00 00       	call   19f47 <ustr2int>
   19508:	83 c4 10             	add    $0x10,%esp
   1950b:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   1950e:	8b 45 0c             	mov    0xc(%ebp),%eax
   19511:	83 c0 04             	add    $0x4,%eax
   19514:	8b 00                	mov    (%eax),%eax
   19516:	0f b6 00             	movzbl (%eax),%eax
   19519:	88 45 eb             	mov    %al,-0x15(%ebp)
			break;
   1951c:	e9 a8 00 00 00       	jmp    195c9 <progS+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   19521:	ff 75 08             	pushl  0x8(%ebp)
   19524:	ff 75 ec             	pushl  -0x14(%ebp)
   19527:	68 51 be 01 00       	push   $0x1be51
   1952c:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   19532:	50                   	push   %eax
   19533:	e8 9a 07 00 00       	call   19cd2 <usprint>
   19538:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1953b:	83 ec 0c             	sub    $0xc,%esp
   1953e:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   19544:	50                   	push   %eax
   19545:	e8 75 0e 00 00       	call   1a3bf <cwrites>
   1954a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1954d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   19554:	eb 5b                	jmp    195b1 <progS+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   19556:	8b 45 08             	mov    0x8(%ebp),%eax
   19559:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19560:	8b 45 0c             	mov    0xc(%ebp),%eax
   19563:	01 d0                	add    %edx,%eax
   19565:	8b 00                	mov    (%eax),%eax
   19567:	85 c0                	test   %eax,%eax
   19569:	74 13                	je     1957e <progS+0xc2>
   1956b:	8b 45 08             	mov    0x8(%ebp),%eax
   1956e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19575:	8b 45 0c             	mov    0xc(%ebp),%eax
   19578:	01 d0                	add    %edx,%eax
   1957a:	8b 00                	mov    (%eax),%eax
   1957c:	eb 05                	jmp    19583 <progS+0xc7>
   1957e:	b8 65 be 01 00       	mov    $0x1be65,%eax
   19583:	83 ec 04             	sub    $0x4,%esp
   19586:	50                   	push   %eax
   19587:	68 6c be 01 00       	push   $0x1be6c
   1958c:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   19592:	50                   	push   %eax
   19593:	e8 3a 07 00 00       	call   19cd2 <usprint>
   19598:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1959b:	83 ec 0c             	sub    $0xc,%esp
   1959e:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   195a4:	50                   	push   %eax
   195a5:	e8 15 0e 00 00       	call   1a3bf <cwrites>
   195aa:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   195ad:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   195b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
   195b4:	3b 45 08             	cmp    0x8(%ebp),%eax
   195b7:	7e 9d                	jle    19556 <progS+0x9a>
			}
			cwrites( "\n" );
   195b9:	83 ec 0c             	sub    $0xc,%esp
   195bc:	68 70 be 01 00       	push   $0x1be70
   195c1:	e8 f9 0d 00 00       	call   1a3bf <cwrites>
   195c6:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   195c9:	83 ec 04             	sub    $0x4,%esp
   195cc:	6a 01                	push   $0x1
   195ce:	8d 45 eb             	lea    -0x15(%ebp),%eax
   195d1:	50                   	push   %eax
   195d2:	6a 01                	push   $0x1
   195d4:	e8 77 d9 ff ff       	call   16f50 <write>
   195d9:	83 c4 10             	add    $0x10,%esp

	usprint( buf, "%s sleeping %d(%d)\n", name, nap, SEC_TO_MS(nap) );
   195dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
   195df:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   195e5:	83 ec 0c             	sub    $0xc,%esp
   195e8:	50                   	push   %eax
   195e9:	ff 75 f4             	pushl  -0xc(%ebp)
   195ec:	ff 75 ec             	pushl  -0x14(%ebp)
   195ef:	68 f0 bf 01 00       	push   $0x1bff0
   195f4:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   195fa:	50                   	push   %eax
   195fb:	e8 d2 06 00 00       	call   19cd2 <usprint>
   19600:	83 c4 20             	add    $0x20,%esp
	cwrites( buf );
   19603:	83 ec 0c             	sub    $0xc,%esp
   19606:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   1960c:	50                   	push   %eax
   1960d:	e8 ad 0d 00 00       	call   1a3bf <cwrites>
   19612:	83 c4 10             	add    $0x10,%esp

	for(;;) {
		sleep( SEC_TO_MS(nap) );
   19615:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19618:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   1961e:	83 ec 0c             	sub    $0xc,%esp
   19621:	50                   	push   %eax
   19622:	e8 61 d9 ff ff       	call   16f88 <sleep>
   19627:	83 c4 10             	add    $0x10,%esp
		write( CHAN_SIO, &ch, 1 );
   1962a:	83 ec 04             	sub    $0x4,%esp
   1962d:	6a 01                	push   $0x1
   1962f:	8d 45 eb             	lea    -0x15(%ebp),%eax
   19632:	50                   	push   %eax
   19633:	6a 01                	push   $0x1
   19635:	e8 16 d9 ff ff       	call   16f50 <write>
   1963a:	83 c4 10             	add    $0x10,%esp
		sleep( SEC_TO_MS(nap) );
   1963d:	eb d6                	jmp    19615 <progS+0x159>

0001963f <progTUV>:

#ifndef MAX_CHILDREN
#define MAX_CHILDREN	50
#endif

USERMAIN( progTUV ) {
   1963f:	55                   	push   %ebp
   19640:	89 e5                	mov    %esp,%ebp
   19642:	81 ec a8 01 00 00    	sub    $0x1a8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   19648:	8b 45 0c             	mov    0xc(%ebp),%eax
   1964b:	8b 00                	mov    (%eax),%eax
   1964d:	85 c0                	test   %eax,%eax
   1964f:	74 07                	je     19658 <progTUV+0x19>
   19651:	8b 45 0c             	mov    0xc(%ebp),%eax
   19654:	8b 00                	mov    (%eax),%eax
   19656:	eb 05                	jmp    1965d <progTUV+0x1e>
   19658:	b8 68 bb 01 00       	mov    $0x1bb68,%eax
   1965d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	int count = 3;			// default child count
   19660:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
	char ch = '6';			// default character to print
   19667:	c6 45 c7 36          	movb   $0x36,-0x39(%ebp)
	int nap = 8;			// nap time
   1966b:	c7 45 cc 08 00 00 00 	movl   $0x8,-0x34(%ebp)
	bool_t waiting = true;	// default is waiting by PID
   19672:	c6 45 f3 01          	movb   $0x1,-0xd(%ebp)
	bool_t bypid = true;
   19676:	c6 45 f2 01          	movb   $0x1,-0xe(%ebp)
	char buf[128];
	uint_t children[MAX_CHILDREN];
	int nkids = 0;
   1967a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	char ch2[] = "*?*";
   19681:	c7 85 78 fe ff ff 2a 	movl   $0x2a3f2a,-0x188(%ebp)
   19688:	3f 2a 00 

	// process the command-line arguments
	switch( argc ) {
   1968b:	8b 45 08             	mov    0x8(%ebp),%eax
   1968e:	83 f8 03             	cmp    $0x3,%eax
   19691:	74 32                	je     196c5 <progTUV+0x86>
   19693:	83 f8 04             	cmp    $0x4,%eax
   19696:	74 07                	je     1969f <progTUV+0x60>
   19698:	83 f8 02             	cmp    $0x2,%eax
   1969b:	74 41                	je     196de <progTUV+0x9f>
   1969d:	eb 52                	jmp    196f1 <progTUV+0xb2>
	case 4:	waiting = argv[3][0] != 'k';	// 'w'/'W' -> wait, else -> kill
   1969f:	8b 45 0c             	mov    0xc(%ebp),%eax
   196a2:	83 c0 0c             	add    $0xc,%eax
   196a5:	8b 00                	mov    (%eax),%eax
   196a7:	0f b6 00             	movzbl (%eax),%eax
   196aa:	3c 6b                	cmp    $0x6b,%al
   196ac:	0f 95 c0             	setne  %al
   196af:	88 45 f3             	mov    %al,-0xd(%ebp)
			bypid   = argv[3][0] != 'w';	// 'W'/'k' -> by PID
   196b2:	8b 45 0c             	mov    0xc(%ebp),%eax
   196b5:	83 c0 0c             	add    $0xc,%eax
   196b8:	8b 00                	mov    (%eax),%eax
   196ba:	0f b6 00             	movzbl (%eax),%eax
   196bd:	3c 77                	cmp    $0x77,%al
   196bf:	0f 95 c0             	setne  %al
   196c2:	88 45 f2             	mov    %al,-0xe(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   196c5:	8b 45 0c             	mov    0xc(%ebp),%eax
   196c8:	83 c0 08             	add    $0x8,%eax
   196cb:	8b 00                	mov    (%eax),%eax
   196cd:	83 ec 08             	sub    $0x8,%esp
   196d0:	6a 0a                	push   $0xa
   196d2:	50                   	push   %eax
   196d3:	e8 6f 08 00 00       	call   19f47 <ustr2int>
   196d8:	83 c4 10             	add    $0x10,%esp
   196db:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   196de:	8b 45 0c             	mov    0xc(%ebp),%eax
   196e1:	83 c0 04             	add    $0x4,%eax
   196e4:	8b 00                	mov    (%eax),%eax
   196e6:	0f b6 00             	movzbl (%eax),%eax
   196e9:	88 45 c7             	mov    %al,-0x39(%ebp)
			break;
   196ec:	e9 a8 00 00 00       	jmp    19799 <progTUV+0x15a>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   196f1:	ff 75 08             	pushl  0x8(%ebp)
   196f4:	ff 75 d0             	pushl  -0x30(%ebp)
   196f7:	68 51 be 01 00       	push   $0x1be51
   196fc:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19702:	50                   	push   %eax
   19703:	e8 ca 05 00 00       	call   19cd2 <usprint>
   19708:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1970b:	83 ec 0c             	sub    $0xc,%esp
   1970e:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19714:	50                   	push   %eax
   19715:	e8 a5 0c 00 00       	call   1a3bf <cwrites>
   1971a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1971d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   19724:	eb 5b                	jmp    19781 <progTUV+0x142>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   19726:	8b 45 08             	mov    0x8(%ebp),%eax
   19729:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19730:	8b 45 0c             	mov    0xc(%ebp),%eax
   19733:	01 d0                	add    %edx,%eax
   19735:	8b 00                	mov    (%eax),%eax
   19737:	85 c0                	test   %eax,%eax
   19739:	74 13                	je     1974e <progTUV+0x10f>
   1973b:	8b 45 08             	mov    0x8(%ebp),%eax
   1973e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19745:	8b 45 0c             	mov    0xc(%ebp),%eax
   19748:	01 d0                	add    %edx,%eax
   1974a:	8b 00                	mov    (%eax),%eax
   1974c:	eb 05                	jmp    19753 <progTUV+0x114>
   1974e:	b8 65 be 01 00       	mov    $0x1be65,%eax
   19753:	83 ec 04             	sub    $0x4,%esp
   19756:	50                   	push   %eax
   19757:	68 6c be 01 00       	push   $0x1be6c
   1975c:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19762:	50                   	push   %eax
   19763:	e8 6a 05 00 00       	call   19cd2 <usprint>
   19768:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1976b:	83 ec 0c             	sub    $0xc,%esp
   1976e:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19774:	50                   	push   %eax
   19775:	e8 45 0c 00 00       	call   1a3bf <cwrites>
   1977a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1977d:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   19781:	8b 45 e8             	mov    -0x18(%ebp),%eax
   19784:	3b 45 08             	cmp    0x8(%ebp),%eax
   19787:	7e 9d                	jle    19726 <progTUV+0xe7>
			}
			cwrites( "\n" );
   19789:	83 ec 0c             	sub    $0xc,%esp
   1978c:	68 70 be 01 00       	push   $0x1be70
   19791:	e8 29 0c 00 00       	call   1a3bf <cwrites>
   19796:	83 c4 10             	add    $0x10,%esp
	}

	// fix the secondary output message (for indicating errors)
	ch2[1] = ch;
   19799:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   1979d:	88 85 79 fe ff ff    	mov    %al,-0x187(%ebp)

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   197a3:	83 ec 04             	sub    $0x4,%esp
   197a6:	6a 01                	push   $0x1
   197a8:	8d 45 c7             	lea    -0x39(%ebp),%eax
   197ab:	50                   	push   %eax
   197ac:	6a 01                	push   $0x1
   197ae:	e8 9d d7 ff ff       	call   16f50 <write>
   197b3:	83 c4 10             	add    $0x10,%esp

	// set up the argument vector
	char *argsw[] = { "progW", "W", "10", "5", NULL };
   197b6:	c7 85 64 fe ff ff 32 	movl   $0x1bf32,-0x19c(%ebp)
   197bd:	bf 01 00 
   197c0:	c7 85 68 fe ff ff 46 	movl   $0x1bc46,-0x198(%ebp)
   197c7:	bc 01 00 
   197ca:	c7 85 6c fe ff ff c4 	movl   $0x1bbc4,-0x194(%ebp)
   197d1:	bb 01 00 
   197d4:	c7 85 70 fe ff ff f3 	movl   $0x1bbf3,-0x190(%ebp)
   197db:	bb 01 00 
   197de:	c7 85 74 fe ff ff 00 	movl   $0x0,-0x18c(%ebp)
   197e5:	00 00 00 

	for( int i = 0; i < count; ++i ) {
   197e8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   197ef:	eb 4c                	jmp    1983d <progTUV+0x1fe>
		int whom = spawn( (uint32_t) progW, argsw );
   197f1:	ba 14 84 01 00       	mov    $0x18414,%edx
   197f6:	83 ec 08             	sub    $0x8,%esp
   197f9:	8d 85 64 fe ff ff    	lea    -0x19c(%ebp),%eax
   197ff:	50                   	push   %eax
   19800:	52                   	push   %edx
   19801:	e8 23 0b 00 00       	call   1a329 <spawn>
   19806:	83 c4 10             	add    $0x10,%esp
   19809:	89 45 c8             	mov    %eax,-0x38(%ebp)
		if( whom < 0 ) {
   1980c:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
   19810:	79 14                	jns    19826 <progTUV+0x1e7>
			swrites( ch2 );
   19812:	83 ec 0c             	sub    $0xc,%esp
   19815:	8d 85 78 fe ff ff    	lea    -0x188(%ebp),%eax
   1981b:	50                   	push   %eax
   1981c:	e8 04 0c 00 00       	call   1a425 <swrites>
   19821:	83 c4 10             	add    $0x10,%esp
   19824:	eb 13                	jmp    19839 <progTUV+0x1fa>
		} else {
			children[nkids++] = whom;
   19826:	8b 45 ec             	mov    -0x14(%ebp),%eax
   19829:	8d 50 01             	lea    0x1(%eax),%edx
   1982c:	89 55 ec             	mov    %edx,-0x14(%ebp)
   1982f:	8b 55 c8             	mov    -0x38(%ebp),%edx
   19832:	89 94 85 7c fe ff ff 	mov    %edx,-0x184(%ebp,%eax,4)
	for( int i = 0; i < count; ++i ) {
   19839:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   1983d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   19840:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   19843:	7c ac                	jl     197f1 <progTUV+0x1b2>
		}
	}

	// let the children start
	sleep( SEC_TO_MS(nap) );
   19845:	8b 45 cc             	mov    -0x34(%ebp),%eax
   19848:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   1984e:	83 ec 0c             	sub    $0xc,%esp
   19851:	50                   	push   %eax
   19852:	e8 31 d7 ff ff       	call   16f88 <sleep>
   19857:	83 c4 10             	add    $0x10,%esp

	// collect exit status information

	// current child index
	int n = 0;
   1985a:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	do {
		int this;
		int32_t status;

		// are we waiting for or killing it?
		if( waiting ) {
   19861:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   19865:	74 2f                	je     19896 <progTUV+0x257>
			this = waitpid( bypid ? children[n] : 0, &status );
   19867:	80 7d f2 00          	cmpb   $0x0,-0xe(%ebp)
   1986b:	74 0c                	je     19879 <progTUV+0x23a>
   1986d:	8b 45 e0             	mov    -0x20(%ebp),%eax
   19870:	8b 84 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%eax
   19877:	eb 05                	jmp    1987e <progTUV+0x23f>
   19879:	b8 00 00 00 00       	mov    $0x0,%eax
   1987e:	83 ec 08             	sub    $0x8,%esp
   19881:	8d 95 60 fe ff ff    	lea    -0x1a0(%ebp),%edx
   19887:	52                   	push   %edx
   19888:	50                   	push   %eax
   19889:	e8 a2 d6 ff ff       	call   16f30 <waitpid>
   1988e:	83 c4 10             	add    $0x10,%esp
   19891:	89 45 dc             	mov    %eax,-0x24(%ebp)
   19894:	eb 19                	jmp    198af <progTUV+0x270>
		} else {
			// always by PID
			this = kill( children[n] );
   19896:	8b 45 e0             	mov    -0x20(%ebp),%eax
   19899:	8b 84 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%eax
   198a0:	83 ec 0c             	sub    $0xc,%esp
   198a3:	50                   	push   %eax
   198a4:	e8 d7 d6 ff ff       	call   16f80 <kill>
   198a9:	83 c4 10             	add    $0x10,%esp
   198ac:	89 45 dc             	mov    %eax,-0x24(%ebp)
		}

		// what was the result?
		if( this < SUCCESS ) {
   198af:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   198b3:	0f 89 a1 00 00 00    	jns    1995a <progTUV+0x31b>

			// uh-oh - something went wrong

			// "no children" means we're all done
			if( this != E_NO_CHILDREN ) {
   198b9:	83 7d dc fc          	cmpl   $0xfffffffc,-0x24(%ebp)
   198bd:	74 77                	je     19936 <progTUV+0x2f7>
				if( waiting ) {
   198bf:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   198c3:	74 3f                	je     19904 <progTUV+0x2c5>
					usprint( buf, "!! %c: waitpid(%d) status %d\n",
   198c5:	80 7d f2 00          	cmpb   $0x0,-0xe(%ebp)
   198c9:	74 0c                	je     198d7 <progTUV+0x298>
   198cb:	8b 45 e0             	mov    -0x20(%ebp),%eax
   198ce:	8b 84 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%eax
   198d5:	eb 05                	jmp    198dc <progTUV+0x29d>
   198d7:	b8 00 00 00 00       	mov    $0x0,%eax
   198dc:	0f b6 55 c7          	movzbl -0x39(%ebp),%edx
   198e0:	0f be d2             	movsbl %dl,%edx
   198e3:	83 ec 0c             	sub    $0xc,%esp
   198e6:	ff 75 dc             	pushl  -0x24(%ebp)
   198e9:	50                   	push   %eax
   198ea:	52                   	push   %edx
   198eb:	68 04 c0 01 00       	push   $0x1c004
   198f0:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   198f6:	50                   	push   %eax
   198f7:	e8 d6 03 00 00       	call   19cd2 <usprint>
   198fc:	83 c4 20             	add    $0x20,%esp
			} else {
				usprint( buf, "!! %c: no children\n", ch );
			}

			// regardless, we're outta here
			break;
   198ff:	e9 9d 01 00 00       	jmp    19aa1 <progTUV+0x462>
					usprint( buf, "!! %c: kill(%d) status %d\n",
   19904:	8b 45 e0             	mov    -0x20(%ebp),%eax
   19907:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   1990e:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   19912:	0f be c0             	movsbl %al,%eax
   19915:	83 ec 0c             	sub    $0xc,%esp
   19918:	ff 75 dc             	pushl  -0x24(%ebp)
   1991b:	52                   	push   %edx
   1991c:	50                   	push   %eax
   1991d:	68 38 bf 01 00       	push   $0x1bf38
   19922:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19928:	50                   	push   %eax
   19929:	e8 a4 03 00 00       	call   19cd2 <usprint>
   1992e:	83 c4 20             	add    $0x20,%esp
			break;
   19931:	e9 6b 01 00 00       	jmp    19aa1 <progTUV+0x462>
				usprint( buf, "!! %c: no children\n", ch );
   19936:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   1993a:	0f be c0             	movsbl %al,%eax
   1993d:	83 ec 04             	sub    $0x4,%esp
   19940:	50                   	push   %eax
   19941:	68 22 c0 01 00       	push   $0x1c022
   19946:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   1994c:	50                   	push   %eax
   1994d:	e8 80 03 00 00       	call   19cd2 <usprint>
   19952:	83 c4 10             	add    $0x10,%esp
   19955:	e9 47 01 00 00       	jmp    19aa1 <progTUV+0x462>

		} else {

			// locate the child
			int ix = -1;
   1995a:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)

			// were we looking by PID?
			if( bypid ) {
   19961:	80 7d f2 00          	cmpb   $0x0,-0xe(%ebp)
   19965:	74 58                	je     199bf <progTUV+0x380>
				// we should have just gotten the one we were looking for
				if( this != children[n] ) {
   19967:	8b 45 e0             	mov    -0x20(%ebp),%eax
   1996a:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   19971:	8b 45 dc             	mov    -0x24(%ebp),%eax
   19974:	39 c2                	cmp    %eax,%edx
   19976:	74 41                	je     199b9 <progTUV+0x37a>
					// uh-oh
					usprint( buf, "** %c: wait/kill PID %d, got %d\n",
   19978:	8b 45 e0             	mov    -0x20(%ebp),%eax
   1997b:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   19982:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   19986:	0f be c0             	movsbl %al,%eax
   19989:	83 ec 0c             	sub    $0xc,%esp
   1998c:	ff 75 dc             	pushl  -0x24(%ebp)
   1998f:	52                   	push   %edx
   19990:	50                   	push   %eax
   19991:	68 38 c0 01 00       	push   $0x1c038
   19996:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   1999c:	50                   	push   %eax
   1999d:	e8 30 03 00 00       	call   19cd2 <usprint>
   199a2:	83 c4 20             	add    $0x20,%esp
							ch, children[n], this );
					cwrites( buf );
   199a5:	83 ec 0c             	sub    $0xc,%esp
   199a8:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   199ae:	50                   	push   %eax
   199af:	e8 0b 0a 00 00       	call   1a3bf <cwrites>
   199b4:	83 c4 10             	add    $0x10,%esp
   199b7:	eb 06                	jmp    199bf <progTUV+0x380>
				} else {
					ix = n;
   199b9:	8b 45 e0             	mov    -0x20(%ebp),%eax
   199bc:	89 45 d8             	mov    %eax,-0x28(%ebp)
				}
			}

			// either not looking by PID, or the lookup failed somehow
			if( ix < 0 ) {
   199bf:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   199c3:	79 2e                	jns    199f3 <progTUV+0x3b4>
				int i;
				for( i = 0; i < nkids; ++i ) {
   199c5:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
   199cc:	eb 1d                	jmp    199eb <progTUV+0x3ac>
					if( children[i] == this ) {
   199ce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   199d1:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   199d8:	8b 45 dc             	mov    -0x24(%ebp),%eax
   199db:	39 c2                	cmp    %eax,%edx
   199dd:	75 08                	jne    199e7 <progTUV+0x3a8>
						ix = i;
   199df:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   199e2:	89 45 d8             	mov    %eax,-0x28(%ebp)
						break;
   199e5:	eb 0c                	jmp    199f3 <progTUV+0x3b4>
				for( i = 0; i < nkids; ++i ) {
   199e7:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
   199eb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   199ee:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   199f1:	7c db                	jl     199ce <progTUV+0x38f>
				}
			}

			// if ix == -1, the PID we received isn't in our list of children

			if( ix < 0 ) {
   199f3:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   199f7:	79 21                	jns    19a1a <progTUV+0x3db>

				// didn't find an entry for this PID???
				usprint( buf, "!! %c: child PID %d term, NOT FOUND\n",
   199f9:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   199fd:	0f be c0             	movsbl %al,%eax
   19a00:	ff 75 dc             	pushl  -0x24(%ebp)
   19a03:	50                   	push   %eax
   19a04:	68 5c c0 01 00       	push   $0x1c05c
   19a09:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19a0f:	50                   	push   %eax
   19a10:	e8 bd 02 00 00       	call   19cd2 <usprint>
   19a15:	83 c4 10             	add    $0x10,%esp
   19a18:	eb 65                	jmp    19a7f <progTUV+0x440>
						ch, this );

			} else {

				// found this PID in our list of children
				if( ix != n ) {
   19a1a:	8b 45 d8             	mov    -0x28(%ebp),%eax
   19a1d:	3b 45 e0             	cmp    -0x20(%ebp),%eax
   19a20:	74 31                	je     19a53 <progTUV+0x414>
					// ... but it's out of sequence
					usprint( buf, "== %c: child %d (%d,%d) status %d\n",
   19a22:	8b 95 60 fe ff ff    	mov    -0x1a0(%ebp),%edx
   19a28:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   19a2c:	0f be c0             	movsbl %al,%eax
   19a2f:	83 ec 04             	sub    $0x4,%esp
   19a32:	52                   	push   %edx
   19a33:	ff 75 dc             	pushl  -0x24(%ebp)
   19a36:	ff 75 e0             	pushl  -0x20(%ebp)
   19a39:	ff 75 d8             	pushl  -0x28(%ebp)
   19a3c:	50                   	push   %eax
   19a3d:	68 84 c0 01 00       	push   $0x1c084
   19a42:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19a48:	50                   	push   %eax
   19a49:	e8 84 02 00 00       	call   19cd2 <usprint>
   19a4e:	83 c4 20             	add    $0x20,%esp
   19a51:	eb 2c                	jmp    19a7f <progTUV+0x440>
							ch, ix, n, this, status );
				} else {
					usprint( buf, "== %c: child %d (%d) status %d\n",
   19a53:	8b 95 60 fe ff ff    	mov    -0x1a0(%ebp),%edx
   19a59:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   19a5d:	0f be c0             	movsbl %al,%eax
   19a60:	83 ec 08             	sub    $0x8,%esp
   19a63:	52                   	push   %edx
   19a64:	ff 75 dc             	pushl  -0x24(%ebp)
   19a67:	ff 75 d8             	pushl  -0x28(%ebp)
   19a6a:	50                   	push   %eax
   19a6b:	68 a8 c0 01 00       	push   $0x1c0a8
   19a70:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19a76:	50                   	push   %eax
   19a77:	e8 56 02 00 00       	call   19cd2 <usprint>
   19a7c:	83 c4 20             	add    $0x20,%esp
				}
			}

		}

		cwrites( buf );
   19a7f:	83 ec 0c             	sub    $0xc,%esp
   19a82:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19a88:	50                   	push   %eax
   19a89:	e8 31 09 00 00       	call   1a3bf <cwrites>
   19a8e:	83 c4 10             	add    $0x10,%esp

		++n;
   19a91:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)

	} while( n < nkids );
   19a95:	8b 45 e0             	mov    -0x20(%ebp),%eax
   19a98:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   19a9b:	0f 8c c0 fd ff ff    	jl     19861 <progTUV+0x222>

	exit( 0 );
   19aa1:	83 ec 0c             	sub    $0xc,%esp
   19aa4:	6a 00                	push   $0x0
   19aa6:	e8 7d d4 ff ff       	call   16f28 <exit>
   19aab:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   19aae:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   19ab3:	c9                   	leave  
   19ab4:	c3                   	ret    

00019ab5 <ublkmov>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void ublkmov( void *dst, const void *src, register uint32_t len ) {
   19ab5:	55                   	push   %ebp
   19ab6:	89 e5                	mov    %esp,%ebp
   19ab8:	56                   	push   %esi
   19ab9:	53                   	push   %ebx
   19aba:	8b 45 10             	mov    0x10(%ebp),%eax

	// verify that the addresses are aligned and
	// the length is a multiple of four bytes
	if( (((uint32_t)dst)&0x3) != 0 ||
   19abd:	8b 55 08             	mov    0x8(%ebp),%edx
   19ac0:	83 e2 03             	and    $0x3,%edx
   19ac3:	85 d2                	test   %edx,%edx
   19ac5:	75 13                	jne    19ada <ublkmov+0x25>
		(((uint32_t)src)&0x3) != 0 ||
   19ac7:	8b 55 0c             	mov    0xc(%ebp),%edx
   19aca:	83 e2 03             	and    $0x3,%edx
	if( (((uint32_t)dst)&0x3) != 0 ||
   19acd:	85 d2                	test   %edx,%edx
   19acf:	75 09                	jne    19ada <ublkmov+0x25>
		(len & 0x3) != 0 ) {
   19ad1:	89 c2                	mov    %eax,%edx
   19ad3:	83 e2 03             	and    $0x3,%edx
		(((uint32_t)src)&0x3) != 0 ||
   19ad6:	85 d2                	test   %edx,%edx
   19ad8:	74 14                	je     19aee <ublkmov+0x39>
		// something isn't aligned, so just use memmove()
		umemmove( dst, src, len );
   19ada:	83 ec 04             	sub    $0x4,%esp
   19add:	50                   	push   %eax
   19ade:	ff 75 0c             	pushl  0xc(%ebp)
   19ae1:	ff 75 08             	pushl  0x8(%ebp)
   19ae4:	e8 b4 00 00 00       	call   19b9d <umemmove>
   19ae9:	83 c4 10             	add    $0x10,%esp
		return;
   19aec:	eb 5a                	jmp    19b48 <ublkmov+0x93>
	}

	// everything is nicely aligned, so off we go
	register uint32_t *dest = dst;
   19aee:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint32_t *source = src;
   19af1:	8b 75 0c             	mov    0xc(%ebp),%esi

	// now copying 32-bit values
	len /= 4;
   19af4:	c1 e8 02             	shr    $0x2,%eax

	if( source < dest && (source + len) > dest ) {
   19af7:	39 de                	cmp    %ebx,%esi
   19af9:	73 44                	jae    19b3f <ublkmov+0x8a>
   19afb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19b02:	01 f2                	add    %esi,%edx
   19b04:	39 d3                	cmp    %edx,%ebx
   19b06:	73 37                	jae    19b3f <ublkmov+0x8a>
		source += len;
   19b08:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19b0f:	01 d6                	add    %edx,%esi
		dest += len;
   19b11:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19b18:	01 d3                	add    %edx,%ebx
		while( len-- > 0 ) {
   19b1a:	eb 0a                	jmp    19b26 <ublkmov+0x71>
			*--dest = *--source;
   19b1c:	83 ee 04             	sub    $0x4,%esi
   19b1f:	83 eb 04             	sub    $0x4,%ebx
   19b22:	8b 16                	mov    (%esi),%edx
   19b24:	89 13                	mov    %edx,(%ebx)
		while( len-- > 0 ) {
   19b26:	89 c2                	mov    %eax,%edx
   19b28:	8d 42 ff             	lea    -0x1(%edx),%eax
   19b2b:	85 d2                	test   %edx,%edx
   19b2d:	75 ed                	jne    19b1c <ublkmov+0x67>
	if( source < dest && (source + len) > dest ) {
   19b2f:	eb 17                	jmp    19b48 <ublkmov+0x93>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   19b31:	89 f1                	mov    %esi,%ecx
   19b33:	8d 71 04             	lea    0x4(%ecx),%esi
   19b36:	89 da                	mov    %ebx,%edx
   19b38:	8d 5a 04             	lea    0x4(%edx),%ebx
   19b3b:	8b 09                	mov    (%ecx),%ecx
   19b3d:	89 0a                	mov    %ecx,(%edx)
		while( len-- ) {
   19b3f:	89 c2                	mov    %eax,%edx
   19b41:	8d 42 ff             	lea    -0x1(%edx),%eax
   19b44:	85 d2                	test   %edx,%edx
   19b46:	75 e9                	jne    19b31 <ublkmov+0x7c>
		}
	}
}
   19b48:	8d 65 f8             	lea    -0x8(%ebp),%esp
   19b4b:	5b                   	pop    %ebx
   19b4c:	5e                   	pop    %esi
   19b4d:	5d                   	pop    %ebp
   19b4e:	c3                   	ret    

00019b4f <umemclr>:
** Initialize all bytes of a block of memory to zero
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
*/
void umemclr( void *buf, register uint32_t len ) {
   19b4f:	55                   	push   %ebp
   19b50:	89 e5                	mov    %esp,%ebp
   19b52:	53                   	push   %ebx
   19b53:	8b 55 0c             	mov    0xc(%ebp),%edx
	register uint8_t *dest = buf;
   19b56:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and clearing
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   19b59:	eb 08                	jmp    19b63 <umemclr+0x14>
			*dest++ = 0;
   19b5b:	89 d8                	mov    %ebx,%eax
   19b5d:	8d 58 01             	lea    0x1(%eax),%ebx
   19b60:	c6 00 00             	movb   $0x0,(%eax)
	while( len-- ) {
   19b63:	89 d0                	mov    %edx,%eax
   19b65:	8d 50 ff             	lea    -0x1(%eax),%edx
   19b68:	85 c0                	test   %eax,%eax
   19b6a:	75 ef                	jne    19b5b <umemclr+0xc>
	}
}
   19b6c:	90                   	nop
   19b6d:	5b                   	pop    %ebx
   19b6e:	5d                   	pop    %ebp
   19b6f:	c3                   	ret    

00019b70 <umemcpy>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void umemcpy( void *dst, register const void *src, register uint32_t len ) {
   19b70:	55                   	push   %ebp
   19b71:	89 e5                	mov    %esp,%ebp
   19b73:	56                   	push   %esi
   19b74:	53                   	push   %ebx
   19b75:	8b 4d 10             	mov    0x10(%ebp),%ecx
	register uint8_t *dest = dst;
   19b78:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint8_t *source = src;
   19b7b:	8b 75 0c             	mov    0xc(%ebp),%esi
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   19b7e:	eb 0f                	jmp    19b8f <umemcpy+0x1f>
		*dest++ = *source++;
   19b80:	89 f2                	mov    %esi,%edx
   19b82:	8d 72 01             	lea    0x1(%edx),%esi
   19b85:	89 d8                	mov    %ebx,%eax
   19b87:	8d 58 01             	lea    0x1(%eax),%ebx
   19b8a:	0f b6 12             	movzbl (%edx),%edx
   19b8d:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   19b8f:	89 c8                	mov    %ecx,%eax
   19b91:	8d 48 ff             	lea    -0x1(%eax),%ecx
   19b94:	85 c0                	test   %eax,%eax
   19b96:	75 e8                	jne    19b80 <umemcpy+0x10>
	}
}
   19b98:	90                   	nop
   19b99:	5b                   	pop    %ebx
   19b9a:	5e                   	pop    %esi
   19b9b:	5d                   	pop    %ebp
   19b9c:	c3                   	ret    

00019b9d <umemmove>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void umemmove( void *dst, const void *src, register uint32_t len ) {
   19b9d:	55                   	push   %ebp
   19b9e:	89 e5                	mov    %esp,%ebp
   19ba0:	56                   	push   %esi
   19ba1:	53                   	push   %ebx
   19ba2:	8b 45 10             	mov    0x10(%ebp),%eax
	register uint8_t *dest = dst;
   19ba5:	8b 75 08             	mov    0x8(%ebp),%esi
	register const uint8_t *source = src;
   19ba8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	if( source < dest && (source + len) > dest ) {
   19bab:	39 f3                	cmp    %esi,%ebx
   19bad:	73 32                	jae    19be1 <umemmove+0x44>
   19baf:	8d 14 03             	lea    (%ebx,%eax,1),%edx
   19bb2:	39 d6                	cmp    %edx,%esi
   19bb4:	73 2b                	jae    19be1 <umemmove+0x44>
		source += len;
   19bb6:	01 c3                	add    %eax,%ebx
		dest += len;
   19bb8:	01 c6                	add    %eax,%esi
		while( len-- > 0 ) {
   19bba:	eb 0b                	jmp    19bc7 <umemmove+0x2a>
			*--dest = *--source;
   19bbc:	83 eb 01             	sub    $0x1,%ebx
   19bbf:	83 ee 01             	sub    $0x1,%esi
   19bc2:	0f b6 13             	movzbl (%ebx),%edx
   19bc5:	88 16                	mov    %dl,(%esi)
		while( len-- > 0 ) {
   19bc7:	89 c2                	mov    %eax,%edx
   19bc9:	8d 42 ff             	lea    -0x1(%edx),%eax
   19bcc:	85 d2                	test   %edx,%edx
   19bce:	75 ec                	jne    19bbc <umemmove+0x1f>
	if( source < dest && (source + len) > dest ) {
   19bd0:	eb 18                	jmp    19bea <umemmove+0x4d>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   19bd2:	89 d9                	mov    %ebx,%ecx
   19bd4:	8d 59 01             	lea    0x1(%ecx),%ebx
   19bd7:	89 f2                	mov    %esi,%edx
   19bd9:	8d 72 01             	lea    0x1(%edx),%esi
   19bdc:	0f b6 09             	movzbl (%ecx),%ecx
   19bdf:	88 0a                	mov    %cl,(%edx)
		while( len-- ) {
   19be1:	89 c2                	mov    %eax,%edx
   19be3:	8d 42 ff             	lea    -0x1(%edx),%eax
   19be6:	85 d2                	test   %edx,%edx
   19be8:	75 e8                	jne    19bd2 <umemmove+0x35>
		}
	}
}
   19bea:	90                   	nop
   19beb:	5b                   	pop    %ebx
   19bec:	5e                   	pop    %esi
   19bed:	5d                   	pop    %ebp
   19bee:	c3                   	ret    

00019bef <umemset>:
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
** @param value  Initialization value
*/
void umemset( void *buf, register uint32_t len, register uint32_t value ) {
   19bef:	55                   	push   %ebp
   19bf0:	89 e5                	mov    %esp,%ebp
   19bf2:	53                   	push   %ebx
   19bf3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register uint8_t *bp = buf;
   19bf6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   19bf9:	eb 0b                	jmp    19c06 <umemset+0x17>
		*bp++ = value;
   19bfb:	89 d8                	mov    %ebx,%eax
   19bfd:	8d 58 01             	lea    0x1(%eax),%ebx
   19c00:	0f b6 55 10          	movzbl 0x10(%ebp),%edx
   19c04:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   19c06:	89 c8                	mov    %ecx,%eax
   19c08:	8d 48 ff             	lea    -0x1(%eax),%ecx
   19c0b:	85 c0                	test   %eax,%eax
   19c0d:	75 ec                	jne    19bfb <umemset+0xc>
	}
}
   19c0f:	90                   	nop
   19c10:	5b                   	pop    %ebx
   19c11:	5d                   	pop    %ebp
   19c12:	c3                   	ret    

00019c13 <upad>:
**
** @return Pointer to the first byte after the padding
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *upad( char *dst, int extra, int padchar ) {
   19c13:	55                   	push   %ebp
   19c14:	89 e5                	mov    %esp,%ebp
	while( extra > 0 ){
   19c16:	eb 12                	jmp    19c2a <upad+0x17>
		*dst++ = (char) padchar;
   19c18:	8b 45 08             	mov    0x8(%ebp),%eax
   19c1b:	8d 50 01             	lea    0x1(%eax),%edx
   19c1e:	89 55 08             	mov    %edx,0x8(%ebp)
   19c21:	8b 55 10             	mov    0x10(%ebp),%edx
   19c24:	88 10                	mov    %dl,(%eax)
		extra -= 1;
   19c26:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
	while( extra > 0 ){
   19c2a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   19c2e:	7f e8                	jg     19c18 <upad+0x5>
	}
	return dst;
   19c30:	8b 45 08             	mov    0x8(%ebp),%eax
}
   19c33:	5d                   	pop    %ebp
   19c34:	c3                   	ret    

00019c35 <upadstr>:
** @return Pointer to the first byte after the padded string
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *upadstr( char *dst, char *str, int len, int width,
				int leftadjust, int padchar ) {
   19c35:	55                   	push   %ebp
   19c36:	89 e5                	mov    %esp,%ebp
   19c38:	83 ec 18             	sub    $0x18,%esp
	int extra;

	// determine the length of the string if we need to
	if( len < 0 ){
   19c3b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
   19c3f:	79 11                	jns    19c52 <upadstr+0x1d>
		len = ustrlen( str );
   19c41:	83 ec 0c             	sub    $0xc,%esp
   19c44:	ff 75 0c             	pushl  0xc(%ebp)
   19c47:	e8 03 04 00 00       	call   1a04f <ustrlen>
   19c4c:	83 c4 10             	add    $0x10,%esp
   19c4f:	89 45 10             	mov    %eax,0x10(%ebp)
	}

	// how much filler must we add?
	extra = width - len;
   19c52:	8b 45 14             	mov    0x14(%ebp),%eax
   19c55:	2b 45 10             	sub    0x10(%ebp),%eax
   19c58:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// add filler on the left if we're not left-justifying
	if( extra > 0 && !leftadjust ){
   19c5b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   19c5f:	7e 1d                	jle    19c7e <upadstr+0x49>
   19c61:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   19c65:	75 17                	jne    19c7e <upadstr+0x49>
		dst = upad( dst, extra, padchar );
   19c67:	83 ec 04             	sub    $0x4,%esp
   19c6a:	ff 75 1c             	pushl  0x1c(%ebp)
   19c6d:	ff 75 f0             	pushl  -0x10(%ebp)
   19c70:	ff 75 08             	pushl  0x8(%ebp)
   19c73:	e8 9b ff ff ff       	call   19c13 <upad>
   19c78:	83 c4 10             	add    $0x10,%esp
   19c7b:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	// copy the string itself
	for( int i = 0; i < len; ++i ) {
   19c7e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   19c85:	eb 1b                	jmp    19ca2 <upadstr+0x6d>
		*dst++ = str[i];
   19c87:	8b 55 f4             	mov    -0xc(%ebp),%edx
   19c8a:	8b 45 0c             	mov    0xc(%ebp),%eax
   19c8d:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
   19c90:	8b 45 08             	mov    0x8(%ebp),%eax
   19c93:	8d 50 01             	lea    0x1(%eax),%edx
   19c96:	89 55 08             	mov    %edx,0x8(%ebp)
   19c99:	0f b6 11             	movzbl (%ecx),%edx
   19c9c:	88 10                	mov    %dl,(%eax)
	for( int i = 0; i < len; ++i ) {
   19c9e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   19ca2:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19ca5:	3b 45 10             	cmp    0x10(%ebp),%eax
   19ca8:	7c dd                	jl     19c87 <upadstr+0x52>
	}

	// add filler on the right if we are left-justifying
	if( extra > 0 && leftadjust ){
   19caa:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   19cae:	7e 1d                	jle    19ccd <upadstr+0x98>
   19cb0:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   19cb4:	74 17                	je     19ccd <upadstr+0x98>
		dst = upad( dst, extra, padchar );
   19cb6:	83 ec 04             	sub    $0x4,%esp
   19cb9:	ff 75 1c             	pushl  0x1c(%ebp)
   19cbc:	ff 75 f0             	pushl  -0x10(%ebp)
   19cbf:	ff 75 08             	pushl  0x8(%ebp)
   19cc2:	e8 4c ff ff ff       	call   19c13 <upad>
   19cc7:	83 c4 10             	add    $0x10,%esp
   19cca:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	return dst;
   19ccd:	8b 45 08             	mov    0x8(%ebp),%eax
}
   19cd0:	c9                   	leave  
   19cd1:	c3                   	ret    

00019cd2 <usprint>:
**
** NOTE:  relies heavily on the x86 parameter passing convention
** (parameters are pushed onto the stack in reverse order as
** 32-bit values).
*/
void usprint( char *dst, char *fmt, ... ) {
   19cd2:	55                   	push   %ebp
   19cd3:	89 e5                	mov    %esp,%ebp
   19cd5:	83 ec 38             	sub    $0x38,%esp
	** to point to the next "thing", and interpret it according
	** to the format string.
	*/
	
	// get the pointer to the first "value" parameter
	ap = (int *)(&fmt) + 1;
   19cd8:	8d 45 0c             	lea    0xc(%ebp),%eax
   19cdb:	83 c0 04             	add    $0x4,%eax
   19cde:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// iterate through the format string
	while( (ch = *fmt++) != '\0' ){
   19ce1:	e9 3f 02 00 00       	jmp    19f25 <usprint+0x253>
		/*
		** Is it the start of a format code?
		*/
		if( ch == '%' ){
   19ce6:	80 7d f3 25          	cmpb   $0x25,-0xd(%ebp)
   19cea:	0f 85 26 02 00 00    	jne    19f16 <usprint+0x244>
			/*
			** Yes, get the padding and width options (if there).
			** Alignment must come at the beginning, then fill,
			** then width.
			*/
			leftadjust = 0;
   19cf0:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
			padchar = ' ';
   19cf7:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
			width = 0;
   19cfe:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
			ch = *fmt++;
   19d05:	8b 45 0c             	mov    0xc(%ebp),%eax
   19d08:	8d 50 01             	lea    0x1(%eax),%edx
   19d0b:	89 55 0c             	mov    %edx,0xc(%ebp)
   19d0e:	0f b6 00             	movzbl (%eax),%eax
   19d11:	88 45 f3             	mov    %al,-0xd(%ebp)
			if( ch == '-' ){
   19d14:	80 7d f3 2d          	cmpb   $0x2d,-0xd(%ebp)
   19d18:	75 16                	jne    19d30 <usprint+0x5e>
				leftadjust = 1;
   19d1a:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
				ch = *fmt++;
   19d21:	8b 45 0c             	mov    0xc(%ebp),%eax
   19d24:	8d 50 01             	lea    0x1(%eax),%edx
   19d27:	89 55 0c             	mov    %edx,0xc(%ebp)
   19d2a:	0f b6 00             	movzbl (%eax),%eax
   19d2d:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			if( ch == '0' ){
   19d30:	80 7d f3 30          	cmpb   $0x30,-0xd(%ebp)
   19d34:	75 40                	jne    19d76 <usprint+0xa4>
				padchar = '0';
   19d36:	c7 45 e4 30 00 00 00 	movl   $0x30,-0x1c(%ebp)
				ch = *fmt++;
   19d3d:	8b 45 0c             	mov    0xc(%ebp),%eax
   19d40:	8d 50 01             	lea    0x1(%eax),%edx
   19d43:	89 55 0c             	mov    %edx,0xc(%ebp)
   19d46:	0f b6 00             	movzbl (%eax),%eax
   19d49:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			while( ch >= '0' && ch <= '9' ){
   19d4c:	eb 28                	jmp    19d76 <usprint+0xa4>
				width *= 10;
   19d4e:	8b 55 e8             	mov    -0x18(%ebp),%edx
   19d51:	89 d0                	mov    %edx,%eax
   19d53:	c1 e0 02             	shl    $0x2,%eax
   19d56:	01 d0                	add    %edx,%eax
   19d58:	01 c0                	add    %eax,%eax
   19d5a:	89 45 e8             	mov    %eax,-0x18(%ebp)
				width += ch - '0';
   19d5d:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   19d61:	83 e8 30             	sub    $0x30,%eax
   19d64:	01 45 e8             	add    %eax,-0x18(%ebp)
				ch = *fmt++;
   19d67:	8b 45 0c             	mov    0xc(%ebp),%eax
   19d6a:	8d 50 01             	lea    0x1(%eax),%edx
   19d6d:	89 55 0c             	mov    %edx,0xc(%ebp)
   19d70:	0f b6 00             	movzbl (%eax),%eax
   19d73:	88 45 f3             	mov    %al,-0xd(%ebp)
			while( ch >= '0' && ch <= '9' ){
   19d76:	80 7d f3 2f          	cmpb   $0x2f,-0xd(%ebp)
   19d7a:	7e 06                	jle    19d82 <usprint+0xb0>
   19d7c:	80 7d f3 39          	cmpb   $0x39,-0xd(%ebp)
   19d80:	7e cc                	jle    19d4e <usprint+0x7c>
			}

			/*
			** What data type do we have?
			*/
			switch( ch ) {
   19d82:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   19d86:	83 e8 63             	sub    $0x63,%eax
   19d89:	83 f8 15             	cmp    $0x15,%eax
   19d8c:	0f 87 93 01 00 00    	ja     19f25 <usprint+0x253>
   19d92:	8b 04 85 c8 c0 01 00 	mov    0x1c0c8(,%eax,4),%eax
   19d99:	ff e0                	jmp    *%eax

			case 'c':  // characters are passed as 32-bit values
				ch = *ap++;
   19d9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19d9e:	8d 50 04             	lea    0x4(%eax),%edx
   19da1:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19da4:	8b 00                	mov    (%eax),%eax
   19da6:	88 45 f3             	mov    %al,-0xd(%ebp)
				buf[ 0 ] = ch;
   19da9:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   19dad:	88 45 d0             	mov    %al,-0x30(%ebp)
				buf[ 1 ] = '\0';
   19db0:	c6 45 d1 00          	movb   $0x0,-0x2f(%ebp)
				dst = upadstr( dst, buf, 1, width, leftadjust, padchar );
   19db4:	83 ec 08             	sub    $0x8,%esp
   19db7:	ff 75 e4             	pushl  -0x1c(%ebp)
   19dba:	ff 75 ec             	pushl  -0x14(%ebp)
   19dbd:	ff 75 e8             	pushl  -0x18(%ebp)
   19dc0:	6a 01                	push   $0x1
   19dc2:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19dc5:	50                   	push   %eax
   19dc6:	ff 75 08             	pushl  0x8(%ebp)
   19dc9:	e8 67 fe ff ff       	call   19c35 <upadstr>
   19dce:	83 c4 20             	add    $0x20,%esp
   19dd1:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19dd4:	e9 4c 01 00 00       	jmp    19f25 <usprint+0x253>

			case 'd':
				len = ucvtdec( buf, *ap++ );
   19dd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19ddc:	8d 50 04             	lea    0x4(%eax),%edx
   19ddf:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19de2:	8b 00                	mov    (%eax),%eax
   19de4:	83 ec 08             	sub    $0x8,%esp
   19de7:	50                   	push   %eax
   19de8:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19deb:	50                   	push   %eax
   19dec:	e8 a4 02 00 00       	call   1a095 <ucvtdec>
   19df1:	83 c4 10             	add    $0x10,%esp
   19df4:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = upadstr( dst, buf, len, width, leftadjust, padchar );
   19df7:	83 ec 08             	sub    $0x8,%esp
   19dfa:	ff 75 e4             	pushl  -0x1c(%ebp)
   19dfd:	ff 75 ec             	pushl  -0x14(%ebp)
   19e00:	ff 75 e8             	pushl  -0x18(%ebp)
   19e03:	ff 75 e0             	pushl  -0x20(%ebp)
   19e06:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19e09:	50                   	push   %eax
   19e0a:	ff 75 08             	pushl  0x8(%ebp)
   19e0d:	e8 23 fe ff ff       	call   19c35 <upadstr>
   19e12:	83 c4 20             	add    $0x20,%esp
   19e15:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19e18:	e9 08 01 00 00       	jmp    19f25 <usprint+0x253>

			case 's':
				str = (char *) (*ap++);
   19e1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19e20:	8d 50 04             	lea    0x4(%eax),%edx
   19e23:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19e26:	8b 00                	mov    (%eax),%eax
   19e28:	89 45 dc             	mov    %eax,-0x24(%ebp)
				dst = upadstr( dst, str, -1, width, leftadjust, padchar );
   19e2b:	83 ec 08             	sub    $0x8,%esp
   19e2e:	ff 75 e4             	pushl  -0x1c(%ebp)
   19e31:	ff 75 ec             	pushl  -0x14(%ebp)
   19e34:	ff 75 e8             	pushl  -0x18(%ebp)
   19e37:	6a ff                	push   $0xffffffff
   19e39:	ff 75 dc             	pushl  -0x24(%ebp)
   19e3c:	ff 75 08             	pushl  0x8(%ebp)
   19e3f:	e8 f1 fd ff ff       	call   19c35 <upadstr>
   19e44:	83 c4 20             	add    $0x20,%esp
   19e47:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19e4a:	e9 d6 00 00 00       	jmp    19f25 <usprint+0x253>

			case 'x':
				len = ucvthex( buf, *ap++ );
   19e4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19e52:	8d 50 04             	lea    0x4(%eax),%edx
   19e55:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19e58:	8b 00                	mov    (%eax),%eax
   19e5a:	83 ec 08             	sub    $0x8,%esp
   19e5d:	50                   	push   %eax
   19e5e:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19e61:	50                   	push   %eax
   19e62:	e8 fe 02 00 00       	call   1a165 <ucvthex>
   19e67:	83 c4 10             	add    $0x10,%esp
   19e6a:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = upadstr( dst, buf, len, width, leftadjust, padchar );
   19e6d:	83 ec 08             	sub    $0x8,%esp
   19e70:	ff 75 e4             	pushl  -0x1c(%ebp)
   19e73:	ff 75 ec             	pushl  -0x14(%ebp)
   19e76:	ff 75 e8             	pushl  -0x18(%ebp)
   19e79:	ff 75 e0             	pushl  -0x20(%ebp)
   19e7c:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19e7f:	50                   	push   %eax
   19e80:	ff 75 08             	pushl  0x8(%ebp)
   19e83:	e8 ad fd ff ff       	call   19c35 <upadstr>
   19e88:	83 c4 20             	add    $0x20,%esp
   19e8b:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19e8e:	e9 92 00 00 00       	jmp    19f25 <usprint+0x253>

			case 'o':
				len = ucvtoct( buf, *ap++ );
   19e93:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19e96:	8d 50 04             	lea    0x4(%eax),%edx
   19e99:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19e9c:	8b 00                	mov    (%eax),%eax
   19e9e:	83 ec 08             	sub    $0x8,%esp
   19ea1:	50                   	push   %eax
   19ea2:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19ea5:	50                   	push   %eax
   19ea6:	e8 44 03 00 00       	call   1a1ef <ucvtoct>
   19eab:	83 c4 10             	add    $0x10,%esp
   19eae:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = upadstr( dst, buf, len, width, leftadjust, padchar );
   19eb1:	83 ec 08             	sub    $0x8,%esp
   19eb4:	ff 75 e4             	pushl  -0x1c(%ebp)
   19eb7:	ff 75 ec             	pushl  -0x14(%ebp)
   19eba:	ff 75 e8             	pushl  -0x18(%ebp)
   19ebd:	ff 75 e0             	pushl  -0x20(%ebp)
   19ec0:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19ec3:	50                   	push   %eax
   19ec4:	ff 75 08             	pushl  0x8(%ebp)
   19ec7:	e8 69 fd ff ff       	call   19c35 <upadstr>
   19ecc:	83 c4 20             	add    $0x20,%esp
   19ecf:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19ed2:	eb 51                	jmp    19f25 <usprint+0x253>

			case 'u':
				len = ucvtuns( buf, *ap++ );
   19ed4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19ed7:	8d 50 04             	lea    0x4(%eax),%edx
   19eda:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19edd:	8b 00                	mov    (%eax),%eax
   19edf:	83 ec 08             	sub    $0x8,%esp
   19ee2:	50                   	push   %eax
   19ee3:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19ee6:	50                   	push   %eax
   19ee7:	e8 8d 03 00 00       	call   1a279 <ucvtuns>
   19eec:	83 c4 10             	add    $0x10,%esp
   19eef:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = upadstr( dst, buf, len, width, leftadjust, padchar );
   19ef2:	83 ec 08             	sub    $0x8,%esp
   19ef5:	ff 75 e4             	pushl  -0x1c(%ebp)
   19ef8:	ff 75 ec             	pushl  -0x14(%ebp)
   19efb:	ff 75 e8             	pushl  -0x18(%ebp)
   19efe:	ff 75 e0             	pushl  -0x20(%ebp)
   19f01:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19f04:	50                   	push   %eax
   19f05:	ff 75 08             	pushl  0x8(%ebp)
   19f08:	e8 28 fd ff ff       	call   19c35 <upadstr>
   19f0d:	83 c4 20             	add    $0x20,%esp
   19f10:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19f13:	90                   	nop
   19f14:	eb 0f                	jmp    19f25 <usprint+0x253>

			}
		} else {
			// no, it's just an ordinary character
			*dst++ = ch;
   19f16:	8b 45 08             	mov    0x8(%ebp),%eax
   19f19:	8d 50 01             	lea    0x1(%eax),%edx
   19f1c:	89 55 08             	mov    %edx,0x8(%ebp)
   19f1f:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
   19f23:	88 10                	mov    %dl,(%eax)
	while( (ch = *fmt++) != '\0' ){
   19f25:	8b 45 0c             	mov    0xc(%ebp),%eax
   19f28:	8d 50 01             	lea    0x1(%eax),%edx
   19f2b:	89 55 0c             	mov    %edx,0xc(%ebp)
   19f2e:	0f b6 00             	movzbl (%eax),%eax
   19f31:	88 45 f3             	mov    %al,-0xd(%ebp)
   19f34:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   19f38:	0f 85 a8 fd ff ff    	jne    19ce6 <usprint+0x14>
		}
	}

	// NUL-terminate the result
	*dst = '\0';
   19f3e:	8b 45 08             	mov    0x8(%ebp),%eax
   19f41:	c6 00 00             	movb   $0x0,(%eax)
}
   19f44:	90                   	nop
   19f45:	c9                   	leave  
   19f46:	c3                   	ret    

00019f47 <ustr2int>:
** @param str   The string to examine
** @param base  The radix to use in the conversion
**
** @return The converted integer
*/
int ustr2int( register const char *str, register int base ) {
   19f47:	55                   	push   %ebp
   19f48:	89 e5                	mov    %esp,%ebp
   19f4a:	53                   	push   %ebx
   19f4b:	83 ec 14             	sub    $0x14,%esp
   19f4e:	8b 45 08             	mov    0x8(%ebp),%eax
   19f51:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register int num = 0;
   19f54:	bb 00 00 00 00       	mov    $0x0,%ebx
	register char bchar = '9';
   19f59:	c6 45 eb 39          	movb   $0x39,-0x15(%ebp)
	int sign = 1;
   19f5d:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)

	// check for leading '-'
	if( *str == '-' ) {
   19f64:	0f b6 10             	movzbl (%eax),%edx
   19f67:	80 fa 2d             	cmp    $0x2d,%dl
   19f6a:	75 0a                	jne    19f76 <ustr2int+0x2f>
		sign = -1;
   19f6c:	c7 45 f8 ff ff ff ff 	movl   $0xffffffff,-0x8(%ebp)
		++str;
   19f73:	83 c0 01             	add    $0x1,%eax
	}

	if( base != 10 ) {
   19f76:	83 f9 0a             	cmp    $0xa,%ecx
   19f79:	74 2b                	je     19fa6 <ustr2int+0x5f>
		bchar = '0' + base - 1;
   19f7b:	89 ca                	mov    %ecx,%edx
   19f7d:	83 c2 2f             	add    $0x2f,%edx
   19f80:	88 55 eb             	mov    %dl,-0x15(%ebp)
	}

	// iterate through the characters
	while( *str ) {
   19f83:	eb 21                	jmp    19fa6 <ustr2int+0x5f>
		if( *str < '0' || *str > bchar )
   19f85:	0f b6 10             	movzbl (%eax),%edx
   19f88:	80 fa 2f             	cmp    $0x2f,%dl
   19f8b:	7e 20                	jle    19fad <ustr2int+0x66>
   19f8d:	0f b6 10             	movzbl (%eax),%edx
   19f90:	38 55 eb             	cmp    %dl,-0x15(%ebp)
   19f93:	7c 18                	jl     19fad <ustr2int+0x66>
			break;
		num = num * base + *str - '0';
   19f95:	0f af d9             	imul   %ecx,%ebx
   19f98:	0f b6 10             	movzbl (%eax),%edx
   19f9b:	0f be d2             	movsbl %dl,%edx
   19f9e:	01 da                	add    %ebx,%edx
   19fa0:	8d 5a d0             	lea    -0x30(%edx),%ebx
		++str;
   19fa3:	83 c0 01             	add    $0x1,%eax
	while( *str ) {
   19fa6:	0f b6 10             	movzbl (%eax),%edx
   19fa9:	84 d2                	test   %dl,%dl
   19fab:	75 d8                	jne    19f85 <ustr2int+0x3e>
	}

	// return the converted value
	return( num * sign );
   19fad:	89 d8                	mov    %ebx,%eax
   19faf:	0f af 45 f8          	imul   -0x8(%ebp),%eax
}
   19fb3:	83 c4 14             	add    $0x14,%esp
   19fb6:	5b                   	pop    %ebx
   19fb7:	5d                   	pop    %ebp
   19fb8:	c3                   	ret    

00019fb9 <ustrcat>:
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the resulting string
*/
char *ustrcat( register char *dst, register const char *src ) {
   19fb9:	55                   	push   %ebp
   19fba:	89 e5                	mov    %esp,%ebp
   19fbc:	56                   	push   %esi
   19fbd:	53                   	push   %ebx
   19fbe:	8b 45 08             	mov    0x8(%ebp),%eax
   19fc1:	8b 75 0c             	mov    0xc(%ebp),%esi
	register char *tmp = dst;
   19fc4:	89 c3                	mov    %eax,%ebx

	while( *dst )  // find the NUL
   19fc6:	eb 03                	jmp    19fcb <ustrcat+0x12>
		++dst;
   19fc8:	83 c0 01             	add    $0x1,%eax
	while( *dst )  // find the NUL
   19fcb:	0f b6 10             	movzbl (%eax),%edx
   19fce:	84 d2                	test   %dl,%dl
   19fd0:	75 f6                	jne    19fc8 <ustrcat+0xf>

	while( (*dst++ = *src++) )  // append the src string
   19fd2:	90                   	nop
   19fd3:	89 f1                	mov    %esi,%ecx
   19fd5:	8d 71 01             	lea    0x1(%ecx),%esi
   19fd8:	89 c2                	mov    %eax,%edx
   19fda:	8d 42 01             	lea    0x1(%edx),%eax
   19fdd:	0f b6 09             	movzbl (%ecx),%ecx
   19fe0:	88 0a                	mov    %cl,(%edx)
   19fe2:	0f b6 12             	movzbl (%edx),%edx
   19fe5:	84 d2                	test   %dl,%dl
   19fe7:	75 ea                	jne    19fd3 <ustrcat+0x1a>
		;

	return( tmp );
   19fe9:	89 d8                	mov    %ebx,%eax
}
   19feb:	5b                   	pop    %ebx
   19fec:	5e                   	pop    %esi
   19fed:	5d                   	pop    %ebp
   19fee:	c3                   	ret    

00019fef <ustrcmp>:
** @param s1 The first source string
** @param s2 The second source string
**
** @return negative if s1 < s2, zero if equal, and positive if s1 > s2
*/
int ustrcmp( register const char *s1, register const char *s2 ) {
   19fef:	55                   	push   %ebp
   19ff0:	89 e5                	mov    %esp,%ebp
   19ff2:	53                   	push   %ebx
   19ff3:	8b 45 08             	mov    0x8(%ebp),%eax
   19ff6:	8b 55 0c             	mov    0xc(%ebp),%edx

	while( *s1 != 0 && (*s1 == *s2) )
   19ff9:	eb 06                	jmp    1a001 <ustrcmp+0x12>
		++s1, ++s2;
   19ffb:	83 c0 01             	add    $0x1,%eax
   19ffe:	83 c2 01             	add    $0x1,%edx
	while( *s1 != 0 && (*s1 == *s2) )
   1a001:	0f b6 08             	movzbl (%eax),%ecx
   1a004:	84 c9                	test   %cl,%cl
   1a006:	74 0a                	je     1a012 <ustrcmp+0x23>
   1a008:	0f b6 18             	movzbl (%eax),%ebx
   1a00b:	0f b6 0a             	movzbl (%edx),%ecx
   1a00e:	38 cb                	cmp    %cl,%bl
   1a010:	74 e9                	je     19ffb <ustrcmp+0xc>

	return( *s1 - *s2 );
   1a012:	0f b6 00             	movzbl (%eax),%eax
   1a015:	0f be c8             	movsbl %al,%ecx
   1a018:	0f b6 02             	movzbl (%edx),%eax
   1a01b:	0f be c0             	movsbl %al,%eax
   1a01e:	29 c1                	sub    %eax,%ecx
   1a020:	89 c8                	mov    %ecx,%eax
}
   1a022:	5b                   	pop    %ebx
   1a023:	5d                   	pop    %ebp
   1a024:	c3                   	ret    

0001a025 <ustrcpy>:
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the copied string
*/
char *ustrcpy( register char *dst, register const char *src ) {
   1a025:	55                   	push   %ebp
   1a026:	89 e5                	mov    %esp,%ebp
   1a028:	56                   	push   %esi
   1a029:	53                   	push   %ebx
   1a02a:	8b 4d 08             	mov    0x8(%ebp),%ecx
   1a02d:	8b 75 0c             	mov    0xc(%ebp),%esi
	register char *tmp = dst;
   1a030:	89 cb                	mov    %ecx,%ebx

	while( (*dst++ = *src++) )
   1a032:	90                   	nop
   1a033:	89 f2                	mov    %esi,%edx
   1a035:	8d 72 01             	lea    0x1(%edx),%esi
   1a038:	89 c8                	mov    %ecx,%eax
   1a03a:	8d 48 01             	lea    0x1(%eax),%ecx
   1a03d:	0f b6 12             	movzbl (%edx),%edx
   1a040:	88 10                	mov    %dl,(%eax)
   1a042:	0f b6 00             	movzbl (%eax),%eax
   1a045:	84 c0                	test   %al,%al
   1a047:	75 ea                	jne    1a033 <ustrcpy+0xe>
		;

	return( tmp );
   1a049:	89 d8                	mov    %ebx,%eax
}
   1a04b:	5b                   	pop    %ebx
   1a04c:	5e                   	pop    %esi
   1a04d:	5d                   	pop    %ebp
   1a04e:	c3                   	ret    

0001a04f <ustrlen>:
**
** @param str The string to examine
**
** @return The length of the string, or 0
*/
uint32_t ustrlen( register const char *str ) {
   1a04f:	55                   	push   %ebp
   1a050:	89 e5                	mov    %esp,%ebp
   1a052:	53                   	push   %ebx
   1a053:	8b 55 08             	mov    0x8(%ebp),%edx
	register uint32_t len = 0;
   1a056:	bb 00 00 00 00       	mov    $0x0,%ebx

	while( *str++ ) {
   1a05b:	eb 03                	jmp    1a060 <ustrlen+0x11>
		++len;
   1a05d:	83 c3 01             	add    $0x1,%ebx
	while( *str++ ) {
   1a060:	89 d0                	mov    %edx,%eax
   1a062:	8d 50 01             	lea    0x1(%eax),%edx
   1a065:	0f b6 00             	movzbl (%eax),%eax
   1a068:	84 c0                	test   %al,%al
   1a06a:	75 f1                	jne    1a05d <ustrlen+0xe>
	}

	return( len );
   1a06c:	89 d8                	mov    %ebx,%eax
}
   1a06e:	5b                   	pop    %ebx
   1a06f:	5d                   	pop    %ebp
   1a070:	c3                   	ret    

0001a071 <ubound>:
** @param value  Value to be constrained
** @param max    Upper bound
**
** @return The constrained value
*/
uint32_t ubound( uint32_t min, uint32_t value, uint32_t max ) {
   1a071:	55                   	push   %ebp
   1a072:	89 e5                	mov    %esp,%ebp
	if( value < min ){
   1a074:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a077:	3b 45 08             	cmp    0x8(%ebp),%eax
   1a07a:	73 06                	jae    1a082 <ubound+0x11>
		value = min;
   1a07c:	8b 45 08             	mov    0x8(%ebp),%eax
   1a07f:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	if( value > max ){
   1a082:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a085:	3b 45 10             	cmp    0x10(%ebp),%eax
   1a088:	76 06                	jbe    1a090 <ubound+0x1f>
		value = max;
   1a08a:	8b 45 10             	mov    0x10(%ebp),%eax
   1a08d:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	return value;
   1a090:	8b 45 0c             	mov    0xc(%ebp),%eax
}
   1a093:	5d                   	pop    %ebp
   1a094:	c3                   	ret    

0001a095 <ucvtdec>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int ucvtdec( char *buf, int32_t value ) {
   1a095:	55                   	push   %ebp
   1a096:	89 e5                	mov    %esp,%ebp
   1a098:	83 ec 18             	sub    $0x18,%esp
	char *bp = buf;
   1a09b:	8b 45 08             	mov    0x8(%ebp),%eax
   1a09e:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if( value < 0 ) {
   1a0a1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   1a0a5:	79 0f                	jns    1a0b6 <ucvtdec+0x21>
		*bp++ = '-';
   1a0a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a0aa:	8d 50 01             	lea    0x1(%eax),%edx
   1a0ad:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1a0b0:	c6 00 2d             	movb   $0x2d,(%eax)
		value = -value;
   1a0b3:	f7 5d 0c             	negl   0xc(%ebp)
	}

	bp = ucvtdec0( bp, value );
   1a0b6:	83 ec 08             	sub    $0x8,%esp
   1a0b9:	ff 75 0c             	pushl  0xc(%ebp)
   1a0bc:	ff 75 f4             	pushl  -0xc(%ebp)
   1a0bf:	e8 18 00 00 00       	call   1a0dc <ucvtdec0>
   1a0c4:	83 c4 10             	add    $0x10,%esp
   1a0c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp  = '\0';
   1a0ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a0cd:	c6 00 00             	movb   $0x0,(%eax)

	return( bp - buf );
   1a0d0:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1a0d3:	8b 45 08             	mov    0x8(%ebp),%eax
   1a0d6:	29 c2                	sub    %eax,%edx
   1a0d8:	89 d0                	mov    %edx,%eax
}
   1a0da:	c9                   	leave  
   1a0db:	c3                   	ret    

0001a0dc <ucvtdec0>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *ucvtdec0( char *buf, int value ) {
   1a0dc:	55                   	push   %ebp
   1a0dd:	89 e5                	mov    %esp,%ebp
   1a0df:	83 ec 18             	sub    $0x18,%esp
	int quotient;

	quotient = value / 10;
   1a0e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   1a0e5:	ba 67 66 66 66       	mov    $0x66666667,%edx
   1a0ea:	89 c8                	mov    %ecx,%eax
   1a0ec:	f7 ea                	imul   %edx
   1a0ee:	c1 fa 02             	sar    $0x2,%edx
   1a0f1:	89 c8                	mov    %ecx,%eax
   1a0f3:	c1 f8 1f             	sar    $0x1f,%eax
   1a0f6:	29 c2                	sub    %eax,%edx
   1a0f8:	89 d0                	mov    %edx,%eax
   1a0fa:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient < 0 ) {
   1a0fd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a101:	79 0e                	jns    1a111 <ucvtdec0+0x35>
		quotient = 214748364;
   1a103:	c7 45 f4 cc cc cc 0c 	movl   $0xccccccc,-0xc(%ebp)
		value = 8;
   1a10a:	c7 45 0c 08 00 00 00 	movl   $0x8,0xc(%ebp)
	}
	if( quotient != 0 ) {
   1a111:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a115:	74 14                	je     1a12b <ucvtdec0+0x4f>
		buf = ucvtdec0( buf, quotient );
   1a117:	83 ec 08             	sub    $0x8,%esp
   1a11a:	ff 75 f4             	pushl  -0xc(%ebp)
   1a11d:	ff 75 08             	pushl  0x8(%ebp)
   1a120:	e8 b7 ff ff ff       	call   1a0dc <ucvtdec0>
   1a125:	83 c4 10             	add    $0x10,%esp
   1a128:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   1a12b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   1a12e:	ba 67 66 66 66       	mov    $0x66666667,%edx
   1a133:	89 c8                	mov    %ecx,%eax
   1a135:	f7 ea                	imul   %edx
   1a137:	c1 fa 02             	sar    $0x2,%edx
   1a13a:	89 c8                	mov    %ecx,%eax
   1a13c:	c1 f8 1f             	sar    $0x1f,%eax
   1a13f:	29 c2                	sub    %eax,%edx
   1a141:	89 d0                	mov    %edx,%eax
   1a143:	c1 e0 02             	shl    $0x2,%eax
   1a146:	01 d0                	add    %edx,%eax
   1a148:	01 c0                	add    %eax,%eax
   1a14a:	29 c1                	sub    %eax,%ecx
   1a14c:	89 ca                	mov    %ecx,%edx
   1a14e:	89 d0                	mov    %edx,%eax
   1a150:	8d 48 30             	lea    0x30(%eax),%ecx
   1a153:	8b 45 08             	mov    0x8(%ebp),%eax
   1a156:	8d 50 01             	lea    0x1(%eax),%edx
   1a159:	89 55 08             	mov    %edx,0x8(%ebp)
   1a15c:	89 ca                	mov    %ecx,%edx
   1a15e:	88 10                	mov    %dl,(%eax)
	return buf;
   1a160:	8b 45 08             	mov    0x8(%ebp),%eax
}
   1a163:	c9                   	leave  
   1a164:	c3                   	ret    

0001a165 <ucvthex>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int ucvthex( char *buf, uint32_t value ) {
   1a165:	55                   	push   %ebp
   1a166:	89 e5                	mov    %esp,%ebp
   1a168:	83 ec 20             	sub    $0x20,%esp
	const char hexdigits[] = "0123456789ABCDEF";
   1a16b:	c7 45 e3 30 31 32 33 	movl   $0x33323130,-0x1d(%ebp)
   1a172:	c7 45 e7 34 35 36 37 	movl   $0x37363534,-0x19(%ebp)
   1a179:	c7 45 eb 38 39 41 42 	movl   $0x42413938,-0x15(%ebp)
   1a180:	c7 45 ef 43 44 45 46 	movl   $0x46454443,-0x11(%ebp)
   1a187:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)
	int chars_stored = 0;
   1a18b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)

	for( int i = 0; i < 8; i += 1 ) {
   1a192:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
   1a199:	eb 43                	jmp    1a1de <ucvthex+0x79>
		uint32_t val = value & 0xf0000000;
   1a19b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a19e:	25 00 00 00 f0       	and    $0xf0000000,%eax
   1a1a3:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if( chars_stored || val != 0 || i == 7 ) {
   1a1a6:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
   1a1aa:	75 0c                	jne    1a1b8 <ucvthex+0x53>
   1a1ac:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a1b0:	75 06                	jne    1a1b8 <ucvthex+0x53>
   1a1b2:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   1a1b6:	75 1e                	jne    1a1d6 <ucvthex+0x71>
			++chars_stored;
   1a1b8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
			val = (val >> 28) & 0xf;
   1a1bc:	c1 6d f4 1c          	shrl   $0x1c,-0xc(%ebp)
			*buf++ = hexdigits[val];
   1a1c0:	8b 45 08             	mov    0x8(%ebp),%eax
   1a1c3:	8d 50 01             	lea    0x1(%eax),%edx
   1a1c6:	89 55 08             	mov    %edx,0x8(%ebp)
   1a1c9:	8d 4d e3             	lea    -0x1d(%ebp),%ecx
   1a1cc:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1a1cf:	01 ca                	add    %ecx,%edx
   1a1d1:	0f b6 12             	movzbl (%edx),%edx
   1a1d4:	88 10                	mov    %dl,(%eax)
		}
		value <<= 4;
   1a1d6:	c1 65 0c 04          	shll   $0x4,0xc(%ebp)
	for( int i = 0; i < 8; i += 1 ) {
   1a1da:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
   1a1de:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   1a1e2:	7e b7                	jle    1a19b <ucvthex+0x36>
	}

	*buf = '\0';
   1a1e4:	8b 45 08             	mov    0x8(%ebp),%eax
   1a1e7:	c6 00 00             	movb   $0x0,(%eax)

	return( chars_stored );
   1a1ea:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   1a1ed:	c9                   	leave  
   1a1ee:	c3                   	ret    

0001a1ef <ucvtoct>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int ucvtoct( char *buf, uint32_t value ) {
   1a1ef:	55                   	push   %ebp
   1a1f0:	89 e5                	mov    %esp,%ebp
   1a1f2:	83 ec 10             	sub    $0x10,%esp
	int i;
	int chars_stored = 0;
   1a1f5:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	char *bp = buf;
   1a1fc:	8b 45 08             	mov    0x8(%ebp),%eax
   1a1ff:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32_t val;

	val = ( value & 0xc0000000 );
   1a202:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a205:	25 00 00 00 c0       	and    $0xc0000000,%eax
   1a20a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	val >>= 30;
   1a20d:	c1 6d f0 1e          	shrl   $0x1e,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   1a211:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   1a218:	eb 47                	jmp    1a261 <ucvtoct+0x72>

		if( i == 10 || val != 0 || chars_stored ) {
   1a21a:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   1a21e:	74 0c                	je     1a22c <ucvtoct+0x3d>
   1a220:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   1a224:	75 06                	jne    1a22c <ucvtoct+0x3d>
   1a226:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
   1a22a:	74 1e                	je     1a24a <ucvtoct+0x5b>
			chars_stored = 1;
   1a22c:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)
			val &= 0x7;
   1a233:	83 65 f0 07          	andl   $0x7,-0x10(%ebp)
			*bp++ = val + '0';
   1a237:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1a23a:	8d 48 30             	lea    0x30(%eax),%ecx
   1a23d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a240:	8d 50 01             	lea    0x1(%eax),%edx
   1a243:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1a246:	89 ca                	mov    %ecx,%edx
   1a248:	88 10                	mov    %dl,(%eax)
		}
		value <<= 3;
   1a24a:	c1 65 0c 03          	shll   $0x3,0xc(%ebp)
		val = ( value & 0xe0000000 );
   1a24e:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a251:	25 00 00 00 e0       	and    $0xe0000000,%eax
   1a256:	89 45 f0             	mov    %eax,-0x10(%ebp)
		val >>= 29;
   1a259:	c1 6d f0 1d          	shrl   $0x1d,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   1a25d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   1a261:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   1a265:	7e b3                	jle    1a21a <ucvtoct+0x2b>
	}
	*bp = '\0';
   1a267:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a26a:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   1a26d:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1a270:	8b 45 08             	mov    0x8(%ebp),%eax
   1a273:	29 c2                	sub    %eax,%edx
   1a275:	89 d0                	mov    %edx,%eax
}
   1a277:	c9                   	leave  
   1a278:	c3                   	ret    

0001a279 <ucvtuns>:
**
** @return Length of the resulting buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int ucvtuns( char *buf, uint32_t value ) {
   1a279:	55                   	push   %ebp
   1a27a:	89 e5                	mov    %esp,%ebp
   1a27c:	83 ec 18             	sub    $0x18,%esp
	char    *bp = buf;
   1a27f:	8b 45 08             	mov    0x8(%ebp),%eax
   1a282:	89 45 f4             	mov    %eax,-0xc(%ebp)

	bp = ucvtuns0( bp, value );
   1a285:	83 ec 08             	sub    $0x8,%esp
   1a288:	ff 75 0c             	pushl  0xc(%ebp)
   1a28b:	ff 75 f4             	pushl  -0xc(%ebp)
   1a28e:	e8 18 00 00 00       	call   1a2ab <ucvtuns0>
   1a293:	83 c4 10             	add    $0x10,%esp
   1a296:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp = '\0';
   1a299:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a29c:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   1a29f:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1a2a2:	8b 45 08             	mov    0x8(%ebp),%eax
   1a2a5:	29 c2                	sub    %eax,%edx
   1a2a7:	89 d0                	mov    %edx,%eax
}
   1a2a9:	c9                   	leave  
   1a2aa:	c3                   	ret    

0001a2ab <ucvtuns0>:
**
** @return Pointer to the first unused byte in the buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *ucvtuns0( char *buf, uint32_t value ) {
   1a2ab:	55                   	push   %ebp
   1a2ac:	89 e5                	mov    %esp,%ebp
   1a2ae:	83 ec 18             	sub    $0x18,%esp
	uint32_t quotient;

	quotient = value / 10;
   1a2b1:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a2b4:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   1a2b9:	f7 e2                	mul    %edx
   1a2bb:	89 d0                	mov    %edx,%eax
   1a2bd:	c1 e8 03             	shr    $0x3,%eax
   1a2c0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient != 0 ){
   1a2c3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a2c7:	74 15                	je     1a2de <ucvtuns0+0x33>
		buf = ucvtdec0( buf, quotient );
   1a2c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a2cc:	83 ec 08             	sub    $0x8,%esp
   1a2cf:	50                   	push   %eax
   1a2d0:	ff 75 08             	pushl  0x8(%ebp)
   1a2d3:	e8 04 fe ff ff       	call   1a0dc <ucvtdec0>
   1a2d8:	83 c4 10             	add    $0x10,%esp
   1a2db:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   1a2de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   1a2e1:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   1a2e6:	89 c8                	mov    %ecx,%eax
   1a2e8:	f7 e2                	mul    %edx
   1a2ea:	c1 ea 03             	shr    $0x3,%edx
   1a2ed:	89 d0                	mov    %edx,%eax
   1a2ef:	c1 e0 02             	shl    $0x2,%eax
   1a2f2:	01 d0                	add    %edx,%eax
   1a2f4:	01 c0                	add    %eax,%eax
   1a2f6:	29 c1                	sub    %eax,%ecx
   1a2f8:	89 ca                	mov    %ecx,%edx
   1a2fa:	89 d0                	mov    %edx,%eax
   1a2fc:	8d 48 30             	lea    0x30(%eax),%ecx
   1a2ff:	8b 45 08             	mov    0x8(%ebp),%eax
   1a302:	8d 50 01             	lea    0x1(%eax),%edx
   1a305:	89 55 08             	mov    %edx,0x8(%ebp)
   1a308:	89 ca                	mov    %ecx,%edx
   1a30a:	88 10                	mov    %dl,(%eax)
	return buf;
   1a30c:	8b 45 08             	mov    0x8(%ebp),%eax
}
   1a30f:	c9                   	leave  
   1a310:	c3                   	ret    

0001a311 <wait>:
** @param status Pointer to int32_t into which the child's status is placed,
**               or NULL
**
** @returns The PID of the terminated child, or an error code
*/
int wait( int32_t *status ) {
   1a311:	55                   	push   %ebp
   1a312:	89 e5                	mov    %esp,%ebp
   1a314:	83 ec 08             	sub    $0x8,%esp
	return( waitpid(0,status) );
   1a317:	83 ec 08             	sub    $0x8,%esp
   1a31a:	ff 75 08             	pushl  0x8(%ebp)
   1a31d:	6a 00                	push   $0x0
   1a31f:	e8 0c cc ff ff       	call   16f30 <waitpid>
   1a324:	83 c4 10             	add    $0x10,%esp
}
   1a327:	c9                   	leave  
   1a328:	c3                   	ret    

0001a329 <spawn>:
** @param entry The entry point of the 'main' function for the process
** @param args  The command-line argument vector for the new process
**
** @returns PID of the new process, or an error code
*/
int32_t spawn( uint32_t entry, char **args ) {
   1a329:	55                   	push   %ebp
   1a32a:	89 e5                	mov    %esp,%ebp
   1a32c:	81 ec 18 01 00 00    	sub    $0x118,%esp
	int32_t pid;
	char buf[256];

	pid = fork();
   1a332:	e8 01 cc ff ff       	call   16f38 <fork>
   1a337:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( pid != 0 ) {
   1a33a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a33e:	74 05                	je     1a345 <spawn+0x1c>
		// failure, or we are the parent
		return( pid );
   1a340:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a343:	eb 57                	jmp    1a39c <spawn+0x73>
	}

	// we are the child
	pid = getpid();
   1a345:	e8 0e cc ff ff       	call   16f58 <getpid>
   1a34a:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// child inherits parent's priority level

	exec( entry, args );
   1a34d:	83 ec 08             	sub    $0x8,%esp
   1a350:	ff 75 0c             	pushl  0xc(%ebp)
   1a353:	ff 75 08             	pushl  0x8(%ebp)
   1a356:	e8 e5 cb ff ff       	call   16f40 <exec>
   1a35b:	83 c4 10             	add    $0x10,%esp

	// uh-oh....

	usprint( buf, "Child %d exec() %08x failed\n", pid, entry );
   1a35e:	ff 75 08             	pushl  0x8(%ebp)
   1a361:	ff 75 f4             	pushl  -0xc(%ebp)
   1a364:	68 20 c1 01 00       	push   $0x1c120
   1a369:	8d 85 f4 fe ff ff    	lea    -0x10c(%ebp),%eax
   1a36f:	50                   	push   %eax
   1a370:	e8 5d f9 ff ff       	call   19cd2 <usprint>
   1a375:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   1a378:	83 ec 0c             	sub    $0xc,%esp
   1a37b:	8d 85 f4 fe ff ff    	lea    -0x10c(%ebp),%eax
   1a381:	50                   	push   %eax
   1a382:	e8 38 00 00 00       	call   1a3bf <cwrites>
   1a387:	83 c4 10             	add    $0x10,%esp

	exit( EXIT_FAILURE );
   1a38a:	83 ec 0c             	sub    $0xc,%esp
   1a38d:	6a ff                	push   $0xffffffff
   1a38f:	e8 94 cb ff ff       	call   16f28 <exit>
   1a394:	83 c4 10             	add    $0x10,%esp
	return( 0 );   // shut the compiler up
   1a397:	b8 00 00 00 00       	mov    $0x0,%eax
}
   1a39c:	c9                   	leave  
   1a39d:	c3                   	ret    

0001a39e <cwritech>:
**
** @param ch The character to write
**
** @returns The return value from calling write()
*/
int cwritech( char ch ) {
   1a39e:	55                   	push   %ebp
   1a39f:	89 e5                	mov    %esp,%ebp
   1a3a1:	83 ec 18             	sub    $0x18,%esp
   1a3a4:	8b 45 08             	mov    0x8(%ebp),%eax
   1a3a7:	88 45 f4             	mov    %al,-0xc(%ebp)
	return( write(CHAN_CIO,&ch,1) );
   1a3aa:	83 ec 04             	sub    $0x4,%esp
   1a3ad:	6a 01                	push   $0x1
   1a3af:	8d 45 f4             	lea    -0xc(%ebp),%eax
   1a3b2:	50                   	push   %eax
   1a3b3:	6a 00                	push   $0x0
   1a3b5:	e8 96 cb ff ff       	call   16f50 <write>
   1a3ba:	83 c4 10             	add    $0x10,%esp
}
   1a3bd:	c9                   	leave  
   1a3be:	c3                   	ret    

0001a3bf <cwrites>:
** cwrites(str) - write a NUL-terminated string to the console
**
** @param str The string to write
**
*/
int cwrites( const char *str ) {
   1a3bf:	55                   	push   %ebp
   1a3c0:	89 e5                	mov    %esp,%ebp
   1a3c2:	83 ec 18             	sub    $0x18,%esp
	int len = ustrlen(str);
   1a3c5:	ff 75 08             	pushl  0x8(%ebp)
   1a3c8:	e8 82 fc ff ff       	call   1a04f <ustrlen>
   1a3cd:	83 c4 04             	add    $0x4,%esp
   1a3d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return( write(CHAN_CIO,str,len) );
   1a3d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a3d6:	83 ec 04             	sub    $0x4,%esp
   1a3d9:	50                   	push   %eax
   1a3da:	ff 75 08             	pushl  0x8(%ebp)
   1a3dd:	6a 00                	push   $0x0
   1a3df:	e8 6c cb ff ff       	call   16f50 <write>
   1a3e4:	83 c4 10             	add    $0x10,%esp
}
   1a3e7:	c9                   	leave  
   1a3e8:	c3                   	ret    

0001a3e9 <cwrite>:
** @param buf  The buffer to write
** @param size The number of bytes to write
**
** @returns The return value from calling write()
*/
int cwrite( const char *buf, uint32_t size ) {
   1a3e9:	55                   	push   %ebp
   1a3ea:	89 e5                	mov    %esp,%ebp
   1a3ec:	83 ec 08             	sub    $0x8,%esp
	return( write(CHAN_CIO,buf,size) );
   1a3ef:	83 ec 04             	sub    $0x4,%esp
   1a3f2:	ff 75 0c             	pushl  0xc(%ebp)
   1a3f5:	ff 75 08             	pushl  0x8(%ebp)
   1a3f8:	6a 00                	push   $0x0
   1a3fa:	e8 51 cb ff ff       	call   16f50 <write>
   1a3ff:	83 c4 10             	add    $0x10,%esp
}
   1a402:	c9                   	leave  
   1a403:	c3                   	ret    

0001a404 <swritech>:
**
** @param ch The character to write
**
** @returns The return value from calling write()
*/
int swritech( char ch ) {
   1a404:	55                   	push   %ebp
   1a405:	89 e5                	mov    %esp,%ebp
   1a407:	83 ec 18             	sub    $0x18,%esp
   1a40a:	8b 45 08             	mov    0x8(%ebp),%eax
   1a40d:	88 45 f4             	mov    %al,-0xc(%ebp)
	return( write(CHAN_SIO,&ch,1) );
   1a410:	83 ec 04             	sub    $0x4,%esp
   1a413:	6a 01                	push   $0x1
   1a415:	8d 45 f4             	lea    -0xc(%ebp),%eax
   1a418:	50                   	push   %eax
   1a419:	6a 01                	push   $0x1
   1a41b:	e8 30 cb ff ff       	call   16f50 <write>
   1a420:	83 c4 10             	add    $0x10,%esp
}
   1a423:	c9                   	leave  
   1a424:	c3                   	ret    

0001a425 <swrites>:
**
** @param str The string to write
**
** @returns The return value from calling write()
*/
int swrites( const char *str ) {
   1a425:	55                   	push   %ebp
   1a426:	89 e5                	mov    %esp,%ebp
   1a428:	83 ec 18             	sub    $0x18,%esp
	int len = ustrlen(str);
   1a42b:	ff 75 08             	pushl  0x8(%ebp)
   1a42e:	e8 1c fc ff ff       	call   1a04f <ustrlen>
   1a433:	83 c4 04             	add    $0x4,%esp
   1a436:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return( write(CHAN_SIO,str,len) );
   1a439:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a43c:	83 ec 04             	sub    $0x4,%esp
   1a43f:	50                   	push   %eax
   1a440:	ff 75 08             	pushl  0x8(%ebp)
   1a443:	6a 01                	push   $0x1
   1a445:	e8 06 cb ff ff       	call   16f50 <write>
   1a44a:	83 c4 10             	add    $0x10,%esp
}
   1a44d:	c9                   	leave  
   1a44e:	c3                   	ret    

0001a44f <swrite>:
** @param buf  The buffer to write
** @param size The number of bytes to write
**
** @returns The return value from calling write()
*/
int swrite( const char *buf, uint32_t size ) {
   1a44f:	55                   	push   %ebp
   1a450:	89 e5                	mov    %esp,%ebp
   1a452:	83 ec 08             	sub    $0x8,%esp
	return( write(CHAN_SIO,buf,size) );
   1a455:	83 ec 04             	sub    $0x4,%esp
   1a458:	ff 75 0c             	pushl  0xc(%ebp)
   1a45b:	ff 75 08             	pushl  0x8(%ebp)
   1a45e:	6a 01                	push   $0x1
   1a460:	e8 eb ca ff ff       	call   16f50 <write>
   1a465:	83 c4 10             	add    $0x10,%esp
}
   1a468:	c9                   	leave  
   1a469:	c3                   	ret    
