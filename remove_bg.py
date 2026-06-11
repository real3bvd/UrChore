"""
Remove the cream/paper background from hedgehog PNG images.

Strategy:
1. Flood-fill from the corners/edges to find the background region.
2. Any pixel that is "light enough" (close to white/cream) AND connected
   to the border is made fully transparent.
3. This preserves the hedgehog's internal light areas (belly, face) while
   removing only the outer background.
"""

from PIL import Image
import os
import collections

def is_light_pixel(r, g, b, a, threshold=200):
    """Check if a pixel is light enough to be considered background."""
    if a < 128:  # already transparent
        return True
    return r > threshold and g > threshold and b > threshold

def remove_background(image_path, output_path, threshold=195):
    """Remove light background via flood-fill from edges."""
    img = Image.open(image_path).convert("RGBA")
    pixels = img.load()
    w, h = img.size

    # Track visited pixels
    visited = set()
    to_clear = set()
    queue = collections.deque()

    # Seed from all border pixels
    for x in range(w):
        queue.append((x, 0))
        queue.append((x, h - 1))
    for y in range(h):
        queue.append((0, y))
        queue.append((w - 1, y))

    # BFS flood fill from edges
    while queue:
        x, y = queue.popleft()
        if (x, y) in visited:
            continue
        if x < 0 or x >= w or y < 0 or y >= h:
            continue
        visited.add((x, y))

        r, g, b, a = pixels[x, y]
        if is_light_pixel(r, g, b, a, threshold):
            to_clear.add((x, y))
            # Add 4-connected neighbors
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
                    queue.append((nx, ny))

    # Clear background pixels
    for x, y in to_clear:
        pixels[x, y] = (0, 0, 0, 0)

    # Also smooth the edges: make semi-transparent border pixels softer
    # by checking neighbors of the cleared region
    edge_pixels = set()
    for x, y in to_clear:
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1), (-1,-1), (1,-1), (-1,1), (1,1)]:
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in to_clear:
                edge_pixels.add((nx, ny))

    # Soften edge pixels slightly for anti-aliasing
    for x, y in edge_pixels:
        r, g, b, a = pixels[x, y]
        if r > 220 and g > 220 and b > 220 and a > 200:
            # Make very light edge pixels semi-transparent
            new_alpha = max(0, min(255, int(a * 0.5)))
            pixels[x, y] = (r, g, b, new_alpha)

    img.save(output_path, "PNG")
    print(f"  OK {os.path.basename(output_path)} - cleared {len(to_clear)} bg pixels, softened {len(edge_pixels)} edge pixels")

def main():
    assets_dir = os.path.join("assets", "images")
    
    files = [
        ("hedgehog_waving.png",    195),
        ("hedgehog_cleaning.png",  195),
        ("hedgehog_scrubbing.png", 195),
        ("hedgehog_mopping.png",   195),
        ("hedgehog_washing.png",   195),
    ]

    print("Removing backgrounds from hedgehog images...\n")
    for filename, thresh in files:
        src = os.path.join(assets_dir, filename)
        if os.path.exists(src):
            # Overwrite in-place
            remove_background(src, src, threshold=thresh)
        else:
            print(f"  SKIP {filename} not found!")

    print("\nDone! All images now have transparent backgrounds.")

if __name__ == "__main__":
    main()
