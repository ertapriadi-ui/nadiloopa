#!/usr/bin/env python3
"""Process and install v2.8.0 art assets for NADILOOPA:
- Avengers-style hero poster -> assets/backgrounds/bg_hero_avengers.png
- 6 story comic event banners -> assets/sprites/events/event_<id>.png
- 7 natural-color 3D organ gems -> assets/sprites/tiles/organ_<name>.png (+ _happy.png)
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
        raise FileNotFoundError(f"Missing artifact matching {prefix}*.jpg in {ART_DIR}")
    return matches[-1]


def install_hero_poster() -> None:
    src = find_latest("bg_hero_avengers_v2_raw_")
    dst = REPO / "assets/backgrounds/bg_hero_avengers.png"
    dst.parent.mkdir(parents=True, exist_ok=True)
    im = Image.open(src).convert("RGB")
    # Center-crop/resize to crisp 1080x1920 portrait cover
    target_w, target_h = 1080, 1920
    scale = max(target_w / im.width, target_h / im.height)
    new_w, new_h = int(round(im.width * scale)), int(round(im.height * scale))
    im = im.resize((new_w, new_h), Image.Resampling.LANCZOS)
    left = (new_w - target_w) // 2
    top = (new_h - target_h) // 2
    im = im.crop((left, top, left + target_w, top + target_h))
    im.save(dst, "PNG", optimize=True)
    print(f"[OK] Hero poster -> {dst} ({im.size})")


def install_event_banners() -> None:
    events = [
        "wildfire_haze",
        "binge_drinking",
        "all_nighter",
        "screen_marathon",
        "junk_feast",
        "smoke_wave",
    ]
    out_dir = REPO / "assets/sprites/events"
    out_dir.mkdir(parents=True, exist_ok=True)
    target_w, target_h = 640, 360
    for ev in events:
        src = find_latest(f"event_{ev}_raw_")
        dst = out_dir / f"event_{ev}.png"
        im = Image.open(src).convert("RGB")
        scale = max(target_w / im.width, target_h / im.height)
        new_w, new_h = int(round(im.width * scale)), int(round(im.height * scale))
        im = im.resize((new_w, new_h), Image.Resampling.LANCZOS)
        left = (new_w - target_w) // 2
        top = (new_h - target_h) // 2
        im = im.crop((left, top, left + target_w, top + target_h))
        im.save(dst, "PNG", optimize=True)
        print(f"[OK] Event banner -> {dst} ({im.size})")


def cutout_organ(src: Path, size: int = 256, fill_ratio: float = 0.94) -> Image.Image:
    im = Image.open(src).convert("RGBA")
    arr = np.array(im, dtype=np.int16)
    h, w, _ = arr.shape
    rgb = arr[:, :, :3]

    # Sample each of the 4 corners independently (handles pure black, pure white, or neutral gray shadows)
    # Neutral grayscale pixels outside the colorful ruby/sapphire/emerald gem frame are background!
    sat = rgb.max(axis=2) - rgb.min(axis=2)
    corners = [rgb[0, 0], rgb[0, w - 1], rgb[h - 1, 0], rgb[h - 1, w - 1]]
    bg_candidate = np.zeros((h, w), dtype=bool)
    for c_rgb in corners:
        bg_candidate |= (np.abs(rgb - c_rgb).max(axis=2) < 34)
    # Also allow neutral grayscale drop-shadow gradients connected to corners (saturation < 24)
    bg_candidate |= (sat < 22)

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

    # Feather 1px anti-aliased fringe along the boundary
    alpha_img = Image.fromarray(alpha, mode="L")
    alpha_soft = alpha_img.filter(ImageFilter.GaussianBlur(radius=0.8))
    alpha_arr = np.minimum(alpha, np.array(alpha_soft, dtype=np.uint8))

    out = arr.astype(np.uint8)
    out[:, :, 3] = alpha_arr
    rgba = Image.fromarray(out, mode="RGBA")

    # Tight crop to non-transparent bounding box
    bbox = rgba.getbbox()
    if bbox:
        rgba = rgba.crop(bbox)

    # Resize to fill ~94% of 256x256 square
    max_dim = int(round(size * fill_ratio))
    scale = min(max_dim / rgba.width, max_dim / rgba.height)
    nw = max(1, int(round(rgba.width * scale)))
    nh = max(1, int(round(rgba.height * scale)))
    rgba = rgba.resize((nw, nh), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(rgba, ((size - nw) // 2, (size - nh) // 2), rgba)
    return canvas


def make_happy_variant(base: Image.Image) -> Image.Image:
    # Subtle golden rim glow + brightness/saturation boost for active/selected/victory state
    r, g, b, a = base.split()
    rgb = Image.merge("RGB", (r, g, b))
    rgb = ImageEnhance.Brightness(rgb).enhance(1.16)
    rgb = ImageEnhance.Color(rgb).enhance(1.18)
    rgb = ImageEnhance.Contrast(rgb).enhance(1.06)
    bright = Image.merge("RGBA", (*rgb.split(), a))

    glow_alpha = a.filter(ImageFilter.GaussianBlur(radius=6))
    glow = Image.new("RGBA", base.size, (255, 244, 170, 0))
    glow.putalpha(glow_alpha.point(lambda p: int(p * 0.55)))

    comp = Image.alpha_composite(glow, bright)
    return comp


def install_organs() -> None:
    organs = ["heart", "brain", "lungs", "kidneys", "stomach", "liver", "muscle"]
    out_dir = REPO / "assets/sprites/tiles"
    out_dir.mkdir(parents=True, exist_ok=True)
    for org in organs:
        prefix = "organ_heart_anat_raw_" if org == "heart" else f"organ_{org}_nat_raw_"
        src = find_latest(prefix)
        base = cutout_organ(src, size=256, fill_ratio=0.94)
        happy = make_happy_variant(base)
        dst_base = out_dir / f"organ_{org}.png"
        dst_happy = out_dir / f"organ_{org}_happy.png"
        base.save(dst_base, "PNG", optimize=True)
        happy.save(dst_happy, "PNG", optimize=True)
        print(f"[OK] Organ {org} -> {dst_base.name} & {dst_happy.name}")


if __name__ == "__main__":
    install_hero_poster()
    install_event_banners()
    install_organs()
    print("All v2.8.0 assets installed successfully!")
