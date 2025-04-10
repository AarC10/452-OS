
boot.o:     file format elf32-i386


Disassembly of section .text:

00000000 <bootentry>:
bootentry:

/*
** Entry point.  Disable interrupts and set up a runtime stack.
*/
	cli
   0:	fa                   	cli    

	movw	$BOOT_SEG, %ax	/* data seg. base address */
   1:	b8 c0 07 8e d8       	mov    $0xd88e07c0,%eax
	movw	%ax, %ds
	movw	%ax, %ss		/* also stack seg. base */
   6:	8e d0                	mov    %eax,%ss
	movw	$BOOT_SP_DISP, %ax
   8:	b8 00 40 89 c4       	mov    $0xc4894000,%eax
	movw	%ax, %sp

/*
** Next, verify that the disk is there and working.
*/
	movb	$BD_CHECK, %ah /* test the disk status and make sure */
   d:	b4 01                	mov    $0x1,%ah
	movb	drive, %dl	 /* it's safe to proceed */
   f:	8a 16                	mov    (%esi),%dl
  11:	fc                   	cld    
  12:	01 cd                	add    %ecx,%ebp
	int	$BIOS_DISK
  14:	13 73 08             	adc    0x8(%ebx),%esi
	jnc	diskok

	movw	$err_diskstatus, %si /* Something went wrong; print a message */
  17:	be 4f 01 e8 ef       	mov    $0xefe8014f,%esi
	call	dispMsg		/* and freeze. */
  1c:	00 eb                	add    %ch,%bl
	jmp	.
  1e:	fe                   	.byte 0xfe

0000001f <diskok>:

/*
** The disk is there. Reset it, and retrieve the disk parameters.
*/
diskok:
	movw	$BD_RESET, %ax	/* Reset the disk */
  1f:	b8 00 00 8a 16       	mov    $0x168a0000,%eax
	movb	drive, %dl
  24:	fc                   	cld    
  25:	01 cd                	add    %ecx,%ebp
	int	$BIOS_DISK
  27:	13 31                	adc    (%ecx),%esi

	/* determine number of heads and sectors/track */
	xorw	%ax, %ax    /* set ES:DI = 0000:0000 in case of BIOS bugs */
  29:	c0 8e c0 89 c7 b4 08 	rorb   $0x8,-0x4b387640(%esi)
	movw	%ax, %es
	movw	%ax, %di
	movb	$BD_PARAMS, %ah	/* get drive parameters */
	movb	drive, %dl	/* hard disk or floppy */
  30:	8a 16                	mov    (%esi),%dl
  32:	fc                   	cld    
  33:	01 cd                	add    %ecx,%ebp
	int	$BIOS_DISK
  35:	13 80 e1 3f fe c1    	adc    -0x3e01c01f(%eax),%eax

	/* store (max + 1) - CL[5:0] = maximum head, DH = maximum head */
	andb	$0x3F, %cl
	incb	%cl
	incb	%dh
  3b:	fe c6                	inc    %dh

	movb	%cl, max_sec
  3d:	88 0e                	mov    %cl,(%esi)
  3f:	3b 01                	cmp    (%ecx),%eax
	movb	%dh, max_head
  41:	88 36                	mov    %dh,(%esi)
  43:	3c 01                	cmp    $0x1,%al
/*
** The disk is OK, so we now need to load the second half of the bootstrap.
** It must immediately follow the boot sector on the disk, and the target
** program(s) must immediately follow that.
*/
	movw	$msg_loading, %si /* Print the Loading message */
  45:	be 3d 01 e8 c1       	mov    $0xc1e8013d,%esi
	call	dispMsg
  4a:	00 b8 01 00 bb c0    	add    %bh,-0x3f44ffff(%eax)

	movw	$1, %ax			/* sector count = 1 */
	movw	$BOOT_SEG, %bx	/* read this into memory that */
  50:	07                   	pop    %es
	movw	%bx, %es		/* immediately follows this code. */
  51:	8e c3                	mov    %ebx,%es
	movw	$PART2_DISP, %bx
  53:	bb 00 02 e8 2e       	mov    $0x2ee80200,%ebx
	call	readprog
  58:	00 bf fe 03 1e 8b    	add    %bh,-0x74e1fc02(%edi)
