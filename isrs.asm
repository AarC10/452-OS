
isrs.o:     file format elf32-i386


Disassembly of section .text:

00000000 <isr_save>:
**	    error code, or 0	saved by the hardware, or the entry macro
**	    saved EIP		saved by the hardware
**	    saved CS		saved by the hardware
**	    saved EFLAGS	saved by the hardware
*/
	pusha			// save E*X, ESP, EBP, ESI, EDI
   0:	60                   	pusha  
	pushl	%ds		// save segment registers
   1:	1e                   	push   %ds
	pushl	%es
   2:	06                   	push   %es
	pushl	%fs
   3:	0f a0                	push   %fs
	pushl	%gs
   5:	0f a8                	push   %gs
	pushl	%ss
   7:	16                   	push   %ss
**
** Note that the saved ESP is the contents before the PUSHA.
**
** Set up parameters for the ISR call.
*/
	movl	CTX_vector(%esp),%eax	// get vector number and error code
   8:	8b 44 24 34          	mov    0x34(%esp),%eax
	movl	CTX_code(%esp),%ebx
   c:	8b 5c 24 38          	mov    0x38(%esp),%ebx

	.globl	current
	.globl	kernel_esp

	// save the context pointer
	movl	current, %edx
  10:	8b 15 00 00 00 00    	mov    0x0,%edx
	movl	%esp, PCB_context(%edx)
  16:	89 22                	mov    %esp,(%edx)
	// NOTE: this is inherently non-reentrant!  If/when the OS
	// is converted from monolithic to something that supports
	// reentrant or interruptable ISRs, this code will need to
	// be changed to support that!

	movl	kernel_esp, %esp
  18:	8b 25 00 00 00 00    	mov    0x0,%esp

#
# END MOD FOR 20245
#

	pushl	%ebx		// put them on the top of the stack ...
  1e:	53                   	push   %ebx
	pushl	%eax		// ... as parameters for the ISR
  1f:	50                   	push   %eax

/*
** Call the ISR
*/
	movl	isr_table(,%eax,4),%ebx
  20:	8b 1c 85 00 00 00 00 	mov    0x0(,%eax,4),%ebx
	call	*%ebx
  27:	ff d3                	call   *%ebx
	addl	$8,%esp		// pop the two parameters
  29:	83 c4 08             	add    $0x8,%esp

0000002c <isr_restore>:
isr_restore:

#
# MOD FOR 20245
#
	movl	current, %ebx	// return to the user stack
  2c:	8b 1d 00 00 00 00    	mov    0x0,%ebx
	movl	PCB_context(%ebx), %esp	// ESP --> context save area
  32:	8b 23                	mov    (%ebx),%esp
#
# Report system time and PID with context
#
	.globl	system_time

	pushl	PCB_pid(%ebx)
  34:	ff 73 18             	pushl  0x18(%ebx)
	pushl	system_time
  37:	ff 35 00 00 00 00    	pushl  0x0
	pushl	$fmtall
  3d:	68 00 00 00 00       	push   $0x0
	pushl	$1
  42:	6a 01                	push   $0x1
	pushl	$0
  44:	6a 00                	push   $0x0
	call	cio_printf_at
  46:	e8 fc ff ff ff       	call   47 <isr_restore+0x1b>
	addl	$20,%esp
  4b:	83 c4 14             	add    $0x14,%esp
#endif

/*
** Restore the context.
*/
	popl	%ss		// restore the segment registers
  4e:	17                   	pop    %ss
	popl	%gs
  4f:	0f a9                	pop    %gs
	popl	%fs
  51:	0f a1                	pop    %fs
	popl	%es
  53:	07                   	pop    %es
	popl	%ds
  54:	1f                   	pop    %ds
	popa			// restore others
  55:	61                   	popa   
	addl	$8, %esp	// discard the error code and vector
  56:	83 c4 08             	add    $0x8,%esp
	iret			// and return
  59:	cf                   	iret   

0000005a <isr_0x00>:
#endif

/*
** Here we generate the individual stubs for each interrupt.
*/
ISR(0x00);	ISR(0x01);	ISR(0x02);	ISR(0x03);
  5a:	6a 00                	push   $0x0
  5c:	6a 00                	push   $0x0
  5e:	eb a0                	jmp    0 <isr_save>

00000060 <isr_0x01>:
  60:	6a 00                	push   $0x0
  62:	6a 01                	push   $0x1
  64:	eb 9a                	jmp    0 <isr_save>

00000066 <isr_0x02>:
  66:	6a 00                	push   $0x0
  68:	6a 02                	push   $0x2
  6a:	eb 94                	jmp    0 <isr_save>

0000006c <isr_0x03>:
  6c:	6a 00                	push   $0x0
  6e:	6a 03                	push   $0x3
  70:	eb 8e                	jmp    0 <isr_save>

00000072 <isr_0x04>:
ISR(0x04);	ISR(0x05);	ISR(0x06);	ISR(0x07);
  72:	6a 00                	push   $0x0
  74:	6a 04                	push   $0x4
  76:	eb 88                	jmp    0 <isr_save>

00000078 <isr_0x05>:
  78:	6a 00                	push   $0x0
  7a:	6a 05                	push   $0x5
  7c:	eb 82                	jmp    0 <isr_save>

0000007e <isr_0x06>:
  7e:	6a 00                	push   $0x0
  80:	6a 06                	push   $0x6
  82:	e9 79 ff ff ff       	jmp    0 <isr_save>

00000087 <isr_0x07>:
  87:	6a 00                	push   $0x0
  89:	6a 07                	push   $0x7
  8b:	e9 70 ff ff ff       	jmp    0 <isr_save>

00000090 <isr_0x08>:
ERR_ISR(0x08);	ISR(0x09);	ERR_ISR(0x0a);	ERR_ISR(0x0b);
  90:	6a 08                	push   $0x8
  92:	e9 69 ff ff ff       	jmp    0 <isr_save>

00000097 <isr_0x09>:
  97:	6a 00                	push   $0x0
  99:	6a 09                	push   $0x9
  9b:	e9 60 ff ff ff       	jmp    0 <isr_save>

000000a0 <isr_0x0a>:
  a0:	6a 0a                	push   $0xa
  a2:	e9 59 ff ff ff       	jmp    0 <isr_save>

000000a7 <isr_0x0b>:
  a7:	6a 0b                	push   $0xb
  a9:	e9 52 ff ff ff       	jmp    0 <isr_save>

000000ae <isr_0x0c>:
ERR_ISR(0x0c);	ERR_ISR(0x0d);	ERR_ISR(0x0e);	ISR(0x0f);
  ae:	6a 0c                	push   $0xc
  b0:	e9 4b ff ff ff       	jmp    0 <isr_save>

000000b5 <isr_0x0d>:
  b5:	6a 0d                	push   $0xd
  b7:	e9 44 ff ff ff       	jmp    0 <isr_save>

000000bc <isr_0x0e>:
  bc:	6a 0e                	push   $0xe
  be:	e9 3d ff ff ff       	jmp    0 <isr_save>

000000c3 <isr_0x0f>:
  c3:	6a 00                	push   $0x0
  c5:	6a 0f                	push   $0xf
  c7:	e9 34 ff ff ff       	jmp    0 <isr_save>

000000cc <isr_0x10>:
ISR(0x10);	ERR_ISR(0x11);	ISR(0x12);	ISR(0x13);
  cc:	6a 00                	push   $0x0
  ce:	6a 10                	push   $0x10
  d0:	e9 2b ff ff ff       	jmp    0 <isr_save>

000000d5 <isr_0x11>:
  d5:	6a 11                	push   $0x11
  d7:	e9 24 ff ff ff       	jmp    0 <isr_save>

000000dc <isr_0x12>:
  dc:	6a 00                	push   $0x0
  de:	6a 12                	push   $0x12
  e0:	e9 1b ff ff ff       	jmp    0 <isr_save>

000000e5 <isr_0x13>:
  e5:	6a 00                	push   $0x0
  e7:	6a 13                	push   $0x13
  e9:	e9 12 ff ff ff       	jmp    0 <isr_save>

