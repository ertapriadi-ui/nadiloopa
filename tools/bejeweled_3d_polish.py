#!/usr/bin/env python3
"""
NADILOOPA v2.7.0 — 3D Bejeweled-Style Glossy Crystal Gem Tile Renderer.
1. Converts the generated 3D Angry Cigarette & Toxic Smoke gem into 256x256 RGBA transparent PNG.
2. Enhances all organ_* and special_* 256x256 tile sprites with 3D Bejeweled faceted bevel lighting,
   curved glass dome specular highlight, Fresnel rim shine, and jewel sparkle glints while preserving
   the crisp smiling 3D mascot faces.
"""

import glob
import os
from collections import deque
import numpy as np
from PIL import Image, ImageFilter, ImageEnhance


REPO_TILES_DIR = "/home/antigravity/ertapriadi-ui/nadiloopa/assets/sprites/tiles"
SMOKE_RAW_GLOB = "/home/antigravity/.gemini/jetski/brain/v1/default/jetski_remote_agents_3p/83c26a44-ed48-4bc2-bb6d-7b42c7dadd75/special_overload_smoke_raw_*.jpg"


def convert_smoke_icon() -> None:
    matches = sorted(glob.glob(SMOKE_RAW_GLOB))
    if not matches:
        print("WARN: No generated smoke icon found, skipping.")
        return
    src = matches[-1]
    img = Image.open(src).convert("RGBA")
    arr = np.array(img)
    h, w, _ = arr.shape

    # Flood-fill from corners to remove pure black outer background cleanly
    rgb_max = arr[:, :, :3].max(axis=2)
    visited = np.zeros((h, w), dtype=bool)
    bg_mask = np.zeros((h, w), dtype=bool)
    q = deque()
    for sx, sy in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
        if rgb_max[sy, sx] < 24:
            visited[sy, sx] = True
            q.append((sx, sy))

    while q:
        x, y = q.popleft()
        bg_mask[y, x] = True
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and not visited[ny, nx]:
                if rgb_max[ny, nx] < 26:
                    visited[ny, nx] = True
                    q.append((nx, ny))

    alpha = np.where(bg_mask, 0, 255).astype(np.uint8)
    # Soft feather 1px around cutout edge
    alpha_img = Image.fromarray(alpha, mode="L").filter(ImageFilter.GaussianBlur(radius=1.2))
    alpha_np = np.array(alpha_img)
    alpha_np = np.where(bg_mask, np.minimum(alpha_np, 20), alpha_np)
    arr[:, :, 3] = alpha_np

    cut = Image.fromarray(arr, mode="RGBA")
    bbox = cut.getbbox()
    if bbox:
        cut = cut.crop(bbox)
    # Fit into 256x256 with 8px margin so it matches special_overload.png scale
    canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    cut.thumbnail((240, 240), Image.Resampling.LANCZOS)
    ox = (256 - cut.width) // 2
    oy = (256 - cut.height) // 2
    canvas.paste(cut, (ox, oy), cut)

    out_path = os.path.join(REPO_TILES_DIR, "special_overload_smoke.png")
    canvas.save(out_path, "PNG")
    print(f"Saved 3D smoke gem icon: {out_path}")


