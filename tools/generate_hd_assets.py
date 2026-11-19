"""
NADILOOPA 9/10 Glossy 2.5D Cartoon Asset Generator (Zero External Dependencies)
Generates supersampled 512x512 master RGBA PNGs in assets/master_sources/
and crisp 2x2-downsampled 256x256 runtime RGBA PNGs in assets/sprites/tiles/
with glossy 3D highlights, big joyful open smiling faces, 6 organ families,
happy selection variants, 4 Overload variants, Vitality Bloom, and 3 ability icons.
"""
import math
import os
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MASTER_DIR = os.path.join(ROOT, "assets", "master_sources")
TILE_DIR = os.path.join(ROOT, "assets", "sprites", "tiles")
ICON_DIR = os.path.join(ROOT, "assets", "icons")

for d in (MASTER_DIR, TILE_DIR, ICON_DIR):
    os.makedirs(d, exist_ok=True)


def clamp(v, lo=0.0, hi=1.0):
    return lo if v < lo else (hi if v > hi else v)


def smoothstep(edge0, edge1, x):
    t = clamp((x - edge0) / (edge1 - edge0))
    return t * t * (3.0 - 2.0 * t)


def mix(a, b, t):
    return a + (b - a) * t


def mix_rgb(c1, c2, t):
    return (
        mix(c1[0], c2[0], t),
        mix(c1[1], c2[1], t),
        mix(c1[2], c2[2], t),
    )


def over(dst_r, dst_g, dst_b, dst_a, src_r, src_g, src_b, src_a):
    if src_a <= 0.0001:
        return dst_r, dst_g, dst_b, dst_a
    if src_a >= 0.9999 and dst_a <= 0.0001:
        return src_r, src_g, src_b, src_a
    out_a = src_a + dst_a * (1.0 - src_a)
    if out_a <= 1e-6:
        return 0.0, 0.0, 0.0, 0.0
    inv = 1.0 / out_a
    return (
        (src_r * src_a + dst_r * dst_a * (1.0 - src_a)) * inv,
        (src_g * src_a + dst_g * dst_a * (1.0 - src_a)) * inv,
        (src_b * src_a + dst_b * dst_a * (1.0 - src_a)) * inv,
        out_a,
    )


def hex_rgb(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16) / 255.0, int(h[2:4], 16) / 255.0, int(h[4:6], 16) / 255.0)


def sd_circle(x, y, cx, cy, r):
    return math.hypot(x - cx, y - cy) - r


def sd_ellipse(x, y, cx, cy, rx, ry):
    dx = (x - cx) / rx
    dy = (y - cy) / ry
    k0 = math.hypot(dx, dy)
    if k0 < 1e-6:
        return -min(rx, ry)
    k1 = math.hypot(dx / rx, dy / ry)
    return k0 * (k0 - 1.0) / k1


def sd_round_box(x, y, cx, cy, hx, hy, r):
    dx = abs(x - cx) - (hx - r)
    dy = abs(y - cy) - (hy - r)
    return math.hypot(max(dx, 0.0), max(dy, 0.0)) + min(max(dx, dy), 0.0) - r


def sd_capsule(x, y, ax, ay, bx, by, r):
    pax, pay = x - ax, y - ay
    bax, bay = bx - ax, by - ay
    denom = bax * bax + bay * bay
    h = clamp((pax * bax + pay * bay) / denom) if denom > 1e-8 else 0.0
    return math.hypot(pax - bax * h, pay - bay * h) - r


def sd_octagon(x, y, r):
    ax, ay = abs(x), abs(y)
    kx, ky, kz = -0.9238795325, 0.3826834323, 0.4142135623
    px, py = ax, ay
    dot1 = min(px * kx + py * ky, 0.0)
    px -= 2.0 * dot1 * kx
    py -= 2.0 * dot1 * ky
    dot2 = min(px * (-kx) + py * ky, 0.0)
    px -= 2.0 * dot2 * (-kx)
    py -= 2.0 * dot2 * ky
    px -= clamp(px, -kz * r, kz * r)
    py -= r
    return math.copysign(math.hypot(px, py), py)


def sd_triangle_up(x, y, cx, cy, r):
    px = abs(x - cx)
    py = -(y - cy)
    k = math.sqrt(3.0)
    px -= r
    py += r / k
    if px + k * py > 0.0:
        px, py = (px - k * py) * 0.5, (-k * px - py) * 0.5
    px -= clamp(px, -2.0 * r, 0.0)
    return -math.hypot(px, py) * (1.0 if py >= 0.0 else -1.0)


def smin(a, b, k=0.08):
    h = max(k - abs(a - b), 0.0) / k
    return min(a, b) - h * h * k * 0.25


def rot(x, y, ang):
    c, s = math.cos(ang), math.sin(ang)
    return x * c - y * s, x * s + y * c


def sd_heart(x, y):
    px = abs(x) * 1.18
    py = -(y - 0.38) * 1.24
    if py + px > 1.0:
        return (math.hypot(px - 0.25, py - 0.75) - math.sqrt(2.0) / 4.0) / 1.22
    d1 = math.hypot(px, py - 1.0) ** 2
    t = max(px + py, 0.0) * 0.5
    d2 = math.hypot(px - t, py - t) ** 2
    sgn = 1.0 if (px - py) >= 0.0 else -1.0
    return (math.sqrt(min(d1, d2)) * sgn) / 1.22


def sd_star(x, y, cx, cy, r):
    px, py = x - cx, y - cy
    an = math.pi / 5.0
    en = math.pi / 3.0
    acs = (math.cos(an), math.sin(an))
    ecs = (math.cos(en), math.sin(en))
    bn = (math.atan2(px, py) % (2.0 * an)) - an
    ln = math.hypot(px, py)
    qx = ln * math.cos(bn)
    qy = abs(ln * math.sin(bn))
    qx -= r * acs[0]
    qy -= r * acs[1]
    t = clamp(-qx * ecs[0] - qy * ecs[1], 0.0, r * acs[1] / ecs[1])
    qx += ecs[0] * t
    qy += ecs[1] * t
    return math.hypot(qx, qy) * (1.0 if qx > 0.0 else -1.0)


class Canvas:
    def __init__(self, size):
        self.size = size
        self.buf = bytearray(size * size * 4)

    def render(self, pixel_fn):
        n = self.size
        inv_n = 2.0 / n
        buf = self.buf
        aa = 2.6 / n
        idx = 0
        for py in range(n):
            y = (py + 0.5) * inv_n - 1.0
            for px in range(n):
                x = (px + 0.5) * inv_n - 1.0
                r, g, b, a = pixel_fn(x, y, aa)
                buf[idx] = int(clamp(r) * 255.0 + 0.5)
                buf[idx + 1] = int(clamp(g) * 255.0 + 0.5)
                buf[idx + 2] = int(clamp(b) * 255.0 + 0.5)
                buf[idx + 3] = int(clamp(a) * 255.0 + 0.5)
                idx += 4

    def downsample_half(self):
        ns = self.size // 2
        out = Canvas(ns)
        src, dst = self.buf, out.buf
        s_stride = self.size * 4
        for y in range(ns):
            sy = y * 2
            row0, row1 = sy * s_stride, (sy + 1) * s_stride
            for x in range(ns):
                sx = x * 8
                i00, i10, i01, i11 = row0 + sx, row0 + sx + 4, row1 + sx, row1 + sx + 4
                a00, a10, a01, a11 = src[i00 + 3], src[i10 + 3], src[i01 + 3], src[i11 + 3]
                asum = a00 + a10 + a01 + a11
                di = (y * ns + x) * 4
                if asum == 0:
                    dst[di] = dst[di + 1] = dst[di + 2] = dst[di + 3] = 0
                else:
                    dst[di] = (src[i00] * a00 + src[i10] * a10 + src[i01] * a01 + src[i11] * a11) // asum
                    dst[di + 1] = (src[i00 + 1] * a00 + src[i10 + 1] * a10 + src[i01 + 1] * a01 + src[i11 + 1] * a11) // asum
                    dst[di + 2] = (src[i00 + 2] * a00 + src[i10 + 2] * a10 + src[i01 + 2] * a01 + src[i11 + 2] * a11) // asum
                    dst[di + 3] = (asum + 2) // 4
        return out

    def save_png(self, path):
        w = h = self.size
        raw = bytearray()
        stride = w * 4
        for y in range(h):
            raw.append(0)
            s = y * stride
            raw.extend(self.buf[s : s + stride])
        comp = zlib.compress(bytes(raw), 9)

        def chunk(tag, data):
            return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

        ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
        png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", comp) + chunk(b"IEND", b"")
        with open(path, "wb") as f:
            f.write(png)