** count field for the next block to load.
*/
	movw	$k_sect, %di

	pushw	%ds
	movw	(%di), %bx
  5e:	1d b8 d0 02 8e       	sbb    $0x8e02d0b8,%eax
	movw	$MMAP_SEG, %ax
	movw	%ax, %ds
  63:	d8 89 1e 0a 00 1f    	fmuls  0x1f000a1e(%ecx)

00000069 <nextblock>:
** Each target program has three values in the array at the end of the
** second half of the bootstrap:  the offset and segment base address
** where the program should go, and the sector count.
*/
nextblock:
	movw	(%di), %ax	/* get the # of sectors */
  69:	8b 05 85 c0 0f 84    	mov    0x840fc085,%eax
	testw	%ax, %ax	/* is it zero? */
	jz	done_loading	/*   yes, nothing more to load. */
  6f:	92                   	xchg   %eax,%edx
  70:	00 83 ef 02 8b 1d    	add    %al,0x1d8b02ef(%ebx)

	subw	$2, %di
	movw	(%di), %bx	/* get the segment value */
	movw	%bx, %es	/*   and copy it to %es */
  76:	8e c3                	mov    %ebx,%es
	subw	$2, %di
  78:	83 ef 02             	sub    $0x2,%edi
	movw	(%di), %bx	/* get the address offset */
  7b:	8b 1d 83 ef 02 57    	mov    0x5702ef83,%ebx
	subw	$2, %di
	pushw	%di		/* save di */
	call	readprog	/* read this program block, */
  81:	e8 03 00 5f eb       	call   eb5f0089 <k_sect+0xeb5efc8b>
	popw	%di		/* and restore di */
	jmp	nextblock	/*   then go back and read the next one. */
  86:	e2                   	.byte 0xe2

00000087 <readprog>:
**
**	ax: number of sectors to read
**	es:bx = starting address for the block
*/
readprog:
	pushw	%ax		/* save sector count */
  87:	50                   	push   %eax

	movw	$3, %cx		/* initial retry count is 3 */
  88:	b9                   	.byte 0xb9
  89:	03 00                	add    (%eax),%eax

0000008b <retry>:
retry:
	pushw	%cx		/* push the retry count on the stack. */
  8b:	51                   	push   %ecx

	movw	sec, %cx	/* get sector number */
  8c:	8b 0e                	mov    (%esi),%ecx
  8e:	37                   	aaa    
  8f:	01 8b 16 39 01 8a    	add    %ecx,-0x75fec6ea(%ebx)
	movw	head, %dx	/* get head number */
	movb	drive, %dl
  95:	16                   	push   %ss
  96:	fc                   	cld    
  97:	01 b8 01 02 cd 13    	add    %edi,0x13cd0201(%eax)

	movw	$BD_READ1, %ax	/* read 1 sector */
	int	$BIOS_DISK
	jnc	readcont	/* jmp if it worked ok */
  9d:	73 11                	jae    b0 <readcont>

	movw	$err_diskread, %si	/* report the error */
  9f:	be 61 01 e8 67       	mov    $0x67e80161,%esi
	call	dispMsg
  a4:	00 59 e2             	add    %bl,-0x1e(%ecx)
	popw	%cx		/* get the retry count back */
	loop	retry		/*   and go try again. */
  a7:	e3 be                	jecxz  67 <diskok+0x48>
	movw	$err_diskfail, %si	/* can't proceed, */
  a9:	79 01                	jns    ac <retry+0x21>
	call	dispMsg		/* print message and freeze. */
  ab:	e8 5e 00 eb fe       	call   feeb010e <k_sect+0xfeeafd10>

000000b0 <readcont>:
	jmp	.

