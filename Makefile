default:
	@echo "Please specify a target: clean, bitmaps, compile, k7"

clean:
	@rm -f build/*.c build/*.bin build/*.k7

bitmaps:
	@python scripts/convert_sprites_to_hector.py png/drmario_sprites_v3.png 15 pill
	@python scripts/convert_sprites_to_hector.py png/drmario_virus.png 3 virus
	@python scripts/convert_bitmap_to_hector.py png/backv2-left.png background_left
	@python scripts/convert_bitmap_to_hector.py png/backv2-right.png background_right
	@python scripts/convert_bitmap_to_hector.py png/backv2-bottom.png background_btm
	@python scripts/convert_bitmap_to_hector.py --full --last 231 png/cthulhu_splashscreen.png splash

compile:
	@z88dk-z80asm -b src/start.asm && mv src/start.bin build && rm -f src/start.o
	@zcc +sos -crt0=src/crt0.asm src/game.c src/lib.asm build/lib.o build/pill_*.c build/virus_*.c build/background_left.c build/background_right.c build/background_btm.c -o build/dontwake.bin

k7:
	@python scripts/create_k7.py