000000ee <isr_0x14>:
ISR(0x14);	ERR_ISR(0x15);	ISR(0x16);	ISR(0x17);
  ee:	6a 00                	push   $0x0
  f0:	6a 14                	push   $0x14
  f2:	e9 09 ff ff ff       	jmp    0 <isr_save>

000000f7 <isr_0x15>:
  f7:	6a 15                	push   $0x15
  f9:	e9 02 ff ff ff       	jmp    0 <isr_save>

000000fe <isr_0x16>:
  fe:	6a 00                	push   $0x0
 100:	6a 16                	push   $0x16
 102:	e9 f9 fe ff ff       	jmp    0 <isr_save>

00000107 <isr_0x17>:
 107:	6a 00                	push   $0x0
 109:	6a 17                	push   $0x17
 10b:	e9 f0 fe ff ff       	jmp    0 <isr_save>

00000110 <isr_0x18>:
ISR(0x18);	ISR(0x19);	ISR(0x1a);	ISR(0x1b);
 110:	6a 00                	push   $0x0
 112:	6a 18                	push   $0x18
 114:	e9 e7 fe ff ff       	jmp    0 <isr_save>

00000119 <isr_0x19>:
 119:	6a 00                	push   $0x0
 11b:	6a 19                	push   $0x19
 11d:	e9 de fe ff ff       	jmp    0 <isr_save>

00000122 <isr_0x1a>:
 122:	6a 00                	push   $0x0
 124:	6a 1a                	push   $0x1a
 126:	e9 d5 fe ff ff       	jmp    0 <isr_save>

0000012b <isr_0x1b>:
 12b:	6a 00                	push   $0x0
 12d:	6a 1b                	push   $0x1b
 12f:	e9 cc fe ff ff       	jmp    0 <isr_save>

00000134 <isr_0x1c>:
ISR(0x1c);	ISR(0x1d);	ISR(0x1e);	ISR(0x1f);
 134:	6a 00                	push   $0x0
 136:	6a 1c                	push   $0x1c
 138:	e9 c3 fe ff ff       	jmp    0 <isr_save>

0000013d <isr_0x1d>:
 13d:	6a 00                	push   $0x0
 13f:	6a 1d                	push   $0x1d
 141:	e9 ba fe ff ff       	jmp    0 <isr_save>

00000146 <isr_0x1e>:
 146:	6a 00                	push   $0x0
 148:	6a 1e                	push   $0x1e
 14a:	e9 b1 fe ff ff       	jmp    0 <isr_save>

0000014f <isr_0x1f>:
 14f:	6a 00                	push   $0x0
 151:	6a 1f                	push   $0x1f
 153:	e9 a8 fe ff ff       	jmp    0 <isr_save>

00000158 <isr_0x20>:
ISR(0x20);	ISR(0x21);	ISR(0x22);	ISR(0x23);
 158:	6a 00                	push   $0x0
 15a:	6a 20                	push   $0x20
 15c:	e9 9f fe ff ff       	jmp    0 <isr_save>

00000161 <isr_0x21>:
 161:	6a 00                	push   $0x0
 163:	6a 21                	push   $0x21
 165:	e9 96 fe ff ff       	jmp    0 <isr_save>

0000016a <isr_0x22>:
 16a:	6a 00                	push   $0x0
 16c:	6a 22                	push   $0x22
 16e:	e9 8d fe ff ff       	jmp    0 <isr_save>

00000173 <isr_0x23>:
 173:	6a 00                	push   $0x0
 175:	6a 23                	push   $0x23
 177:	e9 84 fe ff ff       	jmp    0 <isr_save>

0000017c <isr_0x24>:
ISR(0x24);	ISR(0x25);	ISR(0x26);	ISR(0x27);
 17c:	6a 00                	push   $0x0
 17e:	6a 24                	push   $0x24
 180:	e9 7b fe ff ff       	jmp    0 <isr_save>

00000185 <isr_0x25>:
 185:	6a 00                	push   $0x0
 187:	6a 25                	push   $0x25
 189:	e9 72 fe ff ff       	jmp    0 <isr_save>

0000018e <isr_0x26>:
 18e:	6a 00                	push   $0x0
 190:	6a 26                	push   $0x26
 192:	e9 69 fe ff ff       	jmp    0 <isr_save>

00000197 <isr_0x27>:
 197:	6a 00                	push   $0x0
 199:	6a 27                	push   $0x27
 19b:	e9 60 fe ff ff       	jmp    0 <isr_save>

000001a0 <isr_0x28>:
ISR(0x28);	ISR(0x29);	ISR(0x2a);	ISR(0x2b);
 1a0:	6a 00                	push   $0x0
 1a2:	6a 28                	push   $0x28
 1a4:	e9 57 fe ff ff       	jmp    0 <isr_save>

000001a9 <isr_0x29>:
 1a9:	6a 00                	push   $0x0
 1ab:	6a 29                	push   $0x29
 1ad:	e9 4e fe ff ff       	jmp    0 <isr_save>

000001b2 <isr_0x2a>:
 1b2:	6a 00                	push   $0x0
 1b4:	6a 2a                	push   $0x2a
 1b6:	e9 45 fe ff ff       	jmp    0 <isr_save>

000001bb <isr_0x2b>:
 1bb:	6a 00                	push   $0x0
 1bd:	6a 2b                	push   $0x2b
 1bf:	e9 3c fe ff ff       	jmp    0 <isr_save>

000001c4 <isr_0x2c>:
ISR(0x2c);	ISR(0x2d);	ISR(0x2e);	ISR(0x2f);
 1c4:	6a 00                	push   $0x0
 1c6:	6a 2c                	push   $0x2c
 1c8:	e9 33 fe ff ff       	jmp    0 <isr_save>

000001cd <isr_0x2d>:
 1cd:	6a 00                	push   $0x0
 1cf:	6a 2d                	push   $0x2d
 1d1:	e9 2a fe ff ff       	jmp    0 <isr_save>

000001d6 <isr_0x2e>:
 1d6:	6a 00                	push   $0x0
 1d8:	6a 2e                	push   $0x2e
 1da:	e9 21 fe ff ff       	jmp    0 <isr_save>

000001df <isr_0x2f>:
 1df:	6a 00                	push   $0x0
 1e1:	6a 2f                	push   $0x2f
 1e3:	e9 18 fe ff ff       	jmp    0 <isr_save>

000001e8 <isr_0x30>:
ISR(0x30);	ISR(0x31);	ISR(0x32);	ISR(0x33);
 1e8:	6a 00                	push   $0x0
 1ea:	6a 30                	push   $0x30
 1ec:	e9 0f fe ff ff       	jmp    0 <isr_save>

000001f1 <isr_0x31>:
 1f1:	6a 00                	push   $0x0
 1f3:	6a 31                	push   $0x31
 1f5:	e9 06 fe ff ff       	jmp    0 <isr_save>

000001fa <isr_0x32>:
 1fa:	6a 00                	push   $0x0
 1fc:	6a 32                	push   $0x32
 1fe:	e9 fd fd ff ff       	jmp    0 <isr_save>

00000203 <isr_0x33>:
 203:	6a 00                	push   $0x0
 205:	6a 33                	push   $0x33
 207:	e9 f4 fd ff ff       	jmp    0 <isr_save>

0000020c <isr_0x34>:
ISR(0x34);	ISR(0x35);	ISR(0x36);	ISR(0x37);
 20c:	6a 00                	push   $0x0
 20e:	6a 34                	push   $0x34
 210:	e9 eb fd ff ff       	jmp    0 <isr_save>

00000215 <isr_0x35>:
 215:	6a 00                	push   $0x0
 217:	6a 35                	push   $0x35
 219:	e9 e2 fd ff ff       	jmp    0 <isr_save>

0000021e <isr_0x36>:
 21e:	6a 00                	push   $0x0
 220:	6a 36                	push   $0x36
 222:	e9 d9 fd ff ff       	jmp    0 <isr_save>