readcont:
	movw	$msg_dot, %si	/* print status: a dot */
  b0:	be 45 01 e8 56       	mov    $0x56e80145,%esi
	call	dispMsg
  b5:	00 81 fb 00 fe 74    	add    %al,0x74fe00fb(%ecx)
	cmpw	$OFFSET_LIMIT, %bx	/* have we reached the offset limit? */
	je	adjust		/* Yes--must adjust the es register */
  bb:	06                   	push   %es
	addw	$SECTOR_SIZE, %bx	/* No--just adjust the block size to */
  bc:	81 c3 00 02 eb 0a    	add    $0xaeb0200,%ebx

000000c2 <adjust>:
	jmp	readcont2	/*    the offset and continue. */

adjust:
	movw	$0, %bx		/* start offset over again */
  c2:	bb 00 00 8c c0       	mov    $0xc08c0000,%ebx
	movw	%es, %ax
	addw	$0x1000,%ax	/* move segment pointer to next chunk */
  c7:	05 00 10 8e c0       	add    $0xc08e1000,%eax

000000cc <readcont2>:
	movw	%ax, %es

readcont2:
	incb	%cl		/* not done - move to the next sector */
  cc:	fe c1                	inc    %cl
	cmpb	max_sec, %cl	/* see if we need */
  ce:	3a 0e                	cmp    (%esi),%cl
  d0:	3b 01                	cmp    (%ecx),%eax
	jnz	save_sector	/* to switch heads or tracks */
  d2:	75 1b                	jne    ef <save_sector>

	movb	$1, %cl		/* reset sector number */
  d4:	b1 01                	mov    $0x1,%cl
	incb	%dh		/* first, switch heads */
  d6:	fe c6                	inc    %dh
	cmpb	max_head, %dh	/* there are only two - if we've already */
  d8:	3a 36                	cmp    (%esi),%dh
  da:	3c 01                	cmp    $0x1,%al
	jnz	save_sector	/* used both, we need to switch tracks */
  dc:	75 11                	jne    ef <save_sector>

	xorb	%dh, %dh	/* reset to head 0 */
  de:	30 f6                	xor    %dh,%dh
	incb	%ch		/* inc track number */
  e0:	fe c5                	inc    %ch
	cmpb	$80, %ch	/* 80 tracks per side - have we read all? */
  e2:	80 fd 50             	cmp    $0x50,%ch
	jnz	save_sector	/* read another track */
  e5:	75 08                	jne    ef <save_sector>

	movw	$err_toobig, %si 	/* report the error */
  e7:	be 6f 01 e8 1f       	mov    $0x1fe8016f,%esi
	call	dispMsg
  ec:	00 eb                	add    %ch,%bl
	jmp	.		/* and freeze */
  ee:	fe                   	.byte 0xfe

000000ef <save_sector>:

save_sector:
	movw	%cx, sec	/* save sector number */
  ef:	89 0e                	mov    %ecx,(%esi)
  f1:	37                   	aaa    
  f2:	01 89 16 39 01 58    	add    %ecx,0x58013916(%ecx)
	movw	%dx, head	/*   and head number */

	popw	%ax		/* discard the retry count */
	popw	%ax		/* get the sector count from the stack */
  f8:	58                   	pop    %eax
	decw	%ax		/*   and decrement it. */
  f9:	48                   	dec    %eax
	jg	readprog	/* If it is zero, we're done reading. */
  fa:	7f 8b                	jg     87 <readprog>

000000fc <readdone>:

readdone:
	movw	$msg_bar, %si	/* print message saying this block is done */
  fc:	be 4d 01 e8 0a       	mov    $0xae8014d,%esi
	call	dispMsg
 101:	00 c3                	add    %al,%bl

00000103 <done_loading>:
/*
** We've loaded the whole target program into memory,
** so it's time to transfer to the startup code.
*/
done_loading:
	movw	$msg_go, %si	/* last status message */
 103:	be 47 01 e8 03       	mov    $0x3e80147,%esi
	call	dispMsg
 108:	00 e9                	add    %ch,%cl

	jmp	switch		/* move to the next phase */
 10a:	f4                   	hlt    
	...

