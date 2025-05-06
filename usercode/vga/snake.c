#ifndef SNAKE_C_
#define SNAKE_C_

#include <common.h>
#include <cio.h>                                    ///< for cio_getchar(), cio_kbhit()
#include <clock.h>                                  ///< for system_time RNG
#include "vga/vga_graphics.h"

#define CELL            8                           ///< pixels per grid cell
#define BORDER_CELLS    1                           ///< thickness of permanent wall
#define GRID_W          (VGA_WIDTH / CELL)          ///< total cells across
#define GRID_H          (VGA_HEIGHT / CELL)         ///< total cells down
#define PLAY_W          (GRID_W - 2 * BORDER_CELLS) ///< playable cells across
#define PLAY_H          (GRID_H - 2 * BORDER_CELLS) ///< playable cells down
#define MAX_LEN         (PLAY_W * PLAY_H)           ///< max snake length

/**
** User function: snake
**
** Playable game of snake to demonstrate VGA driver capabilities.
**
** Author: Nicholas Merante <ncm2705@rit.edu>
**
*/

/// A cell on the grid
typedef struct
{
    uint8_t x, y;
} point;

static point snake_body[MAX_LEN];
static int snake_length;
static int dir_x, dir_y;
static point food;
static uint32_t rng_state;

/// Draw one CELL×CELL square into the backbuffer
static void draw_cell(int gx, int gy, uint8_t color)
{
    int px = gx * CELL, py = gy * CELL;
    for (int dy = 0; dy < CELL; ++dy)
        for (int dx = 0; dx < CELL; ++dx)
            vga_put_pixel_buf(px + dx, py + dy, color);
}

/// Simple LCG
static uint32_t lcg_rand(void)
{
    rng_state = rng_state * 1664525 + 1013904223;
    return rng_state;
}

/// Place food in a free cell of the *playable* region
static void place_food(void)
{
    int collision;
    point p;
    do
    {
        p.x = BORDER_CELLS + (lcg_rand() % PLAY_W);
        p.y = BORDER_CELLS + (lcg_rand() % PLAY_H);
        collision = 0;
        for (int i = 0; i < snake_length; ++i)
            if (snake_body[i].x == p.x && snake_body[i].y == p.y)
                collision = 1;
    } while (collision);
    food = p;
}

/// Int to ASCII
static void int_to_str(int v, char *out)
{
    if (v == 0)
    {
        out[0] = '0';
        out[1] = '\0';
        return;
    }
    char tmp[12];
    int i = 0;
    while (v > 0)
    {
        tmp[i++] = '0' + (v % 10);
        v /= 10;
    }
    for (int j = 0; j < i; ++j)
        out[j] = tmp[i - 1 - j];
    out[i] = '\0';
}

