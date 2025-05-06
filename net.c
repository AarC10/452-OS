#include <drivers/intel8255x.h>
#include <net/net.h>

#include "cio.h"
#include "klib.h"
#include "net/ethernet.h"
#include "net/ipv4.h"
#include "net/udp.h"
#include "support.h"
#include "x86/pci.h"

void test_udp_over_ip_over_ethernet() {
    uint8_t buffer[ETH_MAX_FRAME_SIZE] = {0};

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
    uint8_t src_mac[ETH_ADDR_LEN] = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55};
    uint8_t dest_mac[ETH_ADDR_LEN] = {0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF};

    eth_init(&eth, dest_mac, src_mac, ETH_TYPE_IPV4);
    eth_set_payload(&eth, ipv4_buffer, ipv4_size);

    uint32_t eth_size = eth_serialize(&eth, buffer, sizeof(buffer));

    i8255x_transmit(buffer, eth_size);
}

int net_init() {
    if (i8255x_init()) {
        cio_puts("Failed to initialize i8255x\n");
        return -1;
    }

    cio_puts("i8255x initialized successfully\n");
    

    // for (int i = 0; i < 100; i++) {
        // test_udp_over_ip_over_ethernet();
        // cio_printf("Sent packet %d\n", i);
        // delay(DELAY_1_SEC);
    // }



    delay(DELAY_5_SEC);

    return -1;
}