0000010c <dispMsg>:
	
/*
** Support routine - display a message byte by byte to the monitor.
*/
dispMsg:	
	pushw	%ax
 10c:	50                   	push   %eax
	pushw	%bx
 10d:	53                   	push   %ebx

0000010e <repeat>:
repeat:
	lodsb			/* grab next character */
 10e:	ac                   	lods   %ds:(%esi),%al

	movb	$BV_W_ADV, %ah	/* write and advance cursor */
 10f:	b4 0e                	mov    $0xe,%ah
	movw	$0x07, %bx	/* page 0, white on blank, no blink */
 111:	bb 07 00 08 c0       	mov    $0xc0080007,%ebx
	orb	%al, %al	/* AL is character to write */
	jz	getOut		/* if we've reached the NUL, get out */
 116:	74 04                	je     11c <getOut>

	int	$BIOS_VIDEO	/* otherwise, print and repeat */
 118:	cd 10                	int    $0x10
	jmp	repeat	
 11a:	eb f2                	jmp    10e <repeat>

0000011c <getOut>:

getOut:				/* we're done, so return */
	popw	%bx
 11c:	5b                   	pop    %ebx
	popw	%ax
 11d:	58                   	pop    %eax
	ret
 11e:	c3                   	ret    

0000011f <move_gdt>:
** Support routine - move the GDT entries from where they are to
** location 0050:0000. We need to add BOOT_ADDR because the bootstrap
** is linked at 0, but loaded at 0x7c00.
*/
move_gdt:
	movw	%cs, %si
 11f:	8c ce                	mov    %cs,%esi
	movw	%si, %ds
 121:	8e de                	mov    %esi,%ds
	movw	$start_gdt + BOOT_ADDR, %si
 123:	be 20 7f bf 50       	mov    $0x50bf7f20,%esi
	movw	$GDT_SEG, %di
 128:	00 8e c7 31 ff 66    	add    %cl,0x66ff31c7(%esi)
	movw	%di, %es
	xorw	%di, %di
	movl	$gdt_len, %ecx
 12e:	b9 28 00 00 00       	mov    $0x28,%ecx
	cld
 133:	fc                   	cld    
	rep	movsb
 134:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
	ret
 136:	c3                   	ret    

00000137 <sec>:
 137:	02 00                	add    (%eax),%al

00000139 <head>:
	...

0000013b <max_sec>:
 13b:	13                   	.byte 0x13

0000013c <max_head>:
 13c:	02                   	.byte 0x2

0000013d <msg_loading>:
 13d:	4c                   	dec    %esp
 13e:	6f                   	outsl  %ds:(%esi),(%dx)
 13f:	61                   	popa   
 140:	64                   	fs
 141:	69                   	.byte 0x69
 142:	6e                   	outsb  %ds:(%esi),(%dx)
 143:	67                   	addr16
	...

00000145 <msg_dot>:
 145:	2e                   	cs
	...

00000147 <msg_go>:
 147:	64 6f                	outsl  %fs:(%esi),(%dx)
 149:	6e                   	outsb  %ds:(%esi),(%dx)
 14a:	65                   	gs
 14b:	2e                   	cs
	...

0000014d <msg_bar>:
 14d:	7c 00                	jl     14f <err_diskstatus>

0000014f <err_diskstatus>:
 14f:	44                   	inc    %esp
 150:	69 73 6b 20 6e 6f 74 	imul   $0x746f6e20,0x6b(%ebx),%esi
 157:	20 72 65             	and    %dh,0x65(%edx)
 15a:	61                   	popa   
 15b:	64 79 2e             	fs jns 18c <gdt_48+0x3>
 15e:	0a                   	.byte 0xa
 15f:	0d                   	.byte 0xd
	...

00000161 <err_diskread>:
 161:	52                   	push   %edx
 162:	65 61                	gs popa 
 164:	64 20 66 61          	and    %ah,%fs:0x61(%esi)
 168:	69                   	.byte 0x69
 169:	6c                   	insb   (%dx),%es:(%edi)
 16a:	65                   	gs
 16b:	64                   	fs
 16c:	0a                   	.byte 0xa
 16d:	0d                   	.byte 0xd
	...

