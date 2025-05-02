#ifndef NETWORK_LAYER_H
#define NETWORK_LAYER_H

#include "include/net/ethernet.h"
#include "include/net/ipv4.h"
#include "include/net/udp.h"
#include "types.h"

// Network Layer Interface

// Generic buffer structure for packet data
typedef struct {
  uint8_t *data;     // Pointer to buffer data
  uint32_t length;   // Length of data in buffer
  uint32_t capacity; // Total capacity of buffer
} network_buffer_t;

// Network layer initialization parameters
typedef struct {
  uint8_t mac_addr[ETH_ADDR_LEN]; // MAC address for this device
  uint32_t ip_addr;               // IPv4 address for this device
  uint16_t mtu;                   // Maximum transmission unit
} network_params_t;

// Function pointer types for common protocol operations
typedef void (*init_fn)(void *packet, ...);
typedef void (*set_payload_fn)(void *packet, const uint8_t *payload,
                               uint32_t length);
typedef uint32_t (*serialize_fn)(const void *packet, uint8_t *buffer,
                                 uint32_t buffer_size, ...);

// Network layer interface with function pointers for each protocol layer
typedef struct {
  // Network parameters
  network_params_t params;

  // Ethernet Layer
  init_fn eth_init;               // Initialize Ethernet frame
  set_payload_fn eth_set_payload; // Set Ethernet payload
  serialize_fn eth_serialize;     // Serialize Ethernet frame

  // IPv4 Layer
  init_fn ipv4_init;               // Initialize IPv4 packet
  set_payload_fn ipv4_set_payload; // Set IPv4 payload
  serialize_fn ipv4_serialize;     // Serialize IPv4 packet

  // UDP Layer
  init_fn udp_init;               // Initialize UDP packet
  set_payload_fn udp_set_payload; // Set UDP payload
  serialize_fn udp_serialize;     // Serialize UDP packet

  // Complete Stack Functions
  int (*send_udp_packet)(struct network_layer_t *net, uint16_t src_port,
                         uint16_t dest_port, uint32_t dest_addr,
                         const uint8_t *dest_mac, const void *data,
                         uint32_t length);

  int (*receive_packet)(struct network_layer_t *net, network_buffer_t *buffer);

  // Status Information
  uint32_t packets_sent;
  uint32_t packets_received;
  uint32_t packets_dropped;
} network_layer_t;

/*
 * Initialize the network layer
 *
 * @param params Initialization parameters
 * @return Pointer to the network layer interface, or NULL on failure
 */
network_layer_t *network_layer_init(const network_params_t *params);

/*
 * Free resources used by the network layer
 *
 * @param layer Pointer to the network layer interface
 */
void network_layer_cleanup(network_layer_t *layer);

#endif // NETWORK_LAYER_H
