#ifndef _INTEL8255X_DRIVER_
#define _INTEL8255X_DRIVER_

#include <types.h>

#define E1000_RX_RING_SIZE 16
#define E1000_TX_RING_SIZE 16

#define E1000_RXD_STAT_DD 0x01  // Desc done
#define E1000_RXD_STAT_EOP 0x02 // End of packet

typedef struct {
    uint64_t addr; // Addr of the data buffer
    uint16_t length; // Length of data
    uint8_t cso; // Checksum offset
    uint8_t cmd; // Desc ctrl
    uint8_t status; // Desc status
    uint8_t css; // Checksum Start
    uint16_t special; // Special field
} e1000_tx_desc;

typedef struct {
    uint64_t addr;   // Addr of data buffer
    uint16_t length; // Length of data
    uint16_t csum;   // Packet checksum
    uint8_t status;  // Desc status
    uint8_t errors;  // Desc errors
    uint16_t special; // Special field
} e1000_rx_desc;

typedef struct {
    uint32_t mmio_base;
    e1000_rx_desc rx_ring[E1000_RX_RING_SIZE] __attribute__((aligned(16)));
    e1000_tx_desc tx_ring[E1000_TX_RING_SIZE] __attribute__((aligned(16)));
    uint8_t addr[6];
    uint8_t irq;
    struct netdev *netdev;
    struct e1000 *next;
} e1000;

int i8255x_init(uint32_t pci_bar, bool_t is_io);

int i8255x_transmit(const uint8_t *frame, uint16_t len);

int i8255x_receive(uint8_t *buf, uint16_t bufsize);

void i8255x_get_mac(uint8_t mac_out[6]);

#endif // _INTEL8255X_DRIVER_
