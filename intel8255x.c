// intel8255x.c
#include <common.h>
#include <drivers/intel8255x.h>
#include <drivers/intel8255x_ops.h>
#include <kmem.h>
#include <types.h>
#include <x86/pci.h>
#include <cio.h>
#include <klib.h>

#define PCI_BAR_IO_MASK 0x1
#define PCI_BAR_MEM_MASK (~0xFULL)

static i8255x *global_dev;
static uint32_t rx_next = 0;

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

static void i8255x_setup_rings(i8255x *dev) {
    // RX ring
    for (int i = 0; i < I8255X_RX_RING_SIZE; i++) {
        void *buf = km_page_alloc(1);  // allocate 1 page (~4 KB)
        if (!buf) {
            cio_puts("RX buffer alloc failed\n");
            return;
        }
        dev->rx_ring[i].addr = (uint64_t)(uintptr_t)buf;
        dev->rx_ring[i].length = I8255X_PKT_BUF_SIZE;
        dev->rx_ring[i].status = 0;
    }
    // Base addr low/high
    write_reg(dev, I8255X_RDBAL, (uint32_t)((uint64_t)(uintptr_t)dev->rx_ring));
    write_reg(dev, I8255X_RDBAH,
              (uint32_t)(((uint64_t)(uintptr_t)dev->rx_ring) >> 32));
    write_reg(dev, I8255X_RDLEN, I8255X_RX_RING_SIZE * sizeof(i8255x_rx_desc));
    write_reg(dev, I8255X_RDH, 0);
    write_reg(dev, I8255X_RDT, I8255X_RX_RING_SIZE - 1);
    // Enable RX: enable, broadcast, strip CRC, 2 KB buffers
    write_reg(dev, I8255X_RCTL,
              I8255X_RCTL_EN | I8255X_RCTL_BAM | I8255X_RCTL_SECRC |
                  I8255X_RCTL_BSIZE_2048);

    // TX ring
    for (int i = 0; i < I8255X_TX_RING_SIZE; i++) {
        dev->tx_ring[i].status = I8255X_TXD_STAT_DD;
    }
    write_reg(dev, I8255X_TDBAL, (uint32_t)((uint64_t)(uintptr_t)dev->tx_ring));
    write_reg(dev, I8255X_TDBAH,
              (uint32_t)(((uint64_t)(uintptr_t)dev->tx_ring) >> 32));
    write_reg(dev, I8255X_TDLEN, I8255X_TX_RING_SIZE * sizeof(i8255x_tx_desc));
    write_reg(dev, I8255X_TDH, 0);
    write_reg(dev, I8255X_TDT, 0);
    // Enable TX: enable, pad short pkts, default CT/COLD
    write_reg(dev, I8255X_TCTL,
              I8255X_TCTL_EN | I8255X_TCTL_PSP |
                  (0x10 << I8255X_TCTL_CT_SHIFT) |
                  (0x40 << I8255X_TCTL_COLD_SHIFT));
    write_reg(dev, I8255X_TIPG, I8255X_TIPG_DEFAULT);
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



    // clear multicast table
    for (int i = 0; i < 128; i++) {
        write_reg(dev, I8255X_MULTICAST_TABLE_ARRAY + (i << 2), 0);
    }

    global_dev = dev;
    i8255x_setup_rings(dev);
    cio_puts("8255x setup complete\n");


    return 0;
}

int i8255x_transmit(const uint8_t *frame, uint16_t len) {
    i8255x *dev = global_dev;
    uint32_t tail = read_reg(dev, I8255X_TDT);
    i8255x_tx_desc *d = &dev->tx_ring[tail];

    // hardware must have finished with this descriptor
    if (!(d->status & I8255X_TXD_STAT_DD)) return -1;

    d->addr = (uint64_t)(uintptr_t)frame;
    d->length = len;
    d->cso = 0;
    d->cmd = I8255X_TXD_CMD_EOP | I8255X_TXD_CMD_IFCS | I8255X_TXD_CMD_RS;
    d->status = 0;
    d->css = 0;
    d->special = 0;

    tail = (tail + 1) % I8255X_TX_RING_SIZE;
    write_reg(dev, I8255X_TDT, tail);
    return 0;
}

// Receive one packet: returns byte-count, or 0 if none available.
int i8255x_receive(uint8_t *buf, uint16_t bufsize) {
    i8255x *dev = global_dev;
    i8255x_rx_desc *d = &dev->rx_ring[rx_next];
    // Check if descriptor has been filled
    if (!(d->status & I8255X_RXD_STAT_DD)) return 0;
    // Copy up to bufsize
    uint16_t len = d->length;
    if (len > bufsize) len = bufsize;
    memcpy(buf, (void *)(uintptr_t)d->addr, len);
    // Mark descriptor free
    d->status = 0;
    // Advance the hardware tail
    write_reg(dev, I8255X_RDT, rx_next);
    rx_next = (rx_next + 1) % I8255X_RX_RING_SIZE;
    return len;
}
