	.file	"procs.c"
	.text
.Ltext0:
	.local	pcb_freelist_queue
	.comm	pcb_freelist_queue,12,4
	.local	ready_queue
	.comm	ready_queue,12,4
	.local	waiting_queue
	.comm	waiting_queue,12,4
	.local	sleeping_queue
	.comm	sleeping_queue,12,4
	.local	zombie_queue
	.comm	zombie_queue,12,4
	.local	sioread_queue
	.comm	sioread_queue,12,4
	.comm	pcb_freelist,4,4
	.comm	ready,4,4
	.comm	waiting,4,4
	.comm	sleeping,4,4
	.comm	zombie,4,4
	.comm	sioread,4,4
	.comm	current,4,4
	.comm	ptable,1200,32
	.comm	next_pid,4,4
	.comm	init_pcb,4,4
	.globl	state_str
	.section	.rodata
	.align 32
	.type	state_str, @object
	.size	state_str, 36
state_str:
	.string	"Unu"
	.string	"New"
	.string	"Rdy"
	.string	"Run"
	.string	"Slp"
	.string	"Blk"
	.string	"Wat"
	.string	"Kil"
	.string	"Zom"
	.globl	prio_str
	.align 4
	.type	prio_str, @object
	.size	prio_str, 20
prio_str:
	.string	"High"
	.string	"User"
	.string	"Low "
	.string	"Def "
	.globl	ord_str
	.align 4
	.type	ord_str, @object
	.size	ord_str, 20
ord_str:
	.string	"FIFO"
	.string	"PRIO"
	.string	"PID "
	.string	"WAKE"
.LC0:
	.string	"queue != 0"
.LC1:
	.string	"procs.c"
.LC2:
	.string	"%s (%s @ %d), %d: %s\n"
.LC3:
	.string	"pcb != 0"
	.text
	.type	find_prev_wakeup, @function
find_prev_wakeup:
.LFB34:
	.file 1 "procs.c"
	.loc 1 129 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$24, %esp
	.loc 1 132 0
	cmpl	$0, 8(%ebp)
	jne	.L2
	.loc 1 132 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC0
	pushl	$1
	pushl	$132
	pushl	$.LC1
	pushl	$__func__.1409
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L2:
	.loc 1 133 0 is_stmt 1
	cmpl	$0, 12(%ebp)
	jne	.L3
	.loc 1 133 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC3
	pushl	$1
	pushl	$133
	pushl	$.LC1
	pushl	$__func__.1409
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L3:
	.loc 1 135 0 is_stmt 1
	movl	$0, -12(%ebp)
	.loc 1 136 0
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	movl	%eax, -16(%ebp)
	.loc 1 138 0
	jmp	.L4
.L6:
	.loc 1 139 0
	movl	-16(%ebp), %eax
	movl	%eax, -12(%ebp)
	.loc 1 140 0
	movl	-16(%ebp), %eax
	movl	8(%eax), %eax
	movl	%eax, -16(%ebp)
.L4:
	.loc 1 138 0
	cmpl	$0, -16(%ebp)
	je	.L5
	.loc 1 138 0 is_stmt 0 discriminator 1
	movl	-16(%ebp), %eax
	movl	16(%eax), %edx
	movl	12(%ebp), %eax
	movl	16(%eax), %eax
	cmpl	%eax, %edx
	jbe	.L6
.L5:
	.loc 1 143 0 is_stmt 1
	movl	-12(%ebp), %eax
	.loc 1 144 0
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE34:
	.size	find_prev_wakeup, .-find_prev_wakeup
	.type	find_prev_priority, @function
find_prev_priority:
.LFB35:
	.loc 1 146 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$24, %esp
	.loc 1 149 0
	cmpl	$0, 8(%ebp)
	jne	.L9
	.loc 1 149 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC0
	pushl	$1
	pushl	$149
	pushl	$.LC1
	pushl	$__func__.1419
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L9:
	.loc 1 150 0 is_stmt 1
	cmpl	$0, 12(%ebp)
	jne	.L10
	.loc 1 150 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC3
	pushl	$1
	pushl	$150
	pushl	$.LC1
	pushl	$__func__.1419
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L10:
	.loc 1 152 0 is_stmt 1
	movl	$0, -12(%ebp)
	.loc 1 153 0
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	movl	%eax, -16(%ebp)
	.loc 1 155 0
	jmp	.L11
.L13:
	.loc 1 156 0
	movl	-16(%ebp), %eax
	movl	%eax, -12(%ebp)
	.loc 1 157 0
	movl	-16(%ebp), %eax
	movl	8(%eax), %eax
	movl	%eax, -16(%ebp)
.L11:
	.loc 1 155 0
	cmpl	$0, -16(%ebp)
	je	.L12
	.loc 1 155 0 is_stmt 0 discriminator 1
	movl	-16(%ebp), %eax
	movl	32(%eax), %edx
	movl	12(%ebp), %eax
	movl	32(%eax), %eax
	cmpl	%eax, %edx
	jbe	.L13
.L12:
	.loc 1 160 0 is_stmt 1
	movl	-12(%ebp), %eax
	.loc 1 161 0
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE35:
	.size	find_prev_priority, .-find_prev_priority
	.type	find_prev_pid, @function
find_prev_pid:
.LFB36:
	.loc 1 163 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$24, %esp
	.loc 1 166 0
	cmpl	$0, 8(%ebp)
	jne	.L16
	.loc 1 166 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC0
	pushl	$1
	pushl	$166
	pushl	$.LC1
	pushl	$__func__.1429
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L16:
	.loc 1 167 0 is_stmt 1
	cmpl	$0, 12(%ebp)
	jne	.L17
	.loc 1 167 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC3
	pushl	$1
	pushl	$167
	pushl	$.LC1
	pushl	$__func__.1429
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L17:
	.loc 1 169 0 is_stmt 1
	movl	$0, -12(%ebp)
	.loc 1 170 0
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	movl	%eax, -16(%ebp)
	.loc 1 172 0
	jmp	.L18
.L20:
	.loc 1 173 0
	movl	-16(%ebp), %eax
	movl	%eax, -12(%ebp)
	.loc 1 174 0
	movl	-16(%ebp), %eax
	movl	8(%eax), %eax
	movl	%eax, -16(%ebp)
.L18:
	.loc 1 172 0
	cmpl	$0, -16(%ebp)
	je	.L19
	.loc 1 172 0 is_stmt 0 discriminator 1
	movl	-16(%ebp), %eax
	movl	24(%eax), %edx
	movl	12(%ebp), %eax
	movl	24(%eax), %eax
	cmpl	%eax, %edx
	jbe	.L20
.L19:
	.loc 1 177 0 is_stmt 1
	movl	-12(%ebp), %eax
	.loc 1 178 0
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE36:
	.size	find_prev_pid, .-find_prev_pid
	.section	.rodata
.LC4:
	.string	" Procs"
	.align 4
.LC5:
	.string	"\"pcb_init can't reset \" \"pcb_freelist\""
	.align 4
.LC6:
	.string	"\"pcb_init can't reset \" \"ready\""
	.align 4
.LC7:
	.string	"\"pcb_init can't reset \" \"waiting\""
	.align 4
.LC8:
	.string	"\"pcb_init can't reset \" \"sleeping\""
	.align 4
.LC9:
	.string	"\"pcb_init can't reset \" \"zombie\""
	.align 4
.LC10:
	.string	"\"pcb_init can't reset \" \"sioread\""
	.text
	.globl	pcb_init
	.type	pcb_init, @function
pcb_init:
.LFB37:
	.loc 1 196 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$24, %esp
	.loc 1 199 0
	subl	$12, %esp
	pushl	$.LC4
	call	cio_puts
	addl	$16, %esp
	.loc 1 203 0
	movl	$0, current
	.loc 1 206 0
	movl	$pcb_freelist_queue, pcb_freelist
	movl	pcb_freelist, %eax
	subl	$8, %esp
	pushl	$0
	pushl	%eax
	call	pcb_queue_reset
	addl	$16, %esp
	testl	%eax, %eax
	je	.L23
	.loc 1 206 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC5
	pushl	$0
	pushl	$206
	pushl	$.LC1
	pushl	$__func__.1438
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L23:
	.loc 1 207 0 is_stmt 1
	movl	$ready_queue, ready
	movl	ready, %eax
	subl	$8, %esp
	pushl	$1
	pushl	%eax
	call	pcb_queue_reset
	addl	$16, %esp
	testl	%eax, %eax
	je	.L24
	.loc 1 207 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC6
	pushl	$0
	pushl	$207
	pushl	$.LC1
	pushl	$__func__.1438
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L24:
	.loc 1 208 0 is_stmt 1
	movl	$waiting_queue, waiting
	movl	waiting, %eax
	subl	$8, %esp
	pushl	$2
	pushl	%eax
	call	pcb_queue_reset
	addl	$16, %esp
	testl	%eax, %eax
	je	.L25
	.loc 1 208 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC7
	pushl	$0
	pushl	$208
	pushl	$.LC1
	pushl	$__func__.1438
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L25:
	.loc 1 209 0 is_stmt 1
	movl	$sleeping_queue, sleeping
	movl	sleeping, %eax
	subl	$8, %esp
	pushl	$3
	pushl	%eax
	call	pcb_queue_reset
	addl	$16, %esp
	testl	%eax, %eax
	je	.L26
	.loc 1 209 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC8
	pushl	$0
	pushl	$209
	pushl	$.LC1
	pushl	$__func__.1438
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L26:
	.loc 1 210 0 is_stmt 1
	movl	$zombie_queue, zombie
	movl	zombie, %eax
	subl	$8, %esp
	pushl	$2
	pushl	%eax
	call	pcb_queue_reset
	addl	$16, %esp
	testl	%eax, %eax
	je	.L27
	.loc 1 210 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC9
	pushl	$0
	pushl	$210
	pushl	$.LC1
	pushl	$__func__.1438
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L27:
	.loc 1 211 0 is_stmt 1
	movl	$sioread_queue, sioread
	movl	sioread, %eax
	subl	$8, %esp
	pushl	$0
	pushl	%eax
	call	pcb_queue_reset
	addl	$16, %esp
	testl	%eax, %eax
	je	.L28
	.loc 1 211 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC10
	pushl	$0
	pushl	$211
	pushl	$.LC1
	pushl	$__func__.1438
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L28:
	.loc 1 221 0 is_stmt 1
	movl	$ptable, -12(%ebp)
.LBB2:
	.loc 1 222 0
	movl	$0, -16(%ebp)
	jmp	.L29
.L30:
	.loc 1 223 0 discriminator 3
	subl	$12, %esp
	pushl	-12(%ebp)
	call	pcb_free
	addl	$16, %esp
	.loc 1 224 0 discriminator 3
	addl	$48, -12(%ebp)
	.loc 1 222 0 discriminator 3
	addl	$1, -16(%ebp)
.L29:
	.loc 1 222 0 is_stmt 0 discriminator 1
	cmpl	$24, -16(%ebp)
	jle	.L30
.LBE2:
	.loc 1 226 0 is_stmt 1
	nop
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE37:
	.size	pcb_init, .-pcb_init
	.globl	pcb_alloc
	.type	pcb_alloc, @function
pcb_alloc:
.LFB38:
	.loc 1 237 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$24, %esp
	.loc 1 240 0
	cmpl	$0, 8(%ebp)
	jne	.L32
	.loc 1 240 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC3
	pushl	$1
	pushl	$240
	pushl	$.LC1
	pushl	$__func__.1447
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L32:
	.loc 1 244 0 is_stmt 1
	movl	pcb_freelist, %eax
	subl	$8, %esp
	leal	-12(%ebp), %edx
	pushl	%edx
	pushl	%eax
	call	pcb_queue_remove
	addl	$16, %esp
	testl	%eax, %eax
	je	.L33
	.loc 1 245 0
	movl	$-101, %eax
	jmp	.L35
.L33:
	.loc 1 248 0
	movl	-12(%ebp), %edx
	movl	8(%ebp), %eax
	movl	%edx, (%eax)
	.loc 1 249 0
	movl	$0, %eax
.L35:
	.loc 1 250 0 discriminator 1
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE38:
	.size	pcb_alloc, .-pcb_alloc
	.section	.rodata
.LC11:
	.string	"pcb_free(0x%08x) status %d"
.LC12:
	.string	"b256"
	.text
	.globl	pcb_free
	.type	pcb_free, @function
pcb_free:
.LFB39:
	.loc 1 259 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$24, %esp
	.loc 1 261 0
	cmpl	$0, 8(%ebp)
	je	.L38
.LBB3:
	.loc 1 263 0
	movl	8(%ebp), %eax
	movl	$0, 28(%eax)
	.loc 1 266 0
	movl	pcb_freelist, %eax
	subl	$8, %esp
	pushl	8(%ebp)
	pushl	%eax
	call	pcb_queue_insert
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	.loc 1 269 0
	cmpl	$0, -12(%ebp)
	je	.L38
	.loc 1 270 0
	movl	8(%ebp), %eax
	pushl	-12(%ebp)
	pushl	%eax
	pushl	$.LC11
	pushl	$b256
	call	sprint
	addl	$16, %esp
	.loc 1 272 0
	subl	$4, %esp
	pushl	$.LC12
	pushl	$0
	pushl	$272
	pushl	$.LC1
	pushl	$__func__.1453
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L38:
.LBE3:
	.loc 1 275 0
	nop
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE39:
	.size	pcb_free, .-pcb_free
	.globl	pcb_stack_alloc
	.type	pcb_stack_alloc, @function
pcb_stack_alloc:
.LFB40:
	.loc 1 286 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$24, %esp
	.loc 1 292 0
	cmpl	$0, 8(%ebp)
	jne	.L40
	.loc 1 294 0
	movl	$2, 8(%ebp)
.L40:
	.loc 1 297 0
	subl	$12, %esp
	pushl	8(%ebp)
	call	km_page_alloc
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	.loc 1 301 0
	cmpl	$0, -12(%ebp)
	je	.L41
	.loc 1 303 0
	movl	8(%ebp), %eax
	sall	$12, %eax
	subl	$8, %esp
	pushl	%eax
	pushl	-12(%ebp)
	call	memclr
	addl	$16, %esp
.L41:
	.loc 1 306 0
	movl	-12(%ebp), %eax
	.loc 1 307 0
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE40:
	.size	pcb_stack_alloc, .-pcb_stack_alloc
	.section	.rodata
