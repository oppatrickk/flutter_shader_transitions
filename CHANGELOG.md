# Changelog

## 0.0.1 — Initial release

- `ShaderTransitions.preload()` to compile all bundled fragment shaders once at app startup.
- `ShaderPageRoute` + `ShaderTransitions.{diamond, circle, wipe}` convenience factories for `Navigator`-style use.
- `ShaderTransitionBuilders.create(config)` for `CustomTransitionPage` (go_router) and `CustomRoute` (auto_route) integrations.
- Three shaders: diamond grid (Manhattan-distance reveal), circle iris, linear directional wipe with feathered edge.
- Eight `SweepDirection` values — four axis-aligned, four diagonals; all normalized so push and pop wipes reach every corner regardless of direction.
- Optional `color` cover with a configurable `coverDuration` hold and a 75% clamp so the wipes always retain visible motion.
- Cell-size floor of 1 px on the diamond shader (no divide-by-zero, no sub-pixel aliasing).
- Example gallery app with two-column layout at ≥ 720 px wide and page-navigation flow below.
