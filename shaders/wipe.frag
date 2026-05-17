#version 460 core
#include <flutter/runtime_effect.glsl>

// Unified uniform layout v2 (set unconditionally by ShaderMaskTransition):
//  0    uProgress   — animation phase progress (0.0 → 1.0)
//  1-2  uResolution — bounds size in px
//  3-4  uOrigin     — normalized [0,1] focal point (unused by wipe)
//  5-6  uDirection   — sweep direction vector (normalized)
//  7    uFeather     — edge softness in px (0 = hard edge)
//  8    uCellSize    — grid cell px (unused by wipe)
//  9    uRotation    — rotation of the wipe edge, radians
//  10   uInvert      — 0/1, flips which side reveals first
uniform float uProgress;
uniform vec2  uResolution;
uniform vec2  uOrigin;
uniform vec2  uDirection;
uniform float uFeather;
uniform float uCellSize;
uniform float uRotation;
uniform float uInvert;
uniform float uSectors; // unused by wipe (shared layout v3)
uniform float uSides;   // unused by wipe (shared layout v3)

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // Rotate the sweep direction around screen center by uRotation.
    vec2 d0 = normalize(uDirection);
    float c = cos(uRotation);
    float s = sin(uRotation);
    vec2 d = vec2(d0.x * c - d0.y * s, d0.x * s + d0.y * c);

    // Center-based projection remap: pos is 0 at the start corner of the
    // sweep and 1 at the end corner, for ANY direction (axis-aligned,
    // negative, diagonal, or rotated). h is half the projected extent of
    // the [0,1]^2 box onto d.
    vec2 rel = uv - 0.5;
    float proj = dot(rel, d);
    float h = 0.5 * (abs(d.x) + abs(d.y)) + 1e-5;
    float pos = (proj + h) / (2.0 * h);
    pos = mix(pos, 1.0 - pos, uInvert);

    // Convert px feather to normalized units; min keeps a hard edge stable.
    float feather = max(uFeather / max(uResolution.x, uResolution.y), 0.001);
    float alpha = 1.0 - smoothstep(uProgress - feather, uProgress + feather, pos);

    fragColor = vec4(1.0, 1.0, 1.0, alpha);
}
