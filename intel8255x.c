// intel8255x.c
#include <common.h>
#include <drivers/intel8255x.h>
#include <drivers/intel8255x_ops.h>
#include <kmem.h>
#include <types.h>
#include <x86/pci.h>

#define PCI_BAR_IO_MASK 0x1
#define PCI_BAR_MEM_MASK (~0xFULL)

static inline uint32_t read_reg(i8255x *dev, uint32_t off) {
    return *(volatile uint32_t *)(dev->mmio_base + off);
}

static inline void write_reg(i8255x *dev, uint32_t off, uint32_t v) {
    *(volatile uint32_t *)(dev->mmio_base + off) = v;
}

static uint32_t get_mmio_addr(struct pci_func *pcif) {
    for (int i = 0; i < 6; i++) {
        uint32_t bar = pcif->base_addr[i];
        if (bar == 0 || (bar & PCI_BAR_IO_MASK)) continue;
        return bar & PCI_BAR_MEM_MASK;
    }
    return 0;
}

static uint16_t i8255x_read_eeprom(i8255x *dev, uint8_t addr) {
    uint32_t cmd = ((uint32_t)addr << I8255X_EERD_ADDR) | I8255X_EERD_READ;
    write_reg(dev, I8255X_EERD, cmd);

    uint32_t data;
    int timeout = 100000;
    do {
        data = read_reg(dev, I8255X_EERD);
        __asm__ __volatile__("pause");
    } while (!(data & I8255X_EERD_DONE) && --timeout);

    if (!timeout) {
        cio_puts("EEPROM read timeout\n");
        return 0xFFFF;
    }
    return (uint16_t)(data >> I8255X_EERD_DATA);
}

static void get_mac_addr(i8255x *dev, uint8_t mac[6]) {
    uint32_t status = read_reg(dev, I8255X_STATUS);
    if (status & (1 << 8)) {
        // EEPROM present: read words 0..2
        for (int i = 0; i < 3; i++) {
            uint16_t w = i8255x_read_eeprom(dev, i);
            mac[i * 2] = w & 0xFF;
            mac[i * 2 + 1] = (w >> 8) & 0xFF;
        }
    } else {
        // Fallback: read Receive Address registers
        uint32_t lo = read_reg(dev, I8255X_RA);
        uint32_t hi = read_reg(dev, I8255X_RA + 4);
        mac[0] = lo & 0xFF;
        mac[1] = (lo >> 8) & 0xFF;
        mac[2] = (lo >> 16) & 0xFF;
        mac[3] = (lo >> 24) & 0xFF;
        mac[4] = hi & 0xFF;
        mac[5] = (hi >> 8) & 0xFF;
    }
}

static void i8255x_init_tx(i8255x *dev) {
    for (int i = 0; i < I8255X_TX_RING_SIZE; i++) {
        memset(&dev->tx_ring[i], 0, sizeof(i8255x_tx_desc));
    }
}

static void i8255x_init_rx(i8255x *dev) {
    for (int i = 0; i < I8255X_RX_RING_SIZE; i++) {
        memset(&dev->rx_ring[i], 0, sizeof(i8255x_rx_desc));
    }
}

int i8255x_init(void) {
    struct pci_func *pcif = km_slice_alloc();
    if (!pcif) {
        cio_puts("PCI alloc failed\n");
        return -1;
    }

    // find either device ID
    if (pci_search_for_device(0x8086, 0x1227, pcif) &&
        pci_search_for_device(0x8086, 0x1229, pcif)) {
        cio_puts("No Intel 8255x NIC found\n");
        return -1;
    }

    i8255x *dev = km_slice_alloc();
    dev->mmio_base = get_mmio_addr(pcif);
    if (!dev->mmio_base) {
        cio_puts("Failed to get MMIO base\n");
        return -1;
    }
    cio_printf("8255x MMIO @ 0x%08x\n", dev->mmio_base);

    // reset and wait
    write_reg(dev, I8255X_CTL, I8255X_CTL_RST);
    while (read_reg(dev, I8255X_CTL) & I8255X_CTL_RST) {
        __asm__ __volatile__("pause");
    }

    // read or fallback MAC
    get_mac_addr(dev, dev->addr);
    cio_printf("MAC %02x:%02x:%02x:%02x:%02x:%02x\n", dev->addr[0],
               dev->addr[1], dev->addr[2], dev->addr[3], dev->addr[4],
               dev->addr[5]);

    // init rings
    i8255x_init_tx(dev);
    i8255x_init_rx(dev);

    // clear multicast table
    for (int i = 0; i < 128; i++) {
        write_reg(dev, I8255X_MULTICAST_TABLE_ARRAY + (i << 2), 0);
    }

    return 0;
}

int i8255x_transmit(const uint8_t *frame, uint16_t len) { return -1; }

int i8255x_receive(uint8_t *buf, uint16_t bufsize) { return -1; }

void i8255x_get_mac(uint8_t mac_out[6]) {
    // no-op: mac is already in dev->addr
}