def shade_glossy_3d(x, y, d, aa, top_col, bot_col, outline_col, rim_col, outline_w=0.045, glow_col=None, extra_gloss=True):
    r, g, b, a = 0.0, 0.0, 0.0, 0.0
    if glow_col is not None:
        ga = (1.0 - smoothstep(0.0, 0.16, d)) * 0.34
        r, g, b, a = over(r, g, b, a, glow_col[0], glow_col[1], glow_col[2], ga)

    oa = 1.0 - smoothstep(-aa, aa, d - outline_w)
    r, g, b, a = over(r, g, b, a, outline_col[0], outline_col[1], outline_col[2], oa)

    fa = 1.0 - smoothstep(-aa, aa, d)
    if fa > 0.001:
        grad_t = clamp((y + 0.68) / 1.36)
        br, bg, bb = mix_rgb(top_col, bot_col, grad_t)
        # 3D pillow core brightness + edge depth darkening
        core = smoothstep(-0.26, -0.02, d)
        br, bg, bb = mix_rgb((br, bg, bb), (bot_col[0] * 0.78, bot_col[1] * 0.74, bot_col[2] * 0.84), core * 0.48)
        # Soft glossy top dome illumination
        hl = math.exp(-(((x + 0.22) * 1.9) ** 2 + ((y + 0.36) * 2.2) ** 2))
        br, bg, bb = mix_rgb((br, bg, bb), rim_col, hl * (0.78 if extra_gloss else 0.55))
        # Subtle lower rim bounce light
        bounce = math.exp(-(((x - 0.15) * 1.6) ** 2 + ((y - 0.44) * 3.8) ** 2)) * (1.0 - smoothstep(-0.14, 0.0, d))
        br, bg, bb = mix_rgb((br, bg, bb), rim_col, bounce * 0.28)
        r, g, b, a = over(r, g, b, a, br, bg, bb, fa)
    return r, g, b, a


def draw_smiling_face(x, y, aa, r, g, b, a, cx=0.0, eye_dx=0.17, eye_y=-0.03, eye_r=0.072, cheek_dx=0.29, cheek_y=0.09, smile_y=0.06, smile_w=0.13, scale=1.0, happy=False):
    lx = x - cx
    ex = abs(lx)

    # Warm rosy cheeks
    dc = sd_ellipse(ex, y, cheek_dx * scale, cheek_y * scale, 0.092 * scale, 0.056 * scale)
    r, g, b, a = over(r, g, b, a, 1.0, 0.45, 0.58, (1.0 - smoothstep(-aa, aa, dc)) * 0.78)

    # Eyes
    if happy:
        # Joyful curved ^ ^ happy squint eyes!
        for sign in (-1.0, 1.0):
            ex_c = sign * eye_dx * scale
            sx = clamp(lx - ex_c, -0.072 * scale, 0.072 * scale)
            sy = (eye_y + 0.015) * scale - 0.048 * scale * (1.0 - (sx / (0.075 * scale)) ** 2)
            de = math.hypot((lx - ex_c) - sx, y - sy) - 0.019 * scale
            r, g, b, a = over(r, g, b, a, 0.15, 0.08, 0.16, 1.0 - smoothstep(-aa, aa, de))
    else:
        # Glossy sparkling anime/cartoon eyes
        de = sd_circle(ex, y, eye_dx * scale, eye_y * scale, eye_r * scale)
        r, g, b, a = over(r, g, b, a, 0.12, 0.08, 0.16, 1.0 - smoothstep(-aa, aa, de))
        # Large specular catchlights
        for sgn in (-1.0, 1.0):
            c_x = sgn * eye_dx * scale
            dl1 = sd_circle(lx, y, c_x - 0.022 * scale, (eye_y - 0.024) * scale, 0.027 * scale)
            dl2 = sd_circle(lx, y, c_x + 0.024 * scale, (eye_y + 0.022) * scale, 0.013 * scale)
            r, g, b, a = over(r, g, b, a, 1.0, 1.0, 1.0, 1.0 - smoothstep(-aa, aa, min(dl1, dl2)))

    # Big joyful open D-shaped smile with cute coral-pink tongue!
    my = smile_y * scale
    mw = smile_w * scale
    mh = (0.115 if happy else 0.095) * scale
    # Semi-ellipse mouth interior (clipped to y >= my)
    d_mouth_fill = max(sd_ellipse(lx, y, 0.0, my, mw, mh), my - y)
    d_mouth_rim = abs(d_mouth_fill) - 0.015 * scale
    # Mouth dark plum interior
    r, g, b, a = over(r, g, b, a, 0.28, 0.07, 0.13, 1.0 - smoothstep(-aa, aa, d_mouth_fill))
    # Cute pink tongue peeking inside bottom of smile
    d_tongue = max(sd_ellipse(lx, y, 0.0, my + mh * 0.65, mw * 0.58, mh * 0.45), d_mouth_fill + 0.008 * scale)
    r, g, b, a = over(r, g, b, a, 1.0, 0.52, 0.64, 1.0 - smoothstep(-aa, aa, d_tongue))
    # Upper crisp white smile highlight teeth strip
    d_teeth = max(sd_round_box(lx, y, 0.0, my + 0.012 * scale, mw * 0.72, 0.018 * scale, 0.008 * scale), d_mouth_fill + 0.005 * scale)
    r, g, b, a = over(r, g, b, a, 1.0, 0.99, 0.98, 1.0 - smoothstep(-aa, aa, d_teeth))
    # Crisp mouth outline
    r, g, b, a = over(r, g, b, a, 0.18, 0.06, 0.12, 1.0 - smoothstep(-aa, aa, d_mouth_rim))
    return r, g, b, a


def add_gloss_pill(x, y, aa, r, g, b, a, cx, cy, ang, rx, ry, alpha=0.82):
    hx, hy = rot(x - cx, y - cy, ang)
    dh = sd_ellipse(hx, hy, 0.0, 0.0, rx, ry)
    r, g, b, a = over(r, g, b, a, 1.0, 0.98, 0.99, (1.0 - smoothstep(-aa, aa, dh)) * alpha)
    # Tiny companion glossy dot
    hx2, hy2 = rot(x - (cx + 0.15 * rx * 4.5), y - (cy - 0.04), ang)
    dh2 = sd_circle(hx2, hy2, 0.0, 0.0, ry * 0.68)
    r, g, b, a = over(r, g, b, a, 1.0, 0.99, 1.0, (1.0 - smoothstep(-aa, aa, dh2)) * alpha * 0.85)
    return r, g, b, a


