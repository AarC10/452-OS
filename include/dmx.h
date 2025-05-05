/**
** @file	dmx.h
**
** @author	John Arrandale
**
** @brief	DMX definitions
*/

#ifndef DMX_H_
#define DMX_H_

// compatibility definitions
#include <compat.h>

#include <x86/uart.h>

#ifndef ASM_SRC

/*
** Start of C-only definitions
*/

#define DMX_PORT1 UA4_PORT2

#define DMX_SLOTS 32 // Normally 512 for 512 channels
#define DMX_FRAME_SIZE (DMX_FRAME_DATA_SIZE + 2) // Normally +3 bits (x1 start bit, x2 stop bits)
// Adjusted to +2 based on 115.2 kbaud (receiver is using 250 kbaud)
#define DMX_FRAME_DATA_SIZE (sizeof(uint8_t) * 8 / 2 - 1) // Normally 8 bits
// Adjusted to half (4 bits) based on 1 bit at 115.2 kbaud = 2 bits at 250 kbaud
// 1 subtracted due to assumed 0 from "double" start bit and an extra 1 from "double" stop bits 

/**
** dmx_write(port,data)
**
** Wraps the given DMX slot data into DMX frames and writes the
** DMX packet to the given serial port
**
** usage:    sio_dmx( uint_t port, uint8_t data[DMX_SLOTS] )
**
** @param port	The serial port to write out of
** @param data	An array of DMX slot data
*/
void dmx_write(uint_t port, uint8_t data[DMX_SLOTS]);

#endif
#endif