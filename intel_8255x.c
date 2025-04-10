#include "drivers/intel_8255x.h"
#include <common.h>
#include <types.h>
#include <x86/ops.h>

static uint32_t pci_read_config(int bus, int device, int func, int offset) {
  uint32_t address =
      (1 << 31)          /* Enable bit */
      | (bus << 16)      /* Bus number */
      | (device << 11)   /* Device number */
      | (func << 8)      /* Function number */
      | (offset & 0xFC); /* Register number (must be 4-byte aligned) */

  outl(0xCF8, address); /* Write address to PCI config space */
  return inl(0xCFC);    /* Read data from PCI config space */
}

int detect_intel_8255x() {
  int bus;
  int dev;
  int func;
  uint32_t val;
  int found = 0;

  /* Initialize the device state */
  // e100_state.initialized = 0;
  // e100_state.rx_ready = 0;
  // initlock(&e100_state.lock, "e100");

  /* Set up the function pointers */
  // e100_state.dev.read = xv6_read;
  // e100_state.dev.write = xv6_write;

  /* Search PCI bus for Intel 8255x device */
  for (bus = 0; bus < 256 && !found; bus++) {
    for (dev = 0; dev < 32 && !found; dev++) {
      for (func = 0; func < 8 && !found; func++) {
        val = pci_read_config(bus, dev, func, 0);
        if ((val & 0xFFFF) == 0x8086) { /* Intel vendor ID */
          uint16_t device_id = (val >> 16) & 0xFFFF;

          if (device_id == 0x1227 || /* 82557 */
              device_id == 0x1229) { /* 82559 */

            cio_printf(
                "e100: found Intel 8255x at bus %d, device %d, function %d\n",
                bus, dev, func);

            // Get I/O base address
            uint32_t io_bar = pci_read_config(bus, dev, func, 0x10);
            uint32_t io_base = io_bar & ~0x3; /* Mask off the low bits */

            // Get interrupt line
            uint8_t irq = pci_read_config(bus, dev, func, 0x3C) & 0xFF;

            cio_printf("e100: I/O base = 0x%x, IRQ = %d\n", io_base, irq);

            return 0;
          }
        }
      }
    }
  }
}
