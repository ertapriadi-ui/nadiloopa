#!/usr/bin/env python3
"""Install v2.11.0 visual assets:
1. 3 transparent 3D terrain obstacle sprites (256x256 RGBA PNG) -> assets/sprites/tiles/
2. 10 unique chapter biome backgrounds (720x1600 JPG) -> assets/backgrounds/chapters/
3. Reframed menu hero background (720x1600) so Villains + all 7 Heroes sit cleanly above the bottom dock.
"""

import glob
import os
from collections import deque
from PIL import Image, ImageFilter

ART_DIR = "/home/antigravity/.gemini/jetski/brain/v1/default/jetski_remote_agents_3p/83c26a44-ed48-4bc2-bb6d-7b42c7dadd75"
REPO_DIR = "/home/antigravity/ertapriadi-ui/nadiloopa"


def find_latest(prefix: str) -> str:
    matches = sorted(glob.glob(os.path.join(ART_DIR, f"{prefix}_*.jpg")))
    if not matches:
        raise FileNotFoundError(f"No artifact found for prefix {prefix}")
    return matches[-1]


def remove_white_bg_floodfill(src_path: str, out_path: str, size: int = 256) -> None:
    """Flood-fill remove pure/near-white background from corners/edges, preserving bright interior highlights."""
    im = Image.open(src_path).convert("RGBA")
    w, h = im.size
    px = im.load()

    def is_bg(r: int, g: int, b: int) -> bool:
        # Near-white low-saturation pixels
        mx = max(r, g, b)
        mn = min(r, g, b)
        return mn >= 225 and (mx - mn) <= 24

    visited = [[False] * w for _ in range(h)]
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            r, g, b, _ = px[x, y]
            if is_bg(r, g, b) and not visited[y][x]:
                visited[y][x] = True
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            r, g, b, _ = px[x, y]
            if is_bg(r, g, b) and not visited[y][x]:
                visited[y][x] = True
                q.append((x, y))

    while q:
        cx, cy = q.popleft()
        px[cx, cy] = (0, 0, 0, 0)
        for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
            if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx]:
                r, g, b, _ = px[nx, ny]
                if is_bg(r, g, b):
                    visited[ny][nx] = True
                    q.append((nx, ny))

    # Soften 1px fringe around transparent boundary to eliminate white halo
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            # Check if adjacent to transparent pixel
            adj_trans = (
                px[x - 1, y][3] == 0
                or px[x + 1, y][3] == 0
                or px[x, y - 1][3] == 0
                or px[x, y + 1][3] == 0
            )
            if adj_trans and min(r, g, b) >= 195 and (max(r, g, b) - min(r, g, b)) <= 36:
                lum = (r + g + b) / 3.0
                new_a = int(max(0, min(255, (250.0 - lum) * 4.5)))
                px[x, y] = (r, g, b, new_a)

    # Crop tight bounding box with small padding and center into square canvas
    bbox = im.getbbox()
    if bbox:
        cropped = im.crop(bbox)
    else:
        cropped = im

    cw, ch = cropped.size
    target_inner = int(size * 0.90)
    scale = min(target_inner / float(cw), target_inner / float(ch))
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(resized, ((size - nw) // 2, (size - nh) // 2), resized)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    canvas.save(out_path, "PNG", optimize=True)
    kb = os.path.getsize(out_path) / 1024.0
    print(f"Installed obstacle sprite: {out_path} ({size}x{size}, {kb:.1f} KB)")


def fit_cover_portrait(src_path: str, out_path: str, tw: int = 720, th: int = 1600, quality: int = 84) -> None:
    im = Image.open(src_path).convert("RGB")
    sw, sh = im.size
    target_ratio = tw / float(th)
    src_ratio = sw / float(sh)
    if src_ratio > target_ratio:
        # Wider than target: crop left/right equally
        new_w = int(round(sh * target_ratio))
        x0 = (sw - new_w) // 2
        im = im.crop((x0, 0, x0 + new_w, sh))
    else:
        # Taller than target: crop top/bottom equally
        new_h = int(round(sw / target_ratio))
        y0 = (sh - new_h) // 2
        im = im.crop((0, y0, sw, y0 + new_h))
    im = im.resize((tw, th), Image.Resampling.LANCZOS)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    im.save(out_path, "JPEG", quality=quality, optimize=True, progressive=True)
    kb = os.path.getsize(out_path) / 1024.0
    print(f"Installed chapter bg: {out_path} ({tw}x{th}, {kb:.1f} KB)")


def reframe_menu_hero(src_path: str, out_path: str, tw: int = 720, th: int = 1600) -> None:
    """Place the full 9:16 Villains+Heroes artwork into the top 76% of the 720x1600 canvas,
    and smoothly extend the bottom warm floor into the bottom 24% so the bottom menu dock
    never cuts off the Heart or any organ hero."""
    src = Image.open(src_path).convert("RGB")
    sw, sh = src.size
    # Top 77% = 1232px tall. Maintain 9:16 proportion inside 720x1232 (693x1232 -> fit width 720 -> height 1280)
    # Wait: 720 * (16/9) = 1280px, which is 80.0% of 1600px!
    # Let's place it at 720x1240 (very slight 3% trim from top sky so Villains start nicely at top and Heart ends at y=1140px = 71.2%!)
    hero_h = 1240
    # Crop 3% off very top sky so Villains sit cleanly near top without extra empty dark sky
    crop_top = int(sh * 0.025)
    cropped = src.crop((0, crop_top, sw, sh))
    hero_img = cropped.resize((tw, hero_h), Image.Resampling.LANCZOS)

    canvas = Image.new("RGB", (tw, th))
    canvas.paste(hero_img, (0, 0))

    # Build smooth floor extension for y = hero_h .. th by taking bottom 80px strip,
    # stretching & blurring it, and blending softly into a deep warm twilight-navy floor
    strip = hero_img.crop((0, hero_h - 90, tw, hero_h)).resize(
        (tw, th - hero_h + 60), Image.Resampling.BICUBIC
    )
    strip = strip.filter(ImageFilter.GaussianBlur(radius=18))

    # Darken smoothly toward the bottom so dock buttons have crisp contrast
    s_px = strip.load()
    sh_ext = strip.size[1]
    for y in range(sh_ext):
        t = y / float(max(1, sh_ext - 1))
        # Blend toward rich deep midnight-indigo (12, 24, 38)
        blend = min(0.78, t * 0.85)
        for x in range(tw):
            r, g, b = s_px[x, y]
            nr = int(r * (1.0 - blend) + 12 * blend)
            ng = int(g * (1.0 - blend) + 24 * blend)
            nb = int(b * (1.0 - blend) + 38 * blend)
            s_px[x, y] = (nr, ng, nb)

    # Paste with 60px vertical alpha feather overlap for a totally seamless transition
    mask = Image.new("L", (tw, sh_ext), 255)
    m_px = mask.load()
    for y in range(60):
        alpha = int(255 * (y / 60.0))
        for x in range(tw):
            m_px[x, y] = alpha

    canvas.paste(strip, (0, hero_h - 60), mask)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    # Save as PNG (existing filename in repo is bg_hero_avengers.png) with optimization, or keep exact path
    canvas.save(out_path, "PNG", optimize=True)
    kb = os.path.getsize(out_path) / 1024.0
    print(f"Reframed menu hero: {out_path} ({tw}x{th}, {kb:.1f} KB)")


def main() -> None:
    # 1. Obstacles
    for name in ("rock", "log", "island"):
        src = find_latest(f"obstacle_{name}_raw")
        dst = os.path.join(REPO_DIR, "assets", "sprites", "tiles", f"obstacle_{name}.png")
        remove_white_bg_floodfill(src, dst, size=256)

    # 2. 10 Chapter biome backgrounds
    for ch in range(1, 11):
        src = find_latest(f"bg_ch{ch:02d}_raw")
        dst = os.path.join(REPO_DIR, "assets", "backgrounds", "chapters", f"bg_ch{ch:02d}.jpg")
        fit_cover_portrait(src, dst, tw=720, th=1600, quality=84)

    # 3. Reframe menu hero background so Heart & all 7 Heroes sit cleanly above bottom dock
    hero_src = find_latest("bg_hero_avengers_v2_raw")
    hero_dst = os.path.join(REPO_DIR, "assets", "backgrounds", "bg_hero_avengers.png")
    reframe_menu_hero(hero_src, hero_dst, tw=720, th=1600)


if __name__ == "__main__":
    main()
