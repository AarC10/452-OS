// pci.c
#include <cio.h>
#include <x86/ops.h>
#include <x86/pci.h>

#define PCI_CONFIG_ADDRESS 0xCF8
#define PCI_CONFIG_DATA    0xCFC

static void conf_set_addr(uint32_t bus, uint32_t dev, uint32_t func,
                          uint32_t offset) {
    uint32_t addr = (1U << 31) | (bus << PCI_CONFIG_BUS_NUMBER_OFFSET) |
                    (dev << PCI_CONFIG_DEV_NUMBER_OFFSET) |
                    (func << PCI_CONFIG_FUN_NUMBER_OFFSET) | (offset & 0xFC);
    outl(PCI_CONFIG_ADDRESS_REGISTER, addr);
}

static uint32_t conf_read(struct pci_func *pcif, uint32_t offset) {
    conf_set_addr(pcif->bus.busno, pcif->device, pcif->function, offset);
    return inl(PCI_CONFIG_DATA_REGISTER);
}

static void conf_write(struct pci_func *pcif, uint32_t offset, uint32_t value) {
    conf_set_addr(pcif->bus.busno, pcif->device, pcif->function, offset);
    outl(PCI_CONFIG_DATA_REGISTER, value);
}

uint32_t pci_read_config(uint8_t bus, uint8_t device, uint8_t function,
                         uint8_t offset) {
    uint32_t addr = (1U << PCI_CONFIG_ENABLE_BIT_OFFSET) |
                    (bus << PCI_CONFIG_BUS_NUMBER_OFFSET) |
                    (device << PCI_CONFIG_DEV_NUMBER_OFFSET) |
                    (function << PCI_CONFIG_FUN_NUMBER_OFFSET) |
                    (offset & 0xFC);
    outl(PCI_CONFIG_ADDRESS_REGISTER, addr);
    return inl(PCI_CONFIG_DATA_REGISTER);
}

int pci_find_device_by_id(uint16_t vendor_id, uint16_t device_id,
                          struct pci_func *pcif) {
    for (int b = 0; b < PCI_MAX_BUSES; b++) {
        for (int d = 0; d < PCI_MAX_DEVICES_PER_BUS; d++) {
            for (int f = 0; f < PCI_MAX_FUNCTIONS; f++) {
                uint32_t v = pci_read_config(b, d, f, 0x00);
                if ((v & 0xFFFF) == vendor_id &&
                    ((v >> 16) & 0xFFFF) == device_id) {
                    pcif->bus.busno = b;
                    pcif->device = d;
                    pcif->function = f;
                    pci_func_enable(pcif);
                    return 0;
                }
            }
        }
    }
    return -1;
}

/**
 * Given the provided class code, return the bus, device, and func numbers
 * of the first found matching PCI device.
 */
int pci_find_device_by_class(uint8_t base_class, uint8_t sub_class,
	struct pci_func *pcif) {
	for (uint8_t b = 0; b < PCI_MAX_BUSES; b++) {
		for (uint8_t d = 0; d < PCI_MAX_DEVICES_PER_BUS; d++) {
			for (uint8_t f = 0; f < PCI_MAX_FUNCTIONS; f++) {
				uint32_t found_class = pci_read_config(b, d, f, 0x8) >> 8;
				uint8_t found_base = found_class >> 16;
				uint8_t found_sub = (found_class >> 8) & 0xFF;

				if(found_base == base_class && found_sub == sub_class) {
					pcif->bus.busno = b;
					pcif->device = d;
					pcif->function = f;

					pci_func_enable(pcif);
					return 0;
				}
			}
		}
	}

	return -1;
}

void pci_func_enable(struct pci_func *pcif) {
    // Enable memory space + bus mastering
    uint16_t cmd =
        pci_read_config(pcif->bus.busno, pcif->device, pcif->function, 0x04) &
        0xFFFF;
    cmd |= PCI_COMMAND_MEM_ENABLE | PCI_COMMAND_MASTER_ENABLE;
    conf_write(pcif, 0x04, cmd);

    // Probe BARs
    uint32_t bar_width = 0;
    for (uint32_t bar = PCI_MAP_REG_START; bar < PCI_MAP_REG_END;
         bar += bar_width) {
        uint32_t oldv = conf_read(pcif, bar);
        bar_width = 4;

        conf_write(pcif, bar, 0xFFFFFFFF);
        uint32_t newv = conf_read(pcif, bar);
        conf_write(pcif, bar, oldv);

        if (newv == 0) continue;

        int reg = PCI_MAP_REG_NUM(bar);
        uint32_t base, size;
        if (PCI_MAP_REG_TYPE(newv) == PCI_MAP_REG_TYPE_MEM) {
            if (PCI_MAP_REG_MEM_TYPE(newv) == PCI_MAP_REG_MEM_TYPE_64BIT)
                bar_width = 8;
            size = PCI_MAP_REG_MEM_SIZE(newv);
            base = PCI_MAP_REG_MEM_ADDR(oldv);
        } else {
            size = PCI_MAP_REG_IO_SIZE(newv);
            base = PCI_MAP_REG_IO_ADDR(oldv);
        }

        pcif->base_addr[reg] = base;
        pcif->size[reg] = size;
        cio_printf("  BAR%d = 0x%08x (size=0x%x)\n", reg, base, size);
    }

    cio_printf(
        "PCI %02x:%02x.%d enabled (CMD=0x%04x)\n", pcif->bus.busno,
        pcif->device, pcif->function,
        pci_read_config(pcif->bus.busno, pcif->device, pcif->function, 0x04));
}

