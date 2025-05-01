#include "net/ipv4.h"
#include <string.h>

// Calculate IPv4 header checksum
uint16_t ipv4_calculate_checksum(const uint8_t *header, uint32_t length) {
  uint32_t sum = 0;
  const uint16_t *ptr = (const uint16_t *)header;

  // Sum all 16-bit words
  while (length > 1) {
    sum += *ptr++;
    length -= 2;
  }

  // Add left-over byte, if any
  if (length > 0) {
    sum += *(const uint8_t *)ptr;
  }

  // Fold 32-bit sum to 16 bits
  while (sum >> 16) {
    sum = (sum & 0xFFFF) + (sum >> 16);
  }

  // Take one's complement
  return ~sum;
}

// Initialize an IPv4 packet
void ipv4_init(ipv4_packet_t *packet, uint8_t dscp_ecn, uint16_t identification,
               uint8_t flags, uint16_t fragment_offset, uint8_t ttl,
               uint8_t protocol, uint32_t src_addr, uint32_t dest_addr) {
  packet->version_ihl = 0x45; // Version 4, IHL 5 (5 * 4 = 20 bytes, no options)
  packet->dscp_ecn = dscp_ecn;
  packet->total_length = 0; // Will be set during serialization
  packet->identification = identification;

  // Combine flags (3 bits) and fragment offset (13 bits)
  packet->flags_fragment =
      ((uint16_t)(flags & 0x07) << 13) | (fragment_offset & 0x1FFF);

  packet->ttl = ttl;
  packet->protocol = protocol;
  packet->header_checksum = 0; // Will be calculated during serialization
  packet->src_addr = src_addr;
  packet->dest_addr = dest_addr;
  packet->payload_len = 0;
}

// Set the payload for the IPv4 packet
void ipv4_set_payload(ipv4_packet_t *packet, const uint8_t *payload,
                      uint32_t length) {
  if (length > IPV4_MAX_PAYLOAD) {
    length = IPV4_MAX_PAYLOAD;
  }

  memcpy(packet->payload, payload, length);
  packet->payload_len = length;
}

// Serialize the IPv4 packet to a buffer
uint32_t ipv4_serialize(const ipv4_packet_t *packet, uint8_t *buffer,
                        uint32_t buffer_size) {
  uint32_t header_size = IPV4_HEADER_MIN_LEN; // Standard IPv4 header size (5 *
                                              // 4 = 20 bytes, no options)
  uint32_t total_size = header_size + packet->payload_len;

  if (buffer_size < total_size) {
    return 0; // Buffer too small
  }

  // Copy header to buffer
  buffer[0] = packet->version_ihl;
  buffer[1] = packet->dscp_ecn;

  // Set total length (in network byte order)
  buffer[2] = (total_size >> 8) & 0xFF;
  buffer[3] = total_size & 0xFF;

  // Set identification (in network byte order)
  buffer[4] = (packet->identification >> 8) & 0xFF;
  buffer[5] = packet->identification & 0xFF;

  // Set flags and fragment offset (in network byte order)
  buffer[6] = (packet->flags_fragment >> 8) & 0xFF;
  buffer[7] = packet->flags_fragment & 0xFF;

  buffer[8] = packet->ttl;
  buffer[9] = packet->protocol;
  buffer[10] = 0; // Checksum high byte (calculated later)
  buffer[11] = 0; // Checksum low byte (calculated later)

  // Source IP address
  buffer[12] = (packet->src_addr >> 24) & 0xFF;
  buffer[13] = (packet->src_addr >> 16) & 0xFF;
  buffer[14] = (packet->src_addr >> 8) & 0xFF;
  buffer[15] = packet->src_addr & 0xFF;

  // Destination IP address
  buffer[16] = (packet->dest_addr >> 24) & 0xFF;
  buffer[17] = (packet->dest_addr >> 16) & 0xFF;
  buffer[18] = (packet->dest_addr >> 8) & 0xFF;
  buffer[19] = packet->dest_addr & 0xFF;

  // Calculate header checksum
  uint16_t checksum = ipv4_calculate_checksum(buffer, header_size);
  buffer[10] = (checksum >> 8) & 0xFF; // Checksum high byte
  buffer[11] = checksum & 0xFF;        // Checksum low byte

  // Copy payload
  memcpy(buffer + header_size, packet->payload, packet->payload_len);

  return total_size;
}
