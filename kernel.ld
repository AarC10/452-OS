/*
** Simple linker script for the 20245 kernel.
*/

OUTPUT_FORMAT("elf32-i386", "elf32-i386", "elf32-i386")
OUTPUT_ARCH(i386)
ENTRY(_start)

SECTIONS
{
	/* Link the kernel at this address. */
        /* Must match what is defined in vm.h! */
	. = 0x00010000;

	.text : AT(0x10000) {
		*(.text .stub .text.* .gnu.linkonce.t.*)
	}

	/* standard symbols */
	PROVIDE(etext = .);
	PROVIDE(_etext = .);

	/* put read-only data next */
	.rodata : {
		*(.rodata .rodata.* .gnu.linkonce.r.*)
	}

	/* Put STABs here */
	/*
	.stab : { 
		PROVIDE(__STAB_BEGIN__ = .);
		*(.stab);
		PROVIDE(__STAB_END__ = .);
	}
	.stabstr : {
		PROVIDE(__STABSTR_BEGIN__ = .);
		*(.stabstr);
		PROVIDE(__STABSTR_END__ = .);
	}
		*/

	/* Align the data segment at the next page boundary */
	. = ALIGN(0x1000);

	PROVIDE(data = .);
	PROVIDE(_data = .);
	PROVIDE(__data_start = .);

	/* The data segment */
	.data : {
		*(.data .data.*)
	}

	PROVIDE(edata = .);
	PROVIDE(_edata = .);
	PROVIDE(__data_end = .);

	/* page-align the BSS */
	. = ALIGN(0x1000);

	PROVIDE(__bss_start = .);

	.bss : {
		*(.bss .bss.*)
		*(COMMON)
	}

	PROVIDE(end = .);
	PROVIDE(_end = .);

	/DISCARD/ : {
		*(.stab .stab_info .stabstr)
		*(.eh_frame .eh_frame_hdr)
		*(.note.GNU-stack .note.gnu.property .comment)
	}
}