0000016f <err_toobig>:
 16f:	54                   	push   %esp
 170:	6f                   	outsl  %ds:(%esi),(%dx)
 171:	6f                   	outsl  %ds:(%esi),(%dx)
 172:	20 62 69             	and    %ah,0x69(%edx)
 175:	67 0a 0d             	or     (%di),%cl
	...

00000179 <err_diskfail>:
 179:	43                   	inc    %ebx
 17a:	61                   	popa   
 17b:	6e                   	outsb  %ds:(%esi),(%dx)
 17c:	27                   	daa    
 17d:	74 20                	je     19f <idt_48+0xc>
 17f:	70 72                	jo     1f3 <idt_48+0x60>
 181:	6f                   	outsl  %ds:(%esi),(%dx)
 182:	63 65 65             	arpl   %sp,0x65(%ebp)
 185:	64                   	fs
 186:	0a                   	.byte 0xa
 187:	0d                   	.byte 0xd
	...

00000189 <gdt_48>:
 189:	00 20                	add    %ah,(%eax)
 18b:	00 05 00 00 00 00    	add    %al,0x0
	...

00000193 <idt_48>:
 193:	00 08                	add    %cl,(%eax)
 195:	00 25 00 00 00 00    	add    %ah,0x0
	...

000001fc <drive>:
 1fc:	80                   	.byte 0x80
	...

000001fe <boot_sig>:
 1fe:	55                   	push   %ebp
 1ff:	aa                   	stos   %al,%es:(%edi)

00000200 <switch>:
** This code configures the GDT, enters protected mode, and then
** transfers to the OS entry point.
*/

switch:
	cli
 200:	fa                   	cli    
	movb	$NMI_DISABLE, %al	/* also disable NMIs */
 201:	b0 80                	mov    $0x80,%al
	outb	%al, $CMOS_ADDR
 203:	e6 70                	out    %al,$0x70

#ifdef USE_FLOPPY
	call	floppy_off
#endif
	call	enable_A20
 205:	e8 22 00 e8 14       	call   14e8022c <k_sect+0x14e7fe2e>
	call	move_gdt
 20a:	ff                   	(bad)  
#if defined(GET_MMAP) || defined(OS_CONFIG)
	call	check_memory
 20b:	e8 6e 00 0f 01       	call   10f027e <k_sect+0x10efe80>
/*
** The IDTR and GDTR are loaded relative to this segment, so we must
** use the full offsets from the beginning of the segment (0000:0000);
** however, we were loaded at 0000:7c00, so we need to add that in.
*/
	lidt	idt_48 + BOOT_ADDR
 210:	1e                   	push   %ds
 211:	93                   	xchg   %eax,%ebx
 212:	7d 0f                	jge    223 <switch+0x23>
	lgdt	gdt_48 + BOOT_ADDR
 214:	01 16                	add    %edx,(%esi)
 216:	89 7d 0f             	mov    %edi,0xf(%ebp)

	movl	%cr0, %eax	/* get current CR0 */
 219:	20 c0                	and    %al,%al
	orl	$1, %eax	/* set the PE bit */
 21b:	66 83 c8 01          	or     $0x1,%ax
	movl	%eax, %cr0	/* and store it back. */
 21f:	0f 22 c0             	mov    %eax,%cr0
 222:	66 ea 00 00 01 00    	ljmpw  $0x1,$0x0
	**	.word	GDT_CODE
	*/

	.byte	0x66
	.code32
	ljmp	$GDT_CODE, $TARGET_ADDR
 228:	10 00                	adc    %al,(%eax)

0000022a <enable_A20>:

