// HDA.h - defines for Intel High Definition Audio system

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

// Global default HDA controller
extern hda_t default_hda;

// Discover and initialize a new HDA controller
void hda_init(hda_t* hda);

// Set the volume of a specified codec's node along with it's mute status
void hda_set_volume(hda_t* hda,	uint8_t caddr, uint8_t nid, uint8_t volume,
	bool_t input, bool_t output, bool_t  mute);

