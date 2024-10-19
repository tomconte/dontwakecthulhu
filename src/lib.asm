MODULE lib

PUBLIC _rom_cls
PUBLIC _rom_ci
PUBLIC _vsync
PUBLIC _key_in
PUBLIC _set_palette
PUBLIC _draw_sprite
PUBLIC _delete_sprite
PUBLIC _draw_digit
PUBLIC _draw_bitmap
PUBLIC _decompress_menu
PUBLIC _decompress_menubg

; -----------------------------------------------------------------------------
; ROM routines
; -----------------------------------------------------------------------------

_rom_cls:
    IFDEF HRX
    ;ld a, 0x0f
    ;rst 0x28
    nop
    ELSE
    call 0x0d2f
    ENDIF
    ret

_rom_ci:
    IFDEF HRX
    call 0x10ca
    ELSE
    call 0x07e0
    ENDIF
    ld h, 0
    ld l, a
    ret

_key_in:
    IFDEF HRX
    call 0x10d3
    ELSE
    call 0x07e7
    ENDIF
    ld h, 0
    ld l, a
    ret

; -----------------------------------------------------------------------------
; Wait for the next vertical sync (not used)
; -----------------------------------------------------------------------------

_vsync:
    halt
    ret

; -----------------------------------------------------------------------------
; Set the palette
; -----------------------------------------------------------------------------

_set_palette:
    ld hl, 0x1000
    ld (hl), 0x08    ; color0 = 0, color2 = 5
    ld hl, 0x1800
    ld (hl), 0x3a    ; color1 = 2, color3 = 7
    ret

; -----------------------------------------------------------------------------
; Draw a sprite on the screen
; -----------------------------------------------------------------------------

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

; -----------------------------------------------------------------------------
; Delete a sprite from the screen
; -----------------------------------------------------------------------------

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

; -----------------------------------------------------------------------------
; Draw a digit on the screen
; -----------------------------------------------------------------------------

_draw_digit:
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
    ld a, 8

digitloop:
    ; copy one byte
    ld bc, 1
    ldi
    ; add 63 bytes to de to go to the next line
    ld bc, 63
    ex de, hl
    add hl, bc
    ex de, hl
    ; decrement a and loop if not zero
    dec a
    jr nz, digitloop

    ret

; -----------------------------------------------------------------------------
; Draw a bitmap on the screen
; -----------------------------------------------------------------------------

_draw_bitmap:
    ; Read parameters from the stack
    ; y start offset
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
    ; x start offset
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
    ; rows (height)
    ld hl, 6
    add hl, sp
    ld b, (hl)
    ; columns (width)
    ld hl, 8
    add hl, sp
    ld c, (hl)
    ; address of the bitmap
    ld hl, 10
    add hl, sp
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a

draw_bitmap_row:
    push bc            ; Save the row counter
    ld a, c            ; Load the column counter into a

draw_bitmap_col:
    ld b, (hl)         ; Load the next byte from the bitmap
    ld (de), b         ; Store it in video memory
    inc hl             ; Move to the next byte in the bitmap
    inc de             ; Move to the next byte in video memory
    dec a              ; Decrement column counter
    jr nz, draw_bitmap_col ; Repeat for all columns

    pop bc             ; Restore the row counter

    ld a, 64
    sub c
    add a, e
    ld e, a
    ld a, d
    adc a, 0
    ld d, a

    dec b              ; Decrement row counter
    jr nz, draw_bitmap_row ; Repeat for all rows

    ret                ; Return from the function

; -----------------------------------------------------------------------------
; Decompress menu and menubg
; -----------------------------------------------------------------------------

_decompress_menu:
    ld hl, bitmap_menu
    ld de, 0xc000 + (96*64)
    call dzx0_standard
    ret

_decompress_menubg:
    ld hl, bitmap_menubg
    ld de, 0xc000
    call dzx0_standard
    ret

; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas & Urusergi
; "Standard" version (68 bytes only)
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------

PUBLIC dzx0_standard

dzx0_standard:
        ld      bc, $ffff               ; preserve default offset 1
        push    bc
        inc     bc
        ld      a, $80
dzx0s_literals:
        call    dzx0s_elias             ; obtain length
        ldir                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0s_new_offset
        call    dzx0s_elias             ; obtain length
dzx0s_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0s_literals
dzx0s_new_offset:
        pop     bc                      ; discard last offset
        ld      c, $fe                  ; prepare negative offset
        call    dzx0s_elias_loop        ; obtain offset MSB
        inc     c
        ret     z                       ; check end marker
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        rr      b                       ; last offset bit becomes first length bit
        rr      c
        push    bc                      ; preserve new offset
        ld      bc, 1                   ; obtain length
        call    nc, dzx0s_elias_backtrack
        inc     bc
        jr      dzx0s_copy
dzx0s_elias:
        inc     c                       ; interlaced Elias gamma coding
dzx0s_elias_loop:
        add     a, a
        jr      nz, dzx0s_elias_skip
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0s_elias_skip:
        ret     c
dzx0s_elias_backtrack:
        add     a, a
        rl      c
        rl      b
        jr      dzx0s_elias_loop
; -----------------------------------------------------------------------------

bitmap_menu:
    incbin "build/menu.bin.zx0"

bitmap_menubg:
    incbin "build/menubg.bin.zx0"
