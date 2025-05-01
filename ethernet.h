#ifndef ETHERNET_H
#define ETHERNET_H

#include <stdint.h>

// Ethernet Constants
#define ETH_ADDR_LEN          6      // MAC address length in bytes
#define ETH_HEADER_LEN        14     // Ethernet header length
#define ETH_MTU               1500   // Maximum Transmission Unit
#define ETH_MIN_PAYLOAD       46     // Minimum payload size for Ethernet (padded if less)
#define ETH_MAX_FRAME_SIZE    1518   // Maximum Ethernet frame size without FCS
#define ETH_MIN_FRAME_SIZE    64     // Minimum Ethernet frame size with FCS

// EtherType Values
#define ETH_TYPE_IPV4         0x0800 // IPv4 EtherType
#define ETH_TYPE_ARP          0x0806 // ARP EtherType
#define ETH_TYPE_IPV6         0x86DD // IPv6 EtherType
#define ETH_TYPE_VLAN         0x8100 // VLAN EtherType

// Ethernet II Frame structure
typedef struct {
    uint8_t dest_mac[ETH_ADDR_LEN];      // Destination MAC address
    uint8_t src_mac[ETH_ADDR_LEN];       // Source MAC address
    uint16_t ethertype;                   // EtherType (protocol)
    uint8_t payload[ETH_MTU];            // Payload (variable length, max 1500 bytes)
    uint32_t payload_len;                 // Current payload length
} eth_frame_t;

// Function prototypes

/*
 * Initialize an Ethernet II frame
 * @param frame Pointer to the frame structure to initialize
 * @param dest_mac Destination MAC address (6 bytes)
 * @param src_mac Source MAC address (6 bytes)
 * @param ethertype EtherType value (protocol identifier)
 */
void eth_init(eth_frame_t *frame, const uint8_t *dest_mac, const uint8_t *src_mac, uint16_t ethertype);

/*
 * Set the payload for the Ethernet frame
 * @param frame Pointer to the frame structure
 * @param payload Pointer to the payload data
 * @param length Length of the payload in bytes
 */
void eth_set_payload(eth_frame_t *frame, const uint8_t *payload, uint32_t length);

/*
 * Serialize the Ethernet frame to a buffer
 * @param frame Pointer to the frame structure
 * @param buffer Pointer to the buffer where the frame will be serialized
 * @param buffer_size Size of the buffer in bytes
 * @return The total length of the serialized frame, or 0 if the buffer is too small
 */
uint32_t eth_serialize(const eth_frame_t *frame, uint8_t *buffer, uint32_t buffer_size);

#endif // ETHERNET_H
