#include <net/ethernet.h>

void eth_init(eth_frame_t *frame, const uint8_t *dest_mac,
              const uint8_t *src_mac, uint16_t ethertype) {
  memcpy(frame->dest_mac, dest_mac, ETH_ADDR_LEN);
  memcpy(frame->src_mac, src_mac, ETH_ADDR_LEN);
  frame->ethertype = ethertype;
  frame->payload_len = 0;
}

void eth_set_payload(eth_frame_t *frame, const uint8_t *payload,
                     uint32_t length) {
  if (length > ETH_MTU) {
    length = ETH_MTU;
  }

  memcpy(frame->payload, payload, length);
  frame->payload_len = length;
}

uint32_t eth_serialize(const eth_frame_t *frame, uint8_t *buffer,
                       uint32_t buffer_size) {
  uint32_t payload_len = frame->payload_len;

  if (payload_len < ETH_MIN_PAYLOAD) {
    payload_len = ETH_MIN_PAYLOAD; // Apply padding
  }

  uint32_t total_len =
      ETH_HEADER_LEN + payload_len; // Header + payload (FCS added by NIC)

  if (buffer_size < total_len) {
    return 0; // Buffer too small
  }

  // Copy destination MAC
  memcpy(buffer, frame->dest_mac, ETH_ADDR_LEN);

  // Copy source MAC
  memcpy(buffer + ETH_ADDR_LEN, frame->src_mac, ETH_ADDR_LEN);

  // Set EtherType (in network byte order)
  buffer[12] = (frame->ethertype >> 8) & 0xFF;
  buffer[13] = frame->ethertype & 0xFF;

  // Copy payload
  memcpy(buffer + ETH_HEADER_LEN, frame->payload, frame->payload_len);

  // Zero-fill padding if needed
  if (frame->payload_len < ETH_MIN_PAYLOAD) {
    memset(buffer + ETH_HEADER_LEN + frame->payload_len, 0,
           ETH_MIN_PAYLOAD - frame->payload_len);
  }

  return total_len;
}
