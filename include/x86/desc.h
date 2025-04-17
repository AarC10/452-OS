/*
** @file    desc.h
**
** @author  Warren R. Carithers
** @author	K. Reek
**
** Definitions of constants, macros, and types for memory and
** interrupt descriptors for the x86 architecture.
**
*/

#ifndef X86DESC_H_
#define X86DESC_H_

/*
** Descriptors
**
** These are all eight bytes in length, with fields laid out
** as follows:
**
**      Segment Desc.                   Interrupt Desc.
**   ----------------------          ----------------------
**   | Limit 15-0         |  byte 0  | Offset 15-0        |
**   |                    |  byte 1  |                    |
**   ----------------------          ----------------------
**   | Base 15-0          |  byte 2  | segment selector   |
**   |                    |  byte 3  |                    |
**   ----------------------          ----------------------
**   | Base 23-16         |  byte 4  | RSVD, MBZ          |
**   ----------------------          ----------------------
**   | Type, DPL, P       |  byte 5  | Type, DPL, P       |
**   ----------------------          ----------------------
**   | Limit 19-16, AVL,  |  byte 6  | Offset 31-16       |
**   | L, D/B, G          |          |                    |
**   ----------------------          |                    |
**   | Base 31-24         |  byte 7  |                    |
**   ----------------------          ----------------------
*/

#ifndef ASM_SRC

/*
** C-only type specifications
*/

// generic descriptor layout
typedef struct desc_s {
	uint16_t bytes_0_1;
	uint16_t bytes_2_3;
	uint16_t bytes_4_5;
	uint16_t bytes_6_7;
} desc_t;

// segment descriptor layout
// Intel SDM Vol 3A page 3-10 (Edition 079US, March 2023)
typedef struct sdesc_s {
	uint16_t limit_15_0;   // lower 16 bits of segment limit
	uint16_t base_15_0;    // lower 16 bits of segment base address
	uint8_t  base_23_16;   // third byte of segment base address
	uint8_t  flags;        // type, s, dpl, and p fields
	uint8_t  flags2;       // upper 4 bits of limit, L, D/B, and G fields
	uint8_t  base_31_24;   // uppber byte of segment base address
} segd_t;

// interrupt descriptor
// Intel SDM Vol 3A page 6-11 (Edition 079US, March 2023)
typedef struct idesc_s {
	uint16_t offset_15_0;  // lower 16 bits of ISR offset
	uint16_t selector;     // segment selector for CS
	uint8_t  zero;         // reserved (bits 4-0) and MBZ (bits 7-5)
	uint8_t  flags;        // type, s, dpl, and p fields
	uint16_t offset_31_16; // upper 16 bits of ISR offset
} intd_t;

/*
** Byte 5:    access control bits
**    7:    present
**    6-5:  DPL
**    4:    system/user
**    3-0:  type
*/
struct dfl_s {
	uint_t   type  :4;
	uint_t   s     :1;
	uint_t   dpl   :2;
	uint_t   p     :1;
};

typedef union dfl_u {
	uint8_t data;
	struct dfl_s bits;
} dflags_t;

/*
** Byte 6:    sizes
**    7:    granularity
**    6:    d/b
**    5:    long mode
**    4:    available!
**    3-0:  upper 4 bits of limit
*/
struct dfl2_s {
	uint_t   limit_19_16 :4;
	uint_t   avl         :1;
	uint_t   l           :1;
	uint_t   db          :1;
	uint_t   g           :1;
};

typedef union dfl2_u {
	uint8_t data;
	struct dfl2_s bits;
} dflags2_t;

#endif  /* !ASM_SRC */

/*******************************
** Memory management
*******************************/

/*
** CPP macros defining field contents, etc.
**
** Commented-out declarations are duplicates of ones
** also defined in <x86/arch.h>
*/

/*
** Segment field flags
*/

// fields in byte 5
#define SEG_PRESENT_MASK        0x80
// #   define SEG_PRESENT          0x80
// #   define SEG_NOT_PRESENT      0x00

#define SEG_DPL_MASK            0x60
// #   define SEG_DPL_0            0x00
// #   define SEG_DPL_1            0x20
// #   define SEG_DPL_2            0x40
// #   define SEG_DPL_3            0x60

#define SEG_S_MASK              0x10
// #	define SEG_SYSTEM           0x10
#	define SEG_CODE_DATA        0x00