00000227 <isr_0x37>:
 227:	6a 00                	push   $0x0
 229:	6a 37                	push   $0x37
 22b:	e9 d0 fd ff ff       	jmp    0 <isr_save>

00000230 <isr_0x38>:
ISR(0x38);	ISR(0x39);	ISR(0x3a);	ISR(0x3b);
 230:	6a 00                	push   $0x0
 232:	6a 38                	push   $0x38
 234:	e9 c7 fd ff ff       	jmp    0 <isr_save>

00000239 <isr_0x39>:
 239:	6a 00                	push   $0x0
 23b:	6a 39                	push   $0x39
 23d:	e9 be fd ff ff       	jmp    0 <isr_save>

00000242 <isr_0x3a>:
 242:	6a 00                	push   $0x0
 244:	6a 3a                	push   $0x3a
 246:	e9 b5 fd ff ff       	jmp    0 <isr_save>

0000024b <isr_0x3b>:
 24b:	6a 00                	push   $0x0
 24d:	6a 3b                	push   $0x3b
 24f:	e9 ac fd ff ff       	jmp    0 <isr_save>

00000254 <isr_0x3c>:
ISR(0x3c);	ISR(0x3d);	ISR(0x3e);	ISR(0x3f);
 254:	6a 00                	push   $0x0
 256:	6a 3c                	push   $0x3c
 258:	e9 a3 fd ff ff       	jmp    0 <isr_save>

0000025d <isr_0x3d>:
 25d:	6a 00                	push   $0x0
 25f:	6a 3d                	push   $0x3d
 261:	e9 9a fd ff ff       	jmp    0 <isr_save>

00000266 <isr_0x3e>:
 266:	6a 00                	push   $0x0
 268:	6a 3e                	push   $0x3e
 26a:	e9 91 fd ff ff       	jmp    0 <isr_save>

0000026f <isr_0x3f>:
 26f:	6a 00                	push   $0x0
 271:	6a 3f                	push   $0x3f
 273:	e9 88 fd ff ff       	jmp    0 <isr_save>

00000278 <isr_0x40>:
ISR(0x40);	ISR(0x41);	ISR(0x42);	ISR(0x43);
 278:	6a 00                	push   $0x0
 27a:	6a 40                	push   $0x40
 27c:	e9 7f fd ff ff       	jmp    0 <isr_save>

00000281 <isr_0x41>:
 281:	6a 00                	push   $0x0
 283:	6a 41                	push   $0x41
 285:	e9 76 fd ff ff       	jmp    0 <isr_save>

0000028a <isr_0x42>:
 28a:	6a 00                	push   $0x0
 28c:	6a 42                	push   $0x42
 28e:	e9 6d fd ff ff       	jmp    0 <isr_save>

00000293 <isr_0x43>:
 293:	6a 00                	push   $0x0
 295:	6a 43                	push   $0x43
 297:	e9 64 fd ff ff       	jmp    0 <isr_save>

0000029c <isr_0x44>:
ISR(0x44);	ISR(0x45);	ISR(0x46);	ISR(0x47);
 29c:	6a 00                	push   $0x0
 29e:	6a 44                	push   $0x44
 2a0:	e9 5b fd ff ff       	jmp    0 <isr_save>

000002a5 <isr_0x45>:
 2a5:	6a 00                	push   $0x0
 2a7:	6a 45                	push   $0x45
 2a9:	e9 52 fd ff ff       	jmp    0 <isr_save>

000002ae <isr_0x46>:
 2ae:	6a 00                	push   $0x0
 2b0:	6a 46                	push   $0x46
 2b2:	e9 49 fd ff ff       	jmp    0 <isr_save>

000002b7 <isr_0x47>:
 2b7:	6a 00                	push   $0x0
 2b9:	6a 47                	push   $0x47
 2bb:	e9 40 fd ff ff       	jmp    0 <isr_save>

000002c0 <isr_0x48>:
ISR(0x48);	ISR(0x49);	ISR(0x4a);	ISR(0x4b);
 2c0:	6a 00                	push   $0x0
 2c2:	6a 48                	push   $0x48
 2c4:	e9 37 fd ff ff       	jmp    0 <isr_save>

000002c9 <isr_0x49>:
 2c9:	6a 00                	push   $0x0
 2cb:	6a 49                	push   $0x49
 2cd:	e9 2e fd ff ff       	jmp    0 <isr_save>

000002d2 <isr_0x4a>:
 2d2:	6a 00                	push   $0x0
 2d4:	6a 4a                	push   $0x4a
 2d6:	e9 25 fd ff ff       	jmp    0 <isr_save>

000002db <isr_0x4b>:
 2db:	6a 00                	push   $0x0
 2dd:	6a 4b                	push   $0x4b
 2df:	e9 1c fd ff ff       	jmp    0 <isr_save>

000002e4 <isr_0x4c>:
ISR(0x4c);	ISR(0x4d);	ISR(0x4e);	ISR(0x4f);
 2e4:	6a 00                	push   $0x0
 2e6:	6a 4c                	push   $0x4c
 2e8:	e9 13 fd ff ff       	jmp    0 <isr_save>

000002ed <isr_0x4d>:
 2ed:	6a 00                	push   $0x0
 2ef:	6a 4d                	push   $0x4d
 2f1:	e9 0a fd ff ff       	jmp    0 <isr_save>

000002f6 <isr_0x4e>:
 2f6:	6a 00                	push   $0x0
 2f8:	6a 4e                	push   $0x4e
 2fa:	e9 01 fd ff ff       	jmp    0 <isr_save>

000002ff <isr_0x4f>:
 2ff:	6a 00                	push   $0x0
 301:	6a 4f                	push   $0x4f
 303:	e9 f8 fc ff ff       	jmp    0 <isr_save>

00000308 <isr_0x50>:
ISR(0x50);	ISR(0x51);	ISR(0x52);	ISR(0x53);
 308:	6a 00                	push   $0x0
 30a:	6a 50                	push   $0x50
 30c:	e9 ef fc ff ff       	jmp    0 <isr_save>

00000311 <isr_0x51>:
 311:	6a 00                	push   $0x0
 313:	6a 51                	push   $0x51
 315:	e9 e6 fc ff ff       	jmp    0 <isr_save>

0000031a <isr_0x52>:
 31a:	6a 00                	push   $0x0
 31c:	6a 52                	push   $0x52
 31e:	e9 dd fc ff ff       	jmp    0 <isr_save>

00000323 <isr_0x53>:
 323:	6a 00                	push   $0x0
 325:	6a 53                	push   $0x53
 327:	e9 d4 fc ff ff       	jmp    0 <isr_save>

0000032c <isr_0x54>:
ISR(0x54);	ISR(0x55);	ISR(0x56);	ISR(0x57);
 32c:	6a 00                	push   $0x0
 32e:	6a 54                	push   $0x54
 330:	e9 cb fc ff ff       	jmp    0 <isr_save>

00000335 <isr_0x55>:
 335:	6a 00                	push   $0x0
 337:	6a 55                	push   $0x55
 339:	e9 c2 fc ff ff       	jmp    0 <isr_save>

0000033e <isr_0x56>:
 33e:	6a 00                	push   $0x0
 340:	6a 56                	push   $0x56
 342:	e9 b9 fc ff ff       	jmp    0 <isr_save>

00000347 <isr_0x57>:
 347:	6a 00                	push   $0x0
 349:	6a 57                	push   $0x57
 34b:	e9 b0 fc ff ff       	jmp    0 <isr_save>

00000350 <isr_0x58>:
ISR(0x58);	ISR(0x59);	ISR(0x5a);	ISR(0x5b);
 350:	6a 00                	push   $0x0
 352:	6a 58                	push   $0x58
 354:	e9 a7 fc ff ff       	jmp    0 <isr_save>

00000359 <isr_0x59>:
 359:	6a 00                	push   $0x0
 35b:	6a 59                	push   $0x59
 35d:	e9 9e fc ff ff       	jmp    0 <isr_save>

00000362 <isr_0x5a>:
 362:	6a 00                	push   $0x0
 364:	6a 5a                	push   $0x5a
 366:	e9 95 fc ff ff       	jmp    0 <isr_save>

