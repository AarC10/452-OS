/**
** @file	elf.h
**
** @author	Warren R. Carithers
**
** @brief	ELF format declarations
*/

#ifndef ELF_H_
#define ELF_H_

#include <common.h>

#ifndef ASM_SRC

/*
** Start of C-only definitions
*/

// ELF data types (TIS ELF Spec v1.2, May 1995
typedef uint32_t e32_a;    // 32-bit unsigned address
typedef uint16_t e32_h;    // 16-bit unsigned "medium" integer
typedef uint32_t e32_o;    // 32-bit unsigned offset
typedef int32_t  e32_sw;   // 32-bit signed "large" integer
typedef uint32_t e32_w;    // 32-bit unsigned "large" integer
typedef uint8_t  e32_si;   // 8-bit unsigned "small" integer

// ELF magic number - first four bytes
#define ELF_MAGIC    0x464C457FU    // "\x7FELF" in little-endian order
#define	EI_NIDENT    16

union elfident_u {
	uint8_t bytes[EI_NIDENT];  // array of 16 bytes
	struct {
		uint32_t magic;        // magic number
		uint8_t  class;        // file class
		uint8_t  data;         // data encoding
		uint8_t  version;      // file version
		uint8_t  pad[9];       // padding to 16 bytes
	} f;
};

// indices for byte fields in the ident array
#define EI_MAGIC          0
#	define EI_MAG0        EI_MAGIC
#	define EI_MAG1        1
#	define EI_MAG2        2
#	define EI_MAG3        3
#define EI_CLASS          4
#define EI_DATA           5
#define EI_VERSION        6

// ELF classes
#define ELF_CLASS_NONE    0
#define ELF_CLASS_32      1   // 32-bit objects
#define ELF_CLASS_64      2   // 64-bit objects

// ELF data encoding
#define ELF_DATA_NONE     0   // invalid data encoding
#define ELF_DATA_2LSB     1   // two's complement little-endian
#define ELF_DATA_2MSB     2   // two's complement big-endian

// ELF versions
#define ELF_VERSION__NONE     0   // invalid version
#	define EV_NONE            ELF_VERSION_NONE
#define ELF_VERSION__CURRENT  1   // current version
#	define EV_CURRENT         ELF_VERSION_CURRENT

// ELF header
//
// field names are from the TIS ELF Spec v1.2, May 1995
typedef struct elfhdr_s {
	union elfident_u e_ident;  // file identification
	e32_h e_type;              // file type
	e32_h e_machine;           // required architecture
	e32_w e_version;           // object file version
	e32_a e_entry;             // entry point (VA)
	e32_o e_phoff;             // offset to program header table (PHT)
	e32_o e_shoff;             // offset to section header table (SHT)
	e32_w e_flags;             // processor-specific flags
	e32_h e_ehsize;            // ELF header size (bytes)
	e32_h e_phentsize;         // size of one PHT entry (bytes)
	e32_h e_phnum;             // number of PHT entries
	e32_h e_shentsize;         // size of one SHT entry (bytes)
	e32_h e_shnum;             // number of SHT entries
	e32_h e_shstrndx;          // SHT index of the sect. name string table
} elfhdr_t;

#define SZ_ELFHDR   sizeof(elfhdr_t)

// field values
// e_type
#define ET_NONE     0        // no file type
#define ET_REL      1        // relocatable file
#define ET_EXEC     2        // executable file
#define ET_DYN      3        // shared object file
#define ET_CORE     4        // core file
#define ET_LOPROC   0xff00   // processor-specific
#define ET_HIPROC   0xffff   // processor-specific

// e_machine
#define EM_NONE          0   // no machine type
#define EM_M32           1   // AT&T WE 32100
#define EM_SPARC         2   // SPARC
#define EM_386           3   // Intel Architecture
#define EM_68K           4   // Motorola 68000
#define EM_88K           5   // Motorola 88000
#define EM_UNU6          6   // Unassigned
#define EM_860           7   // Intel 80860
#define EM_MIPS          8   // MIPS RS3000 Big-Endian
#define EM_UNU9          9   // Unassigned
#define EM_MIPS_RS4_BE   10  // MIPS RS4000 Big-Endian
#define EM_RSV11         11  // Reserved
#define EM_RSV12         10  // Reserved
#define EM_RSV13         10  // Reserved
#define EM_RSV14         10  // Reserved
#define EM_RSV15         10  // Reserved
#define EM_RSV16         10  // Reserved

// ELF section header
//
// field names are from the TIS ELF Spec v1.2, May 1995
typedef struct shdr_s {
	e32_w sh_name;         // section name (index into string table)
	e32_w sh_type;         // section contents/semantics
	e32_w sh_flags;        // attribute flag bits
	e32_a sh_addr;         // 0, or load point of this section in memory
	e32_o sh_offset;       // byte offset within the file
	e32_w sh_size;         // section size in bytes
	e32_w sh_link;         // section header index table link
	e32_w sh_info;         // "extra information"
	e32_w sh_addralign;    // required alignment
	e32_w sh_entsize;      // 0, or size of each entry in the section
} elfsecthdr_t;

#define SZ_ELFSECTHDR   sizeof(elfsecthdr_t)

// sh_name
#define SHN_UNDEF       0

// sh_type
#define SHT_NULL        0
#define SHT_PROGBITS    1
#define SHT_SYMTAB      2
#define SHT_STRTAB      3
#define SHT_RELA        4
#define SHT_HASH        5
#define SHT_DYNAMIC     6
#define SHT_NOTE        7
#define SHT_NOBITS      8
#define SHT_REL         9
#define SHT_SHLIB       10
#define SHT_DYNSYM      11
#define SHT_LOPROC      0x70000000
#define SHT_HIPROC      0x7fffffff
#define SHT_LOUSER      0x80000000
#define SHT_HIUSER      0x8fffffff

// sh_flags
#define SHF_WRITE      0x1
#define SHF_ALLOC      0x2
#define SHF_EXECINSTR  0x4
#define SHF_MASKPROC   0xf0000000

// ELF program header
//
// field names are from the TIS ELF Spec v1.2, May 1995
typedef struct phdr_s {
	e32_w p_type;        // type of segment
	e32_o p_offset;      // byte offset in file
	e32_a p_va;          // load point in memory (virtual address)
	e32_a p_pa;          // load point in memory (physical address)
	e32_w p_filesz;      // number of bytes in this file
	e32_w p_memsz;       // number of bytes in memory
	e32_w p_flags;       // attribute flag bits
	e32_w p_align;       // required alignment
} elfproghdr_t;

#define SZ_ELFPROGHDR   sizeof(elfproghdr_t)

// p_type
#define PT_NULL        0
#define PT_LOAD        1
#define PT_DYNAMIC     2
#define PT_INTERP      3
#define PT_NOTE        4
#define PT_SHLIB       5
#define PT_PHDR        6
#define PT_TLS         7
#define PT_LOPROC      0x70000000
#define PT_HIPROC      0x7fffffff

// p_flags
#define PF_E           0x1
#define PF_W           0x2
#define PF_R           0x4
#define PF_MASKPROC    0xf0000000

/*
** Globals
*/

/*
** Prototypes
*/

#endif  /* !ASM_SRC */

#endif