# --- 6 Glossy Smiling Organ Characters ---
def make_organ_heart(happy=False):
    def px(x, y, aa):
        ds = sd_heart(x * 1.10, (y - 0.08) * 1.10)
        r, g, b, a = 0.0, 0.0, 0.0, 0.0
        r, g, b, a = over(r, g, b, a, 0.24, 0.04, 0.10, (1.0 - smoothstep(-0.04, 0.10, ds)) * 0.30)

        d = sd_heart(x * 1.10, (y + 0.01) * 1.10) / 1.10
        top_c = hex_rgb("#FF92A8") if happy else hex_rgb("#FF7A92")
        bot_c = hex_rgb("#E02850")
        br, bg, bb, ba = shade_glossy_3d(x, y, d, aa, top_c, bot_c, hex_rgb("#541128"), hex_rgb("#FFE5EC"), glow_col=hex_rgb("#FF8DA1"))
        r, g, b, a = over(r, g, b, a, br, bg, bb, ba)

        # Glossy candy highlights
        r, g, b, a = add_gloss_pill(x, y, aa, r, g, b, a, -0.28, -0.28, 0.55, 0.14, 0.055, 0.82)

        # Cute sprout leaf badge
        lx, ly = rot(x - 0.34, y + 0.48, -0.55)
        dl = sd_ellipse(lx, ly, 0.0, 0.0, 0.14, 0.075)
        r, g, b, a = over(r, g, b, a, 0.08, 0.33, 0.18, 1.0 - smoothstep(-aa, aa, dl - 0.025))
        lcol = mix_rgb(hex_rgb("#78F5A6"), hex_rgb("#22B261"), clamp((ly + 0.08) / 0.16))
        r, g, b, a = over(r, g, b, a, lcol[0], lcol[1], lcol[2], 1.0 - smoothstep(-aa, aa, dl))

        r, g, b, a = draw_smiling_face(x, y, aa, r, g, b, a, eye_dx=0.17, eye_y=-0.04, eye_r=0.070, cheek_dx=0.30, cheek_y=0.07, smile_y=0.05, smile_w=0.135, happy=happy)
        if happy:
            d_sp = sd_star(x, y, -0.48, -0.44, 0.11)
            r, g, b, a = over(r, g, b, a, 1.0, 0.94, 0.50, 1.0 - smoothstep(-aa, aa, d_sp))
        return r, g, b, a
    return px


def make_organ_brain(happy=False):
    def px(x, y, aa):
        sx, sy = x * 1.05, (y - 0.01) * 1.05
        d = sd_ellipse(sx, sy, 0.0, 0.03, 0.64, 0.52)
        for cx, cy, cr in ((-0.34, -0.22, 0.25), (0.0, -0.30, 0.26), (0.34, -0.22, 0.25), (-0.46, 0.04, 0.24), (0.46, 0.04, 0.24), (-0.28, 0.26, 0.24), (0.28, 0.26, 0.24), (0.0, 0.22, 0.23)):
            d = smin(d, sd_circle(sx, sy, cx, cy, cr), 0.11)
        d /= 1.05

        r, g, b, a = 0.0, 0.0, 0.0, 0.0
        ds = sd_ellipse(x, y - 0.08, 0.0, 0.03, 0.68, 0.54)
        r, g, b, a = over(r, g, b, a, 0.14, 0.06, 0.28, (1.0 - smoothstep(-0.04, 0.11, ds)) * 0.28)

        top_c = hex_rgb("#DFB8FF") if happy else hex_rgb("#D2A4FF")
        br, bg, bb, ba = shade_glossy_3d(x, y, d, aa, top_c, hex_rgb("#7C44DF"), hex_rgb("#311761"), hex_rgb("#F7ECFF"), glow_col=hex_rgb("#BE8EFF"))
        r, g, b, a = over(r, g, b, a, br, bg, bb, ba)

        # Curved cerebral gyri fold marks
        for ax, ay, bx, by in ((0.0, -0.44, 0.0, -0.20), (-0.30, -0.28, -0.14, -0.18), (0.30, -0.28, 0.14, -0.18), (-0.40, -0.02, -0.28, -0.10), (0.40, -0.02, 0.28, -0.10)):
            fd = sd_capsule(x, y, ax, ay, bx, by, 0.015)
            r, g, b, a = over(r, g, b, a, 0.36, 0.16, 0.64, (1.0 - smoothstep(-aa, aa, fd)) * 0.45)

        r, g, b, a = add_gloss_pill(x, y, aa, r, g, b, a, -0.26, -0.32, 0.38, 0.14, 0.052, 0.78)

        # Gold star clip
        d_star = sd_star(x, y, 0.40, -0.40, 0.14)
        r, g, b, a = over(r, g, b, a, 0.38, 0.22, 0.04, 1.0 - smoothstep(-aa, aa, d_star - 0.022))
        r, g, b, a = over(r, g, b, a, 1.0, 0.88, 0.28, 1.0 - smoothstep(-aa, aa, d_star))

        r, g, b, a = draw_smiling_face(x, y, aa, r, g, b, a, eye_dx=0.17, eye_y=0.01, eye_r=0.068, cheek_dx=0.31, cheek_y=0.12, smile_y=0.10, smile_w=0.135, happy=happy)
        return r, g, b, a
    return px


def make_organ_lungs(happy=False):
    def px(x, y, aa):
        ax = abs(x)
        lx, ly = rot(ax - 0.31, y - 0.06, -0.20)
        d_lobe = sd_ellipse(lx, ly, 0.0, 0.0, 0.27, 0.46)
        d_lung = smin(d_lobe, sd_circle(ax, y, 0.36, 0.26, 0.24), 0.14)
        d_trachea = sd_capsule(x, y, 0.0, -0.58, 0.0, -0.20, 0.085)
        d_branch = sd_capsule(ax, y, 0.0, -0.24, 0.24, -0.08, 0.075)
        d_tr_all = min(d_trachea, d_branch)

        r, g, b, a = 0.0, 0.0, 0.0, 0.0
        ds = sd_ellipse(ax, y - 0.08, 0.32, 0.08, 0.29, 0.48)
        r, g, b, a = over(r, g, b, a, 0.04, 0.18, 0.26, (1.0 - smoothstep(-0.04, 0.11, ds)) * 0.26)

        r, g, b, a = over(r, g, b, a, 0.07, 0.28, 0.36, 1.0 - smoothstep(-aa, aa, d_tr_all - 0.04))
        r, g, b, a = over(r, g, b, a, 0.78, 0.98, 0.97, 1.0 - smoothstep(-aa, aa, d_tr_all))

        top_c = hex_rgb("#8BF7F2") if happy else hex_rgb("#73F0EA")
        br, bg, bb, ba = shade_glossy_3d(x, y, d_lung, aa, top_c, hex_rgb("#169BC2"), hex_rgb("#0D4257"), hex_rgb("#E2FFFE"), glow_col=hex_rgb("#5CE6E0"))
        r, g, b, a = over(r, g, b, a, br, bg, bb, ba)

        # Glossy candy pills on both lobes
        r, g, b, a = add_gloss_pill(x, y, aa, r, g, b, a, -0.35, -0.22, 0.35, 0.095, 0.042, 0.76)
        r, g, b, a = add_gloss_pill(x, y, aa, r, g, b, a, 0.27, -0.22, 0.35, 0.095, 0.042, 0.65)

        # Twin cute smiling faces (1 per lung lobe)
        for sign in (-1.0, 1.0):
            r, g, b, a = draw_smiling_face(x, y, aa, r, g, b, a, cx=sign * 0.31, eye_dx=0.072, eye_y=0.00, eye_r=0.042, cheek_dx=0.115, cheek_y=0.085, smile_y=0.075, smile_w=0.078, scale=1.0, happy=happy)
        return r, g, b, a
    return px


