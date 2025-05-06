/**
 * @file        pci.h
 *
 * @author      Aaron Chan
 *
 * @brief       PCI interface. See https://wiki.osdev.org/PCI for more details
 */

#ifndef PCI_H_
#define PCI_H_

#include "types.h"

// PCI Constants
#define PCI_MAX_BUSES 256
#define PCI_MAX_DEVICES_PER_BUS 32
#define PCI_MAX_FUNCTIONS 8
// Addresses
#define PCI_CONFIG_ADDRESS_REGISTER 0xCF8
#define PCI_CONFIG_DATA_REGISTER 0xCFC

// PCI Configuration Offsets
#define PCI_CONFIG_ENABLE_BIT_OFFSET 31
#define PCI_CONFIG_BUS_NUMBER_OFFSET 16
#define PCI_CONFIG_DEV_NUMBER_OFFSET 11
#define PCI_CONFIG_FUN_NUMBER_OFFSET 8

// PCI Command and Status Register
#define PCI_COMMAND_STATUS_REG 0x04
#define PCI_COMMAND_SHIFT 0
#define PCI_COMMAND_MASK 0xffff
#define PCI_STATUS_SHIFT 16
#define PCI_STATUS_MASK 0xffff

// PCI Enables
#define PCI_COMMAND_IO_ENABLE (1 << 0)
#define PCI_COMMAND_MEM_ENABLE (1 << 1)
#define PCI_COMMAND_MASTER_ENABLE (1 << 2)
#define PCI_COMMAND_SPECIAL_ENABLE (1 << 3)
#define PCI_COMMAND_INVALIDATE_ENABLE (1 << 4)

// Mapping Registers
#define PCI_MAP_REG_START 0x10
#define PCI_MAP_REG_END 0x28
#define PCI_MAP_REG_TYPE_MASK 0x00000001
#define PCI_MAP_REG_TYPE_MEM 0x00000000
#define PCI_MAP_REG_TYPE_IO 0x00000001
#define PCI_MAP_REG_ROM_ENABLE 0x00000001
#define PCI_MAP_REG_TYPE(mr) ((mr) & PCI_MAP_REG_TYPE_MASK)

#define PCI_MAP_REG_MEM_TYPE_MASK 0x00000006
#define PCI_MAP_REG_MEM_TYPE(mr) ((mr) & PCI_MAP_REG_MEM_TYPE_MASK)

#define PCI_MAP_REG_MEM_TYPE_32BIT 0x00000000
#define PCI_MAP_REG_MEM_TYPE_32BIT_1M 0x00000002
#define PCI_MAP_REG_MEM_TYPE_64BIT 0x00000004

#define PCI_MAP_REG_NUM(offset) (((uint_t)(offset) - PCI_MAP_REG_START) / 4)

#define PCI_MAP_REG_MEM_ADDR_MASK 0xfffffff0
#define PCI_MAP_REG_MEM_ADDR(mr) ((mr) & PCI_MAP_REG_MEM_ADDR_MASK)
#define PCI_MAP_REG_MEM_SIZE(mr) (PCI_MAP_REG_MEM_ADDR(mr) & -PCI_MAP_REG_MEM_ADDR(mr))

#define PCI_MAP_REG_MEM64_ADDR_MASK 0xfffffffffffffff0ULL
#define PCI_MAP_REG_MEM64_ADDR(mr) ((mr) & PCI_MAP_REG_MEM64_ADDR_MASK)
#define PCI_MAP_REG_MEM64_SIZE(mr) (PCI_MAP_REG_MEM64_ADDR(mr) & -PCI_MAP_REG_MEM64_ADDR(mr))

#define PCI_MAP_REG_IO_ADDR_MASK 0xfffffffc
#define PCI_MAP_REG_IO_ADDR(mr) ((mr) & PCI_MAP_REG_IO_ADDR_MASK)
#define PCI_MAP_REG_IO_SIZE(mr) (PCI_MAP_REG_IO_ADDR(mr) & -PCI_MAP_REG_IO_ADDR(mr))

// Product
#define PCI_PRODUCT_SHIFT 16
#define PCI_PRODUCT_MASK 0xffff
#define PCI_PRODUCT(id) (((id) >> PCI_PRODUCT_SHIFT) & PCI_PRODUCT_MASK)

// Vendor
#define PCI_VENDOR_SHIFT 0
#define PCI_VENDOR_MASK 0xffff
#define PCI_VENDOR(id) (((id) >> PCI_VENDOR_SHIFT) & PCI_VENDOR_MASK)

enum pci_class_codes {
    PCI_UNCLASSIFIED = 0x0,
    PCI_MASS_STORAGE_CONTROLLER = 0x1,
    PCI_NETWORK_CONTROLLER = 0x2,
    PCI_DISPLAY_CONTROLLER = 0x3,
    PCI_MULTIMEDIA_CONTROLLER = 0x5,
    PCI_CLASS_CODES_COUNT,
    // Note there are more, but unknown if we are using the rest
    // Also, currently only one in use for this OS is most likely only net
    // ctrler
};

enum pci_header_type {
    PCI_HEADER_BAR0 = 0x10,
};

struct pci_bus {
    struct pci_func *parent;
    uint32_t busno;
};

struct pci_func {
    struct pci_bus bus;       // Parent bus the device is on
    uint32_t id;       // Device ID
    uint8_t device;    // Device number
    uint8_t function;  // Function number
    uint32_t base_addr[6];  // Base address registers
    uint32_t size[6]; // Size of the base address registers
    uint32_t class; // Class code
    uint8_t irq_line; // Interrupt line
};

/**
 * Brute force search for where a specific device is located based on
 * it's vendor and device IDs.
 * @param[in] vendor_id the id of the vendor
 * @param[in] device_id the id of the device
 * @param[out] bus the bus the PCI device is on
 * @param[out] dev the device number of the bus the PCI device is on
 * @param[out] func the function of the PCI device
 *
 * @return 1 if found. 0 if not found
 */
int pci_find_device_by_id(uint16_t vendor_id, uint16_t device_id, struct pci_func *pcif);

/**
 * Brute force search for where a specific device is located based on
 * it's base class and sub class.
 * @param[in] vendor_id the id of the vendor
 * @param[in] device_id the id of the device
 * @param[out] pci_func pointer to PCI function
 *
 * @return 0 if found, otherwise -1
 */
int pci_find_device_by_class(uint8_t base_class, uint8_t sub_class, struct pci_func *pcif);

/**
 * Read the configuration for a PCI device
 * @param[in] bus the bus number
 * @param[in] device the device number
 * @param[in] func the function number
 * @param[in] offset the 4-byte register number
 *
 * @return PCI config space data
 */
uint32_t pci_read_config(uint8_t bus, uint8_t device, uint8_t func,
                         uint8_t offset);
// uint32_t pci_read_config(int bus, int device, int func, int offset);

void pci_func_enable(struct pci_func *pcif);

#endif
