# shader_transitions

[![pub package](https://img.shields.io/pub/v/shader_transitions.svg)](https://pub.dev/packages/shader_transitions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.10-02569B?logo=flutter)](https://flutter.dev)

GPU-accelerated, shader-based page transitions for Flutter — diamond grid, circle iris, and linear wipe with eight sweep directions, optional cover color, and a configurable hold for cinematic fade-through transitions.

![hero](https://raw.githubusercontent.com/oppatrickk/flutter_shader_transitions/main/screenshots/hero.gif)

---

## Features

- **Eight shader transitions** — `DiamondTransition`, `CircleTransition`, `WipeTransition`, `ClockTransition`, `PolygonTransition`, `DissolveTransition`, `FadeShaderTransition`, `BarsTransition`. One sealed `ShaderTransition` API.
- **Shared, clear parameter vocabulary** — `origin`, `direction`, `feather`/`softness`, `rotation`, `invert`, `sectors`/`sides`/`count`; the same name means the same thing everywhere.
- **Eight sweep directions** — four axis-aligned, four diagonals; all reach every corner.
- **Optional cover color + hold** — `TransitionCover(color:, hold:)` for a cinematic fade-through (cover wipe-in → hold → page wipe-out).
- **Routes, widgets, and app-wide** — `ShaderPageRoute` (Navigator), `ShaderTransitionBuilders.create` (go_router/auto_route), `ShaderPageTransitionsBuilder` (`pageTransitionsTheme`), `ShaderTransitionSwitcher` (between widgets).
- **Lifecycle callbacks** — `onStart` / `onComplete` / `onProgress`; play your own sound (no audio dependency bundled).
- **Preload-once design** — `FragmentProgram` compilation is a one-time `async` cost at app startup, not per-route.
- **Impeller-friendly** — `#version 460 core` + `flutter/runtime_effect.glsl`, the modern Flutter shader path.

## Showcase

| Diamond | Circle iris | Wipe |
|:---:|:---:|:---:|
| ![diamond](https://raw.githubusercontent.com/oppatrickk/flutter_shader_transitions/main/screenshots/diamond.gif) | ![circle](https://raw.githubusercontent.com/oppatrickk/flutter_shader_transitions/main/screenshots/circle.gif) | ![wipe](https://raw.githubusercontent.com/oppatrickk/flutter_shader_transitions/main/screenshots/wipe.gif) |

**Diamond** — a grid of diamond cells. A soft band sweeps along the chosen direction; within the band each cell fills from its center outward, so the edge reads as a shimmer of growing diamonds rather than a hard line. `cellSize` controls the grid density.

**Circle iris** — a circular reveal that grows from the screen center outward, feathered at the edge for a clean anti-aliased ring. Duration is the only knob.

**Wipe** — a straight feathered edge that travels across the screen in any of eight directions (four axis-aligned, four diagonal). `softness` sets the feather width; `0` gives a hard edge. `rotation` tilts the edge.

**Clock** — a radial hand sweeping around `origin`; `sectors` fans it into a multi-blade pinwheel, `invert` reverses the direction.

**Polygon** — a regular n-gon iris from `origin`. `sides: 3` is a triangle; high counts approximate `CircleTransition`. `invert` contracts instead of expands.

**Dissolve** — a pseudo-random per-pixel grain that fills in as progress rises; `grain` controls how soft the speckle fades.

**Fade** — a uniform cross-fade, but routed through the same pipeline so it still composes with `cover` and the lifecycle callbacks.

**Bars** — a venetian blind: `count` parallel bars along `direction` wipe in parallel.

Cover color with a 600 ms hold ("fade to black, hold, reveal new scene") — the incoming page is hidden while a flat color wipes in, holds, then wipes back out to reveal the destination:

![cover-fade](https://raw.githubusercontent.com/oppatrickk/flutter_shader_transitions/main/screenshots/cover-fade.gif)

## Installation

```sh
flutter pub add shader_transitions
```

Or in `pubspec.yaml`:

```yaml
dependencies:
  shader_transitions: ^0.1.0
```

> **Upgrading from 0.0.x?** The config API changed — see [Migrating from 0.0.x](#migrating-from-00x).

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
      const DiamondTransition(),
    ),
  ),
),
```

## Usage

Every transition is a sealed `ShaderTransition`: `DiamondTransition`,
`CircleTransition`, or `WipeTransition`. All share `duration`, an optional
`cover`, and an `invert` flag.

### Diamond grid

A grid of diamond cells that fan out behind a sweeping band.

```dart
Navigator.of(context).push(
  ShaderTransitions.diamond(
    page: const NextPage(),
    direction: SweepDirection.leftToRight,
    cellSize: 40.0, // diamond cell size in px (≥ 1)
    duration: const Duration(milliseconds: 800),
  ),
);
```

Or build the transition directly for full control:

```dart
const DiamondTransition(
  direction: SweepDirection.bottomLeftToTopRight,
  cellSize: 28.0,
  duration: Duration(milliseconds: 900),
)
```

### Circle iris

Circular iris reveal. `origin` sets where it emanates from; `invert` makes
it contract instead of expand.

```dart
Navigator.of(context).push(
  ShaderTransitions.circle(
    page: const NextPage(),
    origin: Alignment.bottomRight,
    invert: true, // contracting iris
    duration: const Duration(milliseconds: 700),
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
    rotation: 0.0, // radians; tilts the edge
    duration: const Duration(milliseconds: 600),
  ),
);
```

### Cover color & hold (cinematic fade)

Pass a `TransitionCover` to fill the un-revealed area with a flat color
instead of letting the outgoing page show through. `hold` keeps the screen
fully covered between the wipe-in and wipe-out.

```dart
Navigator.of(context).push(
  ShaderPageRoute(
    page: const NextPage(),
    transition: const WipeTransition(
      direction: SweepDirection.leftToRight,
      duration: Duration(milliseconds: 800),
      cover: TransitionCover(
        color: Colors.black,
        hold: Duration(milliseconds: 600), // hold on black for 600 ms
      ),
    ),
  ),
);
```

`cover.hold` is clamped internally to at most 75% of `duration` — each wipe always gets at least 12.5% of the timeline, so the cover hold can never squash the wipes into nothing.

Timeline with `duration: 800 ms` and `cover.hold: 600 ms`:

```
| cover wipes in | hold full cover     | page wipes in |
|     100 ms     |       600 ms        |    100 ms     |
```

### Configuration reference

Shared by every `ShaderTransition`:

| Field | Type | Default |
|---|---|---|
| `duration` | `Duration` | `800 ms` diamond · `700 ms` circle · `600 ms` wipe |
| `cover` | `TransitionCover?` | `null` |
| `invert` | `bool` | `false` |

`TransitionCover`: `color` (`Color`, required), `hold` (`Duration`, default `Duration.zero`, clamped to ≤ 75% of `duration`).

Per-type fields:

| Type | Field | Type | Default |
|---|---|---|---|
| `DiamondTransition` | `cellSize` | `double` | `40.0` (px, min 1) |
| | `feather` | `double` | `0.0` |
| | `direction` | `SweepDirection` | `topLeftToBottomRight` |
| `CircleTransition` | `origin` | `Alignment` | `Alignment.center` |
| | `feather` | `double` | `2.0` |
| `WipeTransition` | `softness` | `double` | `4.0` (px; 0 = hard edge) |
| | `direction` | `SweepDirection` | `leftToRight` |
| | `rotation` | `double` | `0.0` (radians) |
| `ClockTransition` | `origin` | `Alignment` | `Alignment.center` |
| | `sectors` | `int` | `1` |
| | `rotation` | `double` | `0.0` |
| | `feather` | `double` | `2.0` |
| `PolygonTransition` | `origin` | `Alignment` | `Alignment.center` |
| | `sides` | `int` | `6` (min 3) |
| | `feather` | `double` | `2.0` |
| | `rotation` | `double` | `0.0` |
| `DissolveTransition` | `grain` | `double` | `8.0` |
| `FadeShaderTransition` | _(shared fields only)_ | | |
| `BarsTransition` | `count` | `int` | `6` |
| | `softness` | `double` | `4.0` |
| | `direction` | `SweepDirection` | `leftToRight` |

`SweepDirection` values: `topLeftToBottomRight`, `topRightToBottomLeft`, `bottomLeftToTopRight`, `bottomRightToTopLeft`, `leftToRight`, `rightToLeft`, `topToBottom`, `bottomToTop`.

## With go_router / auto_route / app-wide

`ShaderTransitionBuilders.create(transition)` returns a standard `RouteTransitionsBuilder`, so any router that accepts one works.

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
      const DiamondTransition(direction: SweepDirection.leftToRight),
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
      const CircleTransition(),
    ),
  ),
),
```

**App-wide** via `ThemeData.pageTransitionsTheme`:

```dart
MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ShaderPageTransitionsBuilder(
          WipeTransition(direction: SweepDirection.leftToRight),
        ),
        TargetPlatform.iOS: ShaderPageTransitionsBuilder(CircleTransition()),
      },
    ),
  ),
)
```

> ⚠️ **`opaque: false` is required** for the outgoing page to show through the un-revealed area. `ShaderPageRoute` sets it for you; with go_router/auto_route you set it on the page. `ShaderPageTransitionsBuilder` is best paired with a `cover` (covered transitions don't need the route below to be visible).

## Widget transitions

`ShaderTransitionSwitcher` runs a transition between two widgets instead of
routes — an `AnimatedSwitcher` analog. Key the children so swaps are detected:

```dart
ShaderTransitionSwitcher(
  transition: const CircleTransition(),
  child: KeyedSubtree(
    key: ValueKey(index),
    child: pages[index],
  ),
)
```

## Sound on transition

The package bundles no audio. Use the `onStart` / `onComplete` / `onProgress`
callbacks (available on `ShaderPageRoute`, `ShaderTransitionBuilders.create`,
and `ShaderTransitionSwitcher`) and play audio with whatever package you
already use:

```dart
Navigator.of(context).push(
  ShaderPageRoute(
    page: const NextPage(),
    transition: const WipeTransition(),
    onStart: () => audioPlayer.play(AssetSource('whoosh.mp3')),
  ),
);
```

## Migrating from 0.0.x

0.1.0 replaced the single `ShaderTransitionConfig` with a sealed
`ShaderTransition` hierarchy.

| 0.0.x | 0.1.0 |
|---|---|
| `ShaderTransitionConfig.diamond(size: 40, transitionDuration: d)` | `DiamondTransition(cellSize: 40, duration: d)` |
| `ShaderTransitionConfig.wipe(size: 6)` | `WipeTransition(softness: 6)` |
| `ShaderTransitionConfig.circle()` | `CircleTransition()` |
| `color: Colors.black, coverDuration: h` | `cover: TransitionCover(color: Colors.black, hold: h)` |
| `ShaderPageRoute(config: c)` | `ShaderPageRoute(transition: t)` |
| `ShaderTransitionBuilders.create(config)` | `ShaderTransitionBuilders.create(transition)` |

The `ShaderTransitions.{diamond,circle,wipe}(...)` convenience factories keep working — only their parameter names changed (`size`→`cellSize`, `transitionDuration`→`duration`, etc.).

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
