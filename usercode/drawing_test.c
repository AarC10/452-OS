#ifndef DRAWING_TEST_INC_C_
#define DRAWING_TEST_INC_C_

#include <common.h>
#include "vga_graphics.h"

USERMAIN(drawing_test)
{
    char *name = argv[0] ? argv[0] : "drawing_test";
    char buf[128];

    usprint(buf, "%s: starting drawing test...\n", name);
    swrites(buf);

    // Fill the background with blue (index 1)
    vga_clear(1);

    // Set custom palette color (index 10 = bright green)
    vga_set_palette_color(10, 0, 255, 0);

    // Drawing primitives
    vga_draw_rect(20, 20, 60, 40, 4, 1);     // Filled red rectangle
    vga_draw_rect(100, 20, 60, 40, 15, 0);   // White rectangle outline
    vga_draw_line(0, 0, 319, 199, 14);       // Yellow diagonal line
    vga_draw_circle(160, 100, 30, 11, 0);    // Cyan circle outline
    vga_draw_circle(240, 100, 25, 10, 1);    // Filled green circle (palette index 10)
    vga_draw_triangle(160, 150, 200, 180, 120, 180, 13); // Magenta triangle

    // Let the screen persist for a moment
    sleep(3);

    swrites("drawing_test: done.\n");
    exit(0);
    return 0;
}

#endif // DRAWING_TEST_INC_C_
