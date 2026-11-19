#!/usr/bin/env python3
"""Install v2.9.0 art assets for NADILOOPA:
- High-contrast anatomical Heart (red + blue veins) in soft rose-pink crystal gem
  -> assets/sprites/tiles/organ_heart.png, organ_heart_happy.png
  -> assets/icons/icon_1024.png (Android launcher icon)
- 3D glossy blockbuster NADILOOPA logo
  -> assets/ui/logo_nadiloopa_3d.png
"""

from collections import deque
from pathlib import Path
import numpy as np
from PIL import Image, ImageEnhance, ImageFilter

ART_DIR = Path(
    "/home/antigravity/.gemini/jetski/brain/v1/default/jetski_remote_agents_3p/"
    "83c26a44-ed48-4bc2-bb6d-7b42c7dadd75"
)
REPO = Path("/home/antigravity/ertapriadi-ui/nadiloopa")


def find_latest(prefix: str) -> Path:
    matches = sorted(ART_DIR.glob(f"{prefix}*.jpg"))
    if not matches:
        raise FileNotFoundError(f"Missing {prefix}*.jpg in {ART_DIR}")
    return matches[-1]


def cutout_gem(src: Path, size: int, fill_ratio: float = 0.94) -> Image.Image:
    im = Image.open(src).convert("RGBA")
    arr = np.array(im, dtype=np.int16)
    h, w, _ = arr.shape
    rgb = arr[:, :, :3]
    sat = rgb.max(axis=2) - rgb.min(axis=2)
    lum = rgb.max(axis=2)
    # Pure black, pure white, or neutral gray drop-shadow outside the rose-pink gem frame
    bg_candidate = (lum < 38) | (sat < 22)

    visited = np.zeros((h, w), dtype=bool)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if bg_candidate[y, x] and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if bg_candidate[y, x] and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))

    while q:
        cy, cx = q.popleft()
        for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and bg_candidate[ny, nx]:
                visited[ny, nx] = True
                q.append((ny, nx))

    alpha = np.where(visited, 0, 255).astype(np.uint8)
    alpha_soft = Image.fromarray(alpha, mode="L").filter(ImageFilter.GaussianBlur(radius=0.9))
    alpha_arr = np.minimum(alpha, np.array(alpha_soft, dtype=np.uint8))

    out = arr.astype(np.uint8)
    out[:, :, 3] = alpha_arr
    rgba = Image.fromarray(out, mode="RGBA")
    bbox = rgba.getbbox()
    if bbox:
        rgba = rgba.crop(bbox)

    max_dim = int(round(size * fill_ratio))
    scale = min(max_dim / rgba.width, max_dim / rgba.height)
    nw = max(1, int(round(rgba.width * scale)))
    nh = max(1, int(round(rgba.height * scale)))
    rgba = rgba.resize((nw, nh), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(rgba, ((size - nw) // 2, (size - nh) // 2), rgba)
    return canvas


def make_happy_variant(base: Image.Image) -> Image.Image:
    r, g, b, a = base.split()
    rgb = Image.merge("RGB", (r, g, b))
    rgb = ImageEnhance.Brightness(rgb).enhance(1.14)
    rgb = ImageEnhance.Color(rgb).enhance(1.18)
    bright = Image.merge("RGBA", (*rgb.split(), a))
    glow_alpha = a.filter(ImageFilter.GaussianBlur(radius=6))
    glow = Image.new("RGBA", base.size, (255, 244, 175, 0))
    glow.putalpha(glow_alpha.point(lambda p: int(p * 0.55)))
    return Image.alpha_composite(glow, bright)


def install_heart_and_app_icon() -> None:
    src = find_latest("organ_heart_bluevein_raw_")
    tile_base = cutout_gem(src, size=256, fill_ratio=0.94)
    tile_happy = make_happy_variant(tile_base)
    tile_base.save(REPO / "assets/sprites/tiles/organ_heart.png", "PNG", optimize=True)
    tile_happy.save(REPO / "assets/sprites/tiles/organ_heart_happy.png", "PNG", optimize=True)

    # 1024x1024 Android App Icon: rich deep-teal radial/rounded badge behind the gleaming Heart crystal gem
    app_gem = cutout_gem(src, size=1024, fill_ratio=0.90)
    yy, xx = np.mgrid[0:1024, 0:1024]
    dist = np.sqrt((xx - 512) ** 2 + (yy - 512) ** 2) / 512.0
    grad = np.clip(1.0 - dist * 0.85, 0.0, 1.0)
    bg_arr = np.zeros((1024, 1024, 4), dtype=np.uint8)
    bg_arr[:, :, 0] = np.clip(26 + grad * 52, 0, 255).astype(np.uint8)
    bg_arr[:, :, 1] = np.clip(54 + grad * 74, 0, 255).astype(np.uint8)
    bg_arr[:, :, 2] = np.clip(62 + grad * 68, 0, 255).astype(np.uint8)
    bg_arr[:, :, 3] = 255
    icon_out = Image.alpha_composite(Image.fromarray(bg_arr, mode="RGBA"), app_gem)
    icon_out.save(REPO / "assets/icons/icon_1024.png", "PNG", optimize=True)
    print("[OK] Installed organ_heart.png, organ_heart_happy.png, and assets/icons/icon_1024.png")


def install_3d_logo() -> None:
    src = find_latest("logo_nadiloopa_3d_raw_")
    im = Image.open(src).convert("RGBA")
    arr = np.array(im, dtype=np.float32)
    h, w, _ = arr.shape
    rgb = arr[:, :, :3]
    lum = rgb.max(axis=2)

    # Identify solid letter bodies (teal/navy 3D bevels have strong blue/green channel > 55 or bright gold > 90)
    solid_body = (lum >= 88) | ((rgb[:, :, 2] >= 58) & (rgb[:, :, 1] >= 42))
    # Smooth un-premultiplied alpha for sparkles & red ECG glow on pure black background
    glow_alpha = np.clip((lum - 18.0) / 145.0, 0.0, 1.0)
    alpha_f = np.where(solid_body, 1.0, glow_alpha)

    # Un-premultiply dark glow pixels so sparkles & ECG stay bright gold/red instead of dark brown!
    safe_a = np.maximum(alpha_f, 0.08)[:, :, None]
    unprem = np.where(solid_body[:, :, None], rgb, np.clip(rgb / safe_a, 0.0, 255.0))

    out = np.zeros((h, w, 4), dtype=np.uint8)
    out[:, :, :3] = unprem.astype(np.uint8)
    out[:, :, 3] = np.clip(alpha_f * 255.0, 0, 255).astype(np.uint8)
    # Remove tiny faint noise specks (< 16 alpha)
    out[out[:, :, 3] < 16, 3] = 0

    rgba = Image.fromarray(out, mode="RGBA")
    bbox = rgba.getbbox()
    if bbox:
        rgba = rgba.crop(bbox)

    target_w, target_h = 960, 360
    scale = min((target_w - 16) / rgba.width, (target_h - 16) / rgba.height)
    nw = max(1, int(round(rgba.width * scale)))
    nh = max(1, int(round(rgba.height * scale)))
    rgba = rgba.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    canvas.paste(rgba, ((target_w - nw) // 2, (target_h - nh) // 2), rgba)

    dst = REPO / "assets/ui/logo_nadiloopa_3d.png"
    dst.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(dst, "PNG", optimize=True)
    print(f"[OK] Installed clean 3D logo -> {dst} ({canvas.size})")


if __name__ == "__main__":
    install_heart_and_app_icon()
    install_3d_logo()