/*
** Enable the A20 gate for full memory access.
*/
enable_A20:
	call	a20wait
 22a:	e8 2d 00 b0 ad       	call   adb0025c <k_sect+0xadaffe5e>
	movb	$KBD_P1_DISABLE, %al
	outb	%al, $KBD_CMD
 22f:	e6 64                	out    %al,$0x64

	call	a20wait
 231:	e8 26 00 b0 d0       	call   d0b0025c <k_sect+0xd0affe5e>
	movb	$KBD_RD_OPORT, %al
	outb	%al, $KBD_CMD
 236:	e6 64                	out    %al,$0x64

	call	a20wait2
 238:	e8 30 00 e4 60       	call   60e4026d <k_sect+0x60e3fe6f>
	inb	$KBD_DATA, %al
	pushl	%eax
 23d:	66 50                	push   %ax

	call	a20wait
 23f:	e8 18 00 b0 d1       	call   d1b0025c <k_sect+0xd1affe5e>
	movb	$KBD_WT_OPORT, %al
	outb	%al, $KBD_CMD
 244:	e6 64                	out    %al,$0x64

	call	a20wait
 246:	e8 11 00 66 58       	call   5866025c <k_sect+0x5865fe5e>
	popl	%eax
	orb	$2, %al
 24b:	0c 02                	or     $0x2,%al
	outb	%al, $KBD_DATA
 24d:	e6 60                	out    %al,$0x60

	call	a20wait
 24f:	e8 08 00 b0 ae       	call   aeb0025c <k_sect+0xaeaffe5e>
	mov	$KBD_P1_ENABLE, %al
	out	%al, $KBD_CMD
 254:	e6 64                	out    %al,$0x64

	call	a20wait
 256:	e8                   	.byte 0xe8
 257:	01 00                	add    %eax,(%eax)
	ret
 259:	c3                   	ret    

0000025a <a20wait>:

a20wait:	/* wait until bit 1 of the device register is clear */
	movl    $65536, %ecx	/* loop a lot if need be */
 25a:	66 b9 00 00          	mov    $0x0,%cx
 25e:	01 00                	add    %eax,(%eax)

00000260 <wait_loop>:
wait_loop: 
	inb     $KBD_STAT, %al	/* grab the byte */
 260:	e4 64                	in     $0x64,%al
	test    $2, %al		/* is the bit clear? */
 262:	a8 02                	test   $0x2,%al
	jz      wait_exit	/* yes */
 264:	74 04                	je     26a <wait_exit>
	loop    wait_loop	/* no, so loop */
 266:	e2 f8                	loop   260 <wait_loop>
	jmp     a20wait		/* if still not clear, go again */
 268:	eb f0                	jmp    25a <a20wait>

0000026a <wait_exit>:
wait_exit:    
	ret
 26a:	c3                   	ret    

0000026b <a20wait2>:

a20wait2:	/* like a20wait, but waits until bit 0 is set. */
	mov     $65536, %ecx
 26b:	66 b9 00 00          	mov    $0x0,%cx
 26f:	01 00                	add    %eax,(%eax)

00000271 <wait2_loop>:
wait2_loop:
	in      $KBD_STAT, %al
 271:	e4 64                	in     $0x64,%al
	test    $1, %al
 273:	a8 01                	test   $0x1,%al
	jnz     wait2_exit
 275:	75 04                	jne    27b <wait2_exit>
	loop    wait2_loop
 277:	e2 f8                	loop   271 <wait2_loop>
	jmp     a20wait2
 279:	eb f0                	jmp    26b <a20wait2>

0000027b <wait2_exit>:
wait2_exit:
	ret
 27b:	c3                   	ret    

