#version 460 core
#include <flutter/runtime_effect.glsl>

// Uniform layout (identical across all shaders — set unconditionally by ShaderMaskTransition):
// 0: uProgress    — animation.value (0.0 → 1.0)
// 1: uResolution  — vec2.x (screen width)
// 2: uResolution  — vec2.y (screen height)
// 3: uSize        — diamond cell size in pixels
// 4: uDirection   — vec2.x (normalized sweep direction)
// 5: uDirection   — vec2.y (normalized sweep direction)
uniform float uProgress;
uniform vec2  uResolution;
uniform float uSize;
uniform vec2  uDirection;

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;
    vec2 d = normalize(uDirection);

    // Manhattan distance from the cell center, range [0, 1].
    // 0 at cell center, 1 at cell corners — defines the diamond shape.
    // Clamp uSize to ≥ 1 px so we never divide by zero (or a sub-pixel value
    // that would alias every cell onto the same coordinate).
    float cellSize = max(uSize, 1.0);
    vec2 cell = fract(fragCoord / cellSize);
    float diamond = abs(cell.x - 0.5) + abs(cell.y - 0.5);

    // Remap dot(uv, d) to [0, 1] so pos=0 is always the start corner of the
    // sweep and pos=1 is always the end corner, regardless of which
    // SweepDirection (axis-aligned positive, negative, or diagonal). Same
    // trick as wipe.frag — without it, negative directions and diagonals
    // have wrong/incomplete sweeps.
    float raw = dot(uv, d);
    float minPos = min(d.x, 0.0) + min(d.y, 0.0);
    float maxPos = max(d.x, 0.0) + max(d.y, 0.0);
    float pos = (raw - minPos) / (maxPos - minPos);

    // A wipe band of width `bandWidth` sweeps across pos as uProgress goes
    // 0→1. Behind the band the screen is fully revealed; ahead of it nothing
    // is. Within the band, cells reveal center-first (low diamond) and then
    // outward toward their corners (high diamond).
    //
    // p is the trailing edge of the band, padded so that at uProgress=0 the
    // entire screen is ahead of the band (alpha=0) and at uProgress=1 the
    // entire screen is behind it (alpha=1).
    const float bandWidth = 0.3;
    float p = uProgress * (1.0 + bandWidth) - bandWidth;

    // bandProgress: 0 = at trailing edge (revealed); 1 = at leading edge (hidden).
    float bandProgress = clamp((pos - p) / bandWidth, 0.0, 1.0);

    // Scale revealLevel to [-0.1, 1.1] so the endpoints fully hide / reveal
    // (otherwise cell centers leak through at uProgress=0 and cell corners
    // never finish at uProgress=1).
    float revealLevel = (1.0 - bandProgress) * 1.2 - 0.1;
    float alpha = step(diamond, revealLevel);

    // Output only alpha — RGB is irrelevant when used with ShaderMask(blendMode: BlendMode.dstIn).
    fragColor = vec4(1.0, 1.0, 1.0, alpha);
}
