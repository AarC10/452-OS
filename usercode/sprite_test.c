#ifndef SPRITE_TEST_C_
#define SPRITE_TEST_C_

#include <common.h>
#include "vga_graphics.h"

// 8×8 checkerboard pattern: palette index 1 squares on transparent (0)
static const uint8_t checker8[8 * 8] = {
    1, 0, 1, 0, 1, 0, 1, 0,
    0, 1, 0, 1, 0, 1, 0, 1,
    1, 0, 1, 0, 1, 0, 1, 0,
    0, 1, 0, 1, 0, 1, 0, 1,
    1, 0, 1, 0, 1, 0, 1, 0,
    0, 1, 0, 1, 0, 1, 0, 1,
    1, 0, 1, 0, 1, 0, 1, 0,
    0, 1, 0, 1, 0, 1, 0, 1};

USERMAIN(sprite_test)
{
    swrites("sprite_test: bouncing checker with delays...\n");

    // Start near center
    int x = (VGA_WIDTH - 8) / 2;
    int y = (VGA_HEIGHT - 8) / 2;
    int dx = 2;
    int dy = 1;
    const int w = 8, h = 8;
    int toggle = 0;

    while (1)
    {
        // Flash background to visualize frame timing
        vga_clear_buf(toggle ? 8 : 9);
        toggle = !toggle;

        // Draw sprite
        vga_blit(checker8, w, h, x, y, 0);
        vga_render();

        // Update position and bounce
        x += dx;
        if (x <= 0 || x + w >= VGA_WIDTH)
            dx = -dx;
        y += dy;
        if (y <= 0 || y + h >= VGA_HEIGHT)
            dy = -dy;

        // Pause half a second
        vga_sleep_ms(500);
    }

    return 0;
}

#endif // SPRITE_TEST_C_
