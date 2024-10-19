MODULE lib

PUBLIC _rom_cls
PUBLIC _rom_ci
PUBLIC _vsync
PUBLIC _key_in
PUBLIC _set_palette
PUBLIC _draw_sprite
PUBLIC _delete_sprite
PUBLIC _draw_digit
PUBLIC _draw_background_left
PUBLIC _draw_background_right
PUBLIC _draw_background_btm

EXTERN _bitmap_background_left
EXTERN _bitmap_background_right
EXTERN _bitmap_background_btm

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
    ld l, a
    ret

_key_in:
    IFDEF HRX
    call 0x10d3
    ELSE
    call 0x07e7
    ENDIF
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

_draw_background_left:
    ld b, 231          ; Set loop counter for rows (i = 0; i < 231; i++)
    ld hl, _bitmap_background_left ; Load the address of bitmap_background_left into HL
    ld de, 0xc000      ; Start address in video memory

draw_background_left_row:
    push bc            ; Save the row counter
    ld c, 7            ; Set loop counter for columns (j = 0; j < 7; j++)

draw_background_left_col:
    ld a, (hl)         ; Load the next byte from bitmap_background_left
    ld (de), a         ; Store it in video memory
    inc hl             ; Move to the next byte in bitmap_background_left
    inc de             ; Move to the next byte in video memory
    dec c              ; Decrement column counter
    jr nz, draw_background_left_col ; Repeat for all columns

    pop bc             ; Restore the row counter
    ld a, e            ; Get the low byte of DE
    add a, 64-7        ; Move to the next row in video memory
    ld e, a            ; Store the new low byte of DE
    ld a, d            ; Get the high byte of DE
    adc a, 0           ; Add carry if necessary
    ld d, a            ; Store the new high byte of DE
    dec b              ; Decrement row counter
    jr nz, draw_background_left_row ; Repeat for all rows

    ret                ; Return from the function

_draw_background_right:
    ld b, 231          ; Set loop counter for rows (i = 0; i < 231; i++)
    ld hl, _bitmap_background_right ; Load the address of bitmap_background_left into HL
    ld de, 0xc000+39    ; Start address in video memory

draw_background_right_row:
    push bc            ; Save the row counter
    ld c, 22           ; Set loop counter for columns (j = 0; j < 7; j++)

draw_background_right_col:
    ld a, (hl)         ; Load the next byte from bitmap_background_left
    ld (de), a         ; Store it in video memory
    inc hl             ; Move to the next byte in bitmap_background_left
    inc de             ; Move to the next byte in video memory
    dec c              ; Decrement column counter
    jr nz, draw_background_right_col ; Repeat for all columns

    pop bc             ; Restore the row counter
    ld a, e            ; Get the low byte of DE
    add a, 64-22       ; Move to the next row in video memory
    ld e, a            ; Store the new low byte of DE
    ld a, d            ; Get the high byte of DE
    adc a, 0           ; Add carry if necessary
    ld d, a            ; Store the new high byte of DE
    dec b              ; Decrement row counter
    jr nz, draw_background_right_row ; Repeat for all rows

    ret                ; Return from the function

_draw_background_btm:
    ld b, 7          ; Set loop counter for rows (i = 0; i < 231; i++)
    ld hl, _bitmap_background_btm ; Load the address of bitmap_background_left into HL
    ld de, 0xc000 + (224*64) + 7    ; Start address in video memory

draw_background_btm_row:
    push bc            ; Save the row counter
    ld c, 32           ; Set loop counter for columns (j = 0; j < 7; j++)

draw_background_btm_col:
    ld a, (hl)         ; Load the next byte from bitmap_background_left
    ld (de), a         ; Store it in video memory
    inc hl             ; Move to the next byte in bitmap_background_left
    inc de             ; Move to the next byte in video memory
    dec c              ; Decrement column counter
    jr nz, draw_background_btm_col ; Repeat for all columns

    pop bc             ; Restore the row counter
    ld a, e            ; Get the low byte of DE
    add a, 64-32       ; Move to the next row in video memory
    ld e, a            ; Store the new low byte of DE
    ld a, d            ; Get the high byte of DE
    adc a, 0           ; Add carry if necessary
    ld d, a            ; Store the new high byte of DE
    dec b              ; Decrement row counter
    jr nz, draw_background_btm_row ; Repeat for all rows

    ret                ; Return from the function
