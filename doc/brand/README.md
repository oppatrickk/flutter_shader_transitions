# Brand assets

The shader_transitions mark: a diamond tiled with smaller diamonds that grow
from left to right until they merge, a frozen frame of `DiamondTransition`.

| File | Use |
|---|---|
| `logo.svg`, `logo-512.png` | The mark on a transparent background (README, docs, slides) |
| `logo-small.svg` | Fewer, larger cells that stay legible at 16–48 px (favicons) |
| `icon.svg`, `icon-1024.png` | App icon, square and opaque: launcher-icon tools, app stores, maskable and adaptive icons |
| `icon-rounded.svg` | App icon with rounded corners and a transparent outside (PWA "any" icons) |

Colors: background `#141218` (the example app's dark surface), gradient
`#7C4DFF` → `#00E5FF`.

## Regenerate

Every file here comes from `generate.py`, which needs Python 3, Pillow, and
Inkscape on PATH. Change the design in the script, not in the SVGs.

```sh
python doc/brand/generate.py                    # the files in this folder
python doc/brand/generate.py --web path/to/web  # favicon and PWA/iOS icons for a Flutter web/ folder
python doc/brand/generate.py --splash           # <svg> markup for the web splash screen
```
