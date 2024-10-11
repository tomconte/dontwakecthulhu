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

import argparse
import sys

from PIL import Image

# Define the RGB values for the palette
PALETTE = [
    (0, 0, 0),  # black
    (0, 255, 0),  # green
    (255, 0, 0),  # red
    (255, 255, 255),  # white
]


def convert_bitmap_to_hector(png_file, output_prefix, include_full_line=False, last_lines=None):
    # Open image
    img = Image.open(png_file)
    img = img.convert("RGB")

    # Print image info for debug
    print(f"Image width: {img.width}")
    print(f"Image height: {img.height}")

    # Warning is the width is not a multiple of 4
    if img.width % 4 != 0:
        print("Warning: Image width is not a multiple of 4")

    # Calculate total size in bytes of the resulting bitmap
    # Take into account that the width will be rounded up to the next multiple of 4
    total_size = (img.height * ((img.width + 3) // 4))

    # Open output binary file
    with open(f"build/{output_prefix}.bin", "wb") as f:

        # Also open a file to write the binary data as a C array
        with open(f"build/{output_prefix}.c", "w") as c:
            c.write(f"const unsigned char bitmap_{output_prefix}[{total_size}] = {{\n")

            # Write the last lines only
            if last_lines:
                start_line = img.height - last_lines
            else:
                start_line = 0

            # Write pixels
            for y in range(start_line, img.height):
                pixel_values = []
                for x in range(img.width):
                    r, g, b = img.getpixel((x, y))

                    # Find the palette index for the pixel
                    if (r, g, b) in PALETTE:
                        pixel = PALETTE.index((r, g, b))
                    else:
                        # Unknown color, default to black
                        print(f"Unknown color at ({x}, {y}): {r:02x}, {g:02x}, {b:02x}")
                        pixel = 0

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

                # If we have remaining pixels, write them
                # If less than 4 pixels, fill with black
                if pixel_values:
                    while len(pixel_values) < 4:
                        pixel_values.append(0)

                    # Write to the binary file
                    byte = 0
                    for i, p in enumerate(pixel_values):
                        byte |= p << (i * 2)
                    f.write(byte.to_bytes(1, byteorder="little"))

                    # Write to the C file
                    c.write(f"    0x{byte:02x},\n")

                # Now add pixels to reach 256 pixels per line
                if include_full_line:
                    for i in range(0, 64 - ((img.width + 3) // 4)):
                        f.write(b"\x00")
                        c.write("    0x00,\n")

            c.write("};\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert PNG image to Hector bitmap format.")
    parser.add_argument("png_file", help="Path to the PNG file to convert")
    parser.add_argument("output_prefix", help="Prefix for the output files")
    parser.add_argument("--full", action="store_true", help="Include full 256 pixels per line in the output")
    parser.add_argument("--last", help="Only output the last n lines", type=int, action="store"),

    args = parser.parse_args()

    png_file = args.png_file
    output_prefix = args.output_prefix
    include_full_line = args.full
    last_lines = args.last

    convert_bitmap_to_hector(png_file, output_prefix, include_full_line, last_lines)
