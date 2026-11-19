Add-Type -AssemblyName System.Drawing

$csharp = @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class AppleAssetBuilder {
    public static byte[] LockReadRgba(Bitmap bmp) {
        int w = bmp.Width, h = bmp.Height;
        BitmapData bd = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        byte[] buf = new byte[w * h * 4];
        Marshal.Copy(bd.Scan0, buf, 0, buf.Length);
        bmp.UnlockBits(bd);
        return buf;
    }

    public static void LockWriteRgba(Bitmap bmp, byte[] buf) {
        int w = bmp.Width, h = bmp.Height;
        BitmapData bd = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        Marshal.Copy(buf, 0, bd.Scan0, buf.Length);
        bmp.UnlockBits(bd);
    }

    static bool IsWhiteBgPixel(byte b, byte g, byte r) {
        int minC = Math.Min(r, Math.Min(g, b));
        int maxC = Math.Max(r, Math.Max(g, b));
        return minC >= 246 && (maxC - minC) <= 10;
    }

    static bool IsStudioBgPixel(byte b, byte g, byte r, string role) {
        // Dark corners / emerald vignette
        if (r < 32 && g < 88 && b < 90 && g >= r + 4 && b >= r + 2) return true;
        if (role == "care" || role == "bloom") {
            // Preserve lime broccoli/lettuce (g - b > 34 or high r), remove dark emerald-teal studio glow
            return r < 58 && g < 150 && b < 135 && g >= r + 14 && (g - b) <= 30 && b >= r + 4;
        }
        if (role == "lungs") {
            return r < 85 && g < 185 && b < 170 && g >= r + 10 && b <= g + 4 && b >= r + 2;
        }
        // Warm organs & fatty villain foods: remove entire teal/emerald-mint radial studio halo
        return r < 198 && g >= r + 8 && b >= r - 4 && (g - b) <= 44;
    }

    static void RgbToHsv(double r, double g, double b, out double h, out double s, out double v) {
        double max = Math.Max(r, Math.Max(g, b));
        double min = Math.Min(r, Math.Min(g, b));
        double d = max - min;
        v = max;
        s = max <= 1e-6 ? 0.0 : d / max;
        if (d <= 1e-6) {
            h = 0.0;
            return;
        }
        if (Math.Abs(max - r) < 1e-6) h = 60.0 * (((g - b) / d) % 6.0);
        else if (Math.Abs(max - g) < 1e-6) h = 60.0 * (((b - r) / d) + 2.0);
        else h = 60.0 * (((r - g) / d) + 4.0);
        if (h < 0) h += 360.0;
    }

    static void HsvToRgb(double h, double s, double v, out byte r, out byte g, out byte b) {
        double c = v * s;
        double hh = (h % 360.0) / 60.0;
        if (hh < 0) hh += 6.0;
        double x = c * (1.0 - Math.Abs((hh % 2.0) - 1.0));
        double rr = 0, gg = 0, bb = 0;
        if (hh < 1)      { rr = c; gg = x; bb = 0; }
        else if (hh < 2) { rr = x; gg = c; bb = 0; }
        else if (hh < 3) { rr = 0; gg = c; bb = x; }
        else if (hh < 4) { rr = 0; gg = x; bb = c; }
        else if (hh < 5) { rr = x; gg = 0; bb = c; }
        else             { rr = c; gg = 0; bb = x; }
        double m = v - c;
        r = (byte)Math.Max(0, Math.Min(255, (int)Math.Round((rr + m) * 255.0)));
        g = (byte)Math.Max(0, Math.Min(255, (int)Math.Round((gg + m) * 255.0)));
        b = (byte)Math.Max(0, Math.Min(255, (int)Math.Round((bb + m) * 255.0)));
    }

    static double LerpAngle(double a, double b, double t) {
        double diff = ((b - a + 540.0) % 360.0) - 180.0;
        double res = (a + diff * t) % 360.0;
        if (res < 0) res += 360.0;
        return res;
    }

    static void RecolorMascot(byte[] buf, int w, int h, string role) {
        if (role != "brain" && role != "kidneys" && role != "liver") return;
        for (int p = 0; p < w * h; p++) {
            int bi = p * 4;
            if (buf[bi + 3] < 8) continue;
            double bb = buf[bi] / 255.0;
            double gg = buf[bi + 1] / 255.0;
            double rr = buf[bi + 2] / 255.0;
            double hue, sat, val;
            RgbToHsv(rr, gg, bb, out hue, out sat, out val);
            // Keep white gloves, eye whites, teeth, and deep pupils intact
            if (sat < 0.24 || val < 0.14) continue;

            if (role == "brain") {
                // Shift salmon-red cortex, shoes, and arms to Royal Amethyst Purple (272 deg)
                if (hue <= 28.0 || hue >= 325.0) {
                    double t = sat >= 0.42 ? 1.0 : (sat - 0.24) / 0.18;
                    double newH = LerpAngle(hue, 272.0, t);
                    double newS = Math.Min(1.0, sat * (1.0 + 0.14 * t));
                    double newV = Math.Min(1.0, val * (1.0 + 0.05 * t));
                    byte nr, ng, nb;
                    HsvToRgb(newH, newS, newV, out nr, out ng, out nb);
                    buf[bi] = nb; buf[bi + 1] = ng; buf[bi + 2] = nr;
                }
            } else if (role == "kidneys") {
                // Shift dark crimson kidney to Rich Chestnut-Amber Brown (28 deg), keep blue tube intact
                if (hue <= 24.0 || hue >= 332.0) {
                    double t = sat >= 0.45 ? 1.0 : (sat - 0.24) / 0.21;
                    double newH = LerpAngle(hue, 27.0, t);
                    double newS = Math.Min(0.86, sat * 0.92);
                    double newV = Math.Min(0.95, val * 0.90);
                    byte nr, ng, nb;
                    HsvToRgb(newH, newS, newV, out nr, out ng, out nb);
                    buf[bi] = nb; buf[bi + 1] = ng; buf[bi + 2] = nr;
                }
            } else if (role == "liver") {
                // Shift amber-orange pancreas & dark red shoes toward Sunny Golden Yellow (44 deg)
                if (hue <= 40.0 || hue >= 330.0) {
                    double t = sat >= 0.38 ? 1.0 : (sat - 0.24) / 0.14;
                    double newH = LerpAngle(hue, 44.0, t);
                    double newS = Math.Min(0.96, sat * 1.04);
                    double newV = Math.Min(1.0, val * 1.12);
                    byte nr, ng, nb;
                    HsvToRgb(newH, newS, newV, out nr, out ng, out nb);
                    buf[bi] = nb; buf[bi + 1] = ng; buf[bi + 2] = nr;
                }
            }
        }
    }

    public static Bitmap ExtractForeground(string srcPath, string role, out Rectangle tightBox) {
        using (Bitmap orig = (Bitmap)Bitmap.FromFile(srcPath)) {
            int w = orig.Width, h = orig.Height;
            Bitmap work = new Bitmap(w, h, PixelFormat.Format32bppArgb);
            using (Graphics gr = Graphics.FromImage(work)) {
                gr.DrawImage(orig, 0, 0, w, h);
            }
            byte[] buf = LockReadRgba(work);

            // Detect native alpha transparency (like the 4 user-uploaded mascot PNGs)
            byte cornerA = buf[3];
            bool hasNativeAlpha = cornerA < 16;

            if (!hasNativeAlpha) {
                bool isWhiteBg = IsWhiteBgPixel(buf[0], buf[1], buf[2]);
                bool[] bg = new bool[w * h];
                Queue<int> q = new Queue<int>();

                for (int x = 0; x < w; x++) {
                    int top = x;
                    int bot = (h - 1) * w + x;
                    if (!bg[top]) { bg[top] = true; q.Enqueue(top); }
                    if (!bg[bot]) { bg[bot] = true; q.Enqueue(bot); }
                }
                for (int y = 0; y < h; y++) {
                    int lft = y * w;
                    int rgt = y * w + (w - 1);
                    if (!bg[lft]) { bg[lft] = true; q.Enqueue(lft); }
                    if (!bg[rgt]) { bg[rgt] = true; q.Enqueue(rgt); }
                }

                int[] dx = { -1, 1, 0, 0 };
                int[] dy = { 0, 0, -1, 1 };
                while (q.Count > 0) {
                    int p = q.Dequeue();
                    int x = p % w, y = p / w;
                    for (int k = 0; k < 4; k++) {
                        int nx = x + dx[k], ny = y + dy[k];
                        if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
                        int np = ny * w + nx;
                        if (bg[np]) continue;
                        int bi = np * 4;
                        bool match = isWhiteBg
                            ? IsWhiteBgPixel(buf[bi], buf[bi + 1], buf[bi + 2])
                            : IsStudioBgPixel(buf[bi], buf[bi + 1], buf[bi + 2], role);
                        if (match) {
                            bg[np] = true;
                            q.Enqueue(np);
                        }
                    }
                }

                for (int y = 0; y < h; y++) {
                    for (int x = 0; x < w; x++) {
                        int p = y * w + x;
                        int bi = p * 4;
                        if (bg[p]) {
                            buf[bi + 3] = 0;
                            continue;
                        }
                        int bgNbs = 0;
                        for (int oy = -2; oy <= 2; oy++) {
                            int yy = y + oy;
                            if (yy < 0 || yy >= h) { bgNbs++; continue; }
                            for (int ox = -2; ox <= 2; ox++) {
                                int xx = x + ox;
                                if (xx < 0 || xx >= w || bg[yy * w + xx]) bgNbs++;
                            }
                        }
                        double aVal = 255.0;
                        if (bgNbs > 0) {
                            byte bb = buf[bi], gg = buf[bi + 1], rr = buf[bi + 2];
                            if (isWhiteBg && Math.Min(rr, Math.Min(gg, bb)) > 220) {
                                aVal = Math.Max(0.0, 255.0 * (1.0 - bgNbs / 12.0));
                            } else if (!isWhiteBg && rr < 180 && gg >= rr + 6 && (gg - bb) <= 45) {
                                aVal = Math.Max(0.0, 255.0 * (1.0 - bgNbs / 12.0));
                            } else if (bgNbs >= 10) {
                                aVal = 210.0;
                            }
                        }
                        buf[bi + 3] = (byte)Math.Round(aVal);
                    }
                }
            }

            RecolorMascot(buf, w, h, role);

            int minX = w, minY = h, maxX = 0, maxY = 0;
            for (int y = 0; y < h; y++) {
                for (int x = 0; x < w; x++) {
                    int p = y * w + x;
                    if (buf[p * 4 + 3] > 28) {
                        if (x < minX) minX = x;
                        if (x > maxX) maxX = x;
                        if (y < minY) minY = y;
                        if (y > maxY) maxY = y;
                    }
                }
            }

            LockWriteRgba(work, buf);
            if (maxX <= minX || maxY <= minY) {
                tightBox = new Rectangle(0, 0, w, h);
            } else {
                tightBox = new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
            }
            return work;
        }
    }

    public static void DrawStudioBg(Bitmap dst, Color inner, Color outer) {
        int w = dst.Width, h = dst.Height;
        byte[] buf = new byte[w * h * 4];
        double cx = (w - 1) * 0.5, cy = (h - 1) * 0.5;
        double rad = w * 0.60;
        int idx = 0;
        for (int y = 0; y < h; y++) {
            double dy = (y - cy) / rad;
            for (int x = 0; x < w; x++) {
                double dx = (x - cx) / rad;
                double glow = Math.Exp(-(dx * dx + dy * dy) * 2.0);
                buf[idx++] = (byte)Math.Round(outer.B + (inner.B - outer.B) * glow);
                buf[idx++] = (byte)Math.Round(outer.G + (inner.G - outer.G) * glow);
                buf[idx++] = (byte)Math.Round(outer.R + (inner.R - outer.R) * glow);
                buf[idx++] = 255;
            }
        }
        LockWriteRgba(dst, buf);
    }

    public static void CompositeFitted(Bitmap src, Rectangle box, Bitmap dst, double fillFraction) {
        int dw = dst.Width, dh = dst.Height;
        double maxSide = Math.Max(box.Width, box.Height);
        double scale = (dw * fillFraction) / maxSide;
        int tw = Math.Max(1, (int)Math.Round(box.Width * scale));
        int th = Math.Max(1, (int)Math.Round(box.Height * scale));
        int ox = (dw - tw) / 2;
        int oy = (dh - th) / 2;
        using (Graphics g = Graphics.FromImage(dst)) {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.DrawImage(src, new Rectangle(ox, oy, tw, th), box, GraphicsUnit.Pixel);
        }
    }

    static GraphicsPath RoundedRect(float x, float y, float w, float h, float r) {
        GraphicsPath p = new GraphicsPath();
        float d = r * 2f;
        p.AddArc(x, y, d, d, 180, 90);
        p.AddArc(x + w - d, y, d, d, 270, 90);
        p.AddArc(x + w - d, y + h - d, d, d, 0, 90);
        p.AddArc(x, y + h - d, d, d, 90, 90);
        p.CloseFigure();
        return p;
    }

    public static Bitmap CreateOrganTile(Bitmap fg, Rectangle box, int size, Color topCol, Color botCol, Color borderCol) {
        Bitmap dst = new Bitmap(size, size, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(dst)) {
            g.Clear(Color.Transparent);
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;

            float pad = size * 0.025f;
            float side = size - pad * 2f;
            float rad = size * 0.19f;

            // Soft outer elevation shadow
            using (GraphicsPath shPath = RoundedRect(pad, pad + size * 0.015f, side, side, rad))
            using (SolidBrush shBrush = new SolidBrush(Color.FromArgb(65, 8, 22, 22))) {
                g.FillPath(shBrush, shPath);
            }

            using (GraphicsPath sqPath = RoundedRect(pad, pad, side, side, rad)) {
                using (LinearGradientBrush fill = new LinearGradientBrush(
                    new PointF(0, pad),
                    new PointF(0, pad + side),
                    topCol,
                    botCol)) {
                    g.FillPath(fill, sqPath);
                }

                // Subtle soft radial white spotlight behind mascot for high contrast
                g.SetClip(sqPath);
                using (GraphicsPath spot = new GraphicsPath()) {
                    spot.AddEllipse(size * 0.08f, size * 0.08f, size * 0.84f, size * 0.84f);
                    using (PathGradientBrush pgb = new PathGradientBrush(spot)) {
                        pgb.CenterColor = Color.FromArgb(88, 255, 255, 255);
                        pgb.SurroundColors = new Color[] { Color.FromArgb(0, 255, 255, 255) };
                        g.FillEllipse(pgb, size * 0.08f, size * 0.08f, size * 0.84f, size * 0.84f);
                    }
                }
                // Crisp Apple-style top specular gloss
                using (LinearGradientBrush glass = new LinearGradientBrush(
                    new PointF(0, pad),
                    new PointF(0, size * 0.42f),
                    Color.FromArgb(95, 255, 255, 255),
                    Color.FromArgb(0, 255, 255, 255))) {
                    g.FillEllipse(glass, -size * 0.08f, -size * 0.16f, size * 1.16f, size * 0.56f);
                }
                g.ResetClip();

                using (Pen rim = new Pen(borderCol, Math.Max(3f, size * 0.028f))) {
                    g.DrawPath(rim, sqPath);
                }
                using (Pen innerRim = new Pen(Color.FromArgb(140, 255, 255, 255), Math.Max(1.5f, size * 0.012f))) {
                    using (GraphicsPath iPath = RoundedRect(pad + size * 0.016f, pad + size * 0.016f, side - size * 0.032f, side - size * 0.032f, rad * 0.90f)) {
                        g.DrawPath(innerRim, iPath);
                    }
                }
            }
        }

        // Composite mascot large (~88% of square) right inside the rounded square tile!
        CompositeFitted(fg, box, dst, 0.88);
        return dst;
    }

    public static Bitmap CreateRoundedAppIcon(Bitmap fg, Rectangle box, int size, Color topCol, Color botCol) {
        Bitmap square = CreateOrganTile(fg, box, size, topCol, botCol, Color.FromArgb(245, 255, 255, 255));
        Bitmap outBmp = new Bitmap(size, size, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(outBmp)) {
            g.Clear(Color.Transparent);
            g.DrawImage(square, 0, 0, size, size);
        }
        square.Dispose();
        return outBmp;
    }

    public static Bitmap CreateHappyVariant(Bitmap normalTile) {
        int s = normalTile.Width;
        Bitmap dst = new Bitmap(s, s, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(dst)) {
            g.Clear(Color.Transparent);
            g.SmoothingMode = SmoothingMode.HighQuality;
            using (GraphicsPath gp = RoundedRect(s * 0.015f, s * 0.015f, s * 0.97f, s * 0.97f, s * 0.19f))
            using (Pen glowPen = new Pen(Color.FromArgb(255, 255, 232, 76), 10f)) {
                g.DrawPath(glowPen, gp);
            }
            ColorMatrix cm = new ColorMatrix(new float[][] {
                new float[] {1.10f, 0, 0, 0, 0},
                new float[] {0, 1.10f, 0, 0, 0},
                new float[] {0, 0, 1.08f, 0, 0},
                new float[] {0, 0, 0, 1.0f, 0},
                new float[] {0.05f, 0.05f, 0.03f, 0, 1f}
            });
            using (ImageAttributes ia = new ImageAttributes()) {
                ia.SetColorMatrix(cm);
                g.DrawImage(normalTile, new Rectangle(0, 0, s, s), 0, 0, s, s, GraphicsUnit.Pixel, ia);
            }
            DrawSparkle(g, s * 0.14f, s * 0.16f, s * 0.095f);
            DrawSparkle(g, s * 0.86f, s * 0.18f, s * 0.080f);
        }
        return dst;
    }

    static void DrawSparkle(Graphics g, float cx, float cy, float r) {
        PointF[] pts = new PointF[8];
        for (int i = 0; i < 8; i++) {
            double ang = i * Math.PI / 4.0;
            float rad = (i % 2 == 0) ? r : r * 0.30f;
            pts[i] = new PointF(cx + (float)(Math.Cos(ang) * rad), cy + (float)(Math.Sin(ang) * rad));
        }
        using (Pen p = new Pen(Color.FromArgb(245, 255, 250, 210), Math.Max(1.5f, r * 0.16f))) {
            g.DrawPolygon(p, pts);
        }
        using (SolidBrush b = new SolidBrush(Color.FromArgb(255, 255, 224, 70))) {
            g.FillPolygon(b, pts);
        }
    }

    public static Bitmap CreateHazardBadge(Bitmap fg, Rectangle box, bool armored) {
        int s = 256;
        Bitmap dst = new Bitmap(s, s, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(dst)) {
            g.Clear(Color.Transparent);
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;

            PointF[] oct = new PointF[8];
            float rad = s * 0.47f;
            float c = s * 0.50f;
            for (int i = 0; i < 8; i++) {
                double a = Math.PI / 8.0 + i * Math.PI / 4.0;
                oct[i] = new PointF(c + (float)(Math.Cos(a) * rad), c + (float)(Math.Sin(a) * rad));
            }
            Color bg1 = armored ? Color.FromArgb(245, 52, 58, 76) : Color.FromArgb(245, 145, 22, 32);
            Color rimC = armored ? Color.FromArgb(255, 195, 210, 232) : Color.FromArgb(255, 255, 118, 48);
            using (SolidBrush br = new SolidBrush(bg1)) g.FillPolygon(br, oct);
            using (Pen pen = new Pen(rimC, 8f)) g.DrawPolygon(pen, oct);

            CompositeFitted(fg, box, dst, 0.85);

            PointF[] tri = { new PointF(s * 0.84f, s * 0.04f), new PointF(s * 0.96f, s * 0.25f), new PointF(s * 0.72f, s * 0.25f) };
            using (SolidBrush tb = new SolidBrush(Color.FromArgb(255, 255, 214, 38))) g.FillPolygon(tb, tri);
            using (Pen tp = new Pen(Color.FromArgb(255, 72, 12, 12), 3.5f)) g.DrawPolygon(tp, tri);
            using (SolidBrush exb = new SolidBrush(Color.FromArgb(255, 58, 10, 10))) {
                g.FillRectangle(exb, s * 0.826f, s * 0.108f, s * 0.028f, s * 0.075f);
                g.FillEllipse(exb, s * 0.822f, s * 0.200f, s * 0.034f, s * 0.034f);
            }

            if (armored) {
                using (GraphicsPath sh = RoundedRect(s * 0.06f, s * 0.63f, s * 0.26f, s * 0.30f, s * 0.06f)) {
                    using (SolidBrush sb = new SolidBrush(Color.FromArgb(255, 36, 106, 206))) g.FillPath(sb, sh);
                    using (Pen sp = new Pen(Color.FromArgb(255, 250, 212, 76), 4.5f)) g.DrawPath(sp, sh);
                }
                using (Font f = new Font("Arial", 32, FontStyle.Bold, GraphicsUnit.Pixel))
                using (StringFormat sf = new StringFormat() { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center })
                using (SolidBrush wb = new SolidBrush(Color.White)) {
                    g.DrawString("2", f, wb, new RectangleF(s * 0.06f, s * 0.64f, s * 0.26f, s * 0.29f), sf);
                }
            }
        }
        return dst;
    }

    public static Bitmap CreateHealthyTile(Bitmap fg, Rectangle box, bool isAntioxidant) {
        int s = 256;
        Bitmap dst = new Bitmap(s, s, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(dst)) {
            g.Clear(Color.Transparent);
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            Color rimCol = isAntioxidant ? Color.FromArgb(255, 255, 205, 42) : Color.FromArgb(255, 42, 224, 128);
            Color fillCol = isAntioxidant ? Color.FromArgb(245, 92, 46, 148) : Color.FromArgb(245, 20, 146, 78);
            using (SolidBrush fb = new SolidBrush(fillCol)) g.FillEllipse(fb, 8, 8, s - 16, s - 16);
            using (Pen rp = new Pen(rimCol, 9f)) g.DrawEllipse(rp, 8, 8, s - 16, s - 16);
            CompositeFitted(fg, box, dst, 0.86);
        }
        return dst;
    }
}
"@

