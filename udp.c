#include "net/udp.h"
#include "klib.h"

// Calculate UDP checksum (including IPv4 pseudo-header)
uint16_t udp_calculate_checksum(const udp_packet_t *packet,
                                const uint8_t *udp_buffer, uint32_t udp_len,
                                uint32_t src_addr, uint32_t dest_addr) {
  // Create the pseudo-header
  ipv4_pseudo_header_t pseudo_header;
  pseudo_header.src_addr = src_addr;
  pseudo_header.dest_addr = dest_addr;
  pseudo_header.zeros = 0;
  pseudo_header.protocol = IPV4_PROTO_UDP; // 17 for UDP
  pseudo_header.udp_length =
      (udp_len >> 8) | ((udp_len & 0xFF) << 8); // Host to network byte order

  // Calculate the sum over the pseudo-header
  uint32_t sum = 0;
  const uint16_t *ptr = (const uint16_t *)&pseudo_header;
  for (int i = 0; i < sizeof(ipv4_pseudo_header_t) / 2; i++) {
    sum += *ptr++;
  }

  // Add the UDP packet
  ptr = (const uint16_t *)udp_buffer;
  int len = udp_len;

  while (len > 1) {
    sum += *ptr++;
    len -= 2;
  }

  // If length is odd, pad with zero
  if (len > 0) {
    sum += *(uint8_t *)ptr;
  }

  // Fold 32-bit sum to 16 bits
  while (sum >> 16) {
    sum = (sum & 0xFFFF) + (sum >> 16);
  }

  // Take one's complement
  uint16_t checksum = ~sum;

  // Return 0xFFFF if checksum calculates to 0
  return (checksum == 0) ? 0xFFFF : checksum;
}

// Initialize a UDP packet
void udp_init(udp_packet_t *packet, uint16_t src_port, uint16_t dest_port) {
  packet->src_port = src_port;
  packet->dest_port = dest_port;
  packet->length = UDP_HEADER_LEN; // Just the header size initially
  packet->checksum = 0;            // Will be calculated during serialization
  packet->payload_len = 0;
}

// Set the payload for the UDP packet
void udp_set_payload(udp_packet_t *packet, const uint8_t *payload,
                     uint32_t length) {
  if (length > UDP_MAX_PAYLOAD) {
    length = UDP_MAX_PAYLOAD;
  }

  memcpy(packet->payload, payload, length);
  packet->payload_len = length;
}

// Serialize the UDP packet to a buffer
uint32_t udp_serialize(const udp_packet_t *packet, uint8_t *buffer,
                       uint32_t buffer_size, uint32_t src_addr,
                       uint32_t dest_addr) {
  uint32_t total_size = UDP_HEADER_LEN + packet->payload_len;

  if (buffer_size < total_size) {
    return 0; // Buffer too small
  }

  // Copy header to buffer with fields in network byte order
  buffer[0] = (packet->src_port >> 8) & 0xFF;
  buffer[1] = packet->src_port & 0xFF;

  buffer[2] = (packet->dest_port >> 8) & 0xFF;
  buffer[3] = packet->dest_port & 0xFF;

  // Set length (header + data) in network byte order
  buffer[4] = (total_size >> 8) & 0xFF;
  buffer[5] = total_size & 0xFF;

  // Temporarily set checksum to 0
  buffer[6] = 0;
  buffer[7] = 0;

  // Copy payload
  memcpy(buffer + UDP_HEADER_LEN, packet->payload, packet->payload_len);

  // Calculate checksum (includes pseudo header)
  uint16_t checksum =
      udp_calculate_checksum(packet, buffer, total_size, src_addr, dest_addr);

  // Set checksum in network byte order
  buffer[6] = (checksum >> 8) & 0xFF;
  buffer[7] = checksum & 0xFF;

  return total_size;
}
