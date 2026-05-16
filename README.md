# shader_transitions

[![pub package](https://img.shields.io/pub/v/shader_transitions.svg)](https://pub.dev/packages/shader_transitions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.10-02569B?logo=flutter)](https://flutter.dev)

GPU-accelerated, shader-based page transitions for Flutter — diamond grid, circle iris, and linear wipe with eight sweep directions, optional cover color, and a configurable hold for cinematic fade-through transitions.

![hero](https://raw.githubusercontent.com/oppatrickk/flutter_shader_transitions/main/screenshots/hero.gif)

---

## Features

- **Three shader transitions** out of the box — `diamond` grid, `circle` iris, `wipe` linear.
- **Eight sweep directions** — four axis-aligned, four diagonals; all reach every corner regardless of direction.
- **Optional cover color** — replace the cross-fade through the outgoing page with a flat color (e.g. black) for a true cinematic fade.
- **Configurable cover hold** — pause on a full-cover frame between the cover-in and page-in wipes; pass a `Duration`.
- **Drop-in for Navigator, go_router, and auto_route** — `ShaderPageRoute` for Navigator, `ShaderTransitionBuilders.create(config)` for the others.
- **Preload-once design** — `FragmentProgram` compilation is a one-time `async` cost at app startup, not per-route.
- **Impeller-friendly** — uses `#version 460 core` + `flutter/runtime_effect.glsl`, the modern Flutter shader path.

## Showcase

| Diamond | Circle iris | Wipe |
|:---:|:---:|:---:|
| ![diamond](https://raw.githubusercontent.com/oppatrickk/flutter_shader_transitions/main/screenshots/diamond.gif) | ![circle](https://raw.githubusercontent.com/oppatrickk/flutter_shader_transitions/main/screenshots/circle.gif) | ![wipe](https://raw.githubusercontent.com/oppatrickk/flutter_shader_transitions/main/screenshots/wipe.gif) |

**Diamond** — a grid of diamond cells. A soft band sweeps along the chosen direction; within the band each cell fills from its center outward, so the edge reads as a shimmer of growing diamonds rather than a hard line. `cellSize` controls the grid density.

**Circle iris** — a circular reveal that grows from the screen center outward, feathered at the edge for a clean anti-aliased ring. Duration is the only knob.

**Wipe** — a straight feathered edge that travels across the screen in any of eight directions (four axis-aligned, four diagonal). `softness` sets the feather width; `0` gives a hard edge.

Cover color with a 600 ms hold ("fade to black, hold, reveal new scene") — the incoming page is hidden while a flat color wipes in, holds, then wipes back out to reveal the destination:

![cover-fade](https://raw.githubusercontent.com/oppatrickk/flutter_shader_transitions/main/screenshots/cover-fade.gif)

## Installation

```sh
flutter pub add shader_transitions
```

Or in `pubspec.yaml`:

```yaml
dependencies:
  shader_transitions: ^0.0.3
```

## Quick start

**1. Preload shaders at app startup.** Fragment program compilation is too slow to do on the first transition.

```dart
import 'package:flutter/material.dart';
import 'package:shader_transitions/shader_transitions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ShaderTransitions.preload();
  runApp(const MyApp());
}
```

**2. Push a route** with one of the convenience factories:

```dart
Navigator.of(context).push(
  ShaderTransitions.diamond(
    page: const NextPage(),
    direction: SweepDirection.topLeftToBottomRight,
  ),
);
```

**3. With go_router** — wrap your page in `CustomTransitionPage` and pass `ShaderTransitionBuilders.create`. **`opaque: false` is required** so the outgoing page shows through the masked area:

```dart
GoRoute(
  path: '/next',
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: const NextPage(),
    opaque: false, // ← required
    transitionDuration: const Duration(milliseconds: 800),
    transitionsBuilder: ShaderTransitionBuilders.create(
      const ShaderTransitionConfig.diamond(),
    ),
  ),
),
```

## Usage

### Diamond grid

A grid of diamond cells that fan out behind a sweeping band.

```dart
Navigator.of(context).push(
  ShaderTransitions.diamond(
    page: const NextPage(),
    direction: SweepDirection.leftToRight,
    size: 40.0, // diamond cell size in pixels (≥ 1)
    transitionDuration: const Duration(milliseconds: 800),
  ),
);
```

Or with the `ShaderTransitionConfig.diamond` constructor for full control:

```dart
const ShaderTransitionConfig.diamond(
  direction: SweepDirection.bottomLeftToTopRight,
  size: 28.0,
  transitionDuration: Duration(milliseconds: 900),
)
```

### Circle iris

Center-expanding iris wipe. `direction` and `size` don't apply.

```dart
Navigator.of(context).push(
  ShaderTransitions.circle(
    page: const NextPage(),
    transitionDuration: const Duration(milliseconds: 700),
  ),
);
```

### Wipe

Linear directional wipe with a feathered edge.

```dart
Navigator.of(context).push(
  ShaderTransitions.wipe(
    page: const NextPage(),
    direction: SweepDirection.rightToLeft,
    softness: 6.0, // feather width in px; 0 = hard edge
    transitionDuration: const Duration(milliseconds: 600),
  ),
);
```

### Cover color & hold (cinematic fade)

Set `color` to fill the un-revealed area with a flat color instead of letting the outgoing page show through. Set `coverDuration` to hold on the fully-covered frame between the wipe-in and wipe-out.

```dart
Navigator.of(context).push(
  ShaderPageRoute(
    page: const NextPage(),
    config: const ShaderTransitionConfig.wipe(
      direction: SweepDirection.leftToRight,
      transitionDuration: Duration(milliseconds: 800),
      color: Colors.black,
      coverDuration: Duration(milliseconds: 600), // hold on black for 600 ms
    ),
  ),
);
```

`coverDuration` is clamped internally to at most 75% of `transitionDuration` — each wipe always gets at least 12.5% of the timeline, so the cover hold can never squash the wipes into nothing.

Timeline with `transitionDuration: 800 ms` and `coverDuration: 600 ms`:

```
| cover wipes in | hold full cover     | page wipes in |
|     100 ms     |       600 ms        |    100 ms     |
```

### Configuration reference

| Field | Type | Default | Applies to |
|---|---|---|---|
| `type` | `TransitionType` | `diamond` | all |
| `direction` | `SweepDirection` | `topLeftToBottomRight` | `diamond`, `wipe` |
| `transitionDuration` | `Duration` | `800 ms` (diamond), `700 ms` (circle), `600 ms` (wipe) | all |
| `size` | `double` | `40.0` (diamond), `4.0` (wipe) | `diamond` (cell px, min 1), `wipe` (feather px) |
| `color` | `Color?` | `null` | all |
| `coverDuration` | `Duration` | `Duration.zero` | all (only effective when `color != null`) |

`SweepDirection` values: `topLeftToBottomRight`, `topRightToBottomLeft`, `bottomLeftToTopRight`, `bottomRightToTopLeft`, `leftToRight`, `rightToLeft`, `topToBottom`, `bottomToTop`.

## With go_router / auto_route

`ShaderTransitionBuilders.create(config)` returns a standard `RouteTransitionsBuilder`, so any router that accepts one works.

**go_router:**

```dart
GoRoute(
  path: '/next',
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: const NextPage(),
    opaque: false,
    transitionDuration: const Duration(milliseconds: 800),
    transitionsBuilder: ShaderTransitionBuilders.create(
      const ShaderTransitionConfig.diamond(direction: SweepDirection.leftToRight),
    ),
  ),
),
```

**auto_route:**

```dart
AutoRoute(
  page: NextRoute.page,
  customRouteBuilder: <T>(context, child, page) => PageRouteBuilder<T>(
    settings: page,
    opaque: false,
    pageBuilder: (_, __, ___) => child,
    transitionsBuilder: ShaderTransitionBuilders.create(
      const ShaderTransitionConfig.circle(),
    ),
  ),
),
```

> ⚠️ **`opaque: false` is required.** Without it, Flutter stops drawing the route below the transition, causing a black flash at the start. Every Navigator-side path in this package sets it for you.

## How it works

The core is `ShaderMask(blendMode: BlendMode.dstIn)` wrapping the incoming page — the shader writes alpha into `BlendMode.dstIn`, so where the shader's alpha is `0` the page is transparent and the outgoing route shows through, and where it's `1` the page is opaque.

When `color != null` the widget owns **two** `FragmentShader` instances and composes a three-phase Stack:

```
animation.value:  0 ─────── phase1End ───── phase2End ─────── 1
                  │             │              │              │
cover wipe in     │░░░░░░░░░░░░░│  full cover  │  full cover  │
                  │             │              │              │
page wipe out     │   hidden    │   hidden     │░░░░░░░░░░░░░░│
                  │             │              │              │
visible result:   outgoing →  cover     full cover     cover → new page
```

`phase1End` and `phase2End` are derived from `transitionDuration` and `coverDuration`. With `coverDuration: Duration.zero`, phases 1 and 3 abut directly — a continuous cross-fade through the color.

## Used by

- _Your project here — open a [PR](https://github.com/oppatrickk/flutter_shader_transitions/pulls) adding it!_

If you ship a published app or open-source project that uses `shader_transitions`, please send a PR adding it to this list. A short description and a link is enough.

## Contributing

Issues, PRs, and discussions all welcome.

- **Bug reports** → [open an issue](https://github.com/oppatrickk/flutter_shader_transitions/issues) with a minimum reproducible example and the platform you saw it on (Impeller vs Skia matters for shader behavior).
- **Feature requests** → an issue with the `enhancement` label is fine.
- **Pull requests** — fork, branch, keep commits small and focused, and make sure `flutter analyze` from both the repo root and `example/` stays clean.
- **Editing a `.frag` file** → run `flutter clean && flutter pub get` in `example/` before re-launching. Flutter caches compiled shader assets and hot reload won't pick up GLSL changes on its own.

Maintainer: [John Patrick Prieto](https://johnpatrickprieto.com)

## License

[MIT](LICENSE) © 2026 John Patrick Prieto

---

Built by [John Patrick Prieto](https://johnpatrickprieto.com) · [GitHub](https://github.com/oppatrickk)