0000036b <isr_0x5b>:
 36b:	6a 00                	push   $0x0
 36d:	6a 5b                	push   $0x5b
 36f:	e9 8c fc ff ff       	jmp    0 <isr_save>

00000374 <isr_0x5c>:
ISR(0x5c);	ISR(0x5d);	ISR(0x5e);	ISR(0x5f);
 374:	6a 00                	push   $0x0
 376:	6a 5c                	push   $0x5c
 378:	e9 83 fc ff ff       	jmp    0 <isr_save>

0000037d <isr_0x5d>:
 37d:	6a 00                	push   $0x0
 37f:	6a 5d                	push   $0x5d
 381:	e9 7a fc ff ff       	jmp    0 <isr_save>

00000386 <isr_0x5e>:
 386:	6a 00                	push   $0x0
 388:	6a 5e                	push   $0x5e
 38a:	e9 71 fc ff ff       	jmp    0 <isr_save>

0000038f <isr_0x5f>:
 38f:	6a 00                	push   $0x0
 391:	6a 5f                	push   $0x5f
 393:	e9 68 fc ff ff       	jmp    0 <isr_save>

00000398 <isr_0x60>:
ISR(0x60);	ISR(0x61);	ISR(0x62);	ISR(0x63);
 398:	6a 00                	push   $0x0
 39a:	6a 60                	push   $0x60
 39c:	e9 5f fc ff ff       	jmp    0 <isr_save>

000003a1 <isr_0x61>:
 3a1:	6a 00                	push   $0x0
 3a3:	6a 61                	push   $0x61
 3a5:	e9 56 fc ff ff       	jmp    0 <isr_save>

000003aa <isr_0x62>:
 3aa:	6a 00                	push   $0x0
 3ac:	6a 62                	push   $0x62
 3ae:	e9 4d fc ff ff       	jmp    0 <isr_save>

000003b3 <isr_0x63>:
 3b3:	6a 00                	push   $0x0
 3b5:	6a 63                	push   $0x63
 3b7:	e9 44 fc ff ff       	jmp    0 <isr_save>

000003bc <isr_0x64>:
ISR(0x64);	ISR(0x65);	ISR(0x66);	ISR(0x67);
 3bc:	6a 00                	push   $0x0
 3be:	6a 64                	push   $0x64
 3c0:	e9 3b fc ff ff       	jmp    0 <isr_save>

000003c5 <isr_0x65>:
 3c5:	6a 00                	push   $0x0
 3c7:	6a 65                	push   $0x65
 3c9:	e9 32 fc ff ff       	jmp    0 <isr_save>

000003ce <isr_0x66>:
 3ce:	6a 00                	push   $0x0
 3d0:	6a 66                	push   $0x66
 3d2:	e9 29 fc ff ff       	jmp    0 <isr_save>

000003d7 <isr_0x67>:
 3d7:	6a 00                	push   $0x0
 3d9:	6a 67                	push   $0x67
 3db:	e9 20 fc ff ff       	jmp    0 <isr_save>

000003e0 <isr_0x68>:
ISR(0x68);	ISR(0x69);	ISR(0x6a);	ISR(0x6b);
 3e0:	6a 00                	push   $0x0
 3e2:	6a 68                	push   $0x68
 3e4:	e9 17 fc ff ff       	jmp    0 <isr_save>

000003e9 <isr_0x69>:
 3e9:	6a 00                	push   $0x0
 3eb:	6a 69                	push   $0x69
 3ed:	e9 0e fc ff ff       	jmp    0 <isr_save>

000003f2 <isr_0x6a>:
 3f2:	6a 00                	push   $0x0
 3f4:	6a 6a                	push   $0x6a
 3f6:	e9 05 fc ff ff       	jmp    0 <isr_save>

000003fb <isr_0x6b>:
 3fb:	6a 00                	push   $0x0
 3fd:	6a 6b                	push   $0x6b
 3ff:	e9 fc fb ff ff       	jmp    0 <isr_save>

00000404 <isr_0x6c>:
ISR(0x6c);	ISR(0x6d);	ISR(0x6e);	ISR(0x6f);
 404:	6a 00                	push   $0x0
 406:	6a 6c                	push   $0x6c
 408:	e9 f3 fb ff ff       	jmp    0 <isr_save>

0000040d <isr_0x6d>:
 40d:	6a 00                	push   $0x0
 40f:	6a 6d                	push   $0x6d
 411:	e9 ea fb ff ff       	jmp    0 <isr_save>

00000416 <isr_0x6e>:
 416:	6a 00                	push   $0x0
 418:	6a 6e                	push   $0x6e
 41a:	e9 e1 fb ff ff       	jmp    0 <isr_save>

0000041f <isr_0x6f>:
 41f:	6a 00                	push   $0x0
 421:	6a 6f                	push   $0x6f
 423:	e9 d8 fb ff ff       	jmp    0 <isr_save>

00000428 <isr_0x70>:
ISR(0x70);	ISR(0x71);	ISR(0x72);	ISR(0x73);
 428:	6a 00                	push   $0x0
 42a:	6a 70                	push   $0x70
 42c:	e9 cf fb ff ff       	jmp    0 <isr_save>

00000431 <isr_0x71>:
 431:	6a 00                	push   $0x0
 433:	6a 71                	push   $0x71
 435:	e9 c6 fb ff ff       	jmp    0 <isr_save>

0000043a <isr_0x72>:
 43a:	6a 00                	push   $0x0
 43c:	6a 72                	push   $0x72
 43e:	e9 bd fb ff ff       	jmp    0 <isr_save>

00000443 <isr_0x73>:
 443:	6a 00                	push   $0x0
 445:	6a 73                	push   $0x73
 447:	e9 b4 fb ff ff       	jmp    0 <isr_save>

0000044c <isr_0x74>:
ISR(0x74);	ISR(0x75);	ISR(0x76);	ISR(0x77);
 44c:	6a 00                	push   $0x0
 44e:	6a 74                	push   $0x74
 450:	e9 ab fb ff ff       	jmp    0 <isr_save>

00000455 <isr_0x75>:
 455:	6a 00                	push   $0x0
 457:	6a 75                	push   $0x75
 459:	e9 a2 fb ff ff       	jmp    0 <isr_save>

0000045e <isr_0x76>:
 45e:	6a 00                	push   $0x0
 460:	6a 76                	push   $0x76
 462:	e9 99 fb ff ff       	jmp    0 <isr_save>

00000467 <isr_0x77>:
 467:	6a 00                	push   $0x0
 469:	6a 77                	push   $0x77
 46b:	e9 90 fb ff ff       	jmp    0 <isr_save>

00000470 <isr_0x78>:
ISR(0x78);	ISR(0x79);	ISR(0x7a);	ISR(0x7b);
 470:	6a 00                	push   $0x0
 472:	6a 78                	push   $0x78
 474:	e9 87 fb ff ff       	jmp    0 <isr_save>

00000479 <isr_0x79>:
 479:	6a 00                	push   $0x0
 47b:	6a 79                	push   $0x79
 47d:	e9 7e fb ff ff       	jmp    0 <isr_save>

00000482 <isr_0x7a>:
 482:	6a 00                	push   $0x0
 484:	6a 7a                	push   $0x7a
 486:	e9 75 fb ff ff       	jmp    0 <isr_save>

0000048b <isr_0x7b>:
 48b:	6a 00                	push   $0x0
 48d:	6a 7b                	push   $0x7b
 48f:	e9 6c fb ff ff       	jmp    0 <isr_save>

00000494 <isr_0x7c>:
ISR(0x7c);	ISR(0x7d);	ISR(0x7e);	ISR(0x7f);
 494:	6a 00                	push   $0x0
 496:	6a 7c                	push   $0x7c
 498:	e9 63 fb ff ff       	jmp    0 <isr_save>

0000049d <isr_0x7d>:
 49d:	6a 00                	push   $0x0
 49f:	6a 7d                	push   $0x7d
 4a1:	e9 5a fb ff ff       	jmp    0 <isr_save>

