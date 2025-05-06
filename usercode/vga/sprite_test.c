#ifndef SPRITE_TEST_C_
#define SPRITE_TEST_C_

#include <common.h>
#include "vga/vga_graphics.h"

/**
** User function: sprite_test
**
** Bouncing sprite demo to show double buffering and sprite blitter.
**
*/

// 8×8 smiley face pattern: palette index 1 (e.g. yellow) on transparent (0)
static const uint8_t smiley8[8 * 8] = {
    0, 0, 1, 1, 1, 1, 0, 0,
    0, 1, 1, 1, 1, 1, 1, 0,
    1, 1, 0, 1, 1, 0, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1,
    1, 0, 1, 1, 1, 1, 0, 1,
    1, 1, 0, 0, 0, 0, 1, 1,
    0, 1, 1, 1, 1, 1, 1, 0,
    0, 0, 1, 1, 1, 1, 0, 0
};

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
    swrites("sprite_test: bouncing checker with delays a...\n");

    // Start near center
    int x = (VGA_WIDTH - 8) / 2;
    int y = (VGA_HEIGHT - 8) / 2;
    int dx = 2;
    int dy = 1;
    const int w = 8, h = 8;
    int toggle = 0;
    vga_set_palette_color(1, 0xFF, 0xFF, 0x00); // Yellow (RGB: 255, 255, 0)

    while (1)
    {
        // // Flash background to visualize frame timing
        // vga_clear_buf(toggle ? 8 : 9);
        // toggle = !toggle;
        vga_clear_buf(VGA_COLOR_LIGHT_BLUE);

        // Draw sprite
        vga_blit(smiley8, w, h, x, y, 0);
        vga_render();

        // Update position and bounce
        x += dx;
        if (x <= 0 || x + w >= VGA_WIDTH)
            dx = -dx;
        y += dy;
        if (y <= 0 || y + h >= VGA_HEIGHT)
            dy = -dy;

        // Wait to set movement speed
        vga_sleep_ms(6);
    }

    return 0;
}

#endif // SPRITE_TEST_C_