.LC13:
	.string	"stk != 0"
	.text
	.globl	pcb_stack_free
	.type	pcb_stack_free, @function
pcb_stack_free:
.LFB41:
	.loc 1 317 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$8, %esp
	.loc 1 323 0
	cmpl	$0, 8(%ebp)
	jne	.L44
	.loc 1 323 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC13
	pushl	$0
	pushl	$323
	pushl	$.LC1
	pushl	$__func__.1462
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L44:
	.loc 1 326 0 is_stmt 1
	cmpl	$0, 12(%ebp)
	jne	.L45
	.loc 1 328 0
	movl	$2, 12(%ebp)
.L45:
	.loc 1 332 0
	subl	$8, %esp
	pushl	12(%ebp)
	pushl	8(%ebp)
	call	km_page_free_multi
	addl	$16, %esp
	.loc 1 333 0
	nop
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE41:
	.size	pcb_stack_free, .-pcb_stack_free
	.section	.rodata
.LC14:
	.string	"victim->parent != 0"
	.align 4
.LC15:
	.string	"pcb_queue_remove_this(zombie,zchild) == (0)"
	.align 4
.LC16:
	.string	"pcb_queue_remove_this(waiting,init_pcb) == (0)"
	.align 4
.LC17:
	.string	"pcb_queue_insert(zombie,victim) == (0)"
	.text
	.globl	pcb_zombify
	.type	pcb_zombify, @function
pcb_zombify:
.LFB42:
	.loc 1 344 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%esi
	pushl	%ebx
	subl	$32, %esp
	.cfi_offset 6, -12
	.cfi_offset 3, -16
	movl	8(%ebp), %ebx
	.loc 1 347 0
	testl	%ebx, %ebx
	je	.L62
	.loc 1 352 0
	movl	12(%ebx), %eax
	testl	%eax, %eax
	jne	.L49
	.loc 1 352 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC14
	pushl	$0
	pushl	$352
	pushl	$.LC1
	pushl	$__func__.1466
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L49:
	.loc 1 359 0 is_stmt 1
	movl	12(%ebx), %eax
	movl	%eax, -20(%ebp)
	.loc 1 360 0
	movl	$0, -12(%ebp)
	.loc 1 363 0
	movl	24(%ebx), %eax
	movl	%eax, -24(%ebp)
	.loc 1 366 0
	movl	$ptable, %esi
.LBB4:
	.loc 1 368 0
	movl	$0, -16(%ebp)
	jmp	.L50
.L54:
	.loc 1 371 0
	movl	28(%esi), %eax
	testl	%eax, %eax
	je	.L63
	.loc 1 377 0
	cmpl	-20(%ebp), %esi
	je	.L64
	.loc 1 381 0
	movl	12(%esi), %eax
	cmpl	%eax, %ebx
	jne	.L52
	.loc 1 384 0
	movl	init_pcb, %eax
	movl	%eax, 12(%esi)
	.loc 1 387 0
	movl	28(%esi), %eax
	cmpl	$8, %eax
	jne	.L52
	.loc 1 393 0
	movl	%esi, -12(%ebp)
	jmp	.L52
.L63:
	.loc 1 372 0
	nop
	jmp	.L52
.L64:
	.loc 1 378 0
	nop
.L52:
	.loc 1 368 0 discriminator 2
	addl	$1, -16(%ebp)
	addl	$48, %esi
.L50:
	.loc 1 368 0 is_stmt 0 discriminator 1
	cmpl	$24, -16(%ebp)
	jle	.L54
.LBE4:
	.loc 1 415 0 is_stmt 1
	cmpl	$0, -12(%ebp)
	je	.L55
	.loc 1 415 0 is_stmt 0 discriminator 1
	movl	init_pcb, %eax
	movl	28(%eax), %eax
	cmpl	$6, %eax
	jne	.L55
.LBB5:
	.loc 1 418 0 is_stmt 1
	movl	zombie, %eax
	subl	$8, %esp
	pushl	-12(%ebp)
	pushl	%eax
	call	pcb_queue_remove_this
	addl	$16, %esp
	testl	%eax, %eax
	je	.L56
	.loc 1 418 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC15
	pushl	$0
	pushl	$418
	pushl	$.LC1
	pushl	$__func__.1466
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L56:
	.loc 1 420 0 is_stmt 1
	movl	init_pcb, %edx
	movl	waiting, %eax
	subl	$8, %esp
	pushl	%edx
	pushl	%eax
	call	pcb_queue_remove_this
	addl	$16, %esp
	testl	%eax, %eax
	je	.L57
	.loc 1 420 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC16
	pushl	$0
	pushl	$420
	pushl	$.LC1
	pushl	$__func__.1466
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L57:
	.loc 1 423 0 is_stmt 1
	movl	init_pcb, %eax
	movl	(%eax), %eax
	movl	-12(%ebp), %edx
	movl	24(%edx), %edx
	movl	%edx, 48(%eax)
	.loc 1 426 0
	movl	init_pcb, %eax
	movl	(%eax), %eax
	addl	$72, %eax
	addl	$8, %eax
	movl	(%eax), %eax
	movl	%eax, -28(%ebp)
	.loc 1 428 0
	cmpl	$0, -28(%ebp)
	je	.L58
	.loc 1 437 0
	movl	-12(%ebp), %eax
	movl	20(%eax), %edx
	movl	-28(%ebp), %eax
	movl	%edx, (%eax)
.L58:
	.loc 1 441 0
	movl	init_pcb, %eax
	subl	$12, %esp
	pushl	%eax
	call	schedule
	addl	$16, %esp
	.loc 1 442 0
	subl	$12, %esp
	pushl	-12(%ebp)
	call	pcb_cleanup
	addl	$16, %esp
.L55:
.LBE5:
	.loc 1 456 0
	movl	-20(%ebp), %eax
	movl	28(%eax), %eax
	cmpl	$6, %eax
	jne	.L59
.LBB6:
	.loc 1 460 0
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	addl	$72, %eax
	movl	4(%eax), %eax
	movl	%eax, -32(%ebp)
	.loc 1 462 0
	cmpl	$0, -32(%ebp)
	je	.L60
	.loc 1 462 0 is_stmt 0 discriminator 1
	movl	-32(%ebp), %eax
	cmpl	-24(%ebp), %eax
	jne	.L59
.L60:
.LBB7:
	.loc 1 468 0 is_stmt 1
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	movl	-24(%ebp), %edx
	movl	%edx, 48(%eax)
	.loc 1 471 0
	movl	-20(%ebp), %eax
	movl	(%eax), %eax
	addl	$72, %eax
	addl	$8, %eax
	movl	(%eax), %eax
	movl	%eax, -36(%ebp)
	.loc 1 473 0
	cmpl	$0, -36(%ebp)
	je	.L61
	.loc 1 482 0
	movl	20(%ebx), %edx
	movl	-36(%ebp), %eax
	movl	%edx, (%eax)
.L61:
	.loc 1 486 0
	subl	$12, %esp
	pushl	-20(%ebp)
	call	schedule
	addl	$16, %esp
	.loc 1 487 0
	subl	$12, %esp
	pushl	%ebx
	call	pcb_cleanup
	addl	$16, %esp
	.loc 1 489 0
	jmp	.L46
.L59:
.LBE7:
.LBE6:
	.loc 1 504 0
	movl	$8, 28(%ebx)
	.loc 1 505 0
	movl	zombie, %eax
	subl	$8, %esp
	pushl	%ebx
	pushl	%eax
	call	pcb_queue_insert
	addl	$16, %esp
	testl	%eax, %eax
	je	.L46
	.loc 1 505 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC17
	pushl	$0
	pushl	$505
	pushl	$.LC1
	pushl	$__func__.1466
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
	jmp	.L46
.L62:
	.loc 1 348 0 is_stmt 1
	nop
.L46:
	.loc 1 512 0
	leal	-8(%ebp), %esp
	popl	%ebx
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE42:
	.size	pcb_zombify, .-pcb_zombify
	.globl	pcb_cleanup
	.type	pcb_cleanup, @function
pcb_cleanup:
.LFB43:
	.loc 1 521 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$8, %esp
	.loc 1 528 0
	cmpl	$0, 8(%ebp)
	je	.L68
	.loc 1 534 0
	subl	$12, %esp
	pushl	8(%ebp)
	call	user_cleanup
	addl	$16, %esp
	.loc 1 537 0
	subl	$12, %esp
	pushl	8(%ebp)
	call	pcb_free
	addl	$16, %esp
	jmp	.L65
.L68:
	.loc 1 530 0
	nop
.L65:
	.loc 1 538 0
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE43:
	.size	pcb_cleanup, .-pcb_cleanup
	.globl	pcb_find_pid
	.type	pcb_find_pid, @function
pcb_find_pid:
.LFB44:
	.loc 1 549 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$16, %esp
	.loc 1 552 0
	cmpl	$0, 8(%ebp)
	jne	.L70
	.loc 1 553 0
	movl	$0, %eax
	jmp	.L71
.L70:
	.loc 1 557 0
	movl	$ptable, -4(%ebp)
.LBB8:
	.loc 1 559 0
	movl	$0, -8(%ebp)
	jmp	.L72
.L74:
	.loc 1 560 0
	movl	-4(%ebp), %eax
	movl	24(%eax), %eax
	cmpl	%eax, 8(%ebp)
	jne	.L73
	.loc 1 560 0 is_stmt 0 discriminator 1
	movl	-4(%ebp), %eax
	movl	28(%eax), %eax
	testl	%eax, %eax
	je	.L73
	.loc 1 561 0 is_stmt 1
	movl	-4(%ebp), %eax
	jmp	.L71
.L73:
	.loc 1 559 0 discriminator 2
	addl	$1, -8(%ebp)
	addl	$48, -4(%ebp)
.L72:
	.loc 1 559 0 is_stmt 0 discriminator 1
	cmpl	$24, -8(%ebp)
	jle	.L74
.LBE8:
	.loc 1 566 0 is_stmt 1
	movl	$0, %eax
.L71:
	.loc 1 567 0
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE44:
	.size	pcb_find_pid, .-pcb_find_pid
	.section	.rodata
.LC18:
	.string	"p->parent != 0"
	.text
	.globl	pcb_find_ppid
	.type	pcb_find_ppid, @function
pcb_find_ppid:
.LFB45:
	.loc 1 578 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$24, %esp
	.loc 1 581 0
	cmpl	$0, 8(%ebp)
	jne	.L76
	.loc 1 582 0
	movl	$0, %eax
	jmp	.L77
.L76:
	.loc 1 586 0
	movl	$ptable, -12(%ebp)
.LBB9:
	.loc 1 588 0
	movl	$0, -16(%ebp)
	jmp	.L78
.L81:
	.loc 1 589 0
	movl	-12(%ebp), %eax
	movl	12(%eax), %eax
	testl	%eax, %eax
	jne	.L79
	.loc 1 589 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC18
	pushl	$1
	pushl	$589
	pushl	$.LC1
	pushl	$__func__.1495
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L79:
	.loc 1 590 0 is_stmt 1
	movl	-12(%ebp), %eax
	movl	12(%eax), %eax
	movl	24(%eax), %eax
	cmpl	%eax, 8(%ebp)
	jne	.L80
	.loc 1 590 0 is_stmt 0 discriminator 1
	movl	-12(%ebp), %eax
	movl	12(%eax), %eax
	movl	28(%eax), %eax
	testl	%eax, %eax
	je	.L80
	.loc 1 591 0 is_stmt 1
	movl	-12(%ebp), %eax
	jmp	.L77
.L80:
	.loc 1 588 0 discriminator 2
	addl	$1, -16(%ebp)
	addl	$48, -12(%ebp)
.L78:
	.loc 1 588 0 is_stmt 0 discriminator 1
	cmpl	$24, -16(%ebp)
	jle	.L81
.LBE9:
	.loc 1 596 0 is_stmt 1
	movl	$0, %eax
.L77:
	.loc 1 597 0
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE45:
	.size	pcb_find_ppid, .-pcb_find_ppid
	.globl	pcb_queue_reset
	.type	pcb_queue_reset, @function
pcb_queue_reset:
.LFB46:
	.loc 1 610 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$8, %esp
	.loc 1 613 0
	cmpl	$0, 8(%ebp)
	jne	.L83
	.loc 1 613 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC0
	pushl	$1
	pushl	$613
	pushl	$.LC1
	pushl	$__func__.1503
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L83:
	.loc 1 616 0 is_stmt 1
	cmpl	$3, 12(%ebp)
	jbe	.L84
	.loc 1 617 0
	movl	$-2, %eax
	jmp	.L85
.L84:
	.loc 1 621 0
	movl	8(%ebp), %eax
	movl	$0, 4(%eax)
	movl	8(%ebp), %eax
	movl	4(%eax), %edx
	movl	8(%ebp), %eax
	movl	%edx, (%eax)
	.loc 1 622 0
	movl	8(%ebp), %eax
	movl	12(%ebp), %edx
	movl	%edx, 8(%eax)
	.loc 1 624 0
	movl	$0, %eax
.L85:
	.loc 1 625 0
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE46:
	.size	pcb_queue_reset, .-pcb_queue_reset
	.globl	pcb_queue_empty
	.type	pcb_queue_empty, @function
pcb_queue_empty:
.LFB47:
	.loc 1 637 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$8, %esp
	.loc 1 640 0
	cmpl	$0, 8(%ebp)
	jne	.L87
	.loc 1 640 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC0
	pushl	$1
	pushl	$640
	pushl	$.LC1
	pushl	$__func__.1507
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L87:
	.loc 1 642 0 is_stmt 1
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	testl	%eax, %eax
	sete	%al
	.loc 1 643 0
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE47:
	.size	pcb_queue_empty, .-pcb_queue_empty
	.globl	pcb_queue_length
	.type	pcb_queue_length, @function
pcb_queue_length:
.LFB48:
	.loc 1 654 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%esi
	pushl	%ebx
	.cfi_offset 6, -12
	.cfi_offset 3, -16
	.loc 1 657 0
	cmpl	$0, 8(%ebp)
	jne	.L90
	.loc 1 657 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC0
	pushl	$1
	pushl	$657
	pushl	$.LC1
	pushl	$__func__.1511
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L90:
	.loc 1 660 0 is_stmt 1
	movl	8(%ebp), %eax
	movl	(%eax), %ebx
	.loc 1 661 0
	movl	$0, %esi
	.loc 1 663 0
	jmp	.L91