def apply_bejeweled_3d_gloss(path: str) -> None:
    img = Image.open(path).convert("RGBA")
    if img.size != (256, 256):
        img = img.resize((256, 256), Image.Resampling.LANCZOS)

    # Slight vibrancy boost so jewel colors pop like Bejeweled
    rgb = img.convert("RGB")
    rgb = ImageEnhance.Color(rgb).enhance(1.16)
    rgb = ImageEnhance.Contrast(rgb).enhance(1.08)
    arr = np.array(rgb, dtype=np.float32) / 255.0
    alpha = np.array(img.split()[3], dtype=np.float32) / 255.0
    mask = alpha > 0.15

    # Compute signed distance / inner bevel using blurred alpha gradient
    a_img = Image.fromarray((alpha * 255).astype(np.uint8), mode="L")
    a_blur = np.array(a_img.filter(ImageFilter.GaussianBlur(radius=9.0)), dtype=np.float32) / 255.0
    a_sharp = np.array(a_img.filter(ImageFilter.GaussianBlur(radius=3.0)), dtype=np.float32) / 255.0

    # Normal estimation from blurred alpha (creates 3D pillow/bevel surface normal!)
    gy, gx = np.gradient(a_blur)
    # Light from top-left (-0.7, -0.7)
    bevel_dot = (-gx * 0.72 - gy * 0.72) * 14.0
    bevel_hi = np.clip(bevel_dot, 0.0, 1.0)
    bevel_lo = np.clip(-bevel_dot, 0.0, 1.0)

    # Edge band mask (stronger near the outer crystal rim, gentle over center face)
    edge_band = np.clip((1.0 - a_blur) * 2.8, 0.0, 1.0) * np.clip(a_sharp * 1.4, 0.0, 1.0)

    # 3D faceted crystal rim highlight (top-left bright, bottom-right deep jewel shadow)
    arr += (bevel_hi[:, :, None] * edge_band[:, :, None]) * np.array([0.42, 0.44, 0.48], dtype=np.float32)
    arr -= (bevel_lo[:, :, None] * edge_band[:, :, None]) * np.array([0.24, 0.22, 0.26], dtype=np.float32)

    # Curved glossy glass dome specular crescent on upper-left quadrant
    yy, xx = np.mgrid[0:256, 0:256].astype(np.float32)
    nx = (xx - 128.0) / 112.0
    ny = (yy - 128.0) / 112.0

    # Soft crescent sheen at top (y around -0.78 to -0.30)
    dome = np.exp(-((nx + 0.12) ** 2 / 0.58 + (ny + 0.68) ** 2 / 0.065)) * 0.42
    # Crisp secondary crystal sparkle glint on upper-left bevel corner
    glint1 = np.exp(-((nx + 0.58) ** 2 / 0.018 + (ny + 0.62) ** 2 / 0.018)) * 0.65
    # Subtle lower-right bounced rim light (classic Bejeweled internal refraction!)
    bounce = np.exp(-((nx - 0.35) ** 2 / 0.38 + (ny - 0.72) ** 2 / 0.055)) * 0.24

    # Keep central face area clean while rim/top dome gleams
    center_r2 = nx * nx + ny * ny
    dome_mask = np.clip((center_r2 - 0.18) * 1.8, 0.22, 1.0) * mask

    spec = (dome + glint1) * dome_mask
    arr += spec[:, :, None] * np.array([0.96, 0.98, 1.0], dtype=np.float32)
    arr += (bounce * mask)[:, :, None] * np.array([0.55, 0.88, 1.0], dtype=np.float32)

    # 4-point diamond star glint at upper-left crystal facet
    sx, sy = 64.0, 56.0
    dx = np.abs(xx - sx)
    dy = np.abs(yy - sy)
    star = (np.exp(-(dx * dx / 2.2 + dy * dy / 55.0)) + np.exp(-(dy * dy / 2.2 + dx * dx / 55.0))) * 0.72
    star *= mask
    arr += star[:, :, None] * np.array([1.0, 1.0, 0.96], dtype=np.float32)

    arr = np.clip(arr * 255.0, 0, 255).astype(np.uint8)
    out = np.dstack([arr, (alpha * 255.0).astype(np.uint8)])
    Image.fromarray(out, mode="RGBA").save(path, "PNG")


def main() -> None:
    convert_smoke_icon()
    targets = sorted(glob.glob(os.path.join(REPO_TILES_DIR, "organ_*.png")))
    targets += sorted(glob.glob(os.path.join(REPO_TILES_DIR, "special_*.png")))
    for p in targets:
        base = os.path.basename(p)
        if base == "special_overload_smoke.png":
            continue  # Already rendered with full 3D Bejeweled crystal facets
        apply_bejeweled_3d_gloss(p)
        print(f"Polished 3D Bejeweled tile: {base}")


if __name__ == "__main__":
    main()
