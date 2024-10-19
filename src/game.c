#define POKE(reg, value) (*(volatile unsigned char *)(reg) = (unsigned char)(value))
#define PEEK(reg) (*(volatile unsigned char *)(reg))

// Pill bitmaps
extern const unsigned char pill_0[64];
extern const unsigned char pill_1[64];
extern const unsigned char pill_2[64];
extern const unsigned char pill_3[64];
extern const unsigned char pill_4[64];
extern const unsigned char pill_5[64];
extern const unsigned char pill_6[64];
extern const unsigned char pill_7[64];
extern const unsigned char pill_8[64];
extern const unsigned char pill_9[64];
extern const unsigned char pill_10[64];
extern const unsigned char pill_11[64];
extern const unsigned char pill_12[64];
extern const unsigned char pill_13[64];
extern const unsigned char pill_14[64];

// Virus bitmaps
extern const unsigned char virus_0[64];
extern const unsigned char virus_1[64];
extern const unsigned char virus_2[64];

// Background bitmaps
extern const unsigned char bitmap_background_left[1561];
extern const unsigned char bitmap_background_right[5082];
extern const unsigned char bitmap_background_btm[224];

// Menu
extern const unsigned char bitmap_menu[6527];

// Digits bitmaps
// In this order: 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, dot
extern const unsigned char digit_0[8];
extern const unsigned char digit_1[8];
extern const unsigned char digit_2[8];
extern const unsigned char digit_3[8];
extern const unsigned char digit_4[8];
extern const unsigned char digit_5[8];
extern const unsigned char digit_6[8];
extern const unsigned char digit_7[8];
extern const unsigned char digit_8[8];
extern const unsigned char digit_9[8];
extern const unsigned char digit_dot[8];

// Define the translation table to go from a character to a sprite index
const unsigned char *char_to_sprite[] = {
    digit_9, // 0
    digit_0, // 1
    digit_1, // 2
    digit_2, // 3
    digit_3, // 4
    digit_4, // 5
    digit_5, // 6
    digit_6, // 7
    digit_7, // 8
    digit_8  // 9
};

// Define ROM routines
extern void rom_cls();
extern unsigned char rom_ci();
extern void set_palette();
extern void vsync();
extern unsigned char key_in();
extern void draw_sprite(const unsigned char *sprite, unsigned char x, unsigned char y);
extern void delete_sprite(unsigned char x, unsigned char y);
extern void draw_digit(const unsigned char *digit, unsigned char x, unsigned char y);
extern void draw_bitmap(const unsigned char *bitmap, unsigned char width, unsigned char height, unsigned char x, unsigned char y);

// Array of pointers to bitmaps

// The 3 bitmaps representing a pill left part
const unsigned char *pill_left[] = {
    pill_0,
    pill_5,
    pill_10};

// The 3 bitmaps representing a pill bottom part
const unsigned char *pill_bottom[] = {
    pill_1,
    pill_6,
    pill_11};

// The 3 bitmaps representing a pill right part
const unsigned char *pill_right[] = {
    pill_2,
    pill_7,
    pill_12};

// The 3 bitmaps representing a pill top part
const unsigned char *pill_top[] = {
    pill_3,
    pill_8,
    pill_13};

// The 3 bitmaps representing a pill isolated part
const unsigned char *pill_isolated[] = {
    pill_4,
    pill_9,
    pill_14};

// The 3 bitmaps representing a virus
const unsigned char *virus[] = {
    virus_1,
    virus_2,
    virus_0};

/* Various utility methods for Hector */

unsigned char __rand;
// Generate a random number
unsigned char rand()
{
    __rand = __rand * 0x41 + 0x3039;
    return __rand;
}

/*************** */
/* Score Display */
/*************** */

#define SCORE_X 48
#define SCORE_Y 98
#define LEVEL_X 56
#define LEVEL_Y 86

