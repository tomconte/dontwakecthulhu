default:
	@echo "Please specify a target: clean, compile"

clean:
	@rm -f build/*.c build/*.bin build/*.k7

compile:
	@python scripts/convert_sprites_to_hector.py png/drmario_sprites_v3.png 15 pill
	@python scripts/convert_sprites_to_hector.py png/drmario_virus.png 3 virus
	@python scripts/convert_bitmap_to_hector.py png/cthulhu-background-left.png background_left
	@python scripts/convert_bitmap_to_hector.py png/cthulhu-background-right.png background_right
	@zcc +sos -crt0=src/crt0.asm src/game.c src/asm.c build/pill_*.c build/virus_*.c build/background_left.c build/background_right.c -o build/dontwake.bin

k7:
	@python scripts/create_k7.py
