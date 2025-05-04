#include <common.h>
#include <support.h>
#include <types.h>
#include <x86/ops.h>
#include <cio.h>
#include <sio.h>
#include <pci.h>
#include <hda.h>

// Macros for handling memory mapped IO with byte offsets
#define MMIO_BYTE(ptr, offset) 	((uint8_t*)((char*)(ptr) + (offset)))
#define MMIO_HW(ptr, offset) 	((uint16_t*)((char*)(ptr) + (offset)))
#define MMIO_WORD(ptr, offset) 	((uint32_t*)((char*)(ptr) + (offset)))

#define HDA_GCTL_CRST 	0x1	// Controller reset

// HDA Audio Controller register set
// See: High Definition Audio Specificaiton section 3.3
#pragma pack(push, 1)
typedef struct hda_regset {
	uint16_t 	gcap; 	// Global capabilities
	uint8_t		vmin;	// Minor version
	uint8_t 	vmaj; 	// Major version
	uint16_t	outpay;	// Output payload capability
	uint16_t	inpay;	// Input payload capability

	uint32_t 	gctl; 	// Global control
	uint16_t 	wakeen;	// Wake enable
	uint16_t	wakests;// Wake status
	uint16_t	gsts;	// Global status

	uint32_t	rsvd12;	// Reserved
	uint8_t		rsvd17;	// Reserved

	uint16_t 	outstrmpay;	// Output stream payload capability
	uint16_t 	instrmpay;	// Input stream payload capability
} hda_regset_t;
#pragma pack(pop)

// HDA controller
typedef struct hda {
	hda_regset_t* regs;
} hda_t;

void print_controller_info(hda_t* hda) {
	cio_printf("hda: controller v%d.%d\n", hda->regs->vmaj, hda->regs->vmin);

	cio_printf("hda: capabilties 0x%x\n", hda->regs->gcap);
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

	hda_regset_t* regs = (hda_regset_t*) io_base;

	// Bring the controller into and out of reset
	regs->gctl &= ~HDA_GCTL_CRST;
	do {
		delay(1);
	} while(regs->gctl && HDA_GCTL_CRST);
	delay(1);
	regs->gctl |= HDA_GCTL_CRST;
	do {
		delay(1);
	} while(!(regs->gctl && HDA_GCTL_CRST));
	delay(1); // Additional delay for codecs to reset

	hda_t hda = {
		.regs = (hda_regset_t*) io_base
	};

	print_controller_info(&hda);
}

