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
/// 320*200 = 64000 bytes
#define VGA_BYTES  (VGA_WIDTH * VGA_HEIGHT)
/// Number of bytes in the VGA frame buffer (mode 13h is 64 KiB)
#define VGA_VRAM_SIZE  0x10000

// -----------------------------------------------------------------------------
// VGA Color Definitions
// -----------------------------------------------------------------------------

#define VGA_COLOR_BLACK          0  ///< Black
#define VGA_COLOR_BLUE           1  ///< Blue
#define VGA_COLOR_GREEN          2  ///< Green
#define VGA_COLOR_CYAN           3  ///< Cyan
#define VGA_COLOR_RED            4  ///< Red
#define VGA_COLOR_MAGENTA        5  ///< Magenta
#define VGA_COLOR_BROWN          6  ///< Brown (dark yellow)
#define VGA_COLOR_LIGHT_GREY     7  ///< Light gray
#define VGA_COLOR_DARK_GREY      8  ///< Dark gray
#define VGA_COLOR_LIGHT_BLUE     9  ///< Light blue
#define VGA_COLOR_LIGHT_GREEN   10  ///< Light green
#define VGA_COLOR_LIGHT_CYAN    11  ///< Light cyan
#define VGA_COLOR_LIGHT_RED     12  ///< Light red
#define VGA_COLOR_LIGHT_MAGENTA 13  ///< Light magenta
#define VGA_COLOR_YELLOW        14  ///< Yellow
#define VGA_COLOR_WHITE         15  ///< White

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
 * @brief Draw a rectangle into the backbuffer (no VRAM writes).
 *
 * Just like vga_draw_rect, but writes into the off-screen buffer so
 * that a subsequent vga_render() will show it.
 *
 * @param x      Left coordinate (pixels)
 * @param y      Top  coordinate (pixels)
 * @param w      Width  (pixels)
 * @param h      Height (pixels)
 * @param color  Palette index (0–255)
 * @param filled If non-zero, fill; else only outline
 */
void vga_draw_rect_buf(int x, int y, int w, int h, uint8_t color, int filled);

/**
 * @brief Clear the software backbuffer to a single color.
 *
 * Fills all VGA_VRAM_SIZE entries so that vga_render() overwrites
 * *every* byte in the 64 KiB VGA page.
 *
 * @param color Palette index (0–255).
 */
void vga_clear_buf(uint8_t color);

/**
 * @brief Render the backbuffer to video memory.
 *
 * Copies all VGA_VRAM_SIZE bytes from the backbuffer into VGA memory.
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

/**
 * @brief Draw a single ASCII character in graphics mode.
 *
 * Renders the 8×8 glyph for character c into the software backbuffer at (x,y).
 * Uses font8x8.h for bitmap data. Call vga_render() to flush to screen.
 *
 * @param x     X pixel coordinate (0 <= x <= VGA_WIDTH - 8)
 * @param y     Y pixel coordinate (0 <= y <= VGA_HEIGHT - 8)
 * @param c     ASCII character to draw
 * @param color Palette index (0–255) for drawing pixels
 */
void vga_draw_char(int x, int y, char c, uint8_t color);

/**
 * @brief Draw a null-terminated string in graphics mode.
 *
 * Renders each character at 8-pixel horizontal increments. Automatically
 * wraps to next line if it exceeds VGA_WIDTH; does not scroll.
 * Call vga_render() to flush.
 *
 * @param x     Starting X coordinate
 * @param y     Starting Y coordinate
 * @param str   Null-terminated C string
 * @param color Palette index (0–255)
 */
void vga_draw_string(int x, int y, const char *str, uint8_t color);

#endif // VGA_GRAPHICS_H_
