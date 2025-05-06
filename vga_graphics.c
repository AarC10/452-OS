/**
 * @file vga_graphics.c
 * @brief VGA graphics driver implementation for 320×200×256 mode (Mode 13h)
 * @author Nicholas Merante <ncm2705@rit.edu>
 *
 * This file contains the implementation of low-level VGA graphics routines
 * for Mode 13h (320×200, 256 colors). It provides direct pixel access, basic
 * shapes rendering (lines, rectangles, circles, triangles), palette control,
 * double buffering, sprite blitting with transparency, vertical sync handling,
 * frame-based timing delays, and text rendering using an 8×8 bitmap font.
 *
 * All rendering operations are performed either directly to VGA memory or
 * to a software backbuffer that can be flushed to screen via vga_render().
 */

#include <common.h>
#include <clock.h> // for system_time, CLOCK_FREQ
#include <lib.h>   // for umemcpy
#include "vga/vga_graphics.h"
#include "vga/font8x8.h"

// -----------------------------------------------------------------------------
// Port I/O helpers
// -----------------------------------------------------------------------------

/**
 * @brief Read a byte from an I/O port.
 */
static inline uint8_t inb(uint16_t port)
{
    uint8_t val;
    __asm__ volatile("inb %1, %0" : "=a"(val) : "Nd"(port));
    return val;
}

/**
 * @brief Write a byte to an I/O port.
 */
static inline void outb(uint16_t port, uint8_t val)
{
    __asm__ volatile("outb %0, %1" : : "a"(val), "Nd"(port));
}

// -----------------------------------------------------------------------------
// Vertical sync & delays
// -----------------------------------------------------------------------------

void vga_wait_vsync(void)
{
    // wait for end of current retrace
    while (inb(0x3DA) & 0x08)
    {
        __asm__ volatile("hlt");
    }
    // wait for start of next retrace
    while (!(inb(0x3DA) & 0x08))
    {
        __asm__ volatile("hlt");
    }
}

void vga_delay_frames(uint32_t frames)
{
    while (frames--)
    {
        vga_wait_vsync();
    }
}

void vga_delay_ms(uint32_t ms)
{
    uint32_t frames = (ms * VGA_REFRESH_HZ + 500) / 1000;
    vga_delay_frames(frames);
}

void vga_sleep_ms(uint32_t ms)
{
    uint32_t end = system_time + (ms * CLOCK_FREQ + 500) / 1000;
    while (system_time < end)
    {
        __asm__ volatile("hlt");
    }
}

// -----------------------------------------------------------------------------
// Basic drawing primitives
// -----------------------------------------------------------------------------

static inline int vga_abs(int x)
{
    return x < 0 ? -x : x;
}

void vga_put_pixel(int x, int y, uint8_t color)
{
    if (x >= 0 && x < VGA_WIDTH && y >= 0 && y < VGA_HEIGHT)
    {
        uint8_t *fb = VGA_ADDRESS;
        fb[y * VGA_WIDTH + x] = color;
    }
}

void vga_clear(uint8_t color)
{
    for (int y = 0; y < VGA_HEIGHT; ++y)
    {
        for (int x = 0; x < VGA_WIDTH; ++x)
        {
            vga_put_pixel(x, y, color);
        }
    }
}

