#version 460 core
#include <flutter/runtime_effect.glsl>

// Uniform layout (identical across all shaders — set unconditionally by ShaderMaskTransition):
// 0: uProgress    — animation.value (0.0 → 1.0)
// 1: uResolution  — vec2.x (screen width)
// 2: uResolution  — vec2.y (screen height)
// 3: uSize        — feather/softness width in pixels (0 = hard edge)
// 4: uDirection   — vec2.x (normalized wipe direction)
// 5: uDirection   — vec2.y (normalized wipe direction)
uniform float uProgress;
uniform vec2  uResolution;
uniform float uSize;
uniform vec2  uDirection;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 d = normalize(uDirection);

    // Project UV onto the wipe direction. The raw range of dot(uv, d) over
    // uv ∈ [0,1]² depends on the signs of d.x and d.y — for negative-axis
    // directions (e.g. rightToLeft) it spans [-1,0], and for diagonals it
    // spans [0, √2]. Remap to [0,1] so pos=0 is always the start corner of
    // the sweep and pos=1 is the end corner, regardless of direction.
    float raw = dot(uv, d);
    float minPos = min(d.x, 0.0) + min(d.y, 0.0);
    float maxPos = max(d.x, 0.0) + max(d.y, 0.0);
    float pos = (raw - minPos) / (maxPos - minPos);

    // Convert the pixel-space feather width into normalized UV space.
    // A minimum of 0.001 prevents division issues when uSize=0 (hard edge).
    float feather = max(uSize / max(uResolution.x, uResolution.y), 0.001);

    // alpha=1 where pos < uProgress (already revealed), 0 where pos > uProgress (not yet revealed).
    // smoothstep creates a soft feathered edge of width 2*feather around the wipe boundary.
    float alpha = 1.0 - smoothstep(uProgress - feather, uProgress + feather, pos);

    // Output only alpha — RGB is irrelevant when used with ShaderMask(blendMode: BlendMode.dstIn).
    fragColor = vec4(1.0, 1.0, 1.0, alpha);
}
