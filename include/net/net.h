/**
 * @file net.h
 * @author Aaron Chan
 * @brief Network interface header file
 */

#ifndef _NET_
#define _NET_

// Intentionally include headers here for getting frame sizes
#include <net/ethernet.h>
#include <net/ipv4.h>
#include <net/udp.h>

/**
 * Initializes the network interface for transmission and reception.
 */
int net_init(void);

/**
 * Transmits an Ethernet frame over the network.
 * 
 * @param frame Pointer to the frame data to be transmitted.
 * @param len Length of the frame data in bytes.
 * @return 0 on success, or -1 on failure.
 */
int net_transmit(const uint8_t *frame, uint16_t len);

/**
 * Receives an Ethernet frame from the network.
 * 
 * @param buffer Pointer to the buffer where the received frame will be stored.
 * @param len Size of the buffer in bytes.
 * @return Number of bytes received, or -1 on failure.
 */
int net_receive(uint8_t *buffer, uint16_t len);

#endif // _NET_
