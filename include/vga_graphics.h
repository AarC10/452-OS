#ifndef VGA_GRAPHICS_H_
#define VGA_GRAPHICS_H_

#include <common.h>

// Screen dimensions in Mode 13h
#define VGA_WIDTH   320
#define VGA_HEIGHT  200

// VGA framebuffer address in mode 13h
#define VGA_ADDRESS ((uint8_t *)0xA0000)

void vga_put_pixel(int x, int y, uint8_t color);
void vga_draw_rect(int x, int y, int w, int h, uint8_t color, int filled);
void vga_draw_line(int x0, int y0, int x1, int y1, uint8_t color);

#endif
