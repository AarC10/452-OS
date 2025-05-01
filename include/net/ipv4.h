#ifndef IPV4_H
#define IPV4_H

#include <stdint.h>

// IPv4 Constants
#define IPV4_HEADER_MIN_LEN   20     // Minimum IPv4 header length (5 * 4 bytes)
#define IPV4_MAX_PACKET_SIZE  65535  // Maximum IPv4 packet size
#define IPV4_DEFAULT_TTL      64     // Default Time to Live value
#define IPV4_MAX_PAYLOAD      1480   // Maximum payload size (assuming 20 byte IPv4 header)

// IPv4 Protocol Values
#define IPV4_PROTO_ICMP       1      // ICMP protocol
#define IPV4_PROTO_TCP        6      // TCP protocol
#define IPV4_PROTO_UDP        17     // UDP protocol

// IPv4 Flags
#define IPV4_FLAG_RESERVED    0x04   // Reserved bit (must be zero)
#define IPV4_FLAG_DF          0x02   // Don't Fragment
#define IPV4_FLAG_MF          0x01   // More Fragments

// IPv4 Header structure
typedef struct {
    uint8_t version_ihl;      // Version (4 bits) + Internet Header Length (4 bits)
    uint8_t dscp_ecn;         // DSCP (6 bits) + ECN (2 bits)
    uint16_t total_length;    // Total Length
    uint16_t identification;  // Identification
    uint16_t flags_fragment;  // Flags (3 bits) + Fragment Offset (13 bits)
    uint8_t ttl;              // Time to Live
    uint8_t protocol;         // Protocol
    uint16_t header_checksum; // Header Checksum
    uint32_t src_addr;        // Source Address
    uint32_t dest_addr;       // Destination Address
    uint8_t payload[IPV4_MAX_PAYLOAD];  // Payload (variable length)
    uint32_t payload_len;     // Current payload length
} ipv4_packet_t;

// Function prototypes

/*
 * Calculate IPv4 header checksum
 * @param header Pointer to the header data
 * @param length Length of the header in bytes
 * @return The calculated checksum
 */
uint16_t ipv4_calculate_checksum(const uint8_t *header, uint32_t length);

/*
 * Initialize an IPv4 packet
 * @param packet Pointer to the packet structure to initialize
 * @param dscp_ecn DSCP and ECN values combined
 * @param identification Identification value
 * @param flags Flags (bit 0: MF, bit 1: DF, bit 2: Reserved)
 * @param fragment_offset Fragment offset
 * @param ttl Time to Live
 * @param protocol Protocol identifier
 * @param src_addr Source IP address
 * @param dest_addr Destination IP address
 */
void ipv4_init(ipv4_packet_t *packet, uint8_t dscp_ecn, uint16_t identification,
              uint8_t flags, uint16_t fragment_offset, uint8_t ttl, uint8_t protocol,
              uint32_t src_addr, uint32_t dest_addr);

/*
 * Set the payload for the IPv4 packet
 * @param packet Pointer to the packet structure
 * @param payload Pointer to the payload data
 * @param length Length of the payload in bytes
 */
void ipv4_set_payload(ipv4_packet_t *packet, const uint8_t *payload, uint32_t length);

/*
 * Serialize the IPv4 packet to a buffer
 * @param packet Pointer to the packet structure
 * @param buffer Pointer to the buffer where the packet will be serialized
 * @param buffer_size Size of the buffer in bytes
 * @return The total length of the serialized packet, or 0 if the buffer is too small
 */
uint32_t ipv4_serialize(const ipv4_packet_t *packet, uint8_t *buffer, uint32_t buffer_size);

#endif // IPV4_H
