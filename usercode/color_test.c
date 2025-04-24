#ifndef COLOR_TEST_INC_C_
#define COLOR_TEST_INC_C_

#include <common.h>
#include "vga_graphics.h"

/**
** User function: color_test
**
** Fills the entire VGA screen with red (color index 4).
**
** Invoked as:  color_test
*/

USERMAIN(color_test)
{
    char *name = argv[0] ? argv[0] : "nobody";
    char buf[128];

    usprint(buf, "%s: filling screen with red\n", name);
    swrites(buf);

    // This function assumes mode 13h (320x200x256) is already active.

    const uint8_t RED = 4; // Standard red index in VGA palette

    for (int y = 0; y < 200; ++y)
    {
        for (int x = 0; x < 320; ++x)
        {
            vga_put_pixel(x, y, RED);
        }
    }

    // Wait a bit so user can see the screen (adjust as needed)
    sleep(2);

    // Optionally exit cleanly
    exit(0);

    return 0;
}
#endif