Add-Type -TypeDefinition $csharp -ReferencedAssemblies System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$artDir = "C:\Users\User\.gemini\antigravity\brain\6555a06f-d3f1-4e81-8daf-9b20cd11e4d5"
$uploadDir = Join-Path $artDir ".user_uploaded"
$masterDir = Join-Path $root "assets\master_sources"
$tileDir = Join-Path $root "assets\sprites\tiles"
$iconDir = Join-Path $root "assets\icons"

function C($r, $g, $b) { return [System.Drawing.Color]::FromArgb(255, $r, $g, $b) }

# Organs mapped cleanly to 7 unmistakable colors on glossy rounded-square badges ("mendekati kotak")
$items = @{
    "heart"          = @{ src = (Join-Path $uploadDir "media_1795044816050_faa17f7c.png");           isOrgan = $true;  top = (C 255 128 142); bot = (C 198 22 46);  rim = (C 155 12 32) }
    "lungs"          = @{ src = (Join-Path $artDir "twin_lungs_mascot_refined_1795045162048.jpg");     isOrgan = $true;  top = (C 120 228 255); bot = (C 16 146 218); rim = (C 10 104 168) }
    "brain"          = @{ src = (Join-Path $uploadDir "media_1795044829588_a117c633.png");           isOrgan = $true;  top = (C 196 142 255); bot = (C 118 44 218); rim = (C 82 22 162) }
    "stomach"        = @{ src = (Join-Path $artDir "stomach_mascot_icon_v2_1795045160166.jpg");        isOrgan = $true;  top = (C 255 182 96);  bot = (C 232 94 14);  rim = (C 175 62 6) }
    "muscle"         = @{ src = (Join-Path $artDir "biceps_muscle_mascot_v2_1795045175765.jpg");       isOrgan = $true;  top = (C 255 128 196); bot = (C 202 28 118); rim = (C 146 14 78) }
    "liver"          = @{ src = (Join-Path $uploadDir "media_1795044835846_6a2702e4.png");           isOrgan = $true;  top = (C 255 236 112); bot = (C 232 168 12); rim = (C 176 118 6) }
    "kidneys"        = @{ src = (Join-Path $uploadDir "media_1795044823613_a7305934.png");           isOrgan = $true;  top = (C 218 164 108); bot = (C 142 78 28);  rim = (C 96 46 12) }
    "care"           = @{ src = (Join-Path $artDir "healthy_veggie_salad_hero_88pct_1795044459179.jpg"); isOrgan = $false }
    "bloom"          = @{ src = (Join-Path $artDir "antioxidant_fruit_superfood_icon_fullframe_1795044430004.jpg"); isOrgan = $false }
    "overload"       = @{ src = (Join-Path $artDir "greasy_double_cheeseburger_villain_icon_tight_1795044464466.jpg"); isOrgan = $false }
    "overload_soda"  = @{ src = (Join-Path $artDir "greasy_pizza_villain_icon_1795044422881.jpg");     isOrgan = $false }
    "overload_snack" = @{ src = (Join-Path $artDir "ribeye_steak_villain_icon_1to1_v3_1795044458187.jpg"); isOrgan = $false }
}