void draw_number(unsigned int number, unsigned char x, unsigned char y)
{
    unsigned char digits[5] = {0, 0, 0, 0, 0};
    unsigned char i = 0;
    unsigned char leading = 0;
    unsigned char x_offset = 0;

    if (number == 0)
    {
        draw_digit(char_to_sprite[0], x, y);
        return;
    }

    while (number > 0)
    {
        digits[i++] = number % 10;
        number /= 10;
    }

    leading = 1;
    for (i = 0; i < 5; i++)
    {
        // Score examples: 12345 -> 54321, 123 -> 32100, 800 -> 00800, 1200 -> 00210
        // Skip the leading zeros
        if (digits[4 - i] != 0 || !leading)
        {
            draw_digit(char_to_sprite[digits[4 - i]], x + x_offset, y);
            leading = 0;
            x_offset++;
        }
    }
}

/**************/
/* GAME LOGIC */
/**************/

#define BOARD_WIDTH 8
#define BOARD_HEIGHT 14
#define EMPTY 0
#define VIRUS_RED 1
#define VIRUS_YELLOW 2
#define VIRUS_BLUE 3
#define PILL_RED 4
#define PILL_YELLOW 5
#define PILL_BLUE 6

// Connectivities:
// 1 = connected right
// 2 = connected left
// 3 = connected up
// 4 = connected down
#define CONNECTED_NONE 0
#define CONNECTED_RIGHT 1
#define CONNECTED_LEFT 2
#define CONNECTED_UP 3
#define CONNECTED_DOWN 4

typedef struct
{
    unsigned char color;
    unsigned char connected; // 0 = not connected, 1 = connected right, 2 = connected left, 3 = connected up, 4 = connected down
} Cell;

Cell board[BOARD_WIDTH * BOARD_HEIGHT];
unsigned char virus_count;
unsigned int score;
unsigned int level;
unsigned char current_pill_x, current_pill_y;
unsigned char current_pill_color1, current_pill_color2;
unsigned char next_pill_color1, next_pill_color2;
unsigned char game_over;
unsigned char current_pill_connection;

// Helper function to check if two colors match (including virus-pill matches)
unsigned char colors_match(unsigned char color1, unsigned char color2)
{
    if (color1 == color2)
        return 1;
    if ((color1 == VIRUS_RED && color2 == PILL_RED) || (color1 == PILL_RED && color2 == VIRUS_RED))
        return 1;
    if ((color1 == VIRUS_YELLOW && color2 == PILL_YELLOW) || (color1 == PILL_YELLOW && color2 == VIRUS_YELLOW))
        return 1;
    if ((color1 == VIRUS_BLUE && color2 == PILL_BLUE) || (color1 == PILL_BLUE && color2 == VIRUS_BLUE))
        return 1;
    return 0;
}

unsigned char is_virus(unsigned char color)
{
    return color >= VIRUS_RED && color <= VIRUS_BLUE;
}

unsigned char is_pill(unsigned char color)
{
    return color >= PILL_RED && color <= PILL_BLUE;
}

// Render game state
void render_game(void)
{
    unsigned char x, y;
    for (y = 0; y < BOARD_HEIGHT; y++)
    {
        for (x = 0; x < BOARD_WIDTH; x++)
        {
            if (board[y * BOARD_WIDTH + x].color != EMPTY)
            {
                if (is_virus(board[y * BOARD_WIDTH + x].color))
                {
                    draw_sprite(virus[board[y * BOARD_WIDTH + x].color - VIRUS_RED], 7 + x * 4, y * 16);
                }
                else
                {
                    if (board[y * BOARD_WIDTH + x].connected == CONNECTED_RIGHT)
                    {
                        draw_sprite(pill_left[board[y * BOARD_WIDTH + x].color - PILL_RED], 7 + x * 4, y * 16);
                        draw_sprite(pill_right[board[y * BOARD_WIDTH + x + 1].color - PILL_RED], 7 + x * 4 + 4, y * 16);
                    }
                    else if (board[y * BOARD_WIDTH + x].connected == CONNECTED_UP)
                    {
                        draw_sprite(pill_bottom[board[y * BOARD_WIDTH + x].color - PILL_RED], 7 + x * 4, y * 16);
                        draw_sprite(pill_top[board[(y - 1) * BOARD_WIDTH + x].color - PILL_RED], 7 + x * 4, y * 16 - 16);
                    }
                    else if (board[y * BOARD_WIDTH + x].connected == CONNECTED_NONE)
                    {
                        draw_sprite(pill_isolated[board[y * BOARD_WIDTH + x].color - PILL_RED], 7 + x * 4, y * 16);
                    }
                }
            }
            else
            {
                delete_sprite(7 + x * 4, y * 16);
            }
        }
    }
}

