#ifndef _INTEL8255X_DRIVER_
#define _INTEL8255X_DRIVER_

#include <types.h>

#define I8255X_RX_RING_SIZE 16
#define I8255X_TX_RING_SIZE 16

#define I8255X_RXD_STAT_DD 0x01  // Desc done
#define I8255X_RXD_STAT_EOP 0x02 // End of packet

#define I8255X_MULTICAST_TABLE_ARRAY 0x5200

// Registers
// Registers 
#define I8255X_CTL (0x0000)   // Device Control Register - RW
#define I8255X_STATUS 0x0008  // Device Status Register - RO
#define I8255X_EERD (0x0014)  // EEPROM Read - RW 
#define I8255X_ICR (0x00C0)   // Interrupt Cause Read - R 
#define I8255X_IMS (0x00D0)   // Interrupt Mask Set - RW 
#define I8255X_IMC (0x00D8)   // Interrupt Mask Clear - RW 
#define I8255X_RCTL (0x0100)  // RX Control - RW 
#define I8255X_TCTL (0x0400)  // TX Control - RW 
#define I8255X_TIPG (0x0410)  // TX Inter-packet gap -RW 
#define I8255X_RDBAL (0x2800) // RX Descriptor Base Address Low - RW 
#define I8255X_RDBAH (0x2804) // RX Descriptor Base Address High - RW 
#define I8255X_RDTR (0x2820)  // RX Delay Timer 
#define I8255X_RADV (0x282C)  // RX Interrupt Absolute Delay Timer 
#define I8255X_RDH (0x2810)   // RX Descriptor Head - RW 
#define I8255X_RDT (0x2818)   // RX Descriptor Tail - RW 
#define I8255X_RDLEN (0x2808) // RX Descriptor Length - RW 
#define I8255X_RSRPD (0x2C00) // RX Small Packet Detect Interrupt 
#define I8255X_TDBAL (0x3800) // TX Descriptor Base Address Low - RW 
#define I8255X_TDBAH (0x3804) // TX Descriptor Base Address Hi - RW 
#define I8255X_TDLEN (0x3808) // TX Descriptor Length - RW 
#define I8255X_TDH (0x3810)   // TX Descriptor Head - RW 
#define I8255X_TDT (0x3818)   // TX Descripotr Tail - RW 
#define I8255X_MTA (0x5200)   // Multicast Table Array - RW Array 
#define I8255X_RA (0x5400)    // Receive Address - RW Array 

// Dev Ctrl
#define I8255X_CTL_SLU 0x00000040     // Link speed
#define I8255X_CTL_FRCSPD 0x00000800  // Force speed
#define I8255X_CTL_FRCDPLX 0x00001000 // Force duplex
#define I8255X_CTL_RST 0x00400000     // Full reset

// EEPROM
#define I8255X_EERD_ADDR 8
#define I8255X_EERD_DATA 16
#define I8255X_EERD_READ (1 << 0)
#define I8255X_EERD_DONE (1 << 4)

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

int i8255x_init(void);

int i8255x_transmit(const uint8_t *frame, uint16_t len);

int i8255x_receive(uint8_t *buf, uint16_t bufsize);

#endif // _INTEL8255X_DRIVER_