USERMAIN(snake)
{
    // Draw a permanent white border
    vga_clear_buf(VGA_COLOR_BLACK);
    // Top and bottom border rows
    vga_draw_rect_buf(0, 0, VGA_WIDTH, CELL, VGA_COLOR_WHITE, 1);
    vga_draw_rect_buf(0, VGA_HEIGHT - CELL, VGA_WIDTH, CELL, VGA_COLOR_WHITE, 1);
    // Left and right border cols
    vga_draw_rect_buf(0, 0, CELL, VGA_HEIGHT, VGA_COLOR_WHITE, 1);
    vga_draw_rect_buf(VGA_WIDTH - CELL, 0, CELL, VGA_HEIGHT, VGA_COLOR_WHITE, 1);
    // Title and prompt
    const char *title = "SNAKE";
    int tx = (VGA_WIDTH - ustrlen(title) * 8) / 2;
    int ty = (VGA_HEIGHT / 2) - 16;
    vga_draw_string(tx, ty, title, VGA_COLOR_YELLOW);
    const char *startp = "PRESS ENTER TO START";
    int sx = (VGA_WIDTH - ustrlen(startp) * 8) / 2;
    int sy = VGA_HEIGHT / 2;
    vga_draw_string(sx, sy, startp, VGA_COLOR_LIGHT_GREY);

    vga_wait_vsync();
    vga_render();
    vga_wait_vsync();

    // Wait for ENTER
    int c;
    do
    {
        c = cio_getchar();
    } while (c != 13 && c != 10);

    while (1)
    {
        // Init snake in the *playable* center
        rng_state = system_time;
        snake_length = 5;
        int cx = BORDER_CELLS + PLAY_W / 2;
        int cy = BORDER_CELLS + PLAY_H / 2;
        for (int i = 0; i < snake_length; ++i)
        {
            snake_body[i].x = cx - i;
            snake_body[i].y = cy;
        }
        dir_x = 1;
        dir_y = 0;
        place_food();

        // Game loop
        int running = 1;
        while (running)
        {
            if (cio_kbhit())
            {
                c = cio_getchar();
                // Arrow codes in the 50s are for arrows, plus WASD
                if (c == 27)
                {
                    running = 0;
                    break;
                }
                if ((c == 'w' || c == 'W' || c == 56) && dir_y != 1)
                {
                    dir_x = 0;
                    dir_y = -1;
                }
                else if ((c == 's' || c == 'S' || c == 50) && dir_y != -1)
                {
                    dir_x = 0;
                    dir_y = 1;
                }
                else if ((c == 'a' || c == 'A' || c == 52) && dir_x != 1)
                {
                    dir_x = -1;
                    dir_y = 0;
                }
                else if ((c == 'd' || c == 'D' || c == 54) && dir_x != -1)
                {
                    dir_x = 1;
                    dir_y = 0;
                }
            }

            // Move body
            for (int i = snake_length; i > 0; --i)
                snake_body[i] = snake_body[i - 1];
            snake_body[0].x += dir_x;
            snake_body[0].y += dir_y;

            // Collisions with border
            if (snake_body[0].x < BORDER_CELLS ||
                snake_body[0].x >= GRID_W - BORDER_CELLS ||
                snake_body[0].y < BORDER_CELLS ||
                snake_body[0].y >= GRID_H - BORDER_CELLS)
            {
                running = 0;
            }
            // Self collision
            for (int i = 1; i < snake_length && running; ++i)
                if (snake_body[i].x == snake_body[0].x &&
                    snake_body[i].y == snake_body[0].y)
                    running = 0;
            if (!running)
                break;

            // Eat food?
            if (snake_body[0].x == food.x &&
                snake_body[0].y == food.y)
            {
                if (++snake_length > MAX_LEN)
                    snake_length = MAX_LEN;
                place_food();
            }

            // Clear play area only
            vga_draw_rect_buf(CELL, CELL,
                              CELL * PLAY_W, CELL * PLAY_H,
                              VGA_COLOR_DARK_GREY, 1);

            // Draw food & snake
            draw_cell(food.x, food.y, VGA_COLOR_RED);
            for (int i = 0; i < snake_length; ++i)
                draw_cell(snake_body[i].x,
                          snake_body[i].y,
                          VGA_COLOR_GREEN);

            // Re-draw the fixed border
            vga_draw_rect_buf(0, 0, VGA_WIDTH, CELL, VGA_COLOR_WHITE, 1);
            vga_draw_rect_buf(0, VGA_HEIGHT - CELL, VGA_WIDTH, CELL, VGA_COLOR_WHITE, 1);
            vga_draw_rect_buf(0, 0, CELL, VGA_HEIGHT, VGA_COLOR_WHITE, 1);
            vga_draw_rect_buf(VGA_WIDTH - CELL, 0, CELL, VGA_HEIGHT, VGA_COLOR_WHITE, 1);

            vga_wait_vsync();
            vga_render();
            vga_wait_vsync();

            vga_sleep_ms(80);
        }

        // Game over: clear *everything* (including stray rows)
        vga_clear_buf(VGA_COLOR_BLACK);
        // Re-draw border
        vga_draw_rect_buf(0, 0, VGA_WIDTH, CELL, VGA_COLOR_WHITE, 1);
        vga_draw_rect_buf(0, VGA_HEIGHT - CELL, VGA_WIDTH, CELL, VGA_COLOR_WHITE, 1);
        vga_draw_rect_buf(0, 0, CELL, VGA_HEIGHT, VGA_COLOR_WHITE, 1);
        vga_draw_rect_buf(VGA_WIDTH - CELL, 0, CELL, VGA_HEIGHT, VGA_COLOR_WHITE, 1);

        // Messages
        const char *go = "GAME OVER!";
        int go_x = (VGA_WIDTH - ustrlen(go) * 8) / 2;
        int go_y = VGA_HEIGHT / 2 - 16;
        vga_draw_string(go_x, go_y, go, VGA_COLOR_LIGHT_RED);

        char score_line[20] = "SCORE: ";
        int_to_str(snake_length - 5, score_line + 7);
        int sc_x = (VGA_WIDTH - ustrlen(score_line) * 8) / 2;
        int sc_y = VGA_HEIGHT / 2;
        vga_draw_string(sc_x, sc_y, score_line, VGA_COLOR_LIGHT_GREEN);

        const char *retry = "PRESS ENTER TO PLAY AGAIN";
        int rt_x = (VGA_WIDTH - ustrlen(retry) * 8) / 2;
        int rt_y = VGA_HEIGHT / 2 + 16;
        vga_draw_string(rt_x, rt_y, retry, VGA_COLOR_LIGHT_CYAN);

        vga_wait_vsync();
        vga_render();
        vga_wait_vsync();

        // Wait for ENTER
        do
        {
            c = cio_getchar();
        } while (c != 13 && c != 10);
    }

    return 0;
}

#endif // SNAKE_C_