// Display the next pill
void display_next_pill(void)
{
    draw_sprite(pill_left[next_pill_color1 - PILL_RED], 50, 61);
    draw_sprite(pill_right[next_pill_color2 - PILL_RED], 50 + 4, 61);
}

// Function to clear lines and update score
void clear_lines(void)
{
    unsigned char x, y, len, cleared, fell;
    unsigned char chain = 0;
    unsigned char to_clear[BOARD_WIDTH * BOARD_HEIGHT] = {0};

    do
    {
        cleared = 0;

        // Check horizontal lines
        for (y = 0; y < BOARD_HEIGHT; y++)
        {
            for (x = 0; x < BOARD_WIDTH; x++)
            {
                unsigned char index = y * BOARD_WIDTH + x;

                if (board[index].color == EMPTY)
                    continue;

                len = 1;
                while (x + len < BOARD_WIDTH &&
                       colors_match(board[index].color, board[index + len].color))
                {
                    len++;
                }

                if (len >= 4)
                {
                    for (unsigned char i = 0; i < len; i++)
                    {
                        to_clear[index + i] = 1;
                    }
                    cleared = 1;
                }
            }
        }

        // Check vertical lines
        for (x = 0; x < BOARD_WIDTH; x++)
        {
            for (y = 0; y < BOARD_HEIGHT; y++)
            {
                unsigned char index = y * BOARD_WIDTH + x;

                if (board[index].color == EMPTY)
                    continue;

                len = 1;
                while (y + len < BOARD_HEIGHT &&
                       colors_match(board[index].color, board[(y + len) * BOARD_WIDTH + x].color))
                {
                    len++;
                }

                if (len >= 4)
                {
                    for (unsigned char i = 0; i < len; i++)
                    {
                        to_clear[(y + i) * BOARD_WIDTH + x] = 1;
                    }
                    cleared = 1;
                }
            }
        }

        // Clear marked cells and update score
        if (cleared)
        {
            for (y = 0; y < BOARD_HEIGHT; y++)
            {
                for (x = 0; x < BOARD_WIDTH; x++)
                {
                    unsigned char index = y * BOARD_WIDTH + x;

                    if (to_clear[index])
                    {
                        if (is_virus(board[index].color))
                        {
                            virus_count--;
                        }
                        
                        // Mark pill halves as isolated
                        if (board[index].connected == CONNECTED_RIGHT) {
                            board[index + 1].connected = CONNECTED_NONE;
                        } else if (board[index].connected == CONNECTED_LEFT) {
                            board[index - 1].connected = CONNECTED_NONE;
                        } else if (board[index].connected == CONNECTED_UP) {
                            board[(y - 1) * BOARD_WIDTH + x].connected = CONNECTED_NONE;
                        } else if (board[index].connected == CONNECTED_DOWN) {
                            board[(y + 1) * BOARD_WIDTH + x].connected = CONNECTED_NONE;
                        }

                        // Clear the cell
                        board[index].color = EMPTY;
                        board[index].connected = CONNECTED_NONE;

                        score += 100 * (chain + 1);
                        to_clear[index] = 0;
                    }
                }
            }

            // Render game so we can see the changed pills
            render_game();

            // Apply gravity to make pills fall
            // If any piece falls; loop again to check for more hanging pieces
            do
            {
                fell = 0;

                for (x = 0; x < BOARD_WIDTH; x++)
                {
                    unsigned char write = BOARD_HEIGHT - 1;
                    unsigned char read = BOARD_HEIGHT - 1;
                    while (read != 255)
                    {
                        if (is_virus(board[read * BOARD_WIDTH + x].color))
                        {
                            // Viruses don't fall
                            read--;
                            write = read;
                        }
                        else if (is_pill(board[read * BOARD_WIDTH + x].color))
                        {
                            if (board[read * BOARD_WIDTH + x].connected == CONNECTED_RIGHT && x < BOARD_WIDTH - 1)
                            {
                                // Pill connected to the right
                                if (read < write)
                                {
                                    // Check all the x+1 column cells between read and write, not just the next one
                                    for (unsigned char i = read + 1; i <= write; i++)
                                    {
                                        if (board[i * BOARD_WIDTH + x + 1].color != EMPTY)
                                        {
                                            write = i - 1;
                                            break;
                                        }
                                    }

                                    // Can still fall
                                    if (read < write)
                                    {
                                        board[write * BOARD_WIDTH + x] = board[read * BOARD_WIDTH + x];
                                        board[write * BOARD_WIDTH + x + 1] = board[read * BOARD_WIDTH + x + 1];
                                        board[read * BOARD_WIDTH + x].color = EMPTY;
                                        board[read * BOARD_WIDTH + x].connected = 0;
                                        board[read * BOARD_WIDTH + x + 1].color = EMPTY;
                                        board[read * BOARD_WIDTH + x + 1].connected = 0;

                                        fell = 1;
                                        write--;
                                        read--;
                                    } else {
                                        read--;
                                        write = read;
                                    }
                                } else {
                                    write--;
                                    read--;
                                }
                            }
                            else if (board[read * BOARD_WIDTH + x].connected == CONNECTED_LEFT && x > 0)
                            {
                                // Pill connected to the left (do nothing, it was handled in the previous iteration)
                                read--;
                                write = read;
                            }
                            else if (board[read * BOARD_WIDTH + x].connected == CONNECTED_UP && read > 0)
                            {
                                // Pill connected upwards
                                if (read - 1 < write - 1)
                                {
                                    board[write * BOARD_WIDTH + x] = board[read * BOARD_WIDTH + x];
                                    board[(write - 1) * BOARD_WIDTH + x] = board[(read - 1) * BOARD_WIDTH + x];
                                    
                                    // Don't overwrite the top half of the pill
                                    if (read < write - 1)
                                    {
                                        board[read * BOARD_WIDTH + x].color = EMPTY;
                                        board[read * BOARD_WIDTH + x].connected = 0;
                                    }

                                    board[(read - 1) * BOARD_WIDTH + x].color = EMPTY;
                                    board[(read - 1) * BOARD_WIDTH + x].connected = 0;

                                    fell = 1;
                                }
                                write -= 2;
                                read -= 2;
                            }
                            else if (board[read * BOARD_WIDTH + x].connected == CONNECTED_DOWN)
                            {
                                // Pill connected downwards (do nothing, it was handled in the previous iteration)
                                read--;
                                write = read;
                            }
                            else
                            {
                                // Single pill piece
                                if (read < write)
                                {
                                    board[write * BOARD_WIDTH + x] = board[read * BOARD_WIDTH + x];
                                    board[read * BOARD_WIDTH + x].color = EMPTY;
                                    board[read * BOARD_WIDTH + x].connected = 0;

                                    fell = 1;
                                }
                                write--;
                                read--;
                            }
                        }
                        else
                        {
                            read--;
                        }
                    }
                }

                // Render game so we can see the changed pills
                render_game();

            } while (fell);

            chain++;
        }
    } while (cleared);
}

