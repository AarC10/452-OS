#ifndef DRAWING_TEST_INC_C_
#define DRAWING_TEST_INC_C_

#include <common.h>
#include "vga/vga_graphics.h"

/**
** User function: drawing_test
**
** Draws various VGA primitives to the screen.
**
*/

USERMAIN(drawing_test)
{
    char *name = argv[0] ? argv[0] : "drawing_test";
    char buf[128];

    usprint(buf, "%s: starting drawing test...\n", name);
    swrites(buf);

    // Fill the background with blue
    vga_clear(VGA_COLOR_BLUE);

    // Set custom palette color to green
    vga_set_palette_color(VGA_COLOR_GREEN, 0, 255, 0);

    // Drawing primitives
    vga_draw_rect(20, 20, 60, 40, VGA_COLOR_RED, 1);                        // Filled red rectangle
    vga_draw_rect(100, 20, 60, 40, VGA_COLOR_WHITE, 0);                     // White rectangle outline
    vga_draw_line(0, 0, 319, 199, VGA_COLOR_YELLOW);                        // Yellow diagonal line
    vga_draw_circle(160, 100, 30, VGA_COLOR_CYAN, 0);                       // Cyan circle outline
    vga_draw_circle(240, 100, 25, VGA_COLOR_GREEN, 1);                      // Filled green circle (palette index 10)
    vga_draw_triangle(160, 150, 200, 180, 120, 180, VGA_COLOR_MAGENTA);     // Magenta triangle

    sleep(3);

    swrites("drawing_test: done.\n");
    exit(0);
    return 0;
}

#endif // DRAWING_TEST_INC_C_