.L92:
	.loc 1 664 0
	addl	$1, %esi
	.loc 1 665 0
	movl	8(%ebx), %ebx
.L91:
	.loc 1 663 0
	testl	%ebx, %ebx
	jne	.L92
	.loc 1 668 0
	movl	%esi, %eax
	.loc 1 669 0
	leal	-8(%ebp), %esp
	popl	%ebx
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE48:
	.size	pcb_queue_length, .-pcb_queue_length
	.section	.rodata
.LC19:
	.string	"queue->tail != 0"
	.text
	.globl	pcb_queue_insert
	.type	pcb_queue_insert, @function
pcb_queue_insert:
.LFB49:
	.loc 1 681 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$24, %esp
	.loc 1 684 0
	cmpl	$0, 8(%ebp)
	jne	.L95
	.loc 1 684 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC0
	pushl	$1
	pushl	$684
	pushl	$.LC1
	pushl	$__func__.1521
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L95:
	.loc 1 685 0 is_stmt 1
	cmpl	$0, 12(%ebp)
	jne	.L96
	.loc 1 685 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC3
	pushl	$1
	pushl	$685
	pushl	$.LC1
	pushl	$__func__.1521
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L96:
	.loc 1 688 0 is_stmt 1
	movl	12(%ebp), %eax
	movl	8(%eax), %eax
	testl	%eax, %eax
	je	.L97
	.loc 1 690 0
	movl	$-2, %eax
	jmp	.L98
.L97:
	.loc 1 694 0
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	testl	%eax, %eax
	jne	.L99
	.loc 1 695 0
	movl	8(%ebp), %eax
	movl	12(%ebp), %edx
	movl	%edx, 4(%eax)
	movl	8(%ebp), %eax
	movl	4(%eax), %edx
	movl	8(%ebp), %eax
	movl	%edx, (%eax)
	.loc 1 696 0
	movl	$0, %eax
	jmp	.L98
.L99:
	.loc 1 698 0
	movl	8(%ebp), %eax
	movl	4(%eax), %eax
	testl	%eax, %eax
	jne	.L100
	.loc 1 698 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC19
	pushl	$1
	pushl	$698
	pushl	$.LC1
	pushl	$__func__.1521
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L100:
	.loc 1 701 0 is_stmt 1
	movl	$0, -12(%ebp)
	.loc 1 704 0
	movl	8(%ebp), %eax
	movl	8(%eax), %eax
	cmpl	$1, %eax
	je	.L102
	cmpl	$1, %eax
	jb	.L103
	cmpl	$2, %eax
	je	.L104
	cmpl	$3, %eax
	je	.L105
	jmp	.L111
.L103:
	.loc 1 706 0
	movl	8(%ebp), %eax
	movl	4(%eax), %eax
	movl	%eax, -12(%ebp)
	.loc 1 707 0
	jmp	.L106
.L102:
	.loc 1 709 0
	subl	$8, %esp
	pushl	12(%ebp)
	pushl	8(%ebp)
	call	find_prev_priority
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	.loc 1 710 0
	jmp	.L106
.L104:
	.loc 1 712 0
	subl	$8, %esp
	pushl	12(%ebp)
	pushl	8(%ebp)
	call	find_prev_pid
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	.loc 1 713 0
	jmp	.L106
.L105:
	.loc 1 715 0
	subl	$8, %esp
	pushl	12(%ebp)
	pushl	8(%ebp)
	call	find_prev_wakeup
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	.loc 1 716 0
	jmp	.L106
.L111:
	.loc 1 719 0
	movl	$-2, %eax
	jmp	.L98
.L106:
	.loc 1 724 0
	cmpl	$0, -12(%ebp)
	jne	.L107
	.loc 1 728 0
	movl	8(%ebp), %eax
	movl	(%eax), %edx
	movl	12(%ebp), %eax
	movl	%edx, 8(%eax)
	.loc 1 729 0
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	testl	%eax, %eax
	jne	.L108
	.loc 1 731 0
	movl	8(%ebp), %eax
	movl	12(%ebp), %edx
	movl	%edx, 4(%eax)
.L108:
	.loc 1 733 0
	movl	8(%ebp), %eax
	movl	12(%ebp), %edx
	movl	%edx, (%eax)
	jmp	.L109
.L107:
	.loc 1 735 0
	movl	-12(%ebp), %eax
	movl	8(%eax), %eax
	testl	%eax, %eax
	jne	.L110
	.loc 1 738 0
	movl	-12(%ebp), %eax
	movl	12(%ebp), %edx
	movl	%edx, 8(%eax)
	.loc 1 739 0
	movl	8(%ebp), %eax
	movl	12(%ebp), %edx
	movl	%edx, 4(%eax)
	jmp	.L109
.L110:
	.loc 1 744 0
	movl	-12(%ebp), %eax
	movl	8(%eax), %edx
	movl	12(%ebp), %eax
	movl	%edx, 8(%eax)
	.loc 1 745 0
	movl	-12(%ebp), %eax
	movl	12(%ebp), %edx
	movl	%edx, 8(%eax)
.L109:
	.loc 1 749 0
	movl	$0, %eax
.L98:
	.loc 1 750 0
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE49:
	.size	pcb_queue_insert, .-pcb_queue_insert
	.globl	pcb_queue_remove
	.type	pcb_queue_remove, @function
pcb_queue_remove:
.LFB50:
	.loc 1 762 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$24, %esp
	.loc 1 765 0
	cmpl	$0, 8(%ebp)
	jne	.L113
	.loc 1 765 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC0
	pushl	$1
	pushl	$765
	pushl	$.LC1
	pushl	$__func__.1533
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L113:
	.loc 1 766 0 is_stmt 1
	cmpl	$0, 12(%ebp)
	jne	.L114
	.loc 1 766 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC3
	pushl	$1
	pushl	$766
	pushl	$.LC1
	pushl	$__func__.1533
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L114:
	.loc 1 769 0 is_stmt 1
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	testl	%eax, %eax
	jne	.L115
	.loc 1 770 0
	movl	$-100, %eax
	jmp	.L116
.L115:
	.loc 1 774 0
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	movl	%eax, -12(%ebp)
	.loc 1 775 0
	movl	-12(%ebp), %eax
	movl	8(%eax), %edx
	movl	8(%ebp), %eax
	movl	%edx, (%eax)
	.loc 1 778 0
	movl	-12(%ebp), %eax
	movl	$0, 8(%eax)
	.loc 1 781 0
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	testl	%eax, %eax
	jne	.L117
	.loc 1 783 0
	movl	8(%ebp), %eax
	movl	$0, 4(%eax)
.L117:
	.loc 1 787 0
	movl	12(%ebp), %eax
	movl	-12(%ebp), %edx
	movl	%edx, (%eax)
	.loc 1 789 0
	movl	$0, %eax
.L116:
	.loc 1 790 0
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE50:
	.size	pcb_queue_remove, .-pcb_queue_remove
	.section	.rodata
.LC20:
	.string	"prev != 0"
	.align 4
.LC21:
	.string	"(queue->head == 0 && queue->tail == 0) || (queue->head != 0 && queue->tail != 0)"
	.text
	.globl	pcb_queue_remove_this
	.type	pcb_queue_remove_this, @function
pcb_queue_remove_this:
.LFB51:
	.loc 1 806 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$24, %esp
	.loc 1 809 0
	cmpl	$0, 8(%ebp)
	jne	.L119
	.loc 1 809 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC0
	pushl	$1
	pushl	$809
	pushl	$.LC1
	pushl	$__func__.1539
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L119:
	.loc 1 810 0 is_stmt 1
	cmpl	$0, 12(%ebp)
	jne	.L120
	.loc 1 810 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC3
	pushl	$1
	pushl	$810
	pushl	$.LC1
	pushl	$__func__.1539
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L120:
	.loc 1 813 0 is_stmt 1
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	testl	%eax, %eax
	jne	.L121
	.loc 1 814 0
	movl	$-100, %eax
	jmp	.L122
.L121:
	.loc 1 818 0
	movl	$0, -12(%ebp)
	.loc 1 819 0
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	movl	%eax, -16(%ebp)
	.loc 1 821 0
	jmp	.L123
.L125:
	.loc 1 822 0
	movl	-16(%ebp), %eax
	movl	%eax, -12(%ebp)
	.loc 1 823 0
	movl	-16(%ebp), %eax
	movl	8(%eax), %eax
	movl	%eax, -16(%ebp)
.L123:
	.loc 1 821 0
	cmpl	$0, -16(%ebp)
	je	.L124
	.loc 1 821 0 is_stmt 0 discriminator 1
	movl	-16(%ebp), %eax
	cmpl	12(%ebp), %eax
	jne	.L125
.L124:
	.loc 1 835 0 is_stmt 1
	cmpl	$0, -16(%ebp)
	jne	.L126
	.loc 1 837 0
	cmpl	$0, -12(%ebp)
	jne	.L127
	.loc 1 837 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC20
	pushl	$0
	pushl	$837
	pushl	$.LC1
	pushl	$__func__.1539
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L127:
	.loc 1 839 0 is_stmt 1
	movl	$-6, %eax
	jmp	.L122
.L126:
	.loc 1 843 0
	cmpl	$0, -12(%ebp)
	je	.L128
	.loc 1 846 0
	movl	-16(%ebp), %eax
	movl	8(%eax), %edx
	movl	-12(%ebp), %eax
	movl	%edx, 8(%eax)
	jmp	.L129
.L128:
	.loc 1 850 0
	movl	-16(%ebp), %eax
	movl	8(%eax), %edx
	movl	8(%ebp), %eax
	movl	%edx, (%eax)
.L129:
	.loc 1 855 0
	movl	-16(%ebp), %eax
	movl	8(%eax), %eax
	testl	%eax, %eax
	jne	.L130
	.loc 1 858 0
	movl	8(%ebp), %eax
	movl	-12(%ebp), %edx
	movl	%edx, 4(%eax)
.L130:
	.loc 1 862 0
	movl	-16(%ebp), %eax
	movl	$0, 8(%eax)
	.loc 1 868 0
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	testl	%eax, %eax
	jne	.L131
	.loc 1 868 0 is_stmt 0 discriminator 2
	movl	8(%ebp), %eax
	movl	4(%eax), %eax
	testl	%eax, %eax
	je	.L132
.L131:
	.loc 1 868 0 discriminator 3
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	testl	%eax, %eax
	je	.L133
	.loc 1 868 0 discriminator 5
	movl	8(%ebp), %eax
	movl	4(%eax), %eax
	testl	%eax, %eax
	jne	.L132
.L133:
	.loc 1 868 0 discriminator 6
	subl	$4, %esp
	pushl	$.LC21
	pushl	$1
	pushl	$871
	pushl	$.LC1
	pushl	$__func__.1539
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L132:
	.loc 1 873 0 is_stmt 1
	movl	$0, %eax
.L122:
	.loc 1 874 0
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE51:
	.size	pcb_queue_remove_this, .-pcb_queue_remove_this
	.globl	pcb_queue_peek
	.type	pcb_queue_peek, @function
pcb_queue_peek:
.LFB52:
	.loc 1 886 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$8, %esp
	.loc 1 889 0
	cmpl	$0, 8(%ebp)
	jne	.L135
	.loc 1 889 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC0
	pushl	$1
	pushl	$889
	pushl	$.LC1
	pushl	$__func__.1548
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L135:
	.loc 1 892 0 is_stmt 1
	movl	8(%ebp), %eax
	movl	(%eax), %eax
	testl	%eax, %eax
	jne	.L136
	.loc 1 893 0
	movl	$0, %eax
	jmp	.L137
.L136:
	.loc 1 897 0
	movl	8(%ebp), %eax
	movl	(%eax), %eax
.L137:
	.loc 1 898 0
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE52:
	.size	pcb_queue_peek, .-pcb_queue_peek
	.section	.rodata
.LC22:
	.string	"\"schedule insert fail\""
	.text
	.globl	schedule
	.type	schedule, @function
schedule:
.LFB53:
	.loc 1 911 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$8, %esp
	.loc 1 914 0
	cmpl	$0, 8(%ebp)
	jne	.L139
	.loc 1 914 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC3
	pushl	$1
	pushl	$914
	pushl	$.LC1
	pushl	$__func__.1552
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L139:
	.loc 1 917 0 is_stmt 1
	movl	8(%ebp), %eax
	movl	28(%eax), %eax
	cmpl	$7, %eax
	jne	.L140
	.loc 1 918 0
	subl	$12, %esp
	pushl	8(%ebp)
	call	pcb_zombify
	addl	$16, %esp
	.loc 1 919 0
	jmp	.L138
.L140:
	.loc 1 923 0
	movl	8(%ebp), %eax
	movl	$2, 28(%eax)
	.loc 1 926 0
	movl	ready, %eax
	subl	$8, %esp
	pushl	8(%ebp)
	pushl	%eax
	call	pcb_queue_insert
	addl	$16, %esp
	testl	%eax, %eax
	je	.L138
	.loc 1 927 0
	subl	$4, %esp
	pushl	$.LC22
	pushl	$0
	pushl	$927
	pushl	$.LC1
	pushl	$__func__.1552
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L138:
	.loc 1 929 0
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE53:
	.size	schedule, .-schedule
	.section	.rodata
.LC23:
	.string	"current == 0"
	.align 4
.LC24:
	.string	"dispatch queue remove failed, code %d"
	.text
	.globl	dispatch
	.type	dispatch, @function
dispatch:
.LFB54:
	.loc 1 936 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$24, %esp
	.loc 1 939 0
	movl	current, %eax
	testl	%eax, %eax
	je	.L143
	.loc 1 939 0 is_stmt 0 discriminator 1
	subl	$4, %esp
	pushl	$.LC23
	pushl	$0
	pushl	$939
	pushl	$.LC1
	pushl	$__func__.1556
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L143:
	.loc 1 942 0 is_stmt 1
	movl	ready, %eax
	subl	$8, %esp
	pushl	$current
	pushl	%eax
	call	pcb_queue_remove
	addl	$16, %esp
	movl	%eax, -12(%ebp)
	.loc 1 943 0
	cmpl	$0, -12(%ebp)
	je	.L144
	.loc 1 944 0
	subl	$4, %esp
	pushl	-12(%ebp)
	pushl	$.LC24
	pushl	$b256
	call	sprint
	addl	$16, %esp
	.loc 1 945 0
	subl	$4, %esp
	pushl	$.LC12
	pushl	$0
	pushl	$945
	pushl	$.LC1
	pushl	$__func__.1556
	pushl	$.LC2
	pushl	$b512
	call	sprint
	addl	$32, %esp
	subl	$12, %esp
	pushl	$b512
	call	kpanic
	addl	$16, %esp
