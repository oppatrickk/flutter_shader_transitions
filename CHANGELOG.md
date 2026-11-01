# Changelog

## 1.1.1 — Homepage points to the demo site

- The pub.dev homepage link is now the demo site,
  https://flutter-shader-transition.web.app: showcase, playground, and API
  reference.
- Example: a pub.dev link next to the GitHub one in the app bar (labeled
  on wide screens, icons on phones).

## 1.1.0 — iOS swipe back + named constructors (additive)

- Named constructors on `ShaderTransition` for all eight transitions:
  `ShaderTransition.diamond()`, `.circle()`, `.wipe()`, `.clock()`,
  `.polygon()`, `.dissolve()`, `.fade()`, `.bars()`. Each redirects to the
  existing concrete class (same parameters and defaults), so typing
  `ShaderTransition.` lists every transition, and Dart 3.10+ apps can write
  `transition: .diamond()`.
- README, library docs, and the example gallery use the named constructors.
- Package tests added for the constructors.
- Package logo and app icon in `doc/brand/` (SVG sources, PNG exports, and
  the script that generates them). The README shows the logo and links the
  live demo at https://flutter-shader-transition.web.app.
- **iOS swipe back.** `ShaderPageRoute` now pops with the platform edge
  swipe on iOS and macOS, scrubbing the shader transition backwards under
  the finger (Cupertino thresholds; refused for the first route,
  `PopScope(canPop: false)`, and mid-transition; RTL-aware). New
  `swipeBack` parameter on `ShaderPageRoute` and the `ShaderTransitions.*`
  shortcuts: `null` follows the platform, `true`/`false` forces it.
  `onStart` / `onComplete` don't fire while a swipe is scrubbing the route.
- **Minimum Flutter is now 3.22 (Dart 3.4)**, up from 3.10 — the swipe
  relies on `PageRoute.popGestureEnabled`. Apps on older Flutter keep
  resolving 1.0.0.
- Verified on iOS (Impeller/Metal, iOS 26.5 and 27 simulators): all eight
  shaders compile and render with correct geometry, and the device build
  compiles for arm64.
- Example: iOS runner migrated to the UIScene lifecycle (required when
  building with the iOS 27 SDK), minimum iOS 15.0, Swift Package Manager
  integration, and a real bundle ID
  (`com.johnpatrickprieto.shadertransitions.example`) so it can be signed
  for a physical iPhone. The example now needs Flutter 3.38+.
- Example: on-device tests in `example/integration_test/` read back pixels
  to check every transition's mask and the back swipe on a real GPU
  backend.
- Example: a GitHub button in the app bar (adds `url_launcher` to the
  example only). On the web, `?transition=<name>` opens that transition's
  editor. Builds can pass `--dart-define` values to show the package
  version and commit (`SHADER_TRANSITIONS_VERSION`,
  `SHADER_TRANSITIONS_COMMIT`) and a link back to a site (`SITE_HOME_URL`);
  the demo site uses all three.
- Fix: with a `TransitionCover`, feather-wide slivers of both pages showed at
  the screen edges while the screen should be fully covered (the masks are
  only half-opaque along an edge sitting on the screen border at progress
  0 and 1). A finished cover now paints unmasked and a page whose wipe hasn't
  started is hidden.
