#ifndef _INTEL8255X_DRIVER_
#define _INTEL8255X_DRIVER_

#include <types.h>

#define I8255X_RX_RING_SIZE 16
#define I8255X_TX_RING_SIZE 16

#define I8255X_RXD_STAT_DD 0x01  // Desc done
#define I8255X_RXD_STAT_EOP 0x02 // End of packet

#define I8255X_MULTICAST_TABLE_ARRAY 0x5200

typedef struct {
    uint64_t addr; // Addr of the data buffer
    uint16_t length; // Length of data
    uint8_t cso; // Checksum offset
    uint8_t cmd; // Desc ctrl
    uint8_t status; // Desc status
    uint8_t css; // Checksum Start
    uint16_t special; // Special field
} i8255x_tx_desc;

typedef struct {
    uint64_t addr;   // Addr of data buffer
    uint16_t length; // Length of data
    uint16_t csum;   // Packet checksum
    uint8_t status;  // Desc status
    uint8_t errors;  // Desc errors
    uint16_t special; // Special field
} i8255x_rx_desc;

typedef struct {
    uint32_t mmio_base;
    i8255x_rx_desc rx_ring[I8255X_RX_RING_SIZE] __attribute__((aligned(16)));
    i8255x_tx_desc tx_ring[I8255X_TX_RING_SIZE] __attribute__((aligned(16)));
    uint8_t addr[6];
    uint8_t irq;
    struct netdev *netdev;
    struct i8255x *next;
} i8255x;

int i8255x_init(uint32_t pci_bar, bool_t is_io);

int i8255x_transmit(const uint8_t *frame, uint16_t len);

int i8255x_receive(uint8_t *buf, uint16_t bufsize);

void i8255x_get_mac(uint8_t mac_out[6]);

#endif // _INTEL8255X_DRIVER_