$box = New-Object System.Drawing.Rectangle(0, 0, 1, 1)

foreach ($key in $items.Keys) {
    $cfg = $items[$key]
    $srcPath = $cfg.src
    $ext = [System.IO.Path]::GetExtension($srcPath)
    Copy-Item $srcPath (Join-Path $masterDir ("raw_3d_" + $key + $ext)) -Force

    $fg = [AppleAssetBuilder]::ExtractForeground($srcPath, $key, [ref]$box)

    if ($cfg.isOrgan) {
        # 1. Full-frame 1024x1024 glossy rounded-square character showcase icon
        $sq = [AppleAssetBuilder]::CreateOrganTile($fg, $box, 1024, $cfg.top, $cfg.bot, $cfg.rim)
        $sq.Save((Join-Path $masterDir ("icon_square_" + $key + ".png")), [System.Drawing.Imaging.ImageFormat]::Png)
        $sq.Save((Join-Path $artDir ("icon_square_" + $key + ".png")), [System.Drawing.Imaging.ImageFormat]::Png)

        # 2. Game tile 256x256 (fills ~95% of cell, unmistakable hue!)
        $tile = [AppleAssetBuilder]::CreateOrganTile($fg, $box, 256, $cfg.top, $cfg.bot, $cfg.rim)
        $tile.Save((Join-Path $tileDir ("organ_" + $key + ".png")), [System.Drawing.Imaging.ImageFormat]::Png)

        $happy = [AppleAssetBuilder]::CreateHappyVariant($tile)
        $happy.Save((Join-Path $tileDir ("organ_" + $key + "_happy.png")), [System.Drawing.Imaging.ImageFormat]::Png)
        $happy.Dispose()
        $tile.Dispose()

        if ($key -eq "heart") {
            # App Icons built directly from smiling Heart mascot
            $icon1024 = [AppleAssetBuilder]::CreateRoundedAppIcon($fg, $box, 1024, $cfg.top, $cfg.bot)
            $icon1024.Save((Join-Path $iconDir "icon_1024.png"), [System.Drawing.Imaging.ImageFormat]::Png)
            $icon192 = [AppleAssetBuilder]::CreateRoundedAppIcon($fg, $box, 192, $cfg.top, $cfg.bot)
            $icon192.Save((Join-Path $iconDir "launcher_192.png"), [System.Drawing.Imaging.ImageFormat]::Png)
            $icon1024.Dispose()
            $icon192.Dispose()

            $adBg = New-Object System.Drawing.Bitmap(432, 432, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            [AppleAssetBuilder]::DrawStudioBg($adBg, $cfg.top, $cfg.bot)
            $adBg.Save((Join-Path $iconDir "adaptive_bg_432.png"), [System.Drawing.Imaging.ImageFormat]::Png)
            $adBg.Dispose()

            $adFg = New-Object System.Drawing.Bitmap(432, 432, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            [AppleAssetBuilder]::CompositeFitted($fg, $box, $adFg, 0.70)
            $adFg.Save((Join-Path $iconDir "adaptive_fg_432.png"), [System.Drawing.Imaging.ImageFormat]::Png)
            $adFg.Dispose()
        }
        $sq.Dispose()
    }
    else {
        # Special tiles & showcase square icons
        $sq = New-Object System.Drawing.Bitmap(1024, 1024, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        [AppleAssetBuilder]::DrawStudioBg($sq, (C 28 118 98), (C 4 38 44))
        [AppleAssetBuilder]::CompositeFitted($fg, $box, $sq, 0.90)
        $sq.Save((Join-Path $masterDir ("icon_square_" + $key + ".png")), [System.Drawing.Imaging.ImageFormat]::Png)
        $sq.Save((Join-Path $artDir ("icon_square_" + $key + ".png")), [System.Drawing.Imaging.ImageFormat]::Png)
        $sq.Dispose()

        if ($key -eq "care") {
            $ct = [AppleAssetBuilder]::CreateHealthyTile($fg, $box, $false)
            $ct.Save((Join-Path $tileDir "special_care.png"), [System.Drawing.Imaging.ImageFormat]::Png)
            $ct.Dispose()
        }
        elseif ($key -eq "bloom") {
            $bt = [AppleAssetBuilder]::CreateHealthyTile($fg, $box, $true)
            $bt.Save((Join-Path $tileDir "special_bloom.png"), [System.Drawing.Imaging.ImageFormat]::Png)
            $bt.Dispose()
        }
        elseif ($key -eq "overload") {
            $ov = [AppleAssetBuilder]::CreateHazardBadge($fg, $box, $false)
            $ov.Save((Join-Path $tileDir "special_overload.png"), [System.Drawing.Imaging.ImageFormat]::Png)
            $ov.Dispose()

            $ova = [AppleAssetBuilder]::CreateHazardBadge($fg, $box, $true)
            $ova.Save((Join-Path $tileDir "special_overload_armor.png"), [System.Drawing.Imaging.ImageFormat]::Png)
            $ova.Dispose()
        }
        elseif ($key -eq "overload_soda" -or $key -eq "overload_snack") {
            $ovx = [AppleAssetBuilder]::CreateHazardBadge($fg, $box, $false)
            $ovx.Save((Join-Path $tileDir ("special_" + $key + ".png")), [System.Drawing.Imaging.ImageFormat]::Png)
            $ovx.Dispose()
        }
    }

    $fg.Dispose()
    Write-Host ("Processed " + $key + " box=" + $box.Width + "x" + $box.Height)
}

Write-Host "ALL 12 MASCOT & FOOD ASSETS BUILT CLEANLY"