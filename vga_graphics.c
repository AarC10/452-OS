#include <common.h>
#include "vga_graphics.h"

#define VGA_ADDRESS 0xA0000

// Inline abs for freestanding environment
static inline int vga_abs(int x)
{
    return x < 0 ? -x : x;
}

static inline void outb(uint16_t port, uint8_t val)
{
    __asm__ volatile("outb %0, %1" : : "a"(val), "Nd"(port));
}

void vga_put_pixel(int x, int y, uint8_t color)
{
    if (x >= 0 && x < VGA_WIDTH && y >= 0 && y < VGA_HEIGHT)
    {
        uint8_t *vga = (uint8_t *)VGA_ADDRESS;
        vga[y * VGA_WIDTH + x] = color;
    }
}

void vga_clear(uint8_t color)
{
    for (int y = 0; y < VGA_HEIGHT; ++y)
        for (int x = 0; x < VGA_WIDTH; ++x)
            vga_put_pixel(x, y, color);
}

void vga_draw_rect(int x, int y, int w, int h, uint8_t color, int fill)
{
    if (fill)
    {
        for (int i = y; i < y + h; ++i)
            for (int j = x; j < x + w; ++j)
                vga_put_pixel(j, i, color);
    }
    else
    {
        for (int i = x; i < x + w; ++i)
        {
            vga_put_pixel(i, y, color);
            vga_put_pixel(i, y + h - 1, color);
        }
        for (int i = y; i < y + h; ++i)
        {
            vga_put_pixel(x, i, color);
            vga_put_pixel(x + w - 1, i, color);
        }
    }
}

void vga_draw_line(int x0, int y0, int x1, int y1, uint8_t color)
{
    int dx = vga_abs(x1 - x0), sx = x0 < x1 ? 1 : -1;
    int dy = -vga_abs(y1 - y0), sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;

    while (1)
    {
        vga_put_pixel(x0, y0, color);
        if (x0 == x1 && y0 == y1)
            break;
        int e2 = 2 * err;
        if (e2 >= dy)
        {
            err += dy;
            x0 += sx;
        }
        if (e2 <= dx)
        {
            err += dx;
            y0 += sy;
        }
    }
}

static void draw_circle_points(int cx, int cy, int x, int y, uint8_t color, int fill)
{
    if (fill)
    {
        for (int i = -x; i <= x; ++i)
        {
            vga_put_pixel(cx + i, cy + y, color);
            vga_put_pixel(cx + i, cy - y, color);
        }
        for (int i = -y; i <= y; ++i)
        {
            vga_put_pixel(cx + i, cy + x, color);
            vga_put_pixel(cx + i, cy - x, color);
        }
    }
    else
    {
        vga_put_pixel(cx + x, cy + y, color);
        vga_put_pixel(cx - x, cy + y, color);
        vga_put_pixel(cx + x, cy - y, color);
        vga_put_pixel(cx - x, cy - y, color);
        vga_put_pixel(cx + y, cy + x, color);
        vga_put_pixel(cx - y, cy + x, color);
        vga_put_pixel(cx + y, cy - x, color);
        vga_put_pixel(cx - y, cy - x, color);
    }
}

void vga_draw_circle(int cx, int cy, int radius, uint8_t color, int fill)
{
    int x = 0;
    int y = radius;
    int d = 3 - 2 * radius;

    while (y >= x)
    {
        draw_circle_points(cx, cy, x, y, color, fill);
        x++;
        if (d > 0)
        {
            y--;
            d += 4 * (x - y) + 10;
        }
        else
        {
            d += 4 * x + 6;
        }
    }
}

void vga_draw_triangle(int x1, int y1, int x2, int y2, int x3, int y3, uint8_t color)
{
    vga_draw_line(x1, y1, x2, y2, color);
    vga_draw_line(x2, y2, x3, y3, color);
    vga_draw_line(x3, y3, x1, y1, color);
}

void vga_set_palette_color(uint8_t index, uint8_t r, uint8_t g, uint8_t b)
{
    outb(0x3C8, index);
    outb(0x3C9, r >> 2);
    outb(0x3C9, g >> 2);
    outb(0x3C9, b >> 2);
}