000004a6 <isr_0x7e>:
 4a6:	6a 00                	push   $0x0
 4a8:	6a 7e                	push   $0x7e
 4aa:	e9 51 fb ff ff       	jmp    0 <isr_save>

000004af <isr_0x7f>:
 4af:	6a 00                	push   $0x0
 4b1:	6a 7f                	push   $0x7f
 4b3:	e9 48 fb ff ff       	jmp    0 <isr_save>

000004b8 <isr_0x80>:
ISR(0x80);	ISR(0x81);	ISR(0x82);	ISR(0x83);
 4b8:	6a 00                	push   $0x0
 4ba:	68 80 00 00 00       	push   $0x80
 4bf:	e9 3c fb ff ff       	jmp    0 <isr_save>

000004c4 <isr_0x81>:
 4c4:	6a 00                	push   $0x0
 4c6:	68 81 00 00 00       	push   $0x81
 4cb:	e9 30 fb ff ff       	jmp    0 <isr_save>

000004d0 <isr_0x82>:
 4d0:	6a 00                	push   $0x0
 4d2:	68 82 00 00 00       	push   $0x82
 4d7:	e9 24 fb ff ff       	jmp    0 <isr_save>

000004dc <isr_0x83>:
 4dc:	6a 00                	push   $0x0
 4de:	68 83 00 00 00       	push   $0x83
 4e3:	e9 18 fb ff ff       	jmp    0 <isr_save>

000004e8 <isr_0x84>:
ISR(0x84);	ISR(0x85);	ISR(0x86);	ISR(0x87);
 4e8:	6a 00                	push   $0x0
 4ea:	68 84 00 00 00       	push   $0x84
 4ef:	e9 0c fb ff ff       	jmp    0 <isr_save>

000004f4 <isr_0x85>:
 4f4:	6a 00                	push   $0x0
 4f6:	68 85 00 00 00       	push   $0x85
 4fb:	e9 00 fb ff ff       	jmp    0 <isr_save>

00000500 <isr_0x86>:
 500:	6a 00                	push   $0x0
 502:	68 86 00 00 00       	push   $0x86
 507:	e9 f4 fa ff ff       	jmp    0 <isr_save>

0000050c <isr_0x87>:
 50c:	6a 00                	push   $0x0
 50e:	68 87 00 00 00       	push   $0x87
 513:	e9 e8 fa ff ff       	jmp    0 <isr_save>

00000518 <isr_0x88>:
ISR(0x88);	ISR(0x89);	ISR(0x8a);	ISR(0x8b);
 518:	6a 00                	push   $0x0
 51a:	68 88 00 00 00       	push   $0x88
 51f:	e9 dc fa ff ff       	jmp    0 <isr_save>

00000524 <isr_0x89>:
 524:	6a 00                	push   $0x0
 526:	68 89 00 00 00       	push   $0x89
 52b:	e9 d0 fa ff ff       	jmp    0 <isr_save>

00000530 <isr_0x8a>:
 530:	6a 00                	push   $0x0
 532:	68 8a 00 00 00       	push   $0x8a
 537:	e9 c4 fa ff ff       	jmp    0 <isr_save>

0000053c <isr_0x8b>:
 53c:	6a 00                	push   $0x0
 53e:	68 8b 00 00 00       	push   $0x8b
 543:	e9 b8 fa ff ff       	jmp    0 <isr_save>

00000548 <isr_0x8c>:
ISR(0x8c);	ISR(0x8d);	ISR(0x8e);	ISR(0x8f);
 548:	6a 00                	push   $0x0
 54a:	68 8c 00 00 00       	push   $0x8c
 54f:	e9 ac fa ff ff       	jmp    0 <isr_save>

00000554 <isr_0x8d>:
 554:	6a 00                	push   $0x0
 556:	68 8d 00 00 00       	push   $0x8d
 55b:	e9 a0 fa ff ff       	jmp    0 <isr_save>

00000560 <isr_0x8e>:
 560:	6a 00                	push   $0x0
 562:	68 8e 00 00 00       	push   $0x8e
 567:	e9 94 fa ff ff       	jmp    0 <isr_save>

0000056c <isr_0x8f>:
 56c:	6a 00                	push   $0x0
 56e:	68 8f 00 00 00       	push   $0x8f
 573:	e9 88 fa ff ff       	jmp    0 <isr_save>

00000578 <isr_0x90>:
ISR(0x90);	ISR(0x91);	ISR(0x92);	ISR(0x93);
 578:	6a 00                	push   $0x0
 57a:	68 90 00 00 00       	push   $0x90
 57f:	e9 7c fa ff ff       	jmp    0 <isr_save>

00000584 <isr_0x91>:
 584:	6a 00                	push   $0x0
 586:	68 91 00 00 00       	push   $0x91
 58b:	e9 70 fa ff ff       	jmp    0 <isr_save>

00000590 <isr_0x92>:
 590:	6a 00                	push   $0x0
 592:	68 92 00 00 00       	push   $0x92
 597:	e9 64 fa ff ff       	jmp    0 <isr_save>

0000059c <isr_0x93>:
 59c:	6a 00                	push   $0x0
 59e:	68 93 00 00 00       	push   $0x93
 5a3:	e9 58 fa ff ff       	jmp    0 <isr_save>

000005a8 <isr_0x94>:
ISR(0x94);	ISR(0x95);	ISR(0x96);	ISR(0x97);
 5a8:	6a 00                	push   $0x0
 5aa:	68 94 00 00 00       	push   $0x94
 5af:	e9 4c fa ff ff       	jmp    0 <isr_save>

000005b4 <isr_0x95>:
 5b4:	6a 00                	push   $0x0
 5b6:	68 95 00 00 00       	push   $0x95
 5bb:	e9 40 fa ff ff       	jmp    0 <isr_save>

000005c0 <isr_0x96>:
 5c0:	6a 00                	push   $0x0
 5c2:	68 96 00 00 00       	push   $0x96
 5c7:	e9 34 fa ff ff       	jmp    0 <isr_save>

000005cc <isr_0x97>:
 5cc:	6a 00                	push   $0x0
 5ce:	68 97 00 00 00       	push   $0x97
 5d3:	e9 28 fa ff ff       	jmp    0 <isr_save>

000005d8 <isr_0x98>:
ISR(0x98);	ISR(0x99);	ISR(0x9a);	ISR(0x9b);
 5d8:	6a 00                	push   $0x0
 5da:	68 98 00 00 00       	push   $0x98
 5df:	e9 1c fa ff ff       	jmp    0 <isr_save>

000005e4 <isr_0x99>:
 5e4:	6a 00                	push   $0x0
 5e6:	68 99 00 00 00       	push   $0x99
 5eb:	e9 10 fa ff ff       	jmp    0 <isr_save>

000005f0 <isr_0x9a>:
 5f0:	6a 00                	push   $0x0
 5f2:	68 9a 00 00 00       	push   $0x9a
 5f7:	e9 04 fa ff ff       	jmp    0 <isr_save>

000005fc <isr_0x9b>:
 5fc:	6a 00                	push   $0x0
 5fe:	68 9b 00 00 00       	push   $0x9b
 603:	e9 f8 f9 ff ff       	jmp    0 <isr_save>

00000608 <isr_0x9c>:
ISR(0x9c);	ISR(0x9d);	ISR(0x9e);	ISR(0x9f);
 608:	6a 00                	push   $0x0
 60a:	68 9c 00 00 00       	push   $0x9c
 60f:	e9 ec f9 ff ff       	jmp    0 <isr_save>

00000614 <isr_0x9d>:
 614:	6a 00                	push   $0x0
 616:	68 9d 00 00 00       	push   $0x9d
 61b:	e9 e0 f9 ff ff       	jmp    0 <isr_save>

00000620 <isr_0x9e>:
 620:	6a 00                	push   $0x0
 622:	68 9e 00 00 00       	push   $0x9e
 627:	e9 d4 f9 ff ff       	jmp    0 <isr_save>

