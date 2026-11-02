"""Generate the GeauxPark app icon for Android and web.

The icon is a gold map pin holding a purple "P" on LSU purple. Everything is
drawn with geometry (no fonts), so the output is the same on every machine.

    python tool/generate_app_icon.py

Writes:
  android/app/src/main/res/mipmap-*/ic_launcher.png          legacy icon
  android/app/src/main/res/mipmap-*/ic_launcher_foreground.png  adaptive layer
  android/app/src/main/res/mipmap-*/ic_launcher_monochrome.png  themed icon
  web/icons/*.png, web/favicon.png
  docs/design/app_icon.png                                    1024px preview
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android" / "app" / "src" / "main" / "res"

PURPLE = (0x46, 0x1D, 0x7C, 255)
PURPLE_DARK = (0x30, 0x12, 0x58, 255)
GOLD = (0xFD, 0xD0, 0x23, 255)
WHITE = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)

# Adaptive icons are drawn on a 108-unit canvas. Launchers show the middle
# 72 units and guarantee a 66-unit circle is never clipped.
CANVAS = 108.0
SCALE = 16  # supersampling factor; the master is 1728px
PIN_RADIUS = 21.0

DENSITIES = {
    "mdpi": 1.0,
    "hdpi": 1.5,
    "xhdpi": 2.0,
    "xxhdpi": 3.0,
    "xxxhdpi": 4.0,
}


def _pin_geometry(r: float) -> tuple[float, float, float]:
    """Return (cx, cy, tip_y) so the pin is centered on the canvas."""
    tip_distance = 1.75 * r
    height = r + tip_distance
    cx = CANVAS / 2
    top = (CANVAS - height) / 2
    cy = top + r
    return cx, cy, cy + tip_distance


def _draw_pin(draw: ImageDraw.ImageDraw, pin: tuple, p_color: tuple,
              shadow: tuple | None) -> None:
    s = SCALE
    r = PIN_RADIUS
    cx, cy, tip_y = _pin_geometry(r)

    if shadow is not None:
        sw, sh = 0.85 * r, 0.2 * r
        draw.ellipse(
            [(cx - sw / 2) * s, (tip_y - sh / 2) * s,
             (cx + sw / 2) * s, (tip_y + sh / 2) * s],
            fill=shadow,
        )

    # Pin head plus the two tangent lines that meet at the tip.
    theta = math.acos(r / (tip_y - cy))
    left = (cx - r * math.sin(theta), cy + r * math.cos(theta))
    right = (cx + r * math.sin(theta), cy + r * math.cos(theta))
    draw.polygon(
        [(cx * s, tip_y * s), (left[0] * s, left[1] * s),
         (right[0] * s, right[1] * s)],
        fill=pin,
    )
    draw.ellipse([(cx - r) * s, (cy - r) * s, (cx + r) * s, (cy + r) * s],
                 fill=pin)

    # The "P": a stem plus a D-shaped bowl with its counter cut out.
    stroke = 0.25 * r
    x0 = cx - 0.42 * r
    top = cy - 0.6 * r
    bowl_bottom = cy + 0.2 * r
    stem_bottom = cy + 0.62 * r
    bowl_r = (bowl_bottom - top) / 2
    xc = cx + 0.07 * r

    def d_shape(inset: float, color: tuple) -> None:
        rr = bowl_r - inset
        draw.rectangle(
            [(x0 + inset) * s, (top + inset) * s, xc * s,
             (bowl_bottom - inset) * s],
            fill=color,
        )
        draw.ellipse(
            [(xc - rr) * s, (top + inset) * s, (xc + rr) * s,
             (bowl_bottom - inset) * s],
            fill=color,
        )

    d_shape(0, p_color)
    d_shape(stroke, pin)
    draw.rectangle([x0 * s, top * s, (x0 + stroke) * s, stem_bottom * s],
                   fill=p_color)


def foreground() -> Image.Image:
    size = int(CANVAS * SCALE)
    image = Image.new("RGBA", (size, size), CLEAR)
    _draw_pin(ImageDraw.Draw(image), GOLD, PURPLE, PURPLE_DARK)
    return image


def monochrome() -> Image.Image:
    """White pin with the P cut out; launchers tint it for themed icons."""
    size = int(CANVAS * SCALE)
    image = Image.new("RGBA", (size, size), CLEAR)
    _draw_pin(ImageDraw.Draw(image), WHITE, CLEAR, None)
    return image


def composite() -> Image.Image:
    size = int(CANVAS * SCALE)
    image = Image.new("RGBA", (size, size), PURPLE)
    image.alpha_composite(foreground())
    return image


def crop_center(image: Image.Image, units: float) -> Image.Image:
    size = image.width
    px = units / CANVAS * size
    offset = (size - px) / 2
    return image.crop((round(offset), round(offset), round(offset + px),
                       round(offset + px)))


def rounded(image: Image.Image, radius_ratio: float = 0.22) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, image.width - 1, image.height - 1],
        radius=image.width * radius_ratio,
        fill=255,
    )
    out = Image.new("RGBA", image.size, CLEAR)
    out.paste(image, (0, 0), mask)
    return out


def save(image: Image.Image, path: Path, px: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((px, px), Image.LANCZOS).save(path, optimize=True)
    print(f"wrote {path.relative_to(ROOT)} ({px}px)")


def main() -> None:
    fg = foreground()
    mono = monochrome()
    legacy = rounded(crop_center(composite(), 72))
    full_bleed = crop_center(composite(), 72)
    maskable = crop_center(composite(), 84)

    for name, factor in DENSITIES.items():
        folder = RES / f"mipmap-{name}"
        save(legacy, folder / "ic_launcher.png", round(48 * factor))
        save(fg, folder / "ic_launcher_foreground.png", round(108 * factor))
        save(mono, folder / "ic_launcher_monochrome.png", round(108 * factor))

    web = ROOT / "web"
    save(legacy, web / "icons" / "Icon-192.png", 192)
    save(legacy, web / "icons" / "Icon-512.png", 512)
    save(maskable, web / "icons" / "Icon-maskable-192.png", 192)
    save(maskable, web / "icons" / "Icon-maskable-512.png", 512)
    save(full_bleed, web / "favicon.png", 32)

    save(legacy, ROOT / "docs" / "design" / "app_icon.png", 1024)


if __name__ == "__main__":
    main()
