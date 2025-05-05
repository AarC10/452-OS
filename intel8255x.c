#include <drivers/intel8255x.h>
#include <types.h>
#include <drivers/intel8255x_ops.h>

static uint_t read_reg(i8255x *dev, uint32_t offset) {
    return *(volatile uint32_t *)(dev->mmio_base + offset);
}

static void write_reg(i8255x *dev, uint32_t offset, uint32_t value) {
    *(volatile uint32_t *)(dev->mmio_base + offset) = value;
}

int i8255x_init(uint32_t pci_bar, bool_t is_io) { return -1; }

int i8255x_transmit(const uint8_t *frame, uint16_t len) { return -1; }

int i8255x_receive(uint8_t *buf, uint16_t bufsize) { return -1; }

void i8255x_get_mac(uint8_t mac_out[6]) {}
