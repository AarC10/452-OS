#include <drivers/intel8255x.h>
#include <types.h>
#include <drivers/intel8255x_ops.h>

int i8255x_init(uint32_t pci_bar, bool_t is_io) { return -1; }

int i8255x_transmit(const uint8_t *frame, uint16_t len) { return -1; }

int i8255x_receive(uint8_t *buf, uint16_t bufsize) { return -1; }

void i8255x_get_mac(uint8_t mac_out[6]) {}
