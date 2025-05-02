#include "cio.h"
#include "x86/pci.h"
#include <net/net.h>

int net_init() {
    struct pci_func pcif;

    if (pci_search_for_device(0x8086, 0x1229, &pcif) == 0) {
      usprint("Detected\n");
      return 0;
    } else {
      usprint("Not detected\n");
  }

    return -1;
}
