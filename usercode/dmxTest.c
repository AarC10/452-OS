#ifndef UDMXTEST_INC_C_
#define UDMXTEST_INC_C_
#include <common.h>
#include <sio.h>
#include <cio.h>
#include <klib.h>

USERMAIN(dmxTest) {
	cwrites("Running DMX channel check!\n");

	uint8_t data[DMX_SLOTS];

	for (int i = 0; i < DMX_SLOTS; i++) {
		data[i] = 0;
	}

	while (true) {
		cwrites("--- Starting Loop ---\n");

		for (int i = 0; i < DMX_SLOTS; i++) {
			int prev = data[i];

			data[i] = 255;

			char binary[9];

			itoa(i, binary, 2);

			cio_printf("Channel: %d (%08s)\n", i + 1, binary);			

			for (int i = 0; i < 5; i++) {
				sio_dmx(0x2f8, data);
				sleep(70);
			}

			data[i] = prev;
		}

		cwrites("--- Loop Complete! ---\n");
	}

	exit(0);

	return( 42 );  // shut the compiler up!
}

#endif