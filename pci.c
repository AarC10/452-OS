#include <common.h>
#include <types.h>
#include <x86/ops.h>
#include <cio.h>

#include <pci.h>

#define PCI_CONFIG_ADDRESS 0xCF8
#define PCI_CONFIG_DATA    0xCFC

#define PCI_NUM_BUSES 	256
#define PCI_NUM_DEVICES	32
#define PCI_NUM_FUNCS 	8

static uint32_t pci_read_config(uint8_t bus, uint8_t device, uint8_t func, uint8_t reg_num)
{
	uint32_t address =
		(1 << 31)          	/* Enable bit */
		| (bus << 16)      	/* Bus number */
		| (device << 11)   	/* Device number */
		| (func << 8)      	/* Function number */
		| (reg_num & 0xFC); /* Register number (must be 4-byte aligned) */

	outl(PCI_CONFIG_ADDRESS, address); 	/* Write address to PCI config space */
	return inl(PCI_CONFIG_DATA);    	/* Read data from PCI config space */
}

/**
 * Given the provided vendor_id and device_id, return the bus, device, and func numbers
 * of the first found matching PCI device.
 */
uint8_t pci_find_device(
		uint16_t vendor_id, uint16_t device_id, 
		uint8_t* bus, uint8_t* dev, uint8_t* func,
		void** io_base, uint8_t* irq)
{
	for (*bus = 0; *bus < PCI_NUM_BUSES; (*bus)++) {
		for (*dev = 0; *dev < PCI_NUM_DEVICES; (*dev)++) {
			for (*func = 0; *func < PCI_NUM_FUNCS; (*func)++) {
				uint32_t val = pci_read_config(*bus, *dev, *func, 0);
				if ((val & 0xFFFF) == vendor_id) {
					uint16_t found_device_id = (val >> 16) & 0xFFFF;

					if (device_id == found_device_id) {
						// Get I/O base address
						uint32_t io_bar = pci_read_config(*bus, *dev, *func, 0x10);
						*io_base = (void*)(io_bar & ~0x3); /* Mask off the low bits */

						// Get interrupt line
						*irq = pci_read_config(*bus, *dev, *func, 0x3C) & 0xFF;

						return 0;
					}
				}
			}
		}
	}
	return 1;
}
