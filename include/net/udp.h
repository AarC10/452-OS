/**
 * @file udp.h
 * @author Aaron Chan
 * @brief UDP header file with definitions and function prototypes
 */
#ifndef UDP_H
#define UDP_H

#include "net/ipv4.h"
#include "types.h"

// UDP Constants
#define UDP_HEADER_LEN 8 // UDP header length
#define UDP_MAX_DATAGRAM_SIZE                                                  \
  65507 // Maximum UDP datagram size (65535 - 20 - 8)
#define UDP_MAX_PAYLOAD                                                        \
  1472 // Maximum UDP payload in standard MTU (1500 - 20 - 8)

// Common UDP port numbers
#define UDP_PORT_DHCP_CLIENT 68 // DHCP client
#define UDP_PORT_DHCP_SERVER 67 // DHCP server
#define UDP_PORT_DNS 53         // DNS
#define UDP_PORT_NTP 123        // NTP
#define UDP_PORT_SNMP 161       // SNMP

// UDP Header structure
typedef struct {
  uint16_t src_port;                // Source Port
  uint16_t dest_port;               // Destination Port
  uint16_t length;                  // Length (header + data)
  uint16_t checksum;                // Checksum
  uint8_t payload[UDP_MAX_PAYLOAD]; // Payload (variable length)
  uint32_t payload_len;             // Current payload length
} udp_packet_t;

// IPv4 Pseudo-header for UDP checksum calculation
typedef struct {
  uint32_t src_addr;   // Source Address
  uint32_t dest_addr;  // Destination Address
  uint8_t zeros;       // Reserved (must be zero)
  uint8_t protocol;    // Protocol (17 for UDP)
  uint16_t udp_length; // UDP Length
} ipv4_pseudo_header_t;

// Function prototypes

/*
 * Calculate UDP checksum (including IPv4 pseudo-header)
 * @param packet Pointer to the UDP packet structure
 * @param udp_buffer Pointer to the serialized UDP packet
 * @param udp_len Length of the UDP packet
 * @param src_addr Source IP address
 * @param dest_addr Destination IP address
 * @return The calculated checksum
 */
uint16_t udp_calculate_checksum(const udp_packet_t *packet,
                                const uint8_t *udp_buffer, uint32_t udp_len,
                                uint32_t src_addr, uint32_t dest_addr);

/*
 * Initialize a UDP packet
 * @param packet Pointer to the packet structure to initialize
 * @param src_port Source port
 * @param dest_port Destination port
 */
void udp_init(udp_packet_t *packet, uint16_t src_port, uint16_t dest_port);

/*
 * Set the payload for the UDP packet
 * @param packet Pointer to the packet structure
 * @param payload Pointer to the payload data
 * @param length Length of the payload in bytes
 */
void udp_set_payload(udp_packet_t *packet, const uint8_t *payload,
                     uint32_t length);

/*
 * Serialize the UDP packet to a buffer
 * @param packet Pointer to the packet structure
 * @param buffer Pointer to the buffer where the packet will be serialized
 * @param buffer_size Size of the buffer in bytes
 * @param src_addr Source IP address (for checksum calculation)
 * @param dest_addr Destination IP address (for checksum calculation)
 * @return The total length of the serialized packet, or 0 if the buffer is too
 * small
 */
uint32_t udp_serialize(const udp_packet_t *packet, uint8_t *buffer,
                       uint32_t buffer_size, uint32_t src_addr,
                       uint32_t dest_addr);

#endif // UDP_H
