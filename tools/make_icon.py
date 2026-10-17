#!/usr/bin/env python3
"""
Generate a 1024x1024 PNG App Icon using only the Python standard library.
Design: warm orange gradient background + a stylized white clock / camera lens.
Color type MUST be 2 (truecolor RGB, no alpha) or Xcode will reject.
"""
from __future__ import annotations
import math
import struct
import zlib
from pathlib import Path

SIZE = 1024
OUT = Path(__file__).resolve().parent.parent / "ShiGuang" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon-1024.png"


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def gradient(x: float, y: float) -> tuple[int, int, int]:
    # Diagonal warm gradient: top-left #FF8C4A -> bottom-right #FF5E8A
    t = (x + y) / 2.0
    r = lerp(0xFF, 0xFF, t)
    g = lerp(0x8C, 0x5E, t)
    b = lerp(0x4A, 0x8A, t)
    return int(r), int(g), int(b)


def draw_clock(pixel: list[list[list[int]]], cx: float, cy: float, radius: float) -> None:
    """White ring + hour/minute hands."""
    ring_thick = radius * 0.10
    hand_thick = radius * 0.09

    for py in range(SIZE):
        for px in range(SIZE):
            dx = px - cx
            dy = py - cy
            d = math.hypot(dx, dy)
            # ring
            if radius - ring_thick <= d <= radius:
                # anti-alias edge
                aa = min(1.0, (radius - d) / 2.0, (d - (radius - ring_thick)) / 2.0)
                aa = max(0.0, aa)
                blend_white(pixel, px, py, aa)
            # hour hand: pointing to ~10 o'clock direction
            # minute hand: pointing to ~2 o'clock direction
            for angle_deg, length_ratio in ((300, 0.55), (60, 0.85)):
                ang = math.radians(angle_deg - 90)  # 12 o'clock = -90
                ux, uy = math.cos(ang), math.sin(ang)
                # project (dx,dy) onto (ux,uy)
                proj = dx * ux + dy * uy
                if 0 <= proj <= radius * length_ratio:
                    # perpendicular distance
                    perp = abs(dx * uy - dy * ux)
                    if perp <= hand_thick / 2:
                        aa = min(1.0, (hand_thick / 2 - perp) / 1.5)
                        aa = max(0.0, aa)
                        blend_white(pixel, px, py, aa)
            # center dot
            if d <= radius * 0.10:
                blend_white(pixel, px, py, 1.0)


def blend_white(pixel: list[list[list[int]]], x: int, y: int, alpha: float) -> None:
    if alpha <= 0:
        return
    cur = pixel[y][x]
    pixel[y][x] = [
        int(lerp(cur[0], 255, alpha)),
        int(lerp(cur[1], 255, alpha)),
        int(lerp(cur[2], 255, alpha)),
    ]


def write_png(path: Path, pixel: list[list[list[int]]]) -> None:
    """Write RGB PNG (color type 2, no alpha)."""
    raw = bytearray()
    for row in pixel:
        raw.append(0)  # filter type 0
        for r, g, b in row:
            raw.extend((r, g, b))

    def chunk(tag: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)  # color_type=2
    idat = zlib.compress(bytes(raw), level=9)

    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", idat)
        + chunk(b"IEND", b"")
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def main() -> None:
    print(f"Generating {SIZE}x{SIZE} icon -> {OUT}")
    pixel: list[list[list[int]]] = []
    for y in range(SIZE):
        row: list[list[int]] = []
        for x in range(SIZE):
            r, g, b = gradient(x / SIZE, y / SIZE)
            row.append([r, g, b])
        pixel.append(row)

    draw_clock(pixel, SIZE / 2, SIZE / 2, SIZE * 0.30)
    write_png(OUT, pixel)
    # Verify
    data = OUT.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    ihdr_len = struct.unpack(">I", data[8:12])[0]
    assert data[12:16] == b"IHDR"
    w, h, bit_depth, color_type = struct.unpack(">IIBB", data[16:26])
    assert (w, h, bit_depth, color_type) == (SIZE, SIZE, 8, 2), (w, h, bit_depth, color_type)
    print(f"OK: {OUT} ({len(data)} bytes, {w}x{h}, color_type={color_type})")


if __name__ == "__main__":
    main()