.L144:
	.loc 1 949 0
	movl	current, %eax
	movl	$3, 28(%eax)
	.loc 1 950 0
	movl	current, %eax
	movl	$3, 36(%eax)
	.loc 1 951 0
	nop
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE54:
	.size	dispatch, .-dispatch
	.section	.rodata
.LC25:
	.string	" @ %08x:\n"
.LC26:
	.string	" NULL???\n"
	.align 4
.LC27:
	.string	"ss %04x gs %04x fs %04x es %04x ds %04x cs %04x\n"
	.align 4
.LC28:
	.string	"  edi %08x esi %08x ebp %08x esp %08x\n"
	.align 4
.LC29:
	.string	"  ebx %08x edx %08x ecx %08x eax %08x\n"
	.align 4
.LC30:
	.string	"  vec %08x cod %08x eip %08x efl %08x\n"
	.text
	.globl	ctx_dump
	.type	ctx_dump, @function
ctx_dump:
.LFB55:
	.loc 1 966 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$28, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	movl	12(%ebp), %ebx
	.loc 1 969 0
	cmpl	$0, 8(%ebp)
	je	.L146
	.loc 1 970 0
	subl	$12, %esp
	pushl	8(%ebp)
	call	cio_puts
	addl	$16, %esp
.L146:
	.loc 1 974 0
	movl	%ebx, %eax
	subl	$8, %esp
	pushl	%eax
	pushl	$.LC25
	call	cio_printf
	addl	$16, %esp
	.loc 1 977 0
	testl	%ebx, %ebx
	jne	.L147
	.loc 1 978 0
	subl	$12, %esp
	pushl	$.LC26
	call	cio_puts
	addl	$16, %esp
	.loc 1 979 0
	jmp	.L145
.L147:
	.loc 1 985 0
	movl	64(%ebx), %eax
	.loc 1 983 0
	movzbl	%al, %eax
	movl	%eax, -28(%ebp)
	.loc 1 985 0
	movl	16(%ebx), %eax
	.loc 1 983 0
	movzbl	%al, %edi
	.loc 1 985 0
	movl	12(%ebx), %eax
	.loc 1 983 0
	movzbl	%al, %esi
	.loc 1 984 0
	movl	8(%ebx), %eax
	.loc 1 983 0
	movzbl	%al, %ecx
	.loc 1 984 0
	movl	4(%ebx), %eax
	.loc 1 983 0
	movzbl	%al, %edx
	.loc 1 984 0
	movl	(%ebx), %eax
	.loc 1 983 0
	movzbl	%al, %eax
	subl	$4, %esp
	pushl	-28(%ebp)
	pushl	%edi
	pushl	%esi
	pushl	%ecx
	pushl	%edx
	pushl	%eax
	pushl	$.LC27
	call	cio_printf
	addl	$32, %esp
	.loc 1 986 0
	movl	32(%ebx), %esi
	movl	28(%ebx), %ecx
	movl	24(%ebx), %edx
	movl	20(%ebx), %eax
	subl	$12, %esp
	pushl	%esi
	pushl	%ecx
	pushl	%edx
	pushl	%eax
	pushl	$.LC28
	call	cio_printf
	addl	$32, %esp
	.loc 1 988 0
	movl	48(%ebx), %esi
	movl	44(%ebx), %ecx
	movl	40(%ebx), %edx
	movl	36(%ebx), %eax
	subl	$12, %esp
	pushl	%esi
	pushl	%ecx
	pushl	%edx
	pushl	%eax
	pushl	$.LC29
	call	cio_printf
	addl	$32, %esp
	.loc 1 990 0
	movl	68(%ebx), %esi
	movl	60(%ebx), %ecx
	movl	56(%ebx), %edx
	movl	52(%ebx), %eax
	subl	$12, %esp
	pushl	%esi
	pushl	%ecx
	pushl	%edx
	pushl	%eax
	pushl	$.LC30
	call	cio_printf
	addl	$32, %esp
.L145:
	.loc 1 992 0
	leal	-12(%ebp), %esp
	popl	%ebx
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%edi
	.cfi_restore 7
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE55:
	.size	ctx_dump, .-ctx_dump
	.section	.rodata
.LC31:
	.string	"%2d(%d): "
	.text
	.globl	ctx_dump_all
	.type	ctx_dump_all, @function
ctx_dump_all:
.LFB56:
	.loc 1 1001 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$20, %esp
	.cfi_offset 3, -12
	.loc 1 1003 0
	cmpl	$0, 8(%ebp)
	je	.L150
	.loc 1 1004 0
	subl	$12, %esp
	pushl	8(%ebp)
	call	cio_puts
	addl	$16, %esp
.L150:
	.loc 1 1007 0
	movl	$0, -12(%ebp)
	.loc 1 1008 0
	movl	$ptable, %ebx
.LBB10:
	.loc 1 1009 0
	movl	$0, -16(%ebp)
	jmp	.L151
.L153:
	.loc 1 1010 0
	movl	28(%ebx), %eax
	testl	%eax, %eax
	je	.L152
	.loc 1 1011 0
	addl	$1, -12(%ebp)
	.loc 1 1012 0
	movl	24(%ebx), %eax
	subl	$4, %esp
	pushl	%eax
	pushl	-12(%ebp)
	pushl	$.LC31
	call	cio_printf
	addl	$16, %esp
	.loc 1 1013 0
	movl	(%ebx), %eax
	subl	$8, %esp
	pushl	%eax
	pushl	$0
	call	ctx_dump
	addl	$16, %esp
.L152:
	.loc 1 1009 0 discriminator 2
	addl	$1, -16(%ebp)
	addl	$48, %ebx
.L151:
	.loc 1 1009 0 is_stmt 0 discriminator 1
	cmpl	$24, -16(%ebp)
	jle	.L153
.LBE10:
	.loc 1 1016 0 is_stmt 1
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE56:
	.size	ctx_dump_all, .-ctx_dump_all
	.section	.rodata
.LC32:
	.string	" @ %08x:"
.LC33:
	.string	"???"
.LC34:
	.string	" %d %s"
.LC35:
	.string	" %s"
.LC36:
	.string	" ticks %u xit %d wake %08x\n"
.LC37:
	.string	" parent %08x"
.LC38:
	.string	" (%u)"
	.align 4
.LC39:
	.string	" next %08x context %08x stk %08x (%u)"
	.text
	.globl	pcb_dump
	.type	pcb_dump, @function
pcb_dump:
.LFB57:
	.loc 1 1027 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%esi
	pushl	%ebx
	subl	$16, %esp
	.cfi_offset 6, -12
	.cfi_offset 3, -16
	movl	12(%ebp), %ebx
	movl	16(%ebp), %eax
	movb	%al, -12(%ebp)
	.loc 1 1030 0
	cmpl	$0, 8(%ebp)
	je	.L155
	.loc 1 1031 0
	subl	$12, %esp
	pushl	8(%ebp)
	call	cio_puts
	addl	$16, %esp
.L155:
	.loc 1 1035 0
	movl	%ebx, %eax
	subl	$8, %esp
	pushl	%eax
	pushl	$.LC32
	call	cio_printf
	addl	$16, %esp
	.loc 1 1038 0
	testl	%ebx, %ebx
	jne	.L156
	.loc 1 1039 0
	subl	$12, %esp
	pushl	$.LC26
	call	cio_puts
	addl	$16, %esp
	.loc 1 1040 0
	jmp	.L154
.L156:
	.loc 1 1044 0
	movl	28(%ebx), %eax
	.loc 1 1043 0
	cmpl	$8, %eax
	ja	.L158
	.loc 1 1044 0 discriminator 1
	movl	28(%ebx), %eax
	.loc 1 1043 0 discriminator 1
	sall	$2, %eax
	leal	state_str(%eax), %edx
	jmp	.L159
.L158:
	.loc 1 1043 0 is_stmt 0 discriminator 2
	movl	$.LC33, %edx
.L159:
	.loc 1 1043 0 discriminator 4
	movl	24(%ebx), %eax
	subl	$4, %esp
	pushl	%edx
	pushl	%eax
	pushl	$.LC34
	call	cio_printf
	addl	$16, %esp
	.loc 1 1046 0 is_stmt 1 discriminator 4
	cmpb	$0, -12(%ebp)
	je	.L164
	.loc 1 1053 0
	movl	32(%ebx), %eax
	.loc 1 1052 0
	cmpl	$3, %eax
	ja	.L161
	.loc 1 1053 0 discriminator 1
	movl	32(%ebx), %edx
	.loc 1 1052 0 discriminator 1
	movl	%edx, %eax
	sall	$2, %eax
	addl	%edx, %eax
	addl	$prio_str, %eax
	jmp	.L162
.L161:
	.loc 1 1052 0 is_stmt 0 discriminator 2
	movl	$.LC33, %eax
.L162:
	.loc 1 1052 0 discriminator 4
	subl	$8, %esp
	pushl	%eax
	pushl	$.LC35
	call	cio_printf
	addl	$16, %esp
	.loc 1 1055 0 is_stmt 1 discriminator 4
	movl	16(%ebx), %ecx
	movl	20(%ebx), %edx
	movl	36(%ebx), %eax
	pushl	%ecx
	pushl	%edx
	pushl	%eax
	pushl	$.LC36
	call	cio_printf
	addl	$16, %esp
	.loc 1 1058 0 discriminator 4
	movl	12(%ebx), %eax
	subl	$8, %esp
	pushl	%eax
	pushl	$.LC37
	call	cio_printf
	addl	$16, %esp
	.loc 1 1059 0 discriminator 4
	movl	12(%ebx), %eax
	testl	%eax, %eax
	je	.L163
	.loc 1 1060 0
	movl	12(%ebx), %eax
	movl	24(%eax), %eax
	subl	$8, %esp
	pushl	%eax
	pushl	$.LC38
	call	cio_printf
	addl	$16, %esp
.L163:
	.loc 1 1063 0
	movl	40(%ebx), %eax
	.loc 1 1065 0
	movl	4(%ebx), %edx
	.loc 1 1063 0
	movl	%edx, %esi
	.loc 1 1064 0
	movl	(%ebx), %edx
	.loc 1 1063 0
	movl	%edx, %ecx
	.loc 1 1064 0
	movl	8(%ebx), %edx
	.loc 1 1063 0
	subl	$12, %esp
	pushl	%eax
	pushl	%esi
	pushl	%ecx
	pushl	%edx
	pushl	$.LC39
	call	cio_printf
	addl	$32, %esp
	.loc 1 1067 0
	subl	$12, %esp
	pushl	$10
	call	cio_putchar
	addl	$16, %esp
	jmp	.L154
.L164:
	.loc 1 1048 0
	nop
.L154:
	.loc 1 1068 0
	leal	-8(%ebp), %esp
	popl	%ebx
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE57:
	.size	pcb_dump, .-pcb_dump
	.section	.rodata
.LC40:
	.string	"%s: "
.LC41:
	.string	"NULL???\n"
.LC42:
	.string	"head %08x tail %08x"
.LC43:
	.string	"????"
.LC44:
	.string	" order %s\n"
.LC45:
	.string	" PIDs: "
.LC46:
	.string	" [%u]"
.LC47:
	.string	" ..."
	.text
	.globl	pcb_queue_dump
	.type	pcb_queue_dump, @function
pcb_queue_dump:
.LFB58:
	.loc 1 1077 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$40, %esp
	movl	16(%ebp), %eax
	movb	%al, -28(%ebp)
	.loc 1 1080 0
	subl	$8, %esp
	pushl	8(%ebp)
	pushl	$.LC40
	call	cio_printf
	addl	$16, %esp
	.loc 1 1081 0
	cmpl	$0, 12(%ebp)
	jne	.L166
	.loc 1 1082 0
	subl	$12, %esp
	pushl	$.LC41
	call	cio_puts
	addl	$16, %esp
	.loc 1 1083 0
	jmp	.L165
.L166:
	.loc 1 1088 0
	movl	12(%ebp), %eax
	movl	4(%eax), %eax
	.loc 1 1087 0
	movl	%eax, %edx
	.loc 1 1088 0
	movl	12(%ebp), %eax
	movl	(%eax), %eax
	.loc 1 1087 0
	subl	$4, %esp
	pushl	%edx
	pushl	%eax
	pushl	$.LC42
	call	cio_printf
	addl	$16, %esp
	.loc 1 1092 0
	movl	12(%ebp), %eax
	movl	8(%eax), %eax
	.loc 1 1091 0
	cmpl	$3, %eax
	ja	.L168
	.loc 1 1092 0 discriminator 1
	movl	12(%ebp), %eax
	movl	8(%eax), %edx
	.loc 1 1091 0 discriminator 1
	movl	%edx, %eax
	sall	$2, %eax
	addl	%edx, %eax
	addl	$ord_str, %eax
	jmp	.L169
.L168:
	.loc 1 1091 0 is_stmt 0 discriminator 2
	movl	$.LC43, %eax
.L169:
	.loc 1 1091 0 discriminator 4
	subl	$8, %esp
	pushl	%eax
	pushl	$.LC44
	call	cio_printf
	addl	$16, %esp
	.loc 1 1095 0 is_stmt 1 discriminator 4
	cmpb	$0, -28(%ebp)
	je	.L165
	.loc 1 1095 0 is_stmt 0 discriminator 1
	movl	12(%ebp), %eax
	movl	(%eax), %eax
	testl	%eax, %eax
	je	.L165
.LBB11:
	.loc 1 1096 0 is_stmt 1
	subl	$12, %esp
	pushl	$.LC45
	call	cio_puts
	addl	$16, %esp
	.loc 1 1097 0
	movl	12(%ebp), %eax
	movl	(%eax), %eax
	movl	%eax, -12(%ebp)
.LBB12:
	.loc 1 1098 0
	movl	$0, -16(%ebp)
	jmp	.L170
