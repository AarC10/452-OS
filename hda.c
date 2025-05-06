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

// Notable register fields
#define HDA_GCTL_CRST 	0x1	// Controller reset

#define HDA_ICIS_ICB	0x1 // Immediate command busy
#define HDA_ICIS_IRV	0x2	// Immediate result valid

// HDA codec verbs
#define HDA_VERB_PARAM_GET	0xF00	// Get parameter
#define HDA_VERB_AMP_GET	0xB		// Get amplifier gain / mute
#define HDA_VERB_AMP_SET	0x3		// Set amplifier gain / mute
#define HDA_VERB_STRFMT_GET	0xA		// Get stream format

// HDA codec parameters
#define HDA_PARAM_VID 		0x00 // Vendor ID
#define HDA_PARAM_REVID 	0x02 // Revision ID
#define HDA_PARAM_SUBORDCNT	0x04 // Subordinate node count
#define HDA_PARAM_FGTYPE	0x05 // Function group type
#define HDA_PARAM_FGCAPS	0x08 // Function group capabilities
#define HDA_PARAM_AWCAPS	0x09 // Audio widget capabilities

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
	uint16_t	statests;	// State change status (or WAKESTS wake status in the summary)
	uint16_t	gsts;	// Global status

	uint32_t	rsvd12;	// Reserved
	uint16_t	rsvd17;	// Reserved

	uint16_t 	outstrmpay;	// Output stream payload capability
	uint16_t 	instrmpay;	// Input stream payload capability

	uint32_t	rsvd1c;	// Reserved

	uint32_t	intctl; // Interrupt control
	uint32_t	intsts;	// Interrupt status

	uint32_t	rsvd28; // Reserved
	uint32_t	rsvd2c; // Reserved

	uint32_t 	walclk;	// Wall clock counter
	uint32_t 	rsvd34; // Reserved
	uint32_t	ssync; 	// Stream synchronization

	uint32_t	rsvd3c;	// Reserved

	uint32_t	corblbase; 	// CORB lower base address
	uint32_t 	corbubase;	// CORB upper base address
	uint16_t	corbwp;		// CORB write pointer
	uint16_t	corbrp;		// CORB read pointer
	uint8_t		corbctl;	// CORB control
	uint8_t 	corbsts;	// CORB status
	uint8_t		corbsize;	// CORB size
	uint8_t 	rsvd4f;		// Reserved

	uint32_t	rirblbase; 	// RIRB lower base address
	uint32_t 	rirbubase;	// RIRB upper base address
	uint16_t	rirbwp;		// RIRB write pointer
	uint16_t	rintctl; 	// RIRB interrupt count
	uint8_t		rirbctl;	// RIRB control
	uint8_t 	rirbsts;	// RIRB status
	uint8_t		rirbsize;	// RIRB size
	uint8_t 	rsvd5f;		// Reserved

	uint32_t	icoi; 	// Immediate command output interface
	uint32_t	icii;	// Immediate command input interface
	uint16_t	icis; 	// Immediate command status
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

// Send a verb and data to the specified codec / node using the immediate command interface
// If with_response is true, reads response and returns, otherwise returns 0;
uint32_t send_verb_imm(hda_t* hda, uint8_t caddr, uint8_t nid,
	uint16_t verb, uint16_t data, bool_t with_response) {
	// Wait for the immediate interface to be available
	while (hda->regs->icis & HDA_ICIS_ICB) {
		delay(1);
	}

	caddr &= 0xF;

	// Write the command
	if (verb > 0xF) {
		// 12-bit verb with 8 bit payload
		hda->regs->icoi = (caddr << 28) | (nid << 20) | (verb << 8) | (data & 0xFF);
	} else {
		// 4-bit verb with 16 bit payload
		hda->regs->icoi = (caddr << 28) | (nid << 20) | (verb << 16) | data;
	}

	if (with_response) {
		hda->regs->icis |= HDA_ICIS_ICB | HDA_ICIS_IRV;
	} else {
		hda->regs->icis |= HDA_ICIS_ICB;
	}

	while(hda->regs->icis & HDA_ICIS_ICB) {
		delay(1);
	}

	// Read the result
	if (with_response) {
		while((hda->regs->icis & HDA_ICIS_IRV) == 0){
			delay(1);
		}
		return hda->regs->icii;
	} else {
		return 0;
	}
}