void vga_draw_rect(int x, int y, int w, int h, uint8_t color, int filled)
{
    if (filled)
    {
        for (int yy = y; yy < y + h; ++yy)
        {
            for (int xx = x; xx < x + w; ++xx)
            {
                vga_put_pixel(xx, yy, color);
            }
        }
    }
    else
    {
        // top & bottom
        for (int xx = x; xx < x + w; ++xx)
        {
            vga_put_pixel(xx, y, color);
            vga_put_pixel(xx, y + h - 1, color);
        }
        // left & right
        for (int yy = y; yy < y + h; ++yy)
        {
            vga_put_pixel(x, yy, color);
            vga_put_pixel(x + w - 1, yy, color);
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
    int x = 0, y = radius;
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

// -----------------------------------------------------------------------------
// Software double-buffering
// -----------------------------------------------------------------------------

static uint8_t vga_backbuffer[VGA_VRAM_SIZE];

void vga_put_pixel_buf(int x, int y, uint8_t color)
{
    if (x >= 0 && x < VGA_WIDTH && y >= 0 && y < VGA_HEIGHT)
    {
        vga_backbuffer[y * VGA_WIDTH + x] = color;
    }
}

void vga_draw_rect_buf(int x, int y, int w, int h, uint8_t color, int filled)
{
    if (filled)
    {
        for (int yy = y; yy < y + h; ++yy)
        {
            if (yy < 0 || yy >= VGA_HEIGHT)
                continue;
            for (int xx = x; xx < x + w; ++xx)
            {
                if (xx < 0 || xx >= VGA_WIDTH)
                    continue;
                vga_backbuffer[yy * VGA_WIDTH + xx] = color;
            }
        }
    }
    else
    {
        // top & bottom edges
        for (int xx = x; xx < x + w; ++xx)
        {
            if (xx < 0 || xx >= VGA_WIDTH)
                continue;
            if (y >= 0 && y < VGA_HEIGHT)
                vga_backbuffer[y * VGA_WIDTH + xx] = color;
            if (y + h - 1 >= 0 && y + h - 1 < VGA_HEIGHT)
                vga_backbuffer[(y + h - 1) * VGA_WIDTH + xx] = color;
        }
        // left & right edges
        for (int yy = y; yy < y + h; ++yy)
        {
            if (yy < 0 || yy >= VGA_HEIGHT)
                continue;
            if (x >= 0 && x < VGA_WIDTH)
                vga_backbuffer[yy * VGA_WIDTH + x] = color;
            if (x + w - 1 >= 0 && x + w - 1 < VGA_WIDTH)
                vga_backbuffer[yy * VGA_WIDTH + x + w - 1] = color;
        }
    }
}

void vga_clear_buf(uint8_t color)
{
    // clear the entire VGA page
    for (int i = 0; i < VGA_VRAM_SIZE; ++i)
    {
        vga_backbuffer[i] = color;
    }
}

void vga_render(void)
{
    // copy the entire 64 KiB to video RAM
    umemcpy((void *)VGA_ADDRESS, vga_backbuffer, VGA_VRAM_SIZE);
}

// -----------------------------------------------------------------------------
// Sprite blitting with transparency
// -----------------------------------------------------------------------------

void vga_blit(const uint8_t *sprite, int w, int h, int x0, int y0, uint8_t transparent_color)
{
    for (int y = 0; y < h; ++y)
    {
        int yy = y0 + y;
        if (yy < 0 || yy >= VGA_HEIGHT)
            continue;
        for (int x = 0; x < w; ++x)
        {
            int xx = x0 + x;
            if (xx < 0 || xx >= VGA_WIDTH)
                continue;
            uint8_t p = sprite[y * w + x];
            if (p != transparent_color)
            {
                vga_put_pixel_buf(xx, yy, p);
            }
        }
    }
}

/**
 * Draws a single character by reversing bit order so glyphs display correctly.
 */
void vga_draw_char(int x, int y, char c, uint8_t color)
{
    const uint8_t *glyph = font8x8_get(c);
    for (int row = 0; row < 8; ++row)
    {
        uint8_t bits = glyph[row];
        for (int col = 0; col < 8; ++col)
        {
            // reverse horizontal bit order: MSB maps to col=0
            if (bits & (1 << (7 - col)))
            {
                vga_put_pixel_buf(x + col, y + row, color);
            }
        }
    }
}

void vga_draw_string(int x, int y, const char *str, uint8_t color)
{
    int cx = x, cy = y;
    while (*str)
    {
        if (*str == '\n')
        {
            cx = x;
            cy += 8;
        }
        else
        {
            vga_draw_char(cx, cy, *str, color);
            cx += 8;
            if (cx + 8 > VGA_WIDTH)
            {
                cx = x;
                cy += 8;
            }
        }
        ++str;
    }
}