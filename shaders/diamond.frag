#version 460 core
#include <flutter/runtime_effect.glsl>

// Unified uniform layout v2 (set unconditionally by ShaderMaskTransition):
//  0    uProgress   — animation phase progress (0.0 → 1.0)
//  1-2  uResolution — bounds size in px
//  3-4  uOrigin     — normalized [0,1] focal point (unused by diamond)
//  5-6  uDirection   — sweep direction vector (normalized)
//  7    uFeather     — band edge softness in px
//  8    uCellSize    — diamond grid cell size in px
//  9    uRotation    — radians (unused by diamond)
//  10   uInvert      — 0/1, flips sweep direction
uniform float uProgress;
uniform vec2  uResolution;
uniform vec2  uOrigin;
uniform vec2  uDirection;
uniform float uFeather;
uniform float uCellSize;
uniform float uRotation;
uniform float uInvert;
uniform float uSectors; // unused by diamond (shared layout v3)
uniform float uSides;   // unused by diamond (shared layout v3)

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;
    vec2 d = normalize(uDirection);

    // Manhattan distance from the cell center, range [0, 1]. 0 at center,
    // 1 at corners. Cell size is clamped ≥ 1 px to avoid divide-by-zero
    // and sub-pixel aliasing.
    float cellSize = max(uCellSize, 1.0);
    vec2 cell = fract(fragCoord / cellSize);
    float diamond = abs(cell.x - 0.5) + abs(cell.y - 0.5);

    // Center-based projection remap (see wipe.frag): pos 0 at the start
    // corner of the sweep, 1 at the end corner, for any direction.
    vec2 rel = uv - 0.5;
    float proj = dot(rel, d);
    float h = 0.5 * (abs(d.x) + abs(d.y)) + 1e-5;
    float pos = (proj + h) / (2.0 * h);
    pos = mix(pos, 1.0 - pos, uInvert);

    // A band sweeps along pos; behind it everything is revealed, ahead
    // nothing is, and within it cells fill center-first.
    const float bandWidth = 0.3;
    float p = uProgress * (1.0 + bandWidth) - bandWidth;
    float bandProgress = clamp((pos - p) / bandWidth, 0.0, 1.0);
    float revealLevel = (1.0 - bandProgress) * 1.2 - 0.1;

    // Soft cell edge controlled by uFeather (0 → near-hard step).
    float fe = max(uFeather / max(uResolution.x, uResolution.y), 0.001);
    float alpha = smoothstep(diamond - fe, diamond + fe, revealLevel);

    fragColor = vec4(1.0, 1.0, 1.0, alpha);
}