// Get the parameter of a specified codec using the immediate command interface
uint32_t get_param(hda_t* hda, uint8_t caddr, uint8_t nid, uint8_t param) {
	return send_verb_imm(hda, caddr, nid, HDA_VERB_PARAM_GET, param, true);
}

void enumerate_codecs(hda_t* hda) {
	for (uint8_t i = 0; i < 15; i++) {
		if (hda->regs->statests & ((uint8_t)0x1 << i)) {
			uint32_t result = get_param(hda, i, 0, HDA_PARAM_VID);
			uint16_t vendor_id = result >> 16;
			uint16_t device_id = result & 0xFFFF;

			result = get_param(hda, i, 0, HDA_PARAM_SUBORDCNT);
			uint8_t start = result >> 16;
			uint8_t count = result & 0xFF;

			cio_printf("hda: codec present on caddr %d, vendor ID %04x:%04x, subordinates %d-%d\n", i, vendor_id, device_id, start, start+count-1);

			// Walk subordiante function groups
			for (uint8_t j = 0; j < count; j++) {
				result = get_param(hda, i, j + start, HDA_PARAM_FGTYPE);
				uint8_t fg_type = result & 0xFF;

				result = get_param(hda, i, j + start, HDA_PARAM_SUBORDCNT);
				uint8_t s_start = result >> 16;
				uint8_t s_count = result & 0xFF;
				cio_printf("hda: |-> subordinate %d fg type %d has subordinates %d-%d\n", j + count, fg_type, s_start, s_start + s_count - 1);

				if (fg_type == 1) {
					result = get_param(hda, i, j + start, HDA_PARAM_FGCAPS);
					cio_printf("hda:     audio function group caps 0x%08x\n", result);
					for (uint8_t wi = s_start; wi < s_start + s_count; wi++) {
						result = get_param(hda, i, wi, HDA_PARAM_AWCAPS);
						uint8_t w_type = result >> 20;
						cio_printf("hda:     |-> widget %d type %x caps 0x%08x\n", wi, w_type, result);

						// Get the widget's amplifier status
						result = send_verb_imm(hda, i, wi, HDA_VERB_AMP_GET, 0x0, true);
						uint8_t in_gain = result & 0x7F;
						bool_t in_mute = result >> 7;
						result = send_verb_imm(hda, i, wi, HDA_VERB_AMP_GET, 1 << 15, true);
						uint8_t out_gain = result & 0x7F;
						bool_t out_mute = result >> 7;
						cio_printf("hda:         in: %s %d, out: %s %d\n",
							in_mute ? "unmute" : "muted", in_gain, out_mute ? "unmute" : "muted", out_gain);
					}
				}
			}
		}
	}
}

void hda_init() {
	uint8_t bus, device, func, irq;
	void* io_base;

	uint8_t result = pci_find_device_by_class(0x04, 0x03, &bus, &device, &func, &io_base, &irq);
	if (result == 0) {
		cio_printf("found intel HDA device on bus %d, device %d, func %d, base %08x\n",
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
	} while(regs->gctl & HDA_GCTL_CRST);
	delay(1);
	regs->gctl |= HDA_GCTL_CRST;
	do {
		delay(1);
	} while(!(regs->gctl & HDA_GCTL_CRST));
	delay(1); // Additional delay for codecs to reset

	hda_t hda = {
		.regs = (hda_regset_t*) io_base
	};

	print_controller_info(&hda);
	enumerate_codecs(&hda);
}

