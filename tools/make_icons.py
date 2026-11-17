#!/usr/bin/env python3
"""Draws the IGCSE Chemistry MCQs icon (a conical flask) and the Play feature graphic.

Writes, from one geometry in the 108-unit adaptive-icon viewport:
  android/app/src/main/res/drawable/ic_launcher_foreground.xml   adaptive foreground
  android/app/src/main/res/values/ic_launcher_background.xml     adaptive background
  android/app/src/main/res/mipmap-*/ic_launcher.png              legacy launcher icons
  store-assets/icon-512.png                                      Play icon
  store-assets/feature-graphic.png                               Play feature graphic 1024x500

Run from the repo root: python3 tools/make_icons.py
"""
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
STORE = ROOT / "store-assets"

TEAL = "#0F766E"
TEAL_DARK = "#134E4A"
WHITE = "#FFFFFF"
YELLOW = "#FFC94D"
STROKE = 3.5  # in viewport units, as the physics atom

# Flask outline, open at the top: neck, then the conical body with rounded bottom corners.
OUTLINE = "M47,30 L47,46 L31.5,75 Q29.8,80 35,80 L73,80 Q78.2,80 76.5,75 L61,46 L61,30"
RIM = "M42.5,30 L65.5,30"
LIQUID = "M39.4,62 L68.6,62 L74.2,73.5 Q76,77.6 71.8,77.6 L36.2,77.6 Q32,77.6 33.8,73.5 Z"
BUBBLES = [(50, 55.5, 2.2), (56.5, 50.5, 1.6)]

FONT_BOLD = "/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf"
FONT_REG = "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf"


def _points(path):
    """Samples an absolute M/L/Q/Z path into a list of (x, y) points."""
    toks = re.findall(r"[MLQZ]|-?\d*\.?\d+", path)
    pts, i, cmd = [], 0, None
    while i < len(toks):
        if toks[i] in "MLQZ":
            cmd = toks[i]
            i += 1
            if cmd == "Z":
                pts.append(pts[0])
                continue
        if cmd in "ML":
            pts.append((float(toks[i]), float(toks[i + 1])))
            i += 2
        elif cmd == "Q":
            (x0, y0) = pts[-1]
            cx, cy, x1, y1 = map(float, toks[i : i + 4])
            for k in range(1, 13):
                t = k / 12
                pts.append(
                    (
                        (1 - t) ** 2 * x0 + 2 * (1 - t) * t * cx + t * t * x1,
                        (1 - t) ** 2 * y0 + 2 * (1 - t) * t * cy + t * t * y1,
                    )
                )
            i += 4
    return pts


def _draw_flask(d, scale, ox, oy):
    """Draws the flask with viewport point (54, 54) at (ox, oy), `scale` px per unit."""

    def tr(p):
        return [(ox + (x - 54) * scale, oy + (y - 54) * scale) for x, y in p]

    w = round(STROKE * scale)
    d.polygon(tr(_points(LIQUID)), fill=YELLOW)
    for cx, cy, r in BUBBLES:
        (x, y), = tr([(cx, cy)])
        d.ellipse([x - r * scale, y - r * scale, x + r * scale, y + r * scale], fill=YELLOW)
    for path in (OUTLINE, RIM):
        pts = tr(_points(path))
        d.line(pts, fill=WHITE, width=w, joint="curve")
        for x, y in (pts[0], pts[-1]):  # round caps
            d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=WHITE)


def square_icon(size, scale_units=7.5 / 512):
    """Full-bleed teal square with the flask, drawn 4x and downsampled for smooth edges."""
    big = size * 4
    img = Image.new("RGB", (big, big), TEAL)
    _draw_flask(ImageDraw.Draw(img), big * scale_units, big / 2, big / 2)
    return img.resize((size, size), Image.LANCZOS)


def feature_graphic():
    w, h, k = 1024, 500, 2
    img = Image.new("RGB", (w * k, h * k))
    d = ImageDraw.Draw(img)
    top, bot = Image.new("RGB", (1, 1), TEAL).getpixel((0, 0)), Image.new(
        "RGB", (1, 1), TEAL_DARK
    ).getpixel((0, 0))
    for y in range(h * k):
        t = y / (h * k)
        d.line([(0, y), (w * k, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(top, bot)))
    _draw_flask(d, 6.2 * k, 205 * k, 250 * k)
    bold = lambda s: ImageFont.truetype(FONT_BOLD, s * k)
    reg = lambda s: ImageFont.truetype(FONT_REG, s * k)
    x = 400 * k
    d.text((x, 120 * k), "IGCSE Chemistry", font=bold(62), fill=WHITE)
    d.text((x, 195 * k), "MCQs", font=bold(62), fill=YELLOW)
    d.text((x, 292 * k), "1,440 exam-style questions", font=bold(30), fill=WHITE)
    d.text((x, 338 * k), "50 timed mock papers · every answer explained", font=reg(24), fill="#E6F4F1")
    d.text((x, 376 * k), "Core & Extended · offline · no account", font=reg(24), fill="#E6F4F1")
    return img.resize((w, h), Image.LANCZOS)


def vector_xml():
    bubbles = "\n".join(
        f'    <path android:pathData="M{cx - r:g},{cy:g} a{r:g},{r:g} 0 1,0 {2 * r:g},0 '
        f'a{r:g},{r:g} 0 1,0 {-2 * r:g},0" android:fillColor="{YELLOW}" />'
        for cx, cy, r in BUBBLES
    )
    stroke = (
        f'android:strokeColor="{WHITE}" android:strokeWidth="{STROKE}" '
        'android:strokeLineCap="round" android:strokeLineJoin="round" '
        'android:fillColor="#00000000"'
    )
    return f"""<?xml version="1.0" encoding="utf-8"?>
<!-- Conical flask with liquid and two bubbles, inside the adaptive-icon safe zone.
     Generated by tools/make_icons.py; edit the geometry there. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:pathData="{LIQUID}" android:fillColor="{YELLOW}" />
{bubbles}
    <path android:pathData="{OUTLINE}"
        {stroke} />
    <path android:pathData="{RIM}"
        {stroke} />
</vector>
"""


def main():
    (RES / "drawable/ic_launcher_foreground.xml").write_text(vector_xml())
    (RES / "values/ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
        f'    <color name="ic_launcher_background">{TEAL}</color>\n</resources>\n'
    )
    for folder, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        square_icon(px).save(RES / f"mipmap-{folder}/ic_launcher.png", optimize=True)
    STORE.mkdir(exist_ok=True)
    square_icon(512).save(STORE / "icon-512.png", optimize=True)
    feature_graphic().save(STORE / "feature-graphic.png", optimize=True)
    print("icons written")


if __name__ == "__main__":
    main()
