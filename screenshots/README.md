# Screenshots

Drop the following GIFs here once recorded. They're referenced from the package and example READMEs via raw.githubusercontent.com URLs so they render on pub.dev:

| File | What to capture |
|---|---|
| `hero.gif`       | 5–8 s reel cycling diamond → circle → wipe → cover variant. Used in both READMEs as the hero image. |
| `diamond.gif`    | Diamond grid, `topLeftToBottomRight`, `transitionDuration: 800ms`, `size: 40`. |
| `circle.gif`     | Circle iris, `transitionDuration: 700ms`. |
| `wipe.gif`       | Linear wipe, `leftToRight`, `transitionDuration: 600ms`, `softness: 6`. |
| `cover-fade.gif` | Wipe `leftToRight` with `color: Colors.black, coverDuration: Duration(milliseconds: 600)`. Shows the three-phase cover flow. |

## Recording tips

- **Aspect / resolution**: 540×960 (phone portrait) or similar. Both READMEs render fine at that size.
- **Frame rate**: 24 fps is plenty for these wipes.
- **File size**: aim for ≤ 2 MB each so the README pane on pub.dev loads quickly.
- **Source**: run `example/` and capture the gallery → destination flow with the matching config in the editor. The example is laid out specifically so each capture is one tap.

Once a file is committed, the links in the root `README.md` and `example/README.md` resolve automatically (no path edits needed).