.L172:
	.loc 1 1099 0 discriminator 4
	movl	-12(%ebp), %eax
	movl	24(%eax), %eax
	subl	$8, %esp
	pushl	%eax
	pushl	$.LC46
	call	cio_printf
	addl	$16, %esp
	.loc 1 1098 0 discriminator 4
	addl	$1, -16(%ebp)
	movl	-12(%ebp), %eax
	movl	8(%eax), %eax
	movl	%eax, -12(%ebp)
.L170:
	.loc 1 1098 0 is_stmt 0 discriminator 1
	cmpl	$4, -16(%ebp)
	jg	.L171
	.loc 1 1098 0 discriminator 3
	cmpl	$0, -12(%ebp)
	jne	.L172
.L171:
.LBE12:
	.loc 1 1102 0 is_stmt 1
	cmpl	$0, -12(%ebp)
	je	.L173
	.loc 1 1103 0
	subl	$12, %esp
	pushl	$.LC47
	call	cio_puts
	addl	$16, %esp
.L173:
	.loc 1 1106 0
	subl	$12, %esp
	pushl	$10
	call	cio_putchar
	addl	$16, %esp
.L165:
.LBE11:
	.loc 1 1108 0
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE58:
	.size	pcb_queue_dump, .-pcb_queue_dump
	.section	.rodata
.LC48:
	.string	" #%d:"
	.align 4
.LC49:
	.string	"Table size %d, used %d + empty %d = %d???\n"
	.text
	.globl	ptable_dump
	.type	ptable_dump, @function
ptable_dump:
.LFB59:
	.loc 1 1118 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$36, %esp
	.cfi_offset 3, -12
	movl	12(%ebp), %eax
	movb	%al, -28(%ebp)
	.loc 1 1120 0
	cmpl	$0, 8(%ebp)
	je	.L175
	.loc 1 1121 0
	subl	$12, %esp
	pushl	8(%ebp)
	call	cio_puts
	addl	$16, %esp
.L175:
	.loc 1 1123 0
	subl	$12, %esp
	pushl	$32
	call	cio_putchar
	addl	$16, %esp
	.loc 1 1125 0
	movl	$0, -12(%ebp)
	.loc 1 1126 0
	movl	$0, -16(%ebp)
	.loc 1 1128 0
	movl	$ptable, %ebx
.LBB13:
	.loc 1 1129 0
	movl	$0, -20(%ebp)
	jmp	.L176
.L180:
	.loc 1 1130 0
	movl	28(%ebx), %eax
	testl	%eax, %eax
	jne	.L177
	.loc 1 1133 0
	addl	$1, -16(%ebp)
	jmp	.L178
.L177:
	.loc 1 1138 0
	addl	$1, -12(%ebp)
	.loc 1 1141 0
	cmpb	$0, -28(%ebp)
	jne	.L179
	.loc 1 1141 0 is_stmt 0 discriminator 1
	cmpl	$0, -12(%ebp)
	je	.L179
	.loc 1 1142 0 is_stmt 1
	subl	$12, %esp
	pushl	$44
	call	cio_putchar
	addl	$16, %esp
.L179:
	.loc 1 1146 0
	subl	$8, %esp
	pushl	-20(%ebp)
	pushl	$.LC48
	call	cio_printf
	addl	$16, %esp
	.loc 1 1149 0
	movzbl	-28(%ebp), %eax
	subl	$4, %esp
	pushl	%eax
	pushl	%ebx
	pushl	$0
	call	pcb_dump
	addl	$16, %esp
.L178:
	.loc 1 1129 0 discriminator 2
	addl	$1, -20(%ebp)
.L176:
	.loc 1 1129 0 is_stmt 0 discriminator 1
	cmpl	$24, -20(%ebp)
	jle	.L180
.LBE13:
	.loc 1 1154 0 is_stmt 1
	cmpb	$0, -28(%ebp)
	jne	.L181
	.loc 1 1155 0
	subl	$12, %esp
	pushl	$10
	call	cio_putchar
	addl	$16, %esp
.L181:
	.loc 1 1159 0
	movl	-12(%ebp), %edx
	movl	-16(%ebp), %eax
	addl	%edx, %eax
	cmpl	$25, %eax
	je	.L183
	.loc 1 1160 0
	movl	-12(%ebp), %edx
	movl	-16(%ebp), %eax
	addl	%edx, %eax
	subl	$12, %esp
	pushl	%eax
	pushl	-16(%ebp)
	pushl	-12(%ebp)
	pushl	$25
	pushl	$.LC49
	call	cio_printf
	addl	$32, %esp
.L183:
	.loc 1 1163 0
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE59:
	.size	ptable_dump, .-ptable_dump
	.section	.rodata
.LC50:
	.string	"Ptable: %u ***"
.LC51:
	.string	" %u %s"
	.text
	.globl	ptable_dump_counts
	.type	ptable_dump_counts, @function
ptable_dump_counts:
.LFB60:
	.loc 1 1171 0
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	subl	$52, %esp
	.cfi_offset 7, -12
	.loc 1 1172 0
	leal	-56(%ebp), %edx
	movl	$0, %eax
	movl	$9, %ecx
	movl	%edx, %edi
	rep stosl
	.loc 1 1173 0
	movl	$0, -12(%ebp)
	.loc 1 1175 0
	movl	$0, -16(%ebp)
	.loc 1 1176 0
	movl	$ptable, -20(%ebp)
	.loc 1 1177 0
	jmp	.L185
.L188:
	.loc 1 1178 0
	movl	-20(%ebp), %eax
	movl	28(%eax), %eax
	cmpl	$8, %eax
	jbe	.L186
	.loc 1 1179 0
	addl	$1, -12(%ebp)
	jmp	.L187
.L186:
	.loc 1 1181 0
	movl	-20(%ebp), %eax
	movl	28(%eax), %eax
	movl	-56(%ebp,%eax,4), %edx
	addl	$1, %edx
	movl	%edx, -56(%ebp,%eax,4)
.L187:
	.loc 1 1183 0
	addl	$1, -16(%ebp)
	.loc 1 1184 0
	addl	$48, -20(%ebp)
.L185:
	.loc 1 1177 0
	cmpl	$24, -16(%ebp)
	jle	.L188
	.loc 1 1187 0
	subl	$8, %esp
	pushl	-12(%ebp)
	pushl	$.LC50
	call	cio_printf
	addl	$16, %esp
	.loc 1 1188 0
	movl	$0, -16(%ebp)
	jmp	.L189
.L191:
	.loc 1 1189 0
	movl	-16(%ebp), %eax
	movl	-56(%ebp,%eax,4), %eax
	testl	%eax, %eax
	je	.L190
	.loc 1 1191 0
	movl	-16(%ebp), %eax
	sall	$2, %eax
	leal	state_str(%eax), %edx
	.loc 1 1190 0
	movl	-16(%ebp), %eax
	movl	-56(%ebp,%eax,4), %eax
	subl	$4, %esp
	pushl	%edx
	pushl	%eax
	pushl	$.LC51
	call	cio_printf
	addl	$16, %esp
.L190:
	.loc 1 1188 0 discriminator 2
	addl	$1, -16(%ebp)
.L189:
	.loc 1 1188 0 is_stmt 0 discriminator 1
	cmpl	$8, -16(%ebp)
	jle	.L191
	.loc 1 1194 0 is_stmt 1
	subl	$12, %esp
	pushl	$10
	call	cio_putchar
	addl	$16, %esp
	.loc 1 1195 0
	nop
	movl	-4(%ebp), %edi
	leave
	.cfi_restore 5
	.cfi_restore 7
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE60:
	.size	ptable_dump_counts, .-ptable_dump_counts
	.section	.rodata
	.align 4
	.type	__func__.1409, @object
	.size	__func__.1409, 17
__func__.1409:
	.string	"find_prev_wakeup"
	.align 4
	.type	__func__.1419, @object
	.size	__func__.1419, 19
__func__.1419:
	.string	"find_prev_priority"
	.align 4
	.type	__func__.1429, @object
	.size	__func__.1429, 14
__func__.1429:
	.string	"find_prev_pid"
	.align 4
	.type	__func__.1438, @object
	.size	__func__.1438, 9
__func__.1438:
	.string	"pcb_init"
	.align 4
	.type	__func__.1447, @object
	.size	__func__.1447, 10
__func__.1447:
	.string	"pcb_alloc"
	.align 4
	.type	__func__.1453, @object
	.size	__func__.1453, 9
__func__.1453:
	.string	"pcb_free"
	.align 4
	.type	__func__.1462, @object
	.size	__func__.1462, 15
__func__.1462:
	.string	"pcb_stack_free"
	.align 4
	.type	__func__.1466, @object
	.size	__func__.1466, 12
__func__.1466:
	.string	"pcb_zombify"
	.align 4
	.type	__func__.1495, @object
	.size	__func__.1495, 14
__func__.1495:
	.string	"pcb_find_ppid"
	.align 4
	.type	__func__.1503, @object
	.size	__func__.1503, 16
__func__.1503:
	.string	"pcb_queue_reset"
	.align 4
	.type	__func__.1507, @object
	.size	__func__.1507, 16
__func__.1507:
	.string	"pcb_queue_empty"
	.align 4
	.type	__func__.1511, @object
	.size	__func__.1511, 17
__func__.1511:
	.string	"pcb_queue_length"
	.align 4
	.type	__func__.1521, @object
	.size	__func__.1521, 17
__func__.1521:
	.string	"pcb_queue_insert"
	.align 4
	.type	__func__.1533, @object
	.size	__func__.1533, 17
__func__.1533:
	.string	"pcb_queue_remove"
	.align 4
	.type	__func__.1539, @object
	.size	__func__.1539, 22
__func__.1539:
	.string	"pcb_queue_remove_this"
	.align 4
	.type	__func__.1548, @object
	.size	__func__.1548, 15
__func__.1548:
	.string	"pcb_queue_peek"
	.align 4
	.type	__func__.1552, @object
	.size	__func__.1552, 9
__func__.1552:
	.string	"schedule"
	.align 4
	.type	__func__.1556, @object
	.size	__func__.1556, 9
__func__.1556:
	.string	"dispatch"
	.text
.Letext0:
	.file 2 "./include/types.h"
	.file 3 "./include/kdefs.h"
	.file 4 "./include/defs.h"
	.file 5 "./include/procs.h"
	.section	.debug_info,"",@progbits
