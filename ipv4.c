#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define MAX_IPV4_PAYLOAD_SIZE 1480

// IPv4 Header structure
typedef struct {
  uint8_t version_ihl;     // Version (4 bits) + Internet Header Length (4 bits)
  uint8_t dscp_ecn;        // DSCP (6 bits) + ECN (2 bits)
  uint16_t total_length;   // Total Length
  uint16_t identification; // Identification
  uint16_t flags_fragment; // Flags (3 bits) + Fragment Offset (13 bits)
  uint8_t ttl;             // Time to Live
  uint8_t protocol;        // Protocol
  uint16_t header_checksum;               // Header Checksum
  uint32_t src_addr;                      // Source Address
  uint32_t dest_addr;                     // Destination Address
  uint8_t payload[MAX_IPV4_PAYLOAD_SIZE]; // Payload (variable length, MTU -
                                          // IPv4 header)
  uint32_t payload_len;                   // Current payload length
} ipv4_packet_t;

uint16_t ipv4_calculate_checksum(const uint8_t *header, uint32_t length) {
  uint32_t sum = 0;
  const uint16_t *ptr = (const uint16_t *)header;

  // Sum all 16 bit words
  while (length > 1) {
    sum += *ptr++;
    length -= 2;
  }

  // Add nay left-over bytes
  if (length > 0) {
    sum += *(const uint8_t *)ptr;
  }

  // Fold sum to 16 bits
  while (sum >> 16) {
    sum = (sum & 0xFFFF) + (sum >> 16);
  }

  // Take 1s complement
  return ~sum;
}

// Initialize an IPv4 packet
void ipv4_init(ipv4_packet_t *packet, uint8_t dscp_ecn, uint16_t identification,
               uint8_t flags, uint16_t fragment_offset, uint8_t ttl,
               uint8_t protocol, uint32_t src_addr, uint32_t dest_addr) {
  packet->version_ihl = 0x45; // Version 4, IHL 5 (5 * 4 = 20 bytes, no options)
  packet->dscp_ecn = dscp_ecn;
  packet->total_length = 0; // set during init
  packet->identification = identification;

  // Combine flags (3 bits) and fragment offset (13 bits)
  packet->flags_fragment =
      ((uint16_t)(flags & 0x07) << 13) | (fragment_offset & 0x1FFF);

  packet->ttl = ttl;
  packet->protocol = protocol;
  packet->header_checksum = 0;
  packet->src_addr = src_addr;
  packet->dest_addr = dest_addr;
  packet->payload_len = 0;
}

void ipv4_set_payload(ipv4_packet_t *packet, const uint8_t *payload,
                      uint32_t length) {
  if (length > MAX_IPV4_PAYLOAD_SIZE) {
    length = MAX_IPV4_PAYLOAD_SIZE;
  }

  memcpy(packet->payload, payload, length);
  packet->payload_len = length;
}

// Serialize the IPv4 packet to a buffer
uint32_t ipv4_serialize(const ipv4_packet_t *packet, uint8_t *buffer,
                        uint32_t buffer_size) {
  uint32_t header_size =
      20; // Standard IPv4 header size (5 * 4 = 20 bytes, no options)
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

int main() {
  uint8_t test_payload[32];
  for (int i = 0; i < 32; i++) {
    test_payload[i] = i + 1;
  }

  ipv4_packet_t packet = {0};

  // Source IP: 192.168.1.100, Destination IP: 192.168.1.1
  uint32_t src_ip = (10 << 24) | (0 << 16) | (0 << 8) | 1;
  uint32_t dest_ip = (10 << 24) | (0 << 16) | (0 << 8) | 2;

  ipv4_init(&packet, 0, 1234, 2, 0, 64, 17, // 17 is UDP protocol
            src_ip, dest_ip);

  ipv4_set_payload(&packet, test_payload, sizeof(test_payload));

  uint8_t buffer[1500] = {0};
  uint32_t size = ipv4_serialize(&packet, buffer, sizeof(buffer));

  for (uint32_t i = 0; i < size; i++) {
    printf("%02x ", buffer[i]);
    if ((i + 1) % 16 == 0)
      printf("\n");
  }
  printf("\n");

  return 0;
}
