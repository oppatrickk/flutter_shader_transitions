#!/usr/bin/env python3
"""Generates the shader_transitions logo and app icons.

The mark is a diamond tiled with smaller diamonds that grow from left to
right until they merge: a frozen frame of DiamondTransition's sweep.

Needs Python 3, Pillow, and Inkscape on PATH (Inkscape renders the PNGs).

    python doc/brand/generate.py              # SVGs + PNGs in doc/brand/
    python doc/brand/generate.py --web DIR    # also a Flutter web/ icon set in DIR
    python doc/brand/generate.py --splash     # print the splash-screen <svg> markup
"""
import argparse
import shutil
import subprocess
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent

# BACKGROUND is the example app's dark surface
# (ColorScheme.fromSeed(Color(0xFF6750A4), brightness: dark)). The gradient
# runs from the gallery's Diamond accent to cyan.
BACKGROUND = '#141218'
VIOLET = '#7C4DFF'
CYAN = '#00E5FF'


def cell_scale(column, n):
    """Cells grow from the left tip; from the middle column on they're full and
    merge. Partial cells stop at 0.68 so the gaps never thin into hairlines."""
    if column >= n - 1:
        return 1.0
    first, last = 0.24, 0.68
    return first + (last - first) * column / max(n - 2, 1)


def cells(n, cx, cy, r):
    """Yields (column, center, corners) for an n×n lattice of diamond cells
    filling the diamond of radius r at (cx, cy). Columns run 0..2n-2, left to right."""
    def point(u, v):
        return cx - r + (u + v) * r / n, cy + (v - u) * r / n

    for i in range(n):
        for j in range(n):
            corners = [point(i, j), point(i + 1, j), point(i + 1, j + 1), point(i, j + 1)]
            yield i + j, point(i + 0.5, j + 0.5), corners


def path_data(points):
    return 'M' + ' L'.join(f'{x:.2f},{y:.2f}' for x, y in points) + ' Z'


def mark_path(n, cx, cy, r):
    """One <path> for the whole mark, so full cells merge without seams."""
    parts = []
    for column, (ox, oy), corners in cells(n, cx, cy, r):
        s = cell_scale(column, n)
        parts.append(path_data([(ox + s * (x - ox), oy + s * (y - oy)) for x, y in corners]))
    return ' '.join(parts)


def gradient(gid, cx, cy, r):
    return (f'<linearGradient id="{gid}" gradientUnits="userSpaceOnUse" '
            f'x1="{cx - r:.2f}" y1="{cy - r:.2f}" x2="{cx + r:.2f}" y2="{cy + r:.2f}">'
            f'<stop offset="0" stop-color="{VIOLET}"/><stop offset="1" stop-color="{CYAN}"/>'
            '</linearGradient>')


def svg(size, defs, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" '
            f'viewBox="0 0 {size} {size}"><defs>{defs}</defs>{body}</svg>\n')


def logo_svg(n, size):
    """The mark alone on a transparent background."""
    c, r = size / 2, size * 0.49
    return svg(size, gradient('g', c, c, r), f'<path fill="url(#g)" d="{mark_path(n, c, c, r)}"/>')


def icon_svg(size, rounded):
    """The mark on the dark background. Full-bleed (rounded=False) for maskable,
    adaptive, and iOS icons; the mark stays inside their safe zones."""
    r = size * 0.30
    # The solid half carries the weight, so nudge the mark left to look centered.
    cx, cy = size / 2 - size * 0.03, size / 2
    corner = f' rx="{size * 0.22:.2f}"' if rounded else ''
    glow = (f'<radialGradient id="glow" gradientUnits="userSpaceOnUse" cx="{cx + r * 0.3:.2f}" '
            f'cy="{cy:.2f}" r="{size * 0.45:.2f}"><stop offset="0" stop-color="{VIOLET}" '
            f'stop-opacity="0.22"/><stop offset="1" stop-color="{VIOLET}" stop-opacity="0"/>'
            '</radialGradient>')
    body = (f'<rect width="{size}" height="{size}"{corner} fill="{BACKGROUND}"/>'
            f'<rect width="{size}" height="{size}"{corner} fill="url(#glow)"/>'
            f'<path fill="url(#g)" d="{mark_path(5, cx, cy, r)}"/>')
    return svg(size, gradient('g', cx, cy, r) + glow, body)


def splash_svg():
    """Inline <svg> for web/index.html: each cell is its own path so CSS can
    animate it; --k is the column (drives the sweep delay), --s the static scale."""
    size, n = 100, 5
    c, r = size / 2, size * 0.49

    def scale(column):
        # Separate paths leave anti-aliasing seams between full cells; overlap them a hair.
        s = cell_scale(column, n)
        return 1.02 if s >= 1.0 else s

    paths = '\n'.join(
        f'    <path class="c" style="--k:{column};--s:{scale(column):.3f}" d="{path_data(corners)}"/>'
        for column, _, corners in cells(n, c, c, r))
    return (f'<svg viewBox="0 0 {size} {size}" aria-hidden="true">\n'
            f'  <defs>{gradient("st-g", c, c, r)}</defs>\n'
            f'  <g fill="url(#st-g)">\n{paths}\n  </g>\n</svg>')


def export_png(svg_path, png_path, size, opaque=False):
    inkscape = shutil.which('inkscape')
    if not inkscape:
        raise SystemExit('Inkscape not found on PATH; it is needed to render PNGs.')
    png_path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([inkscape, '--export-type=png', f'--export-filename={png_path}',
                    f'--export-width={size}', f'--export-height={size}', str(svg_path)],
                   check=True, capture_output=True)
    image = Image.open(png_path)
    # App stores and iOS reject icons with an alpha channel.
    (image.convert('RGB') if opaque else image.convert('RGBA')).save(png_path, optimize=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    parser.add_argument('--web', type=Path, help='Flutter web/ directory to write icons into')
    parser.add_argument('--splash', action='store_true', help='print the splash <svg> markup and exit')
    args = parser.parse_args()

    if args.splash:
        print(splash_svg())
        return

    sources = {
        'logo.svg': logo_svg(5, 512),
        'logo-small.svg': logo_svg(3, 64),  # fewer, larger cells stay legible at favicon size
        'icon.svg': icon_svg(1024, rounded=False),
        'icon-rounded.svg': icon_svg(1024, rounded=True),
    }
    for name, text in sources.items():
        (HERE / name).write_text(text, encoding='utf-8')
    export_png(HERE / 'logo.svg', HERE / 'logo-512.png', 512)
    export_png(HERE / 'icon.svg', HERE / 'icon-1024.png', 1024, opaque=True)

    if args.web:
        web = args.web
        shutil.copyfile(HERE / 'logo-small.svg', web / 'favicon.svg')
        export_png(HERE / 'logo-small.svg', web / 'favicon.png', 32)
        for size in (192, 512):
            export_png(HERE / 'icon-rounded.svg', web / 'icons' / f'Icon-{size}.png', size)
            export_png(HERE / 'icon.svg', web / 'icons' / f'Icon-maskable-{size}.png', size, opaque=True)
        export_png(HERE / 'icon.svg', web / 'icons' / 'apple-touch-icon.png', 180, opaque=True)


if __name__ == '__main__':
    main()