.Ldebug_info0:
	.long	0xf4a
	.value	0x4
	.long	.Ldebug_abbrev0
	.byte	0x4
	.uleb128 0x1
	.long	.LASF128
	.byte	0xc
	.long	.LASF129
	.long	.LASF130
	.long	.Ltext0
	.long	.Letext0-.Ltext0
	.long	.Ldebug_line0
	.uleb128 0x2
	.byte	0x1
	.byte	0x6
	.long	.LASF0
	.uleb128 0x3
	.long	0x25
	.uleb128 0x4
	.long	.LASF4
	.byte	0x2
	.byte	0x1e
	.long	0x3c
	.uleb128 0x2
	.byte	0x1
	.byte	0x8
	.long	.LASF1
	.uleb128 0x2
	.byte	0x2
	.byte	0x5
	.long	.LASF2
	.uleb128 0x2
	.byte	0x2
	.byte	0x7
	.long	.LASF3
	.uleb128 0x4
	.long	.LASF5
	.byte	0x2
	.byte	0x21
	.long	0x5c
	.uleb128 0x5
	.byte	0x4
	.byte	0x5
	.string	"int"
	.uleb128 0x4
	.long	.LASF6
	.byte	0x2
	.byte	0x22
	.long	0x6e
	.uleb128 0x2
	.byte	0x4
	.byte	0x7
	.long	.LASF7
	.uleb128 0x2
	.byte	0x8
	.byte	0x5
	.long	.LASF8
	.uleb128 0x2
	.byte	0x8
	.byte	0x7
	.long	.LASF9
	.uleb128 0x4
	.long	.LASF10
	.byte	0x2
	.byte	0x28
	.long	0x6e
	.uleb128 0x2
	.byte	0x4
	.byte	0x7
	.long	.LASF11
	.uleb128 0x4
	.long	.LASF12
	.byte	0x2
	.byte	0x2c
	.long	0x31
	.uleb128 0x6
	.long	.LASF22
	.byte	0x7
	.byte	0x4
	.long	0x6e
	.byte	0x4
	.byte	0x5e
	.long	0xd0
	.uleb128 0x7
	.long	.LASF13
	.byte	0
	.uleb128 0x7
	.long	.LASF14
	.byte	0x1
	.uleb128 0x7
	.long	.LASF15
	.byte	0x2
	.uleb128 0x7
	.long	.LASF16
	.byte	0x3
	.uleb128 0x7
	.long	.LASF17
	.byte	0x4
	.byte	0
	.uleb128 0x8
	.long	0x25
	.long	0xe0
	.uleb128 0x9
	.long	0x6e
	.byte	0xff
	.byte	0
	.uleb128 0xa
	.long	.LASF18
	.byte	0x3
	.byte	0x9d
	.long	0xd0
	.uleb128 0x8
	.long	0x25
	.long	0xfc
	.uleb128 0xb
	.long	0x6e
	.value	0x1ff
	.byte	0
	.uleb128 0xa
	.long	.LASF19
	.byte	0x3
	.byte	0xa0
	.long	0xeb
	.uleb128 0x8
	.long	0x63
	.long	0x118
	.uleb128 0xb
	.long	0x6e
	.value	0x3ff
	.byte	0
	.uleb128 0xa
	.long	.LASF20
	.byte	0x3
	.byte	0xa3
	.long	0x107
	.uleb128 0xa
	.long	.LASF21
	.byte	0x3
	.byte	0xa4
	.long	0x12e
	.uleb128 0xc
	.byte	0x4
	.long	0x63
	.uleb128 0x6
	.long	.LASF23
	.byte	0x7
	.byte	0x4
	.long	0x6e
	.byte	0x5
	.byte	0x1f
	.long	0x182
	.uleb128 0x7
	.long	.LASF24
	.byte	0
	.uleb128 0x7
	.long	.LASF25
	.byte	0x1
	.uleb128 0x7
	.long	.LASF26
	.byte	0x2
	.uleb128 0x7
	.long	.LASF27
	.byte	0x3
	.uleb128 0x7
	.long	.LASF28
	.byte	0x4
	.uleb128 0x7
	.long	.LASF29
	.byte	0x5
	.uleb128 0x7
	.long	.LASF30
	.byte	0x6
	.uleb128 0x7
	.long	.LASF31
	.byte	0x7
	.uleb128 0x7
	.long	.LASF32
	.byte	0x8
	.uleb128 0x7
	.long	.LASF33
	.byte	0x9
	.byte	0
	.uleb128 0x6
	.long	.LASF34
	.byte	0x7
	.byte	0x4
	.long	0x6e
	.byte	0x5
	.byte	0x39
	.long	0x1a6
	.uleb128 0x7
	.long	.LASF35
	.byte	0x1
	.uleb128 0x7
	.long	.LASF36
	.byte	0x3
	.uleb128 0x7
	.long	.LASF37
	.byte	0x5
	.byte	0
	.uleb128 0xd
	.long	.LASF42
	.byte	0x48
	.byte	0x5
	.byte	0x50
	.long	0x285
	.uleb128 0xe
	.string	"ss"
	.byte	0x5
	.byte	0x51
	.long	0x63
	.byte	0
	.uleb128 0xe
	.string	"gs"
	.byte	0x5
	.byte	0x52
	.long	0x63
	.byte	0x4
	.uleb128 0xe
	.string	"fs"
	.byte	0x5
	.byte	0x53
	.long	0x63
	.byte	0x8
	.uleb128 0xe
	.string	"es"
	.byte	0x5
	.byte	0x54
	.long	0x63
	.byte	0xc
	.uleb128 0xe
	.string	"ds"
	.byte	0x5
	.byte	0x55
	.long	0x63
	.byte	0x10
	.uleb128 0xe
	.string	"edi"
	.byte	0x5
	.byte	0x56
	.long	0x63
	.byte	0x14
	.uleb128 0xe
	.string	"esi"
	.byte	0x5
	.byte	0x57
	.long	0x63
	.byte	0x18
	.uleb128 0xe
	.string	"ebp"
	.byte	0x5
	.byte	0x58
	.long	0x63
	.byte	0x1c
	.uleb128 0xe
	.string	"esp"
	.byte	0x5
	.byte	0x59
	.long	0x63
	.byte	0x20
	.uleb128 0xe
	.string	"ebx"
	.byte	0x5
	.byte	0x5a
	.long	0x63
	.byte	0x24
	.uleb128 0xe
	.string	"edx"
	.byte	0x5
	.byte	0x5b
	.long	0x63
	.byte	0x28
	.uleb128 0xe
	.string	"ecx"
	.byte	0x5
	.byte	0x5c
	.long	0x63
	.byte	0x2c
	.uleb128 0xe
	.string	"eax"
	.byte	0x5
	.byte	0x5d
	.long	0x63
	.byte	0x30
	.uleb128 0xf
	.long	.LASF38
	.byte	0x5
	.byte	0x5e
	.long	0x63
	.byte	0x34
	.uleb128 0xf
	.long	.LASF39
	.byte	0x5
	.byte	0x5f
	.long	0x63
	.byte	0x38
	.uleb128 0xe
	.string	"eip"
	.byte	0x5
	.byte	0x60
	.long	0x63
	.byte	0x3c
	.uleb128 0xe
	.string	"cs"
	.byte	0x5
	.byte	0x61
	.long	0x63
	.byte	0x40
	.uleb128 0xf
	.long	.LASF40
	.byte	0x5
	.byte	0x62
	.long	0x63
	.byte	0x44
	.byte	0
	.uleb128 0x4
	.long	.LASF41
	.byte	0x5
	.byte	0x63
	.long	0x1a6
	.uleb128 0xd
	.long	.LASF43
	.byte	0x30
	.byte	0x5
	.byte	0x77
	.long	0x32d
	.uleb128 0xf
	.long	.LASF44
	.byte	0x5
	.byte	0x7b
	.long	0x32d
	.byte	0
	.uleb128 0xf
	.long	.LASF45
	.byte	0x5
	.byte	0x7e
	.long	0x12e
	.byte	0x4
	.uleb128 0xf
	.long	.LASF46
	.byte	0x5
	.byte	0x81
	.long	0x333
	.byte	0x8
	.uleb128 0xf
	.long	.LASF47
	.byte	0x5
	.byte	0x84
	.long	0x333
	.byte	0xc
	.uleb128 0xf
	.long	.LASF48
	.byte	0x5
	.byte	0x85
	.long	0x63
	.byte	0x10
	.uleb128 0xf
	.long	.LASF49
	.byte	0x5
	.byte	0x86
	.long	0x51
	.byte	0x14
	.uleb128 0xe
	.string	"pid"
	.byte	0x5
	.byte	0x89
	.long	0x83
	.byte	0x18
	.uleb128 0xf
	.long	.LASF50
	.byte	0x5
	.byte	0x8a
	.long	0x134
	.byte	0x1c
	.uleb128 0xf
	.long	.LASF51
	.byte	0x5
	.byte	0x8b
	.long	0xa0
	.byte	0x20
	.uleb128 0xf
	.long	.LASF52
	.byte	0x5
	.byte	0x8c
	.long	0x83
	.byte	0x24
	.uleb128 0xf
	.long	.LASF53
	.byte	0x5
	.byte	0x8d
	.long	0x83
	.byte	0x28
	.uleb128 0xf
	.long	.LASF54
	.byte	0x5
	.byte	0x90
	.long	0x339
	.byte	0x2c
	.byte	0
	.uleb128 0xc
	.byte	0x4
	.long	0x285
	.uleb128 0xc
	.byte	0x4
	.long	0x290
	.uleb128 0x8
	.long	0x31
	.long	0x349
	.uleb128 0x9
	.long	0x6e
	.byte	0x3
	.byte	0
	.uleb128 0x4
	.long	.LASF55
	.byte	0x5
	.byte	0x92
	.long	0x290
	.uleb128 0x4
	.long	.LASF56
	.byte	0x5
	.byte	0x98
	.long	0x364
	.uleb128 0x3
	.long	0x354
	.uleb128 0xc
	.byte	0x4
	.long	0x36a
	.uleb128 0xd
	.long	.LASF57
	.byte	0xc
	.byte	0x1
	.byte	0x23
	.long	0x39b
	.uleb128 0xf
	.long	.LASF58
	.byte	0x1
	.byte	0x24
	.long	0x418
	.byte	0
	.uleb128 0xf
	.long	.LASF59
	.byte	0x1
	.byte	0x25
	.long	0x418
	.byte	0x4
	.uleb128 0xf
	.long	.LASF60
	.byte	0x1
	.byte	0x26
	.long	0x39b
	.byte	0x8
	.byte	0
	.uleb128 0x6
	.long	.LASF61
	.byte	0x7
	.byte	0x4
	.long	0x6e
	.byte	0x5
	.byte	0x9d
	.long	0x3cb
	.uleb128 0x7
	.long	.LASF62
	.byte	0
	.uleb128 0x7
	.long	.LASF63
	.byte	0x1
	.uleb128 0x7
	.long	.LASF64
	.byte	0x2
	.uleb128 0x7
	.long	.LASF65
	.byte	0x3
	.uleb128 0x7
	.long	.LASF66
	.byte	0x4
	.byte	0
	.uleb128 0xa
	.long	.LASF67
	.byte	0x5
	.byte	0xaa
	.long	0x354
	.uleb128 0xa
	.long	.LASF68
	.byte	0x5
	.byte	0xab
	.long	0x354
	.uleb128 0xa
	.long	.LASF69
	.byte	0x5
	.byte	0xac
	.long	0x354
	.uleb128 0xa
	.long	.LASF70
	.byte	0x5
	.byte	0xad
	.long	0x354
	.uleb128 0xa
	.long	.LASF71
	.byte	0x5
	.byte	0xae
	.long	0x354
	.uleb128 0xa
	.long	.LASF72
	.byte	0x5
	.byte	0xaf
	.long	0x354
	.uleb128 0xa
	.long	.LASF73
	.byte	0x5
	.byte	0xb2
	.long	0x418
	.uleb128 0xc
	.byte	0x4
	.long	0x349
	.uleb128 0x8
	.long	0x349
	.long	0x42e
	.uleb128 0x9
	.long	0x6e
	.byte	0x18
	.byte	0
	.uleb128 0xa
	.long	.LASF74
	.byte	0x5
	.byte	0xb5
	.long	0x41e
	.uleb128 0xa
	.long	.LASF75
	.byte	0x5
	.byte	0xb8
	.long	0x83
	.uleb128 0xa
	.long	.LASF76
	.byte	0x5
	.byte	0xbb
	.long	0x418
	.uleb128 0x8
	.long	0x2c
	.long	0x465
	.uleb128 0x9
	.long	0x6e
	.byte	0x8
	.uleb128 0x9
	.long	0x6e
	.byte	0x3
	.byte	0
	.uleb128 0x3
	.long	0x44f
	.uleb128 0xa
	.long	.LASF77
	.byte	0x5
	.byte	0xbe
	.long	0x465
	.uleb128 0x8
	.long	0x2c
	.long	0x48b
	.uleb128 0x9
	.long	0x6e
	.byte	0x3
	.uleb128 0x9
	.long	0x6e
	.byte	0x4
	.byte	0
	.uleb128 0x3
	.long	0x475
	.uleb128 0xa
	.long	.LASF78
	.byte	0x5
	.byte	0xc1
	.long	0x48b
	.uleb128 0xa
	.long	.LASF79
	.byte	0x5
	.byte	0xc4
	.long	0x48b
	.uleb128 0x10
	.long	.LASF80
	.byte	0x1
	.byte	0x2e
	.long	0x36a
	.uleb128 0x5
	.byte	0x3
	.long	pcb_freelist_queue
	.uleb128 0x10
	.long	.LASF81
	.byte	0x1
	.byte	0x2f
	.long	0x36a
	.uleb128 0x5
	.byte	0x3
	.long	ready_queue
	.uleb128 0x10
	.long	.LASF82
	.byte	0x1
	.byte	0x30
	.long	0x36a
	.uleb128 0x5
	.byte	0x3
	.long	waiting_queue
	.uleb128 0x10
	.long	.LASF83
	.byte	0x1
	.byte	0x31
	.long	0x36a
	.uleb128 0x5
	.byte	0x3
	.long	sleeping_queue
	.uleb128 0x10
	.long	.LASF84
	.byte	0x1
	.byte	0x32
	.long	0x36a
	.uleb128 0x5
	.byte	0x3
	.long	zombie_queue
	.uleb128 0x10
	.long	.LASF85
	.byte	0x1
	.byte	0x33
	.long	0x36a
	.uleb128 0x5
	.byte	0x3
	.long	sioread_queue
	.uleb128 0x11
	.long	0x3cb
	.byte	0x1
	.byte	0x3a
	.uleb128 0x5
	.byte	0x3
	.long	pcb_freelist
	.uleb128 0x11
	.long	0x3d6
	.byte	0x1
	.byte	0x3b
	.uleb128 0x5
	.byte	0x3
	.long	ready
	.uleb128 0x11
	.long	0x3e1
	.byte	0x1
	.byte	0x3c
	.uleb128 0x5
	.byte	0x3
	.long	waiting
	.uleb128 0x11
	.long	0x3ec
	.byte	0x1
	.byte	0x3d
	.uleb128 0x5
	.byte	0x3
	.long	sleeping
	.uleb128 0x11
	.long	0x3f7
	.byte	0x1
	.byte	0x3e
	.uleb128 0x5
	.byte	0x3
	.long	zombie
	.uleb128 0x11
	.long	0x402
	.byte	0x1
	.byte	0x3f
	.uleb128 0x5
	.byte	0x3
	.long	sioread
	.uleb128 0x11
	.long	0x40d
	.byte	0x1
	.byte	0x42
	.uleb128 0x5
	.byte	0x3
	.long	current
	.uleb128 0x11
	.long	0x42e
	.byte	0x1
	.byte	0x45
	.uleb128 0x5
	.byte	0x3
	.long	ptable
	.uleb128 0x11
	.long	0x439
	.byte	0x1
	.byte	0x48
	.uleb128 0x5
	.byte	0x3
	.long	next_pid
	.uleb128 0x11
	.long	0x444
	.byte	0x1
	.byte	0x4b
	.uleb128 0x5
	.byte	0x3
	.long	init_pcb
	.uleb128 0x11
	.long	0x46a
	.byte	0x1
	.byte	0x4e
	.uleb128 0x5
	.byte	0x3
	.long	state_str
	.uleb128 0x11
	.long	0x490
	.byte	0x1
	.byte	0x5b
	.uleb128 0x5
	.byte	0x3
	.long	prio_str
	.uleb128 0x11
	.long	0x49b
	.byte	0x1
	.byte	0x63
	.uleb128 0x5
	.byte	0x3
	.long	ord_str
	.uleb128 0x12
	.long	.LASF88
	.byte	0x1
	.value	0x493
	.long	.LFB60
	.long	.LFE60-.LFB60
	.uleb128 0x1
	.byte	0x9c
	.long	0x606
	.uleb128 0x13
	.long	.LASF86
	.byte	0x1
	.value	0x494
	.long	0x606
	.uleb128 0x2
	.byte	0x91
	.sleb128 -64
	.uleb128 0x13
	.long	.LASF87
	.byte	0x1
	.value	0x495
	.long	0x83
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x14
	.string	"n"
	.byte	0x1
	.value	0x497
	.long	0x5c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.uleb128 0x14
	.string	"ptr"
	.byte	0x1
	.value	0x498
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -28
	.byte	0
	.uleb128 0x8
	.long	0x83
	.long	0x616
	.uleb128 0x9
	.long	0x6e
	.byte	0x8
	.byte	0
	.uleb128 0x12
	.long	.LASF89
	.byte	0x1
	.value	0x45e
	.long	.LFB59
	.long	.LFE59-.LFB59
	.uleb128 0x1
	.byte	0x9c
	.long	0x68e
	.uleb128 0x15
	.string	"msg"
	.byte	0x1
	.value	0x45e
	.long	0x68e
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x15
	.string	"all"
	.byte	0x1
	.value	0x45e
	.long	0x95
	.uleb128 0x2
	.byte	0x91
	.sleb128 -36
	.uleb128 0x13
	.long	.LASF90
	.byte	0x1
	.value	0x465
	.long	0x5c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x13
	.long	.LASF91
	.byte	0x1
	.value	0x466
	.long	0x5c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.uleb128 0x14
	.string	"pcb"
	.byte	0x1
	.value	0x468
	.long	0x418
	.uleb128 0x1
	.byte	0x53
	.uleb128 0x16
	.long	.LBB13
	.long	.LBE13-.LBB13
	.uleb128 0x14
	.string	"i"
	.byte	0x1
	.value	0x469
	.long	0x5c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -28
	.byte	0
	.byte	0
	.uleb128 0xc
	.byte	0x4
	.long	0x2c
	.uleb128 0x12
	.long	.LASF92
	.byte	0x1
	.value	0x435
	.long	.LFB58
	.long	.LFE58-.LFB58
	.uleb128 0x1
	.byte	0x9c
	.long	0x708
	.uleb128 0x15
	.string	"msg"
	.byte	0x1
	.value	0x435
	.long	0x68e
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x17
	.long	.LASF93
	.byte	0x1
	.value	0x435
	.long	0x354
	.uleb128 0x2
	.byte	0x91
	.sleb128 4
	.uleb128 0x17
	.long	.LASF94
	.byte	0x1
	.value	0x435
	.long	0x95
	.uleb128 0x2
	.byte	0x91
	.sleb128 -36
	.uleb128 0x16
	.long	.LBB11
	.long	.LBE11-.LBB11
	.uleb128 0x14
	.string	"tmp"
	.byte	0x1
	.value	0x449
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x16
	.long	.LBB12
	.long	.LBE12-.LBB12
	.uleb128 0x14
	.string	"i"
	.byte	0x1
	.value	0x44a
	.long	0x5c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.byte	0
	.uleb128 0x12
	.long	.LASF95
	.byte	0x1
	.value	0x403
	.long	.LFB57
	.long	.LFE57-.LFB57
	.uleb128 0x1
	.byte	0x9c
	.long	0x74b
	.uleb128 0x15
	.string	"msg"
	.byte	0x1
	.value	0x403
	.long	0x68e
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x15
	.string	"pcb"
	.byte	0x1
	.value	0x403
	.long	0x418
	.uleb128 0x1
	.byte	0x53
	.uleb128 0x15
	.string	"all"
	.byte	0x1
	.value	0x403
	.long	0x95
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.uleb128 0x12
	.long	.LASF96
	.byte	0x1
	.value	0x3e9
	.long	.LFB56
	.long	.LFE56-.LFB56
	.uleb128 0x1
	.byte	0x9c
	.long	0x7a3
	.uleb128 0x15
	.string	"msg"
	.byte	0x1
	.value	0x3e9
	.long	0x68e
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x14
	.string	"n"
	.byte	0x1
	.value	0x3ef
	.long	0x5c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x14
	.string	"pcb"
	.byte	0x1
	.value	0x3f0
	.long	0x418
	.uleb128 0x1
	.byte	0x53
	.uleb128 0x16
	.long	.LBB10
	.long	.LBE10-.LBB10
	.uleb128 0x14
	.string	"i"
	.byte	0x1
	.value	0x3f1
	.long	0x5c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.uleb128 0x12
	.long	.LASF97
	.byte	0x1
	.value	0x3c6
	.long	.LFB55
	.long	.LFE55-.LFB55
	.uleb128 0x1
	.byte	0x9c
	.long	0x7d5
	.uleb128 0x15
	.string	"msg"
	.byte	0x1
	.value	0x3c6
	.long	0x68e
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x15
	.string	"c"
	.byte	0x1
	.value	0x3c6
	.long	0x32d
	.uleb128 0x1
	.byte	0x53
	.byte	0
	.uleb128 0x12
	.long	.LASF98
	.byte	0x1
	.value	0x3a8
	.long	.LFB54
	.long	.LFE54-.LFB54
	.uleb128 0x1
	.byte	0x9c
	.long	0x80a
	.uleb128 0x18
	.long	.LASF101
	.long	0x81a
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1556
	.uleb128 0x13
	.long	.LASF99
	.byte	0x1
	.value	0x3ae
	.long	0x5c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.uleb128 0x8
	.long	0x2c
	.long	0x81a
	.uleb128 0x9
	.long	0x6e
	.byte	0x8
	.byte	0
	.uleb128 0x3
	.long	0x80a
	.uleb128 0x12
	.long	.LASF100
	.byte	0x1
	.value	0x38f
	.long	.LFB53
	.long	.LFE53-.LFB53
	.uleb128 0x1
	.byte	0x9c
	.long	0x854
	.uleb128 0x15
	.string	"pcb"
	.byte	0x1
	.value	0x38f
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x18
	.long	.LASF101
	.long	0x81a
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1552
	.byte	0
	.uleb128 0x19
	.long	.LASF102
	.byte	0x1
	.value	0x376
	.long	0x418
	.long	.LFB52
	.long	.LFE52-.LFB52
	.uleb128 0x1
	.byte	0x9c
	.long	0x88d
	.uleb128 0x17
	.long	.LASF93
	.byte	0x1
	.value	0x376
	.long	0x35f
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x18
	.long	.LASF101
	.long	0x89d
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1548
	.byte	0
	.uleb128 0x8
	.long	0x2c
	.long	0x89d
	.uleb128 0x9
	.long	0x6e
	.byte	0xe
	.byte	0
	.uleb128 0x3
	.long	0x88d
	.uleb128 0x19
	.long	.LASF103
	.byte	0x1
	.value	0x326
	.long	0x5c
	.long	.LFB51
	.long	.LFE51-.LFB51
	.uleb128 0x1
	.byte	0x9c
	.long	0x908
	.uleb128 0x17
	.long	.LASF93
	.byte	0x1
	.value	0x326
	.long	0x354
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x15
	.string	"pcb"
	.byte	0x1
	.value	0x326
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 4
	.uleb128 0x18
	.long	.LASF101
	.long	0x918
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1539
	.uleb128 0x13
	.long	.LASF104
	.byte	0x1
	.value	0x332
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x13
	.long	.LASF105
	.byte	0x1
	.value	0x333
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.uleb128 0x8
	.long	0x2c
	.long	0x918
	.uleb128 0x9
	.long	0x6e
	.byte	0x15
	.byte	0
	.uleb128 0x3
	.long	0x908
	.uleb128 0x19
	.long	.LASF106
	.byte	0x1
	.value	0x2fa
	.long	0x5c
	.long	.LFB50
	.long	.LFE50-.LFB50
	.uleb128 0x1
	.byte	0x9c
	.long	0x974
	.uleb128 0x17
	.long	.LASF93
	.byte	0x1
	.value	0x2fa
	.long	0x354
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x15
	.string	"pcb"
	.byte	0x1
	.value	0x2fa
	.long	0x974
	.uleb128 0x2
	.byte	0x91
	.sleb128 4
	.uleb128 0x18
	.long	.LASF101
	.long	0x98a
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1533
	.uleb128 0x14
	.string	"tmp"
	.byte	0x1
	.value	0x306
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.uleb128 0xc
	.byte	0x4
	.long	0x418
	.uleb128 0x8
	.long	0x2c
	.long	0x98a
	.uleb128 0x9
	.long	0x6e
	.byte	0x10
	.byte	0
	.uleb128 0x3
	.long	0x97a
	.uleb128 0x19
	.long	.LASF107
	.byte	0x1
	.value	0x2a9
	.long	0x5c
	.long	.LFB49
	.long	.LFE49-.LFB49
	.uleb128 0x1
	.byte	0x9c
	.long	0x9e6
	.uleb128 0x17
	.long	.LASF93
	.byte	0x1
	.value	0x2a9
	.long	0x354
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x15
	.string	"pcb"
	.byte	0x1
	.value	0x2a9
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 4
	.uleb128 0x18
	.long	.LASF101
	.long	0x98a
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1521
	.uleb128 0x13
	.long	.LASF104
	.byte	0x1
	.value	0x2bd
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.uleb128 0x19
	.long	.LASF108
	.byte	0x1
	.value	0x28e
	.long	0x83
	.long	.LFB48
	.long	.LFE48-.LFB48
	.uleb128 0x1
	.byte	0x9c
	.long	0xa3b
	.uleb128 0x17
	.long	.LASF93
	.byte	0x1
	.value	0x28e
	.long	0x35f
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x18
	.long	.LASF101
	.long	0x98a
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1511
	.uleb128 0x14
	.string	"tmp"
	.byte	0x1
	.value	0x294
	.long	0x418
	.uleb128 0x1
	.byte	0x53
	.uleb128 0x14
	.string	"num"
	.byte	0x1
	.value	0x295
	.long	0x5c
	.uleb128 0x1
	.byte	0x56
	.byte	0
	.uleb128 0x19
	.long	.LASF109
	.byte	0x1
	.value	0x27d
	.long	0x95
	.long	.LFB47
	.long	.LFE47-.LFB47
	.uleb128 0x1
	.byte	0x9c
	.long	0xa74
	.uleb128 0x17
	.long	.LASF93
	.byte	0x1
	.value	0x27d
	.long	0x354
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x18
	.long	.LASF101
	.long	0xa84
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1507
	.byte	0
	.uleb128 0x8
	.long	0x2c
	.long	0xa84
	.uleb128 0x9
	.long	0x6e
	.byte	0xf
	.byte	0
	.uleb128 0x3
	.long	0xa74
	.uleb128 0x19
	.long	.LASF110
	.byte	0x1
	.value	0x262
	.long	0x5c
	.long	.LFB46
	.long	.LFE46-.LFB46
	.uleb128 0x1
	.byte	0x9c
	.long	0xad1
	.uleb128 0x17
	.long	.LASF93
	.byte	0x1
	.value	0x262
	.long	0x354
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x17
	.long	.LASF111
	.byte	0x1
	.value	0x262
	.long	0x39b
	.uleb128 0x2
	.byte	0x91
	.sleb128 4
	.uleb128 0x18
	.long	.LASF101
	.long	0xa84
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1503
	.byte	0
	.uleb128 0x19
	.long	.LASF112
	.byte	0x1
	.value	0x242
	.long	0x418
	.long	.LFB45
	.long	.LFE45-.LFB45
	.uleb128 0x1
	.byte	0x9c
	.long	0xb2e
	.uleb128 0x15
	.string	"pid"
	.byte	0x1
	.value	0x242
	.long	0x83
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x14
	.string	"p"
	.byte	0x1
	.value	0x24a
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x18
	.long	.LASF101
	.long	0xb3e
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1495
	.uleb128 0x16
	.long	.LBB9
	.long	.LBE9-.LBB9
	.uleb128 0x14
	.string	"i"
	.byte	0x1
	.value	0x24c
	.long	0x5c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.uleb128 0x8
	.long	0x2c
	.long	0xb3e
	.uleb128 0x9
	.long	0x6e
	.byte	0xd
	.byte	0
	.uleb128 0x3
	.long	0xb2e
	.uleb128 0x1a
	.long	.LASF113
	.byte	0x1
	.value	0x225
	.long	0x418
	.long	.LFB44
	.long	.LFE44-.LFB44
	.uleb128 0x1
	.byte	0x9c
	.long	0xb91
	.uleb128 0x15
	.string	"pid"
	.byte	0x1
	.value	0x225
	.long	0x83
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x14
	.string	"p"
	.byte	0x1
	.value	0x22d
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -12
	.uleb128 0x16
	.long	.LBB8
	.long	.LBE8-.LBB8
	.uleb128 0x14
	.string	"i"
	.byte	0x1
	.value	0x22f
	.long	0x5c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -16
	.byte	0
	.byte	0
	.uleb128 0x12
	.long	.LASF114
	.byte	0x1
	.value	0x209
	.long	.LFB43
	.long	.LFE43-.LFB43
	.uleb128 0x1
	.byte	0x9c
	.long	0xbb7
	.uleb128 0x15
	.string	"pcb"
	.byte	0x1
	.value	0x209
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.byte	0
	.uleb128 0x12
	.long	.LASF115
	.byte	0x1
	.value	0x158
	.long	.LFB42
	.long	.LFE42-.LFB42
	.uleb128 0x1
	.byte	0x9c
	.long	0xc90
	.uleb128 0x17
	.long	.LASF116
	.byte	0x1
	.value	0x158
	.long	0x418
	.uleb128 0x1
	.byte	0x53
	.uleb128 0x18
	.long	.LASF101
	.long	0xca0
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1466
	.uleb128 0x13
	.long	.LASF47
	.byte	0x1
	.value	0x167
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -28
	.uleb128 0x13
	.long	.LASF117
	.byte	0x1
	.value	0x168
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x13
	.long	.LASF118
	.byte	0x1
	.value	0x16b
	.long	0x83
	.uleb128 0x2
	.byte	0x91
	.sleb128 -32
	.uleb128 0x13
	.long	.LASF105
	.byte	0x1
	.value	0x16e
	.long	0x418
	.uleb128 0x1
	.byte	0x56
	.uleb128 0x1b
	.long	.LBB4
	.long	.LBE4-.LBB4
	.long	0xc40
	.uleb128 0x14
	.string	"i"
	.byte	0x1
	.value	0x170
	.long	0x5c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.uleb128 0x1b
	.long	.LBB5
	.long	.LBE5-.LBB5
	.long	0xc5d
	.uleb128 0x14
	.string	"ptr"
	.byte	0x1
	.value	0x1aa
	.long	0xca5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -36
	.byte	0
	.uleb128 0x16
	.long	.LBB6
	.long	.LBE6-.LBB6
	.uleb128 0x13
	.long	.LASF119
	.byte	0x1
	.value	0x1cc
	.long	0x63
	.uleb128 0x2
	.byte	0x91
	.sleb128 -40
	.uleb128 0x16
	.long	.LBB7
	.long	.LBE7-.LBB7
	.uleb128 0x14
	.string	"ptr"
	.byte	0x1
	.value	0x1d7
	.long	0xca5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -44
	.byte	0
	.byte	0
	.byte	0
	.uleb128 0x8
	.long	0x2c
	.long	0xca0
	.uleb128 0x9
	.long	0x6e
	.byte	0xb
	.byte	0
	.uleb128 0x3
	.long	0xc90
	.uleb128 0xc
	.byte	0x4
	.long	0x51
	.uleb128 0x12
	.long	.LASF120
	.byte	0x1
	.value	0x13d
	.long	.LFB41
	.long	.LFE41-.LFB41
	.uleb128 0x1
	.byte	0x9c
	.long	0xcef
	.uleb128 0x15
	.string	"stk"
	.byte	0x1
	.value	0x13d
	.long	0x12e
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x17
	.long	.LASF121
	.byte	0x1
	.value	0x13d
	.long	0x63
	.uleb128 0x2
	.byte	0x91
	.sleb128 4
	.uleb128 0x18
	.long	.LASF101
	.long	0x89d
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1462
	.byte	0
	.uleb128 0x19
	.long	.LASF122
	.byte	0x1
	.value	0x11e
	.long	0x12e
	.long	.LFB40
	.long	.LFE40-.LFB40
	.uleb128 0x1
	.byte	0x9c
	.long	0xd28
	.uleb128 0x17
	.long	.LASF121
	.byte	0x1
	.value	0x11e
	.long	0x63
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x14
	.string	"ptr"
	.byte	0x1
	.value	0x129
	.long	0x12e
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.uleb128 0x12
	.long	.LASF123
	.byte	0x1
	.value	0x103
	.long	.LFB39
	.long	.LFE39-.LFB39
	.uleb128 0x1
	.byte	0x9c
	.long	0xd76
	.uleb128 0x15
	.string	"pcb"
	.byte	0x1
	.value	0x103
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x18
	.long	.LASF101
	.long	0x81a
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1453
	.uleb128 0x16
	.long	.LBB3
	.long	.LBE3-.LBB3
	.uleb128 0x13
	.long	.LASF99
	.byte	0x1
	.value	0x10a
	.long	0x5c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.byte	0
	.uleb128 0x1c
	.long	.LASF124
	.byte	0x1
	.byte	0xed
	.long	0x5c
	.long	.LFB38
	.long	.LFE38-.LFB38
	.uleb128 0x1
	.byte	0x9c
	.long	0xdbb
	.uleb128 0x1d
	.string	"pcb"
	.byte	0x1
	.byte	0xed
	.long	0x974
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x18
	.long	.LASF101
	.long	0xdcb
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1447
	.uleb128 0x1e
	.string	"tmp"
	.byte	0x1
	.byte	0xf3
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.uleb128 0x8
	.long	0x2c
	.long	0xdcb
	.uleb128 0x9
	.long	0x6e
	.byte	0x9
	.byte	0
	.uleb128 0x3
	.long	0xdbb
	.uleb128 0x1f
	.long	.LASF125
	.byte	0x1
	.byte	0xc4
	.long	.LFB37
	.long	.LFE37-.LFB37
	.uleb128 0x1
	.byte	0x9c
	.long	0xe19
	.uleb128 0x18
	.long	.LASF101
	.long	0x81a
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1438
	.uleb128 0x1e
	.string	"ptr"
	.byte	0x1
	.byte	0xdd
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x16
	.long	.LBB2
	.long	.LBE2-.LBB2
	.uleb128 0x1e
	.string	"i"
	.byte	0x1
	.byte	0xde
	.long	0x5c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.uleb128 0x20
	.long	.LASF126
	.byte	0x1
	.byte	0xa3
	.long	0x418
	.long	.LFB36
	.long	.LFE36-.LFB36
	.uleb128 0x1
	.byte	0x9c
	.long	0xe7a
	.uleb128 0x21
	.long	.LASF93
	.byte	0x1
	.byte	0xa3
	.long	0x354
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x1d
	.string	"pcb"
	.byte	0x1
	.byte	0xa3
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 4
	.uleb128 0x18
	.long	.LASF101
	.long	0xb3e
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1429
	.uleb128 0x10
	.long	.LASF104
	.byte	0x1
	.byte	0xa9
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x10
	.long	.LASF105
	.byte	0x1
	.byte	0xaa
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.uleb128 0x20
	.long	.LASF127
	.byte	0x1
	.byte	0x92
	.long	0x418
	.long	.LFB35
	.long	.LFE35-.LFB35
	.uleb128 0x1
	.byte	0x9c
	.long	0xedb
	.uleb128 0x21
	.long	.LASF93
	.byte	0x1
	.byte	0x92
	.long	0x354
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x1d
	.string	"pcb"
	.byte	0x1
	.byte	0x92
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 4
	.uleb128 0x18
	.long	.LASF101
	.long	0xeeb
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1419
	.uleb128 0x10
	.long	.LASF104
	.byte	0x1
	.byte	0x98
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x10
	.long	.LASF105
	.byte	0x1
	.byte	0x99
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.uleb128 0x8
	.long	0x2c
	.long	0xeeb
	.uleb128 0x9
	.long	0x6e
	.byte	0x12
	.byte	0
	.uleb128 0x3
	.long	0xedb
	.uleb128 0x22
	.long	.LASF131
	.byte	0x1
	.byte	0x81
	.long	0x418
	.long	.LFB34
	.long	.LFE34-.LFB34
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x21
	.long	.LASF93
	.byte	0x1
	.byte	0x81
	.long	0x354
	.uleb128 0x2
	.byte	0x91
	.sleb128 0
	.uleb128 0x1d
	.string	"pcb"
	.byte	0x1
	.byte	0x81
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 4
	.uleb128 0x18
	.long	.LASF101
	.long	0x98a
	.uleb128 0x5
	.byte	0x3
	.long	__func__.1409
	.uleb128 0x10
	.long	.LASF104
	.byte	0x1
	.byte	0x87
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x10
	.long	.LASF105
	.byte	0x1
	.byte	0x88
	.long	0x418
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.section	.debug_abbrev,"",@progbits
.Ldebug_abbrev0:
	.uleb128 0x1
	.uleb128 0x11
	.byte	0x1
	.uleb128 0x25
	.uleb128 0xe
	.uleb128 0x13
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x1b
	.uleb128 0xe
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x10
	.uleb128 0x17
	.byte	0
	.byte	0
	.uleb128 0x2
	.uleb128 0x24
	.byte	0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0xe
	.byte	0
	.byte	0
	.uleb128 0x3
	.uleb128 0x26
	.byte	0
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x4
	.uleb128 0x16
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x5
	.uleb128 0x24
	.byte	0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0x8
	.byte	0
	.byte	0
	.uleb128 0x6
	.uleb128 0x4
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x7
	.uleb128 0x28
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x1c
	.uleb128 0xb
	.byte	0
	.byte	0
	.uleb128 0x8
	.uleb128 0x1
	.byte	0x1
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x9
	.uleb128 0x21
	.byte	0
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2f
	.uleb128 0xb
	.byte	0
	.byte	0
	.uleb128 0xa
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3c
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0xb
	.uleb128 0x21
	.byte	0
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2f
	.uleb128 0x5
	.byte	0
	.byte	0
	.uleb128 0xc
	.uleb128 0xf
	.byte	0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0xd
	.uleb128 0x13
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0xe
	.uleb128 0xd
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x38
	.uleb128 0xb
	.byte	0
	.byte	0
	.uleb128 0xf
	.uleb128 0xd
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x38
	.uleb128 0xb
	.byte	0
	.byte	0
	.uleb128 0x10
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x11
	.uleb128 0x34
	.byte	0
	.uleb128 0x47
	.uleb128 0x13
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x12
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x2116
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x13
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x14
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x15
	.uleb128 0x5
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x16
	.uleb128 0xb
	.byte	0x1
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.byte	0
	.byte	0
	.uleb128 0x17
	.uleb128 0x5
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x18
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x34
	.uleb128 0x19
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x19
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x2116
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x1a
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x2117
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x1b
	.uleb128 0xb
	.byte	0x1
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x1c
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x2116
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x1d
	.uleb128 0x5
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x1e
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x1f
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x2116
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x20
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x2116
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x21
	.uleb128 0x5
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x22
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x2116
	.uleb128 0x19
	.byte	0
	.byte	0
	.byte	0
	.section	.debug_aranges,"",@progbits
	.long	0x1c
	.value	0x2
	.long	.Ldebug_info0
	.byte	0x4
	.byte	0
	.value	0
	.value	0
	.long	.Ltext0
	.long	.Letext0-.Ltext0
	.long	0
	.long	0
	.section	.debug_line,"",@progbits
