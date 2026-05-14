# shader_transitions — example gallery

A live demo of every transition in the [`shader_transitions`](https://pub.dev/packages/shader_transitions) package, with sliders and color swatches that let you configure each option before triggering the transition.

![gallery](https://raw.githubusercontent.com/oppatrickk/flutter_shader_transitions/main/screenshots/hero.gif)

## Run it

```sh
cd example
flutter pub get
flutter run
```

> If you've edited any `.frag` file in `../shaders/`, run `flutter clean && flutter pub get` first — Flutter caches compiled shader assets and hot reload won't pick up GLSL changes on its own.

## Layout

- **≥ 720 px wide** → two-column master/detail. Type list on the left, live editor on the right.
- **< 720 px wide** → tapping a type pushes an editor page; back button returns to the list.

The breakpoint lives in [`lib/screens/gallery_screen.dart`](lib/screens/gallery_screen.dart) as `wideLayoutBreakpoint`.

## What's interactive

In the editor pane (or page) you can tweak:

- **Direction** — full dropdown over all 8 `SweepDirection` values; hidden for the circle iris.
- **Transition duration** — slider, 100–2000 ms.
- **Size** — slider, 1–100 px. Cell size for diamond, feather width for wipe; hidden for circle.
- **Cover color** — None / Black / White / Indigo / Red swatches. Picking a color flips the transition into the three-phase cover flow.
- **Cover duration** — slider, 0–3000 ms. Appears once a cover color is set; this is the hold time between the cover wipe-in and the page wipe-out, clamped internally to ≤ 75% of `transitionDuration`.

The **Test transition** button at the bottom pushes a `DestinationScreen` with the current config so you see the full forward animation; the back arrow plays the reverse.

## Key files

- [`lib/main.dart`](lib/main.dart) — `ShaderTransitions.preload()` before `runApp`, then mounts `GalleryScreen`.
- [`lib/screens/gallery_screen.dart`](lib/screens/gallery_screen.dart) — type list, layout switching, the `TransitionEditor` widget that builds each `ShaderTransitionConfig`.
- [`lib/screens/destination_screen.dart`](lib/screens/destination_screen.dart) — the page each transition pushes into. Shows the live config and includes a "Push again" button so you can verify stacking.

## Screenshots

Each GIF in [`../screenshots/`](../screenshots/) is recorded straight from this gallery's gallery → destination flow.

---

Built by [John Patrick Prieto](https://johnpatrickprieto.com)
