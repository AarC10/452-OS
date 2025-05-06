/**
 * @file net.h
 * @author Aaron Chan
 * @brief Abstracts away interfacing with hardware devices for networking
 *        and sending and receiving packets over UDP.  
 */

#include <drivers/intel8255x.h>
#include <net/net.h>

#include <cio.h>
#include <klib.h>
#include <kmem.h>
#include <support.h>
#include <x86/pci.h>

static uint8_t src_mac[ETH_ADDR_LEN] = {0};

int net_init() {
    if (i8255x_init(src_mac)) {
        cio_puts("Failed to initialize i8255x\n");
        return -1;
    }

    cio_puts("i8255x initialized successfully\n");
    
    // Test sending a packet
    const char *test_str = "Hello, OS!";
    const uint16_t test_len = strlen(test_str);

    net_transmit((uint8_t*) test_str, test_len);
    delay(DELAY_5_SEC);

    return -1;
}

int net_transmit(const uint8_t *frame, uint16_t len) {
    uint8_t *buffer = km_page_alloc(1);
    if (!buffer) {
        cio_puts("TX buffer alloc failed\n");
        return -1;
    }
    memcpy(buffer, frame, len);


    // UDP
    udp_packet_t udp;
    const char *message = "testing";
    uint32_t message_len = strlen(message);

    udp_init(&udp, 10000, 11000);
    udp_set_payload(&udp, (const uint8_t *)message, message_len);

    uint32_t src_ip = (192 << 24) | (168 << 16) | (1 << 8) | 100;
    uint32_t dest_ip = (192 << 24) | (168 << 16) | (1 << 8) | 1;

    uint8_t udp_buffer[UDP_MAX_DATAGRAM_SIZE];
    uint32_t udp_size =
        udp_serialize(&udp, udp_buffer, sizeof(udp_buffer), src_ip, dest_ip);

    // IPv4
    ipv4_packet_t ipv4;
    ipv4_init(&ipv4, 0, 1234, 0, 0, IPV4_DEFAULT_TTL, IPV4_PROTO_UDP, src_ip,
              dest_ip);
    ipv4_set_payload(&ipv4, udp_buffer, udp_size);

    uint8_t ipv4_buffer[IPV4_MAX_PACKET_SIZE];
    uint32_t ipv4_size =
        ipv4_serialize(&ipv4, ipv4_buffer, sizeof(ipv4_buffer));

    // Ethernet II
    eth_frame_t eth;
    uint8_t dest_mac[ETH_ADDR_LEN] = {0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF};

    eth_init(&eth, dest_mac, src_mac, ETH_TYPE_IPV4);
    eth_set_payload(&eth, ipv4_buffer, ipv4_size);

    uint32_t eth_size = eth_serialize(&eth, buffer, sizeof(buffer));

    return i8255x_transmit(buffer, eth_size);
}

int net_receive(uint8_t *buffer, uint16_t len) {
    return i8255x_receive(buffer, len);
}
