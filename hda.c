// HDA.c - driver for Intel High Definition Audio system

#include <common.h>
#include <support.h>
#include <types.h>
#include <x86/ops.h>
#include <x86/pci.h>
#include <cio.h>
#include <sio.h>
#include <hda.h>

// Glocal default HDA controller
hda_t default_hda;

static inline void hda_write32(hda_t* h, uint32_t off, uint32_t val) {
	*(volatile uint32_t*)( (uint8_t*)h->regs + off ) = val;
}

static inline uint32_t hda_read32(hda_t* h, uint32_t off) {
	return *(volatile uint32_t*)( (uint8_t*)h->regs + off );
}


// Given a handle to an HDA conteroller, print it's version and capabilities
void print_controller_info(hda_t* hda) {
	cio_printf("hda: controller v%d.%d, capabilities: 0x%x\n",
		hda->regs->vmaj, hda->regs->vmin, hda->regs->gcap);
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

	// Indicate a message is ready to be sent, and optionally
	// mark ready to receiving if receiving.
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

// Walk through codec node tree and print out codec / function group / widget details.
void enumerate_codecs(hda_t* hda) {
	for (uint8_t i = 0; i < 15; i++) {
		if (hda->regs->statests & ((uint8_t)0x1 << i)) {
			uint32_t result = get_param(hda, i, 0, HDA_PARAM_VID);
			uint16_t vendor_id = result >> 16;
			uint16_t device_id = result & 0xFFFF;

			result = get_param(hda, i, 0, HDA_PARAM_SUBORDCNT);
			uint8_t start = result >> 16;
			uint8_t count = result & 0xFF;

			cio_printf(
				"hda: codec present on caddr %d, vendor ID %04x:%04x, subordinates %d-%d\n",
				i, vendor_id, device_id, start, start+count-1
			);

			// Walk subordiante function groups
			for (uint8_t j = 0; j < count; j++) {
				result = get_param(hda, i, j + start, HDA_PARAM_FGTYPE);
				uint8_t fg_type = result & 0xFF;

				result = get_param(hda, i, j + start, HDA_PARAM_SUBORDCNT);
				uint8_t s_start = result >> 16;
				uint8_t s_count = result & 0xFF;
				cio_printf(
					"hda: |-> subordinate %d fg type %d has subordinates %d-%d\n",
					j + count, fg_type, s_start, s_start + s_count - 1
				);

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

// Discover and intialize a new HDA controller, printing it's details.
void hda_init(hda_t* hda) {
	struct pci_func pcif;

	uint8_t result = pci_find_device_by_class(0x04, 0x03, &pcif);
	if (result == 0) {
		cio_printf("found intel HDA device on bus %d, device %d, func %d\n",
			pcif.bus.busno, pcif.device, pcif.function);
	} else {
		cio_puts("error: failed to find intel HDA device\n");
		return;
	}

	hda_regset_t* regs = (hda_regset_t*) pcif.base_addr[0];

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

	hda->regs = regs;

	print_controller_info(hda);
	enumerate_codecs(hda);
}

// Set the volume of the specified codec's node.
void hda_set_volume(hda_t* hda, uint8_t caddr, uint8_t nid, uint8_t volume,
	bool_t input, bool_t output, bool_t mute)
{
	// payload: bits[13:12] - set left and right, bit7 = mute, bits[6:0] = gain
	uint16_t payload = ((output ? 1 : 0) << 15) | ((input ? 1 : 0) << 14) | (0x3 << 12)
		| ((mute ? 1 : 0) << 7) | (volume & 0x7F);

	send_verb_imm(hda, caddr, nid, HDA_VERB_AMP_SET,
			payload, false);
}

int hda_setup_playback_stream(hda_t* hda, uint8_t stream,
		void* bdl_addr, uint16_t lvi, uint16_t fmt)
{
	// stop stream & clear status
	hda_write32(hda, HDA_SD_CTL(stream), 0);
	hda_write32(hda, HDA_SD_STS(stream),
			HDA_SD_STS_BDLT | HDA_SD_STS_FIFORDY);

	// program buffer‐descriptor list address
	hda_write32(hda, HDA_SD_BDLPL(stream), (uint32_t) bdl_addr);

	// last valid index: number_of_entries–1
	hda_write32(hda, HDA_SD_LVI(stream), lvi);

	// stream format
	hda_write32(hda, HDA_SD_FMT(stream), fmt);

	// start DMA: run + IRQ on completion
	hda_write32(hda, HDA_SD_CTL(stream),
			HDA_SD_CTL_RUN | HDA_SD_CTL_IOCE);

	return 0;
}
