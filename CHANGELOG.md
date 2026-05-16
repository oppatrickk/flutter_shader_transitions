# Changelog

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
