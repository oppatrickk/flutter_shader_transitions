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

    // Project the screen UV onto the wipe direction to get a scalar position (0..1)
    // along the wipe axis. Pixels at the start of the direction reveal first.
    float pos = dot(uv, normalize(uDirection));

    // Convert the pixel-space feather width into normalized UV space.
    // A minimum of 0.001 prevents division issues when uSize=0 (hard edge).
    float feather = max(uSize / max(uResolution.x, uResolution.y), 0.001);

    // alpha=1 where pos < uProgress (already revealed), 0 where pos > uProgress (not yet revealed).
    // smoothstep creates a soft feathered edge of width 2*feather around the wipe boundary.
    float alpha = smoothstep(uProgress - feather, uProgress + feather, pos);

    // Output only alpha — RGB is irrelevant when used with ShaderMask(blendMode: BlendMode.dstIn).
    fragColor = vec4(1.0, 1.0, 1.0, alpha);
}