- Fix: once a transition finishes, the page paints without the shader mask,
  so pixels that settle just below full opacity (dissolve grain, clock and
  bars seams, a wipe's trailing edge) can't leave a faint copy of the
  previous page showing through.
- README: demo GIFs for every transition plus a hero reel, rendered from the
  real shaders by `example/tool/readme_gifs_test.dart`.
- No breaking changes — the concrete classes and `ShaderTransitions`
  factories are unchanged.

## 1.0.0 — Stable

API freeze. No code changes vs 0.3.2 — this marks the sealed
`ShaderTransition` API and the eight-transition catalogue (diamond, circle,
wipe, clock, polygon, dissolve, fade, bars) as stable under semantic
versioning.

- README documents the full catalogue (features, showcase, per-type config
  reference).
- pana: 150/160 (50/50 static analysis, 40/40 dependencies, WASM-ready,
  lower-bound-constraint compatible). The remaining points are the
  screenshots bucket, pending recorded GIFs.

## 0.3.2 — Bars / venetian-blind transition (additive)

- `BarsTransition` — `count` parallel bars along `direction` reveal in
  parallel for a venetian-blind effect (reuses the shared `uSectors`
  uniform as the bar count; no uniform layout change).
- Example gallery gains a Bars entry.
- **Not added, by design:** a content *slide* moves the child — that's a
  transform, not an alpha mask, so it's outside this package's
  `ShaderMask(dstIn)` core; use Flutter's built-in `SlideTransition`.
  A *corner wipe* is already `WipeTransition` with a diagonal
  `SweepDirection`. *Combination* presets are already expressible by
  pairing any transition with a `TransitionCover`.
- No breaking changes.

## 0.3.1 — Dissolve + fade transitions (additive)

- `DissolveTransition` — noise-grain dissolve; `grain` controls how soft
  the speckle fades in.
- `FadeShaderTransition` — uniform shader cross-fade that composes with
  `cover` and the lifecycle callbacks like every other transition.
- Example gallery gains Dissolve and Fade entries. No breaking changes.

## 0.3.0 — Clock + polygon transitions (additive)

- `ClockTransition` — a radial sweep around `origin`, optionally fanned into
  `sectors` identical wedges; `invert` reverses the sweep direction.
- `PolygonTransition` — a regular n-gon iris (`sides` ≥ 3; high counts look
  circular); `origin`, `feather`, `rotation`, `invert` apply.
- Internal shader uniform layout extended to v3 (`uSectors`, `uSides`); the
  public parameter vocabulary is unchanged.
- Example gallery gains Clock and Polygon entries with a sectors/sides
  control. No breaking changes.

## 0.2.0 — Widget transitions + lifecycle hooks (additive)

- `ShaderTransitionSwitcher` — an `AnimatedSwitcher` analog that runs a
  `ShaderTransition` between two child widgets (not routes). Key your
  children to trigger swaps.
- `onStart` / `onComplete` / `onProgress` callbacks on `ShaderPageRoute`,
  `ShaderTransitionBuilders.create`, and `ShaderTransitionSwitcher`. This is
  the sound mechanism — play your own audio in `onStart`; the package adds
  no audio dependency.
- No breaking changes.

## 0.1.0 — API redesign (breaking)

The single overloaded `ShaderTransitionConfig` is replaced by a sealed
`ShaderTransition` hierarchy with a clear, shared parameter vocabulary.

**Breaking changes**

- Removed `ShaderTransitionConfig`, `TransitionType`. Use the sealed types:
  `DiamondTransition`, `CircleTransition`, `WipeTransition`.
- `ShaderPageRoute(config:)` → `ShaderPageRoute(transition:)`.
- `ShaderTransitionBuilders.create(config)` now takes a `ShaderTransition`.
- The overloaded `size` is gone: it's `DiamondTransition.cellSize`,
  `WipeTransition.softness`.
- `transitionDuration` → `duration`. Loose `color` + `coverDuration` are
  grouped into `TransitionCover(color:, hold:)` passed as `cover:`.

**Migration**

| 0.0.x | 0.1.0 |
|---|---|
| `ShaderTransitionConfig.diamond(size: 40, transitionDuration: d)` | `DiamondTransition(cellSize: 40, duration: d)` |
| `ShaderTransitionConfig.wipe(size: 6)` | `WipeTransition(softness: 6)` |
| `ShaderTransitionConfig.circle()` | `CircleTransition()` |
| `color: Colors.black, coverDuration: h` | `cover: TransitionCover(color: Colors.black, hold: h)` |
| `ShaderPageRoute(config: c)` | `ShaderPageRoute(transition: t)` |

**New**

- `CircleTransition.origin` (`Alignment`) — iris can emanate from any point.
- Shared `invert` flag — e.g. `CircleTransition(invert: true)` is a
  contracting iris; flips reveal order for directional transitions.
- `WipeTransition.rotation` (radians) — tilt the wipe edge.
- `ShaderPageTransitionsBuilder` — drop into
  `ThemeData.pageTransitionsTheme` for app-wide shader transitions.
- Unified shader uniform layout v2 (origin / direction / feather / cellSize
  / rotation / invert) shared by every `.frag`.

## 0.0.3

- Lower the SDK floor to Dart 3.0 / Flutter 3.10 (was Dart 3.2 / Flutter 3.16). This is the lowest that supports the Dart 3 records & patterns used in `lib/` plus `ui.FragmentProgram.fromAsset` (stable since Flutter 3.7), widening compatibility for consumers.
- Dartdoc: document every `SweepDirection` value and the `SweepDirectionVector` extension; fix stale `coverHold` references in `ShaderMaskTransition` docs (the field is `coverDuration`).
- README: per-transition "how it works" explanations in the showcase; updated Flutter badge and install constraint.

## 0.0.2

- Shorten pubspec `description` to fit within pub.dev's 60–180 character window (was 218 chars and failed the "Provide a valid pubspec.yaml" check).

## 0.0.1 — Initial release

- `ShaderTransitions.preload()` to compile all bundled fragment shaders once at app startup.
- `ShaderPageRoute` + `ShaderTransitions.{diamond, circle, wipe}` convenience factories for `Navigator`-style use.
- `ShaderTransitionBuilders.create(config)` for `CustomTransitionPage` (go_router) and `CustomRoute` (auto_route) integrations.
- Three shaders: diamond grid (Manhattan-distance reveal), circle iris, linear directional wipe with feathered edge.
- Eight `SweepDirection` values — four axis-aligned, four diagonals; all normalized so push and pop wipes reach every corner regardless of direction.
- Optional `color` cover with a configurable `coverDuration` hold and a 75% clamp so the wipes always retain visible motion.
- Cell-size floor of 1 px on the diamond shader (no divide-by-zero, no sub-pixel aliasing).
- Example gallery app with two-column layout at ≥ 720 px wide and page-navigation flow below.