def make_organ_kidneys(happy=False):
    def px(x, y, aa):
        ax = abs(x)
        kx, ky = rot(ax - 0.36, y - 0.02, 0.26)
        d_lobe = smin(smin(sd_circle(kx, ky, 0.04, -0.20, 0.24), sd_circle(kx, ky, 0.04, 0.20, 0.24), 0.08), sd_ellipse(kx, ky, 0.09, 0.0, 0.23, 0.40), 0.06)
        d_kidney = max(d_lobe, -sd_circle(kx, ky, -0.22, 0.0, 0.14))
        d_vascular = smin(sd_capsule(x, y, -0.26, 0.06, 0.26, 0.06, 0.075), sd_capsule(x, y, 0.0, 0.06, 0.0, 0.44, 0.065), 0.06)

        r, g, b, a = 0.0, 0.0, 0.0, 0.0
        ds = sd_ellipse(ax, y - 0.08, 0.36, 0.03, 0.27, 0.44)
        r, g, b, a = over(r, g, b, a, 0.26, 0.10, 0.02, (1.0 - smoothstep(-0.04, 0.10, ds)) * 0.28)

        r, g, b, a = over(r, g, b, a, 0.40, 0.18, 0.04, 1.0 - smoothstep(-aa, aa, d_vascular - 0.035))
        r, g, b, a = over(r, g, b, a, 1.0, 0.89, 0.58, 1.0 - smoothstep(-aa, aa, d_vascular))

        top_c = hex_rgb("#FFD36E") if happy else hex_rgb("#FFC452")
        br, bg, bb, ba = shade_glossy_3d(x, y, d_kidney, aa, top_c, hex_rgb("#DC6612"), hex_rgb("#5C2505"), hex_rgb("#FFF5CE"), glow_col=hex_rgb("#FFB347"))
        r, g, b, a = over(r, g, b, a, br, bg, bb, ba)

        r, g, b, a = add_gloss_pill(x, y, aa, r, g, b, a, -0.44, -0.24, -0.25, 0.085, 0.038, 0.78)
        r, g, b, a = add_gloss_pill(x, y, aa, r, g, b, a, 0.34, -0.24, 0.25, 0.085, 0.038, 0.70)

        for sign in (-1.0, 1.0):
            r, g, b, a = draw_smiling_face(x, y, aa, r, g, b, a, cx=sign * 0.40, eye_dx=0.068, eye_y=-0.04, eye_r=0.040, cheek_dx=0.11, cheek_y=0.05, smile_y=0.04, smile_w=0.075, scale=1.0, happy=happy)
        return r, g, b, a
    return px


def make_organ_stomach(happy=False):
    """Cute glossy peach-tangerine J-shaped Stomach (Lambung) mascot."""
    def px(x, y, aa):
        # J-curved plump stomach shape
        d1 = sd_ellipse(x, y, -0.10, -0.02, 0.36, 0.44)
        d2 = sd_ellipse(x, y, 0.18, 0.22, 0.34, 0.26)
        d_top_neck = sd_capsule(x, y, -0.16, -0.58, -0.12, -0.22, 0.13)
        d_outlet = sd_capsule(x, y, 0.28, 0.14, 0.56, 0.02, 0.11)
        d = smin(smin(d1, d2, 0.16), smin(d_top_neck, d_outlet, 0.08), 0.08)

        r, g, b, a = 0.0, 0.0, 0.0, 0.0
        ds = sd_ellipse(x, y - 0.08, 0.02, 0.08, 0.52, 0.46)
        r, g, b, a = over(r, g, b, a, 0.25, 0.10, 0.04, (1.0 - smoothstep(-0.04, 0.10, ds)) * 0.26)

        top_c = hex_rgb("#FFB678") if happy else hex_rgb("#FFA25B")
        br, bg, bb, ba = shade_glossy_3d(x, y, d, aa, top_c, hex_rgb("#E85D2A"), hex_rgb("#63200B"), hex_rgb("#FFE8D4"), glow_col=hex_rgb("#FF9E66"))
        r, g, b, a = over(r, g, b, a, br, bg, bb, ba)

        r, g, b, a = add_gloss_pill(x, y, aa, r, g, b, a, -0.25, -0.26, 0.50, 0.12, 0.048, 0.80)
        r, g, b, a = draw_smiling_face(x, y, aa, r, g, b, a, cx=-0.02, eye_dx=0.14, eye_y=-0.02, eye_r=0.062, cheek_dx=0.25, cheek_y=0.08, smile_y=0.07, smile_w=0.12, happy=happy)
        return r, g, b, a
    return px


def make_organ_liver(happy=False):
    """Cute glossy warm-berry dual-lobe wedge Liver (Hati) mascot with leaf crest."""
    def px(x, y, aa):
        # Asymmetric friendly rounded triangular liver silhouette (larger left lobe, cute tapered right lobe)
        lx, ly = rot(x + 0.16, y - 0.02, -0.22)
        d_main = sd_ellipse(lx, ly, 0.0, 0.0, 0.42, 0.38)
        rx, ry = rot(x - 0.24, y + 0.10, 0.25)
        d_right = sd_ellipse(rx, ry, 0.0, 0.0, 0.34, 0.25)
        d = smin(d_main, d_right, 0.18)

        r, g, b, a = 0.0, 0.0, 0.0, 0.0
        ds = sd_ellipse(x, y - 0.08, 0.0, 0.05, 0.56, 0.42)
        r, g, b, a = over(r, g, b, a, 0.22, 0.04, 0.12, (1.0 - smoothstep(-0.04, 0.10, ds)) * 0.26)

        top_c = hex_rgb("#F7749C") if happy else hex_rgb("#E85884")
        br, bg, bb, ba = shade_glossy_3d(x, y, d, aa, top_c, hex_rgb("#9E2153"), hex_rgb("#4A0B24"), hex_rgb("#FFD6E6"), glow_col=hex_rgb("#F279A1"))
        r, g, b, a = over(r, g, b, a, br, bg, bb, ba)

        # Tiny emerald leaf-crown accent
        lx2, ly2 = rot(x + 0.26, y + 0.42, 0.45)
        dl = sd_ellipse(lx2, ly2, 0.0, 0.0, 0.12, 0.065)
        r, g, b, a = over(r, g, b, a, 0.08, 0.34, 0.18, 1.0 - smoothstep(-aa, aa, dl - 0.022))
        r, g, b, a = over(r, g, b, a, 0.42, 0.92, 0.58, 1.0 - smoothstep(-aa, aa, dl))

        r, g, b, a = add_gloss_pill(x, y, aa, r, g, b, a, -0.28, -0.22, 0.42, 0.12, 0.045, 0.78)
        r, g, b, a = draw_smiling_face(x, y, aa, r, g, b, a, cx=-0.04, eye_dx=0.15, eye_y=-0.02, eye_r=0.062, cheek_dx=0.26, cheek_y=0.08, smile_y=0.07, smile_w=0.12, happy=happy)
        return r, g, b, a
    return px


