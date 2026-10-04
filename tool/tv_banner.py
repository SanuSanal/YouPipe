"""Draws the Android TV / Fire TV launcher banner (docs/release.md).

    python tool/tv_banner.py

Writes android/app/src/main/res/drawable-xhdpi/tv_banner.png: 320x180, the logo mark and the "YouPipe" wordmark
on YouTube's dark background, as TV launchers show it in their app rows.
"""

import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT = Path(shutil.which("flutter")).resolve().parent / "cache" / "artifacts" / "material_fonts" / "roboto-bold.ttf"
LOGO = ROOT / "assets" / "branding" / "logo_1024.png"
OUT = ROOT / "android" / "app" / "src" / "main" / "res" / "drawable-xhdpi" / "tv_banner.png"

W, H = 320, 180
SS = 4  # supersampling
BACKGROUND = (15, 15, 15, 255)
TEXT = (241, 241, 241, 255)


def main() -> None:
    canvas = Image.new("RGBA", (W * SS, H * SS), BACKGROUND)
    font = ImageFont.truetype(str(FONT), 46 * SS)
    text = "YouPipe"
    text_w = ImageDraw.Draw(canvas).textlength(text, font=font)

    logo_h = 64 * SS
    logo = Image.open(LOGO).convert("RGBA")
    # The mark is a rounded rectangle; trim the transparent margin so it lines up with the text.
    logo = logo.crop(logo.getbbox())
    logo = logo.resize((round(logo.width * logo_h / logo.height), logo_h), Image.Resampling.LANCZOS)

    gap = 14 * SS
    total = logo.width + gap + text_w
    x = round((W * SS - total) / 2)
    y = (H * SS - logo_h) // 2
    canvas.alpha_composite(logo, (x, y))
    ImageDraw.Draw(canvas).text(
        (x + logo.width + gap, H * SS // 2), text, font=font, fill=TEXT, anchor="lm"
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.resize((W, H), Image.Resampling.LANCZOS).save(OUT)
    print(OUT)


if __name__ == "__main__":
    main()
