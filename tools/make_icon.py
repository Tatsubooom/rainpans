#!/usr/bin/env python3
"""Draws the 32x32 pixel icon (a can catching a drop under a lamp glow) and
writes it upscaled 4x to assets/icon.png."""
from PIL import Image
P = {
    ".": (0, 0, 0, 0), "k": (7, 9, 14, 255), "n": (19, 26, 37, 255), "m": (35, 46, 63, 255),
    "f": (81, 96, 118, 255), "r": (143, 162, 187, 255), "h": (195, 209, 227, 255),
    "1": (58, 63, 72, 255), "2": (91, 98, 109, 255), "3": (140, 148, 160, 255), "4": (185, 192, 201, 255),
    "5": (228, 232, 236, 255), "a": (143, 58, 42, 255), "b": (196, 104, 62, 255),
    "l": (255, 214, 138, 255), "L": (242, 166, 90, 255), "d": (209, 116, 58, 255),
}
ROWS = [
    "kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk",
    "knnnnnnnnnnnnnnnnnnnnnnnnnnnnnnk",
    "knnnnnnnnnnnnnnhnnnnnnnnnnnnnnnk",
    "knnnnnnnnnnnnnnrnnnnnnnnnnnnnnnk",
    "knnnnnnnnnnnnnnrnnnnnnnnnnnnnnnk",
    "knnnnnnnnnnnnnnnnnnnnnnnnnnnnnnk",
    "knnnnnnnnnnnnnhnnnnnnnnnnnnnnnnk",
    "knnnnnnnnnnnnnrnnnnnnnnnnnnnnnnk",
    "knnnmnnnnnnnnnnnnnnnnnnnnnnnmnnk",
    "knnnnnnnnnnnnnnnnnnnnnnnnnnnnnnk",
    "knnnnnnnnnnnnnnhnnnnnnnnnnnnnnnk",
    "knnnnnnnnnnnnnhhhnnnnnnnnnnnnnnk",
    "knnnnnnnnnnnnnhrhnnnnnnnnnnnnnnk",
    "knnnnnnnnnnnnnnhnnnnnnnnnnnnnnnk",
    "knnnnnnnnnnnnnnnnnnnnnnnnnnnnnnk",
    "knnnnnnnnnnkkkkkkkkknnnnnnnnnnnk",
    "knnnnnnnnnk5544443321knnnnnnnnnk",
    "knnnnnnnnnk4mmmmmmmm2knnnnnnnnnk",
    "knnnnnnnnnk5544443321knnnnnnnnnk",
    "knnnnnnnnnk4aaaaaaaa2knnnnnnnnnk",
    "knnnnnnnnnk4abbbbbba2knnnnnnnnnk",
    "knnnnnnnnnk4abaaaaba2knnnnnnnnnk",
    "knnnnnnnnnk4abbbbbba2knnnnnnnnnk",
    "knnnnnnnnnk4aaaaaaaa2knnnnnnnnnk",
    "knnnnnnnnnk4443333211knnnnnnnnnk",
    "knnnnnnnnnk4443333211knnnnnnnnnk",
    "knnnnnnnnnk5543333211knnnnnnnnnk",
    "knnnnnnnnnnkkkkkkkkkfffnnnnnnnnk",
    "knnnnnnfffmmmmmmmmmmmmmmffnnnnnk",
    "knnnnnnnnmmmmmmmmmmmmmmmmnnnnnnk",
    "knnnnnnnnnnnnnnnnnnnnnnnnnnnnnnk",
    "kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk",
]
img = Image.new("RGBA", (32, 32))
for y, row in enumerate(ROWS):
    for x, ch in enumerate(row):
        img.putpixel((x, y), P[ch])
img.resize((128, 128), Image.NEAREST).save(__import__("os").path.join(__import__("os").path.dirname(__file__), "..", "assets", "icon.png"))
