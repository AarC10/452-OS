#include <stdint.h>
#include <stdio.h>
#include <string.h>

// Ethernet II Frame structure
typedef struct {
  uint8_t dst_mac[6];    // Destination MAC address
  uint8_t src_mac[6];    // Source MAC address
  uint16_t ethertype;    // EtherType (protocol)
  uint8_t payload[1500]; // Payload (variable length, max 1500 bytes)
  uint32_t payload_len;  // Current payload length
} eth_frame_t;

static const int MAX_ETH_FRAME_SIZE = 1518;
static const int MAC_ADDR_SIZE = 6;

void eth_init(eth_frame_t *frame, const uint8_t *dst_mac,
              const uint8_t *src_mac, uint16_t ethertype) {
  memcpy(frame->dst_mac, dst_mac, MAC_ADDR_SIZE);
  memcpy(frame->src_mac, src_mac, MAC_ADDR_SIZE);
  frame->ethertype = ethertype;
  frame->payload_len = 0;
}

void eth_set_payload(eth_frame_t *frame, const uint8_t *payload,
                     uint32_t length) {
  if (length > 1500) {
    length = 1500;
  }

  memcpy(frame->payload, payload, length);
  frame->payload_len = length;
}

uint32_t eth_serialize(const eth_frame_t *frame, uint8_t *buffer,
                       uint32_t buffer_size) {
  uint32_t min_payload = 46; // 64 - 14 (header) - 4 (FCS)
  uint32_t payload_len = frame->payload_len;

  if (payload_len < min_payload) {
    payload_len = min_payload; // padding
  }

  uint32_t total_len = 14 + payload_len; // Header + payload (FCS added by NIC)

  if (buffer_size < total_len) {
    return 0; // Buffer too small
  }

  // Copy MACs
  memcpy(buffer, frame->dst_mac, 6);
  memcpy(buffer + 6, frame->src_mac, 6);

  // Set eth type (in network byte order)
  buffer[12] = (frame->ethertype >> 8) & 0xFF;
  buffer[13] = frame->ethertype & 0xFF;

  // payload
  memcpy(buffer + 14, frame->payload, frame->payload_len);

  // Zero-fill padding
  if (frame->payload_len < min_payload) {
    memset(buffer + 14 + frame->payload_len, 0,
           min_payload - frame->payload_len);
  }

  return total_len;
}

#ifdef ETH_TEST
int main() {
  // Sample MAC addresses
  uint8_t src_mac[6] = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55};
  uint8_t dst_mac[6] = {0x00, 0x11, 0x22, 0x33, 0x44, 0x66};

  // Sample payload
  uint8_t test_payload[20] = {0};
  for (int i = 0; i < 20; i++) {
    test_payload[i] = i;
  }

  eth_frame_t frame = {0};
  eth_init(&frame, dst_mac, src_mac, 0x0800); // 0x0800 is IPv4
  eth_set_payload(&frame, test_payload, sizeof(test_payload));

  // Serialize to buffer
  uint8_t buffer[MAX_ETH_FRAME_SIZE]; // Max Ethernet frame size (without FCS)
  uint32_t size = eth_serialize(&frame, buffer, sizeof(buffer));

  for (uint32_t i = 0; i < size; i++) {
    printf("%02x ", buffer[i]);
    if ((i + 1) % 16 == 0) {
      printf("\n");
    }
  }
  printf("\n");

  return 0;
}
#endif