# --- Special Tiles ---
def px_special_care(x, y, aa):
    d_oct = sd_octagon(x, y, 0.78)
    r, g, b, a = 0.0, 0.0, 0.0, 0.0
    ds = sd_octagon(x, y - 0.06, 0.78)
    r, g, b, a = over(r, g, b, a, 0.02, 0.18, 0.10, (1.0 - smoothstep(-0.04, 0.09, ds)) * 0.28)
    br, bg, bb, ba = shade_glossy_3d(x, y, d_oct, aa, hex_rgb("#4EF29E"), hex_rgb("#0A9C56"), hex_rgb("#064A29"), hex_rgb("#D6FFE9"), glow_col=hex_rgb("#42F59B"))
    r, g, b, a = over(r, g, b, a, br, bg, bb, ba)

    d_in = sd_circle(x, y, 0.0, 0.02, 0.54)
    r, g, b, a = over(r, g, b, a, 0.08, 0.48, 0.28, 1.0 - smoothstep(-aa, aa, d_in - 0.02))
    r, g, b, a = over(r, g, b, a, 0.92, 1.0, 0.95, 1.0 - smoothstep(-aa, aa, d_in))

    d_stem = sd_round_box(x, y, 0.0, 0.22, 0.13, 0.15, 0.06)
    r, g, b, a = over(r, g, b, a, 0.12, 0.42, 0.22, 1.0 - smoothstep(-aa, aa, d_stem - 0.025))
    r, g, b, a = over(r, g, b, a, 0.62, 0.92, 0.54, 1.0 - smoothstep(-aa, aa, d_stem))

    df = 1.0
    for fx, fy, fr in ((-0.18, -0.02, 0.17), (0.18, -0.02, 0.17), (0.0, -0.14, 0.21), (-0.11, -0.10, 0.15), (0.11, -0.10, 0.15)):
        df = min(df, sd_circle(x, y, fx, fy, fr))
    r, g, b, a = over(r, g, b, a, 0.06, 0.30, 0.15, 1.0 - smoothstep(-aa, aa, df - 0.026))
    fa = 1.0 - smoothstep(-aa, aa, df)
    if fa > 0.001:
        fcol = mix_rgb(hex_rgb("#64ED82"), hex_rgb("#18A34A"), clamp((y + 0.3) / 0.5))
        r, g, b, a = over(r, g, b, a, fcol[0], fcol[1], fcol[2], fa)

    r, g, b, a = draw_smiling_face(x, y, aa, r, g, b, a, eye_dx=0.105, eye_y=-0.02, eye_r=0.044, cheek_dx=0.18, cheek_y=0.06, smile_y=0.05, smile_w=0.08, happy=True)
    d_b = sd_star(x, y, 0.0, -0.60, 0.11)
    r, g, b, a = over(r, g, b, a, 0.06, 0.35, 0.20, 1.0 - smoothstep(-aa, aa, d_b - 0.02))
    r, g, b, a = over(r, g, b, a, 0.88, 1.0, 0.62, 1.0 - smoothstep(-aa, aa, d_b))
    return r, g, b, a


def _draw_overload_frame(x, y, aa, armored=False):
    d_oct = sd_octagon(x, y, 0.78)
    r, g, b, a = 0.0, 0.0, 0.0, 0.0
    ds = sd_octagon(x, y - 0.06, 0.78)
    r, g, b, a = over(r, g, b, a, 0.24, 0.03, 0.03, (1.0 - smoothstep(-0.04, 0.09, ds)) * 0.30)

    top_c = hex_rgb("#9EA8B8") if armored else hex_rgb("#FF843C")
    bot_c = hex_rgb("#5A1D28") if armored else hex_rgb("#D12136")
    out_c = hex_rgb("#2C1622") if armored else hex_rgb("#520B12")
    br, bg, bb, ba = shade_glossy_3d(x, y, d_oct, aa, top_c, bot_c, out_c, hex_rgb("#FFE0BF"), glow_col=hex_rgb("#FF5C33"))
    r, g, b, a = over(r, g, b, a, br, bg, bb, ba)

    d_in = sd_octagon(x, y, 0.60)
    if d_oct < 0.0 and d_in > -0.02:
        if math.sin((x + y) * 26.0) > 0.0:
            bezel_mask = (1.0 - smoothstep(-aa, aa, d_oct)) * smoothstep(-aa, aa, d_in)
            r, g, b, a = over(r, g, b, a, 1.0, 0.82, 0.20, bezel_mask * 0.45)

    d_disk = sd_circle(x, y, 0.0, 0.04, 0.53)
    r, g, b, a = over(r, g, b, a, 0.42, 0.08, 0.10, 1.0 - smoothstep(-aa, aa, d_disk - 0.02))
    r, g, b, a = over(r, g, b, a, 1.0, 0.94, 0.88, 1.0 - smoothstep(-aa, aa, d_disk))
    return r, g, b, a


def _draw_warning_badge(x, y, aa, r, g, b, a, armored=False):
    tx, ty = 0.46, -0.44
    d_tri = sd_triangle_up(x, y, tx, ty, 0.22)
    r, g, b, a = over(r, g, b, a, 0.28, 0.04, 0.04, 1.0 - smoothstep(-aa, aa, d_tri - 0.028))
    r, g, b, a = over(r, g, b, a, 1.0, 0.86, 0.14, 1.0 - smoothstep(-aa, aa, d_tri))
    d_ex1 = sd_capsule(x, y, tx, ty - 0.11, tx, ty + 0.01, 0.024)
    d_ex2 = sd_circle(x, y, tx, ty + 0.08, 0.026)
    r, g, b, a = over(r, g, b, a, 0.28, 0.04, 0.04, 1.0 - smoothstep(-aa, aa, min(d_ex1, d_ex2)))

    if armored:
        # Metallic blue-steel shield crest embossed with "2" indicating 2-HP Armor
        ax, ay = -0.45, 0.42
        d_arm = sd_round_box(x, y, ax, ay - 0.01, 0.175, 0.165, 0.055)
        d_tip = sd_ellipse(x, y, ax, ay + 0.11, 0.155, 0.105)
        d_shield = min(d_arm, d_tip)
        r, g, b, a = over(r, g, b, a, 0.08, 0.14, 0.24, 1.0 - smoothstep(-aa, aa, d_shield - 0.032))
        r, g, b, a = over(r, g, b, a, 0.96, 0.84, 0.34, 1.0 - smoothstep(-aa, aa, d_shield - 0.014))
        r, g, b, a = over(r, g, b, a, 0.22, 0.46, 0.78, 1.0 - smoothstep(-aa, aa, d_shield))
        lx, ly = x - ax, y - ay
        d_two = min(
            sd_capsule(lx, ly, -0.055, -0.075, 0.055, -0.075, 0.024),
            sd_capsule(lx, ly, 0.055, -0.075, 0.055, -0.002, 0.024),
            sd_capsule(lx, ly, 0.055, -0.002, -0.055, 0.080, 0.024),
            sd_capsule(lx, ly, -0.055, 0.080, 0.062, 0.080, 0.024),
        )
        r, g, b, a = over(r, g, b, a, 0.06, 0.10, 0.20, 1.0 - smoothstep(-aa, aa, d_two - 0.016))
        r, g, b, a = over(r, g, b, a, 1.0, 0.98, 0.90, 1.0 - smoothstep(-aa, aa, d_two))
    return r, g, b, a