0000027c <check_memory>:
**     None
**/
check_memory:
	// save everything
	// pushaw won't work here because we're still in real mode
	pushw	%ds
 27c:	1e                   	push   %ds
	pushw	%es
 27d:	06                   	push   %es
	pushw	%ax
 27e:	50                   	push   %eax
	pushw	%bx
 27f:	53                   	push   %ebx
	pushw	%cx
 280:	51                   	push   %ecx
	pushw	%dx
 281:	52                   	push   %edx
	pushw	%si
 282:	56                   	push   %esi
	pushw	%di
 283:	57                   	push   %edi

	// Set the start of the buffer
	movw	$MMAP_SEG, %bx // 0x2D0
 284:	bb d0 02 8e db       	mov    $0xdb8e02d0,%ebx
	mov	%bx, %ds	// Data segment now starts at 0x2D00
	mov	%bx, %es	// Extended segment also starts at 0x2D00
 289:	8e c3                	mov    %ebx,%es

	// Reserve the first 4 bytes for the # of entries
	movw	$0x4, %di
 28b:	bf 04 00 26 c7       	mov    $0xc7260004,%edi
	// Make a valid ACPI 3.X entry
	movw	$1, %es:20(%di)
 290:	45                   	inc    %ebp
 291:	14 01                	adc    $0x1,%al
 293:	00 31                	add    %dh,(%ecx)

	xorw	%bp, %bp	// Count of entries in the list
 295:	ed                   	in     (%dx),%eax
	xorl	%ebx, %ebx	// EBX must contain zeroes
 296:	66 31 db             	xor    %bx,%bx

	movl	$MMAP_MAGIC_NUM, %edx	// Magic number into EDX
 299:	66 ba 50 41          	mov    $0x4150,%dx
 29d:	4d                   	dec    %ebp
 29e:	53                   	push   %ebx
	movl	$MMAP_CODE, %eax	// E820 memory command
 29f:	66 b8 20 e8          	mov    $0xe820,%ax
 2a3:	00 00                	add    %al,(%eax)
	movl	$MMAP_ENT, %ecx	// Ask the BIOS for 24 bytes
 2a5:	66 b9 18 00          	mov    $0x18,%cx
 2a9:	00 00                	add    %al,(%eax)
	int	$BIOS_MISC	// Call the BIOS
 2ab:	cd 15                	int    $0x15

	// check for success
	jc	cm_failed	// C == 1 --> failure
 2ad:	72 5d                	jb     30c <cm_failed>
	movl	$MMAP_MAGIC_NUM, %edx	// sometimes EDX changes
 2af:	66 ba 50 41          	mov    $0x4150,%dx
 2b3:	4d                   	dec    %ebp
 2b4:	53                   	push   %ebx
	cmpl	%eax, %edx	// EAX should equal EDX after the call
 2b5:	66 39 c2             	cmp    %ax,%dx
	jne	cm_failed
 2b8:	75 52                	jne    30c <cm_failed>
	testl	%ebx, %ebx	// Should have at least one more entry
 2ba:	66 85 db             	test   %bx,%bx
	je	cm_failed
 2bd:	74 4d                	je     30c <cm_failed>

	jmp	cm_jumpin	// Good to go - start us off
 2bf:	eb 1b                	jmp    2dc <cm_jumpin>

000002c1 <cm_loop>:

cm_loop:
	movl	$MMAP_CODE, %eax	// Reset our registers
 2c1:	66 b8 20 e8          	mov    $0xe820,%ax
 2c5:	00 00                	add    %al,(%eax)
	movw	$1, 20(%di)
 2c7:	c7 45 14 01 00 66 b9 	movl   $0xb9660001,0x14(%ebp)
	movl	$MMAP_ENT, %ecx
 2ce:	18 00                	sbb    %al,(%eax)
 2d0:	00 00                	add    %al,(%eax)
	int	$BIOS_MISC
 2d2:	cd 15                	int    $0x15
	jc	cm_end_of_list	// C == 1 --> end of list
 2d4:	72 2f                	jb     305 <cm_end_of_list>
	movl	$MMAP_MAGIC_NUM, %edx
 2d6:	66 ba 50 41          	mov    $0x4150,%dx
 2da:	4d                   	dec    %ebp
 2db:	53                   	push   %ebx

000002dc <cm_jumpin>:

