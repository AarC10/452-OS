/**
** @file	dmx.c
**
** @author	John Arrandale
**
** @brief	DMX driver
*/

#define KERNEL_SRC

// this should do all includes required for this OS
#include <compat.h>

// all other framework includes are next
#include <x86/uart.h>
#include <x86/arch.h>
#include <x86/pic.h>

#include <dmx.h>
#include <lib.h>

#ifdef CIO_DUP2_SIO
#include <cio.h>
#endif

/**
** dmx_write(port,data)
**
** Wraps the given DMX slot data into DMX frames and writes the
** DMX packet to the given serial port
**
** usage:    dmx_write( uint_t port, uint8_t data[DMX_SLOTS] )
**
** @param port	The serial port to write out of
** @param data	An array of DMX slot data
*/
void dmx_write( uint_t port, uint8_t data[DMX_SLOTS] ) {
	/*
	Implementation/Standard Notes:
		- At 115.2 kbaud, each bit is ~8.4usec (DMX standard is 4usec)
		- Bits go from LSB to MSB (0b100 shows up as 0b001)
		- Start procedure: "SPACE" for BREAK, "MARK" after BREAK, START Code
		- Assume 1 bit (at 115.2 kbaud) is recieved by the end device as 
		  2 bits (aka reading at 250 kbaud)
	*/

	char start_code[] = "1100001";
	/*
		11 0000 1
				^->Stop bits (x2 HIGH bits)
		    ^->START Code (all 0s)
		^->"MARK" after BREAK (>8usec)
	*/

	int offset = sizeof(start_code) / sizeof(start_code[0]);

	// Builds an array of complete DMX frames
	uint8_t bits[DMX_SLOTS * DMX_FRAME_SIZE + offset];

	// Build start code frame
	for (int i = 0; i < offset; i++) {
		bits[i] = start_code[i] == '1' ? 1 : 0;
	}

	// Build data frames
	for (int i = 0; i < DMX_SLOTS; i++) {
		int base = offset + i * DMX_FRAME_SIZE + 1;

		bits[base - 1] = 0; // Start bit
		
		// Data bits
		for (int bit = 0; bit < DMX_FRAME_DATA_SIZE; bit++) {
			bits[base + bit] = (data[i] & (1 << bit)) >> bit;
		}

		// Stop bits
		for (int j = 0; j < 2; j++) {
			bits[base + DMX_FRAME_DATA_SIZE + j] = 1;
		}
	}

	int chunks = sizeof(bits) / sizeof(bits[0]) / 8;

	uint8_t buffer[chunks];

	// Change bit stream to be chunks from LSB to MSB
	for (int i = 0; i < chunks; i++) {
		int base = i * 8;

		uint8_t byte = 0;

		// Flip bits
		for (int bit = 7; bit >= 0; bit--) {
			byte <<= 1;
			byte |= bits[base + bit];
		}

		buffer[i] = byte;
	}

	// DMX Reset Procedure
	for (int i = 0; i < 2; i++) {
		outb(port, NULL); // "SPACE" for BREAK (>92usec)
	}

	// Send data to serial device
	for (int i = 0; i < chunks; i++) {
		outb(port, buffer[i]);
	}
}