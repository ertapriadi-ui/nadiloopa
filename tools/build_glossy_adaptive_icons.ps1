Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$srcPath = Join-Path $root "assets\master_sources\icon_glossy_v2.jpg"
$fgPath  = Join-Path $root "assets\icons\adaptive_fg_432.png"
$bgPath  = Join-Path $root "assets\icons\adaptive_bg_432.png"

$src = [System.Drawing.Bitmap]::FromFile($srcPath)
$size = 432

# 1. Adaptive Background (432x432): Deep glossy emerald radial glow matching icon_glossy_v2.jpg
$bgBmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$cx = ($size - 1) * 0.5
$cy = ($size - 1) * 0.5
$maxR = $size * 0.65
for ($y = 0; $y -lt $size; $y++) {
    for ($x = 0; $x -lt $size; $x++) {
        $dx = ($x - $cx) / $maxR
        $dy = ($y - $cy) / $maxR
        $d = [Math]::Sqrt($dx * $dx + $dy * $dy)
        $gVal = [Math]::Exp(-($d * $d) * 2.2)
        $r = [int]([Math]::Round(5 + 16 * $gVal))
        $g = [int]([Math]::Round(58 + 78 * $gVal))
        $b = [int]([Math]::Round(52 + 64 * $gVal))
        $bgBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
    }
}
$bgBmp.Save($bgPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bgBmp.Dispose()

# 2. Adaptive Foreground (432x432): Glossy center organs from icon_glossy_v2.jpg inside 66% safe zone
$fgTemp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gr = [System.Drawing.Graphics]::FromImage($fgTemp)
$gr.Clear([System.Drawing.Color]::Transparent)
$gr.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gr.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$gr.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

# Crop central organ cluster inside glass bezel (10.5% margin) and scale to 316x316 centered at (216,216)
$cropPad = [int]([Math]::Round($src.Width * 0.115))
$srcW = [int]($src.Width - (2 * $cropPad))
$srcH = [int]($src.Height - (2 * $cropPad))
$srcRect = New-Object System.Drawing.Rectangle -ArgumentList @($cropPad, $cropPad, $srcW, $srcH)
$dstSize = 316
$dstOffset = [int](($size - $dstSize) / 2)
$dstRect = New-Object System.Drawing.Rectangle -ArgumentList @($dstOffset, $dstOffset, $dstSize, $dstSize)
$gr.DrawImage($src, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
$gr.Dispose()
$src.Dispose()

# Apply soft circular alpha feather + knock out dark background pixels near outer perimeter
$fgBmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$rInner = $size * 0.295
$rOuter = $size * 0.375
for ($y = 0; $y -lt $size; $y++) {
    for ($x = 0; $x -lt $size; $x++) {
        $px = $fgTemp.GetPixel($x, $y)
        $dist = [Math]::Sqrt(($x - $cx) * ($x - $cx) + ($y - $cy) * ($y - $cy))
        $t = [Math]::Max(0.0, [Math]::Min(1.0, ($dist - $rInner) / ($rOuter - $rInner)))
        $radialAlpha = 1.0 - ($t * $t * (3.0 - 2.0 * $t))
        $aOut = [int]([Math]::Round($px.A * $radialAlpha))
        $fgBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($aOut, $px.R, $px.G, $px.B))
    }
}
$fgTemp.Dispose()
$fgBmp.Save($fgPath, [System.Drawing.Imaging.ImageFormat]::Png)
$fgBmp.Dispose()
Write-Host "Built glossy adaptive_fg_432.png and adaptive_bg_432.png from icon_glossy_v2.jpg"
