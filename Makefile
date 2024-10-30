SOURCES = 	src/game.c src/lib.asm \
			build/pill_*.c build/virus_*.c build/digit_*.c build/cleared_*.c \
			build/background_left.c build/background_right.c build/background_btm.c \
			build/gameover.c

ZX0 = ../ZX0/win/zx0.exe

default:
	@echo "Please specify a target: clean, bitmaps, compile, k7"

clean:
	rm -f build/*.c build/*.bin build/*.k7 build/*.zx0

bitmaps:
	python scripts/convert_sprites_to_hector.py png/drmario_sprites_v3.png 15 pill
	python scripts/convert_sprites_to_hector.py png/sprite_clear.png 1 cleared
	python scripts/convert_sprites_to_hector.py png/drmario_virus.png 3 virus
	python scripts/convert_bitmap_to_hector.py png/backv2-left.png background_left
	python scripts/convert_bitmap_to_hector.py png/backv2-right.png background_right
	python scripts/convert_bitmap_to_hector.py png/backv2-bottom.png background_btm
	python scripts/convert_bitmap_to_hector.py --full png/menu-text-new.png menu
	python scripts/convert_bitmap_to_hector.py --full --last 231 png/cthulhu_splashscreen.png splash
	python scripts/convert_bitmap_to_hector.py --full png/cthulhu_splash_small.png menubg
	python scripts/convert_digits_to_hector.py png/font-cthulhu.png digit
	python scripts/convert_bitmap_to_hector.py png/game-over.png gameover
	$(ZX0) build/menu.bin
	$(ZX0) build/menubg.bin

compile:
	z88dk-z80asm -b src/start.asm && mv src/start.bin build/start.bin && rm -f src/start.o
	z88dk-z80asm -b src/start_hrx.asm && mv src/start_hrx.bin build/start_hrx.bin && rm -f src/start_hrx.o
	zcc +sos -crt0=src/crt0.asm $(SOURCES) -o build/dontwake.bin
	zcc +sos -crt0=src/crt0.asm $(SOURCES) -o build/dontwake_hrx.bin -Ca-DHRX

k7:
	python scripts/create_k7.py HR
	python scripts/create_k7.py HRX
