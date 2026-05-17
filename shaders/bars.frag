#version 460 core
#include <flutter/runtime_effect.glsl>

// Shared uniform layout v3 (set unconditionally by ShaderMaskTransition).
// Bars reuses uSectors as the bar count.
uniform float uProgress;
uniform vec2  uResolution;
uniform vec2  uOrigin;
uniform vec2  uDirection;
uniform float uFeather;
uniform float uCellSize;
uniform float uRotation;
uniform float uInvert;
uniform float uSectors; // bar count
uniform float uSides;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 d = normalize(uDirection);

    // Center-based projection remap → pos in [0,1] along the bar axis,
    // for any direction (matches wipe.frag).
    vec2 rel = uv - 0.5;
    float proj = dot(rel, d);
    float h = 0.5 * (abs(d.x) + abs(d.y)) + 1e-5;
    float pos = (proj + h) / (2.0 * h);

    // Split into `count` parallel bars; each bar runs the same local wipe
    // simultaneously — a venetian-blind reveal.
    float count = max(uSectors, 1.0);
    float local = fract(pos * count);
    local = mix(local, 1.0 - local, uInvert);

    float feather = max(uFeather / max(uResolution.x, uResolution.y), 0.001);
    float alpha = 1.0 - smoothstep(uProgress - feather, uProgress + feather, local);

    fragColor = vec4(1.0, 1.0, 1.0, alpha);
}
