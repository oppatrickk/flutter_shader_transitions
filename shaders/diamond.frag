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

    // Manhattan distance from the center of the current grid cell.
    // Ranges 0.0 at cell center to 0.5 at cell corners — this defines the diamond shape.
    vec2 cell = fract(fragCoord / uSize);
    float diamond = abs(cell.x - 0.5) + abs(cell.y - 0.5);

    // Project the screen UV onto the sweep direction to get a per-pixel wave offset.
    // dot(uv, normalize(uDirection)) ranges 0..1 across the screen in the sweep direction.
    float offset = dot(uv, normalize(uDirection));

    // alpha=1.0 where the pixel has been "revealed" by the advancing threshold.
    // The multiplier 1.5 ensures the sweep fully covers the screen at uProgress=1.0
    // regardless of the uDirection vector chosen.
    float alpha = step(diamond + offset * 0.5, uProgress * 1.5);

    // Output only alpha — RGB is irrelevant when used with ShaderMask(blendMode: BlendMode.dstIn).
    fragColor = vec4(1.0, 1.0, 1.0, alpha);
}
