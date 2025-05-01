/**
 * @file vga_graphics.h
 * @brief VGA graphics driver interface for 320×200×256 mode
 *
 * Provides low-level drawing primitives (pixels, lines, rectangles, circles, triangles),
 * palette control, software double-buffer management, sprite blitting with transparency,
 * and frame/timing utilities (vertical sync and delays) for VGA mode 13h.
 */

#ifndef VGA_GRAPHICS_H_
#define VGA_GRAPHICS_H_

#include <common.h>

/// Width of the screen in pixels (Mode 13h)
#define VGA_WIDTH 320
/// Height of the screen in pixels (Mode 13h)
#define VGA_HEIGHT 200
/// Base address of VGA frame buffer
#define VGA_ADDRESS ((uint8_t *)0xA0000)
/// Approximate display refresh rate for delay calculations
#define VGA_REFRESH_HZ 60

// -----------------------------------------------------------------------------
// Basic drawing primitives
// -----------------------------------------------------------------------------

/**
 * @brief Set a pixel in video memory.
 *
 * Writes the given color index directly into VGA memory at (x, y).
 *
 * @param x     Horizontal coordinate, 0 <= x < VGA_WIDTH
 * @param y     Vertical coordinate,   0 <= y < VGA_HEIGHT
 * @param color Palette index (0–255)
 */
void vga_put_pixel(int x, int y, uint8_t color);

/**
 * @brief Clear the screen.
 *
 * Fills the entire visible area with a single color.
 *
 * @param color Palette index to fill the screen with
 */
void vga_clear(uint8_t color);

/**
 * @brief Draw a filled or outlined rectangle.
 *
 * Renders a rectangle of width w and height h at position (x, y).
 *
 * @param x      X-coordinate of the top-left corner
 * @param y      Y-coordinate of the top-left corner
 * @param w      Width of the rectangle in pixels
 * @param h      Height of the rectangle in pixels
 * @param color  Palette index for drawing
 * @param filled Non-zero to fill the rectangle; zero to draw only the outline
 */
void vga_draw_rect(int x, int y, int w, int h, uint8_t color, int filled);

/**
 * @brief Draw a line using Bresenham's algorithm.
 *
 * Connects points (x0, y0) and (x1, y1) with a straight line.
 *
 * @param x0    Starting X-coordinate
 * @param y0    Starting Y-coordinate
 * @param x1    Ending X-coordinate
 * @param y1    Ending Y-coordinate
 * @param color Palette index for the line
 */
void vga_draw_line(int x0, int y0, int x1, int y1, uint8_t color);

/**
 * @brief Draw a circle using the midpoint algorithm.
 *
 * Renders a circle centered at (cx, cy) of the given radius.
 *
 * @param cx     Center X-coordinate
 * @param cy     Center Y-coordinate
 * @param radius Radius in pixels
 * @param color  Palette index for drawing
 * @param fill   Non-zero to fill the circle; zero for outline only
 */
void vga_draw_circle(int cx, int cy, int radius, uint8_t color, int fill);

/**
 * @brief Draw a triangle by connecting three vertices.
 *
 * Uses line-drawing to connect (x1,y1), (x2,y2), and (x3,y3).
 *
 * @param x1    X-coordinate of first vertex
 * @param y1    Y-coordinate of first vertex
 * @param x2    X-coordinate of second vertex
 * @param y2    Y-coordinate of second vertex
 * @param x3    X-coordinate of third vertex
 * @param y3    Y-coordinate of third vertex
 * @param color Palette index for drawing
 */
void vga_draw_triangle(int x1, int y1,
                       int x2, int y2,
                       int x3, int y3,
                       uint8_t color);

/**
 * @brief Set a palette entry.
 *
 * Programs the VGA DAC to map color index to an (r,g,b) value.
 * Each component is 0–255; VGA hardware uses 6-bit, so values are scaled.
 *
 * @param index Palette index to set (0–255)
 * @param r     Red component (0–255)
 * @param g     Green component (0–255)
 * @param b     Blue component (0–255)
 */
void vga_set_palette_color(uint8_t index, uint8_t r, uint8_t g, uint8_t b);

// -----------------------------------------------------------------------------
// Software double buffering
// -----------------------------------------------------------------------------

/**
 * @brief Draw a pixel into the backbuffer.
 *
 * Updates the off-screen buffer at (x, y) without touching video memory.
 *
 * @param x     Horizontal coordinate
 * @param y     Vertical coordinate
 * @param color Palette index (0–255)
 */
void vga_put_pixel_buf(int x, int y, uint8_t color);

/**
 * @brief Clear the backbuffer.
 *
 * Fills the entire backbuffer with the given color.
 *
 * @param color Palette index to fill the backbuffer
 */
void vga_clear_buf(uint8_t color);

/**
 * @brief Copy the backbuffer to video memory.
 *
 * Flushes the entire off-screen buffer into VGA memory in one block.
 */
void vga_render(void);

// -----------------------------------------------------------------------------
// Sprite blitting
// -----------------------------------------------------------------------------

/**
 * @brief Blit a sprite into the backbuffer with transparency.
 *
 * Copies a w×h array of palette indices, skipping pixels equal to the transparent_color.
 *
 * @param sprite            Pointer to sprite data (w*h bytes)
 * @param w                 Sprite width in pixels
 * @param h                 Sprite height in pixels
 * @param x                 Destination X-coordinate
 * @param y                 Destination Y-coordinate
 * @param transparent_color Palette index to treat as transparent
 */
void vga_blit(const uint8_t *sprite,
              int w, int h,
              int x, int y,
              uint8_t transparent_color);

// -----------------------------------------------------------------------------
// Vertical sync & delays
// -----------------------------------------------------------------------------

/**
 * @brief Wait for the next vertical blank interval.
 *
 * Polls the VGA status register and halts until the CRT enters vertical blank.
 */
void vga_wait_vsync(void);

/**
 * @brief Delay by a number of display frames (~1/VGA_REFRESH_HZ seconds).
 *
 * Calls vga_wait_vsync() frame_count times.
 *
 * @param frame_count Number of frames to delay
 */
void vga_delay_frames(uint32_t frame_count);

/**
 * @brief Delay approximately ms milliseconds using frame delays.
 *
 * Converts ms to frame count by VGA_REFRESH_HZ and waits.
 *
 * @param ms Delay in milliseconds
 */
void vga_delay_ms(uint32_t ms);

/**
 * @brief Sleep for a given number of milliseconds based on PIT ticks.
 *
 * Uses the kernel's system_time (ticks) to block for accurate millisecond delays.
 *
 * @param ms Delay in milliseconds
 */
void vga_sleep_ms(uint32_t ms);

#endif // VGA_GRAPHICS_H_