// Function to place the current pill on the board
void place_pill()
{
    if (current_pill_connection == CONNECTED_RIGHT)
    {
        board[current_pill_y * BOARD_WIDTH + current_pill_x].color = current_pill_color1;
        board[current_pill_y * BOARD_WIDTH + current_pill_x].connected = CONNECTED_RIGHT;
        board[current_pill_y * BOARD_WIDTH + current_pill_x + 1].color = current_pill_color2;
        board[current_pill_y * BOARD_WIDTH + current_pill_x + 1].connected = CONNECTED_LEFT;
    }
    else if (current_pill_connection == CONNECTED_UP)
    {
        board[current_pill_y * BOARD_WIDTH + current_pill_x].color = current_pill_color1;
        board[current_pill_y * BOARD_WIDTH + current_pill_x].connected = CONNECTED_UP;
        board[(current_pill_y - 1) * BOARD_WIDTH + current_pill_x].color = current_pill_color2;
        board[(current_pill_y - 1) * BOARD_WIDTH + current_pill_x].connected = CONNECTED_DOWN;
    }
}

// Check if the current pill position is valid
unsigned char is_valid_position(unsigned char x, unsigned char y)
{
    // Check first half of pill based on orientation
    if (current_pill_connection == CONNECTED_RIGHT)
    { // Horizontal
        if (x < 0 || x >= BOARD_WIDTH - 1 || y >= BOARD_HEIGHT)
            return 0;
    }
    else if (current_pill_connection == CONNECTED_UP)
    { // Vertical
        if (x < 0 || x >= BOARD_WIDTH || y >= BOARD_HEIGHT)
            return 0;
    }

    if (board[y * BOARD_WIDTH + x].color != EMPTY)
        return 0;

    // Check second half of pill based on orientation
    if (current_pill_connection == CONNECTED_RIGHT)
    { // Horizontal
        if (x + 1 >= BOARD_WIDTH || board[y * BOARD_WIDTH + x + 1].color != EMPTY)
            return 0;
    }
    else if (current_pill_connection == CONNECTED_UP)
    { // Vertical
        if (y == 0 || board[(y - 1) * BOARD_WIDTH + x].color != EMPTY)
            return 0;
    }

    return 1;
}

