#ifndef UDMXTEST_INC_C_
#define UDMXTEST_INC_C_

#include <common.h>
#include <dmx.h>
#include <lib.h>

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

			char str_buffer[120];

			usprint(str_buffer, "Channel: %d (%08s)\n", i + 1, binary);
			cwrites(str_buffer);

			for (int i = 0; i < 5; i++) {
				dmxwrite(DMX_PORT1, data);
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