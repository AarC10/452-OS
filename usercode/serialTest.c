#ifndef USERIALTEST_INC_C_
#define USERIALTEST_INC_C_
#include <common.h>
#include <sio.h>

USERMAIN(serialTest) {
	cwrites("Running serial test!\n");

	uint8_t data[8];

	for (int i = 0; i < DMX_SLOTS; i++) {
		data[i] = 255;
	}

	sio_dmx(0x2f8, data);

	exit(0);

	return( 42 );  // shut the compiler up!
}

#endif