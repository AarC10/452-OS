#ifndef VGA_TYPE_C_
#define VGA_TYPE_C_

#include <common.h>
#include <cio.h>
#include "vga_graphics.h"

#define TEXT_COLOR 15

USERMAIN(vga_type)
{
    vga_clear_buf(0);

    int cursor_x = 0, cursor_y = 0;
    int ch;
    swrites("vga_type: type keys (ESC to exit) in graphics mode...\n");

    while ((ch = cio_getchar()) >= 0)
    {
        if (ch == 27)
            break; // ESC
        if (ch == '\r' || ch == '\n')
        {
            cursor_x = 0;
            cursor_y += 8;
            if (cursor_y + 8 > VGA_HEIGHT)
            {
                vga_clear_buf(0);
                cursor_y = 0;
            }
        }
        else
        {
            vga_draw_char(cursor_x, cursor_y, (char)ch, TEXT_COLOR);
            cursor_x += 8;
            if (cursor_x + 8 > VGA_WIDTH)
            {
                cursor_x = 0;
                cursor_y += 8;
                if (cursor_y + 8 > VGA_HEIGHT)
                {
                    vga_clear_buf(0);
                    cursor_y = 0;
                }
            }
        }
        vga_render();
    }

    exit(0);
    return 0;
}

#endif // VGA_TYPE_C_