#define SEG_GATE_TYPE_MASK      0x0f
#   define SEG_T0               0x00
#   define SEG_T1               0x01
#   define SEG_T2               0x02
#   define SEG_T3               0x03
#   define SEG_T4               0x04
#   define SEG_T5               0x05
#   define SEG_T6               0x06
#   define SEG_T7               0x07
#   define SEG_T8               0x08
#   define SEG_T9               0x09
#   define SEG_TA               0x0a
#   define SEG_TB               0x0b
#   define SEG_TC               0x0c
#   define SEG_TD               0x0d
#   define SEG_TE               0x0e
#   define SEG_TF               0x0f

/*
** Segment descriptor types (S == 0)
**
** Types 0, 8, 10, and 13 are reserved
*/
#define	SEG_TYPE_TSS16_AVL      SEG_T1
#define	SEG_TYPE_LDT            SEG_T2
#define	SEG_TYPE_TSS16_BSY      SEG_T3
#define	SEG_TYPE_CALL16         SEG_T4
#define	SEG_TYPE_TASK           SEG_T5
#define	SEG_TYPE_INT16          SEG_T6
#define	SEG_TYPE_TRAP16         SEG_T7
#define	SEG_TYPE_TSS32_AVL      SEG_T9
#define	SEG_TYPE_TSS32_BSY      SEG_TB
#define	SEG_TYPE_CALL32         SEG_TC
#define	SEG_TYPE_INT32          SEG_TE
#define	SEG_TYPE_TRAP32         SEG_TF

/*
** Segment descriptor types (S == 1)
*/
#define	SEG_TYPE_DATA_RO        SEG_T0
#define	SEG_TYPE_DATA_RO_A      SEG_T1
#define	SEG_TYPE_DATA_RW        SEG_T2
#define	SEG_TYPE_DATA_RW_A      SEG_T3
#define	SEG_TYPE_DATA_RO_XD     SEG_T4
#define	SEG_TYPE_DATA_RO_XD_A   SEG_T5
#define	SEG_TYPE_DATA_RW_XD     SEG_T6
#define	SEG_TYPE_DATA_RW_XD_A   SEG_T7

// #define	SEG_DATA_E_BIT          0x04
#	define SEG_EXPAND_UP        0x00
#	define SEG_EXPAND_DN        0x04
// #define	SEG_DATA_W_BIT          0x02
#	define SEG_NOT_WRITABLE     0x00
#	define SEG_WRITABLE         0x02
// #define	SEG_DATA_A_BIT          0x01
#	define SEG_NOT_ACCESSED     0x00
#	define SEG_ACCESSED         0x01

#define	SEG_TYPE_CODE_XO        SEG_T8
#define	SEG_TYPE_CODE_XO_A      SEG_T9
#define	SEG_TYPE_CODE_XR        SEG_TA
#define	SEG_TYPE_CODE_XR_A      SEG_TB
#define	SEG_TYPE_CODE_XO_C      SEG_TC
#define	SEG_TYPE_CODE_XO_C_A    SEG_TD
#define	SEG_TYPE_CODE_XR_C      SEG_TE
#define	SEG_TYPE_CODE_XR_C_A    SEG_TF

// #define	SEG_CODE_C_BIT          0x04
#	define SEG_NOT_CONFORMING   0x00
#	define SEG_CONFORMING       0x04
// #define	SEG_CODE_R_BIT          0x02
#	define SEG_NOT_READABLE     0x00
#	define SEG_READABLE         0x02
// #define	SEG_CODE_A_BIT          0x01

// fields in byte 6
#define SEG_AVL_MASK            0x10

#define SEG_L_MASK              0x20
	// protected mode, ia-32e compatability mode
#	define SEG_MODE_32          0x00
	// ia-32e long mode
#	define SEG_MODE_64          0x20

#define SEG_DB_MASK             0x40
	// executable code segments
#	define SEG_D_16             0x00
#	define SEG_D_32             0x40
	// stack segments
#	define SEG_B_16             0x00
#	define SEG_B_32             0x40
	// expand-down data segments
#	define SEG_B_4MB_LIM        0x00
#	define SEG_B_4GB_LIM        0x40

#define SEG_G_MASK              0x80
#	define SEG_G_BYTE_LIM       0x00
#	define SEG_G_4KB_LIM        0x80

/*
** Segment segment selector field masks
**
** Intel SDM Vol 3A page 3-7 (Edition 079US, March 2023)
*/
// #define SEG_SEL_IX_MASK         0xfff8
#	define SEG_SEL_IX_SHIFT     3

// #define SEG_SEL_TI_MASK         0x0004
#	define SEG_SEL_GDT          0x0000
#	define SEG_SEL_LDT          0x0004

// #define SEG_SEL_RPL_MASK        0x0003

#endif