0000062c <isr_0x9f>:
 62c:	6a 00                	push   $0x0
 62e:	68 9f 00 00 00       	push   $0x9f
 633:	e9 c8 f9 ff ff       	jmp    0 <isr_save>

00000638 <isr_0xa0>:
ISR(0xa0);	ISR(0xa1);	ISR(0xa2);	ISR(0xa3);
 638:	6a 00                	push   $0x0
 63a:	68 a0 00 00 00       	push   $0xa0
 63f:	e9 bc f9 ff ff       	jmp    0 <isr_save>

00000644 <isr_0xa1>:
 644:	6a 00                	push   $0x0
 646:	68 a1 00 00 00       	push   $0xa1
 64b:	e9 b0 f9 ff ff       	jmp    0 <isr_save>

00000650 <isr_0xa2>:
 650:	6a 00                	push   $0x0
 652:	68 a2 00 00 00       	push   $0xa2
 657:	e9 a4 f9 ff ff       	jmp    0 <isr_save>

0000065c <isr_0xa3>:
 65c:	6a 00                	push   $0x0
 65e:	68 a3 00 00 00       	push   $0xa3
 663:	e9 98 f9 ff ff       	jmp    0 <isr_save>

00000668 <isr_0xa4>:
ISR(0xa4);	ISR(0xa5);	ISR(0xa6);	ISR(0xa7);
 668:	6a 00                	push   $0x0
 66a:	68 a4 00 00 00       	push   $0xa4
 66f:	e9 8c f9 ff ff       	jmp    0 <isr_save>

00000674 <isr_0xa5>:
 674:	6a 00                	push   $0x0
 676:	68 a5 00 00 00       	push   $0xa5
 67b:	e9 80 f9 ff ff       	jmp    0 <isr_save>

00000680 <isr_0xa6>:
 680:	6a 00                	push   $0x0
 682:	68 a6 00 00 00       	push   $0xa6
 687:	e9 74 f9 ff ff       	jmp    0 <isr_save>

0000068c <isr_0xa7>:
 68c:	6a 00                	push   $0x0
 68e:	68 a7 00 00 00       	push   $0xa7
 693:	e9 68 f9 ff ff       	jmp    0 <isr_save>

00000698 <isr_0xa8>:
ISR(0xa8);	ISR(0xa9);	ISR(0xaa);	ISR(0xab);
 698:	6a 00                	push   $0x0
 69a:	68 a8 00 00 00       	push   $0xa8
 69f:	e9 5c f9 ff ff       	jmp    0 <isr_save>

000006a4 <isr_0xa9>:
 6a4:	6a 00                	push   $0x0
 6a6:	68 a9 00 00 00       	push   $0xa9
 6ab:	e9 50 f9 ff ff       	jmp    0 <isr_save>

000006b0 <isr_0xaa>:
 6b0:	6a 00                	push   $0x0
 6b2:	68 aa 00 00 00       	push   $0xaa
 6b7:	e9 44 f9 ff ff       	jmp    0 <isr_save>

000006bc <isr_0xab>:
 6bc:	6a 00                	push   $0x0
 6be:	68 ab 00 00 00       	push   $0xab
 6c3:	e9 38 f9 ff ff       	jmp    0 <isr_save>

000006c8 <isr_0xac>:
ISR(0xac);	ISR(0xad);	ISR(0xae);	ISR(0xaf);
 6c8:	6a 00                	push   $0x0
 6ca:	68 ac 00 00 00       	push   $0xac
 6cf:	e9 2c f9 ff ff       	jmp    0 <isr_save>

000006d4 <isr_0xad>:
 6d4:	6a 00                	push   $0x0
 6d6:	68 ad 00 00 00       	push   $0xad
 6db:	e9 20 f9 ff ff       	jmp    0 <isr_save>

000006e0 <isr_0xae>:
 6e0:	6a 00                	push   $0x0
 6e2:	68 ae 00 00 00       	push   $0xae
 6e7:	e9 14 f9 ff ff       	jmp    0 <isr_save>

000006ec <isr_0xaf>:
 6ec:	6a 00                	push   $0x0
 6ee:	68 af 00 00 00       	push   $0xaf
 6f3:	e9 08 f9 ff ff       	jmp    0 <isr_save>

000006f8 <isr_0xb0>:
ISR(0xb0);	ISR(0xb1);	ISR(0xb2);	ISR(0xb3);
 6f8:	6a 00                	push   $0x0
 6fa:	68 b0 00 00 00       	push   $0xb0
 6ff:	e9 fc f8 ff ff       	jmp    0 <isr_save>

00000704 <isr_0xb1>:
 704:	6a 00                	push   $0x0
 706:	68 b1 00 00 00       	push   $0xb1
 70b:	e9 f0 f8 ff ff       	jmp    0 <isr_save>

00000710 <isr_0xb2>:
 710:	6a 00                	push   $0x0
 712:	68 b2 00 00 00       	push   $0xb2
 717:	e9 e4 f8 ff ff       	jmp    0 <isr_save>

0000071c <isr_0xb3>:
 71c:	6a 00                	push   $0x0
 71e:	68 b3 00 00 00       	push   $0xb3
 723:	e9 d8 f8 ff ff       	jmp    0 <isr_save>

00000728 <isr_0xb4>:
ISR(0xb4);	ISR(0xb5);	ISR(0xb6);	ISR(0xb7);
 728:	6a 00                	push   $0x0
 72a:	68 b4 00 00 00       	push   $0xb4
 72f:	e9 cc f8 ff ff       	jmp    0 <isr_save>

00000734 <isr_0xb5>:
 734:	6a 00                	push   $0x0
 736:	68 b5 00 00 00       	push   $0xb5
 73b:	e9 c0 f8 ff ff       	jmp    0 <isr_save>

00000740 <isr_0xb6>:
 740:	6a 00                	push   $0x0
 742:	68 b6 00 00 00       	push   $0xb6
 747:	e9 b4 f8 ff ff       	jmp    0 <isr_save>

0000074c <isr_0xb7>:
 74c:	6a 00                	push   $0x0
 74e:	68 b7 00 00 00       	push   $0xb7
 753:	e9 a8 f8 ff ff       	jmp    0 <isr_save>

00000758 <isr_0xb8>:
ISR(0xb8);	ISR(0xb9);	ISR(0xba);	ISR(0xbb);
 758:	6a 00                	push   $0x0
 75a:	68 b8 00 00 00       	push   $0xb8
 75f:	e9 9c f8 ff ff       	jmp    0 <isr_save>

00000764 <isr_0xb9>:
 764:	6a 00                	push   $0x0
 766:	68 b9 00 00 00       	push   $0xb9
 76b:	e9 90 f8 ff ff       	jmp    0 <isr_save>

00000770 <isr_0xba>:
 770:	6a 00                	push   $0x0
 772:	68 ba 00 00 00       	push   $0xba
 777:	e9 84 f8 ff ff       	jmp    0 <isr_save>

0000077c <isr_0xbb>:
 77c:	6a 00                	push   $0x0
 77e:	68 bb 00 00 00       	push   $0xbb
 783:	e9 78 f8 ff ff       	jmp    0 <isr_save>

00000788 <isr_0xbc>:
ISR(0xbc);	ISR(0xbd);	ISR(0xbe);	ISR(0xbf);
 788:	6a 00                	push   $0x0
 78a:	68 bc 00 00 00       	push   $0xbc
 78f:	e9 6c f8 ff ff       	jmp    0 <isr_save>

00000794 <isr_0xbd>:
 794:	6a 00                	push   $0x0
 796:	68 bd 00 00 00       	push   $0xbd
 79b:	e9 60 f8 ff ff       	jmp    0 <isr_save>

000007a0 <isr_0xbe>:
 7a0:	6a 00                	push   $0x0
 7a2:	68 be 00 00 00       	push   $0xbe
 7a7:	e9 54 f8 ff ff       	jmp    0 <isr_save>

000007ac <isr_0xbf>:
 7ac:	6a 00                	push   $0x0
 7ae:	68 bf 00 00 00       	push   $0xbf
 7b3:	e9 48 f8 ff ff       	jmp    0 <isr_save>

