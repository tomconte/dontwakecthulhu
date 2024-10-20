    MODULE Start

    ORG 0x4c00

    ld sp, 0xc000

    ; On the HRX, enable VRAM paging
    ld (0x0800), a

    jp 0x6000
