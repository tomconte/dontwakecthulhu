"""Convert PNG image to Hector bitmap format.

Bitmaps on the Hector are encoded on two bits per pixel. This means that each byte in the display RAM contains four pixels.
The two bits encode the palette index of the pixel.
We are using the following CGA-like palette:

0: black
1: green
2: red
3: white

The first pixel is stored in the two least significant bits of the byte, the second pixel in the next two bits, and so on.
The pixels are stored in the file from left to right and from top to bottom.

This version of the script will output the bitmap in a the binary format that can be directly written to the Hector display RAM.
It is saved as a binary that can be included using the INCBIN directive in the Z80 assembly code.

"""
import sys

from PIL import Image

# Define the RGB values for the palette
PALETTE = [
    (0, 0, 0),  # black
    (0, 255, 0),  # green
    (255, 0, 0),  # red
    (255, 255, 255),  # white
]


def convert_sprites_to_hector(png_file, num_sprites, output_prefix):
    # Open image
    img = Image.open(png_file)
    img = img.convert("RGB")

    # Print image info for debug
    print(f"Image width: {img.width}")
    print(f"Image height: {img.height}")

    # Check height is 16
    if img.height != 16:
        raise ValueError("Image height must be 16 pixels")

    # We are going to process x sprites of 16x width in a loop
    for sprite in range(num_sprites):
        # Open output binary file
        with open(f"build/{output_prefix}_{sprite}.bin", "wb") as f:

            # Also open a file to write the binary data as a C array
            with open(f"build/{output_prefix}_{sprite}.c", "w") as c:
                c.write(f"const unsigned char {output_prefix}_{sprite}[64] = {{\n")

                # Write pixels
                pixel_values = []
                for y in range(img.height):
                    for x in range(16):
                        r, g, b = img.getpixel((sprite * 16 + x, y))

                        # Find the palette index for the pixel
                        if (r, g, b) in PALETTE:
                            pixel = PALETTE.index((r, g, b))
                        else:
                            raise ValueError(f"Unknown color: ({r}, {g}, {b})")

                        # Every 4 pixels, we can write a byte
                        pixel_values.append(pixel)
                        if len(pixel_values) == 4:
                            # Write to the binary file
                            byte = 0
                            for i, p in enumerate(pixel_values):
                                byte |= p << (i * 2)
                            f.write(byte.to_bytes(1, byteorder="little"))

                            # Write to the C file
                            c.write(f"    0x{byte:02x},\n")

                            # Reset pixel values
                            pixel_values = []

                c.write("};\n")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python convert_sprites_to_hector_bin.py <png_file> <num_sprites> <output_prefix>")
        sys.exit(1)

    png_file = sys.argv[1]
    num_sprites = int(sys.argv[2])
    output_prefix = sys.argv[3]

    convert_sprites_to_hector(png_file, num_sprites, output_prefix)