.Ldebug_line0:
	.section	.debug_str,"MS",@progbits,1
.LASF52:
	.string	"ticks"
.LASF124:
	.string	"pcb_alloc"
.LASF116:
	.string	"victim"
.LASF106:
	.string	"pcb_queue_remove"
.LASF109:
	.string	"pcb_queue_empty"
.LASF97:
	.string	"ctx_dump"
.LASF32:
	.string	"STATE_ZOMBIE"
.LASF49:
	.string	"exit_status"
.LASF50:
	.string	"state"
.LASF119:
	.string	"target"
.LASF104:
	.string	"prev"
.LASF2:
	.string	"short int"
.LASF86:
	.string	"nstate"
.LASF118:
	.string	"vicpid"
.LASF40:
	.string	"eflags"
.LASF15:
	.string	"PRIO_LOW"
.LASF41:
	.string	"context_t"
.LASF87:
	.string	"unknown"
.LASF96:
	.string	"ctx_dump_all"
.LASF29:
	.string	"STATE_BLOCKED"
.LASF131:
	.string	"find_prev_wakeup"
.LASF42:
	.string	"context_s"
.LASF110:
	.string	"pcb_queue_reset"
.LASF84:
	.string	"zombie_queue"
.LASF111:
	.string	"style"
.LASF77:
	.string	"state_str"
