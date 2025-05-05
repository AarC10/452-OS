#include "cio.h"
#include "x86/pci.h"
#include <net/net.h>
#include <drivers/intel8255x.h>
#include "support.h"

int net_init() {
    if (i8255x_init()) {
        cio_puts("Failed to initialize i8255x\n");
        return -1;
    }

    cio_puts("i8255x initialized successfully\n");
    delay(DELAY_5_SEC);

    return -1;
}
