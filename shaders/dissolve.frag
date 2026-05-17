#version 460 core
#include <flutter/runtime_effect.glsl>

// Shared uniform layout v3 (set unconditionally by ShaderMaskTransition).
uniform float uProgress;
uniform vec2  uResolution;
uniform vec2  uOrigin;
uniform vec2  uDirection;
uniform float uFeather;
uniform float uCellSize;
uniform float uRotation;
uniform float uInvert;
uniform float uSectors;
uniform float uSides;

out vec4 fragColor;

// Cheap per-pixel hash → pseudo-random threshold in [0,1].
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float threshold = hash(floor(FlutterFragCoord().xy));

    // Soften the grain so pixels fade in over a small progress window
    // rather than popping. uFeather widens that window.
    float feather = max(uFeather / 100.0, 0.01);

    // As uProgress rises, more pixels cross their threshold and reveal.
    float alpha = smoothstep(threshold - feather, threshold + feather, uProgress);
    alpha = mix(alpha, 1.0 - alpha, uInvert);

    fragColor = vec4(1.0, 1.0, 1.0, alpha);
}
