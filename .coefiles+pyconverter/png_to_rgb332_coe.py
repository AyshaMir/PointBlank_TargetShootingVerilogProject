from PIL import Image
import sys

def rgb_to_332(r, g, b):
    r3 = (r >> 5) & 0x07   # 3 bits
    g3 = (g >> 5) & 0x07   # 3 bits
    b2 = (b >> 6) & 0x03   # 2 bits
    return (r3 << 5) | (g3 << 2) | b2

def png_to_coe(png_path, coe_path):
    img = Image.open(png_path).convert("RGB")
    width, height = img.size
    pixels = img.load()

    with open(coe_path, "w") as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")

        values = []
        for y in range(height):
            for x in range(width):
                r, g, b = pixels[x, y]
                values.append(f"{rgb_to_332(r, g, b):02X}")

        f.write(",\n".join(values))
        f.write(";\n")

    print(f"Converted {png_path} → {coe_path}")
    print(f"Resolution: {width} x {height}")
    print(f"Total pixels: {width * height}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python png_to_rgb332_coe.py input.png output.coe")
        sys.exit(1)

    png_to_coe(sys.argv[1], sys.argv[2])
