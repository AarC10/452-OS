/*
** @file	vga.h
**
** @author	M. Reek
** @authors	K. Reek, Warren R. Carithers
**
** Basic definitions for VGA video.
*/

#ifndef VGA_H
#define	VGA_H

/*
** Video parameters
*/
#define	SCREEN_MIN_X    0
#define	SCREEN_MIN_Y    0
#define	SCREEN_X_SIZE   80
#define	SCREEN_Y_SIZE   25
#define	SCREEN_MAX_X    ( SCREEN_X_SIZE - 1 )
#define	SCREEN_MAX_Y    ( SCREEN_Y_SIZE - 1 )

/*
** VGA definitions
*/

// calculate the memory address of a specific character position
// within VGA memory
#define VIDEO_ADDR(x,y) ( unsigned short * ) \
	( ( VID_BASE_ADDR + 2 * ( (y) * SCREEN_X_SIZE + (x) ) ) )

// port addresses
#define	VGA_CTRL_IX_ADDR    0x3d4
#define	VGA_CTRL_IX_DATA    0x3d5

// cursor location commands
#define	VGA_CTRL_CUR_HIGH   0x0e	// cursor location, high byte
#define	VGA_CTRL_CUR_LOW    0x0f	// cursor location, low byte

// attribute bits
#define	VGA_ATT_BBI     0x80	// blink, or background intensity
#define	VGA_ATT_BGC     0x70	// background color
#define	VGA_ATT_FICS    0x80	// foreground intensity or char font select
#define	VGA_ATT_FGC     0x70	// foreground color

// color selections
#define	VGA_BG_BLACK    0x0000	// background colors
#define	VGA_BG_BLUE     0x1000
#define	VGA_BG_GREEN    0x2000
#define	VGA_BG_CYAN     0x3000
#define	VGA_BG_RED      0x4000
#define	VGA_BG_MAGENTA  0x5000
#define	VGA_BG_BROWN    0x6000
#define	VGA_BG_WHITE    0x7000

#define	VGA_FG_BLACK    0x0000	// foreground colors
#define	VGA_FG_BLUE     0x0100
#define	VGA_FG_GREEN    0x0200
#define	VGA_FG_CYAN     0x0300
#define	VGA_FG_RED      0x0400
#define	VGA_FG_MAGENTA  0x0500
#define	VGA_FG_BROWN    0x0600
#define	VGA_FG_WHITE    0x0700

// color combinations
#define	VGA_WHITE_ON_BLACK  (VGA_FG_WHITE | VGA_BG_BLACK)
#define	VGA_BLACK_ON_WHITE  (VGA_FG_BLACK | VGA_BG_WHITE)

#endif	/* vga.h */