def px_special_overload(x, y, aa, armored=False):
    r, g, b, a = _draw_overload_frame(x, y, aa, armored)
    d_bbun = sd_round_box(x, y, -0.06, 0.25, 0.25, 0.065, 0.045)
    d_patty = sd_round_box(x, y, -0.06, 0.15, 0.28, 0.052, 0.032)
    d_cheese = sd_round_box(x, y, -0.06, 0.09, 0.26, 0.030, 0.018)
    d_lettuce = sd_round_box(x, y, -0.06, 0.05, 0.27, 0.028, 0.015)
    d_tbun = max(sd_ellipse(x, y, -0.06, 0.04, 0.26, 0.21), (y - 0.04))

    for df, col in (
        (sd_round_box(x, y, 0.20, -0.09, 0.032, 0.14, 0.015), "#FFD23F"),
        (sd_round_box(x, y, 0.28, -0.07, 0.032, 0.13, 0.015), "#FFB81C"),
        (sd_round_box(x, y, 0.35, -0.03, 0.028, 0.11, 0.014), "#FFD23F"),
        (sd_round_box(x, y, 0.27, 0.11, 0.12, 0.15, 0.028), "#E63946"),
    ):
        r, g, b, a = over(r, g, b, a, 0.35, 0.10, 0.05, 1.0 - smoothstep(-aa, aa, df - 0.018))
        c = hex_rgb(col)
        r, g, b, a = over(r, g, b, a, c[0], c[1], c[2], 1.0 - smoothstep(-aa, aa, df))

    for df, col in ((d_bbun, "#F2A84B"), (d_patty, "#6E331A"), (d_cheese, "#FFD23F"), (d_lettuce, "#47C968"), (d_tbun, "#F7B652")):
        r, g, b, a = over(r, g, b, a, 0.30, 0.09, 0.05, 1.0 - smoothstep(-aa, aa, df - 0.020))
        c = hex_rgb(col)
        r, g, b, a = over(r, g, b, a, c[0], c[1], c[2], 1.0 - smoothstep(-aa, aa, df))

    for sx, sy in ((-0.15, -0.08), (-0.06, -0.11), (0.04, -0.07)):
        r, g, b, a = over(r, g, b, a, 1.0, 0.96, 0.80, 1.0 - smoothstep(-aa, aa, sd_ellipse(x, y, sx, sy, 0.024, 0.014)))

    return _draw_warning_badge(x, y, aa, r, g, b, a, armored)


def px_special_overload_soda(x, y, aa):
    r, g, b, a = _draw_overload_frame(x, y, aa, False)
    # Fizzy sugary cup with red/white stripes & bent straw
    d_straw = min(sd_capsule(x, y, 0.02, -0.14, 0.04, -0.34, 0.024), sd_capsule(x, y, 0.04, -0.34, 0.18, -0.38, 0.024))
    r, g, b, a = over(r, g, b, a, 0.30, 0.08, 0.08, 1.0 - smoothstep(-aa, aa, d_straw - 0.018))
    r, g, b, a = over(r, g, b, a, 1.0, 0.32, 0.36, 1.0 - smoothstep(-aa, aa, d_straw))

    d_cup = sd_round_box(x, y, 0.0, 0.10, 0.21, 0.25, 0.05)
    r, g, b, a = over(r, g, b, a, 0.30, 0.06, 0.06, 1.0 - smoothstep(-aa, aa, d_cup - 0.022))
    ca = 1.0 - smoothstep(-aa, aa, d_cup)
    if ca > 0.001:
        stripe = 1.0 if int(floor_div_x(x)) % 2 == 0 else 0.0
        col = mix_rgb(hex_rgb("#F7FAFF"), hex_rgb("#E83B48"), 1.0 if abs(x) < 0.07 or abs(x) > 0.14 else 0.0)
        r, g, b, a = over(r, g, b, a, col[0], col[1], col[2], ca)

    d_lid = sd_round_box(x, y, 0.0, -0.14, 0.24, 0.045, 0.025)
    r, g, b, a = over(r, g, b, a, 0.25, 0.08, 0.08, 1.0 - smoothstep(-aa, aa, d_lid - 0.018))
    r, g, b, a = over(r, g, b, a, 0.98, 0.96, 0.94, 1.0 - smoothstep(-aa, aa, d_lid))
    return _draw_warning_badge(x, y, aa, r, g, b, a, False)


def floor_div_x(x):
    return int(math.floor((x + 0.3) * 12.0))


def px_special_overload_snack(x, y, aa):
    r, g, b, a = _draw_overload_frame(x, y, aa, False)
    # Glossy frosted donut with colorful sugar sprinkles
    d_ring = max(sd_circle(x, y, 0.0, 0.04, 0.30), -sd_circle(x, y, 0.0, 0.04, 0.095))
    r, g, b, a = over(r, g, b, a, 0.35, 0.14, 0.06, 1.0 - smoothstep(-aa, aa, d_ring - 0.024))
    r, g, b, a = over(r, g, b, a, 0.94, 0.72, 0.42, 1.0 - smoothstep(-aa, aa, d_ring))
    d_icing = max(sd_circle(x, y, 0.0, 0.02, 0.275), -sd_circle(x, y, 0.0, 0.04, 0.105))
    r, g, b, a = over(r, g, b, a, 1.0, 0.44, 0.68, 1.0 - smoothstep(-aa, aa, d_icing))
    for sx, sy, col in ((-0.16, -0.06, "#FFE047"), (0.14, -0.08, "#5CEBFF"), (0.18, 0.14, "#FFE047"), (-0.15, 0.16, "#78F59C"), (0.0, 0.22, "#FFFFFF")):
        c = hex_rgb(col)
        r, g, b, a = over(r, g, b, a, c[0], c[1], c[2], 1.0 - smoothstep(-aa, aa, sd_circle(x, y, sx, sy, 0.025)))
    return _draw_warning_badge(x, y, aa, r, g, b, a, False)


def px_special_bloom(x, y, aa):
    """Golden-Jade Vitality Bloom bonus tile: smiling lotus flower on sunlit medallion."""
    d_oct = sd_octagon(x, y, 0.78)
    r, g, b, a = 0.0, 0.0, 0.0, 0.0
    br, bg, bb, ba = shade_glossy_3d(x, y, d_oct, aa, hex_rgb("#FFE875"), hex_rgb("#E89B18"), hex_rgb("#663E04"), hex_rgb("#FFFAD6"), glow_col=hex_rgb("#FFDF6B"))
    r, g, b, a = over(r, g, b, a, br, bg, bb, ba)

    # 8 blooming petals around smiling center
    for i in range(8):
        ang = i * (math.pi / 4.0)
        px, py = rot(x, y, ang)
        dp = sd_ellipse(px, py, 0.0, -0.34, 0.13, 0.21)
        r, g, b, a = over(r, g, b, a, 0.28, 0.14, 0.04, 1.0 - smoothstep(-aa, aa, dp - 0.018))
        pcol = mix_rgb(hex_rgb("#FFF4AE"), hex_rgb("#FF9DC4"), 0.35 if i % 2 == 0 else 0.05)
        r, g, b, a = over(r, g, b, a, pcol[0], pcol[1], pcol[2], 1.0 - smoothstep(-aa, aa, dp))

    dc = sd_circle(x, y, 0.0, 0.0, 0.27)
    r, g, b, a = over(r, g, b, a, 0.45, 0.24, 0.02, 1.0 - smoothstep(-aa, aa, dc - 0.02))
    r, g, b, a = over(r, g, b, a, 1.0, 0.84, 0.30, 1.0 - smoothstep(-aa, aa, dc))
    r, g, b, a = draw_smiling_face(x, y, aa, r, g, b, a, eye_dx=0.095, eye_y=-0.03, eye_r=0.038, cheek_dx=0.16, cheek_y=0.04, smile_y=0.03, smile_w=0.075, happy=True)
    return r, g, b, a


