#ifndef COLOR_TEST_INC_C_
#define COLOR_TEST_INC_C_

#include <common.h>
#include "vga/vga_graphics.h"

/**
** User function: color_test
**
** Draws classic VGA vertical color stripes across the screen.
**
** Author: Nicholas Merante <ncm2705@rit.edu>
**
*/

USERMAIN(color_test)
{
    char *name = argv[0] ? argv[0] : "color_test";
    char buf[128];

    usprint(buf, "%s: drawing VGA color stripes\n", name);
    swrites(buf);

    // This function assumes mode 13h (320x200x256) is already active

    const int num_stripes = 16;
    const int stripe_width = VGA_WIDTH / num_stripes;

    for (int i = 0; i < num_stripes; ++i)
    {
        uint8_t color = (uint8_t)i;

        for (int y = 0; y < VGA_HEIGHT; ++y)
        {
            for (int x = i * stripe_width; x < (i + 1) * stripe_width; ++x)
            {
                vga_put_pixel(x, y, color);
            }
        }
    }

    sleep(3);

    exit(0);
    return 0;
}
#endif