.LASF103:
	.string	"pcb_queue_remove_this"
.LASF92:
	.string	"pcb_queue_dump"
.LASF108:
	.string	"pcb_queue_length"
.LASF91:
	.string	"empty"
.LASF37:
	.string	"QUANTUM_LONG"
.LASF19:
	.string	"b512"
.LASF94:
	.string	"contents"
.LASF58:
	.string	"head"
.LASF100:
	.string	"schedule"
.LASF4:
	.string	"uint8_t"
.LASF78:
	.string	"prio_str"
.LASF71:
	.string	"zombie"
.LASF47:
	.string	"parent"
.LASF38:
	.string	"vector"
.LASF23:
	.string	"state_e"
.LASF74:
	.string	"ptable"
.LASF43:
	.string	"pcb_s"
.LASF72:
	.string	"sioread"
.LASF55:
	.string	"pcb_t"
.LASF24:
	.string	"STATE_UNUSED"
.LASF62:
	.string	"O_FIFO"
.LASF8:
	.string	"long long int"
.LASF128:
	.string	"GNU C99 7.5.0 -m32 -mtune=generic -march=i686 -ggdb -std=c99 -fno-pie -fno-stack-protector -fno-builtin"
.LASF60:
	.string	"order"
.LASF115:
	.string	"pcb_zombify"
.LASF76:
	.string	"init_pcb"
.LASF79:
	.string	"ord_str"
.LASF93:
	.string	"queue"
.LASF129:
	.string	"procs.c"
.LASF21:
	.string	"kernel_esp"
.LASF67:
	.string	"pcb_freelist"
.LASF120:
	.string	"pcb_stack_free"
.LASF59:
	.string	"tail"
.LASF1:
	.string	"unsigned char"
.LASF112:
	.string	"pcb_find_ppid"
.LASF125:
	.string	"pcb_init"
.LASF13:
	.string	"PRIO_HIGH"
.LASF126:
	.string	"find_prev_pid"
.LASF65:
	.string	"O_WAKEUP"
.LASF9:
	.string	"long long unsigned int"
.LASF61:
	.string	"pcb_queue_order_e"
.LASF6:
	.string	"uint32_t"
.LASF28:
	.string	"STATE_SLEEPING"
.LASF7:
	.string	"unsigned int"
.LASF98:
	.string	"dispatch"
.LASF45:
	.string	"stack"
.LASF14:
	.string	"PRIO_STD"
.LASF31:
	.string	"STATE_KILLED"
.LASF39:
	.string	"code"
.LASF73:
	.string	"current"
.LASF101:
	.string	"__func__"
.LASF20:
	.string	"kstack"
.LASF3:
	.string	"short unsigned int"
.LASF26:
	.string	"STATE_READY"
.LASF99:
	.string	"status"
.LASF30:
	.string	"STATE_WAITING"
.LASF57:
	.string	"pcb_queue_s"
.LASF18:
	.string	"b256"
.LASF0:
	.string	"char"
.LASF63:
	.string	"O_PRIO"
.LASF66:
	.string	"N_ORDERINGS"
.LASF68:
	.string	"ready"
.LASF5:
	.string	"int32_t"
.LASF12:
	.string	"bool_t"
.LASF70:
	.string	"sleeping"
.LASF51:
	.string	"priority"
.LASF36:
	.string	"QUANTUM_STANDARD"
.LASF80:
	.string	"pcb_freelist_queue"
.LASF123:
	.string	"pcb_free"
.LASF25:
	.string	"STATE_NEW"
.LASF113:
	.string	"pcb_find_pid"
.LASF75:
	.string	"next_pid"
.LASF48:
	.string	"wakeup"
.LASF44:
	.string	"context"
.LASF114:
	.string	"pcb_cleanup"
.LASF130:
	.string	"/home/fac/wrc/cl/452/pub/old2"
.LASF11:
	.string	"long unsigned int"
.LASF127:
	.string	"find_prev_priority"
.LASF117:
	.string	"zchild"
.LASF83:
	.string	"sleeping_queue"
.LASF33:
	.string	"N_STATES"
.LASF121:
	.string	"size"
.LASF53:
	.string	"stkpgs"
.LASF95:
	.string	"pcb_dump"
.LASF89:
	.string	"ptable_dump"
.LASF54:
	.string	"filler"
.LASF82:
	.string	"waiting_queue"
.LASF90:
	.string	"used"
.LASF64:
	.string	"O_PID"
.LASF16:
	.string	"PRIO_DEFERRED"
.LASF10:
	.string	"uint_t"
.LASF27:
	.string	"STATE_RUNNING"
.LASF34:
	.string	"quantum_e"
.LASF69:
	.string	"waiting"
.LASF88:
	.string	"ptable_dump_counts"
.LASF35:
	.string	"QUANTUM_SHORT"
.LASF85:
	.string	"sioread_queue"
.LASF81:
	.string	"ready_queue"
.LASF122:
	.string	"pcb_stack_alloc"
.LASF107:
	.string	"pcb_queue_insert"
.LASF56:
	.string	"pcb_queue_t"
.LASF17:
	.string	"N_PRIOS"
.LASF46:
	.string	"next"
.LASF22:
	.string	"priority_e"
.LASF105:
	.string	"curr"
.LASF102:
	.string	"pcb_queue_peek"
	.ident	"GCC: (Ubuntu 7.5.0-3ubuntu1~18.04) 7.5.0"
	.section	.note.GNU-stack,"",@progbits
