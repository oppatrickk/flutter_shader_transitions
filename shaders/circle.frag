#version 460 core
#include <flutter/runtime_effect.glsl>

// Unified uniform layout v2 (set unconditionally by ShaderMaskTransition):
//  0    uProgress   — animation phase progress (0.0 → 1.0)
//  1-2  uResolution — bounds size in px
//  3-4  uOrigin     — normalized [0,1] iris focal point
//  5-6  uDirection   — unused by circle
//  7    uFeather     — ring edge softness in px
//  8    uCellSize    — unused by circle
//  9    uRotation    — unused by circle
//  10   uInvert      — 0/1, expanding (0) vs contracting (1) iris
uniform float uProgress;
uniform vec2  uResolution;
uniform vec2  uOrigin;
uniform vec2  uDirection;
uniform float uFeather;
uniform float uCellSize;
uniform float uRotation;
uniform float uInvert;

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    // Iris focal point in px from the normalized [0,1] origin.
    vec2 origin = uOrigin * uResolution;
    float dist = length(fragCoord - origin);

    // Farthest screen corner from the origin, so the iris always fully
    // covers the screen at uProgress = 1 regardless of where it starts.
    float maxDist = max(
        max(length(origin), length(vec2(uResolution.x, 0.0) - origin)),
        max(length(vec2(0.0, uResolution.y) - origin),
            length(uResolution - origin))
    );

    float normDist = dist / maxDist;
    float feather = max(uFeather / maxDist, 0.001);

    // alpha=1 inside the growing circle. uInvert flips to a contracting iris.
    float a = 1.0 - smoothstep(uProgress - feather, uProgress + feather, normDist);
    float alpha = mix(a, 1.0 - a, uInvert);

    fragColor = vec4(1.0, 1.0, 1.0, alpha);
}
