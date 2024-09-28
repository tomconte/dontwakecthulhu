void rom_cls()
{
    __asm
    call 0x0d2f
    __endasm;
}

unsigned char rom_ci()
{
    __asm
    call 0x07e0
    ld l, a
    __endasm;
}

void vsync()
{
    __asm
    halt
    __endasm;
}

void set_palette()
{
    __asm
    ld hl, 0x1000
    ld (hl), 0x08    ; color0 = 0, color2 = 5
    ld hl, 0x1800
    ld (hl), 0x3a    ; color1 = 2, color3 = 7
    __endasm;
}
