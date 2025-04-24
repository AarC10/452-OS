#include "vga_graphics.h"

void vga_put_pixel(int x, int y, uint8_t color)
{
    if (x < 0 || x >= VGA_WIDTH || y < 0 || y >= VGA_HEIGHT)
        return;
    VGA_ADDRESS[y * VGA_WIDTH + x] = color;
}

void vga_draw_rect(int x, int y, int w, int h, uint8_t color, int filled)
{
    if (filled)
    {
        for (int j = y; j < y + h; j++)
        {
            for (int i = x; i < x + w; i++)
            {
                vga_put_pixel(i, j, color);
            }
        }
    }
    else
    {
        for (int i = x; i < x + w; i++)
        {
            vga_put_pixel(i, y, color);
            vga_put_pixel(i, y + h - 1, color);
        }
        for (int j = y; j < y + h; j++)
        {
            vga_put_pixel(x, j, color);
            vga_put_pixel(x + w - 1, j, color);
        }
    }
}

// Bresenham's Line Algorithm
void vga_draw_line(int x0, int y0, int x1, int y1, uint8_t color)
{
    int dx = (x1 > x0) ? x1 - x0 : x0 - x1;
    int dy = (y1 > y0) ? y1 - y0 : y0 - y1;
    int sx = (x0 < x1) ? 1 : -1;
    int sy = (y0 < y1) ? 1 : -1;
    int err = dx - dy;

    while (1)
    {
        vga_put_pixel(x0, y0, color);
        if (x0 == x1 && y0 == y1)
            break;
        int e2 = 2 * err;
        if (e2 > -dy)
        {
            err -= dy;
            x0 += sx;
        }
        if (e2 < dx)
        {
            err += dx;
            y0 += sy;
        }
    }
}
