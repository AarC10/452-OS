#include <common.h>
#include <support.h>
#include <types.h>
#include <x86/ops.h>
#include <cio.h>
#include <sio.h>
#include <pci.h>
#include <hda.h>

#define HDA_REG_GCAP 0x00
#define HDA_REG_VMIN 0x02
#define HDA_REG_VMAJ 0x03
#define HDA_REG_GCTL 0x08

// Macros for handling memory mapped IO with byte offsets
#define MMIO_BYTE(ptr, offset) 	((uint8_t*)((char*)(ptr) + (offset)))
#define MMIO_HW(ptr, offset) 	((uint16_t*)((char*)(ptr) + (offset)))
#define MMIO_WORD(ptr, offset) 	((uint32_t*)((char*)(ptr) + (offset)))

// HDA controller
typedef struct hda {
	void* bar;
} hda_t;

void print_controller_info(hda_t* hda) {
	uint8_t vmin, vmaj;

	vmin = *MMIO_BYTE(hda->bar, HDA_REG_VMIN);
	vmaj = *MMIO_BYTE(hda->bar, HDA_REG_VMAJ);

	cio_printf("hda: controller v%d.%d\n", vmaj, vmin);

	uint16_t caps = *MMIO_HW(hda->bar, HDA_REG_GCAP);
	cio_printf("hda: capabilties 0x%x\n", caps);
}

void hda_init() {
	uint8_t bus, device, func, irq;
	void* io_base;

	uint8_t result = pci_find_device(0x8086, 0x2668, &bus, &device, &func, &io_base, &irq);
	if (result == 0) {
		cio_printf("found intel HDA device on bus %d, device %d, func %d, base %x\n",
			bus, device, func, io_base);
	} else {
		cio_puts("error: failed to find intel HDA device\n");
		return;
	}

	// Bring HDA device out of reset
	// outl(io_base + HDA_REG_GCTL, HDA_GCTL_CRST);

	// Wait for CRST to be set (controller ready)
	// uint32_t gctl;
	// do {
	//     delay(1);
	//     gctl = inl(io_base + HDA_REG_GCTL);
	// } while (!(gctl & HDA_GCTL_CRST));

	hda_t hda = {
		.bar = io_base
	};

	print_controller_info(&hda);
}

