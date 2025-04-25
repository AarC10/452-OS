#ifndef VGA_GRAPHICS_H_
#define VGA_GRAPHICS_H_

#include <common.h>

/**
 * @file vga_graphics.h
 * @brief Basic graphics functions for VGA mode 13h (320x200, 256 colors)
 *
 * Provides low-level drawing routines for direct pixel manipulation in
 * VGA graphics memory. Assumes video mode 0x13 is already active.
 */

// === VGA Mode 13h Parameters ===
#define VGA_WIDTH  320    ///< Width of the screen in pixels
#define VGA_HEIGHT 200    ///< Height of the screen in pixels

#define VGA_ADDRESS ((uint8_t*)0xA0000)  ///< VGA framebuffer base address

/**
 * @brief Draw a single pixel at (x, y) with the given color.
 *
 * @param x X coordinate (0 to 319)
 * @param y Y coordinate (0 to 199)
 * @param color VGA color index (0 to 255)
 */
void vga_put_pixel(int x, int y, uint8_t color);

/**
 * @brief Fill the entire screen with a given color.
 *
 * @param color VGA color index to fill
 */
void vga_clear(uint8_t color);

/**
 * @brief Draw a rectangle on screen.
 *
 * @param x Top-left X coordinate
 * @param y Top-left Y coordinate
 * @param w Width of the rectangle
 * @param h Height of the rectangle
 * @param color VGA color index
 * @param filled If non-zero, fills the rectangle; else just draws the border
 */
void vga_draw_rect(int x, int y, int w, int h, uint8_t color, int filled);

/**
 * @brief Draw a line from (x0, y0) to (x1, y1) using Bresenham's algorithm.
 *
 * @param x0 Starting X
 * @param y0 Starting Y
 * @param x1 Ending X
 * @param y1 Ending Y
 * @param color VGA color index
 */
void vga_draw_line(int x0, int y0, int x1, int y1, uint8_t color);

/**
 * @brief Draw a circle using the midpoint circle algorithm.
 *
 * @param cx Center X coordinate
 * @param cy Center Y coordinate
 * @param radius Radius of the circle
 * @param color VGA color index
 * @param fill Non-zero to fill the circle, 0 for outline only
 */
void vga_draw_circle(int cx, int cy, int radius, uint8_t color, int fill);

/**
 * @brief Draw a filled or outlined triangle connecting 3 points.
 *
 * @param x1 Vertex 1 X
 * @param y1 Vertex 1 Y
 * @param x2 Vertex 2 X
 * @param y2 Vertex 2 Y
 * @param x3 Vertex 3 X
 * @param y3 Vertex 3 Y
 * @param color VGA color index
 */
void vga_draw_triangle(int x1, int y1, int x2, int y2, int x3, int y3, uint8_t color);

/**
 * @brief Set a color in the VGA 256-color palette.
 *
 * @param index Palette index (0–255)
 * @param r Red component (0–255)
 * @param g Green component (0–255)
 * @param b Blue component (0–255)
 */
void vga_set_palette_color(uint8_t index, uint8_t r, uint8_t g, uint8_t b);

#endif  // VGA_GRAPHICS_H_
