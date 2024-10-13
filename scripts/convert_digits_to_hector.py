"""Convert PNG image to Hector bitmap format."""
import sys

from PIL import Image

# Define the RGB values for the palette
PALETTE = [
    (0, 0, 0),  # black
    (0, 255, 0),  # green
    (255, 0, 0),  # red
    (255, 255, 255),  # white
]


# Convert the digits to Hector format. The digits are 4x10 pixels each. They use a single color, white.
# The PNG file must contain the following characters: "1234567890." (there is a dot in the digits so we can use it as a separator) 
def convert_digits_to_hector(png_file, output_prefix):
    # Open image
    img = Image.open(png_file)
    img = img.convert("RGB")

    # Print image info for debug
    print(f"Image width: {img.width}")
    print(f"Image height: {img.height}")

    # Check height is 10
    if img.height != 8:
        raise ValueError("Image height must be 10 pixels")

    # We are going to process 11 digits of 4x10 width in a loop
    for digit in range(11):
        # Open output binary file
        with open(f"build/{output_prefix}_{digit}.bin", "wb") as f:

            # Also open a file to write the binary data as a C array
            with open(f"build/{output_prefix}_{digit}.c", "w") as c:
                c.write(f"const unsigned char {output_prefix}_{digit}[8] = {{\n")

                # Write pixels
                pixel_values = []
                for y in range(img.height):
                    for x in range(4):
                        r, g, b = img.getpixel((digit * 4 + x, y))

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
    if len(sys.argv) != 3:
        print("Usage: python convert_digits_to_hector_bin.py <png_file> <output_prefix>")
        sys.exit(1)

    png_file = sys.argv[1]
    output_prefix = sys.argv[2]

    convert_digits_to_hector(png_file, output_prefix)
