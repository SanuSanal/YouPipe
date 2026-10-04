"""Turns raw phone captures into the README and website screenshots (docs/site.md).

    python tool/screenshots.py <dir with raw PNGs>

Each <name>.png (a 1080x2400 `adb exec-out screencap -p`) becomes:
  site/screenshots/<name>.webp    the screen only, with a clean status bar (the site draws the phone in CSS)
  assets/screenshots/<name>.webp  the same screen inside a thin-bezel, flat-sided phone frame (README)

The clean status bar replaces notification icons and the battery percentage with the time, signal,
Wi-Fi and a battery, like the website's hero mockup. The area behind it is filled from the row under the
system icons, blurred and faded into the real image. The icons are white on dark screens and near-black on
light ones. Adapted from YouPipe Music's tool of the same name.
"""

import shutil
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageStat

ROOT = Path(__file__).resolve().parent.parent
# Roboto, as the app uses it, from the Flutter SDK's material fonts.
FONT = Path(shutil.which("flutter")).resolve().parent / "cache" / "artifacts" / "material_fonts" / "roboto-medium.ttf"

TIME = "2:10"  # the same clock as the website's hero mockup, so every screenshot agrees
BAR = 100  # status bar height at 1080 px wide
ICONS_END = 80  # the system's status icons end above this row
SS = 4  # supersampling for anti-aliased shapes

# Frame proportions at a 1080 px screen: thin, even bezels and moderately rounded corners.
BEZEL = 26
OUTER_RADIUS = 118
SCREEN_RADIUS = 96
PUNCH_RADIUS = 19
KEY = 7  # side keys stick out this far


def clean_status_bar(shot: Image.Image) -> Image.Image:
    shot = shot.convert("RGB")
    w = shot.width
    # The row just under the system icons, stretched up and softened, fading into the real image below.
    row = shot.crop((0, ICONS_END, w, ICONS_END + 1))
    band = row.resize((w, BAR)).filter(ImageFilter.GaussianBlur(24))
    fade = Image.linear_gradient("L").resize((w, BAR - ICONS_END + 2)).transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    mask = Image.new("L", (w, BAR), 255)
    mask.paste(fade, (0, ICONS_END - 2))
    shot.paste(band, (0, 0), mask)

    light = ImageStat.Stat(row.convert("L")).mean[0] > 140
    ink = (15, 15, 15, 255) if light else (255, 255, 255, 255)

    layer = Image.new("RGBA", (w * SS, BAR * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cy = 50 * SS

    font = ImageFont.truetype(str(FONT), 38 * SS)
    d.text((62 * SS, cy), TIME, font=font, fill=ink, anchor="lm")

    # Battery: outline, fill and cap.
    right = (w - 60) * SS
    bw, bh = 48 * SS, 24 * SS
    bx, by = right - bw, cy - bh // 2
    d.rounded_rectangle((bx, by, bx + bw, by + bh), radius=6 * SS, outline=ink, width=3 * SS)
    d.rounded_rectangle((bx + 6 * SS, by + 6 * SS, bx + bw - 12 * SS, by + bh - 6 * SS), radius=2 * SS, fill=ink)
    d.rounded_rectangle((bx + bw + 3 * SS, cy - 5 * SS, bx + bw + 7 * SS, cy + 5 * SS), radius=2 * SS, fill=ink)

    # Wi-Fi: a wedge opening upwards from a point on the baseline.
    base = cy + 13 * SS
    r = 30 * SS
    half = int(r * 0.71)
    wx = bx - 22 * SS - half
    d.pieslice((wx - r, base - r, wx + r, base + r), start=225, end=315, fill=ink)

    # Signal: four rising bars.
    right_bar = wx - half - 20 * SS
    for i in range(4):
        h = (9 + i * 6) * SS
        x0 = right_bar - (3 - i) * 11 * SS - 7 * SS
        d.rounded_rectangle((x0, base - h, x0 + 7 * SS, base), radius=2 * SS, fill=ink)

    layer = layer.resize((w, BAR), Image.Resampling.LANCZOS)
    shot.paste(layer, (0, 0), layer)
    return shot


def rounded_mask(size, radius, scale=SS):
    w, h = size
    mask = Image.new("L", (w * scale, h * scale), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w * scale - 1, h * scale - 1), radius=radius * scale, fill=255)
    return mask.resize(size, Image.Resampling.LANCZOS)


def frame(screen: Image.Image) -> Image.Image:
    sw, sh = screen.size
    ow, oh = sw + 2 * BEZEL, sh + 2 * BEZEL
    canvas = Image.new("RGBA", (ow + 2 * KEY, oh), (0, 0, 0, 0))

    hi = Image.new("RGBA", ((ow + 2 * KEY) * SS, oh * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(hi)
    ox = KEY * SS
    # Side keys (volume, power) on the right edge.
    for top, length in ((0.20, 0.10), (0.33, 0.06)):
        y0 = int(oh * top) * SS
        d.rounded_rectangle(
            (ox + ow * SS - 4 * SS, y0, ox + ow * SS + KEY * SS, y0 + int(oh * length) * SS),
            radius=4 * SS,
            fill=(58, 60, 66, 255),
        )
    # Body: a light rim, then the dark bezel.
    d.rounded_rectangle((ox, 0, ox + ow * SS - 1, oh * SS - 1), radius=OUTER_RADIUS * SS, fill=(74, 77, 84, 255))
    d.rounded_rectangle(
        (ox + 4 * SS, 4 * SS, ox + ow * SS - 1 - 4 * SS, oh * SS - 1 - 4 * SS),
        radius=(OUTER_RADIUS - 4) * SS,
        fill=(14, 15, 18, 255),
    )
    canvas = hi.resize(canvas.size, Image.Resampling.LANCZOS)

    screen = screen.convert("RGBA")
    screen.putalpha(rounded_mask(screen.size, SCREEN_RADIUS))
    canvas.alpha_composite(screen, (KEY + BEZEL, BEZEL))

    # Punch-hole camera, centred in the status bar.
    hole = Image.new("RGBA", (PUNCH_RADIUS * 2 * SS, PUNCH_RADIUS * 2 * SS), (0, 0, 0, 0))
    ImageDraw.Draw(hole).ellipse((0, 0, hole.width - 1, hole.height - 1), fill=(8, 8, 10, 255))
    hole = hole.resize((PUNCH_RADIUS * 2, PUNCH_RADIUS * 2), Image.Resampling.LANCZOS)
    canvas.alpha_composite(hole, (KEY + BEZEL + sw // 2 - PUNCH_RADIUS, BEZEL + BAR // 2 - PUNCH_RADIUS))
    return canvas


def main(raw_dir: Path) -> None:
    site = ROOT / "site" / "screenshots"
    readme = ROOT / "assets" / "screenshots"
    site.mkdir(parents=True, exist_ok=True)
    readme.mkdir(parents=True, exist_ok=True)
    for raw in sorted(raw_dir.glob("*.png")):
        screen = clean_status_bar(Image.open(raw))
        screen.resize((540, 1200), Image.Resampling.LANCZOS).save(site / f"{raw.stem}.webp", quality=84, method=6)
        framed = frame(screen)
        framed = framed.resize((560, round(framed.height * 560 / framed.width)), Image.Resampling.LANCZOS)
        framed.save(readme / f"{raw.stem}.webp", quality=86, method=6)
        print(raw.stem)


if __name__ == "__main__":
    main(Path(sys.argv[1]))
