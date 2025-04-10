
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
   10020:	bf 00 d0 01 00       	mov    $0x1d000,%edi

00010025 <clearbss>:
clearbss:
	movl	$0, (%edi)
   10025:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
	addl	$4, %edi
   1002b:	83 c7 04             	add    $0x4,%edi
	cmpl	$_end, %edi
   1002e:	81 ff e4 18 02 00    	cmp    $0x218e4,%edi
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
   10050:	8b 15 14 10 02 00    	mov    0x21014,%edx
	movl	%esp, PCB_context(%edx)
   10056:	89 22                	mov    %esp,(%edx)
	// NOTE: this is inherently non-reentrant!  If/when the OS
	// is converted from monolithic to something that supports
	// reentrant or interruptable ISRs, this code will need to
	// be changed to support that!

	movl	kernel_esp, %esp
   10058:	8b 25 0c c1 01 00    	mov    0x1c10c,%esp

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
   10060:	8b 1c 85 e0 14 02 00 	mov    0x214e0(,%eax,4),%ebx
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
   1006c:	8b 1d 14 10 02 00    	mov    0x21014,%ebx
	movl	PCB_context(%ebx), %esp	// ESP --> context save area
   10072:	8b 23                	mov    (%ebx),%esp
#
# Report system time and PID with context
#
	.globl	system_time

	pushl	PCB_pid(%ebx)
   10074:	ff 73 18             	pushl  0x18(%ebx)
	pushl	system_time
   10077:	ff 35 bc e1 01 00    	pushl  0x1e1bc
	pushl	$fmtall
   1007d:	68 e0 a2 01 00       	push   $0x1a2e0
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
   10afe:	a1 14 d0 01 00       	mov    0x1d014,%eax
   10b03:	89 45 fc             	mov    %eax,-0x4(%ebp)

	if( y > scroll_max_y ) {
   10b06:	a1 0c d0 01 00       	mov    0x1d00c,%eax
   10b0b:	39 45 fc             	cmp    %eax,-0x4(%ebp)
   10b0e:	76 08                	jbe    10b18 <setcursor+0x20>
		y = scroll_max_y;
   10b10:	a1 0c d0 01 00       	mov    0x1d00c,%eax
   10b15:	89 45 fc             	mov    %eax,-0x4(%ebp)
	}

	addr = (unsigned)( y * SCREEN_X_SIZE + curr_x );
   10b18:	8b 55 fc             	mov    -0x4(%ebp),%edx
   10b1b:	89 d0                	mov    %edx,%eax
   10b1d:	c1 e0 02             	shl    $0x2,%eax
   10b20:	01 d0                	add    %edx,%eax
   10b22:	c1 e0 04             	shl    $0x4,%eax
   10b25:	89 c2                	mov    %eax,%edx
   10b27:	a1 10 d0 01 00       	mov    0x1d010,%eax
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
   10b93:	a1 20 d0 01 00       	mov    0x1d020,%eax
   10b98:	39 45 08             	cmp    %eax,0x8(%ebp)
   10b9b:	77 53                	ja     10bf0 <putchar_at+0x63>
   10b9d:	a1 24 d0 01 00       	mov    0x1d024,%eax
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
   10bf9:	8b 15 20 d0 01 00    	mov    0x1d020,%edx
   10bff:	a1 18 d0 01 00       	mov    0x1d018,%eax
   10c04:	83 ec 04             	sub    $0x4,%esp
   10c07:	52                   	push   %edx
   10c08:	ff 75 08             	pushl  0x8(%ebp)
   10c0b:	50                   	push   %eax
   10c0c:	e8 ba 14 00 00       	call   120cb <bound>
   10c11:	83 c4 10             	add    $0x10,%esp
   10c14:	a3 00 d0 01 00       	mov    %eax,0x1d000
	scroll_min_y = bound( min_y, s_min_y, max_y );
   10c19:	8b 15 24 d0 01 00    	mov    0x1d024,%edx
   10c1f:	a1 1c d0 01 00       	mov    0x1d01c,%eax
   10c24:	83 ec 04             	sub    $0x4,%esp
   10c27:	52                   	push   %edx
   10c28:	ff 75 0c             	pushl  0xc(%ebp)
   10c2b:	50                   	push   %eax
   10c2c:	e8 9a 14 00 00       	call   120cb <bound>
   10c31:	83 c4 10             	add    $0x10,%esp
   10c34:	a3 04 d0 01 00       	mov    %eax,0x1d004
	scroll_max_x = bound( scroll_min_x, s_max_x, max_x );
   10c39:	8b 15 20 d0 01 00    	mov    0x1d020,%edx
   10c3f:	a1 00 d0 01 00       	mov    0x1d000,%eax
   10c44:	83 ec 04             	sub    $0x4,%esp
   10c47:	52                   	push   %edx
   10c48:	ff 75 10             	pushl  0x10(%ebp)
   10c4b:	50                   	push   %eax
   10c4c:	e8 7a 14 00 00       	call   120cb <bound>
   10c51:	83 c4 10             	add    $0x10,%esp
   10c54:	a3 08 d0 01 00       	mov    %eax,0x1d008
	scroll_max_y = bound( scroll_min_y, s_max_y, max_y );
   10c59:	8b 15 24 d0 01 00    	mov    0x1d024,%edx
   10c5f:	a1 04 d0 01 00       	mov    0x1d004,%eax
   10c64:	83 ec 04             	sub    $0x4,%esp
   10c67:	52                   	push   %edx
   10c68:	ff 75 14             	pushl  0x14(%ebp)
   10c6b:	50                   	push   %eax
   10c6c:	e8 5a 14 00 00       	call   120cb <bound>
   10c71:	83 c4 10             	add    $0x10,%esp
   10c74:	a3 0c d0 01 00       	mov    %eax,0x1d00c
	curr_x = scroll_min_x;
   10c79:	a1 00 d0 01 00       	mov    0x1d000,%eax
   10c7e:	a3 10 d0 01 00       	mov    %eax,0x1d010
	curr_y = scroll_min_y;
   10c83:	a1 04 d0 01 00       	mov    0x1d004,%eax
   10c88:	a3 14 d0 01 00       	mov    %eax,0x1d014
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
   10c9b:	8b 15 08 d0 01 00    	mov    0x1d008,%edx
   10ca1:	8b 0d 00 d0 01 00    	mov    0x1d000,%ecx
   10ca7:	8b 45 08             	mov    0x8(%ebp),%eax
   10caa:	01 c1                	add    %eax,%ecx
   10cac:	a1 00 d0 01 00       	mov    0x1d000,%eax
   10cb1:	83 ec 04             	sub    $0x4,%esp
   10cb4:	52                   	push   %edx
   10cb5:	51                   	push   %ecx
   10cb6:	50                   	push   %eax
   10cb7:	e8 0f 14 00 00       	call   120cb <bound>
   10cbc:	83 c4 10             	add    $0x10,%esp
   10cbf:	a3 10 d0 01 00       	mov    %eax,0x1d010
	curr_y = bound( scroll_min_y, y + scroll_min_y, scroll_max_y );
   10cc4:	8b 15 0c d0 01 00    	mov    0x1d00c,%edx
   10cca:	8b 0d 04 d0 01 00    	mov    0x1d004,%ecx
   10cd0:	8b 45 0c             	mov    0xc(%ebp),%eax
   10cd3:	01 c1                	add    %eax,%ecx
   10cd5:	a1 04 d0 01 00       	mov    0x1d004,%eax
   10cda:	83 ec 04             	sub    $0x4,%esp
   10cdd:	52                   	push   %edx
   10cde:	51                   	push   %ecx
   10cdf:	50                   	push   %eax
   10ce0:	e8 e6 13 00 00       	call   120cb <bound>
   10ce5:	83 c4 10             	add    $0x10,%esp
   10ce8:	a3 14 d0 01 00       	mov    %eax,0x1d014
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
   10d06:	a1 08 d0 01 00       	mov    0x1d008,%eax
   10d0b:	39 45 08             	cmp    %eax,0x8(%ebp)
   10d0e:	76 0a                	jbe    10d1a <cio_putchar_at+0x25>
			limit = max_x;
   10d10:	a1 20 d0 01 00       	mov    0x1d020,%eax
   10d15:	89 45 fc             	mov    %eax,-0x4(%ebp)
   10d18:	eb 35                	jmp    10d4f <cio_putchar_at+0x5a>
		}
		else if( x >= scroll_min_x ) {
   10d1a:	a1 00 d0 01 00       	mov    0x1d000,%eax
   10d1f:	39 45 08             	cmp    %eax,0x8(%ebp)
   10d22:	72 0a                	jb     10d2e <cio_putchar_at+0x39>
			limit = scroll_max_x;
   10d24:	a1 08 d0 01 00       	mov    0x1d008,%eax
   10d29:	89 45 fc             	mov    %eax,-0x4(%ebp)
   10d2c:	eb 21                	jmp    10d4f <cio_putchar_at+0x5a>
		}
		else {
			limit = scroll_min_x - 1;
   10d2e:	a1 00 d0 01 00       	mov    0x1d000,%eax
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
   10d73:	8b 15 14 d0 01 00    	mov    0x1d014,%edx
   10d79:	a1 0c d0 01 00       	mov    0x1d00c,%eax
   10d7e:	39 c2                	cmp    %eax,%edx
   10d80:	76 25                	jbe    10da7 <cio_putchar+0x3a>
		cio_scroll( curr_y - scroll_max_y );
   10d82:	8b 15 14 d0 01 00    	mov    0x1d014,%edx
   10d88:	a1 0c d0 01 00       	mov    0x1d00c,%eax
   10d8d:	29 c2                	sub    %eax,%edx
   10d8f:	89 d0                	mov    %edx,%eax
   10d91:	83 ec 0c             	sub    $0xc,%esp
   10d94:	50                   	push   %eax
   10d95:	e8 65 02 00 00       	call   10fff <cio_scroll>
   10d9a:	83 c4 10             	add    $0x10,%esp
		curr_y = scroll_max_y;
   10d9d:	a1 0c d0 01 00       	mov    0x1d00c,%eax
   10da2:	a3 14 d0 01 00       	mov    %eax,0x1d014
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
   10db9:	8b 15 14 d0 01 00    	mov    0x1d014,%edx
   10dbf:	a1 10 d0 01 00       	mov    0x1d010,%eax
   10dc4:	83 ec 04             	sub    $0x4,%esp
   10dc7:	6a 20                	push   $0x20
   10dc9:	52                   	push   %edx
   10dca:	50                   	push   %eax
   10dcb:	e8 bd fd ff ff       	call   10b8d <putchar_at>
   10dd0:	83 c4 10             	add    $0x10,%esp
			curr_x += 1;
   10dd3:	a1 10 d0 01 00       	mov    0x1d010,%eax
   10dd8:	83 c0 01             	add    $0x1,%eax
   10ddb:	a3 10 d0 01 00       	mov    %eax,0x1d010
		while( curr_x <= scroll_max_x ) {
   10de0:	8b 15 10 d0 01 00    	mov    0x1d010,%edx
   10de6:	a1 08 d0 01 00       	mov    0x1d008,%eax
   10deb:	39 c2                	cmp    %eax,%edx
   10ded:	76 ca                	jbe    10db9 <cio_putchar+0x4c>
		}
		curr_x = scroll_min_x;
   10def:	a1 00 d0 01 00       	mov    0x1d000,%eax
   10df4:	a3 10 d0 01 00       	mov    %eax,0x1d010
		curr_y += 1;
   10df9:	a1 14 d0 01 00       	mov    0x1d014,%eax
   10dfe:	83 c0 01             	add    $0x1,%eax
   10e01:	a3 14 d0 01 00       	mov    %eax,0x1d014
		break;
   10e06:	eb 5b                	jmp    10e63 <cio_putchar+0xf6>

	case '\r':
		curr_x = scroll_min_x;
   10e08:	a1 00 d0 01 00       	mov    0x1d000,%eax
   10e0d:	a3 10 d0 01 00       	mov    %eax,0x1d010
		break;
   10e12:	eb 4f                	jmp    10e63 <cio_putchar+0xf6>

	default:
		putchar_at( curr_x, curr_y, c );
   10e14:	8b 15 14 d0 01 00    	mov    0x1d014,%edx
   10e1a:	a1 10 d0 01 00       	mov    0x1d010,%eax
   10e1f:	83 ec 04             	sub    $0x4,%esp
   10e22:	ff 75 08             	pushl  0x8(%ebp)
   10e25:	52                   	push   %edx
   10e26:	50                   	push   %eax
   10e27:	e8 61 fd ff ff       	call   10b8d <putchar_at>
   10e2c:	83 c4 10             	add    $0x10,%esp
		curr_x += 1;
   10e2f:	a1 10 d0 01 00       	mov    0x1d010,%eax
   10e34:	83 c0 01             	add    $0x1,%eax
   10e37:	a3 10 d0 01 00       	mov    %eax,0x1d010
		if( curr_x > scroll_max_x ) {
   10e3c:	8b 15 10 d0 01 00    	mov    0x1d010,%edx
   10e42:	a1 08 d0 01 00       	mov    0x1d008,%eax
   10e47:	39 c2                	cmp    %eax,%edx
   10e49:	76 17                	jbe    10e62 <cio_putchar+0xf5>
			curr_x = scroll_min_x;
   10e4b:	a1 00 d0 01 00       	mov    0x1d000,%eax
   10e50:	a3 10 d0 01 00       	mov    %eax,0x1d010
			curr_y += 1;
   10e55:	a1 14 d0 01 00       	mov    0x1d014,%eax
   10e5a:	83 c0 01             	add    $0x1,%eax
   10e5d:	a3 14 d0 01 00       	mov    %eax,0x1d014
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
   10ea0:	a1 20 d0 01 00       	mov    0x1d020,%eax
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
   10f1c:	8b 15 08 d0 01 00    	mov    0x1d008,%edx
   10f22:	a1 00 d0 01 00       	mov    0x1d000,%eax
   10f27:	29 c2                	sub    %eax,%edx
   10f29:	89 d0                	mov    %edx,%eax
   10f2b:	83 c0 01             	add    $0x1,%eax
   10f2e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	unsigned int l;
	unsigned int c;

	for( l = scroll_min_y; l <= scroll_max_y; l += 1 ) {
   10f31:	a1 04 d0 01 00       	mov    0x1d004,%eax
   10f36:	89 45 fc             	mov    %eax,-0x4(%ebp)
   10f39:	eb 47                	jmp    10f82 <cio_clearscroll+0x6c>
		unsigned short *to = VIDEO_ADDR( scroll_min_x, l );
   10f3b:	8b 55 fc             	mov    -0x4(%ebp),%edx
   10f3e:	89 d0                	mov    %edx,%eax
   10f40:	c1 e0 02             	shl    $0x2,%eax
   10f43:	01 d0                	add    %edx,%eax
   10f45:	c1 e0 04             	shl    $0x4,%eax
   10f48:	89 c2                	mov    %eax,%edx
   10f4a:	a1 00 d0 01 00       	mov    0x1d000,%eax
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
   10f82:	a1 0c d0 01 00       	mov    0x1d00c,%eax
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
   10f95:	8b 15 1c d0 01 00    	mov    0x1d01c,%edx
   10f9b:	89 d0                	mov    %edx,%eax
   10f9d:	c1 e0 02             	shl    $0x2,%eax
   10fa0:	01 d0                	add    %edx,%eax
   10fa2:	c1 e0 04             	shl    $0x4,%eax
   10fa5:	89 c2                	mov    %eax,%edx
   10fa7:	a1 18 d0 01 00       	mov    0x1d018,%eax
   10fac:	01 d0                	add    %edx,%eax
   10fae:	05 00 c0 05 00       	add    $0x5c000,%eax
   10fb3:	01 c0                	add    %eax,%eax
   10fb5:	89 45 fc             	mov    %eax,-0x4(%ebp)
	unsigned int    nchars = ( max_y - min_y + 1 ) * ( max_x - min_x + 1 );
   10fb8:	8b 15 24 d0 01 00    	mov    0x1d024,%edx
   10fbe:	a1 1c d0 01 00       	mov    0x1d01c,%eax
   10fc3:	29 c2                	sub    %eax,%edx
   10fc5:	89 d0                	mov    %edx,%eax
   10fc7:	8d 48 01             	lea    0x1(%eax),%ecx
   10fca:	8b 15 20 d0 01 00    	mov    0x1d020,%edx
   10fd0:	a1 18 d0 01 00       	mov    0x1d018,%eax
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
   11005:	8b 15 08 d0 01 00    	mov    0x1d008,%edx
   1100b:	a1 00 d0 01 00       	mov    0x1d000,%eax
   11010:	29 c2                	sub    %eax,%edx
   11012:	89 d0                	mov    %edx,%eax
   11014:	83 c0 01             	add    $0x1,%eax
   11017:	89 45 ec             	mov    %eax,-0x14(%ebp)
	int line, c;

	/*
	** If # of lines is the whole scrolling region or more, just clear.
	*/
	if( lines > scroll_max_y - scroll_min_y ) {
   1101a:	8b 15 0c d0 01 00    	mov    0x1d00c,%edx
   11020:	a1 04 d0 01 00       	mov    0x1d004,%eax
   11025:	29 c2                	sub    %eax,%edx
   11027:	89 d0                	mov    %edx,%eax
   11029:	39 45 08             	cmp    %eax,0x8(%ebp)
   1102c:	76 23                	jbe    11051 <cio_scroll+0x52>
		cio_clearscroll();
   1102e:	e8 e3 fe ff ff       	call   10f16 <cio_clearscroll>
		curr_x = scroll_min_x;
   11033:	a1 00 d0 01 00       	mov    0x1d000,%eax
   11038:	a3 10 d0 01 00       	mov    %eax,0x1d010
		curr_y = scroll_min_y;
   1103d:	a1 04 d0 01 00       	mov    0x1d004,%eax
   11042:	a3 14 d0 01 00       	mov    %eax,0x1d014
		setcursor();
   11047:	e8 ac fa ff ff       	call   10af8 <setcursor>
		return;
   1104c:	e9 ea 00 00 00       	jmp    1113b <cio_scroll+0x13c>
	}

	/*
	** Must copy it line by line.
	*/
	for( line = scroll_min_y; line <= scroll_max_y - lines; line += 1 ) {
   11051:	a1 04 d0 01 00       	mov    0x1d004,%eax
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
   1106f:	a1 00 d0 01 00       	mov    0x1d000,%eax
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
   1108f:	a1 00 d0 01 00       	mov    0x1d000,%eax
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
   110d1:	a1 0c d0 01 00       	mov    0x1d00c,%eax
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
   110f7:	a1 00 d0 01 00       	mov    0x1d000,%eax
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
   11132:	a1 0c d0 01 00       	mov    0x1d00c,%eax
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
   1119b:	e8 bf 18 00 00       	call   12a5f <strlen>
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
   112fa:	8b 04 85 98 a7 01 00 	mov    0x1a798(,%eax,4),%eax
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
   11357:	e8 93 0d 00 00       	call   120ef <cvtdec>
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
   113d3:	e8 e7 0d 00 00       	call   121bf <cvthex>
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
   1141a:	e8 2a 0e 00 00       	call   12249 <cvtoct>
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
   11461:	e8 6d 0e 00 00       	call   122d3 <cvtuns>
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
   114cb:	a1 00 d0 01 00       	mov    0x1d000,%eax
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
   1154a:	b8 08 d1 01 00       	mov    $0x1d108,%eax
   1154f:	39 45 08             	cmp    %eax,0x8(%ebp)
   11552:	72 07                	jb     1155b <increment+0x18>
		pointer = input_buffer;
   11554:	c7 45 08 40 d0 01 00 	movl   $0x1d040,0x8(%ebp)
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
   115a4:	c7 05 08 d1 01 00 01 	movl   $0x1,0x1d108
   115ab:	00 00 00 
		break;
   115ae:	e9 99 00 00 00       	jmp    1164c <input_scan_code+0xec>

	case L_SHIFT_UP:
	case R_SHIFT_UP:
		shift = 0;
   115b3:	c7 05 08 d1 01 00 00 	movl   $0x0,0x1d108
   115ba:	00 00 00 
		break;
   115bd:	e9 8a 00 00 00       	jmp    1164c <input_scan_code+0xec>

	case L_CTRL_DN:
		ctrl_mask = BMASK5;
   115c2:	c7 05 08 c1 01 00 1f 	movl   $0x1f,0x1c108
   115c9:	00 00 00 
		break;
   115cc:	eb 7e                	jmp    1164c <input_scan_code+0xec>

	case L_CTRL_UP:
		ctrl_mask = BMASK8;
   115ce:	c7 05 08 c1 01 00 ff 	movl   $0xff,0x1c108
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
   115e6:	a1 08 d1 01 00       	mov    0x1d108,%eax
   115eb:	c1 e0 07             	shl    $0x7,%eax
   115ee:	89 c2                	mov    %eax,%edx
   115f0:	8b 45 08             	mov    0x8(%ebp),%eax
   115f3:	01 d0                	add    %edx,%eax
   115f5:	05 00 c0 01 00       	add    $0x1c000,%eax
   115fa:	0f b6 00             	movzbl (%eax),%eax
   115fd:	0f b6 c0             	movzbl %al,%eax
   11600:	89 45 08             	mov    %eax,0x8(%ebp)
			if( code != '\377' ) {
   11603:	83 7d 08 ff          	cmpl   $0xffffffff,0x8(%ebp)
   11607:	74 43                	je     1164c <input_scan_code+0xec>
				volatile char   *next = increment( next_space );
   11609:	a1 04 c1 01 00       	mov    0x1c104,%eax
   1160e:	50                   	push   %eax
   1160f:	e8 2f ff ff ff       	call   11543 <increment>
   11614:	83 c4 04             	add    $0x4,%esp
   11617:	89 45 f8             	mov    %eax,-0x8(%ebp)

				/*
				** Store character only if there's room
				*/
				rval = code & ctrl_mask;
   1161a:	a1 08 c1 01 00       	mov    0x1c108,%eax
   1161f:	23 45 08             	and    0x8(%ebp),%eax
   11622:	89 45 fc             	mov    %eax,-0x4(%ebp)
				if( next != next_char ) {
   11625:	a1 00 c1 01 00       	mov    0x1c100,%eax
   1162a:	39 45 f8             	cmp    %eax,-0x8(%ebp)
   1162d:	74 1d                	je     1164c <input_scan_code+0xec>
					*next_space = code & ctrl_mask;
   1162f:	8b 45 08             	mov    0x8(%ebp),%eax
   11632:	89 c1                	mov    %eax,%ecx
   11634:	a1 08 c1 01 00       	mov    0x1c108,%eax
   11639:	89 c2                	mov    %eax,%edx
   1163b:	a1 04 c1 01 00       	mov    0x1c104,%eax
   11640:	21 ca                	and    %ecx,%edx
   11642:	88 10                	mov    %dl,(%eax)
					next_space = next;
   11644:	8b 45 f8             	mov    -0x8(%ebp),%eax
   11647:	a3 04 c1 01 00       	mov    %eax,0x1c104
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
   11685:	a1 28 d0 01 00       	mov    0x1d028,%eax
   1168a:	85 c0                	test   %eax,%eax
   1168c:	74 10                	je     1169e <keyboard_isr+0x4d>
		notify( val );
   1168e:	a1 28 d0 01 00       	mov    0x1d028,%eax
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
   11711:	8b 15 00 c1 01 00    	mov    0x1c100,%edx
   11717:	a1 04 c1 01 00       	mov    0x1c104,%eax
   1171c:	39 c2                	cmp    %eax,%edx
   1171e:	74 ac                	je     116cc <cio_getchar+0x18>
		}
	}

	c = *next_char & BMASK8;
   11720:	a1 00 c1 01 00       	mov    0x1c100,%eax
   11725:	0f b6 00             	movzbl (%eax),%eax
   11728:	88 45 f3             	mov    %al,-0xd(%ebp)
	next_char = increment( next_char );
   1172b:	a1 00 c1 01 00       	mov    0x1c100,%eax
   11730:	50                   	push   %eax
   11731:	e8 0d fe ff ff       	call   11543 <increment>
   11736:	83 c4 04             	add    $0x4,%esp
   11739:	a3 00 c1 01 00       	mov    %eax,0x1c100
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
   117b1:	a1 04 c1 01 00       	mov    0x1c104,%eax
   117b6:	89 c2                	mov    %eax,%edx
   117b8:	a1 00 c1 01 00       	mov    0x1c100,%eax
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
   117dc:	c7 05 18 d0 01 00 00 	movl   $0x0,0x1d018
   117e3:	00 00 00 
	min_y  = SCREEN_MIN_Y;
   117e6:	c7 05 1c d0 01 00 00 	movl   $0x0,0x1d01c
   117ed:	00 00 00 
	max_x  = SCREEN_MAX_X;
   117f0:	c7 05 20 d0 01 00 4f 	movl   $0x4f,0x1d020
   117f7:	00 00 00 
	max_y  = SCREEN_MAX_Y;
   117fa:	c7 05 24 d0 01 00 18 	movl   $0x18,0x1d024
   11801:	00 00 00 

	/*
	** Scrolling region
	*/
	scroll_min_x = SCREEN_MIN_X;
   11804:	c7 05 00 d0 01 00 00 	movl   $0x0,0x1d000
   1180b:	00 00 00 
	scroll_min_y = SCREEN_MIN_Y;
   1180e:	c7 05 04 d0 01 00 00 	movl   $0x0,0x1d004
   11815:	00 00 00 
	scroll_max_x = SCREEN_MAX_X;
   11818:	c7 05 08 d0 01 00 4f 	movl   $0x4f,0x1d008
   1181f:	00 00 00 
	scroll_max_y = SCREEN_MAX_Y;
   11822:	c7 05 0c d0 01 00 18 	movl   $0x18,0x1d00c
   11829:	00 00 00 

	/*
	** Initial cursor location
	*/
	curr_y = min_y;
   1182c:	a1 1c d0 01 00       	mov    0x1d01c,%eax
   11831:	a3 14 d0 01 00       	mov    %eax,0x1d014
	curr_x = min_x;
   11836:	a1 18 d0 01 00       	mov    0x1d018,%eax
   1183b:	a3 10 d0 01 00       	mov    %eax,0x1d010
	setcursor();
   11840:	e8 b3 f2 ff ff       	call   10af8 <setcursor>

	/*
	** Notification function (or NULL)
	*/
	notify = fcn;
   11845:	8b 45 08             	mov    0x8(%ebp),%eax
   11848:	a3 28 d0 01 00       	mov    %eax,0x1d028

	/*
	** Set up the interrupt handler for the keyboard
	*/
	install_isr( VEC_KBD, keyboard_isr );
   1184d:	83 ec 08             	sub    $0x8,%esp
   11850:	68 51 16 01 00       	push   $0x11651
   11855:	6a 21                	push   $0x21
   11857:	e8 05 3f 00 00       	call   15761 <install_isr>
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
   1186b:	a1 0c d1 01 00       	mov    0x1d10c,%eax
   11870:	83 c0 01             	add    $0x1,%eax
   11873:	a3 0c d1 01 00       	mov    %eax,0x1d10c
	if( pinwheel == (CLOCK_FREQ / 10) ) {
   11878:	a1 0c d1 01 00       	mov    0x1d10c,%eax
   1187d:	83 f8 64             	cmp    $0x64,%eax
   11880:	75 39                	jne    118bb <clk_isr+0x59>
		pinwheel = 0;
   11882:	c7 05 0c d1 01 00 00 	movl   $0x0,0x1d10c
   11889:	00 00 00 
		++pindex;
   1188c:	a1 10 d1 01 00       	mov    0x1d110,%eax
   11891:	83 c0 01             	add    $0x1,%eax
   11894:	a3 10 d1 01 00       	mov    %eax,0x1d110
		cio_putchar_at( 0, 0, "|/-\\"[ pindex & 3 ] );
   11899:	a1 10 d1 01 00       	mov    0x1d110,%eax
   1189e:	83 e0 03             	and    $0x3,%eax
   118a1:	0f b6 80 6b a8 01 00 	movzbl 0x1a86b(%eax),%eax
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
   118bb:	8b 0d bc e1 01 00    	mov    0x1e1bc,%ecx
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
   118dd:	a1 04 10 02 00       	mov    0x21004,%eax
   118e2:	83 ec 0c             	sub    $0xc,%esp
   118e5:	50                   	push   %eax
   118e6:	e8 81 25 00 00       	call   13e6c <pcb_queue_length>
   118eb:	83 c4 10             	add    $0x10,%esp
   118ee:	89 45 d4             	mov    %eax,-0x2c(%ebp)
   118f1:	a1 18 10 02 00       	mov    0x21018,%eax
   118f6:	83 ec 0c             	sub    $0xc,%esp
   118f9:	50                   	push   %eax
   118fa:	e8 6d 25 00 00       	call   13e6c <pcb_queue_length>
   118ff:	83 c4 10             	add    $0x10,%esp
   11902:	89 c7                	mov    %eax,%edi
   11904:	a1 08 10 02 00       	mov    0x21008,%eax
   11909:	83 ec 0c             	sub    $0xc,%esp
   1190c:	50                   	push   %eax
   1190d:	e8 5a 25 00 00       	call   13e6c <pcb_queue_length>
   11912:	83 c4 10             	add    $0x10,%esp
   11915:	89 c6                	mov    %eax,%esi
   11917:	a1 10 10 02 00       	mov    0x21010,%eax
   1191c:	83 ec 0c             	sub    $0xc,%esp
   1191f:	50                   	push   %eax
   11920:	e8 47 25 00 00       	call   13e6c <pcb_queue_length>
   11925:	83 c4 10             	add    $0x10,%esp
   11928:	89 c3                	mov    %eax,%ebx
   1192a:	a1 d0 14 02 00       	mov    0x214d0,%eax
   1192f:	83 ec 0c             	sub    $0xc,%esp
   11932:	50                   	push   %eax
   11933:	e8 34 25 00 00       	call   13e6c <pcb_queue_length>
   11938:	83 c4 10             	add    $0x10,%esp
   1193b:	ff 75 d4             	pushl  -0x2c(%ebp)
   1193e:	57                   	push   %edi
   1193f:	56                   	push   %esi
   11940:	53                   	push   %ebx
   11941:	50                   	push   %eax
   11942:	68 f0 a7 01 00       	push   $0x1a7f0
   11947:	6a 00                	push   $0x0
   11949:	6a 01                	push   $0x1
   1194b:	e8 b7 fb ff ff       	call   11507 <cio_printf_at>
   11950:	83 c4 20             	add    $0x20,%esp
		);
	}
#endif

	// time marches on!
	++system_time;
   11953:	a1 bc e1 01 00       	mov    0x1e1bc,%eax
   11958:	83 c0 01             	add    $0x1,%eax
   1195b:	a3 bc e1 01 00       	mov    %eax,0x1e1bc
	// we give them preference over the current process when
	// it is scheduled again

	do {
		// if there isn't anyone in the sleep queue, we're done
		if( pcb_queue_empty(sleeping) ) {
   11960:	a1 08 10 02 00       	mov    0x21008,%eax
   11965:	83 ec 0c             	sub    $0xc,%esp
   11968:	50                   	push   %eax
   11969:	e8 ab 24 00 00       	call   13e19 <pcb_queue_empty>
   1196e:	83 c4 10             	add    $0x10,%esp
   11971:	84 c0                	test   %al,%al
   11973:	0f 85 c7 00 00 00    	jne    11a40 <clk_isr+0x1de>
			break;
		}

		// peek at the first member of the queue
		pcb_t *tmp = pcb_queue_peek( sleeping );
   11979:	a1 08 10 02 00       	mov    0x21008,%eax
   1197e:	83 ec 0c             	sub    $0xc,%esp
   11981:	50                   	push   %eax
   11982:	e8 c5 29 00 00       	call   1434c <pcb_queue_peek>
   11987:	83 c4 10             	add    $0x10,%esp
   1198a:	89 45 dc             	mov    %eax,-0x24(%ebp)
		assert( tmp != NULL );
   1198d:	8b 45 dc             	mov    -0x24(%ebp),%eax
   11990:	85 c0                	test   %eax,%eax
   11992:	75 38                	jne    119cc <clk_isr+0x16a>
   11994:	83 ec 04             	sub    $0x4,%esp
   11997:	68 1a a8 01 00       	push   $0x1a81a
   1199c:	6a 00                	push   $0x0
   1199e:	6a 64                	push   $0x64
   119a0:	68 23 a8 01 00       	push   $0x1a823
   119a5:	68 78 a8 01 00       	push   $0x1a878
   119aa:	68 2b a8 01 00       	push   $0x1a82b
   119af:	68 00 f0 01 00       	push   $0x1f000
   119b4:	e8 29 0d 00 00       	call   126e2 <sprint>
   119b9:	83 c4 20             	add    $0x20,%esp
   119bc:	83 ec 0c             	sub    $0xc,%esp
   119bf:	68 00 f0 01 00       	push   $0x1f000
   119c4:	e8 99 0a 00 00       	call   12462 <kpanic>
   119c9:	83 c4 10             	add    $0x10,%esp
		// the sleep queue is sorted in ascending order by wakeup
		// time, so we know that the retrieved PCB's wakeup time is
		// the earliest of any process on the sleep queue; if that
		// time hasn't arrived yet, there's nobody left to awaken

		if( tmp->wakeup > system_time ) {
   119cc:	8b 45 dc             	mov    -0x24(%ebp),%eax
   119cf:	8b 50 10             	mov    0x10(%eax),%edx
   119d2:	a1 bc e1 01 00       	mov    0x1e1bc,%eax
   119d7:	39 c2                	cmp    %eax,%edx
   119d9:	77 68                	ja     11a43 <clk_isr+0x1e1>
			break;
		}

		// OK, we need to wake this process up
		assert( pcb_queue_remove(sleeping,&tmp) == SUCCESS );
   119db:	a1 08 10 02 00       	mov    0x21008,%eax
   119e0:	83 ec 08             	sub    $0x8,%esp
   119e3:	8d 55 dc             	lea    -0x24(%ebp),%edx
   119e6:	52                   	push   %edx
   119e7:	50                   	push   %eax
   119e8:	e8 ca 26 00 00       	call   140b7 <pcb_queue_remove>
   119ed:	83 c4 10             	add    $0x10,%esp
   119f0:	85 c0                	test   %eax,%eax
   119f2:	74 38                	je     11a2c <clk_isr+0x1ca>
   119f4:	83 ec 04             	sub    $0x4,%esp
   119f7:	68 44 a8 01 00       	push   $0x1a844
   119fc:	6a 00                	push   $0x0
   119fe:	6a 70                	push   $0x70
   11a00:	68 23 a8 01 00       	push   $0x1a823
   11a05:	68 78 a8 01 00       	push   $0x1a878
   11a0a:	68 2b a8 01 00       	push   $0x1a82b
   11a0f:	68 00 f0 01 00       	push   $0x1f000
   11a14:	e8 c9 0c 00 00       	call   126e2 <sprint>
   11a19:	83 c4 20             	add    $0x20,%esp
   11a1c:	83 ec 0c             	sub    $0xc,%esp
   11a1f:	68 00 f0 01 00       	push   $0x1f000
   11a24:	e8 39 0a 00 00       	call   12462 <kpanic>
   11a29:	83 c4 10             	add    $0x10,%esp
		schedule( tmp );
   11a2c:	8b 45 dc             	mov    -0x24(%ebp),%eax
   11a2f:	83 ec 0c             	sub    $0xc,%esp
   11a32:	50                   	push   %eax
   11a33:	e8 72 29 00 00       	call   143aa <schedule>
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
   11a44:	a1 14 10 02 00       	mov    0x21014,%eax
   11a49:	8b 50 24             	mov    0x24(%eax),%edx
   11a4c:	a1 14 10 02 00       	mov    0x21014,%eax
   11a51:	83 ea 01             	sub    $0x1,%edx
   11a54:	89 50 24             	mov    %edx,0x24(%eax)

	// has it expired?
	if( current->ticks < 1 ) {
   11a57:	a1 14 10 02 00       	mov    0x21014,%eax
   11a5c:	8b 40 24             	mov    0x24(%eax),%eax
   11a5f:	85 c0                	test   %eax,%eax
   11a61:	75 20                	jne    11a83 <clk_isr+0x221>
		// yes! reschedule it
		schedule( current );
   11a63:	a1 14 10 02 00       	mov    0x21014,%eax
   11a68:	83 ec 0c             	sub    $0xc,%esp
   11a6b:	50                   	push   %eax
   11a6c:	e8 39 29 00 00       	call   143aa <schedule>
   11a71:	83 c4 10             	add    $0x10,%esp
		current = NULL;
   11a74:	c7 05 14 10 02 00 00 	movl   $0x0,0x21014
   11a7b:	00 00 00 
		// and pick a new process
		dispatch();
   11a7e:	e8 e8 29 00 00       	call   1446b <dispatch>
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
   11aa8:	68 70 a8 01 00       	push   $0x1a870
   11aad:	e8 fb f3 ff ff       	call   10ead <cio_puts>
   11ab2:	83 c4 10             	add    $0x10,%esp
#endif

	// start the pinwheel
	pinwheel = (CLOCK_FREQ / 10) - 1;
   11ab5:	c7 05 0c d1 01 00 63 	movl   $0x63,0x1d10c
   11abc:	00 00 00 
	pindex = 0;
   11abf:	c7 05 10 d1 01 00 00 	movl   $0x0,0x1d110
   11ac6:	00 00 00 

	// return to the dawn of time
	system_time = 0;
   11ac9:	c7 05 bc e1 01 00 00 	movl   $0x0,0x1e1bc
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
   11b2a:	e8 32 3c 00 00       	call   15761 <install_isr>
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
   11b44:	68 80 a8 01 00       	push   $0x1a880
   11b49:	e8 5f f3 ff ff       	call   10ead <cio_puts>
   11b4e:	83 c4 10             	add    $0x10,%esp
	cio_printf( "Config:  N_PROCS = %d", N_PROCS );
   11b51:	83 ec 08             	sub    $0x8,%esp
   11b54:	6a 19                	push   $0x19
   11b56:	68 a2 a8 01 00       	push   $0x1a8a2
   11b5b:	e8 c7 f9 ff ff       	call   11527 <cio_printf>
   11b60:	83 c4 10             	add    $0x10,%esp
	cio_printf( " N_PRIOS = %d", N_PRIOS );
   11b63:	83 ec 08             	sub    $0x8,%esp
   11b66:	6a 04                	push   $0x4
   11b68:	68 b8 a8 01 00       	push   $0x1a8b8
   11b6d:	e8 b5 f9 ff ff       	call   11527 <cio_printf>
   11b72:	83 c4 10             	add    $0x10,%esp
	cio_printf( " N_STATES = %d", N_STATES );
   11b75:	83 ec 08             	sub    $0x8,%esp
   11b78:	6a 09                	push   $0x9
   11b7a:	68 c6 a8 01 00       	push   $0x1a8c6
   11b7f:	e8 a3 f9 ff ff       	call   11527 <cio_printf>
   11b84:	83 c4 10             	add    $0x10,%esp
	cio_printf( " CLOCK = %dHz\n", CLOCK_FREQ );
   11b87:	83 ec 08             	sub    $0x8,%esp
   11b8a:	68 e8 03 00 00       	push   $0x3e8
   11b8f:	68 d5 a8 01 00       	push   $0x1a8d5
   11b94:	e8 8e f9 ff ff       	call   11527 <cio_printf>
   11b99:	83 c4 10             	add    $0x10,%esp

	// This code is ugly, but it's the simplest way to
	// print out the values of compile-time options
	// without spending a lot of execution time at it.

	cio_puts( "Options: "
   11b9c:	83 ec 0c             	sub    $0xc,%esp
   11b9f:	68 e4 a8 01 00       	push   $0x1a8e4
   11ba4:	e8 04 f3 ff ff       	call   10ead <cio_puts>
   11ba9:	83 c4 10             	add    $0x10,%esp
		" Cstats"
#endif
		); // end of cio_puts() call

#ifdef SANITY
	cio_printf( " SANITY = %d", SANITY );
   11bac:	83 ec 08             	sub    $0x8,%esp
   11baf:	68 0f 27 00 00       	push   $0x270f
   11bb4:	68 ff a8 01 00       	push   $0x1a8ff
   11bb9:	e8 69 f9 ff ff       	call   11527 <cio_printf>
   11bbe:	83 c4 10             	add    $0x10,%esp
#ifdef STATUS
	cio_printf( " STATUS = %d", STATUS );
#endif

#if TRACE > 0
	cio_printf( " TRACE = 0x%04x\n", TRACE );
   11bc1:	83 ec 08             	sub    $0x8,%esp
   11bc4:	68 00 01 00 00       	push   $0x100
   11bc9:	68 0c a9 01 00       	push   $0x1a90c
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
   11bdf:	68 1d a9 01 00       	push   $0x1a91d
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
   11c5b:	68 2b a9 01 00       	push   $0x1a92b
   11c60:	e8 96 2c 00 00       	call   148fb <ptable_dump>
   11c65:	83 c4 10             	add    $0x10,%esp
		break;
   11c68:	e9 db 00 00 00       	jmp    11d48 <stats+0x14c>

	case 'c':  // dump context info for all active PCBs
		ctx_dump_all( "\nContext dump" );
   11c6d:	83 ec 0c             	sub    $0xc,%esp
   11c70:	68 3d a9 01 00       	push   $0x1a93d
   11c75:	e8 ba 29 00 00       	call   14634 <ctx_dump_all>
   11c7a:	83 c4 10             	add    $0x10,%esp
		break;
   11c7d:	e9 c6 00 00 00       	jmp    11d48 <stats+0x14c>

	case 'p':  // dump the active table and all PCBs
		ptable_dump( "\nActive processes", true );
   11c82:	83 ec 08             	sub    $0x8,%esp
   11c85:	6a 01                	push   $0x1
   11c87:	68 2b a9 01 00       	push   $0x1a92b
   11c8c:	e8 6a 2c 00 00       	call   148fb <ptable_dump>
   11c91:	83 c4 10             	add    $0x10,%esp
		break;
   11c94:	e9 af 00 00 00       	jmp    11d48 <stats+0x14c>

	case 'q':  // dump the queues
		// code to dump out any/all queues
		pcb_queue_dump( "R", ready, true );
   11c99:	a1 d0 14 02 00       	mov    0x214d0,%eax
   11c9e:	83 ec 04             	sub    $0x4,%esp
   11ca1:	6a 01                	push   $0x1
   11ca3:	50                   	push   %eax
   11ca4:	68 4b a9 01 00       	push   $0x1a94b
   11ca9:	e8 3a 2b 00 00       	call   147e8 <pcb_queue_dump>
   11cae:	83 c4 10             	add    $0x10,%esp
		pcb_queue_dump( "W", waiting, true );
   11cb1:	a1 10 10 02 00       	mov    0x21010,%eax
   11cb6:	83 ec 04             	sub    $0x4,%esp
   11cb9:	6a 01                	push   $0x1
   11cbb:	50                   	push   %eax
   11cbc:	68 4d a9 01 00       	push   $0x1a94d
   11cc1:	e8 22 2b 00 00       	call   147e8 <pcb_queue_dump>
   11cc6:	83 c4 10             	add    $0x10,%esp
		pcb_queue_dump( "S", sleeping, true );
   11cc9:	a1 08 10 02 00       	mov    0x21008,%eax
   11cce:	83 ec 04             	sub    $0x4,%esp
   11cd1:	6a 01                	push   $0x1
   11cd3:	50                   	push   %eax
   11cd4:	68 4f a9 01 00       	push   $0x1a94f
   11cd9:	e8 0a 2b 00 00       	call   147e8 <pcb_queue_dump>
   11cde:	83 c4 10             	add    $0x10,%esp
		pcb_queue_dump( "Z", zombie, true );
   11ce1:	a1 18 10 02 00       	mov    0x21018,%eax
   11ce6:	83 ec 04             	sub    $0x4,%esp
   11ce9:	6a 01                	push   $0x1
   11ceb:	50                   	push   %eax
   11cec:	68 51 a9 01 00       	push   $0x1a951
   11cf1:	e8 f2 2a 00 00       	call   147e8 <pcb_queue_dump>
   11cf6:	83 c4 10             	add    $0x10,%esp
		pcb_queue_dump( "I", sioread, true );
   11cf9:	a1 04 10 02 00       	mov    0x21004,%eax
   11cfe:	83 ec 04             	sub    $0x4,%esp
   11d01:	6a 01                	push   $0x1
   11d03:	50                   	push   %eax
   11d04:	68 53 a9 01 00       	push   $0x1a953
   11d09:	e8 da 2a 00 00       	call   147e8 <pcb_queue_dump>
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
   11d28:	68 58 a9 01 00       	push   $0x1a958
   11d2d:	e8 f5 f7 ff ff       	call   11527 <cio_printf>
   11d32:	83 c4 10             	add    $0x10,%esp
		// FALL THROUGH

	case 'h':  // help message
		cio_puts( "\nCommands:\n"
   11d35:	83 ec 0c             	sub    $0xc,%esp
   11d38:	68 7c a9 01 00       	push   $0x1a97c
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
   11d5d:	e8 ec 39 00 00       	call   1574e <init_interrupts>
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
   11d7a:	68 48 aa 01 00       	push   $0x1aa48
   11d7f:	e8 29 f1 ff ff       	call   10ead <cio_puts>
   11d84:	83 c4 10             	add    $0x10,%esp
	cio_puts( "-------------------------------\n" );
   11d87:	83 ec 0c             	sub    $0xc,%esp
   11d8a:	68 6c aa 01 00       	push   $0x1aa6c
   11d8f:	e8 19 f1 ff ff       	call   10ead <cio_puts>
   11d94:	83 c4 10             	add    $0x10,%esp

#if TRACING_INIT
	cio_puts( "Modules:" );
   11d97:	83 ec 0c             	sub    $0xc,%esp
   11d9a:	68 8d aa 01 00       	push   $0x1aa8d
   11d9f:	e8 09 f1 ff ff       	call   10ead <cio_puts>
   11da4:	83 c4 10             	add    $0x10,%esp
#endif

	// call the module initialization functions, being
	// careful to follow any module precedence requirements

	km_init();		// MUST BE FIRST
   11da7:	e8 df 0d 00 00       	call   12b8b <km_init>

	// other module initialization calls here
	clk_init();     // clock
   11dac:	e8 ee fc ff ff       	call   11a9f <clk_init>
	pcb_init();     // process (PCBs, queues, scheduler)
   11db1:	e8 0a 18 00 00       	call   135c0 <pcb_init>
	sio_init();     // serial i/o
   11db6:	e8 19 30 00 00       	call   14dd4 <sio_init>
	sys_init();     // system call
   11dbb:	e8 9a 4c 00 00       	call   16a5a <sys_init>
	user_init();    // user code handling
   11dc0:	e8 77 4f 00 00       	call   16d3c <user_init>

	cio_puts( "\nModule initialization complete.\n" );
   11dc5:	83 ec 0c             	sub    $0xc,%esp
   11dc8:	68 98 aa 01 00       	push   $0x1aa98
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
   11de5:	68 6c aa 01 00       	push   $0x1aa6c
   11dea:	e8 be f0 ff ff       	call   10ead <cio_puts>
   11def:	83 c4 10             	add    $0x10,%esp
	** This code is largely stolen from the fork() and exec()
	** implementations in syscalls.c; if those change, this must
	** also change.
	*/

	cio_puts( "Creating initial user process..." );
   11df2:	83 ec 0c             	sub    $0xc,%esp
   11df5:	68 bc aa 01 00       	push   $0x1aabc
   11dfa:	e8 ae f0 ff ff       	call   10ead <cio_puts>
   11dff:	83 c4 10             	add    $0x10,%esp

	// if we can't get a PCB, there's no use continuing!
	assert( pcb_alloc(&init_pcb) == SUCCESS );
   11e02:	83 ec 0c             	sub    $0xc,%esp
   11e05:	68 0c 10 02 00       	push   $0x2100c
   11e0a:	e8 32 1a 00 00       	call   13841 <pcb_alloc>
   11e0f:	83 c4 10             	add    $0x10,%esp
   11e12:	85 c0                	test   %eax,%eax
   11e14:	74 3b                	je     11e51 <main+0x106>
   11e16:	83 ec 04             	sub    $0x4,%esp
   11e19:	68 dd aa 01 00       	push   $0x1aadd
   11e1e:	6a 00                	push   $0x0
   11e20:	68 53 01 00 00       	push   $0x153
   11e25:	68 f9 aa 01 00       	push   $0x1aaf9
   11e2a:	68 20 ac 01 00       	push   $0x1ac20
   11e2f:	68 02 ab 01 00       	push   $0x1ab02
   11e34:	68 00 f0 01 00       	push   $0x1f000
   11e39:	e8 a4 08 00 00       	call   126e2 <sprint>
   11e3e:	83 c4 20             	add    $0x20,%esp
   11e41:	83 ec 0c             	sub    $0xc,%esp
   11e44:	68 00 f0 01 00       	push   $0x1f000
   11e49:	e8 14 06 00 00       	call   12462 <kpanic>
   11e4e:	83 c4 10             	add    $0x10,%esp

	// fill in the necessary details
	init_pcb->pid = PID_INIT;
   11e51:	a1 0c 10 02 00       	mov    0x2100c,%eax
   11e56:	c7 40 18 01 00 00 00 	movl   $0x1,0x18(%eax)
	init_pcb->state = STATE_NEW;
   11e5d:	a1 0c 10 02 00       	mov    0x2100c,%eax
   11e62:	c7 40 1c 01 00 00 00 	movl   $0x1,0x1c(%eax)
	init_pcb->priority = PRIO_HIGH;
   11e69:	a1 0c 10 02 00       	mov    0x2100c,%eax
   11e6e:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

	// command-line arguments for 'init'
	const char *args[3] = { "init", "+", NULL };
   11e75:	c7 45 ec 18 ab 01 00 	movl   $0x1ab18,-0x14(%ebp)
   11e7c:	c7 45 f0 1d ab 01 00 	movl   $0x1ab1d,-0x10(%ebp)
   11e83:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// the entry point for 'init'
	extern int init(int,char **);

	// allocate a default-sized stack
	init_pcb->stack = pcb_stack_alloc( N_USTKPAGES );
   11e8a:	8b 1d 0c 10 02 00    	mov    0x2100c,%ebx
   11e90:	83 ec 0c             	sub    $0xc,%esp
   11e93:	6a 02                	push   $0x2
   11e95:	e8 a7 1a 00 00       	call   13941 <pcb_stack_alloc>
   11e9a:	83 c4 10             	add    $0x10,%esp
   11e9d:	89 43 04             	mov    %eax,0x4(%ebx)
	assert( init_pcb->stack != NULL );
   11ea0:	a1 0c 10 02 00       	mov    0x2100c,%eax
   11ea5:	8b 40 04             	mov    0x4(%eax),%eax
   11ea8:	85 c0                	test   %eax,%eax
   11eaa:	75 3b                	jne    11ee7 <main+0x19c>
   11eac:	83 ec 04             	sub    $0x4,%esp
   11eaf:	68 1f ab 01 00       	push   $0x1ab1f
   11eb4:	6a 00                	push   $0x0
   11eb6:	68 62 01 00 00       	push   $0x162
   11ebb:	68 f9 aa 01 00       	push   $0x1aaf9
   11ec0:	68 20 ac 01 00       	push   $0x1ac20
   11ec5:	68 02 ab 01 00       	push   $0x1ab02
   11eca:	68 00 f0 01 00       	push   $0x1f000
   11ecf:	e8 0e 08 00 00       	call   126e2 <sprint>
   11ed4:	83 c4 20             	add    $0x20,%esp
   11ed7:	83 ec 0c             	sub    $0xc,%esp
   11eda:	68 00 f0 01 00       	push   $0x1f000
   11edf:	e8 7e 05 00 00       	call   12462 <kpanic>
   11ee4:	83 c4 10             	add    $0x10,%esp
	// remember that we used the default size
	init_pcb->stkpgs = N_USTKPAGES;
   11ee7:	a1 0c 10 02 00       	mov    0x2100c,%eax
   11eec:	c7 40 28 02 00 00 00 	movl   $0x2,0x28(%eax)

	// initialize the stack and the context to be restored
	init_pcb->context = stack_setup( init_pcb, (uint32_t) init, args, true );
   11ef3:	b9 43 73 01 00       	mov    $0x17343,%ecx
   11ef8:	a1 0c 10 02 00       	mov    0x2100c,%eax
   11efd:	8b 1d 0c 10 02 00    	mov    0x2100c,%ebx
   11f03:	6a 01                	push   $0x1
   11f05:	8d 55 ec             	lea    -0x14(%ebp),%edx
   11f08:	52                   	push   %edx
   11f09:	51                   	push   %ecx
   11f0a:	50                   	push   %eax
   11f0b:	e8 78 4b 00 00       	call   16a88 <stack_setup>
   11f10:	83 c4 10             	add    $0x10,%esp
   11f13:	89 03                	mov    %eax,(%ebx)
	assert( init_pcb->context != NULL );
   11f15:	a1 0c 10 02 00       	mov    0x2100c,%eax
   11f1a:	8b 00                	mov    (%eax),%eax
   11f1c:	85 c0                	test   %eax,%eax
   11f1e:	75 3b                	jne    11f5b <main+0x210>
   11f20:	83 ec 04             	sub    $0x4,%esp
   11f23:	68 34 ab 01 00       	push   $0x1ab34
   11f28:	6a 00                	push   $0x0
   11f2a:	68 68 01 00 00       	push   $0x168
   11f2f:	68 f9 aa 01 00       	push   $0x1aaf9
   11f34:	68 20 ac 01 00       	push   $0x1ac20
   11f39:	68 02 ab 01 00       	push   $0x1ab02
   11f3e:	68 00 f0 01 00       	push   $0x1f000
   11f43:	e8 9a 07 00 00       	call   126e2 <sprint>
   11f48:	83 c4 20             	add    $0x20,%esp
   11f4b:	83 ec 0c             	sub    $0xc,%esp
   11f4e:	68 00 f0 01 00       	push   $0x1f000
   11f53:	e8 0a 05 00 00       	call   12462 <kpanic>
   11f58:	83 c4 10             	add    $0x10,%esp

	// "i'm my own grandpa...."
	init_pcb->parent = init_pcb;
   11f5b:	a1 0c 10 02 00       	mov    0x2100c,%eax
   11f60:	8b 15 0c 10 02 00    	mov    0x2100c,%edx
   11f66:	89 50 0c             	mov    %edx,0xc(%eax)

	// send it on its merry way
	schedule( init_pcb );
   11f69:	a1 0c 10 02 00       	mov    0x2100c,%eax
   11f6e:	83 ec 0c             	sub    $0xc,%esp
   11f71:	50                   	push   %eax
   11f72:	e8 33 24 00 00       	call   143aa <schedule>
   11f77:	83 c4 10             	add    $0x10,%esp

	// make sure there's no current process
	current = NULL;
   11f7a:	c7 05 14 10 02 00 00 	movl   $0x0,0x21014
   11f81:	00 00 00 

	// pick a winner
	dispatch();
   11f84:	e8 e2 24 00 00       	call   1446b <dispatch>

	cio_puts( " done.\n" );
   11f89:	83 ec 0c             	sub    $0xc,%esp
   11f8c:	68 4b ab 01 00       	push   $0x1ab4b
   11f91:	e8 17 ef ff ff       	call   10ead <cio_puts>
   11f96:	83 c4 10             	add    $0x10,%esp

	delay( DELAY_1_SEC );
   11f99:	83 ec 0c             	sub    $0xc,%esp
   11f9c:	6a 28                	push   $0x28
   11f9e:	e8 e3 37 00 00       	call   15786 <delay>
   11fa3:	83 c4 10             	add    $0x10,%esp

#ifdef TRACE_CX

	// wipe out whatever is on the screen at the moment
	cio_clearscreen();
   11fa6:	e8 e4 ef ff ff       	call   10f8f <cio_clearscreen>

	// define a scrolling region in the top 7 lines of the screen
	cio_setscroll( 0, 7, 99, 99 );
   11fab:	6a 63                	push   $0x63
   11fad:	6a 63                	push   $0x63
   11faf:	6a 07                	push   $0x7
   11fb1:	6a 00                	push   $0x0
   11fb3:	e8 3b ec ff ff       	call   10bf3 <cio_setscroll>
   11fb8:	83 c4 10             	add    $0x10,%esp

	// clear it
	cio_clearscroll();
   11fbb:	e8 56 ef ff ff       	call   10f16 <cio_clearscroll>

	// clear the top line
	cio_puts_at( 0, 0, "*                                                                               " );
   11fc0:	83 ec 04             	sub    $0x4,%esp
   11fc3:	68 54 ab 01 00       	push   $0x1ab54
   11fc8:	6a 00                	push   $0x0
   11fca:	6a 00                	push   $0x0
   11fcc:	e8 9a ee ff ff       	call   10e6b <cio_puts_at>
   11fd1:	83 c4 10             	add    $0x10,%esp
	// separator
	cio_puts_at( 0, 6, "================================================================================" );
   11fd4:	83 ec 04             	sub    $0x4,%esp
   11fd7:	68 a8 ab 01 00       	push   $0x1aba8
   11fdc:	6a 06                	push   $0x6
   11fde:	6a 00                	push   $0x0
   11fe0:	e8 86 ee ff ff       	call   10e6b <cio_puts_at>
   11fe5:	83 c4 10             	add    $0x10,%esp

	/*
	** END OF TERM-SPECIFIC CODE
	*/

	sio_flush( SIO_RX | SIO_TX );
   11fe8:	83 ec 0c             	sub    $0xc,%esp
   11feb:	6a 03                	push   $0x3
   11fed:	e8 45 30 00 00       	call   15037 <sio_flush>
   11ff2:	83 c4 10             	add    $0x10,%esp
	sio_enable( SIO_RX );
   11ff5:	83 ec 0c             	sub    $0xc,%esp
   11ff8:	6a 02                	push   $0x2
   11ffa:	e8 48 2f 00 00       	call   14f47 <sio_enable>
   11fff:	83 c4 10             	add    $0x10,%esp

	cio_puts( "System initialization complete.\n" );
   12002:	83 ec 0c             	sub    $0xc,%esp
   12005:	68 fc ab 01 00       	push   $0x1abfc
   1200a:	e8 9e ee ff ff       	call   10ead <cio_puts>
   1200f:	83 c4 10             	add    $0x10,%esp
	cio_puts( "-------------------------------\n" );
   12012:	83 ec 0c             	sub    $0xc,%esp
   12015:	68 6c aa 01 00       	push   $0x1aa6c
   1201a:	e8 8e ee ff ff       	call   10ead <cio_puts>
   1201f:	83 c4 10             	add    $0x10,%esp
	pcb_dump( "Current: ", current, true );

	delay( DELAY_2_SEC );
#endif

	return 0;
   12022:	b8 00 00 00 00       	mov    $0x0,%eax
}
   12027:	8d 65 f8             	lea    -0x8(%ebp),%esp
   1202a:	59                   	pop    %ecx
   1202b:	5b                   	pop    %ebx
   1202c:	5d                   	pop    %ebp
   1202d:	8d 61 fc             	lea    -0x4(%ecx),%esp
   12030:	c3                   	ret    

00012031 <blkmov>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void blkmov( void *dst, const void *src, register uint32_t len ) {
   12031:	55                   	push   %ebp
   12032:	89 e5                	mov    %esp,%ebp
   12034:	56                   	push   %esi
   12035:	53                   	push   %ebx
   12036:	8b 45 10             	mov    0x10(%ebp),%eax

	// verify that the addresses are aligned and
	// the length is a multiple of four bytes
	if( (((uint32_t)dst)&0x3) != 0 ||
   12039:	8b 55 08             	mov    0x8(%ebp),%edx
   1203c:	83 e2 03             	and    $0x3,%edx
   1203f:	85 d2                	test   %edx,%edx
   12041:	75 13                	jne    12056 <blkmov+0x25>
		(((uint32_t)src)&0x3) != 0 ||
   12043:	8b 55 0c             	mov    0xc(%ebp),%edx
   12046:	83 e2 03             	and    $0x3,%edx
	if( (((uint32_t)dst)&0x3) != 0 ||
   12049:	85 d2                	test   %edx,%edx
   1204b:	75 09                	jne    12056 <blkmov+0x25>
		(len & 0x3) != 0 ) {
   1204d:	89 c2                	mov    %eax,%edx
   1204f:	83 e2 03             	and    $0x3,%edx
		(((uint32_t)src)&0x3) != 0 ||
   12052:	85 d2                	test   %edx,%edx
   12054:	74 14                	je     1206a <blkmov+0x39>
		// something isn't aligned, so just use memmove()
		memmove( dst, src, len );
   12056:	83 ec 04             	sub    $0x4,%esp
   12059:	50                   	push   %eax
   1205a:	ff 75 0c             	pushl  0xc(%ebp)
   1205d:	ff 75 08             	pushl  0x8(%ebp)
   12060:	e8 48 05 00 00       	call   125ad <memmove>
   12065:	83 c4 10             	add    $0x10,%esp
		return;
   12068:	eb 5a                	jmp    120c4 <blkmov+0x93>
	}

	// everything is nicely aligned, so off we go
	register uint32_t *dest = dst;
   1206a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint32_t *source = src;
   1206d:	8b 75 0c             	mov    0xc(%ebp),%esi

	// now copying 32-bit values
	len /= 4;
   12070:	c1 e8 02             	shr    $0x2,%eax

	if( source < dest && (source + len) > dest ) {
   12073:	39 de                	cmp    %ebx,%esi
   12075:	73 44                	jae    120bb <blkmov+0x8a>
   12077:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1207e:	01 f2                	add    %esi,%edx
   12080:	39 d3                	cmp    %edx,%ebx
   12082:	73 37                	jae    120bb <blkmov+0x8a>
		source += len;
   12084:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1208b:	01 d6                	add    %edx,%esi
		dest += len;
   1208d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   12094:	01 d3                	add    %edx,%ebx
		while( len-- > 0 ) {
   12096:	eb 0a                	jmp    120a2 <blkmov+0x71>
			*--dest = *--source;
   12098:	83 ee 04             	sub    $0x4,%esi
   1209b:	83 eb 04             	sub    $0x4,%ebx
   1209e:	8b 16                	mov    (%esi),%edx
   120a0:	89 13                	mov    %edx,(%ebx)
		while( len-- > 0 ) {
   120a2:	89 c2                	mov    %eax,%edx
   120a4:	8d 42 ff             	lea    -0x1(%edx),%eax
   120a7:	85 d2                	test   %edx,%edx
   120a9:	75 ed                	jne    12098 <blkmov+0x67>
	if( source < dest && (source + len) > dest ) {
   120ab:	eb 17                	jmp    120c4 <blkmov+0x93>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   120ad:	89 f1                	mov    %esi,%ecx
   120af:	8d 71 04             	lea    0x4(%ecx),%esi
   120b2:	89 da                	mov    %ebx,%edx
   120b4:	8d 5a 04             	lea    0x4(%edx),%ebx
   120b7:	8b 09                	mov    (%ecx),%ecx
   120b9:	89 0a                	mov    %ecx,(%edx)
		while( len-- ) {
   120bb:	89 c2                	mov    %eax,%edx
   120bd:	8d 42 ff             	lea    -0x1(%edx),%eax
   120c0:	85 d2                	test   %edx,%edx
   120c2:	75 e9                	jne    120ad <blkmov+0x7c>
		}
	}
}
   120c4:	8d 65 f8             	lea    -0x8(%ebp),%esp
   120c7:	5b                   	pop    %ebx
   120c8:	5e                   	pop    %esi
   120c9:	5d                   	pop    %ebp
   120ca:	c3                   	ret    

000120cb <bound>:
** @param value  Value to be constrained
** @param max    Upper bound
**
** @return The constrained value
*/
uint32_t bound( uint32_t min, uint32_t value, uint32_t max ) {
   120cb:	55                   	push   %ebp
   120cc:	89 e5                	mov    %esp,%ebp
	if( value < min ){
   120ce:	8b 45 0c             	mov    0xc(%ebp),%eax
   120d1:	3b 45 08             	cmp    0x8(%ebp),%eax
   120d4:	73 06                	jae    120dc <bound+0x11>
		value = min;
   120d6:	8b 45 08             	mov    0x8(%ebp),%eax
   120d9:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	if( value > max ){
   120dc:	8b 45 0c             	mov    0xc(%ebp),%eax
   120df:	3b 45 10             	cmp    0x10(%ebp),%eax
   120e2:	76 06                	jbe    120ea <bound+0x1f>
		value = max;
   120e4:	8b 45 10             	mov    0x10(%ebp),%eax
   120e7:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	return value;
   120ea:	8b 45 0c             	mov    0xc(%ebp),%eax
}
   120ed:	5d                   	pop    %ebp
   120ee:	c3                   	ret    

000120ef <cvtdec>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtdec( char *buf, int32_t value ) {
   120ef:	55                   	push   %ebp
   120f0:	89 e5                	mov    %esp,%ebp
   120f2:	83 ec 18             	sub    $0x18,%esp
	char *bp = buf;
   120f5:	8b 45 08             	mov    0x8(%ebp),%eax
   120f8:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if( value < 0 ) {
   120fb:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   120ff:	79 0f                	jns    12110 <cvtdec+0x21>
		*bp++ = '-';
   12101:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12104:	8d 50 01             	lea    0x1(%eax),%edx
   12107:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1210a:	c6 00 2d             	movb   $0x2d,(%eax)
		value = -value;
   1210d:	f7 5d 0c             	negl   0xc(%ebp)
	}

	bp = cvtdec0( bp, value );
   12110:	83 ec 08             	sub    $0x8,%esp
   12113:	ff 75 0c             	pushl  0xc(%ebp)
   12116:	ff 75 f4             	pushl  -0xc(%ebp)
   12119:	e8 18 00 00 00       	call   12136 <cvtdec0>
   1211e:	83 c4 10             	add    $0x10,%esp
   12121:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp  = '\0';
   12124:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12127:	c6 00 00             	movb   $0x0,(%eax)

	return( bp - buf );
   1212a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1212d:	8b 45 08             	mov    0x8(%ebp),%eax
   12130:	29 c2                	sub    %eax,%edx
   12132:	89 d0                	mov    %edx,%eax
}
   12134:	c9                   	leave  
   12135:	c3                   	ret    

00012136 <cvtdec0>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *cvtdec0( char *buf, int value ) {
   12136:	55                   	push   %ebp
   12137:	89 e5                	mov    %esp,%ebp
   12139:	83 ec 18             	sub    $0x18,%esp
	int quotient;

	quotient = value / 10;
   1213c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   1213f:	ba 67 66 66 66       	mov    $0x66666667,%edx
   12144:	89 c8                	mov    %ecx,%eax
   12146:	f7 ea                	imul   %edx
   12148:	c1 fa 02             	sar    $0x2,%edx
   1214b:	89 c8                	mov    %ecx,%eax
   1214d:	c1 f8 1f             	sar    $0x1f,%eax
   12150:	29 c2                	sub    %eax,%edx
   12152:	89 d0                	mov    %edx,%eax
   12154:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient < 0 ) {
   12157:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1215b:	79 0e                	jns    1216b <cvtdec0+0x35>
		quotient = 214748364;
   1215d:	c7 45 f4 cc cc cc 0c 	movl   $0xccccccc,-0xc(%ebp)
		value = 8;
   12164:	c7 45 0c 08 00 00 00 	movl   $0x8,0xc(%ebp)
	}
	if( quotient != 0 ) {
   1216b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1216f:	74 14                	je     12185 <cvtdec0+0x4f>
		buf = cvtdec0( buf, quotient );
   12171:	83 ec 08             	sub    $0x8,%esp
   12174:	ff 75 f4             	pushl  -0xc(%ebp)
   12177:	ff 75 08             	pushl  0x8(%ebp)
   1217a:	e8 b7 ff ff ff       	call   12136 <cvtdec0>
   1217f:	83 c4 10             	add    $0x10,%esp
   12182:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   12185:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   12188:	ba 67 66 66 66       	mov    $0x66666667,%edx
   1218d:	89 c8                	mov    %ecx,%eax
   1218f:	f7 ea                	imul   %edx
   12191:	c1 fa 02             	sar    $0x2,%edx
   12194:	89 c8                	mov    %ecx,%eax
   12196:	c1 f8 1f             	sar    $0x1f,%eax
   12199:	29 c2                	sub    %eax,%edx
   1219b:	89 d0                	mov    %edx,%eax
   1219d:	c1 e0 02             	shl    $0x2,%eax
   121a0:	01 d0                	add    %edx,%eax
   121a2:	01 c0                	add    %eax,%eax
   121a4:	29 c1                	sub    %eax,%ecx
   121a6:	89 ca                	mov    %ecx,%edx
   121a8:	89 d0                	mov    %edx,%eax
   121aa:	8d 48 30             	lea    0x30(%eax),%ecx
   121ad:	8b 45 08             	mov    0x8(%ebp),%eax
   121b0:	8d 50 01             	lea    0x1(%eax),%edx
   121b3:	89 55 08             	mov    %edx,0x8(%ebp)
   121b6:	89 ca                	mov    %ecx,%edx
   121b8:	88 10                	mov    %dl,(%eax)
	return buf;
   121ba:	8b 45 08             	mov    0x8(%ebp),%eax
}
   121bd:	c9                   	leave  
   121be:	c3                   	ret    

000121bf <cvthex>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvthex( char *buf, uint32_t value ) {
   121bf:	55                   	push   %ebp
   121c0:	89 e5                	mov    %esp,%ebp
   121c2:	83 ec 20             	sub    $0x20,%esp
	const char hexdigits[] = "0123456789ABCDEF";
   121c5:	c7 45 e3 30 31 32 33 	movl   $0x33323130,-0x1d(%ebp)
   121cc:	c7 45 e7 34 35 36 37 	movl   $0x37363534,-0x19(%ebp)
   121d3:	c7 45 eb 38 39 41 42 	movl   $0x42413938,-0x15(%ebp)
   121da:	c7 45 ef 43 44 45 46 	movl   $0x46454443,-0x11(%ebp)
   121e1:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)
	int chars_stored = 0;
   121e5:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)

	for( int i = 0; i < 8; i += 1 ) {
   121ec:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
   121f3:	eb 43                	jmp    12238 <cvthex+0x79>
		uint32_t val = value & 0xf0000000;
   121f5:	8b 45 0c             	mov    0xc(%ebp),%eax
   121f8:	25 00 00 00 f0       	and    $0xf0000000,%eax
   121fd:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if( chars_stored || val != 0 || i == 7 ) {
   12200:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
   12204:	75 0c                	jne    12212 <cvthex+0x53>
   12206:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1220a:	75 06                	jne    12212 <cvthex+0x53>
   1220c:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   12210:	75 1e                	jne    12230 <cvthex+0x71>
			++chars_stored;
   12212:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
			val = (val >> 28) & 0xf;
   12216:	c1 6d f4 1c          	shrl   $0x1c,-0xc(%ebp)
			*buf++ = hexdigits[val];
   1221a:	8b 45 08             	mov    0x8(%ebp),%eax
   1221d:	8d 50 01             	lea    0x1(%eax),%edx
   12220:	89 55 08             	mov    %edx,0x8(%ebp)
   12223:	8d 4d e3             	lea    -0x1d(%ebp),%ecx
   12226:	8b 55 f4             	mov    -0xc(%ebp),%edx
   12229:	01 ca                	add    %ecx,%edx
   1222b:	0f b6 12             	movzbl (%edx),%edx
   1222e:	88 10                	mov    %dl,(%eax)
		}
		value <<= 4;
   12230:	c1 65 0c 04          	shll   $0x4,0xc(%ebp)
	for( int i = 0; i < 8; i += 1 ) {
   12234:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
   12238:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   1223c:	7e b7                	jle    121f5 <cvthex+0x36>
	}

	*buf = '\0';
   1223e:	8b 45 08             	mov    0x8(%ebp),%eax
   12241:	c6 00 00             	movb   $0x0,(%eax)

	return( chars_stored );
   12244:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   12247:	c9                   	leave  
   12248:	c3                   	ret    

00012249 <cvtoct>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtoct( char *buf, uint32_t value ) {
   12249:	55                   	push   %ebp
   1224a:	89 e5                	mov    %esp,%ebp
   1224c:	83 ec 10             	sub    $0x10,%esp
	int i;
	int chars_stored = 0;
   1224f:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	char *bp = buf;
   12256:	8b 45 08             	mov    0x8(%ebp),%eax
   12259:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32_t val;

	val = ( value & 0xc0000000 );
   1225c:	8b 45 0c             	mov    0xc(%ebp),%eax
   1225f:	25 00 00 00 c0       	and    $0xc0000000,%eax
   12264:	89 45 f0             	mov    %eax,-0x10(%ebp)
	val >>= 30;
   12267:	c1 6d f0 1e          	shrl   $0x1e,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   1226b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   12272:	eb 47                	jmp    122bb <cvtoct+0x72>

		if( i == 10 || val != 0 || chars_stored ) {
   12274:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   12278:	74 0c                	je     12286 <cvtoct+0x3d>
   1227a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   1227e:	75 06                	jne    12286 <cvtoct+0x3d>
   12280:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
   12284:	74 1e                	je     122a4 <cvtoct+0x5b>
			chars_stored = 1;
   12286:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)
			val &= 0x7;
   1228d:	83 65 f0 07          	andl   $0x7,-0x10(%ebp)
			*bp++ = val + '0';
   12291:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12294:	8d 48 30             	lea    0x30(%eax),%ecx
   12297:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1229a:	8d 50 01             	lea    0x1(%eax),%edx
   1229d:	89 55 f4             	mov    %edx,-0xc(%ebp)
   122a0:	89 ca                	mov    %ecx,%edx
   122a2:	88 10                	mov    %dl,(%eax)
		}
		value <<= 3;
   122a4:	c1 65 0c 03          	shll   $0x3,0xc(%ebp)
		val = ( value & 0xe0000000 );
   122a8:	8b 45 0c             	mov    0xc(%ebp),%eax
   122ab:	25 00 00 00 e0       	and    $0xe0000000,%eax
   122b0:	89 45 f0             	mov    %eax,-0x10(%ebp)
		val >>= 29;
   122b3:	c1 6d f0 1d          	shrl   $0x1d,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   122b7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   122bb:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   122bf:	7e b3                	jle    12274 <cvtoct+0x2b>
	}
	*bp = '\0';
   122c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
   122c4:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   122c7:	8b 55 f4             	mov    -0xc(%ebp),%edx
   122ca:	8b 45 08             	mov    0x8(%ebp),%eax
   122cd:	29 c2                	sub    %eax,%edx
   122cf:	89 d0                	mov    %edx,%eax
}
   122d1:	c9                   	leave  
   122d2:	c3                   	ret    

000122d3 <cvtuns>:
**
** @return Length of the resulting buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int cvtuns( char *buf, uint32_t value ) {
   122d3:	55                   	push   %ebp
   122d4:	89 e5                	mov    %esp,%ebp
   122d6:	83 ec 18             	sub    $0x18,%esp
	char    *bp = buf;
   122d9:	8b 45 08             	mov    0x8(%ebp),%eax
   122dc:	89 45 f4             	mov    %eax,-0xc(%ebp)

	bp = cvtuns0( bp, value );
   122df:	83 ec 08             	sub    $0x8,%esp
   122e2:	ff 75 0c             	pushl  0xc(%ebp)
   122e5:	ff 75 f4             	pushl  -0xc(%ebp)
   122e8:	e8 18 00 00 00       	call   12305 <cvtuns0>
   122ed:	83 c4 10             	add    $0x10,%esp
   122f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp = '\0';
   122f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
   122f6:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   122f9:	8b 55 f4             	mov    -0xc(%ebp),%edx
   122fc:	8b 45 08             	mov    0x8(%ebp),%eax
   122ff:	29 c2                	sub    %eax,%edx
   12301:	89 d0                	mov    %edx,%eax
}
   12303:	c9                   	leave  
   12304:	c3                   	ret    

00012305 <cvtuns0>:
**
** @return Pointer to the first unused byte in the buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *cvtuns0( char *buf, uint32_t value ) {
   12305:	55                   	push   %ebp
   12306:	89 e5                	mov    %esp,%ebp
   12308:	83 ec 18             	sub    $0x18,%esp
	uint32_t quotient;

	quotient = value / 10;
   1230b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1230e:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   12313:	f7 e2                	mul    %edx
   12315:	89 d0                	mov    %edx,%eax
   12317:	c1 e8 03             	shr    $0x3,%eax
   1231a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient != 0 ){
   1231d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12321:	74 15                	je     12338 <cvtuns0+0x33>
		buf = cvtdec0( buf, quotient );
   12323:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12326:	83 ec 08             	sub    $0x8,%esp
   12329:	50                   	push   %eax
   1232a:	ff 75 08             	pushl  0x8(%ebp)
   1232d:	e8 04 fe ff ff       	call   12136 <cvtdec0>
   12332:	83 c4 10             	add    $0x10,%esp
   12335:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   12338:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   1233b:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   12340:	89 c8                	mov    %ecx,%eax
   12342:	f7 e2                	mul    %edx
   12344:	c1 ea 03             	shr    $0x3,%edx
   12347:	89 d0                	mov    %edx,%eax
   12349:	c1 e0 02             	shl    $0x2,%eax
   1234c:	01 d0                	add    %edx,%eax
   1234e:	01 c0                	add    %eax,%eax
   12350:	29 c1                	sub    %eax,%ecx
   12352:	89 ca                	mov    %ecx,%edx
   12354:	89 d0                	mov    %edx,%eax
   12356:	8d 48 30             	lea    0x30(%eax),%ecx
   12359:	8b 45 08             	mov    0x8(%ebp),%eax
   1235c:	8d 50 01             	lea    0x1(%eax),%edx
   1235f:	89 55 08             	mov    %edx,0x8(%ebp)
   12362:	89 ca                	mov    %ecx,%edx
   12364:	88 10                	mov    %dl,(%eax)
	return buf;
   12366:	8b 45 08             	mov    0x8(%ebp),%eax
}
   12369:	c9                   	leave  
   1236a:	c3                   	ret    

0001236b <put_char_or_code>:
** is a non-printing character, in which case its hex code
** is printed
**
** @param ch    The character to be printed
*/
void put_char_or_code( int ch ) {
   1236b:	55                   	push   %ebp
   1236c:	89 e5                	mov    %esp,%ebp
   1236e:	83 ec 08             	sub    $0x8,%esp

	if( ch >= ' ' && ch < 0x7f ) {
   12371:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
   12375:	7e 17                	jle    1238e <put_char_or_code+0x23>
   12377:	83 7d 08 7e          	cmpl   $0x7e,0x8(%ebp)
   1237b:	7f 11                	jg     1238e <put_char_or_code+0x23>
		cio_putchar( ch );
   1237d:	8b 45 08             	mov    0x8(%ebp),%eax
   12380:	83 ec 0c             	sub    $0xc,%esp
   12383:	50                   	push   %eax
   12384:	e8 e4 e9 ff ff       	call   10d6d <cio_putchar>
   12389:	83 c4 10             	add    $0x10,%esp
   1238c:	eb 13                	jmp    123a1 <put_char_or_code+0x36>
	} else {
		cio_printf( "\\x%02x", ch );
   1238e:	83 ec 08             	sub    $0x8,%esp
   12391:	ff 75 08             	pushl  0x8(%ebp)
   12394:	68 28 ac 01 00       	push   $0x1ac28
   12399:	e8 89 f1 ff ff       	call   11527 <cio_printf>
   1239e:	83 c4 10             	add    $0x10,%esp
	}
}
   123a1:	90                   	nop
   123a2:	c9                   	leave  
   123a3:	c3                   	ret    

000123a4 <backtrace>:
** Perform a stack backtrace
**
** @param ebp   Initial EBP to use
** @param args  Number of function argument values to print
*/
void backtrace( uint32_t *ebp, uint_t args ) {
   123a4:	55                   	push   %ebp
   123a5:	89 e5                	mov    %esp,%ebp
   123a7:	83 ec 18             	sub    $0x18,%esp

	cio_puts( "Trace:  " );
   123aa:	83 ec 0c             	sub    $0xc,%esp
   123ad:	68 2f ac 01 00       	push   $0x1ac2f
   123b2:	e8 f6 ea ff ff       	call   10ead <cio_puts>
   123b7:	83 c4 10             	add    $0x10,%esp
	if( ebp == NULL ) {
   123ba:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   123be:	75 15                	jne    123d5 <backtrace+0x31>
		cio_puts( "NULL ebp, no trace possible\n" );
   123c0:	83 ec 0c             	sub    $0xc,%esp
   123c3:	68 38 ac 01 00       	push   $0x1ac38
   123c8:	e8 e0 ea ff ff       	call   10ead <cio_puts>
   123cd:	83 c4 10             	add    $0x10,%esp
		return;
   123d0:	e9 8b 00 00 00       	jmp    12460 <backtrace+0xbc>
	} else {
		cio_putchar( '\n' );
   123d5:	83 ec 0c             	sub    $0xc,%esp
   123d8:	6a 0a                	push   $0xa
   123da:	e8 8e e9 ff ff       	call   10d6d <cio_putchar>
   123df:	83 c4 10             	add    $0x10,%esp
	}

	while( ebp != NULL ){
   123e2:	eb 76                	jmp    1245a <backtrace+0xb6>

		// get return address and report it and EBP
		uint32_t ret = ebp[1];
   123e4:	8b 45 08             	mov    0x8(%ebp),%eax
   123e7:	8b 40 04             	mov    0x4(%eax),%eax
   123ea:	89 45 f0             	mov    %eax,-0x10(%ebp)
		cio_printf( " ebp %08x ret %08x args", (uint32_t) ebp, ret );
   123ed:	8b 45 08             	mov    0x8(%ebp),%eax
   123f0:	83 ec 04             	sub    $0x4,%esp
   123f3:	ff 75 f0             	pushl  -0x10(%ebp)
   123f6:	50                   	push   %eax
   123f7:	68 55 ac 01 00       	push   $0x1ac55
   123fc:	e8 26 f1 ff ff       	call   11527 <cio_printf>
   12401:	83 c4 10             	add    $0x10,%esp

		// print the requested number of function arguments
		for( uint_t i = 0; i < args; ++i ) {
   12404:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   1240b:	eb 30                	jmp    1243d <backtrace+0x99>
			cio_printf( " [%u] %08x", i+1, ebp[2+i] );
   1240d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12410:	83 c0 02             	add    $0x2,%eax
   12413:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1241a:	8b 45 08             	mov    0x8(%ebp),%eax
   1241d:	01 d0                	add    %edx,%eax
   1241f:	8b 00                	mov    (%eax),%eax
   12421:	8b 55 f4             	mov    -0xc(%ebp),%edx
   12424:	83 c2 01             	add    $0x1,%edx
   12427:	83 ec 04             	sub    $0x4,%esp
   1242a:	50                   	push   %eax
   1242b:	52                   	push   %edx
   1242c:	68 6d ac 01 00       	push   $0x1ac6d
   12431:	e8 f1 f0 ff ff       	call   11527 <cio_printf>
   12436:	83 c4 10             	add    $0x10,%esp
		for( uint_t i = 0; i < args; ++i ) {
   12439:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   1243d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12440:	3b 45 0c             	cmp    0xc(%ebp),%eax
   12443:	72 c8                	jb     1240d <backtrace+0x69>
		}
		cio_putchar( '\n' );
   12445:	83 ec 0c             	sub    $0xc,%esp
   12448:	6a 0a                	push   $0xa
   1244a:	e8 1e e9 ff ff       	call   10d6d <cio_putchar>
   1244f:	83 c4 10             	add    $0x10,%esp

		// follow the chain
		ebp = (uint32_t *) *ebp;
   12452:	8b 45 08             	mov    0x8(%ebp),%eax
   12455:	8b 00                	mov    (%eax),%eax
   12457:	89 45 08             	mov    %eax,0x8(%ebp)
	while( ebp != NULL ){
   1245a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1245e:	75 84                	jne    123e4 <backtrace+0x40>
	}
}
   12460:	c9                   	leave  
   12461:	c3                   	ret    

00012462 <kpanic>:
** (e.g., printing a stack traceback)
**
** @param msg[in]  String containing a relevant message to be printed,
**				   or NULL
*/
void kpanic( const char *msg ) {
   12462:	55                   	push   %ebp
   12463:	89 e5                	mov    %esp,%ebp
   12465:	83 ec 18             	sub    $0x18,%esp

	cio_puts( "\n\n***** KERNEL PANIC *****\n\n" );
   12468:	83 ec 0c             	sub    $0xc,%esp
   1246b:	68 78 ac 01 00       	push   $0x1ac78
   12470:	e8 38 ea ff ff       	call   10ead <cio_puts>
   12475:	83 c4 10             	add    $0x10,%esp

	if( msg ) {
   12478:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1247c:	74 13                	je     12491 <kpanic+0x2f>
		cio_printf( "%s\n", msg );
   1247e:	83 ec 08             	sub    $0x8,%esp
   12481:	ff 75 08             	pushl  0x8(%ebp)
   12484:	68 95 ac 01 00       	push   $0x1ac95
   12489:	e8 99 f0 ff ff       	call   11527 <cio_printf>
   1248e:	83 c4 10             	add    $0x10,%esp
	}

	delay( DELAY_5_SEC );   // approximately
   12491:	83 ec 0c             	sub    $0xc,%esp
   12494:	68 c8 00 00 00       	push   $0xc8
   12499:	e8 e8 32 00 00       	call   15786 <delay>
   1249e:	83 c4 10             	add    $0x10,%esp

	// dump a bunch of potentially useful information

	// dump the contents of the current PCB
	pcb_dump( "Current", current, true );
   124a1:	a1 14 10 02 00       	mov    0x21014,%eax
   124a6:	83 ec 04             	sub    $0x4,%esp
   124a9:	6a 01                	push   $0x1
   124ab:	50                   	push   %eax
   124ac:	68 99 ac 01 00       	push   $0x1ac99
   124b1:	e8 f3 21 00 00       	call   146a9 <pcb_dump>
   124b6:	83 c4 10             	add    $0x10,%esp

	// dump the basic info about what's in the process table
	ptable_dump_counts();
   124b9:	e8 28 25 00 00       	call   149e6 <ptable_dump_counts>

	// dump information about the queues
	pcb_queue_dump( "R", ready, true );
   124be:	a1 d0 14 02 00       	mov    0x214d0,%eax
   124c3:	83 ec 04             	sub    $0x4,%esp
   124c6:	6a 01                	push   $0x1
   124c8:	50                   	push   %eax
   124c9:	68 a1 ac 01 00       	push   $0x1aca1
   124ce:	e8 15 23 00 00       	call   147e8 <pcb_queue_dump>
   124d3:	83 c4 10             	add    $0x10,%esp
	pcb_queue_dump( "W", waiting, true );
   124d6:	a1 10 10 02 00       	mov    0x21010,%eax
   124db:	83 ec 04             	sub    $0x4,%esp
   124de:	6a 01                	push   $0x1
   124e0:	50                   	push   %eax
   124e1:	68 a3 ac 01 00       	push   $0x1aca3
   124e6:	e8 fd 22 00 00       	call   147e8 <pcb_queue_dump>
   124eb:	83 c4 10             	add    $0x10,%esp
	pcb_queue_dump( "S", sleeping, true );
   124ee:	a1 08 10 02 00       	mov    0x21008,%eax
   124f3:	83 ec 04             	sub    $0x4,%esp
   124f6:	6a 01                	push   $0x1
   124f8:	50                   	push   %eax
   124f9:	68 a5 ac 01 00       	push   $0x1aca5
   124fe:	e8 e5 22 00 00       	call   147e8 <pcb_queue_dump>
   12503:	83 c4 10             	add    $0x10,%esp
	pcb_queue_dump( "Z", zombie, true );
   12506:	a1 18 10 02 00       	mov    0x21018,%eax
   1250b:	83 ec 04             	sub    $0x4,%esp
   1250e:	6a 01                	push   $0x1
   12510:	50                   	push   %eax
   12511:	68 a7 ac 01 00       	push   $0x1aca7
   12516:	e8 cd 22 00 00       	call   147e8 <pcb_queue_dump>
   1251b:	83 c4 10             	add    $0x10,%esp
	pcb_queue_dump( "I", sioread, true );
   1251e:	a1 04 10 02 00       	mov    0x21004,%eax
   12523:	83 ec 04             	sub    $0x4,%esp
   12526:	6a 01                	push   $0x1
   12528:	50                   	push   %eax
   12529:	68 a9 ac 01 00       	push   $0x1aca9
   1252e:	e8 b5 22 00 00       	call   147e8 <pcb_queue_dump>
   12533:	83 c4 10             	add    $0x10,%esp
	__asm__ __volatile__( "movl %%ebp,%0" : "=r" (val) );
   12536:	89 e8                	mov    %ebp,%eax
   12538:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return val;
   1253b:	8b 45 f4             	mov    -0xc(%ebp),%eax

	// perform a stack backtrace
	backtrace( (uint32_t *) r_ebp(), 3 );
   1253e:	83 ec 08             	sub    $0x8,%esp
   12541:	6a 03                	push   $0x3
   12543:	50                   	push   %eax
   12544:	e8 5b fe ff ff       	call   123a4 <backtrace>
   12549:	83 c4 10             	add    $0x10,%esp

	// could dump other stuff here, too

	panic( "KERNEL PANIC" );
   1254c:	83 ec 0c             	sub    $0xc,%esp
   1254f:	68 ab ac 01 00       	push   $0x1acab
   12554:	e8 d9 31 00 00       	call   15732 <panic>
   12559:	83 c4 10             	add    $0x10,%esp
}
   1255c:	90                   	nop
   1255d:	c9                   	leave  
   1255e:	c3                   	ret    

0001255f <memclr>:
** Initialize all bytes of a block of memory to zero
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
*/
void memclr( void *buf, register uint32_t len ) {
   1255f:	55                   	push   %ebp
   12560:	89 e5                	mov    %esp,%ebp
   12562:	53                   	push   %ebx
   12563:	8b 55 0c             	mov    0xc(%ebp),%edx
	register uint8_t *dest = buf;
   12566:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and clearing
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   12569:	eb 08                	jmp    12573 <memclr+0x14>
			*dest++ = 0;
   1256b:	89 d8                	mov    %ebx,%eax
   1256d:	8d 58 01             	lea    0x1(%eax),%ebx
   12570:	c6 00 00             	movb   $0x0,(%eax)
	while( len-- ) {
   12573:	89 d0                	mov    %edx,%eax
   12575:	8d 50 ff             	lea    -0x1(%eax),%edx
   12578:	85 c0                	test   %eax,%eax
   1257a:	75 ef                	jne    1256b <memclr+0xc>
	}
}
   1257c:	90                   	nop
   1257d:	5b                   	pop    %ebx
   1257e:	5d                   	pop    %ebp
   1257f:	c3                   	ret    

00012580 <memcpy>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void memcpy( void *dst, register const void *src, register uint32_t len ) {
   12580:	55                   	push   %ebp
   12581:	89 e5                	mov    %esp,%ebp
   12583:	56                   	push   %esi
   12584:	53                   	push   %ebx
   12585:	8b 4d 10             	mov    0x10(%ebp),%ecx
	register uint8_t *dest = dst;
   12588:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint8_t *source = src;
   1258b:	8b 75 0c             	mov    0xc(%ebp),%esi
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   1258e:	eb 0f                	jmp    1259f <memcpy+0x1f>
		*dest++ = *source++;
   12590:	89 f2                	mov    %esi,%edx
   12592:	8d 72 01             	lea    0x1(%edx),%esi
   12595:	89 d8                	mov    %ebx,%eax
   12597:	8d 58 01             	lea    0x1(%eax),%ebx
   1259a:	0f b6 12             	movzbl (%edx),%edx
   1259d:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   1259f:	89 c8                	mov    %ecx,%eax
   125a1:	8d 48 ff             	lea    -0x1(%eax),%ecx
   125a4:	85 c0                	test   %eax,%eax
   125a6:	75 e8                	jne    12590 <memcpy+0x10>
	}
}
   125a8:	90                   	nop
   125a9:	5b                   	pop    %ebx
   125aa:	5e                   	pop    %esi
   125ab:	5d                   	pop    %ebp
   125ac:	c3                   	ret    

000125ad <memmove>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void memmove( void *dst, const void *src, register uint32_t len ) {
   125ad:	55                   	push   %ebp
   125ae:	89 e5                	mov    %esp,%ebp
   125b0:	56                   	push   %esi
   125b1:	53                   	push   %ebx
   125b2:	8b 45 10             	mov    0x10(%ebp),%eax
	register uint8_t *dest = dst;
   125b5:	8b 75 08             	mov    0x8(%ebp),%esi
	register const uint8_t *source = src;
   125b8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	if( source < dest && (source + len) > dest ) {
   125bb:	39 f3                	cmp    %esi,%ebx
   125bd:	73 32                	jae    125f1 <memmove+0x44>
   125bf:	8d 14 03             	lea    (%ebx,%eax,1),%edx
   125c2:	39 d6                	cmp    %edx,%esi
   125c4:	73 2b                	jae    125f1 <memmove+0x44>
		source += len;
   125c6:	01 c3                	add    %eax,%ebx
		dest += len;
   125c8:	01 c6                	add    %eax,%esi
		while( len-- > 0 ) {
   125ca:	eb 0b                	jmp    125d7 <memmove+0x2a>
			*--dest = *--source;
   125cc:	83 eb 01             	sub    $0x1,%ebx
   125cf:	83 ee 01             	sub    $0x1,%esi
   125d2:	0f b6 13             	movzbl (%ebx),%edx
   125d5:	88 16                	mov    %dl,(%esi)
		while( len-- > 0 ) {
   125d7:	89 c2                	mov    %eax,%edx
   125d9:	8d 42 ff             	lea    -0x1(%edx),%eax
   125dc:	85 d2                	test   %edx,%edx
   125de:	75 ec                	jne    125cc <memmove+0x1f>
	if( source < dest && (source + len) > dest ) {
   125e0:	eb 18                	jmp    125fa <memmove+0x4d>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   125e2:	89 d9                	mov    %ebx,%ecx
   125e4:	8d 59 01             	lea    0x1(%ecx),%ebx
   125e7:	89 f2                	mov    %esi,%edx
   125e9:	8d 72 01             	lea    0x1(%edx),%esi
   125ec:	0f b6 09             	movzbl (%ecx),%ecx
   125ef:	88 0a                	mov    %cl,(%edx)
		while( len-- ) {
   125f1:	89 c2                	mov    %eax,%edx
   125f3:	8d 42 ff             	lea    -0x1(%edx),%eax
   125f6:	85 d2                	test   %edx,%edx
   125f8:	75 e8                	jne    125e2 <memmove+0x35>
		}
	}
}
   125fa:	90                   	nop
   125fb:	5b                   	pop    %ebx
   125fc:	5e                   	pop    %esi
   125fd:	5d                   	pop    %ebp
   125fe:	c3                   	ret    

000125ff <memset>:
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
** @param value  Initialization value
*/
void memset( void *buf, register uint32_t len, register uint32_t value ) {
   125ff:	55                   	push   %ebp
   12600:	89 e5                	mov    %esp,%ebp
   12602:	53                   	push   %ebx
   12603:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register uint8_t *bp = buf;
   12606:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   12609:	eb 0b                	jmp    12616 <memset+0x17>
		*bp++ = value;
   1260b:	89 d8                	mov    %ebx,%eax
   1260d:	8d 58 01             	lea    0x1(%eax),%ebx
   12610:	0f b6 55 10          	movzbl 0x10(%ebp),%edx
   12614:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   12616:	89 c8                	mov    %ecx,%eax
   12618:	8d 48 ff             	lea    -0x1(%eax),%ecx
   1261b:	85 c0                	test   %eax,%eax
   1261d:	75 ec                	jne    1260b <memset+0xc>
	}
}
   1261f:	90                   	nop
   12620:	5b                   	pop    %ebx
   12621:	5d                   	pop    %ebp
   12622:	c3                   	ret    

00012623 <pad>:
**
** @return Pointer to the first byte after the padding
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *pad( char *dst, int extra, int padchar ) {
   12623:	55                   	push   %ebp
   12624:	89 e5                	mov    %esp,%ebp
	while( extra > 0 ){
   12626:	eb 12                	jmp    1263a <pad+0x17>
		*dst++ = (char) padchar;
   12628:	8b 45 08             	mov    0x8(%ebp),%eax
   1262b:	8d 50 01             	lea    0x1(%eax),%edx
   1262e:	89 55 08             	mov    %edx,0x8(%ebp)
   12631:	8b 55 10             	mov    0x10(%ebp),%edx
   12634:	88 10                	mov    %dl,(%eax)
		extra -= 1;
   12636:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
	while( extra > 0 ){
   1263a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   1263e:	7f e8                	jg     12628 <pad+0x5>
	}
	return dst;
   12640:	8b 45 08             	mov    0x8(%ebp),%eax
}
   12643:	5d                   	pop    %ebp
   12644:	c3                   	ret    

00012645 <padstr>:
** @return Pointer to the first byte after the padded string
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *padstr( char *dst, char *str, int len, int width,
				int leftadjust, int padchar ) {
   12645:	55                   	push   %ebp
   12646:	89 e5                	mov    %esp,%ebp
   12648:	83 ec 18             	sub    $0x18,%esp
	int extra;

	// determine the length of the string if we need to
	if( len < 0 ){
   1264b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
   1264f:	79 11                	jns    12662 <padstr+0x1d>
		len = strlen( str );
   12651:	83 ec 0c             	sub    $0xc,%esp
   12654:	ff 75 0c             	pushl  0xc(%ebp)
   12657:	e8 03 04 00 00       	call   12a5f <strlen>
   1265c:	83 c4 10             	add    $0x10,%esp
   1265f:	89 45 10             	mov    %eax,0x10(%ebp)
	}

	// how much filler must we add?
	extra = width - len;
   12662:	8b 45 14             	mov    0x14(%ebp),%eax
   12665:	2b 45 10             	sub    0x10(%ebp),%eax
   12668:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// add filler on the left if we're not left-justifying
	if( extra > 0 && !leftadjust ){
   1266b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   1266f:	7e 1d                	jle    1268e <padstr+0x49>
   12671:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   12675:	75 17                	jne    1268e <padstr+0x49>
		dst = pad( dst, extra, padchar );
   12677:	83 ec 04             	sub    $0x4,%esp
   1267a:	ff 75 1c             	pushl  0x1c(%ebp)
   1267d:	ff 75 f0             	pushl  -0x10(%ebp)
   12680:	ff 75 08             	pushl  0x8(%ebp)
   12683:	e8 9b ff ff ff       	call   12623 <pad>
   12688:	83 c4 10             	add    $0x10,%esp
   1268b:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	// copy the string itself
	for( int i = 0; i < len; ++i ) {
   1268e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   12695:	eb 1b                	jmp    126b2 <padstr+0x6d>
		*dst++ = str[i];
   12697:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1269a:	8b 45 0c             	mov    0xc(%ebp),%eax
   1269d:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
   126a0:	8b 45 08             	mov    0x8(%ebp),%eax
   126a3:	8d 50 01             	lea    0x1(%eax),%edx
   126a6:	89 55 08             	mov    %edx,0x8(%ebp)
   126a9:	0f b6 11             	movzbl (%ecx),%edx
   126ac:	88 10                	mov    %dl,(%eax)
	for( int i = 0; i < len; ++i ) {
   126ae:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   126b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
   126b5:	3b 45 10             	cmp    0x10(%ebp),%eax
   126b8:	7c dd                	jl     12697 <padstr+0x52>
	}

	// add filler on the right if we are left-justifying
	if( extra > 0 && leftadjust ){
   126ba:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   126be:	7e 1d                	jle    126dd <padstr+0x98>
   126c0:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   126c4:	74 17                	je     126dd <padstr+0x98>
		dst = pad( dst, extra, padchar );
   126c6:	83 ec 04             	sub    $0x4,%esp
   126c9:	ff 75 1c             	pushl  0x1c(%ebp)
   126cc:	ff 75 f0             	pushl  -0x10(%ebp)
   126cf:	ff 75 08             	pushl  0x8(%ebp)
   126d2:	e8 4c ff ff ff       	call   12623 <pad>
   126d7:	83 c4 10             	add    $0x10,%esp
   126da:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	return dst;
   126dd:	8b 45 08             	mov    0x8(%ebp),%eax
}
   126e0:	c9                   	leave  
   126e1:	c3                   	ret    

000126e2 <sprint>:
**
** NOTE:  relies heavily on the x86 parameter passing convention
** (parameters are pushed onto the stack in reverse order as
** 32-bit values).
*/
void sprint( char *dst, char *fmt, ... ) {
   126e2:	55                   	push   %ebp
   126e3:	89 e5                	mov    %esp,%ebp
   126e5:	83 ec 38             	sub    $0x38,%esp
	** to point to the next "thing", and interpret it according
	** to the format string.
	*/
	
	// get the pointer to the first "value" parameter
	ap = (int *)(&fmt) + 1;
   126e8:	8d 45 0c             	lea    0xc(%ebp),%eax
   126eb:	83 c0 04             	add    $0x4,%eax
   126ee:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// iterate through the format string
	while( (ch = *fmt++) != '\0' ){
   126f1:	e9 3f 02 00 00       	jmp    12935 <sprint+0x253>
		/*
		** Is it the start of a format code?
		*/
		if( ch == '%' ){
   126f6:	80 7d f3 25          	cmpb   $0x25,-0xd(%ebp)
   126fa:	0f 85 26 02 00 00    	jne    12926 <sprint+0x244>
			/*
			** Yes, get the padding and width options (if there).
			** Alignment must come at the beginning, then fill,
			** then width.
			*/
			leftadjust = 0;
   12700:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
			padchar = ' ';
   12707:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
			width = 0;
   1270e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
			ch = *fmt++;
   12715:	8b 45 0c             	mov    0xc(%ebp),%eax
   12718:	8d 50 01             	lea    0x1(%eax),%edx
   1271b:	89 55 0c             	mov    %edx,0xc(%ebp)
   1271e:	0f b6 00             	movzbl (%eax),%eax
   12721:	88 45 f3             	mov    %al,-0xd(%ebp)
			if( ch == '-' ){
   12724:	80 7d f3 2d          	cmpb   $0x2d,-0xd(%ebp)
   12728:	75 16                	jne    12740 <sprint+0x5e>
				leftadjust = 1;
   1272a:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
				ch = *fmt++;
   12731:	8b 45 0c             	mov    0xc(%ebp),%eax
   12734:	8d 50 01             	lea    0x1(%eax),%edx
   12737:	89 55 0c             	mov    %edx,0xc(%ebp)
   1273a:	0f b6 00             	movzbl (%eax),%eax
   1273d:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			if( ch == '0' ){
   12740:	80 7d f3 30          	cmpb   $0x30,-0xd(%ebp)
   12744:	75 40                	jne    12786 <sprint+0xa4>
				padchar = '0';
   12746:	c7 45 e4 30 00 00 00 	movl   $0x30,-0x1c(%ebp)
				ch = *fmt++;
   1274d:	8b 45 0c             	mov    0xc(%ebp),%eax
   12750:	8d 50 01             	lea    0x1(%eax),%edx
   12753:	89 55 0c             	mov    %edx,0xc(%ebp)
   12756:	0f b6 00             	movzbl (%eax),%eax
   12759:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			while( ch >= '0' && ch <= '9' ){
   1275c:	eb 28                	jmp    12786 <sprint+0xa4>
				width *= 10;
   1275e:	8b 55 e8             	mov    -0x18(%ebp),%edx
   12761:	89 d0                	mov    %edx,%eax
   12763:	c1 e0 02             	shl    $0x2,%eax
   12766:	01 d0                	add    %edx,%eax
   12768:	01 c0                	add    %eax,%eax
   1276a:	89 45 e8             	mov    %eax,-0x18(%ebp)
				width += ch - '0';
   1276d:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   12771:	83 e8 30             	sub    $0x30,%eax
   12774:	01 45 e8             	add    %eax,-0x18(%ebp)
				ch = *fmt++;
   12777:	8b 45 0c             	mov    0xc(%ebp),%eax
   1277a:	8d 50 01             	lea    0x1(%eax),%edx
   1277d:	89 55 0c             	mov    %edx,0xc(%ebp)
   12780:	0f b6 00             	movzbl (%eax),%eax
   12783:	88 45 f3             	mov    %al,-0xd(%ebp)
			while( ch >= '0' && ch <= '9' ){
   12786:	80 7d f3 2f          	cmpb   $0x2f,-0xd(%ebp)
   1278a:	7e 06                	jle    12792 <sprint+0xb0>
   1278c:	80 7d f3 39          	cmpb   $0x39,-0xd(%ebp)
   12790:	7e cc                	jle    1275e <sprint+0x7c>
			}

			/*
			** What data type do we have?
			*/
			switch( ch ) {
   12792:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   12796:	83 e8 63             	sub    $0x63,%eax
   12799:	83 f8 15             	cmp    $0x15,%eax
   1279c:	0f 87 93 01 00 00    	ja     12935 <sprint+0x253>
   127a2:	8b 04 85 b8 ac 01 00 	mov    0x1acb8(,%eax,4),%eax
   127a9:	ff e0                	jmp    *%eax

			case 'c':  // characters are passed as 32-bit values
				ch = *ap++;
   127ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
   127ae:	8d 50 04             	lea    0x4(%eax),%edx
   127b1:	89 55 f4             	mov    %edx,-0xc(%ebp)
   127b4:	8b 00                	mov    (%eax),%eax
   127b6:	88 45 f3             	mov    %al,-0xd(%ebp)
				buf[ 0 ] = ch;
   127b9:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   127bd:	88 45 d0             	mov    %al,-0x30(%ebp)
				buf[ 1 ] = '\0';
   127c0:	c6 45 d1 00          	movb   $0x0,-0x2f(%ebp)
				dst = padstr( dst, buf, 1, width, leftadjust, padchar );
   127c4:	83 ec 08             	sub    $0x8,%esp
   127c7:	ff 75 e4             	pushl  -0x1c(%ebp)
   127ca:	ff 75 ec             	pushl  -0x14(%ebp)
   127cd:	ff 75 e8             	pushl  -0x18(%ebp)
   127d0:	6a 01                	push   $0x1
   127d2:	8d 45 d0             	lea    -0x30(%ebp),%eax
   127d5:	50                   	push   %eax
   127d6:	ff 75 08             	pushl  0x8(%ebp)
   127d9:	e8 67 fe ff ff       	call   12645 <padstr>
   127de:	83 c4 20             	add    $0x20,%esp
   127e1:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   127e4:	e9 4c 01 00 00       	jmp    12935 <sprint+0x253>

			case 'd':
				len = cvtdec( buf, *ap++ );
   127e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
   127ec:	8d 50 04             	lea    0x4(%eax),%edx
   127ef:	89 55 f4             	mov    %edx,-0xc(%ebp)
   127f2:	8b 00                	mov    (%eax),%eax
   127f4:	83 ec 08             	sub    $0x8,%esp
   127f7:	50                   	push   %eax
   127f8:	8d 45 d0             	lea    -0x30(%ebp),%eax
   127fb:	50                   	push   %eax
   127fc:	e8 ee f8 ff ff       	call   120ef <cvtdec>
   12801:	83 c4 10             	add    $0x10,%esp
   12804:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   12807:	83 ec 08             	sub    $0x8,%esp
   1280a:	ff 75 e4             	pushl  -0x1c(%ebp)
   1280d:	ff 75 ec             	pushl  -0x14(%ebp)
   12810:	ff 75 e8             	pushl  -0x18(%ebp)
   12813:	ff 75 e0             	pushl  -0x20(%ebp)
   12816:	8d 45 d0             	lea    -0x30(%ebp),%eax
   12819:	50                   	push   %eax
   1281a:	ff 75 08             	pushl  0x8(%ebp)
   1281d:	e8 23 fe ff ff       	call   12645 <padstr>
   12822:	83 c4 20             	add    $0x20,%esp
   12825:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   12828:	e9 08 01 00 00       	jmp    12935 <sprint+0x253>

			case 's':
				str = (char *) (*ap++);
   1282d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12830:	8d 50 04             	lea    0x4(%eax),%edx
   12833:	89 55 f4             	mov    %edx,-0xc(%ebp)
   12836:	8b 00                	mov    (%eax),%eax
   12838:	89 45 dc             	mov    %eax,-0x24(%ebp)
				dst = padstr( dst, str, -1, width, leftadjust, padchar );
   1283b:	83 ec 08             	sub    $0x8,%esp
   1283e:	ff 75 e4             	pushl  -0x1c(%ebp)
   12841:	ff 75 ec             	pushl  -0x14(%ebp)
   12844:	ff 75 e8             	pushl  -0x18(%ebp)
   12847:	6a ff                	push   $0xffffffff
   12849:	ff 75 dc             	pushl  -0x24(%ebp)
   1284c:	ff 75 08             	pushl  0x8(%ebp)
   1284f:	e8 f1 fd ff ff       	call   12645 <padstr>
   12854:	83 c4 20             	add    $0x20,%esp
   12857:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   1285a:	e9 d6 00 00 00       	jmp    12935 <sprint+0x253>

			case 'x':
				len = cvthex( buf, *ap++ );
   1285f:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12862:	8d 50 04             	lea    0x4(%eax),%edx
   12865:	89 55 f4             	mov    %edx,-0xc(%ebp)
   12868:	8b 00                	mov    (%eax),%eax
   1286a:	83 ec 08             	sub    $0x8,%esp
   1286d:	50                   	push   %eax
   1286e:	8d 45 d0             	lea    -0x30(%ebp),%eax
   12871:	50                   	push   %eax
   12872:	e8 48 f9 ff ff       	call   121bf <cvthex>
   12877:	83 c4 10             	add    $0x10,%esp
   1287a:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   1287d:	83 ec 08             	sub    $0x8,%esp
   12880:	ff 75 e4             	pushl  -0x1c(%ebp)
   12883:	ff 75 ec             	pushl  -0x14(%ebp)
   12886:	ff 75 e8             	pushl  -0x18(%ebp)
   12889:	ff 75 e0             	pushl  -0x20(%ebp)
   1288c:	8d 45 d0             	lea    -0x30(%ebp),%eax
   1288f:	50                   	push   %eax
   12890:	ff 75 08             	pushl  0x8(%ebp)
   12893:	e8 ad fd ff ff       	call   12645 <padstr>
   12898:	83 c4 20             	add    $0x20,%esp
   1289b:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   1289e:	e9 92 00 00 00       	jmp    12935 <sprint+0x253>

			case 'o':
				len = cvtoct( buf, *ap++ );
   128a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
   128a6:	8d 50 04             	lea    0x4(%eax),%edx
   128a9:	89 55 f4             	mov    %edx,-0xc(%ebp)
   128ac:	8b 00                	mov    (%eax),%eax
   128ae:	83 ec 08             	sub    $0x8,%esp
   128b1:	50                   	push   %eax
   128b2:	8d 45 d0             	lea    -0x30(%ebp),%eax
   128b5:	50                   	push   %eax
   128b6:	e8 8e f9 ff ff       	call   12249 <cvtoct>
   128bb:	83 c4 10             	add    $0x10,%esp
   128be:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   128c1:	83 ec 08             	sub    $0x8,%esp
   128c4:	ff 75 e4             	pushl  -0x1c(%ebp)
   128c7:	ff 75 ec             	pushl  -0x14(%ebp)
   128ca:	ff 75 e8             	pushl  -0x18(%ebp)
   128cd:	ff 75 e0             	pushl  -0x20(%ebp)
   128d0:	8d 45 d0             	lea    -0x30(%ebp),%eax
   128d3:	50                   	push   %eax
   128d4:	ff 75 08             	pushl  0x8(%ebp)
   128d7:	e8 69 fd ff ff       	call   12645 <padstr>
   128dc:	83 c4 20             	add    $0x20,%esp
   128df:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   128e2:	eb 51                	jmp    12935 <sprint+0x253>

			case 'u':
				len = cvtuns( buf, *ap++ );
   128e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   128e7:	8d 50 04             	lea    0x4(%eax),%edx
   128ea:	89 55 f4             	mov    %edx,-0xc(%ebp)
   128ed:	8b 00                	mov    (%eax),%eax
   128ef:	83 ec 08             	sub    $0x8,%esp
   128f2:	50                   	push   %eax
   128f3:	8d 45 d0             	lea    -0x30(%ebp),%eax
   128f6:	50                   	push   %eax
   128f7:	e8 d7 f9 ff ff       	call   122d3 <cvtuns>
   128fc:	83 c4 10             	add    $0x10,%esp
   128ff:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = padstr( dst, buf, len, width, leftadjust, padchar );
   12902:	83 ec 08             	sub    $0x8,%esp
   12905:	ff 75 e4             	pushl  -0x1c(%ebp)
   12908:	ff 75 ec             	pushl  -0x14(%ebp)
   1290b:	ff 75 e8             	pushl  -0x18(%ebp)
   1290e:	ff 75 e0             	pushl  -0x20(%ebp)
   12911:	8d 45 d0             	lea    -0x30(%ebp),%eax
   12914:	50                   	push   %eax
   12915:	ff 75 08             	pushl  0x8(%ebp)
   12918:	e8 28 fd ff ff       	call   12645 <padstr>
   1291d:	83 c4 20             	add    $0x20,%esp
   12920:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   12923:	90                   	nop
   12924:	eb 0f                	jmp    12935 <sprint+0x253>

			}
		} else {
			// no, it's just an ordinary character
			*dst++ = ch;
   12926:	8b 45 08             	mov    0x8(%ebp),%eax
   12929:	8d 50 01             	lea    0x1(%eax),%edx
   1292c:	89 55 08             	mov    %edx,0x8(%ebp)
   1292f:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
   12933:	88 10                	mov    %dl,(%eax)
	while( (ch = *fmt++) != '\0' ){
   12935:	8b 45 0c             	mov    0xc(%ebp),%eax
   12938:	8d 50 01             	lea    0x1(%eax),%edx
   1293b:	89 55 0c             	mov    %edx,0xc(%ebp)
   1293e:	0f b6 00             	movzbl (%eax),%eax
   12941:	88 45 f3             	mov    %al,-0xd(%ebp)
   12944:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   12948:	0f 85 a8 fd ff ff    	jne    126f6 <sprint+0x14>
		}
	}

	// NUL-terminate the result
	*dst = '\0';
   1294e:	8b 45 08             	mov    0x8(%ebp),%eax
   12951:	c6 00 00             	movb   $0x0,(%eax)
}
   12954:	90                   	nop
   12955:	c9                   	leave  
   12956:	c3                   	ret    

00012957 <str2int>:
** @param str   The string to examine
** @param base  The radix to use in the conversion
**
** @return The converted integer
*/
int str2int( register const char *str, register int base ) {
   12957:	55                   	push   %ebp
   12958:	89 e5                	mov    %esp,%ebp
   1295a:	53                   	push   %ebx
   1295b:	83 ec 14             	sub    $0x14,%esp
   1295e:	8b 45 08             	mov    0x8(%ebp),%eax
   12961:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register int num = 0;
   12964:	bb 00 00 00 00       	mov    $0x0,%ebx
	register char bchar = '9';
   12969:	c6 45 eb 39          	movb   $0x39,-0x15(%ebp)
	int sign = 1;
   1296d:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)

	// check for leading '-'
	if( *str == '-' ) {
   12974:	0f b6 10             	movzbl (%eax),%edx
   12977:	80 fa 2d             	cmp    $0x2d,%dl
   1297a:	75 0a                	jne    12986 <str2int+0x2f>
		sign = -1;
   1297c:	c7 45 f8 ff ff ff ff 	movl   $0xffffffff,-0x8(%ebp)
		++str;
   12983:	83 c0 01             	add    $0x1,%eax
	}

	if( base != 10 ) {
   12986:	83 f9 0a             	cmp    $0xa,%ecx
   12989:	74 2b                	je     129b6 <str2int+0x5f>
		bchar = '0' + base - 1;
   1298b:	89 ca                	mov    %ecx,%edx
   1298d:	83 c2 2f             	add    $0x2f,%edx
   12990:	88 55 eb             	mov    %dl,-0x15(%ebp)
	}

	// iterate through the characters
	while( *str ) {
   12993:	eb 21                	jmp    129b6 <str2int+0x5f>
		if( *str < '0' || *str > bchar )
   12995:	0f b6 10             	movzbl (%eax),%edx
   12998:	80 fa 2f             	cmp    $0x2f,%dl
   1299b:	7e 20                	jle    129bd <str2int+0x66>
   1299d:	0f b6 10             	movzbl (%eax),%edx
   129a0:	38 55 eb             	cmp    %dl,-0x15(%ebp)
   129a3:	7c 18                	jl     129bd <str2int+0x66>
			break;
		num = num * base + *str - '0';
   129a5:	0f af d9             	imul   %ecx,%ebx
   129a8:	0f b6 10             	movzbl (%eax),%edx
   129ab:	0f be d2             	movsbl %dl,%edx
   129ae:	01 da                	add    %ebx,%edx
   129b0:	8d 5a d0             	lea    -0x30(%edx),%ebx
		++str;
   129b3:	83 c0 01             	add    $0x1,%eax
	while( *str ) {
   129b6:	0f b6 10             	movzbl (%eax),%edx
   129b9:	84 d2                	test   %dl,%dl
   129bb:	75 d8                	jne    12995 <str2int+0x3e>
	}

	// return the converted value
	return( num * sign );
   129bd:	89 d8                	mov    %ebx,%eax
   129bf:	0f af 45 f8          	imul   -0x8(%ebp),%eax
}
   129c3:	83 c4 14             	add    $0x14,%esp
   129c6:	5b                   	pop    %ebx
   129c7:	5d                   	pop    %ebp
   129c8:	c3                   	ret    

000129c9 <strcat>:
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the resulting string
*/
char *strcat( register char *dst, register const char *src ) {
   129c9:	55                   	push   %ebp
   129ca:	89 e5                	mov    %esp,%ebp
   129cc:	56                   	push   %esi
   129cd:	53                   	push   %ebx
   129ce:	8b 45 08             	mov    0x8(%ebp),%eax
   129d1:	8b 75 0c             	mov    0xc(%ebp),%esi
	register char *tmp = dst;
   129d4:	89 c3                	mov    %eax,%ebx

	while( *dst )  // find the NUL
   129d6:	eb 03                	jmp    129db <strcat+0x12>
		++dst;
   129d8:	83 c0 01             	add    $0x1,%eax
	while( *dst )  // find the NUL
   129db:	0f b6 10             	movzbl (%eax),%edx
   129de:	84 d2                	test   %dl,%dl
   129e0:	75 f6                	jne    129d8 <strcat+0xf>

	while( (*dst++ = *src++) )  // append the src string
   129e2:	90                   	nop
   129e3:	89 f1                	mov    %esi,%ecx
   129e5:	8d 71 01             	lea    0x1(%ecx),%esi
   129e8:	89 c2                	mov    %eax,%edx
   129ea:	8d 42 01             	lea    0x1(%edx),%eax
   129ed:	0f b6 09             	movzbl (%ecx),%ecx
   129f0:	88 0a                	mov    %cl,(%edx)
   129f2:	0f b6 12             	movzbl (%edx),%edx
   129f5:	84 d2                	test   %dl,%dl
   129f7:	75 ea                	jne    129e3 <strcat+0x1a>
		;

	return( tmp );
   129f9:	89 d8                	mov    %ebx,%eax
}
   129fb:	5b                   	pop    %ebx
   129fc:	5e                   	pop    %esi
   129fd:	5d                   	pop    %ebp
   129fe:	c3                   	ret    

000129ff <strcmp>:
** @param s1 The first source string
** @param s2 The second source string
**
** @return negative if s1 < s2, zero if equal, and positive if s1 > s2
*/
int strcmp( register const char *s1, register const char *s2 ) {
   129ff:	55                   	push   %ebp
   12a00:	89 e5                	mov    %esp,%ebp
   12a02:	53                   	push   %ebx
   12a03:	8b 45 08             	mov    0x8(%ebp),%eax
   12a06:	8b 55 0c             	mov    0xc(%ebp),%edx

	while( *s1 != 0 && (*s1 == *s2) )
   12a09:	eb 06                	jmp    12a11 <strcmp+0x12>
		++s1, ++s2;
   12a0b:	83 c0 01             	add    $0x1,%eax
   12a0e:	83 c2 01             	add    $0x1,%edx
	while( *s1 != 0 && (*s1 == *s2) )
   12a11:	0f b6 08             	movzbl (%eax),%ecx
   12a14:	84 c9                	test   %cl,%cl
   12a16:	74 0a                	je     12a22 <strcmp+0x23>
   12a18:	0f b6 18             	movzbl (%eax),%ebx
   12a1b:	0f b6 0a             	movzbl (%edx),%ecx
   12a1e:	38 cb                	cmp    %cl,%bl
   12a20:	74 e9                	je     12a0b <strcmp+0xc>

	return( *s1 - *s2 );
   12a22:	0f b6 00             	movzbl (%eax),%eax
   12a25:	0f be c8             	movsbl %al,%ecx
   12a28:	0f b6 02             	movzbl (%edx),%eax
   12a2b:	0f be c0             	movsbl %al,%eax
   12a2e:	29 c1                	sub    %eax,%ecx
   12a30:	89 c8                	mov    %ecx,%eax
}
   12a32:	5b                   	pop    %ebx
   12a33:	5d                   	pop    %ebp
   12a34:	c3                   	ret    

00012a35 <strcpy>:
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the copied string
*/
char *strcpy( register char *dst, register const char *src ) {
   12a35:	55                   	push   %ebp
   12a36:	89 e5                	mov    %esp,%ebp
   12a38:	56                   	push   %esi
   12a39:	53                   	push   %ebx
   12a3a:	8b 4d 08             	mov    0x8(%ebp),%ecx
   12a3d:	8b 75 0c             	mov    0xc(%ebp),%esi
	register char *tmp = dst;
   12a40:	89 cb                	mov    %ecx,%ebx

	while( (*dst++ = *src++) )
   12a42:	90                   	nop
   12a43:	89 f2                	mov    %esi,%edx
   12a45:	8d 72 01             	lea    0x1(%edx),%esi
   12a48:	89 c8                	mov    %ecx,%eax
   12a4a:	8d 48 01             	lea    0x1(%eax),%ecx
   12a4d:	0f b6 12             	movzbl (%edx),%edx
   12a50:	88 10                	mov    %dl,(%eax)
   12a52:	0f b6 00             	movzbl (%eax),%eax
   12a55:	84 c0                	test   %al,%al
   12a57:	75 ea                	jne    12a43 <strcpy+0xe>
		;

	return( tmp );
   12a59:	89 d8                	mov    %ebx,%eax
}
   12a5b:	5b                   	pop    %ebx
   12a5c:	5e                   	pop    %esi
   12a5d:	5d                   	pop    %ebp
   12a5e:	c3                   	ret    

00012a5f <strlen>:
**
** @param str The string to examine
**
** @return The length of the string, or 0
*/
uint32_t strlen( register const char *str ) {
   12a5f:	55                   	push   %ebp
   12a60:	89 e5                	mov    %esp,%ebp
   12a62:	53                   	push   %ebx
   12a63:	8b 55 08             	mov    0x8(%ebp),%edx
	register uint32_t len = 0;
   12a66:	bb 00 00 00 00       	mov    $0x0,%ebx

	while( *str++ ) {
   12a6b:	eb 03                	jmp    12a70 <strlen+0x11>
		++len;
   12a6d:	83 c3 01             	add    $0x1,%ebx
	while( *str++ ) {
   12a70:	89 d0                	mov    %edx,%eax
   12a72:	8d 50 01             	lea    0x1(%eax),%edx
   12a75:	0f b6 00             	movzbl (%eax),%eax
   12a78:	84 c0                	test   %al,%al
   12a7a:	75 f1                	jne    12a6d <strlen+0xe>
	}

	return( len );
   12a7c:	89 d8                	mov    %ebx,%eax
}
   12a7e:	5b                   	pop    %ebx
   12a7f:	5d                   	pop    %ebp
   12a80:	c3                   	ret    

00012a81 <add_block>:
** Add a block to the free list
**
** @param base   Base address of the block
** @param length Block length, in bytes
*/
static void add_block( uint32_t base, uint32_t length ) {
   12a81:	55                   	push   %ebp
   12a82:	89 e5                	mov    %esp,%ebp
   12a84:	83 ec 18             	sub    $0x18,%esp

	// don't add it if it isn't at least 4K
	if( length < SZ_PAGE ) {
   12a87:	81 7d 0c ff 0f 00 00 	cmpl   $0xfff,0xc(%ebp)
   12a8e:	0f 86 f4 00 00 00    	jbe    12b88 <add_block+0x107>
#if ANY_KMEM
	cio_printf( "  add(%08x,%08x): ", base, length );
#endif

	// only want to add multiples of 4K; check the lower bits
	if( (length & 0xfff) != 0 ) {
   12a94:	8b 45 0c             	mov    0xc(%ebp),%eax
   12a97:	25 ff 0f 00 00       	and    $0xfff,%eax
   12a9c:	85 c0                	test   %eax,%eax
   12a9e:	74 07                	je     12aa7 <add_block+0x26>
		// round it down to 4K
		length &= 0xfffff000;
   12aa0:	81 65 0c 00 f0 ff ff 	andl   $0xfffff000,0xc(%ebp)
	cio_printf( " --> base %08x length %08x", base, length );
#endif

	// create the "block"

	Blockinfo *block = (Blockinfo *) base;
   12aa7:	8b 45 08             	mov    0x8(%ebp),%eax
   12aaa:	89 45 ec             	mov    %eax,-0x14(%ebp)
	block->pages = B2P(length);
   12aad:	8b 45 0c             	mov    0xc(%ebp),%eax
   12ab0:	c1 e8 0c             	shr    $0xc,%eax
   12ab3:	89 c2                	mov    %eax,%edx
   12ab5:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12ab8:	89 10                	mov    %edx,(%eax)
	block->next = NULL;
   12aba:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12abd:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	** coalescing adjacent free blocks.
	**
	** Handle the easiest case first.
	*/

	if( free_pages == NULL ) {
   12ac4:	a1 14 d1 01 00       	mov    0x1d114,%eax
   12ac9:	85 c0                	test   %eax,%eax
   12acb:	75 17                	jne    12ae4 <add_block+0x63>
		free_pages = block;
   12acd:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12ad0:	a3 14 d1 01 00       	mov    %eax,0x1d114
		n_pages = block->pages;
   12ad5:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12ad8:	8b 00                	mov    (%eax),%eax
   12ada:	a3 1c d1 01 00       	mov    %eax,0x1d11c
		return;
   12adf:	e9 a5 00 00 00       	jmp    12b89 <add_block+0x108>
	** Find the correct insertion spot.
	*/

	Blockinfo *prev, *curr;

	prev = NULL;
   12ae4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	curr = free_pages;
   12aeb:	a1 14 d1 01 00       	mov    0x1d114,%eax
   12af0:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr && curr < block ) {
   12af3:	eb 0f                	jmp    12b04 <add_block+0x83>
		prev = curr;
   12af5:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12af8:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   12afb:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12afe:	8b 40 04             	mov    0x4(%eax),%eax
   12b01:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr && curr < block ) {
   12b04:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12b08:	74 08                	je     12b12 <add_block+0x91>
   12b0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12b0d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   12b10:	72 e3                	jb     12af5 <add_block+0x74>
	}

	// the new block always points to its successor
	block->next = curr;
   12b12:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12b15:	8b 55 f0             	mov    -0x10(%ebp),%edx
   12b18:	89 50 04             	mov    %edx,0x4(%eax)
	/*
	** If prev is NULL, we're adding at the front; otherwise,
	** we're adding after some other entry (middle or end).
	*/

	if( prev == NULL ) {
   12b1b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12b1f:	75 4b                	jne    12b6c <add_block+0xeb>
		// sanity check - both pointers can't be NULL
		assert( curr );
   12b21:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12b25:	75 3b                	jne    12b62 <add_block+0xe1>
   12b27:	83 ec 04             	sub    $0x4,%esp
   12b2a:	68 10 ad 01 00       	push   $0x1ad10
   12b2f:	6a 00                	push   $0x0
   12b31:	68 0d 01 00 00       	push   $0x10d
   12b36:	68 15 ad 01 00       	push   $0x1ad15
   12b3b:	68 0c ae 01 00       	push   $0x1ae0c
   12b40:	68 1c ad 01 00       	push   $0x1ad1c
   12b45:	68 00 f0 01 00       	push   $0x1f000
   12b4a:	e8 93 fb ff ff       	call   126e2 <sprint>
   12b4f:	83 c4 20             	add    $0x20,%esp
   12b52:	83 ec 0c             	sub    $0xc,%esp
   12b55:	68 00 f0 01 00       	push   $0x1f000
   12b5a:	e8 03 f9 ff ff       	call   12462 <kpanic>
   12b5f:	83 c4 10             	add    $0x10,%esp
		// add at the beginning
		free_pages = block;
   12b62:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12b65:	a3 14 d1 01 00       	mov    %eax,0x1d114
   12b6a:	eb 09                	jmp    12b75 <add_block+0xf4>
	} else {
		// inserting in the middle or at the end
		prev->next = block;
   12b6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12b6f:	8b 55 ec             	mov    -0x14(%ebp),%edx
   12b72:	89 50 04             	mov    %edx,0x4(%eax)
	}

	// bump the count of available pages
	n_pages += block->pages;
   12b75:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12b78:	8b 10                	mov    (%eax),%edx
   12b7a:	a1 1c d1 01 00       	mov    0x1d11c,%eax
   12b7f:	01 d0                	add    %edx,%eax
   12b81:	a3 1c d1 01 00       	mov    %eax,0x1d11c
   12b86:	eb 01                	jmp    12b89 <add_block+0x108>
		return;
   12b88:	90                   	nop
}
   12b89:	c9                   	leave  
   12b8a:	c3                   	ret    

00012b8b <km_init>:
**
** Dependencies:
**    Must be called before any other init routine that uses
**    dynamic storage is called.
*/
void km_init( void ) {
   12b8b:	55                   	push   %ebp
   12b8c:	89 e5                	mov    %esp,%ebp
   12b8e:	53                   	push   %ebx
   12b8f:	83 ec 34             	sub    $0x34,%esp
	int32_t entries;
	region_t *region;

#if TRACING_INIT
	// announce that we're starting initialization
	cio_puts( " Kmem" );
   12b92:	83 ec 0c             	sub    $0xc,%esp
   12b95:	68 32 ad 01 00       	push   $0x1ad32
   12b9a:	e8 0e e3 ff ff       	call   10ead <cio_puts>
   12b9f:	83 c4 10             	add    $0x10,%esp
#endif

	// initially, nothing in the free lists
	free_slices = NULL;
   12ba2:	c7 05 18 d1 01 00 00 	movl   $0x0,0x1d118
   12ba9:	00 00 00 
	free_pages = NULL;
   12bac:	c7 05 14 d1 01 00 00 	movl   $0x0,0x1d114
   12bb3:	00 00 00 
	n_pages = n_slices = 0;
   12bb6:	c7 05 20 d1 01 00 00 	movl   $0x0,0x1d120
   12bbd:	00 00 00 
   12bc0:	a1 20 d1 01 00       	mov    0x1d120,%eax
   12bc5:	a3 1c d1 01 00       	mov    %eax,0x1d11c
	km_initialized = 0;
   12bca:	c7 05 24 d1 01 00 00 	movl   $0x0,0x1d124
   12bd1:	00 00 00 

	// get the list length
	entries = *((int32_t *) MMAP_ADDR);
   12bd4:	b8 00 2d 00 00       	mov    $0x2d00,%eax
   12bd9:	8b 00                	mov    (%eax),%eax
   12bdb:	89 45 dc             	mov    %eax,-0x24(%ebp)
#if KMEM_OR_INIT
	cio_printf( "\nKmem: %d regions\n", entries );
#endif

	// if there are no entries, we have nothing to do!
	if( entries < 1 ) {  // note: entries == -1 could occur!
   12bde:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   12be2:	0f 8e 77 01 00 00    	jle    12d5f <km_init+0x1d4>
		return;
	}

	// iterate through the entries, adding things to the freelist

	region = ((region_t *) (MMAP_ADDR + 4));
   12be8:	c7 45 f4 04 2d 00 00 	movl   $0x2d04,-0xc(%ebp)

	for( int i = 0; i < entries; ++i, ++region ) {
   12bef:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   12bf6:	e9 4c 01 00 00       	jmp    12d47 <km_init+0x1bc>
		** this to include ACPI "reclaimable" memory.
		*/

		// first, check the ACPI one-bit flags

		if( ((region->acpi) & REGION_IGNORE) == 0 ) {
   12bfb:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12bfe:	8b 40 14             	mov    0x14(%eax),%eax
   12c01:	83 e0 01             	and    $0x1,%eax
   12c04:	85 c0                	test   %eax,%eax
   12c06:	0f 84 26 01 00 00    	je     12d32 <km_init+0x1a7>
			cio_puts( " IGN\n" );
#endif
			continue;
		}

		if( ((region->acpi) & REGION_NONVOL) != 0 ) {
   12c0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c0f:	8b 40 14             	mov    0x14(%eax),%eax
   12c12:	83 e0 02             	and    $0x2,%eax
   12c15:	85 c0                	test   %eax,%eax
   12c17:	0f 85 18 01 00 00    	jne    12d35 <km_init+0x1aa>
			continue;  // we'll ignore this, too
		}

		// next, the region type

		if( (region->type) != REGION_USABLE ) {
   12c1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c20:	8b 40 10             	mov    0x10(%eax),%eax
   12c23:	83 f8 01             	cmp    $0x1,%eax
   12c26:	0f 85 0c 01 00 00    	jne    12d38 <km_init+0x1ad>
		** split it, and only use the portion that's within those
		** bounds.
		*/

		// grab the two 64-bit values to simplify things
		uint64_t base   = region->base.all;
   12c2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c2f:	8b 50 04             	mov    0x4(%eax),%edx
   12c32:	8b 00                	mov    (%eax),%eax
   12c34:	89 45 e8             	mov    %eax,-0x18(%ebp)
   12c37:	89 55 ec             	mov    %edx,-0x14(%ebp)
		uint64_t length = region->length.all;
   12c3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12c3d:	8b 50 0c             	mov    0xc(%eax),%edx
   12c40:	8b 40 08             	mov    0x8(%eax),%eax
   12c43:	89 45 d0             	mov    %eax,-0x30(%ebp)
   12c46:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		uint64_t endpt  = base + length;
   12c49:	8b 4d e8             	mov    -0x18(%ebp),%ecx
   12c4c:	8b 5d ec             	mov    -0x14(%ebp),%ebx
   12c4f:	8b 45 d0             	mov    -0x30(%ebp),%eax
   12c52:	8b 55 d4             	mov    -0x2c(%ebp),%edx
   12c55:	01 c8                	add    %ecx,%eax
   12c57:	11 da                	adc    %ebx,%edx
   12c59:	89 45 e0             	mov    %eax,-0x20(%ebp)
   12c5c:	89 55 e4             	mov    %edx,-0x1c(%ebp)

		// see if it's above our arbitrary high cutoff point
		if( base >= KM_HIGH_CUTOFF || endpt >= KM_HIGH_CUTOFF ) {
   12c5f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12c63:	77 24                	ja     12c89 <km_init+0xfe>
   12c65:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12c69:	72 09                	jb     12c74 <km_init+0xe9>
   12c6b:	81 7d e8 ff ff ff 3f 	cmpl   $0x3fffffff,-0x18(%ebp)
   12c72:	77 15                	ja     12c89 <km_init+0xfe>
   12c74:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12c78:	72 3a                	jb     12cb4 <km_init+0x129>
   12c7a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12c7e:	77 09                	ja     12c89 <km_init+0xfe>
   12c80:	81 7d e0 ff ff ff 3f 	cmpl   $0x3fffffff,-0x20(%ebp)
   12c87:	76 2b                	jbe    12cb4 <km_init+0x129>

			// is the whole thing too high, or just part?
			if( base > KM_HIGH_CUTOFF ) {
   12c89:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12c8d:	72 17                	jb     12ca6 <km_init+0x11b>
   12c8f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12c93:	0f 87 a2 00 00 00    	ja     12d3b <km_init+0x1b0>
   12c99:	81 7d e8 00 00 00 40 	cmpl   $0x40000000,-0x18(%ebp)
   12ca0:	0f 87 95 00 00 00    	ja     12d3b <km_init+0x1b0>
#endif
				continue;
			}

			// some of it is usable - fix the end point
			endpt = KM_HIGH_CUTOFF;
   12ca6:	c7 45 e0 00 00 00 40 	movl   $0x40000000,-0x20(%ebp)
   12cad:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		}

		// see if it's below our low cutoff point
		if( base < KM_LOW_CUTOFF || endpt < KM_LOW_CUTOFF ) {
   12cb4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12cb8:	72 24                	jb     12cde <km_init+0x153>
   12cba:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12cbe:	77 09                	ja     12cc9 <km_init+0x13e>
   12cc0:	81 7d e8 ff ff 0f 00 	cmpl   $0xfffff,-0x18(%ebp)
   12cc7:	76 15                	jbe    12cde <km_init+0x153>
   12cc9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12ccd:	77 32                	ja     12d01 <km_init+0x176>
   12ccf:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12cd3:	72 09                	jb     12cde <km_init+0x153>
   12cd5:	81 7d e0 ff ff 0f 00 	cmpl   $0xfffff,-0x20(%ebp)
   12cdc:	77 23                	ja     12d01 <km_init+0x176>

			// is the whole thing too low, or just part?
			if( endpt < KM_LOW_CUTOFF ) {
   12cde:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12ce2:	77 0f                	ja     12cf3 <km_init+0x168>
   12ce4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   12ce8:	72 54                	jb     12d3e <km_init+0x1b3>
   12cea:	81 7d e0 ff ff 0f 00 	cmpl   $0xfffff,-0x20(%ebp)
   12cf1:	76 4b                	jbe    12d3e <km_init+0x1b3>
#endif
				continue;
			}

			// some of it is usable - fix the starting point
			base = KM_LOW_CUTOFF;
   12cf3:	c7 45 e8 00 00 10 00 	movl   $0x100000,-0x18(%ebp)
   12cfa:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
		}

		// recalculate the length
		length = endpt - base;
   12d01:	8b 45 e0             	mov    -0x20(%ebp),%eax
   12d04:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   12d07:	2b 45 e8             	sub    -0x18(%ebp),%eax
   12d0a:	1b 55 ec             	sbb    -0x14(%ebp),%edx
   12d0d:	89 45 d0             	mov    %eax,-0x30(%ebp)
   12d10:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		cio_puts( " OK\n" );
#endif

		// we survived the gauntlet - add the new block

		uint32_t b32 = base   & ADDR_LOW_HALF;
   12d13:	8b 45 e8             	mov    -0x18(%ebp),%eax
   12d16:	89 45 cc             	mov    %eax,-0x34(%ebp)
		uint32_t l32 = length & ADDR_LOW_HALF;
   12d19:	8b 45 d0             	mov    -0x30(%ebp),%eax
   12d1c:	89 45 c8             	mov    %eax,-0x38(%ebp)

		add_block( b32, l32 );
   12d1f:	83 ec 08             	sub    $0x8,%esp
   12d22:	ff 75 c8             	pushl  -0x38(%ebp)
   12d25:	ff 75 cc             	pushl  -0x34(%ebp)
   12d28:	e8 54 fd ff ff       	call   12a81 <add_block>
   12d2d:	83 c4 10             	add    $0x10,%esp
   12d30:	eb 0d                	jmp    12d3f <km_init+0x1b4>
			continue;
   12d32:	90                   	nop
   12d33:	eb 0a                	jmp    12d3f <km_init+0x1b4>
			continue;  // we'll ignore this, too
   12d35:	90                   	nop
   12d36:	eb 07                	jmp    12d3f <km_init+0x1b4>
			continue;  // we won't attempt to reclaim ACPI memory (yet)
   12d38:	90                   	nop
   12d39:	eb 04                	jmp    12d3f <km_init+0x1b4>
				continue;
   12d3b:	90                   	nop
   12d3c:	eb 01                	jmp    12d3f <km_init+0x1b4>
				continue;
   12d3e:	90                   	nop
	for( int i = 0; i < entries; ++i, ++region ) {
   12d3f:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   12d43:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
   12d47:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12d4a:	3b 45 dc             	cmp    -0x24(%ebp),%eax
   12d4d:	0f 8c a8 fe ff ff    	jl     12bfb <km_init+0x70>
	}

	// record the initialization
	km_initialized = 1;
   12d53:	c7 05 24 d1 01 00 01 	movl   $0x1,0x1d124
   12d5a:	00 00 00 
   12d5d:	eb 01                	jmp    12d60 <km_init+0x1d5>
		return;
   12d5f:	90                   	nop
#if KMEM_OR_INIT
	delay( DELAY_1_SEC );
#endif
}
   12d60:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   12d63:	c9                   	leave  
   12d64:	c3                   	ret    

00012d65 <km_dump>:
/**
** Name:    km_dump
**
** Dump the current contents of the free list to the console
*/
void km_dump( void ) {
   12d65:	55                   	push   %ebp
   12d66:	89 e5                	mov    %esp,%ebp
   12d68:	53                   	push   %ebx
   12d69:	83 ec 14             	sub    $0x14,%esp
	Blockinfo *block;

	cio_printf( "&free_pages=%08x, &free_slices %08x, %u pages, %u slices\n",
   12d6c:	8b 15 20 d1 01 00    	mov    0x1d120,%edx
   12d72:	a1 1c d1 01 00       	mov    0x1d11c,%eax
   12d77:	bb 18 d1 01 00       	mov    $0x1d118,%ebx
   12d7c:	b9 14 d1 01 00       	mov    $0x1d114,%ecx
   12d81:	83 ec 0c             	sub    $0xc,%esp
   12d84:	52                   	push   %edx
   12d85:	50                   	push   %eax
   12d86:	53                   	push   %ebx
   12d87:	51                   	push   %ecx
   12d88:	68 38 ad 01 00       	push   $0x1ad38
   12d8d:	e8 95 e7 ff ff       	call   11527 <cio_printf>
   12d92:	83 c4 20             	add    $0x20,%esp
			(uint32_t) &free_pages, (uint32_t) &free_slices,
			n_pages, n_slices );

	for( block = free_pages; block != NULL; block = block->next ) {
   12d95:	a1 14 d1 01 00       	mov    0x1d114,%eax
   12d9a:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12d9d:	eb 39                	jmp    12dd8 <km_dump+0x73>
		cio_printf(
   12d9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12da2:	8b 50 04             	mov    0x4(%eax),%edx
			"block @ 0x%08x 0x%08x pages (ends at 0x%08x) next @ 0x%08x\n",
				block, block->pages, P2B(block->pages) + (uint32_t) block,
   12da5:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12da8:	8b 00                	mov    (%eax),%eax
   12daa:	c1 e0 0c             	shl    $0xc,%eax
   12dad:	89 c1                	mov    %eax,%ecx
   12daf:	8b 45 f4             	mov    -0xc(%ebp),%eax
		cio_printf(
   12db2:	01 c1                	add    %eax,%ecx
   12db4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12db7:	8b 00                	mov    (%eax),%eax
   12db9:	83 ec 0c             	sub    $0xc,%esp
   12dbc:	52                   	push   %edx
   12dbd:	51                   	push   %ecx
   12dbe:	50                   	push   %eax
   12dbf:	ff 75 f4             	pushl  -0xc(%ebp)
   12dc2:	68 74 ad 01 00       	push   $0x1ad74
   12dc7:	e8 5b e7 ff ff       	call   11527 <cio_printf>
   12dcc:	83 c4 20             	add    $0x20,%esp
	for( block = free_pages; block != NULL; block = block->next ) {
   12dcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12dd2:	8b 40 04             	mov    0x4(%eax),%eax
   12dd5:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12dd8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12ddc:	75 c1                	jne    12d9f <km_dump+0x3a>
				block->next );
	}

	for( block = free_slices; block != NULL; block = block->next ) {
   12dde:	a1 18 d1 01 00       	mov    0x1d118,%eax
   12de3:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12de6:	eb 39                	jmp    12e21 <km_dump+0xbc>
		cio_printf(
   12de8:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12deb:	8b 50 04             	mov    0x4(%eax),%edx
			"block @ 0x%08x 0x%08x slices (ends at 0x%08x) next @ 0x%08x\n",
				block, block->pages, P2B(block->pages) + (uint32_t) block,
   12dee:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12df1:	8b 00                	mov    (%eax),%eax
   12df3:	c1 e0 0c             	shl    $0xc,%eax
   12df6:	89 c1                	mov    %eax,%ecx
   12df8:	8b 45 f4             	mov    -0xc(%ebp),%eax
		cio_printf(
   12dfb:	01 c1                	add    %eax,%ecx
   12dfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12e00:	8b 00                	mov    (%eax),%eax
   12e02:	83 ec 0c             	sub    $0xc,%esp
   12e05:	52                   	push   %edx
   12e06:	51                   	push   %ecx
   12e07:	50                   	push   %eax
   12e08:	ff 75 f4             	pushl  -0xc(%ebp)
   12e0b:	68 b0 ad 01 00       	push   $0x1adb0
   12e10:	e8 12 e7 ff ff       	call   11527 <cio_printf>
   12e15:	83 c4 20             	add    $0x20,%esp
	for( block = free_slices; block != NULL; block = block->next ) {
   12e18:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12e1b:	8b 40 04             	mov    0x4(%eax),%eax
   12e1e:	89 45 f4             	mov    %eax,-0xc(%ebp)
   12e21:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12e25:	75 c1                	jne    12de8 <km_dump+0x83>
				block->next );
	}

}
   12e27:	90                   	nop
   12e28:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   12e2b:	c9                   	leave  
   12e2c:	c3                   	ret    

00012e2d <km_page_alloc>:
** @param count  Number of contiguous pages desired
**
** @return a pointer to the beginning of the first allocated page,
**         or NULL if no memory is available
*/
void *km_page_alloc( unsigned int count ) {
   12e2d:	55                   	push   %ebp
   12e2e:	89 e5                	mov    %esp,%ebp
   12e30:	83 ec 28             	sub    $0x28,%esp

	assert( km_initialized );
   12e33:	a1 24 d1 01 00       	mov    0x1d124,%eax
   12e38:	85 c0                	test   %eax,%eax
   12e3a:	75 3b                	jne    12e77 <km_page_alloc+0x4a>
   12e3c:	83 ec 04             	sub    $0x4,%esp
   12e3f:	68 ed ad 01 00       	push   $0x1aded
   12e44:	6a 00                	push   $0x0
   12e46:	68 ee 01 00 00       	push   $0x1ee
   12e4b:	68 15 ad 01 00       	push   $0x1ad15
   12e50:	68 18 ae 01 00       	push   $0x1ae18
   12e55:	68 1c ad 01 00       	push   $0x1ad1c
   12e5a:	68 00 f0 01 00       	push   $0x1f000
   12e5f:	e8 7e f8 ff ff       	call   126e2 <sprint>
   12e64:	83 c4 20             	add    $0x20,%esp
   12e67:	83 ec 0c             	sub    $0xc,%esp
   12e6a:	68 00 f0 01 00       	push   $0x1f000
   12e6f:	e8 ee f5 ff ff       	call   12462 <kpanic>
   12e74:	83 c4 10             	add    $0x10,%esp

	// make sure we actually need to do something!
	if( count < 1 ) {
   12e77:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12e7b:	75 0a                	jne    12e87 <km_page_alloc+0x5a>
		return( NULL );
   12e7d:	b8 00 00 00 00       	mov    $0x0,%eax
   12e82:	e9 a9 00 00 00       	jmp    12f30 <km_page_alloc+0x103>
	/*
	** Look for the first entry that is large enough.
	*/

	// pointer to the current block
	Blockinfo *block = free_pages;
   12e87:	a1 14 d1 01 00       	mov    0x1d114,%eax
   12e8c:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// pointer to where the pointer to the current block is
	Blockinfo **pointer = &free_pages;
   12e8f:	c7 45 f0 14 d1 01 00 	movl   $0x1d114,-0x10(%ebp)

	while( block != NULL && block->pages < count ){
   12e96:	eb 11                	jmp    12ea9 <km_page_alloc+0x7c>
		pointer = &block->next;
   12e98:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12e9b:	83 c0 04             	add    $0x4,%eax
   12e9e:	89 45 f0             	mov    %eax,-0x10(%ebp)
		block = *pointer;
   12ea1:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12ea4:	8b 00                	mov    (%eax),%eax
   12ea6:	89 45 f4             	mov    %eax,-0xc(%ebp)
	while( block != NULL && block->pages < count ){
   12ea9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12ead:	74 0a                	je     12eb9 <km_page_alloc+0x8c>
   12eaf:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12eb2:	8b 00                	mov    (%eax),%eax
   12eb4:	39 45 08             	cmp    %eax,0x8(%ebp)
   12eb7:	77 df                	ja     12e98 <km_page_alloc+0x6b>
	}

	// did we find a big enough block?
	if( block == NULL ){
   12eb9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   12ebd:	75 07                	jne    12ec6 <km_page_alloc+0x99>
		// nope!
		return( NULL );
   12ebf:	b8 00 00 00 00       	mov    $0x0,%eax
   12ec4:	eb 6a                	jmp    12f30 <km_page_alloc+0x103>
	}

	// found one!  check the length

	if( block->pages == count ) {
   12ec6:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ec9:	8b 00                	mov    (%eax),%eax
   12ecb:	39 45 08             	cmp    %eax,0x8(%ebp)
   12ece:	75 0d                	jne    12edd <km_page_alloc+0xb0>

		// exactly the right size - unlink it from the list

		*pointer = block->next;
   12ed0:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ed3:	8b 50 04             	mov    0x4(%eax),%edx
   12ed6:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12ed9:	89 10                	mov    %edx,(%eax)
   12edb:	eb 43                	jmp    12f20 <km_page_alloc+0xf3>

		// bigger than we need - carve the amount we need off
		// the beginning of this block

		// remember where this chunk begins
		Blockinfo *chunk = block;
   12edd:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ee0:	89 45 ec             	mov    %eax,-0x14(%ebp)

		// how much space will be left over?
		int excess = block->pages - count;
   12ee3:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ee6:	8b 00                	mov    (%eax),%eax
   12ee8:	2b 45 08             	sub    0x8(%ebp),%eax
   12eeb:	89 45 e8             	mov    %eax,-0x18(%ebp)

		// find the start of the new fragment
		Blockinfo *fragment = (Blockinfo *) ( (uint8_t *) block + P2B(count) );
   12eee:	8b 45 08             	mov    0x8(%ebp),%eax
   12ef1:	c1 e0 0c             	shl    $0xc,%eax
   12ef4:	89 c2                	mov    %eax,%edx
   12ef6:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12ef9:	01 d0                	add    %edx,%eax
   12efb:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// set the length and link for the new fragment
		fragment->pages = excess;
   12efe:	8b 55 e8             	mov    -0x18(%ebp),%edx
   12f01:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   12f04:	89 10                	mov    %edx,(%eax)
		fragment->next  = block->next;
   12f06:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12f09:	8b 50 04             	mov    0x4(%eax),%edx
   12f0c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   12f0f:	89 50 04             	mov    %edx,0x4(%eax)

		// replace this chunk with the fragment
		*pointer = fragment;
   12f12:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12f15:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   12f18:	89 10                	mov    %edx,(%eax)

		// return this chunk
		block = chunk;
   12f1a:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12f1d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	}

	// fix the count of available pages
	n_pages -= count;;
   12f20:	a1 1c d1 01 00       	mov    0x1d11c,%eax
   12f25:	2b 45 08             	sub    0x8(%ebp),%eax
   12f28:	a3 1c d1 01 00       	mov    %eax,0x1d11c

	return( block );
   12f2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   12f30:	c9                   	leave  
   12f31:	c3                   	ret    

00012f32 <km_page_free>:
** CRITICAL NOTE:  multi-page blocks must be freed one page
** at a time OR freed using km_page_free_multi()!
**
** @param block   Pointer to the page to be returned to the free list
*/
void km_page_free( void *block ) {
   12f32:	55                   	push   %ebp
   12f33:	89 e5                	mov    %esp,%ebp
   12f35:	83 ec 08             	sub    $0x8,%esp

	/*
	** Don't do anything if the address is NULL.
	*/
	if( block == NULL ){
   12f38:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12f3c:	74 12                	je     12f50 <km_page_free+0x1e>
		return;
	}

	km_page_free_multi( block, 1 );
   12f3e:	83 ec 08             	sub    $0x8,%esp
   12f41:	6a 01                	push   $0x1
   12f43:	ff 75 08             	pushl  0x8(%ebp)
   12f46:	e8 08 00 00 00       	call   12f53 <km_page_free_multi>
   12f4b:	83 c4 10             	add    $0x10,%esp
   12f4e:	eb 01                	jmp    12f51 <km_page_free+0x1f>
		return;
   12f50:	90                   	nop
}
   12f51:	c9                   	leave  
   12f52:	c3                   	ret    

00012f53 <km_page_free_multi>:
** accepts a pointer to a multi-page block of memory.
**
** @param block   Pointer to the block to be returned to the free list
** @param count   Number of pages in the block
*/
void km_page_free_multi( void *block, uint32_t count ) {
   12f53:	55                   	push   %ebp
   12f54:	89 e5                	mov    %esp,%ebp
   12f56:	83 ec 18             	sub    $0x18,%esp
	Blockinfo *used;
	Blockinfo *prev;
	Blockinfo *curr;

	assert( km_initialized );
   12f59:	a1 24 d1 01 00       	mov    0x1d124,%eax
   12f5e:	85 c0                	test   %eax,%eax
   12f60:	75 3b                	jne    12f9d <km_page_free_multi+0x4a>
   12f62:	83 ec 04             	sub    $0x4,%esp
   12f65:	68 ed ad 01 00       	push   $0x1aded
   12f6a:	6a 00                	push   $0x0
   12f6c:	68 57 02 00 00       	push   $0x257
   12f71:	68 15 ad 01 00       	push   $0x1ad15
   12f76:	68 28 ae 01 00       	push   $0x1ae28
   12f7b:	68 1c ad 01 00       	push   $0x1ad1c
   12f80:	68 00 f0 01 00       	push   $0x1f000
   12f85:	e8 58 f7 ff ff       	call   126e2 <sprint>
   12f8a:	83 c4 20             	add    $0x20,%esp
   12f8d:	83 ec 0c             	sub    $0xc,%esp
   12f90:	68 00 f0 01 00       	push   $0x1f000
   12f95:	e8 c8 f4 ff ff       	call   12462 <kpanic>
   12f9a:	83 c4 10             	add    $0x10,%esp

	/*
	** Don't do anything if the address is NULL.
	*/
	if( block == NULL ){
   12f9d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   12fa1:	0f 84 e3 00 00 00    	je     1308a <km_page_free_multi+0x137>
		return;
	}

	used = (Blockinfo *) block;
   12fa7:	8b 45 08             	mov    0x8(%ebp),%eax
   12faa:	89 45 f4             	mov    %eax,-0xc(%ebp)
	used->pages = count;
   12fad:	8b 45 f4             	mov    -0xc(%ebp),%eax
   12fb0:	8b 55 0c             	mov    0xc(%ebp),%edx
   12fb3:	89 10                	mov    %edx,(%eax)

	/*
	** Advance through the list until current and previous
	** straddle the place where the new block should be inserted.
	*/
	prev = NULL;
   12fb5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	curr = free_pages;
   12fbc:	a1 14 d1 01 00       	mov    0x1d114,%eax
   12fc1:	89 45 ec             	mov    %eax,-0x14(%ebp)

	while( curr != NULL && curr < used ){
   12fc4:	eb 0f                	jmp    12fd5 <km_page_free_multi+0x82>
		prev = curr;
   12fc6:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12fc9:	89 45 f0             	mov    %eax,-0x10(%ebp)
		curr = curr->next;
   12fcc:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12fcf:	8b 40 04             	mov    0x4(%eax),%eax
   12fd2:	89 45 ec             	mov    %eax,-0x14(%ebp)
	while( curr != NULL && curr < used ){
   12fd5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   12fd9:	74 08                	je     12fe3 <km_page_free_multi+0x90>
   12fdb:	8b 45 ec             	mov    -0x14(%ebp),%eax
   12fde:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   12fe1:	72 e3                	jb     12fc6 <km_page_free_multi+0x73>

	/*
	** If this is not the first block in the resulting list,
	** we may need to merge it with its predecessor.
	*/
	if( prev != NULL ){
   12fe3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   12fe7:	74 44                	je     1302d <km_page_free_multi+0xda>

		// There is a predecessor.  Check to see if we need to merge.
		if( adjacent( prev, used ) ){
   12fe9:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12fec:	8b 00                	mov    (%eax),%eax
   12fee:	c1 e0 0c             	shl    $0xc,%eax
   12ff1:	89 c2                	mov    %eax,%edx
   12ff3:	8b 45 f0             	mov    -0x10(%ebp),%eax
   12ff6:	01 d0                	add    %edx,%eax
   12ff8:	39 45 f4             	cmp    %eax,-0xc(%ebp)
   12ffb:	75 19                	jne    13016 <km_page_free_multi+0xc3>

			// yes - merge them
			prev->pages += used->pages;
   12ffd:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13000:	8b 10                	mov    (%eax),%edx
   13002:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13005:	8b 00                	mov    (%eax),%eax
   13007:	01 c2                	add    %eax,%edx
   13009:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1300c:	89 10                	mov    %edx,(%eax)

			// the predecessor becomes the "newly inserted" block,
			// because we still need to check to see if we should
			// merge with the successor
			used = prev;
   1300e:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13011:	89 45 f4             	mov    %eax,-0xc(%ebp)
   13014:	eb 2b                	jmp    13041 <km_page_free_multi+0xee>

		} else {

			// Not adjacent - just insert the new block
			// between the predecessor and the successor.
			used->next = prev->next;
   13016:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13019:	8b 50 04             	mov    0x4(%eax),%edx
   1301c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1301f:	89 50 04             	mov    %edx,0x4(%eax)
			prev->next = used;
   13022:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13025:	8b 55 f4             	mov    -0xc(%ebp),%edx
   13028:	89 50 04             	mov    %edx,0x4(%eax)
   1302b:	eb 14                	jmp    13041 <km_page_free_multi+0xee>
		}

	} else {

		// Yes, it is first.  Update the list pointer to insert it.
		used->next = free_pages;
   1302d:	8b 15 14 d1 01 00    	mov    0x1d114,%edx
   13033:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13036:	89 50 04             	mov    %edx,0x4(%eax)
		free_pages = used;
   13039:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1303c:	a3 14 d1 01 00       	mov    %eax,0x1d114

	/*
	** If this is not the last block in the resulting list,
	** we may (also) need to merge it with its successor.
	*/
	if( curr != NULL ){
   13041:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   13045:	74 31                	je     13078 <km_page_free_multi+0x125>

		// No.  Check to see if it should be merged with the successor.
		if( adjacent( used, curr ) ){
   13047:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1304a:	8b 00                	mov    (%eax),%eax
   1304c:	c1 e0 0c             	shl    $0xc,%eax
   1304f:	89 c2                	mov    %eax,%edx
   13051:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13054:	01 d0                	add    %edx,%eax
   13056:	39 45 ec             	cmp    %eax,-0x14(%ebp)
   13059:	75 1d                	jne    13078 <km_page_free_multi+0x125>

			// Yes, combine them.
			used->next = curr->next;
   1305b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1305e:	8b 50 04             	mov    0x4(%eax),%edx
   13061:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13064:	89 50 04             	mov    %edx,0x4(%eax)
			used->pages += curr->pages;
   13067:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1306a:	8b 10                	mov    (%eax),%edx
   1306c:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1306f:	8b 00                	mov    (%eax),%eax
   13071:	01 c2                	add    %eax,%edx
   13073:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13076:	89 10                	mov    %edx,(%eax)

		}
	}

	// more in the pool
	n_pages += count;
   13078:	8b 15 1c d1 01 00    	mov    0x1d11c,%edx
   1307e:	8b 45 0c             	mov    0xc(%ebp),%eax
   13081:	01 d0                	add    %edx,%eax
   13083:	a3 1c d1 01 00       	mov    %eax,0x1d11c
   13088:	eb 01                	jmp    1308b <km_page_free_multi+0x138>
		return;
   1308a:	90                   	nop
}
   1308b:	c9                   	leave  
   1308c:	c3                   	ret    

0001308d <carve_slices>:
** Name:        carve_slices
**
** Allocate a page and split it into four slices;  If no
**              memory is available, we panic.
*/
static void carve_slices( void ) {
   1308d:	55                   	push   %ebp
   1308e:	89 e5                	mov    %esp,%ebp
   13090:	83 ec 18             	sub    $0x18,%esp
	void *page;

	// get a page
	page = km_page_alloc( 1 );
   13093:	83 ec 0c             	sub    $0xc,%esp
   13096:	6a 01                	push   $0x1
   13098:	e8 90 fd ff ff       	call   12e2d <km_page_alloc>
   1309d:	83 c4 10             	add    $0x10,%esp
   130a0:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// allocation failure is a show-stopping problem
	assert( page );
   130a3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   130a7:	75 3b                	jne    130e4 <carve_slices+0x57>
   130a9:	83 ec 04             	sub    $0x4,%esp
   130ac:	68 fc ad 01 00       	push   $0x1adfc
   130b1:	6a 00                	push   $0x0
   130b3:	68 c8 02 00 00       	push   $0x2c8
   130b8:	68 15 ad 01 00       	push   $0x1ad15
   130bd:	68 3c ae 01 00       	push   $0x1ae3c
   130c2:	68 1c ad 01 00       	push   $0x1ad1c
   130c7:	68 00 f0 01 00       	push   $0x1f000
   130cc:	e8 11 f6 ff ff       	call   126e2 <sprint>
   130d1:	83 c4 20             	add    $0x20,%esp
   130d4:	83 ec 0c             	sub    $0xc,%esp
   130d7:	68 00 f0 01 00       	push   $0x1f000
   130dc:	e8 81 f3 ff ff       	call   12462 <kpanic>
   130e1:	83 c4 10             	add    $0x10,%esp

	// we have the page; create the four slices from it
	uint8_t *ptr = (uint8_t *) page;
   130e4:	8b 45 ec             	mov    -0x14(%ebp),%eax
   130e7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	for( int i = 0; i < 4; ++i ) {
   130ea:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   130f1:	eb 26                	jmp    13119 <carve_slices+0x8c>
		km_slice_free( (void *) ptr );
   130f3:	83 ec 0c             	sub    $0xc,%esp
   130f6:	ff 75 f4             	pushl  -0xc(%ebp)
   130f9:	e8 f5 00 00 00       	call   131f3 <km_slice_free>
   130fe:	83 c4 10             	add    $0x10,%esp
		ptr += SZ_SLICE;
   13101:	81 45 f4 00 04 00 00 	addl   $0x400,-0xc(%ebp)
		++n_slices;
   13108:	a1 20 d1 01 00       	mov    0x1d120,%eax
   1310d:	83 c0 01             	add    $0x1,%eax
   13110:	a3 20 d1 01 00       	mov    %eax,0x1d120
	for( int i = 0; i < 4; ++i ) {
   13115:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   13119:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
   1311d:	7e d4                	jle    130f3 <carve_slices+0x66>
	}
}
   1311f:	90                   	nop
   13120:	c9                   	leave  
   13121:	c3                   	ret    

00013122 <km_slice_alloc>:
** Dynamically allocates a slice (1/4 of a page).  If no
** memory is available, we panic.
**
** @return a pointer to the allocated slice
*/
void *km_slice_alloc( void ) {
   13122:	55                   	push   %ebp
   13123:	89 e5                	mov    %esp,%ebp
   13125:	83 ec 18             	sub    $0x18,%esp
	Blockinfo *slice;

	assert( km_initialized );
   13128:	a1 24 d1 01 00       	mov    0x1d124,%eax
   1312d:	85 c0                	test   %eax,%eax
   1312f:	75 3b                	jne    1316c <km_slice_alloc+0x4a>
   13131:	83 ec 04             	sub    $0x4,%esp
   13134:	68 ed ad 01 00       	push   $0x1aded
   13139:	6a 00                	push   $0x0
   1313b:	68 de 02 00 00       	push   $0x2de
   13140:	68 15 ad 01 00       	push   $0x1ad15
   13145:	68 4c ae 01 00       	push   $0x1ae4c
   1314a:	68 1c ad 01 00       	push   $0x1ad1c
   1314f:	68 00 f0 01 00       	push   $0x1f000
   13154:	e8 89 f5 ff ff       	call   126e2 <sprint>
   13159:	83 c4 20             	add    $0x20,%esp
   1315c:	83 ec 0c             	sub    $0xc,%esp
   1315f:	68 00 f0 01 00       	push   $0x1f000
   13164:	e8 f9 f2 ff ff       	call   12462 <kpanic>
   13169:	83 c4 10             	add    $0x10,%esp

	// if we are out of slices, create a few more
	if( free_slices == NULL ) {
   1316c:	a1 18 d1 01 00       	mov    0x1d118,%eax
   13171:	85 c0                	test   %eax,%eax
   13173:	75 05                	jne    1317a <km_slice_alloc+0x58>
		carve_slices();
   13175:	e8 13 ff ff ff       	call   1308d <carve_slices>
	}

	// take the first one from the free list
	slice = free_slices;
   1317a:	a1 18 d1 01 00       	mov    0x1d118,%eax
   1317f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert( slice != NULL );
   13182:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   13186:	75 3b                	jne    131c3 <km_slice_alloc+0xa1>
   13188:	83 ec 04             	sub    $0x4,%esp
   1318b:	68 01 ae 01 00       	push   $0x1ae01
   13190:	6a 00                	push   $0x0
   13192:	68 e7 02 00 00       	push   $0x2e7
   13197:	68 15 ad 01 00       	push   $0x1ad15
   1319c:	68 4c ae 01 00       	push   $0x1ae4c
   131a1:	68 1c ad 01 00       	push   $0x1ad1c
   131a6:	68 00 f0 01 00       	push   $0x1f000
   131ab:	e8 32 f5 ff ff       	call   126e2 <sprint>
   131b0:	83 c4 20             	add    $0x20,%esp
   131b3:	83 ec 0c             	sub    $0xc,%esp
   131b6:	68 00 f0 01 00       	push   $0x1f000
   131bb:	e8 a2 f2 ff ff       	call   12462 <kpanic>
   131c0:	83 c4 10             	add    $0x10,%esp
	--n_slices;
   131c3:	a1 20 d1 01 00       	mov    0x1d120,%eax
   131c8:	83 e8 01             	sub    $0x1,%eax
   131cb:	a3 20 d1 01 00       	mov    %eax,0x1d120

	// unlink it
	free_slices = slice->next;
   131d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
   131d3:	8b 40 04             	mov    0x4(%eax),%eax
   131d6:	a3 18 d1 01 00       	mov    %eax,0x1d118

	// make it nice and shiny for the caller
	memclr( (void *) slice, SZ_SLICE );
   131db:	83 ec 08             	sub    $0x8,%esp
   131de:	68 00 04 00 00       	push   $0x400
   131e3:	ff 75 f4             	pushl  -0xc(%ebp)
   131e6:	e8 74 f3 ff ff       	call   1255f <memclr>
   131eb:	83 c4 10             	add    $0x10,%esp

	return( slice );
   131ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   131f1:	c9                   	leave  
   131f2:	c3                   	ret    

000131f3 <km_slice_free>:
** We make no attempt to merge slices, as they are independent
** blocks of memory (unlike pages).
**
** @param block  Pointer to the slice (1/4 page) to be freed
*/
void km_slice_free( void *block ) {
   131f3:	55                   	push   %ebp
   131f4:	89 e5                	mov    %esp,%ebp
   131f6:	83 ec 18             	sub    $0x18,%esp
	Blockinfo *slice = (Blockinfo *) block;
   131f9:	8b 45 08             	mov    0x8(%ebp),%eax
   131fc:	89 45 f4             	mov    %eax,-0xc(%ebp)

	assert( km_initialized );
   131ff:	a1 24 d1 01 00       	mov    0x1d124,%eax
   13204:	85 c0                	test   %eax,%eax
   13206:	75 3b                	jne    13243 <km_slice_free+0x50>
   13208:	83 ec 04             	sub    $0x4,%esp
   1320b:	68 ed ad 01 00       	push   $0x1aded
   13210:	6a 00                	push   $0x0
   13212:	68 00 03 00 00       	push   $0x300
   13217:	68 15 ad 01 00       	push   $0x1ad15
   1321c:	68 5c ae 01 00       	push   $0x1ae5c
   13221:	68 1c ad 01 00       	push   $0x1ad1c
   13226:	68 00 f0 01 00       	push   $0x1f000
   1322b:	e8 b2 f4 ff ff       	call   126e2 <sprint>
   13230:	83 c4 20             	add    $0x20,%esp
   13233:	83 ec 0c             	sub    $0xc,%esp
   13236:	68 00 f0 01 00       	push   $0x1f000
   1323b:	e8 22 f2 ff ff       	call   12462 <kpanic>
   13240:	83 c4 10             	add    $0x10,%esp

	// just add it to the front of the free list
	slice->pages = SZ_SLICE;
   13243:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13246:	c7 00 00 04 00 00    	movl   $0x400,(%eax)
	slice->next = free_slices;
   1324c:	8b 15 18 d1 01 00    	mov    0x1d118,%edx
   13252:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13255:	89 50 04             	mov    %edx,0x4(%eax)
	free_slices = slice;
   13258:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1325b:	a3 18 d1 01 00       	mov    %eax,0x1d118
	++n_slices;
   13260:	a1 20 d1 01 00       	mov    0x1d120,%eax
   13265:	83 c0 01             	add    $0x1,%eax
   13268:	a3 20 d1 01 00       	mov    %eax,0x1d120
}
   1326d:	90                   	nop
   1326e:	c9                   	leave  
   1326f:	c3                   	ret    

00013270 <list_add>:
** Add the supplied data to the beginning of the specified list.
**
** @param[in,out] list  The address of a list_t variable
** @param[in] data      The data to prepend to the list
*/
void list_add( list_t *list, void *data ) {
   13270:	55                   	push   %ebp
   13271:	89 e5                	mov    %esp,%ebp
   13273:	83 ec 18             	sub    $0x18,%esp

	// sanity checks
	assert1( list != NULL );
   13276:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1327a:	75 38                	jne    132b4 <list_add+0x44>
   1327c:	83 ec 04             	sub    $0x4,%esp
   1327f:	68 6c ae 01 00       	push   $0x1ae6c
   13284:	6a 01                	push   $0x1
   13286:	6a 23                	push   $0x23
   13288:	68 76 ae 01 00       	push   $0x1ae76
   1328d:	68 a0 ae 01 00       	push   $0x1aea0
   13292:	68 7d ae 01 00       	push   $0x1ae7d
   13297:	68 00 f0 01 00       	push   $0x1f000
   1329c:	e8 41 f4 ff ff       	call   126e2 <sprint>
   132a1:	83 c4 20             	add    $0x20,%esp
   132a4:	83 ec 0c             	sub    $0xc,%esp
   132a7:	68 00 f0 01 00       	push   $0x1f000
   132ac:	e8 b1 f1 ff ff       	call   12462 <kpanic>
   132b1:	83 c4 10             	add    $0x10,%esp
	assert1( data != NULL );
   132b4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   132b8:	75 38                	jne    132f2 <list_add+0x82>
   132ba:	83 ec 04             	sub    $0x4,%esp
   132bd:	68 93 ae 01 00       	push   $0x1ae93
   132c2:	6a 01                	push   $0x1
   132c4:	6a 24                	push   $0x24
   132c6:	68 76 ae 01 00       	push   $0x1ae76
   132cb:	68 a0 ae 01 00       	push   $0x1aea0
   132d0:	68 7d ae 01 00       	push   $0x1ae7d
   132d5:	68 00 f0 01 00       	push   $0x1f000
   132da:	e8 03 f4 ff ff       	call   126e2 <sprint>
   132df:	83 c4 20             	add    $0x20,%esp
   132e2:	83 ec 0c             	sub    $0xc,%esp
   132e5:	68 00 f0 01 00       	push   $0x1f000
   132ea:	e8 73 f1 ff ff       	call   12462 <kpanic>
   132ef:	83 c4 10             	add    $0x10,%esp

	list_t *tmp = (list_t *)data;
   132f2:	8b 45 0c             	mov    0xc(%ebp),%eax
   132f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tmp->next = list->next;
   132f8:	8b 45 08             	mov    0x8(%ebp),%eax
   132fb:	8b 10                	mov    (%eax),%edx
   132fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13300:	89 10                	mov    %edx,(%eax)
	list->next = tmp;
   13302:	8b 45 08             	mov    0x8(%ebp),%eax
   13305:	8b 55 f4             	mov    -0xc(%ebp),%edx
   13308:	89 10                	mov    %edx,(%eax)
}
   1330a:	90                   	nop
   1330b:	c9                   	leave  
   1330c:	c3                   	ret    

0001330d <list_remove>:
**
** @param[in,out] list  The address of a list_t variable
**
** @return a pointer to the removed data, or NULL if the list was empty
*/
void *list_remove( list_t *list ) {
   1330d:	55                   	push   %ebp
   1330e:	89 e5                	mov    %esp,%ebp
   13310:	83 ec 18             	sub    $0x18,%esp

	assert1( list != NULL );
   13313:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13317:	75 38                	jne    13351 <list_remove+0x44>
   13319:	83 ec 04             	sub    $0x4,%esp
   1331c:	68 6c ae 01 00       	push   $0x1ae6c
   13321:	6a 01                	push   $0x1
   13323:	6a 36                	push   $0x36
   13325:	68 76 ae 01 00       	push   $0x1ae76
   1332a:	68 ac ae 01 00       	push   $0x1aeac
   1332f:	68 7d ae 01 00       	push   $0x1ae7d
   13334:	68 00 f0 01 00       	push   $0x1f000
   13339:	e8 a4 f3 ff ff       	call   126e2 <sprint>
   1333e:	83 c4 20             	add    $0x20,%esp
   13341:	83 ec 0c             	sub    $0xc,%esp
   13344:	68 00 f0 01 00       	push   $0x1f000
   13349:	e8 14 f1 ff ff       	call   12462 <kpanic>
   1334e:	83 c4 10             	add    $0x10,%esp

	list_t *data = list->next;
   13351:	8b 45 08             	mov    0x8(%ebp),%eax
   13354:	8b 00                	mov    (%eax),%eax
   13356:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( data != NULL ) {
   13359:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1335d:	74 13                	je     13372 <list_remove+0x65>
		list->next = data->next;
   1335f:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13362:	8b 10                	mov    (%eax),%edx
   13364:	8b 45 08             	mov    0x8(%ebp),%eax
   13367:	89 10                	mov    %edx,(%eax)
		data->next = NULL;
   13369:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1336c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}

	return (void *)data;
   13372:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   13375:	c9                   	leave  
   13376:	c3                   	ret    

00013377 <find_prev_wakeup>:
** @param[in] pcb    The PCB to look for
**
** @return a pointer to the predecessor in the queue, or NULL if
** this PCB would be at the beginning of the queue.
*/
static pcb_t *find_prev_wakeup( pcb_queue_t queue, pcb_t *pcb ) {
   13377:	55                   	push   %ebp
   13378:	89 e5                	mov    %esp,%ebp
   1337a:	83 ec 18             	sub    $0x18,%esp

	// sanity checks!
	assert1( queue != NULL );
   1337d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13381:	75 3b                	jne    133be <find_prev_wakeup+0x47>
   13383:	83 ec 04             	sub    $0x4,%esp
   13386:	68 0c af 01 00       	push   $0x1af0c
   1338b:	6a 01                	push   $0x1
   1338d:	68 84 00 00 00       	push   $0x84
   13392:	68 17 af 01 00       	push   $0x1af17
   13397:	68 74 b3 01 00       	push   $0x1b374
   1339c:	68 1f af 01 00       	push   $0x1af1f
   133a1:	68 00 f0 01 00       	push   $0x1f000
   133a6:	e8 37 f3 ff ff       	call   126e2 <sprint>
   133ab:	83 c4 20             	add    $0x20,%esp
   133ae:	83 ec 0c             	sub    $0xc,%esp
   133b1:	68 00 f0 01 00       	push   $0x1f000
   133b6:	e8 a7 f0 ff ff       	call   12462 <kpanic>
   133bb:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   133be:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   133c2:	75 3b                	jne    133ff <find_prev_wakeup+0x88>
   133c4:	83 ec 04             	sub    $0x4,%esp
   133c7:	68 35 af 01 00       	push   $0x1af35
   133cc:	6a 01                	push   $0x1
   133ce:	68 85 00 00 00       	push   $0x85
   133d3:	68 17 af 01 00       	push   $0x1af17
   133d8:	68 74 b3 01 00       	push   $0x1b374
   133dd:	68 1f af 01 00       	push   $0x1af1f
   133e2:	68 00 f0 01 00       	push   $0x1f000
   133e7:	e8 f6 f2 ff ff       	call   126e2 <sprint>
   133ec:	83 c4 20             	add    $0x20,%esp
   133ef:	83 ec 0c             	sub    $0xc,%esp
   133f2:	68 00 f0 01 00       	push   $0x1f000
   133f7:	e8 66 f0 ff ff       	call   12462 <kpanic>
   133fc:	83 c4 10             	add    $0x10,%esp

	pcb_t *prev = NULL;
   133ff:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *curr = queue->head;
   13406:	8b 45 08             	mov    0x8(%ebp),%eax
   13409:	8b 00                	mov    (%eax),%eax
   1340b:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr != NULL && curr->wakeup <= pcb->wakeup ) {
   1340e:	eb 0f                	jmp    1341f <find_prev_wakeup+0xa8>
		prev = curr;
   13410:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13413:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   13416:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13419:	8b 40 08             	mov    0x8(%eax),%eax
   1341c:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr != NULL && curr->wakeup <= pcb->wakeup ) {
   1341f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   13423:	74 10                	je     13435 <find_prev_wakeup+0xbe>
   13425:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13428:	8b 50 10             	mov    0x10(%eax),%edx
   1342b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1342e:	8b 40 10             	mov    0x10(%eax),%eax
   13431:	39 c2                	cmp    %eax,%edx
   13433:	76 db                	jbe    13410 <find_prev_wakeup+0x99>
	}

	return prev;
   13435:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   13438:	c9                   	leave  
   13439:	c3                   	ret    

0001343a <find_prev_priority>:

static pcb_t *find_prev_priority( pcb_queue_t queue, pcb_t *pcb ) {
   1343a:	55                   	push   %ebp
   1343b:	89 e5                	mov    %esp,%ebp
   1343d:	83 ec 18             	sub    $0x18,%esp

	// sanity checks!
	assert1( queue != NULL );
   13440:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13444:	75 3b                	jne    13481 <find_prev_priority+0x47>
   13446:	83 ec 04             	sub    $0x4,%esp
   13449:	68 0c af 01 00       	push   $0x1af0c
   1344e:	6a 01                	push   $0x1
   13450:	68 95 00 00 00       	push   $0x95
   13455:	68 17 af 01 00       	push   $0x1af17
   1345a:	68 88 b3 01 00       	push   $0x1b388
   1345f:	68 1f af 01 00       	push   $0x1af1f
   13464:	68 00 f0 01 00       	push   $0x1f000
   13469:	e8 74 f2 ff ff       	call   126e2 <sprint>
   1346e:	83 c4 20             	add    $0x20,%esp
   13471:	83 ec 0c             	sub    $0xc,%esp
   13474:	68 00 f0 01 00       	push   $0x1f000
   13479:	e8 e4 ef ff ff       	call   12462 <kpanic>
   1347e:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   13481:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   13485:	75 3b                	jne    134c2 <find_prev_priority+0x88>
   13487:	83 ec 04             	sub    $0x4,%esp
   1348a:	68 35 af 01 00       	push   $0x1af35
   1348f:	6a 01                	push   $0x1
   13491:	68 96 00 00 00       	push   $0x96
   13496:	68 17 af 01 00       	push   $0x1af17
   1349b:	68 88 b3 01 00       	push   $0x1b388
   134a0:	68 1f af 01 00       	push   $0x1af1f
   134a5:	68 00 f0 01 00       	push   $0x1f000
   134aa:	e8 33 f2 ff ff       	call   126e2 <sprint>
   134af:	83 c4 20             	add    $0x20,%esp
   134b2:	83 ec 0c             	sub    $0xc,%esp
   134b5:	68 00 f0 01 00       	push   $0x1f000
   134ba:	e8 a3 ef ff ff       	call   12462 <kpanic>
   134bf:	83 c4 10             	add    $0x10,%esp

	pcb_t *prev = NULL;
   134c2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *curr = queue->head;
   134c9:	8b 45 08             	mov    0x8(%ebp),%eax
   134cc:	8b 00                	mov    (%eax),%eax
   134ce:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr != NULL && curr->priority <= pcb->priority ) {
   134d1:	eb 0f                	jmp    134e2 <find_prev_priority+0xa8>
		prev = curr;
   134d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
   134d6:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   134d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
   134dc:	8b 40 08             	mov    0x8(%eax),%eax
   134df:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr != NULL && curr->priority <= pcb->priority ) {
   134e2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   134e6:	74 10                	je     134f8 <find_prev_priority+0xbe>
   134e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
   134eb:	8b 50 20             	mov    0x20(%eax),%edx
   134ee:	8b 45 0c             	mov    0xc(%ebp),%eax
   134f1:	8b 40 20             	mov    0x20(%eax),%eax
   134f4:	39 c2                	cmp    %eax,%edx
   134f6:	76 db                	jbe    134d3 <find_prev_priority+0x99>
	}

	return prev;
   134f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   134fb:	c9                   	leave  
   134fc:	c3                   	ret    

000134fd <find_prev_pid>:

static pcb_t *find_prev_pid( pcb_queue_t queue, pcb_t *pcb ) {
   134fd:	55                   	push   %ebp
   134fe:	89 e5                	mov    %esp,%ebp
   13500:	83 ec 18             	sub    $0x18,%esp

	// sanity checks!
	assert1( queue != NULL );
   13503:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13507:	75 3b                	jne    13544 <find_prev_pid+0x47>
   13509:	83 ec 04             	sub    $0x4,%esp
   1350c:	68 0c af 01 00       	push   $0x1af0c
   13511:	6a 01                	push   $0x1
   13513:	68 a6 00 00 00       	push   $0xa6
   13518:	68 17 af 01 00       	push   $0x1af17
   1351d:	68 9c b3 01 00       	push   $0x1b39c
   13522:	68 1f af 01 00       	push   $0x1af1f
   13527:	68 00 f0 01 00       	push   $0x1f000
   1352c:	e8 b1 f1 ff ff       	call   126e2 <sprint>
   13531:	83 c4 20             	add    $0x20,%esp
   13534:	83 ec 0c             	sub    $0xc,%esp
   13537:	68 00 f0 01 00       	push   $0x1f000
   1353c:	e8 21 ef ff ff       	call   12462 <kpanic>
   13541:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   13544:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   13548:	75 3b                	jne    13585 <find_prev_pid+0x88>
   1354a:	83 ec 04             	sub    $0x4,%esp
   1354d:	68 35 af 01 00       	push   $0x1af35
   13552:	6a 01                	push   $0x1
   13554:	68 a7 00 00 00       	push   $0xa7
   13559:	68 17 af 01 00       	push   $0x1af17
   1355e:	68 9c b3 01 00       	push   $0x1b39c
   13563:	68 1f af 01 00       	push   $0x1af1f
   13568:	68 00 f0 01 00       	push   $0x1f000
   1356d:	e8 70 f1 ff ff       	call   126e2 <sprint>
   13572:	83 c4 20             	add    $0x20,%esp
   13575:	83 ec 0c             	sub    $0xc,%esp
   13578:	68 00 f0 01 00       	push   $0x1f000
   1357d:	e8 e0 ee ff ff       	call   12462 <kpanic>
   13582:	83 c4 10             	add    $0x10,%esp

	pcb_t *prev = NULL;
   13585:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *curr = queue->head;
   1358c:	8b 45 08             	mov    0x8(%ebp),%eax
   1358f:	8b 00                	mov    (%eax),%eax
   13591:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr != NULL && curr->pid <= pcb->pid ) {
   13594:	eb 0f                	jmp    135a5 <find_prev_pid+0xa8>
		prev = curr;
   13596:	8b 45 f0             	mov    -0x10(%ebp),%eax
   13599:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   1359c:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1359f:	8b 40 08             	mov    0x8(%eax),%eax
   135a2:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr != NULL && curr->pid <= pcb->pid ) {
   135a5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   135a9:	74 10                	je     135bb <find_prev_pid+0xbe>
   135ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
   135ae:	8b 50 18             	mov    0x18(%eax),%edx
   135b1:	8b 45 0c             	mov    0xc(%ebp),%eax
   135b4:	8b 40 18             	mov    0x18(%eax),%eax
   135b7:	39 c2                	cmp    %eax,%edx
   135b9:	76 db                	jbe    13596 <find_prev_pid+0x99>
	}

	return prev;
   135bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   135be:	c9                   	leave  
   135bf:	c3                   	ret    

000135c0 <pcb_init>:
/**
** Name:	pcb_init
**
** Initialization for the Process module.
*/
void pcb_init( void ) {
   135c0:	55                   	push   %ebp
   135c1:	89 e5                	mov    %esp,%ebp
   135c3:	83 ec 18             	sub    $0x18,%esp

#if TRACING_INIT
	cio_puts( " Procs" );
   135c6:	83 ec 0c             	sub    $0xc,%esp
   135c9:	68 3e af 01 00       	push   $0x1af3e
   135ce:	e8 da d8 ff ff       	call   10ead <cio_puts>
   135d3:	83 c4 10             	add    $0x10,%esp
#endif

	// there is no current process
	current = NULL;
   135d6:	c7 05 14 10 02 00 00 	movl   $0x0,0x21014
   135dd:	00 00 00 

	// first user PID
	next_pid = FIRST_USER_PID;
   135e0:	c7 05 1c 10 02 00 02 	movl   $0x2,0x2101c
   135e7:	00 00 00 

	// set up the external links to the queues
	QINIT( pcb_freelist, O_FIFO );
   135ea:	c7 05 00 10 02 00 28 	movl   $0x1d128,0x21000
   135f1:	d1 01 00 
   135f4:	a1 00 10 02 00       	mov    0x21000,%eax
   135f9:	83 ec 08             	sub    $0x8,%esp
   135fc:	6a 00                	push   $0x0
   135fe:	50                   	push   %eax
   135ff:	e8 9c 07 00 00       	call   13da0 <pcb_queue_reset>
   13604:	83 c4 10             	add    $0x10,%esp
   13607:	85 c0                	test   %eax,%eax
   13609:	74 3b                	je     13646 <pcb_init+0x86>
   1360b:	83 ec 04             	sub    $0x4,%esp
   1360e:	68 48 af 01 00       	push   $0x1af48
   13613:	6a 00                	push   $0x0
   13615:	68 d1 00 00 00       	push   $0xd1
   1361a:	68 17 af 01 00       	push   $0x1af17
   1361f:	68 ac b3 01 00       	push   $0x1b3ac
   13624:	68 1f af 01 00       	push   $0x1af1f
   13629:	68 00 f0 01 00       	push   $0x1f000
   1362e:	e8 af f0 ff ff       	call   126e2 <sprint>
   13633:	83 c4 20             	add    $0x20,%esp
   13636:	83 ec 0c             	sub    $0xc,%esp
   13639:	68 00 f0 01 00       	push   $0x1f000
   1363e:	e8 1f ee ff ff       	call   12462 <kpanic>
   13643:	83 c4 10             	add    $0x10,%esp
	QINIT( ready, O_PRIO );
   13646:	c7 05 d0 14 02 00 34 	movl   $0x1d134,0x214d0
   1364d:	d1 01 00 
   13650:	a1 d0 14 02 00       	mov    0x214d0,%eax
   13655:	83 ec 08             	sub    $0x8,%esp
   13658:	6a 01                	push   $0x1
   1365a:	50                   	push   %eax
   1365b:	e8 40 07 00 00       	call   13da0 <pcb_queue_reset>
   13660:	83 c4 10             	add    $0x10,%esp
   13663:	85 c0                	test   %eax,%eax
   13665:	74 3b                	je     136a2 <pcb_init+0xe2>
   13667:	83 ec 04             	sub    $0x4,%esp
   1366a:	68 70 af 01 00       	push   $0x1af70
   1366f:	6a 00                	push   $0x0
   13671:	68 d2 00 00 00       	push   $0xd2
   13676:	68 17 af 01 00       	push   $0x1af17
   1367b:	68 ac b3 01 00       	push   $0x1b3ac
   13680:	68 1f af 01 00       	push   $0x1af1f
   13685:	68 00 f0 01 00       	push   $0x1f000
   1368a:	e8 53 f0 ff ff       	call   126e2 <sprint>
   1368f:	83 c4 20             	add    $0x20,%esp
   13692:	83 ec 0c             	sub    $0xc,%esp
   13695:	68 00 f0 01 00       	push   $0x1f000
   1369a:	e8 c3 ed ff ff       	call   12462 <kpanic>
   1369f:	83 c4 10             	add    $0x10,%esp
	QINIT( waiting, O_PID );
   136a2:	c7 05 10 10 02 00 40 	movl   $0x1d140,0x21010
   136a9:	d1 01 00 
   136ac:	a1 10 10 02 00       	mov    0x21010,%eax
   136b1:	83 ec 08             	sub    $0x8,%esp
   136b4:	6a 02                	push   $0x2
   136b6:	50                   	push   %eax
   136b7:	e8 e4 06 00 00       	call   13da0 <pcb_queue_reset>
   136bc:	83 c4 10             	add    $0x10,%esp
   136bf:	85 c0                	test   %eax,%eax
   136c1:	74 3b                	je     136fe <pcb_init+0x13e>
   136c3:	83 ec 04             	sub    $0x4,%esp
   136c6:	68 90 af 01 00       	push   $0x1af90
   136cb:	6a 00                	push   $0x0
   136cd:	68 d3 00 00 00       	push   $0xd3
   136d2:	68 17 af 01 00       	push   $0x1af17
   136d7:	68 ac b3 01 00       	push   $0x1b3ac
   136dc:	68 1f af 01 00       	push   $0x1af1f
   136e1:	68 00 f0 01 00       	push   $0x1f000
   136e6:	e8 f7 ef ff ff       	call   126e2 <sprint>
   136eb:	83 c4 20             	add    $0x20,%esp
   136ee:	83 ec 0c             	sub    $0xc,%esp
   136f1:	68 00 f0 01 00       	push   $0x1f000
   136f6:	e8 67 ed ff ff       	call   12462 <kpanic>
   136fb:	83 c4 10             	add    $0x10,%esp
	QINIT( sleeping, O_WAKEUP );
   136fe:	c7 05 08 10 02 00 4c 	movl   $0x1d14c,0x21008
   13705:	d1 01 00 
   13708:	a1 08 10 02 00       	mov    0x21008,%eax
   1370d:	83 ec 08             	sub    $0x8,%esp
   13710:	6a 03                	push   $0x3
   13712:	50                   	push   %eax
   13713:	e8 88 06 00 00       	call   13da0 <pcb_queue_reset>
   13718:	83 c4 10             	add    $0x10,%esp
   1371b:	85 c0                	test   %eax,%eax
   1371d:	74 3b                	je     1375a <pcb_init+0x19a>
   1371f:	83 ec 04             	sub    $0x4,%esp
   13722:	68 b4 af 01 00       	push   $0x1afb4
   13727:	6a 00                	push   $0x0
   13729:	68 d4 00 00 00       	push   $0xd4
   1372e:	68 17 af 01 00       	push   $0x1af17
   13733:	68 ac b3 01 00       	push   $0x1b3ac
   13738:	68 1f af 01 00       	push   $0x1af1f
   1373d:	68 00 f0 01 00       	push   $0x1f000
   13742:	e8 9b ef ff ff       	call   126e2 <sprint>
   13747:	83 c4 20             	add    $0x20,%esp
   1374a:	83 ec 0c             	sub    $0xc,%esp
   1374d:	68 00 f0 01 00       	push   $0x1f000
   13752:	e8 0b ed ff ff       	call   12462 <kpanic>
   13757:	83 c4 10             	add    $0x10,%esp
	QINIT( zombie, O_PID );
   1375a:	c7 05 18 10 02 00 58 	movl   $0x1d158,0x21018
   13761:	d1 01 00 
   13764:	a1 18 10 02 00       	mov    0x21018,%eax
   13769:	83 ec 08             	sub    $0x8,%esp
   1376c:	6a 02                	push   $0x2
   1376e:	50                   	push   %eax
   1376f:	e8 2c 06 00 00       	call   13da0 <pcb_queue_reset>
   13774:	83 c4 10             	add    $0x10,%esp
   13777:	85 c0                	test   %eax,%eax
   13779:	74 3b                	je     137b6 <pcb_init+0x1f6>
   1377b:	83 ec 04             	sub    $0x4,%esp
   1377e:	68 d8 af 01 00       	push   $0x1afd8
   13783:	6a 00                	push   $0x0
   13785:	68 d5 00 00 00       	push   $0xd5
   1378a:	68 17 af 01 00       	push   $0x1af17
   1378f:	68 ac b3 01 00       	push   $0x1b3ac
   13794:	68 1f af 01 00       	push   $0x1af1f
   13799:	68 00 f0 01 00       	push   $0x1f000
   1379e:	e8 3f ef ff ff       	call   126e2 <sprint>
   137a3:	83 c4 20             	add    $0x20,%esp
   137a6:	83 ec 0c             	sub    $0xc,%esp
   137a9:	68 00 f0 01 00       	push   $0x1f000
   137ae:	e8 af ec ff ff       	call   12462 <kpanic>
   137b3:	83 c4 10             	add    $0x10,%esp
	QINIT( sioread, O_FIFO );
   137b6:	c7 05 04 10 02 00 64 	movl   $0x1d164,0x21004
   137bd:	d1 01 00 
   137c0:	a1 04 10 02 00       	mov    0x21004,%eax
   137c5:	83 ec 08             	sub    $0x8,%esp
   137c8:	6a 00                	push   $0x0
   137ca:	50                   	push   %eax
   137cb:	e8 d0 05 00 00       	call   13da0 <pcb_queue_reset>
   137d0:	83 c4 10             	add    $0x10,%esp
   137d3:	85 c0                	test   %eax,%eax
   137d5:	74 3b                	je     13812 <pcb_init+0x252>
   137d7:	83 ec 04             	sub    $0x4,%esp
   137da:	68 fc af 01 00       	push   $0x1affc
   137df:	6a 00                	push   $0x0
   137e1:	68 d6 00 00 00       	push   $0xd6
   137e6:	68 17 af 01 00       	push   $0x1af17
   137eb:	68 ac b3 01 00       	push   $0x1b3ac
   137f0:	68 1f af 01 00       	push   $0x1af1f
   137f5:	68 00 f0 01 00       	push   $0x1f000
   137fa:	e8 e3 ee ff ff       	call   126e2 <sprint>
   137ff:	83 c4 20             	add    $0x20,%esp
   13802:	83 ec 0c             	sub    $0xc,%esp
   13805:	68 00 f0 01 00       	push   $0x1f000
   1380a:	e8 53 ec ff ff       	call   12462 <kpanic>
   1380f:	83 c4 10             	add    $0x10,%esp
	** so that we dynamically allocate PCBs, this step either
	** won't be required, or could be used to pre-allocate some
	** number of PCB structures for future use.
	*/

	pcb_t *ptr = ptable;
   13812:	c7 45 f4 20 10 02 00 	movl   $0x21020,-0xc(%ebp)
	for( int i = 0; i < N_PROCS; ++i ) {
   13819:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   13820:	eb 16                	jmp    13838 <pcb_init+0x278>
		pcb_free( ptr );
   13822:	83 ec 0c             	sub    $0xc,%esp
   13825:	ff 75 f4             	pushl  -0xc(%ebp)
   13828:	e8 8a 00 00 00       	call   138b7 <pcb_free>
   1382d:	83 c4 10             	add    $0x10,%esp
		++ptr;
   13830:	83 45 f4 30          	addl   $0x30,-0xc(%ebp)
	for( int i = 0; i < N_PROCS; ++i ) {
   13834:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   13838:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   1383c:	7e e4                	jle    13822 <pcb_init+0x262>
	}
}
   1383e:	90                   	nop
   1383f:	c9                   	leave  
   13840:	c3                   	ret    

00013841 <pcb_alloc>:
**
** @param pcb   Pointer to a pcb_t * where the PCB pointer will be returned.
**
** @return status of the allocation attempt
*/
int pcb_alloc( pcb_t **pcb ) {
   13841:	55                   	push   %ebp
   13842:	89 e5                	mov    %esp,%ebp
   13844:	83 ec 18             	sub    $0x18,%esp

	// sanity check!
	assert1( pcb != NULL );
   13847:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1384b:	75 3b                	jne    13888 <pcb_alloc+0x47>
   1384d:	83 ec 04             	sub    $0x4,%esp
   13850:	68 35 af 01 00       	push   $0x1af35
   13855:	6a 01                	push   $0x1
   13857:	68 f3 00 00 00       	push   $0xf3
   1385c:	68 17 af 01 00       	push   $0x1af17
   13861:	68 b8 b3 01 00       	push   $0x1b3b8
   13866:	68 1f af 01 00       	push   $0x1af1f
   1386b:	68 00 f0 01 00       	push   $0x1f000
   13870:	e8 6d ee ff ff       	call   126e2 <sprint>
   13875:	83 c4 20             	add    $0x20,%esp
   13878:	83 ec 0c             	sub    $0xc,%esp
   1387b:	68 00 f0 01 00       	push   $0x1f000
   13880:	e8 dd eb ff ff       	call   12462 <kpanic>
   13885:	83 c4 10             	add    $0x10,%esp

	// remove the first PCB from the free list
	pcb_t *tmp;
	if( pcb_queue_remove(pcb_freelist,&tmp) != SUCCESS ) {
   13888:	a1 00 10 02 00       	mov    0x21000,%eax
   1388d:	83 ec 08             	sub    $0x8,%esp
   13890:	8d 55 f4             	lea    -0xc(%ebp),%edx
   13893:	52                   	push   %edx
   13894:	50                   	push   %eax
   13895:	e8 1d 08 00 00       	call   140b7 <pcb_queue_remove>
   1389a:	83 c4 10             	add    $0x10,%esp
   1389d:	85 c0                	test   %eax,%eax
   1389f:	74 07                	je     138a8 <pcb_alloc+0x67>
		return E_NO_PCBS;
   138a1:	b8 9b ff ff ff       	mov    $0xffffff9b,%eax
   138a6:	eb 0d                	jmp    138b5 <pcb_alloc+0x74>
	}

	*pcb = tmp;
   138a8:	8b 55 f4             	mov    -0xc(%ebp),%edx
   138ab:	8b 45 08             	mov    0x8(%ebp),%eax
   138ae:	89 10                	mov    %edx,(%eax)
	return SUCCESS;
   138b0:	b8 00 00 00 00       	mov    $0x0,%eax
}
   138b5:	c9                   	leave  
   138b6:	c3                   	ret    

000138b7 <pcb_free>:
**
** Return a PCB to the list of free PCBs.
**
** @param pcb   Pointer to the PCB to be deallocated.
*/
void pcb_free( pcb_t *pcb ) {
   138b7:	55                   	push   %ebp
   138b8:	89 e5                	mov    %esp,%ebp
   138ba:	83 ec 18             	sub    $0x18,%esp

	if( pcb != NULL ) {
   138bd:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   138c1:	74 7b                	je     1393e <pcb_free+0x87>
		// mark the PCB as available
		pcb->state = STATE_UNUSED;
   138c3:	8b 45 08             	mov    0x8(%ebp),%eax
   138c6:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

		// add it to the free list
		int status = pcb_queue_insert( pcb_freelist, pcb );
   138cd:	a1 00 10 02 00       	mov    0x21000,%eax
   138d2:	83 ec 08             	sub    $0x8,%esp
   138d5:	ff 75 08             	pushl  0x8(%ebp)
   138d8:	50                   	push   %eax
   138d9:	e8 f3 05 00 00       	call   13ed1 <pcb_queue_insert>
   138de:	83 c4 10             	add    $0x10,%esp
   138e1:	89 45 f4             	mov    %eax,-0xc(%ebp)

		// if that failed, we're in trouble
		if( status != SUCCESS ) {
   138e4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   138e8:	74 54                	je     1393e <pcb_free+0x87>
			sprint( b256, "pcb_free(0x%08x) status %d", (uint32_t) pcb,
   138ea:	8b 45 08             	mov    0x8(%ebp),%eax
   138ed:	ff 75 f4             	pushl  -0xc(%ebp)
   138f0:	50                   	push   %eax
   138f1:	68 1e b0 01 00       	push   $0x1b01e
   138f6:	68 00 f2 01 00       	push   $0x1f200
   138fb:	e8 e2 ed ff ff       	call   126e2 <sprint>
   13900:	83 c4 10             	add    $0x10,%esp
					status );
			PANIC( 0, b256 );
   13903:	83 ec 04             	sub    $0x4,%esp
   13906:	68 39 b0 01 00       	push   $0x1b039
   1390b:	6a 00                	push   $0x0
   1390d:	68 13 01 00 00       	push   $0x113
   13912:	68 17 af 01 00       	push   $0x1af17
   13917:	68 c4 b3 01 00       	push   $0x1b3c4
   1391c:	68 1f af 01 00       	push   $0x1af1f
   13921:	68 00 f0 01 00       	push   $0x1f000
   13926:	e8 b7 ed ff ff       	call   126e2 <sprint>
   1392b:	83 c4 20             	add    $0x20,%esp
   1392e:	83 ec 0c             	sub    $0xc,%esp
   13931:	68 00 f0 01 00       	push   $0x1f000
   13936:	e8 27 eb ff ff       	call   12462 <kpanic>
   1393b:	83 c4 10             	add    $0x10,%esp
		}
	}
}
   1393e:	90                   	nop
   1393f:	c9                   	leave  
   13940:	c3                   	ret    

00013941 <pcb_stack_alloc>:
**
** @param size   Desired size (in pages, or 0 to get the default size
**
** @return pointer to the allocated space, or NULL
*/
uint32_t *pcb_stack_alloc( uint32_t size ) {
   13941:	55                   	push   %ebp
   13942:	89 e5                	mov    %esp,%ebp
   13944:	83 ec 18             	sub    $0x18,%esp

#if TRACING_STACK
	cio_printf( "stack alloc, %u", size );
#endif
	// do we have a desired size?
	if( size == 0 ) {
   13947:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1394b:	75 07                	jne    13954 <pcb_stack_alloc+0x13>
		// no, so use the default
		size = N_USTKPAGES;
   1394d:	c7 45 08 02 00 00 00 	movl   $0x2,0x8(%ebp)
	}

	uint32_t *ptr = (uint32_t *) km_page_alloc( size );
   13954:	83 ec 0c             	sub    $0xc,%esp
   13957:	ff 75 08             	pushl  0x8(%ebp)
   1395a:	e8 ce f4 ff ff       	call   12e2d <km_page_alloc>
   1395f:	83 c4 10             	add    $0x10,%esp
   13962:	89 45 f4             	mov    %eax,-0xc(%ebp)
#if TRACING_STACK
	cio_printf( " --> %08x\n", (uint32_t) ptr );
#endif
	if( ptr ) {
   13965:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   13969:	74 15                	je     13980 <pcb_stack_alloc+0x3f>
		// clear out the allocated space
		memclr( ptr, size * SZ_PAGE );
   1396b:	8b 45 08             	mov    0x8(%ebp),%eax
   1396e:	c1 e0 0c             	shl    $0xc,%eax
   13971:	83 ec 08             	sub    $0x8,%esp
   13974:	50                   	push   %eax
   13975:	ff 75 f4             	pushl  -0xc(%ebp)
   13978:	e8 e2 eb ff ff       	call   1255f <memclr>
   1397d:	83 c4 10             	add    $0x10,%esp
	}

	return ptr;
   13980:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   13983:	c9                   	leave  
   13984:	c3                   	ret    

00013985 <pcb_stack_free>:
** Dellocate space for a stack
**
** @param stk    Pointer to the stack
** @param size   Allocation size (in pages, or 0 for the default size
*/
void pcb_stack_free( uint32_t *stk, uint32_t size ) {
   13985:	55                   	push   %ebp
   13986:	89 e5                	mov    %esp,%ebp
   13988:	83 ec 08             	sub    $0x8,%esp

#if TRACING_STACK
	cio_printf( "stack free, %08x %u\n", (uint32_t) stk, size );
#endif

	assert( stk != NULL );
   1398b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1398f:	75 3b                	jne    139cc <pcb_stack_free+0x47>
   13991:	83 ec 04             	sub    $0x4,%esp
   13994:	68 3e b0 01 00       	push   $0x1b03e
   13999:	6a 00                	push   $0x0
   1399b:	68 46 01 00 00       	push   $0x146
   139a0:	68 17 af 01 00       	push   $0x1af17
   139a5:	68 d0 b3 01 00       	push   $0x1b3d0
   139aa:	68 1f af 01 00       	push   $0x1af1f
   139af:	68 00 f0 01 00       	push   $0x1f000
   139b4:	e8 29 ed ff ff       	call   126e2 <sprint>
   139b9:	83 c4 20             	add    $0x20,%esp
   139bc:	83 ec 0c             	sub    $0xc,%esp
   139bf:	68 00 f0 01 00       	push   $0x1f000
   139c4:	e8 99 ea ff ff       	call   12462 <kpanic>
   139c9:	83 c4 10             	add    $0x10,%esp

	// do we have an alternate size?
	if( size == 0 ) {
   139cc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   139d0:	75 07                	jne    139d9 <pcb_stack_free+0x54>
		// no, so use the default
		size = N_USTKPAGES;
   139d2:	c7 45 0c 02 00 00 00 	movl   $0x2,0xc(%ebp)
	}

	// send it back to the pool
	km_page_free_multi( (void *)stk, size );
   139d9:	83 ec 08             	sub    $0x8,%esp
   139dc:	ff 75 0c             	pushl  0xc(%ebp)
   139df:	ff 75 08             	pushl  0x8(%ebp)
   139e2:	e8 6c f5 ff ff       	call   12f53 <km_page_free_multi>
   139e7:	83 c4 10             	add    $0x10,%esp
}
   139ea:	90                   	nop
   139eb:	c9                   	leave  
   139ec:	c3                   	ret    

000139ed <pcb_zombify>:
** does most of the real work for exit() and kill() calls.
** Is also called from the scheduler and dispatcher.
**
** @param pcb   Pointer to the newly-undead PCB
*/
void pcb_zombify( register pcb_t *victim ) {
   139ed:	55                   	push   %ebp
   139ee:	89 e5                	mov    %esp,%ebp
   139f0:	56                   	push   %esi
   139f1:	53                   	push   %ebx
   139f2:	83 ec 20             	sub    $0x20,%esp
   139f5:	8b 5d 08             	mov    0x8(%ebp),%ebx

	// should this be an error?
	if( victim == NULL ) {
   139f8:	85 db                	test   %ebx,%ebx
   139fa:	0f 84 79 02 00 00    	je     13c79 <pcb_zombify+0x28c>
		return;
	}

	// every process must have a parent, even if it's 'init'
	assert( victim->parent != NULL );
   13a00:	8b 43 0c             	mov    0xc(%ebx),%eax
   13a03:	85 c0                	test   %eax,%eax
   13a05:	75 3b                	jne    13a42 <pcb_zombify+0x55>
   13a07:	83 ec 04             	sub    $0x4,%esp
   13a0a:	68 47 b0 01 00       	push   $0x1b047
   13a0f:	6a 00                	push   $0x0
   13a11:	68 63 01 00 00       	push   $0x163
   13a16:	68 17 af 01 00       	push   $0x1af17
   13a1b:	68 e0 b3 01 00       	push   $0x1b3e0
   13a20:	68 1f af 01 00       	push   $0x1af1f
   13a25:	68 00 f0 01 00       	push   $0x1f000
   13a2a:	e8 b3 ec ff ff       	call   126e2 <sprint>
   13a2f:	83 c4 20             	add    $0x20,%esp
   13a32:	83 ec 0c             	sub    $0xc,%esp
   13a35:	68 00 f0 01 00       	push   $0x1f000
   13a3a:	e8 23 ea ff ff       	call   12462 <kpanic>
   13a3f:	83 c4 10             	add    $0x10,%esp
	/*
	** We need to locate the parent of this process.  We also need
	** to reparent any children of this process.  We do these in
	** a single loop.
	*/
	pcb_t *parent = victim->parent;
   13a42:	8b 43 0c             	mov    0xc(%ebx),%eax
   13a45:	89 45 ec             	mov    %eax,-0x14(%ebp)
	pcb_t *zchild = NULL;
   13a48:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// two PIDs we will look for
	uint_t vicpid = victim->pid;
   13a4f:	8b 43 18             	mov    0x18(%ebx),%eax
   13a52:	89 45 e8             	mov    %eax,-0x18(%ebp)

	// speed up access to the process table entries
	register pcb_t *curr = ptable;
   13a55:	be 20 10 02 00       	mov    $0x21020,%esi

	for( int i = 0; i < N_PROCS; ++i, ++curr ) {
   13a5a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   13a61:	eb 33                	jmp    13a96 <pcb_zombify+0xa9>

		// make sure this is a valid entry
		if( curr->state == STATE_UNUSED ) {
   13a63:	8b 46 1c             	mov    0x1c(%esi),%eax
   13a66:	85 c0                	test   %eax,%eax
   13a68:	74 21                	je     13a8b <pcb_zombify+0x9e>
			continue;
		}

		// if this is our parent, just keep going - we continue
		// iterating to find all the children of this process.
		if( curr == parent ) {
   13a6a:	3b 75 ec             	cmp    -0x14(%ebp),%esi
   13a6d:	74 1f                	je     13a8e <pcb_zombify+0xa1>
			continue;
		}

		if( curr->parent == victim ) {
   13a6f:	8b 46 0c             	mov    0xc(%esi),%eax
   13a72:	39 c3                	cmp    %eax,%ebx
   13a74:	75 19                	jne    13a8f <pcb_zombify+0xa2>

			// found a child - reparent it
			curr->parent = init_pcb;
   13a76:	a1 0c 10 02 00       	mov    0x2100c,%eax
   13a7b:	89 46 0c             	mov    %eax,0xc(%esi)

			// see if this child is already undead
			if( curr->state == STATE_ZOMBIE ) {
   13a7e:	8b 46 1c             	mov    0x1c(%esi),%eax
   13a81:	83 f8 08             	cmp    $0x8,%eax
   13a84:	75 09                	jne    13a8f <pcb_zombify+0xa2>
				// if it's already a zombie, remember it, so we
				// can pass it on to 'init'; also, if there are
				// two or more zombie children, it doesn't matter
				// which one we pick here, as the others will be
				// collected when 'init' loops
				zchild = curr;
   13a86:	89 75 f4             	mov    %esi,-0xc(%ebp)
   13a89:	eb 04                	jmp    13a8f <pcb_zombify+0xa2>
			continue;
   13a8b:	90                   	nop
   13a8c:	eb 01                	jmp    13a8f <pcb_zombify+0xa2>
			continue;
   13a8e:	90                   	nop
	for( int i = 0; i < N_PROCS; ++i, ++curr ) {
   13a8f:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   13a93:	83 c6 30             	add    $0x30,%esi
   13a96:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   13a9a:	7e c7                	jle    13a63 <pcb_zombify+0x76>
	** existing process itself is cleaned up by init. This will work,
	** because after init cleans up the zombie, it will loop and
	** call waitpid() again, by which time this exiting process will
	** be marked as a zombie.
	*/
	if( zchild != NULL && init_pcb->state == STATE_WAITING ) {
   13a9c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   13aa0:	0f 84 0d 01 00 00    	je     13bb3 <pcb_zombify+0x1c6>
   13aa6:	a1 0c 10 02 00       	mov    0x2100c,%eax
   13aab:	8b 40 1c             	mov    0x1c(%eax),%eax
   13aae:	83 f8 06             	cmp    $0x6,%eax
   13ab1:	0f 85 fc 00 00 00    	jne    13bb3 <pcb_zombify+0x1c6>

		// dequeue the zombie
		assert( pcb_queue_remove_this(zombie,zchild) == SUCCESS );
   13ab7:	a1 18 10 02 00       	mov    0x21018,%eax
   13abc:	83 ec 08             	sub    $0x8,%esp
   13abf:	ff 75 f4             	pushl  -0xc(%ebp)
   13ac2:	50                   	push   %eax
   13ac3:	e8 c6 06 00 00       	call   1418e <pcb_queue_remove_this>
   13ac8:	83 c4 10             	add    $0x10,%esp
   13acb:	85 c0                	test   %eax,%eax
   13acd:	74 3b                	je     13b0a <pcb_zombify+0x11d>
   13acf:	83 ec 04             	sub    $0x4,%esp
   13ad2:	68 5c b0 01 00       	push   $0x1b05c
   13ad7:	6a 00                	push   $0x0
   13ad9:	68 a5 01 00 00       	push   $0x1a5
   13ade:	68 17 af 01 00       	push   $0x1af17
   13ae3:	68 e0 b3 01 00       	push   $0x1b3e0
   13ae8:	68 1f af 01 00       	push   $0x1af1f
   13aed:	68 00 f0 01 00       	push   $0x1f000
   13af2:	e8 eb eb ff ff       	call   126e2 <sprint>
   13af7:	83 c4 20             	add    $0x20,%esp
   13afa:	83 ec 0c             	sub    $0xc,%esp
   13afd:	68 00 f0 01 00       	push   $0x1f000
   13b02:	e8 5b e9 ff ff       	call   12462 <kpanic>
   13b07:	83 c4 10             	add    $0x10,%esp

		assert( pcb_queue_remove_this(waiting,init_pcb) == SUCCESS );
   13b0a:	8b 15 0c 10 02 00    	mov    0x2100c,%edx
   13b10:	a1 10 10 02 00       	mov    0x21010,%eax
   13b15:	83 ec 08             	sub    $0x8,%esp
   13b18:	52                   	push   %edx
   13b19:	50                   	push   %eax
   13b1a:	e8 6f 06 00 00       	call   1418e <pcb_queue_remove_this>
   13b1f:	83 c4 10             	add    $0x10,%esp
   13b22:	85 c0                	test   %eax,%eax
   13b24:	74 3b                	je     13b61 <pcb_zombify+0x174>
   13b26:	83 ec 04             	sub    $0x4,%esp
   13b29:	68 88 b0 01 00       	push   $0x1b088
   13b2e:	6a 00                	push   $0x0
   13b30:	68 a7 01 00 00       	push   $0x1a7
   13b35:	68 17 af 01 00       	push   $0x1af17
   13b3a:	68 e0 b3 01 00       	push   $0x1b3e0
   13b3f:	68 1f af 01 00       	push   $0x1af1f
   13b44:	68 00 f0 01 00       	push   $0x1f000
   13b49:	e8 94 eb ff ff       	call   126e2 <sprint>
   13b4e:	83 c4 20             	add    $0x20,%esp
   13b51:	83 ec 0c             	sub    $0xc,%esp
   13b54:	68 00 f0 01 00       	push   $0x1f000
   13b59:	e8 04 e9 ff ff       	call   12462 <kpanic>
   13b5e:	83 c4 10             	add    $0x10,%esp

		// intrinsic return value is the PID
		RET(init_pcb) = zchild->pid;
   13b61:	a1 0c 10 02 00       	mov    0x2100c,%eax
   13b66:	8b 00                	mov    (%eax),%eax
   13b68:	8b 55 f4             	mov    -0xc(%ebp),%edx
   13b6b:	8b 52 18             	mov    0x18(%edx),%edx
   13b6e:	89 50 30             	mov    %edx,0x30(%eax)

		// may also want to return the exit status
		int32_t *ptr = (int32_t *) ARG(init_pcb,2);
   13b71:	a1 0c 10 02 00       	mov    0x2100c,%eax
   13b76:	8b 00                	mov    (%eax),%eax
   13b78:	83 c0 48             	add    $0x48,%eax
   13b7b:	83 c0 08             	add    $0x8,%eax
   13b7e:	8b 00                	mov    (%eax),%eax
   13b80:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		if( ptr != NULL ) {
   13b83:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   13b87:	74 0b                	je     13b94 <pcb_zombify+0x1a7>
			// ** This works in the baseline because we aren't using
			// ** any type of memory protection.  If address space
			// ** separation is implemented, this code will very likely
			// ** STOP WORKING, and will need to be fixed.
			// ********************************************************
			*ptr = zchild->exit_status;
   13b89:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13b8c:	8b 50 14             	mov    0x14(%eax),%edx
   13b8f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   13b92:	89 10                	mov    %edx,(%eax)
		}

		// all done - schedule 'init', and clean up the zombie
		schedule( init_pcb );
   13b94:	a1 0c 10 02 00       	mov    0x2100c,%eax
   13b99:	83 ec 0c             	sub    $0xc,%esp
   13b9c:	50                   	push   %eax
   13b9d:	e8 08 08 00 00       	call   143aa <schedule>
   13ba2:	83 c4 10             	add    $0x10,%esp
		pcb_cleanup( zchild );
   13ba5:	83 ec 0c             	sub    $0xc,%esp
   13ba8:	ff 75 f4             	pushl  -0xc(%ebp)
   13bab:	e8 d1 00 00 00       	call   13c81 <pcb_cleanup>
   13bb0:	83 c4 10             	add    $0x10,%esp
	** init up to deal with a zombie child of the exiting process,
	** init's status won't be Waiting any more, so we don't have to
	** worry about it being scheduled twice.
	*/

	if( parent->state == STATE_WAITING ) {
   13bb3:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13bb6:	8b 40 1c             	mov    0x1c(%eax),%eax
   13bb9:	83 f8 06             	cmp    $0x6,%eax
   13bbc:	75 61                	jne    13c1f <pcb_zombify+0x232>

		// verify that the parent is either waiting for this process
		// or is waiting for any of its children
		uint32_t target = ARG(parent,1);
   13bbe:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13bc1:	8b 00                	mov    (%eax),%eax
   13bc3:	83 c0 48             	add    $0x48,%eax
   13bc6:	8b 40 04             	mov    0x4(%eax),%eax
   13bc9:	89 45 e0             	mov    %eax,-0x20(%ebp)

		if( target == 0 || target == vicpid ) {
   13bcc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   13bd0:	74 08                	je     13bda <pcb_zombify+0x1ed>
   13bd2:	8b 45 e0             	mov    -0x20(%ebp),%eax
   13bd5:	3b 45 e8             	cmp    -0x18(%ebp),%eax
   13bd8:	75 45                	jne    13c1f <pcb_zombify+0x232>

			// the parent is waiting for this child or is waiting
			// for any of its children, so we can wake it up.

			// intrinsic return value is the PID
			RET(parent) = vicpid;
   13bda:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13bdd:	8b 00                	mov    (%eax),%eax
   13bdf:	8b 55 e8             	mov    -0x18(%ebp),%edx
   13be2:	89 50 30             	mov    %edx,0x30(%eax)

			// may also want to return the exit status
			int32_t *ptr = (int32_t *) ARG(parent,2);
   13be5:	8b 45 ec             	mov    -0x14(%ebp),%eax
   13be8:	8b 00                	mov    (%eax),%eax
   13bea:	83 c0 48             	add    $0x48,%eax
   13bed:	83 c0 08             	add    $0x8,%eax
   13bf0:	8b 00                	mov    (%eax),%eax
   13bf2:	89 45 dc             	mov    %eax,-0x24(%ebp)

			if( ptr != NULL ) {
   13bf5:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   13bf9:	74 08                	je     13c03 <pcb_zombify+0x216>
				// ** This works in the baseline because we aren't using
				// ** any type of memory protection.  If address space
				// ** separation is implemented, this code will very likely
				// ** STOP WORKING, and will need to be fixed.
				// ********************************************************
				*ptr = victim->exit_status;
   13bfb:	8b 53 14             	mov    0x14(%ebx),%edx
   13bfe:	8b 45 dc             	mov    -0x24(%ebp),%eax
   13c01:	89 10                	mov    %edx,(%eax)
			}

			// all done - schedule the parent, and clean up the zombie
			schedule( parent );
   13c03:	83 ec 0c             	sub    $0xc,%esp
   13c06:	ff 75 ec             	pushl  -0x14(%ebp)
   13c09:	e8 9c 07 00 00       	call   143aa <schedule>
   13c0e:	83 c4 10             	add    $0x10,%esp
			pcb_cleanup( victim );
   13c11:	83 ec 0c             	sub    $0xc,%esp
   13c14:	53                   	push   %ebx
   13c15:	e8 67 00 00 00       	call   13c81 <pcb_cleanup>
   13c1a:	83 c4 10             	add    $0x10,%esp

			return;
   13c1d:	eb 5b                	jmp    13c7a <pcb_zombify+0x28d>
	** a state of 'Zombie'.  This simplifies life immensely,
	** because we won't need to dequeue it when it is collected
	** by its parent.
	*/

	victim->state = STATE_ZOMBIE;
   13c1f:	c7 43 1c 08 00 00 00 	movl   $0x8,0x1c(%ebx)
	assert( pcb_queue_insert(zombie,victim) == SUCCESS );
   13c26:	a1 18 10 02 00       	mov    0x21018,%eax
   13c2b:	83 ec 08             	sub    $0x8,%esp
   13c2e:	53                   	push   %ebx
   13c2f:	50                   	push   %eax
   13c30:	e8 9c 02 00 00       	call   13ed1 <pcb_queue_insert>
   13c35:	83 c4 10             	add    $0x10,%esp
   13c38:	85 c0                	test   %eax,%eax
   13c3a:	74 3e                	je     13c7a <pcb_zombify+0x28d>
   13c3c:	83 ec 04             	sub    $0x4,%esp
   13c3f:	68 b8 b0 01 00       	push   $0x1b0b8
   13c44:	6a 00                	push   $0x0
   13c46:	68 fc 01 00 00       	push   $0x1fc
   13c4b:	68 17 af 01 00       	push   $0x1af17
   13c50:	68 e0 b3 01 00       	push   $0x1b3e0
   13c55:	68 1f af 01 00       	push   $0x1af1f
   13c5a:	68 00 f0 01 00       	push   $0x1f000
   13c5f:	e8 7e ea ff ff       	call   126e2 <sprint>
   13c64:	83 c4 20             	add    $0x20,%esp
   13c67:	83 ec 0c             	sub    $0xc,%esp
   13c6a:	68 00 f0 01 00       	push   $0x1f000
   13c6f:	e8 ee e7 ff ff       	call   12462 <kpanic>
   13c74:	83 c4 10             	add    $0x10,%esp
   13c77:	eb 01                	jmp    13c7a <pcb_zombify+0x28d>
		return;
   13c79:	90                   	nop
	/*
	** Note: we don't call _dispatch() here - we leave that for
	** the calling routine, as it's possible we don't need to
	** choose a new current process.
	*/
}
   13c7a:	8d 65 f8             	lea    -0x8(%ebp),%esp
   13c7d:	5b                   	pop    %ebx
   13c7e:	5e                   	pop    %esi
   13c7f:	5d                   	pop    %ebp
   13c80:	c3                   	ret    

00013c81 <pcb_cleanup>:
**
** Reclaim a process' data structures
**
** @param pcb   The PCB to reclaim
*/
void pcb_cleanup( pcb_t *pcb ) {
   13c81:	55                   	push   %ebp
   13c82:	89 e5                	mov    %esp,%ebp
   13c84:	83 ec 08             	sub    $0x8,%esp
#if TRACING_PCB
	cio_printf( "** pcb_cleanup(0x%08x)\n", (uint32_t) pcb );
#endif

	// avoid deallocating a NULL pointer
	if( pcb == NULL ) {
   13c87:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13c8b:	74 1e                	je     13cab <pcb_cleanup+0x2a>
		// should this be an error?
		return;
	}

	// we need to release all the VM data structures and frames
	user_cleanup( pcb );
   13c8d:	83 ec 0c             	sub    $0xc,%esp
   13c90:	ff 75 08             	pushl  0x8(%ebp)
   13c93:	e8 bd 30 00 00       	call   16d55 <user_cleanup>
   13c98:	83 c4 10             	add    $0x10,%esp

	// release the PCB itself
	pcb_free( pcb );
   13c9b:	83 ec 0c             	sub    $0xc,%esp
   13c9e:	ff 75 08             	pushl  0x8(%ebp)
   13ca1:	e8 11 fc ff ff       	call   138b7 <pcb_free>
   13ca6:	83 c4 10             	add    $0x10,%esp
   13ca9:	eb 01                	jmp    13cac <pcb_cleanup+0x2b>
		return;
   13cab:	90                   	nop
}
   13cac:	c9                   	leave  
   13cad:	c3                   	ret    

00013cae <pcb_find_pid>:
**
** @param pid   The PID to be located
**
** @return Pointer to the PCB, or NULL
*/
pcb_t *pcb_find_pid( uint_t pid ) {
   13cae:	55                   	push   %ebp
   13caf:	89 e5                	mov    %esp,%ebp
   13cb1:	83 ec 10             	sub    $0x10,%esp

	// must be a valid PID
	if( pid < 1 ) {
   13cb4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13cb8:	75 07                	jne    13cc1 <pcb_find_pid+0x13>
		return NULL;
   13cba:	b8 00 00 00 00       	mov    $0x0,%eax
   13cbf:	eb 3d                	jmp    13cfe <pcb_find_pid+0x50>
	}

	// scan the process table
	pcb_t *p = ptable;
   13cc1:	c7 45 fc 20 10 02 00 	movl   $0x21020,-0x4(%ebp)

	for( int i = 0; i < N_PROCS; ++i, ++p ) {
   13cc8:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
   13ccf:	eb 22                	jmp    13cf3 <pcb_find_pid+0x45>
		if( p->pid == pid && p->state != STATE_UNUSED ) {
   13cd1:	8b 45 fc             	mov    -0x4(%ebp),%eax
   13cd4:	8b 40 18             	mov    0x18(%eax),%eax
   13cd7:	39 45 08             	cmp    %eax,0x8(%ebp)
   13cda:	75 0f                	jne    13ceb <pcb_find_pid+0x3d>
   13cdc:	8b 45 fc             	mov    -0x4(%ebp),%eax
   13cdf:	8b 40 1c             	mov    0x1c(%eax),%eax
   13ce2:	85 c0                	test   %eax,%eax
   13ce4:	74 05                	je     13ceb <pcb_find_pid+0x3d>
			return p;
   13ce6:	8b 45 fc             	mov    -0x4(%ebp),%eax
   13ce9:	eb 13                	jmp    13cfe <pcb_find_pid+0x50>
	for( int i = 0; i < N_PROCS; ++i, ++p ) {
   13ceb:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
   13cef:	83 45 fc 30          	addl   $0x30,-0x4(%ebp)
   13cf3:	83 7d f8 18          	cmpl   $0x18,-0x8(%ebp)
   13cf7:	7e d8                	jle    13cd1 <pcb_find_pid+0x23>
		}
	}

	// didn't find it!
	return NULL;
   13cf9:	b8 00 00 00 00       	mov    $0x0,%eax
}
   13cfe:	c9                   	leave  
   13cff:	c3                   	ret    

00013d00 <pcb_find_ppid>:
**
** @param pid   The PID to be located
**
** @return Pointer to the PCB, or NULL
*/
pcb_t *pcb_find_ppid( uint_t pid ) {
   13d00:	55                   	push   %ebp
   13d01:	89 e5                	mov    %esp,%ebp
   13d03:	83 ec 18             	sub    $0x18,%esp

	// must be a valid PID
	if( pid < 1 ) {
   13d06:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13d0a:	75 0a                	jne    13d16 <pcb_find_ppid+0x16>
		return NULL;
   13d0c:	b8 00 00 00 00       	mov    $0x0,%eax
   13d11:	e9 88 00 00 00       	jmp    13d9e <pcb_find_ppid+0x9e>
	}

	// scan the process table
	pcb_t *p = ptable;
   13d16:	c7 45 f4 20 10 02 00 	movl   $0x21020,-0xc(%ebp)

	for( int i = 0; i < N_PROCS; ++i, ++p ) {
   13d1d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   13d24:	eb 6d                	jmp    13d93 <pcb_find_ppid+0x93>
		assert1( p->parent != NULL );
   13d26:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13d29:	8b 40 0c             	mov    0xc(%eax),%eax
   13d2c:	85 c0                	test   %eax,%eax
   13d2e:	75 3b                	jne    13d6b <pcb_find_ppid+0x6b>
   13d30:	83 ec 04             	sub    $0x4,%esp
   13d33:	68 df b0 01 00       	push   $0x1b0df
   13d38:	6a 01                	push   $0x1
   13d3a:	68 50 02 00 00       	push   $0x250
   13d3f:	68 17 af 01 00       	push   $0x1af17
   13d44:	68 ec b3 01 00       	push   $0x1b3ec
   13d49:	68 1f af 01 00       	push   $0x1af1f
   13d4e:	68 00 f0 01 00       	push   $0x1f000
   13d53:	e8 8a e9 ff ff       	call   126e2 <sprint>
   13d58:	83 c4 20             	add    $0x20,%esp
   13d5b:	83 ec 0c             	sub    $0xc,%esp
   13d5e:	68 00 f0 01 00       	push   $0x1f000
   13d63:	e8 fa e6 ff ff       	call   12462 <kpanic>
   13d68:	83 c4 10             	add    $0x10,%esp
		if( p->parent->pid == pid && p->parent->state != STATE_UNUSED ) {
   13d6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13d6e:	8b 40 0c             	mov    0xc(%eax),%eax
   13d71:	8b 40 18             	mov    0x18(%eax),%eax
   13d74:	39 45 08             	cmp    %eax,0x8(%ebp)
   13d77:	75 12                	jne    13d8b <pcb_find_ppid+0x8b>
   13d79:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13d7c:	8b 40 0c             	mov    0xc(%eax),%eax
   13d7f:	8b 40 1c             	mov    0x1c(%eax),%eax
   13d82:	85 c0                	test   %eax,%eax
   13d84:	74 05                	je     13d8b <pcb_find_ppid+0x8b>
			return p;
   13d86:	8b 45 f4             	mov    -0xc(%ebp),%eax
   13d89:	eb 13                	jmp    13d9e <pcb_find_ppid+0x9e>
	for( int i = 0; i < N_PROCS; ++i, ++p ) {
   13d8b:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   13d8f:	83 45 f4 30          	addl   $0x30,-0xc(%ebp)
   13d93:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   13d97:	7e 8d                	jle    13d26 <pcb_find_ppid+0x26>
		}
	}

	// didn't find it!
	return NULL;
   13d99:	b8 00 00 00 00       	mov    $0x0,%eax
}
   13d9e:	c9                   	leave  
   13d9f:	c3                   	ret    

00013da0 <pcb_queue_reset>:
** @param queue[out]  The queue to be initialized
** @param order[in]   The desired ordering for the queue
**
** @return status of the init request
*/
int pcb_queue_reset( pcb_queue_t queue, enum pcb_queue_order_e style ) {
   13da0:	55                   	push   %ebp
   13da1:	89 e5                	mov    %esp,%ebp
   13da3:	83 ec 08             	sub    $0x8,%esp

	// sanity check
	assert1( queue != NULL );
   13da6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13daa:	75 3b                	jne    13de7 <pcb_queue_reset+0x47>
   13dac:	83 ec 04             	sub    $0x4,%esp
   13daf:	68 0c af 01 00       	push   $0x1af0c
   13db4:	6a 01                	push   $0x1
   13db6:	68 68 02 00 00       	push   $0x268
   13dbb:	68 17 af 01 00       	push   $0x1af17
   13dc0:	68 fc b3 01 00       	push   $0x1b3fc
   13dc5:	68 1f af 01 00       	push   $0x1af1f
   13dca:	68 00 f0 01 00       	push   $0x1f000
   13dcf:	e8 0e e9 ff ff       	call   126e2 <sprint>
   13dd4:	83 c4 20             	add    $0x20,%esp
   13dd7:	83 ec 0c             	sub    $0xc,%esp
   13dda:	68 00 f0 01 00       	push   $0x1f000
   13ddf:	e8 7e e6 ff ff       	call   12462 <kpanic>
   13de4:	83 c4 10             	add    $0x10,%esp

	// make sure the style is valid
	if( style < O_FIRST_STYLE || style > O_LAST_STYLE ) {
   13de7:	83 7d 0c 03          	cmpl   $0x3,0xc(%ebp)
   13deb:	76 07                	jbe    13df4 <pcb_queue_reset+0x54>
		return E_BAD_PARAM;
   13ded:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
   13df2:	eb 23                	jmp    13e17 <pcb_queue_reset+0x77>
	}

	// reset the queue
	queue->head = queue->tail = NULL;
   13df4:	8b 45 08             	mov    0x8(%ebp),%eax
   13df7:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
   13dfe:	8b 45 08             	mov    0x8(%ebp),%eax
   13e01:	8b 50 04             	mov    0x4(%eax),%edx
   13e04:	8b 45 08             	mov    0x8(%ebp),%eax
   13e07:	89 10                	mov    %edx,(%eax)
	queue->order = style;
   13e09:	8b 45 08             	mov    0x8(%ebp),%eax
   13e0c:	8b 55 0c             	mov    0xc(%ebp),%edx
   13e0f:	89 50 08             	mov    %edx,0x8(%eax)

	return SUCCESS;
   13e12:	b8 00 00 00 00       	mov    $0x0,%eax
}
   13e17:	c9                   	leave  
   13e18:	c3                   	ret    

00013e19 <pcb_queue_empty>:
**
** @param[in] queue  The queue to check
**
** @return true if the queue is empty, else false
*/
bool_t pcb_queue_empty( pcb_queue_t queue ) {
   13e19:	55                   	push   %ebp
   13e1a:	89 e5                	mov    %esp,%ebp
   13e1c:	83 ec 08             	sub    $0x8,%esp

	// if there is no queue, blow up
	assert1( queue != NULL );
   13e1f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13e23:	75 3b                	jne    13e60 <pcb_queue_empty+0x47>
   13e25:	83 ec 04             	sub    $0x4,%esp
   13e28:	68 0c af 01 00       	push   $0x1af0c
   13e2d:	6a 01                	push   $0x1
   13e2f:	68 83 02 00 00       	push   $0x283
   13e34:	68 17 af 01 00       	push   $0x1af17
   13e39:	68 0c b4 01 00       	push   $0x1b40c
   13e3e:	68 1f af 01 00       	push   $0x1af1f
   13e43:	68 00 f0 01 00       	push   $0x1f000
   13e48:	e8 95 e8 ff ff       	call   126e2 <sprint>
   13e4d:	83 c4 20             	add    $0x20,%esp
   13e50:	83 ec 0c             	sub    $0xc,%esp
   13e53:	68 00 f0 01 00       	push   $0x1f000
   13e58:	e8 05 e6 ff ff       	call   12462 <kpanic>
   13e5d:	83 c4 10             	add    $0x10,%esp

	return PCB_QUEUE_EMPTY(queue);
   13e60:	8b 45 08             	mov    0x8(%ebp),%eax
   13e63:	8b 00                	mov    (%eax),%eax
   13e65:	85 c0                	test   %eax,%eax
   13e67:	0f 94 c0             	sete   %al
}
   13e6a:	c9                   	leave  
   13e6b:	c3                   	ret    

00013e6c <pcb_queue_length>:
**
** @param[in] queue  The queue to check
**
** @return the count (0 if the queue is empty)
*/
uint_t pcb_queue_length( const pcb_queue_t queue ) {
   13e6c:	55                   	push   %ebp
   13e6d:	89 e5                	mov    %esp,%ebp
   13e6f:	56                   	push   %esi
   13e70:	53                   	push   %ebx

	// sanity check
	assert1( queue != NULL );
   13e71:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13e75:	75 3b                	jne    13eb2 <pcb_queue_length+0x46>
   13e77:	83 ec 04             	sub    $0x4,%esp
   13e7a:	68 0c af 01 00       	push   $0x1af0c
   13e7f:	6a 01                	push   $0x1
   13e81:	68 94 02 00 00       	push   $0x294
   13e86:	68 17 af 01 00       	push   $0x1af17
   13e8b:	68 1c b4 01 00       	push   $0x1b41c
   13e90:	68 1f af 01 00       	push   $0x1af1f
   13e95:	68 00 f0 01 00       	push   $0x1f000
   13e9a:	e8 43 e8 ff ff       	call   126e2 <sprint>
   13e9f:	83 c4 20             	add    $0x20,%esp
   13ea2:	83 ec 0c             	sub    $0xc,%esp
   13ea5:	68 00 f0 01 00       	push   $0x1f000
   13eaa:	e8 b3 e5 ff ff       	call   12462 <kpanic>
   13eaf:	83 c4 10             	add    $0x10,%esp

	// this is pretty simple
	register pcb_t *tmp = queue->head;
   13eb2:	8b 45 08             	mov    0x8(%ebp),%eax
   13eb5:	8b 18                	mov    (%eax),%ebx
	register int num = 0;
   13eb7:	be 00 00 00 00       	mov    $0x0,%esi
	
	while( tmp != NULL ) {
   13ebc:	eb 06                	jmp    13ec4 <pcb_queue_length+0x58>
		++num;
   13ebe:	83 c6 01             	add    $0x1,%esi
		tmp = tmp->next;
   13ec1:	8b 5b 08             	mov    0x8(%ebx),%ebx
	while( tmp != NULL ) {
   13ec4:	85 db                	test   %ebx,%ebx
   13ec6:	75 f6                	jne    13ebe <pcb_queue_length+0x52>
	}

	return num;
   13ec8:	89 f0                	mov    %esi,%eax
}
   13eca:	8d 65 f8             	lea    -0x8(%ebp),%esp
   13ecd:	5b                   	pop    %ebx
   13ece:	5e                   	pop    %esi
   13ecf:	5d                   	pop    %ebp
   13ed0:	c3                   	ret    

00013ed1 <pcb_queue_insert>:
** @param queue[in,out]  The queue to be used
** @param pcb[in]        The PCB to be inserted
**
** @return status of the insertion request
*/
int pcb_queue_insert( pcb_queue_t queue, pcb_t *pcb ) {
   13ed1:	55                   	push   %ebp
   13ed2:	89 e5                	mov    %esp,%ebp
   13ed4:	83 ec 18             	sub    $0x18,%esp

	// sanity checks
	assert1( queue != NULL );
   13ed7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   13edb:	75 3b                	jne    13f18 <pcb_queue_insert+0x47>
   13edd:	83 ec 04             	sub    $0x4,%esp
   13ee0:	68 0c af 01 00       	push   $0x1af0c
   13ee5:	6a 01                	push   $0x1
   13ee7:	68 af 02 00 00       	push   $0x2af
   13eec:	68 17 af 01 00       	push   $0x1af17
   13ef1:	68 30 b4 01 00       	push   $0x1b430
   13ef6:	68 1f af 01 00       	push   $0x1af1f
   13efb:	68 00 f0 01 00       	push   $0x1f000
   13f00:	e8 dd e7 ff ff       	call   126e2 <sprint>
   13f05:	83 c4 20             	add    $0x20,%esp
   13f08:	83 ec 0c             	sub    $0xc,%esp
   13f0b:	68 00 f0 01 00       	push   $0x1f000
   13f10:	e8 4d e5 ff ff       	call   12462 <kpanic>
   13f15:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   13f18:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   13f1c:	75 3b                	jne    13f59 <pcb_queue_insert+0x88>
   13f1e:	83 ec 04             	sub    $0x4,%esp
   13f21:	68 35 af 01 00       	push   $0x1af35
   13f26:	6a 01                	push   $0x1
   13f28:	68 b0 02 00 00       	push   $0x2b0
   13f2d:	68 17 af 01 00       	push   $0x1af17
   13f32:	68 30 b4 01 00       	push   $0x1b430
   13f37:	68 1f af 01 00       	push   $0x1af1f
   13f3c:	68 00 f0 01 00       	push   $0x1f000
   13f41:	e8 9c e7 ff ff       	call   126e2 <sprint>
   13f46:	83 c4 20             	add    $0x20,%esp
   13f49:	83 ec 0c             	sub    $0xc,%esp
   13f4c:	68 00 f0 01 00       	push   $0x1f000
   13f51:	e8 0c e5 ff ff       	call   12462 <kpanic>
   13f56:	83 c4 10             	add    $0x10,%esp

	// if this PCB is already in a queue, we won't touch it
	if( pcb->next != NULL ) {
   13f59:	8b 45 0c             	mov    0xc(%ebp),%eax
   13f5c:	8b 40 08             	mov    0x8(%eax),%eax
   13f5f:	85 c0                	test   %eax,%eax
   13f61:	74 0a                	je     13f6d <pcb_queue_insert+0x9c>
		// what to do? we let the caller decide
		return E_BAD_PARAM;
   13f63:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
   13f68:	e9 48 01 00 00       	jmp    140b5 <pcb_queue_insert+0x1e4>
	}

	// is the queue empty?
	if( queue->head == NULL ) {
   13f6d:	8b 45 08             	mov    0x8(%ebp),%eax
   13f70:	8b 00                	mov    (%eax),%eax
   13f72:	85 c0                	test   %eax,%eax
   13f74:	75 1e                	jne    13f94 <pcb_queue_insert+0xc3>
		queue->head = queue->tail = pcb;
   13f76:	8b 45 08             	mov    0x8(%ebp),%eax
   13f79:	8b 55 0c             	mov    0xc(%ebp),%edx
   13f7c:	89 50 04             	mov    %edx,0x4(%eax)
   13f7f:	8b 45 08             	mov    0x8(%ebp),%eax
   13f82:	8b 50 04             	mov    0x4(%eax),%edx
   13f85:	8b 45 08             	mov    0x8(%ebp),%eax
   13f88:	89 10                	mov    %edx,(%eax)
		return SUCCESS;
   13f8a:	b8 00 00 00 00       	mov    $0x0,%eax
   13f8f:	e9 21 01 00 00       	jmp    140b5 <pcb_queue_insert+0x1e4>
	}
	assert1( queue->tail != NULL );
   13f94:	8b 45 08             	mov    0x8(%ebp),%eax
   13f97:	8b 40 04             	mov    0x4(%eax),%eax
   13f9a:	85 c0                	test   %eax,%eax
   13f9c:	75 3b                	jne    13fd9 <pcb_queue_insert+0x108>
   13f9e:	83 ec 04             	sub    $0x4,%esp
   13fa1:	68 ee b0 01 00       	push   $0x1b0ee
   13fa6:	6a 01                	push   $0x1
   13fa8:	68 bd 02 00 00       	push   $0x2bd
   13fad:	68 17 af 01 00       	push   $0x1af17
   13fb2:	68 30 b4 01 00       	push   $0x1b430
   13fb7:	68 1f af 01 00       	push   $0x1af1f
   13fbc:	68 00 f0 01 00       	push   $0x1f000
   13fc1:	e8 1c e7 ff ff       	call   126e2 <sprint>
   13fc6:	83 c4 20             	add    $0x20,%esp
   13fc9:	83 ec 0c             	sub    $0xc,%esp
   13fcc:	68 00 f0 01 00       	push   $0x1f000
   13fd1:	e8 8c e4 ff ff       	call   12462 <kpanic>
   13fd6:	83 c4 10             	add    $0x10,%esp

	// no, so we need to search it
	pcb_t *prev = NULL;
   13fd9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// find the predecessor node
	switch( queue->order ) {
   13fe0:	8b 45 08             	mov    0x8(%ebp),%eax
   13fe3:	8b 40 08             	mov    0x8(%eax),%eax
   13fe6:	83 f8 01             	cmp    $0x1,%eax
   13fe9:	74 1c                	je     14007 <pcb_queue_insert+0x136>
   13feb:	83 f8 01             	cmp    $0x1,%eax
   13fee:	72 0c                	jb     13ffc <pcb_queue_insert+0x12b>
   13ff0:	83 f8 02             	cmp    $0x2,%eax
   13ff3:	74 28                	je     1401d <pcb_queue_insert+0x14c>
   13ff5:	83 f8 03             	cmp    $0x3,%eax
   13ff8:	74 39                	je     14033 <pcb_queue_insert+0x162>
   13ffa:	eb 4d                	jmp    14049 <pcb_queue_insert+0x178>
	case O_FIFO:
		prev = queue->tail;
   13ffc:	8b 45 08             	mov    0x8(%ebp),%eax
   13fff:	8b 40 04             	mov    0x4(%eax),%eax
   14002:	89 45 f4             	mov    %eax,-0xc(%ebp)
		break;
   14005:	eb 49                	jmp    14050 <pcb_queue_insert+0x17f>
	case O_PRIO:
		prev = find_prev_priority(queue,pcb);
   14007:	83 ec 08             	sub    $0x8,%esp
   1400a:	ff 75 0c             	pushl  0xc(%ebp)
   1400d:	ff 75 08             	pushl  0x8(%ebp)
   14010:	e8 25 f4 ff ff       	call   1343a <find_prev_priority>
   14015:	83 c4 10             	add    $0x10,%esp
   14018:	89 45 f4             	mov    %eax,-0xc(%ebp)
		break;
   1401b:	eb 33                	jmp    14050 <pcb_queue_insert+0x17f>
	case O_PID:
		prev = find_prev_pid(queue,pcb);
   1401d:	83 ec 08             	sub    $0x8,%esp
   14020:	ff 75 0c             	pushl  0xc(%ebp)
   14023:	ff 75 08             	pushl  0x8(%ebp)
   14026:	e8 d2 f4 ff ff       	call   134fd <find_prev_pid>
   1402b:	83 c4 10             	add    $0x10,%esp
   1402e:	89 45 f4             	mov    %eax,-0xc(%ebp)
		break;
   14031:	eb 1d                	jmp    14050 <pcb_queue_insert+0x17f>
	case O_WAKEUP:
		prev = find_prev_wakeup(queue,pcb);
   14033:	83 ec 08             	sub    $0x8,%esp
   14036:	ff 75 0c             	pushl  0xc(%ebp)
   14039:	ff 75 08             	pushl  0x8(%ebp)
   1403c:	e8 36 f3 ff ff       	call   13377 <find_prev_wakeup>
   14041:	83 c4 10             	add    $0x10,%esp
   14044:	89 45 f4             	mov    %eax,-0xc(%ebp)
		break;
   14047:	eb 07                	jmp    14050 <pcb_queue_insert+0x17f>
	default:
		// do we need something more specific here?
		return E_BAD_PARAM;
   14049:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
   1404e:	eb 65                	jmp    140b5 <pcb_queue_insert+0x1e4>
	}

	// OK, we found the predecessor node; time to do the insertion

	if( prev == NULL ) {
   14050:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   14054:	75 27                	jne    1407d <pcb_queue_insert+0x1ac>

		// there is no predecessor, so we're
		// inserting at the front of the queue
		pcb->next = queue->head;
   14056:	8b 45 08             	mov    0x8(%ebp),%eax
   14059:	8b 10                	mov    (%eax),%edx
   1405b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1405e:	89 50 08             	mov    %edx,0x8(%eax)
		if( queue->head == NULL ) {
   14061:	8b 45 08             	mov    0x8(%ebp),%eax
   14064:	8b 00                	mov    (%eax),%eax
   14066:	85 c0                	test   %eax,%eax
   14068:	75 09                	jne    14073 <pcb_queue_insert+0x1a2>
			// empty queue!?! - should we panic?
			queue->tail = pcb;
   1406a:	8b 45 08             	mov    0x8(%ebp),%eax
   1406d:	8b 55 0c             	mov    0xc(%ebp),%edx
   14070:	89 50 04             	mov    %edx,0x4(%eax)
		}
		queue->head = pcb;
   14073:	8b 45 08             	mov    0x8(%ebp),%eax
   14076:	8b 55 0c             	mov    0xc(%ebp),%edx
   14079:	89 10                	mov    %edx,(%eax)
   1407b:	eb 33                	jmp    140b0 <pcb_queue_insert+0x1df>

	} else if( prev->next == NULL ) {
   1407d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   14080:	8b 40 08             	mov    0x8(%eax),%eax
   14083:	85 c0                	test   %eax,%eax
   14085:	75 14                	jne    1409b <pcb_queue_insert+0x1ca>

		// append at end
		prev->next = pcb;
   14087:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1408a:	8b 55 0c             	mov    0xc(%ebp),%edx
   1408d:	89 50 08             	mov    %edx,0x8(%eax)
		queue->tail = pcb;
   14090:	8b 45 08             	mov    0x8(%ebp),%eax
   14093:	8b 55 0c             	mov    0xc(%ebp),%edx
   14096:	89 50 04             	mov    %edx,0x4(%eax)
   14099:	eb 15                	jmp    140b0 <pcb_queue_insert+0x1df>

	} else {

		// insert between prev & prev->next
		pcb->next = prev->next;
   1409b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1409e:	8b 50 08             	mov    0x8(%eax),%edx
   140a1:	8b 45 0c             	mov    0xc(%ebp),%eax
   140a4:	89 50 08             	mov    %edx,0x8(%eax)
		prev->next = pcb;
   140a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
   140aa:	8b 55 0c             	mov    0xc(%ebp),%edx
   140ad:	89 50 08             	mov    %edx,0x8(%eax)

	}

	return SUCCESS;
   140b0:	b8 00 00 00 00       	mov    $0x0,%eax
}
   140b5:	c9                   	leave  
   140b6:	c3                   	ret    

000140b7 <pcb_queue_remove>:
** @param queue[in,out]  The queue to be used
** @param pcb[out]       Pointer to where the PCB pointer will be saved
**
** @return status of the removal request
*/
int pcb_queue_remove( pcb_queue_t queue, pcb_t **pcb ) {
   140b7:	55                   	push   %ebp
   140b8:	89 e5                	mov    %esp,%ebp
   140ba:	83 ec 18             	sub    $0x18,%esp

	//sanity checks
	assert1( queue != NULL );
   140bd:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   140c1:	75 3b                	jne    140fe <pcb_queue_remove+0x47>
   140c3:	83 ec 04             	sub    $0x4,%esp
   140c6:	68 0c af 01 00       	push   $0x1af0c
   140cb:	6a 01                	push   $0x1
   140cd:	68 00 03 00 00       	push   $0x300
   140d2:	68 17 af 01 00       	push   $0x1af17
   140d7:	68 44 b4 01 00       	push   $0x1b444
   140dc:	68 1f af 01 00       	push   $0x1af1f
   140e1:	68 00 f0 01 00       	push   $0x1f000
   140e6:	e8 f7 e5 ff ff       	call   126e2 <sprint>
   140eb:	83 c4 20             	add    $0x20,%esp
   140ee:	83 ec 0c             	sub    $0xc,%esp
   140f1:	68 00 f0 01 00       	push   $0x1f000
   140f6:	e8 67 e3 ff ff       	call   12462 <kpanic>
   140fb:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   140fe:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   14102:	75 3b                	jne    1413f <pcb_queue_remove+0x88>
   14104:	83 ec 04             	sub    $0x4,%esp
   14107:	68 35 af 01 00       	push   $0x1af35
   1410c:	6a 01                	push   $0x1
   1410e:	68 01 03 00 00       	push   $0x301
   14113:	68 17 af 01 00       	push   $0x1af17
   14118:	68 44 b4 01 00       	push   $0x1b444
   1411d:	68 1f af 01 00       	push   $0x1af1f
   14122:	68 00 f0 01 00       	push   $0x1f000
   14127:	e8 b6 e5 ff ff       	call   126e2 <sprint>
   1412c:	83 c4 20             	add    $0x20,%esp
   1412f:	83 ec 0c             	sub    $0xc,%esp
   14132:	68 00 f0 01 00       	push   $0x1f000
   14137:	e8 26 e3 ff ff       	call   12462 <kpanic>
   1413c:	83 c4 10             	add    $0x10,%esp

	// can't get anything if there's nothing to get!
	if( PCB_QUEUE_EMPTY(queue) ) {
   1413f:	8b 45 08             	mov    0x8(%ebp),%eax
   14142:	8b 00                	mov    (%eax),%eax
   14144:	85 c0                	test   %eax,%eax
   14146:	75 07                	jne    1414f <pcb_queue_remove+0x98>
		return E_EMPTY_QUEUE;
   14148:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
   1414d:	eb 3d                	jmp    1418c <pcb_queue_remove+0xd5>
	}

	// take the first entry from the queue
	pcb_t *tmp = queue->head;
   1414f:	8b 45 08             	mov    0x8(%ebp),%eax
   14152:	8b 00                	mov    (%eax),%eax
   14154:	89 45 f4             	mov    %eax,-0xc(%ebp)
	queue->head = tmp->next;
   14157:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1415a:	8b 50 08             	mov    0x8(%eax),%edx
   1415d:	8b 45 08             	mov    0x8(%ebp),%eax
   14160:	89 10                	mov    %edx,(%eax)

	// disconnect it completely
	tmp->next = NULL;
   14162:	8b 45 f4             	mov    -0xc(%ebp),%eax
   14165:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)

	// was this the last thing in the queue?
	if( queue->head == NULL ) {
   1416c:	8b 45 08             	mov    0x8(%ebp),%eax
   1416f:	8b 00                	mov    (%eax),%eax
   14171:	85 c0                	test   %eax,%eax
   14173:	75 0a                	jne    1417f <pcb_queue_remove+0xc8>
		// yes, so clear the tail pointer for consistency
		queue->tail = NULL;
   14175:	8b 45 08             	mov    0x8(%ebp),%eax
   14178:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	}

	// save the pointer
	*pcb = tmp;
   1417f:	8b 45 0c             	mov    0xc(%ebp),%eax
   14182:	8b 55 f4             	mov    -0xc(%ebp),%edx
   14185:	89 10                	mov    %edx,(%eax)

	return SUCCESS;
   14187:	b8 00 00 00 00       	mov    $0x0,%eax
}
   1418c:	c9                   	leave  
   1418d:	c3                   	ret    

0001418e <pcb_queue_remove_this>:
** @param queue[in,out]  The queue to be used
** @param pcb[in]        Pointer to the PCB to be removed
**
** @return status of the removal request
*/
int pcb_queue_remove_this( pcb_queue_t queue, pcb_t *pcb ) {
   1418e:	55                   	push   %ebp
   1418f:	89 e5                	mov    %esp,%ebp
   14191:	83 ec 18             	sub    $0x18,%esp

	//sanity checks
	assert1( queue != NULL );
   14194:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   14198:	75 3b                	jne    141d5 <pcb_queue_remove_this+0x47>
   1419a:	83 ec 04             	sub    $0x4,%esp
   1419d:	68 0c af 01 00       	push   $0x1af0c
   141a2:	6a 01                	push   $0x1
   141a4:	68 2c 03 00 00       	push   $0x32c
   141a9:	68 17 af 01 00       	push   $0x1af17
   141ae:	68 58 b4 01 00       	push   $0x1b458
   141b3:	68 1f af 01 00       	push   $0x1af1f
   141b8:	68 00 f0 01 00       	push   $0x1f000
   141bd:	e8 20 e5 ff ff       	call   126e2 <sprint>
   141c2:	83 c4 20             	add    $0x20,%esp
   141c5:	83 ec 0c             	sub    $0xc,%esp
   141c8:	68 00 f0 01 00       	push   $0x1f000
   141cd:	e8 90 e2 ff ff       	call   12462 <kpanic>
   141d2:	83 c4 10             	add    $0x10,%esp
	assert1( pcb != NULL );
   141d5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   141d9:	75 3b                	jne    14216 <pcb_queue_remove_this+0x88>
   141db:	83 ec 04             	sub    $0x4,%esp
   141de:	68 35 af 01 00       	push   $0x1af35
   141e3:	6a 01                	push   $0x1
   141e5:	68 2d 03 00 00       	push   $0x32d
   141ea:	68 17 af 01 00       	push   $0x1af17
   141ef:	68 58 b4 01 00       	push   $0x1b458
   141f4:	68 1f af 01 00       	push   $0x1af1f
   141f9:	68 00 f0 01 00       	push   $0x1f000
   141fe:	e8 df e4 ff ff       	call   126e2 <sprint>
   14203:	83 c4 20             	add    $0x20,%esp
   14206:	83 ec 0c             	sub    $0xc,%esp
   14209:	68 00 f0 01 00       	push   $0x1f000
   1420e:	e8 4f e2 ff ff       	call   12462 <kpanic>
   14213:	83 c4 10             	add    $0x10,%esp

	// can't get anything if there's nothing to get!
	if( PCB_QUEUE_EMPTY(queue) ) {
   14216:	8b 45 08             	mov    0x8(%ebp),%eax
   14219:	8b 00                	mov    (%eax),%eax
   1421b:	85 c0                	test   %eax,%eax
   1421d:	75 0a                	jne    14229 <pcb_queue_remove_this+0x9b>
		return E_EMPTY_QUEUE;
   1421f:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
   14224:	e9 21 01 00 00       	jmp    1434a <pcb_queue_remove_this+0x1bc>
	}

	// iterate through the queue until we find the desired PCB
	pcb_t *prev = NULL;
   14229:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pcb_t *curr = queue->head;
   14230:	8b 45 08             	mov    0x8(%ebp),%eax
   14233:	8b 00                	mov    (%eax),%eax
   14235:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while( curr != NULL && curr != pcb ) {
   14238:	eb 0f                	jmp    14249 <pcb_queue_remove_this+0xbb>
		prev = curr;
   1423a:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1423d:	89 45 f4             	mov    %eax,-0xc(%ebp)
		curr = curr->next;
   14240:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14243:	8b 40 08             	mov    0x8(%eax),%eax
   14246:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while( curr != NULL && curr != pcb ) {
   14249:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   1424d:	74 08                	je     14257 <pcb_queue_remove_this+0xc9>
   1424f:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14252:	3b 45 0c             	cmp    0xc(%ebp),%eax
   14255:	75 e3                	jne    1423a <pcb_queue_remove_this+0xac>
	//   3.    0    !0    !0    removing first element
	//   4.   !0     0    --    *** NOT FOUND ***
	//   5.   !0    !0     0    removing from end
	//   6.   !0    !0    !0    removing from middle

	if( curr == NULL ) {
   14257:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   1425b:	75 4b                	jne    142a8 <pcb_queue_remove_this+0x11a>
		// case 1
		assert( prev != NULL );
   1425d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   14261:	75 3b                	jne    1429e <pcb_queue_remove_this+0x110>
   14263:	83 ec 04             	sub    $0x4,%esp
   14266:	68 ff b0 01 00       	push   $0x1b0ff
   1426b:	6a 00                	push   $0x0
   1426d:	68 48 03 00 00       	push   $0x348
   14272:	68 17 af 01 00       	push   $0x1af17
   14277:	68 58 b4 01 00       	push   $0x1b458
   1427c:	68 1f af 01 00       	push   $0x1af1f
   14281:	68 00 f0 01 00       	push   $0x1f000
   14286:	e8 57 e4 ff ff       	call   126e2 <sprint>
   1428b:	83 c4 20             	add    $0x20,%esp
   1428e:	83 ec 0c             	sub    $0xc,%esp
   14291:	68 00 f0 01 00       	push   $0x1f000
   14296:	e8 c7 e1 ff ff       	call   12462 <kpanic>
   1429b:	83 c4 10             	add    $0x10,%esp
		// case 4
		return E_NOT_FOUND;
   1429e:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
   142a3:	e9 a2 00 00 00       	jmp    1434a <pcb_queue_remove_this+0x1bc>
	}

	// connect predecessor to successor
	if( prev != NULL ) {
   142a8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   142ac:	74 0e                	je     142bc <pcb_queue_remove_this+0x12e>
		// not the first element
		// cases 5 and 6
		prev->next = curr->next;
   142ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
   142b1:	8b 50 08             	mov    0x8(%eax),%edx
   142b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   142b7:	89 50 08             	mov    %edx,0x8(%eax)
   142ba:	eb 0b                	jmp    142c7 <pcb_queue_remove_this+0x139>
	} else {
		// removing first element
		// cases 2 and 3
		queue->head = curr->next;
   142bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
   142bf:	8b 50 08             	mov    0x8(%eax),%edx
   142c2:	8b 45 08             	mov    0x8(%ebp),%eax
   142c5:	89 10                	mov    %edx,(%eax)
	}

	// if this was the last node (cases 2 and 5),
	// also need to reset the tail pointer
	if( curr->next == NULL ) {
   142c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
   142ca:	8b 40 08             	mov    0x8(%eax),%eax
   142cd:	85 c0                	test   %eax,%eax
   142cf:	75 09                	jne    142da <pcb_queue_remove_this+0x14c>
		// if this was the only entry (2), prev is NULL,
		// so this works for that case, too
		queue->tail = prev;
   142d1:	8b 45 08             	mov    0x8(%ebp),%eax
   142d4:	8b 55 f4             	mov    -0xc(%ebp),%edx
   142d7:	89 50 04             	mov    %edx,0x4(%eax)
	}

	// unlink current from queue
	curr->next = NULL;
   142da:	8b 45 f0             	mov    -0x10(%ebp),%eax
   142dd:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)

	// there's a possible consistancy problem here if somehow
	// one of the queue pointers is NULL and the other one
	// is not NULL

	assert1(
   142e4:	8b 45 08             	mov    0x8(%ebp),%eax
   142e7:	8b 00                	mov    (%eax),%eax
   142e9:	85 c0                	test   %eax,%eax
   142eb:	75 0a                	jne    142f7 <pcb_queue_remove_this+0x169>
   142ed:	8b 45 08             	mov    0x8(%ebp),%eax
   142f0:	8b 40 04             	mov    0x4(%eax),%eax
   142f3:	85 c0                	test   %eax,%eax
   142f5:	74 4e                	je     14345 <pcb_queue_remove_this+0x1b7>
   142f7:	8b 45 08             	mov    0x8(%ebp),%eax
   142fa:	8b 00                	mov    (%eax),%eax
   142fc:	85 c0                	test   %eax,%eax
   142fe:	74 0a                	je     1430a <pcb_queue_remove_this+0x17c>
   14300:	8b 45 08             	mov    0x8(%ebp),%eax
   14303:	8b 40 04             	mov    0x4(%eax),%eax
   14306:	85 c0                	test   %eax,%eax
   14308:	75 3b                	jne    14345 <pcb_queue_remove_this+0x1b7>
   1430a:	83 ec 04             	sub    $0x4,%esp
   1430d:	68 0c b1 01 00       	push   $0x1b10c
   14312:	6a 01                	push   $0x1
   14314:	68 6a 03 00 00       	push   $0x36a
   14319:	68 17 af 01 00       	push   $0x1af17
   1431e:	68 58 b4 01 00       	push   $0x1b458
   14323:	68 1f af 01 00       	push   $0x1af1f
   14328:	68 00 f0 01 00       	push   $0x1f000
   1432d:	e8 b0 e3 ff ff       	call   126e2 <sprint>
   14332:	83 c4 20             	add    $0x20,%esp
   14335:	83 ec 0c             	sub    $0xc,%esp
   14338:	68 00 f0 01 00       	push   $0x1f000
   1433d:	e8 20 e1 ff ff       	call   12462 <kpanic>
   14342:	83 c4 10             	add    $0x10,%esp
		(queue->head == NULL && queue->tail == NULL) ||
		(queue->head != NULL && queue->tail != NULL)
	);

	return SUCCESS;
   14345:	b8 00 00 00 00       	mov    $0x0,%eax
}
   1434a:	c9                   	leave  
   1434b:	c3                   	ret    

0001434c <pcb_queue_peek>:
**
** @param queue[in]  The queue to be used
**
** @return the PCB poiner, or NULL if the queue is empty
*/
pcb_t *pcb_queue_peek( const pcb_queue_t queue ) {
   1434c:	55                   	push   %ebp
   1434d:	89 e5                	mov    %esp,%ebp
   1434f:	83 ec 08             	sub    $0x8,%esp

	//sanity check
	assert1( queue != NULL );
   14352:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   14356:	75 3b                	jne    14393 <pcb_queue_peek+0x47>
   14358:	83 ec 04             	sub    $0x4,%esp
   1435b:	68 0c af 01 00       	push   $0x1af0c
   14360:	6a 01                	push   $0x1
   14362:	68 7c 03 00 00       	push   $0x37c
   14367:	68 17 af 01 00       	push   $0x1af17
   1436c:	68 70 b4 01 00       	push   $0x1b470
   14371:	68 1f af 01 00       	push   $0x1af1f
   14376:	68 00 f0 01 00       	push   $0x1f000
   1437b:	e8 62 e3 ff ff       	call   126e2 <sprint>
   14380:	83 c4 20             	add    $0x20,%esp
   14383:	83 ec 0c             	sub    $0xc,%esp
   14386:	68 00 f0 01 00       	push   $0x1f000
   1438b:	e8 d2 e0 ff ff       	call   12462 <kpanic>
   14390:	83 c4 10             	add    $0x10,%esp

	// can't get anything if there's nothing to get!
	if( PCB_QUEUE_EMPTY(queue) ) {
   14393:	8b 45 08             	mov    0x8(%ebp),%eax
   14396:	8b 00                	mov    (%eax),%eax
   14398:	85 c0                	test   %eax,%eax
   1439a:	75 07                	jne    143a3 <pcb_queue_peek+0x57>
		return NULL;
   1439c:	b8 00 00 00 00       	mov    $0x0,%eax
   143a1:	eb 05                	jmp    143a8 <pcb_queue_peek+0x5c>
	}

	// just return the first entry from the queue
	return queue->head;
   143a3:	8b 45 08             	mov    0x8(%ebp),%eax
   143a6:	8b 00                	mov    (%eax),%eax
}
   143a8:	c9                   	leave  
   143a9:	c3                   	ret    

000143aa <schedule>:
**
** Schedule the supplied process
**
** @param pcb   Pointer to the PCB of the process to be scheduled
*/
void schedule( pcb_t *pcb ) {
   143aa:	55                   	push   %ebp
   143ab:	89 e5                	mov    %esp,%ebp
   143ad:	83 ec 08             	sub    $0x8,%esp

	// sanity check
	assert1( pcb != NULL );
   143b0:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   143b4:	75 3b                	jne    143f1 <schedule+0x47>
   143b6:	83 ec 04             	sub    $0x4,%esp
   143b9:	68 35 af 01 00       	push   $0x1af35
   143be:	6a 01                	push   $0x1
   143c0:	68 95 03 00 00       	push   $0x395
   143c5:	68 17 af 01 00       	push   $0x1af17
   143ca:	68 80 b4 01 00       	push   $0x1b480
   143cf:	68 1f af 01 00       	push   $0x1af1f
   143d4:	68 00 f0 01 00       	push   $0x1f000
   143d9:	e8 04 e3 ff ff       	call   126e2 <sprint>
   143de:	83 c4 20             	add    $0x20,%esp
   143e1:	83 ec 0c             	sub    $0xc,%esp
   143e4:	68 00 f0 01 00       	push   $0x1f000
   143e9:	e8 74 e0 ff ff       	call   12462 <kpanic>
   143ee:	83 c4 10             	add    $0x10,%esp

	// check for a killed process
	if( pcb->state == STATE_KILLED ) {
   143f1:	8b 45 08             	mov    0x8(%ebp),%eax
   143f4:	8b 40 1c             	mov    0x1c(%eax),%eax
   143f7:	83 f8 07             	cmp    $0x7,%eax
   143fa:	75 10                	jne    1440c <schedule+0x62>
		pcb_zombify( pcb );
   143fc:	83 ec 0c             	sub    $0xc,%esp
   143ff:	ff 75 08             	pushl  0x8(%ebp)
   14402:	e8 e6 f5 ff ff       	call   139ed <pcb_zombify>
   14407:	83 c4 10             	add    $0x10,%esp
		return;
   1440a:	eb 5d                	jmp    14469 <schedule+0xbf>
	}

	// mark it as ready
	pcb->state = STATE_READY;
   1440c:	8b 45 08             	mov    0x8(%ebp),%eax
   1440f:	c7 40 1c 02 00 00 00 	movl   $0x2,0x1c(%eax)

	// add it to the ready queue
	if( pcb_queue_insert(ready,pcb) != SUCCESS ) {
   14416:	a1 d0 14 02 00       	mov    0x214d0,%eax
   1441b:	83 ec 08             	sub    $0x8,%esp
   1441e:	ff 75 08             	pushl  0x8(%ebp)
   14421:	50                   	push   %eax
   14422:	e8 aa fa ff ff       	call   13ed1 <pcb_queue_insert>
   14427:	83 c4 10             	add    $0x10,%esp
   1442a:	85 c0                	test   %eax,%eax
   1442c:	74 3b                	je     14469 <schedule+0xbf>
		PANIC( 0, "schedule insert fail" );
   1442e:	83 ec 04             	sub    $0x4,%esp
   14431:	68 5d b1 01 00       	push   $0x1b15d
   14436:	6a 00                	push   $0x0
   14438:	68 a2 03 00 00       	push   $0x3a2
   1443d:	68 17 af 01 00       	push   $0x1af17
   14442:	68 80 b4 01 00       	push   $0x1b480
   14447:	68 1f af 01 00       	push   $0x1af1f
   1444c:	68 00 f0 01 00       	push   $0x1f000
   14451:	e8 8c e2 ff ff       	call   126e2 <sprint>
   14456:	83 c4 20             	add    $0x20,%esp
   14459:	83 ec 0c             	sub    $0xc,%esp
   1445c:	68 00 f0 01 00       	push   $0x1f000
   14461:	e8 fc df ff ff       	call   12462 <kpanic>
   14466:	83 c4 10             	add    $0x10,%esp
	}
}
   14469:	c9                   	leave  
   1446a:	c3                   	ret    

0001446b <dispatch>:
/**
** dispatch()
**
** Select the next process to receive the CPU
*/
void dispatch( void ) {
   1446b:	55                   	push   %ebp
   1446c:	89 e5                	mov    %esp,%ebp
   1446e:	83 ec 18             	sub    $0x18,%esp

	// verify that there is no current process
	assert( current == NULL );
   14471:	a1 14 10 02 00       	mov    0x21014,%eax
   14476:	85 c0                	test   %eax,%eax
   14478:	74 3b                	je     144b5 <dispatch+0x4a>
   1447a:	83 ec 04             	sub    $0x4,%esp
   1447d:	68 74 b1 01 00       	push   $0x1b174
   14482:	6a 00                	push   $0x0
   14484:	68 ae 03 00 00       	push   $0x3ae
   14489:	68 17 af 01 00       	push   $0x1af17
   1448e:	68 8c b4 01 00       	push   $0x1b48c
   14493:	68 1f af 01 00       	push   $0x1af1f
   14498:	68 00 f0 01 00       	push   $0x1f000
   1449d:	e8 40 e2 ff ff       	call   126e2 <sprint>
   144a2:	83 c4 20             	add    $0x20,%esp
   144a5:	83 ec 0c             	sub    $0xc,%esp
   144a8:	68 00 f0 01 00       	push   $0x1f000
   144ad:	e8 b0 df ff ff       	call   12462 <kpanic>
   144b2:	83 c4 10             	add    $0x10,%esp

	// grab whoever is at the head of the queue
	int status = pcb_queue_remove( ready, &current );
   144b5:	a1 d0 14 02 00       	mov    0x214d0,%eax
   144ba:	83 ec 08             	sub    $0x8,%esp
   144bd:	68 14 10 02 00       	push   $0x21014
   144c2:	50                   	push   %eax
   144c3:	e8 ef fb ff ff       	call   140b7 <pcb_queue_remove>
   144c8:	83 c4 10             	add    $0x10,%esp
   144cb:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( status != SUCCESS ) {
   144ce:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   144d2:	74 53                	je     14527 <dispatch+0xbc>
		sprint( b256, "dispatch queue remove failed, code %d", status );
   144d4:	83 ec 04             	sub    $0x4,%esp
   144d7:	ff 75 f4             	pushl  -0xc(%ebp)
   144da:	68 84 b1 01 00       	push   $0x1b184
   144df:	68 00 f2 01 00       	push   $0x1f200
   144e4:	e8 f9 e1 ff ff       	call   126e2 <sprint>
   144e9:	83 c4 10             	add    $0x10,%esp
		PANIC( 0, b256 );
   144ec:	83 ec 04             	sub    $0x4,%esp
   144ef:	68 39 b0 01 00       	push   $0x1b039
   144f4:	6a 00                	push   $0x0
   144f6:	68 b4 03 00 00       	push   $0x3b4
   144fb:	68 17 af 01 00       	push   $0x1af17
   14500:	68 8c b4 01 00       	push   $0x1b48c
   14505:	68 1f af 01 00       	push   $0x1af1f
   1450a:	68 00 f0 01 00       	push   $0x1f000
   1450f:	e8 ce e1 ff ff       	call   126e2 <sprint>
   14514:	83 c4 20             	add    $0x20,%esp
   14517:	83 ec 0c             	sub    $0xc,%esp
   1451a:	68 00 f0 01 00       	push   $0x1f000
   1451f:	e8 3e df ff ff       	call   12462 <kpanic>
   14524:	83 c4 10             	add    $0x10,%esp
	}

	// set the process up for success
	current->state = STATE_RUNNING;
   14527:	a1 14 10 02 00       	mov    0x21014,%eax
   1452c:	c7 40 1c 03 00 00 00 	movl   $0x3,0x1c(%eax)
	current->ticks = QUANTUM_STANDARD;
   14533:	a1 14 10 02 00       	mov    0x21014,%eax
   14538:	c7 40 24 03 00 00 00 	movl   $0x3,0x24(%eax)
}
   1453f:	90                   	nop
   14540:	c9                   	leave  
   14541:	c3                   	ret    

00014542 <ctx_dump>:
** Dumps the contents of this process context to the console
**
** @param msg[in]   An optional message to print before the dump
** @param c[in]     The context to dump out
*/
void ctx_dump( const char *msg, register context_t *c ) {
   14542:	55                   	push   %ebp
   14543:	89 e5                	mov    %esp,%ebp
   14545:	57                   	push   %edi
   14546:	56                   	push   %esi
   14547:	53                   	push   %ebx
   14548:	83 ec 1c             	sub    $0x1c,%esp
   1454b:	8b 5d 0c             	mov    0xc(%ebp),%ebx

	// first, the message (if there is one)
	if( msg ) {
   1454e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   14552:	74 0e                	je     14562 <ctx_dump+0x20>
		cio_puts( msg );
   14554:	83 ec 0c             	sub    $0xc,%esp
   14557:	ff 75 08             	pushl  0x8(%ebp)
   1455a:	e8 4e c9 ff ff       	call   10ead <cio_puts>
   1455f:	83 c4 10             	add    $0x10,%esp
	}

	// the pointer
	cio_printf( " @ %08x:\n", (uint32_t) c );
   14562:	89 d8                	mov    %ebx,%eax
   14564:	83 ec 08             	sub    $0x8,%esp
   14567:	50                   	push   %eax
   14568:	68 aa b1 01 00       	push   $0x1b1aa
   1456d:	e8 b5 cf ff ff       	call   11527 <cio_printf>
   14572:	83 c4 10             	add    $0x10,%esp

	// if it's NULL, why did you bother calling me?
	if( c == NULL ) {
   14575:	85 db                	test   %ebx,%ebx
   14577:	75 15                	jne    1458e <ctx_dump+0x4c>
		cio_puts( " NULL???\n" );
   14579:	83 ec 0c             	sub    $0xc,%esp
   1457c:	68 b4 b1 01 00       	push   $0x1b1b4
   14581:	e8 27 c9 ff ff       	call   10ead <cio_puts>
   14586:	83 c4 10             	add    $0x10,%esp
		return;
   14589:	e9 9e 00 00 00       	jmp    1462c <ctx_dump+0xea>
	}

	// now, the contents
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
				  c->es & 0xff, c->ds & 0xff, c->cs & 0xff );
   1458e:	8b 43 40             	mov    0x40(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   14591:	0f b6 c0             	movzbl %al,%eax
   14594:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				  c->es & 0xff, c->ds & 0xff, c->cs & 0xff );
   14597:	8b 43 10             	mov    0x10(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   1459a:	0f b6 f8             	movzbl %al,%edi
				  c->es & 0xff, c->ds & 0xff, c->cs & 0xff );
   1459d:	8b 43 0c             	mov    0xc(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145a0:	0f b6 f0             	movzbl %al,%esi
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
   145a3:	8b 43 08             	mov    0x8(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145a6:	0f b6 c8             	movzbl %al,%ecx
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
   145a9:	8b 43 04             	mov    0x4(%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145ac:	0f b6 d0             	movzbl %al,%edx
				  c->ss & 0xff, c->gs & 0xff, c->fs & 0xff,
   145af:	8b 03                	mov    (%ebx),%eax
	cio_printf( "ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n",
   145b1:	0f b6 c0             	movzbl %al,%eax
   145b4:	83 ec 04             	sub    $0x4,%esp
   145b7:	ff 75 e4             	pushl  -0x1c(%ebp)
   145ba:	57                   	push   %edi
   145bb:	56                   	push   %esi
   145bc:	51                   	push   %ecx
   145bd:	52                   	push   %edx
   145be:	50                   	push   %eax
   145bf:	68 c0 b1 01 00       	push   $0x1b1c0
   145c4:	e8 5e cf ff ff       	call   11527 <cio_printf>
   145c9:	83 c4 20             	add    $0x20,%esp
	cio_printf( "  edi %08x esi %08x ebp %08x esp %08x\n",
   145cc:	8b 73 20             	mov    0x20(%ebx),%esi
   145cf:	8b 4b 1c             	mov    0x1c(%ebx),%ecx
   145d2:	8b 53 18             	mov    0x18(%ebx),%edx
   145d5:	8b 43 14             	mov    0x14(%ebx),%eax
   145d8:	83 ec 0c             	sub    $0xc,%esp
   145db:	56                   	push   %esi
   145dc:	51                   	push   %ecx
   145dd:	52                   	push   %edx
   145de:	50                   	push   %eax
   145df:	68 f4 b1 01 00       	push   $0x1b1f4
   145e4:	e8 3e cf ff ff       	call   11527 <cio_printf>
   145e9:	83 c4 20             	add    $0x20,%esp
				  c->edi, c->esi, c->ebp, c->esp );
	cio_printf( "  ebx %08x edx %08x ecx %08x eax %08x\n",
   145ec:	8b 73 30             	mov    0x30(%ebx),%esi
   145ef:	8b 4b 2c             	mov    0x2c(%ebx),%ecx
   145f2:	8b 53 28             	mov    0x28(%ebx),%edx
   145f5:	8b 43 24             	mov    0x24(%ebx),%eax
   145f8:	83 ec 0c             	sub    $0xc,%esp
   145fb:	56                   	push   %esi
   145fc:	51                   	push   %ecx
   145fd:	52                   	push   %edx
   145fe:	50                   	push   %eax
   145ff:	68 1c b2 01 00       	push   $0x1b21c
   14604:	e8 1e cf ff ff       	call   11527 <cio_printf>
   14609:	83 c4 20             	add    $0x20,%esp
				  c->ebx, c->edx, c->ecx, c->eax );
	cio_printf( "  vec %08x cod %08x eip %08x efl %08x\n",
   1460c:	8b 73 44             	mov    0x44(%ebx),%esi
   1460f:	8b 4b 3c             	mov    0x3c(%ebx),%ecx
   14612:	8b 53 38             	mov    0x38(%ebx),%edx
   14615:	8b 43 34             	mov    0x34(%ebx),%eax
   14618:	83 ec 0c             	sub    $0xc,%esp
   1461b:	56                   	push   %esi
   1461c:	51                   	push   %ecx
   1461d:	52                   	push   %edx
   1461e:	50                   	push   %eax
   1461f:	68 44 b2 01 00       	push   $0x1b244
   14624:	e8 fe ce ff ff       	call   11527 <cio_printf>
   14629:	83 c4 20             	add    $0x20,%esp
				  c->vector, c->code, c->eip, c->eflags );
}
   1462c:	8d 65 f4             	lea    -0xc(%ebp),%esp
   1462f:	5b                   	pop    %ebx
   14630:	5e                   	pop    %esi
   14631:	5f                   	pop    %edi
   14632:	5d                   	pop    %ebp
   14633:	c3                   	ret    

00014634 <ctx_dump_all>:
**
** dump the process context for all active processes
**
** @param msg[in]  Optional message to print
*/
void ctx_dump_all( const char *msg ) {
   14634:	55                   	push   %ebp
   14635:	89 e5                	mov    %esp,%ebp
   14637:	53                   	push   %ebx
   14638:	83 ec 14             	sub    $0x14,%esp

	if( msg != NULL ) {
   1463b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1463f:	74 0e                	je     1464f <ctx_dump_all+0x1b>
		cio_puts( msg );
   14641:	83 ec 0c             	sub    $0xc,%esp
   14644:	ff 75 08             	pushl  0x8(%ebp)
   14647:	e8 61 c8 ff ff       	call   10ead <cio_puts>
   1464c:	83 c4 10             	add    $0x10,%esp
	}

	int n = 0;
   1464f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	register pcb_t *pcb = ptable;
   14656:	bb 20 10 02 00       	mov    $0x21020,%ebx
	for( int i = 0; i < N_PROCS; ++i, ++pcb ) {
   1465b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   14662:	eb 39                	jmp    1469d <ctx_dump_all+0x69>
		if( pcb->state != STATE_UNUSED ) {
   14664:	8b 43 1c             	mov    0x1c(%ebx),%eax
   14667:	85 c0                	test   %eax,%eax
   14669:	74 2b                	je     14696 <ctx_dump_all+0x62>
			++n;
   1466b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
			cio_printf( "%2d(%d): ", n, pcb->pid );
   1466f:	8b 43 18             	mov    0x18(%ebx),%eax
   14672:	83 ec 04             	sub    $0x4,%esp
   14675:	50                   	push   %eax
   14676:	ff 75 f4             	pushl  -0xc(%ebp)
   14679:	68 6b b2 01 00       	push   $0x1b26b
   1467e:	e8 a4 ce ff ff       	call   11527 <cio_printf>
   14683:	83 c4 10             	add    $0x10,%esp
			ctx_dump( NULL, pcb->context );
   14686:	8b 03                	mov    (%ebx),%eax
   14688:	83 ec 08             	sub    $0x8,%esp
   1468b:	50                   	push   %eax
   1468c:	6a 00                	push   $0x0
   1468e:	e8 af fe ff ff       	call   14542 <ctx_dump>
   14693:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < N_PROCS; ++i, ++pcb ) {
   14696:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   1469a:	83 c3 30             	add    $0x30,%ebx
   1469d:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   146a1:	7e c1                	jle    14664 <ctx_dump_all+0x30>
		}
	}
}
   146a3:	90                   	nop
   146a4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   146a7:	c9                   	leave  
   146a8:	c3                   	ret    

000146a9 <pcb_dump>:
**
** @param msg[in]  An optional message to print before the dump
** @param pcb[in]  The PCB to dump
** @param all[in]  Dump all the contents?
*/
void pcb_dump( const char *msg, register pcb_t *pcb, bool_t all ) {
   146a9:	55                   	push   %ebp
   146aa:	89 e5                	mov    %esp,%ebp
   146ac:	56                   	push   %esi
   146ad:	53                   	push   %ebx
   146ae:	83 ec 10             	sub    $0x10,%esp
   146b1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
   146b4:	8b 45 10             	mov    0x10(%ebp),%eax
   146b7:	88 45 f4             	mov    %al,-0xc(%ebp)

	// first, the message (if there is one)
	if( msg ) {
   146ba:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   146be:	74 0e                	je     146ce <pcb_dump+0x25>
		cio_puts( msg );
   146c0:	83 ec 0c             	sub    $0xc,%esp
   146c3:	ff 75 08             	pushl  0x8(%ebp)
   146c6:	e8 e2 c7 ff ff       	call   10ead <cio_puts>
   146cb:	83 c4 10             	add    $0x10,%esp
	}

	// the pointer
	cio_printf( " @ %08x:", (uint32_t) pcb );
   146ce:	89 d8                	mov    %ebx,%eax
   146d0:	83 ec 08             	sub    $0x8,%esp
   146d3:	50                   	push   %eax
   146d4:	68 75 b2 01 00       	push   $0x1b275
   146d9:	e8 49 ce ff ff       	call   11527 <cio_printf>
   146de:	83 c4 10             	add    $0x10,%esp

	// if it's NULL, why did you bother calling me?
	if( pcb == NULL ) {
   146e1:	85 db                	test   %ebx,%ebx
   146e3:	75 15                	jne    146fa <pcb_dump+0x51>
		cio_puts( " NULL???\n" );
   146e5:	83 ec 0c             	sub    $0xc,%esp
   146e8:	68 b4 b1 01 00       	push   $0x1b1b4
   146ed:	e8 bb c7 ff ff       	call   10ead <cio_puts>
   146f2:	83 c4 10             	add    $0x10,%esp
		return;
   146f5:	e9 e7 00 00 00       	jmp    147e1 <pcb_dump+0x138>
	}

	cio_printf( " %d %s", pcb->pid,
			pcb->state >= N_STATES ? "???" : state_str[pcb->state] );
   146fa:	8b 43 1c             	mov    0x1c(%ebx),%eax
	cio_printf( " %d %s", pcb->pid,
   146fd:	83 f8 08             	cmp    $0x8,%eax
   14700:	77 0e                	ja     14710 <pcb_dump+0x67>
			pcb->state >= N_STATES ? "???" : state_str[pcb->state] );
   14702:	8b 43 1c             	mov    0x1c(%ebx),%eax
	cio_printf( " %d %s", pcb->pid,
   14705:	c1 e0 02             	shl    $0x2,%eax
   14708:	8d 90 c0 ae 01 00    	lea    0x1aec0(%eax),%edx
   1470e:	eb 05                	jmp    14715 <pcb_dump+0x6c>
   14710:	ba 7e b2 01 00       	mov    $0x1b27e,%edx
   14715:	8b 43 18             	mov    0x18(%ebx),%eax
   14718:	83 ec 04             	sub    $0x4,%esp
   1471b:	52                   	push   %edx
   1471c:	50                   	push   %eax
   1471d:	68 82 b2 01 00       	push   $0x1b282
   14722:	e8 00 ce ff ff       	call   11527 <cio_printf>
   14727:	83 c4 10             	add    $0x10,%esp

	if( !all ) {
   1472a:	80 7d f4 00          	cmpb   $0x0,-0xc(%ebp)
   1472e:	0f 84 ac 00 00 00    	je     147e0 <pcb_dump+0x137>
		return;
	}

	// now, the rest of the contents
	cio_printf( " %s",
			pcb->priority >= N_PRIOS ? "???" : prio_str[pcb->priority] );
   14734:	8b 43 20             	mov    0x20(%ebx),%eax
	cio_printf( " %s",
   14737:	83 f8 03             	cmp    $0x3,%eax
   1473a:	77 11                	ja     1474d <pcb_dump+0xa4>
			pcb->priority >= N_PRIOS ? "???" : prio_str[pcb->priority] );
   1473c:	8b 53 20             	mov    0x20(%ebx),%edx
	cio_printf( " %s",
   1473f:	89 d0                	mov    %edx,%eax
   14741:	c1 e0 02             	shl    $0x2,%eax
   14744:	01 d0                	add    %edx,%eax
   14746:	05 e4 ae 01 00       	add    $0x1aee4,%eax
   1474b:	eb 05                	jmp    14752 <pcb_dump+0xa9>
   1474d:	b8 7e b2 01 00       	mov    $0x1b27e,%eax
   14752:	83 ec 08             	sub    $0x8,%esp
   14755:	50                   	push   %eax
   14756:	68 89 b2 01 00       	push   $0x1b289
   1475b:	e8 c7 cd ff ff       	call   11527 <cio_printf>
   14760:	83 c4 10             	add    $0x10,%esp

	cio_printf( " ticks %u xit %d wake %08x\n",
   14763:	8b 4b 10             	mov    0x10(%ebx),%ecx
   14766:	8b 53 14             	mov    0x14(%ebx),%edx
   14769:	8b 43 24             	mov    0x24(%ebx),%eax
   1476c:	51                   	push   %ecx
   1476d:	52                   	push   %edx
   1476e:	50                   	push   %eax
   1476f:	68 8d b2 01 00       	push   $0x1b28d
   14774:	e8 ae cd ff ff       	call   11527 <cio_printf>
   14779:	83 c4 10             	add    $0x10,%esp
				pcb->ticks, pcb->exit_status, pcb->wakeup );

	cio_printf( " parent %08x", (uint32_t)pcb->parent );
   1477c:	8b 43 0c             	mov    0xc(%ebx),%eax
   1477f:	83 ec 08             	sub    $0x8,%esp
   14782:	50                   	push   %eax
   14783:	68 a9 b2 01 00       	push   $0x1b2a9
   14788:	e8 9a cd ff ff       	call   11527 <cio_printf>
   1478d:	83 c4 10             	add    $0x10,%esp
	if( pcb->parent != NULL ) {
   14790:	8b 43 0c             	mov    0xc(%ebx),%eax
   14793:	85 c0                	test   %eax,%eax
   14795:	74 17                	je     147ae <pcb_dump+0x105>
		cio_printf( " (%u)", pcb->parent->pid );
   14797:	8b 43 0c             	mov    0xc(%ebx),%eax
   1479a:	8b 40 18             	mov    0x18(%eax),%eax
   1479d:	83 ec 08             	sub    $0x8,%esp
   147a0:	50                   	push   %eax
   147a1:	68 b6 b2 01 00       	push   $0x1b2b6
   147a6:	e8 7c cd ff ff       	call   11527 <cio_printf>
   147ab:	83 c4 10             	add    $0x10,%esp
	}

	cio_printf( " next %08x context %08x stk %08x (%u)",
   147ae:	8b 43 28             	mov    0x28(%ebx),%eax
			(uint32_t) pcb->next, (uint32_t) pcb->context,
			(uint32_t) pcb->stack, pcb->stkpgs );
   147b1:	8b 53 04             	mov    0x4(%ebx),%edx
	cio_printf( " next %08x context %08x stk %08x (%u)",
   147b4:	89 d6                	mov    %edx,%esi
			(uint32_t) pcb->next, (uint32_t) pcb->context,
   147b6:	8b 13                	mov    (%ebx),%edx
	cio_printf( " next %08x context %08x stk %08x (%u)",
   147b8:	89 d1                	mov    %edx,%ecx
			(uint32_t) pcb->next, (uint32_t) pcb->context,
   147ba:	8b 53 08             	mov    0x8(%ebx),%edx
	cio_printf( " next %08x context %08x stk %08x (%u)",
   147bd:	83 ec 0c             	sub    $0xc,%esp
   147c0:	50                   	push   %eax
   147c1:	56                   	push   %esi
   147c2:	51                   	push   %ecx
   147c3:	52                   	push   %edx
   147c4:	68 bc b2 01 00       	push   $0x1b2bc
   147c9:	e8 59 cd ff ff       	call   11527 <cio_printf>
   147ce:	83 c4 20             	add    $0x20,%esp

	cio_putchar( '\n' );
   147d1:	83 ec 0c             	sub    $0xc,%esp
   147d4:	6a 0a                	push   $0xa
   147d6:	e8 92 c5 ff ff       	call   10d6d <cio_putchar>
   147db:	83 c4 10             	add    $0x10,%esp
   147de:	eb 01                	jmp    147e1 <pcb_dump+0x138>
		return;
   147e0:	90                   	nop
}
   147e1:	8d 65 f8             	lea    -0x8(%ebp),%esp
   147e4:	5b                   	pop    %ebx
   147e5:	5e                   	pop    %esi
   147e6:	5d                   	pop    %ebp
   147e7:	c3                   	ret    

000147e8 <pcb_queue_dump>:
**
** @param msg[in]       Optional message to print
** @param queue[in]     The queue to dump
** @param contents[in]  Also dump (some) contents?
*/
void pcb_queue_dump( const char *msg, pcb_queue_t queue, bool_t contents ) {
   147e8:	55                   	push   %ebp
   147e9:	89 e5                	mov    %esp,%ebp
   147eb:	83 ec 28             	sub    $0x28,%esp
   147ee:	8b 45 10             	mov    0x10(%ebp),%eax
   147f1:	88 45 e4             	mov    %al,-0x1c(%ebp)

	// report on this queue
	cio_printf( "%s: ", msg );
   147f4:	83 ec 08             	sub    $0x8,%esp
   147f7:	ff 75 08             	pushl  0x8(%ebp)
   147fa:	68 e2 b2 01 00       	push   $0x1b2e2
   147ff:	e8 23 cd ff ff       	call   11527 <cio_printf>
   14804:	83 c4 10             	add    $0x10,%esp
	if( queue == NULL ) {
   14807:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   1480b:	75 15                	jne    14822 <pcb_queue_dump+0x3a>
		cio_puts( "NULL???\n" );
   1480d:	83 ec 0c             	sub    $0xc,%esp
   14810:	68 e7 b2 01 00       	push   $0x1b2e7
   14815:	e8 93 c6 ff ff       	call   10ead <cio_puts>
   1481a:	83 c4 10             	add    $0x10,%esp
		return;
   1481d:	e9 d7 00 00 00       	jmp    148f9 <pcb_queue_dump+0x111>
	}

	// first, the basic data
	cio_printf( "head %08x tail %08x",
			(uint32_t) queue->head, (uint32_t) queue->tail );
   14822:	8b 45 0c             	mov    0xc(%ebp),%eax
   14825:	8b 40 04             	mov    0x4(%eax),%eax
	cio_printf( "head %08x tail %08x",
   14828:	89 c2                	mov    %eax,%edx
			(uint32_t) queue->head, (uint32_t) queue->tail );
   1482a:	8b 45 0c             	mov    0xc(%ebp),%eax
   1482d:	8b 00                	mov    (%eax),%eax
	cio_printf( "head %08x tail %08x",
   1482f:	83 ec 04             	sub    $0x4,%esp
   14832:	52                   	push   %edx
   14833:	50                   	push   %eax
   14834:	68 f0 b2 01 00       	push   $0x1b2f0
   14839:	e8 e9 cc ff ff       	call   11527 <cio_printf>
   1483e:	83 c4 10             	add    $0x10,%esp

	// next, how the queue is ordered
	cio_printf( " order %s\n",
			queue->order >= N_ORDERINGS ? "????" : ord_str[queue->order] );
   14841:	8b 45 0c             	mov    0xc(%ebp),%eax
   14844:	8b 40 08             	mov    0x8(%eax),%eax
	cio_printf( " order %s\n",
   14847:	83 f8 03             	cmp    $0x3,%eax
   1484a:	77 14                	ja     14860 <pcb_queue_dump+0x78>
			queue->order >= N_ORDERINGS ? "????" : ord_str[queue->order] );
   1484c:	8b 45 0c             	mov    0xc(%ebp),%eax
   1484f:	8b 50 08             	mov    0x8(%eax),%edx
	cio_printf( " order %s\n",
   14852:	89 d0                	mov    %edx,%eax
   14854:	c1 e0 02             	shl    $0x2,%eax
   14857:	01 d0                	add    %edx,%eax
   14859:	05 f8 ae 01 00       	add    $0x1aef8,%eax
   1485e:	eb 05                	jmp    14865 <pcb_queue_dump+0x7d>
   14860:	b8 04 b3 01 00       	mov    $0x1b304,%eax
   14865:	83 ec 08             	sub    $0x8,%esp
   14868:	50                   	push   %eax
   14869:	68 09 b3 01 00       	push   $0x1b309
   1486e:	e8 b4 cc ff ff       	call   11527 <cio_printf>
   14873:	83 c4 10             	add    $0x10,%esp

	// if there are members in the queue, dump the first few PIDs
	if( contents && queue->head != NULL ) {
   14876:	80 7d e4 00          	cmpb   $0x0,-0x1c(%ebp)
   1487a:	74 7d                	je     148f9 <pcb_queue_dump+0x111>
   1487c:	8b 45 0c             	mov    0xc(%ebp),%eax
   1487f:	8b 00                	mov    (%eax),%eax
   14881:	85 c0                	test   %eax,%eax
   14883:	74 74                	je     148f9 <pcb_queue_dump+0x111>
		cio_puts( " PIDs: " );
   14885:	83 ec 0c             	sub    $0xc,%esp
   14888:	68 14 b3 01 00       	push   $0x1b314
   1488d:	e8 1b c6 ff ff       	call   10ead <cio_puts>
   14892:	83 c4 10             	add    $0x10,%esp
		pcb_t *tmp = queue->head;
   14895:	8b 45 0c             	mov    0xc(%ebp),%eax
   14898:	8b 00                	mov    (%eax),%eax
   1489a:	89 45 f4             	mov    %eax,-0xc(%ebp)
		for( int i = 0; i < 5 && tmp != NULL; ++i, tmp = tmp->next ) {
   1489d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   148a4:	eb 24                	jmp    148ca <pcb_queue_dump+0xe2>
			cio_printf( " [%u]", tmp->pid );
   148a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
   148a9:	8b 40 18             	mov    0x18(%eax),%eax
   148ac:	83 ec 08             	sub    $0x8,%esp
   148af:	50                   	push   %eax
   148b0:	68 1c b3 01 00       	push   $0x1b31c
   148b5:	e8 6d cc ff ff       	call   11527 <cio_printf>
   148ba:	83 c4 10             	add    $0x10,%esp
		for( int i = 0; i < 5 && tmp != NULL; ++i, tmp = tmp->next ) {
   148bd:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   148c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
   148c4:	8b 40 08             	mov    0x8(%eax),%eax
   148c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
   148ca:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
   148ce:	7f 06                	jg     148d6 <pcb_queue_dump+0xee>
   148d0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   148d4:	75 d0                	jne    148a6 <pcb_queue_dump+0xbe>
		}

		if( tmp != NULL ) {
   148d6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   148da:	74 10                	je     148ec <pcb_queue_dump+0x104>
			cio_puts( " ..." );
   148dc:	83 ec 0c             	sub    $0xc,%esp
   148df:	68 22 b3 01 00       	push   $0x1b322
   148e4:	e8 c4 c5 ff ff       	call   10ead <cio_puts>
   148e9:	83 c4 10             	add    $0x10,%esp
		}

		cio_putchar( '\n' );
   148ec:	83 ec 0c             	sub    $0xc,%esp
   148ef:	6a 0a                	push   $0xa
   148f1:	e8 77 c4 ff ff       	call   10d6d <cio_putchar>
   148f6:	83 c4 10             	add    $0x10,%esp
	}
}
   148f9:	c9                   	leave  
   148fa:	c3                   	ret    

000148fb <ptable_dump>:
** dump the contents of the "active processes" table
**
** @param msg[in]  Optional message to print
** @param all[in]  Dump all or only part of the relevant data
*/
void ptable_dump( const char *msg, bool_t all ) {
   148fb:	55                   	push   %ebp
   148fc:	89 e5                	mov    %esp,%ebp
   148fe:	53                   	push   %ebx
   148ff:	83 ec 24             	sub    $0x24,%esp
   14902:	8b 45 0c             	mov    0xc(%ebp),%eax
   14905:	88 45 e4             	mov    %al,-0x1c(%ebp)

	if( msg ) {
   14908:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1490c:	74 0e                	je     1491c <ptable_dump+0x21>
		cio_puts( msg );
   1490e:	83 ec 0c             	sub    $0xc,%esp
   14911:	ff 75 08             	pushl  0x8(%ebp)
   14914:	e8 94 c5 ff ff       	call   10ead <cio_puts>
   14919:	83 c4 10             	add    $0x10,%esp
	}
	cio_putchar( ' ' );
   1491c:	83 ec 0c             	sub    $0xc,%esp
   1491f:	6a 20                	push   $0x20
   14921:	e8 47 c4 ff ff       	call   10d6d <cio_putchar>
   14926:	83 c4 10             	add    $0x10,%esp

	int used = 0;
   14929:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	int empty = 0;
   14930:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

	register pcb_t *pcb = ptable;
   14937:	bb 20 10 02 00       	mov    $0x21020,%ebx
	for( int i = 0; i < N_PROCS; ++i ) {
   1493c:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   14943:	eb 54                	jmp    14999 <ptable_dump+0x9e>
		if( pcb->state == STATE_UNUSED ) {
   14945:	8b 43 1c             	mov    0x1c(%ebx),%eax
   14948:	85 c0                	test   %eax,%eax
   1494a:	75 06                	jne    14952 <ptable_dump+0x57>

			// an empty slot
			++empty;
   1494c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   14950:	eb 43                	jmp    14995 <ptable_dump+0x9a>

		} else {

			// a non-empty slot
			++used;
   14952:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

			// if not dumping everything, add commas if needed
			if( !all && used ) {
   14956:	80 7d e4 00          	cmpb   $0x0,-0x1c(%ebp)
   1495a:	75 13                	jne    1496f <ptable_dump+0x74>
   1495c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   14960:	74 0d                	je     1496f <ptable_dump+0x74>
				cio_putchar( ',' );
   14962:	83 ec 0c             	sub    $0xc,%esp
   14965:	6a 2c                	push   $0x2c
   14967:	e8 01 c4 ff ff       	call   10d6d <cio_putchar>
   1496c:	83 c4 10             	add    $0x10,%esp
			}

			// report the table slot #
			cio_printf( " #%d:", i );
   1496f:	83 ec 08             	sub    $0x8,%esp
   14972:	ff 75 ec             	pushl  -0x14(%ebp)
   14975:	68 27 b3 01 00       	push   $0x1b327
   1497a:	e8 a8 cb ff ff       	call   11527 <cio_printf>
   1497f:	83 c4 10             	add    $0x10,%esp

			// and dump the contents
			pcb_dump( NULL, pcb, all );
   14982:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
   14986:	83 ec 04             	sub    $0x4,%esp
   14989:	50                   	push   %eax
   1498a:	53                   	push   %ebx
   1498b:	6a 00                	push   $0x0
   1498d:	e8 17 fd ff ff       	call   146a9 <pcb_dump>
   14992:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < N_PROCS; ++i ) {
   14995:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   14999:	83 7d ec 18          	cmpl   $0x18,-0x14(%ebp)
   1499d:	7e a6                	jle    14945 <ptable_dump+0x4a>
		}
	}

	// only need this if we're doing one-line output
	if( !all ) {
   1499f:	80 7d e4 00          	cmpb   $0x0,-0x1c(%ebp)
   149a3:	75 0d                	jne    149b2 <ptable_dump+0xb7>
		cio_putchar( '\n' );
   149a5:	83 ec 0c             	sub    $0xc,%esp
   149a8:	6a 0a                	push   $0xa
   149aa:	e8 be c3 ff ff       	call   10d6d <cio_putchar>
   149af:	83 c4 10             	add    $0x10,%esp
	}

	// sanity check - make sure we saw the correct number of table slots
	if( (used + empty) != N_PROCS ) {
   149b2:	8b 55 f4             	mov    -0xc(%ebp),%edx
   149b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
   149b8:	01 d0                	add    %edx,%eax
   149ba:	83 f8 19             	cmp    $0x19,%eax
   149bd:	74 21                	je     149e0 <ptable_dump+0xe5>
		cio_printf( "Table size %d, used %d + empty %d = %d???\n",
   149bf:	8b 55 f4             	mov    -0xc(%ebp),%edx
   149c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
   149c5:	01 d0                	add    %edx,%eax
   149c7:	83 ec 0c             	sub    $0xc,%esp
   149ca:	50                   	push   %eax
   149cb:	ff 75 f0             	pushl  -0x10(%ebp)
   149ce:	ff 75 f4             	pushl  -0xc(%ebp)
   149d1:	6a 19                	push   $0x19
   149d3:	68 30 b3 01 00       	push   $0x1b330
   149d8:	e8 4a cb ff ff       	call   11527 <cio_printf>
   149dd:	83 c4 20             	add    $0x20,%esp
					  N_PROCS, used, empty, used + empty );
	}
}
   149e0:	90                   	nop
   149e1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   149e4:	c9                   	leave  
   149e5:	c3                   	ret    

000149e6 <ptable_dump_counts>:
** Name:    ptable_dump_counts
**
** Prints basic information about the process table (number of
** entries, number with each process state, etc.).
*/
void ptable_dump_counts( void ) {
   149e6:	55                   	push   %ebp
   149e7:	89 e5                	mov    %esp,%ebp
   149e9:	57                   	push   %edi
   149ea:	83 ec 34             	sub    $0x34,%esp
	uint_t nstate[N_STATES] = { 0 };
   149ed:	8d 55 c8             	lea    -0x38(%ebp),%edx
   149f0:	b8 00 00 00 00       	mov    $0x0,%eax
   149f5:	b9 09 00 00 00       	mov    $0x9,%ecx
   149fa:	89 d7                	mov    %edx,%edi
   149fc:	f3 ab                	rep stos %eax,%es:(%edi)
	uint_t unknown = 0;
   149fe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	int n = 0;
   14a05:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	pcb_t *ptr = ptable;
   14a0c:	c7 45 ec 20 10 02 00 	movl   $0x21020,-0x14(%ebp)
	while( n < N_PROCS ) {
   14a13:	eb 2a                	jmp    14a3f <ptable_dump_counts+0x59>
		if( ptr->state < 0 || ptr->state >= N_STATES ) {
   14a15:	8b 45 ec             	mov    -0x14(%ebp),%eax
   14a18:	8b 40 1c             	mov    0x1c(%eax),%eax
   14a1b:	83 f8 08             	cmp    $0x8,%eax
   14a1e:	76 06                	jbe    14a26 <ptable_dump_counts+0x40>
			++unknown;
   14a20:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   14a24:	eb 11                	jmp    14a37 <ptable_dump_counts+0x51>
		} else {
			++nstate[ptr->state];
   14a26:	8b 45 ec             	mov    -0x14(%ebp),%eax
   14a29:	8b 40 1c             	mov    0x1c(%eax),%eax
   14a2c:	8b 54 85 c8          	mov    -0x38(%ebp,%eax,4),%edx
   14a30:	83 c2 01             	add    $0x1,%edx
   14a33:	89 54 85 c8          	mov    %edx,-0x38(%ebp,%eax,4)
		}
		++n;
   14a37:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
		++ptr;
   14a3b:	83 45 ec 30          	addl   $0x30,-0x14(%ebp)
	while( n < N_PROCS ) {
   14a3f:	83 7d f0 18          	cmpl   $0x18,-0x10(%ebp)
   14a43:	7e d0                	jle    14a15 <ptable_dump_counts+0x2f>
	}

	cio_printf( "Ptable: %u ***", unknown );
   14a45:	83 ec 08             	sub    $0x8,%esp
   14a48:	ff 75 f4             	pushl  -0xc(%ebp)
   14a4b:	68 5b b3 01 00       	push   $0x1b35b
   14a50:	e8 d2 ca ff ff       	call   11527 <cio_printf>
   14a55:	83 c4 10             	add    $0x10,%esp
	for( n = 0; n < N_STATES; ++n ) {
   14a58:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   14a5f:	eb 34                	jmp    14a95 <ptable_dump_counts+0xaf>
		if( nstate[n] ) {
   14a61:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14a64:	8b 44 85 c8          	mov    -0x38(%ebp,%eax,4),%eax
   14a68:	85 c0                	test   %eax,%eax
   14a6a:	74 25                	je     14a91 <ptable_dump_counts+0xab>
			cio_printf( " %u %s", nstate[n],
					state_str[n] != NULL ? state_str[n] : "???" );
   14a6c:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14a6f:	c1 e0 02             	shl    $0x2,%eax
   14a72:	8d 90 c0 ae 01 00    	lea    0x1aec0(%eax),%edx
			cio_printf( " %u %s", nstate[n],
   14a78:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14a7b:	8b 44 85 c8          	mov    -0x38(%ebp,%eax,4),%eax
   14a7f:	83 ec 04             	sub    $0x4,%esp
   14a82:	52                   	push   %edx
   14a83:	50                   	push   %eax
   14a84:	68 6a b3 01 00       	push   $0x1b36a
   14a89:	e8 99 ca ff ff       	call   11527 <cio_printf>
   14a8e:	83 c4 10             	add    $0x10,%esp
	for( n = 0; n < N_STATES; ++n ) {
   14a91:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   14a95:	83 7d f0 08          	cmpl   $0x8,-0x10(%ebp)
   14a99:	7e c6                	jle    14a61 <ptable_dump_counts+0x7b>
		}
	}
	cio_putchar( '\n' );
   14a9b:	83 ec 0c             	sub    $0xc,%esp
   14a9e:	6a 0a                	push   $0xa
   14aa0:	e8 c8 c2 ff ff       	call   10d6d <cio_putchar>
   14aa5:	83 c4 10             	add    $0x10,%esp
}
   14aa8:	90                   	nop
   14aa9:	8b 7d fc             	mov    -0x4(%ebp),%edi
   14aac:	c9                   	leave  
   14aad:	c3                   	ret    

00014aae <sio_isr>:
** events (as described by the SIO controller).
**
** @param vector   The interrupt vector number for this interrupt
** @param ecode    The error code associated with this interrupt
*/
static void sio_isr( int vector, int ecode ) {
   14aae:	55                   	push   %ebp
   14aaf:	89 e5                	mov    %esp,%ebp
   14ab1:	83 ec 58             	sub    $0x58,%esp
   14ab4:	c7 45 e8 fa 03 00 00 	movl   $0x3fa,-0x18(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14abb:	8b 45 e8             	mov    -0x18(%ebp),%eax
   14abe:	89 c2                	mov    %eax,%edx
   14ac0:	ec                   	in     (%dx),%al
   14ac1:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
   14ac4:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
	//

	for(;;) {

		// get the "pending event" indicator
		int iir = inb( UA4_IIR ) & UA4_IIR_INT_PRI_MASK;
   14ac8:	0f b6 c0             	movzbl %al,%eax
   14acb:	83 e0 0f             	and    $0xf,%eax
   14ace:	89 45 f0             	mov    %eax,-0x10(%ebp)

		// process this event
		switch( iir ) {
   14ad1:	83 7d f0 0c          	cmpl   $0xc,-0x10(%ebp)
   14ad5:	0f 87 95 02 00 00    	ja     14d70 <sio_isr+0x2c2>
   14adb:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14ade:	c1 e0 02             	shl    $0x2,%eax
   14ae1:	05 5c b5 01 00       	add    $0x1b55c,%eax
   14ae6:	8b 00                	mov    (%eax),%eax
   14ae8:	ff e0                	jmp    *%eax
   14aea:	c7 45 e0 fd 03 00 00 	movl   $0x3fd,-0x20(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14af1:	8b 45 e0             	mov    -0x20(%ebp),%eax
   14af4:	89 c2                	mov    %eax,%edx
   14af6:	ec                   	in     (%dx),%al
   14af7:	88 45 df             	mov    %al,-0x21(%ebp)
	return data;
   14afa:	0f b6 45 df          	movzbl -0x21(%ebp),%eax

		case UA4_IIR_LINE_STATUS:
			// shouldn't happen, but just in case....
			cio_printf( "** SIO int, LSR = %02x\n", inb(UA4_LSR) );
   14afe:	0f b6 c0             	movzbl %al,%eax
   14b01:	83 ec 08             	sub    $0x8,%esp
   14b04:	50                   	push   %eax
   14b05:	68 98 b4 01 00       	push   $0x1b498
   14b0a:	e8 18 ca ff ff       	call   11527 <cio_printf>
   14b0f:	83 c4 10             	add    $0x10,%esp
			break;
   14b12:	e9 b6 02 00 00       	jmp    14dcd <sio_isr+0x31f>
   14b17:	c7 45 d8 f8 03 00 00 	movl   $0x3f8,-0x28(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14b1e:	8b 45 d8             	mov    -0x28(%ebp),%eax
   14b21:	89 c2                	mov    %eax,%edx
   14b23:	ec                   	in     (%dx),%al
   14b24:	88 45 d7             	mov    %al,-0x29(%ebp)
	return data;
   14b27:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
		case UA4_IIR_RX:
#if TRACING_SIO_ISR
	cio_puts( " RX" );
#endif
			// get the character
			ch = inb( UA4_RXD );
   14b2b:	0f b6 c0             	movzbl %al,%eax
   14b2e:	89 45 f4             	mov    %eax,-0xc(%ebp)
			if( ch == '\r' ) {    // map CR to LF
   14b31:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
   14b35:	75 07                	jne    14b3e <sio_isr+0x90>
				ch = '\n';
   14b37:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
			// If there is a waiting process, this must be
			// the first input character; give it to that
			// process and awaken the process.
			//

			if( !QEMPTY(QNAME) ) {
   14b3e:	a1 04 10 02 00       	mov    0x21004,%eax
   14b43:	83 ec 0c             	sub    $0xc,%esp
   14b46:	50                   	push   %eax
   14b47:	e8 cd f2 ff ff       	call   13e19 <pcb_queue_empty>
   14b4c:	83 c4 10             	add    $0x10,%esp
   14b4f:	84 c0                	test   %al,%al
   14b51:	0f 85 d0 00 00 00    	jne    14c27 <sio_isr+0x179>
				PCBTYPE *pcb;

				QDEQUE( QNAME, pcb );
   14b57:	a1 04 10 02 00       	mov    0x21004,%eax
   14b5c:	83 ec 08             	sub    $0x8,%esp
   14b5f:	8d 55 b0             	lea    -0x50(%ebp),%edx
   14b62:	52                   	push   %edx
   14b63:	50                   	push   %eax
   14b64:	e8 4e f5 ff ff       	call   140b7 <pcb_queue_remove>
   14b69:	83 c4 10             	add    $0x10,%esp
   14b6c:	85 c0                	test   %eax,%eax
   14b6e:	74 3b                	je     14bab <sio_isr+0xfd>
   14b70:	83 ec 04             	sub    $0x4,%esp
   14b73:	68 b0 b4 01 00       	push   $0x1b4b0
   14b78:	6a 00                	push   $0x0
   14b7a:	68 ac 00 00 00       	push   $0xac
   14b7f:	68 e8 b4 01 00       	push   $0x1b4e8
   14b84:	68 ec b5 01 00       	push   $0x1b5ec
   14b89:	68 ee b4 01 00       	push   $0x1b4ee
   14b8e:	68 00 f0 01 00       	push   $0x1f000
   14b93:	e8 4a db ff ff       	call   126e2 <sprint>
   14b98:	83 c4 20             	add    $0x20,%esp
   14b9b:	83 ec 0c             	sub    $0xc,%esp
   14b9e:	68 00 f0 01 00       	push   $0x1f000
   14ba3:	e8 ba d8 ff ff       	call   12462 <kpanic>
   14ba8:	83 c4 10             	add    $0x10,%esp
				// make sure we got a non-NULL result
				assert( pcb );
   14bab:	8b 45 b0             	mov    -0x50(%ebp),%eax
   14bae:	85 c0                	test   %eax,%eax
   14bb0:	75 3b                	jne    14bed <sio_isr+0x13f>
   14bb2:	83 ec 04             	sub    $0x4,%esp
   14bb5:	68 04 b5 01 00       	push   $0x1b504
   14bba:	6a 00                	push   $0x0
   14bbc:	68 ae 00 00 00       	push   $0xae
   14bc1:	68 e8 b4 01 00       	push   $0x1b4e8
   14bc6:	68 ec b5 01 00       	push   $0x1b5ec
   14bcb:	68 ee b4 01 00       	push   $0x1b4ee
   14bd0:	68 00 f0 01 00       	push   $0x1f000
   14bd5:	e8 08 db ff ff       	call   126e2 <sprint>
   14bda:	83 c4 20             	add    $0x20,%esp
   14bdd:	83 ec 0c             	sub    $0xc,%esp
   14be0:	68 00 f0 01 00       	push   $0x1f000
   14be5:	e8 78 d8 ff ff       	call   12462 <kpanic>
   14bea:	83 c4 10             	add    $0x10,%esp

				// return char via arg #2 and count in EAX
				char *buf = (char *) ARG(pcb,2);
   14bed:	8b 45 b0             	mov    -0x50(%ebp),%eax
   14bf0:	8b 00                	mov    (%eax),%eax
   14bf2:	83 c0 48             	add    $0x48,%eax
   14bf5:	83 c0 08             	add    $0x8,%eax
   14bf8:	8b 00                	mov    (%eax),%eax
   14bfa:	89 45 ec             	mov    %eax,-0x14(%ebp)
				*buf = ch & 0xff;
   14bfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
   14c00:	89 c2                	mov    %eax,%edx
   14c02:	8b 45 ec             	mov    -0x14(%ebp),%eax
   14c05:	88 10                	mov    %dl,(%eax)
				RET(pcb) = 1;
   14c07:	8b 45 b0             	mov    -0x50(%ebp),%eax
   14c0a:	8b 00                	mov    (%eax),%eax
   14c0c:	c7 40 30 01 00 00 00 	movl   $0x1,0x30(%eax)
				SCHED( pcb );
   14c13:	8b 45 b0             	mov    -0x50(%ebp),%eax
   14c16:	83 ec 0c             	sub    $0xc,%esp
   14c19:	50                   	push   %eax
   14c1a:	e8 8b f7 ff ff       	call   143aa <schedule>
   14c1f:	83 c4 10             	add    $0x10,%esp
				}

#ifdef QNAME
			}
#endif /* QNAME */
			break;
   14c22:	e9 a5 01 00 00       	jmp    14dcc <sio_isr+0x31e>
				if( incount < BUF_SIZE ) {
   14c27:	a1 88 d9 01 00       	mov    0x1d988,%eax
   14c2c:	3d ff 07 00 00       	cmp    $0x7ff,%eax
   14c31:	0f 87 95 01 00 00    	ja     14dcc <sio_isr+0x31e>
					*inlast++ = ch;
   14c37:	a1 80 d9 01 00       	mov    0x1d980,%eax
   14c3c:	8d 50 01             	lea    0x1(%eax),%edx
   14c3f:	89 15 80 d9 01 00    	mov    %edx,0x1d980
   14c45:	8b 55 f4             	mov    -0xc(%ebp),%edx
   14c48:	88 10                	mov    %dl,(%eax)
					++incount;
   14c4a:	a1 88 d9 01 00       	mov    0x1d988,%eax
   14c4f:	83 c0 01             	add    $0x1,%eax
   14c52:	a3 88 d9 01 00       	mov    %eax,0x1d988
			break;
   14c57:	e9 70 01 00 00       	jmp    14dcc <sio_isr+0x31e>
   14c5c:	c7 45 d0 f8 03 00 00 	movl   $0x3f8,-0x30(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14c63:	8b 45 d0             	mov    -0x30(%ebp),%eax
   14c66:	89 c2                	mov    %eax,%edx
   14c68:	ec                   	in     (%dx),%al
   14c69:	88 45 cf             	mov    %al,-0x31(%ebp)
	return data;
   14c6c:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax

		case UA5_IIR_RX_FIFO:
			// shouldn't happen, but just in case....
			ch = inb( UA4_RXD );
   14c70:	0f b6 c0             	movzbl %al,%eax
   14c73:	89 45 f4             	mov    %eax,-0xc(%ebp)
			cio_printf( "** SIO FIFO timeout, RXD = %02x\n", ch );
   14c76:	83 ec 08             	sub    $0x8,%esp
   14c79:	ff 75 f4             	pushl  -0xc(%ebp)
   14c7c:	68 08 b5 01 00       	push   $0x1b508
   14c81:	e8 a1 c8 ff ff       	call   11527 <cio_printf>
   14c86:	83 c4 10             	add    $0x10,%esp
			break;
   14c89:	e9 3f 01 00 00       	jmp    14dcd <sio_isr+0x31f>
		case UA4_IIR_TX:
#if TRACING_SIO_ISR
	cio_puts( " TX" );
#endif
			// if there is another character, send it
			if( sending && outcount > 0 ) {
   14c8e:	a1 ac e1 01 00       	mov    0x1e1ac,%eax
   14c93:	85 c0                	test   %eax,%eax
   14c95:	74 5d                	je     14cf4 <sio_isr+0x246>
   14c97:	a1 a8 e1 01 00       	mov    0x1e1a8,%eax
   14c9c:	85 c0                	test   %eax,%eax
   14c9e:	74 54                	je     14cf4 <sio_isr+0x246>
#if TRACING_SIO_ISR
	cio_printf( " ch %02x", *outnext );
#endif
				outb( UA4_TXD, *outnext );
   14ca0:	a1 a4 e1 01 00       	mov    0x1e1a4,%eax
   14ca5:	0f b6 00             	movzbl (%eax),%eax
   14ca8:	0f b6 c0             	movzbl %al,%eax
   14cab:	c7 45 c8 f8 03 00 00 	movl   $0x3f8,-0x38(%ebp)
   14cb2:	88 45 c7             	mov    %al,-0x39(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   14cb5:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   14cb9:	8b 55 c8             	mov    -0x38(%ebp),%edx
   14cbc:	ee                   	out    %al,(%dx)
				++outnext;
   14cbd:	a1 a4 e1 01 00       	mov    0x1e1a4,%eax
   14cc2:	83 c0 01             	add    $0x1,%eax
   14cc5:	a3 a4 e1 01 00       	mov    %eax,0x1e1a4
				// wrap around if necessary
				if( outnext >= (outbuffer + BUF_SIZE) ) {
   14cca:	a1 a4 e1 01 00       	mov    0x1e1a4,%eax
   14ccf:	ba a0 e1 01 00       	mov    $0x1e1a0,%edx
   14cd4:	39 d0                	cmp    %edx,%eax
   14cd6:	72 0a                	jb     14ce2 <sio_isr+0x234>
					outnext = outbuffer;
   14cd8:	c7 05 a4 e1 01 00 a0 	movl   $0x1d9a0,0x1e1a4
   14cdf:	d9 01 00 
				}
				--outcount;
   14ce2:	a1 a8 e1 01 00       	mov    0x1e1a8,%eax
   14ce7:	83 e8 01             	sub    $0x1,%eax
   14cea:	a3 a8 e1 01 00       	mov    %eax,0x1e1a8
				outlast = outnext = outbuffer;
				sending = 0;
				// disable TX interrupts
				sio_disable( SIO_TX );
			}
			break;
   14cef:	e9 d9 00 00 00       	jmp    14dcd <sio_isr+0x31f>
				outcount = 0;
   14cf4:	c7 05 a8 e1 01 00 00 	movl   $0x0,0x1e1a8
   14cfb:	00 00 00 
				outlast = outnext = outbuffer;
   14cfe:	c7 05 a4 e1 01 00 a0 	movl   $0x1d9a0,0x1e1a4
   14d05:	d9 01 00 
   14d08:	a1 a4 e1 01 00       	mov    0x1e1a4,%eax
   14d0d:	a3 a0 e1 01 00       	mov    %eax,0x1e1a0
				sending = 0;
   14d12:	c7 05 ac e1 01 00 00 	movl   $0x0,0x1e1ac
   14d19:	00 00 00 
				sio_disable( SIO_TX );
   14d1c:	83 ec 0c             	sub    $0xc,%esp
   14d1f:	6a 01                	push   $0x1
   14d21:	e8 99 02 00 00       	call   14fbf <sio_disable>
   14d26:	83 c4 10             	add    $0x10,%esp
			break;
   14d29:	e9 9f 00 00 00       	jmp    14dcd <sio_isr+0x31f>
   14d2e:	c7 45 c0 20 00 00 00 	movl   $0x20,-0x40(%ebp)
   14d35:	c6 45 bf 20          	movb   $0x20,-0x41(%ebp)
   14d39:	0f b6 45 bf          	movzbl -0x41(%ebp),%eax
   14d3d:	8b 55 c0             	mov    -0x40(%ebp),%edx
   14d40:	ee                   	out    %al,(%dx)
#if TRACING_SIO_ISR
	cio_puts( " EOI\n" );
#endif
			// nothing to do - tell the PIC we're done
			outb( PIC1_CMD, PIC_EOI );
			return;
   14d41:	e9 8c 00 00 00       	jmp    14dd2 <sio_isr+0x324>
   14d46:	c7 45 b8 fe 03 00 00 	movl   $0x3fe,-0x48(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   14d4d:	8b 45 b8             	mov    -0x48(%ebp),%eax
   14d50:	89 c2                	mov    %eax,%edx
   14d52:	ec                   	in     (%dx),%al
   14d53:	88 45 b7             	mov    %al,-0x49(%ebp)
	return data;
   14d56:	0f b6 45 b7          	movzbl -0x49(%ebp),%eax

		case UA4_IIR_MODEM_STATUS:
			// shouldn't happen, but just in case....
			cio_printf( "** SIO int, MSR = %02x\n", inb(UA4_MSR) );
   14d5a:	0f b6 c0             	movzbl %al,%eax
   14d5d:	83 ec 08             	sub    $0x8,%esp
   14d60:	50                   	push   %eax
   14d61:	68 29 b5 01 00       	push   $0x1b529
   14d66:	e8 bc c7 ff ff       	call   11527 <cio_printf>
   14d6b:	83 c4 10             	add    $0x10,%esp
			break;
   14d6e:	eb 5d                	jmp    14dcd <sio_isr+0x31f>

		default:
			// uh-oh....
			sprint( b256, "sio isr: IIR %02x\n", ((uint32_t) iir) & 0xff );
   14d70:	8b 45 f0             	mov    -0x10(%ebp),%eax
   14d73:	0f b6 c0             	movzbl %al,%eax
   14d76:	83 ec 04             	sub    $0x4,%esp
   14d79:	50                   	push   %eax
   14d7a:	68 41 b5 01 00       	push   $0x1b541
   14d7f:	68 00 f2 01 00       	push   $0x1f200
   14d84:	e8 59 d9 ff ff       	call   126e2 <sprint>
   14d89:	83 c4 10             	add    $0x10,%esp
			PANIC( 0, b256 );
   14d8c:	83 ec 04             	sub    $0x4,%esp
   14d8f:	68 54 b5 01 00       	push   $0x1b554
   14d94:	6a 00                	push   $0x0
   14d96:	68 fe 00 00 00       	push   $0xfe
   14d9b:	68 e8 b4 01 00       	push   $0x1b4e8
   14da0:	68 ec b5 01 00       	push   $0x1b5ec
   14da5:	68 ee b4 01 00       	push   $0x1b4ee
   14daa:	68 00 f0 01 00       	push   $0x1f000
   14daf:	e8 2e d9 ff ff       	call   126e2 <sprint>
   14db4:	83 c4 20             	add    $0x20,%esp
   14db7:	83 ec 0c             	sub    $0xc,%esp
   14dba:	68 00 f0 01 00       	push   $0x1f000
   14dbf:	e8 9e d6 ff ff       	call   12462 <kpanic>
   14dc4:	83 c4 10             	add    $0x10,%esp
   14dc7:	e9 e8 fc ff ff       	jmp    14ab4 <sio_isr+0x6>
			break;
   14dcc:	90                   	nop
	for(;;) {
   14dcd:	e9 e2 fc ff ff       	jmp    14ab4 <sio_isr+0x6>
	
	}

	// should never reach this point!
	assert( false );
}
   14dd2:	c9                   	leave  
   14dd3:	c3                   	ret    

00014dd4 <sio_init>:
/**
** sio_init()
**
** Initialize the UART chip.
*/
void sio_init( void ) {
   14dd4:	55                   	push   %ebp
   14dd5:	89 e5                	mov    %esp,%ebp
   14dd7:	83 ec 68             	sub    $0x68,%esp

#if TRACING_INIT
	cio_puts( " Sio" );
   14dda:	83 ec 0c             	sub    $0xc,%esp
   14ddd:	68 90 b5 01 00       	push   $0x1b590
   14de2:	e8 c6 c0 ff ff       	call   10ead <cio_puts>
   14de7:	83 c4 10             	add    $0x10,%esp

	/*
	** Initialize SIO variables.
	*/

	memclr( (void *) inbuffer, sizeof(inbuffer) );
   14dea:	83 ec 08             	sub    $0x8,%esp
   14ded:	68 00 08 00 00       	push   $0x800
   14df2:	68 80 d1 01 00       	push   $0x1d180
   14df7:	e8 63 d7 ff ff       	call   1255f <memclr>
   14dfc:	83 c4 10             	add    $0x10,%esp
	inlast = innext = inbuffer;
   14dff:	c7 05 84 d9 01 00 80 	movl   $0x1d180,0x1d984
   14e06:	d1 01 00 
   14e09:	a1 84 d9 01 00       	mov    0x1d984,%eax
   14e0e:	a3 80 d9 01 00       	mov    %eax,0x1d980
	incount = 0;
   14e13:	c7 05 88 d9 01 00 00 	movl   $0x0,0x1d988
   14e1a:	00 00 00 

	memclr( (void *) outbuffer, sizeof(outbuffer) );
   14e1d:	83 ec 08             	sub    $0x8,%esp
   14e20:	68 00 08 00 00       	push   $0x800
   14e25:	68 a0 d9 01 00       	push   $0x1d9a0
   14e2a:	e8 30 d7 ff ff       	call   1255f <memclr>
   14e2f:	83 c4 10             	add    $0x10,%esp
	outlast = outnext = outbuffer;
   14e32:	c7 05 a4 e1 01 00 a0 	movl   $0x1d9a0,0x1e1a4
   14e39:	d9 01 00 
   14e3c:	a1 a4 e1 01 00       	mov    0x1e1a4,%eax
   14e41:	a3 a0 e1 01 00       	mov    %eax,0x1e1a0
	outcount = 0;
   14e46:	c7 05 a8 e1 01 00 00 	movl   $0x0,0x1e1a8
   14e4d:	00 00 00 
	sending = 0;
   14e50:	c7 05 ac e1 01 00 00 	movl   $0x0,0x1e1ac
   14e57:	00 00 00 
   14e5a:	c7 45 a4 fa 03 00 00 	movl   $0x3fa,-0x5c(%ebp)
   14e61:	c6 45 a3 20          	movb   $0x20,-0x5d(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   14e65:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
   14e69:	8b 55 a4             	mov    -0x5c(%ebp),%edx
   14e6c:	ee                   	out    %al,(%dx)
   14e6d:	c7 45 ac fa 03 00 00 	movl   $0x3fa,-0x54(%ebp)
   14e74:	c6 45 ab 00          	movb   $0x0,-0x55(%ebp)
   14e78:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
   14e7c:	8b 55 ac             	mov    -0x54(%ebp),%edx
   14e7f:	ee                   	out    %al,(%dx)
   14e80:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
   14e87:	c6 45 b3 01          	movb   $0x1,-0x4d(%ebp)
   14e8b:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
   14e8f:	8b 55 b4             	mov    -0x4c(%ebp),%edx
   14e92:	ee                   	out    %al,(%dx)
   14e93:	c7 45 bc fa 03 00 00 	movl   $0x3fa,-0x44(%ebp)
   14e9a:	c6 45 bb 03          	movb   $0x3,-0x45(%ebp)
   14e9e:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
   14ea2:	8b 55 bc             	mov    -0x44(%ebp),%edx
   14ea5:	ee                   	out    %al,(%dx)
   14ea6:	c7 45 c4 fa 03 00 00 	movl   $0x3fa,-0x3c(%ebp)
   14ead:	c6 45 c3 07          	movb   $0x7,-0x3d(%ebp)
   14eb1:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
   14eb5:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   14eb8:	ee                   	out    %al,(%dx)
   14eb9:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
   14ec0:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
   14ec4:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
   14ec8:	8b 55 cc             	mov    -0x34(%ebp),%edx
   14ecb:	ee                   	out    %al,(%dx)
	** note that we leave them disabled; sio_enable() must be
	** called to switch them back on
	*/

	outb( UA4_IER, 0 );
	ier = 0;
   14ecc:	c6 05 b0 e1 01 00 00 	movb   $0x0,0x1e1b0
   14ed3:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
   14eda:	c6 45 d3 80          	movb   $0x80,-0x2d(%ebp)
   14ede:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
   14ee2:	8b 55 d4             	mov    -0x2c(%ebp),%edx
   14ee5:	ee                   	out    %al,(%dx)
   14ee6:	c7 45 dc f8 03 00 00 	movl   $0x3f8,-0x24(%ebp)
   14eed:	c6 45 db 0c          	movb   $0xc,-0x25(%ebp)
   14ef1:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   14ef5:	8b 55 dc             	mov    -0x24(%ebp),%edx
   14ef8:	ee                   	out    %al,(%dx)
   14ef9:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
   14f00:	c6 45 e3 00          	movb   $0x0,-0x1d(%ebp)
   14f04:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
   14f08:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   14f0b:	ee                   	out    %al,(%dx)
   14f0c:	c7 45 ec fb 03 00 00 	movl   $0x3fb,-0x14(%ebp)
   14f13:	c6 45 eb 03          	movb   $0x3,-0x15(%ebp)
   14f17:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   14f1b:	8b 55 ec             	mov    -0x14(%ebp),%edx
   14f1e:	ee                   	out    %al,(%dx)
   14f1f:	c7 45 f4 fc 03 00 00 	movl   $0x3fc,-0xc(%ebp)
   14f26:	c6 45 f3 0b          	movb   $0xb,-0xd(%ebp)
   14f2a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   14f2e:	8b 55 f4             	mov    -0xc(%ebp),%edx
   14f31:	ee                   	out    %al,(%dx)

	/*
	** Install our ISR
	*/

	install_isr( VEC_COM1, sio_isr );
   14f32:	83 ec 08             	sub    $0x8,%esp
   14f35:	68 ae 4a 01 00       	push   $0x14aae
   14f3a:	6a 24                	push   $0x24
   14f3c:	e8 20 08 00 00       	call   15761 <install_isr>
   14f41:	83 c4 10             	add    $0x10,%esp
}
   14f44:	90                   	nop
   14f45:	c9                   	leave  
   14f46:	c3                   	ret    

00014f47 <sio_enable>:
**
** @param which   Bit mask indicating which interrupt(s) to enable
**
** @return the prior IER setting
*/
uint8_t sio_enable( uint8_t which ) {
   14f47:	55                   	push   %ebp
   14f48:	89 e5                	mov    %esp,%ebp
   14f4a:	83 ec 14             	sub    $0x14,%esp
   14f4d:	8b 45 08             	mov    0x8(%ebp),%eax
   14f50:	88 45 ec             	mov    %al,-0x14(%ebp)
	uint8_t old;

	// remember the current status

	old = ier;
   14f53:	0f b6 05 b0 e1 01 00 	movzbl 0x1e1b0,%eax
   14f5a:	88 45 ff             	mov    %al,-0x1(%ebp)

	// figure out what to enable

	if( which & SIO_TX ) {
   14f5d:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   14f61:	83 e0 01             	and    $0x1,%eax
   14f64:	85 c0                	test   %eax,%eax
   14f66:	74 0f                	je     14f77 <sio_enable+0x30>
		ier |= UA4_IER_TX_IE;
   14f68:	0f b6 05 b0 e1 01 00 	movzbl 0x1e1b0,%eax
   14f6f:	83 c8 02             	or     $0x2,%eax
   14f72:	a2 b0 e1 01 00       	mov    %al,0x1e1b0
	}

	if( which & SIO_RX ) {
   14f77:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   14f7b:	83 e0 02             	and    $0x2,%eax
   14f7e:	85 c0                	test   %eax,%eax
   14f80:	74 0f                	je     14f91 <sio_enable+0x4a>
		ier |= UA4_IER_RX_IE;
   14f82:	0f b6 05 b0 e1 01 00 	movzbl 0x1e1b0,%eax
   14f89:	83 c8 01             	or     $0x1,%eax
   14f8c:	a2 b0 e1 01 00       	mov    %al,0x1e1b0
	}

	// if there was a change, make it

	if( old != ier ) {
   14f91:	0f b6 05 b0 e1 01 00 	movzbl 0x1e1b0,%eax
   14f98:	38 45 ff             	cmp    %al,-0x1(%ebp)
   14f9b:	74 1c                	je     14fb9 <sio_enable+0x72>
		outb( UA4_IER, ier );
   14f9d:	0f b6 05 b0 e1 01 00 	movzbl 0x1e1b0,%eax
   14fa4:	0f b6 c0             	movzbl %al,%eax
   14fa7:	c7 45 f8 f9 03 00 00 	movl   $0x3f9,-0x8(%ebp)
   14fae:	88 45 f7             	mov    %al,-0x9(%ebp)
   14fb1:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
   14fb5:	8b 55 f8             	mov    -0x8(%ebp),%edx
   14fb8:	ee                   	out    %al,(%dx)
	}

	// return the prior settings

	return( old );
   14fb9:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
   14fbd:	c9                   	leave  
   14fbe:	c3                   	ret    

00014fbf <sio_disable>:
**
** @param which   Bit mask indicating which interrupt(s) to disable
**
** @return the prior IER setting
*/
uint8_t sio_disable( uint8_t which ) {
   14fbf:	55                   	push   %ebp
   14fc0:	89 e5                	mov    %esp,%ebp
   14fc2:	83 ec 14             	sub    $0x14,%esp
   14fc5:	8b 45 08             	mov    0x8(%ebp),%eax
   14fc8:	88 45 ec             	mov    %al,-0x14(%ebp)
	uint8_t old;

	// remember the current status

	old = ier;
   14fcb:	0f b6 05 b0 e1 01 00 	movzbl 0x1e1b0,%eax
   14fd2:	88 45 ff             	mov    %al,-0x1(%ebp)

	// figure out what to disable

	if( which & SIO_TX ) {
   14fd5:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   14fd9:	83 e0 01             	and    $0x1,%eax
   14fdc:	85 c0                	test   %eax,%eax
   14fde:	74 0f                	je     14fef <sio_disable+0x30>
		ier &= ~UA4_IER_TX_IE;
   14fe0:	0f b6 05 b0 e1 01 00 	movzbl 0x1e1b0,%eax
   14fe7:	83 e0 fd             	and    $0xfffffffd,%eax
   14fea:	a2 b0 e1 01 00       	mov    %al,0x1e1b0
	}

	if( which & SIO_RX ) {
   14fef:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
   14ff3:	83 e0 02             	and    $0x2,%eax
   14ff6:	85 c0                	test   %eax,%eax
   14ff8:	74 0f                	je     15009 <sio_disable+0x4a>
		ier &= ~UA4_IER_RX_IE;
   14ffa:	0f b6 05 b0 e1 01 00 	movzbl 0x1e1b0,%eax
   15001:	83 e0 fe             	and    $0xfffffffe,%eax
   15004:	a2 b0 e1 01 00       	mov    %al,0x1e1b0
	}

	// if there was a change, make it

	if( old != ier ) {
   15009:	0f b6 05 b0 e1 01 00 	movzbl 0x1e1b0,%eax
   15010:	38 45 ff             	cmp    %al,-0x1(%ebp)
   15013:	74 1c                	je     15031 <sio_disable+0x72>
		outb( UA4_IER, ier );
   15015:	0f b6 05 b0 e1 01 00 	movzbl 0x1e1b0,%eax
   1501c:	0f b6 c0             	movzbl %al,%eax
   1501f:	c7 45 f8 f9 03 00 00 	movl   $0x3f9,-0x8(%ebp)
   15026:	88 45 f7             	mov    %al,-0x9(%ebp)
   15029:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
   1502d:	8b 55 f8             	mov    -0x8(%ebp),%edx
   15030:	ee                   	out    %al,(%dx)
	}

	// return the prior settings

	return( old );
   15031:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
   15035:	c9                   	leave  
   15036:	c3                   	ret    

00015037 <sio_flush>:
**
** Flush the SIO input and/or output.
**
** @param which  Bit mask indicating which queue(s) to flush.
*/
void sio_flush( uint8_t which ) {
   15037:	55                   	push   %ebp
   15038:	89 e5                	mov    %esp,%ebp
   1503a:	83 ec 24             	sub    $0x24,%esp
   1503d:	8b 45 08             	mov    0x8(%ebp),%eax
   15040:	88 45 dc             	mov    %al,-0x24(%ebp)

	if( (which & SIO_RX) != 0 ) {
   15043:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
   15047:	83 e0 02             	and    $0x2,%eax
   1504a:	85 c0                	test   %eax,%eax
   1504c:	74 69                	je     150b7 <sio_flush+0x80>
		// empty the queue
		incount = 0;
   1504e:	c7 05 88 d9 01 00 00 	movl   $0x0,0x1d988
   15055:	00 00 00 
		inlast = innext = inbuffer;
   15058:	c7 05 84 d9 01 00 80 	movl   $0x1d180,0x1d984
   1505f:	d1 01 00 
   15062:	a1 84 d9 01 00       	mov    0x1d984,%eax
   15067:	a3 80 d9 01 00       	mov    %eax,0x1d980
   1506c:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   15073:	8b 45 f8             	mov    -0x8(%ebp),%eax
   15076:	89 c2                	mov    %eax,%edx
   15078:	ec                   	in     (%dx),%al
   15079:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
   1507c:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax

		// discard any characters in the receiver FIFO
		uint8_t lsr = inb( UA4_LSR );
   15080:	88 45 ff             	mov    %al,-0x1(%ebp)
		while( (lsr & UA4_LSR_RXDA) != 0 ) {
   15083:	eb 27                	jmp    150ac <sio_flush+0x75>
   15085:	c7 45 e8 f8 03 00 00 	movl   $0x3f8,-0x18(%ebp)
	__asm__ __volatile__( "inb %w1,%0" : "=a" (data) : "d" (port) );
   1508c:	8b 45 e8             	mov    -0x18(%ebp),%eax
   1508f:	89 c2                	mov    %eax,%edx
   15091:	ec                   	in     (%dx),%al
   15092:	88 45 e7             	mov    %al,-0x19(%ebp)
   15095:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
   1509c:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1509f:	89 c2                	mov    %eax,%edx
   150a1:	ec                   	in     (%dx),%al
   150a2:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
   150a5:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
			(void) inb( UA4_RXD );
			lsr = inb( UA4_LSR );
   150a9:	88 45 ff             	mov    %al,-0x1(%ebp)
		while( (lsr & UA4_LSR_RXDA) != 0 ) {
   150ac:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
   150b0:	83 e0 01             	and    $0x1,%eax
   150b3:	85 c0                	test   %eax,%eax
   150b5:	75 ce                	jne    15085 <sio_flush+0x4e>
		}
	}

	if( (which & SIO_TX) != 0 ) {
   150b7:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
   150bb:	83 e0 01             	and    $0x1,%eax
   150be:	85 c0                	test   %eax,%eax
   150c0:	74 28                	je     150ea <sio_flush+0xb3>
		// empty the queue
		outcount = 0;
   150c2:	c7 05 a8 e1 01 00 00 	movl   $0x0,0x1e1a8
   150c9:	00 00 00 
		outlast = outnext = outbuffer;
   150cc:	c7 05 a4 e1 01 00 a0 	movl   $0x1d9a0,0x1e1a4
   150d3:	d9 01 00 
   150d6:	a1 a4 e1 01 00       	mov    0x1e1a4,%eax
   150db:	a3 a0 e1 01 00       	mov    %eax,0x1e1a0

		// terminate any in-progress send operation
		sending = 0;
   150e0:	c7 05 ac e1 01 00 00 	movl   $0x0,0x1e1ac
   150e7:	00 00 00 
	}
}
   150ea:	90                   	nop
   150eb:	c9                   	leave  
   150ec:	c3                   	ret    

000150ed <sio_inq_length>:
**
** usage:    int num = sio_inq_length()
**
** @return the count of characters still in the input queue
*/
int sio_inq_length( void ) {
   150ed:	55                   	push   %ebp
   150ee:	89 e5                	mov    %esp,%ebp
	return( incount );
   150f0:	a1 88 d9 01 00       	mov    0x1d988,%eax
}
   150f5:	5d                   	pop    %ebp
   150f6:	c3                   	ret    

000150f7 <sio_readc>:
**
** usage:    int ch = sio_readc()
**
** @return the next character, or -1 if no character is available
*/
int sio_readc( void ) {
   150f7:	55                   	push   %ebp
   150f8:	89 e5                	mov    %esp,%ebp
   150fa:	83 ec 10             	sub    $0x10,%esp
	int ch;

	// assume there is no character available
	ch = -1;
   150fd:	c7 45 fc ff ff ff ff 	movl   $0xffffffff,-0x4(%ebp)

	// 
	// If there is a character, return it
	//

	if( incount > 0 ) {
   15104:	a1 88 d9 01 00       	mov    0x1d988,%eax
   15109:	85 c0                	test   %eax,%eax
   1510b:	74 46                	je     15153 <sio_readc+0x5c>

		// take it out of the input buffer
		ch = ((int)(*innext++)) & 0xff;
   1510d:	a1 84 d9 01 00       	mov    0x1d984,%eax
   15112:	8d 50 01             	lea    0x1(%eax),%edx
   15115:	89 15 84 d9 01 00    	mov    %edx,0x1d984
   1511b:	0f b6 00             	movzbl (%eax),%eax
   1511e:	0f be c0             	movsbl %al,%eax
   15121:	25 ff 00 00 00       	and    $0xff,%eax
   15126:	89 45 fc             	mov    %eax,-0x4(%ebp)
		--incount;
   15129:	a1 88 d9 01 00       	mov    0x1d988,%eax
   1512e:	83 e8 01             	sub    $0x1,%eax
   15131:	a3 88 d9 01 00       	mov    %eax,0x1d988

		// reset the buffer variables if this was the last one
		if( incount < 1 ) {
   15136:	a1 88 d9 01 00       	mov    0x1d988,%eax
   1513b:	85 c0                	test   %eax,%eax
   1513d:	75 14                	jne    15153 <sio_readc+0x5c>
			inlast = innext = inbuffer;
   1513f:	c7 05 84 d9 01 00 80 	movl   $0x1d180,0x1d984
   15146:	d1 01 00 
   15149:	a1 84 d9 01 00       	mov    0x1d984,%eax
   1514e:	a3 80 d9 01 00       	mov    %eax,0x1d980
		}

	}

	return( ch );
   15153:	8b 45 fc             	mov    -0x4(%ebp),%eax

}
   15156:	c9                   	leave  
   15157:	c3                   	ret    

00015158 <sio_read>:
** @param length  Length of the buffer
**
** @return the number of bytes copied, or 0 if no characters were available
*/

int sio_read( char *buf, int length ) {
   15158:	55                   	push   %ebp
   15159:	89 e5                	mov    %esp,%ebp
   1515b:	83 ec 10             	sub    $0x10,%esp
	char *ptr = buf;
   1515e:	8b 45 08             	mov    0x8(%ebp),%eax
   15161:	89 45 fc             	mov    %eax,-0x4(%ebp)
	int copied = 0;
   15164:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// if there are no characters, just return 0

	if( incount < 1 ) {
   1516b:	a1 88 d9 01 00       	mov    0x1d988,%eax
   15170:	85 c0                	test   %eax,%eax
   15172:	75 4c                	jne    151c0 <sio_read+0x68>
		return( 0 );
   15174:	b8 00 00 00 00       	mov    $0x0,%eax
   15179:	eb 76                	jmp    151f1 <sio_read+0x99>
	// We have characters.  Copy as many of them into the user
	// buffer as will fit.
	//

	while( incount > 0 && copied < length ) {
		*ptr++ = *innext++ & 0xff;
   1517b:	8b 15 84 d9 01 00    	mov    0x1d984,%edx
   15181:	8d 42 01             	lea    0x1(%edx),%eax
   15184:	a3 84 d9 01 00       	mov    %eax,0x1d984
   15189:	8b 45 fc             	mov    -0x4(%ebp),%eax
   1518c:	8d 48 01             	lea    0x1(%eax),%ecx
   1518f:	89 4d fc             	mov    %ecx,-0x4(%ebp)
   15192:	0f b6 12             	movzbl (%edx),%edx
   15195:	88 10                	mov    %dl,(%eax)
		if( innext > (inbuffer + BUF_SIZE) ) {
   15197:	a1 84 d9 01 00       	mov    0x1d984,%eax
   1519c:	ba 80 d9 01 00       	mov    $0x1d980,%edx
   151a1:	39 d0                	cmp    %edx,%eax
   151a3:	76 0a                	jbe    151af <sio_read+0x57>
			innext = inbuffer;
   151a5:	c7 05 84 d9 01 00 80 	movl   $0x1d180,0x1d984
   151ac:	d1 01 00 
		}
		--incount;
   151af:	a1 88 d9 01 00       	mov    0x1d988,%eax
   151b4:	83 e8 01             	sub    $0x1,%eax
   151b7:	a3 88 d9 01 00       	mov    %eax,0x1d988
		++copied;
   151bc:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
	while( incount > 0 && copied < length ) {
   151c0:	a1 88 d9 01 00       	mov    0x1d988,%eax
   151c5:	85 c0                	test   %eax,%eax
   151c7:	74 08                	je     151d1 <sio_read+0x79>
   151c9:	8b 45 f8             	mov    -0x8(%ebp),%eax
   151cc:	3b 45 0c             	cmp    0xc(%ebp),%eax
   151cf:	7c aa                	jl     1517b <sio_read+0x23>
	}

	// reset the input buffer if necessary

	if( incount < 1 ) {
   151d1:	a1 88 d9 01 00       	mov    0x1d988,%eax
   151d6:	85 c0                	test   %eax,%eax
   151d8:	75 14                	jne    151ee <sio_read+0x96>
		inlast = innext = inbuffer;
   151da:	c7 05 84 d9 01 00 80 	movl   $0x1d180,0x1d984
   151e1:	d1 01 00 
   151e4:	a1 84 d9 01 00       	mov    0x1d984,%eax
   151e9:	a3 80 d9 01 00       	mov    %eax,0x1d980
	}

	// return the copy count

	return( copied );
   151ee:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
   151f1:	c9                   	leave  
   151f2:	c3                   	ret    

000151f3 <sio_writec>:
**
** usage:    sio_writec( int ch )
**
** @param ch   Character to be written (in the low-order 8 bits)
*/
void sio_writec( int ch ){
   151f3:	55                   	push   %ebp
   151f4:	89 e5                	mov    %esp,%ebp
   151f6:	83 ec 18             	sub    $0x18,%esp

	//
	// Must do LF -> CRLF mapping
	//

	if( ch == '\n' ) {
   151f9:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
   151fd:	75 0d                	jne    1520c <sio_writec+0x19>
		sio_writec( '\r' );
   151ff:	83 ec 0c             	sub    $0xc,%esp
   15202:	6a 0d                	push   $0xd
   15204:	e8 ea ff ff ff       	call   151f3 <sio_writec>
   15209:	83 c4 10             	add    $0x10,%esp

	//
	// If we're currently transmitting, just add this to the buffer
	//

	if( sending ) {
   1520c:	a1 ac e1 01 00       	mov    0x1e1ac,%eax
   15211:	85 c0                	test   %eax,%eax
   15213:	74 22                	je     15237 <sio_writec+0x44>
		*outlast++ = ch;
   15215:	a1 a0 e1 01 00       	mov    0x1e1a0,%eax
   1521a:	8d 50 01             	lea    0x1(%eax),%edx
   1521d:	89 15 a0 e1 01 00    	mov    %edx,0x1e1a0
   15223:	8b 55 08             	mov    0x8(%ebp),%edx
   15226:	88 10                	mov    %dl,(%eax)
		++outcount;
   15228:	a1 a8 e1 01 00       	mov    0x1e1a8,%eax
   1522d:	83 c0 01             	add    $0x1,%eax
   15230:	a3 a8 e1 01 00       	mov    %eax,0x1e1a8
		return;
   15235:	eb 2f                	jmp    15266 <sio_writec+0x73>

	//
	// Not sending - must prime the pump
	//

	sending = 1;
   15237:	c7 05 ac e1 01 00 01 	movl   $0x1,0x1e1ac
   1523e:	00 00 00 
	outb( UA4_TXD, ch );
   15241:	8b 45 08             	mov    0x8(%ebp),%eax
   15244:	0f b6 c0             	movzbl %al,%eax
   15247:	c7 45 f4 f8 03 00 00 	movl   $0x3f8,-0xc(%ebp)
   1524e:	88 45 f3             	mov    %al,-0xd(%ebp)
	__asm__ __volatile__( "outb %0,%w1" : : "a" (data), "d" (port) );
   15251:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   15255:	8b 55 f4             	mov    -0xc(%ebp),%edx
   15258:	ee                   	out    %al,(%dx)

	// Also must enable transmitter interrupts

	sio_enable( SIO_TX );
   15259:	83 ec 0c             	sub    $0xc,%esp
   1525c:	6a 01                	push   $0x1
   1525e:	e8 e4 fc ff ff       	call   14f47 <sio_enable>
   15263:	83 c4 10             	add    $0x10,%esp

}
   15266:	c9                   	leave  
   15267:	c3                   	ret    

00015268 <sio_write>:
** @param buffer   Buffer containing characters to write
** @param length   Number of characters to write
**
** @return the number of characters copied into the SIO output buffer
*/
int sio_write( const char *buffer, int length ) {
   15268:	55                   	push   %ebp
   15269:	89 e5                	mov    %esp,%ebp
   1526b:	83 ec 18             	sub    $0x18,%esp
	int first = *buffer;
   1526e:	8b 45 08             	mov    0x8(%ebp),%eax
   15271:	0f b6 00             	movzbl (%eax),%eax
   15274:	0f be c0             	movsbl %al,%eax
   15277:	89 45 ec             	mov    %eax,-0x14(%ebp)
	const char *ptr = buffer;
   1527a:	8b 45 08             	mov    0x8(%ebp),%eax
   1527d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	int copied = 0;
   15280:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	// the characters to the output buffer; else, we want
	// to append all but the first character, and then use
	// sio_writec() to send the first one out.
	//

	if( !sending ) {
   15287:	a1 ac e1 01 00       	mov    0x1e1ac,%eax
   1528c:	85 c0                	test   %eax,%eax
   1528e:	75 4f                	jne    152df <sio_write+0x77>
		ptr += 1;
   15290:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
		copied++;
   15294:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
	}

	while( copied < length && outcount < BUF_SIZE ) {
   15298:	eb 45                	jmp    152df <sio_write+0x77>
		*outlast++ = *ptr++;
   1529a:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1529d:	8d 42 01             	lea    0x1(%edx),%eax
   152a0:	89 45 f4             	mov    %eax,-0xc(%ebp)
   152a3:	a1 a0 e1 01 00       	mov    0x1e1a0,%eax
   152a8:	8d 48 01             	lea    0x1(%eax),%ecx
   152ab:	89 0d a0 e1 01 00    	mov    %ecx,0x1e1a0
   152b1:	0f b6 12             	movzbl (%edx),%edx
   152b4:	88 10                	mov    %dl,(%eax)
		// wrap around if necessary
		if( outlast >= (outbuffer + BUF_SIZE) ) {
   152b6:	a1 a0 e1 01 00       	mov    0x1e1a0,%eax
   152bb:	ba a0 e1 01 00       	mov    $0x1e1a0,%edx
   152c0:	39 d0                	cmp    %edx,%eax
   152c2:	72 0a                	jb     152ce <sio_write+0x66>
			outlast = outbuffer;
   152c4:	c7 05 a0 e1 01 00 a0 	movl   $0x1d9a0,0x1e1a0
   152cb:	d9 01 00 
		}
		++outcount;
   152ce:	a1 a8 e1 01 00       	mov    0x1e1a8,%eax
   152d3:	83 c0 01             	add    $0x1,%eax
   152d6:	a3 a8 e1 01 00       	mov    %eax,0x1e1a8
		++copied;
   152db:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
	while( copied < length && outcount < BUF_SIZE ) {
   152df:	8b 45 f0             	mov    -0x10(%ebp),%eax
   152e2:	3b 45 0c             	cmp    0xc(%ebp),%eax
   152e5:	7d 0c                	jge    152f3 <sio_write+0x8b>
   152e7:	a1 a8 e1 01 00       	mov    0x1e1a8,%eax
   152ec:	3d ff 07 00 00       	cmp    $0x7ff,%eax
   152f1:	76 a7                	jbe    1529a <sio_write+0x32>
	// We use sio_writec() to send out the first character,
	// as it will correctly set all the other necessary
	// variables for us.
	//

	if( !sending ) {
   152f3:	a1 ac e1 01 00       	mov    0x1e1ac,%eax
   152f8:	85 c0                	test   %eax,%eax
   152fa:	75 0e                	jne    1530a <sio_write+0xa2>
		sio_writec( first );
   152fc:	83 ec 0c             	sub    $0xc,%esp
   152ff:	ff 75 ec             	pushl  -0x14(%ebp)
   15302:	e8 ec fe ff ff       	call   151f3 <sio_writec>
   15307:	83 c4 10             	add    $0x10,%esp
	}

	// Return the transfer count


	return( copied );
   1530a:	8b 45 f0             	mov    -0x10(%ebp),%eax

}
   1530d:	c9                   	leave  
   1530e:	c3                   	ret    

0001530f <sio_puts>:
**
** @param buffer  The buffer containing a NUL-terminated string
**
** @return the count of bytes transferred
*/
int sio_puts( const char *buffer ) {
   1530f:	55                   	push   %ebp
   15310:	89 e5                	mov    %esp,%ebp
   15312:	83 ec 18             	sub    $0x18,%esp
	int n;  // must be outside the loop so we can return it

	n = SLENGTH( buffer );
   15315:	83 ec 0c             	sub    $0xc,%esp
   15318:	ff 75 08             	pushl  0x8(%ebp)
   1531b:	e8 3f d7 ff ff       	call   12a5f <strlen>
   15320:	83 c4 10             	add    $0x10,%esp
   15323:	89 45 f4             	mov    %eax,-0xc(%ebp)
	sio_write( buffer, n );
   15326:	83 ec 08             	sub    $0x8,%esp
   15329:	ff 75 f4             	pushl  -0xc(%ebp)
   1532c:	ff 75 08             	pushl  0x8(%ebp)
   1532f:	e8 34 ff ff ff       	call   15268 <sio_write>
   15334:	83 c4 10             	add    $0x10,%esp

	return( n );
   15337:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
   1533a:	c9                   	leave  
   1533b:	c3                   	ret    

0001533c <sio_dump>:
** @param full   Boolean indicating whether or not a "full" dump
**               is being requested (which includes the contents
**               of the queues)
*/

void sio_dump( bool_t full ) {
   1533c:	55                   	push   %ebp
   1533d:	89 e5                	mov    %esp,%ebp
   1533f:	57                   	push   %edi
   15340:	56                   	push   %esi
   15341:	53                   	push   %ebx
   15342:	83 ec 2c             	sub    $0x2c,%esp
   15345:	8b 45 08             	mov    0x8(%ebp),%eax
   15348:	88 45 d4             	mov    %al,-0x2c(%ebp)
	int n;
	char *ptr;

	// dump basic info into the status region

	cio_printf_at( 48, 0,
   1534b:	8b 0d a8 e1 01 00    	mov    0x1e1a8,%ecx
   15351:	8b 15 88 d9 01 00    	mov    0x1d988,%edx
		"SIO: IER %02x (%c%c%c) in %d ot %d",
			((uint32_t)ier) & 0xff, sending ? '*' : '.',
			(ier & UA4_IER_TX_IE) ? 'T' : 't',
			(ier & UA4_IER_RX_IE) ? 'R' : 'r',
   15357:	0f b6 05 b0 e1 01 00 	movzbl 0x1e1b0,%eax
   1535e:	0f b6 c0             	movzbl %al,%eax
   15361:	83 e0 01             	and    $0x1,%eax
	cio_printf_at( 48, 0,
   15364:	85 c0                	test   %eax,%eax
   15366:	74 07                	je     1536f <sio_dump+0x33>
   15368:	bf 52 00 00 00       	mov    $0x52,%edi
   1536d:	eb 05                	jmp    15374 <sio_dump+0x38>
   1536f:	bf 72 00 00 00       	mov    $0x72,%edi
			(ier & UA4_IER_TX_IE) ? 'T' : 't',
   15374:	0f b6 05 b0 e1 01 00 	movzbl 0x1e1b0,%eax
   1537b:	0f b6 c0             	movzbl %al,%eax
   1537e:	83 e0 02             	and    $0x2,%eax
	cio_printf_at( 48, 0,
   15381:	85 c0                	test   %eax,%eax
   15383:	74 07                	je     1538c <sio_dump+0x50>
   15385:	be 54 00 00 00       	mov    $0x54,%esi
   1538a:	eb 05                	jmp    15391 <sio_dump+0x55>
   1538c:	be 74 00 00 00       	mov    $0x74,%esi
			((uint32_t)ier) & 0xff, sending ? '*' : '.',
   15391:	a1 ac e1 01 00       	mov    0x1e1ac,%eax
	cio_printf_at( 48, 0,
   15396:	85 c0                	test   %eax,%eax
   15398:	74 07                	je     153a1 <sio_dump+0x65>
   1539a:	bb 2a 00 00 00       	mov    $0x2a,%ebx
   1539f:	eb 05                	jmp    153a6 <sio_dump+0x6a>
   153a1:	bb 2e 00 00 00       	mov    $0x2e,%ebx
   153a6:	0f b6 05 b0 e1 01 00 	movzbl 0x1e1b0,%eax
   153ad:	0f b6 c0             	movzbl %al,%eax
   153b0:	83 ec 0c             	sub    $0xc,%esp
   153b3:	51                   	push   %ecx
   153b4:	52                   	push   %edx
   153b5:	57                   	push   %edi
   153b6:	56                   	push   %esi
   153b7:	53                   	push   %ebx
   153b8:	50                   	push   %eax
   153b9:	68 98 b5 01 00       	push   $0x1b598
   153be:	6a 00                	push   $0x0
   153c0:	6a 30                	push   $0x30
   153c2:	e8 40 c1 ff ff       	call   11507 <cio_printf_at>
   153c7:	83 c4 30             	add    $0x30,%esp
			incount, outcount );

	// if we're not doing a full dump, stop now

	if( !full ) {
   153ca:	80 7d d4 00          	cmpb   $0x0,-0x2c(%ebp)
   153ce:	0f 84 dc 00 00 00    	je     154b0 <sio_dump+0x174>
	}

	// also want the queue contents, but we'll
	// dump them into the scrolling region

	if( incount ) {
   153d4:	a1 88 d9 01 00       	mov    0x1d988,%eax
   153d9:	85 c0                	test   %eax,%eax
   153db:	74 5c                	je     15439 <sio_dump+0xfd>
		cio_puts( "SIO input queue: \"" );
   153dd:	83 ec 0c             	sub    $0xc,%esp
   153e0:	68 bb b5 01 00       	push   $0x1b5bb
   153e5:	e8 c3 ba ff ff       	call   10ead <cio_puts>
   153ea:	83 c4 10             	add    $0x10,%esp
		ptr = innext; 
   153ed:	a1 84 d9 01 00       	mov    0x1d984,%eax
   153f2:	89 45 e0             	mov    %eax,-0x20(%ebp)
		for( n = 0; n < incount; ++n ) {
   153f5:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   153fc:	eb 1f                	jmp    1541d <sio_dump+0xe1>
			put_char_or_code( *ptr++ );
   153fe:	8b 45 e0             	mov    -0x20(%ebp),%eax
   15401:	8d 50 01             	lea    0x1(%eax),%edx
   15404:	89 55 e0             	mov    %edx,-0x20(%ebp)
   15407:	0f b6 00             	movzbl (%eax),%eax
   1540a:	0f be c0             	movsbl %al,%eax
   1540d:	83 ec 0c             	sub    $0xc,%esp
   15410:	50                   	push   %eax
   15411:	e8 55 cf ff ff       	call   1236b <put_char_or_code>
   15416:	83 c4 10             	add    $0x10,%esp
		for( n = 0; n < incount; ++n ) {
   15419:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   1541d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   15420:	a1 88 d9 01 00       	mov    0x1d988,%eax
   15425:	39 c2                	cmp    %eax,%edx
   15427:	72 d5                	jb     153fe <sio_dump+0xc2>
		}
		cio_puts( "\"\n" );
   15429:	83 ec 0c             	sub    $0xc,%esp
   1542c:	68 ce b5 01 00       	push   $0x1b5ce
   15431:	e8 77 ba ff ff       	call   10ead <cio_puts>
   15436:	83 c4 10             	add    $0x10,%esp
	}

	if( outcount ) {
   15439:	a1 a8 e1 01 00       	mov    0x1e1a8,%eax
   1543e:	85 c0                	test   %eax,%eax
   15440:	74 6f                	je     154b1 <sio_dump+0x175>
		cio_puts( "SIO output queue: \"" );
   15442:	83 ec 0c             	sub    $0xc,%esp
   15445:	68 d1 b5 01 00       	push   $0x1b5d1
   1544a:	e8 5e ba ff ff       	call   10ead <cio_puts>
   1544f:	83 c4 10             	add    $0x10,%esp
		cio_puts( " ot: \"" );
   15452:	83 ec 0c             	sub    $0xc,%esp
   15455:	68 e5 b5 01 00       	push   $0x1b5e5
   1545a:	e8 4e ba ff ff       	call   10ead <cio_puts>
   1545f:	83 c4 10             	add    $0x10,%esp
		ptr = outnext; 
   15462:	a1 a4 e1 01 00       	mov    0x1e1a4,%eax
   15467:	89 45 e0             	mov    %eax,-0x20(%ebp)
		for( n = 0; n < outcount; ++n )  {
   1546a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   15471:	eb 1f                	jmp    15492 <sio_dump+0x156>
			put_char_or_code( *ptr++ );
   15473:	8b 45 e0             	mov    -0x20(%ebp),%eax
   15476:	8d 50 01             	lea    0x1(%eax),%edx
   15479:	89 55 e0             	mov    %edx,-0x20(%ebp)
   1547c:	0f b6 00             	movzbl (%eax),%eax
   1547f:	0f be c0             	movsbl %al,%eax
   15482:	83 ec 0c             	sub    $0xc,%esp
   15485:	50                   	push   %eax
   15486:	e8 e0 ce ff ff       	call   1236b <put_char_or_code>
   1548b:	83 c4 10             	add    $0x10,%esp
		for( n = 0; n < outcount; ++n )  {
   1548e:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   15492:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   15495:	a1 a8 e1 01 00       	mov    0x1e1a8,%eax
   1549a:	39 c2                	cmp    %eax,%edx
   1549c:	72 d5                	jb     15473 <sio_dump+0x137>
		}
		cio_puts( "\"\n" );
   1549e:	83 ec 0c             	sub    $0xc,%esp
   154a1:	68 ce b5 01 00       	push   $0x1b5ce
   154a6:	e8 02 ba ff ff       	call   10ead <cio_puts>
   154ab:	83 c4 10             	add    $0x10,%esp
   154ae:	eb 01                	jmp    154b1 <sio_dump+0x175>
		return;
   154b0:	90                   	nop
	}
}
   154b1:	8d 65 f4             	lea    -0xc(%ebp),%esp
   154b4:	5b                   	pop    %ebx
   154b5:	5e                   	pop    %esi
   154b6:	5f                   	pop    %edi
   154b7:	5d                   	pop    %ebp
   154b8:	c3                   	ret    

000154b9 <unexpected_handler>:
** @param vector   vector number for the interrupt that occurred
** @param code     error code, or a dummy value
**
** Does not return.
*/
static void unexpected_handler( int vector, int code ) {
   154b9:	55                   	push   %ebp
   154ba:	89 e5                	mov    %esp,%ebp
   154bc:	83 ec 08             	sub    $0x8,%esp
#ifdef RPT_INT_UNEXP
	cio_printf( "\n** UNEXPECTED vector %d code %d\n", vector, code );
   154bf:	83 ec 04             	sub    $0x4,%esp
   154c2:	ff 75 0c             	pushl  0xc(%ebp)
   154c5:	ff 75 08             	pushl  0x8(%ebp)
   154c8:	68 f4 b5 01 00       	push   $0x1b5f4
   154cd:	e8 55 c0 ff ff       	call   11527 <cio_printf>
   154d2:	83 c4 10             	add    $0x10,%esp
#endif
	panic( "Unexpected interrupt" );
   154d5:	83 ec 0c             	sub    $0xc,%esp
   154d8:	68 16 b6 01 00       	push   $0x1b616
   154dd:	e8 50 02 00 00       	call   15732 <panic>
   154e2:	83 c4 10             	add    $0x10,%esp
}
   154e5:	90                   	nop
   154e6:	c9                   	leave  
   154e7:	c3                   	ret    

000154e8 <default_handler>:
** handling (yet).  We just reset the PIC and return.
**
** @param vector   vector number for the interrupt that occurred
** @param code     error code, or a dummy value
*/
static void default_handler( int vector, int code ) {
   154e8:	55                   	push   %ebp
   154e9:	89 e5                	mov    %esp,%ebp
   154eb:	83 ec 18             	sub    $0x18,%esp
#ifdef RPT_INT_UNEXP
	cio_printf( "\n** vector %d code %d\n", vector, code );
   154ee:	83 ec 04             	sub    $0x4,%esp
   154f1:	ff 75 0c             	pushl  0xc(%ebp)
   154f4:	ff 75 08             	pushl  0x8(%ebp)
   154f7:	68 2b b6 01 00       	push   $0x1b62b
   154fc:	e8 26 c0 ff ff       	call   11527 <cio_printf>
   15501:	83 c4 10             	add    $0x10,%esp
#endif
	if( vector >= 0x20 && vector < 0x30 ) {
   15504:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
   15508:	7e 34                	jle    1553e <default_handler+0x56>
   1550a:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
   1550e:	7f 2e                	jg     1553e <default_handler+0x56>
		if( vector > 0x27 ) {
   15510:	83 7d 08 27          	cmpl   $0x27,0x8(%ebp)
   15514:	7e 13                	jle    15529 <default_handler+0x41>
   15516:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
   1551d:	c6 45 f3 20          	movb   $0x20,-0xd(%ebp)
   15521:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   15525:	8b 55 f4             	mov    -0xc(%ebp),%edx
   15528:	ee                   	out    %al,(%dx)
   15529:	c7 45 ec 20 00 00 00 	movl   $0x20,-0x14(%ebp)
   15530:	c6 45 eb 20          	movb   $0x20,-0x15(%ebp)
   15534:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   15538:	8b 55 ec             	mov    -0x14(%ebp),%edx
   1553b:	ee                   	out    %al,(%dx)
			// must also ACK the secondary PIC
			outb( PIC2_CMD, PIC_EOI );
		}
		outb( PIC1_CMD, PIC_EOI );
   1553c:	eb 10                	jmp    1554e <default_handler+0x66>
		/*
		** All the "expected" interrupts will be handled by the
		** code above.  If we get down here, the isr table may
		** have been corrupted.  Print a message and don't return.
		*/
		panic( "Unexpected \"expected\" interrupt!" );
   1553e:	83 ec 0c             	sub    $0xc,%esp
   15541:	68 44 b6 01 00       	push   $0x1b644
   15546:	e8 e7 01 00 00       	call   15732 <panic>
   1554b:	83 c4 10             	add    $0x10,%esp
	}
}
   1554e:	90                   	nop
   1554f:	c9                   	leave  
   15550:	c3                   	ret    

00015551 <mystery_handler>:
** source.
**
** @param vector   vector number for the interrupt that occurred
** @param code     error code, or a dummy value
*/
static void mystery_handler( int vector, int code ) {
   15551:	55                   	push   %ebp
   15552:	89 e5                	mov    %esp,%ebp
   15554:	83 ec 18             	sub    $0x18,%esp
#if defined(RPT_INT_MYSTERY) || defined(RPT_INT_UNEXP)
	cio_printf( "\nMystery interrupt!\nVector=0x%02x, code=%d\n",
   15557:	83 ec 04             	sub    $0x4,%esp
   1555a:	ff 75 0c             	pushl  0xc(%ebp)
   1555d:	ff 75 08             	pushl  0x8(%ebp)
   15560:	68 68 b6 01 00       	push   $0x1b668
   15565:	e8 bd bf ff ff       	call   11527 <cio_printf>
   1556a:	83 c4 10             	add    $0x10,%esp
   1556d:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
   15574:	c6 45 f3 20          	movb   $0x20,-0xd(%ebp)
   15578:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   1557c:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1557f:	ee                   	out    %al,(%dx)
		  vector, code );
#endif
	outb( PIC1_CMD, PIC_EOI );
}
   15580:	90                   	nop
   15581:	c9                   	leave  
   15582:	c3                   	ret    

00015583 <init_pic>:
/**
** init_pic
**
** Initialize the 8259 Programmable Interrupt Controller.
*/
static void init_pic( void ) {
   15583:	55                   	push   %ebp
   15584:	89 e5                	mov    %esp,%ebp
   15586:	83 ec 50             	sub    $0x50,%esp
   15589:	c7 45 b4 20 00 00 00 	movl   $0x20,-0x4c(%ebp)
   15590:	c6 45 b3 11          	movb   $0x11,-0x4d(%ebp)
   15594:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
   15598:	8b 55 b4             	mov    -0x4c(%ebp),%edx
   1559b:	ee                   	out    %al,(%dx)
   1559c:	c7 45 bc a0 00 00 00 	movl   $0xa0,-0x44(%ebp)
   155a3:	c6 45 bb 11          	movb   $0x11,-0x45(%ebp)
   155a7:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
   155ab:	8b 55 bc             	mov    -0x44(%ebp),%edx
   155ae:	ee                   	out    %al,(%dx)
   155af:	c7 45 c4 21 00 00 00 	movl   $0x21,-0x3c(%ebp)
   155b6:	c6 45 c3 20          	movb   $0x20,-0x3d(%ebp)
   155ba:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
   155be:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   155c1:	ee                   	out    %al,(%dx)
   155c2:	c7 45 cc a1 00 00 00 	movl   $0xa1,-0x34(%ebp)
   155c9:	c6 45 cb 28          	movb   $0x28,-0x35(%ebp)
   155cd:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
   155d1:	8b 55 cc             	mov    -0x34(%ebp),%edx
   155d4:	ee                   	out    %al,(%dx)
   155d5:	c7 45 d4 21 00 00 00 	movl   $0x21,-0x2c(%ebp)
   155dc:	c6 45 d3 04          	movb   $0x4,-0x2d(%ebp)
   155e0:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
   155e4:	8b 55 d4             	mov    -0x2c(%ebp),%edx
   155e7:	ee                   	out    %al,(%dx)
   155e8:	c7 45 dc a1 00 00 00 	movl   $0xa1,-0x24(%ebp)
   155ef:	c6 45 db 02          	movb   $0x2,-0x25(%ebp)
   155f3:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   155f7:	8b 55 dc             	mov    -0x24(%ebp),%edx
   155fa:	ee                   	out    %al,(%dx)
   155fb:	c7 45 e4 21 00 00 00 	movl   $0x21,-0x1c(%ebp)
   15602:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
   15606:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
   1560a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
   1560d:	ee                   	out    %al,(%dx)
   1560e:	c7 45 ec a1 00 00 00 	movl   $0xa1,-0x14(%ebp)
   15615:	c6 45 eb 01          	movb   $0x1,-0x15(%ebp)
   15619:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
   1561d:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15620:	ee                   	out    %al,(%dx)
   15621:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
   15628:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)
   1562c:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   15630:	8b 55 f4             	mov    -0xc(%ebp),%edx
   15633:	ee                   	out    %al,(%dx)
   15634:	c7 45 fc a1 00 00 00 	movl   $0xa1,-0x4(%ebp)
   1563b:	c6 45 fb 00          	movb   $0x0,-0x5(%ebp)
   1563f:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
   15643:	8b 55 fc             	mov    -0x4(%ebp),%edx
   15646:	ee                   	out    %al,(%dx)
	/*
	** OCW1: allow interrupts on all lines
	*/
	outb( PIC1_DATA, PIC_MASK_NONE );
	outb( PIC2_DATA, PIC_MASK_NONE );
}
   15647:	90                   	nop
   15648:	c9                   	leave  
   15649:	c3                   	ret    

0001564a <set_idt_entry>:
** @param handler  ISR address to be put into the IDT entry
**
** Note: generally, the handler invoked from the IDT will be a "stub"
** that calls the second-level C handler via the isr_table array.
*/
static void set_idt_entry( int entry, void ( *handler )( void ) ) {
   1564a:	55                   	push   %ebp
   1564b:	89 e5                	mov    %esp,%ebp
   1564d:	83 ec 10             	sub    $0x10,%esp
	IDT_Gate *g = (IDT_Gate *)IDT_ADDR + entry;
   15650:	8b 45 08             	mov    0x8(%ebp),%eax
   15653:	c1 e0 03             	shl    $0x3,%eax
   15656:	05 00 25 00 00       	add    $0x2500,%eax
   1565b:	89 45 fc             	mov    %eax,-0x4(%ebp)

	g->offset_15_0 = (int)handler & 0xffff;
   1565e:	8b 45 0c             	mov    0xc(%ebp),%eax
   15661:	89 c2                	mov    %eax,%edx
   15663:	8b 45 fc             	mov    -0x4(%ebp),%eax
   15666:	66 89 10             	mov    %dx,(%eax)
	g->segment_selector = 0x0010;
   15669:	8b 45 fc             	mov    -0x4(%ebp),%eax
   1566c:	66 c7 40 02 10 00    	movw   $0x10,0x2(%eax)
	g->flags = IDT_PRESENT | IDT_DPL_0 | IDT_INT32_GATE;
   15672:	8b 45 fc             	mov    -0x4(%ebp),%eax
   15675:	66 c7 40 04 00 8e    	movw   $0x8e00,0x4(%eax)
	g->offset_31_16 = (int)handler >> 16 & 0xffff;
   1567b:	8b 45 0c             	mov    0xc(%ebp),%eax
   1567e:	c1 e8 10             	shr    $0x10,%eax
   15681:	89 c2                	mov    %eax,%edx
   15683:	8b 45 fc             	mov    -0x4(%ebp),%eax
   15686:	66 89 50 06          	mov    %dx,0x6(%eax)
}
   1568a:	90                   	nop
   1568b:	c9                   	leave  
   1568c:	c3                   	ret    

0001568d <init_idt>:
** the entries in the IDT point to the isr stub for that entry, and
** installs a default handler in the handler table.  Temporary handlers
** are then installed for those interrupts we may get before a real
** handler is set up.
*/
static void init_idt( void ) {
   1568d:	55                   	push   %ebp
   1568e:	89 e5                	mov    %esp,%ebp
   15690:	83 ec 18             	sub    $0x18,%esp

	/*
	** Make each IDT entry point to the stub for that vector.  Also
	** make each entry in the ISR table point to the default handler.
	*/
	for ( i=0; i < N_EXCEPTIONS; i++ ) {
   15693:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   1569a:	eb 2d                	jmp    156c9 <init_idt+0x3c>
		set_idt_entry( i, isr_stub_table[ i ] );
   1569c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1569f:	8b 04 85 96 a3 01 00 	mov    0x1a396(,%eax,4),%eax
   156a6:	50                   	push   %eax
   156a7:	ff 75 f4             	pushl  -0xc(%ebp)
   156aa:	e8 9b ff ff ff       	call   1564a <set_idt_entry>
   156af:	83 c4 08             	add    $0x8,%esp
		install_isr( i, unexpected_handler );
   156b2:	83 ec 08             	sub    $0x8,%esp
   156b5:	68 b9 54 01 00       	push   $0x154b9
   156ba:	ff 75 f4             	pushl  -0xc(%ebp)
   156bd:	e8 9f 00 00 00       	call   15761 <install_isr>
   156c2:	83 c4 10             	add    $0x10,%esp
	for ( i=0; i < N_EXCEPTIONS; i++ ) {
   156c5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   156c9:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
   156d0:	7e ca                	jle    1569c <init_idt+0xf>
	** Install the handlers for interrupts that have (or will have) a
	** specific handler. Comments indicate which module init function
	** will eventually install the "real" handler.
	*/

	install_isr( VEC_KBD, default_handler );         // cio_init()
   156d2:	83 ec 08             	sub    $0x8,%esp
   156d5:	68 e8 54 01 00       	push   $0x154e8
   156da:	6a 21                	push   $0x21
   156dc:	e8 80 00 00 00       	call   15761 <install_isr>
   156e1:	83 c4 10             	add    $0x10,%esp
	install_isr( VEC_COM1, default_handler );        // sio_init()
   156e4:	83 ec 08             	sub    $0x8,%esp
   156e7:	68 e8 54 01 00       	push   $0x154e8
   156ec:	6a 24                	push   $0x24
   156ee:	e8 6e 00 00 00       	call   15761 <install_isr>
   156f3:	83 c4 10             	add    $0x10,%esp
	install_isr( VEC_TIMER, default_handler );       // clk_init()
   156f6:	83 ec 08             	sub    $0x8,%esp
   156f9:	68 e8 54 01 00       	push   $0x154e8
   156fe:	6a 20                	push   $0x20
   15700:	e8 5c 00 00 00       	call   15761 <install_isr>
   15705:	83 c4 10             	add    $0x10,%esp
	install_isr( VEC_SYSCALL, default_handler );     // sys_init()
   15708:	83 ec 08             	sub    $0x8,%esp
   1570b:	68 e8 54 01 00       	push   $0x154e8
   15710:	68 80 00 00 00       	push   $0x80
   15715:	e8 47 00 00 00       	call   15761 <install_isr>
   1571a:	83 c4 10             	add    $0x10,%esp
	// install_isr( VEC_PAGE_FAULT, default_handler );  // vm_init()

	install_isr( VEC_MYSTERY, mystery_handler );
   1571d:	83 ec 08             	sub    $0x8,%esp
   15720:	68 51 55 01 00       	push   $0x15551
   15725:	6a 27                	push   $0x27
   15727:	e8 35 00 00 00       	call   15761 <install_isr>
   1572c:	83 c4 10             	add    $0x10,%esp
}
   1572f:	90                   	nop
   15730:	c9                   	leave  
   15731:	c3                   	ret    

00015732 <panic>:
/*
** panic
**
** Called when we find an unrecoverable error.
*/
void panic( char *reason ) {
   15732:	55                   	push   %ebp
   15733:	89 e5                	mov    %esp,%ebp
   15735:	83 ec 08             	sub    $0x8,%esp
	__asm__( "cli" );
   15738:	fa                   	cli    
	cio_printf( "\nPANIC: %s\nHalting...", reason );
   15739:	83 ec 08             	sub    $0x8,%esp
   1573c:	ff 75 08             	pushl  0x8(%ebp)
   1573f:	68 94 b6 01 00       	push   $0x1b694
   15744:	e8 de bd ff ff       	call   11527 <cio_printf>
   15749:	83 c4 10             	add    $0x10,%esp
	for(;;) {
   1574c:	eb fe                	jmp    1574c <panic+0x1a>

0001574e <init_interrupts>:
/*
** init_interrupts
**
** (Re)initilizes the interrupt system.
*/
void init_interrupts( void ) {
   1574e:	55                   	push   %ebp
   1574f:	89 e5                	mov    %esp,%ebp
   15751:	83 ec 08             	sub    $0x8,%esp
	init_idt();
   15754:	e8 34 ff ff ff       	call   1568d <init_idt>
	init_pic();
   15759:	e8 25 fe ff ff       	call   15583 <init_pic>
}
   1575e:	90                   	nop
   1575f:	c9                   	leave  
   15760:	c3                   	ret    

00015761 <install_isr>:
** install_isr
**
** Installs a second-level handler for a specific interrupt.
*/
void (*install_isr( int vector,
		void (*handler)(int,int) ) ) ( int, int ) {
   15761:	55                   	push   %ebp
   15762:	89 e5                	mov    %esp,%ebp
   15764:	83 ec 10             	sub    $0x10,%esp

	void ( *old_handler )( int vector, int code );

	old_handler = isr_table[ vector ];
   15767:	8b 45 08             	mov    0x8(%ebp),%eax
   1576a:	8b 04 85 e0 14 02 00 	mov    0x214e0(,%eax,4),%eax
   15771:	89 45 fc             	mov    %eax,-0x4(%ebp)
	isr_table[ vector ] = handler;
   15774:	8b 45 08             	mov    0x8(%ebp),%eax
   15777:	8b 55 0c             	mov    0xc(%ebp),%edx
   1577a:	89 14 85 e0 14 02 00 	mov    %edx,0x214e0(,%eax,4)
	return old_handler;
   15781:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   15784:	c9                   	leave  
   15785:	c3                   	ret    

00015786 <delay>:
** On the current machines (Intel Core i5-7500), delay(100) is about
** 2.5 seconds, so each "unit" is roughly 0.025 seconds.
**
** Ultimately, just remember that DELAY VALUES ARE APPROXIMATE AT BEST.
*/
void delay( int length ) {
   15786:	55                   	push   %ebp
   15787:	89 e5                	mov    %esp,%ebp
   15789:	83 ec 10             	sub    $0x10,%esp

	while( --length >= 0 ) {
   1578c:	eb 16                	jmp    157a4 <delay+0x1e>
		for( int i = 0; i < 10000000; ++i )
   1578e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   15795:	eb 04                	jmp    1579b <delay+0x15>
   15797:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   1579b:	81 7d fc 7f 96 98 00 	cmpl   $0x98967f,-0x4(%ebp)
   157a2:	7e f3                	jle    15797 <delay+0x11>
	while( --length >= 0 ) {
   157a4:	83 6d 08 01          	subl   $0x1,0x8(%ebp)
   157a8:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   157ac:	79 e0                	jns    1578e <delay+0x8>
			;
	}
}
   157ae:	90                   	nop
   157af:	c9                   	leave  
   157b0:	c3                   	ret    

000157b1 <sys_exit>:
** Implements:
**		void exit( int32_t status );
**
** Does not return
*/
SYSIMPL(exit) {
   157b1:	55                   	push   %ebp
   157b2:	89 e5                	mov    %esp,%ebp
   157b4:	83 ec 08             	sub    $0x8,%esp

	// sanity check
	assert( pcb != NULL );
   157b7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   157bb:	75 38                	jne    157f5 <sys_exit+0x44>
   157bd:	83 ec 04             	sub    $0x4,%esp
   157c0:	68 c0 b6 01 00       	push   $0x1b6c0
   157c5:	6a 00                	push   $0x0
   157c7:	6a 65                	push   $0x65
   157c9:	68 c9 b6 01 00       	push   $0x1b6c9
   157ce:	68 7c b8 01 00       	push   $0x1b87c
   157d3:	68 d4 b6 01 00       	push   $0x1b6d4
   157d8:	68 00 f0 01 00       	push   $0x1f000
   157dd:	e8 00 cf ff ff       	call   126e2 <sprint>
   157e2:	83 c4 20             	add    $0x20,%esp
   157e5:	83 ec 0c             	sub    $0xc,%esp
   157e8:	68 00 f0 01 00       	push   $0x1f000
   157ed:	e8 70 cc ff ff       	call   12462 <kpanic>
   157f2:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   157f5:	a1 e0 18 02 00       	mov    0x218e0,%eax
   157fa:	85 c0                	test   %eax,%eax
   157fc:	74 1c                	je     1581a <sys_exit+0x69>
   157fe:	8b 45 08             	mov    0x8(%ebp),%eax
   15801:	8b 40 18             	mov    0x18(%eax),%eax
   15804:	83 ec 04             	sub    $0x4,%esp
   15807:	50                   	push   %eax
   15808:	68 7c b8 01 00       	push   $0x1b87c
   1580d:	68 ea b6 01 00       	push   $0x1b6ea
   15812:	e8 10 bd ff ff       	call   11527 <cio_printf>
   15817:	83 c4 10             	add    $0x10,%esp

	// retrieve the exit status of this process
	pcb->exit_status = (int32_t) ARG(pcb,1);
   1581a:	8b 45 08             	mov    0x8(%ebp),%eax
   1581d:	8b 00                	mov    (%eax),%eax
   1581f:	83 c0 48             	add    $0x48,%eax
   15822:	83 c0 04             	add    $0x4,%eax
   15825:	8b 00                	mov    (%eax),%eax
   15827:	89 c2                	mov    %eax,%edx
   15829:	8b 45 08             	mov    0x8(%ebp),%eax
   1582c:	89 50 14             	mov    %edx,0x14(%eax)

	// now, we need to do the following:
	// 	reparent any children of this process and wake up init if need be
	// 	find this process' parent and wake it up if it's waiting
	
	pcb_zombify( pcb );
   1582f:	83 ec 0c             	sub    $0xc,%esp
   15832:	ff 75 08             	pushl  0x8(%ebp)
   15835:	e8 b3 e1 ff ff       	call   139ed <pcb_zombify>
   1583a:	83 c4 10             	add    $0x10,%esp

	// pick a new winner
	current = NULL;
   1583d:	c7 05 14 10 02 00 00 	movl   $0x0,0x21014
   15844:	00 00 00 
	dispatch();
   15847:	e8 1f ec ff ff       	call   1446b <dispatch>

	SYSCALL_EXIT( 0 );
   1584c:	a1 e0 18 02 00       	mov    0x218e0,%eax
   15851:	85 c0                	test   %eax,%eax
   15853:	74 18                	je     1586d <sys_exit+0xbc>
   15855:	83 ec 04             	sub    $0x4,%esp
   15858:	6a 00                	push   $0x0
   1585a:	68 7c b8 01 00       	push   $0x1b87c
   1585f:	68 fb b6 01 00       	push   $0x1b6fb
   15864:	e8 be bc ff ff       	call   11527 <cio_printf>
   15869:	83 c4 10             	add    $0x10,%esp
	return;
   1586c:	90                   	nop
   1586d:	90                   	nop
}
   1586e:	c9                   	leave  
   1586f:	c3                   	ret    

00015870 <sys_waitpid>:
** Blocks the calling process until the specified child (or any child)
** of the caller terminates. Intrinsic return is the PID of the child that
** terminated, or an error code; on success, returns the child's termination
** status via 'status' if that pointer is non-NULL.
*/
SYSIMPL(waitpid) {
   15870:	55                   	push   %ebp
   15871:	89 e5                	mov    %esp,%ebp
   15873:	53                   	push   %ebx
   15874:	83 ec 24             	sub    $0x24,%esp

	// sanity check
	assert( pcb != NULL );
   15877:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1587b:	75 3b                	jne    158b8 <sys_waitpid+0x48>
   1587d:	83 ec 04             	sub    $0x4,%esp
   15880:	68 c0 b6 01 00       	push   $0x1b6c0
   15885:	6a 00                	push   $0x0
   15887:	68 88 00 00 00       	push   $0x88
   1588c:	68 c9 b6 01 00       	push   $0x1b6c9
   15891:	68 88 b8 01 00       	push   $0x1b888
   15896:	68 d4 b6 01 00       	push   $0x1b6d4
   1589b:	68 00 f0 01 00       	push   $0x1f000
   158a0:	e8 3d ce ff ff       	call   126e2 <sprint>
   158a5:	83 c4 20             	add    $0x20,%esp
   158a8:	83 ec 0c             	sub    $0xc,%esp
   158ab:	68 00 f0 01 00       	push   $0x1f000
   158b0:	e8 ad cb ff ff       	call   12462 <kpanic>
   158b5:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   158b8:	a1 e0 18 02 00       	mov    0x218e0,%eax
   158bd:	85 c0                	test   %eax,%eax
   158bf:	74 1c                	je     158dd <sys_waitpid+0x6d>
   158c1:	8b 45 08             	mov    0x8(%ebp),%eax
   158c4:	8b 40 18             	mov    0x18(%eax),%eax
   158c7:	83 ec 04             	sub    $0x4,%esp
   158ca:	50                   	push   %eax
   158cb:	68 88 b8 01 00       	push   $0x1b888
   158d0:	68 ea b6 01 00       	push   $0x1b6ea
   158d5:	e8 4d bc ff ff       	call   11527 <cio_printf>
   158da:	83 c4 10             	add    $0x10,%esp
	** we reap here; there could be several, but we only need to
	** find one.
	*/

	// verify that we aren't looking for ourselves!
	uint_t target = ARG(pcb,1);
   158dd:	8b 45 08             	mov    0x8(%ebp),%eax
   158e0:	8b 00                	mov    (%eax),%eax
   158e2:	83 c0 48             	add    $0x48,%eax
   158e5:	8b 40 04             	mov    0x4(%eax),%eax
   158e8:	89 45 e8             	mov    %eax,-0x18(%ebp)

	if( target == pcb->pid ) {
   158eb:	8b 45 08             	mov    0x8(%ebp),%eax
   158ee:	8b 40 18             	mov    0x18(%eax),%eax
   158f1:	39 45 e8             	cmp    %eax,-0x18(%ebp)
   158f4:	75 35                	jne    1592b <sys_waitpid+0xbb>
		RET(pcb) = E_BAD_PARAM;
   158f6:	8b 45 08             	mov    0x8(%ebp),%eax
   158f9:	8b 00                	mov    (%eax),%eax
   158fb:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
		SYSCALL_EXIT( E_BAD_PARAM );
   15902:	a1 e0 18 02 00       	mov    0x218e0,%eax
   15907:	85 c0                	test   %eax,%eax
   15909:	0f 84 55 02 00 00    	je     15b64 <sys_waitpid+0x2f4>
   1590f:	83 ec 04             	sub    $0x4,%esp
   15912:	6a fe                	push   $0xfffffffe
   15914:	68 88 b8 01 00       	push   $0x1b888
   15919:	68 fb b6 01 00       	push   $0x1b6fb
   1591e:	e8 04 bc ff ff       	call   11527 <cio_printf>
   15923:	83 c4 10             	add    $0x10,%esp
		return;
   15926:	e9 39 02 00 00       	jmp    15b64 <sys_waitpid+0x2f4>
	}

	// Good.  Now, figure out what we're looking for.

	pcb_t *child = NULL;
   1592b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if( target != 0 ) {
   15932:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
   15936:	0f 84 a7 00 00 00    	je     159e3 <sys_waitpid+0x173>

		// we're looking for a specific child
		child = pcb_find_pid( target );
   1593c:	83 ec 0c             	sub    $0xc,%esp
   1593f:	ff 75 e8             	pushl  -0x18(%ebp)
   15942:	e8 67 e3 ff ff       	call   13cae <pcb_find_pid>
   15947:	83 c4 10             	add    $0x10,%esp
   1594a:	89 45 f4             	mov    %eax,-0xc(%ebp)

		if( child != NULL ) {
   1594d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15951:	74 5b                	je     159ae <sys_waitpid+0x13e>

			// found the process; is it one of our children:
			if( child->parent != pcb ) {
   15953:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15956:	8b 40 0c             	mov    0xc(%eax),%eax
   15959:	39 45 08             	cmp    %eax,0x8(%ebp)
   1595c:	74 35                	je     15993 <sys_waitpid+0x123>
				// NO, so we can't wait for it
				RET(pcb) = E_BAD_PARAM;
   1595e:	8b 45 08             	mov    0x8(%ebp),%eax
   15961:	8b 00                	mov    (%eax),%eax
   15963:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
				SYSCALL_EXIT( E_BAD_PARAM );
   1596a:	a1 e0 18 02 00       	mov    0x218e0,%eax
   1596f:	85 c0                	test   %eax,%eax
   15971:	0f 84 f0 01 00 00    	je     15b67 <sys_waitpid+0x2f7>
   15977:	83 ec 04             	sub    $0x4,%esp
   1597a:	6a fe                	push   $0xfffffffe
   1597c:	68 88 b8 01 00       	push   $0x1b888
   15981:	68 fb b6 01 00       	push   $0x1b6fb
   15986:	e8 9c bb ff ff       	call   11527 <cio_printf>
   1598b:	83 c4 10             	add    $0x10,%esp
				return;
   1598e:	e9 d4 01 00 00       	jmp    15b67 <sys_waitpid+0x2f7>
			}

			// yes!  is this one ready to be collected?
			if( child->state != STATE_ZOMBIE ) {
   15993:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15996:	8b 40 1c             	mov    0x1c(%eax),%eax
   15999:	83 f8 08             	cmp    $0x8,%eax
   1599c:	0f 84 bb 00 00 00    	je     15a5d <sys_waitpid+0x1ed>
				// no, so we'll have to block for now
				child = NULL;
   159a2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   159a9:	e9 af 00 00 00       	jmp    15a5d <sys_waitpid+0x1ed>
			}

		} else {

			// no such child
			RET(pcb) = E_BAD_PARAM;
   159ae:	8b 45 08             	mov    0x8(%ebp),%eax
   159b1:	8b 00                	mov    (%eax),%eax
   159b3:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
			SYSCALL_EXIT( E_BAD_PARAM );
   159ba:	a1 e0 18 02 00       	mov    0x218e0,%eax
   159bf:	85 c0                	test   %eax,%eax
   159c1:	0f 84 a3 01 00 00    	je     15b6a <sys_waitpid+0x2fa>
   159c7:	83 ec 04             	sub    $0x4,%esp
   159ca:	6a fe                	push   $0xfffffffe
   159cc:	68 88 b8 01 00       	push   $0x1b888
   159d1:	68 fb b6 01 00       	push   $0x1b6fb
   159d6:	e8 4c bb ff ff       	call   11527 <cio_printf>
   159db:	83 c4 10             	add    $0x10,%esp
			return;
   159de:	e9 87 01 00 00       	jmp    15b6a <sys_waitpid+0x2fa>
		// looking for any child

		// we need to find a process that is our child
		// and has already exited

		child = NULL;
   159e3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
		bool_t found = false;
   159ea:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)

		// unfortunately, we can't stop at the first child,
		// so we need to do the iteration ourselves
		register pcb_t *curr = ptable;
   159ee:	bb 20 10 02 00       	mov    $0x21020,%ebx

		for( int i = 0; i < N_PROCS; ++i, ++curr ) {
   159f3:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   159fa:	eb 20                	jmp    15a1c <sys_waitpid+0x1ac>

			if( curr->parent == pcb ) {
   159fc:	8b 43 0c             	mov    0xc(%ebx),%eax
   159ff:	39 45 08             	cmp    %eax,0x8(%ebp)
   15a02:	75 11                	jne    15a15 <sys_waitpid+0x1a5>

				// found one!
				found = true;
   15a04:	c6 45 f3 01          	movb   $0x1,-0xd(%ebp)

				// has it already exited?
				if( curr->state == STATE_ZOMBIE ) {
   15a08:	8b 43 1c             	mov    0x1c(%ebx),%eax
   15a0b:	83 f8 08             	cmp    $0x8,%eax
   15a0e:	75 05                	jne    15a15 <sys_waitpid+0x1a5>
					// yes, so we're done here
					child = curr;
   15a10:	89 5d f4             	mov    %ebx,-0xc(%ebp)
					break;
   15a13:	eb 0d                	jmp    15a22 <sys_waitpid+0x1b2>
		for( int i = 0; i < N_PROCS; ++i, ++curr ) {
   15a15:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   15a19:	83 c3 30             	add    $0x30,%ebx
   15a1c:	83 7d ec 18          	cmpl   $0x18,-0x14(%ebp)
   15a20:	7e da                	jle    159fc <sys_waitpid+0x18c>
				}
			}
		}

		if( !found ) {
   15a22:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   15a26:	75 35                	jne    15a5d <sys_waitpid+0x1ed>
			// got through the loop without finding a child!
			RET(pcb) = E_NO_CHILDREN;
   15a28:	8b 45 08             	mov    0x8(%ebp),%eax
   15a2b:	8b 00                	mov    (%eax),%eax
   15a2d:	c7 40 30 fc ff ff ff 	movl   $0xfffffffc,0x30(%eax)
			SYSCALL_EXIT( E_NO_CHILDREN );
   15a34:	a1 e0 18 02 00       	mov    0x218e0,%eax
   15a39:	85 c0                	test   %eax,%eax
   15a3b:	0f 84 2c 01 00 00    	je     15b6d <sys_waitpid+0x2fd>
   15a41:	83 ec 04             	sub    $0x4,%esp
   15a44:	6a fc                	push   $0xfffffffc
   15a46:	68 88 b8 01 00       	push   $0x1b888
   15a4b:	68 fb b6 01 00       	push   $0x1b6fb
   15a50:	e8 d2 ba ff ff       	call   11527 <cio_printf>
   15a55:	83 c4 10             	add    $0x10,%esp
			return;
   15a58:	e9 10 01 00 00       	jmp    15b6d <sys_waitpid+0x2fd>
	** case, we collect its status and clean it up; otherwise,
	** we block this process.
	*/

	// did we find one to collect?
	if( child == NULL ) {
   15a5d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15a61:	0f 85 96 00 00 00    	jne    15afd <sys_waitpid+0x28d>

		// no - mark the parent as "Waiting"
		pcb->state = STATE_WAITING;
   15a67:	8b 45 08             	mov    0x8(%ebp),%eax
   15a6a:	c7 40 1c 06 00 00 00 	movl   $0x6,0x1c(%eax)
		assert( pcb_queue_insert(waiting,pcb) == SUCCESS );
   15a71:	a1 10 10 02 00       	mov    0x21010,%eax
   15a76:	83 ec 08             	sub    $0x8,%esp
   15a79:	ff 75 08             	pushl  0x8(%ebp)
   15a7c:	50                   	push   %eax
   15a7d:	e8 4f e4 ff ff       	call   13ed1 <pcb_queue_insert>
   15a82:	83 c4 10             	add    $0x10,%esp
   15a85:	85 c0                	test   %eax,%eax
   15a87:	74 3b                	je     15ac4 <sys_waitpid+0x254>
   15a89:	83 ec 04             	sub    $0x4,%esp
   15a8c:	68 08 b7 01 00       	push   $0x1b708
   15a91:	6a 00                	push   $0x0
   15a93:	68 fe 00 00 00       	push   $0xfe
   15a98:	68 c9 b6 01 00       	push   $0x1b6c9
   15a9d:	68 88 b8 01 00       	push   $0x1b888
   15aa2:	68 d4 b6 01 00       	push   $0x1b6d4
   15aa7:	68 00 f0 01 00       	push   $0x1f000
   15aac:	e8 31 cc ff ff       	call   126e2 <sprint>
   15ab1:	83 c4 20             	add    $0x20,%esp
   15ab4:	83 ec 0c             	sub    $0xc,%esp
   15ab7:	68 00 f0 01 00       	push   $0x1f000
   15abc:	e8 a1 c9 ff ff       	call   12462 <kpanic>
   15ac1:	83 c4 10             	add    $0x10,%esp

		// select a new current process
		current = NULL;
   15ac4:	c7 05 14 10 02 00 00 	movl   $0x0,0x21014
   15acb:	00 00 00 
		dispatch();
   15ace:	e8 98 e9 ff ff       	call   1446b <dispatch>
		SYSCALL_EXIT( (uint32_t) current );
   15ad3:	a1 e0 18 02 00       	mov    0x218e0,%eax
   15ad8:	85 c0                	test   %eax,%eax
   15ada:	0f 84 90 00 00 00    	je     15b70 <sys_waitpid+0x300>
   15ae0:	a1 14 10 02 00       	mov    0x21014,%eax
   15ae5:	83 ec 04             	sub    $0x4,%esp
   15ae8:	50                   	push   %eax
   15ae9:	68 88 b8 01 00       	push   $0x1b888
   15aee:	68 fb b6 01 00       	push   $0x1b6fb
   15af3:	e8 2f ba ff ff       	call   11527 <cio_printf>
   15af8:	83 c4 10             	add    $0x10,%esp
		return;
   15afb:	eb 73                	jmp    15b70 <sys_waitpid+0x300>
	}

	// found a Zombie; collect its information and clean it up
	RET(pcb) = child->pid;
   15afd:	8b 45 08             	mov    0x8(%ebp),%eax
   15b00:	8b 00                	mov    (%eax),%eax
   15b02:	8b 55 f4             	mov    -0xc(%ebp),%edx
   15b05:	8b 52 18             	mov    0x18(%edx),%edx
   15b08:	89 50 30             	mov    %edx,0x30(%eax)

	// get "status" pointer from parent
	int32_t *stat = (int32_t *) ARG(pcb,2);
   15b0b:	8b 45 08             	mov    0x8(%ebp),%eax
   15b0e:	8b 00                	mov    (%eax),%eax
   15b10:	83 c0 48             	add    $0x48,%eax
   15b13:	83 c0 08             	add    $0x8,%eax
   15b16:	8b 00                	mov    (%eax),%eax
   15b18:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	// if stat is NULL, the parent doesn't want the status
	if( stat != NULL ) {
   15b1b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   15b1f:	74 0b                	je     15b2c <sys_waitpid+0x2bc>
		// ** This works in the baseline because we aren't using
		// ** any type of memory protection.  If address space
		// ** separation is implemented, this code will very likely
		// ** STOP WORKING, and will need to be fixed.
		// ********************************************************
		*stat = child->exit_status;
   15b21:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15b24:	8b 50 14             	mov    0x14(%eax),%edx
   15b27:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   15b2a:	89 10                	mov    %edx,(%eax)
	}

	// clean up the child
	pcb_cleanup( child );
   15b2c:	83 ec 0c             	sub    $0xc,%esp
   15b2f:	ff 75 f4             	pushl  -0xc(%ebp)
   15b32:	e8 4a e1 ff ff       	call   13c81 <pcb_cleanup>
   15b37:	83 c4 10             	add    $0x10,%esp

	SYSCALL_EXIT( RET(pcb) );
   15b3a:	a1 e0 18 02 00       	mov    0x218e0,%eax
   15b3f:	85 c0                	test   %eax,%eax
   15b41:	74 30                	je     15b73 <sys_waitpid+0x303>
   15b43:	8b 45 08             	mov    0x8(%ebp),%eax
   15b46:	8b 00                	mov    (%eax),%eax
   15b48:	8b 40 30             	mov    0x30(%eax),%eax
   15b4b:	83 ec 04             	sub    $0x4,%esp
   15b4e:	50                   	push   %eax
   15b4f:	68 88 b8 01 00       	push   $0x1b888
   15b54:	68 fb b6 01 00       	push   $0x1b6fb
   15b59:	e8 c9 b9 ff ff       	call   11527 <cio_printf>
   15b5e:	83 c4 10             	add    $0x10,%esp
	return;
   15b61:	90                   	nop
   15b62:	eb 0f                	jmp    15b73 <sys_waitpid+0x303>
		return;
   15b64:	90                   	nop
   15b65:	eb 0d                	jmp    15b74 <sys_waitpid+0x304>
				return;
   15b67:	90                   	nop
   15b68:	eb 0a                	jmp    15b74 <sys_waitpid+0x304>
			return;
   15b6a:	90                   	nop
   15b6b:	eb 07                	jmp    15b74 <sys_waitpid+0x304>
			return;
   15b6d:	90                   	nop
   15b6e:	eb 04                	jmp    15b74 <sys_waitpid+0x304>
		return;
   15b70:	90                   	nop
   15b71:	eb 01                	jmp    15b74 <sys_waitpid+0x304>
	return;
   15b73:	90                   	nop
}
   15b74:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   15b77:	c9                   	leave  
   15b78:	c3                   	ret    

00015b79 <sys_fork>:
**
** Creates a new process that is a duplicate of the calling process.
** Returns the child's PID to the parent, and 0 to the child, on success;
** else, returns an error code to the parent.
*/
SYSIMPL(fork) {
   15b79:	55                   	push   %ebp
   15b7a:	89 e5                	mov    %esp,%ebp
   15b7c:	53                   	push   %ebx
   15b7d:	83 ec 14             	sub    $0x14,%esp

	// sanity check
	assert( pcb != NULL );
   15b80:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15b84:	75 3b                	jne    15bc1 <sys_fork+0x48>
   15b86:	83 ec 04             	sub    $0x4,%esp
   15b89:	68 c0 b6 01 00       	push   $0x1b6c0
   15b8e:	6a 00                	push   $0x0
   15b90:	68 2e 01 00 00       	push   $0x12e
   15b95:	68 c9 b6 01 00       	push   $0x1b6c9
   15b9a:	68 94 b8 01 00       	push   $0x1b894
   15b9f:	68 d4 b6 01 00       	push   $0x1b6d4
   15ba4:	68 00 f0 01 00       	push   $0x1f000
   15ba9:	e8 34 cb ff ff       	call   126e2 <sprint>
   15bae:	83 c4 20             	add    $0x20,%esp
   15bb1:	83 ec 0c             	sub    $0xc,%esp
   15bb4:	68 00 f0 01 00       	push   $0x1f000
   15bb9:	e8 a4 c8 ff ff       	call   12462 <kpanic>
   15bbe:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   15bc1:	a1 e0 18 02 00       	mov    0x218e0,%eax
   15bc6:	85 c0                	test   %eax,%eax
   15bc8:	74 1c                	je     15be6 <sys_fork+0x6d>
   15bca:	8b 45 08             	mov    0x8(%ebp),%eax
   15bcd:	8b 40 18             	mov    0x18(%eax),%eax
   15bd0:	83 ec 04             	sub    $0x4,%esp
   15bd3:	50                   	push   %eax
   15bd4:	68 94 b8 01 00       	push   $0x1b894
   15bd9:	68 ea b6 01 00       	push   $0x1b6ea
   15bde:	e8 44 b9 ff ff       	call   11527 <cio_printf>
   15be3:	83 c4 10             	add    $0x10,%esp

	// Make sure there's room for another process!
	pcb_t *new;
	if( pcb_alloc(&new) != SUCCESS || new == NULL ) {
   15be6:	83 ec 0c             	sub    $0xc,%esp
   15be9:	8d 45 ec             	lea    -0x14(%ebp),%eax
   15bec:	50                   	push   %eax
   15bed:	e8 4f dc ff ff       	call   13841 <pcb_alloc>
   15bf2:	83 c4 10             	add    $0x10,%esp
   15bf5:	85 c0                	test   %eax,%eax
   15bf7:	75 07                	jne    15c00 <sys_fork+0x87>
   15bf9:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15bfc:	85 c0                	test   %eax,%eax
   15bfe:	75 3c                	jne    15c3c <sys_fork+0xc3>
		RET(pcb) = E_NO_PROCS;
   15c00:	8b 45 08             	mov    0x8(%ebp),%eax
   15c03:	8b 00                	mov    (%eax),%eax
   15c05:	c7 40 30 f9 ff ff ff 	movl   $0xfffffff9,0x30(%eax)
		SYSCALL_EXIT( RET(pcb) );
   15c0c:	a1 e0 18 02 00       	mov    0x218e0,%eax
   15c11:	85 c0                	test   %eax,%eax
   15c13:	0f 84 c0 01 00 00    	je     15dd9 <sys_fork+0x260>
   15c19:	8b 45 08             	mov    0x8(%ebp),%eax
   15c1c:	8b 00                	mov    (%eax),%eax
   15c1e:	8b 40 30             	mov    0x30(%eax),%eax
   15c21:	83 ec 04             	sub    $0x4,%esp
   15c24:	50                   	push   %eax
   15c25:	68 94 b8 01 00       	push   $0x1b894
   15c2a:	68 fb b6 01 00       	push   $0x1b6fb
   15c2f:	e8 f3 b8 ff ff       	call   11527 <cio_printf>
   15c34:	83 c4 10             	add    $0x10,%esp
		return;
   15c37:	e9 9d 01 00 00       	jmp    15dd9 <sys_fork+0x260>
	}

	// create a stack for the new child
	new->stack = pcb_stack_alloc( N_USTKPAGES );
   15c3c:	8b 5d ec             	mov    -0x14(%ebp),%ebx
   15c3f:	83 ec 0c             	sub    $0xc,%esp
   15c42:	6a 02                	push   $0x2
   15c44:	e8 f8 dc ff ff       	call   13941 <pcb_stack_alloc>
   15c49:	83 c4 10             	add    $0x10,%esp
   15c4c:	89 43 04             	mov    %eax,0x4(%ebx)
	if( new->stack == NULL ) {
   15c4f:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15c52:	8b 40 04             	mov    0x4(%eax),%eax
   15c55:	85 c0                	test   %eax,%eax
   15c57:	75 44                	jne    15c9d <sys_fork+0x124>
		pcb_free( new );
   15c59:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15c5c:	83 ec 0c             	sub    $0xc,%esp
   15c5f:	50                   	push   %eax
   15c60:	e8 52 dc ff ff       	call   138b7 <pcb_free>
   15c65:	83 c4 10             	add    $0x10,%esp
		RET(pcb) = E_NO_PROCS;
   15c68:	8b 45 08             	mov    0x8(%ebp),%eax
   15c6b:	8b 00                	mov    (%eax),%eax
   15c6d:	c7 40 30 f9 ff ff ff 	movl   $0xfffffff9,0x30(%eax)
		SYSCALL_EXIT(E_NO_PROCS);
   15c74:	a1 e0 18 02 00       	mov    0x218e0,%eax
   15c79:	85 c0                	test   %eax,%eax
   15c7b:	0f 84 5b 01 00 00    	je     15ddc <sys_fork+0x263>
   15c81:	83 ec 04             	sub    $0x4,%esp
   15c84:	6a f9                	push   $0xfffffff9
   15c86:	68 94 b8 01 00       	push   $0x1b894
   15c8b:	68 fb b6 01 00       	push   $0x1b6fb
   15c90:	e8 92 b8 ff ff       	call   11527 <cio_printf>
   15c95:	83 c4 10             	add    $0x10,%esp
		return;
   15c98:	e9 3f 01 00 00       	jmp    15ddc <sys_fork+0x263>
	}
	// remember that we used the default size
	new->stkpgs = N_USTKPAGES;
   15c9d:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15ca0:	c7 40 28 02 00 00 00 	movl   $0x2,0x28(%eax)

	// duplicate the parent's stack
	memcpy( (void *)new->stack, (void *)pcb->stack, N_USTKPAGES * SZ_PAGE );
   15ca7:	8b 45 08             	mov    0x8(%ebp),%eax
   15caa:	8b 50 04             	mov    0x4(%eax),%edx
   15cad:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15cb0:	8b 40 04             	mov    0x4(%eax),%eax
   15cb3:	83 ec 04             	sub    $0x4,%esp
   15cb6:	68 00 20 00 00       	push   $0x2000
   15cbb:	52                   	push   %edx
   15cbc:	50                   	push   %eax
   15cbd:	e8 be c8 ff ff       	call   12580 <memcpy>
   15cc2:	83 c4 10             	add    $0x10,%esp
    ** them, as that's impractical. As a result, user code that relies on
    ** such pointers may behave strangely after a fork().
    */

    // Figure out the byte offset from one stack to the other.
    int32_t offset = (void *) new->stack - (void *) pcb->stack;
   15cc5:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15cc8:	8b 40 04             	mov    0x4(%eax),%eax
   15ccb:	89 c2                	mov    %eax,%edx
   15ccd:	8b 45 08             	mov    0x8(%ebp),%eax
   15cd0:	8b 40 04             	mov    0x4(%eax),%eax
   15cd3:	29 c2                	sub    %eax,%edx
   15cd5:	89 d0                	mov    %edx,%eax
   15cd7:	89 45 f0             	mov    %eax,-0x10(%ebp)

    // Add this to the child's context pointer.
    new->context = (context_t *) (((void *)pcb->context) + offset);
   15cda:	8b 45 08             	mov    0x8(%ebp),%eax
   15cdd:	8b 08                	mov    (%eax),%ecx
   15cdf:	8b 55 f0             	mov    -0x10(%ebp),%edx
   15ce2:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15ce5:	01 ca                	add    %ecx,%edx
   15ce7:	89 10                	mov    %edx,(%eax)

    // Fix the child's ESP and EBP values IFF they're non-zero.
    if( REG(new,ebp) != 0 ) {
   15ce9:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15cec:	8b 00                	mov    (%eax),%eax
   15cee:	8b 40 1c             	mov    0x1c(%eax),%eax
   15cf1:	85 c0                	test   %eax,%eax
   15cf3:	74 15                	je     15d0a <sys_fork+0x191>
        REG(new,ebp) += offset;
   15cf5:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15cf8:	8b 00                	mov    (%eax),%eax
   15cfa:	8b 48 1c             	mov    0x1c(%eax),%ecx
   15cfd:	8b 55 f0             	mov    -0x10(%ebp),%edx
   15d00:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d03:	8b 00                	mov    (%eax),%eax
   15d05:	01 ca                	add    %ecx,%edx
   15d07:	89 50 1c             	mov    %edx,0x1c(%eax)
    }
    if( REG(new,esp) != 0 ) {
   15d0a:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d0d:	8b 00                	mov    (%eax),%eax
   15d0f:	8b 40 20             	mov    0x20(%eax),%eax
   15d12:	85 c0                	test   %eax,%eax
   15d14:	74 15                	je     15d2b <sys_fork+0x1b2>
        REG(new,esp) += offset;
   15d16:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d19:	8b 00                	mov    (%eax),%eax
   15d1b:	8b 48 20             	mov    0x20(%eax),%ecx
   15d1e:	8b 55 f0             	mov    -0x10(%ebp),%edx
   15d21:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d24:	8b 00                	mov    (%eax),%eax
   15d26:	01 ca                	add    %ecx,%edx
   15d28:	89 50 20             	mov    %edx,0x20(%eax)
    }

    // Follow the EBP chain through the child's stack.
    uint32_t *bp = (uint32_t *) REG(new,ebp);
   15d2b:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d2e:	8b 00                	mov    (%eax),%eax
   15d30:	8b 40 1c             	mov    0x1c(%eax),%eax
   15d33:	89 45 f4             	mov    %eax,-0xc(%ebp)
    while( bp ) {
   15d36:	eb 17                	jmp    15d4f <sys_fork+0x1d6>
        *bp += offset;
   15d38:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15d3b:	8b 10                	mov    (%eax),%edx
   15d3d:	8b 45 f0             	mov    -0x10(%ebp),%eax
   15d40:	01 c2                	add    %eax,%edx
   15d42:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15d45:	89 10                	mov    %edx,(%eax)
        bp = (uint32_t *) *bp;
   15d47:	8b 45 f4             	mov    -0xc(%ebp),%eax
   15d4a:	8b 00                	mov    (%eax),%eax
   15d4c:	89 45 f4             	mov    %eax,-0xc(%ebp)
    while( bp ) {
   15d4f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   15d53:	75 e3                	jne    15d38 <sys_fork+0x1bf>
    }

	// Set the child's identity.
	new->pid = next_pid++;
   15d55:	a1 1c 10 02 00       	mov    0x2101c,%eax
   15d5a:	8d 50 01             	lea    0x1(%eax),%edx
   15d5d:	89 15 1c 10 02 00    	mov    %edx,0x2101c
   15d63:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15d66:	89 42 18             	mov    %eax,0x18(%edx)
	new->parent = pcb;
   15d69:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d6c:	8b 55 08             	mov    0x8(%ebp),%edx
   15d6f:	89 50 0c             	mov    %edx,0xc(%eax)
	new->state = STATE_NEW;
   15d72:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d75:	c7 40 1c 01 00 00 00 	movl   $0x1,0x1c(%eax)

	// replicate other things inherited from the parent
	new->priority = pcb->priority;
   15d7c:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d7f:	8b 55 08             	mov    0x8(%ebp),%edx
   15d82:	8b 52 20             	mov    0x20(%edx),%edx
   15d85:	89 50 20             	mov    %edx,0x20(%eax)

	// Set the return values for the two processes.
	RET(pcb) = new->pid;
   15d88:	8b 55 ec             	mov    -0x14(%ebp),%edx
   15d8b:	8b 45 08             	mov    0x8(%ebp),%eax
   15d8e:	8b 00                	mov    (%eax),%eax
   15d90:	8b 52 18             	mov    0x18(%edx),%edx
   15d93:	89 50 30             	mov    %edx,0x30(%eax)
	RET(new) = 0;
   15d96:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15d99:	8b 00                	mov    (%eax),%eax
   15d9b:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)

	// Schedule the child, and let the parent continue.
	schedule( new );
   15da2:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15da5:	83 ec 0c             	sub    $0xc,%esp
   15da8:	50                   	push   %eax
   15da9:	e8 fc e5 ff ff       	call   143aa <schedule>
   15dae:	83 c4 10             	add    $0x10,%esp

	SYSCALL_EXIT( new->pid );
   15db1:	a1 e0 18 02 00       	mov    0x218e0,%eax
   15db6:	85 c0                	test   %eax,%eax
   15db8:	74 25                	je     15ddf <sys_fork+0x266>
   15dba:	8b 45 ec             	mov    -0x14(%ebp),%eax
   15dbd:	8b 40 18             	mov    0x18(%eax),%eax
   15dc0:	83 ec 04             	sub    $0x4,%esp
   15dc3:	50                   	push   %eax
   15dc4:	68 94 b8 01 00       	push   $0x1b894
   15dc9:	68 fb b6 01 00       	push   $0x1b6fb
   15dce:	e8 54 b7 ff ff       	call   11527 <cio_printf>
   15dd3:	83 c4 10             	add    $0x10,%esp
	return;
   15dd6:	90                   	nop
   15dd7:	eb 06                	jmp    15ddf <sys_fork+0x266>
		return;
   15dd9:	90                   	nop
   15dda:	eb 04                	jmp    15de0 <sys_fork+0x267>
		return;
   15ddc:	90                   	nop
   15ddd:	eb 01                	jmp    15de0 <sys_fork+0x267>
	return;
   15ddf:	90                   	nop
}
   15de0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   15de3:	c9                   	leave  
   15de4:	c3                   	ret    

00015de5 <sys_exec>:
** indicated program.
**
** Returns only on failure.
*/
SYSIMPL(exec)
{
   15de5:	55                   	push   %ebp
   15de6:	89 e5                	mov    %esp,%ebp
   15de8:	83 ec 18             	sub    $0x18,%esp
	// sanity check
	assert( pcb != NULL );
   15deb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15def:	75 3b                	jne    15e2c <sys_exec+0x47>
   15df1:	83 ec 04             	sub    $0x4,%esp
   15df4:	68 c0 b6 01 00       	push   $0x1b6c0
   15df9:	6a 00                	push   $0x0
   15dfb:	68 8a 01 00 00       	push   $0x18a
   15e00:	68 c9 b6 01 00       	push   $0x1b6c9
   15e05:	68 a0 b8 01 00       	push   $0x1b8a0
   15e0a:	68 d4 b6 01 00       	push   $0x1b6d4
   15e0f:	68 00 f0 01 00       	push   $0x1f000
   15e14:	e8 c9 c8 ff ff       	call   126e2 <sprint>
   15e19:	83 c4 20             	add    $0x20,%esp
   15e1c:	83 ec 0c             	sub    $0xc,%esp
   15e1f:	68 00 f0 01 00       	push   $0x1f000
   15e24:	e8 39 c6 ff ff       	call   12462 <kpanic>
   15e29:	83 c4 10             	add    $0x10,%esp

	uint_t what = ARG(pcb,1);
   15e2c:	8b 45 08             	mov    0x8(%ebp),%eax
   15e2f:	8b 00                	mov    (%eax),%eax
   15e31:	83 c0 48             	add    $0x48,%eax
   15e34:	8b 40 04             	mov    0x4(%eax),%eax
   15e37:	89 45 f4             	mov    %eax,-0xc(%ebp)
	const char **args = (const char **) ARG(pcb,2);
   15e3a:	8b 45 08             	mov    0x8(%ebp),%eax
   15e3d:	8b 00                	mov    (%eax),%eax
   15e3f:	83 c0 48             	add    $0x48,%eax
   15e42:	83 c0 08             	add    $0x8,%eax
   15e45:	8b 00                	mov    (%eax),%eax
   15e47:	89 45 f0             	mov    %eax,-0x10(%ebp)

	SYSCALL_ENTER( pcb->pid );
   15e4a:	a1 e0 18 02 00       	mov    0x218e0,%eax
   15e4f:	85 c0                	test   %eax,%eax
   15e51:	74 1c                	je     15e6f <sys_exec+0x8a>
   15e53:	8b 45 08             	mov    0x8(%ebp),%eax
   15e56:	8b 40 18             	mov    0x18(%eax),%eax
   15e59:	83 ec 04             	sub    $0x4,%esp
   15e5c:	50                   	push   %eax
   15e5d:	68 a0 b8 01 00       	push   $0x1b8a0
   15e62:	68 ea b6 01 00       	push   $0x1b6ea
   15e67:	e8 bb b6 ff ff       	call   11527 <cio_printf>
   15e6c:	83 c4 10             	add    $0x10,%esp

	// we create a new stack for the process so we don't have to
	// worry about overwriting data in the old stack; however, we
	// need to keep the old one around until after we have copied
	// all the argument data from it.
	void *oldstack = (void *) pcb->stack;
   15e6f:	8b 45 08             	mov    0x8(%ebp),%eax
   15e72:	8b 40 04             	mov    0x4(%eax),%eax
   15e75:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32_t oldsize = pcb->stkpgs;
   15e78:	8b 45 08             	mov    0x8(%ebp),%eax
   15e7b:	8b 40 28             	mov    0x28(%eax),%eax
   15e7e:	89 45 e8             	mov    %eax,-0x18(%ebp)

	// allocate a new stack of the default size
	pcb->stack = pcb_stack_alloc( N_USTKPAGES );
   15e81:	83 ec 0c             	sub    $0xc,%esp
   15e84:	6a 02                	push   $0x2
   15e86:	e8 b6 da ff ff       	call   13941 <pcb_stack_alloc>
   15e8b:	83 c4 10             	add    $0x10,%esp
   15e8e:	89 c2                	mov    %eax,%edx
   15e90:	8b 45 08             	mov    0x8(%ebp),%eax
   15e93:	89 50 04             	mov    %edx,0x4(%eax)
	assert( pcb->stack != NULL );
   15e96:	8b 45 08             	mov    0x8(%ebp),%eax
   15e99:	8b 40 04             	mov    0x4(%eax),%eax
   15e9c:	85 c0                	test   %eax,%eax
   15e9e:	75 3b                	jne    15edb <sys_exec+0xf6>
   15ea0:	83 ec 04             	sub    $0x4,%esp
   15ea3:	68 2d b7 01 00       	push   $0x1b72d
   15ea8:	6a 00                	push   $0x0
   15eaa:	68 9d 01 00 00       	push   $0x19d
   15eaf:	68 c9 b6 01 00       	push   $0x1b6c9
   15eb4:	68 a0 b8 01 00       	push   $0x1b8a0
   15eb9:	68 d4 b6 01 00       	push   $0x1b6d4
   15ebe:	68 00 f0 01 00       	push   $0x1f000
   15ec3:	e8 1a c8 ff ff       	call   126e2 <sprint>
   15ec8:	83 c4 20             	add    $0x20,%esp
   15ecb:	83 ec 0c             	sub    $0xc,%esp
   15ece:	68 00 f0 01 00       	push   $0x1f000
   15ed3:	e8 8a c5 ff ff       	call   12462 <kpanic>
   15ed8:	83 c4 10             	add    $0x10,%esp
	pcb->stkpgs = N_USTKPAGES;
   15edb:	8b 45 08             	mov    0x8(%ebp),%eax
   15ede:	c7 40 28 02 00 00 00 	movl   $0x2,0x28(%eax)

	// set up the new stack using the old stack data
	pcb->context = stack_setup( pcb, what, args, true );
   15ee5:	6a 01                	push   $0x1
   15ee7:	ff 75 f0             	pushl  -0x10(%ebp)
   15eea:	ff 75 f4             	pushl  -0xc(%ebp)
   15eed:	ff 75 08             	pushl  0x8(%ebp)
   15ef0:	e8 93 0b 00 00       	call   16a88 <stack_setup>
   15ef5:	83 c4 10             	add    $0x10,%esp
   15ef8:	89 c2                	mov    %eax,%edx
   15efa:	8b 45 08             	mov    0x8(%ebp),%eax
   15efd:	89 10                	mov    %edx,(%eax)
	assert( pcb->context != NULL );
   15eff:	8b 45 08             	mov    0x8(%ebp),%eax
   15f02:	8b 00                	mov    (%eax),%eax
   15f04:	85 c0                	test   %eax,%eax
   15f06:	75 3b                	jne    15f43 <sys_exec+0x15e>
   15f08:	83 ec 04             	sub    $0x4,%esp
   15f0b:	68 3d b7 01 00       	push   $0x1b73d
   15f10:	6a 00                	push   $0x0
   15f12:	68 a2 01 00 00       	push   $0x1a2
   15f17:	68 c9 b6 01 00       	push   $0x1b6c9
   15f1c:	68 a0 b8 01 00       	push   $0x1b8a0
   15f21:	68 d4 b6 01 00       	push   $0x1b6d4
   15f26:	68 00 f0 01 00       	push   $0x1f000
   15f2b:	e8 b2 c7 ff ff       	call   126e2 <sprint>
   15f30:	83 c4 20             	add    $0x20,%esp
   15f33:	83 ec 0c             	sub    $0xc,%esp
   15f36:	68 00 f0 01 00       	push   $0x1f000
   15f3b:	e8 22 c5 ff ff       	call   12462 <kpanic>
   15f40:	83 c4 10             	add    $0x10,%esp

	// now we can safely free the old stack
	pcb_stack_free( oldstack, oldsize );
   15f43:	83 ec 08             	sub    $0x8,%esp
   15f46:	ff 75 e8             	pushl  -0x18(%ebp)
   15f49:	ff 75 ec             	pushl  -0x14(%ebp)
   15f4c:	e8 34 da ff ff       	call   13985 <pcb_stack_free>
   15f51:	83 c4 10             	add    $0x10,%esp
	 **	(C) reset this one's time slice and let it continue
	 **
	 ** We choose option A.
	 */

	schedule( pcb );
   15f54:	83 ec 0c             	sub    $0xc,%esp
   15f57:	ff 75 08             	pushl  0x8(%ebp)
   15f5a:	e8 4b e4 ff ff       	call   143aa <schedule>
   15f5f:	83 c4 10             	add    $0x10,%esp

	// reset 'current' to keep dispatch() happy
	current = NULL;
   15f62:	c7 05 14 10 02 00 00 	movl   $0x0,0x21014
   15f69:	00 00 00 
	dispatch();
   15f6c:	e8 fa e4 ff ff       	call   1446b <dispatch>
}
   15f71:	90                   	nop
   15f72:	c9                   	leave  
   15f73:	c3                   	ret    

00015f74 <sys_read>:
**		int read( uint_t chan, void *buffer, uint_t length );
**
** Reads up to 'length' bytes from 'chan' into 'buffer'. Returns the
** count of bytes actually transferred.
*/
SYSIMPL(read) {
   15f74:	55                   	push   %ebp
   15f75:	89 e5                	mov    %esp,%ebp
   15f77:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   15f7a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   15f7e:	75 3b                	jne    15fbb <sys_read+0x47>
   15f80:	83 ec 04             	sub    $0x4,%esp
   15f83:	68 c0 b6 01 00       	push   $0x1b6c0
   15f88:	6a 00                	push   $0x0
   15f8a:	68 c3 01 00 00       	push   $0x1c3
   15f8f:	68 c9 b6 01 00       	push   $0x1b6c9
   15f94:	68 ac b8 01 00       	push   $0x1b8ac
   15f99:	68 d4 b6 01 00       	push   $0x1b6d4
   15f9e:	68 00 f0 01 00       	push   $0x1f000
   15fa3:	e8 3a c7 ff ff       	call   126e2 <sprint>
   15fa8:	83 c4 20             	add    $0x20,%esp
   15fab:	83 ec 0c             	sub    $0xc,%esp
   15fae:	68 00 f0 01 00       	push   $0x1f000
   15fb3:	e8 aa c4 ff ff       	call   12462 <kpanic>
   15fb8:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   15fbb:	a1 e0 18 02 00       	mov    0x218e0,%eax
   15fc0:	85 c0                	test   %eax,%eax
   15fc2:	74 1c                	je     15fe0 <sys_read+0x6c>
   15fc4:	8b 45 08             	mov    0x8(%ebp),%eax
   15fc7:	8b 40 18             	mov    0x18(%eax),%eax
   15fca:	83 ec 04             	sub    $0x4,%esp
   15fcd:	50                   	push   %eax
   15fce:	68 ac b8 01 00       	push   $0x1b8ac
   15fd3:	68 ea b6 01 00       	push   $0x1b6ea
   15fd8:	e8 4a b5 ff ff       	call   11527 <cio_printf>
   15fdd:	83 c4 10             	add    $0x10,%esp
	
	// grab the arguments
	uint_t chan = ARG(pcb,1);
   15fe0:	8b 45 08             	mov    0x8(%ebp),%eax
   15fe3:	8b 00                	mov    (%eax),%eax
   15fe5:	83 c0 48             	add    $0x48,%eax
   15fe8:	8b 40 04             	mov    0x4(%eax),%eax
   15feb:	89 45 f4             	mov    %eax,-0xc(%ebp)
	char *buf = (char *) ARG(pcb,2);
   15fee:	8b 45 08             	mov    0x8(%ebp),%eax
   15ff1:	8b 00                	mov    (%eax),%eax
   15ff3:	83 c0 48             	add    $0x48,%eax
   15ff6:	83 c0 08             	add    $0x8,%eax
   15ff9:	8b 00                	mov    (%eax),%eax
   15ffb:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint_t len = ARG(pcb,3);
   15ffe:	8b 45 08             	mov    0x8(%ebp),%eax
   16001:	8b 00                	mov    (%eax),%eax
   16003:	83 c0 48             	add    $0x48,%eax
   16006:	8b 40 0c             	mov    0xc(%eax),%eax
   16009:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// if the buffer is of length 0, we're done!
	if( len == 0 ) {
   1600c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   16010:	75 35                	jne    16047 <sys_read+0xd3>
		RET(pcb) = 0;
   16012:	8b 45 08             	mov    0x8(%ebp),%eax
   16015:	8b 00                	mov    (%eax),%eax
   16017:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
		SYSCALL_EXIT( 0 );
   1601e:	a1 e0 18 02 00       	mov    0x218e0,%eax
   16023:	85 c0                	test   %eax,%eax
   16025:	0f 84 2b 01 00 00    	je     16156 <sys_read+0x1e2>
   1602b:	83 ec 04             	sub    $0x4,%esp
   1602e:	6a 00                	push   $0x0
   16030:	68 ac b8 01 00       	push   $0x1b8ac
   16035:	68 fb b6 01 00       	push   $0x1b6fb
   1603a:	e8 e8 b4 ff ff       	call   11527 <cio_printf>
   1603f:	83 c4 10             	add    $0x10,%esp
		return;
   16042:	e9 0f 01 00 00       	jmp    16156 <sys_read+0x1e2>
	}

	// try to get the next character(s)
	int n = 0;
   16047:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	if( chan == CHAN_CIO ) {
   1604e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   16052:	0f 85 85 00 00 00    	jne    160dd <sys_read+0x169>

		// console input is non-blocking
		if( cio_input_queue() < 1 ) {
   16058:	e8 4e b7 ff ff       	call   117ab <cio_input_queue>
   1605d:	85 c0                	test   %eax,%eax
   1605f:	7f 35                	jg     16096 <sys_read+0x122>
			RET(pcb) = 0;
   16061:	8b 45 08             	mov    0x8(%ebp),%eax
   16064:	8b 00                	mov    (%eax),%eax
   16066:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
			SYSCALL_EXIT( 0 );
   1606d:	a1 e0 18 02 00       	mov    0x218e0,%eax
   16072:	85 c0                	test   %eax,%eax
   16074:	0f 84 df 00 00 00    	je     16159 <sys_read+0x1e5>
   1607a:	83 ec 04             	sub    $0x4,%esp
   1607d:	6a 00                	push   $0x0
   1607f:	68 ac b8 01 00       	push   $0x1b8ac
   16084:	68 fb b6 01 00       	push   $0x1b6fb
   16089:	e8 99 b4 ff ff       	call   11527 <cio_printf>
   1608e:	83 c4 10             	add    $0x10,%esp
			return;
   16091:	e9 c3 00 00 00       	jmp    16159 <sys_read+0x1e5>
		}
		// at least one character
		n = cio_gets( buf, len );
   16096:	83 ec 08             	sub    $0x8,%esp
   16099:	ff 75 ec             	pushl  -0x14(%ebp)
   1609c:	ff 75 f0             	pushl  -0x10(%ebp)
   1609f:	e8 b6 b6 ff ff       	call   1175a <cio_gets>
   160a4:	83 c4 10             	add    $0x10,%esp
   160a7:	89 45 e8             	mov    %eax,-0x18(%ebp)
		RET(pcb) = n;
   160aa:	8b 45 08             	mov    0x8(%ebp),%eax
   160ad:	8b 00                	mov    (%eax),%eax
   160af:	8b 55 e8             	mov    -0x18(%ebp),%edx
   160b2:	89 50 30             	mov    %edx,0x30(%eax)
		SYSCALL_EXIT( n );
   160b5:	a1 e0 18 02 00       	mov    0x218e0,%eax
   160ba:	85 c0                	test   %eax,%eax
   160bc:	0f 84 9a 00 00 00    	je     1615c <sys_read+0x1e8>
   160c2:	8b 45 e8             	mov    -0x18(%ebp),%eax
   160c5:	83 ec 04             	sub    $0x4,%esp
   160c8:	50                   	push   %eax
   160c9:	68 ac b8 01 00       	push   $0x1b8ac
   160ce:	68 fb b6 01 00       	push   $0x1b6fb
   160d3:	e8 4f b4 ff ff       	call   11527 <cio_printf>
   160d8:	83 c4 10             	add    $0x10,%esp
		return;
   160db:	eb 7f                	jmp    1615c <sys_read+0x1e8>

	} else if( chan == CHAN_SIO ) {
   160dd:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
   160e1:	75 44                	jne    16127 <sys_read+0x1b3>

		// SIO input is blocking, so if there are no characters
		// available, we'll block this process
		n = sio_read( buf, len );
   160e3:	8b 45 ec             	mov    -0x14(%ebp),%eax
   160e6:	83 ec 08             	sub    $0x8,%esp
   160e9:	50                   	push   %eax
   160ea:	ff 75 f0             	pushl  -0x10(%ebp)
   160ed:	e8 66 f0 ff ff       	call   15158 <sio_read>
   160f2:	83 c4 10             	add    $0x10,%esp
   160f5:	89 45 e8             	mov    %eax,-0x18(%ebp)
		RET(pcb) = n;
   160f8:	8b 45 08             	mov    0x8(%ebp),%eax
   160fb:	8b 00                	mov    (%eax),%eax
   160fd:	8b 55 e8             	mov    -0x18(%ebp),%edx
   16100:	89 50 30             	mov    %edx,0x30(%eax)
		SYSCALL_EXIT( n );
   16103:	a1 e0 18 02 00       	mov    0x218e0,%eax
   16108:	85 c0                	test   %eax,%eax
   1610a:	74 53                	je     1615f <sys_read+0x1eb>
   1610c:	8b 45 e8             	mov    -0x18(%ebp),%eax
   1610f:	83 ec 04             	sub    $0x4,%esp
   16112:	50                   	push   %eax
   16113:	68 ac b8 01 00       	push   $0x1b8ac
   16118:	68 fb b6 01 00       	push   $0x1b6fb
   1611d:	e8 05 b4 ff ff       	call   11527 <cio_printf>
   16122:	83 c4 10             	add    $0x10,%esp
		return;
   16125:	eb 38                	jmp    1615f <sys_read+0x1eb>

	}

	// bad channel code
	RET(pcb) = E_BAD_PARAM;
   16127:	8b 45 08             	mov    0x8(%ebp),%eax
   1612a:	8b 00                	mov    (%eax),%eax
   1612c:	c7 40 30 fe ff ff ff 	movl   $0xfffffffe,0x30(%eax)
	SYSCALL_EXIT( E_BAD_PARAM );
   16133:	a1 e0 18 02 00       	mov    0x218e0,%eax
   16138:	85 c0                	test   %eax,%eax
   1613a:	74 26                	je     16162 <sys_read+0x1ee>
   1613c:	83 ec 04             	sub    $0x4,%esp
   1613f:	6a fe                	push   $0xfffffffe
   16141:	68 ac b8 01 00       	push   $0x1b8ac
   16146:	68 fb b6 01 00       	push   $0x1b6fb
   1614b:	e8 d7 b3 ff ff       	call   11527 <cio_printf>
   16150:	83 c4 10             	add    $0x10,%esp
	return;
   16153:	90                   	nop
   16154:	eb 0c                	jmp    16162 <sys_read+0x1ee>
		return;
   16156:	90                   	nop
   16157:	eb 0a                	jmp    16163 <sys_read+0x1ef>
			return;
   16159:	90                   	nop
   1615a:	eb 07                	jmp    16163 <sys_read+0x1ef>
		return;
   1615c:	90                   	nop
   1615d:	eb 04                	jmp    16163 <sys_read+0x1ef>
		return;
   1615f:	90                   	nop
   16160:	eb 01                	jmp    16163 <sys_read+0x1ef>
	return;
   16162:	90                   	nop
}
   16163:	c9                   	leave  
   16164:	c3                   	ret    

00016165 <sys_write>:
**		int write( uint_t chan, const void *buffer, uint_t length );
**
** Writes 'length' bytes from 'buffer' to 'chan'. Returns the
** count of bytes actually transferred.
*/
SYSIMPL(write) {
   16165:	55                   	push   %ebp
   16166:	89 e5                	mov    %esp,%ebp
   16168:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   1616b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1616f:	75 3b                	jne    161ac <sys_write+0x47>
   16171:	83 ec 04             	sub    $0x4,%esp
   16174:	68 c0 b6 01 00       	push   $0x1b6c0
   16179:	6a 00                	push   $0x0
   1617b:	68 01 02 00 00       	push   $0x201
   16180:	68 c9 b6 01 00       	push   $0x1b6c9
   16185:	68 b8 b8 01 00       	push   $0x1b8b8
   1618a:	68 d4 b6 01 00       	push   $0x1b6d4
   1618f:	68 00 f0 01 00       	push   $0x1f000
   16194:	e8 49 c5 ff ff       	call   126e2 <sprint>
   16199:	83 c4 20             	add    $0x20,%esp
   1619c:	83 ec 0c             	sub    $0xc,%esp
   1619f:	68 00 f0 01 00       	push   $0x1f000
   161a4:	e8 b9 c2 ff ff       	call   12462 <kpanic>
   161a9:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   161ac:	a1 e0 18 02 00       	mov    0x218e0,%eax
   161b1:	85 c0                	test   %eax,%eax
   161b3:	74 1c                	je     161d1 <sys_write+0x6c>
   161b5:	8b 45 08             	mov    0x8(%ebp),%eax
   161b8:	8b 40 18             	mov    0x18(%eax),%eax
   161bb:	83 ec 04             	sub    $0x4,%esp
   161be:	50                   	push   %eax
   161bf:	68 b8 b8 01 00       	push   $0x1b8b8
   161c4:	68 ea b6 01 00       	push   $0x1b6ea
   161c9:	e8 59 b3 ff ff       	call   11527 <cio_printf>
   161ce:	83 c4 10             	add    $0x10,%esp

	// grab the parameters
	uint_t chan = ARG(pcb,1);
   161d1:	8b 45 08             	mov    0x8(%ebp),%eax
   161d4:	8b 00                	mov    (%eax),%eax
   161d6:	83 c0 48             	add    $0x48,%eax
   161d9:	8b 40 04             	mov    0x4(%eax),%eax
   161dc:	89 45 f0             	mov    %eax,-0x10(%ebp)
	char *buf = (char *) ARG(pcb,2);
   161df:	8b 45 08             	mov    0x8(%ebp),%eax
   161e2:	8b 00                	mov    (%eax),%eax
   161e4:	83 c0 48             	add    $0x48,%eax
   161e7:	83 c0 08             	add    $0x8,%eax
   161ea:	8b 00                	mov    (%eax),%eax
   161ec:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint_t length = ARG(pcb,3);
   161ef:	8b 45 08             	mov    0x8(%ebp),%eax
   161f2:	8b 00                	mov    (%eax),%eax
   161f4:	83 c0 48             	add    $0x48,%eax
   161f7:	8b 40 0c             	mov    0xc(%eax),%eax
   161fa:	89 45 e8             	mov    %eax,-0x18(%ebp)

	// this is almost insanely simple, but it does separate the
	// low-level device access fromm the higher-level syscall implementation

	// assume we write the indicated amount
	int rval = length;
   161fd:	8b 45 e8             	mov    -0x18(%ebp),%eax
   16200:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// simplest case
	if( length >= 0 ) {

		if( chan == CHAN_CIO ) {
   16203:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   16207:	75 14                	jne    1621d <sys_write+0xb8>

			cio_write( buf, length );
   16209:	8b 45 e8             	mov    -0x18(%ebp),%eax
   1620c:	83 ec 08             	sub    $0x8,%esp
   1620f:	50                   	push   %eax
   16210:	ff 75 ec             	pushl  -0x14(%ebp)
   16213:	e8 c6 ac ff ff       	call   10ede <cio_write>
   16218:	83 c4 10             	add    $0x10,%esp
   1621b:	eb 21                	jmp    1623e <sys_write+0xd9>

		} else if( chan == CHAN_SIO ) {
   1621d:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
   16221:	75 14                	jne    16237 <sys_write+0xd2>

			sio_write( buf, length );
   16223:	8b 45 e8             	mov    -0x18(%ebp),%eax
   16226:	83 ec 08             	sub    $0x8,%esp
   16229:	50                   	push   %eax
   1622a:	ff 75 ec             	pushl  -0x14(%ebp)
   1622d:	e8 36 f0 ff ff       	call   15268 <sio_write>
   16232:	83 c4 10             	add    $0x10,%esp
   16235:	eb 07                	jmp    1623e <sys_write+0xd9>

		} else {

			rval = E_BAD_CHAN;
   16237:	c7 45 f4 fd ff ff ff 	movl   $0xfffffffd,-0xc(%ebp)

		}

	}

	RET(pcb) = rval;
   1623e:	8b 45 08             	mov    0x8(%ebp),%eax
   16241:	8b 00                	mov    (%eax),%eax
   16243:	8b 55 f4             	mov    -0xc(%ebp),%edx
   16246:	89 50 30             	mov    %edx,0x30(%eax)

	SYSCALL_EXIT( rval );
   16249:	a1 e0 18 02 00       	mov    0x218e0,%eax
   1624e:	85 c0                	test   %eax,%eax
   16250:	74 1a                	je     1626c <sys_write+0x107>
   16252:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16255:	83 ec 04             	sub    $0x4,%esp
   16258:	50                   	push   %eax
   16259:	68 b8 b8 01 00       	push   $0x1b8b8
   1625e:	68 fb b6 01 00       	push   $0x1b6fb
   16263:	e8 bf b2 ff ff       	call   11527 <cio_printf>
   16268:	83 c4 10             	add    $0x10,%esp
	return;
   1626b:	90                   	nop
   1626c:	90                   	nop
}
   1626d:	c9                   	leave  
   1626e:	c3                   	ret    

0001626f <sys_getpid>:
** sys_getpid - returns the PID of the calling process
**
** Implements:
**		uint_t getpid( void );
*/
SYSIMPL(getpid) {
   1626f:	55                   	push   %ebp
   16270:	89 e5                	mov    %esp,%ebp
   16272:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   16275:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16279:	75 3b                	jne    162b6 <sys_getpid+0x47>
   1627b:	83 ec 04             	sub    $0x4,%esp
   1627e:	68 c0 b6 01 00       	push   $0x1b6c0
   16283:	6a 00                	push   $0x0
   16285:	68 32 02 00 00       	push   $0x232
   1628a:	68 c9 b6 01 00       	push   $0x1b6c9
   1628f:	68 c4 b8 01 00       	push   $0x1b8c4
   16294:	68 d4 b6 01 00       	push   $0x1b6d4
   16299:	68 00 f0 01 00       	push   $0x1f000
   1629e:	e8 3f c4 ff ff       	call   126e2 <sprint>
   162a3:	83 c4 20             	add    $0x20,%esp
   162a6:	83 ec 0c             	sub    $0xc,%esp
   162a9:	68 00 f0 01 00       	push   $0x1f000
   162ae:	e8 af c1 ff ff       	call   12462 <kpanic>
   162b3:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   162b6:	a1 e0 18 02 00       	mov    0x218e0,%eax
   162bb:	85 c0                	test   %eax,%eax
   162bd:	74 1c                	je     162db <sys_getpid+0x6c>
   162bf:	8b 45 08             	mov    0x8(%ebp),%eax
   162c2:	8b 40 18             	mov    0x18(%eax),%eax
   162c5:	83 ec 04             	sub    $0x4,%esp
   162c8:	50                   	push   %eax
   162c9:	68 c4 b8 01 00       	push   $0x1b8c4
   162ce:	68 ea b6 01 00       	push   $0x1b6ea
   162d3:	e8 4f b2 ff ff       	call   11527 <cio_printf>
   162d8:	83 c4 10             	add    $0x10,%esp

	// return the time
	RET(pcb) = pcb->pid;
   162db:	8b 45 08             	mov    0x8(%ebp),%eax
   162de:	8b 00                	mov    (%eax),%eax
   162e0:	8b 55 08             	mov    0x8(%ebp),%edx
   162e3:	8b 52 18             	mov    0x18(%edx),%edx
   162e6:	89 50 30             	mov    %edx,0x30(%eax)
}
   162e9:	90                   	nop
   162ea:	c9                   	leave  
   162eb:	c3                   	ret    

000162ec <sys_getppid>:
** sys_getppid - returns the PID of the parent of the calling process
**
** Implements:
**		uint_t getppid( void );
*/
SYSIMPL(getppid) {
   162ec:	55                   	push   %ebp
   162ed:	89 e5                	mov    %esp,%ebp
   162ef:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   162f2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   162f6:	75 3b                	jne    16333 <sys_getppid+0x47>
   162f8:	83 ec 04             	sub    $0x4,%esp
   162fb:	68 c0 b6 01 00       	push   $0x1b6c0
   16300:	6a 00                	push   $0x0
   16302:	68 43 02 00 00       	push   $0x243
   16307:	68 c9 b6 01 00       	push   $0x1b6c9
   1630c:	68 d0 b8 01 00       	push   $0x1b8d0
   16311:	68 d4 b6 01 00       	push   $0x1b6d4
   16316:	68 00 f0 01 00       	push   $0x1f000
   1631b:	e8 c2 c3 ff ff       	call   126e2 <sprint>
   16320:	83 c4 20             	add    $0x20,%esp
   16323:	83 ec 0c             	sub    $0xc,%esp
   16326:	68 00 f0 01 00       	push   $0x1f000
   1632b:	e8 32 c1 ff ff       	call   12462 <kpanic>
   16330:	83 c4 10             	add    $0x10,%esp
	assert( pcb->parent != NULL );
   16333:	8b 45 08             	mov    0x8(%ebp),%eax
   16336:	8b 40 0c             	mov    0xc(%eax),%eax
   16339:	85 c0                	test   %eax,%eax
   1633b:	75 3b                	jne    16378 <sys_getppid+0x8c>
   1633d:	83 ec 04             	sub    $0x4,%esp
   16340:	68 4f b7 01 00       	push   $0x1b74f
   16345:	6a 00                	push   $0x0
   16347:	68 44 02 00 00       	push   $0x244
   1634c:	68 c9 b6 01 00       	push   $0x1b6c9
   16351:	68 d0 b8 01 00       	push   $0x1b8d0
   16356:	68 d4 b6 01 00       	push   $0x1b6d4
   1635b:	68 00 f0 01 00       	push   $0x1f000
   16360:	e8 7d c3 ff ff       	call   126e2 <sprint>
   16365:	83 c4 20             	add    $0x20,%esp
   16368:	83 ec 0c             	sub    $0xc,%esp
   1636b:	68 00 f0 01 00       	push   $0x1f000
   16370:	e8 ed c0 ff ff       	call   12462 <kpanic>
   16375:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   16378:	a1 e0 18 02 00       	mov    0x218e0,%eax
   1637d:	85 c0                	test   %eax,%eax
   1637f:	74 1c                	je     1639d <sys_getppid+0xb1>
   16381:	8b 45 08             	mov    0x8(%ebp),%eax
   16384:	8b 40 18             	mov    0x18(%eax),%eax
   16387:	83 ec 04             	sub    $0x4,%esp
   1638a:	50                   	push   %eax
   1638b:	68 d0 b8 01 00       	push   $0x1b8d0
   16390:	68 ea b6 01 00       	push   $0x1b6ea
   16395:	e8 8d b1 ff ff       	call   11527 <cio_printf>
   1639a:	83 c4 10             	add    $0x10,%esp

	// return the time
	RET(pcb) = pcb->parent->pid;
   1639d:	8b 45 08             	mov    0x8(%ebp),%eax
   163a0:	8b 50 0c             	mov    0xc(%eax),%edx
   163a3:	8b 45 08             	mov    0x8(%ebp),%eax
   163a6:	8b 00                	mov    (%eax),%eax
   163a8:	8b 52 18             	mov    0x18(%edx),%edx
   163ab:	89 50 30             	mov    %edx,0x30(%eax)
}
   163ae:	90                   	nop
   163af:	c9                   	leave  
   163b0:	c3                   	ret    

000163b1 <sys_gettime>:
** sys_gettime - returns the current system time
**
** Implements:
**		uint32_t gettime( void );
*/
SYSIMPL(gettime) {
   163b1:	55                   	push   %ebp
   163b2:	89 e5                	mov    %esp,%ebp
   163b4:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   163b7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   163bb:	75 3b                	jne    163f8 <sys_gettime+0x47>
   163bd:	83 ec 04             	sub    $0x4,%esp
   163c0:	68 c0 b6 01 00       	push   $0x1b6c0
   163c5:	6a 00                	push   $0x0
   163c7:	68 55 02 00 00       	push   $0x255
   163cc:	68 c9 b6 01 00       	push   $0x1b6c9
   163d1:	68 dc b8 01 00       	push   $0x1b8dc
   163d6:	68 d4 b6 01 00       	push   $0x1b6d4
   163db:	68 00 f0 01 00       	push   $0x1f000
   163e0:	e8 fd c2 ff ff       	call   126e2 <sprint>
   163e5:	83 c4 20             	add    $0x20,%esp
   163e8:	83 ec 0c             	sub    $0xc,%esp
   163eb:	68 00 f0 01 00       	push   $0x1f000
   163f0:	e8 6d c0 ff ff       	call   12462 <kpanic>
   163f5:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   163f8:	a1 e0 18 02 00       	mov    0x218e0,%eax
   163fd:	85 c0                	test   %eax,%eax
   163ff:	74 1c                	je     1641d <sys_gettime+0x6c>
   16401:	8b 45 08             	mov    0x8(%ebp),%eax
   16404:	8b 40 18             	mov    0x18(%eax),%eax
   16407:	83 ec 04             	sub    $0x4,%esp
   1640a:	50                   	push   %eax
   1640b:	68 dc b8 01 00       	push   $0x1b8dc
   16410:	68 ea b6 01 00       	push   $0x1b6ea
   16415:	e8 0d b1 ff ff       	call   11527 <cio_printf>
   1641a:	83 c4 10             	add    $0x10,%esp

	// return the time
	RET(pcb) = system_time;
   1641d:	8b 45 08             	mov    0x8(%ebp),%eax
   16420:	8b 00                	mov    (%eax),%eax
   16422:	8b 15 bc e1 01 00    	mov    0x1e1bc,%edx
   16428:	89 50 30             	mov    %edx,0x30(%eax)
}
   1642b:	90                   	nop
   1642c:	c9                   	leave  
   1642d:	c3                   	ret    

0001642e <sys_getprio>:
** sys_getprio - the scheduling priority of the calling process
**
** Implements:
**		int getprio( void );
*/
SYSIMPL(getprio) {
   1642e:	55                   	push   %ebp
   1642f:	89 e5                	mov    %esp,%ebp
   16431:	83 ec 08             	sub    $0x8,%esp

	// sanity check!
	assert( pcb != NULL );
   16434:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16438:	75 3b                	jne    16475 <sys_getprio+0x47>
   1643a:	83 ec 04             	sub    $0x4,%esp
   1643d:	68 c0 b6 01 00       	push   $0x1b6c0
   16442:	6a 00                	push   $0x0
   16444:	68 66 02 00 00       	push   $0x266
   16449:	68 c9 b6 01 00       	push   $0x1b6c9
   1644e:	68 e8 b8 01 00       	push   $0x1b8e8
   16453:	68 d4 b6 01 00       	push   $0x1b6d4
   16458:	68 00 f0 01 00       	push   $0x1f000
   1645d:	e8 80 c2 ff ff       	call   126e2 <sprint>
   16462:	83 c4 20             	add    $0x20,%esp
   16465:	83 ec 0c             	sub    $0xc,%esp
   16468:	68 00 f0 01 00       	push   $0x1f000
   1646d:	e8 f0 bf ff ff       	call   12462 <kpanic>
   16472:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   16475:	a1 e0 18 02 00       	mov    0x218e0,%eax
   1647a:	85 c0                	test   %eax,%eax
   1647c:	74 1c                	je     1649a <sys_getprio+0x6c>
   1647e:	8b 45 08             	mov    0x8(%ebp),%eax
   16481:	8b 40 18             	mov    0x18(%eax),%eax
   16484:	83 ec 04             	sub    $0x4,%esp
   16487:	50                   	push   %eax
   16488:	68 e8 b8 01 00       	push   $0x1b8e8
   1648d:	68 ea b6 01 00       	push   $0x1b6ea
   16492:	e8 90 b0 ff ff       	call   11527 <cio_printf>
   16497:	83 c4 10             	add    $0x10,%esp

	// return the time
	RET(pcb) = pcb->priority;
   1649a:	8b 45 08             	mov    0x8(%ebp),%eax
   1649d:	8b 00                	mov    (%eax),%eax
   1649f:	8b 55 08             	mov    0x8(%ebp),%edx
   164a2:	8b 52 20             	mov    0x20(%edx),%edx
   164a5:	89 50 30             	mov    %edx,0x30(%eax)
}
   164a8:	90                   	nop
   164a9:	c9                   	leave  
   164aa:	c3                   	ret    

000164ab <sys_setprio>:
** sys_setprio - sets the scheduling priority of the calling process
**
** Implements:
**		int setprio( int new );
*/
SYSIMPL(setprio) {
   164ab:	55                   	push   %ebp
   164ac:	89 e5                	mov    %esp,%ebp
   164ae:	83 ec 18             	sub    $0x18,%esp

	// sanity check!
	assert( pcb != NULL );
   164b1:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   164b5:	75 3b                	jne    164f2 <sys_setprio+0x47>
   164b7:	83 ec 04             	sub    $0x4,%esp
   164ba:	68 c0 b6 01 00       	push   $0x1b6c0
   164bf:	6a 00                	push   $0x0
   164c1:	68 77 02 00 00       	push   $0x277
   164c6:	68 c9 b6 01 00       	push   $0x1b6c9
   164cb:	68 f4 b8 01 00       	push   $0x1b8f4
   164d0:	68 d4 b6 01 00       	push   $0x1b6d4
   164d5:	68 00 f0 01 00       	push   $0x1f000
   164da:	e8 03 c2 ff ff       	call   126e2 <sprint>
   164df:	83 c4 20             	add    $0x20,%esp
   164e2:	83 ec 0c             	sub    $0xc,%esp
   164e5:	68 00 f0 01 00       	push   $0x1f000
   164ea:	e8 73 bf ff ff       	call   12462 <kpanic>
   164ef:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   164f2:	a1 e0 18 02 00       	mov    0x218e0,%eax
   164f7:	85 c0                	test   %eax,%eax
   164f9:	74 1c                	je     16517 <sys_setprio+0x6c>
   164fb:	8b 45 08             	mov    0x8(%ebp),%eax
   164fe:	8b 40 18             	mov    0x18(%eax),%eax
   16501:	83 ec 04             	sub    $0x4,%esp
   16504:	50                   	push   %eax
   16505:	68 f4 b8 01 00       	push   $0x1b8f4
   1650a:	68 ea b6 01 00       	push   $0x1b6ea
   1650f:	e8 13 b0 ff ff       	call   11527 <cio_printf>
   16514:	83 c4 10             	add    $0x10,%esp

	// remember the old priority
	int old = pcb->priority;
   16517:	8b 45 08             	mov    0x8(%ebp),%eax
   1651a:	8b 40 20             	mov    0x20(%eax),%eax
   1651d:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// set the priority
	pcb->priority = ARG(pcb,1);
   16520:	8b 45 08             	mov    0x8(%ebp),%eax
   16523:	8b 00                	mov    (%eax),%eax
   16525:	83 c0 48             	add    $0x48,%eax
   16528:	83 c0 04             	add    $0x4,%eax
   1652b:	8b 10                	mov    (%eax),%edx
   1652d:	8b 45 08             	mov    0x8(%ebp),%eax
   16530:	89 50 20             	mov    %edx,0x20(%eax)

	// return the old value
	RET(pcb) = old;
   16533:	8b 45 08             	mov    0x8(%ebp),%eax
   16536:	8b 00                	mov    (%eax),%eax
   16538:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1653b:	89 50 30             	mov    %edx,0x30(%eax)
}
   1653e:	90                   	nop
   1653f:	c9                   	leave  
   16540:	c3                   	ret    

00016541 <sys_kill>:
**		int32_t kill( uint_t pid );
**
** Marks the specified process (or the calling process, if PID is 0)
** as "killed". Returns 0 on success, else an error code.
*/
SYSIMPL(kill) {
   16541:	55                   	push   %ebp
   16542:	89 e5                	mov    %esp,%ebp
   16544:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   16547:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1654b:	75 3b                	jne    16588 <sys_kill+0x47>
   1654d:	83 ec 04             	sub    $0x4,%esp
   16550:	68 c0 b6 01 00       	push   $0x1b6c0
   16555:	6a 00                	push   $0x0
   16557:	68 91 02 00 00       	push   $0x291
   1655c:	68 c9 b6 01 00       	push   $0x1b6c9
   16561:	68 00 b9 01 00       	push   $0x1b900
   16566:	68 d4 b6 01 00       	push   $0x1b6d4
   1656b:	68 00 f0 01 00       	push   $0x1f000
   16570:	e8 6d c1 ff ff       	call   126e2 <sprint>
   16575:	83 c4 20             	add    $0x20,%esp
   16578:	83 ec 0c             	sub    $0xc,%esp
   1657b:	68 00 f0 01 00       	push   $0x1f000
   16580:	e8 dd be ff ff       	call   12462 <kpanic>
   16585:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   16588:	a1 e0 18 02 00       	mov    0x218e0,%eax
   1658d:	85 c0                	test   %eax,%eax
   1658f:	74 1c                	je     165ad <sys_kill+0x6c>
   16591:	8b 45 08             	mov    0x8(%ebp),%eax
   16594:	8b 40 18             	mov    0x18(%eax),%eax
   16597:	83 ec 04             	sub    $0x4,%esp
   1659a:	50                   	push   %eax
   1659b:	68 00 b9 01 00       	push   $0x1b900
   165a0:	68 ea b6 01 00       	push   $0x1b6ea
   165a5:	e8 7d af ff ff       	call   11527 <cio_printf>
   165aa:	83 c4 10             	add    $0x10,%esp

	// who is the victim?
	uint_t pid = ARG(pcb,1);
   165ad:	8b 45 08             	mov    0x8(%ebp),%eax
   165b0:	8b 00                	mov    (%eax),%eax
   165b2:	83 c0 48             	add    $0x48,%eax
   165b5:	8b 40 04             	mov    0x4(%eax),%eax
   165b8:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// if it's this process, convert this into a call to exit()
	if( pid == pcb->pid ) {
   165bb:	8b 45 08             	mov    0x8(%ebp),%eax
   165be:	8b 40 18             	mov    0x18(%eax),%eax
   165c1:	39 45 f0             	cmp    %eax,-0x10(%ebp)
   165c4:	75 50                	jne    16616 <sys_kill+0xd5>
		pcb->exit_status = EXIT_KILLED;
   165c6:	8b 45 08             	mov    0x8(%ebp),%eax
   165c9:	c7 40 14 9b ff ff ff 	movl   $0xffffff9b,0x14(%eax)
		pcb_zombify( pcb );
   165d0:	83 ec 0c             	sub    $0xc,%esp
   165d3:	ff 75 08             	pushl  0x8(%ebp)
   165d6:	e8 12 d4 ff ff       	call   139ed <pcb_zombify>
   165db:	83 c4 10             	add    $0x10,%esp
		// reset 'current' to keep dispatch() happy
		current = NULL;
   165de:	c7 05 14 10 02 00 00 	movl   $0x0,0x21014
   165e5:	00 00 00 
		dispatch();
   165e8:	e8 7e de ff ff       	call   1446b <dispatch>
		SYSCALL_EXIT( EXIT_KILLED );
   165ed:	a1 e0 18 02 00       	mov    0x218e0,%eax
   165f2:	85 c0                	test   %eax,%eax
   165f4:	0f 84 2e 02 00 00    	je     16828 <sys_kill+0x2e7>
   165fa:	83 ec 04             	sub    $0x4,%esp
   165fd:	6a 9b                	push   $0xffffff9b
   165ff:	68 00 b9 01 00       	push   $0x1b900
   16604:	68 fb b6 01 00       	push   $0x1b6fb
   16609:	e8 19 af ff ff       	call   11527 <cio_printf>
   1660e:	83 c4 10             	add    $0x10,%esp
		return;
   16611:	e9 12 02 00 00       	jmp    16828 <sys_kill+0x2e7>
	}

	// must be a valid "ordinary user" PID
	// QUESTION: what if it's the idle process?
	if( pid < FIRST_USER_PID ) {
   16616:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
   1661a:	77 35                	ja     16651 <sys_kill+0x110>
		RET(pcb) = E_FAILURE;
   1661c:	8b 45 08             	mov    0x8(%ebp),%eax
   1661f:	8b 00                	mov    (%eax),%eax
   16621:	c7 40 30 ff ff ff ff 	movl   $0xffffffff,0x30(%eax)
		SYSCALL_EXIT( E_FAILURE );
   16628:	a1 e0 18 02 00       	mov    0x218e0,%eax
   1662d:	85 c0                	test   %eax,%eax
   1662f:	0f 84 f6 01 00 00    	je     1682b <sys_kill+0x2ea>
   16635:	83 ec 04             	sub    $0x4,%esp
   16638:	6a ff                	push   $0xffffffff
   1663a:	68 00 b9 01 00       	push   $0x1b900
   1663f:	68 fb b6 01 00       	push   $0x1b6fb
   16644:	e8 de ae ff ff       	call   11527 <cio_printf>
   16649:	83 c4 10             	add    $0x10,%esp
		return;
   1664c:	e9 da 01 00 00       	jmp    1682b <sys_kill+0x2ea>
	}

	// OK, this is an acceptable victim; see if it exists
	pcb_t *victim = pcb_find_pid( pid );
   16651:	83 ec 0c             	sub    $0xc,%esp
   16654:	ff 75 f0             	pushl  -0x10(%ebp)
   16657:	e8 52 d6 ff ff       	call   13cae <pcb_find_pid>
   1665c:	83 c4 10             	add    $0x10,%esp
   1665f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if( victim == NULL ) {
   16662:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
   16666:	75 35                	jne    1669d <sys_kill+0x15c>
		// nope!
		RET(pcb) = E_NOT_FOUND;
   16668:	8b 45 08             	mov    0x8(%ebp),%eax
   1666b:	8b 00                	mov    (%eax),%eax
   1666d:	c7 40 30 fa ff ff ff 	movl   $0xfffffffa,0x30(%eax)
		SYSCALL_EXIT( E_NOT_FOUND );
   16674:	a1 e0 18 02 00       	mov    0x218e0,%eax
   16679:	85 c0                	test   %eax,%eax
   1667b:	0f 84 ad 01 00 00    	je     1682e <sys_kill+0x2ed>
   16681:	83 ec 04             	sub    $0x4,%esp
   16684:	6a fa                	push   $0xfffffffa
   16686:	68 00 b9 01 00       	push   $0x1b900
   1668b:	68 fb b6 01 00       	push   $0x1b6fb
   16690:	e8 92 ae ff ff       	call   11527 <cio_printf>
   16695:	83 c4 10             	add    $0x10,%esp
		return;
   16698:	e9 91 01 00 00       	jmp    1682e <sys_kill+0x2ed>
	}

	// must have a state that is possible
	assert( victim->state >= FIRST_VIABLE && victim->state < N_STATES );
   1669d:	8b 45 ec             	mov    -0x14(%ebp),%eax
   166a0:	8b 40 1c             	mov    0x1c(%eax),%eax
   166a3:	83 f8 01             	cmp    $0x1,%eax
   166a6:	76 0b                	jbe    166b3 <sys_kill+0x172>
   166a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
   166ab:	8b 40 1c             	mov    0x1c(%eax),%eax
   166ae:	83 f8 08             	cmp    $0x8,%eax
   166b1:	76 3b                	jbe    166ee <sys_kill+0x1ad>
   166b3:	83 ec 04             	sub    $0x4,%esp
   166b6:	68 60 b7 01 00       	push   $0x1b760
   166bb:	6a 00                	push   $0x0
   166bd:	68 b5 02 00 00       	push   $0x2b5
   166c2:	68 c9 b6 01 00       	push   $0x1b6c9
   166c7:	68 00 b9 01 00       	push   $0x1b900
   166cc:	68 d4 b6 01 00       	push   $0x1b6d4
   166d1:	68 00 f0 01 00       	push   $0x1f000
   166d6:	e8 07 c0 ff ff       	call   126e2 <sprint>
   166db:	83 c4 20             	add    $0x20,%esp
   166de:	83 ec 0c             	sub    $0xc,%esp
   166e1:	68 00 f0 01 00       	push   $0x1f000
   166e6:	e8 77 bd ff ff       	call   12462 <kpanic>
   166eb:	83 c4 10             	add    $0x10,%esp

	// how we perform the kill depends on the victim's state
	int32_t status = SUCCESS;
   166ee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	switch( victim->state ) {
   166f5:	8b 45 ec             	mov    -0x14(%ebp),%eax
   166f8:	8b 40 1c             	mov    0x1c(%eax),%eax
   166fb:	83 f8 08             	cmp    $0x8,%eax
   166fe:	0f 87 a4 00 00 00    	ja     167a8 <sys_kill+0x267>
   16704:	8b 04 85 c8 b7 01 00 	mov    0x1b7c8(,%eax,4),%eax
   1670b:	ff e0                	jmp    *%eax

	case STATE_KILLED:    // FALL THROUGH
	case STATE_ZOMBIE:
		// you can't kill it if it's already dead
		RET(pcb) = SUCCESS;
   1670d:	8b 45 08             	mov    0x8(%ebp),%eax
   16710:	8b 00                	mov    (%eax),%eax
   16712:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
		break;
   16719:	e9 e5 00 00 00       	jmp    16803 <sys_kill+0x2c2>
	case STATE_READY:     // FALL THROUGH
	case STATE_SLEEPING:  // FALL THROUGH
	case STATE_BLOCKED:   // FALL THROUGH
		// here, the process is on a queue somewhere; mark
		// it as "killed", and let the scheduler deal with it
		victim->state = STATE_KILLED;
   1671e:	8b 45 ec             	mov    -0x14(%ebp),%eax
   16721:	c7 40 1c 07 00 00 00 	movl   $0x7,0x1c(%eax)
		RET(pcb) = SUCCESS;
   16728:	8b 45 08             	mov    0x8(%ebp),%eax
   1672b:	8b 00                	mov    (%eax),%eax
   1672d:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)
		break;
   16734:	e9 ca 00 00 00       	jmp    16803 <sys_kill+0x2c2>

	case STATE_RUNNING:
		// we have met the enemy, and it is us!
		pcb->exit_status = EXIT_KILLED;
   16739:	8b 45 08             	mov    0x8(%ebp),%eax
   1673c:	c7 40 14 9b ff ff ff 	movl   $0xffffff9b,0x14(%eax)
		pcb_zombify( pcb );
   16743:	83 ec 0c             	sub    $0xc,%esp
   16746:	ff 75 08             	pushl  0x8(%ebp)
   16749:	e8 9f d2 ff ff       	call   139ed <pcb_zombify>
   1674e:	83 c4 10             	add    $0x10,%esp
		status = EXIT_KILLED;
   16751:	c7 45 f4 9b ff ff ff 	movl   $0xffffff9b,-0xc(%ebp)
		// we need a new current process
		// reset 'current' to keep dispatch() happy
		current = NULL;
   16758:	c7 05 14 10 02 00 00 	movl   $0x0,0x21014
   1675f:	00 00 00 
		dispatch();
   16762:	e8 04 dd ff ff       	call   1446b <dispatch>
		break;
   16767:	e9 97 00 00 00       	jmp    16803 <sys_kill+0x2c2>

	case STATE_WAITING:
		// similar to the 'running' state, but we don't need
		// to dispatch a new process
		victim->exit_status = EXIT_KILLED;
   1676c:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1676f:	c7 40 14 9b ff ff ff 	movl   $0xffffff9b,0x14(%eax)
		status = pcb_queue_remove_this( waiting, victim );
   16776:	a1 10 10 02 00       	mov    0x21010,%eax
   1677b:	83 ec 08             	sub    $0x8,%esp
   1677e:	ff 75 ec             	pushl  -0x14(%ebp)
   16781:	50                   	push   %eax
   16782:	e8 07 da ff ff       	call   1418e <pcb_queue_remove_this>
   16787:	83 c4 10             	add    $0x10,%esp
   1678a:	89 45 f4             	mov    %eax,-0xc(%ebp)
		pcb_zombify( victim );
   1678d:	83 ec 0c             	sub    $0xc,%esp
   16790:	ff 75 ec             	pushl  -0x14(%ebp)
   16793:	e8 55 d2 ff ff       	call   139ed <pcb_zombify>
   16798:	83 c4 10             	add    $0x10,%esp
		RET(pcb) = status;
   1679b:	8b 45 08             	mov    0x8(%ebp),%eax
   1679e:	8b 00                	mov    (%eax),%eax
   167a0:	8b 55 f4             	mov    -0xc(%ebp),%edx
   167a3:	89 50 30             	mov    %edx,0x30(%eax)
		break;
   167a6:	eb 5b                	jmp    16803 <sys_kill+0x2c2>
	default:
		// this is a really bad potential problem - we have an
		// unexpected or bogus process state, but we didn't
		// catch that earlier.
		sprint( b256, "*** kill(): victim %d, odd state %d\n",
				victim->pid, victim->state );
   167a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
   167ab:	8b 50 1c             	mov    0x1c(%eax),%edx
		sprint( b256, "*** kill(): victim %d, odd state %d\n",
   167ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
   167b1:	8b 40 18             	mov    0x18(%eax),%eax
   167b4:	52                   	push   %edx
   167b5:	50                   	push   %eax
   167b6:	68 9c b7 01 00       	push   $0x1b79c
   167bb:	68 00 f2 01 00       	push   $0x1f200
   167c0:	e8 1d bf ff ff       	call   126e2 <sprint>
   167c5:	83 c4 10             	add    $0x10,%esp
		PANIC( 0, b256 );
   167c8:	83 ec 04             	sub    $0x4,%esp
   167cb:	68 c1 b7 01 00       	push   $0x1b7c1
   167d0:	6a 00                	push   $0x0
   167d2:	68 e5 02 00 00       	push   $0x2e5
   167d7:	68 c9 b6 01 00       	push   $0x1b6c9
   167dc:	68 00 b9 01 00       	push   $0x1b900
   167e1:	68 d4 b6 01 00       	push   $0x1b6d4
   167e6:	68 00 f0 01 00       	push   $0x1f000
   167eb:	e8 f2 be ff ff       	call   126e2 <sprint>
   167f0:	83 c4 20             	add    $0x20,%esp
   167f3:	83 ec 0c             	sub    $0xc,%esp
   167f6:	68 00 f0 01 00       	push   $0x1f000
   167fb:	e8 62 bc ff ff       	call   12462 <kpanic>
   16800:	83 c4 10             	add    $0x10,%esp
	}

	SYSCALL_EXIT( status );
   16803:	a1 e0 18 02 00       	mov    0x218e0,%eax
   16808:	85 c0                	test   %eax,%eax
   1680a:	74 25                	je     16831 <sys_kill+0x2f0>
   1680c:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1680f:	83 ec 04             	sub    $0x4,%esp
   16812:	50                   	push   %eax
   16813:	68 00 b9 01 00       	push   $0x1b900
   16818:	68 fb b6 01 00       	push   $0x1b6fb
   1681d:	e8 05 ad ff ff       	call   11527 <cio_printf>
   16822:	83 c4 10             	add    $0x10,%esp
	return;
   16825:	90                   	nop
   16826:	eb 09                	jmp    16831 <sys_kill+0x2f0>
		return;
   16828:	90                   	nop
   16829:	eb 07                	jmp    16832 <sys_kill+0x2f1>
		return;
   1682b:	90                   	nop
   1682c:	eb 04                	jmp    16832 <sys_kill+0x2f1>
		return;
   1682e:	90                   	nop
   1682f:	eb 01                	jmp    16832 <sys_kill+0x2f1>
	return;
   16831:	90                   	nop
}
   16832:	c9                   	leave  
   16833:	c3                   	ret    

00016834 <sys_sleep>:
**		uint_t sleep( uint_t ms );
**
** Puts the calling process to sleep for 'ms' milliseconds (or just yields
** the CPU if 'ms' is 0).  ** Returns the time the process spent sleeping.
*/
SYSIMPL(sleep) {
   16834:	55                   	push   %ebp
   16835:	89 e5                	mov    %esp,%ebp
   16837:	83 ec 18             	sub    $0x18,%esp

	// sanity check
	assert( pcb != NULL );
   1683a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   1683e:	75 3b                	jne    1687b <sys_sleep+0x47>
   16840:	83 ec 04             	sub    $0x4,%esp
   16843:	68 c0 b6 01 00       	push   $0x1b6c0
   16848:	6a 00                	push   $0x0
   1684a:	68 f9 02 00 00       	push   $0x2f9
   1684f:	68 c9 b6 01 00       	push   $0x1b6c9
   16854:	68 0c b9 01 00       	push   $0x1b90c
   16859:	68 d4 b6 01 00       	push   $0x1b6d4
   1685e:	68 00 f0 01 00       	push   $0x1f000
   16863:	e8 7a be ff ff       	call   126e2 <sprint>
   16868:	83 c4 20             	add    $0x20,%esp
   1686b:	83 ec 0c             	sub    $0xc,%esp
   1686e:	68 00 f0 01 00       	push   $0x1f000
   16873:	e8 ea bb ff ff       	call   12462 <kpanic>
   16878:	83 c4 10             	add    $0x10,%esp

	SYSCALL_ENTER( pcb->pid );
   1687b:	a1 e0 18 02 00       	mov    0x218e0,%eax
   16880:	85 c0                	test   %eax,%eax
   16882:	74 1c                	je     168a0 <sys_sleep+0x6c>
   16884:	8b 45 08             	mov    0x8(%ebp),%eax
   16887:	8b 40 18             	mov    0x18(%eax),%eax
   1688a:	83 ec 04             	sub    $0x4,%esp
   1688d:	50                   	push   %eax
   1688e:	68 0c b9 01 00       	push   $0x1b90c
   16893:	68 ea b6 01 00       	push   $0x1b6ea
   16898:	e8 8a ac ff ff       	call   11527 <cio_printf>
   1689d:	83 c4 10             	add    $0x10,%esp

	// get the desired duration
	uint_t length = ARG( pcb, 1 );
   168a0:	8b 45 08             	mov    0x8(%ebp),%eax
   168a3:	8b 00                	mov    (%eax),%eax
   168a5:	83 c0 48             	add    $0x48,%eax
   168a8:	8b 40 04             	mov    0x4(%eax),%eax
   168ab:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if( length == 0 ) {
   168ae:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   168b2:	75 1c                	jne    168d0 <sys_sleep+0x9c>

		// just yield the CPU
		// sleep duration is 0
		RET(pcb) = 0;
   168b4:	8b 45 08             	mov    0x8(%ebp),%eax
   168b7:	8b 00                	mov    (%eax),%eax
   168b9:	c7 40 30 00 00 00 00 	movl   $0x0,0x30(%eax)

		// back on the ready queue
		schedule( pcb );
   168c0:	83 ec 0c             	sub    $0xc,%esp
   168c3:	ff 75 08             	pushl  0x8(%ebp)
   168c6:	e8 df da ff ff       	call   143aa <schedule>
   168cb:	83 c4 10             	add    $0x10,%esp
   168ce:	eb 7a                	jmp    1694a <sys_sleep+0x116>

	} else {

		// sleep for a while
		pcb->wakeup = system_time + length;
   168d0:	8b 15 bc e1 01 00    	mov    0x1e1bc,%edx
   168d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
   168d9:	01 c2                	add    %eax,%edx
   168db:	8b 45 08             	mov    0x8(%ebp),%eax
   168de:	89 50 10             	mov    %edx,0x10(%eax)

		if( pcb_queue_insert(sleeping,pcb) != SUCCESS ) {
   168e1:	a1 08 10 02 00       	mov    0x21008,%eax
   168e6:	83 ec 08             	sub    $0x8,%esp
   168e9:	ff 75 08             	pushl  0x8(%ebp)
   168ec:	50                   	push   %eax
   168ed:	e8 df d5 ff ff       	call   13ed1 <pcb_queue_insert>
   168f2:	83 c4 10             	add    $0x10,%esp
   168f5:	85 c0                	test   %eax,%eax
   168f7:	74 51                	je     1694a <sys_sleep+0x116>
			// something strange is happening
			WARNING( "sleep pcb insert failed" );
   168f9:	68 10 03 00 00       	push   $0x310
   168fe:	68 c9 b6 01 00       	push   $0x1b6c9
   16903:	68 0c b9 01 00       	push   $0x1b90c
   16908:	68 ec b7 01 00       	push   $0x1b7ec
   1690d:	e8 15 ac ff ff       	call   11527 <cio_printf>
   16912:	83 c4 10             	add    $0x10,%esp
   16915:	83 ec 0c             	sub    $0xc,%esp
   16918:	68 ff b7 01 00       	push   $0x1b7ff
   1691d:	e8 8b a5 ff ff       	call   10ead <cio_puts>
   16922:	83 c4 10             	add    $0x10,%esp
   16925:	83 ec 0c             	sub    $0xc,%esp
   16928:	6a 0a                	push   $0xa
   1692a:	e8 3e a4 ff ff       	call   10d6d <cio_putchar>
   1692f:	83 c4 10             	add    $0x10,%esp
			// if this is the current process, report an error
			if( current == pcb ) {
   16932:	a1 14 10 02 00       	mov    0x21014,%eax
   16937:	39 45 08             	cmp    %eax,0x8(%ebp)
   1693a:	75 29                	jne    16965 <sys_sleep+0x131>
				RET(pcb) = -1;
   1693c:	8b 45 08             	mov    0x8(%ebp),%eax
   1693f:	8b 00                	mov    (%eax),%eax
   16941:	c7 40 30 ff ff ff ff 	movl   $0xffffffff,0x30(%eax)
			}
			// return without dispatching a new process
			return;
   16948:	eb 1b                	jmp    16965 <sys_sleep+0x131>
		}
	}

	// only dispatch if the current process called us
	if( pcb == current ) {
   1694a:	a1 14 10 02 00       	mov    0x21014,%eax
   1694f:	39 45 08             	cmp    %eax,0x8(%ebp)
   16952:	75 12                	jne    16966 <sys_sleep+0x132>
		current = NULL;
   16954:	c7 05 14 10 02 00 00 	movl   $0x0,0x21014
   1695b:	00 00 00 
		dispatch();
   1695e:	e8 08 db ff ff       	call   1446b <dispatch>
   16963:	eb 01                	jmp    16966 <sys_sleep+0x132>
			return;
   16965:	90                   	nop
	}
}
   16966:	c9                   	leave  
   16967:	c3                   	ret    

00016968 <sys_isr>:
** System call ISR
**
** @param vector   Vector number for this interrupt
** @param code     Error code (0 for this interrupt)
*/
static void sys_isr( int vector, int code ) {
   16968:	55                   	push   %ebp
   16969:	89 e5                	mov    %esp,%ebp
   1696b:	83 ec 18             	sub    $0x18,%esp
	// keep the compiler happy
	(void) vector;
	(void) code;

	// sanity check!
	assert( current != NULL );
   1696e:	a1 14 10 02 00       	mov    0x21014,%eax
   16973:	85 c0                	test   %eax,%eax
   16975:	75 3b                	jne    169b2 <sys_isr+0x4a>
   16977:	83 ec 04             	sub    $0x4,%esp
   1697a:	68 54 b8 01 00       	push   $0x1b854
   1697f:	6a 00                	push   $0x0
   16981:	68 4d 03 00 00       	push   $0x34d
   16986:	68 c9 b6 01 00       	push   $0x1b6c9
   1698b:	68 18 b9 01 00       	push   $0x1b918
   16990:	68 d4 b6 01 00       	push   $0x1b6d4
   16995:	68 00 f0 01 00       	push   $0x1f000
   1699a:	e8 43 bd ff ff       	call   126e2 <sprint>
   1699f:	83 c4 20             	add    $0x20,%esp
   169a2:	83 ec 0c             	sub    $0xc,%esp
   169a5:	68 00 f0 01 00       	push   $0x1f000
   169aa:	e8 b3 ba ff ff       	call   12462 <kpanic>
   169af:	83 c4 10             	add    $0x10,%esp
	assert( current->context != NULL );
   169b2:	a1 14 10 02 00       	mov    0x21014,%eax
   169b7:	8b 00                	mov    (%eax),%eax
   169b9:	85 c0                	test   %eax,%eax
   169bb:	75 3b                	jne    169f8 <sys_isr+0x90>
   169bd:	83 ec 04             	sub    $0x4,%esp
   169c0:	68 61 b8 01 00       	push   $0x1b861
   169c5:	6a 00                	push   $0x0
   169c7:	68 4e 03 00 00       	push   $0x34e
   169cc:	68 c9 b6 01 00       	push   $0x1b6c9
   169d1:	68 18 b9 01 00       	push   $0x1b918
   169d6:	68 d4 b6 01 00       	push   $0x1b6d4
   169db:	68 00 f0 01 00       	push   $0x1f000
   169e0:	e8 fd bc ff ff       	call   126e2 <sprint>
   169e5:	83 c4 20             	add    $0x20,%esp
   169e8:	83 ec 0c             	sub    $0xc,%esp
   169eb:	68 00 f0 01 00       	push   $0x1f000
   169f0:	e8 6d ba ff ff       	call   12462 <kpanic>
   169f5:	83 c4 10             	add    $0x10,%esp

	// retrieve the syscall code
	int num = REG( current, eax );
   169f8:	a1 14 10 02 00       	mov    0x21014,%eax
   169fd:	8b 00                	mov    (%eax),%eax
   169ff:	8b 40 30             	mov    0x30(%eax),%eax
   16a02:	89 45 f4             	mov    %eax,-0xc(%ebp)
#if TRACING_SYSCALLS
	cio_printf( "** --> SYS pid %u code %u\n", current->pid, num );
#endif

	// validate it
	if( num < 0 || num >= N_SYSCALLS ) {
   16a05:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   16a09:	78 06                	js     16a11 <sys_isr+0xa9>
   16a0b:	83 7d f4 0c          	cmpl   $0xc,-0xc(%ebp)
   16a0f:	7e 1a                	jle    16a2b <sys_isr+0xc3>
		// bad syscall number
		// could kill it, but we'll just force it to exit
		num = SYS_exit;
   16a11:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
		ARG(current,1) = EXIT_BAD_SYSCALL;
   16a18:	a1 14 10 02 00       	mov    0x21014,%eax
   16a1d:	8b 00                	mov    (%eax),%eax
   16a1f:	83 c0 48             	add    $0x48,%eax
   16a22:	83 c0 04             	add    $0x4,%eax
   16a25:	c7 00 9a ff ff ff    	movl   $0xffffff9a,(%eax)
	}

	// call the handler
	syscalls[num]( current );
   16a2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16a2e:	8b 04 85 20 b8 01 00 	mov    0x1b820(,%eax,4),%eax
   16a35:	8b 15 14 10 02 00    	mov    0x21014,%edx
   16a3b:	83 ec 0c             	sub    $0xc,%esp
   16a3e:	52                   	push   %edx
   16a3f:	ff d0                	call   *%eax
   16a41:	83 c4 10             	add    $0x10,%esp
   16a44:	c7 45 f0 20 00 00 00 	movl   $0x20,-0x10(%ebp)
   16a4b:	c6 45 ef 20          	movb   $0x20,-0x11(%ebp)
   16a4f:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
   16a53:	8b 55 f0             	mov    -0x10(%ebp),%edx
   16a56:	ee                   	out    %al,(%dx)
	cio_printf( "** <-- SYS pid %u ret %u\n", current->pid, RET(current) );
#endif

	// tell the PIC we're done
	outb( PIC1_CMD, PIC_EOI );
}
   16a57:	90                   	nop
   16a58:	c9                   	leave  
   16a59:	c3                   	ret    

00016a5a <sys_init>:
** Syscall module initialization routine
**
** Dependencies:
**    Must be called after cio_init()
*/
void sys_init( void ) {
   16a5a:	55                   	push   %ebp
   16a5b:	89 e5                	mov    %esp,%ebp
   16a5d:	83 ec 08             	sub    $0x8,%esp

#if TRACING_INIT
	cio_puts( " Sys" );
   16a60:	83 ec 0c             	sub    $0xc,%esp
   16a63:	68 77 b8 01 00       	push   $0x1b877
   16a68:	e8 40 a4 ff ff       	call   10ead <cio_puts>
   16a6d:	83 c4 10             	add    $0x10,%esp
#endif

	// install the second-stage ISR
	install_isr( VEC_SYSCALL, sys_isr );
   16a70:	83 ec 08             	sub    $0x8,%esp
   16a73:	68 68 69 01 00       	push   $0x16968
   16a78:	68 80 00 00 00       	push   $0x80
   16a7d:	e8 df ec ff ff       	call   15761 <install_isr>
   16a82:	83 c4 10             	add    $0x10,%esp
}
   16a85:	90                   	nop
   16a86:	c9                   	leave  
   16a87:	c3                   	ret    

00016a88 <stack_setup>:
** @param sys    Is the argument vector from kernel code?
**
** @return A (user VA) pointer to the context_t on the stack, or NULL
*/
context_t *stack_setup( pcb_t *pcb, uint32_t entry,
		const char **args, bool_t sys ) {
   16a88:	55                   	push   %ebp
   16a89:	89 e5                	mov    %esp,%ebp
   16a8b:	57                   	push   %edi
   16a8c:	56                   	push   %esi
   16a8d:	53                   	push   %ebx
   16a8e:	81 ec cc 00 00 00    	sub    $0xcc,%esp
   16a94:	8b 45 14             	mov    0x14(%ebp),%eax
   16a97:	88 85 34 ff ff ff    	mov    %al,-0xcc(%ebp)
	**       the remainder of the aggregate shall be initialized
	**       implicitly the same as objects that have static storage
	**       duration."
	*/

	int argbytes = 0;                    // total length of arg strings
   16a9d:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
	int argc = 0;                        // number of argv entries
   16aa4:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
	const char *kv_strs[N_ARGS] = { 0 }; // converted user arg string pointers
   16aab:	8d 55 88             	lea    -0x78(%ebp),%edx
   16aae:	b8 00 00 00 00       	mov    $0x0,%eax
   16ab3:	b9 0a 00 00 00       	mov    $0xa,%ecx
   16ab8:	89 d7                	mov    %edx,%edi
   16aba:	f3 ab                	rep stos %eax,%es:(%edi)
	int strlengths[N_ARGS] = { 0 };      // length of each string
   16abc:	8d 95 60 ff ff ff    	lea    -0xa0(%ebp),%edx
   16ac2:	b8 00 00 00 00       	mov    $0x0,%eax
   16ac7:	b9 0a 00 00 00       	mov    $0xa,%ecx
   16acc:	89 d7                	mov    %edx,%edi
   16ace:	f3 ab                	rep stos %eax,%es:(%edi)
	int uv_offsets[N_ARGS] = { 0 };      // offsets into string buffer
   16ad0:	8d 95 38 ff ff ff    	lea    -0xc8(%ebp),%edx
   16ad6:	b8 00 00 00 00       	mov    $0x0,%eax
   16adb:	b9 0a 00 00 00       	mov    $0xa,%ecx
   16ae0:	89 d7                	mov    %edx,%edi
   16ae2:	f3 ab                	rep stos %eax,%es:(%edi)
	/*
	** IF the argument list given to us came from  user code, we need
	** to convert its address and the addresses it contains to kernel
	** VAs; otherwise, we can use them directly.
	*/
	const char **kv_args = args;
   16ae4:	8b 45 10             	mov    0x10(%ebp),%eax
   16ae7:	89 45 cc             	mov    %eax,-0x34(%ebp)

	while( kv_args[argc] != NULL ) {
   16aea:	eb 61                	jmp    16b4d <stack_setup+0xc5>
		kv_strs[argc] = args[argc];
   16aec:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16aef:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   16af6:	8b 45 10             	mov    0x10(%ebp),%eax
   16af9:	01 d0                	add    %edx,%eax
   16afb:	8b 10                	mov    (%eax),%edx
   16afd:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b00:	89 54 85 88          	mov    %edx,-0x78(%ebp,%eax,4)
		strlengths[argc] = strlen( kv_strs[argc] ) + 1;
   16b04:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b07:	8b 44 85 88          	mov    -0x78(%ebp,%eax,4),%eax
   16b0b:	83 ec 0c             	sub    $0xc,%esp
   16b0e:	50                   	push   %eax
   16b0f:	e8 4b bf ff ff       	call   12a5f <strlen>
   16b14:	83 c4 10             	add    $0x10,%esp
   16b17:	83 c0 01             	add    $0x1,%eax
   16b1a:	89 c2                	mov    %eax,%edx
   16b1c:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b1f:	89 94 85 60 ff ff ff 	mov    %edx,-0xa0(%ebp,%eax,4)
		// can't go over one page in size
		if( (argbytes + strlengths[argc]) > SZ_PAGE ) {
   16b26:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b29:	8b 94 85 60 ff ff ff 	mov    -0xa0(%ebp,%eax,4),%edx
   16b30:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   16b33:	01 d0                	add    %edx,%eax
   16b35:	3d 00 10 00 00       	cmp    $0x1000,%eax
   16b3a:	7f 28                	jg     16b64 <stack_setup+0xdc>
			// oops - ignore this and any others
			break;
		}
		argbytes += strlengths[argc];
   16b3c:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b3f:	8b 84 85 60 ff ff ff 	mov    -0xa0(%ebp,%eax,4),%eax
   16b46:	01 45 d4             	add    %eax,-0x2c(%ebp)
		++argc;
   16b49:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
	while( kv_args[argc] != NULL ) {
   16b4d:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16b50:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   16b57:	8b 45 cc             	mov    -0x34(%ebp),%eax
   16b5a:	01 d0                	add    %edx,%eax
   16b5c:	8b 00                	mov    (%eax),%eax
   16b5e:	85 c0                	test   %eax,%eax
   16b60:	75 8a                	jne    16aec <stack_setup+0x64>
   16b62:	eb 01                	jmp    16b65 <stack_setup+0xdd>
			break;
   16b64:	90                   	nop
	}

	// Round up the byte count to the next multiple of four.
	argbytes = (argbytes + 3) & MOD4_MASK;
   16b65:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   16b68:	83 c0 03             	add    $0x3,%eax
   16b6b:	83 e0 fc             	and    $0xfffffffc,%eax
   16b6e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	** We don't know where the argument strings actually live; they
	** could be inside the stack of a process that called exec(), so
	** we can't run the risk of overwriting them. Copy them into our
	** own address space.
	*/
	char argstrings[ argbytes ];
   16b71:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
   16b74:	89 e0                	mov    %esp,%eax
   16b76:	89 c3                	mov    %eax,%ebx
   16b78:	8d 41 ff             	lea    -0x1(%ecx),%eax
   16b7b:	89 45 c8             	mov    %eax,-0x38(%ebp)
   16b7e:	89 ca                	mov    %ecx,%edx
   16b80:	b8 10 00 00 00       	mov    $0x10,%eax
   16b85:	83 e8 01             	sub    $0x1,%eax
   16b88:	01 d0                	add    %edx,%eax
   16b8a:	be 10 00 00 00       	mov    $0x10,%esi
   16b8f:	ba 00 00 00 00       	mov    $0x0,%edx
   16b94:	f7 f6                	div    %esi
   16b96:	6b c0 10             	imul   $0x10,%eax,%eax
   16b99:	29 c4                	sub    %eax,%esp
   16b9b:	89 e0                	mov    %esp,%eax
   16b9d:	83 c0 00             	add    $0x0,%eax
   16ba0:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	CLEAR( argstrings );
   16ba3:	89 ca                	mov    %ecx,%edx
   16ba5:	8b 45 c4             	mov    -0x3c(%ebp),%eax
   16ba8:	83 ec 08             	sub    $0x8,%esp
   16bab:	52                   	push   %edx
   16bac:	50                   	push   %eax
   16bad:	e8 ad b9 ff ff       	call   1255f <memclr>
   16bb2:	83 c4 10             	add    $0x10,%esp

	char *tmp = argstrings;
   16bb5:	8b 45 c4             	mov    -0x3c(%ebp),%eax
   16bb8:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for( int i = 0; i < argc; ++i ) {
   16bbb:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
   16bc2:	eb 3b                	jmp    16bff <stack_setup+0x177>
		// do the copy
		strcpy( tmp, kv_strs[i] );
   16bc4:	8b 45 e0             	mov    -0x20(%ebp),%eax
   16bc7:	8b 44 85 88          	mov    -0x78(%ebp,%eax,4),%eax
   16bcb:	83 ec 08             	sub    $0x8,%esp
   16bce:	50                   	push   %eax
   16bcf:	ff 75 dc             	pushl  -0x24(%ebp)
   16bd2:	e8 5e be ff ff       	call   12a35 <strcpy>
   16bd7:	83 c4 10             	add    $0x10,%esp
		// remember where this string begins in the buffer
		uv_offsets[i] = tmp - argstrings;
   16bda:	8b 45 dc             	mov    -0x24(%ebp),%eax
   16bdd:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   16be0:	29 d0                	sub    %edx,%eax
   16be2:	89 c2                	mov    %eax,%edx
   16be4:	8b 45 e0             	mov    -0x20(%ebp),%eax
   16be7:	89 94 85 38 ff ff ff 	mov    %edx,-0xc8(%ebp,%eax,4)
		// move to the next string position
		tmp += strlengths[i];
   16bee:	8b 45 e0             	mov    -0x20(%ebp),%eax
   16bf1:	8b 84 85 60 ff ff ff 	mov    -0xa0(%ebp,%eax,4),%eax
   16bf8:	01 45 dc             	add    %eax,-0x24(%ebp)
	for( int i = 0; i < argc; ++i ) {
   16bfb:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
   16bff:	8b 45 e0             	mov    -0x20(%ebp),%eax
   16c02:	3b 45 d8             	cmp    -0x28(%ebp),%eax
   16c05:	7c bd                	jl     16bc4 <stack_setup+0x13c>
	** frame is in the first page directory entry. Extract that from the
	** entry and convert it into a virtual address for the kernel to use.
	*/
	// pointer to the first byte after the user stack
	uint32_t *kvptr = (uint32_t *)
		(((uint32_t)(pcb->stack)) + N_USTKPAGES * SZ_PAGE);
   16c07:	8b 45 08             	mov    0x8(%ebp),%eax
   16c0a:	8b 40 04             	mov    0x4(%eax),%eax
   16c0d:	05 00 20 00 00       	add    $0x2000,%eax
	uint32_t *kvptr = (uint32_t *)
   16c12:	89 45 c0             	mov    %eax,-0x40(%ebp)

	// put the buffer longword into the stack
	*--kvptr = 0;
   16c15:	83 6d c0 04          	subl   $0x4,-0x40(%ebp)
   16c19:	8b 45 c0             	mov    -0x40(%ebp),%eax
   16c1c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	/*
	** Move these pointers to where the string area will begin. We
	** will then back up to the next lower multiple-of-four address.
	*/
	uint32_t kvstrptr = ((uint32_t) kvptr) - argbytes;
   16c22:	8b 55 c0             	mov    -0x40(%ebp),%edx
   16c25:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   16c28:	29 c2                	sub    %eax,%edx
   16c2a:	89 d0                	mov    %edx,%eax
   16c2c:	89 45 bc             	mov    %eax,-0x44(%ebp)
	kvstrptr &= MOD4_MASK;
   16c2f:	83 65 bc fc          	andl   $0xfffffffc,-0x44(%ebp)

	// Copy over the argv strings
	memmove( (void *) kvstrptr, (void *) argstrings, argbytes );
   16c33:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
   16c36:	8b 55 c4             	mov    -0x3c(%ebp),%edx
   16c39:	8b 45 bc             	mov    -0x44(%ebp),%eax
   16c3c:	83 ec 04             	sub    $0x4,%esp
   16c3f:	51                   	push   %ecx
   16c40:	52                   	push   %edx
   16c41:	50                   	push   %eax
   16c42:	e8 66 b9 ff ff       	call   125ad <memmove>
   16c47:	83 c4 10             	add    $0x10,%esp
	** The space needed for argc, argv, and the argv array itself is
	** argc + 3 words (argc+1 for the argv entries, plus one word each
	** for argc and argv).  We back up that much from the string area.
	*/

	int nwords = argc + 3;
   16c4a:	8b 45 d8             	mov    -0x28(%ebp),%eax
   16c4d:	83 c0 03             	add    $0x3,%eax
   16c50:	89 45 b8             	mov    %eax,-0x48(%ebp)
	uint32_t *kvacptr = ((uint32_t *) kvstrptr) - nwords;
   16c53:	8b 45 b8             	mov    -0x48(%ebp),%eax
   16c56:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   16c5d:	8b 45 bc             	mov    -0x44(%ebp),%eax
   16c60:	29 d0                	sub    %edx,%eax
   16c62:	89 45 b4             	mov    %eax,-0x4c(%ebp)

	// back these up to multiple-of-16 addresses for stack alignment
	kvacptr = (uint32_t *) ( ((uint32_t)kvacptr) & MOD16_MASK );
   16c65:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16c68:	83 e0 f0             	and    $0xfffffff0,%eax
   16c6b:	89 45 b4             	mov    %eax,-0x4c(%ebp)

	// copy in 'argc'
	*kvacptr = argc;
   16c6e:	8b 55 d8             	mov    -0x28(%ebp),%edx
   16c71:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16c74:	89 10                	mov    %edx,(%eax)
	cio_printf( "setup: argc '%d' @ %08x,", argc, (uint32_t) kvacptr );
#endif

	// 'argv' immediately follows 'argc', and 'argv[0]' immediately
	// follows 'argv'
	uint32_t *kvavptr = kvacptr + 2;
   16c76:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16c79:	83 c0 08             	add    $0x8,%eax
   16c7c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	*(kvavptr-1) = (uint32_t) kvavptr;
   16c7f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16c82:	8d 50 fc             	lea    -0x4(%eax),%edx
   16c85:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16c88:	89 02                	mov    %eax,(%edx)
	cio_printf( " argv '%08x' @ %08x,", (uint32_t) kvavptr,
			(uint32_t) (kvavptr - 1) );
#endif

	// now, the argv entries themselves
	for( int i = 0; i < argc; ++i ) {
   16c8a:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
   16c91:	eb 20                	jmp    16cb3 <stack_setup+0x22b>
		*kvavptr++ = (uint32_t) (kvstrptr + uv_offsets[i]);
   16c93:	8b 45 d0             	mov    -0x30(%ebp),%eax
   16c96:	8b 84 85 38 ff ff ff 	mov    -0xc8(%ebp,%eax,4),%eax
   16c9d:	89 c1                	mov    %eax,%ecx
   16c9f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16ca2:	8d 50 04             	lea    0x4(%eax),%edx
   16ca5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
   16ca8:	8b 55 bc             	mov    -0x44(%ebp),%edx
   16cab:	01 ca                	add    %ecx,%edx
   16cad:	89 10                	mov    %edx,(%eax)
	for( int i = 0; i < argc; ++i ) {
   16caf:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
   16cb3:	8b 45 d0             	mov    -0x30(%ebp),%eax
   16cb6:	3b 45 d8             	cmp    -0x28(%ebp),%eax
   16cb9:	7c d8                	jl     16c93 <stack_setup+0x20b>
		(uint32_t) (kvavptr-1) );
#endif
	}

	// and the trailing NULL
	*kvavptr = NULL;
   16cbb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   16cbe:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#if TRACING_STACK
	cio_printf( " NULL @ %08x,", (uint32_t) kvavptr );
#endif

	// push the fake return address right above 'argc' on the stack
	*--kvacptr = (uint32_t) fake_exit;
   16cc4:	83 6d b4 04          	subl   $0x4,-0x4c(%ebp)
   16cc8:	ba f9 6d 01 00       	mov    $0x16df9,%edx
   16ccd:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16cd0:	89 10                	mov    %edx,(%eax)
	** the interrupt "returns" to the entry point of the process.
	*/

	// Locate the context save area on the stack by backup up one
	// "context" from where the argc value is saved
	context_t *kvctx = ((context_t *) kvacptr) - 1;
   16cd2:	8b 45 b4             	mov    -0x4c(%ebp),%eax
   16cd5:	83 e8 48             	sub    $0x48,%eax
   16cd8:	89 45 b0             	mov    %eax,-0x50(%ebp)
	** as the 'popa' that restores the general registers doesn't
	** actually restore ESP from the context area - it leaves it
	** where it winds up.
	*/

	kvctx->eflags = DEFAULT_EFLAGS;    // IF enabled, IOPL 0
   16cdb:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16cde:	c7 40 44 02 02 00 00 	movl   $0x202,0x44(%eax)
	kvctx->eip = entry;                // initial EIP
   16ce5:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16ce8:	8b 55 0c             	mov    0xc(%ebp),%edx
   16ceb:	89 50 3c             	mov    %edx,0x3c(%eax)
	kvctx->cs = GDT_CODE;              // segment registers
   16cee:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16cf1:	c7 40 40 10 00 00 00 	movl   $0x10,0x40(%eax)
	kvctx->ss = GDT_STACK;
   16cf8:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16cfb:	c7 00 20 00 00 00    	movl   $0x20,(%eax)
	kvctx->ds = kvctx->es = kvctx->fs = kvctx->gs = GDT_DATA;
   16d01:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d04:	c7 40 04 18 00 00 00 	movl   $0x18,0x4(%eax)
   16d0b:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d0e:	8b 50 04             	mov    0x4(%eax),%edx
   16d11:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d14:	89 50 08             	mov    %edx,0x8(%eax)
   16d17:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d1a:	8b 50 08             	mov    0x8(%eax),%edx
   16d1d:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d20:	89 50 0c             	mov    %edx,0xc(%eax)
   16d23:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d26:	8b 50 0c             	mov    0xc(%eax),%edx
   16d29:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d2c:	89 50 10             	mov    %edx,0x10(%eax)
	/*
	** Return the new context pointer to the caller as a user
	** space virtual address.
	*/
	
	return kvctx;
   16d2f:	8b 45 b0             	mov    -0x50(%ebp),%eax
   16d32:	89 dc                	mov    %ebx,%esp
}
   16d34:	8d 65 f4             	lea    -0xc(%ebp),%esp
   16d37:	5b                   	pop    %ebx
   16d38:	5e                   	pop    %esi
   16d39:	5f                   	pop    %edi
   16d3a:	5d                   	pop    %ebp
   16d3b:	c3                   	ret    

00016d3c <user_init>:
/**
** Name:	user_init
**
** Initializes the user support module.
*/
void user_init( void ) {
   16d3c:	55                   	push   %ebp
   16d3d:	89 e5                	mov    %esp,%ebp
   16d3f:	83 ec 08             	sub    $0x8,%esp

#if TRACING_INIT
	cio_puts( " User" );
   16d42:	83 ec 0c             	sub    $0xc,%esp
   16d45:	68 20 b9 01 00       	push   $0x1b920
   16d4a:	e8 5e a1 ff ff       	call   10ead <cio_puts>
   16d4f:	83 c4 10             	add    $0x10,%esp
#endif 

	// really not much to do here any more....
}
   16d52:	90                   	nop
   16d53:	c9                   	leave  
   16d54:	c3                   	ret    

00016d55 <user_cleanup>:
** "Unloads" a user program. Deallocates all memory frames and
** cleans up the VM structures.
**
** @param pcb   The PCB of the program to be unloaded
*/
void user_cleanup( pcb_t *pcb ) {
   16d55:	55                   	push   %ebp
   16d56:	89 e5                	mov    %esp,%ebp
   16d58:	83 ec 08             	sub    $0x8,%esp

#if TRACING_USER
	cio_printf( "Uclean: %08x\n", (uint32_t) pcb );
#endif
	
	if( pcb == NULL ) {
   16d5b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   16d5f:	74 1b                	je     16d7c <user_cleanup+0x27>
		// should this be an error?
		return;
	}

	// free the stack pages
	pcb_stack_free( pcb->stack, pcb->stkpgs );
   16d61:	8b 45 08             	mov    0x8(%ebp),%eax
   16d64:	8b 50 28             	mov    0x28(%eax),%edx
   16d67:	8b 45 08             	mov    0x8(%ebp),%eax
   16d6a:	8b 40 04             	mov    0x4(%eax),%eax
   16d6d:	83 ec 08             	sub    $0x8,%esp
   16d70:	52                   	push   %edx
   16d71:	50                   	push   %eax
   16d72:	e8 0e cc ff ff       	call   13985 <pcb_stack_free>
   16d77:	83 c4 10             	add    $0x10,%esp
   16d7a:	eb 01                	jmp    16d7d <user_cleanup+0x28>
		return;
   16d7c:	90                   	nop
}
   16d7d:	c9                   	leave  
   16d7e:	c3                   	ret    

00016d7f <detect_intel_8255x>:
#include "drivers/intel_8255x.h"

int detect_intel_8255x() { return 0; }
   16d7f:	55                   	push   %ebp
   16d80:	89 e5                	mov    %esp,%ebp
   16d82:	b8 00 00 00 00       	mov    $0x0,%eax
   16d87:	5d                   	pop    %ebp
   16d88:	c3                   	ret    

00016d89 <exit>:

/*
** "real" system calls
*/

SYSCALL(exit)
   16d89:	b8 00 00 00 00       	mov    $0x0,%eax
   16d8e:	cd 80                	int    $0x80
   16d90:	c3                   	ret    

00016d91 <waitpid>:
SYSCALL(waitpid)
   16d91:	b8 01 00 00 00       	mov    $0x1,%eax
   16d96:	cd 80                	int    $0x80
   16d98:	c3                   	ret    

00016d99 <fork>:
SYSCALL(fork)
   16d99:	b8 02 00 00 00       	mov    $0x2,%eax
   16d9e:	cd 80                	int    $0x80
   16da0:	c3                   	ret    

00016da1 <exec>:
SYSCALL(exec)
   16da1:	b8 03 00 00 00       	mov    $0x3,%eax
   16da6:	cd 80                	int    $0x80
   16da8:	c3                   	ret    

00016da9 <read>:
SYSCALL(read)
   16da9:	b8 04 00 00 00       	mov    $0x4,%eax
   16dae:	cd 80                	int    $0x80
   16db0:	c3                   	ret    

00016db1 <write>:
SYSCALL(write)
   16db1:	b8 05 00 00 00       	mov    $0x5,%eax
   16db6:	cd 80                	int    $0x80
   16db8:	c3                   	ret    

00016db9 <getpid>:
SYSCALL(getpid)
   16db9:	b8 06 00 00 00       	mov    $0x6,%eax
   16dbe:	cd 80                	int    $0x80
   16dc0:	c3                   	ret    

00016dc1 <getppid>:
SYSCALL(getppid)
   16dc1:	b8 07 00 00 00       	mov    $0x7,%eax
   16dc6:	cd 80                	int    $0x80
   16dc8:	c3                   	ret    

00016dc9 <gettime>:
SYSCALL(gettime)
   16dc9:	b8 08 00 00 00       	mov    $0x8,%eax
   16dce:	cd 80                	int    $0x80
   16dd0:	c3                   	ret    

00016dd1 <getprio>:
SYSCALL(getprio)
   16dd1:	b8 09 00 00 00       	mov    $0x9,%eax
   16dd6:	cd 80                	int    $0x80
   16dd8:	c3                   	ret    

00016dd9 <setprio>:
SYSCALL(setprio)
   16dd9:	b8 0a 00 00 00       	mov    $0xa,%eax
   16dde:	cd 80                	int    $0x80
   16de0:	c3                   	ret    

00016de1 <kill>:
SYSCALL(kill)
   16de1:	b8 0b 00 00 00       	mov    $0xb,%eax
   16de6:	cd 80                	int    $0x80
   16de8:	c3                   	ret    

00016de9 <sleep>:
SYSCALL(sleep)
   16de9:	b8 0c 00 00 00       	mov    $0xc,%eax
   16dee:	cd 80                	int    $0x80
   16df0:	c3                   	ret    

00016df1 <bogus>:

/*
** This is a bogus system call; it's here so that we can test
** our handling of out-of-range syscall codes in the syscall ISR.
*/
SYSCALL(bogus)
   16df1:	b8 ad 0b 00 00       	mov    $0xbad,%eax
   16df6:	cd 80                	int    $0x80
   16df8:	c3                   	ret    

00016df9 <fake_exit>:
*/

	.globl	fake_exit
fake_exit:
	// alternate: could push a "fake exit" status
	pushl	%eax	// termination status returned by main()
   16df9:	50                   	push   %eax
	call	exit	// terminate this process
   16dfa:	e8 8a ff ff ff       	call   16d89 <exit>

00016dff <idle>:
** when there is no other process to dispatch.
**
** Invoked as:	idle
*/

USERMAIN( idle ) {
   16dff:	55                   	push   %ebp
   16e00:	89 e5                	mov    %esp,%ebp
   16e02:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char ch = '.';
#endif

	// ignore the command-line arguments
	(void) argc;
	char *name = argv[0] ? argv[0] : "nobody";
   16e08:	8b 45 0c             	mov    0xc(%ebp),%eax
   16e0b:	8b 00                	mov    (%eax),%eax
   16e0d:	85 c0                	test   %eax,%eax
   16e0f:	74 07                	je     16e18 <idle+0x19>
   16e11:	8b 45 0c             	mov    0xc(%ebp),%eax
   16e14:	8b 00                	mov    (%eax),%eax
   16e16:	eb 05                	jmp    16e1d <idle+0x1e>
   16e18:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   16e1d:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// get some current information
	uint_t pid = getpid();
   16e20:	e8 94 ff ff ff       	call   16db9 <getpid>
   16e25:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32_t now = gettime();
   16e28:	e8 9c ff ff ff       	call   16dc9 <gettime>
   16e2d:	89 45 e8             	mov    %eax,-0x18(%ebp)
	enum priority_e prio = getprio();
   16e30:	e8 9c ff ff ff       	call   16dd1 <getprio>
   16e35:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	char buf[128];
	usprint( buf, "%s [%d], started @ %u\n", name, pid, prio, now );
   16e38:	83 ec 08             	sub    $0x8,%esp
   16e3b:	ff 75 e8             	pushl  -0x18(%ebp)
   16e3e:	ff 75 e4             	pushl  -0x1c(%ebp)
   16e41:	ff 75 ec             	pushl  -0x14(%ebp)
   16e44:	ff 75 f0             	pushl  -0x10(%ebp)
   16e47:	68 2f b9 01 00       	push   $0x1b92f
   16e4c:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
   16e52:	50                   	push   %eax
   16e53:	e8 db 2c 00 00       	call   19b33 <usprint>
   16e58:	83 c4 20             	add    $0x20,%esp
	cwrites( buf );
   16e5b:	83 ec 0c             	sub    $0xc,%esp
   16e5e:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
   16e64:	50                   	push   %eax
   16e65:	e8 b6 33 00 00       	call   1a220 <cwrites>
   16e6a:	83 c4 10             	add    $0x10,%esp

	// idle() should never block - it must always be available
	// for dispatching when we need to pick a new current process

	for(;;) {
		DELAY(LONG);
   16e6d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   16e74:	eb 04                	jmp    16e7a <idle+0x7b>
   16e76:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   16e7a:	81 7d f4 ff e0 f5 05 	cmpl   $0x5f5e0ff,-0xc(%ebp)
   16e81:	7e f3                	jle    16e76 <idle+0x77>
   16e83:	eb e8                	jmp    16e6d <idle+0x6e>

00016e85 <usage>:
};

/*
** usage function
*/
static void usage( void ) {
   16e85:	55                   	push   %ebp
   16e86:	89 e5                	mov    %esp,%ebp
   16e88:	83 ec 18             	sub    $0x18,%esp
	swrites( "\nTests - run with '@x', where 'x' is one or more of:\n " );
   16e8b:	83 ec 0c             	sub    $0xc,%esp
   16e8e:	68 14 ba 01 00       	push   $0x1ba14
   16e93:	e8 ee 33 00 00       	call   1a286 <swrites>
   16e98:	83 c4 10             	add    $0x10,%esp
	proc_t *p = sh_spawn_table;
   16e9b:	c7 45 f4 20 c1 01 00 	movl   $0x1c120,-0xc(%ebp)
	while( p->entry != TBLEND ) {
   16ea2:	eb 23                	jmp    16ec7 <usage+0x42>
		swritech( ' ' );
   16ea4:	83 ec 0c             	sub    $0xc,%esp
   16ea7:	6a 20                	push   $0x20
   16ea9:	e8 b7 33 00 00       	call   1a265 <swritech>
   16eae:	83 c4 10             	add    $0x10,%esp
		swritech( p->select[0] );
   16eb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16eb4:	0f b6 40 09          	movzbl 0x9(%eax),%eax
   16eb8:	0f be c0             	movsbl %al,%eax
   16ebb:	83 ec 0c             	sub    $0xc,%esp
   16ebe:	50                   	push   %eax
   16ebf:	e8 a1 33 00 00       	call   1a265 <swritech>
   16ec4:	83 c4 10             	add    $0x10,%esp
	while( p->entry != TBLEND ) {
   16ec7:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16eca:	8b 00                	mov    (%eax),%eax
   16ecc:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   16ed1:	75 d1                	jne    16ea4 <usage+0x1f>
	}
	swrites( "\nOther commands: @* (all), @h (help), @x (exit)\n" );
   16ed3:	83 ec 0c             	sub    $0xc,%esp
   16ed6:	68 4c ba 01 00       	push   $0x1ba4c
   16edb:	e8 a6 33 00 00       	call   1a286 <swrites>
   16ee0:	83 c4 10             	add    $0x10,%esp
}
   16ee3:	90                   	nop
   16ee4:	c9                   	leave  
   16ee5:	c3                   	ret    

00016ee6 <run>:

/*
** run a program from the program table, or a builtin command
*/
static int run( char which ) {
   16ee6:	55                   	push   %ebp
   16ee7:	89 e5                	mov    %esp,%ebp
   16ee9:	53                   	push   %ebx
   16eea:	81 ec a4 00 00 00    	sub    $0xa4,%esp
   16ef0:	8b 45 08             	mov    0x8(%ebp),%eax
   16ef3:	88 85 64 ff ff ff    	mov    %al,-0x9c(%ebp)
	char buf[128];
	register proc_t *p;

	if( which == 'h' ) {
   16ef9:	80 bd 64 ff ff ff 68 	cmpb   $0x68,-0x9c(%ebp)
   16f00:	75 0a                	jne    16f0c <run+0x26>

		// builtin "help" command
		usage();
   16f02:	e8 7e ff ff ff       	call   16e85 <usage>
   16f07:	e9 e0 00 00 00       	jmp    16fec <run+0x106>

	} else if( which == 'x' ) {
   16f0c:	80 bd 64 ff ff ff 78 	cmpb   $0x78,-0x9c(%ebp)
   16f13:	75 0c                	jne    16f21 <run+0x3b>

		// builtin "exit" command
		time_to_stop = true;
   16f15:	c6 05 b4 e1 01 00 01 	movb   $0x1,0x1e1b4
   16f1c:	e9 cb 00 00 00       	jmp    16fec <run+0x106>

	} else if( which == '*' ) {
   16f21:	80 bd 64 ff ff ff 2a 	cmpb   $0x2a,-0x9c(%ebp)
   16f28:	75 40                	jne    16f6a <run+0x84>

		// torture test! run everything!
		for( p = sh_spawn_table; p->entry != TBLEND; ++p ) {
   16f2a:	bb 20 c1 01 00       	mov    $0x1c120,%ebx
   16f2f:	eb 2b                	jmp    16f5c <run+0x76>
			int status = spawn( p->entry, p->args );
   16f31:	8d 53 0c             	lea    0xc(%ebx),%edx
   16f34:	8b 03                	mov    (%ebx),%eax
   16f36:	83 ec 08             	sub    $0x8,%esp
   16f39:	52                   	push   %edx
   16f3a:	50                   	push   %eax
   16f3b:	e8 4a 32 00 00       	call   1a18a <spawn>
   16f40:	83 c4 10             	add    $0x10,%esp
   16f43:	89 45 f0             	mov    %eax,-0x10(%ebp)
			if( status > 0 ) {
   16f46:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   16f4a:	7e 0d                	jle    16f59 <run+0x73>
				++children;
   16f4c:	a1 b8 e1 01 00       	mov    0x1e1b8,%eax
   16f51:	83 c0 01             	add    $0x1,%eax
   16f54:	a3 b8 e1 01 00       	mov    %eax,0x1e1b8
		for( p = sh_spawn_table; p->entry != TBLEND; ++p ) {
   16f59:	83 c3 34             	add    $0x34,%ebx
   16f5c:	8b 03                	mov    (%ebx),%eax
   16f5e:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   16f63:	75 cc                	jne    16f31 <run+0x4b>
   16f65:	e9 82 00 00 00       	jmp    16fec <run+0x106>
		}

	} else {

		// must be a single test; find and run it
		for( p = sh_spawn_table; p->entry != TBLEND; ++p ) {
   16f6a:	bb 20 c1 01 00       	mov    $0x1c120,%ebx
   16f6f:	eb 3c                	jmp    16fad <run+0xc7>
			if( p->select[0] == which ) {
   16f71:	0f b6 43 09          	movzbl 0x9(%ebx),%eax
   16f75:	38 85 64 ff ff ff    	cmp    %al,-0x9c(%ebp)
   16f7b:	75 2d                	jne    16faa <run+0xc4>
				// found it!
				int status = spawn( p->entry, p->args );
   16f7d:	8d 53 0c             	lea    0xc(%ebx),%edx
   16f80:	8b 03                	mov    (%ebx),%eax
   16f82:	83 ec 08             	sub    $0x8,%esp
   16f85:	52                   	push   %edx
   16f86:	50                   	push   %eax
   16f87:	e8 fe 31 00 00       	call   1a18a <spawn>
   16f8c:	83 c4 10             	add    $0x10,%esp
   16f8f:	89 45 f4             	mov    %eax,-0xc(%ebp)
				if( status > 0 ) {
   16f92:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   16f96:	7e 0d                	jle    16fa5 <run+0xbf>
					++children;
   16f98:	a1 b8 e1 01 00       	mov    0x1e1b8,%eax
   16f9d:	83 c0 01             	add    $0x1,%eax
   16fa0:	a3 b8 e1 01 00       	mov    %eax,0x1e1b8
				}
				return status;
   16fa5:	8b 45 f4             	mov    -0xc(%ebp),%eax
   16fa8:	eb 47                	jmp    16ff1 <run+0x10b>
		for( p = sh_spawn_table; p->entry != TBLEND; ++p ) {
   16faa:	83 c3 34             	add    $0x34,%ebx
   16fad:	8b 03                	mov    (%ebx),%eax
   16faf:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   16fb4:	75 bb                	jne    16f71 <run+0x8b>
			}
		}

		// uh-oh, made it through the table without finding the program
		usprint( buf, "shell: unknown cmd '%c'\n", which );
   16fb6:	0f be 85 64 ff ff ff 	movsbl -0x9c(%ebp),%eax
   16fbd:	83 ec 04             	sub    $0x4,%esp
   16fc0:	50                   	push   %eax
   16fc1:	68 7d ba 01 00       	push   $0x1ba7d
   16fc6:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
   16fcc:	50                   	push   %eax
   16fcd:	e8 61 2b 00 00       	call   19b33 <usprint>
   16fd2:	83 c4 10             	add    $0x10,%esp
		swrites( buf );
   16fd5:	83 ec 0c             	sub    $0xc,%esp
   16fd8:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
   16fde:	50                   	push   %eax
   16fdf:	e8 a2 32 00 00       	call   1a286 <swrites>
   16fe4:	83 c4 10             	add    $0x10,%esp
		usage();
   16fe7:	e8 99 fe ff ff       	call   16e85 <usage>
	}

	return 0;
   16fec:	b8 00 00 00 00       	mov    $0x0,%eax
}
   16ff1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
   16ff4:	c9                   	leave  
   16ff5:	c3                   	ret    

00016ff6 <edit>:
** edit - perform any command-line editing we need to do
**
** @param line   Input line buffer
** @param n      Number of valid bytes in the buffer
*/
static int edit( char line[], int n ) {
   16ff6:	55                   	push   %ebp
   16ff7:	89 e5                	mov    %esp,%ebp
   16ff9:	83 ec 10             	sub    $0x10,%esp
	char *ptr = line + n - 1;	// last char in buffer
   16ffc:	8b 45 0c             	mov    0xc(%ebp),%eax
   16fff:	8d 50 ff             	lea    -0x1(%eax),%edx
   17002:	8b 45 08             	mov    0x8(%ebp),%eax
   17005:	01 d0                	add    %edx,%eax
   17007:	89 45 fc             	mov    %eax,-0x4(%ebp)

	// strip the EOLN sequence
	while( n > 0 ) {
   1700a:	eb 18                	jmp    17024 <edit+0x2e>
		if( *ptr == '\n' || *ptr == '\r' ) {
   1700c:	8b 45 fc             	mov    -0x4(%ebp),%eax
   1700f:	0f b6 00             	movzbl (%eax),%eax
   17012:	3c 0a                	cmp    $0xa,%al
   17014:	74 0a                	je     17020 <edit+0x2a>
   17016:	8b 45 fc             	mov    -0x4(%ebp),%eax
   17019:	0f b6 00             	movzbl (%eax),%eax
   1701c:	3c 0d                	cmp    $0xd,%al
   1701e:	75 0a                	jne    1702a <edit+0x34>
			--n;
   17020:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
	while( n > 0 ) {
   17024:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   17028:	7f e2                	jg     1700c <edit+0x16>
			break;
		}
	}

	// add a trailing NUL byte
	if( n > 0 ) {
   1702a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   1702e:	7e 0b                	jle    1703b <edit+0x45>
		line[n] = '\0';
   17030:	8b 55 0c             	mov    0xc(%ebp),%edx
   17033:	8b 45 08             	mov    0x8(%ebp),%eax
   17036:	01 d0                	add    %edx,%eax
   17038:	c6 00 00             	movb   $0x0,(%eax)
	}

	return n;
   1703b:	8b 45 0c             	mov    0xc(%ebp),%eax
}
   1703e:	c9                   	leave  
   1703f:	c3                   	ret    

00017040 <shell>:
** shell - extremely simple shell for spawning test programs
**
** Scheduled by _kshell() when the character 'u' is typed on
** the console keyboard.
*/
USERMAIN( shell ) {
   17040:	55                   	push   %ebp
   17041:	89 e5                	mov    %esp,%ebp
   17043:	81 ec 28 01 00 00    	sub    $0x128,%esp
	char line[128];

	// keep the compiler happy
	(void) argc;
	char *name = argv[0] ? argv[0] : "nobody";
   17049:	8b 45 0c             	mov    0xc(%ebp),%eax
   1704c:	8b 00                	mov    (%eax),%eax
   1704e:	85 c0                	test   %eax,%eax
   17050:	74 07                	je     17059 <shell+0x19>
   17052:	8b 45 0c             	mov    0xc(%ebp),%eax
   17055:	8b 00                	mov    (%eax),%eax
   17057:	eb 05                	jmp    1705e <shell+0x1e>
   17059:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   1705e:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// report that we're up and running
	usprint( line, "%s is ready\n", name );
   17061:	83 ec 04             	sub    $0x4,%esp
   17064:	ff 75 ec             	pushl  -0x14(%ebp)
   17067:	68 96 ba 01 00       	push   $0x1ba96
   1706c:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17072:	50                   	push   %eax
   17073:	e8 bb 2a 00 00       	call   19b33 <usprint>
   17078:	83 c4 10             	add    $0x10,%esp
	swrites( line );
   1707b:	83 ec 0c             	sub    $0xc,%esp
   1707e:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17084:	50                   	push   %eax
   17085:	e8 fc 31 00 00       	call   1a286 <swrites>
   1708a:	83 c4 10             	add    $0x10,%esp

	// print a summary of the commands we'll accept
	usage();
   1708d:	e8 f3 fd ff ff       	call   16e85 <usage>

	// loop forever
	while( !time_to_stop ) {
   17092:	e9 a7 01 00 00       	jmp    1723e <shell+0x1fe>
		char *ptr;

		// the shell reads one line from the keyboard, parses it,
		// and performs whatever command it requests.

		swrites( "\n> " );
   17097:	83 ec 0c             	sub    $0xc,%esp
   1709a:	68 a3 ba 01 00       	push   $0x1baa3
   1709f:	e8 e2 31 00 00       	call   1a286 <swrites>
   170a4:	83 c4 10             	add    $0x10,%esp
		int n = read( CHAN_SIO, line, sizeof(line) );
   170a7:	83 ec 04             	sub    $0x4,%esp
   170aa:	68 80 00 00 00       	push   $0x80
   170af:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   170b5:	50                   	push   %eax
   170b6:	6a 01                	push   $0x1
   170b8:	e8 ec fc ff ff       	call   16da9 <read>
   170bd:	83 c4 10             	add    $0x10,%esp
   170c0:	89 45 e8             	mov    %eax,-0x18(%ebp)
		
		// shortest valid command is "@?", so must have 3+ chars here
		if( n < 3 ) {
   170c3:	83 7d e8 02          	cmpl   $0x2,-0x18(%ebp)
   170c7:	7f 05                	jg     170ce <shell+0x8e>
			// ignore it
			continue;
   170c9:	e9 70 01 00 00       	jmp    1723e <shell+0x1fe>
		}

		// edit it as needed; new shortest command is 2+ chars
		if( (n=edit(line,n)) < 2 ) {
   170ce:	83 ec 08             	sub    $0x8,%esp
   170d1:	ff 75 e8             	pushl  -0x18(%ebp)
   170d4:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   170da:	50                   	push   %eax
   170db:	e8 16 ff ff ff       	call   16ff6 <edit>
   170e0:	83 c4 10             	add    $0x10,%esp
   170e3:	89 45 e8             	mov    %eax,-0x18(%ebp)
   170e6:	83 7d e8 01          	cmpl   $0x1,-0x18(%ebp)
   170ea:	7f 05                	jg     170f1 <shell+0xb1>
			continue;
   170ec:	e9 4d 01 00 00       	jmp    1723e <shell+0x1fe>
		}

		// find the '@'
		int i = 0;
   170f1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
		for( ptr = line; i < n; ++i, ++ptr ) {
   170f8:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   170fe:	89 45 f4             	mov    %eax,-0xc(%ebp)
   17101:	eb 12                	jmp    17115 <shell+0xd5>
			if( *ptr == '@' ) {
   17103:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17106:	0f b6 00             	movzbl (%eax),%eax
   17109:	3c 40                	cmp    $0x40,%al
   1710b:	74 12                	je     1711f <shell+0xdf>
		for( ptr = line; i < n; ++i, ++ptr ) {
   1710d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   17111:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   17115:	8b 45 f0             	mov    -0x10(%ebp),%eax
   17118:	3b 45 e8             	cmp    -0x18(%ebp),%eax
   1711b:	7c e6                	jl     17103 <shell+0xc3>
   1711d:	eb 01                	jmp    17120 <shell+0xe0>
				break;
   1711f:	90                   	nop
			}
		}

		// did we find an '@'?
		if( i < n ) {
   17120:	8b 45 f0             	mov    -0x10(%ebp),%eax
   17123:	3b 45 e8             	cmp    -0x18(%ebp),%eax
   17126:	0f 8d 12 01 00 00    	jge    1723e <shell+0x1fe>

			// yes; process any commands that follow it
			++ptr;
   1712c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

			for( ; *ptr != '\0'; ++ptr ) {
   17130:	eb 66                	jmp    17198 <shell+0x158>
				char buf[128];
				int pid = run( *ptr );
   17132:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17135:	0f b6 00             	movzbl (%eax),%eax
   17138:	0f be c0             	movsbl %al,%eax
   1713b:	83 ec 0c             	sub    $0xc,%esp
   1713e:	50                   	push   %eax
   1713f:	e8 a2 fd ff ff       	call   16ee6 <run>
   17144:	83 c4 10             	add    $0x10,%esp
   17147:	89 45 e4             	mov    %eax,-0x1c(%ebp)

				if( pid < 0 ) {
   1714a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   1714e:	79 39                	jns    17189 <shell+0x149>
					// spawn() failed
					usprint( buf, "+++ %s spawn %c failed, code %d\n",
							name, *ptr, pid );
   17150:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17153:	0f b6 00             	movzbl (%eax),%eax
					usprint( buf, "+++ %s spawn %c failed, code %d\n",
   17156:	0f be c0             	movsbl %al,%eax
   17159:	83 ec 0c             	sub    $0xc,%esp
   1715c:	ff 75 e4             	pushl  -0x1c(%ebp)
   1715f:	50                   	push   %eax
   17160:	ff 75 ec             	pushl  -0x14(%ebp)
   17163:	68 a8 ba 01 00       	push   $0x1baa8
   17168:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   1716e:	50                   	push   %eax
   1716f:	e8 bf 29 00 00       	call   19b33 <usprint>
   17174:	83 c4 20             	add    $0x20,%esp
					cwrites( buf );
   17177:	83 ec 0c             	sub    $0xc,%esp
   1717a:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   17180:	50                   	push   %eax
   17181:	e8 9a 30 00 00       	call   1a220 <cwrites>
   17186:	83 c4 10             	add    $0x10,%esp
				}

				// should we end it all?
				if( time_to_stop ) {
   17189:	0f b6 05 b4 e1 01 00 	movzbl 0x1e1b4,%eax
   17190:	84 c0                	test   %al,%al
   17192:	75 13                	jne    171a7 <shell+0x167>
			for( ; *ptr != '\0'; ++ptr ) {
   17194:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   17198:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1719b:	0f b6 00             	movzbl (%eax),%eax
   1719e:	84 c0                	test   %al,%al
   171a0:	75 90                	jne    17132 <shell+0xf2>
   171a2:	e9 8a 00 00 00       	jmp    17231 <shell+0x1f1>
					break;
   171a7:	90                   	nop
				}
			} // for

			// now, wait for all the spawned children
			while( children > 0 ) {
   171a8:	e9 84 00 00 00       	jmp    17231 <shell+0x1f1>
				// wait for the child
				int32_t status;
				char buf[128];
				int whom = waitpid( 0, &status );
   171ad:	83 ec 08             	sub    $0x8,%esp
   171b0:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   171b6:	50                   	push   %eax
   171b7:	6a 00                	push   $0x0
   171b9:	e8 d3 fb ff ff       	call   16d91 <waitpid>
   171be:	83 c4 10             	add    $0x10,%esp
   171c1:	89 45 e0             	mov    %eax,-0x20(%ebp)

				// figure out the result
				if( whom == E_NO_CHILDREN ) {
   171c4:	83 7d e0 fc          	cmpl   $0xfffffffc,-0x20(%ebp)
   171c8:	75 02                	jne    171cc <shell+0x18c>
   171ca:	eb 72                	jmp    1723e <shell+0x1fe>
					break;
				} else if( whom < 1 ) {
   171cc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   171d0:	7f 1c                	jg     171ee <shell+0x1ae>
					usprint( buf, "%s: waitpid() returned %d\n", name, whom );
   171d2:	ff 75 e0             	pushl  -0x20(%ebp)
   171d5:	ff 75 ec             	pushl  -0x14(%ebp)
   171d8:	68 c9 ba 01 00       	push   $0x1bac9
   171dd:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   171e3:	50                   	push   %eax
   171e4:	e8 4a 29 00 00       	call   19b33 <usprint>
   171e9:	83 c4 10             	add    $0x10,%esp
   171ec:	eb 31                	jmp    1721f <shell+0x1df>
				} else {
					--children;
   171ee:	a1 b8 e1 01 00       	mov    0x1e1b8,%eax
   171f3:	83 e8 01             	sub    $0x1,%eax
   171f6:	a3 b8 e1 01 00       	mov    %eax,0x1e1b8
					usprint( buf, "%s: PID %d exit status %d\n",
   171fb:	8b 85 5c ff ff ff    	mov    -0xa4(%ebp),%eax
   17201:	83 ec 0c             	sub    $0xc,%esp
   17204:	50                   	push   %eax
   17205:	ff 75 e0             	pushl  -0x20(%ebp)
   17208:	ff 75 ec             	pushl  -0x14(%ebp)
   1720b:	68 e4 ba 01 00       	push   $0x1bae4
   17210:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   17216:	50                   	push   %eax
   17217:	e8 17 29 00 00       	call   19b33 <usprint>
   1721c:	83 c4 20             	add    $0x20,%esp
							name, whom, status );
				}
				// report it
				swrites( buf );
   1721f:	83 ec 0c             	sub    $0xc,%esp
   17222:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
   17228:	50                   	push   %eax
   17229:	e8 58 30 00 00       	call   1a286 <swrites>
   1722e:	83 c4 10             	add    $0x10,%esp
			while( children > 0 ) {
   17231:	a1 b8 e1 01 00       	mov    0x1e1b8,%eax
   17236:	85 c0                	test   %eax,%eax
   17238:	0f 8f 6f ff ff ff    	jg     171ad <shell+0x16d>
	while( !time_to_stop ) {
   1723e:	0f b6 05 b4 e1 01 00 	movzbl 0x1e1b4,%eax
   17245:	84 c0                	test   %al,%al
   17247:	0f 84 4a fe ff ff    	je     17097 <shell+0x57>
			}
		}  // if i < n
	}  // while

	cwrites( "!!! shell exited loop???\n" );
   1724d:	83 ec 0c             	sub    $0xc,%esp
   17250:	68 ff ba 01 00       	push   $0x1baff
   17255:	e8 c6 2f 00 00       	call   1a220 <cwrites>
   1725a:	83 c4 10             	add    $0x10,%esp
	exit( 1 );
   1725d:	83 ec 0c             	sub    $0xc,%esp
   17260:	6a 01                	push   $0x1
   17262:	e8 22 fb ff ff       	call   16d89 <exit>
   17267:	83 c4 10             	add    $0x10,%esp

	// yeah, yeah....
	return( 0 );
   1726a:	b8 00 00 00 00       	mov    $0x0,%eax
}
   1726f:	c9                   	leave  
   17270:	c3                   	ret    

00017271 <process>:
**
** @param proc  pointer to the spawn table entry to be used
*/

static void process( proc_t *proc )
{
   17271:	55                   	push   %ebp
   17272:	89 e5                	mov    %esp,%ebp
   17274:	81 ec 98 00 00 00    	sub    $0x98,%esp
	char buf[128];

	// kick off the process
	int32_t p = fork();
   1727a:	e8 1a fb ff ff       	call   16d99 <fork>
   1727f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( p < 0 ) {
   17282:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   17286:	79 34                	jns    172bc <process+0x4b>

		// error!
		usprint( buf, "INIT: fork for #%d failed\n",
				(uint32_t) (proc->entry) );
   17288:	8b 45 08             	mov    0x8(%ebp),%eax
   1728b:	8b 00                	mov    (%eax),%eax
		usprint( buf, "INIT: fork for #%d failed\n",
   1728d:	83 ec 04             	sub    $0x4,%esp
   17290:	50                   	push   %eax
   17291:	68 26 bb 01 00       	push   $0x1bb26
   17296:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
   1729c:	50                   	push   %eax
   1729d:	e8 91 28 00 00       	call   19b33 <usprint>
   172a2:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   172a5:	83 ec 0c             	sub    $0xc,%esp
   172a8:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
   172ae:	50                   	push   %eax
   172af:	e8 6c 2f 00 00       	call   1a220 <cwrites>
   172b4:	83 c4 10             	add    $0x10,%esp
		swritech( ch );

		proc->pid = p;

	}
}
   172b7:	e9 84 00 00 00       	jmp    17340 <process+0xcf>
	} else if( p == 0 ) {
   172bc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   172c0:	75 5f                	jne    17321 <process+0xb0>
		(void) setprio( proc->e_prio );
   172c2:	8b 45 08             	mov    0x8(%ebp),%eax
   172c5:	0f b6 40 08          	movzbl 0x8(%eax),%eax
   172c9:	0f b6 c0             	movzbl %al,%eax
   172cc:	83 ec 0c             	sub    $0xc,%esp
   172cf:	50                   	push   %eax
   172d0:	e8 04 fb ff ff       	call   16dd9 <setprio>
   172d5:	83 c4 10             	add    $0x10,%esp
		exec( proc->entry, proc->args );
   172d8:	8b 45 08             	mov    0x8(%ebp),%eax
   172db:	8d 50 0c             	lea    0xc(%eax),%edx
   172de:	8b 45 08             	mov    0x8(%ebp),%eax
   172e1:	8b 00                	mov    (%eax),%eax
   172e3:	83 ec 08             	sub    $0x8,%esp
   172e6:	52                   	push   %edx
   172e7:	50                   	push   %eax
   172e8:	e8 b4 fa ff ff       	call   16da1 <exec>
   172ed:	83 c4 10             	add    $0x10,%esp
				(uint32_t) (proc->entry) );
   172f0:	8b 45 08             	mov    0x8(%ebp),%eax
   172f3:	8b 00                	mov    (%eax),%eax
		usprint( buf, "INIT: exec(0x%08x) failed\n",
   172f5:	83 ec 04             	sub    $0x4,%esp
   172f8:	50                   	push   %eax
   172f9:	68 41 bb 01 00       	push   $0x1bb41
   172fe:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
   17304:	50                   	push   %eax
   17305:	e8 29 28 00 00       	call   19b33 <usprint>
   1730a:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   1730d:	83 ec 0c             	sub    $0xc,%esp
   17310:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
   17316:	50                   	push   %eax
   17317:	e8 04 2f 00 00       	call   1a220 <cwrites>
   1731c:	83 c4 10             	add    $0x10,%esp
}
   1731f:	eb 1f                	jmp    17340 <process+0xcf>
		swritech( ch );
   17321:	0f b6 05 3c c6 01 00 	movzbl 0x1c63c,%eax
   17328:	0f be c0             	movsbl %al,%eax
   1732b:	83 ec 0c             	sub    $0xc,%esp
   1732e:	50                   	push   %eax
   1732f:	e8 31 2f 00 00       	call   1a265 <swritech>
   17334:	83 c4 10             	add    $0x10,%esp
		proc->pid = p;
   17337:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1733a:	8b 45 08             	mov    0x8(%ebp),%eax
   1733d:	89 50 04             	mov    %edx,0x4(%eax)
}
   17340:	90                   	nop
   17341:	c9                   	leave  
   17342:	c3                   	ret    

00017343 <init>:
/*
** The initial user process. Should be invoked with zero or one
** argument; if provided, the first argument should be the ASCII
** character 'init' will print to indicate the spawning of a process.
*/
USERMAIN( init ) {
   17343:	55                   	push   %ebp
   17344:	89 e5                	mov    %esp,%ebp
   17346:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   1734c:	8b 45 0c             	mov    0xc(%ebp),%eax
   1734f:	8b 00                	mov    (%eax),%eax
   17351:	85 c0                	test   %eax,%eax
   17353:	74 07                	je     1735c <init+0x19>
   17355:	8b 45 0c             	mov    0xc(%ebp),%eax
   17358:	8b 00                	mov    (%eax),%eax
   1735a:	eb 05                	jmp    17361 <init+0x1e>
   1735c:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   17361:	89 45 e8             	mov    %eax,-0x18(%ebp)
	char buf[128];

	// check to see if we got a non-standard "spawn" character
	if( argc > 1 ) {
   17364:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
   17368:	7e 2d                	jle    17397 <init+0x54>
		// maybe - check it to be sure it's printable
		uint_t i = argv[1][0];
   1736a:	8b 45 0c             	mov    0xc(%ebp),%eax
   1736d:	83 c0 04             	add    $0x4,%eax
   17370:	8b 00                	mov    (%eax),%eax
   17372:	0f b6 00             	movzbl (%eax),%eax
   17375:	0f be c0             	movsbl %al,%eax
   17378:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		if( i > ' ' && i < 0x7f ) {
   1737b:	83 7d e4 20          	cmpl   $0x20,-0x1c(%ebp)
   1737f:	76 16                	jbe    17397 <init+0x54>
   17381:	83 7d e4 7e          	cmpl   $0x7e,-0x1c(%ebp)
   17385:	77 10                	ja     17397 <init+0x54>
			ch = argv[1][0];
   17387:	8b 45 0c             	mov    0xc(%ebp),%eax
   1738a:	83 c0 04             	add    $0x4,%eax
   1738d:	8b 00                	mov    (%eax),%eax
   1738f:	0f b6 00             	movzbl (%eax),%eax
   17392:	a2 3c c6 01 00       	mov    %al,0x1c63c
		}
	}

	// test the sio
	write( CHAN_SIO, "$+$\n", 4 );
   17397:	83 ec 04             	sub    $0x4,%esp
   1739a:	6a 04                	push   $0x4
   1739c:	68 5c bb 01 00       	push   $0x1bb5c
   173a1:	6a 01                	push   $0x1
   173a3:	e8 09 fa ff ff       	call   16db1 <write>
   173a8:	83 c4 10             	add    $0x10,%esp
	DELAY(SHORT);
   173ab:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   173b2:	eb 04                	jmp    173b8 <init+0x75>
   173b4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   173b8:	81 7d f4 9f 25 26 00 	cmpl   $0x26259f,-0xc(%ebp)
   173bf:	7e f3                	jle    173b4 <init+0x71>

	usprint( buf, "%s: started\n", name );
   173c1:	83 ec 04             	sub    $0x4,%esp
   173c4:	ff 75 e8             	pushl  -0x18(%ebp)
   173c7:	68 61 bb 01 00       	push   $0x1bb61
   173cc:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   173d2:	50                   	push   %eax
   173d3:	e8 5b 27 00 00       	call   19b33 <usprint>
   173d8:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   173db:	83 ec 0c             	sub    $0xc,%esp
   173de:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   173e4:	50                   	push   %eax
   173e5:	e8 36 2e 00 00       	call   1a220 <cwrites>
   173ea:	83 c4 10             	add    $0x10,%esp

	// home up, clear on a TVI 925
	// swritech( '\x1a' );

	// wait a bit
	DELAY(SHORT);
   173ed:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   173f4:	eb 04                	jmp    173fa <init+0xb7>
   173f6:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   173fa:	81 7d f0 9f 25 26 00 	cmpl   $0x26259f,-0x10(%ebp)
   17401:	7e f3                	jle    173f6 <init+0xb3>

	// a bit of Dante to set the mood :-)
	swrites( "\n\nSpem relinquunt qui huc intrasti!\n\n\r" );
   17403:	83 ec 0c             	sub    $0xc,%esp
   17406:	68 70 bb 01 00       	push   $0x1bb70
   1740b:	e8 76 2e 00 00       	call   1a286 <swrites>
   17410:	83 c4 10             	add    $0x10,%esp

	/*
	** Start all the user processes
	*/

	usprint( buf, "%s: starting user processes\n", name );
   17413:	83 ec 04             	sub    $0x4,%esp
   17416:	ff 75 e8             	pushl  -0x18(%ebp)
   17419:	68 97 bb 01 00       	push   $0x1bb97
   1741e:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17424:	50                   	push   %eax
   17425:	e8 09 27 00 00       	call   19b33 <usprint>
   1742a:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   1742d:	83 ec 0c             	sub    $0xc,%esp
   17430:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17436:	50                   	push   %eax
   17437:	e8 e4 2d 00 00       	call   1a220 <cwrites>
   1743c:	83 c4 10             	add    $0x10,%esp

	proc_t *next;
	for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
   1743f:	c7 45 ec a0 c5 01 00 	movl   $0x1c5a0,-0x14(%ebp)
   17446:	eb 12                	jmp    1745a <init+0x117>
		process( next );
   17448:	83 ec 0c             	sub    $0xc,%esp
   1744b:	ff 75 ec             	pushl  -0x14(%ebp)
   1744e:	e8 1e fe ff ff       	call   17271 <process>
   17453:	83 c4 10             	add    $0x10,%esp
	for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
   17456:	83 45 ec 34          	addl   $0x34,-0x14(%ebp)
   1745a:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1745d:	8b 00                	mov    (%eax),%eax
   1745f:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   17464:	75 e2                	jne    17448 <init+0x105>
	}

	swrites( " !!!\r\n\n" );
   17466:	83 ec 0c             	sub    $0xc,%esp
   17469:	68 b4 bb 01 00       	push   $0x1bbb4
   1746e:	e8 13 2e 00 00       	call   1a286 <swrites>
   17473:	83 c4 10             	add    $0x10,%esp
	/*
	** At this point, we go into an infinite loop waiting
	** for our children (direct, or inherited) to exit.
	*/

	usprint( buf, "%s: transitioning to wait() mode\n", name );
   17476:	83 ec 04             	sub    $0x4,%esp
   17479:	ff 75 e8             	pushl  -0x18(%ebp)
   1747c:	68 bc bb 01 00       	push   $0x1bbbc
   17481:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17487:	50                   	push   %eax
   17488:	e8 a6 26 00 00       	call   19b33 <usprint>
   1748d:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   17490:	83 ec 0c             	sub    $0xc,%esp
   17493:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17499:	50                   	push   %eax
   1749a:	e8 81 2d 00 00       	call   1a220 <cwrites>
   1749f:	83 c4 10             	add    $0x10,%esp

	for(;;) {
		int32_t status;
		int whom = waitpid( 0, &status );
   174a2:	83 ec 08             	sub    $0x8,%esp
   174a5:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   174ab:	50                   	push   %eax
   174ac:	6a 00                	push   $0x0
   174ae:	e8 de f8 ff ff       	call   16d91 <waitpid>
   174b3:	83 c4 10             	add    $0x10,%esp
   174b6:	89 45 e0             	mov    %eax,-0x20(%ebp)

		// PIDs must be positive numbers!
		if( whom <= 0 ) {
   174b9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   174bd:	7f 2e                	jg     174ed <init+0x1aa>

			usprint( buf, "%s: waitpid() returned %d???\n", name, whom );
   174bf:	ff 75 e0             	pushl  -0x20(%ebp)
   174c2:	ff 75 e8             	pushl  -0x18(%ebp)
   174c5:	68 de bb 01 00       	push   $0x1bbde
   174ca:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   174d0:	50                   	push   %eax
   174d1:	e8 5d 26 00 00       	call   19b33 <usprint>
   174d6:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   174d9:	83 ec 0c             	sub    $0xc,%esp
   174dc:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   174e2:	50                   	push   %eax
   174e3:	e8 38 2d 00 00       	call   1a220 <cwrites>
   174e8:	83 c4 10             	add    $0x10,%esp
   174eb:	eb b5                	jmp    174a2 <init+0x15f>

		} else {

			// got one; report it
			usprint( buf, "%s: pid %d exit(%d)\n", name, whom, status );
   174ed:	8b 85 5c ff ff ff    	mov    -0xa4(%ebp),%eax
   174f3:	83 ec 0c             	sub    $0xc,%esp
   174f6:	50                   	push   %eax
   174f7:	ff 75 e0             	pushl  -0x20(%ebp)
   174fa:	ff 75 e8             	pushl  -0x18(%ebp)
   174fd:	68 fc bb 01 00       	push   $0x1bbfc
   17502:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   17508:	50                   	push   %eax
   17509:	e8 25 26 00 00       	call   19b33 <usprint>
   1750e:	83 c4 20             	add    $0x20,%esp
			cwrites( buf );
   17511:	83 ec 0c             	sub    $0xc,%esp
   17514:	8d 85 60 ff ff ff    	lea    -0xa0(%ebp),%eax
   1751a:	50                   	push   %eax
   1751b:	e8 00 2d 00 00       	call   1a220 <cwrites>
   17520:	83 c4 10             	add    $0x10,%esp

			// figure out if this is one of ours
			for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
   17523:	c7 45 ec a0 c5 01 00 	movl   $0x1c5a0,-0x14(%ebp)
   1752a:	eb 2b                	jmp    17557 <init+0x214>
				if( next->pid == whom ) {
   1752c:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1752f:	8b 50 04             	mov    0x4(%eax),%edx
   17532:	8b 45 e0             	mov    -0x20(%ebp),%eax
   17535:	39 c2                	cmp    %eax,%edx
   17537:	75 1a                	jne    17553 <init+0x210>
					// one of ours - reset the PID field
					// (in case the spawn attempt fails)
					next->pid = 0;
   17539:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1753c:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
					// and restart it
					process( next );
   17543:	83 ec 0c             	sub    $0xc,%esp
   17546:	ff 75 ec             	pushl  -0x14(%ebp)
   17549:	e8 23 fd ff ff       	call   17271 <process>
   1754e:	83 c4 10             	add    $0x10,%esp
					break;
   17551:	eb 10                	jmp    17563 <init+0x220>
			for( next = init_spawn_table; next->entry != TBLEND; ++next ) {
   17553:	83 45 ec 34          	addl   $0x34,-0x14(%ebp)
   17557:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1755a:	8b 00                	mov    (%eax),%eax
   1755c:	3d ed ad be de       	cmp    $0xdebeaded,%eax
   17561:	75 c9                	jne    1752c <init+0x1e9>
	for(;;) {
   17563:	e9 3a ff ff ff       	jmp    174a2 <init+0x15f>

00017568 <progABC>:
** Invoked as:  progABC  x  n
**	 where x is the ID character
**		   n is the iteration count
*/

USERMAIN( progABC ) {
   17568:	55                   	push   %ebp
   17569:	89 e5                	mov    %esp,%ebp
   1756b:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   17571:	8b 45 0c             	mov    0xc(%ebp),%eax
   17574:	8b 00                	mov    (%eax),%eax
   17576:	85 c0                	test   %eax,%eax
   17578:	74 07                	je     17581 <progABC+0x19>
   1757a:	8b 45 0c             	mov    0xc(%ebp),%eax
   1757d:	8b 00                	mov    (%eax),%eax
   1757f:	eb 05                	jmp    17586 <progABC+0x1e>
   17581:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   17586:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 30; // default iteration count
   17589:	c7 45 f4 1e 00 00 00 	movl   $0x1e,-0xc(%ebp)
	char ch = '1';	// default character to print
   17590:	c6 45 f3 31          	movb   $0x31,-0xd(%ebp)
	char buf[128];	// local char buffer

	// process the command-line arguments
	switch( argc ) {
   17594:	8b 45 08             	mov    0x8(%ebp),%eax
   17597:	83 f8 02             	cmp    $0x2,%eax
   1759a:	74 1e                	je     175ba <progABC+0x52>
   1759c:	83 f8 03             	cmp    $0x3,%eax
   1759f:	75 2c                	jne    175cd <progABC+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   175a1:	8b 45 0c             	mov    0xc(%ebp),%eax
   175a4:	83 c0 08             	add    $0x8,%eax
   175a7:	8b 00                	mov    (%eax),%eax
   175a9:	83 ec 08             	sub    $0x8,%esp
   175ac:	6a 0a                	push   $0xa
   175ae:	50                   	push   %eax
   175af:	e8 f4 27 00 00       	call   19da8 <ustr2int>
   175b4:	83 c4 10             	add    $0x10,%esp
   175b7:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   175ba:	8b 45 0c             	mov    0xc(%ebp),%eax
   175bd:	83 c0 04             	add    $0x4,%eax
   175c0:	8b 00                	mov    (%eax),%eax
   175c2:	0f b6 00             	movzbl (%eax),%eax
   175c5:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   175c8:	e9 a8 00 00 00       	jmp    17675 <progABC+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   175cd:	ff 75 08             	pushl  0x8(%ebp)
   175d0:	ff 75 e0             	pushl  -0x20(%ebp)
   175d3:	68 11 bc 01 00       	push   $0x1bc11
   175d8:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   175de:	50                   	push   %eax
   175df:	e8 4f 25 00 00       	call   19b33 <usprint>
   175e4:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   175e7:	83 ec 0c             	sub    $0xc,%esp
   175ea:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   175f0:	50                   	push   %eax
   175f1:	e8 2a 2c 00 00       	call   1a220 <cwrites>
   175f6:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   175f9:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   17600:	eb 5b                	jmp    1765d <progABC+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   17602:	8b 45 08             	mov    0x8(%ebp),%eax
   17605:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1760c:	8b 45 0c             	mov    0xc(%ebp),%eax
   1760f:	01 d0                	add    %edx,%eax
   17611:	8b 00                	mov    (%eax),%eax
   17613:	85 c0                	test   %eax,%eax
   17615:	74 13                	je     1762a <progABC+0xc2>
   17617:	8b 45 08             	mov    0x8(%ebp),%eax
   1761a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17621:	8b 45 0c             	mov    0xc(%ebp),%eax
   17624:	01 d0                	add    %edx,%eax
   17626:	8b 00                	mov    (%eax),%eax
   17628:	eb 05                	jmp    1762f <progABC+0xc7>
   1762a:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   1762f:	83 ec 04             	sub    $0x4,%esp
   17632:	50                   	push   %eax
   17633:	68 2c bc 01 00       	push   $0x1bc2c
   17638:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1763e:	50                   	push   %eax
   1763f:	e8 ef 24 00 00       	call   19b33 <usprint>
   17644:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17647:	83 ec 0c             	sub    $0xc,%esp
   1764a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17650:	50                   	push   %eax
   17651:	e8 ca 2b 00 00       	call   1a220 <cwrites>
   17656:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17659:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   1765d:	8b 45 ec             	mov    -0x14(%ebp),%eax
   17660:	3b 45 08             	cmp    0x8(%ebp),%eax
   17663:	7e 9d                	jle    17602 <progABC+0x9a>
			}
			cwrites( "\n" );
   17665:	83 ec 0c             	sub    $0xc,%esp
   17668:	68 30 bc 01 00       	push   $0x1bc30
   1766d:	e8 ae 2b 00 00       	call   1a220 <cwrites>
   17672:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int n = swritech( ch );
   17675:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17679:	83 ec 0c             	sub    $0xc,%esp
   1767c:	50                   	push   %eax
   1767d:	e8 e3 2b 00 00       	call   1a265 <swritech>
   17682:	83 c4 10             	add    $0x10,%esp
   17685:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if( n != 1 ) {
   17688:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   1768c:	74 2e                	je     176bc <progABC+0x154>
		usprint( buf, "== %c, write #1 returned %d\n", ch, n );
   1768e:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17692:	ff 75 dc             	pushl  -0x24(%ebp)
   17695:	50                   	push   %eax
   17696:	68 32 bc 01 00       	push   $0x1bc32
   1769b:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   176a1:	50                   	push   %eax
   176a2:	e8 8c 24 00 00       	call   19b33 <usprint>
   176a7:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   176aa:	83 ec 0c             	sub    $0xc,%esp
   176ad:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   176b3:	50                   	push   %eax
   176b4:	e8 67 2b 00 00       	call   1a220 <cwrites>
   176b9:	83 c4 10             	add    $0x10,%esp
	}

	// iterate and print the required number of other characters
	for( int i = 0; i < count; ++i ) {
   176bc:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   176c3:	eb 61                	jmp    17726 <progABC+0x1be>
		DELAY(STD);
   176c5:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   176cc:	eb 04                	jmp    176d2 <progABC+0x16a>
   176ce:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   176d2:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   176d9:	7e f3                	jle    176ce <progABC+0x166>
		n = swritech( ch );
   176db:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   176df:	83 ec 0c             	sub    $0xc,%esp
   176e2:	50                   	push   %eax
   176e3:	e8 7d 2b 00 00       	call   1a265 <swritech>
   176e8:	83 c4 10             	add    $0x10,%esp
   176eb:	89 45 dc             	mov    %eax,-0x24(%ebp)
		if( n != 1 ) {
   176ee:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   176f2:	74 2e                	je     17722 <progABC+0x1ba>
			usprint( buf, "== %c, write #2 returned %d\n", ch, n );
   176f4:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   176f8:	ff 75 dc             	pushl  -0x24(%ebp)
   176fb:	50                   	push   %eax
   176fc:	68 4f bc 01 00       	push   $0x1bc4f
   17701:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17707:	50                   	push   %eax
   17708:	e8 26 24 00 00       	call   19b33 <usprint>
   1770d:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17710:	83 ec 0c             	sub    $0xc,%esp
   17713:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17719:	50                   	push   %eax
   1771a:	e8 01 2b 00 00       	call   1a220 <cwrites>
   1771f:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   17722:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   17726:	8b 45 e8             	mov    -0x18(%ebp),%eax
   17729:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   1772c:	7c 97                	jl     176c5 <progABC+0x15d>
		}
	}

	// all done!
	exit( 0 );
   1772e:	83 ec 0c             	sub    $0xc,%esp
   17731:	6a 00                	push   $0x0
   17733:	e8 51 f6 ff ff       	call   16d89 <exit>
   17738:	83 c4 10             	add    $0x10,%esp

	// should never reach this code; if we do, something is
	// wrong with exit(), so we'll report it

	char msg[] = "*1*";
   1773b:	c7 85 58 ff ff ff 2a 	movl   $0x2a312a,-0xa8(%ebp)
   17742:	31 2a 00 
	msg[1] = ch;
   17745:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   17749:	88 85 59 ff ff ff    	mov    %al,-0xa7(%ebp)
	n = write( CHAN_SIO, msg, 3 );	  /* shouldn't happen! */
   1774f:	83 ec 04             	sub    $0x4,%esp
   17752:	6a 03                	push   $0x3
   17754:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   1775a:	50                   	push   %eax
   1775b:	6a 01                	push   $0x1
   1775d:	e8 4f f6 ff ff       	call   16db1 <write>
   17762:	83 c4 10             	add    $0x10,%esp
   17765:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if( n != 3 ) {
   17768:	83 7d dc 03          	cmpl   $0x3,-0x24(%ebp)
   1776c:	74 2e                	je     1779c <progABC+0x234>
		usprint( buf, "User %c, write #3 returned %d\n", ch, n );
   1776e:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17772:	ff 75 dc             	pushl  -0x24(%ebp)
   17775:	50                   	push   %eax
   17776:	68 6c bc 01 00       	push   $0x1bc6c
   1777b:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17781:	50                   	push   %eax
   17782:	e8 ac 23 00 00       	call   19b33 <usprint>
   17787:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   1778a:	83 ec 0c             	sub    $0xc,%esp
   1778d:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17793:	50                   	push   %eax
   17794:	e8 87 2a 00 00       	call   1a220 <cwrites>
   17799:	83 c4 10             	add    $0x10,%esp
	}

	// this should really get us out of here
	return( 42 );
   1779c:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   177a1:	c9                   	leave  
   177a2:	c3                   	ret    

000177a3 <progDE>:
** Invoked as:  progDE  x  n
**	 where x is the ID character
**		   n is the iteration count
*/

USERMAIN( progDE ) {
   177a3:	55                   	push   %ebp
   177a4:	89 e5                	mov    %esp,%ebp
   177a6:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   177ac:	8b 45 0c             	mov    0xc(%ebp),%eax
   177af:	8b 00                	mov    (%eax),%eax
   177b1:	85 c0                	test   %eax,%eax
   177b3:	74 07                	je     177bc <progDE+0x19>
   177b5:	8b 45 0c             	mov    0xc(%ebp),%eax
   177b8:	8b 00                	mov    (%eax),%eax
   177ba:	eb 05                	jmp    177c1 <progDE+0x1e>
   177bc:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   177c1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int n;
	int count = 30;	  // default iteration count
   177c4:	c7 45 f4 1e 00 00 00 	movl   $0x1e,-0xc(%ebp)
	char ch = '2';	  // default character to print
   177cb:	c6 45 f3 32          	movb   $0x32,-0xd(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   177cf:	8b 45 08             	mov    0x8(%ebp),%eax
   177d2:	83 f8 02             	cmp    $0x2,%eax
   177d5:	74 1e                	je     177f5 <progDE+0x52>
   177d7:	83 f8 03             	cmp    $0x3,%eax
   177da:	75 2c                	jne    17808 <progDE+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   177dc:	8b 45 0c             	mov    0xc(%ebp),%eax
   177df:	83 c0 08             	add    $0x8,%eax
   177e2:	8b 00                	mov    (%eax),%eax
   177e4:	83 ec 08             	sub    $0x8,%esp
   177e7:	6a 0a                	push   $0xa
   177e9:	50                   	push   %eax
   177ea:	e8 b9 25 00 00       	call   19da8 <ustr2int>
   177ef:	83 c4 10             	add    $0x10,%esp
   177f2:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   177f5:	8b 45 0c             	mov    0xc(%ebp),%eax
   177f8:	83 c0 04             	add    $0x4,%eax
   177fb:	8b 00                	mov    (%eax),%eax
   177fd:	0f b6 00             	movzbl (%eax),%eax
   17800:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   17803:	e9 a8 00 00 00       	jmp    178b0 <progDE+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   17808:	ff 75 08             	pushl  0x8(%ebp)
   1780b:	ff 75 e0             	pushl  -0x20(%ebp)
   1780e:	68 11 bc 01 00       	push   $0x1bc11
   17813:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17819:	50                   	push   %eax
   1781a:	e8 14 23 00 00       	call   19b33 <usprint>
   1781f:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17822:	83 ec 0c             	sub    $0xc,%esp
   17825:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1782b:	50                   	push   %eax
   1782c:	e8 ef 29 00 00       	call   1a220 <cwrites>
   17831:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17834:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   1783b:	eb 5b                	jmp    17898 <progDE+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   1783d:	8b 45 08             	mov    0x8(%ebp),%eax
   17840:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17847:	8b 45 0c             	mov    0xc(%ebp),%eax
   1784a:	01 d0                	add    %edx,%eax
   1784c:	8b 00                	mov    (%eax),%eax
   1784e:	85 c0                	test   %eax,%eax
   17850:	74 13                	je     17865 <progDE+0xc2>
   17852:	8b 45 08             	mov    0x8(%ebp),%eax
   17855:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1785c:	8b 45 0c             	mov    0xc(%ebp),%eax
   1785f:	01 d0                	add    %edx,%eax
   17861:	8b 00                	mov    (%eax),%eax
   17863:	eb 05                	jmp    1786a <progDE+0xc7>
   17865:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   1786a:	83 ec 04             	sub    $0x4,%esp
   1786d:	50                   	push   %eax
   1786e:	68 2c bc 01 00       	push   $0x1bc2c
   17873:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17879:	50                   	push   %eax
   1787a:	e8 b4 22 00 00       	call   19b33 <usprint>
   1787f:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17882:	83 ec 0c             	sub    $0xc,%esp
   17885:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   1788b:	50                   	push   %eax
   1788c:	e8 8f 29 00 00       	call   1a220 <cwrites>
   17891:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17894:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   17898:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1789b:	3b 45 08             	cmp    0x8(%ebp),%eax
   1789e:	7e 9d                	jle    1783d <progDE+0x9a>
			}
			cwrites( "\n" );
   178a0:	83 ec 0c             	sub    $0xc,%esp
   178a3:	68 30 bc 01 00       	push   $0x1bc30
   178a8:	e8 73 29 00 00       	call   1a220 <cwrites>
   178ad:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	n = swritech( ch );
   178b0:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   178b4:	83 ec 0c             	sub    $0xc,%esp
   178b7:	50                   	push   %eax
   178b8:	e8 a8 29 00 00       	call   1a265 <swritech>
   178bd:	83 c4 10             	add    $0x10,%esp
   178c0:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if( n != 1 ) {
   178c3:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   178c7:	74 2e                	je     178f7 <progDE+0x154>
		usprint( buf, "== %c, write #1 returned %d\n", ch, n );
   178c9:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   178cd:	ff 75 dc             	pushl  -0x24(%ebp)
   178d0:	50                   	push   %eax
   178d1:	68 32 bc 01 00       	push   $0x1bc32
   178d6:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   178dc:	50                   	push   %eax
   178dd:	e8 51 22 00 00       	call   19b33 <usprint>
   178e2:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   178e5:	83 ec 0c             	sub    $0xc,%esp
   178e8:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   178ee:	50                   	push   %eax
   178ef:	e8 2c 29 00 00       	call   1a220 <cwrites>
   178f4:	83 c4 10             	add    $0x10,%esp
	}

	// iterate and print the required number of other characters
	for( int i = 0; i < count; ++i ) {
   178f7:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   178fe:	eb 61                	jmp    17961 <progDE+0x1be>
		DELAY(STD);
   17900:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   17907:	eb 04                	jmp    1790d <progDE+0x16a>
   17909:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   1790d:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   17914:	7e f3                	jle    17909 <progDE+0x166>
		n = swritech( ch );
   17916:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   1791a:	83 ec 0c             	sub    $0xc,%esp
   1791d:	50                   	push   %eax
   1791e:	e8 42 29 00 00       	call   1a265 <swritech>
   17923:	83 c4 10             	add    $0x10,%esp
   17926:	89 45 dc             	mov    %eax,-0x24(%ebp)
		if( n != 1 ) {
   17929:	83 7d dc 01          	cmpl   $0x1,-0x24(%ebp)
   1792d:	74 2e                	je     1795d <progDE+0x1ba>
			usprint( buf, "== %c, write #2 returned %d\n", ch, n );
   1792f:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17933:	ff 75 dc             	pushl  -0x24(%ebp)
   17936:	50                   	push   %eax
   17937:	68 4f bc 01 00       	push   $0x1bc4f
   1793c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17942:	50                   	push   %eax
   17943:	e8 eb 21 00 00       	call   19b33 <usprint>
   17948:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1794b:	83 ec 0c             	sub    $0xc,%esp
   1794e:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17954:	50                   	push   %eax
   17955:	e8 c6 28 00 00       	call   1a220 <cwrites>
   1795a:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   1795d:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   17961:	8b 45 e8             	mov    -0x18(%ebp),%eax
   17964:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   17967:	7c 97                	jl     17900 <progDE+0x15d>
		}
	}

	// all done!
	return( 0 );
   17969:	b8 00 00 00 00       	mov    $0x0,%eax
}
   1796e:	c9                   	leave  
   1796f:	c3                   	ret    

00017970 <progFG>:
**	 where x is the ID character
**		   n is the iteration count
**		   s is the sleep time in seconds
*/

USERMAIN( progFG ) {
   17970:	55                   	push   %ebp
   17971:	89 e5                	mov    %esp,%ebp
   17973:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   17979:	8b 45 0c             	mov    0xc(%ebp),%eax
   1797c:	8b 00                	mov    (%eax),%eax
   1797e:	85 c0                	test   %eax,%eax
   17980:	74 07                	je     17989 <progFG+0x19>
   17982:	8b 45 0c             	mov    0xc(%ebp),%eax
   17985:	8b 00                	mov    (%eax),%eax
   17987:	eb 05                	jmp    1798e <progFG+0x1e>
   17989:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   1798e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	char ch = '3';	// default character to print
   17991:	c6 45 df 33          	movb   $0x33,-0x21(%ebp)
	int nap = 10;	// default sleep time
   17995:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
	int count = 30;	// iteration count
   1799c:	c7 45 f0 1e 00 00 00 	movl   $0x1e,-0x10(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   179a3:	8b 45 08             	mov    0x8(%ebp),%eax
   179a6:	83 f8 03             	cmp    $0x3,%eax
   179a9:	74 25                	je     179d0 <progFG+0x60>
   179ab:	83 f8 04             	cmp    $0x4,%eax
   179ae:	74 07                	je     179b7 <progFG+0x47>
   179b0:	83 f8 02             	cmp    $0x2,%eax
   179b3:	74 34                	je     179e9 <progFG+0x79>
   179b5:	eb 45                	jmp    179fc <progFG+0x8c>
	case 4:	nap = ustr2int( argv[3], 10 );
   179b7:	8b 45 0c             	mov    0xc(%ebp),%eax
   179ba:	83 c0 0c             	add    $0xc,%eax
   179bd:	8b 00                	mov    (%eax),%eax
   179bf:	83 ec 08             	sub    $0x8,%esp
   179c2:	6a 0a                	push   $0xa
   179c4:	50                   	push   %eax
   179c5:	e8 de 23 00 00       	call   19da8 <ustr2int>
   179ca:	83 c4 10             	add    $0x10,%esp
   179cd:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   179d0:	8b 45 0c             	mov    0xc(%ebp),%eax
   179d3:	83 c0 08             	add    $0x8,%eax
   179d6:	8b 00                	mov    (%eax),%eax
   179d8:	83 ec 08             	sub    $0x8,%esp
   179db:	6a 0a                	push   $0xa
   179dd:	50                   	push   %eax
   179de:	e8 c5 23 00 00       	call   19da8 <ustr2int>
   179e3:	83 c4 10             	add    $0x10,%esp
   179e6:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   179e9:	8b 45 0c             	mov    0xc(%ebp),%eax
   179ec:	83 c0 04             	add    $0x4,%eax
   179ef:	8b 00                	mov    (%eax),%eax
   179f1:	0f b6 00             	movzbl (%eax),%eax
   179f4:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   179f7:	e9 a8 00 00 00       	jmp    17aa4 <progFG+0x134>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   179fc:	ff 75 08             	pushl  0x8(%ebp)
   179ff:	ff 75 e4             	pushl  -0x1c(%ebp)
   17a02:	68 11 bc 01 00       	push   $0x1bc11
   17a07:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17a0d:	50                   	push   %eax
   17a0e:	e8 20 21 00 00       	call   19b33 <usprint>
   17a13:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17a16:	83 ec 0c             	sub    $0xc,%esp
   17a19:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17a1f:	50                   	push   %eax
   17a20:	e8 fb 27 00 00       	call   1a220 <cwrites>
   17a25:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17a28:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   17a2f:	eb 5b                	jmp    17a8c <progFG+0x11c>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   17a31:	8b 45 08             	mov    0x8(%ebp),%eax
   17a34:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17a3b:	8b 45 0c             	mov    0xc(%ebp),%eax
   17a3e:	01 d0                	add    %edx,%eax
   17a40:	8b 00                	mov    (%eax),%eax
   17a42:	85 c0                	test   %eax,%eax
   17a44:	74 13                	je     17a59 <progFG+0xe9>
   17a46:	8b 45 08             	mov    0x8(%ebp),%eax
   17a49:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17a50:	8b 45 0c             	mov    0xc(%ebp),%eax
   17a53:	01 d0                	add    %edx,%eax
   17a55:	8b 00                	mov    (%eax),%eax
   17a57:	eb 05                	jmp    17a5e <progFG+0xee>
   17a59:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   17a5e:	83 ec 04             	sub    $0x4,%esp
   17a61:	50                   	push   %eax
   17a62:	68 2c bc 01 00       	push   $0x1bc2c
   17a67:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17a6d:	50                   	push   %eax
   17a6e:	e8 c0 20 00 00       	call   19b33 <usprint>
   17a73:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17a76:	83 ec 0c             	sub    $0xc,%esp
   17a79:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17a7f:	50                   	push   %eax
   17a80:	e8 9b 27 00 00       	call   1a220 <cwrites>
   17a85:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17a88:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   17a8c:	8b 45 ec             	mov    -0x14(%ebp),%eax
   17a8f:	3b 45 08             	cmp    0x8(%ebp),%eax
   17a92:	7e 9d                	jle    17a31 <progFG+0xc1>
			}
			cwrites( "\n" );
   17a94:	83 ec 0c             	sub    $0xc,%esp
   17a97:	68 30 bc 01 00       	push   $0x1bc30
   17a9c:	e8 7f 27 00 00       	call   1a220 <cwrites>
   17aa1:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int n = swritech( ch );
   17aa4:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
   17aa8:	0f be c0             	movsbl %al,%eax
   17aab:	83 ec 0c             	sub    $0xc,%esp
   17aae:	50                   	push   %eax
   17aaf:	e8 b1 27 00 00       	call   1a265 <swritech>
   17ab4:	83 c4 10             	add    $0x10,%esp
   17ab7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if( n != 1 ) {
   17aba:	83 7d e0 01          	cmpl   $0x1,-0x20(%ebp)
   17abe:	74 31                	je     17af1 <progFG+0x181>
		usprint( buf, "=== %c, write #1 returned %d\n", ch, n );
   17ac0:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
   17ac4:	0f be c0             	movsbl %al,%eax
   17ac7:	ff 75 e0             	pushl  -0x20(%ebp)
   17aca:	50                   	push   %eax
   17acb:	68 8b bc 01 00       	push   $0x1bc8b
   17ad0:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17ad6:	50                   	push   %eax
   17ad7:	e8 57 20 00 00       	call   19b33 <usprint>
   17adc:	83 c4 10             	add    $0x10,%esp
		cwrites( buf );
   17adf:	83 ec 0c             	sub    $0xc,%esp
   17ae2:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   17ae8:	50                   	push   %eax
   17ae9:	e8 32 27 00 00       	call   1a220 <cwrites>
   17aee:	83 c4 10             	add    $0x10,%esp
	}

	write( CHAN_SIO, &ch, 1 );
   17af1:	83 ec 04             	sub    $0x4,%esp
   17af4:	6a 01                	push   $0x1
   17af6:	8d 45 df             	lea    -0x21(%ebp),%eax
   17af9:	50                   	push   %eax
   17afa:	6a 01                	push   $0x1
   17afc:	e8 b0 f2 ff ff       	call   16db1 <write>
   17b01:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   17b04:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   17b0b:	eb 2c                	jmp    17b39 <progFG+0x1c9>
		sleep( SEC_TO_MS(nap) );
   17b0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   17b10:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   17b16:	83 ec 0c             	sub    $0xc,%esp
   17b19:	50                   	push   %eax
   17b1a:	e8 ca f2 ff ff       	call   16de9 <sleep>
   17b1f:	83 c4 10             	add    $0x10,%esp
		write( CHAN_SIO, &ch, 1 );
   17b22:	83 ec 04             	sub    $0x4,%esp
   17b25:	6a 01                	push   $0x1
   17b27:	8d 45 df             	lea    -0x21(%ebp),%eax
   17b2a:	50                   	push   %eax
   17b2b:	6a 01                	push   $0x1
   17b2d:	e8 7f f2 ff ff       	call   16db1 <write>
   17b32:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   17b35:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   17b39:	8b 45 e8             	mov    -0x18(%ebp),%eax
   17b3c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
   17b3f:	7c cc                	jl     17b0d <progFG+0x19d>
	}

	exit( 0 );
   17b41:	83 ec 0c             	sub    $0xc,%esp
   17b44:	6a 00                	push   $0x0
   17b46:	e8 3e f2 ff ff       	call   16d89 <exit>
   17b4b:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   17b4e:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   17b53:	c9                   	leave  
   17b54:	c3                   	ret    

00017b55 <progH>:
** Invoked as:  progH  x  n
**	 where x is the ID character
**		   n is the number of children to spawn
*/

USERMAIN( progH ) {
   17b55:	55                   	push   %ebp
   17b56:	89 e5                	mov    %esp,%ebp
   17b58:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   17b5e:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b61:	8b 00                	mov    (%eax),%eax
   17b63:	85 c0                	test   %eax,%eax
   17b65:	74 07                	je     17b6e <progH+0x19>
   17b67:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b6a:	8b 00                	mov    (%eax),%eax
   17b6c:	eb 05                	jmp    17b73 <progH+0x1e>
   17b6e:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   17b73:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int32_t ret = 0;  // return value
   17b76:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	int count = 5;	  // child count
   17b7d:	c7 45 f0 05 00 00 00 	movl   $0x5,-0x10(%ebp)
	char ch = 'h';	  // default character to print
   17b84:	c6 45 ef 68          	movb   $0x68,-0x11(%ebp)
	char buf[128];
	int whom;

	// process the argument(s)
	switch( argc ) {
   17b88:	8b 45 08             	mov    0x8(%ebp),%eax
   17b8b:	83 f8 02             	cmp    $0x2,%eax
   17b8e:	74 1e                	je     17bae <progH+0x59>
   17b90:	83 f8 03             	cmp    $0x3,%eax
   17b93:	75 2c                	jne    17bc1 <progH+0x6c>
	case 3:	count = ustr2int( argv[2], 10 );
   17b95:	8b 45 0c             	mov    0xc(%ebp),%eax
   17b98:	83 c0 08             	add    $0x8,%eax
   17b9b:	8b 00                	mov    (%eax),%eax
   17b9d:	83 ec 08             	sub    $0x8,%esp
   17ba0:	6a 0a                	push   $0xa
   17ba2:	50                   	push   %eax
   17ba3:	e8 00 22 00 00       	call   19da8 <ustr2int>
   17ba8:	83 c4 10             	add    $0x10,%esp
   17bab:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17bae:	8b 45 0c             	mov    0xc(%ebp),%eax
   17bb1:	83 c0 04             	add    $0x4,%eax
   17bb4:	8b 00                	mov    (%eax),%eax
   17bb6:	0f b6 00             	movzbl (%eax),%eax
   17bb9:	88 45 ef             	mov    %al,-0x11(%ebp)
			break;
   17bbc:	e9 a8 00 00 00       	jmp    17c69 <progH+0x114>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   17bc1:	ff 75 08             	pushl  0x8(%ebp)
   17bc4:	ff 75 e0             	pushl  -0x20(%ebp)
   17bc7:	68 11 bc 01 00       	push   $0x1bc11
   17bcc:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17bd2:	50                   	push   %eax
   17bd3:	e8 5b 1f 00 00       	call   19b33 <usprint>
   17bd8:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17bdb:	83 ec 0c             	sub    $0xc,%esp
   17bde:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17be4:	50                   	push   %eax
   17be5:	e8 36 26 00 00       	call   1a220 <cwrites>
   17bea:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17bed:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   17bf4:	eb 5b                	jmp    17c51 <progH+0xfc>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   17bf6:	8b 45 08             	mov    0x8(%ebp),%eax
   17bf9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17c00:	8b 45 0c             	mov    0xc(%ebp),%eax
   17c03:	01 d0                	add    %edx,%eax
   17c05:	8b 00                	mov    (%eax),%eax
   17c07:	85 c0                	test   %eax,%eax
   17c09:	74 13                	je     17c1e <progH+0xc9>
   17c0b:	8b 45 08             	mov    0x8(%ebp),%eax
   17c0e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17c15:	8b 45 0c             	mov    0xc(%ebp),%eax
   17c18:	01 d0                	add    %edx,%eax
   17c1a:	8b 00                	mov    (%eax),%eax
   17c1c:	eb 05                	jmp    17c23 <progH+0xce>
   17c1e:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   17c23:	83 ec 04             	sub    $0x4,%esp
   17c26:	50                   	push   %eax
   17c27:	68 2c bc 01 00       	push   $0x1bc2c
   17c2c:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17c32:	50                   	push   %eax
   17c33:	e8 fb 1e 00 00       	call   19b33 <usprint>
   17c38:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17c3b:	83 ec 0c             	sub    $0xc,%esp
   17c3e:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17c44:	50                   	push   %eax
   17c45:	e8 d6 25 00 00       	call   1a220 <cwrites>
   17c4a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17c4d:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   17c51:	8b 45 e8             	mov    -0x18(%ebp),%eax
   17c54:	3b 45 08             	cmp    0x8(%ebp),%eax
   17c57:	7e 9d                	jle    17bf6 <progH+0xa1>
			}
			cwrites( "\n" );
   17c59:	83 ec 0c             	sub    $0xc,%esp
   17c5c:	68 30 bc 01 00       	push   $0x1bc30
   17c61:	e8 ba 25 00 00       	call   1a220 <cwrites>
   17c66:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	swritech( ch );
   17c69:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   17c6d:	83 ec 0c             	sub    $0xc,%esp
   17c70:	50                   	push   %eax
   17c71:	e8 ef 25 00 00       	call   1a265 <swritech>
   17c76:	83 c4 10             	add    $0x10,%esp

	// we spawn user Z and then exit before it can terminate
	// progZ 'Z' 10

	char *argsz[] = { "progZ", "Z", "10", NULL };
   17c79:	c7 85 4c ff ff ff a9 	movl   $0x1bca9,-0xb4(%ebp)
   17c80:	bc 01 00 
   17c83:	c7 85 50 ff ff ff af 	movl   $0x1bcaf,-0xb0(%ebp)
   17c8a:	bc 01 00 
   17c8d:	c7 85 54 ff ff ff 84 	movl   $0x1b984,-0xac(%ebp)
   17c94:	b9 01 00 
   17c97:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
   17c9e:	00 00 00 

	for( int i = 0; i < count; ++i ) {
   17ca1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   17ca8:	eb 57                	jmp    17d01 <progH+0x1ac>

		// spawn a child
		whom = spawn( (uint32_t) progZ, argsz );
   17caa:	ba 3b 7d 01 00       	mov    $0x17d3b,%edx
   17caf:	83 ec 08             	sub    $0x8,%esp
   17cb2:	8d 85 4c ff ff ff    	lea    -0xb4(%ebp),%eax
   17cb8:	50                   	push   %eax
   17cb9:	52                   	push   %edx
   17cba:	e8 cb 24 00 00       	call   1a18a <spawn>
   17cbf:	83 c4 10             	add    $0x10,%esp
   17cc2:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// our exit status is the number of failed spawn() calls
		if( whom < 0 ) {
   17cc5:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   17cc9:	79 32                	jns    17cfd <progH+0x1a8>
			usprint( buf, "!! %c spawn() failed, returned %d\n", ch, whom );
   17ccb:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   17ccf:	ff 75 dc             	pushl  -0x24(%ebp)
   17cd2:	50                   	push   %eax
   17cd3:	68 b4 bc 01 00       	push   $0x1bcb4
   17cd8:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17cde:	50                   	push   %eax
   17cdf:	e8 4f 1e 00 00       	call   19b33 <usprint>
   17ce4:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17ce7:	83 ec 0c             	sub    $0xc,%esp
   17cea:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17cf0:	50                   	push   %eax
   17cf1:	e8 2a 25 00 00       	call   1a220 <cwrites>
   17cf6:	83 c4 10             	add    $0x10,%esp
			ret += 1;
   17cf9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
	for( int i = 0; i < count; ++i ) {
   17cfd:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   17d01:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   17d04:	3b 45 f0             	cmp    -0x10(%ebp),%eax
   17d07:	7c a1                	jl     17caa <progH+0x155>
		}
	}

	// yield the CPU so that our child(ren) can run
	sleep( 0 );
   17d09:	83 ec 0c             	sub    $0xc,%esp
   17d0c:	6a 00                	push   $0x0
   17d0e:	e8 d6 f0 ff ff       	call   16de9 <sleep>
   17d13:	83 c4 10             	add    $0x10,%esp

	// announce our departure
	swritech( ch );
   17d16:	0f be 45 ef          	movsbl -0x11(%ebp),%eax
   17d1a:	83 ec 0c             	sub    $0xc,%esp
   17d1d:	50                   	push   %eax
   17d1e:	e8 42 25 00 00       	call   1a265 <swritech>
   17d23:	83 c4 10             	add    $0x10,%esp

	exit( ret );
   17d26:	83 ec 0c             	sub    $0xc,%esp
   17d29:	ff 75 f4             	pushl  -0xc(%ebp)
   17d2c:	e8 58 f0 ff ff       	call   16d89 <exit>
   17d31:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   17d34:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   17d39:	c9                   	leave  
   17d3a:	c3                   	ret    

00017d3b <progZ>:
** Invoked as:	progZ  x  [ n ]
**	 where x is the ID character
**		   n is the iteration count (defaults to 10)
*/

USERMAIN( progZ ) {
   17d3b:	55                   	push   %ebp
   17d3c:	89 e5                	mov    %esp,%ebp
   17d3e:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   17d44:	8b 45 0c             	mov    0xc(%ebp),%eax
   17d47:	8b 00                	mov    (%eax),%eax
   17d49:	85 c0                	test   %eax,%eax
   17d4b:	74 07                	je     17d54 <progZ+0x19>
   17d4d:	8b 45 0c             	mov    0xc(%ebp),%eax
   17d50:	8b 00                	mov    (%eax),%eax
   17d52:	eb 05                	jmp    17d59 <progZ+0x1e>
   17d54:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   17d59:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 10;	  // default iteration count
   17d5c:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
	char ch = 'z';	  // default character to print
   17d63:	c6 45 f3 7a          	movb   $0x7a,-0xd(%ebp)
	char buf[128];

	(void) name;

	// process the command-line arguments
	switch( argc ) {
   17d67:	8b 45 08             	mov    0x8(%ebp),%eax
   17d6a:	83 f8 02             	cmp    $0x2,%eax
   17d6d:	74 1e                	je     17d8d <progZ+0x52>
   17d6f:	83 f8 03             	cmp    $0x3,%eax
   17d72:	75 2c                	jne    17da0 <progZ+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   17d74:	8b 45 0c             	mov    0xc(%ebp),%eax
   17d77:	83 c0 08             	add    $0x8,%eax
   17d7a:	8b 00                	mov    (%eax),%eax
   17d7c:	83 ec 08             	sub    $0x8,%esp
   17d7f:	6a 0a                	push   $0xa
   17d81:	50                   	push   %eax
   17d82:	e8 21 20 00 00       	call   19da8 <ustr2int>
   17d87:	83 c4 10             	add    $0x10,%esp
   17d8a:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17d8d:	8b 45 0c             	mov    0xc(%ebp),%eax
   17d90:	83 c0 04             	add    $0x4,%eax
   17d93:	8b 00                	mov    (%eax),%eax
   17d95:	0f b6 00             	movzbl (%eax),%eax
   17d98:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   17d9b:	e9 a8 00 00 00       	jmp    17e48 <progZ+0x10d>
	default:
			usprint( buf, "?: argc %d, args: ", argc );
   17da0:	83 ec 04             	sub    $0x4,%esp
   17da3:	ff 75 08             	pushl  0x8(%ebp)
   17da6:	68 d7 bc 01 00       	push   $0x1bcd7
   17dab:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17db1:	50                   	push   %eax
   17db2:	e8 7c 1d 00 00       	call   19b33 <usprint>
   17db7:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17dba:	83 ec 0c             	sub    $0xc,%esp
   17dbd:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17dc3:	50                   	push   %eax
   17dc4:	e8 57 24 00 00       	call   1a220 <cwrites>
   17dc9:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17dcc:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   17dd3:	eb 5b                	jmp    17e30 <progZ+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   17dd5:	8b 45 08             	mov    0x8(%ebp),%eax
   17dd8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17ddf:	8b 45 0c             	mov    0xc(%ebp),%eax
   17de2:	01 d0                	add    %edx,%eax
   17de4:	8b 00                	mov    (%eax),%eax
   17de6:	85 c0                	test   %eax,%eax
   17de8:	74 13                	je     17dfd <progZ+0xc2>
   17dea:	8b 45 08             	mov    0x8(%ebp),%eax
   17ded:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17df4:	8b 45 0c             	mov    0xc(%ebp),%eax
   17df7:	01 d0                	add    %edx,%eax
   17df9:	8b 00                	mov    (%eax),%eax
   17dfb:	eb 05                	jmp    17e02 <progZ+0xc7>
   17dfd:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   17e02:	83 ec 04             	sub    $0x4,%esp
   17e05:	50                   	push   %eax
   17e06:	68 2c bc 01 00       	push   $0x1bc2c
   17e0b:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17e11:	50                   	push   %eax
   17e12:	e8 1c 1d 00 00       	call   19b33 <usprint>
   17e17:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   17e1a:	83 ec 0c             	sub    $0xc,%esp
   17e1d:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17e23:	50                   	push   %eax
   17e24:	e8 f7 23 00 00       	call   1a220 <cwrites>
   17e29:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17e2c:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   17e30:	8b 45 ec             	mov    -0x14(%ebp),%eax
   17e33:	3b 45 08             	cmp    0x8(%ebp),%eax
   17e36:	7e 9d                	jle    17dd5 <progZ+0x9a>
			}
			cwrites( "\n" );
   17e38:	83 ec 0c             	sub    $0xc,%esp
   17e3b:	68 30 bc 01 00       	push   $0x1bc30
   17e40:	e8 db 23 00 00       	call   1a220 <cwrites>
   17e45:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int pid = getpid();
   17e48:	e8 6c ef ff ff       	call   16db9 <getpid>
   17e4d:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d]", ch, pid );
   17e50:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17e54:	ff 75 dc             	pushl  -0x24(%ebp)
   17e57:	50                   	push   %eax
   17e58:	68 ea bc 01 00       	push   $0x1bcea
   17e5d:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17e63:	50                   	push   %eax
   17e64:	e8 ca 1c 00 00       	call   19b33 <usprint>
   17e69:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   17e6c:	83 ec 0c             	sub    $0xc,%esp
   17e6f:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17e75:	50                   	push   %eax
   17e76:	e8 0b 24 00 00       	call   1a286 <swrites>
   17e7b:	83 c4 10             	add    $0x10,%esp

	// iterate for a while; occasionally yield the CPU
	for( int i = 0; i < count ; ++i ) {
   17e7e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   17e85:	eb 5f                	jmp    17ee6 <progZ+0x1ab>
		usprint( buf, " %c[%d]", ch, i );
   17e87:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   17e8b:	ff 75 e8             	pushl  -0x18(%ebp)
   17e8e:	50                   	push   %eax
   17e8f:	68 ea bc 01 00       	push   $0x1bcea
   17e94:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17e9a:	50                   	push   %eax
   17e9b:	e8 93 1c 00 00       	call   19b33 <usprint>
   17ea0:	83 c4 10             	add    $0x10,%esp
		swrites( buf );
   17ea3:	83 ec 0c             	sub    $0xc,%esp
   17ea6:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   17eac:	50                   	push   %eax
   17ead:	e8 d4 23 00 00       	call   1a286 <swrites>
   17eb2:	83 c4 10             	add    $0x10,%esp
		DELAY(STD);
   17eb5:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   17ebc:	eb 04                	jmp    17ec2 <progZ+0x187>
   17ebe:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   17ec2:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   17ec9:	7e f3                	jle    17ebe <progZ+0x183>
		if( i & 1 ) {
   17ecb:	8b 45 e8             	mov    -0x18(%ebp),%eax
   17ece:	83 e0 01             	and    $0x1,%eax
   17ed1:	85 c0                	test   %eax,%eax
   17ed3:	74 0d                	je     17ee2 <progZ+0x1a7>
			sleep( 0 );
   17ed5:	83 ec 0c             	sub    $0xc,%esp
   17ed8:	6a 00                	push   $0x0
   17eda:	e8 0a ef ff ff       	call   16de9 <sleep>
   17edf:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   17ee2:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   17ee6:	8b 45 e8             	mov    -0x18(%ebp),%eax
   17ee9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   17eec:	7c 99                	jl     17e87 <progZ+0x14c>
		}
	}

	exit( 0 );
   17eee:	83 ec 0c             	sub    $0xc,%esp
   17ef1:	6a 00                	push   $0x0
   17ef3:	e8 91 ee ff ff       	call   16d89 <exit>
   17ef8:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   17efb:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   17f00:	c9                   	leave  
   17f01:	c3                   	ret    

00017f02 <progI>:
** Invoked as:  progI [ x [ n ] ]
**	 where x is the ID character (defaults to 'i')
**		   n is the number of children to spawn (defaults to 5)
*/

USERMAIN( progI ) {
   17f02:	55                   	push   %ebp
   17f03:	89 e5                	mov    %esp,%ebp
   17f05:	81 ec 98 01 00 00    	sub    $0x198,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   17f0b:	8b 45 0c             	mov    0xc(%ebp),%eax
   17f0e:	8b 00                	mov    (%eax),%eax
   17f10:	85 c0                	test   %eax,%eax
   17f12:	74 07                	je     17f1b <progI+0x19>
   17f14:	8b 45 0c             	mov    0xc(%ebp),%eax
   17f17:	8b 00                	mov    (%eax),%eax
   17f19:	eb 05                	jmp    17f20 <progI+0x1e>
   17f1b:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   17f20:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 5;	  // default child count
   17f23:	c7 45 f4 05 00 00 00 	movl   $0x5,-0xc(%ebp)
	char ch = 'i';	  // default character to print
   17f2a:	c6 45 cf 69          	movb   $0x69,-0x31(%ebp)
	int nap = 5;	  // nap time
   17f2e:	c7 45 dc 05 00 00 00 	movl   $0x5,-0x24(%ebp)
	char buf[128];
	char ch2[] = "*?*";
   17f35:	c7 85 4b ff ff ff 2a 	movl   $0x2a3f2a,-0xb5(%ebp)
   17f3c:	3f 2a 00 
	uint_t children[MAX_CHILDREN];
	int nkids = 0;
   17f3f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

	// process the command-line arguments
	switch( argc ) {
   17f46:	8b 45 08             	mov    0x8(%ebp),%eax
   17f49:	83 f8 02             	cmp    $0x2,%eax
   17f4c:	74 29                	je     17f77 <progI+0x75>
   17f4e:	83 f8 03             	cmp    $0x3,%eax
   17f51:	74 0b                	je     17f5e <progI+0x5c>
   17f53:	83 f8 01             	cmp    $0x1,%eax
   17f56:	0f 84 d8 00 00 00    	je     18034 <progI+0x132>
   17f5c:	eb 2c                	jmp    17f8a <progI+0x88>
	case 3:	count = ustr2int( argv[2], 10 );
   17f5e:	8b 45 0c             	mov    0xc(%ebp),%eax
   17f61:	83 c0 08             	add    $0x8,%eax
   17f64:	8b 00                	mov    (%eax),%eax
   17f66:	83 ec 08             	sub    $0x8,%esp
   17f69:	6a 0a                	push   $0xa
   17f6b:	50                   	push   %eax
   17f6c:	e8 37 1e 00 00       	call   19da8 <ustr2int>
   17f71:	83 c4 10             	add    $0x10,%esp
   17f74:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   17f77:	8b 45 0c             	mov    0xc(%ebp),%eax
   17f7a:	83 c0 04             	add    $0x4,%eax
   17f7d:	8b 00                	mov    (%eax),%eax
   17f7f:	0f b6 00             	movzbl (%eax),%eax
   17f82:	88 45 cf             	mov    %al,-0x31(%ebp)
			break;
   17f85:	e9 ab 00 00 00       	jmp    18035 <progI+0x133>
	case 1:	// just use the defaults
			break;
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   17f8a:	ff 75 08             	pushl  0x8(%ebp)
   17f8d:	ff 75 e0             	pushl  -0x20(%ebp)
   17f90:	68 11 bc 01 00       	push   $0x1bc11
   17f95:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   17f9b:	50                   	push   %eax
   17f9c:	e8 92 1b 00 00       	call   19b33 <usprint>
   17fa1:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   17fa4:	83 ec 0c             	sub    $0xc,%esp
   17fa7:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   17fad:	50                   	push   %eax
   17fae:	e8 6d 22 00 00       	call   1a220 <cwrites>
   17fb3:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   17fb6:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   17fbd:	eb 5b                	jmp    1801a <progI+0x118>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   17fbf:	8b 45 08             	mov    0x8(%ebp),%eax
   17fc2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17fc9:	8b 45 0c             	mov    0xc(%ebp),%eax
   17fcc:	01 d0                	add    %edx,%eax
   17fce:	8b 00                	mov    (%eax),%eax
   17fd0:	85 c0                	test   %eax,%eax
   17fd2:	74 13                	je     17fe7 <progI+0xe5>
   17fd4:	8b 45 08             	mov    0x8(%ebp),%eax
   17fd7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   17fde:	8b 45 0c             	mov    0xc(%ebp),%eax
   17fe1:	01 d0                	add    %edx,%eax
   17fe3:	8b 00                	mov    (%eax),%eax
   17fe5:	eb 05                	jmp    17fec <progI+0xea>
   17fe7:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   17fec:	83 ec 04             	sub    $0x4,%esp
   17fef:	50                   	push   %eax
   17ff0:	68 2c bc 01 00       	push   $0x1bc2c
   17ff5:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   17ffb:	50                   	push   %eax
   17ffc:	e8 32 1b 00 00       	call   19b33 <usprint>
   18001:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   18004:	83 ec 0c             	sub    $0xc,%esp
   18007:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   1800d:	50                   	push   %eax
   1800e:	e8 0d 22 00 00       	call   1a220 <cwrites>
   18013:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18016:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   1801a:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1801d:	3b 45 08             	cmp    0x8(%ebp),%eax
   18020:	7e 9d                	jle    17fbf <progI+0xbd>
			}
			cwrites( "\n" );
   18022:	83 ec 0c             	sub    $0xc,%esp
   18025:	68 30 bc 01 00       	push   $0x1bc30
   1802a:	e8 f1 21 00 00       	call   1a220 <cwrites>
   1802f:	83 c4 10             	add    $0x10,%esp
   18032:	eb 01                	jmp    18035 <progI+0x133>
			break;
   18034:	90                   	nop
	}

	// secondary output (for indicating errors)
	ch2[1] = ch;
   18035:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   18039:	88 85 4c ff ff ff    	mov    %al,-0xb4(%ebp)

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   1803f:	83 ec 04             	sub    $0x4,%esp
   18042:	6a 01                	push   $0x1
   18044:	8d 45 cf             	lea    -0x31(%ebp),%eax
   18047:	50                   	push   %eax
   18048:	6a 01                	push   $0x1
   1804a:	e8 62 ed ff ff       	call   16db1 <write>
   1804f:	83 c4 10             	add    $0x10,%esp

	// set up the argument vector
	// we run:	progW 10 5

	char *argsw[] = { "progW", "W", "10", "5", NULL };
   18052:	c7 85 6c fe ff ff f2 	movl   $0x1bcf2,-0x194(%ebp)
   18059:	bc 01 00 
   1805c:	c7 85 70 fe ff ff 06 	movl   $0x1ba06,-0x190(%ebp)
   18063:	ba 01 00 
   18066:	c7 85 74 fe ff ff 84 	movl   $0x1b984,-0x18c(%ebp)
   1806d:	b9 01 00 
   18070:	c7 85 78 fe ff ff b3 	movl   $0x1b9b3,-0x188(%ebp)
   18077:	b9 01 00 
   1807a:	c7 85 7c fe ff ff 00 	movl   $0x0,-0x184(%ebp)
   18081:	00 00 00 

	for( int i = 0; i < count; ++i ) {
   18084:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   1808b:	eb 5f                	jmp    180ec <progI+0x1ea>
		int whom = spawn( (uint32_t) progW, argsw );
   1808d:	ba 75 82 01 00       	mov    $0x18275,%edx
   18092:	83 ec 08             	sub    $0x8,%esp
   18095:	8d 85 6c fe ff ff    	lea    -0x194(%ebp),%eax
   1809b:	50                   	push   %eax
   1809c:	52                   	push   %edx
   1809d:	e8 e8 20 00 00       	call   1a18a <spawn>
   180a2:	83 c4 10             	add    $0x10,%esp
   180a5:	89 45 d0             	mov    %eax,-0x30(%ebp)
		if( whom < 0 ) {
   180a8:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
   180ac:	79 14                	jns    180c2 <progI+0x1c0>
			swrites( ch2 );
   180ae:	83 ec 0c             	sub    $0xc,%esp
   180b1:	8d 85 4b ff ff ff    	lea    -0xb5(%ebp),%eax
   180b7:	50                   	push   %eax
   180b8:	e8 c9 21 00 00       	call   1a286 <swrites>
   180bd:	83 c4 10             	add    $0x10,%esp
   180c0:	eb 26                	jmp    180e8 <progI+0x1e6>
		} else {
			swritech( ch );
   180c2:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   180c6:	0f be c0             	movsbl %al,%eax
   180c9:	83 ec 0c             	sub    $0xc,%esp
   180cc:	50                   	push   %eax
   180cd:	e8 93 21 00 00       	call   1a265 <swritech>
   180d2:	83 c4 10             	add    $0x10,%esp
			children[nkids++] = whom;
   180d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
   180d8:	8d 50 01             	lea    0x1(%eax),%edx
   180db:	89 55 f0             	mov    %edx,-0x10(%ebp)
   180de:	8b 55 d0             	mov    -0x30(%ebp),%edx
   180e1:	89 94 85 80 fe ff ff 	mov    %edx,-0x180(%ebp,%eax,4)
	for( int i = 0; i < count; ++i ) {
   180e8:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   180ec:	8b 45 e8             	mov    -0x18(%ebp),%eax
   180ef:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   180f2:	7c 99                	jl     1808d <progI+0x18b>
		}
	}

	// let the children start
	sleep( SEC_TO_MS(nap) );
   180f4:	8b 45 dc             	mov    -0x24(%ebp),%eax
   180f7:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   180fd:	83 ec 0c             	sub    $0xc,%esp
   18100:	50                   	push   %eax
   18101:	e8 e3 ec ff ff       	call   16de9 <sleep>
   18106:	83 c4 10             	add    $0x10,%esp

	// kill two of them
	int32_t status = kill( children[1] );
   18109:	8b 85 84 fe ff ff    	mov    -0x17c(%ebp),%eax
   1810f:	83 ec 0c             	sub    $0xc,%esp
   18112:	50                   	push   %eax
   18113:	e8 c9 ec ff ff       	call   16de1 <kill>
   18118:	83 c4 10             	add    $0x10,%esp
   1811b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	if( status ) {
   1811e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   18122:	74 45                	je     18169 <progI+0x267>
		usprint( buf, "!! %c: kill(%d) status %d\n", ch, children[1], status );
   18124:	8b 95 84 fe ff ff    	mov    -0x17c(%ebp),%edx
   1812a:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   1812e:	0f be c0             	movsbl %al,%eax
   18131:	83 ec 0c             	sub    $0xc,%esp
   18134:	ff 75 d8             	pushl  -0x28(%ebp)
   18137:	52                   	push   %edx
   18138:	50                   	push   %eax
   18139:	68 f8 bc 01 00       	push   $0x1bcf8
   1813e:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   18144:	50                   	push   %eax
   18145:	e8 e9 19 00 00       	call   19b33 <usprint>
   1814a:	83 c4 20             	add    $0x20,%esp
		cwrites( buf );
   1814d:	83 ec 0c             	sub    $0xc,%esp
   18150:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   18156:	50                   	push   %eax
   18157:	e8 c4 20 00 00       	call   1a220 <cwrites>
   1815c:	83 c4 10             	add    $0x10,%esp
		children[1] = -42;
   1815f:	c7 85 84 fe ff ff d6 	movl   $0xffffffd6,-0x17c(%ebp)
   18166:	ff ff ff 
	}
	status = kill( children[3] );
   18169:	8b 85 8c fe ff ff    	mov    -0x174(%ebp),%eax
   1816f:	83 ec 0c             	sub    $0xc,%esp
   18172:	50                   	push   %eax
   18173:	e8 69 ec ff ff       	call   16de1 <kill>
   18178:	83 c4 10             	add    $0x10,%esp
   1817b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	if( status ) {
   1817e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   18182:	74 45                	je     181c9 <progI+0x2c7>
		usprint( buf, "!! %c: kill(%d) status %d\n", ch, children[3], status );
   18184:	8b 95 8c fe ff ff    	mov    -0x174(%ebp),%edx
   1818a:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   1818e:	0f be c0             	movsbl %al,%eax
   18191:	83 ec 0c             	sub    $0xc,%esp
   18194:	ff 75 d8             	pushl  -0x28(%ebp)
   18197:	52                   	push   %edx
   18198:	50                   	push   %eax
   18199:	68 f8 bc 01 00       	push   $0x1bcf8
   1819e:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   181a4:	50                   	push   %eax
   181a5:	e8 89 19 00 00       	call   19b33 <usprint>
   181aa:	83 c4 20             	add    $0x20,%esp
		cwrites( buf );
   181ad:	83 ec 0c             	sub    $0xc,%esp
   181b0:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   181b6:	50                   	push   %eax
   181b7:	e8 64 20 00 00       	call   1a220 <cwrites>
   181bc:	83 c4 10             	add    $0x10,%esp
		children[3] = -42;
   181bf:	c7 85 8c fe ff ff d6 	movl   $0xffffffd6,-0x174(%ebp)
   181c6:	ff ff ff 
	}

	// collect child information
	while( 1 ) {
		int n = waitpid( 0, NULL );
   181c9:	83 ec 08             	sub    $0x8,%esp
   181cc:	6a 00                	push   $0x0
   181ce:	6a 00                	push   $0x0
   181d0:	e8 bc eb ff ff       	call   16d91 <waitpid>
   181d5:	83 c4 10             	add    $0x10,%esp
   181d8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		if( n == E_NO_CHILDREN ) {
   181db:	83 7d d4 fc          	cmpl   $0xfffffffc,-0x2c(%ebp)
   181df:	74 7f                	je     18260 <progI+0x35e>
			// all done!
			break;
		}
		for( int i = 0; i < count; ++i ) {
   181e1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   181e8:	eb 54                	jmp    1823e <progI+0x33c>
			if( children[i] == n ) {
   181ea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   181ed:	8b 94 85 80 fe ff ff 	mov    -0x180(%ebp,%eax,4),%edx
   181f4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   181f7:	39 c2                	cmp    %eax,%edx
   181f9:	75 3f                	jne    1823a <progI+0x338>
				usprint( buf, "== %c: child %d (%d)\n", ch, i, children[i] );
   181fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   181fe:	8b 94 85 80 fe ff ff 	mov    -0x180(%ebp,%eax,4),%edx
   18205:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
   18209:	0f be c0             	movsbl %al,%eax
   1820c:	83 ec 0c             	sub    $0xc,%esp
   1820f:	52                   	push   %edx
   18210:	ff 75 e4             	pushl  -0x1c(%ebp)
   18213:	50                   	push   %eax
   18214:	68 13 bd 01 00       	push   $0x1bd13
   18219:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   1821f:	50                   	push   %eax
   18220:	e8 0e 19 00 00       	call   19b33 <usprint>
   18225:	83 c4 20             	add    $0x20,%esp
				cwrites( buf );
   18228:	83 ec 0c             	sub    $0xc,%esp
   1822b:	8d 85 4f ff ff ff    	lea    -0xb1(%ebp),%eax
   18231:	50                   	push   %eax
   18232:	e8 e9 1f 00 00       	call   1a220 <cwrites>
   18237:	83 c4 10             	add    $0x10,%esp
		for( int i = 0; i < count; ++i ) {
   1823a:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   1823e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   18241:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18244:	7c a4                	jl     181ea <progI+0x2e8>
			}
		}
		sleep( SEC_TO_MS(nap) );
   18246:	8b 45 dc             	mov    -0x24(%ebp),%eax
   18249:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   1824f:	83 ec 0c             	sub    $0xc,%esp
   18252:	50                   	push   %eax
   18253:	e8 91 eb ff ff       	call   16de9 <sleep>
   18258:	83 c4 10             	add    $0x10,%esp
	while( 1 ) {
   1825b:	e9 69 ff ff ff       	jmp    181c9 <progI+0x2c7>
			break;
   18260:	90                   	nop
	};

	// let init() clean up after us!

	exit( 0 );
   18261:	83 ec 0c             	sub    $0xc,%esp
   18264:	6a 00                	push   $0x0
   18266:	e8 1e eb ff ff       	call   16d89 <exit>
   1826b:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   1826e:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   18273:	c9                   	leave  
   18274:	c3                   	ret    

00018275 <progW>:
**	 where x is the ID character
**		   n is the iteration count (defaults to 20)
**		   s is the sleep time (defaults to 3 seconds)
*/

USERMAIN( progW ) {
   18275:	55                   	push   %ebp
   18276:	89 e5                	mov    %esp,%ebp
   18278:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   1827e:	8b 45 0c             	mov    0xc(%ebp),%eax
   18281:	8b 00                	mov    (%eax),%eax
   18283:	85 c0                	test   %eax,%eax
   18285:	74 07                	je     1828e <progW+0x19>
   18287:	8b 45 0c             	mov    0xc(%ebp),%eax
   1828a:	8b 00                	mov    (%eax),%eax
   1828c:	eb 05                	jmp    18293 <progW+0x1e>
   1828e:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   18293:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int count = 20;	  // default iteration count
   18296:	c7 45 f4 14 00 00 00 	movl   $0x14,-0xc(%ebp)
	char ch = 'w';	  // default character to print
   1829d:	c6 45 db 77          	movb   $0x77,-0x25(%ebp)
	int nap = 3;	  // nap length
   182a1:	c7 45 f0 03 00 00 00 	movl   $0x3,-0x10(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   182a8:	8b 45 08             	mov    0x8(%ebp),%eax
   182ab:	83 f8 03             	cmp    $0x3,%eax
   182ae:	74 25                	je     182d5 <progW+0x60>
   182b0:	83 f8 04             	cmp    $0x4,%eax
   182b3:	74 07                	je     182bc <progW+0x47>
   182b5:	83 f8 02             	cmp    $0x2,%eax
   182b8:	74 34                	je     182ee <progW+0x79>
   182ba:	eb 45                	jmp    18301 <progW+0x8c>
	case 4:	nap = ustr2int( argv[3], 10 );
   182bc:	8b 45 0c             	mov    0xc(%ebp),%eax
   182bf:	83 c0 0c             	add    $0xc,%eax
   182c2:	8b 00                	mov    (%eax),%eax
   182c4:	83 ec 08             	sub    $0x8,%esp
   182c7:	6a 0a                	push   $0xa
   182c9:	50                   	push   %eax
   182ca:	e8 d9 1a 00 00       	call   19da8 <ustr2int>
   182cf:	83 c4 10             	add    $0x10,%esp
   182d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   182d5:	8b 45 0c             	mov    0xc(%ebp),%eax
   182d8:	83 c0 08             	add    $0x8,%eax
   182db:	8b 00                	mov    (%eax),%eax
   182dd:	83 ec 08             	sub    $0x8,%esp
   182e0:	6a 0a                	push   $0xa
   182e2:	50                   	push   %eax
   182e3:	e8 c0 1a 00 00       	call   19da8 <ustr2int>
   182e8:	83 c4 10             	add    $0x10,%esp
   182eb:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   182ee:	8b 45 0c             	mov    0xc(%ebp),%eax
   182f1:	83 c0 04             	add    $0x4,%eax
   182f4:	8b 00                	mov    (%eax),%eax
   182f6:	0f b6 00             	movzbl (%eax),%eax
   182f9:	88 45 db             	mov    %al,-0x25(%ebp)
			break;
   182fc:	e9 a8 00 00 00       	jmp    183a9 <progW+0x134>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18301:	ff 75 08             	pushl  0x8(%ebp)
   18304:	ff 75 e4             	pushl  -0x1c(%ebp)
   18307:	68 11 bc 01 00       	push   $0x1bc11
   1830c:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18312:	50                   	push   %eax
   18313:	e8 1b 18 00 00       	call   19b33 <usprint>
   18318:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1831b:	83 ec 0c             	sub    $0xc,%esp
   1831e:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18324:	50                   	push   %eax
   18325:	e8 f6 1e 00 00       	call   1a220 <cwrites>
   1832a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1832d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18334:	eb 5b                	jmp    18391 <progW+0x11c>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18336:	8b 45 08             	mov    0x8(%ebp),%eax
   18339:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18340:	8b 45 0c             	mov    0xc(%ebp),%eax
   18343:	01 d0                	add    %edx,%eax
   18345:	8b 00                	mov    (%eax),%eax
   18347:	85 c0                	test   %eax,%eax
   18349:	74 13                	je     1835e <progW+0xe9>
   1834b:	8b 45 08             	mov    0x8(%ebp),%eax
   1834e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18355:	8b 45 0c             	mov    0xc(%ebp),%eax
   18358:	01 d0                	add    %edx,%eax
   1835a:	8b 00                	mov    (%eax),%eax
   1835c:	eb 05                	jmp    18363 <progW+0xee>
   1835e:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   18363:	83 ec 04             	sub    $0x4,%esp
   18366:	50                   	push   %eax
   18367:	68 2c bc 01 00       	push   $0x1bc2c
   1836c:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18372:	50                   	push   %eax
   18373:	e8 bb 17 00 00       	call   19b33 <usprint>
   18378:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1837b:	83 ec 0c             	sub    $0xc,%esp
   1837e:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18384:	50                   	push   %eax
   18385:	e8 96 1e 00 00       	call   1a220 <cwrites>
   1838a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1838d:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18391:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18394:	3b 45 08             	cmp    0x8(%ebp),%eax
   18397:	7e 9d                	jle    18336 <progW+0xc1>
			}
			cwrites( "\n" );
   18399:	83 ec 0c             	sub    $0xc,%esp
   1839c:	68 30 bc 01 00       	push   $0x1bc30
   183a1:	e8 7a 1e 00 00       	call   1a220 <cwrites>
   183a6:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int pid = getpid();
   183a9:	e8 0b ea ff ff       	call   16db9 <getpid>
   183ae:	89 45 e0             	mov    %eax,-0x20(%ebp)
	uint32_t now = gettime();
   183b1:	e8 13 ea ff ff       	call   16dc9 <gettime>
   183b6:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d,%u]", ch, pid, now );
   183b9:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   183bd:	0f be c0             	movsbl %al,%eax
   183c0:	83 ec 0c             	sub    $0xc,%esp
   183c3:	ff 75 dc             	pushl  -0x24(%ebp)
   183c6:	ff 75 e0             	pushl  -0x20(%ebp)
   183c9:	50                   	push   %eax
   183ca:	68 29 bd 01 00       	push   $0x1bd29
   183cf:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   183d5:	50                   	push   %eax
   183d6:	e8 58 17 00 00       	call   19b33 <usprint>
   183db:	83 c4 20             	add    $0x20,%esp
	swrites( buf );
   183de:	83 ec 0c             	sub    $0xc,%esp
   183e1:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   183e7:	50                   	push   %eax
   183e8:	e8 99 1e 00 00       	call   1a286 <swrites>
   183ed:	83 c4 10             	add    $0x10,%esp

	write( CHAN_SIO, &ch, 1 );
   183f0:	83 ec 04             	sub    $0x4,%esp
   183f3:	6a 01                	push   $0x1
   183f5:	8d 45 db             	lea    -0x25(%ebp),%eax
   183f8:	50                   	push   %eax
   183f9:	6a 01                	push   $0x1
   183fb:	e8 b1 e9 ff ff       	call   16db1 <write>
   18400:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   18403:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   1840a:	eb 58                	jmp    18464 <progW+0x1ef>
		now = gettime();
   1840c:	e8 b8 e9 ff ff       	call   16dc9 <gettime>
   18411:	89 45 dc             	mov    %eax,-0x24(%ebp)
		usprint( buf, " %c[%d,%u] ", ch, pid, now );
   18414:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
   18418:	0f be c0             	movsbl %al,%eax
   1841b:	83 ec 0c             	sub    $0xc,%esp
   1841e:	ff 75 dc             	pushl  -0x24(%ebp)
   18421:	ff 75 e0             	pushl  -0x20(%ebp)
   18424:	50                   	push   %eax
   18425:	68 34 bd 01 00       	push   $0x1bd34
   1842a:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18430:	50                   	push   %eax
   18431:	e8 fd 16 00 00       	call   19b33 <usprint>
   18436:	83 c4 20             	add    $0x20,%esp
		swrites( buf );
   18439:	83 ec 0c             	sub    $0xc,%esp
   1843c:	8d 85 5b ff ff ff    	lea    -0xa5(%ebp),%eax
   18442:	50                   	push   %eax
   18443:	e8 3e 1e 00 00       	call   1a286 <swrites>
   18448:	83 c4 10             	add    $0x10,%esp
		sleep( SEC_TO_MS(nap) );
   1844b:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1844e:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   18454:	83 ec 0c             	sub    $0xc,%esp
   18457:	50                   	push   %eax
   18458:	e8 8c e9 ff ff       	call   16de9 <sleep>
   1845d:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   18460:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18464:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18467:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   1846a:	7c a0                	jl     1840c <progW+0x197>
	}

	exit( 0 );
   1846c:	83 ec 0c             	sub    $0xc,%esp
   1846f:	6a 00                	push   $0x0
   18471:	e8 13 e9 ff ff       	call   16d89 <exit>
   18476:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18479:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   1847e:	c9                   	leave  
   1847f:	c3                   	ret    

00018480 <progJ>:
** Invoked as:  progJ  x  [ n ]
**	 where x is the ID character
**		   n is the number of children to spawn (defaults to 2 * N_PROCS)
*/

USERMAIN( progJ ) {
   18480:	55                   	push   %ebp
   18481:	89 e5                	mov    %esp,%ebp
   18483:	81 ec b8 00 00 00    	sub    $0xb8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18489:	8b 45 0c             	mov    0xc(%ebp),%eax
   1848c:	8b 00                	mov    (%eax),%eax
   1848e:	85 c0                	test   %eax,%eax
   18490:	74 07                	je     18499 <progJ+0x19>
   18492:	8b 45 0c             	mov    0xc(%ebp),%eax
   18495:	8b 00                	mov    (%eax),%eax
   18497:	eb 05                	jmp    1849e <progJ+0x1e>
   18499:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   1849e:	89 45 e8             	mov    %eax,-0x18(%ebp)
	int count = 2 * N_PROCS;	// number of children to spawn
   184a1:	c7 45 f4 32 00 00 00 	movl   $0x32,-0xc(%ebp)
	char ch = 'j';				// default character to print
   184a8:	c6 45 e3 6a          	movb   $0x6a,-0x1d(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   184ac:	8b 45 08             	mov    0x8(%ebp),%eax
   184af:	83 f8 02             	cmp    $0x2,%eax
   184b2:	74 1e                	je     184d2 <progJ+0x52>
   184b4:	83 f8 03             	cmp    $0x3,%eax
   184b7:	75 2c                	jne    184e5 <progJ+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   184b9:	8b 45 0c             	mov    0xc(%ebp),%eax
   184bc:	83 c0 08             	add    $0x8,%eax
   184bf:	8b 00                	mov    (%eax),%eax
   184c1:	83 ec 08             	sub    $0x8,%esp
   184c4:	6a 0a                	push   $0xa
   184c6:	50                   	push   %eax
   184c7:	e8 dc 18 00 00       	call   19da8 <ustr2int>
   184cc:	83 c4 10             	add    $0x10,%esp
   184cf:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   184d2:	8b 45 0c             	mov    0xc(%ebp),%eax
   184d5:	83 c0 04             	add    $0x4,%eax
   184d8:	8b 00                	mov    (%eax),%eax
   184da:	0f b6 00             	movzbl (%eax),%eax
   184dd:	88 45 e3             	mov    %al,-0x1d(%ebp)
			break;
   184e0:	e9 a8 00 00 00       	jmp    1858d <progJ+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   184e5:	ff 75 08             	pushl  0x8(%ebp)
   184e8:	ff 75 e8             	pushl  -0x18(%ebp)
   184eb:	68 11 bc 01 00       	push   $0x1bc11
   184f0:	8d 85 63 ff ff ff    	lea    -0x9d(%ebp),%eax
   184f6:	50                   	push   %eax
   184f7:	e8 37 16 00 00       	call   19b33 <usprint>
   184fc:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   184ff:	83 ec 0c             	sub    $0xc,%esp
   18502:	8d 85 63 ff ff ff    	lea    -0x9d(%ebp),%eax
   18508:	50                   	push   %eax
   18509:	e8 12 1d 00 00       	call   1a220 <cwrites>
   1850e:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18511:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   18518:	eb 5b                	jmp    18575 <progJ+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   1851a:	8b 45 08             	mov    0x8(%ebp),%eax
   1851d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18524:	8b 45 0c             	mov    0xc(%ebp),%eax
   18527:	01 d0                	add    %edx,%eax
   18529:	8b 00                	mov    (%eax),%eax
   1852b:	85 c0                	test   %eax,%eax
   1852d:	74 13                	je     18542 <progJ+0xc2>
   1852f:	8b 45 08             	mov    0x8(%ebp),%eax
   18532:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18539:	8b 45 0c             	mov    0xc(%ebp),%eax
   1853c:	01 d0                	add    %edx,%eax
   1853e:	8b 00                	mov    (%eax),%eax
   18540:	eb 05                	jmp    18547 <progJ+0xc7>
   18542:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   18547:	83 ec 04             	sub    $0x4,%esp
   1854a:	50                   	push   %eax
   1854b:	68 2c bc 01 00       	push   $0x1bc2c
   18550:	8d 85 63 ff ff ff    	lea    -0x9d(%ebp),%eax
   18556:	50                   	push   %eax
   18557:	e8 d7 15 00 00       	call   19b33 <usprint>
   1855c:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1855f:	83 ec 0c             	sub    $0xc,%esp
   18562:	8d 85 63 ff ff ff    	lea    -0x9d(%ebp),%eax
   18568:	50                   	push   %eax
   18569:	e8 b2 1c 00 00       	call   1a220 <cwrites>
   1856e:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18571:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   18575:	8b 45 f0             	mov    -0x10(%ebp),%eax
   18578:	3b 45 08             	cmp    0x8(%ebp),%eax
   1857b:	7e 9d                	jle    1851a <progJ+0x9a>
			}
			cwrites( "\n" );
   1857d:	83 ec 0c             	sub    $0xc,%esp
   18580:	68 30 bc 01 00       	push   $0x1bc30
   18585:	e8 96 1c 00 00       	call   1a220 <cwrites>
   1858a:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   1858d:	83 ec 04             	sub    $0x4,%esp
   18590:	6a 01                	push   $0x1
   18592:	8d 45 e3             	lea    -0x1d(%ebp),%eax
   18595:	50                   	push   %eax
   18596:	6a 01                	push   $0x1
   18598:	e8 14 e8 ff ff       	call   16db1 <write>
   1859d:	83 c4 10             	add    $0x10,%esp

	// set up the command-line arguments
	char *argsy[] = { "progY", "Y", "10", NULL };
   185a0:	c7 85 50 ff ff ff 40 	movl   $0x1bd40,-0xb0(%ebp)
   185a7:	bd 01 00 
   185aa:	c7 85 54 ff ff ff 46 	movl   $0x1bd46,-0xac(%ebp)
   185b1:	bd 01 00 
   185b4:	c7 85 58 ff ff ff 84 	movl   $0x1b984,-0xa8(%ebp)
   185bb:	b9 01 00 
   185be:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
   185c5:	00 00 00 

	for( int i = 0; i < count ; ++i ) {
   185c8:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   185cf:	eb 4e                	jmp    1861f <progJ+0x19f>
		int whom = spawn( (uint32_t) progY, argsy );
   185d1:	ba 3b 86 01 00       	mov    $0x1863b,%edx
   185d6:	83 ec 08             	sub    $0x8,%esp
   185d9:	8d 85 50 ff ff ff    	lea    -0xb0(%ebp),%eax
   185df:	50                   	push   %eax
   185e0:	52                   	push   %edx
   185e1:	e8 a4 1b 00 00       	call   1a18a <spawn>
   185e6:	83 c4 10             	add    $0x10,%esp
   185e9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		if( whom < 0 ) {
   185ec:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
   185f0:	79 16                	jns    18608 <progJ+0x188>
			write( CHAN_SIO, "!j!", 3 );
   185f2:	83 ec 04             	sub    $0x4,%esp
   185f5:	6a 03                	push   $0x3
   185f7:	68 48 bd 01 00       	push   $0x1bd48
   185fc:	6a 01                	push   $0x1
   185fe:	e8 ae e7 ff ff       	call   16db1 <write>
   18603:	83 c4 10             	add    $0x10,%esp
   18606:	eb 13                	jmp    1861b <progJ+0x19b>
		} else {
			write( CHAN_SIO, &ch, 1 );
   18608:	83 ec 04             	sub    $0x4,%esp
   1860b:	6a 01                	push   $0x1
   1860d:	8d 45 e3             	lea    -0x1d(%ebp),%eax
   18610:	50                   	push   %eax
   18611:	6a 01                	push   $0x1
   18613:	e8 99 e7 ff ff       	call   16db1 <write>
   18618:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   1861b:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   1861f:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18622:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18625:	7c aa                	jl     185d1 <progJ+0x151>
		}
	}

	exit( 0 );
   18627:	83 ec 0c             	sub    $0xc,%esp
   1862a:	6a 00                	push   $0x0
   1862c:	e8 58 e7 ff ff       	call   16d89 <exit>
   18631:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18634:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   18639:	c9                   	leave  
   1863a:	c3                   	ret    

0001863b <progY>:
** Invoked as:	progY  x  [ n ]
**	 where x is the ID character
**		   n is the iteration count (defaults to 10)
*/

USERMAIN( progY ) {
   1863b:	55                   	push   %ebp
   1863c:	89 e5                	mov    %esp,%ebp
   1863e:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18644:	8b 45 0c             	mov    0xc(%ebp),%eax
   18647:	8b 00                	mov    (%eax),%eax
   18649:	85 c0                	test   %eax,%eax
   1864b:	74 07                	je     18654 <progY+0x19>
   1864d:	8b 45 0c             	mov    0xc(%ebp),%eax
   18650:	8b 00                	mov    (%eax),%eax
   18652:	eb 05                	jmp    18659 <progY+0x1e>
   18654:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   18659:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 10;	  // default iteration count
   1865c:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
	char ch = 'y';	  // default character to print
   18663:	c6 45 f3 79          	movb   $0x79,-0xd(%ebp)
	char buf[128];

	(void) name;

	// process the command-line arguments
	switch( argc ) {
   18667:	8b 45 08             	mov    0x8(%ebp),%eax
   1866a:	83 f8 02             	cmp    $0x2,%eax
   1866d:	74 1e                	je     1868d <progY+0x52>
   1866f:	83 f8 03             	cmp    $0x3,%eax
   18672:	75 2c                	jne    186a0 <progY+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   18674:	8b 45 0c             	mov    0xc(%ebp),%eax
   18677:	83 c0 08             	add    $0x8,%eax
   1867a:	8b 00                	mov    (%eax),%eax
   1867c:	83 ec 08             	sub    $0x8,%esp
   1867f:	6a 0a                	push   $0xa
   18681:	50                   	push   %eax
   18682:	e8 21 17 00 00       	call   19da8 <ustr2int>
   18687:	83 c4 10             	add    $0x10,%esp
   1868a:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   1868d:	8b 45 0c             	mov    0xc(%ebp),%eax
   18690:	83 c0 04             	add    $0x4,%eax
   18693:	8b 00                	mov    (%eax),%eax
   18695:	0f b6 00             	movzbl (%eax),%eax
   18698:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   1869b:	e9 a8 00 00 00       	jmp    18748 <progY+0x10d>
	default:
			usprint( buf, "?: argc %d, args: ", argc );
   186a0:	83 ec 04             	sub    $0x4,%esp
   186a3:	ff 75 08             	pushl  0x8(%ebp)
   186a6:	68 d7 bc 01 00       	push   $0x1bcd7
   186ab:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   186b1:	50                   	push   %eax
   186b2:	e8 7c 14 00 00       	call   19b33 <usprint>
   186b7:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   186ba:	83 ec 0c             	sub    $0xc,%esp
   186bd:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   186c3:	50                   	push   %eax
   186c4:	e8 57 1b 00 00       	call   1a220 <cwrites>
   186c9:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   186cc:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   186d3:	eb 5b                	jmp    18730 <progY+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   186d5:	8b 45 08             	mov    0x8(%ebp),%eax
   186d8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   186df:	8b 45 0c             	mov    0xc(%ebp),%eax
   186e2:	01 d0                	add    %edx,%eax
   186e4:	8b 00                	mov    (%eax),%eax
   186e6:	85 c0                	test   %eax,%eax
   186e8:	74 13                	je     186fd <progY+0xc2>
   186ea:	8b 45 08             	mov    0x8(%ebp),%eax
   186ed:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   186f4:	8b 45 0c             	mov    0xc(%ebp),%eax
   186f7:	01 d0                	add    %edx,%eax
   186f9:	8b 00                	mov    (%eax),%eax
   186fb:	eb 05                	jmp    18702 <progY+0xc7>
   186fd:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   18702:	83 ec 04             	sub    $0x4,%esp
   18705:	50                   	push   %eax
   18706:	68 2c bc 01 00       	push   $0x1bc2c
   1870b:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18711:	50                   	push   %eax
   18712:	e8 1c 14 00 00       	call   19b33 <usprint>
   18717:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1871a:	83 ec 0c             	sub    $0xc,%esp
   1871d:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18723:	50                   	push   %eax
   18724:	e8 f7 1a 00 00       	call   1a220 <cwrites>
   18729:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1872c:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18730:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18733:	3b 45 08             	cmp    0x8(%ebp),%eax
   18736:	7e 9d                	jle    186d5 <progY+0x9a>
			}
			cwrites( "\n" );
   18738:	83 ec 0c             	sub    $0xc,%esp
   1873b:	68 30 bc 01 00       	push   $0x1bc30
   18740:	e8 db 1a 00 00       	call   1a220 <cwrites>
   18745:	83 c4 10             	add    $0x10,%esp
	}

	// report our presence
	int pid = getpid();
   18748:	e8 6c e6 ff ff       	call   16db9 <getpid>
   1874d:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d]", ch, pid );
   18750:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   18754:	ff 75 dc             	pushl  -0x24(%ebp)
   18757:	50                   	push   %eax
   18758:	68 ea bc 01 00       	push   $0x1bcea
   1875d:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18763:	50                   	push   %eax
   18764:	e8 ca 13 00 00       	call   19b33 <usprint>
   18769:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   1876c:	83 ec 0c             	sub    $0xc,%esp
   1876f:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18775:	50                   	push   %eax
   18776:	e8 0b 1b 00 00       	call   1a286 <swrites>
   1877b:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   1877e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18785:	eb 3c                	jmp    187c3 <progY+0x188>
		swrites( buf );
   18787:	83 ec 0c             	sub    $0xc,%esp
   1878a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18790:	50                   	push   %eax
   18791:	e8 f0 1a 00 00       	call   1a286 <swrites>
   18796:	83 c4 10             	add    $0x10,%esp
		DELAY(STD);
   18799:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   187a0:	eb 04                	jmp    187a6 <progY+0x16b>
   187a2:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   187a6:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   187ad:	7e f3                	jle    187a2 <progY+0x167>
		sleep( SEC_TO_MS(1) );
   187af:	83 ec 0c             	sub    $0xc,%esp
   187b2:	68 e8 03 00 00       	push   $0x3e8
   187b7:	e8 2d e6 ff ff       	call   16de9 <sleep>
   187bc:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   187bf:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   187c3:	8b 45 e8             	mov    -0x18(%ebp),%eax
   187c6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   187c9:	7c bc                	jl     18787 <progY+0x14c>
	}

	exit( 0 );
   187cb:	83 ec 0c             	sub    $0xc,%esp
   187ce:	6a 00                	push   $0x0
   187d0:	e8 b4 e5 ff ff       	call   16d89 <exit>
   187d5:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   187d8:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   187dd:	c9                   	leave  
   187de:	c3                   	ret    

000187df <progKL>:
** Invoked as:  progKL  x  n
**	 where x is the ID character
**		   n is the iteration count (defaults to 5)
*/

USERMAIN( progKL ) {
   187df:	55                   	push   %ebp
   187e0:	89 e5                	mov    %esp,%ebp
   187e2:	83 ec 58             	sub    $0x58,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   187e5:	8b 45 0c             	mov    0xc(%ebp),%eax
   187e8:	8b 00                	mov    (%eax),%eax
   187ea:	85 c0                	test   %eax,%eax
   187ec:	74 07                	je     187f5 <progKL+0x16>
   187ee:	8b 45 0c             	mov    0xc(%ebp),%eax
   187f1:	8b 00                	mov    (%eax),%eax
   187f3:	eb 05                	jmp    187fa <progKL+0x1b>
   187f5:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   187fa:	89 45 e8             	mov    %eax,-0x18(%ebp)
	int count = 5;			// default iteration count
   187fd:	c7 45 f4 05 00 00 00 	movl   $0x5,-0xc(%ebp)
	char ch = '4';			// default character to print
   18804:	c6 45 df 34          	movb   $0x34,-0x21(%ebp)
	int nap = 30;			// nap time
   18808:	c7 45 e4 1e 00 00 00 	movl   $0x1e,-0x1c(%ebp)
	char msg2[] = "*4*";	// "error" message to print
   1880f:	c7 45 db 2a 34 2a 00 	movl   $0x2a342a,-0x25(%ebp)
	char buf[32];

	// process the command-line arguments
	switch( argc ) {
   18816:	8b 45 08             	mov    0x8(%ebp),%eax
   18819:	83 f8 02             	cmp    $0x2,%eax
   1881c:	74 1e                	je     1883c <progKL+0x5d>
   1881e:	83 f8 03             	cmp    $0x3,%eax
   18821:	75 2c                	jne    1884f <progKL+0x70>
	case 3:	count = ustr2int( argv[2], 10 );
   18823:	8b 45 0c             	mov    0xc(%ebp),%eax
   18826:	83 c0 08             	add    $0x8,%eax
   18829:	8b 00                	mov    (%eax),%eax
   1882b:	83 ec 08             	sub    $0x8,%esp
   1882e:	6a 0a                	push   $0xa
   18830:	50                   	push   %eax
   18831:	e8 72 15 00 00       	call   19da8 <ustr2int>
   18836:	83 c4 10             	add    $0x10,%esp
   18839:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   1883c:	8b 45 0c             	mov    0xc(%ebp),%eax
   1883f:	83 c0 04             	add    $0x4,%eax
   18842:	8b 00                	mov    (%eax),%eax
   18844:	0f b6 00             	movzbl (%eax),%eax
   18847:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   1884a:	e9 9c 00 00 00       	jmp    188eb <progKL+0x10c>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   1884f:	ff 75 08             	pushl  0x8(%ebp)
   18852:	ff 75 e8             	pushl  -0x18(%ebp)
   18855:	68 11 bc 01 00       	push   $0x1bc11
   1885a:	8d 45 bb             	lea    -0x45(%ebp),%eax
   1885d:	50                   	push   %eax
   1885e:	e8 d0 12 00 00       	call   19b33 <usprint>
   18863:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18866:	83 ec 0c             	sub    $0xc,%esp
   18869:	8d 45 bb             	lea    -0x45(%ebp),%eax
   1886c:	50                   	push   %eax
   1886d:	e8 ae 19 00 00       	call   1a220 <cwrites>
   18872:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18875:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   1887c:	eb 55                	jmp    188d3 <progKL+0xf4>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   1887e:	8b 45 08             	mov    0x8(%ebp),%eax
   18881:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18888:	8b 45 0c             	mov    0xc(%ebp),%eax
   1888b:	01 d0                	add    %edx,%eax
   1888d:	8b 00                	mov    (%eax),%eax
   1888f:	85 c0                	test   %eax,%eax
   18891:	74 13                	je     188a6 <progKL+0xc7>
   18893:	8b 45 08             	mov    0x8(%ebp),%eax
   18896:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   1889d:	8b 45 0c             	mov    0xc(%ebp),%eax
   188a0:	01 d0                	add    %edx,%eax
   188a2:	8b 00                	mov    (%eax),%eax
   188a4:	eb 05                	jmp    188ab <progKL+0xcc>
   188a6:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   188ab:	83 ec 04             	sub    $0x4,%esp
   188ae:	50                   	push   %eax
   188af:	68 2c bc 01 00       	push   $0x1bc2c
   188b4:	8d 45 bb             	lea    -0x45(%ebp),%eax
   188b7:	50                   	push   %eax
   188b8:	e8 76 12 00 00       	call   19b33 <usprint>
   188bd:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   188c0:	83 ec 0c             	sub    $0xc,%esp
   188c3:	8d 45 bb             	lea    -0x45(%ebp),%eax
   188c6:	50                   	push   %eax
   188c7:	e8 54 19 00 00       	call   1a220 <cwrites>
   188cc:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   188cf:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   188d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
   188d6:	3b 45 08             	cmp    0x8(%ebp),%eax
   188d9:	7e a3                	jle    1887e <progKL+0x9f>
			}
			cwrites( "\n" );
   188db:	83 ec 0c             	sub    $0xc,%esp
   188de:	68 30 bc 01 00       	push   $0x1bc30
   188e3:	e8 38 19 00 00       	call   1a220 <cwrites>
   188e8:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   188eb:	83 ec 04             	sub    $0x4,%esp
   188ee:	6a 01                	push   $0x1
   188f0:	8d 45 df             	lea    -0x21(%ebp),%eax
   188f3:	50                   	push   %eax
   188f4:	6a 01                	push   $0x1
   188f6:	e8 b6 e4 ff ff       	call   16db1 <write>
   188fb:	83 c4 10             	add    $0x10,%esp

	// argument vector for the processes we will spawn
	char *arglist[] = { "progX", "X", buf, NULL };
   188fe:	c7 45 a8 4c bd 01 00 	movl   $0x1bd4c,-0x58(%ebp)
   18905:	c7 45 ac 52 bd 01 00 	movl   $0x1bd52,-0x54(%ebp)
   1890c:	8d 45 bb             	lea    -0x45(%ebp),%eax
   1890f:	89 45 b0             	mov    %eax,-0x50(%ebp)
   18912:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)

	for( int i = 0; i < count ; ++i ) {
   18919:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18920:	e9 89 00 00 00       	jmp    189ae <progKL+0x1cf>

		write( CHAN_SIO, &ch, 1 );
   18925:	83 ec 04             	sub    $0x4,%esp
   18928:	6a 01                	push   $0x1
   1892a:	8d 45 df             	lea    -0x21(%ebp),%eax
   1892d:	50                   	push   %eax
   1892e:	6a 01                	push   $0x1
   18930:	e8 7c e4 ff ff       	call   16db1 <write>
   18935:	83 c4 10             	add    $0x10,%esp

		// second argument to X is 100 plus the iteration number
		usprint( buf, "%d", 100 + i );
   18938:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1893b:	83 c0 64             	add    $0x64,%eax
   1893e:	83 ec 04             	sub    $0x4,%esp
   18941:	50                   	push   %eax
   18942:	68 54 bd 01 00       	push   $0x1bd54
   18947:	8d 45 bb             	lea    -0x45(%ebp),%eax
   1894a:	50                   	push   %eax
   1894b:	e8 e3 11 00 00       	call   19b33 <usprint>
   18950:	83 c4 10             	add    $0x10,%esp
		int whom = spawn( (uint32_t) progX, arglist );
   18953:	ba ce 89 01 00       	mov    $0x189ce,%edx
   18958:	83 ec 08             	sub    $0x8,%esp
   1895b:	8d 45 a8             	lea    -0x58(%ebp),%eax
   1895e:	50                   	push   %eax
   1895f:	52                   	push   %edx
   18960:	e8 25 18 00 00       	call   1a18a <spawn>
   18965:	83 c4 10             	add    $0x10,%esp
   18968:	89 45 e0             	mov    %eax,-0x20(%ebp)
		if( whom < 0 ) {
   1896b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   1896f:	79 11                	jns    18982 <progKL+0x1a3>
			swrites( msg2 );
   18971:	83 ec 0c             	sub    $0xc,%esp
   18974:	8d 45 db             	lea    -0x25(%ebp),%eax
   18977:	50                   	push   %eax
   18978:	e8 09 19 00 00       	call   1a286 <swrites>
   1897d:	83 c4 10             	add    $0x10,%esp
   18980:	eb 13                	jmp    18995 <progKL+0x1b6>
		} else {
			write( CHAN_SIO, &ch, 1 );
   18982:	83 ec 04             	sub    $0x4,%esp
   18985:	6a 01                	push   $0x1
   18987:	8d 45 df             	lea    -0x21(%ebp),%eax
   1898a:	50                   	push   %eax
   1898b:	6a 01                	push   $0x1
   1898d:	e8 1f e4 ff ff       	call   16db1 <write>
   18992:	83 c4 10             	add    $0x10,%esp
		}

		sleep( SEC_TO_MS(nap) );
   18995:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   18998:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   1899e:	83 ec 0c             	sub    $0xc,%esp
   189a1:	50                   	push   %eax
   189a2:	e8 42 e4 ff ff       	call   16de9 <sleep>
   189a7:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count ; ++i ) {
   189aa:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   189ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
   189b1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   189b4:	0f 8c 6b ff ff ff    	jl     18925 <progKL+0x146>
	}

	exit( 0 );
   189ba:	83 ec 0c             	sub    $0xc,%esp
   189bd:	6a 00                	push   $0x0
   189bf:	e8 c5 e3 ff ff       	call   16d89 <exit>
   189c4:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   189c7:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   189cc:	c9                   	leave  
   189cd:	c3                   	ret    

000189ce <progX>:
** Invoked as:  progX  x  n
**	 where x is the ID character
**		   n is the iteration count
*/

USERMAIN( progX ) {
   189ce:	55                   	push   %ebp
   189cf:	89 e5                	mov    %esp,%ebp
   189d1:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   189d7:	8b 45 0c             	mov    0xc(%ebp),%eax
   189da:	8b 00                	mov    (%eax),%eax
   189dc:	85 c0                	test   %eax,%eax
   189de:	74 07                	je     189e7 <progX+0x19>
   189e0:	8b 45 0c             	mov    0xc(%ebp),%eax
   189e3:	8b 00                	mov    (%eax),%eax
   189e5:	eb 05                	jmp    189ec <progX+0x1e>
   189e7:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   189ec:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int count = 20;	  // iteration count
   189ef:	c7 45 f4 14 00 00 00 	movl   $0x14,-0xc(%ebp)
	char ch = 'x';	  // default character to print
   189f6:	c6 45 f3 78          	movb   $0x78,-0xd(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   189fa:	8b 45 08             	mov    0x8(%ebp),%eax
   189fd:	83 f8 02             	cmp    $0x2,%eax
   18a00:	74 1e                	je     18a20 <progX+0x52>
   18a02:	83 f8 03             	cmp    $0x3,%eax
   18a05:	75 2c                	jne    18a33 <progX+0x65>
	case 3:	count = ustr2int( argv[2], 10 );
   18a07:	8b 45 0c             	mov    0xc(%ebp),%eax
   18a0a:	83 c0 08             	add    $0x8,%eax
   18a0d:	8b 00                	mov    (%eax),%eax
   18a0f:	83 ec 08             	sub    $0x8,%esp
   18a12:	6a 0a                	push   $0xa
   18a14:	50                   	push   %eax
   18a15:	e8 8e 13 00 00       	call   19da8 <ustr2int>
   18a1a:	83 c4 10             	add    $0x10,%esp
   18a1d:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18a20:	8b 45 0c             	mov    0xc(%ebp),%eax
   18a23:	83 c0 04             	add    $0x4,%eax
   18a26:	8b 00                	mov    (%eax),%eax
   18a28:	0f b6 00             	movzbl (%eax),%eax
   18a2b:	88 45 f3             	mov    %al,-0xd(%ebp)
			break;
   18a2e:	e9 a8 00 00 00       	jmp    18adb <progX+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18a33:	ff 75 08             	pushl  0x8(%ebp)
   18a36:	ff 75 e0             	pushl  -0x20(%ebp)
   18a39:	68 11 bc 01 00       	push   $0x1bc11
   18a3e:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18a44:	50                   	push   %eax
   18a45:	e8 e9 10 00 00       	call   19b33 <usprint>
   18a4a:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18a4d:	83 ec 0c             	sub    $0xc,%esp
   18a50:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18a56:	50                   	push   %eax
   18a57:	e8 c4 17 00 00       	call   1a220 <cwrites>
   18a5c:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18a5f:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18a66:	eb 5b                	jmp    18ac3 <progX+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18a68:	8b 45 08             	mov    0x8(%ebp),%eax
   18a6b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18a72:	8b 45 0c             	mov    0xc(%ebp),%eax
   18a75:	01 d0                	add    %edx,%eax
   18a77:	8b 00                	mov    (%eax),%eax
   18a79:	85 c0                	test   %eax,%eax
   18a7b:	74 13                	je     18a90 <progX+0xc2>
   18a7d:	8b 45 08             	mov    0x8(%ebp),%eax
   18a80:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18a87:	8b 45 0c             	mov    0xc(%ebp),%eax
   18a8a:	01 d0                	add    %edx,%eax
   18a8c:	8b 00                	mov    (%eax),%eax
   18a8e:	eb 05                	jmp    18a95 <progX+0xc7>
   18a90:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   18a95:	83 ec 04             	sub    $0x4,%esp
   18a98:	50                   	push   %eax
   18a99:	68 2c bc 01 00       	push   $0x1bc2c
   18a9e:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18aa4:	50                   	push   %eax
   18aa5:	e8 89 10 00 00       	call   19b33 <usprint>
   18aaa:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   18aad:	83 ec 0c             	sub    $0xc,%esp
   18ab0:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18ab6:	50                   	push   %eax
   18ab7:	e8 64 17 00 00       	call   1a220 <cwrites>
   18abc:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18abf:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18ac3:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18ac6:	3b 45 08             	cmp    0x8(%ebp),%eax
   18ac9:	7e 9d                	jle    18a68 <progX+0x9a>
			}
			cwrites( "\n" );
   18acb:	83 ec 0c             	sub    $0xc,%esp
   18ace:	68 30 bc 01 00       	push   $0x1bc30
   18ad3:	e8 48 17 00 00       	call   1a220 <cwrites>
   18ad8:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	int pid = getpid();
   18adb:	e8 d9 e2 ff ff       	call   16db9 <getpid>
   18ae0:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d]", ch, pid );
   18ae3:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   18ae7:	ff 75 dc             	pushl  -0x24(%ebp)
   18aea:	50                   	push   %eax
   18aeb:	68 ea bc 01 00       	push   $0x1bcea
   18af0:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18af6:	50                   	push   %eax
   18af7:	e8 37 10 00 00       	call   19b33 <usprint>
   18afc:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   18aff:	83 ec 0c             	sub    $0xc,%esp
   18b02:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18b08:	50                   	push   %eax
   18b09:	e8 78 17 00 00       	call   1a286 <swrites>
   18b0e:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count ; ++i ) {
   18b11:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18b18:	eb 2c                	jmp    18b46 <progX+0x178>
		swrites( buf );
   18b1a:	83 ec 0c             	sub    $0xc,%esp
   18b1d:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
   18b23:	50                   	push   %eax
   18b24:	e8 5d 17 00 00       	call   1a286 <swrites>
   18b29:	83 c4 10             	add    $0x10,%esp
		DELAY(STD);
   18b2c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   18b33:	eb 04                	jmp    18b39 <progX+0x16b>
   18b35:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   18b39:	81 7d e4 9f 25 26 00 	cmpl   $0x26259f,-0x1c(%ebp)
   18b40:	7e f3                	jle    18b35 <progX+0x167>
	for( int i = 0; i < count ; ++i ) {
   18b42:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18b46:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18b49:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18b4c:	7c cc                	jl     18b1a <progX+0x14c>
	}

	exit( 12 );
   18b4e:	83 ec 0c             	sub    $0xc,%esp
   18b51:	6a 0c                	push   $0xc
   18b53:	e8 31 e2 ff ff       	call   16d89 <exit>
   18b58:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18b5b:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   18b60:	c9                   	leave  
   18b61:	c3                   	ret    

00018b62 <progMN>:
**	 where x is the ID character
**		   n is the iteration count
**		   b is the w&z boolean
*/

USERMAIN( progMN ) {
   18b62:	55                   	push   %ebp
   18b63:	89 e5                	mov    %esp,%ebp
   18b65:	81 ec d8 00 00 00    	sub    $0xd8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18b6b:	8b 45 0c             	mov    0xc(%ebp),%eax
   18b6e:	8b 00                	mov    (%eax),%eax
   18b70:	85 c0                	test   %eax,%eax
   18b72:	74 07                	je     18b7b <progMN+0x19>
   18b74:	8b 45 0c             	mov    0xc(%ebp),%eax
   18b77:	8b 00                	mov    (%eax),%eax
   18b79:	eb 05                	jmp    18b80 <progMN+0x1e>
   18b7b:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   18b80:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int count = 5;	// default iteration count
   18b83:	c7 45 f4 05 00 00 00 	movl   $0x5,-0xc(%ebp)
	char ch = '5';	// default character to print
   18b8a:	c6 45 df 35          	movb   $0x35,-0x21(%ebp)
	int alsoZ = 0;	// also do progZ?
   18b8e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	char msgw[] = "*5w*";
   18b95:	c7 45 da 2a 35 77 2a 	movl   $0x2a77352a,-0x26(%ebp)
   18b9c:	c6 45 de 00          	movb   $0x0,-0x22(%ebp)
	char msgz[] = "*5z*";
   18ba0:	c7 45 d5 2a 35 7a 2a 	movl   $0x2a7a352a,-0x2b(%ebp)
   18ba7:	c6 45 d9 00          	movb   $0x0,-0x27(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   18bab:	8b 45 08             	mov    0x8(%ebp),%eax
   18bae:	83 f8 03             	cmp    $0x3,%eax
   18bb1:	74 22                	je     18bd5 <progMN+0x73>
   18bb3:	83 f8 04             	cmp    $0x4,%eax
   18bb6:	74 07                	je     18bbf <progMN+0x5d>
   18bb8:	83 f8 02             	cmp    $0x2,%eax
   18bbb:	74 31                	je     18bee <progMN+0x8c>
   18bbd:	eb 42                	jmp    18c01 <progMN+0x9f>
	case 4:	alsoZ = argv[3][0] == 't';
   18bbf:	8b 45 0c             	mov    0xc(%ebp),%eax
   18bc2:	83 c0 0c             	add    $0xc,%eax
   18bc5:	8b 00                	mov    (%eax),%eax
   18bc7:	0f b6 00             	movzbl (%eax),%eax
   18bca:	3c 74                	cmp    $0x74,%al
   18bcc:	0f 94 c0             	sete   %al
   18bcf:	0f b6 c0             	movzbl %al,%eax
   18bd2:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   18bd5:	8b 45 0c             	mov    0xc(%ebp),%eax
   18bd8:	83 c0 08             	add    $0x8,%eax
   18bdb:	8b 00                	mov    (%eax),%eax
   18bdd:	83 ec 08             	sub    $0x8,%esp
   18be0:	6a 0a                	push   $0xa
   18be2:	50                   	push   %eax
   18be3:	e8 c0 11 00 00       	call   19da8 <ustr2int>
   18be8:	83 c4 10             	add    $0x10,%esp
   18beb:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18bee:	8b 45 0c             	mov    0xc(%ebp),%eax
   18bf1:	83 c0 04             	add    $0x4,%eax
   18bf4:	8b 00                	mov    (%eax),%eax
   18bf6:	0f b6 00             	movzbl (%eax),%eax
   18bf9:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   18bfc:	e9 a8 00 00 00       	jmp    18ca9 <progMN+0x147>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18c01:	ff 75 08             	pushl  0x8(%ebp)
   18c04:	ff 75 e4             	pushl  -0x1c(%ebp)
   18c07:	68 11 bc 01 00       	push   $0x1bc11
   18c0c:	8d 85 55 ff ff ff    	lea    -0xab(%ebp),%eax
   18c12:	50                   	push   %eax
   18c13:	e8 1b 0f 00 00       	call   19b33 <usprint>
   18c18:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18c1b:	83 ec 0c             	sub    $0xc,%esp
   18c1e:	8d 85 55 ff ff ff    	lea    -0xab(%ebp),%eax
   18c24:	50                   	push   %eax
   18c25:	e8 f6 15 00 00       	call   1a220 <cwrites>
   18c2a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18c2d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18c34:	eb 5b                	jmp    18c91 <progMN+0x12f>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18c36:	8b 45 08             	mov    0x8(%ebp),%eax
   18c39:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18c40:	8b 45 0c             	mov    0xc(%ebp),%eax
   18c43:	01 d0                	add    %edx,%eax
   18c45:	8b 00                	mov    (%eax),%eax
   18c47:	85 c0                	test   %eax,%eax
   18c49:	74 13                	je     18c5e <progMN+0xfc>
   18c4b:	8b 45 08             	mov    0x8(%ebp),%eax
   18c4e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18c55:	8b 45 0c             	mov    0xc(%ebp),%eax
   18c58:	01 d0                	add    %edx,%eax
   18c5a:	8b 00                	mov    (%eax),%eax
   18c5c:	eb 05                	jmp    18c63 <progMN+0x101>
   18c5e:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   18c63:	83 ec 04             	sub    $0x4,%esp
   18c66:	50                   	push   %eax
   18c67:	68 2c bc 01 00       	push   $0x1bc2c
   18c6c:	8d 85 55 ff ff ff    	lea    -0xab(%ebp),%eax
   18c72:	50                   	push   %eax
   18c73:	e8 bb 0e 00 00       	call   19b33 <usprint>
   18c78:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   18c7b:	83 ec 0c             	sub    $0xc,%esp
   18c7e:	8d 85 55 ff ff ff    	lea    -0xab(%ebp),%eax
   18c84:	50                   	push   %eax
   18c85:	e8 96 15 00 00       	call   1a220 <cwrites>
   18c8a:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18c8d:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18c91:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18c94:	3b 45 08             	cmp    0x8(%ebp),%eax
   18c97:	7e 9d                	jle    18c36 <progMN+0xd4>
			}
			cwrites( "\n" );
   18c99:	83 ec 0c             	sub    $0xc,%esp
   18c9c:	68 30 bc 01 00       	push   $0x1bc30
   18ca1:	e8 7a 15 00 00       	call   1a220 <cwrites>
   18ca6:	83 c4 10             	add    $0x10,%esp
	}

	// update the extra message strings
	msgw[1] = msgz[1] = ch;
   18ca9:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
   18cad:	88 45 d6             	mov    %al,-0x2a(%ebp)
   18cb0:	0f b6 45 d6          	movzbl -0x2a(%ebp),%eax
   18cb4:	88 45 db             	mov    %al,-0x25(%ebp)

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   18cb7:	83 ec 04             	sub    $0x4,%esp
   18cba:	6a 01                	push   $0x1
   18cbc:	8d 45 df             	lea    -0x21(%ebp),%eax
   18cbf:	50                   	push   %eax
   18cc0:	6a 01                	push   $0x1
   18cc2:	e8 ea e0 ff ff       	call   16db1 <write>
   18cc7:	83 c4 10             	add    $0x10,%esp

	// set up the argument vector(s)

	// W:  15 iterations, 5-second sleep
	char *argsw[] = { "progW", "W", "15", "5", NULL };
   18cca:	c7 85 40 ff ff ff f2 	movl   $0x1bcf2,-0xc0(%ebp)
   18cd1:	bc 01 00 
   18cd4:	c7 85 44 ff ff ff 06 	movl   $0x1ba06,-0xbc(%ebp)
   18cdb:	ba 01 00 
   18cde:	c7 85 48 ff ff ff 57 	movl   $0x1bd57,-0xb8(%ebp)
   18ce5:	bd 01 00 
   18ce8:	c7 85 4c ff ff ff b3 	movl   $0x1b9b3,-0xb4(%ebp)
   18cef:	b9 01 00 
   18cf2:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
   18cf9:	00 00 00 

	// Z:  15 iterations
	char *argsz[] = { "progZ", "Z", "15", NULL };
   18cfc:	c7 85 30 ff ff ff a9 	movl   $0x1bca9,-0xd0(%ebp)
   18d03:	bc 01 00 
   18d06:	c7 85 34 ff ff ff af 	movl   $0x1bcaf,-0xcc(%ebp)
   18d0d:	bc 01 00 
   18d10:	c7 85 38 ff ff ff 57 	movl   $0x1bd57,-0xc8(%ebp)
   18d17:	bd 01 00 
   18d1a:	c7 85 3c ff ff ff 00 	movl   $0x0,-0xc4(%ebp)
   18d21:	00 00 00 

	for( int i = 0; i < count; ++i ) {
   18d24:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18d2b:	eb 7d                	jmp    18daa <progMN+0x248>
		write( CHAN_SIO, &ch, 1 );
   18d2d:	83 ec 04             	sub    $0x4,%esp
   18d30:	6a 01                	push   $0x1
   18d32:	8d 45 df             	lea    -0x21(%ebp),%eax
   18d35:	50                   	push   %eax
   18d36:	6a 01                	push   $0x1
   18d38:	e8 74 e0 ff ff       	call   16db1 <write>
   18d3d:	83 c4 10             	add    $0x10,%esp
		int whom = spawn( (uint32_t) progW, argsw	);
   18d40:	ba 75 82 01 00       	mov    $0x18275,%edx
   18d45:	83 ec 08             	sub    $0x8,%esp
   18d48:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
   18d4e:	50                   	push   %eax
   18d4f:	52                   	push   %edx
   18d50:	e8 35 14 00 00       	call   1a18a <spawn>
   18d55:	83 c4 10             	add    $0x10,%esp
   18d58:	89 45 e0             	mov    %eax,-0x20(%ebp)
		if( whom < 1 ) {
   18d5b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   18d5f:	7f 0f                	jg     18d70 <progMN+0x20e>
			swrites( msgw );
   18d61:	83 ec 0c             	sub    $0xc,%esp
   18d64:	8d 45 da             	lea    -0x26(%ebp),%eax
   18d67:	50                   	push   %eax
   18d68:	e8 19 15 00 00       	call   1a286 <swrites>
   18d6d:	83 c4 10             	add    $0x10,%esp
		}
		if( alsoZ ) {
   18d70:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   18d74:	74 30                	je     18da6 <progMN+0x244>
			whom = spawn( (uint32_t) progZ, argsz );
   18d76:	ba 3b 7d 01 00       	mov    $0x17d3b,%edx
   18d7b:	83 ec 08             	sub    $0x8,%esp
   18d7e:	8d 85 30 ff ff ff    	lea    -0xd0(%ebp),%eax
   18d84:	50                   	push   %eax
   18d85:	52                   	push   %edx
   18d86:	e8 ff 13 00 00       	call   1a18a <spawn>
   18d8b:	83 c4 10             	add    $0x10,%esp
   18d8e:	89 45 e0             	mov    %eax,-0x20(%ebp)
			if( whom < 1 ) {
   18d91:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
   18d95:	7f 0f                	jg     18da6 <progMN+0x244>
				swrites( msgz );
   18d97:	83 ec 0c             	sub    $0xc,%esp
   18d9a:	8d 45 d5             	lea    -0x2b(%ebp),%eax
   18d9d:	50                   	push   %eax
   18d9e:	e8 e3 14 00 00       	call   1a286 <swrites>
   18da3:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   18da6:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18daa:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18dad:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18db0:	0f 8c 77 ff ff ff    	jl     18d2d <progMN+0x1cb>
			}
		}
	}

	exit( 0 );
   18db6:	83 ec 0c             	sub    $0xc,%esp
   18db9:	6a 00                	push   $0x0
   18dbb:	e8 c9 df ff ff       	call   16d89 <exit>
   18dc0:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18dc3:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   18dc8:	c9                   	leave  
   18dc9:	c3                   	ret    

00018dca <progP>:
**	 where x is the ID character
**		   n is the iteration count (defaults to 3)
**		   t is the sleep time (defaults to 2 seconds)
*/

USERMAIN( progP ) {
   18dca:	55                   	push   %ebp
   18dcb:	89 e5                	mov    %esp,%ebp
   18dcd:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18dd3:	8b 45 0c             	mov    0xc(%ebp),%eax
   18dd6:	8b 00                	mov    (%eax),%eax
   18dd8:	85 c0                	test   %eax,%eax
   18dda:	74 07                	je     18de3 <progP+0x19>
   18ddc:	8b 45 0c             	mov    0xc(%ebp),%eax
   18ddf:	8b 00                	mov    (%eax),%eax
   18de1:	eb 05                	jmp    18de8 <progP+0x1e>
   18de3:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   18de8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int count = 3;	  // default iteration count
   18deb:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
	char ch = 'p';	  // default character to print
   18df2:	c6 45 df 70          	movb   $0x70,-0x21(%ebp)
	int nap = 2;	  // nap time
   18df6:	c7 45 f0 02 00 00 00 	movl   $0x2,-0x10(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   18dfd:	8b 45 08             	mov    0x8(%ebp),%eax
   18e00:	83 f8 03             	cmp    $0x3,%eax
   18e03:	74 25                	je     18e2a <progP+0x60>
   18e05:	83 f8 04             	cmp    $0x4,%eax
   18e08:	74 07                	je     18e11 <progP+0x47>
   18e0a:	83 f8 02             	cmp    $0x2,%eax
   18e0d:	74 34                	je     18e43 <progP+0x79>
   18e0f:	eb 45                	jmp    18e56 <progP+0x8c>
	case 4:	nap = ustr2int( argv[3], 10 );
   18e11:	8b 45 0c             	mov    0xc(%ebp),%eax
   18e14:	83 c0 0c             	add    $0xc,%eax
   18e17:	8b 00                	mov    (%eax),%eax
   18e19:	83 ec 08             	sub    $0x8,%esp
   18e1c:	6a 0a                	push   $0xa
   18e1e:	50                   	push   %eax
   18e1f:	e8 84 0f 00 00       	call   19da8 <ustr2int>
   18e24:	83 c4 10             	add    $0x10,%esp
   18e27:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   18e2a:	8b 45 0c             	mov    0xc(%ebp),%eax
   18e2d:	83 c0 08             	add    $0x8,%eax
   18e30:	8b 00                	mov    (%eax),%eax
   18e32:	83 ec 08             	sub    $0x8,%esp
   18e35:	6a 0a                	push   $0xa
   18e37:	50                   	push   %eax
   18e38:	e8 6b 0f 00 00       	call   19da8 <ustr2int>
   18e3d:	83 c4 10             	add    $0x10,%esp
   18e40:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   18e43:	8b 45 0c             	mov    0xc(%ebp),%eax
   18e46:	83 c0 04             	add    $0x4,%eax
   18e49:	8b 00                	mov    (%eax),%eax
   18e4b:	0f b6 00             	movzbl (%eax),%eax
   18e4e:	88 45 df             	mov    %al,-0x21(%ebp)
			break;
   18e51:	e9 a8 00 00 00       	jmp    18efe <progP+0x134>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18e56:	ff 75 08             	pushl  0x8(%ebp)
   18e59:	ff 75 e4             	pushl  -0x1c(%ebp)
   18e5c:	68 11 bc 01 00       	push   $0x1bc11
   18e61:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   18e67:	50                   	push   %eax
   18e68:	e8 c6 0c 00 00       	call   19b33 <usprint>
   18e6d:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18e70:	83 ec 0c             	sub    $0xc,%esp
   18e73:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   18e79:	50                   	push   %eax
   18e7a:	e8 a1 13 00 00       	call   1a220 <cwrites>
   18e7f:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18e82:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
   18e89:	eb 5b                	jmp    18ee6 <progP+0x11c>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18e8b:	8b 45 08             	mov    0x8(%ebp),%eax
   18e8e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18e95:	8b 45 0c             	mov    0xc(%ebp),%eax
   18e98:	01 d0                	add    %edx,%eax
   18e9a:	8b 00                	mov    (%eax),%eax
   18e9c:	85 c0                	test   %eax,%eax
   18e9e:	74 13                	je     18eb3 <progP+0xe9>
   18ea0:	8b 45 08             	mov    0x8(%ebp),%eax
   18ea3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   18eaa:	8b 45 0c             	mov    0xc(%ebp),%eax
   18ead:	01 d0                	add    %edx,%eax
   18eaf:	8b 00                	mov    (%eax),%eax
   18eb1:	eb 05                	jmp    18eb8 <progP+0xee>
   18eb3:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   18eb8:	83 ec 04             	sub    $0x4,%esp
   18ebb:	50                   	push   %eax
   18ebc:	68 2c bc 01 00       	push   $0x1bc2c
   18ec1:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   18ec7:	50                   	push   %eax
   18ec8:	e8 66 0c 00 00       	call   19b33 <usprint>
   18ecd:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   18ed0:	83 ec 0c             	sub    $0xc,%esp
   18ed3:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   18ed9:	50                   	push   %eax
   18eda:	e8 41 13 00 00       	call   1a220 <cwrites>
   18edf:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18ee2:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
   18ee6:	8b 45 ec             	mov    -0x14(%ebp),%eax
   18ee9:	3b 45 08             	cmp    0x8(%ebp),%eax
   18eec:	7e 9d                	jle    18e8b <progP+0xc1>
			}
			cwrites( "\n" );
   18eee:	83 ec 0c             	sub    $0xc,%esp
   18ef1:	68 30 bc 01 00       	push   $0x1bc30
   18ef6:	e8 25 13 00 00       	call   1a220 <cwrites>
   18efb:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	uint32_t now = gettime();
   18efe:	e8 c6 de ff ff       	call   16dc9 <gettime>
   18f03:	89 45 e0             	mov    %eax,-0x20(%ebp)
	usprint( buf, " P@%u", now );
   18f06:	83 ec 04             	sub    $0x4,%esp
   18f09:	ff 75 e0             	pushl  -0x20(%ebp)
   18f0c:	68 5a bd 01 00       	push   $0x1bd5a
   18f11:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   18f17:	50                   	push   %eax
   18f18:	e8 16 0c 00 00       	call   19b33 <usprint>
   18f1d:	83 c4 10             	add    $0x10,%esp
	swrites( buf );
   18f20:	83 ec 0c             	sub    $0xc,%esp
   18f23:	8d 85 5f ff ff ff    	lea    -0xa1(%ebp),%eax
   18f29:	50                   	push   %eax
   18f2a:	e8 57 13 00 00       	call   1a286 <swrites>
   18f2f:	83 c4 10             	add    $0x10,%esp

	for( int i = 0; i < count; ++i ) {
   18f32:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   18f39:	eb 2c                	jmp    18f67 <progP+0x19d>
		sleep( SEC_TO_MS(nap) );
   18f3b:	8b 45 f0             	mov    -0x10(%ebp),%eax
   18f3e:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   18f44:	83 ec 0c             	sub    $0xc,%esp
   18f47:	50                   	push   %eax
   18f48:	e8 9c de ff ff       	call   16de9 <sleep>
   18f4d:	83 c4 10             	add    $0x10,%esp
		write( CHAN_SIO, &ch, 1 );
   18f50:	83 ec 04             	sub    $0x4,%esp
   18f53:	6a 01                	push   $0x1
   18f55:	8d 45 df             	lea    -0x21(%ebp),%eax
   18f58:	50                   	push   %eax
   18f59:	6a 01                	push   $0x1
   18f5b:	e8 51 de ff ff       	call   16db1 <write>
   18f60:	83 c4 10             	add    $0x10,%esp
	for( int i = 0; i < count; ++i ) {
   18f63:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   18f67:	8b 45 e8             	mov    -0x18(%ebp),%eax
   18f6a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   18f6d:	7c cc                	jl     18f3b <progP+0x171>
	}

	exit( 0 );
   18f6f:	83 ec 0c             	sub    $0xc,%esp
   18f72:	6a 00                	push   $0x0
   18f74:	e8 10 de ff ff       	call   16d89 <exit>
   18f79:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   18f7c:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   18f81:	c9                   	leave  
   18f82:	c3                   	ret    

00018f83 <progQ>:
**
** Invoked as:  progQ  x
**	 where x is the ID character
*/

USERMAIN( progQ ) {
   18f83:	55                   	push   %ebp
   18f84:	89 e5                	mov    %esp,%ebp
   18f86:	81 ec 98 00 00 00    	sub    $0x98,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   18f8c:	8b 45 0c             	mov    0xc(%ebp),%eax
   18f8f:	8b 00                	mov    (%eax),%eax
   18f91:	85 c0                	test   %eax,%eax
   18f93:	74 07                	je     18f9c <progQ+0x19>
   18f95:	8b 45 0c             	mov    0xc(%ebp),%eax
   18f98:	8b 00                	mov    (%eax),%eax
   18f9a:	eb 05                	jmp    18fa1 <progQ+0x1e>
   18f9c:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   18fa1:	89 45 f0             	mov    %eax,-0x10(%ebp)
	char ch = 'q';	  // default character to print
   18fa4:	c6 45 ef 71          	movb   $0x71,-0x11(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   18fa8:	8b 45 08             	mov    0x8(%ebp),%eax
   18fab:	83 f8 02             	cmp    $0x2,%eax
   18fae:	75 13                	jne    18fc3 <progQ+0x40>
	case 2:	ch = argv[1][0];
   18fb0:	8b 45 0c             	mov    0xc(%ebp),%eax
   18fb3:	83 c0 04             	add    $0x4,%eax
   18fb6:	8b 00                	mov    (%eax),%eax
   18fb8:	0f b6 00             	movzbl (%eax),%eax
   18fbb:	88 45 ef             	mov    %al,-0x11(%ebp)
			break;
   18fbe:	e9 a8 00 00 00       	jmp    1906b <progQ+0xe8>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   18fc3:	ff 75 08             	pushl  0x8(%ebp)
   18fc6:	ff 75 f0             	pushl  -0x10(%ebp)
   18fc9:	68 11 bc 01 00       	push   $0x1bc11
   18fce:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   18fd4:	50                   	push   %eax
   18fd5:	e8 59 0b 00 00       	call   19b33 <usprint>
   18fda:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   18fdd:	83 ec 0c             	sub    $0xc,%esp
   18fe0:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   18fe6:	50                   	push   %eax
   18fe7:	e8 34 12 00 00       	call   1a220 <cwrites>
   18fec:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   18fef:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   18ff6:	eb 5b                	jmp    19053 <progQ+0xd0>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   18ff8:	8b 45 08             	mov    0x8(%ebp),%eax
   18ffb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19002:	8b 45 0c             	mov    0xc(%ebp),%eax
   19005:	01 d0                	add    %edx,%eax
   19007:	8b 00                	mov    (%eax),%eax
   19009:	85 c0                	test   %eax,%eax
   1900b:	74 13                	je     19020 <progQ+0x9d>
   1900d:	8b 45 08             	mov    0x8(%ebp),%eax
   19010:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19017:	8b 45 0c             	mov    0xc(%ebp),%eax
   1901a:	01 d0                	add    %edx,%eax
   1901c:	8b 00                	mov    (%eax),%eax
   1901e:	eb 05                	jmp    19025 <progQ+0xa2>
   19020:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   19025:	83 ec 04             	sub    $0x4,%esp
   19028:	50                   	push   %eax
   19029:	68 2c bc 01 00       	push   $0x1bc2c
   1902e:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   19034:	50                   	push   %eax
   19035:	e8 f9 0a 00 00       	call   19b33 <usprint>
   1903a:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   1903d:	83 ec 0c             	sub    $0xc,%esp
   19040:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   19046:	50                   	push   %eax
   19047:	e8 d4 11 00 00       	call   1a220 <cwrites>
   1904c:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1904f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   19053:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19056:	3b 45 08             	cmp    0x8(%ebp),%eax
   19059:	7e 9d                	jle    18ff8 <progQ+0x75>
			}
			cwrites( "\n" );
   1905b:	83 ec 0c             	sub    $0xc,%esp
   1905e:	68 30 bc 01 00       	push   $0x1bc30
   19063:	e8 b8 11 00 00       	call   1a220 <cwrites>
   19068:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   1906b:	83 ec 04             	sub    $0x4,%esp
   1906e:	6a 01                	push   $0x1
   19070:	8d 45 ef             	lea    -0x11(%ebp),%eax
   19073:	50                   	push   %eax
   19074:	6a 01                	push   $0x1
   19076:	e8 36 dd ff ff       	call   16db1 <write>
   1907b:	83 c4 10             	add    $0x10,%esp

	// try something weird
	bogus();
   1907e:	e8 6e dd ff ff       	call   16df1 <bogus>

	// should not have come back here!
	usprint( buf, "!!!!! %c returned from bogus syscall!?!?!\n", ch );
   19083:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
   19087:	0f be c0             	movsbl %al,%eax
   1908a:	83 ec 04             	sub    $0x4,%esp
   1908d:	50                   	push   %eax
   1908e:	68 60 bd 01 00       	push   $0x1bd60
   19093:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   19099:	50                   	push   %eax
   1909a:	e8 94 0a 00 00       	call   19b33 <usprint>
   1909f:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   190a2:	83 ec 0c             	sub    $0xc,%esp
   190a5:	8d 85 6f ff ff ff    	lea    -0x91(%ebp),%eax
   190ab:	50                   	push   %eax
   190ac:	e8 6f 11 00 00       	call   1a220 <cwrites>
   190b1:	83 c4 10             	add    $0x10,%esp

	exit( 1 );
   190b4:	83 ec 0c             	sub    $0xc,%esp
   190b7:	6a 01                	push   $0x1
   190b9:	e8 cb dc ff ff       	call   16d89 <exit>
   190be:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   190c1:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   190c6:	c9                   	leave  
   190c7:	c3                   	ret    

000190c8 <progR>:
**	 where x is the ID character
**		   n is the sequence number of the initial incarnation
**		   s is the initial delay time (defaults to 10)
*/

USERMAIN( progR ) {
   190c8:	55                   	push   %ebp
   190c9:	89 e5                	mov    %esp,%ebp
   190cb:	81 ec a8 00 00 00    	sub    $0xa8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   190d1:	8b 45 0c             	mov    0xc(%ebp),%eax
   190d4:	8b 00                	mov    (%eax),%eax
   190d6:	85 c0                	test   %eax,%eax
   190d8:	74 07                	je     190e1 <progR+0x19>
   190da:	8b 45 0c             	mov    0xc(%ebp),%eax
   190dd:	8b 00                	mov    (%eax),%eax
   190df:	eb 05                	jmp    190e6 <progR+0x1e>
   190e1:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   190e6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	char ch = 'r';	// default character to print
   190e9:	c6 45 f7 72          	movb   $0x72,-0x9(%ebp)
	int delay = 10;	// initial delay count
   190ed:	c7 45 f0 0a 00 00 00 	movl   $0xa,-0x10(%ebp)
	int seq = 99;	// my sequence number
   190f4:	c7 45 ec 63 00 00 00 	movl   $0x63,-0x14(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   190fb:	8b 45 08             	mov    0x8(%ebp),%eax
   190fe:	83 f8 03             	cmp    $0x3,%eax
   19101:	74 25                	je     19128 <progR+0x60>
   19103:	83 f8 04             	cmp    $0x4,%eax
   19106:	74 07                	je     1910f <progR+0x47>
   19108:	83 f8 02             	cmp    $0x2,%eax
   1910b:	74 34                	je     19141 <progR+0x79>
   1910d:	eb 45                	jmp    19154 <progR+0x8c>
	case 4:	delay = ustr2int( argv[3], 10 );
   1910f:	8b 45 0c             	mov    0xc(%ebp),%eax
   19112:	83 c0 0c             	add    $0xc,%eax
   19115:	8b 00                	mov    (%eax),%eax
   19117:	83 ec 08             	sub    $0x8,%esp
   1911a:	6a 0a                	push   $0xa
   1911c:	50                   	push   %eax
   1911d:	e8 86 0c 00 00       	call   19da8 <ustr2int>
   19122:	83 c4 10             	add    $0x10,%esp
   19125:	89 45 f0             	mov    %eax,-0x10(%ebp)
			// FALL THROUGH
	case 3:	seq = ustr2int( argv[2], 10 );
   19128:	8b 45 0c             	mov    0xc(%ebp),%eax
   1912b:	83 c0 08             	add    $0x8,%eax
   1912e:	8b 00                	mov    (%eax),%eax
   19130:	83 ec 08             	sub    $0x8,%esp
   19133:	6a 0a                	push   $0xa
   19135:	50                   	push   %eax
   19136:	e8 6d 0c 00 00       	call   19da8 <ustr2int>
   1913b:	83 c4 10             	add    $0x10,%esp
   1913e:	89 45 ec             	mov    %eax,-0x14(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   19141:	8b 45 0c             	mov    0xc(%ebp),%eax
   19144:	83 c0 04             	add    $0x4,%eax
   19147:	8b 00                	mov    (%eax),%eax
   19149:	0f b6 00             	movzbl (%eax),%eax
   1914c:	88 45 f7             	mov    %al,-0x9(%ebp)
			break;
   1914f:	e9 a8 00 00 00       	jmp    191fc <progR+0x134>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   19154:	ff 75 08             	pushl  0x8(%ebp)
   19157:	ff 75 e4             	pushl  -0x1c(%ebp)
   1915a:	68 11 bc 01 00       	push   $0x1bc11
   1915f:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19165:	50                   	push   %eax
   19166:	e8 c8 09 00 00       	call   19b33 <usprint>
   1916b:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1916e:	83 ec 0c             	sub    $0xc,%esp
   19171:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19177:	50                   	push   %eax
   19178:	e8 a3 10 00 00       	call   1a220 <cwrites>
   1917d:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   19180:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   19187:	eb 5b                	jmp    191e4 <progR+0x11c>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   19189:	8b 45 08             	mov    0x8(%ebp),%eax
   1918c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19193:	8b 45 0c             	mov    0xc(%ebp),%eax
   19196:	01 d0                	add    %edx,%eax
   19198:	8b 00                	mov    (%eax),%eax
   1919a:	85 c0                	test   %eax,%eax
   1919c:	74 13                	je     191b1 <progR+0xe9>
   1919e:	8b 45 08             	mov    0x8(%ebp),%eax
   191a1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   191a8:	8b 45 0c             	mov    0xc(%ebp),%eax
   191ab:	01 d0                	add    %edx,%eax
   191ad:	8b 00                	mov    (%eax),%eax
   191af:	eb 05                	jmp    191b6 <progR+0xee>
   191b1:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   191b6:	83 ec 04             	sub    $0x4,%esp
   191b9:	50                   	push   %eax
   191ba:	68 2c bc 01 00       	push   $0x1bc2c
   191bf:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   191c5:	50                   	push   %eax
   191c6:	e8 68 09 00 00       	call   19b33 <usprint>
   191cb:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   191ce:	83 ec 0c             	sub    $0xc,%esp
   191d1:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   191d7:	50                   	push   %eax
   191d8:	e8 43 10 00 00       	call   1a220 <cwrites>
   191dd:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   191e0:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   191e4:	8b 45 e8             	mov    -0x18(%ebp),%eax
   191e7:	3b 45 08             	cmp    0x8(%ebp),%eax
   191ea:	7e 9d                	jle    19189 <progR+0xc1>
			}
			cwrites( "\n" );
   191ec:	83 ec 0c             	sub    $0xc,%esp
   191ef:	68 30 bc 01 00       	push   $0x1bc30
   191f4:	e8 27 10 00 00       	call   1a220 <cwrites>
   191f9:	83 c4 10             	add    $0x10,%esp
	int32_t ppid;

 restart:

	// announce our presence
	pid = getpid();
   191fc:	e8 b8 db ff ff       	call   16db9 <getpid>
   19201:	89 45 e0             	mov    %eax,-0x20(%ebp)
	ppid = getppid();
   19204:	e8 b8 db ff ff       	call   16dc1 <getppid>
   19209:	89 45 dc             	mov    %eax,-0x24(%ebp)

	usprint( buf, " %c[%d,%d,%d]", ch, seq, pid, ppid );
   1920c:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
   19210:	83 ec 08             	sub    $0x8,%esp
   19213:	ff 75 dc             	pushl  -0x24(%ebp)
   19216:	ff 75 e0             	pushl  -0x20(%ebp)
   19219:	ff 75 ec             	pushl  -0x14(%ebp)
   1921c:	50                   	push   %eax
   1921d:	68 8b bd 01 00       	push   $0x1bd8b
   19222:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19228:	50                   	push   %eax
   19229:	e8 05 09 00 00       	call   19b33 <usprint>
   1922e:	83 c4 20             	add    $0x20,%esp
	swrites( buf );
   19231:	83 ec 0c             	sub    $0xc,%esp
   19234:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   1923a:	50                   	push   %eax
   1923b:	e8 46 10 00 00       	call   1a286 <swrites>
   19240:	83 c4 10             	add    $0x10,%esp

	sleep( SEC_TO_MS(delay) );
   19243:	8b 45 f0             	mov    -0x10(%ebp),%eax
   19246:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   1924c:	83 ec 0c             	sub    $0xc,%esp
   1924f:	50                   	push   %eax
   19250:	e8 94 db ff ff       	call   16de9 <sleep>
   19255:	83 c4 10             	add    $0x10,%esp

	// create the next child in sequence
	if( seq < 5 ) {
   19258:	83 7d ec 04          	cmpl   $0x4,-0x14(%ebp)
   1925c:	7f 63                	jg     192c1 <progR+0x1f9>
		++seq;
   1925e:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
		int32_t n = fork();
   19262:	e8 32 db ff ff       	call   16d99 <fork>
   19267:	89 45 d8             	mov    %eax,-0x28(%ebp)
		switch( n ) {
   1926a:	8b 45 d8             	mov    -0x28(%ebp),%eax
   1926d:	83 f8 ff             	cmp    $0xffffffff,%eax
   19270:	74 06                	je     19278 <progR+0x1b0>
   19272:	85 c0                	test   %eax,%eax
   19274:	74 86                	je     191fc <progR+0x134>
   19276:	eb 2e                	jmp    192a6 <progR+0x1de>
		case -1:
			// failure?
			usprint( buf, "** R[%d] fork code %d\n", pid, n );
   19278:	ff 75 d8             	pushl  -0x28(%ebp)
   1927b:	ff 75 e0             	pushl  -0x20(%ebp)
   1927e:	68 99 bd 01 00       	push   $0x1bd99
   19283:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19289:	50                   	push   %eax
   1928a:	e8 a4 08 00 00       	call   19b33 <usprint>
   1928f:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   19292:	83 ec 0c             	sub    $0xc,%esp
   19295:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   1929b:	50                   	push   %eax
   1929c:	e8 7f 0f 00 00       	call   1a220 <cwrites>
   192a1:	83 c4 10             	add    $0x10,%esp
			break;
   192a4:	eb 1c                	jmp    192c2 <progR+0x1fa>
		case 0:
			// child
			goto restart;
		default:
			// parent
			--seq;
   192a6:	83 6d ec 01          	subl   $0x1,-0x14(%ebp)
			sleep( SEC_TO_MS(delay) );
   192aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
   192ad:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   192b3:	83 ec 0c             	sub    $0xc,%esp
   192b6:	50                   	push   %eax
   192b7:	e8 2d db ff ff       	call   16de9 <sleep>
   192bc:	83 c4 10             	add    $0x10,%esp
   192bf:	eb 01                	jmp    192c2 <progR+0x1fa>
		}
	}
   192c1:	90                   	nop

	// final report - PPID may change, but PID and seq shouldn't
	pid = getpid();
   192c2:	e8 f2 da ff ff       	call   16db9 <getpid>
   192c7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	ppid = getppid();
   192ca:	e8 f2 da ff ff       	call   16dc1 <getppid>
   192cf:	89 45 dc             	mov    %eax,-0x24(%ebp)
	usprint( buf, " %c[%d,%d,%d]", ch, seq, pid, ppid );
   192d2:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
   192d6:	83 ec 08             	sub    $0x8,%esp
   192d9:	ff 75 dc             	pushl  -0x24(%ebp)
   192dc:	ff 75 e0             	pushl  -0x20(%ebp)
   192df:	ff 75 ec             	pushl  -0x14(%ebp)
   192e2:	50                   	push   %eax
   192e3:	68 8b bd 01 00       	push   $0x1bd8b
   192e8:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   192ee:	50                   	push   %eax
   192ef:	e8 3f 08 00 00       	call   19b33 <usprint>
   192f4:	83 c4 20             	add    $0x20,%esp
	swrites( buf );
   192f7:	83 ec 0c             	sub    $0xc,%esp
   192fa:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
   19300:	50                   	push   %eax
   19301:	e8 80 0f 00 00       	call   1a286 <swrites>
   19306:	83 c4 10             	add    $0x10,%esp

	exit( 0 );
   19309:	83 ec 0c             	sub    $0xc,%esp
   1930c:	6a 00                	push   $0x0
   1930e:	e8 76 da ff ff       	call   16d89 <exit>
   19313:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   19316:	b8 2a 00 00 00       	mov    $0x2a,%eax

}
   1931b:	c9                   	leave  
   1931c:	c3                   	ret    

0001931d <progS>:
** Invoked as:  progS  x  [ s ]
**	 where x is the ID character
**		   s is the sleep time (defaults to 20)
*/

USERMAIN( progS ) {
   1931d:	55                   	push   %ebp
   1931e:	89 e5                	mov    %esp,%ebp
   19320:	81 ec 98 00 00 00    	sub    $0x98,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   19326:	8b 45 0c             	mov    0xc(%ebp),%eax
   19329:	8b 00                	mov    (%eax),%eax
   1932b:	85 c0                	test   %eax,%eax
   1932d:	74 07                	je     19336 <progS+0x19>
   1932f:	8b 45 0c             	mov    0xc(%ebp),%eax
   19332:	8b 00                	mov    (%eax),%eax
   19334:	eb 05                	jmp    1933b <progS+0x1e>
   19336:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   1933b:	89 45 ec             	mov    %eax,-0x14(%ebp)
	char ch = 's';	  // default character to print
   1933e:	c6 45 eb 73          	movb   $0x73,-0x15(%ebp)
	int nap = 20;	  // nap time
   19342:	c7 45 f4 14 00 00 00 	movl   $0x14,-0xc(%ebp)
	char buf[128];

	// process the command-line arguments
	switch( argc ) {
   19349:	8b 45 08             	mov    0x8(%ebp),%eax
   1934c:	83 f8 02             	cmp    $0x2,%eax
   1934f:	74 1e                	je     1936f <progS+0x52>
   19351:	83 f8 03             	cmp    $0x3,%eax
   19354:	75 2c                	jne    19382 <progS+0x65>
	case 3:	nap = ustr2int( argv[2], 10 );
   19356:	8b 45 0c             	mov    0xc(%ebp),%eax
   19359:	83 c0 08             	add    $0x8,%eax
   1935c:	8b 00                	mov    (%eax),%eax
   1935e:	83 ec 08             	sub    $0x8,%esp
   19361:	6a 0a                	push   $0xa
   19363:	50                   	push   %eax
   19364:	e8 3f 0a 00 00       	call   19da8 <ustr2int>
   19369:	83 c4 10             	add    $0x10,%esp
   1936c:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   1936f:	8b 45 0c             	mov    0xc(%ebp),%eax
   19372:	83 c0 04             	add    $0x4,%eax
   19375:	8b 00                	mov    (%eax),%eax
   19377:	0f b6 00             	movzbl (%eax),%eax
   1937a:	88 45 eb             	mov    %al,-0x15(%ebp)
			break;
   1937d:	e9 a8 00 00 00       	jmp    1942a <progS+0x10d>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   19382:	ff 75 08             	pushl  0x8(%ebp)
   19385:	ff 75 ec             	pushl  -0x14(%ebp)
   19388:	68 11 bc 01 00       	push   $0x1bc11
   1938d:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   19393:	50                   	push   %eax
   19394:	e8 9a 07 00 00       	call   19b33 <usprint>
   19399:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1939c:	83 ec 0c             	sub    $0xc,%esp
   1939f:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   193a5:	50                   	push   %eax
   193a6:	e8 75 0e 00 00       	call   1a220 <cwrites>
   193ab:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   193ae:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
   193b5:	eb 5b                	jmp    19412 <progS+0xf5>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   193b7:	8b 45 08             	mov    0x8(%ebp),%eax
   193ba:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   193c1:	8b 45 0c             	mov    0xc(%ebp),%eax
   193c4:	01 d0                	add    %edx,%eax
   193c6:	8b 00                	mov    (%eax),%eax
   193c8:	85 c0                	test   %eax,%eax
   193ca:	74 13                	je     193df <progS+0xc2>
   193cc:	8b 45 08             	mov    0x8(%ebp),%eax
   193cf:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   193d6:	8b 45 0c             	mov    0xc(%ebp),%eax
   193d9:	01 d0                	add    %edx,%eax
   193db:	8b 00                	mov    (%eax),%eax
   193dd:	eb 05                	jmp    193e4 <progS+0xc7>
   193df:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   193e4:	83 ec 04             	sub    $0x4,%esp
   193e7:	50                   	push   %eax
   193e8:	68 2c bc 01 00       	push   $0x1bc2c
   193ed:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   193f3:	50                   	push   %eax
   193f4:	e8 3a 07 00 00       	call   19b33 <usprint>
   193f9:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   193fc:	83 ec 0c             	sub    $0xc,%esp
   193ff:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   19405:	50                   	push   %eax
   19406:	e8 15 0e 00 00       	call   1a220 <cwrites>
   1940b:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1940e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
   19412:	8b 45 f0             	mov    -0x10(%ebp),%eax
   19415:	3b 45 08             	cmp    0x8(%ebp),%eax
   19418:	7e 9d                	jle    193b7 <progS+0x9a>
			}
			cwrites( "\n" );
   1941a:	83 ec 0c             	sub    $0xc,%esp
   1941d:	68 30 bc 01 00       	push   $0x1bc30
   19422:	e8 f9 0d 00 00       	call   1a220 <cwrites>
   19427:	83 c4 10             	add    $0x10,%esp
	}

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   1942a:	83 ec 04             	sub    $0x4,%esp
   1942d:	6a 01                	push   $0x1
   1942f:	8d 45 eb             	lea    -0x15(%ebp),%eax
   19432:	50                   	push   %eax
   19433:	6a 01                	push   $0x1
   19435:	e8 77 d9 ff ff       	call   16db1 <write>
   1943a:	83 c4 10             	add    $0x10,%esp

	usprint( buf, "%s sleeping %d(%d)\n", name, nap, SEC_TO_MS(nap) );
   1943d:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19440:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   19446:	83 ec 0c             	sub    $0xc,%esp
   19449:	50                   	push   %eax
   1944a:	ff 75 f4             	pushl  -0xc(%ebp)
   1944d:	ff 75 ec             	pushl  -0x14(%ebp)
   19450:	68 b0 bd 01 00       	push   $0x1bdb0
   19455:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   1945b:	50                   	push   %eax
   1945c:	e8 d2 06 00 00       	call   19b33 <usprint>
   19461:	83 c4 20             	add    $0x20,%esp
	cwrites( buf );
   19464:	83 ec 0c             	sub    $0xc,%esp
   19467:	8d 85 6b ff ff ff    	lea    -0x95(%ebp),%eax
   1946d:	50                   	push   %eax
   1946e:	e8 ad 0d 00 00       	call   1a220 <cwrites>
   19473:	83 c4 10             	add    $0x10,%esp

	for(;;) {
		sleep( SEC_TO_MS(nap) );
   19476:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19479:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   1947f:	83 ec 0c             	sub    $0xc,%esp
   19482:	50                   	push   %eax
   19483:	e8 61 d9 ff ff       	call   16de9 <sleep>
   19488:	83 c4 10             	add    $0x10,%esp
		write( CHAN_SIO, &ch, 1 );
   1948b:	83 ec 04             	sub    $0x4,%esp
   1948e:	6a 01                	push   $0x1
   19490:	8d 45 eb             	lea    -0x15(%ebp),%eax
   19493:	50                   	push   %eax
   19494:	6a 01                	push   $0x1
   19496:	e8 16 d9 ff ff       	call   16db1 <write>
   1949b:	83 c4 10             	add    $0x10,%esp
		sleep( SEC_TO_MS(nap) );
   1949e:	eb d6                	jmp    19476 <progS+0x159>

000194a0 <progTUV>:

#ifndef MAX_CHILDREN
#define MAX_CHILDREN	50
#endif

USERMAIN( progTUV ) {
   194a0:	55                   	push   %ebp
   194a1:	89 e5                	mov    %esp,%ebp
   194a3:	81 ec a8 01 00 00    	sub    $0x1a8,%esp
	char *name = argv[0] ? argv[0] : "nobody";
   194a9:	8b 45 0c             	mov    0xc(%ebp),%eax
   194ac:	8b 00                	mov    (%eax),%eax
   194ae:	85 c0                	test   %eax,%eax
   194b0:	74 07                	je     194b9 <progTUV+0x19>
   194b2:	8b 45 0c             	mov    0xc(%ebp),%eax
   194b5:	8b 00                	mov    (%eax),%eax
   194b7:	eb 05                	jmp    194be <progTUV+0x1e>
   194b9:	b8 28 b9 01 00       	mov    $0x1b928,%eax
   194be:	89 45 d0             	mov    %eax,-0x30(%ebp)
	int count = 3;			// default child count
   194c1:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
	char ch = '6';			// default character to print
   194c8:	c6 45 c7 36          	movb   $0x36,-0x39(%ebp)
	int nap = 8;			// nap time
   194cc:	c7 45 cc 08 00 00 00 	movl   $0x8,-0x34(%ebp)
	bool_t waiting = true;	// default is waiting by PID
   194d3:	c6 45 f3 01          	movb   $0x1,-0xd(%ebp)
	bool_t bypid = true;
   194d7:	c6 45 f2 01          	movb   $0x1,-0xe(%ebp)
	char buf[128];
	uint_t children[MAX_CHILDREN];
	int nkids = 0;
   194db:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	char ch2[] = "*?*";
   194e2:	c7 85 78 fe ff ff 2a 	movl   $0x2a3f2a,-0x188(%ebp)
   194e9:	3f 2a 00 

	// process the command-line arguments
	switch( argc ) {
   194ec:	8b 45 08             	mov    0x8(%ebp),%eax
   194ef:	83 f8 03             	cmp    $0x3,%eax
   194f2:	74 32                	je     19526 <progTUV+0x86>
   194f4:	83 f8 04             	cmp    $0x4,%eax
   194f7:	74 07                	je     19500 <progTUV+0x60>
   194f9:	83 f8 02             	cmp    $0x2,%eax
   194fc:	74 41                	je     1953f <progTUV+0x9f>
   194fe:	eb 52                	jmp    19552 <progTUV+0xb2>
	case 4:	waiting = argv[3][0] != 'k';	// 'w'/'W' -> wait, else -> kill
   19500:	8b 45 0c             	mov    0xc(%ebp),%eax
   19503:	83 c0 0c             	add    $0xc,%eax
   19506:	8b 00                	mov    (%eax),%eax
   19508:	0f b6 00             	movzbl (%eax),%eax
   1950b:	3c 6b                	cmp    $0x6b,%al
   1950d:	0f 95 c0             	setne  %al
   19510:	88 45 f3             	mov    %al,-0xd(%ebp)
			bypid   = argv[3][0] != 'w';	// 'W'/'k' -> by PID
   19513:	8b 45 0c             	mov    0xc(%ebp),%eax
   19516:	83 c0 0c             	add    $0xc,%eax
   19519:	8b 00                	mov    (%eax),%eax
   1951b:	0f b6 00             	movzbl (%eax),%eax
   1951e:	3c 77                	cmp    $0x77,%al
   19520:	0f 95 c0             	setne  %al
   19523:	88 45 f2             	mov    %al,-0xe(%ebp)
			// FALL THROUGH
	case 3:	count = ustr2int( argv[2], 10 );
   19526:	8b 45 0c             	mov    0xc(%ebp),%eax
   19529:	83 c0 08             	add    $0x8,%eax
   1952c:	8b 00                	mov    (%eax),%eax
   1952e:	83 ec 08             	sub    $0x8,%esp
   19531:	6a 0a                	push   $0xa
   19533:	50                   	push   %eax
   19534:	e8 6f 08 00 00       	call   19da8 <ustr2int>
   19539:	83 c4 10             	add    $0x10,%esp
   1953c:	89 45 f4             	mov    %eax,-0xc(%ebp)
			// FALL THROUGH
	case 2:	ch = argv[1][0];
   1953f:	8b 45 0c             	mov    0xc(%ebp),%eax
   19542:	83 c0 04             	add    $0x4,%eax
   19545:	8b 00                	mov    (%eax),%eax
   19547:	0f b6 00             	movzbl (%eax),%eax
   1954a:	88 45 c7             	mov    %al,-0x39(%ebp)
			break;
   1954d:	e9 a8 00 00 00       	jmp    195fa <progTUV+0x15a>
	default:
			usprint( buf, "%s: argc %d, args: ", name, argc );
   19552:	ff 75 08             	pushl  0x8(%ebp)
   19555:	ff 75 d0             	pushl  -0x30(%ebp)
   19558:	68 11 bc 01 00       	push   $0x1bc11
   1955d:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19563:	50                   	push   %eax
   19564:	e8 ca 05 00 00       	call   19b33 <usprint>
   19569:	83 c4 10             	add    $0x10,%esp
			cwrites( buf );
   1956c:	83 ec 0c             	sub    $0xc,%esp
   1956f:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19575:	50                   	push   %eax
   19576:	e8 a5 0c 00 00       	call   1a220 <cwrites>
   1957b:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   1957e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
   19585:	eb 5b                	jmp    195e2 <progTUV+0x142>
				usprint( buf, " %s", argv[argc] ? argv[argc] : "(null)" );
   19587:	8b 45 08             	mov    0x8(%ebp),%eax
   1958a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19591:	8b 45 0c             	mov    0xc(%ebp),%eax
   19594:	01 d0                	add    %edx,%eax
   19596:	8b 00                	mov    (%eax),%eax
   19598:	85 c0                	test   %eax,%eax
   1959a:	74 13                	je     195af <progTUV+0x10f>
   1959c:	8b 45 08             	mov    0x8(%ebp),%eax
   1959f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   195a6:	8b 45 0c             	mov    0xc(%ebp),%eax
   195a9:	01 d0                	add    %edx,%eax
   195ab:	8b 00                	mov    (%eax),%eax
   195ad:	eb 05                	jmp    195b4 <progTUV+0x114>
   195af:	b8 25 bc 01 00       	mov    $0x1bc25,%eax
   195b4:	83 ec 04             	sub    $0x4,%esp
   195b7:	50                   	push   %eax
   195b8:	68 2c bc 01 00       	push   $0x1bc2c
   195bd:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   195c3:	50                   	push   %eax
   195c4:	e8 6a 05 00 00       	call   19b33 <usprint>
   195c9:	83 c4 10             	add    $0x10,%esp
				cwrites( buf );
   195cc:	83 ec 0c             	sub    $0xc,%esp
   195cf:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   195d5:	50                   	push   %eax
   195d6:	e8 45 0c 00 00       	call   1a220 <cwrites>
   195db:	83 c4 10             	add    $0x10,%esp
			for( int i = 0; i <= argc; ++i ) {
   195de:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
   195e2:	8b 45 e8             	mov    -0x18(%ebp),%eax
   195e5:	3b 45 08             	cmp    0x8(%ebp),%eax
   195e8:	7e 9d                	jle    19587 <progTUV+0xe7>
			}
			cwrites( "\n" );
   195ea:	83 ec 0c             	sub    $0xc,%esp
   195ed:	68 30 bc 01 00       	push   $0x1bc30
   195f2:	e8 29 0c 00 00       	call   1a220 <cwrites>
   195f7:	83 c4 10             	add    $0x10,%esp
	}

	// fix the secondary output message (for indicating errors)
	ch2[1] = ch;
   195fa:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   195fe:	88 85 79 fe ff ff    	mov    %al,-0x187(%ebp)

	// announce our presence
	write( CHAN_SIO, &ch, 1 );
   19604:	83 ec 04             	sub    $0x4,%esp
   19607:	6a 01                	push   $0x1
   19609:	8d 45 c7             	lea    -0x39(%ebp),%eax
   1960c:	50                   	push   %eax
   1960d:	6a 01                	push   $0x1
   1960f:	e8 9d d7 ff ff       	call   16db1 <write>
   19614:	83 c4 10             	add    $0x10,%esp

	// set up the argument vector
	char *argsw[] = { "progW", "W", "10", "5", NULL };
   19617:	c7 85 64 fe ff ff f2 	movl   $0x1bcf2,-0x19c(%ebp)
   1961e:	bc 01 00 
   19621:	c7 85 68 fe ff ff 06 	movl   $0x1ba06,-0x198(%ebp)
   19628:	ba 01 00 
   1962b:	c7 85 6c fe ff ff 84 	movl   $0x1b984,-0x194(%ebp)
   19632:	b9 01 00 
   19635:	c7 85 70 fe ff ff b3 	movl   $0x1b9b3,-0x190(%ebp)
   1963c:	b9 01 00 
   1963f:	c7 85 74 fe ff ff 00 	movl   $0x0,-0x18c(%ebp)
   19646:	00 00 00 

	for( int i = 0; i < count; ++i ) {
   19649:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
   19650:	eb 4c                	jmp    1969e <progTUV+0x1fe>
		int whom = spawn( (uint32_t) progW, argsw );
   19652:	ba 75 82 01 00       	mov    $0x18275,%edx
   19657:	83 ec 08             	sub    $0x8,%esp
   1965a:	8d 85 64 fe ff ff    	lea    -0x19c(%ebp),%eax
   19660:	50                   	push   %eax
   19661:	52                   	push   %edx
   19662:	e8 23 0b 00 00       	call   1a18a <spawn>
   19667:	83 c4 10             	add    $0x10,%esp
   1966a:	89 45 c8             	mov    %eax,-0x38(%ebp)
		if( whom < 0 ) {
   1966d:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
   19671:	79 14                	jns    19687 <progTUV+0x1e7>
			swrites( ch2 );
   19673:	83 ec 0c             	sub    $0xc,%esp
   19676:	8d 85 78 fe ff ff    	lea    -0x188(%ebp),%eax
   1967c:	50                   	push   %eax
   1967d:	e8 04 0c 00 00       	call   1a286 <swrites>
   19682:	83 c4 10             	add    $0x10,%esp
   19685:	eb 13                	jmp    1969a <progTUV+0x1fa>
		} else {
			children[nkids++] = whom;
   19687:	8b 45 ec             	mov    -0x14(%ebp),%eax
   1968a:	8d 50 01             	lea    0x1(%eax),%edx
   1968d:	89 55 ec             	mov    %edx,-0x14(%ebp)
   19690:	8b 55 c8             	mov    -0x38(%ebp),%edx
   19693:	89 94 85 7c fe ff ff 	mov    %edx,-0x184(%ebp,%eax,4)
	for( int i = 0; i < count; ++i ) {
   1969a:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
   1969e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
   196a1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
   196a4:	7c ac                	jl     19652 <progTUV+0x1b2>
		}
	}

	// let the children start
	sleep( SEC_TO_MS(nap) );
   196a6:	8b 45 cc             	mov    -0x34(%ebp),%eax
   196a9:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
   196af:	83 ec 0c             	sub    $0xc,%esp
   196b2:	50                   	push   %eax
   196b3:	e8 31 d7 ff ff       	call   16de9 <sleep>
   196b8:	83 c4 10             	add    $0x10,%esp

	// collect exit status information

	// current child index
	int n = 0;
   196bb:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	do {
		int this;
		int32_t status;

		// are we waiting for or killing it?
		if( waiting ) {
   196c2:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   196c6:	74 2f                	je     196f7 <progTUV+0x257>
			this = waitpid( bypid ? children[n] : 0, &status );
   196c8:	80 7d f2 00          	cmpb   $0x0,-0xe(%ebp)
   196cc:	74 0c                	je     196da <progTUV+0x23a>
   196ce:	8b 45 e0             	mov    -0x20(%ebp),%eax
   196d1:	8b 84 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%eax
   196d8:	eb 05                	jmp    196df <progTUV+0x23f>
   196da:	b8 00 00 00 00       	mov    $0x0,%eax
   196df:	83 ec 08             	sub    $0x8,%esp
   196e2:	8d 95 60 fe ff ff    	lea    -0x1a0(%ebp),%edx
   196e8:	52                   	push   %edx
   196e9:	50                   	push   %eax
   196ea:	e8 a2 d6 ff ff       	call   16d91 <waitpid>
   196ef:	83 c4 10             	add    $0x10,%esp
   196f2:	89 45 dc             	mov    %eax,-0x24(%ebp)
   196f5:	eb 19                	jmp    19710 <progTUV+0x270>
		} else {
			// always by PID
			this = kill( children[n] );
   196f7:	8b 45 e0             	mov    -0x20(%ebp),%eax
   196fa:	8b 84 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%eax
   19701:	83 ec 0c             	sub    $0xc,%esp
   19704:	50                   	push   %eax
   19705:	e8 d7 d6 ff ff       	call   16de1 <kill>
   1970a:	83 c4 10             	add    $0x10,%esp
   1970d:	89 45 dc             	mov    %eax,-0x24(%ebp)
		}

		// what was the result?
		if( this < SUCCESS ) {
   19710:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
   19714:	0f 89 a1 00 00 00    	jns    197bb <progTUV+0x31b>

			// uh-oh - something went wrong

			// "no children" means we're all done
			if( this != E_NO_CHILDREN ) {
   1971a:	83 7d dc fc          	cmpl   $0xfffffffc,-0x24(%ebp)
   1971e:	74 77                	je     19797 <progTUV+0x2f7>
				if( waiting ) {
   19720:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   19724:	74 3f                	je     19765 <progTUV+0x2c5>
					usprint( buf, "!! %c: waitpid(%d) status %d\n",
   19726:	80 7d f2 00          	cmpb   $0x0,-0xe(%ebp)
   1972a:	74 0c                	je     19738 <progTUV+0x298>
   1972c:	8b 45 e0             	mov    -0x20(%ebp),%eax
   1972f:	8b 84 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%eax
   19736:	eb 05                	jmp    1973d <progTUV+0x29d>
   19738:	b8 00 00 00 00       	mov    $0x0,%eax
   1973d:	0f b6 55 c7          	movzbl -0x39(%ebp),%edx
   19741:	0f be d2             	movsbl %dl,%edx
   19744:	83 ec 0c             	sub    $0xc,%esp
   19747:	ff 75 dc             	pushl  -0x24(%ebp)
   1974a:	50                   	push   %eax
   1974b:	52                   	push   %edx
   1974c:	68 c4 bd 01 00       	push   $0x1bdc4
   19751:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19757:	50                   	push   %eax
   19758:	e8 d6 03 00 00       	call   19b33 <usprint>
   1975d:	83 c4 20             	add    $0x20,%esp
			} else {
				usprint( buf, "!! %c: no children\n", ch );
			}

			// regardless, we're outta here
			break;
   19760:	e9 9d 01 00 00       	jmp    19902 <progTUV+0x462>
					usprint( buf, "!! %c: kill(%d) status %d\n",
   19765:	8b 45 e0             	mov    -0x20(%ebp),%eax
   19768:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   1976f:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   19773:	0f be c0             	movsbl %al,%eax
   19776:	83 ec 0c             	sub    $0xc,%esp
   19779:	ff 75 dc             	pushl  -0x24(%ebp)
   1977c:	52                   	push   %edx
   1977d:	50                   	push   %eax
   1977e:	68 f8 bc 01 00       	push   $0x1bcf8
   19783:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19789:	50                   	push   %eax
   1978a:	e8 a4 03 00 00       	call   19b33 <usprint>
   1978f:	83 c4 20             	add    $0x20,%esp
			break;
   19792:	e9 6b 01 00 00       	jmp    19902 <progTUV+0x462>
				usprint( buf, "!! %c: no children\n", ch );
   19797:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   1979b:	0f be c0             	movsbl %al,%eax
   1979e:	83 ec 04             	sub    $0x4,%esp
   197a1:	50                   	push   %eax
   197a2:	68 e2 bd 01 00       	push   $0x1bde2
   197a7:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   197ad:	50                   	push   %eax
   197ae:	e8 80 03 00 00       	call   19b33 <usprint>
   197b3:	83 c4 10             	add    $0x10,%esp
   197b6:	e9 47 01 00 00       	jmp    19902 <progTUV+0x462>

		} else {

			// locate the child
			int ix = -1;
   197bb:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)

			// were we looking by PID?
			if( bypid ) {
   197c2:	80 7d f2 00          	cmpb   $0x0,-0xe(%ebp)
   197c6:	74 58                	je     19820 <progTUV+0x380>
				// we should have just gotten the one we were looking for
				if( this != children[n] ) {
   197c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
   197cb:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   197d2:	8b 45 dc             	mov    -0x24(%ebp),%eax
   197d5:	39 c2                	cmp    %eax,%edx
   197d7:	74 41                	je     1981a <progTUV+0x37a>
					// uh-oh
					usprint( buf, "** %c: wait/kill PID %d, got %d\n",
   197d9:	8b 45 e0             	mov    -0x20(%ebp),%eax
   197dc:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   197e3:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   197e7:	0f be c0             	movsbl %al,%eax
   197ea:	83 ec 0c             	sub    $0xc,%esp
   197ed:	ff 75 dc             	pushl  -0x24(%ebp)
   197f0:	52                   	push   %edx
   197f1:	50                   	push   %eax
   197f2:	68 f8 bd 01 00       	push   $0x1bdf8
   197f7:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   197fd:	50                   	push   %eax
   197fe:	e8 30 03 00 00       	call   19b33 <usprint>
   19803:	83 c4 20             	add    $0x20,%esp
							ch, children[n], this );
					cwrites( buf );
   19806:	83 ec 0c             	sub    $0xc,%esp
   19809:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   1980f:	50                   	push   %eax
   19810:	e8 0b 0a 00 00       	call   1a220 <cwrites>
   19815:	83 c4 10             	add    $0x10,%esp
   19818:	eb 06                	jmp    19820 <progTUV+0x380>
				} else {
					ix = n;
   1981a:	8b 45 e0             	mov    -0x20(%ebp),%eax
   1981d:	89 45 d8             	mov    %eax,-0x28(%ebp)
				}
			}

			// either not looking by PID, or the lookup failed somehow
			if( ix < 0 ) {
   19820:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   19824:	79 2e                	jns    19854 <progTUV+0x3b4>
				int i;
				for( i = 0; i < nkids; ++i ) {
   19826:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
   1982d:	eb 1d                	jmp    1984c <progTUV+0x3ac>
					if( children[i] == this ) {
   1982f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   19832:	8b 94 85 7c fe ff ff 	mov    -0x184(%ebp,%eax,4),%edx
   19839:	8b 45 dc             	mov    -0x24(%ebp),%eax
   1983c:	39 c2                	cmp    %eax,%edx
   1983e:	75 08                	jne    19848 <progTUV+0x3a8>
						ix = i;
   19840:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   19843:	89 45 d8             	mov    %eax,-0x28(%ebp)
						break;
   19846:	eb 0c                	jmp    19854 <progTUV+0x3b4>
				for( i = 0; i < nkids; ++i ) {
   19848:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
   1984c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
   1984f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   19852:	7c db                	jl     1982f <progTUV+0x38f>
				}
			}

			// if ix == -1, the PID we received isn't in our list of children

			if( ix < 0 ) {
   19854:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
   19858:	79 21                	jns    1987b <progTUV+0x3db>

				// didn't find an entry for this PID???
				usprint( buf, "!! %c: child PID %d term, NOT FOUND\n",
   1985a:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   1985e:	0f be c0             	movsbl %al,%eax
   19861:	ff 75 dc             	pushl  -0x24(%ebp)
   19864:	50                   	push   %eax
   19865:	68 1c be 01 00       	push   $0x1be1c
   1986a:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   19870:	50                   	push   %eax
   19871:	e8 bd 02 00 00       	call   19b33 <usprint>
   19876:	83 c4 10             	add    $0x10,%esp
   19879:	eb 65                	jmp    198e0 <progTUV+0x440>
						ch, this );

			} else {

				// found this PID in our list of children
				if( ix != n ) {
   1987b:	8b 45 d8             	mov    -0x28(%ebp),%eax
   1987e:	3b 45 e0             	cmp    -0x20(%ebp),%eax
   19881:	74 31                	je     198b4 <progTUV+0x414>
					// ... but it's out of sequence
					usprint( buf, "== %c: child %d (%d,%d) status %d\n",
   19883:	8b 95 60 fe ff ff    	mov    -0x1a0(%ebp),%edx
   19889:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   1988d:	0f be c0             	movsbl %al,%eax
   19890:	83 ec 04             	sub    $0x4,%esp
   19893:	52                   	push   %edx
   19894:	ff 75 dc             	pushl  -0x24(%ebp)
   19897:	ff 75 e0             	pushl  -0x20(%ebp)
   1989a:	ff 75 d8             	pushl  -0x28(%ebp)
   1989d:	50                   	push   %eax
   1989e:	68 44 be 01 00       	push   $0x1be44
   198a3:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   198a9:	50                   	push   %eax
   198aa:	e8 84 02 00 00       	call   19b33 <usprint>
   198af:	83 c4 20             	add    $0x20,%esp
   198b2:	eb 2c                	jmp    198e0 <progTUV+0x440>
							ch, ix, n, this, status );
				} else {
					usprint( buf, "== %c: child %d (%d) status %d\n",
   198b4:	8b 95 60 fe ff ff    	mov    -0x1a0(%ebp),%edx
   198ba:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
   198be:	0f be c0             	movsbl %al,%eax
   198c1:	83 ec 08             	sub    $0x8,%esp
   198c4:	52                   	push   %edx
   198c5:	ff 75 dc             	pushl  -0x24(%ebp)
   198c8:	ff 75 d8             	pushl  -0x28(%ebp)
   198cb:	50                   	push   %eax
   198cc:	68 68 be 01 00       	push   $0x1be68
   198d1:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   198d7:	50                   	push   %eax
   198d8:	e8 56 02 00 00       	call   19b33 <usprint>
   198dd:	83 c4 20             	add    $0x20,%esp
				}
			}

		}

		cwrites( buf );
   198e0:	83 ec 0c             	sub    $0xc,%esp
   198e3:	8d 85 47 ff ff ff    	lea    -0xb9(%ebp),%eax
   198e9:	50                   	push   %eax
   198ea:	e8 31 09 00 00       	call   1a220 <cwrites>
   198ef:	83 c4 10             	add    $0x10,%esp

		++n;
   198f2:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)

	} while( n < nkids );
   198f6:	8b 45 e0             	mov    -0x20(%ebp),%eax
   198f9:	3b 45 ec             	cmp    -0x14(%ebp),%eax
   198fc:	0f 8c c0 fd ff ff    	jl     196c2 <progTUV+0x222>

	exit( 0 );
   19902:	83 ec 0c             	sub    $0xc,%esp
   19905:	6a 00                	push   $0x0
   19907:	e8 7d d4 ff ff       	call   16d89 <exit>
   1990c:	83 c4 10             	add    $0x10,%esp

	return( 42 );  // shut the compiler up!
   1990f:	b8 2a 00 00 00       	mov    $0x2a,%eax
}
   19914:	c9                   	leave  
   19915:	c3                   	ret    

00019916 <ublkmov>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void ublkmov( void *dst, const void *src, register uint32_t len ) {
   19916:	55                   	push   %ebp
   19917:	89 e5                	mov    %esp,%ebp
   19919:	56                   	push   %esi
   1991a:	53                   	push   %ebx
   1991b:	8b 45 10             	mov    0x10(%ebp),%eax

	// verify that the addresses are aligned and
	// the length is a multiple of four bytes
	if( (((uint32_t)dst)&0x3) != 0 ||
   1991e:	8b 55 08             	mov    0x8(%ebp),%edx
   19921:	83 e2 03             	and    $0x3,%edx
   19924:	85 d2                	test   %edx,%edx
   19926:	75 13                	jne    1993b <ublkmov+0x25>
		(((uint32_t)src)&0x3) != 0 ||
   19928:	8b 55 0c             	mov    0xc(%ebp),%edx
   1992b:	83 e2 03             	and    $0x3,%edx
	if( (((uint32_t)dst)&0x3) != 0 ||
   1992e:	85 d2                	test   %edx,%edx
   19930:	75 09                	jne    1993b <ublkmov+0x25>
		(len & 0x3) != 0 ) {
   19932:	89 c2                	mov    %eax,%edx
   19934:	83 e2 03             	and    $0x3,%edx
		(((uint32_t)src)&0x3) != 0 ||
   19937:	85 d2                	test   %edx,%edx
   19939:	74 14                	je     1994f <ublkmov+0x39>
		// something isn't aligned, so just use memmove()
		umemmove( dst, src, len );
   1993b:	83 ec 04             	sub    $0x4,%esp
   1993e:	50                   	push   %eax
   1993f:	ff 75 0c             	pushl  0xc(%ebp)
   19942:	ff 75 08             	pushl  0x8(%ebp)
   19945:	e8 b4 00 00 00       	call   199fe <umemmove>
   1994a:	83 c4 10             	add    $0x10,%esp
		return;
   1994d:	eb 5a                	jmp    199a9 <ublkmov+0x93>
	}

	// everything is nicely aligned, so off we go
	register uint32_t *dest = dst;
   1994f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint32_t *source = src;
   19952:	8b 75 0c             	mov    0xc(%ebp),%esi

	// now copying 32-bit values
	len /= 4;
   19955:	c1 e8 02             	shr    $0x2,%eax

	if( source < dest && (source + len) > dest ) {
   19958:	39 de                	cmp    %ebx,%esi
   1995a:	73 44                	jae    199a0 <ublkmov+0x8a>
   1995c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19963:	01 f2                	add    %esi,%edx
   19965:	39 d3                	cmp    %edx,%ebx
   19967:	73 37                	jae    199a0 <ublkmov+0x8a>
		source += len;
   19969:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19970:	01 d6                	add    %edx,%esi
		dest += len;
   19972:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
   19979:	01 d3                	add    %edx,%ebx
		while( len-- > 0 ) {
   1997b:	eb 0a                	jmp    19987 <ublkmov+0x71>
			*--dest = *--source;
   1997d:	83 ee 04             	sub    $0x4,%esi
   19980:	83 eb 04             	sub    $0x4,%ebx
   19983:	8b 16                	mov    (%esi),%edx
   19985:	89 13                	mov    %edx,(%ebx)
		while( len-- > 0 ) {
   19987:	89 c2                	mov    %eax,%edx
   19989:	8d 42 ff             	lea    -0x1(%edx),%eax
   1998c:	85 d2                	test   %edx,%edx
   1998e:	75 ed                	jne    1997d <ublkmov+0x67>
	if( source < dest && (source + len) > dest ) {
   19990:	eb 17                	jmp    199a9 <ublkmov+0x93>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   19992:	89 f1                	mov    %esi,%ecx
   19994:	8d 71 04             	lea    0x4(%ecx),%esi
   19997:	89 da                	mov    %ebx,%edx
   19999:	8d 5a 04             	lea    0x4(%edx),%ebx
   1999c:	8b 09                	mov    (%ecx),%ecx
   1999e:	89 0a                	mov    %ecx,(%edx)
		while( len-- ) {
   199a0:	89 c2                	mov    %eax,%edx
   199a2:	8d 42 ff             	lea    -0x1(%edx),%eax
   199a5:	85 d2                	test   %edx,%edx
   199a7:	75 e9                	jne    19992 <ublkmov+0x7c>
		}
	}
}
   199a9:	8d 65 f8             	lea    -0x8(%ebp),%esp
   199ac:	5b                   	pop    %ebx
   199ad:	5e                   	pop    %esi
   199ae:	5d                   	pop    %ebp
   199af:	c3                   	ret    

000199b0 <umemclr>:
** Initialize all bytes of a block of memory to zero
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
*/
void umemclr( void *buf, register uint32_t len ) {
   199b0:	55                   	push   %ebp
   199b1:	89 e5                	mov    %esp,%ebp
   199b3:	53                   	push   %ebx
   199b4:	8b 55 0c             	mov    0xc(%ebp),%edx
	register uint8_t *dest = buf;
   199b7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and clearing
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   199ba:	eb 08                	jmp    199c4 <umemclr+0x14>
			*dest++ = 0;
   199bc:	89 d8                	mov    %ebx,%eax
   199be:	8d 58 01             	lea    0x1(%eax),%ebx
   199c1:	c6 00 00             	movb   $0x0,(%eax)
	while( len-- ) {
   199c4:	89 d0                	mov    %edx,%eax
   199c6:	8d 50 ff             	lea    -0x1(%eax),%edx
   199c9:	85 c0                	test   %eax,%eax
   199cb:	75 ef                	jne    199bc <umemclr+0xc>
	}
}
   199cd:	90                   	nop
   199ce:	5b                   	pop    %ebx
   199cf:	5d                   	pop    %ebp
   199d0:	c3                   	ret    

000199d1 <umemcpy>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void umemcpy( void *dst, register const void *src, register uint32_t len ) {
   199d1:	55                   	push   %ebp
   199d2:	89 e5                	mov    %esp,%ebp
   199d4:	56                   	push   %esi
   199d5:	53                   	push   %ebx
   199d6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	register uint8_t *dest = dst;
   199d9:	8b 5d 08             	mov    0x8(%ebp),%ebx
	register const uint8_t *source = src;
   199dc:	8b 75 0c             	mov    0xc(%ebp),%esi
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   199df:	eb 0f                	jmp    199f0 <umemcpy+0x1f>
		*dest++ = *source++;
   199e1:	89 f2                	mov    %esi,%edx
   199e3:	8d 72 01             	lea    0x1(%edx),%esi
   199e6:	89 d8                	mov    %ebx,%eax
   199e8:	8d 58 01             	lea    0x1(%eax),%ebx
   199eb:	0f b6 12             	movzbl (%edx),%edx
   199ee:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   199f0:	89 c8                	mov    %ecx,%eax
   199f2:	8d 48 ff             	lea    -0x1(%eax),%ecx
   199f5:	85 c0                	test   %eax,%eax
   199f7:	75 e8                	jne    199e1 <umemcpy+0x10>
	}
}
   199f9:	90                   	nop
   199fa:	5b                   	pop    %ebx
   199fb:	5e                   	pop    %esi
   199fc:	5d                   	pop    %ebp
   199fd:	c3                   	ret    

000199fe <umemmove>:
**
** @param dst   Destination buffer
** @param src   Source buffer
** @param len   Buffer size (in bytes)
*/
void umemmove( void *dst, const void *src, register uint32_t len ) {
   199fe:	55                   	push   %ebp
   199ff:	89 e5                	mov    %esp,%ebp
   19a01:	56                   	push   %esi
   19a02:	53                   	push   %ebx
   19a03:	8b 45 10             	mov    0x10(%ebp),%eax
	register uint8_t *dest = dst;
   19a06:	8b 75 08             	mov    0x8(%ebp),%esi
	register const uint8_t *source = src;
   19a09:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	if( source < dest && (source + len) > dest ) {
   19a0c:	39 f3                	cmp    %esi,%ebx
   19a0e:	73 32                	jae    19a42 <umemmove+0x44>
   19a10:	8d 14 03             	lea    (%ebx,%eax,1),%edx
   19a13:	39 d6                	cmp    %edx,%esi
   19a15:	73 2b                	jae    19a42 <umemmove+0x44>
		source += len;
   19a17:	01 c3                	add    %eax,%ebx
		dest += len;
   19a19:	01 c6                	add    %eax,%esi
		while( len-- > 0 ) {
   19a1b:	eb 0b                	jmp    19a28 <umemmove+0x2a>
			*--dest = *--source;
   19a1d:	83 eb 01             	sub    $0x1,%ebx
   19a20:	83 ee 01             	sub    $0x1,%esi
   19a23:	0f b6 13             	movzbl (%ebx),%edx
   19a26:	88 16                	mov    %dl,(%esi)
		while( len-- > 0 ) {
   19a28:	89 c2                	mov    %eax,%edx
   19a2a:	8d 42 ff             	lea    -0x1(%edx),%eax
   19a2d:	85 d2                	test   %edx,%edx
   19a2f:	75 ec                	jne    19a1d <umemmove+0x1f>
	if( source < dest && (source + len) > dest ) {
   19a31:	eb 18                	jmp    19a4b <umemmove+0x4d>
		}
	} else {
		while( len-- ) {
			*dest++ = *source++;
   19a33:	89 d9                	mov    %ebx,%ecx
   19a35:	8d 59 01             	lea    0x1(%ecx),%ebx
   19a38:	89 f2                	mov    %esi,%edx
   19a3a:	8d 72 01             	lea    0x1(%edx),%esi
   19a3d:	0f b6 09             	movzbl (%ecx),%ecx
   19a40:	88 0a                	mov    %cl,(%edx)
		while( len-- ) {
   19a42:	89 c2                	mov    %eax,%edx
   19a44:	8d 42 ff             	lea    -0x1(%edx),%eax
   19a47:	85 d2                	test   %edx,%edx
   19a49:	75 e8                	jne    19a33 <umemmove+0x35>
		}
	}
}
   19a4b:	90                   	nop
   19a4c:	5b                   	pop    %ebx
   19a4d:	5e                   	pop    %esi
   19a4e:	5d                   	pop    %ebp
   19a4f:	c3                   	ret    

00019a50 <umemset>:
**
** @param buf    The buffer to initialize
** @param len    Buffer size (in bytes)
** @param value  Initialization value
*/
void umemset( void *buf, register uint32_t len, register uint32_t value ) {
   19a50:	55                   	push   %ebp
   19a51:	89 e5                	mov    %esp,%ebp
   19a53:	53                   	push   %ebx
   19a54:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register uint8_t *bp = buf;
   19a57:	8b 5d 08             	mov    0x8(%ebp),%ebx
	/*
	** We could speed this up by unrolling it and copying
	** words at a time (instead of bytes).
	*/

	while( len-- ) {
   19a5a:	eb 0b                	jmp    19a67 <umemset+0x17>
		*bp++ = value;
   19a5c:	89 d8                	mov    %ebx,%eax
   19a5e:	8d 58 01             	lea    0x1(%eax),%ebx
   19a61:	0f b6 55 10          	movzbl 0x10(%ebp),%edx
   19a65:	88 10                	mov    %dl,(%eax)
	while( len-- ) {
   19a67:	89 c8                	mov    %ecx,%eax
   19a69:	8d 48 ff             	lea    -0x1(%eax),%ecx
   19a6c:	85 c0                	test   %eax,%eax
   19a6e:	75 ec                	jne    19a5c <umemset+0xc>
	}
}
   19a70:	90                   	nop
   19a71:	5b                   	pop    %ebx
   19a72:	5d                   	pop    %ebp
   19a73:	c3                   	ret    

00019a74 <upad>:
**
** @return Pointer to the first byte after the padding
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *upad( char *dst, int extra, int padchar ) {
   19a74:	55                   	push   %ebp
   19a75:	89 e5                	mov    %esp,%ebp
	while( extra > 0 ){
   19a77:	eb 12                	jmp    19a8b <upad+0x17>
		*dst++ = (char) padchar;
   19a79:	8b 45 08             	mov    0x8(%ebp),%eax
   19a7c:	8d 50 01             	lea    0x1(%eax),%edx
   19a7f:	89 55 08             	mov    %edx,0x8(%ebp)
   19a82:	8b 55 10             	mov    0x10(%ebp),%edx
   19a85:	88 10                	mov    %dl,(%eax)
		extra -= 1;
   19a87:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
	while( extra > 0 ){
   19a8b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   19a8f:	7f e8                	jg     19a79 <upad+0x5>
	}
	return dst;
   19a91:	8b 45 08             	mov    0x8(%ebp),%eax
}
   19a94:	5d                   	pop    %ebp
   19a95:	c3                   	ret    

00019a96 <upadstr>:
** @return Pointer to the first byte after the padded string
**
** NOTE: does NOT NUL-terminate the buffer
*/
char *upadstr( char *dst, char *str, int len, int width,
				int leftadjust, int padchar ) {
   19a96:	55                   	push   %ebp
   19a97:	89 e5                	mov    %esp,%ebp
   19a99:	83 ec 18             	sub    $0x18,%esp
	int extra;

	// determine the length of the string if we need to
	if( len < 0 ){
   19a9c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
   19aa0:	79 11                	jns    19ab3 <upadstr+0x1d>
		len = ustrlen( str );
   19aa2:	83 ec 0c             	sub    $0xc,%esp
   19aa5:	ff 75 0c             	pushl  0xc(%ebp)
   19aa8:	e8 03 04 00 00       	call   19eb0 <ustrlen>
   19aad:	83 c4 10             	add    $0x10,%esp
   19ab0:	89 45 10             	mov    %eax,0x10(%ebp)
	}

	// how much filler must we add?
	extra = width - len;
   19ab3:	8b 45 14             	mov    0x14(%ebp),%eax
   19ab6:	2b 45 10             	sub    0x10(%ebp),%eax
   19ab9:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// add filler on the left if we're not left-justifying
	if( extra > 0 && !leftadjust ){
   19abc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   19ac0:	7e 1d                	jle    19adf <upadstr+0x49>
   19ac2:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   19ac6:	75 17                	jne    19adf <upadstr+0x49>
		dst = upad( dst, extra, padchar );
   19ac8:	83 ec 04             	sub    $0x4,%esp
   19acb:	ff 75 1c             	pushl  0x1c(%ebp)
   19ace:	ff 75 f0             	pushl  -0x10(%ebp)
   19ad1:	ff 75 08             	pushl  0x8(%ebp)
   19ad4:	e8 9b ff ff ff       	call   19a74 <upad>
   19ad9:	83 c4 10             	add    $0x10,%esp
   19adc:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	// copy the string itself
	for( int i = 0; i < len; ++i ) {
   19adf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
   19ae6:	eb 1b                	jmp    19b03 <upadstr+0x6d>
		*dst++ = str[i];
   19ae8:	8b 55 f4             	mov    -0xc(%ebp),%edx
   19aeb:	8b 45 0c             	mov    0xc(%ebp),%eax
   19aee:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
   19af1:	8b 45 08             	mov    0x8(%ebp),%eax
   19af4:	8d 50 01             	lea    0x1(%eax),%edx
   19af7:	89 55 08             	mov    %edx,0x8(%ebp)
   19afa:	0f b6 11             	movzbl (%ecx),%edx
   19afd:	88 10                	mov    %dl,(%eax)
	for( int i = 0; i < len; ++i ) {
   19aff:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
   19b03:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19b06:	3b 45 10             	cmp    0x10(%ebp),%eax
   19b09:	7c dd                	jl     19ae8 <upadstr+0x52>
	}

	// add filler on the right if we are left-justifying
	if( extra > 0 && leftadjust ){
   19b0b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   19b0f:	7e 1d                	jle    19b2e <upadstr+0x98>
   19b11:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
   19b15:	74 17                	je     19b2e <upadstr+0x98>
		dst = upad( dst, extra, padchar );
   19b17:	83 ec 04             	sub    $0x4,%esp
   19b1a:	ff 75 1c             	pushl  0x1c(%ebp)
   19b1d:	ff 75 f0             	pushl  -0x10(%ebp)
   19b20:	ff 75 08             	pushl  0x8(%ebp)
   19b23:	e8 4c ff ff ff       	call   19a74 <upad>
   19b28:	83 c4 10             	add    $0x10,%esp
   19b2b:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	return dst;
   19b2e:	8b 45 08             	mov    0x8(%ebp),%eax
}
   19b31:	c9                   	leave  
   19b32:	c3                   	ret    

00019b33 <usprint>:
**
** NOTE:  relies heavily on the x86 parameter passing convention
** (parameters are pushed onto the stack in reverse order as
** 32-bit values).
*/
void usprint( char *dst, char *fmt, ... ) {
   19b33:	55                   	push   %ebp
   19b34:	89 e5                	mov    %esp,%ebp
   19b36:	83 ec 38             	sub    $0x38,%esp
	** to point to the next "thing", and interpret it according
	** to the format string.
	*/
	
	// get the pointer to the first "value" parameter
	ap = (int *)(&fmt) + 1;
   19b39:	8d 45 0c             	lea    0xc(%ebp),%eax
   19b3c:	83 c0 04             	add    $0x4,%eax
   19b3f:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// iterate through the format string
	while( (ch = *fmt++) != '\0' ){
   19b42:	e9 3f 02 00 00       	jmp    19d86 <usprint+0x253>
		/*
		** Is it the start of a format code?
		*/
		if( ch == '%' ){
   19b47:	80 7d f3 25          	cmpb   $0x25,-0xd(%ebp)
   19b4b:	0f 85 26 02 00 00    	jne    19d77 <usprint+0x244>
			/*
			** Yes, get the padding and width options (if there).
			** Alignment must come at the beginning, then fill,
			** then width.
			*/
			leftadjust = 0;
   19b51:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
			padchar = ' ';
   19b58:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
			width = 0;
   19b5f:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
			ch = *fmt++;
   19b66:	8b 45 0c             	mov    0xc(%ebp),%eax
   19b69:	8d 50 01             	lea    0x1(%eax),%edx
   19b6c:	89 55 0c             	mov    %edx,0xc(%ebp)
   19b6f:	0f b6 00             	movzbl (%eax),%eax
   19b72:	88 45 f3             	mov    %al,-0xd(%ebp)
			if( ch == '-' ){
   19b75:	80 7d f3 2d          	cmpb   $0x2d,-0xd(%ebp)
   19b79:	75 16                	jne    19b91 <usprint+0x5e>
				leftadjust = 1;
   19b7b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
				ch = *fmt++;
   19b82:	8b 45 0c             	mov    0xc(%ebp),%eax
   19b85:	8d 50 01             	lea    0x1(%eax),%edx
   19b88:	89 55 0c             	mov    %edx,0xc(%ebp)
   19b8b:	0f b6 00             	movzbl (%eax),%eax
   19b8e:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			if( ch == '0' ){
   19b91:	80 7d f3 30          	cmpb   $0x30,-0xd(%ebp)
   19b95:	75 40                	jne    19bd7 <usprint+0xa4>
				padchar = '0';
   19b97:	c7 45 e4 30 00 00 00 	movl   $0x30,-0x1c(%ebp)
				ch = *fmt++;
   19b9e:	8b 45 0c             	mov    0xc(%ebp),%eax
   19ba1:	8d 50 01             	lea    0x1(%eax),%edx
   19ba4:	89 55 0c             	mov    %edx,0xc(%ebp)
   19ba7:	0f b6 00             	movzbl (%eax),%eax
   19baa:	88 45 f3             	mov    %al,-0xd(%ebp)
			}
			while( ch >= '0' && ch <= '9' ){
   19bad:	eb 28                	jmp    19bd7 <usprint+0xa4>
				width *= 10;
   19baf:	8b 55 e8             	mov    -0x18(%ebp),%edx
   19bb2:	89 d0                	mov    %edx,%eax
   19bb4:	c1 e0 02             	shl    $0x2,%eax
   19bb7:	01 d0                	add    %edx,%eax
   19bb9:	01 c0                	add    %eax,%eax
   19bbb:	89 45 e8             	mov    %eax,-0x18(%ebp)
				width += ch - '0';
   19bbe:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   19bc2:	83 e8 30             	sub    $0x30,%eax
   19bc5:	01 45 e8             	add    %eax,-0x18(%ebp)
				ch = *fmt++;
   19bc8:	8b 45 0c             	mov    0xc(%ebp),%eax
   19bcb:	8d 50 01             	lea    0x1(%eax),%edx
   19bce:	89 55 0c             	mov    %edx,0xc(%ebp)
   19bd1:	0f b6 00             	movzbl (%eax),%eax
   19bd4:	88 45 f3             	mov    %al,-0xd(%ebp)
			while( ch >= '0' && ch <= '9' ){
   19bd7:	80 7d f3 2f          	cmpb   $0x2f,-0xd(%ebp)
   19bdb:	7e 06                	jle    19be3 <usprint+0xb0>
   19bdd:	80 7d f3 39          	cmpb   $0x39,-0xd(%ebp)
   19be1:	7e cc                	jle    19baf <usprint+0x7c>
			}

			/*
			** What data type do we have?
			*/
			switch( ch ) {
   19be3:	0f be 45 f3          	movsbl -0xd(%ebp),%eax
   19be7:	83 e8 63             	sub    $0x63,%eax
   19bea:	83 f8 15             	cmp    $0x15,%eax
   19bed:	0f 87 93 01 00 00    	ja     19d86 <usprint+0x253>
   19bf3:	8b 04 85 88 be 01 00 	mov    0x1be88(,%eax,4),%eax
   19bfa:	ff e0                	jmp    *%eax

			case 'c':  // characters are passed as 32-bit values
				ch = *ap++;
   19bfc:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19bff:	8d 50 04             	lea    0x4(%eax),%edx
   19c02:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19c05:	8b 00                	mov    (%eax),%eax
   19c07:	88 45 f3             	mov    %al,-0xd(%ebp)
				buf[ 0 ] = ch;
   19c0a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
   19c0e:	88 45 d0             	mov    %al,-0x30(%ebp)
				buf[ 1 ] = '\0';
   19c11:	c6 45 d1 00          	movb   $0x0,-0x2f(%ebp)
				dst = upadstr( dst, buf, 1, width, leftadjust, padchar );
   19c15:	83 ec 08             	sub    $0x8,%esp
   19c18:	ff 75 e4             	pushl  -0x1c(%ebp)
   19c1b:	ff 75 ec             	pushl  -0x14(%ebp)
   19c1e:	ff 75 e8             	pushl  -0x18(%ebp)
   19c21:	6a 01                	push   $0x1
   19c23:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19c26:	50                   	push   %eax
   19c27:	ff 75 08             	pushl  0x8(%ebp)
   19c2a:	e8 67 fe ff ff       	call   19a96 <upadstr>
   19c2f:	83 c4 20             	add    $0x20,%esp
   19c32:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19c35:	e9 4c 01 00 00       	jmp    19d86 <usprint+0x253>

			case 'd':
				len = ucvtdec( buf, *ap++ );
   19c3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19c3d:	8d 50 04             	lea    0x4(%eax),%edx
   19c40:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19c43:	8b 00                	mov    (%eax),%eax
   19c45:	83 ec 08             	sub    $0x8,%esp
   19c48:	50                   	push   %eax
   19c49:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19c4c:	50                   	push   %eax
   19c4d:	e8 a4 02 00 00       	call   19ef6 <ucvtdec>
   19c52:	83 c4 10             	add    $0x10,%esp
   19c55:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = upadstr( dst, buf, len, width, leftadjust, padchar );
   19c58:	83 ec 08             	sub    $0x8,%esp
   19c5b:	ff 75 e4             	pushl  -0x1c(%ebp)
   19c5e:	ff 75 ec             	pushl  -0x14(%ebp)
   19c61:	ff 75 e8             	pushl  -0x18(%ebp)
   19c64:	ff 75 e0             	pushl  -0x20(%ebp)
   19c67:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19c6a:	50                   	push   %eax
   19c6b:	ff 75 08             	pushl  0x8(%ebp)
   19c6e:	e8 23 fe ff ff       	call   19a96 <upadstr>
   19c73:	83 c4 20             	add    $0x20,%esp
   19c76:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19c79:	e9 08 01 00 00       	jmp    19d86 <usprint+0x253>

			case 's':
				str = (char *) (*ap++);
   19c7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19c81:	8d 50 04             	lea    0x4(%eax),%edx
   19c84:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19c87:	8b 00                	mov    (%eax),%eax
   19c89:	89 45 dc             	mov    %eax,-0x24(%ebp)
				dst = upadstr( dst, str, -1, width, leftadjust, padchar );
   19c8c:	83 ec 08             	sub    $0x8,%esp
   19c8f:	ff 75 e4             	pushl  -0x1c(%ebp)
   19c92:	ff 75 ec             	pushl  -0x14(%ebp)
   19c95:	ff 75 e8             	pushl  -0x18(%ebp)
   19c98:	6a ff                	push   $0xffffffff
   19c9a:	ff 75 dc             	pushl  -0x24(%ebp)
   19c9d:	ff 75 08             	pushl  0x8(%ebp)
   19ca0:	e8 f1 fd ff ff       	call   19a96 <upadstr>
   19ca5:	83 c4 20             	add    $0x20,%esp
   19ca8:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19cab:	e9 d6 00 00 00       	jmp    19d86 <usprint+0x253>

			case 'x':
				len = ucvthex( buf, *ap++ );
   19cb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19cb3:	8d 50 04             	lea    0x4(%eax),%edx
   19cb6:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19cb9:	8b 00                	mov    (%eax),%eax
   19cbb:	83 ec 08             	sub    $0x8,%esp
   19cbe:	50                   	push   %eax
   19cbf:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19cc2:	50                   	push   %eax
   19cc3:	e8 fe 02 00 00       	call   19fc6 <ucvthex>
   19cc8:	83 c4 10             	add    $0x10,%esp
   19ccb:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = upadstr( dst, buf, len, width, leftadjust, padchar );
   19cce:	83 ec 08             	sub    $0x8,%esp
   19cd1:	ff 75 e4             	pushl  -0x1c(%ebp)
   19cd4:	ff 75 ec             	pushl  -0x14(%ebp)
   19cd7:	ff 75 e8             	pushl  -0x18(%ebp)
   19cda:	ff 75 e0             	pushl  -0x20(%ebp)
   19cdd:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19ce0:	50                   	push   %eax
   19ce1:	ff 75 08             	pushl  0x8(%ebp)
   19ce4:	e8 ad fd ff ff       	call   19a96 <upadstr>
   19ce9:	83 c4 20             	add    $0x20,%esp
   19cec:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19cef:	e9 92 00 00 00       	jmp    19d86 <usprint+0x253>

			case 'o':
				len = ucvtoct( buf, *ap++ );
   19cf4:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19cf7:	8d 50 04             	lea    0x4(%eax),%edx
   19cfa:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19cfd:	8b 00                	mov    (%eax),%eax
   19cff:	83 ec 08             	sub    $0x8,%esp
   19d02:	50                   	push   %eax
   19d03:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19d06:	50                   	push   %eax
   19d07:	e8 44 03 00 00       	call   1a050 <ucvtoct>
   19d0c:	83 c4 10             	add    $0x10,%esp
   19d0f:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = upadstr( dst, buf, len, width, leftadjust, padchar );
   19d12:	83 ec 08             	sub    $0x8,%esp
   19d15:	ff 75 e4             	pushl  -0x1c(%ebp)
   19d18:	ff 75 ec             	pushl  -0x14(%ebp)
   19d1b:	ff 75 e8             	pushl  -0x18(%ebp)
   19d1e:	ff 75 e0             	pushl  -0x20(%ebp)
   19d21:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19d24:	50                   	push   %eax
   19d25:	ff 75 08             	pushl  0x8(%ebp)
   19d28:	e8 69 fd ff ff       	call   19a96 <upadstr>
   19d2d:	83 c4 20             	add    $0x20,%esp
   19d30:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19d33:	eb 51                	jmp    19d86 <usprint+0x253>

			case 'u':
				len = ucvtuns( buf, *ap++ );
   19d35:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19d38:	8d 50 04             	lea    0x4(%eax),%edx
   19d3b:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19d3e:	8b 00                	mov    (%eax),%eax
   19d40:	83 ec 08             	sub    $0x8,%esp
   19d43:	50                   	push   %eax
   19d44:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19d47:	50                   	push   %eax
   19d48:	e8 8d 03 00 00       	call   1a0da <ucvtuns>
   19d4d:	83 c4 10             	add    $0x10,%esp
   19d50:	89 45 e0             	mov    %eax,-0x20(%ebp)
				dst = upadstr( dst, buf, len, width, leftadjust, padchar );
   19d53:	83 ec 08             	sub    $0x8,%esp
   19d56:	ff 75 e4             	pushl  -0x1c(%ebp)
   19d59:	ff 75 ec             	pushl  -0x14(%ebp)
   19d5c:	ff 75 e8             	pushl  -0x18(%ebp)
   19d5f:	ff 75 e0             	pushl  -0x20(%ebp)
   19d62:	8d 45 d0             	lea    -0x30(%ebp),%eax
   19d65:	50                   	push   %eax
   19d66:	ff 75 08             	pushl  0x8(%ebp)
   19d69:	e8 28 fd ff ff       	call   19a96 <upadstr>
   19d6e:	83 c4 20             	add    $0x20,%esp
   19d71:	89 45 08             	mov    %eax,0x8(%ebp)
				break;
   19d74:	90                   	nop
   19d75:	eb 0f                	jmp    19d86 <usprint+0x253>

			}
		} else {
			// no, it's just an ordinary character
			*dst++ = ch;
   19d77:	8b 45 08             	mov    0x8(%ebp),%eax
   19d7a:	8d 50 01             	lea    0x1(%eax),%edx
   19d7d:	89 55 08             	mov    %edx,0x8(%ebp)
   19d80:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
   19d84:	88 10                	mov    %dl,(%eax)
	while( (ch = *fmt++) != '\0' ){
   19d86:	8b 45 0c             	mov    0xc(%ebp),%eax
   19d89:	8d 50 01             	lea    0x1(%eax),%edx
   19d8c:	89 55 0c             	mov    %edx,0xc(%ebp)
   19d8f:	0f b6 00             	movzbl (%eax),%eax
   19d92:	88 45 f3             	mov    %al,-0xd(%ebp)
   19d95:	80 7d f3 00          	cmpb   $0x0,-0xd(%ebp)
   19d99:	0f 85 a8 fd ff ff    	jne    19b47 <usprint+0x14>
		}
	}

	// NUL-terminate the result
	*dst = '\0';
   19d9f:	8b 45 08             	mov    0x8(%ebp),%eax
   19da2:	c6 00 00             	movb   $0x0,(%eax)
}
   19da5:	90                   	nop
   19da6:	c9                   	leave  
   19da7:	c3                   	ret    

00019da8 <ustr2int>:
** @param str   The string to examine
** @param base  The radix to use in the conversion
**
** @return The converted integer
*/
int ustr2int( register const char *str, register int base ) {
   19da8:	55                   	push   %ebp
   19da9:	89 e5                	mov    %esp,%ebp
   19dab:	53                   	push   %ebx
   19dac:	83 ec 14             	sub    $0x14,%esp
   19daf:	8b 45 08             	mov    0x8(%ebp),%eax
   19db2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	register int num = 0;
   19db5:	bb 00 00 00 00       	mov    $0x0,%ebx
	register char bchar = '9';
   19dba:	c6 45 eb 39          	movb   $0x39,-0x15(%ebp)
	int sign = 1;
   19dbe:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)

	// check for leading '-'
	if( *str == '-' ) {
   19dc5:	0f b6 10             	movzbl (%eax),%edx
   19dc8:	80 fa 2d             	cmp    $0x2d,%dl
   19dcb:	75 0a                	jne    19dd7 <ustr2int+0x2f>
		sign = -1;
   19dcd:	c7 45 f8 ff ff ff ff 	movl   $0xffffffff,-0x8(%ebp)
		++str;
   19dd4:	83 c0 01             	add    $0x1,%eax
	}

	if( base != 10 ) {
   19dd7:	83 f9 0a             	cmp    $0xa,%ecx
   19dda:	74 2b                	je     19e07 <ustr2int+0x5f>
		bchar = '0' + base - 1;
   19ddc:	89 ca                	mov    %ecx,%edx
   19dde:	83 c2 2f             	add    $0x2f,%edx
   19de1:	88 55 eb             	mov    %dl,-0x15(%ebp)
	}

	// iterate through the characters
	while( *str ) {
   19de4:	eb 21                	jmp    19e07 <ustr2int+0x5f>
		if( *str < '0' || *str > bchar )
   19de6:	0f b6 10             	movzbl (%eax),%edx
   19de9:	80 fa 2f             	cmp    $0x2f,%dl
   19dec:	7e 20                	jle    19e0e <ustr2int+0x66>
   19dee:	0f b6 10             	movzbl (%eax),%edx
   19df1:	38 55 eb             	cmp    %dl,-0x15(%ebp)
   19df4:	7c 18                	jl     19e0e <ustr2int+0x66>
			break;
		num = num * base + *str - '0';
   19df6:	0f af d9             	imul   %ecx,%ebx
   19df9:	0f b6 10             	movzbl (%eax),%edx
   19dfc:	0f be d2             	movsbl %dl,%edx
   19dff:	01 da                	add    %ebx,%edx
   19e01:	8d 5a d0             	lea    -0x30(%edx),%ebx
		++str;
   19e04:	83 c0 01             	add    $0x1,%eax
	while( *str ) {
   19e07:	0f b6 10             	movzbl (%eax),%edx
   19e0a:	84 d2                	test   %dl,%dl
   19e0c:	75 d8                	jne    19de6 <ustr2int+0x3e>
	}

	// return the converted value
	return( num * sign );
   19e0e:	89 d8                	mov    %ebx,%eax
   19e10:	0f af 45 f8          	imul   -0x8(%ebp),%eax
}
   19e14:	83 c4 14             	add    $0x14,%esp
   19e17:	5b                   	pop    %ebx
   19e18:	5d                   	pop    %ebp
   19e19:	c3                   	ret    

00019e1a <ustrcat>:
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the resulting string
*/
char *ustrcat( register char *dst, register const char *src ) {
   19e1a:	55                   	push   %ebp
   19e1b:	89 e5                	mov    %esp,%ebp
   19e1d:	56                   	push   %esi
   19e1e:	53                   	push   %ebx
   19e1f:	8b 45 08             	mov    0x8(%ebp),%eax
   19e22:	8b 75 0c             	mov    0xc(%ebp),%esi
	register char *tmp = dst;
   19e25:	89 c3                	mov    %eax,%ebx

	while( *dst )  // find the NUL
   19e27:	eb 03                	jmp    19e2c <ustrcat+0x12>
		++dst;
   19e29:	83 c0 01             	add    $0x1,%eax
	while( *dst )  // find the NUL
   19e2c:	0f b6 10             	movzbl (%eax),%edx
   19e2f:	84 d2                	test   %dl,%dl
   19e31:	75 f6                	jne    19e29 <ustrcat+0xf>

	while( (*dst++ = *src++) )  // append the src string
   19e33:	90                   	nop
   19e34:	89 f1                	mov    %esi,%ecx
   19e36:	8d 71 01             	lea    0x1(%ecx),%esi
   19e39:	89 c2                	mov    %eax,%edx
   19e3b:	8d 42 01             	lea    0x1(%edx),%eax
   19e3e:	0f b6 09             	movzbl (%ecx),%ecx
   19e41:	88 0a                	mov    %cl,(%edx)
   19e43:	0f b6 12             	movzbl (%edx),%edx
   19e46:	84 d2                	test   %dl,%dl
   19e48:	75 ea                	jne    19e34 <ustrcat+0x1a>
		;

	return( tmp );
   19e4a:	89 d8                	mov    %ebx,%eax
}
   19e4c:	5b                   	pop    %ebx
   19e4d:	5e                   	pop    %esi
   19e4e:	5d                   	pop    %ebp
   19e4f:	c3                   	ret    

00019e50 <ustrcmp>:
** @param s1 The first source string
** @param s2 The second source string
**
** @return negative if s1 < s2, zero if equal, and positive if s1 > s2
*/
int ustrcmp( register const char *s1, register const char *s2 ) {
   19e50:	55                   	push   %ebp
   19e51:	89 e5                	mov    %esp,%ebp
   19e53:	53                   	push   %ebx
   19e54:	8b 45 08             	mov    0x8(%ebp),%eax
   19e57:	8b 55 0c             	mov    0xc(%ebp),%edx

	while( *s1 != 0 && (*s1 == *s2) )
   19e5a:	eb 06                	jmp    19e62 <ustrcmp+0x12>
		++s1, ++s2;
   19e5c:	83 c0 01             	add    $0x1,%eax
   19e5f:	83 c2 01             	add    $0x1,%edx
	while( *s1 != 0 && (*s1 == *s2) )
   19e62:	0f b6 08             	movzbl (%eax),%ecx
   19e65:	84 c9                	test   %cl,%cl
   19e67:	74 0a                	je     19e73 <ustrcmp+0x23>
   19e69:	0f b6 18             	movzbl (%eax),%ebx
   19e6c:	0f b6 0a             	movzbl (%edx),%ecx
   19e6f:	38 cb                	cmp    %cl,%bl
   19e71:	74 e9                	je     19e5c <ustrcmp+0xc>

	return( *s1 - *s2 );
   19e73:	0f b6 00             	movzbl (%eax),%eax
   19e76:	0f be c8             	movsbl %al,%ecx
   19e79:	0f b6 02             	movzbl (%edx),%eax
   19e7c:	0f be c0             	movsbl %al,%eax
   19e7f:	29 c1                	sub    %eax,%ecx
   19e81:	89 c8                	mov    %ecx,%eax
}
   19e83:	5b                   	pop    %ebx
   19e84:	5d                   	pop    %ebp
   19e85:	c3                   	ret    

00019e86 <ustrcpy>:
**
** @return The dst parameter
**
** NOTE:  assumes dst is large enough to hold the copied string
*/
char *ustrcpy( register char *dst, register const char *src ) {
   19e86:	55                   	push   %ebp
   19e87:	89 e5                	mov    %esp,%ebp
   19e89:	56                   	push   %esi
   19e8a:	53                   	push   %ebx
   19e8b:	8b 4d 08             	mov    0x8(%ebp),%ecx
   19e8e:	8b 75 0c             	mov    0xc(%ebp),%esi
	register char *tmp = dst;
   19e91:	89 cb                	mov    %ecx,%ebx

	while( (*dst++ = *src++) )
   19e93:	90                   	nop
   19e94:	89 f2                	mov    %esi,%edx
   19e96:	8d 72 01             	lea    0x1(%edx),%esi
   19e99:	89 c8                	mov    %ecx,%eax
   19e9b:	8d 48 01             	lea    0x1(%eax),%ecx
   19e9e:	0f b6 12             	movzbl (%edx),%edx
   19ea1:	88 10                	mov    %dl,(%eax)
   19ea3:	0f b6 00             	movzbl (%eax),%eax
   19ea6:	84 c0                	test   %al,%al
   19ea8:	75 ea                	jne    19e94 <ustrcpy+0xe>
		;

	return( tmp );
   19eaa:	89 d8                	mov    %ebx,%eax
}
   19eac:	5b                   	pop    %ebx
   19ead:	5e                   	pop    %esi
   19eae:	5d                   	pop    %ebp
   19eaf:	c3                   	ret    

00019eb0 <ustrlen>:
**
** @param str The string to examine
**
** @return The length of the string, or 0
*/
uint32_t ustrlen( register const char *str ) {
   19eb0:	55                   	push   %ebp
   19eb1:	89 e5                	mov    %esp,%ebp
   19eb3:	53                   	push   %ebx
   19eb4:	8b 55 08             	mov    0x8(%ebp),%edx
	register uint32_t len = 0;
   19eb7:	bb 00 00 00 00       	mov    $0x0,%ebx

	while( *str++ ) {
   19ebc:	eb 03                	jmp    19ec1 <ustrlen+0x11>
		++len;
   19ebe:	83 c3 01             	add    $0x1,%ebx
	while( *str++ ) {
   19ec1:	89 d0                	mov    %edx,%eax
   19ec3:	8d 50 01             	lea    0x1(%eax),%edx
   19ec6:	0f b6 00             	movzbl (%eax),%eax
   19ec9:	84 c0                	test   %al,%al
   19ecb:	75 f1                	jne    19ebe <ustrlen+0xe>
	}

	return( len );
   19ecd:	89 d8                	mov    %ebx,%eax
}
   19ecf:	5b                   	pop    %ebx
   19ed0:	5d                   	pop    %ebp
   19ed1:	c3                   	ret    

00019ed2 <ubound>:
** @param value  Value to be constrained
** @param max    Upper bound
**
** @return The constrained value
*/
uint32_t ubound( uint32_t min, uint32_t value, uint32_t max ) {
   19ed2:	55                   	push   %ebp
   19ed3:	89 e5                	mov    %esp,%ebp
	if( value < min ){
   19ed5:	8b 45 0c             	mov    0xc(%ebp),%eax
   19ed8:	3b 45 08             	cmp    0x8(%ebp),%eax
   19edb:	73 06                	jae    19ee3 <ubound+0x11>
		value = min;
   19edd:	8b 45 08             	mov    0x8(%ebp),%eax
   19ee0:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	if( value > max ){
   19ee3:	8b 45 0c             	mov    0xc(%ebp),%eax
   19ee6:	3b 45 10             	cmp    0x10(%ebp),%eax
   19ee9:	76 06                	jbe    19ef1 <ubound+0x1f>
		value = max;
   19eeb:	8b 45 10             	mov    0x10(%ebp),%eax
   19eee:	89 45 0c             	mov    %eax,0xc(%ebp)
	}
	return value;
   19ef1:	8b 45 0c             	mov    0xc(%ebp),%eax
}
   19ef4:	5d                   	pop    %ebp
   19ef5:	c3                   	ret    

00019ef6 <ucvtdec>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int ucvtdec( char *buf, int32_t value ) {
   19ef6:	55                   	push   %ebp
   19ef7:	89 e5                	mov    %esp,%ebp
   19ef9:	83 ec 18             	sub    $0x18,%esp
	char *bp = buf;
   19efc:	8b 45 08             	mov    0x8(%ebp),%eax
   19eff:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if( value < 0 ) {
   19f02:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
   19f06:	79 0f                	jns    19f17 <ucvtdec+0x21>
		*bp++ = '-';
   19f08:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19f0b:	8d 50 01             	lea    0x1(%eax),%edx
   19f0e:	89 55 f4             	mov    %edx,-0xc(%ebp)
   19f11:	c6 00 2d             	movb   $0x2d,(%eax)
		value = -value;
   19f14:	f7 5d 0c             	negl   0xc(%ebp)
	}

	bp = ucvtdec0( bp, value );
   19f17:	83 ec 08             	sub    $0x8,%esp
   19f1a:	ff 75 0c             	pushl  0xc(%ebp)
   19f1d:	ff 75 f4             	pushl  -0xc(%ebp)
   19f20:	e8 18 00 00 00       	call   19f3d <ucvtdec0>
   19f25:	83 c4 10             	add    $0x10,%esp
   19f28:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp  = '\0';
   19f2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
   19f2e:	c6 00 00             	movb   $0x0,(%eax)

	return( bp - buf );
   19f31:	8b 55 f4             	mov    -0xc(%ebp),%edx
   19f34:	8b 45 08             	mov    0x8(%ebp),%eax
   19f37:	29 c2                	sub    %eax,%edx
   19f39:	89 d0                	mov    %edx,%eax
}
   19f3b:	c9                   	leave  
   19f3c:	c3                   	ret    

00019f3d <ucvtdec0>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *ucvtdec0( char *buf, int value ) {
   19f3d:	55                   	push   %ebp
   19f3e:	89 e5                	mov    %esp,%ebp
   19f40:	83 ec 18             	sub    $0x18,%esp
	int quotient;

	quotient = value / 10;
   19f43:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   19f46:	ba 67 66 66 66       	mov    $0x66666667,%edx
   19f4b:	89 c8                	mov    %ecx,%eax
   19f4d:	f7 ea                	imul   %edx
   19f4f:	c1 fa 02             	sar    $0x2,%edx
   19f52:	89 c8                	mov    %ecx,%eax
   19f54:	c1 f8 1f             	sar    $0x1f,%eax
   19f57:	29 c2                	sub    %eax,%edx
   19f59:	89 d0                	mov    %edx,%eax
   19f5b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient < 0 ) {
   19f5e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   19f62:	79 0e                	jns    19f72 <ucvtdec0+0x35>
		quotient = 214748364;
   19f64:	c7 45 f4 cc cc cc 0c 	movl   $0xccccccc,-0xc(%ebp)
		value = 8;
   19f6b:	c7 45 0c 08 00 00 00 	movl   $0x8,0xc(%ebp)
	}
	if( quotient != 0 ) {
   19f72:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   19f76:	74 14                	je     19f8c <ucvtdec0+0x4f>
		buf = ucvtdec0( buf, quotient );
   19f78:	83 ec 08             	sub    $0x8,%esp
   19f7b:	ff 75 f4             	pushl  -0xc(%ebp)
   19f7e:	ff 75 08             	pushl  0x8(%ebp)
   19f81:	e8 b7 ff ff ff       	call   19f3d <ucvtdec0>
   19f86:	83 c4 10             	add    $0x10,%esp
   19f89:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   19f8c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   19f8f:	ba 67 66 66 66       	mov    $0x66666667,%edx
   19f94:	89 c8                	mov    %ecx,%eax
   19f96:	f7 ea                	imul   %edx
   19f98:	c1 fa 02             	sar    $0x2,%edx
   19f9b:	89 c8                	mov    %ecx,%eax
   19f9d:	c1 f8 1f             	sar    $0x1f,%eax
   19fa0:	29 c2                	sub    %eax,%edx
   19fa2:	89 d0                	mov    %edx,%eax
   19fa4:	c1 e0 02             	shl    $0x2,%eax
   19fa7:	01 d0                	add    %edx,%eax
   19fa9:	01 c0                	add    %eax,%eax
   19fab:	29 c1                	sub    %eax,%ecx
   19fad:	89 ca                	mov    %ecx,%edx
   19faf:	89 d0                	mov    %edx,%eax
   19fb1:	8d 48 30             	lea    0x30(%eax),%ecx
   19fb4:	8b 45 08             	mov    0x8(%ebp),%eax
   19fb7:	8d 50 01             	lea    0x1(%eax),%edx
   19fba:	89 55 08             	mov    %edx,0x8(%ebp)
   19fbd:	89 ca                	mov    %ecx,%edx
   19fbf:	88 10                	mov    %dl,(%eax)
	return buf;
   19fc1:	8b 45 08             	mov    0x8(%ebp),%eax
}
   19fc4:	c9                   	leave  
   19fc5:	c3                   	ret    

00019fc6 <ucvthex>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int ucvthex( char *buf, uint32_t value ) {
   19fc6:	55                   	push   %ebp
   19fc7:	89 e5                	mov    %esp,%ebp
   19fc9:	83 ec 20             	sub    $0x20,%esp
	const char hexdigits[] = "0123456789ABCDEF";
   19fcc:	c7 45 e3 30 31 32 33 	movl   $0x33323130,-0x1d(%ebp)
   19fd3:	c7 45 e7 34 35 36 37 	movl   $0x37363534,-0x19(%ebp)
   19fda:	c7 45 eb 38 39 41 42 	movl   $0x42413938,-0x15(%ebp)
   19fe1:	c7 45 ef 43 44 45 46 	movl   $0x46454443,-0x11(%ebp)
   19fe8:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)
	int chars_stored = 0;
   19fec:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)

	for( int i = 0; i < 8; i += 1 ) {
   19ff3:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
   19ffa:	eb 43                	jmp    1a03f <ucvthex+0x79>
		uint32_t val = value & 0xf0000000;
   19ffc:	8b 45 0c             	mov    0xc(%ebp),%eax
   19fff:	25 00 00 00 f0       	and    $0xf0000000,%eax
   1a004:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if( chars_stored || val != 0 || i == 7 ) {
   1a007:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
   1a00b:	75 0c                	jne    1a019 <ucvthex+0x53>
   1a00d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a011:	75 06                	jne    1a019 <ucvthex+0x53>
   1a013:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   1a017:	75 1e                	jne    1a037 <ucvthex+0x71>
			++chars_stored;
   1a019:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
			val = (val >> 28) & 0xf;
   1a01d:	c1 6d f4 1c          	shrl   $0x1c,-0xc(%ebp)
			*buf++ = hexdigits[val];
   1a021:	8b 45 08             	mov    0x8(%ebp),%eax
   1a024:	8d 50 01             	lea    0x1(%eax),%edx
   1a027:	89 55 08             	mov    %edx,0x8(%ebp)
   1a02a:	8d 4d e3             	lea    -0x1d(%ebp),%ecx
   1a02d:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1a030:	01 ca                	add    %ecx,%edx
   1a032:	0f b6 12             	movzbl (%edx),%edx
   1a035:	88 10                	mov    %dl,(%eax)
		}
		value <<= 4;
   1a037:	c1 65 0c 04          	shll   $0x4,0xc(%ebp)
	for( int i = 0; i < 8; i += 1 ) {
   1a03b:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
   1a03f:	83 7d f8 07          	cmpl   $0x7,-0x8(%ebp)
   1a043:	7e b7                	jle    19ffc <ucvthex+0x36>
	}

	*buf = '\0';
   1a045:	8b 45 08             	mov    0x8(%ebp),%eax
   1a048:	c6 00 00             	movb   $0x0,(%eax)

	return( chars_stored );
   1a04b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
   1a04e:	c9                   	leave  
   1a04f:	c3                   	ret    

0001a050 <ucvtoct>:
** @return The number of characters placed into the buffer
**          (not including the NUL)
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int ucvtoct( char *buf, uint32_t value ) {
   1a050:	55                   	push   %ebp
   1a051:	89 e5                	mov    %esp,%ebp
   1a053:	83 ec 10             	sub    $0x10,%esp
	int i;
	int chars_stored = 0;
   1a056:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	char *bp = buf;
   1a05d:	8b 45 08             	mov    0x8(%ebp),%eax
   1a060:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32_t val;

	val = ( value & 0xc0000000 );
   1a063:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a066:	25 00 00 00 c0       	and    $0xc0000000,%eax
   1a06b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	val >>= 30;
   1a06e:	c1 6d f0 1e          	shrl   $0x1e,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   1a072:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
   1a079:	eb 47                	jmp    1a0c2 <ucvtoct+0x72>

		if( i == 10 || val != 0 || chars_stored ) {
   1a07b:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   1a07f:	74 0c                	je     1a08d <ucvtoct+0x3d>
   1a081:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
   1a085:	75 06                	jne    1a08d <ucvtoct+0x3d>
   1a087:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
   1a08b:	74 1e                	je     1a0ab <ucvtoct+0x5b>
			chars_stored = 1;
   1a08d:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)
			val &= 0x7;
   1a094:	83 65 f0 07          	andl   $0x7,-0x10(%ebp)
			*bp++ = val + '0';
   1a098:	8b 45 f0             	mov    -0x10(%ebp),%eax
   1a09b:	8d 48 30             	lea    0x30(%eax),%ecx
   1a09e:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a0a1:	8d 50 01             	lea    0x1(%eax),%edx
   1a0a4:	89 55 f4             	mov    %edx,-0xc(%ebp)
   1a0a7:	89 ca                	mov    %ecx,%edx
   1a0a9:	88 10                	mov    %dl,(%eax)
		}
		value <<= 3;
   1a0ab:	c1 65 0c 03          	shll   $0x3,0xc(%ebp)
		val = ( value & 0xe0000000 );
   1a0af:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a0b2:	25 00 00 00 e0       	and    $0xe0000000,%eax
   1a0b7:	89 45 f0             	mov    %eax,-0x10(%ebp)
		val >>= 29;
   1a0ba:	c1 6d f0 1d          	shrl   $0x1d,-0x10(%ebp)
	for( i = 0; i < 11; i += 1 ){
   1a0be:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
   1a0c2:	83 7d fc 0a          	cmpl   $0xa,-0x4(%ebp)
   1a0c6:	7e b3                	jle    1a07b <ucvtoct+0x2b>
	}
	*bp = '\0';
   1a0c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a0cb:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   1a0ce:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1a0d1:	8b 45 08             	mov    0x8(%ebp),%eax
   1a0d4:	29 c2                	sub    %eax,%edx
   1a0d6:	89 d0                	mov    %edx,%eax
}
   1a0d8:	c9                   	leave  
   1a0d9:	c3                   	ret    

0001a0da <ucvtuns>:
**
** @return Length of the resulting buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
int ucvtuns( char *buf, uint32_t value ) {
   1a0da:	55                   	push   %ebp
   1a0db:	89 e5                	mov    %esp,%ebp
   1a0dd:	83 ec 18             	sub    $0x18,%esp
	char    *bp = buf;
   1a0e0:	8b 45 08             	mov    0x8(%ebp),%eax
   1a0e3:	89 45 f4             	mov    %eax,-0xc(%ebp)

	bp = ucvtuns0( bp, value );
   1a0e6:	83 ec 08             	sub    $0x8,%esp
   1a0e9:	ff 75 0c             	pushl  0xc(%ebp)
   1a0ec:	ff 75 f4             	pushl  -0xc(%ebp)
   1a0ef:	e8 18 00 00 00       	call   1a10c <ucvtuns0>
   1a0f4:	83 c4 10             	add    $0x10,%esp
   1a0f7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	*bp = '\0';
   1a0fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a0fd:	c6 00 00             	movb   $0x0,(%eax)

	return bp - buf;
   1a100:	8b 55 f4             	mov    -0xc(%ebp),%edx
   1a103:	8b 45 08             	mov    0x8(%ebp),%eax
   1a106:	29 c2                	sub    %eax,%edx
   1a108:	89 d0                	mov    %edx,%eax
}
   1a10a:	c9                   	leave  
   1a10b:	c3                   	ret    

0001a10c <ucvtuns0>:
**
** @return Pointer to the first unused byte in the buffer
**
** NOTE:  assumes buf is large enough to hold the resulting string
*/
char *ucvtuns0( char *buf, uint32_t value ) {
   1a10c:	55                   	push   %ebp
   1a10d:	89 e5                	mov    %esp,%ebp
   1a10f:	83 ec 18             	sub    $0x18,%esp
	uint32_t quotient;

	quotient = value / 10;
   1a112:	8b 45 0c             	mov    0xc(%ebp),%eax
   1a115:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   1a11a:	f7 e2                	mul    %edx
   1a11c:	89 d0                	mov    %edx,%eax
   1a11e:	c1 e8 03             	shr    $0x3,%eax
   1a121:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( quotient != 0 ){
   1a124:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a128:	74 15                	je     1a13f <ucvtuns0+0x33>
		buf = ucvtdec0( buf, quotient );
   1a12a:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a12d:	83 ec 08             	sub    $0x8,%esp
   1a130:	50                   	push   %eax
   1a131:	ff 75 08             	pushl  0x8(%ebp)
   1a134:	e8 04 fe ff ff       	call   19f3d <ucvtdec0>
   1a139:	83 c4 10             	add    $0x10,%esp
   1a13c:	89 45 08             	mov    %eax,0x8(%ebp)
	}
	*buf++ = value % 10 + '0';
   1a13f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
   1a142:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
   1a147:	89 c8                	mov    %ecx,%eax
   1a149:	f7 e2                	mul    %edx
   1a14b:	c1 ea 03             	shr    $0x3,%edx
   1a14e:	89 d0                	mov    %edx,%eax
   1a150:	c1 e0 02             	shl    $0x2,%eax
   1a153:	01 d0                	add    %edx,%eax
   1a155:	01 c0                	add    %eax,%eax
   1a157:	29 c1                	sub    %eax,%ecx
   1a159:	89 ca                	mov    %ecx,%edx
   1a15b:	89 d0                	mov    %edx,%eax
   1a15d:	8d 48 30             	lea    0x30(%eax),%ecx
   1a160:	8b 45 08             	mov    0x8(%ebp),%eax
   1a163:	8d 50 01             	lea    0x1(%eax),%edx
   1a166:	89 55 08             	mov    %edx,0x8(%ebp)
   1a169:	89 ca                	mov    %ecx,%edx
   1a16b:	88 10                	mov    %dl,(%eax)
	return buf;
   1a16d:	8b 45 08             	mov    0x8(%ebp),%eax
}
   1a170:	c9                   	leave  
   1a171:	c3                   	ret    

0001a172 <wait>:
** @param status Pointer to int32_t into which the child's status is placed,
**               or NULL
**
** @returns The PID of the terminated child, or an error code
*/
int wait( int32_t *status ) {
   1a172:	55                   	push   %ebp
   1a173:	89 e5                	mov    %esp,%ebp
   1a175:	83 ec 08             	sub    $0x8,%esp
	return( waitpid(0,status) );
   1a178:	83 ec 08             	sub    $0x8,%esp
   1a17b:	ff 75 08             	pushl  0x8(%ebp)
   1a17e:	6a 00                	push   $0x0
   1a180:	e8 0c cc ff ff       	call   16d91 <waitpid>
   1a185:	83 c4 10             	add    $0x10,%esp
}
   1a188:	c9                   	leave  
   1a189:	c3                   	ret    

0001a18a <spawn>:
** @param entry The entry point of the 'main' function for the process
** @param args  The command-line argument vector for the new process
**
** @returns PID of the new process, or an error code
*/
int32_t spawn( uint32_t entry, char **args ) {
   1a18a:	55                   	push   %ebp
   1a18b:	89 e5                	mov    %esp,%ebp
   1a18d:	81 ec 18 01 00 00    	sub    $0x118,%esp
	int32_t pid;
	char buf[256];

	pid = fork();
   1a193:	e8 01 cc ff ff       	call   16d99 <fork>
   1a198:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( pid != 0 ) {
   1a19b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
   1a19f:	74 05                	je     1a1a6 <spawn+0x1c>
		// failure, or we are the parent
		return( pid );
   1a1a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a1a4:	eb 57                	jmp    1a1fd <spawn+0x73>
	}

	// we are the child
	pid = getpid();
   1a1a6:	e8 0e cc ff ff       	call   16db9 <getpid>
   1a1ab:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// child inherits parent's priority level

	exec( entry, args );
   1a1ae:	83 ec 08             	sub    $0x8,%esp
   1a1b1:	ff 75 0c             	pushl  0xc(%ebp)
   1a1b4:	ff 75 08             	pushl  0x8(%ebp)
   1a1b7:	e8 e5 cb ff ff       	call   16da1 <exec>
   1a1bc:	83 c4 10             	add    $0x10,%esp

	// uh-oh....

	usprint( buf, "Child %d exec() %08x failed\n", pid, entry );
   1a1bf:	ff 75 08             	pushl  0x8(%ebp)
   1a1c2:	ff 75 f4             	pushl  -0xc(%ebp)
   1a1c5:	68 e0 be 01 00       	push   $0x1bee0
   1a1ca:	8d 85 f4 fe ff ff    	lea    -0x10c(%ebp),%eax
   1a1d0:	50                   	push   %eax
   1a1d1:	e8 5d f9 ff ff       	call   19b33 <usprint>
   1a1d6:	83 c4 10             	add    $0x10,%esp
	cwrites( buf );
   1a1d9:	83 ec 0c             	sub    $0xc,%esp
   1a1dc:	8d 85 f4 fe ff ff    	lea    -0x10c(%ebp),%eax
   1a1e2:	50                   	push   %eax
   1a1e3:	e8 38 00 00 00       	call   1a220 <cwrites>
   1a1e8:	83 c4 10             	add    $0x10,%esp

	exit( EXIT_FAILURE );
   1a1eb:	83 ec 0c             	sub    $0xc,%esp
   1a1ee:	6a ff                	push   $0xffffffff
   1a1f0:	e8 94 cb ff ff       	call   16d89 <exit>
   1a1f5:	83 c4 10             	add    $0x10,%esp
	return( 0 );   // shut the compiler up
   1a1f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
   1a1fd:	c9                   	leave  
   1a1fe:	c3                   	ret    

0001a1ff <cwritech>:
**
** @param ch The character to write
**
** @returns The return value from calling write()
*/
int cwritech( char ch ) {
   1a1ff:	55                   	push   %ebp
   1a200:	89 e5                	mov    %esp,%ebp
   1a202:	83 ec 18             	sub    $0x18,%esp
   1a205:	8b 45 08             	mov    0x8(%ebp),%eax
   1a208:	88 45 f4             	mov    %al,-0xc(%ebp)
	return( write(CHAN_CIO,&ch,1) );
   1a20b:	83 ec 04             	sub    $0x4,%esp
   1a20e:	6a 01                	push   $0x1
   1a210:	8d 45 f4             	lea    -0xc(%ebp),%eax
   1a213:	50                   	push   %eax
   1a214:	6a 00                	push   $0x0
   1a216:	e8 96 cb ff ff       	call   16db1 <write>
   1a21b:	83 c4 10             	add    $0x10,%esp
}
   1a21e:	c9                   	leave  
   1a21f:	c3                   	ret    

0001a220 <cwrites>:
** cwrites(str) - write a NUL-terminated string to the console
**
** @param str The string to write
**
*/
int cwrites( const char *str ) {
   1a220:	55                   	push   %ebp
   1a221:	89 e5                	mov    %esp,%ebp
   1a223:	83 ec 18             	sub    $0x18,%esp
	int len = ustrlen(str);
   1a226:	ff 75 08             	pushl  0x8(%ebp)
   1a229:	e8 82 fc ff ff       	call   19eb0 <ustrlen>
   1a22e:	83 c4 04             	add    $0x4,%esp
   1a231:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return( write(CHAN_CIO,str,len) );
   1a234:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a237:	83 ec 04             	sub    $0x4,%esp
   1a23a:	50                   	push   %eax
   1a23b:	ff 75 08             	pushl  0x8(%ebp)
   1a23e:	6a 00                	push   $0x0
   1a240:	e8 6c cb ff ff       	call   16db1 <write>
   1a245:	83 c4 10             	add    $0x10,%esp
}
   1a248:	c9                   	leave  
   1a249:	c3                   	ret    

0001a24a <cwrite>:
** @param buf  The buffer to write
** @param size The number of bytes to write
**
** @returns The return value from calling write()
*/
int cwrite( const char *buf, uint32_t size ) {
   1a24a:	55                   	push   %ebp
   1a24b:	89 e5                	mov    %esp,%ebp
   1a24d:	83 ec 08             	sub    $0x8,%esp
	return( write(CHAN_CIO,buf,size) );
   1a250:	83 ec 04             	sub    $0x4,%esp
   1a253:	ff 75 0c             	pushl  0xc(%ebp)
   1a256:	ff 75 08             	pushl  0x8(%ebp)
   1a259:	6a 00                	push   $0x0
   1a25b:	e8 51 cb ff ff       	call   16db1 <write>
   1a260:	83 c4 10             	add    $0x10,%esp
}
   1a263:	c9                   	leave  
   1a264:	c3                   	ret    

0001a265 <swritech>:
**
** @param ch The character to write
**
** @returns The return value from calling write()
*/
int swritech( char ch ) {
   1a265:	55                   	push   %ebp
   1a266:	89 e5                	mov    %esp,%ebp
   1a268:	83 ec 18             	sub    $0x18,%esp
   1a26b:	8b 45 08             	mov    0x8(%ebp),%eax
   1a26e:	88 45 f4             	mov    %al,-0xc(%ebp)
	return( write(CHAN_SIO,&ch,1) );
   1a271:	83 ec 04             	sub    $0x4,%esp
   1a274:	6a 01                	push   $0x1
   1a276:	8d 45 f4             	lea    -0xc(%ebp),%eax
   1a279:	50                   	push   %eax
   1a27a:	6a 01                	push   $0x1
   1a27c:	e8 30 cb ff ff       	call   16db1 <write>
   1a281:	83 c4 10             	add    $0x10,%esp
}
   1a284:	c9                   	leave  
   1a285:	c3                   	ret    

0001a286 <swrites>:
**
** @param str The string to write
**
** @returns The return value from calling write()
*/
int swrites( const char *str ) {
   1a286:	55                   	push   %ebp
   1a287:	89 e5                	mov    %esp,%ebp
   1a289:	83 ec 18             	sub    $0x18,%esp
	int len = ustrlen(str);
   1a28c:	ff 75 08             	pushl  0x8(%ebp)
   1a28f:	e8 1c fc ff ff       	call   19eb0 <ustrlen>
   1a294:	83 c4 04             	add    $0x4,%esp
   1a297:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return( write(CHAN_SIO,str,len) );
   1a29a:	8b 45 f4             	mov    -0xc(%ebp),%eax
   1a29d:	83 ec 04             	sub    $0x4,%esp
   1a2a0:	50                   	push   %eax
   1a2a1:	ff 75 08             	pushl  0x8(%ebp)
   1a2a4:	6a 01                	push   $0x1
   1a2a6:	e8 06 cb ff ff       	call   16db1 <write>
   1a2ab:	83 c4 10             	add    $0x10,%esp
}
   1a2ae:	c9                   	leave  
   1a2af:	c3                   	ret    

0001a2b0 <swrite>:
** @param buf  The buffer to write
** @param size The number of bytes to write
**
** @returns The return value from calling write()
*/
int swrite( const char *buf, uint32_t size ) {
   1a2b0:	55                   	push   %ebp
   1a2b1:	89 e5                	mov    %esp,%ebp
   1a2b3:	83 ec 08             	sub    $0x8,%esp
	return( write(CHAN_SIO,buf,size) );
   1a2b6:	83 ec 04             	sub    $0x4,%esp
   1a2b9:	ff 75 0c             	pushl  0xc(%ebp)
   1a2bc:	ff 75 08             	pushl  0x8(%ebp)
   1a2bf:	6a 01                	push   $0x1
   1a2c1:	e8 eb ca ff ff       	call   16db1 <write>
   1a2c6:	83 c4 10             	add    $0x10,%esp
}
   1a2c9:	c9                   	leave  
   1a2ca:	c3                   	ret    
