from PIL import Image
import sys

def rgb_to_332(r, g, b):
    r3 = (r >> 5) & 0x07   # 3 bits
    g3 = (g >> 5) & 0x07   # 3 bits
    b2 = (b >> 6) & 0x03   # 2 bits
    return (r3 << 5) | (g3 << 2) | b2

def png_to_mem(png_path, mem_path):
    img = Image.open(png_path).convert("RGBA")
    width, height = img.size
    pixels = img.load()

    with open(mem_path, "w") as f:
        for y in range(height):
            for x in range(width):
                r, g, b, a = pixels[x, y]

                # Transparency → 0x00
                if a < 128:
                    f.write("00\n")
                else:
                    val = rgb_to_332(r, g, b)
                    f.write(f"{val:02X}\n")

    print(f"Converted {png_path} → {mem_path}")
    print(f"Resolution: {width} x {height}")
    print(f"Total pixels: {width * height}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python png_to_rgb332_mem.py input.png output.mem")
        sys.exit(1)

    png_to_mem(sys.argv[1], sys.argv[2])
