#ifndef PCI_H_
#define PCI_H_

#include <types.h>

uint8_t pci_find_device_by_id(
		uint16_t vendor_id, uint16_t device_id,
		uint8_t* bus, uint8_t* dev, uint8_t* func,
		void** io_base, uint8_t* irq);

uint8_t pci_find_device_by_class(
		uint8_t base_class, uint8_t sub_class,
		uint8_t* bus, uint8_t* dev, uint8_t* func,
		void** io_base, uint8_t* irq);

#endif