// Move the current pill
unsigned char move_pill(unsigned char dx, unsigned char dy)
{
    unsigned char new_x = current_pill_x + dx;
    unsigned char new_y = current_pill_y + dy;

    // Clear current position
    if (board[current_pill_y * BOARD_WIDTH + current_pill_x].connected == CONNECTED_RIGHT)
    {
        board[current_pill_y * BOARD_WIDTH + current_pill_x + 1].color = EMPTY;
        board[current_pill_y * BOARD_WIDTH + current_pill_x + 1].connected = 0;
    }
    else if (board[current_pill_y * BOARD_WIDTH + current_pill_x].connected == CONNECTED_UP)
    {
        board[(current_pill_y - 1) * BOARD_WIDTH + current_pill_x].color = EMPTY;
        board[(current_pill_y - 1) * BOARD_WIDTH + current_pill_x].connected = 0;
    }
    board[current_pill_y * BOARD_WIDTH + current_pill_x].color = EMPTY;
    board[current_pill_y * BOARD_WIDTH + current_pill_x].connected = 0;

    if (!is_valid_position(new_x, new_y))
    {
        // Restore current position
        place_pill();
        return 0;
    }

    // Set new position
    current_pill_x = new_x;
    current_pill_y = new_y;
    place_pill();

    return 1;
}

// Rotate the current pill
void rotate_pill(void)
{
    if (board[current_pill_y * BOARD_WIDTH + current_pill_x].connected == CONNECTED_RIGHT)
    { // Horizontal to vertical
        if (current_pill_y > 0 && board[(current_pill_y - 1) * BOARD_WIDTH + current_pill_x].color == EMPTY)
        {
            board[(current_pill_y - 1) * BOARD_WIDTH + current_pill_x].color = current_pill_color2;
            board[(current_pill_y - 1) * BOARD_WIDTH + current_pill_x].connected = CONNECTED_DOWN;
            board[current_pill_y * BOARD_WIDTH + current_pill_x].connected = CONNECTED_UP;
            board[current_pill_y * BOARD_WIDTH + current_pill_x + 1].color = EMPTY;
            board[current_pill_y * BOARD_WIDTH + current_pill_x + 1].connected = 0;
            current_pill_connection = CONNECTED_UP;
        }
    }
    else if (board[current_pill_y * BOARD_WIDTH + current_pill_x].connected == CONNECTED_UP)
    { // Vertical to horizontal
        if (current_pill_x < BOARD_WIDTH - 1 && board[current_pill_y * BOARD_WIDTH + current_pill_x + 1].color == EMPTY)
        {
            // Exchange the colors
            unsigned char temp_color = current_pill_color1;
            current_pill_color1 = current_pill_color2;
            current_pill_color2 = temp_color;

            board[current_pill_y * BOARD_WIDTH + current_pill_x + 1].color = current_pill_color2;
            board[current_pill_y * BOARD_WIDTH + current_pill_x + 1].connected = CONNECTED_LEFT;
            board[current_pill_y * BOARD_WIDTH + current_pill_x].color = current_pill_color1;
            board[current_pill_y * BOARD_WIDTH + current_pill_x].connected = CONNECTED_RIGHT;
            board[(current_pill_y - 1) * BOARD_WIDTH + current_pill_x].color = EMPTY;
            board[(current_pill_y - 1) * BOARD_WIDTH + current_pill_x].connected = 0;
            current_pill_connection = CONNECTED_RIGHT;
        }
    }
}

