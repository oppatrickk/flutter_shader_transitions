#version 460 core
#include <flutter/runtime_effect.glsl>

// Uniform layout (identical across all shaders — set unconditionally by ShaderMaskTransition):
// 0: uProgress    — animation.value (0.0 → 1.0)
// 1: uResolution  — vec2.x (screen width)
// 2: uResolution  — vec2.y (screen height)
// 3: uSize        — unused (declared to keep layout consistent)
// 4: uDirection   — vec2.x (unused, declared to keep layout consistent)
// 5: uDirection   — vec2.y (unused, declared to keep layout consistent)
uniform float uProgress;
uniform vec2  uResolution;
uniform float uSize;
uniform vec2  uDirection;

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    // Normalized distance from the center of the screen.
    // 0.0 at center, ~1.0 at the midpoints of the screen edges,
    // slightly above 1.0 at the corners.
    vec2 center = uResolution * 0.5;
    float dist = length(fragCoord - center);
    float maxDist = length(center); // distance to the midpoint of the shorter edge

    float normDist = dist / maxDist;

    // Smooth 2-pixel feathered edge for anti-aliasing.
    float feather = 2.0 / maxDist;

    // alpha=1 inside the growing circle, 0 outside.
    // As uProgress goes 0→1, the circle expands from the center outward.
    float alpha = 1.0 - smoothstep(uProgress - feather, uProgress + feather, normDist);

    // Output only alpha — RGB is irrelevant when used with ShaderMask(blendMode: BlendMode.dstIn).
    fragColor = vec4(1.0, 1.0, 1.0, alpha);
}
