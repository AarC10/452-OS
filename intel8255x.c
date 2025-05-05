#include <drivers/intel8255x.h>
#include <types.h>
#include <drivers/intel8255x_ops.h>
#include <x86/pci.h>
#include <kmem.h>
#include <common.h>

#define PCI_BASE_ADDR_SPACE_MASK 0xffff
#define PCI_BASE_ADDR_MEM_MASK (1 << 17)

static uint_t read_reg(i8255x *dev, uint32_t offset) {
    return *(volatile uint32_t *)(dev->mmio_base + offset);
}

static void write_reg(i8255x *dev, uint32_t offset, uint32_t value) {
    *(volatile uint32_t *)(dev->mmio_base + offset) = value;
}

// BAR bit-0 == 1 means I/O space; == 0 means memory space
#define PCI_BAR_IO_MASK 0x1

// mask bottom 4 flag bits of a mem BAR (bits 0–3)
#define PCI_BAR_MEM_MASK (~0xFULL)
static uint32_t get_mmio_addr(struct pci_func *pcif) {
    uint32_t mmio_base = 0;
    for (int i = 0; i < 6; i++) {
        uint32_t bar = pcif->base_addr[i];
        // skip empty BARs
        if (bar == 0) continue;
        // skip I/O‐space BARs
        if (bar & PCI_BAR_IO_MASK) continue;
        // this is a memory BAR, mask off the low flags:
        mmio_base = bar & PCI_BAR_MEM_MASK;
        break;
    }
    return mmio_base;
}

static uint16_t eeprom_read(i8255x *dev, uint8_t addr) {
    uint32_t data = 0;
    write_reg(dev, I8255X_EERD, I8255X_EERD_READ | addr << I8255X_EERD_ADDR);
    while (!((data = read_reg(dev, I8255X_EERD)) & I8255X_EERD_DONE)) {
        __asm__ __volatile__("pause");
    }
    return (uint16_t)(data >> I8255X_EERD_DATA);
}

static void get_mac_addr(i8255x *dev, uint8_t mac[6]) {
    uint16_t res = 0;
    for (int i = 0; i < 3; i++) {
        res = eeprom_read(dev, i);
        mac[i * 2] = (res >> 8) & 0xFF;
        mac[i * 2 + 1] = res & 0xFF;
    }
}

static void i8255x_init_tx(i8255x *dev) {
    for (int i = 0; i < I8255X_TX_RING_SIZE; i++) {
        memset(&dev->tx_ring[i], 0, sizeof(i8255x_tx_desc));
    }

    // Expecting we aren't using the virtual addr space in this OS right now
    // Can ignore V2P functions here. Causes some weird compile issues when
    // including vm.h
    uint64_t base = (uint64_t)(dev->tx_ring);
}

static void i8255x_init_rx(i8255x *dev) {
    for (int i = 0; i < I8255X_RX_RING_SIZE; i++) {
        memset(&dev->rx_ring[i], 0, sizeof(i8255x_rx_desc));
    }

    uint64_t base = (uint64_t)(dev->rx_ring);
}

int i8255x_init() {
    struct pci_func *pcif = (struct pci_func *) km_slice_alloc();
    if (!pcif) {
        cio_puts("km_slice_alloc failed for network pcif\n");
        return -1;
    }

    // Find the PCI device
    if (!pci_search_for_device(0x8086, 0x1227, pcif)) {
        if (!pci_search_for_device(0x8086, 0x1229, pcif)) {
            cio_puts("Failed to find PCI device\n");
            km_slice_free(pcif);
            return -1;
        }
    }

    pci_func_enable(pcif);
    i8255x *dev = (struct i8255x *)km_slice_alloc();
    dev->mmio_base = get_mmio_addr(pcif);
    if (!dev->mmio_base) {
        cio_puts("Failed to resolve MMIO base\n");
        km_slice_free(pcif);
        return -1;
    }

    cio_printf("mmio_base=0x%08x\n", dev->mmio_base);


    // Read HW address from EEPROM
    get_mac_addr(dev, dev->addr);


    cio_printf("MAC addr=%02x:%02x:%02x:%02x:%02x:%02x\n", dev->addr[0],
            dev->addr[1], dev->addr[2], dev->addr[3], dev->addr[4],
            dev->addr[5]);


    // //APIC
    // dev->irq = pcif->irq_line;
    // ioapicenable(dev->irq, ncpu - 1);

    // setup tx/rx rings
    i8255x_init_tx(dev);
    i8255x_init_rx(dev);

    // Init multicast array table
    for (int i = 0; i < 128; i++) {
        write_reg(dev, I8255X_MULTICAST_TABLE_ARRAY + (i << 2), 0);
    }

    return 0;
}

int i8255x_transmit(const uint8_t *frame, uint16_t len) { return -1; }

int i8255x_receive(uint8_t *buf, uint16_t bufsize) { return -1; }

void i8255x_get_mac(uint8_t mac_out[6]) {}
