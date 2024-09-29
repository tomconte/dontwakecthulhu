MODULE lib

PUBLIC _rom_cls
PUBLIC _rom_ci
PUBLIC _vsync
PUBLIC _set_palette

_rom_cls:
    call 0x0d2f
    ret

_rom_ci:
    call 0x07e0
    ld l, a
    ret

_vsync:
    halt
    ret

_set_palette:
    ld hl, 0x1000
    ld (hl), 0x08    ; color0 = 0, color2 = 5
    ld hl, 0x1800
    ld (hl), 0x3a    ; color1 = 2, color3 = 7
    ret