// Generate a new pill
void generate_pill(void)
{
    if (next_pill_color1 != 0 && next_pill_color2 != 0)
    {
        current_pill_color1 = next_pill_color1;
        current_pill_color2 = next_pill_color2;
        next_pill_color1 = PILL_RED + (rand() % 3);
        next_pill_color2 = PILL_RED + (rand() % 3);
    } else {
        current_pill_color1 = PILL_RED + (rand() % 3);
        current_pill_color2 = PILL_RED + (rand() % 3);
        next_pill_color1 = PILL_RED + (rand() % 3);
        next_pill_color2 = PILL_RED + (rand() % 3);
    }

    current_pill_x = BOARD_WIDTH / 2 - 1;
    current_pill_y = 0;
    current_pill_connection = CONNECTED_RIGHT;

    if (!is_valid_position(current_pill_x, current_pill_y))
    {
        game_over = 1;
    }
    else
    {
        place_pill();
    }
}

// Initialize a level
void init_level(void)
{
    unsigned char x, y;

    // Increment level
    level++;

    // Clear the board
    for (y = 0; y < BOARD_HEIGHT; y++)
    {
        for (x = 0; x < BOARD_WIDTH; x++)
        {
            board[y * BOARD_WIDTH + x].color = EMPTY;
            board[y * BOARD_WIDTH + x].connected = 0;
        }
    }

    // Place viruses
    virus_count = 0;
    unsigned char level_viruses = 3 + (2 * (score / 1000)); // Increase difficulty with score
    while (virus_count < level_viruses)
    {
        x = rand() % BOARD_WIDTH;
        y = BOARD_HEIGHT / 2 + (rand() % (BOARD_HEIGHT / 2));
        if (board[y * BOARD_WIDTH + x].color == EMPTY)
        {
            board[y * BOARD_WIDTH + x].color = VIRUS_RED + (rand() % 3);
            virus_count++;
        }
    }

    game_over = 0;
    generate_pill();
    display_next_pill();
    draw_number(score, SCORE_X, SCORE_Y);
    draw_number(level, LEVEL_X, LEVEL_Y);
}

// Initialize a new game
void init_game(void)
{
    score = 0;
    level = 0;
    init_level();
}

// Main game loop
void game_loop(void)
{
    unsigned char frame_counter = 0;
    unsigned char key;

    while (!game_over)
    {
        // Render game state
        render_game();

        // Handle input
        key = key_in();

        if (key == 'o')
        { // Left arrow
            move_pill(-1, 0);
        }
        else if (key == 'p')
        { // Right arrow
            move_pill(1, 0);
        }
        else if (key == 'e')
        { // Down arrow
            if (!move_pill(0, 1))
            {
                // Pill has landed
                clear_lines();
                if (virus_count == 0)
                {
                    // Level cleared
                    init_level();
                }
                else
                {
                    generate_pill();
                    display_next_pill();
                    draw_number(score, SCORE_X, SCORE_Y);
                }
            }
        }
        else if (key == 'r')
        { // Up arrow
            rotate_pill();
        }

        // Move pill down every N frames
        if (++frame_counter >= 30) {  // Adjust for desired speed
            frame_counter = 0;
            if (!move_pill(0, 1)) {
                // Pill has landed
                clear_lines();
                if (virus_count == 0) {
                    // Level cleared
                    init_level();
                } else {
                    generate_pill();
                    display_next_pill();
                    draw_number(score, SCORE_X, SCORE_Y);
                }
            }
        }
    }
}

/********/
/* MAIN */
/********/

void main()
{
    set_palette();

    // Initialize random number generator
    __rand = PEEK(0x5fef);

    while (1)
    {
        // Game menu
        rom_cls();
        draw_bitmap(bitmap_menu, 61, 107, 0, 96);
        // Wait for space key
        while (rom_ci() != ' ')
            ;

        // Game screen
        rom_cls();
        draw_bitmap(bitmap_background_left, 7, 231, 0, 0);
        draw_bitmap(bitmap_background_right, 22, 231, 39, 0);
        draw_bitmap(bitmap_background_btm, 32, 7, 7, 224);

        init_game();

        game_loop();

        // TODO: game over screen
        // Wait for space key
        while (rom_ci() != ' ')
            ;
    }
}