# --- Tactical Care Ability Icons ---
def make_ability_icon(col_top, col_bot, symbol_kind):
    def px(x, y, aa):
        d = sd_circle(x, y, 0.0, 0.0, 0.84)
        r, g, b, a = shade_glossy_3d(x, y, d, aa, hex_rgb(col_top), hex_rgb(col_bot), hex_rgb("#0A2C2A"), hex_rgb("#FFFFFF"))
        r, g, b, a = add_gloss_pill(x, y, aa, r, g, b, a, -0.25, -0.38, 0.4, 0.16, 0.055, 0.72)
        if symbol_kind == "spark":
            ds = sd_star(x, y, 0.0, 0.0, 0.46)
            r, g, b, a = over(r, g, b, a, 0.25, 0.12, 0.02, 1.0 - smoothstep(-aa, aa, ds - 0.03))
            r, g, b, a = over(r, g, b, a, 1.0, 0.96, 0.68, 1.0 - smoothstep(-aa, aa, ds))
        elif symbol_kind == "flow":
            d1 = sd_capsule(x, y, -0.38, -0.18, 0.38, -0.18, 0.08)
            d2 = sd_capsule(x, y, -0.28, 0.05, 0.42, 0.05, 0.08)
            d3 = sd_capsule(x, y, -0.38, 0.28, 0.28, 0.28, 0.08)
            dw = min(d1, min(d2, d3))
            r, g, b, a = over(r, g, b, a, 0.08, 0.25, 0.32, 1.0 - smoothstep(-aa, aa, dw - 0.025))
            r, g, b, a = over(r, g, b, a, 0.90, 0.99, 1.0, 1.0 - smoothstep(-aa, aa, dw))
        elif symbol_kind == "rest":
            do = sd_octagon(x, y, 0.44)
            r, g, b, a = over(r, g, b, a, 0.05, 0.28, 0.14, 1.0 - smoothstep(-aa, aa, do - 0.03))
            r, g, b, a = over(r, g, b, a, 0.85, 1.0, 0.88, 1.0 - smoothstep(-aa, aa, do))
            dh = sd_heart(x * 2.6, (y + 0.02) * 2.6) / 2.6
            r, g, b, a = over(r, g, b, a, 0.12, 0.72, 0.42, 1.0 - smoothstep(-aa, aa, dh))
        return r, g, b, a
    return px


def px_overlay_restricted(x, y, aa):
    r, g, b, a = 0.0, 0.0, 0.0, 0.0
    d_ring = abs(sd_round_box(x, y, 0.0, 0.0, 0.84, 0.84, 0.22)) - 0.045
    r, g, b, a = over(r, g, b, a, 1.0, 0.45, 0.22, (1.0 - smoothstep(-aa, aa, d_ring)) * 0.85)
    bx, by = 0.56, 0.56
    d_bg = sd_circle(x, y, bx, by, 0.24)
    r, g, b, a = over(r, g, b, a, 0.20, 0.08, 0.08, 1.0 - smoothstep(-aa, aa, d_bg - 0.025))
    r, g, b, a = over(r, g, b, a, 1.0, 0.52, 0.24, 1.0 - smoothstep(-aa, aa, d_bg))
    d_shackle = max(abs(sd_circle(x, y, bx, by - 0.04, 0.075)) - 0.022, y - (by - 0.03))
    d_body = sd_round_box(x, y, bx, by + 0.05, 0.095, 0.075, 0.022)
    r, g, b, a = over(r, g, b, a, 1.0, 0.97, 0.92, 1.0 - smoothstep(-aa, aa, min(d_shackle, d_body)))
    return r, g, b, a


def px_overlay_shield_aura(x, y, aa):
    dist = math.hypot(x, y)
    ring = math.exp(-((dist - 0.78) * 14.0) ** 2)
    inner = math.exp(-((dist - 0.65) * 6.0) ** 2) * 0.35
    return 0.35, 1.0, 0.68, clamp(ring * 0.85 + inner)


def px_pulse_ring(x, y, aa):
    dist = math.hypot(x, y)
    ring = math.exp(-((dist - 0.74) * 12.0) ** 2)
    halo = math.exp(-((dist - 0.74) * 4.5) ** 2) * 0.4
    return 1.0, 1.0, 1.0, clamp(ring + halo)


def px_particle_star(x, y, aa):
    d = sd_star(x, y, 0.0, 0.0, 0.72)
    a = 1.0 - smoothstep(-aa * 2.0, aa * 2.0, d)
    glow = math.exp(-((math.hypot(x, y) * 2.2) ** 2)) * 0.5
    return 1.0, 0.96, 0.75, clamp(max(a, glow))


def px_particle_heart(x, y, aa):
    d = sd_heart(x * 1.15, y * 1.15)
    return 1.0, 0.68, 0.78, 1.0 - smoothstep(-aa * 2.0, aa * 2.0, d)


def px_particle_leaf(x, y, aa):
    lx, ly = rot(x, y, -0.5)
    d = sd_ellipse(lx, ly, 0.0, 0.0, 0.62, 0.30)
    return 0.45, 0.95, 0.58, 1.0 - smoothstep(-aa * 2.0, aa * 2.0, d)


def px_icon_bg(x, y, aa):
    t = clamp((y + 1.0) * 0.5)
    c = mix_rgb(hex_rgb("#1AB29E"), hex_rgb("#053736"), t)
    glow = math.exp(-((x * 1.10) ** 2 + (y * 1.10) ** 2)) * 0.44
    c = mix_rgb(c, hex_rgb("#9BF7D6"), glow)
    # Glossy diagonal top-left studio glass sheen
    sheen = clamp(1.0 - (x * 0.45 + y * 0.85 + 0.35) * 1.6) * 0.18
    c = mix_rgb(c, (1.0, 1.0, 1.0), sheen)
    dist = math.hypot(x, y)
    rings = (
        math.exp(-((dist - 0.62) * 20.0) ** 2) * 0.45
        + math.exp(-((dist - 0.78) * 20.0) ** 2) * 0.30
        + math.exp(-((dist - 0.92) * 20.0) ** 2) * 0.16
    )
    c = mix_rgb(c, hex_rgb("#FFE999"), clamp(rings))
    return c[0], c[1], c[2], 1.0