000007b8 <isr_0xc0>:
ISR(0xc0);	ISR(0xc1);	ISR(0xc2);	ISR(0xc3);
 7b8:	6a 00                	push   $0x0
 7ba:	68 c0 00 00 00       	push   $0xc0
 7bf:	e9 3c f8 ff ff       	jmp    0 <isr_save>

000007c4 <isr_0xc1>:
 7c4:	6a 00                	push   $0x0
 7c6:	68 c1 00 00 00       	push   $0xc1
 7cb:	e9 30 f8 ff ff       	jmp    0 <isr_save>

000007d0 <isr_0xc2>:
 7d0:	6a 00                	push   $0x0
 7d2:	68 c2 00 00 00       	push   $0xc2
 7d7:	e9 24 f8 ff ff       	jmp    0 <isr_save>

000007dc <isr_0xc3>:
 7dc:	6a 00                	push   $0x0
 7de:	68 c3 00 00 00       	push   $0xc3
 7e3:	e9 18 f8 ff ff       	jmp    0 <isr_save>

000007e8 <isr_0xc4>:
ISR(0xc4);	ISR(0xc5);	ISR(0xc6);	ISR(0xc7);
 7e8:	6a 00                	push   $0x0
 7ea:	68 c4 00 00 00       	push   $0xc4
 7ef:	e9 0c f8 ff ff       	jmp    0 <isr_save>

000007f4 <isr_0xc5>:
 7f4:	6a 00                	push   $0x0
 7f6:	68 c5 00 00 00       	push   $0xc5
 7fb:	e9 00 f8 ff ff       	jmp    0 <isr_save>

00000800 <isr_0xc6>:
 800:	6a 00                	push   $0x0
 802:	68 c6 00 00 00       	push   $0xc6
 807:	e9 f4 f7 ff ff       	jmp    0 <isr_save>

0000080c <isr_0xc7>:
 80c:	6a 00                	push   $0x0
 80e:	68 c7 00 00 00       	push   $0xc7
 813:	e9 e8 f7 ff ff       	jmp    0 <isr_save>

00000818 <isr_0xc8>:
ISR(0xc8);	ISR(0xc9);	ISR(0xca);	ISR(0xcb);
 818:	6a 00                	push   $0x0
 81a:	68 c8 00 00 00       	push   $0xc8
 81f:	e9 dc f7 ff ff       	jmp    0 <isr_save>

00000824 <isr_0xc9>:
 824:	6a 00                	push   $0x0
 826:	68 c9 00 00 00       	push   $0xc9
 82b:	e9 d0 f7 ff ff       	jmp    0 <isr_save>

00000830 <isr_0xca>:
 830:	6a 00                	push   $0x0
 832:	68 ca 00 00 00       	push   $0xca
 837:	e9 c4 f7 ff ff       	jmp    0 <isr_save>

0000083c <isr_0xcb>:
 83c:	6a 00                	push   $0x0
 83e:	68 cb 00 00 00       	push   $0xcb
 843:	e9 b8 f7 ff ff       	jmp    0 <isr_save>

00000848 <isr_0xcc>:
ISR(0xcc);	ISR(0xcd);	ISR(0xce);	ISR(0xcf);
 848:	6a 00                	push   $0x0
 84a:	68 cc 00 00 00       	push   $0xcc
 84f:	e9 ac f7 ff ff       	jmp    0 <isr_save>

00000854 <isr_0xcd>:
 854:	6a 00                	push   $0x0
 856:	68 cd 00 00 00       	push   $0xcd
 85b:	e9 a0 f7 ff ff       	jmp    0 <isr_save>

00000860 <isr_0xce>:
 860:	6a 00                	push   $0x0
 862:	68 ce 00 00 00       	push   $0xce
 867:	e9 94 f7 ff ff       	jmp    0 <isr_save>

0000086c <isr_0xcf>:
 86c:	6a 00                	push   $0x0
 86e:	68 cf 00 00 00       	push   $0xcf
 873:	e9 88 f7 ff ff       	jmp    0 <isr_save>

00000878 <isr_0xd0>:
ISR(0xd0);	ISR(0xd1);	ISR(0xd2);	ISR(0xd3);
 878:	6a 00                	push   $0x0
 87a:	68 d0 00 00 00       	push   $0xd0
 87f:	e9 7c f7 ff ff       	jmp    0 <isr_save>

00000884 <isr_0xd1>:
 884:	6a 00                	push   $0x0
 886:	68 d1 00 00 00       	push   $0xd1
 88b:	e9 70 f7 ff ff       	jmp    0 <isr_save>

00000890 <isr_0xd2>:
 890:	6a 00                	push   $0x0
 892:	68 d2 00 00 00       	push   $0xd2
 897:	e9 64 f7 ff ff       	jmp    0 <isr_save>

0000089c <isr_0xd3>:
 89c:	6a 00                	push   $0x0
 89e:	68 d3 00 00 00       	push   $0xd3
 8a3:	e9 58 f7 ff ff       	jmp    0 <isr_save>

000008a8 <isr_0xd4>:
ISR(0xd4);	ISR(0xd5);	ISR(0xd6);	ISR(0xd7);
 8a8:	6a 00                	push   $0x0
 8aa:	68 d4 00 00 00       	push   $0xd4
 8af:	e9 4c f7 ff ff       	jmp    0 <isr_save>

000008b4 <isr_0xd5>:
 8b4:	6a 00                	push   $0x0
 8b6:	68 d5 00 00 00       	push   $0xd5
 8bb:	e9 40 f7 ff ff       	jmp    0 <isr_save>

000008c0 <isr_0xd6>:
 8c0:	6a 00                	push   $0x0
 8c2:	68 d6 00 00 00       	push   $0xd6
 8c7:	e9 34 f7 ff ff       	jmp    0 <isr_save>

000008cc <isr_0xd7>:
 8cc:	6a 00                	push   $0x0
 8ce:	68 d7 00 00 00       	push   $0xd7
 8d3:	e9 28 f7 ff ff       	jmp    0 <isr_save>

000008d8 <isr_0xd8>:
ISR(0xd8);	ISR(0xd9);	ISR(0xda);	ISR(0xdb);
 8d8:	6a 00                	push   $0x0
 8da:	68 d8 00 00 00       	push   $0xd8
 8df:	e9 1c f7 ff ff       	jmp    0 <isr_save>

000008e4 <isr_0xd9>:
 8e4:	6a 00                	push   $0x0
 8e6:	68 d9 00 00 00       	push   $0xd9
 8eb:	e9 10 f7 ff ff       	jmp    0 <isr_save>

000008f0 <isr_0xda>:
 8f0:	6a 00                	push   $0x0
 8f2:	68 da 00 00 00       	push   $0xda
 8f7:	e9 04 f7 ff ff       	jmp    0 <isr_save>

000008fc <isr_0xdb>:
 8fc:	6a 00                	push   $0x0
 8fe:	68 db 00 00 00       	push   $0xdb
 903:	e9 f8 f6 ff ff       	jmp    0 <isr_save>

00000908 <isr_0xdc>:
ISR(0xdc);	ISR(0xdd);	ISR(0xde);	ISR(0xdf);
 908:	6a 00                	push   $0x0
 90a:	68 dc 00 00 00       	push   $0xdc
 90f:	e9 ec f6 ff ff       	jmp    0 <isr_save>

00000914 <isr_0xdd>:
 914:	6a 00                	push   $0x0
 916:	68 dd 00 00 00       	push   $0xdd
 91b:	e9 e0 f6 ff ff       	jmp    0 <isr_save>

00000920 <isr_0xde>:
 920:	6a 00                	push   $0x0
 922:	68 de 00 00 00       	push   $0xde
 927:	e9 d4 f6 ff ff       	jmp    0 <isr_save>

0000092c <isr_0xdf>:
 92c:	6a 00                	push   $0x0
 92e:	68 df 00 00 00       	push   $0xdf
 933:	e9 c8 f6 ff ff       	jmp    0 <isr_save>

