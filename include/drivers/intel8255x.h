#ifndef _INTEL8255X_DRIVER_
#define _INTEL8255X_DRIVER_

#include <types.h>

int i8255x_init(uint32_t pci_bar, bool is_io);

int i8255x_transmit(const uint8_t *frame, uint16_t len);

int i8255x_receive(uint8_t *buf, uint16_t bufsize);

void i8255x_get_mac(uint8_t mac_out[6]);

#endif // _INTEL8255X_DRIVER_
