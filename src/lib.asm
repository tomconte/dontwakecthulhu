MODULE lib

PUBLIC _rom_cls
PUBLIC _rom_ci
PUBLIC _vsync
PUBLIC _set_palette
PUBLIC _draw_sprite
PUBLIC _delete_sprite

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

_draw_sprite:
    ; copy the bitmap to screen
    ; - the bitmap is 16x16 pixels
    ; - each bitmap line is made of 4 bytes
    ; - the screen is 64 bytes wide
    ; to use ldir we need: bc = number of bytes to copy, hl = source, de = destination
    ; first we read y from the stack, multiply it by 64 and add x and 0xc000 to get the destination address

    ; read y
    ld hl, 2
    add hl, sp
    ld a, (hl)
    ; multiply y by 64
    ld h, 0
    ld l, a
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ; save hl to de
    ex de, hl
    ; read x
    ld hl, 4
    add hl, sp
    ld a, (hl)
    ; add x to de
    ld h, 0
    ld l, a
    add hl, de
    ; add 0xc000 to hl
    add hl, 0xc000
    ; save hl to de
    ex de, hl
    ; read the source address
    ld hl, 6
    add hl, sp
    ld a, (hl)
    inc hl
    ld b, (hl)
    ; transfer the source address to hl
    ld l, a
    ld h, b

    ; initialize the loop counter
    ld a, 16

spriteloop:
    ; copy four bytes
    ld bc, 4
    ldir
    ; add 60 bytes to hl to go to the next line
    ld bc, 60
    ex de, hl
    add hl, bc
    ex de, hl
    ; decrement a and loop if not zero
    dec a
    jr nz, spriteloop

    ret

_delete_sprite:
    ; clear the sprite from the screen
    ; - the sprite is 16x16 pixels
    ; - the screen is 64 bytes wide
    ; to use ldir we need: bc = number of bytes to copy, hl = source, de = destination
    ; first we read y from the stack, multiply it by 64 and add x and 0xc000 to get the destination address

    ; read y
    ld hl, 2
    add hl, sp
    ld a, (hl)
    ; multiply y by 64
    ld h, 0
    ld l, a
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ; save hl to de
    ex de, hl
    ; read x
    ld hl, 4
    add hl, sp
    ld a, (hl)
    ; add x to de
    ld h, 0
    ld l, a
    add hl, de
    ; add 0xc000 to hl
    add hl, 0xc000
    ; load into ix
    ld ix, hl

    ; we will increment ix by 64 to go to the next line
    ld bc, 64
    ; initialize the loop counter
    ld a, 16

deleteloop:
    ; clear four bytes using offsets
    ld (ix), 0
    ld (ix+1), 0
    ld (ix+2), 0
    ld (ix+3), 0
    ; add 64 bytes to ix to go to the next line
    add ix, bc
    ; decrement a and loop if not zero
    dec a
    jr nz, deleteloop

    ret
