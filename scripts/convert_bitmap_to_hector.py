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


def convert_bitmap_to_hector(png_file, output_prefix):
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

            # Write pixels
            for y in range(img.height):
                pixel_values = []
                for x in range(img.width):
                    r, g, b = img.getpixel((x, y))

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

            c.write("};\n")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(
            "Usage: python convert_sprites_to_hector_bin.py <png_file> <output_prefix>"
        )
        sys.exit(1)

    png_file = sys.argv[1]
    output_prefix = sys.argv[2]

    convert_bitmap_to_hector(png_file, output_prefix)