00000938 <isr_0xe0>:
ISR(0xe0);	ISR(0xe1);	ISR(0xe2);	ISR(0xe3);
 938:	6a 00                	push   $0x0
 93a:	68 e0 00 00 00       	push   $0xe0
 93f:	e9 bc f6 ff ff       	jmp    0 <isr_save>

00000944 <isr_0xe1>:
 944:	6a 00                	push   $0x0
 946:	68 e1 00 00 00       	push   $0xe1
 94b:	e9 b0 f6 ff ff       	jmp    0 <isr_save>

00000950 <isr_0xe2>:
 950:	6a 00                	push   $0x0
 952:	68 e2 00 00 00       	push   $0xe2
 957:	e9 a4 f6 ff ff       	jmp    0 <isr_save>

0000095c <isr_0xe3>:
 95c:	6a 00                	push   $0x0
 95e:	68 e3 00 00 00       	push   $0xe3
 963:	e9 98 f6 ff ff       	jmp    0 <isr_save>

00000968 <isr_0xe4>:
ISR(0xe4);	ISR(0xe5);	ISR(0xe6);	ISR(0xe7);
 968:	6a 00                	push   $0x0
 96a:	68 e4 00 00 00       	push   $0xe4
 96f:	e9 8c f6 ff ff       	jmp    0 <isr_save>

00000974 <isr_0xe5>:
 974:	6a 00                	push   $0x0
 976:	68 e5 00 00 00       	push   $0xe5
 97b:	e9 80 f6 ff ff       	jmp    0 <isr_save>

00000980 <isr_0xe6>:
 980:	6a 00                	push   $0x0
 982:	68 e6 00 00 00       	push   $0xe6
 987:	e9 74 f6 ff ff       	jmp    0 <isr_save>

0000098c <isr_0xe7>:
 98c:	6a 00                	push   $0x0
 98e:	68 e7 00 00 00       	push   $0xe7
 993:	e9 68 f6 ff ff       	jmp    0 <isr_save>

00000998 <isr_0xe8>:
ISR(0xe8);	ISR(0xe9);	ISR(0xea);	ISR(0xeb);
 998:	6a 00                	push   $0x0
 99a:	68 e8 00 00 00       	push   $0xe8
 99f:	e9 5c f6 ff ff       	jmp    0 <isr_save>

000009a4 <isr_0xe9>:
 9a4:	6a 00                	push   $0x0
 9a6:	68 e9 00 00 00       	push   $0xe9
 9ab:	e9 50 f6 ff ff       	jmp    0 <isr_save>

000009b0 <isr_0xea>:
 9b0:	6a 00                	push   $0x0
 9b2:	68 ea 00 00 00       	push   $0xea
 9b7:	e9 44 f6 ff ff       	jmp    0 <isr_save>

000009bc <isr_0xeb>:
 9bc:	6a 00                	push   $0x0
 9be:	68 eb 00 00 00       	push   $0xeb
 9c3:	e9 38 f6 ff ff       	jmp    0 <isr_save>

000009c8 <isr_0xec>:
ISR(0xec);	ISR(0xed);	ISR(0xee);	ISR(0xef);
 9c8:	6a 00                	push   $0x0
 9ca:	68 ec 00 00 00       	push   $0xec
 9cf:	e9 2c f6 ff ff       	jmp    0 <isr_save>

000009d4 <isr_0xed>:
 9d4:	6a 00                	push   $0x0
 9d6:	68 ed 00 00 00       	push   $0xed
 9db:	e9 20 f6 ff ff       	jmp    0 <isr_save>

000009e0 <isr_0xee>:
 9e0:	6a 00                	push   $0x0
 9e2:	68 ee 00 00 00       	push   $0xee
 9e7:	e9 14 f6 ff ff       	jmp    0 <isr_save>

000009ec <isr_0xef>:
 9ec:	6a 00                	push   $0x0
 9ee:	68 ef 00 00 00       	push   $0xef
 9f3:	e9 08 f6 ff ff       	jmp    0 <isr_save>

000009f8 <isr_0xf0>:
ISR(0xf0);	ISR(0xf1);	ISR(0xf2);	ISR(0xf3);
 9f8:	6a 00                	push   $0x0
 9fa:	68 f0 00 00 00       	push   $0xf0
 9ff:	e9 fc f5 ff ff       	jmp    0 <isr_save>

00000a04 <isr_0xf1>:
 a04:	6a 00                	push   $0x0
 a06:	68 f1 00 00 00       	push   $0xf1
 a0b:	e9 f0 f5 ff ff       	jmp    0 <isr_save>

00000a10 <isr_0xf2>:
 a10:	6a 00                	push   $0x0
 a12:	68 f2 00 00 00       	push   $0xf2
 a17:	e9 e4 f5 ff ff       	jmp    0 <isr_save>

00000a1c <isr_0xf3>:
 a1c:	6a 00                	push   $0x0
 a1e:	68 f3 00 00 00       	push   $0xf3
 a23:	e9 d8 f5 ff ff       	jmp    0 <isr_save>

00000a28 <isr_0xf4>:
ISR(0xf4);	ISR(0xf5);	ISR(0xf6);	ISR(0xf7);
 a28:	6a 00                	push   $0x0
 a2a:	68 f4 00 00 00       	push   $0xf4
 a2f:	e9 cc f5 ff ff       	jmp    0 <isr_save>

00000a34 <isr_0xf5>:
 a34:	6a 00                	push   $0x0
 a36:	68 f5 00 00 00       	push   $0xf5
 a3b:	e9 c0 f5 ff ff       	jmp    0 <isr_save>

00000a40 <isr_0xf6>:
 a40:	6a 00                	push   $0x0
 a42:	68 f6 00 00 00       	push   $0xf6
 a47:	e9 b4 f5 ff ff       	jmp    0 <isr_save>

00000a4c <isr_0xf7>:
 a4c:	6a 00                	push   $0x0
 a4e:	68 f7 00 00 00       	push   $0xf7
 a53:	e9 a8 f5 ff ff       	jmp    0 <isr_save>

00000a58 <isr_0xf8>:
ISR(0xf8);	ISR(0xf9);	ISR(0xfa);	ISR(0xfb);
 a58:	6a 00                	push   $0x0
 a5a:	68 f8 00 00 00       	push   $0xf8
 a5f:	e9 9c f5 ff ff       	jmp    0 <isr_save>

00000a64 <isr_0xf9>:
 a64:	6a 00                	push   $0x0
 a66:	68 f9 00 00 00       	push   $0xf9
 a6b:	e9 90 f5 ff ff       	jmp    0 <isr_save>

00000a70 <isr_0xfa>:
 a70:	6a 00                	push   $0x0
 a72:	68 fa 00 00 00       	push   $0xfa
 a77:	e9 84 f5 ff ff       	jmp    0 <isr_save>

00000a7c <isr_0xfb>:
 a7c:	6a 00                	push   $0x0
 a7e:	68 fb 00 00 00       	push   $0xfb
 a83:	e9 78 f5 ff ff       	jmp    0 <isr_save>

00000a88 <isr_0xfc>:
ISR(0xfc);	ISR(0xfd);	ISR(0xfe);	ISR(0xff);
 a88:	6a 00                	push   $0x0
 a8a:	68 fc 00 00 00       	push   $0xfc
 a8f:	e9 6c f5 ff ff       	jmp    0 <isr_save>

00000a94 <isr_0xfd>:
 a94:	6a 00                	push   $0x0
 a96:	68 fd 00 00 00       	push   $0xfd
 a9b:	e9 60 f5 ff ff       	jmp    0 <isr_save>

00000aa0 <isr_0xfe>:
 aa0:	6a 00                	push   $0x0
 aa2:	68 fe 00 00 00       	push   $0xfe
 aa7:	e9 54 f5 ff ff       	jmp    0 <isr_save>

00000aac <isr_0xff>:
 aac:	6a 00                	push   $0x0
 aae:	68 ff 00 00 00       	push   $0xff
 ab3:	e9 48 f5 ff ff       	jmp    0 <isr_save>
