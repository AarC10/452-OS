#include <cio.h>
#include <x86/ops.h>
#include <x86/pci.h>

static void conf_set_addr(uint32_t bus, uint32_t dev, uint32_t func,
                          uint32_t offset) {
    uint32_t value =
        (1 << 31) | (bus << 16) | (dev << 11) | (func << 8) | (offset & 0xFC);
    outl(PCI_CONFIG_ADDRESS_REGISTER, value);
}

static uint32_t conf_read(struct pci_func *pcif, uint32_t offset) {
    conf_set_addr(pcif->bus.busno, pcif->device, pcif->function, offset);
    return inl(PCI_CONFIG_DATA_REGISTER);
}

static void conf_write(struct pci_func *pcif, uint32_t offset, uint32_t v) {
    conf_set_addr(pcif->bus.busno, pcif->device, pcif->function, offset);
    outl(PCI_CONFIG_DATA_REGISTER, v);
}

uint32_t pci_read_config(uint8_t bus, uint8_t device, uint8_t func,
                         uint8_t offset) {
    uint32_t address = (1 << PCI_CONFIG_ENABLE_BIT_OFFSET) |
                       (bus << PCI_CONFIG_BUS_NUMBER_OFFSET) |
                       (device << PCI_CONFIG_DEV_NUMBER_OFFSET) |
                       (func << PCI_CONFIG_FUN_NUMBER_OFFSET) | (offset & 0xFC);

    outl(PCI_CONFIG_ADDRESS_REGISTER, address);
    return inl(PCI_CONFIG_DATA_REGISTER);
}

int pci_search_for_device(uint16_t vendor_id, uint16_t device_id,
                          struct pci_func *pcif) {
    for (int current_bus = 0; current_bus < PCI_MAX_BUSES; current_bus++) {
        for (int current_dev = 0; current_dev < PCI_MAX_DEVICES_PER_BUS;
             current_dev++) {
            for (int current_func = 0; current_func < PCI_MAX_FUNCTIONS;
                 current_func++) {
                uint32_t result = pci_read_config(current_bus, current_dev,
                                                  current_func, 0x00);
                uint16_t res_vendor_id = (result & 0xFFFF);
                uint16_t res_device_id = (result >> 16) & 0xFFFF;
                if (res_vendor_id == vendor_id && res_device_id == device_id) {
                    pcif->bus.busno = current_bus;
                    pcif->device = current_dev;
                    pcif->function = current_func;
                    pci_func_enable(pcif);  // ensure BARs can be probed
                    return 0;
                }
            }
        }
    }
    return -1;
}

void pci_func_enable(struct pci_func *pcif) {
    // Enable memory + bus master
    uint16_t cmd =
        pci_read_config(pcif->bus.busno, pcif->device, pcif->function, 0x04) &
        0xFFFF;
    cmd |= (1 << 1) | (1 << 2);  // memory + bus master
    conf_write(pcif, 0x04, cmd);

    uint32_t bar_width = 0;
    for (uint32_t bar = PCI_MAP_REG_START; bar < PCI_MAP_REG_END;
         bar += bar_width) {
        uint32_t old_val = conf_read(pcif, bar);
        bar_width = 4;

        conf_write(pcif, bar, 0xFFFFFFFF);
        uint32_t new_val = conf_read(pcif, bar);
        conf_write(pcif, bar, old_val);  // restore original

        if (new_val == 0) continue;

        int reg_num = PCI_MAP_REG_NUM(bar);
        uint32_t base, size;

        if (PCI_MAP_REG_TYPE(new_val) == PCI_MAP_REG_TYPE_MEM) {
            if (PCI_MAP_REG_MEM_TYPE(new_val) == PCI_MAP_REG_MEM_TYPE_64BIT)
                bar_width = 8;
            size = PCI_MAP_REG_MEM_SIZE(new_val);
            base = PCI_MAP_REG_MEM_ADDR(old_val);
        } else {
            size = PCI_MAP_REG_IO_SIZE(new_val);
            base = PCI_MAP_REG_IO_ADDR(old_val);
        }

        pcif->base_addr[reg_num] = base;
        pcif->size[reg_num] = size;

        cio_printf("BAR%d = 0x%08x (size = 0x%x)\n", reg_num, base, size);
    }

    cio_printf("PCI function %02x:%02x.%d enabled\n", pcif->bus.busno,
               pcif->device, pcif->function);
}