def _draw_heart_mascot_glossy(x, y, aa, scale, r, g, b, a):
    hx = x * scale
    hy = (y - 0.02) * scale
    hr, hg, hb, ha = make_organ_heart(False)(hx, hy, aa * scale)
    # Extra candy-glass dome specular glaze on upper-left cheek of the Heart
    d_heart_mask = sd_heart(hx * 1.10, (hy + 0.01) * 1.10) / 1.10
    if ha > 0.01 and d_heart_mask < -0.02:
        gx = hx + 0.20
        gy = hy + 0.28
        dome = math.exp(-((gx * 2.1) ** 2 + (gy * 2.5) ** 2)) * 0.42
        rx, ry = rot(hx + 0.24, hy + 0.25, 0.52)
        ribbon = (1.0 - smoothstep(-aa * scale, aa * scale, sd_ellipse(rx, ry, 0.0, 0.0, 0.22, 0.075))) * 0.52
        hr = clamp(hr + (dome + ribbon) * (1.0 - hr) * 0.75)
        hg = clamp(hg + (dome + ribbon) * (1.0 - hg) * 0.75)
        hb = clamp(hb + (dome + ribbon) * (1.0 - hb) * 0.75)
    r, g, b, a = over(r, g, b, a, hr, hg, hb, ha)

    # Golden sparkle accents around the mascot
    for sx, sy, sr in ((-0.46 / scale * 1.35, -0.34 / scale * 1.35, 0.075), (0.50 / scale * 1.35, 0.28 / scale * 1.35, 0.068), (-0.42 / scale * 1.35, 0.38 / scale * 1.35, 0.055)):
        ds = sd_star(x, y, sx, sy, sr)
        r, g, b, a = over(r, g, b, a, 1.0, 0.96, 0.56, 1.0 - smoothstep(-aa, aa, ds))
    return r, g, b, a


def px_icon_fg(x, y, aa):
    r, g, b, a = 0.0, 0.0, 0.0, 0.0
    dist = math.hypot(x, y)
    rings = math.exp(-((dist - 0.55) * 19.0) ** 2) * 0.85 + math.exp(-((dist - 0.67) * 19.0) ** 2) * 0.42
    r, g, b, a = over(r, g, b, a, 0.54, 0.99, 0.76, clamp(rings))
    return _draw_heart_mascot_glossy(x, y, aa, 1.48, r, g, b, a)


def px_app_icon_rounded(x, y, aa):
    d_box = sd_round_box(x, y, 0.0, 0.0, 0.91, 0.91, 0.24)
    mask = 1.0 - smoothstep(-aa, aa, d_box)
    if mask <= 0.001:
        return 0.0, 0.0, 0.0, 0.0

    r, g, b, a = px_icon_bg(x, y, aa)
    a = mask

    # Curved upper glass reflection overlay inside icon
    glass_curve = sd_ellipse(x + 0.10, y + 0.68, 0.0, 0.0, 1.28, 0.78)
    ga = (1.0 - smoothstep(-aa, aa, glass_curve)) * (clamp(-y * 0.55 + 0.35) * 0.24) * mask
    r, g, b, a = over(r, g, b, a, 1.0, 1.0, 0.99, ga)

    # Matching Smiling Heart character (scale 1.22 fills badge cleanly)
    r, g, b, a = _draw_heart_mascot_glossy(x, y, aa, 1.22, r, g, b, a)

    # Glossy crystal bezel rim
    if d_box > -0.075 and d_box < 0.005:
        rim_t = smoothstep(-0.075, -0.025, d_box) * (1.0 - smoothstep(-0.005, 0.005, d_box))
        spec = 0.45 + 0.55 * clamp(1.0 - math.hypot(x + 0.55, y + 0.55) * 0.85)
        r, g, b, a = over(r, g, b, a, 0.82 * spec + 0.18, 0.98 * spec + 0.02, 0.92 * spec + 0.08, rim_t * 0.78 * mask)

    # Corner star gleam on top-right glass bezel
    gx, gy = rot(x - 0.64, y + 0.64, 0.785)
    d_gleam = min(sd_ellipse(x - 0.64, y + 0.64, 0.0, 0.0, 0.14, 0.022), sd_ellipse(x - 0.64, y + 0.64, 0.0, 0.0, 0.022, 0.14))
    d_gleam = min(d_gleam, sd_circle(x, y, 0.64, -0.64, 0.045))
    r, g, b, a = over(r, g, b, a, 1.0, 1.0, 0.96, (1.0 - smoothstep(-aa, aa, d_gleam)) * 0.90 * mask)
    return r, g, b, clamp(mask)


def generate_asset(name, fn, master_size=512, out_dir=TILE_DIR, save_master=True):
    c = Canvas(master_size)
    c.render(fn)
    if save_master:
        c.save_png(os.path.join(MASTER_DIR, f"{name}_{master_size}.png"))
    down = c.downsample_half()
    out_path = os.path.join(out_dir, f"{name}.png")
    down.save_png(out_path)
    print(f"Generated {out_path} ({down.size}x{down.size})")


def main():
    sprites = [
        ("organ_heart", make_organ_heart(False), 512),
        ("organ_heart_happy", make_organ_heart(True), 512),
        ("organ_brain", make_organ_brain(False), 512),
        ("organ_brain_happy", make_organ_brain(True), 512),
        ("organ_lungs", make_organ_lungs(False), 512),
        ("organ_lungs_happy", make_organ_lungs(True), 512),
        ("organ_kidneys", make_organ_kidneys(False), 512),
        ("organ_kidneys_happy", make_organ_kidneys(True), 512),
        ("organ_stomach", make_organ_stomach(False), 512),
        ("organ_stomach_happy", make_organ_stomach(True), 512),
        ("organ_liver", make_organ_liver(False), 512),
        ("organ_liver_happy", make_organ_liver(True), 512),
        ("special_care", px_special_care, 512),
        ("special_overload", lambda x, y, aa: px_special_overload(x, y, aa, False), 512),
        ("special_overload_soda", px_special_overload_soda, 512),
        ("special_overload_snack", px_special_overload_snack, 512),
        ("special_overload_armor", lambda x, y, aa: px_special_overload(x, y, aa, True), 512),
        ("special_bloom", px_special_bloom, 512),
        ("icon_ability_spark", make_ability_icon("#FFD452", "#E67E18", "spark"), 256),
        ("icon_ability_flow", make_ability_icon("#56E8DF", "#128CA6", "flow"), 256),
        ("icon_ability_rest", make_ability_icon("#52EE9B", "#0E9454", "rest"), 256),
        ("overlay_restricted", px_overlay_restricted, 512),
        ("overlay_shield_aura", px_overlay_shield_aura, 512),
        ("pulse_ring", px_pulse_ring, 512),
        ("particle_star", px_particle_star, 256),
        ("particle_heart", px_particle_heart, 256),
        ("particle_leaf", px_particle_leaf, 256),
    ]
    import sys
    only = set(sys.argv[1:])
    if only == {"icons"}:
        sprites = []

    for name, fn, sz in sprites:
        if only and name not in only:
            continue
        generate_asset(name, fn, sz, TILE_DIR, save_master=True)

    if not only or "icons" in only:
        cfg = Canvas(864)
        cfg.render(px_icon_fg)
        cfg.downsample_half().save_png(os.path.join(ICON_DIR, "adaptive_fg_432.png"))

        cbg = Canvas(864)
        cbg.render(px_icon_bg)
        cbg.downsample_half().save_png(os.path.join(ICON_DIR, "adaptive_bg_432.png"))

        c1024 = Canvas(1024)
        c1024.render(px_app_icon_rounded)
        c1024.save_png(os.path.join(ICON_DIR, "icon_1024.png"))

        c192 = Canvas(384)
        c192.render(px_app_icon_rounded)
        c192.downsample_half().save_png(os.path.join(ICON_DIR, "launcher_192.png"))
        print("Generated glossy matching Heart icons: adaptive_fg_432.png, adaptive_bg_432.png, icon_1024.png, launcher_192.png")

    print("Asset generation complete.")


if __name__ == "__main__":
    main()