cm_jumpin:
	jcxz	cm_skip_entry	// Did we get any data?
 2dc:	e3 22                	jecxz  300 <cm_skip_entry>

	cmp	$20, %cl	// Check the byte count
 2de:	80 f9 14             	cmp    $0x14,%cl
	jbe	cm_no_text	// Skip the next test if only 20 bytes
 2e1:	76 07                	jbe    2ea <cm_no_text>

	testb	$1, %es:20(%di) // Check the "ignore this entry" flag
 2e3:	26 f6 45 14 01       	testb  $0x1,%es:0x14(%ebp)
	je	cm_skip_entry
 2e8:	74 16                	je     300 <cm_skip_entry>

000002ea <cm_no_text>:

cm_no_text:
	mov	%es:8(%di), %ecx	// lower half of length
 2ea:	26 66 8b 4d 08       	mov    %es:0x8(%ebp),%cx
	or	%es:12(%di), %ecx	// now, full length
 2ef:	26 66 0b 4d 0c       	or     %es:0xc(%ebp),%cx
	jz	cm_skip_entry
 2f4:	74 0a                	je     300 <cm_skip_entry>

	inc	%bp		// one more valid entry
 2f6:	45                   	inc    %ebp

	// make sure we don't overflow our space
	cmpw	$MMAP_MAX_ENTS, %bp
 2f7:	81 fd 4a 03 7d 08    	cmp    $0x87d034a,%ebp
	jge	cm_end_of_list

	// we're ok - move the pointer to the next struct in the array
	add	$24, %di
 2fd:	83 c7 18             	add    $0x18,%edi

00000300 <cm_skip_entry>:

cm_skip_entry:
	// are there more entries to retrieve?
	testl	%ebx, %ebx
 300:	66 85 db             	test   %bx,%bx
	jne	cm_loop
 303:	75 bc                	jne    2c1 <cm_loop>

00000305 <cm_end_of_list>:

cm_end_of_list:
	// All done!  Store the number of elements in 0x2D00
	movw	%bp, %ds:0x0
 305:	89 2e                	mov    %ebp,(%esi)
 307:	00 00                	add    %al,(%eax)

	clc	// Clear the carry bit and return
 309:	f8                   	clc    
	jmp	cm_ret
 30a:	eb 0a                	jmp    316 <cm_ret>

0000030c <cm_failed>:

cm_failed:
	movl	$-1, %ds:0x0	// indicate failure
 30c:	66 c7 06 00 00       	movw   $0x0,(%esi)
 311:	ff                   	(bad)  
 312:	ff                   	(bad)  
 313:	ff                   	(bad)  
 314:	ff                   	(bad)  
	stc
 315:	f9                   	stc    

00000316 <cm_ret>:

cm_ret:
	// restore everything we saved
	// popaw won't work here (still in real mode!)
	popw	%di
 316:	5f                   	pop    %edi
	popw	%si
 317:	5e                   	pop    %esi
	popw	%dx
 318:	5a                   	pop    %edx
	popw	%cx
 319:	59                   	pop    %ecx
	popw	%bx
 31a:	5b                   	pop    %ebx
	popw	%ax
 31b:	58                   	pop    %eax
	popw	%es
 31c:	07                   	pop    %es
	popw	%ds
 31d:	1f                   	pop    %ds
	ret
 31e:	c3                   	ret    
 31f:	90                   	nop

00000320 <start_gdt>:
	...
 328:	ff                   	(bad)  
 329:	ff 00                	incl   (%eax)
 32b:	00 00                	add    %al,(%eax)
 32d:	92                   	xchg   %eax,%edx
 32e:	cf                   	iret   
 32f:	00 ff                	add    %bh,%bh
 331:	ff 00                	incl   (%eax)
 333:	00 00                	add    %al,(%eax)
 335:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
 33c:	00 92 cf 00 ff ff    	add    %dl,-0xff31(%edx)
 342:	00 00                	add    %al,(%eax)
 344:	00                   	.byte 0x0
 345:	92                   	xchg   %eax,%edx
 346:	cf                   	iret   
	...

00000348 <end_gdt>:
	...

000003f4 <u_off>:
	...

000003f6 <u_seg>:
	...

000003f8 <u_sect>:
	...

000003fa <k_off>:
	...

000003fc <k_seg>:
	...

000003fe <k_sect>:
	...
